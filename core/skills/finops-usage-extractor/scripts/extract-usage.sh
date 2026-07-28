#!/bin/bash
# finops-usage-extractor — local-session usage parser (slice C1, #3909).
#
# Extracts per-session and per-in-transcript-subagent token spend from local Claude
# Code session transcripts into the operator-local, git-ignored FinOps usage store
# defined by core/schemas/finops-usage-store-schema.md (frozen v1.0.0). Exact
# message.usage counts are PRIMARY; the context-budget-auditor (#16) word->token
# heuristic is the FALLBACK for usage-less records only. Read-only on the source
# transcripts; writes only the resolved store (atomic tmp -> mv).
#
# Store path resolution (no hardcoded operator path):
#   env STORE > env FINOPS_STORE_PATH > operator.toml [paths].operator_instance_finops_store_path
#   > default ${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/finops
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
# Exit codes: 0 ok · 2 usage error · 3 source unreadable · 4 store-not-git-ignored
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
  store="${store:-${workspace_root}/personal/pmo-instance/finops}"
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

. as $all
| [ $all[] | select(.type=="assistant") ] as $asst
| [ $all[] | .timestamp // empty ] as $ts
# session_id = the filename stem (a unique UUID, one record per file). NOT the internal
# .sessionId, which real session resumption/forking can duplicate across files — that
# cross-file linkage is C2's attribution scope, not a C1 key.
| $sid_fallback as $sid
| ( [ $all[] | .cwd // empty ] | last ) as $cwd
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
# Only spend-bearing sessions (>=1 assistant record) yield a record. Files with zero
# assistant turns (project summary/index files, empty transcripts) carry no token spend
# and are skipped — this also excludes non-session `.jsonl` files under the projects root.
| if ($asst | length) == 0 then empty
  else
  (
  # session record (tokens is the WHOLE-FILE total, inclusive of sidechains)
  ( { record: "session", session_id: $sid, project_dir: $project_dir,
      cwd: $cwd, git_branch: $branch, started_utc: $start, ended_utc: $end,
      model: $model, service_tier: $tier, turns: $st.turns,
      tokens: tokens_obj($st), tool_use: tooluse_obj($st),
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
  jq -cn --arg sv "1.0.0" --arg gen "finops-usage-extractor" --arg genver "$(generator_version)" \
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
  jq -c --argjson drop "$drop_json" \
     'select(.record=="session" or .record=="subagent")
      | select( ($drop | index(.session_id)) | not )' \
     "$store_file" 2>/dev/null > "$merged" || true
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
                    | {session_id, tokens, tool_use, token_source, heuristic_turns, subagent_count}]
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

  # 8) Incremental idempotence: no source change -> session digest unchanged, no dup.
  local d1 d2
  d1="$(jq -s -S '[.[] | select(.record=="session") | {session_id, tokens}] | sort_by(.session_id)' "$st_store/usage.jsonl" 2>/dev/null)"
  STORE="$st_store" FINOPS_SOURCE_ROOT="$src" do_incremental "$st_store" "$src"
  d2="$(jq -s -S '[.[] | select(.record=="session") | {session_id, tokens}] | sort_by(.session_id)' "$st_store/usage.jsonl" 2>/dev/null)"
  [ "$d1" = "$d2" ] || { echo "FAIL: incremental (no change) altered the session digest"; fail=1; }

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
exit 0
