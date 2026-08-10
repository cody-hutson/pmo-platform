#!/usr/bin/env python3
"""check-milestone-epic-membership.py — milestone↔issue-population invariants (Check 56).

Legs with DELIBERATELY DIFFERENT severities. The enumeration below is the
authority for which legs exist; no count is stated here, because a stated count
goes stale the next time a leg lands and re-arms the same drift it documents.
The subject is the milestone's issue population: which epic its cards sit under
(M1), whether its description matches its membership (M2), whether its pipeline
scaffold is complete (M3), and whether a pipeline sub-task escaped milestone
attachment altogether (M4).

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

      Each `named-not-member` ref carries ONE inline bracketed SUB-CLASS TOKEN
      naming why it is not a member, because "named but not a member" collapses
      states whose remedies are opposite: a ref sitting in ANOTHER milestone is a
      mis-scoped card, a ref in NO milestone is an unattached one, a ref that IS in
      this milestone but excluded from the reconciled set is a Scope line to drop,
      and a ref nothing could resolve is an unknown that must not be guessed at.
      See the M2 SUB-CLASS VOCABULARY block below the constants.

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

  M4 SUB-TASK MILESTONE ORPHANS (WARN-capable, on its OWN mode dial)
      A pipeline sub-task carrying NO milestone at all. Such an issue is
      invisible to every milestone-scoped query the pipeline runs — routing,
      close-out enumeration, gate-passage-proof lookup and this very check —
      so the release that created it silently loses part of its own scaffold
      while every surface still reports green.

      WHY THIS IS NOT AN EXTENSION OF M3. M3's orphan class asks a
      milestone-RELATIVE question: "does this stage title name slug X while
      sitting in some milestone other than X's?" It is evaluated by iterating
      milestones and matching the slug inside the title. A sub-task attached to
      NO milestone and naming NO slug is unreachable from every per-milestone
      iteration — measured over the full milestone set, the live cases match
      zero times, while a slug-bearing control title matches. This is the same
      structural argument this file already makes for M3's own limbs: a limb
      gated on the attribute its class destroys can never fire. M4 is therefore
      REPOSITORY-scoped, not milestone-scoped, and that is its whole reason to
      exist as a separate leg.

      WHY IT IS WARN-CAPABLE RATHER THAN STRUCTURALLY ADVISORY. M2 and M3 are
      advisory because each has a legitimate state its predicate cannot tell
      from a defect — a description that lags membership, a milestone that
      gained a card after scaffolding. M4 has no such state: the creating
      procedure stamps the milestone in the SAME issue-create call as the label
      and the scope marker, so a correctly-created sub-task is never
      momentarily milestone-less. The leg therefore takes M1's shape — routed
      through deploy.sh's `flag_warn_or_issue` behind an explicit mode branch,
      shipped in WARN so it cannot gate before shakedown, but keeping a real
      enforce path. Routing it through the structurally-non-escalating emitter
      would forfeit that graduation permanently.

      Its dial is its OWN (`milestone-subtask-orphan`, committed default
      `warn`), NOT the shared cohort dial. Sharing M1's would mean that
      flipping M1 to enforce after M1's shakedown silently graduates an
      unshaken-down leg by side effect.

      GATING SCOPE IS THE OPEN SUBSET. COUNT_M4_OPEN is the gate-eligible
      number; COUNT_M4_CLOSED is reported and never gated. A closed sub-task's
      missing milestone is history, not drift — M1's scope rule, adopted with
      M1's reason — and the historical backlog is owned by a separate backfill
      work item. Gating on it would make the leg permanently non-green on first
      landing, which is exactly how M3's docstring says a gate becomes a no-op.

      M4 NEVER MOVES THIS SCRIPT'S EXIT CODE. Severity lives entirely in
      deploy.sh's mode branch, as M3's does.

WHY M4 DOES NOT REUSE THE STAGE-TITLE FETCHER
---------------------------------------------
`fetch_stage_titled()` reads through `gh issue list --search`, and the GitHub
SEARCH API caps retrieval at 1,000 results regardless of the requested limit —
asking for more returns the same 1,000. Against this repository's stage-title
population that cap is live, not hypothetical, and a leg built on that fetcher
reports the milestone-less count it can SEE rather than the count that exists:
measured, an order of magnitude and change below the truth, with nothing in the
output saying so. That defect is disclosed and separately tracked against the
existing fetcher; M4 does not inherit it.

M4 therefore counts with `search/issues` `total_count`, which is EXACT and
uncapped — only the *item* pagination is capped, and when it binds, M4_SCAN
says `truncated` rather than letting a sampled finding list read as complete.
Counting and enumerating are separated deliberately: the counter stays correct
even when the finding list cannot be.

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
             detail's `named-not-member:` refs each carry ONE bracketed
             sub-class token: [elsewhere:ms#<N>] · [no-milestone] ·
             [member-excluded[:sub-task]] · [unresolved].
             `member-not-named:` refs are UNANNOTATED and byte-unchanged.
  EXEMPT     <leg> <detail>
  COUNT_M1   <n>                              FAIL-capable findings
  COUNT_M2   <n>                              warn-only findings — MILESTONE ROWS
  COUNT_M2_NNM <n>                            named-not-member REFS (NNM). A
                                              DIFFERENT denominator from COUNT_M2:
                                              that one counts rows, this one counts
                                              refs. Never conflate them.
  COUNT_M2_NNM_ELSEWHERE        <n>           \
  COUNT_M2_NNM_NO_MILESTONE     <n>            > always emitted, 0 included; the
  COUNT_M2_NNM_MEMBER_EXCLUDED  <n>            > four sum to COUNT_M2_NNM
  COUNT_M2_NNM_UNRESOLVED       <n>           /
  M2_REF_RESOLUTION <status> <requested> <resolved>
                                              status ∈ {not-needed, fetched,
                                              degraded, fixture}. `degraded` says
                                              the overlay call FAILED — distinct
                                              from `fetched` with 0 resolved, so a
                                              dead resolver is never rendered as a
                                              population that genuinely could not
                                              be resolved.
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
  M4         <issue>  <title>                 OPEN milestone-less sub-task. Rows
                                              are the GATE-ELIGIBLE subset only;
                                              the closed population is counted,
                                              never listed — it is history, and
                                              271-odd rows per run is noise that
                                              buries the live ones.
  M4-INFO    non-qualifying-rows-dropped <n>  rows the search returned that the
                                              in-process predicate rejected —
                                              non-zero means the QUERY drifted
                                              from the predicate, which is a
                                              defect in this file, not in the data
  COUNT_M4   <n>                              \  always emitted together, zeros
  COUNT_M4_OPEN   <n>                          > included; OPEN + CLOSED sum to
  COUNT_M4_CLOSED <n>                         /  COUNT_M4. Read with awk EXACT
                                              field equality — a grep for
                                              COUNT_M4 prefix-collides with both
                                              sub-counters, the same trap
                                              COUNT_M2_NNM already documents.
  M4_SCAN <status> <total> <enumerated> [<note>]
                                              status ∈ {fetched, truncated,
                                              degraded, fixture, not-run}.
                                                fetched   — counted and fully
                                                            enumerated
                                                truncated — count EXACT, finding
                                                            list is a SAMPLE
                                                            (item pagination hit
                                                            the search cap)
                                                degraded  — the call FAILED. The
                                                            population is
                                                            UNMEASURED, never 0
                                                not-run   — the --milestone /
                                                            --leg M3 short-circuit
                                                            did not reach M4
                                              `total` and `enumerated` are `-`
                                              whenever the population was not
                                              measured, and the COUNT_M4* rows
                                              are then ABSENT rather than zero:
                                              absence from a source is
                                              information, not a value. A
                                              consumer MUST branch on this row
                                              before reading any COUNT_M4* —
                                              reading the count alone consumes
                                              "nothing was examined" as "nothing
                                              was found".

  exit 0 — no findings on M1 or M2
  exit 1 — M1/M2 findings present (deploy.sh splits severity by leg). M3 and M4
           NEVER move the exit code: M3 is advisory by construction, and M4's
           severity lives entirely in deploy.sh's own mode branch.
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

# GitHub's search API returns at most this many RESULTS regardless of the
# requested page size or limit — a request for more silently yields the same
# ceiling. `total_count` is NOT subject to it, which is the whole reason M4
# counts with the count field and enumerates separately. When the ceiling binds,
# say so (`M4_SCAN truncated`) rather than letting a sample read as a census.
SEARCH_RESULT_CAP = 1000
SEARCH_PAGE_SIZE = 100

# ── M2 SUB-CLASS VOCABULARY ─────────────────────────────────────────────────
# The enum models the OUTCOME OF RESOLVING the ref, not the ref's milestone
# state. That is the distinction that makes it closed: "resolver could not
# answer" and "resolver answered 'no milestone'" are different facts, and an
# enum keyed on the ref's state has no cell for the first one.
#
#   elsewhere:ms#<N>        resolved — the ref belongs to a DIFFERENT milestone
#   no-milestone            resolved — the ref belongs to NO milestone
#   member-excluded[:sub-task]
#                           resolved to THIS milestone, but filtered out of the
#                           reconciled `live` set. `live` excludes sub-tasks, so
#                           on the live path that filter is the cause; the
#                           `:sub-task` qualifier is appended only when the
#                           member node CONFIRMS it, never asserted from the
#                           classification alone
#   unresolved              NOT resolved — no source could answer
#
# `unresolved` is a POSITIVELY EMITTED unknown, never a default. The same rule
# `scope_marker` states for the scaffold marker applies to the resolution
# question: absence from a source is information, not a value. Collapsing
# `unresolved` into `no-milestone` would reintroduce, one level down, the exact
# misclassification these tokens exist to remove.
#
# The kind is the segment BEFORE the first colon; anything after it is verified
# detail. That is what lets `elsewhere:ms#<N>` and `member-excluded:sub-task`
# carry an argument without widening the counted vocabulary.
M2_SUBCLASS_KINDS = ("elsewhere", "no-milestone", "member-excluded", "unresolved")
M2_SUBCLASS_TOKEN = re.compile(r'#\d+\[([a-z-]+)(?::[^\]]+)?\]')

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


def _gh_partial(args):
    """`gh` invocation that TOLERATES a non-zero exit when stdout still carries data.

    `gh api graphql` returns rc=1 whenever ANY alias in a batched query fails to
    resolve — while populating `data` for every alias that DID resolve. `_gh()`
    above raises on non-zero rc, so routing a batched aliased query through it
    would abort the whole check on one rotted reference.

    This is a SIBLING, not a loosening: five other fetchers depend on `_gh()`'s
    raise-on-rc contract, and widening it to serve one partial-tolerant caller
    would trade a loud failure for a silent one everywhere else. Returns stdout
    only; the caller decides what an undecodable or empty stream means.
    """
    proc = subprocess.run(args, capture_output=True, text=True)
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


def _parse_ref_milestone_payload(text):
    """PURE. Parse a batched aliased issue→milestone response into the OVERLAY map.

    The overlay is TRI-STATE, and the tri-state is the whole contract:

        {"<ref>": "<milestone-number>"}  the ref resolved AND carries a milestone
        {"<ref>": None}                  the ref resolved AND carries NO milestone
        key ABSENT                       the ref did NOT resolve

    A map built the obvious way — comprehending only the nodes whose `milestone`
    is truthy — drops the middle row into the third, and every closed,
    milestone-less reference then reads `unresolved`. That is inference-by-absence
    one level below the misclassification the sub-class tokens exist to remove,
    so the null-milestone key is written explicitly rather than filtered out.

    Returns None — distinct from an empty dict — when the response was absent or
    undecodable. Empty-but-decodable means "the call worked and resolved nothing";
    None means "the call did not work". Only the caller can tell those apart, and
    only if this function keeps them apart.
    """
    if not (text or "").strip():
        return None
    try:
        docs = list(iter_json_docs(text))
    except ValueError:
        return None
    out = {}
    try:
        for payload in docs:
            repo_node = ((payload or {}).get("data") or {}).get("repository") or {}
            for alias, node in repo_node.items():
                # A ref that did not resolve arrives as `<alias>: null` plus an
                # entry in `errors[]`. Skipping it is what makes its key ABSENT.
                if not alias.startswith("r") or not isinstance(node, dict):
                    continue
                number = node.get("number")
                if number is None:
                    continue
                milestone = node.get("milestone")
                out[str(number)] = (str(milestone.get("number"))
                                    if isinstance(milestone, dict) else None)
    except (AttributeError, TypeError):
        return None
    return out


def fetch_ref_milestones(repo, refs):
    """Deferred, batched ref→milestone overlay. Returns (ok, {ref: ms-or-None}).

    ONE GraphQL document of `r<N>: issue(number:N){ number milestone{ number } }`
    aliases, chunked at 100 — not an N+1 per-ref fan-out, which this module's own
    docstring rules out. It exists because the two FREE indices are incomplete BY
    CONSTRUCTION: the membership map is open-milestone-scoped and the issue index
    is OPEN-scoped, so a closed issue sitting in a closed milestone is invisible
    to both, and a zero-fetch design would report it `no-milestone` — the exact
    misclassification the sub-class split exists to eliminate.

    STRUCTURALLY CANNOT RAISE, and that is expressed as a MECHANISM rather than a
    docstring promise: the body is wrapped, so no escape is possible. The reason
    it matters is the caller's exit-code fork — `main()`'s live-fetch guard
    catches RuntimeError only, so any other exception exits 1 with a traceback on
    the same stream deploy.sh parses as TSV, which then reads as a clean check.
    A property no line enforces is not a fail-posture.

    `ok` is the DEGRADED-vs-CLEAN discriminator. A call that failed and a call
    that succeeded while resolving nothing both return an empty map; an output
    that cannot tell those apart is the fail-open shape this check must not have.
    Callers degrade to the free indices and then to `unresolved` either way — the
    flag changes what is REPORTED, never what is computed.
    """
    refs = sorted(set(str(r) for r in refs), key=int)
    if not refs:
        return True, {}
    owner, _, name = repo.partition("/")
    mapping, ok = {}, True
    try:
        for start in range(0, len(refs), 100):
            chunk = refs[start:start + 100]
            aliases = "\n".join(
                "    r%s: issue(number:%s){ number milestone{ number } }" % (r, r)
                for r in chunk)
            query = ("query($owner:String!,$name:String!){\n"
                     "  repository(owner:$owner,name:$name){\n"
                     + aliases + "\n  }\n}\n")
            parsed = _parse_ref_milestone_payload(
                _gh_partial(["gh", "api", "graphql",
                             "-f", "query=" + query,
                             "-F", "owner=" + owner, "-F", "name=" + name]))
            if parsed is None:
                ok = False
                continue
            mapping.update(parsed)
    except Exception:  # noqa: BLE001 — deliberate; see the docstring
        return False, mapping
    return ok, mapping


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


def m4_query(repo):
    """The M4 population query. ONE definition, shared by the count and the
    enumeration, so the number and the list can never be answered by two
    different predicates."""
    return ("repo:%s is:issue no:milestone label:%s,%s"
            % (repo, SUB_TASK_LABEL, SUB_TASK_LEGACY_LABEL))


def _m4_node(item):
    """Normalise a REST `search/issues` item into this file's internal node shape.

    The search endpoint returns `labels` as a FLAT LIST and the GraphQL fetchers
    return `{nodes: [...]}`. Normalising here is what lets `is_sub_task_family`
    — one predicate, one definition — serve both transports.
    """
    return {
        "number": item.get("number"),
        "title": item.get("title") or "",
        "state": str(item.get("state") or "").lower(),
        "labels": {"nodes": [{"name": l.get("name", "")}
                             for l in (item.get("labels") or [])]},
        "milestone": (item.get("milestone") or {}).get("number"),
    }


def _search_page(query, page):
    """One `search/issues` page. Returns the decoded payload, or None on failure.

    NEVER RAISES, deliberately. M4 reports its own degradation through M4_SCAN
    rather than aborting the run: a search outage must not take the M1 and M2
    legs down with it, and a leg that cannot report its own failure reports it
    as clean. Routed through `_gh_partial` for the same reason — the rc is not
    the signal here; the presence of a decodable payload carrying `total_count`
    is.
    """
    raw = _gh_partial(["gh", "api", "-X", "GET", "search/issues",
                       "-f", "q=" + query,
                       "-f", "per_page=" + str(SEARCH_PAGE_SIZE),
                       "-f", "page=" + str(page)])
    if not (raw or "").strip():
        return None
    try:
        payload = json.loads(raw)
    except ValueError:
        return None
    if not isinstance(payload, dict) or "total_count" not in payload:
        return None
    return payload


def fetch_m4(repo):
    """Milestone-less sub-task-family population. Returns
    (status, total, open_total, items).

    COUNTED by `total_count`, ENUMERATED separately — see the module docstring
    for why the stage-title fetcher is not reused. Both sub-counters come from
    their own exact counts rather than from the enumeration, so they stay
    correct (and keep summing to the total) even when the item pagination is
    truncated.

    On any failure the status is `degraded` and the counts are NOT returned as
    zeros — the caller emits no COUNT_M4* rows at all in that case, because a
    zero here is indistinguishable from a genuinely empty population and that
    confusion is the exact defect this leg exists to detect.
    """
    query = m4_query(repo)
    first = _search_page(query, 1)
    if first is None:
        return ("degraded", None, None, [])
    total = int(first.get("total_count") or 0)
    items = list(first.get("items") or [])
    page = 2
    while len(items) < min(total, SEARCH_RESULT_CAP):
        payload = _search_page(query, page)
        if payload is None:
            return ("degraded", None, None, [])
        batch = list(payload.get("items") or [])
        if not batch:
            break
        items.extend(batch)
        page += 1
    open_payload = _search_page(query + " is:open", 1)
    if open_payload is None:
        return ("degraded", None, None, [])
    open_total = int(open_payload.get("total_count") or 0)
    status = "fetched" if len(items) >= total else "truncated"
    return (status, total, open_total, [_m4_node(i) for i in items])


def analyse_m4(total, open_total, items):
    """Pure join. Returns (open_rows, counts, dropped).

    Rows are the OPEN subset ONLY — the gate-eligible set. A closed sub-task's
    missing milestone is history rather than drift (M1's scope rule, adopted
    with M1's reason), and the historical population belongs to the separate
    backfill work item, not to this leg's finding list.

    `dropped` counts rows the search returned that the in-process predicate
    rejected. It should always be 0; a non-zero value means the query and the
    predicate have drifted apart, which is a defect in this file. It is emitted
    rather than swallowed.
    """
    qualifying = [n for n in items if m4_qualifies(n)]
    dropped = len(items) - len(qualifying)
    open_rows = [(str(n.get("number")), n.get("title") or "")
                 for n in qualifying if n.get("state") == "open"]
    open_rows.sort(key=lambda r: int(r[0]) if r[0].isdigit() else 0)
    closed_total = total - open_total
    return open_rows, (total, open_total, closed_total), dropped


def emit_m4(status, rows, counts, dropped, enumerated, note=""):
    """M4's TSV block.

    When the population was NOT measured (`degraded` / `not-run`), the counters
    are OMITTED and the scan row carries `-` in both numeric fields. Emitting
    `COUNT_M4 0` there would render an unmeasured population as an empty one —
    the false-green this leg exists to eliminate, reproduced inside the catcher.
    """
    out = []
    if counts is None:
        out.append("M4_SCAN\t%s\t-\t-%s" % (status, ("\t" + note) if note else ""))
        return out
    total, open_total, closed_total = counts
    for num, title in rows:
        out.append("M4\t" + num + "\t" + title)
    if dropped:
        out.append("M4-INFO\tnon-qualifying-rows-dropped\t" + str(dropped))
    out.append("COUNT_M4\t" + str(total))
    out.append("COUNT_M4_OPEN\t" + str(open_total))
    out.append("COUNT_M4_CLOSED\t" + str(closed_total))
    out.append("M4_SCAN\t%s\t%d\t%d%s"
               % (status, total, enumerated, ("\t" + note) if note else ""))
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


def m4_qualifies(node):
    """M4's population predicate: sub-task family AND no milestone.

    The search query already carries both clauses, so re-asserting them here
    looks redundant. It is not, for two reasons.

    It makes the leg's PRECISION testable offline. Without a predicate in
    process, the only thing separating a near-miss from a finding is a query
    string, and no self-test can reach a query string. With it, the two
    discriminating near-misses are exercisable as data: a sub-task that DOES
    carry a milestone (differs in exactly the milestone property), and a
    milestone-less issue that is NOT a sub-task but whose TITLE contains the
    words "sub-task" (differs in exactly the shape property, and is precisely
    what a substring predicate would wrongly flag).

    And it fails CLOSED against query drift. If the query is ever widened or
    mistyped, a milestoned sub-task or a milestone-less work item is dropped
    here rather than promoted to a finding — and the drop is COUNTED and
    emitted, because a silently-filtered row would hide the very drift this
    guard exists to catch.

    Reads the milestone field with an explicit `is None` test. A milestone
    number of 0 is not a real GitHub milestone, but a falsiness test would also
    swallow it, and this leg's entire subject is the difference between "has no
    milestone" and "has a milestone I failed to read".
    """
    return is_sub_task_family(node) and node.get("milestone") is None


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
    that is its only available signal. The instance that motivated this limb was
    milestone #275 `template-system-governance-wave-1`, whose sole stage-titled
    issue #3848 was unlabelled and correctly milestoned; that issue was one of 74
    remediated by the `sub-task` label backfill, so the case is HISTORICAL rather
    than live. The limb is not thereby obsolete — it fires on a SHAPE, the backfill
    cleared one population, and the shape recurs on any future unlabelled,
    correctly-milestoned stage title. `fx_275` below preserves the shape as a
    fixture precisely so the guard does not depend on a live specimen existing.
    Limb 3 reuses the narrowed predicate the `UNLABELLED` loop itself applies
    (`unlabelled_stage_titled`), so the limb and
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
        # been skipped upstream (the motivating instance: #3848 on milestone #275,
        # since remediated by the `sub-task` label backfill — historical, not live).
        for wi in unlabelled:
            load_bearing.append((ms_num, "UNLABELLED", "#" + str(wi.get("number"))))

        expected = len(RELEASE_SCOPED_STAGES) + len(work_items) * len(PER_ISSUE_STAGES)
        denom.append((ms_num, str(len(work_items)), str(expected), str(len(attached))))
        if legacy_attributions:
            info.append((ms_num, "LEGACY-TITLE-INFERRED", str(legacy_attributions)))

    return load_bearing, advisory, policy, info, denom, marker, skipped


# ── M2 divergence + sub-class resolution ────────────────────────────────────

def _issues_by_milestone(issues):
    """{milestone-number: [open-issue-node, ...]}. Milestone-less issues dropped."""
    by_ms = {}
    for iss in issues:
        ms = iss.get("milestone")
        if not ms:
            continue
        by_ms.setdefault(str(ms.get("number")), []).append(iss)
    return by_ms


def m2_divergence(milestones, issues, members_all=None):
    """The M2 set difference, per milestone. ONE definition, TWO call sites.

    Returns {ms_num: (named, live, missing, extra)} for every milestone whose
    description names at least one card — `missing` = named but not a live
    member, `extra` = live member the description omits. Milestones naming no
    card are absent from the map, exactly as the join skips them.

    `analyse()` consumes it to build the emitted rows and `main()` consumes it to
    build the overlay's candidate set. THEY MUST NEVER DRIFT: a candidate set
    computed from a narrower difference than the one emitted would leave refs
    unresolvable for no reason, and a wider one would pay for refs nothing
    reports. Same rule, same reason, as `unlabelled_stage_titled` above — do not
    inline either call site.

    The returned tuple carries `named` and `live` as well as the two differences
    because the caller needs their cardinalities for the emitted row; returning
    only the differences would force `analyse()` to recompute both sets, which is
    precisely the second definition this helper exists to prevent.
    """
    by_ms = _issues_by_milestone(issues)
    out = {}
    for ms in milestones:
        ms_num = str(ms.get("number"))
        named = named_cards(ms.get("description") or "")
        if not named:
            continue
        # M2 membership spans ALL states (see the analyse docstring); the OPEN
        # `children` set stays M1's basis and is the offline/--fixture fallback.
        if members_all is None:
            live = set(str(c.get("number"))
                       for c in by_ms.get(ms_num, []) if not is_sub_task(c))
        else:
            live = set(str(c.get("number"))
                       for c in members_all.get(ms_num, []) if not is_sub_task(c))
        out[ms_num] = (named, live,
                       sorted(named - live, key=int),
                       sorted(live - named, key=int))
    return out


def m2_ref_indices(issues, members_all):
    """The two FREE ref→milestone indices — no network call, both incomplete.

    Returns (member_ms, open_ms):
      member_ms  {ref: (milestone-number, is-sub-task)} over every member of every
                 OPEN milestone, ALL issue states, sub-tasks INCLUDED. The
                 inclusion is load-bearing: the sub-task exclusion is exactly what
                 `member-excluded` has to be able to name, and an index that
                 pre-filtered them could not.
      open_ms    {ref: milestone-number-or-None} over every OPEN issue, INCLUDING
                 the milestone-less ones the by-milestone grouping drops.

    Both are incomplete by construction — open-milestone-scoped and OPEN-scoped
    respectively — which is the whole reason the deferred overlay exists. Their
    incompleteness is never read as an answer; it falls through to `unresolved`.
    """
    member_ms = {}
    for ms_num, nodes in (members_all or {}).items():
        for node in nodes:
            member_ms.setdefault(str(node.get("number")),
                                 (str(ms_num), is_sub_task(node)))
    open_ms = {}
    for iss in issues:
        ms = iss.get("milestone")
        open_ms[str(iss.get("number"))] = str(ms.get("number")) if ms else None
    return member_ms, open_ms


def _m2_classify(ref, ms_num, resolved_ms, member_ms):
    """Turn a RESOLVED milestone answer into a sub-class (kind, detail) pair."""
    if resolved_ms is None:
        return "no-milestone", None
    if str(resolved_ms) == str(ms_num):
        entry = member_ms.get(ref)
        # The qualifier is appended only when the member node confirms it. On the
        # live path the sub-task filter is the only thing that can remove a
        # confirmed member from `live`, but naming a cause the data did not show
        # is the habit this whole token set exists to break.
        return "member-excluded", ("sub-task" if entry and entry[1] else None)
    return "elsewhere", "ms#" + str(resolved_ms)


def resolve_named_ref(ref, ms_num, ref_milestone, member_ms, open_ms):
    """Why is `ref`, named in ms#<ms_num>'s Scope, absent from its reconciled set?

    Returns one (kind, detail) pair from the closed four-value enum documented at
    M2_SUBCLASS_KINDS. Pure — every source is an already-materialised map.

    Resolution order, most-complete source first:
      1. `ref_milestone` — the deferred overlay, TRI-STATE (see
         `_parse_ref_milestone_payload`). A present key is authoritative whether
         its value is a milestone number or None.
      2. `member_ms` — any-state member of an OPEN milestone.
      3. `open_ms` — any OPEN issue, including one carrying no milestone.
      4. `unresolved`.

    ABSENCE FROM THE OVERLAY IS NEVER `no-milestone`. It falls through to the two
    free indices and, failing those, to the positively-emitted unknown. The
    overlay says "no milestone" by holding the key with a None value, never by
    not holding the key — those are different facts and the caller must be able
    to tell them apart.
    """
    ref = str(ref)
    if ref_milestone and ref in ref_milestone:
        return _m2_classify(ref, ms_num, ref_milestone[ref], member_ms)
    if ref in (member_ms or {}):
        return _m2_classify(ref, ms_num, member_ms[ref][0], member_ms)
    if open_ms and ref in open_ms:
        return _m2_classify(ref, ms_num, open_ms[ref], member_ms)
    return "unresolved", None


def m2_subclass_token(kind, detail):
    """Render one inline bracketed sub-class token. Kind before the colon."""
    return "[%s]" % kind if detail is None else "[%s:%s]" % (kind, detail)


def m2_subclass_counts(m2):
    """Sub-class tally over the EMITTED M2 rows. Pure — takes analyse()'s output.

    Returns (total, {kind: n}). Reading the emitted rows rather than an internal
    accumulator is deliberate: the counters then describe what an operator can
    actually see, and a token that stops being emitted stops being counted.

    COUNTS REFS. `COUNT_M2` counts milestone ROWS. Different denominators — the
    invariant is stated against this total and never against `COUNT_M2`.

    `total` counts every token found, while the buckets count only the four known
    kinds, so `sum(buckets) == total` is a real assertion about the enum staying
    closed rather than an arithmetic tautology. `member-not-named` refs carry no
    token and are therefore invisible to this tally by construction.
    """
    counts = dict((kind, 0) for kind in M2_SUBCLASS_KINDS)
    total = 0
    for row in m2:
        for kind in M2_SUBCLASS_TOKEN.findall(row[3]):
            total += 1
            if kind in counts:
                counts[kind] += 1
    return total, counts


def analyse(milestones, issues, members_all=None, ref_milestone=None):
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

    `ref_milestone` is the optional deferred ref→milestone overlay, added the same
    way `members_all` was: an optional trailing argument, defaulting to the
    pre-existing behaviour. It drives the `named-not-member` sub-class tokens and
    NOTHING else. IT IS INJECTED, NEVER FETCHED HERE — keeping this join pure and
    I/O-free is what keeps `--self-test` offline and credential-free, which is a
    CI roster invariant. Return arity is unchanged.
    """
    by_ms = _issues_by_milestone(issues)
    divergence = m2_divergence(milestones, issues, members_all)
    member_ms, open_ms = m2_ref_indices(issues, members_all)

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
        # The set difference comes from m2_divergence() — the SAME binding main()
        # uses to build the overlay's candidate set. Do not recompute it here.
        entry = divergence.get(ms_num)
        if entry is None:
            continue
        named, live, missing, extra = entry
        if missing or extra:
            detail = []
            if missing:
                # Each ref carries ONE sub-class token. `member-not-named` below
                # is deliberately left unannotated and byte-identical.
                detail.append("named-not-member: " + ",".join(
                    "#%s%s" % (n, m2_subclass_token(
                        *resolve_named_ref(n, ms_num, ref_milestone,
                                           member_ms, open_ms)))
                    for n in missing))
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

    # ── M2 named-not-member SUB-CLASS tokens ─────────────────────────────
    # Every arm below pairs a subject with a discriminating control, because the
    # failure this token set exists to prevent is a plausible-looking wrong
    # answer, not a crash. An arm whose control also passes proves nothing.

    def _m2_detail(milestones, issues, members=None, overlay=None):
        _, rows, _, _, _ = analyse(milestones, issues, members, overlay)
        return rows[0][3] if rows else ""

    # T-A: the ref is a member of a DIFFERENT milestone, resolvable for free.
    ms = [{"number": 2, "description": "### Scope\n1. #10 — a\n2. #77 — b\n"}]
    members = {"2": [{"number": 10, "labels": {"nodes": []}}],
               "3": [{"number": 77, "labels": {"nodes": []}}]}
    check("M2 T-A elsewhere token names the other milestone",
          "#77[elsewhere:ms#3]" in _m2_detail(ms, [_iss(10, ms=2)], members))

    # T-B: the ref is an OPEN issue carrying no milestone — the free open-issue
    # index answers, and the answer is a milestone-less one.
    ms = [{"number": 2, "description": "### Scope\n1. #10 — a\n2. #88 — b\n"}]
    members = {"2": [{"number": 10, "labels": {"nodes": []}}]}
    check("M2 T-B no-milestone token from the open-issue index",
          "#88[no-milestone]" in
          _m2_detail(ms, [_iss(10, ms=2), _iss(88)], members))

    # T-B2 + control: THE MODAL LIVE CASE — a closed, milestone-less ref, invisible
    # to both free indices, resolvable ONLY by an overlay entry whose value is
    # None. A map that drops null-milestone keys passes every other arm here and
    # fails this one; that is the entire reason it exists.
    ms = [{"number": 2, "description": "### Scope\n1. #10 — a\n2. #90 — b\n"}]
    members = {"2": [{"number": 10, "labels": {"nodes": []}}]}
    check("M2 T-B2 overlay key with a NULL value yields no-milestone",
          "#90[no-milestone]" in
          _m2_detail(ms, [_iss(10, ms=2)], members, {"90": None}))
    check("M2 T-B2-ctrl the same ref with the overlay entry REMOVED is unresolved",
          "#90[unresolved]" in _m2_detail(ms, [_iss(10, ms=2)], members, {}))

    # T-C: in neither free index and no overlay entry → the positively-emitted
    # unknown. Never coerced to no-milestone.
    ms = [{"number": 2, "description": "### Scope\n1. #10 — a\n2. #99 — b\n"}]
    check("M2 T-C unresolved token when nothing can answer",
          "#99[unresolved]" in
          _m2_detail(ms, [_iss(10, ms=2)],
                     {"2": [{"number": 10, "labels": {"nodes": []}}]}))

    # T-D + control: the overlay resolves a ref BOTH free indices miss — the live
    # closed-issue-in-a-closed-milestone shape. The control drops the overlay and
    # must degrade to unresolved, which is what proves the overlay is load-bearing
    # rather than shadowing an answer a free index already had.
    ms = [{"number": 2, "description": "### Scope\n1. #10 — a\n2. #77 — b\n"}]
    members = {"2": [{"number": 10, "labels": {"nodes": []}}]}
    check("M2 T-D overlay resolves a ref both free indices miss",
          "#77[elsewhere:ms#4242]" in
          _m2_detail(ms, [_iss(10, ms=2)], members, {"77": "4242"}))
    check("M2 T-D-ctrl the same fixture without the overlay is unresolved",
          "#77[unresolved]" in _m2_detail(ms, [_iss(10, ms=2)], members, None))

    # T-G: an unresolved ref must not carry `no-milestone` anywhere on its token —
    # the anti-inference-by-absence control, asserted negatively.
    check("M2 T-G an unresolved ref is not reported as no-milestone",
          "no-milestone" not in _m2_detail(ms, [_iss(10, ms=2)], members, None))

    # T-H: the ref IS a member of THIS milestone but carries `sub-task`, so it is
    # filtered out of the reconciled set. Emitting `elsewhere:ms#<itself>` here
    # would send the operator hunting for the milestone they are already reading.
    ms = [{"number": 2, "description": "### Scope\n1. #10 — a\n2. #55 — b\n"}]
    members_st = {"2": [{"number": 10, "labels": {"nodes": []}},
                        {"number": 55,
                         "labels": {"nodes": [{"name": SUB_TASK_LABEL}]}}]}
    t_h = _m2_detail(ms, [_iss(10, ms=2)], members_st)
    check("M2 T-H a same-milestone excluded member reads member-excluded",
          "#55[member-excluded:sub-task]" in t_h)
    check("M2 T-H-ctrl it is NOT reported as elsewhere-to-itself",
          "elsewhere:ms#2" not in t_h)

    # T-E1 / T-E2: the counters. Deliberately two separate check() calls — a
    # mutation that zeroes every sub-count still satisfies the sum invariant
    # (0+0+0+0 == 0 is false only because the total moves with it), while a
    # mutation that MIS-BUCKETS leaves the sum intact and is caught only by T-E1.
    ms = [{"number": 2, "description":
           "### Scope\n1. #10 — a\n2. #77 — b\n3. #90 — c\n4. #55 — d\n5. #99 — e\n"}]
    members_mix = {"2": [{"number": 10, "labels": {"nodes": []}},
                         {"number": 55,
                          "labels": {"nodes": [{"name": SUB_TASK_LABEL}]}}],
                   "3": [{"number": 77, "labels": {"nodes": []}}]}
    _, m2_mix, _, _, _ = analyse(ms, [_iss(10, ms=2)], members_mix, {"90": None})
    mix_total, mix_counts = m2_subclass_counts(m2_mix)
    check("M2 T-E1 one ref of each sub-class buckets 1/1/1/1",
          mix_total == 4 and mix_counts["elsewhere"] == 1
          and mix_counts["no-milestone"] == 1
          and mix_counts["member-excluded"] == 1
          and mix_counts["unresolved"] == 1)
    check("M2 T-E2 the four sub-counts sum to the named-not-member total",
          sum(mix_counts.values()) == mix_total)

    # T-F: the OPPOSITE leg is byte-identical. The 4-tuple is hardcoded rather
    # than recomputed, so a refactor of the set difference cannot quietly agree
    # with itself.
    ms = [{"number": 2, "description": "### Scope\n1. #10 — a\n"}]
    _, m2_opp, _, _, _ = analyse(ms, [_iss(10, ms=2)],
                                 {"2": [{"number": 10, "labels": {"nodes": []}},
                                        {"number": 12, "labels": {"nodes": []}}]})
    check("M2 T-F member-not-named output is byte-identical",
          m2_opp == [("2", "1", "2", "member-not-named: #12")])

    # T-F2: a BOTH-DIRECTIONS row — the two-segment join, which no pre-existing
    # fixture covered and which is the one path where field 3's bytes genuinely
    # move. Full-string equality, not a substring.
    ms = [{"number": 2, "description": "### Scope\n1. #10 — a\n2. #77 — b\n"}]
    _, m2_both, _, _, _ = analyse(ms, [_iss(10, ms=2)],
                                  {"2": [{"number": 10, "labels": {"nodes": []}},
                                         {"number": 12, "labels": {"nodes": []}}]},
                                  {"77": "4242"})
    check("M2 T-F2 both-direction row keeps the member-not-named segment intact",
          m2_both == [("2", "2", "2",
                       "named-not-member: #77[elsewhere:ms#4242]; "
                       "member-not-named: #12")])

    # T-I: `m2_divergence` has TWO call sites (the join and the overlay's
    # candidate set) and they must never drift. Asserted directly rather than
    # trusted: the difference the helper reports is the difference the row emits.
    div = m2_divergence(ms, [_iss(10, ms=2)],
                        {"2": [{"number": 10, "labels": {"nodes": []}},
                               {"number": 12, "labels": {"nodes": []}}]})
    check("M2 T-I m2_divergence agrees with the emitted row",
          div["2"][2] == ["77"] and div["2"][3] == ["12"])

    # T-J: the overlay parser's TRI-STATE contract, driven from a raw payload of
    # the exact shape the API returns. Resolved-with-milestone, resolved-with-none
    # and did-not-resolve are three outcomes, and the middle one is the one an
    # obvious implementation loses.
    payload = ('{"data":{"repository":{'
               '"r51":{"number":51,"milestone":{"number":4242}},'
               '"r52":{"number":52,"milestone":null},'
               '"rGHOST":null}},'
               '"errors":[{"type":"NOT_FOUND","path":["repository","rGHOST"]}]}')
    parsed = _parse_ref_milestone_payload(payload)
    check("M2 T-J overlay parse keeps a resolved milestone",
          parsed.get("51") == "4242")
    check("M2 T-J2 overlay parse keeps a NULL milestone as a present None value",
          "52" in parsed and parsed["52"] is None)
    check("M2 T-J3 overlay parse OMITS a ref that did not resolve",
          len(parsed) == 2)
    check("M2 T-J4 an undecodable overlay response is None, not an empty map",
          _parse_ref_milestone_payload("Traceback (most recent call last):")
          is None
          and _parse_ref_milestone_payload("") is None
          and _parse_ref_milestone_payload('{"data":{"repository":{}}}') == {})

    # T-K: the fetcher's DEGRADED-vs-CLEAN discriminator. Exercised WITHOUT a
    # network call by substituting the transport in-process — no subprocess, no
    # credentials, so the offline/stdlib-only invariant holds. This arm exists
    # because `ok` is the only thing that separates "the resolver died" from "the
    # resolver ran and resolved nothing", and an untested flag is not a control.
    global _gh_partial                        # restored in the finally below
    _real_transport = _gh_partial

    def _transport_raises(_args):
        raise OSError("transport exploded")

    try:
        _gh_partial = (lambda _args:
                       '{"data":{"repository":'
                       '{"r7":{"number":7,"milestone":null}}}}')
        ok_arm = fetch_ref_milestones("o/n", ["7"])
        _gh_partial = lambda _args: ""          # decoded nothing
        empty_arm = fetch_ref_milestones("o/n", ["7"])
        _gh_partial = _transport_raises         # blew up
        raised_arm = fetch_ref_milestones("o/n", ["7"])
        _gh_partial = _transport_raises
        no_refs_arm = fetch_ref_milestones("o/n", [])
    finally:
        _gh_partial = _real_transport

    check("M2 T-K a working overlay call reports ok with the tri-state map",
          ok_arm == (True, {"7": None}))
    check("M2 T-K-ctrl an undecodable overlay call reports DEGRADED, not empty-ok",
          empty_arm == (False, {}))
    check("M2 T-K2 a raising transport returns degraded instead of propagating",
          raised_arm == (False, {}))
    check("M2 T-K3 an empty candidate set makes no call and is not degraded",
          no_refs_arm == (True, {}))

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

    # fx_275 — the third fire limb. Modelled on milestone #275 `template-system-
    # governance-wave-1`, which held exactly one stage-titled artifact, #3848,
    # UNLABELLED and CORRECTLY MILESTONED. `attached` is label-gated and
    # `orphans_for()` excludes issues whose milestone IS this one, so limbs 1 and 2
    # both read zero and the milestone reported `SKIP_MS … not-yet-scaffolded` —
    # silencing the one class that was its only available signal.
    #
    # The live specimen is GONE — that issue was one of 74 remediated by the
    # `sub-task` label backfill — which is exactly why this fixture matters: the
    # data below is synthetic and constructed inline, so the guard survives the
    # remediation of every instance it was built to catch. A regression that
    # re-introduced the blind spot would still be caught here with no live
    # specimen in the repository.
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

    # ── M4 sub-task milestone orphans ────────────────────────────────────
    # The fixture is SYNTHETIC and constructed inline. It is deliberately NOT a
    # live issue: a live fixture would enter the very population COUNT_M4
    # counts (the check would be measuring its own test), would mutate a public
    # repository to manufacture the exact defect this leg exists to eliminate,
    # and would not survive the backfill that drains the population — it would
    # have to be either fixed (killing the test) or exempted forever. Synthetic
    # data makes the guard outlive every instance it was built to catch.
    def _m4_item(num, title, labels=("sub-task",), state="open", ms=None):
        """RAW `search/issues` item shape — flat `labels`, so the arms exercise
        the transport normaliser rather than starting downstream of it."""
        item = {"number": num, "title": title, "state": state,
                "labels": [{"name": l} for l in labels]}
        if ms is not None:
            item["milestone"] = {"number": ms}
        return item

    # Fixture titles carry NO issue reference, deliberately: a fabricated `#N`
    # in durable test data is a reference the issue-reference validity gate must
    # either resolve or fail on, and this leg reads labels and the milestone
    # field only — the title is illustrative and is never parsed by M4.
    #
    # TRUE POSITIVE — a milestone-less stage sub-task, the subject of the leg.
    fx_m4_hit = _m4_node(_m4_item(9001, "Stage 6 Engineering — a-release-slug"))
    check("M4 flags a milestone-less stage sub-task", m4_qualifies(fx_m4_hit))

    # CONTROL 1 — differs in EXACTLY ONE property: it HAS a milestone. This is
    # the shape of a correctly-created sub-task, and it isolates the milestone
    # property from the sub-task-shape property.
    fx_m4_milestoned = _m4_node(
        _m4_item(9002, "Stage 5 Solutioning — a-release-slug", ms=42))
    check("M4 control: a correctly-milestoned sub-task is NOT flagged",
          not m4_qualifies(fx_m4_milestoned))

    # CONTROL 2 — differs in EXACTLY ONE property: it is not a sub-task. It
    # carries NO milestone and its TITLE contains the words "sub-task", so a
    # substring predicate WOULD flag it. That is what makes it a discriminating
    # near-miss rather than a decorative one.
    fx_m4_titled = _m4_node(_m4_item(
        9003, "sub-task issues carry no milestone — backfill the owning release",
        labels=("improvement", "size:L")))
    check("M4 control: a milestone-less NON-sub-task naming 'sub-task' in its "
          "title is NOT flagged", not m4_qualifies(fx_m4_titled))
    check("M4 control 2 is discriminating: a substring predicate WOULD flag it",
          "sub-task" in fx_m4_titled["title"])

    # The legacy alias counts — M4 uses the WIDER family predicate, as M3 does,
    # because the scaffold is its subject.
    check("M4 counts the legacy `type:subtask` alias",
          m4_qualifies(_m4_node(_m4_item(9004, "Stage 7 Dev Testing — x",
                                         labels=("type:subtask",)))))

    # Rows are the OPEN subset; closed members are counted, never listed.
    m4_items = [fx_m4_hit, fx_m4_milestoned, fx_m4_titled,
                _m4_node(_m4_item(9005, "Stage 9 Plan Review — x", state="closed"))]
    m4_rows, m4_counts, m4_dropped = analyse_m4(10, 4, m4_items)
    check("M4 emits rows for the OPEN subset only",
          [r[0] for r in m4_rows] == ["9001"])
    check("M4 drops the two near-misses and COUNTS the drop", m4_dropped == 2)
    check("M4 sub-counters sum to COUNT_M4",
          m4_counts[1] + m4_counts[2] == m4_counts[0])

    # Precision probe: without it, "the controls are clean" is satisfied by a
    # predicate that finds nothing ever.
    check("M4 precision probe: the population is non-empty when it should be",
          len(m4_rows) > 0)

    m4_emit = emit_m4("fetched", m4_rows, m4_counts, m4_dropped, 4)
    check("M4 emits all three counters, zeros included",
          all(any(r.split("\t")[0] == k for r in m4_emit)
              for k in ("COUNT_M4", "COUNT_M4_OPEN", "COUNT_M4_CLOSED")))
    check("M4_SCAN reports status, total and enumerated",
          "M4_SCAN\tfetched\t10\t4" in m4_emit)
    check("M4-INFO surfaces the non-qualifying drop rather than swallowing it",
          any(r.startswith("M4-INFO\tnon-qualifying-rows-dropped\t2")
              for r in m4_emit))

    # awk EXACT-field-equality trap, asserted rather than merely documented: a
    # PREFIX match on COUNT_M4 hits all three counters, so a consumer reading
    # the total with `grep COUNT_M4` would silently read a sub-counter.
    check("M4 counter names prefix-collide (why consumers must use awk $1==)",
          len([r for r in m4_emit if r.startswith("COUNT_M4")]) == 3
          and len([r for r in m4_emit if r.split("\t")[0] == "COUNT_M4"]) == 1)

    # DEGRADED is a positively-emitted unknown: no counters at all, and `-` in
    # the numeric fields. A `COUNT_M4 0` here would render an unmeasured
    # population as an empty one — the exact false-green the leg exists to kill.
    m4_deg = emit_m4("degraded", [], None, 0, 0)
    check("M4 degraded emits NO counters and never a zero",
          m4_deg == ["M4_SCAN\tdegraded\t-\t-"])
    m4_nr = emit_m4("not-run", [], None, 0, 0, note="scope:m3-only")
    check("M4 not-run is positively emitted with its scope",
          m4_nr == ["M4_SCAN\tnot-run\t-\t-\tscope:m3-only"])

    # TRUNCATION: the count stays exact while the finding list becomes a sample,
    # and the status says so. This is the property that makes the counter safe
    # to trust when the search API's result cap binds.
    check("M4 status is truncated when enumeration falls short of the count",
          emit_m4("truncated", m4_rows, (3352, 7, 3345), 0,
                  SEARCH_RESULT_CAP)[-1]
          == "M4_SCAN\ttruncated\t3352\t1000")

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

    rows = emit_m3(*analyse_m3(m3_input))
    # M4 IS POSITIVELY REPORTED AS NOT RUN ON THIS PATH, never silently absent.
    # This is the Procedure 1 Step 6.5 invocation — the single moment in the
    # pipeline when a milestone-less sub-task is most likely to have JUST been
    # created — and it is milestone-scoped, so the repository-scoped M4 leg does
    # not fire here. A reader who saw no M4 rows and inferred "no findings"
    # would be consuming the absence of a measurement as a clean result, which
    # is the precise defect M4 exists to catch, reproduced inside the catcher.
    rows.extend(emit_m4("not-run", [], None, 0, 0, note="scope:m3-only"))
    print("\n".join(rows))
    # M3 NEVER drives the exit code. It routes through deploy.sh's
    # `flag_advisory_only` emitter, which is structurally incapable of enforcement
    # (no mode case, no enforce branch, no ISSUES increment) — an exit-1 here would
    # smuggle enforcement back in through the one door that is supposed to have none.
    return 0


def _m4_from_fixture(data):
    """(status, total, open_total, items) from a fixture's `m4` key.

    Accepts the same triple the live fetcher returns so the offline arm
    exercises `analyse_m4` and `emit_m4` on the identical shape — a fixture that
    feeds a different shape than production tests a function that does not ship.
    """
    block = data.get("m4")
    if block is None:
        return None
    # Items are supplied in RAW `search/issues` shape (flat `labels` list) and
    # run through the same normaliser the live path uses, so the offline arm
    # covers the transport adapter too rather than starting downstream of it.
    return ("fixture", int(block.get("total", 0)),
            int(block.get("open_total", 0)),
            [_m4_node(i) for i in block.get("items", [])])


def run_m4_only(args):
    """The `--leg M4` path. Repository-scoped; M1, M2 and M3 are not run.

    M4 is a property of the repository's issue population, not of any one
    milestone, so `--milestone` does not narrow it and this branch is taken
    ahead of the milestone short-circuit when `--leg M4` is explicit.
    """
    if args.fixture:
        try:
            with open(args.fixture, "r", encoding="utf-8") as fh:
                data = json.load(fh)
            fetched = _m4_from_fixture(data)
            if fetched is None:
                raise KeyError("m4")
        except (OSError, ValueError, KeyError) as exc:
            print("ERROR\tM4 fixture unreadable: " + str(exc), file=sys.stderr)
            return 3
    else:
        repo = _derive_repo(args.repo)
        if not repo:
            print("ERROR\t--repo not supplied and git remote origin unresolved",
                  file=sys.stderr)
            return 3
        fetched = fetch_m4(repo)

    status, total, open_total, items = fetched
    if total is None:
        print("\n".join(emit_m4(status, [], None, 0, 0)))
        return 0
    rows, counts, dropped = analyse_m4(total, open_total, items)
    print("\n".join(emit_m4(status, rows, counts, dropped, len(items))))
    # M4 never drives the exit code: its severity lives entirely in deploy.sh's
    # own mode branch, exactly as M3's does. Returning 1 here would smuggle
    # enforcement past the dial that is supposed to own it.
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
    ap.add_argument("--leg", choices=("M1", "M2", "M3", "M4", "all"), default="all",
                    help="which leg(s) to run; default all. M4 is REPOSITORY-scoped, "
                         "so --milestone does not narrow it")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    # M4 is tested BEFORE the milestone short-circuit: an explicit `--leg M4`
    # names a repository-scoped leg, and `--milestone` cannot narrow it.
    if args.leg == "M4":
        return run_m4_only(args)

    if args.milestone or args.leg == "M3":
        return run_m3_only(args)

    members_all = None
    m3_input = None
    m4_fetched = None
    ref_milestone = None
    ref_resolution = ("not-needed", 0, 0)
    if args.fixture:
        try:
            with open(args.fixture, "r", encoding="utf-8") as fh:
                data = json.load(fh)
            milestones, issues = data["milestones"], data["issues"]
            # Optional: a fixture may supply an explicit all-states membership
            # map to drive M2; absent it, M2 falls back to the OPEN set.
            members_all = data.get("members_all")
            # Optional: a fixture may also supply the ref→milestone overlay, so
            # the sub-class tokens are exercisable entirely offline.
            ref_milestone = data.get("ref_milestone")
            if ref_milestone is not None:
                ref_resolution = ("fixture", len(ref_milestone), len(ref_milestone))
            m3_input = data.get("m3")
            m4_fetched = _m4_from_fixture(data)
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
        # OUTSIDE the RuntimeError guard deliberately: fetch_m4 cannot raise. It
        # reports its own failure as `degraded` so that a search outage costs
        # this run its M4 measurement and nothing else — the M1 and M2 legs above
        # have already been computed and must still be emitted.
        m4_fetched = fetch_m4(repo)
        # Deferred ref→milestone overlay. The candidate set comes from the SAME
        # m2_divergence() binding the join consumes, and the call fires ONLY when
        # that set is non-empty — a clean M2 leg costs zero extra calls. The
        # fetcher cannot raise and cannot move the exit code, so it sits outside
        # the RuntimeError guard above deliberately: it has nothing to guard.
        candidates = set()
        for _named, _live, missing, _extra in m2_divergence(
                milestones, issues, members_all).values():
            candidates.update(missing)
        if candidates:
            resolved_ok, ref_milestone = fetch_ref_milestones(repo, candidates)
            ref_resolution = ("fetched" if resolved_ok else "degraded",
                              len(candidates), len(ref_milestone))

    m1, m2, skipped, exempted, declared = analyse(milestones, issues, members_all,
                                                  ref_milestone)
    # `--leg` restricts what is REPORTED, never what is computed: analyse() is one
    # pure join and splitting it would give the legs two membership bases to drift
    # apart. Default `all` emits every row, so the pre-existing output is unchanged.
    if args.leg == "M1":
        m2 = []
    elif args.leg == "M2":
        m1 = []
    if args.leg in ("M1", "M2"):
        m3_input = None
        m4_fetched = None

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
    # NNM counters are REF-denominated; COUNT_M2 above is ROW-denominated. Both
    # are emitted unconditionally, zeros included, so a consumer never has to
    # infer a missing counter's value from its absence. Read them with awk EXACT
    # field equality — a grep for COUNT_M2_NNM prefix-collides with all four
    # sub-counters.
    nnm_total, nnm_counts = m2_subclass_counts(m2)
    out.append("COUNT_M2_NNM\t" + str(nnm_total))
    for kind in M2_SUBCLASS_KINDS:
        out.append("COUNT_M2_NNM_%s\t%d"
                   % (kind.upper().replace("-", "_"), nnm_counts[kind]))
    # The resolver's own state, always emitted: a dead overlay and a population
    # that genuinely could not be resolved otherwise produce identical output,
    # and a check that cannot report its own degradation reports it as clean.
    out.append("M2_REF_RESOLUTION\t%s\t%d\t%d" % ref_resolution)
    if m3_input is not None:
        out.extend(emit_m3(*analyse_m3(m3_input)))
    # M4 emits on EVERY path, including the ones that do not run it: a leg whose
    # absence has to be inferred from missing rows is a leg whose "no findings"
    # and "never looked" render identically.
    if m4_fetched is None:
        out.extend(emit_m4("not-run", [], None, 0, 0, note="scope:leg-" + args.leg))
    else:
        m4_status, m4_total, m4_open, m4_items = m4_fetched
        if m4_total is None:
            out.extend(emit_m4(m4_status, [], None, 0, 0))
        else:
            m4_rows, m4_counts, m4_dropped = analyse_m4(m4_total, m4_open, m4_items)
            out.extend(emit_m4(m4_status, m4_rows, m4_counts, m4_dropped,
                               len(m4_items)))
    print("\n".join(out))
    # M3 and M4 are deliberately absent from this expression. M3 is advisory by
    # construction; M4's severity lives entirely in deploy.sh's own mode branch.
    # Neither may move the exit code M1/M2's severity split reads.
    return 1 if (m1 or m2) else 0


if __name__ == "__main__":
    sys.exit(main())
