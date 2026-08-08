#!/bin/bash
# finops-usage-extractor — estimation module (slice C3).
#
# Produces a token-cost ESTIMATE for a PLANNED work item from historical
# comparables in the operator-local FinOps usage store — naming the comparables
# it used and a confidence level derived from comparable count and dispersion.
# The store schema authority is core/schemas/finops-usage-store-schema.md; the
# attribution vocabulary is core/standards/finops-attribution-convention.md.
#
# The store carries NO work-item size / type / scope field, so every matcher is a
# JOIN OUT of the store. The default join is LOCAL and in-repo: a rollup row keyed
# `milestone:vX.Y` joins release/releases/RELEASE_LOG.md's governed `**Velocity:**`
# field -> (planned points, release class). Issue-grain matching needs GitHub
# labels and is therefore OPT-IN (--resolve-labels), exactly as --resolve-prs is.
#
# READ-ONLY, WRITES NOTHING — reads the store and the in-repo release log and
# prints to stdout, so no artifact exists that could be accidentally committed
# (CIAC-3 data hygiene). The resolved store PATH value is never printed.
#
# Honesty contract (five structural rules, not review conventions):
#   1. HARD FLOOR N_min=3. Below three comparables NO estimate is emitted — not a
#      wide range, not a LOW-confidence figure. At n=2 the median IS the mean, so
#      the outlier-robustness the median was chosen for silently evaporates; at
#      n=1 dispersion is zero, so every confidence signal reads maximally tight.
#      Declining is an ANSWER (exit 0), not an error.
#   2. MEDIAN, never the mean — token spend is right-skewed and one long item
#      moves a mean without widening it. The mean is rendered only as a labelled
#      not-used contrast so the skew is visible.
#   3. CONFIDENCE is a total, ordered function of (n, rMAD), then capped down by
#      evidence quality. It is never a free-text adjective.
#   4. Every figure carries provenance: the marker rides the numeral (`14,200`
#      exact vs `~14,200` not exact) plus a tag column and a per-comparable
#      attribution tier. The estimate line and its basis table are produced by ONE
#      renderer, so an estimate without its basis is unrepresentable.
#   5. `$` fires ONLY on the presence of a `provider` record. That record is
#      emitted only by the OFF-by-default provider-usage-connector.sh, which ships
#      with no live endpoint wired — so volume mode is the only reachable mode
#      today and the header says so. No price table, ever: the rate is derived
#      from the provider record's own cost/token pair or it is not rendered.
#
# The roll-up-has-run predicate is the presence of the run-level `coverage`
# record, NEVER meta.schema_version — from v1.2.0 both phases stamp the same
# version, so a version test passes on an extraction-only store and the comparable
# set silently comes back empty.
#
# Store path resolution (no hardcoded operator path; same as extract-usage.sh):
#   env STORE > env FINOPS_STORE_PATH > operator.toml [paths].operator_instance_finops_store_path
#   > default ${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/finops
# Release-log resolution (in-repo, path-resolved, never an operator root):
#   env FINOPS_RELEASE_LOG > <repo>/release/releases/RELEASE_LOG.md
#   plus every sibling <same-stem>_ARCHIVE-*.md in that file's own directory —
#   the archival sweep relocates aged-out Deployment-Log narrative there and the
#   Velocity basis follows its content rather than shrinking silently.
# Test-only offline override for the OPT-IN label tier:
#   env FINOPS_LABEL_MAP=<path to {"#N":{"points":P,"type":T}} json>
#
# Usage:
#   bash estimate-usage.sh [--class C --points N | --size XS|S|M|L|XL | --like WI[,WI...]]
#                          [--type T] [--tolerance N] [--include-nonreproducible]
#                          [--resolve-labels] [--delta WI] [--json] [--verbose] [--self-test]
#     --class C      release class to match on (e.g. novel|routine|cross-cutting).
#     --points N     planned points for the work item being estimated.
#     --size S       XS|S|M|L|XL — translated through the canonical point scale
#                    (XS=1/S=2/M=4/L=8/XL=16). Mutually exclusive with --points.
#     --like WI,...  EXPLICIT comparables (tier E1); the operator names them.
#                    Mutually exclusive with --class / --points / --size.
#     --type T       optional issue type filter, used by the OPT-IN label tier.
#     --tolerance N  points band half-width (DEFAULT max(2, round(0.5*points))).
#     --include-nonreproducible  admit pr-resolved comparables; caps confidence LOW
#                    and stamps the whole output reproducible:false.
#     --resolve-labels  OPT-IN: resolve issue-grain size/type labels via `gh`
#                    (NETWORK, non-reproducible). Caps confidence LOW.
#     --delta WI     leave-one-out re-derivation: rebuild WI's own comparable set
#                    with WI excluded, then report estimate -> actual, signed
#                    delta, percentage error, basis and confidence. Writes nothing.
#                    REQUIRES WI to carry a rollup row in the store (its measured
#                    actual). A target with no rollup row — the default for any work
#                    item predating the store's coverage window — is REFUSED with
#                    exit 3, never answered with an unrequested forward estimate.
#                    When the point estimate is suppressed (below N_min, or above the
#                    rMAD ceiling) the signed delta and % error are suppressed with
#                    it: either one recovers the withheld figure from `actual` in one
#                    arithmetic step.
#     --json         emit the machine shape instead of markdown.
#     --verbose      additionally list every excluded row with its named reason.
#     --self-test    run built-in assertions against the synthetic estimate
#                    fixtures; no operator-store or network access.
#
# Exit codes: 0 ok · 2 usage error · 3 store unreadable / not rolled up / render
#             aborted / --delta target has no rollup row · 4 store-not-git-ignored
#             (fail-closed public-repo exfil guard) · 5 missing dependency (jq/git).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_MD="$SCRIPT_DIR/../SKILL.md"
FIXTURES_DIR="$SCRIPT_DIR/../test-fixtures/estimate"
SELF="$SCRIPT_DIR/estimate-usage.sh"
SIBLING="$SCRIPT_DIR/rollup-attribution.sh"

# ── VERBATIM from rollup-attribution.sh:53-61 — parity asserted by --self-test SE-1. Do NOT edit here alone. ──
preflight_deps() {
  local missing=""
  command -v jq  >/dev/null 2>&1 || missing="jq"
  command -v git >/dev/null 2>&1 || missing="${missing:+$missing, }git"
  if [ -n "$missing" ]; then
    printf 'FATAL (exit 5): missing dependency: %s — see SKILL.md ## Dependencies\n' "$missing" >&2
    exit 5
  fi
}

# ── VERBATIM from rollup-attribution.sh:64-68 — parity asserted by --self-test SE-1. Do NOT edit here alone. ──
generator_version() {
  local v=""
  [ -r "$SKILL_MD" ] && v="$( { grep -m1 -E '^version:' "$SKILL_MD" 2>/dev/null || true; } | awk '{print $2}')"
  printf '%s' "${v:-unknown}"
}

# ── VERBATIM from rollup-attribution.sh:71-75 — parity asserted by --self-test SE-1. Do NOT edit here alone. ──
toml_val() {
  local key="$1" toml="${HOME}/.config/pmo-platform/operator.toml"
  [ -r "$toml" ] || return 0
  { grep -m1 -E "^${key}" "$toml" 2>/dev/null || true; } | awk -F= '{gsub(/[" ]/,"",$2); print $2}'
}

# ── VERBATIM from rollup-attribution.sh:77-81 — parity asserted by --self-test SE-1. Do NOT edit here alone. ──
workspace_root() {
  local wr="${CLAUDE_WORKSPACE_ROOT:-}"
  [ -z "$wr" ] && wr="$(toml_val claude_workspace_root)"
  printf '%s' "${wr:-${HOME}/Claude}"
}

# ── VERBATIM from rollup-attribution.sh:84-89 — parity asserted by --self-test SE-1. Do NOT edit here alone. ──
resolve_store() {
  local store="${STORE:-${FINOPS_STORE_PATH:-}}"
  [ -z "$store" ] && store="$(toml_val operator_instance_finops_store_path)"
  store="${store:-$(workspace_root)/personal/pmo-instance/finops}"
  printf '%s' "$store"
}

# ── VERBATIM from rollup-attribution.sh:113-132 — parity asserted by --self-test SE-1. Do NOT edit here alone. ──
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

# ── Release-log (the LOCAL size/class bridge) resolution. Same env → default
#    cascade shape as resolve_hub_state_dir / resolve_event_log; the in-repo
#    default is resolved RELATIVE to this script, never to an operator root. ──
resolve_release_log() {
  local f="${FINOPS_RELEASE_LOG:-}"
  [ -z "$f" ] && f="$SCRIPT_DIR/../../../../release/releases/RELEASE_LOG.md"
  printf '%s' "$f"
}

# ── Canonical point scale XS=1/S=2/M=4/L=8/XL=16 — DEFINED at
#    release/references/standards/bundle-composition-doctrine.md § 3 Step 5 and
#    implemented at release/tools/compute-release-velocity.sh:96-104. Reused
#    verbatim (including the exit-2 on an out-of-set value), NOT redefined here:
#    an unrecognized size is a source-integrity violation, never coerced to a
#    nearest bucket. ──
size_to_points() {
  case "$1" in
    XS) printf '1'  ;;
    S)  printf '2'  ;;
    M)  printf '4'  ;;
    L)  printf '8'  ;;
    XL) printf '16' ;;
    *)  printf 'FATAL (exit 2): unrecognized size label: %s (expected XS|S|M|L|XL). Source-integrity violation — not coerced to a nearest bucket.\n' "$1" >&2
        exit 2 ;;
  esac
}

# ── The single SA-8 accessor: RELEASE_LOG.md -> {version: {points, class}}.
#    Reads the `#### Deployment Log <version>` heading, then the FIRST
#    `**Velocity:**` line beneath it, and requires BOTH `planned <N> pts` AND
#    `class <release-class>` to parse. A row that is N/A, narrative, or otherwise
#    unparsable yields NO entry — the caller excludes it with reason `unkeyable`.
#    It is NEVER defaulted to zero: a defaulted point count would silently admit
#    an unsized release as a comparable. One function, one grammar coupling. ──
#    THE BASIS IS THE LEDGER PLUS ITS ARCHIVE SEGMENTS. Deployment-Log narrative
#    older than the release log's hot window is relocated by
#    release/tools/sweep-release-corpus.py into sibling
#    RELEASE_LOG_ARCHIVE-<family>.md files, which keep the same `#### Deployment
#    Log <version>` heading and the same field lines. A `**Velocity:**` row is
#    read for ANY historical release, not just the newest, so reading the hot
#    file alone would silently shrink this accessor's basis population every
#    time the archival chore runs — and it would shrink SILENTLY, because an
#    unresolvable version is excluded as `unkeyable` rather than raising. The
#    glob is resolved against the ledger's OWN directory, so a fixture ledger
#    picks up only its own siblings and never the live corpus.
release_log_velocity_map() {
  local log="$1"
  if [ ! -r "$log" ]; then printf '{}'; return 0; fi
  local -a sources=("$log")
  local seg
  for seg in "$(dirname "$log")"/"$(basename "$log" .md)"_ARCHIVE-*.md; do
    [ -r "$seg" ] && sources+=("$seg")
  done
  awk '
    FNR == 1 { ver=""; have=0 }
    /^#### Deployment Log / { ver=$4; have=0; next }
    (ver != "") && (have == 0) && /^\*\*Velocity:\*\*/ {
      have=1; line=$0; pts=""; cls="";
      if (match(line, /planned [0-9]+ pts/)) { s=substr(line, RSTART, RLENGTH); gsub(/[^0-9]/, "", s); pts=s }
      if (match(line, /class [a-z][a-z-]*/))  { cls=substr(line, RSTART+6, RLENGTH-6) }
      if (pts != "" && cls != "") printf "%s\t%s\t%s\n", ver, pts, cls
    }
  ' "${sources[@]}" \
  | jq -R -s 'split("\n") | map(select(length > 0) | split("\t"))
              | map({key: .[0], value: {points: (.[1] | tonumber), class: .[2]}})
              | from_entries'
}

# ── §5 The estimation jq program. Input: the slurped store. Output: markdown
#    (default) or the machine model (--json). BOTH surfaces route through
#    `basis_rows` and `confidence`, so there is exactly ONE enforcement point for
#    the "every estimate names its basis AND its confidence" rule. ──
read -r -d '' JQ_ESTIMATE <<'JQEOF' || true
# ---------------------------------------------------------------------------
# Numeric helpers. `commafy` is string-recursive so it needs no locale support.
# ---------------------------------------------------------------------------
def absn: if . < 0 then (0 - .) else . end;
def median: sort | if length == 0 then null
            elif (length % 2) == 1 then .[((length - 1) / 2)]
            else ((.[(length / 2) - 1] + .[(length / 2)]) / 2) end;
def madof($m): if $m == null then null else (map((. - $m) | absn) | median) end;
def commafy:
  def go: if (length) <= 3 then . else ((.[0:length-3] | go) + "," + .[length-3:]) end;
  (floor | tostring) | go;
def r4: ((. * 10000) | round) / 10000;
def pct1: ((. * 1000) | round) / 10;

# ---------------------------------------------------------------------------
# Provenance vocabulary — adopted VERBATIM from the sibling scripts so the four
# scripts of this skill present provenance identically.
# ---------------------------------------------------------------------------
def fig($src): commafy | if $src == "exact" then . else "~" + . end;
def tier_label($t):
  if   $t == "branch-milestone"  then "deterministic, local"
  elif $t == "hub-state-lineage" then "deterministic join, local"
  elif $t == "issue-event-keyed" then "best-effort, fuzzy key"
  elif $t == "pr-resolved"       then "NETWORK, reproducible:false"
  else $t end;
def src_label($s; $nheur; $ntot):
  if   $s == "exact"     then "[SOURCE: exact message.usage]"
  elif $s == "heuristic" then "[INFERRED: ceil(words/0.75) fallback]"
  else "[MIXED: \($nheur) of \($ntot) comparables carry heuristic turns]" end;
# The estimate's own token_source folds over its comparables using the roll-up's
# existing rule — reused verbatim from rollup-attribution.sh:344-345, not re-derived.
def fold_token_source: (map(.token_source) | unique) as $ts
                       | if ($ts | length) == 1 then $ts[0] else "mixed" end;
def best_effort_fraction:
  (map(.tokens) | add // 0) as $tot
  | if $tot == 0 then 0
    else ((map(select(.tier == "issue-event-keyed" or .tier == "pr-resolved") | .tokens) | add // 0) / $tot) end;

# ---------------------------------------------------------------------------
# Confidence — a TOTAL, ordered, first-match-wins function of (n, rMAD), then
# capped DOWN by evidence quality. Caps never raise. Thresholds by provenance:
#   N_min = 3            [SOURCE: core/schemas/gate-evaluation-spec.md:95-96]
#   n >= 2*N_min = 6     derived from the floor, not a second invented count
#   rMAD 0.25 / 0.50     [SOURCE: finops-attribution-convention.md:75-77 —
#                        this skill's own coverage.health OK/WARN/FAIL bands]
#   rMAD 0.75            [RECOMMENDED] provisional representability boundary.
#                        NOTE the design's proposed 1.00 edge is UNREACHABLE: for
#                        non-negative data MAD <= median always, so rMAD <= 1.00
#                        is a mathematical ceiling and a >1.00 branch could never
#                        fire (nor be tested). 0.75 sits between the convention's
#                        FAIL edge and that ceiling. [CALIBRATE-AFTER-3]
# ---------------------------------------------------------------------------
def rank($c): if $c == "HIGH" then 3 elif $c == "MEDIUM" then 2 else 1 end;
def unrank($n): if $n >= 3 then "HIGH" elif $n == 2 then "MEDIUM" else "LOW" end;
def cap_to($a; $b): unrank([rank($a), rank($b)] | min);
def confidence_ladder($n; $rm):
  if   $n < $nmin                            then {rule: "R1", label: "DECLINE",  point: false}
  elif ($rm != null and $rm > 0.75)          then {rule: "R2", label: "LOW",      point: false}
  elif ($rm != null and $rm <= 0.25 and $n >= ($nmin * 2))
                                             then {rule: "R3", label: "HIGH",     point: true}
  elif ($rm != null and $rm <= 0.50)         then {rule: "R4", label: "MEDIUM",   point: true}
  else                                            {rule: "R5", label: "LOW",      point: true} end;

# ---------------------------------------------------------------------------
# Eligibility P1-P7. Predicates are evaluated in order; the FIRST failure records
# a named exclusion reason, so a thin population is diagnosable (--verbose) rather
# than mysterious. A row is NEVER silently pooled.
# ---------------------------------------------------------------------------
def four_leaf: (.tokens.input + .tokens.output + .tokens.cache_creation.total + .tokens.cache_read);

. as $all
| ($all | any(.record == "coverage")) as $rolled_up
| ($all | map(select(.record == "meta")) | .[0] // {}) as $meta
| ($all | map(select(.record == "provider"))) as $providers
| ($all | map(select(.record == "rollup"))) as $rollups

# ---- unit detection (AC-2). Presence-based, expressed in exactly one place. ----
| ($providers | length > 0) as $has_provider
| (if $has_provider then ($providers[0]) else null end) as $prov
# provider is RESERVED with zero declared fields (schema:207-209) and its schema is
# not this script's file, so the read is a defensive multi-probe behind ONE named
# seam. A wrong guess degrades to the named unreadable notice, never to a wrong $.
| (if $prov == null then null else ($prov.cost_usd // $prov.cost // $prov.amount_usd // null) end) as $prov_cost
| (if $prov == null then null
   else ($prov.tokens_total
         // (if ($prov.tokens | type) == "object"
             then (($prov.tokens.input // 0) + ($prov.tokens.output // 0)
                   + ($prov.tokens.cache_creation.total // 0) + ($prov.tokens.cache_read // 0))
             elif ($prov.tokens | type) == "number" then $prov.tokens
             else null end)
         // null) end) as $prov_tokens
| (($prov_cost != null) and ($prov_tokens != null) and ($prov_tokens > 0)) as $rate_readable
| (if $rate_readable then ($prov_cost / $prov_tokens) else null end) as $usd_rate
| (if ($has_provider | not) then "volume"
   elif $rate_readable then "usd"
   else "volume-provider-unreadable" end) as $unit_mode

# ---- candidate enrichment + exclusion reasons ----
| ($rollups | map(
    . as $r
    | ($r | four_leaf) as $tot
    | (if $r.work_item_kind == "milestone" then ($r.work_item | ltrimstr("milestone:")) else null end) as $ver
    | (if $ver == null then null else ($vel[$ver] // null) end) as $mkey
    | (if $r.work_item_kind == "issue" then ($lbl[$r.work_item] // null) else null end) as $ikey
    | { work_item: $r.work_item, kind: $r.work_item_kind, tier: $r.attribution_tier,
        reproducible: $r.reproducible, tokens: $tot, token_source: $r.token_source,
        session_count: ($r.session_count // 0), mkey: $mkey, ikey: $ikey,
        excl:
          ( if   ($r.work_item_kind != "milestone" and $r.work_item_kind != "issue")
                                                            then "P2 not-a-work-item (\($r.work_item_kind) is an honesty bucket)"
            elif ($r.attribution_tier == "unattributed")     then "P3 unattributed tier"
            elif (($r.reproducible != true) and ($incl_nonrepro == 0))
                                                            then "P4 non-reproducible (admit with --include-nonreproducible)"
            elif (($r.session_count // 0) < 1)               then "P5 no contributing sessions"
            elif ($tot <= 0)                                 then "P5 zero-token row (bookkeeping artifact, not evidence)"
            elif ($target_wi != "" and $r.work_item == $target_wi)
                                                            then "P6 leave-one-out (an item never estimates from itself)"
            else null end ) } ) ) as $cands

# ---- the matching ladder: ordered, first-match-wins, LOCAL by default ----
| ($like | map(select(length > 0))) as $likes
| ($cands | map(select(.excl == null))) as $ok
| ($ok | map(select(.kind == "milestone" and .mkey != null))) as $keyed_ms
| ($ok | map(select(.kind == "milestone" and .mkey == null))
       | map(. + {excl: "P7 unkeyable (no parsable RELEASE_LOG **Velocity:** row for this version)"})) as $unkeyable_ms

| ( if ($likes | length) > 0
    then { tier: "E1", tier_name: "explicit (--like)", local: true,
           key: "operator-declared comparables",
           set: ($ok | map(select(.work_item as $w | $likes | index($w)))),
           basis_kind: "tokens" }
    else
      ( $keyed_ms
        | map(select(.mkey.class == $tclass and (((.mkey.points - $tpoints) | absn) <= $tol))) ) as $e2
      | if ($e2 | length) >= $nmin
        then { tier: "E2", tier_name: "class + points", local: true,
               key: "(class=\($tclass), points \($tpoints - $tol)-\($tpoints + $tol), tolerance ±\($tol))",
               set: $e2, basis_kind: "tokens" }
        else
          ( $keyed_ms | map(select(.mkey.points > 0)) | map(. + {rate: (.tokens / .mkey.points)}) ) as $e3
          | if ($e3 | length) >= $nmin
            then { tier: "E3", tier_name: "pooled tokens-per-point rate", local: true,
                   key: "pooled rate across ALL keyable milestone rows regardless of class, x \($tpoints) pts",
                   set: $e3, basis_kind: "rate", fell_from: ($e2 | length) }
            else
              ( $ok | map(select(.kind == "issue" and .ikey != null))
                    | map(select((((.ikey.points - $tpoints) | absn) <= $tol)
                                 and (($ttype == "") or (.ikey.type == $ttype)))) ) as $elbl
              | if ($resolve_labels == 1) and (($elbl | length) >= $nmin)
                then { tier: "E-LBL", tier_name: "issue-grain labels (OPT-IN, NETWORK)", local: false,
                       key: "(type=\(if $ttype == "" then "any" else $ttype end), points \($tpoints - $tol)-\($tpoints + $tol))",
                       set: $elbl, basis_kind: "tokens" }
                else { tier: "E4", tier_name: "DECLINE (terminal)", local: true,
                       key: "(class=\($tclass), points \($tpoints - $tol)-\($tpoints + $tol))",
                       set: (if ($e2 | length) >= ($e3 | length) then $e2 else $e3 end),
                       basis_kind: "tokens", attempted: {E2: ($e2 | length), E3: ($e3 | length), "E-LBL": ($elbl | length)} }
                end
            end
        end
    end ) as $L

| ($L.set) as $set
| ($set | length) as $n
| (if $L.basis_kind == "rate" then ($set | map(.rate)) else ($set | map(.tokens)) end) as $values
| ($values | median) as $med
| ($values | madof($med)) as $mad
| (if ($med == null or $med == 0) then null else (($mad / $med)) end) as $rm
| (if $L.basis_kind == "rate" then (if $med == null then null else (($med * $tpoints) | floor) end)
   else (if $med == null then null else ($med | floor) end) end) as $estimate
| (if $n == 0 then null else (($set | map(.tokens) | add) / $n) end) as $mean_tokens
| ($set | map(.tokens) | min) as $vmin
| ($set | map(.tokens) | max) as $vmax
| (if $n == 0 then "exact" else ($set | fold_token_source) end) as $tsrc
| ($set | map(select(.token_source != "exact")) | length) as $nheur
| ($set | best_effort_fraction) as $bef
| ($set | any(.reproducible != true)) as $any_nonrepro
| (($set | all(.reproducible == true)) and ($L.tier != "E-LBL")) as $reproducible

# ---- confidence: ladder, then caps (caps only ever move DOWN) ----
| confidence_ladder($n; $rm) as $base
#    NOTE (precedence, load-bearing): the C-TIER element MUST stay parenthesised.
#    `|` binds looser than `,`, so an unparenthesised `A | select(...) | {...}, B, C`
#    parses as `A | select(...) | ({...}, B, C)` — and when the C-TIER select yields
#    nothing the WHOLE array collapses to empty, silently dropping every other cap
#    while still rendering as "no caps applied". Asserted by SE-15.
| ( [ ( (if $bef > 0.50 then "LOW" elif $bef > 0.25 then "MEDIUM" else null end)
        | select(. != null) | {cap: "C-TIER", to: .} ),
      (if $any_nonrepro then {cap: "C-NONREPRO", to: "LOW"} else empty end),
      (if $L.tier == "E3" then {cap: "C-RATE", to: "MEDIUM"} else empty end),
      (if $L.tier == "E-LBL" then {cap: "C-NET", to: "LOW"} else empty end) ] ) as $caps
| ( if $base.label == "DECLINE" then $base.label
    else ($caps | map(.to) | reduce .[] as $c ($base.label; cap_to(.; $c))) end ) as $conf_label
| ($base.point and ($base.label != "DECLINE")) as $show_point
| (if $show_point then null
   elif $base.label == "DECLINE" then "INSUFFICIENT-COMPARABLES"
   else "RANGE-ONLY" end) as $suppression

# ---- basis rows: the SINGLE construction point for AC-1's basis ----
| ( $set | sort_by(.tokens) | map(
     . as $row
   | { work_item: .work_item, tokens: .tokens, figure: ($row.tokens | fig($row.token_source)),
       attribution_tier: .tier, tier_label: tier_label($row.tier),
       token_source: .token_source,
       provenance: (src_label(.token_source; $nheur; $n)),
       key: (if .mkey != null then "\(.mkey.points) pts / \(.mkey.class)"
             elif .ikey != null then "\(.ikey.points) pts / \(.ikey.type)"
             else "operator-declared" end),
       rate: (.rate // null),
       is_median: false } ) ) as $basis_rows

| ($cands | map(select(.excl != null)) + $unkeyable_ms
   | map({work_item: .work_item, reason: .excl})) as $excluded

# ---- delta (leave-one-out) ----
| (if $target_wi == "" then null
   else ($rollups | map(select(.work_item == $target_wi)) | .[0] // null) end) as $target_row
| (if $target_row == null then null else ($target_row | four_leaf) end) as $actual
| (if ($actual == null or $estimate == null) then null else ($estimate - $actual) end) as $delta_tokens
# NOTE: `pct1` already converts a FRACTION to a 1-dp percentage (x1000, round, /10).
# Multiplying by 100 first double-scales it — a -87.2% error renders as -8722.2%,
# which is arithmetically wrong while still looking like a plausible percentage.
# Asserted against an independently-computed value by SE-11.
| (if ($actual == null or $estimate == null or $actual == 0) then null
   else ((($estimate - $actual) / $actual) | pct1) end) as $pct_error

# ---- USD (only ever rendered when a provider record supplies its own rate) ----
| (if ($unit_mode == "usd" and $estimate != null) then (($estimate * $usd_rate) * 100 | round) / 100 else null end) as $usd_est

# ---------------------------------------------------------------------------
# Renderers. BOTH route through $basis_rows + $conf_label, so an estimate without
# its basis and its confidence is unrepresentable in either output shape.
# ---------------------------------------------------------------------------
| { schema_version: ($meta.schema_version // "unknown"),
    store_generator_version: ($meta.generator_version // "unknown"),
    generator_version: $gen_ver,
    estimated_utc: $gen_utc,
    mode: (if $target_wi == "" then "estimate" else "delta" end),
    rolled_up: $rolled_up,
    unit_mode: $unit_mode,
    usd_rate: $usd_rate,
    matching: { tier: $L.tier, tier_name: $L.tier_name, local: $L.local, key: $L.key,
                target: { class: $tclass, points: $tpoints, type: (if $ttype == "" then null else $ttype end),
                          tolerance: $tol, work_item: (if $target_wi == "" then null else $target_wi end) },
                attempted: ($L.attempted // null) },
    n_comparables: $n,
    n_min: $nmin,
    estimate_tokens: (if $show_point then $estimate else null end),
    estimate_usd: (if $show_point then $usd_est else null end),
    range: (if $n > 0 then {min: $vmin, max: $vmax} else null end),
    mean_tokens_not_used: (if $mean_tokens == null then null else ($mean_tokens | floor) end),
    dispersion: {mad: (if $mad == null then null else ($mad | r4) end), rmad: (if $rm == null then null else ($rm | r4) end)},
    confidence: $conf_label,
    confidence_rule: $base.rule,
    confidence_caps: $caps,
    suppression: $suppression,
    token_source: $tsrc,
    best_effort_token_fraction: ($bef | r4),
    reproducible: $reproducible,
    basis: $basis_rows,
    excluded: (if $verbose == 1 then $excluded else null end),
    excluded_count: ($excluded | length),
    actual_tokens: $actual,
    # A DERIVED field of a suppressed estimate is the estimate. `actual + delta`
    # recovers the withheld point figure in one subtraction, and `actual * (1 +
    # pct_error)` recovers it in one multiplication — so rendering either one beside
    # a "(suppressed)" estimate discloses exactly the figure the N_min floor (or the
    # rMAD ceiling) declined to emit. Both are suppressed with the point figure, on
    # the SAME $show_point predicate, so they cannot come apart from it.
    delta_tokens: (if $show_point then $delta_tokens else null end),
    pct_error:    (if $show_point then $pct_error    else null end),
    delta_suppression:
      (if ($target_wi != "" and ($show_point | not) and $actual != null and $estimate != null)
       then ("derived fields withheld with the point estimate (suppression: " + $suppression
             + ") — signed delta and % error each recover the suppressed figure from `actual` "
             + "in one arithmetic step")
       else null end),
    leave_one_out: ($target_wi != "") } as $M

| if $as_json == "1" then $M
  else
    ( [ "# FinOps estimate — \(if $M.mode == "delta" then "leave-one-out delta for \($target_wi)" else "planned work item" end)",
        "",
        "Unit: " + (if $unit_mode == "volume" then "token volume (flat-rate; no metered-API source in store)."
                    elif $unit_mode == "usd" then "token volume + derived $ (a provider record supplies cost/tokens; rate DERIVED from the store's own record, never a price table)."
                    else "token volume. PROVIDER-PRESENT-BUT-UNREADABLE: a provider record exists but carries no readable cost/token pair; rendering token volume only." end),
        "Roll-up gate: coverage record PRESENT (predicate `any(.record==\"coverage\")` — never meta.schema_version).",
        "Store resolution chain: env STORE > env FINOPS_STORE_PATH > operator.toml [paths].operator_instance_finops_store_path > ${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/finops  (the resolved path VALUE is deliberately not printed)",
        "Release-log resolution chain: env FINOPS_RELEASE_LOG > <repo>/release/releases/RELEASE_LOG.md",
        "Store provenance: schema_version=\($M.schema_version), store generator_version=\($M.store_generator_version); estimator generator_version=\($M.generator_version).",
        "Matching: tier \($L.tier) — \($L.tier_name) \(if $L.local then "[LOCAL, reproducible]" else "[NETWORK, non-reproducible]" end); key \($L.key).",
        "" ]
      + ( if $suppression == "INSUFFICIENT-COMPARABLES"
          then [ "**INSUFFICIENT-COMPARABLES: n=\($n) (\($nmin) required). NO ESTIMATE EMITTED.**",
                 "",
                 "Basis attempted: \($L.key) at tier \($L.tier).",
                 "Below the N_min floor the median degenerates toward the mean and dispersion reads as zero, so every confidence signal would report maximum certainty precisely where there is least. Declining is the correct output, not a failure (exit 0).",
                 (if ($L.attempted != null) then "Tier population: E2=\($L.attempted.E2) · E3=\($L.attempted.E3) · E-LBL=\($L.attempted["E-LBL"]) — none reached \($nmin)." else null end),
                 "\($M.excluded_count) row(s) excluded by the eligibility predicates (run --verbose to list each with its named reason)." ]
          elif $suppression == "RANGE-ONLY"
          then [ "**Point estimate SUPPRESSED — the comparables do not agree closely enough to support a point figure.**",
                 "Observed range: \($vmin | fig($tsrc)) – \($vmax | fig($tsrc)) tokens   [confidence: \($conf_label)]   (rule \($base.rule): rMAD \($M.dispersion.rmad) > 0.75)" ]
          else [ "Estimate: \($estimate | fig($tsrc)) tokens   [confidence: \($conf_label)]   \(if $tsrc == "exact" then "" else "[~ = not exact]" end)" ]
               + (if $usd_est != null then ["Derived cost: $\($usd_est)   (rate $\($usd_rate) / token, DERIVED from the store's own provider record; inherits the estimate's confidence)"] else [] end)
          end )
      + [ "",
          (if $suppression == "INSUFFICIENT-COMPARABLES"
           then "Sub-threshold rows found (n=\($n)) — listed for diagnosis, NOT a basis; no median was computed and no estimate was emitted:"
           else "Basis: median of \($n) comparable(s) matched on \($L.key), tier \($L.tier)." end),
          (if $L.basis_kind == "rate"
           then "| work item | tokens | tokens/pt | key | attribution tier | token source |"
           else "| work item | tokens | key | attribution tier | token source |" end),
          (if $L.basis_kind == "rate"
           then "|---|---|---|---|---|---|"
           else "|---|---|---|---|---|" end) ]
      + ( $basis_rows | map(
            if $L.basis_kind == "rate"
            then "| \(.work_item) | \(.figure) | \((.rate // 0) | floor | commafy) | \(.key) | \(.attribution_tier) — \(.tier_label) | \(.provenance) |"
            else "| \(.work_item) | \(.figure) | \(.key) | \(.attribution_tier) — \(.tier_label) | \(.provenance) |" end ) )
      + [ "",
          (if $suppression == "INSUFFICIENT-COMPARABLES" then null
           else "Dispersion: MAD \(if $mad == null then "n/a" else ($mad | floor | commafy) end) (rMAD \(if $rm == null then "n/a" else ($rm | r4) end)).  Best-effort token fraction: \($M.best_effort_token_fraction).  Reproducible: \($reproducible)." end),
          (if $suppression == "INSUFFICIENT-COMPARABLES" then null
           else "Comparison (NOT used): arithmetic mean = \(if $mean_tokens == null then "n/a" else ($mean_tokens | floor | commafy) end) tokens"
            + (if ($mean_tokens != null and $med != null and $med > 0 and $L.basis_kind != "rate")
               then " — \((($mean_tokens / $med) * 100 | round) / 100)x the median. Median is used because token spend is right-skewed; one long item moves a mean without widening it [SOURCE: dora-telemetry.md:45]."
               else "." end) end),
          (if $suppression == "INSUFFICIENT-COMPARABLES"
           then "Confidence: n/a — DECLINED at rule \($base.rule) (n=\($n) < N_min=\($nmin)). A confidence label is not emitted for a figure that does not exist."
           else "Confidence: \($conf_label) via rule \($base.rule) on (n=\($n), rMAD=\(if $rm == null then "n/a" else ($rm | r4) end))"
            + (if ($caps | length) > 0 then ", capped by \($caps | map("\(.cap)->\(.to)") | join(", "))." else " (no caps applied)." end) end),
          "Provenance: token_source=\($tsrc)" + (if $tsrc == "exact" then " — all comparables exact; figures rendered bare with an exact-source tag." else " (\($nheur) of \($n) comparables carry non-exact turns) — figures marked ~." end),
          "Thresholds: N_min=\($nmin) [SOURCE gate-evaluation-spec.md:95-96]; rMAD bands 0.25/0.50 [SOURCE finops-attribution-convention.md:75-77]; 0.75 [RECOMMENDED].",
          "Grounding honesty: no usage distribution exists to calibrate these bands against — data hygiene forbids reading the operator-local store from the public repo, and no committed store exists. The rMAD band edges are proposed values, not measurements. [CALIBRATE-AFTER-3]",
          "\($M.excluded_count) row(s) excluded by the eligibility predicates\(if $verbose == 1 then ":" else " (run --verbose to list each with its named reason)." end)" ]
      + (if $verbose == 1 then ($excluded | map("  - \(.work_item): \(.reason)")) else [] end)
      + ( if $M.mode == "delta"
          then [ "",
                 "## Leave-one-out delta — \($target_wi)",
                 "",
                 # Never the word FATAL on STDOUT: a fatal condition is a stderr +
                 # non-zero-exit event, and the CLI refuses this case (P6b) before
                 # anything renders. Reaching this line means the jq program was
                 # invoked directly, so it states the absence without claiming a
                 # back-test ran.
                 (if $actual == null then "NO DELTA COMPUTED — \($target_wi) has no rollup row in this store, so no measured actual exists to compare against. Nothing below was back-tested."
                  else "| estimate | actual | signed delta | % error |" end),
                 (if $actual == null then null else "|---|---|---|---|" end),
                 (if ($actual == null or $estimate == null) then null
                  elif ($show_point | not)
                  then "| (suppressed) | \($actual | commafy) | (suppressed) | (suppressed) |"
                  else "| \($estimate | commafy) | \($actual | commafy) | \(if $delta_tokens < 0 then "-" else "+" end)\(($delta_tokens | absn) | commafy) | \(if $pct_error > 0 then "+" else "" end)\($pct_error)% |" end),
                 (if ($actual != null and $estimate != null and ($show_point | not))
                  then "\n**Signed delta and % error are SUPPRESSED with the point figure, not merely blanked.** Either one recovers the withheld estimate from `actual` in a single arithmetic step (estimate = actual + delta; estimate = actual x (1 + % error)). A figure the estimator explicitly declined to emit must not be recoverable by arithmetic from the same output. Suppression class: \($suppression) (rule \($base.rule), n=\($n), N_min=\($nmin))."
                  else null end),
                 "",
                 # Gated on $actual: with no measured actual nothing was back-tested,
                 # and this sentence would assert a comparison that did not happen.
                 (if $actual == null then null
                  else "The comparable set above was rebuilt for \($target_wi)'s OWN matching key with \($target_wi) excluded (P6), then the identical estimator was run over it — so this is the estimate a planner would have seen BEFORE the work started. Basis and confidence as stated above (\($conf_label), rule \($base.rule)). Zero writes, zero new records, zero schema surface." end) ]
          else [] end )
      | map(select(. != null)) | join("\n") )
  end
JQEOF

# ── §6 Arg parse + validation ──
TCLASS=""
TPOINTS=""
TSIZE=""
TTYPE=""
TOL=""
LIKE=""
DELTA_WI=""
INCL_NONREPRO=0
RESOLVE_LABELS=0
AS_JSON=0
VERBOSE=0
DO_SELFTEST=0
NMIN=3

usage_fail() { printf 'FATAL (exit 2): %s\n' "$1" >&2; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --class)
      [ $# -ge 2 ] || usage_fail "--class requires a release-class value"
      TCLASS="$2"; shift 2; continue ;;
    --points)
      [ $# -ge 2 ] || usage_fail "--points requires a positive integer"
      TPOINTS="$2"; shift 2; continue ;;
    --size)
      [ $# -ge 2 ] || usage_fail "--size requires XS|S|M|L|XL"
      TSIZE="$2"; shift 2; continue ;;
    --type)
      [ $# -ge 2 ] || usage_fail "--type requires a work-item type"
      TTYPE="$2"; shift 2; continue ;;
    --tolerance)
      [ $# -ge 2 ] || usage_fail "--tolerance requires a non-negative integer"
      TOL="$2"; shift 2; continue ;;
    --like)
      [ $# -ge 2 ] || usage_fail "--like requires a comma-separated work-item list"
      LIKE="$2"; shift 2; continue ;;
    --delta)
      [ $# -ge 2 ] || usage_fail "--delta requires a work item (#N or milestone:vX.Y)"
      DELTA_WI="$2"; shift 2; continue ;;
    --include-nonreproducible) INCL_NONREPRO=1 ;;
    --resolve-labels)          RESOLVE_LABELS=1 ;;
    --json)                    AS_JSON=1 ;;
    --verbose)                 VERBOSE=1 ;;
    --self-test)               DO_SELFTEST=1 ;;
    -h|--help)
      # sigpipe-idiom: allow — `head` truncates the RENDERED help text, not the match set; an intervening `sed` sits between grep and head, so `-m90` would cap the wrong stage.
      grep -aE '^#( |$)' "$0" | sed -E 's/^# ?//' | head -90
      exit 0 ;;
    *) usage_fail "unknown argument: $1" ;;
  esac
  shift
done

if [ "$DO_SELFTEST" -eq 0 ]; then
  [ -n "$LIKE" ] && { [ -n "$TCLASS" ] || [ -n "$TPOINTS" ] || [ -n "$TSIZE" ]; } \
    && usage_fail "--like is mutually exclusive with --class / --points / --size"
  [ -n "$TSIZE" ] && [ -n "$TPOINTS" ] \
    && usage_fail "--size and --points are mutually exclusive (--size translates through the canonical point scale)"
  if [ -n "$TSIZE" ]; then TPOINTS="$(size_to_points "$TSIZE")"; fi
  if [ -n "$TPOINTS" ]; then
    case "$TPOINTS" in ''|*[!0-9]*) usage_fail "--points must be a positive integer (got '$TPOINTS')" ;; esac
    [ "$TPOINTS" -ge 1 ] || usage_fail "--points must be >= 1 (got '$TPOINTS')"
  fi
  if [ -n "$TOL" ]; then
    case "$TOL" in ''|*[!0-9]*) usage_fail "--tolerance must be a non-negative integer (got '$TOL')" ;; esac
  fi
  if [ -z "$LIKE" ] && [ -z "$DELTA_WI" ]; then
    [ -n "$TCLASS" ] || usage_fail "--class is required (or use --like for explicit comparables, or --delta for a leave-one-out re-derivation)"
    [ -n "$TPOINTS" ] || usage_fail "--points or --size is required (or use --like for explicit comparables)"
  fi
fi

# ── §7 Main ──
render() {
  local store_dir="$1"
  local store_file="$store_dir/usage.jsonl"
  if [ ! -f "$store_file" ] || [ ! -r "$store_file" ]; then
    printf 'FATAL (exit 3): FinOps store unreadable: %s (run extract-usage.sh first)\n' "$store_file" >&2
    exit 3
  fi

  # P0 — the BINDING roll-up gate. Gated on the coverage RECORD, never on
  # meta.schema_version: from v1.2.0 both phases stamp the same version, so a
  # version test passes on an extraction-only store and the comparable set comes
  # back empty while still looking like a successful run. Fails CLOSED — a
  # malformed store makes jq exit non-zero and lands here too.
  if ! jq -e -s 'any(.[]; .record == "coverage")' "$store_file" >/dev/null 2>&1; then
    printf 'FATAL (exit 3): store carries no coverage record — the roll-up phase has not run (run rollup-attribution.sh first).\n' >&2
    exit 3
  fi

  # P6b — a --delta target with NO rollup row has no measured actual, so there is
  # nothing to back-test against. This is the DEFAULT case for every work item that
  # predates the store's coverage window, not an edge case. Before this gate the run
  # exited 0, rendered an UNREQUESTED forward estimate, and printed the word FATAL to
  # STDOUT under prose asserting the back-test had run. FAILS CLOSED — refuse before
  # anything is rendered, name the reason on STDERR, exit non-zero. A jq abort here
  # is also non-zero, so an unreadable store refuses rather than falling through.
  if [ -n "$DELTA_WI" ]; then
    if ! jq -e -s --arg wi "$DELTA_WI" \
         'any(.[]; .record == "rollup" and .work_item == $wi)' "$store_file" >/dev/null 2>&1; then
      printf 'FATAL (exit 3): --delta %s has no rollup row in this store, so there is no measured\n' "$DELTA_WI" >&2
      printf 'actual to back-test against and no leave-one-out delta can be computed.\n' >&2
      printf 'Expected for any work item predating the store coverage window. Refusing to render a\n' >&2
      printf 'forward estimate that was not asked for — re-run rollup-attribution.sh over a store\n' >&2
      printf 'whose window covers %s, or drop --delta and ask for a forward estimate explicitly.\n' "$DELTA_WI" >&2
      exit 3
    fi
  fi

  # The velocity map is the LOCAL size/class bridge. An unreadable or unparsable
  # release log yields an EMPTY map, which thins the comparable population and is
  # then caught by the N_min floor — it must never yield a malformed --argjson
  # value, because that aborts jq and an aborted render must not read as a pass.
  local rel_log vel_map
  rel_log="$(resolve_release_log)"
  vel_map="$(release_log_velocity_map "$rel_log")"
  printf '%s' "${vel_map:-}" | jq -e 'type == "object"' >/dev/null 2>&1 || vel_map='{}'

  # OPT-IN issue-grain label map. NETWORK + non-reproducible; off by default.
  # FINOPS_LABEL_MAP is a test-only offline override so the tier is assertable
  # without a network call (the `gh` leg keeps the --resolve-prs posture).
  local lbl_map='{}'
  if [ "$RESOLVE_LABELS" -eq 1 ]; then
    if [ -n "${FINOPS_LABEL_MAP:-}" ] && [ -r "${FINOPS_LABEL_MAP}" ]; then
      lbl_map="$(cat "${FINOPS_LABEL_MAP}")"
    else
      lbl_map="$(resolve_labels_via_gh "$store_file")"
    fi
    printf '%s' "${lbl_map:-}" | jq -e 'type == "object"' >/dev/null 2>&1 || lbl_map='{}'
  fi

  # --delta: derive the TARGET's OWN matching key from the same local sources the
  # comparables are keyed by, so the leave-one-out set is rebuilt for the key the
  # target itself carries. FAILS CLOSED — an underivable key exits 3 rather than
  # falling back to a 0-point target, which would silently produce a 0 estimate
  # that still renders as a successful run.
  if [ -n "$DELTA_WI" ] && { [ -z "$TCLASS" ] || [ -z "$TPOINTS" ]; }; then
    local dkey=""
    case "$DELTA_WI" in
      milestone:*)
        dkey="$(printf '%s' "$vel_map" | jq -r --arg v "${DELTA_WI#milestone:}" \
                  '(.[$v] // empty) | "\(.points)|\(.class)"')" ;;
      *)
        dkey="$(printf '%s' "$lbl_map" | jq -r --arg k "$DELTA_WI" \
                  '(.[$k] // empty) | "\(.points)|\(.type)"')" ;;
    esac
    if [ -z "$dkey" ]; then
      printf 'FATAL (exit 3): cannot derive a matching key for --delta %s.\n' "$DELTA_WI" >&2
      printf 'A milestone target needs a parsable `**Velocity:**` row in the release log; an issue target needs --resolve-labels.\n' >&2
      printf 'Supply --class/--points explicitly, or fix the source row. Refusing to estimate against an underivable key.\n' >&2
      exit 3
    fi
    [ -z "$TPOINTS" ] && TPOINTS="${dkey%%|*}"
    case "$DELTA_WI" in
      milestone:*) [ -z "$TCLASS" ] && TCLASS="${dkey#*|}" ;;
      *)           [ -z "$TTYPE"  ] && TTYPE="${dkey#*|}" ;;
    esac
  fi

  # Derived tolerance: max(2, round(0.5 * points)). 2 is the point value of
  # `size:S` on the canonical scale, so the band is never narrower than one
  # bucket step; the proportional half-width keeps a 4-pt item and a 20-pt
  # release equally well-banded, which a fixed +/-N does not. [RECOMMENDED]
  local tol="$TOL" pts="${TPOINTS:-0}"
  if [ -z "$tol" ]; then
    local half=$(( (pts + 1) / 2 ))
    tol=$(( half > 2 ? half : 2 ))
  fi

  # NOTE (fail-closed, load-bearing): `printf '%s'` on an EMPTY value gives jq -R
  # zero input lines, so it emits nothing and --argjson then receives an empty
  # string and aborts. The trailing newline guarantees exactly one raw line in
  # every case; the select() drops the empty element an empty line produces.
  local like_json
  like_json="$(printf '%s\n' "$LIKE" | jq -R '[splits(",")] | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))')"
  printf '%s' "$like_json" | jq -e 'type == "array"' >/dev/null 2>&1 \
    || { printf 'FATAL (exit 2): could not parse --like list\n' >&2; exit 2; }

  jq -r -s \
    --argjson vel "$vel_map" \
    --argjson lbl "$lbl_map" \
    --argjson like "$like_json" \
    --arg tclass "$TCLASS" \
    --argjson tpoints "$pts" \
    --argjson tol "$tol" \
    --arg ttype "$TTYPE" \
    --arg target_wi "$DELTA_WI" \
    --argjson incl_nonrepro "$INCL_NONREPRO" \
    --argjson resolve_labels "$RESOLVE_LABELS" \
    --argjson verbose "$VERBOSE" \
    --argjson nmin "$NMIN" \
    --arg as_json "$AS_JSON" \
    --arg gen_utc "$(NOW_UTC)" \
    --arg gen_ver "$(generator_version)" \
    "$JQ_ESTIMATE" "$store_file"
  # FAIL CLOSED: a jq abort (malformed store, bad --argjson, program error) must
  # NOT exit 0 behind a truncated or empty render. Without this the caller sees
  # rc=0 and reads an aborted estimate as a successful one — the exact silent
  # fail-open class this release has already produced five times.
  local jrc=$?
  if [ "$jrc" -ne 0 ]; then
    printf 'FATAL (exit 3): the estimate program aborted (jq exit %s) — no estimate was produced.\n' "$jrc" >&2
    exit 3
  fi
  return 0
}

# ── OPT-IN label resolve (NETWORK). Mirrors --resolve-prs: never on the default
#    path, stamps the output non-reproducible, and DEGRADES to the local path
#    (an empty map -> the ladder falls to E4 DECLINE) rather than failing the run.
#    A `gh` failure must never silently produce a *smaller-but-plausible* map, so
#    a per-issue failure is skipped explicitly and the tier's own N_min floor is
#    what decides whether the thinned population may be used at all. ──
resolve_labels_via_gh() {
  local store_file="$1"
  command -v gh >/dev/null 2>&1 || { printf '{}'; return 0; }
  local issues
  issues="$(jq -r -s '[.[] | select(.record == "rollup") | select(.work_item_kind == "issue") | .work_item]
                      | unique | .[]' "$store_file" 2>/dev/null || true)"
  local out="{}" n lbls size type pts
  while IFS= read -r wi; do
    [ -n "$wi" ] || continue
    n="${wi#\#}"
    case "$n" in ''|*[!0-9]*) continue ;; esac
    lbls="$(gh issue view "$n" --json labels --jq '[.labels[].name] | join(" ")' 2>/dev/null || true)"
    [ -n "$lbls" ] || continue
    # sigpipe-idiom: allow — `grep -o` emits N matches per LINE, so `-m1` (which counts LINES) would keep BOTH matches; `head -1` must stay. Writer converted to a here-string, so nothing is piped into the short-circuiting reader.
    size="$(grep -aoE 'size:(XS|S|M|L|XL)' <<<"$lbls" | head -1 | cut -d: -f2)"
    # sigpipe-idiom: allow — same `grep -o` line-vs-match divergence as the size probe above.
    type="$(grep -aoE 'type:[a-z-]+' <<<"$lbls" | head -1 | cut -d: -f2)"
    [ -n "$size" ] || continue
    pts="$(size_to_points "$size")"
    out="$(printf '%s' "$out" | jq --arg k "$wi" --argjson p "$pts" --arg t "${type:-unknown}" \
             '. + {($k): {points: $p, type: $t}}')"
  done <<< "$issues"
  printf '%s' "$out"
}

# ── §8 Self-test — synthetic fixtures only; no operator store, no network.
#    Every assertion below FAILS CLOSED: a render that aborts, exits non-zero, or
#    produces no output is a FAIL; every negative assertion is paired with a
#    positive control, and every count-based check asserts a non-empty search
#    space first, so an empty population can never read as "no violations". ──
FAILN=0
ok()  { printf '  PASS: %s\n' "$1"; }
bad() { printf 'FAIL: %s\n' "$1"; FAILN=1; }

# run_est <outfile> <store-dir> <args...> -> rc; FAILS CLOSED on empty output.
run_est() {
  local out="$1" sd="$2"; shift 2
  local rc
  STORE="$sd" bash "$SELF" "$@" > "$out" 2>"$out.err"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    bad "estimate exited $rc (want 0) for [$*] — $(head -1 "$out.err" 2>/dev/null)"
    return "$rc"
  fi
  if [ ! -s "$out" ]; then
    bad "estimate produced EMPTY output for [$*] — an empty render must never read as a pass"
    return 1
  fi
  return 0
}

self_test() {
  [ -d "$FIXTURES_DIR" ] || { echo "FAIL: estimate fixtures dir missing: $FIXTURES_DIR"; return 1; }
  local fx="$FIXTURES_DIR/usage.jsonl"
  local fxthin="$FIXTURES_DIR/usage-thin.jsonl"
  local fxnc="$FIXTURES_DIR/usage-no-coverage.jsonl"
  local fxpv="$FIXTURES_DIR/usage-provider.jsonl"
  local fxpu="$FIXTURES_DIR/usage-provider-unreadable.jsonl"
  local rlog="$FIXTURES_DIR/RELEASE_LOG.fixture.md"
  local oracle="$FIXTURES_DIR/estimate.expected.json"
  local f
  for f in "$fx" "$fxthin" "$fxnc" "$fxpv" "$fxpu" "$rlog"; do
    [ -f "$f" ] || { echo "FAIL: missing fixture: $f"; return 1; }
  done

  local wd; wd="$(mktemp -d "${TMPDIR:-/tmp}/finops-estimate-selftest.XXXXXX")"
  local d
  for d in main thin nocov prov provbad; do mkdir -p "$wd/$d"; done
  cp "$fx"     "$wd/main/usage.jsonl"
  cp "$fxthin" "$wd/thin/usage.jsonl"
  cp "$fxnc"   "$wd/nocov/usage.jsonl"
  cp "$fxpv"   "$wd/prov/usage.jsonl"
  cp "$fxpu"   "$wd/provbad/usage.jsonl"
  export FINOPS_RELEASE_LOG="$rlog"

  local MD="$wd/md.txt" JS="$wd/js.json"
  run_est "$MD" "$wd/main" --class novel --points 16          || { rm -rf "$wd"; return 1; }
  run_est "$JS" "$wd/main" --class novel --points 16 --json   || { rm -rf "$wd"; return 1; }

  # ── SE-1 PARITY — the six lifted helpers are byte-identical to the sibling's. ──
  local fn a b parity_ok=1 checked=0
  if [ ! -r "$SIBLING" ]; then
    bad "SE-1 PARITY: sibling script unreadable ($SIBLING) — cannot verify, treating as FAIL"
  else
    for fn in preflight_deps generator_version toml_val workspace_root resolve_store guard_store_git_ignored; do
      a="$(sed -n "/^${fn}() {/,/^}/p" "$SELF")"
      b="$(sed -n "/^${fn}() {/,/^}/p" "$SIBLING")"
      if [ -z "$a" ] || [ -z "$b" ]; then
        bad "SE-1 PARITY: could not extract '$fn' from both files (empty extraction is a FAIL, not a skip)"
        parity_ok=0; continue
      fi
      checked=$((checked+1))
      [ "$a" = "$b" ] || { bad "SE-1 PARITY: '$fn' differs from rollup-attribution.sh"; parity_ok=0; }
    done
    if [ "$checked" -ne 6 ]; then
      bad "SE-1 PARITY: extracted $checked of 6 helpers — an under-populated check cannot pass"
    elif [ "$parity_ok" -eq 1 ]; then
      ok "SE-1 PARITY (6/6 inherited helpers byte-identical to rollup-attribution.sh)"
    fi
  fi

  # ── SE-1b GUARD — store inside a repo but not ignored -> exit 4; outside -> proceeds. ──
  local gd rc
  gd="$(mktemp -d "${TMPDIR:-/tmp}/finops-estimate-guard.XXXXXX")"
  ( cd "$gd" && git init -q . >/dev/null 2>&1 )
  mkdir -p "$gd/store"; cp "$fx" "$gd/store/usage.jsonl"
  ( STORE="$gd/store" bash "$SELF" --class novel --points 16 >/dev/null 2>&1 ); rc=$?
  [ "$rc" -eq 4 ] && ok "SE-1b GUARD: un-ignored in-repo store refused (exit 4)" \
    || bad "SE-1b GUARD: in-repo un-ignored store not refused (exit $rc, want 4)"
  local outside_repo
  outside_repo="$(git -C "$wd" rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -n "$outside_repo" ]; then
    bad "SE-1b GUARD: the self-test temp dir resolved inside git repo $outside_repo — control invalid, cannot assert the pass-through leg"
  else
    ( STORE="$wd/main" bash "$SELF" --class novel --points 16 >/dev/null 2>&1 ); rc=$?
    [ "$rc" -eq 0 ] && ok "SE-1b GUARD: store outside any repo proceeds (exit 0)" \
      || bad "SE-1b GUARD: outside-repo store did not proceed (exit $rc, want 0)"
  fi
  rm -rf "$gd"

  # ── SE-2 ROLLUP-GATE — no coverage record -> exit 3, WITH a negative control
  #    proving the gate is on the record and not on meta.schema_version. ──
  local scv
  scv="$(jq -r -s '[.[]|select(.record=="meta")|.schema_version][0] // "absent"' "$fxnc")"
  if [ "$scv" != "1.2.0" ]; then
    bad "SE-2 control invalid: the no-coverage fixture must carry meta.schema_version=\"1.2.0\" (got '$scv') — without it the negative control proves nothing"
  else
    ( STORE="$wd/nocov" bash "$SELF" --class novel --points 16 >"$wd/nc.out" 2>"$wd/nc.err" ); rc=$?
    if [ "$rc" -eq 3 ] && grep -aq 'store carries no coverage record' "$wd/nc.err"; then
      ok "SE-2 ROLLUP-GATE: coverage-less store exits 3 with the named message DESPITE meta.schema_version=1.2.0 (gate is on the record, not the version)"
    else
      bad "SE-2 ROLLUP-GATE: coverage-less store exited $rc (want 3) / message missing — $(head -1 "$wd/nc.err" 2>/dev/null)"
    fi
    ( STORE="$wd/main" bash "$SELF" --class novel --points 16 >/dev/null 2>&1 ); rc=$?
    [ "$rc" -eq 0 ] && ok "SE-2 control: the SAME query on a rolled-up store exits 0 (the gate is not rejecting everything)" \
      || bad "SE-2 control: rolled-up store exited $rc (want 0) — the gate is over-rejecting"
  fi

  # ── SE-3 N_MIN — a 2-comparable store DECLINES; adding a 3rd produces a figure. ──
  local T2="$wd/thin.txt" navail
  navail="$(jq -r -s '[.[]|select(.record=="rollup")]|length' "$fxthin")"
  if [ "${navail:-0}" -ne 2 ]; then
    bad "SE-3 control invalid: the thin fixture must hold exactly 2 rollup rows (got ${navail:-0})"
  elif run_est "$T2" "$wd/thin" --class thin-population --points 4; then
    if grep -aq 'INSUFFICIENT-COMPARABLES: n=2 (3 required). NO ESTIMATE EMITTED.' "$T2" \
       && ! grep -aqE '^Estimate: ' "$T2"; then
      ok "SE-3 N_MIN: a 2-comparable population DECLINES (exit 0) and emits NO estimate line"
    else
      bad "SE-3 N_MIN: the 2-comparable case did not decline cleanly (an 'Estimate:' line or a missing decline message)"
    fi
    #    A decline must not print median-shaped statistics either. A "Dispersion:
    #    MAD … (rMAD …)" line under a decline reads as a computed-but-hedged
    #    figure — precisely the false precision the floor exists to prevent — so
    #    the sub-threshold rows render as diagnosis, explicitly NOT as a basis.
    if grep -aqE '^Dispersion: |^Comparison \(NOT used\)|^Basis: median of ' "$T2"; then
      bad "SE-3 N_MIN: the declined render printed median-shaped statistics (Dispersion / mean-comparison / 'Basis: median of') — a decline must not imply a computed figure"
    elif grep -aq 'NOT a basis; no median was computed' "$T2" \
         && grep -aq 'Confidence: n/a — DECLINED at rule R1' "$T2"; then
      ok "SE-3 N_MIN: the declined render prints NO dispersion, NO mean-comparison and NO confidence label — the sub-threshold rows are labelled diagnosis, not a basis"
    else
      bad "SE-3 N_MIN: the declined render is missing the explicit not-a-basis / confidence-n-a wording"
    fi
  fi
  local T3="$wd/thin3.txt"
  mkdir -p "$wd/thin3"
  { cat "$fxthin"
    jq -c -s '[.[]|select(.record=="rollup")][0] | .work_item="milestone:v9.50" | .session_ids=["00000000-0000-4000-8000-000000000999"]' "$fxthin"
  } > "$wd/thin3/usage.jsonl"
  if run_est "$T3" "$wd/thin3" --class thin-population --points 4; then
    grep -aqE '^Estimate: ' "$T3" \
      && ok "SE-3 N_MIN control: adding a 3rd comparable DOES produce an estimate (the floor is the reason, not an unrelated failure)" \
      || bad "SE-3 N_MIN control: 3 comparables still produced no estimate — the decline is not attributable to the floor"
  fi

  # ── SE-4 MEDIAN-NOT-MEAN — the right-skewed set yields the median, never the mean. ──
  local emed emean
  emed="$(jq -r '.estimate_tokens' "$JS")"
  emean="$(jq -r '.mean_tokens_not_used' "$JS")"
  if [ "$emed" = "null" ] || [ "$emean" = "null" ]; then
    bad "SE-4 MEDIAN: the fixture produced no estimate/mean pair — the check cannot pass on an empty population"
  elif [ "$emed" = "$emean" ]; then
    bad "SE-4 MEDIAN: estimate ($emed) EQUALS the mean ($emean) — the fixture is not right-skewed, so the check is vacuous"
  elif [ "$emed" -lt "$emean" ]; then
    ok "SE-4 MEDIAN-NOT-MEAN (estimate=$emed is the median; the mean is $emean — a mean-based regression fails here)"
  else
    bad "SE-4 MEDIAN: estimate ($emed) exceeds the mean ($emean) on a right-skewed fixture — the aggregation is wrong"
  fi

  # ── SE-5 CONFIDENCE — the ladder is TOTAL: four fixtures pin every reachable
  #    outcome, each asserting the LABEL, the RULE, and the (n, rMAD) pair. ──
  local lbl rule nn rmv want got legs=0
  set -- "routine:8:HIGH:R3" "novel:16:MEDIUM:R4" "cross-cutting:10:LOW:R5" "wide-dispersion:6:LOW:R2"
  for want in "$@"; do
    local cls="${want%%:*}" rest="${want#*:}"
    local pts="${rest%%:*}"; rest="${rest#*:}"
    local wlbl="${rest%%:*}" wrule="${rest#*:}"
    if run_est "$wd/c.json" "$wd/main" --class "$cls" --points "$pts" --json; then
      lbl="$(jq -r '.confidence' "$wd/c.json")"
      rule="$(jq -r '.confidence_rule' "$wd/c.json")"
      nn="$(jq -r '.n_comparables' "$wd/c.json")"
      rmv="$(jq -r '.dispersion.rmad' "$wd/c.json")"
      if [ "$lbl" = "$wlbl" ] && [ "$rule" = "$wrule" ]; then
        ok "SE-5 CONFIDENCE $cls: $lbl via $rule on (n=$nn, rMAD=$rmv)"
        legs=$((legs+1))
      else
        bad "SE-5 CONFIDENCE $cls: got $lbl/$rule on (n=$nn, rMAD=$rmv), want $wlbl/$wrule"
      fi
    fi
  done
  [ "$legs" -eq 4 ] || bad "SE-5 CONFIDENCE: only $legs of 4 ladder legs asserted — an under-populated ladder check cannot pass"
  # R2 must actually SUPPRESS the point figure, not merely label it.
  if run_est "$wd/r2.txt" "$wd/main" --class wide-dispersion --points 6; then
    if grep -aq 'Point estimate SUPPRESSED' "$wd/r2.txt" && ! grep -aqE '^Estimate: ' "$wd/r2.txt"; then
      ok "SE-5 R2: extreme dispersion suppresses the point figure and renders the observed range instead"
    else
      bad "SE-5 R2: a point figure rendered despite rule R2 (or the suppression notice is missing)"
    fi
  fi

  # ── SE-6 CAPS — weaker evidence must move the LABEL, not just annotate it. ──
  #    Leg 1: a best-effort-heavy explicit set that scores MEDIUM on dispersion
  #    alone renders LOW via C-TIER (f > 0.50).
  if run_est "$wd/cap1.json" "$wd/main" --like 'milestone:v9.90,#99001,#99002' --json; then
    local f1 l1 r1
    f1="$(jq -r '.best_effort_token_fraction' "$wd/cap1.json")"
    l1="$(jq -r '.confidence' "$wd/cap1.json")"
    r1="$(jq -r '.confidence_rule' "$wd/cap1.json")"
    if [ "$(jq -r '.best_effort_token_fraction > 0.5' "$wd/cap1.json")" != "true" ]; then
      bad "SE-6 C-TIER control invalid: best-effort fraction is $f1, not > 0.50 — the cap cannot be exercised"
    elif [ "$r1" = "R4" ] && [ "$l1" = "LOW" ]; then
      ok "SE-6 C-TIER: dispersion rule R4 would score MEDIUM, best-effort fraction $f1 > 0.50 caps it to LOW"
    else
      bad "SE-6 C-TIER: got $l1 via $r1 (want rule R4 capped to LOW) at best-effort fraction $f1"
    fi
  fi
  #    Leg 2: HIGH -> MEDIUM at 0.25 < f <= 0.50.
  if run_est "$wd/cap2.json" "$wd/main" --like 'milestone:v9.80,milestone:v9.81,milestone:v9.82,milestone:v9.83,milestone:v9.84,milestone:v9.85,#99004' --json; then
    local l2 r2v f2
    l2="$(jq -r '.confidence' "$wd/cap2.json")"; r2v="$(jq -r '.confidence_rule' "$wd/cap2.json")"
    f2="$(jq -r '.best_effort_token_fraction' "$wd/cap2.json")"
    if [ "$r2v" = "R3" ] && [ "$l2" = "MEDIUM" ]; then
      ok "SE-6 C-TIER: dispersion rule R3 would score HIGH, best-effort fraction $f2 in (0.25,0.50] caps it to MEDIUM"
    else
      bad "SE-6 C-TIER (HIGH->MEDIUM): got $l2 via $r2v at f=$f2 (want R3 capped to MEDIUM)"
    fi
  fi
  #    Leg 3: --include-nonreproducible admits a pr-resolved row -> LOW + reproducible:false.
  if run_est "$wd/cap3.json" "$wd/main" --like 'milestone:v9.80,milestone:v9.81,milestone:v9.82,milestone:v9.83,milestone:v9.84,milestone:v9.85,#99003' --include-nonreproducible --json; then
    local l3 rp3 has3
    l3="$(jq -r '.confidence' "$wd/cap3.json")"
    rp3="$(jq -r '.reproducible' "$wd/cap3.json")"
    has3="$(jq -r '[.basis[]|select(.work_item=="#99003")]|length' "$wd/cap3.json")"
    if [ "$has3" != "1" ]; then
      bad "SE-6 C-NONREPRO control invalid: the pr-resolved row was not admitted under --include-nonreproducible"
    elif [ "$l3" = "LOW" ] && [ "$rp3" = "false" ]; then
      ok "SE-6 C-NONREPRO: an admitted pr-resolved comparable caps confidence to LOW and stamps reproducible:false"
    else
      bad "SE-6 C-NONREPRO: got confidence=$l3 reproducible=$rp3 (want LOW / false)"
    fi
  fi
  #    Leg 4: the SAME set WITHOUT the flag must exclude the pr-resolved row (P4).
  if run_est "$wd/cap4.json" "$wd/main" --like 'milestone:v9.80,milestone:v9.81,milestone:v9.82,#99003' --json; then
    [ "$(jq -r '[.basis[]|select(.work_item=="#99003")]|length' "$wd/cap4.json")" = "0" ] \
      && ok "SE-6 P4 control: without --include-nonreproducible the pr-resolved row is EXCLUDED by default" \
      || bad "SE-6 P4 control: a pr-resolved row entered the basis on the default path"
  fi

  # ── SE-7 ELIGIBILITY — honesty buckets are never comparables, in any mode. ──
  local badrows
  badrows="$(jq -r '[.basis[] | select(.work_item=="unattributed" or .work_item=="multi-branch")] | length' "$JS")"
  local anyrows; anyrows="$(jq -r '.basis|length' "$JS")"
  if [ "${anyrows:-0}" -lt 3 ]; then
    bad "SE-7 ELIGIBILITY: only ${anyrows:-0} basis row(s) — an empty basis cannot prove an exclusion"
  elif [ "$badrows" = "0" ]; then
    ok "SE-7 ELIGIBILITY: unattributed / multi-branch rows never appear as comparables ($anyrows rows scanned)"
  else
    bad "SE-7 ELIGIBILITY: $badrows honesty-bucket row(s) entered the basis"
  fi
  # The fixture must actually CONTAIN those rows, or the assertion is vacuous.
  local present
  present="$(jq -r -s '[.[]|select(.record=="rollup")|select(.work_item=="unattributed" or .work_item=="multi-branch")]|length' "$fx")"
  [ "${present:-0}" -eq 2 ] \
    && ok "SE-7 control: the fixture DOES carry both honesty-bucket rows (the exclusion is real, not an empty search space)" \
    || bad "SE-7 control: the fixture carries ${present:-0} honesty-bucket row(s), expected 2 — the exclusion check is vacuous"
  # Zero-token and unkeyable rows are excluded with NAMED reasons.
  if run_est "$wd/vb.txt" "$wd/main" --class novel --points 16 --verbose; then
    grep -aq 'milestone:v9.10: P5 zero-token row' "$wd/vb.txt" \
      && ok "SE-7 P5: the zero-token row is excluded with its named reason" \
      || bad "SE-7 P5: the zero-token exclusion reason is missing from --verbose"
    grep -aq 'milestone:v9.20: P7 unkeyable' "$wd/vb.txt" \
      && ok "SE-7 P7: a milestone with no RELEASE_LOG row is excluded as unkeyable (never defaulted)" \
      || bad "SE-7 P7: the unkeyable exclusion reason is missing from --verbose"
    grep -aq 'milestone:v9.30: P7 unkeyable' "$wd/vb.txt" \
      && ok "SE-7 SA-8: an N/A **Velocity:** row fails to parse and is excluded, not defaulted" \
      || bad "SE-7 SA-8: the N/A velocity row was not excluded as unkeyable"
    grep -aq 'milestone:v9.31: P7 unkeyable' "$wd/vb.txt" \
      && ok "SE-7 SA-8: a narrative **Velocity:** row fails to parse and is excluded, not defaulted" \
      || bad "SE-7 SA-8: the narrative velocity row was not excluded as unkeyable"
  fi

  # ── SE-8 UNITS — volume by default; $ only from a provider record's own rate;
  #    a present-but-unreadable provider record renders volume + a NAMED notice. ──
  #    The negative is scoped to a $-DENOMINATED FIGURE (a '$' adjacent to a
  #    numeral, or a Derived-cost line), not to the '$' character: the header
  #    legitimately prints the ${CLAUDE_WORKSPACE_ROOT} resolution chain, and a
  #    bare-character test would fail on that and mask the real assertion.
  local usdfigs
  usdfigs="$(grep -acE '\$[0-9]|Derived cost: \$' "$MD" || true)"
  if ! grep -aq 'Unit: token volume (flat-rate; no metered-API source in store).' "$MD"; then
    bad "SE-8 UNITS: the default render lacks the volume-mode statement — the reason for volume mode must be stated, not implied"
  elif [ "${usdfigs:-1}" -eq 0 ]; then
    ok "SE-8 UNITS: default store renders token volume only — 0 \$-denominated figures, and the volume-mode reason is stated"
  else
    bad "SE-8 UNITS: the default render contains $usdfigs \$-denominated figure(s) with no provider record in the store"
  fi
  if run_est "$wd/pv.txt" "$wd/prov" --class novel --points 16; then
    grep -aq 'Derived cost: \$' "$wd/pv.txt" && grep -aq 'DERIVED from the store' "$wd/pv.txt" \
      && ok "SE-8 UNITS: a provider record with a readable cost/token pair yields a \$ figure at the OBSERVED rate (no price table)" \
      || bad "SE-8 UNITS: the synthetic provider fixture did not produce a derived \$ figure"
  fi
  if run_est "$wd/pu.txt" "$wd/provbad" --class novel --points 16; then
    if grep -aq 'PROVIDER-PRESENT-BUT-UNREADABLE' "$wd/pu.txt" && ! grep -aq 'Derived cost: \$' "$wd/pu.txt"; then
      ok "SE-8 UNITS: an unreadable provider record renders volume plus the named notice — never a silent fallback"
    else
      bad "SE-8 UNITS: the unreadable-provider case did not render the named notice (or rendered a \$ anyway)"
    fi
  fi

  # ── SE-9 PROVENANCE (CIAC-4) — NO BARE NUMERAL. Every basis figure is either
  #    tagged [SOURCE: exact message.usage] or carries a leading '~'. Fails closed. ──
  local scan viol
  scan="$(jq '[.basis[]] | length' "$JS")"
  viol="$(jq '[.basis[] | select((.figure|startswith("~")|not) and (.provenance != "[SOURCE: exact message.usage]"))] | length' "$JS")"
  if [ "${scan:-0}" -lt 3 ]; then
    bad "SE-9 CIAC-4: only ${scan:-0} basis figure(s) — too few to be a meaningful check (fail closed)"
  elif [ "${viol:-1}" -eq 0 ]; then
    ok "SE-9 CIAC-4 no-bare-numeral ($scan basis figures, 0 unprovenanced)"
  else
    bad "SE-9 CIAC-4: $viol of $scan basis figure(s) carry neither '~' nor an exact-source tag"
  fi
  grep -aqE '~[0-9]' "$MD" \
    && ok "SE-9 CIAC-4: a not-exact figure carries the '~' marker on the numeral itself" \
    || bad "SE-9 CIAC-4: no '~'-marked figure rendered — the fixture must exercise a heuristic comparable"
  grep -aq '\[INFERRED: ceil(words/0.75) fallback\]' "$MD" \
    && ok "SE-9 CIAC-4: a heuristic comparable renders its [INFERRED] tag (distinguishable from exact)" \
    || bad "SE-9 CIAC-4: no [INFERRED] row rendered"
  grep -aq 'hub-state-lineage — deterministic join, local' "$MD" \
    && ok "SE-9 CIAC-4: every basis row carries its attribution-tier label verbatim from the convention" \
    || bad "SE-9 CIAC-4: attribution-tier labels missing from the basis table"
  # Every rendered estimate carries BOTH a basis table and a confidence label.
  local nb=0 nc=0 file
  for file in "$MD" "$wd/r2.txt" "$wd/vb.txt" "$wd/pv.txt" "$T2"; do
    [ -f "$file" ] || continue
    grep -aq '^Basis: ' "$file" || grep -aq '^Basis attempted: ' "$file" || { bad "SE-9 AC-1: $file renders no basis"; continue; }
    nb=$((nb+1))
    grep -aqE 'confidence: (HIGH|MEDIUM|LOW)\]|^Confidence: (HIGH|MEDIUM|LOW)|NO ESTIMATE EMITTED' "$file" || { bad "SE-9 AC-1: $file renders no confidence"; continue; }
    nc=$((nc+1))
  done
  if [ "$nb" -lt 4 ] || [ "$nc" -lt 4 ]; then
    bad "SE-9 AC-1: only $nb basis / $nc confidence render(s) checked — an under-populated check cannot pass"
  else
    ok "SE-9 AC-1: every rendered output ($nb) carries BOTH its basis and its confidence"
  fi

  # ── SE-10 CIAC-3 — no operator path, no store path, no session directory value
  #    leaks into any render, against a fixture that deliberately carries one. ──
  local leakctl
  leakctl="$(grep -ac '/Users/synthetic-operator/' "$fx" || true)"
  if [ "${leakctl:-0}" -lt 1 ]; then
    bad "SE-10 CIAC-3 control invalid: the fixture carries no /Users/ path, so the negative proves nothing"
  else
    local leaks=0 nfiles=0
    for file in "$MD" "$JS" "$wd/vb.txt" "$wd/pv.txt"; do
      [ -f "$file" ] || continue
      nfiles=$((nfiles+1))
      grep -aqE '/Users/|/home/|synthetic-operator' "$file" && { leaks=$((leaks+1)); bad "SE-10 CIAC-3: $file leaks a filesystem path"; }
    done
    if [ "$nfiles" -lt 4 ]; then
      bad "SE-10 CIAC-3: only $nfiles render(s) scanned — an under-populated leak check cannot pass"
    elif [ "$leaks" -eq 0 ]; then
      ok "SE-10 CIAC-3 ($nfiles renders scanned against a fixture carrying $leakctl operator-path line(s); 0 leaks)"
    fi
  fi

  # ── SE-11 DELTA — leave-one-out: excludes the target from its own basis and
  #    reports estimate -> actual, signed delta, % error, basis and confidence. ──
  if run_est "$wd/delta.json" "$wd/main" --delta 'milestone:v9.94' --json; then
    local dself dact dest ddel dpct dconf
    dself="$(jq -r '[.basis[]|select(.work_item=="milestone:v9.94")]|length' "$wd/delta.json")"
    dact="$(jq -r '.actual_tokens' "$wd/delta.json")"
    dest="$(jq -r '.estimate_tokens' "$wd/delta.json")"
    ddel="$(jq -r '.delta_tokens' "$wd/delta.json")"
    dpct="$(jq -r '.pct_error' "$wd/delta.json")"
    dconf="$(jq -r '.confidence' "$wd/delta.json")"
    if [ "$dself" != "0" ]; then
      bad "SE-11 DELTA: the target appeared in its OWN comparable set (leave-one-out violated)"
    elif [ "$dact" = "null" ] || [ "$dest" = "null" ] || [ "$ddel" = "null" ] || [ "$dpct" = "null" ]; then
      bad "SE-11 DELTA: one of estimate/actual/delta/pct_error is null (est=$dest act=$dact delta=$ddel pct=$dpct)"
    elif [ "$((dest - ddel))" -ne "$dact" ]; then
      # delta_tokens is defined as (estimate - actual), so actual == estimate - delta.
      bad "SE-11 DELTA: arithmetic broken — estimate($dest) - delta($ddel) != actual($dact)"
    elif [ "$dconf" = "null" ]; then
      bad "SE-11 DELTA: the delta carries no confidence label"
    elif [ "$(jq -n --argjson e "$dest" --argjson a "$dact" --argjson p "$dpct" \
               '((((($e - $a) / $a) * 1000) | round) / 10) == $p' 2>/dev/null)" != "true" ]; then
      # Independently recomputed, not read back from the same expression: a
      # double-scaled percentage (x100 twice) still looks like a percentage.
      bad "SE-11 DELTA: pct_error $dpct% does not match the independently computed (estimate-actual)/actual — check for a double-scaled percentage"
    else
      ok "SE-11 DELTA: estimate=$dest actual=$dact delta=$ddel pct_error=$dpct% confidence=$dconf (target excluded from its own basis)"
    fi
    # The leave-one-out estimate must DIFFER from the all-in figure, or the
    # exclusion is unobservable and the test proves nothing.
    if run_est "$wd/allin.json" "$wd/main" --class novel --points 18 --json; then
      local ain; ain="$(jq -r '.estimate_tokens' "$wd/allin.json")"
      if [ "$ain" = "null" ]; then
        bad "SE-11 DELTA control: the all-in run produced no estimate — the comparison is vacuous"
      fi
      [ "$ain" != "$dest" ] \
        && ok "SE-11 DELTA control: leave-one-out ($dest) differs from the all-in estimate ($ain) — the exclusion is observable" \
        || bad "SE-11 DELTA control: leave-one-out equals the all-in estimate ($ain) — the exclusion is unobservable here"
    fi
  fi
  if run_est "$wd/delta.txt" "$wd/main" --delta 'milestone:v9.94'; then
    grep -aq '## Leave-one-out delta' "$wd/delta.txt" && grep -aq '| estimate | actual | signed delta | % error |' "$wd/delta.txt" \
      && ok "SE-11 DELTA: the markdown surface renders the estimate/actual/delta/%-error table" \
      || bad "SE-11 DELTA: the markdown delta table is missing"
  fi

  # ── SE-11c NO-ARITHMETIC-RECOVERY — a --delta whose estimate is SUPPRESSED must
  #    not leak that estimate through a derived field. `actual + delta` recovers the
  #    withheld point figure in one subtraction and `actual x (1 + pct_error)`
  #    recovers it in one multiplication, so both are suppressed with the figure.
  #    Fails CLOSED: the run must actually BE in a suppressed-with-a-real-actual
  #    state or the check is vacuous, and the paired positive leg (SE-11 above, plus
  #    the explicit control here) proves the fields are not blanket-nulled. ──
  local DS="$wd/delta-suppressed.json" DSM="$wd/delta-suppressed.txt"
  if run_est "$DS" "$wd/thin" --delta 'milestone:v9.41' --json \
     && run_est "$DSM" "$wd/thin" --delta 'milestone:v9.41'; then
    local ds_sup ds_est ds_act ds_del ds_pct
    ds_sup="$(jq -r '.suppression // "null"' "$DS")"
    ds_est="$(jq -r '.estimate_tokens // "null"' "$DS")"
    ds_act="$(jq -r '.actual_tokens // "null"' "$DS")"
    ds_del="$(jq -r '.delta_tokens // "null"' "$DS")"
    ds_pct="$(jq -r '.pct_error // "null"' "$DS")"
    if [ "$ds_sup" = "null" ] || [ "$ds_est" != "null" ] || [ "$ds_act" = "null" ]; then
      bad "SE-11c control invalid: this run is not a suppressed-estimate-with-a-real-actual case (suppression=$ds_sup, estimate=$ds_est, actual=$ds_act) — 'the derived fields are withheld' proves nothing here"
    elif [ "$ds_del" != "null" ] || [ "$ds_pct" != "null" ]; then
      bad "SE-11c json: the estimate is suppressed but delta=$ds_del / pct_error=$ds_pct still render — actual($ds_act) + delta recovers the withheld figure in one subtraction"
    elif ! jq -e '.delta_suppression != null' "$DS" >/dev/null 2>&1; then
      bad "SE-11c json: the derived fields are null but nothing names WHY — a silent null is indistinguishable from 'not computed'"
    else
      #    Rendered leg: all three derived cells say (suppressed), and the delta
      #    SECTION carries no numeral that reconstructs the figure.
      local dsec dcells
      dsec="$(sed -n '/## Leave-one-out delta/,$p' "$DSM")"
      dcells="$(printf '%s\n' "$dsec" | grep -ac '^| (suppressed) | .* | (suppressed) | (suppressed) |' || true)"
      if [ "${dcells:-0}" -ne 1 ]; then
        bad "SE-11c rendered: expected exactly 1 fully-suppressed delta row, found ${dcells:-0}"
      elif grep -aqE '\| [-+][0-9]' <<<"$dsec"; then
        bad "SE-11c rendered: the delta section still renders a signed numeral — the withheld figure is recoverable"
      elif grep -aq 'SUPPRESSED with the point figure' <<<"$dsec"; then
        ok "SE-11c NO-ARITHMETIC-RECOVERY: suppressed estimate (class $ds_sup) withholds delta AND % error in both shapes; the delta section renders actual=$ds_act and no signed numeral, so the figure is not recoverable"
      else
        bad "SE-11c rendered: the delta row is suppressed but the render does not say why"
      fi
    fi
  fi
  # ── SE-11d NO-ROLLUP-ROW TARGET — a --delta whose target carries no rollup row has
  #    no measured actual, so no back-test is possible. This is the DEFAULT case for
  #    every work item predating the store's coverage window. It used to exit 0,
  #    render an UNREQUESTED forward estimate, and print the word FATAL to STDOUT
  #    under prose asserting the back-test had run. Must now: exit non-zero, name the
  #    FATAL on STDERR, and render NO estimate at all.
  #    Fails CLOSED with two discriminating controls: the target must be derivable
  #    (a velocity row exists) so the refusal is about the MISSING ROW and not an
  #    underivable key, and it must genuinely have no rollup row. ──
  local NRT="milestone:v9.41" nrt_rows nrt_vel nrtrc
  nrt_rows="$(jq -r -s --arg wi "$NRT" '[.[]|select(.record=="rollup")|select(.work_item==$wi)]|length' "$fx")"
  nrt_vel="$(grep -ac "^#### Deployment Log ${NRT#milestone:}\$" "$rlog" || true)"
  if [ "${nrt_rows:-1}" -ne 0 ] || [ "${nrt_vel:-0}" -lt 1 ]; then
    bad "SE-11d control invalid: $NRT must have 0 rollup rows in the fixture (got ${nrt_rows:-?}) AND a velocity row in the fixture log (got ${nrt_vel:-0}) — otherwise the refusal proves nothing about the missing-row gate"
  else
    ( STORE="$wd/main" bash "$SELF" --delta "$NRT" >"$wd/nrt.out" 2>"$wd/nrt.err" ); nrtrc=$?
    if [ "$nrtrc" -eq 0 ]; then
      bad "SE-11d: --delta on a target with no rollup row exited 0 — a failed back-test read as a successful one"
    elif ! grep -aq 'FATAL (exit 3): --delta' "$wd/nrt.err"; then
      bad "SE-11d: --delta on a rowless target exited $nrtrc but named no FATAL on STDERR — $(head -1 "$wd/nrt.err" 2>/dev/null)"
    elif grep -aq 'FATAL' "$wd/nrt.out"; then
      bad "SE-11d: 'FATAL' was printed to STDOUT — a fatal condition is a stderr + non-zero-exit event, not a line inside the report body"
    elif grep -aqE '^Estimate: |^\*\*Point estimate SUPPRESSED|^## Leave-one-out delta' "$wd/nrt.out"; then
      bad "SE-11d: an UNREQUESTED estimate / delta section rendered for a target that cannot be back-tested"
    elif [ -s "$wd/nrt.out" ]; then
      bad "SE-11d: the refused run still wrote $(wc -c <"$wd/nrt.out" | tr -d ' ') byte(s) to stdout — a refusal renders nothing"
    else
      ok "SE-11d NO-ROLLUP-ROW: --delta $NRT (derivable key, no rollup row) exits $nrtrc with FATAL on STDERR, empty stdout, and no unrequested estimate"
    fi
    #    Paired POSITIVE control — a target that DOES carry a rollup row still runs,
    #    or the gate is refusing every --delta rather than the rowless case.
    ( STORE="$wd/main" bash "$SELF" --delta 'milestone:v9.94' >/dev/null 2>&1 ); nrtrc=$?
    [ "$nrtrc" -eq 0 ] \
      && ok "SE-11d control: a --delta target that DOES carry a rollup row still runs (exit 0) — the gate is not refusing every --delta" \
      || bad "SE-11d control: a --delta target WITH a rollup row was refused (exit $nrtrc) — over-rejection"
  fi

  #    Paired POSITIVE control — on an un-suppressed delta the SAME fields must
  #    still render, or the fix is blanket nulling rather than a suppression gate.
  local pc_del pc_pct
  pc_del="$(jq -r '.delta_tokens // "null"' "$wd/delta.json" 2>/dev/null || echo null)"
  pc_pct="$(jq -r '.pct_error // "null"' "$wd/delta.json" 2>/dev/null || echo null)"
  if [ "$pc_del" != "null" ] && [ "$pc_pct" != "null" ]; then
    ok "SE-11c control: an UN-suppressed delta still emits delta=$pc_del and pct_error=$pc_pct — the gate is tied to \$show_point, not blanket nulling"
  else
    bad "SE-11c control: an un-suppressed delta lost its derived fields (delta=$pc_del, pct_error=$pc_pct) — over-suppression"
  fi

  # ── SE-12 SIZE-SCALE — --size M resolves to 4 pts; an out-of-set size -> exit 2. ──
  if run_est "$wd/size.json" "$wd/main" --class novel --size M --json; then
    [ "$(jq -r '.matching.target.points' "$wd/size.json")" = "4" ] \
      && ok "SE-12 SIZE-SCALE: --size M resolves to 4 points via the canonical scale" \
      || bad "SE-12 SIZE-SCALE: --size M did not resolve to 4 points"
  fi
  ( STORE="$wd/main" bash "$SELF" --class novel --size XXL >/dev/null 2>"$wd/sz.err" ); rc=$?
  if [ "$rc" -eq 2 ] && grep -aq 'unrecognized size label' "$wd/sz.err"; then
    ok "SE-12 SIZE-SCALE: an out-of-set size is a source-integrity violation (exit 2), never coerced to a nearest bucket"
  else
    bad "SE-12 SIZE-SCALE: out-of-set size exited $rc (want 2) / message missing"
  fi

  # ── SE-13 EXIT CODES — every documented code reachable and distinct. ──
  local codes_ok=1
  ( STORE="$wd/main" bash "$SELF" --nope >/dev/null 2>&1 ); [ $? -eq 2 ] || { bad "SE-13: unknown flag did not exit 2"; codes_ok=0; }
  ( STORE="$wd/main" bash "$SELF" --like 'x' --class y >/dev/null 2>&1 ); [ $? -eq 2 ] || { bad "SE-13: mutual-exclusion violation did not exit 2"; codes_ok=0; }
  ( STORE="$wd/absent" bash "$SELF" --class novel --points 16 >/dev/null 2>&1 ); [ $? -eq 3 ] || { bad "SE-13: missing store did not exit 3"; codes_ok=0; }
  ( STORE="$wd/nocov" bash "$SELF" --class novel --points 16 >/dev/null 2>&1 ); [ $? -eq 3 ] || { bad "SE-13: coverage-less store did not exit 3"; codes_ok=0; }
  [ "$codes_ok" -eq 1 ] && ok "SE-13 EXIT CODES (2 usage x2 · 3 unreadable · 3 not-rolled-up · 4 guard via SE-1b)"

  # ── SE-14 ORACLE — --json equals the committed oracle modulo estimated_utc. ──
  if [ -f "$oracle" ]; then
    if diff <(jq -S 'del(.estimated_utc, .generator_version)' "$oracle") \
            <(jq -S 'del(.estimated_utc, .generator_version)' "$JS") >/dev/null 2>&1; then
      ok "SE-14 oracle (--json matches estimate.expected.json modulo estimated_utc)"
    else
      bad "SE-14 oracle: --json diverged from estimate.expected.json"
      diff <(jq -S 'del(.estimated_utc, .generator_version)' "$oracle") \
           <(jq -S 'del(.estimated_utc, .generator_version)' "$JS") 2>/dev/null | head -20
    fi
  else
    bad "SE-14 oracle: estimate.expected.json missing — an absent oracle is a FAIL, not a skip"
  fi

  # ── SE-15 E3 POOLED RATE — a thin class falls through to the pooled tier and
  #    is capped MEDIUM by C-RATE (the linearity-in-points assumption is unverified). ──
  if run_est "$wd/e3.json" "$wd/main" --class thin-population --points 4 --json; then
    local e3t e3c e3caps
    e3t="$(jq -r '.matching.tier' "$wd/e3.json")"
    e3c="$(jq -r '.confidence' "$wd/e3.json")"
    e3caps="$(jq -r '[.confidence_caps[].cap]|join(",")' "$wd/e3.json")"
    if [ "$e3t" = "E3" ] && [ "$e3c" = "MEDIUM" ] && grep -aq 'C-RATE' <<<"$e3caps"; then
      ok "SE-15 E3: a 2-member class falls through to the pooled tokens-per-point tier, capped MEDIUM by C-RATE"
    else
      bad "SE-15 E3: got tier=$e3t confidence=$e3c caps=[$e3caps] (want E3 / MEDIUM / C-RATE)"
    fi
  fi

  unset FINOPS_RELEASE_LOG
  rm -rf "$wd"
  if [ "$FAILN" -eq 0 ]; then echo "finops-usage-extractor estimate --self-test: PASS"; return 0; fi
  echo "finops-usage-extractor estimate --self-test: FAIL"; return 1
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
