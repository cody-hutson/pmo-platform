#!/usr/bin/env python3
"""check-milestone-epic-membership.py — milestone↔issue-population invariants (Check 56).

Three legs with DELIBERATELY DIFFERENT severities. The subject is the milestone's
issue population: which epic its cards sit under (M1), whether its description
matches its membership (M2), and whether its pipeline scaffold is complete (M3).

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

  M3 SCAFFOLD COMPLETENESS (ADVISORY-ONLY, structurally — #3819)
      Does the milestone's pipeline scaffold cover the stages it should? Routed
      through deploy.sh's `flag_advisory_only`, which has no mode case, no enforce
      branch and no ISSUES increment, so this leg CANNOT be flipped to FAIL by a
      future cohort graduation. It reports rather than gates, and its findings
      never move this script's exit code.

      Scope is a FUNCTION OF THE STAGE NUMBER — Stages 5–8 are per-issue, every
      other stage is release-scoped (hub-spoke-bridge.md Procedure 1). It is NOT a
      function of the title grammar: four per-issue grammars are live concurrently
      and the most common covers 53.3%, so a title-keyed classifier inherits that
      drift. Parent identity comes from the positively-emitted marker
      `<!-- subtask-scope: issue:#N | release -->`, three-valued with an explicit
      UNMARKED state — never inference-by-absence.

      The finding set splits by what membership currency can move:
        load-bearing (COUNT_M3)  ORPHAN-STAGE-TITLE · UNLABELLED ·
                                 release-scoped MISSING on markered milestones
        advisory (COUNT_M3_ADV)  per-issue MISSING · DUPLICATE-PER-ISSUE
        policy (M3-POLICY)       release-scoped MISSING pre-cutover, and
                                 Stages 10/11 always (they compress for
                                 git-native releases)
      Per-issue gaps are advisory because a milestone that gains a card after
      scaffolding legitimately has no sub-tasks for it until Procedure 1 Step 2's
      late-add rule fires — a gate that fails a legitimate state gets routed
      around, which is how a gate becomes a no-op.

WHY SUB-TASKS ARE EXCLUDED FROM THE M1 AND M2 LEGS
--------------------------------------------------
Pipeline sub-tasks (`sub-task` label) are Stage-6 scaffolding created AFTER the
milestone description is authored, and they carry no parent-epic by design. Milestone
266 today holds 6 cards + 3 pipeline sub-tasks; counting the sub-tasks would make M2
permanently non-green for every in-flight milestone and would make M1 flag scaffolding
as cross-epic drift. Excluding them is what makes those two legs mean something.

M3 INVERTS THIS: the scaffold IS its subject, so it counts sub-tasks rather than
excluding them, and it uses the WIDER `is_sub_task_family` predicate
(`sub-task` ∪ `type:subtask`). M1/M2's `is_sub_task` is deliberately narrower —
see the note on `is_sub_task_family`. M3 also gets its OWN member query
(`GRAPHQL_M3_MEMBERS`, adding `title` + `body`) and its OWN milestone fetch
(`fetch_milestone_by_slug`, all-states) rather than widening M1/M2's, so M1/M2
output is unchanged BY CONSTRUCTION rather than by assertion.

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
  SKIP_MS    <ms>  not-yet-scaffolded         M3: 0 attached AND 0 orphans AND
                                              0 narrowed-unlabelled stage titles
  M3         <ms>  MISSING <stage> | ORPHAN-STAGE-TITLE #<n> | UNLABELLED #<n>
  M3-ADV     <ms>  MISSING <stage>:#<issue> | DUPLICATE-PER-ISSUE <stage>:#<issue>
  M3-POLICY  <ms>  MISSING <stage>
  M3-INFO    <ms>  COMBINED-STAGE #<n> | SUB-PHASE #<n> | LEGACY-TITLE-INFERRED <n>
  M3_DENOM   <ms>  <work_items>  <expected_slots>  <created>
  SCAFFOLD_MARKER <ms> <marked>/<total>
  COUNT_M3   <n>                              load-bearing scaffold findings
  COUNT_M3_ADV <n>                            advisory scaffold findings

  exit 0 — no findings on M1 or M2
  exit 1 — M1/M2 findings present (deploy.sh splits severity by leg). M3 NEVER
           moves the exit code: it is advisory by construction.
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
SUB_TASK_LEGACY_LABEL = "type:subtask"
EPIC_LABEL = "type:epic"

# ── M3 scaffold-completeness vocabulary (#3819) ─────────────────────────────
# Scope is a FUNCTION OF THE STAGE NUMBER, per hub-spoke-bridge.md Procedure 1.
PER_ISSUE_STAGES = frozenset({5, 6, 7, 8})
RELEASE_SCOPED_STAGES = frozenset({4, 9, 10, 11, 12, 13})
# Stages 10 (Dry Run) and 11 (Snapshot) compress for git-native releases — their
# absence is a convention question, never a defect, so they are POLICY-only.
COMPRESSIBLE_STAGES = frozenset({10, 11})

STAGE_TOKEN = re.compile(r'^Stage\s+(\d+)((?:\s*[+&/]\s*\d+)*)\b')
SUB_PHASE_TOKEN = re.compile(r'\bPhase\s+[A-Z]?\d')
SCOPE_MARKER = re.compile(r'<!--\s*subtask-scope:\s*(?:issue:#(\d+)|release)\s*-->')

# The four live per-issue title grammars, in priority order. Used ONLY by the
# pre-cutover advisory heuristic — never as a load-bearing key.
G2_DOT = re.compile(r'·\s*#(\d+)\s*·')
G4_MULTI = re.compile(r'—\s*#(\d+)((?:\s+\d+)+)')
G1_PAREN = re.compile(r'—\s*#(\d+)\s*\(')
G3_BARE = re.compile(r'—\s*#(\d+)(?:\s|$)')

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


# M3's OWN member query. `GRAPHQL_MILESTONE_MEMBERS` above is NOT modified and
# NOT reused: M3 needs `title` (stage token) and `body` (scope marker), neither of
# which M2 requests, and widening the shared query would put M2's output at risk
# for no benefit to it. M2's rows stay byte-identical BY CONSTRUCTION rather than
# by a regression assertion. Milestone-scoped and all-states — the scaffold of a
# closed milestone is exactly what an audit of a historical release needs to read.
GRAPHQL_M3_MEMBERS = """
query($owner:String!,$name:String!,$number:Int!,$endCursor:String){
  repository(owner:$owner,name:$name){
    milestone(number:$number){
      title
      issues(first:100, after:$endCursor){
        pageInfo{hasNextPage endCursor}
        nodes{ number title body labels(first:40){ nodes{ name } } }
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


def fetch_milestone_by_slug(repo, wanted):
    """Resolve ONE milestone by slug or number, across ALL states.

    Reachable only from the `--milestone` path. `fetch_milestones()` above stays
    `state=open` — M1/M2's open-only basis is deliberate and untouched — but a
    scaffold audit of a historical release must be able to read a CLOSED
    milestone, which is the whole point of the #264 case.
    """
    raw = _gh(["gh", "api",
               "repos/%s/milestones?state=all&per_page=100" % repo, "--paginate"])
    for payload in iter_json_docs(raw):
        if not isinstance(payload, list):
            continue
        for ms in payload:
            if str(ms.get("number")) == str(wanted) or ms.get("title") == wanted:
                return ms
    raise RuntimeError("milestone not found (any state): %s" % wanted)


def fetch_m3_members(repo, number):
    """All-states issues of ONE milestone, with title + body. Returns (slug, nodes)."""
    owner, _, name = repo.partition("/")
    raw = _gh(["gh", "api", "graphql", "--paginate",
               "-f", "query=" + GRAPHQL_M3_MEMBERS,
               "-F", "owner=" + owner, "-F", "name=" + name,
               "-F", "number=%d" % int(number)])
    slug, nodes = "", []
    try:
        for payload in iter_json_docs(raw):
            node = payload["data"]["repository"]["milestone"]
            slug = node.get("title") or slug
            nodes.extend(node["issues"]["nodes"])
    except (KeyError, TypeError, ValueError):
        raise RuntimeError("unexpected M3 membership payload shape")
    return slug, nodes


def fetch_stage_titled(repo):
    """Every stage-titled issue in the repo, ANY state, with its milestone.

    ONE search call, not a per-milestone fan-out and not the repository-wide
    all-states issue enumeration the module docstring rules out (that was an
    `issues` walk; this is a title-scoped search). Its output is the
    attachment-INDEPENDENT limb of the fire predicate: the orphan set is computed
    from it in memory by slug match, so a milestone whose every sub-task lost its
    milestone field is still detected — while OPEN — by evidence the defect
    CREATES rather than by one it destroys.
    """
    raw = _gh(["gh", "issue", "list", "--repo", repo, "--search", "Stage in:title",
               "--state", "all", "--limit", "1000",
               "--json", "number,title,labels,milestone"])
    try:
        rows = json.loads(raw or "[]")
    except ValueError:
        raise RuntimeError("stage-title search payload was not decodable JSON")
    out = []
    for r in rows:
        out.append({
            "number": r.get("number"),
            "title": r.get("title") or "",
            "body": "",
            "labels": {"nodes": [{"name": l.get("name", "")}
                                 for l in (r.get("labels") or [])]},
            "milestone": (r.get("milestone") or {}).get("number"),
        })
    return out


def orphans_for(slug, ms_number, stage_titled):
    """Stage-titled issues naming this slug whose milestone is NOT this one."""
    if not slug:
        return []
    needle = slug.lower()
    out = []
    for n in stage_titled:
        if needle not in (n.get("title") or "").lower():
            continue
        if str(n.get("milestone")) == str(ms_number):
            continue
        if not stage_tokens(n.get("title"))[0]:
            continue
        out.append(n)
    return out


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


def is_sub_task_family(node):
    """M3's sub-task predicate — DELIBERATELY WIDER than `is_sub_task`.

    M1/M2 test `sub-task` alone because they are *excluding* scaffolding from a
    membership population: a narrow exclusion errs toward flagging, which is the
    safe direction for those legs. M3 is *counting* the scaffold itself, so a
    sub-task carrying only the tolerated legacy alias `type:subtask` must be
    counted, not treated as an unlabelled work item. Two predicates, two
    populations, one reason each — do not collapse them.
    """
    names = label_names(node)
    return SUB_TASK_LABEL in names or SUB_TASK_LEGACY_LABEL in names


def stage_tokens(title):
    """Stages a title claims, from its LEADING `Stage {N}` token.

    Returns ([int, ...], is_sub_phase). Empty list ⇒ not a stage-titled issue.

    Scope is a function of the stage number, never of the title grammar: four
    per-issue title grammars are live concurrently (anchored-paren 53.3% / dot
    41.7% / em-dash-bare 3.1% / multi-parent 0.8%) and no one of them is a sound
    key, but `^Stage (\\d+)` matches 613/613 live stage-titled sub-tasks across all
    four. The combined form (`Stage 7+8 Verification …`) occupies BOTH slots —
    reading only the first would emit a spurious `MISSING 8`.
    """
    m = STAGE_TOKEN.match(title or "")
    if not m:
        return [], False
    stages = [int(m.group(1))]
    for extra in re.findall(r"\d+", m.group(2) or ""):
        stages.append(int(extra))
    # A phase sub-sub-task (`Stage 5 Phase A6.5 · … · Adversarial Design Review`)
    # is work *within* a stage, not an occupant of the stage's slot.
    return stages, bool(SUB_PHASE_TOKEN.search(title or ""))


def scope_marker(body):
    """Three-valued scope/parent resolution from the positively-emitted marker.

    Returns ("issue", "<N>") · ("release", None) · (None, None) for UNMARKED.

    NEVER inference-by-absence. An unmarked sub-task is reported as unmarked and
    gates the parent-dependent rows; it is not silently coerced to either kind.
    A fail-safe default here would be the same shape that lets a marker check
    fail open — the marker is *emitted* by the same `gh issue create` that stamps
    the milestone and the label, so its absence is information, not a default.
    """
    if not body:
        return None, None
    m = SCOPE_MARKER.search(body)
    if not m:
        return None, None
    if m.group(1):
        return "issue", m.group(1)
    return "release", None


def legacy_parent_from_title(title):
    """Pre-cutover attribution heuristic. ADVISORY ONLY — never load-bearing.

    Priority union over the four live grammars. Returns [] when none matches.
    Every row derived from this is tagged `[LEGACY-TITLE-INFERRED]` and excluded
    from COUNT_M3, because the union covers 95.0% of the live per-issue corpus
    and a 95% key is not a key.
    """
    t = title or ""
    m = G2_DOT.search(t)
    if m:
        return [m.group(1)]
    m = G4_MULTI.search(t)
    if m:
        return [m.group(1)] + re.findall(r"\d+", m.group(2))
    m = G1_PAREN.search(t)
    if m:
        return [m.group(1)]
    m = G3_BARE.search(t)
    if m:
        return [m.group(1)]
    return []


def unlabelled_stage_titled(work_items, slug):
    """The NARROWED unlabelled-stage-sub-task predicate. Single definition.

    Returns the work items (i.e. members carrying no sub-task-family label) whose
    title claims a stage AND is narrowed by the milestone slug or an issue
    reference. A bare `^Stage \\d+` predicate false-positives on a real work item
    whose title merely begins with a stage word, so the narrowing is load-bearing.

    ONE definition, TWO call sites — M3's fire predicate and M3's `UNLABELLED`
    emission loop. They must never drift: a fire limb narrower than the emission
    loop silences rows; a fire limb wider than it over-flags. Do not inline either.
    """
    out = []
    for wi in work_items:
        title = wi.get("title") or ""
        if not stage_tokens(title)[0]:
            continue
        if slug and slug.lower() in title.lower():
            out.append(wi)
        elif ISSUE_REF.search(title):
            out.append(wi)
    return out


def analyse_m3(milestones):
    """Pure join — scaffold completeness per milestone. No I/O.

    `milestones` is a list of dicts:
      {"number": str, "slug": str, "members": [node, ...], "orphans": [node, ...]}
    where each node carries `number`, `title`, `body`, `labels`.

    Returns (load_bearing, advisory, policy, info, denom, marker, skipped).

    FIRE PREDICATE — three limbs, one per load-bearing class, because each class
    is defined by the destruction of a DIFFERENT attribute, and a limb gated on
    the attribute its own class destroys can never fire.

      (attached >= 1)     the milestone is scaffolded and labelled
      OR (orphans >= 1)   `ORPHAN-STAGE-TITLE`'s attribute is the MILESTONE field
      OR (unlabelled >= 1) `UNLABELLED`'s attribute is the sub-task LABEL

    SKIP only when all three are zero.

    Limb 2 exists because the founding defect NULLs the milestone field on every
    sub-task it creates: milestone #264 has `attached = 0` and 21 stage-titled
    issues naming its slug with `milestone: NULL`, and an attachment-gated
    predicate calls that "not yet scaffolded" and says nothing.

    Limb 3 exists because that same blind spot recurs one level down for a
    different class. `attached` is computed from the sub-task LABEL — the exact
    attribute `UNLABELLED` exists to detect — and `orphans_for()` excludes any
    issue whose milestone IS this one. So a milestone whose only stage-titled
    artifact is unlabelled AND correctly milestoned satisfies neither of the first
    two limbs and reports `SKIP_MS … not-yet-scaffolded`, silencing the one class
    that is its only available signal. Live instance: milestone #275
    `template-system-governance-wave-1`, whose sole stage-titled issue #3848 is
    unlabelled and correctly milestoned. Limb 3 reuses the narrowed predicate the
    `UNLABELLED` loop itself applies (`unlabelled_stage_titled`), so the limb and
    the emission can never disagree, and the narrowing is inherited rather than
    re-stated: a milestone whose only stage-titled member fails the narrowing
    (the #3826 prose shape) still correctly SKIPs.
    """
    load_bearing, advisory, policy, info = [], [], [], []
    denom, marker, skipped = [], [], []

    for ms in milestones:
        ms_num = str(ms.get("number"))
        slug = ms.get("slug") or ""
        members = ms.get("members") or []
        orphans = ms.get("orphans") or []

        subtasks = [n for n in members if is_sub_task_family(n)]
        work_items = [n for n in members if not is_sub_task_family(n)]

        attached = [n for n in subtasks if stage_tokens(n.get("title"))[0]]
        unlabelled = unlabelled_stage_titled(work_items, slug)
        if not attached and not orphans and not unlabelled:
            skipped.append(ms_num)
            continue

        # ── occupancy ────────────────────────────────────────────────────
        marked = 0
        release_slots = {}          # stage -> occupant count
        per_issue = {}              # (stage, parent) -> occupant count
        legacy_attributions = 0
        for node in attached:
            num = str(node.get("number"))
            stages, is_phase = stage_tokens(node.get("title"))
            if is_phase:
                info.append((ms_num, "SUB-PHASE", "#" + num))
                continue
            if len(stages) > 1:
                info.append((ms_num, "COMBINED-STAGE", "#" + num))
            kind, parent = scope_marker(node.get("body"))
            if kind is not None:
                marked += 1
            parents = [parent] if parent else []
            if kind is None:
                # Pre-cutover: attribute by the union title heuristic, advisory only.
                parents = legacy_parent_from_title(node.get("title"))
                if parents:
                    legacy_attributions += 1
            for st in stages:
                if st in RELEASE_SCOPED_STAGES:
                    release_slots[st] = release_slots.get(st, 0) + 1
                elif st in PER_ISSUE_STAGES:
                    for p in (parents or [None]):
                        key = (st, p)
                        per_issue[key] = per_issue.get(key, 0) + 1

        is_markered = marked > 0
        marker.append((ms_num, "%d/%d" % (marked, len(attached))))

        # ── release-scoped slots ─────────────────────────────────────────
        # `>= 1` occupant, never `== 1`: a remediation re-run legitimately adds a
        # second Stage-9 sub-task, and calling that a duplicate would punish the
        # correct behaviour.
        for st in sorted(RELEASE_SCOPED_STAGES):
            if release_slots.get(st, 0) >= 1:
                continue
            if st in COMPRESSIBLE_STAGES or not is_markered:
                # Stages 10/11 compress for git-native releases, and a pre-cutover
                # milestone predates the convention entirely: both are POLICY
                # assertions about a canonicalization, not defect detections.
                policy.append((ms_num, "MISSING", str(st)))
            else:
                load_bearing.append((ms_num, "MISSING", str(st)))

        # ── per-issue slots (advisory — membership currency, see docstring) ──
        for wi in work_items:
            wnum = str(wi.get("number"))
            for st in sorted(PER_ISSUE_STAGES):
                seen = per_issue.get((st, wnum), 0)
                tag = "" if is_markered else " [LEGACY-TITLE-INFERRED]"
                if seen == 0:
                    advisory.append((ms_num, "MISSING", "%d:#%s%s" % (st, wnum, tag)))
                elif seen > 1:
                    advisory.append((ms_num, "DUPLICATE-PER-ISSUE",
                                     "%d:#%s%s" % (st, wnum, tag)))

        # ── orphaned stage titles (load-bearing on EVERY milestone) ──────
        # Not a policy assertion: a stage sub-task detached from its milestone is
        # a defect under every convention that has ever existed here, so this class
        # asserts pre- and post-cutover alike.
        for node in orphans:
            load_bearing.append((ms_num, "ORPHAN-STAGE-TITLE",
                                 "#" + str(node.get("number"))))

        # ── unlabelled stage sub-tasks (load-bearing, NARROWED) ──────────
        # `unlabelled` was computed ABOVE, by the same helper the fire predicate's
        # third limb uses. Reusing the one binding is what makes limb 3 and this
        # emission structurally incapable of disagreeing — the narrowing lives in
        # `unlabelled_stage_titled` and nowhere else. Do not re-derive it here.
        #
        # Carrying the slug is what makes such a title RECOGNISABLE; it was never
        # what made it REPORTABLE. Until limb 3 was added, a slug-bearing
        # unlabelled title on a milestone with no labelled sub-task and no orphan
        # was recognised here and never reached, because the milestone had already
        # been skipped upstream (live: #3848 on milestone #275).
        for wi in unlabelled:
            load_bearing.append((ms_num, "UNLABELLED", "#" + str(wi.get("number"))))

        expected = len(RELEASE_SCOPED_STAGES) + len(work_items) * len(PER_ISSUE_STAGES)
        denom.append((ms_num, str(len(work_items)), str(expected), str(len(attached))))
        if legacy_attributions:
            info.append((ms_num, "LEGACY-TITLE-INFERRED", str(legacy_attributions)))

    return load_bearing, advisory, policy, info, denom, marker, skipped


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

    # ── M3 scaffold completeness (#3819) ─────────────────────────────────
    def _st(num, title, body="", labels=("sub-task",), ms=None):
        return {"number": num, "title": title, "body": body,
                "labels": {"nodes": [{"name": l} for l in labels]},
                "milestone": ms}

    def _ms(num, slug, members, orphans=()):
        return {"number": num, "slug": slug,
                "members": list(members), "orphans": list(orphans)}

    MK_R = "<!-- subtask-scope: release -->"

    def _mk_i(n):
        return "<!-- subtask-scope: issue:#%d -->" % n

    # fx_complete — one work item, all six release-scoped slots, all four
    # per-issue slots, every sub-task markered.
    def _complete():
        members = [_st(10, "A delivered work item", labels=("bug",))]
        for st in (4, 9, 10, 11, 12, 13):
            members.append(_st(100 + st, "Stage %d X — slug (release-scoped)" % st, MK_R))
        for st in (5, 6, 7, 8):
            members.append(_st(200 + st, "Stage %d X — #10 (slug)" % st, _mk_i(10)))
        return _ms(1, "slug", members)

    lb, adv, pol, inf, den, mk, sk = analyse_m3([_complete()])
    check("M3 fx_complete: a fully-scaffolded milestone is clean",
          len(lb) == 0 and len(adv) == 0 and len(pol) == 0 and sk == [])
    check("M3 fx_complete: SCAFFOLD_MARKER reports full adoption",
          mk == [("1", "10/10")])
    check("M3 fx_complete: M3_DENOM reports work items / expected slots / created",
          den == [("1", "1", "10", "10")])

    # Precision probe: delete one expected sub-task ⇒ COUNT_M3 non-zero. Without
    # this, "fx_complete is clean" is satisfied by a leg that finds nothing ever.
    partial = _complete()
    partial["members"] = [n for n in partial["members"]
                          if not str(n["title"]).startswith("Stage 13")]
    lb_p, _, _, _, _, _, _ = analyse_m3([partial])
    check("M3 precision probe: removing the Stage-13 slot produces a finding",
          ("1", "MISSING", "13") in lb_p)

    # fx_264 — OPEN, never milestoned, 21 orphan stage titles naming the slug.
    # SHAPED OPEN DELIBERATELY: an earlier revision of this fixture was CLOSED,
    # which let it pass through the milestone-state limb and never exercised the
    # OPEN case that is the actual defect. A fixture that passes for the wrong
    # reason is how a blind spot survives its own test set.
    orphans_264 = [_st(3000 + i, "Stage %d Work — #%d (pda-rollup-and-portfolio)"
                       % (5 + (i % 4), 900 + i), ms=None) for i in range(21)]
    fx_264 = _ms(264, "pda-rollup-and-portfolio", [], orphans_264)
    lb264, _, _, _, _, _, sk264 = analyse_m3([fx_264])
    check("M3 fx_264: fires while OPEN with attached=0 via the orphan limb",
          sk264 == [] and len(lb264) > 0)
    check("M3 fx_264: emits 21 ORPHAN-STAGE-TITLE rows",
          len([r for r in lb264 if r[1] == "ORPHAN-STAGE-TITLE"]) == 21)

    # fx_264_closed — the same shape on a CLOSED milestone still fires; the leg
    # keys on evidence, not on milestone state.
    lb264c, _, _, _, _, _, sk264c = analyse_m3(
        [_ms(264, "pda-rollup-and-portfolio", [], orphans_264)])
    check("M3 fx_264_closed: closed-milestone path still fires on orphans",
          sk264c == [] and len(lb264c) > 0)

    # fx_notstarted — OPEN, 0 attached, 0 orphans, 0 unlabelled ⇒ SKIP.
    # Discriminated from fx_264 by the variable the defect CREATES (orphan count),
    # not by one it destroys (milestone attachment). RETAINED as the anti-over-flag
    # control for all three fire limbs: a genuinely un-scaffolded milestone must
    # still SKIP after limb 3 was added.
    _, _, _, _, _, _, sk_ns = analyse_m3([_ms(999, "not-started-yet", [], [])])
    check("M3 fx_notstarted: 0 attached AND 0 orphans AND 0 unlabelled ⇒ SKIP",
          sk_ns == ["999"])

    # fx_275 — the third fire limb. Milestone #275 `template-system-governance-
    # wave-1` holds exactly one stage-titled artifact, #3848, which is UNLABELLED
    # and CORRECTLY MILESTONED. `attached` is label-gated and `orphans_for()`
    # excludes issues whose milestone IS this one, so limbs 1 and 2 both read zero
    # and the milestone reported `SKIP_MS … not-yet-scaffolded` — silencing the one
    # class that was its only available signal.
    #
    # THIS IS THE FOUNDING BLIND SPOT REPRODUCED ONE LEVEL DOWN. fx_264 covers the
    # class whose destroyed attribute is the MILESTONE field; this covers the class
    # whose destroyed attribute is the sub-task LABEL. Neither fixture substitutes
    # for the other, and fx_notstarted (0 members) could never have caught it —
    # there was no fixture in this shape (members present, stage-titled, unlabelled,
    # no orphans) until this one.
    fx_275 = _ms(275, "template-system-governance-wave-1", [
        _st(3848, "Stage 4 Release Planning — template-system-governance-wave-1 "
                  "(#275)", labels=("bug",)),
        _st(3849, "Template inventory and gap analysis", labels=("bug",)),
        _st(3850, "Author the governance template standard", labels=("bug",)),
    ])
    lb275, _, _, _, _, _, sk275 = analyse_m3([fx_275])
    check("M3 fx_275: an unlabelled, correctly-milestoned stage title fires "
          "(limb 3) rather than reading as not-yet-scaffolded",
          sk275 == [] and ("275", "UNLABELLED", "#3848") in lb275)
    check("M3 fx_275: the UNLABELLED row is the ONLY load-bearing class it "
          "raises (no spurious release-scoped MISSING on an unmarkered milestone)",
          [r for r in lb275 if r[1] != "UNLABELLED"] == [])

    # fx_275_narrowing — the anti-over-flag control PAIRED to fx_275, and the one
    # that proves limb 3 INHERITED the narrowing rather than degrading to a bare
    # `^Stage \d+` fire. Same shape as fx_275, but its only stage-titled member is
    # the #3826 prose shape: no slug, no issue reference. It must still SKIP.
    # Without this, "limb 3 fires" is satisfied by a limb that fires on everything.
    fx_275_narrow = _ms(276, "template-system-governance-wave-1", [
        _st(3826, "Stage 5-9 review and the Stage-9 readiness scan miss the "
                  "required issue-reference", labels=("bug",)),
        _st(3851, "Template inventory and gap analysis", labels=("bug",)),
    ])
    lb276, _, _, _, _, _, sk276 = analyse_m3([fx_275_narrow])
    check("M3 fx_275_narrowing: limb 3 inherits the narrowing — a stage-titled "
          "member with neither slug nor issue ref still SKIPs",
          sk276 == ["276"] and lb276 == [])

    # fx_titleforms (T-10) — controls drawn from the population the parser was
    # NOT written from: the dot form, the bare form, multi-parent, the
    # milestone-number near-miss, combined-stage, sub-phase, and #3826's shape.
    check("M3 T-10 dot form parses its parent",
          legacy_parent_from_title("Stage 5 · #3809 · Solutioning") == ["3809"])
    check("M3 T-10 bare em-dash form parses its parent",
          legacy_parent_from_title("Stage 8 QA — #3441 human-process build") == ["3441"])
    check("M3 T-10 multi-parent form parses all five parents",
          legacy_parent_from_title("Stage 5 Solutioning — #2221 2702 2701 2917 380 (slug)")
          == ["2221", "2702", "2701", "2917", "380"])
    check("M3 T-10 combined-stage title occupies BOTH slots",
          stage_tokens("Stage 7+8 Verification (Dev Testing + QA) — slug (#271)")[0] == [7, 8])
    check("M3 T-10 sub-phase title is not a slot occupant",
          stage_tokens("Stage 5 Phase A6.5 · slug · Adversarial Design Review")[1] is True)
    check("M3 T-10 Stage-4 near-miss is release-scoped by stage number",
          stage_tokens("Stage 4 Release Planning — agent-finops-intelligence (#293)")[0] == [4]
          and 4 in RELEASE_SCOPED_STAGES)

    # The combined-stage title must actually SUPPRESS the spurious MISSING 8 —
    # the assertion above only proves the tokenizer, not the consequence.
    comb = _complete()
    comb["members"] = [n for n in comb["members"]
                       if not str(n["title"]).startswith(("Stage 7", "Stage 8"))]
    comb["members"].append(_st(777, "Stage 7+8 Verification — #10 (slug)", _mk_i(10)))
    _, adv_c, _, _, _, _, _ = analyse_m3([comb])
    check("M3 T-10 combined-stage occupies both per-issue slots (no spurious MISSING 8)",
          not [r for r in adv_c if r[1] == "MISSING"])

    # fx_unlabelled — five slug-bearing unlabelled Stage-4 titles fire; the
    # #3826-shaped prose title (no slug, no #N) stays silent. That control is the
    # whole point of the narrowing: a bare `^Stage \d+` predicate false-positives
    # on a real work item whose title merely begins with a stage word.
    unl_members = [_st(3443 + i, "Stage 4 Release Planning — narrow-slug", labels=("bug",))
                   for i in range(5)]
    unl_members.append(_st(3826,
                           "Stage 5-9 review and the Stage-9 readiness scan miss the "
                           "required issue-reference", labels=("bug",)))
    unl_members.append(_st(400, "Stage 9 Plan Review — narrow-slug (release-scoped)", MK_R))
    lb_u, _, _, _, _, _, _ = analyse_m3([_ms(7, "narrow-slug", unl_members)])
    unl_rows = [r for r in lb_u if r[1] == "UNLABELLED"]
    check("M3 fx_unlabelled: five slug-bearing unlabelled Stage-4 titles fire",
          len(unl_rows) == 5)
    check("M3 fx_unlabelled: the #3826-shaped prose title is NOT flagged (live control)",
          ("7", "UNLABELLED", "#3826") not in lb_u)

    # fx_remediation — two Stage-9 release-scoped sub-tasks (a remediation re-run)
    # must NOT read as a duplicate: the slot requires >=1 occupant, never ==1.
    rem = _complete()
    rem["members"].append(_st(4426, "Stage 9 Plan Review — slug (release-scoped)", MK_R))
    lb_r, adv_r, _, _, _, _, _ = analyse_m3([rem])
    check("M3 fx_remediation: a second Stage-9 sub-task is not a duplicate",
          len(lb_r) == 0 and len(adv_r) == 0)

    # fx_lateadd — a work item milestoned AFTER the scaffold has per-issue gaps,
    # and they must be ADVISORY: membership currency cannot distinguish a late add
    # from an omission, so gating on it would fail a legitimate state.
    late = _complete()
    late["members"].append(_st(11, "A late-added work item", labels=("bug",)))
    lb_l, adv_l, _, _, _, _, _ = analyse_m3([late])
    check("M3 fx_lateadd: per-issue gaps are ADVISORY, COUNT_M3 stays 0",
          len(lb_l) == 0 and len([r for r in adv_l if r[1] == "MISSING"]) == 4)

    # M3-POLICY — an UNMARKERED milestone's missing release-scoped slots are a
    # policy assertion about a canonicalization, not a defect detection, so they
    # never enter COUNT_M3. Stages 10/11 stay POLICY even when markered: they
    # compress for git-native releases.
    pre = _ms(290, "governance-hardening",
              [_st(20, "A work item", labels=("bug",)),
               _st(300, "Stage 5 · #20 · Solutioning"),
               _st(301, "Stage 6 · #20 · Engineering"),
               _st(302, "Stage 7 · #20 · Dev Testing"),
               _st(303, "Stage 8 · #20 · QA Testing"),
               _st(304, "Stage 4 Release Planning — governance-hardening")])
    lb_pre, adv_pre, pol_pre, _, _, mk_pre, _ = analyse_m3([pre])
    check("M3 pre-cutover: unmarkered milestone emits POLICY, never load-bearing",
          len(lb_pre) == 0 and len(pol_pre) == 5)
    check("M3 pre-cutover: SCAFFOLD_MARKER reports 0 adoption rather than green",
          mk_pre == [("290", "0/5")])
    check("M3 pre-cutover: per-issue rows carry the [LEGACY-TITLE-INFERRED] tag",
          all("[LEGACY-TITLE-INFERRED]" in r[2] for r in adv_pre) if adv_pre else True)
    markered_10_11 = _complete()
    markered_10_11["members"] = [n for n in markered_10_11["members"]
                                 if not str(n["title"]).startswith(("Stage 10", "Stage 11"))]
    lb_c, _, pol_c, _, _, _, _ = analyse_m3([markered_10_11])
    check("M3 compressible stages 10/11 stay POLICY even on a markered milestone",
          len(lb_c) == 0 and sorted(r[2] for r in pol_c) == ["10", "11"])

    # T-15 — falsifiability of the advisory legacy heuristic. A heuristic whose
    # only test is "it returned something" is not tested: assert a NON-ZERO
    # attribution count over the bare em-dash grammar the parser was not written
    # from, and assert it returns nothing on a title carrying no parent at all.
    bare = ["Stage 5 Solutioning — #3441 human-process build",
            "Stage 6 Engineering — #3442 human-process build",
            "Stage 7 Dev Testing — #3443 human-process build"]
    attributed = [t for t in bare if legacy_parent_from_title(t)]
    check("M3 T-15 legacy heuristic attributes the bare grammar (non-zero)",
          len(attributed) == 3)
    check("M3 T-15 legacy heuristic returns nothing when no parent ref is present",
          legacy_parent_from_title("Stage 5 Solutioning — governance-ci-checks") == [])

    # UNMARKED is reported, never coerced: a per-issue stage scaffolded in the
    # release-scoped shape has no parent to infer and must not be assumed either way.
    unm = _ms(266, "governance-ci-checks",
              [_st(30, "A work item", labels=("bug",)),
               _st(3652, "Stage 5 Solutioning — governance-ci-checks")])
    _, _, _, _, _, mk_unm, _ = analyse_m3([unm])
    check("M3 UNMARKED sub-tasks are reported as unmarked, not coerced",
          mk_unm == [("266", "0/1")])

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


def collect_m3(repo, milestones, stage_titled):
    """Build analyse_m3()'s input, fetching detail ONLY for firing milestones.

    The fire predicate is evaluated entirely from the single stage-title search —
    both `attached` (stage-titled issues whose milestone IS this one) and
    `orphans` (naming the slug, milestone is not this one) come from it — so a
    non-firing milestone costs zero extra calls. Detail (body, for the scope
    marker; work items, for the per-issue slots) is fetched only after the
    milestone has already fired.
    """
    out = []
    for ms in milestones:
        num = ms.get("number")
        slug = ms.get("title") or ""
        attached = [n for n in stage_titled
                    if str(n.get("milestone")) == str(num) and stage_tokens(n.get("title"))[0]]
        orphans = orphans_for(slug, num, stage_titled)
        if not attached and not orphans:
            out.append({"number": num, "slug": slug, "members": [], "orphans": []})
            continue
        fetched_slug, nodes = fetch_m3_members(repo, num)
        out.append({"number": num, "slug": fetched_slug or slug,
                    "members": nodes, "orphans": orphans})
    return out


def emit_m3(load_bearing, advisory, policy, info, denom, marker, skipped):
    out = []
    for ms_num in skipped:
        out.append("SKIP_MS\t" + str(ms_num) + "\tnot-yet-scaffolded")
    for row in load_bearing:
        out.append("M3\t" + "\t".join(str(c) for c in row))
    for row in advisory:
        out.append("M3-ADV\t" + "\t".join(str(c) for c in row))
    for row in policy:
        out.append("M3-POLICY\t" + "\t".join(str(c) for c in row))
    for row in info:
        out.append("M3-INFO\t" + "\t".join(str(c) for c in row))
    for row in denom:
        out.append("M3_DENOM\t" + "\t".join(str(c) for c in row))
    for row in marker:
        out.append("SCAFFOLD_MARKER\t" + "\t".join(str(c) for c in row))
    out.append("COUNT_M3\t" + str(len(load_bearing)))
    out.append("COUNT_M3_ADV\t" + str(len(advisory)))
    return out


def run_m3_only(args):
    """The `--leg M3` / `--milestone` path. M1 and M2 are not run and not touched."""
    if args.fixture:
        try:
            with open(args.fixture, "r", encoding="utf-8") as fh:
                data = json.load(fh)
            m3_input = data["m3"]
        except (OSError, ValueError, KeyError) as exc:
            print("ERROR\tM3 fixture unreadable: " + str(exc), file=sys.stderr)
            return 3
    else:
        repo = _derive_repo(args.repo)
        if not repo:
            print("ERROR\t--repo not supplied and git remote origin unresolved",
                  file=sys.stderr)
            return 3
        try:
            stage_titled = fetch_stage_titled(repo)
            if args.milestone:
                ms = fetch_milestone_by_slug(repo, args.milestone)
                milestones = [ms]
            else:
                milestones = fetch_milestones(repo)
            m3_input = collect_m3(repo, milestones, stage_titled)
        except RuntimeError as exc:
            print("ERROR\t" + str(exc), file=sys.stderr)
            return 3

    print("\n".join(emit_m3(*analyse_m3(m3_input))))
    # M3 NEVER drives the exit code. It routes through deploy.sh's
    # `flag_advisory_only` emitter, which is structurally incapable of enforcement
    # (no mode case, no enforce branch, no ISSUES increment) — an exit-1 here would
    # smuggle enforcement back in through the one door that is supposed to have none.
    return 0


def main():
    ap = argparse.ArgumentParser(description="Milestone-epic membership check.")
    ap.add_argument("--repo", default=None,
                    help="owner/name; derived from git remote origin when omitted")
    ap.add_argument("--output-format", choices=("tsv",), default="tsv")
    ap.add_argument("--fixture", help="JSON {milestones:[],issues:[]} — drives both legs offline")
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--milestone",
                    help="slug or number — scope M3 to ONE milestone, any state "
                         "(the Procedure 1 Step 6.5 invocation)")
    ap.add_argument("--leg", choices=("M1", "M2", "M3", "all"), default="all",
                    help="which leg(s) to run; default all")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    if args.milestone or args.leg == "M3":
        return run_m3_only(args)

    members_all = None
    m3_input = None
    if args.fixture:
        try:
            with open(args.fixture, "r", encoding="utf-8") as fh:
                data = json.load(fh)
            milestones, issues = data["milestones"], data["issues"]
            # Optional: a fixture may supply an explicit all-states membership
            # map to drive M2; absent it, M2 falls back to the OPEN set.
            members_all = data.get("members_all")
            m3_input = data.get("m3")
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
            m3_input = collect_m3(repo, milestones, fetch_stage_titled(repo))
        except RuntimeError as exc:
            print("ERROR\t" + str(exc), file=sys.stderr)
            return 3

    m1, m2, skipped, exempted, declared = analyse(milestones, issues, members_all)
    # `--leg` restricts what is REPORTED, never what is computed: analyse() is one
    # pure join and splitting it would give the legs two membership bases to drift
    # apart. Default `all` emits every row, so the pre-existing output is unchanged.
    if args.leg == "M1":
        m2 = []
    elif args.leg == "M2":
        m1 = []
    if args.leg in ("M1", "M2"):
        m3_input = None

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
    if m3_input is not None:
        out.extend(emit_m3(*analyse_m3(m3_input)))
    print("\n".join(out))
    # M3 is deliberately absent from this expression: it is advisory by
    # construction and must not move the exit code M1/M2's severity split reads.
    return 1 if (m1 or m2) else 0


if __name__ == "__main__":
    sys.exit(main())
