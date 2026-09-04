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

# The three declared operand domains, one `case` body each, carried over verbatim
# from the arms they came from. `interp` takes a script suffix; `source` takes ANY
# file and so carries PREFIX alternatives too; `exec` mirrors `interp` widened only
# by `*.bash`. Do NOT unify them — the shipped reasoning on each arm forbids it in
# both directions, and the bodies are adjacent here only so the subject rule above
# has a single implementation.
script_operand_domain_hit() {   # $1 = domain  $2 = subject
  case "$1" in
    interp) case "$2" in *.sh) return 0 ;; esac ;;
    source) case "$2" in /*|./*|../*|~/*|*.sh|*.bash) return 0 ;; esac ;;
    exec)   case "$2" in *.sh|*.bash) return 0 ;; esac ;;
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
check_script_target() {
  local path="$1" resolved="${2:-1}"
  if [ "$resolved" -eq 0 ]; then
    block "BLOCK-DESTRUCTIVE-022" \
      "unresolvable script path (quoting): the operand's quotes do not close within its own token, so the filename the shell will run cannot be determined from argv (nearest resolvable prefix: $path)." \
      "invoke with a fully-quoted literal path (bash '/abs/path.sh'), or add the resolved path to .claude/script-execution-allowlist.txt, or set CLAUDE_HOOK_BYPASS=1"
  fi
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
# BLOCK-DESTRUCTIVE-022 EXEC ARM — rollout phase, drain, and verdict router.
#
# WHAT THE ARM IS. Direct execution of a script (`./x.sh`, no interpreter token)
# carries no `bash`/`sh`/`zsh`/`source` verb, so it matched no arm of this rule
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
readonly DESTRUCTIVE_022_EXEC_ARMED="2026-08-24"
readonly DESTRUCTIVE_022_EXEC_REVIEW_DAYS=60    # deadline arm — repo-derivable
readonly DESTRUCTIVE_022_EXEC_REVIEW_ROWS=25    # evidence arm — operator-local
readonly DESTRUCTIVE_022_EXEC_ESCALATE_DAYS=90  # deadline arm turns ISSUES red

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
log_would_fire_022() {
  local phase="$1"
  local cause="$2"
  local path="$3"
  local ts
  ts="$(/bin/date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo 'unknown')"
  "$JQ" -nc --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "BLOCK-DESTRUCTIVE-022" \
    --arg tool "$TOOL_NAME" --arg phase "$phase" --arg cause "$cause" \
    --arg path "$path" --arg cwd "$CWD" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, phase:$phase, reason:"would-fire", cause:$cause, path:$path, cwd:$cwd}' \
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
      log_would_fire_022 "shadow" "$cause" "$path"
      return 0
      ;;
    warn)
      log_would_fire_022 "warn" "$cause" "$path"
      "$PRINTF" '[CLAUDE-HOOK:%s:BLOCK-DESTRUCTIVE-022] WARN (would-block, rollout=warn, cause=%s): direct script execution %s\n' \
        "$HOOK_NAME" "$cause" "$path" >&2
      return 0
      ;;
  esac
  log_would_fire_022 "enforce" "$cause" "$path"
  check_script_target "$path" "$resolved"
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
      # reaches the new view if its NORMALIZED BASENAME is exactly `bash`, `sh`, `zsh`,
      # `source` or `.`. None of those carries a `.sh` or `.bash` suffix, so no such
      # token could ever have satisfied the exec arm's operand domain: the exec arm
      # never returned a verdict and never wrote a drain row for any of them. Arm
      # F1-QVERB-ctl-exec is the control — a quoted NON-verb command word must still
      # reach exec and still flag — and it was green before this change.
      #
      # ORDER IS LOAD-BEARING, UNCHANGED: the exec discriminator stays LAST, so
      # `/bin/bash` and `/bin/.` keep resolving to their own arms rather than being
      # captured by the slash test. The quoted absolute spelling `"/bin/bash"` is why
      # that matters here: it missed the raw verb set AND was then exempted by the exec
      # arm's system-bin set, so the interpreter binary itself carried its operand past
      # both arms (arm F1-QVERB-abs).
      script_verb=""
      script_word=""
      case "${script_tokens[$script_hidx]##*/}" in
        bash|sh|zsh) script_verb="interp" ;;
        source|.)    script_verb="source" ;;
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
            bash|sh|zsh) script_verb="interp" ;;
            source|.)    script_verb="source" ;;
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
      # NET DIRECTION, which is the property to check any edit against: a token can
      # move from "operand that no arm claimed" to "skipped", and the walk then
      # reaches a LATER token that may be adjudicated. It can never move a token out
      # of a domain that claimed it. So the change can only turn an ALLOW into a
      # BLOCK, never the reverse.
      script_idx=$(( script_hidx + 1 ))
      script_cmode=0
      while [ "$script_idx" -lt "${#script_tokens[@]}" ]; do
        script_ftok="${script_tokens[$script_idx]}"
        case "$script_ftok" in
          -*) ;;   # raw view already decides — unchanged, and asked first
          *)
            normalize_script_token "$script_ftok"
            if [ "$script_norm_ok" -eq 1 ]; then
              case "$script_norm_out" in
                -*)
                  if ! script_operand_implicated "$script_verb"; then
                    script_ftok="$script_norm_out"
                  fi
                  ;;
              esac
            fi
            ;;
        esac
        case "$script_ftok" in
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
          normalize_script_token "${script_tokens[$script_idx]}"
          script_cand="$script_norm_out"
          # This loop is the reason the domain gate exists at all: under `-c` the
          # tokens are WORDS OF A PROGRAM STRING, not declared operands, and
          # segment splitting routinely hands it fragments like `'echo`. The gate
          # keeps those inert (arm F1-FP-cmode) while a fragment whose real name
          # ends `.sh` is still adjudicated.
          if script_operand_implicated interp; then
            check_script_target "$script_cand" "$script_norm_ok"
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
          if script_operand_implicated interp; then
            check_script_target "$script_cand" "$script_norm_ok"
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
      #   Arm 1 (traversal) matches and does NOTHING, so control falls through to
      #   `block`. It is NOT decoration. abs_target above is the RAW, UN-NORMALIZED
      #   FILE_PATH whenever the target AND its parent directory both do not exist
      #   (the else-branch of the normalizer) — and a `case` glob matches across
      #   `/`, so `<root>/pmo-platform/analysis/../core/x.md` matches arm 2's
      #   pattern while naming a TRACKED Layer-1 file. Today that path is harmless
      #   because -019 denies the whole tree; the carve-out below is what would
      #   make it an escape. The guard is required BY this change.
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
        *"/../"*|*/..)
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
