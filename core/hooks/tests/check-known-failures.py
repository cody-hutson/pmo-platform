#!/usr/bin/env python3
"""check-known-failures.py — judge a hook-harness run against a list of known failures.

The Linux hook-harness job runs the same suites as the macOS job, on a platform where some
of them still fail for reasons already filed. The job cannot be required until those are
fixed, and a plain red check would hold up every pull request until then. This checker is
the job's verdict instead: the run is GREEN only when every failure it shows is a known
one, and RED as soon as it shows anything else.

    check-known-failures.py --run-log <runner output> --list <known-failure list>
                            --tests-dir <materialized tests dir>
    check-known-failures.py --self-test

RED (exit 1) when any of these holds:
  - the runner printed no AGGREGATE line (the run is not a result);
  - a suite in --tests-dir did not run, or ran without a summary line;
  - a suite's FAIL lines do not number its summary's FAIL count;
  - a FAIL line matches no list row for its suite;
  - a `defect` row matches no FAIL line — the defect is fixed, so its row must go;
  - the list itself is malformed.
A `timing` row may match or not: timing arms pass or fail between runs on a shared runner,
so a row for one can tolerate its failure but cannot demand it. Exit 2: unreadable input.

The list holds one row per known failure, `suite|arm|class|reason`, `#` comments and blank
lines ignored. `arm` is a literal prefix of the failure's text after `FAIL: `. `class` is
`defect` or `timing`. `reason` says why the arm fails here, in words: the list is a stopgap
for failures that are each fixed under their own work item, never a permanent exemption,
and the job becomes a required check once the list holds no rows.

Lines the runner forwards as `RESIDUAL` are reported as not evaluated on this runner. They
never count as a pass.
"""
import argparse
import os
import re
import sys
import tempfile

CLASSES = ("defect", "timing")
RUNNING = re.compile(r"^----- running: (\S+) -----$")
SUMMARY = re.compile(r"^(\S+) — Total: (\d+)  PASS: (\d+)  FAIL: (\d+)$")
NOSUM = re.compile(r"^ERROR: (\S+) produced no summary line$")
AGG = re.compile(r"^AGGREGATE: PASS=(\d+)  FAIL=(\d+)$")


def parse_list(text):
    """Return (rows, problems). A row is (suite, arm, class, reason, line number)."""
    rows, problems, seen = [], [], set()
    for n, raw in enumerate(text.splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("|", 3)
        if len(parts) != 4:
            problems.append(f"list line {n}: expected suite|arm|class|reason, got {line!r}")
            continue
        suite, arm, cls, reason = (p.strip() for p in parts)
        if not suite.endswith(".test.sh"):
            problems.append(f"list line {n}: suite {suite!r} is not a *.test.sh name")
        if not arm:
            problems.append(f"list line {n}: empty arm")
        if cls not in CLASSES:
            problems.append(f"list line {n}: class {cls!r} is not one of {', '.join(CLASSES)}")
        if not reason:
            problems.append(f"list line {n}: empty reason")
        if (suite, arm) in seen:
            problems.append(f"list line {n}: duplicate row for {suite} {arm!r}")
        seen.add((suite, arm))
        rows.append((suite, arm, cls, reason, n))
    return rows, problems


def parse_run(text):
    """Return a dict: summaries, nosummary, fails (suite -> [text]), residuals, aggregate."""
    out = {"ran": [], "summaries": {}, "nosummary": [], "fails": {}, "residuals": [], "aggregate": None}
    cur = None
    sealed = False  # once a suite has no summary, its echoed output is not forwarded lines
    for line in text.splitlines():
        m = RUNNING.match(line)
        if m:
            cur = m.group(1)
            out["ran"].append(cur)
            sealed = False
            continue
        m = AGG.match(line)
        if m:
            out["aggregate"] = (int(m.group(1)), int(m.group(2)))
            cur = None
            continue
        if cur is None:
            continue
        m = NOSUM.match(line)
        if m and m.group(1) == cur:
            out["nosummary"].append(cur)
            sealed = True
            continue
        if sealed:
            continue
        m = SUMMARY.match(line)
        if m and m.group(1) == cur:
            out["summaries"][cur] = (int(m.group(2)), int(m.group(3)), int(m.group(4)))
            continue
        if cur in out["summaries"]:
            if line.startswith("FAIL"):
                out["fails"].setdefault(cur, []).append(re.sub(r"^FAIL:?\s*", "", line))
            elif line.startswith("RESIDUAL"):
                out["residuals"].append((cur, line))
    return out


def judge(run_text, list_text, expected_suites):
    """Return (red, report lines)."""
    rows, problems = parse_list(list_text)
    run = parse_run(run_text)
    red = list(problems)
    report = []
    if run["aggregate"] is None:
        red.append("the runner printed no AGGREGATE line, so this run is not a result")
    for s in sorted(expected_suites):
        if s not in run["ran"]:
            red.append(f"{s} did not run")
        elif s in run["nosummary"]:
            red.append(f"{s} ran without a summary line, so none of its assertions were counted")
    used = set()
    for suite, fails in sorted(run["fails"].items()):
        total, _, nfail = run["summaries"][suite]
        if len(fails) != nfail:
            red.append(f"{suite}: its summary counts {nfail} failure(s) but {len(fails)} FAIL line(s) were forwarded")
        for f in fails:
            match = [r for r in rows if r[0] == suite and f.startswith(r[1])]
            if match:
                used.add((match[0][0], match[0][1]))
                report.append(f"KNOWN    {suite}: {match[0][1]} ({match[0][2]}) — {match[0][3]}")
            else:
                red.append(f"{suite}: unlisted failure: {f[:240]}")
    for suite, (total, _, nfail) in sorted(run["summaries"].items()):
        if nfail and suite not in run["fails"]:
            red.append(f"{suite}: its summary counts {nfail} failure(s) but no FAIL line was forwarded")
    for suite, arm, cls, reason, n in rows:
        if (suite, arm) in used:
            continue
        if cls == "defect":
            red.append(f"list line {n}: {suite} {arm!r} no longer fails — the defect is fixed, so remove its row")
        else:
            report.append(f"PASSED   {suite}: {arm} (timing row; tolerated either way)")
    for suite, line in run["residuals"]:
        report.append(f"RESIDUAL {suite}: {line}")
    agg = run["aggregate"]
    report.append(f"rows: {len(rows)} ({sum(1 for r in rows if r[2] == 'defect')} defect, "
                  f"{sum(1 for r in rows if r[2] == 'timing')} timing); aggregate: "
                  f"{'PASS=%d FAIL=%d' % agg if agg else 'none'}")
    return red, report


def run_checker(args):
    try:
        run_text = open(args.run_log, encoding="utf-8", errors="replace").read()
        list_text = open(args.list, encoding="utf-8").read()
        suites = [f for f in os.listdir(args.tests_dir) if f.endswith(".test.sh")]
    except OSError as e:
        print(f"check-known-failures: cannot read input: {e}", file=sys.stderr)
        return 2
    if not suites:
        print(f"check-known-failures: no *.test.sh in {args.tests_dir}", file=sys.stderr)
        return 2
    red, report = judge(run_text, list_text, suites)
    for line in report:
        print(line)
    for line in red:
        print(f"RED      {line}")
    verdict = "RED" if red else "GREEN"
    print(f"KNOWN-FAILURES: {verdict} — {len(red)} problem(s), {len(suites)} suite(s) expected")
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as fh:
            fh.write(f"### Hook harness against the known-failure list: {verdict}\n\n```\n")
            fh.write("\n".join(report + [f"RED {r}" for r in red]) + "\n```\n")
    return 1 if red else 0


# ----------------------------------------------------------------------------------------
# Self-test: each arm judges a constructed run against a constructed list, and states the
# verdict it must reach. Sensitivity arms must go RED; specificity arms must stay GREEN.
def _run(*suites, aggregate=True):
    lines = ["hook test harness"]
    tp = tf = 0
    for name, total, fails, residuals in suites:
        lines.append(f"----- running: {name} -----")
        if total is None:
            lines.append(f"ERROR: {name} produced no summary line")
            lines.append("FAIL: echoed output from a suite with no summary")
            continue
        lines.append(f"{name} — Total: {total}  PASS: {total - len(fails)}  FAIL: {len(fails)}")
        lines.extend(residuals)
        lines.extend(f"FAIL: {f}" for f in fails)
        tp += total - len(fails)
        tf += len(fails)
    if aggregate:
        lines.append(f"AGGREGATE: PASS={tp}  FAIL={tf}")
    return "\n".join(lines) + "\n"


LIST = """# suite|arm|class|reason
a.test.sh|AC-1:|defect|a known defect
a.test.sh|AC-T:|timing|a timing arm that flips
"""


def self_test():
    S = ["a.test.sh", "b.test.sh"]
    ok = [("a.test.sh", 5, ["AC-1: known one", "AC-T: slow"], []), ("b.test.sh", 3, [], [])]
    arms = [
        ("SPEC-1 every failure listed", _run(*ok), LIST, S, False),
        ("SPEC-2 a timing row that passed", _run(("a.test.sh", 5, ["AC-1: known one"], []), ("b.test.sh", 3, [], [])), LIST, S, False),
        ("SPEC-3 a RESIDUAL line is reported, not counted",
         _run(("a.test.sh", 5, ["AC-1: x", "AC-T: y"], ["RESIDUAL: not evaluated here"]), ("b.test.sh", 3, [], [])), LIST, S, False),
        ("SENS-1 an unlisted failure", _run(("a.test.sh", 5, ["AC-1: x", "AC-9: new"], []), ("b.test.sh", 3, [], [])), LIST, S, True),
        ("SENS-2 a defect row that no longer fails", _run(("a.test.sh", 5, ["AC-T: y"], []), ("b.test.sh", 3, [], [])), LIST, S, True),
        ("SENS-3 a suite with no summary line", _run(("a.test.sh", 5, ["AC-1: x"], []), ("b.test.sh", None, [], [])), LIST, S, True),
        ("SENS-4 no AGGREGATE line", _run(*ok, aggregate=False), LIST, S, True),
        ("SENS-5 an expected suite that did not run", _run(*ok), LIST, S + ["c.test.sh"], True),
        ("SENS-6 a listed arm failing in another suite", _run(("a.test.sh", 5, ["AC-1: x"], []), ("b.test.sh", 3, ["AC-1: x"], [])), LIST, S, True),
        ("SENS-7 FAIL lines fewer than the summary's count",
         _run(*ok).replace("a.test.sh — Total: 5  PASS: 3  FAIL: 2", "a.test.sh — Total: 5  PASS: 2  FAIL: 3"), LIST, S, True),
        ("SENS-8 a row with no reason", _run(*ok), LIST + "a.test.sh|AC-2:|defect|\n", S, True),
        ("SENS-9 a row with an unknown class", _run(*ok), LIST + "a.test.sh|AC-2:|flaky|why\n", S, True),
        ("SENS-10 a duplicate row", _run(*ok), LIST + "a.test.sh|AC-1:|defect|again\n", S, True),
    ]
    bad = 0
    for name, run_text, list_text, suites, want_red in arms:
        red, _ = judge(run_text, list_text, suites)
        got = bool(red)
        verdict = "PASS" if got == want_red else "FAIL"
        bad += verdict == "FAIL"
        print(f"{verdict}: {name} -> {'RED' if got else 'GREEN'} (want {'RED' if want_red else 'GREEN'})")
    # The command-line path, end to end, on files: a GREEN and a RED run.
    with tempfile.TemporaryDirectory() as d:
        os.makedirs(os.path.join(d, "t"))
        for s in S:
            open(os.path.join(d, "t", s), "w").close()
        open(os.path.join(d, "list"), "w").write(LIST)
        for name, text, want in (("CLI-GREEN", _run(*ok), 0), ("CLI-RED", _run(*ok, aggregate=False), 1)):
            open(os.path.join(d, "log"), "w").write(text)
            ns = argparse.Namespace(run_log=os.path.join(d, "log"), list=os.path.join(d, "list"), tests_dir=os.path.join(d, "t"))
            saved = os.environ.pop("GITHUB_STEP_SUMMARY", None)
            null = open(os.devnull, "w")
            real, sys.stdout = sys.stdout, null
            try:
                rc = run_checker(ns)
            finally:
                sys.stdout = real
                null.close()
                if saved is not None:
                    os.environ["GITHUB_STEP_SUMMARY"] = saved
            verdict = "PASS" if rc == want else "FAIL"
            bad += verdict == "FAIL"
            print(f"{verdict}: {name} -> exit {rc} (want {want})")
    total = len(arms) + 2
    print(f"Total: {total}  PASS: {total - bad}  FAIL: {bad}")
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--run-log")
    ap.add_argument("--list")
    ap.add_argument("--tests-dir")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return self_test()
    if not (args.run_log and args.list and args.tests_dir):
        ap.error("--run-log, --list and --tests-dir are required unless --self-test")
    return run_checker(args)


if __name__ == "__main__":
    sys.exit(main())
