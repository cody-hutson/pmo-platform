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
# (see resolve_and_classify). Command substitution, backticks, the canonicalizer's
# quoted-span sentinel, literal `..` traversal and normalizer failure are refused
# under -003; a decidable literal prefix is classified under -001/-002; an operand
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
CMDPOS_OK=0
if [ -r "$CMDPOS_AWK" ]; then
  if _cp_canary="$("$PRINTF" '%s' 'q() { r; }' | /usr/bin/awk -f "$CMDPOS_AWK" 2>/dev/null)" \
     && "$PRINTF" '%s' "$_cp_canary" | "$GREP" -q '; r'; then
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
matches() {
  local pattern="$1"
  "$PRINTF" '%s' "$COMMAND_CMDPOS" | "$GREP" -qE "$pattern"
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
render_token() {
  local t="$1"
  "$PRINTF" '%s' "${t//$CMDPOS_SENTINEL/<quoted-expansion>}"
}

# _split_expansions(token)
#   Split an expansion-bearing token into its SKELETON (each expansion span replaced by
#   $EXPANSION_SENTINEL) and its literal PREFIX (the text before the FIRST expansion).
#   Recognized expansion spans: $NAME, an UNQUOTED ${...}, and the $1/$@/$#/$*/$?/$$/$!
#   positional-and-special class. A `$` that introduces none of these is NOT guessed at —
#   the function fails and the caller refuses. Conservative by construction.
#   Sets: _SK, _PFX. Returns 0 on a clean split, 1 when a `$` is unrecognizable.
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
        # Unquoted ${...}. A QUOTED one never reaches here — it carries the sentinel
        # and was already refused by G1.
        case "$after" in
          *\}*) inner="${after%%\}*}"; consumed="\$${inner}}";;
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
#   Ordered guard cascade (refuse-before-decide: G0/G1/G2 precede any span analysis, so
#   an ambiguous or executable construct can never reach the code that could admit it):
#
#     G0  token is exactly $XARGS-STDIN (canonicalizer's stdin sentinel)  -> REFUSE  -003
#     G1  token carries the \001 quoted-span sentinel (ambiguous)         -> REFUSE  -003
#     G2  token contains $( or a backtick (execution surface)             -> REFUSE  -003
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

  # --- G2: unquoted execution surface. ---
  # shellcheck disable=SC2016  # literal char matches in case glob; not expansions
  case "$token" in
    *\$\(*) return 2;;
    *\`*)   return 2;;
  esac

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
#   expansion, carrying no $(, no backtick, no \001 sentinel, and no `..` in any literal
#   span. It is ADMITTED, and the admission is recorded whenever this function is reached.
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

# check_verb(verb, rule_id_class)
#   Run the verb-detection + per-token classification loop.
#   rule_id_class: "READ" → BLOCK-FS-BOUNDARY-001 / -003 / -004
#                  "WRITE" → BLOCK-FS-BOUNDARY-002 / -003 / -004
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
          "${verb} target unresolvable under strict policy (variable/subshell/backtick/traversal token, or path-normalizer unavailable): $(render_token "$token")" \
          "use explicit absolute paths without .. traversal instead of variables/subshells, ensure python3 is installed, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional" || true
        ;;
      3)
        advise_unresolvable "$verb" "$token"
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
