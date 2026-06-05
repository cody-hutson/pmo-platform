#!/usr/bin/env bash
# test_lib_composition.sh — regression tests for lib-composition.sh under bash 3.2
#
# Covers the bash-3.2 array-scope contract that the manifest and
# lib_compose_source_manifest depend on:
#
#   1. composition-surface-manifest.sh must use PLAIN ASSIGNMENT (no
#      `declare -a`). `declare -a` inside a sourced-from-function context
#      makes the array function-local; the caller never sees it.
#
#   2. lib_compose_source_manifest must validate that the array is defined
#      and non-empty after sourcing, so the regression in #1 fails loud
#      rather than silently installing zero composition-surface files.
#
#   3. The iteration site must be `set -u`-safe for the empty-array case
#      (bash 3.2 has a known unbound-variable bug on empty-array iteration).
#
# Run with system bash (which is bash 3.2 on macOS) to exercise the real
# constraint:
#   /bin/bash core/deploy/tests/test_lib_composition.sh
#
# Returns non-zero on any failure. Exits 0 on success.

set -uo pipefail   # NOT -e: we want each test to run and report independently.

# --- Resolve fixture paths ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEPLOY_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
LIB_COMPOSITION="${DEPLOY_DIR}/lib-composition.sh"
REAL_MANIFEST="${DEPLOY_DIR}/composition-surface-manifest.sh"

PASS=0
FAIL=0
TMPDIR=""

cleanup() {
  [ -n "${TMPDIR}" ] && [ -d "${TMPDIR}" ] && rm -rf "${TMPDIR}"
}
trap cleanup EXIT

TMPDIR=$(mktemp -d -t test-lib-composition.XXXXXX)

# --- Test helpers ---
assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [ "${expected}" = "${actual}" ]; then
    printf '  PASS: %s\n' "${name}"
    PASS=$((PASS + 1))
  else
    printf '  FAIL: %s\n         expected: %s\n         actual:   %s\n' \
      "${name}" "${expected}" "${actual}"
    FAIL=$((FAIL + 1))
  fi
}

assert_nonzero() {
  local name="$1" actual="$2"
  if [ "${actual}" -ne 0 ]; then
    printf '  PASS: %s\n' "${name}"
    PASS=$((PASS + 1))
  else
    printf '  FAIL: %s (expected non-zero exit, got 0)\n' "${name}"
    FAIL=$((FAIL + 1))
  fi
}

# --- Test 1: real manifest produces a non-empty array when sourced through lib helper ---
printf '\nTest 1: real manifest sourced via lib_compose_source_manifest exposes non-empty array\n'
test_real_manifest_via_lib() {
  local entry_count
  # Source lib + run lib_compose_source_manifest, then count entries via lib_compose_iterate.
  entry_count=$(
    # shellcheck disable=SC1090
    source "${LIB_COMPOSITION}"
    # Repo root is two levels above DEPLOY_DIR (core/deploy → core → repo root).
    if lib_compose_source_manifest "${DEPLOY_DIR%/core/deploy}"; then
      printf '%s' "${#COMPOSITION_SURFACE_FILES[@]}"
    else
      printf '0'
    fi
  )
  assert_eq "Real manifest exposes 17 entries" "17" "${entry_count}"
}
test_real_manifest_via_lib

# --- Test 2: manifest with `declare -a` (the regression we fixed) is detected ---
printf '\nTest 2: manifest with `declare -a` fails the lib validation (regression detection)\n'
test_declare_a_regression_detected() {
  # Build a fixture that uses `declare -a` like the pre-fix manifest did.
  mkdir -p "${TMPDIR}/fixture/core/deploy"
  cat > "${TMPDIR}/fixture/core/deploy/composition-surface-manifest.sh" <<'EOF'
declare -a COMPOSITION_SURFACE_FILES=(
  "alpha|hook|tokens"
  "beta|instance|raw"
)
EOF
  # Source lib + source manifest + run caller-scope assert. This matches the
  # real callers' invocation pattern (lib + assert pair). With `declare -a`,
  # the array becomes function-local to lib_compose_source_manifest and is
  # invisible from this scope — assert must return non-zero.
  local rc
  set +e
  (
    # shellcheck disable=SC1090
    source "${LIB_COMPOSITION}"
    lib_compose_source_manifest "${TMPDIR}/fixture" && \
      lib_compose_assert_manifest_loaded
  ) >/dev/null 2>&1
  rc=$?
  set -e
  assert_nonzero "caller-scope assert rejects declare -a regression" "${rc}"
}
test_declare_a_regression_detected

# --- Test 3: plain-assignment manifest (the fix) passes lib validation ---
printf '\nTest 3: plain-assignment manifest is accepted (the post-fix shape)\n'
test_plain_assignment_accepted() {
  mkdir -p "${TMPDIR}/fixture-good/core/deploy"
  cat > "${TMPDIR}/fixture-good/core/deploy/composition-surface-manifest.sh" <<'EOF'
COMPOSITION_SURFACE_FILES=(
  "alpha|hook|tokens"
  "beta|instance|raw"
)
EOF
  local entry_count
  entry_count=$(
    # shellcheck disable=SC1090
    source "${LIB_COMPOSITION}"
    if lib_compose_source_manifest "${TMPDIR}/fixture-good"; then
      printf '%s' "${#COMPOSITION_SURFACE_FILES[@]}"
    else
      printf 'sourcing-failed'
    fi
  )
  assert_eq "Plain-assignment manifest exposes 2 entries" "2" "${entry_count}"
}
test_plain_assignment_accepted

# --- Test 4: empty manifest also fails the lib validation ---
printf '\nTest 4: empty manifest is rejected\n'
test_empty_manifest_rejected() {
  mkdir -p "${TMPDIR}/fixture-empty/core/deploy"
  cat > "${TMPDIR}/fixture-empty/core/deploy/composition-surface-manifest.sh" <<'EOF'
COMPOSITION_SURFACE_FILES=()
EOF
  local rc
  set +e
  (
    # shellcheck disable=SC1090
    source "${LIB_COMPOSITION}"
    lib_compose_source_manifest "${TMPDIR}/fixture-empty" && \
      lib_compose_assert_manifest_loaded
  ) >/dev/null 2>&1
  rc=$?
  set -e
  assert_nonzero "Empty manifest is rejected by assert" "${rc}"
}
test_empty_manifest_rejected

# --- Test 5: iteration site is `set -u`-safe even if guarded by length-check ---
printf '\nTest 5: defensive iteration pattern is set-u-safe on empty array\n'
test_iteration_set_u_safe() {
  local rc
  set +e
  /bin/bash -c '
    set -u
    EMPTY=()
    if [ "${#EMPTY[@]}" -gt 0 ]; then
      for x in "${EMPTY[@]}"; do echo "$x"; done
    fi
  ' >/dev/null 2>&1
  rc=$?
  set -e
  assert_eq "Length-guarded iteration on empty array exits 0" "0" "${rc}"
}
test_iteration_set_u_safe

# --- Summary ---
printf '\n======================================================================\n'
printf 'test_lib_composition.sh: %d passed, %d failed (bash %s)\n' \
  "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

if [ "${FAIL}" -ne 0 ]; then
  exit 1
fi
exit 0
