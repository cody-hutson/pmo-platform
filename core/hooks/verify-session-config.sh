#!/usr/bin/env bash
# verify-session-config.sh — SessionStart hook (WORKFLOW-CLASS, non-blocking notifier).
# hook-owner: core/config/platform-config.toml.template [spoke_runtime] (ADR-094 verification arm)
#
# Verifies the active session's resolved MODEL + EFFORT posture at launch against
# the workspace directive, catching runtime drift (a session launched
# `--model haiku`, a mid-session `/model` switch, an env override on a forked
# terminal) at the earliest surface — the fourth detection surface added to the
# model/effort-posture composite (deploy-time Check 27 + invocation-time Model
# Provenance + Stage-8 QA now + this runtime-launch reader).
#
# CLASS: workflow (NOT a security/floor hook). This is a model/effort *posture*
# verifier, not a public-surface *security* guard, so it is governed by the #310
# master-activation gate as a WORKFLOW-class hook: master-OFF makes it inert.
#
# NON-BLOCKING BY CONSTRUCTION. SessionStart hooks structurally CANNOT block a
# session (a non-zero exit renders a non-blocking "hook error" notice; the session
# proceeds regardless). This hook is a NOTIFIER/VERIFIER, not a blocker — which
# satisfies the "MUST NOT block legitimate downgrade workflows" constraint by
# construction. EVERY failure path exits 0 (fail-toward-advisory) — the deliberate
# OPPOSITE of the block-*.sh security fail-closed exit-2 posture (a hard exit-2 on
# a workflow notifier would spam a hook-error notice every launch, and a
# fail-closed stance is wrong for an advisory). "enforce" mode = loud stderr +
# non-zero exit (wrapper/CI-detectable), NOT a hard stop.
#
# STDERR, NOT STDOUT. A SessionStart hook's stdout is injected into Claude's
# context. All notices go to STDERR (operator-facing) so mismatch notices never
# pollute the model's context.
#
# RUNTIME PRECEDENCE (highest first, mirroring the block-*.sh chain, #310):
#   CLAUDE_HOOK_BYPASS  →  master_enable_gate workflow  →  .verify-session-config-mode  →  rule-eval
#
# RULE REGISTRY (first non-BLOCK- RULE family — the hook VERIFIES; a BLOCK- prefix
# would misdescribe a non-blocking SessionStart notice):
#   VERIFY-SESSION-CONFIG-001  model mismatch  (resolved model matches neither the
#                              default_spoke_model nor the chip_model family)
#   VERIFY-SESSION-CONFIG-002  effort mismatch (resolved effort != the directive `max`)
#   VERIFY-SESSION-CONFIG-003  payload-schema-fallback — fires ONLY when payload
#                              `.model` is absent (source ∈ clear|compact|resume|
#                              recovery); a DEGRADED-verification notice, NEVER a
#                              silent pass.
#
# EXPECTED VALUES (read canonically — NO hardcoded model constant):
#   model  — the accept-set { default_spoke_model, chip_model } read from the
#            canonical `platform-config.toml [spoke_runtime]` surface (ADR-094) the
#            SAME way deploy.sh's resolve_platform_config reads it. Accept EITHER
#            (the hook cannot distinguish a chip session from a subagent at launch).
#            The `opus` used when a field is unresolved at every rung is the
#            resolver Rule-2 consumer-fallback (identical to Check 27's), NOT a
#            transitional inline pin.
#   effort — the immutable, name-agnostic directive value `max` (SSOT: the operator
#            model-preference memory directive). [spoke_runtime] deliberately stores
#            NO effort field (a stored value would shadow-SSOT and drift, per
#            ADR-094 §Decision point 2) — the expected constant IS the directive.
#
# Structure copies block-skill-direct-edit.sh (header / PATH-pin / payload-parse /
# log-write / precedence) with the deltas a non-blocking SessionStart notifier
# requires. Reference: core/rules/bypass-mode-readiness/verify-session-config.md.

set -uo pipefail
# Any unexpected command failure trips this trap and exits 0 — every session
# launches this hook, so it MUST be fail-safe (matches its two SessionStart
# siblings notify-version-skew.sh / prime-autonomy-ceiling-cache.sh).
trap 'exit 0' ERR

# --- PATH PINNING (tamper resistance; mirrors the block-*.sh header) ---
export PATH="/usr/bin:/bin"
readonly GREP="/usr/bin/grep"
readonly PRINTF="/usr/bin/printf"
readonly DATE="/bin/date"
readonly CAT="/bin/cat"
readonly TR="/usr/bin/tr"
readonly HEAD="/usr/bin/head"
readonly SED="/usr/bin/sed"

# --- METADATA ---
readonly HOOK_NAME="verify-session-config"
readonly HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"
readonly WARN_LOG="${HOOK_DIR}/verify-session-warn-log.jsonl"
readonly MODE_FILE="${HOOK_DIR}/.verify-session-config-mode"
readonly MASTER_ENABLE_CLASS="workflow"
readonly MASTER_LIB="${HOOK_DIR}/lib/master-enable.sh"
readonly DEP_LIB="${HOOK_DIR}/lib/dep-resolve.sh"
# The immutable, name-agnostic effort directive value (no stored config field —
# no-shadow-SSOT per ADR-094). The expected-effort constant IS the directive.
readonly EXPECTED_EFFORT="max"

_vsc_ts() { "$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown; }

# --- CONSUME STDIN ONCE (jq-free capture; SessionStart payload JSON) ---
INPUT="$("$CAT" 2>/dev/null || echo '')"

# --- 1. CLAUDE_HOOK_BYPASS escape hatch — evaluated FIRST, before any dep/jq or
# master gate (the escape must not depend on the very machinery it bypasses). ---
if [ "${CLAUDE_HOOK_BYPASS:-}" = "1" ]; then
  ts="$(_vsc_ts)"
  "$PRINTF" '{"ts":"%s","hook":"%s","action":"bypass"}\n' "$ts" "$HOOK_NAME" >> "$BYPASS_LOG" 2>/dev/null || true
  exit 0
fi

# --- 2. Master-activation gate (#310) — WORKFLOW class. Precedence layer 2:
# bypass → master → .mode → rule. Guarded source: a MISSING lib does NOT gate
# (fail-toward-current-behavior — the hook keeps its advisory .mode path; a read
# failure never silently disables the verifier). For the WORKFLOW class,
# master_enable_gate calls `exit 0` internally when the master state is off, so a
# master-OFF workspace suppresses this hook. ---
if [ -r "$MASTER_LIB" ]; then . "$MASTER_LIB" 2>/dev/null || true; fi
if command -v master_enable_gate >/dev/null 2>&1; then master_enable_gate "$MASTER_ENABLE_CLASS"; fi

# --- 3. Mode read — OWN mode file `.verify-session-config-mode` (NOT the shared
# `.mode`), so this hook's ≥3-day warn shakedown is decoupled from the security
# cohort (the block-autonomy-ceiling `.autonomy-mode` precedent). Ships warn; an
# absent file defaults to warn (advisory). off → exit 0. ---
MODE="warn"
if [ -f "$MODE_FILE" ]; then
  mode_raw="$("$CAT" "$MODE_FILE" 2>/dev/null | "$TR" -d '[:space:]' || echo warn)"
  case "$mode_raw" in warn|enforce|off) MODE="$mode_raw" ;; *) MODE="warn" ;; esac
fi
[ "$MODE" = "off" ] && exit 0

# --- jq resolve (payload parse). Sourced from the shared resolver; if
# unresolvable, model becomes unverifiable → VERIFY-SESSION-CONFIG-003 degraded
# notice (never a silent pass). Effort stays checkable via $CLAUDE_EFFORT (env,
# jq-free). Unlike the block-*.sh security hooks, a missing jq NEVER fails closed
# here — a SessionStart notifier cannot block, and degrading to advisory is the
# correct posture. ---
JQ=""
if [ -r "$DEP_LIB" ] && . "$DEP_LIB" 2>/dev/null && command -v resolve_jq >/dev/null 2>&1; then
  JQ="$(resolve_jq)"
fi

# --- canonical [spoke_runtime] reader (ADR-094 / #340). Reads the SAME field
# names from the SAME canonical surface as deploy.sh's resolve_platform_config,
# mirroring its rung-1 idiom (in-repo template FLOOR, XDG individual OVERRIDE) —
# the deployed hook cannot source the ~6k-line deploy.sh, and #310's master-enable
# lib set the precedent that a hook reads platform-config with its own jq-free
# reader. Section-blind grep is safe: default_spoke_model / chip_model are
# repo-unique keys (the same assumption resolve_platform_config's _toml_field
# makes). NO hardcoded model — the field drives the expected value. ---
_vsc_cfg_field() {
  local _f="$1" _k="$2"
  [ -n "$_f" ] && [ -r "$_f" ] || return 0
  "$GREP" -E "^[[:space:]]*${_k}[[:space:]]*=" "$_f" 2>/dev/null \
    | "$HEAD" -1 \
    | "$SED" -E -e 's/.*=[[:space:]]*"([^"]*)".*/\1/' -e t -e 's/.*=[[:space:]]*([^#]*).*/\1/' \
    | "$SED" -E 's/^[[:space:]]+//; s/[[:space:]]+$//' || true
}
_vsc_resolve_platform_config() {
  local field="$1" val="" hit=""
  local cfg_root="${PMO_PLATFORM_CONFIG_ROOT:-$HOME/.config/pmo-platform}"
  # Rung 1 — in-repo template (global-default FLOOR); reachable in the
  # source-clone/test layout (hook at core/hooks/, template at core/config/),
  # absent in the deployed .claude/hooks/ layout.
  local tmpl="${HOOK_DIR}/../config/platform-config.toml.template"
  hit="$(_vsc_cfg_field "$tmpl" "$field")"; [ -n "$hit" ] && val="$hit"
  # Rung 5 — XDG individual surface OVERRIDES the template floor (the durable
  # operator-instance value; honors PMO_PLATFORM_CONFIG_ROOT for tests).
  hit="$(_vsc_cfg_field "${cfg_root}/platform-config.toml" "$field")"; [ -n "$hit" ] && val="$hit"
  "$PRINTF" '%s' "$val"
}

expected_default="$(_vsc_resolve_platform_config default_spoke_model)"
[ -n "$expected_default" ] || expected_default="opus"   # resolver Rule-2 consumer-fallback (ADR-094 / Check 27)
expected_chip="$(_vsc_resolve_platform_config chip_model)"
[ -n "$expected_chip" ] || expected_chip="opus"

# --- parse payload (source / model / effort.level); jq-guarded ---
resolved_source=""
resolved_model=""
payload_effort=""
if [ -n "$JQ" ] && "$PRINTF" '%s' "$INPUT" | "$JQ" -e . >/dev/null 2>&1; then
  resolved_source="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.source // empty' 2>/dev/null || echo '')"
  resolved_model="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.model // empty' 2>/dev/null || echo '')"
  payload_effort="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.effort.level // empty' 2>/dev/null || echo '')"
fi
# Effort: $CLAUDE_EFFORT (documented hook env — primary) with payload .effort.level
# as the jq-free-unavailable cross-check.
resolved_effort="${CLAUDE_EFFORT:-$payload_effort}"

# --- model-family canonicalization: payload gives a full id (claude-opus-4-8),
# config a family alias (opus). Compare on the family token so a point-release
# never false-flags (parameterize-over-hardcode / version-stable). ---
_vsc_family() {
  local m; m="$("$PRINTF" '%s' "$1" | "$TR" '[:upper:]' '[:lower:]')"
  case "$m" in
    *opus*)   "$PRINTF" 'opus' ;;
    *sonnet*) "$PRINTF" 'sonnet' ;;
    *haiku*)  "$PRINTF" 'haiku' ;;
    *)        "$PRINTF" '%s' "$m" ;;
  esac
}

# --- rule evaluation — accumulate ALL drift, emit once (report model AND effort
# in a single launch notice). findings: newline-separated "NNN|message". ---
findings=""
add_finding() { findings="${findings}$1|$2
"; }

# Model
if [ -z "$resolved_model" ]; then
  # payload `.model` absent (source ∈ clear|compact|resume|recovery) → degraded
  # verification, NEVER a silent pass (VERIFY-SESSION-CONFIG-003).
  add_finding "003" "runtime model unverifiable this launch (payload .model absent; source=${resolved_source:-unknown}); expected ${expected_default} — DEGRADED verification, not a pass"
else
  rf="$(_vsc_family "$resolved_model")"
  df="$(_vsc_family "$expected_default")"
  cf="$(_vsc_family "$expected_chip")"
  if [ "$rf" != "$df" ] && [ "$rf" != "$cf" ]; then
    add_finding "001" "model mismatch (${resolved_model} [${rf}] vs expected ${expected_default}/${expected_chip} [${df}/${cf}])"
  fi
fi

# Effort
if [ -z "$resolved_effort" ]; then
  # Rare edge: no $CLAUDE_EFFORT (documented-present) AND payload .effort.level
  # unparseable. Not a numbered rule (003 is scoped to model-absent by design);
  # emit a standalone DEGRADED advisory so effort is never silently passed.
  "$PRINTF" '[CLAUDE-HOOK:%s:DEGRADED] runtime effort unverifiable this launch (no $CLAUDE_EFFORT + payload .effort.level absent); expected %s — DEGRADED verification, not a pass\n' "$HOOK_NAME" "$EXPECTED_EFFORT" >&2
else
  ef="$("$PRINTF" '%s' "$resolved_effort" | "$TR" '[:upper:]' '[:lower:]')"
  if [ "$ef" != "$EXPECTED_EFFORT" ]; then
    add_finding "002" "effort mismatch (${resolved_effort} vs ${EXPECTED_EFFORT})"
  fi
fi

# No drift → clean exit.
[ -z "$findings" ] && exit 0

# --- emit — warn: warn-log + stderr WARN + exit 0; enforce: block-log + stderr +
# non-zero exit (wrapper/CI-detectable; SessionStart still cannot hard-stop). ---
ts="$(_vsc_ts)"
rc=0
[ "$MODE" = "enforce" ] && rc=1
"$PRINTF" '%s' "$findings" | while IFS='|' read -r n msg; do
  [ -z "$n" ] && continue
  rule="VERIFY-SESSION-CONFIG-$n"
  if [ "$MODE" = "enforce" ]; then
    "$PRINTF" '{"ts":"%s","hook":"%s","rule":"%s","mode":"enforce","detail":"%s"}\n' "$ts" "$HOOK_NAME" "$rule" "$msg" >> "$BLOCK_LOG" 2>/dev/null || true
    "$PRINTF" '[CLAUDE-HOOK:%s:%s] %s\n' "$HOOK_NAME" "$rule" "$msg" >&2
  else
    "$PRINTF" '{"ts":"%s","hook":"%s","rule":"%s","mode":"warn","detail":"%s"}\n' "$ts" "$HOOK_NAME" "$rule" "$msg" >> "$WARN_LOG" 2>/dev/null || true
    "$PRINTF" '[CLAUDE-HOOK:%s:%s:WARN] %s (warn-mode — advisory only)\n' "$HOOK_NAME" "$rule" "$msg" >&2
  fi
done || true

exit "$rc"
