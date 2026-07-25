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

# --- Test 1: real manifest, sourced through the lib helper, exposes a non-empty
#             array whose entry count matches the manifest's own declared rows ---
# The expected count is DERIVED from the manifest file (its pipe-delimited entry
# rows), not hardcoded, so a manifest that grows from 17 to 18 entries cannot
# silently re-rot this assertion. The test still proves both that the array is
# non-empty AND that the lib-sourced count equals the file's declared rows —
# catching a partial-source regression — without embedding a literal.
printf '\nTest 1: real manifest lib-sourced count matches manifest entry rows\n'
test_real_manifest_via_lib() {
  local entry_count expected_count
  # Source lib + run lib_compose_source_manifest, then count entries.
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
  # Expected count derived from the manifest's pipe-delimited entry rows
  # ("<src>|<tier>|<flag>"), the single source of truth — never a literal.
  expected_count=$(/usr/bin/grep -cE '^[[:space:]]*"[^"]+\|[^"]+\|[^"]+"' "${REAL_MANIFEST}")
  assert_eq "lib-sourced count equals manifest entry rows" "${expected_count}" "${entry_count}"
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

# --- Test 6: CLAUDE.md is a Customizable file, not a composition surface ---
# CLAUDE.md is composed at install by setup-workspace.sh via full-file token
# substitution (substitute_templates) and refreshed by re-running it; it is
# NOT modified by update.sh and is NOT a registered composition surface.
# Therefore core/CLAUDE.md.template must carry NO "regenerated by update.sh"
# managed-section marker, AND CLAUDE.md must be absent from
# COMPOSITION_SURFACE_FILES. The two facts must AGREE. This asserts the honest
# end-state and FAILS against a template that carries the false marker while the
# manifest omits CLAUDE.md — the exact marker-vs-manifest divergence it guards.
printf '\nTest 6: CLAUDE.md carries no false update.sh-regen marker (marker<->manifest consistent)\n'
test_claude_md_marker_manifest_consistent() {
  local repo_root template marker_present managed_marker manifest_lists
  repo_root="${DEPLOY_DIR%/core/deploy}"
  template="${repo_root}/core/CLAUDE.md.template"

  # (a) Falsification: the false "regenerated by update.sh" claim is absent from
  #     the CLAUDE.md template. (1 = present = pre-fix; 0 = absent = post-fix.)
  if /usr/bin/grep -q 'regenerated by update.sh' "${template}"; then
    marker_present=1
  else
    marker_present=0
  fi
  assert_eq "CLAUDE.md.template carries no 'regenerated by update.sh' marker" "0" "${marker_present}"

  # (b) Structural: no MANAGED SECTION fence remains in the template.
  if /usr/bin/grep -q '=== BEGIN MANAGED SECTION' "${template}"; then
    managed_marker=1
  else
    managed_marker=0
  fi
  assert_eq "CLAUDE.md.template carries no MANAGED SECTION fence" "0" "${managed_marker}"

  # (c) Consistency: CLAUDE.md is absent from COMPOSITION_SURFACE_FILES. An entry
  #     row is a quoted "<src>|<tier>|<flag>"; CLAUDE.md must not appear as a src.
  if /usr/bin/grep -qE '^[[:space:]]*"[^"]*CLAUDE\.md[^"]*\|' "${REAL_MANIFEST}"; then
    manifest_lists=1
  else
    manifest_lists=0
  fi
  assert_eq "CLAUDE.md absent from COMPOSITION_SURFACE_FILES" "0" "${manifest_lists}"

  # (d) The marker claim and the manifest membership must AGREE (both 0 = the
  #     honest state here; both 1 would be the alternative register-as-surface
  #     state). A divergence between the two is the defect this test guards.
  assert_eq "marker claim and manifest membership agree" "${manifest_lists}" "${marker_present}"
}
test_claude_md_marker_manifest_consistent

# --- Summary ---
printf '\n======================================================================\n'
printf 'test_lib_composition.sh: %d passed, %d failed (bash %s)\n' \
  "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

if [ "${FAIL}" -ne 0 ]; then
  exit 1
fi
exit 0
