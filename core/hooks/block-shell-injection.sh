#!/bin/bash
# block-shell-injection.sh — PreToolUse hook blocking shell-injection patterns in script-execution argv
# hook-owner: core/rules/bypass-mode-readiness/block-shell-injection.md
#
# Closes the slash-command shell-injection class identified in a security audit:
# the slash command surface (`~/.claude/commands/*.md` + upstream-vendored plugin commands)
# renders into Bash commands at execute time. When the rendered command contains an unquoted
# `$ARGUMENTS` interpolation followed by shell metacharacters, a compromised Claude session
# (prompt injection) can chain arbitrary commands. Defense-in-depth: source-level quoting
# protects pmo-authored commands (Stage 5 spec verified `account-switcher.md` is already
# quoted); this hook catches BOTH pmo AND upstream-plugin surfaces at execute time.
#
# Coverage:
#   - Script execution (*.sh, bash <path>, sh <path>, ~/.claude/*, /Users/<user>/.claude/*)
#     followed by command-chain metachar (;, |, &&, ||) leading into a command verb
#     (curl, wget, nc, ncat, scp, ssh, sh, bash, eval, python, python3, node, ruby, perl).
#   - Script execution with command substitution shape ($(...) or backtick) in argv.
#
# Out of scope (other hooks cover):
#   - Bare metachar usage without script-execution prefix (legitimate pipeline behavior)
#   - Credential reads via cat/head (block-egress.sh BLOCK-EGRESS-001/002)
#   - Network egress (block-egress.sh BLOCK-EGRESS-004..013)
#   - File deletion (block-rm-prefer-trash.sh BLOCK-TRASH-001..003)
#
# Warn-mode: reads .claude/hooks/.mode (warn|enforce|off).
#   Default state for new deploy is `warn` — 2-week (fast-path: 3-day) shakedown.
#   Operator flips to `enforce` after reviewing shell-injection-warn-log.jsonl per the
#   Shakedown → Enforce Transition Checklist in bypass-mode-readiness.md.
#
# Matcher scope: Bash
# Rule ID range: BLOCK-SHELL-INJECTION-001..099

set -euo pipefail

# --- PATH PINNING ---
export PATH="/usr/bin:/bin"

readonly GREP="/usr/bin/grep"
readonly PRINTF="/usr/bin/printf"
readonly CAT="/bin/cat"
readonly TR="/usr/bin/tr"
readonly DATE="/bin/date"
# jq is resolved below via lib/dep-resolve.sh (once HOOK_DIR is known), from a fixed
# absolute-path allowlist — never $PATH — so the anti-hijack PATH pin still holds
# (GHSA-9cjm-v22x-4x33).

# --- METADATA ---
readonly HOOK_NAME="block-shell-injection"
readonly HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"
readonly ERROR_LOG="${HOOK_DIR}/hook-errors.log"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"
readonly WARN_LOG="${HOOK_DIR}/shell-injection-warn-log.jsonl"
readonly MODE_FILE="${HOOK_DIR}/.mode"

readonly INJECTION_ALLOWLIST="${HOOK_DIR}/../shell-injection-allowlist.txt"

# --- MODE DETECTION (defined BEFORE the dependency gate so the gate's severity is
# mode-coupled and the value is resolvable without the helper) ---
get_mode() {
  local mode="warn"
  if [ -f "$MODE_FILE" ]; then
    mode="$("$CAT" "$MODE_FILE" 2>/dev/null | "$TR" -d '[:space:]' || echo warn)"
  fi
  case "$mode" in
    warn|enforce|off) "$PRINTF" '%s' "$mode" ;;
    *) "$PRINTF" 'warn' ;;  # default on unrecognized value — conservative since this hook is new
  esac
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
# Precheck syntax with `bash -n` BEFORE sourcing: a truncated/corrupt lib is a parse
# error, and sourcing a parse-error file is FATAL to this parent. Also require
# deny_missing_primitive so a valid-but-stale lib (pre-fix, no helper) trips here.
# Severity is mode-coupled: a rule match in warn/off would not block, so an unusable
# helper must not block harder than a match would.
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
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$PRINTF" '%s [%s] %s\n' "$ts" "$HOOK_NAME" "$1" >> "$ERROR_LOG" 2>/dev/null || true
}

trap 'rc=$?; log_error "RULE-EVAL-ERROR at line $LINENO (exit $rc)"; "$PRINTF" "[CLAUDE-HOOK:%s:HOOK-ERROR] BLOCKED: rule-eval error at line %s (exit %s). See %s.\n" "$HOOK_NAME" "$LINENO" "$rc" "$ERROR_LOG" >&2; exit 2' ERR

# --- READ INPUT (jq-free; stdin is consumed exactly once) ---
INPUT="$(cat)"

# --- CLAUDE_HOOK_BYPASS escape hatch — evaluated BEFORE the jq gate so it works even
# when jq is unresolvable (GHSA-9cjm-v22x-4x33 V1-F3: the old ordering placed this
# AFTER the exit-2 gate, making the escape hatch its own message advertised dead). ---
if [ "${CLAUDE_HOOK_BYPASS:-}" = "1" ]; then
  ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  if [ -n "$JQ" ]; then
    btool="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_name // empty' 2>/dev/null || echo unknown)"
    bcwd="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.cwd // empty' 2>/dev/null || echo unknown)"
    "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg tool "$btool" --arg cwd "$bcwd" \
      '{ts:$ts, hook:$hook, tool:$tool, cwd:$cwd, action:"bypass"}' >> "$BYPASS_LOG" 2>/dev/null || true
  else
    "$PRINTF" '{"ts":"%s","hook":"%s","action":"bypass","note":"jq-unresolved"}\n' "$ts" "$HOOK_NAME" >> "$BYPASS_LOG" 2>/dev/null || true
  fi
  exit 0
fi

# --- Master-activation gate (#310) — layer 2, AFTER CLAUDE_HOOK_BYPASS and BEFORE the
# .mode read. CLASS=security (D-R9): master-OFF NEVER makes this hook inert — the
# security/floor class always enforces (public-surface security is paramount; a silently
# disabled guard -> an IRREVERSIBLE leaked commit/PR). It goes inert ONLY on the operator's
# explicit, logged security_class_master_optout=true. Fail-toward-current-behavior: a
# missing lib does NOT gate. Read jq-free from the durable XDG platform-config.toml. ---
readonly MASTER_ENABLE_CLASS="security"
readonly MASTER_LIB="${HOOK_DIR}/lib/master-enable.sh"
if [ -r "$MASTER_LIB" ]; then . "$MASTER_LIB" 2>/dev/null || true; fi
if command -v master_enable_gate >/dev/null 2>&1; then master_enable_gate "$MASTER_ENABLE_CLASS"; fi

# --- DEPENDENCY GATE (mode-gated: a security control that cannot evaluate its input
# must not block HARDER than a rule match would — GHSA-9cjm-v22x-4x33). Runs AFTER the
# bypass short-circuit. In enforce mode we fail CLOSED (deny); in warn/off we degrade
# fail-open (a rule match in those modes never blocks either). .mode is read jq-free. ---
if [ -z "$JQ" ]; then
  mode="$(get_mode)"
  if [ "$mode" = "enforce" ]; then
    log_error "DEPENDENCY-MISSING: jq not found on the pinned tool path (mode=enforce)"
    deny_missing_dep jq "$HOOK_NAME" "$PRINTF"
  else
    log_error "DEPENDENCY-MISSING: jq not found — mode=$mode, DEGRADED (fail-open per warn/off posture)"
    "$PRINTF" '[CLAUDE-HOOK:%s:DEPENDENCY-WARN] jq missing — hook DEGRADED (mode=%s, fail-open).\n' "$HOOK_NAME" "$mode" >&2
    exit 0
  fi
fi

# --- VALIDATE INPUT ---
if ! "$PRINTF" '%s' "$INPUT" | "$JQ" -e . >/dev/null 2>&1; then
  log_error "INVALID-INPUT: malformed JSON"
  "$PRINTF" '[CLAUDE-HOOK:%s:INPUT-INVALID] BLOCKED: malformed hook input JSON.\n' "$HOOK_NAME" >&2
  exit 2
fi

TOOL_NAME="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_name // empty')"
CWD="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.cwd // empty')"

# --- Workspace-scope gate (#4436) — layer 3, AFTER the master-activation gate and
# BEFORE the .mode / rule path. Precedence: bypass -> master -> SCOPE -> .mode -> rule.
# Inverted fail direction on the cwd axis, NOT on the lib axis. See lib/scope-guard.sh. ---
readonly SCOPE_GUARD_LIB="${HOOK_DIR}/lib/scope-guard.sh"
if [ -r "$SCOPE_GUARD_LIB" ]; then . "$SCOPE_GUARD_LIB" 2>/dev/null || true; fi
if command -v scope_guard_gate >/dev/null 2>&1; then scope_guard_gate "$CWD"; fi

# --- BLOCK LOG HELPER ---
log_block() {
  local rule_id="$1"
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  local tool_input; tool_input="$("$PRINTF" '%s' "$INPUT" | "$JQ" -c '.tool_input // {}')"
  local input_digest; input_digest="$("$PRINTF" '%s' "$tool_input" | /usr/bin/shasum -a 256 | "$GREP" -oE '^[a-f0-9]+' | /usr/bin/head -c 16)"
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg digest "$input_digest" --arg cwd "$CWD" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, input_digest:$digest, cwd:$cwd}' \
    >> "$BLOCK_LOG" 2>/dev/null || true
}

# Append a JSONL entry to warn log with digest (no raw command in log)
log_warn() {
  local rule_id="$1"
  local reason="$2"
  local evidence="$3"  # rule-specific evidence (matched-shape digest, not raw command)
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg reason "$reason" --arg evidence "$evidence" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, reason:$reason, evidence:$evidence}' \
    >> "$WARN_LOG" 2>/dev/null || true
}

# Apply block per current mode
apply_block() {
  local rule_id="$1"
  local reason="$2"
  local override="$3"
  local evidence="${4:-}"
  local mode; mode="$(get_mode)"

  case "$mode" in
    warn)
      log_warn "$rule_id" "$reason" "$evidence"
      "$PRINTF" '[CLAUDE-HOOK:%s:%s] WARN (would-block, .mode=warn): %s\n' "$HOOK_NAME" "$rule_id" "$reason" >&2
      exit 0
      ;;
    off)
      exit 0
      ;;
    enforce|*)
      log_block "$rule_id"
      "$PRINTF" '[CLAUDE-HOOK:%s:%s] BLOCKED: %s\nOverride: %s\n' "$HOOK_NAME" "$rule_id" "$reason" "$override" >&2
      exit 2
      ;;
  esac
}

# --- HELPERS ---

# Pattern match against $COMMAND
matches() {
  "$PRINTF" '%s' "$COMMAND" | "$GREP" -qE "$1"
}

# Check the literal $COMMAND against a glob-pattern allowlist file (bash case globbing)
is_allowlisted() {
  local value="$1"
  local allowlist="$2"
  [ -f "$allowlist" ] || return 1
  local pattern
  while IFS= read -r pattern || [ -n "$pattern" ]; do
    case "$pattern" in
      ''|'#'*) continue;;
    esac
    # shellcheck disable=SC2254
    case "$value" in
      $pattern) return 0;;
    esac
  done < "$allowlist"
  return 1
}

# sha256 digest for log evidence (avoids logging raw command material)
digest() {
  "$PRINTF" '%s' "$1" | /usr/bin/shasum -a 256 | "$GREP" -oE '^[a-f0-9]+' | /usr/bin/head -c 16
}

# ==========================================================================
# BRANCH BY TOOL NAME
# ==========================================================================

case "$TOOL_NAME" in
  Bash)
    COMMAND="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.command // empty')"
    [ -z "$COMMAND" ] && exit 0

    # Allowlist short-circuit — operator-declared legitimate patterns
    if is_allowlisted "$COMMAND" "$INJECTION_ALLOWLIST"; then
      exit 0
    fi

    # ----- Script-execution + chain-metachar + command-verb shape -----

    # BLOCK-SHELL-INJECTION-001 — Script-execution token followed by chain metachar
    # leading into a command verb. The shape signature of an injection pattern is:
    #   <script-exec-token> <some-args> <chain-metachar> <command-verb> ...
    # where script-exec-tokens are: *.sh, bash <path>, sh <path>, ~/.claude/<path>,
    # /Users/<user>/.claude/<path>; chain metachars are ;, |, &&, ||; command verbs
    # are common payload-delivery commands.
    #
    # Detection: command starts with (or chains into) a script-execution token AND
    # contains, within the same chain, one of the chain metachars followed by one
    # of the watched command verbs. The script-execution prefix is the discriminator
    # that separates this from legitimate Bash pipelines (e.g., `cat file | grep foo`
    # has no script-exec prefix, so it is allowed).
    #
    # Regex shape (POSIX-ERE):
    #   (^|[;&|])[[:space:]]*           — segment start
    #   (                                — script-execution token
    #     [^[:space:];&|]+\.sh|          — *.sh path
    #     bash[[:space:]]+[^[:space:];&|]+|
    #     sh[[:space:]]+[^[:space:];&|]+|
    #     ~/\.claude/[^[:space:];&|]+|
    #     /Users/[^/]+/\.claude/[^[:space:];&|]+
    #   )
    #   [^;&|]*                          — any args (but NOT another segment boundary)
    #   (;|\|\||&&|\|)                   — chain metachar
    #   [[:space:]]*
    #   (curl|wget|nc|ncat|scp|ssh|sh|bash|eval|python|python3|node|ruby|perl)
    #   ([[:space:]]|$)                  — verb terminator
    if matches '(^|[;&|])[[:space:]]*([^[:space:];&|]+\.sh|bash[[:space:]]+[^[:space:];&|]+|sh[[:space:]]+[^[:space:];&|]+|~/\.claude/[^[:space:];&|]+|/Users/[^/]+/\.claude/[^[:space:];&|]+)[^;&|]*(;|\|\||&&|\|)[[:space:]]*(curl|wget|nc|ncat|scp|ssh|sh|bash|eval|python|python3|node|ruby|perl)([[:space:]]|$)'; then
      apply_block "BLOCK-SHELL-INJECTION-001" \
        "Script-execution followed by chain metachar leading to command verb denied — slash-command argument injection vector." \
        "if this is a legitimate pipeline, add a glob pattern to .claude/shell-injection-allowlist.txt via allowlist-add.sh, or set CLAUDE_HOOK_BYPASS=1" \
        "digest=$(digest "$COMMAND")"
    fi

    # ----- Script-execution + command substitution in argv -----

    # BLOCK-SHELL-INJECTION-002 — Script execution with command substitution ($(...) or
    # backtick) in argv. Detection: command segment starts with a script-execution token
    # AND contains $(...) or backtick within the same segment.
    #
    # Regex shape (POSIX-ERE):
    #   (^|[;&|])[[:space:]]*
    #   (
    #     [^[:space:];&|]+\.sh|
    #     bash[[:space:]]+[^[:space:];&|]+|
    #     sh[[:space:]]+[^[:space:];&|]+|
    #     ~/\.claude/[^[:space:];&|]+|
    #     /Users/[^/]+/\.claude/[^[:space:];&|]+
    #   )
    #   [^;&|]*                          — argv tokens (same segment)
    #   (\$\(|`)                          — command substitution shape
    if matches '(^|[;&|])[[:space:]]*([^[:space:];&|]+\.sh|bash[[:space:]]+[^[:space:];&|]+|sh[[:space:]]+[^[:space:];&|]+|~/\.claude/[^[:space:];&|]+|/Users/[^/]+/\.claude/[^[:space:];&|]+)[^;&|]*(\$\(|`)'; then
      apply_block "BLOCK-SHELL-INJECTION-002" \
        "Script-execution with command substitution (\$(...) or backtick) in argv denied — slash-command argument injection vector." \
        "if this is a legitimate precomputation, add a glob pattern to .claude/shell-injection-allowlist.txt via allowlist-add.sh, or set CLAUDE_HOOK_BYPASS=1" \
        "digest=$(digest "$COMMAND")"
    fi

    exit 0
    ;;

  *)
    exit 0
    ;;
esac
