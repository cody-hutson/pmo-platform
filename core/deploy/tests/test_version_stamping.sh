#!/usr/bin/env bash
# test_version_stamping.sh — regression test for the .version release-cut-ownership
# fix (#1643). Sibling to test_notify_version_skew.sh.
#
# Guards the 3-layer fix:
#   L2 — release/tools/automated-closeout.sh phase_bump_version:
#        writes + (implicitly) stages .version for a versioned $VERSION,
#        SKIPs-with-PASS for a version-less / non-vX.Y $VERSION, is monotone
#        (never regresses .version; equality is a limb).
#   L3 — core/deploy/deploy.sh Check 39 comparison algorithm:
#        anchored on the latest PUBLISHED Release, .version == anchor -> PASS,
#        exactly 1 published-minor apart -> WARN (Stage-12->13 window),
#        >=2 published-minors apart OR different major-lineage -> FAIL.
#
# Layering note: phase_bump_version is exercised by SOURCING the close-out script
# (functions only — its top-level `Main` block is guarded so a sourced load is a
# no-op via the --self-test early-exit path; see SOURCE_GUARD below). Check 39 is
# embedded inside deploy.sh's cmd_check() (a 5000-line function that shells a live
# `gh api`), so the algorithm-level invariant is re-implemented here as the unit
# under test (the SAME parse + signed-minor-distance logic deploy.sh Check 39
# uses) and driven with controlled anchor/local pairs. The deploy.sh Check 39
# end-to-end behavior (live gh anchor; FAIL at v2.08; PASS once corrected) is
# demonstrated in the PR's Verification Evidence; this offline test guards the
# decision logic so CI can run it credential-free.
#
# Hermetic + offline: a private sandbox; no network call (phase_bump_version never
# shells gh, and Part 2 drives the Check 39 algorithm with literal inputs); no
# operator state touched. Portable: pure bash; runs on macOS CI and Linux alike.
#
# Run from repo root:
#   bash core/deploy/tests/test_version_stamping.sh
#
# Returns non-zero on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
CLOSEOUT_SRC="${REPO_ROOT}/release/tools/automated-closeout.sh"
# The Part-1 subshell REASSIGNS REPO_ROOT to its sandbox, so anything that must
# resolve against the REAL checkout after that point (the version-grammar SSOT the
# Part-3 arms call) has to capture the root here, before it is shadowed.
REPO_ROOT_REAL="${REPO_ROOT}"

PASS=0
FAIL=0
SBX=""

cleanup() {
  if [ -n "${SBX}" ] && [ -d "${SBX}" ]; then
    rm -rf "${SBX}"
  fi
}
trap cleanup EXIT

report() {
  local name="$1" passed="$2" detail="${3:-}"
  if [ "${passed}" = "1" ]; then
    printf '  PASS: %s\n' "${name}"
    PASS=$((PASS + 1))
  else
    printf '  FAIL: %s\n' "${name}"
    [ -n "${detail}" ] && printf '         %s\n' "${detail}"
    FAIL=$((FAIL + 1))
  fi
}

if [ ! -r "${CLOSEOUT_SRC}" ]; then
  printf 'FATAL: close-out script not found at %s\n' "${CLOSEOUT_SRC}" >&2
  exit 2
fi

SBX=$(mktemp -d -t version-stamping.XXXXXX)
printf '\nVersion-stamping regression (#1643) (bash %s)\n' "${BASH_VERSION:-unknown}"

# ─────────────────────────────────────────────────────────────────────────────
# Part 1 — L2: phase_bump_version (sourced from automated-closeout.sh)
# ─────────────────────────────────────────────────────────────────────────────
#
# We source a FUNCTION-ONLY slice of the close-out script (everything up to the
# "# ─── Argument parsing" banner) so its top-level Main block never runs on load.
# THREE load-time guards in that slice are neutralized for the offline harness,
# all irrelevant to phase_bump_version (which never calls gh, never needs the PATH
# pin, and never resolves an operator-instance path): (1) the
# `export PATH="/usr/bin:/bin"` pin is dropped so this harness's tools stay
# reachable; (2) the gh-resolution `exit 1` (fires when neither
# /opt/homebrew/bin/gh nor /usr/local/bin/gh exists — e.g. Linux CI) is rewritten
# to set GH to a harmless stub; (3) INSTANCE_LIB is REPOINTED at the real resolver
# in this checkout. The phase_bump_version logic itself is sourced verbatim — it
# is the unit under test.
#
# WHY (3) EXISTS, AND WHY IT PINS RATHER THAN DISABLES. The slice carries
# automated-closeout.sh's fail-closed `source "$INSTANCE_LIB"` guard. Inside the
# slice, SCRIPT_DIR resolves to ${SBX} (the sliced copy's own directory), so the
# script's own `REPO_ROOT="$SCRIPT_DIR/../.."` lands outside this repo and
# $REPO_ROOT/core/deploy/lib-instance-path.sh does not exist. The guard would then
# `exit 2` — inside the bv_result subshell, with the `source` already running under
# `2>/dev/null`, so the failure is SILENT and every Part-1 assertion fails with no
# stated cause.
#
# The pin points INSTANCE_LIB at the real library via this harness's own REPO_ROOT
# (the real repo, resolved at the top of this file), which PRESERVES the
# fail-closed guard rather than defeating it: a genuinely missing resolver still
# exits 2 and still surfaces. Neutralizing the guard instead (making it fail-open,
# or deleting the source) was considered and rejected — that would let this harness
# exercise a code path that resolves the instance root differently from production,
# which is the duplicate-resolution defect the source exists to remove.

CLOSEOUT_FUNCS="${SBX}/closeout-funcs.sh"
/usr/bin/sed -n '1,/^# ─── Argument parsing/p' "${CLOSEOUT_SRC}" \
  | /usr/bin/sed \
      -e '/^export PATH="\/usr\/bin:\/bin"/c\
: PATH-pin disabled for offline harness' \
      -e 's@^  exit 1$@  GH=/usr/bin/true@' \
      -e "s@^INSTANCE_LIB=.*@INSTANCE_LIB=\"${REPO_ROOT}/core/deploy/lib-instance-path.sh\"@" \
  > "${CLOSEOUT_FUNCS}"

# Run all phase_bump_version assertions inside one subshell so the sourced
# script's `set -euo pipefail` + globals do not leak into the harness. Emit one
# line per assertion: "name|0|detail" or "name|1|".
bv_result=$(
  set +e
  # shellcheck disable=SC1090
  source "${CLOSEOUT_FUNCS}" 2>/dev/null

  # Sandbox repo root + .version (override the script's REPO_ROOT global).
  REPO_ROOT="${SBX}/repo"
  mkdir -p "${REPO_ROOT}"
  MODE="apply"

  emit() { printf '%s\n' "$1"; }   # one line per assertion: "name|0/1|detail"

  # (a) version-less / non-vX.Y -> SKIPPED, .version untouched
  printf 'v2.08\n' > "${REPO_ROOT}/.version"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  VERSION="release-version-stamping"
  phase_bump_version >/dev/null 2>&1
  r="$(get_phase bump_version)"
  if [[ "$r" == SKIPPED\|* && "$(head -1 "${REPO_ROOT}/.version")" == "v2.08" ]]; then
    emit "phase_bump_version: version-less SKIP, .version untouched|1|"
  else
    emit "phase_bump_version: version-less SKIP, .version untouched|0|got '$r' / .version='$(head -1 "${REPO_ROOT}/.version")'"
  fi

  # (b) empty $VERSION -> SKIPPED (validate_version rejects empty)
  printf 'v2.08\n' > "${REPO_ROOT}/.version"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  VERSION=""
  phase_bump_version >/dev/null 2>&1
  r="$(get_phase bump_version)"
  if [[ "$r" == SKIPPED\|* && "$(head -1 "${REPO_ROOT}/.version")" == "v2.08" ]]; then
    emit "phase_bump_version: empty VERSION SKIP|1|"
  else
    emit "phase_bump_version: empty VERSION SKIP|0|got '$r'"
  fi

  # (c) versioned $VERSION, current != target -> PASS, .version written + single clean line
  printf 'v2.08\n' > "${REPO_ROOT}/.version"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  VERSION="v2.13"
  phase_bump_version >/dev/null 2>&1
  r="$(get_phase bump_version)"
  lines=$(wc -l < "${REPO_ROOT}/.version" | tr -d ' ')
  if [[ "$r" == PASS\|* && "$(head -1 "${REPO_ROOT}/.version")" == "v2.13" && "$lines" == "1" ]]; then
    emit "phase_bump_version: versioned apply writes .version (single line)|1|"
  else
    emit "phase_bump_version: versioned apply writes .version (single line)|0|got '$r' / .version='$(head -1 "${REPO_ROOT}/.version")' / lines=$lines"
  fi

  # (d) monotonicity (equal limb) — re-run at target -> SKIPPED
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_bump_version >/dev/null 2>&1
  r="$(get_phase bump_version)"
  if [[ "$r" == SKIPPED\|* ]]; then
    emit "phase_bump_version: monotone equal-limb SKIP|1|"
  else
    emit "phase_bump_version: monotone equal-limb SKIP|0|got '$r'"
  fi

  # (e) dry-run preview -> DRY-RUN, no write
  printf 'v2.08\n' > "${REPO_ROOT}/.version"
  MODE="dry-run"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  VERSION="v2.13"
  phase_bump_version >/dev/null 2>&1
  r="$(get_phase bump_version)"
  if [[ "$r" == DRY-RUN\|* && "$(head -1 "${REPO_ROOT}/.version")" == "v2.08" ]]; then
    emit "phase_bump_version: dry-run preview, no write|1|"
  else
    emit "phase_bump_version: dry-run preview, no write|0|got '$r' / .version='$(head -1 "${REPO_ROOT}/.version")'"
  fi

  # ── (f)..(r) MONOTONICITY ORDERED PAIRS ────────────────────────────────────
  # The exhaustive table for the monotonicity guard. Each arm asserts BOTH the
  # recorded phase outcome AND the resulting .version value: the outcome alone
  # cannot distinguish "SKIPped correctly" from "SKIPped and also corrupted the
  # file", and the value alone cannot distinguish a deliberate SKIP from a write
  # that happened to land on the same string.
  #
  # ANTI-VACUITY IS THE POINT, and it is two-sided. Seven arms must be SKIPPED
  # and six must be non-SKIPPED, so an always-SKIP implementation fails 6 and an
  # always-WRITE implementation fails 7. Neither degenerate form passes. Arms
  # (f) and (g) are the ordered pair for the lexical trap; (h)/(i) for the major
  # bump; (j)/(k) for the historical incident; (p)/(q)/(r) pin the recovery paths.
  #
  # THE SSOT MUST BE LOADED FIRST, AND THAT IS NOT AUTOMATIC HERE. The sliced
  # function-only copy lives in the sandbox, so the script's own SCRIPT_DIR-relative
  # source of the version-grammar library cannot resolve and the slice sets
  # _ACO_HAVE_GRAMMAR=0. In PRODUCTION that source always resolves — the library is a
  # sibling of automated-closeout.sh — so leaving the slice's 0 in place grades every
  # arm below against the DEGRADE path instead of the real one. Measured, not assumed:
  # with the flag left at 0, M-1 reports PASS and .version is written DOWN to v4.9 —
  # the fixture reports FAIL against CORRECT code. Load the real library and pin the
  # flag so these arms model production.
  . "${REPO_ROOT_REAL}/release/tools/version-grammar.sh" "" 2>/dev/null || true
  _ACO_HAVE_GRAMMAR=0
  if declare -F version_cmp >/dev/null 2>&1 && declare -F version_stamp_state >/dev/null 2>&1; then
    _ACO_HAVE_GRAMMAR=1
  fi
  # ANTI-VACUITY FLOOR. Without this, a future break in the load path silently turns
  # every arm below into a degrade-path arm that still reports green.
  if [[ "$_ACO_HAVE_GRAMMAR" == "1" ]]; then
    emit "version-grammar SSOT loaded for the monotonicity arms|1|"
  else
    emit "version-grammar SSOT loaded for the monotonicity arms|0|version_cmp / version_stamp_state unavailable — every arm below would grade the DEGRADE path, not the real one"
  fi

  MODE="apply"
  _mono() {  # <before> <target> <expected-verdict-prefix> <expected-after> <label>
    printf '%s' "$1" > "${REPO_ROOT}/.version"
    PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
    VERSION="$2"
    phase_bump_version >/dev/null 2>&1
    local got after
    got="$(get_phase bump_version)"
    after="$(head -1 "${REPO_ROOT}/.version" 2>/dev/null)"
    if [[ "$got" == "$3"\|* && "$after" == "$4" ]]; then
      emit "phase_bump_version: $5|1|"
    else
      emit "phase_bump_version: $5|0|want ${3}/.version=${4}, got '${got%%|*}'/.version='${after}'"
    fi
  }

  #      before                target     verdict  after      label
  _mono 'v4.10'               'v4.9'     SKIPPED 'v4.10'   "M-1 lexical trap — v4.10 is NOT below v4.9"
  _mono 'v4.9'                'v4.10'    PASS    'v4.10'   "M-2 sens partner of M-1"
  _mono 'v5.0'                'v4.99'    SKIPPED 'v5.0'    "M-3 major bump — a minor-only compare writes the downgrade"
  _mono 'v4.99'               'v5.0'     PASS    'v5.0'    "M-4 sens partner of M-3"
  _mono 'v4.18'               'v4.17'    SKIPPED 'v4.18'   "M-5 THE HISTORICAL INCIDENT — no regress on out-of-order close"
  _mono 'v4.17'               'v4.18'    PASS    'v4.18'   "M-6 sens partner of M-5"
  _mono 'v4.17'               'v4.17'    SKIPPED 'v4.17'   "M-7 equal limb — idempotency retained inside monotonicity"
  _mono 'v2.6'                'v2.06'    SKIPPED 'v2.6'    "M-8 leading-zero equivalence — string-UNEQUAL, version-EQUAL"
  _mono 'v2.06.1'             'v2.07'    PASS    'v2.07'   "M-9 hotfix < next minor (3-component limb)"
  _mono 'v2.07'               'v2.06.1'  SKIPPED 'v2.07'   "M-10 reverse of M-9"
  _mono 'v2.08'  'release-version-stamping' SKIPPED 'v2.08' "M-11 version-less N/A path"
  _mono ''                    'v4.19'    PASS    'v4.19'   "M-12 empty .version recovery — empty compare must not read as higher"
  _mono 'some-milestone-slug' 'v4.19'    PASS    'v4.19'   "M-13 slug-shaped corrupt value recovery"

  # ── Part 3 — THE DOC-SITE VERIFICATION PREDICATE (V-1..V-3) ────────────────
  # The three Procedure-7 doc sites now call version_stamp_state. Until these
  # arms existed the only verification of that change was a REMOVAL count of the
  # old idiom -- a specificity check with no sensitivity partner, which cannot
  # tell "correctly replaced" from "deleted and nothing put back". These arms
  # assert the replacement RETURNS THE RIGHT ANSWER.
  #
  # Hermetic by construction: each calls the helper directly against a literal,
  # so there is no git read to parameterise and no repo state to depend on. The
  # library is already loaded above, behind the anti-vacuity floor.
  if declare -F version_stamp_state >/dev/null 2>&1; then
    _docsite() {  # <current> <target> <expected> <label>
      local got; got="$(version_stamp_state "$1" "$2")"
      if [[ "$got" == "$3" ]]; then emit "doc-site predicate: $4|1|"
      else emit "doc-site predicate: $4|0|expected $3 got '$got'"; fi
    }
    _docsite 'v4.18'               'v4.17' PASS       "V-1 a HIGHER .version is the correct out-of-order-close state"
    _docsite 'v4.16'               'v4.17' MISSING    "V-2 sens partner — the stamp genuinely did not land"
    _docsite 'some-milestone-slug' 'v4.17' UNVERIFIED "V-3 a non-canonical value must NEVER read as PASS"
  else
    emit "doc-site predicate: V-1..V-3 could not load the version-grammar SSOT|0|version_stamp_state unavailable"
  fi

  # ── (s) DEGRADE PATH — the no-regression claim, made executable ─────────────
  # With the grammar library ABSENT the guard must still SKIP on equality. This is
  # the arm that pins the claim "byte-identical to the prior behaviour on EVERY
  # input class": if idempotency were gated behind _ACO_HAVE_GRAMMAR, a re-run at
  # target would WRITE where it previously SKIPped — a regression on the very path
  # labelled no-regression. Driven by flipping the flag, then restored.
  _ACO_HAVE_GRAMMAR=0
  _mono 'v4.17' 'v4.17' SKIPPED 'v4.17' "M-14 degrade path — equality SKIPs with the grammar ABSENT"
  _mono 'v4.16' 'v4.17' PASS    'v4.17' "M-15 degrade path — a non-equal value still stamps (anti-vacuity partner)"
  _ACO_HAVE_GRAMMAR=1
)

# Replay the subshell's assertion lines through report().
while IFS='|' read -r _name _ok _detail; do
  [ -n "${_name}" ] || continue
  report "${_name}" "${_ok}" "${_detail}"
done <<< "${bv_result}"

# Confirm the staging contract: .version is listed in phase_commit_chore_pr's
# files=() array (the phase writes; commit_chore_pr stages). Static assertion
# against the source — guards against the array entry being dropped.
if /usr/bin/grep -qE '^\s*"\.version"\s*$' "${CLOSEOUT_SRC}"; then
  report "phase_commit_chore_pr stages .version (files=() array entry present)" 1
else
  report "phase_commit_chore_pr stages .version (files=() array entry present)" 0 \
    ".version not found as a files=() array element in ${CLOSEOUT_SRC}"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Part 2 — L3: Check 39 comparison algorithm (the SAME logic deploy.sh Check 39
# uses, exercised offline with controlled anchor/local pairs)
# ─────────────────────────────────────────────────────────────────────────────
#
# Verdicts: PASS (equal) / WARN (exactly 1 published-minor apart) / FAIL (>=2 apart
# OR different major-lineage). Mirrors the deploy.sh Check 39 parse + signed-minor-
# distance algorithm; kept in lockstep with it.

c39_verdict() {
  # args: <local .version> <anchor latest-published-tag> ; echoes PASS|WARN|FAIL|NA
  local local_v="$1" anchor="$2"
  [ -n "$anchor" ] || { echo "NA"; return; }
  [ -n "$local_v" ] || { echo "FAIL"; return; }
  if [ "$local_v" = "$anchor" ]; then echo "PASS"; return; fi
  local l_maj l_min a_maj a_min
  l_maj="$(printf '%s' "$local_v" | sed -nE 's/^v([0-9]+)\.([0-9]+).*/\1/p')"
  l_min="$(printf '%s' "$local_v" | sed -nE 's/^v([0-9]+)\.([0-9]+).*/\2/p')"
  a_maj="$(printf '%s' "$anchor"  | sed -nE 's/^v([0-9]+)\.([0-9]+).*/\1/p')"
  a_min="$(printf '%s' "$anchor"  | sed -nE 's/^v([0-9]+)\.([0-9]+).*/\2/p')"
  if [ -z "$l_maj" ] || [ -z "$a_maj" ]; then echo "FAIL"; return; fi
  if [ "$l_maj" != "$a_maj" ]; then echo "FAIL"; return; fi
  # Force base-10 (10#…) — a zero-padded minor like 08/09 is invalid octal otherwise
  # (matches the deploy.sh Check 39 arithmetic; the bug this test caught).
  local dist=$(( 10#$l_min - 10#$a_min )); local abs=${dist#-}
  if [ "$abs" -le 1 ]; then echo "WARN"; else echo "FAIL"; fi
}

assert_verdict() {
  local local_v="$1" anchor="$2" want="$3" name="$4"
  local got; got="$(c39_verdict "$local_v" "$anchor")"
  if [ "$got" = "$want" ]; then
    report "${name}" 1
  else
    report "${name}" 0 "want ${want}, got ${got} (.version=${local_v}, anchor=${anchor})"
  fi
}

# The bug state: .version=v2.08, latest published v2.11 -> >=2 minors -> FAIL.
assert_verdict "v2.08" "v2.11" "FAIL" "Check 39: bug state (v2.08 vs v2.11) FAILs (>=2 minors)"
# >=2 minors against a later anchor too (the live drift case).
assert_verdict "v2.08" "v2.13" "FAIL" "Check 39: bug state (v2.08 vs v2.13) FAILs (>=2 minors)"
# Corrected: .version == latest published -> PASS.
assert_verdict "v2.13" "v2.13" "PASS" "Check 39: corrected (v2.13 == v2.13) PASSes"
# Legitimate Stage-12->13 window: exactly 1 minor apart -> WARN (not FAIL).
assert_verdict "v2.12" "v2.13" "WARN" "Check 39: 1-minor window (v2.12 vs v2.13) WARNs"
assert_verdict "v2.13" "v2.12" "WARN" "Check 39: 1-minor-ahead (v2.13 vs v2.12) WARNs"
# Different major-lineage -> FAIL (the orphan v3.x guard).
assert_verdict "v3.19" "v2.13" "FAIL" "Check 39: different major-lineage (v3.19 vs v2.13) FAILs"
# Empty local .version -> FAIL (can't assert invariant).
assert_verdict "" "v2.13" "FAIL" "Check 39: empty .version FAILs"
# No anchor (offline / no published Release) -> NA (never FAIL).
assert_verdict "v2.08" "" "NA" "Check 39: no published-release anchor resolves to N/A"
# Version with letter/qualifier still parses on the lineage compare.
assert_verdict "v2.13" "v2.13b-1" "WARN" "Check 39: qualifier-suffix anchor parses (v2.13 vs v2.13b-1) -> 0/1 window WARN"

# ─── Summary ────────────────────────────────────────────────────────────────
printf '\n======================================================================\n'
printf 'test_version_stamping.sh: %d passed, %d failed (bash %s)\n' \
  "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

if [ "${FAIL}" -ne 0 ]; then
  exit 1
fi
exit 0
