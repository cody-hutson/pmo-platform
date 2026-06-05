#!/bin/bash
# block-egress.sh — PreToolUse hook blocking network egress / data-exfiltration channels
#
# Closes Red Team C2 (Critical): the credential-read deny only covers Claude's Read tool;
# Bash subprocesses (cat, curl, gh gist, nc, scp) bypass it entirely.
#
# Coverage:
#   - Subprocess credential reads (cat/head/tail/base64 on ~/.ssh, ~/.aws, *.env, *.pem, *.key)
#   - Network upload channels (curl POST, wget --post-*, gh gist, gh api POST)
#   - Raw network tools (nc, ncat, scp, rsync, ssh) with allowlists
#   - WebFetch domain allowlist
#
# Warn-mode: reads .claude/hooks/.mode (warn|enforce|off).
#   Default state for new deploy is `warn` — 2-week (fast-path: 3-day) shakedown.
#   User flips to `enforce` after reviewing egress-warn-log.jsonl.
#
# Matcher scope: Bash, WebFetch
# Rule ID range: BLOCK-EGRESS-001..099
#
# Part of: the bypass-permissions-readiness hardening.

set -euo pipefail

# --- PATH PINNING ---
export PATH="/usr/bin:/bin"

readonly GREP="/usr/bin/grep"
readonly JQ="/usr/bin/jq"
readonly PRINTF="/usr/bin/printf"
readonly CAT="/bin/cat"
readonly TR="/usr/bin/tr"
readonly DATE="/bin/date"

# --- METADATA ---
readonly HOOK_NAME="block-egress"
readonly HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"
readonly ERROR_LOG="${HOOK_DIR}/hook-errors.log"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"
readonly WARN_LOG="${HOOK_DIR}/egress-warn-log.jsonl"
readonly MODE_FILE="${HOOK_DIR}/.mode"

readonly EGRESS_ALLOWLIST="${HOOK_DIR}/../egress-allowlist.txt"
readonly WEBFETCH_ALLOWLIST="${HOOK_DIR}/../webfetch-allowlist.txt"
readonly SSH_ALLOWLIST="${HOOK_DIR}/../ssh-allowlist.txt"

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
# each hook file-local-self-contained per the existing posture.
# WebFetch-branch rules (BLOCK-EGRESS-012, BLOCK-EGRESS-013) are
# tool-name-matched (not verb-anchored) and not affected by this hook.
readonly ANCHOR_PREFIX_BASH='(^|[;&|])[[:space:]]*(/(usr/(local/)?|opt/(homebrew|local)/)?bin/)?'

# --- ERROR HANDLERS ---
log_error() {
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$PRINTF" '%s [%s] %s\n' "$ts" "$HOOK_NAME" "$1" >> "$ERROR_LOG" 2>/dev/null || true
}

trap 'rc=$?; log_error "RULE-EVAL-ERROR at line $LINENO (exit $rc)"; "$PRINTF" "[CLAUDE-HOOK:%s:HOOK-ERROR] BLOCKED: rule-eval error at line %s (exit %s). See %s.\n" "$HOOK_NAME" "$LINENO" "$rc" "$ERROR_LOG" >&2; exit 2' ERR

# --- DEPENDENCY CHECK (fail-OPEN on missing jq; fail-CLOSED on rule error) ---
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

# --- CLAUDE_HOOK_BYPASS escape hatch (NEW-E D8) ---
if [ "${CLAUDE_HOOK_BYPASS:-}" = "1" ]; then
  ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg tool "$TOOL_NAME" --arg cwd "$CWD" \
    '{ts:$ts, hook:$hook, tool:$tool, cwd:$cwd, action:"bypass"}' \
    >> "$BYPASS_LOG" 2>/dev/null || true
  exit 0
fi

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

# --- MODE DETECTION ---
get_mode() {
  local mode="enforce"
  if [ -f "$MODE_FILE" ]; then
    mode="$("$CAT" "$MODE_FILE" 2>/dev/null | "$TR" -d '[:space:]' || echo enforce)"
  fi
  case "$mode" in
    warn|enforce|off) "$PRINTF" '%s' "$mode" ;;
    *) "$PRINTF" 'enforce' ;;  # default on unrecognized value
  esac
}

# Append a JSONL entry to warn log with digest (no raw secrets in log)
log_warn() {
  local rule_id="$1"
  local reason="$2"
  local evidence="$3"  # tool-specific evidence (command digest, URL, etc.) — may contain digest, NOT raw
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

# Check a value against a glob-pattern allowlist file (bash case globbing)
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

# Extract host from a URL (scheme://host/... → host)
extract_host() {
  "$PRINTF" '%s' "$1" | "$GREP" -oE '^https?://[^/:]+' | "$GREP" -oE '[^/:]+$' || "$PRINTF" ''
}

# sha256 digest for log evidence (avoids logging raw secret material)
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

    # ----- Subprocess credential reads -----

    # BLOCK-EGRESS-001 — cat / head / tail / less / more on ~/.ssh, ~/.aws, ~/.config/gh
    # Absolute-path-aware: also detects /bin/cat ~/.ssh/id_rsa, /usr/bin/head, etc.
    if matches "${ANCHOR_PREFIX_BASH}"'(cat|head|tail|less|more|bat|view)[[:space:]]+([^;&|]*[[:space:]])?(~/\.ssh|~/\.aws|~/\.config/gh|/Users/[^/]+/\.ssh|/Users/[^/]+/\.aws|/Users/[^/]+/\.config/gh|\$HOME/\.ssh|\$HOME/\.aws)'; then
      apply_block "BLOCK-EGRESS-001" \
        "Subprocess read of credential directory (~/.ssh, ~/.aws, ~/.config/gh) denied — exfil risk." \
        "if you truly need these files, use Read via Claude (still blocked by NEW-E Read deny) or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-EGRESS-002 — read of .env / id_rsa / *.pem / *.key files
    # .env variants blocked: bare .env, .env.{local,production,dev,development,staging,test,testing,prod,secrets,secret}
    # Explicit allow: .env.example (common template, non-sensitive)
    # SSH private keys blocked bare (id_rsa), NOT .pub (public key is safe)
    # Absolute-path-aware.
    if matches "${ANCHOR_PREFIX_BASH}"'(cat|head|tail|less|more|bat|view|base64)[[:space:]]+([^;&|]*[[:space:]])?[^[:space:];&|]*(\.env|\.env\.(local|production|dev|development|staging|test|testing|prod|secrets|secret)|/id_rsa|/id_ed25519|/id_ecdsa|\.pem|\.key)([[:space:]]|$)'; then
      apply_block "BLOCK-EGRESS-002" \
        "Subprocess read of secret-like file denied (.env[.local/production/etc], id_rsa, *.pem, *.key)." \
        ".env.example and *.pub are explicitly allowed. Set CLAUDE_HOOK_BYPASS=1 only if intentional"
    fi

    # BLOCK-EGRESS-003 — base64 encoding of credential paths (common exfil wrapper)
    # Absolute-path-aware.
    if matches "${ANCHOR_PREFIX_BASH}"'base64[[:space:]]+([^;&|]*[[:space:]])?(~/\.ssh|~/\.aws|/Users/[^/]+/\.ssh|/Users/[^/]+/\.aws|\$HOME/\.ssh|\$HOME/\.aws)'; then
      apply_block "BLOCK-EGRESS-003" \
        "base64 encoding of credential directory denied (classic exfil preparation)." \
        "set CLAUDE_HOOK_BYPASS=1 if intentional"
    fi

    # ----- Network upload channels -----

    # BLOCK-EGRESS-004 — curl POST / data-upload flags to non-allowlisted host
    # Absolute-path-aware.
    if matches "${ANCHOR_PREFIX_BASH}"'curl[[:space:]]+[^;&|]*(-X[[:space:]]+POST|-X[[:space:]]+PUT|-X[[:space:]]+PATCH|-d[[:space:]]|--data|-F[[:space:]]|-T[[:space:]]|--upload-file|--data-binary|--data-raw|--data-urlencode)'; then
      # Extract target URL
      target_url="$("$PRINTF" '%s' "$COMMAND" | "$GREP" -oE 'https?://[^[:space:]"'"'"';&|]+' | /usr/bin/head -1 || "$PRINTF" '')"
      target_host="$(extract_host "${target_url:-}")"
      if [ -z "$target_host" ] || ! is_allowlisted "$target_host" "$EGRESS_ALLOWLIST"; then
        apply_block "BLOCK-EGRESS-004" \
          "curl POST/PUT/upload to non-allowlisted host denied (target: ${target_host:-unknown})." \
          "add host to .claude/egress-allowlist.txt via allowlist-add.sh, or set CLAUDE_HOOK_BYPASS=1" \
          "host=${target_host:-unknown} digest=$(digest "${target_url:-}")"
      fi
    fi

    # BLOCK-EGRESS-005 — wget --post-data / --post-file (unconditional)
    # Absolute-path-aware: also detects /opt/homebrew/bin/wget --post-data, etc.
    if matches "${ANCHOR_PREFIX_BASH}"'wget[[:space:]]+[^;&|]*(--post-data|--post-file|--body-data|--body-file)'; then
      apply_block "BLOCK-EGRESS-005" \
        "wget --post-data/--post-file denied (no allowlist for wget uploads)." \
        "use curl (allowlist-governed) or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-EGRESS-006 — gh gist create (unconditional; public-share vector)
    # Absolute-path-aware.
    if matches "${ANCHOR_PREFIX_BASH}"'gh[[:space:]]+gist[[:space:]]+create([[:space:]]|$)'; then
      apply_block "BLOCK-EGRESS-006" \
        "gh gist create denied (public-share vector with no allowlist)." \
        "upload via repo PR/issue (allowlisted) or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-EGRESS-007 — gh api POST/PUT/PATCH/DELETE to non-allowlisted API path
    # Absolute-path-aware.
    if matches "${ANCHOR_PREFIX_BASH}"'gh[[:space:]]+api[[:space:]]+[^;&|]*(-X[[:space:]]+(POST|PUT|PATCH|DELETE)|--method[[:space:]]+(POST|PUT|PATCH|DELETE))'; then
      # Extract API path (first arg after "gh api")
      api_path="$("$PRINTF" '%s' "$COMMAND" | "$GREP" -oE 'gh[[:space:]]+api[[:space:]]+[^[:space:];&|]+' | /usr/bin/head -1 | "$GREP" -oE '[^[:space:]]+$' || "$PRINTF" '')"
      if [ -z "$api_path" ] || ! is_allowlisted "$api_path" "$EGRESS_ALLOWLIST"; then
        apply_block "BLOCK-EGRESS-007" \
          "gh api write to non-allowlisted path denied (path: ${api_path:-unknown})." \
          "add path to .claude/egress-allowlist.txt, or set CLAUDE_HOOK_BYPASS=1" \
          "path=${api_path:-unknown}"
      fi
    fi

    # ----- Raw network tools -----

    # BLOCK-EGRESS-008 — nc / ncat (unconditional)
    # Absolute-path-aware: also detects /usr/local/bin/nc, etc.
    if matches "${ANCHOR_PREFIX_BASH}"'(nc|ncat)([[:space:]]|$)'; then
      apply_block "BLOCK-EGRESS-008" \
        "nc / ncat denied (raw TCP is a direct exfil channel)." \
        "set CLAUDE_HOOK_BYPASS=1 if truly needed"
    fi

    # BLOCK-EGRESS-009 — scp to remote target
    # Absolute-path-aware.
    if matches "${ANCHOR_PREFIX_BASH}"'scp[[:space:]]+[^;&|]*[a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+:'; then
      apply_block "BLOCK-EGRESS-009" \
        "scp to remote host denied (data-exfil vector)." \
        "set CLAUDE_HOOK_BYPASS=1 if intentional"
    fi

    # BLOCK-EGRESS-010 — rsync with remote target (user@host: syntax)
    # Absolute-path-aware.
    if matches "${ANCHOR_PREFIX_BASH}"'rsync[[:space:]]+[^;&|]*[a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+:'; then
      apply_block "BLOCK-EGRESS-010" \
        "rsync to remote host denied (data-exfil vector)." \
        "set CLAUDE_HOOK_BYPASS=1 if intentional"
    fi

    # BLOCK-EGRESS-011 — ssh to non-allowlisted host
    # Absolute-path-aware.
    if matches "${ANCHOR_PREFIX_BASH}"'ssh[[:space:]]+'; then
      # Extract the host (first non-flag arg)
      ssh_host="$("$PRINTF" '%s' "$COMMAND" | "$GREP" -oE 'ssh[[:space:]]+([^[:space:]]+[[:space:]]+)*[a-zA-Z0-9._@-]+([[:space:]]|$)' | /usr/bin/head -1 | "$GREP" -oE '[a-zA-Z0-9._@-]+[[:space:]]*$' | "$TR" -d '[:space:]' || "$PRINTF" '')"
      if [ -z "$ssh_host" ] || ! is_allowlisted "$ssh_host" "$SSH_ALLOWLIST"; then
        apply_block "BLOCK-EGRESS-011" \
          "ssh to non-allowlisted host denied (host: ${ssh_host:-unknown})." \
          "add host to .claude/ssh-allowlist.txt, or set CLAUDE_HOOK_BYPASS=1" \
          "host=${ssh_host:-unknown}"
      fi
    fi

    exit 0
    ;;

  WebFetch)
    URL="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.url // empty')"
    [ -z "$URL" ] && exit 0

    # BLOCK-EGRESS-012 — file:// and localhost / 127.0.0.1 URLs
    case "$URL" in
      file://*)
        apply_block "BLOCK-EGRESS-012" \
          "WebFetch to file:// URL denied (local file exfil via URL param)." \
          "use Read tool to access local files, or set CLAUDE_HOOK_BYPASS=1"
        ;;
      http://localhost*|http://127.0.0.1*|https://localhost*|https://127.0.0.1*|http://0.0.0.0*)
        apply_block "BLOCK-EGRESS-012" \
          "WebFetch to localhost / loopback denied (internal services bypass)." \
          "use direct tool calls for local services, or set CLAUDE_HOOK_BYPASS=1"
        ;;
    esac

    # BLOCK-EGRESS-013 — WebFetch to non-allowlisted domain
    webfetch_host="$(extract_host "$URL")"
    if [ -z "$webfetch_host" ] || ! is_allowlisted "$webfetch_host" "$WEBFETCH_ALLOWLIST"; then
      apply_block "BLOCK-EGRESS-013" \
        "WebFetch to non-allowlisted domain denied (domain: ${webfetch_host:-unknown})." \
        "add domain to .claude/webfetch-allowlist.txt, or set CLAUDE_HOOK_BYPASS=1" \
        "host=${webfetch_host:-unknown}"
    fi

    exit 0
    ;;

  *)
    exit 0
    ;;
esac
