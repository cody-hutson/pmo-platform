#!/usr/bin/env bash
# test_ps1_dryrun_contract.sh — v3.90 / #303 regression for the Windows install/
# update -DryRun proxy contract (A6.5 Counter-Design CD-1, Option B).
#
# WHY THIS TEST EXISTS (and why it does NOT run PowerShell):
#   #303 ships install.ps1 / update.ps1 with a NON-VACUOUS `-DryRun` proxy. The
#   proxy's load-bearing operation is a compose.py regen round-trip that must run
#   bash-free on Windows (the re-scoped AC-4 evidence). PowerShell cannot execute
#   on the macOS CI runner, so the *executable* proxy is validated on the Windows
#   leg by #304's matrix. This test instead pins the contract on the runner we DO
#   have by two complementary means:
#     Part 1 — exercise the IDENTICAL compose.py regen + installed_sha round-trip
#              in POSIX (the exact portable substrate the .ps1 drives), incl. the
#              HOME-fallback token path the Windows HOME shim protects.
#     Part 2 — statically lint install.ps1 / update.ps1 / lib-dryrun-proxy.ps1 so
#              the pinned contract cannot silently drift out of the scripts.
#     Part 3 — assert BOTH non-Darwin platform gates are relaxed (opt-in), so the
#              #304 matrix legs can run (Stage-5 REC-3: two independent gates).
#
# Platform-agnostic: uses only bash + python3 + grep; it does NOT invoke
# setup-workspace.sh or deploy.sh, so it runs on macOS AND Linux (no self-skip).
#
# Member of the standing install/onboarding/update regression suite
# (run-install-regression.sh). Prints "<name>: N passed, M failed"; exits non-zero
# on any FAIL.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

COMPOSE_PY="${REPO_ROOT}/core/deploy/compose.py"
SRC_TEMPLATE="${REPO_ROOT}/core/config/allowlists/fs-boundary-allowlist.txt"
INSTALL_PS1="${REPO_ROOT}/install.ps1"
UPDATE_PS1="${REPO_ROOT}/update.ps1"
LIB_PS1="${REPO_ROOT}/core/deploy/lib-dryrun-proxy.ps1"
SETUP_SH="${REPO_ROOT}/docs/scripts/setup-workspace.sh"
VALIDATE_SH="${REPO_ROOT}/docs/scripts/validate-install.sh"

PASS=0
FAIL=0
TMP=""

cleanup() {
  if [ -n "${TMP}" ] && [ -d "${TMP}" ]; then
    rm -rf "${TMP}"
  fi
}
trap cleanup EXIT

report() {
  local name="$1" ok="$2" detail="${3:-}"
  if [ "${ok}" = "1" ]; then
    printf '  PASS: %s\n' "${name}"
    PASS=$((PASS + 1))
  else
    printf '  FAIL: %s\n' "${name}"
    [ -n "${detail}" ] && printf '        %s\n' "${detail}"
    FAIL=$((FAIL + 1))
  fi
}

# Portable SHA-256 (macOS shasum; Linux sha256sum fallback) — mirrors the
# lib_compose_sha_compute convention (lowercase hex, digest only).
sha256_of() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

# grep a file for a fixed string; report PASS/FAIL with a descriptive name.
assert_contains() {
  local file="$1" needle="$2" name="$3"
  if [ ! -f "${file}" ]; then
    report "${name}" 0 "file missing: ${file}"
    return
  fi
  if grep -qF -- "${needle}" "${file}"; then
    report "${name}" 1
  else
    report "${name}" 0 "expected to find: ${needle}"
  fi
}

printf '======================================================================\n'
printf 'test_ps1_dryrun_contract.sh — Windows -DryRun proxy contract (#303)\n'
printf '======================================================================\n'

# --- Preflight ---
if ! command -v python3 >/dev/null 2>&1; then
  printf 'FAIL: python3 not on PATH (required for the compose round-trip)\n'
  printf 'test_ps1_dryrun_contract.sh: 0 passed, 1 failed\n'
  exit 1
fi
for f in "${COMPOSE_PY}" "${SRC_TEMPLATE}" "${INSTALL_PS1}" "${UPDATE_PS1}" "${LIB_PS1}" "${SETUP_SH}" "${VALIDATE_SH}"; do
  if [ ! -f "${f}" ]; then
    printf 'FAIL: required artifact missing: %s\n' "${f}"
    printf 'test_ps1_dryrun_contract.sh: 0 passed, 1 failed\n'
    exit 1
  fi
done

TMP="$(mktemp -d -t ps1-dryrun.XXXXXX)"

# ─────────────────────────────────────────────────────────────────────────────
# Part 1 — POSIX compose.py regen round-trip (the portable substrate the .ps1
#          drives; identical operation to Invoke-PmoComposeRoundTrip).
# ─────────────────────────────────────────────────────────────────────────────
printf '\nPart 1: compose.py regen + installed_sha round-trip (portable substrate)\n'

OUT="${TMP}/fs-boundary-allowlist.txt"
ABSENT_TOML="${TMP}/operator.toml"   # deliberately absent -> HOME-fallback token path
SRC_SHA="$(sha256_of "${SRC_TEMPLATE}")"

# HOME shim analogue: the round-trip resolves [CLAUDE_WORKSPACE_ROOT] from HOME
# when operator.toml omits [paths]. This is the exact fallback the Windows shim
# ($env:HOME = %USERPROFILE%) protects. Pin HOME to a known sentinel so the
# substitution is deterministically assertable.
SHIM_HOME="${TMP}/home"
mkdir -p "${SHIM_HOME}"

regen_out="$(HOME="${SHIM_HOME}" python3 "${COMPOSE_PY}" regen \
  --source "${SRC_TEMPLATE}" --target "${OUT}" \
  --operator-toml "${ABSENT_TOML}" --tokens-flag tokens --source-sha "${SRC_SHA}" 2>&1)"
regen_exit=$?
if [ "${regen_exit}" -eq 0 ] && [ -f "${OUT}" ]; then
  report "T1: compose.py regen into temp dir succeeds (exit 0, file written)" 1
else
  report "T1: compose.py regen into temp dir succeeds (exit 0, file written)" 0 \
    "exit ${regen_exit}: ${regen_out}"
fi

STORED_SHA="$(grep -E '^# installed_sha:' "${OUT}" 2>/dev/null | head -1 | awk '{print $3}')"
READBACK_SHA="$(python3 "${COMPOSE_PY}" installed-sha --target "${OUT}" 2>/dev/null)"
if [ -n "${STORED_SHA}" ] && [ "${STORED_SHA}" = "${READBACK_SHA}" ]; then
  report "T2: installed_sha round-trip (write-stored == read-back, non-empty)" 1
else
  report "T2: installed_sha round-trip (write-stored == read-back, non-empty)" 0 \
    "stored='${STORED_SHA}' readback='${READBACK_SHA}'"
fi

# T3: HOME-fallback substitution observable — [CLAUDE_WORKSPACE_ROOT] resolved to
# <HOME>/Claude proves the shim path is live (the Windows failure mode is HOME
# unset -> this resolving to a bare "Claude").
if grep -qF "${SHIM_HOME}/Claude" "${OUT}"; then
  report "T3: HOME-fallback token resolves ([CLAUDE_WORKSPACE_ROOT] -> <HOME>/Claude)" 1
else
  report "T3: HOME-fallback token resolves ([CLAUDE_WORKSPACE_ROOT] -> <HOME>/Claude)" 0 \
    "expected '${SHIM_HOME}/Claude' in composed body"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Part 2 — Static contract lint of the .ps1 surface (the executable proxy is run
#          on the Windows leg by #304; this guards against contract drift).
# ─────────────────────────────────────────────────────────────────────────────
printf '\nPart 2: .ps1 -DryRun contract lint (contract cannot silently drift)\n'

# Shared library: the pinned CD-1 (a)-(d) mechanics live here.
assert_contains "${LIB_PS1}" 'Resolve-PmoPython'          "T4: lib resolves a Python interpreter (contract a)"
assert_contains "${LIB_PS1}" 'floor'                      "T5: lib asserts a Python version floor (contract a)"
assert_contains "${LIB_PS1}" '$env:HOME = Get-PmoHome'    "T6: lib applies the HOME shim at the compose call (A6.5 PT-2/CD-3)"
assert_contains "${LIB_PS1}" 'compose.py'                 "T7: lib invokes compose.py (contract d)"
assert_contains "${LIB_PS1}" 'installed-sha'             "T8: lib performs the installed_sha read-back (contract d)"
assert_contains "${LIB_PS1}" 'regen'                      "T9: lib runs compose.py regen into a temp target (contract d)"

# install.ps1: entry-point + phase plan (both phases bash-only -> SKIPPED).
assert_contains "${INSTALL_PS1}" '[switch]$DryRun'        "T10: install.ps1 exposes -DryRun"
assert_contains "${INSTALL_PS1}" 'lib-dryrun-proxy.ps1'   "T11: install.ps1 dot-sources the shared proxy lib"
assert_contains "${INSTALL_PS1}" 'Invoke-PmoDryRunProof'  "T12: install.ps1 runs the pinned proof (contracts a-d)"
assert_contains "${INSTALL_PS1}" 'SKIPPED'                "T13: install.ps1 phase plan marks bash-only phases SKIPPED (contract e)"

# update.ps1: entry-point + phase plan (Phase 3 portable -> EXERCISED; rest SKIPPED).
assert_contains "${UPDATE_PS1}" '[switch]$DryRun'         "T14: update.ps1 exposes -DryRun"
assert_contains "${UPDATE_PS1}" 'lib-dryrun-proxy.ps1'    "T15: update.ps1 dot-sources the shared proxy lib"
assert_contains "${UPDATE_PS1}" 'Invoke-PmoDryRunProof'   "T16: update.ps1 runs the pinned proof (contracts a-d)"
assert_contains "${UPDATE_PS1}" 'EXERCISED'               "T17: update.ps1 marks the portable Phase 3 EXERCISED (contract e)"
assert_contains "${UPDATE_PS1}" 'SKIPPED'                 "T18: update.ps1 marks bash-only phases SKIPPED (contract e)"

# ─────────────────────────────────────────────────────────────────────────────
# Part 3 — Both non-Darwin gates relaxed (opt-in) so #304's matrix can run.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nPart 3: both non-Darwin platform gates relaxed (Stage-5 REC-3)\n'

assert_contains "${SETUP_SH}"    'PMO_ALLOW_NON_DARWIN'   "T19: setup-workspace.sh check_platform honors PMO_ALLOW_NON_DARWIN"
assert_contains "${VALIDATE_SH}" 'PMO_ALLOW_NON_DARWIN'   "T20: validate-install.sh honors PMO_ALLOW_NON_DARWIN"
# The protective exit 78 must remain for the un-opted-in case (not neutered).
assert_contains "${SETUP_SH}"    'exit 78'                "T21: setup-workspace.sh retains exit 78 for the un-opted-in case"
assert_contains "${VALIDATE_SH}" 'exit 78'                "T22: validate-install.sh retains exit 78 for the un-opted-in case"

# --- Summary ---
printf '\n======================================================================\n'
printf 'test_ps1_dryrun_contract.sh: %d passed, %d failed (bash %s)\n' \
  "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

if [ "${FAIL}" -ne 0 ]; then
  exit 1
fi
exit 0
