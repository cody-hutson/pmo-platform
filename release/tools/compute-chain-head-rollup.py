#!/usr/bin/env python3
"""compute-chain-head-rollup.py — every chain head in one view, read live.

A chain head is the top of a line of work in the tracker. There are two kinds,
and neither is registered anywhere — both are derived from tracker state on every
run:

  * an INITIATIVE head: every `project:` label carrying at least one open issue
    (a label with none is listed as empty, not drawn);
  * a LONE-EPIC head: every open `type:epic` issue carrying no `project:` label —
    except that a label-less epic whose children, by strict majority, carry one
    standing initiative's label renders inside that initiative as a flow container.

Under each head the view draws three levels: the head, its epics (and, for a
standing initiative, its flow containers), and each epic's open children. Adding
an epic to an initiative needs only the label; there is no list to edit.

STANDING vs FINITE. An initiative is standing when its label's description, left-
stripped, begins with the word `Standing` (label taxonomy, § Initiative Labels).
A standing initiative is capacity-governed and never shows a completion
percentage. If NO initiative reads as standing, the run stops with exit 1 and says
why: an edit that drops the word would otherwise turn the standing initiative into
a finite one and put every flow container back as a separate head, silently.

WHAT IS COUNTED, AND WHAT IS NOT CLAIMED.
  * Members of an initiative are its open issues that are not epics or sub-tasks.
    Every member falls in exactly one bucket — in an epic tree of that head,
    parented outside it, or unparented — and the three counts must sum to the
    member count (a broken sum exits 1).
  * The host omits `parent_issue_url` from an issue that has no parent, so a
    missing key means NO PARENT and the member counts as unparented. The facet is
    marked unmeasured, never 0, only when the field is not served at all: no open
    issue carries it while some issue reports sub-issues.
  * Dependency edges come from the single-sourced grammar in
    bundle-issues-parser.py (`parse_dependencies`), loaded by path; this file has
    no grammar of its own. A `clean` parse is measured; any other status is
    unmeasured and the member is left out of the blocked count. A member with no
    Dependencies section whose tracker record shows open native blockers is also
    unmeasured, never "not blocked".
  * An epic's children come from _epic_child_set.py, the one child-set rule this
    view shares with audit-epic-rollup-close.sh. A child-set read that failed is
    unmeasured, never "no children".
  * The order is a display order (open-member count, then name), never a run
    sequence. The output says so.

LAYERS. fetch_snapshot() is the only code that talks to the host (REST through
`gh api`; no GraphQL). derive() is pure and takes the grammar and the child-set
rule as arguments. render_markdown() and the JSON dump format the result. The tool
writes no file and keeps no cache: every run reads the tracker afresh.

Usage:
  python3 release/tools/compute-chain-head-rollup.py                # Markdown (default)
  python3 release/tools/compute-chain-head-rollup.py --json         # versioned JSON rollup
  python3 release/tools/compute-chain-head-rollup.py --repo owner/name --limit 5000
  python3 release/tools/compute-chain-head-rollup.py --self-test

Exit codes:
  0  the view rendered (unmeasured facets included — an unmeasured facet is
     reported, not an error)
  1  a usage error; an unreadable population (labels or open issues); an empty
     population; more open issues than --limit; a broken partition sum; no
     initiative reading as standing; or a grammar or child-set module that would
     not load

Python 3.9, stdlib only. The decision this tool implements is recorded as
{{ADR:chain-head-set-derives-from-tracker-labels}}.
"""

import argparse
import datetime
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.parse
from typing import Dict, List, Optional, Tuple

SCHEMA_VERSION = "1"
HERE = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(os.path.dirname(HERE))
GRAMMAR_PATH = os.path.join(HERE, "bundle-issues-parser.py")
CHILD_SET_PATH = os.path.join(HERE, "_epic_child_set.py")

PROJECT_PREFIX = "project:"
EPIC_LINK_PREFIX = "epic:"
EPIC_LABEL = "type:epic"
NON_MEMBER_LABELS = ("type:epic", "sub-task", "type:subtask")
STANDING_WORD_RE = re.compile(r"Standing\b")
STANDING_REASON = "standing — capacity-governed"
ABSORB_THRESHOLD = 0.5  # strictly more than half of an epic's children
ORDERING_BASIS = ("initiative heads by open-member count descending, then name; lone-epic "
                  "heads by number; epics by open-child count descending, then number; "
                  "children by number")
GH_CANDIDATES = ("/opt/homebrew/bin/gh", "/usr/local/bin/gh", "/usr/bin/gh")


class ToolError(Exception):
    """Any condition that stops the run with exit 1."""


class StandingGuardError(ToolError):
    """No initiative label reads as standing."""


class PartitionError(ToolError):
    """A head's member buckets do not sum to its member count."""


# ---- Module loading (by path, relative to this file) ---------------------------

def _load_by_path(name: str, path: str):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ToolError("cannot load %s from %s" % (name, _rel(path)))
    mod = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(mod)
    except Exception as exc:  # a missing or broken module stops the run
        raise ToolError("cannot load %s from %s: %s" % (name, _rel(path), exc))
    return mod


class Grammar:
    """The dependency grammar the view reads edges through, plus its section test."""

    def __init__(self, source: str, parse_dependencies, extract_section_aliased, heading_aliases):
        self.source = source
        self.parse_dependencies = parse_dependencies
        self.extract_section_aliased = extract_section_aliased
        self.heading_aliases = list(heading_aliases)

    def section_present(self, body: str) -> bool:
        return self.extract_section_aliased(body or "", self.heading_aliases) is not None


def load_grammar() -> Grammar:
    """The single-sourced grammar: bundle-issues-parser.py's parse_dependencies."""
    bip = _load_by_path("bundle_issues_parser", GRAMMAR_PATH)
    return Grammar(_rel(GRAMMAR_PATH), bip.parse_dependencies, bip.extract_section_aliased,
                   bip.DEP_HEADING_ALIASES)


def load_child_rule():
    """The one epic child-set rule (G1a), shared with the epic rollup-close audit."""
    return _load_by_path("_epic_child_set", CHILD_SET_PATH)


def _rel(path: str) -> str:
    try:
        return os.path.relpath(path, REPO_ROOT)
    except ValueError:
        return os.path.basename(path)


# ---- Fetch (the only layer that talks to the host) -----------------------------

def parse_slug_from_url(url: str) -> Optional[str]:
    """git@host:owner/name.git or https://host/owner/name(.git) -> owner/name."""
    url = (url or "").strip()
    if not url:
        return None
    if url.endswith(".git"):
        url = url[:-4]
    tail = url.replace(":", "/").rstrip("/").split("/")
    if len(tail) < 2 or not tail[-1] or not tail[-2]:
        return None
    return tail[-2] + "/" + tail[-1]


def _toml_value(path: str, key: str) -> Optional[str]:
    try:
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                if line.strip().startswith(key) and "=" in line:
                    return line.split("=", 1)[1].strip().strip('"').strip("'") or None
    except OSError:
        return None
    return None


def resolve_repo(explicit: Optional[str]) -> str:
    """--repo, then the git remote, then operator.toml. Never a hardcoded owner."""
    if explicit:
        return explicit
    try:
        res = subprocess.run(["git", "-C", REPO_ROOT, "remote", "get-url", "origin"],
                             capture_output=True, text=True)
        slug = parse_slug_from_url(res.stdout) if res.returncode == 0 else None
        if slug:
            return slug
    except OSError:
        pass
    toml = os.path.join(os.path.expanduser("~"), ".config", "pmo-platform", "operator.toml")
    owner = _toml_value(toml, "operator_github")
    name = _toml_value(toml, "pmo_platform_repo_name") or "pmo-platform"
    if owner:
        return owner + "/" + name
    raise ToolError("cannot resolve the repository — pass --repo <owner/name>")


def resolve_gh() -> str:
    found = shutil.which("gh")
    if found:
        return found
    for cand in GH_CANDIDATES:
        if os.path.isfile(cand) and os.access(cand, os.X_OK):
            return cand
    raise ToolError("gh CLI not found on PATH or at %s" % ", ".join(GH_CANDIDATES))


def _gh_pages(gh: str, endpoint: str) -> List[Dict]:
    """GET a paginated REST list; raise RuntimeError on any failure."""
    res = subprocess.run([gh, "api", endpoint, "--paginate", "--slurp"],
                         capture_output=True, text=True)
    if res.returncode != 0:
        raise RuntimeError((res.stderr or res.stdout).strip()[:200])
    pages = json.loads(res.stdout or "[]")
    rows: List[Dict] = []
    for page in pages:
        if isinstance(page, list):
            rows.extend(page)
        elif isinstance(page, dict):
            rows.append(page)
    return rows


def _child_row(raw: Dict) -> Dict:
    return {"number": int(raw["number"]), "title": raw.get("title") or "",
            "state": raw.get("state") or "", "state_reason": raw.get("state_reason"),
            "labels": [lb.get("name", "") for lb in raw.get("labels") or []]}


def fetch_snapshot(repo: str, limit: int) -> Dict:
    """Read labels, open issues and every open epic's children. No cache, no writes."""
    gh = resolve_gh()
    reads: List[Dict] = []
    try:
        labels = _gh_pages(gh, "repos/%s/labels?per_page=100" % repo)
    except (RuntimeError, ValueError) as exc:
        raise ToolError("the label read failed — refusing to render an unread population: %s" % exc)
    reads.append({"read": "labels", "status": "ok", "detail": "%d labels" % len(labels)})
    try:
        raw_issues = _gh_pages(gh, "repos/%s/issues?state=open&per_page=100" % repo)
    except (RuntimeError, ValueError) as exc:
        raise ToolError("the open-issue read failed — refusing to render an unread population: %s" % exc)
    issues = [it for it in raw_issues if "pull_request" not in it]
    reads.append({"read": "open_issues", "status": "ok", "detail": "%d open issues" % len(issues)})
    if len(issues) > limit:
        raise ToolError("%d open issues exceed --limit %d — raise the limit rather than truncate"
                        % (len(issues), limit))

    search_total = None
    res = subprocess.run([gh, "api", "-X", "GET", "search/issues", "-f",
                          "q=repo:%s is:issue is:open" % repo, "--jq", ".total_count"],
                         capture_output=True, text=True)
    if res.returncode == 0 and res.stdout.strip().isdigit():
        search_total = int(res.stdout.strip())
        reads.append({"read": "search_total", "status": "ok", "detail": str(search_total)})
    else:
        reads.append({"read": "search_total", "status": "failed",
                      "detail": (res.stderr or res.stdout).strip()[:200]})

    child_reads: Dict[int, Dict] = {}
    for it in issues:
        names = [lb.get("name", "") for lb in it.get("labels") or []]
        if EPIC_LABEL not in names:
            continue
        number = int(it["number"])
        entry = {"status": "ok", "detail": "", "native": [], "label": []}
        try:
            entry["native"] = [_child_row(r) for r in
                               _gh_pages(gh, "repos/%s/issues/%d/sub_issues?per_page=100" % (repo, number))]
            for name in names:
                if not name.startswith(EPIC_LINK_PREFIX):
                    continue
                endpoint = "repos/%s/issues?labels=%s&state=all&per_page=100" % (
                    repo, urllib.parse.quote(name, safe=":"))
                entry["label"].extend(_child_row(r) for r in _gh_pages(gh, endpoint)
                                      if "pull_request" not in r)
        except (RuntimeError, ValueError, KeyError) as exc:
            entry = {"status": "failed", "detail": str(exc)[:200], "native": [], "label": []}
        child_reads[number] = entry
        reads.append({"read": "epic_children:%d" % number, "status": entry["status"],
                      "detail": entry["detail"]})

    anchor = "unknown"
    try:
        res = subprocess.run(["git", "-C", REPO_ROOT, "rev-parse", "--short", "HEAD"],
                             capture_output=True, text=True)
        if res.returncode == 0 and res.stdout.strip():
            anchor = res.stdout.strip()
    except OSError:
        pass
    return {"repo": repo, "commit_anchor": anchor,
            "generated_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "labels": labels, "issues": issues, "search_total": search_total,
            "child_reads": child_reads, "reads": reads}


# ---- Derive (pure) --------------------------------------------------------------

def _issue(raw: Dict) -> Dict:
    """Normalise one REST issue row. A missing parent_issue_url key means no parent."""
    names = [lb.get("name", "") for lb in raw.get("labels") or []]
    parent_url = raw.get("parent_issue_url")
    parent = None
    if parent_url:
        tail = str(parent_url).rstrip("/").rsplit("/", 1)[-1]
        parent = int(tail) if tail.isdigit() else None
    ms = raw.get("milestone") or None
    deps = raw.get("issue_dependencies_summary")
    subs = raw.get("sub_issues_summary")
    return {
        "number": int(raw["number"]), "title": raw.get("title") or "",
        "labels": names, "body": raw.get("body") or "",
        "has_parent_key": "parent_issue_url" in raw, "parent": parent,
        "milestone": ({"number": ms.get("number"), "title": ms.get("title") or "",
                       "state": ms.get("state") or ""} if isinstance(ms, dict) else None),
        "native_blocked_by_open": (deps.get("blocked_by") if isinstance(deps, dict) else None),
        "sub_issues_total": (subs.get("total") if isinstance(subs, dict) else None),
    }


def is_standing(description: Optional[str]) -> bool:
    return bool(STANDING_WORD_RE.match((description or "").lstrip()))


def _edges(issue: Dict, grammar: Grammar, open_numbers) -> Dict:
    targets, status = grammar.parse_dependencies(issue["body"])
    section = "present" if grammar.section_present(issue["body"]) else "absent"
    native = issue.get("native_blocked_by_open")
    blocked_by = [{"number": t, "in_open_set": t in open_numbers} for t in sorted(targets)]
    edges = {"status": "measured", "parse_status": status, "section": section,
             "native_blocked_by_open": native, "blocked_by": blocked_by, "reason": None}
    if status != "clean":
        edges["status"] = "unmeasured"
        edges["reason"] = "the dependency parse read '%s', not clean" % status
    elif section == "absent" and isinstance(native, int) and native > 0:
        edges["status"] = "unmeasured"
        edges["reason"] = ("no Dependencies section; the tracker records %d open blocker%s"
                           % (native, "" if native == 1 else "s"))
    return edges


def _is_blocked(edges: Dict) -> bool:
    return edges["status"] == "measured" and any(t["in_open_set"] for t in edges["blocked_by"])


def _progress_of(child_status: str, union: Dict[int, Dict], role: str) -> Dict:
    if child_status != "ok":
        return {"status": "unmeasured", "reason": "the child-set read failed"}
    if role == "flow-container":
        return {"status": "not-applicable", "reason": STANDING_REASON}
    if not union:
        return {"status": "undefined", "reason": "no children"}
    completed = sum(1 for c in union.values() if (c.get("state") or "").lower() == "closed"
                    and (c.get("state_reason") or "").lower() == "completed")
    not_planned = sum(1 for c in union.values() if (c.get("state") or "").lower() == "closed"
                      and (c.get("state_reason") or "").lower() == "not_planned")
    total = len(union)
    return {"status": "measured", "completed": completed, "not_planned": not_planned,
            "total": total, "percent": int(round(100.0 * completed / total))}


def _sum_progress(nodes: List[Dict]) -> Dict:
    finite = [n for n in nodes if n["role"] == "epic"]
    if not finite:
        return {"status": "undefined", "reason": "no epics"}
    if any(n["progress"]["status"] == "unmeasured" for n in finite):
        return {"status": "unmeasured", "reason": "an epic's child-set read failed"}
    measured = [n["progress"] for n in finite if n["progress"]["status"] == "measured"]
    total = sum(p["total"] for p in measured)
    if total == 0:
        return {"status": "undefined", "reason": "no children"}
    completed = sum(p["completed"] for p in measured)
    return {"status": "measured", "completed": completed,
            "not_planned": sum(p["not_planned"] for p in measured), "total": total,
            "percent": int(round(100.0 * completed / total))}


def check_partition(head_id: str, in_tree: int, outside: int, unparented: int, members: int) -> None:
    if in_tree + outside + unparented != members:
        raise PartitionError("partition broken for %s: %d in tree + %d parented outside + %d "
                             "unparented != %d open members"
                             % (head_id, in_tree, outside, unparented, members))


def derive(snapshot: Dict, grammar: Grammar, child_rule) -> Dict:
    """Snapshot -> schema-v1 rollup. Pure: no host, no file, no clock."""
    project = [(lb.get("name", ""), lb.get("description") or "") for lb in snapshot.get("labels") or []
               if (lb.get("name") or "").startswith(PROJECT_PREFIX)]
    issues = [_issue(r) for r in snapshot.get("issues") or []]
    if not project:
        raise ToolError("no %s label exists — an empty population, not an empty view" % PROJECT_PREFIX)
    if not issues:
        raise ToolError("the open-issue read returned no issues — a broken read, not an empty view")
    standing = sorted(name for name, desc in project if is_standing(desc))
    if not standing:
        raise StandingGuardError(
            "no %s label reads as standing. A standing initiative declares itself by "
            "beginning its label description with the word `Standing` (label taxonomy, "
            "§ Initiative Labels). Refusing to render: without one, the standing initiative "
            "would read as finite and every flow container would return as a separate head."
            % PROJECT_PREFIX)

    by_number = {i["number"]: i for i in issues}
    open_numbers = set(by_number)
    epics = [i for i in issues if EPIC_LABEL in i["labels"]]
    members_all = [i for i in issues if not any(lb in NON_MEMBER_LABELS for lb in i["labels"])]
    child_reads = {int(k): v for k, v in (snapshot.get("child_reads") or {}).items()}

    # The parent field is unmeasured only when the host does not serve it at all.
    served = any(i["has_parent_key"] for i in issues)
    has_subissues = any((i["sub_issues_total"] or 0) > 0 for i in issues)
    parent_measured = served or not has_subissues
    parent_reason = None if parent_measured else (
        "the open-issue read carries no parent field while some issue reports sub-issues")

    def child_union(epic: Dict) -> Tuple[str, Dict[int, Dict], int, int]:
        read = child_reads.get(epic["number"])
        if not read or read.get("status") != "ok":
            return "failed", {}, 0, 0
        native, label_only = child_rule.child_set(epic["number"], read.get("native") or [],
                                                  read.get("label") or [])
        return "ok", child_rule.union(native, label_only), len(native), len(label_only)

    def make_node(epic: Dict, role: str, absorption: Optional[Dict]) -> Dict:
        status, union, n_native, n_label = child_union(epic)
        open_kids = sorted(n for n, c in union.items() if (c.get("state") or "").lower() == "open")
        children = []
        for n in open_kids:
            rec = by_number.get(n)
            if rec is None:
                children.append({"number": n, "title": union[n].get("title") or "", "milestone": None,
                                 "edges": {"status": "unmeasured", "blocked_by": [],
                                           "reason": "not in the open-issue read"}})
                continue
            children.append({"number": n, "title": rec["title"], "milestone": rec["milestone"],
                             "edges": _edges(rec, grammar, open_numbers)})
        return {"number": epic["number"], "title": epic["title"], "role": role,
                "absorption": absorption,
                "child_set": {"status": "measured" if status == "ok" else "unmeasured",
                              "native": n_native, "label": n_label, "total": len(union),
                              "open": len(open_kids)},
                "progress": _progress_of(status, union, role), "children": children}

    # Label-less epics: absorbed into a standing initiative by strict majority, or heads.
    absorbed: Dict[str, List[Dict]] = {s: [] for s in standing}
    lone: List[Dict] = []
    for epic in sorted((e for e in epics if not any(lb.startswith(PROJECT_PREFIX) for lb in e["labels"])),
                       key=lambda e: e["number"]):
        status, union, _n, _l = child_union(epic)
        if status != "ok":
            lone.append({"epic": epic, "absorption": {"status": "unmeasured",
                                                      "reason": "the child-set read failed"}})
            continue
        if not union:
            lone.append({"epic": epic, "absorption": {"status": "measured", "label": None,
                                                      "reason": "no children"}})
            continue
        total = len(union)
        shares = {s: sum(1 for c in union.values() if s in (c.get("labels") or [])) for s in standing}
        best = max(shares.values())
        winners = [s for s, v in shares.items() if v == best]
        if best > ABSORB_THRESHOLD * total and len(winners) == 1:
            absorbed[winners[0]].append({"epic": epic, "absorption": {
                "status": "measured", "label": winners[0], "share": "%d/%d" % (best, total)}})
        else:
            lone.append({"epic": epic, "absorption": {
                "status": "measured", "label": None,
                "reason": ("a tie between standing labels" if len(winners) > 1 and best > ABSORB_THRESHOLD * total
                           else "no standing label holds a strict majority of its children"),
                "share": "%d/%d" % (best, total)}})

    # Epic-label links: an issue carrying epic:<slug> is linked to each open epic carrying it.
    link_index: Dict[str, set] = {}
    for epic in epics:
        for lb in epic["labels"]:
            if lb.startswith(EPIC_LINK_PREFIX):
                link_index.setdefault(lb, set()).add(epic["number"])

    def links_of(issue: Dict) -> set:
        found = set()
        for lb in issue["labels"]:
            found |= link_index.get(lb, set())
        found.discard(issue["number"])
        return found

    heads: List[Dict] = []
    empty_labels: List[str] = []
    for name, desc in project:
        members = [m for m in members_all if name in m["labels"]]
        own_epics = [e for e in epics if name in e["labels"]]
        if not members and not own_epics and not absorbed.get(name):
            empty_labels.append(name)
            continue
        mode = "standing" if name in standing else "finite"
        nodes = [make_node(e, "epic", None) for e in own_epics]
        nodes += [make_node(a["epic"], "flow-container", a["absorption"]) for a in absorbed.get(name, [])]
        nodes.sort(key=lambda n: (-n["child_set"]["open"], n["number"]))
        l2 = {n["number"] for n in nodes}
        in_tree = outside = 0
        unparented_issues: List[int] = []
        blocked = unmeasured_edges = 0
        for m in members:
            linked = links_of(m)
            if (m["parent"] in l2) or (linked & l2):
                in_tree += 1
            elif m["parent"] is not None or linked:
                outside += 1
            else:
                unparented_issues.append(m["number"])
            edges = _edges(m, grammar, open_numbers)
            if edges["status"] != "measured":
                unmeasured_edges += 1
            elif _is_blocked(edges):
                blocked += 1
        if parent_measured:
            check_partition(name, in_tree, outside, len(unparented_issues), len(members))
            partition = {"status": "measured", "in_tree": in_tree, "parented_outside": outside}
            unparented = {"status": "measured", "count": len(unparented_issues),
                          "issues": sorted(unparented_issues), "reason": None}
        else:
            partition = {"status": "unmeasured", "in_tree": None, "parented_outside": None}
            unparented = {"status": "unmeasured", "count": None, "issues": [], "reason": parent_reason}
        progress = ({"status": "not-applicable", "reason": STANDING_REASON} if mode == "standing"
                    else _sum_progress(nodes))
        heads.append({"id": name, "kind": "initiative", "mode": mode, "mode_basis": "label-description",
                      "title": name, "description": desc, "members_open": len(members),
                      "partition": partition, "unparented": unparented, "progress": progress,
                      "blocked": {"count": blocked, "unmeasured": unmeasured_edges}, "nodes": nodes})
    heads.sort(key=lambda h: (-h["members_open"], h["id"]))

    lone_heads: List[Dict] = []
    for item in lone:
        epic = item["epic"]
        node = make_node(epic, "epic", item["absorption"])
        measured = node["child_set"]["status"] == "measured"
        kids = node["children"]
        blocked = sum(1 for c in kids if _is_blocked(c["edges"]))
        unmeasured_edges = sum(1 for c in kids if c["edges"]["status"] != "measured")
        lone_heads.append({
            "id": "#%d" % epic["number"], "kind": "lone-epic", "mode": "finite", "mode_basis": "lone-epic",
            "title": epic["title"], "description": "", "absorption": item["absorption"],
            "members_open": len(kids) if measured else None,
            "partition": ({"status": "measured", "in_tree": len(kids), "parented_outside": 0} if measured
                          else {"status": "unmeasured", "in_tree": None, "parented_outside": None}),
            "unparented": ({"status": "measured", "count": 0, "issues": [], "reason": None} if measured
                           else {"status": "unmeasured", "count": None, "issues": [],
                                 "reason": "the child-set read failed"}),
            "progress": node["progress"], "blocked": {"count": blocked, "unmeasured": unmeasured_edges},
            "nodes": [node]})

    unlabeled = [m for m in members_all if not any(lb.startswith(PROJECT_PREFIX) for lb in m["labels"])]
    multi = sorted(m["number"] for m in members_all
                   if sum(1 for lb in m["labels"] if lb.startswith(PROJECT_PREFIX)) > 1)
    meta = {
        "generated_at": snapshot.get("generated_at"), "commit_anchor": snapshot.get("commit_anchor"),
        "repo": snapshot.get("repo"), "denominator": len(issues),
        "search_total": snapshot.get("search_total"), "reads": snapshot.get("reads") or [],
        "grammar": {"source": grammar.source, "callable": "parse_dependencies"},
        "child_set_rule": {"source": _rel(CHILD_SET_PATH), "callable": "child_set"},
        "standing_labels": standing,
        "parent_field": {"status": "measured" if parent_measured else "unmeasured", "reason": parent_reason},
        "ordering": {"basis": ORDERING_BASIS, "is_sequence": False},
        "unlabeled": {"count": len(unlabeled),
                      "unparented": (sum(1 for m in unlabeled if m["parent"] is None and not links_of(m))
                                     if parent_measured else None),
                      "issues": sorted(m["number"] for m in unlabeled)},
        "multi_initiative_members": multi,
        "empty_initiative_labels": sorted(empty_labels),
    }
    return {"schema_version": SCHEMA_VERSION, "meta": meta, "heads": heads + lone_heads}


# ---- Render ---------------------------------------------------------------------

def md_cell(text) -> str:
    """Encode untrusted text for a Markdown table cell or an HTML context."""
    s = "" if text is None else str(text)
    s = s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    s = s.replace("`", "&#96;").replace("[", "&#91;").replace("]", "&#93;")
    s = s.replace("|", "\\|")
    return s.replace("\r\n", " ").replace("\r", " ").replace("\n", " ")


def _progress_text(p: Dict) -> str:
    if p["status"] == "measured":
        extra = ", %d not planned" % p["not_planned"] if p.get("not_planned") else ""
        return "%d%% (%d of %d done%s)" % (p["percent"], p["completed"], p["total"], extra)
    if p["status"] == "not-applicable":
        return "no percentage — %s" % p["reason"]
    return "%s — %s" % (p["status"], p.get("reason") or "")


def _edges_text(e: Dict) -> str:
    if e["status"] != "measured":
        return "edges unmeasured — %s" % e.get("reason")
    if not e["blocked_by"]:
        return "not blocked"
    return "blocked by " + ", ".join("#%d%s" % (t["number"], "" if t["in_open_set"] else " (not open)")
                                     for t in e["blocked_by"])


def render_markdown(rollup: Dict) -> str:
    m = rollup["meta"]
    out: List[str] = []
    add = out.append
    initiative = [h for h in rollup["heads"] if h["kind"] == "initiative"]
    lone = [h for h in rollup["heads"] if h["kind"] == "lone-epic"]
    add("# Chain-Head View\n")
    add("**Generated:** %s · **Commit anchor:** `%s` · **Repo:** %s  " % (
        md_cell(m["generated_at"]), md_cell(m["commit_anchor"]), md_cell(m["repo"])))
    add("**Denominator:** %d open issues (search total %s) · **Heads:** %d initiative, %d lone-epic  " % (
        m["denominator"], "unread" if m["search_total"] is None else m["search_total"],
        len(initiative), len(lone)))
    add("**Edges:** `%s` `parse_dependencies` · **Children:** `%s` `child_set` · **Standing:** %s\n" % (
        md_cell(m["grammar"]["source"]), md_cell(m["child_set_rule"]["source"]),
        ", ".join("`%s`" % md_cell(s) for s in m["standing_labels"])))
    add("> **This order is not a sequence.** It is a display order — %s. It ranks nothing, "
        "gates nothing, and implies no run order; a roadmap carries sequence.\n" % md_cell(m["ordering"]["basis"]))
    failed = [r for r in m["reads"] if r.get("status") != "ok"]
    if failed:
        add("**Reads that failed (their facets read unmeasured):** " + "; ".join(
            "%s (%s)" % (md_cell(r["read"]), md_cell(r.get("detail"))) for r in failed) + "\n")
    if m["parent_field"]["status"] != "measured":
        add("**Unparented counts are unmeasured:** %s.\n" % md_cell(m["parent_field"]["reason"]))
    add("| Head | Kind | Mode | Open members | Unparented | Blocked | Progress |")
    add("|---|---|---|---|---|---|---|")
    for h in rollup["heads"]:
        up = h["unparented"]
        add("| %s | %s | %s | %s | %s | %d%s | %s |" % (
            md_cell(h["id"] if h["kind"] == "initiative" else "%s %s" % (h["id"], h["title"])),
            h["kind"], h["mode"], "unmeasured" if h["members_open"] is None else h["members_open"],
            up["count"] if up["status"] == "measured" else "unmeasured",
            h["blocked"]["count"], " (%d unmeasured)" % h["blocked"]["unmeasured"] if h["blocked"]["unmeasured"] else "",
            md_cell(_progress_text(h["progress"]))))
    add("")
    for h in rollup["heads"]:
        add("## %s\n" % md_cell(h["id"] if h["kind"] == "initiative" else "%s %s" % (h["id"], h["title"])))
        if h["description"]:
            add("%s\n" % md_cell(h["description"]))
        if h["partition"]["status"] == "measured" and h["kind"] == "initiative":
            add("Members: %d in an epic tree here · %d parented outside it · %d unparented%s\n" % (
                h["partition"]["in_tree"], h["partition"]["parented_outside"], h["unparented"]["count"],
                (" (" + ", ".join("#%d" % n for n in h["unparented"]["issues"]) + ")")
                if h["unparented"]["issues"] else ""))
        if not h["nodes"]:
            add("_No epics._\n")
        for n in h["nodes"]:
            cs = n["child_set"]
            share = ""
            if n["role"] == "flow-container" and n.get("absorption"):
                share = " · flow container (%s of its children carry the label)" % md_cell(n["absorption"].get("share"))
            add("<details><summary>#%d %s — %s open of %s · %s%s</summary>\n" % (
                n["number"], md_cell(n["title"]), cs["open"] if cs["status"] == "measured" else "unmeasured",
                cs["total"] if cs["status"] == "measured" else "unmeasured",
                md_cell(_progress_text(n["progress"])), share))
            if n["children"]:
                add("| Child | Title | Milestone | Dependencies |")
                add("|---|---|---|---|")
                for c in n["children"]:
                    ms = c["milestone"]["title"] if c.get("milestone") else "—"
                    add("| #%d | %s | %s | %s |" % (c["number"], md_cell(c["title"]), md_cell(ms),
                                                    md_cell(_edges_text(c["edges"]))))
            else:
                add("_No open children._")
            add("\n</details>\n")
    add("## Open issues with no initiative label\n")
    un = m["unlabeled"]
    add("%d issue%s%s%s\n" % (
        un["count"], "" if un["count"] == 1 else "s",
        "" if un["unparented"] is None else " (%d unparented)" % un["unparented"],
        (": " + ", ".join("#%d" % n for n in un["issues"])) if un["issues"] else ""))
    add("## Issues in more than one initiative\n")
    add((", ".join("#%d" % n for n in m["multi_initiative_members"]) or "None.") + "\n")
    add("## Initiative labels with no open issue\n")
    add((", ".join("`%s`" % md_cell(s) for s in m["empty_initiative_labels"]) or "None.") + "\n")
    return "\n".join(out)


# ---- Self-test (offline) ---------------------------------------------------------

def _fixture_snapshot() -> Dict:
    def issue(n, labels, body="", parent=None, keyless=False, native=0, subs=0):
        row = {"number": n, "title": "issue %d" % n, "labels": [{"name": x} for x in labels],
               "body": body, "milestone": None, "state": "open", "state_reason": None,
               "issue_dependencies_summary": {"blocked_by": native, "total_blocked_by": native},
               "sub_issues_summary": {"total": subs, "completed": 0, "percent_completed": 0}}
        if not keyless:
            row["parent_issue_url"] = None if parent is None else "https://api.example/repos/o/r/issues/%d" % parent
        if keyless and parent is not None:
            row["parent_issue_url"] = "https://api.example/repos/o/r/issues/%d" % parent
        return row

    kid = lambda n, state, labels, reason=None: {"number": n, "title": "child %d" % n, "state": state,
                                                  "state_reason": reason, "labels": labels}
    alpha, flow = PROJECT_PREFIX + "alpha", PROJECT_PREFIX + "flow"  # synthetic labels
    return {
        "repo": "o/r", "commit_anchor": "abc1234", "generated_at": "2026-01-01T00:00:00Z",
        "labels": [{"name": alpha, "description": "Finite work toward a capability"},
                   {"name": flow, "description": "Standing quality flow"},
                   {"name": EPIC_LABEL, "description": "An epic"}],
        "issues": [
            issue(10, [EPIC_LABEL, alpha], subs=2),
            issue(11, [alpha], body="### Dependencies\nBlocked by: #12\n", parent=10),
            issue(12, [alpha], parent=10),
            issue(20, [EPIC_LABEL], subs=3),
            issue(21, [flow], parent=20),
            issue(22, [flow], body="### Dependencies\n[ASSUMPTION – CONFIRM] TBD — identified in Planning\n",
                  keyless=True),
        ],
        "search_total": 6,
        "child_reads": {
            10: {"status": "ok", "native": [kid(11, "open", [alpha]), kid(12, "open", [alpha]),
                                            kid(13, "closed", [alpha], "completed")], "label": []},
            20: {"status": "ok", "native": [kid(21, "open", [flow]), kid(23, "closed", [flow], "completed"),
                                            kid(24, "closed", [], "completed")], "label": []},
        },
        "reads": [],
    }


def run_self_test() -> int:
    failures: List[str] = []

    def check(label: str, ok: bool) -> None:
        print("  %s %s" % ("ok  " if ok else "FAIL", label))
        if not ok:
            failures.append(label)

    print("compute-chain-head-rollup.py --self-test (offline; inline snapshot)")
    grammar, rule = load_grammar(), load_child_rule()
    rollup = derive(_fixture_snapshot(), grammar, rule)
    heads = {h["id"]: h for h in rollup["heads"]}
    alpha, flow = PROJECT_PREFIX + "alpha", PROJECT_PREFIX + "flow"
    check("two initiative heads, no lone-epic head", sorted(heads) == [alpha, flow])
    check("the label-less epic is absorbed as a flow container",
          [n["role"] for n in heads[flow]["nodes"]] == ["flow-container"])
    check("the standing head carries no percentage",
          heads[flow]["progress"]["status"] == "not-applicable" and "percent" not in heads[flow]["progress"])
    check("the finite head carries a percentage", heads[alpha]["progress"].get("percent") == 33)
    check("a deferred dependency parse is unmeasured, not 'not blocked'",
          heads[flow]["blocked"] == {"count": 0, "unmeasured": 1})
    check("a governed blocked-by edge counts the member blocked", heads[alpha]["blocked"]["count"] == 1)
    check("a member with no parent key counts as unparented",
          heads[flow]["unparented"] == {"status": "measured", "count": 1, "issues": [22], "reason": None})
    check("the output declares it is not a sequence", rollup["meta"]["ordering"]["is_sequence"] is False
          and "not a sequence" in render_markdown(rollup))
    snap = _fixture_snapshot()
    snap["labels"][1]["description"] = "Quality flow, never closes"
    try:
        derive(snap, grammar, rule)
        check("no standing initiative fails loudly", False)
    except StandingGuardError:
        check("no standing initiative fails loudly", True)
    if failures:
        print("compute-chain-head-rollup.py --self-test: FAIL (%d)" % len(failures), file=sys.stderr)
        return 1
    print("compute-chain-head-rollup.py --self-test: PASS")
    return 0


# ---- CLI --------------------------------------------------------------------------

class _Parser(argparse.ArgumentParser):
    def error(self, message):
        self.print_usage(sys.stderr)
        print("compute-chain-head-rollup.py: error: %s" % message, file=sys.stderr)
        sys.exit(1)


def main(argv: Optional[List[str]] = None) -> int:
    ap = _Parser(description="Every chain head in one view, read live from the tracker.")
    fmt = ap.add_mutually_exclusive_group()
    fmt.add_argument("--markdown", action="store_true", help="human view (default)")
    fmt.add_argument("--json", action="store_true", help="versioned machine-readable rollup")
    ap.add_argument("--repo", help="owner/name (default: the git remote, then operator.toml)")
    ap.add_argument("--limit", type=int, default=5000, help="open-issue ceiling (default 5000)")
    ap.add_argument("--self-test", action="store_true", help="offline fixtures; no host read")
    args = ap.parse_args(argv)
    try:
        if args.self_test:
            return run_self_test()
        grammar, rule = load_grammar(), load_child_rule()
        snapshot = fetch_snapshot(resolve_repo(args.repo), args.limit)
        rollup = derive(snapshot, grammar, rule)
    except ToolError as exc:
        print("ERROR: %s" % exc, file=sys.stderr)
        return 1
    if args.json:
        print(json.dumps(rollup, indent=2))
    else:
        print(render_markdown(rollup))
    return 0


if __name__ == "__main__":
    sys.exit(main())
