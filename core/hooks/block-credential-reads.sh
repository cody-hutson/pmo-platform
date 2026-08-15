#!/bin/bash
# block-credential-reads.sh — PreToolUse hook blocking Claude Read-tool access to credential-like files.
# hook-owner: core/rules/bypass-mode-readiness/block-credential-reads.md
#
# Defense-in-depth companion to block-egress.sh BLOCK-EGRESS-001/002/003 (which handles Bash
# subprocess reads). Together they ensure credentials can't leak via either the Read tool or
# `cat` / `base64` / etc. in Bash.
#
# Matcher scope: Read
# Rule IDs: BLOCK-CREDENTIAL-READ-001..010

set -euo pipefail

export PATH="/usr/bin:/bin"

readonly GREP="/usr/bin/grep"
readonly PRINTF="/usr/bin/printf"
readonly DATE="/bin/date"
readonly SHASUM="/usr/bin/shasum"
# jq is resolved below via lib/dep-resolve.sh (once HOOK_DIR is known), from a fixed
# absolute-path allowlist — never $PATH — so the anti-hijack PATH pin still holds
# (GHSA-9cjm-v22x-4x33).

readonly HOOK_NAME="block-credential-reads"
readonly HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"
readonly ERROR_LOG="${HOOK_DIR}/hook-errors.log"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"

# --- SHARED DEPENDENCY RESOLVER (fail CLOSED if the helper is missing/invalid) ---
# Two properties this guard must have that the prior shape did not (#5071, ADR-136):
#
#  1. A helper whose top level runs `exit 0` is SYNTACTICALLY VALID and terminates this
#     hook from inside the guard's own condition — before the guard can rule. `bash -n`
#     cannot see it: that is a syntax check and the syntax is fine. So the helper is
#     first evaluated OUT OF PROCESS, in a command-substitution subshell where its exit
#     kills the child and not this hook. It must ATTEST: the token below is printed by
#     THIS file, as the last term of the chain, and is therefore reachable only if
#     control RETURNED from the source. The helper's own stdout is discarded during the
#     source, so it cannot forge the token.
#  2. The real, in-process source still has to happen (the hook needs these as functions
#     in its own shell), and a helper swapped between the probe and that source could
#     still exit. The EXIT trap below is armed BEFORE it and disarmed only once the
#     contract is proven, so ANY premature termination of this region lands on deny.
#     It writes to fd 9 — a saved copy of stderr — because when a sourced file exits,
#     the `2>/dev/null` on the source is still in effect and would swallow the message.
#
# Readability is still tested BEFORE sourcing: bash 3.2 (macOS system bash) exits 1 on a
# failed `.` of a missing file even inside an `if !` condition, and exit 1 (unlike exit 2)
# is NON-blocking in the PreToolUse contract — i.e. a missing helper would fail OPEN.
#
# The expected contract value is captured `readonly` ABOVE any source: a sourced file
# cannot overwrite a readonly (ADR-130 D3 — the control is immutability, not ordering).
readonly DEP_LIB_CONTRACT="dep-resolve/v1"
exec 9>&2
DEP_GUARD_VERDICT="pending"
trap 'if [ "${DEP_GUARD_VERDICT:-pending}" = "pending" ]; then
        "$PRINTF" "[CLAUDE-HOOK:%s:LIB-MISSING] BLOCKED (fail-closed): dependency helper lib/dep-resolve.sh terminated this hook instead of satisfying the %s contract. Reinstall the hook bundle from your own terminal: bash docs/scripts/setup-workspace.sh (CLAUDE_HOOK_BYPASS does not clear this block).\n" "$HOOK_NAME" "$DEP_LIB_CONTRACT" >&9
        exit 2
      fi' EXIT

# Out-of-process contract attestation. Never sources into this shell.
dep_lib_attests() {
  [ "$( { . "$DEP_LIB" >/dev/null 2>&1 \
          && [ "${DEP_RESOLVE_CONTRACT:-}" = "$DEP_LIB_CONTRACT" ] \
          && command -v resolve_jq              >/dev/null 2>&1 \
          && command -v resolve_python3         >/dev/null 2>&1 \
          && command -v deny_missing_dep        >/dev/null 2>&1 \
          && command -v deny_missing_primitive  >/dev/null 2>&1 \
          && "$PRINTF" '%s' "$DEP_LIB_CONTRACT" ; } 2>/dev/null || true )" \
    = "$DEP_LIB_CONTRACT" ]
}
readonly -f dep_lib_attests 2>/dev/null || true

readonly DEP_LIB="${HOOK_DIR}/lib/dep-resolve.sh"
if [ ! -r "$DEP_LIB" ] \
   || ! dep_lib_attests \
   || ! . "$DEP_LIB" 2>/dev/null \
   || [ "${DEP_RESOLVE_CONTRACT:-}" != "$DEP_LIB_CONTRACT" ] \
   || ! command -v resolve_jq >/dev/null 2>&1 \
   || ! command -v deny_missing_dep >/dev/null 2>&1; then
  DEP_GUARD_VERDICT="denied"
  "$PRINTF" '[CLAUDE-HOOK:%s:LIB-MISSING] BLOCKED (fail-closed): dependency helper lib/dep-resolve.sh unavailable or invalid.\n' "$HOOK_NAME" >&2
  exit 2
fi
DEP_GUARD_VERDICT="passed"
trap - EXIT
exec 9>&-
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
# rule path. CLASS=security (D-R9): master-OFF NEVER makes this hook inert — the
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
# BEFORE the rule path. Precedence AS IMPLEMENTED IN THIS FILE:
#   dependency guard -> bypass -> master -> SCOPE -> rule
# This hook is MODE-INDEPENDENT: there is no `.mode` layer. It declares no MODE_FILE and
# reads no mode file of any name — it is one of the three always-enforce hooks, and that
# unconditional posture is the basis on which the mode-capable cohort was permitted to
# degrade (ADR-130 D4). check-hook-dep-hardening.sh CHECK-4 goes red if a mode reference
# appears in the dependency-guard block. Note also that the dependency guard is the FIRST
# gate, ahead of bypass: CLAUDE_HOOK_BYPASS cannot clear a LIB-MISSING block.
# Inverted fail direction on the cwd axis, NOT on the lib axis. See lib/scope-guard.sh. ---
readonly SCOPE_GUARD_LIB="${HOOK_DIR}/lib/scope-guard.sh"
if [ -r "$SCOPE_GUARD_LIB" ]; then . "$SCOPE_GUARD_LIB" 2>/dev/null || true; fi
if command -v scope_guard_gate >/dev/null 2>&1; then scope_guard_gate "$CWD"; fi

# --- EARLY EXIT: non-Read tool calls ---
if [ "$TOOL_NAME" != "Read" ]; then
  exit 0
fi

FILE_PATH="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.file_path // empty')"
[ -z "$FILE_PATH" ] && exit 0

# --- HELPERS ---
log_block() {
  local rule_id="$1"
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  local input_digest; input_digest="$("$PRINTF" '%s' "$FILE_PATH" | "$SHASUM" -a 256 | "$GREP" -oE '^[a-f0-9]+' | /usr/bin/head -c 16)"
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

# --- EXPLICIT ALLOWS (checked before denies) ---
# .env.example and *.pub are legitimate non-sensitive files
case "$FILE_PATH" in
  *.env.example|*.env.sample|*.env.template|*/.env.example|*/.env.sample|*/.env.template)
    exit 0
    ;;
  */id_rsa.pub|*/id_ed25519.pub|*/id_ecdsa.pub|*.pub)
    exit 0
    ;;
esac

# --- DENY RULES ---

# BLOCK-CREDENTIAL-READ-001 — SSH private keys and ~/.ssh contents
case "$FILE_PATH" in
  */.ssh/id_rsa|*/.ssh/id_ed25519|*/.ssh/id_ecdsa|*/.ssh/id_dsa)
    block "BLOCK-CREDENTIAL-READ-001" \
      "Read of SSH private key denied: $FILE_PATH" \
      "SSH private keys are never required for development; set CLAUDE_HOOK_BYPASS=1 only if intentional"
    ;;
  */.ssh/*)
    block "BLOCK-CREDENTIAL-READ-001" \
      "Read of ~/.ssh/ contents denied: $FILE_PATH" \
      "specify why you need it and set CLAUDE_HOOK_BYPASS=1, or use .pub (public key) variants"
    ;;
esac

# BLOCK-CREDENTIAL-READ-002 — AWS credentials
case "$FILE_PATH" in
  */.aws/credentials|*/.aws/config|*/.aws/*)
    block "BLOCK-CREDENTIAL-READ-002" \
      "Read of ~/.aws/ credentials denied: $FILE_PATH" \
      "set CLAUDE_HOOK_BYPASS=1 only if the read is truly required"
    ;;
esac

# BLOCK-CREDENTIAL-READ-003 — gh auth tokens
case "$FILE_PATH" in
  */.config/gh/hosts.yml|*/.config/gh/*)
    block "BLOCK-CREDENTIAL-READ-003" \
      "Read of gh auth config denied: $FILE_PATH" \
      "use 'gh auth status' (no file read) or set CLAUDE_HOOK_BYPASS=1"
    ;;
esac

# BLOCK-CREDENTIAL-READ-004 — .env variants (excluding .env.example handled above)
case "$FILE_PATH" in
  *.env|*/.env|*.env.local|*/.env.local|*.env.production|*/.env.production|*.env.dev|*/.env.dev|*.env.development|*/.env.development|*.env.staging|*/.env.staging|*.env.test|*/.env.test|*.env.testing|*/.env.testing|*.env.prod|*/.env.prod|*.env.secrets|*/.env.secrets|*.env.secret|*/.env.secret)
    block "BLOCK-CREDENTIAL-READ-004" \
      "Read of .env file denied: $FILE_PATH" \
      ".env.example / .env.sample / .env.template are allowed; for actual .env values set CLAUDE_HOOK_BYPASS=1"
    ;;
esac

# BLOCK-CREDENTIAL-READ-005 — SSH keys outside ~/.ssh (bare id_rsa-style filenames)
case "$FILE_PATH" in
  */id_rsa|*/id_ed25519|*/id_ecdsa|*/id_dsa)
    block "BLOCK-CREDENTIAL-READ-005" \
      "Read of SSH private key (any location) denied: $FILE_PATH" \
      "set CLAUDE_HOOK_BYPASS=1 only if intentional"
    ;;
esac

# BLOCK-CREDENTIAL-READ-006 — *.pem / *.key files
case "$FILE_PATH" in
  *.pem|*.key|*.p12|*.pfx|*.keystore)
    block "BLOCK-CREDENTIAL-READ-006" \
      "Read of cryptographic key file denied: $FILE_PATH" \
      "set CLAUDE_HOOK_BYPASS=1 if this is a non-sensitive cert/key"
    ;;
esac

# No match — allow
exit 0
