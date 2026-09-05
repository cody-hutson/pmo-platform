#!/usr/bin/env python3
"""check-ac-binding.py — release-plan AC row-to-criterion BINDING conformance.

THE INVARIANT. A release plan's Verification Plan carries one `AC-N` row per
acceptance criterion, and — per the plan template's row-label contract — those rows
"correspond position-for-position to the numbered criteria in the issue body". This
primitive asserts that correspondence. It is the runner for a contract that until now
existed only as prose.

WHY THE EXISTING SIGNAL CANNOT DO THIS. `ac_baseline: { #N: <count>, ... }` records a
COUNT of criteria per issue. A count is compared against a count, so it is blind to
binding by construction: a plan can carry exactly as many rows as the issue has
criteria while a row grades the wrong criterion, grades an implementation act that is
not a criterion at all, or leaves a criterion ungraded — and the arithmetic still
closes. That is not hypothetical. Across one release's four cards every count matched
and three of the four were mis-bound; a manual sweep repaired one card and left its
sibling broken with the repair commit still fresh. This check is the mechanical answer
to a class a sweep demonstrably does not hold.

THE COUNT CHECK IS NOT REPLACED. `ac_baseline` catches a real and DIFFERENT class —
the plan's transcription of the criterion count drifting from the live issue — and
this primitive asserts it too, as BASELINE-DRIFT, whenever the criteria oracle is
present. Binding is added BESIDE the count, never in place of it.

WHERE THE ORACLE COMES FROM. Criterion TEXT is the only oracle for binding, and the
plan does not carry it: plans cite "AC1-AC5 per the issue body". So the oracle is the
issue body, supplied as a JSON snapshot via --criteria-file (the determinism seam,
mirroring the host tooling's --stage4-comment / --fcm-diff-file convention) or read
live with --fetch. THE ORDINAL LIMB NEEDS NEITHER: it is computed from the plan alone,
because `ac_baseline` names the criterion COUNT and therefore the criterion ORDINAL
SET {1..N}. Reading the baseline as a SET rather than a CARDINALITY is what turns it
from a number-vs-number comparison into an assertion with a gap, a duplicate and an
out-of-range class.

WHAT THIS CHECK DOES NOT ASSERT, STATED PLAINLY. It cannot read intent. The binding
limb is LEXICAL: a row binds when it echoes at least one of its criterion's
DISCRIMINATIVE terms — the terms that separate that criterion from its siblings in the
same issue. A row that echoes a discriminative term while grading a different aspect
of the same criterion still reads BOUND. That residue is reviewer-read and is named in
the output as such, rather than being dressed up as a semantic verdict. The asymmetry
is deliberate and is the safe direction: a false BOUND leaves today's reviewer read
exactly where it already is, while a false UNBOUND is loud and costs one dismissal.

DISPLACED OBLIGATIONS ARE LEGITIMATE. `OBL-N` rows carry real obligations a card owes
from its Change Specification or Documentation Impact table. They are re-homed
obligations, not deleted ones. They are parsed, reported as DISPLACED, and EXCLUDED
from the criterion set — never counted against it, and never treated as a missing AC.

A ZERO-ROW PLAN IS NOT A CLEAN RESULT. "No rows" and "all rows correctly bound" are
byte-identical under a naive implementation, which is the false-green shape this family
of checks exists to remove. A plan with no `ac_baseline` line, no per-issue table, or
zero parsed `AC-` rows is UNPARSEABLE (exit 3) — an input failure, never BOUND. An
issue whose criteria cannot be parsed withholds its binding verdict as NOT-EVALUATED
rather than passing on an empty oracle.

VERDICT PRECEDENCE (headline token only):
    UNPARSEABLE > BASELINE-DRIFT > ORDINAL-GAP > UNBOUND > NOT-EVALUATED > BOUND
Every finding of every class is emitted as its own row regardless of which one supplies
the headline, so a lower-precedence finding is never masked by a higher one.

OUTPUT — TSV, one class per first field:

    SCAN            <plan>        <ac-rows>     <obl-rows>    <issues>
    BASELINE        <#N>          <count>       <read_at>
    COVERAGE        <#N>          <claimed>     <expected>    <missing|-> <extra|-> <dup|->
    DISPLACED       <#N>          <OBL-k>       excluded-from-ac-set
    BINDING         <#N>          <AC-k>        <BOUND|UNBOUND|WEAK-ORACLE|NOT-EVALUATED>  <detail>
    BASELINE-DRIFT  <#N>          <declared>    <observed>
    ORDINAL-GAP     <#N>          <class>       <detail>
    UNBOUND         <#N>          <AC-k>        <criterion-head>
    NOT-EVALUATED   <#N|->        <reason>
    UNPARSEABLE     <reason>
    VERDICT         <token>

Callers MUST route every unrecognised first-field value through a residual bucket: an
unrecognised class is a FINDING, never an absence.

EXIT CODES (mirroring the check-roster extraction-contract convention):
    0  BOUND
    1  a non-BOUND verdict was reached (finding, or a withheld verdict)
    3  input failure — the plan carries no baseline, no per-issue table, or no `AC-`
       rows; fail loud rather than reading green over an empty set
"""

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

# --- Plan grammar -----------------------------------------------------------
# The per-issue table lives under a `### Per-Issue Verification` heading; the
# baseline is a fenced-code `ac_baseline:` line in the same section. Both shapes are
# published in release/skills/release-planner/references/release-plan-template.md.
_SECTION_RE = re.compile(r"^#{2,4}\s+Per-Issue Verification\s*$")
_HEADING_RE = re.compile(r"^#{1,6}\s+")
_BASELINE_RE = re.compile(r"ac_baseline\s*:\s*\{(.*?)\}", re.DOTALL)
_BASELINE_ENTRY_RE = re.compile(r"#(\d+)\s*:\s*(\d+)")
_READ_AT_RE = re.compile(r"read_at\s*:\s*([0-9a-fA-F]{7,40})")
_ISSUE_CELL_RE = re.compile(r"^#(\d+)$")
_LABEL_CELL_RE = re.compile(r"^(AC|OBL)[-‐-―\s]?(\d+)$", re.IGNORECASE)

_ORDINAL_CLASSES = ("missing", "extra", "duplicate")

# Terms this short, or this common, carry no discriminating power. Kept small and
# explicit: the predicate's job is to find the terms that SEPARATE sibling criteria,
# and an over-large stoplist would erase real signal rather than noise.
_MIN_TERM_LEN = 4
_STOPWORDS = frozenset("""
that this with from into than then when what which where while there their they them
have been being does done doing must should would could shall will
each every both same other another such only also more most less least very
rather instead across against about above below over under after before
than once upon here else none nothing something anything
""".split())

_TOKEN_RE = re.compile(r"[A-Za-z0-9_.\-/]+")


def _fold(term):
    """Light suffix fold so `links`/`link` and `mandates`/`mandate` compare equal."""
    for suffix, keep in (("ies", 3), ("ing", 3), ("ed", 2), ("es", 2), ("s", 1)):
        if term.endswith(suffix) and len(term) - keep >= _MIN_TERM_LEN:
            return term[: len(term) - keep]
    return term


def related(a, b):
    """The term-matching relation: equality, or prefix subsumption at >= 4 chars.

    A suffix fold alone is asymmetric in a way that costs real accuracy: `cites`
    folds to `cite` while `cited` does not (the `ed` rule would leave a 3-char stem),
    so a row citing a rule reads as unrelated to a criterion about citing it. Prefix
    subsumption closes that without a stemmer dependency.

    THE SAME RELATION MUST GOVERN BOTH USES. Discriminative terms are computed with
    it and the row intersection is tested with it. Using set equality for one and
    subsumption for the other would let a term count as discriminating under the
    strict relation and then match a sibling's row under the loose one — a binding
    asserted by the inconsistency rather than by the text.
    """
    if a == b:
        return True
    if len(b) >= _MIN_TERM_LEN and a.startswith(b):
        return True
    return len(a) >= _MIN_TERM_LEN and b.startswith(a)


def terms(text):
    """Content terms of a string: lowercased, folded, stopworded, length-filtered."""
    out = set()
    for raw in _TOKEN_RE.findall(text or ""):
        tok = raw.lower().strip("._-/")
        if len(tok) < _MIN_TERM_LEN or tok in _STOPWORDS:
            continue
        out.add(_fold(tok))
        # A path or dotted token also contributes its segments, so
        # `core/rules/git-workflow.md` reaches a criterion naming `git-workflow`.
        for seg in re.split(r"[./_-]+", tok):
            if len(seg) >= _MIN_TERM_LEN and seg not in _STOPWORDS:
                out.add(_fold(seg))
    return out


def split_row(line):
    """Split a markdown table row on UNESCAPED pipes.

    Plan method cells legitimately carry `\\|` to hold a shell pipeline inside a
    table cell. Splitting on a bare `|` shears those cells and grades the wrong
    fragment, so the escape is honoured here rather than assumed absent.
    """
    cells, buf, i = [], [], 0
    while i < len(line):
        ch = line[i]
        if ch == "\\" and i + 1 < len(line) and line[i + 1] == "|":
            buf.append("|")
            i += 2
            continue
        if ch == "|":
            cells.append("".join(buf).strip())
            buf = []
            i += 1
            continue
        buf.append(ch)
        i += 1
    cells.append("".join(buf).strip())
    if cells and cells[0] == "":
        cells = cells[1:]
    if cells and cells[-1] == "":
        cells = cells[:-1]
    return cells


def parse_plan(text):
    """Return (rows, baseline, read_at, saw_section).

    rows: list of dicts {issue, kind, ordinal, method, expected}
    baseline: {issue -> declared criterion count}
    """
    lines = text.splitlines()
    start = None
    for idx, line in enumerate(lines):
        if _SECTION_RE.match(line.strip()):
            start = idx + 1
            break
    if start is None:
        return [], {}, "", False

    end = len(lines)
    for idx in range(start, len(lines)):
        stripped = lines[idx].strip()
        if _HEADING_RE.match(stripped) and not _SECTION_RE.match(stripped):
            end = idx
            break
    body = "\n".join(lines[start:end])

    rows = []
    for line in lines[start:end]:
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue
        cells = split_row(stripped)
        if len(cells) < 2:
            continue
        m_issue = _ISSUE_CELL_RE.match(cells[0])
        if not m_issue:
            continue
        m_label = _LABEL_CELL_RE.match(cells[1])
        if not m_label:
            continue
        rows.append({
            "issue": m_issue.group(1),
            "kind": m_label.group(1).upper(),
            "ordinal": int(m_label.group(2)),
            "method": cells[2] if len(cells) > 2 else "",
            "expected": cells[3] if len(cells) > 3 else "",
        })

    baseline, read_at = {}, ""
    m_base = _BASELINE_RE.search(body)
    if m_base:
        for issue, count in _BASELINE_ENTRY_RE.findall(m_base.group(1)):
            baseline[issue] = int(count)
        m_read = _READ_AT_RE.search(m_base.group(1))
        if m_read:
            read_at = m_read.group(1)
    return rows, baseline, read_at, True


def discriminative(criteria):
    """Per-criterion terms that no SIBLING criterion in the same issue carries.

    The discriminating terms are the ones a correctly-bound row must echo. Generic
    vocabulary — `check`, `rules`, `deploy` — recurs across every criterion of a card
    and would let any row match any criterion, which is the same blindness the count
    check already has one level down.
    """
    all_terms = [terms(c) for c in criteria]
    out = []
    for i, own in enumerate(all_terms):
        others = set()
        for j, sib in enumerate(all_terms):
            if j != i:
                others |= sib
        out.append({t for t in own if not any(related(t, o) for o in others)})
    return out, all_terms


def analyse(plan_text, criteria_map=None, plan_name="-"):
    """Return (rows_out, verdict, exit_code)."""
    criteria_map = criteria_map or {}
    out = []
    rows, baseline, read_at, saw_section = parse_plan(plan_text)

    ac_rows = [r for r in rows if r["kind"] == "AC"]
    obl_rows = [r for r in rows if r["kind"] == "OBL"]

    # --- Vacuity guards. Each is an INPUT FAILURE, never a clean result. --------
    if not saw_section:
        out.append(("UNPARSEABLE", "no `### Per-Issue Verification` section in the plan"))
        out.append(("VERDICT", "UNPARSEABLE"))
        return out, "UNPARSEABLE", 3
    if not baseline:
        out.append(("UNPARSEABLE",
                    "no `ac_baseline:` line — the criterion ordinal set has no oracle, "
                    "so no binding can be asserted"))
        out.append(("VERDICT", "UNPARSEABLE"))
        return out, "UNPARSEABLE", 3
    if not ac_rows:
        out.append(("UNPARSEABLE",
                    "zero `AC-` rows parsed under a declared baseline of %d issue(s) — "
                    "an empty row set is not all-bindings-correct" % len(baseline)))
        out.append(("VERDICT", "UNPARSEABLE"))
        return out, "UNPARSEABLE", 3

    out.append(("SCAN", plan_name, str(len(ac_rows)), str(len(obl_rows)), str(len(baseline))))

    findings = {"BASELINE-DRIFT": 0, "ORDINAL-GAP": 0, "UNBOUND": 0, "NOT-EVALUATED": 0}

    issues = sorted(set(list(baseline.keys()) + [r["issue"] for r in rows]), key=int)
    for issue in issues:
        declared = baseline.get(issue)
        if declared is None:
            findings["ORDINAL-GAP"] += 1
            out.append(("ORDINAL-GAP", "#" + issue, "no-baseline",
                        "the plan grades this issue but `ac_baseline` does not name it, "
                        "so its criterion ordinal set is undeclared"))
            continue
        out.append(("BASELINE", "#" + issue, str(declared), read_at or "-"))

        claimed = [r["ordinal"] for r in ac_rows if r["issue"] == issue]
        expected = set(range(1, declared + 1))
        missing = sorted(expected - set(claimed))
        extra = sorted(set(claimed) - expected)
        dup = sorted({o for o in claimed if claimed.count(o) > 1})
        out.append(("COVERAGE", "#" + issue,
                    ",".join(str(o) for o in sorted(set(claimed))) or "-",
                    "1-%d" % declared if declared else "-",
                    ",".join(str(o) for o in missing) or "-",
                    ",".join(str(o) for o in extra) or "-",
                    ",".join(str(o) for o in dup) or "-"))
        for cls, vals in zip(_ORDINAL_CLASSES, (missing, extra, dup)):
            if vals:
                findings["ORDINAL-GAP"] += len(vals)
                out.append(("ORDINAL-GAP", "#" + issue, cls,
                            "ordinal(s) %s" % ",".join(str(v) for v in vals)))

        for row in sorted((r for r in obl_rows if r["issue"] == issue),
                          key=lambda r: r["ordinal"]):
            out.append(("DISPLACED", "#" + issue, "OBL-%d" % row["ordinal"],
                        "excluded-from-ac-set"))

        # --- Binding limb ------------------------------------------------------
        criteria = criteria_map.get(issue)
        if not criteria:
            findings["NOT-EVALUATED"] += 1
            out.append(("NOT-EVALUATED", "#" + issue,
                        "no criteria oracle for this issue — binding withheld, not passed"))
            continue
        if len(criteria) != declared:
            findings["BASELINE-DRIFT"] += 1
            out.append(("BASELINE-DRIFT", "#" + issue, str(declared), str(len(criteria))))

        disc, full = discriminative(criteria)
        for row in sorted((r for r in ac_rows if r["issue"] == issue),
                          key=lambda r: r["ordinal"]):
            k = row["ordinal"]
            if not 1 <= k <= len(criteria):
                # Already counted as an ordinal gap; the binding limb has no
                # criterion to compare against, so it withholds rather than passes.
                out.append(("BINDING", "#" + issue, "AC-%d" % k, "NOT-EVALUATED",
                            "no criterion at this ordinal"))
                continue
            row_terms = terms(row["method"] + " " + row["expected"])
            own_disc = disc[k - 1]
            oracle, state = own_disc, "BOUND"
            if not own_disc:
                # Sibling criteria are lexically indistinguishable — the oracle is
                # degraded. Say so; do not silently fall through to a pass.
                oracle, state = full[k - 1], "WEAK-ORACLE"
            shared = sorted(t for t in oracle if any(related(t, r) for r in row_terms))
            if shared:
                out.append(("BINDING", "#" + issue, "AC-%d" % k, state,
                            ",".join(shared[:6])))
            else:
                findings["UNBOUND"] += 1
                head = " ".join(criteria[k - 1].split())[:110]
                out.append(("BINDING", "#" + issue, "AC-%d" % k, "UNBOUND",
                            "no discriminative term of the criterion appears in the row"))
                out.append(("UNBOUND", "#" + issue, "AC-%d" % k, head))

    for token in ("BASELINE-DRIFT", "ORDINAL-GAP", "UNBOUND", "NOT-EVALUATED"):
        if findings[token]:
            out.append(("VERDICT", token))
            return out, token, 1
    out.append(("VERDICT", "BOUND"))
    return out, "BOUND", 0


def emit(rows, stream):
    for row in rows:
        stream.write("\t".join(str(c) for c in row) + "\n")


# ---------------------------------------------------------------------------
# Criteria oracle
# ---------------------------------------------------------------------------
_AC_HEADING_RE = re.compile(r"^#+\s*Acceptance Criteria", re.IGNORECASE)
_AC_ITEM_RE = re.compile(r"^\s*[-*]\s*\[[ xX]\]\s*(.+)$")


def criteria_from_body(body):
    crits, on = [], False
    for line in (body or "").splitlines():
        if _AC_HEADING_RE.match(line.strip()):
            on = True
            continue
        if on and re.match(r"^#+\s", line):
            break
        if on:
            m = _AC_ITEM_RE.match(line)
            if m:
                crits.append(m.group(1).strip())
    return crits


def fetch_criteria(issues, repo):
    out = {}
    for issue in issues:
        proc = subprocess.run(
            ["gh", "issue", "view", issue, "--repo", repo,
             "--json", "body", "--jq", ".body"],
            capture_output=True, text=True)
        if proc.returncode != 0:
            continue
        crits = criteria_from_body(proc.stdout)
        if crits:
            out[issue] = crits
    return out


def load_criteria_file(path):
    with open(path, encoding="utf-8") as fh:
        raw = json.load(fh)
    return {str(k).lstrip("#"): list(v) for k, v in raw.items()}


# ---------------------------------------------------------------------------
# Self-test — every arm is a falsification arm.
# ---------------------------------------------------------------------------
_PLAN_HEAD = "## Verification Plan\n\n### Per-Issue Verification\n\n"
_TABLE_HEAD = "| Issue | AC | Verification Method | Expected Result |\n|---|---|---|---|\n"


def _plan(rows, baseline="ac_baseline: { #1: 2, read_at: abc1234 }", section=True):
    body = _PLAN_HEAD if section else "## Verification Plan\n\n"
    body += _TABLE_HEAD + "".join(rows)
    body += "\n`%s`\n" % baseline if baseline else "\n"
    return body


_CRIT = {"1": ["The widget emits a checksum for every shard.",
               "The daemon rotates its journal at midnight."]}


def _cases():
    """(name, plan, criteria, expected_verdict, expected_exit)."""
    bound = [
        "| #1 | AC-1 | `grep checksum w.py` | Every shard carries a checksum |\n",
        "| #1 | AC-2 | `grep journal d.py` | The journal rotates at midnight |\n",
    ]
    return [
        ("bound — every ordinal present and every row echoes its criterion",
         _plan(bound), _CRIT, "BOUND", 0),
        ("ordinal-gap missing — AC-2 has no row while the baseline declares 2",
         _plan(bound[:1]), _CRIT, "ORDINAL-GAP", 1),
        ("ordinal-gap duplicate — two rows claim AC-1, so AC-2 is silently ungraded",
         _plan([bound[0], bound[0]]), _CRIT, "ORDINAL-GAP", 1),
        ("ordinal-gap extra — a row claims an ordinal the issue does not have",
         _plan(bound + ["| #1 | AC-3 | `grep x w.py` | Something |\n"]),
         _CRIT, "ORDINAL-GAP", 1),
        ("unbound — the count and the ordinals both close, and AC-2 grades AC-1's subject",
         _plan([bound[0],
                "| #1 | AC-2 | `grep checksum w.py` | The shard checksum is emitted |\n"]),
         _CRIT, "UNBOUND", 1),
        ("unbound — a row grades an implementation act that is no criterion at all",
         _plan([bound[0],
                "| #1 | AC-2 | `grep -c legacy d.py` | Zero: the legacy array entry is gone |\n"]),
         _CRIT, "UNBOUND", 1),
        ("displaced obligations do not count against the criterion set",
         _plan(bound + ["| #1 | OBL-1 | `grep telemetry d.py` | The telemetry note is recorded |\n"]),
         _CRIT, "BOUND", 0),
        ("baseline-drift — the declared count no longer matches the live criteria",
         _plan(bound, baseline="ac_baseline: { #1: 3, read_at: abc1234 }"),
         _CRIT, "BASELINE-DRIFT", 1),
        ("not-evaluated — no oracle for the issue withholds the binding verdict",
         _plan(bound), {}, "NOT-EVALUATED", 1),
        ("escaped pipes in a method cell do not shear the row",
         _plan([
             "| #1 | AC-1 | `grep checksum w.py \\| wc -l` | Every shard carries a checksum |\n",
             bound[1]]),
         _CRIT, "BOUND", 0),
    ]


def _vacuity_cases():
    """(name, plan, criteria, expected_verdict, expected_exit) — the false-green arms."""
    bound = "| #1 | AC-1 | `grep checksum w.py` | Every shard carries a checksum |\n"
    return [
        ("vacuity — a plan with ZERO rows must not read as all-bindings-correct",
         _plan([]), _CRIT, "UNPARSEABLE", 3),
        ("vacuity — a plan with no `ac_baseline` line has no ordinal oracle",
         _plan([bound], baseline=""), _CRIT, "UNPARSEABLE", 3),
        ("vacuity — a plan with no per-issue section at all",
         _plan([bound], section=False), _CRIT, "UNPARSEABLE", 3),
        ("vacuity — an EMPTY input is an input failure, never BOUND",
         "", _CRIT, "UNPARSEABLE", 3),
    ]


def self_test():
    failures, ran = [], 0

    for name, plan, crits, want_verdict, want_exit in _cases() + _vacuity_cases():
        _rows, verdict, code = analyse(plan, crits, "self-test")
        ran += 1
        if verdict != want_verdict or code != want_exit:
            failures.append("%s: expected %s/exit %d, got %s/exit %d"
                            % (name, want_verdict, want_exit, verdict, code))

    # An issue whose criteria are lexically indistinguishable degrades the oracle
    # rather than silently passing: the row must be labelled WEAK-ORACLE.
    same = {"1": ["The widget emits a checksum.", "The widget emits a checksum."]}
    rows, _verdict, _code = analyse(
        _plan(["| #1 | AC-1 | `grep checksum w.py` | A checksum is emitted |\n",
               "| #1 | AC-2 | `grep checksum w.py` | A checksum is emitted |\n"]),
        same, "self-test")
    ran += 1
    if not any(r[0] == "BINDING" and r[3] == "WEAK-ORACLE" for r in rows):
        failures.append("weak-oracle: indistinguishable sibling criteria must be "
                        "labelled WEAK-ORACLE, not passed silently")

    # Every finding is emitted as its own row even when a higher-precedence class
    # supplies the headline — a masked finding is an invisible one.
    rows, verdict, _code = analyse(
        _plan(["| #1 | AC-1 | `grep -c legacy d.py` | Zero: the legacy entry is gone |\n"],
              baseline="ac_baseline: { #1: 3, read_at: abc1234 }"),
        _CRIT, "self-test")
    ran += 1
    classes = {r[0] for r in rows}
    if verdict != "BASELINE-DRIFT" or not {"ORDINAL-GAP", "UNBOUND"} <= classes:
        failures.append("precedence: a BASELINE-DRIFT headline must still emit the "
                        "ORDINAL-GAP and UNBOUND rows it outranks (got %s / %s)"
                        % (verdict, sorted(classes)))

    # Round-trip: the criteria extractor must read a real issue-body shape.
    body = ("## Summary\n\n### Acceptance Criteria\n\n"
            "- [ ] First criterion.\n- [x] Second criterion.\n\n### Notes\n\n- [ ] Not a criterion.\n")
    ran += 1
    if criteria_from_body(body) != ["First criterion.", "Second criterion."]:
        failures.append("oracle: the criteria extractor must stop at the next heading "
                        "and read both checked and unchecked items")

    # This file must itself parse as UNPARSEABLE — a table fixture leaking into the
    # module docstring would make the tool grade its own prose on a live run.
    with tempfile.TemporaryDirectory() as root:
        path = os.path.join(root, "self.md")
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(open(os.path.abspath(__file__), encoding="utf-8").read())
        _rows, verdict, code = analyse(open(path, encoding="utf-8").read(), {}, "self")
    ran += 1
    if (verdict, code) != ("UNPARSEABLE", 3):
        failures.append("self-reference: this file must not parse as a release plan "
                        "(got %s/exit %d)" % (verdict, code))

    for line in failures:
        sys.stderr.write("FAIL  %s\n" % line)
    sys.stdout.write("self-test: %d case(s), %d failure(s)\n" % (ran, len(failures)))
    return 1 if failures else 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("plan", nargs="?", help="release plan markdown file")
    parser.add_argument("--criteria-file",
                        help="JSON {issue: [criterion, ...]} — the determinism seam")
    parser.add_argument("--fetch", action="store_true",
                        help="read criteria live with `gh issue view` instead")
    parser.add_argument("--repo", default="cody-hutson/pmo-platform")
    parser.add_argument("--output-format", choices=("tsv",), default="tsv")
    parser.add_argument("--self-test", action="store_true",
                        help="run the falsification arms and exit")
    args = parser.parse_args(argv)

    if args.self_test:
        return self_test()
    if not args.plan:
        parser.error("a release plan path is required (or --self-test)")
    if not os.path.isfile(args.plan):
        sys.stderr.write("error: not a regular file: %s\n" % args.plan)
        return 3

    with open(args.plan, encoding="utf-8") as fh:
        text = fh.read()

    criteria = {}
    if args.criteria_file:
        criteria = load_criteria_file(args.criteria_file)
    elif args.fetch:
        _rows, baseline, _read_at, _seen = parse_plan(text)
        criteria = fetch_criteria(sorted(baseline, key=int), args.repo)

    rows, _verdict, code = analyse(text, criteria, os.path.basename(args.plan))
    emit(rows, sys.stdout)
    return code


if __name__ == "__main__":
    sys.exit(main())
