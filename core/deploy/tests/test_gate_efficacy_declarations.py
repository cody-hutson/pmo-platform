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

EXIT CONTRACT
-------------
    0  every workflow conforms AND the anti-vacuity harness passed
    1  at least one declared-vs-actual mismatch (a workflow with no header, a job
       publishing a check-run its workflow's headers do not name, a `required` posture
       naming a surface that cannot block, or a stale residual-ledger entry)
    2  the harness itself could not assert — an unreadable population, a partition too
       small to build a mutation arm, or a mutation the detector failed to flag.
       Fail-closed: a probe that cannot demonstrate it discriminates reports 2 rather
       than the clean it can no longer distinguish from a real one.

THE HARNESS RUNS BY DEFAULT, ON EVERY INVOCATION — deliberately, and it is the whole
reason to trust the zero. A falsification harness behind a flag nothing passes runs
exactly once, at implementation, and thereafter certifies nothing. Every mutation arm
below is derived from the LIVE population at run time rather than from hardcoded
workflow names, so a rename cannot quietly empty it, and an empty partition is a
reported NOSET rather than a skipped arm.

Hermetic: reads the workflow files, mutates only in-memory copies, writes nothing.
"""

from __future__ import annotations

import re
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
    one header that must agree. Three oracles, three functions; widening either existing
    return would change a contract for a reason unrelated to it.

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

    harness_failures = harness(sources, filtered, filter_free)
    harness_failures += job_harness(sources)
    harness_failures += posture_harness(sources)
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
    print("anti-vacuity (posture): C1 flagged a `required` declaration repointed at a "
          "non-blocking surface and C2 flagged an advisory one promoted to `required`, "
          "so BOTH graded fields are really read; specificity arms C3 (a QUALIFIED "
          "`required` still naming branch-protection) and C4 (an advisory declaration's "
          "surface) stayed clean on the same non-empty input; C5 showed a conformed "
          "residual stops matching its ledger entry, so a stale exemption is detected")

    findings = findings + job_findings + posture_findings
    if findings:
        print(f"FAIL: {len(findings)} declared-vs-actual mismatch(es).", file=sys.stderr)
        for finding in findings:
            print(f"  {finding}", file=sys.stderr)
        print("Fix the HEADER and the TRIGGER together, in the same commit — that "
              "same-commit obligation is the invariant, per "
              "core/standards/gate-efficacy-standard.md Requirement (b). For a per-job "
              "finding, add a `gate-efficacy:` block naming that job's check-run and "
              "stating its ACTUAL posture — an advisory gate declaring `advisory` is "
              "conforming; an undeclared one is not.",
              file=sys.stderr)
        return 1

    print(f"OK — {n_declarations}/{n_declarations} gate-efficacy declaration(s) across "
          f"{len(sources)} workflow file(s) agree with their triggers, "
          f"{n_jobs}/{n_jobs} named job(s) in check-run-naming workflows carry a "
          f"declaration of their own, and "
          f"{n_required - len(residual_hits)}/{n_required} `required` declaration(s) "
          f"name a blocking enforcement surface "
          f"({len(residual_hits)} ledgered residual(s) pending an operator posture "
          f"decision).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
