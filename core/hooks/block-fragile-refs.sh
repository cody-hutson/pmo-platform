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
# ALLOWLIST resolves relative to the hook's own directory (matches the sibling hook's
# exemption-list pattern). This finds the allowlist in whichever checkout the hook runs
# from — primary or worktree — which matters during engineering before deployment.
readonly ALLOWLIST="${HOOK_DIR}/reference-durability-allowlist.txt"
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

# --- PATH ALLOWLIST check (glob-per-line; trailing slash = directory; # = comment) ---
if [ -f "$ALLOWLIST" ]; then
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

# --- PER-FILE OVERRIDE MARKERS (suppress a class for this file; matches still reported) ---
ALLOW_LINK=0
ALLOW_VERSION=0
ALLOW_URL=0
if "$PRINTF" '%s\n' "$CONTENT" | "$GREP" -qE '<!--[[:space:]]*reference-durability:[[:space:]]*allow-link[[:space:]]*-->'; then
  ALLOW_LINK=1
fi
if "$PRINTF" '%s\n' "$CONTENT" | "$GREP" -qE '<!--[[:space:]]*reference-durability:[[:space:]]*allow-version-ref[[:space:]]*-->'; then
  ALLOW_VERSION=1
fi
if "$PRINTF" '%s\n' "$CONTENT" | "$GREP" -qE '<!--[[:space:]]*reference-durability:[[:space:]]*allow-url[[:space:]]*-->'; then
  ALLOW_URL=1
fi

# --- LEDGER-SURFACE EXEMPTION (Class U scope; mirrors the CI is_ledger_exempt predicate) ---
# The ref-permitted ledger surfaces (the five named in the universal-vs-release-pipeline
# split rule) are categorically exempt from the raw-URL class — a ledger URL is native
# provenance there. The hook's durable-corpus scope gate above already excludes
# release/releases/* and top-level CHANGELOG.md (neither matches a durable glob), so this
# is defense-in-depth + self-documentation: if the scope gate ever widens, this stays the
# Class-U guard. Class L / Class V / positional issue-ref are unaffected by this flag.
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
