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
# Pattern is duplicated across the 3 regex-based PreToolUse hooks
# (block-destructive.sh, block-egress.sh, block-rm-prefer-trash.sh) —
# extracted as a per-hook constant to surface the convention and keep
# each hook file-local-self-contained per the existing posture.
# WebFetch-branch rules (BLOCK-EGRESS-012, BLOCK-EGRESS-013) are
# tool-name-matched (not verb-anchored) and not affected by this hook.
readonly ANCHOR_PREFIX_BASH='(^|[;&|])[[:space:]]*(/(usr/(local/)?|opt/(homebrew|local)/)?bin/)?'

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
# `evidence` is the rule-specific detail apply_block already receives — the denied
# path, the target host, the cause class. It used to be threaded into the WARN log
# and dropped on the floor in enforce, where log_block was called with the rule id
# alone. The record then said THAT something was denied but never WHAT, which makes
# a block log unreadable at exactly the mode where it is the only observation
# surface: an operator watching a shakedown could see a rule firing and had no way
# to tell a genuine catch from a false positive. Additive — the field is optional,
# and every existing consumer reads by key.
log_block() {
  local rule_id="$1"
  local evidence="${2:-}"
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  local tool_input; tool_input="$("$PRINTF" '%s' "$INPUT" | "$JQ" -c '.tool_input // {}')"
  local input_digest; input_digest="$("$PRINTF" '%s' "$tool_input" | /usr/bin/shasum -a 256 | "$GREP" -oE '^[a-f0-9]+' | /usr/bin/head -c 16)"
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
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
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
  local mode; mode="$(get_mode)"

  case "$mode" in
    warn)
      log_warn "$rule_id" "$reason" "$evidence"
      "$PRINTF" '[CLAUDE-HOOK:%s:%s] WARN (would-block, .mode=warn): %s\n' "$HOOK_NAME" "$rule_id" "$reason" >&2
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

# --- HELPERS ---

# Pattern match against $COMMAND
matches() {
  "$PRINTF" '%s' "$COMMAND" | "$GREP" -qE "$1"
}

# Check a value against a glob-pattern allowlist file (bash case globbing)
is_allowlisted() {
  local value="$1"
  local allowlist="$2"
  [ -f "$allowlist" ] || return 1
  local pattern
  while IFS= read -r pattern || [ -n "$pattern" ]; do
    case "$pattern" in
      ''|'#'*) continue;;
    esac
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
# Bash 3.2-safe throughout (macOS system bash): parameter expansion and `case`
# only, no subprocess inside the scanner, and the segment loop runs in the CURRENT
# shell (here-string, never a pipeline) so apply_block's exit 2 propagates instead
# of dying in a subshell.

# Rollout phase for -007's WIDENING classes, per progressive-rollout-convention.md.
#   shadow  — evaluate, log `would-fire`, take NO action, surface nothing
#   warn    — evaluate, log, emit a stderr notice, still allow
#   enforce — apply the deny
# Deliberately ONE line to advance, so the Stage-9 GO gate can ratify straight to
# `enforce` without a code redesign. Advance one rung at a time; retreat is the
# same single edit. REPAIRS — quote handling, the flag walk, `--` — are NOT gated
# by this and enforce from day one, because they can only STOP a wrong denial and
# so carry no new-deny risk by construction.
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

# Segment-boundary class markers. Segmentation emits one segment per line, each
# prefixed with the class of the separator that OPENED it, so the rollout classifier
# can tell a command position the replaced matcher adjudicated from one it never
# reached. Carrying the class inline keeps segmentation a single flat pass.
readonly EGRESS_BND_OLD=$'\002'   # `;` `&` `|` — the replaced anchor admitted these
readonly EGRESS_BND_NEW=$'\003'   # `(` `)` backtick — it did not

# True when the string ends in an ODD number of backslashes — i.e. a following
# quote character is escaped and is not a terminator.
egress_trailing_backslash_odd() {
  local t="$1" c=0
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
egress_comment_open_at_end() {
  local last="${1##*$'\n'}"
  local pre
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
egress_neutralize_quoted() {
  local rest="$1"
  local out="" head body q
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
      body="${body//\"/${EGRESS_SENT}}"
      body="${body//\'/${EGRESS_SENT}}"
      out="${out}${body}"
      continue
    fi
    q="${rest%"${rest#?}"}"
    rest="${rest#?}"
    case "$rest" in
      *"$q"*) ;;
      *) return 1 ;;
    esac
    body="${rest%%"$q"*}"
    rest="${rest#"$body"}"
    # A backslash-escaped quote inside a DOUBLE-quoted span is content, not a
    # terminator; absorb it and keep scanning. Single quotes have no escape
    # mechanism in shell, so this correction applies to double quotes only.
    if [ "$q" = '"' ]; then
      while egress_trailing_backslash_odd "$body"; do
        rest="${rest#?}"
        case "$rest" in
          *"$q"*) ;;
          *) return 1 ;;
        esac
        body="${body}${q}${rest%%"$q"*}"
        rest="${rest#"${rest%%"$q"*}"}"
      done
    fi
    rest="${rest#?}"
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
    out="${out}${body}"
  done
  "$PRINTF" '%s' "$out"
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

# Classify a gh-api path operand per the AUTHORITY-PREFIX rule.
#
# An UNEVALUABLE span is a path segment carrying `$`, a backtick, a `{...}` pair,
# or a leading `:name`. The AUTHORITY PREFIX is the first THREE path segments:
# GitHub REST paths are `repos/{owner}/{repo}/...`, `orgs/{org}/...` and
# `users/{user}/...`, so the first three segments are exactly what decides WHICH
# repository a write reaches — and every path pattern in the allowlist fixes those
# three literally. The threshold is read off the allowlist's own shape, not chosen.
#
#   unevaluable IN the authority  -> return 1; the caller denies, naming the cause
#   unevaluable BELOW it          -> substitute `*` and adjudicate normally
#
# The second half is sound because every allowlist path pattern is prefix-anchored:
# the literal prefix is fixed, so whatever the variable expands to, the path still
# begins inside an allowlisted repository. It is also what keeps a bulk loop over
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
log_would_fire() {
  local rule_id="$1"
  local phase="$2"
  local cause="$3"
  local path="$4"
  local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  # `-c` — one entry per LINE, which is what the .jsonl extension claims and what a
  # shakedown reading needs. The older writers in this file emit jq's default
  # pretty form, so their entries span several lines each; that is pre-existing and
  # is not changed here, because their consumers count lines as a growth signal.
  "$JQ" -nc --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg phase "$phase" --arg cause "$cause" --arg path "$path" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, phase:$phase, reason:"would-fire", cause:$cause, path:$path}' \
    >> "$WARN_LOG" 2>/dev/null || true
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
  local reason override

  if [ "$widening" -eq 1 ]; then
    case "$EGRESS_007_WIDENING_PHASE" in
      shadow)
        log_would_fire "BLOCK-EGRESS-007" "shadow" "$cause" "$path"
        return 0
        ;;
      warn)
        log_would_fire "BLOCK-EGRESS-007" "warn" "$cause" "$path"
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
  apply_block "BLOCK-EGRESS-007" "$reason" "$override" "path=${path} cause=${cause}"
}

# ==========================================================================
# BRANCH BY TOOL NAME
# ==========================================================================

case "$TOOL_NAME" in
  Bash)
    COMMAND="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.command // empty')"
    [ -z "$COMMAND" ] && exit 0

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
      if [ -z "$target_host" ] || ! is_allowlisted "$target_host" "$EGRESS_ALLOWLIST"; then
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
    # Fast-path guard. The head token's basename must be `gh`, so the substring is
    # necessarily present — a command without it can be skipped without scanning.
    # Non-`gh` commands are therefore measurably FASTER than before this change,
    # because the gate `grep` fork the old structure always ran is now skipped.
    case "$COMMAND" in
      *gh*)
    # The branch body below is deliberately left at the rule's own indentation
    # rather than shifted under the `case`. The guard is a performance wrapper, not
    # a logical nesting level, and re-indenting the whole evaluator to express it
    # would bury the logic a reviewer actually needs to read. The branch closes at
    # the `;;` / `esac` at the end of the rule.
    if ! egress_norm="$(egress_neutralize_quoted "$COMMAND")"; then
      # An unterminated quote in COMMAND text — comment text can no longer produce
      # one. Raised only when the command carries a `gh api` invocation at a command
      # position the replaced matcher could have reached, so an unbalanced quote in
      # an unrelated command is not this rule's business.
      #
      # NOT a widening. The class is scoped to input that genuinely cannot execute
      # as typed, so the deny costs nothing that the shell would not cost anyway —
      # and gating it would do what the rollout ladder must never do: allow, on
      # account of the rung, a case the replaced matcher denied.
      if egress_old_reachable_gh_api "$COMMAND"; then
        egress_007_verdict "unparseable" "unknown" 0
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
      egress_segs="${egress_norm//;/$'\n'${EGRESS_BND_OLD}}"
      egress_segs="${egress_segs//&/$'\n'${EGRESS_BND_OLD}}"
      egress_segs="${egress_segs//|/$'\n'${EGRESS_BND_OLD}}"
      egress_segs="${egress_segs//(/$'\n'${EGRESS_BND_NEW}}"
      egress_segs="${egress_segs//)/$'\n'${EGRESS_BND_NEW}}"
      egress_segs="${egress_segs//\`/$'\n'${EGRESS_BND_NEW}}"

      egress_segno=0
      egress_ghseen=0

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
        [ "${#egress_toks[@]}" -ge 2 ] || continue

        # ---- Resolve COMMAND POSITION before reading the verb ----
        #
        # Consume, repeatedly and in any order: compound-command keywords, command
        # wrappers (each followed by its own leading flags), and variable-assignment
        # prefixes. The command word is the first token that is none of these — which
        # is how the shell itself resolves command position, rather than assuming
        # index 0.
        #
        # A keyword only counts at the HEAD of a segment, and a segment can no longer
        # begin inside a string literal, which is what makes this precise rather than
        # permissive: `echo "step 1; do gh api ... --method POST"` produces no segment
        # at all, because its separators were neutralized.
        #
        # The assignment-prefix predicate is spelled identically to the one
        # BLOCK-DESTRUCTIVE-022 uses — a token is a prefix assignment IFF it contains
        # `=` AND its NAME part is a valid shell name — so `a-b=1` and `--body=x` both
        # terminate the walk and the skip cannot degrade into "advance past any token
        # containing `=`". One vocabulary across both matcher surfaces, deliberately.
        egress_hidx=0
        while [ "$egress_hidx" -lt "${#egress_toks[@]}" ]; do
          egress_raw="${egress_toks[$egress_hidx]}"
          case "$egress_raw" in
            [A-Za-z_]*=*)
              case "${egress_raw%%=*}" in
                *[!A-Za-z0-9_]*) break ;;
              esac
              egress_hidx=$(( egress_hidx + 1 ))
              continue
              ;;
          esac
          case "${egress_raw##*/}" in
            do|then|else|elif|if|while|until|'!'|'{'|'}'|'{}')
              egress_hidx=$(( egress_hidx + 1 ))
              ;;
            time|command|builtin|exec|nohup|env|sudo|xargs|timeout|nice|stdbuf)
              egress_hidx=$(( egress_hidx + 1 ))
              while [ "$egress_hidx" -lt "${#egress_toks[@]}" ]; do
                case "${egress_toks[$egress_hidx]}" in
                  -*) egress_hidx=$(( egress_hidx + 1 )) ;;
                  *) break ;;
                esac
              done
              ;;
            *) break ;;
          esac
        done

        # need a verb AND at least one token after it
        [ $(( egress_hidx + 1 )) -lt "${#egress_toks[@]}" ] || continue

        # Basename match subsumes every absolute-path form and is strictly tighter
        # than the prefix enumeration the old anchor carried: an unlisted prefix no
        # longer evades.
        case "${egress_toks[$egress_hidx]##*/}" in
          gh) ;;
          *) continue ;;
        esac
        case "${egress_toks[$(( egress_hidx + 1 ))]}" in
          api) ;;
          *) continue ;;
        esac
        egress_ghseen=$(( egress_ghseen + 1 ))

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
        # A deny is a WIDENING exactly when the replaced matcher could not have
        # produced it. That matcher adjudicated ONE path — the FIRST `gh api` in the
        # command — reached only from start-of-string or a `[;&|]` separator, with the
        # verb at the head of the segment, and only when an explicit write method was
        # present. A deny meeting all four conditions is the SAME verdict the old code
        # reached: it enforces from day one, because gating it would LOOSEN a control
        # that already denies. Anything else is new and enters the rollout ladder.
        #
        # The `oldpos` term is why segmentation tracks two separator classes. Without
        # it a write inside `$( )` or a subshell would be classified as old-reachable
        # and enforced on day one — but the old anchor never admitted those positions,
        # so that deny is new and owes the ladder. Measured: it is the difference
        # between three cases reading enforce and reading shadow.
        egress_widening=1
        if [ "$egress_ghseen" -eq 1 ] && [ "$egress_hidx" -eq 0 ] && [ "$egress_explicit" -eq 1 ] && [ "$egress_oldpos" -eq 1 ]; then
          egress_widening=0
        fi

        if [ -z "$egress_path" ]; then
          egress_007_verdict "no-path" "unknown" "$egress_widening"
          continue
        fi

        if ! egress_norm_path="$(egress_classify_api_path "$egress_path")"; then
          egress_007_verdict "unresolvable" "$egress_path" "$egress_widening"
          continue
        fi

        if ! is_allowlisted "$egress_norm_path" "$EGRESS_ALLOWLIST"; then
          egress_007_verdict "not-allowlisted" "$egress_norm_path" "$egress_widening"
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
