#!/bin/bash
# finops-usage-extractor — local-session usage parser (slice C1, #3909).
#
# Extracts per-session and per-in-transcript-subagent token spend from local Claude
# Code session transcripts into the operator-local, git-ignored FinOps usage store
# defined by core/schemas/finops-usage-store-schema.md (schema v2.0.0). Exact
# message.usage counts are PRIMARY; the context-budget-auditor (#16) word->token
# heuristic is the FALLBACK for usage-less records only. Read-only on the source
# transcripts; writes only the resolved store (atomic tmp -> mv).
# Every token and turn figure is counted once per API RESPONSE within one transcript
# file — lines grouped by message.id, each usage field max-merged (schema § Counting unit).
# A response with no stop reason on any of its lines never received its final usage,
# which arrives in the same streaming event: it is recorded at its snapshot and counted in
# incomplete_responses, or in unevaluated_responses when the flag cannot decide (schema
# § Incomplete responses).
#
# Store path resolution (no hardcoded operator path):
#   env STORE > env FINOPS_STORE_PATH > operator.toml [paths].operator_instance_finops_store_path
#   > default ${CLAUDE_WORKSPACE_ROOT}/pmo-instance/finops
# Source root resolution:
#   env FINOPS_SOURCE_ROOT > ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects
#
# Usage:
#   bash extract-usage.sh [--rebuild | --incremental] [--self-test]
#     --rebuild      (DEFAULT) truncate + rewrite from source; deterministic order;
#                    byte-idempotent over unchanged source.
#     --incremental  mtime-gated upsert by session_id (newest-wins); opt-in optimization.
#     --self-test    run built-in assertions against the synthetic test-fixtures; no
#                    source or operator-store access.
#
# Exit codes: 0 ok · 2 usage error · 3 fail-closed read/preserve failure (five causes,
#             below) · 4 store-not-git-ignored (fail-closed public-repo exfil guard)
#             · 5 missing dependency (jq/git).
#
# Exit 3 has FIVE distinct causes, not one. Every one leaves an existing store
# UNCHANGED, and every one prints its own `FATAL (exit 3):` line naming itself — so
# the cause is READ OFF STDERR and never inferred from the code alone:
#     - session-data source root unreadable            (both modes, pre-dispatch)
#     - --incremental drop-set read failed over the re-extracted records
#     - --incremental drop-set could not be assembled
#     - --incremental carry-forward could not read the store
#     - --rebuild could not preserve a store of another counting unit (schema major)
# The carry-forward cause came from #4188; the two drop-set causes are new in #5240.
# The preservation cause is new in schema v2.0.0.
# A caller that branches on the exit code alone cannot tell "there was nothing to
# read" from "the store is intact but now stale" — match the message, not just 3.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_MD="$SCRIPT_DIR/../SKILL.md"
FIXTURES_DIR="$SCRIPT_DIR/../test-fixtures"

# ── token heuristic reused from core/skills/context-budget-auditor/scripts/measure-context-budget.sh:46
#    est_tokens_from_words() — declared ceil(words/0.75); fallback only, source usage is authoritative.
est_tokens_from_words() {
  local words="$1"
  # ceil(w / 0.75) == ceil(4w / 3) == (4w + 2) / 3   (integer division)
  echo $(( (4 * words + 2) / 3 ))
}

# ── FM-3 preflight: hard dependencies (jq for parsing, git for the FM-2 guard). ──
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

# ── Store schema version this writer emits — the counting-unit identity (schema § Versioning). ──
SCHEMA_VERSION="2.0.0"
# The schema version an on-disk store declares; "unknown" when its meta is unreadable.
# Filename-safe charset only, because the value names the preserved copy.
store_schema_version() {
  local v
  v="$(jq -rn 'first(inputs | select(.record=="meta") | (.schema_version // "unknown")) // "unknown"' "$1" 2>/dev/null)" || v="unknown"
  case "$v" in ''|*[!0-9A-Za-z.+-]*) v="unknown" ;; esac
  printf '%s' "$v"
}
# The counting unit is the MAJOR component of the schema version (schema § Counting
# unit): 1.x counted per transcript line, 2.x once per API response within one
# transcript file. An additive (minor) bump keeps the unit, so the boundary keys on the
# major alone, never on the full string; an unreadable version ("unknown") never matches.
same_counting_unit() {
  [ "$1" != "unknown" ] && [ "${1%%.*}" = "${SCHEMA_VERSION%%.*}" ]
}
# What a store's declared version says about its counting unit — for operator messages,
# so a store of the current unit is never described as per-line.
counting_unit_note() {
  case "${1%%.*}" in
    1)       printf 'counted per transcript line (inflated; schema § Versioning)' ;;
    unknown) printf 'its schema version is unreadable, so its counting unit is unknown' ;;
    *)       printf "a counting unit other than this writer's" ;;
  esac
}

# ── Store path resolution (env → operator.toml → default). ──
resolve_store() {
  local store="${STORE:-${FINOPS_STORE_PATH:-}}"
  local workspace_root="${CLAUDE_WORKSPACE_ROOT:-}"
  local operator_toml="${HOME}/.config/pmo-platform/operator.toml"
  if [ -z "$store" ] && [ -r "$operator_toml" ]; then
    # `|| true`: an absent key exits grep non-zero; tolerate and fall through.
    store="$( { grep -E '^operator_instance_finops_store_path' "$operator_toml" 2>/dev/null || true; } | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}')"
  fi
  if [ -z "$workspace_root" ] && [ -r "$operator_toml" ]; then
    workspace_root="$( { grep -E '^claude_workspace_root' "$operator_toml" 2>/dev/null || true; } | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}')"
  fi
  workspace_root="${workspace_root:-${HOME}/Claude}"
  store="${store:-${workspace_root}/pmo-instance/finops}"
  printf '%s' "$store"
}

# ── FM-2 fail-closed store guard — resolve-time, BEFORE any write/mkdir. ──
#    Refuses (exit 4) if the resolved store is inside a git repo but NOT git-ignored
#    there. A store outside any repo (rc=128 — the default case) is not committable
#    and proceeds. Keys on the store's CONTAINING repo, not the script's repo. An
#    optional second argument names another store-relative file to check (the
#    preserved prior-unit store), so every write path passes the same guard.
guard_store_git_ignored() {
  local store_dir="$1"
  local store_file="$store_dir/${2:-usage.jsonl}"
  # Nearest existing ancestor (store dir may not exist on first run) so `git -C` has a valid cwd.
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
      printf 'Refusing to write (public-repo exfil guard, FM-2 / #3909). Fix: point operator.toml\n' >&2
      printf '[paths].operator_instance_finops_store_path at an ignored or outside-repo path,\n' >&2
      printf 'or add a matching rule to %s/.gitignore.\n' "$store_repo" >&2
      exit 4
    fi
  fi
  # store_repo empty (rc=128 / no toplevel) → outside any repo → not committable → proceed.
  return 0
}

# ── jq program: emit one `session` record + N `subagent` records for one session file. ──
#    Input is the slurped array of all records (`jq -s`). Exact counts primary; the
#    #16 heuristic (4*words+2)/3 == ceil(words/0.75) mirrors est_tokens_from_words()
#    for usage-less records only.
read -r -d '' JQ_EXTRACT <<'JQEOF' || true
def wc:
  ( .message.content ) as $c
  | ( if   ($c|type)=="string" then $c
      elif ($c|type)=="array"  then ([ $c[]? | select(.type=="text") | .text ] | join(" "))
      else "" end )
  | gsub("^\\s+";"") | gsub("\\s+$";"")
  | if . == "" then 0 else ([splits("\\s+")] | length) end ;

# mirror of context-budget-auditor est_tokens_from_words (ceil(words/0.75)); fallback only.
def est: ((4 * . + 2) / 3) | floor ;

# ── Source-field seams (schema v1.2.0 analysis dimensions). ─────────────────────
# ONE named line per dimension: the source RECORD LOCATION of the three v1.2.0
# dimension fields is the only unverified assumption in this program, so it is
# isolated here. Each probes the top-level record AND `.message` so the extractor
# is correct under either placement; if a real store shows only one populates, the
# redundant leg is trimmed here and nowhere else.
def skill_of($r): ($r.attributionSkill // $r.message.attributionSkill // null) ;
def mcp_of($r):   ($r.attributionMcpServer // $r.message.attributionMcpServer // null) ;
def stop_of($r):  ($r.message.stop_reason // $r.stop_reason // null) ;

# Normalize any dimension key to a string, folding null/empty onto the RESERVED
# "unknown" bucket (the honesty mechanism — see schema § Analysis sub-aggregates).
def dim_key: if (. == null or . == "") then "unknown" else tostring end ;

# inc / unev count the completeness tag per_response puts on each response (below); every
# caller passes per_response output, so each record carries the tag.
def toksum($arr):
  ( [ $arr[] | select(.message.usage != null) ] ) as $ex
  | ( [ $arr[] | select(.message.usage == null) ] ) as $he
  | { input:    (([ $ex[] | .message.usage.input_tokens? // 0 ] | add // 0)
                 + ([ $he[] | wc | est ] | add // 0)),
      output:   ([ $ex[] | .message.usage.output_tokens? // 0 ] | add // 0),
      cc_total: ([ $ex[] | .message.usage.cache_creation_input_tokens? // 0 ] | add // 0),
      cc_1h:    ([ $ex[] | .message.usage.cache_creation.ephemeral_1h_input_tokens? // 0 ] | add // 0),
      cc_5m:    ([ $ex[] | .message.usage.cache_creation.ephemeral_5m_input_tokens? // 0 ] | add // 0),
      cread:    ([ $ex[] | .message.usage.cache_read_input_tokens? // 0 ] | add // 0),
      ws:       ([ $ex[] | .message.usage.server_tool_use.web_search_requests? // 0 ] | add // 0),
      wf:       ([ $ex[] | .message.usage.server_tool_use.web_fetch_requests? // 0 ] | add // 0),
      ht:       ($he | length),
      inc:      ([ $arr[] | select(.response_completeness == "incomplete") ] | length),
      unev:     ([ $arr[] | select(.response_completeness == "unevaluated") ] | length),
      turns:    ($arr | length) } ;

def tokens_obj($t): { input: $t.input, output: $t.output,
                      cache_creation: { total: $t.cc_total, ephemeral_1h: $t.cc_1h, ephemeral_5m: $t.cc_5m },
                      cache_read: $t.cread } ;
def tooluse_obj($t): { web_search_requests: $t.ws, web_fetch_requests: $t.wf } ;
def tsrc($t): if $t.ht == 0 then "exact" elif $t.ht >= $t.turns then "heuristic" else "mixed" end ;

# ── v1.2.0 per-session sub-aggregates (session-grain projections of turn data). ──
# dim_agg: partition $arr by `keyfn`, then reduce each group with the SAME toksum +
# tokens_obj used for session.tokens, so the leaf shape is byte-identical to
# session.tokens and the four leaves sum back to it. The reserved "unknown" key is
# SEEDED, so it is present even when empty — that is what makes the conservation
# invariant `sum(by_X.*.tokens) == session.tokens` hold for a partial dimension.
# The entry value is the WRAPPER {turns, tokens}, never a bare tokens object.
def dim_agg($arr; keyfn):
  ( [ $arr[] | { k: ((keyfn) | dim_key), r: . } ] ) as $tagged
  | ( reduce $tagged[] as $e ({ "unknown": [] }; . + { ($e.k): ((.[$e.k] // []) + [$e.r]) }) )
  | with_entries( .value = ( toksum(.value) as $t | { turns: $t.turns, tokens: tokens_obj($t) } ) ) ;

# count_agg: plain per-key integer counts. $seed pre-seeds reserved keys — {"unknown":0}
# for stop_reason (so `sum(stop_reason.*) == turns` is total), {} for tool_calls (a tool
# call is a count, not a partition of tokens, so it reserves nothing).
def count_agg($vals; $seed): reduce $vals[] as $k ($seed; . + { ($k): ((.[$k] // 0) + 1) }) ;

# The four cost-relevant leaves of a tokens object, per the schema summation invariant.
def leaf_total($t): ($t.input + $t.output + $t.cache_creation.total + $t.cache_read) ;

# dimension_coverage entry — a STORED PROJECTION of the map's "unknown" bucket
# (1 - uncovered/total, token basis; 1 when the session carries no tokens). Stored, not
# left derivable, because the label must be impossible to render without. The self-test
# asserts it agrees with the bucket, so the projection cannot drift from its source.
def dim_cov($map; $total):
  ( leaf_total($map["unknown"].tokens) ) as $u
  | { covered_token_fraction: ( if $total <= 0 then 1 else (($total - $u) / $total) end ),
      basis: "best-effort" } ;

# ── Per-response aggregation (schema v2.0.0). The unit of spend is the API RESPONSE: the
# transcript writes one line per content block and repeats the response's whole usage
# on each; a subagent transcript's first line can carry a PARTIAL streaming
# output_tokens. Every reducer consumes ONE line-shaped record per response, built
# here, so the reducers stay unchanged; a per-response property belongs here.
# resp_key is the source-format seam for the key; an id-less line is its own response.
# The grouping is per transcript file: a response that a resumed or forked session
# copied into another file is counted once in each (schema § Counting unit).
def resp_key($i):
  if   ((.message.id? // null) | type) == "string" and ((.message.id | length) > 0) then "id:" + .message.id
  elif ((.uuid? // null) | type) == "string" and ((.uuid | length) > 0)             then "uuid:" + .uuid
  else "ix:" + ($i | tostring) end ;
def umax($us; f): ([ $us[] | f | numbers ] | max) ;
def lastnn($vals): ([ $vals[] | select(. != null and . != "") ] | last) ;
# Each usage field is its MAXIMUM across the response's lines — order-independent, so a
# partial streaming output_tokens loses to its final value wherever the final line sits.
def merge_usage($us):
  if ($us | length) == 0 then null
  else { input_tokens:                umax($us; .input_tokens),
         output_tokens:               umax($us; .output_tokens),
         cache_creation_input_tokens: umax($us; .cache_creation_input_tokens),
         cache_creation: { ephemeral_1h_input_tokens: umax($us; .cache_creation.ephemeral_1h_input_tokens?),
                           ephemeral_5m_input_tokens: umax($us; .cache_creation.ephemeral_5m_input_tokens?) },
         cache_read_input_tokens:     umax($us; .cache_read_input_tokens),
         server_tool_use: { web_search_requests: umax($us; .server_tool_use.web_search_requests?),
                            web_fetch_requests:  umax($us; .server_tool_use.web_fetch_requests?) },
         service_tier: lastnn([ $us[] | .service_tier? ]) } end ;
def blocks: (.message.content // []) | if type == "string" then [ { type: "text", text: . } ]
                                       elif type == "array" then . else [] end ;
# A response's content blocks, with a tool_use block that its lines repeat kept once
# (by tool_use id), so tool_calls counts one call per id.
def dedupe_tool_use:
  reduce .[] as $b ({ seen: {}, out: [] };
    if (($b | type) == "object") and ($b.type == "tool_use") and ((($b.id // null) | type) == "string")
    then (if .seen[$b.id] then . else (.seen[$b.id] = true | .out += [ $b ]) end)
    else .out += [ $b ] end)
  | .out ;
# ── Response completeness (schema § Incomplete responses). The stop reason and the final
# cumulative usage arrive in one streaming event, so a response none of whose lines carries
# a stop reason holds only its opening snapshot: its output is provisional, its other usage
# fields can be too, and its server-side tool counts are absent. Three states:
#   complete     the response carries a stop reason;
#   incomplete   no stop reason, and the response is evaluable;
#   unevaluated  no stop reason, and not evaluable — never counted incomplete, and never
#                silently counted complete either.
# Evaluable: the lines were grouped by message.id — the group's key comes from resp_key's
# id branch, which holds only when EVERY line carries that id, because the lines are
# grouped by key — and every line carries a usage object and the stop_reason key, in either
# placement stop_of reads. Both line tests run on the raw lines: the merged record always
# carries message.stop_reason, so it cannot tell an absent key from a null one.
def msg_obj: (.message | if type == "object" then . else {} end) ;
def evaluable($k; $ls):
  ($k | startswith("id:"))
  and ([ $ls[] | select((msg_obj | .usage | type) != "object") ] | length) == 0
  and ([ $ls[] | select(((msg_obj | has("stop_reason")) or has("stop_reason")) | not) ] | length) == 0 ;
# Run on the merged record. Its stop reason is read through stop_of and dim_key, exactly as
# the stop_reason histogram reads it, so incomplete + unevaluated is that map's "unknown".
def completeness($k; $ls):
  if   (stop_of(.) | dim_key) != "unknown" then "complete"
  elif evaluable($k; $ls)                then "incomplete"
  else                                        "unevaluated" end ;

# CIAC-1 per-response-incomplete — this one per-response reduction carries both behaviours:
# a response written across several transcript lines is counted once (its usage
# max-merged), and the same merged record is tagged complete, incomplete or unevaluated
# (response_completeness) from the same group of lines. No second grouping pass exists.
# One record per response, in first-line order. It keeps the FIRST line's envelope
# (uuid, parentUuid, isSidechain, timestamp), takes the last non-null skill, MCP server,
# model and stop reason across the response's lines, and the max-merged usage.
def per_response($lines):
  [ $lines | to_entries[] | { k: (.key as $i | .value | resp_key($i)), i: .key, r: .value } ]
  | group_by(.k)
  | map({ k: .[0].k, first: (map(.i) | min), ls: (sort_by(.i) | map(.r)) })
  | sort_by(.first)
  | map( .k as $k | .ls as $ls
         | ( [ $ls[] | .message.usage | objects ] ) as $us
         | $ls[0]
           + { attributionSkill:     lastnn([ $ls[] | skill_of(.) ]),
               attributionMcpServer: lastnn([ $ls[] | mcp_of(.) ]),
               message: ( ($ls[0].message // {})
                          + { model:       lastnn([ $ls[] | .message.model? ]),
                              stop_reason: lastnn([ $ls[] | stop_of(.) ]),
                              content:     ([ $ls[] | blocks[] ] | dedupe_tool_use),
                              usage:       merge_usage($us) } ) }
         | . + { response_completeness: completeness($k; $ls) } ) ;

. as $all
| [ $all[] | select(.type=="assistant") ] as $asst
| [ $all[] | .timestamp // empty ] as $ts
# session_id = the filename stem (a unique UUID, one record per file). NOT the internal
# .sessionId, which real session resumption/forking can duplicate across files — that
# cross-file linkage is C2's attribution scope, not a C1 key.
| $sid_fallback as $sid
| ( [ $all[] | .cwd // empty ] | last ) as $cwd
# Data-minimization (schema v1.2.0): persist ONLY the working-directory BASENAME.
# `.cwd` is the SOURCE transcript's own field name (not ours to change); the store
# field is `worktree`, and the full absolute path is never written. `map(select(length>0))`
# makes it trailing-slash-safe ("/a/b/" -> "b", where a bare split|last yields "").
| ( if $cwd == null then null
    else ($cwd | split("/") | map(select(length > 0)) | last) end ) as $worktree
| ( [ $all[] | .gitBranch // empty ] | last ) as $branch
| ( [ $asst[] | .message.model // empty ] | last ) as $model
| ( [ $asst[] | .message.usage.service_tier? // empty ] | last ) as $tier
| ( if ($ts|length) > 0 then ($ts|first) else null end ) as $start
| ( if ($ts|length) > 0 then ($ts|last)  else null end ) as $end
# parent map + sidechain set (for in-transcript subagent grouping)
| ( reduce $all[] as $r ({}; if ($r.uuid != null) then . + {($r.uuid): ($r.parentUuid // null)} else . end) ) as $pmap
| ( reduce $all[] as $r ({}; if (($r.isSidechain == true) and ($r.uuid != null)) then . + {($r.uuid): true} else . end) ) as $sset
# each sidechain assistant record -> its sidechain-root uuid (walk parentUuid while parent is a sidechain)
| ( [ $asst[] | select(.isSidechain == true) | . as $rec
      | ( {u: $rec.uuid, i: 0}
          # sentinel: never a real uuid -> terminates the walk at a parentless record
          | until( ( ($sset[($pmap[.u] // "__no_parent__")] // false) | not ) or (.i >= 1000)
                 ; {u: ($pmap[.u] // .u), i: (.i + 1)} )
          | .u ) as $root
      | { root: $root, rec: $rec } ] ) as $side
| ( $side | group_by(.root) ) as $groups
| per_response($asst) as $resp
| toksum($resp) as $st
# ── v1.2.0 analysis dimensions — session-grain sub-aggregates over the SAME $resp set
#    (one record per API response) the session total is computed from, so every map
#    partitions session.tokens exactly.
| dim_agg($resp; skill_of(.))         as $by_skill
| dim_agg($resp; mcp_of(.))           as $by_mcp
| dim_agg($resp; .message.model)      as $by_model
| ( leaf_total(tokens_obj($st)) )     as $sess_total
# tool_calls counts CLIENT-SIDE invocations by name from the turn content — distinct
# from `tool_use`, which counts SERVER-SIDE requests from message.usage.server_tool_use.
| count_agg([ $resp[] | .message.content[]? | select(.type == "tool_use") | .name // empty ]; {})
    as $tool_calls
| count_agg([ $resp[] | stop_of(.) | dim_key ]; { "unknown": 0 }) as $stop_reason
# Only spend-bearing sessions (>=1 assistant record) yield a record. Files with zero
# assistant turns (project summary/index files, empty transcripts) carry no token spend
# and are skipped — this also excludes non-session `.jsonl` files under the projects root.
| if ($asst | length) == 0 then empty
  else
  (
  # session record (tokens is the WHOLE-FILE total, inclusive of sidechains)
  ( { record: "session", session_id: $sid, project_dir: $project_dir,
      worktree: $worktree, git_branch: $branch, started_utc: $start, ended_utc: $end,
      model: $model, service_tier: $tier, turns: $st.turns,
      tokens: tokens_obj($st), tool_use: tooluse_obj($st),
      by_skill: $by_skill, by_mcp: $by_mcp, by_model: $by_model,
      tool_calls: $tool_calls, stop_reason: $stop_reason,
      # Best-effort dimensions ONLY. by_model / tool_calls / stop_reason are exact by
      # construction and get NO entry — a constant 1.0 trains consumers to ignore the field.
      dimension_coverage: { by_skill: dim_cov($by_skill; $sess_total),
                            by_mcp:   dim_cov($by_mcp;   $sess_total) },
      subagent_count: ($groups | length), token_source: tsrc($st),
      heuristic_turns: $st.ht,
      incomplete_responses: $st.inc, unevaluated_responses: $st.unev,
      extracted_utc: $now } ),
  # subagent drill-down records (NOT summed on top of session.tokens)
  ( $groups[]
    | { root: .[0].root, recs: [ .[].rec ] } as $g
    | toksum(per_response($g.recs)) as $gt
    | [ $g.recs[] | .timestamp // empty ] as $gts
    | { record: "subagent", session_id: $sid, subagent_id: $g.root,
        parent_uuid: ($pmap[$g.root] // null), git_branch: $branch,
        service_tier: ( ([ $g.recs[] | .message.usage.service_tier? // empty ] | last) // $tier ),
        started_utc: ( if ($gts|length)>0 then ($gts|first) else null end ),
        ended_utc:   ( if ($gts|length)>0 then ($gts|last)  else null end ),
        model: ( [ $g.recs[] | .message.model // empty ] | last ),
        turns: $gt.turns, tokens: tokens_obj($gt), tool_use: tooluse_obj($gt),
        token_source: tsrc($gt), heuristic_turns: $gt.ht,
        incomplete_responses: $gt.inc, unevaluated_responses: $gt.unev,
        extracted_utc: $now } )
  )
  end
JQEOF

NOW_UTC() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Extract one session file -> JSONL records on stdout.
extract_file() {
  local f="$1" now="$2"
  local stem pdir
  stem="$(basename "$f" .jsonl)"
  pdir="$(basename "$(dirname "$f")")"
  # A malformed file must not abort the whole run — skip-with-warning, continue.
  if ! jq -c -s "$JQ_EXTRACT" \
        --arg sid_fallback "$stem" --arg project_dir "$pdir" --arg now "$now" \
        "$f" 2>/dev/null; then
    printf 'WARN: skipped unparseable session file: %s\n' "$f" >&2
  fi
}

# Build the store body (all session/subagent records, unsorted) to a temp file.
build_body() {
  local src_root="$1" now="$2" out="$3"
  : > "$out"
  local f
  while IFS= read -r f; do
    extract_file "$f" "$now" >> "$out"
  done < <(find "$src_root" -type f -name '*.jsonl' 2>/dev/null)
}

# Write meta line + deterministically-sorted body to the store, atomically.
write_store() {
  local store_dir="$1" src_root="$2" created="$3" last="$4" body="$5"
  local tmp="$store_dir/usage.jsonl.tmp"
  jq -cn --arg sv "$SCHEMA_VERSION" --arg gen "finops-usage-extractor" --arg genver "$(generator_version)" \
     --arg root "$src_root" --arg created "$created" --arg last "$last" \
     '{record:"meta", schema:"finops-usage-store", schema_version:$sv, generated_by:$gen,
       generator_version:$genver, source_root:$root, created_utc:$created,
       last_extract_utc:$last,
       token_model:"exact-source; fallback ceil(words/0.75) per context-budget-auditor"}' > "$tmp"
  # Deterministic order: a TOTAL sort key (started_utc, session_id, record kind —
  # session < subagent — then subagent_id) so two rebuilds over unchanged source are
  # byte-identical regardless of filesystem `find` order.
  if [ -s "$body" ]; then
    jq -s -c 'sort_by(.started_utc, .session_id, .record, (.subagent_id // ""))[]' "$body" >> "$tmp"
  fi
  mv -f "$tmp" "$store_dir/usage.jsonl"
}

# A store of another counting unit is never rebuilt over: a 1.x store counted per
# transcript line (inflated), and a session whose transcript is gone exists nowhere
# else. Keep it at every crossing, as a store, at prior/schema-<old>/usage.jsonl — a hard
# link (no copy, no moment without a store; cp is the fallback), so the existing tools read
# it with STORE=<store>/prior/schema-<old>. A kept store is never overwritten: while that
# path holds one an earlier crossing from the same version kept, this crossing's goes to
# prior/schema-<old>-<UTC stamp>/usage.jsonl, and only an existing stamped path refuses
# (exit 3). A store of the current unit (same major) is rebuilt over as before. Fails
# closed: exit 3, the store and its directory unchanged.
preserve_prior_unit_store() {
  local store_dir="$1" f="$1/usage.jsonl" old rel dest dest_dir made_prior=0 made_dir=0
  [ -f "$f" ] || return 0
  old="$(store_schema_version "$f")"
  same_counting_unit "$old" && return 0
  rel="prior/schema-${old}/usage.jsonl"
  [ -e "$store_dir/$rel" ] && rel="prior/schema-${old}-$(date -u +%Y%m%dT%H%M%SZ)/usage.jsonl"
  dest="$store_dir/$rel"
  dest_dir="$(dirname "$dest")"
  if [ -e "$dest" ]; then
    printf 'FATAL (exit 3): could not preserve the schema-%s store — %s already exists; the store is left UNCHANGED at %s\n' "$old" "$rel" "$f" >&2
    return 3
  fi
  guard_store_git_ignored "$store_dir" "$rel"
  [ -d "$store_dir/prior" ] || made_prior=1
  [ -d "$dest_dir" ] || made_dir=1
  if mkdir -p "$dest_dir" 2>/dev/null && { ln "$f" "$dest" 2>/dev/null || cp -p "$f" "$dest" 2>/dev/null; }; then
    printf 'finops-usage-extractor: kept the schema-%s store as %s — %s; sessions whose transcripts are gone exist only there\n' "$old" "$rel" "$(counting_unit_note "$old")" >&2
    return 0
  fi
  # Undo only what this call created: a partial copy, then the directories it made.
  rm -f "$dest" 2>/dev/null
  [ "$made_dir" -eq 1 ] && rmdir "$dest_dir" 2>/dev/null
  [ "$made_prior" -eq 1 ] && rmdir "$store_dir/prior" 2>/dev/null
  printf 'FATAL (exit 3): could not preserve the schema-%s store before rebuilding; the store is left UNCHANGED at %s\n' "$old" "$f" >&2
  return 3
}

# The rebuild summary's completeness clause: the two counts summed over the session
# records. A record without them was not evaluated, so a missing count prints "?", never 0.
completeness_summary() {
  jq -rs '[ .[] | select(.record=="session") ] as $s
          | if ([ $s[] | select((.incomplete_responses | type) != "number" or (.unevaluated_responses | type) != "number") ] | length) > 0
            then "? API response(s) flagged incomplete (a session record lacks the counts)"
            else "\([ $s[].incomplete_responses ] | add // 0) API response(s) flagged incomplete, \([ $s[].unevaluated_responses ] | add // 0) not evaluated"
            end' "$1" 2>/dev/null || printf '? API response(s) flagged incomplete'
}

do_rebuild() {
  local store_dir="$1" src_root="$2"
  local now body
  now="$(NOW_UTC)"
  mkdir -p "$store_dir"
  preserve_prior_unit_store "$store_dir" || return 3
  body="$(mktemp "${TMPDIR:-/tmp}/finops-body.XXXXXX")"
  build_body "$src_root" "$now" "$body"
  write_store "$store_dir" "$src_root" "$now" "$now" "$body"
  rm -f "$body"
  printf 'finops-usage-extractor: rebuilt %s (%s session record(s); %s)\n' \
    "$store_dir/usage.jsonl" "$(jq -r 'select(.record=="session")' "$store_dir/usage.jsonl" 2>/dev/null | jq -s 'length' 2>/dev/null || echo '?')" \
    "$(completeness_summary "$store_dir/usage.jsonl")" >&2
}

do_incremental() {
  local store_dir="$1" src_root="$2"
  local store_file="$store_dir/usage.jsonl"
  [ -f "$store_file" ] || { do_rebuild "$store_dir" "$src_root"; return; }
  # Records of another counting unit cannot be upserted into: a per-response record
  # beside per-line ones would put two units under one version. Same unit (same schema
  # major) → upsert as usual; anything else → rebuild, which preserves the prior store.
  local on_disk
  on_disk="$(store_schema_version "$store_file")"
  if ! same_counting_unit "$on_disk"; then
    printf "finops-usage-extractor: incremental — the store declares schema %s: %s. This writer counts under schema %s, so its records cannot be upserted into that store; falling back to --rebuild\n" "$on_disk" "$(counting_unit_note "$on_disk")" "$SCHEMA_VERSION" >&2
    do_rebuild "$store_dir" "$src_root"
    return $?
  fi
  local now created changed body merged
  now="$(NOW_UTC)"
  created="$( { jq -r 'select(.record=="meta") | .created_utc' "$store_file" 2>/dev/null || true; } | head -1)"
  created="${created:-$now}"
  # Changed = source files newer than the store file (mtime gate).
  changed="$(mktemp "${TMPDIR:-/tmp}/finops-chg.XXXXXX")"
  local f
  while IFS= read -r f; do
    if [ "$f" -nt "$store_file" ]; then printf '%s\n' "$f" >> "$changed"; fi
  done < <(find "$src_root" -type f -name '*.jsonl' 2>/dev/null)
  if [ ! -s "$changed" ]; then
    rm -f "$changed"
    printf 'finops-usage-extractor: incremental — no source change; store unchanged\n' >&2
    return
  fi
  # Re-extract changed files; collect their session_ids.
  body="$(mktemp "${TMPDIR:-/tmp}/finops-body.XXXXXX")"; : > "$body"
  local ids
  ids="$(mktemp "${TMPDIR:-/tmp}/finops-ids.XXXXXX")"; : > "$ids"
  while IFS= read -r f; do
    extract_file "$f" "$now" >> "$body"
  done < "$changed"
  # The drop-set is the SAME class of read as the carry-forward below, and it fails in
  # the OPPOSITE direction: an unread drop-set is an EMPTY drop-set, so carry-forward
  # drops NOTHING and the `cat "$body" >> "$merged"` append below re-adds every
  # re-extracted session on top of the copy already carried forward — DUPLICATING
  # session records instead of superseding them. Silently wrong, and just as
  # data-affecting as the truncation the carry-forward guard closes. Fail closed and
  # leave the existing store untouched. Never `2>/dev/null` on this path.
  local ids_err="${ids}.err"
  if ! jq -r 'select(.record=="session") | .session_id' "$body" 2>"$ids_err" | sort -u > "$ids"; then
    printf 'FATAL (exit 3): incremental drop-set read failed over the re-extracted records; the store is left UNCHANGED at %s\n' "$store_file" >&2
    sed 's/^/  jq: /' "$ids_err" >&2
    printf 'Recover with: bash %s --rebuild\n' "${BASH_SOURCE[0]}" >&2
    rm -f "$changed" "$body" "$ids" "$ids_err"
    return 3
  fi
  rm -f "$ids_err"
  # Carry forward existing records whose session_id is NOT in the changed set.
  # Same class, same direction: the shipped `|| echo '[]'` WAS the fail-open — it
  # converted a failed read into an empty drop-set, which carry-forward then honours
  # as "drop nothing". A legitimately empty "$ids" still yields `[]` on the SUCCESS
  # path (both stages exit 0 on empty input), so this guard fires only on real failure.
  local drop_json drop_err="${ids}.drop.err"
  : > "$drop_err"
  if ! drop_json="$(jq -R . "$ids" 2>>"$drop_err" | jq -s -c '.' 2>>"$drop_err")"; then
    printf 'FATAL (exit 3): incremental drop-set could not be assembled; the store is left UNCHANGED at %s\n' "$store_file" >&2
    sed 's/^/  jq: /' "$drop_err" >&2
    printf 'Recover with: bash %s --rebuild\n' "${BASH_SOURCE[0]}" >&2
    rm -f "$changed" "$body" "$ids" "$drop_err"
    return 3
  fi
  rm -f "$drop_err"
  merged="$(mktemp "${TMPDIR:-/tmp}/finops-merge.XXXXXX")"
  local merged_err="${merged}.err"
  # Carry-forward is a READ of an already-written store; there is no benign failure
  # here. A non-zero means the filter is wrong or the store is corrupt, and in BOTH
  # cases falling through to write_store silently TRUNCATES the store to just the
  # re-extracted sessions. Fail closed and leave the existing store untouched.
  # `.` is rebound to $drop inside the pipe, so the record MUST be bound first:
  # `($drop | index(.session_id))` indexes an array with a string and errors on
  # every record. Never `2>/dev/null || true` on this path.
  if ! jq -c --argjson drop "$drop_json" \
        'select(.record=="session" or .record=="subagent")
         | . as $r | select( ($drop | index($r.session_id)) | not )' \
        "$store_file" > "$merged" 2>"$merged_err"; then
    printf 'FATAL (exit 3): incremental carry-forward could not read the store; it is left UNCHANGED at %s\n' "$store_file" >&2
    sed 's/^/  jq: /' "$merged_err" >&2
    printf 'Recover with: bash %s --rebuild\n' "${BASH_SOURCE[0]}" >&2
    rm -f "$changed" "$body" "$ids" "$merged" "$merged_err"
    return 3
  fi
  rm -f "$merged_err"
  cat "$body" >> "$merged"
  write_store "$store_dir" "$src_root" "$created" "$now" "$merged"
  rm -f "$changed" "$body" "$ids" "$merged"
  printf 'finops-usage-extractor: incremental upsert complete\n' >&2
}

# ── Self-test: assertions against synthetic fixtures only (no operator-store / source). ──
self_test() {
  local fail=0
  # 1) Heuristic estimator reused from #16 (verbatim formula).
  [ "$(est_tokens_from_words 3)" = "4" ]   || { echo "FAIL: est_tokens_from_words(3) != 4"; fail=1; }
  [ "$(est_tokens_from_words 750)" = "1000" ] || { echo "FAIL: est_tokens_from_words(750) != 1000"; fail=1; }

  [ -d "$FIXTURES_DIR" ] || { echo "FAIL: fixtures dir missing: $FIXTURES_DIR"; return 1; }

  local st_store src
  st_store="$(mktemp -d "${TMPDIR:-/tmp}/finops-selftest.XXXXXX")"
  src="$FIXTURES_DIR"

  # 2) Rebuild is DETERMINISTIC: the record body is byte-identical across two rebuilds
  #    over unchanged source, MODULO the extraction-time metadata (extracted_utc per
  #    record + the meta line's created/last_extract timestamps), which update by design.
  STORE="$st_store" FINOPS_SOURCE_ROOT="$src" do_rebuild "$st_store" "$src"
  jq -c 'select(.record!="meta") | del(.extracted_utc)' "$st_store/usage.jsonl" > "$st_store/norm1.jsonl" 2>/dev/null
  STORE="$st_store" FINOPS_SOURCE_ROOT="$src" do_rebuild "$st_store" "$src"
  jq -c 'select(.record!="meta") | del(.extracted_utc)' "$st_store/usage.jsonl" > "$st_store/norm2.jsonl" 2>/dev/null
  if ! diff -q "$st_store/norm1.jsonl" "$st_store/norm2.jsonl" >/dev/null 2>&1; then
    echo "FAIL: rebuild body not deterministic (non-stable order/content across rebuilds)"; fail=1
  fi

  # 3) No duplicate session_id.
  local dups
  dups="$(jq -r 'select(.record=="session") | .session_id' "$st_store/usage.jsonl" 2>/dev/null | sort | uniq -d)"
  [ -z "$dups" ] || { echo "FAIL: duplicate session_id(s): $dups"; fail=1; }

  # 4) At least one session record produced.
  local nsess
  nsess="$(jq -s '[.[] | select(.record=="session")] | length' "$st_store/usage.jsonl" 2>/dev/null)"
  [ "${nsess:-0}" -ge 1 ] || { echo "FAIL: no session records produced"; fail=1; }

  # 5) Cache-tier invariant: ephemeral_1h + ephemeral_5m == cache_creation.total per session
  #    (holds for the exact-only fixtures where tiers are populated).
  local tier_bad
  tier_bad="$(jq -s '[.[] | select(.record=="session")
                     | select((.tokens.cache_creation.ephemeral_1h + .tokens.cache_creation.ephemeral_5m)
                              != .tokens.cache_creation.total)
                     | .session_id] | length' "$st_store/usage.jsonl" 2>/dev/null)"
  [ "${tier_bad:-0}" -eq 0 ] || { echo "FAIL: cache-tier invariant broken on $tier_bad session(s)"; fail=1; }

  # 6) Summation-invariant sanity: subagent tokens are a drill-down already inside the
  #    session total (never negative; session with sidechains reports subagent_count>0).
  #    + provenance: heuristic fixture flags token_source != "exact".
  local prov
  prov="$(jq -s '[.[] | select(.record=="session" and .token_source=="heuristic")] | length' "$st_store/usage.jsonl" 2>/dev/null)"
  [ "${prov:-0}" -ge 1 ] || { echo "FAIL: heuristic fixture did not yield token_source=heuristic"; fail=1; }

  # 7) Oracle comparison: session token digest matches the committed .expected.json (if present).
  local oracle="$FIXTURES_DIR/usage.expected.json"
  if [ -f "$oracle" ]; then
    local got want
    got="$(jq -s -S '[.[] | select(.record=="session")
                    | {session_id, tokens, tool_use, token_source, heuristic_turns, subagent_count,
                       by_skill, by_mcp, by_model, tool_calls, stop_reason, dimension_coverage}]
                    | sort_by(.session_id)' "$st_store/usage.jsonl" 2>/dev/null)"
    want="$(jq -S '. | sort_by(.session_id)' "$oracle" 2>/dev/null)"
    if [ "$got" != "$want" ]; then
      echo "FAIL: extraction does not match oracle usage.expected.json"; fail=1
    fi
  fi

  # 8b) Subagent drill-down records emitted for the sidechain fixtures (root grouping):
  #     proj-gamma's in-transcript sidechain, and the partial-output and no-final-output
  #     subagent transcripts, every record of which is a sidechain as in a real
  #     spawned-agent file. The input check is scoped to proj-gamma, so a further sidechain
  #     fixture moves the count only.
  local nsub subin
  nsub="$(jq -s '[.[] | select(.record=="subagent")] | length' "$st_store/usage.jsonl" 2>/dev/null)"
  [ "${nsub:-0}" -eq 3 ] || { echo "FAIL: expected exactly 3 subagent records (proj-gamma's sidechain + the partial-output and no-final-output subagent transcripts), got ${nsub:-0}"; fail=1; }
  subin="$(jq -s '[.[] | select(.record=="subagent" and .session_id=="00000000-0000-4000-8000-000000000003") | .tokens.input] | add // 0' "$st_store/usage.jsonl" 2>/dev/null)"
  [ "${subin:-0}" -eq 28 ] || { echo "FAIL: proj-gamma subagent input tokens != 28 (got ${subin:-0})"; fail=1; }

  # R1) three-block — a response written across several transcript lines (one per content
  #     block, each repeating the response's usage) is counted ONCE. Fixture
  #     per-response/proj-zeta/…0006: three responses on six assistant lines. The
  #     three-block response's last line carries a deliberately LOWER cache_read (97
  #     against 98), so a last-line-wins merge reads cache_read 232 and fails here, as
  #     does the per-line sum [109,71,48,491,6,2]; only the per-field max-merge reads
  #     [42,27,18,233,3,1]. The repeated tool_use id counts one Read call, not two.
  #     Non-vacuity first: the fixture must still write a response across several lines.
  local f6 f6_lines f6_resp r1_got
  f6="$FIXTURES_DIR/per-response/proj-zeta/00000000-0000-4000-8000-000000000006.jsonl"
  f6_lines="$(jq -s '[.[] | select(.type=="assistant")] | length' "$f6" 2>/dev/null)"
  f6_resp="$(jq -s '[.[] | select(.type=="assistant") | .message.id] | unique | length' "$f6" 2>/dev/null)"
  if [ -z "$f6_lines" ] || [ -z "$f6_resp" ] || [ "$f6_lines" -le "$f6_resp" ]; then
    echo "FAIL: three-block arm is vacuous — its fixture no longer writes a response across several lines (lines=${f6_lines:-?}, responses=${f6_resp:-?})"; fail=1
  fi
  r1_got="$(jq -c 'select(.record=="session" and .session_id=="00000000-0000-4000-8000-000000000006")
                   | [.tokens.input, .tokens.output, .tokens.cache_creation.total, .tokens.cache_read, .turns, (.tool_calls.Read // 0)]' \
            "$st_store/usage.jsonl" 2>/dev/null)"
  [ "$r1_got" = "[42,27,18,233,3,1]" ] \
    || { echo "FAIL: three-block response not counted once per API response (got ${r1_got:-nothing}, want [42,27,18,233,3,1])"; fail=1; }

  # R2) partial-output — a subagent response whose FIRST line carries a partial streaming
  #     output_tokens is recorded at its final value. Fixture per-response/proj-eta/
  #     …0007/subagents/agent-00000000000000007, in the real spawned-agent layout:
  #     first-line output 2, final 25. The per-line sum reads [27,2,80], and a
  #     first-line-wins merge reads output 2. Non-vacuity first, as in R1.
  local f7 f7_first f7_last r2_sess r2_sub
  f7="$FIXTURES_DIR/per-response/proj-eta/00000000-0000-4000-8000-000000000007/subagents/agent-00000000000000007.jsonl"
  f7_first="$(jq -s '[.[] | select(.type=="assistant") | .message.usage.output_tokens] | first' "$f7" 2>/dev/null)"
  f7_last="$(jq -s '[.[] | select(.type=="assistant") | .message.usage.output_tokens] | last' "$f7" 2>/dev/null)"
  case "${f7_first:-x}${f7_last:-x}" in
    *[!0-9]*) f7_first=0; f7_last=0 ;;
  esac
  [ "$f7_first" -lt "$f7_last" ] \
    || { echo "FAIL: partial-output arm is vacuous — its fixture's first line no longer carries an output_tokens below the final"; fail=1; }
  r2_sess="$(jq -c 'select(.record=="session" and .session_id=="agent-00000000000000007") | [.tokens.output, .turns, .tokens.input]' "$st_store/usage.jsonl" 2>/dev/null)"
  [ "$r2_sess" = "[25,1,40]" ] \
    || { echo "FAIL: partial-output subagent response: the session record did not take the final output_tokens (got ${r2_sess:-nothing}, want [25,1,40])"; fail=1; }
  r2_sub="$(jq -c 'select(.record=="subagent" and .session_id=="agent-00000000000000007") | [.tokens.output, .turns]' "$st_store/usage.jsonl" 2>/dev/null)"
  [ "$r2_sub" = "[25,1]" ] \
    || { echo "FAIL: partial-output subagent response: the subagent record did not take the final output_tokens (got ${r2_sub:-nothing}, want [25,1])"; fail=1; }

  # K) v1.2.0 analysis dimensions — STRUCTURAL invariants, asserted independently of the
  #    oracle (the oracle pins values; this pins the contract, so it still holds if the
  #    fixtures change). Reports every violation by session + dimension, not just a count.
  local dim_bad dim_rc
  dim_bad="$(jq -s -r '
    # Null-safe leaves: a malformed record must produce a REPORTED violation, never a jq
    # hard error — an aborted check emits nothing, and nothing reads as PASS (fail-open).
    def leaf($t): (($t.input // 0) + ($t.output // 0) + ($t.cache_creation.total // 0) + ($t.cache_read // 0));
    def absf: if . < 0 then (0 - .) else . end;
    def dsum($m): { i: ([ $m[].tokens.input ] | add // 0),
                    o: ([ $m[].tokens.output ] | add // 0),
                    c: ([ $m[].tokens.cache_creation.total ] | add // 0),
                    h: ([ $m[].tokens.cache_creation.ephemeral_1h ] | add // 0),
                    f: ([ $m[].tokens.cache_creation.ephemeral_5m ] | add // 0),
                    r: ([ $m[].tokens.cache_read ] | add // 0),
                    t: ([ $m[].turns ] | add // 0) };
    [ .[] | select(.record=="session") | . as $s
      | (
          # (K1) every token-bearing map: reserved "unknown" present + leaf-by-leaf
          #      conservation against session.tokens, and turns conservation too.
          ( ["by_skill","by_mcp","by_model"][] as $d
            | ($s[$d]) as $m
            | if   ($m == null)                      then "\($s.session_id): \($d) absent"
              elif ($m | has("unknown") | not)       then "\($s.session_id): \($d) missing reserved \"unknown\" key"
              elif ([ $m[] | has("tokens") | not ] | any) then "\($s.session_id): \($d) entry is not the {turns,tokens} wrapper"
              else ( dsum($m) as $g
                     | if ($g.i != $s.tokens.input or $g.o != $s.tokens.output
                           or $g.c != $s.tokens.cache_creation.total
                           or $g.h != $s.tokens.cache_creation.ephemeral_1h
                           or $g.f != $s.tokens.cache_creation.ephemeral_5m
                           or $g.r != $s.tokens.cache_read)
                       then "\($s.session_id): \($d) conservation broken (sum(\($d).*.tokens) != session.tokens)"
                       elif ($g.t != $s.turns)
                       then "\($s.session_id): \($d) turns conservation broken (\($g.t) != \($s.turns))"
                       else empty end ) end ),
          # (K2) stop_reason is a total partition of the assistant turns.
          ( if   (($s.stop_reason // null) == null)              then "\($s.session_id): stop_reason absent"
            elif ($s.stop_reason | has("unknown") | not)         then "\($s.session_id): stop_reason missing reserved \"unknown\" key"
            elif (([ $s.stop_reason[] ] | add // 0) != $s.turns) then "\($s.session_id): sum(stop_reason.*) != turns"
            else empty end ),
          # (K3) tool_calls is always an object (never absent) and is NOT tool_use.
          ( if (($s.tool_calls // null) | type) != "object" then "\($s.session_id): tool_calls absent or not an object" else empty end ),
          # (K4) dimension_coverage is the stored projection of the "unknown" bucket.
          ( ["by_skill","by_mcp"][] as $d
            | ( leaf($s.tokens) ) as $tot
            | ( leaf($s[$d]["unknown"].tokens) ) as $unk
            | ( if $tot <= 0 then 1 else (($tot - $unk) / $tot) end ) as $want
            | ( $s.dimension_coverage[$d] ) as $cv
            | if   ($cv == null)                                                    then "\($s.session_id): dimension_coverage.\($d) missing"
              elif ((($cv.covered_token_fraction - $want) | absf) > 0.000001)       then "\($s.session_id): dimension_coverage.\($d) != 1 - (unknown/total)"
              elif ($cv.covered_token_fraction < 0 or $cv.covered_token_fraction > 1) then "\($s.session_id): dimension_coverage.\($d) outside [0,1]"
              elif ((["best-effort","exact"] | index($cv.basis)) == null)           then "\($s.session_id): dimension_coverage.\($d).basis not in the enum"
              else empty end ),
          # (K5) the exact-by-construction dimensions get NO coverage entry — a constant
          #      1.0 would train a renderer to ignore the field.
          ( ["by_model","tool_calls","stop_reason"][] as $d
            | if ($s.dimension_coverage | has($d))
              then "\($s.session_id): dimension_coverage must NOT carry \($d) (exact by construction)"
              else empty end )
        ) ] | .[]' "$st_store/usage.jsonl" 2>&1)"; dim_rc=$?
  # An honesty check that cannot run must FAIL, never pass silently: a jq abort yields no
  # output, and "no violations reported" would otherwise be indistinguishable from "clean".
  if [ "$dim_rc" -ne 0 ]; then
    echo "FAIL: v1.2.0 analysis-dimension check could not run (jq exit $dim_rc) — not treated as clean:"
    printf '%s\n' "$dim_bad" | sed 's/^/       /'
    fail=1
  elif [ -n "$dim_bad" ]; then
    echo "FAIL: v1.2.0 analysis-dimension invariants:"
    printf '%s\n' "$dim_bad" | sed 's/^/       /'
    fail=1
  fi

  # NF) no-final-output — the incomplete-response flag (CIAC-1 per-response-incomplete).
  #     Fixture per-response/subagents/agent-afixture-no-final-output: eight API responses,
  #     every record a sidechain as in a real spawned-agent file. A to D are write shapes
  #     measured in real transcripts: A writes a snapshot line and then its stop reason
  #     (complete — the near-miss an any-line-null test flags), B (two lines) and C (one)
  #     carry no stop reason on any line (incomplete), and D is one closing line. E, F and
  #     G carry no stop reason and each fails exactly ONE evaluability clause — no
  #     stop_reason key, no message.id, no usage block — so each is not evaluated, and
  #     deleting that clause would count it incomplete. H carries the stop_reason key only
  #     at the record's top level, the other placement stop_of reads, so it is evaluable
  #     and incomplete. Every failure message below names this arm, and the release-tooling
  #     smoke workflow's no-final-output precision probe reads that name: in a throwaway copy
  #     it rewrites the stop-reason test to the any-line-null form and requires this arm's
  #     FAIL line.
  local nf_got nf_tot nf_bad nf_rc
  nf_got="$(jq -s -c '[ .[] | select((.record=="session" or .record=="subagent") and .session_id=="agent-afixture-no-final-output")
                        | [.record, .incomplete_responses, .unevaluated_responses] ] | sort' "$st_store/usage.jsonl" 2>/dev/null)"
  [ "$nf_got" = '[["session",3,3],["subagent",3,3]]' ] \
    || { echo "FAIL: no-final-output — the fixture's [record, incomplete_responses, unevaluated_responses] read ${nf_got:-nothing}, want one session and one subagent record, each [3,3]"; fail=1; }
  # Corpus specificity: no other fixture counts as incomplete — the proj-zeta and proj-eta
  # per-response fixtures write a snapshot line before the closing one, which an
  # any-line-null test would flag — and the unevaluated set is the 7 responses of the
  # id-less pre-v2.0.0 fixtures that carry no stop reason, plus E, F and G.
  nf_tot="$(jq -s -c '[ .[] | select(.record=="session") ] | [ ([ .[].incomplete_responses ] | add), ([ .[].unevaluated_responses ] | add) ]' "$st_store/usage.jsonl" 2>/dev/null)"
  [ "$nf_tot" = "[3,10]" ] \
    || { echo "FAIL: no-final-output — the fixture corpus's session records carry [incomplete, unevaluated] = ${nf_tot:-nothing}, want [3,10]"; fail=1; }
  # Presence (an absent count is not a zero) and the bounds, on every record. An incomplete
  # response carries usage on every line, so it is never a heuristic one; an unevaluated one
  # may be, so the two bounds differ. On a session record the two counts are exactly the
  # stop_reason map's "unknown" bucket, because both read the stop reason through stop_of
  # on the same merged response.
  nf_bad="$(jq -s -r '
    [ .[] | select(.record=="session" or .record=="subagent") | . as $r
      | if ((($r.incomplete_responses | type) != "number") or (($r.unevaluated_responses | type) != "number")
            or ($r.incomplete_responses < 0) or ($r.unevaluated_responses < 0))
        then "\($r.record) \($r.session_id): incomplete_responses / unevaluated_responses absent or negative"
        elif $r.incomplete_responses > (($r.turns // 0) - ($r.heuristic_turns // 0))
        then "\($r.record) \($r.session_id): incomplete_responses exceeds turns - heuristic_turns"
        elif ($r.incomplete_responses + $r.unevaluated_responses) > ($r.turns // 0)
        then "\($r.record) \($r.session_id): incomplete_responses + unevaluated_responses exceeds turns"
        elif ($r.record == "session") and (($r.incomplete_responses + $r.unevaluated_responses) != ($r.stop_reason["unknown"] // -1))
        then "\($r.session_id): incomplete_responses + unevaluated_responses != stop_reason.unknown"
        else empty end ] | .[]' "$st_store/usage.jsonl" 2>&1)"; nf_rc=$?
  if [ "$nf_rc" -ne 0 ]; then
    echo "FAIL: no-final-output — the invariant check could not run (jq exit $nf_rc), not treated as clean:"
    printf '%s\n' "$nf_bad" | sed 's/^/       /'; fail=1
  elif [ -n "$nf_bad" ]; then
    echo "FAIL: no-final-output invariants:"
    printf '%s\n' "$nf_bad" | sed 's/^/       /'; fail=1
  fi

  # 8) Incremental idempotence: no source change -> session digest unchanged, no dup.
  local d1 d2
  d1="$(jq -s -S '[.[] | select(.record=="session") | {session_id, tokens}] | sort_by(.session_id)' "$st_store/usage.jsonl" 2>/dev/null)"
  STORE="$st_store" FINOPS_SOURCE_ROOT="$src" do_incremental "$st_store" "$src"
  d2="$(jq -s -S '[.[] | select(.record=="session") | {session_id, tokens}] | sort_by(.session_id)' "$st_store/usage.jsonl" 2>/dev/null)"
  [ "$d1" = "$d2" ] || { echo "FAIL: incremental (no change) altered the session digest"; fail=1; }

  # 9) Incremental CARRY-FORWARD branch. Step 8 exercises only the no-source-change
  #    EARLY RETURN; the carry-forward filter it exits before is the branch that
  #    silently truncated the store. Drives that branch on a THROWAWAY copy of the
  #    fixtures (never the checked-in tree) with deterministic `touch -t` mtimes (no
  #    sleep, no race), then asserts prior records SURVIVE. Every guard fails LOUD —
  #    a sub-test that cannot set itself up is a FAILURE, never a silent skip.
  #    INVARIANT: every failure message below contains the literal "carry-forward";
  #    the carry-forward precision probe in the release-tooling smoke workflow greps
  #    for it to confirm a non-zero exit came from THIS block, not an unrelated
  #    regression. Keep this block AFTER the analysis-dimension block above, so that
  #    probe's own marker is already emitted whatever this block does.
  local cf_src cf_store cf_pick cf_file cf_base cf_after cf_err cf_rc cf_n cf_nsub
  cf_src="$(mktemp -d "${TMPDIR:-/tmp}/finops-cfsrc.XXXXXX")"
  cf_store="$(mktemp -d "${TMPDIR:-/tmp}/finops-cfstore.XXXXXX")"
  cp -R "$FIXTURES_DIR/." "$cf_src/" 2>/dev/null
  STORE="$cf_store" FINOPS_SOURCE_ROOT="$cf_src" do_rebuild "$cf_store" "$cf_src" 2>/dev/null
  cf_n="$(jq -s '[.[] | select(.record=="session")] | length' "$cf_store/usage.jsonl" 2>/dev/null)"
  cf_nsub="$(jq -s '[.[] | select(.record=="subagent")] | length' "$cf_store/usage.jsonl" 2>/dev/null)"
  cf_base="$(jq -s -S '[.[] | select(.record=="session" or .record=="subagent")
                        | {record, session_id, subagent_id, tokens, turns}]
                       | sort_by(.session_id, .record, (.subagent_id // ""))' "$cf_store/usage.jsonl" 2>/dev/null)"
  if [ "${cf_n:-0}" -lt 2 ]; then
    echo "FAIL: carry-forward sub-test cannot run — needs >=2 fixture session records, got ${cf_n:-0}"; fail=1
  else
    # All sources OLD, store MIDDLE, exactly one source NEW. `touch -t` is the portable
    # form across BSD (macOS) and GNU (CI runners); `touch -d` is not.
    find "$cf_src" -type f -name '*.jsonl' -exec touch -t 202001010000 {} + 2>/dev/null
    touch -t 202006010000 "$cf_store/usage.jsonl" 2>/dev/null
    # `head` closes its input on the first line, and every producer still upstream
    # inherits the broken pipe (#3832). `sort` has to consume the whole stream
    # regardless, so it is snapshotted rather than bounded; `find` answers the
    # first-hit question directly with `-print -quit`.
    cf_pick="$(head -1 <<<"$( { jq -r 'select(.record=="session") | .session_id' "$cf_store/usage.jsonl" 2>/dev/null || true; } | sort)")"
    cf_file="$(find "$cf_src" -type f -name "${cf_pick:-__none__}.jsonl" -print -quit 2>/dev/null || true)"
    if [ -z "$cf_pick" ] || [ -z "$cf_file" ]; then
      echo "FAIL: carry-forward sub-test cannot resolve a source file for session '${cf_pick:-}'"; fail=1
    else
      touch -t 202101010000 "$cf_file" 2>/dev/null
      cf_err="$cf_store/incr.err"
      STORE="$cf_store" FINOPS_SOURCE_ROOT="$cf_src" do_incremental "$cf_store" "$cf_src" 2>"$cf_err"; cf_rc=$?
      if [ "$cf_rc" -ne 0 ]; then
        echo "FAIL: carry-forward incremental run exited $cf_rc (fail-closed guard; store left unchanged):"
        sed 's/^/       /' "$cf_err"
        fail=1
      else
        # Branch-entry proof A (wording-independent): the early return never rewrites the
        # store, so its mtime would still be the staged 2020 value.
        [ "$cf_store/usage.jsonl" -nt "$cf_file" ] \
          || { echo "FAIL: carry-forward branch not reached — store was not rewritten (mtime gate did not fire)"; fail=1; }
        # Branch-entry proof B (redundant, marker-keyed): the carry-forward path's own
        # message, not the early return's. Two independent proofs, because the defect
        # class here is a check that silently stops evaluating.
        grep -q 'incremental upsert complete' "$cf_err" \
          || { echo "FAIL: carry-forward branch not reached — --incremental took the no-source-change early return"; fail=1; }
        cf_after="$(jq -s '[.[] | select(.record=="session")] | length' "$cf_store/usage.jsonl" 2>/dev/null)"
        [ "${cf_after:-0}" -eq "${cf_n:-0}" ] \
          || { echo "FAIL: incremental carry-forward LOST session records (${cf_n} -> ${cf_after:-0})"; fail=1; }
        cf_after="$(jq -s '[.[] | select(.record=="subagent")] | length' "$cf_store/usage.jsonl" 2>/dev/null)"
        [ "${cf_after:-0}" -eq "${cf_nsub:-0}" ] \
          || { echo "FAIL: incremental carry-forward LOST subagent records (${cf_nsub} -> ${cf_after:-0})"; fail=1; }
        cf_after="$(jq -s -S '[.[] | select(.record=="session" or .record=="subagent")
                               | {record, session_id, subagent_id, tokens, turns}]
                              | sort_by(.session_id, .record, (.subagent_id // ""))' "$cf_store/usage.jsonl" 2>/dev/null)"
        [ "$cf_after" = "$cf_base" ] \
          || { echo "FAIL: incremental carry-forward changed the record set (expected identical modulo extraction time)"; fail=1; }
      fi
    fi
  fi
  rm -rf "$cf_src" "$cf_store"

  # 10) DROP-SET fail-closed arms (#5240). Sub-test 9 proves the carry-forward SURVIVES a
  #     HEALTHY run; it cannot distinguish "guard present" from "guard absent", because
  #     both look identical when nothing fails. These are MUTATION arms: they induce the
  #     failure and assert the new behaviour is loud. The direction is why they are
  #     needed — an unread drop-set is an EMPTY drop-set, so the pre-fix code carried
  #     everything forward AND appended the re-extracted records, silently DUPLICATING
  #     sessions. A duplicate store still parses, still has a plausible length, and still
  #     passes every shape assertion above; only an induced failure can catch it.
  #
  #     Mechanism: shadow `jq` on PATH for the duration of ONE do_incremental call, in a
  #     SUBSHELL so neither PATH nor the fail-selector can leak into later assertions.
  #     The stub matches the ONE failing invocation by an exact argv element, so no other
  #     jq call inside do_incremental is affected — the arms are precise, not blanket.
  #     INVARIANT: every failure message below contains the literal "drop-set"; each arm
  #     greps its OWN guard's wording, so arm (a) cannot be satisfied by arm (b)'s guard.
  local ds_src ds_store ds_bin ds_realjq ds_pick ds_file ds_err ds_rc ds_n
  ds_realjq="$(command -v jq 2>/dev/null || true)"
  ds_src="$(mktemp -d "${TMPDIR:-/tmp}/finops-dssrc.XXXXXX")"
  ds_store="$(mktemp -d "${TMPDIR:-/tmp}/finops-dsstore.XXXXXX")"
  ds_bin="$(mktemp -d "${TMPDIR:-/tmp}/finops-dsbin.XXXXXX")"
  cp -R "$FIXTURES_DIR/." "$ds_src/" 2>/dev/null
  STORE="$ds_store" FINOPS_SOURCE_ROOT="$ds_src" do_rebuild "$ds_store" "$ds_src" 2>/dev/null
  cp -f "$ds_store/usage.jsonl" "$ds_store/usage.baseline.jsonl" 2>/dev/null
  ds_n="$(jq -s '[.[] | select(.record=="session")] | length' "$ds_store/usage.jsonl" 2>/dev/null)"
  # The stub is written with a QUOTED heredoc — nothing expands at author time; the real
  # jq path and the fail-selector arrive through the environment, so the stub text is
  # inert until it runs.
  cat > "$ds_bin/jq" <<'DSSTUBEOF'
#!/bin/bash
# finops-usage-extractor --self-test stub. Fails exactly ONE jq invocation, selected by
# FINOPS_SELFTEST_JQ_FAIL, and delegates every other call to the real jq unchanged.
_dsfail=0
# `dropset-slurp` matches the WHOLE argv, not a member: `-s` and `-c` each appear in
# extract_file's and write_store's invocations too, so a member match would over-fire
# and the arm would stop proving anything about the drop-set specifically.
if [ "${FINOPS_SELFTEST_JQ_FAIL:-}" = "dropset-slurp" ] && [ "$#" -eq 3 ] \
   && [ "$1" = "-s" ] && [ "$2" = "-c" ] && [ "$3" = "." ]; then
  _dsfail=1
fi
for _a in "$@"; do
  case "${FINOPS_SELFTEST_JQ_FAIL:-}" in
    dropset-ids)  [ "$_a" = 'select(.record=="session") | .session_id' ] && _dsfail=1 ;;
    dropset-json) [ "$_a" = "-R" ] && _dsfail=1 ;;
  esac
done
if [ "$_dsfail" -eq 1 ]; then
  printf 'finops-selftest-stub: induced failure for %s\n' "${FINOPS_SELFTEST_JQ_FAIL}" >&2
  exit 5
fi
exec "$FINOPS_SELFTEST_REAL_JQ" "$@"
DSSTUBEOF
  chmod +x "$ds_bin/jq"
  if [ -z "$ds_realjq" ] || [ "${ds_n:-0}" -lt 2 ]; then
    echo "FAIL: drop-set sub-test cannot run — needs a resolvable jq and >=2 fixture session records (jq='${ds_realjq}', sessions=${ds_n:-0})"; fail=1
  else
    # Same deterministic mtime staging as sub-test 9: all sources OLD, store MIDDLE,
    # exactly one source NEW, so the mtime gate fires and the drop-set code is reached
    # rather than the no-source-change early return.
    find "$ds_src" -type f -name '*.jsonl' -exec touch -t 202001010000 {} + 2>/dev/null
    touch -t 202006010000 "$ds_store/usage.jsonl" 2>/dev/null
    ds_pick="$(head -1 <<<"$( { jq -r 'select(.record=="session") | .session_id' "$ds_store/usage.jsonl" 2>/dev/null || true; } | sort)")"
    ds_file="$(find "$ds_src" -type f -name "${ds_pick:-__none__}.jsonl" -print -quit 2>/dev/null || true)"
    if [ -z "$ds_pick" ] || [ -z "$ds_file" ]; then
      echo "FAIL: drop-set sub-test cannot resolve a source file for session '${ds_pick:-}'"; fail=1
    else
      touch -t 202101010000 "$ds_file" 2>/dev/null
      ds_err="$ds_store/dropset.err"
      # (10a) MUTATION — the session_id read that builds "$ids".
      (
        export PATH="$ds_bin:$PATH"
        export FINOPS_SELFTEST_REAL_JQ="$ds_realjq"
        export FINOPS_SELFTEST_JQ_FAIL="dropset-ids"
        do_incremental "$ds_store" "$ds_src"
      ) 2>"$ds_err"; ds_rc=$?
      [ "$ds_rc" -eq 3 ] \
        || { echo "FAIL: drop-set id-read failure did not fail closed (expected exit 3, got $ds_rc)"; fail=1; }
      grep -q 'drop-set read failed over the re-extracted records' "$ds_err" \
        || { echo "FAIL: drop-set id-read guard did not report its own failure (message missing from stderr)"; fail=1; }
      diff -q "$ds_store/usage.jsonl" "$ds_store/usage.baseline.jsonl" >/dev/null 2>&1 \
        || { echo "FAIL: drop-set id-read failure rewrote the store; fail-closed must leave it UNCHANGED"; fail=1; }
      [ ! "$ds_store/usage.jsonl" -nt "$ds_file" ] \
        || { echo "FAIL: drop-set id-read failure touched the store (mtime advanced past the staged source)"; fail=1; }

      # (10b) MUTATION — the `jq -R` stage that assembles $drop_json. The store is still
      #       unstaged because (10a) returned before write_store, so no re-staging is
      #       needed.
      #       KEEP THE MESSAGE ASSERTION. Measured against the pre-fix code, the exit-code
      #       limb ALONE does not discriminate here: the shipped `|| echo '[]'` captures
      #       BOTH the surviving second stage's `[]` AND the fallback's `[]`, so
      #       $drop_json becomes two concatenated documents, --argjson rejects it, and the
      #       carry-forward guard returns 3 for a DIFFERENT reason. Exit 3 alone would
      #       therefore pass against the defect. The wording limb is what fails it.
      (
        export PATH="$ds_bin:$PATH"
        export FINOPS_SELFTEST_REAL_JQ="$ds_realjq"
        export FINOPS_SELFTEST_JQ_FAIL="dropset-json"
        do_incremental "$ds_store" "$ds_src"
      ) 2>"$ds_err"; ds_rc=$?
      [ "$ds_rc" -eq 3 ] \
        || { echo "FAIL: drop-set assembly failure did not fail closed (expected exit 3, got $ds_rc)"; fail=1; }
      grep -q 'drop-set could not be assembled' "$ds_err" \
        || { echo "FAIL: drop-set assembly guard did not report its own failure (message missing from stderr)"; fail=1; }
      diff -q "$ds_store/usage.jsonl" "$ds_store/usage.baseline.jsonl" >/dev/null 2>&1 \
        || { echo "FAIL: drop-set assembly failure rewrote the store; fail-closed must leave it UNCHANGED"; fail=1; }
      [ ! "$ds_store/usage.jsonl" -nt "$ds_file" ] \
        || { echo "FAIL: drop-set assembly failure touched the store (mtime advanced past the staged source)"; fail=1; }

      # (10b2) MUTATION — the SLURP stage of the same statement. This is the genuinely
      #        SILENT variant of the defect and the reason (10b) is not sufficient on its
      #        own: when only the second stage fails, the shipped fail-open produces a
      #        CLEAN `[]`, --argjson accepts it, carry-forward drops nothing, the append
      #        duplicates every re-extracted session, and the run exits 0. Nothing
      #        downstream catches it. Under the guard it is exit 3 and loud.
      (
        export PATH="$ds_bin:$PATH"
        export FINOPS_SELFTEST_REAL_JQ="$ds_realjq"
        export FINOPS_SELFTEST_JQ_FAIL="dropset-slurp"
        do_incremental "$ds_store" "$ds_src"
      ) 2>"$ds_err"; ds_rc=$?
      [ "$ds_rc" -eq 3 ] \
        || { echo "FAIL: drop-set slurp failure did not fail closed (expected exit 3, got $ds_rc) — this is the SILENT variant, exit 0 here means the store was duplicated"; fail=1; }
      grep -q 'drop-set could not be assembled' "$ds_err" \
        || { echo "FAIL: drop-set slurp guard did not report its own failure (message missing from stderr)"; fail=1; }
      diff -q "$ds_store/usage.jsonl" "$ds_store/usage.baseline.jsonl" >/dev/null 2>&1 \
        || { echo "FAIL: drop-set slurp failure rewrote the store; fail-closed must leave it UNCHANGED"; fail=1; }
      [ ! "$ds_store/usage.jsonl" -nt "$ds_file" ] \
        || { echo "FAIL: drop-set slurp failure touched the store (mtime advanced past the staged source)"; fail=1; }

      # (10c) CONTROL — identical harness, identical stub on PATH, NO fail selector. If
      #       this arm did not pass, (10a)/(10b)/(10b2) would prove nothing: the harness
      #       itself would be the cause. Runs LAST because it legitimately rewrites the
      #       store.
      #       Non-vacuity is asserted on MTIME, not on bytes. A byte-difference assertion
      #       is a flake: the incremental write preserves created_utc and re-derives
      #       last_extract_utc / extracted_utc from a SECOND-resolution clock, so when the
      #       whole block runs inside one second a successful run legitimately reproduces
      #       the rebuild byte-for-byte. Observed red on exactly that path while authoring
      #       this arm. `write_store` mv's a fresh temp file into place, so mtime advances
      #       unconditionally — the same wording-independent probe sub-test 9 uses.
      (
        export PATH="$ds_bin:$PATH"
        export FINOPS_SELFTEST_REAL_JQ="$ds_realjq"
        do_incremental "$ds_store" "$ds_src"
      ) 2>"$ds_err"; ds_rc=$?
      [ "$ds_rc" -eq 0 ] \
        || { echo "FAIL: drop-set control arm did not succeed (exit $ds_rc) — the harness, not the guard, is failing the mutation arms"; fail=1; }
      grep -q 'incremental upsert complete' "$ds_err" \
        || { echo "FAIL: drop-set control arm did not reach the carry-forward branch — the mutation arms tested the early return, not the guards"; fail=1; }
      [ "$ds_store/usage.jsonl" -nt "$ds_file" ] \
        || { echo "FAIL: drop-set control arm did not rewrite the store — the store-unchanged assertions above are vacuous"; fail=1; }
      # The defect this card closes, asserted directly: a healthy run must not duplicate.
      local ds_dups
      ds_dups="$(jq -r 'select(.record=="session") | .session_id' "$ds_store/usage.jsonl" 2>/dev/null | sort | uniq -d)"
      [ -z "$ds_dups" ] \
        || { echo "FAIL: drop-set control arm produced duplicate session_id(s): $ds_dups"; fail=1; }
    fi
  fi
  rm -rf "$ds_src" "$ds_store" "$ds_bin"

  # 11) COUNTING-UNIT BOUNDARY (schema v2.0.0). A store of another counting unit (another
  #     schema MAJOR) is never rebuilt over and never upserted into: --rebuild first keeps
  #     it, as a store, at prior/schema-<old>/usage.jsonl (a second crossing from the same
  #     version: the stamped prior/schema-<old>-<UTC stamp>/usage.jsonl, 11e), and
  #     --incremental falls back to --rebuild. A store of the current unit (same major — an additive minor)
  #     is neither kept nor falls back. Every store here is a throwaway mktemp dir built
  #     from the synthetic fixtures. INVARIANT: every failure message below contains the
  #     literal "counting-unit boundary".
  local cu_store cu_ref cu_bin cu_err cu_rc cu_n cu_fc cu_nm cu_other cu_two cu_stamped
  cu_store="$(mktemp -d "${TMPDIR:-/tmp}/finops-custore.XXXXXX")"
  cu_ref="$(mktemp -d "${TMPDIR:-/tmp}/finops-curef.XXXXXX")"
  cu_bin="$(mktemp -d "${TMPDIR:-/tmp}/finops-cubin.XXXXXX")"
  cu_fc="$(mktemp -d "${TMPDIR:-/tmp}/finops-custore.XXXXXX")"
  cu_nm="$(mktemp -d "${TMPDIR:-/tmp}/finops-custore.XXXXXX")"
  cu_other="$(mktemp -d "${TMPDIR:-/tmp}/finops-custore.XXXXXX")"
  cu_err="$cu_ref/boundary.err"

  # (11a) A 1.x store (counted per transcript line), crossed by --incremental.
  do_rebuild "$cu_store" "$src" 2>/dev/null
  jq -c 'if .record=="meta" then .schema_version="1.2.0" else . end' "$cu_store/usage.jsonl" > "$cu_ref/prior.jsonl" 2>/dev/null
  cp -f "$cu_ref/prior.jsonl" "$cu_store/usage.jsonl"
  do_incremental "$cu_store" "$src" 2>"$cu_err"; cu_rc=$?
  [ "$cu_rc" -eq 0 ] \
    || { echo "FAIL: counting-unit boundary — --incremental over a schema-1.2.0 store exited $cu_rc, want 0"; fail=1; }
  grep -q 'falling back to --rebuild' "$cu_err" \
    || { echo "FAIL: counting-unit boundary — --incremental over a schema-1.2.0 store did not fall back to --rebuild"; fail=1; }
  grep -q 'counted per transcript line' "$cu_err" \
    || { echo "FAIL: counting-unit boundary — the message did not describe a 1.x store as counted per transcript line"; fail=1; }
  [ "$(store_schema_version "$cu_store/usage.jsonl")" = "$SCHEMA_VERSION" ] \
    || { echo "FAIL: counting-unit boundary — the rebuilt store does not declare schema $SCHEMA_VERSION"; fail=1; }
  cmp -s "$cu_store/prior/schema-1.2.0/usage.jsonl" "$cu_ref/prior.jsonl" \
    || { echo "FAIL: counting-unit boundary — the schema-1.2.0 store was not kept byte-identical at prior/schema-1.2.0/usage.jsonl"; fail=1; }
  # Control: a second --rebuild meets the current unit and keeps nothing more.
  do_rebuild "$cu_store" "$src" 2>/dev/null
  cu_n="$(find "$cu_store/prior" -type f -name usage.jsonl 2>/dev/null | wc -l | tr -d ' ')"
  [ "${cu_n:-0}" -eq 1 ] \
    || { echo "FAIL: counting-unit boundary — a second --rebuild changed the preserved-store count (want 1, got ${cu_n:-0})"; fail=1; }

  # (11b) MUTATION — the fail-closed path. With ln and cp both failing on PATH (in a
  #       subshell, so nothing leaks), the boundary cannot keep the prior store: the run
  #       must exit 3, leave the store byte-identical, and leave no prior/ directory. A
  #       rebuild that went on regardless would overwrite the only copy of every session
  #       whose transcript is gone, which no success-path assertion above can catch.
  printf '#!/bin/sh\nexit 1\n' > "$cu_bin/ln"
  printf '#!/bin/sh\nexit 1\n' > "$cu_bin/cp"
  chmod +x "$cu_bin/ln" "$cu_bin/cp"
  cp -f "$cu_ref/prior.jsonl" "$cu_fc/usage.jsonl"
  (
    export PATH="$cu_bin:$PATH"
    do_incremental "$cu_fc" "$src"
  ) 2>"$cu_err"; cu_rc=$?
  [ "$cu_rc" -eq 3 ] \
    || { echo "FAIL: counting-unit boundary — a preservation failure did not fail closed (exit $cu_rc, want 3)"; fail=1; }
  grep -q 'could not preserve' "$cu_err" \
    || { echo "FAIL: counting-unit boundary — the preservation guard did not report its own failure (message missing from stderr)"; fail=1; }
  cmp -s "$cu_fc/usage.jsonl" "$cu_ref/prior.jsonl" \
    || { echo "FAIL: counting-unit boundary — a preservation failure rewrote the store; fail-closed must leave it UNCHANGED"; fail=1; }
  [ ! -e "$cu_fc/prior" ] \
    || { echo "FAIL: counting-unit boundary — a preservation failure left a prior/ directory behind"; fail=1; }

  # (11c) NEAR-MISS — the same counting unit. An additive-minor store (2.0.1-selftest)
  #       keeps the unit, so --incremental must not fall back and --rebuild must keep
  #       nothing; keyed on the full version string, every future additive bump would
  #       split the store's history. The stamp is read back first, so the arm cannot
  #       pass on a store that never carried the near-miss version.
  do_rebuild "$cu_nm" "$src" 2>/dev/null
  jq -c 'if .record=="meta" then .schema_version="2.0.1-selftest" else . end' "$cu_nm/usage.jsonl" > "$cu_ref/minor.jsonl" 2>/dev/null
  cp -f "$cu_ref/minor.jsonl" "$cu_nm/usage.jsonl"
  [ "$(store_schema_version "$cu_nm/usage.jsonl")" = "2.0.1-selftest" ] \
    || { echo "FAIL: counting-unit boundary — near-miss arm is vacuous: the store does not declare 2.0.1-selftest"; fail=1; }
  do_incremental "$cu_nm" "$src" 2>"$cu_err"; cu_rc=$?
  [ "$cu_rc" -eq 0 ] \
    || { echo "FAIL: counting-unit boundary — --incremental over a same-unit (2.0.1-selftest) store exited $cu_rc, want 0"; fail=1; }
  if grep -q 'falling back to --rebuild' "$cu_err"; then
    echo "FAIL: counting-unit boundary — --incremental fell back to --rebuild over a store of the same counting unit (2.0.1-selftest)"; fail=1
  fi
  cp -f "$cu_ref/minor.jsonl" "$cu_nm/usage.jsonl"
  do_rebuild "$cu_nm" "$src" 2>/dev/null
  [ ! -e "$cu_nm/prior" ] \
    || { echo "FAIL: counting-unit boundary — a same-unit (2.0.1-selftest) store was kept under prior/, which splits its history at an additive bump"; fail=1; }

  # (11d) A store of another unit that is NOT 1.x is kept too, and its message does not
  #       call it per-line: only a 1.x store counted per transcript line (11a is the
  #       positive control for that wording).
  do_rebuild "$cu_other" "$src" 2>/dev/null
  jq -c 'if .record=="meta" then .schema_version="3.0.0-selftest" else . end' "$cu_other/usage.jsonl" > "$cu_ref/other.jsonl" 2>/dev/null
  cp -f "$cu_ref/other.jsonl" "$cu_other/usage.jsonl"
  do_rebuild "$cu_other" "$src" 2>"$cu_err"
  cmp -s "$cu_other/prior/schema-3.0.0-selftest/usage.jsonl" "$cu_ref/other.jsonl" \
    || { echo "FAIL: counting-unit boundary — a schema-3.0.0-selftest store was not kept at prior/schema-3.0.0-selftest/usage.jsonl"; fail=1; }
  if grep -q 'per transcript line' "$cu_err"; then
    echo "FAIL: counting-unit boundary — a store that is not 1.x was described as counted per transcript line"; fail=1
  fi

  # (11e) A SECOND crossing from the same version. While prior/schema-1.2.0/ holds the
  #       store an earlier crossing kept, the next crossing keeps its store at the stamped
  #       prior/schema-1.2.0-<UTC stamp>/usage.jsonl and never overwrites the first. The two
  #       pre-crossing stores differ in content, so cmp can tell a kept copy from an
  #       overwritten one. Controls: after the first crossing the count instrument reads 1
  #       and the stamped glob 0; the unstamped directory name fails the stamped form. The
  #       store sits inside cu_ref, so cu_ref's own cleanup below removes it.
  cu_two="$cu_ref/two"
  mkdir -p "$cu_two"
  do_rebuild "$cu_two" "$src" 2>/dev/null
  jq -c 'if .record=="meta" then .schema_version="1.2.0" else . end' "$cu_two/usage.jsonl" > "$cu_ref/first.jsonl" 2>/dev/null
  jq -c 'if .record=="meta" then .schema_version="1.2.0" | .selftest_crossing=2 else . end' "$cu_two/usage.jsonl" > "$cu_ref/second.jsonl" 2>/dev/null
  if cmp -s "$cu_ref/first.jsonl" "$cu_ref/second.jsonl"; then
    echo "FAIL: counting-unit boundary — second-crossing arm is vacuous: its two schema-1.2.0 stores are identical"; fail=1
  fi
  cp -f "$cu_ref/first.jsonl" "$cu_two/usage.jsonl"
  do_rebuild "$cu_two" "$src" 2>/dev/null
  cu_n="$(find "$cu_two/prior" -type f -name usage.jsonl 2>/dev/null | wc -l | tr -d ' ')"
  cu_stamped="$(find "$cu_two/prior" -type f -path '*/prior/schema-1.2.0-*/usage.jsonl' 2>/dev/null)"
  [ "${cu_n:-0}" -eq 1 ] && [ -z "$cu_stamped" ] \
    || { echo "FAIL: counting-unit boundary — the first crossing did not keep exactly one unstamped store (count ${cu_n:-0}, stamped '${cu_stamped}')"; fail=1; }
  if printf '%s\n' "schema-1.2.0" | grep -Eq '^schema-1[.]2[.]0-[0-9]{8}T[0-9]{6}Z$'; then
    echo "FAIL: counting-unit boundary — the stamped-name check matches the unstamped name, so it tests nothing"; fail=1
  fi
  cp -f "$cu_ref/second.jsonl" "$cu_two/usage.jsonl"
  do_rebuild "$cu_two" "$src" 2>"$cu_err"; cu_rc=$?
  [ "$cu_rc" -eq 0 ] \
    || { echo "FAIL: counting-unit boundary — a second crossing from schema 1.2.0 exited $cu_rc, want 0"; fail=1; }
  cmp -s "$cu_two/prior/schema-1.2.0/usage.jsonl" "$cu_ref/first.jsonl" \
    || { echo "FAIL: counting-unit boundary — a second crossing changed the store the first one kept at prior/schema-1.2.0/usage.jsonl"; fail=1; }
  cu_stamped="$(find "$cu_two/prior" -type f -path '*/prior/schema-1.2.0-*/usage.jsonl' 2>/dev/null)"
  cu_n="$(find "$cu_two/prior" -type f -name usage.jsonl 2>/dev/null | wc -l | tr -d ' ')"
  if [ "${cu_n:-0}" -ne 2 ] || [ "$(printf '%s\n' "$cu_stamped" | grep -c .)" -ne 1 ]; then
    echo "FAIL: counting-unit boundary — a second crossing did not keep exactly one stamped store beside the first (count ${cu_n:-0})"; fail=1
  elif ! basename "$(dirname "$cu_stamped")" | grep -Eq '^schema-1[.]2[.]0-[0-9]{8}T[0-9]{6}Z$'; then
    echo "FAIL: counting-unit boundary — the second crossing's store is not at prior/schema-1.2.0-<UTC stamp>/usage.jsonl"; fail=1
  elif ! cmp -s "$cu_stamped" "$cu_ref/second.jsonl"; then
    echo "FAIL: counting-unit boundary — the stamped store is not byte-identical to the store the second crossing replaced"; fail=1
  fi
  rm -rf "$cu_store" "$cu_ref" "$cu_bin" "$cu_fc" "$cu_nm" "$cu_other"

  rm -rf "$st_store"
  if [ "$fail" -eq 0 ]; then
    echo "finops-usage-extractor --self-test: PASS"
    return 0
  fi
  echo "finops-usage-extractor --self-test: FAIL"
  return 1
}

# ── Main ──
MODE="rebuild"
DO_SELFTEST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --rebuild)     MODE="rebuild" ;;
    --incremental) MODE="incremental" ;;
    --self-test)   DO_SELFTEST=1 ;;
    -h|--help)
      # The header block — every comment line up to the first non-comment line — whatever
      # its length; a fixed line count cut it off mid-sentence once the header grew.
      awk 'NR == 1 { next } /^# |^#$/ { sub(/^# ?/, ""); print; next } { exit }' "$0"
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
SOURCE_ROOT="${FINOPS_SOURCE_ROOT:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects}"

guard_store_git_ignored "$STORE_DIR"

if [ ! -d "$SOURCE_ROOT" ] || [ ! -r "$SOURCE_ROOT" ]; then
  printf 'FATAL (exit 3): session-data source root unreadable: %s\n' "$SOURCE_ROOT" >&2
  exit 3
fi

case "$MODE" in
  rebuild)     do_rebuild     "$STORE_DIR" "$SOURCE_ROOT" ;;
  incremental) do_incremental "$STORE_DIR" "$SOURCE_ROOT" ;;
esac
# An unconditional `exit 0` here would swallow the mode function's return code, which
# is exactly how the incremental carry-forward failure stayed silent: the fail-closed
# guard above returns 3, and without this propagation the caller still sees 0. The
# mode functions must `return` (never `exit`) for this to work — self_test() calls
# do_incremental directly, and an `exit` there would bypass its FAIL reporting.
MODE_RC=$?
exit "$MODE_RC"
