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
# Rollout drain for the BLOCK-DESTRUCTIVE-022 exec arm — the FIRST drain this hook
# has ever had. Named `<hook-stem>-warn-log.jsonl` because nine hooks in this bundle
# already use that shape, and because `.gitignore` covers `core/hooks/*.jsonl` and
# `.claude/hooks/*.jsonl`, so it is git-ignored by construction with no ignore-rule
# edit. Declaring it here does NOT make this hook mode-capable: the write is gated
# on DESTRUCTIVE_022_EXEC_PHASE alone and never on a mode dial. That distinction is
# load-bearing — block-fs-boundary.sh:53 and block-shell-injection.sh:53 each declare
# a drain whose write is conditional on the shared `.mode`, which is never in the
# writing position, so those drains are declared-but-dead and indistinguishable from
# absent. This one is live on day one because the arm ships at `warn` and `warn`
# writes.
readonly WARN_LOG="${HOOK_DIR}/destructive-warn-log.jsonl"
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

# Resolve one raw-argv token to the filename the shell will actually operate on.
# Quoting a path is ordinary usage, and an unstripped quote leaves the token not
# ending in `.sh` — which silently disabled BLOCK-DESTRUCTIVE-022 altogether
# (`bash "/tmp/evil.sh"` matched nothing and fell through to allow). A
# half-quoted token left by segment splitting (`/tmp/evil.sh"`) needs the same
# treatment.
#
# WHY THE TRAILING SIDE IS A RUN AND NOT ONE CHARACTER. Stripping exactly one
# trailing quote left a second defect open. A token that is the TAIL of a
# command substitution carries the substitution's own closing punctuation, so
# `echo "$(cd /tmp && bash /tmp/evil.sh)"` presents the operand as
# `/tmp/evil.sh)"` — one strip leaves `/tmp/evil.sh)`, which the interpreter
# arm's SUFFIX-anchored `*.sh` filter does not match. The matcher fired and then
# skipped, and check_script_target was never called. The `source`/`.` arm
# survived the identical input only because its filter carries PREFIX
# alternatives (`/*`, `./*`, `../*`) that trailing punctuation does not disturb
# — a measured asymmetry between two arms of one rule, not a design.
#
# WHY NORMALIZATION AND NOT A FILTER CHANGE. Unifying the two arms' operand
# filters is forbidden in both directions by the comment on the source arm
# below: narrowing drops `/*`, `~/*` and `*.bash` coverage, and widening the
# interpreter arm opens a false-positive surface with no defect behind it.
# Normalizing here fixes the asymmetry ahead of BOTH filters and leaves each
# arm's declared operand domain exactly as it was.
#
# THE STRIPPED SET IS SHELL SYNTAX, NOT "PUNCTUATION". It is the POSIX shell
# metacharacters `| & ; < > ( )` plus the three quoting characters `" ' \``.
# Every one of them, appearing UNESCAPED AND UNQUOTED in raw argv, is syntax
# rather than part of a filename. Characters that ARE legal unquoted in a word
# (`{ } [ ] , . -`) are deliberately NOT stripped: removing those could rewrite
# one real path into a different real path, which is the one direction that can
# manufacture an allow. Arms `F1-CARVE-*` assert those four still block.
#
# DIRECTION OF ERROR — CORRECTED, THIS PARAGRAPH USED TO BE FALSE. A previous
# revision asserted that stripping "only ever makes a token MORE likely to reach
# the allowlist, never more likely to bypass it", and that a path legitimately
# containing a stripped character "fails toward blocking". Backwards, and
# measurably so. The trailing loop ran straight THROUGH a self-quoted token's own
# closing quote and kept eating characters that were literal filename content:
# `source './core/deploy/deploy.sh)'` runs a file named `deploy.sh)` — NOT
# allowlisted — and normalized to `deploy.sh`, which IS. All TEN declared-stripped
# characters flipped BLOCK to ALLOW in that one spelling. The paragraph's own
# reasoning (a strip that rewrites one real path into another manufactures an
# allow) was correct and was simply never carried to the stripped set: the
# carve-out set was audited for it, the stripped set was not. Arms
# `F1-QUOTED-*` are one per stripped character, and each was demonstrated failing
# against the pre-fix hook.
#
# THE RULE THAT REPLACES IT: DENY WHAT YOU CANNOT FULLY RESOLVE — "denied by
# construction rather than best-effort-sanitized", the Injection resistance
# concept in core/standards/domain-best-practices/software.md, whose named
# exemplar is block-fs-boundary.sh's strict branch. Best-effort sanitizing until
# a token happens to match an allowlist row is how the defect above was built. So
# the token is now read as the shell reads it, and the two cases are kept apart:
#
#   SELF-QUOTED (the token OPENS its own quote). Everything from the opening
#   quote to its MATCHING close is literal filename and must not be touched.
#   Resolution is exact when that close is the token's LAST character, and only
#   then. `'./x.sh)'` resolves to `./x.sh)` — a real filename, which then fails
#   the allowlist on its own merits rather than being sanitized into passing it.
#
#   NOT SELF-QUOTED. The trailing characters cannot be filename content: an
#   unquoted, unescaped metacharacter ends the word, and a filename that contains
#   one must be quoted or escaped (the quoted spelling is the case above; the
#   escaped spelling leaves a `\` the strip does not remove, so it fails the
#   allowlist). The trailing-run strip is therefore sound HERE and only here, and
#   it is unchanged — this is the whole of what the command-substitution-tail fix
#   contributed and arm `F1-ALLOW-tail` pins that it still passes.
#
# WHAT "CANNOT FULLY RESOLVE" MEANS CONCRETELY. Two shapes: the token opens a
# quote it never closes (`bash 'my` — segment splitting cut a space-bearing path
# in half), or it closes and then CONTINUES (`'./a''`, `'./a'b`) so the real name
# is a concatenation of the quoted run with whatever follows it. Both set
# script_norm_ok=0 and the caller denies. The value returned alongside is a
# FILTER PROBE, not a path: it exists so the arm can ask "is my operand domain
# even implicated?" before denying. Without that question every `bash -c 'a; …'`
# would deny, because segment splitting hands the `-c` arm the fragment `'a`.
# Keeping the deny inside each arm's declared operand domain is what arm
# `F1-FP-cmode` controls for.
#
# THE PROBE IS A PREFIX, AND ON ITS OWN IT CANNOT ANSWER THAT QUESTION. In the
# second shape above the rest of the real filename is still in the RAW TOKEN,
# and the probe has truncated it away: `'/tmp/'evil.sh` runs `/tmp/evil.sh` and
# probes to `/tmp/`. Every arm's domain asks a SUFFIX question, so a probe-only
# test reported "not my operand" and skipped a deny it was never meant to gate.
# Callers therefore go through script_operand_implicated, which asks the probe
# AND the raw token; this function is unchanged and is NOT where that was fixed.
#
# NOT CLAIMED: that a quote-bearing filename always resolves. `"./x\".sh"`
# resolves to `./x\` and fails the allowlist. That is the safe direction, it is
# a residual rather than a guarantee, and it is stated here rather than papered
# over — a comment in this function has already asserted one impossible direction.
#
# OUTPUT CONTRACT — GLOBALS, NOT STDOUT. Two facts must leave this function: the
# path AND whether the resolution is trustworthy. `$( … )` runs in a SUBSHELL, so
# a status set inside a command substitution cannot reach the caller at all; and
# packing the pair into one stdout string would need a delimiter that a filename
# may legally contain. So the function assigns and the caller reads.
#   script_norm_out — the path to adjudicate (or the filter probe when ok=0)
#   script_norm_ok  — 1 resolves to exactly ONE literal filename; 0 it does not
#   script_norm_raw — the token EXACTLY as argv presented it, always. Added
#     because the probe is a strict PREFIX of the real filename, and an arm whose
#     operand filter is SUFFIX-anchored cannot answer its own question from a
#     prefix — see script_operand_implicated below, which is the only reader.
#     This function's resolution logic is unchanged; this is a third output, not
#     a different answer.
normalize_script_token() {
  local t="$1" q="" body="" prev=""
  script_norm_ok=1
  script_norm_raw="$1"
  case "$t" in
    \"*|\'*)
      q="${t:0:1}"
      t="${t:1}"
      case "$t" in
        *"$q"*)
          body="${t%%"$q"*}"
          if [ "${body}${q}" = "$t" ]; then
            script_norm_out="$body"          # matching close is the last char
          else
            script_norm_ok=0                 # closes, then continues
            script_norm_out="$body"          # filter probe only
          fi
          ;;
        *)
          script_norm_ok=0                   # opened, never closed
          script_norm_out="$t"               # filter probe only
          ;;
      esac
      return 0
      ;;
  esac
  while [ "$t" != "$prev" ]; do
    prev="$t"
    t="${t%[\"\'\`\(\)\;\&\|\<\>]}"
  done
  script_norm_out="$t"
}

# Decide whether the token just normalized falls inside ONE arm's declared operand
# domain — the question each arm's `case` filter was already written to answer.
#
# THE SUBJECT RULE, WHICH IS THE WHOLE OF THIS FUNCTION. When the token RESOLVED
# (script_norm_ok=1) script_norm_out IS the filename the shell will operate on, it
# is the only subject, and nothing here changes. When it did NOT resolve,
# script_norm_out is a strict PREFIX of that filename and nothing more. Every
# domain below asks at least one SUFFIX question (`*.sh`, `*.bash`), and a suffix
# question CANNOT be answered from a prefix — it reports "outside my domain" for a
# token whose real name ends in `.sh`, the arm skips, and the deny
# check_script_target was about to raise is never reached.
#
# That is precisely how `bash '/tmp/'evil.sh` — ordinary quote-adjacent shell
# concatenation, which runs the real and non-allowlisted /tmp/evil.sh — went from
# DENY to a silent ALLOW: the token opens a quote, closes it, then continues, so
# the resolution correctly declines and hands back the probe `/tmp/`, which ends
# in no suffix at all. The resolution was right. The subject the filter then read
# was a prefix, and the filter asked it a suffix question.
#
# So an unresolvable token is tested against BOTH views this hook holds — the
# resolved prefix AND the raw argv token — and the domain counts as implicated if
# EITHER matches. The direction is forced: a partial view of a token may ADD
# coverage, it may never VETO it. Neither view alone is sufficient, and they are
# not interchangeable — that is why both are asked and not just the better one:
#   probe only  is the defect above (`'/tmp/'evil.sh` -> probe `/tmp/`, no suffix)
#   raw only    loses arm F1-QUOTED-squote/interp (`'<path>.sh''` -> the raw token
#               ends `''` and matches no suffix, while its probe `<path>.sh` does)
#
# THE DENY IS STILL GATED ON THE DOMAIN, AND THAT GATE IS LOAD-BEARING. Raising
# the unresolvable deny ABOVE the domain test — denying the moment a quote fails
# to close — blocks every `bash -c '… ; …'` in the workspace, because segment
# splitting hands the `-c` arm the fragment `'echo`. Arm F1-FP-cmode is that
# control and it stays green through this change: `'echo` matches no domain under
# EITHER view, so nothing is denied. The correction is to stop a truncated subject
# from EXCLUDING a token — not to remove the exclusion test.
#
# WHY ONE FUNCTION NOW. This same shape of defect has been fixed three times at
# three layers of this one rule, each fix correcting one layer's input and leaving
# the next layer deciding on the wrong thing. The three domain bodies stay
# SEPARATE (below) so an edit to one arm's domain still cannot retarget another's;
# what is shared is the subject rule, so there is one place to get it right.
script_operand_implicated() {   # $1 = interp | source | exec
  if script_operand_domain_hit "$1" "$script_norm_out"; then return 0; fi
  if [ "$script_norm_ok" -eq 0 ] \
     && script_operand_domain_hit "$1" "$script_norm_raw"; then return 0; fi
  return 1
}

# The declared operand domains, one `case` body each, carried over verbatim from
# the arms they came from. `interp` takes a shell script suffix; `source` takes ANY
# file and so carries PREFIX alternatives too; `exec` mirrors the union of the
# interpreter domains. Do NOT unify them — the shipped reasoning on each arm forbids
# it in both directions, and the bodies are adjacent here only so the subject rule
# above has a single implementation.
#
# THE `interp` BODY IS BYTE-PRESERVED, AND THAT IS THE MECHANISM RATHER THAN A
# PROMISE. Admitting the non-shell interpreters did not edit it: four SIBLING arms
# were added beside it, and script_set_interp_domain below defaults every basename
# it does not name — the shell trio included — back to `interp`. So every token
# that resolved to the `*.sh` domain before resolves to it now, by construction and
# not by argument. Editing this body is how a widening would silently narrow.
#
# WHY ONE DOMAIN PER INTERPRETER FAMILY AND NOT ONE SHARED `*.py|*.rb|…` SET. A
# shared set would adjudicate `python3 x.rb` against the Ruby suffix — a token no
# Python invocation can execute — which is the blanket-widening failure the exec
# arm's own comment argues against. The domain follows the INTERPRETER, so each
# arm claims exactly what its interpreter can run.
script_operand_domain_hit() {   # $1 = domain  $2 = subject
  case "$1" in
    interp) case "$2" in *.sh) return 0 ;; esac ;;
    interp-py) case "$2" in *.py) return 0 ;; esac ;;
    interp-pl) case "$2" in *.pl|*.pm) return 0 ;; esac ;;
    interp-rb) case "$2" in *.rb) return 0 ;; esac ;;
    interp-js) case "$2" in *.js|*.mjs|*.cjs) return 0 ;; esac ;;
    source) case "$2" in /*|./*|../*|~/*|*.sh|*.bash) return 0 ;; esac ;;
    # THE EXEC DOMAIN IS THE UNION OF THE INTERPRETER DOMAINS, WIDENED BY `*.bash`,
    # AND THE PARITY IS REQUIRED RATHER THAN TIDY. `python3 tools/x.py` and
    # `./tools/x.py` are the same execution by two spellings; adjudicating the first
    # and not the second would ship exactly the arm-to-arm asymmetry that produced
    # this rule's three prior remediations. The extensionless residual is UNCHANGED
    # — `./x` still escapes every arm — and arm T-EXEC-9 pins it.
    exec)   case "$2" in *.sh|*.bash|*.py|*.pl|*.pm|*.rb|*.js|*.mjs|*.cjs) return 0 ;; esac ;;
  esac
  return 1
}

# THE EXEC ARM'S SYSTEM-BIN EXEMPTION SET. One definition, asked twice below —
# once of the token and once of what the token resolves to. Having it in one place
# is what makes "both views, one set" readable instead of a pair of literals that
# can drift apart.
script_under_system_bin() {   # $1 = a path
  case "$1" in
    /bin/*|/usr/bin/*|/usr/local/bin/*|/opt/local/bin/*) return 0 ;;
  esac
  return 1
}

# Resolve a path the way this hook ALREADY resolves one, for the single decision
# that needs a location rather than a token.
#
# SAME PRIMITIVE AS THE Write|Edit BRANCH: `$PYTHON3` + os.path.realpath, which
# that branch documents as the portable stand-in for `realpath -m` (macOS ships no
# GNU realpath). It collapses `..` and `.`, follows symlinks, and does not require
# the path to exist.
#
# THE CALL SITES ARE DELIBERATELY NOT UNIFIED, AND THE REASON IS THE FAILURE
# DIRECTION. Write|Edit degrades gracefully when python is unavailable — it falls
# back to the raw path and keeps checking its boundary, which for a CHECK is the
# safe direction. An EXEMPTION cannot borrow that: falling back to the raw path is
# the exact defect being corrected here. So this wrapper fails CLOSED — non-zero
# and no output — and its one caller reads that as "not exempt".
script_realpath() {
  local _p="$1" _r=""
  [ -x "$PYTHON3" ] || return 1
  _r="$("$PYTHON3" -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$_p" 2>/dev/null)" \
    || return 1
  [ -n "$_r" ] || return 1
  "$PRINTF" '%s' "$_r"
}

# Is the file this token will ACTUALLY execute located under one of the exempted
# root-owned system-bin directories?
#
# WHAT THE EXEMPTION USED TO COMPARE, AND WHY IT WAS THE WRONG THING. It was a
# glob against the raw token. A token is not a location: `/usr/bin/../../tmp/
# evil.sh` matches `/usr/bin/*` and executes `/tmp/evil.sh`. The exec arm exempted
# it and never adjudicated it, while `bash /usr/bin/../../tmp/evil.sh` — the same
# file, through the other arm of the same rule — blocked. Same file, opposite
# verdicts. What this exemption governs is a FILE LOCATION, so a file location is
# what it must read.
#
# BOTH VIEWS MUST AGREE, AND THE `AND` IS THE POINT. The token test is kept as the
# ENTRY gate and the resolved test is added on top, so the predicate can only
# NARROW. Resolving FIRST and testing only the result would newly exempt things
# that never were: a relative `./usr/bin/x.sh` evaluated under `/` resolves INTO
# the set. Widening an exemption is the one direction that manufactures an allow.
#
# AN UNRESOLVABLE TOKEN IS NEVER EXEMPT — the rule the rest of this arm already
# follows. If the filename cannot be determined from argv it cannot be shown to
# live in a trusted directory, and without this the probe `/usr/bin/` left by
# `'/usr/bin/'../../tmp/evil.sh` would satisfy the entry glob on its own.
#
# STATED LIMIT — THIS SET IS NOT PORTABLE, AND NOTHING IN THIS REPO DETECTS THAT.
# The four prefixes were MEASURED `root:wheel drwxr-xr-x` on the reference host
# (Apple Silicon macOS), where `/opt/homebrew/bin` measured `drwxrwxr-x` owned by
# the operator's admin group and was removed from this set for exactly that
# reason. But `/usr/local/bin` is root-owned THERE only because Homebrew lives at
# `/opt/homebrew`. On INTEL macOS Homebrew installs into `/usr/local`, where
# `/usr/local/bin` is group-writable by `admin` — the same agent-writable
# condition that disqualified `/opt/homebrew/bin`. So on an Intel host this set
# exempts a directory the agent can write into without elevation, and no check in
# this repo measures the mode of these directories at deploy or CI time. This is
# recorded as a known limit, not solved: a runtime stat of each prefix is a
# different change carrying its own failure modes (a stat that fails, a mounted
# volume, a container with no such directory), and naming the boundary is worth
# more than a half-portable guess made inside an unrelated fix.
script_exempt_system_bin() {   # $1 = normalized token  $2 = script_norm_ok
  local _tok="$1" _ok="${2:-1}" _real=""
  [ "$_ok" -eq 1 ] || return 1
  if ! script_under_system_bin "$_tok"; then return 1; fi
  _real="$(script_realpath "$_tok")" || return 1
  if script_under_system_bin "$_real"; then return 0; fi
  return 1
}

# THE PARSE-ONLY (noexec) TABLE, KEYED ON THE INTERPRETER — NEVER ON THE FLAG.
#
# `-n` is not a parse-only flag; it is a parse-only flag FOR A POSIX SHELL.
# `perl -n` and `ruby -n` are implicit input loops that EXECUTE, `python3` has no
# `-n` at all, and `source`/`.` are builtins taking no options — a `-n` there is
# an operand, not a flag. A flag-keyed exemption would therefore turn into a hole
# the moment the adjudicated interpreter set widens. A table keyed on the
# interpreter cannot: every interpreter not named below reaches the EXPLICIT NULL
# and its behaviour is unchanged.
#
# WHERE THIS FUNCTION LIVES IS PART OF THE DESIGN. It sits with the other
# `script_*` predicates and DELIBERATELY apart from both the verb classifier and
# script_operand_implicated, because widening the interpreter set edits those two
# and must not have to move this. Widening means ADDING A `case` LABEL HERE —
# with a measured row for the new interpreter, or leaving it on the documented
# null — and nothing in the flag walk changes.
#
# RECOGNISED SPELLINGS ARE DELIBERATELY MINIMAL — the bare token `-n` only.
# Everything else falls through to today's adjudication, which is the fail-safe
# direction (still refused, never newly permitted):
#   - A CLUSTER (`-nx`) IS NOT ADMITTED. Admitting one requires proving that no
#     letter in it takes an argument; a letter that does would consume the
#     following token and change which token is the operand. `bash -nx <path>`
#     keeps blocking exactly as today. Declared residual, not an oversight.
#   - `-o noexec` IS NOT ADMITTED, and it is UNREACHABLE rather than merely
#     omitted: `-o` takes a separate argument, so the arity table below consumes
#     `noexec` AS THAT ARGUMENT and never offers it to this table as a flag. This
#     table can therefore never be asked about it. Listing it would ship a dead
#     branch on a security surface. It is recorded as listed-but-unreachable in
#     core/rules/bypass-mode-readiness/block-destructive.md.
#
# THIS TABLE IS ONLY SOUND IF THE WALK KNOWS OPTION ARITY, which is why the arity
# table below is its immediate neighbour rather than a separate concern. An
# arity-blind walk hands this table the ARGUMENT of an argument-taking option and
# asks "is this a flag": `bash --rcfile -n <path>` presents `-n`, which bash has
# already consumed as the rcfile FILENAME, and the answer "yes, parse-only" turns
# a live block into an allow on an invocation that genuinely executes <path>.
# Measured, not reasoned: `bash --rcfile -n -c 'echo X'` prints X, while
# `bash -n -c 'echo X'` prints nothing. Never widen one table without the other.
#
# Bash 3.2-safe: `case` only, no associative arrays (the file-wide constraint).
script_interp_noexec_flag() {   # $1 = interpreter basename  $2 = normalized flag token
  case "$1" in
    bash|sh|zsh)
      case "$2" in -n) return 0 ;; esac
      ;;
    *) : ;;   # EXPLICIT NULL — see the table note above. Not an omission.
  esac
  return 1
}

# THE OPTION-ARITY TABLE, KEYED ON THE INTERPRETER — the third per-interpreter
# table, beside the other two for the same reason they are beside each other:
# widening the interpreter set must mean adding a label in one place, not hunting
# three. This one answers "does this option consume the NEXT token as its
# argument".
#
# WHY THE WALK NEEDS IT AT ALL. The flag walk steps over `-*` one token at a time
# and stops on the first non-option, calling that the operand. With no notion of
# arity it is wrong in both directions on the same invocation:
#   - it can stop on an option's ARGUMENT and adjudicate that instead of the
#     script — `bash --rcfile <allowlisted> <unlisted>` adjudicated the rcfile and
#     never saw the script bash actually runs; and
#   - it can hand an option's ARGUMENT to the noexec table as though it were a
#     flag — `bash --rcfile -n <unlisted>`, where `-n` is the rcfile filename and
#     the invocation executes.
#
# THE SET IS MEASURED, NOT INFERRED, AND THE PROBE IS A SCRIPT-EXECUTION MARKER
# rather than an option-parse result. Each spelling below was swept against the
# interpreter on the reference host (bash 3.2.57, /bin/sh = bash, zsh 5.9) with
# `<interp> <opt> <sentinel> marker.sh`, where marker.sh prints M1RAN:
#   - M1RAN on stdout      => <opt> CONSUMED <sentinel> and marker.sh became the
#                             script, i.e. arity 1;
#   - <sentinel> named in  => <opt> consumed it and then REJECTED it, i.e. arity 1
#     the error message       with a validated argument namespace (`-o`, `+o`);
#   - marker.sh named in   => <sentinel> was the SCRIPT, i.e. arity 0. This third
#     the error message       case is why the probe must not be read as a mere
#                             pass/fail: `-n <sentinel> marker.sh` errors on the
#                             sentinel too, and is arity 0.
#
# AN EARLIER FORM OF THIS NOTE STATED THE PROBE AS `<interp> <opt> -n -c 'echo X'`
# PRINTS X EXACTLY WHEN <opt> CONSUMED THE `-n`. That is NOT a biconditional and it
# would drop four correct rows: `bash -O +O -o +o` DO consume the `-n` but print
# nothing, because bash then aborts with `-n: invalid shell option name` (rc=2);
# `zsh -o +o` abort the same way (rc=1). A maintainer widening this table by the
# old rule would exclude exactly the rows that are already in it. Use the marker
# form above, and read all three outcomes, not two.
#
#   bash, sh : --rcfile --init-file -O +O -o +o   (bash's own usage text names
#              `-c command`, `-O shopt_option`, `-o option` as the argument-taking
#              forms; `--rcfile=FILE` is rejected outright, so only the separate
#              -argument spelling exists and only it is listed. No long-option
#              ABBREVIATION is accepted — `--rcf`, `--init-f`, `--initfile` all
#              rc=2 — so no unlisted spelling of these two exists)
#   zsh      : -o +o --emulate                    (measured: `zsh -O -n -c …` runs
#              nothing, so zsh's `-O`/`+O` take NO argument and are correctly absent)
#
# `--emulate` IS THE ROW THAT A LETTER-BY-LETTER SWEEP MISSES, and it is listed
# because it was measured, not because zsh's own `--help` names it — it does not.
# `zsh --emulate -n -s` EXECUTES its stdin while the control `zsh -n -s` prints
# nothing, because `-n` is eaten as the emulation-mode NAME. The sweep behind this
# row enumerated zsh's full option surface — every `-X`/`+X` single letter, and
# `--<name>`, `--no<name>`, `--no-<name>`, `+-<name>`, `+-no-<name>` for all 197
# setopt names plus the 12 documented aliases, 1135 spellings in all — and found
# exactly two arity-1 spellings that execute despite a following `-n`: `--emulate`
# and `+-emulate`. Controls fired both ways (`zsh --xtrace -n marker.sh` silent,
# `zsh --emulate -n marker.sh` prints M1RAN).
#
# `+-emulate` IS PRESENT, AND AN EARLIER FORM OF THIS NOTE SAID IT WAS DELIBERATELY
# ABSENT. That exclusion was correct for the code it was written against and is now
# false, so it is replaced rather than annotated. The argument was structural: the
# walk's option arm matches `-*`, a `+`-leading token matches neither it nor the
# `--`/`-c` labels, so it fell to `*) break`, was taken as the operand, and the table
# was never consulted for it — a `+-emulate` row would have been a dead branch. THE
# `*) break` IT RESTED ON NO LONGER EXISTS: the operand walk now terminates on the
# arm's declared operand DOMAIN and ADVANCES PAST any token the domain does not
# claim, so every `+`-leading spelling reaches this table. The row is live, and so
# are the `+O`/`+o` rows above, which were kept for exactly this eventuality.
#
# THE ROW IS ALSO NO LONGER OPTIONAL, because the consequence stopped being
# inherited. `zsh +-emulate -n <path>` is BLOCK on origin/main — main advances past
# `+-emulate` and adjudicates the script, having no parse-only exemption to fool —
# and without this row the merged hook would ALLOW it. That is a BLOCK -> ALLOW on a
# shape the real shell EXECUTES: an escape INTRODUCED BY THE MERGE rather than by
# either side. Measured with controls firing: `zsh +-emulate -n -c 'echo X'` prints
# X, `zsh -n -c 'echo X'` is silent.
#
# THE `+` SURFACE WAS RE-SWEPT BEFORE THE ROW WAS ADDED, because a row is only worth
# what the sweep behind it is. 656 zsh `+` spellings (`+<letter>`, and `+-<name>`,
# `+-no<name>`, `+-no-<name>` over the live shell's own 197 `${(k)options}` plus the
# 12 documented aliases) and 89 bash/sh `+` spellings, classified by the THREE-outcome
# read this note already mandates — B-named = consumed, A-named-and-REJECTED =
# consumed against a validated namespace, A-named-and-not-found = A was the script.
# Controls fired on both readings (`--emulate`/`--rcfile` arity 1, `-x` arity 0).
# Result: `+-emulate` is the ONLY arity-1 `+` spelling zsh has beyond `+o`, and
# bash/sh have none beyond the `+O`/`+o` already listed. It is also the only one that
# leaves the shell LIVE after eating a `-n` (`+o`/`+O` abort, rc=2/rc=1).
#
# THE ZSH `--rcfile` / `--init-file` ROWS ARE DELIBERATE AND THEY ARE NOT A CLAIM
# THAT ZSH HAS THOSE OPTIONS. It does not — `zsh --rcfile …` exits "no such
# option: rcfile" and runs nothing. They are listed because the alternative is
# worse: without them the walk hands `-n` in `zsh --rcfile -n <path>` to the
# noexec table and allows the segment, which is a shipped BLOCK turned into an
# ALLOW. The verdict would then rest on "zsh will reject this invocation" — a
# second-order argument about another program's option parser, exactly the kind
# this file declines to carry two tables up. Listing them costs nothing real,
# because no zsh invocation that reaches an interpreter uses them.
#
# `-c` IS DELIBERATELY ABSENT and its absence is structural, not an omission. The
# walk's own `-c)` label runs BEFORE this one and BREAKS, handing every following
# token to the cmode loop. A `-c` row here could never be reached — a dead branch
# on a security surface, which this file refuses on principle.
#
# THE NON-SHELL INTERPRETERS REACH THE EXPLICIT NULL and their behaviour is
# unchanged. `python3 -m`, `perl -e`, `node -r` and the rest have their own arity
# and are a DECLARED RESIDUAL here: they adjudicate through the phase-gated
# destructive_022_interp_verdict, F-01's blast radius does not reach them, and
# admitting them needs its own measurement rather than a guess made inside a fix
# for the shell trio.
#
# Bash 3.2-safe: `case` only, no associative arrays (the file-wide constraint).
script_interp_optarg_flag() {   # $1 = interpreter basename  $2 = normalized flag token
  case "$1" in
    bash|sh)
      case "$2" in --rcfile|--init-file|-O|+O|-o|+o) return 0 ;; esac
      ;;
    zsh)
      case "$2" in -o|+o|--emulate|+-emulate|--rcfile|--init-file) return 0 ;; esac
      ;;
    *) : ;;   # EXPLICIT NULL — see the table note above. Not an omission.
  esac
  return 1
}

# THE OPERAND-DOMAIN TABLE, KEYED ON THE INTERPRETER — the second per-interpreter
# table, placed beside the first deliberately so the two cannot drift apart. The
# table above answers "does this interpreter's flag mean it executes nothing"; this
# one answers "what can this interpreter execute". Both are asked about the SAME
# basename the verb classifier matched, and widening the interpreter set means
# adding a label to each — one place to look, not two.
#
# THE `*)` DEFAULT IS THE WHOLE SAFETY ARGUMENT, NOT A TIDY-UP. `bash`, `sh`, `zsh`
# and every basename this table does not name resolve to `interp`, the domain they
# already resolved to when the domain was a hard-coded literal at the call sites.
# The shell arms' behaviour is therefore unchanged BY CONSTRUCTION rather than by
# assertion — the same direction the subject rule takes on
# script_operand_implicated: a new view may ADD coverage, it may never VETO it.
#
# THE SET IS CLOSED EXACT LITERALS, AND THE CLOSEDNESS IS A SAFETY PROPERTY. See
# the verb classifier below for the reason a trailing glob is refused here: the
# verb `case` runs BEFORE the exec discriminator, so a glob that accidentally
# claimed a script name (`python3.9-wrapper.sh` under `python3.[0-9]*`) would
# remove that script from exec-arm adjudication — a widening that narrows. Versioned
# spellings are a DECLARED RESIDUAL, recorded in
# core/rules/bypass-mode-readiness/block-destructive.md, not half-closed here.
#
# `awk` IS DELIBERATELY ABSENT. Its script operand arrives through `-f`, a flag
# ARGUMENT — and the arity table above names no `awk` row, so the walk still does
# not consume it and an `awk` label here could never reach its operand: a dead
# branch on a security surface. core/hooks/lib/positional-issueref.awk states the
# same boundary from the other side. Admitting `awk` now means TWO measured rows,
# one in the arity table and one here, added together — not one without the other.
#
# Bash 3.2-safe: `case` only, no associative arrays (the file-wide constraint).
script_set_interp_domain() {   # $1 = interpreter basename -> sets script_interp_domain
  case "$1" in
    python|python3) script_interp_domain="interp-py" ;;
    perl)           script_interp_domain="interp-pl" ;;
    ruby)           script_interp_domain="interp-rb" ;;
    node)           script_interp_domain="interp-js" ;;
    *)              script_interp_domain="interp" ;;   # shell trio + all else: UNCHANGED
  esac
}

# Adjudicate one candidate script path against the allowlist. Blocks (exit 2) on
# a non-allowlisted target, and blocks on an UNRESOLVABLE one: this hook sees
# unexpanded argv, so a variable-bearing path cannot be resolved here. Denying is
# the same fail-closed posture as the dependency gate above — a security control
# that cannot evaluate its input must deny, never guess.
#
# THERE ARE NOW TWO UNRESOLVABLE CLASSES AND THEY ARE SEPARATE ARGUMENTS. The
# variable-bearing one is a property of the PATH TEXT and is detected here.
# The quoting one is a property of the TOKEN the path was extracted from — by the
# time a path reaches this function the quotes are gone, so it CANNOT be detected
# here and must be carried in. $2 is that carry: 1 (the default, for the callers
# that hold a path with no token behind it) means resolved, 0 means
# normalize_script_token could not close the token's own quote and $1 is a filter
# probe rather than a filename. Defaulting to 1 keeps every existing one-argument
# call site byte-identical in behaviour.
#
# HINT ORDERING IS LOAD-BEARING, AND THE ORDER IS RETRY → WIDEN → BYPASS.
# is_script_allowlisted above matches with `case "$path" in $pattern)` — a bash
# glob against the path EXACTLY AS WRITTEN on argv. There is no realpath, no
# canonicalization, no normalization to absolute. The allowlist is overwhelmingly
# spelled in repository-relative form, so the SAME script is refused by an
# absolute path from a session worktree and permitted by its repository-relative
# path from the repository root. That retry is therefore not a workaround: it is
# the invocation the allowlist was already written to admit, and it is the move
# that most often resolves this block.
#
# The hints below used to name only allowlist-widening and the bypass variable.
# Both are worse first moves. Widening edits a security control to admit a path
# a sanctioned spelling already covers, and the bypass is an operator-only escape
# hatch that disables every rule in every hook — not one path in one rule. Naming
# them first taught blocked agents to reach for the two expensive answers and
# hid the cheap correct one, which is why the retry now leads all three strings.
#
# THE BYPASS STAYS NAMED. It is a real escape hatch and removing it would leave a
# genuinely-stuck operator with no documented route. It is ordered last and
# labelled as the operator's, not demoted out of the text.
check_script_target() {
  local path="$1" resolved="${2:-1}"
  if [ "$resolved" -eq 0 ]; then
    block "BLOCK-DESTRUCTIVE-022" \
      "unresolvable script path (quoting): the operand's quotes do not close within its own token, so the filename the shell will run cannot be determined from argv (nearest resolvable prefix: $path)." \
      "first retry the form the allowlist already permits: a fully-quoted literal path, spelled repository-relative from the repository root (bash 'core/deploy/deploy.sh'). The allowlist matches the path AS WRITTEN, so an absolute path can be refused where the identical script's repository-relative form is allowed. Only if no permitted form matches, add the resolved path to .claude/script-execution-allowlist.txt; CLAUDE_HOOK_BYPASS=1 is an operator-only escape hatch, not an agent's next step."
  fi
  case "$path" in
    *'$'*)
      block "BLOCK-DESTRUCTIVE-022" \
        "unresolvable script path (variable-bearing): $path — the hook sees unexpanded argv and cannot resolve it to an allowlist entry." \
        "first retry the form the allowlist already permits: a literal path with no variable, spelled repository-relative from the repository root. The allowlist matches the path AS WRITTEN, so an absolute path can be refused where the identical script's repository-relative form is allowed. Only if no permitted form matches, add the resolved path to .claude/script-execution-allowlist.txt; CLAUDE_HOOK_BYPASS=1 is an operator-only escape hatch, not an agent's next step."
      ;;
  esac
  if ! is_script_allowlisted "$path"; then
    block "BLOCK-DESTRUCTIVE-022" \
      "subprocess script execution not in allowlist: $path (Red Team C1 — script-laundering mitigation)." \
      "first retry the form the allowlist already permits: invoke the script by its repository-relative path from the repository root. The allowlist matches the path AS WRITTEN, so an absolute path can be refused where the identical script's repository-relative form is allowed. Only if no permitted form matches, add to .claude/script-execution-allowlist.txt (glob patterns supported); CLAUDE_HOOK_BYPASS=1 is an operator-only escape hatch, not an agent's next step."
  fi
}

# --------------------------------------------------------------------------
# BLOCK-DESTRUCTIVE-022 EXEC ARM — rollout phase, drain, and verdict router.
#
# WHAT THE ARM IS. Direct execution of a script (`./x.sh`, no interpreter token)
# carries no interpreter or `source` verb at all, so it matched no arm of this rule
# and the allowlist was never consulted — the allowlist was bypassable by making
# the file executable and dropping the interpreter word. Operator decision
# D-ScriptScope (rendered 2026-08-23) resolves that this allowlist governs
# EXECUTION CAPABILITY, not interpreter invocations only, so direct execution is
# in scope. Rollout is phased; the scope change is not.
#
# WHY A PER-RULE CONSTANT AND NOT THE SHARED `.mode`. This hook is
# mode-independent by design and its unconditional posture is the basis on which
# the mode-capable cohort was permitted to degrade at all. Coupling this arm to
# `.mode` would soften seven unrelated hooks to tune one arm of one rule.
# block-egress.sh states the same precedent for -007: the dial is a cohort
# instrument and this is a per-rule decision.
#
# WHY A 3-VALUE ENUM AND NOT A BOOLEAN. Retreat must be as cheap as advance. A
# boolean offers on/off; the enum offers a rung BELOW `warn` (`shadow`: keep
# measuring, stop emitting) so a noisy warn phase does not force a choice between
# notice-spam and going blind. Advance and retreat are each a one-word edit, and
# the edited word IS the audit record of the decision.
#
# ENTRY RUNG IS `warn`, DELIBERATELY, AND IT IS NOT A SKIPPED RUNG. The hook
# layer's own ladder is warn/enforce/off; `warn` is its entry rung. The enum
# nonetheless carries `shadow` so the cheap retreat exists.
readonly DESTRUCTIVE_022_EXEC_PHASE="warn"   # shadow | warn | enforce

# Arming date for the graduation criterion, in UTC. SELF-ARMED at the commit that
# introduced the arm — never a placeholder for a later editor to fill. The
# platform has a worked failure behind that rule: Check 48 shipped expecting a
# stamp that was never written and gated nothing for 62 releases.
#
# THE GRADUATION CRITERION IS SPLIT BY READABILITY, AND THE REPO-DERIVABLE HALF
# CARRIES THE TEETH. The evidence arm reads the drain, which is git-ignored and
# absent in a fresh checkout or CI — so nothing in the pipeline can read it, and a
# row-count criterion alone can force nothing. That is exactly why
# BLOCK-EGRESS-007's widening drain has sat at 2 rows and can never graduate on
# evidence. The DEADLINE arm reads a committed constant and today's date, so it
# works in CI and in a fresh clone. deploy.sh Check 71 is its enforcement surface:
# silent below threshold, warning at REVIEW_DAYS or REVIEW_ROWS, and at
# ESCALATE_DAYS with this phase constant unchanged it increments ISSUES so
# `--check --strict` exits 1. Doing nothing turns the pipeline red, and every way
# of turning it green is a recorded decision.
#
# RE-DATED 2026-09-03, AND THE RE-DATE IS THE RECORDED DECISION RATHER THAN AN
# INCIDENTAL EDIT. The exec arm's operand domain was widened in the same change
# that admitted the non-shell interpreters, so rows accumulated from that commit
# forward include `.py`/`.rb`/`.js`/`.pl` direct executions — traffic the original
# 2026-08-24 arming was not measuring. Check 71 names this exact remedy in its own
# failure text ("extend ONCE by re-dating"), and reading a graduation against a
# population whose composition changed underneath it is the alternative. This is
# the one extension; a second would be a decision to retreat or graduate instead.
readonly DESTRUCTIVE_022_EXEC_ARMED="2026-09-03"
readonly DESTRUCTIVE_022_EXEC_REVIEW_DAYS=60    # deadline arm — repo-derivable
readonly DESTRUCTIVE_022_EXEC_REVIEW_ROWS=25    # evidence arm — operator-local
readonly DESTRUCTIVE_022_EXEC_ESCALATE_DAYS=90  # deadline arm turns ISSUES red

# ── THE INTERPRETER ARM'S SIBLING FAMILY, AND IT IS A SIBLING RATHER THAN A REUSE.
#
# WHAT THIS ARM IS. The verb classifier admitted only `bash|sh|zsh`, so a script
# invoked through any other interpreter was never classified as an execution at
# all and no arm ever asked the allowlist about it. `python3 <path>.py` was as
# unadjudicated as `./x.sh` was before the exec arm shipped, and for the same root
# cause: an execution model expressed as a fixed vocabulary of shell tokens and
# shell suffixes. Operator decision D-ScriptScope already resolves that this
# allowlist governs EXECUTION CAPABILITY rather than interpreter invocations only,
# and a non-shell interpreter invocation is an execution capability.
#
# WHY A SEPARATE CONSTANT FAMILY AND NOT `DESTRUCTIVE_022_EXEC_*`. The two
# rollouts must be able to retreat INDEPENDENTLY. Binding this larger widening to
# the exec constant would mean a noisy reading on either forces a retreat on both,
# destroying the "retreat must be as cheap as advance" property the 3-value enum
# exists to provide. They are two widenings with two populations and two
# graduation decisions; one constant cannot record two decisions.
#
# WHY THE ENTRY RUNG IS `warn` AND NOT `enforce`. Measured at the introducing
# commit: all 289 non-comment entries in the script-execution allowlist end in
# `.sh`, so ZERO of them can ever match a `.py` path, against 72 tracked `.py`
# files. Landing this at `enforce` would refuse every one of them on day one. The
# `warn` phase is what measures the real agent-side population — which no static
# corpus survey can supply — and the allowlist rows are then added from that
# evidence rather than speculatively. `shadow` is carried for the cheap retreat if
# the first reading is as noisy as the corpus count suggests it may be.
readonly DESTRUCTIVE_022_INTERP_PHASE="warn"   # shadow | warn | enforce

# Self-armed at the commit that introduced this family — never a placeholder for a
# later editor to fill, for the reason recorded on the exec arming stamp above.
readonly DESTRUCTIVE_022_INTERP_ARMED="2026-09-03"
readonly DESTRUCTIVE_022_INTERP_REVIEW_DAYS=60    # deadline arm — repo-derivable
readonly DESTRUCTIVE_022_INTERP_REVIEW_ROWS=25    # evidence arm — operator-local
readonly DESTRUCTIVE_022_INTERP_ESCALATE_DAYS=90  # deadline arm turns ISSUES red

# Rollout telemetry for the exec arm: evaluate, record, take no action. Carries
# the CAUSE CLASS as well as the path, because an operator reading this drain must
# separate `not-allowlisted` (add an allowlist entry) from `unresolvable` (spell
# the path out literally) — conflating those two is the trap -007 was filed about.
#
# `jq -nc`: ONE object per LINE, which is what the `.jsonl` extension claims and
# what any row count depends on. This hook's existing log_block emits jq's default
# PRETTY form, spanning several lines per entry — which is why the block-log
# needed a streaming JSON parser rather than a line count. That shape is
# deliberately NOT copied here.
#
# THE `arm` FIELD, AND THE DEFECT IT CLOSES IS ONE THIS DRAIN ALREADY HAD. Before
# it, every row carried the bare reason `would-fire` and nothing naming WHICH
# widening produced it — so a reading of 1,067 rows could size the rule and could
# not apportion a single row to the arm whose graduation it was supposed to inform.
# With two phase-gated arms writing to one drain that stops being an inconvenience
# and becomes unusable: two independent graduation decisions, one undifferentiated
# population. One `--arg` makes both readable from the same file.
#
# ROWS WRITTEN BEFORE THIS CHANGE CARRY NO `arm` FIELD, and a reader must treat an
# absent field as `exec` — which is factually correct, because the exec arm was the
# only writer that existed. deploy.sh Check 71 does exactly that.
log_would_fire_022() {
  local phase="$1"
  local cause="$2"
  local path="$3"
  local arm="${4:-exec}"
  local ts
  ts="$(/bin/date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo 'unknown')"
  "$JQ" -nc --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "BLOCK-DESTRUCTIVE-022" \
    --arg tool "$TOOL_NAME" --arg phase "$phase" --arg cause "$cause" \
    --arg arm "$arm" --arg path "$path" --arg cwd "$CWD" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, phase:$phase, reason:"would-fire", arm:$arm, cause:$cause, path:$path, cwd:$cwd}' \
    >> "$WARN_LOG" 2>/dev/null || true
}

# Adjudicate one direct-execution candidate under the rollout phase.
#
# THE TWO EXISTING ARMS DO NOT ROUTE THROUGH THIS. They keep calling
# check_script_target directly, with their call sites unedited, so their verdicts
# are byte-preserved rather than argued to be equivalent. This function is reached
# only from the exec arm.
#
# An allowlisted, resolvable path returns silently and writes NOTHING. A drain
# that records permitted traffic measures the corpus rather than the widening, and
# the graduation reading would be unusable.
#
# At `enforce` the verdict is delegated to check_script_target rather than
# reimplemented, so both block messages keep exactly ONE definition in this file
# and cannot drift from the interpreter arm's. The drain keeps writing at
# `enforce` so the graduation record does not go dark at the moment it becomes the
# block record.
#
# An unrecognised phase value falls through to `enforce`. That is the same
# fail-closed direction block-egress.sh takes for -007, and deploy.sh Check 71
# validates the enum so a typo surfaces as a check finding rather than as a silent
# posture change.
destructive_022_exec_verdict() {
  local path="$1" resolved="${2:-1}"
  local cause="not-allowlisted"
  case "$path" in
    *'$'*) cause="unresolvable" ;;
  esac
  # A token whose own quote does not close is `unresolvable` for the same reason
  # a variable-bearing one is — the drain must not label it `not-allowlisted`,
  # because that sends the operator to an allowlist that can never match it.
  if [ "$resolved" -eq 0 ]; then cause="unresolvable"; fi
  if [ "$cause" = "not-allowlisted" ] && is_script_allowlisted "$path"; then
    return 0
  fi
  case "$DESTRUCTIVE_022_EXEC_PHASE" in
    shadow)
      log_would_fire_022 "shadow" "$cause" "$path" "exec"
      return 0
      ;;
    warn)
      log_would_fire_022 "warn" "$cause" "$path" "exec"
      "$PRINTF" '[CLAUDE-HOOK:%s:BLOCK-DESTRUCTIVE-022] WARN (would-block, rollout=warn, cause=%s): direct script execution %s\n' \
        "$HOOK_NAME" "$cause" "$path" >&2
      return 0
      ;;
  esac
  log_would_fire_022 "enforce" "$cause" "$path" "exec"
  check_script_target "$path" "$resolved"
}

# Adjudicate one NON-SHELL INTERPRETER operand under its own rollout phase.
#
# THE SHELL TRIO DOES NOT ROUTE THROUGH THIS, and that is the same discipline the
# exec router states one function above. `bash`, `sh`, `zsh`, `source` and `.` keep
# calling check_script_target directly from their unedited call-site branch, so
# their always-enforce verdicts are byte-preserved rather than argued to be
# equivalent. That unconditional posture is the basis on which the mode-capable
# hook cohort was permitted to degrade at all; softening it as a side effect of
# admitting python would be the one change this widening must not make. The
# `[ "$script_interp_domain" = "interp" ]` test at each call site is what enforces
# it, and it is a positive test for the shipped domain rather than a negative test
# against a list that could grow.
#
# An allowlisted, resolvable path returns silently and writes NOTHING — a drain
# that records permitted traffic measures the corpus rather than the widening.
#
# At `enforce` the verdict is delegated to check_script_target rather than
# reimplemented, so this arm cannot grow a second block message that drifts from
# the interpreter arm's. An unrecognised phase value falls through to `enforce`,
# the same fail-closed direction the exec router takes, and deploy.sh Check 71
# validates the enum so a typo surfaces as a check finding rather than as a silent
# posture change.
destructive_022_interp_verdict() {   # $1 = path  $2 = resolved
  local path="$1" resolved="${2:-1}"
  local cause="not-allowlisted"
  case "$path" in
    *'$'*) cause="unresolvable" ;;
  esac
  if [ "$resolved" -eq 0 ]; then cause="unresolvable"; fi
  if [ "$cause" = "not-allowlisted" ] && is_script_allowlisted "$path"; then
    return 0
  fi
  case "$DESTRUCTIVE_022_INTERP_PHASE" in
    shadow)
      log_would_fire_022 "shadow" "$cause" "$path" "interp-nonshell"
      return 0
      ;;
    warn)
      log_would_fire_022 "warn" "$cause" "$path" "interp-nonshell"
      "$PRINTF" '[CLAUDE-HOOK:%s:BLOCK-DESTRUCTIVE-022] WARN (would-block, rollout=warn, cause=%s): non-shell interpreter script execution %s\n' \
        "$HOOK_NAME" "$cause" "$path" >&2
      return 0
      ;;
  esac
  log_would_fire_022 "enforce" "$cause" "$path" "interp-nonshell"
  check_script_target "$path" "$resolved"
}

# ADJUDICATE A TOKEN THE FLAG WALK CONSUMED AS AN OPTION'S ARGUMENT.
#
# WHY CONSUMING IS NOT ENOUGH, AND THIS FUNCTION IS THE WHOLE DIFFERENCE. Teaching
# the walk arity moves an option's argument out of the operand slot. If the walk
# merely STEPPED OVER it, that token would leave adjudication altogether — and the
# walk's own NET DIRECTION rule forbids exactly that: it may never move a token
# out of a domain that claimed it, because that converts a shipped BLOCK into an
# ALLOW. `bash --rcfile <unlisted>.sh <allowlisted>.sh` blocks today on the rcfile,
# and it must keep blocking: an rcfile is a file bash SOURCES, so a non-allowlisted
# one is exactly what this rule exists to refuse.
#
# So the argument is consumed for OPERAND SELECTION and still adjudicated here,
# through the identical pair of calls the post-walk operand branch makes. No token
# is dropped BY THE CONSUMPTION STEP ITSELF, and the true operand — previously
# unreachable behind the argument — is adjudicated as well.
#
# THE CHANGE IS NOT "PURELY ADDITIVE", AND AN EARLIER FORM OF THIS COMMENT SAID IT
# WAS. The claim was "Direction: ALLOW may become BLOCK, never the reverse — that
# is the property to check any edit to this function against", and it is FALSE as
# stated. Changing which token is the operand necessarily changes post-walk
# ROUTING: when an option's argument is `-c` or `--`, the walk's own labels no
# longer see it, so a segment that used to route through the cmode loop — which
# adjudicates every remaining token — now routes through the single-operand branch,
# and later tokens do leave adjudication. Measured against the pre-arity hook over
# 4775 payloads: 64 ALLOW -> BLOCK, 15 BLOCK -> ALLOW, the rest unchanged. An
# independent dev-testing differential over a different 4183-payload set measured
# 154 and 23. Two sets, same mechanism, no other.
#
# THE PROPERTY THAT IS TRUE, AND THE ONE TO CHECK ANY EDIT AGAINST, IS NARROWER:
# every BLOCK -> ALLOW this function causes must be a PRECISION IMPROVEMENT — a
# verdict the real interpreter agrees with — and never an escape. That has to be
# checked against the interpreter, not argued from the code. Every measured
# instance holds: the shape either aborts in the real shell (`-c: invalid shell
# option name`, rc=1/2) or is genuinely inert (`bash --rcfile -c -n <script>`:
# rc=0, no output) or executes exactly the token this walk does adjudicate
# (`bash --rcfile -c <a> <b>` runs <a>).
#
# DO NOT "FIX" THIS BY DECLINING TO CONSUME `--` AND `-c`. It restores the literal
# additive claim and opens a real hole — `bash --rcfile -- -c <script>` executes
# <script>. The arity step carries the measurement and the counter-example.
#
# A token that claims no arm's operand domain (`-o noexec`, `-O expand_aliases`)
# falls through the gate and adjudicates nothing, exactly as it does anywhere else
# in this file. The gate, not a special case, is what keeps a shell-option NAME
# from being treated as a path.
script_adjudicate_optarg() {   # $1 = raw argv token consumed as an option argument
  normalize_script_token "$1"
  if script_operand_implicated "$script_interp_domain"; then
    if [ "$script_interp_domain" = "interp" ]; then
      check_script_target "$script_norm_out" "$script_norm_ok"
    else
      destructive_022_interp_verdict "$script_norm_out" "$script_norm_ok"
    fi
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

# --------------------------------------------------------------------------
# HERE-DOCUMENT PRE-PASS (POSIX Shell Command Language 2.7.4)
#
# A here-document BODY is the INPUT DATA a redirection supplies to a command. It
# is not command text, and the shell never parses it as a command list. That is a
# GRAMMAR fact about where command text can appear — the same class of authority
# this file already relies on at 2.9.1 for the assignment-prefix walk and at
# 2.9.1.1 for the exec discriminator — not a property of what the body says. No
# markdown fence, no "report"-like phrasing and no CLI flag name enters the
# decision below, because every one of those is forgeable by anything that can
# print one.
#
# WHY A PRE-PASS AND NOT A BRANCH IN THE SEGMENT LOOP. A body is delimited by
# TRUE NEWLINES in the original command, and the splitter replaces `;`, `&` and
# `|` with newlines BEFORE the loop runs — so by the time the loop sees text the
# line structure is already gone. `gh … <<'E' ; echo done` puts `echo done` on
# the OPERATOR's own line, where POSIX runs it before the body begins; after
# `;` → newline it is indistinguishable from the first body line. Detecting
# bodies inside the loop would therefore fail OPEN on exactly that shape. Running
# this pass on the original text makes the hazard unreachable.
#
# WHAT IT REMOVES. Only bodies that PROVABLY CANNOT be evaluated, under the SAME
# two conditions the quoted-fragment suppression below already states (see THE
# INVARIANT there), extended over one further construct:
#
#  (1) CARRIER — the command RECEIVING the redirection is in the existing
#      `gh|printf|echo|jq` set. For a here-document the question is "does not
#      execute its STDIN" rather than "cannot evaluate its ARGUMENT"; for these
#      four the answers coincide (`gh` and `jq` read stdin as data, `printf` and
#      `echo` ignore it), so the VALUE is reused unchanged. The MEMBERSHIP
#      CRITERION is now the CONJUNCTION of both tests, and an editor adding a
#      member must satisfy both — a verb that cannot evaluate its argument but
#      DOES execute its stdin would be a fail-open here while remaining sound
#      below. `bash <<'EOF'` is what this condition exists to refuse: bash reads
#      its PROGRAM from stdin, so that body genuinely executes.
#  (2) CONSTRUCT-INERT — the delimiter is QUOTED (`'D'`, `"D"`, `\D`), which
#      suppresses every expansion in the body; or it is BARE and the body
#      contains neither `$` nor a backtick. That is the identical two-tier split
#      already applied to `'…'` versus `"…"`, and it rests on the identical
#      claim: every expansion is introduced by one of those two characters. If a
#      future shell adds a third introducer BOTH suppressions break together,
#      which is the right coupling — it is one claim, not two.
#
# The receiving command is resolved from the text between the last SEPARATOR at
# quote-state 0 and the operator, not from the head of the line. `gh x ; bash
# <<'E'` must resolve to `bash`, not to `gh`; reading the line head would hand a
# real interpreter's stdin the carrier's exemption.
#
# ALL-OR-NOTHING, BY DESIGN. If ANY here-document in the command fails either
# condition, NOTHING is excised and the caller latches script_qbail — so every
# shape this model declines keeps its PRE-CHANGE VERDICT BIT-FOR-BIT, rather than
# being handed a partially-rewritten text whose verdict nobody measured. The same
# latch covers every shape the model cannot RESOLVE: an unterminated body, a
# delimiter outside the accepted word charset, more than two here-documents
# queued on one line, more than eight in a command, more than 500 lines, or the
# work budget.
#
# WHAT NEWLY PASSES, EXACTLY: the body of a here-document whose delimiter is
# quoted, or is bare with a body free of `$` and backtick, redirected into `gh`,
# `printf`, `echo` or `jq`. Nothing else. The RESIDUAL is that naming a carrier
# verb gets that body unadjudicated — which is NOT a new residual. It is exactly
# the one the quoted-argument suppression below already carries and ships:
# `gh … --body 'note; bash <x>.sh'` is allowed today by the same reasoning. This
# extends that residual's SURFACE from quoted arguments to here-document bodies;
# it does not change its KIND, its precondition (impersonating a carrier) or its
# fail direction. That is the honest cost, and it is why the carrier set is
# reused at its current value rather than widened: a missing entry costs a false
# positive and can never admit an evasion.
# --------------------------------------------------------------------------

# A delimiter word this model will accept: a non-empty run of [A-Za-z0-9_.-].
# Anything else — a delimiter bearing `$`, a backtick, or any other expansion
# character — is a shape the model declines, and declining latches the bail.
script_hd_delim_ok() {
  case "$1" in
    "") return 1 ;;
    *[!A-Za-z0-9_.-]*) return 1 ;;
    *) return 0 ;;
  esac
}

# Walk $COMMAND left to right, honouring quote state so a `<<` inside a quoted
# span is TEXT and not an operator, and excise the provably-inert bodies.
# Sets script_hdstripped (the text the splitter consumes) and script_hdbail.
script_heredoc_prescan() {
  script_hdstripped="$COMMAND"
  script_hdbail=0

  # FAST PATH. No `<<` anywhere means no here-document and no here-string, so the
  # adjudicated text is $COMMAND byte-for-byte and nothing below can perturb it.
  # This is what keeps every command that carries no such operator — the
  # overwhelming majority — on exactly its pre-change code path.
  case "$COMMAND" in
    *'<<'*) : ;;
    *) return 0 ;;
  esac

  local _lt='<' _sc=';' _amp='&' _bar='|'
  local -a _lines _qdelim _qquoted _qstrip _qhead
  local _tmp="" _opline="" _cmp="" _pre="" _ch=""
  local _delim="" _delimline="" _body="" _bodyraw="" _headtxt=""
  local _n=0 _i=0 _k=0 _qn=0 _qs=0 _work=0 _pos=0 _lastsep=0 _abs=0
  local _total=0 _excised=0 _found=0 _quoted=0 _strip=0 _ex=0 _out=""

  # Split into PHYSICAL lines. Bodies are newline-delimited, so the line is the
  # unit this pass reasons in.
  _tmp="$COMMAND"
  while [ -n "$_tmp" ]; do
    if [ "$_n" -ge 500 ]; then script_hdbail=1; return 0; fi
    case "$_tmp" in
      *$'\n'*) _lines[$_n]="${_tmp%%$'\n'*}"; _tmp="${_tmp#*$'\n'}" ;;
      *)       _lines[$_n]="$_tmp"; _tmp="" ;;
    esac
    _n=$(( _n + 1 ))
  done

  while [ "$_i" -lt "$_n" ]; do
    _opline="${_lines[$_i]}"
    _i=$(( _i + 1 ))
    _qn=0
    _pos=0
    _lastsep=0
    script_qt="$_opline"

    # ---- scan this line for here-document operators at quote-state 0 ----
    while [ -n "$script_qt" ]; do
      _work=$(( _work + 1 ))
      if [ "$_work" -ge 2000 ]; then script_hdbail=1; return 0; fi

      if [ "$_qs" -eq 1 ]; then
        script_qnext "$script_q1"
        if [ "$script_qi" -lt 0 ]; then break; fi
        _pos=$(( _pos + script_qi + 1 )); script_qt="${script_qt:$(( script_qi + 1 ))}"
        _qs=0
      elif [ "$_qs" -eq 3 ]; then
        script_qnext "$script_bs" "$script_q1"
        if [ "$script_qi" -lt 0 ]; then break; fi
        _ch="$script_qc"
        _pos=$(( _pos + script_qi + 1 )); script_qt="${script_qt:$(( script_qi + 1 ))}"
        if [ "$_ch" = "$script_bs" ]; then
          _pos=$(( _pos + 1 )); script_qt="${script_qt:1}"
        else
          _qs=0
        fi
      elif [ "$_qs" -eq 2 ]; then
        script_qnext "$script_bs" "$script_q2"
        if [ "$script_qi" -lt 0 ]; then break; fi
        _ch="$script_qc"
        _pos=$(( _pos + script_qi + 1 )); script_qt="${script_qt:$(( script_qi + 1 ))}"
        if [ "$_ch" = "$script_bs" ]; then
          _pos=$(( _pos + 1 )); script_qt="${script_qt:1}"
        else
          _qs=0
        fi
      else
        script_qnext "$script_bs" "$script_q1" "$script_q2" "$_lt" "$_sc" "$_amp" "$_bar"
        if [ "$script_qi" -lt 0 ]; then break; fi
        _pre="$script_qpre"
        _ch="$script_qc"
        _abs=$(( _pos + script_qi ))
        _pos=$(( _abs + 1 )); script_qt="${script_qt:$(( script_qi + 1 ))}"
        if [ "$_ch" = "$script_bs" ]; then
          _pos=$(( _pos + 1 )); script_qt="${script_qt:1}"
        elif [ "$_ch" = "$script_q1" ]; then
          # A `'` directly preceded by `$` opens ANSI-C quoting, exactly as in
          # script_qadvance. Reading it as a plain single quote would end one
          # quote out of phase and report *inside* where bash is *outside*.
          _qs=1
          case "$_pre" in
            *"$script_qd") _qs=3 ;;
          esac
        elif [ "$_ch" = "$script_q2" ]; then
          _qs=2
        elif [ "$_ch" = "$_sc" ] || [ "$_ch" = "$_amp" ] || [ "$_ch" = "$_bar" ]; then
          # A separator OUTSIDE any quote starts a new simple command, so the
          # receiving command of any operator after it is resolved from here.
          _lastsep="$_pos"
        else
          # `<`. Three distinct constructs share the character.
          case "$script_qt" in
            '<<'*)
              # `<<<` is a HERE-STRING: one word, already covered by the quote
              # model. Recognised FIRST — reading it as `<<` plus a delimiter of
              # `<` would corrupt the scan. (The latch this replaces globbed
              # `*'<<'*`, which matched here-strings too; part of why it was
              # over-broad.)
              _pos=$(( _pos + 2 )); script_qt="${script_qt:2}"
              ;;
            '<'*)
              # `<<` or `<<-`: a here-document redirection operator.
              _pos=$(( _pos + 1 )); script_qt="${script_qt:1}"
              _strip=0
              case "$script_qt" in
                '-'*) _strip=1; _pos=$(( _pos + 1 )); script_qt="${script_qt:1}" ;;
              esac
              while :; do
                case "$script_qt" in
                  ' '*|$'\t'*) _pos=$(( _pos + 1 )); script_qt="${script_qt:1}" ;;
                  *) break ;;
                esac
              done
              _quoted=0
              _delim=""
              case "$script_qt" in
                "$script_q1"*)
                  _quoted=1
                  script_qt="${script_qt:1}"; _pos=$(( _pos + 1 ))
                  case "$script_qt" in
                    *"$script_q1"*) _delim="${script_qt%%"$script_q1"*}" ;;
                    *) script_hdbail=1; return 0 ;;
                  esac
                  _pos=$(( _pos + ${#_delim} + 1 ))
                  script_qt="${script_qt:$(( ${#_delim} + 1 ))}"
                  ;;
                "$script_q2"*)
                  _quoted=1
                  script_qt="${script_qt:1}"; _pos=$(( _pos + 1 ))
                  case "$script_qt" in
                    *"$script_q2"*) _delim="${script_qt%%"$script_q2"*}" ;;
                    *) script_hdbail=1; return 0 ;;
                  esac
                  _pos=$(( _pos + ${#_delim} + 1 ))
                  script_qt="${script_qt:$(( ${#_delim} + 1 ))}"
                  ;;
                "$script_bs"*)
                  # `<<\D`: the backslash quotes the delimiter, so the body
                  # performs no expansion, exactly as `'D'` does.
                  _quoted=1
                  script_qt="${script_qt:1}"; _pos=$(( _pos + 1 ))
                  _delim="${script_qt%%[!A-Za-z0-9_.-]*}"
                  case "$script_qt" in
                    [!A-Za-z0-9_.-]*) _delim="" ;;
                  esac
                  _pos=$(( _pos + ${#_delim} ))
                  script_qt="${script_qt:${#_delim}}"
                  ;;
                *)
                  _delim="${script_qt%%[!A-Za-z0-9_.-]*}"
                  case "$script_qt" in
                    [!A-Za-z0-9_.-]*) _delim="" ;;
                  esac
                  _pos=$(( _pos + ${#_delim} ))
                  script_qt="${script_qt:${#_delim}}"
                  ;;
              esac
              if ! script_hd_delim_ok "$_delim"; then script_hdbail=1; return 0; fi
              if [ "$_qn" -ge 2 ]; then script_hdbail=1; return 0; fi
              _qdelim[$_qn]="$_delim"
              _qquoted[$_qn]="$_quoted"
              _qstrip[$_qn]="$_strip"
              _qhead[$_qn]="${_opline:$_lastsep:$(( _abs - _lastsep ))}"
              _qn=$(( _qn + 1 ))
              ;;
            *)
              # A plain `<` input redirection. Already consumed; nothing to do.
              :
              ;;
          esac
        fi
      fi
    done

    _out="${_out}${_opline}"$'\n'

    # ---- consume the queued bodies, in operator order ----
    _k=0
    while [ "$_k" -lt "$_qn" ]; do
      _delim="${_qdelim[$_k]}"
      _quoted="${_qquoted[$_k]}"
      _strip="${_qstrip[$_k]}"
      _headtxt="${_qhead[$_k]}"
      _body=""
      _bodyraw=""
      _delimline=""
      _found=0
      while [ "$_i" -lt "$_n" ]; do
        _cmp="${_lines[$_i]}"
        _delimline="${_lines[$_i]}"
        _i=$(( _i + 1 ))
        if [ "$_strip" -eq 1 ]; then
          while :; do
            case "$_cmp" in
              $'\t'*) _cmp="${_cmp:1}" ;;
              *) break ;;
            esac
          done
        fi
        if [ "$_cmp" = "$_delim" ]; then _found=1; break; fi
        _bodyraw="${_bodyraw}${_delimline}"$'\n'
        _body="${_body}${_delimline}"
      done
      # An unterminated body is a shape the model cannot resolve.
      if [ "$_found" -eq 0 ]; then script_hdbail=1; return 0; fi

      _total=$(( _total + 1 ))
      if [ "$_total" -gt 8 ]; then script_hdbail=1; return 0; fi

      _ex=0
      script_resolve_head "$_headtxt"
      case "${script_head##*/}" in
        gh|printf|echo|jq)
          if [ "$_quoted" -eq 1 ]; then
            _ex=1
          else
            case "$_body" in
              *"$script_qd"*|*"$script_qbt"*) _ex=0 ;;
              *) _ex=1 ;;
            esac
          fi
          ;;
      esac

      if [ "$_ex" -eq 1 ]; then
        _excised=$(( _excised + 1 ))
        _out="${_out}${_delimline}"$'\n'
      else
        _out="${_out}${_bodyraw}${_delimline}"$'\n'
      fi
      _k=$(( _k + 1 ))
    done
  done

  # No here-document operator at quote-state 0 — every `<<` in this command was a
  # here-string or quoted text. Nothing to excise, and nothing to decline.
  if [ "$_total" -eq 0 ]; then return 0; fi

  # ALL-OR-NOTHING: one declined body means the whole command keeps its
  # pre-change text and the caller latches the bail.
  if [ "$_excised" -ne "$_total" ]; then script_hdbail=1; return 0; fi

  script_hdstripped="${_out%$'\n'}"
  return 0
}

# Resolve the command word of a segment into script_head (empty when the segment
# has none), using the POSIX 2.9.1 prefix walk: a simple command is
# `prefix* word suffix*`, and a prefix is a variable assignment. An assignment
# prefix must not change either the carrier answer or the verb answer.
#
# DELIBERATE ASYMMETRY with the verb walk in the main loop, which ALSO steps over a
# bounded set of command-wrapper words (`sudo`, `env`, `exec`, …). This walk does
# not, and the two are NOT to be harmonized: they fail in opposite directions.
# Widening the VERB walk adjudicates MORE invocations — fail-closed. Widening THIS
# walk would resolve `sudo gh …` to the carrier `gh` and SUPPRESS more fragments —
# fail-open, against the suppression set's stated gating direction that a missing
# entry may only ever cost a false positive. The price of the asymmetry is exactly
# that price: a wrapper in front of a carrier verb keeps the pre-existing false
# positive on a quoted argument. Pay it here rather than on the other side.
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

    # BLOCK-DESTRUCTIVE-022 — an interpreter (bash/sh/zsh, or python/python3/perl/
    # ruby/node) with a script operand in that interpreter's suffix domain, or
    # source/. <path>, or a direct execution — not in allowlist
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

    # THE SEPARATOR SUBSTITUTION MOVED DOWN, and the move is load-bearing. It now
    # runs AFTER the here-document pre-pass, on script_hdstripped rather than on
    # $COMMAND — because the pass has to read TRUE newlines, and this substitution
    # injects newlines that are indistinguishable from them. See the pre-pass
    # header for the shape that fails OPEN when the order is reversed.

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
    # ALWAYS adjudicated.
    #
    # THAT IS NOT TRUE OF ENCLOSURE, and an earlier version of this comment said it
    # was. It claimed unquoted `$( )`, backticks and `<( )` "all land there, so they
    # need no separate rule". Measured, they do not: `$(bash <x>.sh)`,
    # `` `bash <x>.sh` ``, `cat <( bash <x>.sh )` and `echo "$(bash <x>.sh)"` are all
    # ALLOWED today. The inner command word sits at token index >= 1 of its segment,
    # where the command-position walk never looks — a substitution is not a
    # SEPARATOR, so it never starts a new segment and the inner word never reaches
    # command position. (Adding a `;` inside the substitution blocks, but only
    # incidentally: the separator shreds the substitution into a fresh segment.)
    # This is a live fail-open in an always-enforce arm. It is a WIDENING to close
    # and is tracked separately; the false claim is corrected here so a reader does
    # not infer coverage the code does not have. Condition (2) below is unaffected —
    # it governs what may be SUPPRESSED, and it is why `echo "$(…)"` is not.
    #
    # HERE-DOCUMENTS ARE MODELLED, by a pre-pass that runs before the separator
    # substitution and excises only PROVABLY-INERT bodies — see the
    # script_heredoc_prescan header for the construct rule, the two conditions and
    # the all-or-nothing posture. What reaches this loop is therefore either a
    # command with every body excised, or the ORIGINAL text with script_qbail
    # latched. The four declared residuals:
    #
    #   R-1 CARRIER IMPERSONATION. A shell function or alias named `gh` makes the
    #       head token a carrier while the body executes. This rule cannot see
    #       prior-turn state. NOT NEW — the quoted-argument suppression below
    #       carries the identical hole (`gh … --body 'note; bash <x>.sh'` ships
    #       allowed). The surface grows to here-document bodies; the kind, the
    #       precondition and the fail direction do not.
    #   R-2 A BARE-DELIMITER EXPANSION INTRODUCED BY NEITHER `$` NOR A BACKTICK.
    #       None exists in POSIX; this is the same claim condition (2) already
    #       makes for `"…"`, so both break together if a shell ever adds one.
    #   R-3 THE COMMAND-SUBSTITUTION FAIL-OPEN above is UNTOUCHED and remains live.
    #       The pre-pass neither creates nor widens it, and a here-document arm
    #       reading green is not evidence of its absence.
    #   R-4 A NON-CARRIER RECEIVER KEEPS THE FALSE POSITIVE. `cat <<'RPT'` still
    #       blocks. Deliberate: a missing carrier entry costs a false positive and
    #       can never admit an evasion, which is the fail direction this block
    #       demands below.
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
    #
    # MEMBERSHIP IS NOW A CONJUNCTION, because this one set gates two suppressions.
    # A member must BOTH (a) be unable to evaluate its ARGUMENT — what the quoted
    # fragment rule below asks — AND (b) not execute its STDIN, which is what the
    # here-document pre-pass asks. The four current members satisfy both, so the
    # value is shared rather than duplicated into a second set that could drift from
    # this one (keeping two matchers is what let the arms drift apart before). A
    # verb that satisfies (a) but not (b) — `cat` and `tee` do not execute stdin, but
    # any stdin-executing verb would — is a fail-open on the pre-pass while still
    # sound here, so BOTH tests must be answered before adding a member. `cat` and
    # `tee` are plausible additions that would remove the R-4 false positive; they
    # are deliberately NOT added here, because membership risk does not belong in a
    # change whose job is to narrow.
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
    # The flag walk's effective subject (raw token, or its normalized view when
    # that view is a flag outside every operand domain). Initialised for the same
    # reason as the three below: an unset read under `set -u` exits 1, and exit 1
    # is NON-blocking in the PreToolUse contract — i.e. it would fail OPEN.
    script_ftok=""
    # normalize_script_token sets all three before any reader runs. Initialised
    # anyway because an unset read under `set -u` exits 1, and exit 1 is
    # NON-blocking in the PreToolUse contract — i.e. it would fail OPEN.
    script_norm_out=""
    script_norm_raw=""
    script_norm_ok=1

    # HERE-DOCUMENT PRE-PASS. What stood here was a blunt latch —
    # `case "$COMMAND" in *'<<'*) script_qbail=1` — which switched suppression off
    # for ANY command containing `<<`, including text this loop had already
    # adjudicated correctly. It was over-broad in three separate ways: it matched a
    # `<<` inside a QUOTED argument, where the characters are text and not an
    # operator; it matched a here-STRING `<<<`, which is one word and needs no
    # model; and it disarmed the whole command for a here-document with nothing to
    # do with the quoted argument in question. Measured: `gh … --body 'note; bash
    # <x>.sh'` is ALLOWED, and the same bytes plus an unrelated trailing `<<'X'`
    # BLOCK. That is the machinery working and then being switched off.
    #
    # The pass below replaces the latch with a model of the construct and KEEPS the
    # latch for everything the model declines, so the fail-closed posture is
    # preserved for every shape it does not cover. script_qbail is reused because
    # its meaning is already "stop vouching for anything".
    script_hdstripped="$COMMAND"
    script_hdbail=0
    script_heredoc_prescan
    if [ "$script_hdbail" -eq 1 ]; then
      script_qbail=1
      script_hdstripped="$COMMAND"
    fi

    # Separator substitution, on the pre-pass output. Excised bodies are already
    # gone; a declined command reaches this line as $COMMAND verbatim.
    script_segments="${script_hdstripped//;/$'\n'}"
    script_segments="${script_segments//&/$'\n'}"
    script_segments="${script_segments//|/$'\n'}"

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
      # ARITY IS PER-ARM, AND RESOLVING IT BEFORE THE VERB IS WHAT HID DIRECT
      # EXECUTION. This guard used to require `-ge 2`, and the guard below used to
      # require an operand AFTER the verb — both applied before the verb was known.
      # A bare `./x.sh` is ONE token and failed the first outright, so the `*)
      # continue` in the verb `case` was never even the thing hiding it. Neither
      # requirement is a property of the rule: they are the interpreter and source
      # arms' operand arity, hoisted above the point where the arm is decided. The
      # order is now walk → resolve → per-arm arity, which is the order the shell
      # itself resolves a simple command in.
      #
      # BEHAVIOUR-PRESERVING FOR BOTH EXISTING ARMS, and the proof is a predicate
      # identity rather than a claim. Let n = token count and h = the assignment
      # walk's result. The old gate was (n >= 2) AND (h+1 < n); the new gate for
      # those two arms is (n >= 1) AND (h < n) AND (h+1 < n). But (h+1 < n) implies
      # both n >= 2 and h < n, so each conjunction reduces to exactly (h+1 < n) —
      # the same predicate over the same two values. The walk is a pure function of
      # the token array and is re-initialised every iteration, so moving it above
      # the arity test cannot change h. The verb `case` mutates neither h nor the
      # array, so moving (h+1 < n) below it is order-independent. The only
      # observable delta is which segments now reach a THIRD arm that did not
      # previously exist.
      [ "${#script_tokens[@]}" -ge 1 ] || continue

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
      # (everything before the FIRST `=`) is a valid shell name. A token that is
      # neither an assignment nor a listed wrapper (below) TERMINATES the run and is
      # the command word — so `a-b=1` and `--body=x` both stop the walk, and the skip
      # cannot degrade into a general "advance past any token containing `=`". The
      # two tests are ordered: `${tok%%=*}` returns the whole token when there is no
      # `=`, so the pattern test must gate it.
      #
      # A COMMAND-WRAPPER prefix is walked the same way, from a BOUNDED ENUMERATION
      # that mirrors lib/command-position.awk's PREFIX set — one set, two walks, so
      # the shared canonicalizer and this local walk cannot drift apart. `sudo bash
      # <script>`, `env bash <script>` and `then bash <script>` are the SAME operation
      # as `bash <script>`; without this the wrapper resolved as the command word, no
      # verb matched, and the invocation fell through to ALLOW with the allowlist
      # never consulted — the verdict tracking lexical position instead of the action.
      # Matched on the BASENAME, as the verb below is, so `/usr/bin/env bash <script>`
      # resolves too.
      #
      # This is NOT the denylist-of-evaluating-verbs that the earlier note here ruled
      # out, and its failure direction is the opposite one. That note was reasoning
      # about the SUPPRESSION set below, where a missed entry silently admits a real
      # execution. Here a word MISSING from the set means the wrapper resolves as the
      # command word and the invocation is simply not adjudicated — the status quo,
      # never a newly-admitted evasion — and a word wrongly IN it over-blocks, which
      # is recoverable. Membership criterion: the word must be a TRANSPARENT prefix —
      # a shell keyword, or a wrapper that execs the rest of the argv unchanged.
      #
      # Still NOT skipped, deliberately: `eval` and `timeout`. `eval` re-parses a
      # program string this lexical matcher cannot resolve (the same nested-shell
      # residual lib/command-position.awk records for `bash -c '…'`), and `timeout`
      # carries a duration operand the walk would additionally have to consume.
      # Recorded residuals, not half-closed cases.
      script_hidx=0
      script_xargs=0
      while [ "$script_hidx" -lt "${#script_tokens[@]}" ]; do
        script_ptok="${script_tokens[$script_hidx]}"
        case "$script_ptok" in
          [A-Za-z_]*=*)
            case "${script_ptok%%=*}" in
              *[!A-Za-z0-9_]*) break ;;
            esac
            script_hidx=$(( script_hidx + 1 ))
            continue
            ;;
        esac
        case "${script_ptok##*/}" in
          sudo|env|command|builtin|exec|nohup|time|xargs|then|do|else|elif|'in'|'!')
            if [ "${script_ptok##*/}" = "xargs" ]; then script_xargs=1; fi
            script_hidx=$(( script_hidx + 1 ))
            ;;
          *) break ;;
        esac
      done
      # A command word must EXIST at command position -- an all-prefix segment
      # has none. The walk can consume every token (`FOO=1` as a whole segment,
      # or a segment that is nothing but wrapper prefixes), and this is the
      # weakest predicate that keeps the dereference below in bounds under
      # `set -u`. The old `-ge 2` guard reached that dereference only
      # incidentally, via the operand requirement that has now moved to where it
      # belongs.
      [ "$script_hidx" -lt "${#script_tokens[@]}" ] || continue

      # Verb at command position. Basename match subsumes every absolute form
      # (/bin/bash, /usr/local/bin/zsh, /bin/.) that ANCHOR_PREFIX_BASH enumerated
      # explicitly, and is strictly tighter: an unlisted prefix no longer evades.
      # `source`/`.` are adjudicated HERE rather than by a second mechanism —
      # sourcing executes the file's contents in the current shell, which is the
      # same execution capability the interpreter arm guards, not a lesser one.
      #
      # THREE ARMS. The first two match on the BASENAME and are unedited — same
      # subject expression, same patterns, same verbs — so any token that resolved
      # to `interp` or `source` before resolves to it now. The third arm is the
      # `*)` fallthrough, and it is deliberately the LAST branch: `/bin/bash` and
      # `/bin/.` both contain a slash, and they must keep resolving to their own
      # arms rather than being captured by the exec discriminator.
      #
      # THE EXEC DISCRIMINATOR IS THE SHELL'S OWN. POSIX Shell Command Language
      # 2.9.1.1: a command name containing at least one slash is executed as a
      # pathname; otherwise the shell performs a PATH search. So the slash IS the
      # execute-this-file test, and using anything else here (a suffix test, an
      # exec-bit stat, a prefix allowlist) would be a proxy for it. This is the
      # same grammar authority the assignment-prefix walk above already cites, not
      # a second one. It also excludes every PATH-resolved utility — `ls`, `git`,
      # `grep` — by construction, which is what keeps the widening from
      # degenerating into "adjudicate every command".
      #
      # NORMALIZATION IS NO LONGER SCOPED TO THE EXEC BRANCH, AND THIS COMMENT USED
      # TO SAY THE OPPOSITE. It read: "the two arms above read a basename against a
      # fixed verb set and must not [normalize]. Normalizing their subject would
      # newly resolve `"bash" x.sh` to the interpreter arm — a tightening, but a
      # behaviour change to a shipped arm, which this slice must not make." That was
      # a correct description of a DEFERRAL, and it was recorded as though it were a
      # boundary. The deferral has since been decided the other way: `"bash" <script>`
      # and `'sh' <script>` are ordinary shell spellings that execute exactly what the
      # unquoted spellings execute, and a rule that adjudicates one and not the other
      # is one quote away from being no rule at all. The prior wording is kept here
      # rather than deleted, because a reader who remembers it needs to know it was
      # reversed deliberately — the same reason the exec arm's scope reversal is
      # recorded rather than silently replaced.
      #
      # THE RAW VIEW STILL DECIDES FIRST, AND IT IS UNCHANGED. The normalized view is
      # asked ONLY when the raw basename matched no verb, so every token that resolved
      # to `interp` or `source` before resolves to it now, by construction. This is the
      # SUBJECT RULE from script_operand_implicated applied one layer up: a second view
      # of a token may ADD coverage, it may never VETO it.
      #
      # AND IT COSTS THE EXEC ARM NOTHING — provable, not asserted. A token only
      # reaches the new view if its NORMALIZED BASENAME is exactly one of the verb
      # literals: `bash`, `sh`, `zsh`, `python`, `python3`, `perl`, `ruby`, `node`,
      # `source` or `.`. THE PROOF IS RE-ARGUED FOR THE NEW MEMBERS RATHER THAN
      # INHERITED: none of the five added literals carries `.sh`, `.bash`, `.py`,
      # `.pl`, `.pm`, `.rb`, `.js`, `.mjs` or `.cjs` either, so no such token could
      # ever have satisfied the exec arm's operand domain even after that domain was
      # widened to the union — the exec arm never returned a verdict and never wrote
      # a drain row for any of them. Arm F1-QVERB-ctl-exec is the control — a quoted
      # NON-verb command word must still reach exec and still flag.
      #
      # ORDER IS LOAD-BEARING, UNCHANGED: the exec discriminator stays LAST, so
      # `/bin/bash` and `/bin/.` keep resolving to their own arms rather than being
      # captured by the slash test. The quoted absolute spelling `"/bin/bash"` is why
      # that matters here: it missed the raw verb set AND was then exempted by the exec
      # arm's system-bin set, so the interpreter binary itself carried its operand past
      # both arms (arm F1-QVERB-abs).
      #
      # AND IT IS WHY THE INTERPRETER SET IS CLOSED EXACT LITERALS RATHER THAN A GLOB.
      # This `case` runs BEFORE the exec discriminator and SUPPRESSES it on a match.
      # A trailing glob per family — `python3.[0-9]*` for the versioned spellings —
      # also matches a SCRIPT named `python3.9-wrapper.sh`, which would classify as an
      # interpreter, stop being its own adjudicated subject, and turn a direct
      # execution the exec arm adjudicates today into an ALLOW. A widening whose
      # implementation NARROWS is strictly worse than the residual it closes, and
      # nothing here asserts that an arbitrary `.sh` name is not a verb, so it would
      # be silent. Versioned spellings stay a DECLARED RESIDUAL; the safe way to close
      # them is an order change running a slash-bearing token's exec test first, which
      # is the operand-walk's neighbourhood and not this one's.
      script_verb=""
      script_word=""
      # THE INTERPRETER BASENAME THE CLASSIFIER DECIDED ON, captured at the two
      # points below that already compute one, so script_interp_noexec_flag is
      # asked about the same token this `case` matched rather than re-deriving it
      # downstream from a view the classifier did not use. Reset per segment,
      # beside script_verb, so a previous segment's interpreter cannot leak into
      # this one's parse-only decision.
      script_interp_base=""
      # THE OPERAND DOMAIN THIS SEGMENT ADJUDICATES AGAINST — the interpreter's
      # answer to "what can I execute", resolved once here and read at the three
      # call sites below instead of a literal `interp`. Reset per segment beside
      # script_interp_base, for the same leak reason.
      #
      # THE DEFAULT IS `interp`, WHICH IS WHAT MAKES THE SHELL ARMS UNCHANGED. Every
      # path that reaches a call site without a classified interpreter — and every
      # basename script_set_interp_domain does not name, the shell trio included —
      # reads the same `*.sh` domain the call sites used to name literally.
      script_interp_domain="interp"
      case "${script_tokens[$script_hidx]##*/}" in
        bash|sh|zsh|python|python3|perl|ruby|node)
                     script_verb="interp"; script_interp_base="${script_tokens[$script_hidx]##*/}"
                     script_set_interp_domain "$script_interp_base" ;;
        source|.)    script_verb="source"; script_interp_domain="source" ;;
      esac
      if [ -z "$script_verb" ]; then
        normalize_script_token "${script_tokens[$script_hidx]}"
        # AN UNRESOLVABLE TOKEN HAS NO KNOWABLE BASENAME, so it is not asked. When
        # script_norm_ok=0 `$script_norm_out` is a strict PREFIX, and a prefix can
        # name a verb the whole token does not (`'bash'x` probes to `bash`). Reading
        # it would route a token to an arm on evidence that does not identify it —
        # the exact subject error this block exists to stop, in the other direction.
        # That leaves the unresolvable-verb spelling a declared residual, stated in
        # core/rules/bypass-mode-readiness/block-destructive.md rather than half-closed.
        if [ "$script_norm_ok" -eq 1 ]; then
          case "${script_norm_out##*/}" in
            bash|sh|zsh|python|python3|perl|ruby|node)
                         script_verb="interp"; script_interp_base="${script_norm_out##*/}"
                         script_set_interp_domain "$script_interp_base" ;;
            source|.)    script_verb="source"; script_interp_domain="source" ;;
          esac
        fi
      fi
      # EXEC ARM (the former `*)` branch of the verb `case`). Its body is carried
      # over at its ORIGINAL indentation deliberately: re-indenting it would rewrite
      # ~60 unchanged lines and bury this change's three real edits in the diff.
      # `normalize_script_token` has already run above — reaching here requires the
      # raw verb test to have declined, which is the branch that calls it.
      if [ -z "$script_verb" ]; then
          script_word="$script_norm_out"
          case "$script_word" in
            # THIS SET IS NOT ANCHOR_PREFIX_BASH'S, AND THE DIVERGENCE IS THE
            # POINT. It used to be — adopted verbatim "so this file keeps ONE
            # definition of system bin" — and that reuse was a defect, because the
            # two uses ask INVERTED security questions. Where ANCHOR_PREFIX_BASH
            # originates, the prefix identifies the INTERPRETER BINARY being
            # invoked: a trusted-SOURCE question, and listing a directory there
            # only widens what the anchor recognises as a command start (it can
            # add coverage, never remove it). HERE the prefix exempts the
            # EXECUTION TARGET from adjudication: an untrusted-TARGET question,
            # where listing a directory REMOVES coverage. One list cannot answer
            # both, and sharing it silently exported an anchor-widening decision
            # into the exemption set.
            #
            # THE PREDICATE THIS SET ANSWERS: can the agent write into the
            # directory without elevation? If it can, "system bin" is not a
            # trust statement about the target — the agent could place the script
            # there itself, which is precisely the script-laundering route -022
            # exists to close. Measured on the reference host:
            #   /bin /usr/bin /usr/local/bin /opt/local/bin  drwxr-xr-x root:wheel
            #   /opt/homebrew/bin                            drwxrwxr-x <user>:admin
            # `/opt/homebrew/bin` is group-writable by an admin user and so is
            # agent-writable without elevation — `/opt/homebrew/bin/x.sh` executed
            # directly was never adjudicated while `bash /opt/homebrew/bin/x.sh`
            # was blocked. It is therefore REMOVED here. Arm `F1-EXEC-homebrew`
            # asserts the removal; arms `F1-EXEC-ctl-*` assert the four that
            # remain keep their exemption, so this is a narrowing and not a
            # rewrite.
            #
            # ANCHOR_PREFIX_BASH ITSELF IS DELIBERATELY UNCHANGED. Other rules in
            # this file depend on it in its original trusted-source role, where
            # dropping a prefix would narrow a matcher rather than an exemption —
            # the opposite of the direction intended here.
            #
            # `/sbin` and `/usr/sbin` stay absent, unchanged: adding them would
            # WIDEN the exemption, and neither is a script-laundering route an
            # agent reaches.
            #
            # THE PREFIX BELOW IS AN ENTRY GATE, NOT THE VERDICT. Matching it only
            # asks the question; script_exempt_system_bin answers it on the
            # RESOLVED path, because a token that merely starts with an exempted
            # prefix can execute a file anywhere (`/usr/bin/../../tmp/evil.sh`).
            # That function also carries the STATED PORTABILITY LIMIT of this set
            # — it is measured on an Apple Silicon host and `/usr/local/bin` is
            # agent-writable on Intel macOS, which nothing here detects.
            /bin/*|/usr/bin/*|/usr/local/bin/*|/opt/local/bin/*)
              if script_exempt_system_bin "$script_word" "$script_norm_ok"; then
                continue
              fi
              # Not exempt after resolution. Every token reaching this arm holds a
              # slash, so this is the same verdict the `*/*` branch below would
              # have reached — the exemption is declined, not re-routed.
              script_verb="exec"
              ;;
            */*) script_verb="exec" ;;
            *)
              # SAME SUBJECT RULE AS script_operand_implicated, one layer up. This
              # branch asks "is the command word a pathname" — POSIX 2.9.1.1's
              # slash test — and when the token did not resolve, `$script_word` is
              # a PREFIX that can have lost the slash entirely (`''/tmp/evil.sh`
              # probes to the empty string). Ask the raw argv token too, so a
              # truncated view cannot exclude a pathname execution.
              #
              # [SCOPED ADDITION — flagged for Stage 9.] This is the exec-side twin
              # of the ITEM 1 defect, inside the same `case` this change already
              # edits. It is included rather than left because shipping a known
              # instance of the defect being fixed, in the statement being fixed,
              # is how this rule reached a third remediation. Arm F1-CONCAT-exec-
              # empty pins it. Reverting it is this one branch.
              if [ "$script_norm_ok" -eq 0 ]; then
                case "$script_norm_raw" in
                  */*) script_verb="exec" ;;
                  *)   continue ;;
                esac
              else
                continue
              fi
              ;;
          esac
      fi

      # EXEC ARM. No flag walk and no operand arity: the command word IS the file
      # that executes, so there is nothing after it to resolve.
      #
      # THE OPERAND FILTER IS A SEPARATE `case`, NOT A REUSE OF EITHER ARM'S. It
      # mirrors the interpreter arm's expression, widened only by `*.bash`, and it
      # is written out here so that an edit to one arm's filter cannot silently
      # retarget another's. It is NOT the source arm's filter: borrowing that
      # would put this arm WIDER than the interpreter arm and create a fresh
      # asymmetry between arms of one rule — the mirror image of the defect the
      # normalization fix above exists to remove. Measured on the doc corpus, the
      # wider filter finds the SAME 15 real tokens while adding 10 awk/sed-fragment
      # false positives and one unresolvable hard-block, and buys only
      # extensionless-executable coverage, of which this repo has zero.
      #
      # NAMED RESIDUAL, INHERITED NOT INTRODUCED: `./x` with no extension escapes
      # this arm — and already escapes the interpreter arm, which does not
      # adjudicate `bash /tmp/evil` either. One residual across three arms,
      # recorded once, and pinned by a test so a future widening is a deliberate
      # act rather than a drift.
      # THE OPERAND FILTER STILL GATES AN UNRESOLVABLE TOKEN, and that gate is
      # still deliberate: it keeps the deny inside this arm's declared operand
      # domain instead of turning every unclosed quote at command position into a
      # verdict. WHAT CHANGED IS THE SUBJECT, NOT THE ORDER. When script_norm_ok=0
      # `$script_word` is a PREFIX of the filename and this filter is
      # suffix-anchored, so asking it about the prefix alone EXCLUDED tokens whose
      # real name ends `.sh` — `'/tmp/'evil.sh` probes to `/tmp/` and was skipped
      # outright. script_operand_implicated asks the raw argv token as well; the
      # reasoning is on that function under THE SUBJECT RULE.
      if [ "$script_verb" = "exec" ]; then
        if script_operand_implicated exec; then
          destructive_022_exec_verdict "$script_word" "$script_norm_ok"
        fi
        continue
      fi

      # PER-ARM ARITY. The interpreter and source arms take a script as an
      # OPERAND, so they need a token after the verb; the exec arm, handled above,
      # does not. This is the predicate the old pre-verb guard applied, unchanged,
      # now applied where the arm is known.
      #
      # THE CHECK ITSELF LIVES IN THE BLOCK BELOW, NOT ON A LINE OF ITS OWN HERE,
      # and that placement is load-bearing rather than stylistic. The same
      # predicate also identifies the `xargs <verb>` construct whose operand list
      # arrives on stdin, which must DENY rather than fall through. A bare
      # `|| continue` at this line would satisfy the arity requirement and, being
      # first, silently disarm that deny -- two guards on one predicate, the
      # earlier one winning. That is precisely the regression the merge of these
      # two changes produced, and the reason they are one block and not two.

      # An interpreter/source verb needs at least one operand ON ARGV to adjudicate.
      # When `xargs` was consumed by the prefix walk and no argv operand follows, the
      # operand list arrives on STDIN — which a PreToolUse hook cannot see — so the
      # executed target is UNRESOLVABLE. Deny, for the same reason check_script_target
      # denies a variable-bearing path: a control that cannot evaluate its input must
      # deny rather than guess. Falling through to `continue` here would be a silent
      # allow on the one construct the prefix walk just proved it cannot resolve.
      # With an argv operand present, `xargs <verb> <path> …` executes <path>, so the
      # ordinary adjudication below is correct and an allowlisted target still allows.
      if [ $(( script_hidx + 1 )) -ge "${#script_tokens[@]}" ]; then
        if [ "$script_xargs" -eq 1 ]; then
          block "BLOCK-DESTRUCTIVE-022" \
            "unresolvable script target: xargs feeds '${script_tokens[$script_hidx]}' from stdin, so no argv path exists for this hook to adjudicate." \
            "pass the script path on the command line (xargs <interpreter> <path> ...), or set CLAUDE_HOOK_BYPASS=1"
        fi
        continue
      fi

      # walk past flags to the first operand. `-c` takes a program STRING rather
      # than a path, so every .sh-bearing token after it is a candidate instead of
      # just one — and `-c` is meaningless for `source`, so cmode is gated on the
      # interpreter verb. Walking `-*` on the source arm is strictly TIGHTER than
      # not walking it: otherwise `. -x <path>` presents `-x` as the operand.
      #
      # THE WALK'S SUBJECT, AND WHY IT IS AN EXEMPTION RATHER THAN A MATCHER. Every
      # token this walk steps over is a token it REMOVES from adjudication, so its
      # failure direction is the exemption's, not the matcher's: it may only ever
      # NARROW. It used to test the RAW argv token, and a quoted flag does not start
      # with `-`. `bash '-x' <script>` therefore stopped the walk at `'-x'`, handed
      # `-x` to the operand adjudicator, found `-x` inside no arm's operand domain,
      # and adjudicated NOTHING — while `bash -x <script>`, one quote away and the
      # same execution, blocked. Same defect shape as the three F1 fixes above: a
      # decision taken on a token that is not the thing whose behaviour it governs.
      #
      # THE FIX IS ADDITIVE AND THE FIRST DISJUNCT IS THE OLD PREDICATE VERBATIM. A
      # raw token that already looked like a flag is still skipped, on the raw view
      # alone, before anything else runs. Only a token the old predicate REJECTED can
      # reach the second view, so nothing that was skipped stops being skipped.
      #
      # THE NEW VIEW IS GATED ON THE OPERAND DOMAIN, AND THAT GATE IS THE WHOLE
      # CORRECTION. "Normalize, then test `-*`" is the naive fix and it WIDENS the
      # exemption: `bash '-x.sh'` normalizes to `-x.sh`, which is flag-shaped AND is
      # exactly the token the interpreter arm's operand domain already claimed and
      # already blocked. Skipping it flips a shipped BLOCK to an ALLOW — the precise
      # failure two earlier remediations of this rule shipped. So a normalized token
      # is treated as a flag only when it is flag-shaped AND lands in NO arm's
      # declared operand domain: a domain claim beats a flag shape, because the arm
      # that claims the token is the arm that will adjudicate it. Arm
      # F1-QFLAG-ctl-domain is that control and was green before this change.
      #
      # AN UNRESOLVABLE TOKEN IS NEVER SKIPPED, for the reason every exemption in
      # this file already gives: a filename that cannot be determined from argv
      # cannot be shown to be a flag either. It breaks the walk and becomes the
      # operand, where script_operand_implicated reads BOTH views and the
      # unresolvable deny is reachable.
      #
      # NET DIRECTION. For the FLAG-SHAPE rule immediately above, the direction is
      # one-way: a token can move from "operand that no arm claimed" to "skipped",
      # and the walk then reaches a LATER token that may be adjudicated; it can never
      # move a token out of a domain that claimed it, so that rule can only turn an
      # ALLOW into a BLOCK. The arity step added below preserves the same guarantee
      # for the token it consumes, by ADJUDICATING each argument rather than merely
      # stepping over it — consuming alone would move a claimed token out of
      # adjudication. Check any arity edit against that, first.
      #
      # THE ONE-WAY CLAIM DOES NOT EXTEND TO THE WALK'S VERDICTS AS A WHOLE, and an
      # earlier form of this note over-reached by saying it did. Arity changes WHICH
      # TOKEN IS THE OPERAND, and that changes post-walk ROUTING: when an option's
      # argument is `-c` or `--`, the walk's own labels no longer see it and a
      # segment that used to route through the cmode loop — which adjudicates every
      # remaining token — now routes through the single-operand branch. Measured
      # against the pre-arity hook over 4775 payloads: 55 ALLOW -> BLOCK and 12
      # BLOCK -> ALLOW. The property that actually binds is stated on
      # script_adjudicate_optarg: every BLOCK -> ALLOW must be a PRECISION
      # improvement the real interpreter agrees with, never an escape — and that is
      # checked against the interpreter, not argued from this code.
      script_idx=$(( script_hidx + 1 ))
      script_cmode=0
      # Is the interpreter in a parse-only mode AS OF THE LAST OPTION TOKEN SEEN?
      # Not "was a parse-only flag ever present" — the shells resolve this mode
      # last-one-wins, so the walk carries the RUNNING state and each stepped-over
      # token reassigns it (see the `-*)` arm). Reset per segment beside
      # script_cmode; read once, after the walk, together with it. 0 is both the
      # initial value and the fail-safe one: it exempts nothing.
      script_noexec=0
      while [ "$script_idx" -lt "${#script_tokens[@]}" ]; do
        script_ftok="${script_tokens[$script_idx]}"
        case "$script_ftok" in
          -*) ;;   # raw view already decides — unchanged, and asked first
          *)
            normalize_script_token "$script_ftok"
            if [ "$script_norm_ok" -eq 1 ]; then
              case "$script_norm_out" in
                -*)
                  # THE DOMAIN, NOT THE VERB. `$script_verb` is the three-value
                  # CLASS (interp | source | exec); the domain is what the
                  # interpreter can execute, and those stopped being the same thing
                  # when the non-shell interpreters were admitted. Asking the class
                  # here would test a `-`-normalizing token under `python3` against
                  # the SHELL suffix set and find no claim, skipping a token the
                  # Python domain claims — the exemption widening this walk's own
                  # comment forbids.
                  if ! script_operand_implicated "$script_interp_domain"; then
                    script_ftok="$script_norm_out"
                  fi
                  ;;
              esac
            fi
            ;;
        esac
        # THE TERMINATION PREDICATE IS THE ARM'S OWN DECLARED OPERAND DOMAIN, not
        # "the first token that is not flag-shaped". Answering "where is the operand?"
        # with "the first non-flag token" is wrong in two independent ways, and both
        # land in the same place: a token that is NOT the operand becomes the
        # adjudicated operand, fails the arm's operand-domain test, and the arm
        # concludes the invocation is not its business -- reaching ALLOW WITHOUT THE
        # ALLOWLIST EVER BEING CONSULTED.
        #
        #   (1) A PLUS-FORM option is not matched by `-*`, so it fell to `*)` and the
        #       OPTION ITSELF became the operand:      bash +x <script>
        #   (2) An option taking a SEPARATE argument was skipped by `-*`, its value is
        #       not dash-prefixed, so THE VALUE became the operand:
        #                                              bash -o errexit <script>
        #
        # The controls are what made this a defect rather than a boundary: an option
        # that takes NO separate argument leaves the real operand in place, so
        # `bash -x <script>` blocked while `bash -o errexit <script>` allowed. Two
        # spellings of one execution, one checked and one not. It also DISARMED the
        # variable-bearing fail-closed deny — `bash -o errexit "$DIR/x.sh"` reached
        # ALLOW while the bare spelling denied — so a documented fail-closed posture
        # was bypassable by prefixing any value-taking flag.
        #
        # WHY A DOMAIN TEST AND NOT AN ARITY TABLE. A per-interpreter "which flags take
        # an argument" table FAILS OPEN on omission: one unenumerated value-taking flag
        # leaves its argument unconsumed, the argument lands outside the domain, nothing
        # is adjudicated, ALLOW — the exact defect above, re-entering through the fix.
        # That is the denylist construction this rule's own doc already forbids inside a
        # fail-closed control. The domain test has nothing to omit: `+x`, `errexit`,
        # `extglob`, an rcfile path are all simply NOT THE OPERAND, and the walk keeps
        # looking. It needs no arity knowledge and no plus-form enumeration.
        #
        # AN UNRESOLVABLE TOKEN IS NEVER SKIPPED, AND THAT CLAUSE IS NOT OPTIONAL. It is
        # this file's own doctrine (stated above and on script_exempt_system_bin) applied
        # to a new arm: ADVANCING PAST a token is an exemption in exactly the sense
        # SKIPPING one is, so it inherits the same rule -- a filename that cannot be
        # determined from argv cannot be shown not to be the operand either. Without the
        # clause the walk advances off `'/tmp/pmo` (whitespace splitting hands it the
        # first fragment of a space-bearing quoted path) onto a LATER fragment and
        # adjudicates the wrong subject; arm F1-QTOK-RESIDUAL-space is that control and
        # it turns red, which is how the clause was found.
        #
        # NET DIRECTION -- MONOTONE ALLOW->BLOCK BY CONSTRUCTION, which is the property
        # to check any edit to this arm against. If the old first-non-flag token WAS
        # domain-claimed, the new walk stops at the same token and behaviour is
        # identical. If it was NOT domain-claimed, the old code adjudicated nothing and
        # no block was possible. So this can only turn an ALLOW into a BLOCK, never the
        # reverse. It introduces no new exemption.
        #
        # DECLARED RESIDUAL (R1), pinned by F2-FWALK-RESIDUAL-flagarg: a value-taking
        # flag whose ARGUMENT is itself an allowlisted script path still hides the real
        # operand, because the scan legitimately terminates on that argument. This is a
        # strict NARROWING of the prior hole -- today any value-taking flag hid the
        # script unconditionally; now the caller must additionally name an allowlisted
        # path in flag position. Closing it is the one job an arity overlay would be
        # right for, and layered ON TOP of this walk its failure direction inverts back
        # to safe (an omitted flag falls through to the domain test, not to an
        # unguarded ALLOW).
        #
        # THE DOMAIN ARGUMENT IS THE ONE TOKEN A SUCCESSOR CHANGE MUST RE-POINT. This
        # arm asks script_operand_implicated for the domain of `$script_verb` because
        # on this revision the verb class and the operand domain are the same three
        # values. A successor change that SPLITS interpreter DOMAIN from verb CLASS
        # (per-interpreter operand suffix sets) must re-point this ONE argument to that
        # domain variable, or a non-shell interpreter's real script is tested against
        # the SHELL suffix set, found unclaimed, walked past, and silently
        # under-adjudicated -- a fail-open re-introduced by an otherwise clean merge.
        case "$script_ftok" in
          --) script_idx=$(( script_idx + 1 )); break ;;
          -c)
            if [ "$script_verb" = "interp" ]; then script_cmode=1; fi
            script_idx=$(( script_idx + 1 )); break ;;
          -*)
            # PARSE-ONLY DETECTION — AN ASSIGNMENT OF THE *CURRENT EFFECTIVE STATE*,
            # NOT A LATCH. Asked of the INTERPRETER, about the same token the walk is
            # about to skip (raw when the raw view decided, normalized when it did not
            # — script_ftok already carries whichever view won above). The skip itself
            # is UNCHANGED: this records the mode the interpreter is in and adjudicates
            # nothing on its own.
            #
            # WHY AN ASSIGNMENT. `noexec` is a shell MODE, and every shell in the table
            # resolves mode options LAST-ONE-WINS. An earlier form of this block set the
            # flag to 1 on first sight and never cleared it, so a later token that turns
            # noexec back OFF left the hook believing the invocation was parse-only while
            # the interpreter EXECUTED the operand. Measured on the reference host with a
            # runtime-assembled marker (so `-v`/`-x` echoing the source cannot forge it):
            #   bash -n +n /dev/stdin        -> marker prints   (EXECUTES)
            #   bash -n +o noexec /dev/stdin -> marker prints   (EXECUTES)
            #   zsh  -n +-noexec /dev/stdin  -> marker prints   (EXECUTES)
            #   bash -n /dev/stdin           -> silent          (control: really inert)
            # Reading "was a set-spelling ever seen" answers a question the shell does
            # not ask. Reading the LAST token to speak answers the one it does.
            #
            # THE REVOCATION IS DELIBERATELY NOT A CLEARING TABLE, and that asymmetry is
            # the whole design. A table of clear-spellings symmetric to the set-table
            # fails OPEN on omission: one unlisted way of writing "noexec off" leaves the
            # parse-only claim standing and the segment is exempted while it runs — the
            # identical failure direction `3f364a59` cited when it refused an arity table
            # as the TERMINATION predicate. Parse-only status is granted ONLY by positive
            # recognition in script_interp_noexec_flag and is REVOKED BY EVERY TOKEN THE
            # WALK STEPS OVER, whatever it is spelled.
            #
            # THE GUARANTEE IS SCOPED TO STEPPED-OVER TOKENS, AND AN EARLIER FORM OF THIS
            # NOTE OVERSTATED IT. It said "there is nothing to omit" and "a spelling this
            # file has never seen cannot produce a parse-only verdict; it can only cost an
            # over-block" — unqualified, of the whole predicate. That holds for every token
            # the walk STEPS OVER and FAILS for a token the walk ENDS ON, because the
            # revoke sits below both breaks (see the advance-past arm below). For a token
            # that ends the walk an earlier grant SURVIVES, and what keeps that safe is
            # OPERAND ADJUDICATION, not this predicate. State the property that way and it
            # is decidable per token; state it unqualified and it is simply false.
            #
            # THE BOUNDARY HAS ONE LIVE FAMILY, AND IT IS INHERITED, NOT INTRODUCED HERE.
            # A token whose leading quote closes early — `""+n`, `''+n`, `'+'n`, `"-"n` —
            # is marked unresolvable by normalize_script_token, so it breaks at the
            # script_norm_ok test ABOVE the revoke and an earlier `-n` grant stands:
            #   bash -n ""+n <unlisted>.sh  -> ALLOW  (the shell runs it; `""+n` IS `+n`)
            #   bash -n   +n <unlisted>.sh  -> BLOCK  (same invocation, unquoted)
            # The same family ALLOWs on `origin/main`, so this release introduces none of
            # it, and the shape that proves WHERE the allow comes from carries no `-n` at
            # all: `bash ""-x <unlisted>.sh` ALLOWs on `origin/main` and here alike. The
            # cause is the unresolvable-operand path, not noexec. A symmetric clear on that
            # break is therefore MEASURABLY INERT — it was built and measured and the shape
            # still ALLOWs — so it is deliberately NOT shipped: it would add a fourth
            # enumeration and close nothing. Arms NOEXEC-QSPLIT-* pin the family and
            # NOEXEC-QSPLIT-M* pins the inertness; closing it is the operand path's job.
            #
            # FAIL-SAFE DIRECTION, PER BRANCH. Recognised set-spelling -> 1 (exempt) is
            # the ONLY path to parse-only, and it is exactly today's measured row. Every
            # other token THE WALK STEPS OVER -> 0, which does not allow anything: it
            # routes the segment into the ordinary allowlist adjudication below. Within
            # that class, unknown means REFUSED, never EXEMPT. A token the walk ENDS ON is
            # outside the class and does not revoke — deliberately, per the advance-past
            # arm — so there "unknown" leaves the prior state standing and the operand
            # adjudication below is what decides.
            #
            # THE CONSUMED ARGUMENT OF AN ARITY OPTION NEEDS NO REVOCATION OF ITS OWN,
            # and that is a property of the two tables rather than an assumption: every
            # member of script_interp_optarg_flag (`--rcfile --init-file -O +O -o +o
            # --emulate +-emulate`) is absent from script_interp_noexec_flag (`-n`), so
            # the option ALWAYS revokes before its argument is consumed. `bash -n -o
            # noexec <script>` is revoked by `-o`, not by `noexec`. Adding an
            # argument-taking option to the noexec table would break that and is why the
            # two tables are neighbours.
            if [ "$script_verb" = "interp" ]; then
              if script_interp_noexec_flag "$script_interp_base" "$script_ftok"; then
                script_noexec=1
              else
                script_noexec=0   # M-NOEXEC-REVOKE (mutation target; pinned by NOEXEC-M1)
              fi
            fi
            script_idx=$(( script_idx + 1 ))
            # OPTION ARITY — the one thing this walk did not know. It stepped over
            # `-*` a token at a time and called the first non-option the operand,
            # so an option that takes a SEPARATE argument left that argument in the
            # operand slot. Two failures, one cause:
            #   `bash --rcfile <allowlisted> <unlisted>` adjudicated the rcfile and
            #     never saw the script bash runs — an unlisted script admitted; and
            #   `bash --rcfile -n <unlisted>` offered `-n` to the noexec table as a
            #     FLAG, when bash had taken it as the rcfile FILENAME, so the
            #     parse-only exemption above fired on an invocation that executes.
            # Consuming the argument closes both, because the walk then continues
            # to the token the interpreter will really run.
            #
            # ORDER IS LOAD-BEARING: the argument is consumed AFTER the noexec test
            # of its own option and BEFORE the next iteration, so it is never itself
            # offered to the noexec table. That is the half that closes the second
            # failure, and reordering these two blocks reopens it.
            #
            # THE ARGUMENT IS STILL ADJUDICATED — see script_adjudicate_optarg for
            # why that is required rather than tidy. Consuming without adjudicating
            # would move a token out of a domain that claimed it, which is the one
            # direction the NET DIRECTION note above forbids for this step.
            #
            # `-c` cannot reach here AS THE OPTION (its own label breaks the walk
            # above), and a trailing option with no argument left on argv is bounded
            # by the index test rather than reading past the end.
            #
            # THE ARGUMENT IS CONSUMED UNCONDITIONALLY, INCLUDING WHEN IT IS `--` OR
            # `-c`, AND DECLINING THOSE TWO WAS TRIED AND IS WRONG. Consumption
            # happens before the walk's own `--)` and `-c)` labels can see the token,
            # so when an arity option's argument is literally `-c` the cmode flag
            # stays 0 where it previously became 1 and the post-walk route changes
            # from the cmode loop to the single-operand branch. That is a REAL change
            # in verdicts and it is not one-directional — see the NET DIRECTION note
            # above, which is corrected accordingly. Declining to consume the two
            # tokens looks like the tidy fix and it opens a hole:
            #
            #   bash --rcfile -- -c <script>   EXECUTES <script>. Measured, with an
            #     executable marker: rc=0 and the marker prints. `--` is the rcfile
            #     FILENAME, not an end-of-options marker, and `-c` is a real
            #     command-mode flag. If the walk declines `--`, its `--)` label
            #     breaks the walk and takes `-c` as the operand — a token that claims
            #     no domain — and the whole segment is ALLOWED. Consuming keeps the
            #     segment blocked. This shape is ALLOW on the pre-arity hook, BLOCK
            #     here, and ALLOW again under a decline: declining re-opens it.
            #
            #   bash --rcfile -c -n <script>   is genuinely INERT (measured: rc=0, no
            #     output), and bash --rcfile -c <a> <b> runs <a> — precisely the
            #     token the operand branch adjudicates. Declining `-c` turns both of
            #     those correct verdicts back into over-blocks.
            #
            # So `--` and `-c` are consumed like any other argument, because that is
            # what the interpreter does with them in this position.
            if [ "$script_verb" = "interp" ] \
               && [ "$script_idx" -lt "${#script_tokens[@]}" ] \
               && script_interp_optarg_flag "$script_interp_base" "$script_ftok"; then
              script_adjudicate_optarg "${script_tokens[$script_idx]}"
              script_idx=$(( script_idx + 1 ))
            fi
            ;;
          *) # M-FWALK-ADVANCE - mutation target (AC4; pinned by AC-D022-M1)
            # THE ADVANCE-PAST ARM AND THE SKIP ARM ARE ONE JUDGEMENT, SO THEY MUST
            # ASK THE TOKEN THE SAME QUESTIONS. `3f364a59` replaced `*) break` with a
            # domain test, and the reason it gives is that a token the domain does not
            # claim is NOT THE OPERAND — which is the same statement the `-*)` arm above
            # makes about a token it skips. Once the walk ADVANCES PAST a token here,
            # that token is an option by the walk's own reasoning, and an option whose
            # arity is never asked leaves its ARGUMENT in the stream. The `-*)` arm asks;
            # this one did not, and the whole `+`-leading surface reaches only this arm.
            #
            # THAT ASYMMETRY IS AN EXECUTION HOLE AND IT IS THIS MERGE THAT OPENS IT.
            # Neither side has it alone. `origin/main` advances past `+-emulate` and then
            # adjudicates the script, because main has no parse-only exemption to fool.
            # This branch never advances past `+-emulate` at all, because `*) break` took
            # it as the operand. Combine them — main's advance plus this branch's
            # parse-only exemption — and `zsh +-emulate -n <unlisted>.sh` walks past
            # `+-emulate`, hands the FOLLOWING `-n` to the noexec table as a flag, and
            # exempts a segment the real shell EXECUTES. Measured, controls firing:
            # `zsh +-emulate -n -c 'echo X'` prints X while `zsh -n -c 'echo X'` is
            # silent, because `+-emulate` eats the `-n` as the emulation MODE NAME.
            # Asking arity here is what closes it, and it closes the CLASS rather than
            # that one spelling.
            #
            # THIS IS THE OVERLAY `3f364a59` NAMED, NOT A SPECIAL CASE BESIDE IT. That
            # commit rejected an arity table as the TERMINATION predicate because such a
            # table fails OPEN on omission, and said in the same breath that closing its
            # declared residual R1 "is the one job an arity overlay would be right for,
            # and layered ON TOP of this walk its failure direction inverts back to safe
            # (an omitted flag falls through to the domain test, not to an unguarded
            # ALLOW)". That is exactly the shape here: the domain test still decides where
            # the walk STOPS, and arity only decides how far it STEPS. An arity row this
            # table omits costs an over-block, never an exemption. Both properties are
            # kept; neither side wins.
            #
            # THE DOMAIN ARGUMENT IS RE-POINTED, AND `3f364a59` ASKED FOR THAT BY NAME.
            # Its note says a successor that SPLITS interpreter DOMAIN from verb CLASS
            # "must re-point this ONE argument to that domain variable, or a non-shell
            # interpreter's real script is tested against the SHELL suffix set, found
            # unclaimed, walked past, and silently under-adjudicated -- a fail-open
            # re-introduced by an otherwise clean merge." This branch IS that successor:
            # script_interp_domain exists here and does not exist on main, so main's
            # `$script_verb` would test `python3 <path>.py` against the `*.sh` set. Taking
            # main's arm verbatim is the fail-open it predicted. Arm FWALK-DOM-py is that
            # control.
            #
            # NOEXEC IS NEVER *GRANTED* HERE, AND IS ALWAYS *REVOKED* HERE. An earlier
            # form of this note said noexec is "deliberately not asked here" and stopped
            # there; that was right about the direction it refused and silent about the
            # one it owed. Both halves follow from the same observation it already makes.
            #
            #   GRANT — still refused, unchanged. A noexec question that could answer YES
            #   on a `+` token would CREATE an inertness claim and move BLOCK -> ALLOW on
            #   an unmeasured surface. `+n` is "turn noexec OFF", the exact inversion, so
            #   a symmetric widening would be wrong on its most obvious member.
            #
            #   REVOKE — owed, and its absence was the defect. That same sentence says a
            #   `+` token can turn noexec OFF; a walk that steps over one while still
            #   holding a parse-only claim from an earlier `-n` reports inert on an
            #   invocation the shell RUNS. `bash -n +n <script>` and `zsh -n +-noexec
            #   <script>` reach ALLOW that way, and the whole `+` surface arrives only at
            #   this arm. Revoking is the ALLOW -> BLOCK direction this arm already
            #   accepts for arity, so it is the same trade, not a new one.
            #
            # THE REVOKE IS UNCONDITIONAL WITHIN THIS ARM — no test, no table, nothing to
            # omit — AND THAT IS THE WHOLE OF ITS SCOPE. Anything the walk advances past
            # here is, by this arm's own reasoning, an option or an option's argument
            # rather than the operand; none of them can be a recognised parse-only
            # spelling, because those are `-`-leading and are answered by the `-*)` arm
            # above. So the honest state after stepping over one is "not known to be
            # parse-only", which is 0. It says NOTHING about a token that ENDS the walk —
            # that is the next paragraph's subject and the predicate's declared residual,
            # and reading this sentence as a property of the whole predicate is the
            # overstatement corrected at the `-*)` arm above.
            #
            # IT SITS BELOW BOTH BREAKS ON PURPOSE. A token that ENDS the walk — an
            # unresolvable token, or the domain-claimed operand — is not stepped over and
            # must not revoke, or `bash -n <script>.sh` would revoke on the script itself
            # and the card's entire value would be lost. Arms PARSE-07 and NOEXEC-CTL-01
            # pin that boundary behaviourally and NOEXEC-ORD-01 pins the LINE ORDER
            # itself, so hoisting the revoke above either break is caught as a structural
            # edit rather than only as a behavioural regression.
            #
            # AND THAT ORDERING IS EXACTLY WHERE THE PREDICATE'S GUARANTEE STOPS. The two
            # breaks above are the tokens the revoke never sees, so a grant made earlier
            # survives them; the `-*)` arm's note carries the measured residual (the
            # leading-quote-closes-early family) and the evidence that clearing here would
            # be inert. The right reading of this ordering is a declared trade — the
            # card's value in exchange for a residual the OPERAND path owns — and not a
            # claim that the predicate cannot fail open.
            normalize_script_token "${script_tokens[$script_idx]}"   # M-FWALK-BODY
            if [ "$script_norm_ok" -eq 0 ]; then break; fi
            if script_operand_implicated "$script_interp_domain"; then break; fi
            if [ "$script_verb" = "interp" ]; then
              script_noexec=0   # M-NOEXEC-REVOKE (mutation target; pinned by NOEXEC-M1)
            fi
            # The NORMALIZED view is what the arity table is asked about, because the
            # raw view is what got us here: a `+`-leading token never reaches the flag
            # normalization above, so `'+-emulate'` (quoted) would otherwise miss the
            # table and fall to the fail-OPEN side. Captured before the consumption
            # below re-normalizes into the same globals.
            script_fadv="$script_norm_out"
            script_idx=$(( script_idx + 1 ))
            if [ "$script_verb" = "interp" ] \
               && [ "$script_idx" -lt "${#script_tokens[@]}" ] \
               && script_interp_optarg_flag "$script_interp_base" "$script_fadv"; then
              script_adjudicate_optarg "${script_tokens[$script_idx]}"
              script_idx=$(( script_idx + 1 ))
            fi
            ;;
        esac
      done
      [ "$script_idx" -lt "${#script_tokens[@]}" ] || continue

      # PARSE-ONLY EXEMPTION. Under `bash -n` (and `sh`/`zsh`) the interpreter
      # PARSES and exits — it executes nothing, whatever the operand is. Inertness
      # is a property of the interpreter's MODE, fully determined by argv, so this
      # needs no path resolution and correctly covers the non-allowlisted,
      # variable-bearing and quote-unresolvable operands that otherwise hard-block.
      # The refused-but-inert case is what this rule was blocking that no arm
      # declares: a syntax check runs nothing.
      #
      # THE `-c` EXCLUSION IS BELT AND BRACES, because the two orders fail
      # differently and only one of them is closed structurally:
      #   - `bash -c 'echo hi' -n <path>` — the walk BREAKS at `-c`, so the
      #     trailing `-n` is never examined as a flag and script_noexec stays 0.
      #     That invocation genuinely executes, and the break is what keeps it
      #     refused. Structural, not asserted.
      #   - `bash -n -c '…'` — here `-n` IS seen first and does set the flag, so
      #     the structure alone would exempt it. The script_cmode conjunct below
      #     declines it. Reasoning about whether an arbitrary program string is
      #     inert under noexec is a second-order argument a security control
      #     should not carry.
      if [ "$script_noexec" -eq 1 ] && [ "$script_cmode" -eq 0 ]; then
        continue
      fi

      if [ "$script_cmode" -eq 1 ]; then
        while [ "$script_idx" -lt "${#script_tokens[@]}" ]; do
          normalize_script_token "${script_tokens[$script_idx]}"
          script_cand="$script_norm_out"
          # This loop is the reason the domain gate exists at all: under `-c` the
          # tokens are WORDS OF A PROGRAM STRING, not declared operands, and
          # segment splitting routinely hands it fragments like `'echo`. The gate
          # keeps those inert (arm F1-FP-cmode) while a fragment whose real name
          # ends `.sh` is still adjudicated.
          if script_operand_implicated "$script_interp_domain"; then
            if [ "$script_interp_domain" = "interp" ]; then
              check_script_target "$script_cand" "$script_norm_ok"
            else
              destructive_022_interp_verdict "$script_cand" "$script_norm_ok"
            fi
          fi
          script_idx=$(( script_idx + 1 ))
        done
      else
        # normalize BEFORE the filter on both verbs — a quoted path does not end in
        # `.sh` and does not start with `/`, so an unstripped quote matches no
        # pattern and falls through to ALLOW without the allowlist being consulted.
        # The domain gate still runs BEFORE the deny on an unresolvable token, so
        # each arm's deny stays inside the operand domain that arm declares — but
        # it now reads BOTH the probe and the raw argv token, because the probe is
        # a PREFIX and the interpreter arm's domain is a SUFFIX test. Asking the
        # prefix alone is what let `bash '/tmp/'evil.sh` through: probe `/tmp/`,
        # no `.sh`, arm skipped, deny never reached. See THE SUBJECT RULE on
        # script_operand_implicated.
        normalize_script_token "${script_tokens[$script_idx]}"
        script_cand="$script_norm_out"
        if [ "$script_verb" = "source" ]; then
          # `source`/`.` take ANY file, not only a script suffix. Its domain is
          # preserved verbatim from the mechanism it replaces — it lives in
          # script_operand_domain_hit's `source` body, still its own `case`. Do NOT
          # unify it with the interpreter arm's `*.sh`: narrowing silently drops
          # `/*`, `~/*` and `*.bash` coverage, and widening the interpreter arm to
          # `/*` opens a false-positive surface with no defect behind it.
          if script_operand_implicated source; then
            check_script_target "$script_cand" "$script_norm_ok"
          fi
        else
          # THE SHELL TRIO'S PATH IS THE UNEDITED ONE, AND THE BRANCH IS HOW THAT IS
          # ENFORCED RATHER THAN ASSERTED. Domain `interp` — `bash`, `sh`, `zsh` and
          # every basename script_set_interp_domain does not name — still calls
          # check_script_target directly and still blocks unconditionally. Only a
          # newly-admitted interpreter reaches the phase-gated router, so admitting
          # python cannot soften the arm that was always-enforce before it.
          if script_operand_implicated "$script_interp_domain"; then
            if [ "$script_interp_domain" = "interp" ]; then
              check_script_target "$script_cand" "$script_norm_ok"
            else
              destructive_022_interp_verdict "$script_cand" "$script_norm_ok"
            fi
          fi
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

      # SECOND -019 EXEMPTION — the git-ignored analysis workspace (#6427).
      # core/standards/analysis-workspace-standard.md §1 designates the repo-root
      # analysis/ folder as the analysis home and §2 makes each analysis ONE dated
      # SUBFOLDER; .gitignore (`/analysis/*` + `!/analysis/README.md`) ignores every
      # such subfolder and tracks README.md alone. The sanctioned location and this
      # control contradicted each other, and the session shape the standard
      # anticipates is exactly the non-worktree one this rule denies.
      #
      # TWO ARMS, AND THE ORDER IS THE GUARD. `case` takes the FIRST match:
      #
      #   Arm 1 (dot segments) matches and does NOTHING, so control falls through
      #   to `block`. It is NOT decoration. abs_target above is the RAW,
      #   UN-NORMALIZED FILE_PATH whenever the target AND its parent directory
      #   both do not exist (the else-branch of the normalizer) — and a `case`
      #   glob matches across `/`, so `<root>/pmo-platform/analysis/../core/x.md`
      #   matches arm 2's pattern while naming a TRACKED Layer-1 file. Today that
      #   path is harmless because -019 denies the whole tree; the carve-out below
      #   is what would make it an escape. The guard is required BY this change.
      #
      #   BOTH dot segments are rejected, each in a mid-path and a trailing form.
      #   `..` is the escape above. A SINGLE `.` does not traverse, but it does
      #   satisfy arm 2's `*/*` subfolder requirement on this same raw-path branch,
      #   so `<root>/pmo-platform/analysis/./README.md` would reach arm 2 and admit
      #   the one TRACKED file the subfolder segment exists to exclude. Rejecting
      #   `.` is therefore not traversal defence — it is what keeps arm 2's
      #   subfolder predicate from being satisfied by a no-op segment. A dotfile
      #   (`…/analysis/<sub>/.hidden.md`) carries `/.` but is neither `/./` nor
      #   trailing `/.`, so it is unaffected and still admitted.
      #
      #   Arm 2 requires a SUBFOLDER SEGMENT (`analysis/`*`/`*), not `analysis/`*.
      #   analysis/README.md is the one TRACKED file under this folder and the bare
      #   prefix admits it. Keying on the subfolder is the standard's own §2
      #   convention, so the predicate tracks the sanctioned shape rather than a
      #   filename exception that a future .gitignore edit would silently void.
      #
      # The pattern is ANCHORED AT THE REPO ROOT: `release/analysis/…` and
      # `.claude/worktrees/*/analysis/…` do NOT match, so this admits exactly one
      # subtree and not every directory in the tree named `analysis`.
      #
      # WHY THE PREDICATE IS STATIC, AND WHY THAT IS THE SECURITY PROPERTY. This
      # pattern lives inside .claude/hooks/*, which -019 itself protects and
      # BLOCK-AUTONOMY-001 always-blocks. An exemption authored in a surface the
      # rule's own subject can write is not an exemption, it is a widening
      # primitive: an allowlist file at .claude/<name>.txt is agent-appendable by
      # design, and `git check-ignore` answers from .gitignore / core.excludesFile,
      # which `git config --global` can re-point with no hook rule in the way.
      # Neither is admissible for the self-modification guard specifically.
      case "$abs_target" in
        *"/../"*|*/..|*"/./"*|*/.)
          ;;
        "${PRIMARY_ROOT}/pmo-platform/analysis/"*/*)
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
