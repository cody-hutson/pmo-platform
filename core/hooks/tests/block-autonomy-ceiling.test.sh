#!/bin/bash
# tests/block-autonomy-ceiling.test.sh — synthetic PreToolUse payload tests for
# block-autonomy-ceiling.sh (C5, #1163).
#
# Covers the #1163 ACs + the #1438 D7 fixture set:
#   - ceiling block:     above-ceiling action at recommend → exit 2
#   - ceiling pass:      at-ceiling action at recommend / bounded_auto → exit 0
#   - Tier-0 override:   governance-file Write at bounded_auto → STILL exit 2
#   - Tier-0 under warn: governance-file Write, .autonomy-mode=warn → STILL exit 2
#   - cross-domain:      pmo-platform cwd writing projects/ → exit 2 (Tier-0)
#   - warn-mode ceiling: above-ceiling, .autonomy-mode=warn → exit 0 + warn-log grows
#   - off-mode ceiling:  above-ceiling, .autonomy-mode=off → exit 0
#   - permissive default: unmapped tool call → exit 0
#   - non-mutation:      Read / WebFetch → exit 0 (out of matcher scope)
#   - bypass:            CLAUDE_HOOK_BYPASS=1 → exit 0 + bypass-log
#   - malformed JSON → exit 2
#
# The ceiling is controlled per-case via the cache file (read first by the hook):
#   0 = off, 1 = recommend, 2 = bounded_auto.
# Governance/cross-domain path detection anchors on CLAUDE_WORKSPACE_ROOT, which
# this harness pins to a temp workspace so fixtures are host-independent.

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
HOOK="${HOOK_DIR}/block-autonomy-ceiling.sh"
MODE_FILE="${HOOK_DIR}/.autonomy-mode"
WARN_LOG="${HOOK_DIR}/autonomy-warn-log.jsonl"
BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"

if [ ! -x "$HOOK" ]; then echo "FAIL: hook not executable at $HOOK" >&2; echo "Total: 1  PASS: 0  FAIL: 1"; exit 1; fi

# --- Pinned temp workspace + cache (host-independent) ---
# CLAUDE_WORKSPACE_ROOT pins the governance/cross-domain anchors; a temp HOME-like
# cache dir controls the resolved ceiling. We override the cache path by pointing
# HOME at a temp dir for the duration of each hook invocation (the hook resolves
# the cache under ${HOME}/.cache/pmo-platform/).
#
# TEST_WS is pinned to its PHYSICALLY RESOLVED path (`cd … && pwd -P`), not the raw
# mktemp string. The hook compares ABS_TARGET — which resolve_path() has already run
# through realpath / `cd "$parent" && pwd -P` — against ${PRIMARY_ROOT}. On macOS
# mktemp hands back /var/folders/… while /var is a symlink to /private/var, so an
# unresolved root makes every anchored comparison compare a resolved target against an
# unresolved prefix and never match. That latent mismatch was invisible while the
# governance entries were bare basename globs (they matched any prefix) and while the
# already-anchored fixtures happened to name parents that do not exist on disk (for
# which resolve_path returns the raw string untouched). Resolving here is what makes
# the anchored assertions genuine rather than accidentally-passing.
TEST_WS="$(cd "$(/usr/bin/mktemp -d)" && pwd -P)"
TEST_HOME="$(/usr/bin/mktemp -d)"
/bin/mkdir -p "${TEST_HOME}/.cache/pmo-platform"
CACHE_FILE="${TEST_HOME}/.cache/pmo-platform/autonomy-ceiling"

# --- MASTER ACTIVATION, seeded ON for the whole suite ---
# The HOME pin above is what makes the ceiling cache host-independent, but HOME is
# ALSO where lib/master-enable.sh looks for its activation state:
#   ${PMO_PLATFORM_CONFIG_ROOT:-${HOME}/.config/pmo-platform}/platform-config.toml
# Pinning HOME to a bare temp dir therefore pointed that read at a file that does not
# exist, master resolved to the shipped 'off' default, and the master-gated STEP-2
# ceiling check went inert for every case that did not seed its own config. The suite
# was internally inconsistent as a result: R-8 below DOCUMENTS master-OFF as rendering
# the ceiling inert, while five non-R ceiling cases above it silently depended on the
# ceiling being live and failed. Seeding activation here is what makes the ceiling
# assertions test the ceiling rather than the activation gate.
#
# The two arms that genuinely need master-OFF (R-8, R-9, and the -004 master-OFF arm)
# opt out explicitly by pointing PMO_PLATFORM_CONFIG_ROOT at an empty directory, which
# takes precedence over this file. Activation is therefore ON by default and OFF only
# where an arm says so — the inverse of the accidental posture it replaces.
CONFIG_ROOT="${TEST_HOME}/.config/pmo-platform"
/bin/mkdir -p "$CONFIG_ROOT"
/usr/bin/printf '[security_hooks]\nmaster_enabled = true\n' > "${CONFIG_ROOT}/platform-config.toml"

export CLAUDE_WORKSPACE_ROOT="$TEST_WS"

# --- Save + restore the hook's own mode file ---
ORIGINAL_MODE=""
[ -f "$MODE_FILE" ] && ORIGINAL_MODE="$(/bin/cat "$MODE_FILE")"
restore_state() {
  if [ -n "$ORIGINAL_MODE" ]; then
    /usr/bin/printf '%s' "$ORIGINAL_MODE" > "$MODE_FILE"
  else
    /bin/rm -f "$MODE_FILE"
  fi
  /bin/rm -rf "$TEST_WS" "$TEST_HOME"
}
trap restore_state EXIT

PASS=0
FAIL=0

# set_ceiling N — write the numeric ceiling to the pinned cache.
set_ceiling() { /usr/bin/printf '%s\n' "$1" > "$CACHE_FILE"; }
set_mode() { /usr/bin/printf '%s' "$1" > "$MODE_FILE"; }

# test_case name payload expected_exit [expected_pattern]
# Runs the hook with HOME pinned to the temp cache dir.
test_case() {
  local name="$1"; local payload="$2"; local expected_exit="$3"; local expected_pattern="${4:-}"
  local tmp_stderr; tmp_stderr="$(/usr/bin/mktemp)"
  local actual_exit=0
  /usr/bin/printf '%s' "$payload" | HOME="$TEST_HOME" /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
  local actual_stderr; actual_stderr="$(/bin/cat "$tmp_stderr")"; /bin/rm -f "$tmp_stderr"
  local ok=1
  [ "$actual_exit" != "$expected_exit" ] && ok=0
  if [ -n "$expected_pattern" ] && ! /usr/bin/printf '%s' "$actual_stderr" | /usr/bin/grep -qE "$expected_pattern"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s (exit=%s expected=%s)\n  stderr: %s\n' "$name" "$actual_exit" "$expected_exit" "$actual_stderr"
    FAIL=$((FAIL + 1))
  fi
}

# --- Payload builders ---
write_payload() {
  # write_payload file_path cwd
  /usr/bin/jq -n --arg fp "$1" --arg cwd "$2" \
    '{tool_name: "Write", tool_input: {file_path: $fp, content: "x"}, cwd: $cwd}'
}
edit_payload() {
  /usr/bin/jq -n --arg fp "$1" --arg cwd "$2" \
    '{tool_name: "Edit", tool_input: {file_path: $fp, old_string: "a", new_string: "b"}, cwd: $cwd}'
}
# mcp_payload tool [cwd] / bash_payload command [cwd]
#
# The cwd defaults INSIDE the pinned workspace root, and that default is load-bearing.
# Both builders hard-coded cwd "/tmp" until now, which put every mcp and Bash payload
# OUTSIDE the governed tree — and the #4436 workspace-scope gate early-exits 0 for an
# out-of-tree cwd, before the ceiling check runs. Three ceiling assertions on these two
# builders were therefore being answered by the scope gate rather than by the ceiling
# they name, and an mcp arm that expects a BLOCK could never see one. This is a second,
# independent cause of the same symptom as the HOME-pin defect fixed at setup: both made
# a gate ABOVE the ceiling answer a question about the ceiling.
#
# An arm that genuinely wants an out-of-tree cwd passes one explicitly.
mcp_payload() {
  /usr/bin/jq -n --arg tool "$1" --arg cwd "${2:-${TEST_WS}/pmo-platform}" \
    '{tool_name: $tool, tool_input: {}, cwd: $cwd}'
}
bash_payload() {
  /usr/bin/jq -n --arg cmd "$1" --arg cwd "${2:-${TEST_WS}/pmo-platform}" \
    '{tool_name: "Bash", tool_input: {command: $cmd}, cwd: $cwd}'
}

echo "================================"
echo "block-autonomy-ceiling.sh tests (C5 #1163)"
echo "workspace=$TEST_WS"
echo "================================"

# =====================================================================
# CEILING CHECK — block / pass (enforce mode)
# =====================================================================
echo ""
echo "Ceiling check (enforce mode)"
echo "---"
set_mode "enforce"

# At recommend (ceiling=1): a Tier-2 staging write EXCEEDS the ceiling → block.
set_ceiling 1
test_case "above-ceiling: 08-Generated write (Tier 2) at recommend → BLOCK" \
  "$(write_payload "${TEST_WS}/projects/Default/08-Generated/out.md" "${TEST_WS}/projects/Default")" \
  2 "BLOCK-AUTONOMY-003"

# At recommend (ceiling=1): a Tier-1 stakeholder write is AT the ceiling → allow.
test_case "at-ceiling: projects stakeholder write (Tier 1) at recommend → ALLOW" \
  "$(write_payload "${TEST_WS}/projects/Default/01-Governance/plan.md" "${TEST_WS}/projects/Default")" \
  0

# At bounded_auto (ceiling=2): the Tier-2 staging write is AT the ceiling → allow.
set_ceiling 2
test_case "at-ceiling: 08-Generated write (Tier 2) at bounded_auto → ALLOW" \
  "$(write_payload "${TEST_WS}/projects/Default/08-Generated/out.md" "${TEST_WS}/projects/Default")" \
  0

# At off (ceiling=0): a Tier-1 write EXCEEDS the ceiling → block.
set_ceiling 0
test_case "above-ceiling: projects write (Tier 1) at off → BLOCK" \
  "$(write_payload "${TEST_WS}/projects/Default/01-Governance/plan.md" "${TEST_WS}/projects/Default")" \
  2 "BLOCK-AUTONOMY-003"

# MCP write-verb tool (Tier 1) at off (ceiling=0) → block.
test_case "above-ceiling: mcp write-verb (Tier 1) at off → BLOCK" \
  "$(mcp_payload 'mcp__atlassian__createJiraIssue')" \
  2 "BLOCK-AUTONOMY-003"

# MCP write-verb tool (Tier 1) at recommend (ceiling=1) → at ceiling → allow.
set_ceiling 1
test_case "at-ceiling: mcp write-verb (Tier 1) at recommend → ALLOW" \
  "$(mcp_payload 'mcp__atlassian__createJiraIssue')" \
  0

# =====================================================================
# IRREDUCIBLE TIER-0 FLOOR — always block (mode + level independent)
# =====================================================================
echo ""
echo "Irreducible Tier-0 floor (always-block)"
echo "---"

# Governance-file Write at bounded_auto (highest ceiling) → STILL block (AC3).
set_ceiling 2
set_mode "enforce"
test_case "Tier-0 override: CLAUDE.md Write at bounded_auto → BLOCK (AC3)" \
  "$(write_payload "${TEST_WS}/CLAUDE.md" "${TEST_WS}/pmo-platform/.claude/worktrees/wt")" \
  2 "BLOCK-AUTONOMY-001"

# SKILL.md is NOT in this hook's governance set — see #5515. It is guarded by
# block-skill-direct-edit.sh (Gate 2), which owns skills and can tell a sanctioned
# pmo-skill-editor session from a straight edit. This hook cannot: always_block
# ignores every signal including the session sentinel, so carrying SKILL.md here
# made the sanctioned path structurally unreachable — a valid session satisfied
# Gate 2 and was still denied here.
#
# This asserts the ABSENCE of a block, so it is worth stating what stops it from
# being a hole: the same edit is still denied by Gate 2 absent a live,
# correctly-targeted, non-stale sentinel. That is Gate 2's contract and is
# exercised in block-skill-direct-edit.test.sh, not here. A regression that
# re-adds the arm fails this case; a regression that weakens Gate 2 fails there.
test_case "SKILL.md Edit at bounded_auto → ALLOW here (Gate 2 owns skills; #5515)" \
  "$(edit_payload "${TEST_WS}/pmo-platform/core/skills/foo/SKILL.md" "${TEST_WS}/pmo-platform")" \
  0 ""

# Control for the case above: the governance files this hook DOES own must still
# block at the same ceiling and mode. If this passes while the case above also
# passes, the arm removal was surgical; if both allow, the hook has been broken
# rather than narrowed.
test_case "Tier-0 override: OPERATIONS.md Edit at bounded_auto → BLOCK (control)" \
  "$(edit_payload "${TEST_WS}/pmo-platform/core/governance/OPERATIONS.md" "${TEST_WS}/pmo-platform")" \
  2 "BLOCK-AUTONOMY-001"

test_case "Tier-0 override: settings.json Write at bounded_auto → BLOCK" \
  "$(write_payload "${TEST_WS}/.claude/settings.json" "${TEST_WS}/pmo-platform")" \
  2 "BLOCK-AUTONOMY-001"

test_case "Tier-0 override: a hook file Write at bounded_auto → BLOCK" \
  "$(write_payload "${TEST_WS}/.claude/hooks/evil.sh" "${TEST_WS}/pmo-platform")" \
  2 "BLOCK-AUTONOMY-001"

# Governance-file Write under .autonomy-mode=warn → STILL block (proves Tier-0 is
# always-enforce, NOT warn-gated).
set_mode "warn"
test_case "Tier-0 override under warn: CLAUDE.md Write, mode=warn → STILL BLOCK" \
  "$(write_payload "${TEST_WS}/CLAUDE.md" "${TEST_WS}/pmo-platform/.claude/worktrees/wt")" \
  2 "BLOCK-AUTONOMY-001"

# Governance-file Write under .autonomy-mode=off → STILL block.
set_mode "off"
test_case "Tier-0 override under off: OPERATIONS.md Write, mode=off → STILL BLOCK" \
  "$(write_payload "${TEST_WS}/pmo-platform/core/governance/OPERATIONS.md" "${TEST_WS}/pmo-platform")" \
  2 "BLOCK-AUTONOMY-001"

# --- Location anchoring of the -001 governance set (#5812) ---
# The three document entries were bare basename globs until #5812, so a file merely
# NAMED CLAUDE.md was blocked wherever on disk it lived. The suite could not see that:
# every pre-existing arm asserts a block, and a basename glob satisfies all of them, so
# the whole set passed identically before and after anchoring. The missing half is a
# must-NOT-block arm, and a lone allow-assertion is worthless without something that
# proves the hook was live when it allowed.
#
# Each pair below is therefore discriminating by construction: identical payload shape
# and identical cwd, with ONLY the target path differing. The block arm is what stops
# its partner's exit 0 from being an inert zero — it proves the -001 case arm was
# reached and evaluated for both payloads. (It holds even when this file is run outside
# test-runner.sh: the Tier-0 floor is evaluated BEFORE the master-activation and
# workspace-scope gates, so the block arm cannot be short-circuited by either.)
set_mode "enforce"
set_ceiling 2

test_case "#5812 sensitivity: the anchored charter still BLOCKS (pair control)" \
  "$(write_payload "${TEST_WS}/CLAUDE.md" "${TEST_WS}/personal/product-repo")" \
  2 "BLOCK-AUTONOMY-001"

test_case "#5812 specificity: another repo's root CLAUDE.md → ALLOW (it is not the charter)" \
  "$(write_payload "${TEST_WS}/personal/product-repo/CLAUDE.md" "${TEST_WS}/personal/product-repo")" \
  0 ""

# RELEASE_PROTOCOL.md carried no fixture at all before #5812, so its scope was
# unasserted in BOTH directions. Same discriminating-pair shape.
test_case "#5812 sensitivity: RELEASE_PROTOCOL.md in the platform checkout → BLOCK" \
  "$(edit_payload "${TEST_WS}/pmo-platform/release/governance/RELEASE_PROTOCOL.md" "${TEST_WS}/pmo-platform")" \
  2 "BLOCK-AUTONOMY-001"

test_case "#5812 specificity: a RELEASE_PROTOCOL.md outside the checkout → ALLOW" \
  "$(edit_payload "${TEST_WS}/personal/product-repo/RELEASE_PROTOCOL.md" "${TEST_WS}/personal/product-repo")" \
  0 ""

# Anchoring must not have quietly re-introduced the worktree exemption this rule's own
# comment says it does not grant. A governance file inside a worktree NESTED under the
# platform checkout stays blocked, because the checkout anchor matches at any depth.
test_case "#5812: OPERATIONS.md inside a nested worktree → STILL BLOCK (no worktree exemption)" \
  "$(edit_payload "${TEST_WS}/pmo-platform/.claude/worktrees/wt/core/governance/OPERATIONS.md" "${TEST_WS}/pmo-platform/.claude/worktrees/wt")" \
  2 "BLOCK-AUTONOMY-001"

# A governance basename sitting directly AT the checkout root — the one-path gap the
# BLOCK-AUTONOMY-002 comment below calls out for its own domain globs. Covered by the
# paired checkout-root pattern, and asserted so a future tidy-up cannot drop it.
test_case "#5812: OPERATIONS.md at the platform checkout root → BLOCK (root-level arm)" \
  "$(edit_payload "${TEST_WS}/pmo-platform/OPERATIONS.md" "${TEST_WS}/pmo-platform")" \
  2 "BLOCK-AUTONOMY-001"

# --- The operations context anchor is a governance file (#5293) ---
# projects/CLAUDE.md is the operations context anchor: installer-produced,
# pointer-only, and agent-unwritable per operations-bridge.md § Context-Load Contract.
# Location-anchoring the -001 set (#5812) narrowed the old bare */CLAUDE.md glob, which
# had been covering this file incidentally. BLOCK-AUTONOMY-002 does NOT cover it either
# — -002 blocks a projects-cwd session writing INTO pmo-platform, not a projects-rooted
# session editing its own anchor, and after the directional split below the converse
# direction is not a floor at all. Without an explicit arm the anchor would be the one
# governance surface the anchoring left unguarded, so it carries its own entry and its
# own must-block case.
#
# Same-domain by construction (projects cwd → projects target), which is what makes this
# a -001 assertion rather than a cross-domain one: if the arm were ever removed from the
# governance set this payload would fall through to the ceiling check and ALLOW.
test_case "#5293: projects/CLAUDE.md (the operations anchor) → BLOCK (-001)" \
  "$(edit_payload "${TEST_WS}/projects/CLAUDE.md" "${TEST_WS}/projects/Default")" \
  2 "BLOCK-AUTONOMY-001"

# Specificity partner: a CLAUDE.md one level deeper is a PROJECT's own file, not the
# anchor, and is not in the governance set. Without this arm the entry above could be
# a path prefix rather than the exact anchor and no case would notice.
test_case "#5293 specificity: a project-level CLAUDE.md is NOT the anchor → ALLOW" \
  "$(edit_payload "${TEST_WS}/projects/Default/CLAUDE.md" "${TEST_WS}/projects/Default")" \
  0 ""

# =====================================================================
# CROSS-DOMAIN BRIDGE WRITES — the directional split (#5293)
# =====================================================================
# The two directions are NOT symmetric and no longer share a rule.
#
#   projects cwd  -> pmo-platform target : BLOCK-AUTONOMY-002, always_block.
#       Operations content entering a PUBLIC git repo, where it becomes committable
#       and pushable. Irreducible Tier-0: mode-independent, level-independent, and
#       above the master gate.
#
#   pmo-platform cwd -> projects target  : BLOCK-AUTONOMY-004, apply_block.
#       An engineering checkout writing into the untracked sibling operations tree.
#       Nothing can reach the repo — git cannot see the target — so this is a
#       layer-discipline signal, not a disclosure control. Mode-gated, and below the
#       master and scope gates.
#
# The matrix below asserts the asymmetry in both directions and under every mode,
# because the failure that matters is not "-004 is too strict" but "-002 got widened
# by one path while nobody was looking".
echo ""
echo "cross-domain bridge writes — directional split (#5293)"
echo "---"
set_ceiling 2

XD_HIGH_RISK="$(write_payload "${TEST_WS}/pmo-platform/core/foo.md" "${TEST_WS}/projects/Default")"
XD_LOW_RISK="$(write_payload "${TEST_WS}/projects/Default/notes.md" "${TEST_WS}/pmo-platform")"

# --- -002: the high-risk direction blocks under EVERY mode, including off ---
# always_block does not consult get_mode(), so all three arms must return the same
# verdict. Asserting all three (rather than one) is the guard against a future edit
# routing this direction through apply_block, which would pass a single enforce-mode
# arm unchanged while silently opening the direction under warn and off.
for xd_mode in enforce warn off; do
  set_mode "$xd_mode"
  test_case "-002 high-risk (projects cwd → pmo-platform), mode=${xd_mode} → BLOCK" \
    "$XD_HIGH_RISK" 2 "BLOCK-AUTONOMY-002"
done

# --- -002 must not fire on the direction it no longer owns ---
# The pre-#5293 rule blocked this payload as -002. If a future edit restores the
# symmetric branch, this arm fails on the rule id even though the exit status matches.
set_mode "enforce"
test_case "-002 no longer claims the low-risk direction (rule id is -004, not -002)" \
  "$XD_LOW_RISK" 2 "BLOCK-AUTONOMY-004"

# --- -004: the low-risk direction is mode-gated ---
set_mode "enforce"
test_case "-004 low-risk (pmo-platform cwd → projects), mode=enforce → BLOCK" \
  "$XD_LOW_RISK" 2 "BLOCK-AUTONOMY-004"

# The -004 override text must name the relaunch remedy and must NOT lead with the
# whole-session security-hook disable. Asserted on the enforce arm because that is the
# only mode that prints an Override line.
test_case "-004 override names the relaunch remedy, not CLAUDE_HOOK_BYPASS" \
  "$XD_LOW_RISK" 2 "Override: .*relaunch"

set_mode "warn"
WARN4_BEFORE=0
[ -f "$WARN_LOG" ] && WARN4_BEFORE="$(/usr/bin/wc -l < "$WARN_LOG" | /usr/bin/tr -d '[:space:]')"
test_case "-004 low-risk, mode=warn → ALLOW + WARN (friction removed)" \
  "$XD_LOW_RISK" 0 "BLOCK-AUTONOMY-004.*WARN|WARN.*BLOCK-AUTONOMY-004"
WARN4_AFTER=0
[ -f "$WARN_LOG" ] && WARN4_AFTER="$(/usr/bin/wc -l < "$WARN_LOG" | /usr/bin/tr -d '[:space:]')"
if [ "$WARN4_AFTER" -gt "$WARN4_BEFORE" ]; then
  echo "PASS: -004 warn arm appended to autonomy-warn-log.jsonl ($WARN4_BEFORE → $WARN4_AFTER)"; PASS=$((PASS + 1))
else
  echo "FAIL: -004 warn arm did NOT append to autonomy-warn-log.jsonl"; FAIL=$((FAIL + 1))
fi

set_mode "off"
test_case "-004 low-risk, mode=off → ALLOW" \
  "$XD_LOW_RISK" 0

# --- -004 under master-OFF: allowed, and NOT logged ---
# -004 sits below the master-activation gate, so master-OFF makes it inert — the hook
# exits 0 at the gate and no warn row is written. That is intended, and it is the exact
# boundary of the "-004 preserves an audit trail" claim: the trail exists only where the
# operator has opted into the security-hook suite. Master-OFF is the SHIPPED default.
#
# Exit status alone cannot distinguish this from the warn arm above (both exit 0), so
# the discriminating assertion is the ABSENCE of a new warn row. Paired with the -002
# arm immediately below, which proves the hook was live and the payload was reachable.
set_mode "warn"
XD_MASTER_OFF="$(/usr/bin/mktemp -d)"
WARNM_BEFORE=0
[ -f "$WARN_LOG" ] && WARNM_BEFORE="$(/usr/bin/wc -l < "$WARN_LOG" | /usr/bin/tr -d '[:space:]')"
xdm_err="$(/usr/bin/mktemp)"; xdm_exit=0
/usr/bin/printf '%s' "$XD_LOW_RISK" \
  | HOME="$TEST_HOME" PMO_PLATFORM_CONFIG_ROOT="$XD_MASTER_OFF" /bin/bash "$HOOK" 2>"$xdm_err" >/dev/null || xdm_exit="$?"
xdm_stderr="$(/bin/cat "$xdm_err")"; /bin/rm -f "$xdm_err"
WARNM_AFTER=0
[ -f "$WARN_LOG" ] && WARNM_AFTER="$(/usr/bin/wc -l < "$WARN_LOG" | /usr/bin/tr -d '[:space:]')"
if [ "$xdm_exit" = 0 ] && [ "$WARNM_AFTER" = "$WARNM_BEFORE" ]; then
  echo "PASS: -004 under master-OFF → exit 0 AND no warn row (the audit trail needs master ON)"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: -004 master-OFF (exit=%s expected=0, warn rows %s → %s expected unchanged)\n  stderr: %s\n' \
    "$xdm_exit" "$WARNM_BEFORE" "$WARNM_AFTER" "$xdm_stderr"; FAIL=$((FAIL + 1))
fi

# -002 on the SAME master-OFF config: still blocks. This is what proves the arm above
# is -004 going inert rather than the whole hook going inert, and it is the security
# assertion of the pair — the disclosure-bearing direction survives master-OFF.
xdm2_err="$(/usr/bin/mktemp)"; xdm2_exit=0
/usr/bin/printf '%s' "$XD_HIGH_RISK" \
  | HOME="$TEST_HOME" PMO_PLATFORM_CONFIG_ROOT="$XD_MASTER_OFF" /bin/bash "$HOOK" 2>"$xdm2_err" >/dev/null || xdm2_exit="$?"
xdm2_stderr="$(/bin/cat "$xdm2_err")"; /bin/rm -f "$xdm2_err"; /bin/rm -rf "$XD_MASTER_OFF"
if [ "$xdm2_exit" = 2 ] && /usr/bin/printf '%s' "$xdm2_stderr" | /usr/bin/grep -qE "BLOCK-AUTONOMY-002"; then
  echo "PASS: -002 under master-OFF → STILL BLOCKS (the floor is above the master gate)"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: -002 under master-OFF (exit=%s expected=2, want BLOCK-AUTONOMY-002)\n  stderr: %s\n' \
    "$xdm2_exit" "$xdm2_stderr"; FAIL=$((FAIL + 1))
fi

# --- Same-domain and empty-cwd_domain writes are untouched by the split ---
set_mode "enforce"
set_ceiling 2

test_case "same-domain: projects cwd writing projects/ (non-gov) at bounded_auto → ALLOW" \
  "$(write_payload "${TEST_WS}/projects/Default/08-Generated/x.md" "${TEST_WS}/projects/Default")" \
  0

test_case "same-domain: pmo-platform cwd writing pmo-platform/ → ALLOW" \
  "$(write_payload "${TEST_WS}/pmo-platform/core/notes.md" "${TEST_WS}/pmo-platform")" \
  0

# Empty cwd_domain: a session rooted AT the workspace root belongs to neither domain,
# so neither rule can fire. The target is a projects/ path, so a rule that tested the
# target alone would block here — this arm is what pins the mismatch to a PAIR.
test_case "empty cwd_domain: workspace-root cwd writing projects/ → ALLOW (no domain to cross)" \
  "$(write_payload "${TEST_WS}/projects/Default/08-Generated/y.md" "${TEST_WS}")" \
  0

# --- A governance target still hits -001 first, in BOTH directions ---
# -001 is evaluated before either cross-domain rule, so the rule id in stderr must be
# -001 even on a payload that ALSO satisfies a cross-domain condition. Both directions
# are asserted because the two rules now sit on opposite sides of the master gate, and
# only -001's precedence keeps their ordering irrelevant for governance targets.
test_case "precedence: governance target, projects cwd → -001 (not -002)" \
  "$(edit_payload "${TEST_WS}/pmo-platform/core/governance/OPERATIONS.md" "${TEST_WS}/projects/Default")" \
  2 "BLOCK-AUTONOMY-001"

test_case "precedence: governance target, pmo-platform cwd → -001 (not -004)" \
  "$(write_payload "${TEST_WS}/projects/CLAUDE.md" "${TEST_WS}/pmo-platform")" \
  2 "BLOCK-AUTONOMY-001"

# --- CLAUDE_HOOK_BYPASS is unaffected by the split ---
xdb_err="$(/usr/bin/mktemp)"; xdb_exit=0
/usr/bin/printf '%s' "$XD_LOW_RISK" \
  | HOME="$TEST_HOME" CLAUDE_HOOK_BYPASS=1 /bin/bash "$HOOK" 2>"$xdb_err" >/dev/null || xdb_exit="$?"
/bin/rm -f "$xdb_err"
if [ "$xdb_exit" = 0 ]; then
  echo "PASS: CLAUDE_HOOK_BYPASS=1 allows the -004 payload (bypass precedes every rule)"; PASS=$((PASS + 1))
else
  echo "FAIL: bypass did not allow the -004 payload (exit=$xdb_exit)"; FAIL=$((FAIL + 1))
fi

# =====================================================================
# H1 — the -004 read must be SAFE for payloads that never enter Write|Edit
# =====================================================================
# The hook runs `set -euo pipefail`. target_domain and cwd_domain are assigned inside
# the `case "$TOOL_NAME"` Write|Edit branch, but -004 is evaluated BELOW that branch,
# after the master and scope gates. A -004 condition that reads either variable without
# an unconditional declaration therefore aborts the hook with `unbound variable` on
# every Bash and every mcp call — the two highest-traffic matchers on this hook — and
# an aborted PreToolUse hook is a fail-OPEN.
#
# The arms below are the regression guard. They are only meaningful with an in-workspace
# cwd: an out-of-tree cwd is answered by the scope gate BEFORE -004 is reached, which is
# precisely why the pre-existing /tmp-cwd permissive cases could not have caught this.
echo ""
echo "H1 — unbound-variable safety below the Write|Edit branch (#5293)"
echo "---"
set_mode "enforce"
set_ceiling 0

test_case "H1: Bash payload, in-workspace cwd → ALLOW (not an unbound-variable abort)" \
  "$(bash_payload 'ls -la /tmp' "${TEST_WS}/pmo-platform")" \
  0

test_case "H1: non-write mcp payload, in-workspace cwd → ALLOW (not an unbound-variable abort)" \
  "$(mcp_payload 'mcp__atlassian__search' "${TEST_WS}/pmo-platform")" \
  0

# H1 discriminating control. A lone pair of allow-assertions is an inert zero: they pass
# identically against a hook with no -004 in it at all. This arm proves the payloads
# above actually REACH the -004 evaluation point under the same cwd, by sending a Write
# through it and requiring the block. If -004 were unreachable for this cwd, this fails
# and the two arms above are correctly read as untrustworthy.
set_ceiling 2
test_case "H1 control: same cwd, Write payload → -004 fires (proves the arms above reach it)" \
  "$XD_LOW_RISK" 2 "BLOCK-AUTONOMY-004"

# H1 differential. The two arms above pass against the PRE-#5293 hook too — it has no
# -004 to crash on — so on their own they demonstrate nothing about this change. This
# block builds the naive placement (the -004 branch with the declaration removed) in a
# sandbox and asserts the arms FAIL against it. That is the discrimination: the fixture
# is only worth having if some reachable implementation fails it.
H1_SANDBOX="$(/usr/bin/mktemp -d)"
/bin/mkdir -p "${H1_SANDBOX}/lib"
/bin/cp "${HOOK_DIR}/lib/"*.sh "${H1_SANDBOX}/lib/" 2>/dev/null || true
/bin/cp "${HOOK_DIR}/lib/"*.awk "${H1_SANDBOX}/lib/" 2>/dev/null || true
# Delete the unconditional declaration; leave everything else byte-identical.
/usr/bin/sed -e '/^target_domain=""[[:space:]]*#[[:space:]]*H1:/d' \
             -e '/^cwd_domain=""[[:space:]]*#[[:space:]]*H1:/d' \
             "$HOOK" > "${H1_SANDBOX}/block-autonomy-ceiling.sh"
/bin/chmod +x "${H1_SANDBOX}/block-autonomy-ceiling.sh"
/usr/bin/printf 'enforce' > "${H1_SANDBOX}/.autonomy-mode"
/usr/bin/printf '[security_hooks]\nmaster_enabled = true\n' > "${CONFIG_ROOT}/platform-config.toml"

h1_removed=$(( $(/usr/bin/grep -c . < "$HOOK") - $(/usr/bin/grep -c . < "${H1_SANDBOX}/block-autonomy-ceiling.sh") ))
h1_err="$(/usr/bin/mktemp)"; h1_exit=0
/usr/bin/printf '%s' "$(bash_payload 'ls -la /tmp' "${TEST_WS}/pmo-platform")" \
  | HOME="$TEST_HOME" /bin/bash "${H1_SANDBOX}/block-autonomy-ceiling.sh" 2>"$h1_err" >/dev/null || h1_exit="$?"
h1_stderr="$(/bin/cat "$h1_err")"; /bin/rm -f "$h1_err"
/bin/rm -rf "$H1_SANDBOX"
# Guard the differential itself: if sed removed nothing, the "sandbox" IS the real hook
# and its exit 0 would be meaningless. Require both a real edit and a real failure.
if [ "$h1_removed" = 2 ] && [ "$h1_exit" != 0 ]; then
  echo "PASS: H1 differential — naive placement (declaration deleted) aborts the Bash payload (exit=$h1_exit); the shipped placement does not"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: H1 differential inconclusive (lines removed=%s expected=2, sandbox exit=%s expected non-zero)\n  stderr: %s\n' \
    "$h1_removed" "$h1_exit" "$h1_stderr"; FAIL=$((FAIL + 1))
fi

# =====================================================================
# WARN-MODE + OFF-MODE ceiling behavior (NOT the Tier-0 floor)
# =====================================================================
echo ""
echo "warn-mode / off-mode ceiling"
echo "---"

set_ceiling 0   # off ceiling → a Tier-1 mcp write EXCEEDS it
set_mode "warn"
WARN_BEFORE=0
[ -f "$WARN_LOG" ] && WARN_BEFORE="$(/usr/bin/wc -l < "$WARN_LOG" | /usr/bin/tr -d '[:space:]')"

test_case "warn-mode: above-ceiling mcp write → exit 0 + WARN" \
  "$(mcp_payload 'mcp__atlassian__createJiraIssue')" \
  0 "WARN"

WARN_AFTER=0
[ -f "$WARN_LOG" ] && WARN_AFTER="$(/usr/bin/wc -l < "$WARN_LOG" | /usr/bin/tr -d '[:space:]')"
if [ "$WARN_AFTER" -gt "$WARN_BEFORE" ]; then
  echo "PASS: warn log grew (lines: $WARN_BEFORE → $WARN_AFTER)"; PASS=$((PASS + 1))
else
  echo "FAIL: warn log did NOT grow"; FAIL=$((FAIL + 1))
fi

set_mode "off"
test_case "off-mode: above-ceiling mcp write → exit 0 (no block)" \
  "$(mcp_payload 'mcp__atlassian__createJiraIssue')" \
  0

# =====================================================================
# PERMISSIVE DEFAULT — unmapped actions allow
# =====================================================================
echo ""
echo "permissive default (unmapped → allow)"
echo "---"
set_mode "enforce"
set_ceiling 0   # most restrictive ceiling; unmapped MUST still allow

test_case "permissive: unmapped Bash command at off-ceiling → ALLOW" \
  "$(bash_payload 'ls -la /tmp')" \
  0

test_case "permissive: non-write mcp tool (search) at off-ceiling → ALLOW" \
  "$(mcp_payload 'mcp__atlassian__search')" \
  0

test_case "permissive: Write to an unmapped path (outside projects/) at off-ceiling → ALLOW" \
  "$(write_payload "/tmp/scratch.txt" "/tmp")" \
  0

# =====================================================================
# NON-MUTATION early exit (out of matcher scope)
# =====================================================================
echo ""
echo "non-mutation early exit"
echo "---"
set_ceiling 0

test_case "Read tool → early exit (out of scope)" \
  '{"tool_name":"Read","tool_input":{"file_path":"/tmp/x"},"cwd":"/tmp"}' \
  0

test_case "WebFetch tool → early exit (out of scope)" \
  '{"tool_name":"WebFetch","tool_input":{"url":"https://example.com"},"cwd":"/tmp"}' \
  0

# =====================================================================
# BYPASS + malformed input
# =====================================================================
echo ""
echo "bypass + malformed input"
echo "---"
set_mode "enforce"
set_ceiling 2

BYPASS_BEFORE=0
[ -f "$BYPASS_LOG" ] && BYPASS_BEFORE="$(/usr/bin/wc -l < "$BYPASS_LOG" | /usr/bin/tr -d '[:space:]')"

# Bypass must allow even a Tier-0 governance write (env var set on the hook call).
bypass_stderr="$(/usr/bin/mktemp)"; bypass_exit=0
/usr/bin/printf '%s' "$(write_payload "${TEST_WS}/CLAUDE.md" "${TEST_WS}/pmo-platform")" \
  | HOME="$TEST_HOME" CLAUDE_HOOK_BYPASS=1 /bin/bash "$HOOK" 2>"$bypass_stderr" >/dev/null || bypass_exit="$?"
/bin/rm -f "$bypass_stderr"
if [ "$bypass_exit" = 0 ]; then
  echo "PASS: CLAUDE_HOOK_BYPASS=1 allows Tier-0 write (exit 0)"; PASS=$((PASS + 1))
else
  echo "FAIL: bypass did not allow (exit=$bypass_exit)"; FAIL=$((FAIL + 1))
fi
BYPASS_AFTER=0
[ -f "$BYPASS_LOG" ] && BYPASS_AFTER="$(/usr/bin/wc -l < "$BYPASS_LOG" | /usr/bin/tr -d '[:space:]')"
if [ "$BYPASS_AFTER" -gt "$BYPASS_BEFORE" ]; then
  echo "PASS: bypass log grew (lines: $BYPASS_BEFORE → $BYPASS_AFTER)"; PASS=$((PASS + 1))
else
  echo "FAIL: bypass log did NOT grow"; FAIL=$((FAIL + 1))
fi

test_case "malformed JSON → exit 2" \
  'this is not json' \
  2 "INPUT-INVALID"

# =====================================================================
# DEPENDENCY GATE — jq resolution lives in lib/dep-resolve.sh
# (GHSA-9cjm-v22x-4x33). Because resolution is in the HELPER, simulating
# missing jq requires sandboxing BOTH files: a copy of the hook + a copy of
# dep-resolve.sh with all three jq candidate paths sed'd to nonexistent.
# MODE-AWARE fail-closed posture (v3.74 build-security-hardening, S2 first
# conformance case): the dependency gate now runs AFTER mode detection.
#   - enforce (and the no-mode-file default): fail CLOSED (exit 2 +
#     DEPENDENCY-MISSING) — the always-enforce Tier-0 floor must not be silently
#     disabled by an unresolvable jq (the ADR-078 §Consequences residual).
#   - warn / off: DEGRADE (exit 0 + DEPENDENCY-DEGRADED:WARN) — no harder than a
#     rule match would block.
# A MISSING helper, by contrast, is fail-CLOSED (exit 2) in every mode.
# =====================================================================
echo ""
echo "dependency gate (jq via helper; mode-aware fail-closed vs warn-degrade)"
echo "---"

DEP_SANDBOX="$(/usr/bin/mktemp -d)"
/bin/mkdir -p "${DEP_SANDBOX}/lib"
/bin/cp "$HOOK" "${DEP_SANDBOX}/block-autonomy-ceiling.sh"
# Broken helper: point every jq candidate at a nonexistent path.
/usr/bin/sed -e 's#/usr/bin/jq#/nonexistent/jq#g' \
             -e 's#/opt/homebrew/bin/jq#/nonexistent/opt/jq#g' \
             -e 's#/usr/local/bin/jq#/nonexistent/local/jq#g' \
             "${HOOK_DIR}/lib/dep-resolve.sh" > "${DEP_SANDBOX}/lib/dep-resolve.sh"
/bin/chmod +x "${DEP_SANDBOX}/block-autonomy-ceiling.sh"

dep_payload="$(write_payload "${TEST_WS}/CLAUDE.md" "${TEST_WS}/pmo-platform")"

# enforce mode + a would-block Tier-0 governance write: jq unresolvable → the
# always-enforce floor cannot be evaluated → FAIL CLOSED (exit 2 +
# DEPENDENCY-MISSING). This is the fix for the ADR-078 §Consequences residual:
# the old code exited 0 (fail-open) here even under enforce.
/usr/bin/printf 'enforce' > "${DEP_SANDBOX}/.autonomy-mode"
dep_err="$(/usr/bin/mktemp)"; dep_exit=0
/usr/bin/printf '%s' "$dep_payload" \
  | HOME="$TEST_HOME" /bin/bash "${DEP_SANDBOX}/block-autonomy-ceiling.sh" 2>"$dep_err" >/dev/null || dep_exit="$?"
dep_stderr="$(/bin/cat "$dep_err")"; /bin/rm -f "$dep_err"
if [ "$dep_exit" = 2 ] \
   && /usr/bin/printf '%s' "$dep_stderr" | /usr/bin/grep -qE "DEPENDENCY-MISSING" \
   && ! /usr/bin/printf '%s' "$dep_stderr" | /usr/bin/grep -qE "DEPENDENCY-WARN|DEGRADED \(fail-open\)"; then
  echo "PASS: jq missing + enforce → FAIL CLOSED (exit 2 + DEPENDENCY-MISSING) even for a Tier-0 write"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: jq-missing enforce fail-closed (exit=%s expected=2, want DEPENDENCY-MISSING, no fail-open string)\n  stderr: %s\n' "$dep_exit" "$dep_stderr"; FAIL=$((FAIL + 1))
fi

# warn mode + jq missing: DEGRADE to exit 0 (DEPENDENCY-DEGRADED:WARN) — a warn
# hook must not block harder than a rule match would when the dependency is gone.
/usr/bin/printf 'warn' > "${DEP_SANDBOX}/.autonomy-mode"
depw_err="$(/usr/bin/mktemp)"; depw_exit=0
/usr/bin/printf '%s' "$dep_payload" \
  | HOME="$TEST_HOME" /bin/bash "${DEP_SANDBOX}/block-autonomy-ceiling.sh" 2>"$depw_err" >/dev/null || depw_exit="$?"
depw_stderr="$(/bin/cat "$depw_err")"; /bin/rm -f "$depw_err"
if [ "$depw_exit" = 0 ] && /usr/bin/printf '%s' "$depw_stderr" | /usr/bin/grep -qE "DEPENDENCY-DEGRADED:WARN"; then
  echo "PASS: jq missing + warn → DEGRADE (exit 0 + DEPENDENCY-DEGRADED:WARN)"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: jq-missing warn-degrade (exit=%s expected=0, want DEPENDENCY-DEGRADED:WARN)\n  stderr: %s\n' "$depw_exit" "$depw_stderr"; FAIL=$((FAIL + 1))
fi

# Missing helper entirely → fail CLOSED (exit 2). The exact readable-before-source
# guard exists precisely so bash 3.2's exit-1-on-failed-source cannot fail OPEN.
NOHELPER_SANDBOX="$(/usr/bin/mktemp -d)"
/bin/cp "$HOOK" "${NOHELPER_SANDBOX}/block-autonomy-ceiling.sh"
/bin/chmod +x "${NOHELPER_SANDBOX}/block-autonomy-ceiling.sh"
nohelper_err="$(/usr/bin/mktemp)"; nohelper_exit=0
/usr/bin/printf '%s' "$dep_payload" \
  | HOME="$TEST_HOME" /bin/bash "${NOHELPER_SANDBOX}/block-autonomy-ceiling.sh" 2>"$nohelper_err" >/dev/null || nohelper_exit="$?"
nohelper_stderr="$(/bin/cat "$nohelper_err")"; /bin/rm -f "$nohelper_err"
if [ "$nohelper_exit" = 2 ] && /usr/bin/printf '%s' "$nohelper_stderr" | /usr/bin/grep -qE "LIB-MISSING"; then
  echo "PASS: dep-resolve.sh missing → fail-CLOSED exit 2 (LIB-MISSING)"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: helper-missing fail-closed (exit=%s expected=2, want LIB-MISSING)\n  stderr: %s\n' "$nohelper_exit" "$nohelper_stderr"; FAIL=$((FAIL + 1))
fi

/bin/rm -rf "$DEP_SANDBOX" "$NOHELPER_SANDBOX"

# =====================================================================
# SUITE R — DIRECT-RESOLVE PATH (cache ABSENT), section-awareness end to end
# =====================================================================
# Suite letter R (Reader). P is taken by the install-regression preservation suite;
# C and S are reserved by sibling cards in this release.
#
# WHY THIS SUITE EXISTS. Every ceiling assertion above sets the ceiling through the
# CACHE file, so resolve_level_direct — the fallback the hook uses whenever the
# SessionStart primer has not run, or a tool call lands before it — was never exercised
# by any test. That is the path the section-blindness defect lived on. These cases delete
# the cache and drive the ceiling from a seeded operator.toml, through the REAL hook.
#
# The four fail-OPEN shapes (B exact-name key under another section sorting first,
# C same-PREFIX key under another section, K dotted subtable header, O same-PREFIX key
# INSIDE [automation]) are asserted as BLOCKS. Before the hardening each of them
# resolved bounded_auto(2) from a config whose [automation] table says off(0), and the
# same payload was ALLOWED. The pre/post delta is characterized fixture-by-fixture in
# tests/prime-autonomy-ceiling-cache.test.sh; this suite asserts the consequence where
# it actually matters — the hook's allow/block verdict.
#
# B/C/K are closed by section-awareness; O is closed ONLY by the "=" terminator, which
# is why it is arm R-4b rather than a fourth variation on R-4.
echo ""
echo "Suite R — direct-resolve path (cache absent)"
echo "---"
set_mode "enforce"

# Master activation for this suite is the suite-wide seed written at setup ($CONFIG_ROOT,
# same path) — this suite no longer writes its own. Under test-runner.sh,
# PMO_PLATFORM_CONFIG_ROOT is exported master-ON and takes precedence over both.
R_CFG="$CONFIG_ROOT"

# seed_operator_toml <body> — write the fixture and DELETE the cache, so the hook must
# take the direct-resolve path. Deleting the cache is the whole point of the suite.
seed_operator_toml() {
  /usr/bin/printf '%s\n' "$1" > "${R_CFG}/operator.toml"
  /bin/rm -f "$CACHE_FILE"
}

R_TIER1_PAYLOAD="$(write_payload "${TEST_WS}/projects/Default/01-Governance/plan.md" "${TEST_WS}/projects/Default")"

# R-1 sensitivity: a plain in-section bounded_auto resolves 2 → the Tier-1 write is
# at-ceiling → ALLOW. Without this arm every block below could be a hook that blocks
# unconditionally once the cache is gone.
seed_operator_toml '[automation]
automation_level = "bounded_auto"'
test_case "R-1 direct-resolve, cache absent: [automation] bounded_auto → Tier-1 write ALLOWED" \
  "$R_TIER1_PAYLOAD" 0

# R-2 subject: the same read at off resolves 0 → the Tier-1 write exceeds → BLOCK.
# R-1 and R-2 are the discrimination pair: the direct path returns different verdicts
# for different configs, so it is genuinely reading the file.
seed_operator_toml '[automation]
automation_level = "off"'
test_case "R-2 direct-resolve, cache absent: [automation] off → Tier-1 write BLOCKED" \
  "$R_TIER1_PAYLOAD" 2 "BLOCK-AUTONOMY-003"

# R-3 fail-OPEN closure: an exact-name key under ANOTHER section, sorting BEFORE
# [automation]. Pre-hardening this resolved bounded_auto(2) and ALLOWED the write.
seed_operator_toml '[aaa_other]
automation_level = "bounded_auto"

[automation]
automation_level = "off"'
test_case "R-3 fail-OPEN closed: colliding exact-name key under another section → still BLOCKED" \
  "$R_TIER1_PAYLOAD" 2 "BLOCK-AUTONOMY-003"

# R-4 fail-OPEN closure: a same-PREFIX key. The prior reader had no "=" terminator, so
# a DIFFERENTLY-NAMED key collided too — the hazard was the prefix class, not the name.
seed_operator_toml '[aaa_other]
automation_level_ci_autoresolve = "bounded_auto"

[automation]
automation_level = "off"'
test_case "R-4 fail-OPEN closed: same-PREFIX key automation_level_ci_autoresolve → still BLOCKED" \
  "$R_TIER1_PAYLOAD" 2 "BLOCK-AUTONOMY-003"

# R-4b is R-4's matched pair, and it is the arm that actually pins the "=" terminator.
# R-4 puts the prefix key under ANOTHER section, so section-awareness alone already
# excludes it and the terminator is never consulted — R-4 passes with the terminator
# deleted. Here the prefix key is INSIDE [automation] and sorts ABOVE the real key, so
# the reader reaches it first and the terminator is the ONLY thing that can reject it.
# Without this arm the terminator could be removed and both hook suites stayed green
# while off(0) silently resolved back to bounded_auto(2) and this write was ALLOWED.
seed_operator_toml '[automation]
automation_level_ci_autoresolve = "bounded_auto"
automation_level = "off"'
test_case "R-4b fail-OPEN closed: same-PREFIX key INSIDE [automation], above the real key → still BLOCKED" \
  "$R_TIER1_PAYLOAD" 2 "BLOCK-AUTONOMY-003"

# R-5 fail-OPEN closure: a dotted subtable header. A section probe anchored
# ^\[[a-z_]+\] would not even see this line; the reader string-compares the trimmed
# header, so [automation.experimental] is correctly NOT the target section.
seed_operator_toml '[automation.experimental]
automation_level = "bounded_auto"

[automation]
automation_level = "off"'
test_case "R-5 fail-OPEN closed: dotted subtable [automation.experimental] → still BLOCKED" \
  "$R_TIER1_PAYLOAD" 2 "BLOCK-AUTONOMY-003"

# R-6 no-regression: absent operator.toml keeps the documented recommend(1) default, so
# a Tier-2 staging write still exceeds the ceiling.
/bin/rm -f "${R_CFG}/operator.toml" "$CACHE_FILE"
test_case "R-6 direct-resolve, no operator.toml at all → recommend(1) default holds (Tier-2 BLOCKED)" \
  "$(write_payload "${TEST_WS}/projects/Default/08-Generated/out.md" "${TEST_WS}/projects/Default")" \
  2 "BLOCK-AUTONOMY-003"

# R-7 floor invariant: the irreducible Tier-0 floor runs BEFORE the master gate and
# before the ceiling check, so it must still block with the ceiling read at its most
# permissive AND with the cache absent. This is the assertion that would catch a change
# to the ceiling reader that accidentally reordered or short-circuited the floor.
seed_operator_toml '[automation]
automation_level = "bounded_auto"'
test_case "R-7 Tier-0 floor still ALWAYS enforces (bounded_auto, cache absent, enforce)" \
  "$(write_payload "${TEST_WS}/pmo-platform/CLAUDE.md" "${TEST_WS}/pmo-platform")" \
  2 "BLOCK-AUTONOMY-001"

# R-8 blast-radius bound: with master OFF (the SHIPPED default), the ceiling check is
# inert — so the reader change reaches only instances that opted in. Asserted by driving
# the R-2 config, which blocks under master ON, and observing exit 0 under master OFF.
R_MASTER_OFF="$(/usr/bin/mktemp -d)"
seed_operator_toml '[automation]
automation_level = "off"'
r8_err="$(/usr/bin/mktemp)"; r8_exit=0
/usr/bin/printf '%s' "$R_TIER1_PAYLOAD" \
  | HOME="$TEST_HOME" PMO_PLATFORM_CONFIG_ROOT="$R_MASTER_OFF" /bin/bash "$HOOK" 2>"$r8_err" >/dev/null || r8_exit="$?"
r8_stderr="$(/bin/cat "$r8_err")"; /bin/rm -f "$r8_err"; /bin/rm -rf "$R_MASTER_OFF"
if [ "$r8_exit" = 0 ]; then
  echo "PASS: R-8 master-OFF (shipped default) → ceiling check inert, identical payload exits 0"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: R-8 master-OFF inert (exit=%s expected=0)\n  stderr: %s\n' "$r8_exit" "$r8_stderr"; FAIL=$((FAIL + 1))
fi

# R-9 floor-under-master-OFF: the Tier-0 floor is NOT gated by master activation. Paired
# with R-8 on the same master-OFF config, this is what proves R-8's exit 0 is the ceiling
# going inert and not the whole hook going inert.
R_MASTER_OFF2="$(/usr/bin/mktemp -d)"
r9_err="$(/usr/bin/mktemp)"; r9_exit=0
/usr/bin/printf '%s' "$(write_payload "${TEST_WS}/pmo-platform/CLAUDE.md" "${TEST_WS}/pmo-platform")" \
  | HOME="$TEST_HOME" PMO_PLATFORM_CONFIG_ROOT="$R_MASTER_OFF2" /bin/bash "$HOOK" 2>"$r9_err" >/dev/null || r9_exit="$?"
r9_stderr="$(/bin/cat "$r9_err")"; /bin/rm -f "$r9_err"; /bin/rm -rf "$R_MASTER_OFF2"
if [ "$r9_exit" = 2 ] && /usr/bin/printf '%s' "$r9_stderr" | /usr/bin/grep -qE "BLOCK-AUTONOMY-001"; then
  echo "PASS: R-9 master-OFF → Tier-0 floor STILL blocks (R-8's exit 0 is the ceiling, not the hook)"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: R-9 floor under master-OFF (exit=%s expected=2, want BLOCK-AUTONOMY-001)\n  stderr: %s\n' "$r9_exit" "$r9_stderr"; FAIL=$((FAIL + 1))
fi

# Leave platform-config.toml in place — it is the suite-wide activation seed, not
# Suite R's to remove. Only the operator.toml fixture Suite R authored is cleaned up.
/bin/rm -f "${R_CFG}/operator.toml"

# run_hook_env VAR=VAL... -- payload  → sets $RHE_EXIT and $RHE_STDERR.
# test_case pins HOME and inherits the exported CLAUDE_WORKSPACE_ROOT, which is exactly
# right for every arm above and exactly wrong for Suite N, whose whole subject is what
# happens when CLAUDE_WORKSPACE_ROOT arrives in a different shape. This runs the same
# hook with an arbitrary per-case environment prefix instead.
RHE_EXIT=0
RHE_STDERR=""
run_hook_env() {
  local payload="$1"; shift
  local err; err="$(/usr/bin/mktemp)"
  RHE_EXIT=0
  /usr/bin/printf '%s' "$payload" \
    | HOME="$TEST_HOME" /usr/bin/env "$@" /bin/bash "$HOOK" 2>"$err" >/dev/null || RHE_EXIT="$?"
  RHE_STDERR="$(/bin/cat "$err")"; /bin/rm -f "$err"
}

# assert_hook name expected_exit expected_pattern — grade the last run_hook_env call.
assert_hook() {
  local name="$1"; local want_exit="$2"; local want_pat="${3:-}"
  local ok=1
  [ "$RHE_EXIT" != "$want_exit" ] && ok=0
  if [ -n "$want_pat" ] && ! /usr/bin/printf '%s' "$RHE_STDERR" | /usr/bin/grep -qE "$want_pat"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s (exit=%s expected=%s)\n  stderr: %s\n' "$name" "$RHE_EXIT" "$want_exit" "$RHE_STDERR"
    FAIL=$((FAIL + 1))
  fi
}

# =====================================================================
# SUITE W — the -001 governance set must reach working trees of THIS
#           repository that live OUTSIDE ${PRIMARY_ROOT}/pmo-platform
# =====================================================================
# WHY THIS SUITE EXISTS. #5812 anchored the -001 case set to ${PRIMARY_ROOT}, correctly
# ending the era when a file merely NAMED CLAUDE.md was blocked wherever on disk it sat.
# The anchor it chose for the three in-repo documents is ${PRIMARY_ROOT}/pmo-platform —
# the platform CHECKOUT — which covers every worktree nested beneath the checkout and no
# worktree anywhere else. Linked worktrees are routinely created outside that subtree: a
# spawned session receives one under its own scratchpad. The on-disk copy is transient,
# which is what made the gap look tolerable; the COMMIT made from that copy is not, and
# it pushes to the same public repository this floor exists to guard. Transience of the
# working tree is not transience of the disclosure.
#
# The discrimination pinned here is NOT a path prefix. No prefix can express "wherever
# that tree happens to live", which is precisely why the #5812 anchoring could not also
# solve this. It is REPOSITORY MEMBERSHIP: a working tree belongs to this repository when
# its git administrative directory resolves inside ${PRIMARY_ROOT}/pmo-platform/.git. A
# linked worktree's `.git` is a one-line pointer at exactly that directory, so the test is
# a bounded upward walk plus one small file read — and it runs only for a Write/Edit whose
# resolved basename is already one of the three governance documents.
#
# Every block arm is paired with an allow arm of identical shape, differing only in which
# repository the enclosing tree belongs to. A lone block arm would pass unchanged against
# a hook that had simply reverted to matching basenames, which is the regression that
# matters most here — #5812's fix must not be undone in the course of restoring coverage.
echo ""
echo "Suite W — -001 reaches out-of-anchor working trees of this repo (#5812 F1)"
echo "---"
set_mode "enforce"
set_ceiling 2

# A scratchpad OUTSIDE ${PRIMARY_ROOT} entirely — the shape a spawned session actually
# gets, not a contrived sibling of the checkout.
W_SCRATCH="$(cd "$(/usr/bin/mktemp -d)" && pwd -P)"

# The platform checkout's administrative directory, plus the per-worktree admin dir
# beneath it that `git worktree add` creates. Nothing else about the checkout is needed:
# membership is decided by where the admin directory lives, not by the tree's contents.
/bin/mkdir -p "${TEST_WS}/pmo-platform/.git/worktrees/wt1"
/bin/mkdir -p "${W_SCRATCH}/wt/core/governance" "${W_SCRATCH}/wt/release/governance"
/usr/bin/printf 'gitdir: %s\n' "${TEST_WS}/pmo-platform/.git/worktrees/wt1" > "${W_SCRATCH}/wt/.git"

# An UNRELATED repository, with its own real administrative directory. This is #5812's
# subject and it must keep falling through.
/bin/mkdir -p "${W_SCRATCH}/product-repo/.git"

# A plain directory that is not a repository at all — the backup-copy case.
/bin/mkdir -p "${W_SCRATCH}/loose"

W_CWD="${W_SCRATCH}/wt"

# W-1..W-3 — all three governance basenames, in a working tree of this repository that
# sits outside the checkout anchor. These are the arms #5812 dropped.
run_hook_env "$(write_payload "${W_SCRATCH}/wt/CLAUDE.md" "$W_CWD")" CLAUDE_WORKSPACE_ROOT="$TEST_WS"
assert_hook "W-1 out-of-anchor worktree: CLAUDE.md → BLOCK (-001)" 2 "BLOCK-AUTONOMY-001"

run_hook_env "$(edit_payload "${W_SCRATCH}/wt/core/governance/OPERATIONS.md" "$W_CWD")" CLAUDE_WORKSPACE_ROOT="$TEST_WS"
assert_hook "W-2 out-of-anchor worktree: OPERATIONS.md → BLOCK (-001)" 2 "BLOCK-AUTONOMY-001"

run_hook_env "$(edit_payload "${W_SCRATCH}/wt/release/governance/RELEASE_PROTOCOL.md" "$W_CWD")" CLAUDE_WORKSPACE_ROOT="$TEST_WS"
assert_hook "W-3 out-of-anchor worktree: RELEASE_PROTOCOL.md → BLOCK (-001)" 2 "BLOCK-AUTONOMY-001"

# W-4 — #5812 NON-REGRESSION, and the single most important arm in this suite. An
# unrelated repository's root doc must keep falling through to the mode- and
# level-dependent path. This arm passes against the hook BEFORE this change as well as
# after; that is the point of it. If restoring worktree coverage cost us this, the cure
# would be the disease #5812 diagnosed.
run_hook_env "$(write_payload "${W_SCRATCH}/product-repo/CLAUDE.md" "${W_SCRATCH}/product-repo")" CLAUDE_WORKSPACE_ROOT="$TEST_WS"
assert_hook "W-4 #5812 non-regression: an unrelated REPO's root CLAUDE.md → ALLOW" 0 ""

# W-5 — the backup-copy case: a governance basename in a directory that is not a working
# tree of anything. The upward walk must terminate without a verdict rather than blocking.
run_hook_env "$(write_payload "${W_SCRATCH}/loose/OPERATIONS.md" "${W_SCRATCH}/loose")" CLAUDE_WORKSPACE_ROOT="$TEST_WS"
assert_hook "W-5 a loose copy in no repository at all → ALLOW" 0 ""

# W-6 — SPECIFICITY, and the arm that proves the rule keys on WHICH repository rather
# than on "is a linked worktree". A worktree of some OTHER repo carries a `.git` file of
# exactly the same shape; only the target of the pointer differs.
/bin/mkdir -p "${W_SCRATCH}/foreign-wt" "${W_SCRATCH}/foreign-repo/.git/worktrees/w"
/usr/bin/printf 'gitdir: %s\n' "${W_SCRATCH}/foreign-repo/.git/worktrees/w" > "${W_SCRATCH}/foreign-wt/.git"
run_hook_env "$(write_payload "${W_SCRATCH}/foreign-wt/CLAUDE.md" "${W_SCRATCH}/foreign-wt")" CLAUDE_WORKSPACE_ROOT="$TEST_WS"
assert_hook "W-6 specificity: a worktree of a DIFFERENT repository → ALLOW" 0 ""

# W-7 — a RELATIVE gitdir pointer. git 2.48+ writes one under `worktree.useRelativePaths`
# / `git worktree add --relative-paths`, and a membership test that only understood the
# absolute form would silently allow every worktree on such an instance. Asserted rather
# than assumed, because "the pointer is always absolute" is exactly the shape of
# unverified premise this release shipped a bypass on.
#
# The tree is placed as a SIBLING of the pinned workspace so the relative pointer can be
# written exactly, with no path arithmetic: one level up, then down by basename. It is
# still out-of-anchor (it is not under ${TEST_WS}/pmo-platform), which is what the arm is
# about. An earlier draft of this fixture composed a relative path that resolved nowhere,
# and the arm failed for that reason rather than the hook's — worth recording, because a
# fixture that fails for its own defect is indistinguishable from a real finding until it
# is read.
W_TS_PARENT="$(/usr/bin/dirname "$TEST_WS")"
W_TS_BASE="$(/usr/bin/basename "$TEST_WS")"
W_RELWT="${W_TS_PARENT}/relwt-$$"
/bin/mkdir -p "$W_RELWT"
/usr/bin/printf 'gitdir: ../%s/pmo-platform/.git/worktrees/wt1\n' "$W_TS_BASE" > "${W_RELWT}/.git"
run_hook_env "$(write_payload "${W_RELWT}/CLAUDE.md" "$W_RELWT")" CLAUDE_WORKSPACE_ROOT="$TEST_WS"
assert_hook "W-7 relative gitdir pointer still resolves to this repo → BLOCK (-001)" 2 "BLOCK-AUTONOMY-001"

# W-7 DIFFERENTIAL. W-1..W-3 and Suite N were each demonstrated failing against the hook
# as it stood before this change, which is what makes their passing mean something. W-7
# cannot borrow that evidence: the membership test it exercises did not exist to fail, so
# a pre-change run says only "no coverage at all", not "the absolute-only reading is
# insufficient". The naive implementation this arm actually discriminates against is a
# membership test that understands ONLY the absolute pointer form — so build exactly that
# in a sandbox by deleting the relative-pointer join, and require W-7's payload to be
# ALLOWED against it. A fixture is worth having only if some reachable implementation
# fails it.
W7_SANDBOX="$(/usr/bin/mktemp -d)"
/bin/mkdir -p "${W7_SANDBOX}/lib"
/bin/cp "${HOOK_DIR}/lib/"*.sh "${W7_SANDBOX}/lib/" 2>/dev/null || true
/bin/cp "${HOOK_DIR}/lib/"*.awk "${W7_SANDBOX}/lib/" 2>/dev/null || true
/usr/bin/sed -e '/# W7: relative-pointer join/d' "$HOOK" > "${W7_SANDBOX}/block-autonomy-ceiling.sh"
/bin/chmod +x "${W7_SANDBOX}/block-autonomy-ceiling.sh"
/usr/bin/printf 'enforce' > "${W7_SANDBOX}/.autonomy-mode"
w7_removed=$(( $(/usr/bin/wc -l < "$HOOK") - $(/usr/bin/wc -l < "${W7_SANDBOX}/block-autonomy-ceiling.sh") ))
w7_err="$(/usr/bin/mktemp)"; w7_exit=0
/usr/bin/printf '%s' "$(write_payload "${W_RELWT}/CLAUDE.md" "$W_RELWT")" \
  | HOME="$TEST_HOME" /bin/bash "${W7_SANDBOX}/block-autonomy-ceiling.sh" 2>"$w7_err" >/dev/null || w7_exit="$?"
w7_stderr="$(/bin/cat "$w7_err")"; /bin/rm -f "$w7_err"; /bin/rm -rf "$W7_SANDBOX"
# Guard the differential itself: if sed removed nothing, the "sandbox" IS the shipped hook
# and its verdict would be meaningless. Require both a real edit and a real divergence.
if [ "$w7_removed" = 1 ] && [ "$w7_exit" = 0 ]; then
  echo "PASS: W-7 differential — an absolute-only membership test ALLOWS the relative-pointer worktree; the shipped one blocks it"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: W-7 differential inconclusive (lines removed=%s expected=1, sandbox exit=%s expected=0)\n  stderr: %s\n' \
    "$w7_removed" "$w7_exit" "$w7_stderr"; FAIL=$((FAIL + 1))
fi
/bin/rm -rf "$W_RELWT"

# W-8 — NEAREST-ENCLOSING. A separate repository checked out INSIDE a platform worktree
# has its own administrative directory, so git cannot track its contents through the
# platform repo and its root doc is not platform governance. The walk must stop at the
# nearest enclosing tree rather than continuing up to the platform one. This is the same
# discrimination as W-4, one directory level down, and it is the arm that would catch a
# walk written to search for the platform gitdir instead of resolving the nearest.
/bin/mkdir -p "${W_SCRATCH}/wt/vendor/nested/.git"
run_hook_env "$(write_payload "${W_SCRATCH}/wt/vendor/nested/CLAUDE.md" "$W_CWD")" CLAUDE_WORKSPACE_ROOT="$TEST_WS"
assert_hook "W-8 nearest-enclosing: a nested foreign repo inside the worktree → ALLOW" 0 ""

# W-9 — the in-anchor worktree is unchanged. Paired with W-1 on the same governance
# basename, this is what shows the change ADDED reach rather than MOVING it.
run_hook_env "$(edit_payload "${TEST_WS}/pmo-platform/.claude/worktrees/wt/core/governance/OPERATIONS.md" "${TEST_WS}/pmo-platform")" CLAUDE_WORKSPACE_ROOT="$TEST_WS"
assert_hook "W-9 in-anchor worktree still BLOCKS (coverage added, not relocated)" 2 "BLOCK-AUTONOMY-001"

# =====================================================================
# SUITE N — ${PRIMARY_ROOT} must be resolved the way ABS_TARGET is
# =====================================================================
# The hook compares a REALPATH-RESOLVED target against ${PRIMARY_ROOT} taken RAW from
# CLAUDE_WORKSPACE_ROOT. Four benign shapes of that variable therefore make every anchored
# pattern compare a resolved path against an unresolved prefix, and NONE of them match.
# The failure is total rather than partial: the -001 floor, the -002 floor, -004 and the
# ceiling's projects/ mapping are all anchored on the same value, so a single trailing
# slash silently disables the whole hook while every log line still reads normal.
#
# #5812 widened the exposure — the anchored entry count went from 3 to 11 — which is what
# turns a latent defect into one worth arming. An anchored pattern with a mis-resolving
# anchor is worse than an unanchored one, because it reads as safe.
#
# Each arm drives the SAME governance write that the control arm blocks, changing only the
# shape of CLAUDE_WORKSPACE_ROOT. The control is what stops the four from being an inert
# zero: it proves the payload blocks when the anchor arrives clean.
echo ""
echo "Suite N — CLAUDE_WORKSPACE_ROOT normalization (anchor/target resolution parity)"
echo "---"
set_mode "enforce"
set_ceiling 2

/bin/mkdir -p "${TEST_WS}/pmo-platform/core/governance"
N_PAYLOAD="$(edit_payload "${TEST_WS}/pmo-platform/core/governance/OPERATIONS.md" "${TEST_WS}/pmo-platform")"

# N-0 control — the clean anchor blocks. Every arm below is only meaningful against this.
run_hook_env "$N_PAYLOAD" CLAUDE_WORKSPACE_ROOT="$TEST_WS"
assert_hook "N-0 control: clean anchor → BLOCK (-001)" 2 "BLOCK-AUTONOMY-001"

# N-1 trailing slash. '${WS}/' + '/pmo-platform' yields a doubled separator that matches
# nothing, and the hook allows a governance write at the highest ceiling.
run_hook_env "$N_PAYLOAD" CLAUDE_WORKSPACE_ROOT="${TEST_WS}/"
assert_hook "N-1 trailing slash anchor → STILL BLOCK (-001)" 2 "BLOCK-AUTONOMY-001"

# N-2 trailing '/.'. Valid, idiomatic, and produces '${WS}/./pmo-platform'.
run_hook_env "$N_PAYLOAD" CLAUDE_WORKSPACE_ROOT="${TEST_WS}/."
assert_hook "N-2 trailing '/.' anchor → STILL BLOCK (-001)" 2 "BLOCK-AUTONOMY-001"

# N-3 symlinked alias. The operator points the variable at a symlink to the workspace —
# the single most likely real-world malformation, and invisible in every log line.
N_ALIAS="$(/usr/bin/mktemp -d)/ws-alias"
/bin/ln -s "$TEST_WS" "$N_ALIAS"
run_hook_env "$N_PAYLOAD" CLAUDE_WORKSPACE_ROOT="$N_ALIAS"
assert_hook "N-3 symlinked-alias anchor → STILL BLOCK (-001)" 2 "BLOCK-AUTONOMY-001"

# N-4 relative anchor, resolved against the hook process's own cwd — the same base
# resolve_path() uses for a relative file_path, so anchor and target agree by construction.
N_PARENT="$(/usr/bin/dirname "$TEST_WS")"
N_BASE="$(/usr/bin/basename "$TEST_WS")"
n4_err="$(/usr/bin/mktemp)"; n4_exit=0
( cd "$N_PARENT" && /usr/bin/printf '%s' "$N_PAYLOAD" \
    | HOME="$TEST_HOME" CLAUDE_WORKSPACE_ROOT="$N_BASE" /bin/bash "$HOOK" 2>"$n4_err" >/dev/null ) || n4_exit="$?"
n4_stderr="$(/bin/cat "$n4_err")"; /bin/rm -f "$n4_err"
if [ "$n4_exit" = 2 ] && /usr/bin/printf '%s' "$n4_stderr" | /usr/bin/grep -qE "BLOCK-AUTONOMY-001"; then
  echo "PASS: N-4 relative anchor → STILL BLOCK (-001)"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: N-4 relative anchor (exit=%s expected=2, want BLOCK-AUTONOMY-001)\n  stderr: %s\n' \
    "$n4_exit" "$n4_stderr"; FAIL=$((FAIL + 1))
fi

# =====================================================================
# SUITE A — path ALIASING, and the resolver degradation beneath it
# =====================================================================
# #5293 demoted the pmo-platform → projects/ direction from an always-block floor to a
# mode-gated signal, on the stated premise that the demoted direction CANNOT reach the
# tracked repository. That premise is load-bearing — it is the entire justification for
# the demotion — and it was asserted in a comment, an ADR and a registry fragment without
# a single arm behind it. This release shipped a bypass from exactly that shape: a comment
# asserting a direction was impossible, with nothing testing it.
#
# The premise holds only because classification runs on the RESOLVED path. Arms A-1..A-5
# pin that: five aliases that read as one domain and resolve into the other, each required
# to be classified by where it LANDS. A-6/A-7 then attack the resolver itself, which
# degrades to the raw path when python3 is unavailable — and a raw path is precisely the
# textual reading these five arms exist to reject.
echo ""
echo "Suite A — aliasing, and resolver degradation (#5293 premise)"
echo "---"
set_mode "enforce"
set_ceiling 2

/bin/mkdir -p "${TEST_WS}/projects/Default" "${TEST_WS}/pmo-platform/core/governance"
/usr/bin/printf 'x\n' > "${TEST_WS}/pmo-platform/core/governance/OPERATIONS.md"
/usr/bin/printf 'x\n' > "${TEST_WS}/pmo-platform/core/foo.md"

# A-1 traversal into the repo from a projects cwd — must be the FLOOR (-002), not -004
# and not an allow. The literal string names projects/; the landing site is the repo.
run_hook_env "$(write_payload "${TEST_WS}/projects/../pmo-platform/core/foo.md" "${TEST_WS}/projects/Default")" CLAUDE_WORKSPACE_ROOT="$TEST_WS"
assert_hook "A-1 traversal projects/../pmo-platform → -002 (classified where it lands)" 2 "BLOCK-AUTONOMY-002"

# A-2 traversal onto a governance document — -001 outranks the cross-domain rules.
run_hook_env "$(edit_payload "${TEST_WS}/projects/Default/../../pmo-platform/core/governance/OPERATIONS.md" "${TEST_WS}/projects/Default")" CLAUDE_WORKSPACE_ROOT="$TEST_WS"
assert_hook "A-2 traversal onto OPERATIONS.md → -001" 2 "BLOCK-AUTONOMY-001"

# A-3 symlinked DIRECTORY inside projects/ pointing at the repo.
/bin/ln -s "${TEST_WS}/pmo-platform" "${TEST_WS}/projects/repolink"
run_hook_env "$(write_payload "${TEST_WS}/projects/repolink/core/foo.md" "${TEST_WS}/projects/Default")" CLAUDE_WORKSPACE_ROOT="$TEST_WS"
assert_hook "A-3 symlinked directory projects/repolink → -002" 2 "BLOCK-AUTONOMY-002"

# A-4 symlinked LEAF — the file itself is the alias. Strictly harder than A-3: the parent
# directory is genuinely in projects/ and only the final component crosses.
/bin/ln -s "${TEST_WS}/pmo-platform/core/governance/OPERATIONS.md" "${TEST_WS}/projects/gov.md"
run_hook_env "$(edit_payload "${TEST_WS}/projects/gov.md" "${TEST_WS}/projects/Default")" CLAUDE_WORKSPACE_ROOT="$TEST_WS"
assert_hook "A-4 symlinked leaf projects/gov.md → -001" 2 "BLOCK-AUTONOMY-001"

# A-5 REVERSE symlink — a path that reads in-repo and lands in projects/. The mirror of
# A-3, and the arm that shows resolution is not merely biased toward blocking: it must
# also DEMOTE a repo-looking target that leaves the repo, to -004 rather than same-domain.
/bin/ln -s "${TEST_WS}/projects" "${TEST_WS}/pmo-platform/opslink"
run_hook_env "$(write_payload "${TEST_WS}/pmo-platform/opslink/Default/notes.md" "${TEST_WS}/pmo-platform")" CLAUDE_WORKSPACE_ROOT="$TEST_WS"
assert_hook "A-5 reverse symlink pmo-platform/opslink → -004 (demoted, not same-domain)" 2 "BLOCK-AUTONOMY-004"

# --- A-6 / A-7: the resolver degradation the five arms above sit on top of ---
# resolve_path() falls back to the RAW path string whenever python3 cannot be used, and
# there are three such doors, not one: PYTHON3 absent for an existing target, PYTHON3
# absent for a not-yet-existing target, and PYTHON3 present but non-functional (the
# `|| echo "$fp"` arm — reachable on a Mac carrying the Command Line Tools stub without
# the tools installed, where `[ -x ]` is TRUE and execution still fails).
#
# On the raw path A-1 stops being a floor: the string names projects/ and is classified
# there, which demotes a repo-reaching write from always-block to mode-gated. The sandbox
# below reproduces the degradation honestly rather than asserting it cannot happen.
A_SANDBOX="$(/usr/bin/mktemp -d)"
/bin/mkdir -p "${A_SANDBOX}/lib"
/bin/cp "${HOOK_DIR}/lib/"*.sh "${A_SANDBOX}/lib/" 2>/dev/null || true
/bin/cp "${HOOK_DIR}/lib/"*.awk "${A_SANDBOX}/lib/" 2>/dev/null || true
# Point PYTHON3 at a path that does not exist. Nothing else is touched.
/usr/bin/sed -e 's#^readonly PYTHON3="/usr/bin/python3"#readonly PYTHON3="/nonexistent/python3"#' \
             "$HOOK" > "${A_SANDBOX}/block-autonomy-ceiling.sh"
/bin/chmod +x "${A_SANDBOX}/block-autonomy-ceiling.sh"
/usr/bin/printf 'enforce' > "${A_SANDBOX}/.autonomy-mode"

a_edited=0
/usr/bin/grep -q '/nonexistent/python3' "${A_SANDBOX}/block-autonomy-ceiling.sh" && a_edited=1

# A-6 — traversal under an unusable python3. The floor must survive the degradation.
a6_err="$(/usr/bin/mktemp)"; a6_exit=0
/usr/bin/printf '%s' "$(write_payload "${TEST_WS}/projects/../pmo-platform/core/foo.md" "${TEST_WS}/projects/Default")" \
  | HOME="$TEST_HOME" /bin/bash "${A_SANDBOX}/block-autonomy-ceiling.sh" 2>"$a6_err" >/dev/null || a6_exit="$?"
a6_stderr="$(/bin/cat "$a6_err")"; /bin/rm -f "$a6_err"
if [ "$a_edited" = 1 ] && [ "$a6_exit" = 2 ] && /usr/bin/printf '%s' "$a6_stderr" | /usr/bin/grep -qE "BLOCK-AUTONOMY-002"; then
  echo "PASS: A-6 python3 unusable → traversal STILL classified where it lands (-002)"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: A-6 python3-degraded traversal (sandbox edited=%s, exit=%s expected=2, want BLOCK-AUTONOMY-002)\n  stderr: %s\n' \
    "$a_edited" "$a6_exit" "$a6_stderr"; FAIL=$((FAIL + 1))
fi

# A-7 — the symlinked LEAF under the same degradation. This is the harder half of the
# same claim and it is armed separately, because the shell fallback resolves the parent
# directory and the leaf by different means. Stating "resolution is preserved" while only
# testing A-6 would be the same over-claim this milestone keeps producing.
a7_err="$(/usr/bin/mktemp)"; a7_exit=0
/usr/bin/printf '%s' "$(edit_payload "${TEST_WS}/projects/gov.md" "${TEST_WS}/projects/Default")" \
  | HOME="$TEST_HOME" /bin/bash "${A_SANDBOX}/block-autonomy-ceiling.sh" 2>"$a7_err" >/dev/null || a7_exit="$?"
a7_stderr="$(/bin/cat "$a7_err")"; /bin/rm -f "$a7_err"
if [ "$a_edited" = 1 ] && [ "$a7_exit" = 2 ] && /usr/bin/printf '%s' "$a7_stderr" | /usr/bin/grep -qE "BLOCK-AUTONOMY-001"; then
  echo "PASS: A-7 python3 unusable → symlinked LEAF still resolves (-001)"; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: A-7 python3-degraded symlinked leaf (sandbox edited=%s, exit=%s expected=2, want BLOCK-AUTONOMY-001)\n  stderr: %s\n' \
    "$a_edited" "$a7_exit" "$a7_stderr"; FAIL=$((FAIL + 1))
fi

/bin/rm -rf "$A_SANDBOX"
/bin/rm -rf "$W_SCRATCH"

# =====================================================================
# Summary
# =====================================================================
echo ""
echo "================================"
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "================================"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
