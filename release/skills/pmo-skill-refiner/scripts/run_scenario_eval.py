#!/usr/bin/env python3
"""Deterministic output-scoring runner for scenario eval suites.

WHAT THIS IS
------------
The executor for a contract the platform already declared and left inert. The
eval-harness schema (`evals.json`) and the report contract (`grading.json`) are
documented in `references/schemas.md`; `core/skills/eval-writer/SKILL.md` records
that the assertion-grading path was a grader-honored contract rather than a
runner-executed one. This module executes the DETERMINISTIC half of that path.

It is NOT `run_eval.py`. That script is a *trigger* harness: it asks whether a
skill's description causes Claude to fire for a query. This script asks whether a
scenario's graded statements hold against a committed fixture. Neither reads the
other; neither is modified by the other's existence.

WHAT IT CONSUMES
----------------
The shipped eval-harness schema, extended by exactly ONE optional field:
`assertions[].check`, a declarative predicate object. An assertion carrying no
`check` is UNGRADED and leaves both numerator and denominator, so every suite
already in the corpus remains valid input, unmodified.

`check.kind` is a CLOSED five-value set, derived by construction from the four
deterministic values already in the `assertions[].type` enum:

    path_exists   {kind, target?}                          <- structural
    contains      {kind, target?, value}                   <- structural
    matches       {kind, target?, pattern, engine}         <- structural
    resolves_to   {kind, target?, path, value?}            <- resolution
    unchanged     {kind, target?}                          <- read-only

Closed rather than open because an open predicate set re-admits per-suite Python,
which is exactly the property that stops the one existing deterministic runner
(`core/disciplines/evals/people-graph-consumption/run_consumption_eval.py`) from
running a second suite.

WHAT IT EMITS
-------------
`grading.json` per `references/schemas.md` § grading.json. This module adds no
second definition of that contract; it cites it. The emitted subset is:

    expectations[]  {text, passed, evidence}
    summary         {passed, failed, ungraded, total, pass_rate}
    suite           {suite_name, fixture, sha, run_at}

`execution_metrics`, `timing`, `claims`, `user_notes_summary` and `eval_feedback`
are grader-agent-specific and are deliberately NOT emitted. The aggregator reads
each through a defaulted `.get(...)`, so absence is tolerated.

THE READ/WRITE FIELD-NAME ASYMMETRY IS INHERITED AND PRESERVED
--------------------------------------------------------------
Input graded statements live under `assertions[]` (what every typed suite in the
corpus actually contains). Output graded statements live under `expectations[]`
(what `scripts/aggregate_benchmark.py` and `eval-viewer/generate_review.py` pin in
code). Renaming either side breaks a shipped consumer. This module implements the
mapping `assertions[].text -> expectations[].text`; it does not "fix" the
asymmetry.

THE ZERO-DENOMINATOR RULE
-------------------------
When nothing was gradable, this runner writes NO report and exits 3. It does not
emit `"pass_rate": null` (which raises TypeError in the aggregator's statistics
pass) and it does not omit the key (which the aggregator's defaulted `.get()`
silently reads as 0.0 — absence read as total failure). Writing no file is the one
faithful encoding the frozen contract admits: the aggregator's missing-file branch
warns and skips the run, so a non-measuring run contributes nothing to the mean
rather than entering it as a zero.

EXIT CODES (closed four-value set)
----------------------------------
    0  every gradable assertion passed, and (if --fail-under was given) the pass
       rate is at or above it
    1  at least one gradable assertion failed, OR the pass rate is below
       --fail-under, OR the suite-level non-triviality control did not hold
    2  usage or environment error (unreadable suite, malformed suite, missing
       optional dependency for the fixture format in use)
    3  nothing was gradable -- no report written

Usage:
    python3 -m scripts.run_scenario_eval --suite evals/scenario-runner/evals.json
    python3 -m scripts.run_scenario_eval --suite <path> --fixture <path> --fail-under 1.0

Full contract, for a scenario author who has not read this source:
`references/scenario-eval-contract.md`.
"""

from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import os
import re
import sys
from pathlib import Path

# --------------------------------------------------------------------------- #
# Exit codes -- the closed set, named once so no call site spells a literal.
# --------------------------------------------------------------------------- #
EXIT_PASS = 0
EXIT_FAIL = 1
EXIT_USAGE = 2
EXIT_NOTHING_GRADABLE = 3

CHECK_KINDS = ("path_exists", "contains", "matches", "resolves_to", "unchanged")

#: The one regular-expression dialect this runner implements. A `matches` check
#: must name it in-band: an unnamed dialect is an ungradeable claim, because the
#: same pattern means different things to different engines.
SUPPORTED_ENGINE = "python-re"

#: Spelled-out alias for "the fixture this run is scoring". A check may write it
#: explicitly; omitting `target` entirely means the same thing.
ACTIVE_FIXTURE = "@fixture"


class SuiteError(Exception):
    """A suite is unreadable or malformed -- a usage error, never a low score."""


# --------------------------------------------------------------------------- #
# Fixture loading -- format-agnostic by extension.
#
# `resolves_to` does not care what serialization a fixture uses, so the runner
# does not force one. YAML support imports PyYAML lazily and guards it with the
# same exit code the platform's other deterministic runner uses, so a missing
# optional dependency reports as an environment error rather than as a failing
# assertion.
# --------------------------------------------------------------------------- #
def load_structured(path: Path):
    """Parse a JSON or YAML document into Python data."""
    text = path.read_text(encoding="utf-8")
    suffix = path.suffix.lower()
    if suffix in (".yaml", ".yml"):
        try:
            import yaml  # noqa: PLC0415 -- lazy by design; see the guard below
        except ImportError:
            raise SuiteError(
                "PyYAML is required to read a YAML fixture. "
                "Install with: pip install pyyaml -- or use a .json fixture, "
                "which this runner reads with no extra dependency."
            )
        return yaml.safe_load(text)
    if suffix == ".json":
        return json.loads(text)
    raise SuiteError(
        f"unsupported fixture format {suffix!r} for {path} "
        f"(supported: .json, .yaml, .yml)"
    )


def sha256_of(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


# --------------------------------------------------------------------------- #
# Value resolution and comparison.
#
# The comparison rule is stated here and in the contract document, because a
# scenario author writes `expected_value` as text and needs to know exactly what
# their text is compared against.
# --------------------------------------------------------------------------- #
def resolve_path(data, dotted: str):
    """Walk a dotted path over nested mappings and sequences.

    Returns (found, value). A path segment that is an integer indexes a sequence;
    every other segment is a mapping key. A miss at any depth returns
    (False, None) -- never a partial or a guess.
    """
    current = data
    for segment in dotted.split("."):
        if isinstance(current, dict):
            if segment not in current:
                return False, None
            current = current[segment]
        elif isinstance(current, (list, tuple)):
            try:
                index = int(segment)
            except ValueError:
                return False, None
            if index < 0 or index >= len(current):
                return False, None
            current = current[index]
        else:
            return False, None
    return True, current


def comparable_text(value):
    """Render a resolved value as the text `expected_value` is compared against.

    Scalars render with `str()`. Booleans render lowercased, so a fixture's YAML
    `true` compares equal to an author's `"true"`. Sequences render as their
    members joined with ", ". Mappings are NOT comparable -- a `resolves_to` whose
    path lands on a mapping fails with that stated as its evidence, rather than
    matching some incidental repr.
    """
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return ""
    if isinstance(value, (list, tuple)):
        return ", ".join(comparable_text(v) for v in value)
    if isinstance(value, dict):
        return None
    return str(value)


# --------------------------------------------------------------------------- #
# The predicate evaluator -- one function per member of the closed set.
#
# Every branch returns (passed, evidence). `evidence` is prose describing what the
# check OBSERVED, never a restatement of what it wanted: a report whose evidence
# echoes the assertion cannot distinguish a real pass from a matcher that never
# ran.
# --------------------------------------------------------------------------- #
def evaluate_check(check: dict, assertion: dict, ctx: "RunContext"):
    kind = check.get("kind")
    if kind not in CHECK_KINDS:
        raise SuiteError(
            f"unknown check.kind {kind!r} -- the vocabulary is closed: "
            f"{', '.join(CHECK_KINDS)}"
        )

    target_spec = check.get("target", ACTIVE_FIXTURE)
    target = ctx.resolve_target(target_spec)
    shown = ctx.display(target)

    if kind == "path_exists":
        if target.exists():
            return True, f"{shown} exists"
        return False, f"{shown} does not exist"

    # Every remaining kind reads the target, so a missing target is a uniform
    # failure with a uniform evidence line rather than an exception per branch.
    if not target.exists():
        return False, f"{shown} does not exist, so the check had nothing to read"

    if kind == "unchanged":
        before = ctx.baseline_sha(target)
        after = sha256_of(target)
        if before == after:
            return True, f"{shown} is byte-identical before and after the run (sha {after[:12]})"
        return False, (
            f"{shown} changed during the run "
            f"(sha {before[:12]} -> {after[:12]}) -- the read was not read-only"
        )

    if kind == "contains":
        if "value" not in check:
            raise SuiteError("a `contains` check requires a `value`")
        needle = str(check["value"])
        haystack = target.read_text(encoding="utf-8")
        if needle in haystack:
            return True, f"the literal substring {needle!r} is present in {shown}"
        return False, f"the literal substring {needle!r} is absent from {shown}"

    if kind == "matches":
        if "pattern" not in check:
            raise SuiteError("a `matches` check requires a `pattern`")
        engine = check.get("engine")
        if engine != SUPPORTED_ENGINE:
            raise SuiteError(
                f"a `matches` check must name its engine in-band as "
                f"{SUPPORTED_ENGINE!r}; got {engine!r}. An unnamed dialect is an "
                f"ungradeable claim."
            )
        pattern = check["pattern"]
        try:
            compiled = re.compile(pattern, re.MULTILINE)
        except re.error as exc:
            raise SuiteError(f"invalid {SUPPORTED_ENGINE} pattern {pattern!r}: {exc}")
        found = compiled.search(target.read_text(encoding="utf-8"))
        if found:
            return True, (
                f"pattern {pattern!r} matched {found.group(0)!r} in {shown} "
                f"({SUPPORTED_ENGINE})"
            )
        return False, f"pattern {pattern!r} found no match in {shown} ({SUPPORTED_ENGINE})"

    # kind == "resolves_to"
    if "path" not in check:
        raise SuiteError("a `resolves_to` check requires a `path`")
    expected = check.get("value", assertion.get("expected_value"))
    if expected is None:
        raise SuiteError(
            "a `resolves_to` check needs an expected value -- either `check.value` "
            "or the assertion's `expected_value`"
        )
    dotted = check["path"]
    data = ctx.structured(target)
    found, value = resolve_path(data, dotted)
    if not found:
        return False, f"{dotted} does not resolve in {shown}"
    rendered = comparable_text(value)
    if rendered is None:
        return False, (
            f"{dotted} resolves to a mapping in {shown}, which is not comparable "
            f"to a text expected value"
        )
    if rendered == str(expected):
        return True, f"{dotted} resolves to {rendered!r} in {shown}"
    return False, f"{dotted} resolves to {rendered!r} in {shown}, expected {str(expected)!r}"


# --------------------------------------------------------------------------- #
# Run context -- path anchoring, read caching, and read-only baselines.
# --------------------------------------------------------------------------- #
class RunContext:
    """Anchors every path in a run and holds the pre-run hashes.

    Anchoring is stated once here rather than at each call site: a check's
    `target` is resolved RELATIVE TO THE SUITE FILE'S DIRECTORY, and a target of
    `@fixture` (or an omitted target) resolves to the fixture this run is scoring.
    That default is what lets one suite be run against a baseline fixture, a
    regressed fixture, and an empty control fixture without editing the suite.
    """

    def __init__(self, suite_path: Path, fixture_path: Path):
        self.suite_dir = suite_path.parent.resolve()
        self.fixture = fixture_path
        self._structured: dict = {}
        self._baselines: dict = {}

    def resolve_target(self, spec) -> Path:
        if spec in (None, ACTIVE_FIXTURE):
            return self.fixture
        candidate = Path(str(spec))
        if candidate.is_absolute():
            return candidate
        return (self.suite_dir / candidate).resolve()

    def display(self, path: Path) -> str:
        """A suite-relative rendering, so evidence lines carry no machine path.

        `os.path.relpath` rather than `Path.relative_to`, because a target above
        the suite directory is legitimate (a sibling reference document, say) and
        `relative_to` raises on it. Falling back to the bare basename there would
        make two same-named targets in different directories indistinguishable in
        the evidence, which is the one thing an evidence line must not do.
        """
        try:
            return os.path.relpath(path, self.suite_dir)
        except ValueError:  # different drive on Windows -- no relative form exists
            return str(path)

    def structured(self, path: Path):
        key = str(path)
        if key not in self._structured:
            self._structured[key] = load_structured(path)
        return self._structured[key]

    def snapshot(self, path: Path) -> None:
        key = str(path)
        if key not in self._baselines and path.exists():
            self._baselines[key] = sha256_of(path)

    def baseline_sha(self, path: Path) -> str:
        return self._baselines.get(str(path), sha256_of(path))


# --------------------------------------------------------------------------- #
# Suite reading + validation.
# --------------------------------------------------------------------------- #
def read_suite(suite_path: Path) -> dict:
    if not suite_path.exists():
        raise SuiteError(f"suite not found: {suite_path}")
    try:
        suite = json.loads(suite_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SuiteError(f"suite is not valid JSON ({suite_path}): {exc}")
    if not isinstance(suite, dict):
        raise SuiteError(f"suite must be a JSON object ({suite_path})")
    if not isinstance(suite.get("evals"), list):
        raise SuiteError(f"suite carries no `evals` array ({suite_path})")
    return suite


def iter_assertions(suite: dict):
    """Yield every assertion in the suite, in declaration order."""
    for entry in suite["evals"]:
        if not isinstance(entry, dict):
            raise SuiteError("each member of `evals` must be an object")
        for assertion in entry.get("assertions", []) or []:
            if not isinstance(assertion, dict):
                raise SuiteError("each member of `assertions` must be an object")
            yield entry, assertion


# --------------------------------------------------------------------------- #
# The non-triviality control -- the AC-3 control arm, made declarative.
#
# A suite that declares `control.empty_fixture` has every `resolves_to` check
# re-run against that structurally-empty fixture. ALL of them must fail. A
# resolution that succeeds against an empty fixture is not measuring the fixture,
# which makes every one of that suite's passes unfalsifiable.
#
# This is the same layer `run_consumption_eval.py` implements as four hard-coded
# per-skill functions. Expressed declaratively it generalizes to any suite.
# --------------------------------------------------------------------------- #
def run_non_triviality_control(suite: dict, suite_path: Path, empty_fixture: Path):
    ctx = RunContext(suite_path, empty_fixture)
    spurious = []
    examined = 0
    for _entry, assertion in iter_assertions(suite):
        check = assertion.get("check")
        if not isinstance(check, dict) or check.get("kind") != "resolves_to":
            continue
        examined += 1
        try:
            passed, _evidence = evaluate_check(check, assertion, ctx)
        except SuiteError:
            # A malformed check cannot resolve against anything, which is the
            # outcome this arm requires. The graded pass will surface the defect.
            passed = False
        if passed:
            spurious.append(assertion.get("text", "<untitled assertion>"))
    return examined, spurious


# --------------------------------------------------------------------------- #
# Scoring.
# --------------------------------------------------------------------------- #
def score(suite: dict, suite_path: Path, fixture: Path):
    ctx = RunContext(suite_path, fixture)

    # Snapshot every target BEFORE any check runs, so an `unchanged` check
    # compares against pre-run state rather than against itself.
    for _entry, assertion in iter_assertions(suite):
        check = assertion.get("check")
        if isinstance(check, dict):
            ctx.snapshot(ctx.resolve_target(check.get("target", ACTIVE_FIXTURE)))

    expectations = []
    ungraded_texts = []
    passed = failed = 0

    for _entry, assertion in iter_assertions(suite):
        text = assertion.get("text", "<untitled assertion>")
        check = assertion.get("check")
        if not isinstance(check, dict):
            # No predicate -> UNGRADED. It leaves BOTH numerator and denominator
            # (the all-drift-out convention locked in
            # core/skills/eval-writer/references/acceptance-assertion-type.md),
            # which is precisely what keeps every existing suite valid input.
            ungraded_texts.append(text)
            continue
        ok, evidence = evaluate_check(check, assertion, ctx)
        expectations.append({"text": text, "passed": ok, "evidence": evidence})
        if ok:
            passed += 1
        else:
            failed += 1

    total = passed + failed + len(ungraded_texts)
    gradable = passed + failed
    return expectations, ungraded_texts, passed, failed, total, gradable


def build_report(suite, fixture, expectations, passed, failed, ungraded, total, pass_rate):
    return {
        "expectations": expectations,
        "summary": {
            "passed": passed,
            "failed": failed,
            "ungraded": ungraded,
            "total": total,
            # Rendered at four decimal places. The gate consumes this runner's
            # EXIT STATUS, never this field, so the rendering is a reader's
            # convenience and is never a gate input; the --fail-under comparison
            # is made on the exact quotient below.
            "pass_rate": round(pass_rate, 4),
        },
        "suite": {
            "suite_name": suite.get("suite_name", "<unnamed suite>"),
            "fixture": fixture.name,
            # The fixture's content hash, short-form. This is what makes a run
            # reproducible against a fixture rather than against a path.
            "sha": sha256_of(fixture)[:12],
            "run_at": datetime.datetime.now(datetime.timezone.utc)
            .replace(microsecond=0)
            .isoformat()
            .replace("+00:00", "Z"),
        },
    }


# --------------------------------------------------------------------------- #
# CLI.
# --------------------------------------------------------------------------- #
def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="python3 -m scripts.run_scenario_eval",
        description=(
            "Score a scenario eval suite against a fixture and emit grading.json. "
            "Distinct from scripts/run_eval.py, which grades triggers."
        ),
    )
    parser.add_argument("--suite", required=True, help="path to the suite's evals.json")
    parser.add_argument(
        "--out",
        default=None,
        help="where to write grading.json (default: alongside the suite file)",
    )
    parser.add_argument(
        "--fixture",
        default=None,
        help="override the suite's declared fixture (relative to the suite file)",
    )
    parser.add_argument(
        "--fail-under",
        type=float,
        default=None,
        metavar="FLOAT",
        help="exit 1 when the pass rate falls below this floor",
    )
    parser.add_argument("--verbose", action="store_true")
    return parser


def main(argv=None) -> int:
    args = build_parser().parse_args(argv)

    try:
        suite_path = Path(args.suite).resolve()
        suite = read_suite(suite_path)
        suite_dir = suite_path.parent

        fixture_spec = args.fixture if args.fixture else suite.get("fixture")
        if not fixture_spec:
            raise SuiteError(
                "no fixture: the suite declares no `fixture` and none was passed "
                "with --fixture"
            )
        fixture = Path(fixture_spec)
        if not fixture.is_absolute():
            fixture = (suite_dir / fixture).resolve()
        if not fixture.exists():
            raise SuiteError(f"fixture not found: {fixture}")

        expectations, ungraded_texts, passed, failed, total, gradable = score(
            suite, suite_path, fixture
        )
    except SuiteError as exc:
        sys.stderr.write(f"ERROR: {exc}\n")
        return EXIT_USAGE

    suite_name = suite.get("suite_name", "<unnamed suite>")
    print(f"suite      : {suite_name}")
    print(f"fixture    : {fixture.name} (sha {sha256_of(fixture)[:12]})")
    print(f"assertions : {total} declared -- {gradable} gradable, {len(ungraded_texts)} ungraded")

    if args.verbose:
        for row in expectations:
            print(f"  {'PASS' if row['passed'] else 'FAIL'}  {row['text']}")
            print(f"        {row['evidence']}")
        for text in ungraded_texts:
            print(f"  UNGRADED  {text}")
            print("        no `check` predicate -- out of both numerator and denominator")

    # ---- The zero-denominator rule (see the module docstring) --------------- #
    if gradable == 0:
        sys.stderr.write(
            "NOTHING GRADABLE: every assertion in this suite is ungraded, so no "
            "pass rate exists to report. Writing no report -- a measurement that "
            "did not happen must not be representable as a measurement that "
            "scored zero. Give at least one assertion a `check` predicate.\n"
        )
        return EXIT_NOTHING_GRADABLE

    # The all-drift-out denominator, reused rather than invented: ungraded
    # assertions leave both numerator and denominator.
    pass_rate = passed / gradable
    print(f"pass rate  : {pass_rate:.4f}  ({passed} passed / {gradable} gradable)")

    # ---- The suite-level non-triviality control ----------------------------- #
    control_ok = True
    control_spec = (suite.get("control") or {}).get("empty_fixture")
    if control_spec:
        empty = Path(control_spec)
        if not empty.is_absolute():
            empty = (suite_dir / empty).resolve()
        if not empty.exists():
            sys.stderr.write(f"ERROR: control fixture not found: {empty}\n")
            return EXIT_USAGE
        if empty.resolve() == fixture.resolve():
            print("control    : SKIPPED -- this run IS the empty control fixture")
        else:
            examined, spurious = run_non_triviality_control(suite, suite_path, empty)
            if spurious:
                control_ok = False
                sys.stderr.write(
                    f"NON-TRIVIALITY CONTROL FAILED: {len(spurious)} of {examined} "
                    f"resolution checks still pass against the empty control "
                    f"fixture, so this suite's passes are not load-bearing:\n"
                )
                for text in spurious:
                    sys.stderr.write(f"  spurious: {text}\n")
            else:
                print(
                    f"control    : PASS -- all {examined} resolution checks fail "
                    f"against the empty fixture"
                )
    else:
        print("control    : none declared (no `control.empty_fixture` in the suite)")

    # ---- Emit the report ---------------------------------------------------- #
    out_path = Path(args.out) if args.out else (suite_dir / "grading.json")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    report = build_report(
        suite, fixture, expectations, passed, failed, len(ungraded_texts), total, pass_rate
    )
    out_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"report     : {out_path}")

    # ---- Verdict ------------------------------------------------------------ #
    if not control_ok:
        return EXIT_FAIL
    if failed:
        print(f"VERDICT    : FAIL ({failed} gradable assertion(s) failed)")
        return EXIT_FAIL
    if args.fail_under is not None and pass_rate < args.fail_under:
        print(f"VERDICT    : FAIL (pass rate {pass_rate:.4f} < floor {args.fail_under})")
        return EXIT_FAIL
    print("VERDICT    : PASS")
    return EXIT_PASS


if __name__ == "__main__":
    sys.exit(main())
