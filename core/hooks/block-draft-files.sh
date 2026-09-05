#!/bin/bash
# block-draft-files.sh — PreToolUse Write hook: keep draft / scratch / proposal
# content out of the TRACKED public corpus (#411b).
# hook-owner: core/rules/git-workflow.md
#
# Enforces core/rules/git-workflow.md § Draft / scratch content (the #1823 rule):
# drafts belong in the issue tracker or the git-ignored runtime tier, never as a
# tracked .md in the public repo. Originating incident: a docs/proposals/…md draft
# committed to the public repo (2026-06-06).
#
# Classification of a Write target (repo-relative):
#   1. git-ignored (the sanctioned scratch tier — projects/, personal/,
#      steering-committee/, */governance/roadmaps/, …) → ALLOW. Uses `git
#      check-ignore`, so the allowed set is git's own ignore logic — it cannot
#      drift from .gitignore (closes adversarial PR-1: no hand-maintained list).
#   2. a draft-shaped path segment (proposals/, drafts/, scratch/, sandbox/, wip/)
#      → FLAG, even under an otherwise-governed root (this is the incident shape).
#   3. outside the governed-corpus roots (core/ release/ operations/ packages/
#      docs/ .github/) AND not a tracked top-level file → FLAG (stray new file).
#   4. a normal governed-corpus path → ALLOW.
#
# TWO BOUNDS, AND THE QUESTION BETWEEN THEM (#6115). Classes 2-4 above describe THIS
# repository's layout, but the workspace-scope gate below bounds by WORKSPACE ROOT — and a
# second git repository checked out beneath that root is a strict descendant, so it passes.
# $REL is then computed relative to THAT repository and judged against this platform's
# directory allowlist, which a foreign repo does not have and cannot be expected to. The
# repo-identity gate (layer 4, below) is the missing question, and its fail direction is
# split: a repository provably NOT the platform makes the hook inert (the fix), while an
# anchor that cannot be resolved makes the gate ABSTAIN so it can never become a kill switch.
#
# Path-shape on any Write (the hook cannot see git tracked-status from the payload);
# the repo-integrity CI gate is the A-status-delta merge-time companion (asymmetry
# is intentional — see repo-integrity.yml draft-file gate). Warn-mode initial.
# Matcher: Write. Rule: BLOCK-DRAFT-001.

set -euo pipefail
export PATH="/usr/bin:/bin"
readonly GREP="/usr/bin/grep" JQ="/usr/bin/jq" PRINTF="/usr/bin/printf" CAT="/bin/cat" TR="/usr/bin/tr" DATE="/bin/date" GIT="/usr/bin/git"

readonly HOOK_NAME="block-draft-files"
readonly HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"
readonly ERROR_LOG="${HOOK_DIR}/hook-errors.log"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly WARN_LOG="${HOOK_DIR}/draft-files-warn-log.jsonl"
readonly MODE_FILE="${HOOK_DIR}/.mode"

readonly DRAFT_SEGMENT_RE='(^|/)(proposals|drafts|draft|scratch|sandbox|wip)/'
readonly GOVERNED_ROOT_RE='^(core|release|operations|packages|docs|\.github)/'
readonly TOPLEVEL_ALLOW_RE='^(README\.md|CHANGELOG\.md|LICENSE|SECURITY\.md|CONTRIBUTING\.md|install\.sh|update\.sh|\.gitignore|\.version)$'
# (#6115) Basename of the platform checkout beneath the governed workspace root — the
# repo-identity anchor the layer-4 gate below derives. A layout constant, kept with the
# other layout constants; the same anchor block-autonomy-ceiling.sh already uses.
readonly PLATFORM_CHECKOUT_DIRNAME='pmo-platform'

log_error() { local ts; ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"; "$PRINTF" '%s [%s] %s\n' "$ts" "$HOOK_NAME" "$1" >> "$ERROR_LOG" 2>/dev/null || true; }
trap 'rc=$?; log_error "RULE-EVAL-ERROR line $LINENO (exit $rc)"; exit 0' ERR   # fail-OPEN (warn-posture)

if [ ! -x "$JQ" ] && ! command -v jq >/dev/null 2>&1; then log_error "jq missing"; exit 0; fi
INPUT="$(cat)"
"$PRINTF" '%s' "$INPUT" | "$JQ" -e . >/dev/null 2>&1 || { log_error "bad JSON"; exit 0; }
TOOL_NAME="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_name // empty')"
case "$TOOL_NAME" in Write|Edit|MultiEdit) ;; *) exit 0 ;; esac

[ "${CLAUDE_HOOK_BYPASS:-}" = "1" ] && exit 0

# --- Master-activation gate (#310) — layer 2, AFTER CLAUDE_HOOK_BYPASS and BEFORE the
# .mode read (precedence: bypass -> master -> .mode -> rule). CLASS=workflow: master-OFF
# makes this hook inert (exit 0). Fail-toward-current-behavior: a missing lib does NOT
# gate, so the hook keeps its existing .mode enforcement (a read failure never disables a
# guard). Read jq-free from the durable XDG platform-config.toml [security_hooks]. ---
readonly MASTER_ENABLE_CLASS="workflow"
readonly MASTER_LIB="${HOOK_DIR}/lib/master-enable.sh"
if [ -r "$MASTER_LIB" ]; then . "$MASTER_LIB" 2>/dev/null || true; fi
if command -v master_enable_gate >/dev/null 2>&1; then master_enable_gate "$MASTER_ENABLE_CLASS"; fi

FILE_PATH="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.file_path // empty')"
CWD="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.cwd // empty')"

# --- Workspace-scope gate (#4436) — layer 3, AFTER the master-activation gate and
# BEFORE the .mode / rule path. Precedence: bypass -> master -> SCOPE -> .mode -> rule.
# Placed BEFORE this hook's own `[ -z "$CWD" ] && CWD="$PWD"` fallback so the guard
# sees the raw payload value; the guard applies the same $PWD fallback internally
# (single-sourced there) before deciding. Inverted fail direction on the cwd axis,
# NOT on the lib axis. See lib/scope-guard.sh. ---
readonly SCOPE_GUARD_LIB="${HOOK_DIR}/lib/scope-guard.sh"
if [ -r "$SCOPE_GUARD_LIB" ]; then . "$SCOPE_GUARD_LIB" 2>/dev/null || true; fi
if command -v scope_guard_gate >/dev/null 2>&1; then scope_guard_gate "$CWD"; fi

[ -z "$FILE_PATH" ] && exit 0
[ -z "$CWD" ] && CWD="$PWD"

# Repo root + repo-relative path (fail-OPEN if not in a repo)
REPO="$("$GIT" -C "$CWD" rev-parse --show-toplevel 2>/dev/null || echo "")"
[ -z "$REPO" ] && exit 0

# --- Repo-identity gate (#6115) — layer 4, AFTER the workspace-scope gate and BEFORE the
# `git check-ignore` / classification path below, so a foreign repo costs one rev-parse and
# not also a check-ignore. Precedence:
#   CLAUDE_HOOK_BYPASS -> master-enable -> SCOPE (workspace) -> REPO-IDENTITY (here) -> .mode -> rule
#
# WHY THIS IS HERE AND NOT IN lib/scope-guard.sh. That lib's header states the boundary as
# design intent: "Scope is decided by the session's working directory, not by repository
# identity." Identity is deliberately outside its contract, and 12 of its 13 consumers
# correctly want workspace scope — block-egress.sh and block-gh-path-leak.sh MUST keep
# firing in a nested repository, which may be public. Only THIS hook's rule is specific to
# this repository's layout, so only this hook asks the identity question. The shared
# contract is untouched: blast radius 1 of 13, not 13 of 13.
#
# MEMBERSHIP, NOT PATH SHAPE. The test is git's own --git-common-dir, which every working
# tree of a repository reports identically. A linked worktree of the platform — including
# one relocated outside the workspace root — is therefore recognized, while a foreign repo
# nested inside a platform worktree is not. Both sides are normalized through `cd .. && pwd -P`
# for the reason git-post-merge-deploy.sh's Guard A documents: from a SUBDIRECTORY git
# reports --git-common-dir RELATIVE, so a raw string compare silently mis-classifies. Unlike
# a HEAD/content probe this is content- and branch-independent, so a checkout before its
# first commit is still recognized as the platform.
#
# FAIL DIRECTIONS — two axes, and only one is inverted.
#   1. IDENTITY axis (INVERTED): a repository provably NOT the anchor -> exit 0, inert. That
#      is the fix. Its failure mode is under-enforcement in a repo the rule never described.
#   2. ANCHOR axis (NOT inverted, identical to lib/scope-guard.sh clause 2): if the anchor
#      cannot be resolved — no checkout at <workspace-root>/pmo-platform, or the scope lib
#      absent so no root is derivable — this gate ABSTAINS and the hook keeps its existing
#      .mode/rule path. Inverting this axis would make a single `rm -rf` of the platform
#      checkout a silent, total kill switch for BLOCK-DRAFT-001 everywhere, which is the
#      exact shape that clause forbids. An unresolvable common-dir for $CWD's OWN repo
#      exits 0, matching the `[ -z "$REPO" ] && exit 0` fail-open directly above.
#
# ACCEPTED RESIDUAL: a platform clone at a different basename, or placed outside the
# workspace root, is not recognized and BLOCK-DRAFT-001 stops applying there. That is
# under-enforcement on a warn-posture workflow rule — recoverable, no public surface, and
# identical in kind to the residual block-autonomy-ceiling.sh already accepts at its own
# ${PRIMARY_ROOT}/pmo-platform anchor. ---

# _bdf_common_dir DIR — echo the physical --git-common-dir of the repository containing DIR,
# or empty when DIR is not in a repo / the value cannot be normalized. Never exits non-zero.
_bdf_common_dir() {
  local _d="${1:-}" _raw
  [ -n "$_d" ] || { "$PRINTF" '%s' ''; return 0; }
  _raw="$("$GIT" -C "$_d" rev-parse --git-common-dir 2>/dev/null || "$PRINTF" '%s' '')"
  [ -n "$_raw" ] || { "$PRINTF" '%s' ''; return 0; }
  # --git-common-dir is reported relative to DIR when relative, so resolve it from there.
  ( cd -- "$_d" 2>/dev/null && cd -- "$_raw" 2>/dev/null && pwd -P ) 2>/dev/null \
    || "$PRINTF" '%s' ''
  return 0
}

if command -v scope_guard_root >/dev/null 2>&1; then
  _bdf_ws="$(scope_guard_root 2>/dev/null || "$PRINTF" '%s' '')"
  # Strip a trailing slash so a root of "/" yields "/pmo-platform", not "//pmo-platform".
  _bdf_anchor="${_bdf_ws%/}/${PLATFORM_CHECKOUT_DIRNAME}"
  if [ -n "$_bdf_ws" ] && [ -d "$_bdf_anchor" ]; then
    _bdf_anchor_gc="$(_bdf_common_dir "$_bdf_anchor")"
    # Anchor axis: unresolvable -> abstain (fall through to the rule), never a kill switch.
    if [ -n "$_bdf_anchor_gc" ]; then
      _bdf_repo_gc="$(_bdf_common_dir "$CWD")"
      if [ -z "$_bdf_repo_gc" ]; then exit 0; fi
      if [ "$_bdf_repo_gc" != "$_bdf_anchor_gc" ]; then exit 0; fi
    fi
  fi
fi

case "$FILE_PATH" in
  "$REPO"/*) REL="${FILE_PATH#"$REPO"/}" ;;
  /*)        exit 0 ;;   # absolute path outside the repo → not our concern
  *)         REL="$FILE_PATH" ;;   # already relative
esac

# (1) git-ignored → sanctioned scratch tier → ALLOW (git's own ignore logic)
if "$GIT" -C "$REPO" check-ignore -q -- "$REL" 2>/dev/null; then exit 0; fi

# Classify the tracked-able path
REASON=""
if "$PRINTF" '%s' "$REL" | "$GREP" -qE "$DRAFT_SEGMENT_RE"; then
  REASON="draft-shaped path segment (proposals/ drafts/ scratch/ sandbox/ wip/) in the tracked corpus"
elif ! "$PRINTF" '%s' "$REL" | "$GREP" -qE "$GOVERNED_ROOT_RE" && ! "$PRINTF" '%s' "$REL" | "$GREP" -qE "$TOPLEVEL_ALLOW_RE"; then
  REASON="new tracked file outside the governed-corpus roots (core/ release/ operations/ packages/ docs/ .github/)"
fi
[ -z "$REASON" ] && exit 0   # normal governed-corpus write → ALLOW

# Apply per .mode (warn-mode initial)
get_mode() { local m="warn"; [ -f "$MODE_FILE" ] && m="$("$CAT" "$MODE_FILE" 2>/dev/null | "$TR" -d '[:space:]' || echo warn)"; case "$m" in warn|enforce|off) "$PRINTF" '%s' "$m";; *) "$PRINTF" 'warn';; esac; }
mode="$(get_mode)"
ts="$("$DATE" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
reason="draft/scratch in public corpus — ${REASON}: '${REL}'. Drafts belong in the issue tracker (observation.yml -> improvement.yml) or the git-ignored runtime tier (personal/, projects/), per core/rules/git-workflow.md § Draft / scratch content."
case "$mode" in
  off) exit 0 ;;
  warn)
    "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "BLOCK-DRAFT-001" --arg path "$REL" '{ts:$ts,hook:$hook,rule:$rule,path:$path}' >> "$WARN_LOG" 2>/dev/null || true
    "$PRINTF" '[CLAUDE-HOOK:%s:BLOCK-DRAFT-001] WARN (would-block, .mode=warn): %s\n' "$HOOK_NAME" "$reason" >&2
    exit 0 ;;
  enforce|*)
    "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "BLOCK-DRAFT-001" --arg path "$REL" '{ts:$ts,hook:$hook,rule:$rule,path:$path}' >> "$BLOCK_LOG" 2>/dev/null || true
    "$PRINTF" '[CLAUDE-HOOK:%s:BLOCK-DRAFT-001] BLOCKED: %s\nOverride: write it to the git-ignored runtime tier, file it in the tracker, or set CLAUDE_HOOK_BYPASS=1.\n' "$HOOK_NAME" "$reason" >&2
    exit 2 ;;
esac
