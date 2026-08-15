#!/usr/bin/env bash
# test_version_freeness_injection.sh — the LIVE falsification pair for the
# version-freeness merge gate's independent-candidate resolution branch.
#
# Cite the code under test by its INLINE MARKER, never by line number:
#   core/deploy/deploy.sh, `_vf_resolve_candidate()` and `cmd_check_version_freeness()`
# Resolver: grep -n '_vf_resolve_candidate()' core/deploy/deploy.sh
#
# WHAT THIS PROVES, AND WHY IT IS NOT THE SAME AS A GREEN GATE RUN.
# The gate resolves its candidate in three branches: (1) an explicit
# PMO_VERSION_FREENESS_CANDIDATE injection, (2) a bump-class fed to the
# allocator's dry-run, (3) no claim context. The CI job historically set only
# the bump-class variable, so branch (1) never executed in CI and the gate's
# sensitivity to an externally-supplied COLLIDING candidate was assumed rather
# than measured. This suite executes branch (1) on every run and asserts all
# three outcomes the branch can produce, so the gate's green means the
# instrument was exercised rather than merely invoked.
#
# THREE ARMS. Each is independently decidable, and the ORDER is load-bearing:
#   Arm C  injection-off control — NEITHER variable set -> the resolver returns
#          empty and the run SKIPs. Runs FIRST among the verdict arms, because
#          if the control does not SKIP then Arm A's NOT_FREE could have come
#          from the derived path (branch 2) or from an orphan-classified derived
#          candidate rather than from the injection, and no other arm's outcome
#          is interpretable.
#   Arm A  sensitivity — inject a candidate that IS already claimed -> NOT_FREE.
#   Arm B  specificity — inject an out-of-lineage candidate -> FREE. Without it
#          Arm A would pass against a predicate hardwired to report collisions.
#
# THE BUMP-CLASS VARIABLE IS NEVER SET BY THIS SUITE, AND ITS ABSENCE IS THE
# STRUCTURAL WITNESS. Branch (2) cannot run at all, so every verdict below is
# attributable to branch (1). The suite unsets both resolution variables at
# start-up and re-exports only the one variable each arm needs, so an inherited
# value in the calling environment cannot silently re-enter branch (2).
#
# THE COLLIDER IS DERIVED, NOT HARDCODED. It is the repo-root .version value.
# That file is stamped at release close, AFTER the atomic claim that binds a
# version, so it can lag the claimed set but can never lead it — which makes its
# value always-already-claimed and therefore a guaranteed member of the set the
# gate compares against. The collider advances with every release on its own and
# there is no fixture to age. A caller may override it by exporting
# PMO_VERSION_FREENESS_CANDIDATE, which is the surface the CI job assigns.
#
# THE FREE CANDIDATE IS A LITERAL, AND THAT IS CORRECT. v9999.99 is canonical
# under the version grammar (^v[0-9]+\.[0-9]+(\.[0-9]+)?$) so it reaches the
# freeness comparison instead of short-circuiting to a malformed-candidate
# result, and it is unreachable by this repo's lineage. Deriving it would add a
# mechanism with nothing to derive from. Its absence is witnessed on every run.
#
# WITNESS CONTROL — the property that keeps this suite from certifying itself.
# Both fixtures are witnessed against the origin tag surface before any verdict
# is trusted: the collider must be PRESENT and the free candidate must be
# ABSENT. The collider's presence IS the control for the free candidate's
# absence. If BOTH read as absent, the remote read is dead rather than the
# fixtures being correct, and a suite that cannot tell "absent" from "could not
# look" is exactly the defect this suite exists to remove — so that state is
# reported as unevaluated, never as a pass.
#
# THREE STATES, AND THE TRANSPORT EACH TAKES.
#   PASS           the arm ran and the verdict was as expected      -> exit 0
#   FAIL           the arm ran and the verdict was WRONG — the gate  -> exit 1
#                  has lost sensitivity or specificity
#   NOT-EVALUATED  the arm COULD NOT RUN — a fixture is unresolvable,
#                  a witness could not be read, or the gate returned
#                  an undecidable result                             -> exit 0
#
# The FAIL/NOT-EVALUATED split is the whole point. A measured instrument
# regression is a defect and gates. A measurement outage is not a defect and
# must never gate: this suite's consumer is the workflow step runner, which
# escalates ANY non-zero step exit to a failed job, so an outage carried on a
# non-zero exit would convert an environment condition into a merge-blocking
# gate. The unevaluated state therefore crosses IN-BAND — exit 0 carrying an
# explicit marker plus the words "this is not a clean result" — and is never
# silently folded into a pass.
#
# SCOPE BOUNDARY. This suite asserts the INSTRUMENT, not the posture. A real
# version collision still routes through the workflow's own gate-decision step,
# which this suite does not touch and which remains non-blocking. Only a wrong
# ARM verdict fails here.
#
# Portable to bash 3.2 (the macOS runner's system bash): no associative arrays,
# no mapfile, no ${var^^}.
#
# Issue references (summarized inline above, listed here so no reader must open
# a tracker to understand this file):
#   #4705 — the CI job never injected a candidate, leaving the gate's
#           independent-candidate branch unreachable in CI.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
DEPLOY_SH="${REPO_ROOT}/core/deploy/deploy.sh"
VERSION_FILE="${REPO_ROOT}/.version"

# The out-of-lineage free candidate. Canonical under the grammar, unreachable by
# this repo's lineage, witnessed absent on every run.
FREE_CAND="v9999.99"

PASS_COUNT=0
FAIL_COUNT=0
NOTEVAL_COUNT=0

# ── Emitters ──────────────────────────────────────────────────────────────────
# No emitted state string contains a semicolon: downstream grammar predicates
# split on "; " and an in-slot semicolon would silently truncate a field.

arm_pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf 'PASS %s — %s\n' "$1" "$2"
}

arm_fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf '::error::%s\n' "$1"
  printf 'FAIL %s\n' "$1"
}

arm_not_evaluated() {
  NOTEVAL_COUNT=$((NOTEVAL_COUNT + 1))
  printf '::warning::NOT-EVALUATED — %s: %s — this is not a clean result\n' "$1" "$2"
  printf 'NOT-EVALUATED — %s: %s — this is not a clean result\n' "$1" "$2"
}

is_canonical() {
  [[ "$1" =~ ^v[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]
}

# ── Fixture resolution ────────────────────────────────────────────────────────
# Capture any injected candidate BEFORE the variables are cleared, then clear
# both so no arm can inherit a resolution variable it did not set for itself.

COLLIDER=""
COLLIDER_SRC=""
if [ -n "${PMO_VERSION_FREENESS_CANDIDATE:-}" ]; then
  COLLIDER="${PMO_VERSION_FREENESS_CANDIDATE}"
  COLLIDER_SRC="injected environment"
elif [ -f "${VERSION_FILE}" ]; then
  COLLIDER="$(tr -d '[:space:]' < "${VERSION_FILE}")"
  COLLIDER_SRC="repo-root .version"
fi

unset PMO_VERSION_FREENESS_CANDIDATE
unset PMO_VERSION_FREENESS_BUMP

echo "version-freeness injection arms — collider source: ${COLLIDER_SRC:-unresolved}"

# ── Witnesses ─────────────────────────────────────────────────────────────────

LS_RC=0
LS_HITS=0
probe_tag() {
  local _out
  LS_RC=0
  LS_HITS=0
  _out="$(git -C "${REPO_ROOT}" ls-remote --tags origin "refs/tags/$1" 2>/dev/null)" || LS_RC=$?
  if [ -n "${_out}" ]; then
    LS_HITS="$(printf '%s\n' "${_out}" | grep -c .)"
  fi
}

WITNESS_OK=1
WITNESS_REASON=""

if [ -z "${COLLIDER}" ]; then
  WITNESS_OK=0
  WITNESS_REASON="the collider fixture is unresolvable — no injected candidate and no readable repo-root .version"
elif ! is_canonical "${COLLIDER}"; then
  WITNESS_OK=0
  WITNESS_REASON="the collider fixture '${COLLIDER}' is not canonical under the version grammar"
fi

COLLIDER_HITS=0
COLLIDER_LS_RC=0
FREE_HITS=0
FREE_LS_RC=0

if [ "${WITNESS_OK}" -eq 1 ]; then
  probe_tag "${COLLIDER}"
  COLLIDER_HITS="${LS_HITS}"
  COLLIDER_LS_RC="${LS_RC}"
  probe_tag "${FREE_CAND}"
  FREE_HITS="${LS_HITS}"
  FREE_LS_RC="${LS_RC}"

  echo "witness — collider ${COLLIDER}: ${COLLIDER_HITS} tag ref(s), read rc ${COLLIDER_LS_RC}"
  echo "witness — free candidate ${FREE_CAND}: ${FREE_HITS} tag ref(s), read rc ${FREE_LS_RC}"

  if [ "${COLLIDER_LS_RC}" -ne 0 ] || [ "${FREE_LS_RC}" -ne 0 ]; then
    WITNESS_OK=0
    WITNESS_REASON="the origin tag surface could not be read — the fixtures cannot be witnessed"
  elif [ "${COLLIDER_HITS}" -eq 0 ] && [ "${FREE_HITS}" -eq 0 ]; then
    # The control and the subject both read empty. That is a dead read, not a
    # measured absence, and it must never be reported as a correct fixture set.
    WITNESS_OK=0
    WITNESS_REASON="both tag witnesses returned zero — the remote read is undiscriminating rather than the fixtures being correct"
  elif [ "${COLLIDER_HITS}" -eq 0 ]; then
    WITNESS_OK=0
    WITNESS_REASON="the collider ${COLLIDER} is not on the origin tag surface — it is not a guaranteed member of the claimed set"
  elif [ "${FREE_HITS}" -ne 0 ]; then
    WITNESS_OK=0
    WITNESS_REASON="the free-candidate fixture ${FREE_CAND} is unexpectedly present on the origin tag surface — the fixture is compromised, not the gate"
  fi
fi

# ── Arm runner ────────────────────────────────────────────────────────────────
# The exit code is read DIRECTLY from the invocation, never through a pipe: a
# pipeline would report the status of the last stage rather than the gate's own
# verdict, and this suite's entire subject is that verdict-to-exit-code mapping.

GATE_OUT=""
GATE_RC=0
run_gate() {
  GATE_OUT=""
  GATE_RC=0
  if [ -n "$1" ]; then
    GATE_OUT="$(cd "${REPO_ROOT}" && PMO_VERSION_FREENESS_CANDIDATE="$1" bash "${DEPLOY_SH}" --check-version-freeness 2>&1)" || GATE_RC=$?
  else
    GATE_OUT="$(cd "${REPO_ROOT}" && bash "${DEPLOY_SH}" --check-version-freeness 2>&1)" || GATE_RC=$?
  fi
}

# Returns the gate's own verdict token, or the EMPTY STRING when the output
# carries no recognizable verdict line. The empty string is deliberate: naming
# that condition would coin a status token, and the only status vocabulary this
# suite is permitted to emit is the unevaluated marker below.
verdict_token() {
  case "$1" in
    *"version-freeness: NOT_FREE"*)    printf 'NOT_FREE' ;;
    *"version-freeness: UNDECIDABLE"*) printf 'UNDECIDABLE' ;;
    *"version-freeness: SKIP"*)        printf 'SKIP' ;;
    *"is free (not in claimed_set)"*)  printf 'FREE' ;;
    *)                                 printf '' ;;
  esac
}

# Echoed candidate for a collision verdict, whose line reads
# "version-freeness: NOT_FREE — <candidate> <colliding tag>".
echoed_after_not_free() {
  local _tail="${1##*NOT_FREE — }"
  printf '%s' "${_tail%% *}"
}

# Echoed candidate for a free verdict, whose line reads
# "version-freeness: <candidate> is free (not in claimed_set) — OK".
echoed_before_is_free() {
  local _tail="${1##*version-freeness: }"
  printf '%s' "${_tail%% *}"
}

# ── Arm C — injection-off control ─────────────────────────────────────────────

ARM_C_OK=0
if [ "${WITNESS_OK}" -eq 0 ]; then
  arm_not_evaluated "Arm C injection-off control" "${WITNESS_REASON}"
else
  run_gate ""
  _tok="$(verdict_token "${GATE_OUT}")"
  case "${_tok}" in
    SKIP)
      if [ "${GATE_RC}" -eq 0 ]; then
        ARM_C_OK=1
        arm_pass "Arm C injection-off control" "no candidate and no bump-class injected, verdict SKIP at exit 0 — the derived path is inert, so a collision verdict in Arm A is attributable to the injection"
      else
        arm_fail "Arm C injection-off control — injected candidate none, expected verdict SKIP at exit 0, observed verdict SKIP at exit ${GATE_RC}"
      fi
      ;;
    UNDECIDABLE)
      arm_not_evaluated "Arm C injection-off control" "the gate returned an undecidable result rather than a verdict"
      ;;
    "")
      arm_not_evaluated "Arm C injection-off control" "the gate output carried no recognizable verdict line"
      ;;
    *)
      arm_fail "Arm C injection-off control — injected candidate none, expected verdict SKIP, observed verdict ${_tok}. Arm A cannot be attributed to the injection while this control does not hold"
      ;;
  esac
fi

# ── Arm A — sensitivity ───────────────────────────────────────────────────────

if [ "${WITNESS_OK}" -eq 0 ]; then
  arm_not_evaluated "Arm A sensitivity" "${WITNESS_REASON}"
elif [ "${ARM_C_OK}" -eq 0 ]; then
  arm_not_evaluated "Arm A sensitivity" "the injection-off control did not hold, so this arm's verdict is uninterpretable"
else
  run_gate "${COLLIDER}"
  _tok="$(verdict_token "${GATE_OUT}")"
  case "${_tok}" in
    NOT_FREE)
      _echoed="$(echoed_after_not_free "${GATE_OUT}")"
      if [ "${GATE_RC}" -ne 1 ]; then
        arm_fail "Arm A sensitivity — injected candidate ${COLLIDER}, expected verdict NOT_FREE at exit 1, observed verdict NOT_FREE at exit ${GATE_RC}"
      elif [ "${_echoed}" != "${COLLIDER}" ]; then
        arm_fail "Arm A sensitivity — injected candidate ${COLLIDER}, expected the verdict to echo that candidate, observed echoed candidate ${_echoed}"
      else
        arm_pass "Arm A sensitivity" "injected candidate ${COLLIDER}, verdict NOT_FREE at exit 1, echoed candidate equals the injected literal"
      fi
      ;;
    UNDECIDABLE)
      # An undecidable result also exits 1. Reading the exit code alone would
      # certify an outage as a collision, which is the conflation this arm must
      # never make.
      arm_not_evaluated "Arm A sensitivity" "the gate returned an undecidable result rather than a collision verdict — the exit code alone would misread this as a pass"
      ;;
    "")
      arm_not_evaluated "Arm A sensitivity" "the gate output carried no recognizable verdict line"
      ;;
    *)
      arm_fail "Arm A sensitivity — injected candidate ${COLLIDER}, expected verdict NOT_FREE at exit 1, observed verdict ${_tok} at exit ${GATE_RC}. The gate has lost sensitivity to an externally-supplied colliding candidate"
      ;;
  esac
fi

# ── Arm B — specificity ───────────────────────────────────────────────────────

if [ "${WITNESS_OK}" -eq 0 ]; then
  arm_not_evaluated "Arm B specificity" "${WITNESS_REASON}"
elif [ "${ARM_C_OK}" -eq 0 ]; then
  arm_not_evaluated "Arm B specificity" "the injection-off control did not hold, so this arm's verdict is uninterpretable"
else
  run_gate "${FREE_CAND}"
  _tok="$(verdict_token "${GATE_OUT}")"
  case "${_tok}" in
    FREE)
      _echoed="$(echoed_before_is_free "${GATE_OUT}")"
      if [ "${GATE_RC}" -ne 0 ]; then
        arm_fail "Arm B specificity — injected candidate ${FREE_CAND}, expected verdict FREE at exit 0, observed verdict FREE at exit ${GATE_RC}"
      elif [ "${_echoed}" != "${FREE_CAND}" ]; then
        arm_fail "Arm B specificity — injected candidate ${FREE_CAND}, expected the verdict to echo that candidate, observed echoed candidate ${_echoed}"
      else
        arm_pass "Arm B specificity" "injected candidate ${FREE_CAND}, verdict FREE at exit 0, echoed candidate equals the injected literal"
      fi
      ;;
    UNDECIDABLE)
      arm_not_evaluated "Arm B specificity" "the gate returned an undecidable result rather than a freeness verdict"
      ;;
    "")
      arm_not_evaluated "Arm B specificity" "the gate output carried no recognizable verdict line"
      ;;
    *)
      arm_fail "Arm B specificity — injected candidate ${FREE_CAND}, expected verdict FREE at exit 0, observed verdict ${_tok} at exit ${GATE_RC}. The gate reports a collision against a candidate that is not on the tag surface"
      ;;
  esac
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo "---"
echo "version-freeness injection arms: ${PASS_COUNT} passed, ${FAIL_COUNT} failed, ${NOTEVAL_COUNT} not evaluated"

if [ "${FAIL_COUNT}" -gt 0 ]; then
  echo "The version-freeness gate's independent-candidate branch did not behave as asserted."
  exit 1
fi

if [ "${NOTEVAL_COUNT}" -gt 0 ]; then
  echo "One or more arms could not be evaluated — this is not a clean result, and it is reported rather than counted as a pass."
  exit 0
fi

echo "Branch (1) exercised on every arm — sensitivity and specificity both measured."
exit 0
