#!/usr/bin/env bash
# block-fs-boundary.sh — PreToolUse hook enforcing workspace-boundary scoping
# for Bash file commands beyond the Anthropic settings.deny recognized subset.
#
# Anthropic's native settings.deny `Read(...)` / `Edit(...)` rules cover the
# Read tool, the Edit/Write tools, and the recognized Bash file-command subset
# (cat / head / tail / sed per code.claude.com/docs/en/permissions). They do
# NOT cover arbitrary Bash file commands: cp / mv / tee / dd / base64 / xxd /
# od / hexdump / strings / less / more. This hook closes that residual gap.
#
# Verb classes (v1):
#   File-read:  cat, head, tail, less, more, base64, xxd, od, hexdump, strings
#   File-write: cp, mv, tee, dd
# Resolved-path prefix-match against `.claude/fs-boundary-allowlist.txt`.
# Strict-policy block on unresolvable tokens (variables / $(...) / backticks).
# Shell redirection (`>`, `>>`, `<`) deferred to v2 — accepted v1 residual per
# block-rm-prefer-trash.sh § Known Limitations precedent.
#
# Composes with (does not replace) the existing 7 PreToolUse hooks:
# block-destructive, block-egress, block-mcp-writes, block-credential-reads,
# block-shell-injection, block-rm-prefer-trash, block-skill-direct-edit.
#
# Matcher scope: Bash
# Rule IDs: BLOCK-FS-BOUNDARY-001..003
# Mode gating: shared .claude/hooks/.mode (warn / enforce / off), same file as
# block-egress + block-mcp-writes. Default initial = warn (3-day shakedown).
# Release: monolith-cleanup

set -euo pipefail

# --- PATH PINNING (tamper resistance) ---
export PATH="/usr/bin:/bin"

# Absolute tool paths (all in /usr/bin, root-owned on macOS)
readonly GREP="/usr/bin/grep"
readonly JQ="/usr/bin/jq"
readonly PRINTF="/usr/bin/printf"
readonly DATE="/bin/date"
readonly SHASUM="/usr/bin/shasum"
readonly PYTHON3="/usr/bin/python3"

# --- METADATA ---
readonly HOOK_NAME="block-fs-boundary"
HOOK_DIR_RAW="$(cd "$(dirname "$0")" && pwd -P)"
readonly HOOK_DIR="$HOOK_DIR_RAW"
CLAUDE_DIR_RAW="$(cd "${HOOK_DIR}/.." && pwd -P)"
readonly CLAUDE_DIR="$CLAUDE_DIR_RAW"
readonly ERROR_LOG="${HOOK_DIR}/hook-errors.log"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"
readonly WARN_LOG="${HOOK_DIR}/fs-boundary-warn-log.jsonl"
readonly MODE_FILE="${HOOK_DIR}/.mode"
readonly ALLOWLIST_FILE="${CLAUDE_DIR}/fs-boundary-allowlist.txt"

# --- ABSOLUTE-PATH-AWARE ANCHOR ---
# Canonical anchor pattern that captures the 5 macOS/Linux absolute-path
# prefixes (/bin/, /usr/bin/, /usr/local/bin/, /opt/homebrew/bin/,
# /opt/local/bin/) PLUS the existing line-start / separator anchor in a
# single optional capture group. Backward-compatible: when the prefix
# group is absent, the regex degenerates to the original
# (^|[;&|])[[:space:]]* pattern.
#
# POSIX-ERE compliant (no Perl extensions). Tested against BSD grep.
# Pattern is duplicated across the regex-based PreToolUse hooks
# (block-destructive.sh, block-egress.sh, block-rm-prefer-trash.sh,
# block-fs-boundary.sh) — extracted as a per-hook constant to surface
# the convention and keep each hook file-local-self-contained per the
# existing posture.
readonly ANCHOR_PREFIX_BASH='(^|[;&|])[[:space:]]*(/(usr/(local/)?|opt/(homebrew|local)/)?bin/)?'

# --- ERROR HANDLERS ---
log_error() {
  local ts
  ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$PRINTF" '%s [%s] %s\n' "$ts" "$HOOK_NAME" "$1" >> "$ERROR_LOG" 2>/dev/null || true
}

# Fail-CLOSED on rule-evaluation error (exit 2 blocks).
# rc is set inside the trap by $? — shellcheck SC2154 is a false positive here.
# shellcheck disable=SC2154
trap 'rc=$?; log_error "RULE-EVAL-ERROR at line $LINENO (exit $rc)"; "$PRINTF" "[CLAUDE-HOOK:%s:HOOK-ERROR] BLOCKED: rule-eval error at line %s (exit %s). See %s.\n" "$HOOK_NAME" "$LINENO" "$rc" "$ERROR_LOG" >&2; exit 2' ERR

# --- DEPENDENCY CHECK (jq required for JSON parsing) ---
# Fail-OPEN on missing jq with loud warning (sibling-hook convention)
if [ ! -x "$JQ" ] && ! command -v jq >/dev/null 2>&1; then
  log_error "DEPENDENCY-MISSING: jq not found"
  "$PRINTF" '[CLAUDE-HOOK:%s:DEPENDENCY-WARN] jq missing — hook DEGRADED (fail-open).\n' "$HOOK_NAME" >&2
  exit 0
fi

# --- READ & VALIDATE INPUT ---
INPUT="$(cat)"
if ! "$PRINTF" '%s' "$INPUT" | "$JQ" -e . >/dev/null 2>&1; then
  log_error "INVALID-INPUT: malformed JSON"
  "$PRINTF" '[CLAUDE-HOOK:%s:INPUT-INVALID] BLOCKED: malformed hook input JSON.\n' "$HOOK_NAME" >&2
  exit 2
fi

TOOL_NAME="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_name // empty')"
CWD="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.cwd // empty')"

# --- CLAUDE_HOOK_BYPASS escape hatch ---
if [ "${CLAUDE_HOOK_BYPASS:-}" = "1" ]; then
  ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  # shellcheck disable=SC2016  # jq filter — single quotes intentional
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg tool "$TOOL_NAME" --arg cwd "$CWD" \
    '{ts:$ts, hook:$hook, tool:$tool, cwd:$cwd, action:"bypass"}' \
    >> "$BYPASS_LOG" 2>/dev/null || true
  exit 0
fi

# --- EARLY EXIT: non-Bash tool calls ---
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

COMMAND="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.command // empty')"
[ -z "$COMMAND" ] && exit 0

# --- MODE GATING (shared .mode file with block-egress, block-mcp-writes) ---
MODE="enforce"
if [ -f "$MODE_FILE" ]; then
  MODE_RAW="$(/bin/cat "$MODE_FILE" 2>/dev/null | /usr/bin/head -n 1 | /usr/bin/tr -d '[:space:]')"
  case "$MODE_RAW" in
    warn|enforce|off) MODE="$MODE_RAW" ;;
    *) MODE="enforce" ;;
  esac
fi

# Mode = off: hook is disabled
if [ "$MODE" = "off" ]; then
  exit 0
fi

# --- HELPERS ---
log_block() {
  local rule_id="$1"
  local ts
  ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  local input_digest
  input_digest="$("$PRINTF" '%s' "$COMMAND" | "$SHASUM" -a 256 | "$GREP" -oE '^[a-f0-9]+' | /usr/bin/head -c 16)"
  # shellcheck disable=SC2016  # jq filter — single quotes intentional
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg digest "$input_digest" --arg cwd "$CWD" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, input_digest:$digest, cwd:$cwd}' \
    >> "$BLOCK_LOG" 2>/dev/null || true
}

log_warn() {
  local rule_id="$1"
  local reason="$2"
  local ts
  ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  local input_digest
  input_digest="$("$PRINTF" '%s' "$COMMAND" | "$SHASUM" -a 256 | "$GREP" -oE '^[a-f0-9]+' | /usr/bin/head -c 16)"
  # shellcheck disable=SC2016  # jq filter — single quotes intentional
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg digest "$input_digest" --arg cwd "$CWD" --arg reason "$reason" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, input_digest:$digest, cwd:$cwd, reason:$reason, action:"warn"}' \
    >> "$WARN_LOG" 2>/dev/null || true
}

block_or_warn() {
  local rule_id="$1"; local reason="$2"; local override="$3"
  if [ "$MODE" = "warn" ]; then
    log_warn "$rule_id" "$reason"
    "$PRINTF" '[CLAUDE-HOOK:%s:%s:WARN] %s\n' "$HOOK_NAME" "$rule_id" "$reason" >&2
    return 1
  fi
  log_block "$rule_id"
  "$PRINTF" '[CLAUDE-HOOK:%s:%s] BLOCKED: %s\nOverride: %s\n' "$HOOK_NAME" "$rule_id" "$reason" "$override" >&2
  exit 2
}

# Pattern match against $COMMAND
matches() {
  local pattern="$1"
  "$PRINTF" '%s' "$COMMAND" | "$GREP" -qE "$pattern"
}

# is_allowed_path(abs_path)
#   Read allowlist file and check whether $abs_path is inside any allowed root.
#   Returns: 0 = allowed, 1 = not allowed.
#   Allowlist format: one absolute path per line, # comments, blank lines skipped.
#   Tilde-prefixed entries expand to $HOME. Trailing slashes are normalized.
is_allowed_path() {
  local path="$1"
  [ -f "$ALLOWLIST_FILE" ] || return 1
  while IFS= read -r entry || [ -n "$entry" ]; do
    # Skip blank lines and comments
    case "$entry" in
      ''|\#*) continue;;
    esac
    # Trim leading/trailing whitespace
    entry="$(/usr/bin/printf '%s' "$entry" | /usr/bin/sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    [ -z "$entry" ] && continue
    # Strip inline comments after first whitespace+#
    entry="$(/usr/bin/printf '%s' "$entry" | /usr/bin/sed -E 's/[[:space:]]+#.*$//')"
    [ -z "$entry" ] && continue
    # Tilde expansion
    if [ "$entry" = "~" ]; then
      entry="${HOME}"
    elif [ "${entry:0:1}" = "~" ] && [ "${entry:1:1}" = "/" ]; then
      entry="${HOME}/${entry:2}"
    fi
    # Normalize trailing slash off entry for comparison
    entry_trim="${entry%/}"
    # Prefix-match: path = entry exactly, or path starts with entry/
    case "$path" in
      "$entry_trim"|"$entry_trim"/*) return 0;;
    esac
  done < "$ALLOWLIST_FILE"
  return 1
}

# resolve_and_classify(token)
#   Resolve a path token and classify against the allowed-roots allowlist.
#   Returns: 0 = inside allowed root, 1 = outside allowed root, 2 = unresolvable (strict)
#   Outputs the resolved absolute path on stdout (when return is 0 or 1).
resolve_and_classify() {
  local token="$1"
  local resolved=""

  # Step 1: strip surrounding single/double quotes
  case "$token" in
    \"*\") token="${token#\"}"; token="${token%\"}";;
    \'*\') token="${token#\'}"; token="${token%\'}";;
  esac

  # Step 2: detect unresolvable patterns (variables, command substitution, backticks).
  # Patterns match literal $, $(, and ` characters in the input string.
  # shellcheck disable=SC2016  # literal char matches in case glob; not expansions
  case "$token" in
    *\$\(*) return 2;;
    *\`*)   return 2;;
    *\$*)   return 2;;
  esac

  # Step 3: tilde expansion (~ or ~/...). Per-character checks avoid the
  # SC2088 false positive on the literal "~/" prefix string.
  if [ "$token" = "~" ]; then
    token="${HOME}"
  elif [ "${token:0:1}" = "~" ] && [ "${token:1:1}" = "/" ]; then
    token="${HOME}/${token:2}"
  fi

  # Step 4: absolute vs cwd-relative
  case "$token" in
    /*) resolved="$token";;
    *)
      if [ -z "$CWD" ]; then
        # No cwd available — treat as unresolvable
        return 2
      fi
      resolved="${CWD}/${token}"
      ;;
  esac

  # Step 5: normalize via Python os.path.realpath — collapses ../ and ./,
  # does not require existence, follows symlinks (intentional for strict-
  # boundary enforcement). Python 3.9+ is system-default on macOS 12+.
  # Stage 5 spec referenced /usr/bin/realpath -m (GNU); macOS ships BSD
  # realpath without -m, so Python 3 is the portable equivalent.
  if [ -x "$PYTHON3" ]; then
    resolved="$("$PYTHON3" -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$resolved" 2>/dev/null || echo "$resolved")"
  fi

  # Step 6: check resolved path against allowlist
  if is_allowed_path "$resolved"; then
    "$PRINTF" '%s' "$resolved"
    return 0
  fi
  "$PRINTF" '%s' "$resolved"
  return 1
}

# extract_target_tokens(verb)
#   Tokenize $COMMAND, skip $verb itself and flag tokens (-*).
#   Emits target tokens from segments where $verb is the first token.
#   Outputs one token per line.
#
#   Same algorithm as block-rm-prefer-trash.sh extract_target_tokens()
#   (chained-command F1 split + absolute-path-prefix strip).
extract_target_tokens() {
  local verb="$1"
  "$PRINTF" '%s' "$COMMAND" | /usr/bin/awk -v v="$verb" '
    {
      # Split on command separators first; each segment is separator-free.
      n = split($0, segments, /[;&|]+/);
      for (s = 1; s <= n; s++) {
        m = split(segments[s], tokens, /[[:space:]]+/);
        first = 0;
        for (i = 1; i <= m; i++) {
          if (tokens[i] != "") { first = i; break; }
        }
        if (first == 0) continue;
        # Strip canonical absolute-path prefix from first token before
        # verb-equality check. Matches the 5 macOS/Linux paths
        # captured by ANCHOR_PREFIX_BASH at the regex-anchor site.
        first_token = tokens[first];
        sub(/^\/(usr\/(local\/)?|opt\/(homebrew|local)\/)?bin\//, "", first_token);
        if (first_token != v) continue;
        for (i = first + 1; i <= m; i++) {
          t = tokens[i];
          if (t == "") continue;
          # Skip flags (start with -) and -- separator
          if (substr(t, 1, 1) == "-") continue;
          # Strip leading dd-style key= prefix for if=, of=, conv=, status=,
          # etc. — the path token follows the equals sign. Required for
          # `dd of=/path/to/file` form (not positional).
          sub(/^(if|of|conv|status|bs|count|seek|skip|iflag|oflag)=/, "", t);
          if (t == "") continue;
          print t;
        }
      }
    }
  '
}

# check_verb(verb, rule_id_class)
#   Run the verb-detection + per-token classification loop.
#   rule_id_class: "READ" → BLOCK-FS-BOUNDARY-001 / -003
#                  "WRITE" → BLOCK-FS-BOUNDARY-002 / -003
#   Returns: 0 always (block_or_warn exits on enforce-mode block; warn-mode returns)
check_verb() {
  local verb="$1"; local class="$2"
  local outside_rule
  local strict_rule
  case "$class" in
    READ)  outside_rule="BLOCK-FS-BOUNDARY-001"; strict_rule="BLOCK-FS-BOUNDARY-003";;
    WRITE) outside_rule="BLOCK-FS-BOUNDARY-002"; strict_rule="BLOCK-FS-BOUNDARY-003";;
    *)     outside_rule="BLOCK-FS-BOUNDARY-001"; strict_rule="BLOCK-FS-BOUNDARY-003";;
  esac

  # Detect verb at command-start position (absolute-path-aware)
  if ! matches "${ANCHOR_PREFIX_BASH}${verb}([[:space:]]+|$)"; then
    return 0
  fi

  while IFS= read -r token; do
    [ -z "$token" ] && continue
    local classification=0
    local resolved
    resolved="$(resolve_and_classify "$token")" || classification="$?"
    case "$classification" in
      0)
        # Inside allowed root — pass
        :
        ;;
      1)
        block_or_warn "$outside_rule" \
          "${verb} target outside workspace-boundary allowed roots: $resolved" \
          "(a) extend .claude/fs-boundary-allowlist.txt via allowlist-add.sh if root is legitimate, (b) use a path within an allowed root, (c) set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional" || true
        ;;
      2)
        block_or_warn "$strict_rule" \
          "${verb} target unresolvable under strict policy (variable/subshell/backtick token): $token" \
          "use explicit absolute paths instead of variables/subshells, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional" || true
        ;;
    esac
  done < <(extract_target_tokens "$verb")
}

# ==========================================================================
# RULE EVALUATION
# ==========================================================================

# File-read verb class — BLOCK-FS-BOUNDARY-001 (or -003 if unresolvable)
for verb in cat head tail less more base64 xxd od hexdump strings; do
  check_verb "$verb" READ
done

# File-write verb class — BLOCK-FS-BOUNDARY-002 (or -003 if unresolvable)
# For cp/mv: both source AND target may resolve outside; extract_target_tokens
# yields all positional args, both are checked uniformly.
# For tee/dd: target matters for write-leak.
for verb in cp mv tee dd; do
  check_verb "$verb" WRITE
done

# No matcher-verb detected — allow
exit 0
