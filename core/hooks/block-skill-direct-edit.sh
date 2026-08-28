#!/bin/bash
# block-skill-direct-edit.sh — PreToolUse hook enforcing pmo-skill-editor invocation
# hook-owner: core/standards/canonical-skill-structure.md
#
# Gate 2 of the dual-gate skill-discipline enforcement.
# Rejects direct Write/Edit to pmo-platform/skills/<skill>/SKILL.md, reference/**/*.md,
# or references/**/*.md on migrated skills unless a valid pmo-skill-editor session
# sentinel is present. Both singular and plural reference-dir paths are matched
# during the migration window; post-migration hardening to plural-only is
# deferred to a future release. Reference matching is depth-agnostic: a pack or corpus
# file nested below reference[s]/ is behavior-defining and gated exactly as a top-level
# reference file is. See the SCOPE CHECK block for the bounds that keep it from
# over-matching.
#
# Matcher scope: Write, Edit
#
# Rule ID range: BLOCK-SKILL-EDIT-001..099
#
# Pattern: mirrors .claude/hooks/block-destructive.sh architecture exactly
# (PATH pinning, mode-coupled jq posture via lib/dep-resolve.sh [enforce → fail-closed
# on missing jq, warn/off → degrade], fail-closed-on-malformed-input,
# CLAUDE_HOOK_BYPASS escape hatch with audit, .mode file for warn/enforce/off).

set -euo pipefail

# --- PATH PINNING (tamper resistance) ---
export PATH="/usr/bin:/bin"

readonly GREP="/usr/bin/grep"
readonly PRINTF="/usr/bin/printf"
readonly DATE="/bin/date"
# jq is resolved below via lib/dep-resolve.sh (once HOOK_DIR is known), from a fixed
# absolute-path allowlist — never $PATH — so the anti-hijack PATH pin still holds
# (GHSA-9cjm-v22x-4x33).

# --- METADATA ---
readonly HOOK_NAME="block-skill-direct-edit"
readonly HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"
readonly ERROR_LOG="${HOOK_DIR}/hook-errors.log"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"
readonly WARN_LOG="${HOOK_DIR}/skill-edit-warn-log.jsonl"
readonly MODE_FILE="${HOOK_DIR}/.mode"
readonly PRIMARY_ROOT="${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}"
# EXEMPTION_LIST resolves relative to the hook's own directory (matches
# block-destructive.sh's SCRIPT_ALLOWLIST pattern). This ensures the hook
# finds the exemption list in whichever checkout it runs from — primary or
# worktree — which matters during engineering before deployment to primary.
readonly EXEMPTION_LIST="${HOOK_DIR}/../skill-editor-exemption-list.txt"
readonly SENTINEL_TTL_SECONDS=1800  # 30 minutes

# --- MODE DETECTION (shared harness .mode; warn|enforce|off) ---
# jq-free (/bin/cat + /usr/bin/tr only), so it resolves without the dependency helper
# and is therefore defined ahead of the gate below. Extracted from the two inline reads
# that used to sit further down; the normalization — whitespace stripped, unrecognized
# value defaults to enforce — is unchanged.
get_mode() {
  local mode="enforce" raw
  if [ -f "$MODE_FILE" ]; then
    # `|| echo` makes the substitution total. The pipeline returns 1 on a present-but-
    # unreadable mode file, and this runs under `set -euo pipefail` BEFORE the ERR trap is
    # armed — measured, the hook still resolves to the default here and fails closed, but
    # only via a subtle `set -e` interaction with assignment-inside-function. The fallback
    # removes the dependence on it and matches the shape the other cohort hooks already use.
    raw="$(/bin/cat "$MODE_FILE" 2>/dev/null | /usr/bin/tr -d '[:space:]' || echo enforce)"
    case "$raw" in
      warn|enforce|off) mode="$raw" ;;
    esac
  fi
  "$PRINTF" '%s' "$mode"
}

# --- LIB-GUARD MODE SNAPSHOT (resolved BEFORE the dependency guard, frozen readonly) ---
# The guard below sources $DEP_LIB inside its own condition, so by the time the guard's
# failure branch runs, everything that file defines is already in THIS shell — including
# a get_mode of its own. Resolving the mode inside the branch would let the artifact
# under adjudication choose its own verdict. Resolve it here and freeze it: a sourced
# file cannot overwrite a readonly. Routed through get_mode()/$MODE_FILE (never a
# literal mode path), so a hook that later moves to its own mode file follows for free.
LIB_GUARD_MODE="$(get_mode)"; readonly LIB_GUARD_MODE

# --- SHARED DEPENDENCY RESOLVER (mode-coupled: fail CLOSED in enforce, degrade in
# warn/off). Test readability BEFORE sourcing: bash 3.2 (macOS system bash) exits 1
# on a failed `.` of a missing file even inside an `if !` condition, and exit 1
# (unlike exit 2) is NON-blocking in the PreToolUse contract — i.e. a missing helper
# would fail OPEN. Precheck syntax with `bash -n` BEFORE sourcing: a truncated/corrupt
# lib is a parse error, and sourcing a parse-error file is FATAL to this parent. Also
# require deny_missing_primitive so a valid-but-stale lib (pre-fix, no helper) trips
# here. Severity is mode-coupled: a rule match in warn/off would not block, so an
# unusable helper must not block harder than a match would. ---
readonly DEP_LIB="${HOOK_DIR}/lib/dep-resolve.sh"
if [ ! -r "$DEP_LIB" ] || ! "${BASH:-/bin/bash}" -n "$DEP_LIB" 2>/dev/null || ! . "$DEP_LIB" 2>/dev/null || ! command -v resolve_jq >/dev/null 2>&1 || ! command -v deny_missing_primitive >/dev/null 2>&1; then
  if [ "$LIB_GUARD_MODE" = "enforce" ]; then
    "$PRINTF" '[CLAUDE-HOOK:%s:LIB-MISSING] BLOCKED (fail-closed): dependency helper lib/dep-resolve.sh unavailable or invalid.\n' "$HOOK_NAME" >&2
    exit 2
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:LIB-MISSING] WARN (degraded, %s=%s): dependency helper lib/dep-resolve.sh unavailable or invalid; ALL rules for this hook are skipped this run. Reinstall the hook bundle (re-run docs/scripts/setup-workspace.sh) to restore enforcement.\n' "$HOOK_NAME" "${MODE_FILE##*/}" "$LIB_GUARD_MODE" >&2
  exit 0
fi
JQ="$(resolve_jq)"; readonly JQ

# --- ERROR HANDLERS ---
log_error() {
  local ts
  ts="$($DATE -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo 'unknown')"
  "$PRINTF" '%s [%s] %s\n' "$ts" "$HOOK_NAME" "$1" >> "$ERROR_LOG" 2>/dev/null || true
}

trap 'rc=$?; log_error "RULE-EVAL-ERROR at line $LINENO (exit $rc)"; "$PRINTF" "[CLAUDE-HOOK:%s:HOOK-ERROR] BLOCKED: rule-evaluation error at line %s (exit %s). See %s.\n" "$HOOK_NAME" "$LINENO" "$rc" "$ERROR_LOG" >&2; exit 2' ERR

# --- READ INPUT (jq-free; stdin is consumed exactly once) ---
INPUT="$(cat)"

# --- CLAUDE_HOOK_BYPASS escape hatch — evaluated BEFORE the jq gate so it works even
# when jq is unresolvable (GHSA-9cjm-v22x-4x33: the escape hatch must not depend on
# the very dependency whose absence it exists to work around). ---
if [ "${CLAUDE_HOOK_BYPASS:-}" = "1" ]; then
  ts="$($DATE -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  if [ -n "$JQ" ]; then
    btool="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_name // empty' 2>/dev/null || echo unknown)"
    "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg tool "$btool" \
      '{ts:$ts, hook:$hook, tool:$tool, action:"bypass"}' \
      >> "$BYPASS_LOG" 2>/dev/null || true
  else
    "$PRINTF" '{"ts":"%s","hook":"%s","action":"bypass","note":"jq-unresolved"}\n' "$ts" "$HOOK_NAME" >> "$BYPASS_LOG" 2>/dev/null || true
  fi
  exit 0
fi

# --- Master-activation gate (#310) — layer 2, AFTER CLAUDE_HOOK_BYPASS and BEFORE the
# .mode read (precedence: bypass -> master -> .mode -> rule). CLASS=workflow: master-OFF
# makes this hook inert (exit 0). Fail-toward-current-behavior: a missing lib does NOT
# gate, so the hook keeps its existing .mode enforcement (a read failure never disables a
# guard). Read jq-free from the durable XDG platform-config.toml [security_hooks]. ---
readonly MASTER_ENABLE_CLASS="workflow"
readonly MASTER_LIB="${HOOK_DIR}/lib/master-enable.sh"
if [ -r "$MASTER_LIB" ]; then . "$MASTER_LIB" 2>/dev/null || true; fi
if command -v master_enable_gate >/dev/null 2>&1; then master_enable_gate "$MASTER_ENABLE_CLASS"; fi

# --- DEPENDENCY GATE (mode-gated: this hook reads the shared .mode with an enforce
# default, so a missing jq must fail CLOSED in enforce mode (a control that cannot parse
# its input must not ALLOW) and degrade to exit 0 in warn/off (never block harder than a
# rule match would). GHSA-9cjm-v22x-4x33; the helper guard above still fails CLOSED when
# the resolver LIB itself is missing. Runs AFTER the bypass. ---
if [ -z "$JQ" ]; then
  log_error "DEPENDENCY-MISSING: jq not found on the pinned tool path"
  _dep_mode="$LIB_GUARD_MODE"
  if [ "$_dep_mode" = "enforce" ]; then
    deny_missing_dep jq "$HOOK_NAME" "$PRINTF"
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:DEPENDENCY-DEGRADED] jq not found; hook DEGRADED (exit 0) in %s mode.\n' "$HOOK_NAME" "$_dep_mode" >&2
  exit 0
fi

# --- VALIDATE INPUT ---
if ! "$PRINTF" '%s' "$INPUT" | "$JQ" -e . >/dev/null 2>&1; then
  log_error "INVALID-INPUT: malformed JSON on stdin"
  "$PRINTF" '[CLAUDE-HOOK:%s:INPUT-INVALID] BLOCKED: malformed hook input JSON.\n' "$HOOK_NAME" >&2
  exit 2
fi

TOOL_NAME="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_name // empty')"

# Only handle Write and Edit (settings.json matchers constrain, but defense-in-depth)
case "$TOOL_NAME" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

# --- Workspace-scope gate (#4436) — layer 3, AFTER the master-activation gate and
# BEFORE the .mode / rule path. Precedence: bypass -> master -> SCOPE -> .mode -> rule.
# CWD is extracted here (this hook did not previously need it) purely to feed the guard.
# Inverted fail direction on the cwd axis, NOT on the lib axis. See lib/scope-guard.sh. ---
CWD="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.cwd // empty')"
readonly SCOPE_GUARD_LIB="${HOOK_DIR}/lib/scope-guard.sh"
if [ -r "$SCOPE_GUARD_LIB" ]; then . "$SCOPE_GUARD_LIB" 2>/dev/null || true; fi
if command -v scope_guard_gate >/dev/null 2>&1; then scope_guard_gate "$CWD"; fi

FILE_PATH="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.file_path // empty')"
[ -z "$FILE_PATH" ] && exit 0

# --- SCOPE CHECK — act on <root>/skills/<skill>/{SKILL.md | reference[s]/**/*.md} ---
# <root> is a SOURCE module: operations | release | core | pmo-platform (legacy).
# Deploy targets (.claude/skills/) are intentionally NOT in scope.
#
# The reference branch matches at ANY DEPTH below reference[s]/ (`.+`, not `[^/]+`).
# The single-level form left every nested reference subtree ungated — measured at 12
# behavior-defining files across 3 migrated skills (build-reviewer dimension-packs/,
# implementation-planner domain-packs/, pmo-wms-specialist corpus/). A dimension pack IS
# the skill's review behavior and a domain pack IS its classification behavior, so editing
# one changes what the skill does exactly as editing SKILL.md does. Pack-per-subdirectory
# is the growth direction for these skills, so a single-level matcher sheds coverage as the
# corpus grows; depth-agnostic matching is the only form that does not.
#
# Deliberately still bounded on three axes, each load-bearing against over-matching:
#   - the reference[s]/ segment is still REQUIRED, so sibling subtrees under the skill
#     (assets/, templates/, tests/) stay out of scope;
#   - the \.md$ anchor is still required, so non-markdown pack assets stay out of scope;
#   - the <skill> segment is still [^/]+, so skill-directory depth is unchanged.
#
# Those three bound what THIS REGEX MATCHES. They do not bound what a SECOND pattern over
# the same path would match, and that distinction is load-bearing here: `.+` admits `/`, so
# an in-scope path may carry a further <root>/skills/<segment> inside its reference subtree.
# Scope stays correct on such a path — it is the skill-directory EXTRACTION below that a
# second pattern gets wrong, and the greedy one this replaced anchored on the LAST
# occurrence rather than on the one that put the file in scope. The extraction now reads
# the matched substring instead of re-matching. Armed by tests 27 (nested) and 28 (ordinary).
SKILL_SCOPE_RE='(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$'
if [[ "$FILE_PATH" =~ $SKILL_SCOPE_RE ]]; then
  SCOPE_MATCH="${BASH_REMATCH[0]}"
else
  exit 0
fi

# --- EXTRACT SKILL DIRECTORY + NAME (read off the scope match, never re-derived) ---
# Derived from SCOPE_MATCH — the substring the scope regex actually matched — rather than
# from a second pattern over $FILE_PATH. Any second pattern can select a DIFFERENT
# <root>/skills/<skill> than the one that put the file in scope; the greedy one this
# replaced selected the last (test 27 pins the case). Reading the match removes the class
# rather than trading one disagreeing pattern for another: the extracted directory is by
# construction the one the matcher accepted. Note the target is NOT simply the first
# `/skills/` in the path — it is the segment THIS match began at, which on some shapes is
# a later one. The scope regex is $-anchored, so SCOPE_MATCH is a suffix of FILE_PATH and
# the prefix is recovered by suffix removal.
# The condition above is written in POSITIVE form deliberately: BASH_REMATCH must be
# consumed with no intervening [[ =~ ]] able to clobber it, and control flow should show
# that dependency rather than leave it to a comment.
SCOPE_PREFIX="${FILE_PATH%"$SCOPE_MATCH"}"
SCOPE_BODY="$SCOPE_MATCH"
case "$SCOPE_BODY" in
  /*) SCOPE_PREFIX="${SCOPE_PREFIX}/"; SCOPE_BODY="${SCOPE_BODY#/}" ;;  # the (^|/) alternative
esac
skill_root="${SCOPE_BODY%%/*}"
skill="${SCOPE_BODY#*/skills/}"
skill="${skill%%/*}"
skill_dir="${SCOPE_PREFIX}${skill_root}/skills/${skill}"
if [ -z "$skill" ] || [ -z "$skill_dir" ]; then
  log_error "SCOPE-PARSE-ERROR: could not extract skill dir from $FILE_PATH"
  exit 0  # fail-open on parse failure (defensive)
fi

# --- EXEMPTION LIST check ---
if [ -f "$EXEMPTION_LIST" ] && "$GREP" -Fxq "$skill" "$EXEMPTION_LIST" 2>/dev/null; then
  exit 0  # canary or operator-exempted skill
fi

# --- PRE-MIGRATION pass-through ---
# Non-breaking on legacy: if the skill has NOT yet landed the migration marker
# (via per-skill migration commits), the gate is not yet active on that skill.
# Resolve SKILL.md from the skill's own directory (absolute path resolves
# directly; a repo-relative path falls back under the workspace root).
SKILL_MD="$skill_dir/SKILL.md"
if [ ! -f "$SKILL_MD" ]; then
  SKILL_MD_ABS="${PRIMARY_ROOT}/$skill_dir/SKILL.md"
  [ -f "$SKILL_MD_ABS" ] && SKILL_MD="$SKILL_MD_ABS"
fi
if [ -f "$SKILL_MD" ] && ! "$GREP" -qE '^skill_discipline_migrated_v10_2:[[:space:]]*true[[:space:]]*$' "$SKILL_MD"; then
  exit 0  # not yet gated
fi

# --- SENTINEL check ---
SENTINEL="$skill_dir/.editor-session"
if [ ! -f "$SENTINEL" ]; then
  SENTINEL_ABS="${PRIMARY_ROOT}/$skill_dir/.editor-session"
  [ -f "$SENTINEL_ABS" ] && SENTINEL="$SENTINEL_ABS"
fi

# --- MODE check — already resolved above the dependency guard and frozen readonly.
# Reuse the snapshot rather than re-reading: same value, one fewer read, and a value
# the sourced helper cannot have influenced. The off short-circuit stays HERE — after
# bypass and the master-enable gate — so the precedence chain is unchanged. ---
MODE="$LIB_GUARD_MODE"
[ "$MODE" = "off" ] && exit 0

# --- HELPERS ---
digest() {
  "$PRINTF" '%s' "$1" | /usr/bin/shasum -a 256 | "$GREP" -oE '^[a-f0-9]+' | /usr/bin/head -c 16
}

log_block() {
  local rule_id="$1"
  local ts
  ts="$($DATE -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  local tool_input
  tool_input="$("$PRINTF" '%s' "$INPUT" | "$JQ" -c '.tool_input // {}')"
  local input_digest
  input_digest="$(digest "$tool_input")"
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg digest "$input_digest" --arg skill "$skill" --arg path "$FILE_PATH" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, input_digest:$digest, skill:$skill, file_path:$path}' \
    >> "$BLOCK_LOG" 2>/dev/null || true
}

log_warn() {
  local rule_id="$1"
  local reason="$2"
  local ts
  ts="$($DATE -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg skill "$skill" --arg path "$FILE_PATH" --arg reason "$reason" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, skill:$skill, file_path:$path, reason:$reason}' \
    >> "$WARN_LOG" 2>/dev/null || true
}

apply_block() {
  local rule_id="$1"
  local reason="$2"
  local override="$3"
  if [ "$MODE" = "warn" ]; then
    log_warn "$rule_id" "$reason"
    "$PRINTF" '[CLAUDE-HOOK:%s:%s:WARN] %s (warn-mode active — not blocking; would block in enforce-mode)\n' "$HOOK_NAME" "$rule_id" "$reason" >&2
    exit 0
  fi
  log_block "$rule_id"
  "$PRINTF" '[CLAUDE-HOOK:%s:%s] BLOCKED: %s\nOverride: %s\n' "$HOOK_NAME" "$rule_id" "$reason" "$override" >&2
  exit 2
}

# Determine rule ID based on file type in scope
case "$FILE_PATH" in
  */SKILL.md) RULE_ID="BLOCK-SKILL-EDIT-001" ;;
  *) RULE_ID="BLOCK-SKILL-EDIT-002" ;;
esac

# --- SENTINEL presence ---
if [ ! -f "$SENTINEL" ]; then
  apply_block "$RULE_ID" \
    "Direct edit to $FILE_PATH denied — no pmo-skill-editor session marker at $skill_dir/.editor-session (skill has migration marker; gate active)." \
    "invoke pmo-skill-editor Mode A to start an editing session, OR exit claude and relaunch with CLAUDE_HOOK_BYPASS=1 claude"
fi

# --- SENTINEL parse ---
if ! "$JQ" -e . "$SENTINEL" >/dev/null 2>&1; then
  apply_block "$RULE_ID" \
    "Editor session sentinel at $SENTINEL is malformed (not valid JSON)" \
    "remove the sentinel and re-invoke pmo-skill-editor, OR set CLAUDE_HOOK_BYPASS=1"
fi

# --- TARGET-SKILL match ---
target_skill="$("$JQ" -r '.target_skill // empty' "$SENTINEL" 2>/dev/null)"
if [ "$target_skill" != "$skill" ]; then
  apply_block "$RULE_ID" \
    "Sentinel target_skill='$target_skill' does not match edit target '$skill'" \
    "ensure pmo-skill-editor session is on the correct skill, OR set CLAUDE_HOOK_BYPASS=1"
fi

# --- TTL check ---
started_at="$("$JQ" -r '.started_at // empty' "$SENTINEL" 2>/dev/null)"
if [ -z "$started_at" ]; then
  apply_block "$RULE_ID" \
    "Sentinel at $SENTINEL missing started_at field" \
    "re-invoke pmo-skill-editor, OR set CLAUDE_HOOK_BYPASS=1"
fi

# BSD date for ISO-8601 UTC parsing; trailing Z stripped for -f pattern
started_clean="${started_at%Z}"
started_epoch="$($DATE -j -u -f '%Y-%m-%dT%H:%M:%S' "$started_clean" '+%s' 2>/dev/null || echo '')"
now_epoch="$($DATE -u '+%s')"

if [ -z "$started_epoch" ]; then
  apply_block "$RULE_ID" \
    "Sentinel started_at='$started_at' is not a parseable ISO-8601 UTC timestamp" \
    "re-invoke pmo-skill-editor, OR set CLAUDE_HOOK_BYPASS=1"
fi

age=$((now_epoch - started_epoch))
if [ "$age" -lt 0 ]; then
  apply_block "$RULE_ID" \
    "Editor session sentinel has future timestamp (started_at=$started_at; current=$($DATE -u '+%Y-%m-%dT%H:%M:%SZ'))" \
    "reset system clock OR invoke pmo-skill-editor Mode A to regenerate sentinel"
fi
if [ "$age" -gt "$SENTINEL_TTL_SECONDS" ]; then
  apply_block "$RULE_ID" \
    "Editor session sentinel stale (age=${age}s > ${SENTINEL_TTL_SECONDS}s TTL); session expired" \
    "re-invoke pmo-skill-editor to refresh the session, OR set CLAUDE_HOOK_BYPASS=1"
fi

# All checks passed — allow
exit 0
