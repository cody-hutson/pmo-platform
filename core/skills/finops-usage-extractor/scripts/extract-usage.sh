#!/bin/bash
# finops-usage-extractor — local-session usage parser (slice C1, #3909).
#
# Extracts per-session and per-in-transcript-subagent token spend from local Claude
# Code session transcripts into the operator-local, git-ignored FinOps usage store
# defined by core/schemas/finops-usage-store-schema.md (schema v1.2.0). Exact
# message.usage counts are PRIMARY; the context-budget-auditor (#16) word->token
# heuristic is the FALLBACK for usage-less records only. Read-only on the source
# transcripts; writes only the resolved store (atomic tmp -> mv).
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
# Exit codes: 0 ok · 2 usage error · 3 source unreadable, or incremental carry-forward
#             read failure (store left unchanged) · 4 store-not-git-ignored
#             (fail-closed public-repo exfil guard) · 5 missing dependency (jq/git).

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
#    and proceeds. Keys on the store's CONTAINING repo, not the script's repo.
guard_store_git_ignored() {
  local store_dir="$1"
  local store_file="$store_dir/usage.jsonl"
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
| toksum($asst) as $st
# ── v1.2.0 analysis dimensions — session-grain sub-aggregates over the SAME $asst set
#    the session total is computed from, so every map partitions session.tokens exactly.
| dim_agg($asst; skill_of(.))         as $by_skill
| dim_agg($asst; mcp_of(.))           as $by_mcp
| dim_agg($asst; .message.model)      as $by_model
| ( leaf_total(tokens_obj($st)) )     as $sess_total
# tool_calls counts CLIENT-SIDE invocations by name from the turn content — distinct
# from `tool_use`, which counts SERVER-SIDE requests from message.usage.server_tool_use.
| count_agg([ $asst[] | .message.content[]? | select(.type == "tool_use") | .name // empty ]; {})
    as $tool_calls
| count_agg([ $asst[] | stop_of(.) | dim_key ]; { "unknown": 0 }) as $stop_reason
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
      heuristic_turns: $st.ht, extracted_utc: $now } ),
  # subagent drill-down records (NOT summed on top of session.tokens)
  ( $groups[]
    | { root: .[0].root, recs: [ .[].rec ] } as $g
    | toksum($g.recs) as $gt
    | [ $g.recs[] | .timestamp // empty ] as $gts
    | { record: "subagent", session_id: $sid, subagent_id: $g.root,
        parent_uuid: ($pmap[$g.root] // null), git_branch: $branch,
        service_tier: ( ([ $g.recs[] | .message.usage.service_tier? // empty ] | last) // $tier ),
        started_utc: ( if ($gts|length)>0 then ($gts|first) else null end ),
        ended_utc:   ( if ($gts|length)>0 then ($gts|last)  else null end ),
        model: ( [ $g.recs[] | .message.model // empty ] | last ),
        turns: $gt.turns, tokens: tokens_obj($gt), tool_use: tooluse_obj($gt),
        token_source: tsrc($gt), heuristic_turns: $gt.ht, extracted_utc: $now } )
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
  jq -cn --arg sv "1.2.0" --arg gen "finops-usage-extractor" --arg genver "$(generator_version)" \
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

do_rebuild() {
  local store_dir="$1" src_root="$2"
  local now body
  now="$(NOW_UTC)"
  mkdir -p "$store_dir"
  body="$(mktemp "${TMPDIR:-/tmp}/finops-body.XXXXXX")"
  build_body "$src_root" "$now" "$body"
  write_store "$store_dir" "$src_root" "$now" "$now" "$body"
  rm -f "$body"
  printf 'finops-usage-extractor: rebuilt %s (%s session record(s))\n' \
    "$store_dir/usage.jsonl" "$(jq -r 'select(.record=="session")' "$store_dir/usage.jsonl" 2>/dev/null | jq -s 'length' 2>/dev/null || echo '?')" >&2
}

do_incremental() {
  local store_dir="$1" src_root="$2"
  local store_file="$store_dir/usage.jsonl"
  [ -f "$store_file" ] || { do_rebuild "$store_dir" "$src_root"; return; }
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
  jq -r 'select(.record=="session") | .session_id' "$body" 2>/dev/null | sort -u > "$ids"
  # Carry forward existing records whose session_id is NOT in the changed set.
  local drop_json
  drop_json="$(jq -R . "$ids" 2>/dev/null | jq -s -c '.' 2>/dev/null || echo '[]')"
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

  # 8b) Subagent drill-down record emitted for the sidechain fixture (root grouping).
  local nsub subin
  nsub="$(jq -s '[.[] | select(.record=="subagent")] | length' "$st_store/usage.jsonl" 2>/dev/null)"
  [ "${nsub:-0}" -eq 1 ] || { echo "FAIL: expected exactly 1 subagent record, got ${nsub:-0}"; fail=1; }
  subin="$(jq -s '[.[] | select(.record=="subagent") | .tokens.input] | add // 0' "$st_store/usage.jsonl" 2>/dev/null)"
  [ "${subin:-0}" -eq 28 ] || { echo "FAIL: subagent input tokens != 28 (got ${subin:-0})"; fail=1; }

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
      grep -E '^#( |$)' "$0" | sed -E 's/^# ?//' | head -40
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
