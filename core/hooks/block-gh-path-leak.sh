#!/bin/bash
# block-gh-path-leak.sh — PreToolUse hook: catch operator-local path leaks in
# gh issue/PR bodies before they post to a PUBLIC repo (#1137).
# hook-owner: core/rules/git-workflow.md
#
# Extends the path-portability guard (#529) to the gh-issue-ops surface. The #529
# deploy-check covers tracked FILES; this hook covers the OTHER public surface —
# issue/PR bodies + comments authored via `gh`. Composed with #529's file-gate and
# the self-containment convention (core/rules/git-workflow.md § Draft / scratch).
#
# Consumes the SHARED primitive core/deploy/tools/path-leak-patterns.sh
# (PATH_LEAK_RE_* + path_leak_scan_line) — patterns + exempt predicate are shared;
# the gh-body corpus + the body-extraction below are this hook's per-surface job.
#
# NEW capability vs block-egress (FM-2): this hook reads the --body-file / -F body=@
# referenced FILE content (the dominant agent form), not only the command string.
# Fail-OPEN when the referenced file is absent/unreadable (warn-mode posture).
#
# HONEST coverage limit: a PreToolUse hook fires only on Claude's OWN gh tool calls.
# It does NOT cover operator-typed gh in a separate shell or GitHub web-UI edits —
# that out-of-band residual is accepted (covered by the convention + #529's file-gate
# for anything that also lands in a tracked file).
#
# Matcher scope: Bash. Rule ID: BLOCK-GH-PATH-001.
#
# MODE SURFACE: own mode file `.gh-path-leak-mode` (NOT the shared `.mode`), read
# EXCLUSIVELY with no fallback. A fallback would re-couple this rule to a cohort dial
# in both directions — a later cohort flip would re-flip this rule, and a shared file
# set to `off` would resolve a public-surface security guard to `off`. Promoting this
# rule via the shared file would instead have silently promoted seven unrelated hooks.
#
# SHIPPED POSTURE: `warn`, carried in this script's default-when-absent, which IS the
# operative posture — a `.template` is not reliably installed, so a design that puts the
# posture only in a template is a design whose posture may never land. The template
# matches this default as a convenience, not as the source of truth.
#
# WHY warn AND NOT enforce: the warn window produced zero deployed warn-log lines, and
# that is no evidence either way, because the wiring that loads this hook is absent in
# the sessions that produced the leaks. A zero whose instrument was never connected
# measures the wiring, not the behavior. The flip waits for real log data.
#
# WHAT THE MODE DOES NOT FIX. Mode is condition 4 of the four-condition coverage
# boundary in core/rules/bypass-mode-readiness.md. Condition 1 — loading — is delivered
# by an operator-run `docs/scripts/setup-workspace.sh --rehome-hook-wiring`, and until it
# runs on an instance this hook is not active there at any mode. No mode setting is a
# substitute for it, and a flip is never the remedy for it.

set -euo pipefail
export PATH="/usr/bin:/bin"

readonly GREP="/usr/bin/grep"
readonly PRINTF="/usr/bin/printf"
readonly CAT="/bin/cat"
readonly TR="/usr/bin/tr"
readonly DATE="/bin/date"
# jq is resolved below via lib/dep-resolve.sh (once HOOK_DIR is known), from a fixed
# absolute-path allowlist — never $PATH — so the anti-hijack PATH pin still holds
# (GHSA-9cjm-v22x-4x33).

readonly HOOK_NAME="block-gh-path-leak"
readonly HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"
readonly ERROR_LOG="${HOOK_DIR}/hook-errors.log"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"
readonly WARN_LOG="${HOOK_DIR}/gh-path-leak-warn-log.jsonl"
readonly MODE_FILE="${HOOK_DIR}/.gh-path-leak-mode"

# --- MODE DETECTION (own .gh-path-leak-mode, NOT the shared .mode) — defined BEFORE the
# dependency gate so the gate's severity is mode-coupled and the value is resolvable
# without the helper. EXCLUSIVE read: the shared .mode is never consulted, at any point,
# in either direction. The default below is the SHIPPED posture (see the header). ---
get_mode() {
  local mode="warn"
  [ -f "$MODE_FILE" ] && mode="$("$CAT" "$MODE_FILE" 2>/dev/null | "$TR" -d '[:space:]' || echo warn)"
  case "$mode" in warn|enforce|off) "$PRINTF" '%s' "$mode" ;; *) "$PRINTF" 'warn' ;; esac
}

# --- LIB-GUARD MODE SNAPSHOT (resolved BEFORE the dependency guard, frozen readonly) ---
# The guard below sources $DEP_LIB inside its own condition, so by the time the guard's
# failure branch runs, everything that file defines is already in THIS shell — including
# a get_mode of its own. Resolving the mode inside the branch would let the artifact
# under adjudication choose its own verdict. Resolve it here and freeze it: a sourced
# file cannot overwrite a readonly. Routed through get_mode()/$MODE_FILE (never a
# literal mode path), so a hook that later moves to its own mode file follows for free.
LIB_GUARD_MODE="$(get_mode)"; readonly LIB_GUARD_MODE

# --- SHARED DEPENDENCY RESOLVER (mode-coupled: fail CLOSED in enforce, degrade in warn/off) ---
# Test readability BEFORE sourcing: bash 3.2 (macOS system bash) exits 1 on a failed
# `.` of a missing file even inside an `if !` condition, and exit 1 (unlike exit 2) is
# NON-blocking in the PreToolUse contract — i.e. a missing helper would fail OPEN.
readonly DEP_LIB="${HOOK_DIR}/lib/dep-resolve.sh"
# Precheck syntax with `bash -n` BEFORE sourcing: a truncated/corrupt lib (interrupted
# cp, disk-full) is a parse error, and sourcing a parse-error file is FATAL to this
# parent — with partial top-level execution the process can exit 1 (NON-blocking =
# fail-OPEN) instead of blocking. `bash -n` detects that non-fatally so we fail CLOSED
# (GHSA-g9g6-28c9-vrx5). Also require deny_missing_primitive so a valid-but-stale lib
# (pre-fix, no helper) fails closed here rather than fail-open at a later ERR trap.
# Severity is mode-coupled: a rule match in warn/off would not block, so an unusable
# helper must not block harder than a match would.
if [ ! -r "$DEP_LIB" ] || ! "${BASH:-/bin/bash}" -n "$DEP_LIB" 2>/dev/null || ! . "$DEP_LIB" 2>/dev/null || ! command -v resolve_jq >/dev/null 2>&1 || ! command -v deny_missing_primitive >/dev/null 2>&1; then
  if [ "$LIB_GUARD_MODE" = "enforce" ]; then
    "$PRINTF" '[CLAUDE-HOOK:%s:LIB-MISSING] BLOCKED (fail-closed): dependency helper lib/dep-resolve.sh unavailable or invalid.\n' "$HOOK_NAME" >&2
    exit 2
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:LIB-MISSING] WARN (degraded, %s=%s): dependency helper lib/dep-resolve.sh unavailable or invalid; ALL rules for this hook are skipped this run. Reinstall the hook bundle (re-run docs/scripts/setup-workspace.sh) to restore enforcement.\n' "$HOOK_NAME" "${MODE_FILE##*/}" "$LIB_GUARD_MODE" >&2
  exit 0
fi
JQ="$(resolve_jq)"; readonly JQ

# Shared primitive resolves co-located FIRST (deployed layout: .claude/hooks/, where
# setup-workspace.sh co-deploys it next to the hooks), then the repo/source layout
# (core/hooks/../deploy/tools/, the DevTest + CI-check path). Both yield the same
# path_leak_* API. Without the co-located copy a DEPLOYED hook fail-opens, since
# .claude/hooks/../deploy/tools/ does not exist post-install. (#1850)
PRIMITIVE="${HOOK_DIR}/path-leak-patterns.sh"
[ -f "$PRIMITIVE" ] || PRIMITIVE="${HOOK_DIR}/../deploy/tools/path-leak-patterns.sh"
readonly PRIMITIVE

log_error() {
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$PRINTF" '%s [%s] %s\n' "$ts" "$HOOK_NAME" "$1" >> "$ERROR_LOG" 2>/dev/null || true
}
trap 'rc=$?; log_error "RULE-EVAL-ERROR at line $LINENO (exit $rc)"; "$PRINTF" "[CLAUDE-HOOK:%s:HOOK-ERROR] rule-eval error at line %s (exit %s).\n" "$HOOK_NAME" "$LINENO" "$rc" >&2; exit 0' ERR

# --- READ INPUT (jq-free; stdin is consumed exactly once) ---
INPUT="$(cat)"

# --- CLAUDE_HOOK_BYPASS escape hatch — evaluated BEFORE the jq gate so it works even
# when jq is unresolvable (GHSA-9cjm-v22x-4x33). ---
if [ "${CLAUDE_HOOK_BYPASS:-}" = "1" ]; then
  ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  if [ -n "$JQ" ]; then
    "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" '{ts:$ts,hook:$hook,action:"bypass"}' >> "$BYPASS_LOG" 2>/dev/null || true
  else
    "$PRINTF" '{"ts":"%s","hook":"%s","action":"bypass","note":"jq-unresolved"}\n' "$ts" "$HOOK_NAME" >> "$BYPASS_LOG" 2>/dev/null || true
  fi
  exit 0
fi

# --- Master-activation gate (#310) — layer 2, AFTER CLAUDE_HOOK_BYPASS and BEFORE the
# mode read (this hook's own `.gh-path-leak-mode`, never the shared `.mode`). CLASS=security (D-R9): master-OFF NEVER makes this hook inert — the
# security/floor class always enforces (public-surface security is paramount; a silently
# disabled guard -> an IRREVERSIBLE leaked commit/PR). It goes inert ONLY on the operator's
# explicit, logged security_class_master_optout=true. Fail-toward-current-behavior: a
# missing lib does NOT gate. Read jq-free from the durable XDG platform-config.toml. ---
readonly MASTER_ENABLE_CLASS="security"
readonly MASTER_LIB="${HOOK_DIR}/lib/master-enable.sh"
if [ -r "$MASTER_LIB" ]; then . "$MASTER_LIB" 2>/dev/null || true; fi
if command -v master_enable_gate >/dev/null 2>&1; then master_enable_gate "$MASTER_ENABLE_CLASS"; fi

# --- DEPENDENCY GATE (mode-gated posture — GHSA-9cjm-v22x-4x33). This hook ships
# warn, so a missing jq must not block harder than a rule match would: only a
# resolved mode of `enforce` fails CLOSED (exit 2); warn/off degrade to a stderr
# note + exit 0. Runs AFTER the bypass short-circuit.
#
# The mode read here is the EXCLUSIVE one defined above — this hook's own
# `.gh-path-leak-mode`, never the shared `.mode`. This comment previously wrote
# the resolved value as `.mode=enforce`, which named the shared file the hook
# deliberately does not consult; a maintainer reading only this block could have
# reintroduced the shared-file fallback the exclusive read exists to remove. ---
if [ -z "$JQ" ]; then
  log_error "DEPENDENCY-MISSING: jq not found on the pinned tool path"
  _mode="$(get_mode)"
  if [ "$_mode" = "enforce" ]; then
    deny_missing_dep jq "$HOOK_NAME" "$PRINTF"
    exit 2   # caller owns the fail-closed exit — never trust the callee to terminate (GHSA-g9g6)
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:DEPENDENCY-MISSING] WARN (degraded, %s=%s): jq not found on the pinned tool path; gh path-leak scan skipped.\n' "$HOOK_NAME" "${MODE_FILE##*/}" "$_mode" >&2
  exit 0
fi

if ! "$PRINTF" '%s' "$INPUT" | "$JQ" -e . >/dev/null 2>&1; then
  log_error "INVALID-INPUT"; exit 0   # fail-open on malformed input (warn-posture)
fi
TOOL_NAME="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_name // empty')"
[ "$TOOL_NAME" = "Bash" ] || exit 0

# --- Workspace-scope gate (#4436) — layer 3, AFTER the master-activation gate and
# BEFORE the mode / rule path. Precedence: bypass -> master -> SCOPE ->
# `.gh-path-leak-mode` -> rule. Named explicitly: the shared `.mode` is not in this
# hook's precedence chain at any position.
# CWD is extracted here (this hook did not previously need it) purely to feed the guard.
# Inverted fail direction on the cwd axis, NOT on the lib axis. See lib/scope-guard.sh. ---
CWD="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.cwd // empty')"
readonly SCOPE_GUARD_LIB="${HOOK_DIR}/lib/scope-guard.sh"
if [ -r "$SCOPE_GUARD_LIB" ]; then . "$SCOPE_GUARD_LIB" 2>/dev/null || true; fi
if command -v scope_guard_gate >/dev/null 2>&1; then scope_guard_gate "$CWD"; fi

COMMAND="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.command // empty')"
[ -z "$COMMAND" ] && exit 0

# Only act on gh issue/PR WRITES (create / edit / comment) or gh api writes to
# issues/pulls. Reads (view/list) carry no authored body → skip.
if ! "$PRINTF" '%s' "$COMMAND" | "$GREP" -qE 'gh[[:space:]]+(issue|pr)[[:space:]]+(create|edit|comment)|gh[[:space:]]+api[[:space:]]+[^|;&]*(issues|pulls)'; then
  exit 0
fi

# --- SHARED PRIMITIVE gate (mode-gated posture — GHSA-g9g6-28c9-vrx5). We are now
# committed to scanning a gh issue/PR body, which REQUIRES the co-shipped primitive's API
# (path_leak_scan_line). Missing, syntactically broken (bash -n), OR present-but-empty/
# truncated (sources cleanly yet defines nothing) all mean the scan cannot run — treat
# exactly like a missing jq (GHSA-9cjm posture): enforce fails CLOSED (deny the gh write),
# warn/off degrade to a note + exit 0. Verifying the API (command -v), not mere file
# existence, closes the partial-install fail-open where an empty primitive let the
# `if path_leak_scan_line` condition swallow a 127 "command not found" as a no-match.
# Placed AFTER the non-gh short-circuits so an absent primitive never blocks unrelated Bash. ---
_primitive_ok=0
if [ -f "$PRIMITIVE" ] && "${BASH:-/bin/bash}" -n "$PRIMITIVE" 2>/dev/null; then
  # shellcheck source=/dev/null
  . "$PRIMITIVE" 2>/dev/null || true
  command -v path_leak_scan_line >/dev/null 2>&1 && _primitive_ok=1
fi
if [ "$_primitive_ok" -ne 1 ]; then
  log_error "PRIMITIVE-MISSING-OR-INVALID: $PRIMITIVE did not provide path_leak_scan_line"
  _pmode="$(get_mode)"
  if [ "$_pmode" = "enforce" ]; then
    deny_missing_primitive "path-leak-patterns.sh" "$HOOK_NAME" "$PRINTF"
    exit 2   # caller owns the fail-closed exit — never trust the callee to terminate (GHSA-g9g6)
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:PRIMITIVE-MISSING] WARN (degraded, %s=%s): co-shipped primitive path-leak-patterns.sh absent or invalid; gh path-leak scan skipped.\n' "$HOOK_NAME" "${MODE_FILE##*/}" "$_pmode" >&2
  exit 0
fi

# --- Body extraction (this hook's per-surface job) ---
# Collect the authored body text from the three gh forms:
#   --body-file <path> / -F body=@<path> / --field body=@<path>  → read the FILE (FM-2)
#   --body <text> / -b <text> / -f body=<text>                   → inline text
BODY=""
# (1) referenced files — read content (fail-open if absent/unreadable)
for bf in $("$PRINTF" '%s' "$COMMAND" | "$GREP" -oE -- '(--body-file[[:space:]]+|(-F|--field)[[:space:]]+body=@)[^[:space:];&|]+' | "$GREP" -oE '[^[:space:]@]+$' || true); do
  if [ -f "$bf" ] && [ -r "$bf" ]; then
    BODY="${BODY}"$'\n'"$("$CAT" "$bf" 2>/dev/null || true)"
  fi
done
# (2) inline body text (best-effort: capture the token(s) after --body/-b/-f body=)
INLINE="$("$PRINTF" '%s' "$COMMAND" | "$GREP" -oE -- '(--body|-b|-f[[:space:]]+body=)[[:space:]]*[^|;&]+' || true)"
BODY="${BODY}"$'\n'"${INLINE}"

[ -z "$(printf '%s' "$BODY" | "$TR" -d '[:space:]')" ] && exit 0

# --- Scan the body for path leaks (shared primitive; per-surface allow = the
# primitive's generalized-pointer exemptions already pass roadmaps/skill-matrix.md
# etc.; a quoted worked-example can carry 'path-leak: allow') ---
LEAK=""
while IFS= read -r line || [ -n "$line" ]; do
  if path_leak_scan_line "$line"; then
    LEAK="$(printf '%s' "$line" | /usr/bin/sed 's/^[[:space:]]*//' | /usr/bin/cut -c1-80)"
    break
  fi
done <<EOF
$BODY
EOF

[ -z "$LEAK" ] && exit 0

mode="$(get_mode)"
reason="operator-local path leak in a gh issue/PR body bound for a PUBLIC repo: '${LEAK}'. Rewrite it in a sanctioned form per core/standards/analysis-workspace-standard.md section 6.1 — repo-relative, \$HOME-relative, the \${VAR:-\$HOME/Claude} default-expansion, or a registered operator-instance token — instead of an absolute machine path with a username segment or a bare relative operator-instance path."
# The three sanctioned escapes, named in BOTH branches. Under the shipped warn posture the
# enforce branch never executes, so an escape list that lives only there is an escape list
# no operator ever reads. ${MODE_FILE##*/} rather than a literal: parameter expansion, so
# the notice stays accurate if this hook's mode file is ever renamed again, and it takes no
# dependency on an external binary resolving.
escapes="Escapes: mark a worked-example line with 'path-leak: allow'; set CLAUDE_HOOK_BYPASS=1 for the session; or set ${MODE_FILE##*/}=off. Never alter the text's spelling to avoid the match — that evades the control rather than answering it."
ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
case "$mode" in
  off) exit 0 ;;
  warn)
    "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "BLOCK-GH-PATH-001" --arg evidence "$LEAK" \
      '{ts:$ts,hook:$hook,rule:$rule,evidence:$evidence}' >> "$WARN_LOG" 2>/dev/null || true
    "$PRINTF" '[CLAUDE-HOOK:%s:BLOCK-GH-PATH-001] WARN (would-block, %s=%s): %s\n%s\n' "$HOOK_NAME" "${MODE_FILE##*/}" "$mode" "$reason" "$escapes" >&2
    exit 0 ;;
  enforce|*)
    "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "BLOCK-GH-PATH-001" --arg evidence "$LEAK" \
      '{ts:$ts,hook:$hook,rule:$rule,evidence:$evidence}' >> "$BLOCK_LOG" 2>/dev/null || true
    "$PRINTF" '[CLAUDE-HOOK:%s:BLOCK-GH-PATH-001] BLOCKED: %s\n%s\n' "$HOOK_NAME" "$reason" "$escapes" >&2
    exit 2 ;;
esac
