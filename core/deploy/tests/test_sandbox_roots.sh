#!/usr/bin/env bash
# test_sandbox_roots.sh — regression test for F9 (config-root sandboxing)
#
# Asserts that setup-workspace.sh and update.sh honor --config-root (and the
# PMO_PLATFORM_CONFIG_ROOT env-var counterpart) so integration tests can
# sandbox cleanly without polluting the operator's real $HOME state.
#
# Method: run each script under --dry-run pointed at /tmp paths; assert the
# script's planned-write paths land under the sandbox roots and that no
# $HOME/.config/pmo-platform path appears in the output.
#
# Run from repo root:
#   bash core/deploy/tests/test_sandbox_roots.sh
#
# Returns non-zero on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SETUP="${REPO_ROOT}/docs/scripts/setup-workspace.sh"
UPDATE="${REPO_ROOT}/update.sh"

PASS=0
FAIL=0
TMPDIR=""

cleanup() {
  [ -n "${TMPDIR}" ] && [ -d "${TMPDIR}" ] && rm -rf "${TMPDIR}"
}
trap cleanup EXIT

TMPDIR=$(mktemp -d -t test-sandbox.XXXXXX)
SANDBOX_CONFIG="${TMPDIR}/config"
SANDBOX_WS="${TMPDIR}/ws"
mkdir -p "${SANDBOX_CONFIG}" "${SANDBOX_WS}"

# --- Test helpers ---
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

assert_contains() {
  local name="$1" haystack="$2" needle="$3"
  if printf '%s' "${haystack}" | grep -q -- "${needle}"; then
    report "${name}" 1
  else
    report "${name}" 0 "expected to find: ${needle}"
  fi
}

assert_not_contains() {
  local name="$1" haystack="$2" needle="$3"
  if printf '%s' "${haystack}" | grep -q -- "${needle}"; then
    local first; first=$(printf '%s' "${haystack}" | grep -- "${needle}" | head -1)
    report "${name}" 0 "unexpectedly found: ${first}"
  else
    report "${name}" 1
  fi
}

# --- Test 1: setup-workspace.sh --config-root redirects operator.toml write ---
printf '\nTest 1: setup-workspace.sh --config-root redirects operator.toml\n'
setup_output=$("${SETUP}" \
  --source-repo "${REPO_ROOT}" \
  --workspace-root "${SANDBOX_WS}" \
  --config-root "${SANDBOX_CONFIG}" \
  --dry-run 2>&1)

assert_contains "operator.toml lands under --config-root" \
  "${setup_output}" "${SANDBOX_CONFIG}/operator.toml"

assert_not_contains "no \$HOME/.config/pmo-platform leak" \
  "${setup_output}" "${HOME}/.config/pmo-platform"

# --- Test 2: setup-workspace.sh env var overrides default ---
printf '\nTest 2: setup-workspace.sh honors PMO_PLATFORM_CONFIG_ROOT env var\n'
setup_env_output=$(
  PMO_PLATFORM_CONFIG_ROOT="${SANDBOX_CONFIG}" \
  "${SETUP}" \
    --source-repo "${REPO_ROOT}" \
    --workspace-root "${SANDBOX_WS}" \
    --dry-run 2>&1
)

assert_contains "env var routes operator.toml under sandbox config" \
  "${setup_env_output}" "${SANDBOX_CONFIG}/operator.toml"

assert_not_contains "env var path produces no \$HOME/.config leak" \
  "${setup_env_output}" "${HOME}/.config/pmo-platform"

# --- Test 3: CLI flag overrides env var (precedence check) ---
printf '\nTest 3: CLI --config-root overrides PMO_PLATFORM_CONFIG_ROOT env var\n'
CLI_CONFIG="${TMPDIR}/cli-config"
mkdir -p "${CLI_CONFIG}"
precedence_output=$(
  PMO_PLATFORM_CONFIG_ROOT="${SANDBOX_CONFIG}" \
  "${SETUP}" \
    --source-repo "${REPO_ROOT}" \
    --workspace-root "${SANDBOX_WS}" \
    --config-root "${CLI_CONFIG}" \
    --dry-run 2>&1
)

assert_contains "CLI --config-root wins over env" \
  "${precedence_output}" "${CLI_CONFIG}/operator.toml"

assert_not_contains "env-var config-root is NOT used when CLI is set" \
  "${precedence_output}" "${SANDBOX_CONFIG}/operator.toml"

# --- Test 4: update.sh honors --config-root for operator.toml read ---
printf '\nTest 4: update.sh --config-root targets the sandboxed operator.toml\n'
update_output=$("${UPDATE}" --config-root "${SANDBOX_CONFIG}" 2>&1 || true)

# Expected: update.sh fails preflight because no operator.toml exists at the
# sandboxed location. Error message should reference the sandboxed path, not $HOME.
assert_contains "update.sh references sandboxed operator.toml path in error" \
  "${update_output}" "${SANDBOX_CONFIG}/operator.toml"

assert_not_contains "update.sh does NOT mention \$HOME/.config/pmo-platform" \
  "${update_output}" "${HOME}/.config/pmo-platform/operator.toml"

# --- Test 5: update.sh honors PMO_PLATFORM_CONFIG_ROOT env var ---
printf '\nTest 5: update.sh honors PMO_PLATFORM_CONFIG_ROOT env var\n'
update_env_output=$(
  PMO_PLATFORM_CONFIG_ROOT="${SANDBOX_CONFIG}" \
  PMO_PLATFORM_WORKSPACE_ROOT="${SANDBOX_WS}" \
  "${UPDATE}" 2>&1 || true
)

assert_contains "env-var routed update.sh references sandboxed path" \
  "${update_env_output}" "${SANDBOX_CONFIG}/operator.toml"

# --- Summary ---
printf '\n======================================================================\n'
printf 'test_sandbox_roots.sh: %d passed, %d failed (bash %s)\n' \
  "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

if [ "${FAIL}" -ne 0 ]; then
  exit 1
fi
exit 0
