#!/bin/bash
# tests/scope-guard.test.sh — the layer-3 workspace-scope gate (#4436).
#
# This suite OWNS the scope layer. The other *.test.sh files in this directory
# exercise RULE logic and run with the harness-wide PMO_SCOPE_GUARD_ROOT="/" export
# that neutralizes scope (test-runner.sh); if scope were left live there, every rule
# payload -- which carries cwd "/tmp" or omits cwd -- would see an inert hook and the
# suites would go vacuously green. Here the root is set PER CASE so both the in-scope
# and the out-of-scope branches are observed rather than assumed.
#
# Two layers of coverage:
#   Part A — unit: source lib/scope-guard.sh and assert scope_guard_in_scope directly.
#   Part B — in situ: drive a REAL hook (block-destructive) end-to-end and assert the
#            same payload BLOCKS in scope and is ALLOWED out of scope. A guard that
#            only passes unit tests has not been shown to be reachable from a hook.
#
# Part B is the arm that matters: it is the only one that fails if the guard is wired
# into the wrong place in a hook's precedence chain, or not wired at all.

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
LIB="${HOOK_DIR}/lib/scope-guard.sh"
HOOK="${HOOK_DIR}/block-destructive.sh"

if [ ! -r "$LIB" ]; then echo "FAIL: scope-guard lib not readable at $LIB" >&2; exit 1; fi
if [ ! -x "$HOOK" ]; then echo "FAIL: hook not executable at $HOOK" >&2; exit 1; fi

PASS=0
FAIL=0

ok() { /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
no() { /usr/bin/printf 'FAIL: %s — %s\n' "$1" "${2:-}"; FAIL=$((FAIL + 1)); }

echo "================================"
echo "scope-guard.sh tests (#4436)"
echo "================================"

# --- Sandbox: a governed root, a descendant, a name-extending sibling, an outsider ---
# NOTE the `cd && pwd -P`: on macOS mktemp hands back a /var/... path that is a symlink
# to /private/var/..., and the guard canonicalizes both sides. Pinning the PHYSICAL
# spelling here keeps the expectations comparable to what scope_guard_root returns.
SBX="$(cd "$(/usr/bin/mktemp -d)" && pwd -P)"
GOVERNED="${SBX}/Claude"
INSIDE="${GOVERNED}/pmo-platform/.claude/worktrees/wt-1"
SIBLING="${SBX}/ClaudeSandbox"          # name-EXTENDS the root; must NOT be in scope
OUTSIDE="${SBX}/unrelated-repo"
/bin/mkdir -p "$INSIDE" "$SIBLING" "$OUTSIDE" "${GOVERNED}/.claude/hooks"
trap '/bin/rm -rf "$SBX"' EXIT

# ---------------------------------------------------------------------------
# Part A — unit assertions against the sourced library
# ---------------------------------------------------------------------------
# shellcheck disable=SC1090
. "$LIB"

unit() {
  local name="$1" cwd="$2" root="$3" expect="$4"   # expect: in|out
  local got="out"
  if scope_guard_in_scope "$cwd" "$root"; then got="in"; fi
  if [ "$got" = "$expect" ]; then ok "$name"; else no "$name" "expected $expect, got $got"; fi
}

unit "root itself is in scope"                   "$GOVERNED"  "$GOVERNED" in
unit "deep descendant (worktree) is in scope"    "$INSIDE"    "$GOVERNED" in
unit "outsider is out of scope"                  "$OUTSIDE"   "$GOVERNED" out
unit "name-extending sibling is out of scope"    "$SIBLING"   "$GOVERNED" out
unit "parent of the root is out of scope"        "$SBX"       "$GOVERNED" out
unit "trailing slash on cwd still in scope"      "${INSIDE}/" "$GOVERNED" in
unit "trailing slash on root still in scope"     "$INSIDE"    "${GOVERNED}/" in
unit "dot-dot escape resolves out of scope"      "${GOVERNED}/../unrelated-repo" "$GOVERNED" out
unit "nonexistent path under root is in scope"   "${GOVERNED}/gone/missing" "$GOVERNED" in
unit "nonexistent path outside root is out"      "/no/such/place" "$GOVERNED" out

# Symlink canonicalization: an alternate spelling of an in-scope directory must not
# read as out of scope (and the reverse must not be spoofable).
/bin/ln -s "$INSIDE" "${SBX}/link-to-inside"
/bin/ln -s "$OUTSIDE" "${GOVERNED}/link-to-outside"
unit "symlink INTO the root is in scope"         "${SBX}/link-to-inside" "$GOVERNED" in
unit "symlink out of the root is out of scope"   "${GOVERNED}/link-to-outside" "$GOVERNED" out

# CWD-axis fail direction: undeterminable => NOT in scope (the gate maps that to
# do-not-enforce). Empty payload value alone is NOT undeterminable -- $PWD backstops it.
( cd "$INSIDE" && scope_guard_in_scope "" "$GOVERNED" ) \
  && ok "empty payload cwd falls back to \$PWD (in scope)" \
  || no "empty payload cwd falls back to \$PWD (in scope)" "expected in, got out"
( cd "$OUTSIDE" && scope_guard_in_scope "" "$GOVERNED" ) \
  && no "empty payload cwd falls back to \$PWD (out of scope)" "expected out, got in" \
  || ok "empty payload cwd falls back to \$PWD (out of scope)"
( PWD="" scope_guard_in_scope "" "$GOVERNED" ) \
  && no "undeterminable cwd is not in scope" "expected out, got in" \
  || ok "undeterminable cwd is not in scope"

# Root resolution precedence. Every case starts from a HERMETIC environment: the three
# inputs are unset first, then only what the case names is set. Without the `-u` the
# harness-wide PMO_SCOPE_GUARD_ROOT="/" export in test-runner.sh leaks in and the
# "when the override is unset" cases silently test the wrong thing — they pass
# standalone and fail under the runner.
root_is() {
  local name="$1" expect="$2"; shift 2
  local got
  got="$(/usr/bin/env -u PMO_SCOPE_GUARD_ROOT -u CLAUDE_WORKSPACE_ROOT -u HOOK_DIR "$@" \
          /bin/bash -c '. "'"$LIB"'"; scope_guard_root')"
  if [ "$got" = "$expect" ]; then ok "$name"; else no "$name" "expected $expect, got $got"; fi
}
root_is "PMO_SCOPE_GUARD_ROOT wins over CLAUDE_WORKSPACE_ROOT" "$GOVERNED" \
  "PMO_SCOPE_GUARD_ROOT=${GOVERNED}" "CLAUDE_WORKSPACE_ROOT=${OUTSIDE}"
root_is "CLAUDE_WORKSPACE_ROOT used when the override is unset" "$OUTSIDE" \
  "CLAUDE_WORKSPACE_ROOT=${OUTSIDE}"
root_is "HOOK_DIR grandparent used when both are unset" "$GOVERNED" \
  "HOOK_DIR=${GOVERNED}/.claude/hooks"

# ---------------------------------------------------------------------------
# Part B — in situ: the guard is actually reachable from a real hook
# ---------------------------------------------------------------------------
# Payload: an unallowlisted subprocess script. In scope this is BLOCK-DESTRUCTIVE-022
# (exit 2); out of scope the hook must be inert (exit 0) even though the rule matches.
# Same payload, same hook, same mode — only the scope root differs. That single-variable
# construction is what makes the ALLOW arm evidence rather than an absence of evidence.
PAYLOAD="$(/usr/bin/jq -n --arg cwd "$INSIDE" \
  '{tool_name:"Bash", tool_input:{command:"bash /tmp/definitely-not-allowlisted-4436.sh"}, cwd:$cwd}')"

insitu() {
  local name="$1" expected_exit="$2"; shift 2
  local rc=0 err_out
  err_out="$(/usr/bin/printf '%s' "$PAYLOAD" | /usr/bin/env "$@" /bin/bash "$HOOK" 2>&1 >/dev/null)" || rc="$?"
  if [ "$rc" = "$expected_exit" ]; then ok "$name"; else no "$name" "exit=$rc expected=$expected_exit stderr=${err_out}"; fi
}

# Sensitivity: the rule DOES fire when the call is in scope. Without this arm the
# ALLOW arm below would be satisfied by a hook that never blocks anything.
insitu "in scope: unallowlisted script BLOCKS (022)" 2 "PMO_SCOPE_GUARD_ROOT=${GOVERNED}"
# Specificity: the identical call is allowed when the session is outside the root.
insitu "out of scope: identical call is ALLOWED"     0 "PMO_SCOPE_GUARD_ROOT=${OUTSIDE}"
# Layer 1 still precedes layer 3.
insitu "CLAUDE_HOOK_BYPASS still short-circuits"     0 "PMO_SCOPE_GUARD_ROOT=${GOVERNED}" "CLAUDE_HOOK_BYPASS=1"

# LIB-axis fail direction (NOT inverted): a missing lib must NOT gate, so the hook
# keeps enforcing. This is the anti-kill-switch property — assert it, do not assume it.
MISSING_ROOT="$(/usr/bin/mktemp -d)"
/bin/cp "$HOOK" "${MISSING_ROOT}/block-destructive.sh"
/bin/mkdir -p "${MISSING_ROOT}/lib"
for dep in dep-resolve.sh master-enable.sh; do
  [ -r "${HOOK_DIR}/lib/${dep}" ] && /bin/cp "${HOOK_DIR}/lib/${dep}" "${MISSING_ROOT}/lib/"
done
[ -r "${HOOK_DIR}/../script-execution-allowlist.txt" ] \
  && /bin/cp "${HOOK_DIR}/../script-execution-allowlist.txt" "${MISSING_ROOT}/../script-execution-allowlist.txt" 2>/dev/null
rc=0
/usr/bin/printf '%s' "$PAYLOAD" \
  | /usr/bin/env "PMO_SCOPE_GUARD_ROOT=${OUTSIDE}" /bin/bash "${MISSING_ROOT}/block-destructive.sh" >/dev/null 2>&1 || rc="$?"
if [ "$rc" = 2 ]; then
  ok "missing scope-guard lib does NOT disable the hook (no kill switch)"
else
  no "missing scope-guard lib does NOT disable the hook (no kill switch)" "exit=$rc expected=2"
fi
/bin/rm -rf "$MISSING_ROOT"

# BLOCK-DESTRUCTIVE-023 must cover the scope-root override the same way it covers the
# layer-1 hatch, or the override becomes an unguarded mid-session escape.
rc=0
INJ="$(/usr/bin/jq -n --arg cwd "$INSIDE" \
  '{tool_name:"Bash", tool_input:{command:"export PMO_SCOPE_GUARD_ROOT=/nowhere"}, cwd:$cwd}')"
out="$(/usr/bin/printf '%s' "$INJ" | /usr/bin/env "PMO_SCOPE_GUARD_ROOT=${GOVERNED}" /bin/bash "$HOOK" 2>&1 >/dev/null)" || rc="$?"
if [ "$rc" = 2 ] && /usr/bin/printf '%s' "$out" | /usr/bin/grep -q 'BLOCK-DESTRUCTIVE-023'; then
  ok "mid-session PMO_SCOPE_GUARD_ROOT assignment is denied (023)"
else
  no "mid-session PMO_SCOPE_GUARD_ROOT assignment is denied (023)" "exit=$rc out=${out}"
fi

echo ""
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
