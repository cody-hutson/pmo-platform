#!/usr/bin/env bash
# test_install_exit_propagation.sh — regression test for R2 follow-up
#
# Asserts that install.sh propagates a non-zero exit code from a failing
# setup-workspace.sh phase to its OWN exit code (so CI / Makefiles / wrapping
# scripts see the real failure rather than a spurious 0).
#
# The original R2 fix used `if ! cmd; then rc=$?; fi`, which is broken in
# every bash version: the `!` negation operator resets `$?` to 0 before the
# `then` block runs. install.sh would print a loud error message but exit 0.
# The corrected pattern is `cmd || rc=$?` (capture before test).
#
# Method: construct a minimal fixture repo with:
#   - a stub setup-workspace.sh that exits with a known non-zero code
#   - the real install.sh, orchestrate.sh, lib-composition.sh, compose.py
#   - the minimal supporting files install.sh's preflight checks for
# Run install.sh against the fixture. Assert that install.sh's exit code
# equals the stub setup-workspace.sh's exit code.
#
# Run from repo root:
#   /bin/bash core/deploy/tests/test_install_exit_propagation.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
REAL_INSTALL_SH="${REPO_ROOT}/install.sh"
REAL_ORCHESTRATE="${REPO_ROOT}/core/deploy/orchestrate.sh"
REAL_LIB="${REPO_ROOT}/core/deploy/lib-composition.sh"
REAL_COMPOSE="${REPO_ROOT}/core/deploy/compose.py"
REAL_MANIFEST="${REPO_ROOT}/core/deploy/composition-surface-manifest.sh"

PASS=0
FAIL=0
TMPDIR=""

cleanup() {
  [ -n "${TMPDIR}" ] && [ -d "${TMPDIR}" ] && rm -rf "${TMPDIR}"
}
trap cleanup EXIT

TMPDIR=$(mktemp -d -t test-install-exit.XXXXXX)

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

# --- Build a minimal install-target fixture ---
# install.sh's preflight requires:
#   - .version at repo root
#   - core/deploy/composition-surface-manifest.sh
#   - docs/scripts/setup-workspace.sh
#   - core/deploy/orchestrate.sh (for phase_deploy_skills)
# We provide real copies of orchestrate.sh + lib-composition.sh + compose.py
# + a real .version, plus a STUB setup-workspace.sh that exits with a chosen
# non-zero code.

build_fixture() {
  local fixture_root="$1" stub_exit_code="$2"

  mkdir -p "${fixture_root}/docs/scripts"
  mkdir -p "${fixture_root}/core/deploy"

  printf '%s\n' "v1.04" > "${fixture_root}/.version"

  cp "${REAL_INSTALL_SH}"   "${fixture_root}/install.sh"
  cp "${REAL_ORCHESTRATE}"  "${fixture_root}/core/deploy/orchestrate.sh"
  cp "${REAL_LIB}"          "${fixture_root}/core/deploy/lib-composition.sh"
  cp "${REAL_COMPOSE}"      "${fixture_root}/core/deploy/compose.py"
  cp "${REAL_MANIFEST}"     "${fixture_root}/core/deploy/composition-surface-manifest.sh"
  chmod +x "${fixture_root}/install.sh"

  # Stub setup-workspace.sh: emit a recognizable marker on stderr, exit with the
  # parameter exit code. install.sh's phase_workspace_bootstrap should propagate.
  cat > "${fixture_root}/docs/scripts/setup-workspace.sh" <<EOF
#!/usr/bin/env bash
printf 'STUB: simulated setup-workspace.sh failure\n' >&2
exit ${stub_exit_code}
EOF
  chmod +x "${fixture_root}/docs/scripts/setup-workspace.sh"
}

run_install_and_capture_exit() {
  local fixture_root="$1"
  local captured=0
  "${fixture_root}/install.sh" --dry-run >/dev/null 2>&1 || captured=$?
  printf '%s' "${captured}"
}

# --- Test 1: exit code 66 propagates correctly ---
printf '\nTest 1: install.sh propagates setup-workspace.sh exit 66\n'
FIXTURE_66="${TMPDIR}/fixture-66"
build_fixture "${FIXTURE_66}" 66
exit_seen=$(run_install_and_capture_exit "${FIXTURE_66}")
if [ "${exit_seen}" = "66" ]; then
  report "install.sh exits 66 when setup-workspace.sh exits 66" 1
else
  report "install.sh exit code propagation (expected 66)" 0 "got: ${exit_seen}"
fi

# --- Test 2: exit code 73 propagates correctly ---
printf '\nTest 2: install.sh propagates setup-workspace.sh exit 73\n'
FIXTURE_73="${TMPDIR}/fixture-73"
build_fixture "${FIXTURE_73}" 73
exit_seen=$(run_install_and_capture_exit "${FIXTURE_73}")
if [ "${exit_seen}" = "73" ]; then
  report "install.sh exits 73 when setup-workspace.sh exits 73" 1
else
  report "install.sh exit code propagation (expected 73)" 0 "got: ${exit_seen}"
fi

# --- Test 3: error message references the actual exit code (not 0) ---
printf '\nTest 3: install.sh error message names the real exit code\n'
FIXTURE_MSG="${TMPDIR}/fixture-msg"
build_fixture "${FIXTURE_MSG}" 66
msg_output=$("${FIXTURE_MSG}/install.sh" --dry-run 2>&1 || true)
if printf '%s' "${msg_output}" | grep -q 'failed with exit code 66'; then
  report "Error message correctly reports 'exit code 66'" 1
else
  report "Error message should reference exit code 66" 0 \
    "actual: $(printf '%s' "${msg_output}" | grep 'exit code' | head -1)"
fi

# --- Test 4: success path still exits 0 (no false positive) ---
printf '\nTest 4: install.sh exits 0 when setup-workspace.sh exits 0\n'
FIXTURE_OK="${TMPDIR}/fixture-ok"
build_fixture "${FIXTURE_OK}" 0
exit_seen=$(run_install_and_capture_exit "${FIXTURE_OK}")
if [ "${exit_seen}" = "0" ]; then
  report "install.sh exits 0 on successful bootstrap (--dry-run)" 1
else
  report "install.sh dry-run should exit 0" 0 "got: ${exit_seen}"
fi

# --- Test 5: the pattern itself (sanity check the fix vs. the broken idiom) ---
printf '\nTest 5: capture-before-test pattern works under bash 3.2\n'
verify_pattern() {
  failing_cmd() { return 66; }
  local rc=0
  failing_cmd || rc=$?
  printf '%s' "${rc}"
}
captured=$(verify_pattern)
if [ "${captured}" = "66" ]; then
  report "'cmd || rc=\$?' captures real exit code (corrected pattern)" 1
else
  report "Pattern should capture 66, got ${captured}" 0
fi

verify_broken_pattern() {
  failing_cmd() { return 66; }
  if ! failing_cmd; then
    printf '%s' "$?"
  fi
}
broken_captured=$(verify_broken_pattern)
if [ "${broken_captured}" = "0" ]; then
  report "Confirmed: 'if ! cmd; then \$?' shows the gotcha (always 0)" 1
else
  report "Broken pattern unexpectedly captured ${broken_captured}" 0
fi

# --- Summary ---
printf '\n======================================================================\n'
printf 'test_install_exit_propagation.sh: %d passed, %d failed (bash %s)\n' \
  "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

if [ "${FAIL}" -ne 0 ]; then
  exit 1
fi
exit 0
