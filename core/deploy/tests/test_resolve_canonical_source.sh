#!/usr/bin/env bash
# test_resolve_canonical_source.sh — regression net for the single-sourced
# template-sync canonical-source resolver (#2158).
#
# What this proves: resolve_template_sync_source() — now defined ONCE in
# core/deploy/lib-template-sync-source.sh and sourced by BOTH deploy.sh and
# core/deploy/tools/build-skill-packages.sh — resolves each canonical basename to
# the correct source root:
#   - the 3 explicit shared-standards basenames -> core/standards/<name>
#     (output-format.md, operational-artifacts.md — #316; regression-checks.md —
#      #94, the case that broke the pmo-skill-editor rebuild when the two former
#      hand-synced resolver copies diverged)
#   - tracker-schemas.md                        -> core/schemas/<name>
#     (#4178 — the canonical half of a registered complementary pair; a DIFFERENT
#      source root from arm 1, which is why it has its own arm)
#   - template-*.md                             -> core/standards/<name>
#   - everything else (*-template.{md,csv}, …)  -> operations/templates/<name>
#
# It SOURCES the real fragment (no re-implementation) and pins a fixture table,
# then drift-guards BOTH consumer scripts: each must source the fragment, and
# neither may carry an inline `echo "core/standards/$name"` case-arm resolver — so
# re-introducing a divergent second copy (the exact #2158 drift class) fails this
# test.
#
# Hermetic-by-construction: the resolver is pure string logic (no gh, no live
# tracker, no network, no filesystem writes).
# Bash 3.2.57-safe: source + case + local only (no associative arrays / local -n).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="${SCRIPT_DIR}/.."
LIB_FRAGMENT="${DEPLOY_DIR}/lib-template-sync-source.sh"
DEPLOY_SH="${DEPLOY_DIR}/deploy.sh"
BSP_SH="${DEPLOY_DIR}/tools/build-skill-packages.sh"

PASS_COUNT=0
FAIL_COUNT=0

# ── Source the REAL fragment under test (the single source of truth). If it is
#    absent, the whole single-source contract is broken — fail loud.
if [[ ! -f "$LIB_FRAGMENT" ]]; then
  echo "  FAIL: shared resolver fragment not found -> $LIB_FRAGMENT"
  echo "Result: 0 passed, 1 failed"
  echo "resolve-canonical-source regression: FAILED"
  exit 1
fi
# shellcheck source=../lib-template-sync-source.sh disable=SC1091
source "$LIB_FRAGMENT"

if ! type resolve_template_sync_source >/dev/null 2>&1; then
  echo "  FAIL: sourcing $LIB_FRAGMENT did not define resolve_template_sync_source()"
  echo "Result: 0 passed, 1 failed"
  echo "resolve-canonical-source regression: FAILED"
  exit 1
fi

# assert_resolve <expected-path> <canonical-name> <note>
assert_resolve() {
  local _expected="$1" _name="$2" _note="$3" _got
  _got="$(resolve_template_sync_source "$_name")"
  if [[ "$_got" == "$_expected" ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  ok   %-34s -> %-44s  %s\n' "$_name" "$_got" "$_note"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL %-34s want=%s got=%s  (%s)\n' "$_name" "$_expected" "$_got" "$_note"
  fi
}

echo "── resolve_template_sync_source: canonical-source fixture table ──────────"
# Arm 1 — explicit shared-standards basenames -> core/standards/
assert_resolve "core/standards/output-format.md"         "output-format.md"         "explicit (#316)"
assert_resolve "core/standards/operational-artifacts.md" "operational-artifacts.md" "explicit (#316)"
assert_resolve "core/standards/regression-checks.md"     "regression-checks.md"     "explicit (#94 — the drift that broke the rebuild)"
# Arm 1b — the complementary-pair canonical -> core/schemas/ (a DIFFERENT root)
assert_resolve "core/schemas/tracker-schemas.md"         "tracker-schemas.md"       "explicit (#4178 — core/schemas/, NOT core/standards/)"
# Arm 2 — template-*.md -> core/standards/
assert_resolve "core/standards/template-storage.md"      "template-storage.md"      "template-*.md standard"
assert_resolve "core/standards/template-taxonomy.md"     "template-taxonomy.md"     "template-*.md standard"
assert_resolve "core/standards/template-protocol.md"     "template-protocol.md"     "template-*.md standard"
# Arm 3 — default -> operations/templates/
assert_resolve "operations/templates/raid-log-template.csv"            "raid-log-template.csv"            "*-template.csv default -> operations"
assert_resolve "operations/templates/communications-tracker-template.md" "communications-tracker-template.md" "*-template.md default -> operations"
assert_resolve "operations/templates/key-terms-glossary-template.csv"  "key-terms-glossary-template.csv"  ".csv default -> operations"
assert_resolve "operations/templates/people-roster-template.yaml"      "people-roster-template.yaml"      "non-.md non-template-* default -> operations"
assert_resolve "operations/templates/project-bins/1-governance/README.md" "project-bins/1-governance/README.md" "subpath key -> default arm concatenates (no basename constraint)"

echo ""
echo "── Every resolved canonical must EXIST on disk ───────────────────────────"
# The fixture table above pins the resolver's STRING output. This guard pins the
# consequence: a basename that no arm claims falls to the default arm and resolves
# to a path that may not exist at all, which is a silent-until-deploy failure —
# the always-enforce injection check reports "canonical missing from registry" and
# the packager returns non-zero on every build of the owning skill.
#
# tracker-schemas.md is the live instance: it matches neither the explicit
# shared-standards set nor template-*.md, so WITHOUT its own arm it resolves to
# operations/templates/tracker-schemas.md — a third path that is not either half
# of the pair and does not exist. Delete the arm and this guard fails; that is
# what makes the arm's necessity asserted rather than asserted-about.
REPO_ROOT="$(cd "${DEPLOY_DIR}/../.." && pwd)"
assert_resolved_exists() {
  local _name="$1" _note="$2" _got
  _got="$(resolve_template_sync_source "$_name")"
  if [[ -f "$REPO_ROOT/$_got" ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  ok   %-34s -> %-44s exists  %s\n' "$_name" "$_got" "$_note"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL %-34s -> %s DOES NOT EXIST  (%s)\n' "$_name" "$_got" "$_note"
  fi
}
assert_resolved_exists "tracker-schemas.md"   "#4178 complementary-pair canonical — arm removal makes this the default arm's non-existent path"
assert_resolved_exists "regression-checks.md" "#94 — the basename whose mis-resolution broke a package rebuild at release-cut"
assert_resolved_exists "template-storage.md"  "arm 2 control"
assert_resolved_exists "raid-log-template.csv" "default-arm control"
assert_resolved_exists "project-bins/_inbox/README.md" "subpath-key control — the default arm resolves a subpath to an existing canonical"

echo ""
echo "── Drift guard: the resolver is single-sourced (no divergent 2nd copy) ───"
DRIFT_OK=true

# (1) Both consumers must SOURCE the shared fragment.
for _consumer in "$DEPLOY_SH" "$BSP_SH"; do
  if /usr/bin/grep -q 'lib-template-sync-source\.sh' "$_consumer"; then
    printf '  ok   %s sources lib-template-sync-source.sh\n' "$(basename "$_consumer")"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    DRIFT_OK=false
    printf '  FAIL drift: %s does not source lib-template-sync-source.sh\n' "$(basename "$_consumer")"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
done

# (2) Neither consumer may carry an inline canonical-source case-arm. The literal
#     `echo "core/standards/$name"` is the load-bearing resolution logic and must
#     live ONLY in the fragment; its reappearance in a consumer means someone
#     re-inlined a (divergence-prone) second copy — the exact #2158 drift class.
for _consumer in "$DEPLOY_SH" "$BSP_SH"; do
  if /usr/bin/grep -qF 'echo "core/standards/$name"' "$_consumer"; then
    DRIFT_OK=false
    printf '  FAIL drift: %s re-inlines a canonical-source resolver (echo "core/standards/$name")\n' "$(basename "$_consumer")"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  else
    printf '  ok   %s carries no inline canonical-source resolver\n' "$(basename "$_consumer")"
    PASS_COUNT=$((PASS_COUNT + 1))
  fi
done

# (3) The retired resolve_canonical_source() name must be gone from LIVE code —
#     no definition (`resolve_canonical_source() {`) and no call site
#     (`$(resolve_canonical_source` / `resolve_canonical_source "…"`). A prose
#     mention in a history comment is deliberately allowed (this test's own
#     rationale, and the consumer's, reference the retired name), so the guard
#     targets code constructs, not substrings.
if /usr/bin/grep -qE 'resolve_canonical_source\(\)[[:space:]]*\{|resolve_canonical_source[[:space:]]+"|\$\(resolve_canonical_source' "$BSP_SH"; then
  DRIFT_OK=false
  printf '  FAIL drift: build-skill-packages.sh still defines/calls resolve_canonical_source\n'
  FAIL_COUNT=$((FAIL_COUNT + 1))
else
  printf '  ok   retired resolve_canonical_source name has no live definition/call\n'
  PASS_COUNT=$((PASS_COUNT + 1))
fi

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
printf 'Result: %d passed, %d failed\n' "$PASS_COUNT" "$FAIL_COUNT"
if [[ "$FAIL_COUNT" -gt 0 || "$DRIFT_OK" != "true" ]]; then
  echo "resolve-canonical-source regression: FAILED"
  exit 1
fi
echo "resolve-canonical-source regression: PASSED"
exit 0
