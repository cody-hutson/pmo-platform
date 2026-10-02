#!/usr/bin/env python3
"""Assert every workflow's `gate-efficacy:` header agrees with its own trigger.

WHAT THIS GUARDS, AND WHY IT EXISTS
-----------------------------------
`core/standards/gate-efficacy-standard.md` Requirement (b) obliges every workflow to
declare its skip semantics in a machine-greppable header, and § Verdict-Input Closure
makes `skip-semantics=absent-is-pass` a CLAIM ABOUT COVERAGE rather than a formality.
Two spellings of that claim exist and they are mutually exclusive:

    always-reports=yes            <=>  the workflow carries NO on.<event>.paths filter
    skip-semantics=absent-is-pass <=>  the workflow DOES carry one

Before this suite, nothing in the tree asserted that biconditional. The header and the
trigger were two independent strings that a reader kept in agreement by hand, so the
change that breaks the invariant — adding a `paths:` key without touching the header,
or deleting one and leaving `skip-semantics=absent-is-pass` behind — was exactly the
change no gate could see. A declaration nothing checks decays into a comment.

SECOND INVARIANT — THE DECLARATION'S REACH IS THE JOB, NOT THE FILE
------------------------------------------------------------------
The same standard states the obligation as "every automated-assertion gate MUST
self-declare its enforcement posture," and defines that gate's surface as a workflow
JOB. A workflow can therefore satisfy everything above — a well-formed header, agreeing
with its own trigger — while publishing check-runs that no header names at all. That is
a third class, distinct from declared-but-unregistered, and the reader above was blind
to it by construction: it grades headers and never opens the `jobs:` block.

    every job publishing a named check-run, in a workflow whose headers name at
    least one check-run, is itself named by one of those headers

The scope clause is not a convenience. A workflow whose headers name NO check-run
declares its posture by CONTAINMENT — one gate, one file, no ambiguity — and firing
there would flag eleven conforming workflows in this tree. The scope IS the specificity
arm, made structural. Matrix jobs are resolved to their expanded check-run names before
the comparison, because a matrix job publishes one check-run per leg and its raw
`${{ matrix.* }}` template matches no declared context.

THIRD INVARIANT — A `required` POSTURE MUST NAME THE SURFACE THAT DELIVERS IT
----------------------------------------------------------------------------
Operator decision D-13 fixes what `posture=required` MEANS: a red verdict BLOCKS THE
MERGE. On this host exactly one mechanism delivers that, and it is branch protection's
`required_status_checks.contexts`. A declaration may therefore not claim `required`
while naming an enforcement surface that cannot block — `ci-enforce` turns a check red,
and a red non-required check does not stop anybody merging.

    posture=required*  =>  the declaration names `branch-protection`

The qualifier is included: `required(warn-mode-initial)` and `required(enforce; ratified
…)` are `required` postures with a shakedown note attached, not a third posture. The
match is on the LEADING token for exactly the reason `reconcile-gate-posture.py` records
in its own docstring — a space-intolerant match silently drops the compound form, which
is how an earlier measurement of this same population came back one short.

WHY THIS ARM, AND WHY IT DID NOT EXIST. The two invariants above grade a declaration
against its file's TRIGGER and a job against its file's DECLARATION SET. Neither reads
the posture and the enforcement key TOGETHER, so a declaration could claim an
enforcement the repository was not delivering and pass every arm in this file. That is
not a wiring accident: it is a MISSING PREDICATE, and the file carrying it was
`install-tests.yml` — the workflow that RUNS this very suite. The conformance ratchet
executed inside the defect it would have caught, and reported green, because
posture/enforcement agreement was the one pairing it never graded.

The surface test is `startswith("branch-protection")`, character-for-character the test
`core/deploy/tools/reconcile-gate-posture.py` already applies when it builds its declared
set. That agreement is deliberate and load-bearing: two readers of one field that
disagreed on what satisfies it would put this suite and the reconciliation report into
contradiction over the same header, which is the drift the single-parser coupling
between these two files exists to prevent.

This arm is STATIC. It grades the declaration against itself and never reads live
branch protection — an out-of-tree verdict input must not gate a merge (Requirement (b)),
which is precisely why the reconciler that DOES read it is report-only. The two are
complements: this arm asserts the claim is well-formed, the reconciler asserts it is
true today.

FOURTH INVARIANT — A DECLARED POPULATION RESOLVES, AND IS THE ONE THE CHECK SCANS
--------------------------------------------------------------------------------
Requirement (b) gives a gate whose verdict is a claim over a file-root population a
`#   population:` continuation line — its roots, its member filter, its exemption
unit — and Requirement (c) § Population shortfall audits it. This arm grades every such
declaration, on a workflow or on a `core/deploy/deploy.sh` check, against a FOURTH
oracle, the TRACKED TREE:

    every declared root resolves to at least one tracked file under the declared
    filter; on deploy.sh the declaration's `roots=@<array>` names the array its
    check's `_population_resolve` call passes, with the same filter, and a
    `_population_report` call reports the result

A root that yields nothing is a finding unless it sits on POPULATION_RESIDUALS, whose
every entry must still reproduce, and the worked-reference declarations (Checks 25 and
31) must be present. What this arm cannot see — a gate that declares nothing, a narrowed
declaration, a list/glob, sub-file or rows population — the standard enumerates; it is
not implied here.

FIFTH INVARIANT — THE CENSUS MATCHES THE POPULATIONS IT RECORDS
---------------------------------------------------------------
core/standards/gate-efficacy-standard.md § Exit-consumer and executor census renders the
Requirement (c) population record for three populations no single file enumerates: the
drift engine's exit consumers, the workflows' binary-zero exit-status consumers, and the
test suites with their executors. A census nothing re-derives goes stale silently, so every
run re-derives each population and grades the record against it. The drift-engine and
workflow records are graded as SETS — every live member has exactly one row, no row names a
member that is gone, `examined:` equals the rows, and each row carries a token from its
record's closed set and a reason. The executor record lists the zero-executor suites: a
listed suite that has gained an executor fails, while a NEW zero-executor suite, or a listed
one whose row was deleted, is reported and not failed — executor coverage as a merge gate
is the self-test coverage checker's decision.

EXIT CONTRACT
-------------
    0  every workflow conforms AND the anti-vacuity harness passed
    1  at least one declared-vs-actual mismatch (a workflow with no header, a job
       publishing a check-run its workflow's headers do not name, a `required` posture
       naming a surface that cannot block, a stale residual-ledger entry, a malformed
       or zero-yield population declaration, a declared population the check never
       resolves or reports, an absent worked-reference declaration, a stale
       population-ledger entry, a census row missing, stale or unclassified, or a census
       `examined:` that disagrees with its rows)
    2  the harness itself could not assert — an unreadable population, a partition too
       small to build a mutation arm, a mutation the detector failed to flag, an empty
       population-declaration set, a `git ls-files` failure, an unreadable standard or
       census input, a census population that re-derives empty, or a census arm that
       fails to discriminate. Fail-closed: a probe that cannot demonstrate it
       discriminates reports 2 rather than the clean it can no longer distinguish from a
       real one.

THE HARNESS RUNS BY DEFAULT, ON EVERY INVOCATION — deliberately, and it is the whole
reason to trust the zero. A falsification harness behind a flag nothing passes runs
exactly once, at implementation, and thereafter certifies nothing. Every mutation arm
below that proves a LIVE population exists is derived from that population at run time
rather than from hardcoded workflow names, so a rename cannot quietly empty it, and an
empty partition is a reported NOSET rather than a skipped arm. The population arms that
prove the DETECTOR discriminates run on synthetic declarations instead, so reaching the
state they police — an empty residual ledger, a narrowed exemption unit — cannot empty
them.

Hermetic: reads the workflow files, `core/deploy/deploy.sh`,
`core/standards/gate-efficacy-standard.md`, the install-regression runner and the tracked
tools that name the drift engine; lists tracked paths with `git ls-files` (read-only);
mutates only in-memory copies; writes nothing.
"""

from __future__ import annotations

import ast
import fnmatch
import re
import shlex
import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover - environment guard
    print("FAIL: PyYAML is required; the trigger read must be STRUCTURAL. "
          "A raw-text scan for 'paths:' over-counts comment and run:-body "
          "occurrences and would make this gate wrong rather than absent.",
          file=sys.stderr)
    sys.exit(2)

HEADER_RE = re.compile(r"^#\s*gate-efficacy:\s*(?P<fields>.*)$")
FILTER_KEYS = {"paths", "paths-ignore"}

# A declaration binds to a check-run through the quoted value of its enforcement
# field — `enforcement=branch-protection:"<check name>"`. Both live spellings of the
# key are read: `enforcement=` is the form the standard fixes and the live majority
# uses, `enforcement-surface=` is a legacy variant on two sites. Reading only one
# would make the per-job arm's denominator quietly wrong rather than absent.
ENFORCEMENT_KEYS = ("enforcement", "enforcement-surface")
QUOTED_RE = re.compile(r'"([^"]+)"')
MATRIX_REF_RE = re.compile(r"\$\{\{\s*matrix\.([A-Za-z0-9_-]+)\s*\}\}")
ANY_EXPR_RE = re.compile(r"\$\{\{.*?\}\}")

# `required`, or `required(<qualifier>)`. Anchored, and the qualifier must open with a
# literal `(`, so a hypothetical future posture word that merely BEGINS with the letters
# — `required-on-release`, say — is NOT silently swept into the required class.
POSTURE_REQUIRED_RE = re.compile(r"^required(?:\(|$)")

# The only enforcement surface that makes a red verdict block a merge on this host.
BLOCKING_SURFACE = "branch-protection"

# RESIDUALS — declarations that fail the posture/enforcement arm and are NOT this
# change's to fix. Both claim `required(warn-mode-initial)` while naming
# `path-filtered`, and BOTH SAY SO THEMSELVES a few lines further down their own
# headers ("Path-filtered, so ADVISORY by skip-semantics"). Neither is registered in
# branch protection. So each is a genuine posture/enforcement disagreement under D-13 —
# and resolving one means deciding whether the gate becomes advisory in its header or
# required in the repository's settings. That is an operator decision about ENFORCEMENT
# POSTURE, not a spelling fix, and it is deliberately not taken here.
#
# The entry is keyed by (file, posture, surface) rather than by file:line — a line
# number moves under any edit above it, and a file-only key would let a SECOND,
# different defect hide inside an already-listed file. Changing either graded value
# retires the exemption automatically, because the key stops matching.
#
# EVERY ENTRY MUST STILL REPRODUCE ITS FINDING. `main` re-derives that on each run and
# reports any entry that no longer does. An allowlist entry states a fact about the
# corpus, and a fact can stop being true; an entry left standing after its premise
# expires reads as a silent, permanent exemption, which is strictly worse than the
# finding it was suppressing.
POSTURE_RESIDUALS: dict[tuple[str, str, str], str] = {
    ("close-completeness.yml", "required(warn-mode-initial)", "path-filtered"):
        "self-describes as ADVISORY by skip-semantics; unregistered in branch "
        "protection — needs an operator posture decision, not a header edit",
    ("release-corpus-completeness.yml", "required(warn-mode-initial)", "path-filtered"):
        "self-describes as ADVISORY by skip-semantics; unregistered in branch "
        "protection — needs an operator posture decision, not a header edit",
}

# ─── FOURTH INVARIANT — a declared population resolves, and is the one the check scans ──
#
# gate-efficacy-standard.md Requirement (b) (`population:`) and Requirement (c)
# § Population shortfall. Every name from here to POPULATION_RESIDUALS is new, and the
# functions that use them are too: the contract `reconcile-gate-posture.py` imports from
# this module (`parse_headers`, `QUOTED_RE`, `declared_contexts`) is untouched, and
# nothing new runs at import time.
POPULATION_RE = re.compile(r"^\s*#\s{2,}population:\s*(?P<fields>.*)$")

# The closed exemption-unit set, narrowest first. `file/class` is a per-file marker that
# removes ONE predicate class from a file that stays examined for the others (Check 31's
# override markers); `file` removes the file from every class. Both remove a whole file
# from something, so both carry a justification after an em-dash.
EXEMPT_UNITS = ("none", "line", "statement", "symbol", "record", "file/class", "file")
JUSTIFIED_UNITS = ("file/class", "file")

DEPLOY_REL = "core/deploy/deploy.sh"

# A deploy.sh check header in any of its historical forms. A population declaration binds
# to the nearest header above it, and its REGION runs to the next header.
CHECK_HEADER_RE = re.compile(r"^\s*#\s*(?:─+\s*)?Check\s+(\d+[a-z]?)\s*(?::|—)")

# The worked reference the standard's register names: each must carry a declaration.
WORKED_REFERENCE_POPULATIONS = frozenset({(DEPLOY_REL, "25"), (DEPLOY_REL, "31")})

# RESIDUALS — declared roots that resolve to ZERO tracked files and are NOT this change's
# to remove. The check reports each one NOT-EVALUATED at runtime, never skips it, and the
# change that removes or repoints a root retires its entry in the same commit.
#
# Same doctrine as POSTURE_RESIDUALS: keyed by (file, check, root) — never by line, which
# moves under any edit above it — and EVERY ENTRY MUST STILL REPRODUCE (declared AND
# zero-yield). `main` reports an entry that no longer does as a finding, so an exemption
# cannot outlive the fact it records.
POPULATION_RESIDUALS: dict[tuple[str, str, str], str] = {}


def repo_root() -> Path:
    """Walk up to the checkout root. Anchored on the directory this suite reads, so
    relocating the suite cannot silently point it at nothing."""
    for candidate in Path(__file__).resolve().parents:
        if (candidate / ".github" / "workflows").is_dir():
            return candidate
    print("FAIL: no .github/workflows ancestor of this file", file=sys.stderr)
    sys.exit(2)


def parse_headers(text: str) -> list[tuple[int, dict[str, str]]]:
    """EVERY `gate-efficacy:` declaration in the file, as (1-based line, field map).

    EVERY ONE, NOT THE FIRST. A workflow may carry more than one declaration — one
    per job or per named gate — and in this tree two do (five declarations between
    them). The earlier reader returned on its first match, so those extra
    declarations were never graded: the suite reported agreement over a count of
    FILES while its reach was a count of DECLARATIONS, and injecting a contradictory
    field into a second declaration survived every arm in the harness. That is the
    same declared-vs-actual reach overstatement this suite exists to catch, arriving
    inside the catcher. The trigger is a FILE-level property, so every declaration in
    a file is graded against that one trigger; what varies per declaration is the
    claim, and each claim is now read.

    Split on the 2-or-more-space field layout rather than on whitespace: the compound
    posture token `required(warn-mode-initial)` must survive intact, and an earlier
    extraction that split on `\\w+` truncated it to `required` — a silent read of a
    DIFFERENT value than the file carries.

    The whole file is searched, not a leading window: at least one workflow in this
    tree carries its header behind a multi-line rationale block, and a windowed search
    reports it as header-less.
    """
    found: list[tuple[int, dict[str, str]]] = []
    for lineno, line in enumerate(text.splitlines(), 1):
        match = HEADER_RE.match(line.strip())
        if not match:
            continue
        fields: dict[str, str] = {}
        for token in re.split(r"\s{2,}", match.group("fields").strip()):
            if "=" in token:
                key, value = token.split("=", 1)
                fields[key.strip()] = value.strip()
        found.append((lineno, fields))
    return found


def has_path_filter(text: str) -> bool:
    """True iff any `on.<event>` block carries `paths:` or `paths-ignore:`.

    Structural, via a YAML parse. NOTE the `on` lookup: YAML 1.1 resolves a bare `on`
    key to the boolean True, so `doc["on"]` alone misses every workflow in this tree.
    """
    doc = yaml.safe_load(text)
    if not isinstance(doc, dict):
        raise ValueError("workflow did not parse to a mapping")
    triggers = doc.get("on", doc.get(True))
    if not isinstance(triggers, dict):
        return False
    return any(
        isinstance(cfg, dict) and (FILTER_KEYS & set(cfg))
        for cfg in triggers.values()
    )


def evaluate(
    sources: dict[str, str],
) -> tuple[list[str], list[str], list[str], int]:
    """Return (findings, filtered_names, filter_free_names, declaration_count).

    The fourth element is the REACH of this run — how many declarations were actually
    graded. It is returned rather than derived by the caller so the number the suite
    publishes and the number it graded are the same number, taken at the same place.
    A magnitude reported over a population it was not measured on is the defect this
    file guards; reporting `len(sources)` as a declaration count was that defect.
    """
    findings: list[str] = []
    filtered: list[str] = []
    filter_free: list[str] = []
    n_declarations = 0

    for name in sorted(sources):
        text = sources[name]
        try:
            filtered_now = has_path_filter(text)
        except Exception as exc:  # unparseable YAML is a finding, never a skip
            findings.append(f"{name}: trigger unreadable ({exc})")
            continue

        (filtered if filtered_now else filter_free).append(name)

        declarations = parse_headers(text)
        if not declarations:
            findings.append(
                f"{name}: no `gate-efficacy:` header — Requirement (b) obliges one on "
                f"every workflow"
            )
            continue

        # EVERY declaration is graded against the file's trigger — a differential over
        # the whole declaration set, not a spot check on its first member. The finding
        # is keyed by `file:line` so a mismatch on the third declaration in a file
        # points at the third declaration.
        for lineno, fields in declarations:
            n_declarations += 1
            site = f"{name}:{lineno}"
            if filtered_now:
                if fields.get("skip-semantics") != "absent-is-pass":
                    findings.append(
                        f"{site}: carries a paths filter but this declaration does not "
                        f"declare skip-semantics=absent-is-pass (got "
                        f"{fields.get('skip-semantics')!r})"
                    )
                if "always-reports" in fields:
                    findings.append(
                        f"{site}: carries a paths filter yet this declaration declares "
                        f"always-reports — the two fields are mutually exclusive"
                    )
            else:
                if fields.get("always-reports") != "yes":
                    findings.append(
                        f"{site}: carries NO paths filter but this declaration does not "
                        f"declare always-reports=yes (got "
                        f"{fields.get('always-reports')!r})"
                    )
                if "skip-semantics" in fields:
                    findings.append(
                        f"{site}: carries NO paths filter yet this declaration declares "
                        f"skip-semantics — absence cannot occur, so the declaration is "
                        f"false"
                    )

    return findings, filtered, filter_free, n_declarations


def declared_contexts(text: str) -> set[str]:
    """The set of check-run names this workflow's headers bind a posture to.

    Empty for a workflow whose declaration names a posture but no check — the C1
    class. That emptiness is load-bearing: it is what scopes the per-job arm below.
    """
    names: set[str] = set()
    for _, fields in parse_headers(text):
        for key in ENFORCEMENT_KEYS:
            if key in fields:
                names.update(QUOTED_RE.findall(fields[key]))
    return names


def enforcement_surface(fields: dict[str, str]) -> str | None:
    """The SURFACE token of a declaration's enforcement field, or None if it has none.

    The corpus separates the surface from the check-run list it binds with a colon —
    `enforcement=branch-protection:"Ctx A","Ctx B"` — so the surface is everything
    before the FIRST colon. Testing the whole value instead would let a check-run
    literally named `branch-protection` satisfy a surface test it has nothing to do
    with; testing after a whitespace split would truncate the annotated forms this tree
    already carries (`ci-enforce (no warn-mode — findings turn the check red)`).

    Both live spellings of the key are read, for the same reason `declared_contexts`
    reads both: `enforcement=` is the form the standard fixes, `enforcement-surface=`
    is a legacy variant on two sites, and reading one would make this arm's denominator
    quietly wrong rather than absent.
    """
    for key in ENFORCEMENT_KEYS:
        if key in fields:
            return fields[key].split(":", 1)[0].strip()
    return None


def evaluate_posture(
    sources: dict[str, str],
) -> tuple[list[str], set[tuple[str, str, str]], int]:
    """Return (findings, residual_keys_hit, required_declarations_graded).

    THE INVARIANT: a declaration whose posture is `required` — bare or qualified —
    names `branch-protection` as its enforcement surface, because under D-13 that is
    the only surface on this host that makes a red verdict block a merge.

    WHY THIS IS A SEPARATE FUNCTION, for the third time in this file: `evaluate` grades
    a declaration against its file's TRIGGER, `evaluate_jobs` grades a job against its
    file's DECLARATION SET, and this grades a declaration against ITSELF — two fields of
    one header that must agree. Five oracles, five functions (`evaluate_population` grades
    a declaration against the tracked tree; `evaluate_census` grades the standard's census
    against the re-derived populations); widening any existing return would change a
    contract for a reason unrelated to it.

    The second element is the set of residual-ledger keys this run actually matched. It
    is RETURNED rather than recomputed by the caller so the staleness check and the
    exemption it audits are derived from the same pass over the same population — the
    identical reason `evaluate` returns its own declaration count instead of letting the
    caller infer one from `len(sources)`.
    """
    findings: list[str] = []
    hits: set[tuple[str, str, str]] = set()
    graded = 0

    for name in sorted(sources):
        for lineno, fields in parse_headers(sources[name]):
            posture = fields.get("posture", "")
            if not POSTURE_REQUIRED_RE.match(posture):
                continue
            graded += 1
            surface = enforcement_surface(fields)
            # `startswith`, character-for-character the test the reconciliation tool
            # applies to the same field. See the module docstring: two readers of one
            # field that disagreed would contradict each other over the same header.
            if surface is not None and surface.startswith(BLOCKING_SURFACE):
                continue
            key = (name, posture, surface)
            if key in POSTURE_RESIDUALS:
                hits.add(key)
                continue
            findings.append(
                f"{name}:{lineno}: declares posture={posture!r} but names enforcement "
                f"surface {surface!r} — `required` means a red verdict BLOCKS THE MERGE "
                f"(operator decision D-13), and only `branch-protection` delivers that. "
                f"A red non-required check does not stop a merge. Either name "
                f"`branch-protection` (and register the context), or declare the posture "
                f"this gate actually has."
            )

    return findings, hits, graded


def named_jobs(text: str) -> list[tuple[str, int, str]]:
    """Every job carrying an explicit `name:`, as (job key, 1-based line, name).

    STRUCTURAL via the YAML parse, for the same reason `has_path_filter` is: a
    line-oriented scan for `name:` over an arbitrary workflow population also matches
    every STEP name and every `- name:` inside a `run:` heredoc, which would make this
    arm wrong rather than absent. The line number is recovered by locating the job key
    textually, so a finding points at the job the way every other finding here points
    at a declaration — `file:line`, not `file:some-key`.
    """
    doc = yaml.safe_load(text)
    if not isinstance(doc, dict):
        raise ValueError("workflow did not parse to a mapping")
    jobs = doc.get("jobs")
    if not isinstance(jobs, dict):
        return []
    lines = text.splitlines()
    out: list[tuple[str, int, str]] = []
    for key, cfg in jobs.items():
        if not isinstance(cfg, dict):
            continue
        name = cfg.get("name")
        if not isinstance(name, str) or not name.strip():
            continue          # no explicit name: -> GitHub falls back to the job key
        lineno = next(
            (i for i, ln in enumerate(lines, 1) if ln == f"  {key}:"), 0
        )
        out.append((str(key), lineno, name.strip()))
    return out


def expand_job_name(text: str, job_key: str, name: str) -> list[str] | None:
    """Resolve a job `name:` to the check-run name(s) GitHub will actually publish.

    A matrix job publishes ONE check-run per matrix leg, each with `${{ matrix.<k> }}`
    substituted — `install-tests.yml` declares all three expanded forms and would read
    as undeclared against its raw template. Returns the expanded list, or None when the
    name carries an expression this resolver cannot evaluate.

    None is a FINDING upstream, never a skip: a job name that cannot be resolved is a
    declaration binding that cannot be verified, and reporting it clean would assert
    over a population this function could not observe.
    """
    if "${{" not in name:
        return [name]
    doc = yaml.safe_load(text)
    matrix = {}
    if isinstance(doc, dict) and isinstance(doc.get("jobs"), dict):
        cfg = doc["jobs"].get(job_key)
        if isinstance(cfg, dict):
            strategy = cfg.get("strategy")
            if isinstance(strategy, dict) and isinstance(strategy.get("matrix"), dict):
                matrix = strategy["matrix"]
    names = [name]
    for key in MATRIX_REF_RE.findall(name):
        values = matrix.get(key)
        if not isinstance(values, list) or not values:
            return None       # unresolvable: no literal value list to expand over
        names = [
            MATRIX_REF_RE.sub(
                lambda m, v=value: str(v) if m.group(1) == key else m.group(0), n
            )
            for n in names
            for value in values
        ]
    if any(ANY_EXPR_RE.search(n) for n in names):
        return None           # a non-matrix expression survived — do not guess
    return names


def evaluate_jobs(sources: dict[str, str]) -> tuple[list[str], list[str], int]:
    """Return (findings, scoped_workflow_names, jobs_graded).

    THE INVARIANT: in a workflow whose headers name at least one check-run, EVERY job
    that publishes a named check-run is itself named by one of those headers.

    WHY THIS IS A SEPARATE FUNCTION FROM `evaluate`. The two grade different objects
    against different oracles — `evaluate` grades a DECLARATION against its file's
    trigger, this grades a JOB against its file's declaration set — and `evaluate`'s
    four-element return is consumed by name upstream. Widening it to carry a fifth
    element would change a contract for a reason unrelated to it.

    WHY IT IS SCOPED, AND WHY THE SCOPE IS THE SPECIFICITY ARM. A workflow whose
    headers name NO check-run declares its posture by CONTAINMENT — it is a single
    gate, and the header is unambiguously about it. Firing there would flag eleven
    conforming workflows and train a reader to ignore the finding. The scope is not a
    convenience: it is the boundary between a declaration that binds to a named
    check-run and one that binds to the file, and only the first kind can be checked
    this way.
    """
    findings: list[str] = []
    scoped: list[str] = []
    graded = 0

    for name in sorted(sources):
        text = sources[name]
        try:
            contexts = declared_contexts(text)
            jobs = named_jobs(text)
        except Exception as exc:  # unparseable is a finding, never a skip
            findings.append(f"{name}: jobs unreadable ({exc})")
            continue

        if not contexts:
            continue          # C1 class — posture declared by containment; out of scope
        scoped.append(name)

        for job_key, lineno, job_name in jobs:
            graded += 1
            site = f"{name}:{lineno}"
            expanded = expand_job_name(text, job_key, job_name)
            if expanded is None:
                findings.append(
                    f"{site}: job {job_key!r} has a name this suite cannot resolve to a "
                    f"check-run ({job_name!r}) — the declaration binding is unverifiable, "
                    f"which is reported rather than assumed clean"
                )
                continue
            missing = [n for n in expanded if n not in contexts]
            if missing:
                findings.append(
                    f"{site}: job {job_key!r} publishes check-run(s) "
                    f"{', '.join(repr(m) for m in sorted(missing))} that no "
                    f"`gate-efficacy:` header in this workflow names — Requirement (b) "
                    f"obliges every automated-assertion gate to declare its own posture, "
                    f"and the gate's surface is the JOB"
                )

    return findings, scoped, graded


def job_harness(sources: dict[str, str]) -> list[str]:
    """Anti-vacuity for the per-job arm. Same doctrine as `harness` above: every arm
    mutates an in-memory copy of the LIVE population and requires the detector to
    react, an arm that cannot be BUILT is a reported NOSET rather than a skip, and the
    specificity arm runs on the same non-empty input as the sensitivity arms."""
    failures: list[str] = []

    base_findings, scoped, graded = evaluate_jobs(sources)

    if not scoped:
        failures.append("NOSET: no workflow declares a named check-run, so arms "
                        "B1/B3 cannot be built — reported rather than skipped")
    if graded == 0:
        failures.append("NOSET: zero jobs graded — a clean over an empty population "
                        "is not a clean")

    def flags(name: str, mutate) -> bool:
        mutated = dict(sources)
        mutated[name] = mutate(sources[name])
        if mutated[name] == sources[name]:
            failures.append(f"B-CTRL: mutation of {name} changed nothing — the arm "
                            f"asserts against an unmutated input")
            return False
        found, _, _ = evaluate_jobs(mutated)
        return len(found) > len(base_findings)

    # B1 — SENSITIVITY. Rename a declared context that a job actually matches; that job
    # must go from covered to uncovered. Renaming rather than deleting keeps the header
    # well-formed, so the arm proves the JOB check fired and not a parse failure.
    victim = None
    for name in scoped:
        contexts = declared_contexts(sources[name])
        for job_key, _, job_name in named_jobs(sources[name]):
            expanded = expand_job_name(sources[name], job_key, job_name) or []
            hit = next((n for n in expanded if n in contexts), None)
            if hit:
                victim = (name, hit)
                break
        if victim:
            break
    if not victim:
        failures.append("NOSET: no job in any scoped workflow matches a declared "
                        "context, so arm B1 cannot be built — reported rather than "
                        "skipped")
    else:
        vname, vctx = victim
        if not flags(vname, lambda t: edit_header(
                t, f'"{vctx}"', '"zzz-renamed-context"')):
            failures.append(f"B1: renaming the declared context {vctx!r} in {vname} — "
                            f"orphaning the job that publishes it — was NOT flagged")

    # B2 — SPECIFICITY, on the same non-empty input. A C1-class workflow (header
    # declares a posture but names no check-run) must NOT be graded, however its jobs
    # are named. Without this arm a detector that flagged every named job would pass B1
    # and B3 and be worthless — and it would red-CI eleven conforming workflows.
    c1 = [n for n in sorted(sources)
          if parse_headers(sources[n]) and not declared_contexts(sources[n])
          and named_jobs(sources[n])]
    if not c1:
        failures.append("NOSET: no C1-class workflow (header present, no check-run "
                        "named) exists, so arm B2 cannot be built — reported rather "
                        "than skipped")
    else:
        c1_victim = c1[0]
        if flags(c1_victim, lambda t: re.sub(
                r"^(    name:).*$", r"\1 Zzz fabricated job name", t, count=1,
                flags=re.M)):
            failures.append(f"B2: renaming a job in C1-class {c1_victim} WAS flagged — "
                            f"the arm over-matches into workflows whose posture is "
                            f"declared by containment")

    # B3 — MATRIX EXPANSION. A matrix job publishes one check-run per leg, and its raw
    # `${{ matrix.* }}` template matches no declared context. This arm requires the
    # expansion to be real: break ONE declared leg and the job must be flagged for that
    # leg alone. An implementation that skipped matrix jobs entirely would pass B1/B2
    # and silently exempt every matrix gate in the tree.
    matrix_victim = None
    for name in scoped:
        contexts = declared_contexts(sources[name])
        for job_key, _, job_name in named_jobs(sources[name]):
            if "${{" not in job_name:
                continue
            expanded = expand_job_name(sources[name], job_key, job_name)
            if expanded and len(expanded) > 1 and all(n in contexts for n in expanded):
                matrix_victim = (name, expanded[0])
                break
        if matrix_victim:
            break
    if not matrix_victim:
        failures.append("NOSET: no matrix job resolves to more than one DECLARED "
                        "check-run, so arm B3 cannot be built — reported rather than "
                        "skipped")
    else:
        mname, mleg = matrix_victim
        if not flags(mname, lambda t: edit_header(
                t, f'"{mleg}"', '"zzz-broken-matrix-leg"')):
            failures.append(f"B3: breaking the declared matrix leg {mleg!r} in {mname} "
                            f"was NOT flagged — the resolver is not expanding "
                            f"${{{{ matrix.* }}}}, so every matrix job is exempt")

    return failures


def posture_harness(sources: dict[str, str]) -> list[str]:
    """Anti-vacuity for the posture/enforcement arm. Same doctrine as the two harnesses
    above: every arm mutates an in-memory copy of the LIVE population, an arm that
    cannot be BUILT is a reported NOSET rather than a skip, and the specificity arms run
    on the same non-empty input as the sensitivity arms.

    ARM COVERAGE. `evaluate_posture` decides on TWO fields, so it has two ways to be
    wrong and both are armed: C1 mutates the ENFORCEMENT side of a conforming
    declaration, C2 mutates the POSTURE side of a non-conforming one. An implementation
    that ignored posture entirely and flagged every non-`branch-protection` surface
    would pass C1 and fail C2; one that ignored the surface would pass C2 and fail C1.
    C3 and C4 are the specificity pair, and C5 audits the exemption mechanism itself.
    """
    failures: list[str] = []

    base_findings, _, graded = evaluate_posture(sources)

    if graded == 0:
        failures.append("NOSET: no declaration carries a `required` posture, so arms "
                        "C1/C3 cannot be built — reported rather than skipped")

    def flags(name: str, mutate) -> bool:
        mutated = dict(sources)
        mutated[name] = mutate(sources[name])
        if mutated[name] == sources[name]:
            failures.append(f"C-CTRL: mutation of {name} changed nothing — the arm "
                            f"asserts against an unmutated input")
            return False
        found, _, _ = evaluate_posture(mutated)
        return len(found) > len(base_findings)

    def find_declaration(predicate):
        """First (file, posture, surface) in the live population satisfying predicate."""
        for name in sorted(sources):
            for _, fields in parse_headers(sources[name]):
                posture = fields.get("posture", "")
                surface = enforcement_surface(fields)
                if predicate(posture, surface):
                    return name, posture, surface
        return None

    # A conforming declaration whose posture is EXACTLY `required`, so the C3 mutation
    # is a clean substring swap rather than a qualifier stacked onto a qualifier.
    conforming = find_declaration(
        lambda p, s: p == "required" and s is not None and s.startswith(BLOCKING_SURFACE)
    )
    # An advisory declaration naming a NON-blocking surface — the input on which the arm
    # must stay silent, and the input C2 promotes into a finding.
    advisory = find_declaration(
        lambda p, s: not POSTURE_REQUIRED_RE.match(p) and p != ""
        and s is not None and not s.startswith(BLOCKING_SURFACE)
    )

    # C1 — SENSITIVITY, enforcement side. Take a conforming `required` declaration and
    # point it at a surface that cannot block. This is the exact shape of the defect the
    # arm was written for, and the shape `install-tests.yml` carried while this suite
    # ran inside it and reported green.
    if not conforming:
        failures.append("NOSET: no declaration pairs a bare `required` posture with "
                        "`branch-protection`, so arms C1/C3 cannot be built — reported "
                        "rather than skipped")
    else:
        cname, _, _ = conforming
        if not flags(cname, lambda t: edit_header(
                t, f"={BLOCKING_SURFACE}", "=zzz-unregistered-surface")):
            failures.append(f"C1: repointing a `required` declaration in {cname} at a "
                            f"non-blocking enforcement surface was NOT flagged")

    # C2 — SENSITIVITY, posture side. Promote an advisory declaration that names a
    # non-blocking surface to `required` WITHOUT touching its enforcement. Only a
    # detector that actually reads the posture can see this one.
    if not advisory:
        failures.append("NOSET: no advisory declaration names a non-blocking surface, "
                        "so arms C2/C4 cannot be built — reported rather than skipped")
    else:
        aname, aposture, _ = advisory
        if not flags(aname, lambda t, p=aposture: edit_header(
                t, f"posture={p}", "posture=required")):
            failures.append(f"C2: promoting an advisory declaration in {aname} to "
                            f"`required` while it names a non-blocking surface was NOT "
                            f"flagged — the arm is not reading the posture field")

    # C3 — SPECIFICITY, on the same non-empty input. A QUALIFIED `required` posture that
    # still names `branch-protection` is conforming and must stay clean. Without this
    # arm, an implementation that matched only the bare literal `required` would pass
    # C1 and C2 while silently exempting the six qualified declarations in this tree —
    # the same space-intolerant-match failure `reconcile-gate-posture.py` records.
    if conforming:
        cname, _, _ = conforming
        if flags(cname, lambda t: edit_header(
                t, "posture=required", "posture=required(zzz-shakedown-qualifier)")):
            failures.append(f"C3: a QUALIFIED `required` posture still naming "
                            f"`branch-protection` in {cname} WAS flagged — the arm "
                            f"treats a conforming qualified declaration as a defect")

    # C4 — SPECIFICITY, advisory side. An `advisory` posture is unconstrained by this
    # invariant however its surface is spelled. Without this arm a detector that flagged
    # every non-`branch-protection` surface outright would pass C1 and be worthless —
    # and would red-CI twenty-one conforming advisory declarations.
    if advisory:
        aname, _, asurface = advisory
        if flags(aname, lambda t, s=asurface: edit_header(
                t, f"={s}", "=zzz-some-other-advisory-surface")):
            failures.append(f"C4: changing an ADVISORY declaration's enforcement "
                            f"surface in {aname} WAS flagged — the arm over-matches "
                            f"into postures this invariant does not govern")

    # C5 — THE EXEMPTION AUDIT. Every residual-ledger entry must still reproduce the
    # finding it suppresses. This arm proves the staleness detector DISCRIMINATES, by
    # conforming a ledgered declaration and requiring its key to stop being hit.
    #
    # An EMPTY ledger is deliberately NOT a NOSET here, unlike every other unbuildable
    # arm in this file. The NOSET doctrine exists so an emptied population cannot
    # silently disable a check — but an empty ledger means the exemption mechanism is
    # UNUSED, so there is nothing to be blind to, and an empty ledger is the target
    # state. Failing then would make fixing the last residual turn this suite red.
    if POSTURE_RESIDUALS:
        rname, rposture, rsurface = next(iter(POSTURE_RESIDUALS))
        if rname not in sources:
            failures.append(f"C5: residual ledger names {rname}, which is not in the "
                            f"workflow population — the entry cannot be audited")
        else:
            mutated = dict(sources)
            mutated[rname] = edit_header(
                sources[rname], f"={rsurface}", f"={BLOCKING_SURFACE}")
            if mutated[rname] == sources[rname]:
                failures.append(f"C5-CTRL: could not conform {rname} — the arm would "
                                f"assert against an unmutated input")
            else:
                _, hits_after, _ = evaluate_posture(mutated)
                if (rname, rposture, rsurface) in hits_after:
                    failures.append(
                        f"C5: conforming {rname} left its residual-ledger entry still "
                        f"matching — a stale exemption would never be detected, and the "
                        f"entry would suppress findings forever")

    return failures


class TrackedTreeError(RuntimeError):
    """`git ls-files` failed, so the population arm has no tree to resolve against."""


def tracked_files(root: Path) -> list[str]:
    """Every tracked path, repo-relative, from ONE read-only `git ls-files -z`.

    Called once per run from `main` and passed down, never at import: another tool imports
    this module by path. A failure raises TrackedTreeError, which `main` turns into exit 2,
    because resolving declared roots is this arm's whole content and a tree that could not
    be listed is not an empty tree.
    """
    proc = subprocess.run(["git", "-C", str(root), "ls-files", "-z"],
                          capture_output=True, check=False)
    if proc.returncode != 0:
        detail = proc.stderr.decode("utf-8", "replace").strip()
        raise TrackedTreeError(detail or f"exit {proc.returncode}")
    return [p for p in proc.stdout.decode("utf-8", "surrogateescape").split("\0") if p]


def _population_fields(raw: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    for token in re.split(r"\s{2,}", raw.strip()):
        if "=" in token:
            key, value = token.split("=", 1)
            fields[key.strip()] = value.strip()
    return fields


def parse_population(text: str) -> list[tuple[int, dict[str, str]]]:
    """EVERY `#   population:` declaration in a file, as (1-based line, field map).

    The field grammar is `parse_headers`': fields separated by two or more spaces, each
    `key=value`, so a single-spaced value — an `exempts=` justification — survives whole.
    A separate function rather than a widening of `parse_headers`, whose return is part of
    the contract another tool imports.
    """
    found: list[tuple[int, dict[str, str]]] = []
    for lineno, line in enumerate(text.splitlines(), 1):
        match = POPULATION_RE.match(line)
        if match:
            found.append((lineno, _population_fields(match.group("fields"))))
    return found


def _table_cells(line: str) -> list[str]:
    """One markdown table row's cells: split on unescaped pipes, `\\|` unescaped, and one
    pair of enclosing backticks stripped from each cell."""
    body = line.strip()
    body = body[1:] if body.startswith("|") else body
    body = body[:-1] if body.endswith("|") and not body.endswith("\\|") else body
    cells = []
    for raw in re.split(r"(?<!\\)\|", body):
        cell = raw.strip().replace("\\|", "|")
        if len(cell) >= 2 and cell.startswith("`") and cell.endswith("`"):
            cell = cell[1:-1]
        cells.append(cell)
    return cells


def parse_census(text: str) -> tuple[dict[str, dict], list[str]]:
    """The standard's census, as ({record name: record}, form findings).

    Located by the exact heading CENSUS_HEADING and bounded by the next `## ` heading. A
    record is a `#### Population record — <name>` heading, with the em dash as the
    standard writes it; its first fenced block must carry EXACTLY the seven labels of the
    population record, in order, with `examined:` opening on an integer, and the first
    pipe table after that fence holds its members. A separate function beside
    `parse_population` rather than a widening of it: the two read one record form in its
    two renderings, and neither return changes for the other.

    Each record is {"examined": int | None, "columns": [...], "rows": [{column: cell}],
    "keys": [key tuple]}; the key and closed columns are CENSUS_RECORDS'.
    """
    site = STANDARD_REL
    lines = text.splitlines()
    try:
        start = lines.index(CENSUS_HEADING)
    except ValueError:
        return {}, [f"{site}: the census section {CENSUS_HEADING!r} is absent — the "
                    f"populations it records have no record to grade against"]
    end = next((i for i in range(start + 1, len(lines)) if lines[i].startswith("## ")),
               len(lines))
    findings: list[str] = []
    records: dict[str, dict] = {}
    index = start + 1
    while index < end:
        head = RECORD_HEADING_RE.match(lines[index])
        index += 1
        if not head:
            continue
        name = head.group("name")
        where = f"{site}: census record {name!r}"
        if name in records:
            findings.append(f"{where} appears twice")
        body: list[str] = []
        fence = False
        while index < end and (fence or not lines[index].startswith("#")):
            if lines[index].startswith("```"):
                fence = not fence
            body.append(lines[index])
            index += 1
        opens = [i for i, ln in enumerate(body) if ln.startswith("```")]
        record: dict = {"examined": None, "columns": [], "rows": [], "keys": []}
        records[name] = record
        if len(opens) < 2:
            findings.append(f"{where} carries no fenced population block")
            continue
        labels: list[str] = []
        for ln in body[opens[0] + 1:opens[1]]:
            if not ln.strip():
                continue
            label = re.match(r"^([a-z]+):\s*(.*)$", ln)
            if not label:
                findings.append(f"{where}: a fenced line opens with no label: {ln[:60]!r}")
                continue
            labels.append(label.group(1))
            if label.group(1) == "examined":
                count = re.match(r"(\d+)(?!\d)", label.group(2))
                if count:
                    record["examined"] = int(count.group(1))
                else:
                    findings.append(f"{where}: `examined:` does not open on an integer")
        if tuple(labels) != POPULATION_RECORD_LABELS:
            findings.append(f"{where}: labels {labels} are not exactly "
                            f"{list(POPULATION_RECORD_LABELS)}, in that order")
        after = body[opens[1] + 1:]
        first = next((i for i, ln in enumerate(after) if ln.lstrip().startswith("|")),
                     len(after))
        table: list[str] = []
        for ln in after[first:]:
            if not ln.lstrip().startswith("|"):
                break
            table.append(ln)
        if len(table) < 2:
            findings.append(f"{where} carries no member table")
            continue
        header = _table_cells(table[0])
        record["columns"] = header
        spec = CENSUS_RECORDS.get(name)
        if spec is None:
            continue
        key_cols, closed, text_col = spec
        missing = [c for c in key_cols + tuple(closed) + (text_col,) if c not in header]
        if missing:
            findings.append(f"{where}: its table lacks column(s) {missing}")
            continue
        seen: set[tuple[str, ...]] = set()
        for ln in table[2:]:
            cells = _table_cells(ln)
            row = dict(zip(header, cells + [""] * (len(header) - len(cells))))
            key = tuple(row[c] for c in key_cols)
            record["rows"].append(row)
            record["keys"].append(key)
            label = "(" + ", ".join(key) + ")"
            if key in seen:
                findings.append(f"{where}: row {label} appears twice")
            seen.add(key)
            for column, allowed in closed.items():
                if row[column] not in allowed:
                    findings.append(f"{where}: row {label} carries {column} "
                                    f"{row[column]!r}, outside the closed set "
                                    f"({', '.join(allowed)})")
            if not row[text_col].strip():
                findings.append(f"{where}: row {label} carries an empty {text_col}")
    for name in sorted(records):
        if name not in CENSUS_RECORDS:
            findings.append(f"{site}: census record {name!r} is not one of "
                            f"{sorted(CENSUS_RECORDS)}")
    for name in sorted(CENSUS_RECORDS):
        if name not in records:
            findings.append(f"{site}: the census carries no {name!r} record")
    return records, findings


def deploy_declarations(
    text: str,
) -> list[tuple[str | None, int, dict[str, str], list[str], int]]:
    """Each deploy.sh population declaration, bound to the check it sits in.

    Returns (check id, 1-based line, fields, region lines, region start index). The check
    is the nearest CHECK_HEADER_RE line above the declaration, and its region runs to the
    next header, so the reach tests read the same block the declaration describes. A
    declaration above every header binds to nothing (check id None), a finding upstream.
    """
    lines = text.splitlines()
    headers = [(i, m.group(1)) for i, line in enumerate(lines)
               for m in (CHECK_HEADER_RE.match(line),) if m]
    out: list[tuple[str | None, int, dict[str, str], list[str], int]] = []
    for lineno, fields in parse_population(text):
        above = [h for h in headers if h[0] < lineno - 1]
        if not above:
            out.append((None, lineno, fields, [], 0))
            continue
        start, check_id = above[-1]
        end = next((h[0] for h in headers if h[0] > start), len(lines))
        out.append((check_id, lineno, fields, lines[start:end], start))
    return out


def array_literal(name: str, region: list[str]) -> list[str] | None:
    """The elements of bash array `name` as the check defines it inside its region.

    Reads `name=(`, optionally after `local`/`declare` and `-a`, up to the first unquoted,
    uncommented `)`, then splits with shlex — so the quoted form (Check 31's
    `"core/rules" …`) and the unquoted one-per-line form (Check 25's) read alike. None
    when the array is absent or unterminated: a declaration naming an array its check does
    not define cannot be resolved, and that is reported rather than guessed.
    """
    start_re = re.compile(r"^\s*(?:(?:local|declare)\s+(?:-a\s+)?)?"
                          + re.escape(name) + r"=\((?P<rest>.*)$")
    for index, line in enumerate(region):
        match = start_re.match(line)
        if not match:
            continue
        body = "\n".join([match.group("rest")] + region[index + 1:])
        chars: list[str] = []
        quote = ""
        comment = False
        for ch in body:
            if comment:
                if ch == "\n":
                    comment = False
                    chars.append(ch)
            elif quote:
                chars.append(ch)
                if ch == quote:
                    quote = ""
            elif ch in "\"'":
                quote = ch
                chars.append(ch)
            elif ch == "#":
                comment = True
            elif ch == ")":
                try:
                    return shlex.split("".join(chars))
                except ValueError:
                    return None
            else:
                chars.append(ch)
        return None
    return None


def member_count(tracked: list[str], root: str, filt: str) -> int:
    """Tracked files under `root` that the declared filter admits.

    ONE GRAMMAR WITH THE RUNTIME RESOLVER, `_population_resolve` in deploy.sh, which is
    `find`'s `-path` / `-name` split: a `|`-separated pattern containing `/` matches the
    repo-relative path, any other the basename, and `*` admits every file. A root that is
    itself a tracked file counts when the filter admits it, as `find` would list it.
    """
    patterns = [p for p in filt.split("|") if p]
    prefix = root.rstrip("/") + "/"
    count = 0
    for path in tracked:
        if path != root and not path.startswith(prefix):
            continue
        base = path.rsplit("/", 1)[-1]
        if any(fnmatch.fnmatchcase(path if "/" in p else base, p) for p in patterns):
            count += 1
    return count


def exempts_findings(site: str, value: str) -> list[str]:
    """Findings for an `exempts=` value: a comma list of units from EXEMPT_UNITS, one per
    exemption mechanism the gate carries, then — when any unit removes a whole file from
    something — a justification after an em-dash."""
    out: list[str] = []
    units_part, _, rest = value.strip().partition(" ")
    rest = rest.strip()
    why = ""
    if rest:
        if rest[0] in "—-":
            why = rest[1:].strip()
        else:
            out.append(f"{site}: `exempts=` carries text after its unit(s) that does not "
                       f"follow an em-dash (`<unit> — <justification>`): {value!r}")
    units = units_part.split(",")
    outside = [u for u in units if u not in EXEMPT_UNITS]
    if outside:
        out.append(f"{site}: `exempts=` names unit(s) {outside!r} outside the closed set "
                   f"({', '.join(EXEMPT_UNITS)})")
    if any(u in JUSTIFIED_UNITS for u in units) and not why:
        out.append(f"{site}: `exempts={units_part}` removes whole files but states no "
                   f"justification after an em-dash — a whole-file exemption is admitted "
                   f"only where the case is a property of the whole file, and the "
                   f"declaration says why")
    return out


def declaration_findings(site: str, fields: dict[str, str]) -> list[str]:
    """Well-formedness of one declaration: its three fields, a non-empty filter, and a
    valid exemption-unit set."""
    out = [f"{site}: `population:` declaration lacks `{key}=`"
           for key in ("roots", "filter", "exempts") if key not in fields]
    if "filter" in fields and not [p for p in fields["filter"].split("|") if p]:
        out.append(f"{site}: `filter=` is empty — a declaration states its member "
                   f"predicate")
    if "exempts" in fields:
        out += exempts_findings(site, fields["exempts"])
    return out


def _code(region: list[str]) -> list[str]:
    """The region's CODE lines. Comments are excluded on purpose: a comment naming a
    function is not a call, and counting one would let arm P8 — which removes the call —
    pass against a region that still merely mentions it."""
    return [ln for ln in region if ln.strip() and not ln.lstrip().startswith("#")]


def _resolves(region: list[str], filt: str, array: str | None) -> bool:
    """A `_population_resolve` call in the region passes the declared filter literal and,
    for an `@<array>` declaration, that array — so the declared population is the scanned
    one, character for character."""
    ref = None if array is None else "${" + array + "[@]}"
    for line in _code(region):
        if "_population_resolve" not in line:
            continue
        if f"'{filt}'" not in line and f'"{filt}"' not in line:
            continue
        if ref is None or ref in line:
            return True
    return False


def evaluate_population(
    sources: dict[str, str],
    deploy_text: str,
    tracked: list[str],
    ledger: dict[tuple[str, str, str], str] | None = None,
) -> tuple[list[str], set[tuple[str, str, str]], int, int, int]:
    """Return (findings, residual_keys_hit, declarations, declared_roots, resolving_roots).

    THE INVARIANT: every `#   population:` declaration — on a workflow or on a deploy.sh
    check — is well-formed, and every root it declares resolves to at least one TRACKED
    file under its declared filter. On deploy.sh a `roots=@<array>` declaration names an
    array its check defines, a `_population_resolve` call passes that array with the same
    filter, and a `_population_report` call reports the result — so the declared
    population IS the scanned one, and what was examined is emitted at runtime.

    A FOURTH ORACLE, AND SO A FOURTH FUNCTION. The other three grade a declaration against
    its file's trigger, a job against its file's declaration set, and a declaration
    against itself; this one grades a declaration against the tracked tree and the code
    beside it. Widening any existing return would change a contract for a reason
    unrelated to it.

    `ledger` defaults to POPULATION_RESIDUALS. It is a parameter so the anti-vacuity
    harness can drive the ledger branch against a SYNTHETIC ledger on every invocation
    (arm P6): an arm keyed to the live ledger would vanish exactly when that ledger reaches
    its target state, empty. The hit set is RETURNED, as `evaluate_posture` returns its
    own, so the staleness audit reads the same pass over the same population.
    """
    ledger = POPULATION_RESIDUALS if ledger is None else ledger
    findings: list[str] = []
    hits: set[tuple[str, str, str]] = set()
    counts = {"decls": 0, "roots": 0, "resolving": 0}
    declared_checks: set[str] = set()

    def grade_roots(site: str, key_file: str, key_check: str, roots: list[str],
                    filt: str) -> None:
        for root in roots:
            counts["roots"] += 1
            if member_count(tracked, root, filt) > 0:
                counts["resolving"] += 1
                continue
            key = (key_file, key_check, root)
            if key in ledger:
                hits.add(key)   # reported by `main` as a WARN line, never as a finding
                continue
            findings.append(
                f"{site}: declared root {root!r} resolves to ZERO tracked files under "
                f"filter {filt!r} — a population the gate declares but cannot examine is "
                f"a population shortfall. Remove or repoint the root, or ledger it in "
                f"POPULATION_RESIDUALS in the change that is removing it")

    for name in sorted(sources):
        for lineno, fields in parse_population(sources[name]):
            counts["decls"] += 1
            site = f"{name}:{lineno}"
            malformed = declaration_findings(site, fields)
            findings += malformed
            if fields.get("roots", "").startswith("@"):
                findings.append(f"{site}: `roots=@…` names a bash array, which a workflow "
                                f"does not carry — list the roots literally")
                continue
            if malformed:
                continue
            roots = [r.strip() for r in fields["roots"].split(",") if r.strip()]
            if not roots:
                findings.append(f"{site}: `roots=` names no root")
                continue
            grade_roots(site, f".github/workflows/{name}", "", roots, fields["filter"])

    for check_id, lineno, fields, region, _ in deploy_declarations(deploy_text):
        counts["decls"] += 1
        site = f"{DEPLOY_REL}:{lineno}"
        if check_id is None:
            findings.append(f"{site}: population declaration sits above every Check "
                            f"header, so it binds to no check")
            continue
        declared_checks.add(check_id)
        malformed = declaration_findings(site, fields)
        findings += malformed
        if malformed:
            continue
        filt = fields["filter"]
        array = fields["roots"][1:] if fields["roots"].startswith("@") else None
        if array is not None:
            roots = array_literal(array, region)
            if roots is None:
                findings.append(f"{site}: Check {check_id} declares roots=@{array}, but "
                                f"its region defines no `{array}=(…)` array — the "
                                f"declaration cannot be resolved")
                continue
        else:
            roots = [r.strip() for r in fields["roots"].split(",") if r.strip()]
        if not _resolves(region, filt, array):
            scanned = f'"${{{array}[@]}}" ' if array else ""
            findings.append(f"{site}: Check {check_id} declares filter={filt!r}, but no "
                            f"`_population_resolve` call in its region passes "
                            f"{scanned}with that filter — the declared population is not "
                            f"the scanned one")
        if not any("_population_report" in ln for ln in _code(region)):
            findings.append(f"{site}: Check {check_id} declares a population, but no "
                            f"`_population_report` call in its region reports it — what "
                            f"the check examined is never emitted at runtime")
        if not roots:
            findings.append(f"{site}: `roots=` names no root")
            continue
        grade_roots(site, DEPLOY_REL, check_id, roots, filt)

    for key_file, check_id in sorted(WORKED_REFERENCE_POPULATIONS):
        if key_file == DEPLOY_REL and check_id not in declared_checks:
            findings.append(f"{key_file}: worked-reference Check {check_id} carries no "
                            f"`#   population:` declaration — the standard's register names "
                            f"it as the reference implementation")

    return findings, hits, counts["decls"], counts["roots"], counts["resolving"]


def population_ledger_audit(
    hits: set[tuple[str, str, str]],
    ledger: dict[tuple[str, str, str], str] | None = None,
) -> list[str]:
    """THE EXEMPTION AUDIT: every ledger entry must still reproduce — declared AND
    zero-yield. An entry the run did not hit has outlived its premise (the root was
    removed, repointed, or now resolves), and it is reported so retiring it is obligatory.

    Run on the real tree from `main`, never inside `evaluate_population`: the harness runs
    that function over MUTATED text, where a missing hit is the arm working. `ledger` is a
    parameter for the same reason `evaluate_population` takes one (arm P6).
    """
    ledger = POPULATION_RESIDUALS if ledger is None else ledger
    stale = []
    for key in sorted(ledger):
        if key in hits:
            continue
        where = f"{key[0]} Check {key[1]}" if key[1] else key[0]
        stale.append(f"{where}: population-ledger entry for root {key[2]!r} no longer "
                     f"reproduces — the root is gone, repointed or resolving, so the "
                     f"exemption has outlived its premise and MUST be deleted from "
                     f"POPULATION_RESIDUALS")
    return stale


def strip_population(text: str) -> str:
    """Drop every `#   population:` line — arm P5's mutation, textual and in-memory only."""
    kept = [ln for ln in text.splitlines() if not POPULATION_RE.match(ln)]
    return "\n".join(kept) + "\n"


def _synthetic_workflow(population_line: str) -> str:
    """A minimal workflow text carrying one population declaration. Only
    `evaluate_population` ever reads it, so it need not be valid YAML."""
    return ('# gate-efficacy: posture=advisory  enforcement=ci-enforce:"zzz synthetic"  '
            'always-reports=yes\n' + population_line + "\n")


# Arm P6's fixture: a region in the shape of a deploy.sh check, declaring one resolving
# root and one ledgered zero-yield root, with the calls the reach tests require.
P6_ROOT = "zzz-synthetic-ledgered-root"
P6_REGION = "\n".join([
    "  # ─── Check 999: synthetic population-ledger fixture (harness arm P6) ──",
    "  #   population: roots=@zzz_roots  filter=*.md  exempts=none",
    "    local -a zzz_roots=(",
    "      core/standards",
    f"      {P6_ROOT}",
    "    )",
    "    _population_resolve '*.md' -- \"${zzz_roots[@]}\"",
    "    _population_report zzz-synthetic 1 0",
    "",
])
P6_KEY = (DEPLOY_REL, "999", P6_ROOT)

# Arm P10's fixtures: regions in the shape of Check 25 — two declarations, two arrays and
# two resolve calls, every root resolving. P10_REGION's second call drops `--append`, so it
# resets the population the first call resolved before any `_population_report` reports
# it: the first declaration's roots are never examined, yet each call still passes its own
# array and filter, so every per-call reach test reads clean. P10_APPENDED restores the
# flag, and P10_REPORTED reports the first population before the second call; both are
# conforming controls on the same non-empty input.
RESOLVE_ORDER_MARK = "without `--append`"
_P10_HEAD = [
    "  # ─── Check 998: synthetic resolve-order fixture (harness arm P10) ──",
    "  #   population: roots=@zzz_md_roots  filter=*.md  exempts=none",
    "  #   population: roots=@zzz_skill_roots  filter=SKILL.md  exempts=none",
    "    local -a zzz_md_roots=(",
    "      core/standards",
    "    )",
    "    local -a zzz_skill_roots=(",
    "      core/skills",
    "    )",
    "    _population_resolve '*.md' -- \"${zzz_md_roots[@]}\"",
]
_P10_SECOND = "    _population_resolve 'SKILL.md' -- \"${zzz_skill_roots[@]}\""
_P10_REPORT = "    _population_report zzz-synthetic-order 1 0"
P10_REGION = _P10_HEAD + [_P10_SECOND, _P10_REPORT]
P10_APPENDED = _P10_HEAD + [
    "    _population_resolve --append 'SKILL.md' -- \"${zzz_skill_roots[@]}\"", _P10_REPORT]
P10_REPORTED = _P10_HEAD + [_P10_REPORT, _P10_SECOND, _P10_REPORT]


def population_harness(sources: dict[str, str], deploy_text: str,
                       tracked: list[str]) -> list[str]:
    """Anti-vacuity for the population arm, on the doctrine of the three harnesses above:
    an arm that cannot be BUILT is a reported NOSET rather than a skip, and each
    sensitivity arm is paired with a specificity arm on the same non-empty input.

    TWO KINDS OF ARM, KEPT APART DELIBERATELY. The arms that prove the DETECTOR
    discriminates — the exemption-unit arms P3/P3b/P3c/P4, the ledger arm P6 and the
    empty-glob arm P7 — run on SYNTHETIC declarations on every invocation. An arm built
    from a live instance of a construct whose disappearance is the goal (a ledgered root,
    a whole-file exemption) would turn reaching that goal into a harness failure. The
    arms that prove a LIVE population exists and is wired — P1, P2, P5, P8, P8b, P9 — are
    built from the worked reference at run time.
    """
    failures: list[str] = []
    base, _, n_decls, _, _ = evaluate_population(sources, deploy_text, tracked)

    def new_findings(extra: dict[str, str] | None = None,
                     deploy: str | None = None) -> list[str]:
        mutated = dict(sources)
        mutated.update(extra or {})
        found, _, _, _, _ = evaluate_population(
            mutated, deploy_text if deploy is None else deploy, tracked)
        return [f for f in found if f not in base]

    # P5 — NOSET, and the parser reads declarations and nothing else.
    if n_decls == 0:
        failures.append("NOSET: no `#   population:` declaration exists in any workflow or "
                        "in deploy.sh — a clean over an empty declaration set is not a "
                        "clean (P5)")
    _, _, n_stripped, _, _ = evaluate_population(
        {n: strip_population(t) for n, t in sources.items()},
        strip_population(deploy_text), tracked)
    if n_stripped != 0:
        failures.append(f"P5: with every population line removed the parser still counted "
                        f"{n_stripped} declaration(s) — it reads something other than the "
                        f"declarations")

    # The live victim: a worked-reference check carrying exactly ONE `@<array>`
    # declaration, located at run time from WORKED_REFERENCE_POPULATIONS.
    by_check: dict[str, list[tuple[int, dict[str, str], list[str], int]]] = {}
    for check_id, lineno, fields, region, start in deploy_declarations(deploy_text):
        if check_id is not None:
            by_check.setdefault(check_id, []).append((lineno, fields, region, start))
    victim = None
    for key_file, check_id in sorted(WORKED_REFERENCE_POPULATIONS):
        group = by_check.get(check_id, [])
        if key_file == DEPLOY_REL and len(group) == 1 \
                and group[0][1].get("roots", "").startswith("@"):
            victim = (check_id,) + group[0]
            break

    if victim is None:
        failures.append("NOSET: no worked-reference check carries exactly one `@<array>` "
                        "population declaration, so arms P1/P2/P8/P8b/P9 cannot be built "
                        "— reported rather than skipped")
    else:
        v_id, v_line, v_fields, v_region, v_start = victim
        v_site = f"{DEPLOY_REL}:{v_line}:"
        v_array = v_fields["roots"][1:]
        v_roots = array_literal(v_array, v_region) or []
        lines = deploy_text.splitlines()

        def region_mutated(edit) -> str:
            mutated = list(lines)
            end = v_start + len(v_region)
            mutated[v_start:end] = edit(list(v_region))
            return "\n".join(mutated) + "\n"

        # P2 — SPECIFICITY on the live, unmutated declaration: non-empty, and clean.
        if not v_roots:
            failures.append(f"NOSET: Check {v_id}'s declared array {v_array!r} is empty "
                            f"or unreadable, so arm P2 has no non-empty input")
        elif any(f.startswith(v_site) for f in base):
            failures.append(f"P2: Check {v_id}'s live population declaration is flagged "
                            f"unmutated — the arm over-matches a conforming declaration")

        # P1 — SENSITIVITY: a root that does not exist, appended to the live array.
        p1 = re.sub(r"(\b" + re.escape(v_array) + r"=\()",
                    r"\1 zzz-synthetic-missing-root ", deploy_text, count=1)
        if p1 == deploy_text:
            failures.append("P1-CTRL: could not append a root to the live array — the arm "
                            "would assert against an unmutated input")
        elif not any("zzz-synthetic-missing-root" in f for f in new_findings(deploy=p1)):
            failures.append(f"P1: a root that does not exist, appended to Check {v_id}'s "
                            f"declared array, was NOT flagged")

        # P8 — REACH, report side: the live `_population_report` call removed.
        p8 = region_mutated(lambda r: [ln for ln in r if not (
            "_population_report" in ln and not ln.lstrip().startswith("#"))])
        if p8 == deploy_text:
            failures.append("P8-CTRL: the worked reference carries no `_population_report` "
                            "call to remove")
        elif not any(f.startswith(v_site) and "_population_report" in f
                     for f in new_findings(deploy=p8)):
            failures.append(f"P8: removing Check {v_id}'s `_population_report` call was NOT "
                            f"flagged — a declared population could go unreported")

        # P8b — REACH, resolve side: the call's filter no longer the declared one.
        v_filter = v_fields.get("filter", "")
        p8b = region_mutated(lambda r: [
            ln.replace(f"'{v_filter}'", "'zzz-not-the-declared-filter'")
            if "_population_resolve" in ln and not ln.lstrip().startswith("#") else ln
            for ln in r])
        if p8b == deploy_text:
            failures.append("P8b-CTRL: the worked reference carries no `_population_resolve` "
                            "call passing its declared filter literal")
        elif not any(f.startswith(v_site) and "_population_resolve" in f
                     for f in new_findings(deploy=p8b)):
            failures.append(f"P8b: a `_population_resolve` call whose filter differs from "
                            f"Check {v_id}'s declaration was NOT flagged — the declared "
                            f"population could drift from the scanned one")

        # P9 — the worked reference's declaration removed.
        p9_lines = list(lines)
        del p9_lines[v_line - 1]
        if not any(f"worked-reference Check {v_id} " in f
                   for f in new_findings(deploy="\n".join(p9_lines) + "\n")):
            failures.append(f"P9: removing Check {v_id}'s population declaration was NOT "
                            f"flagged — the worked reference could vanish silently")

    # P3 / P3b / P3c — SENSITIVITY on the exemption unit, synthetic; P4 — SPECIFICITY.
    good = ("#   population: roots=core/standards  filter=*.md  "
            "exempts=file — a synthetic whole-file justification")
    if new_findings({"zzz-synthetic-p3.yml": _synthetic_workflow(good)}):
        failures.append("P3-CTRL: a well-formed synthetic declaration over a resolving root "
                        "was flagged — the unit arms would have no clean baseline")
    for arm, value in (("P3", "file"), ("P3b", "file/class"), ("P3c", "zzz-not-a-unit")):
        line = f"#   population: roots=core/standards  filter=*.md  exempts={value}"
        if len(new_findings({"zzz-synthetic-p3.yml": _synthetic_workflow(line)})) != 1:
            failures.append(f"{arm}: `exempts={value}` (no justification) did not draw "
                            f"exactly one finding")
    line = "#   population: roots=core/standards  filter=*.md  exempts=line"
    if new_findings({"zzz-synthetic-p3.yml": _synthetic_workflow(line)}):
        failures.append("P4: `exempts=line` — a narrower unit that needs no justification — "
                        "WAS flagged; the arm over-matches")

    # P7 — the synthetic check over an empty glob, and its non-empty control.
    empty = "#   population: roots=zzz-synthetic-empty-root  filter=*.md  exempts=none"
    if len(new_findings({"zzz-synthetic-p7.yml": _synthetic_workflow(empty)})) != 1:
        failures.append("P7: a synthetic declaration over an empty glob did not draw exactly "
                        "one finding")
    control = "#   population: roots=core/standards  filter=*.md  exempts=none"
    if new_findings({"zzz-synthetic-p7.yml": _synthetic_workflow(control)}):
        failures.append("P7 control: the same declaration over a resolving root WAS "
                        "flagged — the arm over-matches")

    # P6 — THE LEDGER BRANCH, on a SYNTHETIC ledger, every invocation.
    p6_ledger = {P6_KEY: "synthetic fixture entry (harness arm P6)"}
    found, hit, _, _, _ = evaluate_population({}, P6_REGION, tracked, ledger=p6_ledger)
    if P6_KEY not in hit or any(P6_ROOT in f for f in found):
        failures.append("P6: a ledgered zero-yield root was not recorded as a ledger hit, "
                        "or was reported as a finding although ledgered")
    if population_ledger_audit(hit, ledger=p6_ledger):
        failures.append("P6: the audit reported a ledger entry that still reproduces")
    found_bare, _, _, _, _ = evaluate_population({}, P6_REGION, tracked, ledger={})
    if not any(P6_ROOT in f for f in found_bare):
        failures.append("P6: with the ledger emptied, the zero-yield root was NOT reported "
                        "— the ledger is not what suppressed it")
    gone = P6_REGION.replace(f"      {P6_ROOT}\n", "")
    _, hit_gone, _, _, _ = evaluate_population({}, gone, tracked, ledger=p6_ledger)
    stale = population_ledger_audit(hit_gone, ledger=p6_ledger)
    if gone == P6_REGION or len(stale) != 1 or P6_ROOT not in stale[0]:
        failures.append("P6: removing the ledgered root did not make the audit report "
                        "exactly its stale entry")

    # P10 — RESOLVE ORDER, synthetic, every invocation. The region's findings are split
    # into the order finding and everything else; the worked-reference findings a bare
    # fixture always draws are not the fixture's, and are set aside.
    def p10_findings(region: list[str]) -> tuple[list[str], list[str]]:
        found, _, _, _, _ = evaluate_population(
            {}, "\n".join(region) + "\n", tracked, ledger={})
        own = [f for f in found if "worked-reference" not in f]
        return ([f for f in own if RESOLVE_ORDER_MARK in f],
                [f for f in own if RESOLVE_ORDER_MARK not in f])

    order, other = p10_findings(P10_REGION)
    if other:
        failures.append("P10-CTRL: the resolve-order fixture draws a finding other than the "
                        "order finding, so the arm would not isolate it: " + "; ".join(other))
    elif len(order) != 1:
        failures.append(f"P10: a second `_population_resolve` call without `--append`, ahead "
                        f"of any `_population_report`, drew {len(order)} order finding(s), "
                        f"not exactly one for its region — the call resets the population "
                        f"the first call resolved, and the per-call reach tests cannot see it")
    for arm, region in (("P10b", P10_APPENDED), ("P10c", P10_REPORTED)):
        order_c, other_c = p10_findings(region)
        if order_c or other_c:
            failures.append(f"{arm}: a conforming resolve order WAS flagged, so the arm "
                            f"over-matches: " + "; ".join(order_c + other_c))

    return failures


# ─── FIFTH INVARIANT — the census matches the populations it records ──────────────────
#
# gate-efficacy-standard.md § Exit-consumer and executor census renders the population
# record of Requirement (c) § Population shortfall — the seven labels `parse_census`
# reads beside `parse_population` — for three populations no single file enumerates. Every
# name from here to `census_harness` is new, the functions `reconcile-gate-posture.py`
# imports from this module are untouched, and nothing below runs at import time.

STANDARD_REL = "core/standards/gate-efficacy-standard.md"
CENSUS_HEADING = "## Exit-consumer and executor census"
POPULATION_RECORD_LABELS = ("population", "probe", "examined", "sensitivity",
                            "specificity", "state", "exempted")
RECORD_HEADING_RE = re.compile(r"^#### Population record — (?P<name>.+?)\s*$")
DRIFT_ENGINE_REL = "release/tools/check-release-body-drift.sh"
DRIFT_ENGINE_NAME = DRIFT_ENGINE_REL.rsplit("/", 1)[-1]
INSTALL_RUNNER_REL = "core/deploy/tests/run-install-regression.sh"
HOOK_SETUP_REL = "core/hooks/tests/setup-ci-layout.sh"
HOOK_SUITE_DIR = "core/hooks/tests/"

CENSUS_DRIFT = "drift-engine exit consumers"
CENSUS_WORKFLOW = "workflow binary exit consumers"
CENSUS_EXECUTOR = "test-suite executors"

# Per record: its key columns, its closed columns with their token sets, and the column
# that must carry a non-empty reason. The tokens are the census definitions' own, taken
# verbatim so a consumer of the partition reads the same words the census writes.
CENSUS_RECORDS: dict[str, tuple[tuple[str, ...], dict[str, tuple[str, ...]], str]] = {
    CENSUS_DRIFT: (("File", "Consuming unit", "Status variable"),
                   {"Classification": ("distinguishes", "fail-closed", "collapses")},
                   "Reason"),
    CENSUS_WORKFLOW: (("Workflow", "Step", "Status variable"),
                      {"Direction": ("gate", "probe"),
                       "Classification": ("consumes-a-fused-exit-space",
                                          "legitimately-binary")},
                      "Reason"),
    CENSUS_EXECUTOR: (("Suite",), {}, "Disposition"),
}

# A step run by a shell other than bash reads nothing below as shell code.
NON_BASH_SHELLS = ("pwsh", "powershell", "cmd", "python")

HEREDOC_RE = re.compile(r"(?<!<)<<(?!<)(-?)\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\2")
FUNCTION_DEF_RE = re.compile(
    r"^(?:function\s+([A-Za-z_][A-Za-z0-9_:-]*)|([A-Za-z_][A-Za-z0-9_:-]*)\s*\(\))\s*\{?\s*$")

# Command position: the start of a command — a line start, a separator, a group or
# substitution opener, or a keyword that introduces a command — optionally behind
# `NAME=value` prefixes, optionally behind an interpreter (and its flags, including
# `-m pytest`). What follows is EXECUTED; the same token anywhere else is only named.
_LEAD = (r"(?:^|[;&|({`]|\$\(|(?<![\w-])(?:then|do|else|elif|if|while|until|time)"
         r"(?![\w-])|!)")
_PREFIX = r"(?:\s*[A-Za-z_][A-Za-z0-9_]*=(?:\"[^\"]*\"|'[^']*'|[^\s;&|()`]*))*"
_INTERP = (r"(?:\s*(?:/usr/bin/env\s+)?(?:/usr/local/bin/|/opt/homebrew/bin/|/usr/bin/|"
           r"/bin/)?(?:bash|sh|zsh|ksh|dash|python3?(?:\.\d+)?|pytest|node)"
           r"(?:\s+-[A-Za-z]+(?:\s+pytest)?)*)?")
EXEC_LITERAL_RE = re.compile(
    _LEAD + _PREFIX + _INTERP
    + r"\s*[\"']?(?:\./)?(?P<path>[A-Za-z0-9_.][A-Za-z0-9_./*?\[\]-]*)[\"']?"
    + r"(?=[\s;&|)`]|$)")
EXEC_RUNNER_TAIL_RE = re.compile(
    _LEAD + _PREFIX + _INTERP + r"\s*[\"']?[^\s;&|()`\"']*/test-runner\.sh[\"']?(?=[\s;&|)`]|$)")

STATUS_ASSIGN_RE = re.compile(
    r"(?<![\w$])([A-Za-z_][A-Za-z0-9_]*)=(\"?)(?:\$\?|\$\{\?\}|\$\{PIPESTATUS\[\d+\]\})\2"
    r"(?![\w\[])")
OUTPUT_WRITE_RE = re.compile(
    r"\becho\s+[\"']?([A-Za-z_][A-Za-z0-9_-]*)=\$(?:\{([A-Za-z_]\w*)\}|([A-Za-z_]\w*)|(\?))"
    r"[\"']?\s*>>\s*\"?\$\{?GITHUB_OUTPUT\}?\"?")
STEP_OUTPUT_RE = re.compile(r"^\s*\$\{\{\s*steps\.([A-Za-z0-9_-]+)\.outputs\."
                            r"([A-Za-z0-9_-]+)\s*\}\}\s*$")
INLINE_OUTPUT_RE = re.compile(
    r"(?<![\w$])([A-Za-z_]\w*)=\"?\$\{\{\s*steps\.([A-Za-z0-9_-]+)\.outputs\."
    r"([A-Za-z0-9_-]+)\s*\}\}\"?")
SHELL_ASSIGN_RE = re.compile(
    r"(?:^|[\s;&|(])(?:(?:local|export|readonly|declare)(?:\s+-[A-Za-z]+)*\s+)?"
    r"([A-Za-z_][A-Za-z0-9_]*)=(\"[^\"]*\"|'[^']*'|[^\s;&|()]*)")
_TEST_OPS = r"(?:-eq|-ne|-gt|-lt|-ge|-le|==|!=|=)"

# Per-run memos. The anti-vacuity arms re-resolve populations over inputs that are
# mostly unchanged, and a text's code lines, a workflow's steps, or a file's decision
# sites depend on that text alone — so each is computed once per distinct text.
_UNITS_MEMO: dict[str, list[tuple[str, str]]] = {}
_STEPS_MEMO: dict[tuple[str, str], list[tuple[str, str, dict]]] = {}
_SITES_MEMO: dict[tuple[str, str], list[dict]] = {}


class CensusError(RuntimeError):
    """An input the census resolvers need could not be read, so they cannot assert."""


def _strip_comment(line: str) -> str:
    """The line without its shell comment. A `#` opens a comment only outside quotes and
    at a word start, so `$#`, `${#arr[@]}` and a quoted `#` survive."""
    quote = ""
    for index, ch in enumerate(line):
        if quote:
            if ch == quote:
                quote = ""
            elif ch == "\\" and quote == '"':
                continue
        elif ch in "\"'":
            quote = ch
        elif ch == "#" and (index == 0 or line[index - 1] in " \t;"):
            return line[:index]
    return line


def _shell_units(text: str) -> list[tuple[str, str]]:
    """The CODE of a shell text as (enclosing unit, logical line) pairs.

    Comment-only lines are dropped and trailing comments stripped; every heredoc BODY is
    dropped while its opener line is kept, so a Python program inside `<<'PY'` cannot read
    as shell; backslash continuations are joined into one logical line. The unit is the
    enclosing column-0 function (`name() {`), or `<top-level>` outside one — the key a
    decision site carries in place of a line number, which moves under any edit above it.
    """
    if text in _UNITS_MEMO:
        return _UNITS_MEMO[text]
    out: list[tuple[str, str]] = []
    pending: list[tuple[str, bool]] = []
    unit = "<top-level>"
    buf = ""
    for raw in text.splitlines():
        if pending:
            tag, tabs = pending[0]
            if (raw.lstrip("\t") if tabs else raw).rstrip() == tag:
                pending.pop(0)
            continue
        if not buf:
            head = FUNCTION_DEF_RE.match(raw)
            if head:
                unit = head.group(1) or head.group(2)
            elif raw.rstrip() == "}":
                unit = "<top-level>"
        line = _strip_comment(raw)
        if not line.strip():
            continue
        for match in HEREDOC_RE.finditer(line):
            pending.append((match.group(3), match.group(1) == "-"))
        stripped = line.rstrip()
        if stripped.endswith("\\") and not pending:
            buf += stripped[:-1] + " "
            continue
        out.append((unit, buf + line))
        buf = ""
    if buf:
        out.append((unit, buf))
    _UNITS_MEMO[text] = out
    return out


def _shell_code(text: str) -> list[str]:
    """The logical code lines of a shell text (see `_shell_units`)."""
    return [line for _, line in _shell_units(text)]


def _workflow_steps(name: str, text: str) -> list[tuple[str, str, dict]]:
    """Every run step of a workflow whose shell is bash, as (job key, step key, step).

    The step key is its `name`, else its `id`; a step with neither is keyed by its
    position, which a census row cannot name — so such a step stays visible to the
    resolvers but cannot be recorded until it is named. A workflow that does not parse is
    exit 2: the census cannot grade a population it could not read.
    """
    if (name, text) in _STEPS_MEMO:
        return _STEPS_MEMO[(name, text)]
    try:
        doc = yaml.safe_load(text)
    except yaml.YAMLError as exc:
        raise CensusError(f"{name}: workflow does not parse ({exc})") from exc
    if not isinstance(doc, dict) or not isinstance(doc.get("jobs"), dict):
        return []
    out: list[tuple[str, str, dict]] = []
    for job_key, job in doc["jobs"].items():
        if not isinstance(job, dict):
            continue
        for index, step in enumerate(job.get("steps") or []):
            if not isinstance(step, dict) or not isinstance(step.get("run"), str):
                continue
            if str(step.get("shell", "bash")).split()[0] in NON_BASH_SHELLS:
                continue
            key = step.get("name") or step.get("id") or f"<unnamed step {index + 1}>"
            out.append((str(job_key), str(key), step))
    _STEPS_MEMO[(name, text)] = out
    return out


def _var_ref(var: str) -> str:
    if var == "?":
        return r"\$(?:\?|\{\?\})"
    return (r"\$(?:" + re.escape(var) + r"(?![\w])|\{" + re.escape(var)
            + r"(?::?[-=+?][^}]*)?\})")


def _case_values(code: str, var: str) -> list[int] | None:
    """The integer labels of a `case` over `var`, or None when there is no such `case`.

    A consumer's shape is the set of values it compares, so a `case` adds its ARM LABELS
    and nothing else — a `*)` arm adds none, which is what lets a single-value `case`
    read binary-zero rather than multi-state because of its keyword.
    """
    match = re.search(r"\bcase\s+\"?" + _var_ref(var) + r"\"?\s+in\b", code)
    if not match:
        return None
    values: list[int] = []
    pos = match.end()
    depth = 0
    expect_label = True
    while pos < len(code):
        if expect_label:
            ahead = re.match(r"\s*(?:\(\s*)?([^()\n;]*?)\s*\)", code[pos:])
            done = re.match(r"\s*esac\b", code[pos:])
            if done or not ahead:
                break
            for part in ahead.group(1).split("|"):
                token = part.strip().strip("\"'")
                if token.isdigit():
                    values.append(int(token))
            pos += ahead.end()
            expect_label = False
            continue
        nxt = re.search(r";;&?|;&|\bcase\s+\S+\s+in\b|\besac\b", code[pos:])
        if not nxt:
            break
        word = nxt.group(0)
        pos += nxt.end()
        if word.startswith("case"):
            depth += 1
        elif word == "esac":
            if depth == 0:
                break
            depth -= 1
        elif depth == 0:
            expect_label = True
    return values


def _compared_values(code: str, var: str) -> tuple[set[int], bool]:
    """(the integer values `var` is compared against, whether a `case` dispatches on it)."""
    ref = _var_ref(var)
    values: set[int] = set()
    for pattern in (r"\"?" + ref + r"\"?\s*" + _TEST_OPS + r"\s*[\"']?(\d+)[\"']?(?![\w.])",
                    r"(?<![\w$])[\"']?(\d+)[\"']?\s*" + _TEST_OPS + r"\s*\"?" + ref + r"\"?",
                    r"\(\(\s*\$?\{?" + (re.escape(var) if var != "?" else r"\?")
                    + r"\}?\s*(?:==|!=|<=|>=|<|>)\s*(\d+)\s*\)\)"):
        values.update(int(m.group(1)) for m in re.finditer(pattern, code))
    labels = _case_values(code, var)
    if labels is not None:
        values.update(labels)
    return values, labels is not None


def workflow_exit_consumers(sources: dict[str, str]) -> list[dict]:
    """Every workflow exit-status consumer: one dict per (workflow, step, variable).

    A STATUS VARIABLE is one whose value is an exit status by provenance, never by
    spelling: assigned from `$?` or `${PIPESTATUS[n]}` in the step, or read back — through
    the step's `env:` or an inline assignment — from a step output that an earlier step in
    the same job wrote from such a variable. The literal `$?` compared in place counts
    too. A CONSUMER is a status variable the step compares; its shape is the set of values
    it compares against: `binary-zero` (only 0), `binary-exact` (one non-zero value),
    `multi-state` (two or more). A captured status the step never compares is no consumer.
    """
    consumers: list[dict] = []
    for name in sorted(sources):
        steps = _workflow_steps(name, sources[name])
        outputs: set[tuple[str, str, str]] = set()
        for job_key, step_key, step in steps:
            code = "\n".join(_shell_code(step["run"]))
            status = {m.group(1) for m in STATUS_ASSIGN_RE.finditer(code)}
            env = step.get("env") if isinstance(step.get("env"), dict) else {}
            for env_name, value in env.items():
                ref = STEP_OUTPUT_RE.match(str(value))
                if ref and (job_key, ref.group(1), ref.group(2)) in outputs:
                    status.add(str(env_name))
            for match in INLINE_OUTPUT_RE.finditer(code):
                if (job_key, match.group(2), match.group(3)) in outputs:
                    status.add(match.group(1))
            if re.search(_var_ref("?") + r"\"?\s*" + _TEST_OPS, code) \
                    or re.search(r"\bcase\s+\"?" + _var_ref("?"), code):
                status.add("?")
            if step.get("id"):
                for match in OUTPUT_WRITE_RE.finditer(code):
                    source = match.group(2) or match.group(3) or match.group(4)
                    if source in status:
                        outputs.add((job_key, str(step["id"]), match.group(1)))
            for var in sorted(status):
                values, dispatched = _compared_values(code, var)
                if not values and not dispatched:
                    continue
                if len(values) >= 2:
                    shape = "multi-state"
                elif values == {0}:
                    shape = "binary-zero"
                elif values:
                    shape = "binary-exact"
                else:
                    shape = "multi-state"   # a `case` whose every label is a pattern
                consumers.append({"workflow": name, "job": job_key, "step": step_key,
                                  "var": "$?" if var == "?" else var, "shape": shape,
                                  "values": sorted(values)})
    return consumers


def _execs(line: str, targets: list[str]) -> re.Match | None:
    """The first command-position execution, in `line`, of any regex in `targets`."""
    alternatives = "(?:" + "|".join(targets) + ")"
    return re.search(_LEAD + _PREFIX + _INTERP + r"\s*" + alternatives
                     + r"(?=[\s;&|)`]|$)", line)


def _bound_shell_names(code: list[str]) -> set[str]:
    """Names bound to the drift engine's path: a fixpoint over shell assignments whose
    value carries the engine's basename or a reference to a name already bound."""
    assigns = [(m.group(1), m.group(2)) for line in code
               for m in SHELL_ASSIGN_RE.finditer(line)]
    bound: set[str] = set()
    changed = True
    while changed:
        changed = False
        for name, value in assigns:
            if name in bound:
                continue
            if DRIFT_ENGINE_NAME in value or any(
                    re.search(r"\$\{?" + re.escape(b) + r"(?![\w])", value) for b in bound):
                bound.add(name)
                changed = True
    return bound


def _shell_drift_sites(where: str, units: list[tuple[str, str]], unit_of=None) -> list[dict]:
    """Decision sites in shell code: a line that EXECUTES the engine — a bound name or the
    engine's own path, at command position — and captures its status, on that line or
    the next. A name that is only tested (`[[ -x "$T" ]]`) or echoed is not a run."""
    code = [line for _, line in units]
    bound = _bound_shell_names(code)
    targets = [r"[\"']?\$\{?" + re.escape(b) + r"\}?[\"']?" for b in sorted(bound)]
    targets.append(r"[\"']?(?:\./)?(?:[A-Za-z0-9_.-]+/)*" + re.escape(DRIFT_ENGINE_NAME)
                   + r"[\"']?")
    sites: list[dict] = []
    for index, (unit, line) in enumerate(units):
        run = _execs(line, targets)
        if not run:
            continue
        capture = STATUS_ASSIGN_RE.search(line, run.end())
        if capture is None and index + 1 < len(units):
            capture = STATUS_ASSIGN_RE.match(units[index + 1][1].strip())
        if capture is None:
            continue
        sites.append({"file": where, "unit": unit_of or unit, "var": capture.group(1)})
    return sites


def _python_drift_sites(where: str, text: str) -> list[dict]:
    """Decision sites in Python: an assignment whose value is a call carrying a name bound
    to the engine — or the engine's path — INSIDE a list or tuple argument, the argv form.
    `os.path.join(root, NAME)` binds a name; it does not run anything. The status variable
    is the assignment's first target name, and the unit its enclosing `def`."""
    try:
        tree = ast.parse(text, filename=where)
    except SyntaxError as exc:
        raise CensusError(f"{where}: does not parse as Python ({exc})") from exc
    parents: dict[ast.AST, ast.AST] = {}
    for node in ast.walk(tree):
        for child in ast.iter_child_nodes(node):
            parents[child] = node
    assigns = [n for n in ast.walk(tree) if isinstance(n, ast.Assign)]

    def names(target: ast.AST) -> list[str]:
        if isinstance(target, ast.Name):
            return [target.id]
        if isinstance(target, (ast.Tuple, ast.List)):
            return [x for e in target.elts for x in names(e)]
        return []

    def engine_literal(node: ast.AST) -> bool:
        return isinstance(node, ast.Constant) and isinstance(node.value, str) \
            and DRIFT_ENGINE_NAME in node.value

    bound: set[str] = set()
    changed = True
    while changed:
        changed = False
        for node in assigns:
            carried = any(engine_literal(x) or (isinstance(x, ast.Name) and x.id in bound)
                          for x in ast.walk(node.value))
            for target_name in (x for t in node.targets for x in names(t)):
                if carried and target_name not in bound:
                    bound.add(target_name)
                    changed = True
    sites: list[dict] = []
    for node in assigns:
        call = node.value
        while isinstance(call, (ast.Attribute, ast.Subscript)):
            call = call.value
        if not isinstance(call, ast.Call):
            continue
        argv = [a for a in list(call.args) + [k.value for k in call.keywords]
                if isinstance(a, (ast.List, ast.Tuple))]
        if not any(engine_literal(e) or (isinstance(e, ast.Name) and e.id in bound)
                   for a in argv for e in a.elts):
            continue
        target_names = [x for t in node.targets for x in names(t)]
        if not target_names:
            continue
        unit, up = "<module>", parents.get(node)
        while up is not None:
            if isinstance(up, (ast.FunctionDef, ast.AsyncFunctionDef)):
                unit = up.name
                break
            up = parents.get(up)
        sites.append({"file": where, "unit": unit, "var": target_names[0]})
    return sites


def drift_engine_sites(root: Path, tracked: list[str], sources: dict[str, str],
                       extra: dict[str, str] | None = None) -> tuple[list[dict], int]:
    """(every decision site that runs the drift engine, the candidate-file count).

    Candidates are the tracked shell and Python files — outside any `tests` or `fixtures`
    directory, and other than the engine itself — whose text names the engine; `extra`
    adds in-memory files for the anti-vacuity arms. Workflow `run:` steps are scanned too,
    keyed (workflow path, step, variable), because the not-evaluated member reaches a job
    surface there, which is where the defect class this census exists for is defined.
    """
    files: dict[str, str] = {}
    for path in tracked:
        parts = path.split("/")
        if path == DRIFT_ENGINE_REL or "tests" in parts or "fixtures" in parts:
            continue
        if not path.endswith((".sh", ".bash", ".py")):
            continue
        try:
            text = (root / path).read_text(encoding="utf-8", errors="replace")
        except OSError as exc:
            raise CensusError(f"{path}: unreadable ({exc})") from exc
        if DRIFT_ENGINE_NAME in text:
            files[path] = text
    files.update(extra or {})
    sites: list[dict] = []
    for path in sorted(files):
        key = (path, files[path])
        if key not in _SITES_MEMO:
            _SITES_MEMO[key] = (_python_drift_sites(path, files[path])
                                if path.endswith(".py")
                                else _shell_drift_sites(path, _shell_units(files[path])))
        sites += _SITES_MEMO[key]
    for name in sorted(sources):
        for _, step_key, step in _workflow_steps(name, sources[name]):
            units = [(step_key, line) for line in _shell_code(step["run"])]
            sites += _shell_drift_sites(f".github/workflows/{name}", units, step_key)
    return sites, len(files)


def regression_members(root: Path) -> list[str]:
    """The install-regression runner's `REGRESSION_MEMBERS` array, read as the runner
    declares it. A missing runner, or an array that does not parse, is exit 2."""
    try:
        text = (root / INSTALL_RUNNER_REL).read_text(encoding="utf-8")
    except OSError as exc:
        raise CensusError(f"{INSTALL_RUNNER_REL}: unreadable ({exc})") from exc
    match = re.search(r"^REGRESSION_MEMBERS=\((?P<body>.*?)^\)", text, re.M | re.S)
    if not match:
        raise CensusError(f"{INSTALL_RUNNER_REL}: no REGRESSION_MEMBERS=( … ) array")
    body = "\n".join(_strip_comment(line) for line in match.group("body").splitlines())
    try:
        members = shlex.split(body)
    except ValueError as exc:
        raise CensusError(f"{INSTALL_RUNNER_REL}: REGRESSION_MEMBERS does not parse "
                          f"({exc})") from exc
    if not members:
        raise CensusError(f"{INSTALL_RUNNER_REL}: REGRESSION_MEMBERS is empty")
    return members


def is_suite(path: str) -> bool:
    base = path.rsplit("/", 1)[-1]
    return "fixtures" not in path.split("/") and (
        fnmatch.fnmatchcase(base, "test_*.sh") or fnmatch.fnmatchcase(base, "test_*.py")
        or fnmatch.fnmatchcase(base, "*.test.sh"))


def suite_executors(root: Path, tracked: list[str], sources: dict[str, str],
                    members: list[str] | None = None,
                    ) -> tuple[list[str], dict[str, list[str]]]:
    """(every suite, suite -> its executors). A suite with no executor is zero-executor.

    An EXECUTOR is a workflow run step that EXECUTES the suite — its tracked
    repository-relative path at command position, directly or as an interpreter operand
    (`python3 -m pytest <path>` included), never an operand rooted in a variable — or a
    runner such a step executes whose member declaration enumerates it: the
    install-regression runner's `REGRESSION_MEMBERS` (its `core/deploy/tests/` members),
    or the hook floor's `*.test.sh` glob over its own directory, reached by the tracked
    layout script at command position and a `test-runner.sh` it then runs; or a `for` loop
    whose body executes the loop variable, over a tracked glob. A path that is only
    NAMED — a `sed` operand, a redirection target, a copy under a scratch directory — is
    not an execution, so a step that mentions a runner without running it wires nothing.
    """
    suites = sorted(p for p in tracked if is_suite(p))
    executors: dict[str, list[str]] = {s: [] for s in suites}
    runner_steps: list[str] = []
    hook_setup_steps: list[str] = []
    hook_runner_steps: list[str] = []
    for name in sorted(sources):
        for _, step_key, step in _workflow_steps(name, sources[name]):
            where = f"{name} › {step_key}"
            code = _shell_code(step["run"])
            joined = "\n".join(code)
            for line in code:
                for match in EXEC_LITERAL_RE.finditer(line):
                    path = match.group("path")
                    if path in executors:
                        executors[path].append(f"{where} (runs its path)")
                    if path == INSTALL_RUNNER_REL:
                        runner_steps.append(where)
                    if path == HOOK_SETUP_REL:
                        hook_setup_steps.append(where)
                if EXEC_RUNNER_TAIL_RE.search(line):
                    hook_runner_steps.append(where)
            for loop in re.finditer(r"\bfor\s+([A-Za-z_]\w*)\s+in\s+(.*?)\s*;?\s*\bdo\b"
                                    r"(.*?)\bdone\b", joined, re.S):
                var, words, body = loop.group(1), loop.group(2), loop.group(3)
                runs_var = any(_execs(line, [r"[\"']?" + _var_ref(var) + r"[\"']?"])
                               for line in body.splitlines())
                if not runs_var:
                    continue
                for word in shlex.split(words.replace("\\\n", " ")):
                    if word.startswith("$") or not any(c in word for c in "*?["):
                        continue
                    for suite in suites:
                        if fnmatch.fnmatchcase(suite, word):
                            executors[suite].append(f"{where} (loop over {word})")
    if runner_steps:
        enrolled = members if members is not None else regression_members(root)
        for member in enrolled:
            path = "core/deploy/tests/" + member
            if path in executors:
                executors[path] += [f"{s} (install-regression member)" for s in runner_steps]
    hook_steps = [s for s in hook_setup_steps if s in hook_runner_steps]
    if hook_steps:
        for suite in suites:
            rest = suite[len(HOOK_SUITE_DIR):] if suite.startswith(HOOK_SUITE_DIR) else ""
            if rest and "/" not in rest and rest.endswith(".test.sh"):
                executors[suite] += [f"{s} (hook-floor member)" for s in hook_steps]
    return suites, executors


def census_populations(root: Path, tracked: list[str], sources: dict[str, str], *,
                       extra_files: dict[str, str] | None = None,
                       members: list[str] | None = None) -> dict:
    """The three populations the census records, re-derived from the tree in one pass."""
    sites, candidates = drift_engine_sites(root, tracked, sources, extra=extra_files)
    suites, executors = suite_executors(root, tracked, sources, members=members)
    return {"consumers": workflow_exit_consumers(sources), "sites": sites,
            "candidates": candidates, "suites": suites, "executors": executors,
            "workflows": len(sources)}


def _key_text(key: tuple[str, ...]) -> str:
    return "(" + ", ".join(key) + ")"


def evaluate_census(census_text: str, sources: dict[str, str], root: Path,
                    tracked: list[str], *, extra_files: dict[str, str] | None = None,
                    members: list[str] | None = None, populations: dict | None = None,
                    ) -> tuple[list[str], list[str], dict, bool]:
    """Return (findings, unrecorded zero-executor suites, reach, NOSET).

    A FIFTH ORACLE, AND SO A FIFTH FUNCTION: the census against the populations it
    records, RE-DERIVED from the tree on every run — a census nothing re-derives goes
    stale silently, which is how the executor census this invariant replaces went stale
    twice. The drift-engine and workflow records are graded as SETS: every live member has
    exactly one row (a live member with no row is a finding), no row names a member that
    is gone (a stale row is a finding), and `examined:` equals the row count. The executor
    record lists only the zero-executor suites, so it is graded differently: a listed
    suite that has gained an executor is a stale row and a finding, while a zero-executor
    suite with no row — a new one, or one whose row was deleted — is RETURNED, not a
    finding: whether a suite no step runs should fail a merge is the self-test coverage
    checker's decision, and this record does not pre-empt it. Its `examined:` is the suite
    count at the census commit, a snapshot the runtime reach line supersedes, and is read
    for form only.

    NOSET is keyed on each resolver's INPUT, never on a member subset that may
    legitimately reach zero: no exit-status consumer of any shape, no file naming the
    drift engine, or no suite. `populations` lets the anti-vacuity harness reuse a pass it
    already made rather than re-resolve the tree for every arm.
    """
    pops = populations if populations is not None else census_populations(
        root, tracked, sources, extra_files=extra_files, members=members)
    records, findings = parse_census(census_text)
    consumers, sites = pops["consumers"], pops["sites"]
    suites, executors = pops["suites"], pops["executors"]
    members_bz = [c for c in consumers if c["shape"] == "binary-zero"]
    zero = sorted(s for s in suites if not executors[s])
    listed = [key[0] for key in records.get(CENSUS_EXECUTOR, {}).get("keys", [])]
    reach = {
        "sites": len(sites), "site_files": len({s["file"] for s in sites}),
        "candidates": pops["candidates"], "binary_zero": len(members_bz),
        "consumers": len(consumers),
        "consumer_files": len({c["workflow"] for c in consumers}),
        "workflows": pops["workflows"],
        "binary_exact": sum(1 for c in consumers if c["shape"] == "binary-exact"),
        "multi_state": sum(1 for c in consumers if c["shape"] == "multi-state"),
        "suites": len(suites), "zero_executor": len(zero), "recorded": len(listed),
    }
    if not consumers or pops["candidates"] == 0 or not suites:
        return findings, [], reach, True

    def grade(name: str, live_keys: list[tuple[str, ...]], add_hint: str) -> None:
        for key in sorted({k for k in live_keys if live_keys.count(k) > 1}):
            findings.append(f"{STANDARD_REL}: {name}: two live members share the key "
                            f"{_key_text(key)}, so no row can name either — give each a "
                            f"distinct step name or status variable")
        record = records.get(name)
        if record is None or not record["columns"]:
            return
        rows, live = set(record["keys"]), set(live_keys)
        for key in sorted(live - rows):
            findings.append(f"{STANDARD_REL}: {name}: {_key_text(key)} is a member the "
                            f"census does not record — {add_hint}")
        for key in sorted(rows - live):
            findings.append(f"{STANDARD_REL}: {name}: stale row {_key_text(key)} names no "
                            f"live member — delete it, or restore the member it records")
        if record["examined"] is not None and record["examined"] != len(record["keys"]):
            findings.append(f"{STANDARD_REL}: {name}: `examined: {record['examined']}` "
                            f"disagrees with its {len(record['keys'])} row(s)")

    grade(CENSUS_DRIFT, [(s["file"], s["unit"], s["var"]) for s in sites],
          "add its row, classified distinguishes, fail-closed or collapses with a reason, "
          "in the change that adds the run")
    grade(CENSUS_WORKFLOW, [(c["workflow"], c["step"], c["var"]) for c in members_bz],
          "add its row, with its direction, a classification and a reason, in the change "
          "that adds the step — or make the step compare the values it means")
    for suite in listed:
        if suite not in executors:
            findings.append(f"{STANDARD_REL}: {CENSUS_EXECUTOR}: stale row ({suite}) names "
                            f"no tracked suite — delete it with the suite")
        elif suite not in zero:
            findings.append(f"{STANDARD_REL}: {CENSUS_EXECUTOR}: stale row ({suite}) — the "
                            f"suite now has an executor ({executors[suite][0]}); delete the "
                            f"row in the change that wired it")
    return findings, [s for s in zero if s not in listed], reach, False


def _census_layout(text: str) -> dict[str, dict]:
    """Line indices of each census record — its `examined:` line, its table header, and
    its data rows — so the harness can mutate the standard's text in memory."""
    lines = text.splitlines()
    layout: dict[str, dict] = {}
    current = None
    fence = False
    for index, line in enumerate(lines):
        head = RECORD_HEADING_RE.match(line)
        if head:
            current = {"examined": None, "header": None, "rows": []}
            layout[head.group("name")] = current
            fence = False
            continue
        if current is None:
            continue
        if line.startswith("```"):
            fence = not fence
            continue
        if fence and line.startswith("examined:"):
            current["examined"] = index
        elif not fence and line.lstrip().startswith("|"):
            if current["header"] is None:
                current["header"] = index
            elif index > current["header"] + 1 and (not current["rows"]
                                                     or current["rows"][-1] == index - 1):
                current["rows"].append(index)
        elif not fence and line.startswith("#"):
            current = None
    return layout


def _synthetic_steps_yaml(steps: list[tuple[str, str]]) -> str:
    """A minimal, VALID workflow carrying the given (step name, run) pairs — the census
    resolvers parse workflows structurally, so an arm's plant must parse too."""
    return yaml.safe_dump(
        {"name": "zzz census synthetic", "on": {"pull_request": None},
         "jobs": {"planted": {"runs-on": "ubuntu-latest",
                              "steps": [{"name": n, "run": r} for n, r in steps]}}},
        sort_keys=False)


def census_harness(census_text: str, sources: dict[str, str], root: Path,
                   tracked: list[str], populations: dict | None = None,
                   ) -> tuple[list[str], list[str]]:
    """Anti-vacuity for the census, on the doctrine of the four harnesses above: an arm
    that cannot be BUILT is a reported NOSET rather than a skip, and each sensitivity arm
    has a specificity arm on non-empty input. Returns (failures, notes) — a note records an
    arm that did not trigger, so the anti-vacuity line never claims an arm that did not run.

    The DETECTOR arms run on synthetic inputs on every invocation — planted workflows and
    tool files, planted suites, and in-memory edits of the census — so no state the census
    itself polices can empty them. One specificity arm is DRAWN from the live tree as well
    (CS-8b): the live step that names a regression runner without executing it is the
    near-miss the executor predicate exists to reject, and a case the author constructed
    proves only the author's imagination.
    """
    failures: list[str] = []
    notes: list[str] = []
    pops = populations if populations is not None else census_populations(
        root, tracked, sources)
    base, base_unrecorded, _, noset = evaluate_census(census_text, sources, root, tracked,
                                                      populations=pops)
    if noset:
        return (["NOSET: a census population re-derived empty, so arms CS-1…CS-11 cannot "
                 "be built — reported rather than skipped"], notes)
    # Every arm grades against a census record, so a census section or record that is
    # absent — or carries no member table — leaves nothing to grade a planted member
    # against. That is ONE NOSET naming what is missing, the population arm's P5
    # precedent, never a string of arms each misreporting why it drew no finding.
    parsed, _ = parse_census(census_text)
    missing = [name for name in CENSUS_RECORDS if not parsed.get(name, {}).get("columns")]
    if missing:
        what = ("the census section" if not parsed else
                "census record(s) " + ", ".join(repr(m) for m in missing))
        return ([f"NOSET: {what} is absent from {STANDARD_REL} or carries no member table, "
                 f"so arms CS-1…CS-11 have nothing to grade against — reported rather than "
                 f"skipped"], notes)

    def run(text: str = census_text, extra_sources: dict[str, str] | None = None,
            extra_files: dict[str, str] | None = None, tree: list[str] | None = None,
            members: list[str] | None = None, reuse: bool = False,
            ) -> tuple[list[str], list[str]]:
        mutated = dict(sources)
        mutated.update(extra_sources or {})
        live = tracked if tree is None else tree
        p = pops if reuse else census_populations(root, live, mutated,
                                                  extra_files=extra_files, members=members)
        found, unrecorded, _, _ = evaluate_census(text, mutated, root, live, populations=p)
        return [f for f in found if f not in base], unrecorded

    def names(finding_set: list[str], *parts: str) -> bool:
        return any(all(p in f for p in parts) for f in finding_set)

    # CS-1 / CS-2 — the workflow record. A planted step that captures a status and tests
    # only 0 must draw exactly one finding naming it; a planted step testing 3 before 0,
    # and a counter tested against 0, must draw none.
    cs1 = "zz-census-planted.yml"
    new, _ = run(extra_sources={cs1: _synthetic_steps_yaml([
        ("census planted fused consumer",
         'OUT="$(bash x.sh)"; RC=$?\nif [ "$RC" -eq 0 ]; then echo ok; fi\n'),
        ("census planted multi-state consumer",
         'OUT="$(bash y.sh)"; RC2=$?\nif [ "$RC2" -eq 3 ]; then echo skip; '
         'elif [ "$RC2" -eq 0 ]; then echo ok; fi\n'),
        ("census planted counter", 'N=0\nif [ "$N" -eq 0 ]; then echo none; fi\n')])})
    if len(new) != 1 or not names(new, cs1, "census planted fused consumer", "RC)"):
        failures.append(f"CS-1: a planted binary-zero consumer drew {len(new)} new "
                        f"finding(s), not exactly one naming it")
    if names(new, "census planted multi-state consumer") or names(new, "census planted counter"):
        failures.append("CS-2: a planted multi-state consumer, or a counter tested against "
                        "0, WAS counted — the resolver reads spelling, not provenance and "
                        "shape")

    # CS-2b — a `case` counts its arm labels, not its keyword: a single-value `case` is
    # binary-zero, and a `case` over 0 and 2|3 is not.
    cs2b = "zz-census-case.yml"
    new, _ = run(extra_sources={cs2b: _synthetic_steps_yaml([
        ("census planted single-value case",
         'OUT="$(bash z.sh)"; RC3=$?\ncase "$RC3" in\n  0) echo ok ;;\n  *) exit 1 ;;\nesac\n'),
        ("census planted multi-value case",
         'OUT="$(bash z.sh)"; RC4=$?\ncase "$RC4" in\n  0) echo ok ;;\n  2|3) echo na ;;\n'
         '  *) exit 1 ;;\nesac\n')])})
    if len(new) != 1 or not names(new, cs2b, "census planted single-value case", "RC3)"):
        failures.append(f"CS-2b: a single-value `case` drew {len(new)} new finding(s), not "
                        f"exactly one naming it — the shape rule is reading the keyword")

    # CS-3 / CS-4 — the drift record over tool files: a planted file that binds the engine,
    # runs it and captures its status is counted; one that only tests and names it is not.
    engine = DRIFT_ENGINE_REL
    new, _ = run(extra_files={"release/tools/zz-census-planted.sh":
                              f'T="{engine}"\nd=0; "$T" "$V" --quiet >/dev/null 2>&1 || d=$?\n'})
    if len(new) != 1 or not names(new, "release/tools/zz-census-planted.sh", "<top-level>", "d)"):
        failures.append(f"CS-3: a planted drift-engine run drew {len(new)} new finding(s), "
                        f"not exactly one naming it")
    new, _ = run(extra_files={"release/tools/zz-census-nearmiss.sh":
                              f'T="{engine}"\n[[ -x "$T" ]] || echo "missing: $T"; rc=$?\n'})
    if new:
        failures.append("CS-4: a file that binds the engine but only tests and names it WAS "
                        "counted as a run")

    # CS-3w — the drift record over workflow steps: a step that runs the engine by its
    # path, captures its status and dispatches on three values is a drift-engine site
    # keyed by the workflow path and step, and — being multi-state — no workflow member.
    cs3w = "zz-census-drift.yml"
    new, _ = run(extra_sources={cs3w: _synthetic_steps_yaml([
        ("census planted drift run",
         f'd=0\n{engine} "$V" --quiet >/dev/null 2>&1 || d=$?\ncase "$d" in\n'
         '  0) echo match ;;\n  2|3) echo not-evaluated ;;\n  *) exit 1 ;;\nesac\n')])})
    if len(new) != 1 or not names(new, CENSUS_DRIFT, f".github/workflows/{cs3w}",
                                   "census planted drift run"):
        failures.append(f"CS-3w: a workflow step running the drift engine drew {len(new)} "
                        f"new finding(s), not exactly one drift-record finding naming it")

    # CS-5a / CS-5b / CS-6 / CS-11 — in-memory edits of the census itself.
    lines = census_text.splitlines()
    layout = _census_layout(census_text)

    def edited(edit) -> str:
        copy = list(lines)
        edit(copy)
        return "\n".join(copy) + "\n"

    for record in (CENSUS_DRIFT, CENSUS_WORKFLOW):
        spot = layout.get(record)
        if not spot or not spot["rows"]:
            failures.append(f"NOSET: the census {record!r} record has no row, so arm CS-5a "
                            f"cannot be built — reported rather than skipped")
            continue
        header = _table_cells(lines[spot["header"]])
        victim = _table_cells(lines[spot["rows"][0]])
        key_cols = CENSUS_RECORDS[record][0]
        key = tuple(dict(zip(header, victim))[c] for c in key_cols)
        new, _ = run(text=edited(lambda c, i=spot["rows"][0]: c.pop(i)), reuse=True)
        if not names(new, record, _key_text(key), "does not record"):
            failures.append(f"CS-5a: deleting the {record!r} row {_key_text(key)} was NOT "
                            f"flagged")
        fake = list(victim)
        fake[0] = "zz-census-fabricated-member"
        fake_key = tuple(dict(zip(header, fake))[c] for c in key_cols)
        new, _ = run(text=edited(lambda c, i=spot["rows"][-1], f=fake: c.insert(
            i + 1, "| " + " | ".join(f) + " |")), reuse=True)
        if not names(new, record, _key_text(fake_key), "stale row"):
            failures.append(f"CS-5b: a fabricated {record!r} row was NOT flagged stale")

    spot = layout.get(CENSUS_DRIFT)
    if spot and spot["examined"] is not None:
        count = int(re.match(r"examined:\s*(\d+)", lines[spot["examined"]]).group(1))
        new, _ = run(text=edited(lambda c, i=spot["examined"], n=count: c.__setitem__(
            i, re.sub(r"^examined:\s*\d+", f"examined: {n + 1}", c[i]))), reuse=True)
        if not names(new, CENSUS_DRIFT, "`examined:"):
            failures.append("CS-6: a drift record `examined:` one above its rows was NOT "
                            "flagged")
    else:
        failures.append("NOSET: the drift record carries no `examined:` line, so arm CS-6 "
                        "cannot be built — reported rather than skipped")
    if spot and spot["rows"]:
        new, _ = run(text=edited(lambda c, i=spot["rows"][0]: c.__setitem__(
            i, re.sub(r"`(distinguishes|fail-closed|collapses)`", "`fail-open`", c[i], 1))),
                     reuse=True)
        if not names(new, "'fail-open'", "outside the closed set"):
            failures.append("CS-11: a classification token outside the closed set was NOT "
                            "flagged")

    # CS-7 / CS-7b / CS-8 — the executor record: a planted suite with no executor is
    # REPORTED, never a finding; so is a listed suite whose row is deleted; a planted file
    # under fixtures/ is not a suite; and a suite the install runner enrolls has one.
    planted = "core/deploy/tests/test_zzz_census_planted.sh"
    new, unrecorded = run(tree=tracked + [planted])
    if new or planted not in unrecorded:
        failures.append("CS-7: a planted zero-executor suite was not reported, or was "
                        "reported as a finding rather than returned")
    spot = layout.get(CENSUS_EXECUTOR)
    if spot and spot["rows"]:
        new, unrecorded = run(text=edited(lambda c, rows=spot["rows"]: [
            c.pop(i) for i in reversed(rows)]), reuse=True)
        if new or not set(base_unrecorded) < set(unrecorded):
            failures.append("CS-7b: deleting the executor record's rows raised a finding, "
                            "or did not report the suites they listed")
    else:
        notes.append("CS-7b NOT TRIGGERED — the executor record lists no suite")
    fixture = "core/deploy/tests/fixtures/test_zzz_census_fixture.sh"
    fixture_suites, _ = suite_executors(root, tracked + [fixture], sources)
    if fixture_suites != pops["suites"]:
        failures.append("CS-8: a planted test_*.sh under fixtures/ was counted as a suite")
    enrolled = regression_members(root) + [planted.rsplit("/", 1)[-1]]
    _, unrecorded = run(tree=tracked + [planted], members=enrolled)
    if planted in unrecorded:
        failures.append("CS-8: a planted suite enrolled in the install runner's member array "
                        "was reported zero-executor — rule (b) is not resolving")

    # CS-8b — execute, never mention. A step that names both runners — a `sed` operand, a
    # redirection target, a copy under a scratch directory — and executes only the copy
    # wires nothing. Constructed, and drawn from the live tree.
    floor = [s for s in pops["suites"] if s.startswith(HOOK_SUITE_DIR)]
    runner_members = ["core/deploy/tests/" + m for m in regression_members(root)]

    def wired_by(step_sources: dict[str, str]) -> list[str]:
        _, execs = suite_executors(root, tracked, step_sources)
        return [s for s in runner_members + floor if execs.get(s)]

    constructed = _synthetic_steps_yaml([("census planted runner mention", (
        'tmp="$(mktemp -d)"\n'
        f"sed -e 's/x/y/' {INSTALL_RUNNER_REL} > \"$tmp/{INSTALL_RUNNER_REL}\"\n"
        f'bash "$tmp/{INSTALL_RUNNER_REL}"\n'
        f"cat > \"$tmp/{HOOK_SETUP_REL}\" <<'STUB'\necho stub\nSTUB\n"
        ': > "$tmp/core/hooks/tests/test-runner.sh"\n'))])
    if wired_by({"zz-census-mention.yml": constructed}):
        failures.append("CS-8b: a step that only NAMES the runners (constructed) wired their "
                        "members — a mention is being counted as an execution")
    # The drawn step is SELECTED by a shape the predicate under test does not decide — it
    # names a runner's tracked path AND a copy of that same path under a variable-rooted
    # scratch directory — so a regression in the executor predicate cannot also hide the
    # step this arm draws. Selecting with the predicate itself would let a mention-counting
    # regression reclassify the near-miss as an execution and drop it from the arm.
    drawn = []
    for name in sorted(sources):
        for _, step_key, step in _workflow_steps(name, sources[name]):
            text = "\n".join(_shell_code(step["run"]))
            if any(runner in text and re.search(r"\$\{?\w+\}?/" + re.escape(runner), text)
                   for runner in (INSTALL_RUNNER_REL, HOOK_SETUP_REL)):
                drawn.append((name, step_key, step["run"]))
    if drawn:
        name, step_key, run_text = drawn[0]
        if wired_by({"zz-census-drawn.yml": _synthetic_steps_yaml([(step_key, run_text)])}):
            failures.append(f"CS-8b: the live step {name} › {step_key}, which names a runner "
                            f"without executing it, wired that runner's members")
    else:
        notes.append("CS-8b drawn half NOT TRIGGERED — no live step names a regression "
                     "runner without executing it; the constructed half ran")

    # CS-9 — a fabricated zero-executor row naming a suite that HAS an executor is stale.
    wired = next((s for s in pops["suites"] if pops["executors"][s]), None)
    anchor = None
    if spot and spot["rows"]:
        anchor = spot["rows"][-1]
    elif spot and spot["header"] is not None:
        anchor = spot["header"] + 1
    if anchor is not None and wired:
        new, _ = run(text=edited(lambda c, i=anchor, s=wired: c.insert(
            i + 1, f"| `{s}` | zz-census-fabricated row |")), reuse=True)
        if not names(new, CENSUS_EXECUTOR, wired, "stale row"):
            failures.append("CS-9: a zero-executor row naming a suite that has an executor "
                            "was NOT flagged stale")
    else:
        failures.append("NOSET: no executor-record table or no suite with an executor, so "
                        "arm CS-9 cannot be built — reported rather than skipped")

    # CS-10 — an empty population is NOSET, never a clean census.
    if not evaluate_census(census_text, {}, root, tracked)[3]:
        failures.append("CS-10: an empty workflow population did not read NOSET")
    if not evaluate_census(census_text, sources, root, [])[3]:
        failures.append("CS-10: an empty tracked tree did not read NOSET")
    return failures, notes


def load(root: Path) -> dict[str, str]:
    workflows = sorted(
        p for p in (root / ".github" / "workflows").iterdir()
        if p.suffix in (".yml", ".yaml")
    )
    return {p.name: p.read_text(encoding="utf-8") for p in workflows}


def edit_header(text: str, old: str, new: str, occurrence: int = 1) -> str:
    """Replace `old` with `new` INSIDE the gate-efficacy header line only.

    Scoped to the header rather than to the file because at least one workflow
    restates its own posture string in body prose; a whole-file replace would mutate
    the narrative copy and the arm would then assert against an unchanged declaration.

    `occurrence` selects WHICH declaration to mutate, 1-based over the header lines
    that contain `old`. It defaults to the first, which is what every arm but A8
    wants; A8 passes 2 deliberately, because an arm that only ever mutates the first
    declaration cannot tell a whole-set grader from a first-match-only one.
    """
    lines = text.splitlines()
    seen = 0
    for index, line in enumerate(lines):
        if HEADER_RE.match(line.strip()) and old in line:
            seen += 1
            if seen < occurrence:
                continue
            lines[index] = line.replace(old, new, 1)
            break
    return "\n".join(lines) + "\n"


def harness(sources: dict[str, str], filtered: list[str],
            filter_free: list[str]) -> list[str]:
    """Anti-vacuity. Every arm mutates an in-memory copy of a LIVE workflow and
    requires the detector to react. An arm that cannot be BUILT is NOSET, not a skip.

    ARM COVERAGE IS THE DESIGN CONSTRAINT, not arm count. `evaluate` has FOUR finding
    branches — filtered-without-`skip-semantics`, filtered-declaring-`always-reports`,
    filter-free-without-`always-reports`, filter-free-declaring-`skip-semantics` —
    plus the no-header branch. An earlier arm set covered only three of the five: A1
    exercised the second, A2 the fourth, A4 the fifth, and A3's filter deletion was
    ALSO caught by the fourth, so deleting either VALUE branch outright left the suite
    green. That hole was found by mutation-grading this file against itself, not by
    reading it, which is why A6 and A7 exist and why the grading is recorded in the
    register row rather than the arm count.
    """
    failures: list[str] = []

    def flags(name: str, mutate) -> bool:
        mutated = dict(sources)
        mutated[name] = mutate(sources[name])
        if mutated[name] == sources[name]:
            failures.append(f"A-CTRL: mutation of {name} changed nothing — the arm "
                            f"asserts against an unmutated input")
            return False
        found, _, _, _ = evaluate(mutated)
        return bool(found)

    if not filtered:
        failures.append("NOSET: no path-filtered workflow exists, so arms A1/A3/A6 "
                        "cannot be built — reported rather than skipped")
    if not filter_free:
        failures.append("NOSET: no filter-free workflow exists, so arms A2/A4/A5/A7 "
                        "cannot be built — reported rather than skipped")

    if filtered:
        victim = filtered[0]
        # A1 — branch 2: always-reports injected into a FILTERED header.
        if not flags(victim, lambda t: edit_header(
                t, "skip-semantics=absent-is-pass",
                "skip-semantics=absent-is-pass  always-reports=yes")):
            failures.append(f"A1: injecting always-reports into filtered {victim} was "
                            f"NOT flagged")
        # A6 — branch 1: the filter kept, the declared value taken out of the enum.
        # This is the arm that covers the filtered-side VALUE test; without it,
        # deleting that whole branch leaves the suite green.
        if not flags(victim, lambda t: edit_header(
                t, "skip-semantics=absent-is-pass",
                "skip-semantics=zzz-not-the-enum")):
            failures.append(f"A6: a non-enum skip-semantics value on filtered {victim} "
                            f"was NOT flagged")
        # A3 — the filter deleted, the header left claiming absent-is-pass. This is
        # the real-world regression shape (a cost edit that forgets the declaration).
        if not flags(victim, strip_filter):
            failures.append(f"A3: deleting {victim}'s paths filter while leaving "
                            f"skip-semantics=absent-is-pass was NOT flagged")

    if filter_free:
        victim = filter_free[0]
        # A2 — branch 4: skip-semantics injected into a FILTER-FREE header.
        if not flags(victim, lambda t: edit_header(
                t, "always-reports=yes",
                "always-reports=yes  skip-semantics=absent-is-pass")):
            failures.append(f"A2: injecting skip-semantics into filter-free {victim} "
                            f"was NOT flagged")
        # A7 — branch 3: no filter, and the header denies always-reports. The
        # filter-free counterpart of A6, and the arm whose absence let a whole branch
        # be deleted silently.
        if not flags(victim, lambda t: edit_header(
                t, "always-reports=yes", "always-reports=no")):
            failures.append(f"A7: always-reports=no on filter-free {victim} was NOT "
                            f"flagged")
        # A4 — branch 5: the header removed entirely.
        if not flags(victim, lambda t: "\n".join(
                l for l in t.splitlines() if not HEADER_RE.match(l.strip()))):
            failures.append(f"A4: stripping {victim}'s gate-efficacy header was NOT "
                            f"flagged")
        # A5 — SPECIFICITY, on the same non-empty input: a fabricated field touching
        # neither governed field must NOT be flagged. Without it a detector that
        # flagged everything would pass A1-A4/A6/A7 and be worthless.
        if flags(victim, lambda t: edit_header(
                t, "always-reports=yes",
                "always-reports=yes  zzz-fabricated-field=yes")):
            failures.append(f"A5: a fabricated non-governed header field on {victim} "
                            f"WAS flagged — the detector over-matches")

    # A8 — REACH. Every arm above mutates a file's FIRST declaration, so every one of
    # them passes against a grader that reads only the first one: the whole set of
    # them could not see the blind spot they were meant to cover. This arm mutates a
    # LATER declaration in a file that carries more than one, and it is the only arm
    # that goes red if the grader regresses to first-match-only. It was written after
    # exactly that mutation was found to survive the six arms above.
    multi = [n for n in sorted(sources) if len(parse_headers(sources[n])) > 1]
    if not multi:
        failures.append("NOSET: no workflow carries more than one gate-efficacy "
                        "declaration, so arm A8 cannot be built — reported rather "
                        "than skipped")
    else:
        built = False
        for victim in multi:
            # Inject the field the file's trigger FORBIDS, so the mutation lands on a
            # real finding branch rather than on a value the biconditional permits.
            if victim in filtered:
                old, add = "skip-semantics=absent-is-pass", "always-reports=yes"
            else:
                old, add = "always-reports=yes", "skip-semantics=absent-is-pass"
            victim_lines = sources[victim].splitlines()
            carrying = [ln for ln, _ in parse_headers(sources[victim])
                        if old in victim_lines[ln - 1]]
            if len(carrying) < 2:
                continue  # cannot reach a NON-FIRST declaration in this file
            built = True
            if not flags(victim, lambda t, o=old, n=f"{old}  {add}": edit_header(
                    t, o, n, occurrence=2)):
                failures.append(
                    f"A8: injecting {add} into the SECOND gate-efficacy declaration "
                    f"of {victim} (line {carrying[1]}) was NOT flagged — the grader "
                    f"is reading only one declaration per file")
            break
        if not built:
            failures.append("NOSET: no workflow carries the same governed field on two "
                            "of its declarations, so arm A8 cannot be built — reported "
                            "rather than skipped")

    return failures


def strip_filter(text: str) -> str:
    """Delete every `paths:`/`paths-ignore:` block from the `on:` mapping, textually.

    In-memory only, and used solely to build arm A3. Re-emitting the parsed YAML would
    reshape comments and could itself change the answer, so the mutation is textual and
    its effect is verified by re-running the STRUCTURAL reader over the result.
    """
    lines = text.splitlines()
    out: list[str] = []
    dropping_at: int | None = None
    for line in lines:
        stripped = line.strip()
        indent = len(line) - len(line.lstrip())
        if dropping_at is not None:
            if stripped and indent <= dropping_at:
                dropping_at = None
            else:
                continue
        if stripped.rstrip(":") in FILTER_KEYS and stripped.endswith(":"):
            dropping_at = indent
            continue
        out.append(line)
    return "\n".join(out) + "\n"


def main() -> int:
    root = repo_root()
    sources = load(root)

    if not sources:
        print("FAIL (NOSET): no workflow files discovered — a clean over an empty "
              "population is not a clean", file=sys.stderr)
        return 2

    findings, filtered, filter_free, n_declarations = evaluate(sources)
    job_findings, scoped, n_jobs = evaluate_jobs(sources)
    posture_findings, residual_hits, n_required = evaluate_posture(sources)

    # THE EXEMPTION AUDIT, on the real tree rather than on a mutated copy. A ledger entry
    # that no longer reproduces its finding has outlived its premise, and an exemption
    # whose premise expired is a silent permanent hole — strictly worse than the finding
    # it suppressed. Reported as a finding so retiring the entry is obligatory, not
    # optional. Computed here and not inside `evaluate_posture` because the harness runs
    # that function over MUTATED populations, where a missing hit is the arm working
    # rather than a stale ledger.
    for key in sorted(POSTURE_RESIDUALS, key=lambda k: (k[0], k[1], str(k[2]))):
        if key not in residual_hits:
            posture_findings.append(
                f"{key[0]}: residual-ledger entry {key[1]!r}/{key[2]!r} no longer "
                f"reproduces its finding — the exemption has outlived its premise and "
                f"MUST be deleted from POSTURE_RESIDUALS. Leaving it standing silently "
                f"exempts that declaration forever."
            )

    # BOTH counts, always. The file count and the declaration count are different
    # numbers in this tree, and reporting agreement over the file count while grading
    # declarations is precisely the declared-vs-actual reach overstatement this suite
    # exists to catch. State the population with the magnitude. The job count is
    # reported for the same reason and taken from the same place that graded it.
    print(f"population: {len(sources)} workflow file(s) — "
          f"{len(filtered)} path-filtered, {len(filter_free)} filter-free; "
          f"{n_declarations} gate-efficacy declaration(s) graded")
    print(f"per-job reach: {n_jobs} named job(s) graded across {len(scoped)} "
          f"check-run-naming workflow(s); "
          f"{len(sources) - len(scoped)} workflow(s) out of scope (posture declared by "
          f"containment — no check-run named)")
    print(f"posture reach: {n_required} declaration(s) carrying a `required` posture "
          f"graded against their enforcement surface; "
          f"{len(POSTURE_RESIDUALS)} on the residual ledger "
          f"({len(residual_hits)} still reproducing)")

    # THE FOURTH INVARIANT reads two inputs the other three do not: deploy.sh, whose
    # checks carry population declarations, and the TRACKED TREE, which every declared
    # root must resolve against. Either one unreadable is exit 2 — this arm cannot
    # assert without them, and an unread input is not an empty one.
    try:
        deploy_text = (root / DEPLOY_REL).read_text(encoding="utf-8")
    except OSError as exc:
        print(f"FAIL: cannot read {DEPLOY_REL} ({exc}) — the population arm grades the "
              f"declarations it carries, so it is reported rather than skipped",
              file=sys.stderr)
        return 2
    try:
        tracked = tracked_files(root)
    except TrackedTreeError as exc:
        print(f"FAIL: `git ls-files` failed ({exc}) — declared roots resolve against the "
              f"TRACKED TREE, and without it the population arm cannot assert "
              f"(fail-closed)", file=sys.stderr)
        return 2
    pop_findings, pop_hits, n_pop, n_pop_roots, n_pop_resolving = evaluate_population(
        sources, deploy_text, tracked)
    # The population exemption audit, on the real tree, for POSTURE_RESIDUALS' reason.
    pop_findings += population_ledger_audit(pop_hits)
    n_pop_files = (sum(1 for text in sources.values() if parse_population(text))
                   + (1 if parse_population(deploy_text) else 0))
    print(f"population reach: {n_pop} declaration(s) graded across {n_pop_files} "
          f"file(s); {n_pop_roots} declared root(s), {n_pop_resolving} resolving; "
          f"{len(POPULATION_RESIDUALS)} on the residual ledger "
          f"({len(pop_hits)} still reproducing)")
    for key in sorted(pop_hits):
        where = f"{key[0]} Check {key[1]}" if key[1] else key[0]
        print(f"WARN (ledgered residual): {where} declares root '{key[2]}', which resolves "
              f"to zero tracked files — reported, not skipped; delete the ledger entry in "
              f"the change that removes the root")

    # THE FIFTH INVARIANT reads the standard, the install-regression runner and the tracked
    # tools that name the drift engine. Any of them unreadable, or a population that
    # re-derives empty, is exit 2: a census graded over nothing is not a clean census.
    try:
        census_text = (root / STANDARD_REL).read_text(encoding="utf-8")
    except OSError as exc:
        print(f"FAIL (NOSET): cannot read {STANDARD_REL} ({exc}) — the census it carries "
              f"cannot be graded, so it is reported rather than skipped", file=sys.stderr)
        return 2
    try:
        census_pops = census_populations(root, tracked, sources)
        census_findings, unrecorded, reach, noset = evaluate_census(
            census_text, sources, root, tracked, populations=census_pops)
    except CensusError as exc:
        print(f"FAIL: a census input could not be read ({exc}) — the census cannot assert "
              f"(fail-closed)", file=sys.stderr)
        return 2
    if noset:
        print("FAIL (NOSET): a census population re-derived empty — a census graded over "
              "nothing is not a clean census", file=sys.stderr)
        return 2
    print(f"census reach: {reach['sites']} drift-engine decision site(s) in "
          f"{reach['site_files']} file(s) ({reach['candidates']} candidate file(s) name the "
          f"engine); {reach['binary_zero']} binary-zero workflow consumer(s) of "
          f"{reach['consumers']} exit-status consumer(s) in {reach['consumer_files']} of "
          f"{reach['workflows']} workflow file(s) ({reach['binary_exact']} binary-exact, "
          f"{reach['multi_state']} multi-state); {reach['suites']} suite(s), "
          f"{reach['zero_executor']} zero-executor ({reach['recorded']} recorded in the "
          f"census)")
    for suite in unrecorded:
        print(f"WARN (zero-executor suite, not gated): {suite} — no workflow step, runner "
              f"member declaration or executed loop glob runs it; wire it, or record it in "
              f"the census")

    harness_failures = harness(sources, filtered, filter_free)
    harness_failures += job_harness(sources)
    harness_failures += posture_harness(sources)
    harness_failures += population_harness(sources, deploy_text, tracked)
    try:
        census_failures, census_notes = census_harness(census_text, sources, root, tracked,
                                                       census_pops)
    except CensusError as exc:
        census_failures, census_notes = [f"NOSET: a census arm's input could not be read "
                                         f"({exc})"], []
    harness_failures += census_failures
    if harness_failures:
        print("FAIL (harness): the detector did not demonstrate it discriminates.",
              file=sys.stderr)
        for failure in harness_failures:
            print(f"  {failure}", file=sys.stderr)
        return 2
    print("anti-vacuity: sensitivity arms A1/A2/A3/A4/A6/A7 all flagged — one per "
          "finding branch, so no branch can be deleted silently; A8 flagged a mutation "
          "of a NON-FIRST declaration, so the grader's reach is the whole declaration "
          "set; specificity arm A5 stayed clean on the same non-empty input")
    print("anti-vacuity (per-job): B1 flagged an orphaned job after a declared context "
          "was renamed; B3 flagged a broken matrix leg, so `${{ matrix.* }}` is really "
          "expanded rather than exempted; specificity arm B2 stayed clean on a "
          "C1-class workflow whose posture is declared by containment")
    # C5 runs only while POSTURE_RESIDUALS is non-empty — `posture_harness` gates it on
    # exactly that condition, and a C5 that ran and failed has already exited 2 above.
    # The clause below reads the SAME condition, so the line never claims an arm that did
    # not run: an emptied ledger is the target state, and it must not read as a C5 pass.
    c5_clause = ("C5 showed a conformed residual stops matching its ledger entry, so a "
                 "stale exemption is detected" if POSTURE_RESIDUALS else
                 "C5 did not run — the posture residual ledger is empty, so there is no "
                 "exemption to audit")
    print("anti-vacuity (posture): C1 flagged a `required` declaration repointed at a "
          "non-blocking surface and C2 flagged an advisory one promoted to `required`, "
          "so BOTH graded fields are really read; specificity arms C3 (a QUALIFIED "
          "`required` still naming branch-protection) and C4 (an advisory declaration's "
          f"surface) stayed clean on the same non-empty input; {c5_clause}")
    print("anti-vacuity (population): P1 flagged a missing root appended to the worked "
          "reference's live array and P2 kept that declaration clean unmutated; P7 drew "
          "exactly one finding from a synthetic declaration over an empty glob while its "
          "non-empty control stayed clean; P3/P3b/P3c flagged `file` and `file/class` "
          "without a justification and a unit outside the closed set, and specificity arm "
          "P4 (a narrower unit) stayed clean; P6 ran on a SYNTHETIC ledger — a ledgered "
          "zero-yield root was recorded, not reported, the same root was reported once the "
          "ledger was emptied, and dropping it made the audit report exactly its stale "
          "entry; P8 flagged a declared population no `_population_report` call reports and "
          "P8b a resolve call whose filter is not the declared one; P9 flagged the worked "
          "reference's declaration removed; P5 held the declaration set non-empty")
    census_note = "" if not census_notes else " (" + "; ".join(census_notes) + ")"
    print("anti-vacuity (census): CS-1 flagged exactly one planted binary-zero consumer and "
          "CS-2 no planted multi-state consumer or counter; CS-2b counted a single-value "
          "`case` and not a `case` over 0 and 2|3; CS-3 and CS-3w counted a planted "
          "drift-engine run in a tool file and in a workflow step, and CS-4 not a file that "
          "only names the engine; CS-5a flagged a deleted row and CS-5b a fabricated one in "
          "each set-graded record, and CS-6 a shifted `examined:`; CS-7 reported a planted "
          "zero-executor suite and CS-7b a deleted executor row, each as a report and never a "
          "finding; CS-8 kept a planted fixtures/ file out of the suites and wired a suite the "
          "install runner enrolls; CS-8b wired nothing from a step that only names the "
          "runners, constructed and drawn from the live tree; CS-9 flagged a zero-executor "
          "row naming a wired suite; CS-10 read an empty population as NOSET; CS-11 flagged "
          f"a token outside the closed set{census_note}")

    findings = findings + job_findings + posture_findings + pop_findings + census_findings
    if findings:
        print(f"FAIL: {len(findings)} declared-vs-actual mismatch(es).", file=sys.stderr)
        for finding in findings:
            print(f"  {finding}", file=sys.stderr)
        print("Fix the HEADER and the TRIGGER together, in the same commit — that "
              "same-commit obligation is the invariant, per "
              "core/standards/gate-efficacy-standard.md Requirement (b). For a per-job "
              "finding, add a `gate-efficacy:` block naming that job's check-run and "
              "stating its ACTUAL posture — an advisory gate declaring `advisory` is "
              "conforming; an undeclared one is not. For a population finding, declare "
              "the roots the check actually scans (or remove the dead root), and keep the "
              "`_population_resolve` / `_population_report` calls beside the declaration. "
              "For a census finding, add or delete the census row in the same change that "
              "adds or removes the consumer, and keep each record's `examined:` equal to its "
              "rows.",
              file=sys.stderr)
        return 1

    print(f"OK — {n_declarations}/{n_declarations} gate-efficacy declaration(s) across "
          f"{len(sources)} workflow file(s) agree with their triggers, "
          f"{n_jobs}/{n_jobs} named job(s) in check-run-naming workflows carry a "
          f"declaration of their own, "
          f"{n_required - len(residual_hits)}/{n_required} `required` declaration(s) "
          f"name a blocking enforcement surface "
          f"({len(residual_hits)} ledgered residual(s) pending an operator posture "
          f"decision), {n_pop}/{n_pop} population declaration(s) resolve root by "
          f"root and are reported ({len(pop_hits)} ledgered residual root(s) pending the "
          f"change that removes them), and the census's 3 population record(s) match their "
          f"re-derived populations ({len(unrecorded)} unrecorded zero-executor suite(s) "
          f"reported, not gated).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
