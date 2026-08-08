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

# --- guard-block extractor: the DEP_LIB declaration through its closing `fi`. -------
# Used by 4 and 5. Prints nothing when the hook carries no guard.
guard_block() {
  awk '/^readonly DEP_LIB=/{inb=1} inb{print} inb && /^fi$/{exit}' "$1"
}

# 4. Backstop integrity — the always-enforce floor keeps an UNCONDITIONAL guard.
#
#    Mode-coupling the dependency guard on the mode-capable cohort is only safe while
#    at least one hook per matcher class still denies unconditionally. These three span
#    Read (credential-reads), Bash (rm-prefer-trash) and Bash/Write/Edit (destructive),
#    and none of them has a mode surface to couple to. This check goes red the moment
#    someone "makes it uniform" and couples one of them.
#
#    WHAT THIS CHECK DOES NOT COVER — read this before trusting a green result.
#    It greps guard TEXT. The ways the floor actually stops denying at runtime are not
#    textual, and this check is green in every one of them:
#      - a syntactically-valid lib/dep-resolve.sh whose top level runs `exit 0`
#        terminates the hook from inside the guard's own `if` condition, before the
#        guard can rule. Guard text unchanged, hook silently allows. Tracked as a
#        separate defect; NOT closed by this check and NOT closed by the mode-coupling
#        work, which deliberately leaves these three hooks untouched.
#      - a version-skewed lib still defines resolve_jq, so the floor's guard shape
#        passes it and the hook proceeds on a stale helper.
#    The runtime arm lives in core/hooks/tests/hook-fail-closed.test.sh section (6),
#    which executes each floor hook against absent and truncated libs and prints the
#    corrupt-lib residual on every run. Green HERE means "no one text-coupled the
#    floor" and nothing more.
BACKSTOP_HOOKS="block-credential-reads block-destructive block-rm-prefer-trash"
for b in $BACKSTOP_HOOKS; do
  f="$HOOKS_GLOB/$b.sh"
  if [ ! -f "$f" ]; then
    echo "FAIL(4): $f is missing — the always-enforce backstop set changed without updating this check." >&2
    fail=1
    continue
  fi
  blk="$(guard_block "$f")"
  if [ -z "$blk" ]; then
    echo "FAIL(4): $f no longer carries a lib/dep-resolve.sh guard — the unconditional fail-closed backstop was removed." >&2
    fail=1
    continue
  fi
  if ! printf '%s' "$blk" | grep -qF 'BLOCKED (fail-closed)'; then
    echo "FAIL(4): $f guard block no longer denies fail-closed." >&2
    fail=1
  fi
  if printf '%s' "$blk" | grep -qE 'LIB_GUARD_MODE|get_mode|MODE_FILE|\.mode'; then
    echo "FAIL(4): $f guard block references a mode — the always-enforce floor must stay UNCONDITIONAL. Mode-coupling one of these three voids the basis on which the mode-capable cohort was allowed to degrade." >&2
    fail=1
  fi
done

# 5. Cohort conformance — every mode-capable guarded hook couples the SAME way.
#
#    Structural, not a name-list: any block-*.sh that declares both a MODE_FILE and a
#    DEP_LIB guard is in the cohort by construction, so a future 10th mode-capable hook
#    is covered the day it is added. Scoped to block-*.sh deliberately —
#    verify-session-config.sh declares both but is a non-blocking SessionStart hook with
#    no LIB-MISSING guard, and is correctly out of this cohort.
for f in "$HOOKS_GLOB"/block-*.sh; do
  grep -qE '^readonly MODE_FILE=' "$f" || continue
  blk="$(guard_block "$f")"
  [ -n "$blk" ] || continue

  gm_line="$(grep -nE '^get_mode\(\)' "$f" | head -1 | cut -d: -f1)"
  dl_line="$(grep -nE '^readonly DEP_LIB=' "$f" | head -1 | cut -d: -f1)"
  snap_line="$(grep -nE '^LIB_GUARD_MODE=.*; readonly LIB_GUARD_MODE' "$f" | head -1 | cut -d: -f1)"

  if [ -z "$gm_line" ]; then
    echo "FAIL(5): $f declares MODE_FILE and a DEP_LIB guard but defines no get_mode() — one mode-resolution site per hook." >&2
    fail=1
    continue
  fi
  if [ -z "$snap_line" ]; then
    echo "FAIL(5): $f does not snapshot its mode into a readonly LIB_GUARD_MODE. The guard sources the untrusted lib inside its own condition, so resolving the mode after that point lets the lib redefine get_mode and pick the guard's own verdict. readonly is what makes the snapshot un-clobberable." >&2
    fail=1
    continue
  fi
  if [ "$gm_line" -ge "$dl_line" ] || [ "$snap_line" -ge "$dl_line" ]; then
    echo "FAIL(5): $f resolves its mode at or below the DEP_LIB guard (get_mode:$gm_line snapshot:$snap_line guard:$dl_line) — both must precede the guard." >&2
    fail=1
  fi
  if ! printf '%s' "$blk" | grep -qF 'LIB_GUARD_MODE'; then
    echo "FAIL(5): $f guard block does not consult LIB_GUARD_MODE — the guard is still unconditional on a hook that has a mode surface." >&2
    fail=1
  fi
  if printf '%s' "$blk" | grep -qE '\$\(get_mode\)|`get_mode`'; then
    echo "FAIL(5): $f guard block CALLS get_mode() instead of reading the snapshot. By that point the untrusted lib has been sourced and may have redefined the function; read \$LIB_GUARD_MODE." >&2
    fail=1
  fi
  if printf '%s' "$blk" | grep -qE 'basename'; then
    echo "FAIL(5): $f guard block shells out to basename. This branch runs only after the install has been detected broken, so it must take no dependency on an external binary resolving — use \${MODE_FILE##*/}." >&2
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "OK: no hard-coded jq path, no legacy fail-open message, all jq resolvers sourced from lib/dep-resolve.sh, always-enforce floor unconditional, mode-capable cohort couples via a readonly pre-guard snapshot."
fi
exit "$fail"
