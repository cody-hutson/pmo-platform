#!/bin/bash
# finops-usage-extractor — reporting + trends module (slice C4).
#
# Reads the operator-local FinOps usage store produced by extract-usage.sh (C1)
# and rolled up by rollup-attribution.sh (C2), and renders an operator-facing
# spend report over a date window — sliced by work item, worktree, skill, MCP
# server and model — plus a period-bucketed trend view. The store schema
# authority is core/schemas/finops-usage-store-schema.md.
#
# worktree = the session's working-directory BASENAME (store field
# session.worktree). A filesystem directory name — NOT a PMO project. The FinOps
# store carries no PMO-project field, so there is no --by project dimension.
#
# READ-ONLY, WRITES NOTHING — the report prints to stdout and creates no file,
# so no artifact exists that could be accidentally committed (CIAC-3 data hygiene).
#
# Honesty contract (four structural rules, not review conventions):
#   1. A best-effort slice's coverage clause is concatenated INTO its section
#      header string in one renderer, so a coverage-less by_skill / by_mcp
#      section is unrepresentable rather than merely forbidden.
#   2. Every operator-facing figure carries its provenance: the marker rides the
#      numeral (`12,340` exact vs `~12,340` not exact) so it survives a paste
#      that drops the tag column, plus an explicit tag column and, on work-item
#      rows, the attribution-tier weighting.
#   3. A trend DIRECTION is emitted only for an exact-grade dimension. On a
#      best-effort dimension a coverage change is not separable from a spend
#      change, so no arrow, no percentage delta.
#   4. Availability is detected PER FIELD on the windowed records, never from
#      meta.schema_version; and the roll-up-has-run predicate is the presence of
#      the run-level `coverage` record, never the version string.
#
# The reserved "unknown" key of every by_X map is the uncovered remainder, NOT a
# dimension value. It is rendered as an explicit uncovered-remainder row, never
# as a skill / MCP server / model named "unknown".
#
# Store path resolution (no hardcoded operator path; same as extract-usage.sh):
#   env STORE > env FINOPS_STORE_PATH > operator.toml [paths].operator_instance_finops_store_path
#   > default ${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/finops
# The resolved path VALUE is never printed (it is an operator home path); only
# the resolution chain is declared in the report header.
#
# Test-only clock override: env FINOPS_REPORT_NOW=YYYY-MM-DD
#
# Usage:
#   bash report-usage.sh [--window N[d] | --since YYYY-MM-DD --until YYYY-MM-DD]
#                        [--by work-item|worktree|skill|mcp|model|all]
#                        [--trend] [--period day|week|month] [--json] [--self-test]
#     --window N[d]  relative window ending today: the last N calendar days,
#                    inclusive of today (DEFAULT 30). Mutually exclusive with
#                    --since / --until.
#     --since DATE   absolute lower bound, YYYY-MM-DD, inclusive of that day.
#     --until DATE   absolute upper bound, YYYY-MM-DD, inclusive of that day.
#     --by DIM       slice dimension (DEFAULT all). No `project` dimension exists.
#     --trend        additionally render the period-bucketed trend view.
#     --period P     trend bucket granularity: day|week|month (DEFAULT week).
#     --json         emit the machine shape instead of markdown.
#     --self-test    run built-in assertions against the synthetic report
#                    fixtures; no operator-store or network access.
#
# Exit codes: 0 ok · 2 usage error · 3 store unreadable · 4 store-not-git-ignored
#             (fail-closed public-repo exfil guard) · 5 missing dependency (jq/git).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_MD="$SCRIPT_DIR/../SKILL.md"
FIXTURES_DIR="$SCRIPT_DIR/../test-fixtures/report"
SELF="$SCRIPT_DIR/report-usage.sh"
SIBLING="$SCRIPT_DIR/rollup-attribution.sh"

# ── VERBATIM from rollup-attribution.sh:53-61 — parity asserted by --self-test SM-1. Do NOT edit here alone. ──
preflight_deps() {
  local missing=""
  command -v jq  >/dev/null 2>&1 || missing="jq"
  command -v git >/dev/null 2>&1 || missing="${missing:+$missing, }git"
  if [ -n "$missing" ]; then
    printf 'FATAL (exit 5): missing dependency: %s — see SKILL.md ## Dependencies\n' "$missing" >&2
    exit 5
  fi
}

# ── VERBATIM from rollup-attribution.sh:64-68 — parity asserted by --self-test SM-1. Do NOT edit here alone. ──
generator_version() {
  local v=""
  [ -r "$SKILL_MD" ] && v="$( { grep -E '^version:' "$SKILL_MD" 2>/dev/null || true; } | head -1 | awk '{print $2}')"
  printf '%s' "${v:-unknown}"
}

# ── VERBATIM from rollup-attribution.sh:71-75 — parity asserted by --self-test SM-1. Do NOT edit here alone. ──
toml_val() {
  local key="$1" toml="${HOME}/.config/pmo-platform/operator.toml"
  [ -r "$toml" ] || return 0
  { grep -E "^${key}" "$toml" 2>/dev/null || true; } | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}'
}

# ── VERBATIM from rollup-attribution.sh:77-81 — parity asserted by --self-test SM-1. Do NOT edit here alone. ──
workspace_root() {
  local wr="${CLAUDE_WORKSPACE_ROOT:-}"
  [ -z "$wr" ] && wr="$(toml_val claude_workspace_root)"
  printf '%s' "${wr:-${HOME}/Claude}"
}

# ── VERBATIM from rollup-attribution.sh:84-89 — parity asserted by --self-test SM-1. Do NOT edit here alone. ──
resolve_store() {
  local store="${STORE:-${FINOPS_STORE_PATH:-}}"
  [ -z "$store" ] && store="$(toml_val operator_instance_finops_store_path)"
  store="${store:-$(workspace_root)/personal/pmo-instance/finops}"
  printf '%s' "$store"
}

# ── VERBATIM from rollup-attribution.sh:113-132 — parity asserted by --self-test SM-1. Do NOT edit here alone. ──
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

# ── §4 Window resolution — portable BSD/GNU date (BSD form first, GNU fallback). ──
now_date() { printf '%s' "${FINOPS_REPORT_NOW:-$(date -u +%Y-%m-%d)}"; }

# NOTE (portability, load-bearing): on BSD `date` the -v adjustment must precede
# the positional value — `-f FMT "$d" -v-8d` silently returns TODAY in the default
# format instead of failing, which would widen the window rather than error. Every
# result is therefore shape-validated below; a malformed bound is fatal, never a
# silently permissive comparison (an out-of-range window that reads as "all data"
# is the fail-open this guard exists to prevent).
date_shift() {
  local out
  out="$(date -u -j -f %Y-%m-%d -v"$2"d "$1" +%Y-%m-%d 2>/dev/null || true)"
  if ! printf '%s' "$out" | grep -aqE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
    out="$(date -u -d "$1 $2 days" +%Y-%m-%d 2>/dev/null || true)"
  fi
  if ! printf '%s' "$out" | grep -aqE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
    printf 'FATAL (exit 2): could not compute a date %s days from %s on this platform (got %s)\n' \
      "$2" "$1" "${out:-<empty>}" >&2
    exit 2
  fi
  printf '%s' "$out"
}
date_minus_days() { date_shift "$1" "-$2"; }
date_plus_1d()    { date_shift "$1" "+1"; }

# ── §5 The report jq program. Input: the slurped store. Output: a markdown
#    string (default) or the machine model (--json). Both surfaces are built from
#    ONE set of dimension-section objects produced by emit_dim_table, so the
#    coverage + provenance rules have exactly one enforcement point. ──
read -r -d '' JQ_REPORT <<'JQEOF' || true
# ---------------------------------------------------------------------------
# Dimension registry — one definition site. Grade drives BOTH the coverage label
# (CIAC-2) and the trend-direction gate (the TC-gate), because a direction claim
# IS a completeness claim. A sixth dimension is one entry here.
# ---------------------------------------------------------------------------
def dim_registry: {
  "work-item": {grade:"exact",       label:"work item",                                     field:null,       noun:"work item",   indef:"a work item"},
  "worktree":  {grade:"exact",       label:"worktree (session working-directory basename)",  field:null,       noun:"worktree",    indef:"a worktree"},
  "skill":     {grade:"best-effort", label:"skill (best-effort — partial population)",       field:"by_skill", noun:"skill",       indef:"a skill"},
  "mcp":       {grade:"best-effort", label:"MCP server (best-effort — partial population)",  field:"by_mcp",   noun:"MCP server",  indef:"an MCP server"},
  "model":     {grade:"exact",       label:"model",                                          field:"by_model", noun:"model",       indef:"a model"}
};
def dim_order: ["work-item","worktree","skill","mcp","model"];

# ---------------------------------------------------------------------------
# leaf_total — the four cost-relevant leaves of a tokens object.
#
# SA-3 (the silent-zero). The entry value of a v1.2.0 by_X map is the WRAPPER
# {turns, tokens}, NOT a bare tokens object. An accessor that tests the entry
# itself for `input` finds nothing, falls through to `else 0`, and renders EVERY
# by-skill / by-mcp / by-model slice as zero — no error, no exit code, a
# plausible-looking all-zero report. Reach `.tokens` FIRST.
# ---------------------------------------------------------------------------
def leaf_sum: (.input // 0) + (.output // 0) + ((.cache_creation.total) // 0) + (.cache_read // 0);
def leaf_total:
  if type == "object" and has("tokens") then (.tokens | leaf_sum)   # v1.2.0 {turns, tokens} wrapper
  elif type == "object" and has("input") then leaf_sum              # bare tokens object (tolerated)
  elif type == "number" then .                                      # scalar total (tolerated)
  else 0 end;
def sess_total: (.tokens // {}) | leaf_sum;

# ---------------------------------------------------------------------------
# dim_coverage — the SINGLE coverage accessor (SA-4).
# Coverage lives at session.dimension_coverage.by_<x> and is a two-field object
# {covered_token_fraction, basis} — not session.by_<x>_coverage, and not a bare
# number. Semantics (SA-5) are TOKEN basis: 1 − (by_X."unknown" ÷ session total).
# Every coverage read in this program funnels through here.
# ---------------------------------------------------------------------------
def dim_cov_key($dim): {"skill":"by_skill","mcp":"by_mcp"}[$dim];
def dim_coverage($rec; $dim):
  (dim_cov_key($dim)) as $k
  | if $k == null then null
    else ($rec.dimension_coverage[$k] // null)
      | if . == null then null
        elif type == "object" then (.covered_token_fraction // null)
        elif type == "number" then .
        else null end
    end;
def dim_basis($rec; $dim):
  (dim_cov_key($dim)) as $k
  | if $k == null then null
    else (($rec.dimension_coverage[$k] // null) | if type == "object" then (.basis // null) else null end)
    end;

# Token-weighted mean coverage over a session set. Equals 1 − Σunknown/Σtotal,
# the correct aggregate of a per-session token-basis fraction. null when NO
# session in the set carries the field — rendered explicitly, never as 100%.
def agg_coverage($sessions; $dim):
  [ $sessions[] | . as $s | dim_coverage($s; $dim) as $c
    | select($c != null) | {w: ($s | sess_total), c: $c} ] as $ws
  | if ($ws | length) == 0 then null
    else ([$ws[] | .w] | add) as $tw
      | if $tw == 0 then 1 else (([$ws[] | .w * .c] | add) / $tw) end
    end;

# ---------------------------------------------------------------------------
# worktree_of — SA-11-tolerant. Renders session.worktree (a BASENAME); falls back
# to basename(cwd) on a pre-v1.2.0 store. NEVER renders project_dir (a
# path-mangled ABSOLUTE path) and never the raw cwd.
# ---------------------------------------------------------------------------
def worktree_of:
  (.worktree // (if (.cwd // null) != null then (.cwd | split("/") | last) else null end) // "(unknown)");

# ---------------------------------------------------------------------------
# Provenance rendering (CIAC-4).
# Layer 1 — the marker rides the numeral, so it survives a paste that drops the
# tag column: `12,340` = exact, `~12,340` = not exact.
# ---------------------------------------------------------------------------
def commafy:
  . as $v
  | (if $v < 0 then "-" else "" end) as $sign
  | ((if $v < 0 then (-$v) else $v end) | floor | tostring) as $s
  | ($s | length) as $L
  | $sign + ([ range(0; $L) | . as $i
      | $s[$i:$i+1] + (if ((($L - 1 - $i) % 3) == 0 and $i < ($L - 1)) then "," else "" end) ] | join(""));
def fig($src): (commafy) | if $src == "exact" then . else "~" + . end;

# Layer 2 — the explicit tag column, reusing the shipped evidence-label vocabulary.
def src_label($src; $ht; $turns):
  if $src == "exact" then "[SOURCE: exact message.usage]"
  elif $src == "heuristic" then "[INFERRED: ceil(words/0.75) fallback]"
  else "[MIXED: " + (($ht // 0) | tostring) + " heuristic turn(s) of " + (($turns // 0) | tostring) + "]" end;
def tier_label($t): {
  "branch-milestone":  "[tier: branch-milestone — deterministic, local]",
  "issue-event-keyed": "[tier: issue-event-keyed — best-effort, fuzzy key]",
  "hub-state-lineage": "[tier: hub-state-lineage — deterministic join, local]",
  "pr-resolved":       "[tier: pr-resolved — NETWORK, reproducible:false]",
  "unattributed":      "[tier: unattributed — unresolved]",
  "not-rolled-up":     "[tier: not-rolled-up — session absent from every rollup row]"
}[$t] // ("[tier: " + ($t | tostring) + "]");
# The extractor's own token_source rule, recomputed over the filtered subset.
def tsrc($turns; $ht): if $ht == 0 then "exact" elif $ht >= $turns then "heuristic" else "mixed" end;

# ---------------------------------------------------------------------------
# section_header — CIAC-2 enforced STRUCTURALLY. The coverage clause is
# concatenated INTO the header string, not emitted as a second statement, so a
# best-effort header without `coverage:` is unrepresentable. Absent field is
# explicit — never 100%, never nothing.
# ---------------------------------------------------------------------------
def section_header($dim; $cov):
  dim_registry[$dim] as $d
  | if $d.grade == "best-effort"
    then "### " + $d.label + " — coverage: "
         + (if $cov == null then "unknown (coverage field absent — treat as 0% verified)"
            else ((($cov * 100) | round | tostring) + "% (token-weighted over sessions in window)") end)
    else "### " + $d.label end;

# ---------------------------------------------------------------------------
# emit_dim_table — the ONE construction site for a dimension section. Both the
# markdown and the JSON path consume the object this returns, so there is no
# second emit path that could omit the coverage or provenance fields.
# ---------------------------------------------------------------------------
def emit_dim_table($dim; $cov; $basis; $rows; $remainder; $unavailable):
  dim_registry[$dim] as $d
  | { dim: $dim, label: $d.label, grade: $d.grade,
      coverage: $cov, coverage_basis: $basis,
      header: section_header($dim; $cov),
      available: ($unavailable == null),
      unavailable_reason: $unavailable,
      rows: $rows,
      uncovered_remainder: $remainder,
      total: ([$rows[] | .tokens] | add // 0) };

# ---------------------------------------------------------------------------
# Trend bucketing. Week = Monday-start UTC weeks labelled by start date (not ISO
# week numbers — no week-53 / year-boundary ambiguity, and the label sorts
# lexicographically = chronologically).
# ---------------------------------------------------------------------------
def to_epoch: (. + "T00:00:00Z") | strptime("%Y-%m-%dT%H:%M:%SZ") | mktime;
def from_epoch: strftime("%Y-%m-%d");
def bucket_of($period):
  .[0:10] as $d
  | if $period == "day" then $d
    elif $period == "month" then ($d[0:7] + "-01")
    else ($d | to_epoch) as $e
      | ((($e | gmtime)[6] + 6) % 7) as $dow      # gmtime[6] = wday (0=Sun); Monday-start
      | (($e - ($dow * 86400)) | from_epoch)
    end;
def next_bucket($period):
  if $period == "day" then ((to_epoch + 86400) | from_epoch)
  elif $period == "week" then ((to_epoch + 604800) | from_epoch)
  else (.[0:4] | tonumber) as $y | (.[5:7] | tonumber) as $m
    | if $m == 12 then (($y + 1) | tostring) + "-01-01"
      else ($y | tostring) + "-" + (if ($m + 1) < 10 then "0" else "" end) + (($m + 1) | tostring) + "-01" end
  end;
def bucket_end($period):
  if $period == "day" then .
  elif $period == "week" then ((to_epoch + 518400) | from_epoch)
  else ((next_bucket("month") | to_epoch) - 86400 | from_epoch) end;
# DENSE bucket set — every bucket from window start to end is generated, then
# left-joined. An omitted empty bucket makes a gap read as continuity.
def dense_buckets($since; $until; $period):
  ($until | bucket_of($period)) as $last
  | [ ($since | bucket_of($period)) | recurse(if . < $last then next_bucket($period) else empty end) ];

# Trend direction over COMPLETE, NON-EMPTY buckets only. Empty periods are an
# absence of work, not a spend trend; the current (partial) period is the classic
# false-decline. Both are shown and both are excluded from direction.
def trend_verdict($rows; $grade; $dim_label):
  if $grade != "exact" then
    ("TREND: NOT CHARACTERIZED — `" + $dim_label + "` is a best-effort dimension (partial population). "
     + "Per-period volumes and per-period coverage are shown; a direction is not computable because a "
     + "change in coverage is not separable from a change in spend.")
  else
    [ $rows[] | select((.empty | not) and (.partial | not)) | .tokens ] as $v
    | ($v | length) as $n
    | if $n < 3 then
        ("TREND: INSUFFICIENT — " + ($n | tostring) + " non-empty complete period(s); "
         + "≥3 required to characterize a direction.")
      else
        ($n / 2 | floor) as $h
        | (([ $v[0:$h][] ] | add) / $h) as $first
        | (([ $v[($n - $h):][] ] | add) / $h) as $second
        | (if $first == 0 then 0 else (($second - $first) / $first) end) as $delta
        | (($delta * 100) | round) as $pct
        | if ($delta > 0.10) then ("TREND: RISING +" + ($pct | tostring) + "% (mean of first " + ($h | tostring)
              + " complete period(s) vs last " + ($h | tostring) + ")")
          elif ($delta < -0.10) then ("TREND: FALLING " + ($pct | tostring) + "% (mean of first " + ($h | tostring)
              + " complete period(s) vs last " + ($h | tostring) + ")")
          else ("TREND: FLAT (" + (if $pct >= 0 then "+" else "" end) + ($pct | tostring)
              + "%, inside the ±10% band)") end
      end
  end;

# ===========================================================================
# Model construction
# ===========================================================================
. as $all
| ([$all[] | select(.record == "meta")] | first // {}) as $meta
# The BINDING roll-up gate: the canonical "a roll-up has run" predicate is the
# presence of the run-level `coverage` record. NEVER meta.schema_version — from
# v1.2.0 both phases emit the same version, and rollup-attribution.sh rewrites it
# unconditionally, so the version string cannot answer this question.
| ($all | any(.record == "coverage")) as $rolled_up
| (if $rolled_up
   then reduce ($all[] | select(.record == "rollup")) as $r ({};
          reduce ($r.session_ids // [])[] as $sid (.;
            .[$sid] = {work_item: $r.work_item, work_item_kind: $r.work_item_kind,
                       attribution_tier: $r.attribution_tier, reproducible: $r.reproducible}))
   else {} end) as $attr_map
| [ $all[] | select(.record == "session")
    | select((.started_utc // "") >= $since_iso and (.started_utc // "") < $until_excl_iso) ] as $win
| ([$win[] | sess_total] | add // 0) as $grand
| ([$win[] | .turns // 0] | add // 0) as $grand_turns
| ([$win[] | .heuristic_turns // 0] | add // 0) as $grand_ht
| (tsrc($grand_turns; $grand_ht)) as $grand_src

# ---- work-item rows (D-ReportJoin: invert rollup.session_ids -> re-sum sessions) ----
| ( if ($rolled_up | not) then null
    else ( $win
      | group_by(($attr_map[.session_id].work_item) // "(not-rolled-up)")
      | map( . as $g
        | (($attr_map[$g[0].session_id]) // null) as $a
        | ([$g[] | .turns // 0] | add) as $t
        | ([$g[] | .heuristic_turns // 0] | add) as $h
        | { key: (($a.work_item) // "(not-rolled-up)"),
            tokens: ([$g[] | sess_total] | add),
            sessions: ($g | length), turns: $t, heuristic_turns: $h,
            token_source: tsrc($t; $h),
            tier: (($a.attribution_tier) // "not-rolled-up"),
            reproducible: (if $a == null then null else $a.reproducible end) } )
      | map(. as $r | . + {figure: ($r.tokens | fig($r.token_source)),
                           provenance: src_label($r.token_source; $r.heuristic_turns; $r.turns),
                           tier_note: tier_label($r.tier)})
      | sort_by(-.tokens) ) end ) as $wi_rows

# ---- worktree rows ----
| ( $win
    | group_by(worktree_of)
    | map( . as $g
      | ([$g[] | .turns // 0] | add) as $t
      | ([$g[] | .heuristic_turns // 0] | add) as $h
      | { key: ($g[0] | worktree_of), tokens: ([$g[] | sess_total] | add),
          sessions: ($g | length), turns: $t, heuristic_turns: $h,
          token_source: tsrc($t; $h) } )
    | map(. as $r | . + {figure: ($r.tokens | fig($r.token_source)),
                         provenance: src_label($r.token_source; $r.heuristic_turns; $r.turns)})
    | sort_by(-.tokens) ) as $wt_rows

# ---- by_X map rows (skill / mcp / model). The reserved "unknown" key is SPLIT
#      OUT as the uncovered remainder and never rendered as a dimension value. ----
# Per-key accumulation over the windowed sessions. Alongside the token total each
# key carries the turn/heuristic-turn counts of the sessions that contributed to
# it, so a row's provenance is that row's own, not the window's aggregate.
| def map_rows($field):
    reduce $win[] as $s ({};
      reduce (($s[$field] // {}) | to_entries[]) as $e (.;
        .[$e.key] = { tokens: (((.[$e.key].tokens) // 0) + ($e.value | leaf_total)),
                      turns:  (((.[$e.key].turns)  // 0) + ($s.turns // 0)),
                      ht:     (((.[$e.key].ht)     // 0) + ($s.heuristic_turns // 0)) }));
  ( map_rows("by_skill") ) as $skill_all
| ( map_rows("by_mcp") ) as $mcp_all
| ( map_rows("by_model") ) as $model_all

| def named_rows($m): ($m | to_entries | map(select(.key != "unknown"))
    | map(. as $e | (tsrc($e.value.turns; $e.value.ht)) as $src
        | {key: $e.key, tokens: $e.value.tokens, turns: $e.value.turns,
           heuristic_turns: $e.value.ht, token_source: $src,
           figure: ($e.value.tokens | fig($src)),
           provenance: src_label($src; $e.value.ht; $e.value.turns)})
    | sort_by(-.tokens));
  # The reserved "unknown" key is the uncovered REMAINDER, never a dimension
  # value. It is lifted out of the row set entirely and rendered as its own
  # explicitly-labelled artefact so it cannot be read as a real dimension member.
  def remainder($dim; $m):
    dim_registry[$dim] as $d
    | (($m["unknown"]) // null)
    | if . == null then null
      else . as $u | (tsrc($u.turns; $u.ht)) as $src
        | { tokens: $u.tokens, fraction: (if $grand > 0 then ($u.tokens / $grand) else 0 end),
            figure: ($u.tokens | fig($src)), token_source: $src,
            label: ("(uncovered remainder — the source attributed no " + $d.noun
                    + " to these tokens; NOT " + $d.indef + " named \"unknown\")"),
            provenance: "[UNCOVERED: reserved \"unknown\" bucket]" }
      end;
  # An exact dimension's remainder is provably zero (the schema's conservation
  # invariant), so a zero row is noise; a NON-zero one is fail-visible and is
  # always rendered. A best-effort dimension always renders it — present-and-zero
  # is the datum that says "fully covered".
  def remainder_for($dim; $m):
    remainder($dim; $m) as $r
    | if $r == null then null
      elif dim_registry[$dim].grade == "exact" and $r.tokens == 0 then null
      else $r end;
  # Per-field capability detection on the WINDOWED records (never the version string).
  def field_present($field): ($win | any(has($field)));
  def unavail($field):
    if ($win | length) == 0 then "(no data in window)"
    elif (field_present($field) | not) then
      ("UNAVAILABLE: dimension absent from every session in window (store may predate the v1.2 "
       + "analysis dimensions; re-run extract-usage.sh)")
    else null end;

  [ ( emit_dim_table("work-item";
        null; null;
        ($wi_rows // []);
        null;
        (if ($win | length) == 0 then "(no data in window)"
         elif ($rolled_up | not) then
           ("UNAVAILABLE: no roll-up has run over this store (no `coverage` record present) — "
            + "run rollup-attribution.sh, then re-run this report")
         else null end)) ),
    ( emit_dim_table("worktree"; null; null; $wt_rows; null;
        (if ($win | length) == 0 then "(no data in window)" else null end)) ),
    ( emit_dim_table("skill";
        (agg_coverage($win; "skill")); ([$win[] | dim_basis(.; "skill")] | map(select(. != null)) | first // null);
        named_rows($skill_all); remainder_for("skill"; $skill_all); unavail("by_skill")) ),
    ( emit_dim_table("mcp";
        (agg_coverage($win; "mcp")); ([$win[] | dim_basis(.; "mcp")] | map(select(. != null)) | first // null);
        named_rows($mcp_all); remainder_for("mcp"; $mcp_all); unavail("by_mcp")) ),
    ( emit_dim_table("model"; null; null; named_rows($model_all);
        remainder_for("model"; $model_all); unavail("by_model")) )
  ] as $all_dims
| ( if $by == "all" then $all_dims else [$all_dims[] | select(.dim == $by)] end ) as $dims

# ---- tool-call + stop-reason counts (SA-7/SA-8: counts, not tokens; and
#      tool_calls is a DISTINCT sibling of the frozen tool_use, never folded) ----
| ( reduce $win[] as $s ({}; reduce (($s.tool_calls // {}) | to_entries[]) as $e (.;
      .[$e.key] = ((.[$e.key] // 0) + $e.value))) ) as $tool_calls
| ( reduce $win[] as $s ({}; reduce (($s.stop_reason // {}) | to_entries[]) as $e (.;
      .[$e.key] = ((.[$e.key] // 0) + $e.value))) ) as $stop_reason
| ( { web_search_requests: ([$win[] | .tool_use.web_search_requests // 0] | add // 0),
      web_fetch_requests:  ([$win[] | .tool_use.web_fetch_requests  // 0] | add // 0) } ) as $tool_use

# ---- trend ----
# NOTE: compare explicitly. In jq only `null` and `false` are falsy — `0` is
# TRUTHY, so `$do_trend | not` is false for both 0 and 1 and the trend would
# render unconditionally, making --trend a no-op.
| ( if ($do_trend != 1) then null
    else
      (dense_buckets($since; $until; $period)) as $buckets
      | ($now | bucket_of($period)) as $cur
      | ( $buckets | map( . as $b
          | [ $win[] | select((.started_utc | bucket_of($period)) == $b) ] as $bs
          | ([$bs[] | .turns // 0] | add // 0) as $t
          | ([$bs[] | .heuristic_turns // 0] | add // 0) as $h
          | (tsrc($t; $h)) as $src
          | ([$bs[] | sess_total] | add // 0) as $tok
          | { period: $b, period_end: ($b | bucket_end($period)),
              tokens: $tok, sessions: ($bs | length), token_source: $src,
              figure: (if ($bs | length) == 0 then "0" else ($tok | fig($src)) end),
              provenance: (if ($bs | length) == 0 then "—" else src_label($src; $h; $t) end),
              empty: (($bs | length) == 0), partial: ($b == $cur),
              note: (if ($bs | length) == 0 then "(empty — no sessions in this period)"
                     elif ($b == $cur) then ("(partial — period ends " + ($b | bucket_end($period))
                          + "; excluded from trend direction)") else "" end) } ) ) as $orows
      | def dim_trend($dim):
          dim_registry[$dim] as $d
          | ($buckets | map( . as $b
              | [ $win[] | select((.started_utc | bucket_of($period)) == $b) ] as $bs
              | ( if $d.field == null then ([$bs[] | sess_total] | add // 0)
                  else ([ $bs[] | (.[$d.field] // {}) | to_entries[] | select(.key != "unknown")
                          | .value | leaf_total ] | add // 0) end ) as $tok
              | ([$bs[] | .turns // 0] | add // 0) as $t
              | ([$bs[] | .heuristic_turns // 0] | add // 0) as $h
              | (tsrc($t; $h)) as $src
              | (agg_coverage($bs; $dim)) as $cov
              | { period: $b, period_end: ($b | bucket_end($period)),
                  tokens: $tok, sessions: ($bs | length), token_source: $src,
                  figure: (if ($bs | length) == 0 then "0" else ($tok | fig($src)) end),
                  provenance: (if ($bs | length) == 0 then "—" else src_label($src; $h; $t) end),
                  coverage: $cov,
                  coverage_pct: (if $cov == null then "—" else ((($cov * 100) | round | tostring) + "%") end),
                  empty: (($bs | length) == 0), partial: ($b == $cur),
                  note: (if ($bs | length) == 0 then "(empty — no sessions in this period)"
                         elif ($b == $cur) then ("(partial — period ends " + ($b | bucket_end($period))
                              + "; excluded from trend direction)") else "" end) } )) as $rows
          | ([ $rows[] | select(.coverage != null) | .coverage ]) as $covs
          | { dim: $dim, label: $d.label, grade: $d.grade,
              coverage: (agg_coverage($win; $dim)),
              header: section_header($dim; agg_coverage($win; $dim)),
              rows: $rows,
              verdict: trend_verdict($rows; $d.grade; $d.noun),
              coverage_drift:
                (if (($covs | length) >= 2 and (($covs | max) - ($covs | min)) > 0.10)
                 then ("COVERAGE-DRIFT: coverage ranges " + ((($covs | min) * 100 | round) | tostring) + "%–"
                       + ((($covs | max) * 100 | round) | tostring) + "% across periods. Volume changes on this "
                       + "dimension are not separable from capture-rate changes. "
                       + "[RECOMMENDED] threshold: 10 percentage points — a proposed value, not a measurement.")
                 else null end) };
        { period: $period,
          bucket_definition: (if $period == "week" then "Monday-start UTC weeks, labelled by start date"
                              elif $period == "month" then "calendar months, labelled by first day"
                              else "UTC calendar days" end),
          proration: "none — a boundary-spanning session is assigned wholly to its started_utc bucket",
          min_periods: "≥3 non-empty, complete periods are required to characterize a direction; empty and partial periods are shown but excluded",
          flat_band: "[RECOMMENDED] ±10% — a proposed value, not a measurement; no usage distribution exists to calibrate against",
          overall: { dim: "overall", label: "Overall spend", grade: "exact",
                     header: "### Overall spend (exact — every session in window)",
                     rows: $orows,
                     verdict: trend_verdict($orows; "exact"; "overall") },
          dimensions: [ $dims[] | select(.grade == "best-effort") | dim_trend(.dim) ] }
    end ) as $trend

| { generated_utc: $gen_utc,
    window: { since: $since, until: $until, since_iso: $since_iso,
              until_excl_iso: $until_excl_iso, now: $now, basis: "session.started_utc, UTC" },
    store: { resolution_chain: "env STORE > env FINOPS_STORE_PATH > operator.toml [paths].operator_instance_finops_store_path > default ${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/finops",
             path_printed: false,
             schema_version: ($meta.schema_version // "(absent)"),
             generator_version: ($meta.generator_version // "(absent)") },
    rolled_up: $rolled_up,
    sessions_in_window: ($win | length),
    grand_total: $grand,
    grand_total_figure: ($grand | fig($grand_src)),
    grand_token_source: $grand_src,
    grand_provenance: src_label($grand_src; $grand_ht; $grand_turns),
    dimensions: $dims,
    tool_calls: $tool_calls,
    stop_reason: $stop_reason,
    tool_use: $tool_use,
    trend: $trend,
    legend: [
      "`~` before a figure = NOT exact (heuristic or mixed provenance). A bare figure is exact.",
      "`worktree` = the session's working-directory BASENAME (store field session.worktree). A filesystem directory name — NOT a PMO project. The FinOps store carries no PMO-project field.",
      "`best-effort` dimensions are partially populated by construction; each renders its own coverage, and the uncovered remainder is an explicit row — never a dimension value named \"unknown\".",
      "subagent records are an attribution drill-down already inside their session's total and are NEVER summed on top."
    ] } as $model

# ===========================================================================
# Renderers. BOTH consume $model.dimensions — the objects emit_dim_table built.
# ===========================================================================
| def md_dim($d):
    [ $d.header,
      "" ]
    + ( if ($d.available | not) then [ ($d.unavailable_reason), "" ]
        else
          ( if $d.dim == "work-item" then
              [ "| work item | tokens | provenance | attribution | sessions |",
                "|---|---:|---|---|---:|" ]
              + [ $d.rows[] | "| " + .key + " | " + .figure + " | " + .provenance + " | " + .tier_note + " | " + (.sessions | tostring) + " |" ]
            elif $d.dim == "worktree" then
              [ "| worktree (session working-directory basename) | tokens | provenance | sessions |",
                "|---|---:|---|---:|" ]
              + [ $d.rows[] | "| " + .key + " | " + .figure + " | " + .provenance + " | " + (.sessions | tostring) + " |" ]
            else
              [ "| " + $d.label + " | tokens | provenance |", "|---|---:|---|" ]
              + [ $d.rows[] | "| " + .key + " | " + .figure + " | " + .provenance + " |" ]
              + ( if $d.uncovered_remainder == null then []
                  else [ "| " + $d.uncovered_remainder.label + " | " + $d.uncovered_remainder.figure
                         + " | " + $d.uncovered_remainder.provenance + " |" ] end )
            end )
          + ( if (($d.rows | length) == 0 and $d.uncovered_remainder == null) then [ "| (no rows) | 0 | — |" ] else [] end )
          + [ "" ]
          + ( if ($d.grade == "best-effort" and $d.uncovered_remainder != null) then
                [ ("Not captured: " + (($d.uncovered_remainder.fraction * 100) | round | tostring)
                   + "% of the tokens in this window carry no " + dim_registry[$d.dim].noun
                   + " attribution. This slice is NOT a complete census."), "" ]
              else [] end )
        end );
  def md_trend($t):
    [ ("## Trend — period: " + $t.period),
      "",
      ("- Buckets: " + $t.bucket_definition),
      ("- Proration: " + $t.proration),
      ("- Direction rule: " + $t.min_periods),
      ("- FLAT band: " + $t.flat_band),
      "" ]
    + [ $t.overall.header, "",
        "| period | tokens | provenance | sessions | notes |", "|---|---:|---|---:|---|" ]
    + [ $t.overall.rows[] | "| " + .period + " | " + .figure + " | " + .provenance + " | " + (.sessions | tostring) + " | " + .note + " |" ]
    + [ "", $t.overall.verdict, "" ]
    + ( [ $t.dimensions[] | . as $d
          | [ $d.header, "",
              "| period | tokens attributed | provenance | coverage | notes |", "|---|---:|---|---:|---|" ]
            + [ $d.rows[] | "| " + .period + " | " + .figure + " | " + .provenance + " | " + .coverage_pct + " | " + .note + " |" ]
            + [ "", $d.verdict ]
            + ( if $d.coverage_drift == null then [] else [ "", $d.coverage_drift ] end )
            + [ "" ] ] | flatten );
  def md_counts($title; $m; $unit):
    [ ("### " + $title), "", ("| " + $unit + " | count |"), "|---|---:|" ]
    + ( if ($m | length) == 0 then [ "| (none in window) | 0 |" ]
        else [ $m | to_entries | sort_by(-.value) | .[] | "| " + .key + " | " + (.value | tostring) + " |" ] end )
    + [ "" ];

  if $as_json == "1" then $model
  else
  ( [ "# Agent FinOps — spend report",
      "",
      ("- Window: " + $model.window.since + " .. " + $model.window.until
        + " (inclusive of both named days; bucketed on session.started_utc, UTC)"),
      ("- Store: resolved via " + $model.store.resolution_chain
        + " — the resolved path VALUE is deliberately not printed (operator home path)."),
      ("- Store metadata: meta.schema_version=" + $model.store.schema_version
        + " · meta.generator_version=" + $model.store.generator_version
        + " · roll-up present: " + ($model.rolled_up | tostring)
        + " (predicate: a `coverage` record exists — never the version string)."),
      ("- Sessions in window: " + ($model.sessions_in_window | tostring)
        + " · total tokens: " + $model.grand_total_figure + " " + $model.grand_provenance),
      ("- Bucketing rule: a session is assigned wholly to the period containing its `started_utc`; there is no proration."),
      "",
      "**LEGEND**" ]
    + [ $model.legend[] | "- " + . ]
    + [ "" ]
    + ( if $model.sessions_in_window == 0 then
          [ "> No sessions fall in this window. An empty result is an answer, not an error.", "" ] else [] end )
    + [ "## Slices", "" ]
    + ( [ $model.dimensions[] | md_dim(.) ] | flatten )
    + md_counts("Client-side tool calls (count, not tokens — distinct from the server-side `tool_use` below)"; $model.tool_calls; "tool")
    + md_counts("Turn stop reasons (count of assistant turns)"; $model.stop_reason; "stop reason")
    + [ "### Server-side tool requests (frozen `tool_use` — never folded into the client-side counts above)", "",
        "| request kind | count |", "|---|---:|",
        ("| web_search_requests | " + ($model.tool_use.web_search_requests | tostring) + " |"),
        ("| web_fetch_requests | " + ($model.tool_use.web_fetch_requests | tostring) + " |"), "" ]
    + ( if $model.trend == null then [] else md_trend($model.trend) end )
  ) | join("\n")
  end
JQEOF

# ── §6 Arg parse + validation ──
BY="all"
PERIOD="week"
WINDOW=""
SINCE=""
UNTIL=""
DO_TREND=0
AS_JSON=0
DO_SELFTEST=0

usage_fail() { printf 'FATAL (exit 2): %s\n' "$1" >&2; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --window)
      [ $# -ge 2 ] || usage_fail "--window requires N (days, optional 'd' suffix)"
      WINDOW="${2%d}"; shift 2; continue ;;
    --since)
      [ $# -ge 2 ] || usage_fail "--since requires YYYY-MM-DD"
      SINCE="$2"; shift 2; continue ;;
    --until)
      [ $# -ge 2 ] || usage_fail "--until requires YYYY-MM-DD"
      UNTIL="$2"; shift 2; continue ;;
    --by)
      [ $# -ge 2 ] || usage_fail "--by requires work-item|worktree|skill|mcp|model|all"
      BY="$2"; shift 2; continue ;;
    --period)
      [ $# -ge 2 ] || usage_fail "--period requires day|week|month"
      PERIOD="$2"; shift 2; continue ;;
    --trend)     DO_TREND=1 ;;
    --json)      AS_JSON=1 ;;
    --self-test) DO_SELFTEST=1 ;;
    -h|--help)
      grep -aE '^#( |$)' "$0" | sed -E 's/^# ?//' | head -55
      exit 0 ;;
    *) usage_fail "unknown argument: $1" ;;
  esac
  shift
done

case "$BY" in
  work-item|worktree|skill|mcp|model|all) : ;;
  project)
    usage_fail "unknown --by value: project (expected work-item|worktree|skill|mcp|model|all). NOTE: the store carries NO PMO-project field; the directory dimension is --by worktree." ;;
  *) usage_fail "unknown --by value: $BY (expected work-item|worktree|skill|mcp|model|all)" ;;
esac
case "$PERIOD" in day|week|month) : ;; *) usage_fail "unknown --period value: $PERIOD (expected day|week|month)" ;; esac

if [ -n "$WINDOW" ] && { [ -n "$SINCE" ] || [ -n "$UNTIL" ]; }; then
  usage_fail "--window is mutually exclusive with --since / --until"
fi
if [ -n "$WINDOW" ]; then
  case "$WINDOW" in
    ''|*[!0-9]*) usage_fail "--window must be a positive integer number of days (got '$WINDOW')" ;;
  esac
  [ "$WINDOW" -ge 1 ] || usage_fail "--window must be >= 1 (got '$WINDOW')"
fi
for d in "$SINCE" "$UNTIL"; do
  if [ -n "$d" ]; then
    printf '%s' "$d" | grep -aqE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' \
      || usage_fail "date must be YYYY-MM-DD (got '$d')"
  fi
done

# ── §7 Main ──
render() {
  local store_dir="$1"
  local store_file="$store_dir/usage.jsonl"
  if [ ! -f "$store_file" ] || [ ! -r "$store_file" ]; then
    printf 'FATAL (exit 3): FinOps store unreadable: %s (run extract-usage.sh first)\n' "$store_file" >&2
    exit 3
  fi
  local now
  now="$(now_date)"
  local since until
  if [ -n "$SINCE" ] || [ -n "$UNTIL" ]; then
    since="${SINCE:-$(date_minus_days "$now" 29)}"
    until="${UNTIL:-$now}"
  else
    until="$now"
    since="$(date_minus_days "$now" "$(( ${WINDOW:-30} - 1 ))")"
  fi
  [ "$since" \> "$until" ] && { printf 'FATAL (exit 2): --since (%s) is after --until (%s)\n' "$since" "$until" >&2; exit 2; }
  local since_iso until_excl_iso
  since_iso="${since}T00:00:00Z"
  until_excl_iso="$(date_plus_1d "$until")T00:00:00Z"

  jq -r -s \
    --arg since "$since" --arg until "$until" \
    --arg since_iso "$since_iso" --arg until_excl_iso "$until_excl_iso" \
    --arg now "$now" --arg by "$BY" --arg period "$PERIOD" \
    --arg as_json "$AS_JSON" --argjson do_trend "$DO_TREND" \
    --arg gen_utc "$(NOW_UTC)" \
    "$JQ_REPORT" "$store_file"
}

# ── §8 Self-test — synthetic fixtures only; no operator store, no network.
#    Every assertion below FAILS CLOSED: a render that aborts, exits non-zero, or
#    produces no output is a FAIL, and every negative assertion is paired with a
#    positive control so an empty search space can never read as "no violations". ──
FAILN=0
ok()   { printf '  PASS: %s\n' "$1"; }
bad()  { printf 'FAIL: %s\n' "$1"; FAILN=1; }

# run_report <outfile> <store-dir> <args...> -> rc; FAILS CLOSED on empty output.
run_report() {
  local out="$1" sd="$2"; shift 2
  local rc
  STORE="$sd" bash "$SELF" "$@" > "$out" 2>"$out.err"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    bad "render exited $rc (want 0) for [$*] — $(head -1 "$out.err" 2>/dev/null)"
    return "$rc"
  fi
  if [ ! -s "$out" ]; then
    bad "render produced EMPTY output for [$*] — an empty render must never read as a pass"
    return 1
  fi
  return 0
}

self_test() {
  [ -d "$FIXTURES_DIR" ] || { echo "FAIL: report fixtures dir missing: $FIXTURES_DIR"; return 1; }
  local fx="$FIXTURES_DIR/usage.jsonl"
  local fx110="$FIXTURES_DIR/usage-v110.jsonl"
  local fxnr="$FIXTURES_DIR/usage-no-rollup.jsonl"
  local oracle="$FIXTURES_DIR/report.expected.json"
  local f
  for f in "$fx" "$fx110" "$fxnr"; do
    [ -f "$f" ] || { echo "FAIL: missing fixture: $f"; return 1; }
  done

  local wd; wd="$(mktemp -d "${TMPDIR:-/tmp}/finops-report-selftest.XXXXXX")"
  mkdir -p "$wd/main" "$wd/v110" "$wd/norollup" "$wd/nocov"
  cp "$fx" "$wd/main/usage.jsonl"
  cp "$fx110" "$wd/v110/usage.jsonl"
  cp "$fxnr" "$wd/norollup/usage.jsonl"
  jq -c 'if .record=="session" then del(.dimension_coverage) else . end' "$fx" > "$wd/nocov/usage.jsonl" 2>/dev/null

  # The fixture window: 5 Monday-start weeks. Clock pinned inside the last one.
  local W1 W5 NOWD
  W1="$(jq -r -s '[.[]|select(.record=="session")|.started_utc]|min|.[0:10]' "$fx")"
  W5="$(jq -r -s '[.[]|select(.record=="session")|.started_utc]|max|.[0:10]' "$fx")"
  NOWD="$W5"
  export FINOPS_REPORT_NOW="$NOWD"

  local MD="$wd/md.txt" JS="$wd/js.json" TR="$wd/trend.txt"
  run_report "$MD" "$wd/main" --by all --since "$W1" --until "$W5" || { rm -rf "$wd"; return 1; }
  run_report "$JS" "$wd/main" --by all --since "$W1" --until "$W5" --json --trend || { rm -rf "$wd"; return 1; }
  run_report "$TR" "$wd/main" --by all --since "$W1" --until "$W5" --trend || { rm -rf "$wd"; return 1; }

  # ── SM-1 PARITY — the six lifted helpers are byte-identical to the sibling's. ──
  local fn a b parity_ok=1 checked=0
  if [ ! -r "$SIBLING" ]; then
    bad "SM-1 PARITY: sibling script unreadable ($SIBLING) — cannot verify, treating as FAIL"
  else
    for fn in preflight_deps generator_version toml_val workspace_root resolve_store guard_store_git_ignored; do
      a="$(sed -n "/^${fn}() {/,/^}/p" "$SELF")"
      b="$(sed -n "/^${fn}() {/,/^}/p" "$SIBLING")"
      if [ -z "$a" ] || [ -z "$b" ]; then
        bad "SM-1 PARITY: could not extract '$fn' from both files (empty extraction is a FAIL, not a skip)"
        parity_ok=0; continue
      fi
      checked=$((checked+1))
      [ "$a" = "$b" ] || { bad "SM-1 PARITY: '$fn' differs from rollup-attribution.sh"; parity_ok=0; }
    done
    if [ "$checked" -ne 6 ]; then
      bad "SM-1 PARITY: extracted $checked of 6 helpers — an under-populated check cannot pass"
    elif [ "$parity_ok" -eq 1 ]; then
      ok "SM-1 PARITY (6/6 inherited helpers byte-identical to rollup-attribution.sh)"
    fi
  fi

  # ── SM-1b GUARD — store inside a repo but not ignored -> exit 4; outside any repo -> proceeds. ──
  local gd rc
  gd="$(mktemp -d "${TMPDIR:-/tmp}/finops-report-guard.XXXXXX")"
  ( cd "$gd" && git init -q . >/dev/null 2>&1 )
  mkdir -p "$gd/store"; cp "$fx" "$gd/store/usage.jsonl"
  ( STORE="$gd/store" bash "$SELF" --window 3650 >/dev/null 2>&1 ); rc=$?
  [ "$rc" -eq 4 ] && ok "SM-1b GUARD: un-ignored in-repo store refused (exit 4)" \
    || bad "SM-1b GUARD: in-repo un-ignored store not refused (exit $rc, want 4)"
  local outside_repo
  outside_repo="$(git -C "$wd" rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -n "$outside_repo" ]; then
    bad "SM-1b GUARD: the self-test temp dir resolved inside git repo $outside_repo — control invalid, cannot assert the pass-through leg"
  else
    ( STORE="$wd/main" bash "$SELF" --window 3650 >/dev/null 2>&1 ); rc=$?
    [ "$rc" -eq 0 ] && ok "SM-1b GUARD: store outside any repo proceeds (exit 0)" \
      || bad "SM-1b GUARD: outside-repo store did not proceed (exit $rc, want 0)"
  fi
  rm -rf "$gd"

  # ── SM-2 CIAC-2 — every best-effort section header carries its coverage clause,
  #    in BOTH markdown and --json. Fails closed: zero best-effort headers = FAIL. ──
  local be_md be_md_cov be_js be_js_cov
  be_md="$(grep -ac '^### .*best-effort' "$MD" || true)"
  be_md_cov="$(grep -ac '^### .*best-effort.* — coverage: ' "$MD" || true)"
  if [ "${be_md:-0}" -lt 2 ]; then
    bad "SM-2 CIAC-2: found ${be_md:-0} best-effort markdown section header(s), expected >=2 — an empty search space is not a pass"
  elif [ "$be_md" = "$be_md_cov" ]; then
    ok "SM-2 CIAC-2 markdown ($be_md/$be_md best-effort headers carry 'coverage:')"
  else
    bad "SM-2 CIAC-2 markdown: $be_md best-effort header(s), only $be_md_cov carry 'coverage:'"
  fi
  be_js="$(jq '[.dimensions[]|select(.grade=="best-effort")]|length' "$JS")"
  be_js_cov="$(jq '[.dimensions[]|select(.grade=="best-effort")|select(.header|test("coverage: "))|select(has("coverage"))]|length' "$JS")"
  if [ "${be_js:-0}" -lt 2 ]; then
    bad "SM-2 CIAC-2 json: found ${be_js:-0} best-effort dimension objects, expected >=2 — empty search space is not a pass"
  elif [ "$be_js" = "$be_js_cov" ]; then
    ok "SM-2 CIAC-2 json ($be_js/$be_js best-effort dimensions carry the coverage clause + key)"
  else
    bad "SM-2 CIAC-2 json: $be_js best-effort dimension(s), only $be_js_cov carry the coverage clause"
  fi
  # Trend parity — every best-effort trend section header carries it too.
  local tr_be tr_be_cov
  tr_be="$(jq '[.trend.dimensions[]|select(.grade=="best-effort")]|length' "$JS")"
  tr_be_cov="$(jq '[.trend.dimensions[]|select(.grade=="best-effort")|select(.header|test("coverage: "))]|length' "$JS")"
  if [ "${tr_be:-0}" -lt 1 ]; then
    bad "SM-2 CIAC-2 trend: no best-effort trend sections rendered — empty search space is not a pass"
  elif [ "$tr_be" = "$tr_be_cov" ]; then
    ok "SM-2 CIAC-2 trend parity ($tr_be/$tr_be best-effort trend headers carry 'coverage:')"
  else
    bad "SM-2 CIAC-2 trend: $tr_be best-effort trend section(s), only $tr_be_cov carry 'coverage:'"
  fi

  # ── SM-2n — coverage field deleted -> explicit 'unknown (coverage field absent', never a number. ──
  local NC="$wd/nocov.txt"
  if run_report "$NC" "$wd/nocov" --by skill --since "$W1" --until "$W5"; then
    if grep -aq 'coverage: unknown (coverage field absent' "$NC"; then
      if grep -aqE '^### .*best-effort.* — coverage: [0-9]' "$NC"; then
        bad "SM-2n: a numeric coverage rendered despite the coverage field being deleted"
      else
        ok "SM-2n: absent coverage renders 'unknown (coverage field absent — treat as 0% verified)', never a number"
      fi
    else
      bad "SM-2n: absent coverage did not render the explicit unknown clause"
    fi
  fi

  # ── SM-3 CIAC-4 — no bare numeral: every token figure is either on a row tagged
  #    [SOURCE: exact message.usage] or carries a leading '~'. Fails closed. ──
  #    Semantic leg (JSON model): EVERY figure in EVERY row set, everywhere.
  local jscan jviol
  jscan="$(jq '[ (.dimensions[]|.rows[]), (.dimensions[]|.uncovered_remainder|select(.!=null)),
                 (.trend.overall.rows[]), (.trend.dimensions[]|.rows[]) ] | length' "$JS")"
  jviol="$(jq '[ (.dimensions[]|.rows[]), (.dimensions[]|.uncovered_remainder|select(.!=null)),
                 (.trend.overall.rows[]), (.trend.dimensions[]|.rows[]) ]
               | map(select((.figure|startswith("~")|not)
                            and (.provenance != "[SOURCE: exact message.usage]")
                            and ((.provenance // "")|startswith("[UNCOVERED")|not)
                            and (.figure != "0"))) | length' "$JS")"
  if [ "${jscan:-0}" -lt 10 ]; then
    bad "SM-3 CIAC-4 (model): only ${jscan:-0} figure(s) in the model — too few to be a meaningful check (fail closed)"
  elif [ "${jviol:-1}" -eq 0 ]; then
    ok "SM-3 CIAC-4 no-bare-numeral, model ($jscan figures across every row set, 0 unprovenanced)"
  else
    bad "SM-3 CIAC-4 (model): $jviol of $jscan figure(s) carry neither '~' nor an exact-source tag"
  fi
  #    Rendered leg (markdown): spend/trend rows only (>=3 columns; the count
  #    tables are 2-column and carry counts, not token figures).
  local scanned=0 violations=0 line cell
  while IFS= read -r line; do
    printf '%s' "$line" | awk -F'|' 'NF>=5{exit 0} {exit 1}' || continue
    cell="$(printf '%s' "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$3); print $3}')"
    case "$cell" in
      ''|*[!0-9,~]*) continue ;;
      *[0-9]*) : ;;
      *) continue ;;
    esac
    scanned=$((scanned+1))
    case "$cell" in
      "~"*) continue ;;
    esac
    printf '%s' "$line" | grep -aq '\[SOURCE: exact message.usage\]' && continue
    printf '%s' "$line" | grep -aq '\[UNCOVERED' && continue
    { [ "$cell" = "0" ] && printf '%s' "$line" | grep -aq '(empty — no sessions'; } && continue
    violations=$((violations+1))
  done < <(grep -a '^| ' "$MD" || true)
  if [ "$scanned" -lt 10 ]; then
    bad "SM-3 CIAC-4 (rendered): only $scanned token figure(s) scanned — too few to be a meaningful check (fail closed)"
  elif [ "$violations" -eq 0 ]; then
    ok "SM-3 CIAC-4 no-bare-numeral, rendered ($scanned markdown figures scanned, 0 unprovenanced)"
  else
    bad "SM-3 CIAC-4 (rendered): $violations of $scanned token figure(s) rendered with neither '~' nor an exact-source tag"
  fi
  grep -aq '\[INFERRED: ceil(words/0.75) fallback\]' "$MD" \
    && ok "SM-3 CIAC-4: a heuristic row renders its [INFERRED] tag (distinguishable from exact)" \
    || bad "SM-3 CIAC-4: no [INFERRED] heuristic row rendered — the fixture must exercise one"
  grep -aq 'tier: pr-resolved — NETWORK, reproducible:false' "$MD" \
    && ok "SM-3 CIAC-4: a pr-resolved row renders its NETWORK / reproducible:false weighting" \
    || bad "SM-3 CIAC-4: no pr-resolved row rendered — the fixture must exercise one"
  grep -aqE '~[0-9]' "$MD" \
    && ok "SM-3 CIAC-4: a not-exact figure carries the '~' marker on the numeral itself" \
    || bad "SM-3 CIAC-4: no '~'-marked figure rendered"

  # ── SM-3b SA-3 — the silent-zero regression. The by-skill slice must render the
  #    fixture's KNOWN non-zero skill tokens, not 0. This is the assertion that
  #    would have caught the {turns, tokens} wrapper mis-read. ──
  local want_skill got_skill
  want_skill="$(jq -r -s --arg s "${W1}T00:00:00Z" '
      [ .[] | select(.record=="session") | select(.started_utc >= $s)
        | (.by_skill // {}) | to_entries[] | select(.key != "unknown")
        | (.value.tokens.input + .value.tokens.output + .value.tokens.cache_creation.total + .value.tokens.cache_read) ]
      | add // 0' "$fx")"
  got_skill="$(jq '[.dimensions[]|select(.dim=="skill")|.rows[].tokens]|add // 0' "$JS")"
  if [ "${want_skill:-0}" -le 0 ]; then
    bad "SM-3b SA-3: the fixture carries no non-zero named by_skill tokens — the control is invalid, the check cannot pass"
  elif [ "$got_skill" = "$want_skill" ] && [ "$got_skill" -gt 0 ]; then
    ok "SM-3b SA-3 silent-zero regression (by-skill slice renders $got_skill tokens, NOT 0 — .tokens reached before summing leaves)"
  else
    bad "SM-3b SA-3 silent-zero: by-skill slice rendered $got_skill, want $want_skill (a 0 here is the {turns,tokens} wrapper mis-read)"
  fi

  # ── SM-3c — the reserved "unknown" key renders as an explicit uncovered
  #    remainder, NEVER as a dimension value. Fails closed on a zero remainder. ──
  local unk_as_row rem_tok
  unk_as_row="$(jq '[.dimensions[]|.rows[]|select(.key=="unknown")]|length' "$JS")"
  rem_tok="$(jq '[.dimensions[]|select(.dim=="skill")|.uncovered_remainder.tokens]|first // 0' "$JS")"
  if [ "${unk_as_row:-1}" -ne 0 ]; then
    bad "SM-3c: the reserved \"unknown\" key rendered as a dimension row ($unk_as_row occurrence(s)) — uncovered spend reported as covered"
  elif [ "${rem_tok:-0}" -le 0 ]; then
    bad "SM-3c: the by-skill uncovered remainder is $rem_tok — the fixture must carry a non-zero \"unknown\" bucket for this check to mean anything"
  elif grep -aq 'uncovered remainder — the source attributed no skill' "$MD" \
       && grep -aq 'NOT a skill named "unknown"' "$MD"; then
    ok "SM-3c: reserved \"unknown\" bucket renders as an explicit uncovered-remainder row ($rem_tok tokens), never as a skill"
  else
    bad "SM-3c: the uncovered-remainder row is not rendered in markdown"
  fi

  # ── SM-4 CIAC-3 — no absolute home path, no project_dir value, in either render.
  #    Paired with a positive control: the fixtures MUST contain the forbidden
  #    strings, or the negative assertion is vacuous. ──
  local ctl1 ctl2 f2
  ctl1="$(grep -ac -- '-Users-synthetic-operator' "$fx" || true)"     # path-mangled project_dir
  ctl2="$(grep -ac '/Users/synthetic-operator' "$fx110" || true)"     # raw absolute cwd (pre-rename)
  local V110="$wd/v110.txt"
  run_report "$V110" "$wd/v110" --by all --since "$W1" --until "$W5"
  if [ "${ctl1:-0}" -lt 1 ] || [ "${ctl2:-0}" -lt 1 ]; then
    bad "SM-4 CIAC-3: control invalid — the fixtures carry no fabricated path values (mangled=$ctl1, absolute=$ctl2), so 'the render contains none' proves nothing"
  else
    local leak=0
    for f2 in "$MD" "$JS" "$V110"; do
      grep -aqE '/Users/|/home/[a-z]' "$f2" && { bad "SM-4 CIAC-3: an absolute home path leaked into $(basename "$f2")"; leak=1; }
      grep -aq -- '-Users-synthetic-operator' "$f2" && { bad "SM-4 CIAC-3: a path-mangled project_dir value leaked into $(basename "$f2")"; leak=1; }
    done
    [ "$leak" -eq 0 ] && ok "SM-4 CIAC-3 (controls present in fixtures; 0 absolute-path / project_dir leaks across md + json + pre-rename render)"
  fi
  # INT-4: the pre-rename store still renders a directory basename, from cwd.
  grep -aq 'legacy-wt' "$V110" \
    && ok "INT-4: pre-rename store (cwd, no worktree) still renders the directory BASENAME, never the path" \
    || bad "INT-4: pre-rename store did not render a worktree basename"

  # ── SM-5 Conservation — Σ rendered work-item rows == Σ session.tokens in window;
  #    subagent records contribute ZERO. ──
  local sess_sum row_sum sub_ct
  sess_sum="$(jq -r -s --arg a "${W1}T00:00:00Z" '
      [ .[] | select(.record=="session") | select(.started_utc >= $a)
        | (.tokens.input + .tokens.output + .tokens.cache_creation.total + .tokens.cache_read) ] | add // 0' "$fx")"
  row_sum="$(jq '[.dimensions[]|select(.dim=="work-item")|.rows[].tokens]|add // 0' "$JS")"
  sub_ct="$(jq -r -s '[.[]|select(.record=="subagent")]|length' "$fx")"
  if [ "${sub_ct:-0}" -lt 1 ]; then
    bad "SM-5: the fixture carries no subagent record — the never-summed leg of the invariant is untested"
  elif [ "$row_sum" = "$sess_sum" ]; then
    ok "SM-5 conservation (Σ work-item rows == Σ session.tokens in window = $sess_sum; $sub_ct subagent record contributed 0)"
  else
    bad "SM-5 conservation: Σ rendered rows ($row_sum) != Σ session.tokens ($sess_sum)"
  fi
  local nru
  nru="$(jq '[.dimensions[]|select(.dim=="work-item")|.rows[]|select(.key=="(not-rolled-up)")]|length' "$JS")"
  [ "${nru:-0}" -eq 1 ] \
    && ok "SM-5b: a session absent from every rollup row lands in an explicit (not-rolled-up) bucket, never dropped" \
    || bad "SM-5b: expected exactly 1 (not-rolled-up) bucket, got ${nru:-0}"

  # ── SM-6 Window — bounds inclusive of the named days; --window selects the tail. ──
  local W2 n_all n_w2
  W2="$(jq -r -s '[.[]|select(.record=="session")|.started_utc[0:10]]|sort|.[0]' "$fx")"
  n_all="$(jq '.sessions_in_window' "$JS")"
  local NARROW="$wd/narrow.json"
  run_report "$NARROW" "$wd/main" --since "$W2" --until "$W2" --json
  n_w2="$(jq '.sessions_in_window' "$NARROW")"
  local want_w2
  want_w2="$(jq -r -s --arg d "$W2" '[.[]|select(.record=="session")|select(.started_utc[0:10]==$d)]|length' "$fx")"
  if [ "$n_w2" = "$want_w2" ] && [ "${want_w2:-0}" -ge 1 ] && [ "$n_all" -gt "$n_w2" ]; then
    ok "SM-6 window (--since D --until D selects exactly the $want_w2 session(s) started on D; the full window holds $n_all)"
  else
    bad "SM-6 window: single-day window selected $n_w2, want $want_w2 (full window $n_all)"
  fi

  # ── SM-7 Trend — empty period explicit, current period partial + excluded, verdict present. ──
  local n_empty n_partial verdict
  n_empty="$(jq '[.trend.overall.rows[]|select(.empty)]|length' "$JS")"
  n_partial="$(jq '[.trend.overall.rows[]|select(.partial)]|length' "$JS")"
  verdict="$(jq -r '.trend.overall.verdict' "$JS")"
  [ "${n_empty:-0}" -ge 1 ] \
    && ok "SM-7 trend: $n_empty empty period(s) rendered as explicit rows (dense bucket set — a gap never reads as continuity)" \
    || bad "SM-7 trend: no empty period rendered — the 5-week fixture has a deliberately empty week"
  [ "${n_partial:-0}" -eq 1 ] \
    && ok "SM-7 trend: the current period is tagged partial and excluded from direction" \
    || bad "SM-7 trend: expected exactly 1 partial period, got ${n_partial:-0}"
  case "$verdict" in
    TREND:\ RISING*|TREND:\ FALLING*|TREND:\ FLAT*)
      ok "SM-7 trend: >=3 complete non-empty periods yield a direction — '$verdict'" ;;
    TREND:\ INSUFFICIENT*)
      bad "SM-7 trend: the 5-week fixture should yield a direction, got '$verdict'" ;;
    *) bad "SM-7 trend: no recognizable verdict line (got '$verdict')" ;;
  esac
  grep -aq '(empty — no sessions in this period)' "$TR" \
    && grep -aq '(partial — period ends' "$TR" \
    && ok "SM-7 trend markdown: empty and partial periods carry their explicit notes" \
    || bad "SM-7 trend markdown: empty/partial notes missing"
  # n=2 leg: a two-period window renders the table but withholds the characterization.
  local TWO="$wd/two.json" v2
  run_report "$TWO" "$wd/main" --since "$W1" --until "$(date_minus_days "$W5" 8)" --json --trend
  v2="$(jq -r '.trend.overall.verdict' "$TWO")"
  case "$v2" in
    TREND:\ INSUFFICIENT*) ok "SM-7b trend: at n=2 the table renders and the direction is withheld — '$v2'" ;;
    *) bad "SM-7b trend: at n=2 expected TREND: INSUFFICIENT, got '$v2'" ;;
  esac

  # ── SM-7c --trend is OPT-IN — the flag must actually gate the section. Both
  #    legs asserted: absent -> no trend anywhere; present -> a trend. (In jq only
  #    null and false are falsy, so a `$do_trend | not` test is false for 0 AND 1
  #    and the trend renders unconditionally; only the negative leg catches that.) ──
  local NOTREND="$wd/notrend.json" NOTREND_MD="$wd/notrend.txt" nt_json nt_md
  run_report "$NOTREND" "$wd/main" --by all --since "$W1" --until "$W5" --json
  run_report "$NOTREND_MD" "$wd/main" --by all --since "$W1" --until "$W5"
  nt_json="$(jq -r '.trend | if . == null then "null" else "present" end' "$NOTREND")"
  nt_md="$(grep -ac '^## Trend' "$NOTREND_MD" || true)"
  if [ "$nt_json" = "null" ] && [ "${nt_md:-1}" -eq 0 ]; then
    if jq -e '.trend != null' "$JS" >/dev/null 2>&1 && grep -aq '^## Trend' "$TR"; then
      ok "SM-7c: --trend gates the trend section (absent -> no trend in either shape; present -> rendered)"
    else
      bad "SM-7c: --trend was passed but no trend section rendered"
    fi
  else
    bad "SM-7c: the trend rendered WITHOUT --trend (json=$nt_json, markdown '## Trend' headings=$nt_md) — the flag is a no-op"
  fi

  # ── SM-8 TC-gate — a rising best-effort signal still yields NO direction. ──
  local sk_first sk_last sk_verdict
  sk_first="$(jq '[.trend.dimensions[]|select(.dim=="skill")|.rows[]|select((.empty|not) and (.partial|not))|.tokens]|first // 0' "$JS")"
  sk_last="$(jq '[.trend.dimensions[]|select(.dim=="skill")|.rows[]|select((.empty|not) and (.partial|not))|.tokens]|last // 0' "$JS")"
  sk_verdict="$(jq -r '[.trend.dimensions[]|select(.dim=="skill")|.verdict]|first // "(none)"' "$JS")"
  if [ "${sk_last:-0}" -le "${sk_first:-0}" ]; then
    bad "SM-8 TC-gate: the fixture's by-skill signal does not rise ($sk_first -> $sk_last) — the check is vacuous without a rising signal"
  else
    case "$sk_verdict" in
      "TREND: NOT CHARACTERIZED"*)
        ok "SM-8 TC-gate: by-skill volume rises $sk_first -> $sk_last across complete periods, and NO direction is emitted" ;;
      *) bad "SM-8 TC-gate: a best-effort dimension emitted '$sk_verdict' — a direction on a partial population" ;;
    esac
  fi
  local drift
  drift="$(jq -r '[.trend.dimensions[]|select(.dim=="skill")|.coverage_drift]|first // "null"' "$JS")"
  case "$drift" in
    COVERAGE-DRIFT:*) ok "SM-8b: per-period coverage spread >10pp raises the explicit COVERAGE-DRIFT note" ;;
    *) bad "SM-8b: the fixture's coverage drifts across periods but no COVERAGE-DRIFT note was emitted (got '$drift')" ;;
  esac

  # ── SM-9 Degradation — a store without the v1.2 dimensions renders an explicit
  #    UNAVAILABLE line (never a silent omission, which would read as "no spend"),
  #    still renders the exact dimensions, and exits 0. ──
  if grep -aq 'UNAVAILABLE: dimension absent from every session in window' "$V110"; then
    if grep -aq '^### work item' "$V110" && grep -aq '^### worktree' "$V110"; then
      ok "SM-9 degradation: v1.1.0 store renders the best-effort dimensions as explicit UNAVAILABLE and still renders the exact ones (exit 0)"
    else
      bad "SM-9 degradation: the exact dimensions stopped rendering on a v1.1.0 store"
    fi
  else
    bad "SM-9 degradation: v1.1.0 store did not render the explicit UNAVAILABLE line"
  fi

  # ── SM-9b Roll-up gate — the predicate is `any(.record=="coverage")`, never the
  #    version string. A store with sessions but no coverage record must say so. ──
  local NR="$wd/norollup.txt" nr_sv
  nr_sv="$(jq -r -s '[.[]|select(.record=="meta")|.schema_version]|first' "$fxnr")"
  if run_report "$NR" "$wd/norollup" --by work-item --window 3650; then
    if grep -aq 'UNAVAILABLE: no roll-up has run over this store' "$NR"; then
      ok "SM-9b roll-up gate: a store declaring schema_version=$nr_sv but carrying no \`coverage\` record renders work-item UNAVAILABLE (gated on the record, not the version)"
    else
      bad "SM-9b roll-up gate: a store with no coverage record did not render the work-item unavailability line"
    fi
  fi

  # ── SM-10 Exit codes — unknown flag -> 2 · bad --by project -> 2 · missing store -> 3. ──
  ( bash "$SELF" --nonsense >/dev/null 2>&1 ); rc=$?
  [ "$rc" -eq 2 ] && ok "SM-10 exit 2 on unknown argument" || bad "SM-10: unknown argument exited $rc (want 2)"
  local projmsg
  projmsg="$( ( STORE="$wd/main" bash "$SELF" --by project >/dev/null ) 2>&1 )"; rc=$?
  if [ "$rc" -eq 2 ] && printf '%s' "$projmsg" | grep -aq 'the store carries NO PMO-project field'; then
    ok "SM-10b: --by project exits 2 naming the store's absence of a PMO-project field"
  else
    bad "SM-10b: --by project exited $rc without the PMO-project disclaimer"
  fi
  ( STORE="$wd/absent-store" bash "$SELF" --window 30 >/dev/null 2>&1 ); rc=$?
  [ "$rc" -eq 3 ] && ok "SM-10c exit 3 on unreadable store" || bad "SM-10c: missing store exited $rc (want 3)"
  local EMPTYW="$wd/empty.txt"
  if run_report "$EMPTYW" "$wd/main" --since 2019-01-01 --until 2019-01-31; then
    grep -aq 'No sessions fall in this window' "$EMPTYW" \
      && ok "SM-10d: an empty window exits 0 and says so — an empty result is an answer, not an error" \
      || bad "SM-10d: an empty window rendered without the explicit empty-window statement"
  fi

  # ── SM-11 Oracle — --json equals the committed oracle modulo generated_utc. ──
  if [ -f "$oracle" ]; then
    if diff <(jq -S 'del(.generated_utc)' "$oracle") <(jq -S 'del(.generated_utc)' "$JS") >/dev/null 2>&1; then
      ok "SM-11 oracle (--json matches report.expected.json modulo generated_utc)"
    else
      bad "SM-11 oracle: --json diverged from report.expected.json"
      diff <(jq -S 'del(.generated_utc)' "$oracle") <(jq -S 'del(.generated_utc)' "$JS") 2>/dev/null | head -20
    fi
  else
    bad "SM-11 oracle: report.expected.json missing — an absent oracle is a FAIL, not a skip"
  fi

  unset FINOPS_REPORT_NOW
  rm -rf "$wd"
  if [ "$FAILN" -eq 0 ]; then echo "finops-usage-extractor report --self-test: PASS"; return 0; fi
  echo "finops-usage-extractor report --self-test: FAIL"; return 1
}

preflight_deps

if [ "$DO_SELFTEST" -eq 1 ]; then
  self_test
  exit $?
fi

STORE_DIR="$(resolve_store)"
guard_store_git_ignored "$STORE_DIR"
render "$STORE_DIR"
exit 0
