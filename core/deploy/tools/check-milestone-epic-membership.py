#!/usr/bin/env python3
"""check-milestone-epic-membership.py — milestone↔epic membership (#2219, Check 56).

Two legs with DELIBERATELY DIFFERENT severities:

  M1 MEMBERSHIP (FAIL-capable)
      For each open milestone that DECLARES an epic, every open non-sub-task child
      issue's parent-epic must equal that declared epic — unless the child body
      carries the `<!-- milestone-epic: allow -->` cross-epic override.
      A milestone with NO declared epic is SKIPPED, never failed: absence of a
      declaration is not a membership violation.

  M2 RECONCILIATION (WARN-only, separately exemptible)
      The milestone description's `### Scope` section names a card set; compare it
      to live membership and warn on divergence. This leg is INHERENTLY ADVISORY —
      a milestone description legitimately lags its membership mid-release — so it
      must never gate. It is emitted as its own sub-invariant so it can be silenced
      without disabling the (precise) M1 leg.

WHY THE TWO LEGS READ DIFFERENT MEMBERSHIP SETS
-----------------------------------------------
M1 is OPEN-scoped. It is the FAIL-capable leg and asks a live-drift question —
"does this open card sit under the declared epic?" — and a completed card's
parent-epic is history, not drift.

M2's membership set spans ALL issue states. An OPEN-only set cannot distinguish
  (a) the Scope names a card that IS a member and has been COMPLETED   → benign
  (b) the Scope names a card that is NOT a member of this milestone     → drift
because a completed member is simply invisible, so (a) renders as (b). Both then
read `named-not-member`, which puts a false positive in front of the operator on
a leg that is already advisory — and an advisory leg that cries wolf is one the
operator stops reading, taking the precise M1 leg down with it.

The all-states set is fetched THROUGH the open milestones rather than by scanning
every issue in the repository: only the issues M2 actually iterates are retrieved
(measured 1.3s vs 16.5s for a repository-wide all-states scan, with zero
membership divergence between the two over the open-milestone population). A
milestone holding more than 100 issues is re-fetched with the inner connection
paginated — a truncated membership set would turn every unlisted card into a
phantom `named-not-member`, so it must never be silently accepted.

WHY SUB-TASKS ARE EXCLUDED FROM BOTH LEGS
-----------------------------------------
Pipeline sub-tasks (`sub-task` label) are Stage-6 scaffolding created AFTER the
milestone description is authored, and they carry no parent-epic by design. Milestone
266 today holds 6 cards + 3 pipeline sub-tasks; counting the sub-tasks would make M2
permanently non-green for every in-flight milestone and would make M1 flag scaffolding
as cross-epic drift. Excluding them is what makes both legs mean something.

EPIC-DECLARATION SYNTAX
-----------------------
  Canonical:  <!-- milestone-epic: #1177 -->     (machine marker, invisible when rendered)
  Accepted:   **Epic:** #1177                    (human-readable prose form)

Symmetric with the child-side override `<!-- milestone-epic: allow -->` that #2219's
own acceptance criteria specify.

  ADOPTION STATUS AT INTRODUCTION: 0 of 46 open milestones declare an epic in any
  shape. The M1 leg therefore SKIPs universally on first run and is INERT until
  milestone descriptions adopt the marker. This is reported explicitly (DECLARED 0)
  rather than being allowed to read as a green pass — an inert gate that looks green
  is worse than one that says it did nothing.

OUTPUT (TSV) / EXIT CODES
-------------------------
  MILESTONES <n>                              open milestones examined
  DECLARED   <n>                              how many declared an epic
  SKIP_MS    <ms>  no-declared-epic           M1 skipped for this milestone
  M1         <ms>  <issue>  <parent>  <declared>
  M2         <ms>  <named>  <live>  <detail>
  EXEMPT     <leg> <detail>
  COUNT_M1   <n>                              FAIL-capable findings
  COUNT_M2   <n>                              warn-only findings

  exit 0 — no findings on either leg
  exit 1 — findings present (deploy.sh splits severity by leg)
  exit 3 — input failure (API unreadable / malformed fixture)

Python 3.9-compatible — matches /usr/bin/python3 on the operator baseline.
"""

import argparse
import json
import os
import re
import subprocess
import sys

DECLARED_EPIC_MARKER = re.compile(r'<!--\s*milestone-epic:\s*#(\d+)\s*-->')
DECLARED_EPIC_PROSE = re.compile(r'\*\*Epic:\*\*\s*#(\d+)')
CHILD_OVERRIDE = re.compile(r'<!--\s*milestone-epic:\s*allow\s*-->')
ISSUE_REF = re.compile(r'#(\d+)')
SCOPE_SECTION = re.compile(
    r'^#{2,4}\s*Scope\b.*?$(?P<body>.*?)(?=^#{2,4}\s|\Z)',
    re.M | re.S | re.I,
)

SUB_TASK_LABEL = "sub-task"
EPIC_LABEL = "type:epic"

GRAPHQL_OPEN_ISSUES = """
query($owner:String!,$name:String!,$endCursor:String){
  repository(owner:$owner,name:$name){
    issues(first:100, states:OPEN, after:$endCursor){
      pageInfo{hasNextPage endCursor}
      nodes{
        number
        body
        milestone{ number }
        labels(first:40){ nodes{ name } }
        parent{ number labels(first:40){ nodes{ name } } }
      }
    }
  }
}
"""

# M2's membership set, fetched THROUGH the open milestones so it spans ALL issue
# states. Deliberately a second, narrow query rather than dropping states:OPEN
# from the query above:
#   - M1 must stay OPEN-scoped. It is the FAIL-capable leg and asks a live-drift
#     question ("does this open card sit under the declared epic?"); a closed
#     card's parent is history, not drift.
#   - Scoping through milestones(states:OPEN) fetches only the issues that belong
#     to a milestone M2 actually iterates — measured 1.3s versus 16.5s for an
#     all-states repository-wide scan, with 0 membership divergences between the
#     two over the open-milestone population.
# Only `number` + `labels` are requested: M2 needs membership and the sub-task
# predicate, nothing else. `totalCount` + `hasNextPage` drive the overflow
# fallback below — a truncated membership set must never read green.
GRAPHQL_MILESTONE_MEMBERS = """
query($owner:String!,$name:String!,$endCursor:String){
  repository(owner:$owner,name:$name){
    milestones(first:100, states:OPEN, after:$endCursor){
      pageInfo{hasNextPage endCursor}
      nodes{
        number
        issues(first:100){
          totalCount
          pageInfo{hasNextPage}
          nodes{ number labels(first:40){ nodes{ name } } }
        }
      }
    }
  }
}
"""

# Overflow path: a milestone holding >100 issues truncates in the batched query
# above. Rather than silently under-reporting membership (which would turn every
# unlisted card into a phantom `named-not-member`), re-fetch that one milestone
# with the inner connection paginated.
GRAPHQL_ONE_MILESTONE_MEMBERS = """
query($owner:String!,$name:String!,$number:Int!,$endCursor:String){
  repository(owner:$owner,name:$name){
    milestone(number:$number){
      issues(first:100, after:$endCursor){
        pageInfo{hasNextPage endCursor}
        nodes{ number labels(first:40){ nodes{ name } } }
      }
    }
  }
}
"""


def _gh(args):
    proc = subprocess.run(args, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or "gh call failed").strip().splitlines()[0])
    return proc.stdout


def iter_json_docs(text):
    """Yield each JSON document from a CONCATENATED stream.

    `gh api --paginate` emits one JSON document per page with NO separator between
    them — not newline-delimited JSON. Splitting on newlines yields a single
    unparseable blob the moment a query spans >1 page, and the result silently
    reads as zero rows (a false-green). raw_decode walks the concatenation
    correctly regardless of page count.
    """
    decoder = json.JSONDecoder()
    idx, n = 0, len(text)
    while idx < n:
        while idx < n and text[idx].isspace():
            idx += 1
        if idx >= n:
            break
        obj, end = decoder.raw_decode(text, idx)
        yield obj
        idx = end


def fetch_milestones(repo):
    raw = _gh(["gh", "api",
               "repos/%s/milestones?state=open&per_page=100" % repo, "--paginate"])
    out = []
    try:
        for payload in iter_json_docs(raw):
            if isinstance(payload, list):
                out.extend(payload)
    except ValueError:
        raise RuntimeError("milestone payload was not decodable JSON")
    return out


def fetch_open_issues(repo):
    owner, _, name = repo.partition("/")
    raw = _gh(["gh", "api", "graphql", "--paginate",
               "-f", "query=" + GRAPHQL_OPEN_ISSUES,
               "-F", "owner=" + owner, "-F", "name=" + name])
    nodes = []
    try:
        for payload in iter_json_docs(raw):
            nodes.extend(payload["data"]["repository"]["issues"]["nodes"])
    except (KeyError, TypeError, ValueError):
        raise RuntimeError("unexpected GraphQL payload shape")
    return nodes


def fetch_milestone_members(repo):
    """Membership of every OPEN milestone, across ALL issue states.

    Returns {milestone-number: [issue-node, ...]} with each node carrying
    `number` + `labels` (enough for the sub-task predicate). Sub-task filtering
    is left to analyse() so the exclusion rule lives in exactly one place.
    """
    owner, _, name = repo.partition("/")
    raw = _gh(["gh", "api", "graphql", "--paginate",
               "-f", "query=" + GRAPHQL_MILESTONE_MEMBERS,
               "-F", "owner=" + owner, "-F", "name=" + name])
    members, overflowed = {}, []
    try:
        for payload in iter_json_docs(raw):
            for node in payload["data"]["repository"]["milestones"]["nodes"]:
                issues = node["issues"]
                members[str(node["number"])] = list(issues["nodes"])
                if issues["pageInfo"]["hasNextPage"]:
                    overflowed.append(node["number"])
    except (KeyError, TypeError, ValueError):
        raise RuntimeError("unexpected milestone-membership payload shape")

    # Re-fetch any milestone that overflowed the 100-node batch, paginated.
    for number in overflowed:
        raw_one = _gh(["gh", "api", "graphql", "--paginate",
                       "-f", "query=" + GRAPHQL_ONE_MILESTONE_MEMBERS,
                       "-F", "owner=" + owner, "-F", "name=" + name,
                       "-F", "number=%d" % number])
        nodes = []
        try:
            for payload in iter_json_docs(raw_one):
                nodes.extend(payload["data"]["repository"]["milestone"]["issues"]["nodes"])
        except (KeyError, TypeError, ValueError):
            raise RuntimeError("unexpected payload re-fetching milestone #%d" % number)
        members[str(number)] = nodes
    return members


def declared_epic(description):
    """Resolve a milestone's declared epic. None → the milestone is SKIPPED."""
    if not description:
        return None
    m = DECLARED_EPIC_MARKER.search(description)
    if m:
        return m.group(1)
    m = DECLARED_EPIC_PROSE.search(description)
    if m:
        return m.group(1)
    return None


def named_cards(description):
    """Issue refs named in the description's `### Scope` section (that section only).

    Scoped to the Scope heading deliberately: a milestone description also cites
    issues in Dependency Exceptions and the Amendment Log, which are commentary,
    not membership claims.
    """
    if not description:
        return set()
    m = SCOPE_SECTION.search(description)
    if not m:
        return set()
    return set(ISSUE_REF.findall(m.group("body")))


def label_names(node):
    return [n.get("name", "") for n in (node.get("labels") or {}).get("nodes", [])]


def is_sub_task(node):
    return SUB_TASK_LABEL in label_names(node)


def analyse(milestones, issues, members_all=None):
    """Pure join — no I/O, so the self-test can drive it with synthetic data.

    `issues` is the OPEN issue set and drives M1 (the FAIL-capable live-drift
    leg). `members_all`, when supplied, is {milestone-number: [issue-node, ...]}
    spanning ALL issue states and drives M2's membership set ONLY.

    Why M2 needs a different basis: an OPEN-only membership set cannot tell
    "this milestone's Scope names a card that was completed" apart from "this
    milestone's Scope names a card that is not in this milestone at all". The
    first is benign lag, the second is the divergence M2 exists to report, and
    conflating them puts a false positive in front of the operator on a leg that
    is already advisory. When members_all is None the OPEN set is used (the
    pre-existing behavior, and what the offline --fixture path drives).
    """
    by_ms = {}
    for iss in issues:
        ms = iss.get("milestone")
        if not ms:
            continue
        by_ms.setdefault(str(ms.get("number")), []).append(iss)

    m1, m2, skipped, exempted = [], [], [], []
    declared_count = 0

    for ms in milestones:
        ms_num = str(ms.get("number"))
        desc = ms.get("description") or ""
        children = [c for c in by_ms.get(ms_num, []) if not is_sub_task(c)]
        epic = declared_epic(desc)

        # ── M1 membership ────────────────────────────────────────────────
        if epic is None:
            skipped.append(ms_num)
        else:
            declared_count += 1
            for child in children:
                if CHILD_OVERRIDE.search(child.get("body") or ""):
                    exempted.append(("M1", "#%s (milestone-epic: allow)" % child.get("number")))
                    continue
                parent = child.get("parent")
                parent_num = str(parent.get("number")) if parent else "none"
                if parent_num != epic:
                    m1.append((ms_num, str(child.get("number")), parent_num, epic))

        # ── M2 reconciliation (warn-only) ────────────────────────────────
        named = named_cards(desc)
        if not named:
            continue
        # M2 membership spans ALL states (see the analyse docstring); `children`
        # is OPEN-only and stays M1's basis. Falling back to `children` keeps the
        # offline --fixture path and the synthetic self-test fixtures working.
        if members_all is None:
            live = set(str(c.get("number")) for c in children)
        else:
            live = set(str(c.get("number"))
                       for c in members_all.get(ms_num, [])
                       if not is_sub_task(c))
        missing = sorted(named - live, key=int)   # named but not live members
        extra = sorted(live - named, key=int)     # live members not named
        if missing or extra:
            detail = []
            if missing:
                detail.append("named-not-member: " + ",".join("#" + n for n in missing))
            if extra:
                detail.append("member-not-named: " + ",".join("#" + n for n in extra))
            m2.append((ms_num, str(len(named)), str(len(live)), "; ".join(detail)))

    return m1, m2, skipped, exempted, declared_count


# ── self-test ───────────────────────────────────────────────────────────────

def _iss(num, ms=None, parent=None, labels=None, body=""):
    node = {"number": num, "body": body,
            "labels": {"nodes": [{"name": l} for l in (labels or [])]}}
    node["milestone"] = {"number": ms} if ms else None
    node["parent"] = ({"number": parent, "labels": {"nodes": [{"name": EPIC_LABEL}]}}
                      if parent else None)
    return node


def self_test():
    results = []

    def check(name, ok):
        results.append((name, ok))

    # M1-a: a cross-epic child in a milestone that DECLARES an epic → FAIL.
    ms = [{"number": 1, "description": "<!-- milestone-epic: #100 -->"}]
    iss = [_iss(10, ms=1, parent=100), _iss(11, ms=1, parent=999)]
    m1, _, _, _, dec = analyse(ms, iss)
    check("M1 flags cross-epic child", m1 == [("1", "11", "999", "100")] and dec == 1)

    # M1-b: the prose declaration form is equally accepted.
    ms = [{"number": 1, "description": "**Epic:** #100"}]
    m1, _, _, _, _ = analyse(ms, [_iss(11, ms=1, parent=999)])
    check("M1 accepts prose '**Epic:** #N' form", len(m1) == 1)

    # M1-c: `<!-- milestone-epic: allow -->` override suppresses the finding.
    ms = [{"number": 1, "description": "<!-- milestone-epic: #100 -->"}]
    iss = [_iss(11, ms=1, parent=999, body="cross-epic rider\n<!-- milestone-epic: allow -->")]
    m1, _, _, ex, _ = analyse(ms, iss)
    check("M1 override suppresses finding", len(m1) == 0 and len(ex) == 1)

    # M1-d: NO declared epic → SKIP, never FAIL.
    ms = [{"number": 1, "description": "no epic declared here"}]
    m1, _, sk, _, dec = analyse(ms, [_iss(11, ms=1, parent=999)])
    check("M1 skips milestone with no declared epic",
          len(m1) == 0 and sk == ["1"] and dec == 0)

    # M1-e: sub-tasks are excluded (pipeline scaffolding, no parent-epic by design).
    ms = [{"number": 1, "description": "<!-- milestone-epic: #100 -->"}]
    iss = [_iss(11, ms=1, parent=None, labels=[SUB_TASK_LABEL])]
    m1, _, _, _, _ = analyse(ms, iss)
    check("M1 excludes sub-tasks", len(m1) == 0)

    # M1-f: a parentless card under a declared epic IS a finding (parent 'none').
    ms = [{"number": 1, "description": "<!-- milestone-epic: #100 -->"}]
    m1, _, _, _, _ = analyse(ms, [_iss(11, ms=1, parent=None)])
    check("M1 flags parentless card as 'none'", m1 == [("1", "11", "none", "100")])

    # M2-a: description names N cards, live membership is N+1 → warning.
    ms = [{"number": 2, "description": "### Scope\n1. #10 — a\n"}]
    _, m2, _, _, _ = analyse(ms, [_iss(10, ms=2), _iss(11, ms=2)])
    check("M2 warns on member-not-named", len(m2) == 1 and "member-not-named" in m2[0][3])

    # M2-b: named card absent from live membership → warning.
    ms = [{"number": 2, "description": "### Scope\n1. #10 — a\n2. #12 — b\n"}]
    _, m2, _, _, _ = analyse(ms, [_iss(10, ms=2)])
    check("M2 warns on named-not-member", len(m2) == 1 and "named-not-member" in m2[0][3])

    # M2-c: exact agreement → no warning.
    ms = [{"number": 2, "description": "### Scope\n1. #10 — a\n"}]
    _, m2, _, _, _ = analyse(ms, [_iss(10, ms=2)])
    check("M2 silent when description matches membership", len(m2) == 0)

    # M2-d: refs OUTSIDE the Scope section are commentary, not membership claims.
    ms = [{"number": 2, "description":
           "### Scope\n1. #10 — a\n\n### Amendment Log\n- #999 relocated\n"}]
    _, m2, _, _, _ = analyse(ms, [_iss(10, ms=2)])
    check("M2 ignores refs outside the Scope section", len(m2) == 0)

    # M2-e: sub-tasks do not count as unnamed members.
    ms = [{"number": 2, "description": "### Scope\n1. #10 — a\n"}]
    _, m2, _, _, _ = analyse(ms, [_iss(10, ms=2), _iss(99, ms=2, labels=[SUB_TASK_LABEL])])
    check("M2 excludes sub-tasks from membership", len(m2) == 0)

    # ── M2 all-states membership basis ───────────────────────────────────
    # A named card that IS a member but has been COMPLETED must not read as a
    # divergence: the description and membership agree, the card is just done.
    # With an OPEN-only basis that card is invisible and reads named-not-member,
    # which is a false positive on an already-advisory leg.
    ms = [{"number": 2, "description": "### Scope\n1. #10 — a\n2. #12 — b\n"}]
    open_only = [_iss(10, ms=2)]                      # #12 completed → not in the OPEN set
    members = {"2": [{"number": 12, "labels": {"nodes": []}},
                     {"number": 10, "labels": {"nodes": []}}]}

    # Control: the OPEN-only basis DOES flag it — otherwise the assertion below
    # would be vacuous and would pass even if members_all were ignored.
    _, m2_open, _, _, _ = analyse(ms, open_only)
    check("M2 control: OPEN-only basis flags a completed member",
          len(m2_open) == 1 and "named-not-member: #12" in m2_open[0][3])

    _, m2_all, _, _, _ = analyse(ms, open_only, members)
    check("M2 all-states basis clears a completed member", len(m2_all) == 0)

    # A named card that is NOT a member in ANY state is still a divergence —
    # the fix must not blunt the leg into silence.
    ms = [{"number": 2, "description": "### Scope\n1. #10 — a\n2. #77 — elsewhere\n"}]
    _, m2_all, _, _, _ = analyse(ms, open_only, members)
    check("M2 all-states basis still flags a card that is no member at all",
          len(m2_all) == 1 and "named-not-member: #77" in m2_all[0][3])

    # A COMPLETED member the description never names is member-not-named — the
    # recall side of the same change.
    ms = [{"number": 2, "description": "### Scope\n1. #10 — a\n"}]
    _, m2_all, _, _, _ = analyse(ms, open_only, members)
    check("M2 all-states basis reports a completed member the Scope omits",
          len(m2_all) == 1 and "member-not-named: #12" in m2_all[0][3])

    # Sub-task exclusion applies to the all-states basis too (one predicate,
    # both bases) — a closed pipeline sub-task must not become a phantom member.
    ms = [{"number": 2, "description": "### Scope\n1. #10 — a\n"}]
    members_st = {"2": [{"number": 10, "labels": {"nodes": []}},
                        {"number": 98, "labels": {"nodes": [{"name": SUB_TASK_LABEL}]}}]}
    _, m2_all, _, _, _ = analyse(ms, open_only, members_st)
    check("M2 all-states basis excludes sub-tasks", len(m2_all) == 0)

    # M1 must NOT move to the all-states basis: it is the FAIL-capable live-drift
    # leg, and a closed card's parent-epic is history, not drift.
    ms = [{"number": 2, "description": "<!-- milestone-epic: #100 -->"}]
    m1_all, _, _, _, _ = analyse(ms, [_iss(10, ms=2, parent=100)],
                                 {"2": [{"number": 10, "labels": {"nodes": []}},
                                        {"number": 55, "labels": {"nodes": []}}]})
    check("M1 stays OPEN-scoped when an all-states membership map is supplied",
          len(m1_all) == 0)

    # PAGINATION: `gh --paginate` concatenates page documents with NO separator.
    # A newline-split parse silently yields ZERO rows past page 1 — a FALSE-GREEN
    # that made every milestone read as having 0 live members. Regression guard.
    concat = '{"a":1}{"a":2}  {"a":3}'
    check("concatenated multi-page JSON parses to all documents",
          [d["a"] for d in iter_json_docs(concat)] == [1, 2, 3])
    check("single-document JSON still parses",
          [d["a"] for d in iter_json_docs('{"a":9}')] == [9])

    failed = [n for n, ok in results if not ok]
    for name, ok in results:
        print(("  PASS  " if ok else "  FAIL  ") + name)
    print("self-test: %d/%d passed" % (len(results) - len(failed), len(results)))
    return 1 if failed else 0


def _derive_repo(explicit):
    """owner/name of the running clone's origin (fork-correct); never hardcode the
    operator handle (depersonalization gate). Returns None if unset and unresolved."""
    if explicit:
        return explicit
    try:
        url = subprocess.run(["git", "config", "--get", "remote.origin.url"],
                             capture_output=True, text=True).stdout.strip()
        m = re.search(r"[:/]([^/]+/[^/]+?)(?:\.git)?$", url)
        if m:
            return m.group(1)
    except Exception:
        pass
    return None


def main():
    ap = argparse.ArgumentParser(description="Milestone-epic membership check.")
    ap.add_argument("--repo", default=None,
                    help="owner/name; derived from git remote origin when omitted")
    ap.add_argument("--output-format", choices=("tsv",), default="tsv")
    ap.add_argument("--fixture", help="JSON {milestones:[],issues:[]} — drives both legs offline")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    members_all = None
    if args.fixture:
        try:
            with open(args.fixture, "r", encoding="utf-8") as fh:
                data = json.load(fh)
            milestones, issues = data["milestones"], data["issues"]
            # Optional: a fixture may supply an explicit all-states membership
            # map to drive M2; absent it, M2 falls back to the OPEN set.
            members_all = data.get("members_all")
        except (OSError, ValueError, KeyError) as exc:
            print("ERROR\tfixture unreadable: " + str(exc), file=sys.stderr)
            return 3
    else:
        repo = _derive_repo(args.repo)
        if not repo:
            print("ERROR\t--repo not supplied and git remote origin unresolved",
                  file=sys.stderr)
            return 3
        try:
            milestones = fetch_milestones(repo)
            issues = fetch_open_issues(repo)
            members_all = fetch_milestone_members(repo)
        except RuntimeError as exc:
            print("ERROR\t" + str(exc), file=sys.stderr)
            return 3

    m1, m2, skipped, exempted, declared = analyse(milestones, issues, members_all)

    out = ["MILESTONES\t" + str(len(milestones)), "DECLARED\t" + str(declared)]
    for ms_num in skipped:
        out.append("SKIP_MS\t" + ms_num + "\tno-declared-epic")
    for row in m1:
        out.append("M1\t" + "\t".join(row))
    for row in m2:
        out.append("M2\t" + "\t".join(row))
    for leg, detail in exempted:
        out.append("EXEMPT\t" + leg + "\t" + detail)
    out.append("COUNT_M1\t" + str(len(m1)))
    out.append("COUNT_M2\t" + str(len(m2)))
    print("\n".join(out))
    return 1 if (m1 or m2) else 0


if __name__ == "__main__":
    sys.exit(main())
