#!/usr/bin/env python3
"""Assert every step of install-tests.yml that invokes a core/deploy/tests shell suite carries a timeout.

WHAT THIS GUARDS, AND WHY IT EXISTS
-----------------------------------
A suite step with no `timeout-minutes` runs until the host's own job limit when it
hangs. The guard that used to watch for this named the steps it checked, so a suite
added to the workflow was unguarded by default and the guard stayed green while
coverage fell. This suite asserts the property as an INVARIANT over the workflow's own
step list. It names no suite and no step: the population is derived on every run.

WHY A COMMITTED SUITE AND A THIN CALLER
---------------------------------------
The assertion lives here rather than inline in the workflow because a gate's logic is
a committed, locally invocable engine and the workflow is a thin caller over it
(ADR-119, Decision 3). An inline program is reachable only through a CI trigger, so
the only way to exercise it locally is to re-implement it, and a re-implementation
passes while the real gate diverges. It sits in the tests tree as a bare-invocation
entry point, not as a tool with a `--self-test` dispatcher, which is the scope
boundary ADR-119 draws in its Decision 6; no self-test manifest line is owed for it.

THE PREDICATE
-------------
A step is SUITE-INVOKING when a line of its `run:` script names
`core/deploy/tests/<name>.sh`, unless that line is a `#` comment line or a bare
`echo` / `printf` command. A bare echo or printf is one whose line runs nothing else:
no command separator outside quotes and no command substitution.

Reading, copying, hashing or looping over a suite counts as invoking it. That is
deliberate. Whether a program reads its operand or runs it is a property of the
program, not of shell grammar, so the predicate does not try to tell the two apart:
it errs toward requiring a bound. Two live steps sit on that edge and both are
counted: the falsification probe, which runs four suites through a loop variable, and
the install-regression precision probe, which rewrites a copy of the runner into a
temporary tree and runs it from there.

WHAT COUNTS AS A BOUND
----------------------
A positive integer `timeout-minutes` strictly BELOW its ceiling. The ceiling is the
job's own `timeout-minutes` when the job carries a positive integer one (never more
than the host's 360-minute job limit), and otherwise that host limit. A step's clock
starts after its job's, so a bound at or above the ceiling can never be the one that
fires: the job ends first, as a cancellation that names no step, while the step would
be counted as covered by a bound that cannot act.

THE JOB-LEVEL BOUND
-------------------
Every job also carries a positive integer job-level `timeout-minutes` below the host's
360-minute limit. It is an OUTER bound — for the steps that run no suite, which the
step invariant does not reach, and as a backstop under the step budgets — never the
bound that names a suite: a job that reaches its limit is cancelled, and the
cancellation names no step. A job's limit is also the ceiling for each of its steps'
own bounds (above). The suite checks that the limit exists and sits below the host's;
how it was sized is stated beside it in the workflow.

THE POPULATION FLOOR
--------------------
The derived population is held to a committed floor: the `live-population-floor`
integer in the labeled fixture file. The floor is sourced independently of the
derivation, so the two can disagree, and that is the point (ADR-119, Decision 2: an
anti-narrowing guarantee is a committed floor, not reviewer vigilance). Without it, a
refactor that moves invocations out of the predicate's sight shrinks the covered count
and the total together, and the success line still reads N of N while coverage falls.
A population below the floor is a finding.

It is a floor, not a pin. A new suite step that carries a bound is already correct and
passes with no edit to the floor; a new one without a bound is already a finding. A
pin would also fail the correct addition, and two changes that each add a step would
each move the one integer to the same value, merge without a conflict and leave the
default branch red. Every run prints the population against the floor, so slack is
visible: raise the floor when the population has grown, or a later shrink of that size
goes unseen.

WHAT IT DOES NOT SEE (stated, so the next vector is a documented exclusion)
---------------------------------------------------------------------------
- A suite reached with no `core/deploy/tests/<name>.sh` path on any line of the step:
  a `cd` into the directory or a `working-directory:` key, followed by a bare name; a
  path assembled from variables; a wrapper script that runs suites itself. A step
  rewritten into one of these forms leaves the population. The floor reports that only
  once the population falls below it, and only as a count: it cannot name the step.
- A swap that moves one invocation out of sight and adds another in the same change:
  the count does not move, so neither does the floor's verdict.
- A step with no `run:` key, and anything outside `core/deploy/tests/` or not ending
  in `.sh` (the Python suites, the tool test suites, the hook harness).
- Whether a budget is the right SIZE. It checks that a bound exists and can fire
  before its job's limit, not that it fits the step.

THE ARMS RUN BY DEFAULT, ON EVERY INVOCATION
--------------------------------------------
A check that reports only a finding count cannot be told apart from one that examined
nothing, so every run also proves the predicate still discriminates:

  - a committed fixture of labeled steps (`must-flag:` / `must-not-flag:` /
    `not-seen:`) is read through the same structural parse as the live workflow, and
    each step's verdict must equal its label;
  - the timeout is stripped from EACH bounded live suite step in turn, in memory, and
    exactly that finding must appear;
  - a bound that is not a positive integer below its ceiling must be rejected, the
    ceiling itself among the values tried;
  - the live population is driven, in memory, to one below the floor by rewriting
    steps into a loop that names no suite path, and the floor must report it; driven
    to exactly the floor, it must not;
  - the job-level limit is stripped from EACH bounded job in turn, and exactly that
    job must be reported; a job limit set to the host's own limit must be rejected.

EXIT CONTRACT
-------------
    0  every suite-invoking step carries a bound below its ceiling, the population is
       at or above the floor, every job carries a job-level bound, AND every arm
       behaved
    1  at least one suite-invoking step carries no bound below its ceiling, the
       population fell below the committed floor, or a job carries no job-level bound
       below the host's limit
    2  the suite could not assert. Either nothing was measured (the workflow or the
       fixture is unreadable, the fixture carries no positive integer floor, or the
       population is empty), or an arm did not behave and the probe is unusable.
       Fail-closed: a probe that cannot show it discriminates reports 2, never the
       clean it can no longer distinguish from a real one, and it withholds its
       per-step findings.

Usage: test_install_tests_step_timeouts.py [--workflow PATH] [--fixture PATH]
Hermetic: reads two files, mutates only in-memory copies, writes nothing. No network.
"""

from __future__ import annotations

import copy
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover - environment guard
    print("Timeout guard NOT-EVALUATED — PyYAML is not importable under this interpreter, and the "
          "step read must be structural; this is not a clean result.")
    sys.exit(2)

SUITE_RE = re.compile(r"core/deploy/tests/[^\s/\"']+\.sh")
OUTPUT_COMMAND_RE = re.compile(r"(?:echo|printf)(?:\s|$)")
LABELS = ("must-flag", "must-not-flag", "not-seen")
HOST_JOB_LIMIT = 360  # minutes: the host's default, and largest, job time limit
FLOOR_KEY = "live-population-floor"
PATH_FREE_RUN = 'for suite in ${SUITES}; do bash "${suite}"; done\n'


def not_evaluated(cause: str):
    print("Timeout guard NOT-EVALUATED — %s; this is not a clean result." % cause)
    sys.exit(2)


def repo_root() -> Path:
    for candidate in Path(__file__).resolve().parents:
        if (candidate / ".github" / "workflows").is_dir():
            return candidate
    not_evaluated("no .github/workflows ancestor of this file")


def is_output_line(line: str) -> bool:
    """A bare echo/printf: the line runs nothing else."""
    s = line.strip()
    if not OUTPUT_COMMAND_RE.match(s) or "$(" in s or "`" in s:
        return False
    quote, i = None, 0
    while i < len(s):
        c = s[i]
        if quote:
            if c == "\\" and quote == '"':
                i += 1
            elif c == quote:
                quote = None
        elif c in "'\"":
            quote = c
        elif c == "\\":
            i += 1
        elif c in ";|":
            return False
        elif c == "&" and s[i - 1] not in "<>" and s[i + 1:i + 2] != ">":
            return False
        i += 1
    return True


def suites_named(run: str) -> list[str]:
    found: list[str] = []
    for line in run.split("\n"):
        if line.lstrip().startswith("#") or is_output_line(line):
            continue
        found.extend(SUITE_RE.findall(line))
    return found


def positive_int(value) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value >= 1


def ceiling_of(job: dict) -> int:
    """What a step's own bound must stay below: its job's limit, else the host's."""
    limit = job.get("timeout-minutes")
    return min(limit, HOST_JOB_LIMIT) if positive_int(limit) else HOST_JOB_LIMIT


def bounded(step: dict, ceiling: int) -> bool:
    value = step.get("timeout-minutes")
    return positive_int(value) and value < ceiling


def judge(doc: dict):
    """-> (population, findings, run_steps, reasons); entries are (job id, step index, step name)."""
    population, findings, run_steps, reasons = [], [], [], {}
    for job_id, job in (doc.get("jobs") or {}).items():
        ceiling = ceiling_of(job)
        whose = "its job's own limit" if positive_int(job.get("timeout-minutes")) else "the host's job limit"
        for index, step in enumerate(job.get("steps") or []):
            if not isinstance(step.get("run"), str):
                continue
            key = (job_id, index, str(step.get("name") or "<unnamed>"))
            run_steps.append(key)
            if suites_named(step["run"]):
                population.append(key)
                if not bounded(step, ceiling):
                    findings.append(key)
                    value = step.get("timeout-minutes")
                    reasons[key] = ("carries no positive integer timeout-minutes" if not positive_int(value)
                                    else "carries timeout-minutes %d, not below its ceiling of %d minutes (%s), so "
                                         "it can never be the bound that fires" % (value, ceiling, whose))
    return population, findings, run_steps, reasons


def job_findings(doc: dict) -> list[str]:
    """Jobs that carry no positive integer job-level timeout-minutes below the host's limit."""
    return [job_id for job_id, job in (doc.get("jobs") or {}).items()
            if not (positive_int(job.get("timeout-minutes")) and job["timeout-minutes"] < HOST_JOB_LIMIT)]


def job_arms(doc: dict, unbounded_jobs):
    """Strip each bounded job's limit in turn; reject a job limit at the host's own limit."""
    errors: list[tuple[str, str]] = []
    base = set(unbounded_jobs)
    stripped = 0
    for job_id in doc["jobs"]:
        if job_id in base:
            continue
        mutated = copy.deepcopy(doc)
        del mutated["jobs"][job_id]["timeout-minutes"]
        stripped += 1
        if set(job_findings(mutated)) != base | {job_id}:
            errors.append(("BROKEN PROBE", "sensitivity: stripping job %s's limit did not produce exactly that "
                                           "finding" % job_id))
    if stripped == 0:
        errors.append(("INDETERMINATE (PV-2)", "no job carries a job-level limit to strip"))
    first_job = next(iter(doc["jobs"]))
    mutated = copy.deepcopy(doc)
    mutated["jobs"][first_job]["timeout-minutes"] = HOST_JOB_LIMIT
    host_limit_rejected = first_job in job_findings(mutated)
    if not host_limit_rejected:
        errors.append(("BROKEN PROBE", "sensitivity: a job limit of %d minutes, the host's own, was accepted "
                                       "as a bound" % HOST_JOB_LIMIT))
    return errors, stripped, host_limit_rejected


def below_floor(count: int, floor: int) -> bool:
    return count < floor


def population_at(doc: dict, population, target: int) -> dict:
    """A copy of the workflow whose suite-invoking population is `target` steps. Surplus steps are
    rewritten into a loop that names no suite path, the refactor the floor exists to catch; a
    shortfall is made up with bounded seeded steps."""
    mutated = copy.deepcopy(doc)
    surplus = len(population) - target
    for job_id, index, _ in population[:max(surplus, 0)]:
        mutated["jobs"][job_id]["steps"][index]["run"] = PATH_FREE_RUN
    first_job = next(iter(mutated["jobs"]))
    for n in range(max(-surplus, 0)):
        mutated["jobs"][first_job]["steps"].append(
            {"name": "seeded floor step %d" % n, "run": "bash core/deploy/tests/zz_floor_%d.sh\n" % n,
             "timeout-minutes": 1})
    return mutated


def read_yaml(path: Path, what: str):
    try:
        text = path.read_text(encoding="utf-8")
        return text, yaml.safe_load(text)
    except (OSError, yaml.YAMLError) as exc:
        not_evaluated("the %s %s could not be read as YAML (%s)" % (what, path.name, type(exc).__name__))


def fixture_arms(text: str, doc: dict):
    """Each labeled fixture step's verdict must equal its label.
    -> (errors as (verdict token, detail), count per label)."""
    errors: list[tuple[str, str]] = []
    seen = dict.fromkeys(LABELS, 0)
    step_nodes = []
    for _, job_node in dict((k.value, v) for k, v in yaml.compose(text).value)["jobs"].value:
        step_nodes.extend(dict((k.value, v) for k, v in job_node.value)["steps"].value)
    steps = [s for job in doc["jobs"].values() for s in job["steps"]]
    for node, step in zip(step_nodes, steps):
        name = str(step.get("name", ""))
        label = name.split(":", 1)[0]
        if label not in LABELS:
            errors.append(("INDETERMINATE (PV-1)", "fixture step %r carries no label" % name))
            continue
        seen[label] += 1
        counted = bool(suites_named(step.get("run") or ""))
        raw = text[node.start_mark.index:node.end_mark.index]
        if label == "must-flag" and not counted:
            errors.append(("BROKEN PROBE", "sensitivity: %r was not counted" % name))
        if label != "must-flag":
            if counted:
                errors.append(("OVER-MATCHING PROBE", "specificity: %r was counted" % name))
            if "core/deploy/tests" not in raw:
                errors.append(("INDETERMINATE (PV-5)", "specificity: %r does not carry the near-miss, "
                                                        "so its zero is vacuous" % name))
    for label in LABELS:
        if seen[label] == 0:
            errors.append(("INDETERMINATE (PV-2)", "the fixture carries no %s step" % label))
    return errors, seen


def live_arms(doc: dict, population, findings, floor: int):
    """Strip each bounded live suite step in turn; reject bounds that are not bounds; drive the
    population to one below the floor and to the floor."""
    errors: list[tuple[str, str]] = []
    base = set(findings)
    stripped = 0
    for key in population:
        if key in base:
            continue
        mutated = copy.deepcopy(doc)
        del mutated["jobs"][key[0]]["steps"][key[1]]["timeout-minutes"]
        stripped += 1
        if set(judge(mutated)[1]) != base | {key}:
            errors.append(("BROKEN PROBE", "sensitivity: stripping the timeout from job %s step %r did not "
                                           "produce exactly that finding" % (key[0], key[2])))
    if stripped == 0:
        errors.append(("INDETERMINATE (PV-2)", "no bounded suite step exists to strip"))
    first_job = next(iter(doc["jobs"]))
    ceiling = ceiling_of(doc["jobs"][first_job])
    bad_values = (0, "5", True, ceiling)
    for bad in bad_values:
        mutated = copy.deepcopy(doc)
        mutated["jobs"][first_job]["steps"].append(
            {"name": "seeded", "run": "bash core/deploy/tests/zz_seeded.sh\n", "timeout-minutes": bad})
        if len(judge(mutated)[1]) != len(findings) + 1:
            errors.append(("BROKEN PROBE", "sensitivity: timeout-minutes %r was accepted as a bound" % (bad,)))
    floor_reported = {}
    for target, want in ((floor - 1, True), (floor, False)):
        count = len(judge(population_at(doc, population, target))[0])
        if count != target:
            errors.append(("INDETERMINATE (PV-2)", "the floor arm could not drive the population to %d "
                                                   "(it reached %d)" % (target, count)))
            continue
        floor_reported[target] = below_floor(count, floor)
        if floor_reported[target] != want:
            errors.append(("BROKEN PROBE" if want else "OVER-MATCHING PROBE",
                           "%s: a population of %d against the floor of %d was %s"
                           % ("sensitivity" if want else "specificity", count, floor,
                              "not reported" if want else "reported")))
    return errors, stripped, len(bad_values), ceiling, floor_reported


def main(argv: list[str]) -> int:
    root = repo_root()
    workflow = root / ".github" / "workflows" / "install-tests.yml"
    fixture = root / "core" / "deploy" / "tests" / "fixtures" / "step-timeouts" / "labeled-steps.yml"
    args = list(argv)
    while args:
        flag = args.pop(0)
        if flag == "--workflow" and args:
            workflow = Path(args.pop(0))
        elif flag == "--fixture" and args:
            fixture = Path(args.pop(0))
        else:
            not_evaluated("unrecognised argument %r" % flag)

    workflow_text, doc = read_yaml(workflow, "workflow")
    if not isinstance(doc, dict) or not isinstance(doc.get("jobs"), dict):
        not_evaluated("%s carries no jobs mapping" % workflow.name)
    population, findings, run_steps, reasons = judge(doc)
    if not run_steps or not population:
        not_evaluated("%d run: steps and %d suite-invoking steps were parsed out of %s"
                      % (len(run_steps), len(population), workflow.name))
    fixture_text, fixture_doc = read_yaml(fixture, "fixture")
    if not isinstance(fixture_doc, dict) or not isinstance(fixture_doc.get("jobs"), dict):
        not_evaluated("%s carries no jobs mapping" % fixture.name)
    floor = fixture_doc.get(FLOOR_KEY)
    if not positive_int(floor):
        not_evaluated("%s carries no positive integer %s" % (fixture.name, FLOOR_KEY))

    fixture_errors, seen = fixture_arms(fixture_text, fixture_doc)
    live_errors, stripped, bad_values, ceiling, floor_reported = live_arms(doc, population, findings, floor)
    unbounded_jobs = job_findings(doc)
    job_errors, jobs_stripped, host_limit_rejected = job_arms(doc, unbounded_jobs)
    drawn = [k for k in run_steps if k not in population
             and "core/deploy/tests/" in doc["jobs"][k[0]]["steps"][k[1]]["run"]]
    covered = len(population) - len(findings)
    breached = below_floor(len(population), floor)
    jobs_bounded = len(doc["jobs"]) - len(unbounded_jobs)

    print("Timeout guard denominator: %d run: steps in %d jobs of %s (%d bytes read); %d invoke a "
          "core/deploy/tests shell suite and %d do not."
          % (len(run_steps), len(doc["jobs"]), workflow.name, len(workflow_text.encode("utf-8")),
             len(population), len(run_steps) - len(population)))
    print("Timeout guard control — sensitivity: must-flag fixture steps counted: %d; bounded live suite "
          "steps flagged when stripped in turn: %d of %d; values that are not bounds rejected: %d (the "
          "first job's ceiling of %d minutes among them); a population driven to one below the floor "
          "reported: %s."
          % (seen["must-flag"], stripped, covered, bad_values, ceiling,
             "yes" if floor_reported.get(floor - 1) else "no"))
    print("Timeout guard control — specificity: must-not-flag fixture steps left uncounted, each shown to "
          "carry the near-miss: %d (%s, %d bytes read); live run: steps naming the tests directory "
          "without a shell suite, outside the population: %d; a population driven to exactly the floor "
          "reported: %s."
          % (seen["must-not-flag"], fixture.name, len(fixture_text.encode("utf-8")), len(drawn),
             "yes" if floor_reported.get(floor) else "no"))
    print("Timeout guard documented exclusion: not-seen fixture steps left uncounted: %d (a suite reached "
          "with no core/deploy/tests/<name>.sh path on any line)." % seen["not-seen"])
    if breached:
        slack = "BELOW it"
    elif len(population) > floor:
        slack = ("%d above it; raise %s in %s to %d, so a later shrink of that size is caught"
                 % (len(population) - floor, FLOOR_KEY, fixture.name, len(population)))
    else:
        slack = "at it"
    print("Timeout guard population floor: %d suite-invoking steps against a committed floor of %d — %s."
          % (len(population), floor, slack))
    print("Timeout guard job limits: %d of %d jobs carry a job-level timeout-minutes below the host's %d-minute "
          "limit; each job's limit stripped in turn flagged: %d of %d; a job limit at the host's own limit "
          "rejected: %s."
          % (jobs_bounded, len(doc["jobs"]), HOST_JOB_LIMIT, jobs_stripped, jobs_bounded,
             "yes" if host_limit_rejected else "no"))

    arm_errors = fixture_errors + live_errors + job_errors
    if arm_errors:
        for verdict, detail in arm_errors:
            print("::error::timeout guard arm — %s — %s" % (verdict, detail))
        print("Timeout guard verdict: %s. The probe is unusable, so no step is reported clean or flagged."
              % "; ".join(sorted({verdict for verdict, _ in arm_errors})))
        return 2
    print("Timeout guard measurement state: MEASURED - full population examined.")
    for key in findings:
        print("::error::timeout guard — job %s: step \"%s\" invokes a core/deploy/tests shell suite and %s"
              % (key[0], key[2], reasons[key]))
    if breached:
        print("::error::timeout guard — the workflow carries %d suite-invoking steps, below the committed "
              "floor of %d (%s in %s). An invocation that stops naming its core/deploy/tests/<name>.sh path "
              "on a run: line (a loop over a variable, a wrapper, a cd or working-directory key, an assembled "
              "path) leaves this guard's sight, and the floor is what reports it. Restore a countable "
              "invocation, or lower the floor in the same change if the steps were removed on purpose."
              % (len(population), floor, FLOOR_KEY, fixture.name))
    for job_id in unbounded_jobs:
        print("::error::timeout guard — job %s carries no job-level timeout-minutes below the host's %d-minute "
              "limit, so nothing bounds its steps that run no suite" % (job_id, HOST_JOB_LIMIT))
    if findings:
        print("Timeout guard FAILED — %d of %d suite-invoking steps carry timeout-minutes."
              % (covered, len(population)))
    if breached:
        print("Timeout guard FAILED — %d suite-invoking steps, below the committed floor of %d."
              % (len(population), floor))
    if unbounded_jobs:
        print("Timeout guard FAILED — %d of %d jobs carry a job-level timeout-minutes."
              % (jobs_bounded, len(doc["jobs"])))
    if findings or breached or unbounded_jobs:
        return 1
    print("Timeout guard OK — %d of %d suite-invoking steps carry timeout-minutes."
          % (covered, len(population)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
