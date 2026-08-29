#!/usr/bin/env bash
# test_check73_bundle_metrics_discrimination.sh — the discrimination fixture suite
# for Check 73 (bundle-metrics-gate-integrity), the G3-14 / G3-15 gate machinery.
#
# Cite the code under test by its FUNCTION NAME, never by line number:
#   core/deploy/deploy.sh — _g3_14_compute_verdict(), _g3_15_compute_verdict(),
#                           _c73_compute_verdict()
#   Resolver: grep -n '_c73_compute_verdict()' core/deploy/deploy.sh
#
# WHAT THIS PROVES, AND WHY A GREEN GATE RUN IS NOT THE SAME THING.
# G3-14 and G3-15 shipped as prose-declared predicates with NO RUNNER ON ANY
# SURFACE. Building the runner is only half the job: a runner that answers the
# same way to a breaching and a conforming population is not a gate, it is a
# constant that happens to read green. This suite drives BOTH directions of each
# gate on every run, so the instrument's sensitivity AND specificity are measured
# rather than assumed — the test_version_freeness_injection.sh shape.
#
# SINGLE ENGINE. The verdict bodies are EXTRACTED FROM deploy.sh AT RUN TIME by
# function name and sourced into this process. Nothing here re-encodes a
# predicate: a copy would drift from the shipped body silently, and drift in the
# thing under test is what makes a green arm meaningless. If an extraction comes
# back empty the suite fails at Arm A rather than passing on nothing.
#
# THE BOUNDARY FIXTURES ARE THE POINT. Both specificity fixtures sit EXACTLY at
# their threshold — the parse rate at the floor, effective_pts at the band upper
# bound. A specificity fixture comfortably inside the threshold cannot tell a
# correct `>=` from an incorrect `>`, so it would certify a comparator it never
# tested. At the boundary, the two seeded mutations below each flip exactly one
# arm.
#
# THREE STATES, AND THE TRANSPORT EACH TAKES.
#   PASS           the arm ran and the verdict was as expected      -> exit 0
#   FAIL           the arm ran and the verdict was WRONG — the       -> exit 1
#                  instrument has lost sensitivity or specificity
#   NOT-EVALUATED  the arm COULD NOT RUN — deploy.sh unreadable, an  -> exit 0
#                  extraction empty, a fixture unresolvable
#
# The FAIL / NOT-EVALUATED split is load-bearing and is the version-freeness
# contract verbatim. This suite's consumer is a workflow step runner, which
# escalates ANY non-zero step exit to a failed job; carrying an outage on a
# non-zero exit would convert an environment condition into a merge-blocking
# gate. The unevaluated state therefore crosses IN-BAND — exit 0 carrying an
# explicit marker and the words "this is not a clean result" — and is never
# silently folded into a pass.
#
# SCOPE BOUNDARY. This suite asserts the INSTRUMENT, not the posture, and not the
# live backlog. It says nothing about the real Mode-A parse rate or any real
# milestone's effective_pts: that half of the predicate is backlog-resident, has
# no repo-path Verdict-Input Closure, and stays advisory permanently (ADR-162).

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SH="${SCRIPT_DIR}/../deploy.sh"
SRC_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
FIXTURES="${SCRIPT_DIR}/fixtures/bundle-metrics"

PASS_COUNT=0; FAIL_COUNT=0; NOTEVAL_COUNT=0
pass() { PASS_COUNT=$((PASS_COUNT+1)); printf '  PASS  %s\n' "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT+1)); printf '::error::%s\n' "$1"; printf '  FAIL  %s\n' "$1"; }
note() { printf '        %s\n' "$1"; }
not_evaluated() {
  NOTEVAL_COUNT=$((NOTEVAL_COUNT+1))
  printf '::warning::NOT-EVALUATED — %s — this is not a clean result\n' "$1"
  printf '  NOT-EVALUATED — %s — this is not a clean result\n' "$1"
}
TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT

echo "Check 73 bundle-metrics discrimination — G3-14 / G3-15 gate machinery"
echo "─────────────────────────────────────────────────────────────────────────"

# ── Extraction ──────────────────────────────────────────────────────────────
# Per-function anchors, no sentinel markers: a sibling card inserting a new
# top-level verdict body next to these would collide with a region sentinel, and
# per-function anchors make that insertion invisible here.
extract_fn() { /usr/bin/sed -n "/^$1() {\$/,/^}\$/p" "$DEPLOY_SH"; }

BODIES="$TMPD/bodies.sh"
FN_SET=(_bm_src_root _bm_config_template _bm_config_line _bm_dec_scale
        _bm_class_weight _bm_size_pts _g3_14_compute_verdict
        _g3_15_compute_verdict _c73_compute_verdict)

if [[ ! -r "$DEPLOY_SH" ]]; then
  not_evaluated "deploy.sh unreadable at $DEPLOY_SH — no body could be extracted, so no arm ran"
  echo "─────────────────────────────────────────────────────────────────────────"
  echo "PASS $PASS_COUNT · FAIL $FAIL_COUNT · NOT-EVALUATED $NOTEVAL_COUNT"
  exit 0
fi

: > "$BODIES"
_extract_ok=1
for _fn in "${FN_SET[@]}"; do
  _body="$(extract_fn "$_fn")"
  if [[ -z "$_body" ]]; then
    fail "A extraction of ${_fn}() from deploy.sh is EMPTY — the function was renamed or its anchor moved"
    _extract_ok=0
  else
    printf '%s\n\n' "$_body" >> "$BODIES"
  fi
done

# ── Arm A — extraction non-vacuity ──────────────────────────────────────────
# A silently-empty or silently-truncated extraction would make every arm below
# pass on nothing. Each discriminating token is a thing the body MUST contain for
# the arms to be testing what they claim.
if [[ "$_extract_ok" -eq 1 ]]; then
  _a_ok=1
  _all="$(cat "$BODIES")"
  [[ "$_all" == *'_rate4 -ge $_floor4'*   ]] || { _a_ok=0; fail "A the G3-14 body carries no '>=' floor comparison — the comparator under test is gone"; }
  [[ "$_all" == *'_eff -le $_bound'*      ]] || { _a_ok=0; fail "A the G3-15 body carries no '<=' band comparison — the comparator under test is gone"; }
  [[ "$_all" == *'C73-a'*                 ]] || { _a_ok=0; fail "A the Check-73 body carries no C73-a conjunct"; }
  [[ "$_all" == *'C73-b'*                 ]] || { _a_ok=0; fail "A the Check-73 body carries no C73-b conjunct"; }
  [[ "$_all" == *'C73-c'*                 ]] || { _a_ok=0; fail "A the Check-73 body carries no C73-c conjunct"; }
  [[ "$_all" == *'deferred'*              ]] || { _a_ok=0; fail "A the G3-14 body carries no deferred-exclusion arm"; }
  if [[ "$_a_ok" -eq 1 ]]; then
    # shellcheck source=/dev/null
    source "$BODIES"
    pass "A all ${#FN_SET[@]} verdict bodies extracted from deploy.sh and carry their discriminating tokens"
    note "denominator: $(/usr/bin/grep -c . "$BODIES") non-blank line(s) extracted"
  else
    _extract_ok=0
  fi
fi

if [[ "$_extract_ok" -ne 1 ]]; then
  echo "─────────────────────────────────────────────────────────────────────────"
  echo "PASS $PASS_COUNT · FAIL $FAIL_COUNT · NOT-EVALUATED $NOTEVAL_COUNT"
  echo "Check 73 discrimination: FAIL (extraction)"
  exit 1
fi

export PMO_BM_SRC_ROOT="$SRC_ROOT"

# ── Arm-state ledger, consumed by assert_arms_ran ───────────────────────────
ARMS_RUN=0
declare -a G3_14_VERDICTS=() G3_15_VERDICTS=()

# ── assert_g3_14_discriminates ──────────────────────────────────────────────
# Sensitivity: a sub-floor population must BREACH.
# Specificity: an AT-floor population must PASS. Both arms are required; either
# one alone is satisfiable by a constant.
assert_g3_14_discriminates() {
  local _f _want _v _tok
  for _f in "below-floor.tsv:BREACH" "at-floor.tsv:PASS"; do
    _want="${_f#*:}"; _f="${_f%%:*}"
    if [[ ! -r "${FIXTURES}/g3-14/${_f}" ]]; then
      not_evaluated "g3-14 fixture ${_f} is unresolvable at ${FIXTURES}/g3-14/ — this arm did not run"
      continue
    fi
    _v="$(_g3_14_compute_verdict "${FIXTURES}/g3-14/${_f}")"
    _tok="${_v%% *}"
    ARMS_RUN=$((ARMS_RUN+1)); G3_14_VERDICTS+=("$_tok")
    if [[ "$_tok" == "$_want" ]]; then
      pass "g3-14 ${_f} -> ${_tok} (expected ${_want})"
      note "$_v"
    else
      fail "g3-14 ${_f} -> ${_tok}, expected ${_want} — the parse-rate gate has lost $( [[ "$_want" == BREACH ]] && echo sensitivity || echo specificity ): $_v"
    fi
  done
}

# ── assert_g3_15_discriminates ──────────────────────────────────────────────
assert_g3_15_discriminates() {
  local _f _want _v _tok
  for _f in "above-band.tsv:BREACH" "in-band.tsv:PASS"; do
    _want="${_f#*:}"; _f="${_f%%:*}"
    if [[ ! -r "${FIXTURES}/g3-15/${_f}" ]]; then
      not_evaluated "g3-15 fixture ${_f} is unresolvable at ${FIXTURES}/g3-15/ — this arm did not run"
      continue
    fi
    _v="$(_g3_15_compute_verdict "${FIXTURES}/g3-15/${_f}")"
    _tok="${_v%% *}"
    ARMS_RUN=$((ARMS_RUN+1)); G3_15_VERDICTS+=("$_tok")
    if [[ "$_tok" == "$_want" ]]; then
      pass "g3-15 ${_f} -> ${_tok} (expected ${_want})"
      note "$_v"
    else
      fail "g3-15 ${_f} -> ${_tok}, expected ${_want} — the size-bound gate has lost $( [[ "$_want" == BREACH ]] && echo sensitivity || echo specificity ): $_v"
    fi
  done
}

# ── assert_c73b_discriminates ───────────────────────────────────────────────
# C73-b's emitter limb has an EMPTY population on the tree that introduces this
# check — no emitter writes either gate's sink yet. A conjunct whose population
# is empty passes vacuously, and a vacuous conjunct inside a conjunction is
# indistinguishable from an assertion that holds. This arm drives C73-b against
# sandbox declaration/emitter pairs in BOTH directions so the conjunct's
# discrimination is measured on every run rather than deferred to whenever an
# emitter eventually lands.
assert_c73b_discriminates() {
  local _spec="$TMPD/spec.md" _emit="$TMPD/emitter.sh" _v _tok
  local _real="\$(pmo_instance_path)/gate-g3-14-warn-log.jsonl"
  local _real15="\$(pmo_instance_path)/gate-g3-15-warn-log.jsonl"

  _c73b_case() {  # <label> <expected-token> <must-contain-on-fail>
    _v="$(C73_SPEC_FILE="$_spec" C73_EMITTER_FILE="$_emit" C73_FIXTURE_ROOT="$FIXTURES" _c73_compute_verdict gate)"
    _tok="${_v%% *}"
    if [[ "$_tok" != "$2" ]]; then
      fail "C73-b $1 -> ${_tok}, expected $2: $_v"; return
    fi
    if [[ "$2" == "FAIL" && "$_v" != *"$3"* ]]; then
      fail "C73-b $1 FAILed for the wrong reason (expected a $3 finding): $_v"; return
    fi
    pass "C73-b $1 -> ${_tok}"
  }

  # b1 — coherent declarations, ZERO emitters. The tree-as-shipped shape.
  { printf 'G3-14 logs to %s\n' "$_real"; printf 'self-repair: %s\n' "$_real"
    printf 'G3-15 logs to %s\n' "$_real15"; printf 'self-repair: %s\n' "$_real15"; } > "$_spec"
  : > "$_emit"
  _c73b_case "b1 coherent declarations / 0 emitters" PASS ""

  # b2 — the SAME gate declared at two DIFFERENT paths. This is the limb that
  # carries the conjunct today, and it is a real defect class: the shipped spec
  # states each sink twice (criterion row + self-repair row), so a one-sided
  # prefix repair silently splits them.
  { printf 'G3-14 logs to %s\n' "$_real"; printf 'self-repair: core/hooks/gate-g3-14-warn-log.jsonl\n'
    printf 'G3-15 logs to %s\n' "$_real15"; printf 'self-repair: %s\n' "$_real15"; } > "$_spec"
  : > "$_emit"
  _c73b_case "b2 same gate declared at two paths" FAIL "C73-b"

  # b3 — declaration and emitter AGREE. The state after an emitter lands.
  { printf 'G3-14 logs to %s\n' "$_real"; printf 'self-repair: %s\n' "$_real"
    printf 'G3-15 logs to %s\n' "$_real15"; printf 'self-repair: %s\n' "$_real15"; } > "$_spec"
  printf 'printf "%%s" >> "%s"\n' "$_real" > "$_emit"
  _c73b_case "b3 declaration and emitter agree" PASS ""

  # b4 — declaration and emitter DISAGREE. Without this arm b3 would pass against
  # a predicate hardwired to report agreement.
  printf 'printf "%%s" >> "core/hooks/gate-g3-14-warn-log.jsonl"\n' > "$_emit"
  _c73b_case "b4 declaration and emitter disagree" FAIL "C73-b"
}

# ── assert_arms_ran — the anti-vacuity control ──────────────────────────────
# Non-zero unless all four discrimination arms EXECUTED and each gate produced an
# OPPOSITE-VERDICT PAIR. Four green arms that all returned the same token would
# mean the instrument answers one way regardless of input, which is precisely the
# state this check exists to make impossible — and every individual arm can be
# made to pass by deleting the arm that contradicts it.
assert_arms_ran() {
  local _ok=1
  if [[ "$ARMS_RUN" -ne 4 ]]; then
    fail "anti-vacuity: ${ARMS_RUN} of 4 discrimination arms executed — a suite that skipped an arm certifies coverage it never demonstrated"
    _ok=0
  fi
  local _g
  for _g in 14 15; do
    local -n _ref="G3_${_g}_VERDICTS"
    local _uniq
    _uniq="$(printf '%s\n' "${_ref[@]+"${_ref[@]}"}" | /usr/bin/sort -u | /usr/bin/grep -c . || true)"
    if [[ "${_uniq:-0}" -ne 2 ]]; then
      fail "anti-vacuity: g3-${_g} produced ${_uniq:-0} distinct verdict(s) across its arms, not an opposite-verdict pair — the gate answers the same way to a breaching and a conforming population"
      _ok=0
    fi
  done
  [[ "$_ok" -eq 1 ]] && pass "anti-vacuity: 4/4 arms executed; both gates produced an opposite-verdict pair"
}

assert_g3_14_discriminates
assert_g3_15_discriminates
assert_c73b_discriminates
assert_arms_ran

echo "─────────────────────────────────────────────────────────────────────────"
echo "PASS $PASS_COUNT · FAIL $FAIL_COUNT · NOT-EVALUATED $NOTEVAL_COUNT"
if [[ "$FAIL_COUNT" -gt 0 ]]; then
  echo "Check 73 discrimination: FAIL — a wrong arm verdict is an instrument regression, and it gates."
  exit 1
fi
if [[ "$NOTEVAL_COUNT" -gt 0 ]]; then
  echo "Check 73 discrimination: NOT-EVALUATED on $NOTEVAL_COUNT arm(s) — exit 0 by contract (a measurement outage must never gate a merge), but this is NOT a clean result."
  exit 0
fi
echo "Check 73 discrimination: PASS — both gates discriminate; C73-b discriminates in both directions."
exit 0
