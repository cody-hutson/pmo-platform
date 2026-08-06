#!/usr/bin/env python3
"""Self-test coverage gate — discovery-based, with a committed manifest floor.

WHAT THIS IS
    The committed engine behind the `selftest-discovery` CI job. The workflow is a
    THIN CALLER: no discovery predicate, no scope glob, and no roster is re-encoded
    in YAML. This follows the platform's named thin-caller-over-committed-engine
    discipline (gate-efficacy-standard.md; deploy-check-ci.yml states the rule
    outright: "NO check predicate is re-encoded in this YAML").

    It exists because a hardcoded roster of tools-to-self-test drifts: a tool that
    grows a `--self-test` is never added, a tool that loses one is never removed,
    and the roster silently becomes a claim rather than a gate.

WHY PYTHON AND NOT BASH
    One engine runs on TWO runners (ubuntu + macOS). `sed -i`, `grep -oE`, `sort`
    and `find` all diverge BSD<->GNU, and a divergent discovered set between the two
    jobs would break the runner-partition assertion SILENTLY. Python's stdlib has
    identical semantics on both. Bash 3.2 on the macOS runner also has no associative
    arrays, which makes the set arithmetic below error-prone.

    Related hazard, recorded because it cost a real measurement: `grep -q` inside a
    `set -o pipefail` pipeline silently INVERTS a predicate (grep exits early, the
    upstream process takes SIGPIPE, the pipeline reports non-zero). A shell
    implementation of the predicate below is one line away from that bug. This engine
    shells out for nothing except invoking the tools themselves.

THE PREDICATE IS DELIBERATELY RECALL-BIASED — DO NOT "TIGHTEN" IT
    `advertises --self-test` is the union of two per-language tests (see ADVERTISE
    section). The union over-matches: a Python docstring or a shell fixture literal
    that merely NAMES the flag is counted as an advertiser.

    That asymmetry is intentional and total:
      * a false NEGATIVE is an unenforced self-test — exactly the defect this gate
        exists to close — and it is SILENT;
      * a false POSITIVE costs one line in the exclusions file carrying a written
        reason, and it is LOUD (the tool fails with "unrecognized arguments" until
        someone writes the reason down).
    Precision is the exclusions file's job, not the predicate's. Narrowing the regex
    to kill a false positive re-opens the silent class.

THE FOUR ARMS
    A  EXECUTION       HARD   every discovered tool's `--self-test` exits 0
    B  MANIFEST FLOOR  HARD   (i) every manifest path still on disk is discovered
                              (ii) every discovered path is in the manifest
    C  REPO-WIDE       WARN   every tracked *.sh/*.py advertiser repo-wide is either
                              discovered, invoked by a named workflow step, or
                              excluded WITH a reason
    D  TEST SUITES     WARN   every tests/ suite is referenced by >=1 workflow

    Arms A and B are sourced INDEPENDENTLY — A's set comes from a runtime glob, B's
    from a committed artifact. That independence is what stops "advertises but is not
    discovered" from being the empty set by construction. If both sides were computed
    by the same glob, the meta-assertion would assert nothing.

    Arm B(i) is the anti-narrowing guard. Narrowing a `# scope:` directive drops
    paths out of the discovered set while they remain in the manifest and on disk ->
    hard red, naming each dropped path. Greening a narrowed scope therefore requires
    deleting those manifest lines IN THE SAME DIFF, immediately below the directive
    that was narrowed.

EXIT CODES
    0  pass (warnings may still have been emitted)
    1  gate failure (an arm failed, or a self-test assertion failed)
    2  usage / configuration error (bad arguments, unparseable manifest or exclusions,
       zero-yield scope directive)
    Exit 5 is deliberately NOT used: release/tools/domain-blast-radius.sh already
    owns exit 5 in this tree, and a shared harness that treats 5 as a distinct
    condition must not collide with it.

STDLIB ONLY. No network, no `gh`, no git-history read -> a shallow checkout is
sufficient and the gate is deterministic and credential-free.
"""

from __future__ import annotations

import argparse
import contextlib
import io
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# --------------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------------

MANIFEST_REL = "core/deploy/allowlists/selftest-coverage-manifest.txt"
EXCLUSIONS_REL = "core/deploy/allowlists/selftest-coverage-exclusions.txt"
WORKFLOW_DIR_REL = ".github/workflows"

# Fallback scope, used ONLY by --emit-manifest when no manifest exists yet
# (bootstrap). Once the manifest is committed, the scope directives IN IT are the
# single source of truth — the engine never silently falls back to this list.
BOOTSTRAP_SCOPE = (
    "release/tools/*.sh",
    "release/tools/*.py",
    "core/deploy/tools/*.py",
    "core/deploy/tools/*.sh",
)

RUNNERS = ("ubuntu", "macos")
DEFAULT_RUNNER = "ubuntu"

# The runner declaration lives AT THE TOOL, not in the workflow and not in the
# exclusions file. A tool's runner requirement is a property of the tool; putting it
# in the workflow would re-create a roster, and putting it in the exclusions file
# would let a runner problem masquerade as a coverage decision.
RUNNER_DECL_RE = re.compile(r"^\s*#\s*selftest-runner:\s*([A-Za-z0-9_-]+)\s*$")
RUNNER_DECL_SCAN_LINES = 40

# Test-suite naming conventions surveilled by Arm D (NOT the advertise predicate).
TEST_SUITE_GLOBS = (
    "release/tools/tests/test_*.sh",
    "release/tools/tests/test_*.py",
    "core/deploy/tools/tests/*.sh",
    "core/deploy/tools/tests/*.py",
)

SELF_TEST_TOKEN = "--self-test"

PER_TOOL_TIMEOUT_S = 300

# --------------------------------------------------------------------------------
# ADVERTISE — the predicate
# --------------------------------------------------------------------------------

# P3 (dispatch shape), shell: a case-arm pattern `--self-test)` or a comparison
# against the literal. The comparison arm accepts `=`, `==` and `=~` because the
# tree uses all three (`[ "${1:-}" = "--self-test" ]` is live).
P3_SH_RE = re.compile(
    r"""(?x)
    (?: (?:^|[\s|(]) "? --self-test "? \s* \) )     # case arm:  --self-test)
  | (?: [=~]=? \s* ["']? --self-test )              # compare:   = "--self-test"
    """
)

# P3 (dispatch shape), python: the quoted literal, which is how argparse/sys.argv
# dispatch is spelled in every tool in this tree.
P3_PY_RE = re.compile(r"""(?:"--self-test"|'--self-test')""")

# P2 (comment-stripped): strip from the first `#` to end of line, then look for the
# bare token. This is what demotes a comment-only MENTION to a non-advertiser — the
# single most important property of this predicate, and the one a naive
# `grep -l -- --self-test` gets wrong (it counted 19 shell advertisers where 17
# actually dispatch, and that miscount reached two published figures).
_COMMENT_STRIP_RE = re.compile(r"\s*#.*$")


def _strip_comments(text: str) -> str:
    return "\n".join(_COMMENT_STRIP_RE.sub("", line) for line in text.splitlines())


def advertises(path: Path) -> bool:
    """True when the file DISPATCHES on --self-test (P2 union P3), not merely mentions it."""
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return False
    if SELF_TEST_TOKEN not in text:
        return False  # cheap reject; nothing below can match
    if SELF_TEST_TOKEN in _strip_comments(text):
        return True  # P2
    if path.suffix == ".sh":
        return bool(P3_SH_RE.search(text))  # P3 (shell)
    if path.suffix == ".py":
        return bool(P3_PY_RE.search(text))  # P3 (python)
    return False


def mentions(path: Path) -> bool:
    """The naive predicate, kept ONLY so --list --explain can report mention-vs-dispatch."""
    try:
        return SELF_TEST_TOKEN in path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return False


# --------------------------------------------------------------------------------
# Runner declaration
# --------------------------------------------------------------------------------


class ConfigError(Exception):
    """Raised for anything that should exit 2 rather than fail a gate arm."""


def declared_runner(path: Path) -> str:
    """Read `# selftest-runner: <os>` from the first RUNNER_DECL_SCAN_LINES lines."""
    try:
        with path.open("r", encoding="utf-8", errors="replace") as fh:
            for i, line in enumerate(fh):
                if i >= RUNNER_DECL_SCAN_LINES:
                    break
                m = RUNNER_DECL_RE.match(line)
                if m:
                    value = m.group(1).lower()
                    if value not in RUNNERS:
                        raise ConfigError(
                            f"{path}: unknown '# selftest-runner: {m.group(1)}' — "
                            f"expected one of {', '.join(RUNNERS)}. A typo'd declaration "
                            f"must not silently fall back to '{DEFAULT_RUNNER}' and drop "
                            f"the tool off the other runner."
                        )
                    return value
    except OSError:
        pass
    return DEFAULT_RUNNER


# --------------------------------------------------------------------------------
# Manifest + exclusions
# --------------------------------------------------------------------------------

_SCOPE_DIRECTIVE_RE = re.compile(r"^#\s*scope:\s*(\S+)\s*$")


def parse_manifest(text: str) -> tuple[list[str], list[str]]:
    """-> (scope globs, expected relative paths). Raises ConfigError on a bad file."""
    scopes: list[str] = []
    paths: list[str] = []
    for lineno, raw in enumerate(text.splitlines(), start=1):
        line = raw.strip()
        if not line:
            continue
        if line.startswith("#"):
            m = _SCOPE_DIRECTIVE_RE.match(line)
            if m:
                scopes.append(m.group(1))
            continue
        if " " in line or "\t" in line:
            raise ConfigError(
                f"{MANIFEST_REL}:{lineno}: expected a bare path, got {line!r}. "
                f"Regenerate with --emit-manifest rather than hand-editing."
            )
        paths.append(line)
    if not scopes:
        raise ConfigError(
            f"{MANIFEST_REL}: no '# scope:' directive found. The manifest declares its "
            f"own scope; without one the gate would discover nothing and pass vacuously."
        )
    return scopes, paths


def parse_exclusions(text: str) -> dict[str, str]:
    """-> {relative path: reason}. An entry without a reason is a PARSE ERROR.

    Suppression must cost a justification, in the diff, attributable to an author.
    """
    out: dict[str, str] = {}
    for lineno, raw in enumerate(text.splitlines(), start=1):
        line = raw.rstrip()
        if not line.strip():
            continue
        if line.lstrip().startswith("#"):
            continue  # file header / section comment
        path, sep, reason = line.partition("#")
        path = path.strip()
        reason = reason.strip()
        if not path:
            raise ConfigError(f"{EXCLUSIONS_REL}:{lineno}: empty path in {line!r}")
        if not sep or not reason:
            raise ConfigError(
                f"{EXCLUSIONS_REL}:{lineno}: entry {path!r} carries no reason. "
                f"Format is '<path>  # <reason>'. An exclusion without a written reason "
                f"is a silent suppression, which is the failure mode this gate exists to close."
            )
        out[path] = reason
    return out


# --------------------------------------------------------------------------------
# Discovery
# --------------------------------------------------------------------------------


def _sorted_rel(paths) -> list[str]:
    return sorted({str(p) for p in paths})


def discover(
    root: Path, scopes: list[str], exclusions: dict[str, str] | None = None
) -> tuple[list[str], dict[str, list[str]]]:
    """Apply the advertise predicate over the declared scope globs.

    Returns (discovered relative paths, per-scope breakdown).

    The exclusions file is the PRECISION mechanism — the predicate is recall-biased
    on purpose (see the module docstring), so a match that is not a real dispatch is
    retired by writing it down with a reason, never by tightening the regex. Every
    exclusion is echoed on each run, and one that suppresses a REAL dispatcher raises
    a standing warning, so suppression cannot be quiet.

    A scope directive that yields ZERO advertisers is a ConfigError: a glob that
    discovers nothing is either dead or a narrowing in progress, and 'no hits' is
    never evidence of absence.
    """
    excluded = exclusions or {}
    per_scope: dict[str, list[str]] = {}
    found: set[str] = set()
    for glob in scopes:
        hits = []
        for p in sorted(root.glob(glob)):
            if not p.is_file():
                continue
            rel = p.relative_to(root).as_posix()
            if rel in excluded:
                continue
            if advertises(p):
                hits.append(rel)
                found.add(rel)
        if not hits:
            raise ConfigError(
                f"{MANIFEST_REL}: scope directive '# scope: {glob}' matched ZERO "
                f"advertising tools. A scope that discovers nothing cannot be "
                f"distinguished from a scope that was narrowed to nothing — remove the "
                f"directive deliberately (which drops its manifest paths in the same "
                f"diff) rather than leaving a dead glob standing in for coverage."
            )
        per_scope[glob] = hits
    return _sorted_rel(found), per_scope


def partition_by_runner(root: Path, discovered: list[str]) -> dict[str, list[str]]:
    buckets: dict[str, list[str]] = {r: [] for r in RUNNERS}
    for rel in discovered:
        buckets[declared_runner(root / rel)].append(rel)
    return buckets


# --------------------------------------------------------------------------------
# Workflow reference scan (Arms C + D)
# --------------------------------------------------------------------------------


def workflow_text(root: Path) -> str:
    wf_dir = root / WORKFLOW_DIR_REL
    if not wf_dir.is_dir():
        return ""
    chunks = []
    for p in sorted(wf_dir.glob("*.y*ml")):
        try:
            chunks.append(p.read_text(encoding="utf-8", errors="replace"))
        except OSError:
            continue
    return "\n".join(chunks)


def referenced_by_workflow(rel: str, wf_text: str) -> bool:
    """Loose on purpose — Arm C/D are WARN arms; a false 'covered' costs a missing
    warning, never a missing hard failure. Matches the basename with AND without its
    extension, because roster loops spell tools as bare stems (`for s in extract-usage`).
    """
    base = os.path.basename(rel)
    stem = os.path.splitext(base)[0]
    return base in wf_text or re.search(rf"(?<![\w./-]){re.escape(stem)}(?![\w-])", wf_text) is not None


def tracked_scripts(root: Path) -> list[str]:
    """Repo-wide *.sh/*.py population for Arm C.

    Prefers `git ls-files` (tracked-only, and it will not walk sibling worktrees or
    ignored trees). Falls back to a filtered os.walk when git is unavailable or the
    root is not a repo — the fallback is only reachable under --root fixtures.
    """
    try:
        out = subprocess.run(
            ["git", "-C", str(root), "ls-files", "-z", "*.sh", "*.py"],
            capture_output=True,
            text=True,
            timeout=60,
        )
        if out.returncode == 0 and out.stdout:
            rels = [r for r in out.stdout.split("\0") if r]
            return sorted(r for r in rels if not r.startswith(".claude/worktrees/"))
    except (OSError, subprocess.SubprocessError):
        pass
    skip = {".git", "node_modules", ".claude"}
    rels = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in skip]
        for fn in filenames:
            if fn.endswith((".sh", ".py")):
                rels.append((Path(dirpath) / fn).relative_to(root).as_posix())
    return sorted(rels)


# --------------------------------------------------------------------------------
# Reporting helpers
# --------------------------------------------------------------------------------


# GitHub workflow commands are emitted for REAL gate runs only. The --self-test
# fixtures below drive the arms through deliberately-failing trees, and those runs
# must not raise annotations: a GREEN job decorated with a dozen "failure"
# annotations from fixtures that were SUPPOSED to fail teaches a reviewer to ignore
# this gate's annotations, which is worse than having none. Measured on a real run
# before this guard existed.
_ANNOTATE = True


def err(msg: str) -> None:
    print(f"::error::{msg}" if _ANNOTATE else f"[err] {msg}")


def warn(msg: str) -> None:
    print(f"::warning::{msg}" if _ANNOTATE else f"[warn] {msg}")


# --------------------------------------------------------------------------------
# Context
# --------------------------------------------------------------------------------


class Ctx:
    def __init__(self, root: Path):
        self.root = root
        mf = root / MANIFEST_REL
        xf = root / EXCLUSIONS_REL
        if not mf.is_file():
            raise ConfigError(f"missing manifest: {MANIFEST_REL} (under root {root})")
        self.scopes, self.expected = parse_manifest(mf.read_text(encoding="utf-8"))
        self.exclusions = (
            parse_exclusions(xf.read_text(encoding="utf-8")) if xf.is_file() else {}
        )
        self.discovered, self.per_scope = discover(root, self.scopes, self.exclusions)
        # Scope membership is derived from the SAME globbing that discovery uses, so
        # the two can never diverge. (fnmatch is not usable here: its '*' crosses '/',
        # so 'release/tools/*.py' would wrongly claim 'release/tools/tests/x.py'.)
        self.scope_members = {
            p.relative_to(root).as_posix()
            for g in self.scopes
            for p in root.glob(g)
            if p.is_file()
        }

    def in_scope(self, rel: str) -> bool:
        return rel in self.scope_members

    def audit_exclusions(self) -> None:
        """Echo every exclusion, and flag the two shapes that must not go quiet.

        A suppression is only defensible while somebody can see it. This prints the
        full list on every reconcile, warns when an exclusion suppresses a tool that
        genuinely DISPATCHES (the F2 / F4 classes — a real self-test taken out of the
        gate, which is categorically different from retiring a comment-only regex
        match), and warns on entries whose file no longer exists so the file cannot
        silently accumulate dead suppressions.
        """
        if not self.exclusions:
            return
        print(f"Exclusions in force ({len(self.exclusions)}) — each carries a written reason:")
        for rel, reason in sorted(self.exclusions.items()):
            print(f"  EXCLUDED: {rel}  # {reason}")
        stale = [r for r in sorted(self.exclusions) if not (self.root / r).is_file()]
        if stale:
            warn(
                f"{len(stale)} exclusion(s) name a path that no longer exists; prune them "
                f"so the file does not accumulate dead suppressions: {', '.join(stale)}"
            )
        suppressed_real = []
        for rel in sorted(self.exclusions):
            p = self.root / rel
            if not p.is_file() or not self.in_scope(rel):
                continue
            try:
                text = p.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            if SELF_TEST_TOKEN in _strip_comments(text):
                suppressed_real.append(rel)
        if suppressed_real:
            warn(
                f"{len(suppressed_real)} exclusion(s) suppress an in-scope tool that "
                f"genuinely DISPATCHES on --self-test — this is a real self-test removed "
                f"from the gate, not a retired false positive. Each must name the issue "
                f"tracking its return: {', '.join(suppressed_real)}"
            )


# --------------------------------------------------------------------------------
# Modes
# --------------------------------------------------------------------------------


def mode_list(ctx: Ctx, runner: str | None, explain: bool) -> int:
    rels = ctx.discovered
    if runner:
        rels = partition_by_runner(ctx.root, ctx.discovered)[runner]
    for rel in rels:
        if explain:
            p = ctx.root / rel
            print(f"{rel}\trunner={declared_runner(p)}\tmention={mentions(p)}")
        else:
            print(rel)
    return 0


def mode_run(ctx: Ctx, runner: str, only: str | None = None) -> int:
    buckets = partition_by_runner(ctx.root, ctx.discovered)
    targets = buckets[runner]
    other = sum(len(v) for k, v in buckets.items() if k != runner)
    if only is not None:
        # --only is a PROBE affordance and nothing else. It is refused without --root
        # (enforced at the CLI), so the real gate step — which never passes --root —
        # structurally cannot use it to narrow Arm A. Its purpose is to make a
        # negative test attributable: a mutation probe that runs the whole tree cannot
        # tell "the tool I broke failed" from "something else failed in the fixture".
        if only not in ctx.discovered:
            err(
                f"--only {only} is not in the discovered set; a probe must target a tool "
                f"the gate actually covers, or it proves nothing about the gate."
            )
            return 2
        if only not in targets:
            err(f"--only {only} is not in the {runner} partition")
            return 2
        targets = [only]
    print(
        f"Arm A (EXECUTION) — runner={runner}: {len(targets)} of "
        f"{len(ctx.discovered)} discovered tools ({other} declared for another runner)."
    )
    failures: list[str] = []
    for rel in targets:
        path = ctx.root / rel
        interp = "python3" if path.suffix == ".py" else "bash"
        print(f"::group::{rel} --self-test")
        try:
            proc = subprocess.run(
                [interp, str(path), SELF_TEST_TOKEN],
                cwd=str(ctx.root),
                capture_output=True,
                text=True,
                timeout=PER_TOOL_TIMEOUT_S,
            )
            sys.stdout.write(proc.stdout)
            sys.stdout.write(proc.stderr)
            rc = proc.returncode
        except subprocess.TimeoutExpired:
            print(f"TIMEOUT after {PER_TOOL_TIMEOUT_S}s")
            rc = 124
        except OSError as exc:  # interpreter missing, permissions, ...
            print(f"INVOCATION ERROR: {exc}")
            rc = 126
        print("::endgroup::")
        # No fail-fast: one run must report every regression, not just the first.
        if rc == 0:
            print(f"OK: {rel}")
        else:
            err(f"{rel} --self-test FAILED (exit {rc})")
            failures.append(rel)
    if failures:
        print(f"ARM A FAILED: {len(failures)} of {len(targets)}")
        for rel in failures:
            print(f"  FAIL: {rel}")
        return 1
    print(f"ARM A PASSED: {len(targets)} of {len(targets)}")
    return 0


def mode_reconcile(ctx: Ctx) -> int:
    root = ctx.root
    discovered = set(ctx.discovered)
    expected = list(ctx.expected)
    failed = False
    ctx.audit_exclusions()

    # ---- Arm B (i): anti-narrowing. A manifest path still on disk MUST be discovered.
    dropped = [
        rel for rel in expected if (root / rel).is_file() and rel not in discovered
    ]
    vanished = [rel for rel in expected if not (root / rel).is_file()]
    if dropped:
        failed = True
        err(
            f"Arm B(i) MANIFEST FLOOR — {len(dropped)} committed path(s) still exist on "
            f"disk but are NO LONGER DISCOVERED. Either a '# scope:' directive was "
            f"narrowed, or the tool lost its --self-test. Neither is fixable by editing "
            f"the scope: regenerate with --emit-manifest so the removal is explicit in "
            f"the diff, directly below the directive that produced it."
        )
        for rel in dropped:
            print(f"  DROPPED: {rel}")
    if vanished:
        print(
            f"note: {len(vanished)} manifest path(s) no longer exist on disk "
            f"(deleted tools — not a failure): {', '.join(vanished)}"
        )

    # ---- Arm B (ii): a new advertiser must land in the manifest in the same PR.
    unlisted = sorted(discovered - set(expected))
    if unlisted:
        failed = True
        err(
            f"Arm B(ii) MANIFEST FLOOR — {len(unlisted)} discovered tool(s) are not in "
            f"the committed manifest. Run: python3 {Path(__file__).name} --emit-manifest"
        )
        for rel in unlisted:
            print(f"  UNLISTED: {rel}")
    if not dropped and not unlisted:
        print(f"ARM B PASSED — manifest floor reconciles ({len(expected)} paths).")

    # ---- Arm C (WARN): repo-wide advertisers.
    wf_text = workflow_text(root)
    uncovered = []
    for rel in tracked_scripts(root):
        if rel in discovered or rel in ctx.exclusions:
            continue
        if not advertises(root / rel):
            continue
        if referenced_by_workflow(rel, wf_text):
            continue
        uncovered.append(rel)
    if uncovered:
        warn(
            f"Arm C REPO-WIDE COVERAGE — {len(uncovered)} tool(s) advertise --self-test "
            f"but are neither discovered, invoked by a named workflow step, nor listed "
            f"in {EXCLUSIONS_REL} with a reason."
        )
        for rel in uncovered:
            print(f"  UNCOVERED: {rel}")
    else:
        print("ARM C PASSED — every repo-wide advertiser is discovered, wired, or excluded with a reason.")

    # ---- Arm D (WARN): test suites with no executor.
    # This is the stated coverage boundary rendered as a machine check: the tests/
    # trees are OUT of the --self-test discovery scope (they are bare-invocation entry
    # points, not --self-test dispatchers), so a suite there that no workflow runs is
    # invisible to Arms A-C. Naming them on every in-scope PR beats a coordination note.
    suites = []
    for glob in TEST_SUITE_GLOBS:
        suites.extend(p.relative_to(root).as_posix() for p in sorted(root.glob(glob)))
    unwired = [
        rel for rel in sorted(set(suites)) if not referenced_by_workflow(rel, wf_text)
    ]
    if unwired:
        warn(
            f"Arm D TEST-SUITE COVERAGE — {len(unwired)} committed test suite(s) are "
            f"referenced by no workflow. These are OUTSIDE the --self-test discovery "
            f"scope by design; wiring them is separate, tracked work."
        )
        for rel in unwired:
            print(f"  UNWIRED SUITE: {rel}")
    else:
        print("ARM D PASSED — every committed test suite is referenced by >=1 workflow.")

    # ---- Runner partition must be total and disjoint.
    buckets = partition_by_runner(root, ctx.discovered)
    total = sum(len(v) for v in buckets.values())
    if total != len(ctx.discovered):
        failed = True
        err(
            f"runner partition is not total: {total} bucketed vs "
            f"{len(ctx.discovered)} discovered"
        )
    else:
        parts = ", ".join(f"{k}={len(v)}" for k, v in buckets.items())
        print(f"Runner partition total and disjoint ({parts}).")

    return 1 if failed else 0


def render_manifest(scopes, per_scope) -> str:
    lines = [
        "# Self-test coverage manifest — the COMMITTED FLOOR for the selftest-discovery",
        "# CI gate. Regenerate with:",
        "#   python3 release/tools/check-selftest-coverage.py --emit-manifest",
        "#",
        "# Do NOT hand-edit the path list: --reconcile fails when it diverges from what",
        "# the scope directives below actually discover, in either direction.",
        "#",
        "# The '# scope:' directives and the paths they produce are co-located ON",
        "# PURPOSE. Narrowing a directive drops its paths out of the discovered set",
        "# while they remain here and on disk, which is a HARD failure (Arm B(i)) — so",
        "# greening a narrowed scope requires deleting the lines immediately below it,",
        "# in the same diff, in the reviewer's eye. Narrowing the scope is NOT a valid",
        "# disposition for a failing self-test; see the F1-F4 triage classes in the",
        "# gate's ADR.",
    ]
    for glob in scopes:
        lines.append(f"# scope: {glob}")
        lines.extend(per_scope.get(glob, []))
    return "\n".join(lines) + "\n"


def mode_emit_manifest(root: Path) -> int:
    mf = root / MANIFEST_REL
    xf = root / EXCLUSIONS_REL
    if mf.is_file():
        scopes, _ = parse_manifest(mf.read_text(encoding="utf-8"))
    else:
        scopes = list(BOOTSTRAP_SCOPE)
    exclusions = parse_exclusions(xf.read_text(encoding="utf-8")) if xf.is_file() else {}
    _, per_scope = discover(root, scopes, exclusions)
    mf.parent.mkdir(parents=True, exist_ok=True)
    mf.write_text(render_manifest(scopes, per_scope), encoding="utf-8")
    total = len({p for v in per_scope.values() for p in v})
    print(f"wrote {MANIFEST_REL} — {len(scopes)} scope directive(s), {total} path(s)")
    return 0


# --------------------------------------------------------------------------------
# --self-test  (hermetic; the engine is reflexively covered by its own gate)
# --------------------------------------------------------------------------------

_PASS_SH = '#!/usr/bin/env bash\ncase "${1:-}" in --self-test) echo ok; exit 0;; esac\n'
_FAIL_SH = (
    '#!/usr/bin/env bash\n'
    'if [ "${1:-}" = "--self-test" ]; then echo "FAIL [T-9] synthetic"; exit 1; fi\n'
)
_PASS_PY = 'import sys\nif "--self-test" in sys.argv:\n    print("ok")\n    sys.exit(0)\n'
_COMMENT_ONLY_SH = '#!/usr/bin/env bash\n# this tool has no --self-test yet\necho hi\n'
_DOCSTRING_PY = '"""Companion to the tool\'s built-in --self-test."""\nprint("hi")\n'


class _Fixture:
    """A throwaway repo-shaped tree. Never touches the real checkout."""

    def __init__(self):
        self.root = Path(tempfile.mkdtemp(prefix="selftest-cov-"))
        (self.root / "release/tools").mkdir(parents=True)
        (self.root / "core/deploy/tools").mkdir(parents=True)
        (self.root / "core/deploy/allowlists").mkdir(parents=True)
        (self.root / ".github/workflows").mkdir(parents=True)

    def write(self, rel: str, body: str) -> Path:
        p = self.root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(body, encoding="utf-8")
        return p

    def manifest(self, scopes, paths):
        body = "\n".join(f"# scope: {g}" for g in scopes) + "\n" + "\n".join(paths) + "\n"
        self.write(MANIFEST_REL, body)

    def close(self):
        shutil.rmtree(self.root, ignore_errors=True)


def _selftest() -> int:
    global _ANNOTATE
    _ANNOTATE = False  # fixture failures are expected; see the note at err()/warn()
    results: list[tuple[bool, str]] = []

    def check(ok: bool, label: str):
        results.append((bool(ok), label))

    # ---- Predicate: dispatch vs mention. This is the property whose absence cost
    # two published figures, so it is asserted first and from both sides.
    fx = _Fixture()
    try:
        p_disp = fx.write("release/tools/a.sh", _PASS_SH)
        p_cmt = fx.write("release/tools/b.sh", _COMMENT_ONLY_SH)
        p_eqf = fx.write("release/tools/c.sh", _FAIL_SH)
        p_doc = fx.write("release/tools/d.py", _DOCSTRING_PY)
        check(advertises(p_disp), "T-1 shell case-arm dispatch IS an advertiser")
        check(not advertises(p_cmt), "T-2 comment-only MENTION is NOT an advertiser")
        check(mentions(p_cmt), "T-2b the comment-only file does still MENTION the flag")
        check(advertises(p_eqf), "T-3 single-'=' comparison dispatch IS an advertiser")
        check(
            advertises(p_doc),
            "T-4 python docstring mention IS matched (documented recall bias; the "
            "exclusions file is the precision mechanism, not the regex)",
        )
    finally:
        fx.close()

    # ---- Runner declaration.
    fx = _Fixture()
    try:
        near = fx.write("release/tools/m.sh", "#!/bin/sh\n# selftest-runner: macos\n")
        far = fx.write(
            "release/tools/f.sh", "#!/bin/sh\n" + "# pad\n" * 60 + "# selftest-runner: macos\n"
        )
        bad = fx.write("release/tools/x.sh", "#!/bin/sh\n# selftest-runner: plan9\n")
        check(declared_runner(near) == "macos", "T-5 runner declared in first 40 lines is read")
        check(declared_runner(far) == DEFAULT_RUNNER, "T-6 declaration beyond line 40 is ignored")
        try:
            declared_runner(bad)
            check(False, "T-7 unknown runner value must raise, not default silently")
        except ConfigError:
            check(True, "T-7 unknown runner value raises rather than silently defaulting")
    finally:
        fx.close()

    # ---- Exclusions parsing: a reason is mandatory.
    try:
        parse_exclusions("core/x.py  # documented reason\n")
        check(True, "T-8 well-formed exclusion parses")
    except ConfigError:
        check(False, "T-8 well-formed exclusion parses")
    try:
        parse_exclusions("core/x.py\n")
        check(False, "T-9 exclusion without a reason must be a parse error")
    except ConfigError:
        check(True, "T-9 exclusion without a reason is a parse error")

    # ---- Manifest parsing: a scope directive is mandatory.
    try:
        parse_manifest("release/tools/a.sh\n")
        check(False, "T-10 manifest without a '# scope:' directive must be a parse error")
    except ConfigError:
        check(True, "T-10 manifest without a '# scope:' directive is a parse error")

    # ---- Zero-yield scope directive is a hard configuration error.
    fx = _Fixture()
    try:
        fx.write("release/tools/a.sh", _PASS_SH)
        fx.manifest(["release/tools/*.sh", "core/deploy/tools/*.py"], ["release/tools/a.sh"])
        try:
            Ctx(fx.root)
            check(False, "T-11 a scope glob matching zero advertisers must be an error")
        except ConfigError:
            check(True, "T-11 a scope glob matching zero advertisers is an error")
    finally:
        fx.close()

    # ---- Arm A: execution reports the failing tool and does not fail fast.
    fx = _Fixture()
    try:
        fx.write("release/tools/good.sh", _PASS_SH)
        fx.write("release/tools/bad.sh", _FAIL_SH)
        fx.write("core/deploy/tools/good.py", _PASS_PY)
        fx.manifest(
            ["release/tools/*.sh", "core/deploy/tools/*.py"],
            ["release/tools/bad.sh", "release/tools/good.sh", "core/deploy/tools/good.py"],
        )
        ctx = Ctx(fx.root)
        check(len(ctx.discovered) == 3, "T-12 discovery finds all three synthetic advertisers")
        check(mode_run(ctx, "ubuntu") == 1, "T-13 a broken --self-test FAILS the run (exit 1)")
    finally:
        fx.close()

    # ---- Arm A control arm: with the broken tool removed, the same run passes.
    # Without this, T-13's non-zero could be an artifact of the harness rather than
    # of the broken fixture. A failure whose control also fails proves nothing.
    fx = _Fixture()
    try:
        fx.write("release/tools/good.sh", _PASS_SH)
        fx.write("core/deploy/tools/good.py", _PASS_PY)
        fx.manifest(
            ["release/tools/*.sh", "core/deploy/tools/*.py"],
            ["release/tools/good.sh", "core/deploy/tools/good.py"],
        )
        check(mode_run(Ctx(fx.root), "ubuntu") == 0, "T-14 CONTROL: an all-green tree passes the run")
    finally:
        fx.close()

    # ---- Arm B(i): the anti-narrowing guard. THE load-bearing assertion.
    fx = _Fixture()
    try:
        fx.write("release/tools/a.sh", _PASS_SH)
        fx.write("core/deploy/tools/b.py", _PASS_PY)
        # Manifest still lists b.py, but its scope directive has been deleted —
        # exactly the shape of a narrowing that tries to green a failing tool.
        fx.manifest(["release/tools/*.sh"], ["release/tools/a.sh", "core/deploy/tools/b.py"])
        check(mode_reconcile(Ctx(fx.root)) == 1, "T-15 narrowing a scope FAILS Arm B(i)")
    finally:
        fx.close()

    # ---- Arm B(i) control: the same manifest with its scope intact passes.
    fx = _Fixture()
    try:
        fx.write("release/tools/a.sh", _PASS_SH)
        fx.write("core/deploy/tools/b.py", _PASS_PY)
        fx.manifest(
            ["release/tools/*.sh", "core/deploy/tools/*.py"],
            ["release/tools/a.sh", "core/deploy/tools/b.py"],
        )
        check(mode_reconcile(Ctx(fx.root)) == 0, "T-16 CONTROL: an un-narrowed scope passes Arm B")
    finally:
        fx.close()

    # ---- Arm B(i), second shape: the tool silently LOSES its --self-test.
    fx = _Fixture()
    try:
        fx.write("release/tools/a.sh", _PASS_SH)
        fx.write("release/tools/lost.sh", _COMMENT_ONLY_SH)
        fx.manifest(["release/tools/*.sh"], ["release/tools/a.sh", "release/tools/lost.sh"])
        check(
            mode_reconcile(Ctx(fx.root)) == 1,
            "T-17 a tool that silently lost its --self-test FAILS Arm B(i)",
        )
    finally:
        fx.close()

    # ---- Arm B(ii): a new advertiser that never reached the manifest.
    fx = _Fixture()
    try:
        fx.write("release/tools/a.sh", _PASS_SH)
        fx.write("release/tools/new.sh", _PASS_SH)
        fx.manifest(["release/tools/*.sh"], ["release/tools/a.sh"])
        check(mode_reconcile(Ctx(fx.root)) == 1, "T-18 an unlisted new advertiser FAILS Arm B(ii)")
    finally:
        fx.close()

    # ---- A manifest path whose file is gone is informational, not a failure.
    fx = _Fixture()
    try:
        fx.write("release/tools/a.sh", _PASS_SH)
        fx.manifest(["release/tools/*.sh"], ["release/tools/a.sh", "release/tools/deleted.sh"])
        check(
            mode_reconcile(Ctx(fx.root)) == 0,
            "T-19 a manifest path whose file was deleted is informational, not a failure",
        )
    finally:
        fx.close()

    # ---- Runner partition is total and disjoint.
    fx = _Fixture()
    try:
        fx.write("release/tools/u.sh", _PASS_SH)
        fx.write("release/tools/m.sh", "#!/usr/bin/env bash\n# selftest-runner: macos\n" + _PASS_SH)
        fx.manifest(["release/tools/*.sh"], ["release/tools/m.sh", "release/tools/u.sh"])
        ctx = Ctx(fx.root)
        buckets = partition_by_runner(ctx.root, ctx.discovered)
        check(
            sum(len(v) for v in buckets.values()) == len(ctx.discovered)
            and len(buckets["macos"]) == 1
            and len(buckets["ubuntu"]) == 1,
            "T-20 runner partition is total and disjoint",
        )
    finally:
        fx.close()

    # ---- Exclusions are the precision mechanism: they suppress a discovered path.
    fx = _Fixture()
    try:
        fx.write("release/tools/a.sh", _PASS_SH)
        fx.write("release/tools/falsepos.sh", _FAIL_SH)
        fx.manifest(["release/tools/*.sh"], ["release/tools/a.sh"])
        fx.write(
            EXCLUSIONS_REL,
            'release/tools/falsepos.sh  # no --self-test dispatch; P3 matched line 2 "--self-test"\n',
        )
        ctx = Ctx(fx.root)
        check(
            ctx.discovered == ["release/tools/a.sh"],
            "T-23 an excluded path is suppressed from the discovered set",
        )
        check(mode_run(ctx, "ubuntu") == 0, "T-24 Arm A is green once the false positive is excluded")
        check(mode_reconcile(ctx) == 0, "T-25 Arm B reconciles against the post-exclusion set")
    finally:
        fx.close()

    # ---- ...but suppressing a REAL dispatcher must not be quiet.
    fx = _Fixture()
    try:
        fx.write("release/tools/a.sh", _PASS_SH)
        fx.write("release/tools/real.sh", _FAIL_SH)
        fx.manifest(["release/tools/*.sh"], ["release/tools/a.sh"])
        fx.write(EXCLUSIONS_REL, "release/tools/real.sh  # suppressed without an issue\n")
        ctx = Ctx(fx.root)
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            ctx.audit_exclusions()
        out = buf.getvalue()
        check(
            "[warn]" in out and "genuinely DISPATCHES" in out,
            "T-26 excluding a genuine dispatcher raises a standing warning",
        )
        check(
            "EXCLUDED: release/tools/real.sh" in out,
            "T-27 every exclusion is echoed with its reason on each reconcile",
        )
    finally:
        fx.close()

    # ---- Scope membership must not cross a directory boundary. Regression guard for
    # ---- a real defect: fnmatch's '*' matches '/', so 'release/tools/*.py' wrongly
    # ---- claimed 'release/tools/tests/*.py' and mislabelled four out-of-scope
    # ---- exclusions as in-scope suppressions of a real dispatcher.
    fx = _Fixture()
    try:
        fx.write("release/tools/a.sh", _PASS_SH)
        fx.write("release/tools/tests/test_nested.py", _PASS_PY)
        fx.manifest(["release/tools/*.sh", "release/tools/*.py"], ["release/tools/a.sh"])
        try:
            ctx = Ctx(fx.root)
            check(False, "T-28 pre-req: 'release/tools/*.py' must yield zero here")
        except ConfigError:
            pass  # expected: the *.py scope has no in-directory advertiser
        fx.write("release/tools/b.py", _PASS_PY)
        fx.manifest(
            ["release/tools/*.sh", "release/tools/*.py"],
            ["release/tools/a.sh", "release/tools/b.py"],
        )
        ctx = Ctx(fx.root)
        check(
            ctx.in_scope("release/tools/b.py")
            and not ctx.in_scope("release/tools/tests/test_nested.py"),
            "T-28 a scope glob does not cross a directory boundary",
        )
    finally:
        fx.close()

    # ---- --only cannot narrow the real gate. This is the guard that keeps a probe
    # ---- affordance from becoming the narrowing back door AC-8 forbids.
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        rc_only = main(["--run", "--only", "release/tools/version-grammar.sh"])
    check(
        rc_only == 2 and "--only requires --root" in buf.getvalue(),
        "T-29 --only without --root is refused (it cannot narrow the real gate)",
    )

    fx = _Fixture()
    try:
        fx.write("release/tools/good.sh", _PASS_SH)
        fx.write("release/tools/bad.sh", _FAIL_SH)
        fx.manifest(["release/tools/*.sh"], ["release/tools/bad.sh", "release/tools/good.sh"])
        ctx = Ctx(fx.root)
        check(
            mode_run(ctx, "ubuntu", only="release/tools/bad.sh") == 1,
            "T-30 --only targets the broken tool and fails",
        )
        check(
            mode_run(ctx, "ubuntu", only="release/tools/good.sh") == 0,
            "T-31 CONTROL: --only on the healthy sibling passes, so T-30's failure is attributable",
        )
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            rc_undisc = mode_run(ctx, "ubuntu", only="release/tools/not-discovered.sh")
        check(
            rc_undisc == 2 and "not in the discovered set" in buf.getvalue(),
            "T-32 --only refuses a path the gate does not cover",
        )
    finally:
        fx.close()

    # ---- Arm D surveils the tests/ trees, which are OUT of the discovery scope.
    # The premise is NOT that those trees are empty of --self-test dispatch: at least
    # one committed suite does dispatch. Arm D is keyed on the tests/ NAMING
    # convention and on workflow references, never on the advertise predicate.
    fx = _Fixture()
    try:
        fx.write("release/tools/a.sh", _PASS_SH)
        fx.write("release/tools/tests/test_wired.sh", _PASS_SH)
        fx.write("release/tools/tests/test_unwired.sh", _PASS_SH)
        fx.manifest(["release/tools/*.sh"], ["release/tools/a.sh"])
        fx.write(".github/workflows/w.yml", "run: bash release/tools/tests/test_wired.sh\n")
        ctx = Ctx(fx.root)
        wf = workflow_text(fx.root)
        check(
            "release/tools/tests/test_wired.sh" not in ctx.discovered
            and "release/tools/tests/test_unwired.sh" not in ctx.discovered,
            "T-21 tests/ suites are OUTSIDE the discovery scope even when they dispatch",
        )
        check(
            referenced_by_workflow("release/tools/tests/test_wired.sh", wf)
            and not referenced_by_workflow("release/tools/tests/test_unwired.sh", wf),
            "T-22 Arm D distinguishes a wired suite from an unwired one",
        )
    finally:
        fx.close()

    # ---- Report. Annotations go back ON here: a fixture failing is expected and
    # silent, but the ENGINE failing its own fixtures must be loud — that is the one
    # condition under which this gate cannot be trusted at all.
    _ANNOTATE = True
    failed = [label for ok, label in results if not ok]
    for ok, label in results:
        print(f"{'PASS' if ok else 'FAIL'} [{label}]")
    print(f"\n{len(results) - len(failed)}/{len(results)} passed")
    if failed:
        for label in failed:
            err(f"check-selftest-coverage.py self-test FAILED: {label}")
        return 1
    return 0


# --------------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------------


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        prog="check-selftest-coverage.py",
        description="Discovery-based --self-test coverage gate with a committed manifest floor.",
    )
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--list", action="store_true", help="print the discovered set")
    g.add_argument("--run", action="store_true", help="Arm A — execute every discovered --self-test")
    g.add_argument("--reconcile", action="store_true", help="Arms B/C/D — the meta-assertions")
    g.add_argument("--emit-manifest", action="store_true", help="regenerate the committed manifest")
    g.add_argument("--self-test", action="store_true", help="this engine's own hermetic fixtures")
    ap.add_argument("--runner", choices=RUNNERS, help="partition the discovered set by runner")
    ap.add_argument("--root", help="operate against an alternative tree (probes only)")
    ap.add_argument(
        "--only",
        help="PROBE ONLY — restrict --run to one discovered path. Refused without --root, "
        "so the real gate step cannot use it to narrow Arm A.",
    )
    ap.add_argument("--explain", action="store_true", help="--list: annotate runner + mention")
    args = ap.parse_args(argv)

    if args.self_test:
        return _selftest()

    if args.only and not args.root:
        err(
            "--only requires --root. It exists so a mutation probe can attribute a "
            "failure to the tool it broke; against the real checkout it would be a "
            "narrowing of the gate, which is never a valid disposition."
        )
        return 2

    root = Path(args.root).resolve() if args.root else Path(__file__).resolve().parents[2]
    if not root.is_dir():
        err(f"--root {root} is not a directory")
        return 2

    try:
        if args.emit_manifest:
            return mode_emit_manifest(root)
        ctx = Ctx(root)
        if args.list:
            return mode_list(ctx, args.runner, args.explain)
        if args.run:
            return mode_run(ctx, args.runner or DEFAULT_RUNNER, args.only)
        if args.reconcile:
            return mode_reconcile(ctx)
    except ConfigError as exc:
        err(str(exc))
        return 2
    return 2


if __name__ == "__main__":
    sys.exit(main())
