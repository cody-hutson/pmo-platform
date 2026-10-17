#!/usr/bin/env bash
# block-rm-prefer-trash.sh — PreToolUse hook enforcing workspace deletion containment
# and Trash-redirect convention.
# hook-owner: core/rules/bypass-mode-readiness/block-rm-prefer-trash.md
#
# Outside ${WORKSPACE_ROOT}/, file deletion via rm/rmdir/unlink/trash/osascript
# Trash-verb is BLOCKED, with ONE admitted class: a Trash move of a single
# auto-memory entry (see MEMORY-STORE ARM). Inside the workspace, rm/rmdir/unlink is
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

# --- MEMORY-STORE ARM: where the auto-memory store is declared ---
# Read from the operator's USER-scope settings file only — the same file the installer
# re-homes this hook's own PreToolUse wiring into — so the arm and the guard carrying it
# share one trust root. Deliberately no environment override: Claude Code ignores
# platform-only variables, so an override could re-point the arm while the hooks stay
# wired, and BLOCK-DESTRUCTIVE-023 does not cover one. Project and local settings are
# repository-supplied, so they never admit: they are read only to word a refusal (see
# memory_arm_verdict). Tests sandbox HOME.
readonly MEMORY_SETTINGS_FILE="${HOME:-}/.claude/settings.json"

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
# Pattern is duplicated across the 4 regex-based PreToolUse hooks
# (block-destructive.sh, block-egress.sh, block-fs-boundary.sh,
# block-rm-prefer-trash.sh) — extracted as a per-hook constant to surface
# the convention and keep each hook file-local-self-contained per the
# existing posture. Future prefix-set additions require a coordinated
# 4-hook edit (see Stage 5 spec Approach 1 trade-off discussion).
readonly ANCHOR_PREFIX_BASH='(^|[;&|])[[:space:]]*(/(usr/(local/)?|opt/(homebrew|local)/)?bin/)?'

# --- COMMAND-POSITION CANONICALIZER (shared primitive) ---
# The anchor above recognises a command start ONLY at start-of-line or after `;`, `&`,
# `|`. Every other position at which a shell starts a command — `{ … }`, `( … )`,
# `then`/`do`, `sudo`/`env`/`xargs`/`VAR=…`, `\rm` — was invisible to it, so the verdict
# tracked lexical POSITION rather than the action and a deletion became invisible by
# being wrapped. Rather than widen the anchor (which would make the regex the deny
# authority over a loose pattern), the command is canonicalized FIRST so that genuine
# command starts become positions this anchor already recognises. The anchor, the rule
# IDs and the messages are unchanged; the tokenizer below stays the sole deny authority.
# ONE implementation, shared by all four anchor-carrying hooks — four agreeing copies is
# how this cohort drifted into a common blind spot in the first place.
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

# --- EARLY EXIT: non-Bash tool calls ---
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

COMMAND="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.command // empty')"
[ -z "$COMMAND" ] && exit 0

# --- CANONICALIZE COMMAND POSITIONS (see CMDPOS_AWK above) ---
# Verify the primitive actually WORKS before trusting its output. A present-but-empty,
# truncated or corrupt awk would emit an empty string, and every matcher below would then
# find nothing — the whole hook would fail OPEN, which is strictly worse than the gap this
# closes. Canary: a one-line function body, whose canonical form MUST expose the inner
# command at an anchor position. Same posture as block-fragile-refs.sh's classifier canary
# (GHSA-g9g6-28c9-vrx5), and the same fail-closed direction as the dependency guard above.
CMDPOS_OK=0
if [ -r "$CMDPOS_AWK" ]; then
  if _cp_canary="$("$PRINTF" '%s' 'q() { r; }' | /usr/bin/awk -f "$CMDPOS_AWK" 2>/dev/null)" \
     && "$PRINTF" '%s' "$_cp_canary" | "$GREP" -q '; r'; then
    CMDPOS_OK=1
  fi
fi
if [ "$CMDPOS_OK" != 1 ]; then
  log_error "PRIMITIVE-MISSING-OR-INVALID: command-position.awk unusable at $CMDPOS_AWK"
  deny_missing_primitive "command-position.awk" "$HOOK_NAME" "$PRINTF"
  exit 2   # caller owns the fail-closed exit — never trust the callee to terminate
fi
COMMAND_CMDPOS="$("$PRINTF" '%s' "$COMMAND" | /usr/bin/awk -f "$CMDPOS_AWK" 2>/dev/null || "$PRINTF" '%s' "$COMMAND")"
# Belt-and-braces: a non-empty command must never canonicalize to nothing.
[ -n "$COMMAND_CMDPOS" ] || COMMAND_CMDPOS="$COMMAND"

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

# block_cwd_unknown(rule_id, token) — the strict-policy refusal for a relative operand whose
#   working directory cannot be determined (resolve_and_classify class 3). Same rule IDs as
#   the unresolvable-token refusal; the reason names the basis instead of the token's form.
block_cwd_unknown() {
  block "$1" \
    "path is unresolvable under strict policy: this command changes directory in a form the hook cannot follow, so the working directory for relative target '$2' cannot be determined" \
    "name the target by absolute path, or make the directory change a literal path, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
}

# Pattern match against the canonicalized command. Rule patterns are unchanged; only the
# text they read is, so a verb at any genuine command start is now anchored. Direct
# "$COMMAND" readers below (the osascript POSIX-file extractor) deliberately keep the RAW
# command — they parse quoted argument text, which canonicalization is not for.
matches() {
  local pattern="$1"
  "$PRINTF" '%s' "$COMMAND_CMDPOS" | "$GREP" -qE "$pattern"
}

# classify_path(path) — Steps 5-6 below: normalize an absolute path and prefix-match it
#   against WORKSPACE_ROOT. Prints the normalized path; returns 0 inside, 1 outside.
classify_path() {
  local resolved="$1"
  # Normalize via Python os.path.realpath — collapses ../ and ./,
  # does not require existence, follows symlinks (intentional for strict-
  # boundary enforcement). Python 3.9+ is system-default on macOS 12+.
  # Stage 5 spec referenced /usr/bin/realpath -m (GNU); macOS ships BSD
  # realpath without -m, so Python 3 is the portable equivalent.
  if [ -x "$PYTHON3" ]; then
    resolved="$("$PYTHON3" -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$resolved" 2>/dev/null || echo "$resolved")"
  fi
  "$PRINTF" '%s' "$resolved"
  case "$resolved" in
    "${WORKSPACE_ROOT}"|"${WORKSPACE_ROOT}/"*) return 0 ;;
    *) return 1 ;;
  esac
}

# resolve_and_classify(token, [seg])
#   Resolve a path token and classify against workspace boundary.
#   Returns: 0 = inside workspace, 1 = outside workspace, 2 = unresolvable (strict),
#            3 = relative operand whose working directory cannot be determined (strict)
#   Outputs the resolved absolute path on stdout (when return is 0 or 1). For a relative
#   operand, a newline and the directory it was judged from follow (see split_verdict).
#   seg is the operand's segment number (SEGMENT_WALK_AWK); empty means "after every
#   segment". ensure_cwd_table must have run in the hook's own shell first.
resolve_and_classify() {
  local token="$1"
  local seg="${2:-}"
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
    /*)
      # Steps 5-6 (classify_path); the || keeps a non-zero class out of errexit's reach
      classify_path "$token" || return "$?"
      return 0
      ;;
  esac
  if [ -z "$CWD" ]; then
    # No cwd available — treat as unresolvable
    return 2
  fi

  # Step 4b: a relative operand lands under the directory the command is in when the verb
  # runs (see IN-COMMAND WORKING DIRECTORY). Judge it from every such directory; the worst
  # class decides, and the message names the first directory that reached it — the
  # nearest earlier change, else the payload cwd. With no change on the line the only
  # candidate is the payload cwd, which is the join this step has always made.
  local bases="" brc=0 base c p worst=-1 worst_path="" worst_base=""
  bases="$(cwd_candidates_for "$seg")" || brc="$?"
  if [ "$brc" != 0 ]; then
    return 3
  fi
  while IFS= read -r base; do
    [ -n "$base" ] || continue
    c=0
    p="$(classify_path "${base}/${token}")" || c="$?"
    if [ "$c" -gt "$worst" ]; then worst="$c"; worst_path="$p"; worst_base="$base"; fi
  done <<< "$bases"
  if [ "$worst" -lt 0 ]; then
    return 3
  fi
  "$PRINTF" '%s\n%s' "$worst_path" "$worst_base"
  return "$worst"
}

# --- MEMORY-STORE ARM: the one admitted class outside ${WORKSPACE_ROOT}/ ---
# A Trash move of ONE auto-memory entry — the EVICT act of the memory<->corpus lifecycle
# (core/disciplines/knowledge-architecture.md § Memory↔corpus boundary), re-scoped out of
# Tier 0 by core/specs/autonomy-tiers.md § Irreducible Human Tasks item 8a. ONE python3
# program with ONE admitting token: python3 unusable, settings absent or malformed, or any
# exception prints nothing, and the caller falls through to its existing refusal. It never
# consumes resolve_and_classify's raw-path fallback — an allow path must not open when the
# normalizer is missing. The operand is judged first, so a command whose operand cannot be
# an entry never opens a settings file. Admits (ELIGIBLE) only when ALL hold:
#   operand - written only in characters the shell passes through unchanged, absolute
#             (bare or wholly quoted; a ~/-led operand is not admitted), with no ".."
#             component; its leaf ends ".md", has no leading dot and is not MEMORY.md
#             (case-insensitive: realpath keeps the typed case on case-insensitive
#             volumes); an existing regular file and not a symlink (Trash moves the link
#             the operand names, not its referent)
#   store   - autoMemoryDirectory in the USER-scope file: absolute or ~/-prefixed, no
#             control characters, a strict descendant of $HOME, holding a MEMORY.md
#   place   - the operand's resolved parent IS the resolved store
# The verdict is reached once, when the hook judges; the command resolves the operand again
# when it runs, so the path judged is the path moved only while the operand's directories
# are unchanged between the two: the judgment-time class every path-resolving rule carries.
# A store that only project or local settings declare is never admitted. The program then
# prints OUTSIDE-USER-SCOPE, so the refusal can say why: the arm reads user scope only.
readonly MEMORY_ARM_PY='
import json, os, re, sys
settings, home, tok, proj = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

def store_of(path):
    try:
        with open(path, encoding="utf-8") as fh:
            cfg = json.load(fh)
    except Exception:
        return None
    val = cfg.get("autoMemoryDirectory") if isinstance(cfg, dict) else None
    if not isinstance(val, str) or not val or any(ord(c) < 32 for c in val):
        return None
    if val.startswith("~/"):
        val = home + val[1:]
    elif not val.startswith("/"):
        return None
    h = os.path.realpath(home)
    store = os.path.realpath(val)
    if store == h or os.path.commonpath([store, h]) != h:
        return None
    if not os.path.isfile(os.path.join(store, "MEMORY.md")):
        return None
    return store

try:
    if not home.startswith("/"):
        sys.exit(0)
    quoted = len(tok) >= 2 and tok[0] == tok[-1] and tok[0] in ("\x22", "\x27")
    if quoted:
        tok = tok[1:-1]
    if not re.fullmatch("[A-Za-z0-9._/+@,:%=-]+", tok) or ".." in tok.split("/"):
        sys.exit(0)
    if not tok.startswith("/"):
        sys.exit(0)
    leaf = os.path.basename(tok)
    if leaf.startswith(".") or not leaf.endswith(".md") or leaf.casefold() == "memory.md":
        sys.exit(0)
    if os.path.islink(tok) or not os.path.isfile(tok):
        sys.exit(0)
    parent = os.path.realpath(os.path.dirname(tok))
    if store_of(settings) == parent:
        print("ELIGIBLE")
        sys.exit(0)
    if proj.startswith("/"):
        user = os.path.realpath(settings)
        for name in ("settings.json", "settings.local.json"):
            cand = os.path.join(proj, ".claude", name)
            if os.path.realpath(cand) != user and store_of(cand) == parent:
                print("OUTSIDE-USER-SCOPE")
                sys.exit(0)
except Exception:
    sys.exit(0)
'

# memory_arm_verdict(token) — print the MEMORY-STORE ARM's verdict on token: ELIGIBLE,
#   OUTSIDE-USER-SCOPE, or nothing. Project and local settings are looked for under the
#   project root Claude Code passes its hooks, else under the tool call's working
#   directory. Always returns 0, so its output can be captured under set -e.
memory_arm_verdict() {
  [ -x "$PYTHON3" ] || return 0
  "$PYTHON3" -c "$MEMORY_ARM_PY" "$MEMORY_SETTINGS_FILE" "${HOME:-}" "$1" "${CLAUDE_PROJECT_DIR:-$CWD}" 2>/dev/null || true
}

# record_memory_admissions — append one admission row per admitted operand to BLOCK_LOG:
#   one compact JSON line each, carrying the command's digest and never its text or the
#   entry's path, and no rule key (an admission is not a refusal). Returns non-zero when
#   any row cannot be written, and the caller then refuses. Call ONLY as an `if` condition.
record_memory_admissions() {
  local ts digest i=0
  ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  digest="$("$PRINTF" '%s' "$COMMAND" | "$SHASUM" -a 256 2>/dev/null)" || return 1
  digest="${digest%% *}"
  digest="${digest:0:16}"
  [ "${#digest}" = 16 ] || return 1
  while [ "$i" -lt "$MEMORY_ADMISSIONS" ]; do
    # shellcheck disable=SC2016  # jq filter — single quotes intentional
    "$JQ" -n -c --arg ts "$ts" --arg hook "$HOOK_NAME" --arg tool "$TOOL_NAME" \
      --arg digest "$digest" --arg cwd "$CWD" \
      '{ts:$ts, hook:$hook, action:"memory-evict-admit", tool:$tool, input_digest:$digest, cwd:$cwd}' \
      2>/dev/null >> "$BLOCK_LOG" || return 1
    i=$((i + 1))
  done
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
#
#   fix F3 (#5644): reads the CANONICALIZED command, not the raw one.
#   This is the same atomic coupling in a new place — the regex above
#   and this tokenizer must agree on where a command starts. Pointing
#   only the regex at the canonical form would fire the gate and then
#   extract nothing (silent no-op); pointing only this one would leave
#   the regex gating first and close a fraction of the positions.
#
#   Each token is emitted as `<segment-number><TAB><token>`. Segments are
#   numbered across the whole command, lines included, by the SAME walk that
#   extract_dir_events() runs, so a target and a directory change are ordered
#   against one numbering: a third reader of the canonical form, under the
#   same coupling. A `--` ends option parsing, so a dash-led token after it is
#   an operand, and a redirection is not an operand at all.
#
# SEGMENT_WALK_AWK — the one segmentation both readers share.
#   mode "targets": print `<seg><TAB><token>` for each operand of verb v.
#   mode "dirs":    print `<seg><TAB><kind><TAB><operand>` for each directory change,
#                   kind DIR (one literal operand), HOME (bare cd) or UNKNOWN (a form
#                   whose destination cannot be read from the line), plus a
#                   `0<TAB>REENTRANT` line when a loop or function definition can run a
#                   segment again after a later one (so order on the line is not order
#                   of execution).
# shellcheck disable=SC2016  # awk program — single quotes intentional
readonly SEGMENT_WALK_AWK='
  function skip_redirect(t) {
    # A redirection is not an operand; a bare operator takes the next token with it.
    if (t ~ /^[0-9]*(>>|>|<)/) { if (t ~ /(>>|>|<)$/) skipnext = 1; return 1; }
    return 0;
  }
  function dir_event(   w, i, t, nops, op, bad, endopts, flags) {
    w = tokens[first];
    if (w ~ /^(for|while|until|select|repeat|foreach|function)$/ || segments[s] ~ /\(\)/) reentrant = 1;
    if (w != "cd" && w != "chdir" && w != "pushd" && w != "popd") return;
    # popd returns to a directory-stack entry, which can predate this command.
    if (w == "popd") { print seg "\tUNKNOWN\t"; return; }
    flags = (w == "pushd") ? "^-[LPqs]+$" : "^-[LPeqs@]+$";
    nops = 0; bad = 0; endopts = 0; skipnext = 0; op = "";
    for (i = first + 1; i <= m; i++) {
      t = tokens[i];
      if (t == "") continue;
      if (skipnext) { skipnext = 0; continue; }
      if (skip_redirect(t)) continue;
      if (t ~ /^[(){}]+$/) continue;
      if (!endopts && t == "--") { endopts = 1; continue; }
      # `-`, a stack form (`-N`, `+N`) or an unknown option: destination unreadable.
      if (!endopts && t ~ /^[-+]/) { if (t !~ flags) bad = 1; continue; }
      nops++; op = t;
    }
    if (bad || nops > 1) print seg "\tUNKNOWN\t";
    else if (nops == 0) print seg "\t" ((w == "pushd") ? "UNKNOWN" : "HOME") "\t";
    else print seg "\tDIR\t" op;
  }
  {
    # Split on command separators first; each segment is separator-free.
    n = split($0, segments, /[;&|]+/);
    for (s = 1; s <= n; s++) {
      seg++;
      m = split(segments[s], tokens, /[[:space:]]+/);
      first = 0;
      for (i = 1; i <= m; i++) {
        if (tokens[i] != "") { first = i; break; }
      }
      if (first == 0) continue;
      if (mode == "dirs") { dir_event(); continue; }
      # Strip canonical absolute-path prefix from first token before
      # verb-equality check. Matches the 5 macOS/Linux paths
      # captured by ANCHOR_PREFIX_BASH at the regex-anchor site.
      first_token = tokens[first];
      sub(/^\/(usr\/(local\/)?|opt\/(homebrew|local)\/)?bin\//, "", first_token);
      if (first_token != v) continue;
      endopts = 0; skipnext = 0;
      for (i = first + 1; i <= m; i++) {
        t = tokens[i];
        if (t == "") continue;
        if (skipnext) { skipnext = 0; continue; }
        if (skip_redirect(t)) continue;
        # Skip bare shell structure. A subshell leaves its closing `)` inside
        # the segment, and without this `( rm -rf )` would resolve `)` as a
        # relative path and block a targetless no-op (#5644).
        if (t ~ /^[(){}]+$/) continue;
        # Skip flags (start with -) until a `--` ends option parsing.
        if (!endopts && t == "--") { endopts = 1; continue; }
        if (!endopts && substr(t, 1, 1) == "-") continue;
        print seg "\t" t;
      }
    }
  }
  END { if (mode == "dirs" && reentrant) print "0\tREENTRANT\t"; }
'

extract_target_tokens() {
  local verb="$1"
  "$PRINTF" '%s' "$COMMAND_CMDPOS" | /usr/bin/awk -v mode="targets" -v v="$verb" "$SEGMENT_WALK_AWK"
}

# extract_dir_events — the directory changes on the line, in SEGMENT_WALK_AWK's "dirs" form.
extract_dir_events() {
  "$PRINTF" '%s' "$COMMAND_CMDPOS" | /usr/bin/awk -v mode="dirs" -v v="" "$SEGMENT_WALK_AWK"
}

# --- IN-COMMAND WORKING DIRECTORY ---
# The payload cwd is where the call STARTS. A directory change earlier on the line moves
# where a relative operand lands, so a relative target is judged from every directory the
# command can be in when its verb runs: the payload cwd, plus each directory a change in an
# EARLIER segment can lead to. The set only grows — a failed `cd` before `;`, a subshell, a
# pipeline stage all leave an earlier directory in effect, so none is ever dropped — and the
# worst class over the set decides. Where a loop or function definition can re-run a
# segment, every change on the line counts, whatever its position.
#
# CWD_TABLE_PY turns the dirs-mode events into that set. One python3 program; it ends its
# output with an END line, and output without one is read as failure, so a normalizer that
# cannot run never yields a raw-joined directory. Per event it prints each NEW directory as
# `<seg><TAB>DIR<TAB><dir>`, or `<seg><TAB>UNKNOWN` when the destination cannot be read:
#   - the operand is not literal: a variable, a substitution, a glob or brace, an escape,
#     a quote that does not wrap the whole word, a `~user` or zsh `=cmd` word;
#   - the operand is relative and cannot be anchored: the payload cwd is unknown, a loop or
#     function can repeat the change, or the line names CDPATH (a bare name is then searched
#     for along it);
#   - the set would pass LIMIT directories.
# Each destination is recorded in BOTH readings: the lexical one (`cd` is logical by
# default, so `..` climbs the path as typed) and the resolved one (`cd -P`, and what the
# operating system resolves a relative operand against). Either can be the true one.
readonly CWD_TABLE_PY='
import os, re, sys
cwd, home = sys.argv[1], sys.argv[2]
reentrant, cdpath = sys.argv[3] == "1", sys.argv[4] == "1"
LIMIT = 64
LITERAL = re.compile("[A-Za-z0-9._/+@,:%~-][A-Za-z0-9._/+@,:%=~-]*")
cands = [cwd] if cwd.startswith("/") else []

def literal(raw):
    q = raw[:1]
    if len(raw) >= 2 and q in ("\x27", "\x22") and raw[-1] == q:
        body = raw[1:-1]
        banned = "\x27\x01" if q == "\x27" else "\x22$`\\\x01"
        if not body or any(c in banned for c in body):
            return None
        return body
    if not LITERAL.fullmatch(raw):
        return None
    if raw == "~" or raw.startswith("~/"):
        return home + raw[1:] if home.startswith("/") else None
    if raw.startswith("~"):
        return None
    return raw

def land(path):
    if path.startswith("/"):
        joined = [path]
    else:
        if reentrant or cwd[:1] != "/":
            return None
        if cdpath and not (path in (".", "..") or path.startswith(("./", "../"))):
            return None
        joined = [os.path.join(c, path) for c in cands]
    out = []
    for p in joined:
        for form in (os.path.normpath(p), os.path.realpath(p)):
            if form not in out:
                out.append(form)
    return out

try:
    for line in sys.stdin:
        seg, kind, raw = (line.rstrip("\n").split("\t") + ["", ""])[:3]
        if kind == "REENTRANT":
            continue
        if kind == "HOME":
            path = home if home.startswith("/") else None
        elif kind == "DIR":
            path = literal(raw)
        else:
            path = None
        dirs = land(path) if path is not None else None
        new = [d for d in dirs if d not in cands] if dirs is not None else None
        if new is None or len(cands) + len(new) > LIMIT:
            print(seg + "\tUNKNOWN")
            continue
        cands = new + cands
        for d in new:
            print(seg + "\tDIR\t" + d)
    print("-\tEND")
except Exception:
    print("0\tUNKNOWN")
'

readonly TAB=$'\t'
readonly NL=$'\n'
CWD_TABLE_READY=0
CWD_EVT_SEG=()        # segment of each directory a change can lead to
CWD_EVT_DIR=()        # ... and the directory
CWD_UNKNOWN_SEG=""    # first segment whose change cannot be followed, if any
CWD_REENTRANT=0       # 1 when a loop or function can re-run a segment

# ensure_cwd_table — build the in-command working-directory table once. Call it in the
# hook's own shell (never inside $( )), before the first relative target is judged. A
# command with no directory change builds nothing and judges exactly as before.
ensure_cwd_table() {
  local events="" table="" cdpath=0 eseg ekind edir
  if [ "$CWD_TABLE_READY" = 1 ]; then return 0; fi
  CWD_TABLE_READY=1
  events="$(extract_dir_events)" || events="0${TAB}UNKNOWN${TAB}"
  case "$events" in *"${TAB}REENTRANT${TAB}"*) CWD_REENTRANT=1 ;; esac
  case "$events" in *"${TAB}DIR${TAB}"*|*"${TAB}HOME${TAB}"*|*"${TAB}UNKNOWN${TAB}"*) ;; *) return 0 ;; esac
  case "$COMMAND" in *CDPATH*) cdpath=1 ;; esac
  if [ -x "$PYTHON3" ]; then
    table="$("$PRINTF" '%s\n' "$events" | "$PYTHON3" -c "$CWD_TABLE_PY" "$CWD" "${HOME:-}" "$CWD_REENTRANT" "$cdpath" 2>/dev/null)" || table=""
  fi
  if [ "${table##*"$NL"}" != "-${TAB}END" ]; then
    # The normalizer could not run, or did not finish: no change on this line is followed.
    CWD_UNKNOWN_SEG=0
    return 0
  fi
  while IFS="$TAB" read -r eseg ekind edir; do
    case "$ekind" in
      DIR)
        CWD_EVT_SEG[${#CWD_EVT_SEG[@]}]="$eseg"
        CWD_EVT_DIR[${#CWD_EVT_DIR[@]}]="$edir"
        ;;
      UNKNOWN)
        if [ -z "$CWD_UNKNOWN_SEG" ] || [ "$eseg" -lt "$CWD_UNKNOWN_SEG" ]; then CWD_UNKNOWN_SEG="$eseg"; fi
        ;;
    esac
  done <<< "$table"
  return 0
}

# cwd_candidates_for(seg) — print, one per line, every directory a relative operand in
#   segment seg can land under: changes from earlier segments, nearest first (all of them
#   when the line is re-entrant), then the payload cwd. An empty seg means "after every
#   segment". Returns 3, printing nothing, when an earlier change cannot be followed.
cwd_candidates_for() {
  local seg="$1" i
  if [ -n "$CWD_UNKNOWN_SEG" ]; then
    if [ "$CWD_REENTRANT" = 1 ] || [ -z "$seg" ] || [ "$CWD_UNKNOWN_SEG" -lt "$seg" ]; then
      return 3
    fi
  fi
  i=$(( ${#CWD_EVT_SEG[@]} - 1 ))
  while [ "$i" -ge 0 ]; do
    if [ "$CWD_REENTRANT" = 1 ] || [ -z "$seg" ] || [ "${CWD_EVT_SEG[$i]}" -lt "$seg" ]; then
      "$PRINTF" '%s\n' "${CWD_EVT_DIR[$i]}"
    fi
    i=$((i - 1))
  done
  "$PRINTF" '%s\n' "$CWD"
}

# split_verdict(out) — resolve_and_classify prints the judged path, then, for a relative
#   operand, a newline and the directory it was judged from. Sets RESOLVED and BASIS.
split_verdict() {
  RESOLVED="${1%%"$NL"*}"
  BASIS=""
  case "$1" in *"$NL"*) BASIS="${1#*"$NL"}" ;; esac
}

# basis_note — the clause a refusal appends when its relative operand was judged from a
#   directory a change in the command leads to, so the message names its own basis.
basis_note() {
  if [ -n "$BASIS" ] && [ "$BASIS" != "$CWD" ]; then
    "$PRINTF" ' (relative operand judged from %s, which a directory change earlier in this command leads to)' "$BASIS"
  fi
}

# ==========================================================================
# RULE EVALUATION
# ==========================================================================

# Trash-verb operands the MEMORY-STORE ARM admitted; each leaves one row before the allow.
MEMORY_ADMISSIONS=0

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
    ensure_cwd_table
    # Iterate target tokens
    found_target=0
    while IFS="$TAB" read -r tseg token; do
      [ -z "$token" ] && continue
      found_target=1
      classification=0
      verdict="$(resolve_and_classify "$token" "$tseg")" || classification="$?"
      split_verdict "$verdict"; resolved="$RESOLVED"
      case "$classification" in
        0)
          # Inside workspace — block with Trash suggestion
          suggestion="$(suggest_trash_command "$resolved")"
          block "BLOCK-TRASH-002" \
            "permanent deletion inside workspace blocked: $resolved$(basis_note)" \
            "use Trash instead: $suggestion (or set CLAUDE_HOOK_BYPASS=1 only if intentional)"
          ;;
        1)
          # Outside workspace — blocked. An auto-memory entry (MEMORY-STORE ARM) is still
          # refused for a permanent-deletion verb, but the refusal names the Trash move.
          if [ "$(memory_arm_verdict "$token")" = "ELIGIBLE" ]; then
            case "$token" in \"*\"|\'*\') suggestion="trash '${token:1:${#token}-2}'" ;; *) suggestion="trash '$token'" ;; esac
            block "BLOCK-TRASH-001" \
              "permanent deletion of an auto-memory entry is refused — evict it with a Trash move instead: $suggestion" \
              "eviction is a Trash move (core/disciplines/knowledge-architecture.md § Memory↔corpus boundary, EVICT); no bypass is needed"
          fi
          block "BLOCK-TRASH-001" \
            "deletion outside Claude/ is forbidden — cancel operation. Path: $resolved$(basis_note)" \
            "all deletions outside ${WORKSPACE_ROOT}/ are blocked; cancel the operation, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
          ;;
        2)
          # Unresolvable under strict policy
          block "BLOCK-TRASH-001" \
            "path is unresolvable under strict policy (variable/subshell/backtick token): $token" \
            "use explicit absolute paths instead of variables/subshells, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
          ;;
        3)
          # Relative operand after a directory change the hook cannot follow
          block_cwd_unknown "BLOCK-TRASH-001" "$token"
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
  ensure_cwd_table
  found_target=0
  while IFS="$TAB" read -r tseg token; do
    [ -z "$token" ] && continue
    found_target=1
    classification=0
    verdict="$(resolve_and_classify "$token" "$tseg")" || classification="$?"
    split_verdict "$verdict"; resolved="$RESOLVED"
    case "$classification" in
      0)
        # Inside workspace — approved deletion mechanism, allow
        :
        ;;
      1)
        memory_verdict="$(memory_arm_verdict "$token")"
        if [ "$memory_verdict" = "ELIGIBLE" ]; then
          # auto-memory entry — the EVICT Trash move (MEMORY-STORE ARM); its admission row
          # is written below, once every operand has been judged
          MEMORY_ADMISSIONS=$((MEMORY_ADMISSIONS + 1))
        elif [ "$memory_verdict" = "OUTSIDE-USER-SCOPE" ]; then
          block "BLOCK-TRASH-003" \
            "auto-memory entry in a store declared outside user scope is not admitted — the memory-store arm reads autoMemoryDirectory from the operator's user-scope settings only. Path: $resolved" \
            "evict it through the Hook-Blocked → User-Side Handoff (the operator runs the same command), or the operator declares the store in user-scope settings"
        else
          block "BLOCK-TRASH-003" \
            "deletion outside Claude/ is forbidden — cancel operation. Path: $resolved$(basis_note)" \
            "all deletions outside ${WORKSPACE_ROOT}/ are blocked; cancel the operation, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
        fi
        ;;
      2)
        block "BLOCK-TRASH-003" \
          "path is unresolvable under strict policy (variable/subshell/backtick token): $token" \
          "use explicit absolute paths instead of variables/subshells, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
        ;;
      3)
        block_cwd_unknown "BLOCK-TRASH-003" "$token"
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
    # The extractor reads the raw command and carries no segment number, so a relative path
    # is judged from every directory any change on the line can lead to.
    ensure_cwd_table
    while IFS= read -r osa_path; do
      [ -z "$osa_path" ] && continue
      classification=0
      verdict="$(resolve_and_classify "$osa_path")" || classification="$?"
      split_verdict "$verdict"; resolved="$RESOLVED"
      case "$classification" in
        0)
          # Inside workspace — approved deletion, allow
          :
          ;;
        1)
          memory_verdict="$(memory_arm_verdict "$osa_path")"
          if [ "$memory_verdict" = "ELIGIBLE" ]; then
            # auto-memory entry — the EVICT Trash move (MEMORY-STORE ARM); its admission
            # row is written below, once every operand has been judged
            MEMORY_ADMISSIONS=$((MEMORY_ADMISSIONS + 1))
          elif [ "$memory_verdict" = "OUTSIDE-USER-SCOPE" ]; then
            block "BLOCK-TRASH-003" \
              "auto-memory entry in a store declared outside user scope is not admitted — the memory-store arm reads autoMemoryDirectory from the operator's user-scope settings only. Path: $resolved" \
              "evict it through the Hook-Blocked → User-Side Handoff (the operator runs the same command), or the operator declares the store in user-scope settings"
          else
            block "BLOCK-TRASH-003" \
              "deletion outside Claude/ is forbidden — cancel operation. Path: $resolved$(basis_note)" \
              "all deletions outside ${WORKSPACE_ROOT}/ are blocked; cancel the operation, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
          fi
          ;;
        2)
          block "BLOCK-TRASH-003" \
            "path is unresolvable under strict policy (variable/subshell/backtick token): $osa_path" \
            "use explicit absolute paths instead of variables/subshells, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
          ;;
        3)
          block_cwd_unknown "BLOCK-TRASH-003" "$osa_path"
          ;;
      esac
    done < <("$PRINTF" '%s' "$COMMAND" | "$GREP" -oE 'POSIX[[:space:]]+file[[:space:]]+"[^"]*"' | "$GREP" -oE '"[^"]*"' | /usr/bin/sed 's/^"//; s/"$//')
  fi
fi

# --- MEMORY-STORE ARM: every admission leaves one row, before the call is allowed ---
# Written here, after every operand has been judged, so a command refused as a whole leaves
# no row. A row that cannot be written refuses the admission: the arm never admits silently.
if [ "$MEMORY_ADMISSIONS" -gt 0 ] && ! record_memory_admissions; then
  block "BLOCK-TRASH-003" \
    "the Trash move of an auto-memory entry could not be recorded in the hook's admission log, so it is not admitted — every admission leaves one row" \
    "restore write access to ${BLOCK_LOG}, or hand the command to the operator (the Hook-Blocked → User-Side Handoff)"
fi

# No matcher-verb detected — allow
exit 0
