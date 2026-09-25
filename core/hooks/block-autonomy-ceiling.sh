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
# SECTION-AWARE CEILING READ (supersedes the pinned SECTION-BLIND-GREP assumption).
#   The ceiling is resolved by parsing the [automation] TOML section and matching
#   `automation_level` with an `=` terminator, so (a) a same-named key under any other
#   section and (b) any same-PREFIX key (e.g. automation_level_ci_autoresolve) are both
#   unreachable. The prior reader was `grep -E '^automation_level'` with NO terminator,
#   which matched the whole prefix class — the hazard was never limited to a duplicate of
#   the exact name, and its apparent safety was file-ORDER dependent (a colliding key
#   sorting AFTER [automation] was harmlessly overridden, which is why it evaded casual
#   testing). Idiom lifted verbatim from lib/master-enable.sh _me_read_field.
#   STRICT PARITY: the column-0 key anchor and the value extraction are byte-equivalent
#   to the prior reader, so the ONLY changed inputs are the out-of-section ones, which
#   previously resolved fail-OPEN and now resolve fail-restrictive. Two shapes of VALID
#   in-section TOML that the prior reader mis-parsed — an inline trailing comment, and an
#   indented key — are deliberately still mis-parsed, identically, both landing on the
#   `recommend` default: correcting them would RAISE the resolved ceiling for an operator
#   who changed nothing, and a security-posture widening must ship as its own visible
#   change, never as a side effect of a hardening patch.
#   TWIN COPY: prime-autonomy-ceiling-cache.sh carries resolve_level_direct()
#   BYTE-IDENTICALLY — edit both or neither. That is also why this one function uses
#   absolute tool literals (/usr/bin/awk, /usr/bin/printf) rather than this file's $AWK /
#   $PRINTF constants: identical bytes make the twins diffable, and the constants hold
#   exactly those same strings. core/hooks/tests/prime-autonomy-ceiling-cache.test.sh
#   asserts the two resolve identically on every fixture, so copy drift is caught by
#   behaviour rather than by convention alone.
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
# NOTE: no AWK constant. The one awk call site (resolve_level_direct) is a byte-identical
# twin of the same function in prime-autonomy-ceiling-cache.sh and therefore spells the
# absolute path inline; a constant here would be unreferenced.
readonly PYTHON3="/usr/bin/python3"

# --- PATH RESOLUTION (Write/Edit file_path → absolute) ---
# Defined HERE, above ${PRIMARY_ROOT}, rather than beside the rules that consume it: the
# anchor, the target and the working directory must be resolved by the SAME function or
# they cannot meet. See the ANCHOR/TARGET RESOLUTION PARITY note on PRIMARY_ROOT below.

# resolve_path_shell — dependency-free physical resolution using only the pinned tool
# path. Resolves the parent chain with `cd … && pwd -P` (which collapses `..` and every
# symlinked directory component) and then follows a symlinked FINAL component with
# readlink, up to a stated hop bound.
#
# It exists because the python3 arm below has THREE doors to the raw path, not one:
# python3 absent for an existing target, python3 absent for a not-yet-existing target,
# and python3 present-but-non-functional — a Mac carrying the Command Line Tools stub at
# /usr/bin/python3 without the tools installed satisfies `[ -x ]` and still fails to
# execute. A raw path is the TEXTUAL reading of the target, and every classification in
# this hook (the -001 governance set, both cross-domain rules, the ceiling's projects/
# mapping) is a path comparison — so a raw path silently reclassifies an aliased target
# to whatever domain its string happens to name. That is the difference between a
# repo-reaching write being an always-block floor and being mode-gated.
#
# STATED BOUND, not an implied one: a symlink chain is followed at most
# RESOLVE_LINK_HOPS times; a longer chain is returned PARTIALLY resolved. Chains of one
# and two hops are asserted in Suite A of the test file; the bound itself is not, and
# this comment claims no more than that.
readonly RESOLVE_LINK_HOPS=16
resolve_path_shell() {
  local fp="$1"
  local hops=0
  local parent base parent_abs link d_abs
  while [ "$hops" -le "$RESOLVE_LINK_HOPS" ]; do
    # A directory resolves whole — this is also what normalizes a trailing `/`, a
    # trailing `/.`, a relative path and a symlinked alias, which is why ${PRIMARY_ROOT}
    # can be run through the same function as a file target.
    if [ -d "$fp" ]; then
      d_abs="$(cd "$fp" 2>/dev/null && pwd -P)" || d_abs=""
      if [ -z "$d_abs" ]; then d_abs="$fp"; fi
      "$PRINTF" '%s' "$d_abs"
      return 0
    fi
    parent="$(/usr/bin/dirname "$fp" 2>/dev/null || "$PRINTF" '.')"
    base="$(/usr/bin/basename "$fp" 2>/dev/null || "$PRINTF" '%s' "$fp")"
    if [ -d "$parent" ]; then
      parent_abs="$(cd "$parent" 2>/dev/null && pwd -P)" || parent_abs=""
      if [ -z "$parent_abs" ]; then parent_abs="$parent"; fi
    else
      # No existing ancestor to stand on — the same give-up point the prior code had.
      parent_abs="$parent"
    fi
    fp="${parent_abs%/}/${base}"
    if [ ! -L "$fp" ]; then break; fi
    link="$(/usr/bin/readlink "$fp" 2>/dev/null || "$PRINTF" '')"
    if [ -z "$link" ]; then break; fi
    case "$link" in
      /*) fp="$link" ;;
      *)  fp="${parent_abs%/}/${link}" ;;
    esac
    hops=$((hops + 1))
  done
  "$PRINTF" '%s' "$fp"
}

# resolve_path — python3 os.path.realpath when it is usable, the shell resolver
# otherwise. The python arm is kept as the primary because it resolves a whole symlink
# chain in one call and needs no hop bound; the fallback is what stops an unusable
# python3 from degrading a resolved comparison into a textual one.
resolve_path() {
  local fp="$1"
  [ -z "$fp" ] && return 0
  local abs=""
  if [ -e "$fp" ] && [ -x "$PYTHON3" ]; then
    abs="$("$PYTHON3" -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$fp" 2>/dev/null || "$PRINTF" '')"
  fi
  case "$abs" in
    /*) ;;                                   # python3 answered with an absolute path
    *)  abs="$(resolve_path_shell "$fp")" ;; # absent, unusable, or a non-absolute answer
  esac
  "$PRINTF" '%s' "$abs"
}

# resolve_cwd_path <payload-cwd> — the session working directory through the SAME resolver the
# target and the anchor use (see ANCHOR/TARGET RESOLUTION PARITY on PRIMARY_ROOT below). The cwd
# is the verdict's second input; resolving only the target let an aliased, traversal-bearing,
# relative or trailing-separator spelling of the cwd be adjudicated as text beside a
# canonicalized target. Echoes an absolute path, or NOTHING when the cwd is unresolvable.
#
# THE $PWD FALLBACK COMES FIRST. An empty payload value falls back to the hook process's own
# $PWD — the harness runs a PreToolUse hook with the session's cwd as the process cwd, the same
# second reading lib/scope-guard.sh and block-draft-files.sh already use. The idiom is repeated
# here rather than called from that lib ON PURPOSE: this runs inside the Tier-0 floor, before the
# lib is sourced, and the lib's absence is designed not to gate anything. Only when both
# readings are empty, or the resolver yields no absolute path, is the value unresolvable — and
# only BLOCK-AUTONOMY-002 acts on that.
#
# COST. resolve_path forks python3 for an existing path, so this runs only inside the Write|Edit
# branch and only for a target in one of the two domains. No Bash or mcp call pays for it.
resolve_cwd_path() {
  local raw="${1:-}"
  [ -n "$raw" ] || raw="${PWD:-}"     # D10: pwd fallback — the D-10 differential deletes this line
  [ -n "$raw" ] || return 0           # both readings empty → unresolvable (prints nothing)
  local abs="$raw"
  abs="$(resolve_path "$raw")"        # D9: cwd resolution — the D-9 differential deletes this line
  case "$abs" in
    /*) "$PRINTF" '%s' "$abs" ;;      # resolved
  esac                                # anything else → unresolvable (prints nothing)
  return 0
}

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
#
# ANCHOR/TARGET RESOLUTION PARITY. Every anchored comparison in this hook tests a
# REALPATH-RESOLVED target against this value, so the two must be resolved by the same
# function or they cannot meet. Consumed RAW, four benign shapes of
# CLAUDE_WORKSPACE_ROOT — a trailing slash, a trailing `/.`, a relative path, and a
# symlinked alias — each make EVERY anchored pattern miss. The failure is TOTAL rather
# than partial: the -001 location arms, the projects/ side of -002/-004, and the ceiling's
# projects/ mapping are all anchored on this one value, so a single trailing slash disables
# them outright while every log line still reads normal. The platform side of -002/-004 and
# -001's second stage use the membership anchor instead, which lib/platform-membership.sh
# resolves from the same variable and which is armed on the same four shapes (Suite X,
# X-11..X-14). Anchoring the -001 document entries took the anchored-entry count from 3 to
# 11 and widened that exposure accordingly. An anchored pattern with a mis-resolving anchor is worse than an
# unanchored one, because it reads as safe. resolve_path() is therefore defined ABOVE
# this line, and the four shapes are armed in Suite N of the test file.
# The working directory is the THIRD input and goes through the same function, via
# resolve_cwd_path above; its projects/ comparison uses the operations root resolved the same
# way when that root is a symlink. Its shapes are armed in Suite D of the test file.
PRIMARY_ROOT_RAW="$(resolve_path "${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}")"
readonly PRIMARY_ROOT="$PRIMARY_ROOT_RAW"

# Runtime config + cache locations (the notify-version-skew.sh runtime-read
# convention; XDG cache dir).
readonly OPERATOR_TOML="${HOME}/.config/pmo-platform/operator.toml"
readonly CACHE_FILE="${HOME}/.cache/pmo-platform/autonomy-ceiling"

# --- MODE DETECTION (own .autonomy-mode, NOT the shared .mode) — defined before the
# dependency gate so the gate's severity is mode-coupled and the value is resolvable
# without the helper. ---
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

# log_block — this hook's row in the SHARED block log. `cwd` is the payload value AS RECEIVED,
# the field every hook writing this log records and the one its readers are told is read from
# the payload. `cwd_resolved` is added only on rows whose verdict consumed the working directory
# (BLOCK-AUTONOMY-002 / -004): the resolved value the verdict used, or "" when the cwd was
# unresolvable and -002 failed closed. It carries the same evidentiary limit as `cwd`.
log_block() {
  local rule_id="$1"
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  local tool_input; tool_input="$("$PRINTF" '%s' "$INPUT" | "$JQ" -c '.tool_input // {}')"
  local input_digest; input_digest="$("$PRINTF" '%s' "$tool_input" | "$SHASUM" -a 256 | "$GREP" -oE '^[a-f0-9]+' | /usr/bin/head -c 16)"
  # shellcheck disable=SC2016  # jq filter — single quotes intentional
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg digest "$input_digest" --arg cwd "$CWD" \
    --arg cwd_resolved "${ABS_CWD:-}" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, input_digest:$digest, cwd:$cwd}
     + (if ($rule == "BLOCK-AUTONOMY-002" or $rule == "BLOCK-AUTONOMY-004") then {cwd_resolved:$cwd_resolved} else {} end)' \
    >> "$BLOCK_LOG" 2>/dev/null || true
}

# apply_block — mode-gated block (warn / off / enforce). Used by BOTH mode-gated rules:
# BLOCK-AUTONOMY-004 (the low-risk cross-domain direction) and the STEP-2 ceiling check
# (BLOCK-AUTONOMY-003). NOT used by the irreducible Tier-0 floor (BLOCK-AUTONOMY-001/002),
# which uses always_block below and ignores mode entirely.
#
# This comment read "Used ONLY by the ceiling check" until -004 was added as a second
# caller and the sentence was left behind. It is corrected rather than annotated because a
# declaration that over-claims what it governs is this milestone's own defect class — the
# same shape as the -002 comment that asserted a direction was impossible, and the reason
# a bypass shipped. If a third caller is added, this line changes with it.
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

# Direct resolve from operator.toml. Used as the fallback when the SessionStart cache
# is absent. See the SECTION-AWARE CEILING READ block in the header for why this parses
# the section rather than grepping the key, and why the parse is deliberately no more
# permissive than the reader it replaces.
#
# TWIN COPY — byte-identical to prime-autonomy-ceiling-cache.sh resolve_level_direct().
# Edit both or neither; the primer's test suite asserts they agree on every fixture.
# BEGIN TWIN: resolve_level_direct
resolve_level_direct() {
  # Fail-restrictive on EVERY failure path: unreadable config, absent awk, malformed
  # TOML, absent [automation], absent key, unrecognized value all keep this default.
  # The target is `recommend`, not `off` — this hook gates every mutation and carries the
  # highest false-positive risk in the suite, so the codebase's documented safe direction
  # is "never resolve HIGHER than configured", not "resolve as low as possible".
  local level="recommend"
  local parsed
  if [ -r "$OPERATOR_TOML" ] && [ -x /usr/bin/awk ]; then
    # shellcheck disable=SC2016  # awk field refs ($0) — single quotes intentional
    parsed="$(/usr/bin/awk -v sect='[automation]' '
      # Section header: string-compare (trimmed) against the target header, so a "[" in
      # a value can never be misread as a section and a dotted subtable header such as
      # [automation.experimental] is NOT the target section.
      /^[[:space:]]*\[/ {
        line = $0
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        insect = (line == sect) ? 1 : 0
        next
      }
      # Column-0 anchor (parity with the prior reader) + an "=" terminator (which the
      # prior reader lacked, and whose absence is what admitted the whole prefix class).
      insect == 1 && /^automation_level[[:space:]]*=/ {
        split($0, a, "=")
        v = a[2]
        gsub(/[" ]/, "", v)
        print v
        exit
      }
    ' "$OPERATOR_TOML" 2>/dev/null || true)"
    case "$parsed" in off|recommend|bounded_auto) level="$parsed" ;; esac
  fi
  /usr/bin/printf '%s' "$level"
}
# END TWIN: resolve_level_direct

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

# --- REPOSITORY MEMBERSHIP — one shared helper (#6200) ---
# Membership, not location, decides whether a path belongs to this platform. A working tree of this
# repository counts wherever on disk it lives, and an unrelated repository never does. The question
# is answered by ONE implementation, shared with block-draft-files.sh: lib/platform-membership.sh,
# whose header carries the contract, the anchor rule and the walk's shapes. This hook keeps no
# membership implementation of its own. It maps the helper's answers onto its rules, and each rule
# keeps its own failure direction:
#
#   answer              -001 stage 2    target (-002/-004)                cwd, for -004
#   0 member            BLOCK           pmo-platform                      pmo-platform
#   1 not a member      no block        projects/ prefix, else none       projects/ (resolved), else none
#   2 undeterminable    no block        projects/ prefix, else            projects/ (resolved), else none
#                                       pmo-platform (fails -002 closed)
#   helper unavailable  BLOCK (fails    as 2                              as 2
#                       closed)
#
# The working directory's -002 side is NOT a helper answer: it is location, read twice (payload
# spelling; resolved path) - see the -002 comment. No answer in this table can move it, so a
# missing helper cannot block a platform-engineering session's ordinary writes. An empty resolved
# working directory is #6199's "unresolvable" state, not an answer here.
#
# LOADED LAZILY, NOT MODE-COUPLED. pm_load runs only inside the Write|Edit branch, after -001
# stage 1, so Bash and mcp calls never load the helper and never depend on it. The guard has the
# dependency-resolver guard's shape — readable, parses (`bash -n`), sources, both functions present
# — because a corrupt helper sourced unguarded would abort this hook, and an aborted PreToolUse hook
# fails OPEN. Unlike that guard, a failure here does not degrade by mode. The rules this helper
# serves are the mode-independent floor, so its absence fails THEIR questions closed.
# CLAUDE_HOOK_BYPASS still clears it, because the bypass exits before the Write|Edit branch.
#
# COST. Per Write/Edit: one anchor resolution (one or two subshells) and one walk over the target's
# directory; a second walk, over the resolved working directory, runs only when the target lies in
# a domain. A walk is a bounded loop of `[ -d ]` / `[ -f ]` tests with no subprocess per level and
# at most one canonicalizing subshell where a `.git` entry is met. This replaces the python3 fork
# the old inline walk spent on every relative pointer.
readonly PLATFORM_MEMBERSHIP_LIB="${HOOK_DIR}/lib/platform-membership.sh"
PM_LIB_OK=0
PM_ANCHOR=""
PM_RC=1

# pm_load — source the helper once and resolve the anchor. Never exits; always returns 0.
pm_load() {
  if [ -r "$PLATFORM_MEMBERSHIP_LIB" ] \
     && "${BASH:-/bin/bash}" -n "$PLATFORM_MEMBERSHIP_LIB" 2>/dev/null \
     && . "$PLATFORM_MEMBERSHIP_LIB" 2>/dev/null \
     && command -v platform_membership_of >/dev/null 2>&1 \
     && command -v platform_membership_anchor >/dev/null 2>&1; then
    PM_LIB_OK=1
    PM_ANCHOR="$(platform_membership_anchor)" || PM_ANCHOR=""
  fi
  return 0
}

# pm_member DIR — set PM_RC to this hook's membership code for the physical directory DIR: the
# helper's answer when it is loaded, 1 when there is no platform repository at the anchor, and 2
# when the helper is unavailable. Any status outside 0/1/2 reads as 2. Always returns 0.
pm_member() {
  PM_RC=1
  if [ "$PM_LIB_OK" != 1 ]; then PM_RC=2; return 0; fi
  if [ -z "$PM_ANCHOR" ]; then return 0; fi
  PM_RC=0
  platform_membership_of "${1:-}" "$PM_ANCHOR" || PM_RC=$?
  case "$PM_RC" in 0|1|2) ;; *) PM_RC=2 ;; esac
  return 0
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
#   item 7 — cross-domain bridge writes, HIGH-RISK DIRECTION ONLY (a projects/ cwd
#            writing into pmo-platform/). Item 7 is no longer a single symmetric
#            class: per core/specs/autonomy-tiers.md § Irreducible Human Tasks item 7
#            it splits by direction, and only the direction that can place operations
#            content into the tracked public repo is a Tier-0 floor. The converse
#            direction (a pmo-platform cwd writing into the untracked sibling
#            projects/ tree) is BLOCK-AUTONOMY-004, a mode-gated layer-discipline
#            signal evaluated BELOW the master and scope gates — see #5293 and the
#            comment at that rule.
# Items 1/2/3 (financial / account-creation / security-permission) and items 4/5
# (Stage 9 / Stage 12 gates) are NOT mechanically detectable from a tool payload
# — operator-irreducible by convention, documented, not enforced here.
# Item 8 (destructive outside the workspace) is ALREADY owned by
# block-rm-prefer-trash (BLOCK-TRASH-001/003) — C5 does NOT duplicate it.

# --- Cross-domain locals, declared UNCONDITIONALLY (#5293) ---
# These two are ASSIGNED inside the Write|Edit branch below, but BLOCK-AUTONOMY-004
# READS them further down — after the master-activation and workspace-scope gates,
# outside any `case "$TOOL_NAME"` branch. This hook runs `set -euo pipefail` (see the
# top of the file), so under `nounset` a read of an unassigned name is not an empty
# string: it aborts the shell. Every Bash call and every mcp__* call skips the Write|Edit
# branch entirely, which would make the -004 read fatal for the two highest-traffic
# matchers this hook declares — and an aborted PreToolUse hook does not deny, it fails
# OPEN. Declaring here costs two lines and closes that class outright.
#
# The branch below re-initialises both before its own `case` statements. That is
# deliberate redundancy, not a leftover: this declaration exists solely to make the
# read below the gates safe, and the branch stays self-contained so it does not
# silently depend on a line eighty lines above it.
target_domain=""   # H1: see above — read below the gates, so it cannot be branch-local
cwd_domain=""      # H1: see above — read below the gates, so it cannot be branch-local
# ABS_CWD is IP-1: the resolved working directory the cwd classification consumes — an absolute
# path, or EMPTY meaning unresolvable. Assigned only inside the Write|Edit branch, but read by
# log_block, which also runs on the -001 and ceiling paths that never assign it.
ABS_CWD=""         # H1-class: read by log_block outside the branch that assigns it

if [ -n "$ABS_TARGET" ]; then
  case "$TOOL_NAME" in
    Write|Edit)
      # --- BLOCK-AUTONOMY-001 — Tier-0 item 6: governance-file modification ---
      # The governance set per autonomy-tiers.md item 6 + CLAUDE.md "No ungoverned
      # changes": CLAUDE.md, OPERATIONS.md, RELEASE_PROTOCOL.md, the settings.json
      # security file, and the security hooks/rules. Matched by resolved path. This
      # is the autonomy-tier dimension of the same surface block-destructive
      # BLOCK-DESTRUCTIVE-019 guards — but C5's floor is level/mode-independent and
      # does NOT carve out the worktree exemption (governance edits are
      # operator-irreducible regardless of cwd).
      #
      # SKILL.md IS DELIBERATELY NOT IN THIS SET — see #5515.
      # Every other member has no sanctioned agent-editing path, which is what makes an
      # unconditional block the right instrument for them. Skills are the exception: they
      # have a purpose-built editing skill (pmo-skill-editor) and a purpose-built gate
      # (block-skill-direct-edit.sh, BLOCK-SKILL-EDIT-002) covering BOTH SKILL.md and
      # references?/*.md with discriminations this hook lacks — migration-marker scoping,
      # session-target matching, a 30-minute TTL, and an exemption surface.
      #
      # Carrying SKILL.md here duplicated that gate with a blunter instrument AND, because
      # always_block ignores every signal including the session sentinel, made the
      # sanctioned path structurally unreachable: a valid pmo-skill-editor session
      # satisfied Gate 2 and was still denied here. The observable result was an agent
      # that followed every documented instruction, declined every offered bypass, and
      # still could not proceed — which reads as over-caution and is a broken contract.
      #
      # This does NOT make skills agent-writable at will. Gate 2 still denies a direct
      # edit to any migrated skill absent a live, correctly-targeted, non-stale session
      # sentinel. The assertion moves from "no agent may edit a skill" to "no agent may
      # edit a skill outside a sanctioned session" — which is what the surrounding design
      # already assumed was true.
      #
      # EVERY ENTRY IS LOCATION-ANCHORED — see #5812.
      # A governance file is identified by WHERE it sits, never by its basename alone.
      # The three document entries used to be bare basename globs (*/CLAUDE.md,
      # */OPERATIONS.md, */RELEASE_PROTOCOL.md) while the settings/hooks/rules entries
      # were already ${PRIMARY_ROOT}-anchored. That asymmetry was the defect: */CLAUDE.md
      # matches ANY file so named anywhere on disk, so an unrelated product repository
      # whose root doc carries the conventional name CLAUDE.md had that file blocked as
      # though it were this platform's charter — and because always_block ignores mode
      # and level, no configuration could permit the write. The observable result was the
      # same broken contract the SKILL.md removal above describes: an agent holding an
      # approved edit, with no sanctioned path and no bypass it is permitted to take.
      #
      # Two anchors, both load-bearing:
      #   ${PRIMARY_ROOT}              — the workspace root. The charter itself, plus the
      #                                  deployed .claude/ security surface.
      #   ${PRIMARY_ROOT}/pmo-platform — the platform checkout. Its in-repo governance
      #                                  documents at ANY depth, which covers worktrees
      #                                  NESTED UNDER THE CHECKOUT.
      # Each in-repo basename therefore carries BOTH a checkout-root and a subpath
      # pattern, for the reason BLOCK-AUTONOMY-002 below spells out in its own comment:
      # the trailing-slash glob alone would miss a target sitting directly at the root.
      #
      # THE ANCHORS DO NOT COVER EVERY WORKTREE, and this comment used to compose into a
      # claim that they did. "Worktrees nested under the checkout stay covered" and "a
      # same-named file anywhere else falls through" are each true in isolation and read
      # together as "all worktrees are covered" — which is false for any worktree created
      # outside ${PRIMARY_ROOT}/pmo-platform, the shape a spawned session actually gets.
      # That case is covered by the SECOND STAGE below, which asks the shared membership helper
      # (lib/platform-membership.sh) — repository membership rather than location. This floor
      # grants no worktree exemption; before that stage existed, it silently had one.
      #
      # The location anchoring narrows the rule deliberately. A CLAUDE.md that is NOT at
      # one of these locations AND not inside a working tree of this repository — another
      # repository's root doc, a backup copy — falls through to the normal mode- and
      # level-dependent path, where the rest of the hook suite still applies. That
      # fall-through IS the fix, not a hole.
      #
      # THE OPERATIONS CONTEXT ANCHOR IS AN EXPLICIT THIRD LOCATION — see #5293.
      # ${PRIMARY_ROOT}/projects/CLAUDE.md is the operations context anchor:
      # installer-produced, pointer-only, and agent-unwritable per operations-bridge.md
      # § Context-Load Contract. The bare */CLAUDE.md glob had been covering it
      # incidentally, so anchoring dropped it — and nothing else picks it up.
      # BLOCK-AUTONOMY-002 does not: -002 guards a projects cwd writing INTO
      # pmo-platform, whereas editing the anchor is a projects-rooted session writing
      # inside its OWN domain, which is not a cross-domain write in either direction.
      # It is therefore named here, at its exact path, rather than left to a prefix:
      # a project's own ${PRIMARY_ROOT}/projects/<Project>/CLAUDE.md is NOT the anchor
      # and is correctly outside this set.
      case "$ABS_TARGET" in
        "${PRIMARY_ROOT}/CLAUDE.md" \
        | "${PRIMARY_ROOT}/projects/CLAUDE.md" \
        | "${PRIMARY_ROOT}/pmo-platform/CLAUDE.md" \
        | "${PRIMARY_ROOT}/pmo-platform/"*"/CLAUDE.md" \
        | "${PRIMARY_ROOT}/pmo-platform/OPERATIONS.md" \
        | "${PRIMARY_ROOT}/pmo-platform/"*"/OPERATIONS.md" \
        | "${PRIMARY_ROOT}/pmo-platform/RELEASE_PROTOCOL.md" \
        | "${PRIMARY_ROOT}/pmo-platform/"*"/RELEASE_PROTOCOL.md" \
        | "${PRIMARY_ROOT}/.claude/settings.json" \
        | "${PRIMARY_ROOT}/.claude/hooks/"* \
        | "${PRIMARY_ROOT}/.claude/rules/"*)
          always_block "BLOCK-AUTONOMY-001" \
            "governance-file modification is an irreducible Tier-0 action (operator-only per 'No ungoverned changes'); blocked regardless of automation_level. Target: ${ABS_TARGET}" \
            "governance changes require Issue + plan + operator approval — make the change through the governed flow, or set CLAUDE_HOOK_BYPASS=1 only if you ARE the operator acting intentionally"
          ;;
      esac

      # --- Membership (#6200): load the shared helper and place the TARGET's directory once.
      #     -001 stage 2 and the target side of -002/-004 read this one answer, so the two rules
      #     cannot classify one working copy differently. The working directory is placed later,
      #     inside the target-domain gate, from #6199's resolved value (ABS_CWD) - never here. ---
      pm_load
      PM_TARGET_DIR="${ABS_TARGET%/*}"
      if [ -z "$PM_TARGET_DIR" ]; then PM_TARGET_DIR="/"; fi
      pm_member "$PM_TARGET_DIR"; PM_TARGET_RC="$PM_RC"

      # --- BLOCK-AUTONOMY-001, SECOND STAGE: working trees of THIS repository that
      #     live OUTSIDE the checkout anchor ---
      # The anchored case above is the fast path and settles ${PRIMARY_ROOT} and every path
      # beneath the checkout. It cannot settle a linked worktree created elsewhere, because
      # no prefix can name an arbitrary location. This stage asks the one question that
      # survives relocation — does this working tree belong to THIS repository — and asks
      # it ONLY for the three governance basenames, so the walk never touches the hot path.
      #
      # SCOPE IS THE THREE DOCUMENTS, deliberately, and not the .claude/ entries above.
      # Those name the DEPLOYED security surface at the workspace root; the repository
      # tracks no .claude/ files at all, so there is no worktree copy of them to reach.
      # Stating that here rather than leaving it to be inferred: the coverage this stage
      # adds is exactly CLAUDE.md, OPERATIONS.md and RELEASE_PROTOCOL.md.
      #
      # PARSER NOTE: release/tools/tests/test_agent_editability_read.sh derives the Tier-0
      # basename union from the single-line arm below at run time. Keep that arm on one line,
      # keep this block free of a nested case/esac, and keep every `)` line in it free of a
      # file basename before the `)`.
      case "$ABS_TARGET" in
        */CLAUDE.md|*/OPERATIONS.md|*/RELEASE_PROTOCOL.md)
          if [ "$PM_LIB_OK" != 1 ]; then
            always_block "BLOCK-AUTONOMY-001" \
              "LIB-MISSING: governance-file modification cannot be cleared by repository membership, because lib/platform-membership.sh is unavailable or invalid; this floor fails closed rather than reading not-a-member. Target: ${ABS_TARGET}" \
              "reinstall the hook bundle — docs/scripts/setup-workspace.sh --refresh-hooks, which update.sh delegates to — to restore the helper; set CLAUDE_HOOK_BYPASS=1 only if you ARE the operator acting intentionally"
          fi
          if [ "$PM_TARGET_RC" = 0 ]; then
            always_block "BLOCK-AUTONOMY-001" \
              "governance-file modification is an irreducible Tier-0 action (operator-only per 'No ungoverned changes'); blocked regardless of automation_level. This target sits in a working tree of the platform repository located outside ${PRIMARY_ROOT}/pmo-platform — the working copy is transient, the commit it feeds is not. Target: ${ABS_TARGET}" \
              "governance changes require Issue + plan + operator approval — make the change through the governed flow, or set CLAUDE_HOOK_BYPASS=1 only if you ARE the operator acting intentionally"
          fi
          ;;
      esac

      # --- BLOCK-AUTONOMY-002 — Tier-0 item 7, HIGH-RISK DIRECTION ONLY ---
      # Layer separation between Engineering (pmo-platform) and Operations (projects),
      # detected by a PAIR - the target's domain and the working directory's side:
      #   * the TARGET is pmo-platform when it sits in any working tree of this repository,
      #     wherever that tree lives (REPOSITORY MEMBERSHIP, placed above); otherwise projects
      #     when its resolved path is under the operations root - the root itself OR any subpath
      #     (the trailing-slash glob alone would miss a target that IS exactly `${ROOT}/projects`).
      #     Membership comes first, so for every working tree of this checkout's repository a
      #     write "into projects/" is by construction a write into no platform working tree: a
      #     platform worktree nested under projects/ is classified pmo-platform. A separate clone
      #     of the platform remote is a different repository to git and is not a member.
      #   * the WORKING DIRECTORY is on the operations side when EITHER reading puts it under
      #     projects/: its payload spelling under ${PRIMARY_ROOT}/projects, or its RESOLVED path
      #     (resolve_cwd_path - the target's own resolver) under the operations root resolved the
      #     same way. Both readings are used only to BLOCK, never to allow, and membership masks
      #     neither, so a projects-spelled working directory that resolves into a platform tree is
      #     still the operations side. A working directory that cannot be resolved fails closed
      #     on this rule alone (see the fail-closed arm after it).
      #
      # THE TWO DIRECTIONS ARE NOT THE SAME CONTROL — see #5293.
      # The domains are SIBLING directories, not nested: pmo-platform is a git repo and
      # is public; projects is not a git repo and is not in the repo's path space at all.
      # Only ONE direction can therefore put content somewhere it can be committed and
      # pushed:
      #
      #   projects cwd -> pmo-platform target  — operations content entering the tracked
      #       PUBLIC repo. A genuine disclosure control, and an irreducible Tier-0 floor:
      #       always_block, mode- and level-independent, above the master gate. THIS rule.
      #
      #   pmo-platform cwd -> projects target  — an engineering checkout writing into the
      #       untracked sibling operations tree. git cannot see the target, so nothing can
      #       reach the repo. This is a layer-discipline signal with no disclosure
      #       component, and enforcing it at always_block severity made the control
      #       blunter than the risk it models. It is now BLOCK-AUTONOMY-004, mode-gated,
      #       below the master and scope gates.
      #
      # Narrowing this rule to one direction must not widen it by even one path, which is
      # why the condition names both domains explicitly rather than testing inequality:
      # an inequality test would silently re-admit the other direction if a third domain
      # were ever added.
      target_domain=""
      if [ "$PM_TARGET_RC" = 0 ]; then
        target_domain="pmo-platform"
      else
        case "$ABS_TARGET" in
          "${PRIMARY_ROOT}/projects"|"${PRIMARY_ROOT}/projects/"*) target_domain="projects" ;;
        esac
        if [ -z "$target_domain" ] && [ "$PM_TARGET_RC" = 2 ]; then
          target_domain="pmo-platform"   # undeterminable outside projects/ fails -002 closed
        fi
      fi

      # --- The working directory: resolved once (#6199), then read for two questions ---
      # Resolved only when the target lies in a domain - the only writes whose verdict the working
      # directory can change (-002 needs a pmo-platform target, -004 a projects one). Two facts,
      # one question each, because the two rules ask different things of the same directory:
      #   cwd_domain         - its DOMAIN: "unresolvable" (no absolute resolution: -002 fails
      #                        closed on it, nothing else acts on it), "pmo-platform" (it sits in a
      #                        working tree of this repository - REPOSITORY MEMBERSHIP, read by
      #                        -004), "projects" (not a member, resolved under the operations
      #                        root), or "" (neither). An undeterminable membership answer is NEVER
      #                        "unresolvable": that value means only that ABS_CWD is empty.
      #   cwd_under_projects - -002's OPERATIONS SIDE: 1 when EITHER reading puts it under
      #                        projects/ - ABS_CWD against the operations root resolved the same
      #                        way, or its payload spelling. Location only: the helper is never
      #                        consulted, so a missing helper cannot move -002's working-directory
      #                        side, and membership cannot mask it.
      # The scope gate below keeps receiving the RAW payload value.
      cwd_domain=""
      cwd_under_projects=0
      PM_CWD_RC=1
      if [ -n "$target_domain" ]; then
        ABS_CWD="$(resolve_cwd_path "$CWD")" || ABS_CWD=""
        if [ -z "$ABS_CWD" ]; then
          cwd_domain="unresolvable"
        else
          # The operations root, spelled the way ABS_CWD is: resolved only when it is a symlink,
          # so the default layout pays no extra resolver call.
          projects_root="${PRIMARY_ROOT}/projects"
          if [ -L "$projects_root" ]; then
            projects_root="$(resolve_path "$projects_root")" || projects_root="${PRIMARY_ROOT}/projects"
          fi
          case "$ABS_CWD" in
            "$projects_root"|"$projects_root/"*) cwd_under_projects=1 ;;   # reading 1: resolved
          esac
          pm_member "$ABS_CWD"; PM_CWD_RC="$PM_RC"
          if [ "$PM_CWD_RC" = 0 ]; then cwd_domain="pmo-platform"; fi
          if [ -z "$cwd_domain" ] && [ "$cwd_under_projects" = 1 ]; then cwd_domain="projects"; fi
          case "$CWD" in
            "${PRIMARY_ROOT}/projects"|"${PRIMARY_ROOT}/projects/"*) cwd_under_projects=1 ;;   # reading 2: as spelled
          esac
        fi
      fi

      if [ "$cwd_under_projects" = 1 ] && [ "$target_domain" = "pmo-platform" ]; then
        if [ "$PM_TARGET_RC" = 0 ]; then
          always_block "BLOCK-AUTONOMY-002" \
            "cross-domain bridge write into the tracked platform repository is an irreducible Tier-0 action (Layer separation; an Operations cwd writing into pmo-platform/, where the content becomes committable and pushable on a public repository); blocked regardless of automation_level or mode. Target: ${ABS_TARGET}" \
            "platform-engineering changes belong to an engineering session — relaunch in the pmo-platform checkout and make the change there, where it is reviewable as a diff; if you ARE the operator acting intentionally, CLAUDE_HOOK_BYPASS=1 disables every security hook for this one call"
        fi
        if [ "$PM_LIB_OK" != 1 ]; then
          always_block "BLOCK-AUTONOMY-002" \
            "LIB-MISSING: cross-domain bridge write from an Operations working directory into a target whose repository membership cannot be determined, because lib/platform-membership.sh is unavailable or invalid; this Tier-0 floor fails closed rather than reading the target as outside the platform repository. Target: ${ABS_TARGET}" \
            "reinstall the hook bundle — docs/scripts/setup-workspace.sh --refresh-hooks, which update.sh delegates to — to restore the helper; until it is restored, a session rooted under projects/ cannot write outside projects/. Set CLAUDE_HOOK_BYPASS=1 only if you ARE the operator acting intentionally"
        fi
        always_block "BLOCK-AUTONOMY-002" \
          "UNDETERMINABLE: cross-domain bridge write from an Operations working directory into a target whose repository membership could not be determined (a .git pointer file with no pointer line, a path beyond the walk bound, or a target that did not resolve to an absolute path); this Tier-0 floor fails closed rather than reading the target as outside the platform repository. Target: ${ABS_TARGET}" \
          "repair or remove the corrupt .git pointer above the target, or make the change from a session rooted outside projects/ if it is platform-engineering work; set CLAUDE_HOOK_BYPASS=1 only if you ARE the operator acting intentionally"
      fi

      # --- BLOCK-AUTONOMY-002, fail-closed arm (#6199) ---
      # A check that cannot read its input still checks. With the working directory unresolvable
      # the Operations direction cannot be ruled out, and this floor exists for the direction that
      # can put content into a public repository — so the write is blocked instead of the unreadable
      # value being trusted as "neither domain". This binds -002 ONLY: -004 does not fire on it, and
      # the scope gate keeps its own INVERTED direction (lib/scope-guard.sh clause 1) — opposite
      # directions stay in separate branches. Reached only when the payload cwd AND the process
      # $PWD are both empty, or the resolver yields no absolute path — never for a payload that
      # merely omits cwd.
      if [ "$cwd_domain" = "unresolvable" ] && [ "$target_domain" = "pmo-platform" ]; then
        always_block "BLOCK-AUTONOMY-002" \
          "cross-domain bridge write into the tracked platform repository from a working directory that could not be resolved (the payload cwd and the hook process's working directory are both empty, or neither resolves to an absolute path), so the Operations direction cannot be ruled out; this Tier-0 floor fails closed rather than trusting an unreadable value. Target: ${ABS_TARGET}" \
          "relaunch the session from a working directory that exists — the pmo-platform checkout for platform-engineering work — so the direction can be evaluated; if you ARE the operator acting intentionally, CLAUDE_HOOK_BYPASS=1 disables every security hook for this one call"
      fi
      ;;
  esac
fi

# --- Master-activation gate (#310) — layer 2. CLASS=workflow, but DELIBERATELY placed
# HERE — after the STEP-1 Tier-0 always-block floor (BLOCK-AUTONOMY-001/002) and before
# everything mode-gated — so master-OFF disables ONLY the mode-gated rules, NEVER the
# irreducible floor (D-R9: the Tier-0 floor is always-enforce, like the security class; a
# governance-file write, or a cross-domain bridge write INTO the tracked repo, stays
# blocked even under master-OFF).
# Everything below this line is mode-gated: BLOCK-AUTONOMY-004 as well as the STEP-2
# ceiling. Under master-OFF neither is reached — see the -004 comment for why that is
# the intended semantics for the low-risk direction and not a regression (#5293).
# Precedence for this hook: bypass -> floor -> master -> SCOPE -> -004 -> ceiling.
# Fail-toward-current-behavior: a missing lib does NOT gate. ---
readonly MASTER_ENABLE_CLASS="workflow"
readonly MASTER_LIB="${HOOK_DIR}/lib/master-enable.sh"
if [ -r "$MASTER_LIB" ]; then . "$MASTER_LIB" 2>/dev/null || true; fi
if command -v master_enable_gate >/dev/null 2>&1; then master_enable_gate "$MASTER_ENABLE_CLASS"; fi

# --- Workspace-scope gate (#4436) — layer 3, DELIBERATELY placed HERE, immediately
# after the master-activation gate and therefore AFTER the STEP-1 Tier-0 always-block
# floor — exactly mirroring where this hook already places master-activation, and for
# the same reason. The Tier-0 floor is PATH-scoped, not session-scoped: it blocks
# writes INTO the governed tree (governance files, the Engineering/Operations bridge),
# so bounding it by the SESSION's working directory would gate it on the wrong axis and
# open the floor to an out-of-tree session. Scope therefore gates the mode-gated rules
# only — BLOCK-AUTONOMY-004 as well as the STEP-2 ceiling (#5293; -004 IS session-scoped
# by nature, since a session outside the governed tree has no layer boundary to observe).
# Precedence for this hook: bypass -> floor -> master -> SCOPE -> -004 -> ceiling.
# It receives the RAW payload cwd, deliberately: the resolved value (ABS_CWD) feeds only the
# domain classification above, and the two consumers fail in OPPOSITE directions on an
# undeterminable working directory — -002 closed, this gate inert — so they must not share a
# value or a branch.
# Inverted fail direction on the cwd axis, NOT on the lib axis. See lib/scope-guard.sh. ---
readonly SCOPE_GUARD_LIB="${HOOK_DIR}/lib/scope-guard.sh"
if [ -r "$SCOPE_GUARD_LIB" ]; then . "$SCOPE_GUARD_LIB" 2>/dev/null || true; fi
if command -v scope_guard_gate >/dev/null 2>&1; then scope_guard_gate "$CWD"; fi

# --------------------------------------------------------------------------
# BLOCK-AUTONOMY-004 — cross-domain bridge writes, LOW-RISK DIRECTION (#5293)
# --------------------------------------------------------------------------
# Fires when a pmo-platform cwd writes into projects/ — an engineering checkout
# writing the untracked sibling operations tree. See the BLOCK-AUTONOMY-002 comment
# in STEP 1 for why the two directions are not one control; in short, this one cannot
# reach the tracked repository, so it is a layer-discipline signal rather than a
# disclosure floor. Routed through apply_block, so it honours .autonomy-mode:
# warn → warn-log + allow · enforce → block · off → allow.
#
# THREE PROPERTIES OF THIS PLACEMENT, ALL DELIBERATE, ALL WORTH STATING:
#
# 1. It is BELOW the master-activation gate, so master-OFF disables -004 while leaving
#    -002 (above the gate) fully enforced. That asymmetry is the whole point of the
#    directional split and is not a regression. Note the consequence honestly: master-OFF
#    is the SHIPPED default, so on a fresh install -004 contributes nothing at all — not
#    a block, not a warn, not a log row. The warn-log audit trail this rule offers exists
#    only where the operator has enabled the security-hook suite.
#
# 2. It is also below the WORKSPACE-SCOPE gate, which means -004 is inert for a session
#    rooted outside the governed tree. Correct for a layer-discipline signal — a session
#    with no layer has no layer to discipline — but it makes the scope-gate comment
#    directly above incomplete as written: scope no longer gates ONLY the STEP-2 ceiling.
#    The hook's full precedence is: bypass -> floor -> master -> SCOPE -> -004 -> ceiling.
#
# 3. apply_block exits in every mode branch, so a -004 firing means STEP 2 never runs and
#    BLOCK-AUTONOMY-003 is structurally unreachable on this path. The observable
#    divergence is confined to enforce-mode with a permissive ceiling, where a
#    pmo-platform → projects/ write blocks at -004 though the same target from a projects
#    cwd would pass the ceiling. That is the layer signal out-ranking the tier ceiling,
#    which is the intended ordering.
#
# target_domain / cwd_domain are read here but ASSIGNED in STEP 1's Write|Edit branch.
# They are declared unconditionally near the top of STEP 1 because `set -u` would
# otherwise abort this hook on every Bash and mcp call — see the H1 comment there.
if [ "$cwd_domain" = "pmo-platform" ] && [ "$target_domain" = "projects" ]; then
  apply_block "BLOCK-AUTONOMY-004" \
    "cross-domain bridge write out of the platform checkout (an Engineering cwd writing into projects/, the Cowork-owned operations workspace). The target is outside the repository, so this is a layer-discipline signal, not a disclosure control. Target: ${ABS_TARGET}" \
    "operations work should be launched from the operations workspace (${PRIMARY_ROOT}/projects/…), not a repo checkout — relaunch there and this write is in-domain; to change the posture instead, set .autonomy-mode to warn"
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
