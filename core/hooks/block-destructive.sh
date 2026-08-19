#!/bin/bash
# block-destructive.sh — PreToolUse hook blocking destructive operations
# hook-owner: core/rules/bypass-mode-readiness/block-destructive.md
#
# - correct shell semantics (printf, BSD-grep regex, payload cwd, fail-closed on missing jq)
# - git plumbing coverage, primary-write guard, tamper resistance, subprocess script ban
#
# Matcher scope: Bash, Write, Edit (the single hook branches by tool_name)
#
# Rule ID range: BLOCK-DESTRUCTIVE-001..099
#
# Part of: the bypass-permissions-readiness release

set -euo pipefail

# --- PATH PINNING (tamper resistance; blocks PATH-stub attacks per Red Team H2) ---
export PATH="/usr/bin:/bin"

# Absolute tool paths (all in /usr/bin, root-owned on macOS — not user-writable)
readonly GREP="/usr/bin/grep"
readonly PRINTF="/usr/bin/printf"
readonly PYTHON3="/usr/bin/python3"
# jq is resolved below via lib/dep-resolve.sh (once HOOK_DIR is known), from a fixed
# absolute-path allowlist — never $PATH — so the anti-hijack PATH pin still holds
# (GHSA-9cjm-v22x-4x33).

# --- METADATA ---
readonly HOOK_NAME="block-destructive"
readonly HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"
readonly ERROR_LOG="${HOOK_DIR}/hook-errors.log"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"
readonly PRIMARY_ROOT="${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}"
readonly SCRIPT_ALLOWLIST="${HOOK_DIR}/../script-execution-allowlist.txt"

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

# --- ABSOLUTE-PATH-AWARE ANCHORS ---
# Two anchor variants capture the 5 canonical macOS/Linux absolute-path
# prefixes (/bin/, /usr/bin/, /usr/local/bin/, /opt/homebrew/bin/,
# /opt/local/bin/) in a single optional capture group. Backward-
# compatible: when the prefix group is absent, the regex degenerates
# to the original anchor pattern, so every existing fixture continues
# to pass unchanged.
#
# POSIX-ERE compliant (no Perl extensions). Tested against BSD grep.
# Pattern is duplicated across the 3 regex-based PreToolUse hooks
# (block-destructive.sh, block-egress.sh, block-rm-prefer-trash.sh) —
# extracted as a per-hook constant to surface the convention and keep
# each hook file-local-self-contained per the existing posture.
#
# - ANCHOR_PREFIX_BASH: line-start OR command-separator anchor; used
#   for verbs invoked at command position (rm, curl, ssh, alias,
#   PATH=, CLAUDE_HOOK_BYPASS=, etc.).
# - ANCHOR_PREFIX_GIT: non-alphanumeric-boundary anchor; used for the
#   `git` token specifically. Pre-existing pattern recognizes that git
#   subcommand detection must NOT match inside identifiers (e.g.,
#   `mygit_subcommand`). The optional path-prefix group composes here
#   to also detect `/usr/bin/git push --force`, which the prior
#   bare-token anchor evaded under BLOCK-DESTRUCTIVE-001.
readonly ANCHOR_PREFIX_BASH='(^|[;&|])[[:space:]]*(/(usr/(local/)?|opt/(homebrew|local)/)?bin/)?'
readonly ANCHOR_PREFIX_GIT='(^|[^[:alnum:]_-])(/(usr/(local/)?|opt/(homebrew|local)/)?bin/)?'

# --- COMMAND-POSITION CANONICALIZER (shared primitive, #5644) ---
# ANCHOR_PREFIX_BASH recognises a command start ONLY at start-of-line or after `;`, `&`,
# `|`, so a verb inside `{ … }`, `( … )`, after `then`/`do`, behind `sudo`/`env`/`xargs`/
# `VAR=…`, or written `\rm` was invisible to it — the verdict tracked lexical POSITION
# rather than the action. `sudo rm -rf /` did not reach BLOCK-DESTRUCTIVE-004 for that
# reason alone. The command is canonicalized before matching so genuine command starts
# become positions the anchor already recognises; the anchors, rule IDs and messages are
# unchanged. ONE implementation shared by all four anchor-carrying hooks (see
# core/hooks/lib/command-position.awk).
#
# ANCHOR_PREFIX_GIT is a word-boundary anchor, not a command-position one, so it was never
# blind in this way. Canonicalization only ever INSERTS `;` and replaces in-quote structure
# with a non-alphanumeric sentinel — both of which are already `[^[:alnum:]_-]` — so it can
# add boundaries for the git rules but never remove one.
#
# BLOCK-DESTRUCTIVE-022 is deliberately NOT routed through this: its segment loop and
# cumulative quote-parity tracking read "$COMMAND" directly and own their own lexical
# model. Canonicalizing its input would pre-empt the parity machinery that catches a
# script path carried inside a quoted program string.
readonly CMDPOS_AWK="${HOOK_DIR}/lib/command-position.awk"

# --- ERROR HANDLERS ---
log_error() {
  local ts
  ts="$(/bin/date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo 'unknown')"
  "$PRINTF" '%s [%s] %s\n' "$ts" "$HOOK_NAME" "$1" >> "$ERROR_LOG" 2>/dev/null || true
}

# Fail-CLOSED on rule-evaluation error (exit 2 blocks the tool call)
trap 'rc=$?; log_error "RULE-EVAL-ERROR at line $LINENO (exit $rc)"; "$PRINTF" "[CLAUDE-HOOK:%s:HOOK-ERROR] BLOCKED: rule-evaluation error at line %s (exit %s). See %s.\n" "$HOOK_NAME" "$LINENO" "$rc" "$ERROR_LOG" >&2; exit 2' ERR

# --- READ INPUT (jq-free; stdin is consumed exactly once) ---
INPUT="$(cat)"

# --- CLAUDE_HOOK_BYPASS escape hatch (NEW-E D8) — evaluated BEFORE the jq gate so it
# works even when jq is unresolvable (GHSA-9cjm-v22x-4x33). Operator-only override: set
# the env var BEFORE launching claude (e.g., CLAUDE_HOOK_BYPASS=1 claude). Mid-session
# Bash attempts to set this var are denied by BLOCK-DESTRUCTIVE-023 below (anti-injection). ---
if [ "${CLAUDE_HOOK_BYPASS:-}" = "1" ]; then
  ts="$(/bin/date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
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
# SCOPE gate. (There is no `.mode` read in this hook; see the scope-gate comment
# below.) CLASS=security (D-R9): master-OFF NEVER makes this hook inert — the
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
# Validate JSON structure (fail-CLOSED if malformed — indicates hook/harness issue)
if ! "$PRINTF" '%s' "$INPUT" | "$JQ" -e . >/dev/null 2>&1; then
  log_error "INVALID-INPUT: malformed JSON on stdin"
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
# degrade (ADR-130 D4). The chain above previously read `... SCOPE -> .mode -> rule`,
# which advertised a warn dial this hook has never had — on precisely the hooks whose
# tightenings land hardest at deploy. A reader planning a rollback for a change to this
# file could reasonably have concluded a mode flip was available; it is not. The coverage
# boundary is stated at core/rules/bypass-mode-readiness/block-destructive.md, condition
# (4), and canonically at core/standards/subagent-security-posture.md section 3.1.
# The PreToolUse wiring is re-homed out of workspace-project scope so repo- and
# worktree-rooted sessions resolve it at all; this bounds that reach to the governed
# workspace root, so hooks do not begin firing in unrelated repositories. The fail
# direction is INVERTED on the cwd axis (an undeterminable cwd does NOT enforce) and
# NOT inverted on the lib axis (a missing lib does NOT gate, so the hook keeps
# enforcing — a deleted file must never be a silent kill switch). See lib/scope-guard.sh. ---
readonly SCOPE_GUARD_LIB="${HOOK_DIR}/lib/scope-guard.sh"
if [ -r "$SCOPE_GUARD_LIB" ]; then . "$SCOPE_GUARD_LIB" 2>/dev/null || true; fi
if command -v scope_guard_gate >/dev/null 2>&1; then scope_guard_gate "$CWD"; fi

# --- HELPERS ---

# sha256 digest helper (16 chars) for block-log evidence — avoids logging raw tool_input
digest() {
  "$PRINTF" '%s' "$1" | /usr/bin/shasum -a 256 | "$GREP" -oE '^[a-f0-9]+' | /usr/bin/head -c 16
}

# Log a block event to block-log.jsonl (append-only, JSON per line)
log_block() {
  local rule_id="$1"
  local ts; ts="$(/bin/date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  local tool_input; tool_input="$("$PRINTF" '%s' "$INPUT" | "$JQ" -c '.tool_input // {}')"
  local input_digest; input_digest="$(digest "$tool_input")"
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg digest "$input_digest" --arg cwd "$CWD" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, input_digest:$digest, cwd:$cwd}' \
    >> "$BLOCK_LOG" 2>/dev/null || true
}

# Emit structured block message + log + exit 2
block() {
  local rule_id="$1"
  local reason="$2"
  local override="$3"
  log_block "$rule_id"
  "$PRINTF" '[CLAUDE-HOOK:%s:%s] BLOCKED: %s\nOverride: %s\n' "$HOOK_NAME" "$rule_id" "$reason" "$override" >&2
  exit 2
}

# Pattern match against the canonicalized command (single-string scan via printf —
# preserves newlines, avoids IFS splitting). Rule patterns are unchanged; only the text
# they read is, so a verb at any genuine command start is now anchored. Direct "$COMMAND"
# readers below — the BLOCK-DESTRUCTIVE-022 segment loop and its quote-parity tracking —
# deliberately keep the RAW command and are unaffected.
matches() {
  local pattern="$1"
  "$PRINTF" '%s' "$COMMAND_CMDPOS" | "$GREP" -qE "$pattern"
}

# Check if a path matches any glob pattern in the script-execution allowlist
# Uses shell case globbing (bash glob), NOT regex — allowlist entries are bash glob patterns
is_script_allowlisted() {
  local path="$1"
  [ -f "$SCRIPT_ALLOWLIST" ] || return 1
  local pattern
  while IFS= read -r pattern || [ -n "$pattern" ]; do
    # Skip comments and blank lines
    case "$pattern" in
      ''|'#'*) continue;;
    esac
    # shellcheck disable=SC2254
    case "$path" in
      $pattern) return 0;;
    esac
  done < "$SCRIPT_ALLOWLIST"
  return 1
}

# Strip one leading and one trailing quote from a token, independently.
# Quoting a path is ordinary usage, and an unstripped quote leaves the token not
# ending in `.sh` — which silently disabled BLOCK-DESTRUCTIVE-022 altogether
# (`bash "/tmp/evil.sh"` matched nothing and fell through to allow). The two ends
# are stripped independently so a half-quoted token left by segment splitting
# (`/tmp/evil.sh"`) normalizes too. A path legitimately containing a quote
# normalizes to a string that will not be in the allowlist — i.e. it fails toward
# blocking, never toward allowing.
normalize_script_token() {
  local t="$1"
  t="${t#[\"\']}"
  t="${t%[\"\']}"
  "$PRINTF" '%s' "$t"
}

# Adjudicate one candidate script path against the allowlist. Blocks (exit 2) on
# a non-allowlisted target, and blocks on an UNRESOLVABLE one: this hook sees
# unexpanded argv, so a variable-bearing path cannot be resolved here. Denying is
# the same fail-closed posture as the dependency gate above — a security control
# that cannot evaluate its input must deny, never guess.
check_script_target() {
  local path="$1"
  case "$path" in
    *'$'*)
      block "BLOCK-DESTRUCTIVE-022" \
        "unresolvable script path (variable-bearing): $path — the hook sees unexpanded argv and cannot resolve it to an allowlist entry." \
        "invoke with a literal path, or add the resolved path to .claude/script-execution-allowlist.txt, or set CLAUDE_HOOK_BYPASS=1"
      ;;
  esac
  if ! is_script_allowlisted "$path"; then
    block "BLOCK-DESTRUCTIVE-022" \
      "subprocess script execution not in allowlist: $path (Red Team C1 — script-laundering mitigation)." \
      "add to .claude/script-execution-allowlist.txt (glob patterns supported), or set CLAUDE_HOOK_BYPASS=1"
  fi
}

# --------------------------------------------------------------------------
# Cumulative quote tracking for the BLOCK-DESTRUCTIVE-022 segment loop.
#
# The -022 matcher is LEXICAL: it splits raw argv on `;`, `&`, `|` and newline.
# A separator inside a QUOTED ARGUMENT is therefore a spurious split, and the
# fragments either side of it look exactly like commands. Deciding which
# fragments are real requires knowing, for each segment, whether it BEGINS
# inside a quote that opened earlier — which is a property of the whole command,
# not of the segment. Per-segment quote PARITY cannot answer it: `--msg "it's"`
# is ordinary well-formed shell whose segment carries one `'`, and a program
# string like `bash -c 'a; bash x.sh'` puts a REAL command in an odd-parity
# fragment. Parity conflates "inside a quoted argument" with "contains an odd
# number of quote characters"; only a carried state distinguishes them.
#
# script_qstate is that state: 0 outside any quote, 1 inside '...', 2 inside
# "...", 3 inside $'...'. Shell quoting rules are honoured rather than
# approximated, because each approximation fails toward OVER-reporting "inside a
# quote", which is the fail-OPEN direction for the caller:
#   - inside '...' nothing is special but the closing `'` (no escapes at all);
#   - inside "..." a backslash escapes the next character, so `\"` does not close;
#   - inside $'...' a backslash escapes the next character too, so `\'` does NOT
#     close. This is a DIFFERENT construct from '...' and needs its own state:
#     reading `$'it\'s'` under the '...' rule ends one quote out of phase and
#     reports *inside* where bash is *outside*, which is exactly the fail-open
#     direction this block exists to avoid;
#   - outside quotes a backslash escapes the next character, so `\'` does not OPEN
#     one. Without that rule `echo \'; bash <evil>.sh` would read as "inside a
#     quote" and suppress a real execution.
#
# script_qtaint is a second, independent fact about the CURRENT double-quoted
# run: whether the SHELL will evaluate something inside it. Quote state alone
# cannot answer that. Inside "..." the shell performs parameter expansion,
# command substitution and arithmetic expansion, so text there can be at command
# position no matter which verb opened the quote — `echo "$(cd /x; bash <evil>.sh
# --f)"` runs, and `echo` never gets a say. Every one of those expansions is
# introduced by `$` or by a backtick and by nothing else, so seeing either one
# inside an open double-quoted run marks the run EVALUATING for the rest of its
# life. `\$` and `\`` do not count, and that falls out for free: the backslash is
# searched in the same pass and wins by position, so it consumes the character
# after it before the taint test is ever reached. '...' and $'...' perform no
# expansion at all, so neither can be tainted.
# --------------------------------------------------------------------------

# Index of the earliest occurrence in $script_qt of any character in "$@".
# Sets script_qi (-1 when none are present), script_qc (the character found) and
# script_qpre (the text before it, which the caller needs to tell `'` from `$'`).
# Searching for one literal character at a time keeps every pattern a quoted
# expansion, so no bracket expression and no backslash escaping is involved.
script_qnext() {
  script_qi=-1
  script_qc=""
  script_qpre=""
  local _ch _pre
  for _ch in "$@"; do
    _pre="${script_qt%%"$_ch"*}"
    if [ "${#_pre}" -ne "${#script_qt}" ]; then
      if [ "$script_qi" -lt 0 ] || [ "${#_pre}" -lt "$script_qi" ]; then
        script_qi="${#_pre}"
        script_qpre="$_pre"
        script_qc="$_ch"
      fi
    fi
  done
}

# Advance script_qstate across one segment. Separator characters were replaced by
# newlines before splitting and neither they nor newlines are quote-significant,
# so advancing segment by segment is equivalent to scanning the whole command.
#
# script_qwork bounds total work across the command. A pathological input (very
# long, very many quote characters) would otherwise make this quadratic on a hook
# that runs before every Bash call. On exceeding the cap the scan STOPS and
# script_qbail latches, which forces the caller to suppress nothing at all for
# the rest of the command — degradation lands on "adjudicate everything".
script_qadvance() {
  script_qt="$1"
  local _pre
  while [ -n "$script_qt" ]; do
    if [ "$script_qwork" -ge 1000 ]; then
      script_qbail=1
      script_qstate=0
      script_qtaint=0
      return 0
    fi
    script_qwork=$(( script_qwork + 1 ))
    if [ "$script_qstate" -eq 1 ]; then
      script_qnext "$script_q1"
      if [ "$script_qi" -lt 0 ]; then break; fi
      script_qt="${script_qt:$(( script_qi + 1 ))}"
      script_qstate=0
    elif [ "$script_qstate" -eq 3 ]; then
      # $'...': a backslash escapes the next character, `'` closes. Same shape as
      # the double-quote scan with `'` as the terminator.
      script_qnext "$script_bs" "$script_q1"
      if [ "$script_qi" -lt 0 ]; then break; fi
      script_qt="${script_qt:$(( script_qi + 1 ))}"
      if [ "$script_qc" = "$script_bs" ]; then
        script_qt="${script_qt:1}"
      else
        script_qstate=0
      fi
    elif [ "$script_qstate" -eq 2 ]; then
      # `$` and the backtick are searched alongside the escape and the closing
      # quote, in ONE pass, so an escaped `\$` or ``\` `` is consumed by the
      # backslash branch and never taints.
      script_qnext "$script_bs" "$script_q2" "$script_qd" "$script_qbt"
      if [ "$script_qi" -lt 0 ]; then break; fi
      script_qt="${script_qt:$(( script_qi + 1 ))}"
      if [ "$script_qc" = "$script_bs" ]; then
        script_qt="${script_qt:1}"
      elif [ "$script_qc" = "$script_q2" ]; then
        script_qstate=0
        script_qtaint=0
      else
        script_qtaint=1
      fi
    else
      script_qnext "$script_bs" "$script_q1" "$script_q2"
      if [ "$script_qi" -lt 0 ]; then break; fi
      _pre="$script_qpre"
      script_qt="${script_qt:$(( script_qi + 1 ))}"
      if [ "$script_qc" = "$script_bs" ]; then
        script_qt="${script_qt:1}"
      elif [ "$script_qc" = "$script_q1" ]; then
        # A `'` directly preceded by `$` opens ANSI-C quoting, not a plain single
        # quote. `\$'` cannot reach here: the backslash is earlier in the same
        # search and consumes the `$` first.
        script_qstate=1
        case "$_pre" in
          *"$script_qd") script_qstate=3 ;;
        esac
      else
        script_qstate=2
        script_qtaint=0
      fi
    fi
  done
  return 0
}

# Resolve the command word of a segment into script_head (empty when the segment
# has none), using the POSIX 2.9.1 prefix walk the main loop uses: a simple
# command is `prefix* word suffix*`, and a prefix is a variable assignment.
# Shared so the carrier test and the verb test resolve command position the same
# way — an assignment prefix must not change either answer.
script_resolve_head() {
  script_head=""
  local _i
  local -a _tok
  set -f
  # shellcheck disable=SC2206
  _tok=( $1 )
  set +f
  _i=0
  while [ "$_i" -lt "${#_tok[@]}" ]; do
    case "${_tok[$_i]}" in
      [A-Za-z_]*=*)
        case "${_tok[$_i]%%=*}" in
          *[!A-Za-z0-9_]*) break ;;
        esac
        _i=$(( _i + 1 ))
        ;;
      *) break ;;
    esac
  done
  if [ "$_i" -lt "${#_tok[@]}" ]; then
    script_head="${_tok[$_i]}"
  fi
  return 0
}

# ==========================================================================
# BRANCH BY TOOL NAME
# ==========================================================================

case "$TOOL_NAME" in
  Bash)
    # ---- Bash branch — destructive command patterns ----
    COMMAND="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.command // empty')"
    [ -z "$COMMAND" ] && exit 0

    # --- CANONICALIZE COMMAND POSITIONS (see CMDPOS_AWK above) ---
    # Verify the primitive WORKS before trusting its output. A present-but-empty,
    # truncated or corrupt awk emits an empty string, and every matcher below would then
    # find nothing — this hook would fail OPEN, strictly worse than the gap it closes.
    # Canary: a one-line function body whose canonical form MUST expose the inner command
    # at an anchor position. Same posture as block-fragile-refs.sh's classifier canary
    # (GHSA-g9g6-28c9-vrx5) and the same fail-closed direction as the dependency guard.
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

    # ----- NEW-A: destructive rule set (shell-semantics rewrite + catastrophic paths) -----

    # BLOCK-DESTRUCTIVE-001 — git push --force / -f (explicit allow: --force-with-lease, --force-if-includes)
    # Absolute-path-aware: also detects /usr/bin/git push --force, etc.
    if matches "${ANCHOR_PREFIX_GIT}"'git[[:space:]]+push[[:space:]]+[^;&|]*(-f|--force)([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-001" \
        "git push --force is denied (rewrites remote history, coordinates poorly with teammates)." \
        "use 'git push --force-with-lease' (safer variant), or set CLAUDE_HOOK_BYPASS=1 before launching claude"
    fi

    # BLOCK-DESTRUCTIVE-002 — git reset --hard
    if matches "${ANCHOR_PREFIX_GIT}"'git[[:space:]]+reset[[:space:]]+[^;&|]*--hard([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-002" \
        "git reset --hard is denied (discards uncommitted work irreversibly)." \
        "use 'git reset' (soft/mixed) or 'git stash' first, or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-003 — git clean -f / -fd / --force
    if matches "${ANCHOR_PREFIX_GIT}"'git[[:space:]]+clean[[:space:]]+[^;&|]*(-[a-zA-Z]*f[a-zA-Z]*|--force)([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-003" \
        "git clean -f is denied (irreversible deletion of untracked files)." \
        "use 'git clean -n' (dry run) to inspect first, or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-004 — rm on catastrophic system paths
    # Absolute-path-aware: also detects /bin/rm -rf /, /usr/bin/rm -rf /, etc.
    if matches "${ANCHOR_PREFIX_BASH}"'rm[[:space:]]+([^[:space:]]+[[:space:]]+)*(--[[:space:]]+)?(/|/Users|/Applications|/Library|/System|/bin|/sbin|/usr|/etc|/var)([[:space:]]|$|/\*)'; then
      block "BLOCK-DESTRUCTIVE-004" \
        "rm on catastrophic system path denied (/, /Users, /Applications, /Library, /System, /bin, /sbin, /usr, /etc, /var)." \
        "scope the rm to a specific subdirectory, or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-005 — rm -rf $HOME bare
    if matches "${ANCHOR_PREFIX_BASH}"'rm[[:space:]]+([^[:space:]]+[[:space:]]+)*(--[[:space:]]+)?\$HOME/?([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-005" \
        "rm -rf \$HOME (bare) denied (would wipe user home directory on shell expansion)." \
        "scope the rm to a specific subdirectory under \$HOME (e.g., \$HOME/Downloads/temp), or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-006 — rm -rf .git
    if matches "${ANCHOR_PREFIX_BASH}"'rm[[:space:]]+([^[:space:]]+[[:space:]]+)*(--[[:space:]]+)?\.git([[:space:]]|$|/)'; then
      block "BLOCK-DESTRUCTIVE-006" \
        "rm on .git denied (destroys local git history and metadata)." \
        "back up repo first, or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-007 — rm -rf Projects/ (legacy uppercase)
    # repo-integrity: allow-projects-casing — this guard is an INTENTIONAL legacy-
    # uppercase matcher; its Projects/ literals are by-design and file-exempt from
    # the net-new Projects/ casing gate (repo-integrity.yml § projects-casing).
    if matches "${ANCHOR_PREFIX_BASH}"'rm[[:space:]]+([^[:space:]]+[[:space:]]+)*(--[[:space:]]+)?Projects/'; then
      block "BLOCK-DESTRUCTIVE-007" \
        "rm on Projects/ denied (legacy uppercase project directory; data loss risk)." \
        "rm specific files or subdirectories, or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-008 — rm -rf projects/ (Layer 2 Cowork)
    if matches "${ANCHOR_PREFIX_BASH}"'rm[[:space:]]+([^[:space:]]+[[:space:]]+)*(--[[:space:]]+)?projects/'; then
      block "BLOCK-DESTRUCTIVE-008" \
        "rm on projects/ denied (Layer 2 Cowork-owned operational data; data loss risk)." \
        "rm specific files or subdirectories, or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-009 — rm -rf pmo-platform/ (Layer 1 source tree)
    if matches "${ANCHOR_PREFIX_BASH}"'rm[[:space:]]+([^[:space:]]+[[:space:]]+)*(--[[:space:]]+)?pmo-platform/'; then
      block "BLOCK-DESTRUCTIVE-009" \
        "rm on pmo-platform/ denied (Layer 1 source tree; use git to remove tracked files instead)." \
        "rm specific files or subdirectories, or set CLAUDE_HOOK_BYPASS=1"
    fi

    # ----- NEW-B: git plumbing coverage -----

    # BLOCK-DESTRUCTIVE-010 — git update-ref on dangerous refs (main, master, HEAD)
    if matches "${ANCHOR_PREFIX_GIT}"'git[[:space:]]+update-ref[[:space:]]+(-d[[:space:]]+)?(refs/heads/(main|master)|HEAD)([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-010" \
        "git update-ref on main/master/HEAD denied (low-level ref manipulation rewrites history)." \
        "use standard git commands (commit, merge, rebase), or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-011 — git symbolic-ref HEAD to main/master
    if matches "${ANCHOR_PREFIX_GIT}"'git[[:space:]]+symbolic-ref[[:space:]]+HEAD[[:space:]]+refs/heads/(main|master)([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-011" \
        "git symbolic-ref HEAD to main/master denied (can abandon commits, corrupt branch state)." \
        "use standard git commands (checkout, switch), or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-012 — git push with plus-refspec (force push via +<refspec>)
    # Matches: git push <remote> +main, +master, +refs/heads/main:<dst>, etc.
    if matches "${ANCHOR_PREFIX_GIT}"'git[[:space:]]+push[[:space:]]+[^;&|]*\+([^[:space:];&|]*:)?(main|master|refs/heads/(main|master))([[:space:]]|:|$)'; then
      block "BLOCK-DESTRUCTIVE-012" \
        "git push with plus-refspec (+main/+master/+refs/heads/main) denied (bypasses --force detection, still rewrites history)." \
        "use 'git push --force-with-lease' or branch-specific pushes, or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-013 — git reflog expire / delete
    if matches "${ANCHOR_PREFIX_GIT}"'git[[:space:]]+reflog[[:space:]]+(expire|delete)([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-013" \
        "git reflog expire/delete denied (removes recovery safety net for recent ref changes)." \
        "only needed for disk space; set CLAUDE_HOOK_BYPASS=1 if intentional"
    fi

    # BLOCK-DESTRUCTIVE-014 — git filter-branch
    if matches "${ANCHOR_PREFIX_GIT}"'git[[:space:]]+filter-branch([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-014" \
        "git filter-branch denied (rewrites entire history; forces coordinated pushes)." \
        "use 'git filter-repo' with caution (still blocked — see BLOCK-DESTRUCTIVE-015) or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-015 — git filter-repo
    if matches "${ANCHOR_PREFIX_GIT}"'git[[:space:]]+filter-repo([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-015" \
        "git filter-repo denied (rewrites entire history; forces coordinated pushes)." \
        "coordinate with team first, or set CLAUDE_HOOK_BYPASS=1"
    fi

    # ----- NEW-B: tamper resistance (PATH / alias / function / unset) -----

    # BLOCK-DESTRUCTIVE-020 — PATH assignment (export PATH=, PATH=<value>, unset PATH)
    # Blocks both plain assignment and command-prefix assignment (PATH=/tmp:$PATH cmd)
    # Note: shell-assignment rules (PATH=, export, unset) are NOT verb-invocations and
    # the absolute-path prefix is structurally inapplicable — these forms cannot be
    # invoked via /usr/bin/PATH=... However, ANCHOR_PREFIX_BASH is applied uniformly
    # per Stage 5 Spec A4.2 (mechanical uniform anchor transformation). The
    # optional prefix group degenerates to the existing pattern for these rules.
    if matches "${ANCHOR_PREFIX_BASH}"'(export[[:space:]]+)?PATH='; then
      block "BLOCK-DESTRUCTIVE-020" \
        "PATH manipulation denied (enables hook-tool substitution attacks per Red Team H2)." \
        "if you need a modified PATH, set it in your shell before launching claude, or set CLAUDE_HOOK_BYPASS=1"
    fi
    if matches "${ANCHOR_PREFIX_BASH}"'unset[[:space:]]+([^;&|]*[[:space:]])?PATH([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-020" \
        "unset PATH denied (would defeat absolute-tool-path resolution in hooks)." \
        "PATH is required for hook integrity; set CLAUDE_HOOK_BYPASS=1 only if absolutely needed"
    fi

    # BLOCK-DESTRUCTIVE-021 — alias / function override of critical tools (grep, jq)
    if matches "${ANCHOR_PREFIX_BASH}"'alias[[:space:]]+(grep|jq|bash|sh|printf)='; then
      block "BLOCK-DESTRUCTIVE-021" \
        "alias override of critical tool (grep/jq/bash/sh/printf) denied (tamper attempt)." \
        "set CLAUDE_HOOK_BYPASS=1 if intentional"
    fi
    if matches "${ANCHOR_PREFIX_BASH}"'function[[:space:]]+(grep|jq|bash|sh|printf)[[:space:]]*(\(|\{)'; then
      block "BLOCK-DESTRUCTIVE-021" \
        "function override of critical tool (grep/jq/bash/sh/printf) denied (tamper attempt)." \
        "set CLAUDE_HOOK_BYPASS=1 if intentional"
    fi

    # BLOCK-DESTRUCTIVE-023 — anti-injection: deny mid-session setting of CLAUDE_HOOK_BYPASS
    # and of PMO_SCOPE_GUARD_ROOT (#4436), the layer-3 scope-guard root override. Both are
    # pre-launch, operator-only knobs; a mid-session assignment of either is an injection
    # vector, so they carry one posture and one rule ID rather than drifting apart.
    # The escape hatch must be operator-only (set BEFORE claude launch), not accessible to
    # Claude via prompt injection. This rule enforces the asymmetry.
    if matches "${ANCHOR_PREFIX_BASH}"'(export[[:space:]]+)?CLAUDE_HOOK_BYPASS='; then
      block "BLOCK-DESTRUCTIVE-023" \
        "CLAUDE_HOOK_BYPASS cannot be set mid-session (defeats the operator-only escape-hatch design)." \
        "to bypass hooks, exit claude and relaunch with: CLAUDE_HOOK_BYPASS=1 claude"
    fi
    if matches "${ANCHOR_PREFIX_BASH}"'CLAUDE_HOOK_BYPASS='; then
      block "BLOCK-DESTRUCTIVE-023" \
        "CLAUDE_HOOK_BYPASS command-prefix assignment denied (injection-attack vector)." \
        "to bypass hooks, exit claude and relaunch with: CLAUDE_HOOK_BYPASS=1 claude"
    fi
    if matches "${ANCHOR_PREFIX_BASH}"'(export[[:space:]]+)?PMO_SCOPE_GUARD_ROOT='; then
      block "BLOCK-DESTRUCTIVE-023" \
        "PMO_SCOPE_GUARD_ROOT cannot be set mid-session (it re-points the layer-3 workspace-scope guard)." \
        "to change the governed scope root, exit claude and relaunch with: PMO_SCOPE_GUARD_ROOT=<path> claude"
    fi

    # ----- NEW-B: subprocess script ban (closes Red Team C1 — script laundering) -----

    # BLOCK-DESTRUCTIVE-022 — bash/sh/zsh <path.sh> or source/. <path> not in allowlist
    #
    # STRATEGY: segment first, then match — for BOTH verbs, through ONE matcher.
    # A single ERE cannot model shell grammar, and the prior single-pass pattern
    # failed on five independent axes:
    #
    #   (a) the argument span `([^[:space:]]+[[:space:]]+)*` admitted `;`, `&`, and
    #       `|`, so several commands fused into ONE match. That forced a compensating
    #       `tail -1` on the target extraction, which in turn checked the wrong token
    #       whenever a script took a script as an argument — `bash tool.sh arg.sh`
    #       adjudicated `arg.sh`, never the tool actually executed.
    #   (b) the trailing boundary `([[:space:]]|$|\b)` does not honor `\b` inside an
    #       alternation under BSD grep (it does standing alone). A `.sh` immediately
    #       followed by `;` therefore satisfied no branch, the pattern failed, and the
    #       invocation fell through to ALLOW without the allowlist being consulted.
    #   (c) a quoted path does not end in `.sh`, so `bash "x.sh"` likewise matched
    #       nothing and fell through to ALLOW.
    #   (d) an assignment ahead of the verb moved the verb off index 0, so the whole
    #       invocation was skipped — in BOTH directions, so it did not fail safe.
    #       Closed by the command-position walk below.
    #   (e) `source`/`.` ran through a SECOND, older mechanism — a `grep -oE` anchored
    #       at line-start-or-separator, plus `head -1` — which carried (c) unfixed,
    #       evaluated only the FIRST invocation on the line, and was evaded entirely
    #       by (d) because its anchor could not admit a prefix at all. That mechanism
    #       is deleted, not patched: keeping two matchers is what let the arms drift
    #       apart, and patching would have required writing the fix twice.
    #
    # Splitting on separators makes each segment a single command whose command word
    # is resolvable, so the FIRST non-flag operand is the script actually executed —
    # which is what this rule always intended to adjudicate. Every segment is
    # evaluated, not just the first, so a laundered second command cannot hide behind
    # an allowlisted first one. Both verbs share the command-position walk, the quote
    # normalization and `check_script_target` as the single adjudicator; only the
    # operand FILTER differs per verb, because an interpreter takes a script and
    # `source` takes any file.
    #
    # Bash 3.2-safe throughout (macOS system bash): parameter expansion only, no
    # `tr`, no associative arrays, and the loop runs in the CURRENT shell (here-string,
    # never a pipeline) so `block`'s exit 2 propagates rather than dying in a subshell.

    script_segments="${COMMAND//;/$'\n'}"
    script_segments="${script_segments//&/$'\n'}"
    script_segments="${script_segments//|/$'\n'}"

    # ---- Quoted-fragment suppression (per-opener attribution) ----
    #
    # This matcher is LEXICAL: it splits raw argv on separators. A separator and an
    # interpreter appearing inside a QUOTED ARGUMENT are therefore shredded into
    # fragments that look exactly like commands, and the rule fires on text that
    # describes an execution rather than performing one. During this release alone
    # the class fired three times across two hooks — twice on a quoted data string
    # and once on a grep PATTERN — and the tightening above ENLARGES the surface,
    # because every invocation is now adjudicated instead of only the first.
    #
    # THE DISCRIMINATOR. The question a fragment must answer is not "do my own
    # quotes balance" but "am I interior to a quoted argument, and whose argument
    # is it". Those differ, and the difference is the whole rule:
    #
    #   - `bash <x>.sh --msg "it's here"` is a REAL execution whose segment carries
    #     ONE `'`. Odd parity, and it must block.
    #   - `bash -c 'echo hi; bash <x>.sh'` puts a real command in the SECOND
    #     fragment of a quoted program string. Odd parity there too, and it must
    #     block, because `-c` EXECUTES that string — positions inside it are
    #     command positions.
    #   - `gh issue comment 1 --body 'note; bash <x>.sh'` is the false positive.
    #     Also odd parity. Nothing runs.
    #
    # Parity cannot separate those three. Carried quote state can: a segment is
    # interior to a quoted argument exactly when the state at its START is 1 or 2,
    # and the argument belongs to the command that OPENED that quote — not to
    # whichever command happens to head the line.
    #
    # THE INVARIANT, stated so a later editor can check an edit against it:
    #
    #   A suppression may fire only when the enclosing context PROVABLY CANNOT
    #   cause the shell to evaluate the segment.
    #
    # Two independent conditions, and BOTH are necessary:
    #
    #  (1) The command that OPENED the quote cannot evaluate its argument. This is
    #      the carrier test. It is what makes the `-c` case safe: the quote in
    #      `bash -c '…'` is opened by `bash`, so no prefix in front of it —
    #      `echo x; bash -c '…'` — can reattribute the program string to `echo`.
    #  (2) The quoting construct itself performs no expansion. `'…'` and `$'…'`
    #      perform none. `"…"` performs parameter expansion, command substitution
    #      and arithmetic expansion, so a double-quoted run is suppressible only
    #      while it is UNTAINTED — no `$` and no backtick seen since it opened.
    #
    # Condition (1) alone is what the previous two attempts checked, and it is not
    # sufficient. Inside a double-quoted argument the SHELL evaluates `$( … )` and
    # `` ` … ` `` BEFORE the carrier ever runs: `echo "$(cd /x; bash <evil>.sh --f)"`
    # executes, and `echo` — which genuinely cannot evaluate its argument — is never
    # asked. `$( )` does not PREFIX the inner command, it ENCLOSES it, and enclosure
    # was not covered. Condition (2) closes that, and closes it by construct rather
    # than by enumerating shapes: any expansion inside `"…"` needs a `$` or a
    # backtick, so tainting on those two characters covers the whole class —
    # `$( )`, `` ` ` ``, `$(( ))`, `${ }` and anything later added to the language.
    #
    # A segment whose start state is 0 still begins at COMMAND POSITION and is
    # ALWAYS adjudicated. Unquoted `$( )`, backticks and `<( )` all land there, so
    # they need no separate rule.
    #
    # HEREDOCS ARE NOT MODELLED, so suppression is switched off entirely for any
    # command containing `<<`. A heredoc BODY line is not a command line, but the
    # matcher splits on newlines and cannot tell the difference: a body line that
    # opens a quote poisons the carried state, and a real execution after the
    # terminator is then read as interior to it. Declining to suppress is the
    # fail-closed answer to "this construct is outside the model"; the cost is that
    # `<<`-bearing commands keep the false positive.
    #
    # Suppression stays gated on an ALLOWLIST of command words that cannot evaluate
    # their arguments. The direction of that choice is deliberate: an entry MISSING
    # from this set means a false positive persists — it can never mean an evasion
    # is admitted. A denylist of evaluating verbs would invert the failure
    # direction, because one missed verb silently allows a real execution, and a
    # fail-open surface inside a fail-closed control is not an acceptable trade for
    # an availability fix.
    #
    # `git` is NOT in the set, though it reads like a natural member. `git -c
    # alias.x='!<cmd>' x` evaluates its own quoted argument, so it fails the set's
    # stated membership criterion; keeping it would leave exactly the fail-open this
    # block exists to avoid. Membership is the property to re-check when editing.
    script_q1="'"
    script_q2='"'
    script_bs='\'
    script_qd='$'
    script_qbt='`'
    script_qstate=0
    script_qwork=0
    script_qbail=0
    script_qtaint=0
    script_carrier=0
    script_head=""

    # Heredocs are outside the model — see THE INVARIANT above. Latch suppression
    # off for the whole command rather than reason about a body line. This reuses
    # script_qbail, whose meaning is already "stop vouching for anything".
    case "$COMMAND" in
      *'<<'*) script_qbail=1 ;;
    esac

    while IFS= read -r script_seg; do
      # Quote state at the START of this segment, carried in from everything before
      # it. Captured BEFORE the segment is scanned, because a segment that opens a
      # quote is itself still at command position. The taint is captured with it:
      # both describe the context this segment SITS IN, not the one it creates.
      script_segstart="$script_qstate"
      script_segtaint="$script_qtaint"

      # trim leading whitespace (leaves the head token at index 0)
      script_seg="${script_seg#"${script_seg%%[![:space:]]*}"}"

      # Advance the carried state over this segment BEFORE any `continue` below —
      # an empty or suppressed segment still contributes its quote characters, and
      # losing them would desynchronise every segment that follows.
      script_qadvance "$script_seg"

      if [ "$script_segstart" -eq 0 ]; then
        # Command position: this segment follows a separator that was OUTSIDE any
        # quote, so it is a real command, never a fragment. Re-resolve the carrier
        # here — this is what attributes a quote to the command that opens it. An
        # empty segment yields an empty head and therefore carrier 0, which is the
        # fail-closed answer for "no command word to vouch for what follows".
        script_resolve_head "$script_seg"
        script_carrier=0
        if [ "$script_qbail" -eq 0 ]; then
          case "${script_head##*/}" in
            gh|printf|echo|jq) script_carrier=1 ;;
          esac
        fi
      elif [ "$script_carrier" -eq 1 ]; then
        # Interior to a quoted argument of a command that cannot evaluate it —
        # condition (1). Condition (2) is the construct test: `'…'` (state 1) and
        # `$'…'` (state 3) expand nothing, so they are inert unconditionally; a
        # double-quoted run (state 2) is inert only while untainted.
        case "$script_segstart" in
          1|3) continue ;;
          2) if [ "$script_segtaint" -eq 0 ]; then continue; fi ;;
        esac
      fi

      [ -n "$script_seg" ] || continue

      # tokenize on whitespace with globbing OFF, so a literal `*` in the command
      # is not expanded against the cwd before we can adjudicate it
      set -f
      # shellcheck disable=SC2206
      script_tokens=( $script_seg )
      set +f
      [ "${#script_tokens[@]}" -ge 2 ] || continue

      # Resolve COMMAND POSITION before reading the verb. POSIX Shell Command
      # Language 2.9.1 defines a simple command as `prefix* word suffix*`, where a
      # prefix is a variable assignment (or redirection) and the command word is the
      # FIRST token that is not one. Walking the assignment run resolves command
      # position the way the shell resolves it, instead of assuming index 0.
      #
      # Without this the verdict flips on a token that does not change the operation:
      # an assignment ahead of the verb presented that assignment as the head token,
      # matched no verb, and was never adjudicated — in BOTH directions, so it did
      # not even fail safe.
      #
      # A token is a prefix assignment IFF it contains `=` AND its NAME part
      # (everything before the FIRST `=`) is a valid shell name. Anything else
      # TERMINATES the run and is the command word — so `a-b=1` and `--body=x` both
      # stop the walk, and the skip cannot degrade into a general "advance past any
      # token containing `=`". The two tests are ordered: `${tok%%=*}` returns the
      # whole token when there is no `=`, so the pattern test must gate it.
      #
      # NOT skipped, by construction: `env`, `command`, `exec`, `nohup`, `timeout`,
      # `xargs`, `eval`. Under the same grammar their head token IS a real command
      # word, not a prefix. Covering them requires a denylist of evaluating verbs,
      # and a denylist inside a fail-closed control is itself a fail-open surface
      # (miss one and the evasion is silent). Deliberate, recorded residual.
      script_hidx=0
      while [ "$script_hidx" -lt "${#script_tokens[@]}" ]; do
        case "${script_tokens[$script_hidx]}" in
          [A-Za-z_]*=*)
            case "${script_tokens[$script_hidx]%%=*}" in
              *[!A-Za-z0-9_]*) break ;;
            esac
            script_hidx=$(( script_hidx + 1 ))
            ;;
          *) break ;;
        esac
      done
      # need a verb AND at least one operand after it
      [ $(( script_hidx + 1 )) -lt "${#script_tokens[@]}" ] || continue

      # Verb at command position. Basename match subsumes every absolute form
      # (/bin/bash, /usr/local/bin/zsh, /bin/.) that ANCHOR_PREFIX_BASH enumerated
      # explicitly, and is strictly tighter: an unlisted prefix no longer evades.
      # `source`/`.` are adjudicated HERE rather than by a second mechanism —
      # sourcing executes the file's contents in the current shell, which is the
      # same execution capability the interpreter arm guards, not a lesser one.
      script_verb=""
      case "${script_tokens[$script_hidx]##*/}" in
        bash|sh|zsh) script_verb="interp" ;;
        source|.)    script_verb="source" ;;
        *) continue ;;
      esac

      # walk past flags to the first operand. `-c` takes a program STRING rather
      # than a path, so every .sh-bearing token after it is a candidate instead of
      # just one — and `-c` is meaningless for `source`, so cmode is gated on the
      # interpreter verb. Walking `-*` on the source arm is strictly TIGHTER than
      # not walking it: otherwise `. -x <path>` presents `-x` as the operand.
      script_idx=$(( script_hidx + 1 ))
      script_cmode=0
      while [ "$script_idx" -lt "${#script_tokens[@]}" ]; do
        case "${script_tokens[$script_idx]}" in
          --) script_idx=$(( script_idx + 1 )); break ;;
          -c)
            if [ "$script_verb" = "interp" ]; then script_cmode=1; fi
            script_idx=$(( script_idx + 1 )); break ;;
          -*) script_idx=$(( script_idx + 1 )) ;;
          *) break ;;
        esac
      done
      [ "$script_idx" -lt "${#script_tokens[@]}" ] || continue

      if [ "$script_cmode" -eq 1 ]; then
        while [ "$script_idx" -lt "${#script_tokens[@]}" ]; do
          script_cand="$(normalize_script_token "${script_tokens[$script_idx]}")"
          case "$script_cand" in
            *.sh) check_script_target "$script_cand" ;;
          esac
          script_idx=$(( script_idx + 1 ))
        done
      else
        # normalize BEFORE the filter on both verbs — a quoted path does not end in
        # `.sh` and does not start with `/`, so an unstripped quote matches no
        # pattern and falls through to ALLOW without the allowlist being consulted.
        script_cand="$(normalize_script_token "${script_tokens[$script_idx]}")"
        if [ "$script_verb" = "source" ]; then
          # `source`/`.` take ANY file, not only a script suffix. This filter is
          # preserved verbatim from the mechanism it replaces. Do NOT unify it with
          # the interpreter arm's `*.sh`: narrowing silently drops `/*`, `~/*` and
          # `*.bash` coverage, and widening the interpreter arm to `/*` opens a
          # false-positive surface with no defect behind it.
          case "$script_cand" in
            /*|./*|../*|~/*|*.sh|*.bash) check_script_target "$script_cand" ;;
          esac
        else
          case "$script_cand" in
            *.sh) check_script_target "$script_cand" ;;
          esac
        fi
      fi
    done <<< "$script_segments"

    # No Bash rule matched — allow
    exit 0
    ;;

  Write|Edit)
    # ---- Write/Edit branch — .git metadata + primary-write guard ----
    FILE_PATH="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.file_path // empty')"
    # CWD already extracted above

    if [ -z "$FILE_PATH" ]; then
      exit 0
    fi

    # Normalize to absolute path.
    # Note: path may not exist yet (Write creates new files); resolve parent dir symlinks.
    #
    # Path normalization uses Python os.path.realpath via /usr/bin/python3 (Python
    # 3.9+, system-default on macOS 12+). Stage 5 spec referenced GNU realpath -m,
    # but /usr/bin/realpath does not exist on macOS and /bin/realpath is BSD-only
    # without the -m flag. Python os.path.realpath is the portable equivalent:
    # collapses ../ and ./, does not require path existence, follows symlinks
    # (intentional — same semantics as block-rm-prefer-trash.sh).
    # Hook degrades gracefully if /usr/bin/python3 is somehow absent — falls
    # back to the original FILE_PATH string, which still catches absolute-path
    # cases via the existing prefix-match rules but misses the ../-escape
    # edge case.
    abs_target=""
    if [ -e "$FILE_PATH" ] && [ -x "$PYTHON3" ]; then
      abs_target="$("$PYTHON3" -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")"
    elif [ -e "$FILE_PATH" ]; then
      # Python somehow unavailable — degrade gracefully to un-normalized path
      abs_target="$FILE_PATH"
    else
      parent_dir="$(/usr/bin/dirname "$FILE_PATH")"
      if [ -d "$parent_dir" ]; then
        parent_abs="$(cd "$parent_dir" 2>/dev/null && pwd -P)"
        abs_target="${parent_abs}/$(/usr/bin/basename "$FILE_PATH")"
      else
        abs_target="$FILE_PATH"
      fi
    fi

    # BLOCK-DESTRUCTIVE-016 — .git metadata writes (config, hooks, info) — block in any cwd
    case "$abs_target" in
      */.git/config|*/.git/hooks/*|*/.git/info/*)
        block "BLOCK-DESTRUCTIVE-016" \
          "Write/Edit to .git metadata denied (config/hooks/info are security-critical — local hooks can execute arbitrary code)." \
          "use 'git config' subcommands, commit hooks via shared scripts, or set CLAUDE_HOOK_BYPASS=1"
        ;;
    esac

    # Explicit allows (deploy targets / Layer 2)
    case "$abs_target" in
      "${PRIMARY_ROOT}/.claude/skills/"*)
        exit 0  # deploy.sh target — Layer 2
        ;;
      "${PRIMARY_ROOT}/.claude/settings.local.json")
        exit 0  # Layer 2 Cowork-owned local overrides
        ;;
    esac

    # BLOCK-DESTRUCTIVE-019 — Layer 1 primary writes when cwd is NOT under a worktree
    is_layer1=""
    case "$abs_target" in
      "${PRIMARY_ROOT}/CLAUDE.md")
        is_layer1="CLAUDE.md (root governance)"
        ;;
      "${PRIMARY_ROOT}/pmo-platform/"*)
        is_layer1="pmo-platform/** (Layer 1 source)"
        ;;
      "${PRIMARY_ROOT}/.claude/settings.json")
        is_layer1=".claude/settings.json (security settings)"
        ;;
      "${PRIMARY_ROOT}/.claude/hooks/"*)
        is_layer1=".claude/hooks/* (security hooks)"
        ;;
      "${PRIMARY_ROOT}/.claude/rules/"*)
        is_layer1=".claude/rules/* (governance rules)"
        ;;
    esac

    if [ -n "$is_layer1" ]; then
      # Cwd under a worktree allows the write (per AC — worktree context permits Layer 1 edits).
      # Worktrees live under the REPO root (${PRIMARY_ROOT}/pmo-platform/.claude/worktrees/),
      # NOT directly under the workspace root — this exemption base mirrors the :425 Layer-1
      # detection base so the hook has exactly one repo-rooted worktree base (#1639,
      # checkout-independent per ADR-017; PRIMARY_ROOT derives from CLAUDE_WORKSPACE_ROOT).
      case "$CWD" in
        "${PRIMARY_ROOT}/pmo-platform/.claude/worktrees/"*)
          exit 0
          ;;
      esac
      block "BLOCK-DESTRUCTIVE-019" \
        "Write/Edit to Layer 1 primary path denied: ${is_layer1}. cwd=${CWD} is not under pmo-platform/.claude/worktrees/" \
        "work from a git worktree (git worktree add), or set CLAUDE_HOOK_BYPASS=1"
    fi

    # No Write/Edit rule matched — allow
    exit 0
    ;;

  *)
    # Other tools (Read, MCP, WebFetch, etc.) — not handled by this hook; allow
    exit 0
    ;;
esac
