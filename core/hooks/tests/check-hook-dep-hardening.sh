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
#    It greps guard TEXT. Guard text is not runtime behavior, so green HERE means
#    "no one text-coupled the floor" and nothing more. Both of the runtime holes this
#    comment used to name are now closed, and by other instruments than this one:
#      - a syntactically-valid lib/dep-resolve.sh whose top level runs `exit 0` used to
#        terminate the hook from inside the guard's own `if` condition, before the guard
#        could rule — guard text unchanged, hook silently allows. Closed by #5071: the
#        helper is now attested OUT OF PROCESS before it is admitted to the hook's shell,
#        and an EXIT trap covers the in-process source. CHECK-6 below asserts the
#        structure; hook-fail-closed.test.sh section (6) asserts the behavior.
#      - a version-skewed lib still defines resolve_jq, so the floor's guard shape passed
#        it and the hook proceeded on a stale helper. Closed by the contract token, whose
#        agreement across the lib and every carrier CHECK-6 gates.
#    The runtime arm lives in core/hooks/tests/hook-fail-closed.test.sh section (6),
#    which executes each floor hook against seven lib states AND a healthy-lib control
#    pair. Those are assertions now, not the print-only residual they used to be.
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

# 6. Dependency-contract integrity — the floor attests its helper OUT OF PROCESS.
#
#    CHECK-4 greps guard text for what must NOT be there. This asserts what MUST be
#    there: the four structural properties the attestation design rests on (#5071,
#    ADR-134). One of them is a lockout gate rather than a correctness gate.
#
#    THE SKEW GATE (why this check is load-bearing and not ceremony). The floor denies
#    when the helper's contract token does not match the value the hook captured. That
#    detection is what makes a stale or partially-written helper visible — and it is
#    equally a way to deny EVERY matching tool call across the floor, because the
#    dependency guard is evaluated BEFORE the CLAUDE_HOOK_BYPASS check in all three
#    hooks (ADR-130 Alternative 9 considered moving it and rejected that). Bumping the
#    token in the lib without bumping every carrier, or the reverse, ships exactly that
#    lockout. Disagreement fails the build here, so skew introduced IN THIS REPOSITORY
#    cannot reach a deploy.
#
#    WHAT THIS CHECK DOES NOT COVER, stated plainly: a hand-edited or partially-
#    installed DEPLOYED bundle. This reads the repository, never the operator's
#    installed hooks, so a deploy that lands a new lib beside old hooks is outside its
#    reach. That residual is accepted knowingly rather than papered over; recovery is
#    `bash docs/scripts/setup-workspace.sh` from the operator's own terminal, which the
#    hooks do not gate. Verify any hook redeploy by HASH, never by exit status.
DEP_LIB_SRC="$HOOKS_GLOB/lib/dep-resolve.sh"
LIB_CONTRACT="$(grep -m1 -E '^DEP_RESOLVE_CONTRACT=' "$DEP_LIB_SRC" 2>/dev/null \
                 | sed -E 's/^DEP_RESOLVE_CONTRACT=//; s/^"//; s/"$//')"
if [ -z "$LIB_CONTRACT" ]; then
  echo "FAIL(6): $DEP_LIB_SRC declares no DEP_RESOLVE_CONTRACT token. Every floor hook captures that value readonly before sourcing and requires it back afterwards; without it the guard cannot distinguish a healthy helper from a stale or self-exiting one." >&2
  fail=1
fi

for b in $BACKSTOP_HOOKS; do
  f="$HOOKS_GLOB/$b.sh"
  [ -f "$f" ] || continue

  dl_line="$(grep -m1 -nE '^readonly DEP_LIB=' "$f" | cut -d: -f1)"
  ct_line="$(grep -m1 -nE '^readonly DEP_LIB_CONTRACT=' "$f" | cut -d: -f1)"
  vd_line="$(grep -m1 -nF 'DEP_GUARD_VERDICT="pending"' "$f" | cut -d: -f1)"
  fd_line="$(grep -m1 -nF 'exec 9>&2' "$f" | cut -d: -f1)"
  tr_line="$(grep -m1 -nE '^trap .*DEP_GUARD_VERDICT' "$f" | cut -d: -f1)"
  un_line="$(grep -m1 -nF 'trap - EXIT' "$f" | cut -d: -f1)"
  blk="$(guard_block "$f")"

  # (a) the expected contract is captured, and it AGREES with the lib.
  if [ -z "$ct_line" ]; then
    echo "FAIL(6): $f does not capture a readonly DEP_LIB_CONTRACT. The guard's verdict depends on that value, so it must be held where the sourced file cannot write it." >&2
    fail=1
  else
    hook_contract="$(sed -n "${ct_line}p" "$f" \
                      | sed -E 's/^readonly DEP_LIB_CONTRACT=//; s/^"//; s/"$//')"
    if [ -n "$LIB_CONTRACT" ] && [ "$hook_contract" != "$LIB_CONTRACT" ]; then
      echo "FAIL(6): $f expects contract '$hook_contract' but $DEP_LIB_SRC declares '$LIB_CONTRACT'. This is the version-skew LOCKOUT: every matching tool call on the always-enforce floor would be denied, and CLAUDE_HOOK_BYPASS cannot clear a LIB-MISSING block. Bump the token in the lib and in EVERY carrier in the same commit." >&2
      fail=1
    fi
  fi

  # (b) immutability ordering — capture ABOVE the guard, never below it.
  if [ -n "$ct_line" ] && [ -n "$dl_line" ] && [ "$ct_line" -ge "$dl_line" ]; then
    echo "FAIL(6): $f captures DEP_LIB_CONTRACT at or below its DEP_LIB guard (contract:$ct_line guard:$dl_line). It must precede the guard: the control is immutability, not ordering — a sourced file cannot overwrite a readonly, but it CAN set a variable that has not been declared yet (ADR-130 D3)." >&2
    fail=1
  fi

  # (c) the premature-termination interceptor is armed before the guard, on fd 9, and
  #     disarmed after it. A future tidy-up that deletes the trap silently restores the
  #     silent-allow, so its absence is a failure rather than a style note.
  if [ -z "$tr_line" ] || [ -z "$vd_line" ] || [ -z "$un_line" ]; then
    echo "FAIL(6): $f is missing the premature-termination interceptor (trap:${tr_line:-none} verdict:${vd_line:-none} disarm:${un_line:-none}). Without it a helper that exits during the in-process source terminates the hook before the guard can rule, and the hook allows." >&2
    fail=1
  elif [ -n "$dl_line" ] && { [ "$tr_line" -ge "$dl_line" ] || [ "$un_line" -le "$dl_line" ]; }; then
    echo "FAIL(6): $f arms or disarms its EXIT trap outside the guard region (trap:$tr_line guard:$dl_line disarm:$un_line). The trap must be armed BEFORE the source and disarmed only AFTER the contract is proven." >&2
    fail=1
  fi
  if [ -z "$fd_line" ] || ! grep -qF '>&9' "$f"; then
    echo "FAIL(6): $f does not save stderr to fd 9 and write the interceptor's message there. When a sourced file exits, the 2>/dev/null on the source is STILL in effect while the trap body runs, so a trap writing to plain stderr is silently swallowed — exit 2 with no message at all." >&2
    fail=1
  fi

  # (d) the guard attests out of process, and does NOT lean on a syntax check.
  if ! printf '%s' "$blk" | grep -qF 'dep_lib_attests'; then
    echo "FAIL(6): $f guard block does not call dep_lib_attests. Sourcing the helper bare inside the condition is the defect: the helper can terminate the hook from inside the guard's own test." >&2
    fail=1
  fi
  if ! grep -qF 'readonly -f dep_lib_attests' "$f"; then
    echo "FAIL(6): $f does not mark dep_lib_attests readonly -f — the sourced helper could redefine the function the guard's verdict depends on." >&2
    fail=1
  fi
  if printf '%s' "$blk" | grep -qE 'bash[[:space:]]+-n'; then
    echo "FAIL(6): $f guard block relies on a bash -n syntax precheck. That is the control this defect defeats: it verifies the helper PARSES, never that it MEANS what the hook expects, and it passes a top-level 'exit 0' by construction." >&2
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "OK: no hard-coded jq path, no legacy fail-open message, all jq resolvers sourced from lib/dep-resolve.sh, always-enforce floor unconditional, mode-capable cohort couples via a readonly pre-guard snapshot, floor attests its helper out of process on contract $LIB_CONTRACT."
fi
exit "$fail"
