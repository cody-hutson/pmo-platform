#!/usr/bin/env bash
# block-fs-boundary.sh — PreToolUse hook enforcing workspace-boundary scoping
# for Bash file commands beyond the Anthropic settings.deny recognized subset.
# hook-owner: core/rules/bypass-mode-readiness/block-fs-boundary.md
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
# Operand disposition: an ordered guard cascade over the operand's LITERAL spans
# (see resolve_and_classify). Command substitution, backticks, the shape of a
# parameter-transformation operator, the canonicalizer's quoted-span sentinel, literal
# `..` traversal and normalizer failure are refused under -003; a decidable literal
# prefix is classified under -001/-002; an operand
# with no decidable prefix is admitted with a -004 advisory record, written on every
# invocation that reaches check_verb (warn and enforce; at .mode=off this hook exits
# above that point, so the operand is still admitted but nothing is recorded).
# Shell redirection (`>`, `>>`, `<`) deferred to v2 — accepted v1 residual per
# block-rm-prefer-trash.sh § Known Limitations precedent.
#
# Composes with (does not replace) the existing 7 PreToolUse hooks:
# block-destructive, block-egress, block-mcp-writes, block-credential-reads,
# block-shell-injection, block-rm-prefer-trash, block-skill-direct-edit.
#
# Matcher scope: Bash
# Rule IDs: BLOCK-FS-BOUNDARY-001..004
# Mode gating: shared .claude/hooks/.mode (warn / enforce / off), same file as
# block-egress + block-mcp-writes. Default initial = warn (3-day shakedown).
# Release: monolith-cleanup

set -euo pipefail

# --- PATH PINNING (tamper resistance) ---
export PATH="/usr/bin:/bin"

# Absolute tool paths (all in /usr/bin, root-owned on macOS)
readonly GREP="/usr/bin/grep"
readonly PRINTF="/usr/bin/printf"
readonly DATE="/bin/date"
readonly SHASUM="/usr/bin/shasum"
# jq and python3 are resolved below via lib/dep-resolve.sh (once HOOK_DIR is
# known), from a fixed absolute-path allowlist — never $PATH — so the anti-hijack
# PATH pin above still holds (GHSA-9cjm-v22x-4x33).

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

# --- MODE DETECTION (shared .mode file with block-egress, block-mcp-writes) ---
# jq-free (/bin/cat + /usr/bin/head + /usr/bin/tr only), so it resolves without the
# dependency helper and is therefore defined ahead of the gate below. Extracted from
# the inline read that used to sit further down; the normalization — first line only,
# whitespace stripped, unrecognized value defaults to enforce — is unchanged.
get_mode() {
  local mode="enforce" raw
  if [ -f "$MODE_FILE" ]; then
    # `|| echo` makes the substitution total. The pipeline returns 1 on a present-but-
    # unreadable mode file, and this runs under `set -euo pipefail` BEFORE the ERR trap is
    # armed — measured, the hook still resolves to the default here and fails closed, but
    # only via a subtle `set -e` interaction with assignment-inside-function. The fallback
    # removes the dependence on it and matches the shape the other cohort hooks already use.
    raw="$(/bin/cat "$MODE_FILE" 2>/dev/null | /usr/bin/head -n 1 | /usr/bin/tr -d '[:space:]' || echo enforce)"
    case "$raw" in
      warn|enforce|off) mode="$raw" ;;
      *) mode="enforce" ;;
    esac
  fi
  "$PRINTF" '%s' "$mode"
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
PYTHON3="$(resolve_python3)"; readonly PYTHON3

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
# existing posture. All four carry the same value; a prefix-set change is
# a coordinated 4-hook edit.
readonly ANCHOR_PREFIX_BASH='(^|[;&|])[[:space:]]*(/(usr/(local/)?|opt/(homebrew|local)/)?bin/)?'

# --- COMMAND-POSITION CANONICALIZER (shared primitive, #5644) ---
# The anchor above recognises a command start ONLY at start-of-line or after `;`, `&`,
# `|`, so a verb inside `{ … }`, `( … )`, after `then`/`do`, behind `sudo`/`env`/`xargs`/
# `VAR=…`, or written `\cat` was invisible to it — the verdict tracked lexical POSITION
# rather than the action. The command is canonicalized before matching so genuine command
# starts become positions this anchor already recognises; the anchor, rule IDs, messages
# and token extractor are otherwise unchanged. ONE implementation shared by all four
# anchor-carrying hooks (see core/hooks/lib/command-position.awk).
readonly CMDPOS_AWK="${HOOK_DIR}/lib/command-position.awk"

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

# --- CLAUDE_HOOK_BYPASS escape hatch — evaluated BEFORE the jq gate so it works
# even when jq is unresolvable (GHSA-9cjm-v22x-4x33: the old ordering placed this
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
# .mode read (precedence: bypass -> master -> .mode -> rule). CLASS=workflow: master-OFF
# makes this hook inert (exit 0). Fail-toward-current-behavior: a missing lib does NOT
# gate, so the hook keeps its existing .mode enforcement (a read failure never disables a
# guard). Read jq-free from the durable XDG platform-config.toml [security_hooks]. ---
readonly MASTER_ENABLE_CLASS="workflow"
readonly MASTER_LIB="${HOOK_DIR}/lib/master-enable.sh"
if [ -r "$MASTER_LIB" ]; then . "$MASTER_LIB" 2>/dev/null || true; fi
if command -v master_enable_gate >/dev/null 2>&1; then master_enable_gate "$MASTER_ENABLE_CLASS"; fi

# --- MODE GATING (shared .mode file with block-egress, block-mcp-writes) ---
# Already resolved above the dependency gate and frozen readonly, because the gate's
# fail-closed severity is mode-dependent (enforce blocks, warn degrades). Reuse the
# snapshot rather than re-reading: same value, one fewer read, and a value the sourced
# helper cannot have influenced. The off short-circuit stays HERE — after bypass and
# the master-enable gate — so the documented precedence chain is unchanged.
MODE="$LIB_GUARD_MODE"

# Mode = off: hook is disabled
if [ "$MODE" = "off" ]; then
  exit 0
fi

# --- DEPENDENCY GATE (mode-aware fail-closed) — GHSA-9cjm-v22x-4x33. ---
# jq resolution now lives in lib/dep-resolve.sh. A security control that cannot
# evaluate its input must not silently allow. In enforce mode we fail CLOSED
# (exit 2). In warn mode a rule match only warns (exit 0), so a missing dep must
# not block harder than a match would — log a degraded note and exit 0. off has
# already exited above.
if [ -z "$JQ" ]; then
  log_error "DEPENDENCY-MISSING: jq not found on the pinned tool path (mode=$MODE)"
  if [ "$MODE" = "enforce" ]; then
    deny_missing_dep jq "$HOOK_NAME" "$PRINTF"
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:DEPENDENCY-DEGRADED:WARN] jq not found on the pinned tool path; warn-mode hook cannot evaluate input and is allowing this call. Install jq (brew install jq) to restore enforcement.\n' "$HOOK_NAME" >&2
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

# --- Workspace-scope gate (#4436) — layer 3, AFTER the master-activation gate and
# BEFORE the .mode / rule path. Precedence: bypass -> master -> SCOPE -> .mode -> rule.
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

# --- CANONICALIZE COMMAND POSITIONS (see CMDPOS_AWK above) ---
# Verify the primitive WORKS before trusting its output: a present-but-empty, truncated or
# corrupt awk emits an empty string, and every matcher below would then find nothing — the
# hook would fail OPEN, strictly worse than the gap this closes. Canary: a one-line
# function body whose canonical form MUST expose the inner command at an anchor position.
# Mode-gated severity, mirroring this hook's dependency gate and block-fragile-refs.sh
# (GHSA-g9g6-28c9-vrx5): enforce DENIES, warn degrades to the raw command — which is
# exactly this hook's pre-#5644 behaviour, so warn never loses coverage it already had.
# Two probes (#8314): the first catches a present-but-empty or truncated copy; the second
# — a wrapper carrying a separate-argument option before a benign verb, exposed at an
# anchor only by the walk that reads wrapper grammar — catches a VERSION SKEW, a copy that
# predates that grammar. The second probe opens with the append form of a prefix assignment
# (#8314, follow-up pass), so a copy whose walk reads that word as the command word — one
# that predates the append form — fails it too.
CMDPOS_OK=0
if [ -r "$CMDPOS_AWK" ]; then
  if _cp_canary="$("$PRINTF" '%s' 'q() { r; }' | /usr/bin/awk -f "$CMDPOS_AWK" 2>/dev/null)" \
     && "$PRINTF" '%s' "$_cp_canary" | "$GREP" -q '; r' \
     && _cp_canary2="$("$PRINTF" '%s' 'Z+=0 nice -n 0 q' | /usr/bin/awk -f "$CMDPOS_AWK" 2>/dev/null)" \
     && "$PRINTF" '%s' "$_cp_canary2" | "$GREP" -q '; q'; then
    CMDPOS_OK=1
  fi
fi
if [ "$CMDPOS_OK" = 1 ]; then
  COMMAND_CMDPOS="$("$PRINTF" '%s' "$COMMAND" | /usr/bin/awk -f "$CMDPOS_AWK" 2>/dev/null || "$PRINTF" '%s' "$COMMAND")"
  [ -n "$COMMAND_CMDPOS" ] || COMMAND_CMDPOS="$COMMAND"
else
  log_error "PRIMITIVE-MISSING-OR-INVALID: command-position.awk unusable at $CMDPOS_AWK"
  if [ "$MODE" = "enforce" ]; then
    deny_missing_primitive "command-position.awk" "$HOOK_NAME" "$PRINTF"
    exit 2   # caller owns the fail-closed exit — never trust the callee to terminate
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:PRIMITIVE-MISSING] WARN (degraded, .mode=%s): command-position.awk absent or invalid; command-start canonicalization skipped this run (pre-existing anchor positions still enforced).\n' "$HOOK_NAME" "$MODE" >&2
  COMMAND_CMDPOS="$COMMAND"
fi

readonly FSB_READ_VERBS="cat head tail less more base64 xxd od hexdump strings"
readonly FSB_WRITE_VERBS="cp mv tee dd"
readonly FSB_TAB=$'\t'
readonly FSB_NL=$'\n'
readonly FSB_PASS2=1  # M-FSB-PASS2
readonly FSB_REDIR=1  # M-FSB-REDIR
readonly FSB_JOINS=1  # M-FSB-JOIN
readonly FSB_HDQ=1  # M-FSB-HDQ
readonly FSB_MASKFREE=1  # M-FSB-MASKFREE
FSB_SEEN=""
FSB_SEEN_N=0

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

# Pattern match against the canonicalized command. Rule patterns are unchanged; only the
# text they read is, so a verb at any genuine command start is now anchored.
#
# FED BY HERE-STRING, NEVER BY A PIPE (GHSA-xxjm-mhfm-xq5v). `grep -q` exits at its first
# match. Piped, a command longer than the pipe's capacity (64 KiB) left its writer with text
# still to push; the writer took SIGPIPE (141) or a write error (1), `pipefail` made that the
# pipeline's status, and the rule read "no match" and did not fire. A here-string has no
# second process; when bash cannot create the temp file behind it, _rc stays empty and
# matcher_not_evaluated takes the mode-coupled posture. Pinned by
# tests/ghsa-xxjm-long-input-matchers.test.sh — keep the line's shape in step with that
# suite's to_old_shape.
matches() {
  local pattern="$1" _rc=
  { _rc=0; "$GREP" -qE "$pattern" || _rc=$?; } <<< "$COMMAND_CMDPOS" || true
  [ -n "$_rc" ] || matcher_not_evaluated
  [ "$_rc" = 0 ]
}

# matcher_not_evaluated — the rule matcher's here-string could not be created, so no rule read
# the command. Mode-coupled (ADR-078 D2), as the command-position canary's failure above is:
# enforce refuses; warn and off stand down loudly, because no rule ran. Never returns.
matcher_not_evaluated() {
  log_error "INPUT-NOT-EVALUATED: the rule matcher's here-string could not be created (temp file)"
  if [ "$LIB_GUARD_MODE" = "enforce" ]; then
    "$PRINTF" '[CLAUDE-HOOK:%s:INPUT-NOT-EVALUATED] BLOCKED (fail-closed): the command could not be handed to the rule matcher (bash could not create the temp file behind its here-string); this is not a clean result: the hook could not evaluate its input. See %s.\n' "$HOOK_NAME" "$ERROR_LOG" >&2
    exit 2
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:INPUT-NOT-EVALUATED] WARN (degraded, .mode=%s): the command could not be handed to the rule matcher (bash could not create the temp file behind its here-string); this is not a clean result: no rule read the command this run.\n' "$HOOK_NAME" "$LIB_GUARD_MODE" >&2
  exit 0
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

# --- POLICY P CONSTANTS (#5555) ---
# The canonicalizer (lib/command-position.awk) replaces command-structural characters
# INSIDE a quoted span with \001. On the stream this hook actually reads
# ($COMMAND_CMDPOS), a quoted `${VAR}` and a quoted `$(cmd)` are therefore BYTE-IDENTICAL
# — both arrive as $\001…\001. Any policy that admits braced parameter expansions
# silently admits command substitution. That single fact is why the cascade below
# REFUSES on the sentinel (G1) instead of parsing the brace, and why `${…}` must never
# be "simplified" into a benign form. The suite's three-way G1 arm exists to fail that edit.
readonly CMDPOS_SENTINEL=$'\001'
# Substituted for each expansion span when building the skeleton. Deliberately a single
# path segment containing no `/` and no `.`, so an expansion can never introduce a
# separator or a traversal component into the skeleton that steps 3-7 then classify.
readonly EXPANSION_SENTINEL='EXPANSION'

# render_token(token)
#   Message-safe rendering. The 286 sentinel-bearing operands would otherwise emit a raw
#   \001 control byte to the operator and display as a corrupted path.
#
#   THE LINEAR PASS. On bash 3.2 a global pattern substitution costs more than linear time
#   in the text it scans once that text carries the character it replaces, and this builds
#   the refusal message: a token large enough could hold the hook past the runtime's
#   command-hook timeout here, and a hook that times out does not block, so the refusal
#   would become an allow. A token of at least FSB_LINEAR_MIN characters is therefore
#   rewritten first by one sed pass in the C locale, whose output equals the substitution's
#   byte for byte (AC-FSB-X-EQ); the substitution still runs after it and finds nothing left
#   to replace, which costs one scan. A shorter token costs less than the fork the pass
#   takes, so it keeps the substitution alone, and a pass that fails leaves the token to it.
readonly FSB_LINEAR_MIN=256
render_token() {
  local t="$1" lp
  if [ "${#t}" -ge "$FSB_LINEAR_MIN" ] && lp="$(LC_ALL=C /usr/bin/sed "s/${CMDPOS_SENTINEL}/<quoted-expansion>/g" <<< "${t}.")"; then t="${lp%.}"; fi  # linear: render
  "$PRINTF" '%s' "${t//$CMDPOS_SENTINEL/<quoted-expansion>}"
}

# _span_closed_inside_subscript(inner) — the span split's subscript check
#   <inner> is the text _split_expansions takes for one unquoted ${...} span: from its `{`
#   up to the first `}` after it. Returns 0 when that text holds both a `[` and a nested
#   `${`, and 1 otherwise.
#
#   WHY THE SPLIT REFUSES IT. The split closes a span at its first `}`; the shell closes it
#   at the brace that matches its own opener. Inside a subscript the shell reads on across
#   whitespace, `;`, `&`, `|` and line breaks, which end a word or a segment for the token
#   walk. When a subscript holds a braced expansion, the first `}` is that expansion's, so
#   the split ends the span inside the subscript while the shell is still in it, and the
#   rest of the shell's word (the subscript's tail, any operator, the closing brace) lies
#   in text the split never joins to the span: later in this word, in a later word, or in
#   a word the walk never hands over. G2's third limb cannot see such an operand, because
#   it needs the `${` and the operator's shape in one walk word. Nothing in the span decides
#   the operand's path, so the split fails and the caller refuses under -003, as for an
#   unterminated brace. The suite's XFORM-FRAG arms pin each break.
#
#   TWO MARKS, NOT A BRACKET COUNT. Whether the subscript is still open where the span ends
#   is a matter of counting brackets, which takes a loop. Every span this split closes
#   inside a subscript carries two marks instead: the subscript's `[`, and the nested `${`
#   whose brace closed it. Testing the marks refuses more than that class, by decision: a
#   subscript holding a braced expansion when nothing breaks it, and a word that holds a
#   bracket and a nested braced expansion. The XFORM-OVER arms hold that width; the
#   XFORM-NEAR arms hold the forms it must not reach (a subscript holding an unbraced
#   expansion, a nested default with no bracket).
#
#   LINEAR BY CONSTRUCTION. Two globs, each with one leading and one trailing star, over
#   text the split has already taken. The spans the split takes do not overlap, so the check
#   adds at most one pass over the token. No loop, no fork, no pipe, no pattern removal;
#   XFORM-COST-02 holds this shape.
_span_closed_inside_subscript() {
  case "$1" in *\[*) ;; *) return 1;; esac
  case "$1" in *\$\{*) return 0;; esac
  return 1
}

# _split_expansions(token)
#   Split an expansion-bearing token into its SKELETON (each expansion span replaced by
#   $EXPANSION_SENTINEL) and its literal PREFIX (the text before the FIRST expansion).
#   Recognized expansion spans: $NAME, an UNQUOTED ${...}, and the $1/$@/$#/$*/$?/$$/$!
#   positional-and-special class. A `$` that introduces none of these is NOT guessed at —
#   the function fails and the caller refuses. Conservative by construction.
#   A ${...} followed later by the transformation operator's shape never reaches this
#   function: resolve_and_classify refuses it at G2 (see _carries_transform_op).
#   A ${...} span this function would close inside a subscript fails it, as an
#   unterminated one does (see _span_closed_inside_subscript).
#   Sets: _SK, _PFX. Returns 0 on a clean split; 1 when a `$` is unrecognizable, a ${
#   is unterminated, or a ${...} span would close inside a subscript.
_split_expansions() {
  local rest="$1"
  local sk="" pfx="" seen_exp=0 head_ after consumed inner name i c
  _SK=""; _PFX=""
  while [ -n "$rest" ]; do
    head_="${rest%%\$*}"
    if [ "$head_" = "$rest" ]; then
      sk="${sk}${rest}"
      [ "$seen_exp" = 0 ] && pfx="${pfx}${rest}"
      rest=""
      break
    fi
    sk="${sk}${head_}"
    [ "$seen_exp" = 0 ] && pfx="${pfx}${head_}"
    rest="${rest#"$head_"}"
    after="${rest#\$}"
    consumed=""
    case "$after" in
      \{*)
        # A ${...} carrying no sentinel. A QUOTED one normally carries the sentinel and
        # was refused by G1 — but not when the canonicalizer handed the command back
        # unchanged (unbalanced quotes; an apostrophe in a here-document body is enough).
        # Step 1 then stripped the quotes, and the quoted spelling arrives here as the
        # unquoted one. The suite's XFORM-SUBJ-03 arm builds that path.
        case "$after" in
          *\}*) inner="${after%%\}*}"; consumed="\$${inner}}"
                # A span this split would close inside a subscript is refused like an
                # unterminated one (see _span_closed_inside_subscript).
                if _span_closed_inside_subscript "$inner"; then return 1; fi;;
          *)    return 1;;
        esac
        ;;
      [A-Za-z_]*)
        name=""; i=0
        while [ "$i" -lt "${#after}" ]; do
          c="${after:$i:1}"
          case "$c" in
            [A-Za-z0-9_]) name="${name}${c}"; i=$((i + 1));;
            *) break;;
          esac
        done
        consumed="\$${name}"
        ;;
      [0-9@#*?!$]*)
        consumed="\$${after:0:1}"
        ;;
      *)
        # A bare `$` introducing nothing recognizable — do not guess.
        return 1
        ;;
    esac
    sk="${sk}${EXPANSION_SENTINEL}"
    seen_exp=1
    rest="${rest#"$consumed"}"
  done
  _SK="$sk"; _PFX="$pfx"
  return 0
}

# _carries_transform_op(token) — G2, third limb
#   Returns 0 when the token carries a `${` and, anywhere in it, `@` followed by exactly one
#   character that is neither `]` nor `}` and then a closing brace: the shape every use of the
#   parameter-transformation operator ${parameter@operator} has. Returns 1 otherwise.
#
#   WHY G2 REFUSES IT. The cascade classifies an expansion as one unknown segment of a
#   variable's VALUE. An operator yields not the value but text the shell derives from it,
#   and which letter derives what is a property of the shell's version: `P` re-expands the
#   value as a prompt string, command substitutions included. The path is whatever an
#   evaluation produces, as for $( and a backtick, so it is refused with them. That is what
#   this guard can decide. It is not a control on execution, which the script-execution
#   allowlist governs.
#
#   A SHAPE, NOT A GRAMMAR. No operator list: a list fails open on the next letter a shell
#   adds (XFORM-OP-Z). No parameter parsing: a reader that delimits the parameter as the
#   shell does would exempt a default word or pattern ending the same way (${LOG:-a@b}),
#   but its per-character walk was measured to cost time quadratic in the operand, past the
#   hook's timeout on a 40 KB operand, and an earlier text of it admitted a valid use of the
#   operator through a wrong exemption. The price of the shape is that over-refusal and the
#   order-blindness below; the XFORM-OVER arms hold both as a decision, and the XFORM-NEAR
#   arms hold the forms it must not reach (${arr[@]}, ${@:2}, ${!prefix@}).
#
#   LINEAR BY CONSTRUCTION. Two globs, each with one leading and one trailing star, so each
#   is one pass. They do not ask that the `${` come first: the single glob that does (a
#   `${`, a star, then the shape) backtracks over every `${` and costs time quadratic in the
#   operand. No loop, no fork, no pipe, no pattern removal; XFORM-COST-01 holds this shape.
#
#   Like G2's other limbs it reads the token as text: `\${...}` is refused as `\$(` is. It
#   only refuses; a token it returns 1 for continues down the cascade unchanged. It does not
#   see a value the shell re-evaluates (an arithmetic offset or index, an indirection); the
#   readiness fragment declares that limit and the XFORM-RESID arms pin it. It reads one
#   word as the token walk hands it over: an operator use the walk splits inside a
#   subscript is refused by the span split instead (see _span_closed_inside_subscript).
_carries_transform_op() {
  case "$1" in *\$\{*) ;; *) return 1;; esac
  # shellcheck disable=SC1083  # the brace inside the bracket expression is a member, not a brace
  case "$1" in *@[!]}]\}*) return 0;; esac
  return 1
}

# _classify_literal(token)
#   Steps 3-7 for a token containing NO expansions. Extracted verbatim from the original
#   resolve_and_classify body so the literal path is provably unchanged, and so the
#   skeleton and the literal prefix are classified by the SAME code.
#   Returns: 0 = inside allowed root, 1 = outside, 2 = unresolvable.
_classify_literal() {
  local token="$1"
  local resolved=""

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

  # Step 5: reject any `..` path-component (directory traversal) independent of
  # the python3 normalizer below. A literal `..` component escapes an allowed
  # root by prefix-matching BEFORE it is collapsed (e.g.
  # /allowed/../../../etc/passwd starts with /allowed/ yet resolves to /etc).
  # This must fail closed even when python3 IS present (GHSA-9cjm-v22x-4x33 V2).
  case "/$resolved/" in
    */../*) return 2;;
  esac

  # Step 6: normalize via python3 os.path.realpath — collapses ../ and ./,
  # does not require existence, follows symlinks (intentional for strict-
  # boundary enforcement). python3 is resolved from the pinned allowlist via
  # lib/dep-resolve.sh. FAIL CLOSED if python3 is unresolvable OR realpath
  # errors: the un-normalized path must NEVER be classified — the old
  # `|| echo "$resolved"` fallback let an un-collapsed traversal prefix-match
  # an allowed root (GHSA-9cjm-v22x-4x33 V2 second fail-open).
  if [ -z "$PYTHON3" ]; then
    return 2
  fi
  local normalized
  normalized="$("$PYTHON3" -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$resolved" 2>/dev/null)" || return 2
  [ -z "$normalized" ] && return 2
  resolved="$normalized"

  # Step 7: check resolved path against allowlist
  if is_allowed_path "$resolved"; then
    "$PRINTF" '%s' "$resolved"
    return 0
  fi
  "$PRINTF" '%s' "$resolved"
  return 1
}

# resolve_and_classify(token)
#   Classify a path token — POLICY P (#5555): classify the SKELETON, not the token.
#
#   The predicate this replaces was a CHARACTER test (`case $token in *\$*) return 2`),
#   not a SHAPE test: it fired on "$SPOKE_OUT/comment.md" exactly as it fired on
#   "$(curl -s http://evil/loot)", and it fired before any machinery that could tell them
#   apart. It collapsed three distinct epistemic states — decidably-inside,
#   decidably-outside, and genuinely undecidable — into one refusal.
#
#   Ordered guard cascade (refuse-before-decide: G0/G1/G2 precede the span split and every
#   branch that can admit, so an ambiguous or executable construct never reaches them):
#
#     G0  token is exactly $XARGS-STDIN (canonicalizer's stdin sentinel)  -> REFUSE  -003
#     G1  token carries the \001 quoted-span sentinel (ambiguous)         -> REFUSE  -003
#     G2  token contains $( or a backtick, or carries a ${ and the shape @X}
#         of a parameter-transformation operator (see _carries_transform_op) -> REFUSE  -003
#     G3  a literal span holds `..`; or cwd absent for a relative token;
#         or python3 unresolvable / realpath fails                        -> REFUSE  -003
#     G5  decidable literal prefix resolves OUTSIDE all allowed roots     -> REFUSE  -001/-002
#     G4  decidable literal prefix resolves INSIDE an allowed root        -> ALLOW   (silent)
#     G6  no decidable prefix (token opens with an expansion)             -> ALLOW   -004 advisory
#
#   G0 is carved out explicitly: the canonicalizer routes an `xargs` denial THROUGH the
#   unresolvable branch, so a naive "leading expansion -> allow" rule would silently
#   disable that coverage with no test noticing. The suite arms it.
#
#   Returns: 0 = inside allowed root (or decidable prefix inside)
#            1 = outside allowed root (fully resolved)
#            2 = unresolvable (strict refusal)
#            3 = advisory-allow, logged by the caller (BLOCK-FS-BOUNDARY-004);
#                see advise_unresolvable for the mode scope of that record
#            4 = decidable literal PREFIX outside allowed roots (message must say "prefix")
#   Outputs the resolved absolute path on stdout when the return is 0, 1 or 4.
#   A distinct return code — not a global — carries the prefix qualifier, because callers
#   invoke this in a command substitution and a subshell assignment would not propagate.
resolve_and_classify() {
  local token="$1"

  # Step 1: strip surrounding single/double quotes
  case "$token" in
    \"*\") token="${token#\"}"; token="${token%\"}";;
    \'*\') token="${token#\'}"; token="${token%\'}";;
  esac

  # --- G0: the canonicalizer's xargs-stdin sentinel. MUST precede the $NAME parser:
  # `$XARGS-STDIN` would otherwise split as $XARGS + literal "-STDIN", yielding an empty
  # prefix and an advisory ALLOW — turning off an `xargs` denial by accident. ---
  # shellcheck disable=SC2016  # literal sentinel text, not an expansion
  if [ "$token" = '$XARGS-STDIN' ]; then return 2; fi

  # --- G1: quoted structural construct. See CMDPOS_SENTINEL above — on this stream a
  # quoted ${VAR} is indistinguishable from a quoted $(cmd), so both are refused. ---
  case "$token" in
    *"$CMDPOS_SENTINEL"*) return 2;;
  esac

  # --- G2: a construct whose path only an evaluation produces. Three limbs: $( , a
  # backtick, and the shape of a parameter-transformation operator. The third is a test
  # over the token's text, so it also holds for a quoted spelling that reached this point
  # because the canonicalizer's quote mask was unavailable (see _split_expansions). ---
  # shellcheck disable=SC2016  # literal char matches in case glob; not expansions
  case "$token" in
    *\$\(*) return 2;;
    *\`*)   return 2;;
  esac
  if _carries_transform_op "$token"; then return 2; fi

  # --- No expansion at all: the pre-existing literal path, behaviour unchanged. ---
  case "$token" in
    *\$*) :;;
    *) _classify_literal "$token"; return "$?";;
  esac

  # --- Expansion-bearing operand: build the skeleton and classify THAT. ---
  _split_expansions "$token" || return 2

  # G3 — run the literal-span checks over the skeleton. Only a rc of 2 is meaningful
  # here: the skeleton carries a sentinel standing for unknown text, so "outside" on the
  # skeleton is not a decidable verdict and is deliberately NOT acted on.
  local sk_rc=0
  _classify_literal "$_SK" >/dev/null || sk_rc="$?"
  if [ "$sk_rc" = 2 ]; then return 2; fi

  # G5 / G4 — a decidable literal prefix DIRECTORY: the text before the first expansion,
  # truncated at its last `/`. Truncating at the separator is what makes the prefix a
  # directory the allowlist can decide; `/tmp$X` therefore decides on `/`, never on `/tmp`.
  case "$_PFX" in
    */*)
      local pfx_dir="${_PFX%/*}/"
      local pfx_rc=0 pfx_resolved
      pfx_resolved="$(_classify_literal "$pfx_dir")" || pfx_rc="$?"
      case "$pfx_rc" in
        0) return 0;;
        1) "$PRINTF" '%s' "$pfx_resolved"; return 4;;
        *) return 2;;
      esac
      ;;
  esac

  # G6 — no decidable prefix. Advisory allow; the caller logs it whenever this function
  # was reached at all (see advise_unresolvable — .mode=off exits above check_verb).
  return 3
}

# extract_target_tokens(verb)
#   Tokenize $COMMAND, skip $verb itself and flag tokens (-*).
#   Emits target tokens from segments where $verb is the first token.
#   Outputs one token per line.
#
#   Same algorithm as block-rm-prefer-trash.sh extract_target_tokens()
#   (chained-command F1 split + absolute-path-prefix strip).
#
#   Reads the CANONICALIZED command (#5644), like the regex above it.
#   The two are atomically coupled: canonicalizing only one of them
#   either fires the gate and extracts nothing (silent no-op) or leaves
#   the regex gating first and closes only a fraction of the positions.
extract_target_tokens() {
  local verb="$1"
  "$PRINTF" '%s' "$COMMAND_CMDPOS" | /usr/bin/awk -v v="$verb" '
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
          # Skip bare shell structure. A subshell leaves its closing `)` inside
          # the segment, and without this `( cat )` would resolve `)` as a
          # relative path and classify a targetless no-op (#5644).
          if (t ~ /^[(){}]+$/) continue;
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

# advise_unresolvable(verb, token) — BLOCK-FS-BOUNDARY-004 (#5555)
#   The genuinely-undecidable class: an operand whose first character is a parameter
#   expansion, carrying no $(, no backtick, no parameter-transformation operator's shape,
#   no \001 sentinel, and no `..` in any literal span. It is ADMITTED, and the admission is
#   recorded whenever this function is reached.
#
#   THE DISPOSITION IS MODE-INDEPENDENT; THE RECORD IS NOT. This function never reads
#   $MODE and never blocks at any .mode value, so the false-positive fix ships without
#   touching the dial that seven unrelated hooks share. That is a design property, not
#   "warn-mode behaviour" — do not route it through block_or_warn.
#
#   But mode-independence is a property of what this function DOES, not of whether it
#   RUNS. At .mode=off the hook short-circuits at the `off` exit above the dependency
#   gate, so check_verb is never called, this function is never reached, and NO -004
#   record is written. "Always recorded" is therefore wrong as an unqualified claim:
#   the ADMIT is mode-independent, the RECORD is scoped to warn and enforce. Do not
#   restore the absolute wording — the suite's MODEOFF-REC arms fail exactly that edit.
#
#   Record-only, no stderr: the record is what keeps the admitted population measurable
#   on a warn- or enforce-mode instance (and a later narrowing evidence-backed); at
#   .mode=off the class is admitted and unmeasured. Emitting a stderr line per operand
#   would reproduce, on ~90% of file reads, exactly the operator noise this card removes.
advise_unresolvable() {
  local verb="$1"; local token="$2"
  log_warn "BLOCK-FS-BOUNDARY-004" \
    "${verb} target opens with an unresolvable expansion and has no decidable literal prefix to classify; admitted under advisory policy: $(render_token "$token")"
}

# judge_operand(verb, rule_id_class, token)
#   The per-operand disposition, shared by both passes: one token, classified by the cascade
#   (resolve_and_classify) and refused, warned, advised or admitted by the rule its class
#   names. The braced block keeps check_verb's indentation, so the suite's line-keyed
#   mutations of these lines still target them.
judge_operand() {
  local verb="$1"; local class="$2"; local token="$3"
  local outside_rule
  local strict_rule
  case "$class" in
    READ)  outside_rule="BLOCK-FS-BOUNDARY-001"; strict_rule="BLOCK-FS-BOUNDARY-003";;
    WRITE) outside_rule="BLOCK-FS-BOUNDARY-002"; strict_rule="BLOCK-FS-BOUNDARY-003";;
    *)     outside_rule="BLOCK-FS-BOUNDARY-001"; strict_rule="BLOCK-FS-BOUNDARY-003";;
  esac
  {
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
      4)
        # G5 — the DECIDABLE LITERAL PREFIX resolves outside the allowed roots. The
        # message must say "prefix": the operand was never fully resolved, and telling an
        # operator a path resolved when only its prefix did is the failure mode this
        # wording exists to prevent.
        block_or_warn "$outside_rule" \
          "${verb} target's decidable literal prefix resolves outside workspace-boundary allowed roots: ${resolved} (this is the PREFIX of an expansion-bearing operand — the full path was NOT resolved)" \
          "(a) extend .claude/fs-boundary-allowlist.txt via allowlist-add.sh if root is legitimate, (b) use a path within an allowed root, (c) set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional" || true
        ;;
      2)
        block_or_warn "$strict_rule" \
          "${verb} target unresolvable under strict policy (variable/subshell/backtick/parameter-transformation/traversal token, or path-normalizer unavailable): $(render_token "$token")" \
          "use explicit absolute paths without .. traversal instead of variables/subshells, ensure python3 is installed, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional" || true
        ;;
      3)
        advise_unresolvable "$verb" "$token"
        ;;
    esac
  }
}

# check_verb(verb, rule_id_class)
#   Run the verb-detection + per-token classification loop.
#   rule_id_class: "READ" → BLOCK-FS-BOUNDARY-001 / -003 / -004
#                  "WRITE" → BLOCK-FS-BOUNDARY-002 / -003 / -004
#   Each token it hands to judge_operand is recorded in FSB_SEEN first, so the second pass
#   below never judges it again.
#   Returns: 0 always (block_or_warn exits on enforce-mode block; warn-mode returns)
check_verb() {
  local verb="$1"; local class="$2"

  # Detect verb at command-start position (absolute-path-aware)
  if ! matches "${ANCHOR_PREFIX_BASH}${verb}([[:space:]]+|$)"; then
    return 0
  fi

  while IFS= read -r token; do
    [ -z "$token" ] && continue
    FSB_SEEN="${FSB_SEEN}${verb}${FSB_TAB}${token}${FSB_NL}"; FSB_SEEN_N=$((FSB_SEEN_N + 1))
    judge_operand "$verb" "$class" "$token"
  done < <(extract_target_tokens "$verb")
}

# ==========================================================================
# SECOND PASS — the operands the token walk does not hand over
# ({{ADR:fs-boundary-second-pass-reads-skipped-operands}})
# ==========================================================================
# Runs after both rule-evaluation loops, so every first-pass verdict is reached first: under
# enforce a first-pass refusal has already exited, and under warn its records are already
# written. The second pass reads the command again, in readings the first pass does not make,
# and hands each verb-and-word pair the first pass did not hand over to judge_operand — the same
# disposition, rule IDs and messages. It can therefore only add a refusal or a record.
#
# THE READINGS. Each base text is the command as written, and, when a line continuation is
# present, the command with every continuation joined (no join after a line on which an unquoted
# # opens a comment). For each base:
#   C   the base with each top-level redirection operator's & and | taken out (M-FSB-REDIR), so
#       the canonicalizer cuts it only where the shell does, then canonicalized (the first pass's
#       canonical text is reused when nothing was taken out);
#   CH  the same copy with every mark the canonicalizer's quote scanner reads apart from the shell
#       mapped to a neutral byte, canonicalized, and the marks restored (M-FSB-HDQ) — built
#       whenever such a mark is present, whether or not C changed;
#   CM  the base with every quote mark neutral, canonicalized and restored (M-FSB-MASKFREE) —
#       built only when C equals its input, the input carries a quote mark, and CH (if built)
#       also left its input unchanged.
# Each canonical reading of the unjoined base is also read with its continuations joined. At most
# six canonicalizer runs are added, three per base.
#
# FAIL DIRECTION. The whole pass runs in one command substitution with set -e re-armed inside it,
# every external call is checked, every helper leaves FSB_OK=1 only as its last statement and its
# caller checks that flag, and the pass prints its completion line JUDGED only as its last step.
# A non-zero status or a missing completion line is a reading that did not complete:
# reading_not_evaluated refuses under enforce and, under warn, stands down with a warn-log
# record. Every program is fed from a here-string. See the readiness fragment, coverage of G2.
readonly FSB_LEX_AWK='
  # FSB_LEX_AWK - the second pass lexer over one text. -v mode= flags | text | join | maskfree | restore
  BEGIN {
    SQ = sprintf("%c", 39); DQ = sprintf("%c", 34); BS = sprintf("%c", 92)
    C2 = sprintf("%c", 2); C3 = sprintf("%c", 3); C4 = sprintf("%c", 4); C5 = sprintf("%c", 5); C6 = sprintf("%c", 6)
    if (scheme == 2) { MQ = C2 C5; MD = C3 C5; MO = C2 C6; MC = C3 C6; E2 = C2 C4; E3 = C3 C4 }
    else             { MQ = C2;    MD = C3;    MO = C4;    MC = C5;    E2 = C2;    E3 = C3 }
    ESC = (scheme == 2 && (repair || mode == "maskfree"))
    nchk = 0; cur = ""; cl = 0; nrec = 0; pend = 0; joined = 0
    fR = 0; fC = 0; fQ = 0; fT = 0; fX = 0
    L = 0; st[0] = 0; pd[0] = 0; ar[0] = 0; kd[0] = 0; cq[0] = 0
    nq = 0; qh = 1; body = 0
  }
  function out(s) { cur = cur s; cl += length(s); if (cl >= 512) { chk[++nchk] = cur; cur = ""; cl = 0 } }
  function em(x) { if (ESC) { if (x == C2) { out(E2); return } if (x == C3) { out(E3); return } } out(x) }
  function code(x) { return (x == SQ ? MQ : (x == DQ ? MD : (x == "(" ? MO : MC))) }
  function emm(x) { fT = 1; if (!repair) { em(x); return } out(code(x)) }
  function emq(x) { if (L >= 1 && kd[1] == 2) { emm(x); return } em(x) }
  function emp(x) { if (L >= 1 && kd[1] == 1 && (x == "(" || x == ")")) { emm(x); return } if (x == SQ || x == DQ) { emq(x); return } em(x) }
  function naive() { return (L >= 1 && kd[1] == 1) }
  function wstart(i) { if (i == 1) return 1; return (index(" \t;&|()<>", c[i - 1]) > 0) }
  function shifts(s,   n, i, x, z, dep) {
    if (naive() && s ~ /[()]/) return 1
    n = split(s, q, ""); z = 0
    for (i = 1; i <= n; i++) {
      x = q[i]
      if (z == 0) {
        if (x == "$" && q[i + 1] == "(") { dep = 1; i += 2; while (i <= n && dep > 0) { if (q[i] == "(") dep++; else if (q[i] == ")") dep--; i++ } if (dep > 0) return 1; i--; continue }
        if (x == BS) { i++; continue }
        if (x == "#" && (i == 1 || index(" \t;&|", q[i - 1]) > 0)) return 0
        if (x == SQ) { z = 1; continue }
        if (x == DQ) { z = 2; continue }
        continue
      }
      if (z == 2 && x == BS) { i++; continue }
      if ((z == 1 && x == SQ) || (z == 2 && x == DQ)) z = 0
    }
    return (z != 0)
  }
  function plain(s,   n, i) { if (!ESC) { out(s); return } n = split(s, q, ""); for (i = 1; i <= n; i++) em(q[i]) }
  function mapall(s,   n, i, x) {
    n = split(s, q, "")
    for (i = 1; i <= n; i++) { x = q[i]; if (x == SQ || x == DQ || x == "(" || x == ")") emm(x); else em(x) }
  }
  function oddbs(s) { if (match(s, /\\+$/)) return (RLENGTH % 2 == 1); return 0 }
  function rjoin(s,   r) {
    r = s
    gsub(/&>/, ">", r); gsub(/>&/, ">", r); gsub(/>\|/, ">", r); gsub(/<&/, "<", r)
    if (r != s) fR = 1
    return r
  }
  function bodyline(s,   t, k, sh, j, u) {
    k = qh; t = s
    if (hdash[k]) sub(/^\t+/, "", t)
    if (canon) sub(/^; /, "", t)
    if (t == hd[k]) { plain(s); qh++; if (qh > nq) { body = 0; nq = 0; qh = 1 } return }
    sh = shifts(s); if (sh) fT = 1
    j = oddbs(s); if (j) fC = 1
    u = s
    if (redir || mode == "flags") u = rjoin(u)
    if (mode == "join" && j) { u = substr(u, 1, length(u) - 1); pend = 1; joined = 1 }
    if (repair && sh) mapall(u); else plain(u)
  }
  function hdword(i, n,   j, w, x, quo, inq) {
    j = i; while (j <= n && (c[j] == " " || c[j] == "\t")) j++
    w = ""; quo = 0; inq = ""
    while (j <= n && length(w) < 256) {
      x = c[j]
      if (inq == "") {
        if (index(" \t;&|()<>", x) > 0) break
        if (x == SQ || x == DQ) { inq = x; quo = 1; j++; continue }
        if (x == BS) { quo = 1; j++; if (j <= n) w = w c[j]; j++; continue }
        w = w x; j++; continue
      }
      if (x == inq) { inq = ""; j++; continue }
      w = w x; j++
    }
    if (w == "") return
    nq++; hd[nq] = w; hquo[nq] = quo; hdash[nq] = HDASH
  }
  function push(k, a) { L++; st[L] = 0; pd[L] = 1; kd[L] = k; ar[L] = a; cq[L] = 0 }
  function scanline(s,   n, i, x, y, z, cont) {
    n = split(s, c, ""); i = 1; cont = 0
    if (index(s, C2) || index(s, C3) || index(s, C4) || index(s, C5)) fX = 1
    if (index(s, SQ) || index(s, DQ)) fQ = 1
    while (i <= n) {
      x = c[i]; z = st[L]
      if (z == 1) { if (x == SQ) st[L] = 0; emp(x); i++; continue }
      if (z == 3) {
        if (x == BS) {
          if (i == n) { em(x); i++; continue }
          y = c[i + 1]; em(x)
          if (y == SQ && L == 0) emm(y); else emp(y)
          i += 2; continue
        }
        if (x == SQ) st[L] = 0
        emp(x); i++; continue
      }
      if (z == 4) {
        if ((x == SQ || x == DQ) && cq[L]) emm(x); else emp(x)
        i++; continue
      }
      if (z == 2) {
        if (x == BS) {
          if (i == n) { cont = 1; i++; continue }
          y = c[i + 1]; em(x); emp(y)
          i += 2; continue
        }
        if (x == DQ) { st[L] = 0; emq(x); i++; continue }
        if (x == "$" && c[i + 1] == "(") { em(x); em("("); push(2, c[i + 2] == "("); i += 2; continue }
        emp(x); i++; continue
      }
      if (x == BS) {
        if (i == n) { cont = 1; i++; continue }
        y = c[i + 1]; em(x); emp(y)
        i += 2; continue
      }
      if (x == "#" && !ar[L] && wstart(i)) { st[L] = 4; cq[L] = (L == 0 && i > 1 && index("()<>", c[i - 1]) > 0); em(x); i++; continue }
      if (x == SQ) { st[L] = 1; emq(x); i++; continue }
      if (x == DQ) { st[L] = 2; emq(x); i++; continue }
      if (x == "$") {
        y = c[i + 1]
        if (y == "$") { em(x); em(y); i += 2; continue }
        if (y == SQ) { em(x); emq(y); st[L] = 3; i += 2; continue }
        if (y == DQ) { em(x); emq(y); st[L] = 2; i += 2; continue }
        if (y == "(") { em(x); em("("); push(L == 0 ? 1 : kd[L], c[i + 2] == "("); i += 2; continue }
        em(x); i++; continue
      }
      if (x == "(") { if (L >= 1) pd[L]++; em(x); i++; continue }
      if (x == ")") { em(x); i++; if (L >= 1) { pd[L]--; if (pd[L] <= 0) L-- } continue }
      if (x == "<" && c[i + 1] == "<" && c[i + 2] != "<" && !ar[L] && (i == 1 || c[i - 1] != "<")) {
        HDASH = (c[i + 2] == "-"); hdword(i + 2 + HDASH, n)
        em(x); em(c[i + 1]); i += 2; continue
      }
      if (L == 0 && x == "&") {
        y = c[i + 1]
        if (y == ">") {
          fR = 1; if (!redir) em(x); em(y); i += 2
          if (c[i] == ">") { em(c[i]); i++ }
          if (c[i] == "|") { if (!redir) em(c[i]); i++ } else if (c[i] == "!") { em(c[i]); i++ }
          continue
        }
        if (y == "&" || y == "|" || y == "!") { em(x); em(y); i += 2; continue }
        em(x); i++; continue
      }
      if (L == 0 && x == ">") {
        em(x); i++
        if (c[i] == ">") { em(c[i]); i++ }
        if (c[i] == "&") { fR = 1; if (!redir) em(c[i]); i++ }
        if (c[i] == "|") { fR = 1; if (!redir) em(c[i]); i++ } else if (c[i] == "!") { em(c[i]); i++ }
        continue
      }
      if (L == 0 && x == "<" && c[i + 1] == "&") { fR = 1; em(x); if (!redir) em("&"); i += 2; continue }
      if (x == "|" && (c[i + 1] == "|" || c[i + 1] == "&")) { em(x); em(c[i + 1]); i += 2; continue }
      em(x); i++
    }
    if (st[L] == 4) st[L] = 0
    if (cont) { fC = 1; if (mode == "join") { pend = 1; joined = 1 } else em(BS); return }
    if (nq >= qh && st[L] == 0) body = 1
  }
  function maskline(s,   n, i, x) {
    n = split(s, q, "")
    for (i = 1; i <= n; i++) { x = q[i]; if (x == SQ) out(MQ); else if (x == DQ) out(MD); else em(x) }
  }
  function restline(s,   n, i, x, y) {
    n = split(s, q, "")
    for (i = 1; i <= n; i++) {
      x = q[i]
      if (scheme == 2) {
        if ((x == C2 || x == C3) && i < n) {
          y = q[i + 1]; i++
          if (y == C4) out(x)
          else if (y == C5) out(x == C2 ? SQ : DQ)
          else if (y == C6) out(x == C2 ? "(" : ")")
          else out(x y)
          continue
        }
        out(x); continue
      }
      if (x == C2) out(SQ); else if (x == C3) out(DQ); else if (x == C4) out("("); else if (x == C5) out(")"); else out(x)
    }
  }
  {
    nrec++
    if (nrec > 1) { if (pend) pend = 0; else out("\n") }
    if (mode == "maskfree") { maskline($0); next }
    if (mode == "restore") { restline($0); next }
    if (body) { bodyline($0); next }
    scanline($0)
  }
  END {
    if (cl > 0) chk[++nchk] = cur
    if (mode == "flags") { printf "R=%d C=%d Q=%d T=%d X=%d\n", fR, fC, fQ, fT, fX; exit 0 }
    if (mode == "join") { if (!joined) { print "NONE"; exit 0 } print "JOINED" }
    for (k = 1; k <= nchk; k++) printf "%s", chk[k]
  }
'
readonly FSB_ADDED_AWK='
  # FSB_ADDED_AWK - the second pass walk over one reading. stdin: "SEEN <n>", n seen pairs, then the reading.
  # Prints "PAIRS <k>", the k new verb<TAB>word pairs, then "WALKED". Exits 3 unless line 1 is the header and
  # the n counted pairs arrive. -v verbs="<the listed verbs>" -v cross=1 when the reading is canonicalizer output.
  BEGIN {
    SQ = sprintf("%c", 39); DQ = sprintf("%c", 34); BS = sprintf("%c", 92); TAB = sprintf("%c", 9)
    nv = split(verbs, va, " "); for (k = 1; k <= nv; k++) V[va[k]] = 1
    np = split("then do else elif in ! if while until sudo time env nohup command builtin exec xargs nice stdbuf timeout", pw, " ")
    for (k = 1; k <= np; k++) PW[pw[k]] = 1
    HX = "0123456789abcdef"
    hdr = 0; want = 0; got = 0; bad = 0; npairs = 0
    L = 0; rs(0); nsemi = 0; noth = 0; hsep = 0
  }
  function rs(l) { vb[l] = ""; sd[l] = 0; sk[l] = 0; xm[l] = 0; cw[l] = 0 }
  function hexv(ch) { return index(HX, tolower(ch)) - 1 }
  function lit(w,   n, k, ch, z, d, dl, nx, v, m, nul) {
    if (!index(w, SQ) && !index(w, DQ) && !index(w, BS) && !index(w, "$")) { if (w ~ /[`{*?[~]/ || length(w) > 32) return ""; return w }
    n = split(w, q, ""); z = 0; d = ""; dl = 0; nul = 0
    for (k = 1; k <= n; k++) {
      if (dl > 32) return ""
      ch = q[k]
      if (z == 0) {
        if (ch == SQ) { z = 1; continue }
        if (ch == DQ) { z = 2; continue }
        if (ch == BS) { if (k == n) return ""; k++; d = d q[k]; dl++; continue }
        if (ch == "$") { if (q[k + 1] == SQ) { z = 3; nul = 0; k++; continue } if (q[k + 1] == DQ) { z = 2; k++; continue } return "" }
        if (index("`{*?[~", ch) > 0) return ""
        d = d ch; dl++; continue
      }
      if (z == 1) { if (ch == SQ) z = 0; else { d = d ch; dl++ } continue }
      if (z == 2) {
        if (ch == DQ) { z = 0; continue }
        if (ch == "$" || ch == "`") return ""
        if (ch == BS && k < n) { nx = q[k + 1]; if (nx == "$" || nx == "`" || nx == DQ || nx == BS) { d = d nx; dl++; k++; continue } }
        d = d ch; dl++; continue
      }
      if (ch == SQ) { z = 0; continue }
      if (ch != BS || k == n) { if (!nul) { d = d ch; dl++ } continue }
      k++; nx = q[k]; v = -1
      if (nx == "a") v = 7; else if (nx == "b") v = 8; else if (nx == "e" || nx == "E") v = 27
      else if (nx == "f") v = 12; else if (nx == "n") v = 10; else if (nx == "r") v = 13
      else if (nx == "t") v = 9; else if (nx == "v") v = 11
      else if (nx == BS || nx == SQ || nx == DQ || nx == "?") v = -2
      else if (nx ~ /[0-7]/) { v = nx + 0; for (m = 1; m < 3 && q[k + 1] ~ /[0-7]/; m++) { k++; v = v * 8 + q[k] } }
      else if (nx == "x" || nx == "u" || nx == "U") {
        m = (nx == "x" ? 2 : (nx == "u" ? 4 : 8)); v = 0
        if (hexv(q[k + 1]) < 0) { v = -3 } else { while (m > 0 && hexv(q[k + 1]) >= 0) { k++; v = v * 16 + hexv(q[k]); m-- } }
      }
      else if (nx == "c") v = -4
      if (nul) continue
      if (v == -2) { d = d nx; dl++; continue }
      if (v == -3) { d = d BS nx; dl += 2; continue }
      if (v == -4) return ""
      if (v == -1) { d = d BS nx; dl += 2; continue }
      if (v == 0) { nul = 1; continue }
      if (v > 127) return ""
      d = d sprintf("%c", v); dl++
    }
    if (z != 0) return ""
    return d
  }
  function verbof(w,   t) {
    t = lit(w); if (t == "") return ""  # M-FSB-QVERB
    if (substr(t, 1, 1) == "=") t = substr(t, 2)
    sub(/^\/(usr\/(local\/)?|opt\/(homebrew|local)\/)?bin\//, "", t)
    return (t in V) ? t : ""
  }
  function pfx(w,   t) {
    if (w ~ /^[0-9]*[<>]/ || w ~ /^&>/) return 1
    t = w; if (substr(t, 1, 1) == BS) t = substr(t, 2)
    if (length(t) >= 2 && (substr(t, 1, 1) == SQ || substr(t, 1, 1) == DQ) && substr(t, length(t), 1) == substr(t, 1, 1)) t = substr(t, 2, length(t) - 2)
    sub(/.*\//, "", t)
    return (t in PW)
  }
  function emit(v, t,   p) { p = v TAB t; if ((p in seen) || (p in E)) return; E[p] = 1; P[++npairs] = p }
  function endseg(l) { rs(l) }
  function onsep() {
    if (xm[L] && cross && nsemi == 1 && noth == 0 && !pfx(NEXTW)) { xm[L] = (NEXTW ~ /^[A-Za-z_][A-Za-z0-9_]*[+]?=/) ? 1 : 0; return }
    endseg(L)
  }
  function casew(w, l) {
    if (cw[l] == 2) { cw[l] = 0; if (w == "in") { cs[l]++; csd[l, cs[l]] = pdp[l] } return }
    if (cw[l] == 1) { cw[l] = 2; return }
    if (w == "case") cw[l] = 1
    if (cs[l] > 0 && w ~ /^esac([);]|$)/) cs[l]--
  }
  function parens(w,   n, k, ch) {
    n = split(w, pq, "")
    for (k = 1; k <= n && L > 0; k++) {
      ch = pq[k]
      if (ch == "(") pdp[L]++
      else if (ch == ")") {
        if (cs[L] > 0 && pdp[L] == csd[L, cs[L]]) continue  # M-FSB-CASE
        pdp[L]--
        if (pdp[L] <= 0) { L--; xm[L] = 1 }
      }
    }
  }
  function word(w,   l, t, rem) {
    if (hsep) { NEXTW = w; onsep(); hsep = 0; nsemi = 0; noth = 0 }
    if (w ~ /^[<>=]\(/) {  # M-FSB-PSUB
      if (!sd[L]) { sd[L] = 1; vb[L] = "" }
      sk[L] = 0
      L++; rs(L); pdp[L] = 1; cs[L] = 0
      rem = substr(w, 3)
      if (rem != "") word(rem)
      return
    }
    l = L
    if (l > 0) casew(w, l)
    if (sk[l]) sk[l] = 0
    else if (!sd[l]) { sd[l] = 1; vb[l] = verbof(w) }
    else if (vb[l] != "") {
      if (w ~ /^[0-9]*[<>]/ || w ~ /^&>/ || w ~ /^\{[A-Za-z_][A-Za-z0-9_]*\}[<>]/) {
        if (w ~ /^([0-9]*|\{[A-Za-z_][A-Za-z0-9_]*\})([<>]|&>)[<>&|!]*$/) sk[l] = 1
      }
      else if (substr(w, 1, 1) != "-" && w !~ /^[(){}]+$/) {
        t = w; sub(/^(if|of|conv|status|bs|count|seek|skip|iflag|oflag)=/, "", t)
        if (t != "") emit(vb[l], t)
      }
    }
    if (l > 0) parens(w)
  }
  function walkline(s,   n, i, x, ws) {
    n = split(s, c, ""); ws = 0
    for (i = 1; i <= n; i++) {
      x = c[i]
      if (x == " " || x == "\t" || x == "\v" || x == "\f" || x == "\r" || x == ";" || x == "&" || x == "|") {
        if (ws) { word(substr(s, ws, i - ws)); ws = 0 }
        if (x == ";") { nsemi++; hsep = 1 } else if (x == "&" || x == "|") { noth++; hsep = 1 }
        continue
      }
      if (!ws) ws = i
    }
    if (ws) word(substr(s, ws, n - ws + 1))
    noth++; hsep = 1
  }
  NR == 1 { if ($0 !~ /^SEEN [0-9]+$/) { bad = 1; exit 3 } want = substr($0, 6) + 0; hdr = 1; next }
  got < want { seen[$0] = 1; got++; next }
  { walkline($0) }
  END {
    if (bad || !hdr || got < want) exit 3
    printf "PAIRS %d\n", npairs
    for (k = 1; k <= npairs; k++) printf "%s\n", P[k]
    printf "WALKED\n"
  }
'
readonly FSB_ALL_VERBS="${FSB_READ_VERBS} ${FSB_WRITE_VERBS}"
readonly FSB_P2_END="END${FSB_TAB}END"

# reading_not_evaluated <why> — a second-pass reading did not complete. Mode-coupled (ADR-078 D2):
#   enforce refuses; warn stands down loudly and writes a warn-log record whose rule field is
#   INPUT-NOT-EVALUATED, the record the enforce flip reads. Never returns.
reading_not_evaluated() {
  log_error "INPUT-NOT-EVALUATED: ${1}"
  if [ "$LIB_GUARD_MODE" = "enforce" ]; then
    "$PRINTF" '[CLAUDE-HOOK:%s:INPUT-NOT-EVALUATED] BLOCKED (fail-closed): the second pass could not read the command (%s); this is not a clean result: the hook could not evaluate its input. See %s.\n' "$HOOK_NAME" "$1" "$ERROR_LOG" >&2
    exit 2
  fi
  log_warn "INPUT-NOT-EVALUATED" "second pass not evaluated: ${1}"
  "$PRINTF" '[CLAUDE-HOOK:%s:INPUT-NOT-EVALUATED] WARN (degraded, .mode=%s): the second pass could not read the command (%s); this is not a clean result: the operands only the second pass reads were not judged this run.\n' "$HOOK_NAME" "$LIB_GUARD_MODE" "$1" >&2
  exit 0
}

# fsb_canon <text> — FSB_C = the canonicalizer's output on <text>.
fsb_canon() {
  FSB_OK=0
  FSB_C="$(/usr/bin/awk -f "$CMDPOS_AWK" <<< "$1")" || return 1
  if [ -z "$FSB_C" ] && [ -n "$1" ]; then return 1; fi
  FSB_OK=1
}
# fsb_lex <mode> <text> [awk -v assignments] — FSB_L = the lexer's output on <text>.
fsb_lex() {
  local m="$1" t="$2"
  FSB_OK=0
  shift 2
  FSB_L="$(LC_ALL=C /usr/bin/awk -v mode="$m" "$@" "$FSB_LEX_AWK" <<< "$t")" || return 1
  FSB_OK=1
}
# fsb_walk <reading> <cross> — walk one reading; append its new pairs to FSB_OUT and FSB_SEEN.
fsb_walk() {
  local w k body
  FSB_OK=0
  w="$(LC_ALL=C /usr/bin/awk -v verbs="$FSB_ALL_VERBS" -v cross="$2" "$FSB_ADDED_AWK" <<< "SEEN ${FSB_SEEN_N}${FSB_NL}${FSB_SEEN}${1}")" || return 1
  case "$w" in
    "PAIRS "*"${FSB_NL}WALKED") : ;;
    *) return 1 ;;
  esac
  k="${w%%"$FSB_NL"*}"; k="${k#PAIRS }"
  case "$k" in ''|*[!0-9]*) return 1 ;; esac
  if [ "$k" != 0 ]; then
    body="${w#*"$FSB_NL"}"; body="${body%WALKED}"
    FSB_OUT="${FSB_OUT}${body}"; FSB_SEEN="${FSB_SEEN}${body}"; FSB_SEEN_N=$((FSB_SEEN_N + k))
  fi
  FSB_OK=1
}
# fsb_walk_joined <reading> <cross> — the reading with its continuations joined, when it has one.
fsb_walk_joined() {
  FSB_OK=0
  fsb_lex join "$1" -v canon=1; [ "$FSB_OK" = 1 ] || return 1
  case "$FSB_L" in
    NONE) FSB_OK=1; return 0 ;;
    JOINED"$FSB_NL"*) fsb_walk "${FSB_L#JOINED"$FSB_NL"}" "$2"; [ "$FSB_OK" = 1 ] || return 1 ;;
    *) return 1 ;;
  esac
  FSB_OK=1
}
# fsb_restore <text> <scheme> — FSB_R = <text> with each neutral code mapped back.
fsb_restore() {
  FSB_OK=0
  fsb_lex restore "$1" -v scheme="$2"; [ "$FSB_OK" = 1 ] || return 1
  FSB_R="$FSB_L"; FSB_OK=1
}
# fsb_base <text> <first-pass canonical or empty> <joined 0|1> — every reading of one base text.
fsb_base() {
  local t="$1" c0="$2" j="$3" f r=0 q=0 x=0 sc=1 tr cr ch="" rp="" chr
  FSB_OK=0
  fsb_lex flags "$t"; [ "$FSB_OK" = 1 ] || return 1; f="$FSB_L"
  case "$f" in "R="*" C="*" Q="*" T="*" X="*) : ;; *) return 1 ;; esac
  case "$f" in *"R=1"*) r="$FSB_REDIR" ;; esac
  case "$f" in *"Q=1"*) q=1 ;; esac
  case "$f" in *"T=1"*) x="$FSB_HDQ" ;; esac
  case "$f" in *"X=1"*) sc=2 ;; esac
  case "$f" in *"C=1"*) FSB_BASE_CJ="$FSB_JOINS" ;; *) FSB_BASE_CJ=0 ;; esac
  [ "$FSB_JOINS" = 1 ] || j=1
  tr="$t"
  if [ "$r" = 1 ]; then fsb_lex text "$t" -v redir=1; [ "$FSB_OK" = 1 ] || return 1; tr="$FSB_L"; fi
  if [ "$r" = 0 ] && [ -n "$c0" ]; then cr="$c0"; else fsb_canon "$tr"; [ "$FSB_OK" = 1 ] || return 1; cr="$FSB_C"; fi
  fsb_walk "$cr" "$([ "$cr" != "$tr" ] && echo 1 || echo 0)"; [ "$FSB_OK" = 1 ] || return 1
  if [ "$j" = 0 ]; then fsb_walk_joined "$cr" 1; [ "$FSB_OK" = 1 ] || return 1; fi
  if [ "$x" = 1 ]; then
    fsb_lex text "$t" -v redir="$r" -v repair=1 -v scheme="$sc"; [ "$FSB_OK" = 1 ] || return 1; rp="$FSB_L"
    fsb_canon "$rp"; [ "$FSB_OK" = 1 ] || return 1; ch="$FSB_C"
    fsb_restore "$ch" "$sc"; [ "$FSB_OK" = 1 ] || return 1; chr="$FSB_R"
    fsb_walk "$chr" "$([ "$ch" != "$rp" ] && echo 1 || echo 0)"; [ "$FSB_OK" = 1 ] || return 1
    if [ "$j" = 0 ]; then fsb_walk_joined "$chr" 1; [ "$FSB_OK" = 1 ] || return 1; fi
  fi
  if [ "$FSB_MASKFREE" = 1 ] && [ "$cr" = "$tr" ] && [ "$q" = 1 ] && { [ "$x" = 0 ] || [ "$ch" = "$rp" ]; }; then
    fsb_lex maskfree "$tr" -v scheme="$sc"; [ "$FSB_OK" = 1 ] || return 1; rp="$FSB_L"
    fsb_canon "$rp"; [ "$FSB_OK" = 1 ] || return 1; ch="$FSB_C"
    fsb_restore "$ch" "$sc"; [ "$FSB_OK" = 1 ] || return 1; chr="$FSB_R"
    fsb_walk "$chr" "$([ "$ch" != "$rp" ] && echo 1 || echo 0)"; [ "$FSB_OK" = 1 ] || return 1
    if [ "$j" = 0 ]; then fsb_walk_joined "$chr" 1; [ "$FSB_OK" = 1 ] || return 1; fi
  fi
  FSB_OK=1
}
# fsb_pass2 — build every reading, then judge every new pair. Runs inside the command
#   substitution below; its last statement prints the completion line.
fsb_pass2() {
  local v t judged=0
  FSB_OUT=""
  fsb_base "$COMMAND" "$COMMAND_CMDPOS" 0; [ "$FSB_OK" = 1 ] || return 41
  if [ "$FSB_BASE_CJ" = 1 ]; then
    fsb_lex join "$COMMAND"; [ "$FSB_OK" = 1 ] || return 42
    case "$FSB_L" in
      NONE) : ;;
      JOINED"$FSB_NL"*) fsb_base "${FSB_L#JOINED"$FSB_NL"}" "" 1; [ "$FSB_OK" = 1 ] || return 43 ;;
      *) return 44 ;;
    esac
  fi
  FSB_OUT="${FSB_OUT}${FSB_P2_END}"
  while IFS="$FSB_TAB" read -r v t; do
    if [ "$v" = END ] && [ "$t" = END ]; then judged=1; break; fi
    case " $FSB_WRITE_VERBS " in
      *" $v "*) judge_operand "$v" WRITE "$t" ;;
      *) judge_operand "$v" READ "$t" ;;
    esac
  done <<< "$FSB_OUT"
  [ "$judged" = 1 ] || return 45
  "$PRINTF" '%s' JUDGED
}
# fsb_run_pass2 — FSB_P2_RES and FSB_P2_RC = the second pass's output and exit status.
#   The substitution stands as a plain assignment: never on the left of an and-or list, never in
#   an if or while test. Bash ignores errexit for every command a function runs in such a
#   position, and the Linux hook-harness job's bash 5.3 carried that into the substitution, so an
#   unchecked failing command inside the pass ran on and the pass printed its completion line;
#   macOS bash 3.2 honoured the re-armed errexit in either position. The hook's own errexit is
#   suspended around the one assignment, and a function does not inherit the ERR trap, so a
#   non-zero status reaches the dispatch below instead of ending the hook.
fsb_run_pass2() {
  set +e
  FSB_P2_RES="$(set -e; fsb_pass2)"
  FSB_P2_RC="$?"
  set -e
}

# ==========================================================================
# RULE EVALUATION
# ==========================================================================

# File-read verb class — BLOCK-FS-BOUNDARY-001 (or -003 if unresolvable)
for verb in $FSB_READ_VERBS; do
  check_verb "$verb" READ
done

# File-write verb class — BLOCK-FS-BOUNDARY-002 (or -003 if unresolvable)
# For cp/mv: both source AND target may resolve outside; extract_target_tokens
# yields all positional args, both are checked uniformly.
# For tee/dd: target matters for write-leak.
for verb in $FSB_WRITE_VERBS; do
  check_verb "$verb" WRITE
done

# The second pass, gated on the canonicalizer's canary: on the warn-degraded path it does not run,
# and says so in the warn log (enforce has already refused at the canary).
if [ "$FSB_PASS2" != 1 ]; then  :                        # the second pass's off switch (M-FSB-PASS2)
elif [ "$CMDPOS_OK" = 1 ]; then
  FSB_P2_RC=0
  fsb_run_pass2
  case "$FSB_P2_RC" in
    0) [ "$FSB_P2_RES" = JUDGED ] || reading_not_evaluated "no completion line" ;;
    2) if [ "$MODE" = "enforce" ]; then exit 2; fi; reading_not_evaluated "exit 2 under warn" ;;
    *) reading_not_evaluated "exit ${FSB_P2_RC}" ;;
  esac
else
  log_warn "INPUT-NOT-EVALUATED" "second pass not evaluated: the command-position canonicalizer failed its canary"
fi

# No matcher-verb detected — allow
exit 0
