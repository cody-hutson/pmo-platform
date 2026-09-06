#!/usr/bin/env bash
# block-external-seam-shape.sh — PreToolUse hook: refuse register-shaped agent
# content on an external-seam comment write.
# hook-owner: core/disciplines/external-seam-conduct.md
#
# WHAT IT DOES (content-shape gate on ONE surface — payload-triggered):
#   An external seam is a human-facing system the platform integrates with. On that
#   surface the record body is the state and the comment stream is conversation
#   between people; on the platform's OWN work tracker the comment stream IS the
#   audit trail and a dated evidence-bearing comment is correct. This hook detects
#   the register idiom being carried across that contract boundary.
#
# THE SURFACE GATE IS THE LOAD-BEARING PART, AND IT IS VERB-ANCHORED.
#   S1a  tool_name matches ^mcp__  (the structured connected-system surface).
#   S1b  AND a content-bearing WRITE VERB in the anchored position — the shipped
#        filing subset from block-scope-segregation.sh's STEP 1, in the
#        block-mcp-writes.sh:88 anchored shape (verb then _, uppercase, or end,
#        so snake_case and camelCase both terminate). ONE stated extension:
#        `reply`, a content-bearing comment verb neither shipped list carries.
#   S1c  AND a comment-class noun anywhere in the name.
#   Bash is OUT OF SCOPE, UNCONDITIONALLY — the platform's own tracker is reached
#   that way, and excluding it is what makes the register prohibition TRUE rather
#   than merely strict.
#
#   The verb conjunct is not optional and not stylistic. A noun-only key matches
#   READ-family names (list_..._thread_comments, get...PageFooterComments,
#   list_discussions). Those carry no content field, so they would reach the
#   fail-loud arm below and warn on every comment READ — and block one at enforce.
#   A verb is a property of the operation; a vendor name is not. Nothing here is
#   keyed on a tool-name allowlist, a server identifier, or a product name.
#
# ENFORCEMENT POSTURE:
#   FL-1  Fail-LOUD content extraction. On an in-scope surface an empty or
#         unparseable extraction is would-block(warn)/block(enforce), NEVER a
#         silent allow — the CD-3 analogue from block-scope-segregation.sh:452-461.
#         block-scope-segregation.sh:33-37 records that empty extraction is the
#         COMMON case on this surface, so a detector that reads green on it has
#         verified nothing.
#   FL-2  Every extracted key is type-guarded. A key holding a structured document
#         rather than a string is walked for its strings instead of being handed to
#         `join`, which raises on a non-string member — and the raise would be
#         swallowed into an empty result indistinguishable from a genuinely empty
#         payload, firing FL-1 on exactly the well-formed payloads it most needs to
#         read.
#   FL-3  BLOCK-SEAM-SHAPE-004 (budget) is PERMANENTLY WARN-ONLY, on its own
#         per-rule constant. The discipline states the budget as a ceiling a
#         genuinely warranted reply may exceed and say why; that justification is
#         absent from the payload, so an enforce path for this rule would enforce
#         something the discipline does not say. The per-rule constant is the shape
#         block-destructive.sh already uses for its phase-gated arms.
#
# Matcher scope: mcp__.*  (comment-class filing surfaces only). Fires on every MCP
#   call → the surface early-exit is load-bearing.
# Rule IDs: BLOCK-SEAM-SHAPE-001..099
# Mode gating: own .seam-shape-mode (warn / enforce / off). Initial = warn.
#   Deliberately NOT the shared .mode: a flip-to-enforce here must promote this rule
#   on its own evidence rather than dragging unrelated hooks with it.
# Budget: [external_seam].comment_word_budget in the operator's own operator.toml;
#   absent → 250 (the executive-tier word budget the comms corpus already ships).
#   Self-documenting at the edit surface — no central list to drift.

set -euo pipefail

# --- PATH PINNING (tamper resistance) ---
export PATH="/usr/bin:/bin"

readonly GREP="/usr/bin/grep"
readonly PRINTF="/usr/bin/printf"
readonly CAT="/bin/cat"
readonly TR="/usr/bin/tr"
readonly DATE="/bin/date"
readonly SHASUM="/usr/bin/shasum"
readonly SED="/usr/bin/sed"
readonly HEAD="/usr/bin/head"
readonly WC="/usr/bin/wc"
readonly AWK="/usr/bin/awk"
# jq is resolved below via lib/dep-resolve.sh (once HOOK_DIR is known), from a fixed
# absolute-path allowlist — never $PATH — so the anti-hijack PATH pin still holds
# (GHSA-9cjm-v22x-4x33).

# --- METADATA ---
readonly HOOK_NAME="block-external-seam-shape"
HOOK_DIR_RAW="$(cd "$(dirname "$0")" && pwd -P)"
readonly HOOK_DIR="$HOOK_DIR_RAW"
readonly ERROR_LOG="${HOOK_DIR}/hook-errors.log"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"
readonly WARN_LOG="${HOOK_DIR}/seam-shape-warn-log.jsonl"
readonly MODE_FILE="${HOOK_DIR}/.seam-shape-mode"

# Runtime operator config (the block-scope-segregation.sh runtime-read convention;
# XDG config dir). HOME-relative so a sandboxed HOME redirects it deterministically.
readonly OPERATOR_TOML="${HOME}/.config/pmo-platform/operator.toml"
readonly BUDGET_DEFAULT=250

# --- MODE DETECTION (own .seam-shape-mode; default warn) — defined before the
# dependency gate so the gate's severity is mode-coupled and the value is
# resolvable without the helper. ---
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

# --- LIB-GUARD MODE SNAPSHOT (resolved BEFORE the dependency guard, frozen readonly) ---
# The guard below sources $DEP_LIB inside its own condition, so by the time the guard's
# failure branch runs, everything that file defines is already in THIS shell — including
# a get_mode of its own. Resolving the mode inside the branch would let the artifact
# under adjudication choose its own verdict. Resolve it here and freeze it: a sourced
# file cannot overwrite a readonly.
LIB_GUARD_MODE="$(get_mode)"; readonly LIB_GUARD_MODE

# --- SHARED DEPENDENCY RESOLVER (mode-coupled: fail CLOSED in enforce, degrade in
# warn/off). Test readability BEFORE sourcing: bash 3.2 (macOS system bash) exits 1
# on a failed `.` of a missing file even inside an `if !` condition, and exit 1
# (unlike exit 2) is NON-blocking in the PreToolUse contract — a missing helper would
# fail OPEN. ---
readonly DEP_LIB="${HOOK_DIR}/lib/dep-resolve.sh"
# shellcheck source=lib/dep-resolve.sh disable=SC1090,SC1091
if [ ! -r "$DEP_LIB" ] || ! "${BASH:-/bin/bash}" -n "$DEP_LIB" 2>/dev/null || ! . "$DEP_LIB" 2>/dev/null || ! command -v resolve_jq >/dev/null 2>&1 || ! command -v deny_missing_primitive >/dev/null 2>&1; then
  if [ "$LIB_GUARD_MODE" = "enforce" ]; then
    "$PRINTF" '[CLAUDE-HOOK:%s:LIB-MISSING] BLOCKED (fail-closed): dependency helper lib/dep-resolve.sh unavailable or invalid.\n' "$HOOK_NAME" >&2
    exit 2
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:LIB-MISSING] WARN (degraded, %s=%s): dependency helper lib/dep-resolve.sh unavailable or invalid; ALL rules for this hook are skipped this run. Reinstall the hook bundle (re-run docs/scripts/setup-workspace.sh) to restore enforcement.\n' "$HOOK_NAME" "${MODE_FILE##*/}" "$LIB_GUARD_MODE" >&2
  exit 0
fi
JQ="$(resolve_jq)"; readonly JQ

# --- SURFACE KEY (S1b ∧ S1c) ---
# S1b — content-bearing filing verbs in the block-mcp-writes.sh:88 anchored shape.
# The verb set is the shipped filing subset (block-scope-segregation.sh STEP 1) plus
# the one stated extension `reply`. Deliberately NARROWER than the full MCP write-verb
# vocabulary: delete / remove / archive / share / transition / permission are writes
# but carry no authored content, so admitting them would send every comment DELETE
# into the fail-loud arm below.
#
# SERVER SEGMENT — `.+`, deliberately, and NOT the `[^_]+` the four sibling
# detectors use. `__` is the delimiter in `mcp__<server>__<tool>`, so a server id
# that itself contains `_` makes the split ambiguous, and `[^_]+` resolves that
# ambiguity by refusing to match at all — the tool escapes the detector silently
# while carrying an in-scope verb and a comment noun. A silent miss is the one
# failure this discipline does not tolerate, so the ambiguity is resolved the
# other way: `.+` is greedy, so the LAST `__` before the verb becomes the
# delimiter, which is the correct boundary on every real name measured
# (`mcp__Word__By_Anthropic___add_comment` -> verb `add`).
#
# Widening here cannot regress: `[^_]+` is a strict SUBSET of `.+`, so every name
# the old class matched the new one still matches — verified over 4000 synthetic
# names (0 regressions, 337 new catches) and over the 216 live tool names of a
# real session (0 newly blocked, 0 lost — the gap is latent, not active). Nor can
# it over-block: scope is decided by the verb set and by the S1c comment-noun
# gate, and a name reaching both is in scope whatever its server is called.
# A charset enumeration (`[A-Za-z0-9_-]+`) was the runner-up and was rejected for
# re-opening a narrower version of this same silent-miss hole on the first server
# id using a character outside the class. A lazy `.+?` is not POSIX ERE, and for
# a boolean match it is anyway equivalent to the greedy form under backtracking.
#
# RESIDUAL: the identical `[^_]+` server class ships in four sibling detectors —
# audit-mcp-usage.sh:87, block-autonomy-ceiling.sh:898, block-mcp-writes.sh:88,
# block-scope-segregation.sh:322 — and is NOT changed here. See § 8 Limitations
# of core/disciplines/external-seam-conduct.md; this hook closes its own gap only.
readonly SEAM_WRITE_VERB_RE='^mcp__.+__(create|add|comment|post|insert|update|edit|replace|reply)(_|[A-Z]|$)'
# S1c — comment-class noun anywhere in the tool name, case-insensitive.
readonly SEAM_COMMENT_NOUN_RE='[Cc]omment|[Dd]iscussion|[Nn]ote|[Rr]eply|[Tt]hread'

# --- ERROR HANDLERS ---
log_error() {
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$PRINTF" '%s [%s] %s\n' "$ts" "$HOOK_NAME" "$1" >> "$ERROR_LOG" 2>/dev/null || true
}

# Fail-CLOSED on rule-evaluation error (exit 2 blocks) — a control that errors must
# not fail open. Mirrors block-scope-segregation.sh's ERR posture.
# shellcheck disable=SC2154
trap 'rc=$?; log_error "RULE-EVAL-ERROR at line $LINENO (exit $rc)"; "$PRINTF" "[CLAUDE-HOOK:%s:HOOK-ERROR] BLOCKED: rule-eval error at line %s (exit %s). See %s.\n" "$HOOK_NAME" "$LINENO" "$rc" "$ERROR_LOG" >&2; exit 2' ERR

# --- READ INPUT (jq-free; stdin is consumed exactly once) ---
INPUT="$(cat)"

# --- CLAUDE_HOOK_BYPASS escape hatch — evaluated BEFORE the jq gate so it works even
# when jq is unresolvable (GHSA-9cjm-v22x-4x33). ---
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

# --- Master-activation gate — layer 2, AFTER CLAUDE_HOOK_BYPASS and BEFORE the
# .seam-shape-mode read. CLASS=workflow: this is a CONDUCT hook, not a security/floor
# guard. Its failure mode is a badly-shaped comment on a human-facing surface — a
# reversible, non-disclosure-class outcome — so master-OFF makes it inert, matching
# every other workflow-class hook. Fail-toward-current-behavior: a missing lib does
# NOT gate. ---
readonly MASTER_ENABLE_CLASS="workflow"
readonly MASTER_LIB="${HOOK_DIR}/lib/master-enable.sh"
if [ -r "$MASTER_LIB" ]; then . "$MASTER_LIB" 2>/dev/null || true; fi
if command -v master_enable_gate >/dev/null 2>&1; then master_enable_gate "$MASTER_ENABLE_CLASS"; fi

# --- DEPENDENCY GATE (mode-aware fail-closed — GHSA-9cjm-v22x-4x33). ---
if [ -z "$JQ" ]; then
  log_error "DEPENDENCY-MISSING: jq not found on the pinned tool path"
  _jqmiss_mode="$(get_mode)"
  if [ "$_jqmiss_mode" = "enforce" ]; then
    deny_missing_dep jq "$HOOK_NAME" "$PRINTF"
    exit 2   # caller owns the fail-closed exit (GHSA-g9g6) — never trust the callee to terminate
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:DEPENDENCY-DEGRADED] WARN (degraded, .seam-shape-mode=%s): jq not found; external-seam shape scan skipped.\n' "$HOOK_NAME" "$_jqmiss_mode" >&2
  exit 0
fi

# --- VALIDATE INPUT ---
if ! "$PRINTF" '%s' "$INPUT" | "$JQ" -e . >/dev/null 2>&1; then
  log_error "INVALID-INPUT: malformed JSON"
  "$PRINTF" '[CLAUDE-HOOK:%s:INPUT-INVALID] BLOCKED: malformed hook input JSON.\n' "$HOOK_NAME" >&2
  exit 2
fi

TOOL_NAME="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_name // empty')"

# --- EARLY EXIT: out-of-scope tool calls. Bash is excluded UNCONDITIONALLY here —
# not by a later rule, but by never entering scope at all. ---
case "$TOOL_NAME" in
  mcp__*) ;;    # structured connected-system surface — evaluate
  *) exit 0 ;;  # Bash, Write, Edit, Read, everything else — allow
esac

# --- Workspace-scope gate — layer 3, AFTER the master-activation gate and BEFORE the
# mode / rule path. Precedence: bypass -> master -> SCOPE -> mode -> rule.
# Inverted fail direction on the cwd axis, NOT on the lib axis. See lib/scope-guard.sh. ---
CWD="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.cwd // empty')"
readonly SCOPE_GUARD_LIB="${HOOK_DIR}/lib/scope-guard.sh"
if [ -r "$SCOPE_GUARD_LIB" ]; then . "$SCOPE_GUARD_LIB" 2>/dev/null || true; fi
if command -v scope_guard_gate >/dev/null 2>&1; then scope_guard_gate "$CWD"; fi

# --- LOGGING HELPERS ---
digest() {
  "$PRINTF" '%s' "$1" | "$SHASUM" -a 256 | "$SED" -n 's/^\([a-f0-9]\{16\}\).*/\1/p'
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

# log_block records a content DIGEST only — never the raw authored payload (mirrors
# the suite's digest-logging convention; the payload is destined for a human-facing
# system and may carry content the platform must not copy into a local log).
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

# apply_block — MODE-GATED block (warn / off / enforce).
apply_block() {
  local rule_id="$1"; local reason="$2"; local override="$3"; local evidence="${4:-$TOOL_NAME}"
  local mode; mode="$(get_mode)"
  case "$mode" in
    warn)
      log_warn "$rule_id" "$reason" "$(digest "$evidence")"
      "$PRINTF" '[CLAUDE-HOOK:%s:%s] WARN (would-block, .seam-shape-mode=warn): %s\n' "$HOOK_NAME" "$rule_id" "$reason" >&2
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

# warn_only_block — PERMANENTLY warn-only, mode-independent except for `off`.
# Used ONLY by BLOCK-SEAM-SHAPE-004 (FL-3). The governing discipline states the budget
# as a CEILING a genuinely warranted reply may exceed and say why; the justification
# that makes exceeding it legitimate is not readable from the payload, so this rule
# can never survive its own enforce path. Its posture is a per-rule constant rather
# than the hook dial — the shape block-destructive.sh already uses for its phase-gated
# arms — so a later flip of .seam-shape-mode to enforce does NOT promote it.
readonly SEAM_SHAPE_004_PHASE="warn"
warn_only_block() {
  local rule_id="$1"; local reason="$2"; local evidence="${3:-$TOOL_NAME}"
  local mode; mode="$(get_mode)"
  [ "$mode" = "off" ] && exit 0
  log_warn "$rule_id" "$reason" "$(digest "$evidence")"
  "$PRINTF" '[CLAUDE-HOOK:%s:%s] WARN (advisory, per-rule phase=%s — this rule never blocks): %s\n' \
    "$HOOK_NAME" "$rule_id" "$SEAM_SHAPE_004_PHASE" "$reason" >&2
  exit 0
}

# ==========================================================================
# STEP 1 — SURFACE GATE (performance: fires on every MCP call)
# ==========================================================================
# Verb-anchored AND comment-noun. Both conjuncts required; see the header for why
# the verb conjunct is not optional.
if ! "$GREP" -qE "$SEAM_WRITE_VERB_RE" <<<"$TOOL_NAME"; then exit 0; fi
if ! "$GREP" -qE "$SEAM_COMMENT_NOUN_RE" <<<"$TOOL_NAME"; then exit 0; fi

# ==========================================================================
# STEP 2 — CONTENT EXTRACTION (type-guarded; FL-2)
# ==========================================================================
# Field union over .tool_input. NARROWED from the block-scope-segregation.sh:441-445
# shape by dropping .title / .name / .summary — those are record-HEADER fields, not
# comment bodies, and this hook adjudicates a comment. EXTENDED by .commentBody /
# .content / .markdown, the content-field names the union did not carry.
#
# Every member is type-guarded rather than handed to `join`: a key holding a
# structured document (the common shape for a rich-text comment body) makes `join`
# raise, and the raise would be swallowed into an empty result that FL-1 cannot
# distinguish from a genuinely empty payload. A non-string member is walked for its
# strings instead.
#
# The walk drops values of a key literally named `type` first. That key is the
# near-universal structural discriminator in rich-text document formats, and its
# values are format metadata, not authored text. Without the drop the walk yields
# the discriminator tokens ahead of the human text — which would put a structural
# token in the FIRST-LINE position that BLOCK-SEAM-SHAPE-001 reads, so a dated
# header inside a structured body would never be seen. Measured on both shapes.
# The recursion is written out rather than using `walk`, so the expression needs no
# builtin beyond `map_values`.
CONTENT="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '
  def scrub: if type == "object" then (del(.type) | map_values(scrub))
             elif type == "array" then map(scrub)
             else . end;
  .tool_input // {} |
  [ .body, .description, .text, .comment, .commentBody, .content, .markdown,
    ( .fields // {} | .description ), ( .fields // {} | .comment ) ]
  | map(select(. != null))
  | map(if type == "string" then . else ([ scrub | .. | strings ] | join("\n")) end)
  | map(select(. != ""))
  | join("\n")' 2>/dev/null || true)"
[ "$CONTENT" = "null" ] && CONTENT=""

CONTENT_STRIPPED="$("$PRINTF" '%s' "$CONTENT" | "$TR" -d '[:space:]' || true)"

# --- FL-1 — fail-LOUD content extraction. UNLIKE block-gh-path-leak.sh:170's
# fail-open-on-empty, an empty / unparseable extraction on an in-scope surface is
# would-block(warn)/block(enforce): we reached a comment write on an external seam
# and could not read what is being said. block-scope-segregation.sh:33-37 records
# that empty extraction is the COMMON case here, which is exactly why reading green
# on it would verify nothing. ---
if [ -z "$CONTENT_STRIPPED" ]; then
  apply_block "BLOCK-SEAM-SHAPE-010" \
    "content extraction was EMPTY / unparseable for a comment write to an external seam — the comment's shape cannot be adjudicated (fail-loud; empty extraction is the common case on this surface, so a silent allow would verify nothing). Tool: ${TOOL_NAME}." \
    "send the comment body in a recognized content field (body / description / text / comment / commentBody / content / markdown), or set CLAUDE_HOOK_BYPASS=1 if intentional" \
    "${TOOL_NAME}:empty-extraction"
fi

# ==========================================================================
# STEP 3 — SHAPE RULES
# ==========================================================================

# The first NON-BLANK line, with leading heading/emphasis/quote markup stripped.
FIRST_LINE="$("$PRINTF" '%s\n' "$CONTENT" | "$GREP" -m1 -vE '^[[:space:]]*$' || true)"
FIRST_LINE_BARE="$("$PRINTF" '%s' "$FIRST_LINE" | "$SED" -e 's/^[[:space:]]*//' -e 's/^[#>[:space:]]*//' -e 's/^[*_]\{1,3\}//' -e 's/^[[:space:]]*//' || true)"

# --- BLOCK-SEAM-SHAPE-001 — dated log header (§2: no dated log headers) ---
# A date-led opener, bare or wrapped in bold/heading markup. The system already
# timestamps every comment; a date opener is register formatting.
readonly RE_DATE_LED='^([0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{1,2}/[0-9]{1,2}/[0-9]{2,4}|(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[[:space:]]+[0-9]{1,2}|[0-9]{1,2}[[:space:]]+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*)'
if "$GREP" -qE "$RE_DATE_LED" <<<"$FIRST_LINE_BARE"; then
  apply_block "BLOCK-SEAM-SHAPE-001" \
    "the comment opens with a dated log header — a register entry, not a message to a person. On an external seam the system timestamps every comment already, and the record body is where durable state belongs. Tool: ${TOOL_NAME}." \
    "put the durable state in the record's own field or body and open the comment with the ask or the answer; see core/disciplines/external-seam-conduct.md §1-§2, or set CLAUDE_HOOK_BYPASS=1 if intentional" \
    "$FIRST_LINE_BARE"
fi

# --- BLOCK-SEAM-SHAPE-002 — provenance narration (§2: no provenance narration) ---
readonly RE_PROVENANCE='(generated|authored|produced|written|posted|created|updated)[[:space:]]+by[[:space:]]+[^.]{0,40}(agent|bot|automation|assistant|pipeline|model)|via[[:space:]]+the[[:space:]]+(pipeline|automation|agent)|\brun[[:space:]]+[0-9]+[[:space:]]+of[[:space:]]+[0-9]+|(auto-generated|agent-generated|automatically[[:space:]]+generated)'
if "$GREP" -qiE "$RE_PROVENANCE" <<<"$CONTENT"; then
  apply_block "BLOCK-SEAM-SHAPE-002" \
    "the comment narrates its own provenance — who generated it, which run, which pass. That is the platform's audit vocabulary addressed to an audience that does not share it. Tool: ${TOOL_NAME}." \
    "drop the provenance line; the comment carries the ask or the answer and nothing about how it was produced. See core/disciplines/external-seam-conduct.md §2, or set CLAUDE_HOOK_BYPASS=1 if intentional" \
    "$CONTENT"
fi

# --- BLOCK-SEAM-SHAPE-003 — state-change narration (§1: never narrate a transition
# the system's own changelog already records) ---
readonly RE_STATE_CHANGE='\b(status|state|priority|assignee|owner|due[[:space:]]date|target[[:space:]]date|sprint|stage)\b[^.]{0,30}\b(changed|moved|updated|set|transitioned|reassigned|bumped)\b|\b(moved|transitioned)[[:space:]]+(it[[:space:]]+)?(to|from)[[:space:]]+[A-Za-z]|\b(marked|set)[[:space:]]+(it[[:space:]]+)?(as[[:space:]]+|to[[:space:]]+)?(done|complete[d]?|in[[:space:]]progress|blocked|closed|resolved)\b'
if "$GREP" -qiE "$RE_STATE_CHANGE" <<<"$CONTENT"; then
  apply_block "BLOCK-SEAM-SHAPE-003" \
    "the comment restates a field transition the destination system records in its own changelog — a second, immediately-divergent copy of a fact the system already owns. Tool: ${TOOL_NAME}." \
    "make the field change and stop; where a person needs to know, carry the ASK the change raises rather than the transition. See core/disciplines/external-seam-conduct.md §1, or set CLAUDE_HOOK_BYPASS=1 if intentional" \
    "$CONTENT"
fi

# --- BLOCK-SEAM-SHAPE-004 — working budget exceeded (§2). PERMANENTLY WARN-ONLY
# (FL-3): the discipline states the budget as a ceiling a warranted reply may exceed
# and say why, and that justification is absent from the payload. ---
BUDGET="$BUDGET_DEFAULT"
if [ -r "$OPERATOR_TOML" ]; then
  _budget_read="$("$AWK" '
    /^[[:space:]]*\[/ { insec = ($0 ~ /^[[:space:]]*\[external_seam\][[:space:]]*$/); next }
    insec && /^[[:space:]]*comment_word_budget[[:space:]]*=/ {
      split($0, a, "="); gsub(/[^0-9]/, "", a[2]); if (a[2] != "") { print a[2]; exit }
    }
  ' "$OPERATOR_TOML" 2>/dev/null || true)"
  case "$_budget_read" in ''|*[!0-9]*) ;; *) BUDGET="$_budget_read" ;; esac
fi
WORDS="$("$PRINTF" '%s' "$CONTENT" | "$WC" -w | "$TR" -d '[:space:]' || echo 0)"
if [ "${WORDS:-0}" -gt "$BUDGET" ]; then
  warn_only_block "BLOCK-SEAM-SHAPE-004" \
    "the comment is ${WORDS} words against a working budget of ${BUDGET}. The budget is a CEILING, not a cap — a genuinely warranted detailed reply may exceed it and say why, which is why this rule never blocks. Consider whether the content belongs at a durable home with the comment carrying the pointer and the ask. Tool: ${TOOL_NAME}." \
    "$CONTENT"
fi

# Shape-clean comment to an external seam → allow.
exit 0
