#!/bin/bash
# check-hook-dep-hardening.sh — regression guard for GHSA-9cjm-v22x-4x33.
#
# Asserts the jq fail-open class cannot re-drift into the PreToolUse security hooks:
#   1. No hook hard-codes the jq path (jq MUST be resolved via lib/dep-resolve.sh, which
#      probes an absolute-path allowlist and prefers a root-owned binary).
#   2. No hook carries the legacy fail-open degradation message (missing jq must fail
#      CLOSED in enforce, or degrade to exit 0 in warn/off — never a blanket fail-open).
#   3. Every hook that resolves jq actually sources the shared helper.
#
# Shared by manual verification and the Security CI workflow (job: hook-dep-hardening).
# Exit 0 = clean; exit 1 = a drift was reintroduced.

set -euo pipefail
export PATH="/usr/bin:/bin"

# repo root, from core/hooks/tests/
cd "$(dirname "$0")/../../.."
HOOKS_GLOB="core/hooks"
fail=0

# 1. No hard-coded jq path. (Scans only top-level core/hooks/*.sh — lib/dep-resolve.sh
#    legitimately names the candidate paths, and tests/ names them in fixtures.)
if grep -nE 'readonly[[:space:]]+JQ=["'"'"']?/usr/bin/jq' "$HOOKS_GLOB"/*.sh 2>/dev/null; then
  echo "FAIL(1): a hook hard-codes JQ=/usr/bin/jq — resolve via lib/dep-resolve.sh instead (GHSA-9cjm-v22x-4x33)." >&2
  fail=1
fi

# 2. No legacy blanket fail-open message.
if grep -nE 'DEGRADED \(fail-open\)' "$HOOKS_GLOB"/*.sh 2>/dev/null; then
  echo "FAIL(2): a hook still carries the legacy 'DEGRADED (fail-open)' message — missing jq must fail closed (enforce) or degrade per mode, not blanket fail-open." >&2
  fail=1
fi

# 3. Every hook that calls resolve_jq must source the shared helper.
for f in "$HOOKS_GLOB"/*.sh; do
  if grep -qE '\bresolve_jq\b' "$f" 2>/dev/null && ! grep -qE 'dep-resolve\.sh' "$f" 2>/dev/null; then
    echo "FAIL(3): $f calls resolve_jq but does not source lib/dep-resolve.sh." >&2
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "OK: no hard-coded jq path, no legacy fail-open message, all jq resolvers sourced from lib/dep-resolve.sh."
fi
exit "$fail"
