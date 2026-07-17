#!/usr/bin/env bash
# block-autonomy-ceiling.sh — PreToolUse hook enforcing the autonomy-level ceiling.
# hook-owner: core/rules/bypass-mode-readiness/block-autonomy-ceiling.md
#
# Design source: core/standards/subagent-security-posture.md § 4 Deferred Hook
# Contract (RESOLVED in v2.07 — this hook IS that contract's realization). The
# §4 design originally named `block-subagent-tier-violation.sh` triggered on
# subagent-session detection; that trigger is contradicted by §3 Mechanism 2 of
# the same document ("hooks do NOT read session-context fields — no session_id,
# no parent_session, no subagent_type") and has zero precedent in the hook suite.
# This hook triggers on the TOOL-CALL PAYLOAD (the universal signal all hooks
# use) and reads the resolved `automation_level` ceiling. The supersession is
# recorded in core/ADRs/ADR-031. The §4 Tier-0/1/2/3 gating table is absorbed
# here as the rule set; the §4 subagent-only approval-evidence rows (Tier 1/2/3)
# are Phase-2 deferred — they need a session/approval signal the payload lacks.
#
# WHAT IT DOES:
#   1. Irreducible Tier-0 floor (ALWAYS block, regardless of automation_level
#      AND regardless of .autonomy-mode) — the payload-detectable subset of
#      core/specs/autonomy-tiers.md § Irreducible Human Tasks. This is the
#      always-enforce class (mirrors block-rm-prefer-trash / block-destructive
#      permanence). Checked FIRST.
#   2. Ceiling check — compute the action's required tier from a conservative
#      declared-mapping table; block (mode-gated) when required_tier exceeds the
#      resolved `automation_level` ceiling (effective = min(level, required)).
#      PERMISSIVE DEFAULT: an unmapped action is treated as at-or-below the
#      ceiling and ALLOWED (the load-bearing false-positive mitigation — C5
#      gates every mutation, so a deny-default would break the platform; the
#      un-gated action still runs through the 7 existing safety hooks).
#
# ENFORCEMENT POSTURE (do NOT read as "now hard-enforced" unqualified):
#   - The Tier-0 floor is LIVE always (mode/level independent) for the
#     payload-detectable classes ONLY: governance-file writes + cross-domain
#     bridge writes. Financial / account-creation / security-permission and the
#     Stage 9 / Stage 12 gates are NOT mechanically detectable from a tool
#     payload — they remain OPERATOR-IRREDUCIBLE by convention, not by this hook.
#   - The ceiling check is hard-enforced ONLY AFTER the operator flips this
#     hook's own .autonomy-mode from warn → enforce post-shakedown. It ships
#     WARN-MODE-INITIAL (own mode file `.autonomy-mode`, NOT the shared `.mode`)
#     because it has the highest false-positive risk of any hook (it gates every
#     mutation). See core/rules/bypass-mode-readiness.md.
#
# SECTION-BLIND-GREP ASSUMPTION (pinned): the ceiling read greps `^automation_level`
#   line-anchored WITHOUT parsing the `[automation]` TOML section, because the key
#   is unique repo-wide (C0 #322 / #1429 survey: 0 prior occurrences) — exactly as
#   notify-version-skew.sh greps `^operator_github` without parsing `[identity]`.
#   If a second `automation_level` key is ever introduced under a different
#   section, this resolution would need section-awareness.
#
# CACHE (FMF-1): the session-stable dial is resolved ONCE at SessionStart by the
#   sibling prime-autonomy-ceiling-cache.sh hook, which writes the numeric ceiling
#   to ${HOME}/.cache/pmo-platform/autonomy-ceiling. This PreToolUse hook reads
#   that cache (a single file read) rather than grep+awk-ing operator.toml on
#   every tool call. If the cache is absent/unreadable (cache-priming hook did not
#   run, or first call before it ran), it falls back to a direct resolve so the
#   ceiling is never silently dropped.
#
# Composes with (does not replace) the existing 8 PreToolUse hooks. Registered
# LAST per matcher (the safety barriers evaluate first; C5 is the governance-
# ceiling layer on top). It does NOT duplicate destructive / fs-boundary / rm
# enforcement — it adds the autonomy-tier dimension (governance-file +
# cross-domain writes) the suite does not otherwise gate mode/level-independently.
#
# Matcher scope: Bash, Write, Edit, mcp__.*  (mutation surfaces only; Read /
#   WebFetch are non-mutating and out of scope).
# Rule IDs: BLOCK-AUTONOMY-001..099
# Mode gating: own .autonomy-mode (warn / enforce / off). Initial = warn.
# Release: v2.07 (ambient-intake-automation)

set -euo pipefail

# --- PATH PINNING (tamper resistance) ---
export PATH="/usr/bin:/bin"

# Absolute tool paths (all in /usr/bin or /bin, root-owned on macOS)
readonly GREP="/usr/bin/grep"
# jq is resolved below via lib/dep-resolve.sh (once HOOK_DIR is known), from a fixed
# absolute-path allowlist — never $PATH — so the anti-hijack PATH pin still holds
# (GHSA-9cjm-v22x-4x33). It replaces the old hard-coded JQ=/usr/bin/jq that failed
# OPEN on brew-only hosts (jq at /opt/homebrew/bin or /usr/local/bin).
readonly PRINTF="/usr/bin/printf"
readonly CAT="/bin/cat"
readonly TR="/usr/bin/tr"
readonly DATE="/bin/date"
readonly SHASUM="/usr/bin/shasum"
readonly AWK="/usr/bin/awk"
readonly PYTHON3="/usr/bin/python3"

# --- METADATA ---
readonly HOOK_NAME="block-autonomy-ceiling"
HOOK_DIR_RAW="$(cd "$(dirname "$0")" && pwd -P)"
readonly HOOK_DIR="$HOOK_DIR_RAW"
readonly ERROR_LOG="${HOOK_DIR}/hook-errors.log"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"
readonly WARN_LOG="${HOOK_DIR}/autonomy-warn-log.jsonl"
readonly MODE_FILE="${HOOK_DIR}/.autonomy-mode"

# Workspace root (the deployed-hook convention — block-destructive PRIMARY_ROOT /
# block-rm WORKSPACE_ROOT). Governance + cross-domain path detection anchors here.
readonly PRIMARY_ROOT="${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}"

# Runtime config + cache locations (the notify-version-skew.sh runtime-read
# convention; XDG cache dir).
readonly OPERATOR_TOML="${HOME}/.config/pmo-platform/operator.toml"
readonly CACHE_FILE="${HOME}/.cache/pmo-platform/autonomy-ceiling"

# --- SHARED DEPENDENCY RESOLVER (source the helper; fail CLOSED if it is missing/
# invalid — a hook that cannot even resolve its dependencies must not run degraded).
# Test readability BEFORE sourcing: bash 3.2 (macOS system bash) exits 1 on a failed
# `.` of a missing file even inside an `if !` condition, and exit 1 (unlike exit 2) is
# NON-blocking in the PreToolUse contract — i.e. a missing helper would fail OPEN. ---
readonly DEP_LIB="${HOOK_DIR}/lib/dep-resolve.sh"
if [ ! -r "$DEP_LIB" ] || ! . "$DEP_LIB" 2>/dev/null || ! command -v resolve_jq >/dev/null 2>&1; then
  "$PRINTF" '[CLAUDE-HOOK:%s:LIB-MISSING] BLOCKED (fail-closed): dependency helper lib/dep-resolve.sh unavailable or invalid.\n' "$HOOK_NAME" >&2
  exit 2
fi
JQ="$(resolve_jq)"; readonly JQ

# --- ERROR HANDLERS ---
log_error() {
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$PRINTF" '%s [%s] %s\n' "$ts" "$HOOK_NAME" "$1" >> "$ERROR_LOG" 2>/dev/null || true
}

# Fail-CLOSED on rule-evaluation error (exit 2 blocks).
# rc is set inside the trap by $? — shellcheck SC2154 is a false positive here.
# shellcheck disable=SC2154
trap 'rc=$?; log_error "RULE-EVAL-ERROR at line $LINENO (exit $rc)"; "$PRINTF" "[CLAUDE-HOOK:%s:HOOK-ERROR] BLOCKED: rule-eval error at line %s (exit %s). See %s.\n" "$HOOK_NAME" "$LINENO" "$rc" "$ERROR_LOG" >&2; exit 2' ERR

# --- READ INPUT (jq-free; stdin is consumed exactly once) ---
INPUT="$(cat)"

# --- CLAUDE_HOOK_BYPASS escape hatch — evaluated BEFORE the jq gate so it works even
# when jq is unresolvable (GHSA-9cjm-v22x-4x33: the old ordering placed this AFTER the
# jq check, advertising an escape hatch that a missing-jq path could make unreachable).
# jq-OPTIONAL: rich log when jq present, minimal printf record otherwise. ---
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

# --- MODE DETECTION (own .autonomy-mode; jq-free) — read BEFORE the dependency
# gate so the gate's fail-closed severity is mode-aware. Inline here (mirroring
# block-fs-boundary's inline mode read) using the same logic as get_mode() below.
# This governs ONLY the jq-MISSING branch: the always-enforce Tier-0 floor (STEP 1)
# still fires mode-independently via always_block when jq IS present, so this read
# does NOT relax the floor — it hardens the case where jq cannot be resolved. ---
MODE="enforce"
if [ -f "$MODE_FILE" ]; then
  MODE="$("$CAT" "$MODE_FILE" 2>/dev/null | "$TR" -d '[:space:]' || echo enforce)"
  case "$MODE" in warn|enforce|off) ;; *) MODE="enforce" ;; esac
fi

# --- DEPENDENCY GATE (mode-aware fail-closed) — GHSA-9cjm-v22x-4x33. The old code
# exited 0 (DEPENDENCY-WARN) on missing jq REGARDLESS of mode, so the always-enforce
# Tier-0 floor was silently disabled even under .autonomy-mode=enforce — the exact
# residual ADR-078 §Consequences flagged for the warn→enforce promotion. Now the gate
# is mode-aware, mirroring block-fs-boundary: enforce (and the default when no mode
# file exists) → fail CLOSED (exit 2) so the floor cannot be evaluated-away; warn/off
# → degrade (exit 0), no harder than a rule match would. Runs AFTER the bypass
# short-circuit and the mode read. ---
if [ -z "$JQ" ]; then
  log_error "DEPENDENCY-MISSING: jq not found on the pinned tool path (mode=$MODE)"
  if [ "$MODE" = "enforce" ]; then
    deny_missing_dep jq "$HOOK_NAME" "$PRINTF"
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:DEPENDENCY-DEGRADED:WARN] jq not found on the pinned tool path; %s-mode hook cannot evaluate input and is allowing this call. Install jq (brew install jq) to restore enforcement.\n' "$HOOK_NAME" "$MODE" >&2
  exit 0
fi

# --- VALIDATE INPUT ---
if ! "$PRINTF" '%s' "$INPUT" | "$JQ" -e . >/dev/null 2>&1; then
  log_error "INVALID-INPUT: malformed JSON"
  "$PRINTF" '[CLAUDE-HOOK:%s:INPUT-INVALID] BLOCKED: malformed hook input JSON.\n' "$HOOK_NAME" >&2
  exit 2
fi

TOOL_NAME="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_name // empty')"
CWD="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.cwd // empty')"

# --- EARLY EXIT: non-mutation tool calls (out of matcher scope) ---
# Defensive: the registration only wires Bash/Write/Edit/mcp__*, but a future
# mis-registration must not make this hook fire on Read/WebFetch.
case "$TOOL_NAME" in
  Bash|Write|Edit) ;;     # mutation surface — evaluate
  mcp__*) ;;              # MCP surface — evaluate
  *) exit 0 ;;            # Read / WebFetch / anything else — allow
esac

# --- MODE DETECTION (own .autonomy-mode, NOT the shared .mode) ---
get_mode() {
  local mode="enforce"
  if [ -f "$MODE_FILE" ]; then
    mode="$("$CAT" "$MODE_FILE" 2>/dev/null | "$TR" -d '[:space:]' || echo enforce)"
  fi
  case "$mode" in
    warn|enforce|off) "$PRINTF" '%s' "$mode" ;;
    *) "$PRINTF" 'enforce' ;;
  esac
}

# --- LOGGING HELPERS ---
digest() {
  "$PRINTF" '%s' "$1" | "$SHASUM" -a 256 | "$GREP" -oE '^[a-f0-9]+' | /usr/bin/head -c 16
}

log_warn() {
  local rule_id="$1"; local reason="$2"; local tool_digest="$3"
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  # shellcheck disable=SC2016  # jq filter — single quotes intentional
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg reason "$reason" --arg tool_digest "$tool_digest" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, reason:$reason, tool_digest:$tool_digest}' \
    >> "$WARN_LOG" 2>/dev/null || true
}

log_block() {
  local rule_id="$1"
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  local tool_input; tool_input="$("$PRINTF" '%s' "$INPUT" | "$JQ" -c '.tool_input // {}')"
  local input_digest; input_digest="$("$PRINTF" '%s' "$tool_input" | "$SHASUM" -a 256 | "$GREP" -oE '^[a-f0-9]+' | /usr/bin/head -c 16)"
  # shellcheck disable=SC2016  # jq filter — single quotes intentional
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg digest "$input_digest" --arg cwd "$CWD" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, input_digest:$digest, cwd:$cwd}' \
    >> "$BLOCK_LOG" 2>/dev/null || true
}

# apply_block — mode-gated block for the CEILING check (warn / off / enforce).
# Used ONLY by the ceiling check, NOT by the irreducible Tier-0 floor (the floor
# uses always_block below, which ignores mode).
apply_block() {
  local rule_id="$1"; local reason="$2"; local override="$3"
  local mode; mode="$(get_mode)"
  local tool_digest; tool_digest="$(digest "$TOOL_NAME")"
  case "$mode" in
    warn)
      log_warn "$rule_id" "$reason" "$tool_digest"
      "$PRINTF" '[CLAUDE-HOOK:%s:%s] WARN (would-block, .autonomy-mode=warn): %s\n' "$HOOK_NAME" "$rule_id" "$reason" >&2
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

# always_block — UNCONDITIONAL block for the irreducible Tier-0 floor. Mode- AND
# level-independent (always-enforce class, mirrors block-rm BLOCK-TRASH-001).
# Does NOT consult get_mode(): a Tier-0 action is blocked even under
# .autonomy-mode=warn or =off.
always_block() {
  local rule_id="$1"; local reason="$2"; local override="$3"
  log_block "$rule_id"
  "$PRINTF" '[CLAUDE-HOOK:%s:%s] BLOCKED: %s\nOverride: %s\n' "$HOOK_NAME" "$rule_id" "$reason" "$override" >&2
  exit 2
}

# --- CEILING RESOLUTION (FMF-1: cache-first, direct-resolve fallback) ---
# Numeric ceiling map: off=0, recommend=1, bounded_auto=2.
level_to_num() {
  case "$1" in
    off) "$PRINTF" '0' ;;
    recommend) "$PRINTF" '1' ;;
    bounded_auto) "$PRINTF" '2' ;;
    *) "$PRINTF" '1' ;;   # defensive: unrecognized → recommend (never opens to bounded_auto)
  esac
}

# Direct resolve from operator.toml — the notify-version-skew.sh:67 pattern.
# Used as the fallback when the SessionStart cache is absent.
resolve_level_direct() {
  local level="recommend"   # default-on, matches C0 default; a missing config never opens the gate
  if [ -r "$OPERATOR_TOML" ]; then
    local parsed
    # shellcheck disable=SC2016  # awk field ref ($2) — single quotes intentional
    parsed="$("$GREP" -E '^automation_level' "$OPERATOR_TOML" 2>/dev/null | /usr/bin/head -1 | "$AWK" -F= '{gsub(/[" ]/,"",$2); print $2}')"
    case "$parsed" in off|recommend|bounded_auto) level="$parsed" ;; esac
  fi
  "$PRINTF" '%s' "$level"
}

# Resolve the numeric ceiling: cache file first (a single read), else direct.
resolve_ceiling_num() {
  if [ -r "$CACHE_FILE" ]; then
    local cached
    cached="$("$CAT" "$CACHE_FILE" 2>/dev/null | "$TR" -d '[:space:]' || true)"
    case "$cached" in
      0|1|2) "$PRINTF" '%s' "$cached"; return 0 ;;
    esac
  fi
  # Cache absent/unreadable/garbage — direct resolve (defensive; never drop the ceiling)
  level_to_num "$(resolve_level_direct)"
}

# --- PATH RESOLUTION (Write/Edit file_path → absolute) ---
# Mirrors block-destructive.sh Write/Edit branch: Python os.path.realpath when
# available (resolves ../, symlinks; tolerates not-yet-existing files via parent
# resolution); graceful degradation to the raw path string.
resolve_path() {
  local fp="$1"
  [ -z "$fp" ] && return 0
  local abs=""
  if [ -e "$fp" ] && [ -x "$PYTHON3" ]; then
    abs="$("$PYTHON3" -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$fp" 2>/dev/null || echo "$fp")"
  elif [ -e "$fp" ]; then
    abs="$fp"
  elif [ -x "$PYTHON3" ]; then
    # Not-yet-existing target — resolve parent dir, re-attach basename.
    local parent base parent_abs
    parent="$(/usr/bin/dirname "$fp")"
    base="$(/usr/bin/basename "$fp")"
    if [ -d "$parent" ]; then
      parent_abs="$(cd "$parent" 2>/dev/null && pwd -P || echo "$parent")"
      abs="${parent_abs}/${base}"
    else
      abs="$fp"
    fi
  else
    abs="$fp"
  fi
  "$PRINTF" '%s' "$abs"
}

# ==========================================================================
# RULE EVALUATION
# ==========================================================================
#
# Order (per spec D2 §5–6):
#   1. Irreducible Tier-0 floor FIRST (always_block, mode+level independent).
#   2. Ceiling check (apply_block, mode-gated).
# An unmatched action falls through both and is ALLOWED (permissive default).

# Extract the Write/Edit file_path once (empty for Bash/mcp__*).
FILE_PATH="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.file_path // empty')"
ABS_TARGET=""
if [ -n "$FILE_PATH" ]; then
  ABS_TARGET="$(resolve_path "$FILE_PATH")"
fi

# --------------------------------------------------------------------------
# STEP 1 — IRREDUCIBLE TIER-0 FLOOR (always-block; payload-detectable subset of
#          autonomy-tiers.md § Irreducible Human Tasks)
# --------------------------------------------------------------------------
# Only the payload-detectable classes are enforced here:
#   item 6 — governance-file modification (Write/Edit file_path → governance path)
#   item 7 — cross-domain bridge writes (Write/Edit file_path crossing the
#            pmo-platform ↔ projects boundary)
# Items 1/2/3 (financial / account-creation / security-permission) and items 4/5
# (Stage 9 / Stage 12 gates) are NOT mechanically detectable from a tool payload
# — operator-irreducible by convention, documented, not enforced here.
# Item 8 (destructive outside the workspace) is ALREADY owned by
# block-rm-prefer-trash (BLOCK-TRASH-001/003) — C5 does NOT duplicate it.

if [ -n "$ABS_TARGET" ]; then
  case "$TOOL_NAME" in
    Write|Edit)
      # --- BLOCK-AUTONOMY-001 — Tier-0 item 6: governance-file modification ---
      # The governance set per autonomy-tiers.md item 6 + CLAUDE.md "No ungoverned
      # changes": CLAUDE.md, OPERATIONS.md, RELEASE_PROTOCOL.md, any SKILL.md, the
      # settings.json security file, and the security hooks/rules. Matched by
      # resolved path. This is the autonomy-tier dimension of the same surface
      # block-destructive BLOCK-DESTRUCTIVE-019 guards — but C5's floor is
      # level/mode-independent and does NOT carve out the worktree exemption
      # (governance edits are operator-irreducible regardless of cwd).
      case "$ABS_TARGET" in
        */CLAUDE.md \
        | */OPERATIONS.md \
        | */RELEASE_PROTOCOL.md \
        | */SKILL.md \
        | "${PRIMARY_ROOT}/.claude/settings.json" \
        | "${PRIMARY_ROOT}/.claude/hooks/"* \
        | "${PRIMARY_ROOT}/.claude/rules/"*)
          always_block "BLOCK-AUTONOMY-001" \
            "governance-file modification is an irreducible Tier-0 action (operator-only per 'No ungoverned changes'); blocked regardless of automation_level. Target: ${ABS_TARGET}" \
            "governance changes require Issue + plan + operator approval — make the change through the governed flow, or set CLAUDE_HOOK_BYPASS=1 only if you ARE the operator acting intentionally"
          ;;
      esac

      # --- BLOCK-AUTONOMY-002 — Tier-0 item 7: cross-domain bridge writes ---
      # Layer separation: Claude Code (a pmo-platform cwd) never writes to
      # projects/ ; Cowork (a projects/ cwd) never writes to pmo-platform/.
      # Detected by cwd-domain ↔ target-domain mismatch. Path-boundary match
      # against the two domain roots under the workspace.
      # Match the domain ROOT itself OR any subpath (the trailing-slash glob alone
      # would miss a cwd/target that IS exactly `${ROOT}/pmo-platform`).
      target_domain=""
      case "$ABS_TARGET" in
        "${PRIMARY_ROOT}/pmo-platform"|"${PRIMARY_ROOT}/pmo-platform/"*) target_domain="pmo-platform" ;;
        "${PRIMARY_ROOT}/projects"|"${PRIMARY_ROOT}/projects/"*) target_domain="projects" ;;
      esac
      cwd_domain=""
      case "$CWD" in
        "${PRIMARY_ROOT}/pmo-platform"|"${PRIMARY_ROOT}/pmo-platform/"*) cwd_domain="pmo-platform" ;;
        "${PRIMARY_ROOT}/projects"|"${PRIMARY_ROOT}/projects/"*) cwd_domain="projects" ;;
      esac
      if [ -n "$target_domain" ] && [ -n "$cwd_domain" ] && [ "$target_domain" != "$cwd_domain" ]; then
        always_block "BLOCK-AUTONOMY-002" \
          "cross-domain bridge write is an irreducible Tier-0 action (Layer separation; ${cwd_domain} cwd writing to ${target_domain}); blocked regardless of automation_level. Target: ${ABS_TARGET}" \
          "Engineering (pmo-platform) and Operations (projects) are separate layers — do not cross-write; route the change through the owning agent, or set CLAUDE_HOOK_BYPASS=1 only if intentional"
      fi
      ;;
  esac
fi

# --------------------------------------------------------------------------
# STEP 2 — CEILING CHECK (mode-gated; permissive default)
# --------------------------------------------------------------------------
# Determine the action's required tier from the declared-mapping table, then
# block (mode-gated) iff required_tier exceeds the resolved automation_level
# ceiling. effective = min(ceiling, required). Unknown/unmatched → ALLOW.

CEILING_NUM="$(resolve_ceiling_num)"

# determine_required_tier — return the action's required Autonomy Tier number,
# or empty string when the action is unmapped (→ permissive allow).
# Seeded from autonomy-tiers.md observable indicators:
#   governance path → Tier 0 (already always-blocked in STEP 1; not re-emitted)
#   08-Generated/ staging write → Tier 2 (auto-write scope)
#   stakeholder-facing artifact write outside staging → Tier 1
#   mcp__* write-verb tool → Tier 1 (state-changing external action)
# Everything else → unmapped (empty) → allow.
determine_required_tier() {
  case "$TOOL_NAME" in
    Write|Edit)
      [ -z "$ABS_TARGET" ] && return 0
      case "$ABS_TARGET" in
        # 08-Generated/ staging area — Document Tier 2 auto-write scope → Tier 2
        */08-Generated/*) "$PRINTF" '2'; return 0 ;;
        # Other writes inside a projects/ project-artifact tree are stakeholder-
        # facing Document Tier 1 surfaces by default → Tier 1. (Staging above is
        # the Tier-2 carve-out matched first.)
        "${PRIMARY_ROOT}/projects/"*) "$PRINTF" '1'; return 0 ;;
      esac
      return 0   # unmapped → allow
      ;;
    mcp__*)
      # MCP write-verb tools are state-changing external actions → Tier 1.
      # Reuses the block-mcp-writes write-verb convention (snake_case + camelCase
      # termination). Non-write MCP tools (search/get/list/browse) are unmapped.
      if "$PRINTF" '%s' "$TOOL_NAME" | "$GREP" -qE '^mcp__[^_]+__(create|edit|update|delete|add|transition|share|attach|permission|publish|invite|grant|export|copy|move|comment|post|send|email|upload|import|replace|insert|remove|archive)(_|[A-Z]|$)'; then
        "$PRINTF" '1'; return 0
      fi
      return 0   # non-write MCP tool → allow
      ;;
    Bash)
      # Bash command tiering from a raw command string is the open-ended,
      # high-false-positive surface. Per spec D4, NO Bash patterns are mapped to
      # a higher tier here (the irreducible/destructive Bash classes are owned by
      # block-destructive / block-rm / block-egress, which evaluate FIRST). Bash
      # is left permissive at the ceiling layer by design — unmapped → allow.
      return 0
      ;;
  esac
  return 0
}

REQUIRED_TIER="$(determine_required_tier)"

# Unmapped action → permissive allow.
if [ -z "$REQUIRED_TIER" ]; then
  exit 0
fi

# Ceiling check: block (mode-gated) iff the action's required tier EXCEEDS the
# resolved ceiling. At/below the ceiling → allow.
if [ "$REQUIRED_TIER" -gt "$CEILING_NUM" ]; then
  apply_block "BLOCK-AUTONOMY-003" \
    "action requires Autonomy Tier ${REQUIRED_TIER}; the automation_level ceiling is ${CEILING_NUM} (effective = min(ceiling, required)). Tool: ${TOOL_NAME}." \
    "lower the action's autonomy, or raise operator.toml [automation].automation_level (you authorize the higher ceiling), or set CLAUDE_HOOK_BYPASS=1 only if intentional"
fi

# At/below ceiling — allow.
exit 0
