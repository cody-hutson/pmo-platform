#!/bin/bash
# tests/block-scope-segregation.test.sh — synthetic PreToolUse tests for
# block-scope-segregation.sh (#384; the destination-sensitivity content gate).
#
# Proves the fail-closed enforcement posture from the #3877 A6.5 adversarial review:
#   CD-1  fail-closed routing default (unmapped destination while trackers configured
#         → fail closed; NO trackers → permissive back-compat; private dest → allow)
#   CD-2  tiered ALWAYS-BLOCK (identity/private needle → scope:public blocked even in
#         warn mode; only .scope-segregation-mode=off disables it)
#   CD-3  fail-closed content-extraction (empty extraction on mapped-public → block in
#         enforce, would-block in warn — NOT the block-gh-path-leak fail-open-on-empty)
# plus: allow-path (private OK; needle-clean public OK); the three disable paths
# (mode=off, allowlist, CLAUDE_HOOK_BYPASS=1); MCP surface; no-double-fire; and the
# missing-jq / missing-primitive fail-closed regressions.
#
# HERMETIC: builds a sandbox mirroring the DEPLOYED layout (.claude/hooks/ + a
# co-located primitive + resolver + the allowlist one level up at .claude/) with a
# sandboxed HOME so operator.toml resolves into the sandbox. The repo hook dir is
# never mutated. Summary line matches the test-runner contract:
#   "Total: N  PASS: N  FAIL: N".

set -u

SRC_HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
REPO_ROOT="$(cd "${SRC_HOOK_DIR}/../.." && pwd -P)"
JQ="/usr/bin/jq"

[ -x "${SRC_HOOK_DIR}/block-scope-segregation.sh" ] || { echo "FAIL: hook not executable"; echo "Total: 1  PASS: 0  FAIL: 1"; exit 1; }

# --- Build the deployed-layout sandbox ---
SB="$(mktemp -d)"
CLAUDE="${SB}/.claude"
HDIR="${CLAUDE}/hooks"
mkdir -p "${HDIR}/lib" "${SB}/.config/pmo-platform"
cp "${SRC_HOOK_DIR}/block-scope-segregation.sh" "${HDIR}/block-scope-segregation.sh"
cp "${SRC_HOOK_DIR}/lib/dep-resolve.sh"          "${HDIR}/lib/dep-resolve.sh"
# Resolve the shared deps the SAME way the hook does — co-located (deployed / CI
# layout) FIRST, then the source layout (core/deploy/...) — so this test is hermetic
# under both `test-runner.sh` (source tree) and `setup-ci-layout.sh` (deployed sandbox).
PLP_SRC="${SRC_HOOK_DIR}/path-leak-patterns.sh"
[ -f "$PLP_SRC" ] || PLP_SRC="${REPO_ROOT}/core/deploy/tools/path-leak-patterns.sh"
cp "$PLP_SRC" "${HDIR}/path-leak-patterns.sh"
NLP_SRC="${SRC_HOOK_DIR}/lib-instance-path.sh"
[ -f "$NLP_SRC" ] || NLP_SRC="${REPO_ROOT}/core/deploy/lib-instance-path.sh"
cp "$NLP_SRC" "${HDIR}/lib-instance-path.sh"
HOOK="${HDIR}/block-scope-segregation.sh"
MODE_FILE="${HDIR}/.scope-segregation-mode"
ALLOWLIST="${CLAUDE}/scope-segregation-allowlist.txt"
OPTOML="${SB}/.config/pmo-platform/operator.toml"
NEEDLES="${SB}/needles.txt"

cleanup() { [ -n "${SB:-}" ] && /bin/rm -rf "$SB"; }
trap cleanup EXIT

# operator.toml with a private (jira) + a public (github) destination.
seed_trackers() {
  cat > "$OPTOML" <<'TOML'
[identity]
operator_name = "Test Operator"
[trackers.work]
id = "work"
platform = "jira"
identifier = "PROJ"
scope = "private"
[trackers.personal]
id = "personal"
platform = "github-issues"
identifier = "owner/public-repo"
scope = "public"
TOML
}
# operator.toml with NO [trackers.*] (back-compat single-stream).
seed_no_trackers() {
  cat > "$OPTOML" <<'TOML'
[identity]
operator_name = "Test Operator"
[adapters]
ticketing = "github"
TOML
}
seed_needles() { printf 'AcmeCorp\nAcme Cutover\n' > "$NEEDLES"; }
set_mode()     { printf '%s' "$1" > "$MODE_FILE"; }
seed_allowlist() { printf '# test allowlist\n# ---\n%s\n' "${1:-}" > "$ALLOWLIST"; }

seed_trackers; seed_needles; seed_allowlist ""

PASS=0; FAIL=0
p_bash() { "$JQ" -n --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}'; }
p_mcp()  { "$JQ" -n --arg t "$1" --argjson ti "$2" '{tool_name:$t,tool_input:$ti}'; }

# run <name> <payload> <mode> <expected_exit> [stderr_pattern] [extra_env]
run() {
  local name="$1" payload="$2" mode="$3" exp="$4" pat="${5:-}" xenv="${6:-}"
  set_mode "$mode"
  local rc=0
  printf '%s' "$payload" | env HOME="$SB" PMO_LOCALIZED_NEEDLES="$NEEDLES" $xenv /bin/bash "$HOOK" >/dev/null 2>"${SB}/err" || rc=$?
  local err; err="$(/bin/cat "${SB}/err")"
  local ok=1
  [ "$rc" != "$exp" ] && ok=0
  [ -n "$pat" ] && ! printf '%s' "$err" | /usr/bin/grep -qE "$pat" && ok=0
  if [ "$ok" = 1 ]; then printf 'PASS: %s\n' "$name"; PASS=$((PASS+1));
  else printf 'FAIL: %s (exp_exit=%s got=%s pat=[%s])\n  stderr: %s\n' "$name" "$exp" "$rc" "$pat" "$err"; FAIL=$((FAIL+1)); fi
}

echo "===== ALLOW-PATH ====="
run "non-filing bash → allow" "$(p_bash 'ls -la /tmp')" enforce 0
run "filing to PRIVATE (jira PROJ) with PII → allow" "$(p_bash 'gh issue create --repo PROJ --title T --body "call 555-123-4567"')" enforce 0
run "needle-CLEAN → PUBLIC → allow" "$(p_bash 'gh issue create --repo owner/public-repo --title T --body "generic status update"')" enforce 0
run "MCP read (get) → allow" "$(p_mcp 'mcp__srv__getJiraIssue' '{"issueId":"X"}')" enforce 0
run "MCP non-filing write (share) → allow" "$(p_mcp 'mcp__srv__shareBoard' '{"repo":"owner/public-repo"}')" enforce 0

echo "===== CD-2 always-block (identity/private needle → public) ====="
# The personal-email fixture domain is assembled at runtime so the literal
# personal-email string never appears in this tracked source file (it would
# otherwise trip the git-pre-commit-pii guard on a public-repo file). At runtime
# the payload carries a full "foo@<dom>" that the hook's RE_PMAIL matches.
PMAIL_DOM="gmail.com"
run "CD-2 phone → PUBLIC enforce → BLOCK" "$(p_bash 'gh issue create --repo owner/public-repo --title T --body "call 555-123-4567"')" enforce 2 "BLOCK-SCOPE-SEG-004"
run "CD-2 phone → PUBLIC WARN → STILL BLOCK (always)" "$(p_bash 'gh issue create --repo owner/public-repo --title T --body "call 555-123-4567"')" warn 2 "BLOCK-SCOPE-SEG-004"
run "CD-2 personal-email → PUBLIC WARN → BLOCK" "$(p_bash "gh issue create --repo owner/public-repo --title T --body \"reach me at foo@${PMAIL_DOM}\"")" warn 2 "BLOCK-SCOPE-SEG-004"
run "CD-2 home-path → PUBLIC WARN → BLOCK" "$(p_bash 'gh issue create --repo owner/public-repo --title T --body "see /Users/realop/notes"')" warn 2 "BLOCK-SCOPE-SEG-004"
run "CD-2 client-needle (AcmeCorp) → PUBLIC WARN → BLOCK" "$(p_bash 'gh issue create --repo owner/public-repo --title T --body "AcmeCorp cutover blocker"')" warn 2 "BLOCK-SCOPE-SEG-004"
run "CD-2 MCP createIssue PII → PUBLIC enforce → BLOCK" "$(p_mcp 'mcp__gh__createIssue' '{"repo":"owner/public-repo","title":"T","body":"call 555-123-4567"}')" enforce 2 "BLOCK-SCOPE-SEG-004"

echo "===== CD-1 fail-closed routing default ====="
run "CD-1 unmapped + trackers configured enforce → BLOCK (fail-closed)" "$(p_bash 'gh issue create --repo owner/some-other-repo --title T --body clean')" enforce 2 "BLOCK-SCOPE-SEG-001"
run "CD-1 unmapped + trackers configured WARN → would-block (exit 0)" "$(p_bash 'gh issue create --repo owner/some-other-repo --title T --body clean')" warn 0 "WARN .would-block"
run "CD-1 filing to PRIVATE (safe direction) → allow" "$(p_bash 'gh issue create --repo PROJ --title T --body clean')" enforce 0

echo "===== CD-1 back-compat: NO trackers configured → permissive ====="
seed_no_trackers
run "no-trackers unmapped enforce → allow (back-compat single-stream)" "$(p_bash 'gh issue create --repo owner/anything --title T --body clean')" enforce 0
run "no-trackers unmapped + PII enforce → allow (no scope model)" "$(p_bash 'gh issue create --repo owner/anything --title T --body "call 555-123-4567"')" enforce 0
seed_trackers

echo "===== CD-3 fail-closed content-extraction (empty on mapped-public) ====="
run "CD-3 empty-extraction → PUBLIC enforce → BLOCK" "$(p_bash 'gh issue create --repo owner/public-repo')" enforce 2 "BLOCK-SCOPE-SEG-002"
run "CD-3 empty-extraction → PUBLIC WARN → would-block (exit 0)" "$(p_bash 'gh issue create --repo owner/public-repo')" warn 0 "WARN .would-block"
run "CD-3 MCP empty content → PUBLIC enforce → BLOCK" "$(p_mcp 'mcp__gh__createIssue' '{"repo":"owner/public-repo"}')" enforce 2 "BLOCK-SCOPE-SEG-002"

echo "===== DISABLE PATH 1: .scope-segregation-mode=off ====="
run "off: CD-2 identity needle → PUBLIC → allow" "$(p_bash 'gh issue create --repo owner/public-repo --title T --body "call 555-123-4567"')" off 0
run "off: CD-1 unmapped → allow" "$(p_bash 'gh issue create --repo owner/some-other-repo --title T --body clean')" off 0

echo "===== DISABLE PATH 2: allowlist exemption ====="
seed_allowlist "555-123-4567"
run "allowlist exempts the matched line → allow (CD-2 skipped)" "$(p_bash 'gh issue create --repo owner/public-repo --title T --body "call 555-123-4567"')" enforce 0
seed_allowlist ""
run "control: same line NOT allowlisted → BLOCK" "$(p_bash 'gh issue create --repo owner/public-repo --title T --body "call 555-123-4567"')" enforce 2 "BLOCK-SCOPE-SEG-004"

echo "===== DISABLE PATH 3: CLAUDE_HOOK_BYPASS=1 ====="
run "bypass=1: CD-2 needle → PUBLIC → allow" "$(p_bash 'gh issue create --repo owner/public-repo --title T --body "call 555-123-4567"')" enforce 0 "" "CLAUDE_HOOK_BYPASS=1"
run "bypass=1: CD-1 unmapped → allow" "$(p_bash 'gh issue create --repo owner/some-other-repo --title T --body x')" enforce 0 "" "CLAUDE_HOOK_BYPASS=1"

echo "===== NO DOUBLE-FIRE (neighbor-hook orthogonality) ====="
# A plain non-filing Bash that a neighbor hook might gate (e.g. an rm) must be a
# clean exit-0 no-op here — this hook adds ONLY the scope-segregation axis.
run "non-filing rm → allow (no scope axis)" "$(p_bash 'rm -rf /tmp/whatever')" enforce 0
run "gh issue VIEW (read, not filing) → allow" "$(p_bash 'gh issue view 123')" enforce 0

# ==========================================================================
# Missing-jq / missing-primitive fail-closed regressions (own sandbox copy).
# ==========================================================================
echo "===== FAIL-CLOSED: missing jq / missing helper ====="
SBX="$(mktemp -d)"
mkdir -p "${SBX}/.claude/hooks/lib" "${SBX}/.config/pmo-platform"
cp "$HOOK" "${SBX}/.claude/hooks/block-scope-segregation.sh"
cp "${HDIR}/path-leak-patterns.sh" "${SBX}/.claude/hooks/path-leak-patterns.sh"
cp "${HDIR}/lib-instance-path.sh"  "${SBX}/.claude/hooks/lib-instance-path.sh"
cp "$OPTOML" "${SBX}/.config/pmo-platform/operator.toml"
/usr/bin/sed -e 's#/usr/bin/jq#/nonexistent/usr/bin/jq#' \
             -e 's#/opt/homebrew/bin/jq#/nonexistent/opt/homebrew/bin/jq#' \
             -e 's#/usr/local/bin/jq#/nonexistent/usr/local/bin/jq#' \
             "${HDIR}/lib/dep-resolve.sh" > "${SBX}/.claude/hooks/lib/dep-resolve.sh"
SXHOOK="${SBX}/.claude/hooks/block-scope-segregation.sh"
SXMODE="${SBX}/.claude/hooks/.scope-segregation-mode"

sbox_run() { # name mode extra_env expected_exit [pattern]
  local name="$1" mode="$2" xenv="$3" exp="$4" pat="${5:-}"
  printf '%s' "$mode" > "$SXMODE"
  local payload; payload="$(p_bash 'gh issue create --repo owner/public-repo --title T --body "call 555-123-4567"')"
  local rc=0
  printf '%s' "$payload" | env HOME="$SBX" $xenv /bin/bash "$SXHOOK" >/dev/null 2>"${SBX}/err" || rc=$?
  local err; err="$(/bin/cat "${SBX}/err")"
  local ok=1
  [ "$rc" != "$exp" ] && ok=0
  [ -n "$pat" ] && ! printf '%s' "$err" | /usr/bin/grep -qE "$pat" && ok=0
  if [ "$ok" = 1 ]; then printf 'PASS: %s\n' "$name"; PASS=$((PASS+1));
  else printf 'FAIL: %s (exp=%s got=%s)\n  stderr: %s\n' "$name" "$exp" "$rc" "$err"; FAIL=$((FAIL+1)); fi
}
sbox_run "missing-jq enforce → fail CLOSED (exit 2)" enforce "" 2 "DEPENDENCY"
sbox_run "missing-jq warn → degrade (exit 0)"        warn    "" 0 "DEPENDENCY-DEGRADED"
sbox_run "missing-jq + bypass → allow (exit 0)"      enforce "CLAUDE_HOOK_BYPASS=1" 0
# Missing dep helper entirely → fail CLOSED regardless of mode.
/bin/rm -f "${SBX}/.claude/hooks/lib/dep-resolve.sh"
sbox_run "missing-helper enforce → fail CLOSED (exit 2)" enforce "" 2 "LIB-MISSING"
sbox_run "missing-helper off → fail CLOSED (exit 2)"     off     "" 2 "LIB-MISSING"
/bin/rm -rf "$SBX"

printf '\nTotal: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
