#!/bin/bash
# finops-usage-extractor — roll-up + attribution module (slice C2).
#
# Reads the operator-local FinOps usage store produced by extract-usage.sh (slice
# C1) and writes the additive v1.2.0 `rollup` + `coverage` records:
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
#   > default ${CLAUDE_WORKSPACE_ROOT}/pmo-instance/finops
# Hub-state (Surface C) resolution:
#   env FINOPS_HUB_STATE_DIR > operator.toml [paths].operator_instance_hub_state_path
#   > default ${CLAUDE_WORKSPACE_ROOT}/pmo-instance/hub-state
# Pipeline event-log (Surface B) resolution:
#   env FINOPS_PIPELINE_EVENT_LOG
#   > operator.toml [paths].operator_instance_evals_results_path + /pipeline-event-log.md
#   > default ${CLAUDE_WORKSPACE_ROOT}/pmo-instance/evals/results/pipeline-event-log.md
#
# Usage:
#   bash rollup-attribution.sh [--emit] [--resolve-prs] [--self-test]
#     --emit         (DEFAULT) resolve + roll up the store in place: strip any prior
#                    rollup/coverage records, append fresh ones, bump meta schema_version
#                    to 1.2.0. Idempotent over an unchanged store (byte-identical body
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
  [ -r "$SKILL_MD" ] && v="$( { grep -m1 -E '^version:' "$SKILL_MD" 2>/dev/null || true; } | awk '{print $2}')"
  printf '%s' "${v:-unknown}"
}

# ── operator.toml single-key reader (tolerates an absent key). ──
toml_val() {
  local key="$1" toml="${HOME}/.config/pmo-platform/operator.toml"
  [ -r "$toml" ] || return 0
  { grep -m1 -E "^${key}" "$toml" 2>/dev/null || true; } | awk -F= '{gsub(/[" ]/,"",$2); print $2}'
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
  store="${store:-$(workspace_root)/pmo-instance/finops}"
  printf '%s' "$store"
}

# ── Hub-state (Surface C) dir resolution. ──
resolve_hub_state_dir() {
  local d="${FINOPS_HUB_STATE_DIR:-}"
  [ -z "$d" ] && d="$(toml_val operator_instance_hub_state_path)"
  d="${d:-$(workspace_root)/pmo-instance/hub-state}"
  printf '%s' "$d"
}

# ── Pipeline event-log (Surface B) path resolution. ──
resolve_event_log() {
  local f="${FINOPS_PIPELINE_EVENT_LOG:-}"
  if [ -z "$f" ]; then
    local er; er="$(toml_val operator_instance_evals_results_path)"
    er="${er:-$(workspace_root)/pmo-instance/evals/results}"
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

# ── Surface C → {worktree: "<run-key>"} map. Scans <hub-state>/<run-key>/sessions.md
#    tables; the milestone is the parent dir name. Run keys are SLUG-primary (ADR-092;
#    hub-session-continuity.md § 2) with legacy vX.Y dirs read-only
#    (orchestration-playbook.md § 4a.3). The worktree COLUMN INDEX is bound per file from
#    that file's declared header — it is NOT fixed at column 4. ──
build_worktree_milestone_map() {
  local hub_dir="$1"
  [ -d "$hub_dir" ] || { printf '{}'; return 0; }
  local f ver pairs
  # A NAME-shaped run-key guard silently drops whichever key form it was not written for,
  # so there is none here — only the degenerate basenames are refused. The population is
  # constrained by TABLE SHAPE instead: bind the `worktree` COLUMN INDEX and the field
  # count from the row that declares both `session_id` and `worktree`, and ingest only
  # later rows of the same width. A hardcoded $5 reads narrative out of a `sessions.md`
  # whose table is a different shape, and a `$0 !~ /session_id/` header-skip cannot skip a
  # header that does not contain `session_id`.
  #
  # THE BIND IS STICKY PER FILE. The deployed hub-state file interleaves
  # `# === END MANAGED SECTION ===` / `# === BEGIN OPERATOR ADDITIONS ...` between the
  # separator row and the first data row (update.sh composes those fences at install; the
  # in-repo .template carries none). A parser that unbinds on a blank or non-pipe line
  # drops every row after the fence. Do not add such a reset — the failure is SILENT, and
  # the `sticky-header-bind` self-test arm exists to keep it that way only if it is kept.
  pairs="$(
    while IFS= read -r f; do
      ver="$(basename "$(dirname "$f")")"
      # The leading `(` is REQUIRED: this `case` lives inside a `$( … )` command
      # substitution, where an unbalanced pattern-closing `)` ends the substitution early
      # and the remainder is reparsed as shell. The balanced form is portable POSIX.
      case "$ver" in (""|.|..) continue ;; esac
      awk -F'|' -v ver="$ver" '
        function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
        /^[[:space:]]*\|/ {
          if (idx == 0) {
            hs = 0; hw = 0
            for (i = 2; i <= NF; i++) {
              c = trim($i)
              if (c == "session_id") hs = 1
              if (c == "worktree")   hw = i
            }
            if (hs && hw) { idx = hw; nf = NF }
            next
          }
          if ($0 ~ /^[[:space:]]*\|[-|[:space:]:]+\|[[:space:]]*$/) next
          if (NF != nf) next
          wt = trim($idx)
          if (wt != "") printf "%s\t%s\n", wt, ver
        }' "$f"
    done < <(find "$hub_dir" -type f -name 'sessions.md' 2>/dev/null | LC_ALL=C sort)
  )"
  # `LC_ALL=C sort` on the find output is REQUIRED, not cosmetic: the jq reduction below is
  # last-wins and the record it feeds asserts `reproducible: true`, so an unsorted,
  # filesystem-dependent traversal order would make a collision's outcome irreproducible.
  # Sorting makes it deterministic; the warning below makes it VISIBLE (the convention's
  # stated posture is fail-visible, never a silent drop). Identical (worktree, run-key)
  # pairs are deduped first, so only a key spanning two DIFFERENT milestones warns.
  printf '%s\n' "$pairs" | LC_ALL=C sort -u | awk -F'\t' '
    NF == 2 { n[$1]++; m[$1] = (n[$1] == 1 ? $2 : m[$1] ", " $2) }
    END { for (k in n) if (n[k] > 1)
            printf "WARNING: hub-state worktree key \047%s\047 maps to %d milestones (%s); last-wins applied\n", \
              k, n[k], m[k] > "/dev/stderr" }'
  printf '%s\n' "$pairs" \
    | jq -R -s 'split("\n") | map(select(length>0) | split("\t")) | map({(.[0]): .[1]}) | add // {}'
}

# ── Surface B → [{worktree, issue, ts}] list. Scans the pipeline-event-log table for
#    decision/gate-outcome/escalation rows whose payload carries session:<composite>
#    and whose subject/actor names an issue #N. The composite's worktree component is
#    everything before the first '__'. ──
build_issue_event_list() {
  local log="$1"
  [ -r "$log" ] || { printf '[]'; return 0; }
  # FS is the SHARED column delimiter " \| " (space-pipe-space) — the same one every
  # other event-log consumer uses. A bare -F'\|' truncates any payload carrying the
  # escaped multi-value separator '\|' admitted by schema § 4.3a, silently dropping
  # the session: join token and losing issue-grain attribution for that row.
  # Under this FS the row's outer pipes ride $1 (leading) and $NF (trailing).
  awk -F ' \\| ' '
    /^[[:space:]]*\|/ && $0 !~ /ts_iso/ && $0 !~ /-{3,}/ {
      ts=$1;      sub(/^[[:space:]]*\|[[:space:]]*/,"",ts);
                  gsub(/^[[:space:]]+|[[:space:]]+$/,"",ts);
      etype=$4;   gsub(/^[[:space:]]+|[[:space:]]+$/,"",etype);
      actor=$6;   gsub(/^[[:space:]]+|[[:space:]]+$/,"",actor);
      subject=$7; gsub(/^[[:space:]]+|[[:space:]]+$/,"",subject);
      payload=$10;sub(/[[:space:]]*\|[[:space:]]*$/,"",payload);
                  gsub(/^[[:space:]]+|[[:space:]]+$/,"",payload);
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

# ── FM-2 count-once overlap map (hub<->spoke file boundary). Returns a JSON object keyed by
#    HUB session_id → the summed tokens (+ collision `count`) of every in-transcript
#    `subagent` (sidechain) record whose identity (subagent_id) matches a standalone
#    `session` record's session_id. Such a record means the same spoke spend is embedded
#    BOTH inside the hub session's whole-file total AND as its own standalone session; the
#    standalone session is authoritative, so the roll-up deducts the overlapping sidechain
#    copy from the hub's contribution (counted once, not twice). On the current separate-file
#    hub-spoke model a subagent_id is a sidechain-root uuid within the hub file, never a
#    standalone file stem, so the map is empty ({}) by construction — the guard is inert but
#    present so a future harness change that double-emits a spoke is caught, not silent (a
#    non-empty map surfaces as coverage.count_once_overlap). ──
build_count_once_overlap_map() {
  local store_file="$1"
  [ -r "$store_file" ] || { printf '{}'; return 0; }
  jq -s '
    [ .[] | select(.record=="session") | .session_id ] as $sids
    | [ .[] | select(.record=="subagent") | . as $sub
        | select(any($sids[]; . == $sub.subagent_id)) ]
    | group_by(.session_id)
    | map({ key: .[0].session_id,
            value: { input:   (map(.tokens.input // 0) | add),
                     output:  (map(.tokens.output // 0) | add),
                     cc_total:(map(.tokens.cache_creation.total // 0) | add),
                     cc_1h:   (map(.tokens.cache_creation.ephemeral_1h // 0) | add),
                     cc_5m:   (map(.tokens.cache_creation.ephemeral_5m // 0) | add),
                     cread:   (map(.tokens.cache_read // 0) | add),
                     ws:      (map(.tool_use.web_search_requests // 0) | add),
                     wf:      (map(.tool_use.web_fetch_requests // 0) | add),
                     count:   length } })
    | from_entries' "$store_file" 2>/dev/null || printf '{}'
}

# ── The resolver + roll-up jq program. Input: slurped session records. Args: the two
#    hub-state maps ($wt_milestone, $issue_events) + the FM-2 count-once overlap map
#    ($overlap_by_session). Output: one resolution object per session (tokens net of the
#    count-once deduction). ──
read -r -d '' JQ_RESOLVE <<'JQEOF' || true
def tok(t): (t.input // 0) + (t.output // 0) + ((t.cache_creation.total) // 0) + (t.cache_read // 0);
# NOTE (schema v1.2.0): the former `def base($p)` basename adapter is GONE. The store now
# persists `session.worktree` (the basename) directly — basename derivation moved to the
# PRODUCER (extract-usage.sh) as the data-minimization control. The T1/T3 join key is now
# literally identical on both sides, which is what base() was approximating all along.
def parse_milestone($b):
  # test-guard the capture: a bare `capture` on a non-matching string yields EMPTY,
  # and binding `... as $v` to an empty stream would silently drop the whole session.
  ($b // "") as $s
  | if ($s | test("^(?:release|chore)/v[0-9]+\\.[0-9]+"))
    then ($s | capture("^(?:release|chore)/(?<v>v[0-9]+\\.[0-9]+)") | .v)
    else null end ;
def parse_milestone_slug($b):
  # Slug-primary release branches (ADR-092): `release/<milestone-slug>`, no version stem
  # (core/rules/git-workflow.md § Branch naming). TWO deliberate properties:
  #  1. The capture is a single PATH SEGMENT ([^/]+) — a STRUCTURAL constraint, not a
  #     character grammar. The platform declares no milestone-slug grammar (the only two
  #     slug-shaped rules in the corpus govern .md basenames and skill frontmatter names),
  #     and authoring one here would be the same defect that eliminated the explicit-grammar
  #     candidate at design. This axis uses the directory axis's posture: structure, not
  #     name shape.
  #  2. The legacy version form is excluded by DERIVATION from parse_milestone, not by a
  #     second inline copy of the version regex. ONE version predicate in this file.
  # `chore/` is deliberately excluded: `chore/<slug>-stage-13-close` carries a suffix with
  # no delimiter separating it from the slug, so a chore-slug parse would manufacture a
  # wrong key. Such a branch stays `unattributed` — a named, accepted residual.
  # Test-guarded because a bare capture on a non-match yields EMPTY and would silently
  # drop the whole session.
  ($b // "") as $s
  | if (parse_milestone($s) == null) and ($s | test("^release/[^/]+$"))
    then ($s | capture("^release/(?<v>[^/]+)$") | .v)
    else null end ;
def is_fixfeat($b): ($b // "") | test("^(?:fix|feat)/") ;

# T1: an issue-event whose worktree == session.worktree and ts within the session window.
def t1_issue($wt; $start; $end):
  ( [ $issue_events[]
      | select(.worktree == $wt)
      | select( ($start == null) or ($end == null) or (.ts >= $start and .ts <= $end) )
      | .issue ] | first ) ;

.[]
| . as $s
| ($s.tokens // {}) as $tk
| ($s.git_branch) as $branch
| ($s.worktree) as $wt
| ($s.started_utc) as $start
| ($s.ended_utc) as $end
# FM-2 count-once (hub<->spoke file boundary). $overlap_by_session maps a HUB session_id
# to the summed tokens of any in-transcript sidechain `subagent` record whose identity
# (subagent_id) collides with a standalone `session` record — i.e. the same spoke spend
# embedded BOTH inside this hub session's whole-file total AND as its own standalone
# session. On a collision the standalone session is authoritative, so the overlapping
# sidechain copy is excluded from THIS session's roll-up contribution (counted once, not
# twice). Empty ({}) on the current separate-file hub-spoke model (no such collision
# arises) — the deduction is then a no-op, but the guard is always applied.
| ($overlap_by_session[$s.session_id] // {input:0,output:0,cc_total:0,cc_1h:0,cc_5m:0,cread:0,ws:0,wf:0,count:0}) as $ov
# Bind all tier candidates at top level (in scope in every branch below — avoids
# relying on condition-bound variables, which jq does not carry into `then`).
| (t1_issue($wt; $start; $end)) as $t1
| (parse_milestone($branch)) as $t2v
| (parse_milestone_slug($branch)) as $t2sv
# Null-guard the T3 object index: `{...}[null]` is a jq HARD error ("Cannot index object
# with null"), and do_emit runs this program with 2>/dev/null and an untested exit status,
# so an abort here would silently yield an EMPTY roll-up that the coverage record then
# certifies as health=OK / 100% attributed. A session whose source carried no cwd has a
# null worktree; it must fall through to `unattributed`, not abort the whole run.
| (if $wt == null then null else $wt_milestone[$wt] end) as $t3v
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
    # $t2sv sits BELOW $t3v deliberately: a branch name is a heuristic for the milestone,
    # while the hub-state directory holds the value the hub AUTHORED. Lifting this arm
    # above $t3v would let `release/<slug>-suffix` override the exact `<slug>`, splitting
    # one release into two rollup rows. The `shadowing-guard` self-test arm turns red on
    # such a reorder. NOTE the ladder is only PARTLY precision-ordered: the pre-existing
    # $t2v arm is itself a branch-name parse sitting above the authored $t3v. That breach
    # is pre-existing and deliberately NOT reordered here — a reorder would move the
    # attribution of every session currently resolving through $t2v.
    elif $t2sv != null then
      { work_item: ("milestone:" + $t2sv), work_item_kind: "milestone",
        attribution_tier: "branch-milestone", reproducible: true,
        attribution_basis: ("slug-primary release branch " + $branch + " -> milestone " + $t2sv) }
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
    # tokens net of the count-once deduction ($ov, zero unless a collision was detected).
    tokens: { input: (($tk.input // 0) - $ov.input), output: (($tk.output // 0) - $ov.output),
              cache_creation: { total: ((($tk.cache_creation.total) // 0) - $ov.cc_total),
                                ephemeral_1h: ((($tk.cache_creation.ephemeral_1h) // 0) - $ov.cc_1h),
                                ephemeral_5m: ((($tk.cache_creation.ephemeral_5m) // 0) - $ov.cc_5m) },
              cache_read: (($tk.cache_read // 0) - $ov.cread) },
    tool_use: { web_search_requests: ((($s.tool_use.web_search_requests) // 0) - $ov.ws),
                web_fetch_requests: ((($s.tool_use.web_fetch_requests) // 0) - $ov.wf) },
    token_source: ($s.token_source // "exact"),
    overlap_excluded: $ov.count,
    total: (tok($tk) - ($ov.input + $ov.output + $ov.cc_total + $ov.cread)) }
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
# FM-2 count-once: total # of colliding sidechain subagents excluded across all sessions.
# 0 on the current separate-file model; a non-zero value is fail-visible for operator review.
| ( [ $all[] | .overlap_excluded // 0 ] | add // 0 ) as $count_once_overlap
| { record: "coverage",
    attributed_token_fraction: rnd($attr_frac),
    unattributed_token_fraction: rnd($unattr_frac),
    milestone_grain_token_fraction: ( if $grand>0 then rnd($ms/$grand) else 0 end ),
    issue_grain_token_fraction: ( if $grand>0 then rnd($iss/$grand) else 0 end ),
    multi_branch_token_fraction: ( if $grand>0 then rnd($mb/$grand) else 0 end ),
    tier_distribution: $tierdist,
    unattributed_session_rate: ( if $nsess>0 then rnd($unattr_sessions/$nsess) else 0 end ),
    pr_resolved_present: ( $all | any(.attribution_tier=="pr-resolved") ),
    count_once_overlap: $count_once_overlap,
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
       && grep -qE '^(fix|feat)/' <<<"$branch"; then
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
#    append fresh; bump meta schema_version to 1.2.0). Atomic tmp -> mv. ──
do_emit() {
  local store_dir="$1" resolve_prs="$2"
  local store_file="$store_dir/usage.jsonl"
  if [ ! -f "$store_file" ] || [ ! -r "$store_file" ]; then
    printf 'FATAL (exit 3): FinOps store unreadable: %s (run extract-usage.sh first)\n' "$store_file" >&2
    exit 3
  fi
  local hub_dir log wt_map ev_list overlap_map
  hub_dir="$(resolve_hub_state_dir)"
  log="$(resolve_event_log)"
  wt_map="$(build_worktree_milestone_map "$hub_dir")"
  ev_list="$(build_issue_event_list "$log")"
  overlap_map="$(build_count_once_overlap_map "$store_file")"
  [ -n "$overlap_map" ] || overlap_map='{}'

  # ── Store-shape preflight (schema v1.2.0). A pre-v1.2.0 store carries `cwd`, not
  #    `worktree`; the resolver's worktree join would then resolve to null, that session
  #    would fall through to `unattributed`, and its spend would vanish from the roll-up
  #    while the run still exits 0. Fail loudly instead of silently under-reporting an
  #    operator's roll-up. This is the STORE-skew guard; CODE skew (resolver not updated
  #    with the schema) is caught by --self-test's ground-truth oracle. Exit 3 is the
  #    existing "store unreadable" code — a store the resolver cannot read is exactly
  #    that; no new exit code, no contract change.
  #
  #    THE PREDICATE GATES ON THE PRESENCE OF ANY LEGACY RECORD, NOT ON THE ABSENCE OF ALL
  #    CURRENT ONES. The worktree join is evaluated PER RECORD, so a single legacy record is
  #    enough to lose its own T1/T3 attribution — a store is unsafe to roll up the moment ONE
  #    such record exists. Asking instead "do ZERO records carry worktree?" (the earlier
  #    shape) let one current record disarm the guard for the whole store, so a MIXED store
  #    rolled up at exit 0 with a silently under-reported attributed fraction: the exact
  #    fail-open this preflight exists to prevent, one layer down. `has("worktree")` is the
  #    discriminator — a CURRENT record whose source carried no cwd holds an explicit
  #    `worktree: null` (key present) and is correctly NOT legacy; the resolver routes it to
  #    `unattributed` on purpose, with a basis. ──
  local n_sess n_legacy probe_rc=0
  n_sess="$(jq -s '[.[]|select(.record=="session")]|length' "$store_file" 2>/dev/null)"
  probe_rc=$(( probe_rc + $? ))
  n_legacy="$(jq -s '[.[]|select(.record=="session" and (has("worktree")|not))]|length' "$store_file" 2>/dev/null)"
  probe_rc=$(( probe_rc + $? ))
  # FAIL CLOSED: the shape probe must never itself read as a pass. If jq aborted or returned
  # anything but a count, the store's shape is UNKNOWN — which is not the same as clean, and
  # the old `${n:-0}` default silently converted exactly that case into "no legacy records".
  if [ "$probe_rc" -ne 0 ] \
     || ! grep -qE '^[0-9]+$' <<<"$n_sess" \
     || ! grep -qE '^[0-9]+$' <<<"$n_legacy"; then
    printf 'FATAL (exit 3): FinOps store shape could not be determined: %s\n' "$store_file" >&2
    printf 'The store-shape preflight could not read the store (jq probe failed, or returned a non-count).\n' >&2
    printf 'Refusing to roll up a store of unknown shape. The store is a derived cache; rebuild it,\n' >&2
    printf 'then re-run the roll-up:\n' >&2
    printf '  bash %s/extract-usage.sh --rebuild\n' "$SCRIPT_DIR" >&2
    exit 3
  fi
  if [ "$n_legacy" -gt 0 ]; then
    if [ "$n_legacy" -eq "$n_sess" ]; then
      printf 'FATAL (exit 3): FinOps store predates schema v1.2.0 — session records carry no `worktree` field.\n' >&2
    else
      printf 'FATAL (exit 3): FinOps store is MIXED — %s of %s session record(s) predate schema v1.2.0 (no `worktree` field).\n' "$n_legacy" "$n_sess" >&2
      printf 'The v1.2.0 records would roll up normally while the legacy ones silently drop out, so the run\n' >&2
      printf 'would report an UNDER-COUNTED attributed fraction as if it were healthy.\n' >&2
    fi
    printf 'The store is a derived cache; rebuild it, then re-run the roll-up:\n' >&2
    printf '  bash %s/extract-usage.sh --rebuild\n' "$SCRIPT_DIR" >&2
    exit 3
  fi

  local sessions resolutions rolled tmp
  sessions="$(mktemp "${TMPDIR:-/tmp}/finops-sess.XXXXXX")"
  resolutions="$(mktemp "${TMPDIR:-/tmp}/finops-res.XXXXXX")"
  rolled="$(mktemp "${TMPDIR:-/tmp}/finops-roll.XXXXXX")"

  jq -c 'select(.record=="session")' "$store_file" > "$sessions" 2>/dev/null

  # Pass 1: resolve each session (LOCAL-ONLY), net of the FM-2 count-once deduction.
  jq -s -c --argjson wt_milestone "$wt_map" --argjson issue_events "$ev_list" \
     --argjson overlap_by_session "$overlap_map" \
     "$JQ_RESOLVE" "$sessions" > "$resolutions" 2>/dev/null

  # Pass 2 (opt-in): T-PR network upgrade for unattributed fix/feat.
  if [ "$resolve_prs" -eq 1 ]; then
    apply_pr_resolve < "$resolutions" > "$resolutions.pr" && mv -f "$resolutions.pr" "$resolutions"
  fi

  # Pass 3: roll up → rollup rows + coverage.
  jq -s -c "$JQ_ROLLUP" "$resolutions" > "$rolled" 2>/dev/null

  # Rewrite store: meta(schema_version=1.2.0) + verbatim session/subagent + rollup/coverage.
  tmp="$store_file.tmp"
  jq -c 'select(.record=="meta") | .schema_version="1.2.0" | .generator_version=$gv' \
     --arg gv "$(generator_version)" "$store_file" > "$tmp" 2>/dev/null
  jq -c 'select(.record=="session" or .record=="subagent")' "$store_file" >> "$tmp" 2>/dev/null
  cat "$rolled" >> "$tmp"
  mv -f "$tmp" "$store_file"

  rm -f "$sessions" "$resolutions" "$rolled"
  local nroll ncov health overlap
  nroll="$(jq -s '[.[]|select(.record=="rollup")]|length' "$store_file" 2>/dev/null)"
  ncov="$(jq -s '[.[]|select(.record=="coverage")]|length' "$store_file" 2>/dev/null)"
  health="$(jq -r 'select(.record=="coverage")|.health' "$store_file" 2>/dev/null | head -1)"  # sigpipe-idiom: allow — pre-existing at the pin, out of sweep scope; no `set -e` in this script; jq emits one coverage field and the value is consumed, not the status
  overlap="$(jq -r 'select(.record=="coverage")|.count_once_overlap' "$store_file" 2>/dev/null | head -1)"  # sigpipe-idiom: allow — pre-existing at the pin, out of sweep scope; no `set -e` in this script; jq emits one coverage field and the value is consumed, not the status
  printf 'finops-usage-extractor rollup: %s (%s rollup record(s), %s coverage; health=%s; count-once-overlap=%s)\n' \
    "$store_file" "${nroll:-?}" "${ncov:-?}" "${health:-?}" "${overlap:-0}" >&2
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
     --argjson overlap_by_session "$(build_count_once_overlap_map "$st/usage.jsonl")" \
     "$JQ_RESOLVE" "$sessions" > "$res" 2>/dev/null
  # Opt-in T-PR with the stub so the pr-resolved fixture resolves deterministically (no gh).
  if [ -f "$fx_prstub" ]; then
    FINOPS_PR_STUB="$fx_prstub" apply_pr_resolve < "$res" > "$res.pr" && mv -f "$res.pr" "$res"
  fi
  got="$(jq -s -S 'map({session_id, work_item, work_item_kind, attribution_tier}) | sort_by(.session_id)' "$res" 2>/dev/null)"
  want="$(jq -S 'sort_by(.session_id)' "$fx_oracle" 2>/dev/null)"
  if [ "$got" != "$want" ]; then
    echo "FAIL: CIAC-1 ground-truth — resolver did not reproduce the labeled oracle"
    # sigpipe-idiom: allow — multi-line diagnostic preview after an already-recorded FAIL; `diff` has no bounded-output flag to fold `head` into.
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
  health="$(jq -r 'select(.record=="coverage")|.health' "$st/usage.jsonl" | head -1)"  # sigpipe-idiom: allow — pre-existing at the pin, out of sweep scope; no `set -e` in this script; jq emits one coverage field and the value is consumed, not the status
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

  # (H) meta bumped to 1.2.0.
  local sv
  sv="$(jq -r 'select(.record=="meta")|.schema_version' "$st/usage.jsonl" | head -1)"  # sigpipe-idiom: allow — pre-existing at the pin, out of sweep scope; no `set -e` in this script; jq emits one meta field and the value is consumed, not the status
  [ "$sv" = "1.2.0" ] && echo "  PASS: meta.schema_version bumped to 1.2.0" || { echo "FAIL: meta.schema_version != 1.2.0 (got $sv)"; fail=1; }

  # (I) FM-2 count-once (hub<->spoke file boundary). A spoke that appears BOTH as an
  #     in-transcript sidechain `subagent` inside a hub session AND as its own standalone
  #     `session` must be counted EXACTLY ONCE: the standalone session is authoritative and
  #     the overlapping sidechain contribution is excluded from the hub's roll-up
  #     contribution (not double-summed); the collision surfaces in coverage.count_once_overlap.
  #     Ground-truth against the dedicated overlap fixture + oracle.
  local co_dir="$FIXTURES_DIR/count-once"
  local co_store="$co_dir/usage.jsonl" co_oracle="$co_dir/count-once.expected.json"
  if [ -f "$co_store" ] && [ -f "$co_oracle" ]; then
    local co_st want_wi want_once want_naive want_overlap got_total got_overlap
    co_st="$(mktemp -d "${TMPDIR:-/tmp}/finops-roll-countonce.XXXXXX")"
    cp "$co_store" "$co_st/usage.jsonl"
    # Isolate from operator hub-state / event-log (non-existent paths -> empty surfaces);
    # both fixture sessions resolve via T2 (release branch -> milestone:v9.9).
    STORE="$co_st" FINOPS_HUB_STATE_DIR="$co_st/.no-hub" FINOPS_PIPELINE_EVENT_LOG="$co_st/.no-log" \
      do_emit "$co_st" 0 >/dev/null 2>&1
    want_wi="$(jq -r '.work_item' "$co_oracle")"
    want_once="$(jq -r '.count_once_rollup_total' "$co_oracle")"
    want_naive="$(jq -r '.naive_double_count_total' "$co_oracle")"
    want_overlap="$(jq -r '.count_once_overlap' "$co_oracle")"
    got_total="$(jq -s --arg wi "$want_wi" '[.[]|select(.record=="rollup" and .work_item==$wi)|(.tokens.input+.tokens.output+.tokens.cache_creation.total+.tokens.cache_read)]|add // 0' "$co_st/usage.jsonl")"
    got_overlap="$(jq -s '[.[]|select(.record=="coverage")|.count_once_overlap]|first // 0' "$co_st/usage.jsonl")"
    if [ "$got_total" = "$want_once" ] && [ "$got_total" != "$want_naive" ] && [ "$got_overlap" = "$want_overlap" ]; then
      echo "  PASS: FM-2 count-once ($want_wi total=$got_total counted once — not the $want_naive double-count; coverage.count_once_overlap=$got_overlap)"
    else
      echo "FAIL: FM-2 count-once — $want_wi total=$got_total (want $want_once, must differ from naive $want_naive); count_once_overlap=$got_overlap (want $want_overlap)"; fail=1
    fi
    rm -rf "$co_st"
  else
    echo "FAIL: FM-2 count-once fixture missing ($co_store / $co_oracle)"; fail=1
  fi

  # (J) STORE-SKEW preflight — a pre-v1.2.0 on-disk store (session records carrying `cwd`,
  #     not `worktree`) must be REFUSED with exit 3, not silently rolled up. Without this
  #     guard the worktree join resolves to null for every session, the roll-up emits an
  #     empty result, and the coverage record reports health=OK / 100% attributed while all
  #     spend vanishes — a fail-open in the honesty instrument. #4044 is what creates this
  #     skew (upgraded code, operator's existing store), so the guard ships with it.
  #     do_emit is run in a SUBSHELL: its `exit 3` must not terminate the self-test.
  local lg_st lg_rc
  lg_st="$(mktemp -d "${TMPDIR:-/tmp}/finops-roll-legacy.XXXXXX")"
  jq -c 'if .record=="session" then (.cwd = "/synthetic/ws/" + .worktree | del(.worktree)) else . end' \
     "$fx_store" > "$lg_st/usage.jsonl" 2>/dev/null
  ( STORE="$lg_st" FINOPS_HUB_STATE_DIR="$lg_st/.no-hub" FINOPS_PIPELINE_EVENT_LOG="$lg_st/.no-log" \
      do_emit "$lg_st" 0 >/dev/null 2>&1 )
  lg_rc=$?
  if [ "$lg_rc" -eq 3 ]; then
    echo "  PASS: legacy-store preflight (pre-v1.2.0 store refused, exit 3)"
  else
    echo "FAIL: legacy-store preflight — pre-v1.2.0 store was NOT refused (exit $lg_rc, want 3)"; fail=1
  fi
  rm -rf "$lg_st"

  # (K) MIXED-STORE preflight — a store carrying BOTH a legacy session record (no `worktree`)
  #     and current ones (with `worktree`) must be REFUSED with exit 3, exactly like the wholly
  #     legacy store in (J). The worktree join is evaluated PER RECORD, so ONE legacy record
  #     loses its own T1/T3 attribution while every other record resolves normally: the run
  #     would otherwise complete at exit 0 with a silently UNDER-COUNTED attributed fraction —
  #     the same fail-open (J) guards against, one layer down, and invisible because the store
  #     still looks healthy. This case is what forces the predicate to gate on the PRESENCE OF
  #     ANY legacy record rather than the ABSENCE OF ALL current ones.
  #     Paired with a no-false-positive half: a wholly CURRENT store must NOT be refused —
  #     without it the guard could be "fixed" by refusing everything, which passes the first
  #     half and breaks every green path.
  #     do_emit runs in a SUBSHELL in both halves: its `exit 3` must not terminate the self-test.
  local mx_st mx_rc mx_legacy mx_current cur_st cur_rc
  mx_st="$(mktemp -d "${TMPDIR:-/tmp}/finops-roll-mixed.XXXXXX")"
  # Downgrade exactly ONE session record (…001) to the pre-v1.2.0 shape; the other seven keep
  # `worktree`. One legacy record is the minimal trigger and the case the old predicate missed.
  jq -c 'if .record=="session" and (.session_id | endswith("1"))
         then (.cwd = "/synthetic/ws/" + .worktree | del(.worktree)) else . end' \
     "$fx_store" > "$mx_st/usage.jsonl" 2>/dev/null
  # Assert the constructed fixture really IS mixed BEFORE asserting on the guard — a silently
  # no-op downgrade would otherwise let this test "pass" against a store it never mixed.
  mx_legacy="$(jq -s '[.[]|select(.record=="session" and (has("worktree")|not))]|length' "$mx_st/usage.jsonl" 2>/dev/null)"
  mx_current="$(jq -s '[.[]|select(.record=="session" and has("worktree"))]|length' "$mx_st/usage.jsonl" 2>/dev/null)"
  if [ "${mx_legacy:-0}" -lt 1 ] || [ "${mx_current:-0}" -lt 1 ]; then
    echo "FAIL: mixed-store fixture is not actually mixed (legacy=${mx_legacy:-0}, current=${mx_current:-0}) — test would not be exercising the guard"; fail=1
  else
    ( STORE="$mx_st" FINOPS_HUB_STATE_DIR="$fx_hub" FINOPS_PIPELINE_EVENT_LOG="$fx_log" \
        do_emit "$mx_st" 0 >/dev/null 2>&1 )
    mx_rc=$?
    if [ "$mx_rc" -eq 3 ]; then
      echo "  PASS: mixed-store preflight ($mx_legacy legacy + $mx_current v1.2.0 record(s) refused, exit 3)"
    else
      echo "FAIL: mixed-store preflight — a store with $mx_legacy legacy + $mx_current v1.2.0 session record(s) was NOT refused (exit $mx_rc, want 3); its legacy spend would silently drop out of the roll-up"; fail=1
    fi
  fi
  rm -rf "$mx_st"

  # (K2) No false positive — a wholly CURRENT (v1.2.0) store must roll up normally (exit 0).
  cur_st="$(mktemp -d "${TMPDIR:-/tmp}/finops-roll-current.XXXXXX")"
  cp "$fx_store" "$cur_st/usage.jsonl"
  ( STORE="$cur_st" FINOPS_HUB_STATE_DIR="$fx_hub" FINOPS_PIPELINE_EVENT_LOG="$fx_log" \
      do_emit "$cur_st" 0 >/dev/null 2>&1 )
  cur_rc=$?
  if [ "$cur_rc" -eq 0 ]; then
    echo "  PASS: preflight does not fire on a wholly v1.2.0 store (exit 0, green path intact)"
  else
    echo "FAIL: preflight FALSE POSITIVE — wholly v1.2.0 store was refused (exit $cur_rc, want 0)"; fail=1
  fi
  rm -rf "$cur_st"

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
      # sigpipe-idiom: allow — `head` truncates the RENDERED help text, not the match set; an intervening `sed` sits between grep and head, so `-m50` would cap the wrong stage.
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
