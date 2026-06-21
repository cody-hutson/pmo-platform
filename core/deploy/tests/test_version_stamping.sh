#!/usr/bin/env bash
# test_version_stamping.sh — regression test for the .version release-cut-ownership
# fix (#1643). Sibling to test_notify_version_skew.sh.
#
# Guards the 3-layer fix:
#   L2 — release/tools/automated-closeout.sh phase_bump_version:
#        writes + (implicitly) stages .version for a versioned $VERSION,
#        SKIPs-with-PASS for a version-less / non-vX.Y $VERSION, is idempotent.
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
# Two load-time guards in that slice are neutralized for the offline harness, both
# irrelevant to phase_bump_version (which never calls gh and never needs the PATH
# pin): (1) the `export PATH="/usr/bin:/bin"` pin is dropped so this harness's
# tools stay reachable; (2) the gh-resolution `exit 1` (fires when neither
# /opt/homebrew/bin/gh nor /usr/local/bin/gh exists — e.g. Linux CI) is rewritten
# to set GH to a harmless stub. The phase_bump_version logic itself is sourced
# verbatim — it is the unit under test.

CLOSEOUT_FUNCS="${SBX}/closeout-funcs.sh"
/usr/bin/sed -n '1,/^# ─── Argument parsing/p' "${CLOSEOUT_SRC}" \
  | /usr/bin/sed \
      -e '/^export PATH="\/usr\/bin:\/bin"/c\
: PATH-pin disabled for offline harness' \
      -e 's@^  exit 1$@  GH=/usr/bin/true@' \
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

  # (d) idempotency — re-run at target -> SKIPPED
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_bump_version >/dev/null 2>&1
  r="$(get_phase bump_version)"
  if [[ "$r" == SKIPPED\|* ]]; then
    emit "phase_bump_version: idempotent re-run SKIP|1|"
  else
    emit "phase_bump_version: idempotent re-run SKIP|0|got '$r'"
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
