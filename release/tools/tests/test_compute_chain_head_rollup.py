#!/usr/bin/env python3
"""Regression suite for compute-chain-head-rollup.py (the chain-head view).

Offline and deterministic: every arm runs the tool's pure derive() and its
renderers over committed inline snapshots, with the fetch layer replaced. No host
read, no network, no file written outside a temporary directory the AC1 arm
creates and the context manager removes. Issue numbers, repositories and label
names below are synthetic.

Each arm names the acceptance criterion it grades and, where a passing arm could
pass vacuously, carries a control that must come out the other way:

  AC1   the tool writes no file and reads no cache (a write-mode open is refused
        during a run; the run directory stays empty; a source scan with a specimen)
  AC2   a new initiative label becomes a head with no registry edit (and the tool's
        source names no initiative label)
  AC3   a standing head renders without a completion percentage; a finite head
        renders one; no standing initiative stops the run (exit 1, named); three
        drill levels render — head, epic, open child — in the JSON and the Markdown
  AC4   substituting a naive number scrape changes the fixture's edges; the tool's
        source carries no naive number-scrape pattern (with a specimen)
  AC5   an unserved parent field renders unmeasured, not 0; a measured zero renders
        0; a missing parent key counts as unparented (the host omits the key when
        an issue has no parent); a host serving neither the parent field nor the
        sub-issue summary renders unmeasured (control: the summary served at zero
        reads measured)
  INT-1 the view's edges equal parse_dependencies' targets, body by body
  INT-2 a dependency parse that is not clean renders unmeasured edges and stays out
        of the blocked count
  CD-1  a member with no Dependencies section and open native blockers renders
        unmeasured, never "not blocked"
  CIAC-4 the view loads the single-sourced grammar
  EVG   flow-container absorption: strict majority, tie, empty, unmeasured
  PART  the partition invariant holds, and a broken sum is refused
  ENC   untrusted text cannot break a table row or inject HTML
  ORD   the output declares that its order is not a sequence
  G1A   the view and the epic rollup-close audit share one child-set rule

Run:  python3 release/tools/tests/test_compute_chain_head_rollup.py
Exit: 0 = all arms pass (TEST OK), 1 = one or more failed (TEST FAIL).
"""

import ast
import builtins
import importlib.util
import io
import json
import os
import re
import sys
import tempfile
from contextlib import redirect_stderr, redirect_stdout
from typing import Dict, List

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)
TOOL_PATH = os.path.join(TOOLS, "compute-chain-head-rollup.py")
PARSER_PATH = os.path.join(TOOLS, "bundle-issues-parser.py")
RULE_PATH = os.path.join(TOOLS, "_epic_child_set.py")
AUDIT_PATH = os.path.join(TOOLS, "audit-epic-rollup-close.sh")

LABEL_AC1 = "AC1 tool writes no file and reads no cache"
LABEL_AC2 = "AC2 new project label becomes a head with no registry edit"
LABEL_AC3 = "AC3 standing head renders without a completion percentage"
LABEL_AC3_CONTROL = "AC3 control finite head renders a percentage"
LABEL_AC3_GUARD = "AC3 no standing initiative fails loudly"
LABEL_AC3_DRILL = "AC3 three drill levels render head to epic to child"
LABEL_AC4 = "AC4 naive number scrape substitution changes the fixture edges"
LABEL_AC4_SCAN = "AC4 source carries no naive number-scrape pattern"
LABEL_AC5 = "AC5 unreadable parent field renders unmeasured not zero"
LABEL_AC5_CONTROL = "AC5 control measured zero renders 0"
LABEL_AC5_KEYLESS = "AC5 missing parent key counts as unparented"
LABEL_AC5_UNSERVED = "AC5 neither parent field nor sub-issue summary served renders unmeasured"
LABEL_AC5_UNSERVED_CONTROL = "AC5 control summary served at zero renders measured"
LABEL_INT1 = "INT-1 view edges equal parse_dependencies targets"
LABEL_INT2 = "INT-2 non-clean dependency parse renders unmeasured edges"
LABEL_CD1 = "CD-1 no Dependencies section with open native blockers renders unmeasured"
LABEL_CIAC4 = "CIAC-4 view loads the single-sourced grammar"
LABEL_EVG_MAJ = "EVG strict majority absorbs a flow container"
LABEL_EVG_TIE = "EVG tie stays a lone-epic head"
LABEL_EVG_EMPTY = "EVG empty child set stays a head with undefined rollup"
LABEL_EVG_UNM = "EVG unmeasured child set is never absorbed"
LABEL_PART = "PART partition invariant holds"
LABEL_ENC = "ENC untrusted title cannot break the table or inject HTML"
LABEL_ORD = "ORD output declares ordering is not a sequence"
LABEL_G1A = "G1A view and audit share one child-set rule"

DEFERRAL = "[ASSUMPTION – CONFIRM] TBD — identified in Planning"
# The naive scrape the governed grammar replaced: every issue number in the section.
NAIVE_SCRAPE_RE = re.compile(r"#(\d+)")
# The shape of a naive scrape written as a regular-expression literal in source.
NAIVE_SHAPE_RE = re.compile(r"#\s*\(?\s*(?:\\d|\[0-9\])")


def _load(name: str, path: str):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


TOOL = _load("compute_chain_head_rollup", TOOL_PATH)
BIP = _load("bundle_issues_parser_for_suite", PARSER_PATH)
GRAMMAR = TOOL.load_grammar()
RULE = TOOL.load_child_rule()
P = TOOL.PROJECT_PREFIX


# ---- Fixture builders ------------------------------------------------------------

def issue(n: int, labels: List[str], body: str = "", parent=None, keyless: bool = False,
          native: int = 0, subs: int = 0, title: str = "") -> Dict:
    """A REST issue row in the host's live shape: no parent -> the key is absent."""
    row = {"number": n, "title": title or "issue %d" % n, "labels": [{"name": x} for x in labels],
           "body": body, "milestone": {"number": 7, "title": "ms seven", "state": "open"},
           "state": "open", "state_reason": None,
           "issue_dependencies_summary": {"blocked_by": native, "total_blocked_by": native},
           "sub_issues_summary": {"total": subs, "completed": 0, "percent_completed": 0}}
    if parent is not None:
        row["parent_issue_url"] = "https://api.example/repos/o/r/issues/%d" % parent
    elif not keyless:
        pass  # the host omits the key for an issue with no parent; keyless is the default
    return row


def kid(n: int, state: str, labels: List[str], reason=None) -> Dict:
    return {"number": n, "title": "child %d" % n, "state": state, "state_reason": reason, "labels": labels}


def snapshot(labels: List[Dict], issues: List[Dict], child_reads: Dict) -> Dict:
    return {"repo": "o/r", "commit_anchor": "abc1234", "generated_at": "2026-01-01T00:00:00Z",
            "labels": labels, "issues": issues, "search_total": len(issues),
            "child_reads": child_reads, "reads": []}


def base_snapshot() -> Dict:
    """One finite initiative with an epic, one standing initiative with an absorbed container."""
    alpha, flow = P + "alpha", P + "flow"
    return snapshot(
        [{"name": alpha, "description": "Finite work toward a capability"},
         {"name": flow, "description": "Standing quality flow"}],
        [issue(10, ["type:epic", alpha], parent=None, subs=3),
         issue(11, [alpha], body="### Dependencies\nBlocked by: #12\n", parent=10),
         issue(12, [alpha], parent=10),
         issue(20, ["type:epic"], subs=3),
         issue(21, [flow], parent=20),
         issue(22, [flow])],
        {10: {"status": "ok", "native": [kid(11, "open", [alpha]), kid(12, "open", [alpha]),
                                         kid(13, "closed", [alpha], "completed"),
                                         kid(14, "closed", [alpha], "not_planned")], "label": []},
         20: {"status": "ok", "native": [kid(21, "open", [flow]), kid(23, "closed", [flow], "completed"),
                                         kid(24, "closed", [], "completed")], "label": []}})


def heads_of(rollup: Dict) -> Dict[str, Dict]:
    return {h["id"]: h for h in rollup["heads"]}


def row_for(markdown: str, head_id: str) -> str:
    for line in markdown.splitlines():
        if line.startswith("| %s |" % head_id):
            return line
    return ""


def drill_block(markdown: str, head_id: str, epic: int) -> List[str]:
    """The lines of one epic's <details> block inside one head's section, or []."""
    lines = markdown.splitlines()
    if "## %s" % head_id not in lines:
        return []
    start = lines.index("## %s" % head_id) + 1
    end = next((i for i in range(start, len(lines)) if lines[i].startswith("## ")), len(lines))
    opener = "<details><summary>#%d " % epic
    for i in range(start, end):
        if lines[i].startswith(opener):
            close = next((j for j in range(i, end) if lines[j] == "</details>"), end)
            return lines[i:close + 1]
    return []


def run_main(argv: List[str], snap: Dict):
    """Run the CLI with the fetch layer replaced by a fixed snapshot."""
    saved = TOOL.fetch_snapshot, TOOL.resolve_repo
    TOOL.fetch_snapshot = lambda repo, limit: snap
    TOOL.resolve_repo = lambda explicit: "o/r"
    out, err = io.StringIO(), io.StringIO()
    try:
        with redirect_stdout(out), redirect_stderr(err):
            rc = TOOL.main(argv)
    finally:
        TOOL.fetch_snapshot, TOOL.resolve_repo = saved
    return rc, out.getvalue(), err.getvalue()


def source(path: str) -> str:
    with open(path, encoding="utf-8") as fh:
        return fh.read()


# ---- Arms ---------------------------------------------------------------------------

def arm_ac1(fail) -> None:
    real_open = builtins.open
    writes: List[str] = []

    def guarded_open(file, mode="r", *a, **kw):
        if any(ch in str(mode) for ch in "wax+"):
            writes.append("%s (%s)" % (file, mode))
            raise PermissionError("write refused by the AC1 arm")
        return real_open(file, mode, *a, **kw)

    cwd = os.getcwd()
    with tempfile.TemporaryDirectory() as tmp:
        os.chdir(tmp)
        builtins.open = guarded_open
        try:
            rc_md, out_md, _ = run_main([], base_snapshot())
            rc_js, out_js, _ = run_main(["--json"], base_snapshot())
        finally:
            builtins.open = real_open
            os.chdir(cwd)
        left = os.listdir(tmp)
    if rc_md != 0 or rc_js != 0 or not out_md or not out_js:
        fail(LABEL_AC1, "a run did not render (rc %s / %s)" % (rc_md, rc_js))
    if writes:
        fail(LABEL_AC1, "write-mode opens during a run: %s" % writes)
    if left:
        fail(LABEL_AC1, "the run left files behind: %s" % left)
    # Structural: no writing or caching primitive in the tool's source; the specimen bites.
    write_re = re.compile(r"open\([^)]*['\"][wax]|\.write_(?:text|bytes)\(|\b(?:tempfile|shelve|pickle)\b")
    hits = [ln for ln in source(TOOL_PATH).splitlines() if write_re.search(ln)]
    if hits:
        fail(LABEL_AC1, "the tool source carries a write or cache primitive: %s" % hits[:3])
    if not write_re.search("with open(path, 'w') as fh: pickle.dump(x, fh)"):
        fail(LABEL_AC1, "the structural scan does not bite on its specimen")


def arm_ac2(fail) -> None:
    snap = base_snapshot()
    before = set(heads_of(TOOL.derive(snap, GRAMMAR, RULE)))
    new = P + "new-thing"
    snap["labels"].append({"name": new, "description": "A brand-new finite initiative"})
    after_empty = TOOL.derive(snap, GRAMMAR, RULE)
    snap["issues"].append(issue(30, [new]))
    after = set(heads_of(TOOL.derive(snap, GRAMMAR, RULE)))
    if new in before or new not in after or after - before != {new}:
        fail(LABEL_AC2, "a labelled member did not create exactly one new head (%s -> %s)" % (before, after))
    if new in heads_of(after_empty) or new not in after_empty["meta"]["empty_initiative_labels"]:
        fail(LABEL_AC2, "control: a label with no open issue must be listed empty, not drawn")
    # The tool names no initiative label in its source: no registry to edit.
    named = re.compile(r"['\"]project:[a-z0-9]")
    if named.search(source(TOOL_PATH)):
        fail(LABEL_AC2, "the tool source names a project: label")
    if not named.search("REG = ['project:pipeline']"):
        fail(LABEL_AC2, "the source scan does not bite on its specimen")


def arm_ac3(fail) -> None:
    rollup = TOOL.derive(base_snapshot(), GRAMMAR, RULE)
    h = heads_of(rollup)
    md = TOOL.render_markdown(rollup)
    flow, alpha = P + "flow", P + "alpha"
    sp = h[flow]["progress"]
    if sp["status"] != "not-applicable" or "percent" in sp:
        fail(LABEL_AC3, "the standing head carries a percentage: %s" % sp)
    if "%" in row_for(md, flow) or not row_for(md, flow):
        fail(LABEL_AC3, "the standing head's Markdown row shows a percentage: %r" % row_for(md, flow))
    fp = h[alpha]["progress"]
    if fp.get("percent") != 25 or "%" not in row_for(md, alpha):
        fail(LABEL_AC3_CONTROL, "the finite head lacks its percentage: %s / %r" % (fp, row_for(md, alpha)))
    # Three drill levels: the head, its epic #10, and the epic's open children 11 and 12.
    node = next((n for n in h[alpha]["nodes"] if n["number"] == 10), None)
    kids = [c["number"] for c in node["children"]] if node else []
    if not node or node["role"] != "epic" or kids != [11, 12]:
        fail(LABEL_AC3_DRILL, "the JSON does not carry head -> epic #10 -> children 11, 12: %s" % kids)
    block = drill_block(md, alpha, 10)
    for child in (11, 12):
        if not any(ln.startswith("| #%d |" % child) for ln in block):
            fail(LABEL_AC3_DRILL, "the Markdown has no #%d row inside epic #10's block under %s: %r"
                 % (child, alpha, block[:3]))
    if drill_block(md, flow, 10):
        fail(LABEL_AC3_DRILL, "control: epic #10's block was found under the standing head")
    # The guard: drop the word and the run stops, naming why; the control keeps it.
    snap = base_snapshot()
    snap["labels"][1]["description"] = "Quality flow, never closes"
    rc, out, err = run_main(["--json"], snap)
    if rc != 1 or "standing" not in err or out:
        fail(LABEL_AC3_GUARD, "no standing initiative did not stop the run (rc %s, err %r)" % (rc, err[:120]))
    rc_ok, _, _ = run_main(["--json"], base_snapshot())
    if rc_ok != 0:
        fail(LABEL_AC3_GUARD, "control: with a standing initiative the run must succeed (rc %s)" % rc_ok)


AC4_BODY = ("### Dependencies\n"
            "Blocked by: #4\n"
            "Relates to #5\n"
            "Blocks #6\n"
            "Discussed alongside the earlier proposal in #7.\n")


class NaiveGrammar(TOOL.Grammar):
    def __init__(self):
        super().__init__("naive", self._naive, GRAMMAR.extract_section_aliased, GRAMMAR.heading_aliases)

    @staticmethod
    def _naive(body):
        section = GRAMMAR.extract_section_aliased(body, GRAMMAR.heading_aliases)
        if section is None:
            return set(), "clean"
        return {int(x) for x in NAIVE_SCRAPE_RE.findall(section)}, "clean"


def _member_edges(rollup: Dict, head_id: str, number: int):
    for h in rollup["heads"]:
        if h["id"] != head_id:
            continue
        for n in h["nodes"]:
            for c in n["children"]:
                if c["number"] == number:
                    return c["edges"]
    return None


def ac4_snapshot() -> Dict:
    alpha, flow = P + "alpha", P + "flow"
    return snapshot(
        [{"name": alpha, "description": "Finite"}, {"name": flow, "description": "Standing flow"}],
        [issue(10, ["type:epic", alpha], subs=1), issue(11, [alpha], body=AC4_BODY, parent=10),
         issue(4, [alpha]), issue(5, [alpha]), issue(6, [alpha]), issue(7, [alpha]), issue(40, [flow])],
        {10: {"status": "ok", "native": [kid(11, "open", [alpha])], "label": []}})


def arm_ac4(fail) -> None:
    gov = _member_edges(TOOL.derive(ac4_snapshot(), GRAMMAR, RULE), P + "alpha", 11)
    naive = _member_edges(TOOL.derive(ac4_snapshot(), NaiveGrammar(), RULE), P + "alpha", 11)
    g = sorted(t["number"] for t in gov["blocked_by"]) if gov else None
    nv = sorted(t["number"] for t in naive["blocked_by"]) if naive else None
    if g != [4]:
        fail(LABEL_AC4, "the governed edges are not {4}: %s" % g)
    if not nv or len(nv) < 4 or nv == g:
        fail(LABEL_AC4, "the naive substitution did not change the edges: %s" % nv)
    for path in (TOOL_PATH, RULE_PATH):
        hits = [ln.strip() for ln in source(path).splitlines() if NAIVE_SHAPE_RE.search(ln)]
        if hits:
            fail(LABEL_AC4_SCAN, "%s carries a naive scrape pattern: %s" % (os.path.basename(path), hits[:2]))
    if not NAIVE_SHAPE_RE.search('NAIVE = re.compile(r"#(\\d+)")') or not NAIVE_SHAPE_RE.search("x = '#[0-9]+'"):
        fail(LABEL_AC4_SCAN, "the scan does not bite on its specimens")


def arm_ac5(fail) -> None:
    alpha, flow = P + "alpha", P + "flow"
    # No row carries the parent key while an epic reports sub-issues: not served.
    snap = snapshot(
        [{"name": alpha, "description": "Finite"}, {"name": flow, "description": "Standing flow"}],
        [issue(10, ["type:epic", alpha], subs=2), issue(11, [alpha]), issue(12, [alpha]), issue(40, [flow])],
        {10: {"status": "ok", "native": [kid(11, "open", [alpha]), kid(12, "open", [alpha])], "label": []}})
    rollup = TOOL.derive(snap, GRAMMAR, RULE)
    h = heads_of(rollup)[alpha]
    md = TOOL.render_markdown(rollup)
    cells = [c.strip() for c in row_for(md, alpha).split("|")]
    if h["unparented"]["status"] != "unmeasured" or h["unparented"]["count"] is not None:
        fail(LABEL_AC5, "an unserved parent field did not read unmeasured: %s" % h["unparented"])
    if h["partition"]["status"] != "unmeasured":
        fail(LABEL_AC5, "the partition did not read unmeasured: %s" % h["partition"])
    if len(cells) < 6 or cells[5] != "unmeasured":
        fail(LABEL_AC5, "the Markdown unparented cell is not 'unmeasured': %r" % cells)
    # Control: every member parented under the head's epic -> a measured 0, rendered 0.
    snap2 = snapshot(
        [{"name": alpha, "description": "Finite"}, {"name": flow, "description": "Standing flow"}],
        [issue(10, ["type:epic", alpha], subs=2), issue(11, [alpha], parent=10), issue(12, [alpha], parent=10),
         issue(40, [flow], parent=10)],
        {10: {"status": "ok", "native": [kid(11, "open", [alpha]), kid(12, "open", [alpha])], "label": []}})
    r2 = TOOL.derive(snap2, GRAMMAR, RULE)
    cells2 = [c.strip() for c in row_for(TOOL.render_markdown(r2), alpha).split("|")]
    if heads_of(r2)[alpha]["unparented"] != {"status": "measured", "count": 0, "issues": [], "reason": None} \
            or len(cells2) < 6 or cells2[5] != "0":
        fail(LABEL_AC5_CONTROL, "a measured zero did not render 0: %s / %r" % (heads_of(r2)[alpha]["unparented"], cells2))
    # FM-1: the key is absent for a member with no parent while others carry it.
    r3 = TOOL.derive(base_snapshot(), GRAMMAR, RULE)
    up = heads_of(r3)[flow]["unparented"]
    if up != {"status": "measured", "count": 1, "issues": [22], "reason": None}:
        fail(LABEL_AC5_KEYLESS, "a keyless member is not counted unparented: %s" % up)
    if "unparented" not in json.dumps(r3["heads"][0]):
        fail(LABEL_AC5_KEYLESS, "the machine output carries no per-head unparented facet")
    # Neither the parent field nor the sub-issue summary served, while the epic's own
    # sub-issue read lists 11 and 12: unmeasured, not a count those reads contradict.
    labels = [{"name": alpha, "description": "Finite"}, {"name": flow, "description": "Standing flow"}]
    rows = [issue(10, ["type:epic", alpha], subs=2), issue(11, [alpha]), issue(12, [alpha]), issue(40, [flow])]
    for row in rows:
        row.pop("sub_issues_summary", None)
    r4 = TOOL.derive(snapshot(labels, rows, {10: {"status": "ok", "label": [],
                                                  "native": [kid(11, "open", [alpha]), kid(12, "open", [alpha])]}}),
                     GRAMMAR, RULE)
    h4 = heads_of(r4)[alpha]
    cells4 = [c.strip() for c in row_for(TOOL.render_markdown(r4), alpha).split("|")]
    if h4["unparented"]["status"] != "unmeasured" or h4["unparented"]["count"] is not None \
            or h4["partition"]["status"] != "unmeasured" or len(cells4) < 6 or cells4[5] != "unmeasured":
        fail(LABEL_AC5_UNSERVED, "neither field served did not read unmeasured: %s / %s / %r"
             % (h4["unparented"], h4["partition"], cells4))
    if "sub-issue summary" not in (r4["meta"]["parent_field"]["reason"] or ""):
        fail(LABEL_AC5_UNSERVED, "the reason does not name the unserved summary: %s" % r4["meta"]["parent_field"])
    # Control: the summary served at zero everywhere and no native child — every member
    # is genuinely unparented, so the count is measured.
    rows5 = [issue(10, ["type:epic", alpha]), issue(11, [alpha]), issue(12, [alpha]), issue(40, [flow])]
    r5 = TOOL.derive(snapshot(labels, rows5, {10: {"status": "ok", "native": [], "label": []}}), GRAMMAR, RULE)
    up5 = heads_of(r5)[alpha]["unparented"]
    if up5 != {"status": "measured", "count": 2, "issues": [11, 12], "reason": None}:
        fail(LABEL_AC5_UNSERVED_CONTROL, "a served zero summary did not read measured: %s" % up5)


def arm_int1(fail) -> None:
    bodies = [AC4_BODY, "### Dependencies\nBlocked by: #3, #9\nBlocks: #8\n",
              "### Depends on\n- #6\n- #2\n", "### Notes\nNo dependency section.\n",
              "### Dependencies\nGated on, not blocked by #5.\nBlocked by: #1\n", ""]
    alpha, flow = P + "alpha", P + "flow"
    rows = [issue(10, ["type:epic", alpha], subs=len(bodies)), issue(40, [flow])]
    rows += [issue(100 + i, [alpha], body=b, parent=10) for i, b in enumerate(bodies)]
    snap = snapshot([{"name": alpha, "description": "Finite"}, {"name": flow, "description": "Standing"}], rows,
                    {10: {"status": "ok", "native": [kid(100 + i, "open", [alpha]) for i in range(len(bodies))],
                          "label": []}})
    rollup = TOOL.derive(snap, GRAMMAR, RULE)
    checked = 0
    for i, body in enumerate(bodies):
        edges = _member_edges(rollup, alpha, 100 + i)
        want, _status = BIP.parse_dependencies(body)
        got = {t["number"] for t in edges["blocked_by"]}
        checked += 1
        if got != set(want):
            fail(LABEL_INT1, "body %d: view %s != parse_dependencies %s" % (i, sorted(got), sorted(want)))
    if checked != len(bodies) or not any(BIP.parse_dependencies(b)[0] for b in bodies):
        fail(LABEL_INT1, "vacuous: no fixture body carries a governed edge")


def arm_int2(fail) -> None:
    alpha, flow = P + "alpha", P + "flow"
    deferred = "### Dependencies\n%s\n" % DEFERRAL
    snap = snapshot(
        [{"name": alpha, "description": "Finite"}, {"name": flow, "description": "Standing"}],
        [issue(10, ["type:epic", alpha], subs=2), issue(11, [alpha], body=deferred, parent=10),
         issue(12, [alpha], body="### Dependencies\nBlocked by: #13\n", parent=10), issue(13, [alpha]),
         issue(40, [flow])],
        {10: {"status": "ok", "native": [kid(11, "open", [alpha]), kid(12, "open", [alpha])], "label": []}})
    if BIP.parse_dependencies(deferred)[1] == "clean":
        fail(LABEL_INT2, "vacuous: the fixture's parse is clean")
    rollup = TOOL.derive(snap, GRAMMAR, RULE)
    edges = _member_edges(rollup, alpha, 11)
    if edges["status"] != "unmeasured":
        fail(LABEL_INT2, "a deferred parse rendered measured edges: %s" % edges)
    blocked = heads_of(rollup)[alpha]["blocked"]
    if blocked != {"count": 1, "unmeasured": 1}:
        fail(LABEL_INT2, "the deferred member is not held out of the blocked count: %s" % blocked)
    if "not blocked" in TOOL._edges_text(edges):
        fail(LABEL_INT2, "a deferred parse rendered as 'not blocked'")


def arm_cd1(fail) -> None:
    alpha, flow = P + "alpha", P + "flow"
    snap = snapshot(
        [{"name": alpha, "description": "Finite"}, {"name": flow, "description": "Standing"}],
        [issue(10, ["type:epic", alpha], subs=2), issue(11, [alpha], body="### Notes\nnone\n", parent=10, native=2),
         issue(12, [alpha], body="### Notes\nnone\n", parent=10, native=0), issue(40, [flow])],
        {10: {"status": "ok", "native": [kid(11, "open", [alpha]), kid(12, "open", [alpha])], "label": []}})
    rollup = TOOL.derive(snap, GRAMMAR, RULE)
    e11, e12 = _member_edges(rollup, alpha, 11), _member_edges(rollup, alpha, 12)
    if e11["status"] != "unmeasured" or e11["section"] != "absent" or "Dependencies" not in (e11["reason"] or ""):
        fail(LABEL_CD1, "absent section with native blockers is not unmeasured: %s" % e11)
    if e12["status"] != "measured" or e12["native_blocked_by_open"] != 0 or e12["blocked_by"]:
        fail(LABEL_CD1, "control: absent section with no native blocker must read measured: %s" % e12)


def arm_ciac4(fail) -> None:
    pd = GRAMMAR.parse_dependencies
    if pd.__module__ != "bundle_issues_parser" or os.path.realpath(pd.__code__.co_filename) != os.path.realpath(PARSER_PATH):
        fail(LABEL_CIAC4, "the view's parse_dependencies is not the parser's (%s, %s)"
             % (pd.__module__, pd.__code__.co_filename))
    grammar_names = {"parse_dependencies", "parse_body_dependencies", "unattributed_refs", "_attribute_segments",
                     "_segments_for_body", "extract_section", "DEP_TOKEN_RE", "SEGMENT_LABELS"}

    def defined(src: str) -> set:
        names = set()
        for node in ast.parse(src).body:
            if isinstance(node, (ast.FunctionDef, ast.ClassDef)):
                names.add(node.name)
            elif isinstance(node, ast.Assign):
                names |= {t.id for t in node.targets if isinstance(t, ast.Name)}
        return names

    own = defined(source(TOOL_PATH)) & grammar_names
    if own:
        fail(LABEL_CIAC4, "the view defines grammar names of its own: %s" % sorted(own))
    if not defined("def parse_dependencies(b):\n    return set(), 'clean'\n") & grammar_names:
        fail(LABEL_CIAC4, "the structural scan does not bite on its specimen")
    if TOOL.load_grammar().source != "release/tools/bundle-issues-parser.py":
        fail(LABEL_CIAC4, "the grammar source is not the parser: %s" % TOOL.load_grammar().source)


def evg_snapshot(children: List[Dict], status: str = "ok", second_standing: bool = False) -> Dict:
    alpha, flow, flow2 = P + "alpha", P + "flow", P + "flow-two"
    labels = [{"name": alpha, "description": "Finite"}, {"name": flow, "description": "Standing flow"}]
    if second_standing:
        labels.append({"name": flow2, "description": "Standing second flow"})
    return snapshot(labels, [issue(50, ["type:epic"], subs=len(children)), issue(40, [flow], parent=50),
                             issue(41, [alpha])],
                    {50: {"status": status, "native": children, "label": []}})


def _placement(rollup: Dict):
    lone = [h["id"] for h in rollup["heads"] if h["kind"] == "lone-epic"]
    absorbed = [(h["id"], n["number"]) for h in rollup["heads"] for n in h["nodes"] if n["role"] == "flow-container"]
    return lone, absorbed


def arm_evg(fail) -> None:
    flow = P + "flow"
    lone, absorbed = _placement(TOOL.derive(evg_snapshot(
        [kid(40, "open", [flow]), kid(51, "closed", [flow], "completed"), kid(52, "closed", [], "completed")]),
        GRAMMAR, RULE))
    if absorbed != [(flow, 50)] or lone:
        fail(LABEL_EVG_MAJ, "a 2-of-3 standing share was not absorbed: lone %s absorbed %s" % (lone, absorbed))
    lone, absorbed = _placement(TOOL.derive(evg_snapshot(
        [kid(40, "open", [flow]), kid(52, "closed", [], "completed")]), GRAMMAR, RULE))
    if lone != ["#50"] or absorbed:
        fail(LABEL_EVG_MAJ, "control: a 1-of-2 share (not a strict majority) was absorbed")
    both = [flow, P + "flow-two"]
    lone, absorbed = _placement(TOOL.derive(evg_snapshot(
        [kid(40, "open", both), kid(51, "closed", both, "completed")], second_standing=True), GRAMMAR, RULE))
    if lone != ["#50"] or absorbed:
        fail(LABEL_EVG_TIE, "a tie between two standing labels was absorbed: %s" % absorbed)
    rollup = TOOL.derive(evg_snapshot([]), GRAMMAR, RULE)
    lone, absorbed = _placement(rollup)
    head = heads_of(rollup).get("#50")
    if lone != ["#50"] or absorbed or not head or head["progress"]["status"] != "undefined":
        fail(LABEL_EVG_EMPTY, "an empty child set did not stay a head with undefined progress")
    rollup = TOOL.derive(evg_snapshot([kid(40, "open", [flow])], status="failed"), GRAMMAR, RULE)
    lone, absorbed = _placement(rollup)
    head = heads_of(rollup).get("#50")
    if lone != ["#50"] or absorbed or not head or head["absorption"]["status"] != "unmeasured" \
            or head["progress"]["status"] != "unmeasured":
        fail(LABEL_EVG_UNM, "an unmeasured child set was absorbed or read as measured")


def arm_part(fail) -> None:
    rollup = TOOL.derive(base_snapshot(), GRAMMAR, RULE)
    seen = 0
    for h in rollup["heads"]:
        p, up = h["partition"], h["unparented"]
        if p["status"] != "measured":
            continue
        seen += 1
        if p["in_tree"] + p["parented_outside"] + up["count"] != h["members_open"]:
            fail(LABEL_PART, "%s does not sum: %s %s %s" % (h["id"], p, up["count"], h["members_open"]))
    if seen == 0:
        fail(LABEL_PART, "vacuous: no measured partition")
    try:
        TOOL.check_partition("x", 1, 1, 1, 4)
        fail(LABEL_PART, "a broken sum was not refused")
    except TOOL.PartitionError:
        pass


def arm_enc(fail) -> None:
    hostile = "a | b <script>alert(1)</script> [x](http://e) `c`\r\nnext"
    snap = base_snapshot()
    snap["issues"][2]["title"] = hostile
    snap["labels"][0]["description"] = hostile
    md = TOOL.render_markdown(TOOL.derive(snap, GRAMMAR, RULE))
    if "<script>" in md or "](http" in md or "`c`" in md:
        fail(LABEL_ENC, "raw markup survived encoding")
    rows = [ln for ln in md.splitlines() if ln.startswith("| #12 |")]
    if len(rows) != 1 or len(re.split(r"(?<!\\)\|", rows[0])) != 6:
        fail(LABEL_ENC, "the hostile title broke its table row: %r" % rows)
    if TOOL.md_cell("x|y") != "x\\|y" or "\n" in TOOL.md_cell("a\nb"):
        fail(LABEL_ENC, "md_cell does not escape the pipe or fold a newline")


def arm_ord(fail) -> None:
    rollup = TOOL.derive(base_snapshot(), GRAMMAR, RULE)
    if rollup["meta"]["ordering"]["is_sequence"] is not False:
        fail(LABEL_ORD, "meta.ordering.is_sequence is not false")
    if "not a sequence" not in TOOL.render_markdown(rollup):
        fail(LABEL_ORD, "the Markdown does not say its order is not a sequence")


def arm_g1a(fail) -> None:
    if os.path.realpath(RULE.child_set.__code__.co_filename) != os.path.realpath(RULE_PATH):
        fail(LABEL_G1A, "the view's child-set rule is not _epic_child_set.py")
    audit = source(AUDIT_PATH)
    if "_epic_child_set.py" not in audit or "rule.child_set(" not in audit:
        fail(LABEL_G1A, "the audit does not load the shared rule")
    if "if m == n or m in native" in audit:
        fail(LABEL_G1A, "the audit still carries its inline union")
    # The audit's fixtures 6 and 7, replayed through the view's own derive.
    alpha, flow = P + "alpha", P + "flow"
    snap = snapshot(
        [{"name": alpha, "description": "Finite"}, {"name": flow, "description": "Standing"}],
        [issue(6, ["type:epic", alpha, "epic:thing"], subs=1), issue(7, ["type:epic", alpha, "epic:other"], subs=1),
         issue(72, [alpha, "epic:other"]), issue(40, [flow])],
        {6: {"status": "ok", "native": [kid(61, "closed", ["epic:thing"], "completed")],
             "label": [kid(6, "open", ["type:epic", "epic:thing"]), kid(61, "closed", ["epic:thing"], "completed")]},
         7: {"status": "ok", "native": [kid(71, "closed", [], "completed")], "label": [kid(72, "open", ["epic:other"])]}})
    calls: List[int] = []

    class CountingRule:
        """The shared rule, wrapped so the arm sees the view actually call it."""
        @staticmethod
        def child_set(epic, native, label):
            calls.append(epic)
            return RULE.child_set(epic, native, label)
        union = staticmethod(RULE.union)

    nodes = {n["number"]: n for n in heads_of(TOOL.derive(snap, GRAMMAR, CountingRule))[alpha]["nodes"]}
    if sorted(set(calls)) != [6, 7]:
        fail(LABEL_G1A, "the view did not take its child sets from the shared rule (calls %s)" % calls)
    if nodes[6]["child_set"]["total"] != 1 or nodes[6]["child_set"]["label"] != 0:
        fail(LABEL_G1A, "the carrier counted itself (fixture 6): %s" % nodes[6]["child_set"])
    if nodes[7]["child_set"]["total"] != 2 or nodes[7]["child_set"]["label"] != 1 or nodes[7]["child_set"]["open"] != 1:
        fail(LABEL_G1A, "the label-only open child was missed (fixture 7): %s" % nodes[7]["child_set"])


ARMS = [arm_ac1, arm_ac2, arm_ac3, arm_ac4, arm_ac5, arm_int1, arm_int2, arm_cd1, arm_ciac4,
        arm_evg, arm_part, arm_enc, arm_ord, arm_g1a]


def main() -> int:
    failures: List[str] = []

    def fail(label: str, what: str) -> None:
        failures.append("%s — %s" % (label, what))

    for arm in ARMS:
        before = len(failures)
        try:
            arm(fail)
        except Exception as exc:  # an arm that raises is that arm's failure
            failures.append("%s — raised %s: %s" % (arm.__name__, type(exc).__name__, exc))
        print("%s %s" % ("ok  " if len(failures) == before else "FAIL", arm.__name__))
    print("\nchain-head arms: %d run, %d failures" % (len(ARMS), len(failures)))
    if failures:
        print("\nTEST FAIL:", file=sys.stderr)
        for f in failures:
            print("  " + f, file=sys.stderr)
        return 1
    print("\nTEST OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
