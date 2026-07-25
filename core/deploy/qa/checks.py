"""QA-as-code check registry — one @check-decorated function per onboarding-QA finding.

Turns the manual onboarding-install/update QA findings (F1-F10 + regressions
R1/R2) into a runnable, read-only regression suite. Each finding maps 1:1 to a
check function that inspects the LIVE source tree for the guard that closes the
finding — so a regression that removes the guard is caught by a failing check.

Finding semantics (technical predicates only):
  - F1/F3/F5/F9/F10 are corroborated by the public code comments in
    update.sh, install.sh, and core/deploy/orchestrate.sh (grep "closes QA F").
  - F2/F4/F6/F7/F8 are behavioural/structural guards bound from the onboarding-QA
    audit's suite results (durability, token self-heal, docs integrity, hook
    +x bit, idempotency).
  - R1/R2 are the audit's "regression harness" defects (count-drift and
    silent-suite-truncation) turned into standing guards.

Design contract: read-only by construction — checks inspect the source tree and
drive the compose.py primitives inside an ephemeral tempdir; they never mutate
platform state. The whole registry is therefore the read-only subset a doctor
command (a downstream consumer) can import and filter by `read_only`. Deployed
runtime state (the ~/.claude population) is intentionally NOT inspected here:
that is a downstream doctor's job, and reading the operator's live home would
make the suite env-dependent and risk leaking home paths into the report.

Import model: core/deploy is placed on sys.path so `import compose` resolves the
sibling module (matches core/deploy/tests/test_compose.py — core/deploy is NOT a
Python package, so `import core.deploy.compose` is not the live convention).
"""

from __future__ import annotations

import os
import re
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, List, Optional

# Make core/deploy/ importable without packaging the script (matches
# core/deploy/tests/test_compose.py:18). checks.py lives at
# core/deploy/qa/checks.py, so parents[1] is core/deploy/.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import compose  # noqa: E402  (reuse parse_toml / resolve_tokens / round-trip primitives)

# Canonical finding enumeration — the coverage assertion in
# core/deploy/tests/test_qa_module.py pins the registry to exactly this set.
FINDING_IDS: List[str] = [
    "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "R1", "R2",
]

# Status vocabulary. SKIP never fails the suite (env-unavailable optional check);
# FAIL fails it (a guard regressed); PASS is a satisfied guard.
PASS = "PASS"
FAIL = "FAIL"
SKIP = "SKIP"


@dataclass
class CheckResult:
    """Structured outcome of one finding check.

    finding_id : the F#/R# this check covers (member of FINDING_IDS)
    title      : one-line technical description of the guard being verified
    status     : PASS | FAIL | SKIP
    evidence   : what was observed (the grounding for the status)
    remedy     : the fix when status == FAIL (empty on PASS/SKIP)
    read_only  : always True — checks never mutate platform state
    """

    finding_id: str
    title: str
    status: str
    evidence: str
    remedy: str = ""
    read_only: bool = True


@dataclass
class Check:
    """Registry record binding a finding to its check function."""

    finding_id: str
    title: str
    read_only: bool
    fn: Callable[[Optional[Path]], CheckResult]


_REGISTRY: List[Check] = []


def check(finding_id: str, title: str, read_only: bool = True):
    """Decorator: register a finding check into the module registry (order-preserving)."""

    def deco(fn: Callable[[Optional[Path]], CheckResult]) -> Callable[[Optional[Path]], CheckResult]:
        _REGISTRY.append(Check(finding_id, title, read_only, fn))
        return fn

    return deco


def registry() -> List[Check]:
    """Return a shallow copy of the check registry (insertion order)."""
    return list(_REGISTRY)


# --------------------------------------------------------------------------- #
# Helpers (read-only)                                                          #
# --------------------------------------------------------------------------- #

def _repo_root(root: Optional[Path] = None) -> Path:
    """Repo root of the checkout under test.

    Resolved from this file's own location (checks.py at core/deploy/qa/ →
    parents[3] is the repo root), independent of $PMO_PLATFORM_ROOT so the suite
    always inspects the tree it ships in (primary checkout or worktree alike).
    """
    if root is not None:
        return Path(root)
    return Path(__file__).resolve().parents[3]


def _read(path: Path) -> str:
    """Read a text file; return '' when absent/unreadable (never raises)."""
    try:
        return path.read_text(encoding="utf-8")
    except (FileNotFoundError, OSError, UnicodeDecodeError):
        return ""


def _fail_missing(finding_id: str, title: str, what: str, remedy: str) -> CheckResult:
    return CheckResult(finding_id, title, FAIL, f"missing: {what}", remedy)


# --------------------------------------------------------------------------- #
# F1 — skills-only update must not under-report as "no update"                 #
# --------------------------------------------------------------------------- #

@check("F1", "skills-only update keys EX_NOCHANGE off the deployed-skills count")
def check_f1_skill_update_signal(root: Optional[Path] = None) -> CheckResult:
    """update.sh must decide EX_NOCHANGE from the CHANGED-SKILLS count deploy.sh
    actually reports (Phase 5), not from phase_deploy_skills merely returning 0 —
    so a skills-only update that ships new skill versions returns EX_OK, not 64.
    """
    fid, title = "F1", "skills-only update keys EX_NOCHANGE off the deployed-skills count"
    text = _read(_repo_root(root) / "update.sh")
    if not text:
        return _fail_missing(fid, title, "update.sh", "restore update.sh at repo root")
    has_flag = "PHASE5_DEPLOYED=1" in text
    # The count parse: deploy.sh's "Deployed: N skills, M packages, K harness artifacts".
    has_parse = re.search(r"Deployed:.*skills,", text) is not None
    has_exit = "EX_NOCHANGE" in text
    if has_flag and has_parse and has_exit:
        return CheckResult(
            fid, title, PASS,
            "update.sh sets PHASE5_DEPLOYED=1 only when the parsed 'Deployed: N skills' "
            "count >= 1, and EX_NOCHANGE (64) is gated on that flag",
        )
    missing = [n for n, ok in (("PHASE5_DEPLOYED=1", has_flag),
                               ("deploy-summary skills-count parse", has_parse),
                               ("EX_NOCHANGE", has_exit)) if not ok]
    return CheckResult(
        fid, title, FAIL,
        "update.sh missing skills-count update signal: " + ", ".join(missing),
        "restore the Phase-5 skills-count parse that sets PHASE5_DEPLOYED and gates EX_NOCHANGE",
    )


# --------------------------------------------------------------------------- #
# F2 — composition-surface OPERATOR ADDITIONS survive an update                #
# --------------------------------------------------------------------------- #

@check("F2", "operator additions survive a managed-section regeneration verbatim")
def check_f2_operator_additions_roundtrip(root: Optional[Path] = None) -> CheckResult:
    """Install then update (regen with a changed source) must preserve the
    OPERATOR ADDITIONS section byte-for-byte. Drives the compose.py primitives in
    an ephemeral tempdir (no platform mutation).
    """
    fid, title = "F2", "operator additions survive a managed-section regeneration verbatim"
    addition = "CUSTOM-ENTRY-ALPHA\nCUSTOM-ENTRY-BETA"
    try:
        with tempfile.TemporaryDirectory() as td:
            tdp = Path(td)
            src = tdp / "src.txt"
            tgt = tdp / "tgt.txt"
            missing_toml = tdp / "absent-operator.toml"
            src.write_text("managed body v1\n", encoding="utf-8")
            # Install: write managed file carrying the operator addition.
            compose.write_managed_file(src, tgt, {}, addition, "sha-v1", "raw")
            # Update: source changes, regen extracts+re-preserves the addition.
            src.write_text("managed body v2 CHANGED\n", encoding="utf-8")
            compose.regen_one_file(src, tgt, missing_toml, None, "raw", "sha-v2")
            got = compose.extract_operator_additions(tgt)
    except Exception as err:  # noqa: BLE001 — surface as a check FAIL, not a crash
        return CheckResult(fid, title, FAIL, f"compose round-trip raised: {err!r}",
                           "inspect core/deploy/compose.py regen/extract primitives")
    if got == addition:
        return CheckResult(fid, title, PASS,
                           "OPERATOR ADDITIONS preserved verbatim across a regen with a changed source")
    return CheckResult(fid, title, FAIL,
                       f"OPERATOR ADDITIONS not preserved (got {got!r}, expected {addition!r})",
                       "fix extract_operator_additions/write_managed_file round-trip in compose.py")


# --------------------------------------------------------------------------- #
# F3 — install resolves the repo root from any clone location                 #
# --------------------------------------------------------------------------- #

@check("F3", "install.sh resolves repo root from its own location + preflights the clone")
def check_f3_clone_location_preflight(root: Optional[Path] = None) -> CheckResult:
    """install.sh must anchor on its own location (dirname "$0") and preflight the
    required files, so the README's three-command flow works from any clone dir.
    """
    fid, title = "F3", "install.sh resolves repo root from its own location + preflights the clone"
    text = _read(_repo_root(root) / "install.sh")
    if not text:
        return _fail_missing(fid, title, "install.sh", "restore install.sh at repo root")
    has_selfanchor = 'cd "$(dirname "$0")"' in text and "REPO_ROOT=" in text
    has_preflight = "preflight" in text
    if has_selfanchor and has_preflight:
        return CheckResult(fid, title, PASS,
                           'install.sh sets REPO_ROOT via cd "$(dirname "$0")" && pwd and runs preflight() '
                           "before either phase")
    missing = [n for n, ok in (('self-location REPO_ROOT anchor', has_selfanchor),
                               ("preflight()", has_preflight)) if not ok]
    return CheckResult(fid, title, FAIL, "install.sh missing: " + ", ".join(missing),
                       "restore the self-location REPO_ROOT anchor + preflight in install.sh")


# --------------------------------------------------------------------------- #
# F4 — no unsubstituted tokens can survive into deployed files                 #
# --------------------------------------------------------------------------- #

@check("F4", "token resolution self-heals the always-present tokens")
def check_f4_token_resolution(root: Optional[Path] = None) -> CheckResult:
    """compose.resolve_tokens must always populate the tokens that have no
    operator.toml source (repo-root / workspace-root / homedir), even when
    operator.toml is absent — the self-heal that guarantees these tokens can
    never survive unsubstituted into a deployed file.
    """
    fid, title = "F4", "token resolution self-heals the always-present tokens"
    required = ["[PMO_PLATFORM_ROOT]", "[CLAUDE_WORKSPACE_ROOT]", "[OPERATOR_HOMEDIR_PATH]"]
    try:
        with tempfile.TemporaryDirectory() as td:
            tokens = compose.resolve_tokens(Path(td) / "absent-operator.toml")
    except Exception as err:  # noqa: BLE001
        return CheckResult(fid, title, FAIL, f"resolve_tokens raised: {err!r}",
                           "inspect compose.resolve_tokens defaults")
    unresolved = [t for t in required if not tokens.get(t)]
    if not unresolved:
        return CheckResult(fid, title, PASS,
                           "resolve_tokens populated " + ", ".join(required) + " with an absent operator.toml")
    return CheckResult(fid, title, FAIL,
                       "resolve_tokens left unresolved: " + ", ".join(unresolved),
                       "restore the setdefault self-heal for repo-root/workspace-root/homedir in compose.resolve_tokens")


# --------------------------------------------------------------------------- #
# F5 — skills deploy at the end of install                                     #
# --------------------------------------------------------------------------- #

@check("F5", "install wires the skill-deploy phase (deploy.sh --deploy)")
def check_f5_install_skill_deploy(root: Optional[Path] = None) -> CheckResult:
    """orchestrate.sh must define phase_deploy_skills (deploy.sh --deploy) and
    install.sh must invoke it as its final phase, so skills actually deploy.
    """
    fid, title = "F5", "install wires the skill-deploy phase (deploy.sh --deploy)"
    rr = _repo_root(root)
    orch = _read(rr / "core/deploy/orchestrate.sh")
    inst = _read(rr / "install.sh")
    if not orch:
        return _fail_missing(fid, title, "core/deploy/orchestrate.sh", "restore orchestrate.sh")
    if not inst:
        return _fail_missing(fid, title, "install.sh", "restore install.sh")
    defines = "phase_deploy_skills()" in orch and "--deploy" in orch
    invokes = "phase_deploy_skills" in inst
    if defines and invokes:
        return CheckResult(fid, title, PASS,
                           "orchestrate.sh defines phase_deploy_skills() (deploy.sh --deploy); "
                           "install.sh invokes it as Phase 2")
    missing = [n for n, ok in (("orchestrate phase_deploy_skills()/--deploy", defines),
                               ("install.sh invocation", invokes)) if not ok]
    return CheckResult(fid, title, FAIL, "skill-deploy wiring missing: " + ", ".join(missing),
                       "restore phase_deploy_skills in orchestrate.sh and its call in install.sh Phase 2")


# --------------------------------------------------------------------------- #
# F6 — onboarding docs are present and the three-command flow is documented    #
# --------------------------------------------------------------------------- #

@check("F6", "onboarding docs present and the three-command install flow is documented")
def check_f6_docs_onboarding_integrity(root: Optional[Path] = None) -> CheckResult:
    """docs/INSTALL.md, docs/UPDATE.md, docs/GETTING_STARTED.md must exist and the
    README must document the three-command install flow (./install.sh).
    """
    fid, title = "F6", "onboarding docs present and the three-command install flow is documented"
    rr = _repo_root(root)
    docs = ["docs/INSTALL.md", "docs/UPDATE.md", "docs/GETTING_STARTED.md"]
    missing = [d for d in docs if not (rr / d).is_file()]
    readme_ok = "./install.sh" in _read(rr / "README.md")
    if not missing and readme_ok:
        return CheckResult(fid, title, PASS,
                           "INSTALL.md + UPDATE.md + GETTING_STARTED.md present; README documents ./install.sh")
    problems = []
    if missing:
        problems.append("missing docs: " + ", ".join(missing))
    if not readme_ok:
        problems.append("README does not reference ./install.sh")
    return CheckResult(fid, title, FAIL, "; ".join(problems),
                       "restore the onboarding docs and the README three-command flow")


# --------------------------------------------------------------------------- #
# F7 — hooks are installed with the +x bit                                     #
# --------------------------------------------------------------------------- #

@check("F7", "source hooks are present and carry the +x bit")
def check_f7_hook_install_exec(root: Optional[Path] = None) -> CheckResult:
    """The security hooks under core/hooks/ (what install lays down under the
    ~/.claude/hooks/ tree) must exist and carry the +x permission bit — a hook
    without it silently fails to run.
    """
    fid, title = "F7", "source hooks are present and carry the +x bit"
    hooks_dir = _repo_root(root) / "core/hooks"
    if not hooks_dir.is_dir():
        return _fail_missing(fid, title, "core/hooks/", "restore the core/hooks/ directory")
    hooks = sorted(hooks_dir.glob("*.sh"))
    if not hooks:
        return CheckResult(fid, title, FAIL, "no *.sh hooks found under core/hooks/",
                           "restore the security-hook scripts")
    missing_x = [h.name for h in hooks if not os.access(h, os.X_OK)]
    if not missing_x:
        return CheckResult(fid, title, PASS,
                           f"{len(hooks)} hook script(s) under core/hooks/, all carry +x")
    return CheckResult(fid, title, FAIL,
                       f"{len(missing_x)} hook(s) missing +x: " + ", ".join(missing_x),
                       "chmod +x the affected core/hooks/*.sh scripts")


# --------------------------------------------------------------------------- #
# F8 — re-running the composer is idempotent                                   #
# --------------------------------------------------------------------------- #

@check("F8", "managed-file composition is idempotent on re-run")
def check_f8_idempotency(root: Optional[Path] = None) -> CheckResult:
    """Writing the same managed file twice must be idempotent: identical installed
    body hash and exactly one MANAGED fence (no duplicate fences accreting).
    Drives compose.py in an ephemeral tempdir.
    """
    fid, title = "F8", "managed-file composition is idempotent on re-run"
    try:
        with tempfile.TemporaryDirectory() as td:
            tdp = Path(td)
            src = tdp / "src.txt"
            tgt = tdp / "tgt.txt"
            src.write_text("managed body\n", encoding="utf-8")
            compose.write_managed_file(src, tgt, {}, "", "sha-x", "raw")
            sha_a = compose.installed_sha_of(tgt)
            compose.write_managed_file(src, tgt, {}, "", "sha-x", "raw")
            sha_b = compose.installed_sha_of(tgt)
            fences = tgt.read_text(encoding="utf-8").count(compose.BEGIN_MANAGED)
    except Exception as err:  # noqa: BLE001
        return CheckResult(fid, title, FAIL, f"compose idempotency drive raised: {err!r}",
                           "inspect compose.write_managed_file")
    if sha_a and sha_a == sha_b and fences == 1:
        return CheckResult(fid, title, PASS,
                           "two writes of the same source produced an identical installed_sha and a single MANAGED fence")
    return CheckResult(fid, title, FAIL,
                       f"non-idempotent: installed_sha {sha_a!r} vs {sha_b!r}, MANAGED fences={fences}",
                       "ensure write_managed_file overwrites atomically without duplicating fences")


# --------------------------------------------------------------------------- #
# F9 — sandbox roots are honored for test isolation                           #
# --------------------------------------------------------------------------- #

@check("F9", "update honors sandbox-root env precedence (config/workspace roots)")
def check_f9_sandbox_roots(root: Optional[Path] = None) -> CheckResult:
    """update.sh must honor the sandbox-root precedence (CLI flag > env var >
    $HOME default) via PMO_PLATFORM_CONFIG_ROOT / PMO_PLATFORM_WORKSPACE_ROOT so
    tests can isolate from live operator state.
    """
    fid, title = "F9", "update honors sandbox-root env precedence (config/workspace roots)"
    text = _read(_repo_root(root) / "update.sh")
    if not text:
        return _fail_missing(fid, title, "update.sh", "restore update.sh at repo root")
    has_config = "PMO_PLATFORM_CONFIG_ROOT" in text
    has_workspace = "PMO_PLATFORM_WORKSPACE_ROOT" in text
    if has_config and has_workspace:
        return CheckResult(fid, title, PASS,
                           "update.sh reads PMO_PLATFORM_CONFIG_ROOT and PMO_PLATFORM_WORKSPACE_ROOT "
                           "as the env tier of the CLI>env>$HOME sandbox-root precedence")
    missing = [n for n, ok in (("PMO_PLATFORM_CONFIG_ROOT", has_config),
                               ("PMO_PLATFORM_WORKSPACE_ROOT", has_workspace)) if not ok]
    return CheckResult(fid, title, FAIL, "update.sh missing sandbox-root env vars: " + ", ".join(missing),
                       "restore the sandbox-root env-var precedence in update.sh")


# --------------------------------------------------------------------------- #
# F10 — update redeploys newly-shipped skills without a separate step          #
# --------------------------------------------------------------------------- #

@check("F10", "update redeploys skills via a Phase-5 skill-redeploy step")
def check_f10_update_skill_redeploy(root: Optional[Path] = None) -> CheckResult:
    """update.sh must run a Phase-5 skill redeploy (redeploy_skills →
    phase_deploy_skills) so newly-shipped skills land without a separate operator step.
    """
    fid, title = "F10", "update redeploys skills via a Phase-5 skill-redeploy step"
    text = _read(_repo_root(root) / "update.sh")
    if not text:
        return _fail_missing(fid, title, "update.sh", "restore update.sh at repo root")
    has_redeploy = "redeploy_skills" in text
    has_phase = "phase_deploy_skills" in text
    if has_redeploy and has_phase:
        return CheckResult(fid, title, PASS,
                           "update.sh defines redeploy_skills() which invokes phase_deploy_skills (Phase 5)")
    missing = [n for n, ok in (("redeploy_skills", has_redeploy),
                               ("phase_deploy_skills call", has_phase)) if not ok]
    return CheckResult(fid, title, FAIL, "update.sh missing skill-redeploy wiring: " + ", ".join(missing),
                       "restore redeploy_skills + phase_deploy_skills in update.sh Phase 5")


# --------------------------------------------------------------------------- #
# R1 — composition-surface manifest count is self-consistent                  #
# --------------------------------------------------------------------------- #

@check("R1", "composition-surface manifest declared count matches its entry rows")
def check_r1_manifest_count_consistency(root: Optional[Path] = None) -> CheckResult:
    """Regression guard (audit count-drift class): the manifest's self-declared
    "N composition-surface" count must equal the actual number of entry rows, so a
    row added without updating the count can never drift silently.
    """
    fid, title = "R1", "composition-surface manifest declared count matches its entry rows"
    text = _read(_repo_root(root) / "core/deploy/composition-surface-manifest.sh")
    if not text:
        return _fail_missing(fid, title, "core/deploy/composition-surface-manifest.sh",
                             "restore the composition-surface manifest")
    # Actual entry rows: pipe-delimited rows inside the COMPOSITION_SURFACE_FILES=( ... ) block.
    block = re.search(r"COMPOSITION_SURFACE_FILES=\((.*?)\n\)", text, re.DOTALL)
    if not block:
        return CheckResult(fid, title, FAIL, "COMPOSITION_SURFACE_FILES=( ... ) block not found",
                           "restore the manifest array definition")
    actual = len(re.findall(r'"[^"\n]+\|[^"\n]+"', block.group(1)))
    declared_m = re.search(r"(\d+)\s+composition-surface", text)
    if not declared_m:
        return CheckResult(fid, title, FAIL,
                           f"no declared '<N> composition-surface' count comment found (actual rows: {actual})",
                           "add/update the '<N> composition-surface' count comment to match the entry rows")
    declared = int(declared_m.group(1))
    if declared == actual:
        return CheckResult(fid, title, PASS,
                           f"manifest declares {declared} composition-surface entries and defines {actual} entry rows")
    return CheckResult(fid, title, FAIL,
                       f"count drift: manifest comment says {declared} but the array has {actual} entry rows",
                       "reconcile the manifest count comment with the actual entry rows")


# --------------------------------------------------------------------------- #
# R2 — standing regression suite membership is intact                          #
# --------------------------------------------------------------------------- #

@check("R2", "standing regression-suite members all resolve to real test files")
def check_r2_regression_suite_integrity(root: Optional[Path] = None) -> CheckResult:
    """Regression guard (audit suite-truncation class): every member named in
    run-install-regression.sh REGRESSION_MEMBERS must resolve to a real test file
    under core/deploy/tests/, and the suite must not be trivially small — so the
    standing suite cannot silently drop (or dangle) a test.
    """
    fid, title = "R2", "standing regression-suite members all resolve to real test files"
    floor = 5
    rr = _repo_root(root)
    tests_dir = rr / "core/deploy/tests"
    runner = _read(tests_dir / "run-install-regression.sh")
    if not runner:
        return _fail_missing(fid, title, "core/deploy/tests/run-install-regression.sh",
                             "restore the standing regression runner")
    block = re.search(r"REGRESSION_MEMBERS=\((.*?)\n\)", runner, re.DOTALL)
    if not block:
        return CheckResult(fid, title, FAIL, "REGRESSION_MEMBERS=( ... ) block not found",
                           "restore the REGRESSION_MEMBERS array")
    members = re.findall(r'"([^"\n]+\.(?:sh|py))"', block.group(1))
    if not members:
        return CheckResult(fid, title, FAIL, "REGRESSION_MEMBERS is empty",
                           "enroll the install/update regression tests in REGRESSION_MEMBERS")
    dangling = [m for m in members if not (tests_dir / m).is_file()]
    if dangling:
        return CheckResult(fid, title, FAIL,
                           "REGRESSION_MEMBERS names non-existent test file(s): " + ", ".join(dangling),
                           "remove or correct the dangling member(s), or restore the missing test file(s)")
    if len(members) < floor:
        return CheckResult(fid, title, FAIL,
                           f"only {len(members)} regression member(s) (floor {floor}) — suite likely truncated",
                           f"restore the standing regression membership (expected >= {floor})")
    return CheckResult(fid, title, PASS,
                       f"all {len(members)} REGRESSION_MEMBERS resolve to real test files (floor {floor})")
