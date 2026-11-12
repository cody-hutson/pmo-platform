#!/usr/bin/env bash
# convert-usage.sh — the ONE conversion from per-response token totals to weekly points.
#
# Converts token totals in the usage store's `tokens` shape into weekly points (wp) of
# one account, at BOTH ends of the cache-read-weight bracket. What a weekly point is, how
# tokens are counted, the conversion's terms and the pair rule are canonical in
# {{ADR:release-graph-cost-unit}}; this script implements that record's conversion and
# restates none of its calibrated values. Every figure-producing tool — the per-release
# cost row, the command-template ranking — calls THIS script and never re-implements the
# weights: one conversion, one numeric home.
#
# THE NUMERIC HOME. Every calibrated value is read from the [cost_unit] section of the
# platform behaviour configuration, on two rungs, the individual rung winning:
#   rung 1  global default — <src-root>/core/config/platform-config.toml.template
#   rung 5  individual     — ${PMO_PLATFORM_CONFIG_ROOT:-$HOME/.config/pmo-platform}/platform-config.toml
# Rungs 2-4 do not apply: the calibration is per plan and per account (the section's own
# header says why). <src-root> resolves as PMO_SRC_ROOT, else the checkout this script
# sits in (four levels up) when that checkout holds the template, else
# ${CLAUDE_WORKSPACE_ROOT}/pmo-platform. A packaged copy of the skill sits outside any
# checkout, so it reads rung 1 through one of the two variables or not at all.
#
# FAIL CLOSED. A numeric value that is absent at every rung, empty, or not a valid
# positive number — or a bracket whose low end is not below its high end — exits 3 and
# names the key and the rungs read. The caller then records an UNRESOLVED figure: never
# zero and never a built-in constant (a zero K divides by zero; a zero weight erases a
# token type from every figure). The calibration model and the per-model axis are
# optional by design: absent reads as "none named" / "none probed", which is their
# documented meaning, not a substituted value.
#
# THE READER is section-aware and is the core/hooks/lib/master-enable.sh _me_read_field
# awk body VERBATIM, parameterized on the file exactly as release/tools/lib/platform-toggle.sh
# parameterized it. That library cannot be sourced from here — core never depends on
# release/ — so this is the third copy, kept byte-equivalent on purpose: two readers of one
# TOML dialect "cleaned up" independently are two dialects.
#
# THE FORMULA, per end e of the bracket (low and high):
#   W_e  = input + c5*ephemeral_5m + c1*ephemeral_1h + c5*(total - ephemeral_1h - ephemeral_5m)
#          + o*output + w_e*cache_read
#   wp_e = W_e / K_e
# c5, c1 and o are the price-relative weights of a five-minute cache write, a one-hour
# cache write and an output token; w_e is the cache-read weight and K_e the weighted
# tokens per weekly point AT THAT END. The low end uses the low w AND the low K; a figure
# never mixes one end's w with the other's K, and no midpoint is ever formed. Thinking is
# inside output. A cache write with no tier split (total above the two tiers) is weighted
# at the five-minute tier.
#
# THE PAIR IS KEYED BY BRACKET END — at_w_low, at_w_high — never "low"/"high". Which of
# the two is larger depends on the token mix: an output- or write-heavy figure is LARGER
# at the low-w end, because that end's K is smaller. Neither member is a lower bound.
#
# THE PER-MODEL AXIS. When an object carries the store's exact per-model split
# (`by_model`), its figure is summed per model: a model with a recorded draw multiplier
# contributes multiplier * W_e / K_e; the calibration model contributes at 1; any other
# model is UNPROBED, contributes at 1 and is named in `unprobed_models`; a model whose
# recorded weekly windows exclude "all-models" draws no weekly points, is named in
# `own_window_models`, and is not summed. An object without a split is one figure at the
# shared values and reads `per_model: "not-split"`.
#
# THE CALIBRATION LABEL is "calibration: sufficient" or "calibration: insufficient", read
# from the latest dated seed or revisit line of the cost unit's row in the gate-coverage
# register (<src-root>/core/standards/gate-efficacy-standard.md, population
# cost-unit-calibration-revisits) — the line every revisit leaves. When the register
# cannot be read it is "calibration: unresolved"; the figures are still computed.
#
# Usage:
#   bash convert-usage.sh --convert < objects.json   # JSON array in; one JSON object out
#   bash convert-usage.sh --params                   # the resolved values, as JSON
#   bash convert-usage.sh --self-test                # offline arms over temporary configs
#   bash convert-usage.sh --help
#
# --convert reads a JSON array. Each element is either a `tokens` object
#   {input, output, cache_creation:{total, ephemeral_1h, ephemeral_5m}, cache_read}
# or {"tokens": <tokens>, "by_model": {<model-id>: <tokens> | {"tokens": <tokens>, ...}}},
# whose split must sum to its tokens leaf by leaf. It writes, in input order:
#   {"params": {<the ten keys>, "source": "template|individual|template+individual"},
#    "label": "calibration: …", "label_source": "<register path>|unreadable",
#    "pairs": [{"at_w_low": f, "at_w_high": f, "per_model": "split|not-split",
#               "unprobed_models": [...], "own_window_models": [...]}, ...]}
#
# Exit codes: 0 ok · 1 usage error or missing dependency (jq) · 2 malformed input (not an
#   array; a missing, non-numeric or negative leaf; tiers above their total; a per-model
#   split that does not sum to its tokens) · 3 unresolved value (absent at every rung,
#   empty, not a valid positive number, or a bracket whose low end is not below its high
#   end; stderr names the key and the rungs read).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The ten keys of [cost_unit]: seven numeric (fail closed), three optional.
NUMERIC_KEYS="cache_read_weight_low cache_read_weight_high tokens_per_weekly_point_low tokens_per_weekly_point_high cache_write_5m_weight cache_write_1h_weight output_weight"
COST_SECTION="cost_unit"
REGISTER_REL="core/standards/gate-efficacy-standard.md"
REGISTER_POPULATION="cost-unit-calibration-revisits"
DECIMAL_RE='^[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?$'
TAB=$'\t'

usage() {
  local last
  last="$(awk '/^set -uo pipefail/{print NR; exit}' "${BASH_SOURCE[0]}")"
  sed -n "2,$(( last - 2 ))p" "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 0
}

die() { printf 'ERROR: %s\n' "$1" >&2; exit "${2:-1}"; }

need_jq() {
  command -v jq >/dev/null 2>&1 || die "missing dependency: jq — see SKILL.md ## Dependencies" 1
}

# _cu_src_root — the checkout whose template is rung 1; empty when none holds it.
_cu_src_root() {
  if [ -n "${PMO_SRC_ROOT:-}" ]; then
    printf '%s' "$PMO_SRC_ROOT"
    return 0
  fi
  local here
  here="$(cd "$SCRIPT_DIR/../../../.." 2>/dev/null && pwd)" || here=""
  if [ -n "$here" ] && [ -r "$here/core/config/platform-config.toml.template" ]; then
    printf '%s' "$here"
    return 0
  fi
  if [ -n "${CLAUDE_WORKSPACE_ROOT:-}" ] && [ -r "${CLAUDE_WORKSPACE_ROOT}/pmo-platform/core/config/platform-config.toml.template" ]; then
    printf '%s' "${CLAUDE_WORKSPACE_ROOT}/pmo-platform"
    return 0
  fi
  return 0
}

_cu_template_file() {
  local root
  root="$(_cu_src_root)"
  [ -n "$root" ] && printf '%s/core/config/platform-config.toml.template' "$root"
  return 0
}

_cu_config_file() {
  printf '%s/platform-config.toml' "${PMO_PLATFORM_CONFIG_ROOT:-${HOME}/.config/pmo-platform}"
}

# _cu_read_field FILE SECTION KEY — echo the raw value of KEY within [SECTION] of FILE, or
# empty. The awk body is core/hooks/lib/master-enable.sh _me_read_field VERBATIM, with the
# file taken as a parameter (the release/tools/lib/platform-toggle.sh _pt_read_field form).
# Never exits; empty on miss / unreadable file / read error.
_cu_read_field() {
  local _cu_file="$1"; local _cu_sect="$2"; local _cu_key="$3"
  [ -n "$_cu_file" ] && [ -r "$_cu_file" ] || return 0
  [ -x /usr/bin/awk ] || return 0
  /usr/bin/awk -v sect="[${_cu_sect}]" -v key="$_cu_key" '
    # Section header line: string-compare (trimmed) against the target header so a
    # "[" in a value can never be misread as a section, and so no regex-in-brackets
    # ambiguity arises from the section name.
    /^[[:space:]]*\[/ {
      line = $0
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      insect = (line == sect) ? 1 : 0
      next
    }
    insect == 1 && $0 ~ ("^[[:space:]]*" key "[[:space:]]*=") {
      line = $0
      sub(/^[^=]*=[[:space:]]*/, "", line)   # strip "key ="
      sub(/[[:space:]]*#.*$/, "", line)        # strip inline comment
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)  # trim
      gsub(/^"|"$/, "", line)                  # strip surrounding double-quotes
      print line
      exit
    }
  ' "$_cu_file" 2>/dev/null || true
}

# Resolution state, filled by resolve_params.
P_JSON=""
P_SOURCE=""

# _cu_inline_table RAW — a TOML inline table of quoted keys as compact JSON on stdout;
# exit non-zero when it does not parse. {} and an absent key both read as {}.
_cu_inline_table() {
  local raw="$1"
  [ -z "$raw" ] && raw="{}"
  printf '%s' "$raw" | sed -e 's/"\([^"]*\)"[[:space:]]*=/"\1":/g' | jq -c 'if type == "object" then . else error("not a table") end' 2>/dev/null
}

# resolve_params — read the ten keys on both rungs into P_JSON and P_SOURCE, or exit 3.
resolve_params() {
  local tmpl cfg key v_t v_i val used_t=0 used_i=0 json="{}" rungs t_note="" c_note=""
  tmpl="$(_cu_template_file)"
  cfg="$(_cu_config_file)"
  [ -n "$tmpl" ] && [ ! -r "$tmpl" ] && t_note=" (unreadable)"
  [ -r "$cfg" ] || c_note=" (absent)"
  rungs="template ${tmpl:-<none: no checkout holds core/config/platform-config.toml.template; set PMO_SRC_ROOT>}${t_note} · individual ${cfg}${c_note}"
  for key in $NUMERIC_KEYS; do
    v_t="$(_cu_read_field "$tmpl" "$COST_SECTION" "$key")"
    v_i="$(_cu_read_field "$cfg" "$COST_SECTION" "$key")"
    if [ -n "$v_i" ]; then val="$v_i"; used_i=1
    elif [ -n "$v_t" ]; then val="$v_t"; used_t=1
    else
      printf 'FATAL (exit 3): [%s].%s is absent or empty at every rung read (%s) — the figure is UNRESOLVED; no default is substituted\n' "$COST_SECTION" "$key" "$rungs" >&2
      exit 3
    fi
    case "$key" in
      tokens_per_weekly_point_*)
        val="$(printf '%s' "$val" | sed 's/\([0-9]\)_\([0-9]\)/\1\2/g')"
        case "$val" in
          ''|*[!0-9]*) printf 'FATAL (exit 3): [%s].%s = %s is not a positive integer — the figure is UNRESOLVED\n' "$COST_SECTION" "$key" "$val" >&2; exit 3 ;;
        esac ;;
      *)
        if ! [[ "$val" =~ $DECIMAL_RE ]]; then
          printf 'FATAL (exit 3): [%s].%s = %s is not a decimal number — the figure is UNRESOLVED\n' "$COST_SECTION" "$key" "$val" >&2
          exit 3
        fi ;;
    esac
    json="$(jq -c --arg k "$key" --argjson v "$val" '. + {($k): $v}' <<<"$json")" || {
      printf 'FATAL (exit 3): [%s].%s = %s could not be read as a number\n' "$COST_SECTION" "$key" "$val" >&2; exit 3; }
  done
  # Positivity and the bracket's order: a zero K divides by zero, a zero weight erases a
  # token type, and a bracket whose low end is not below its high end is not a bracket.
  local bad
  bad="$(jq -r '[ to_entries[] | select(.value <= 0) | .key ] + (if .cache_read_weight_low >= .cache_read_weight_high then ["cache_read_weight_low >= cache_read_weight_high"] else [] end) + (if .cache_read_weight_high > 1 then ["cache_read_weight_high > 1.0"] else [] end) | join(", ")' <<<"$json")"
  if [ -n "$bad" ]; then
    printf 'FATAL (exit 3): [%s] holds an invalid value (%s) — the figure is UNRESOLVED\n' "$COST_SECTION" "$bad" >&2
    exit 3
  fi
  # The optional axis: individual rung first, absent = none named / none probed.
  local cal mult win
  cal="$(_cu_read_field "$cfg" "$COST_SECTION" calibration_model)"
  [ -n "$cal" ] && used_i=1
  [ -z "$cal" ] && cal="$(_cu_read_field "$tmpl" "$COST_SECTION" calibration_model)"
  v_i="$(_cu_read_field "$cfg" "$COST_SECTION" model_draw_multipliers)"
  if [ -n "$v_i" ]; then mult="$v_i"; used_i=1; else mult="$(_cu_read_field "$tmpl" "$COST_SECTION" model_draw_multipliers)"; fi
  v_i="$(_cu_read_field "$cfg" "$COST_SECTION" model_weekly_windows)"
  if [ -n "$v_i" ]; then win="$v_i"; used_i=1; else win="$(_cu_read_field "$tmpl" "$COST_SECTION" model_weekly_windows)"; fi
  local mult_j win_j
  mult_j="$(_cu_inline_table "$mult")" || { printf 'FATAL (exit 3): [%s].model_draw_multipliers does not parse as an inline table of quoted model ids\n' "$COST_SECTION" >&2; exit 3; }
  win_j="$(_cu_inline_table "$win")" || { printf 'FATAL (exit 3): [%s].model_weekly_windows does not parse as an inline table of quoted model ids\n' "$COST_SECTION" >&2; exit 3; }
  if ! jq -e 'all(.[]; type == "number" and . > 0)' <<<"$mult_j" >/dev/null 2>&1; then
    printf 'FATAL (exit 3): [%s].model_draw_multipliers holds a value that is not a number above 0\n' "$COST_SECTION" >&2
    exit 3
  fi
  if ! jq -e 'all(.[]; type == "string")' <<<"$win_j" >/dev/null 2>&1; then
    printf 'FATAL (exit 3): [%s].model_weekly_windows holds a value that is not a string\n' "$COST_SECTION" >&2
    exit 3
  fi
  if [ "$used_t" -eq 1 ] && [ "$used_i" -eq 1 ]; then P_SOURCE="template+individual"
  elif [ "$used_i" -eq 1 ]; then P_SOURCE="individual"
  else P_SOURCE="template"; fi
  P_JSON="$(jq -c --arg cal "$cal" --argjson m "$mult_j" --argjson w "$win_j" --arg src "$P_SOURCE" \
    '. + {calibration_model: $cal, model_draw_multipliers: $m, model_weekly_windows: $w, source: $src}' <<<"$json")"
}

# calibration_label — "<label>\t<source>" from the register's latest dated line.
calibration_label() {
  local root reg line verdict
  root="$(_cu_src_root)"
  reg="${root:+$root/$REGISTER_REL}"
  if [ -z "$reg" ] || [ ! -r "$reg" ]; then
    printf 'calibration: unresolved%sunreadable' "$TAB"
    return 0
  fi
  line="$(grep -F -- "$REGISTER_POPULATION" "$reg" 2>/dev/null | grep -F -- '| **class 3-O.**' || true)"
  verdict="$(printf '%s\n' "$line" | grep -oE '(seed|revisit) · [0-9]{4}-[0-9]{2}-[0-9]{2} · [^`]* · calibration (sufficient|insufficient)' | sed -n '$p' | sed -E 's/.*calibration (sufficient|insufficient)$/\1/')"
  if [ -z "$verdict" ]; then
    printf 'calibration: unresolved%sunreadable' "$TAB"
    return 0
  fi
  printf 'calibration: %s%s%s' "$verdict" "$TAB" "$REGISTER_REL"
}

read -r -d '' JQ_CONVERT <<'JQEOF' || true
def leaves($t): [ $t.input, $t.output, $t.cache_read, $t.cache_creation.total,
                  $t.cache_creation.ephemeral_1h, $t.cache_creation.ephemeral_5m ];
def check($t; $where):
  if ($t | type) != "object" or ($t.cache_creation | type) != "object" then
    error("\($where): not a tokens object {input, output, cache_creation:{total, ephemeral_1h, ephemeral_5m}, cache_read}")
  elif (leaves($t) | all(type == "number" and . >= 0)) | not then
    error("\($where): a token leaf is missing, non-numeric or negative")
  elif ($t.cache_creation.ephemeral_1h + $t.cache_creation.ephemeral_5m) > $t.cache_creation.total then
    error("\($where): the cache-write tiers exceed their total")
  else $t end;
def W($t; $w):
  $t.input
  + $p.cache_write_5m_weight * $t.cache_creation.ephemeral_5m
  + $p.cache_write_1h_weight * $t.cache_creation.ephemeral_1h
  + $p.cache_write_5m_weight * ($t.cache_creation.total - $t.cache_creation.ephemeral_1h - $t.cache_creation.ephemeral_5m)
  + $p.output_weight * $t.output
  + $w * $t.cache_read;
def endpair($t; $mult):
  { at_w_low:  ($mult * W($t; $p.cache_read_weight_low)  / $p.tokens_per_weekly_point_low),
    at_w_high: ($mult * W($t; $p.cache_read_weight_high) / $p.tokens_per_weekly_point_high) };
def mtok: if (type == "object") and has("tokens") then .tokens else . end;
def own_window($m): ($p.model_weekly_windows[$m] // null) as $w
  | ($w != null) and (($w | split(",") | map(gsub("^\\s+|\\s+$"; "")) | index("all-models")) == null);
if type != "array" then error("input is not a JSON array") else . end
| [ to_entries[] | .key as $i | .value as $o
    | ( if ($o | type) == "object" and ($o | has("tokens")) then $o.tokens else $o end ) as $t
    | check($t; "object \($i)") as $_
    | if ($o | type) == "object" and ($o | has("by_model")) and ($o.by_model != null) then
        ( $o.by_model | to_entries | map({m: .key, t: (.value | mtok)}) ) as $split
        | ( $split | map(check(.t; "object \($i) model \(.m)")) ) as $_c
        | ( [ range(0; 6) as $k | ([ $split[] | leaves(.t)[$k] ] | add // 0) ] ) as $sums
        | if $sums != leaves($t) then error("object \($i): the per-model split does not sum to its tokens") else . end
        | ( [ $split[] | select(own_window(.m) | not) ] ) as $drawn
        | ( [ $drawn[] | .m as $m
              | ( if $m == $p.calibration_model and $m != "" then 1
                  else ($p.model_draw_multipliers[$m] // 1) end ) as $mult
              | endpair(.t; $mult) ] ) as $parts
        | { at_w_low:  ([ $parts[].at_w_low ]  | add // 0),
            at_w_high: ([ $parts[].at_w_high ] | add // 0),
            per_model: "split",
            unprobed_models: [ $drawn[] | .m as $m
                               | select(($m == $p.calibration_model and $m != "") | not)
                               | select($p.model_draw_multipliers | has($m) | not) | $m ] | sort,
            own_window_models: [ $split[] | select(own_window(.m)) | .m ] | sort }
      else endpair($t; 1) + { per_model: "not-split", unprobed_models: [], own_window_models: [] }
      end ]
| { params: $p, label: $label, label_source: $label_source, pairs: . }
JQEOF

cmd_convert() {
  need_jq
  resolve_params
  local lab label label_source input out
  lab="$(calibration_label)"
  label="${lab%%"$TAB"*}"
  label_source="${lab#*"$TAB"}"
  input="$(cat)"
  if ! out="$(jq -c --argjson p "$P_JSON" --arg label "$label" --arg label_source "$label_source" "$JQ_CONVERT" <<<"$input" 2>&1)"; then
    printf 'ERROR (exit 2): malformed input — %s\n' "$out" >&2
    exit 2
  fi
  printf '%s\n' "$out"
}

cmd_params() {
  need_jq
  resolve_params
  printf '%s\n' "$P_JSON"
}

# ─── Self-test (offline; every arm pins both rung seams to temporary files) ───────
CU_ST_TMP=""
self_test() {
  need_jq
  local T fail=0 out rc err
  CU_ST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/convert-usage-selftest-XXXXXX")" || die "self-test: mktemp failed" 1
  trap 'rm -rf "$CU_ST_TMP"' EXIT
  T="$CU_ST_TMP"
  mkdir -p "$T/src/core/config" "$T/src/core/standards" "$T/cfg" "$T/nosrc" "$T/emptycfg"

  ok()   { printf 'PASS: %s\n' "$1"; }
  bad()  { printf 'FAIL: %s\n' "$1"; fail=1; }
  near() { jq -en --argjson a "$1" --argjson b "$2" '(($a - $b) | fabs) < 1e-9' >/dev/null 2>&1; }

  # Synthetic values ONLY — never the shipped calibration (the record moves it; a pinned
  # seed would turn a sanctioned recalibration red). c5 1.5 · c1 3 · o 4 · w 0.02..0.2 ·
  # K 1000 / 4000.
  write_template() {
    local wl="${1:-0.02}" wh="${2:-0.2}" kl="${3:-1000}" kh="${4:-4000}" o="${5:-4}" cal="${6:-}" mu="${7:-}" wi="${8:-}"
    [ -n "$mu" ] || mu='{}'
    [ -n "$wi" ] || wi='{}'
    {
      printf '[other_section]\ncache_read_weight_low = 9.0\n\n[cost_unit]\n'
      printf 'cache_read_weight_low = %s\ncache_read_weight_high = %s\n' "$wl" "$wh"
      printf 'tokens_per_weekly_point_low = %s\ntokens_per_weekly_point_high = %s\n' "$kl" "$kh"
      printf 'cache_write_5m_weight = 1.5\ncache_write_1h_weight = 3\noutput_weight = %s\n' "$o"
      printf 'calibration_model = "%s"\nmodel_draw_multipliers = %s\nmodel_weekly_windows = %s\n' "$cal" "$mu" "$wi"
    } > "$T/src/core/config/platform-config.toml.template"
  }
  run() { PMO_SRC_ROOT="$T/src" PMO_PLATFORM_CONFIG_ROOT="$T/emptycfg" bash "${BASH_SOURCE[0]}" "$@"; }
  write_template

  # T1 — a hand-computed pair, inverted order (CD-2): W_low = 100+30+30+15+200+20 = 395 →
  # 395/1000; W_high = 100+30+30+15+200+200 = 575 → 575/4000.
  local tok1='{"input":100,"output":50,"cache_creation":{"total":40,"ephemeral_1h":10,"ephemeral_5m":20},"cache_read":1000}'
  out="$(printf '[%s]' "$tok1" | run --convert)"; rc=$?
  if [ "$rc" -eq 0 ] && near "$(jq '.pairs[0].at_w_low' <<<"$out")" 0.395 && near "$(jq '.pairs[0].at_w_high' <<<"$out")" 0.14375; then
    ok "T1 hand-computed pair (at_w_low 0.395 > at_w_high 0.14375: an output-heavy figure is larger at the low-w end)"
  else bad "T1 hand-computed pair: rc $rc, got $out"; fi

  # T2 — the unsplit cache-write remainder is weighted at the five-minute tier: tiers 0/0
  # of a 40 total → 100 + 1.5*40 + 200 + 20 = 380 (at the one-hour tier it would be 440).
  out="$(printf '[{"input":100,"output":50,"cache_creation":{"total":40,"ephemeral_1h":0,"ephemeral_5m":0},"cache_read":1000}]' | run --convert)"
  if near "$(jq '.pairs[0].at_w_low' <<<"$out")" 0.38; then ok "T2 unsplit remainder at the five-minute tier"
  else bad "T2 unsplit remainder: got $(jq -c '.pairs[0]' <<<"$out")"; fi

  # T3 — the pair rule on a cache-read-only figure: the low end is 0.02*10000/1000 = 0.2 and
  # the high end 0.2*10000/4000 = 0.5 (conventional order). A cross-end mix gives 0.05 or
  # 2.0; a midpoint w gives neither.
  out="$(printf '[{"input":0,"output":0,"cache_creation":{"total":0,"ephemeral_1h":0,"ephemeral_5m":0},"cache_read":10000}]' | run --convert)"
  if near "$(jq '.pairs[0].at_w_low' <<<"$out")" 0.2 && near "$(jq '.pairs[0].at_w_high' <<<"$out")" 0.5; then
    ok "T3 pair rule (each end uses its own w and its own K; no midpoint, no cross-end mix)"
  else bad "T3 pair rule: got $(jq -c '.pairs[0]' <<<"$out")"; fi

  # T4 — fail closed: a numeric key absent at both rungs exits 3 and names the key.
  sed '/^output_weight/d' "$T/src/core/config/platform-config.toml.template" > "$T/t4" && mv "$T/t4" "$T/src/core/config/platform-config.toml.template"
  err="$(printf '[%s]' "$tok1" | run --convert 2>&1 >/dev/null)"; rc=$?
  if [ "$rc" -eq 3 ] && [ "${err#*output_weight}" != "$err" ]; then ok "T4 absent key fails closed (exit 3, key named)"
  else bad "T4 absent key: rc $rc, stderr $err"; fi
  # T4b — the same key EMPTY is not a value either.
  write_template 0.02 0.2 1000 4000 '""'
  err="$(printf '[%s]' "$tok1" | run --convert 2>&1 >/dev/null)"; rc=$?
  if [ "$rc" -eq 3 ]; then ok "T4b empty value fails closed (exit 3)"; else bad "T4b empty value: rc $rc"; fi
  # T4c — a same-named key under ANOTHER section is not read (the reader is section-aware):
  # [other_section] carries cache_read_weight_low; with [cost_unit]'s deleted, exit 3.
  write_template
  awk '/^\[cost_unit\]/{s=1} !(s && /^cache_read_weight_low/)' "$T/src/core/config/platform-config.toml.template" > "$T/t4c" && mv "$T/t4c" "$T/src/core/config/platform-config.toml.template"
  printf '[%s]' "$tok1" | run --convert >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq 3 ]; then ok "T4c a same-named key in another section is not read"; else bad "T4c section-blind read: rc $rc"; fi

  # T5 — the individual rung wins over the template, key by key.
  write_template
  printf '[cost_unit]\ntokens_per_weekly_point_low = 2000\n' > "$T/cfg/platform-config.toml"
  out="$(printf '[%s]' "$tok1" | PMO_SRC_ROOT="$T/src" PMO_PLATFORM_CONFIG_ROOT="$T/cfg" bash "${BASH_SOURCE[0]}" --convert)"
  if near "$(jq '.pairs[0].at_w_low' <<<"$out")" 0.1975 && near "$(jq '.pairs[0].at_w_high' <<<"$out")" 0.14375 \
     && [ "$(jq -r '.params.source' <<<"$out")" = "template+individual" ]; then
    ok "T5 individual rung overrides one key; the source names both rungs"
  else bad "T5 individual override: got $(jq -c '{p: .pairs[0], s: .params.source}' <<<"$out")"; fi

  # T6 — a bracket whose low end is not below its high end is refused.
  write_template 0.2 0.2
  printf '[%s]' "$tok1" | run --convert >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq 3 ]; then ok "T6 malformed bracket refused (exit 3)"; else bad "T6 malformed bracket: rc $rc"; fi

  # T7 — no checkout holds the template and the individual rung is empty: exit 3, the
  # cause names the missing template (the packaged-copy case).
  write_template
  err="$(printf '[%s]' "$tok1" | PMO_SRC_ROOT="$T/nosrc" PMO_PLATFORM_CONFIG_ROOT="$T/emptycfg" bash "${BASH_SOURCE[0]}" --convert 2>&1 >/dev/null)"; rc=$?
  if [ "$rc" -eq 3 ] && [ "${err#*absent or empty at every rung}" != "$err" ] && [ "${err#*(unreadable)}" != "$err" ]; then
    ok "T7 no template reachable fails closed with the rungs named"
  else bad "T7 unreachable template: rc $rc, stderr $err"; fi

  # T8 — the per-model axis: model a at multiplier 0.5, model b unprobed, model c draws
  # only a model-specific window. Each model carries tok1, so the figure is
  # 0.5*0.395 + 0.395 = 0.5925 at the low end; c is listed, not summed.
  write_template 0.02 0.2 1000 4000 4 "" '{ "model-a" = 0.5 }' '{ "model-c" = "model-specific" }'
  out="$(jq -cn --argjson t "$tok1" '[{tokens: {input: 300, output: 150, cache_creation: {total: 120, ephemeral_1h: 30, ephemeral_5m: 60}, cache_read: 3000},
          by_model: {"model-a": {turns: 1, tokens: $t}, "model-b": $t, "model-c": {tokens: $t}}}]' | run --convert)"
  if near "$(jq '.pairs[0].at_w_low' <<<"$out")" 0.5925 \
     && [ "$(jq -c '[.pairs[0].unprobed_models, .pairs[0].own_window_models, .pairs[0].per_model]' <<<"$out")" = '[["model-b"],["model-c"],"split"]' ]; then
    ok "T8 per-model axis (multiplier applied; unprobed named; own-window model listed, not summed)"
  else bad "T8 per-model axis: got $(jq -c '.pairs[0]' <<<"$out")"; fi
  # T8b — the calibration model needs no entry and is not unprobed.
  write_template 0.02 0.2 1000 4000 4 "model-b" '{ "model-a" = 0.5 }' '{}'
  out="$(jq -cn --argjson t "$tok1" '[{tokens: {input: 200, output: 100, cache_creation: {total: 80, ephemeral_1h: 20, ephemeral_5m: 40}, cache_read: 2000},
          by_model: {"model-a": $t, "model-b": $t}}]' | run --convert)"
  if [ "$(jq -c '.pairs[0].unprobed_models' <<<"$out")" = '[]' ] && near "$(jq '.pairs[0].at_w_low' <<<"$out")" 0.5925; then
    ok "T8b the calibration model is not unprobed"
  else bad "T8b calibration model: got $(jq -c '.pairs[0]' <<<"$out")"; fi
  # T8c — a split that does not sum to its tokens is malformed (exit 2).
  jq -cn --argjson t "$tok1" '[{tokens: $t, by_model: {"model-a": $t, "model-b": $t}}]' | run --convert >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq 2 ]; then ok "T8c a split that does not sum is refused (exit 2)"; else bad "T8c split sum: rc $rc"; fi

  # T9 — malformed input: not an array, a missing leaf, a negative leaf, tiers above total.
  write_template
  local m9 c9=0
  for m9 in '{"input":1}' '[{"input":1,"output":1,"cache_read":1}]' \
            '[{"input":-1,"output":0,"cache_creation":{"total":0,"ephemeral_1h":0,"ephemeral_5m":0},"cache_read":0}]' \
            '[{"input":0,"output":0,"cache_creation":{"total":1,"ephemeral_1h":1,"ephemeral_5m":1},"cache_read":0}]'; do
    printf '%s' "$m9" | run --convert >/dev/null 2>&1; rc=$?
    [ "$rc" -eq 2 ] && c9=$((c9 + 1))
  done
  if [ "$c9" -eq 4 ]; then ok "T9 four malformed inputs each exit 2"; else bad "T9 malformed inputs: $c9 of 4 exited 2"; fi

  # T10 — the calibration label comes from the register's LATEST dated line; the format
  # template line (YYYY-MM-DD) is never read as one; an unreadable register is unresolved.
  printf '| **class 3-O.** rule. **Population:** `%s` | gap | prose | advisory | `revisit · YYYY-MM-DD · <run> · calibration <sufficient or insufficient> · values <changed>` <br>`seed · 2020-01-01 · census · eligible pairs 0 (pooled 0) · calibration insufficient · values seeded`<br>`revisit · 2020-02-01 · run · eligible pairs 3 (pooled 3) · excluded 0 () · pairs held at x · calibration sufficient · values changed` |\n' \
    "$REGISTER_POPULATION" > "$T/src/core/standards/gate-efficacy-standard.md"
  out="$(printf '[%s]' "$tok1" | run --convert)"
  if [ "$(jq -r '.label' <<<"$out")" = "calibration: sufficient" ]; then ok "T10 label from the latest dated register line"
  else bad "T10 register label: got $(jq -r '.label' <<<"$out")"; fi
  printf '| **class 3-O.** rule. **Population:** `%s` | `revisit · YYYY-MM-DD · <run> · calibration sufficient · values x` <br>`seed · 2020-01-01 · census · eligible pairs 0 (pooled 0) · calibration insufficient · values seeded` |\n' \
    "$REGISTER_POPULATION" > "$T/src/core/standards/gate-efficacy-standard.md"
  out="$(printf '[%s]' "$tok1" | run --convert)"
  if [ "$(jq -r '.label' <<<"$out")" = "calibration: insufficient" ]; then ok "T10b the undated format line is never read as a revisit"
  else bad "T10b format line read as a revisit: got $(jq -r '.label' <<<"$out")"; fi
  rm -f "$T/src/core/standards/gate-efficacy-standard.md"
  out="$(printf '[%s]' "$tok1" | run --convert)"
  if [ "$(jq -r '[.label, .label_source] | join("|")' <<<"$out")" = "calibration: unresolved|unreadable" ] && near "$(jq '.pairs[0].at_w_low' <<<"$out")" 0.395; then
    ok "T10c unreadable register: label unresolved, figures still computed"
  else bad "T10c unreadable register: got $(jq -c '{label, label_source}' <<<"$out")"; fi

  # T11 — the shipped template resolves: seven positive numbers, low end below high end.
  # (Values are not pinned: the record moves them by editing the numeric home alone.)
  local repo_root
  repo_root="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
  if [ -r "$repo_root/core/config/platform-config.toml.template" ]; then
    out="$(PMO_SRC_ROOT="$repo_root" PMO_PLATFORM_CONFIG_ROOT="$T/emptycfg" bash "${BASH_SOURCE[0]}" --params)"; rc=$?
    if [ "$rc" -eq 0 ] && jq -e '(.cache_read_weight_low < .cache_read_weight_high) and ([.cache_read_weight_low, .cache_read_weight_high, .tokens_per_weekly_point_low, .tokens_per_weekly_point_high, .cache_write_5m_weight, .cache_write_1h_weight, .output_weight] | all(type == "number" and . > 0)) and (.source == "template")' <<<"$out" >/dev/null; then
      ok "T11 the shipped template's [cost_unit] resolves on rung 1"
    else bad "T11 shipped template: rc $rc, got $out"; fi
  else
    ok "T11 skipped — no checkout around this copy (packaged skill); T7 covers that case"
  fi

  if [ "$fail" -eq 0 ]; then echo "convert-usage self-test: PASS"; return 0; fi
  echo "convert-usage self-test: FAIL"
  return 1
}

case "${1:-}" in
  --convert)   cmd_convert ;;
  --params)    cmd_params ;;
  --self-test) self_test; exit $? ;;
  --help|-h)   usage ;;
  *)           printf 'usage: convert-usage.sh --convert | --params | --self-test | --help\n' >&2; exit 1 ;;
esac
