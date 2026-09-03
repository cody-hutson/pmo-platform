#!/bin/bash
# block-fragile-refs.sh — PreToolUse hook enforcing the reference-durability standard
# hook-owner: core/standards/reference-durability-standard.md
#
# Reference-durability issue (v3.18-corpus-integrity-enforcement):
# Flags fragile references on net-new/modified content destined for durable-corpus
# paths, per core/standards/reference-durability-standard.md. Four detectors:
#   - Class L (BLOCK-FRAGILE-REF-001): markdown link sequences  ]( on a content line
#   - Class V (BLOCK-FRAGILE-REF-002): version-cutover apparatus (idiom + version token)
#   - Positional issue-reference (BLOCK-FRAGILE-REF-003): a bare #N outside a designated
#     reference block, OR a content-free #N inside one (rung-5 "summarize inline" guard)
#   - Class U (BLOCK-FRAGILE-REF-004): a raw github.com/<owner>/<repo>/{issues,pull,milestone}
#     URL (durability-ladder rung-6 — rots on any repository move); the ref-permitted
#     ledger surfaces are categorically exempt (is_ledger_exempt), all other durable
#     corpus is flagged unless the file declares the allow-url override marker
#
# Matcher scope: Write, Edit
#
# Rule ID range: BLOCK-FRAGILE-REF-001..099
#
# Pattern: mirrors core/hooks/block-skill-direct-edit.sh architecture exactly
# (PATH pinning, mode-coupled jq posture via lib/dep-resolve.sh [enforce → fail-closed
# on missing jq, warn/off → degrade], fail-closed-on-malformed-input,
# CLAUDE_HOOK_BYPASS escape hatch with audit, shared .mode file for warn/enforce/off).
#
# Detection scope rationale: the detector flags Class L + Class V wholesale and applies
# a POSITIONAL rule to issue references. It deliberately does NOT classify an issue
# reference as inline-grammar versus provenance-footnote — that classification cannot
# be separated lexically with acceptable precision. The positional rule (block-presence
# + line-self-description) is a deterministic shape test, not a semantic classifier.

set -euo pipefail

# --- PATH PINNING (tamper resistance) ---
export PATH="/usr/bin:/bin"

readonly GREP="/usr/bin/grep"
readonly PRINTF="/usr/bin/printf"
readonly DATE="/bin/date"
readonly AWK="/usr/bin/awk"
readonly SED="/usr/bin/sed"
# jq is resolved below via lib/dep-resolve.sh (once HOOK_DIR is known), from a fixed
# absolute-path allowlist — never $PATH — so the anti-hijack PATH pin still holds
# (GHSA-9cjm-v22x-4x33).

# --- METADATA ---
readonly HOOK_NAME="block-fragile-refs"
readonly HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"
readonly ERROR_LOG="${HOOK_DIR}/hook-errors.log"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"
readonly WARN_LOG="${HOOK_DIR}/fragile-ref-warn-log.jsonl"
readonly MODE_FILE="${HOOK_DIR}/.mode"
# ALLOWLIST resolves at the workspace .claude/ root — ${HOOK_DIR}/.. — which is the
# hook-tier composition-surface target and the pattern every sibling exemption list in
# this cohort uses (block-destructive, block-egress x3, block-mcp-writes,
# block-scope-segregation, block-shell-injection, block-skill-direct-edit, and
# block-fs-boundary via its CLAUDE_DIR).
#
# It deliberately does NOT resolve beside the hook. At runtime $0 is the DEPLOYED copy,
# so ${HOOK_DIR} is the deployed hooks directory and never a checkout — a hook-adjacent
# path resolves to a file that no install step writes. That was the defect: the source
# copy sat in core/hooks/, whose installer loop copies *.sh only, so the surface shipped
# nowhere and every path exemption was unreachable while the hook ran in enforce.
readonly ALLOWLIST="${HOOK_DIR}/../reference-durability-allowlist.txt"
# Shared positional-issue-ref classifier (single source of the positional decision; the
# fixture-runner and the reference-durability CI invoke this same file via `awk -f`, so
# the positional logic cannot drift across the three surfaces). Resolves beside the hook.
readonly POSITIONAL_LIB="${HOOK_DIR}/lib/positional-issueref.awk"
# Shared detector-constant declarations (the sole declaration of LINK_RE / CUTOVER_RE /
# URL_RE / REFBLOCK_RE / ISSUEREF_RE / HEXCOLOR_RE / MIN_SELFDESCRIBE_WORDS). The
# fixture-runner and the reference-durability CI source this same file, so the three
# surfaces read one set of bytes rather than three copies. Sourced below, AFTER the mode
# read and the jq gate, so its own failure posture is mode-coupled (ADR-078 D6) and so a
# jq-unresolvable layout still fails at the jq gate rather than here. Resolves beside the
# hook, like DEP_LIB and POSITIONAL_LIB.
readonly PATTERNS_LIB="${HOOK_DIR}/lib/fragile-ref-patterns.sh"

# --- MODE DETECTION (shared harness .mode; warn|enforce|off) ---
# jq-free (/bin/cat + /usr/bin/tr only), so it resolves without the dependency helper
# and is therefore defined ahead of the gate below. Extracted from the inline read that
# used to sit further down; the normalization — whitespace stripped, unrecognized value
# defaults to warn — is unchanged.
get_mode() {
  local mode="warn" raw
  if [ -f "$MODE_FILE" ]; then
    # `|| echo` makes the substitution total. The pipeline returns 1 on a present-but-
    # unreadable mode file, and this runs under `set -euo pipefail` BEFORE the ERR trap is
    # armed — measured, the hook still resolves to the default here and degrades, but only
    # via a subtle `set -e` interaction with assignment-inside-function. The fallback
    # removes the dependence on it and matches the shape the other cohort hooks already use.
    raw="$(/bin/cat "$MODE_FILE" 2>/dev/null | /usr/bin/tr -d '[:space:]' || echo warn)"
    case "$raw" in
      warn|enforce|off) mode="$raw" ;;
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

# --- SHARED DEPENDENCY RESOLVER (mode-coupled: fail CLOSED in enforce, degrade in warn/off) ---
# Test readability BEFORE sourcing: bash 3.2 (macOS system bash) exits 1 on a failed
# `.` of a missing file even inside an `if !` condition, and exit 1 (unlike exit 2) is
# NON-blocking in the PreToolUse contract — i.e. a missing helper would fail OPEN.
readonly DEP_LIB="${HOOK_DIR}/lib/dep-resolve.sh"
# Precheck syntax with `bash -n` BEFORE sourcing: a truncated/corrupt lib (interrupted
# cp, disk-full) is a parse error, and sourcing a parse-error file is FATAL to this
# parent — with partial top-level execution the process can exit 1 (NON-blocking =
# fail-OPEN) instead of blocking. `bash -n` detects that non-fatally so we fail CLOSED
# (GHSA-g9g6-28c9-vrx5). Also require deny_missing_primitive so a valid-but-stale lib
# (pre-fix, no helper) fails closed here rather than fail-open at a later ERR trap.
# Severity is mode-coupled: a rule match in warn/off would not block, so an unusable
# helper must not block harder than a match would.
if [ ! -r "$DEP_LIB" ] || ! "${BASH:-/bin/bash}" -n "$DEP_LIB" 2>/dev/null || ! . "$DEP_LIB" 2>/dev/null || ! command -v resolve_jq >/dev/null 2>&1 || ! command -v deny_missing_primitive >/dev/null 2>&1; then
  if [ "$LIB_GUARD_MODE" = "enforce" ]; then
    "$PRINTF" '[CLAUDE-HOOK:%s:LIB-MISSING] BLOCKED (fail-closed): dependency helper lib/dep-resolve.sh unavailable or invalid.\n' "$HOOK_NAME" >&2
    exit 2
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:LIB-MISSING] WARN (degraded, %s=%s): dependency helper lib/dep-resolve.sh unavailable or invalid; ALL rules for this hook are skipped this run. Reinstall the hook bundle (re-run docs/scripts/setup-workspace.sh) to restore enforcement.\n' "$HOOK_NAME" "${MODE_FILE##*/}" "$LIB_GUARD_MODE" >&2
  exit 0
fi
JQ="$(resolve_jq)"; readonly JQ

# --- THE FLAGGED-CLASS PATTERNS ---
# Declared once in lib/fragile-ref-patterns.sh (validated against
# core/hooks/testdata/cutover-fixtures.txt) and sourced below, after the mode read and the
# jq gate. Each constant's own rationale lives beside its declaration in that file.

# --- ERROR HANDLERS ---
log_error() {
  local ts
  ts="$($DATE -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo 'unknown')"
  "$PRINTF" '%s [%s] %s\n' "$ts" "$HOOK_NAME" "$1" >> "$ERROR_LOG" 2>/dev/null || true
}

trap 'rc=$?; log_error "RULE-EVAL-ERROR at line $LINENO (exit $rc)"; "$PRINTF" "[CLAUDE-HOOK:%s:HOOK-ERROR] BLOCKED: rule-evaluation error at line %s (exit %s). See %s.\n" "$HOOK_NAME" "$LINENO" "$rc" "$ERROR_LOG" >&2; exit 2' ERR

# --- READ INPUT (jq-free; stdin is consumed exactly once) ---
INPUT="$(cat)"

# --- CLAUDE_HOOK_BYPASS escape hatch — evaluated BEFORE the jq gate so it works even when
# jq is unresolvable (GHSA-9cjm-v22x-4x33: an escape hatch advertised in a fail-closed
# message must actually be reachable without jq). ---
if [ "${CLAUDE_HOOK_BYPASS:-}" = "1" ]; then
  ts="$($DATE -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  if [ -n "$JQ" ]; then
    btool="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_name // empty' 2>/dev/null || echo unknown)"
    "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg tool "$btool" \
      '{ts:$ts, hook:$hook, tool:$tool, action:"bypass"}' \
      >> "$BYPASS_LOG" 2>/dev/null || true
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

# --- MODE check (shared harness .mode; warn|enforce|off) — already resolved above the
# dependency guard and frozen readonly, so a mode-gated hook fails CLOSED only in enforce
# and stands down in off/warn. Reuse the snapshot rather than re-reading: same value, one
# fewer read, and a value the sourced helper cannot have influenced. The off short-circuit
# stays HERE — after bypass and the master-enable gate — so the precedence chain is
# unchanged. ---
MODE="$LIB_GUARD_MODE"
[ "$MODE" = "off" ] && exit 0

# --- DEPENDENCY GATE (mode-gated fail-closed: a security control that cannot evaluate its
# input must DENY in enforce — GHSA-9cjm-v22x-4x33. In warn-mode a rule match only warns, so
# a missing dependency must not block harder than a match would: degrade non-blocking. ---
if [ -z "$JQ" ]; then
  log_error "DEPENDENCY-MISSING: jq not found on the pinned tool path"
  if [ "$MODE" = "enforce" ]; then
    deny_missing_dep jq "$HOOK_NAME" "$PRINTF"
    exit 2   # caller owns the fail-closed exit — never trust the callee to terminate (GHSA-g9g6)
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:DEPENDENCY-WARN] jq not found. Reference-durability hook DEGRADED (fail-open in warn-mode). Install: brew install jq (or ensure /usr/bin/jq exists).\n' "$HOOK_NAME" >&2
  exit 0
fi

# --- DETECTOR-CONSTANT GATE (co-shipped primitive; ADR-078 D6 fail-closed posture) ---
# Every detector's pattern comes from lib/fragile-ref-patterns.sh. Verify the primitive is
# USABLE, not merely present: a present-but-empty or truncated lib sources to nothing and
# leaves the constants unset, and an EMPTY ERE matches every line — so a broken primitive
# here is not a degraded detector but an inverted one. Precheck syntax with `bash -n` BEFORE
# sourcing for the same reason DEP_LIB does: sourcing a parse-error file is fatal to this
# parent and can exit 1 (NON-blocking = fail-OPEN) instead of blocking (GHSA-g9g6-28c9-vrx5).
#
# Posture, mode-coupled like the jq gate above and the classifier gate below: in ENFORCE a
# durable-corpus write whose detectors cannot be constructed fails CLOSED. In warn/off the
# hook STANDS DOWN entirely (exit 0) rather than degrading — unlike the positional-classifier
# gate, no partial degrade exists here, because every class (L/V/U and the positional rule)
# reads its pattern from this file. Running on unset patterns would flag every line.
#
# Placed AFTER the jq gate deliberately: a layout missing both jq and this primitive must
# still fail at the jq gate, so the dependency-hardening tests that build such a layout keep
# measuring what they name.
_patterns_ok=0
if [ -r "$PATTERNS_LIB" ] && "${BASH:-/bin/bash}" -n "$PATTERNS_LIB" 2>/dev/null && . "$PATTERNS_LIB" 2>/dev/null; then
  if [ -n "${LINK_RE:-}" ] && [ -n "${CUTOVER_RE:-}" ] && [ -n "${URL_RE:-}" ] \
     && [ -n "${REFBLOCK_RE:-}" ] && [ -n "${ISSUEREF_RE:-}" ] && [ -n "${HEXCOLOR_RE:-}" ] \
     && [ -n "${MIN_SELFDESCRIBE_WORDS:-}" ]; then
    _patterns_ok=1
  fi
fi
if [ "$_patterns_ok" -eq 0 ]; then
  log_error "PRIMITIVE-MISSING-OR-INVALID: detector constants $PATTERNS_LIB unusable"
  if [ "$MODE" = "enforce" ]; then
    deny_missing_primitive "fragile-ref-patterns.sh" "$HOOK_NAME" "$PRINTF"
    exit 2   # caller owns the fail-closed exit — never trust the callee to terminate (GHSA-g9g6)
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:PRIMITIVE-MISSING] WARN (stood down, .mode=%s): co-shipped detector constants fragile-ref-patterns.sh absent or invalid; ALL reference-durability classes skipped this run.\n' "$HOOK_NAME" "$MODE" >&2
  exit 0
fi
# Restore the hook's immutability posture. The lib declares plain so it stays re-sourceable
# and overridable by a harness; the hook, which wants neither, re-asserts by bare name.
readonly LINK_RE CUTOVER_RE URL_RE REFBLOCK_RE ISSUEREF_RE HEXCOLOR_RE MIN_SELFDESCRIBE_WORDS

# --- VALIDATE INPUT ---
if ! "$PRINTF" '%s' "$INPUT" | "$JQ" -e . >/dev/null 2>&1; then
  log_error "INVALID-INPUT: malformed JSON on stdin"
  "$PRINTF" '[CLAUDE-HOOK:%s:INPUT-INVALID] BLOCKED: malformed hook input JSON.\n' "$HOOK_NAME" >&2
  exit 2
fi

TOOL_NAME="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_name // empty')"

# Only handle Write and Edit (settings.json matchers constrain, but defense-in-depth)
case "$TOOL_NAME" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

# --- Workspace-scope gate (#4436) — layer 3, AFTER the master-activation gate and
# BEFORE the .mode / rule path. Precedence: bypass -> master -> SCOPE -> .mode -> rule.
# CWD is extracted here (this hook did not previously need it) purely to feed the guard.
# Inverted fail direction on the cwd axis, NOT on the lib axis. See lib/scope-guard.sh. ---
CWD="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.cwd // empty')"
readonly SCOPE_GUARD_LIB="${HOOK_DIR}/lib/scope-guard.sh"
if [ -r "$SCOPE_GUARD_LIB" ]; then . "$SCOPE_GUARD_LIB" 2>/dev/null || true; fi
if command -v scope_guard_gate >/dev/null 2>&1; then scope_guard_gate "$CWD"; fi

FILE_PATH="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.file_path // empty')"
[ -z "$FILE_PATH" ] && exit 0

# --- SCOPE CHECK — act ONLY on durable-corpus paths ---
# Matches both absolute (worktree/primary) and repo-relative forms. Transient surfaces
# (chat, GitHub comments, operator-instance gitignored tree, PR bodies) are structurally
# out of reach — the hook only sees a Write/Edit file_path, so anything not matching a
# durable glob below exits 0 untouched.
case "$FILE_PATH" in
  */core/rules/*.md|core/rules/*.md) ;;
  */core/standards/*.md|core/standards/*.md) ;;
  */core/specs/*.md|core/specs/*.md) ;;
  */core/disciplines/*.md|core/disciplines/*.md) ;;
  */core/schemas/*.md|core/schemas/*.md) ;;
  */release/references/*.md|release/references/*.md) ;;
  */release/governance/*.md|release/governance/*.md) ;;
  */release/standards/*.md|release/standards/*.md) ;;
  */release/specs/*.md|release/specs/*.md) ;;
  */release/schemas/*.md|release/schemas/*.md) ;;
  */skills/*/SKILL.md|skills/*/SKILL.md) ;;
  */skills/*/references/*.md|skills/*/references/*.md) ;;
  */release/releases/plans/*_RELEASE_PLAN.md|release/releases/plans/*_RELEASE_PLAN.md) ;;
  *) exit 0 ;;
esac

# --- ALLOWLIST-REACHABILITY GATE (mode-coupled, mirroring the primitive gates above) ---
# Placed AFTER the durable-corpus scope gate deliberately: only a write this hook would
# actually adjudicate can be denied for an unreachable exemption surface. Anything outside
# the durable globs already exited above and is untouched by this gate.
#
# Why a gate at all. The path allowlist is the ONLY exemption mechanism for
# BLOCK-FRAGILE-REF-003 — Classes L/V/U each carry a per-file override marker, the
# positional rule carries none. So a silent skip on an absent allowlist does not degrade
# the control, it removes the sole escape from it: strictly stricter than anyone authored,
# with no signal that it happened. That is the inverse of the fail-open risk the sibling
# primitive gates guard, and it warrants the same loudness.
#
# deny_missing_primitive() is deliberately NOT reused here. Its message names a co-shipped
# primitive and prescribes docs/scripts/setup-workspace.sh, but this surface is a
# COMPOSITION SURFACE installed by update.sh — routing an operator to the hook-bundle
# reinstall would not restore it, and a wrong remediation on a lockout message is worse
# than a generic one.
# Reachability is ABSENCE, not emptiness. An allowlist with zero active entries is a
# legitimate authored state — an operator who deliberately clears it is asking for
# enforcement with no path exemptions, and denying that would override their intent. This
# is the one place the posture diverges from the three sibling gates above, and the reason
# is that they guard primitives where empty IS corrupt (an empty ERE matches every line);
# an empty exemption list is merely empty.
#
# A 0-byte file is still worth saying something about, because a truncated or interrupted
# install produces exactly that and is indistinguishable from intent by inspection. Hence
# a non-blocking note rather than a deny: visible immediately, decides nothing.
_allowlist_ok=0
if [ -f "$ALLOWLIST" ]; then
  _allowlist_ok=1
  # -qv is true when SOME line is neither comment nor blank; negated, every line is one of
  # those, i.e. no entry can ever match. Also true for a 0-byte file (grep finds no lines).
  if ! "$GREP" -qvE '^[[:space:]]*(#|$)' "$ALLOWLIST" 2>/dev/null; then
    "$PRINTF" '[CLAUDE-HOOK:%s:ALLOWLIST-EMPTY] NOTE: path allowlist at %s has zero active entries, so no path exemption can match. Deliberate, or a truncated install?\n' \
      "$HOOK_NAME" "$ALLOWLIST" >&2
  fi
fi

if [ "$_allowlist_ok" -eq 0 ]; then
  log_error "ALLOWLIST-UNREACHABLE: exemption surface $ALLOWLIST absent or unusable"
  if [ "$MODE" = "enforce" ]; then
    # Remediation-first on purpose. At the moment this prints, EVERY durable-corpus write
    # is being denied, so the reader is blocked and wants out before they want a diagnosis.
    #
    # The fix line names setup-workspace.sh FIRST, and that ordering is the whole point.
    # This message fires only when the allowlist is ABSENT, and update.sh does not create
    # an absent surface — its regenerate loop logs "Target absent … fresh install needed
    # via setup-workspace.sh" and skips it, then assert_install_complete refuses to go
    # further. So update.sh alone cannot clear this condition; it is the SECOND step, which
    # re-runs the regenerate path once the surface exists. Naming it alone would send a
    # blocked operator to a command that declines, which is the failure this very hook
    # exists to stop being silent about. deploy.sh --deploy is ruled out explicitly for the
    # same reason: it does not source composition surfaces at all.
    #
    # The recovery line exists because the failure reads like a bricked workspace and is
    # not one: the allowlist path sits outside this hook's own scope gate, so writing it
    # back is never denied by this hook.
    "$PRINTF" '[CLAUDE-HOOK:%s:ALLOWLIST-UNREACHABLE] BLOCKED (fail-closed).\nFix: run docs/scripts/setup-workspace.sh   (installs the absent surface)\n     then ./update.sh                      (regenerates it thereafter)\n     NOT deploy.sh --deploy — it does not source composition surfaces at all,\n     and update.sh ALONE will decline: it regenerates surfaces, it does not create them.\n\nWhy: the reference-durability path allowlist is absent at %s,\nso every path exemption is unreachable and this rule currently has no escape.\nRecovery is not blocked by this hook — that path is outside its durable-corpus scope.\nTo stand the hook down meanwhile: set its .mode to off.\n' \
      "$HOOK_NAME" "$ALLOWLIST" >&2
    exit 2
  fi
  # warn/off: a rule match would only warn here, so an unreachable exemption surface must
  # not block harder than a match would. Degrade and keep evaluating (the POSITIONAL_LIB
  # pattern), rather than standing the hook down entirely.
  "$PRINTF" '[CLAUDE-HOOK:%s:ALLOWLIST-UNREACHABLE] WARN (degraded, .mode=%s): path allowlist absent at %s; ALL path exemptions are unreachable this run and findings below may name paths that are supposed to be exempt.\n' \
    "$HOOK_NAME" "$MODE" "$ALLOWLIST" >&2
fi

# --- PATH ALLOWLIST check (glob-per-line; trailing slash = directory; # = comment) ---
# Existence is the gate's verdict above, not a second test here — one decision, one place.
if [ "$_allowlist_ok" -eq 1 ]; then
  while IFS= read -r _glob || [ -n "$_glob" ]; do
    # strip comments + whitespace
    _glob="${_glob%%#*}"
    _glob="$(printf '%s' "$_glob" | "$SED" 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -z "$_glob" ] && continue
    case "$_glob" in
      */) # directory prefix match (allow both absolute and relative)
        case "$FILE_PATH" in
          *"$_glob"*) exit 0 ;;
        esac
        ;;
      *)  # file/glob match
        case "$FILE_PATH" in
          $_glob|*"/$_glob") exit 0 ;;
        esac
        ;;
    esac
  done < "$ALLOWLIST"
fi

# --- EXTRACT INCOMING CONTENT ---
# Write carries .tool_input.content; Edit carries .tool_input.new_string.
CONTENT="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.content // .tool_input.new_string // empty')"
[ -z "$CONTENT" ] && exit 0

# --- MARKER SOURCE (file-scoped by specification) ---------------------------
# The override markers are FILE-scoped: core/standards/reference-durability-standard.md
# § Per-file override marker declares them "once, as an HTML comment anywhere in
# the file", and the CI resolves them that way already (whole-file, head version,
# in .github/workflows/reference-durability.yml). A Write carries the whole
# post-change file in $CONTENT, so the fragment IS the file and $CONTENT is
# complete. An Edit carries only the replacement fragment, so a file that
# correctly declares its marker at the top is unwritable on any line that does not
# repeat the declaration. Union the on-disk file in for Edit only, so the hook and
# the CI answer one question one way. Fence strip: BOTH surfaces strip fenced blocks
# before resolving a marker, so an illustration of the syntax is never a declaration of
# it. Changing one without the other re-opens the divergence this line exists to close.
#
# Five properties, each load-bearing:
#   1. `[ -f ]`, never `[ -e ]` — excludes directories, FIFOs and character devices,
#      so a pathological file_path cannot hang a PreToolUse hook on the write hot path.
#   2. Every branch total — this runs under `set -euo pipefail` with an ERR trap that
#      exits 2, so a bare non-zero at statement level would block the user's write with
#      a HOOK-ERROR. Hence `|| true` on the cat and if/elif rather than an `||` chain.
#   3. $CWD is already extracted above for the workspace-scope guard — no new input
#      field, no new jq call.
#   4. Absent file => silent fallback to the fragment => today's behavior. Synthetic
#      file_paths that do not exist on disk keep resolving exactly as before.
#   5. `/bin/cat` literal, matching the PATH-pinned style already used by get_mode().
# A Write deliberately does NOT read the disk: for a Write the fragment is the whole
# post-change file, so the disk holds the PRE-change state, and reading it would let a
# marker the author is deleting still grant.
MARKER_SRC="$CONTENT"
if [ "$TOOL_NAME" = "Edit" ]; then
  _mt=""
  if   [ -f "$FILE_PATH" ];                              then _mt="$FILE_PATH"
  elif [ -n "$CWD" ] && [ -f "${CWD}/${FILE_PATH}" ];    then _mt="${CWD}/${FILE_PATH}"
  fi
  if [ -n "$_mt" ]; then
    _mdisk="$(/bin/cat "$_mt" 2>/dev/null || true)"
    MARKER_SRC="${CONTENT}
${_mdisk}"
  fi
fi

# --- PER-FILE OVERRIDE MARKERS (suppress a class for this file; matches still reported) ---
# Read from $MARKER_SRC, not from $CONTENT: for a Write those are the same bytes, and
# for an Edit $MARKER_SRC additionally carries the target file from disk so a file-scoped
# declaration is visible to a fragment that does not repeat it. See MARKER SOURCE above.
# A marker inside a fenced code block OR an inline code span ILLUSTRATES the syntax;
# it does not DECLARE it. The inline case is the one with observed harm: a decision
# index exempted itself with markers in backticked table cells, and two dead
# cross-references then passed CI.
# Resolving markers whole-file cannot tell those apart, so a file that merely documents
# the marker exempts itself from the gate that governs it. Strip fences first, with the
# same awk the detectors use below, so one rule governs both reads. The CI marker read
# strips identically — neither surface may change without the other.
MARKER_SCAN="$("$PRINTF" '%s\n' "$MARKER_SRC" | "$AWK" '
  /^[[:space:]]*```/ { infence = !infence; next }
  !infence { gsub(/`[^`]*`/, ""); print }
')"

ALLOW_LINK=0
ALLOW_VERSION=0
ALLOW_URL=0
# HERE-STRINGS, not pipes, and the reason is a measured defect rather than a style choice.
# `grep -q` exits at its FIRST match. Piping $MARKER_SCAN into it leaves the writer with data
# still to push whenever the payload exceeds the pipe buffer (~64 KB), so the writer takes
# SIGPIPE and returns 141; `set -o pipefail` above promotes that 141 to the pipeline's status
# and this `if` reads FALSE even though the marker WAS found. The file's valid override is
# silently discarded and its reference is flagged — size-dependently, so every marker under the
# buffer resolves correctly and the failure is invisible to small inputs. Removing the writer
# removes the hazard rather than relocating it: a here-string has no second process, so there is
# no early close, no SIGPIPE, and no dependence on `pipefail` semantics.
# The CI marker read uses the same construct for the same reason — the invariant recorded at
# the MARKER_SCAN comment above binds both surfaces, and neither may return to a pipe alone.
# Pinned behavioural arms: core/hooks/testdata/marker-resolution-fixtures.txt.
if "$GREP" -qE '<!--[[:space:]]*reference-durability:[[:space:]]*allow-link[[:space:]]*-->' <<<"$MARKER_SCAN"; then
  ALLOW_LINK=1
fi
if "$GREP" -qE '<!--[[:space:]]*reference-durability:[[:space:]]*allow-version-ref[[:space:]]*-->' <<<"$MARKER_SCAN"; then
  ALLOW_VERSION=1
fi
if "$GREP" -qE '<!--[[:space:]]*reference-durability:[[:space:]]*allow-url[[:space:]]*-->' <<<"$MARKER_SCAN"; then
  ALLOW_URL=1
fi

# --- LEDGER-SURFACE EXEMPTION (Class U scope; mirrors the CI is_ledger_exempt predicate) ---
# The ref-permitted ledger surfaces (the five named in the universal-vs-release-pipeline
# split rule) are categorically exempt from the raw-URL class — a ledger URL is native
# provenance there. The scope gate above excludes MOST of release/releases/* and top-level
# CHANGELOG.md because they match no durable glob — but NOT
# release/releases/plans/*_RELEASE_PLAN.md, which the gate deliberately INCLUDES at the
# plans arm and which the path allowlist then exempts by directory prefix (the entry
# release/releases/plans/ in core/config/allowlists/reference-durability-allowlist.txt,
# whose rationale is recorded there). So a release plan never reaches this flag today —
# the allowlist is what spares it, not the scope gate — and this guard remains
# defense-in-depth for the surfaces the gate does reach and for any future widening.
# Class L / Class V / positional issue-ref are unaffected by this flag.
LEDGER_EXEMPT=0
case "$FILE_PATH" in
  */release/releases/*|release/releases/*) LEDGER_EXEMPT=1 ;;
  */CHANGELOG.md|CHANGELOG.md) LEDGER_EXEMPT=1 ;;
esac

# --- FENCE STRIP — remove fenced code blocks (``` delimited) before scanning ---
# Detectors must not fire on illustrative content inside code fences.
STRIPPED="$("$PRINTF" '%s\n' "$CONTENT" | "$AWK" '
  /^[[:space:]]*```/ { infence = !infence; next }
  !infence { print }
')"

# --- DETECTORS ---
# Each detector returns matched lines (line-numbered against the stripped content) or empty.
link_matches=""
version_matches=""
issueref_matches=""
url_matches=""

if [ "$ALLOW_LINK" -eq 0 ]; then
  link_matches="$("$PRINTF" '%s\n' "$STRIPPED" | "$GREP" -nE "$LINK_RE" || true)"
fi
if [ "$ALLOW_VERSION" -eq 0 ]; then
  version_matches="$("$PRINTF" '%s\n' "$STRIPPED" | "$GREP" -nE "$CUTOVER_RE" || true)"
fi
# Class U — raw ledger URL. Suppressed by the allow-url marker OR by ledger-surface exemption.
if [ "$ALLOW_URL" -eq 0 ] && [ "$LEDGER_EXEMPT" -eq 0 ]; then
  url_matches="$("$PRINTF" '%s\n' "$STRIPPED" | "$GREP" -nE "$URL_RE" || true)"
fi

# Positional issue-reference detector (always on; not governed by the link/version markers).
#
# COORDINATE SPACE — why this reads $STRIPPED and NOT the $MARKER_SRC disk union.
# The classifier's entire decision is `lineno >= refline`, so both numbers must live in
# ONE space. $STRIPPED is the fence-stripped fragment and Pass 2 numbers its lines with NR
# over that same payload, so refline and lineno are both fragment-stripped coordinates and
# the comparison is valid by construction. For a Write the fragment IS the post-change
# file, so that space is the file's too.
#
# The file-scoped marker union above deliberately does NOT extend here, and the reason is a
# MEASURED inversion rather than an oversight. Sourcing refline from the on-disk file for an
# Edit would put refline in FILE coordinates while lineno stayed in FRAGMENT coordinates —
# an index into an n-line file compared against an index into a k-line fragment. That is not
# merely imprecise, it is sign-unstable, and both of its outcomes are wrong:
#   * Block LATE in the file (the common shape, and the very case such a change would be
#     made to fix): every fragment lineno falls below it, every ref still reports
#     OUTSIDE-BLOCK, and the false positive survives untouched. Measured on a 31-line
#     fixture with its block at line 28 — verdicts identical to today for both an in-block
#     edit and a body-prose edit. Inert.
#   * Block EARLY in the file — `## Related` / `## Sources` are REFBLOCK_RE spellings that
#     routinely sit near the top: every fragment line at or past that number flips to
#     in-block, where only the self-describe word count remains, and ordinary body prose
#     clears it. Measured on a 71-line fixture with `## Related` at line 7 against a 12-line
#     body edit carrying one bare ref per line: 12 findings today, 6 under a disk-sourced
#     refline. Six true positives suppressed — a fail-OPEN on BLOCK-FRAGILE-REF-003, the
#     direction GHSA-g9g6-28c9-vrx5 hardened this hook against.
# So where that change would do anything at all it opens the gate, and where it is safe it
# is inert.
#
# Nor is there a sound repair at this surface. The rule needs the fragment's position in the
# POST-change file. An Edit's $CONTENT is .tool_input.new_string — bytes that by definition
# are not yet on disk — so the splice point is unrecoverable without .tool_input.old_string,
# a NEW INPUT FIELD, which the marker-source block above lists as load-bearing property 3.
# The CI can do this because it has a diff and therefore a real hunk->file-line mapper
# (map_added_lines in .github/workflows/reference-durability.yml, whose own header names
# this same two-coordinate-space comparison as the defect it was written to fix); a
# PreToolUse hook has no diff. Today's Edit posture is consequently strictly grant-DENYING:
# refline 0 means CONTENT-FREE-IN-BLOCK can never fire, so every Edit finding is a true
# positive or a false positive and never a miss, and the path allowlist stays the governed
# escape the positional rule already documents. Do not "fix" this by unioning the disk.
#
# Pass 1: locate the FIRST reference-block header line number (0 = none present).
refblock_line="$("$PRINTF" '%s\n' "$STRIPPED" | "$GREP" -nE "$REFBLOCK_RE" | /usr/bin/head -1 | /usr/bin/cut -d: -f1 || true)"
[ -z "$refblock_line" ] && refblock_line=0

# Pass 2: classify each line via the SHARED positional classifier
# (core/hooks/lib/positional-issueref.awk — the same file the fixture-runner and the CI
# invoke, so the positional logic is single-sourced and cannot drift). The hook has true
# file lines already (NR over the stripped payload) and the refblock line from Pass 1; it
# feeds the classifier "<NR>\t<line>" records and passes ISSUEREF_RE in. That regex is the
# sourced lib's bytes, as it is on every other invocation path, so the classifier's parameters
# are the same values everywhere by construction rather than by a maintained invariant.
# Output shape ("<lineno>:VERDICT:<line>") is identical to the previous inline awk, so the
# downstream report wiring is unchanged.
# Verify the classifier actually WORKS before trusting its (possibly empty) output — a
# present-but-empty/truncated/corrupt awk otherwise runs to nothing and silently yields no
# findings, re-opening the fail-OPEN this advisory closes (GHSA-g9g6-28c9-vrx5). Canary: a
# bare positional #N with NO reference block, which the real classifier MUST verdict
# OUTSIDE-BLOCK. A non-zero awk exit (syntax error) or a missing OUTSIDE-BLOCK verdict
# (empty/broken awk) both fail the canary. Evaluated inside an `if` so set -e / the ERR
# trap never fire on a canary miss.
_classifier_ok=0
if [ -f "$POSITIONAL_LIB" ]; then
  if _canary="$("$PRINTF" '1\tThis references #99 in prose.\n' | "$AWK" -f "$POSITIONAL_LIB" \
        -v refline=0 -v issuere="$ISSUEREF_RE" -v hexcolor="$HEXCOLOR_RE" -v minwords="$MIN_SELFDESCRIBE_WORDS" 2>/dev/null)" \
     && "$PRINTF" '%s' "$_canary" | "$GREP" -q 'OUTSIDE-BLOCK'; then
    _classifier_ok=1
  fi
fi
if [ "$_classifier_ok" -eq 1 ]; then
  issueref_matches="$("$PRINTF" '%s\n' "$STRIPPED" | "$AWK" '{ printf "%d\t%s\n", NR, $0 }' \
    | "$AWK" -f "$POSITIONAL_LIB" \
        -v refline="$refblock_line" \
        -v issuere="$ISSUEREF_RE" \
        -v hexcolor="$HEXCOLOR_RE" \
        -v minwords="$MIN_SELFDESCRIBE_WORDS" || true)"
else
  # Classifier missing OR present-but-unusable (empty/truncated/corrupt) — a deploy defect
  # (setup-workspace.sh co-deploys it beside dep-resolve.sh) or tamper. Mode-gated posture
  # (GHSA-g9g6-28c9-vrx5), mirroring the jq gate above: in ENFORCE, a durable-corpus write
  # whose positional check cannot run fails CLOSED (we cannot verify the reference-placement
  # rule, so we DENY); in warn/off it degrades to a note. The Class L / V / U detectors
  # already ran and are unaffected either way. This closes the former fail-OPEN where a
  # missing OR broken classifier silently skipped BLOCK-FRAGILE-REF-003 even in enforce.
  log_error "PRIMITIVE-MISSING-OR-INVALID: positional classifier $POSITIONAL_LIB unusable"
  if [ "$MODE" = "enforce" ]; then
    deny_missing_primitive "positional-issueref.awk" "$HOOK_NAME" "$PRINTF"
    exit 2   # caller owns the fail-closed exit — never trust the callee to terminate (GHSA-g9g6)
  fi
  "$PRINTF" '[CLAUDE-HOOK:%s:PRIMITIVE-MISSING] WARN (degraded, .mode=%s): co-shipped classifier positional-issueref.awk absent or invalid; positional issue-ref check (BLOCK-FRAGILE-REF-003) skipped this run (Class L/V/U still enforced).\n' "$HOOK_NAME" "$MODE" >&2
  issueref_matches=""
fi

# --- AGGREGATE + REPORT ---
have_findings=0
[ -n "$link_matches" ] && have_findings=1
[ -n "$version_matches" ] && have_findings=1
[ -n "$issueref_matches" ] && have_findings=1
[ -n "$url_matches" ] && have_findings=1

[ "$have_findings" -eq 0 ] && exit 0

# --- LOGGING HELPERS ---
log_warn() {
  local rule_id="$1" reason="$2"
  local ts
  ts="$($DATE -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg path "$FILE_PATH" --arg reason "$reason" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, file_path:$path, reason:$reason}' \
    >> "$WARN_LOG" 2>/dev/null || true
}

log_block() {
  local rule_id="$1"
  local ts
  ts="$($DATE -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg path "$FILE_PATH" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, file_path:$path}' \
    >> "$BLOCK_LOG" 2>/dev/null || true
}

# Build a human-readable finding summary for stderr.
build_report() {
  if [ -n "$link_matches" ]; then
    "$PRINTF" '  [BLOCK-FRAGILE-REF-001] Class L (markdown link) on:\n%s\n' "$link_matches"
  fi
  if [ -n "$version_matches" ]; then
    "$PRINTF" '  [BLOCK-FRAGILE-REF-002] Class V (version-cutover apparatus) on:\n%s\n' "$version_matches"
  fi
  if [ -n "$issueref_matches" ]; then
    "$PRINTF" '  [BLOCK-FRAGILE-REF-003] issue-reference placement on:\n%s\n' "$issueref_matches"
  fi
  if [ -n "$url_matches" ]; then
    "$PRINTF" '  [BLOCK-FRAGILE-REF-004] Class U (raw github.com/.../{issues,pull,milestone} URL) on:\n%s\n' "$url_matches"
  fi
}

REPORT="$(build_report)"
readonly TEACH="Rewrite as an inline summary (durability-ladder rung 1-2), or confine an unavoidable issue reference to a designated reference block with a summary noun phrase. A raw github.com/.../{issues,pull,milestone} URL (Class U) is rung-6 — summarize inline rather than link, except in the ref-permitted ledger surfaces. Per-file escape: add an HTML comment '<!-- reference-durability: allow-link -->', '<!-- reference-durability: allow-version-ref -->', or '<!-- reference-durability: allow-url -->'. See core/standards/reference-durability-standard.md."

if [ "$MODE" = "warn" ]; then
  [ -n "$link_matches" ]     && log_warn "BLOCK-FRAGILE-REF-001" "Class L markdown link in $FILE_PATH"
  [ -n "$version_matches" ]  && log_warn "BLOCK-FRAGILE-REF-002" "Class V version-cutover apparatus in $FILE_PATH"
  [ -n "$issueref_matches" ] && log_warn "BLOCK-FRAGILE-REF-003" "issue-reference placement in $FILE_PATH"
  [ -n "$url_matches" ]      && log_warn "BLOCK-FRAGILE-REF-004" "Class U raw ledger URL in $FILE_PATH"
  "$PRINTF" '[CLAUDE-HOOK:%s:RULE:WARN] fragile reference(s) in %s (warn-mode active — not blocking; would block in enforce-mode):\n%s\n%s\n' \
    "$HOOK_NAME" "$FILE_PATH" "$REPORT" "$TEACH" >&2
  exit 0
fi

# enforce-mode
[ -n "$link_matches" ]     && log_block "BLOCK-FRAGILE-REF-001"
[ -n "$version_matches" ]  && log_block "BLOCK-FRAGILE-REF-002"
[ -n "$issueref_matches" ] && log_block "BLOCK-FRAGILE-REF-003"
[ -n "$url_matches" ]      && log_block "BLOCK-FRAGILE-REF-004"
"$PRINTF" '[CLAUDE-HOOK:%s:RULE] BLOCKED: fragile reference(s) in %s:\n%s\nOverride: %s\n' \
  "$HOOK_NAME" "$FILE_PATH" "$REPORT" "$TEACH" >&2
exit 2
