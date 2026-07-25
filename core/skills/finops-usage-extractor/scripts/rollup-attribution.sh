#!/bin/bash
# finops-usage-extractor — roll-up + attribution module (slice C2).
#
# Reads the operator-local FinOps usage store produced by extract-usage.sh (slice
# C1, frozen v1.0.0) and writes the additive v1.1.0 `rollup` + `coverage` records:
# it resolves each `session` record to its owning work item, rolls per-session token
# spend up to that work item (honoring C1's summation invariant), and emits a
# run-level attribution-health `coverage` record. The store schema authority is
# core/schemas/finops-usage-store-schema.md; the mapping ALGORITHM is defined in
# core/standards/finops-attribution-convention.md.
#
# DEFAULT resolver path is LOCAL-ONLY (no network, no gh): the session's own
# release/chore branch → milestone is the reliable workhorse; a decision-event
# payload (local hub-state) is best-effort issue-grain; a hub-state worktree join
# corroborates milestone-grain; everything else lands in an explicit `unattributed`
# bucket (fail-visible, never dropped). The OPT-IN --resolve-prs flag enables a
# network `gh` PR→closing-issue resolve for fix/feat branches ONLY; it stamps
# attribution_tier=pr-resolved + reproducible=false and is never on the default path.
#
# Store path resolution (no hardcoded operator path; same as extract-usage.sh):
#   env STORE > env FINOPS_STORE_PATH > operator.toml [paths].operator_instance_finops_store_path
#   > default ${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/finops
# Hub-state (Surface C) resolution:
#   env FINOPS_HUB_STATE_DIR > operator.toml [paths].operator_instance_hub_state_path
#   > default ${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/hub-state
# Pipeline event-log (Surface B) resolution:
#   env FINOPS_PIPELINE_EVENT_LOG
#   > operator.toml [paths].operator_instance_evals_results_path + /pipeline-event-log.md
#   > default ${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/evals/results/pipeline-event-log.md
#
# Usage:
#   bash rollup-attribution.sh [--emit] [--resolve-prs] [--self-test]
#     --emit         (DEFAULT) resolve + roll up the store in place: strip any prior
#                    rollup/coverage records, append fresh ones, bump meta schema_version
#                    to 1.1.0. Idempotent over an unchanged store (byte-identical body
#                    modulo the rolled_up_utc metadata). Session/subagent lines untouched.
#     --resolve-prs  OPT-IN: additionally resolve fix/feat branches via `gh` (network,
#                    non-reproducible). Absent → those sessions degrade to `unattributed`.
#     --self-test    run built-in assertions against the synthetic rollup fixtures
#                    (ground-truth oracle + conservation + coverage + idempotence);
#                    no operator-store or network access.
#
# Exit codes: 0 ok · 2 usage error · 3 store unreadable · 4 store-not-git-ignored
#             (fail-closed public-repo exfil guard) · 5 missing dependency (jq/git).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_MD="$SCRIPT_DIR/../SKILL.md"
FIXTURES_DIR="$SCRIPT_DIR/../test-fixtures/rollup"

# ── FM preflight: hard dependencies (jq for parsing, git for the store guard). ──
preflight_deps() {
  local missing=""
  command -v jq  >/dev/null 2>&1 || missing="jq"
  command -v git >/dev/null 2>&1 || missing="${missing:+$missing, }git"
  if [ -n "$missing" ]; then
    printf 'FATAL (exit 5): missing dependency: %s — see SKILL.md ## Dependencies\n' "$missing" >&2
    exit 5
  fi
}

# ── Generator version — read the skill's own version frontmatter (never hardcoded). ──
generator_version() {
  local v=""
  [ -r "$SKILL_MD" ] && v="$( { grep -E '^version:' "$SKILL_MD" 2>/dev/null || true; } | head -1 | awk '{print $2}')"
  printf '%s' "${v:-unknown}"
}

# ── operator.toml single-key reader (tolerates an absent key). ──
toml_val() {
  local key="$1" toml="${HOME}/.config/pmo-platform/operator.toml"
  [ -r "$toml" ] || return 0
  { grep -E "^${key}" "$toml" 2>/dev/null || true; } | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}'
}

workspace_root() {
  local wr="${CLAUDE_WORKSPACE_ROOT:-}"
  [ -z "$wr" ] && wr="$(toml_val claude_workspace_root)"
  printf '%s' "${wr:-${HOME}/Claude}"
}

# ── Store path resolution (env → operator.toml → default). Same as extract-usage.sh. ──
resolve_store() {
  local store="${STORE:-${FINOPS_STORE_PATH:-}}"
  [ -z "$store" ] && store="$(toml_val operator_instance_finops_store_path)"
  store="${store:-$(workspace_root)/personal/pmo-instance/finops}"
  printf '%s' "$store"
}

# ── Hub-state (Surface C) dir resolution. ──
resolve_hub_state_dir() {
  local d="${FINOPS_HUB_STATE_DIR:-}"
  [ -z "$d" ] && d="$(toml_val operator_instance_hub_state_path)"
  d="${d:-$(workspace_root)/personal/pmo-instance/hub-state}"
  printf '%s' "$d"
}

# ── Pipeline event-log (Surface B) path resolution. ──
resolve_event_log() {
  local f="${FINOPS_PIPELINE_EVENT_LOG:-}"
  if [ -z "$f" ]; then
    local er; er="$(toml_val operator_instance_evals_results_path)"
    er="${er:-$(workspace_root)/personal/pmo-instance/evals/results}"
    f="$er/pipeline-event-log.md"
  fi
  printf '%s' "$f"
}

# ── FM fail-closed store guard — resolve-time, BEFORE any write. Byte-for-byte the
#    same contract as extract-usage.sh: refuse (exit 4) if the resolved store is inside
#    a git repo but NOT git-ignored there. A store outside any repo proceeds. ──
guard_store_git_ignored() {
  local store_dir="$1"
  local store_file="$store_dir/usage.jsonl"
  local probe="$store_dir"
  while [ ! -d "$probe" ] && [ "$probe" != "/" ] && [ -n "$probe" ]; do
    probe="$(dirname "$probe")"
  done
  [ -d "$probe" ] || return 0
  local store_repo
  store_repo="$(git -C "$probe" rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -n "$store_repo" ]; then
    if ! git -C "$store_repo" check-ignore -q -- "$store_file" 2>/dev/null; then
      printf 'FATAL (exit 4): resolved FinOps store %s is inside git repo %s but is NOT git-ignored.\n' "$store_file" "$store_repo" >&2
      printf 'Refusing to write (public-repo exfil guard). Fix: point operator.toml\n' >&2
      printf '[paths].operator_instance_finops_store_path at an ignored or outside-repo path.\n' >&2
      exit 4
    fi
  fi
  return 0
}

NOW_UTC() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# ── Surface C → {worktree: "vX.Y"} map. Scans <hub-state>/vX.Y/sessions.md tables;
#    the milestone is the parent dir name; the worktree is table column 4. ──
build_worktree_milestone_map() {
  local hub_dir="$1"
  [ -d "$hub_dir" ] || { printf '{}'; return 0; }
  local f ver
  while IFS= read -r f; do
    ver="$(basename "$(dirname "$f")")"
    case "$ver" in v[0-9]*) : ;; *) continue ;; esac
    # Data rows only: start with '|', not the header ('session_id') or separator ('---').
    awk -F'|' -v ver="$ver" '
      /^[[:space:]]*\|/ && $0 !~ /session_id/ && $0 !~ /-{3,}/ {
        wt=$5; gsub(/^[[:space:]]+|[[:space:]]+$/,"",wt);   # $1 empty (leading |), col4 = $5
        if (wt != "") printf "%s\t%s\n", wt, ver
      }' "$f"
  done < <(find "$hub_dir" -type f -name 'sessions.md' 2>/dev/null) \
    | jq -R -s 'split("\n") | map(select(length>0) | split("\t")) | map({(.[0]): .[1]}) | add // {}'
}

# ── Surface B → [{worktree, issue, ts}] list. Scans the pipeline-event-log table for
#    decision/gate-outcome/escalation rows whose payload carries session:<composite>
#    and whose subject/actor names an issue #N. The composite's worktree component is
#    everything before the first '__'. ──
build_issue_event_list() {
  local log="$1"
  [ -r "$log" ] || { printf '[]'; return 0; }
  awk -F'|' '
    /^[[:space:]]*\|/ && $0 !~ /ts_iso/ && $0 !~ /-{3,}/ {
      ts=$2;      gsub(/^[[:space:]]+|[[:space:]]+$/,"",ts);
      etype=$5;   gsub(/^[[:space:]]+|[[:space:]]+$/,"",etype);
      actor=$7;   gsub(/^[[:space:]]+|[[:space:]]+$/,"",actor);
      subject=$8; gsub(/^[[:space:]]+|[[:space:]]+$/,"",subject);
      payload=$11;gsub(/^[[:space:]]+|[[:space:]]+$/,"",payload);
      if (etype !~ /^(decision|gate-outcome|escalation)$/) next;
      # issue number: prefer subject #N, else actor spoke:#N. Normalize to #<digits>.
      issue="";
      if (match(subject, /#[0-9]+/))    issue=substr(subject, RSTART, RLENGTH);
      else if (match(actor, /#[0-9]+/)) issue=substr(actor, RSTART, RLENGTH);
      else next;
      # composite worktree: session:<wt>__...
      if (match(payload, /session:[^;[:space:]]+/)) {
        comp=substr(payload, RSTART+8, RLENGTH-8);      # strip "session:"
        wt=comp; sub(/__.*$/,"",wt);
        if (wt != "" && ts != "") printf "%s\t%s\t%s\n", wt, issue, ts;
      }
    }' "$log" \
    | jq -R -s 'split("\n") | map(select(length>0) | split("\t")) | map({worktree:.[0], issue:.[1], ts:.[2]})'
}

# ── The resolver + roll-up jq program. Input: slurped session records. Args: the two
#    hub-state maps. Output (with --arg mode "resolve"): one resolution object per
#    session. Output (mode "rollup"): the rollup + coverage records. ──
read -r -d '' JQ_RESOLVE <<'JQEOF' || true
def tok(t): (t.input // 0) + (t.output // 0) + ((t.cache_creation.total) // 0) + (t.cache_read // 0);
def base($p): ($p // "") | split("/") | last;
def parse_milestone($b):
  # test-guard the capture: a bare `capture` on a non-matching string yields EMPTY,
  # and binding `... as $v` to an empty stream would silently drop the whole session.
  ($b // "") as $s
  | if ($s | test("^(?:release|chore)/v[0-9]+\\.[0-9]+"))
    then ($s | capture("^(?:release|chore)/(?<v>v[0-9]+\\.[0-9]+)") | .v)
    else null end ;
def is_fixfeat($b): ($b // "") | test("^(?:fix|feat)/") ;

# T1: an issue-event whose worktree == basename(cwd) and ts within the session window.
def t1_issue($cwd; $start; $end):
  base($cwd) as $wt
  | ( [ $issue_events[]
        | select(.worktree == $wt)
        | select( ($start == null) or ($end == null) or (.ts >= $start and .ts <= $end) )
        | .issue ] | first ) ;

.[]
| . as $s
| ($s.tokens // {}) as $tk
| ($s.git_branch) as $branch
| ($s.cwd) as $cwd
| base($cwd) as $wt
| ($s.started_utc) as $start
| ($s.ended_utc) as $end
# Bind all tier candidates at top level (in scope in every branch below — avoids
# relying on condition-bound variables, which jq does not carry into `then`).
| (t1_issue($cwd; $start; $end)) as $t1
| (parse_milestone($branch)) as $t2v
| ($wt_milestone[$wt]) as $t3v
| ( if ($s.branch_switch == true) then
      { work_item: "multi-branch", work_item_kind: "multi-branch",
        attribution_tier: "unattributed", reproducible: true,
        attribution_basis: ("branch_switch across " + (($s.git_branches // []) | join(", "))) }
    elif $t1 != null then
      { work_item: $t1, work_item_kind: "issue",
        attribution_tier: "issue-event-keyed", reproducible: true,
        attribution_basis: ("issue-event payload for worktree " + $wt) }
    elif $t2v != null then
      { work_item: ("milestone:" + $t2v), work_item_kind: "milestone",
        attribution_tier: "branch-milestone", reproducible: true,
        attribution_basis: ("branch " + $branch + " -> milestone " + $t2v) }
    elif $t3v != null then
      { work_item: ("milestone:" + $t3v), work_item_kind: "milestone",
        attribution_tier: "hub-state-lineage", reproducible: true,
        attribution_basis: ("hub-state worktree " + $wt + " -> milestone " + $t3v) }
    else
      { work_item: "unattributed", work_item_kind: "unattributed",
        attribution_tier: "unattributed", reproducible: true,
        attribution_basis: ( if ($branch == null) then "git_branch null"
                             elif is_fixfeat($branch) then ("fix/feat branch " + $branch + " unresolved (no --resolve-prs)")
                             else ("unparseable branch " + ($branch // "null") + " / no hub-state hit") end ) }
    end ) as $res
| { session_id: $s.session_id, work_item: $res.work_item, work_item_kind: $res.work_item_kind,
    attribution_tier: $res.attribution_tier, reproducible: $res.reproducible,
    attribution_basis: $res.attribution_basis, branch: $branch,
    tokens: { input: ($tk.input // 0), output: ($tk.output // 0),
              cache_creation: { total: (($tk.cache_creation.total) // 0),
                                ephemeral_1h: (($tk.cache_creation.ephemeral_1h) // 0),
                                ephemeral_5m: (($tk.cache_creation.ephemeral_5m) // 0) },
              cache_read: ($tk.cache_read // 0) },
    tool_use: { web_search_requests: (($s.tool_use.web_search_requests) // 0),
                web_fetch_requests: (($s.tool_use.web_fetch_requests) // 0) },
    token_source: ($s.token_source // "exact"),
    total: tok($tk) }
JQEOF

# ── Roll-up jq: input = slurped resolution records (post T-PR pass). Output = rollup
#    rows (sorted) + exactly one unattributed row (always) + a coverage record. ──
read -r -d '' JQ_ROLLUP <<'JQEOF' || true
def rnd(f): (f * 1000000 | round) / 1000000;
def rank($t): {"branch-milestone":1,"issue-event-keyed":2,"hub-state-lineage":3,"pr-resolved":4,"unattributed":5}[$t] // 9;
def sumtok($rows): reduce $rows[] as $r
  ({input:0,output:0,cc_total:0,cc_1h:0,cc_5m:0,cread:0,ws:0,wf:0};
   { input:(.input + $r.tokens.input), output:(.output + $r.tokens.output),
     cc_total:(.cc_total + $r.tokens.cache_creation.total),
     cc_1h:(.cc_1h + $r.tokens.cache_creation.ephemeral_1h),
     cc_5m:(.cc_5m + $r.tokens.cache_creation.ephemeral_5m),
     cread:(.cread + $r.tokens.cache_read),
     ws:(.ws + $r.tool_use.web_search_requests),
     wf:(.wf + $r.tool_use.web_fetch_requests) });
def tokens_of($a): { input:$a.input, output:$a.output,
  cache_creation:{ total:$a.cc_total, ephemeral_1h:$a.cc_1h, ephemeral_5m:$a.cc_5m },
  cache_read:$a.cread };
def tooluse_of($a): { web_search_requests:$a.ws, web_fetch_requests:$a.wf };

. as $all
| ($all | map(.total) | add // 0) as $grand
| ( $all | group_by(.work_item)
    | map( . as $g
      | sumtok($g) as $sum
      | ($g | map(.attribution_tier) | min_by(rank(.))) as $tier
      | { record: "rollup",
          work_item: $g[0].work_item,
          work_item_kind: $g[0].work_item_kind,
          attribution_tier: $tier,
          reproducible: ($g | all(.reproducible)),
          tokens: tokens_of($sum),
          tool_use: tooluse_of($sum),
          session_count: ($g | length),
          session_ids: ($g | map(.session_id) | sort),
          token_source: ( ($g | map(.token_source) | unique) as $ts
                          | if ($ts | length) == 1 then $ts[0] else "mixed" end ),
          attribution_basis: $g[0].attribution_basis } )
    | sort_by(.work_item) ) as $rollups
# Always emit exactly one unattributed row (empty if none resolved there).
| ( if ($rollups | any(.work_item == "unattributed")) then $rollups
    else $rollups + [ { record:"rollup", work_item:"unattributed", work_item_kind:"unattributed",
        attribution_tier:"unattributed", reproducible:true,
        tokens:{input:0,output:0,cache_creation:{total:0,ephemeral_1h:0,ephemeral_5m:0},cache_read:0},
        tool_use:{web_search_requests:0,web_fetch_requests:0},
        session_count:0, session_ids:[], token_source:"exact",
        attribution_basis:"no unattributed sessions this run" } ] end ) as $rollups2
# Coverage — computed from the session-level resolutions (not the rollup rows).
| ( [ $all[] | select(.work_item_kind=="milestone") | .total ] | add // 0 ) as $ms
| ( [ $all[] | select(.work_item_kind=="issue") | .total ] | add // 0 ) as $iss
| ( [ $all[] | select(.work_item_kind=="multi-branch") | .total ] | add // 0 ) as $mb
| ( ($ms + $iss) ) as $attr
| ( if $grand>0 then ($attr/$grand) else 1 end ) as $attr_frac
| ( 1 - $attr_frac ) as $unattr_frac
| ( [ "branch-milestone","issue-event-keyed","hub-state-lineage","pr-resolved","unattributed" ]
    | map( . as $t
      | { key: $t,
          value: ( if $grand>0
                   then rnd( ([ $all[] | select(.attribution_tier==$t) | .total ] | add // 0) / $grand )
                   else 0 end ) } ) | from_entries ) as $tierdist
| ( [ $all[] | select(.work_item_kind=="unattributed") ] | length ) as $unattr_sessions
| ( $all | length ) as $nsess
| { record: "coverage",
    attributed_token_fraction: rnd($attr_frac),
    unattributed_token_fraction: rnd($unattr_frac),
    milestone_grain_token_fraction: ( if $grand>0 then rnd($ms/$grand) else 0 end ),
    issue_grain_token_fraction: ( if $grand>0 then rnd($iss/$grand) else 0 end ),
    multi_branch_token_fraction: ( if $grand>0 then rnd($mb/$grand) else 0 end ),
    tier_distribution: $tierdist,
    unattributed_session_rate: ( if $nsess>0 then rnd($unattr_sessions/$nsess) else 0 end ),
    pr_resolved_present: ( $all | any(.attribution_tier=="pr-resolved") ),
    health: ( if $unattr_frac <= 0.25 then "OK" elif $unattr_frac <= 0.50 then "WARN" else "FAIL" end ) } as $coverage
| ( $rollups2[] ), $coverage
JQEOF

# ── Resolve fix/feat branch → closing issue. Uses FINOPS_PR_STUB (branch<TAB>#N) when
#    set (self-test path), else a read-only `gh` query. Prints #N on success. ──
resolve_pr() {
  local branch="$1"
  if [ -n "${FINOPS_PR_STUB:-}" ] && [ -r "$FINOPS_PR_STUB" ]; then
    awk -F'\t' -v b="$branch" '$1==b{print $2; f=1} END{exit !f}' "$FINOPS_PR_STUB"
    return $?
  fi
  command -v gh >/dev/null 2>&1 || return 1
  local issue
  issue="$(gh pr list --head "$branch" --state merged --json closingIssuesReferences \
            --jq '.[0].closingIssuesReferences[0].number // empty' 2>/dev/null || true)"
  [ -n "$issue" ] && { printf '#%s' "$issue"; return 0; }
  return 1
}

# ── T-PR opt-in post-pass: upgrade unattributed fix/feat resolutions to pr-resolved.
#    Reads resolution JSONL on stdin, writes upgraded JSONL on stdout. ──
apply_pr_resolve() {
  local line branch iss
  while IFS= read -r line; do
    branch="$(printf '%s' "$line" | jq -r '.branch // empty')"
    if printf '%s' "$line" | jq -e 'select(.work_item_kind=="unattributed")' >/dev/null 2>&1 \
       && printf '%s' "$branch" | grep -qE '^(fix|feat)/'; then
      if iss="$(resolve_pr "$branch")"; then
        printf '%s' "$line" | jq -c --arg iss "$iss" \
          '.work_item=$iss | .work_item_kind="issue" | .attribution_tier="pr-resolved"
           | .reproducible=false | .attribution_basis=("PR-resolved " + .branch + " -> " + $iss)'
        continue
      fi
    fi
    printf '%s\n' "$line"
  done
}

# ── Core: resolve + roll up an existing store in place (strip prior rollup/coverage,
#    append fresh; bump meta schema_version to 1.1.0). Atomic tmp -> mv. ──
do_emit() {
  local store_dir="$1" resolve_prs="$2"
  local store_file="$store_dir/usage.jsonl"
  if [ ! -f "$store_file" ] || [ ! -r "$store_file" ]; then
    printf 'FATAL (exit 3): FinOps store unreadable: %s (run extract-usage.sh first)\n' "$store_file" >&2
    exit 3
  fi
  local hub_dir log wt_map ev_list
  hub_dir="$(resolve_hub_state_dir)"
  log="$(resolve_event_log)"
  wt_map="$(build_worktree_milestone_map "$hub_dir")"
  ev_list="$(build_issue_event_list "$log")"

  local sessions resolutions rolled tmp
  sessions="$(mktemp "${TMPDIR:-/tmp}/finops-sess.XXXXXX")"
  resolutions="$(mktemp "${TMPDIR:-/tmp}/finops-res.XXXXXX")"
  rolled="$(mktemp "${TMPDIR:-/tmp}/finops-roll.XXXXXX")"

  jq -c 'select(.record=="session")' "$store_file" > "$sessions" 2>/dev/null

  # Pass 1: resolve each session (LOCAL-ONLY).
  jq -s -c --argjson wt_milestone "$wt_map" --argjson issue_events "$ev_list" \
     "$JQ_RESOLVE" "$sessions" > "$resolutions" 2>/dev/null

  # Pass 2 (opt-in): T-PR network upgrade for unattributed fix/feat.
  if [ "$resolve_prs" -eq 1 ]; then
    apply_pr_resolve < "$resolutions" > "$resolutions.pr" && mv -f "$resolutions.pr" "$resolutions"
  fi

  # Pass 3: roll up → rollup rows + coverage.
  jq -s -c "$JQ_ROLLUP" "$resolutions" > "$rolled" 2>/dev/null

  # Rewrite store: meta(schema_version=1.1.0) + verbatim session/subagent + rollup/coverage.
  tmp="$store_file.tmp"
  jq -c 'select(.record=="meta") | .schema_version="1.1.0" | .generator_version=$gv' \
     --arg gv "$(generator_version)" "$store_file" > "$tmp" 2>/dev/null
  jq -c 'select(.record=="session" or .record=="subagent")' "$store_file" >> "$tmp" 2>/dev/null
  cat "$rolled" >> "$tmp"
  mv -f "$tmp" "$store_file"

  rm -f "$sessions" "$resolutions" "$rolled"
  local nroll ncov health
  nroll="$(jq -s '[.[]|select(.record=="rollup")]|length' "$store_file" 2>/dev/null)"
  ncov="$(jq -s '[.[]|select(.record=="coverage")]|length' "$store_file" 2>/dev/null)"
  health="$(jq -r 'select(.record=="coverage")|.health' "$store_file" 2>/dev/null | head -1)"
  printf 'finops-usage-extractor rollup: %s (%s rollup record(s), %s coverage; health=%s)\n' \
    "$store_file" "${nroll:-?}" "${ncov:-?}" "${health:-?}" >&2
}

# ── Self-test: ground-truth oracle + conservation + coverage + idempotence, against
#    the synthetic rollup fixtures. No operator store / no network. ──
self_test() {
  local fail=0
  [ -d "$FIXTURES_DIR" ] || { echo "FAIL: rollup fixtures dir missing: $FIXTURES_DIR"; return 1; }
  local fx_store="$FIXTURES_DIR/usage.jsonl"
  local fx_oracle="$FIXTURES_DIR/rollup.expected.json"
  local fx_hub="$FIXTURES_DIR/hub-state"
  local fx_log="$FIXTURES_DIR/pipeline-event-log.md"
  local fx_prstub="$FIXTURES_DIR/pr-stub.tsv"
  for f in "$fx_store" "$fx_oracle"; do
    [ -f "$f" ] || { echo "FAIL: missing fixture: $f"; return 1; }
  done

  local st; st="$(mktemp -d "${TMPDIR:-/tmp}/finops-roll-selftest.XXXXXX")"
  cp "$fx_store" "$st/usage.jsonl"

  # (A) CIAC-1 PRIMARY — ground-truth resolution reproduces the labeled oracle, tier-by-tier.
  local wt_map ev_list got want
  wt_map="$(FINOPS_HUB_STATE_DIR="$fx_hub" build_worktree_milestone_map "$fx_hub")"
  ev_list="$(build_issue_event_list "$fx_log")"
  local sessions res
  sessions="$(mktemp "${TMPDIR:-/tmp}/finops-st-sess.XXXXXX")"
  res="$(mktemp "${TMPDIR:-/tmp}/finops-st-res.XXXXXX")"
  jq -c 'select(.record=="session")' "$st/usage.jsonl" > "$sessions" 2>/dev/null
  jq -s -c --argjson wt_milestone "$wt_map" --argjson issue_events "$ev_list" \
     "$JQ_RESOLVE" "$sessions" > "$res" 2>/dev/null
  # Opt-in T-PR with the stub so the pr-resolved fixture resolves deterministically (no gh).
  if [ -f "$fx_prstub" ]; then
    FINOPS_PR_STUB="$fx_prstub" apply_pr_resolve < "$res" > "$res.pr" && mv -f "$res.pr" "$res"
  fi
  got="$(jq -s -S 'map({session_id, work_item, work_item_kind, attribution_tier}) | sort_by(.session_id)' "$res" 2>/dev/null)"
  want="$(jq -S 'sort_by(.session_id)' "$fx_oracle" 2>/dev/null)"
  if [ "$got" != "$want" ]; then
    echo "FAIL: CIAC-1 ground-truth — resolver did not reproduce the labeled oracle"
    diff <(printf '%s\n' "$want") <(printf '%s\n' "$got") 2>/dev/null | head -30
    fail=1
  else
    echo "  PASS: CIAC-1 ground-truth attribution (resolver reproduces oracle, tier-by-tier)"
  fi

  # Run the full roll-up (default local-only path) for the remaining checks.
  STORE="$st" FINOPS_HUB_STATE_DIR="$fx_hub" FINOPS_PIPELINE_EVENT_LOG="$fx_log" \
    do_emit "$st" 0 >/dev/null 2>&1

  # (B) CIAC-1b SECONDARY — conservation identity.
  local grand rollsum perrow_bad
  grand="$(jq -s '[.[]|select(.record=="session")|(.tokens.input+.tokens.output+.tokens.cache_creation.total+.tokens.cache_read)]|add // 0' "$st/usage.jsonl")"
  rollsum="$(jq -s '[.[]|select(.record=="rollup")|(.tokens.input+.tokens.output+.tokens.cache_creation.total+.tokens.cache_read)]|add // 0' "$st/usage.jsonl")"
  if [ "$grand" = "$rollsum" ]; then
    echo "  PASS: CIAC-1b conservation (Σ rollup == Σ session = $grand)"
  else
    echo "FAIL: conservation — Σ rollup ($rollsum) != Σ session ($grand)"; fail=1
  fi
  perrow_bad="$(jq -s '
      (map(select(.record=="session")) | map({key:.session_id, value:.}) | from_entries) as $byid
      | [ .[] | select(.record=="rollup")
          | . as $r
          | ($r.tokens.input+$r.tokens.output+$r.tokens.cache_creation.total+$r.tokens.cache_read) as $rt
          | ([ $r.session_ids[] | $byid[.]
               | (.tokens.input+.tokens.output+.tokens.cache_creation.total+.tokens.cache_read) ] | add // 0) as $ssum
          | select($rt != $ssum) | .work_item ] | length' "$st/usage.jsonl" 2>/dev/null)"
  if [ "${perrow_bad:-0}" -eq 0 ]; then
    echo "  PASS: per-row rollup.tokens == Σ over session_ids"
  else
    echo "FAIL: $perrow_bad rollup row(s) mismatch their session_ids sum"; fail=1
  fi

  # (C) Coverage emitted + health OK on the (majority-attributable) fixture.
  local ncov health cov_ok
  ncov="$(jq -s '[.[]|select(.record=="coverage")]|length' "$st/usage.jsonl")"
  health="$(jq -r 'select(.record=="coverage")|.health' "$st/usage.jsonl" | head -1)"
  [ "${ncov:-0}" -eq 1 ] || { echo "FAIL: expected exactly 1 coverage record, got ${ncov:-0}"; fail=1; }
  if [ "$health" = "OK" ]; then echo "  PASS: coverage record emitted (health=OK)";
  else echo "FAIL: coverage health != OK (got '${health:-none}') on the majority-attributable fixture"; fail=1; fi

  # (D) unattributed row ALWAYS present.
  local n_unattr
  n_unattr="$(jq -s '[.[]|select(.record=="rollup" and .work_item=="unattributed")]|length' "$st/usage.jsonl")"
  [ "${n_unattr:-0}" -eq 1 ] && echo "  PASS: exactly one unattributed rollup row (always emitted)" \
    || { echo "FAIL: unattributed rollup row count != 1 (got ${n_unattr:-0})"; fail=1; }

  # (E) multi-branch bucket present (fixture includes a branch_switch session).
  local n_mb
  n_mb="$(jq -s '[.[]|select(.record=="rollup" and .work_item=="multi-branch")]|length' "$st/usage.jsonl")"
  [ "${n_mb:-0}" -eq 1 ] && echo "  PASS: multi-branch bucket emitted (branch_switch routed, not silently attributed)" \
    || { echo "FAIL: multi-branch rollup row count != 1 (got ${n_mb:-0})"; fail=1; }

  # (F) Idempotence — a second roll-up leaves the body byte-identical modulo rolled_up_utc.
  jq -c 'select(.record=="rollup" or .record=="coverage") | del(.rolled_up_utc)' "$st/usage.jsonl" > "$st/n1.jsonl" 2>/dev/null
  STORE="$st" FINOPS_HUB_STATE_DIR="$fx_hub" FINOPS_PIPELINE_EVENT_LOG="$fx_log" do_emit "$st" 0 >/dev/null 2>&1
  jq -c 'select(.record=="rollup" or .record=="coverage") | del(.rolled_up_utc)' "$st/usage.jsonl" > "$st/n2.jsonl" 2>/dev/null
  if diff -q "$st/n1.jsonl" "$st/n2.jsonl" >/dev/null 2>&1; then
    echo "  PASS: idempotent re-run (rollup/coverage body byte-identical modulo timestamp)"
  else
    echo "FAIL: roll-up not idempotent (rollup/coverage body changed across re-run)"; fail=1
  fi

  # (G) No duplicate rollup work_item; session/subagent records preserved (count unchanged).
  local dup nsess_before nsess_after
  dup="$(jq -s '[.[]|select(.record=="rollup")|.work_item]|group_by(.)|map(select(length>1))|length' "$st/usage.jsonl")"
  [ "${dup:-0}" -eq 0 ] && echo "  PASS: no duplicate rollup work_item" || { echo "FAIL: duplicate rollup work_item"; fail=1; }
  nsess_after="$(jq -s '[.[]|select(.record=="session")]|length' "$st/usage.jsonl")"
  nsess_before="$(jq -s '[.[]|select(.record=="session")]|length' "$fx_store")"
  [ "${nsess_after:-0}" = "${nsess_before:-x}" ] && echo "  PASS: session records preserved verbatim (count $nsess_after)" \
    || { echo "FAIL: session record count changed ($nsess_before -> $nsess_after)"; fail=1; }

  # (H) meta bumped to 1.1.0.
  local sv
  sv="$(jq -r 'select(.record=="meta")|.schema_version' "$st/usage.jsonl" | head -1)"
  [ "$sv" = "1.1.0" ] && echo "  PASS: meta.schema_version bumped to 1.1.0" || { echo "FAIL: meta.schema_version != 1.1.0 (got $sv)"; fail=1; }

  rm -f "$sessions" "$res"
  rm -rf "$st"
  if [ "$fail" -eq 0 ]; then echo "finops-usage-extractor rollup --self-test: PASS"; return 0; fi
  echo "finops-usage-extractor rollup --self-test: FAIL"; return 1
}

# ── Main ──
MODE="emit"
RESOLVE_PRS=0
DO_SELFTEST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --emit)        MODE="emit" ;;
    --resolve-prs) RESOLVE_PRS=1 ;;
    --self-test)   DO_SELFTEST=1 ;;
    -h|--help)
      grep -E '^#( |$)' "$0" | sed -E 's/^# ?//' | head -50
      exit 0 ;;
    *)
      printf 'FATAL (exit 2): unknown argument: %s\n' "$1" >&2
      exit 2 ;;
  esac
  shift
done

preflight_deps

if [ "$DO_SELFTEST" -eq 1 ]; then
  self_test
  exit $?
fi

STORE_DIR="$(resolve_store)"
guard_store_git_ignored "$STORE_DIR"
do_emit "$STORE_DIR" "$RESOLVE_PRS"
exit 0
