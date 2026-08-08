#!/usr/bin/env bash
# block-rm-prefer-trash.sh — PreToolUse hook enforcing workspace deletion containment
# and Trash-redirect convention.
# hook-owner: core/rules/bypass-mode-readiness/block-rm-prefer-trash.md
#
# Outside ${WORKSPACE_ROOT}/, file deletion via rm/rmdir/unlink/trash/osascript
# Trash-verb is BLOCKED unconditionally. Inside the workspace, rm/rmdir/unlink is
# BLOCKED with a runtime-auto-detected Trash-equivalent suggestion (3-tier: trash in
# PATH → /opt/homebrew/opt/trash/bin/trash → osascript Finder fallback). Git
# subcommands are exempt (git history provides recoverability).
#
# Composes with (does not replace) the existing 6 PreToolUse hooks: block-destructive,
# block-egress, block-mcp-writes, block-credential-reads, block-shell-injection,
# block-fs-boundary.
#
# Matcher scope: Bash
# Rule IDs: BLOCK-TRASH-001..099
# Release: block-rm-redirect-trash

set -euo pipefail

# --- PATH PINNING (tamper resistance) ---
export PATH="/usr/bin:/bin"

# Absolute tool paths (all in /usr/bin, root-owned on macOS)
readonly GREP="/usr/bin/grep"
readonly PRINTF="/usr/bin/printf"
readonly DATE="/bin/date"
readonly SHASUM="/usr/bin/shasum"
readonly PYTHON3="/usr/bin/python3"
# jq is resolved below via lib/dep-resolve.sh (once HOOK_DIR is known), from a fixed
# absolute-path allowlist — never $PATH — so the anti-hijack PATH pin still holds
# (GHSA-9cjm-v22x-4x33).

# --- METADATA ---
readonly HOOK_NAME="block-rm-prefer-trash"
HOOK_DIR_RAW="$(cd "$(dirname "$0")" && pwd -P)"
readonly HOOK_DIR="$HOOK_DIR_RAW"
readonly ERROR_LOG="${HOOK_DIR}/hook-errors.log"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"
readonly WORKSPACE_ROOT="${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}"

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

# --- ABSOLUTE-PATH-AWARE ANCHOR ---
# Canonical anchor pattern that captures the 5 macOS/Linux absolute-path
# prefixes (/bin/, /usr/bin/, /usr/local/bin/, /opt/homebrew/bin/,
# /opt/local/bin/) PLUS the existing line-start / separator anchor in a
# single optional capture group. Backward-compatible: when the prefix
# group is absent, the regex degenerates to the original
# (^|[;&|])[[:space:]]* pattern, so every existing fixture continues to
# pass unchanged.
#
# POSIX-ERE compliant (no Perl extensions). Tested against BSD grep.
# Pattern is duplicated across the 3 regex-based PreToolUse hooks
# (block-destructive.sh, block-egress.sh, block-rm-prefer-trash.sh) —
# extracted as a per-hook constant to surface the convention and keep
# each hook file-local-self-contained per the existing posture. Future
# prefix-set additions require a coordinated 3-hook edit (see Stage 5
# spec Approach 1 trade-off discussion).
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
    # shellcheck disable=SC2016  # jq filter — single quotes intentional
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

# --- DEPENDENCY GATE (fail CLOSED: a security control that cannot evaluate its input
# must DENY, never allow — GHSA-9cjm-v22x-4x33). Runs AFTER the bypass short-circuit. ---
if [ -z "$JQ" ]; then
  log_error "DEPENDENCY-MISSING: jq not found on the pinned tool path"
  deny_missing_dep jq "$HOOK_NAME" "$PRINTF"
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
# BEFORE the rule path. Precedence: bypass -> master -> SCOPE -> .mode -> rule.
# Inverted fail direction on the cwd axis, NOT on the lib axis. See lib/scope-guard.sh. ---
readonly SCOPE_GUARD_LIB="${HOOK_DIR}/lib/scope-guard.sh"
if [ -r "$SCOPE_GUARD_LIB" ]; then . "$SCOPE_GUARD_LIB" 2>/dev/null || true; fi
if command -v scope_guard_gate >/dev/null 2>&1; then scope_guard_gate "$CWD"; fi

# --- EARLY EXIT: non-Bash tool calls ---
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

COMMAND="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.command // empty')"
[ -z "$COMMAND" ] && exit 0

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

block() {
  local rule_id="$1"; local reason="$2"; local override="$3"
  log_block "$rule_id"
  "$PRINTF" '[CLAUDE-HOOK:%s:%s] BLOCKED: %s\nOverride: %s\n' "$HOOK_NAME" "$rule_id" "$reason" "$override" >&2
  exit 2
}

# Pattern match against $COMMAND
matches() {
  local pattern="$1"
  "$PRINTF" '%s' "$COMMAND" | "$GREP" -qE "$pattern"
}

# resolve_and_classify(token)
#   Resolve a path token and classify against workspace boundary.
#   Returns: 0 = inside workspace, 1 = outside workspace, 2 = unresolvable (strict)
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

  # Step 6: prefix-match against WORKSPACE_ROOT
  case "$resolved" in
    "${WORKSPACE_ROOT}"|"${WORKSPACE_ROOT}/"*)
      "$PRINTF" '%s' "$resolved"
      return 0
      ;;
    *)
      "$PRINTF" '%s' "$resolved"
      return 1
      ;;
  esac
}

# suggest_trash_command(abs_path)
#   Emit a runtime-auto-detected Trash-equivalent command suggestion.
#   3-tier: PATH trash → keg-only path → osascript fallback.
suggest_trash_command() {
  local abs_path="$1"
  if command -v trash >/dev/null 2>&1; then
    "$PRINTF" "trash '%s'" "$abs_path"
  elif [ -x "/opt/homebrew/opt/trash/bin/trash" ]; then
    "$PRINTF" "/opt/homebrew/opt/trash/bin/trash '%s'" "$abs_path"
  else
    "$PRINTF" "osascript -e 'tell application \"Finder\" to delete POSIX file \"%s\"'" "$abs_path"
  fi
}

# extract_target_tokens(verb)
#   Tokenize $COMMAND, skip $verb itself and flag tokens (-*).
#   Emits target tokens from segments where $verb is the first token.
#   Outputs one token per line.
#
#   fix F1: split $COMMAND on separators
#   (;, &, |) first, then require $verb to be the first token of each
#   segment. Closes a bypass where a pre-verb separator (e.g.,
#   `ls && rm /tmp/foo`) aborted the loop before seen_verb was set.
#
#   fix F2: strip canonical absolute-path prefixes from the first
#   token before the verb-equality check. Required for absolute-path
#   invocations like `/bin/rm /tmp/foo` or `/usr/bin/rm foo.txt` —
#   without this, the awk-side exact match rejects the verb token even
#   when the regex-side anchor (block-rm-prefer-trash.sh Step 2)
#   correctly identifies the absolute-path verb. The two changes (regex
#   anchor + awk prefix-strip) are atomically coupled within this hook
#   file; per-segment partial revert produces silently-degraded
#   behavior (regex triggers but awk extracts no target tokens, hook
#   exits 0 instead of blocking). Land as single atomic commit.
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
          print t;
        }
      }
    }
  '
}

# ==========================================================================
# RULE EVALUATION
# ==========================================================================

# Step 1 — Broad git-subcommand exemption (Hub Decision 1)
# Per requirement #6: "git rm and other git <verb> invocations are exempt"
# Broader than the Stage 5 spoke's narrow allowlist — exempts ALL git subcommands.
# Absolute-path-aware: also exempts /usr/bin/git, /bin/git, etc.
if matches "${ANCHOR_PREFIX_BASH}"'git[[:space:]]+[^[:space:]]+'; then
  exit 0
fi

# Step 2 — Verb detection
# Detect rm/rmdir/unlink at command-start position
# Absolute-path-aware: also detects /bin/rm, /usr/bin/rm, etc.
if matches "${ANCHOR_PREFIX_BASH}"'(rm|rmdir|unlink)([[:space:]]+|$)'; then
  # Determine which verb matched (for token extraction)
  verb=""
  if matches "${ANCHOR_PREFIX_BASH}"'rm([[:space:]]+|$)'; then verb="rm"; fi
  if [ -z "$verb" ] && matches "${ANCHOR_PREFIX_BASH}"'rmdir([[:space:]]+|$)'; then verb="rmdir"; fi
  if [ -z "$verb" ] && matches "${ANCHOR_PREFIX_BASH}"'unlink([[:space:]]+|$)'; then verb="unlink"; fi

  if [ -n "$verb" ]; then
    # Iterate target tokens
    found_target=0
    while IFS= read -r token; do
      [ -z "$token" ] && continue
      found_target=1
      classification=0
      resolved="$(resolve_and_classify "$token")" || classification="$?"
      case "$classification" in
        0)
          # Inside workspace — block with Trash suggestion
          suggestion="$(suggest_trash_command "$resolved")"
          block "BLOCK-TRASH-002" \
            "permanent deletion inside workspace blocked: $resolved" \
            "use Trash instead: $suggestion (or set CLAUDE_HOOK_BYPASS=1 only if intentional)"
          ;;
        1)
          # Outside workspace — block unconditionally
          block "BLOCK-TRASH-001" \
            "deletion outside Claude/ is forbidden — cancel operation. Path: $resolved" \
            "all deletions outside ${WORKSPACE_ROOT}/ are blocked; cancel the operation, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
          ;;
        2)
          # Unresolvable under strict policy
          block "BLOCK-TRASH-001" \
            "path is unresolvable under strict policy (variable/subshell/backtick token): $token" \
            "use explicit absolute paths instead of variables/subshells, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
          ;;
      esac
    done < <(extract_target_tokens "$verb")

    # If verb matched but no target tokens were extracted (e.g., bare `rm` with no args),
    # there is nothing to delete — allow.
    if [ "$found_target" = 0 ]; then
      exit 0
    fi
  fi
fi

# Step 3 — trash invocation detection
# Absolute-path-aware: also detects /opt/homebrew/bin/trash, /usr/bin/trash, etc.
if matches "${ANCHOR_PREFIX_BASH}"'trash([[:space:]]+|$)'; then
  found_target=0
  while IFS= read -r token; do
    [ -z "$token" ] && continue
    found_target=1
    classification=0
    resolved="$(resolve_and_classify "$token")" || classification="$?"
    case "$classification" in
      0)
        # Inside workspace — approved deletion mechanism, allow
        :
        ;;
      1)
        block "BLOCK-TRASH-003" \
          "deletion outside Claude/ is forbidden — cancel operation. Path: $resolved" \
          "all deletions outside ${WORKSPACE_ROOT}/ are blocked; cancel the operation, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
        ;;
      2)
        block "BLOCK-TRASH-003" \
          "path is unresolvable under strict policy (variable/subshell/backtick token): $token" \
          "use explicit absolute paths instead of variables/subshells, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
        ;;
    esac
  done < <(extract_target_tokens "trash")
fi

# Step 4 — osascript Trash-verb detection
# Trigger only when osascript invocation contains a Trash-verb pattern
# Absolute-path-aware: also detects /usr/bin/osascript, etc.
if matches "${ANCHOR_PREFIX_BASH}"'osascript([[:space:]]+|$)'; then
  if matches 'delete[[:space:]]+POSIX[[:space:]]+file' || matches 'move[[:space:]]+.*[[:space:]]+to[[:space:]]+trash'; then
    # Extract POSIX file paths from the AppleScript source.
    # Pattern: delete POSIX file "/abs/path"
    while IFS= read -r osa_path; do
      [ -z "$osa_path" ] && continue
      classification=0
      resolved="$(resolve_and_classify "$osa_path")" || classification="$?"
      case "$classification" in
        0)
          # Inside workspace — approved deletion, allow
          :
          ;;
        1)
          block "BLOCK-TRASH-003" \
            "deletion outside Claude/ is forbidden — cancel operation. Path: $resolved" \
            "all deletions outside ${WORKSPACE_ROOT}/ are blocked; cancel the operation, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
          ;;
        2)
          block "BLOCK-TRASH-003" \
            "path is unresolvable under strict policy (variable/subshell/backtick token): $osa_path" \
            "use explicit absolute paths instead of variables/subshells, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
          ;;
      esac
    done < <("$PRINTF" '%s' "$COMMAND" | "$GREP" -oE 'POSIX[[:space:]]+file[[:space:]]+"[^"]*"' | "$GREP" -oE '"[^"]*"' | /usr/bin/sed 's/^"//; s/"$//')
  fi
fi

# No matcher-verb detected — allow
exit 0
