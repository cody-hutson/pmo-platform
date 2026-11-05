#!/bin/bash
# block-egress.sh — PreToolUse hook blocking network egress / data-exfiltration channels
# hook-owner: core/rules/bypass-mode-readiness/block-egress.md
#
# Closes Red Team C2 (Critical): the credential-read deny only covers Claude's Read tool;
# Bash subprocesses (cat, curl, gh gist, nc, scp) bypass it entirely.
#
# Coverage:
#   - Subprocess credential reads (cat/head/tail/base64 on ~/.ssh, ~/.aws, *.env, *.pem, *.key)
#   - Network upload channels (curl POST, wget --post-*, gh gist, gh api POST)
#   - Raw network tools (nc, ncat, scp, rsync, ssh) with allowlists
#   - WebFetch domain allowlist
#
# Warn-mode: reads .claude/hooks/.mode (warn|enforce|off).
#   Default state for new deploy is `warn` — 2-week (fast-path: 3-day) shakedown.
#   User flips to `enforce` after reviewing egress-warn-log.jsonl.
#
# Matcher scope: Bash, WebFetch
# Rule ID range: BLOCK-EGRESS-001..099
#
# Part of: the bypass-permissions-readiness hardening.

set -euo pipefail

# --- PATH PINNING ---
export PATH="/usr/bin:/bin"

readonly GREP="/usr/bin/grep"
readonly PRINTF="/usr/bin/printf"
readonly CAT="/bin/cat"
readonly TR="/usr/bin/tr"
readonly DATE="/bin/date"
# jq is resolved below via lib/dep-resolve.sh (once HOOK_DIR is known), from a fixed
# absolute-path allowlist — never $PATH — so the anti-hijack PATH pin above still
# holds (GHSA-9cjm-v22x-4x33: was hard-coded to /usr/bin/jq, absent on a documented
# `brew install jq` macOS host, which triggered the fail-open branch below).

# --- METADATA ---
readonly HOOK_NAME="block-egress"
readonly HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"
readonly ERROR_LOG="${HOOK_DIR}/hook-errors.log"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"
readonly WARN_LOG="${HOOK_DIR}/egress-warn-log.jsonl"
readonly MODE_FILE="${HOOK_DIR}/.mode"

readonly EGRESS_ALLOWLIST="${HOOK_DIR}/../egress-allowlist.txt"
readonly WEBFETCH_ALLOWLIST="${HOOK_DIR}/../webfetch-allowlist.txt"
readonly SSH_ALLOWLIST="${HOOK_DIR}/../ssh-allowlist.txt"
# Line prefix of a row-scope directive in egress-allowlist.txt (read by is_allowlisted).
readonly EGRESS_SCOPE_DIRECTIVE='# egress-scope:'

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
# existing posture.
# WebFetch-branch rules (BLOCK-EGRESS-012, BLOCK-EGRESS-013) are
# tool-name-matched (not verb-anchored) and not affected by this hook.
readonly ANCHOR_PREFIX_BASH='(^|[;&|])[[:space:]]*(/(usr/(local/)?|opt/(homebrew|local)/)?bin/)?'

# --- COMMAND-POSITION CANONICALIZER (shared primitive, #5644) ---
# The anchor above recognises a command start ONLY at start-of-line or after `;`, `&`,
# `|`, so a verb inside `{ … }`, `( … )`, after `then`/`do`, behind `sudo`/`env`/`xargs`/
# `VAR=…`, or written `\curl` was invisible to it — the verdict tracked lexical POSITION
# rather than the action. The Bash-branch command is canonicalized before matching so
# genuine command starts become positions this anchor already recognises; the anchor,
# rule IDs and messages are unchanged. ONE implementation shared by all four
# anchor-carrying hooks (see core/hooks/lib/command-position.awk). The -007 path keeps its
# own egress_neutralize_quoted() reading the RAW command — that mechanism is unchanged.
readonly CMDPOS_AWK="${HOOK_DIR}/lib/command-position.awk"

# --- MODE DETECTION (jq-free; defined BEFORE the dependency gate so a mode-gated
# hook can degrade correctly when jq is unresolvable) ---
get_mode() {
  local mode="enforce"
  if [ -f "$MODE_FILE" ]; then
    mode="$("$CAT" "$MODE_FILE" 2>/dev/null | "$TR" -d '[:space:]' || echo enforce)"
  fi
  case "$mode" in
    warn|enforce|off) "$PRINTF" '%s' "$mode" ;;
    *) "$PRINTF" 'enforce' ;;  # default on unrecognized value
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

# --- SHARED DEPENDENCY RESOLVER (mode-coupled: fail CLOSED in enforce, degrade in warn/off) ---
# Test readability BEFORE sourcing: bash 3.2 (macOS system bash) exits 1 on a failed
# `.` of a missing file even inside an `if !` condition, and exit 1 (unlike exit 2) is
# NON-blocking in the PreToolUse contract — i.e. a missing helper would fail OPEN.
# Precheck syntax with `bash -n` BEFORE sourcing: a truncated/corrupt lib is a parse
# error, and sourcing a parse-error file is FATAL to this parent. Also require
# deny_missing_primitive so a valid-but-stale lib (pre-fix, no helper) trips here.
# Severity is mode-coupled: a rule match in warn/off would not block, so an unusable
# helper must not block harder than a match would.
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

trap 'rc=$?; log_error "RULE-EVAL-ERROR at line $LINENO (exit $rc)"; "$PRINTF" "[CLAUDE-HOOK:%s:HOOK-ERROR] BLOCKED: rule-eval error at line %s (exit %s). See %s.\n" "$HOOK_NAME" "$LINENO" "$rc" "$ERROR_LOG" >&2; exit 2' ERR

# --- READ INPUT (jq-free; stdin is consumed exactly once) ---
INPUT="$(cat)"

# --- CLAUDE_HOOK_BYPASS escape hatch — evaluated BEFORE the jq gate so it works
# even when jq is unresolvable (GHSA-9cjm-v22x-4x33: the escape hatch its own
# message advertises must not sit behind the fail-closed gate). ---
if [ "${CLAUDE_HOOK_BYPASS:-}" = "1" ]; then
  ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
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
# .mode read. CLASS=security (D-R9): master-OFF NEVER makes this hook inert — the
# security/floor class always enforces (public-surface security is paramount; a silently
# disabled guard -> an IRREVERSIBLE leaked commit/PR). It goes inert ONLY on the operator's
# explicit, logged security_class_master_optout=true. Fail-toward-current-behavior: a
# missing lib does NOT gate. Read jq-free from the durable XDG platform-config.toml. ---
readonly MASTER_ENABLE_CLASS="security"
readonly MASTER_LIB="${HOOK_DIR}/lib/master-enable.sh"
if [ -r "$MASTER_LIB" ]; then . "$MASTER_LIB" 2>/dev/null || true; fi
if command -v master_enable_gate >/dev/null 2>&1; then master_enable_gate "$MASTER_ENABLE_CLASS"; fi

# --- DEPENDENCY GATE (mode-gated: a security control that cannot evaluate its input
# must not fail more permissively than a rule match would. In enforce a rule match
# blocks (exit 2), so unresolved jq DENIES; in warn/off a rule match exits 0, so
# unresolved jq degrades to a stderr note + exit 0 — GHSA-9cjm-v22x-4x33). Runs AFTER
# the bypass short-circuit. ---
if [ -z "$JQ" ]; then
  log_error "DEPENDENCY-MISSING: jq not found on the pinned tool path"
  _mode="$(get_mode)"
  if [ "$_mode" = "enforce" ]; then
    deny_missing_dep jq "$HOOK_NAME" "$PRINTF"
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:DEPENDENCY-DEGRADED] jq unresolved and .mode=%s — cannot evaluate; allowing (degraded; would BLOCK in enforce).\n' "$HOOK_NAME" "$_mode" >&2
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

# --- BLOCK LOG HELPER ---
#
# Every refusal record names the rule and the tool and carries `evidence` — the
# rule-specific detail apply_block receives: the denied path, the target host, the cause
# class. The block log (enforce) adds `input_digest` and `cwd`; the warn log (warn) adds
# `reason`. Neither carries the command text: the digest is a one-way hash of the tool
# input, and the warn log carries no digest at all.
#
# For most rules `evidence` is what lets an operator tell a genuine catch from a false
# positive. For BLOCK-EGRESS-007 `unparseable` it cannot: that cause has no path, so its
# evidence is always the constant `path=unknown cause=unparseable`. Records of that one
# class therefore carry two more keys, in BOTH writers:
#   features    the command's STRUCTURE — never its text, offsets or lengths:
#                 schema_version  versions this set (the integer 1)
#                 oracle          the parser that judged the syntax: `bash-<major>.<minor>`
#                                 (the running bash), or `unknown`
#                 shell_parse     that parser's verdict (`-n`: read, never executed):
#                                 `ok` = accepted, so the refusal was false; `error` =
#                                 rejected BY THAT PARSER — the shell that runs the
#                                 command may still accept it (bash and zsh diverge);
#                                 `skipped` = above the size cap, not checked;
#                                 `unavailable` = the parser is missing or gave no verdict
#                 heredoc         the heredoc delimiter quoting it uses: none | quoted |
#                                 unquoted | both, `skipped` above the cap, or
#                                 `unavailable` when the scan could not run
#   hook_build  the first 16 hex of the git blob id of the hook file that wrote the
#               record, so a record names its producer across redeploys
#               (`git log --raw --no-abbrev -- core/hooks/block-egress.sh` resolves it)
# A specificity reading classifies the class by `features.shell_parse`, scoped by
# `features.oracle`: `error` -> rejected by the recorded oracle (a true positive where
# that oracle's grammar is the executing shell's), `ok` -> benign-shape, `skipped` or
# `unavailable` -> unclassified.
#
# Both keys are optional; every other record keeps the plain template, and every
# consumer reads by key. Neither can change a verdict: the features are computed before
# apply_block is entered, and apply_block takes its exit from the mode alone. The write
# path is failure-proof because it must be: under `set -e` a failing command inside a
# function ends this hook with status 1, which PreToolUse treats as NON-blocking, so an
# unguarded step here would lose the deny that follows it. The feature path is bounded in
# TIME as well as status — each computation is linear in the command and capped — because
# a hook that outlasts its timeout does not block either. A record whose features cannot
# be computed carries the not-computed set (every member `unavailable`, the oracle
# `unknown`); one whose features cannot be written is written with `hook_build` alone;
# and one that cannot carry either is written plain.
log_block() {
  local rule_id="$1"
  local evidence="${2:-}"
  local features="${3:-}"   # optional feature object — only the -007 unparseable class passes one
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  # Both digest steps are guarded. The 16 hex are cut by parameter expansion — the same
  # bytes the former `| grep -oE | head -c 16` cut, with no pipe into a short-circuiting
  # reader.
  local tool_input; tool_input="$("$PRINTF" '%s' "$INPUT" | "$JQ" -c '.tool_input // {}')" || tool_input='{}'
  local input_digest; input_digest="$("$PRINTF" '%s' "$tool_input" | /usr/bin/shasum -a 256)" || input_digest=""
  input_digest="${input_digest%% *}"; input_digest="${input_digest:0:16}"
  [ -n "$input_digest" ] || input_digest="unknown"
  if [ -n "$features" ]; then
    local build; build="$(egress_hook_build)" || build="unknown"
    "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
      --arg tool "$TOOL_NAME" --arg digest "$input_digest" --arg cwd "$CWD" \
      --arg evidence "$evidence" --arg build "$build" --argjson features "$features" \
      '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, input_digest:$digest, cwd:$cwd, evidence:$evidence, hook_build:$build, features:$features}' \
      >> "$BLOCK_LOG" 2>/dev/null && return 0
    "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
      --arg tool "$TOOL_NAME" --arg digest "$input_digest" --arg cwd "$CWD" \
      --arg evidence "$evidence" --arg build "$build" \
      '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, input_digest:$digest, cwd:$cwd, evidence:$evidence, hook_build:$build}' \
      >> "$BLOCK_LOG" 2>/dev/null && return 0
  fi
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg digest "$input_digest" --arg cwd "$CWD" \
    --arg evidence "$evidence" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, input_digest:$digest, cwd:$cwd, evidence:$evidence}' \
    >> "$BLOCK_LOG" 2>/dev/null || true
}

# Append a JSONL entry to warn log with digest (no raw secrets in log)
log_warn() {
  local rule_id="$1"
  local reason="$2"
  local evidence="$3"  # tool-specific evidence (command digest, URL, etc.) — may contain digest, NOT raw
  local features="${4:-}"   # optional feature object — only the -007 unparseable class passes one
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  if [ -n "$features" ]; then
    local build; build="$(egress_hook_build)" || build="unknown"
    "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
      --arg tool "$TOOL_NAME" --arg reason "$reason" --arg evidence "$evidence" \
      --arg build "$build" --argjson features "$features" \
      '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, reason:$reason, evidence:$evidence, hook_build:$build, features:$features}' \
      >> "$WARN_LOG" 2>/dev/null && return 0
    "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
      --arg tool "$TOOL_NAME" --arg reason "$reason" --arg evidence "$evidence" \
      --arg build "$build" \
      '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, reason:$reason, evidence:$evidence, hook_build:$build}' \
      >> "$WARN_LOG" 2>/dev/null && return 0
  fi
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg reason "$reason" --arg evidence "$evidence" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, reason:$reason, evidence:$evidence}' \
    >> "$WARN_LOG" 2>/dev/null || true
}

# Apply block per current mode
apply_block() {
  local rule_id="$1"
  local reason="$2"
  local override="$3"
  local evidence="${4:-}"
  local features="${5:-}"   # optional feature object — only the -007 unparseable class passes one
  local mode; mode="$(get_mode)"

  case "$mode" in
    warn)
      log_warn "$rule_id" "$reason" "$evidence" "$features"
      "$PRINTF" '[CLAUDE-HOOK:%s:%s] WARN (would-block, .mode=warn): %s\n' "$HOOK_NAME" "$rule_id" "$reason" >&2
      exit 0
      ;;
    off)
      exit 0
      ;;
    enforce|*)
      log_block "$rule_id" "$evidence" "$features"
      "$PRINTF" '[CLAUDE-HOOK:%s:%s] BLOCKED: %s\nOverride: %s\n' "$HOOK_NAME" "$rule_id" "$reason" "$override" >&2
      exit 2
      ;;
  esac
}

# --- HELPERS ---

# Pattern match against the canonicalized command. Rule patterns are unchanged; only the
# text they read is, so a verb at any genuine command start is now anchored. Direct
# "$COMMAND" readers below (the -007 quote-neutralizer, the URL and ssh-host extractors)
# deliberately keep the RAW command — they parse argument text, not command position.
matches() {
  "$PRINTF" '%s' "$COMMAND_CMDPOS" | "$GREP" -qE "$1"
}

# Check a value against a glob-pattern allowlist file (bash case globbing).
#
#   is_allowlisted <value> <allowlist> [<domain>]
#
# No <domain>: every non-comment row is a candidate. This is the form the single-domain
# files use (ssh-allowlist.txt at -011, webfetch-allowlist.txt at -013), and it returns
# the verdicts the loop this function replaced returned: a scope directive begins with
# `#`, so it is a comment here exactly as it always was.
#
# <domain> given (`host` at -004, `gh-api-path` at -007): egress-allowlist.txt serves two
# match domains, and a row is a candidate only in its own. The allowlist's header states
# the grammar; this function applies it:
#   * `# egress-scope: host` / `# egress-scope: gh-api-path` declares the domain of the
#     ONE row on the line immediately below it. Any other line in that position (blank,
#     comment, another directive) discards it, so a scope never carries onto a later row.
#   * A directive naming any other value makes that row match NOWHERE — fail closed.
#   * A row with no directive above it is a candidate in BOTH domains: the pre-change
#     behaviour, so an operator row written before directives existed keeps its grant.
#   * At `gh-api-path`, a pattern whose FIRST path segment carries a glob character is
#     never a candidate, declared or not. A host wildcard reaches a path only by
#     absorbing the whole front of it, and a query string lets any write end in
#     host-shaped text (`issues?x=a.github.com`), so a leading glob is the one shape
#     that must never grant a gh api write.
is_allowlisted() {
  local value="$1"
  local allowlist="$2"
  local domain="${3:-}"
  [ -f "$allowlist" ] || return 1
  local pattern pending="" scope first_seg
  while IFS= read -r pattern || [ -n "$pattern" ]; do
    scope="$pending"
    pending=""
    case "$pattern" in
      "$EGRESS_SCOPE_DIRECTIVE"*)
        pending="${pattern#"$EGRESS_SCOPE_DIRECTIVE"}"
        pending="${pending#"${pending%%[![:space:]]*}"}"
        pending="${pending%"${pending##*[![:space:]]}"}"
        case "$pending" in
          host|gh-api-path) ;;
          *) pending="invalid" ;;
        esac
        continue
        ;;
      ''|'#'*) continue;;
    esac
    if [ -n "$domain" ]; then
      if [ -n "$scope" ] && [ "$scope" != "$domain" ]; then
        continue
      fi
      if [ "$domain" = "gh-api-path" ]; then
        first_seg="${pattern#/}"
        first_seg="${first_seg%%/*}"
        case "$first_seg" in
          *'*'*|*'?'*|*'['*) continue ;;
        esac
      fi
    fi
    # shellcheck disable=SC2254
    case "$value" in
      $pattern) return 0;;
    esac
  done < "$allowlist"
  return 1
}

# Extract host from a URL (scheme://host/... → host)
extract_host() {
  "$PRINTF" '%s' "$1" | "$GREP" -oE '^https?://[^/:]+' | "$GREP" -oE '[^/:]+$' || "$PRINTF" ''
}

# sha256 digest for log evidence (avoids logging raw secret material)
digest() {
  "$PRINTF" '%s' "$1" | /usr/bin/shasum -a 256 | "$GREP" -oE '^[a-f0-9]+' | /usr/bin/head -c 16
}

# ==========================================================================
# BLOCK-EGRESS-007 — quote-aware, segment-first command scanner
# ==========================================================================
#
# WHY THE SINGLE-ERE MATCH-THEN-EXTRACT STRUCTURE IS REPLACED RATHER THAN PATCHED.
#
# -007 used to gate on ANCHOR_PREFIX_BASH and then extract the path with
# `grep -oE 'gh[[:space:]]+api[[:space:]]+[^[:space:];&|]+' | head -1`. That
# structure failed on the same three axes BLOCK-DESTRUCTIVE-022 recorded when it
# abandoned single-ERE matching for the interpreter arm:
#
#   (a) QUOTE. The extracted token kept its surrounding quote characters and was
#       glob-matched against unquoted allowlist patterns, so a path that IS
#       allowlisted was DENIED whenever it was quoted — the conventional, and
#       often necessary, spelling. An operator reading the allowlist saw the
#       permission present, the hook denied anyway, and the natural remediation
#       (add another entry) could not fix it.
#   (b) COMMAND POSITION. The anchor admitted only start-of-string or `[;&|]`, so
#       `gh api` reached from any OTHER command position was never matched and
#       passed unadjudicated. Eleven such positions were measured, not one: `do`,
#       `then`, `else`, an `if` condition, a subshell, a command substitution,
#       backticks, `xargs`, and a leading `VAR=x` assignment prefix. This half
#       fails OPEN and is the security-relevant one.
#   (c) FIRST-MATCH TRUNCATION. `head -1` evaluated only the first invocation, so
#       a second write hid behind an allowlisted first one.
#
# A fourth axis is specific to this rule: the extraction took the first token
# after `api` as the path, so `gh api -X POST <path>` — the repo's own dominant
# documented spelling — extracted `-X` as the path and denied. Axes (a) and (b)
# were masking each other: the anchor usually failed first, so fixing either one
# alone makes the other start firing.
#
# `head -1` is removed by REPLACING the extraction, never by looping it. Looping
# the grep was measured to convert a legitimate issue-comment post whose body
# QUOTES a `gh api` write into a DENY, and this pipeline's own artifacts quote
# such commands constantly — so the naive removal is a worse defect than the one
# it fixes. Quote handling is therefore structural (the scanner consumes quote
# marks during tokenization) rather than a strip applied to an extracted token.
#
# ANCHOR_PREFIX_BASH is NOT modified, and -007 no longer reads it. Rules -001..-006
# and -008..-011 keep it: their defect class is not under test here, and the
# constant is read by three hooks and asserted in two governance documents, so
# widening it would reach far beyond this rule.
#
# Bash 3.2-safe throughout (macOS system bash): parameter expansion and `case`, with a
# subprocess inside the scanner only for a long piece — one tr, sed or awk pass that
# keeps its cost linear (see EGRESS_LINEAR_MIN), each with a fallback — and the segment
# loop runs in the CURRENT shell (here-string, never a pipeline) so apply_block's exit 2
# propagates instead of dying in a subshell.

# Rollout phase for -007's WIDENING classes, per progressive-rollout-convention.md.
#   shadow  — evaluate, log `would-fire`, take NO action, surface nothing
#   warn    — evaluate, log, emit a stderr notice, still allow
#   enforce — apply the deny
# Deliberately ONE line to advance, so the Stage-9 GO gate can ratify straight to
# `enforce` without a code redesign. Advance one rung at a time; retreat is the
# same single edit. The phase governs WIDENINGS only. A write is classified by the
# command position the shell resolves it to, not by how that position is spelled:
# the first counted invocation at the head of a segment the replaced anchor admitted,
# with an explicit write method, enforces from day one in every spelling the rule
# resolves. The REPAIRS — quote handling, the flag walk, `--`, the respelling repairs —
# are not gated by this either, and none of them can allow a case the shipped hook
# refuses. Every other position is a widening and follows this phase.
#
# This is deliberately NOT the shared `.claude/hooks/.mode` dial. That file is read
# by every mode-capable hook in the bundle, so flipping it to soften a -007
# shakedown would simultaneously soften several unrelated controls. The dial is a
# cohort instrument and this is a per-rule decision.
readonly EGRESS_007_WIDENING_PHASE="shadow"

# Sentinel standing in for a structural character that appeared INSIDE a quoted
# span. Substituting rather than deleting preserves token boundaries, so a quoted
# argument stays ONE token instead of silently fusing with its neighbour.
readonly EGRESS_SENT=$'\001'

# The respelling mark. It stands in front of text the rule reached only through a spelling the
# shell resolves for it — an ANSI-C or locale span, a joined continuation — and rides inside its
# token (it is neither a blank nor a separator) until the mark pass strips it and flags that token
# as respelled. `\001` already means "structure inside quotes", so this is its own character.
readonly EGRESS_RSP=$'\004'

# A `<` or `>` inside a quoted span is content, never a redirection operator, as the shell reads
# it. The scanner carries each as its own stand-in so the redirection strip cannot take a quoted
# word for a redirection, and the stand-ins are put back right after that strip.
readonly EGRESS_QLT=$'\005'
readonly EGRESS_QGT=$'\006'

# Segment-boundary class markers. Segmentation emits one segment per line, each
# prefixed with the class of the separator that OPENED it, so the rollout classifier
# can tell a command position the replaced matcher adjudicated from one it never
# reached. Carrying the class inline keeps segmentation a single flat pass.
readonly EGRESS_BND_OLD=$'\002'   # `;` `&` `|` — the replaced anchor admitted these
readonly EGRESS_BND_NEW=$'\003'   # `(` `)` backtick — it did not

# The linear pass, a bound in characters. On bash 3.2 a global pattern substitution costs more
# than linear time in the text it scans once that text carries a match for the pattern, so the
# scanner's substitutions over a piece of the command — a quoted span, a comment, a token, a line
# or the whole text — could hold this hook past the runtime's command-hook timeout on a large
# command, and a hook that times out does not block. A piece of at least this many
# characters is therefore rewritten first by one pass of tr, sed or awk in the C locale, whose
# output equals the substitutions' byte for byte (a `# linear:` line, pinned by AC-E007-X-EQ).
# Where every pattern is one character, the substitutions still run after the pass and find
# nothing left to replace, which costs one scan of the piece; the redirection operators, two
# characters each, skip them instead. A shorter piece costs less than the fork the pass takes,
# so it keeps the substitutions alone, and a pass that fails leaves the piece to them, so the
# text that comes out is the same on every path.
#
# The same holds for a removal (`${t#…}`, `${t%…}` and their long forms) and the first-character
# idiom: on bash 3.2 a removal re-measures the text at every position it tries, so one that has
# to scan far, or that runs once per step of a loop over the text left to scan, costs more than
# linear time. The quote walk and the continuation join therefore read a long text once — the
# walk as pieces split at its quote characters by one awk pass, the join a line at a time with
# its mark-free twin beside it — and each step reads only the piece in front of it; the comment
# and trailing-backslash tests read a long text once as well. A short text keeps the code that
# reads it as before, and the two paths give the same result on every input.
readonly EGRESS_LINEAR_MIN=256

# True when the text $1 is long: at least EGRESS_LINEAR_MIN characters.
egress_long() {
  [ "${#1}" -ge "$EGRESS_LINEAR_MIN" ]
}

# The parts of the array named $1, joined with nothing between them, into EGRESS_J. Every parts
# array here starts with one empty part and only grows, because bash 3.2 under `set -u` refuses to
# expand an empty array; and each is appended to at its end and never read by index, because bash
# 3.2 finds an indexed element by walking the array from its start.
egress_cat() {
  local IFS=
  eval "EGRESS_J=\"\${$1[*]}\""
}

# True when the string ends in an ODD number of backslashes — i.e. a following
# quote character is escaped and is not a terminator. A long string is read once, a
# backslash-delimited field at a time, counting the run of empty fields that ends it;
# a short one is trimmed a backslash at a time, as before.
egress_trailing_backslash_odd() {
  local t="$1" c=0 f=""
  if egress_long "$t"; then  # linear: trail
    while IFS= read -r -d '\' f; do
      if [ -n "$f" ]; then c=1; else c=$(( c + 1 )); fi
    done <<< "$t"
    # The read that ends the loop holds what follows the last backslash, and the here-string's
    # newline: the run reaches the end only when nothing else is there.
    [ "$f" = $'\n' ] || c=0
    [ $(( c % 2 )) -eq 1 ]
    return
  fi
  while [ "${t%\\}" != "$t" ]; do
    t="${t%\\}"
    c=$(( c + 1 ))
  done
  [ $(( c % 2 )) -eq 1 ]
}

# True when the unquoted text `$1` ENDS inside a `#` comment — i.e. its final line
# carries a `#` at the start of a word. Only the final line is examined, because a
# newline closes a comment; and only a `#` that opens a word counts, so `${x#?}`
# and `a#b` are not comment openers.
#
# WHY THIS EXISTS. Everything after a comment opener is inert: it cannot execute
# and it cannot open a quoted span. Without that knowledge the scanner reads an
# apostrophe in a trailing comment as an opening quote, finds no terminator, and
# reports the WHOLE command unparseable — which is how an ordinary
# `grep -r "x" . # don't miss the api docs` reached a gh-api rule. The premise the
# unparseable cause rests on ("such a command cannot execute either") is TRUE for an
# unbalanced quote in command text and FALSE for one in a comment; this is what
# separates the two.
#
# A long text is read once: its final line, a line at a time, and that line's `#`s, a
# `#`-delimited field at a time, each field being the text the short path tests at
# that `#` — so the verdict is the same on every input, in every locale.
egress_comment_open_at_end() {
  local last pre l
  if egress_long "$1"; then  # linear: comment-open
    case "$1" in
      *'#'*) ;;
      *) return 1 ;;
    esac
    last=""
    while IFS= read -r l; do last="$l"; done <<< "$1"
    while IFS= read -r -d '#' pre; do
      case "$pre" in
        ''|*[[:space:]]) return 0 ;;
      esac
    done <<< "$last"
    return 1
  fi
  last="${1##*$'\n'}"
  while : ; do
    case "$last" in
      *'#'*) ;;
      *) return 1 ;;
    esac
    pre="${last%%#*}"
    case "$pre" in
      ''|*[[:space:]]) return 0 ;;
    esac
    last="${last#*#}"
  done
}

# Replace every structural character inside a quoted span with the sentinel and
# drop the quote marks, leaving unquoted text untouched. This is what makes the
# command-position predicate immune to strings: structure inside a literal is no
# longer visible to segmentation, so text that DESCRIBES a command cannot be
# mistaken for one that performs it. Quote type is tracked, so an apostrophe
# inside a double-quoted span (and vice versa) is ordinary content, not a
# delimiter. Returns 1 on an unterminated quote.
#
# Comment text is handled by neutralizing its QUOTE CHARACTERS ONLY, in place. It
# is deliberately NOT stripped: a strip would delete a segment the replaced matcher
# adjudicated — `# x; gh api <path> --method DELETE` denies today and must keep
# denying — so removal would soften a live deny while fixing the desynchronization.
# Neutralizing just the quotes fixes the desynchronization and moves nothing else.
#
# The scanner is a CORE that sets EGRESS_NQ and a wrapper that prints it. The core sets
# EGRESS_NQ on every return — on a quote it cannot close, to the text it neutralized
# before that quote — so the unparseable branch's second reader can call it once per
# piece in the current shell, with no fork. An ANSI-C ($'…') or locale ($"…") span is
# read as the shell reads it (egress_ansic_span): its content changes, never where it
# ends, so no command crosses the parse boundary in either direction.
#
# A long text goes to egress_neutralize_long, the same walk over the text read once as
# pieces; the loop below steps through the text left to scan, which costs more than
# linear time on bash 3.2 (see EGRESS_LINEAR_MIN), and keeps a short text.
egress_neutralize_into() {
  local rest="$1"
  local out="" head body q lp
  if egress_long "$rest"; then
    egress_neutralize_long "$rest" && return 0
    [ "$?" -eq 2 ] || return 1
  fi
  while [ -n "$rest" ]; do
    head="${rest%%[\"\']*}"
    if [ "$head" = "$rest" ]; then
      out="${out}${rest}"
      rest=""
      break
    fi
    out="${out}${head}"
    rest="${rest#"$head"}"
    # The quote just reached may sit inside a `#` comment, where it is inert.
    # Neutralize quote characters through end-of-line and resume scanning at the
    # newline that closes the comment.
    if egress_comment_open_at_end "$head"; then
      case "$rest" in
        *$'\n'*) body="${rest%%$'\n'*}"; rest="${rest#"$body"}" ;;
        *)       body="$rest"; rest="" ;;
      esac
      egress_comment_neutralize
      out="${out}${body}"
      continue
    fi
    q="${rest%"${rest#?}"}"
    rest="${rest#?}"
    case "$rest" in
      *"$q"*) ;;
      *) EGRESS_NQ="$out"; return 1 ;;
    esac
    body="${rest%%"$q"*}"
    rest="${rest#"$body"}"
    # A backslash-escaped quote inside a DOUBLE-quoted span is content, not a
    # terminator; absorb it and keep scanning. Single quotes have no escape
    # mechanism in shell, so this correction applies to double quotes only — an
    # ANSI-C span is decoded in place and keeps the shipped terminator.
    if egress_ansic_span; then :  # respell: ansi-c
    elif [ "$q" = '"' ]; then
      while egress_trailing_backslash_odd "$body"; do
        rest="${rest#?}"
        case "$rest" in
          *"$q"*) ;;
          *) EGRESS_NQ="$out"; return 1 ;;
        esac
        body="${body}${q}${rest%%"$q"*}"
        rest="${rest#"${rest%%"$q"*}"}"
      done
    fi
    rest="${rest#?}"
    egress_span_neutralize
    out="${out}${body}"
  done
  EGRESS_NQ="$out"
  return 0
}

# A comment's text, from the quote character that met it to the end of its line, with its quote
# characters neutralized in place (`body`, in the caller). Shared by both walks.
egress_comment_neutralize() {
  local lp
      if [ "${#body}" -ge "$EGRESS_LINEAR_MIN" ] && lp="$(LC_ALL=C "$TR" '\042\047' '\001\001' <<< "${body}.")"; then body="${lp%.}"; fi  # linear: comment
      body="${body//\"/${EGRESS_SENT}}"
      body="${body//\'/${EGRESS_SENT}}"
  return 0
}

# A quoted span's body (`body`, in the caller), neutralized in place: every structural character to
# the sentinel, a quoted `<` or `>` to its stand-in. Shared by both walks; its lines keep the walk's
# indentation, which the suite's source mutants match.
egress_span_neutralize() {
  local lp
    # The here-string's newline is translated too and comes back as the last byte; `%?` drops it.
    if [ "${#body}" -ge "$EGRESS_LINEAR_MIN" ] && lp="$(LC_ALL=C "$TR" '\040\011\012\073\046\174\050\051\043\140\074\076' '\001\001\001\001\001\001\001\001\001\001\005\006' <<< "$body")"; then body="${lp%?}"; fi  # linear: span
    body="${body// /${EGRESS_SENT}}"
    body="${body//	/${EGRESS_SENT}}"
    body="${body//$'\n'/${EGRESS_SENT}}"
    body="${body//;/${EGRESS_SENT}}"
    body="${body//&/${EGRESS_SENT}}"
    body="${body//|/${EGRESS_SENT}}"
    body="${body//(/${EGRESS_SENT}}"
    body="${body//)/${EGRESS_SENT}}"
    body="${body//\#/${EGRESS_SENT}}"
    body="${body//\`/${EGRESS_SENT}}"
    body="${body//</${EGRESS_QLT}}"  # respell: quoted-ops
    body="${body//>/${EGRESS_QGT}}"  # respell: quoted-ops
  return 0
}

# The walk above, for a long text: the same EGRESS_NQ and status on every input, at a cost linear in
# the text. One awk pass in the C locale reads the text once as a stream of pieces — "T" and a run of
# text within one line, "N" for a newline, "D" and a quote character — and the walk takes each piece
# in turn, gathering a head, a span's body or a comment's text as parts joined once. No step re-reads
# the text left to scan or copies what it has gathered. A quote character is a single byte that never
# sits inside a multibyte character, so the pieces split the text where the loop above splits it in
# every locale; each test the loop applies — the comment test on a head, the ANSI-C reading of a span,
# the escape test on a closing quote — is applied here to the same text, and the escape test to the
# span's last run of text, which holds the backslashes the loop's test counts. Returns 2, having set
# nothing, when the pass cannot run, and the loop above reads the text instead.
egress_neutralize_long() {
  local tk l st=0 nl=0 q="" head="" body="" out="" lastf="" seen=0 rest=""
  local -a HP BP
  tk="$(LC_ALL=C /usr/bin/awk '{ gsub(/["\047]/, "\nD&\nT"); print "T" $0; print "N" }' <<< "$1")" || return 2  # linear: walk
  EGRESS_WO=(""); HP=(""); BP=("")
  while IFS= read -r l; do
    # A newline is applied when the piece after it arrives, so the here-string's own goes unused.
    if [ "$nl" -eq 1 ]; then
      nl=0
      if [ "$st" -eq 0 ]; then
        HP[${#HP[@]}]=$'\n'
      elif [ "$st" -eq 1 ]; then
        BP[${#BP[@]}]=$'\n'
      else
        # The newline that ends a comment: its text is done, and the newline opens the next head.
        egress_cat BP; body="$EGRESS_J"
        egress_comment_neutralize
        EGRESS_WO[${#EGRESS_WO[@]}]="$head"; EGRESS_WO[${#EGRESS_WO[@]}]="$body"
        HP=("" $'\n'); st=0
      fi
    fi
    case "$l" in
      T*)
        if [ "$st" -eq 0 ]; then
          HP[${#HP[@]}]="${l#T}"
        else
          BP[${#BP[@]}]="${l#T}"
          if [ "$st" -eq 1 ]; then lastf="${l#T}"; fi
        fi
        ;;
      N) nl=1 ;;
      D*)
        if [ "$st" -eq 0 ]; then
          egress_cat HP; head="$EGRESS_J"; HP=("")
          if egress_comment_open_at_end "$head"; then
            BP=("" "${l#D}"); st=2
          else
            q="${l#D}"; BP=(""); lastf=""; seen=0; out="$head"; st=1
          fi
        elif [ "$st" -eq 2 ]; then
          BP[${#BP[@]}]="${l#D}"
        elif [ "${l#D}" != "$q" ]; then
          BP[${#BP[@]}]="${l#D}"
        else
          # A closing quote, or an escaped one inside a double-quoted span. The ANSI-C reading
          # sees the body up to the first such quote, as in the loop above. The escape test reads
          # the span's last run of text, which ends the body — the stream puts a run, empty or not,
          # after every quote character and newline — and holds every backslash the loop's test
          # would count, a quote character or a newline ending the run. So a body is joined only to
          # be read or closed.
          if [ "$seen" -eq 0 ]; then
            seen=1
            egress_cat BP; body="$EGRESS_J"
            if egress_ansic_span; then :  # respell: ansi-c
              egress_span_neutralize
              EGRESS_WO[${#EGRESS_WO[@]}]="$out"; EGRESS_WO[${#EGRESS_WO[@]}]="$body"
              HP=(""); st=0
              continue
            fi
          fi
          if [ "$q" = '"' ] && egress_trailing_backslash_odd "$lastf"; then
            BP[${#BP[@]}]="$q"
            continue
          fi
          egress_cat BP; body="$EGRESS_J"
          egress_span_neutralize
          EGRESS_WO[${#EGRESS_WO[@]}]="$out"; EGRESS_WO[${#EGRESS_WO[@]}]="$body"
          HP=(""); st=0
        fi
        ;;
    esac
  done <<< "$tk"
  egress_cat EGRESS_WO
  if [ "$st" -eq 1 ]; then
    # A quote it cannot close: the text before it, with the head as the walk had it then.
    if [ "$seen" -eq 0 ]; then EGRESS_NQ="${EGRESS_J}${head}"; else EGRESS_NQ="${EGRESS_J}${out}"; fi
    return 1
  fi
  if [ "$st" -eq 2 ]; then
    l="$EGRESS_J"
    egress_cat BP; body="$EGRESS_J"
    egress_comment_neutralize
    EGRESS_NQ="${l}${head}${body}"
    return 0
  fi
  l="$EGRESS_J"
  egress_cat HP
  EGRESS_NQ="${l}${EGRESS_J}"
  return 0
}

# The scanner as a command: prints the neutralized text, or returns 1 on a quote it cannot close.
egress_neutralize_quoted() {
  egress_neutralize_into "$1" || return 1
  "$PRINTF" '%s' "$EGRESS_NQ"
  return 0
}

# R2 — an ANSI-C ($'…') or a locale ($"…") span, read as the shell reads it. Called by the scanner
# core when it reaches a quote, and reads and edits the core's locals (q, head, body, out, rest).
# It applies only when the unquoted run just consumed — `head`, never `out`, so a quoted `$` before
# a quote stays text — ends in a `$` that is not itself escaped. A locale span drops that `$`,
# leaves the respelling mark, and is then scanned as the double-quoted span it is (returns 1). An
# ANSI-C span keeps the shipped terminator, the next `'`: a body that ends in an odd backslash run
# there is read exactly as before, its `$` kept as text, so the parse boundary does not move;
# otherwise the `$` is dropped, the mark left, and the body decoded (returns 0).
egress_ansic_span() {
  case "$head" in
    *'$') ;;
    *) return 1 ;;
  esac
  if egress_trailing_backslash_odd "${head%\$}"; then return 1; fi
  if [ "$q" = '"' ]; then
    out="${out%\$}${EGRESS_RSP}"
    return 1
  fi
  if egress_trailing_backslash_odd "$body"; then return 1; fi  # respell: ansi-guard
  out="${out%\$}${EGRESS_RSP}"
  egress_ansic_decode "$body"
  body="$EGRESS_AC"
  return 0
}

# Decode the body of an ANSI-C span into EGRESS_AC. The decoded set: \NNN (one to three octal
# digits), \xHH (one or two hex digits), \uHHHH and \UHHHHHHHH when the code point is at most
# U+007F, and \\ \' \" \? \a \b \e \E \f \n \r \t \v. Any other escape stays as written,
# backslash and character. A decoded NUL ends the string, as the shell ends it. Builtins only, and
# no command-derived text ever reaches a format string: a character is produced from a number the
# decoder computed.
egress_ansic_decode() {
  local s="$1" out="" c d n lim v
  while : ; do
    case "$s" in
      *\\*) ;;
      *) out="${out}${s}"; break ;;
    esac
    out="${out}${s%%\\*}"
    s="${s#*\\}"
    c="${s:0:1}"
    v=-1
    case "$c" in
      [01234567])
        d=""; n=0
        while [ "$n" -lt 3 ]; do
          case "${s:$n:1}" in
            [01234567]) d="${d}${s:$n:1}"; n=$(( n + 1 )) ;;
            *) break ;;
          esac
        done
        v=$(( 8#$d & 255 ))
        s="${s:$n}"
        ;;
      x|u|U)
        case "$c" in x) lim=2 ;; u) lim=4 ;; *) lim=8 ;; esac
        d=""; n=1
        while [ "$n" -le "$lim" ]; do
          case "${s:$n:1}" in
            [0123456789abcdefABCDEF]) d="${d}${s:$n:1}"; n=$(( n + 1 )) ;;
            *) break ;;
          esac
        done
        if [ -z "$d" ]; then
          out="${out}\\"
          continue
        fi
        v=$(( 16#$d ))
        if [ "$c" != x ] && [ "$v" -gt 127 ]; then
          out="${out}\\${s:0:$n}"
          s="${s:$n}"
          continue
        fi
        s="${s:$n}"
        ;;
      '\') out="${out}\\"; s="${s:1}"; continue ;;
      "'") out="${out}'"; s="${s:1}"; continue ;;
      '"') out="${out}\""; s="${s:1}"; continue ;;
      '?') out="${out}?"; s="${s:1}"; continue ;;
      a) out="${out}"$'\a'; s="${s:1}"; continue ;;
      b) out="${out}"$'\b'; s="${s:1}"; continue ;;
      e|E) out="${out}"$'\033'; s="${s:1}"; continue ;;
      f) out="${out}"$'\f'; s="${s:1}"; continue ;;
      n) out="${out}"$'\n'; s="${s:1}"; continue ;;
      r) out="${out}"$'\r'; s="${s:1}"; continue ;;
      t) out="${out}"$'\t'; s="${s:1}"; continue ;;
      v) out="${out}"$'\v'; s="${s:1}"; continue ;;
      *) out="${out}\\"; continue ;;
    esac
    if [ "$v" -eq 0 ]; then break; fi
    builtin printf -v d '%o' "$v"
    builtin printf -v c "\\${d}"
    out="${out}${c}"
  done
  EGRESS_AC="$out"
  return 0
}

# Reachability test for the `unparseable` cause, run on the RAW command because by
# definition the scanner could not normalize it. True when the command carries a
# `gh` token immediately followed by an `api` token, at a command position the
# REPLACED matcher could have reached: the start of the command, or immediately
# after `;` `&` `|` or a newline, with an optional path prefix on the `gh` token.
#
# TWO INDEPENDENT SUBSTRING TESTS ARE NOT THIS TEST, and the difference is the whole
# point. `*gh*` plus `*api*` is satisfied by `grep -r "highlight" . # ... api docs`,
# which is not a gh-api invocation in any sense; scoping the class by adjacency and
# command position is what keeps a rule about `gh api` writes out of the business of
# ordinary commands.
#
# The position set is deliberately no WIDER than the anchor it models. This cause
# denies from day one (it is not a widening), so firing it at a position the old
# matcher never adjudicated would introduce an un-laddered deny — the exact error
# the rollout classifier exists to prevent. A write reached from a subshell, a
# command substitution or behind a wrapper is therefore NOT covered here; those
# positions carry no old deny to preserve, and a command that cannot be parsed
# cannot execute, so nothing is lost by allowing them.
egress_old_reachable_gh_api() {
  local rest="$1"
  local pre seg after first=1
  while : ; do
    case "$rest" in
      *gh[[:space:]]*) ;;
      *) return 1 ;;
    esac
    pre="${rest%%gh[[:space:]]*}"
    rest="${rest#"$pre"}"
    after="${rest#gh}"
    after="${after#"${after%%[![:space:]]*}"}"
    case "$after" in
      api|api[[:space:]]*)
        # Drop an absolute- or relative-path prefix attached to the verb, then any
        # run of BLANKS — never the newline, which is itself a command position
        # because the replaced matcher's anchor was line-oriented.
        seg="${pre##*[[:space:];&|]}"
        case "$seg" in
          ''|*/)
            pre="${pre%"$seg"}"
            pre="${pre%"${pre##*[![:blank:]]}"}"
            case "$pre" in
              *';'|*'&'|*'|'|*$'\n') return 0 ;;
              '') [ "$first" -eq 1 ] && return 0 ;;
            esac
            ;;
        esac
        ;;
    esac
    first=0
    rest="${rest#gh}"
  done
}

# ==========================================================================
# BLOCK-EGRESS-007 — respelled spellings, read as the shell resolves them
# ==========================================================================
#
# A shell resolves several spellings to the command word, subcommand or flag it would read
# plainly, and a write reached through one is the same write: a redirection word is no argv word,
# wherever it stands (R5); a backslash-escaped, brace-expanded or letter-case-variant command word
# names the same program (R4); an ANSI-C or locale span is a quoted word (R2, in the scanner); a
# backslash-newline is removed before any word is read (R3); and gh's flag parser reads a method or
# field flag written attached or clustered (the short-flag reader in the operand walk). Each helper
# below is one of those transformations, and each enters the rule through ONE line carrying a
# trailing `# respell: <name>` mark, so the suite's reverse mutants take one repair out at a time.
#
# The rung a respelled write takes is decided by the position the shell resolves it to, never by
# its spelling: a write at the head of a segment the replaced anchor admitted is refused from day
# one in every spelling the rule resolves, and every other position is a widening. An invocation
# the rule resolves only through a respelling never advances the first-invocation counter; it
# counts on its own, so a respelled read early in a command cannot move a later plain write out of
# the day-one refusal, and every verdict the shipped hook gave an invocation it could already
# resolve is kept.
#
# Not resolved, and declared rather than implied: a command word produced by an expansion these
# helpers do not perform (zsh's `=cmd`, a pathname pattern, a nested, sequence, escape-bearing or
# all-empty brace group, an ANSI-C escape outside the decoded set), a redirection written against
# the word before it, a method value that is itself escaped or brace-expanded, a continuation that
# leaves a prefix command's option argument or operand at the head of a line that also holds the
# verb, and arguments that arrive on standard input.

readonly EGRESS_UC='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
readonly EGRESS_LC='abcdefghijklmnopqrstuvwxyz'

# R4 (a) — a word holding exactly one brace group pre{w1,…,wn}post, with n of at least two, no
# nested group, no `..` sequence, and no backslash, `$`, slash or quoted structure anywhere in it,
# expands to its non-empty words. Sets EGRESS_RV, EGRESS_RVN and EGRESS_RVCH; returns 1 for any
# other word, and for a group whose every word is empty.
egress_brace_words() {
  local w="$1" pre rest mid post alt k=0 last=0
  case "$w" in *'{'*','*'}'*) ;; *) return 1 ;; esac
  case "$w" in *\\*|*'$'*|*/*|*..*|*"${EGRESS_SENT}"*) return 1 ;; esac
  pre="${w%%\{*}"
  rest="${w#*\{}"
  mid="${rest%%\}*}"
  post="${rest#*\}}"
  case "${pre}${mid}${post}" in *'{'*|*'}'*) return 1 ;; esac
  case "$mid" in *,*) ;; *) return 1 ;; esac
  EGRESS_BW=()
  while [ "$last" -eq 0 ]; do
    case "$mid" in
      *,*) alt="${mid%%,*}"; mid="${mid#*,}" ;;
      *) alt="$mid"; last=1 ;;
    esac
    if [ -n "${pre}${alt}${post}" ]; then
      EGRESS_BW[$k]="${pre}${alt}${post}"
      k=$(( k + 1 ))
    fi
  done
  [ "$k" -gt 0 ] || return 1
  EGRESS_RV=( "${EGRESS_BW[@]}" )
  EGRESS_RVN="$k"
  EGRESS_RVCH=1
  return 0
}

# R4 (b) — each `\c` in a word becomes `c`, in one left-to-right pass, as quote removal does. The
# scanner has already dropped quote marks, so a backslash that sat inside a quoted span is read
# here too: such a word reads as its escaped twin, stricter and never looser.
egress_unescape_rv() {
  local j=0 s out
  while [ "$j" -lt "$EGRESS_RVN" ]; do
    s="${EGRESS_RV[$j]}"
    case "$s" in
      *\\*)
        out=""
        while : ; do
          case "$s" in
            *\\*) ;;
            *) out="${out}${s}"; break ;;
          esac
          out="${out}${s%%\\*}"
          s="${s#*\\}"
          out="${out}${s:0:1}"
          s="${s:1}"
        done
        EGRESS_RV[$j]="$out"
        EGRESS_RVCH=1
        ;;
    esac
    j=$(( j + 1 ))
  done
  return 0
}

# R4 (c) — a command word's basename of at most seven characters that holds an upper-case ASCII
# letter is folded to lower case: on a case-insensitive volume `GH`, `ENV` and `Sudo` name gh, env
# and sudo. Letters are listed, never a range, because a bracket range follows the locale's
# collation. The subcommand is never folded: gh rejects `API`.
egress_fold_rv() {
  local w dir="" base out="" c p i=0
  [ "$EGRESS_RVN" -ge 1 ] || return 0
  w="${EGRESS_RV[0]}"
  case "$w" in
    */*) dir="${w%/*}/"; base="${w##*/}" ;;
    *) base="$w" ;;
  esac
  [ "${#base}" -le 7 ] || return 0
  case "$base" in
    *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]*) ;;
    *) return 0 ;;
  esac
  while [ "$i" -lt "${#base}" ]; do
    c="${base:$i:1}"
    case "$c" in
      [ABCDEFGHIJKLMNOPQRSTUVWXYZ]) p="${EGRESS_UC%%"$c"*}"; c="${EGRESS_LC:${#p}:1}" ;;
    esac
    out="${out}${c}"
    i=$(( i + 1 ))
  done
  EGRESS_RV[0]="${dir}${out}"
  EGRESS_RVCH=1
  EGRESS_RVFOLD=1
  return 0
}

# R4 — the command-word normalization: what the shell makes of one word before it looks the word
# up. EGRESS_RV holds the resulting words (EGRESS_RVN of them); EGRESS_RVCH is 1 when a step changed
# the word, EGRESS_RVFOLD when the case step did. $2 names the steps: `abc` for a command word, `ab`
# for the subcommand.
egress_respell_word() {
  EGRESS_RV=( "$1" ); EGRESS_RVN=1; EGRESS_RVCH=0; EGRESS_RVFOLD=0
  egress_brace_words "$1" || true  # respell: brace
  egress_unescape_rv  # respell: escape
  case "$2" in *c*) egress_fold_rv ;; esac  # respell: fold
  return 0
}

# The normalization applied in place to the token at index $1 (steps $2): a changed token is written
# back and flagged in egress_tflag, and a brace group's words are spliced in, each flagged. Sets
# egress_cfold.
egress_norm_at() {
  local i="$1" n k j
  egress_respell_word "${egress_toks[$i]}" "$2"
  egress_cfold="$EGRESS_RVFOLD"
  [ "$EGRESS_RVCH" -eq 1 ] || return 0
  if [ "$EGRESS_RVN" -eq 1 ]; then
    egress_toks[$i]="${EGRESS_RV[0]}"
    egress_tflag[$i]=1
    return 0
  fi
  n="${#egress_toks[@]}"
  EGRESS_NT=(); EGRESS_NF=(); k=0; j=0
  while [ "$j" -lt "$i" ]; do
    EGRESS_NT[$k]="${egress_toks[$j]}"; EGRESS_NF[$k]="${egress_tflag[$j]:-0}"
    k=$(( k + 1 )); j=$(( j + 1 ))
  done
  j=0
  while [ "$j" -lt "$EGRESS_RVN" ]; do
    EGRESS_NT[$k]="${EGRESS_RV[$j]}"; EGRESS_NF[$k]=1
    k=$(( k + 1 )); j=$(( j + 1 ))
  done
  j=$(( i + 1 ))
  while [ "$j" -lt "$n" ]; do
    EGRESS_NT[$k]="${egress_toks[$j]}"; EGRESS_NF[$k]="${egress_tflag[$j]:-0}"
    k=$(( k + 1 )); j=$(( j + 1 ))
  done
  egress_toks=( "${EGRESS_NT[@]}" )
  egress_tflag=( "${EGRESS_NF[@]}" )
  return 0
}

# The look-ahead's test in a respelling: the token at $1 normalizes to words whose first has the
# basename `gh` and is followed by `api` — the next word of its own brace group, or the next token
# normalized without the case step. A plain pair is the shipped test's, not this one's. On a hit
# both words are written back, normalized and flagged.
egress_la_respelled() {
  local i="$1" g
  egress_respell_word "${egress_toks[$i]}" abc
  [ "$EGRESS_RVN" -ge 1 ] || return 1
  [ "${EGRESS_RV[0]##*/}" = gh ] || return 1
  if [ "$EGRESS_RVN" -ge 2 ]; then
    [ "${EGRESS_RV[1]}" = api ] || return 1
    egress_norm_at "$i" abc
    return 0
  fi
  g="$EGRESS_RVCH"
  egress_respell_word "${egress_toks[$(( i + 1 ))]}" ab
  [ "$EGRESS_RVN" -ge 1 ] || return 1
  [ "${EGRESS_RV[0]}" = api ] || return 1
  [ "$g" -eq 1 ] || [ "$EGRESS_RVCH" -eq 1 ] || return 1
  egress_norm_at "$i" abc
  egress_norm_at "$(( i + 1 ))" ab
  return 0
}

# R6 — the mark pass, right after a segment is tokenized: strip every respelling mark from
# egress_toks and flag each token that carried one in egress_tflag; a token that was only the mark
# is dropped and its flag moves to the next token. Returns 1 when no token is left.
egress_strip_marks() {
  local i=0 n="${#egress_toks[@]}" k=0 t carry=0 lp
  egress_tflag=()
  case "${egress_toks[*]}" in
    *"${EGRESS_RSP}"*) ;;
    *) return 0 ;;
  esac
  EGRESS_NT=(); EGRESS_NF=()
  while [ "$i" -lt "$n" ]; do
    t="${egress_toks[$i]}"
    i=$(( i + 1 ))
    case "$t" in
      *"${EGRESS_RSP}"*)
        if [ "${#t}" -ge "$EGRESS_LINEAR_MIN" ] && lp="$(LC_ALL=C "$TR" -d '\004' <<< "${t}.")"; then t="${lp%.}"; fi  # linear: mark
        t="${t//${EGRESS_RSP}/}"
        if [ -z "$t" ]; then carry=1; continue; fi
        EGRESS_NT[$k]="$t"; EGRESS_NF[$k]=1
        ;;
      *)
        EGRESS_NT[$k]="$t"; EGRESS_NF[$k]="$carry"
        ;;
    esac
    carry=0
    k=$(( k + 1 ))
  done
  [ "$k" -gt 0 ] || return 1
  egress_toks=( "${EGRESS_NT[@]}" )
  egress_tflag=( "${EGRESS_NF[@]}" )
  return 0
}

# Is the word $1 a redirection? An optional descriptor — a number, or {name} — then an unquoted `<`
# or `>`. The protected forms carry the sentinel in place of the `&` of `>&` and `<&` and the `|` of
# `>|`, and lead with it for `&>` and `&>>`; a quoted `<` or `>` is a stand-in here and never
# matches. EGRESS_RDR_OP is 1 when the word is the operator alone, so its operand is the next word.
egress_is_redirection() {
  local r="$1" nm
  EGRESS_RDR_OP=0
  r="${r#"${r%%[!0123456789]*}"}"
  case "$r" in
    '{'*)
      nm="${r%%\}*}"
      nm="${nm#\{}"
      case "$nm" in ''|[!A-Za-z_]*|*[!A-Za-z0-9_]*) return 1 ;; esac
      case "$r" in *'}'*) r="${r#*\}}" ;; *) return 1 ;; esac
      ;;
  esac
  case "$r" in
    '<'*|'>'*|"${EGRESS_SENT}>"*) ;;
    *) return 1 ;;
  esac
  case "$r" in
    '<'|'>'|'>>'|'<>'|'<<'|'<<-'|'<<<'|">${EGRESS_SENT}"|"<${EGRESS_SENT}"|"${EGRESS_SENT}>"|"${EGRESS_SENT}>>")
      EGRESS_RDR_OP=1
      ;;
  esac
  return 0
}

# R5 — the redirection strip: every redirection word leaves egress_toks, and so does the operand of
# an operator written alone, wherever it stands in the segment, because none of them is an argv
# word. The token after a removal is flagged. Returns 1 when no token is left.
egress_strip_redirections() {
  local i=0 n="${#egress_toks[@]}" k=0 fl=0
  case "${egress_toks[*]}" in
    *'<'*|*'>'*) ;;
    *) return 0 ;;
  esac
  EGRESS_NT=(); EGRESS_NF=()
  while [ "$i" -lt "$n" ]; do
    if egress_is_redirection "${egress_toks[$i]}"; then
      i=$(( i + 1 + EGRESS_RDR_OP ))
      fl=1
      continue
    fi
    EGRESS_NT[$k]="${egress_toks[$i]}"
    if [ "$fl" -eq 1 ]; then EGRESS_NF[$k]=1; else EGRESS_NF[$k]="${egress_tflag[$i]:-0}"; fi
    fl=0
    k=$(( k + 1 ))
    i=$(( i + 1 ))
  done
  [ "$k" -gt 0 ] || return 1
  egress_toks=( "${EGRESS_NT[@]}" )
  egress_tflag=( "${EGRESS_NF[@]}" )
  return 0
}

# Put the quoted-operator stand-ins back once the redirection strip has run, so a path, a field or a
# logged value carries the characters the command wrote.
egress_restore_quoted_ops() {
  local i=0 n="${#egress_toks[@]}" lp
  case "${egress_toks[*]}" in
    *"${EGRESS_QLT}"*|*"${EGRESS_QGT}"*) ;;
    *) return 0 ;;
  esac
  while [ "$i" -lt "$n" ]; do
    if [ "${#egress_toks[$i]}" -ge "$EGRESS_LINEAR_MIN" ] && lp="$(LC_ALL=C "$TR" '\005\006' '\074\076' <<< "${egress_toks[$i]}.")"; then egress_toks[$i]="${lp%.}"; fi  # linear: stand-in
    egress_toks[$i]="${egress_toks[$i]//${EGRESS_QLT}/<}"
    egress_toks[$i]="${egress_toks[$i]//${EGRESS_QGT}/>}"
    i=$(( i + 1 ))
  done
  return 0
}

# R5's operator protection, shared by both adjudication gates: the `&` of `>&`, `<&` and `&>` (so
# `&>>` too) and the `|` of `>|` become the sentinel before segmentation, so a redirection operator
# is never read as a separator. Sets EGRESS_PRO.
egress_protect_redirect_ops() {
  local s="$1" lp
  # On a long text the sed pass makes all four substitutions, in their order, so they are skipped.
  if [ "${#s}" -ge "$EGRESS_LINEAR_MIN" ] && lp="$(LC_ALL=C /usr/bin/sed -e "s/>&/>${EGRESS_SENT}/g" -e "s/<&/<${EGRESS_SENT}/g" -e "s/&>/${EGRESS_SENT}>/g" -e "s/>|/>${EGRESS_SENT}/g" <<< "${s}.")"; then  # linear: redirect-ops
    s="${lp%.}"
  else
    s="${s//>&/>${EGRESS_SENT}}"
    s="${s//<&/<${EGRESS_SENT}}"
    s="${s//&>/${EGRESS_SENT}>}"  # respell: redirect-ampgt
    s="${s//>|/>${EGRESS_SENT}}"
  fi
  EGRESS_PRO="$s"
  return 0
}

# R3's keep rule: the physical line $1 holds an adjacent pair whose first word's basename is gh once
# normalized and whose second word is api, and its first word is neither api nor a dash-led word
# without a slash. Such a line earns a verdict on its own — the shipped hook reads it as a fresh
# command start — and a join would turn it into a prefix position. A line that opens with api, or
# with a dash-led word, cannot resolve alone, so joining it takes nothing from it. The join passes
# the line's mark-free twin, so the mark removal below finds nothing to remove.
egress_keep_line() {
  local l="${1//${EGRESS_RSP}/}" i=0 n w2 first
  case "$l" in *[![:space:]]*) ;; *) return 1 ;; esac
  set -f
  # shellcheck disable=SC2206
  EGRESS_KW=( $l )
  set +f
  n="${#EGRESS_KW[@]}"
  first="${EGRESS_KW[0]}"
  case "$first" in
    api) return 1 ;;
    -*) case "$first" in */*) ;; *) return 1 ;; esac ;;
  esac
  while [ "$i" -lt "$n" ]; do
    egress_respell_word "${EGRESS_KW[$i]}" abc
    if [ "$EGRESS_RVN" -ge 1 ] && [ "${EGRESS_RV[0]##*/}" = gh ]; then
      w2=""
      if [ "$EGRESS_RVN" -ge 2 ]; then
        w2="${EGRESS_RV[1]}"
      elif [ $(( i + 1 )) -lt "$n" ]; then
        egress_respell_word "${EGRESS_KW[$(( i + 1 ))]}" ab
        w2="${EGRESS_RV[0]:-}"
      fi
      if [ "$w2" = api ]; then return 0; fi
    fi
    i=$(( i + 1 ))
  done
  return 1
}

# egress_norm with every respelling mark removed, into EGRESS_MFT: the whole text is rewritten once —
# by one tr pass when it is long — and the join reads it a line at a time beside egress_norm. A text
# with no mark is its own twin.
egress_mark_free_text() {
  local s lp
  case "$egress_norm" in
    *"${EGRESS_RSP}"*) ;;
    *) EGRESS_MFT="$egress_norm"; return 0 ;;
  esac
  s="$egress_norm"
  if [ "${#s}" -ge "$EGRESS_LINEAR_MIN" ] && lp="$(LC_ALL=C "$TR" -d '\004' <<< "${s}.")"; then s="${lp%.}"; fi  # linear: mark-free
  s="${s//${EGRESS_RSP}/}"
  EGRESS_MFT="$s"
  return 0
}

# The state of the logical line the join is building, once physical line $1 (mark-free twin $2) has
# joined it ($3 = joined) or opened it ($3 = fresh): EGRESS_JODD is 1 when the line ends in an odd run
# of backslashes, EGRESS_JCOPEN is 1 when a `#` comment is open at its end, and EGRESS_JOP (with its
# last part, EGRESS_JOPL) holds its text after its last `#`.
#
# Each is what the join tested on the line it had grown, computed from the line just added. The
# grown line ends in the physical line's text after its leading blanks, behind a respelling mark, so
# its run of trailing backslashes is that line's. Its `#`s before this line were tested when the line
# before joined, and none opened a comment, or that line would not have joined; so only this line's
# `#`s are new, each tested on the same text the comment test reads there — the first one's reaching
# back through the open text of the lines before it, which is gathered as parts and joined once.
egress_join_state() {
  local pre first=1
  if egress_trailing_backslash_odd "$1"; then EGRESS_JODD=1; else EGRESS_JODD=0; fi
  if [ "$3" = fresh ]; then
    EGRESS_JOP=(""); EGRESS_JOPL=""
  else
    EGRESS_JOPL="${EGRESS_JOPL%\\}"
  fi
  EGRESS_JCOPEN=0
  case "$2" in
    *'#'*) ;;
    *)
      if [ "$3" = joined ]; then EGRESS_JOP[${#EGRESS_JOP[@]}]="$EGRESS_JOPL"; fi
      EGRESS_JOPL="$2"
      return 0
      ;;
  esac
  pre=""
  while IFS= read -r -d '#' pre; do
    if [ "$first" -eq 1 ]; then
      first=0
      if [ "$3" = joined ]; then
        EGRESS_JOP[${#EGRESS_JOP[@]}]="$EGRESS_JOPL"
        egress_cat EGRESS_JOP
        pre="${EGRESS_J}${pre}"
      fi
    fi
    case "$pre" in
      ''|*[[:space:]]) EGRESS_JCOPEN=1 ;;
    esac
  done <<< "$2"
  # What follows the last `#`, with the here-string's newline, is left in `pre` by the final read.
  EGRESS_JOP=(""); EGRESS_JOPL="${pre%$'\n'}"
  return 0
}

# R3 — the continuation join on the neutralized command in egress_norm: an unquoted backslash-newline
# is removed, as the shell removes it before it reads words, and the respelling mark is left in front
# of the joined line's first non-blank character. Never inside a `#` comment, where a backslash ends
# nothing; never on an even backslash run; and not where the keep rule holds for the line it would
# join. The second reader passes `nokeep`, for a view with every continuation joined.
#
# Linear in the command: the physical lines are read once, a line at a time with their mark-free
# twins beside them, and nothing runs unless the command carries an unquoted backslash-newline. The
# tests the join makes of the line it is building — an odd run of trailing backslashes, a comment
# open at its end — are read from the line just added (egress_join_state), never from the line grown
# so far, and the line is gathered as parts and joined once, so no join re-reads or copies it.
egress_join_continuations() {
  local nxt nxts lead keep last="" started=0
  local -a JC
  case "$egress_norm" in
    *\\$'\n'*) ;;
    *) return 0 ;;
  esac
  egress_mark_free_text
  # EGRESS_JO is joined with a newline between its lines, so it starts empty, not with the empty first
  # part a parts array carries; it holds a line before it is joined.
  EGRESS_JO=(); JC=("")
  while IFS= read -r nxt && IFS= read -r nxts <&3; do
    if [ "$started" -eq 0 ]; then
      started=1; last="$nxt"
      egress_join_state "$nxt" "$nxts" fresh
      continue
    fi
    keep=1
    if [ "$EGRESS_JODD" -eq 1 ] && [ "$EGRESS_JCOPEN" -eq 0 ]; then
      keep=0
      if [ "${1:-}" != nokeep ] && egress_keep_line "$nxts"; then keep=1; fi  # respell: keep
    fi
    if [ "$keep" -eq 1 ]; then
      JC[${#JC[@]}]="$last"; egress_cat JC; EGRESS_JO[${#EGRESS_JO[@]}]="$EGRESS_J"; JC=("")
      last="$nxt"
      egress_join_state "$nxt" "$nxts" fresh
    else
      JC[${#JC[@]}]="${last%\\}"
      lead="${nxt%%[![:blank:]]*}"
      last="${lead}${EGRESS_RSP}${nxt#"$lead"}"
      egress_join_state "$nxt" "$nxts" joined
    fi
  done <<< "$egress_norm" 3<<< "$EGRESS_MFT"
  JC[${#JC[@]}]="$last"; egress_cat JC; EGRESS_JO[${#EGRESS_JO[@]}]="$EGRESS_J"
  egress_join_lines
  return 0
}

# The joined lines back into egress_norm, one newline between each.
egress_join_lines() {
  local IFS=$'\n'
  egress_norm="${EGRESS_JO[*]}"
  return 0
}

# Class 10 — a short-flag word that gh's flag parser reads as a cluster: any run of the boolean -i,
# then one value-taking flag (-X -f -F -H -q -t -p) whose value is the rest of the word with one
# leading `=` dropped, or the next word when nothing is attached. A word that parser would reject is
# stepped over as one token, as before. Reads and advances the operand walk's state.
egress_short_flags() {
  local s="${egress_tok#-}" f v sep=0 hasv=1
  while : ; do
    case "$s" in
      i*) s="${s#i}" ;;
      *) break ;;
    esac
  done
  f="${s:0:1}"
  v="${s:1}"
  case "$f" in
    X|f|F|H|q|t|p) ;;
    *) egress_idx=$(( egress_idx + 1 )); return 0 ;;
  esac
  case "$v" in
    '') sep=1 ;;
    '='?*) v="${v#=}" ;;
  esac
  if [ "$sep" -eq 1 ]; then
    if [ $(( egress_idx + 1 )) -lt "${#egress_toks[@]}" ]; then
      v="${egress_toks[$(( egress_idx + 1 ))]}"
    else
      hasv=0
    fi
  fi
  case "$f" in
    X) if [ "$hasv" -eq 1 ]; then egress_method="$v"; egress_explicit=1; fi ;;
    f|F) egress_implicit=1 ;;
  esac
  egress_idx=$(( egress_idx + 1 + sep ))
  return 0
}

# R9 — the unparseable branch's second reader, joined to the shipped test on one `||` line. A command
# the scanner cannot tokenize is refused when it carries a gh api invocation at a position the
# shipped test reads — the start of the command, or right after `;` `&` `|` or a newline — and the
# shipped test runs first, unchanged, so every refusal it makes stands. This reader finds the same
# invocation in a respelling: in the physical lines, and again with every continuation joined, it
# reads each piece with the walk's own helpers — the quote scanner up to any quote it cannot close,
# the mark pass, the redirection strip, the command-word normalization on the first two words — and
# passes over no keyword, assignment or prefix word, each of which is a widening in the walk where
# this branch has no widening rung. Above the parse cap it locates nothing; the plain spelling there
# is still located by the shipped test.
egress_old_reachable_respelled() {
  local cmd="$1" view v=0 piece lp
  [ "${#cmd}" -le "$EGRESS_007_PARSE_CAP" ] || return 1
  while [ "$v" -lt 2 ]; do
    view="$cmd"
    if [ "$v" -eq 1 ]; then
      case "$view" in
        *\\$'\n'*) ;;
        *) return 1 ;;
      esac
      egress_norm="$view"
      egress_join_continuations nokeep
      view="$egress_norm"
    fi
    egress_protect_redirect_ops "$view"
    view="$EGRESS_PRO"
    if [ "${#view}" -ge "$EGRESS_LINEAR_MIN" ] && lp="$(LC_ALL=C "$TR" '\073\046\174' '\012\012\012' <<< "${view}.")"; then view="${lp%.}"; fi  # linear: view
    view="${view//;/$'\n'}"
    view="${view//&/$'\n'}"
    view="${view//|/$'\n'}"
    while IFS= read -r piece; do
      if egress_piece_is_gh_api "$piece"; then return 0; fi
    done <<< "$view"
    v=$(( v + 1 ))
  done
  return 1
}

# One piece of an untokenizable command: does it open with gh api, in a spelling the walk resolves?
egress_piece_is_gh_api() {
  local p="$1"
  egress_neutralize_into "$p" || true
  p="$EGRESS_NQ"
  case "$p" in *[![:space:]]*) ;; *) return 1 ;; esac
  set -f
  # shellcheck disable=SC2206
  egress_toks=( $p )
  set +f
  egress_strip_marks || return 1
  egress_strip_redirections || return 1
  egress_respell_word "${egress_toks[0]}" abc
  [ "$EGRESS_RVN" -ge 1 ] || return 1
  [ "${EGRESS_RV[0]##*/}" = gh ] || return 1
  if [ "$EGRESS_RVN" -ge 2 ]; then
    [ "${EGRESS_RV[1]}" = api ] || return 1
    return 0
  fi
  [ "${#egress_toks[@]}" -ge 2 ] || return 1
  egress_respell_word "${egress_toks[1]}" ab
  [ "$EGRESS_RVN" -ge 1 ] || return 1
  [ "${EGRESS_RV[0]}" = api ] || return 1
  return 0
}

# Classify a gh-api path operand per the AUTHORITY-PREFIX rule.
#
# An UNEVALUABLE span is a path segment carrying `$`, a backtick, a `{...}` pair,
# or a leading `:name`. The AUTHORITY PREFIX is the first THREE path segments:
# GitHub REST paths are `repos/{owner}/{repo}/...`, `orgs/{org}/...` and
# `users/{user}/...`, so the first three segments are exactly what decides WHICH
# repository a write reaches. The threshold is at least as strict as any path
# pattern's literal prefix: a path pattern must pin the account literally (the
# allowlist header's prefix-anchoring rule), and the account sits inside the first
# three segments.
#
#   unevaluable IN the authority  -> return 1; the caller denies, naming the cause
#   unevaluable BELOW it          -> substitute `*` and adjudicate normally
#
# The second half is sound because every allowlist path pattern is prefix-anchored:
# its literal prefix pins the account, so whatever the variable expands to, the path
# still begins inside an allowlisted account. It is also what keeps a bulk loop over
# issue numbers working.
#
# A blanket deny on any variable-bearing path was rejected on evidence: it would
# deny `repos/<owner>/<repo>/issues/$n`, the exact bulk-write form measured at 152
# invocations in one session. No allowlist entry can ever fix an unresolvable path,
# so a blanket deny pushes the operator toward CLAUDE_HOOK_BYPASS — the outcome a
# security control least wants. Authority-scoping denies exactly the case where the
# hook genuinely cannot know the target repository, and permits the case where it
# provably can.
#
# Expanding the placeholders from the repository remote was rejected outright. `gh`
# resolves `{owner}`/`{repo}` at EXECUTION time from the environment, a default
# repo setting, the cwd's remotes, or a `--repo` flag elsewhere in the same
# command, so a hook resolving from its own view can adjudicate a DIFFERENT
# repository than the command hits — manufacturing an allow for a repository never
# adjudicated. It is also unreachable under this hook's pinned PATH, which is an
# anti-hijack control; `gh` does not live there.
#
# Echoes the normalized path. Returns 1 when the authority is unresolvable.
egress_classify_api_path() {
  local p="$1"
  local lead="" rest seg out="" idx=0 first=1 unevaluable
  case "$p" in
    /*) lead="/"; rest="${p#/}" ;;
    *)  rest="$p" ;;
  esac
  while : ; do
    case "$rest" in
      */*) seg="${rest%%/*}"; rest="${rest#*/}" ;;
      *)   seg="$rest"; rest="" ;;
    esac
    unevaluable=0
    case "$seg" in
      *'$'*|*'`'*) unevaluable=1 ;;
      *'{'*'}'*)   unevaluable=1 ;;
      :?*)         unevaluable=1 ;;
    esac
    if [ "$unevaluable" -eq 1 ]; then
      if [ "$idx" -lt 3 ]; then
        return 1
      fi
      seg="*"
    fi
    if [ "$first" -eq 1 ]; then
      out="$seg"
      first=0
    else
      out="${out}/${seg}"
    fi
    idx=$(( idx + 1 ))
    if [ -z "$rest" ]; then break; fi
  done
  "$PRINTF" '%s%s' "$lead" "$out"
  return 0
}

# Shadow/warn-phase telemetry for a -007 widening: evaluate, record, take no
# action. A shadow rung surfaces nothing to the caller by design — the log IS the
# observation. Carries the CAUSE CLASS as well as the path, because the operator
# reading this log needs to separate `not-allowlisted` (add an allowlist entry)
# from `unresolvable` (spell out the owner and repository); conflating those two
# is precisely the trap this rule was filed about.
#
# A row written for a verb the secondary locator found also carries
# `pos: "look-ahead"`. A row without the key was written for an invocation the head
# walk resolved, as every row written before the key existed was. The key names which
# locator found the verb; it does not say whether the words there are executed, which a
# lexical matcher cannot know, so a look-ahead row is not on its own a reason to add an
# allowlist row.
log_would_fire() {
  local rule_id="$1"
  local phase="$2"
  local cause="$3"
  local path="$4"
  local pos="${5:-}"   # `look-ahead` for a verb the secondary locator found; else empty
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  # `-c` — one entry per LINE, which is what the .jsonl extension claims and what a
  # shakedown reading needs. The older writers in this file emit jq's default
  # pretty form, so their entries span several lines each; that is pre-existing and
  # is not changed here, because their consumers count lines as a growth signal.
  "$JQ" -nc --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg phase "$phase" --arg cause "$cause" --arg path "$path" --arg pos "$pos" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, phase:$phase, reason:"would-fire", cause:$cause, path:$path} + (if $pos == "" then {} else {pos:$pos} end)' \
    >> "$WARN_LOG" 2>/dev/null || true
}

# ---- The `unparseable` refusal record's feature set ----
#
# An `unparseable` refusal has no path, so its evidence is a constant and cannot say
# whether the refusal was right. These helpers record what CAN say it without the
# command: enums, a version number, the parser that judged, and the producing build —
# never command text, offsets, lengths or path fragments. Each prints exactly one value
# and returns 0. That is load-bearing: they run on the way into apply_block, and under
# `set -e` a failing command inside a function ends this hook with status 1, which
# PreToolUse treats as NON-blocking — an enforce-mode deny would be lost. Every fallible
# step therefore sits in a condition or carries a fallback.
readonly EGRESS_007_FEATURES_SCHEMA_VERSION=1
readonly EGRESS_007_PARSE_ORACLE="${BASH:-/bin/bash}"
# Characters. ONE bound for the whole feature path, applied once, because both
# computations read the same caller-sized input: above it neither runs, and both report
# `skipped`. Both are linear in the command, so the cap bounds their cost as well.
readonly EGRESS_007_PARSE_CAP=1048576

# Which parser judges the syntax. The oracle is the running bash, so its version is known
# without a subprocess; were the two ever to differ, the label reads `unknown` rather
# than naming a parser that did not run.
egress_parse_oracle_label() {
  local maj="${BASH_VERSINFO[0]:-}" min="${BASH_VERSINFO[1]:-}"
  case "$maj" in ''|*[!0-9]*) maj="" ;; esac
  case "$min" in ''|*[!0-9]*) min="" ;; esac
  if [ "$EGRESS_007_PARSE_ORACLE" = "${BASH:-}" ] && [ -n "$maj" ] && [ -n "$min" ]; then
    "$PRINTF" 'bash-%s.%s' "$maj" "$min"
  else
    "$PRINTF" 'unknown'
  fi
  return 0
}

# Does the oracle accept the command's syntax? `-n` reads and never executes; `env -i`
# hands the child no inherited BASH_ENV and no exported functions. The command travels
# on stdin (a here-string), never argv, so its size and a leading `-` are inert. Only the
# oracle's own verdicts map to verdict values — exit 0 is `ok`, exit 2 (bash's
# syntax-error status) is `error`. Any other outcome — a failed redirection, a failed
# exec, a signal — is an instrument failure and reads `unavailable`, never `error`: a
# failed run must not read as proof that the refusal was right. The caller applies the
# size cap.
egress_shell_parse() {
  local rc=0
  if [ ! -x "$EGRESS_007_PARSE_ORACLE" ]; then "$PRINTF" 'unavailable'; return 0; fi
  /usr/bin/env -i "$EGRESS_007_PARSE_ORACLE" -n >/dev/null 2>&1 <<<"$1" || rc=$?
  case "$rc" in
    0) "$PRINTF" 'ok' ;;
    2) "$PRINTF" 'error' ;;
    *) "$PRINTF" 'unavailable' ;;
  esac
  return 0
}

# Which heredoc delimiter quoting does the raw command use? A quoted delimiter makes the
# body literal; an unquoted one leaves `$( )` live inside it. `<<<` is a here-string and
# is not counted, and the delimiter WORD is never recorded — only its quoting.
# Approximate by design (a `<<` inside quotes or arithmetic counts too): the oracle, not
# this scan, decides whether a refusal was correct. The caller applies the size cap.
#
# LINEAR in the command's length, so the cap bounds the scan's cost and not only its
# input: two extended-regex searches, byte-wise in the C locale, each stopping at its first
# match. The per-occurrence scan these replace rescanned and re-copied the remainder at
# every operator, which is superlinear under a multibyte locale — tens of seconds on the
# deny path for a well-formed command of 60K characters — and a hook that outlasts its
# timeout does not block.
#
# The two expressions state, operator by operator, the scan that loop was written to
# perform. A maximal run of `<` opens a heredoc only when its length is two more than a
# multiple of three: each `<<<` is a here-string, consumed whole from the left. Then come
# one optional `-` — the `<<-` operator's, only directly after the run — then blanks, then
# the delimiter word, which runs to whitespace or to one of ; & | < > ( ), where the shell's
# own tokenizer ends it. (As bash 3.2 ran the loop's one-bracket terminator set, its word
# did not end at `>`, `(` or `)`, so a syntax error such as `<<(x` read `unquoted`; it reads
# `none` here.) The word is QUOTED when it carries a single quote, a double quote or a
# backslash anywhere, and UNQUOTED when it is non-empty and carries none of them.
readonly EGRESS_007_HEREDOC_QUOTED_ERE='(^|[^<])(<<<)*<<-?[[:blank:]]*[^[:space:];&|<>()]*['"'"'"\]'
readonly EGRESS_007_HEREDOC_UNQUOTED_ERE='(^|[^<])(<<<)*<<(-[[:blank:]]*[^[:space:];&|<>()'"'"'"\]+|[[:blank:]]+[^[:space:];&|<>()'"'"'"\]+|[^-[:space:];&|<>()'"'"'"\][^[:space:];&|<>()'"'"'"\]*)([[:space:];&|<>()]|$)'
# Only the searches' own counts map to a class: `-c -m 1` prints 1 on a match and 0 on
# none, and a search that could not run prints neither, so it reads `unavailable` — never
# a class. The command travels as a here-string, never argv.
egress_heredoc_kind() {
  local q="" u=""
  q="$(LC_ALL=C "$GREP" -c -m 1 -E -e "$EGRESS_007_HEREDOC_QUOTED_ERE" <<<"$1" 2>/dev/null)" || true
  u="$(LC_ALL=C "$GREP" -c -m 1 -E -e "$EGRESS_007_HEREDOC_UNQUOTED_ERE" <<<"$1" 2>/dev/null)" || true
  case "${q}:${u}" in
    1:1) "$PRINTF" 'both' ;;
    1:0) "$PRINTF" 'quoted' ;;
    0:1) "$PRINTF" 'unquoted' ;;
    0:0) "$PRINTF" 'none' ;;
    *)   "$PRINTF" 'unavailable' ;;
  esac
  return 0
}

# The git blob id of the running hook file, first 16 hex; `unknown` when any step fails.
egress_hook_build() {
  local self="${HOOK_DIR}/${0##*/}" n="" h=""
  if [ -r "$self" ]; then
    n="$(/usr/bin/wc -c 2>/dev/null < "$self")" || n=""
    n="${n//[!0-9]/}"
  fi
  if [ -n "$n" ]; then
    h="$({ "$PRINTF" 'blob %s\0' "$n"; "$CAT" "$self"; } 2>/dev/null | /usr/bin/shasum -a 1 2>/dev/null)" || h=""
  fi
  h="${h%% *}"
  case "$h" in
    [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]*)
      "$PRINTF" '%s' "${h:0:16}" ;;
    *) "$PRINTF" 'unknown' ;;
  esac
  return 0
}

# The feature set of a record whose features could not be computed at all: every member
# says so, so the record still carries a defined set beside hook_build.
readonly EGRESS_007_FEATURES_NOT_COMPUTED="{\"schema_version\":${EGRESS_007_FEATURES_SCHEMA_VERSION},\"oracle\":\"unknown\",\"shell_parse\":\"unavailable\",\"heredoc\":\"unavailable\"}"

# The feature object as compact JSON for jq --argjson; empty when it cannot be built, and
# the verdict then records the not-computed set above. The size cap is applied HERE, once,
# to the whole feature path. Each member is checked against its vocabulary before it is
# rendered, so a helper that printed nothing — or anything else — reads `unavailable`.
egress_007_unparseable_features() {
  local cmd="$1" parse="skipped" heredoc="skipped" oracle
  if [ "${#cmd}" -le "$EGRESS_007_PARSE_CAP" ]; then
    parse="$(egress_shell_parse "$cmd")" || parse="unavailable"
    heredoc="$(egress_heredoc_kind "$cmd")" || heredoc="unavailable"
  fi
  case "$parse" in ok|error|skipped|unavailable) ;; *) parse="unavailable" ;; esac
  case "$heredoc" in none|quoted|unquoted|both|skipped|unavailable) ;; *) heredoc="unavailable" ;; esac
  oracle="$(egress_parse_oracle_label)" || oracle="unknown"
  "$JQ" -nc --argjson v "$EGRESS_007_FEATURES_SCHEMA_VERSION" \
    --arg o "$oracle" --arg p "$parse" --arg h "$heredoc" \
    '{schema_version:$v, oracle:$o, shell_parse:$p, heredoc:$h}' 2>/dev/null || true
  return 0
}

# Deny (or shadow-log) one -007 verdict. FOUR causes, each carrying its OWN
# remediation string.
#
# `unresolvable` must NOT offer an allowlist entry. No entry can ever match a path
# whose authority is unresolved, so sending the operator to edit an allowlist that
# already permits the call is the exact defect this rule was filed about,
# reappearing in a new guise. It says: spell the owner and repository out.
egress_007_verdict() {
  local cause="$1"
  local path="$2"
  local widening="$3"
  local features="${4:-}"   # optional feature object — passed by the `unparseable` cause alone
  local pos="${5:-}"        # `look-ahead` when the secondary locator found the verb; else empty
  local reason override

  if [ "$widening" -eq 1 ]; then
    case "$EGRESS_007_WIDENING_PHASE" in
      shadow)
        log_would_fire "BLOCK-EGRESS-007" "shadow" "$cause" "$path" "$pos"
        return 0
        ;;
      warn)
        log_would_fire "BLOCK-EGRESS-007" "warn" "$cause" "$path" "$pos"
        "$PRINTF" '[CLAUDE-HOOK:%s:BLOCK-EGRESS-007] WARN (would-block, rollout=warn, cause=%s): gh api write to %s\n' \
          "$HOOK_NAME" "$cause" "$path" >&2
        return 0
        ;;
    esac
  fi

  case "$cause" in
    unresolvable)
      reason="gh api write to an unresolvable path denied (path: ${path}). The hook sees unexpanded argv, so it cannot resolve the path authority and cannot know which repository this write would reach."
      override="spell out the owner and repository literally — gh resolves them at execution time from state the hook cannot see, so NO allowlist entry can match this path. Or set CLAUDE_HOOK_BYPASS=1"
      ;;
    unparseable)
      reason="gh api write denied: the command carries an unterminated quote and cannot be evaluated."
      override="close the quote — an unbalanced quote outside a comment means the command cannot execute in this form either. Or set CLAUDE_HOOK_BYPASS=1"
      # This class never goes featureless: a set that could not be computed is recorded as
      # not computed, so the record keeps hook_build and cannot be taken, by key, for one
      # written before the set existed.
      [ -n "$features" ] || features="$EGRESS_007_FEATURES_NOT_COMPUTED"
      ;;
    no-path)
      reason="gh api write denied: no API path operand found after 'gh api'."
      override="supply the API path operand, or set CLAUDE_HOOK_BYPASS=1"
      ;;
    *)
      reason="gh api write to non-allowlisted path denied (path: ${path})."
      override="add path to .claude/egress-allowlist.txt via allowlist-add.sh, or set CLAUDE_HOOK_BYPASS=1"
      ;;
  esac
  apply_block "BLOCK-EGRESS-007" "$reason" "$override" "path=${path} cause=${cause}" "$features"
}

# ==========================================================================
# BRANCH BY TOOL NAME
# ==========================================================================

case "$TOOL_NAME" in
  Bash)
    COMMAND="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.command // empty')"
    [ -z "$COMMAND" ] && exit 0

    # --- CANONICALIZE COMMAND POSITIONS (see CMDPOS_AWK above) ---
    # Verify the primitive WORKS before trusting its output: a present-but-empty,
    # truncated or corrupt awk emits an empty string, and every matcher below would then
    # find nothing — the hook would fail OPEN, strictly worse than the gap this closes.
    # Canary: a one-line function body whose canonical form MUST expose the inner command
    # at an anchor position. Mode-gated severity, mirroring this hook's dependency gate:
    # enforce DENIES, warn degrades to the raw command — which is exactly this hook's
    # pre-#5644 behaviour, so warn never loses coverage it already had.
    # Two probes (#8314): the first catches a present-but-empty or truncated copy; the
    # second — a wrapper carrying a separate-argument option before a benign verb, exposed
    # at an anchor only by the walk that reads wrapper grammar — catches a VERSION SKEW, a
    # copy that predates that grammar. The second probe opens with the append form of a
    # prefix assignment (#8314, follow-up pass), so a copy whose walk reads that word as the
    # command word — one that predates the append form — fails it too.
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
      if [ "$LIB_GUARD_MODE" = "enforce" ]; then
        deny_missing_primitive "command-position.awk" "$HOOK_NAME" "$PRINTF"
        exit 2   # caller owns the fail-closed exit — never trust the callee to terminate
      fi
      "$PRINTF" '[CLAUDE-HOOK:%s:PRIMITIVE-MISSING] WARN (degraded, %s=%s): command-position.awk absent or invalid; command-start canonicalization skipped this run (pre-existing anchor positions still enforced).\n' "$HOOK_NAME" "${MODE_FILE##*/}" "$LIB_GUARD_MODE" >&2
      COMMAND_CMDPOS="$COMMAND"
    fi

    # ----- Subprocess credential reads -----

    # BLOCK-EGRESS-001 — cat / head / tail / less / more on ~/.ssh, ~/.aws, ~/.config/gh
    # Absolute-path-aware: also detects /bin/cat ~/.ssh/id_rsa, /usr/bin/head, etc.
    if matches "${ANCHOR_PREFIX_BASH}"'(cat|head|tail|less|more|bat|view)[[:space:]]+([^;&|]*[[:space:]])?(~/\.ssh|~/\.aws|~/\.config/gh|/Users/[^/]+/\.ssh|/Users/[^/]+/\.aws|/Users/[^/]+/\.config/gh|\$HOME/\.ssh|\$HOME/\.aws)'; then
      apply_block "BLOCK-EGRESS-001" \
        "Subprocess read of credential directory (~/.ssh, ~/.aws, ~/.config/gh) denied — exfil risk." \
        "if you truly need these files, use Read via Claude (still blocked by NEW-E Read deny) or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-EGRESS-002 — read of .env / id_rsa / *.pem / *.key files
    # .env variants blocked: bare .env, .env.{local,production,dev,development,staging,test,testing,prod,secrets,secret}
    # Explicit allow: .env.example (common template, non-sensitive)
    # SSH private keys blocked bare (id_rsa), NOT .pub (public key is safe)
    # Absolute-path-aware.
    if matches "${ANCHOR_PREFIX_BASH}"'(cat|head|tail|less|more|bat|view|base64)[[:space:]]+([^;&|]*[[:space:]])?[^[:space:];&|]*(\.env|\.env\.(local|production|dev|development|staging|test|testing|prod|secrets|secret)|/id_rsa|/id_ed25519|/id_ecdsa|\.pem|\.key)([[:space:]]|$)'; then
      apply_block "BLOCK-EGRESS-002" \
        "Subprocess read of secret-like file denied (.env[.local/production/etc], id_rsa, *.pem, *.key)." \
        ".env.example and *.pub are explicitly allowed. Set CLAUDE_HOOK_BYPASS=1 only if intentional"
    fi

    # BLOCK-EGRESS-003 — base64 encoding of credential paths (common exfil wrapper)
    # Absolute-path-aware.
    if matches "${ANCHOR_PREFIX_BASH}"'base64[[:space:]]+([^;&|]*[[:space:]])?(~/\.ssh|~/\.aws|/Users/[^/]+/\.ssh|/Users/[^/]+/\.aws|\$HOME/\.ssh|\$HOME/\.aws)'; then
      apply_block "BLOCK-EGRESS-003" \
        "base64 encoding of credential directory denied (classic exfil preparation)." \
        "set CLAUDE_HOOK_BYPASS=1 if intentional"
    fi

    # ----- Network upload channels -----

    # BLOCK-EGRESS-004 — curl POST / data-upload flags to non-allowlisted host
    # Absolute-path-aware.
    if matches "${ANCHOR_PREFIX_BASH}"'curl[[:space:]]+[^;&|]*(-X[[:space:]]+POST|-X[[:space:]]+PUT|-X[[:space:]]+PATCH|-d[[:space:]]|--data|-F[[:space:]]|-T[[:space:]]|--upload-file|--data-binary|--data-raw|--data-urlencode)'; then
      # Extract target URL
      target_url="$("$PRINTF" '%s' "$COMMAND" | "$GREP" -oE 'https?://[^[:space:]"'"'"';&|]+' | /usr/bin/head -1 || "$PRINTF" '')"
      target_host="$(extract_host "${target_url:-}")"
      if [ -z "$target_host" ] || ! is_allowlisted "$target_host" "$EGRESS_ALLOWLIST" host; then
        apply_block "BLOCK-EGRESS-004" \
          "curl POST/PUT/upload to non-allowlisted host denied (target: ${target_host:-unknown})." \
          "add host to .claude/egress-allowlist.txt via allowlist-add.sh, or set CLAUDE_HOOK_BYPASS=1" \
          "host=${target_host:-unknown} digest=$(digest "${target_url:-}")"
      fi
    fi

    # BLOCK-EGRESS-005 — wget --post-data / --post-file (unconditional)
    # Absolute-path-aware: also detects /opt/homebrew/bin/wget --post-data, etc.
    if matches "${ANCHOR_PREFIX_BASH}"'wget[[:space:]]+[^;&|]*(--post-data|--post-file|--body-data|--body-file)'; then
      apply_block "BLOCK-EGRESS-005" \
        "wget --post-data/--post-file denied (no allowlist for wget uploads)." \
        "use curl (allowlist-governed) or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-EGRESS-006 — gh gist create (unconditional; public-share vector)
    # Absolute-path-aware.
    if matches "${ANCHOR_PREFIX_BASH}"'gh[[:space:]]+gist[[:space:]]+create([[:space:]]|$)'; then
      apply_block "BLOCK-EGRESS-006" \
        "gh gist create denied (public-share vector with no allowlist)." \
        "upload via repo PR/issue (allowlisted) or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-EGRESS-007 — gh api POST/PUT/PATCH/DELETE to non-allowlisted API path
    #
    # Segment-first, quote-aware, every-invocation. See the scanner block above for
    # why the single-ERE structure was replaced rather than patched, and why
    # ANCHOR_PREFIX_BASH is deliberately not read here.
    #
    # Fast-path guard, derived from the transformations it guards rather than from example
    # spellings: the rule resolves a command word through quote removal, ANSI-C decoding,
    # unescaping, the case fold, the brace splice and the continuation join, and every one
    # of those can produce `gh` only from text that, once its quote characters and `$` are
    # removed, holds a `gh` in either letter case or a backslash. A command without either
    # is skipped without scanning, so non-`gh` commands stay as fast as before.
    #
    # The removal is one pass of tr in the C locale, which deletes the same three bytes, and
    # never a pattern substitution over the command: this line runs on every command that
    # reaches the rule, and on bash 3.2 a global substitution of the whole command grows
    # superlinearly once the command carries a character it replaces — the bracket class took
    # a file-sized command past the runtime's hook timeout, after which a PreToolUse hook does
    # not block, and three single-character substitutions grow the same way. tr reads the
    # command from a here-string, so no argument-length limit applies, and a failed pass sends
    # the command to the full scan.
    egress_fast="$COMMAND"
    egress_fq="$(LC_ALL=C "$TR" -d "\"'\$" <<< "$COMMAND")" || egress_fq=gh  # respell: fast-strip
    case "$egress_fq" in *[Gg][Hh]*|*'\'*) egress_fast=gh ;; esac  # respell: fast-path
    case "$egress_fast" in
      *gh*)
    # The branch body below is deliberately left at the rule's own indentation
    # rather than shifted under the `case`. The guard is a performance wrapper, not
    # a logical nesting level, and re-indenting the whole evaluator to express it
    # would bury the logic a reviewer actually needs to read. The branch closes at
    # the `;;` / `esac` at the end of the rule.
    if ! egress_norm="$(egress_neutralize_quoted "$COMMAND")"; then
      # The scanner found an unterminated quote in COMMAND text. Raised only when the
      # command carries a `gh api` invocation at a command position the replaced matcher
      # could have reached, so an unbalanced quote in an unrelated command is not this
      # rule's business.
      #
      # NOT a widening: it denies at every rung, because gating it would do what the
      # rollout ladder must never do — allow, on account of the rung, a case the
      # replaced matcher denied. The deny is free only for a genuinely malformed
      # command, which cannot run either. What the scanner cannot tokenize is WIDER than
      # what the shell cannot parse — a heredoc body, an escaped or nested quote, a
      # comment the scanner does not recognize — so a well-formed command can be refused
      # here too, and each record's `features.shell_parse` says which kind it was.
      #
      # The class is read in every spelling the walk resolves at those positions: the
      # shipped test runs first and unchanged, and the second reader looks for the same
      # invocation through the walk's own helpers, past no keyword, assignment or prefix
      # word, and only up to the parse cap for a respelled verb.
      if egress_old_reachable_gh_api "$COMMAND" || egress_old_reachable_respelled "$COMMAND"; then  # respell: unparseable
        # The one cause whose evidence is a constant carries the feature set instead.
        egress_007_verdict "unparseable" "unknown" 0 "$(egress_007_unparseable_features "$COMMAND")"
      fi
    else
      # Segment on the shell's command separators, in TWO classes — the distinction
      # is load-bearing for the rollout classification below, not cosmetic.
      #
      #   `;` `&` `|` and newline  — separators the REPLACED anchor already
      #                              recognized, so a `gh api` at the head of such a
      #                              segment was reachable by the old matcher.
      #   `(` `)` and the backtick — subshell, command substitution (together with
      #                              the `$` left behind) and its older spelling.
      #                              The old anchor did NOT admit these, so a write
      #                              reached from one of them is a position the old
      #                              matcher provably never adjudicated.
      #
      # Structure inside a quoted span was neutralized above, so a separator that is
      # part of a STRING can no longer create a segment in either class.
      # Each separator becomes a newline PLUS a one-character class marker, so every
      # segment after the first announces how it was opened and the loop below stays a
      # single flat pass. The first segment carries no marker: it is the start of the
      # command, which the old anchor always admitted.
      #
      # Before segmenting, a backslash-newline is joined as the shell joins it (the keep rule
      # keeps a line that earns its own verdict), and a redirection operator's `&` or `|`
      # is protected, so it is read as the operator it is and never as a separator.
      egress_join_continuations  # respell: join
      egress_protect_redirect_ops "$egress_norm"; egress_norm="$EGRESS_PRO"  # respell: redirect
      egress_segs="$egress_norm"
      if [ "${#egress_segs}" -ge "$EGRESS_LINEAR_MIN" ] && egress_lp="$(LC_ALL=C /usr/bin/awk -v o="$EGRESS_BND_OLD" -v w="$EGRESS_BND_NEW" '{ gsub(/[;&|]/, "\n" o); gsub(/[()`]/, "\n" w); print }' <<< "${egress_segs}.")"; then egress_segs="${egress_lp%.}"; fi  # linear: segments
      egress_segs="${egress_segs//;/$'\n'${EGRESS_BND_OLD}}"
      egress_segs="${egress_segs//&/$'\n'${EGRESS_BND_OLD}}"
      egress_segs="${egress_segs//|/$'\n'${EGRESS_BND_OLD}}"
      egress_segs="${egress_segs//(/$'\n'${EGRESS_BND_NEW}}"
      egress_segs="${egress_segs//)/$'\n'${EGRESS_BND_NEW}}"
      egress_segs="${egress_segs//\`/$'\n'${EGRESS_BND_NEW}}"

      egress_segno=0
      egress_ghseen=0
      egress_rpseen=0

      while IFS= read -r egress_seg; do
        egress_segno=$(( egress_segno + 1 ))
        case "$egress_seg" in
          "${EGRESS_BND_NEW}"*) egress_oldpos=0; egress_seg="${egress_seg#?}" ;;
          "${EGRESS_BND_OLD}"*) egress_oldpos=1; egress_seg="${egress_seg#?}" ;;
          *)                    egress_oldpos=1 ;;
        esac
        egress_seg="${egress_seg#"${egress_seg%%[![:space:]]*}"}"
        [ -n "$egress_seg" ] || continue
        # A segment whose head token opens a comment is not a command.
        case "$egress_seg" in
          '#'*) continue ;;
        esac

        # Tokenize with globbing OFF, so a literal `*` in the command is not
        # expanded against the cwd before it can be adjudicated.
        set -f
        # shellcheck disable=SC2206
        egress_toks=( $egress_seg )
        set +f
        # The respelling marks come off, flagging their tokens, and every redirection word
        # (with an operator's operand) leaves the segment, flagging the token after it; a quoted
        # `<` or `>` is a stand-in until then, and is put back once the strip has run.
        egress_strip_marks || continue
        egress_strip_redirections || continue  # respell: redirect
        egress_restore_quoted_ops
        [ "${#egress_toks[@]}" -ge 2 ] || continue

        # ---- Resolve COMMAND POSITION before reading the verb ----
        #
        # Consume, repeatedly and in any order: compound-command keywords, command
        # wrappers (each followed by its own leading flags), and variable-assignment
        # prefixes. The walk stops at the first token that is none of these, rather than
        # assuming index 0. That token is the command word unless a prefix command's own
        # option argument or operand stands in front of it; the secondary locator below
        # the walk finds the gated verb in that case.
        #
        # A keyword only counts at the HEAD of a segment, and a segment can no longer
        # begin inside a string literal, which is what makes this precise rather than
        # permissive: `echo "step 1; do gh api ... --method POST"` produces no segment
        # at all, because its separators were neutralized.
        #
        # The assignment-prefix predicate is spelled identically to the one
        # BLOCK-DESTRUCTIVE-022 uses — a token is a prefix assignment IFF it contains
        # `=` AND its NAME part is a valid shell name, or a valid name and the one `+`
        # of the append form `NAME+=value`, which bash and zsh read as an assignment
        # word too — so `a-b=1` and `--body=x` both terminate the walk and the skip
        # cannot degrade into "advance past any token containing `=`". One vocabulary
        # across both matcher surfaces, deliberately; the suite's AC-E007-AP-PARITY arm
        # reads both. An append whose value opens an array ends the walk, as it ends
        # that rule's; here `(` already opens a segment, so this walk never meets such a
        # token, and the line is kept for the shared spelling. Before the walk-fix pass
        # (#8315) an append-form word ended the walk as an unlisted leading word, which
        # this rule treats as the command, so a write behind it was admitted with no
        # record; it now takes the rung of its NAME=value twin.
        #
        # One line this rule adds after the predicate (`append: hold`): an invocation the
        # walk reaches only behind the append form advances neither first-invocation
        # counter, exactly as a look-ahead hit does not (egress_scanhit), because the
        # shipped hook never reached it. Counting it would move a later write at the head
        # of a segment out of the day-one refusal it has today.
        #
        # A token the walk reaches DIRECTLY — the segment head, or the token right after a
        # keyword, an assignment, or a prefix word with no option between — is read as the
        # shell resolves it (the command-word normalization) before it is tested; the first
        # token after a prefix command's option run is not, because it may be that option's
        # argument. A reserved word is recognized only in its own letter case.
        egress_hidx=0
        egress_pfxseen=0
        egress_scanhit=0
        egress_pos=""
        egress_direct=1
        egress_hnorm=0
        egress_cfold=0
        while [ "$egress_hidx" -lt "${#egress_toks[@]}" ]; do
          egress_raw="${egress_toks[$egress_hidx]}"
          case "$egress_raw" in
            [A-Za-z_]*=*)
              case "${egress_raw%%=*}" in
                *[!A-Za-z0-9_+]*|*+?*) break ;;  # append: walk
                *+) case "${egress_raw#*=}" in '('*) break ;; esac ;;  # append: array
              esac
              case "${egress_raw%%=*}" in *+) egress_scanhit=1 ;; esac  # append: hold
              egress_hidx=$(( egress_hidx + 1 ))
              egress_direct=1
              continue
              ;;
          esac
          egress_hnorm=0
          egress_cfold=0
          if [ "$egress_direct" -eq 1 ]; then
            egress_norm_at "$egress_hidx" abc
            egress_hnorm=1
            egress_raw="${egress_toks[$egress_hidx]}"
          fi
          case "${egress_raw##*/}" in
            do|then|else|elif|if|while|until|'!'|'{'|'}'|'{}')
              [ "$egress_cfold" -eq 0 ] || break
              egress_hidx=$(( egress_hidx + 1 ))
              egress_direct=1
              ;;
            time|command|builtin|exec|nohup|env|sudo|xargs|timeout|nice|stdbuf)
              egress_pfxseen=1
              egress_hidx=$(( egress_hidx + 1 ))
              egress_optat="$egress_hidx"
              while [ "$egress_hidx" -lt "${#egress_toks[@]}" ]; do
                case "${egress_toks[$egress_hidx]}" in
                  -*) egress_hidx=$(( egress_hidx + 1 )) ;;
                  *) break ;;
                esac
              done
              if [ "$egress_hidx" -eq "$egress_optat" ]; then egress_direct=1; else egress_direct=0; fi
              ;;
            *) break ;;
          esac
        done

        # >>> PREFIX-LOCATOR-BEGIN — core/hooks/tests/block-egress.test.sh (AC-E007-W*)
        # ---- Secondary locator: the gated verb behind a prefix command's own grammar ----
        #
        # The walk above skips a prefix command's dash-led tokens and stops at the first
        # token that is not one. That is the command word only when no option takes a
        # separate argument and the prefix command has no operand of its own. Otherwise the
        # walk lands on the argument (`env -u NAME`), the operand (`timeout 5`), or an
        # assignment only that command accepts (`env a-b=1`), and the segment would be
        # skipped with the real `gh api` behind it never examined.
        #
        # The remedy is a DOMAIN TEST, not a table of which options take an argument. When
        # the segment's head resolved through a prefix command and the walk did not land on
        # the gated verb, look for the first `gh` + `api` pair later in the same segment and
        # adjudicate that. A table fails OPEN on omission: one unlisted option, one unlisted
        # operand, or one launcher outside the prefix set strands the command again. The
        # domain test interprets nothing it passes over, so no option, option argument,
        # operand or launcher can end the search before the verb.
        #
        # What it costs, stated: the rule does not model the prefix command's grammar, so a
        # `gh api` pair that is only TEXT behind a prefix command (`env X=1 echo gh api -X
        # POST <path>`, or a heredoc body line that opens with a prefix word) is evaluated as
        # a write. Every position this block reaches is a widening (the verb is never at the
        # head of the segment), so it follows the rollout phase and is refused only once that
        # phase is `enforce`. What the rule reaches is adjacent `gh` and `api` words at a
        # position its walk resolves, in their plain spelling or in one the command-word
        # normalization resolves; anything else is undetermined, not covered — among others a
        # command carried as a string (`bash -c '...'`, `env -S '...'`), a command word that is
        # a variable, a leading word outside the prefix set, and a spelling no helper of this
        # rule resolves (the list beside the respelling helpers).
        #
        # Every segment the walk resolved before the respelling repairs is resolved
        # identically. `egress_scanhit` records that the verb was found here and
        # not by the walk; the first-invocation counter below reads it. `egress_pos` labels
        # the would-fire row this hit writes (`pos: "look-ahead"`), so the drain can tell
        # the two populations apart: it says which locator found the verb, never that the
        # words it found are executed. A candidate is read in a respelling only once: the
        # token the walk already normalized is tested in its normalized form alone.
        if [ "$egress_pfxseen" -eq 1 ]; then
          egress_sidx="$egress_hidx"
          while [ $(( egress_sidx + 1 )) -lt "${#egress_toks[@]}" ]; do
            if [ "${egress_toks[$egress_sidx]##*/}" = "gh" ] && [ "${egress_toks[$(( egress_sidx + 1 ))]}" = "api" ]; then
              if [ "$egress_sidx" -ne "$egress_hidx" ]; then
                egress_hidx="$egress_sidx"
                egress_scanhit=1
                egress_pos="look-ahead"
              fi
              break
            fi
            if { [ "$egress_sidx" -ne "$egress_hidx" ] || [ "$egress_hnorm" -eq 0 ]; } && egress_la_respelled "$egress_sidx"; then
              if [ "$egress_sidx" -ne "$egress_hidx" ]; then
                egress_hidx="$egress_sidx"
                egress_scanhit=1
                egress_pos="look-ahead"
              fi
              break
            fi
            egress_sidx=$(( egress_sidx + 1 ))
          done
        fi
        # >>> PREFIX-LOCATOR-END

        # need a verb AND at least one token after it
        [ $(( egress_hidx + 1 )) -lt "${#egress_toks[@]}" ] || continue

        # Basename match subsumes every absolute-path form and is strictly tighter
        # than the prefix enumeration the old anchor carried: an unlisted prefix no
        # longer evades.
        case "${egress_toks[$egress_hidx]##*/}" in
          gh) ;;
          *) continue ;;
        esac
        # The subcommand is read without the case step: gh rejects `API`.
        egress_norm_at "$(( egress_hidx + 1 ))" ab
        case "${egress_toks[$(( egress_hidx + 1 ))]}" in
          api) ;;
          *) continue ;;
        esac
        # Was this invocation reached through a respelling? It was when any token from the
        # segment start through the subcommand carried a mark, followed a removed
        # redirection, or was changed by the command-word normalization.
        egress_repaired=0
        egress_j=0
        while [ "$egress_j" -le $(( egress_hidx + 1 )) ]; do
          if [ "${egress_tflag[$egress_j]:-0}" -eq 1 ]; then egress_repaired=1; break; fi
          egress_j=$(( egress_j + 1 ))
        done
        # A verb found by the secondary locator does not advance the first-invocation
        # counter. The rollout classifier below can refuse from day one only the FIRST
        # invocation the walk resolves; counting one that only the locator can see would
        # move a later head-position write out of that refusal and into the rollout phase —
        # a deny withdrawn by a change that was meant only to add evaluation. Holding the
        # counter still keeps the shipped hook's verdict for every invocation the walk
        # resolves; it is not a reconstruction of the replaced matcher's verdict.
        #
        # An invocation reached only through a respelling does not advance it either, for the
        # same reason: the shipped hook could not see it, so counting it would move a later
        # plain write out of the day-one refusal. It counts on its own counter instead.
        if [ "$egress_repaired" -eq 1 ] && [ "$egress_scanhit" -eq 0 ]; then egress_scanhit=1; egress_rpseen=$(( egress_rpseen + 1 )); fi  # respell: no-count
        if [ "$egress_scanhit" -eq 0 ]; then egress_ghseen=$(( egress_ghseen + 1 )); fi

        # ---- Walk the operands: method, write-ness, and the path ----
        #
        # Token-level, not a regex over the segment. A `--method PATCH` occurring
        # inside a quoted body is ONE token after neutralization and therefore cannot
        # be mistaken for a flag. Value-taking flags are enumerated so their VALUE is
        # not mistaken for the path — which is the defect that made the repo's own
        # `gh api -X POST <path>` spelling extract `-X` and deny.
        #
        # Implicit POST is exact, not a heuristic: gh documents that the request
        # method defaults to POST when a field flag is present, so `-f`/`-F`/`--field`
        # /`--raw-field`/`--input` IS a write even with no `-X`.
        #
        # A short flag is read in every form gh's parser takes: separate (`-X POST`),
        # attached (`-XPOST`, `-X=POST`) and clustered after the boolean `-i` (`-iX POST`),
        # so a method or field flag sets what its plain spelling sets and its value is never
        # taken for the path.
        egress_idx=$(( egress_hidx + 2 ))
        egress_method=""
        egress_explicit=0
        egress_implicit=0
        egress_path=""
        egress_ddash=0
        while [ "$egress_idx" -lt "${#egress_toks[@]}" ]; do
          egress_tok="${egress_toks[$egress_idx]}"
          if [ "$egress_ddash" -eq 1 ]; then
            if [ -z "$egress_path" ]; then egress_path="$egress_tok"; fi
            egress_idx=$(( egress_idx + 1 ))
            continue
          fi
          case "$egress_tok" in
            --)
              egress_ddash=1
              egress_idx=$(( egress_idx + 1 ))
              ;;
            -X|--method)
              if [ $(( egress_idx + 1 )) -lt "${#egress_toks[@]}" ]; then
                egress_method="${egress_toks[$(( egress_idx + 1 ))]}"
                egress_explicit=1
              fi
              egress_idx=$(( egress_idx + 2 ))
              ;;
            --method=*)
              egress_method="${egress_tok#--method=}"
              egress_explicit=1
              egress_idx=$(( egress_idx + 1 ))
              ;;
            -f|-F|--field|--raw-field|--input)
              egress_implicit=1
              egress_idx=$(( egress_idx + 2 ))
              ;;
            --field=*|--raw-field=*|--input=*)
              egress_implicit=1
              egress_idx=$(( egress_idx + 1 ))
              ;;
            -H|--header|-q|--jq|-t|--template|--hostname|--cache|-p|--preview)
              egress_idx=$(( egress_idx + 2 ))
              ;;
            -[!-]?*) egress_short_flags; continue ;;  # respell: short-flags
            -*)
              egress_idx=$(( egress_idx + 1 ))
              ;;
            *)
              if [ -z "$egress_path" ]; then egress_path="$egress_tok"; fi
              egress_idx=$(( egress_idx + 1 ))
              ;;
          esac
        done

        # Is this segment a WRITE? Each segment carries its own determination, so a
        # read co-located with a write is not adjudicated against the write allowlist.
        egress_write=0
        case "$egress_method" in
          POST|PUT|PATCH|DELETE|post|put|patch|delete|Post|Put|Patch|Delete) egress_write=1 ;;
        esac
        if [ "$egress_implicit" -eq 1 ] && [ "$egress_write" -eq 0 ] && [ "$egress_explicit" -eq 0 ]; then
          egress_write=1
        fi
        [ "$egress_write" -eq 1 ] || continue

        # ---- Rollout classification ----
        #
        # A write is classified by the command position the shell resolves it to, not by
        # how that position is spelled. The replaced matcher adjudicated ONE path — the
        # FIRST `gh api` in the command — reached only from start-of-string or a `[;&|]`
        # separator, with the verb at the head of the segment, and only when an explicit
        # write method was present. A write meeting all four conditions enforces from day
        # one in every spelling the rule resolves, because gating it would LOOSEN a control
        # that already denies its plain spelling. Anything else enters the rollout ladder.
        #
        # "First" is read on two counters. An invocation the shipped hook could resolve is
        # the first when it is the first such one, exactly as before. An invocation resolved
        # only through a respelling is the first when no counted invocation precedes it and
        # it is the first respelled one — so a respelled read before a plain write leaves that
        # write refused, stricter than its plain twin and never looser.
        #
        # The `oldpos` term is why segmentation tracks two separator classes. Without
        # it a write inside `$( )` or a subshell would be classified as old-reachable
        # and enforced on day one — but the old anchor never admitted those positions,
        # so that deny is new and owes the ladder. Measured: it is the difference
        # between three cases reading enforce and reading shadow.
        egress_widening=1
        if [ "$egress_hidx" -eq 0 ] && [ "$egress_explicit" -eq 1 ] && [ "$egress_oldpos" -eq 1 ] && { { [ "$egress_repaired" -eq 0 ] && [ "$egress_ghseen" -eq 1 ]; } || { [ "$egress_repaired" -eq 1 ] && [ "$egress_ghseen" -eq 0 ] && [ "$egress_rpseen" -eq 1 ]; }; }; then
          egress_widening=0
        fi

        if [ -z "$egress_path" ]; then
          egress_007_verdict "no-path" "unknown" "$egress_widening" "" "$egress_pos"
          continue
        fi

        if ! egress_norm_path="$(egress_classify_api_path "$egress_path")"; then
          egress_007_verdict "unresolvable" "$egress_path" "$egress_widening" "" "$egress_pos"
          continue
        fi

        if ! is_allowlisted "$egress_norm_path" "$EGRESS_ALLOWLIST" gh-api-path; then
          egress_007_verdict "not-allowlisted" "$egress_norm_path" "$egress_widening" "" "$egress_pos"
        fi
      done <<< "$egress_segs"
    fi

        ;;
    esac

    # ----- Raw network tools -----

    # BLOCK-EGRESS-008 — nc / ncat (unconditional)
    # Absolute-path-aware: also detects /usr/local/bin/nc, etc.
    if matches "${ANCHOR_PREFIX_BASH}"'(nc|ncat)([[:space:]]|$)'; then
      apply_block "BLOCK-EGRESS-008" \
        "nc / ncat denied (raw TCP is a direct exfil channel)." \
        "set CLAUDE_HOOK_BYPASS=1 if truly needed"
    fi

    # BLOCK-EGRESS-009 — scp to remote target
    # Absolute-path-aware.
    if matches "${ANCHOR_PREFIX_BASH}"'scp[[:space:]]+[^;&|]*[a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+:'; then
      apply_block "BLOCK-EGRESS-009" \
        "scp to remote host denied (data-exfil vector)." \
        "set CLAUDE_HOOK_BYPASS=1 if intentional"
    fi

    # BLOCK-EGRESS-010 — rsync with remote target (user@host: syntax)
    # Absolute-path-aware.
    if matches "${ANCHOR_PREFIX_BASH}"'rsync[[:space:]]+[^;&|]*[a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+:'; then
      apply_block "BLOCK-EGRESS-010" \
        "rsync to remote host denied (data-exfil vector)." \
        "set CLAUDE_HOOK_BYPASS=1 if intentional"
    fi

    # BLOCK-EGRESS-011 — ssh to non-allowlisted host
    # Absolute-path-aware.
    if matches "${ANCHOR_PREFIX_BASH}"'ssh[[:space:]]+'; then
      # Extract the host (first non-flag arg)
      ssh_host="$("$PRINTF" '%s' "$COMMAND" | "$GREP" -oE 'ssh[[:space:]]+([^[:space:]]+[[:space:]]+)*[a-zA-Z0-9._@-]+([[:space:]]|$)' | /usr/bin/head -1 | "$GREP" -oE '[a-zA-Z0-9._@-]+[[:space:]]*$' | "$TR" -d '[:space:]' || "$PRINTF" '')"
      if [ -z "$ssh_host" ] || ! is_allowlisted "$ssh_host" "$SSH_ALLOWLIST"; then
        apply_block "BLOCK-EGRESS-011" \
          "ssh to non-allowlisted host denied (host: ${ssh_host:-unknown})." \
          "add host to .claude/ssh-allowlist.txt, or set CLAUDE_HOOK_BYPASS=1" \
          "host=${ssh_host:-unknown}"
      fi
    fi

    exit 0
    ;;

  WebFetch)
    URL="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.url // empty')"
    [ -z "$URL" ] && exit 0

    # BLOCK-EGRESS-012 — file:// and localhost / 127.0.0.1 URLs
    case "$URL" in
      file://*)
        apply_block "BLOCK-EGRESS-012" \
          "WebFetch to file:// URL denied (local file exfil via URL param)." \
          "use Read tool to access local files, or set CLAUDE_HOOK_BYPASS=1"
        ;;
      http://localhost*|http://127.0.0.1*|https://localhost*|https://127.0.0.1*|http://0.0.0.0*)
        apply_block "BLOCK-EGRESS-012" \
          "WebFetch to localhost / loopback denied (internal services bypass)." \
          "use direct tool calls for local services, or set CLAUDE_HOOK_BYPASS=1"
        ;;
    esac

    # BLOCK-EGRESS-013 — WebFetch to non-allowlisted domain
    webfetch_host="$(extract_host "$URL")"
    if [ -z "$webfetch_host" ] || ! is_allowlisted "$webfetch_host" "$WEBFETCH_ALLOWLIST"; then
      apply_block "BLOCK-EGRESS-013" \
        "WebFetch to non-allowlisted domain denied (domain: ${webfetch_host:-unknown})." \
        "add domain to .claude/webfetch-allowlist.txt, or set CLAUDE_HOOK_BYPASS=1" \
        "host=${webfetch_host:-unknown}"
    fi

    exit 0
    ;;

  *)
    exit 0
    ;;
esac
