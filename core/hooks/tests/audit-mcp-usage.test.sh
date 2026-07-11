#!/bin/bash
# tests/audit-mcp-usage.test.sh — regression tests for audit-mcp-usage.sh
#
# audit-mcp-usage.sh is a manually-run, ONE-SHOT seeding CLI (not a PreToolUse
# hook). Its jq resolution now flows through the shared lib/dep-resolve.sh helper
# (GHSA-9cjm-v22x-4x33). POSTURE = audit / NON-BLOCKING: a degraded run that
# cannot resolve jq must exit 0 (skip), never block.
#
# Because jq resolution lives in the HELPER, simulating "jq missing" requires
# sandboxing BOTH files: a copy of the hook + a copy of dep-resolve.sh with all
# three jq candidate paths rewritten to nonexistent locations.

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
HOOK="${HOOK_DIR}/audit-mcp-usage.sh"
LIB="${HOOK_DIR}/lib/dep-resolve.sh"

if [ ! -x "$HOOK" ]; then echo "FAIL: hook not executable at $HOOK" >&2; exit 1; fi
if [ ! -r "$LIB" ]; then echo "FAIL: helper lib not readable at $LIB" >&2; exit 1; fi

PASS=0
FAIL=0

echo "================================"
echo "audit-mcp-usage.sh tests (jq-helper adoption / audit posture)"
echo "================================"

# ----- Happy path: jq present, --help returns exit 0 (no jq needed) -----
_h_exit=0
/bin/bash "$HOOK" --help >/dev/null 2>&1 || _h_exit="$?"
if [ "$_h_exit" = 0 ]; then
  /usr/bin/printf 'PASS: --help → exit 0\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: --help → expected exit 0, got %s\n' "$_h_exit"; FAIL=$((FAIL + 1))
fi

# ----- Happy path: jq present, normal scan resolves jq via the helper -----
# The scan's exit code is DATA-dependent (0 when session logs exist, non-zero when
# none are found — e.g. a bare CI runner with no Claude session history), so this
# case asserts only what the GHSA-9cjm helper adoption is responsible for: jq
# resolves through lib/dep-resolve.sh with no DEPENDENCY-MISSING / LIB-MISSING error.
_n_err="$(/bin/bash "$HOOK" --days 1 2>&1 >/dev/null)"
if ! /usr/bin/printf '%s' "$_n_err" | /usr/bin/grep -qE 'DEPENDENCY-MISSING|LIB-MISSING'; then
  /usr/bin/printf 'PASS: normal scan resolves jq via helper (no dependency error)\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: normal scan emitted a dependency error\n  stderr: %s\n' "$_n_err"; FAIL=$((FAIL + 1))
fi

# ----- jq MISSING (helper sandbox) → warn-degraded, exit 0 (GHSA-9cjm-v22x-4x33) -----
# Sandbox BOTH files: hook copy + dep-resolve.sh copy with jq candidates broken.
# Audit is non-blocking, so a resolver miss must SKIP (exit 0), not deny.
_sbx="$(/usr/bin/mktemp -d)"
/bin/mkdir -p "$_sbx/lib"
/bin/cp "$HOOK" "$_sbx/audit-mcp-usage.sh"
/usr/bin/sed \
  -e 's#/usr/bin/jq#/nonexistent/jq-a#g' \
  -e 's#/opt/homebrew/bin/jq#/nonexistent/jq-b#g' \
  -e 's#/usr/local/bin/jq#/nonexistent/jq-c#g' \
  "$LIB" > "$_sbx/lib/dep-resolve.sh"
/bin/chmod +x "$_sbx/audit-mcp-usage.sh"
_jqmiss_exit=0
_jqmiss_err="$(/bin/bash "$_sbx/audit-mcp-usage.sh" --days 1 2>&1 >/dev/null)" || _jqmiss_exit="$?"
if [ "$_jqmiss_exit" = 0 ] && /usr/bin/printf '%s' "$_jqmiss_err" | /usr/bin/grep -qE 'DEPENDENCY-MISSING'; then
  /usr/bin/printf 'PASS: jq missing → warn-degraded (exit 0 + DEPENDENCY-MISSING)\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: jq missing → expected exit 0 + DEPENDENCY-MISSING, got exit=%s\n  stderr: %s\n' "$_jqmiss_exit" "$_jqmiss_err"; FAIL=$((FAIL + 1))
fi
/bin/rm -rf "$_sbx"

# ----- Helper lib MISSING entirely → guard fails closed (exit 2 + LIB-MISSING) -----
# The readability guard must fire before any jq use; keeping jq resolution in the
# single shared helper means a missing helper is an install fault the operator
# should see, not a silent empty run.
_sbx2="$(/usr/bin/mktemp -d)"
/bin/cp "$HOOK" "$_sbx2/audit-mcp-usage.sh"
/bin/chmod +x "$_sbx2/audit-mcp-usage.sh"
# deliberately do NOT create $_sbx2/lib/dep-resolve.sh
_libmiss_exit=0
_libmiss_err="$(/bin/bash "$_sbx2/audit-mcp-usage.sh" --days 1 2>&1 >/dev/null)" || _libmiss_exit="$?"
if [ "$_libmiss_exit" = 2 ] && /usr/bin/printf '%s' "$_libmiss_err" | /usr/bin/grep -qE 'LIB-MISSING'; then
  /usr/bin/printf 'PASS: helper missing → guard fires (exit 2 + LIB-MISSING)\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: helper missing → expected exit 2 + LIB-MISSING, got exit=%s\n  stderr: %s\n' "$_libmiss_exit" "$_libmiss_err"; FAIL=$((FAIL + 1))
fi
/bin/rm -rf "$_sbx2"

# ----- Summary -----
echo ""
echo "================================"
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "================================"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
