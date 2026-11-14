#!/usr/bin/env bash
# block-rm-prefer-trash.sh — PreToolUse hook enforcing workspace deletion containment
# and Trash-redirect convention.
# hook-owner: core/rules/bypass-mode-readiness/block-rm-prefer-trash.md
#
# Outside ${WORKSPACE_ROOT}/, file deletion via rm/rmdir/unlink/trash/osascript
# Trash-verb is BLOCKED, with ONE admitted class: a Trash move of a single
# auto-memory entry (see MEMORY-STORE ARM). Inside the workspace, rm/rmdir/unlink is
# BLOCKED with a runtime-auto-detected Trash-equivalent suggestion (3-tier: trash in
# PATH → /opt/homebrew/opt/trash/bin/trash → osascript Finder fallback). A git
# command exempts its own segment only (git history provides recoverability); every
# other segment of the line is judged, and a deletion or Trash verb that does not name
# all its targets on its line, or that sits on a command carrying a line continuation, is
# refused under the strict policy.
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

# --- TRASH-LOCAL: the keg-only location suggest_trash_command recommends (tier 2) ---
# One constant, read by the suggestion, the Step-3 Trash-verb test and the segment walk (through
# its one call site, walk_segments), so the hook never recommends a spelling it does not judge.
# Trash-local by design: it is not a member of the shared prefix set above, which stays
# byte-identical across the four anchor hooks. The path carries no ERE metacharacter, so it is
# interpolated into the regex as written.
readonly TRASH_KEG_DIR="/opt/homebrew/opt/trash/bin"
readonly TRASH_VERB_RE="${ANCHOR_PREFIX_BASH}"'trash([[:space:]]+|$)|(^|[;&|])[[:space:]]*'"${TRASH_KEG_DIR}"'/trash([[:space:]]+|$)'

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

# --- QUOTED HERE-DOCUMENT DATA (#7644) ---
# A here-document whose delimiter is quoted ('D', "D", \D) has a body the shell never expands
# or runs: it is data for the command that receives it. HEREDOC_DATA_AWK removes such a body,
# and its delimiter line, from the text every rule below reads — only when the operator sits at
# the top level of the command, the receiver is on the data-receiver list, and nothing on the
# command can route the body to a program that runs it. It runs before the canonicalizer and
# before every other reader; only the two digests read COMMAND_RAW, because they identify the
# call as submitted.
#   Receivers (the first word of the simple command holding the operator, bare or under the
#   canonical bin prefixes; no wrapper, no assignment, no redirection first): cat; git whose next
#   word is commit or tag, after at most one -C <dir> pair (never -c), and whose words after that
#   subcommand, the operator line read to its end, carry no edit option in any spelling git
#   accepts and no word an expansion or a substitution fills; gh whose next word is
#   issue, pr, release or api; python3 with zero or more single-letter flags from -[BEIOSbdqsuv]
#   and then the operand "-".
#   Declined (the whole command keeps its raw text): an unquoted delimiter; an operator inside a
#   command substitution, a backtick or a subshell — bash 3.2 ends a body inside an unquoted
#   substitution at an unbalanced ")" and runs the lines after it, so only a top-level body is
#   read as data; a pipe, process substitution, backtick or arithmetic (including $[ ]); a
#   function definition (blanks or not between the parentheses) or the words function, alias,
#   hash, enable, coproc, or a PATH assignment, or a subscript of or an assignment to a word
#   ending in aliases, functions or commands (zsh's tables that define an alias, a function or a
#   command path, their global, suffix and disabled siblings included) — an enumeration, not a
#   closed class; a << inside
#   a parameter expansion; an unterminated body; a continuation or open quote at a pending body;
#   more than 8 bodies or 500 lines; a scanned line over 4096 characters, or more than 20 000
#   scanned characters outside bodies.
#   Fail direction, in two halves. Every decline prints RAW, so the hook judges the command
#   byte-for-byte as before. Every admission rests on the pre-pass ending a top-level body where
#   the executing shell ends it: at the first line equal to the delimiter (after tab-stripping
#   for <<-), the rule bash, zsh and dash share for a top-level here-document.
# shellcheck disable=SC2016  # awk program — single quotes intentional
readonly HEREDOC_DATA_AWK='
  BEGIN { SQ = sprintf("%c", 39); BS = "\\" }
  function wordch(c) { return (c ~ /^[A-Za-z0-9_.-]$/) }
  function ap(s) { if (length(cur[d]) < 512) cur[d] = cur[d] s }
  function recv_ok(text,   k, w, j, cw) {
    k = split(text, w, /[ \t\n]+/)
    j = 1; while (j <= k && w[j] == "") j++
    if (j > k) return 0  # M-HD-RECV
    cw = w[j]
    if (cw ~ /^[A-Za-z_][A-Za-z0-9_]*[+]?=/) return 0
    if (cw ~ /^[0-9]*[<>&]/) return 0
    if (cw ~ /\//) {
      if (cw !~ /^\/((usr\/(local\/)?|opt\/(homebrew|local)\/)?)bin\/[^\/]+$/) return 0
      sub(/^.*\//, "", cw)
    }
    if (cw == "git") {
      j++; if (w[j] == "-C") j += 2
      return (j <= k && (w[j] == "commit" || w[j] == "tag")) ? 2 : 0
    }
    if (cw == "gh") return (w[j + 1] == "issue" || w[j + 1] == "pr" || w[j + 1] == "release" || w[j + 1] == "api")
    if (cw == "cat") return 1
    if (cw == "python3") {
      j++; while (j <= k && w[j] ~ /^-[BEIOSbdqsuv]+$/) j++
      return (j <= k && w[j] == "-")
    }
    return 0
  }
  # git_edit(text) — 1 when a word after the subcommand of a git receiver is, or can become, the
  # edit option of git: -e or a short cluster carrying it, --e or any longer prefix of --edit,
  # quoted or not; a word an expansion or a closed substitution fills ($, or the _ a substitution
  # leaves); or a text cut at the 512-character cap. With that option git opens the message, which
  # is the body, in an editor, and an editor named earlier on the line can be a program that runs it.
  function git_edit(text,   k, w, j, i, t) {
    if (length(text) >= 512) return 1
    k = split(text, w, /[ \t\n]+/)
    j = 1; while (j <= k && w[j] == "") j++
    j++; if (w[j] == "-C") j += 2
    for (i = j + 1; i <= k; i++) {
      t = w[i]; gsub(/["\\]/, "", t); gsub(SQ, "", t)
      if (t ~ /[$_]/ || t ~ /^--e/ || t ~ /^-[A-Za-z0-9]*e/) return 1
    }
    return 0
  }
  # seg_done — a simple command at the top level has ended; a git receiver admitted in it is
  # read whole, the words after its operator included, before its body can be taken as data.
  function seg_done() {
    if (gitrx && git_edit(cur[0])) bail = 1  # M-HD-EDIT
    gitrx = 0
  }
  { L[NR] = $0 }
  END {
    n = NR; d = 0; bd = 0; qs = 0; cur[0] = ""; nq = 0; total = 0; bail = 0; risky = 0; work = 0; gitrx = 0
    if (n > 500) bail = 1
    i = 1
    while (!bail && i <= n) {
      line = L[i]; ln = length(line); p = 1; cont = 0
      if (ln > 4096) { bail = 1; break }
      if (line ~ /(^|[^A-Za-z0-9_])(function|alias|hash|enable|coproc)([^A-Za-z0-9_]|$)/ || line ~ /(^|[^A-Za-z0-9_])PATH[+]?=/) risky = 1
      if (line ~ /(aliases|functions|commands)(\[|[+]?=)/) risky = 1
      while (p <= ln) {
        if (++work > 20000) { bail = 1; break }
        c = substr(line, p, 1)
        if (qs == 1) { if (c == SQ) qs = 0; ap(c); p++; continue }
        if (qs == 3) {
          if (c == BS) { ap(substr(line, p, 2)); p += 2; continue }
          if (c == SQ) qs = 0
          ap(c); p++; continue
        }
        if (qs == 2) {
          if (c == BS) { ap(substr(line, p, 2)); p += 2; continue }
          if (c == "\"") { qs = 0; ap(c); p++; continue }
          if (c == "`") risky = 1
          if (c == "$" && substr(line, p + 1, 1) == "(") {
            if (substr(line, p + 2, 1) == "(") risky = 1
            d++; fk[d] = "S"; fq[d] = 2; cur[d] = ""; qs = 0; p += 2; continue
          }
          ap(c); p++; continue
        }
        if (c == BS) { if (p == ln) cont = 1; ap(substr(line, p, 2)); p += 2; continue }
        if (c == "#" && (p == 1 || substr(line, p - 1, 1) ~ /[ \t;&|()]/)) break
        if (c == SQ) { qs = (p > 1 && substr(line, p - 1, 1) == "$") ? 3 : 1; ap(c); p++; continue }
        if (c == "\"") { qs = 2; ap(c); p++; continue }
        if (c == "`") { risky = 1; ap(c); p++; continue }
        if (c == "$" && substr(line, p + 1, 1) == "{") { bd++; ap("${"); p += 2; continue }
        if (c == "$" && substr(line, p + 1, 1) == "[") risky = 1
        if (bd > 0 && c == "{") { bd++; ap(c); p++; continue }
        if (bd > 0 && c == "}") { bd--; ap(c); p++; continue }
        if (c == "$" && substr(line, p + 1, 1) == "(") {
          if (substr(line, p + 2, 1) == "(") risky = 1
          d++; fk[d] = "S"; fq[d] = 0; cur[d] = ""; p += 2; continue
        }
        if ((c == "<" || c == ">") && substr(line, p + 1, 1) == "(") { risky = 1; ap(c); p++; continue }
        if (c == "(") {
          if (substr(line, p + 1, 1) == "(" || substr(line, p + 1, 1) == ")") risky = 1
          d++; fk[d] = "P"; fq[d] = 0; cur[d] = ""; p++; continue
        }
        if (c == ")") { if (nq > 0) { bail = 1; break } if (d > 0) { if (fk[d] == "P" && cur[d] ~ /^[ \t]*$/) risky = 1; d--; qs = fq[d + 1]; ap("_") } p++; continue }
        if (c == "|") {
          if (substr(line, p + 1, 1) == "|") { if (d == 0) seg_done(); if (bail) break; cur[d] = ""; p += 2; continue }
          risky = 1; cur[d] = ""; p++; continue
        }
        if (c == "&" && (substr(line, p - 1, 1) ~ /[<>]/ || substr(line, p + 1, 1) == ">")) { ap(c); p++; continue }
        if (c == ";" || c == "&") { if (d == 0) seg_done(); if (bail) break; cur[d] = ""; p++; continue }
        if (c == "<" && substr(line, p + 1, 1) == "<") {
          if (substr(line, p + 2, 1) == "<") { ap("<<<"); p += 3; continue }
          if (bd > 0) { bail = 1; break }
          head = cur[d]; p += 2; strip = 0; quoted = 0; delim = ""
          if (substr(line, p, 1) == "-") { strip = 1; p++ }
          while (p <= ln && substr(line, p, 1) ~ /[ \t]/) p++
          c = substr(line, p, 1)
          if (c == SQ || c == "\"") {
            quoted = 1; e = index(substr(line, p + 1), c)
            if (e == 0) { bail = 1; break }
            delim = substr(line, p + 1, e - 1); p += e + 1
          } else {
            if (c == BS) { quoted = 1; p++ }
            while (p <= ln && wordch(substr(line, p, 1))) { delim = delim substr(line, p, 1); p++ }
          }
          if (delim !~ /^[A-Za-z0-9_.-]+$/) { bail = 1; break }
          if (p <= ln && substr(line, p, 1) !~ /[ \t;&|()<>]/) { bail = 1; break }
          if (!quoted) { bail = 1; break }  # M-HD-QUOTED
          if (d != 0) { bail = 1; break }  # M-HD-ENCL
          rv = recv_ok(head)
          if (!rv) { bail = 1; break }
          if (rv == 2) gitrx = 1
          if (++total > 8) { bail = 1; break }
          nq++; qd[nq] = delim; qt[nq] = strip
          ap("<<D ")
          continue
        }
        ap(c); p++
      }
      if (bail) break
      i++
      if (qs != 0) { if (nq > 0) { bail = 1; break } ap("\n"); continue }
      if (cont) { if (nq > 0) { bail = 1; break } continue }
      if (d == 0) seg_done()
      if (bail) break
      cur[d] = ""
      for (k = 1; k <= nq; k++) {
        found = 0
        while (i <= n) {
          t = L[i]; ex[i] = 1; i++
          if (qt[k]) sub(/^\t+/, "", t)
          if (t == qd[k]) { found = 1; break }
        }
        if (!found) { bail = 1; break }
      }
      nq = 0
    }
    if (bail || total == 0 || nq > 0 || risky || d != 0 || bd != 0 || qs != 0) { print "RAW"; exit }  # M-HD-RISKY
    out = ""; sep = ""
    for (j = 1; j <= n; j++) { if (j in ex) continue; out = out sep L[j]; sep = "\n" }
    print "EXCISED"; printf "%s", out
  }
'
readonly COMMAND_RAW="$COMMAND"
case "$COMMAND" in
  *'<<'*)
    _hd_out="$("$PRINTF" '%s' "$COMMAND" | /usr/bin/awk "$HEREDOC_DATA_AWK" 2>/dev/null)" || _hd_out=""
    case "$_hd_out" in
      EXCISED$'\n'?*) COMMAND="${_hd_out#EXCISED$'\n'}" ;;
    esac
    ;;
esac

# --- CANONICALIZE COMMAND POSITIONS (see CMDPOS_AWK above) ---
# Verify the primitive actually WORKS before trusting its output. A present-but-empty,
# truncated or corrupt awk would emit an empty string, and every matcher below would then
# find nothing — the whole hook would fail OPEN, which is strictly worse than the gap this
# closes. Canary: a one-line function body, whose canonical form MUST expose the inner
# command at an anchor position. Same posture as block-fragile-refs.sh's classifier canary
# (GHSA-g9g6-28c9-vrx5), and the same fail-closed direction as the dependency guard above.
CMDPOS_OK=0
if [ -r "$CMDPOS_AWK" ]; then
  # Two probes. The first — a one-line function body — detects a present-but-empty or
  # truncated copy. The second — a wrapper carrying a separate-argument option before a
  # benign verb — detects a VERSION SKEW (#8314): a copy that predates the wrapper-grammar
  # walk resolves the benign verb identically on both versions for the first probe, but
  # leaves it unreached here, where the walk that reads wrapper grammar exposes it at an
  # anchor. A stale or damaged row table therefore fails this probe, so the hook denies
  # rather than reading every wrapped command the old way while believing the primitive OK.
  # The second probe opens with the append form of a prefix assignment (#8314, follow-up
  # pass), so a copy whose walk reads that word as the command word — one that predates the
  # append form — fails it too.
  if _cp_canary="$("$PRINTF" '%s' 'q() { r; }' | /usr/bin/awk -f "$CMDPOS_AWK" 2>/dev/null)" \
     && "$PRINTF" '%s' "$_cp_canary" | "$GREP" -q '; r' \
     && _cp_canary2="$("$PRINTF" '%s' 'Z+=0 nice -n 0 q' | /usr/bin/awk -f "$CMDPOS_AWK" 2>/dev/null)" \
     && "$GREP" -q '; q' <<<"$_cp_canary2"; then
    CMDPOS_OK=1
  fi
fi
if [ "$CMDPOS_OK" != 1 ]; then
  log_error "PRIMITIVE-MISSING-OR-INVALID: command-position.awk unusable at $CMDPOS_AWK"
  deny_missing_primitive "command-position.awk" "$HOOK_NAME" "$PRINTF"
  exit 2   # caller owns the fail-closed exit — never trust the callee to terminate
fi
# One run of the canonicalizer gives the form every rule below reads; Step 5 alone canonicalizes
# once more, only on a command that carries a line continuation, over its joined reading. The hook keeps no exit
# that allows on a match ({{ADR:deletion-guard-judges-every-segment}}): every segment is judged,
# so a widening of the walk can only add command starts to judge, never turn a refusal into an
# allow, and the canonicalizer's frozen exit view has no reader here.
COMMAND_CMDPOS="$("$PRINTF" '%s' "$COMMAND" | /usr/bin/awk -f "$CMDPOS_AWK" 2>/dev/null || "$PRINTF" '%s' "$COMMAND")"
# Belt-and-braces: a non-empty command must never canonicalize to nothing.
[ -n "$COMMAND_CMDPOS" ] || COMMAND_CMDPOS="$COMMAND"

# --- HELPERS ---
log_block() {
  local rule_id="$1"
  local ts
  ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  local input_digest
  # The whole digest is read, then cut to its first 16 characters in the shell, so no reader
  # in the pipeline stops before its writer is done.
  input_digest="$("$PRINTF" '%s' "$COMMAND_RAW" | "$SHASUM" -a 256 | "$GREP" -oE '^[a-f0-9]+')"
  input_digest="${input_digest:0:16}"
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

# block_word_unknown(rule_id, token, cause) — the strict-policy refusal for a target word the shell
#   would expand or unquote in a way the hook does not reproduce on this line (class 4). cause is
#   the word resolve_and_classify printed: home, tilde or word.
block_word_unknown() {
  local why
  case "$3" in
    home)  why="home-relative target '$2' is on a line that names HOME, which can change the directory the shell expands it from before the command runs" ;;
    tilde) why="target '$2' begins with a tilde prefix other than ~/ or with a zsh equals-word, which the shell expands to a path the hook does not read" ;;
    *)     why="target '$2' is not a literal word: outside a whole-word quote it carries a brace, a backslash or a quote (as each piece of a quoted path with a space does) or a dot-leading glob component, which the shell expands or removes, so it acts on a different path from the one written; a whole-word quote whose body begins with a tilde or carries a backslash, a quote of the other kind or a dot-leading glob component is refused as well, although the shell keeps it as written" ;;
  esac
  block "$1" "path is unresolvable under strict policy: $why" \
    "name the target by a plain absolute path (a path with spaces through the Finder delete, whose POSIX file string the hook reads whole), or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
}

# block_unnormalized(rule_id, token) — the strict-policy refusal for a target the hook cannot bring
#   into one normalized form with the workspace root (class 5). It is never admitted as inside.
block_unnormalized() {
  block "$1" \
    "path is unresolvable under strict policy: the hook could not bring target '$2' and the workspace root into one normalized form (its path normalizer could not run or gave a form it cannot read, such as a path that carries a line break, or the root is not an absolute path), so the target is not admitted as inside the workspace" \
    "restore ${PYTHON3}, or name the target by a path whose resolved form is one line, or set the workspace root to an absolute path, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
}

# block_unclassified(rule_id, token, class) — the refusal for a class no arm names. Every
#   dispatcher ends with it, so a class added later can never fall through to an allow.
block_unclassified() {
  block "$1" \
    "target '$2' could not be classified (class $3) and is refused under strict policy" \
    "use explicit absolute paths instead of variables/subshells, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
}

# Pattern match against the canonicalized command. Rule patterns are unchanged; only the
# text they read is, so a verb at any genuine command start is now anchored. Direct
# "$COMMAND" readers below (the osascript POSIX-file extractor) deliberately read the command's
# own quoting, not the canonical form — they parse quoted argument text, which canonicalization
# is not for. "$COMMAND" is the command as judged: the raw text with any quoted here-document
# data body removed (see QUOTED HERE-DOCUMENT DATA).
matches() {
  local pattern="$1"
  "$PRINTF" '%s' "$COMMAND_CMDPOS" | "$GREP" -qE "$pattern"
}

# CLASSIFY_PY — normalize the target AND the workspace root with the same function, then print
# END. Output that is not exactly those three lines is failure (the CWD_TABLE_PY convention, made
# exact), so a normalizer that cannot run or does not finish, and a normalized path that carries a
# line break, never yield a comparison: read by line position, such a target would put a piece of
# itself where the root belongs. os.path.realpath collapses ../ and ./,
# does not require existence, and follows symlinks (intentional for strict-boundary enforcement);
# GNU realpath -m is absent on macOS, so Python 3 is the portable equivalent.
readonly CLASSIFY_PY='
import os, sys
print(os.path.realpath(sys.argv[1]))
print(os.path.realpath(sys.argv[2]))
print("END")
'

# classify_path(path) — Steps 5-6 below: normalize an absolute path and WORKSPACE_ROOT in one call,
#   then prefix-match the one against the other, so a root spelled through a symlink, with a
#   trailing slash or a dot segment is compared in its targets' form. Prints the normalized path
#   (on class 5, the path as given). Returns 0 inside, 1 outside, 5 when the two cannot be brought
#   into one form: the normalizer could not run, its output is not exactly the two normalized paths
#   and END (a normalized path that carries a line break, through a link whose destination holds
#   one), or the configured root is not absolute (a relative root is never anchored to this
#   process's own directory). Class 5 is never inside. A normalized root of / admits no target but
#   / itself, exactly as the as-spelled compare did.
classify_path() {
  local target="$1" out="" t r
  case "$WORKSPACE_ROOT" in /*) ;; *) "$PRINTF" '%s' "$target"; return 5 ;; esac  # M-TRASH-ROOTABS
  if [ -x "$PYTHON3" ]; then
    out="$("$PYTHON3" -c "$CLASSIFY_PY" "$target" "$WORKSPACE_ROOT" 2>/dev/null)" || out=""
  fi
  t="${out%%"$NL"*}"; r="${out#*"$NL"}"; r="${r%%"$NL"*}"
  if [ "$out" != "$t$NL$r${NL}END" ]; then "$PRINTF" '%s' "$target"; return 5; fi  # M-TRASH-NORMLINES
  "$PRINTF" '%s' "$t"
  case "$t" in
    "$r"|"$r/"*) return 0 ;;
    *) return 1 ;;
  esac
}

# resolve_and_classify(token, [seg])
#   Resolve a path token and classify against workspace boundary.
#   Returns: 0 = inside workspace, 1 = outside workspace, 2 = unresolvable (strict),
#            3 = relative operand whose working directory cannot be determined (strict),
#            4 = a word the shell would expand or unquote in a way the hook does not reproduce
#                on this line (strict); stdout carries which: home, tilde or word,
#            5 = the target and the workspace root cannot be brought into one normalized form
#                (strict; see classify_path)
#   Outputs the resolved absolute path on stdout (when return is 0 or 1). For a relative
#   operand, a newline and the directory it was judged from follow (see split_verdict).
#   seg is the operand's segment number (SEGMENT_WALK_AWK); empty means "after every
#   segment". ensure_cwd_table must have run in the hook's own shell first (it sets JUDGE_HOME).
resolve_and_classify() {
  local token="$1"
  local seg="${2:-}"
  local resolved="" quoted=0

  # Step 1: strip surrounding single/double quotes
  case "$token" in
    \"*\") token="${token#\"}"; token="${token%\"}"; quoted=1;;
    \'*\') token="${token#\'}"; token="${token%\'}"; quoted=1;;
  esac

  # Step 2: detect unresolvable patterns (variables, command substitution, backticks).
  # Patterns match literal $, $(, and ` characters in the input string.
  # shellcheck disable=SC2016  # literal char matches in case glob; not expansions
  case "$token" in
    *\$\(*) return 2;;
    *\`*)   return 2;;
    *\$*)   return 2;;
  esac

  # Step 2b: the target-literal rule. After Step 1, a word that still carries a brace, a backslash
  # or a quote is not literal: outside a whole-word quote the shell removes quotes, expands braces
  # and unescapes before the command runs, so the path written is not the path acted on (a quoted
  # path with a space arrives here as such words, because the walk splits on whitespace first). So
  # is a component that begins with . and carries a glob character (a shell before bash 5.2 can
  # match .. with it). Inside a whole-word quote the shell keeps a backslash, a quote of the other
  # kind and such a component as written, and the word is refused all the same (a declared
  # over-block); a
  # wholly-quoted word whose body begins with ~ is refused because Step 3 would expand a tilde the
  # shell keeps. A brace inside a whole-word quote never reaches this test: the canonicalizer
  # removes it from the quoted span first, so the word is judged without it. An unquoted glob
  # otherwise stays literal. Judged after Step 2, so a dynamic token keeps its own reason.
  case "$token" in
    *[{}\\\'\"]*) "$PRINTF" 'word'; return 4;;
  esac
  if [ "$quoted" = 1 ] && [ "${token:0:1}" = "~" ]; then "$PRINTF" 'word'; return 4; fi
  if [[ "/$token" =~ $DOTGLOB_RE ]]; then "$PRINTF" 'word'; return 4; fi

  # Step 3: tilde expansion (~ or ~/...) from JUDGE_HOME, the HOME the shell expands it from on
  # this line. On a line that names HOME, JUDGE_HOME is empty (ensure_cwd_table) and the word is
  # refused rather than expanded from a HOME the command may change first. Per-character checks
  # avoid the SC2088 false positive on the literal "~/" prefix string.
  if [ "$token" = "~" ] || { [ "${token:0:1}" = "~" ] && [ "${token:1:1}" = "/" ]; }; then
    case "$JUDGE_HOME" in /*) ;; *) "$PRINTF" 'home'; return 4;; esac
    token="${JUDGE_HOME}${token:1}"
  fi
  # Step 3b: any other tilde prefix (~user, ~+, ~-, a directory-stack index, a zsh named
  # directory) or a zsh equals-word (=cmd) expands to a path the hook does not read.
  case "$token" in
    "~"*|"="*) "$PRINTF" 'tilde'; return 4;;
  esac

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
# exception prints nothing, and the caller falls through to its existing refusal. The resolver
# has no raw-path fallback: a target it cannot normalize is class 5 and refused before this arm
# is consulted, and this arm's own program fails closed the same way. The operand is judged
# first, so a command whose operand cannot be an entry never opens a settings file. Admits
# (ELIGIBLE) only when ALL hold:
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
  digest="$("$PRINTF" '%s' "$COMMAND_RAW" | "$SHASUM" -a 256 2>/dev/null)" || return 1
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
#   3-tier: PATH trash → keg-only path (TRASH_KEG_DIR, which Step 3 also recognises) → osascript fallback.
suggest_trash_command() {
  local abs_path="$1"
  if command -v trash >/dev/null 2>&1; then
    "$PRINTF" "trash '%s'" "$abs_path"
  elif [ -x "${TRASH_KEG_DIR}/trash" ]; then
    "$PRINTF" "${TRASH_KEG_DIR}/trash '%s'" "$abs_path"
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
#   behavior (regex triggers but awk extracts no target tokens, so the
#   call reads as naming none and is refused by the target-less limb for
#   the wrong reason). Land as single atomic commit. The keg-only Trash
#   location is the same coupling for one verb: TRASH_VERB_RE, the keg strip
#   in the walk (its value passed by walk_segments) and suggest_trash_command
#   all read TRASH_KEG_DIR, so none can move without the others.
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
#   same coupling, and the target-less reader (mode "bare") is a fourth, under the
#   same skip rules, so the readers cannot disagree on where a segment starts or on
#   what counts as an operand. A `--` ends option parsing, so a dash-led token after
#   it is an operand, and a redirection is not an operand at all. Every reader goes
#   through walk_segments(), so an argument the walk needs reaches every mode.
#
# SEGMENT_WALK_AWK — the one segmentation every reader shares.
#   The line is cut on every `;`, `&` and `|`, and the canonicalizer reads an ampersand in a
#   redirection as a separator too, so a redirection can carry a command's words past a cut:
#   an operator left without its word (`2>&1`, `>&2`, `<&3`, `2>&-`, `>|file`: the cut fell on
#   the operator itself) takes the next fragment's first word as its word, and a both-streams
#   redirection (`&>file`, `&>>file`: a redirection in bash and zsh, a separator in dash) is
#   followed by the words the canonicalizer then read as a new command — but not past a separator
#   the line itself carries before a compound keyword or a command-prefix word, which the
#   canonicalizer marks with a separator after the word rather than before it. Each fragment is still a
#   segment of its own; the targets reader and the dirs reader also read a verb's segment on
#   through those fragments (widen), so the readings only add operands and directories.
#   mode "targets": print `<seg><TAB><token>` for each operand of verb v, the widened reading.
#   mode "bare":    print `<seg>` for each segment of verb v that does not name all its
#                   targets on its line: the segment on its own carries no operand under the
#                   targets mode's skip rules (flags, a "--", redirections and bare shell
#                   structure are not operands), or its record continues — the record's last
#                   word ends in an odd run of backslashes, so operands go on to the next line,
#                   a record of its own. Where the cut at a redirection's ampersand or pipe makes
#                   the continuation backslash a new command word, the canonicalizer drops it
#                   (a single leading backslash, from a command word), and what it leaves at the
#                   record's end continues the record too: a redirection operator left without
#                   its word, or a both-streams redirection then only the separator and blank the
#                   canonicalizer inserted. A backslash after a separator the line itself carries
#                   begins the next line's command and continues nothing. Read once per record,
#                   whichever redirection precedes the backslash, and every verb segment of a
#                   continued record is reported. A lone trailing backslash is not an operand.
#   mode "dirs":    print `<seg><TAB><kind><TAB><operand>` for each directory change,
#                   kind DIR (one literal operand), HOME (bare cd) or UNKNOWN (a form
#                   whose destination cannot be read from the line), for the segment on its
#                   own and again for its widened reading, plus a `0<TAB>REENTRANT` line
#                   when a loop or function definition can run a segment again after a
#                   later one (so order on the line is not order of execution).
# shellcheck disable=SC2016  # awk program — single quotes intentional
readonly SEGMENT_WALK_AWK='
  function skip_redirect(t) {
    # A redirection is not an operand; a bare operator takes the next token with it.
    if (t ~ /^[0-9]*(>>|>|<)/) { if (t ~ /(>>|>|<)$/) skipnext = 1; return 1; }
    return 0;
  }
  # keyword(str) — the first word of str is one the canonicalizer marks with a separator after it,
  # not before: a compound-command keyword or a command-prefix word. A ";" before such a word is
  # one the line itself carries, so no reading crosses it.
  function keyword(str,   w) {
    w = str; sub(/^[[:space:]]+/, "", w); sub(/[[:space:]].*$/, "", w); sub(/^\\/, "", w); sub(/.*\//, "", w);
    return (w ~ /^(if|while|until|in|then|do|else|elif|!|[{]|sudo|env|nice|nohup|command|builtin|exec|xargs|stdbuf|timeout|time)$/);
  }
  # widen(s) — the words of segment s (jt[1..jbase]), then the words a redirection carries past a
  # cut (jt[jbase+1..jm]). An operator left without its word takes the next fragment with it; a
  # both-streams redirection takes its own fragment and, through the one ";" the canonicalizer
  # puts before the word it then reads as a command, the fragment after it, unless that word is a
  # keyword (above). jend[i] marks the last word of the record.
  function widen(s,   k, i, mm, tk, amp) {
    jm = 0; jbase = 0; amp = 0; k = s;
    for (;;) {
      mm = split(segments[k], tk, /[[:space:]]+/);
      for (i = 1; i <= mm; i++) if (tk[i] != "") { jt[++jm] = tk[i]; jend[jm] = (k == lastk && i == lasti); }
      if (k == s) jbase = jm;
      if (k >= n) return;
      if (jm > 0 && jt[jm] ~ /^[0-9]*(>>|>|<|<>)$/) { amp = 0; k++; continue; }  # M-TRASH-REDIRAMP
      if (seps[k] ~ /(^|[^&])&$/ && segments[k + 1] ~ /^>/) { amp = 1; k++; continue; }  # M-TRASH-BOTHREDIR
      if (amp && seps[k] == ";" && segments[k + 1] ~ /[^[:space:]]/ && !keyword(segments[k + 1])) { amp = 0; k++; continue; }
      return;
    }
  }
  # lastword() — the last word of the record, and where it sits (lastk, lasti).
  function lastword(   k, mm, i, tk) {
    lastk = 0; lasti = 0; lastt = "";
    for (k = n; k >= 1; k--) {
      mm = split(segments[k], tk, /[[:space:]]+/);
      for (i = mm; i >= 1; i--) if (tk[i] != "") { lastk = k; lasti = i; lastt = tk[i]; return; }
    }
  }
  # dir_event(hi) — the directory change jt[1] makes, reading its words jt[2..hi].
  function dir_event(hi,   w, i, t, nops, op, bad, endopts, flags) {
    w = jt[1];
    if (w ~ /^(for|while|until|select|repeat|foreach|function)$/ || segments[s] ~ /\(\)/) reentrant = 1;
    if (w != "cd" && w != "chdir" && w != "pushd" && w != "popd") return;
    # popd returns to a directory-stack entry, which can predate this command.
    if (w == "popd") { print seg "\tUNKNOWN\t"; return; }
    flags = (w == "pushd") ? "^-[LPqs]+$" : "^-[LPeqs@]+$";
    nops = 0; bad = 0; endopts = 0; skipnext = 0; op = "";
    for (i = 2; i <= hi; i++) {
      t = jt[i];
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
    # Split on command separators first; each segment is separator-free. seps[k] is the separator
    # run that ends segment k (the pieces between the runs of other characters).
    n = split($0, segments, /[;&|]+/);
    split($0, runs, /[^;&|]+/); off = ($0 ~ /^[;&|]/) ? 0 : 1;
    for (k = 1; k <= n; k++) seps[k] = runs[k + off];
    # The record continues when its last word ends in an odd run of backslashes: the operands go
    # on to the next line, a record of its own. Read once per record, wherever the cut fell.
    lastword();
    rc = (lastk > 0 && match(lastt, /\\+$/) && RLENGTH % 2 == 1);  # M-TRASH-RECCONT
    # A cut at the ampersand or pipe of a redirection can make the continuation backslash a command
    # word, which the canonicalizer drops, so read what it leaves at the end of the record the same
    # way: a redirection operator left without its word (the word is on the next line, or the line
    # is a syntax error), or a both-streams redirection then only the inserted separator and blank.
    if (lastk > 0 && lastt ~ /^[0-9]*(>>|>|<|<>)$/) rc = 1;  # M-TRASH-RECWORD
    if (n >= 3 && segments[n] == " " && seps[n - 1] == ";" && segments[n - 1] ~ /^>/ && seps[n - 2] ~ /(^|[^&])&$/) rc = 1;  # M-TRASH-RECBOTH
    for (s = 1; s <= n; s++) {
      seg++;
      widen(s);
      if (jbase == 0) continue;
      if (mode == "dirs") { dir_event(jbase); if (jm > jbase) dir_event(jm); continue; }
      # Strip canonical absolute-path prefix from first token before
      # verb-equality check. Matches the 5 macOS/Linux paths
      # captured by ANCHOR_PREFIX_BASH at the regex-anchor site, and, for
      # the Trash verb, the keg-only location TRASH_VERB_RE also matches
      # (keg, passed by walk_segments to every mode).
      first_token = jt[1];
      sub(/^\/(usr\/(local\/)?|opt\/(homebrew|local)\/)?bin\//, "", first_token);
      if (v == "trash" && keg != "" && index(first_token, keg "/") == 1) first_token = substr(first_token, length(keg) + 2);
      if (first_token != v) continue;
      endopts = 0; skipnext = 0; nops = 0;
      for (i = 2; i <= jm; i++) {
        t = jt[i];
        # A lone trailing backslash continues the record; it is not an operand.
        if (jend[i] && t == "\\") continue;
        if (skipnext) { skipnext = 0; continue; }
        if (skip_redirect(t)) continue;
        # Skip bare shell structure. A subshell leaves its closing `)` inside
        # the segment, and without this `( rm -rf )` would resolve `)` as a
        # relative path (#5644); it is refused instead as naming no operand.
        if (t ~ /^[(){}]+$/) continue;
        # Skip flags (start with -) until a `--` ends option parsing.
        if (!endopts && t == "--") { endopts = 1; continue; }
        if (!endopts && substr(t, 1, 1) == "-") continue;
        # The bare reading counts the segment on its own, so a widened word never clears it.
        if (i <= jbase) nops++;
        if (mode == "targets") print seg "\t" t;
      }
      if (mode == "bare" && (nops == 0 || rc)) print seg;
    }
  }
  END { if (mode == "dirs" && reentrant) print "0\tREENTRANT\t"; }
'

# walk_segments(mode, verb) — the one call site of SEGMENT_WALK_AWK. Every reader below goes
# through it, so an argument the walk needs (the keg-only Trash location, TRASH_KEG_DIR, which a
# Trash call's first token is stripped of) is passed to every mode at once and no reader can omit it.
walk_segments() {
  "$PRINTF" '%s' "$COMMAND_CMDPOS" | /usr/bin/awk -v mode="$1" -v v="$2" -v keg="$TRASH_KEG_DIR" "$SEGMENT_WALK_AWK"  # M-TRASH-KEG
}

extract_target_tokens() {
  walk_segments targets "$1"
}

# extract_dir_events — the directory changes on the line, in SEGMENT_WALK_AWK's "dirs" form.
extract_dir_events() {
  walk_segments dirs ""
}

# extract_bare_segments(verb) — the segments of a verb that do not name all their targets on
# their line, in SEGMENT_WALK_AWK's "bare" form.
extract_bare_segments() {
  walk_segments bare "$1"
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
#   - the destination depends on HOME (a bare cd, a ~/ operand) and the line names HOME:
#     ensure_cwd_table then passes no home, so the program has none to expand from;
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
# HOME_WORD_RE — HOME as a whole word (JAVA_HOME and HOMEBREW_* do not count). DOTGLOB_RE — a path
# component that begins with . and carries a glob character, matched against "/<token>".
readonly HOME_WORD_RE='(^|[^A-Za-z0-9_])HOME([^A-Za-z0-9_]|$)'
readonly DOTGLOB_RE='/\.[^/]*[*?[]'
JUDGE_HOME=""         # the HOME a ~/ word expands from; set by ensure_cwd_table; empty = refuse
CWD_TABLE_READY=0
CWD_EVT_SEG=()        # segment of each directory a change can lead to
CWD_EVT_DIR=()        # ... and the directory
CWD_UNKNOWN_SEG=""    # first segment whose change cannot be followed, if any
CWD_REENTRANT=0       # 1 when a loop or function can re-run a segment

# ensure_cwd_table — build the in-command working-directory table once. Call it in the
# hook's own shell (never inside $( )), before the first relative target is judged. A
# command with no directory change builds nothing and judges exactly as before.
ensure_cwd_table() {
  local events="" table="" cdpath=0 eseg ekind edir stripped sq="'" bs="\\"
  if [ "$CWD_TABLE_READY" = 1 ]; then return 0; fi
  CWD_TABLE_READY=1
  # A line that names HOME as a word can change HOME before the verb runs, so no home-relative
  # word is expanded on it: a ~/ target is refused (class 4), and a bare cd or a cd ~/... is left
  # unfollowed (class 3 for a relative target after it). Read on the command as judged, and again
  # with every quote and backslash removed, because a shell assigns by the processed word (a
  # declaration or name-operand builtin can spell the name with an embedded quote or a backslash).
  # A name that only contains HOME does not count. Not seen: a name composed by an expansion (the
  # indirect-spelling class), and a change the line does not spell at all (a nested shell's
  # program, a sourced file, a function or alias from the environment: the nested-shell residual).
  stripped="${COMMAND//\"/}"; stripped="${stripped//$sq/}"; stripped="${stripped//"$bs"/}"
  if [[ "$COMMAND" =~ $HOME_WORD_RE ]] || [[ "$stripped" =~ $HOME_WORD_RE ]]; then
    JUDGE_HOME=""
  else
    JUDGE_HOME="${HOME:-}"
  fi
  events="$(extract_dir_events)" || events="0${TAB}UNKNOWN${TAB}"
  case "$events" in *"${TAB}REENTRANT${TAB}"*) CWD_REENTRANT=1 ;; esac
  case "$events" in *"${TAB}DIR${TAB}"*|*"${TAB}HOME${TAB}"*|*"${TAB}UNKNOWN${TAB}"*) ;; *) return 0 ;; esac
  case "$COMMAND" in *CDPATH*) cdpath=1 ;; esac
  if [ -x "$PYTHON3" ]; then
    table="$("$PRINTF" '%s\n' "$events" | "$PYTHON3" -c "$CWD_TABLE_PY" "$CWD" "$JUDGE_HOME" "$CWD_REENTRANT" "$cdpath" 2>/dev/null)" || table=""
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

# judge_targets(verb) — extract and classify every target token of a deletion verb on the
# canonicalized command, blocking on the first one (every classification of rm/rmdir/unlink
# blocks). Step 2 calls it once for each rm-family verb at a command start.
judge_targets() {
  local verb="$1" tseg token classification verdict resolved suggestion
  while IFS="$TAB" read -r tseg token; do
    [ -z "$token" ] && continue
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
      4)
        # A word the shell would expand or unquote otherwise than the hook reads it
        block_word_unknown "BLOCK-TRASH-001" "$token" "$resolved"
        ;;
      5)
        # Target and root cannot be brought into one normalized form
        block_unnormalized "BLOCK-TRASH-001" "$token"
        ;;
      *)
        block_unclassified "BLOCK-TRASH-001" "$token" "$classification"
        ;;
    esac
  done < <(extract_target_tokens "$verb")
}

# ==========================================================================
# RULE EVALUATION
# ==========================================================================

# Trash-verb operands the MEMORY-STORE ARM admitted; each leaves one row before the allow.
MEMORY_ADMISSIONS=0

# Step 1 — the git subcommand exemption, per segment. A segment whose command word is git
# (bare or by absolute path) is never judged as a deletion: no step below reads a segment whose
# command word is not its own verb. The exemption therefore covers that segment only, and every
# other segment on the line is judged as if it were absent, except that the Finder step (Step 4)
# reads every quoted Finder path on the line, the git segment's own text included. There is
# deliberately no exit here: an exit that allows on a match reads the whole line
# ({{ADR:deletion-guard-judges-every-segment}}).
:  # M-TRASH-SEGWALK

# Step 2 — every rm-family verb, each judged on its own segments. A segment that names no operand
# ends nothing here: the remaining verbs, the Trash step and the Finder step are judged first, and
# the target-less limb after Step 4 refuses it.
# Absolute-path-aware: also detects /bin/rm, /usr/bin/rm, etc.
for verb in rm rmdir unlink; do
  if matches "${ANCHOR_PREFIX_BASH}${verb}"'([[:space:]]+|$)'; then
    ensure_cwd_table
    judge_targets "$verb"  # M-TRASH-SEGVERB
  fi
done

# Step 3 — trash invocation detection
# Absolute-path-aware: also detects /opt/homebrew/bin/trash, /usr/bin/trash, etc., and the
# keg-only location the tier-2 suggestion names (TRASH_KEG_DIR, through TRASH_VERB_RE).
if matches "$TRASH_VERB_RE"; then
  ensure_cwd_table
  while IFS="$TAB" read -r tseg token; do
    [ -z "$token" ] && continue
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
      4)
        block_word_unknown "BLOCK-TRASH-003" "$token" "$resolved"
        ;;
      5)
        block_unnormalized "BLOCK-TRASH-003" "$token"
        ;;
      *)
        block_unclassified "BLOCK-TRASH-003" "$token" "$classification"
        ;;
    esac
  done < <(extract_target_tokens "trash")
  # The target-less limb: a Trash segment that does not name all its targets on its line (no
  # operand, or its line continues) is refused under the strict policy. A Trash program can act
  # on what the line does not name (an empty-the-Trash option takes no operand). Judged after the
  # operands, so it never masks their refusals.
  if [ -n "$(extract_bare_segments trash)" ]; then  # M-TRASH-BARETRASH
    block "BLOCK-TRASH-003" \
      "a Trash invocation that does not name all its targets on its line (no target operand, or the line continues) is unresolvable under strict policy" \
      "name each target by absolute path on the command's own line, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
  fi
fi

# Step 4 — osascript Trash-verb detection
# Trigger only when osascript invocation contains a Trash-verb pattern
# Absolute-path-aware: also detects /usr/bin/osascript, etc.
if matches "${ANCHOR_PREFIX_BASH}"'osascript([[:space:]]+|$)'; then
  if matches 'delete[[:space:]]+POSIX[[:space:]]+file' || matches 'move[[:space:]]+.*[[:space:]]+to[[:space:]]+trash'; then
    # Extract POSIX file paths from the AppleScript source.
    # Pattern: delete POSIX file "/abs/path"
    # The extractor reads the command as judged (raw quoting, data bodies removed) and carries no segment number, so a relative path
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
        4)
          block_word_unknown "BLOCK-TRASH-003" "$osa_path" "$resolved"
          ;;
        5)
          block_unnormalized "BLOCK-TRASH-003" "$osa_path"
          ;;
        *)
          block_unclassified "BLOCK-TRASH-003" "$osa_path" "$classification"
          ;;
      esac
    done < <("$PRINTF" '%s' "$COMMAND" | "$GREP" -oE 'POSIX[[:space:]]+file[[:space:]]+"[^"]*"' | "$GREP" -oE '"[^"]*"' | /usr/bin/sed 's/^"//; s/"$//')
  fi
fi

# The target-less limb for rm, rmdir and unlink: a segment that does not name all its targets on
# its line is refused under the strict policy. Judged last, so a refusal of a real target
# elsewhere on the line always names that target.
for verb in rm rmdir unlink; do
  if matches "${ANCHOR_PREFIX_BASH}${verb}"'([[:space:]]+|$)' && [ -n "$(extract_bare_segments "$verb")" ]; then  # M-TRASH-BARERM
    block "BLOCK-TRASH-001" \
      "a $verb invocation that does not name all its targets on its line (no target operand, or the line continues) is unresolvable under strict policy" \
      "name each target by absolute path on the command's own line, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
  fi
done

# Step 5 — a command that carries a line continuation. Outside the quoted here-document bodies the
# pre-pass removed, a line that ends in an odd run of backslashes continues onto the next one; an even
# run is literal backslashes and continues nothing. The shell joins the two lines before it reads a
# word, so a continuation can split a command word or carry a wrapper option's argument or an
# assignment's value to the next line, while a backslash that ends a comment continues nothing and the
# next line runs as its own command. The hook does not decide which of these the shell does. On such a
# command it takes two readings — the command as judged, each line its own, and the command with every
# continuation joined (each odd run's last backslash and the newline after it removed, then
# canonicalized once more) — and refuses a deletion or Trash verb found in either, in any spelling the
# steps above recognise: BLOCK-TRASH-003 for a Trash call or a Finder delete, else BLOCK-TRASH-001.
# This decides every continued command; the walk's per-form readings (M-TRASH-RECCONT, -RECWORD and
# -RECBOTH) stay in place and refuse first where they fire. Judged after every other step, so a
# refusal of a real target names that target, and before the admission rows below, so a refused
# command leaves none. Declared over-block: every command with a continuation and a deletion or Trash
# verb is refused, whatever the shell would join. Declared residual: the joined reading reads the line
# after a comment that ends in a backslash as part of that comment, so a verb on it that only joining
# would reveal (a command word a continuation splits, a wrapper and its option spread over continued
# lines) is seen by neither reading.
#
# CONT_JOIN_AWK prints NONE when no line but the last ends in an odd run of backslashes, else JOINED,
# a newline, and the joined reading. Any other output is failure, and the command is then read as
# continued with its unjoined text in both readings (fail closed).
# shellcheck disable=SC2016  # awk program — single quotes intentional
readonly CONT_JOIN_AWK='
  { L[NR] = $0 }
  END {
    out = ""; hit = 0
    for (i = 1; i <= NR; i++) {
      s = L[i]
      if (i < NR && match(s, /\\+$/) && RLENGTH % 2 == 1) { hit = 1; out = out substr(s, 1, length(s) - 1); continue }
      out = out s
      if (i < NR) out = out "\n"
    }
    if (!hit) { print "NONE"; exit }
    print "JOINED"; printf "%s", out
  }
'
readonly BS_NL=$'\\\n'

# cont_verbs(reading) — print trash for a Trash call or a Finder delete, and rm for an rm, rmdir or
#   unlink, at a command start of a reading in canonical form: the tests Steps 2 to 4 apply, read from
#   a here-string so no reader in a pipeline stops before its writer is done.
cont_verbs() {
  local verb
  if "$GREP" -qE "$TRASH_VERB_RE" <<<"$1"; then "$PRINTF" 'trash\n'; fi
  if "$GREP" -qE "${ANCHOR_PREFIX_BASH}"'osascript([[:space:]]+|$)' <<<"$1" \
     && { "$GREP" -qE 'delete[[:space:]]+POSIX[[:space:]]+file' <<<"$1" || "$GREP" -qE 'move[[:space:]]+.*[[:space:]]+to[[:space:]]+trash' <<<"$1"; }; then
    "$PRINTF" 'trash\n'
  fi
  for verb in rm rmdir unlink; do
    if "$GREP" -qE "${ANCHOR_PREFIX_BASH}${verb}"'([[:space:]]+|$)' <<<"$1"; then "$PRINTF" 'rm\n'; fi
  done
}

CONT_LINE=0
COMMAND_JOINED=""
CONT_FOUND=""
case "$COMMAND" in *"$BS_NL"*) CONT_LINE=1 ;; esac  # M-TRASH-CONTLINE
if [ "$CONT_LINE" = 1 ]; then
  _cont_out="$("$PRINTF" '%s' "$COMMAND" | /usr/bin/awk "$CONT_JOIN_AWK" 2>/dev/null)" || _cont_out=""
  case "$_cont_out" in
    NONE) CONT_LINE=0 ;;
    JOINED$'\n'*) COMMAND_JOINED="${_cont_out#JOINED$'\n'}" ;;
    *) COMMAND_JOINED="$COMMAND" ;;
  esac
fi
if [ "$CONT_LINE" = 1 ]; then
  COMMAND_JOINED_CMDPOS="$("$PRINTF" '%s' "$COMMAND_JOINED" | /usr/bin/awk -f "$CMDPOS_AWK" 2>/dev/null || "$PRINTF" '%s' "$COMMAND_JOINED")"
  [ -n "$COMMAND_JOINED_CMDPOS" ] || COMMAND_JOINED_CMDPOS="$COMMAND_JOINED"
  CONT_FOUND="$(cont_verbs "$COMMAND_CMDPOS")"  # M-TRASH-CONTUNJ
  CONT_FOUND="${CONT_FOUND}$(cont_verbs "$COMMAND_JOINED_CMDPOS")"  # M-TRASH-CONTJOIN
  case "$CONT_FOUND" in
    *trash*)
      block "BLOCK-TRASH-003" \
        "a command that carries a line continuation (an odd run of backslashes before a newline) and a Trash call or a Finder delete, as written or with its continuations joined, is unresolvable under strict policy: the hook does not decide which lines the shell joins" \
        "write the command on one line, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
      ;;
    *rm*)
      block "BLOCK-TRASH-001" \
        "a command that carries a line continuation (an odd run of backslashes before a newline) and an rm, rmdir or unlink invocation, as written or with its continuations joined, is unresolvable under strict policy: the hook does not decide which lines the shell joins" \
        "write the command on one line, or set CLAUDE_HOOK_BYPASS=1 only if absolutely intentional"
      ;;
  esac
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
