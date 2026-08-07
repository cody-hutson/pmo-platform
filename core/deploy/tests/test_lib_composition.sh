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

# --- Test 6: CLAUDE.md's regeneration claim agrees with its manifest membership ---
# GENERALIZED at ADR-120 (was: "CLAUDE.md carries no false update.sh-regen
# marker"). The invariant is UNCHANGED — a file's regeneration claim must match
# its manifest membership, because a claim honored by no mechanism is exactly the
# false contract that produced the superseded defect. Only the expected VALUES
# moved: pre-ADR-120 the honest state was claim=0 / member=0; post-ADR-120
# CLAUDE.md IS a registered composition surface, so the honest state is
# claim=1 / member=1. The test is generalized, NOT deleted — a divergence in
# either direction still fails it.
printf '\nTest 6: CLAUDE.md regeneration claim <-> manifest membership (ADR-120)\n'
test_claude_md_claim_manifest_consistent() {
  local repo_root template claim_present managed_marker manifest_lists row_shape
  repo_root="${DEPLOY_DIR%/core/deploy}"
  template="${repo_root}/core/CLAUDE.md.template"

  # (a) RETAINED, not inverted: a composition-surface SOURCE template carries no
  #     fences (composition-surface-spec.md §1.2) — the writer emits them. This
  #     expectation is 0 both before and after ADR-120; only the reason changed
  #     (was "the claim is false", now "the writer owns the fence").
  if /usr/bin/grep -q '=== BEGIN MANAGED SECTION' "${template}"; then
    managed_marker=1
  else
    managed_marker=0
  fi
  assert_eq "CLAUDE.md.template carries no MANAGED SECTION fence in source" "0" "${managed_marker}"

  # (b) The regeneration claim in the template's provenance prose. Matches both
  #     the bare and dot-slash spellings so the assertion is about the CLAIM, not
  #     about one punctuation form. (1 = claims update.sh regenerates it.)
  if /usr/bin/grep -qE 'regenerated by \.?/?update\.sh' "${template}"; then
    claim_present=1
  else
    claim_present=0
  fi
  assert_eq "CLAUDE.md.template states the update.sh regeneration claim" "1" "${claim_present}"

  # (c) Membership: CLAUDE.md IS in COMPOSITION_SURFACE_FILES. An entry row is a
  #     quoted "<src>|<tier>|<flag>[|<dialect>]".
  if /usr/bin/grep -qE '^[[:space:]]*"[^"]*CLAUDE\.md[^"]*\|' "${REAL_MANIFEST}"; then
    manifest_lists=1
  else
    manifest_lists=0
  fi
  assert_eq "CLAUDE.md present in COMPOSITION_SURFACE_FILES" "1" "${manifest_lists}"

  # (d) THE INVARIANT (generalized): claim and membership agree. Both 1 post-
  #     ADR-120; both were 0 pre-ADR-120; a 1/0 split in either direction is the
  #     false-contract defect this test has always guarded.
  assert_eq "regeneration claim and manifest membership agree" "${manifest_lists}" "${claim_present}"

  # (e) Row shape: the CLAUDE.md row declares the workspace-root tier and the
  #     markdown dialect. A row that silently reverted to the 3-field form would
  #     default to the plain dialect and emit a `#`-prefixed fence into a
  #     markdown governance file.
  if /usr/bin/grep -qE '^[[:space:]]*"core/CLAUDE\.md\.template\|workspace-root\|tokens\|markdown"' "${REAL_MANIFEST}"; then
    row_shape=1
  else
    row_shape=0
  fi
  assert_eq "CLAUDE.md row declares workspace-root tier + markdown dialect" "1" "${row_shape}"
}
test_claude_md_claim_manifest_consistent

# --- Test 7: the manifest carries the full install-time token vocabulary ---
# LOAD-BEARING (ADR-120 §Decision 8). setup-workspace.sh compute_active_tokens
# derives ACTIVE_TOKENS by grepping core/CLAUDE.md.template +
# core/settings.json.template + THIS MANIFEST. ADR-120 moved the reserved-token
# vocabulary out of the template's authoring header and into the manifest, so a
# future edit that drops a token line from the manifest silently shrinks
# ACTIVE_TOKENS — the installer stops resolving that token and
# write_operator_toml persists it EMPTY. That is the silent-blanking failure the
# [COWORK_INSTALL_PATH_BASE] resolver/writer pairing fix addressed; this test is
# the gate that keeps it fixed.
#
# The assertion is a SET EQUALITY against the pinned vocabulary, not a count: a
# count would pass a swap (one token dropped, another misspelled in).
#
# WHAT THIS TEST DOES AND DOES NOT ASSERT — stated precisely, because the two are
# easy to conflate and the gate-efficacy standard treats an overclaiming label as a
# defect in its own right. This test RE-IMPLEMENTS compute_active_tokens' grep
# rather than invoking it: setup-workspace.sh runs `main "$@"` at end-of-file and
# carries no source-guard, so the function cannot be sourced without running the
# whole installer. The consequence is a bounded and DELIBERATE blind spot:
#
#   COVERED — a token line dropped from the manifest (arm 1 goes red); the manifest
#   contributing nothing at all (arm 2); the manifest removed from the installer's
#   grep inputs entirely (arm 3).
#
#   NOT COVERED — a mutation that keeps the manifest path but NARROWS the
#   installer's own token regex (e.g. dropping COWORK from the alternation). All
#   three arms here stay green because arm 1 uses this file's copy of the regex,
#   not the installer's, so [COWORK_INSTALL_PATH_BASE] would silently leave the
#   real ACTIVE_TOKENS while this test reads 13/0.
#
# That gap is CLOSED DOWNSTREAM, not left open: the end-to-end consequence is
# asserted by test_upgrade_config_durability.sh Suite P arm P-2c, which fails when
# [paths].cowork_install_path is written blank on a fresh install — which is
# exactly what a narrowed regex produces. Do not "fix" the labels below by widening
# what they claim; either keep the claim matched to the assertion, or give
# setup-workspace.sh a source-guard and invoke the real derivation here.
printf '\nTest 7: manifest preserves the full install-time token vocabulary (ADR-120)\n'
test_manifest_declares_full_token_vocabulary() {
  local repo_root derived expected
  repo_root="${DEPLOY_DIR%/core/deploy}"

  # Reproduce compute_active_tokens' derivation over the same three inputs.
  derived=$(
    /usr/bin/grep -hoE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' \
      "${repo_root}/core/CLAUDE.md.template" \
      "${repo_root}/core/settings.json.template" \
      "${REAL_MANIFEST}" \
      2>/dev/null | LC_ALL=C sort -u | tr '\n' ' '
  )

  # The vocabulary as of ADR-120 (core/standards/depersonalization-spec.md §1).
  # Adding a token to the platform means adding it here deliberately.
  #
  # Normalized through the SAME sort pipeline as `derived` rather than written in
  # sorted order by hand: the two differ under C vs. locale collation
  # ([OPERATOR_GITHUB] vs [OPERATOR_GIT_EMAIL] invert on the `_`-vs-`H` byte), and
  # an order-sensitive comparison would fail on a correct set. This is a SET
  # assertion; canonicalizing both sides is what makes it one.
  expected=$(printf '%s\n' \
    '[CLAUDE_WORKSPACE_ROOT]' \
    '[COWORK_INSTALL_PATH_BASE]' \
    '[OPERATOR_EMAIL]' \
    '[OPERATOR_FIRST_NAME]' \
    '[OPERATOR_GITHUB]' \
    '[OPERATOR_GIT_EMAIL]' \
    '[OPERATOR_HOMEDIR_PATH]' \
    '[OPERATOR_NAME]' \
    '[OPERATOR_ORGANIZATION]' \
    '[OPERATOR_PHONE]' \
    '[OPERATOR_PROJECT_NAME]' \
    '[OPERATOR_ROLE_TITLE]' \
    | LC_ALL=C sort -u | tr '\n' ' ')

  assert_eq "the three grep inputs together still carry the full pinned token vocabulary (re-derived here, not read from the installer)" \
    "${expected}" "${derived}"

  # Sensitivity control: the manifest alone must contribute a NON-EMPTY set. If
  # this is 0 the equality above could only pass by the templates coincidentally
  # covering everything — which would make the whole test vacuous.
  local from_manifest_only
  from_manifest_only=$(
    /usr/bin/grep -hoE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' "${REAL_MANIFEST}" \
      2>/dev/null | LC_ALL=C sort -u | /usr/bin/wc -l | tr -d ' '
  )
  if [ "${from_manifest_only}" -ge 6 ]; then
    assert_eq "manifest contributes >=6 tokens the templates no longer carry" "ok" "ok"
  else
    assert_eq "manifest contributes >=6 tokens the templates no longer carry" "ok" \
      "only ${from_manifest_only} token(s) found in manifest"
  fi

  # THE COUPLING ARM. The two assertions above prove the manifest DECLARES the
  # vocabulary; neither proves the installer READS it. Removing the manifest from
  # compute_active_tokens' grep inputs leaves both of them green while
  # ACTIVE_TOKENS silently loses five tokens and operator.toml keys are written
  # blank — a gate that goes green without asserting its invariant. Verified by
  # mutation: dropping the third input turns this arm red, and the end-to-end
  # consequence red in test_upgrade_config_durability.sh Suite P (P-2, P-2c).
  #
  # Its reach is the PATH, not the regex: this arm asserts that setup-workspace.sh
  # still names the manifest among its grep inputs. A mutation that keeps the path
  # and narrows the token alternation passes here by construction — see the blind
  # spot named in this test's header and its downstream catcher, P-2c.
  local setup_script reads_manifest
  setup_script="${repo_root}/docs/scripts/setup-workspace.sh"
  if /usr/bin/grep -qF '${SOURCE_REPO}/core/deploy/composition-surface-manifest.sh' "${setup_script}"; then
    reads_manifest=1
  else
    reads_manifest=0
  fi
  assert_eq "compute_active_tokens still names the manifest path among its grep inputs (ADR-120 §8)" \
    "1" "${reads_manifest}"
}
test_manifest_declares_full_token_vocabulary

# --- Summary ---
printf '\n======================================================================\n'
printf 'test_lib_composition.sh: %d passed, %d failed (bash %s)\n' \
  "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

if [ "${FAIL}" -ne 0 ]; then
  exit 1
fi
exit 0
