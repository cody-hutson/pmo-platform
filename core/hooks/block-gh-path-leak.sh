#!/bin/bash
# block-gh-path-leak.sh — PreToolUse hook: catch operator-local path leaks in
# gh issue/PR bodies before they post to a PUBLIC repo (#1137).
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
# Matcher scope: Bash. Rule ID: BLOCK-GH-PATH-001. Warn-mode initial (.mode).

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
readonly MODE_FILE="${HOOK_DIR}/.mode"

# --- SHARED DEPENDENCY RESOLVER (fail CLOSED if the helper is missing/invalid) ---
# Test readability BEFORE sourcing: bash 3.2 (macOS system bash) exits 1 on a failed
# `.` of a missing file even inside an `if !` condition, and exit 1 (unlike exit 2) is
# NON-blocking in the PreToolUse contract — i.e. a missing helper would fail OPEN.
readonly DEP_LIB="${HOOK_DIR}/lib/dep-resolve.sh"
if [ ! -r "$DEP_LIB" ] || ! . "$DEP_LIB" 2>/dev/null || ! command -v resolve_jq >/dev/null 2>&1; then
  "$PRINTF" '[CLAUDE-HOOK:%s:LIB-MISSING] BLOCKED (fail-closed): dependency helper lib/dep-resolve.sh unavailable or invalid.\n' "$HOOK_NAME" >&2
  exit 2
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

get_mode() {
  local mode="warn"
  [ -f "$MODE_FILE" ] && mode="$("$CAT" "$MODE_FILE" 2>/dev/null | "$TR" -d '[:space:]' || echo warn)"
  case "$mode" in warn|enforce|off) "$PRINTF" '%s' "$mode" ;; *) "$PRINTF" 'warn' ;; esac
}

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

# --- DEPENDENCY GATE (mode-gated posture — GHSA-9cjm-v22x-4x33). This hook ships
# warn, so a missing jq must not block harder than a rule match would: only .mode=
# enforce fails CLOSED (exit 2); warn/off degrade to a stderr note + exit 0. Runs
# AFTER the bypass short-circuit. ---
if [ -z "$JQ" ]; then
  log_error "DEPENDENCY-MISSING: jq not found on the pinned tool path"
  _mode="$(get_mode)"
  if [ "$_mode" = "enforce" ]; then
    deny_missing_dep jq "$HOOK_NAME" "$PRINTF"
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:DEPENDENCY-MISSING] WARN (degraded, .mode=%s): jq not found on the pinned tool path; gh path-leak scan skipped.\n' "$HOOK_NAME" "$_mode" >&2
  exit 0
fi

# --- SHARED PRIMITIVE (fail-OPEN if missing — warn posture, separate concern from jq) ---
if [ ! -f "$PRIMITIVE" ]; then
  log_error "PRIMITIVE-MISSING: $PRIMITIVE — fail-open"; exit 0
fi
# shellcheck source=/dev/null
. "$PRIMITIVE"

if ! "$PRINTF" '%s' "$INPUT" | "$JQ" -e . >/dev/null 2>&1; then
  log_error "INVALID-INPUT"; exit 0   # fail-open on malformed input (warn-posture)
fi
TOOL_NAME="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_name // empty')"
[ "$TOOL_NAME" = "Bash" ] || exit 0

COMMAND="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.command // empty')"
[ -z "$COMMAND" ] && exit 0

# Only act on gh issue/PR WRITES (create / edit / comment) or gh api writes to
# issues/pulls. Reads (view/list) carry no authored body → skip.
if ! "$PRINTF" '%s' "$COMMAND" | "$GREP" -qE 'gh[[:space:]]+(issue|pr)[[:space:]]+(create|edit|comment)|gh[[:space:]]+api[[:space:]]+[^|;&]*(issues|pulls)'; then
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
reason="operator-local path leak in a gh issue/PR body bound for a PUBLIC repo: '${LEAK}'. Use a generalized operator-instance-relative pointer (e.g. roadmaps/skill-matrix.md, \"operator-local per ADR-012\") instead of an absolute /Users//home path or a bare personal/pmo-instance path."
ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
case "$mode" in
  off) exit 0 ;;
  warn)
    "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "BLOCK-GH-PATH-001" --arg evidence "$LEAK" \
      '{ts:$ts,hook:$hook,rule:$rule,evidence:$evidence}' >> "$WARN_LOG" 2>/dev/null || true
    "$PRINTF" '[CLAUDE-HOOK:%s:BLOCK-GH-PATH-001] WARN (would-block, .mode=warn): %s\n' "$HOOK_NAME" "$reason" >&2
    exit 0 ;;
  enforce|*)
    "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "BLOCK-GH-PATH-001" --arg evidence "$LEAK" \
      '{ts:$ts,hook:$hook,rule:$rule,evidence:$evidence}' >> "$BLOCK_LOG" 2>/dev/null || true
    "$PRINTF" '[CLAUDE-HOOK:%s:BLOCK-GH-PATH-001] BLOCKED: %s\nOverride: generalize the path, mark a worked-example line with '\''path-leak: allow'\'', or set CLAUDE_HOOK_BYPASS=1.\n' "$HOOK_NAME" "$reason" >&2
    exit 2 ;;
esac
