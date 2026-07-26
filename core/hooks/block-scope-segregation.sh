#!/usr/bin/env bash
# block-scope-segregation.sh — PreToolUse hook: refuse to file PII / private-marked
# content to a scope:public work-tracker destination (#384).
# hook-owner: core/rules/bypass-mode-readiness/block-scope-segregation.md
#
# WHAT IT DOES (destination-sensitivity content gate — payload-triggered, per the
# ADR-031 precedent; NOT session-detection):
#   Fires on tracker-FILING verbs (Bash `gh issue create` / `gh api … issues` /
#   `gh issue|pr comment` / `gh project item-*`; MCP filing write-verbs). Resolves
#   the filing DESTINATION → its `scope` from operator.toml `[trackers.<id>]`, then:
#     scope:private          → ALLOW (PII is permitted on a private destination).
#     scope:public           → CONTENT SCAN (reused PII substrate). A non-exempt
#                              needle → BLOCK.
#     unmapped + trackers configured → FAIL CLOSED (CD-1). The operator opted into
#                              segregation; an unmapped filing target is unsafe by
#                              default (do NOT silently allow toward public).
#     unmapped + NO trackers configured → ALLOW (back-compat single-stream; the
#                              operator has not opted into multi-destination).
#
# ENFORCEMENT POSTURE (fail-closed, per the #3877 A6.5 adversarial review — the
# original design failed OPEN; these three amendments are load-bearing):
#   CD-1  Fail-closed routing default. A private-scope project with an unset
#         work_tracker must NOT resolve to the public destination. The primary
#         fix is the intake-desk routing read path; the hook's contribution is the
#         unmapped-destination fail-closed default above (mode-gated warn-first).
#   CD-2  Tiered ALWAYS-BLOCK. A high-confidence identity/private needle → a
#         scope:public destination is blocked regardless of mode (warn/off/enforce)
#         — mirroring git-pre-commit-pii.sh (unconditional exit on a real match)
#         and block-autonomy-ceiling.sh (always_block). Warn-mode-first applies
#         ONLY to the fuzzy / destination-resolution layer (CD-1 unmapped, CD-3
#         empty-extraction). The allowlist + CLAUDE_HOOK_BYPASS remain the escapes.
#   CD-3  Fail-closed content-extraction. On the mapped-public branch, an empty /
#         unparseable content extraction fails closed (would-block in warn, block
#         in enforce) — UNLIKE block-gh-path-leak.sh's fail-open-on-empty (:170).
#         On the MCP surface (Jira ADF description, Smartsheet cell values, Linear
#         description) empty-extraction is the common case, not the edge case.
#
# DETECTOR REUSE (honors the AC#3 "reuse the existing PII surface" mandate — no
#   new detector). Inline-reuse variant (DD-4 fallback — avoids regressing the
#   shipped git-pre-commit-pii.sh this release; extracting a shared
#   pii-needle-patterns.sh both hooks source is a flagged fast-follow):
#     - home-path + bare-instance leaks : core/deploy/tools/path-leak-patterns.sh
#                                         (path_leak_scan_line — already shared).
#     - phone + personal-email regexes  : the two generic PATTERNS from
#                                         git-pre-commit-pii.sh (patterns, not PII).
#     - coworker / org / client-project : the gitignored operator-instance needle
#       needles                           file via lib-instance-path.sh
#                                         (pmo_localized_needles). CD-4 extends this
#                                         surface with a private-PROJECT needle class.
#   NO real PII is hardcoded in this tracked file — only detection patterns + a
#   pointer to the gitignored needle file.
#
# Matcher scope: Bash, mcp__.*  (filing surfaces only). Registered LAST per matcher
#   (safety barriers evaluate first). Fires on every Bash/MCP call → the filing-verb
#   early-exit is load-bearing.
# Rule IDs: BLOCK-SCOPE-SEG-001..099
# Mode gating: own .scope-segregation-mode (warn / enforce / off). Initial = warn.
#   The ENFORCE flip for the fuzzy layer is a SEPARATE operator gate, NOT this
#   release's default; CD-2's always-block tier fires even in warn mode.
# Release: v3.91 (cross-platform-install-experience)

set -euo pipefail

# --- PATH PINNING (tamper resistance) ---
export PATH="/usr/bin:/bin"

readonly GREP="/usr/bin/grep"
readonly PRINTF="/usr/bin/printf"
readonly CAT="/bin/cat"
readonly TR="/usr/bin/tr"
readonly DATE="/bin/date"
readonly SHASUM="/usr/bin/shasum"
readonly AWK="/usr/bin/awk"
readonly SED="/usr/bin/sed"
readonly HEAD="/usr/bin/head"
# jq is resolved below via lib/dep-resolve.sh (once HOOK_DIR is known), from a fixed
# absolute-path allowlist — never $PATH — so the anti-hijack PATH pin still holds
# (GHSA-9cjm-v22x-4x33).

# --- METADATA ---
readonly HOOK_NAME="block-scope-segregation"
HOOK_DIR_RAW="$(cd "$(dirname "$0")" && pwd -P)"
readonly HOOK_DIR="$HOOK_DIR_RAW"
readonly ERROR_LOG="${HOOK_DIR}/hook-errors.log"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"
readonly WARN_LOG="${HOOK_DIR}/scope-segregation-warn-log.jsonl"
readonly MODE_FILE="${HOOK_DIR}/.scope-segregation-mode"
readonly ALLOWLIST="${HOOK_DIR}/../scope-segregation-allowlist.txt"

# Runtime operator config (the notify-version-skew.sh / block-autonomy-ceiling.sh
# runtime-read convention; XDG config dir). HOME-relative so a sandboxed HOME (the
# test harness) redirects it deterministically.
readonly OPERATOR_TOML="${HOME}/.config/pmo-platform/operator.toml"

# --- SHARED DEPENDENCY RESOLVER (fail CLOSED if the helper is missing/invalid — a
# security hook that cannot resolve its dependencies must not run degraded). Test
# readability BEFORE sourcing: bash 3.2 (macOS system bash) exits 1 on a failed `.`
# of a missing file even inside an `if !` condition, and exit 1 (unlike exit 2) is
# NON-blocking in the PreToolUse contract — a missing helper would fail OPEN. ---
readonly DEP_LIB="${HOOK_DIR}/lib/dep-resolve.sh"
# shellcheck source=lib/dep-resolve.sh disable=SC1090,SC1091
if [ ! -r "$DEP_LIB" ] || ! "${BASH:-/bin/bash}" -n "$DEP_LIB" 2>/dev/null || ! . "$DEP_LIB" 2>/dev/null || ! command -v resolve_jq >/dev/null 2>&1; then
  "$PRINTF" '[CLAUDE-HOOK:%s:LIB-MISSING] BLOCKED (fail-closed): dependency helper lib/dep-resolve.sh unavailable or invalid.\n' "$HOOK_NAME" >&2
  exit 2
fi
JQ="$(resolve_jq)"; readonly JQ

# Shared path-leak primitive — co-located first (deployed .claude/hooks/ layout),
# then the repo/source layout (core/hooks/../deploy/tools/). Both yield
# path_leak_scan_line. Sourced lazily on the mapped-public branch (below) so an
# absent primitive never blocks unrelated Bash.
PRIMITIVE="${HOOK_DIR}/path-leak-patterns.sh"
[ -f "$PRIMITIVE" ] || PRIMITIVE="${HOOK_DIR}/../deploy/tools/path-leak-patterns.sh"
readonly PRIMITIVE

# Localized-needle resolver — co-located first (deployed layout co-ships it), then
# the source layout. Yields pmo_localized_needles.
NEEDLE_LIB="${HOOK_DIR}/lib-instance-path.sh"
[ -f "$NEEDLE_LIB" ] || NEEDLE_LIB="${HOOK_DIR}/../deploy/lib-instance-path.sh"
readonly NEEDLE_LIB

# --- ERROR HANDLERS ---
log_error() {
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$PRINTF" '%s [%s] %s\n' "$ts" "$HOOK_NAME" "$1" >> "$ERROR_LOG" 2>/dev/null || true
}

# Fail-CLOSED on rule-evaluation error (exit 2 blocks) — a security control that
# errors must not fail open. Mirrors block-autonomy-ceiling.sh's ERR posture.
# shellcheck disable=SC2154
trap 'rc=$?; log_error "RULE-EVAL-ERROR at line $LINENO (exit $rc)"; "$PRINTF" "[CLAUDE-HOOK:%s:HOOK-ERROR] BLOCKED: rule-eval error at line %s (exit %s). See %s.\n" "$HOOK_NAME" "$LINENO" "$rc" "$ERROR_LOG" >&2; exit 2' ERR

# --- MODE DETECTION (own .scope-segregation-mode; default warn) — defined before
# the dependency gate so a missing-jq decision can be mode-aware. ---
get_mode() {
  local mode="warn"
  if [ -f "$MODE_FILE" ]; then
    mode="$("$CAT" "$MODE_FILE" 2>/dev/null | "$TR" -d '[:space:]' || echo warn)"
  fi
  case "$mode" in
    warn|enforce|off) "$PRINTF" '%s' "$mode" ;;
    *) "$PRINTF" 'warn' ;;
  esac
}

# --- READ INPUT (jq-free; stdin is consumed exactly once) ---
INPUT="$(cat)"

# --- CLAUDE_HOOK_BYPASS escape hatch — evaluated BEFORE the jq gate so it works even
# when jq is unresolvable (GHSA-9cjm-v22x-4x33). Anti-injection protected mid-session
# by block-destructive.sh BLOCK-DESTRUCTIVE-023. ---
if [ "${CLAUDE_HOOK_BYPASS:-}" = "1" ]; then
  ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  if [ -n "$JQ" ]; then
    btool="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_name // empty' 2>/dev/null || echo unknown)"
    # shellcheck disable=SC2016
    "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg tool "$btool" \
      '{ts:$ts, hook:$hook, tool:$tool, action:"bypass"}' >> "$BYPASS_LOG" 2>/dev/null || true
  else
    "$PRINTF" '{"ts":"%s","hook":"%s","action":"bypass","note":"jq-unresolved"}\n' "$ts" "$HOOK_NAME" >> "$BYPASS_LOG" 2>/dev/null || true
  fi
  exit 0
fi

# --- Master-activation gate (#310) — layer 2, AFTER CLAUDE_HOOK_BYPASS and BEFORE the
# .scope-segregation-mode read. CLASS=security (D-R9): master-OFF NEVER makes this hook
# inert — the security/floor class always enforces (public-surface security is paramount;
# a silently disabled public-PII->public-destination guard -> an IRREVERSIBLE leak). It
# goes inert ONLY on the operator's explicit, logged security_class_master_optout=true.
# Fail-toward-current-behavior: a missing lib does NOT gate. Read jq-free from the XDG config. ---
readonly MASTER_ENABLE_CLASS="security"
readonly MASTER_LIB="${HOOK_DIR}/lib/master-enable.sh"
if [ -r "$MASTER_LIB" ]; then . "$MASTER_LIB" 2>/dev/null || true; fi
if command -v master_enable_gate >/dev/null 2>&1; then master_enable_gate "$MASTER_ENABLE_CLASS"; fi

# --- DEPENDENCY GATE (mode-aware fail-closed — GHSA-9cjm-v22x-4x33). A control that
# cannot parse its input must not block SOFTER than a rule match would: enforce fails
# CLOSED (exit 2); warn/off degrade to a non-blocking note (a warn-mode match itself
# never blocks). Runs AFTER the bypass short-circuit + mode read. ---
if [ -z "$JQ" ]; then
  log_error "DEPENDENCY-MISSING: jq not found on the pinned tool path"
  _jqmiss_mode="$(get_mode)"
  if [ "$_jqmiss_mode" = "enforce" ]; then
    deny_missing_dep jq "$HOOK_NAME" "$PRINTF"
    exit 2   # caller owns the fail-closed exit (GHSA-g9g6) — never trust the callee to terminate
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:DEPENDENCY-DEGRADED] WARN (degraded, .scope-segregation-mode=%s): jq not found; scope-segregation scan skipped.\n' "$HOOK_NAME" "$_jqmiss_mode" >&2
  exit 0
fi

# --- VALIDATE INPUT ---
if ! "$PRINTF" '%s' "$INPUT" | "$JQ" -e . >/dev/null 2>&1; then
  log_error "INVALID-INPUT: malformed JSON"
  "$PRINTF" '[CLAUDE-HOOK:%s:INPUT-INVALID] BLOCKED: malformed hook input JSON.\n' "$HOOK_NAME" >&2
  exit 2
fi

TOOL_NAME="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_name // empty')"

# --- EARLY EXIT: out-of-scope tool calls (fires on every Bash/MCP call) ---
case "$TOOL_NAME" in
  Bash) ;;      # gh filing surface — evaluate
  mcp__*) ;;    # MCP filing surface — evaluate
  *) exit 0 ;;  # anything else — allow
esac

# --- LOGGING HELPERS ---
digest() {
  "$PRINTF" '%s' "$1" | "$SHASUM" -a 256 | "$GREP" -oE '^[a-f0-9]+' | "$HEAD" -c 16
}

log_warn() {
  local rule_id="$1"; local reason="$2"; local evidence_digest="$3"
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  # shellcheck disable=SC2016
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg reason "$reason" --arg evidence_digest "$evidence_digest" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, reason:$reason, evidence_digest:$evidence_digest}' \
    >> "$WARN_LOG" 2>/dev/null || true
}

# log_block records a content DIGEST only — never raw matched PII (mirrors the
# suite's digest-logging convention).
log_block() {
  local rule_id="$1"; local evidence="$2"
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  local evidence_digest; evidence_digest="$(digest "$evidence")"
  # shellcheck disable=SC2016
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg evidence_digest "$evidence_digest" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, evidence_digest:$evidence_digest}' \
    >> "$BLOCK_LOG" 2>/dev/null || true
}

# apply_block — MODE-GATED block (warn / off / enforce). Used by the fuzzy /
# destination-resolution layer (CD-1 unmapped, CD-3 empty-extraction).
apply_block() {
  local rule_id="$1"; local reason="$2"; local override="$3"; local evidence="${4:-$TOOL_NAME}"
  local mode; mode="$(get_mode)"
  case "$mode" in
    warn)
      log_warn "$rule_id" "$reason" "$(digest "$evidence")"
      "$PRINTF" '[CLAUDE-HOOK:%s:%s] WARN (would-block, .scope-segregation-mode=warn): %s\n' "$HOOK_NAME" "$rule_id" "$reason" >&2
      exit 0
      ;;
    off)
      exit 0
      ;;
    enforce|*)
      log_block "$rule_id" "$evidence"
      "$PRINTF" '[CLAUDE-HOOK:%s:%s] BLOCKED: %s\nOverride: %s\n' "$HOOK_NAME" "$rule_id" "$reason" "$override" >&2
      exit 2
      ;;
  esac
}

# always_block — UNCONDITIONAL block (mode-independent), for CD-2's high-confidence
# identity/private-needle → scope:public crown-jewel class. Mirrors
# block-autonomy-ceiling.sh always_block + git-pre-commit-pii.sh's unconditional
# exit. Honors .scope-segregation-mode=off ONLY as a full kill-switch (an explicit
# operator disable), but NOT warn — a warn window must not be a window of
# irreversible public PII exposure. The allowlist + CLAUDE_HOOK_BYPASS are the
# per-match / per-session escapes (both evaluated before this fires).
always_block() {
  local rule_id="$1"; local reason="$2"; local override="$3"; local evidence="${4:-$TOOL_NAME}"
  local mode; mode="$(get_mode)"
  if [ "$mode" = "off" ]; then
    exit 0
  fi
  log_block "$rule_id" "$evidence"
  "$PRINTF" '[CLAUDE-HOOK:%s:%s] BLOCKED (always-enforce; identity/private PII → public destination): %s\nOverride: %s\n' "$HOOK_NAME" "$rule_id" "$reason" "$override" >&2
  exit 2
}

# ==========================================================================
# STEP 1 — FILING-VERB EARLY EXIT (performance: fires on every Bash/MCP call)
# ==========================================================================
# Only content-BEARING filing verbs to a work tracker are in scope. Everything
# else (reads, non-filing writes, arbitrary Bash) → allow.
COMMAND=""
FILING=0
case "$TOOL_NAME" in
  Bash)
    COMMAND="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.command // empty')"
    [ -z "$COMMAND" ] && exit 0
    # gh issue/pr create|comment ; gh api POST-ish to issues/pulls ; gh project item-*
    if "$PRINTF" '%s' "$COMMAND" | "$GREP" -qE 'gh[[:space:]]+(issue|pr)[[:space:]]+(create|comment)|gh[[:space:]]+api[[:space:]]+[^|;&]*(issues|pulls)|gh[[:space:]]+project[[:space:]]+item-(create|add)'; then
      FILING=1
    fi
    ;;
  mcp__*)
    # Narrowed FILING subset of the block-mcp-writes write-verb set: verbs that
    # create or add CONTENT to a work item (create/add/comment/post/insert/
    # update/edit/replace). Non-filing MCP writes (share/permission/…) and all
    # MCP reads are out of scope.
    if "$PRINTF" '%s' "$TOOL_NAME" | "$GREP" -qE '^mcp__[^_]+__(create|add|comment|post|insert|update|edit|replace)(_|[A-Z]|$)'; then
      FILING=1
    fi
    ;;
esac
[ "$FILING" -eq 1 ] || exit 0

# ==========================================================================
# STEP 2 — DESTINATION → SCOPE RESOLUTION (operator.toml [trackers.<id>])
# ==========================================================================

# trackers_configured — 0 (yes, ≥1 [trackers.*] section) / 1 (no).
trackers_configured() {
  [ -r "$OPERATOR_TOML" ] || return 1
  "$GREP" -qE '^[[:space:]]*\[trackers\.[^]]+\]' "$OPERATOR_TOML" 2>/dev/null
}

# emit_trackers — print one "identifier<TAB>scope" line per [trackers.<id>] section.
# Section-aware (unlike the section-blind automation_level grep): a subtable's
# identifier/scope must be read within its own [trackers.<id>] block.
emit_trackers() {
  [ -r "$OPERATOR_TOML" ] || return 0
  "$AWK" '
    function unq(v){ gsub(/^[ \t]+|[ \t]+$/,"",v); gsub(/^"|"$/,"",v); return v }
    /^[[:space:]]*\[/ {
      if (intr && ident!="") print ident "\t" scope
      intr=0; ident=""; scope=""
      if ($0 ~ /^[[:space:]]*\[trackers\.[^]]+\]/) intr=1
      next
    }
    intr && /^[[:space:]]*identifier[[:space:]]*=/ { split($0,a,"="); ident=unq(a[2]); next }
    intr && /^[[:space:]]*scope[[:space:]]*=/       { split($0,a,"="); scope=unq(a[2]); next }
    END { if (intr && ident!="") print ident "\t" scope }
  ' "$OPERATOR_TOML" 2>/dev/null
}

# Extract the filing destination identifier from the payload (best-effort per the
# feasibility note — v1 covers the shapes an operator actually declares; an
# unknown shape resolves to "" → unmapped → CD-1 branch).
DEST_ID=""
case "$TOOL_NAME" in
  Bash)
    # gh --repo <owner/name>  |  gh api …/repos/<owner/name>/…
    DEST_ID="$("$PRINTF" '%s' "$COMMAND" | "$GREP" -oE -- '--repo[[:space:]]+[^[:space:];&|]+' | "$HEAD" -1 | "$AWK" '{print $2}' || true)"
    if [ -z "$DEST_ID" ]; then
      DEST_ID="$("$PRINTF" '%s' "$COMMAND" | "$GREP" -oE 'repos/[^/[:space:]]+/[^/[:space:]]+' | "$HEAD" -1 | "$SED" 's#repos/##' || true)"
    fi
    ;;
  mcp__*)
    # Common id fields across declared MCP servers (Jira projectKey/cloudId,
    # Smartsheet sheetId, Linear teamId, GitHub owner/repo). Best-effort union.
    DEST_ID="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '
      .tool_input // {} |
      ( .projectKey // .project // .repo // .repository // .owner // .sheetId
        // .sheet_id // .teamId // .team_id // .cloudId // .boardId // .board_id
        // .space // .spaceKey // empty ) | tostring' 2>/dev/null || true)"
    [ "$DEST_ID" = "null" ] && DEST_ID=""
    ;;
esac

# Resolve scope for DEST_ID against the declared trackers.
SCOPE=""
if [ -n "$DEST_ID" ]; then
  while IFS="$(printf '\t')" read -r t_ident t_scope; do
    [ -z "$t_ident" ] && continue
    # Exact match, or containment either direction (an api path carrying owner/name
    # contains the "owner/name" identifier; a bare identifier equals the token).
    case "$DEST_ID" in
      "$t_ident") SCOPE="$t_scope"; break ;;
      *"$t_ident"*) SCOPE="$t_scope"; break ;;
    esac
    case "$t_ident" in
      *"$DEST_ID"*) SCOPE="$t_scope"; break ;;
    esac
  done <<EOF
$(emit_trackers)
EOF
fi

# --- Route by scope ---
if [ "$SCOPE" = "private" ]; then
  exit 0   # PII permitted on a private destination.
fi

if [ -z "$SCOPE" ]; then
  # Unmapped destination.
  if trackers_configured; then
    # CD-1 — fail-closed routing default (fuzzy/destination-resolution layer,
    # mode-gated warn-first). The operator opted into segregation; an unmapped
    # filing target must not silently pass toward a public destination.
    apply_block "BLOCK-SCOPE-SEG-001" \
      "filing to an UNMAPPED tracker destination while [trackers.*] are configured (fail-closed routing default; destination scope is unknown, so public exposure cannot be ruled out). Destination hint: '${DEST_ID:-<none parsed>}', tool: ${TOOL_NAME}." \
      "declare this destination in operator.toml [trackers.<id>] with its scope, select an explicit destination, add a false-positive exemption to .claude/scope-segregation-allowlist.txt, or set CLAUDE_HOOK_BYPASS=1 if intentional" \
      "${DEST_ID}:${TOOL_NAME}"
  fi
  # No trackers configured at all → back-compat single-stream; allow.
  exit 0
fi

# ==========================================================================
# STEP 3 — CONTENT SCAN (mapped scope:public destination only)
# ==========================================================================
# Extract the authored content (title + body + comment). Bash: inline + referenced
# --body-file / -F body=@ files (the block-gh-path-leak.sh extraction model). MCP:
# the content-bearing fields.
CONTENT=""
case "$TOOL_NAME" in
  Bash)
    # (1) referenced body files
    for bf in $("$PRINTF" '%s' "$COMMAND" | "$GREP" -oE -- '(--body-file[[:space:]]+|(-F|--field)[[:space:]]+body=@)[^[:space:];&|]+' | "$GREP" -oE '[^[:space:]@]+$' || true); do
      if [ -f "$bf" ] && [ -r "$bf" ]; then
        CONTENT="${CONTENT}"$'\n'"$("$CAT" "$bf" 2>/dev/null || true)"
      fi
    done
    # (2) inline --title / --body / -b / -f body= text
    INLINE="$("$PRINTF" '%s' "$COMMAND" | "$GREP" -oE -- '(--title|--body|-b|-t|-f[[:space:]]+(body|title)=)[[:space:]]*[^|;&]+' || true)"
    CONTENT="${CONTENT}"$'\n'"${INLINE}"
    ;;
  mcp__*)
    CONTENT="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '
      .tool_input // {} |
      [ .title, .body, .description, .text, .comment, .summary, .name,
        ( .fields // {} | .summary ), ( .fields // {} | .description | tostring ) ]
      | map(select(. != null and . != "")) | join("\n")' 2>/dev/null || true)"
    [ "$CONTENT" = "null" ] && CONTENT=""
    ;;
esac

CONTENT_STRIPPED="$("$PRINTF" '%s' "$CONTENT" | "$TR" -d '[:space:]' || true)"

# CD-3 — fail-closed content-extraction on the mapped-public branch. UNLIKE
# block-gh-path-leak.sh:170 (`[ -z "$BODY" ] && exit 0` — fail-open), an empty /
# unparseable extraction here is treated as would-block(warn)/block(enforce): we
# reached a KNOWN public destination and could not verify the content is clean.
if [ -z "$CONTENT_STRIPPED" ]; then
  apply_block "BLOCK-SCOPE-SEG-002" \
    "content extraction was EMPTY / unparseable for a filing to a scope:public destination ('${DEST_ID}') — cannot verify the content carries no private markers (fail-closed; the MCP surface commonly yields empty extraction). Tool: ${TOOL_NAME}." \
    "file via an extractable form (inline --body / --body-file for gh; a recognized content field for MCP), add an exemption to .claude/scope-segregation-allowlist.txt, or set CLAUDE_HOOK_BYPASS=1 if intentional" \
    "${DEST_ID}:${TOOL_NAME}:empty-extraction"
fi

# --- Allowlist exemption (fixed-string, whole-line): a known-safe content line the
# operator has registered as a false-positive escape. ---
line_is_allowlisted() {
  local line="$1"
  [ -f "$ALLOWLIST" ] || return 1
  # A non-comment, non-blank allowlist entry that appears as a substring of the line.
  local entry
  while IFS= read -r entry; do
    case "$entry" in ''|'#'*) continue ;; esac
    case "$line" in *"$entry"*) return 0 ;; esac
  done < "$ALLOWLIST"
  return 1
}

# --- Needle scan (reused substrate). Any NON-EXEMPT match → CD-2 always-block. ---
# Source the shared path-leak primitive (home-path + bare-instance leaks). Missing /
# invalid on the mapped-public branch is itself fail-closed (we are committed to
# scanning a public filing): enforce blocks, warn would-block.
_primitive_ok=0
if [ -f "$PRIMITIVE" ] && "${BASH:-/bin/bash}" -n "$PRIMITIVE" 2>/dev/null; then
  # shellcheck source=/dev/null
  . "$PRIMITIVE" 2>/dev/null || true
  command -v path_leak_scan_line >/dev/null 2>&1 && _primitive_ok=1
fi
if [ "$_primitive_ok" -ne 1 ]; then
  log_error "PRIMITIVE-MISSING-OR-INVALID: $PRIMITIVE did not provide path_leak_scan_line"
  apply_block "BLOCK-SCOPE-SEG-003" \
    "the shared path-leak primitive is unavailable, so the public-destination content scan cannot run (fail-closed). Tool: ${TOOL_NAME}." \
    "restore core/deploy/tools/path-leak-patterns.sh (or the co-deployed copy), or set CLAUDE_HOOK_BYPASS=1 if intentional" \
    "${DEST_ID}:${TOOL_NAME}:primitive-missing"
fi

# Localized needles (coworker / org / CD-4 client-project) via the single resolver.
NEEDLE_FILE=""
if [ -f "$NEEDLE_LIB" ]; then
  # shellcheck source=/dev/null
  . "$NEEDLE_LIB" 2>/dev/null || true
  command -v pmo_localized_needles >/dev/null 2>&1 && NEEDLE_FILE="$(pmo_localized_needles 2>/dev/null || true)"
fi
NEEDLE_CLEANED=""
if [ -n "$NEEDLE_FILE" ] && [ -r "$NEEDLE_FILE" ]; then
  NEEDLE_CLEANED="$("$GREP" -vE '^[[:space:]]*(#|$)' "$NEEDLE_FILE" 2>/dev/null || true)"
fi

# Generic identity PATTERNS (patterns, not PII) — the two from git-pre-commit-pii.sh.
# home-path is covered by path_leak_scan_line (PATH_LEAK_RE_MACHINE); phone +
# personal-email are inlined here with git-pre-commit-pii.sh as the sibling home.
readonly RE_PHONE='[0-9]{3}-[0-9]{3}-[0-9]{4}'
readonly RE_PMAIL='@(gmail|ymail|yahoo|outlook|hotmail|icloud|proton(mail)?)\.com'

HIT_LINE=""
HIT_CLASS=""
while IFS= read -r line || [ -n "$line" ]; do
  [ -z "$line" ] && continue
  line_is_allowlisted "$line" && continue
  # (a) home-path / bare-instance leak (shared primitive)
  if path_leak_scan_line "$line"; then
    HIT_LINE="$line"; HIT_CLASS="operator-path"; break
  fi
  # (b) phone / personal-email (inline generic patterns)
  if "$PRINTF" '%s' "$line" | "$GREP" -qE "${RE_PHONE}|${RE_PMAIL}"; then
    HIT_LINE="$line"; HIT_CLASS="identity-contact"; break
  fi
  # (c) coworker / org / client-project localized needles (fixed-string, case-insens.)
  if [ -n "$NEEDLE_CLEANED" ] && "$PRINTF" '%s' "$line" | "$GREP" -iFqf <("$PRINTF" '%s\n' "$NEEDLE_CLEANED"); then
    HIT_LINE="$line"; HIT_CLASS="localized-needle"; break
  fi
done <<EOF
$CONTENT
EOF

if [ -n "$HIT_LINE" ]; then
  EVIDENCE="$("$PRINTF" '%s' "$HIT_LINE" | "$SED" 's/^[[:space:]]*//' | "$HEAD" -c 80)"
  # CD-2 — high-confidence identity/private needle → scope:public : ALWAYS block.
  always_block "BLOCK-SCOPE-SEG-004" \
    "private/PII-marked content (${HIT_CLASS}) bound for a scope:public destination ('${DEST_ID}') — public and private work must not cross-contaminate. Tool: ${TOOL_NAME}." \
    "route to a scope:private destination, remove the private marker, add a verified false-positive exemption to .claude/scope-segregation-allowlist.txt, or set CLAUDE_HOOK_BYPASS=1 if intentional" \
    "$EVIDENCE"
fi

# Needle-clean content to a public destination → allow.
exit 0
