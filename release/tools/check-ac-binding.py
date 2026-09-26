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

THE ISSUE BODY IS READ UNDER THE ACCEPTANCE-ASSERTION CONTRACT'S VOCABULARY — its
parse rules P1 and P2, in the eval-writer skill's acceptance-assertion reference —
not under a forked one. A criteria block opens at a heading whose text starts
`Acceptance Criteria` or `Completion condition (verifiable)`, at any heading level,
and the next heading of any level closes it. Its criteria are its top-level list
items of one shape: its task-list lines when any are present; otherwise its ordered
items; otherwise its plain `-`/`*` bullets. A nested item is detail of its parent, a
plain bullet in a task-list block is an annotation, and a thematic break is no item.
A heading outside the vocabulary opens nothing — `Cross-Issue Acceptance Criteria` is
the named control — so a sibling list is never read as the card's own.

THE DESIGN LIMB (MAP) RUNS ONLY ON A SUPPLIED SNAPSHOT. A Stage-5 design comment
restates or refines a card's criteria under its own labels and has no fixed grammar,
so the binder cannot read one. --design-file supplies it: per issue, each design
entry's label, its text, and the issue ordinal it DECLARES it maps to (`maps_to`, or
null for a design-only obligation). The issue list that declaration is checked
against comes through --fetch or --criteria-file — the reader the plan limb uses —
never from the design file. Each declared target is checked lexically, exactly as a
plan row is: a declaration is a claim, and a mis-declared one reads UNBOUND.

CRITERION NAMESPACE. An acceptance-criterion ordinal is unique only inside the list
that counts it — the issue body, a Stage-5 design comment, or the release plan — so
every emitted line ends in an `ns:` field. `ns:plan` marks a line about the plan's own
rows; `ns:plan>issue` a plan row resolved to the issue list; `ns:design>issue` a
declared design mapping checked against it. The VERDICT line names the resolutions
that ran. The field is appended LAST, so every earlier field keeps its index. The
namespaces, the reference forms and the `ns:` grammar are defined once, in the Stage-8
QA spec's criterion-namespace section.

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

OUTPUT — TSV, one class per first field; the LAST field of every line is its `ns:`:

    SCAN            <plan>   <ac-rows>   <obl-rows>   <issues>                        ns:plan
    BASELINE        <#N>     <count>     <read_at>                                    ns:plan
    COVERAGE        <#N>     <claimed>   <expected>   <missing|-> <extra|-> <dup|->   ns:plan
    DISPLACED       <#N>     <OBL-k>     excluded-from-ac-set                         ns:plan
    BINDING         <#N>     <AC-k>      <BOUND|UNBOUND|WEAK-ORACLE|NOT-EVALUATED> <detail>
                                                                                      ns:plan>issue
    BASELINE-DRIFT  <#N>     <declared>  <observed>                                   ns:plan>issue
    ORDINAL-GAP     <#N>     <class>     <detail>                ns:plan, or ns:design>issue
    UNBOUND         <#N>     <label>     <head>            ns:plan>issue, or ns:design>issue
    MAP             <#N>     <label|->   <AC-k|none|?>  <state>  <detail>             ns:design>issue
    NOT-EVALUATED   <#N|->   <reason>                  ns:plan>issue, or ns:design>issue
    UNVISITED       <#N>     <issue|design>  <detail>  ns:plan>issue, or ns:design>issue
    UNPARSEABLE     <reason>                                                          ns:plan
    OUT-OF-SCOPE    <reason>                                                          ns:plan
    VERDICT         <token>                                  ns:<the resolutions that ran>

MAP states. The declared target is checked: BOUND, WEAK-ORACLE (a degraded oracle,
labelled) or UNBOUND. Not checked: NONE (declared design-only; informational),
UNDECLARED (no `maps_to`), OUT-OF-RANGE (a target the issue list does not have), and
UNRESTATED (an issue ordinal no design entry targets; informational, labelled `-`).
UNDECLARED and OUT-OF-RANGE raise ORDINAL-GAP; UNBOUND raises UNBOUND.

NOT-EVALUATED names which of its two causes withheld the verdict, and keeps the phrase
"no criteria oracle": `(oracle-unavailable)` — no criteria were read for the issue (it
is absent from the snapshot, or its fetch failed), so the check cannot run here;
`(no-criteria-section)` — the body was read and carries no vocabulary heading with
items under it, so there was nothing to read.

UNVISITED is informational: a snapshot key the plan grades no row for, reported rather
than dropped.

READING EACH OUTCOME in the release's one outcome partition (the exit codes below are
unchanged by it):

    BOUND, WEAK-ORACLE                   pass                                  exit 0
    UNBOUND, ORDINAL-GAP, BASELINE-DRIFT fail                                  exit 1
    NOT-EVALUATED (oracle-unavailable)   can't run here: unverified, not pass  exit 1
    NOT-EVALUATED (no-criteria-section)  could not read                        exit 1
    OUT-OF-SCOPE                         a named SKIP: predates the schema     exit 0
    UNPARSEABLE                          could not read: an input failure      exit 3

Callers MUST route every unrecognised first-field value through a residual bucket: an
unrecognised class is a FINDING, never an absence.

EXIT CODES (mirroring the check-roster extraction-contract convention):
    0  BOUND
    1  a non-BOUND verdict was reached (finding, or a withheld verdict)
    3  input failure — the plan carries no baseline, no per-issue table, or no `AC-`
       rows; fail loud rather than reading green over an empty set
"""

import argparse
import contextlib
import io
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
_OUTER_SECTION_RE = re.compile(r"^##\s+Verification Plan\s*$")
_SECTION_RE = re.compile(r"^#{2,4}\s+Per-Issue Verification\s*$")
_HEADING_RE = re.compile(r"^#{1,6}\s+")
_BASELINE_RE = re.compile(r"ac_baseline\s*:\s*\{(.*?)\}", re.DOTALL)
_BASELINE_ENTRY_RE = re.compile(r"#(\d+)\s*:\s*(\d+)")
_READ_AT_RE = re.compile(r"read_at\s*:\s*([0-9a-fA-F]{7,40})")
_ISSUE_CELL_RE = re.compile(r"^#(\d+)$")
_LABEL_CELL_RE = re.compile(r"^(AC|OBL)[-‐-―\s]?(\d+)$", re.IGNORECASE)

_ORDINAL_CLASSES = ("missing", "extra", "duplicate")

# The criterion namespace each emitted line carries in its LAST field (the module
# docstring's CRITERION NAMESPACE paragraph; the Stage-8 QA spec defines the grammar).
_NS_PLAN = "ns:plan"
_NS_PLAN_ISSUE = "ns:plan>issue"
_NS_DESIGN_ISSUE = "ns:design>issue"

# The two causes of a withheld verdict. Both keep the phrase "no criteria oracle".
_UNAVAILABLE = "oracle-unavailable"
_NO_SECTION = "no-criteria-section"

# `_MIN_TERM_LEN` is a NOISE AND COST GUARD, NOT A CORRECTNESS GUARD, and the
# distinction is measured rather than assumed: removing it leaves the self-test fully
# green (a deliberately-retained surviving mutant). The reason is the discriminative-
# term design one level up — a short token common enough to matter appears in the
# sibling criteria too, so it is subtracted out of every discriminative set before any
# row is compared, and `related()` carries its own floor so subsumption never fires on
# a short stem either. The floor is kept because it keeps the emitted `shared` cell
# readable and the term sets small; it is NOT claimed to be load-bearing.
#
# `_MAX_PREFIX_DELTA` IS load-bearing and is proven so by mutation — see `related()`.
_MIN_TERM_LEN = 4
_MAX_PREFIX_DELTA = 1
# The stoplist is deliberately small: the predicate's job is to find the terms that
# SEPARATE sibling criteria, and an over-large stoplist erases signal, not noise.
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

    THE LENGTH BOUND IS LOAD-BEARING, and it was added against a measured false BOUND.
    Unbounded subsumption crosses morpheme boundaries: `carried` folds to `carri`,
    which is a prefix of `carrier`, so a criterion about the subset CARRIED to a branch
    read as bound to a row about the mirror CARRIER. The fold already handles every
    ordinary inflection (`links`/`link`, `mirrored`/`mirror`); subsumption exists only
    to rescue the fold's short-stem failures, which are all off by exactly one
    character. Bounding the delta at 1 keeps every rescue and refuses the drift.
    """
    if a == b:
        return True
    shorter, longer = (a, b) if len(a) <= len(b) else (b, a)
    if len(shorter) < _MIN_TERM_LEN or len(longer) - len(shorter) > _MAX_PREFIX_DELTA:
        return False
    return longer.startswith(shorter)


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


def _scan_rows(lines):
    """Graded rows in `lines`: `| #N | AC-k | method | expected |` (or `OBL-k`)."""
    rows = []
    for line in lines:
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue
        cells = split_row(stripped)
        if len(cells) < 2:
            continue
        m_issue = _ISSUE_CELL_RE.match(cells[0])
        m_label = _LABEL_CELL_RE.match(cells[1]) if m_issue else None
        if not m_label:
            continue
        rows.append({
            "issue": m_issue.group(1),
            "kind": m_label.group(1).upper(),
            "ordinal": int(m_label.group(2)),
            "method": cells[2] if len(cells) > 2 else "",
            "expected": cells[3] if len(cells) > 3 else "",
        })
    return rows


def parse_plan(text):
    """Return (rows, baseline, read_at, saw_section).

    rows: list of dicts {issue, kind, ordinal, method, expected}
    baseline: {issue -> declared criterion count}
    """
    lines = text.splitlines()

    # THE ANCHOR IS THE `## Verification Plan` SECTION, NOT the `### Per-Issue
    # Verification` sub-heading, because the shipped corpus carries THREE variants of
    # the same contract: table under the sub-heading with the baseline after it; the
    # baseline above the sub-heading; and — in 9 plans — the table directly under the
    # parent with no sub-heading at all. Anchoring on the sub-heading reads all three
    # of the last kind as "no verification section" and reports a false UNPARSEABLE on
    # a conforming plan. The contract is what the section HOLDS, not which heading
    # level introduces it.
    start = None
    for idx, line in enumerate(lines):
        if _OUTER_SECTION_RE.match(line.strip()) or _SECTION_RE.match(line.strip()):
            start = idx + 1
            break
    if start is None:
        # No heading. Scan the WHOLE document for graded rows anyway, so the
        # out-of-scope escape in analyse() can require their absence rather than
        # trusting a heading that a conforming plan could simply lose.
        return _scan_rows(lines), {}, "", False

    # The section ends at the next SAME-OR-HIGHER heading. Sub-headings inside it
    # (`### Per-Issue Verification`, `### Release-Level Verification`) stay in scope;
    # the rollback tables, which live under their own `## Rollback Strategy` and carry
    # a `### Per-Issue Rollback` of their own, do not.
    end = len(lines)
    for idx in range(start, len(lines)):
        stripped = lines[idx].strip()
        if stripped.startswith("## ") and not stripped.startswith("###"):
            end = idx
            break

    body = "\n".join(lines[start:end])
    rows = _scan_rows(lines[start:end])

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


def _head(text):
    return " ".join((text or "").split())[:110]


def _lexical_bind(text, k, disc, full):
    """(state, shared terms) for `text` claiming criterion `k` (1-based).

    ONE RELATION GOVERNS BOTH LIMBS. A plan row claiming an issue ordinal and a design
    entry declaring one bind the same way: by echoing a discriminative term of that
    criterion, or — when sibling criteria are lexically indistinguishable — a term of
    its full set, labelled WEAK-ORACLE rather than passed silently.
    """
    text_terms = terms(text)
    oracle, state = disc[k - 1], "BOUND"
    if not oracle:
        oracle, state = full[k - 1], "WEAK-ORACLE"
    shared = sorted(t for t in oracle if any(related(t, r) for r in text_terms))
    return state, shared


def _withheld(issue, criteria_map, what):
    """The NOT-EVALUATED detail, naming which of its two causes withheld `what`.

    An issue the snapshot does not carry — or whose fetch failed — had no criteria read
    at all (`oracle-unavailable`); an issue carried with an empty list had its body read
    and found no vocabulary heading with items under it (`no-criteria-section`).
    """
    reason = _NO_SECTION if issue in criteria_map else _UNAVAILABLE
    return "no criteria oracle for this issue (%s) — %s withheld, not passed" % (reason, what)


def _issue_key(issue):
    return (0, int(issue)) if issue.isdigit() else (1, issue)


def _design_limb(issue, entries, criteria_map, out, findings):
    """Check each design entry's DECLARED issue ordinal against the issue list.

    The declaration is the claim and the issue list is the evidence, read through the
    binder's own reader and never taken from the design file — so declaring and
    checking work from different inputs, as they do in the plan limb.
    """
    criteria = criteria_map.get(issue)
    if not criteria:
        findings["NOT-EVALUATED"] += 1
        out.append(("NOT-EVALUATED", "#" + issue,
                    _withheld(issue, criteria_map, "design mapping"), _NS_DESIGN_ISSUE))
        return
    disc, full = discriminative(criteria)
    targeted = set()
    for entry in entries:
        label, head = entry["label"], _head(entry["text"])
        if "maps_to" not in entry:
            findings["ORDINAL-GAP"] += 1
            out.append(("MAP", "#" + issue, label, "?", "UNDECLARED",
                        "the entry declares no issue ordinal", _NS_DESIGN_ISSUE))
            out.append(("ORDINAL-GAP", "#" + issue, "undeclared",
                        "design %s declares no issue ordinal (maps_to)" % label,
                        _NS_DESIGN_ISSUE))
            continue
        k = entry["maps_to"]
        if k is None:
            out.append(("MAP", "#" + issue, label, "none", "NONE", head, _NS_DESIGN_ISSUE))
            continue
        if not 1 <= k <= len(criteria):
            findings["ORDINAL-GAP"] += 1
            out.append(("MAP", "#" + issue, label, "AC-%d" % k, "OUT-OF-RANGE",
                        "the issue list has %d criteria" % len(criteria), _NS_DESIGN_ISSUE))
            out.append(("ORDINAL-GAP", "#" + issue, "out-of-range",
                        "design %s maps to AC-%d; the issue list has %d criteria"
                        % (label, k, len(criteria)), _NS_DESIGN_ISSUE))
            continue
        targeted.add(k)
        state, shared = _lexical_bind(entry["text"], k, disc, full)
        if shared:
            out.append(("MAP", "#" + issue, label, "AC-%d" % k, state,
                        ",".join(shared[:6]), _NS_DESIGN_ISSUE))
        else:
            findings["UNBOUND"] += 1
            out.append(("MAP", "#" + issue, label, "AC-%d" % k, "UNBOUND",
                        "no discriminative term of the target criterion appears in the entry",
                        _NS_DESIGN_ISSUE))
            out.append(("UNBOUND", "#" + issue, label, head, _NS_DESIGN_ISSUE))
    # An issue ordinal no entry targets is reported, informationally: the design may
    # simply not restate it, and the plan limb, not this one, owes it a row.
    for k in range(1, len(criteria) + 1):
        if k not in targeted:
            out.append(("MAP", "#" + issue, "-", "AC-%d" % k, "UNRESTATED",
                        _head(criteria[k - 1]), _NS_DESIGN_ISSUE))


def analyse(plan_text, criteria_map=None, plan_name="-", ordinals_only=False,
            design_map=None):
    """Return (rows_out, verdict, exit_code).

    `ordinals_only` runs the plan-local limb alone. It exists because the two limbs
    have DIFFERENT input sets and therefore different enforceable surfaces: the
    ordinal limb is offline and deterministic, so it can block a pull request, while
    the binding limb needs the issue bodies and can only run where they are readable.
    Without this split the CI surface would report NOT-EVALUATED on every run —
    a permanently degraded gate, which is the shape operators learn to ignore.

    `design_map` ({issue: [{label, text, maps_to?}, ...]}) runs the design limb (MAP)
    after the binding limb, against the same `criteria_map`. It never runs under
    `ordinals_only`. Every emitted row ends in its `ns:` field.
    """
    criteria_map = criteria_map or {}
    out = []
    rows, baseline, read_at, saw_section = parse_plan(plan_text)

    ac_rows = [r for r in rows if r["kind"] == "AC"]
    obl_rows = [r for r in rows if r["kind"] == "OBL"]

    # --- Vacuity guards. Each is an INPUT FAILURE, never a clean result. --------
    if not saw_section:
        # OUT-OF-SCOPE, NOT a pass, and the distinction is the whole point. 181 of the
        # 201 plans in the corpus predate the per-issue Verification Plan schema
        # entirely; grading them UNPARSEABLE would turn a CI surface red on history
        # and teach the operator to ignore it. The population test is emitted with the
        # verdict so an absent section is on the record rather than silently absorbed.
        #
        # THE ESCAPE IS NARROW BY CONSTRUCTION, and it turns on POSITIVE evidence
        # rather than on an absence. It requires zero parsed graded rows AND a
        # document that is structurally a plan (at least one `## ` heading). An
        # empty file, a truncated read, or a file that is not a plan at all has no
        # heading and falls through to UNPARSEABLE — because "nothing here" and
        # "nothing here YET" must not share a verdict. A conforming plan cannot opt
        # out of the gate by losing its heading either: its rows keep it out of this
        # branch.
        plan_shaped = any(ln.startswith("## ") for ln in plan_text.splitlines())
        if not rows and plan_shaped:
            out.append(("OUT-OF-SCOPE",
                        "no `### Per-Issue Verification` section and no `AC-`/`OBL-` "
                        "rows — this plan predates the per-issue verification schema",
                        _NS_PLAN))
            out.append(("VERDICT", "OUT-OF-SCOPE", _NS_PLAN))
            return out, "OUT-OF-SCOPE", 0
        out.append(("UNPARSEABLE",
                    "no `### Per-Issue Verification` heading; %d graded row(s) parsed, "
                    "plan-shaped=%s — neither an in-scope plan nor a readable one"
                    % (len(rows), "yes" if plan_shaped else "no"), _NS_PLAN))
        out.append(("VERDICT", "UNPARSEABLE", _NS_PLAN))
        return out, "UNPARSEABLE", 3
    # OPT-IN TEST, and it runs BEFORE the vacuity guards for a reason. A plan can
    # carry a `## Verification Plan` section that holds only the release-level
    # checklist and grades no per-issue criteria at all; that plan is outside this
    # contract, and reporting it UNPARSEABLE would grade a section for lacking a
    # thing it never claimed. A plan opts IN by carrying graded rows or a baseline —
    # and once it has either, both vacuity guards below apply in full, so opting in
    # halfway is a finding rather than an exemption.
    if not rows and not baseline:
        out.append(("OUT-OF-SCOPE",
                    "a Verification Plan section carrying no graded `AC-`/`OBL-` row "
                    "and no `ac_baseline:` line — this plan grades no per-issue "
                    "criteria", _NS_PLAN))
        out.append(("VERDICT", "OUT-OF-SCOPE", _NS_PLAN))
        return out, "OUT-OF-SCOPE", 0
    if not baseline:
        out.append(("UNPARSEABLE",
                    "%d graded row(s) but no `ac_baseline:` line — the criterion "
                    "ordinal set has no oracle, so no binding can be asserted"
                    % len(rows), _NS_PLAN))
        out.append(("VERDICT", "UNPARSEABLE", _NS_PLAN))
        return out, "UNPARSEABLE", 3
    if not ac_rows:
        out.append(("UNPARSEABLE",
                    "zero `AC-` rows parsed under a declared baseline of %d issue(s) — "
                    "an empty row set is not all-bindings-correct" % len(baseline),
                    _NS_PLAN))
        out.append(("VERDICT", "UNPARSEABLE", _NS_PLAN))
        return out, "UNPARSEABLE", 3

    out.append(("SCAN", plan_name, str(len(ac_rows)), str(len(obl_rows)), str(len(baseline)),
                _NS_PLAN))

    findings = {"BASELINE-DRIFT": 0, "ORDINAL-GAP": 0, "UNBOUND": 0, "NOT-EVALUATED": 0}

    issues = sorted(set(list(baseline.keys()) + [r["issue"] for r in rows]), key=int)
    for issue in issues:
        declared = baseline.get(issue)
        if declared is None:
            findings["ORDINAL-GAP"] += 1
            out.append(("ORDINAL-GAP", "#" + issue, "no-baseline",
                        "the plan grades this issue but `ac_baseline` does not name it, "
                        "so its criterion ordinal set is undeclared", _NS_PLAN))
            continue
        out.append(("BASELINE", "#" + issue, str(declared), read_at or "-", _NS_PLAN))

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
                    ",".join(str(o) for o in dup) or "-", _NS_PLAN))
        for cls, vals in zip(_ORDINAL_CLASSES, (missing, extra, dup)):
            if vals:
                findings["ORDINAL-GAP"] += len(vals)
                out.append(("ORDINAL-GAP", "#" + issue, cls,
                            "ordinal(s) %s" % ",".join(str(v) for v in vals), _NS_PLAN))

        for row in sorted((r for r in obl_rows if r["issue"] == issue),
                          key=lambda r: r["ordinal"]):
            out.append(("DISPLACED", "#" + issue, "OBL-%d" % row["ordinal"],
                        "excluded-from-ac-set", _NS_PLAN))

        # --- Binding limb ------------------------------------------------------
        if ordinals_only:
            continue
        criteria = criteria_map.get(issue)
        if not criteria:
            findings["NOT-EVALUATED"] += 1
            out.append(("NOT-EVALUATED", "#" + issue,
                        _withheld(issue, criteria_map, "binding"), _NS_PLAN_ISSUE))
            continue
        if len(criteria) != declared:
            findings["BASELINE-DRIFT"] += 1
            out.append(("BASELINE-DRIFT", "#" + issue, str(declared), str(len(criteria)),
                        _NS_PLAN_ISSUE))

        disc, full = discriminative(criteria)
        for row in sorted((r for r in ac_rows if r["issue"] == issue),
                          key=lambda r: r["ordinal"]):
            k = row["ordinal"]
            if not 1 <= k <= len(criteria):
                # Already counted as an ordinal gap; the binding limb has no
                # criterion to compare against, so it withholds rather than passes.
                out.append(("BINDING", "#" + issue, "AC-%d" % k, "NOT-EVALUATED",
                            "no criterion at this ordinal", _NS_PLAN_ISSUE))
                continue
            # A degraded oracle (lexically indistinguishable siblings) is labelled
            # WEAK-ORACLE by `_lexical_bind`, never silently passed.
            state, shared = _lexical_bind(row["method"] + " " + row["expected"], k,
                                          disc, full)
            if shared:
                out.append(("BINDING", "#" + issue, "AC-%d" % k, state,
                            ",".join(shared[:6]), _NS_PLAN_ISSUE))
            else:
                findings["UNBOUND"] += 1
                out.append(("BINDING", "#" + issue, "AC-%d" % k, "UNBOUND",
                            "no discriminative term of the criterion appears in the row",
                            _NS_PLAN_ISSUE))
                out.append(("UNBOUND", "#" + issue, "AC-%d" % k, _head(criteria[k - 1]),
                            _NS_PLAN_ISSUE))

    # --- Design limb (MAP): only on a supplied design snapshot, never ordinals-only.
    if design_map is not None and not ordinals_only:
        for issue in issues:
            if issue in design_map:
                _design_limb(issue, design_map[issue], criteria_map, out, findings)

    # A snapshot key the plan grades no row for is named, never silently dropped.
    if not ordinals_only:
        graded = set(issues)
        for key in sorted(set(criteria_map) - graded, key=_issue_key):
            out.append(("UNVISITED", "#" + key, "issue",
                        "the plan grades no row for this issue, so its criteria "
                        "(%d item(s)) were not compared" % len(criteria_map[key]),
                        _NS_PLAN_ISSUE))
        for key in sorted(set(design_map or {}) - graded, key=_issue_key):
            out.append(("UNVISITED", "#" + key, "design",
                        "the plan grades no row for this issue, so its design entries "
                        "(%d item(s)) were not checked" % len(design_map[key]),
                        _NS_DESIGN_ISSUE))

    # VERDICT names the resolutions that ran.
    if ordinals_only:
        verdict_ns = _NS_PLAN
    elif design_map is not None:
        verdict_ns = _NS_PLAN_ISSUE + ",design>issue"
    else:
        verdict_ns = _NS_PLAN_ISSUE
    for token in ("BASELINE-DRIFT", "ORDINAL-GAP", "UNBOUND", "NOT-EVALUATED"):
        if findings[token]:
            out.append(("VERDICT", token, verdict_ns))
            return out, token, 1
    out.append(("VERDICT", "BOUND", verdict_ns))
    return out, "BOUND", 0


def emit(rows, stream):
    for row in rows:
        stream.write("\t".join(str(c) for c in row) + "\n")


# ---------------------------------------------------------------------------
# Criteria oracle
# ---------------------------------------------------------------------------
# Heading vocabulary: reused from the acceptance-assertion contract (P1), not forked —
# `Acceptance Criteria` or `Completion condition (verifiable)`, any heading level,
# matched from the start of the heading text (`… (testable)` matches;
# `Cross-Issue Acceptance Criteria` does not).
_AC_HEADING_RE = re.compile(
    r"^#+\s*(?:Acceptance Criteria|Completion condition \(verifiable\))", re.IGNORECASE)
_BLOCK_CLOSE_RE = re.compile(r"^#+\s")
# Item shapes (P2), each anchored at column 0: a nested line is detail of its parent.
_AC_ITEM_RE = re.compile(r"^[-*]\s*\[[ xX]\]\s*(.+)$")
_ORDERED_ITEM_RE = re.compile(r"^\d+[.)][ \t]+(?:\[[ xX]\][ \t]+)?(\S.*)$")
_BULLET_ITEM_RE = re.compile(r"^[-*][ \t]+(\S.*)$")
_THEMATIC_BREAK_RE = re.compile(r"^([-*_])[ \t]*(?:\1[ \t]*){2,}$")


def criteria_from_body(body):
    """The issue body's criteria, read as the acceptance-assertion contract reads them.

    P1 — the first vocabulary heading opens the block, and the next heading of ANY
    level closes it, a second vocabulary heading included: two lists are never
    unioned. P2 — the block's criteria are its top-level items of one shape: its
    task-list lines when any are present; otherwise its ordered items; otherwise its
    plain bullets, a thematic break excepted. The rule is checkbox-dominant so that a
    plain bullet beside checkboxes — a declined or superseded annotation — is never
    counted as a criterion.
    """
    block, on = [], False
    for line in (body or "").splitlines():
        if not on:
            on = bool(_AC_HEADING_RE.match(line.strip()))
            continue
        if _BLOCK_CLOSE_RE.match(line):
            break
        block.append(line)
    for item_re in (_AC_ITEM_RE, _ORDERED_ITEM_RE):
        items = [m.group(1).strip() for m in map(item_re.match, block) if m]
        if items:
            return items
    return [m.group(1).strip() for m in map(_BULLET_ITEM_RE.match, block)
            if m and not _THEMATIC_BREAK_RE.match(m.group(0))]


def fetch_criteria(issues, repo=None):
    """Read criteria live via `gh`.

    NO REPOSITORY IS NAMED IN THIS FILE. With `--repo` unset the `gh` invocation
    omits the flag entirely and `gh` resolves the repository from the checkout's own
    remote — which is both the portable behaviour and the reason a repo slug never
    needs to be a literal here. A hardcoded default would be operator-identifying
    data in a tracked `release/` file, which the repository-integrity
    depersonalization gate correctly refuses.

    A body that was read and carries no criteria is stored as an EMPTY list, and only
    a failed fetch leaves the issue absent, so the two causes of a withheld verdict
    (`no-criteria-section` and `oracle-unavailable`) stay apart.
    """
    out = {}
    for issue in issues:
        cmd = ["gh", "issue", "view", issue]
        if repo:
            cmd += ["--repo", repo]
        cmd += ["--json", "body", "--jq", ".body"]
        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            continue
        out[issue] = criteria_from_body(proc.stdout)
    return out


def load_criteria_file(path):
    with open(path, encoding="utf-8") as fh:
        raw = json.load(fh)
    return {str(k).lstrip("#"): list(v) for k, v in raw.items()}


_DESIGN_LABEL_RE = re.compile(r"^(AC|INT)-[1-9][0-9]*$")


def load_design_file(path):
    """Read a design snapshot: {issue: [{"label", "text", "maps_to"?}, ...]}.

    Each entry carries its OWN label — the design's `AC-N` or `INT-N` — because a label
    derived from the entry's position would mislabel every integration criterion.
    `maps_to` is the issue ordinal the entry declares it restates, or null for a
    design-only obligation; an entry without the key is reported UNDECLARED. A
    malformed snapshot raises ValueError (the caller exits 3): it is an input failure,
    never an empty mapping.
    """
    with open(path, encoding="utf-8") as fh:
        raw = json.load(fh)
    if not isinstance(raw, dict):
        raise ValueError("expected an object mapping each issue to a list of entries")
    out = {}
    for key, entries in raw.items():
        issue = str(key).lstrip("#")
        if not isinstance(entries, list):
            raise ValueError("#%s: the design entries must be a list" % issue)
        seen = set()
        for pos, entry in enumerate(entries, 1):
            if not isinstance(entry, dict):
                raise ValueError("#%s entry %d: not an object" % (issue, pos))
            label = entry.get("label")
            if not isinstance(label, str) or not _DESIGN_LABEL_RE.match(label):
                raise ValueError("#%s entry %d: `label` must be AC-<n> or INT-<n>" % (issue, pos))
            if label in seen:
                raise ValueError("#%s: the label %s appears twice" % (issue, label))
            seen.add(label)
            if not isinstance(entry.get("text"), str) or not entry["text"].strip():
                raise ValueError("#%s %s: `text` must be the entry's criterion text"
                                 % (issue, label))
            target = entry.get("maps_to")
            if target is not None and (isinstance(target, bool) or not isinstance(target, int)):
                raise ValueError("#%s %s: `maps_to` must be an issue ordinal or null"
                                 % (issue, label))
        out[issue] = entries
    return out


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
        # THE ARM THAT DISCRIMINATES THIS GATE FROM `ac_baseline`. Two rows against a
        # declared two criteria: the COUNT closes exactly, and the ORDINAL SET does
        # not — AC-2 is ungraded while AC-3 grades a criterion that does not exist.
        # A cardinality comparison reads this plan as clean. Downgrade the set read
        # to a count read and this arm is the one that goes red.
        ("ordinal-gap extra at a MATCHING count — the shape a count check cannot see",
         _plan([bound[0], "| #1 | AC-3 | `grep journal d.py` | The journal rotates |\n"]),
         _CRIT, "ORDINAL-GAP", 1),
        ("ordinal-gap duplicate at a MATCHING count — same blindness, repeated ordinal",
         _plan([bound[0], bound[0]]), _CRIT, "ORDINAL-GAP", 1),
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
        # The shear is POSITIONAL: splitting on a bare pipe turns one method cell into
        # two and pushes Expected out of the read window entirely. The method cell here
        # is deliberately all short tokens, so every discriminating term lives in
        # Expected and a sheared row binds to nothing.
        ("escaped pipes in a method cell do not shear the row out of its Expected cell",
         _plan([
             "| #1 | AC-1 | `a \\| b` | The widget emits a checksum for every shard |\n",
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
        # Opting in halfway is a finding, never an exemption: a baseline with no rows
        # and rows with no baseline are BOTH input failures.
        ("vacuity — a baseline with no graded rows at all",
         _plan([]), _CRIT, "UNPARSEABLE", 3),
        ("out-of-scope — a Verification Plan section that grades no per-issue criteria",
         "## Verification Plan\n\n- [ ] File Integrity\n\n## Rollback\n",
         _CRIT, "OUT-OF-SCOPE", 0),
        ("vacuity — an EMPTY input is an input failure, never BOUND",
         "", _CRIT, "UNPARSEABLE", 3),
        ("vacuity — a file with no `## ` heading is not a plan that predates the schema",
         "just some prose with no headings at all\n", _CRIT, "UNPARSEABLE", 3),
        # The out-of-scope escape, pinned in BOTH directions: a genuine pre-schema plan
        # passes, and the same plan carrying a single graded row cannot.
        ("out-of-scope — a plan-shaped document with no verification section at all",
         "## Summary\n\nNo verification plan here.\n", _CRIT, "OUT-OF-SCOPE", 0),
        ("out-of-scope refused — one graded row is enough to keep a plan in the gate",
         "## Summary\n\n| #1 | AC-1 | `grep x` | Something |\n",
         _CRIT, "UNPARSEABLE", 3),
    ]


# ---------------------------------------------------------------------------
# Criterion-namespace, design-limb and heading-vocabulary arms. Each case name
# carries its plan label (V7494-AC2 to V7494-AC5). Every fixture is a
# `\n`-escaped single-line literal, so no fixture line opens a heading or a table
# row in THIS file and the self-reference arm keeps reading it as UNPARSEABLE.
# ---------------------------------------------------------------------------
_NS_FIELD_RE = re.compile(
    r"^ns:(plan|plan>issue|design>issue)(,(plan>issue|design>issue))*$")
_UNDECLARED = object()
_W = "The widget emits a checksum for every shard."
_D = "The daemon rotates its journal at midnight."
_ISSUE6 = [
    _W,
    _D,
    "The exporter writes a manifest beside each archive.",
    "The scheduler retries a failed upload three times.",
    "The console prints its version banner on startup.",
    "The cache evicts entries older than one week.",
]
_PLAN6_ROWS = [
    "| #1 | AC-1 | `grep checksum w.py` | Every shard carries a checksum |\n",
    "| #1 | AC-2 | `grep journal d.py` | The journal rotates at midnight |\n",
    "| #1 | AC-3 | `grep manifest e.py` | Each archive gets a manifest beside it |\n",
    "| #1 | AC-4 | `grep retry s.py` | A failed upload is retried three times |\n",
    "| #1 | AC-5 | `grep banner c.py` | The version banner prints on startup |\n",
    "| #1 | AC-6 | `grep evict k.py` | Cache entries older than a week are evicted |\n",
]
# The divergent design: seven restated criteria in the design's own order, plus an
# integration criterion, each under its OWN label with the issue ordinal it declares.
_DESIGN8 = (
    ("AC-1", "Every shard the widget emits carries a checksum.", 1),
    ("AC-2", "A failed upload is retried by the scheduler, three attempts at most.", 4),
    ("AC-3", "The exporter manifest lists each archive member.", 3),
    ("AC-4", "Journal rotation happens at midnight local time.", 2),
    ("AC-5", "The version banner prints before any other console output.", 5),
    ("AC-6", "The telemetry beacon ships disabled by default.", None),
    ("AC-7", "Cache eviction drops entries older than seven days.", 6),
    ("INT-1", "The exporter manifest names the checksum of every shard it lists.", None),
)
# A fetched body, read through the binder's own reader: an H2 `Completion condition
# (verifiable)` heading over ordered items, the two forms the widened reader adds.
_FETCHED_BODY = (
    "## Summary\n\nA card.\n\n## Completion condition (verifiable)\n\n"
    + "".join("%d. %s\n" % (i, c) for i, c in enumerate(_ISSUE6, 1))
    + "\n## Notes\n\nNone.\n")
# (case name, issue body) — the reader must return exactly [_W, _D], and the two
# criteria must bind the two-row plan.
_VOCABULARY_ARMS = (
    ("V7494-AC4 an H3 `Acceptance Criteria` heading binds (the issue forms render H3)",
     "## Summary\n\nA card.\n\n### Acceptance Criteria\n\n- [ ] %s\n- [ ] %s\n" % (_W, _D)),
    ("V7494-AC4 an H2 `Completion condition (verifiable)` heading binds",
     "## Completion condition (verifiable)\n\n- [ ] %s\n- [ ] %s\n\n## Notes\n\nNone.\n" % (_W, _D)),
    ("V7494-AC4 `Acceptance Criteria (testable)` binds: the vocabulary is prefix-anchored",
     "### Acceptance Criteria (testable)\n\n- [ ] %s\n- [ ] %s\n" % (_W, _D)),
    ("V7494-AC4 an ordered-only block binds: its top-level ordered items are the criteria",
     "### Acceptance Criteria\n\n1. %s\n2. %s\n" % (_W, _D)),
    ("V7494-AC4 a bullet-only block binds: its plain bullets are the criteria",
     "### Acceptance Criteria\n\n- %s\n- %s\n" % (_W, _D)),
    ("V7494-AC4 checkboxes dominate: a plain **[DECLINED]** bullet in a task-list block is an annotation",
     "### Acceptance Criteria\n\n- [ ] %s\n- **[DECLINED]** The legacy exporter also emits a checksum.\n"
     "- [ ] %s\n" % (_W, _D)),
    ("V7494-AC4 a nested task-list sub-item under an ordered parent is detail, not a criterion",
     "### Acceptance Criteria\n\n1. %s\n   - [ ] a sub-step of the first criterion\n2. %s\n" % (_W, _D)),
    ("V7494-AC4 a vocabulary heading directly after the block closes it: the first list only",
     "### Acceptance Criteria\n\n- [ ] %s\n- [ ] %s\n### Acceptance Criteria (re-scoped)\n\n"
     "- [ ] A re-scoped criterion that is not the card's first list.\n" % (_W, _D)),
    ("V7494-AC4 a thematic break closing a bullet-only block is not a criterion",
     "### Acceptance Criteria\n\n- %s\n- %s\n\n* * *\n" % (_W, _D)),
)


def _design(overrides=None):
    """The divergent design as JSON-ready entries; `overrides` re-declares targets."""
    overrides = overrides or {}
    entries = []
    for label, text, target in _DESIGN8:
        entry = {"label": label, "text": text}
        target = overrides.get(label, target)
        if target is not _UNDECLARED:
            entry["maps_to"] = target
        entries.append(entry)
    return entries


def _write(root, name, payload):
    path = os.path.join(root, name)
    with open(path, "w", encoding="utf-8") as fh:
        if isinstance(payload, str):
            fh.write(payload)
        else:
            json.dump(payload, fh)
    return path


def _run_main(argv):
    """Run main() in-process and capture it: (exit, rows split on tabs, stderr)."""
    out, err = io.StringIO(), io.StringIO()
    try:
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = main(argv)
    except SystemExit as exc:  # argparse refuses an argument it does not know
        code = exc.code if isinstance(exc.code, int) else 2
    return code, [ln.split("\t") for ln in out.getvalue().splitlines() if ln], err.getvalue()


def _rows_of(klass, rows):
    return [[str(c) for c in r] for r in rows if r and r[0] == klass]


def _expected_ns(row):
    """The namespace a line of each class must carry: the class → value table."""
    klass = row[0]
    if klass in ("SCAN", "BASELINE", "COVERAGE", "DISPLACED", "UNPARSEABLE", "OUT-OF-SCOPE"):
        return {"ns:plan"}
    if klass == "ORDINAL-GAP":
        return {"ns:design>issue"} if row[2] in ("undeclared", "out-of-range") else {"ns:plan"}
    if klass in ("BINDING", "BASELINE-DRIFT"):
        return {"ns:plan>issue"}
    if klass == "MAP":
        return {"ns:design>issue"}
    if klass == "UNVISITED":
        return {"ns:design>issue"} if row[2] == "design" else {"ns:plan>issue"}
    if klass == "NOT-EVALUATED":
        return {"ns:design>issue"} if "design mapping" in row[2] else {"ns:plan>issue"}
    if klass == "UNBOUND":
        return {"ns:plan>issue", "ns:design>issue"}
    return set()  # an unrecognised class is a finding, never an absence


def _namespace_arms():
    """The #7494 arms: (cases run, failures)."""
    ran, failures = 0, []

    def check(name, ok, detail=""):
        nonlocal ran
        ran += 1
        if not ok:
            failures.append("%s%s" % (name, (" — " + detail) if detail else ""))

    bound_plan = _plan(_PLAN6_ROWS[:2])
    plan5 = _plan(_PLAN6_ROWS[:5], baseline="ac_baseline: { #1: 5, read_at: abc1234 }")
    plan6 = _plan(_PLAN6_ROWS, baseline="ac_baseline: { #1: 6, read_at: abc1234 }")

    with tempfile.TemporaryDirectory() as root:
        plan5_path = _write(root, "plan5.md", plan5)
        plan6_path = _write(root, "plan6.md", plan6)
        crit_path = _write(root, "criteria.json",
                           {"1": _ISSUE6, "3": ["The gizmo logs every request."]})

        def design_run(overrides=None, plan_path=plan5_path, extra=None):
            payload = {"1": _design(overrides)}
            payload.update(extra or {})
            design_path = _write(root, "design.json", payload)
            return _run_main([plan_path, "--criteria-file", crit_path,
                              "--design-file", design_path])

        # --- V7494-AC2: the divergent card; the emitted mapping resolves every ordinal.
        code, rows, _err = design_run(extra={"2": [{
            "label": "AC-1", "text": "An entry for an issue the plan does not grade.",
            "maps_to": None}]})
        divergent_rows = rows
        maps = {r[2]: r for r in _rows_of("MAP", rows) if r[1] == "#1" and r[2] != "-"}
        verdict = _rows_of("VERDICT", rows)
        check("V7494-AC2 the headline is BASELINE-DRIFT: the plan declares 5, the issue carries 6",
              code == 1 and verdict and verdict[0][1] == "BASELINE-DRIFT"
              and any(r[1:4] == ["#1", "5", "6"] for r in _rows_of("BASELINE-DRIFT", rows)),
              "exit %s, verdict %s" % (code, verdict))
        bindings = {r[2]: r[3] for r in _rows_of("BINDING", rows) if r[1] == "#1"}
        check("V7494-AC2 every plan ordinal has a BOUND binding row",
              bindings == {"AC-%d" % k: "BOUND" for k in range(1, 6)}, str(bindings))
        targets = ["AC-%d" % k for k in range(1, 7)] + ["none"]
        labels = [label for label, _text, _target in _DESIGN8]
        check("V7494-AC2 every design label has exactly one MAP row, targeting AC-1..AC-6 or none",
              sorted(maps) == sorted(labels)
              and len([r for r in _rows_of("MAP", rows) if r[2] in labels]) == len(labels)
              and all(r[3] in targets for r in maps.values()), str(sorted(maps)))
        check("V7494-AC2 design AC-6 maps to none, and design AC-7 maps to issue AC-6",
              maps.get("AC-6", [None] * 5)[3:5] == ["none", "NONE"]
              and maps.get("AC-7", [None] * 5)[3:5] == ["AC-6", "BOUND"],
              "%s / %s" % (maps.get("AC-6"), maps.get("AC-7")))
        targeted = {r[3] for r in maps.values()}
        unrestated = {r[3] for r in _rows_of("MAP", rows) if r[1] == "#1" and r[4] == "UNRESTATED"}
        check("V7494-AC2 every issue ordinal is a declared target or reported UNRESTATED",
              all(("AC-%d" % k) in targeted | unrestated for k in range(1, 7)),
              "targeted %s, unrestated %s" % (sorted(targeted), sorted(unrestated)))
        check("V7494-AC2 an integration criterion keeps its own label, never a positional AC-8",
              "INT-1" in maps and maps["INT-1"][3] == "none" and "AC-8" not in maps,
              str(sorted(maps)))
        unvisited = {(r[1], r[2]) for r in _rows_of("UNVISITED", rows)}
        check("V7494-AC2 snapshot keys the plan grades no row for are named, not dropped",
              unvisited == {("#2", "design"), ("#3", "issue")}, str(sorted(unvisited)))

        _code, rows, _err = design_run({"AC-6": 2})
        check("V7494-AC2 falsified: a design entry mis-declared onto AC-2 reads UNBOUND on ns:design>issue",
              any(r[1:3] == ["#1", "AC-6"] and r[-1] == "ns:design>issue"
                  for r in _rows_of("UNBOUND", rows)), str(_rows_of("UNBOUND", rows)))
        _code, rows, _err = design_run({"AC-6": 9})
        check("V7494-AC2 falsified: a declared target past the issue list is an ORDINAL-GAP",
              any(r[1:3] == ["#1", "out-of-range"] and r[-1] == "ns:design>issue"
                  for r in _rows_of("ORDINAL-GAP", rows)), str(_rows_of("ORDINAL-GAP", rows)))
        _code, rows, _err = design_run({"AC-6": _UNDECLARED})
        check("V7494-AC2 falsified: a design entry declaring no target is UNDECLARED and an ORDINAL-GAP",
              any(r[1:3] == ["#1", "AC-6"] and r[4] == "UNDECLARED" for r in _rows_of("MAP", rows))
              and any(r[1:3] == ["#1", "undeclared"] for r in _rows_of("ORDINAL-GAP", rows)),
              str(_rows_of("MAP", rows)))
        code, rows, _err = design_run({"AC-7": None}, plan_path=plan6_path)
        verdict = _rows_of("VERDICT", rows)
        check("V7494-AC2 NONE and UNRESTATED are informational: a clean plan still reads BOUND",
              code == 0 and verdict and verdict[0][1] == "BOUND"
              and any(r[3:5] == ["AC-6", "UNRESTATED"] for r in _rows_of("MAP", rows)),
              "exit %s, verdict %s" % (code, verdict))

        # The issue list of a MAP run comes through the binder's own reader.
        design_path = _write(root, "design.json", {"1": _design()})
        real_fetch = globals()["fetch_criteria"]
        globals()["fetch_criteria"] = lambda issues, repo=None: {
            i: criteria_from_body(_FETCHED_BODY) for i in issues if i == "1"}
        try:
            _code, fetched, _err = _run_main([plan5_path, "--fetch", "--design-file", design_path])
        finally:
            globals()["fetch_criteria"] = real_fetch
        _code, snapshot, _err = _run_main([plan5_path, "--criteria-file", crit_path,
                                          "--design-file", design_path])
        check("V7494-AC2 --design-file combines with --fetch: the same MAP rows as the snapshot run",
              _rows_of("MAP", fetched) and _rows_of("MAP", fetched) == _rows_of("MAP", snapshot),
              "fetch %d rows, snapshot %d rows" % (len(_rows_of("MAP", fetched)),
                                                   len(_rows_of("MAP", snapshot))))
        bad_path = _write(root, "bad-design.json", {"1": [{"text": "An entry with no label.",
                                                           "maps_to": 1}]})
        code, _rows, _err = _run_main([plan5_path, "--criteria-file", crit_path,
                                       "--design-file", bad_path])
        check("V7494-AC2 a design entry with no label is an input failure (exit 3), never a mapping",
              code == 3, "exit %s" % code)

    # --- V7494-AC3: every emitted line names the namespace it resolved.
    runs = (
        ("bound", analyse(bound_plan, _CRIT, "self-test")[0], "ns:plan>issue"),
        ("ordinals-only", analyse(bound_plan, {}, "self-test", ordinals_only=True)[0], "ns:plan"),
        ("vacuity", analyse(_plan([]), _CRIT, "self-test")[0], "ns:plan"),
        ("out-of-scope", analyse("## Summary\n\nNo plan.\n", _CRIT, "self-test")[0], "ns:plan"),
        ("withheld", analyse(bound_plan, {}, "self-test")[0], "ns:plan>issue"),
        ("divergent", divergent_rows, "ns:plan>issue,design>issue"),
    )
    for name, rows, want_verdict_ns in runs:
        rows = [[str(c) for c in r] for r in rows]
        check("V7494-AC3 %s run: every line ends in a well-formed ns: field" % name,
              rows and all(_NS_FIELD_RE.match(r[-1]) for r in rows),
              "%d line(s)" % len(rows))
        wrong = [r for r in rows if r[0] != "VERDICT" and r[-1] not in _expected_ns(r)]
        verdict = [r for r in rows if r[0] == "VERDICT"]
        check("V7494-AC3 %s run: each class carries its namespace; VERDICT names %s"
              % (name, want_verdict_ns),
              rows and not wrong and len(verdict) == 1 and verdict[0][-1] == want_verdict_ns,
              "wrong %s, verdict %s" % (wrong[:2], verdict))
    rows = analyse(_plan([_PLAN6_ROWS[0],
                          "| #1 | AC-2 | `grep checksum w.py` | The shard checksum is emitted |\n"]),
                   _CRIT, "self-test")[0]
    check("V7494-AC3 a plan row bound to the wrong criterion is UNBOUND on ns:plan>issue",
          any(r[0] == "UNBOUND" and r[-1] == "ns:plan>issue" for r in rows),
          str([r for r in rows if r[0] == "UNBOUND"]))

    # --- V7494-AC4: the heading vocabulary and the item rule, one fixture each.
    for name, body in _VOCABULARY_ARMS:
        read = criteria_from_body(body)
        _rows, verdict, code = analyse(bound_plan, {"1": read}, "self-test")
        check(name, read == [_W, _D] and (verdict, code) == ("BOUND", 0),
              "read %r → %s/exit %d" % (read, verdict, code))

    # --- V7494-AC5: a heading outside the vocabulary still reports no criteria oracle,
    # and NOT-EVALUATED names which of its two causes withheld the verdict.
    def withheld(criteria, reason):
        rows, verdict, code = analyse(bound_plan, criteria, "self-test")
        details = [str(r[2]) for r in rows if r[0] == "NOT-EVALUATED"]
        return ((verdict, code) == ("NOT-EVALUATED", 1) and len(details) == 1
                and "no criteria oracle" in details[0] and ("(%s)" % reason) in details[0],
                "%s/exit %d %s" % (verdict, code, details))

    cross = "### Cross-Issue Acceptance Criteria\n\n- [ ] %s\n- [ ] %s\n" % (_W, _D)
    ok, detail = withheld({"1": criteria_from_body(cross)}, "no-criteria-section")
    check("V7494-AC5 a `Cross-Issue Acceptance Criteria` heading opens no block: "
          "no criteria oracle (no-criteria-section)", ok, detail)
    _rows, verdict, code = analyse(bound_plan, {"1": criteria_from_body(cross.replace(
        "Cross-Issue ", ""))}, "self-test")
    check("V7494-AC5 the control's twin under `Acceptance Criteria` binds",
          (verdict, code) == ("BOUND", 0), "%s/exit %d" % (verdict, code))
    ok, detail = withheld({"1": criteria_from_body(
        "## Completion condition\n\n- [ ] %s\n- [ ] %s\n" % (_W, _D))}, "no-criteria-section")
    check("V7494-AC5 a bare `Completion condition` heading is outside the vocabulary "
          "(no-criteria-section)", ok, detail)
    ok, detail = withheld({}, "oracle-unavailable")
    check("V7494-AC5 an issue absent from the snapshot: no criteria oracle (oracle-unavailable)",
          ok, detail)

    def fake_run(cmd, capture_output=True, text=True):
        if cmd[3] == "1":
            return subprocess.CompletedProcess(cmd, 0, cross, "")
        return subprocess.CompletedProcess(cmd, 1, "", "could not resolve to an issue")

    real_run = subprocess.run
    subprocess.run = fake_run
    try:
        fetched = fetch_criteria(["1", "2"])
    finally:
        subprocess.run = real_run
    check("V7494-AC5 the live reader keeps a body with no criteria section apart from a "
          "failed fetch", fetched == {"1": []}, repr(fetched))

    return ran, failures


def self_test():
    failures, ran = [], 0

    ns_ran, ns_failures = _namespace_arms()
    ran += ns_ran
    failures += ns_failures

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

    # --ordinals-only is the CI surface, so its own failure modes are pinned here.
    # It must stay SILENT about binding (never a false BOUND on an unread oracle),
    # must still fire on an ordinal gap, and must NOT lose the vacuity guards — an
    # offline mode that reads an empty plan as clean is the false green one level up.
    ordinal_arms = [
        ("ordinals-only — an ordinal gap still fires with no oracle at all",
         _plan(["| #1 | AC-1 | `grep checksum w.py` | Every shard carries a checksum |\n"]),
         "ORDINAL-GAP", 1),
        ("ordinals-only — a clean ordinal set passes without consulting any oracle",
         _plan(["| #1 | AC-1 | `grep checksum w.py` | Every shard carries a checksum |\n",
                "| #1 | AC-2 | `grep journal d.py` | The journal rotates at midnight |\n"]),
         "BOUND", 0),
        ("ordinals-only — the vacuity guards still hold",
         _plan([]), "UNPARSEABLE", 3),
    ]
    for name, plan, want_verdict, want_exit in ordinal_arms:
        rows, verdict, code = analyse(plan, {}, "self-test", ordinals_only=True)
        ran += 1
        if verdict != want_verdict or code != want_exit:
            failures.append("%s: expected %s/exit %d, got %s/exit %d"
                            % (name, want_verdict, want_exit, verdict, code))
        if any(r[0] in ("BINDING", "UNBOUND", "NOT-EVALUATED", "BASELINE-DRIFT")
               for r in rows):
            failures.append("%s: emitted a binding-limb row with no oracle read" % name)

    # The term relation, pinned in both directions against measured cases. `cite`/
    # `cited` is the fold's short-stem failure that subsumption exists to rescue;
    # `carri`/`carrier` is the morpheme-boundary crossing that produced a real false
    # BOUND on a live plan before the length bound was added.
    for a, b, want, why in (
        ("cite", "cited", True, "the fold's short-stem failure must still match"),
        ("link", "links", True, "an ordinary inflection must match"),
        ("carri", "carrier", False, "subsumption must not cross a morpheme boundary"),
        ("core", "corpus", False, "unrelated terms sharing three letters must not match"),
        ("cor", "core", False, "a stem below the length floor cannot subsume"),
        ("state", "statement", False, "a two-character delta is beyond the bound"),
    ):
        ran += 1
        if related(a, b) != want or related(b, a) != want:
            failures.append("relation: related(%r, %r) must be %s — %s"
                            % (a, b, want, why))

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
                        help="JSON {issue: [criterion, ...]} — the determinism seam; "
                             "an issue mapped to [] reads as a body with no criteria "
                             "section")
    parser.add_argument("--fetch", action="store_true",
                        help="read criteria live with `gh issue view` instead")
    parser.add_argument("--design-file",
                        help="JSON {issue: [{label, text, maps_to}, ...]} — a Stage-5 "
                             "design's declared mapping onto the issue list, checked by "
                             "the design limb (MAP); combines with --fetch or "
                             "--criteria-file, which supply that issue list")
    parser.add_argument("--ordinals-only", action="store_true",
                        help="run the plan-local ordinal limb alone (offline, "
                             "deterministic — the CI surface)")
    parser.add_argument("--repo", default=None,
                        help="OWNER/REPO for --fetch; omit to let `gh` resolve it "
                             "from the checkout's own remote (the default — no "
                             "repository slug is hardcoded in this file)")
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

    design = None
    if args.design_file:
        try:
            design = load_design_file(args.design_file)
        except (OSError, ValueError) as exc:
            sys.stderr.write("error: --design-file %s: %s\n" % (args.design_file, exc))
            return 3

    criteria = {}
    if args.criteria_file:
        criteria = load_criteria_file(args.criteria_file)
    elif args.fetch:
        _rows, baseline, _read_at, _seen = parse_plan(text)
        criteria = fetch_criteria(sorted(baseline, key=int), args.repo)

    rows, _verdict, code = analyse(text, criteria, os.path.basename(args.plan),
                                   ordinals_only=args.ordinals_only, design_map=design)
    emit(rows, sys.stdout)
    return code


if __name__ == "__main__":
    sys.exit(main())
