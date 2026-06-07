#!/usr/bin/env bash
# automated-closeout.sh — Automated Stage 13 close-out
#
# Wraps the Stage 13 chore-PR pattern per pipeline/stage-13-close.md § Phase B
# commit mechanism + hub-spoke-bridge.md Procedure 7. Per the
# Stage 5 spec (relayed; canonical content).
#
# Phases (sequenced; each idempotent — re-running is safe):
#   1  parse_args         CLI validation
#   2  preflight          gh auth, clean tree, worktree cwd, DEPLOYED row, tag exists
#   3  read_state         RELEASE_LOG row + visible-H4 Deployment Log + Milestone state
#   4  detect_open_issues auto-close anomaly enumeration
#   5  create_chore_branch chore/v<X.Y>-stage-13-corpus-update
#   6  transition_release_log  DEPLOYED → VERIFIED
#   7  append_release_index    new row in RELEASE_INDEX.md
#   8  append_release_digest   new entry under v<MAJOR>.* H2 in RELEASE_DIGEST.md
#   9  scaffold_release_notes  frontmatter + section H2 placeholders (SCAFFOLD-ONLY)
#   9.5 append_changelog   prepend ## [vX.Y] section to CHANGELOG.md (Layer-1 dual-write Surface 2)
#   10 commit_chore_pr     git add + git commit (parser-clean message)
#   11 create_chore_pr     gh pr create with safe-phrasing body throughout
#   12 await_merge_chore_pr poll mergeStateStatus per Stage 12 Phase A.6 pattern
#   13 post_close_milestone gh api -X PATCH state=closed
#   14 manual_close_release_issues operator-authorized D-1 with structured comment
#   15 run_verification + post_gate_passage_proof per the gate-passage-proof template
#   15.5 publish_github_release gh release create | edit (Layer-1 dual-write Surface 1)
#   16 invoke_orphan_cleanup cleanup-orphan-state.sh --release-close <slug> --dry-run
#   17 generate_report     structured markdown or JSON close-out report
#
# Usage:
#   ./automated-closeout.sh --pr <N> --version v<X.Y> --milestone <N> [--dry-run|--apply] [--markdown|--json] [--with-pattern-scan]
#   ./automated-closeout.sh --self-test
#   ./automated-closeout.sh --check-paths
#   ./automated-closeout.sh --help
#
# Flags:
#   REQUIRED:
#     --pr <N>                 Release PR number
#     --version v<X.Y>         Version key matching RELEASE_LOG row
#     --milestone <N>          Milestone number
#   MODE (one of, default --dry-run):
#     --dry-run                Enumerate + preview; no state mutation (default)
#     --apply                  Execute state mutations after enumeration (opt-in)
#   OUTPUT (one of, default --markdown):
#     --markdown               Human-readable close-out report (default)
#     --json                   Machine-readable
#   OPTIONAL:
#     --with-pattern-scan      Invoke synthesize-release-learnings.sh --mode pattern-detect post-close
#   META:
#     --self-test              Validate internal logic (offline); exit 0 on success
#     --check-paths            Resolve the four corpus paths (offline); exit 0 if all
#                              resolve, 1 otherwise. CI smoke-gate primitive — no
#                              git remote / gh / network call.
#     --help, -h               Print this help
#
# Hook compatibility (per bypass-mode-readiness.md):
#   - All git mutations via porcelain (broad `git <verb>` exemption per BLOCK-TRASH rules)
#   - No rm/rmdir/unlink; chore branch deletion via `gh pr merge --delete-branch` + `git branch -d`
#   - `gh api -X PATCH/DELETE` requires .claude/egress-allowlist.txt entries (already present)
#
# Cutover: Applies to releases entering Stage 13 strictly AFTER the cutover merge SHA.
# The cutover release itself is exempt — reflexive-pipeline-loop discipline.
# This script does not gate by version — the Stage 13 chip prompt + Mode D
# honor cutover at the call site.
#
# Exit codes:
#   0 = success (dry-run or apply)
#   1 = validation failure / missing required flag
#   2 = preflight failure (Stage 12 chore PR not landed, tag missing, etc.)
#   3 = phase execution failure during --apply (idempotent re-run usually safe)

set -euo pipefail

# Pin PATH to system tools per bypass-mode-readiness.md (BLOCK-DESTRUCTIVE-020).
export PATH="/usr/bin:/bin"

# Resolve `gh` absolute path before PATH-pin removes its directory from search.
# Homebrew on Apple Silicon installs to /opt/homebrew/bin; Intel macs use /usr/local/bin.
# Operator may install elsewhere — fall back to PATH search via `command -v` BEFORE pin.
# We resolved this at script-load time via a check against both standard locations:
GH=""
for candidate in /opt/homebrew/bin/gh /usr/local/bin/gh; do
  if [[ -x "$candidate" ]]; then
    GH="$candidate"
    break
  fi
done
if [[ -z "$GH" ]]; then
  echo "ERROR: gh CLI not found at /opt/homebrew/bin/gh or /usr/local/bin/gh; install via 'brew install gh' or set CLAUDE_HOOK_BYPASS=1 and add gh location" >&2
  exit 1
fi
GIT=/usr/bin/git

# ─── Credential fallback (locked-Keychain degradation) ───────────────────────
#
# On macOS the default credential helper is osxkeychain. When the login Keychain
# is locked (e.g. an unattended/headless session), osxkeychain returns -128 and,
# absent a tty to prompt, git would BLOCK on the first remote-touching call
# (push / fetch / ls-remote) — hanging the close-out indefinitely.
#
# Two guards make a locked Keychain degrade gracefully instead of hanging:
#   1. GIT_TERMINAL_PROMPT=0 — git fails fast on a credential miss rather than
#      blocking on an interactive prompt that can never be answered.
#   2. A gh-backed credential helper (`gh auth git-credential`) layered on top of
#      the configured helper, so an authenticated `gh` supplies the token when the
#      Keychain is unavailable. git_net() injects it on remote-touching calls only;
#      local git operations keep the default helper untouched.
#
# Fast-path detection: if neither the Keychain nor gh can serve a credential, the
# preflight (phase_preflight) surfaces a clear FAIL via `gh auth status` before any
# git network call — so the failure mode is an explicit message, never a hang.
export GIT_TERMINAL_PROMPT=0
# `gh auth git-credential` is git's documented credential-helper contract; the
# leading '!' marks it as a shell command. Layered (not replacing) the configured
# helper — git tries each in order until one returns a credential.
GIT_CRED_HELPER="!${GH} auth git-credential"

# Wrapper for remote-touching git calls: identical to `$GIT` but with the
# gh-backed credential helper layered in. Use for push / fetch / ls-remote.
git_net() {
  $GIT -c "credential.helper=${GIT_CRED_HELPER}" "$@"
}

# ─── Repo-relative paths ─────────────────────────────────────────────────────

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Script lives at release/tools/; repo root is two levels up (release/tools → release → root).
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
# WORKSPACE_ROOT resolution (env-override → operator.toml → default) per the
# cleanup-orphan-state.sh precedent. workspace_boundary_check() keys on this; the
# default uses ${HOME} (no embedded operator identity).
WORKSPACE_ROOT="${WORKSPACE_ROOT:-${CLAUDE_WORKSPACE_ROOT:-}}"
if [[ -z "$WORKSPACE_ROOT" ]]; then
  _operator_toml="${HOME}/.config/pmo-platform/operator.toml"
  if [[ -r "$_operator_toml" ]]; then
    _wr=$(/usr/bin/grep -E '^claude_workspace_root' "$_operator_toml" 2>/dev/null | /usr/bin/head -1 | /usr/bin/awk -F= '{gsub(/[" ]/,"",$2); print $2}')
    [[ -n "$_wr" ]] && WORKSPACE_ROOT="$_wr"
  fi
fi
WORKSPACE_ROOT="${WORKSPACE_ROOT:-${HOME}/Claude}"

# Repo slug resolution (env-override → operator.toml → default). Empty operator
# config → bare "pmo-platform"; gh calls below tolerate a non-resolving slug.
REPO_SLUG="${REPO_SLUG:-}"
if [[ -z "$REPO_SLUG" ]] && [[ -r "${HOME}/.config/pmo-platform/operator.toml" ]]; then
  _gh=$(/usr/bin/grep -E '^operator_github' "${HOME}/.config/pmo-platform/operator.toml" 2>/dev/null | /usr/bin/head -1 | /usr/bin/awk -F= '{gsub(/[" ]/,"",$2); print $2}')
  _repo=$(/usr/bin/grep -E '^pmo_platform_repo_name' "${HOME}/.config/pmo-platform/operator.toml" 2>/dev/null | /usr/bin/head -1 | /usr/bin/awk -F= '{gsub(/[" ]/,"",$2); print $2}')
  [[ -z "$_repo" ]] && _repo="pmo-platform"
  [[ -n "$_gh" ]] && REPO_SLUG="${_gh}/${_repo}"
fi
[[ -z "$REPO_SLUG" ]] && REPO_SLUG="pmo-platform"
RELEASE_LOG="$REPO_ROOT/release/releases/RELEASE_LOG.md"
RELEASE_INDEX="$REPO_ROOT/release/releases/RELEASE_INDEX.md"
RELEASE_DIGEST="$REPO_ROOT/release/releases/RELEASE_DIGEST.md"
RELEASE_NOTES_DIR="$REPO_ROOT/release/releases/notes"
RELEASE_PLANS_DIR="$REPO_ROOT/release/releases/plans"
CLEANUP_TOOL="$SCRIPT_DIR/cleanup-orphan-state.sh"
COMPUTE_CYCLE_TIME="$SCRIPT_DIR/compute-cycle-time.sh"
SYNTHESIZE_LEARNINGS="$SCRIPT_DIR/synthesize-release-learnings.sh"
# The deterministic INDEX generator lives in core/deploy/tools/, NOT alongside
# this script. The prior "$SCRIPT_DIR/generate_release_index.py" pointed at a
# non-existent release/tools/ path, so the "[[ -x "$GENERATE_INDEX" ]]" guard in
# phase_append_release_index always failed and silently fell through to the
# hand-append fallback (#459 — silent-fallthrough class). Point at the real tool.
GENERATE_INDEX="$REPO_ROOT/core/deploy/tools/generate_release_index.py"

# ─── Defaults ────────────────────────────────────────────────────────────────

PR_NUMBER=""
VERSION=""
MILESTONE=""
MODE="dry-run"           # dry-run | apply
OUTPUT="markdown"        # markdown | json
WITH_PATTERN_SCAN=0
SELF_TEST=0
CHECK_PATHS=0            # offline corpus-path resolution probe (CI smoke gate)

# State populated by phases (used by generate_report)
RUN_TS=""
STATE_LOG_ROW_PRESENT=0
STATE_LOG_ROW_STATE=""
STATE_MILESTONE_STATE=""
STATE_MILESTONE_SLUG=""
STATE_CYCLE_TIME=""
STATE_TAG_EXISTS=0
OPEN_ISSUE_LIST=""        # newline-separated list of issue numbers
OPEN_ISSUE_COUNT=0
CHORE_BRANCH=""
CHORE_PR_NUMBER=""
VERIFICATION_RESULTS=""

# Phase outcomes (PASS / FAIL / SKIPPED / N/A / DRY-RUN / MANUAL)
# Bash 3.2 (macOS default) lacks associative arrays — use parallel indexed arrays
# keyed by phase name. Lookup is O(n) but phase count is small (<20).
PHASE_NAMES=()
PHASE_RESULTS=()
PHASE_DETAILS=()

# ─── Helpers ─────────────────────────────────────────────────────────────────

usage() {
  /usr/bin/sed -n '2,67p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

ts_now() { /bin/date -u +%Y-%m-%dT%H:%M:%SZ; }
date_today() { /bin/date -u +%Y-%m-%d; }

# Workspace-boundary safety per cleanup-orphan-state.sh pattern.
workspace_boundary_check() {
  local cwd
  cwd="$(pwd -P)"
  case "$cwd" in
    "$WORKSPACE_ROOT"*) return 0 ;;
    *) echo "ERROR: invoked from $cwd — outside workspace $WORKSPACE_ROOT (defense-in-depth boundary)" >&2; exit 2 ;;
  esac
}

# Validate version key format vX.Y or vX.Y-suffix
validate_version() {
  local v="$1"
  [[ "$v" =~ ^v[0-9]+\.[0-9]+([a-z]|[a-z0-9.-]+)?$ ]]
}

# Returns 0 if string starts with "v<MAJOR>" else 1
extract_major() {
  local v="$1"
  /usr/bin/printf '%s' "$v" | /usr/bin/sed -nE 's/^(v[0-9]+)\..*/\1/p'
}

# Locate the RELEASE_LOG.md row for the version (matches first table column).
# Returns the literal row line on stdout (no leading "LINE:" prefix); empty if not found.
find_log_row() {
  local version="$1"
  # Match pipe-leading row starting with `| v<X.Y>` OR `| v<X.Y>-<slug>`
  /usr/bin/grep -E "^\| ${version}(-[a-z0-9.-]+)? \|" "$RELEASE_LOG" 2>/dev/null | /usr/bin/head -1
}

# Extract milestone slug from existing log row, e.g. "v2.10-content-audits".
# Schema-aware (mirrors extract_row_state's position-independence):
#   - Current 8-column schema `| Version | Milestone | … |`: field 1 is the bare
#     Version (e.g. v3.18); the milestone slug is field 2
#     (e.g. v3.18-corpus-integrity-enforcement).
#   - Legacy 5-column schema `| Milestone | Date | … |`: the slug is field 1.
# Resolution rule (position-independent): the slug is the FIRST field that looks
# like a version key carrying a hyphenated slug suffix — it begins `v<MAJOR>.<MINOR>`
# (optional letter / -N qualifier) AND contains a `-<alpha…>` slug tail. A bare
# Version field (v3.18) has no slug tail, so it is skipped.
# Fallback (defensive): if no field matches (a pure-version row with no slug column),
# return field 1 stripped — preserving the prior behavior.
extract_milestone_slug() {
  local row="$1"
  /usr/bin/printf '%s' "$row" | /usr/bin/awk -F ' \\| ' '
    {
      field1 = ""
      for (i = 1; i <= NF; i++) {
        f = $i
        gsub(/ \|$/, "", f)
        gsub(/^[ \t|]+|[ \t]+$/, "", f)
        if (f == "") continue
        if (field1 == "") field1 = f
        # version key (vMAJOR.MINOR[letter][-N]) followed by a hyphenated slug tail
        if (f ~ /^v[0-9]+\.[0-9]+[a-z]?(-[0-9]+)?-[a-z]/) { print f; exit }
      }
      # Fallback: no hyphenated-slug field found — emit field 1 (legacy/pure-version).
      print field1
    }' | /usr/bin/head -1
}

# Extract the State column from a RELEASE_LOG row. Robust to column position:
# the State is the last non-empty field that is NOT a YYYY-MM-DD date, so it
# resolves whether the row ends "... | State |" (legacy 5-column) or
# "... | State | Date |" (current 8-column schema, where Date is trailing).
extract_row_state() {
  local row="$1"
  /usr/bin/printf '%s' "$row" | /usr/bin/awk -F ' \\| ' '
    {
      for (i = NF; i >= 1; i--) {
        f = $i
        gsub(/ \|$/, "", f)
        gsub(/^[ \t]+|[ \t]+$/, "", f)
        if (f == "") continue
        if (f ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) continue
        print f; exit
      }
    }'
}

# Pre-submit parser-clean check on chore-PR body draft (D9).
# Returns 0 if clean; 1 if any close-family verb + #N detected.
check_parser_clean() {
  local body="$1"
  if /usr/bin/printf '%s' "$body" | /usr/bin/grep -iE "(close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved) +#?\[?[0-9]" >/dev/null 2>&1; then
    return 1
  fi
  return 0
}

mark_phase() {
  PHASE_NAMES+=("$1")
  PHASE_RESULTS+=("$2")
  PHASE_DETAILS+=("${3:-}")
}

# Look up phase result + detail by name; emits "RESULT|DETAIL" on stdout
get_phase() {
  local target="$1"
  local i
  for ((i=0; i<${#PHASE_NAMES[@]}; i++)); do
    if [[ "${PHASE_NAMES[$i]}" == "$target" ]]; then
      /usr/bin/printf '%s|%s\n' "${PHASE_RESULTS[$i]}" "${PHASE_DETAILS[$i]}"
      return 0
    fi
  done
  /usr/bin/printf '—|—\n'
}

# ─── Phase 2: preflight ──────────────────────────────────────────────────────

phase_preflight() {
  # (a) gh auth — also the credential fast-path gate. `gh auth status` does NOT
  # prompt, so it returns immediately even when the Keychain is locked. If gh is
  # authenticated, git_net's gh-backed credential helper will serve remote calls
  # (so a locked Keychain degrades gracefully); if gh is NOT authenticated, fail
  # fast HERE with an actionable message rather than letting a later push/ls-remote
  # block on an unanswerable credential prompt.
  if ! $GH auth status >/dev/null 2>&1; then
    mark_phase "preflight" "FAIL" "gh auth status failed — no usable credential. If the macOS Keychain is locked, run 'gh auth login' (or 'gh auth status' to confirm a token) so the gh-backed credential helper can serve git remote calls; close-out fails fast here instead of hanging on a credential prompt."
    return 2
  fi

  # (b) clean working tree
  if [[ -n "$($GIT -C "$REPO_ROOT" status --porcelain 2>/dev/null)" ]]; then
    mark_phase "preflight" "FAIL" "working tree not clean"
    return 2
  fi

  # (c) cwd is worktree (not primary)
  local cwd
  cwd="$(pwd -P)"
  if [[ "$cwd" == "$WORKSPACE_ROOT" ]]; then
    mark_phase "preflight" "FAIL" "cwd is primary checkout — close-out must run in worktree per git-workflow.md § Primary Checkout Discipline"
    return 2
  fi

  # (d) RELEASE_LOG row for version exists with DEPLOYED state
  local row
  row="$(find_log_row "$VERSION")"
  if [[ -z "$row" ]]; then
    mark_phase "preflight" "FAIL" "RELEASE_LOG row for $VERSION not found — Stage 12 chore PR did not land"
    return 2
  fi
  STATE_LOG_ROW_PRESENT=1
  STATE_LOG_ROW_STATE="$(extract_row_state "$row")"
  STATE_MILESTONE_SLUG="$(extract_milestone_slug "$row")"

  if [[ "$STATE_LOG_ROW_STATE" != "DEPLOYED" && "$STATE_LOG_ROW_STATE" != "VERIFIED" ]]; then
    mark_phase "preflight" "FAIL" "RELEASE_LOG row state='$STATE_LOG_ROW_STATE' (expected DEPLOYED); Stage 12 chore PR may not have landed"
    return 2
  fi

  # (e) annotated tag exists for version
  if $GIT -C "$REPO_ROOT" tag -l "$VERSION" 2>/dev/null | /usr/bin/grep -qE "^${VERSION}$"; then
    STATE_TAG_EXISTS=1
  fi

  mark_phase "preflight" "PASS" "gh auth OK; tree clean; cwd worktree; RELEASE_LOG row state=$STATE_LOG_ROW_STATE; tag_exists=$STATE_TAG_EXISTS"
  return 0
}

# ─── Phase 3: read_state ─────────────────────────────────────────────────────

phase_read_state() {
  STATE_MILESTONE_STATE="$($GH api "repos/${REPO_SLUG}/milestones/${MILESTONE}" --jq '.state' 2>/dev/null || echo "unknown")"

  # Cycle time (read-only; may be N/A pre-instrumentation)
  if [[ -x "$COMPUTE_CYCLE_TIME" ]]; then
    STATE_CYCLE_TIME="$("$COMPUTE_CYCLE_TIME" --version "$VERSION" 2>/dev/null || echo "N/A")"
  else
    STATE_CYCLE_TIME="N/A (compute-cycle-time.sh not executable)"
  fi

  mark_phase "read_state" "PASS" "milestone state=$STATE_MILESTONE_STATE; cycle_time=$STATE_CYCLE_TIME"
  return 0
}

# ─── Phase 4: detect_open_release_issues (D6 — auto-close anomaly) ───────────

phase_detect_open_issues() {
  local slug="$STATE_MILESTONE_SLUG"
  [[ -z "$slug" ]] && slug="$VERSION"

  OPEN_ISSUE_LIST="$($GH issue list --repo "$REPO_SLUG" --milestone "$slug" --state open --json number --jq '.[].number' 2>/dev/null || true)"
  if [[ -z "$OPEN_ISSUE_LIST" ]]; then
    OPEN_ISSUE_COUNT=0
  else
    OPEN_ISSUE_COUNT="$(/usr/bin/printf '%s\n' "$OPEN_ISSUE_LIST" | /usr/bin/grep -c .)"
  fi

  if [[ "$OPEN_ISSUE_COUNT" -gt 10 ]]; then
    mark_phase "detect_open_issues" "FAIL" "$OPEN_ISSUE_COUNT open release issues exceeds D-1 threshold (>10); escalate Tier 2 [SCOPE CHANGE] — possible Stage 12 chore PR did not land"
    return 2
  fi

  mark_phase "detect_open_issues" "PASS" "$OPEN_ISSUE_COUNT open release issues (auto-close anomaly candidates)"
  return 0
}

# ─── Phase 5: create_chore_branch ────────────────────────────────────────────

phase_create_chore_branch() {
  CHORE_BRANCH="chore/${VERSION}-stage-13-corpus-update"

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "create_chore_branch" "DRY-RUN" "would create branch: $CHORE_BRANCH"
    return 0
  fi

  # Idempotent: skip if branch already exists locally
  if $GIT -C "$REPO_ROOT" rev-parse --verify "$CHORE_BRANCH" >/dev/null 2>&1; then
    mark_phase "create_chore_branch" "SKIPPED" "branch $CHORE_BRANCH already exists locally"
    $GIT -C "$REPO_ROOT" checkout "$CHORE_BRANCH" >/dev/null 2>&1 || true
    return 0
  fi

  # Branch from origin/main (Stage 13 chore PR per pipeline/stage-13-close.md)
  if $GIT -C "$REPO_ROOT" checkout -b "$CHORE_BRANCH" origin/main >/dev/null 2>&1; then
    mark_phase "create_chore_branch" "PASS" "created $CHORE_BRANCH from origin/main"
    return 0
  fi
  mark_phase "create_chore_branch" "FAIL" "git checkout -b failed"
  return 3
}

# ─── Phase 6: transition_release_log (DEPLOYED → VERIFIED) ───────────────────

phase_transition_release_log() {
  local slug="$STATE_MILESTONE_SLUG"
  [[ -z "$slug" ]] && slug="$VERSION"

  # Idempotent: skip if row already VERIFIED
  if [[ "$STATE_LOG_ROW_STATE" == "VERIFIED" ]]; then
    mark_phase "transition_release_log" "SKIPPED" "row already VERIFIED"
    return 0
  fi

  local row
  row="$(find_log_row "$VERSION")"
  if [[ -z "$row" ]]; then
    mark_phase "transition_release_log" "FAIL" "row not found"
    return 3
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "transition_release_log" "DRY-RUN" "would replace trailing '| DEPLOYED |' with '| VERIFIED |' on $slug row"
    return 0
  fi

  # Use Python for in-place text edit (avoids BSD-sed -i incompatibility).
  /usr/bin/python3 - "$RELEASE_LOG" "$slug" <<'PY'
import sys, re
log_path, slug = sys.argv[1], sys.argv[2]
with open(log_path, "r", encoding="utf-8") as f:
    txt = f.read()
# Replace ONLY the trailing pipe-state on the line that begins with `| <slug> |`
pat = re.compile(r"(^\| " + re.escape(slug) + r" \|.*\| )DEPLOYED( \|$)", re.MULTILINE)
new_txt, n = pat.subn(r"\1VERIFIED\2", txt, count=1)
if n != 1:
    print(f"ERROR: expected 1 row match for slug='{slug}', got {n}", file=sys.stderr)
    sys.exit(3)
with open(log_path, "w", encoding="utf-8") as f:
    f.write(new_txt)
PY

  STATE_LOG_ROW_STATE="VERIFIED"
  mark_phase "transition_release_log" "PASS" "transitioned $slug row DEPLOYED → VERIFIED"
  return 0
}

# ─── Phase 7: append_release_index ───────────────────────────────────────────

phase_append_release_index() {
  local slug="$STATE_MILESTONE_SLUG"
  [[ -z "$slug" ]] && slug="$VERSION"

  # Idempotent: skip if row already present
  if /usr/bin/grep -qE "^\| ${slug} \|" "$RELEASE_INDEX" 2>/dev/null; then
    mark_phase "append_release_index" "SKIPPED" "INDEX row for $slug already present"
    return 0
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "append_release_index" "DRY-RUN" "would append row for $slug to RELEASE_INDEX.md (via $GENERATE_INDEX if executable, else hand-append)"
    return 0
  fi

  # Prefer generator script (deterministic); fall back to hand-append if missing
  if [[ -x "$GENERATE_INDEX" ]]; then
    if /usr/bin/python3 "$GENERATE_INDEX" >/dev/null 2>&1; then
      mark_phase "append_release_index" "PASS" "regenerated via generate_release_index.py"
      return 0
    fi
    # Fall through to hand-append on generator failure
  fi

  local date_str class_str scope_str plan_link note_link status_str
  date_str="$(date_today)"
  class_str="Minor"   # default; operator can update post-merge
  scope_str="—"        # populated by operator if known
  plan_link="[plan](plans/${VERSION}_RELEASE_PLAN.md)"
  note_link="[note](notes/${VERSION}_RELEASE_NOTES.md)"
  status_str="VERIFIED"

  # Hand-append after the header rule line: find first `| v` row + insert above
  /usr/bin/python3 - "$RELEASE_INDEX" "$slug" "$date_str" "$class_str" "$scope_str" "$plan_link" "$note_link" "$status_str" <<'PY'
import sys
path, slug, date, cls, scope, plan, note, status = sys.argv[1:9]
with open(path, "r", encoding="utf-8") as f:
    lines = f.read().splitlines()
new_row = f"| {slug} | {date} | {cls} | {scope} | {plan} | {note} | [LOG](RELEASE_LOG.md) | {status} |"
# Insert immediately after the first "|---|" separator line (chronological-recent-first)
out = []
inserted = False
for i, line in enumerate(lines):
    out.append(line)
    if (not inserted) and line.startswith("|---"):
        out.append(new_row)
        inserted = True
if not inserted:
    out.append(new_row)
with open(path, "w", encoding="utf-8") as f:
    f.write("\n".join(out) + "\n")
PY
  mark_phase "append_release_index" "PASS" "hand-appended row for $slug"
  return 0
}

# ─── Phase 8: append_release_digest ──────────────────────────────────────────

phase_append_release_digest() {
  local slug="$STATE_MILESTONE_SLUG"
  [[ -z "$slug" ]] && slug="$VERSION"
  local major
  major="$(extract_major "$VERSION")"
  [[ -z "$major" ]] && major="v?"

  # Idempotent: skip if entry already present
  if /usr/bin/grep -qE "^\| ${slug} \|" "$RELEASE_DIGEST" 2>/dev/null; then
    mark_phase "append_release_digest" "SKIPPED" "DIGEST entry for $slug already present"
    return 0
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "append_release_digest" "DRY-RUN" "would append entry for $slug under ${major}.* H2 family (create new H2 if novel major-prefix)"
    return 0
  fi

  # Insert: locate `## ${major}.*` H2 section, then append a table row at end of
  # the first table under it. If no H2 exists for this major, append new H2 +
  # canonical table header + row at end of file.
  /usr/bin/python3 - "$RELEASE_DIGEST" "$slug" "$VERSION" "$major" "$(date_today)" <<'PY'
import sys, re
path, slug, version, major, date = sys.argv[1:6]
with open(path, "r", encoding="utf-8") as f:
    lines = f.read().splitlines()

major_heading_re = re.compile(rf"^## {re.escape(major)}\.\* —")
section_start = None
for i, line in enumerate(lines):
    if major_heading_re.search(line):
        section_start = i
        break

new_row = f"| {slug} | {date} | <headline — populated by operator at chore PR review> |"

if section_start is None:
    # Append a new H2 + table + row at EOF
    block = [
        "",
        f"## {major}.* — (arc TBD; rename at major-prefix maturation)",
        "",
        "",
        f"### Releases",
        "",
        "| Version | Date | Headline |",
        "|---------|------|----------|",
        new_row,
    ]
    out = lines + block
else:
    # Find the last `| v...` row under this H2; insert new row immediately after.
    # Bound search to next H2 or EOF.
    section_end = len(lines)
    for j in range(section_start + 1, len(lines)):
        if lines[j].startswith("## "):
            section_end = j
            break
    # Find last table row line in [section_start, section_end)
    last_row_idx = None
    for j in range(section_start, section_end):
        if lines[j].startswith("| v") or (lines[j].startswith("| ") and lines[j].rstrip().endswith("|")):
            last_row_idx = j
    if last_row_idx is None:
        # No table found; insert at end of section
        last_row_idx = section_end - 1
    out = lines[:last_row_idx + 1] + [new_row] + lines[last_row_idx + 1:]

with open(path, "w", encoding="utf-8") as f:
    f.write("\n".join(out) + "\n")
PY
  mark_phase "append_release_digest" "PASS" "appended entry for $slug under ${major}.* H2"
  return 0
}

# ─── Phase 9: scaffold_release_notes (D5 — SCAFFOLD-ONLY) ────────────────────

phase_scaffold_release_notes() {
  local notes_path="${RELEASE_NOTES_DIR}/${VERSION}_RELEASE_NOTES.md"

  if [[ -f "$notes_path" ]]; then
    mark_phase "scaffold_release_notes" "SKIPPED" "RELEASE_NOTES.md already present for $VERSION (preserving operator prose)"
    return 0
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "scaffold_release_notes" "DRY-RUN" "would scaffold $notes_path (frontmatter + section H2 placeholders per release-notes-standard.md Part 1 Template); operator MUST fill prose before chore-PR merge"
    return 0
  fi

  local date_str
  date_str="$(date_today)"

  /bin/cat > "$notes_path" <<EOF
---
version: ${VERSION}
date: ${date_str}
type: note
issues: []
pr: "#${PR_NUMBER}"
links:
  plan: release/releases/plans/${VERSION}_RELEASE_PLAN.md
  log_anchor: "#${STATE_MILESTONE_SLUG:-${VERSION}}"
reversibility-tier: MODERATE
themes: []
summary: "<one-sentence ≤140 chars; plain language; agent-search target>"
requires_action: false
breaking: false
components: []
followups: []
---

# <Headline — user-visible capability, ≤80 chars>

${date_str} · ${VERSION}

<!-- agent: AUTHOR_SUMMARY_HERE — 2 sentences max. Impact before mechanism. JTBD framing. -->

<!-- agent: Include the skip-gate only if the release does not affect everyone using the platform. -->

<!-- agent: Section 4 — Who this affects. Omit when scope is universal. -->

<!-- agent: Section 5 — only if requires_action=true. -->

## What changed for everyone using the platform

<!-- agent: SECTION 6a — Layer A user-observability bullets per release-notes-standard.md § 2.1.
  - Max 5–7 bullets
  - Apply user-observability filter — only OBSERVABLE changes
  - Each bullet: (a) one-sentence plain WHAT; (b) *Why it matters:* consequence
  - No internal IDs as primary nouns; no file paths in bullet body
  - If filter removes everything: write "No user-visible behavior changes — see operator detail below"
-->

## Known limits

<!-- agent: enumerate carry-forward Issues, deferred items, OOS discoveries. -->

Report issues at https://github.com/cody-hutson/pmo-platform/issues.

## Reversibility

<!-- agent: state CHEAP/MODERATE/EXPENSIVE/IRREVERSIBLE + HIGH/MEDIUM/LOW confidence + 2-sentence rollback statement. -->

---

### Operator and engineering detail

<!-- agent: SECTION 6b — Layer B operator narrative.
  - Cite RELEASE_LOG row anchor for raw audit detail
  - Highlight unusual stage outcomes, cutover compliance, Tier 1/2/3 events
  - Narrative — not raw audit trail
-->
EOF
  mark_phase "scaffold_release_notes" "PASS" "scaffolded $notes_path (operator MUST fill prose before commit)"
  return 0
}

# ─── Phase 9.5: append_changelog (Layer-1 dual-write Surface 2) ──────────────
#
# Prepends a `## [vX.Y] - YYYY-MM-DD` Keep-a-Changelog H2 section to CHANGELOG.md
# at repo root, sourcing content from the canonical RELEASE_NOTES.md frontmatter.
# Surface 2 of the Layer-1 dual-write mechanism per release-notes-standard.md § Part 5.
#
# Idempotency: exact-version-match regex with whitespace terminator
# (adversarial FM-2: prefix-only match false-positives v2.04 vs v2.04b-3).
#
# Pre-CHANGELOG SKIP semantics: if CHANGELOG.md does not exist at repo root,
# SKIP with PASS — Phase 9.5 becomes load-bearing on the FIRST release after
# CHANGELOG.md is introduced.
#
phase_append_changelog() {
  local notes_path="${RELEASE_NOTES_DIR}/${VERSION}_RELEASE_NOTES.md"
  local changelog_path="$REPO_ROOT/CHANGELOG.md"

  # Preflight: CHANGELOG.md must exist
  if [[ ! -f "$changelog_path" ]]; then
    mark_phase "append_changelog" "SKIPPED" "CHANGELOG.md not present at repo root (pre-CHANGELOG state); skipping append"
    return 0
  fi

  # Idempotency: exact-version-match regex with whitespace terminator
  # (FM-2: prefix-only match would false-positive on shared-prefix versions)
  if /usr/bin/grep -qE "^## \[?${VERSION}\]?[[:space:]]" "$changelog_path" 2>/dev/null; then
    mark_phase "append_changelog" "SKIPPED" "${VERSION} already present in CHANGELOG.md (idempotency guard)"
    return 0
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "append_changelog" "DRY-RUN" "would prepend ## [${VERSION}] section to CHANGELOG.md (content sourced from ${notes_path} Section 6a per release-notes-standard.md § 5.3 transform)"
    return 0
  fi

  # Synthesize Keep-a-Changelog block from RELEASE_NOTES frontmatter + Section 6a
  # Implementation: read notes_path frontmatter (date, themes, summary); compose:
  #   ## [vX.Y] - YYYY-MM-DD
  #   <one-line summary from frontmatter `summary` field>
  #   [Full notes](release/releases/notes/vX.Y_RELEASE_NOTES.md) · [Release](https://github.com/${REPO_SLUG}/releases/tag/vX.Y)
  #
  # Then prepend to CHANGELOG.md immediately under "## [Unreleased]" (if present)
  # OR immediately below the K-a-C header (preserves header + reverse-chronological order
  # per K-a-C 1.1.0 convention).

  if ! /usr/bin/python3 - "$changelog_path" "$notes_path" "$VERSION" "$REPO_SLUG" <<'PY' 2>/dev/null
import sys, re, datetime
changelog, notes, version, repo_slug = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

# Parse notes frontmatter (existing convention: YAML between --- markers)
with open(notes) as f:
    content = f.read()
m = re.match(r'---\n(.*?)\n---\n', content, re.DOTALL)
fm = m.group(1) if m else ""
date_m = re.search(r'^date:\s*([0-9-]+)', fm, re.MULTILINE)
summary_m = re.search(r'^summary:\s*"?([^"\n]+)"?', fm, re.MULTILINE)
date = date_m.group(1) if date_m else datetime.date.today().isoformat()
summary = summary_m.group(1).strip() if summary_m else "(see release notes)"

block = f"""## [{version}] - {date}

{summary}

[Full notes](release/releases/notes/{version}_RELEASE_NOTES.md) · [Release](https://github.com/{repo_slug}/releases/tag/{version})

"""

with open(changelog) as f:
    existing = f.read()

# Find insertion point per K-a-C convention:
# Prefer immediately after `## [Unreleased]` block if present;
# Otherwise immediately before first existing `## [vN...` entry;
# Otherwise append at end.
unreleased_m = re.search(r'^## \[Unreleased\][^\n]*\n', existing, re.MULTILINE)
first_version_m = re.search(r'^## \[?v[0-9]', existing, re.MULTILINE)

if unreleased_m:
    # Insert after the Unreleased H2 block (find next H2 or end)
    after_unreleased = unreleased_m.end()
    next_h2 = re.search(r'^## ', existing[after_unreleased:], re.MULTILINE)
    insert_pos = after_unreleased + (next_h2.start() if next_h2 else len(existing) - after_unreleased)
    new = existing[:insert_pos] + block + existing[insert_pos:]
elif first_version_m:
    new = existing[:first_version_m.start()] + block + existing[first_version_m.start():]
else:
    new = existing.rstrip() + "\n\n" + block

with open(changelog, 'w') as f:
    f.write(new)
PY
  then
    mark_phase "append_changelog" "FAIL" "python3 CHANGELOG synthesis failed (frontmatter malformed or file unreadable)"
    return 3
  fi

  mark_phase "append_changelog" "PASS" "prepended ## [${VERSION}] section to CHANGELOG.md (Surface 2 of Layer-1 dual-write)"
  return 0
}

# ─── Phase 10-12: commit_chore_pr / create_chore_pr / await_merge ────────────

build_chore_pr_body() {
  local slug="$STATE_MILESTONE_SLUG"
  [[ -z "$slug" ]] && slug="$VERSION"
  local deferred_summary="none (clean close)"
  if [[ "$OPEN_ISSUE_COUNT" -gt 0 ]]; then
    deferred_summary="${OPEN_ISSUE_COUNT} open issue(s) at close (D-1 manual close pending — see Phase 14)"
  fi

  /bin/cat <<EOF
## Summary

${VERSION} Stage 13 close-out chore PR — release-corpus updates per pipeline/stage-13-close.md § Phase B commit mechanism.

## Changes

| File | Change | Notes |
|------|--------|-------|
| release/releases/RELEASE_LOG.md | EDIT | Transition ${slug} row state DEPLOYED → VERIFIED (Surface 3 of Layer-1 dual-write) |
| release/releases/RELEASE_INDEX.md | EDIT | Append ${slug} row per D6 |
| release/releases/RELEASE_DIGEST.md | EDIT | Append ${slug} entry under v$(extract_major "$VERSION").* family per D6 |
| release/releases/notes/${VERSION}_RELEASE_NOTES.md | NEW | Scaffolded per release-notes-standard.md Part 1 Template; operator-filled prose |
| CHANGELOG.md | EDIT | Prepend ## [${slug}] - YYYY-MM-DD section per Keep-a-Changelog 1.1.0 (Surface 2 of Layer-1 dual-write — SKIPPED if CHANGELOG.md absent) |

## Deferred items

${deferred_summary}

## Verification

- Pre-merge: parser-clean spot-check on this body PASS (no auto-close keywords)
- Post-merge: RELEASE_LOG ${slug} row state = VERIFIED; INDEX + DIGEST entries present on main; RELEASE_NOTES file present

## Cycle time

${STATE_CYCLE_TIME}

## Cross-references

- Release plan: release/releases/plans/${VERSION}_RELEASE_PLAN.md
- Release PR: #${PR_NUMBER}
- Milestone: ${slug} (#${MILESTONE})

## Issue References

This chore PR ships release-corpus updates only. Release-issue auto-close was handled by the Stage 12 release PR (#${PR_NUMBER}). This chore PR has no Issue References block by design.
EOF
}

phase_commit_chore_pr() {
  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "commit_chore_pr" "DRY-RUN" "would: git add RELEASE_LOG.md RELEASE_INDEX.md RELEASE_DIGEST.md RELEASE_NOTES.md CHANGELOG.md (if present) && git commit -m 'chore(${VERSION}): Stage 13 — INDEX + DIGEST + RELEASE_NOTES + CHANGELOG'"
    return 0
  fi

  local files=(
    "release/releases/RELEASE_LOG.md"
    "release/releases/RELEASE_INDEX.md"
    "release/releases/RELEASE_DIGEST.md"
    "release/releases/notes/${VERSION}_RELEASE_NOTES.md"
    "CHANGELOG.md"
  )

  # Stage only files that actually exist + have changes
  local staged=0
  for f in "${files[@]}"; do
    if [[ -f "$REPO_ROOT/$f" ]]; then
      $GIT -C "$REPO_ROOT" add "$f" 2>/dev/null || true
      staged=1
    fi
  done

  if [[ -z "$($GIT -C "$REPO_ROOT" diff --staged --name-only 2>/dev/null)" ]]; then
    mark_phase "commit_chore_pr" "SKIPPED" "nothing staged — phases 6-9 + 9.5 were no-op (already up-to-date)"
    return 0
  fi

  local commit_msg="chore(${VERSION}): Stage 13 — INDEX + DIGEST + RELEASE_NOTES + CHANGELOG"
  if $GIT -C "$REPO_ROOT" commit -m "$commit_msg" >/dev/null 2>&1; then
    mark_phase "commit_chore_pr" "PASS" "committed: $commit_msg"
    return 0
  fi
  mark_phase "commit_chore_pr" "FAIL" "git commit failed"
  return 3
}

phase_create_chore_pr() {
  local body
  body="$(build_chore_pr_body)"

  # Pre-submit parser-clean check (D9 forcing function)
  if ! check_parser_clean "$body"; then
    mark_phase "create_chore_pr" "FAIL" "chore PR body contains close-family verbs + #N — parser-clean discipline violated (D9)"
    return 3
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "create_chore_pr" "DRY-RUN" "body parser-clean PASS; would: gh pr create --title 'chore(${VERSION}): Stage 13 — INDEX + DIGEST + RELEASE_NOTES + CHANGELOG'"
    return 0
  fi

  # Push branch (git_net layers the gh-backed credential helper so a locked
  # Keychain degrades gracefully instead of hanging on credential resolution).
  git_net -C "$REPO_ROOT" push -u origin "$CHORE_BRANCH" >/dev/null 2>&1 || true

  # Idempotency: skip if PR already exists for branch
  local existing_pr
  existing_pr="$($GH pr list --repo "$REPO_SLUG" --head "$CHORE_BRANCH" --state open --json number --jq '.[0].number // ""' 2>/dev/null || echo "")"
  if [[ -n "$existing_pr" ]]; then
    CHORE_PR_NUMBER="$existing_pr"
    mark_phase "create_chore_pr" "SKIPPED" "PR #$existing_pr already exists for branch"
    return 0
  fi

  local tmp_body
  tmp_body="$(/usr/bin/mktemp -t closeout-body.XXXXXX)"
  /usr/bin/printf '%s\n' "$body" > "$tmp_body"

  local pr_url
  pr_url="$($GH pr create \
    --repo "$REPO_SLUG" \
    --title "chore(${VERSION}): Stage 13 — INDEX + DIGEST + RELEASE_NOTES + CHANGELOG" \
    --body-file "$tmp_body" \
    --milestone "${STATE_MILESTONE_SLUG}" \
    --assignee "@me" 2>&1)" || {
      /bin/rm -f "$tmp_body"
      mark_phase "create_chore_pr" "FAIL" "gh pr create failed: $pr_url"
      return 3
    }
  /bin/rm -f "$tmp_body"
  CHORE_PR_NUMBER="$(/usr/bin/printf '%s' "$pr_url" | /usr/bin/grep -oE '[0-9]+$' | /usr/bin/tail -1)"
  mark_phase "create_chore_pr" "PASS" "created PR #${CHORE_PR_NUMBER} ($pr_url)"
  return 0
}

phase_await_merge_chore_pr() {
  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "await_merge_chore_pr" "DRY-RUN" "would poll mergeStateStatus per Stage 12 Phase A.6 (4-tier backoff 3s/5s/10s/12s) then gh pr merge --merge --delete-branch"
    return 0
  fi

  if [[ -z "$CHORE_PR_NUMBER" ]]; then
    mark_phase "await_merge_chore_pr" "FAIL" "no chore PR number recorded"
    return 3
  fi

  # Brief poll per Stage 12 Phase A.6 (3s/5s/10s/12s = 30s cap)
  local backoff=(3 5 10 12)
  local merge_state="UNKNOWN"
  for delay in "${backoff[@]}"; do
    merge_state="$($GH pr view "$CHORE_PR_NUMBER" --repo "$REPO_SLUG" --json mergeStateStatus,mergeable --jq '"\(.mergeable)/\(.mergeStateStatus)"' 2>/dev/null || echo "ERROR")"
    case "$merge_state" in
      MERGEABLE/CLEAN) break ;;
      CONFLICTING/*|MERGEABLE/DIRTY) mark_phase "await_merge_chore_pr" "FAIL" "merge state=$merge_state; HALT — escalate Tier 2 [SCOPE CHANGE]"; return 3 ;;
    esac
    /bin/sleep "$delay"
  done

  if [[ "$merge_state" != "MERGEABLE/CLEAN" ]]; then
    mark_phase "await_merge_chore_pr" "FAIL" "merge state still=$merge_state after 30s polling — escalate"
    return 3
  fi

  if $GH pr merge "$CHORE_PR_NUMBER" --repo "$REPO_SLUG" --merge --delete-branch >/dev/null 2>&1; then
    mark_phase "await_merge_chore_pr" "PASS" "merged PR #${CHORE_PR_NUMBER}"
    return 0
  fi
  mark_phase "await_merge_chore_pr" "FAIL" "gh pr merge failed"
  return 3
}

# ─── Phase 13: post_close_milestone (Hub Tier-1 mechanical) ──────────────────

phase_post_close_milestone() {
  if [[ "$STATE_MILESTONE_STATE" == "closed" ]]; then
    mark_phase "post_close_milestone" "SKIPPED" "milestone already closed"
    return 0
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "post_close_milestone" "DRY-RUN" "would: gh api repos/${REPO_SLUG}/milestones/${MILESTONE} -X PATCH -F state=closed"
    return 0
  fi

  if $GH api "repos/${REPO_SLUG}/milestones/${MILESTONE}" -X PATCH -F state=closed >/dev/null 2>&1; then
    STATE_MILESTONE_STATE="closed"
    mark_phase "post_close_milestone" "PASS" "milestone #${MILESTONE} closed"
    return 0
  fi
  mark_phase "post_close_milestone" "FAIL" "gh api PATCH state=closed failed"
  return 3
}

# ─── Phase 14: manual_close_release_issues (D6 — D-1 anomaly handler) ────────

phase_manual_close_release_issues() {
  if [[ "$OPEN_ISSUE_COUNT" -eq 0 ]]; then
    mark_phase "manual_close_release_issues" "SKIPPED" "no open release issues to manually close"
    return 0
  fi

  local plan_ref="release/releases/plans/${VERSION}_RELEASE_PLAN.md"
  local comment_template="Manually closed at Stage 13 per D-1 — auto-close anomaly (constituent PRs merged to release branch, not default-branch). Per release plan ${plan_ref}."

  if [[ "$MODE" == "dry-run" ]]; then
    local issue_list
    issue_list="$(/usr/bin/printf '%s' "$OPEN_ISSUE_LIST" | /usr/bin/tr '\n' ',' | /usr/bin/sed 's/,$//')"
    mark_phase "manual_close_release_issues" "DRY-RUN" "would close ${OPEN_ISSUE_COUNT} issue(s) [#${issue_list//,/, #}] with comment: $comment_template"
    return 0
  fi

  local closed_count=0
  while IFS= read -r issue_n; do
    [[ -z "$issue_n" ]] && continue
    if $GH issue close "$issue_n" --repo "$REPO_SLUG" --comment "$comment_template" >/dev/null 2>&1; then
      closed_count=$((closed_count + 1))
    fi
  done <<< "$OPEN_ISSUE_LIST"

  mark_phase "manual_close_release_issues" "PASS" "closed ${closed_count}/${OPEN_ISSUE_COUNT} release issues per D-1"
  return 0
}

# ─── Phase 15: run_verification + post_gate_passage_proof ────────────────────

phase_run_verification() {
  local slug="$STATE_MILESTONE_SLUG"
  [[ -z "$slug" ]] && slug="$VERSION"

  # 5 universal verification commands per hub-spoke-bridge.md Procedure 7 Step 4
  local v_notes v_tag v_milestone v_log v_subs
  v_notes="$([[ -f "${RELEASE_NOTES_DIR}/${VERSION}_RELEASE_NOTES.md" ]] && echo PASS || echo FAIL)"
  v_tag="$([[ "$STATE_TAG_EXISTS" -eq 1 ]] && echo PASS || echo FAIL)"
  v_milestone="$([[ "$STATE_MILESTONE_STATE" == "closed" ]] && echo PASS || echo PENDING)"
  v_log="$([[ "$STATE_LOG_ROW_STATE" == "VERIFIED" ]] && echo PASS || echo PENDING)"
  v_subs="$([[ "$OPEN_ISSUE_COUNT" -eq 0 ]] && echo PASS || echo "PARTIAL (${OPEN_ISSUE_COUNT} open)")"

  VERIFICATION_RESULTS=$(/bin/cat <<EOF
| # | Check | Method | Result |
|---|-------|--------|--------|
| 1 | RELEASE_NOTES.md present | test -f releases/notes/${VERSION}_RELEASE_NOTES.md | ${v_notes} |
| 2 | Annotated tag present | git tag -l ${VERSION} | ${v_tag} |
| 3 | Milestone closed | gh api milestones/${MILESTONE} | ${v_milestone} |
| 4 | RELEASE_LOG row VERIFIED | grep '\| ${slug} \|' RELEASE_LOG.md | ${v_log} |
| 5 | All release issues closed | gh issue list --milestone | ${v_subs} |
EOF
)

  mark_phase "run_verification" "PASS" "5 universal checks evaluated"

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "post_gate_passage_proof" "DRY-RUN" "would post gate-passage proof comment to Stage 13 sub-task per the gate-passage-proof template"
    return 0
  fi

  # Posting the comment requires the Stage 13 sub-task number, which the hub
  # supplies via the chip prompt. Defer the comment-post to the hub at apply
  # time; here we emit the comment text for the operator to copy/paste.
  mark_phase "post_gate_passage_proof" "MANUAL" "comment text emitted in final report; hub posts to Stage 13 sub-task per the gate-passage-proof template"
  return 0
}

# ─── Phase 15.5: publish_github_release (Layer-1 dual-write Surface 1) ───────────
#
# Publishes the canonical public release-notes surface (Surface 1) via GitHub Releases API.
# Uses view-then-create-or-edit state machine per release-notes-standard.md § 5.5:
#   - State 0 (release does not exist) → gh release create
#   - State 1 (release exists, body differs) → gh release edit
#   - State 2 (release at canonical content) → no-op PASS
#
# Composes with release-executor Mode F (standalone fix-forward invocation path).
# Both Phase 15.5 + Mode F share the view-then-create-or-edit guard — safe re-invocation.
#
# FM-3: `git ls-remote --tags origin` is the SINGLE tag-existence preflight
# (`--verify-tag` intentionally omitted — single source of truth, clearer error message).
# FM-4: headline extraction falls back to "Release Notes" if no H1 present
# (avoids degraded "vX.Y — vX.Y" title surfacing publicly).
#
phase_publish_github_release() {
  local notes_path="${RELEASE_NOTES_DIR}/${VERSION}_RELEASE_NOTES.md"

  # Preflight 1: tag must exist on origin (Stage 12 Phase B3 push pre-requisite).
  # git_net layers the gh-backed credential helper (locked-Keychain degradation).
  if ! git_net -C "$REPO_ROOT" ls-remote --tags origin "$VERSION" 2>/dev/null | /usr/bin/grep -q "$VERSION"; then
    mark_phase "publish_github_release" "FAIL" "tag $VERSION not present on origin (Stage 12 Phase B3 may not have run; canonical recovery: git push origin $VERSION OR re-invoke Stage 12 spoke)"
    return 3
  fi

  # Preflight 2: notes file should be resolvable (warning, not blocker)
  if [[ ! -f "$notes_path" ]]; then
    mark_phase "publish_github_release" "FAIL" "RELEASE_NOTES file not present at $notes_path (Stage 13 chore PR may not have merged or scaffold step may not have run)"
    return 3
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "publish_github_release" "DRY-RUN" "would invoke view-then-create-or-edit state machine: gh release view $VERSION → create OR edit OR no-op (per release-notes-standard.md § 5.5)"
    return 0
  fi

  # View-then-create-or-edit state machine
  if $GH release view "$VERSION" --repo "$REPO_SLUG" >/dev/null 2>&1; then
    # State 1 or 2 — release exists; compare body
    local existing_body canonical_body
    existing_body="$($GH release view "$VERSION" --repo "$REPO_SLUG" --json body --jq .body 2>/dev/null)"
    canonical_body="$(/usr/bin/sed '1,/^---$/d; 1,/^---$/d' "$notes_path" 2>/dev/null)"

    if [[ "$existing_body" == "$canonical_body" ]]; then
      mark_phase "publish_github_release" "SKIPPED" "GitHub Release $VERSION already at canonical content (State 2 no-op per release-notes-standard.md § 5.5)"
      return 0
    fi

    # State 1 → State 2 transition via idempotent gh release edit
    if $GH release edit "$VERSION" --repo "$REPO_SLUG" --notes "$canonical_body" >/dev/null 2>&1; then
      mark_phase "publish_github_release" "PASS" "edited GitHub Release $VERSION (State 1 → State 2 transition; body refreshed from canonical notes)"
      return 0
    fi
    mark_phase "publish_github_release" "FAIL" "gh release edit failed for existing release $VERSION"
    return 3
  fi

  # State 0 — release does not exist; create
  # Extract headline from canonical notes H1; fallback per FM-4
  local headline
  headline="$(/usr/bin/grep -m1 '^# ' "$notes_path" 2>/dev/null | /usr/bin/sed 's/^# //' || echo "")"
  if [[ -z "$headline" || "$headline" == "$VERSION" ]]; then
    headline="Release Notes"
  fi

  # Surface 1 body = the note minus its YAML frontmatter (the committed notes
  # file is the source of record; the Release page is the rendered copy people
  # read). See release-notes-standard.md § 5.1.
  local notes_body
  notes_body="$(/usr/bin/sed '1,/^---$/d; 1,/^---$/d' "$notes_path" 2>/dev/null)"

  # MERGE_SHA: if available from prior phase capture, use it; otherwise omit --target
  local target_args=""
  if [[ -n "${MERGE_SHA:-}" ]]; then
    target_args="--target $MERGE_SHA"
  fi

  # shellcheck disable=SC2086
  if $GH release create "$VERSION" \
    --repo "$REPO_SLUG" \
    --title "$VERSION — $headline" \
    --notes "$notes_body" \
    $target_args >/dev/null 2>&1; then
    mark_phase "publish_github_release" "PASS" "created GitHub Release $VERSION (Surface 1 of Layer-1 dual-write; title='$VERSION — $headline')"
    return 0
  fi
  mark_phase "publish_github_release" "FAIL" "gh release create failed for new release $VERSION (canonical recovery: re-run Phase 15.5 OR invoke release-executor Mode F standalone)"
  return 3
}

# ─── Phase 16: invoke_orphan_cleanup ─────────────────────────────────────────

phase_invoke_orphan_cleanup() {
  if [[ ! -x "$CLEANUP_TOOL" ]]; then
    mark_phase "invoke_orphan_cleanup" "SKIPPED" "cleanup-orphan-state.sh not executable at $CLEANUP_TOOL"
    return 0
  fi

  local slug="$STATE_MILESTONE_SLUG"
  [[ -z "$slug" ]] && slug="$VERSION"

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "invoke_orphan_cleanup" "DRY-RUN" "would invoke: $CLEANUP_TOOL --release-close $slug --dry-run --markdown"
    return 0
  fi

  # Chained tool defaults to dry-run; operator re-runs with --apply
  if "$CLEANUP_TOOL" --release-close "$slug" --dry-run --markdown >/dev/null 2>&1; then
    mark_phase "invoke_orphan_cleanup" "PASS" "cleanup dry-run report generated (operator reviews + re-invokes with --apply)"
    return 0
  fi
  mark_phase "invoke_orphan_cleanup" "FAIL" "cleanup-orphan-state.sh dry-run returned non-zero"
  return 3
}

# ─── Phase 17 (optional): pattern_scan (synthesizer) ─────────────────────────

phase_pattern_scan() {
  if [[ "$WITH_PATTERN_SCAN" -eq 0 ]]; then
    mark_phase "pattern_scan" "N/A" "not requested (use --with-pattern-scan to enable)"
    return 0
  fi

  if [[ ! -x "$SYNTHESIZE_LEARNINGS" ]]; then
    mark_phase "pattern_scan" "SKIPPED" "synthesize-release-learnings.sh not executable"
    return 0
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "pattern_scan" "DRY-RUN" "would invoke: $SYNTHESIZE_LEARNINGS --mode pattern-detect --window 5"
    return 0
  fi

  if "$SYNTHESIZE_LEARNINGS" --mode pattern-detect --window 5 >/dev/null 2>&1; then
    mark_phase "pattern_scan" "PASS" "pattern-detect scan emitted (dry-run default; no Issues created)"
    return 0
  fi
  mark_phase "pattern_scan" "FAIL" "synthesizer pattern-detect failed"
  return 3
}

# ─── Phase 17/18: generate_report ────────────────────────────────────────────

generate_markdown_report() {
  local slug="$STATE_MILESTONE_SLUG"
  [[ -z "$slug" ]] && slug="$VERSION"

  /bin/cat <<EOF
# Stage 13 Automated Close-Out Report — ${VERSION}

**Generated:** ${RUN_TS}
**Mode:** ${MODE}
**Release PR:** #${PR_NUMBER}
**Milestone:** ${slug} (#${MILESTONE})
**Chore PR:** ${CHORE_PR_NUMBER:+#${CHORE_PR_NUMBER}}${CHORE_PR_NUMBER:-N/A — dry-run or not-yet-created}

## State

- RELEASE_LOG row state: **${STATE_LOG_ROW_STATE}**
- Milestone state: **${STATE_MILESTONE_STATE}**
- Annotated tag exists: $([[ "$STATE_TAG_EXISTS" -eq 1 ]] && echo YES || echo NO)
- Cycle time: ${STATE_CYCLE_TIME}
- Open release issues at close: ${OPEN_ISSUE_COUNT}

## Phase Outcomes

| Phase | Result | Detail |
|-------|--------|--------|
EOF
  local phases=(preflight read_state detect_open_issues create_chore_branch transition_release_log append_release_index append_release_digest scaffold_release_notes append_changelog commit_chore_pr create_chore_pr await_merge_chore_pr post_close_milestone manual_close_release_issues run_verification post_gate_passage_proof publish_github_release invoke_orphan_cleanup pattern_scan)
  local p rd r d
  for p in "${phases[@]}"; do
    rd="$(get_phase "$p")"
    r="${rd%|*}"
    d="${rd#*|}"
    /usr/bin/printf '| %s | %s | %s |\n' "$p" "$r" "$d"
  done
  echo
  echo "## Verification"
  echo
  /usr/bin/printf '%s\n' "$VERIFICATION_RESULTS"
  echo
  if [[ "$OPEN_ISSUE_COUNT" -gt 0 ]]; then
    echo "## D-1 Manual-Close Candidates"
    echo
    while IFS= read -r issue_n; do
      [[ -z "$issue_n" ]] && continue
      echo "- #${issue_n}"
    done <<< "$OPEN_ISSUE_LIST"
    echo
  fi
  if [[ "$MODE" == "dry-run" ]]; then
    echo "**Next step:** review this dry-run report, then re-invoke with \`--apply\` to execute Phases 5-16."
  fi
}

generate_json_report() {
  local slug="$STATE_MILESTONE_SLUG"
  [[ -z "$slug" ]] && slug="$VERSION"
  /usr/bin/python3 - "$RUN_TS" "$MODE" "$PR_NUMBER" "$VERSION" "$MILESTONE" "$slug" \
    "$STATE_LOG_ROW_STATE" "$STATE_MILESTONE_STATE" "$STATE_TAG_EXISTS" \
    "$STATE_CYCLE_TIME" "$OPEN_ISSUE_COUNT" "$CHORE_PR_NUMBER" "$OPEN_ISSUE_LIST" <<'PY'
import sys, json
ts, mode, pr, version, milestone, slug, log_state, ms_state, tag, cycle, open_n, chore_pr, open_list = sys.argv[1:14]
issues = [int(x) for x in open_list.split("\n") if x.strip()]
payload = {
    "timestamp": ts,
    "mode": mode,
    "release_pr": int(pr) if pr.isdigit() else pr,
    "version": version,
    "milestone": {"number": int(milestone), "slug": slug, "state": ms_state},
    "release_log": {"row_state": log_state, "tag_present": bool(int(tag))},
    "cycle_time": cycle,
    "chore_pr": int(chore_pr) if chore_pr.isdigit() else None,
    "d1_manual_close_candidates": {"count": int(open_n), "issues": issues},
}
print(json.dumps(payload, indent=2))
PY
}

generate_report() {
  case "$OUTPUT" in
    markdown) generate_markdown_report ;;
    json) generate_json_report ;;
  esac
}

# ─── Self-test ───────────────────────────────────────────────────────────────

self_test() {
  echo "self-test: starting" >&2
  local failures=0

  # Test 1: validate_version
  validate_version "v2.12" || { echo "FAIL: validate_version v2.12"; failures=$((failures+1)); }
  validate_version "v2.07b" || { echo "FAIL: validate_version v2.07b"; failures=$((failures+1)); }
  validate_version "v2.04b-1" || { echo "FAIL: validate_version v2.04b-1"; failures=$((failures+1)); }
  ! validate_version "2.12" || { echo "FAIL: validate_version should reject 2.12 (no v prefix)"; failures=$((failures+1)); }
  ! validate_version "" || { echo "FAIL: validate_version should reject empty"; failures=$((failures+1)); }

  # Test 2: extract_major
  [[ "$(extract_major v2.12)" == "v2" ]] || { echo "FAIL: extract_major v2.12 should be v2"; failures=$((failures+1)); }
  [[ "$(extract_major v2.07b)" == "v2" ]] || { echo "FAIL: extract_major v2.07b should be v2"; failures=$((failures+1)); }

  # Test 3: extract_row_state — current 8-column schema (State precedes trailing
  # Date). The row matches the live RELEASE_LOG schema
  # `| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |`;
  # the assertion proves the State (field 7) is returned and the trailing Date
  # (field 8) is NOT mistaken for it.
  local sample_row="| v3.18 | v3.18-corpus-integrity-enforcement | issues | pr | sha | tag | VERIFIED | 2026-06-03 |"
  [[ "$(extract_row_state "$sample_row")" == "VERIFIED" ]] || { echo "FAIL: extract_row_state (8-col, trailing Date) should return VERIFIED, got '$(extract_row_state "$sample_row")'"; failures=$((failures+1)); }
  [[ "$(extract_row_state "$sample_row")" != "2026-06-03" ]] || { echo "FAIL: extract_row_state (8-col) returned the trailing Date, not the State"; failures=$((failures+1)); }

  # legacy 5-column schema (State is the trailing field) — must still resolve
  sample_row="| v2.07b-stage-execution-and-process-discipline | 2026-05-19 | Foundation | summary | DEPLOYED |"
  [[ "$(extract_row_state "$sample_row")" == "DEPLOYED" ]] || { echo "FAIL: extract_row_state (5-col) should return DEPLOYED, got '$(extract_row_state "$sample_row")'"; failures=$((failures+1)); }

  # Test 4: extract_milestone_slug — schema-aware (must return the slug, not the
  # bare Version, regardless of column position).
  # 8-column schema: field 1 is the Version (v3.18), field 2 is the slug.
  sample_row="| v3.18 | v3.18-corpus-integrity-enforcement | issues | pr | sha | tag | VERIFIED | 2026-06-03 |"
  [[ "$(extract_milestone_slug "$sample_row")" == "v3.18-corpus-integrity-enforcement" ]] || { echo "FAIL: extract_milestone_slug (8-col) should return field-2 slug, got '$(extract_milestone_slug "$sample_row")'"; failures=$((failures+1)); }
  [[ "$(extract_milestone_slug "$sample_row")" != "v3.18" ]] || { echo "FAIL: extract_milestone_slug (8-col) returned the bare Version (field 1), not the slug (field 2)"; failures=$((failures+1)); }
  # legacy 5-column schema: the slug is field 1.
  sample_row="| v2.10-content-audits | 2026-05-23 | Foundation | summary | VERIFIED |"
  [[ "$(extract_milestone_slug "$sample_row")" == "v2.10-content-audits" ]] || { echo "FAIL: extract_milestone_slug (5-col) got '$(extract_milestone_slug "$sample_row")'"; failures=$((failures+1)); }
  # version-with-letter-and-qualifier carrying a slug tail (v2.04b-1-…) resolves.
  sample_row="| v2.04b-1 | v2.04b-1-hotfix-rollup | #1 | pr | sha | tag | VERIFIED | 2026-06-03 |"
  [[ "$(extract_milestone_slug "$sample_row")" == "v2.04b-1-hotfix-rollup" ]] || { echo "FAIL: extract_milestone_slug (8-col, vN.Nb-N qualifier) got '$(extract_milestone_slug "$sample_row")'"; failures=$((failures+1)); }

  # Test 5: check_parser_clean — must reject close-family + #N
  check_parser_clean "Safe summary text" || { echo "FAIL: parser-clean on safe text"; failures=$((failures+1)); }
  ! check_parser_clean "This closes #123" || { echo "FAIL: parser-clean should reject 'closes #123'"; failures=$((failures+1)); }
  ! check_parser_clean "fixes #45" || { echo "FAIL: parser-clean should reject 'fixes #45'"; failures=$((failures+1)); }
  ! check_parser_clean "resolves #999" || { echo "FAIL: parser-clean should reject 'resolves #999'"; failures=$((failures+1)); }
  ! check_parser_clean "does not close #234" || { echo "FAIL: parser-clean should reject negated form 'close #234' (lexical, not semantic)"; failures=$((failures+1)); }
  check_parser_clean "mark #234 as closed" || { echo "FAIL: parser-clean should ACCEPT safe phrasing 'mark #N as closed'"; failures=$((failures+1)); }

  # Test 6: corpus-path resolution — HARD assertion (not a soft WARN).
  # The four corpus paths are what every --apply phase mutates; if the script is
  # re-pathed out from under the corpus (the migration-drift failure that surfaced
  # when the close-out was first run post-rename), the close-out silently writes
  # nowhere. A soft WARN here let the self-test pass green while every path was
  # wrong — so this is now a hard FAIL that increments `failures`, making the CI
  # smoke gate a real backstop against path rot.
  local corpus_path
  for corpus_path in "$RELEASE_LOG" "$RELEASE_INDEX" "$RELEASE_DIGEST" "$RELEASE_NOTES_DIR"; do
    if [[ ! -e "$corpus_path" ]]; then
      echo "FAIL: corpus path does not resolve: $corpus_path (RELEASE_LOG/INDEX/DIGEST must be files, RELEASE_NOTES_DIR a directory; re-pathing drift?)"
      failures=$((failures+1))
    fi
  done
  # RELEASE_LOG/INDEX/DIGEST must be regular files; RELEASE_NOTES_DIR a directory.
  for corpus_path in "$RELEASE_LOG" "$RELEASE_INDEX" "$RELEASE_DIGEST"; do
    if [[ -e "$corpus_path" && ! -f "$corpus_path" ]]; then
      echo "FAIL: corpus path resolves but is not a regular file: $corpus_path"
      failures=$((failures+1))
    fi
  done
  if [[ -e "$RELEASE_NOTES_DIR" && ! -d "$RELEASE_NOTES_DIR" ]]; then
    echo "FAIL: RELEASE_NOTES_DIR resolves but is not a directory: $RELEASE_NOTES_DIR"
    failures=$((failures+1))
  fi
  # find_log_row sanity: the live RELEASE_LOG must contain at least one parseable
  # version row (proves the row-matching regex still matches the current schema).
  if [[ -f "$RELEASE_LOG" ]]; then
    local first_log_row
    first_log_row="$(/usr/bin/grep -m1 -E '^\| v[0-9]+\.[0-9]' "$RELEASE_LOG" || true)"
    if [[ -z "$first_log_row" ]]; then
      echo "FAIL: RELEASE_LOG has no parseable '| vX.Y' version row — row format may have drifted"
      failures=$((failures+1))
    fi
  fi

  # Test 7: usage block extractable
  if ! /usr/bin/sed -n '2,67p' "${BASH_SOURCE[0]}" | /usr/bin/grep -q "Usage:"; then
    echo "FAIL: usage block extraction"; failures=$((failures+1))
  fi

  # Test 8: chore-PR body has zero parser-clean violations
  VERSION="v2.10"
  PR_NUMBER=2491
  MILESTONE=43
  STATE_MILESTONE_SLUG="v2.10-content-audits"
  STATE_CYCLE_TIME="N/A"
  OPEN_ISSUE_COUNT=0
  local body
  body="$(build_chore_pr_body)"
  if ! check_parser_clean "$body"; then
    echo "FAIL: built chore-PR body is NOT parser-clean (D9 violation)"
    failures=$((failures+1))
  fi

  # Test 9: JSON report renders valid JSON
  RUN_TS="$(ts_now)"
  MODE="dry-run"
  STATE_LOG_ROW_STATE="DEPLOYED"
  STATE_MILESTONE_STATE="open"
  STATE_TAG_EXISTS=1
  CHORE_PR_NUMBER=""
  OPEN_ISSUE_LIST=""
  local json_out
  json_out="$(generate_json_report)"
  if ! /usr/bin/printf '%s' "$json_out" | /usr/bin/python3 -c "import sys,json; json.loads(sys.stdin.read())" >/dev/null 2>&1; then
    echo "FAIL: JSON report not valid JSON: $json_out"
    failures=$((failures+1))
  fi

  if [[ "$failures" -gt 0 ]]; then
    echo "self-test: FAIL ($failures failures)" >&2
    exit 1
  fi

  echo "self-test: PASS" >&2
  echo "  validate_version + extract_major validated" >&2
  echo "  extract_row_state + extract_milestone_slug validated" >&2
  echo "  check_parser_clean validated (D9 — close-family + #N rejection; negated-form rejection; safe-phrasing acceptance)" >&2
  echo "  chore-PR body builder is parser-clean (D9 self-check)" >&2
  echo "  JSON report renders valid JSON" >&2
  echo "  usage block extractable" >&2
  echo "  corpus paths resolve (RELEASE_LOG/INDEX/DIGEST + notes dir)" >&2
  exit 0
}

# ─── Corpus path-resolution probe (offline; CI smoke gate) ───────────────────
#
# OFFLINE by construction: stats the four corpus paths and exits 0 (all resolve)
# or 1 (any missing/wrong-type). Touches NO git remote and NO gh/network call, so
# the CI smoke job is deterministic and credential-free. This is the hard-fail
# path-resolution check the smoke gate runs to catch re-pathing drift (the
# migration-drift failure mode) BEFORE the next release does.
check_paths() {
  local rc=0
  local label path kind
  # name|path|kind triples (file or dir)
  local checks=(
    "RELEASE_LOG|$RELEASE_LOG|file"
    "RELEASE_INDEX|$RELEASE_INDEX|file"
    "RELEASE_DIGEST|$RELEASE_DIGEST|file"
    "RELEASE_NOTES_DIR|$RELEASE_NOTES_DIR|dir"
  )
  echo "check-paths: resolving corpus paths under $REPO_ROOT" >&2
  local entry
  for entry in "${checks[@]}"; do
    label="${entry%%|*}"
    path="${entry#*|}"; path="${path%|*}"
    kind="${entry##*|}"
    if [[ "$kind" == "dir" ]]; then
      if [[ -d "$path" ]]; then
        echo "  OK   $label -> $path (dir)" >&2
      else
        echo "  FAIL $label -> $path (expected directory, not found)" >&2
        rc=1
      fi
    else
      if [[ -f "$path" ]]; then
        echo "  OK   $label -> $path (file)" >&2
      else
        echo "  FAIL $label -> $path (expected file, not found)" >&2
        rc=1
      fi
    fi
  done
  if [[ "$rc" -eq 0 ]]; then
    echo "check-paths: PASS (all four corpus paths resolve)" >&2
  else
    echo "check-paths: FAIL (one or more corpus paths do not resolve — re-pathing drift?)" >&2
  fi
  exit "$rc"
}

# ─── Argument parsing ────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr) PR_NUMBER="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --milestone) MILESTONE="$2"; shift 2 ;;
    --dry-run) MODE="dry-run"; shift ;;
    --apply) MODE="apply"; shift ;;
    --markdown) OUTPUT="markdown"; shift ;;
    --json) OUTPUT="json"; shift ;;
    --with-pattern-scan) WITH_PATTERN_SCAN=1; shift ;;
    --self-test) SELF_TEST=1; shift ;;
    --check-paths) CHECK_PATHS=1; shift ;;
    --help|-h) usage ;;
    *) die "Unknown flag: $1 (try --help)" ;;
  esac
done

# ─── Main ────────────────────────────────────────────────────────────────────

[[ "$SELF_TEST" -eq 1 ]] && self_test
[[ "$CHECK_PATHS" -eq 1 ]] && check_paths   # offline; exits 0/1 before any gh/network call

[[ -z "$PR_NUMBER" ]] && die "Required: --pr <N>"
[[ -z "$VERSION" ]] && die "Required: --version v<X.Y>"
[[ -z "$MILESTONE" ]] && die "Required: --milestone <N>"
validate_version "$VERSION" || die "Invalid version format: '$VERSION' (expected vX.Y or vX.Y-suffix)"

workspace_boundary_check
RUN_TS="$(ts_now)"

# Run phases sequentially; halt on FAIL from any phase
phase_preflight || { generate_report; exit 2; }
phase_read_state || { generate_report; exit 3; }
phase_detect_open_issues || { generate_report; exit 2; }
phase_create_chore_branch || { generate_report; exit 3; }
phase_transition_release_log || { generate_report; exit 3; }
phase_append_release_index || { generate_report; exit 3; }
phase_append_release_digest || { generate_report; exit 3; }
phase_scaffold_release_notes || { generate_report; exit 3; }
phase_append_changelog || { generate_report; exit 3; }                # Phase 9.5 — Layer-1 dual-write Surface 2
phase_commit_chore_pr || { generate_report; exit 3; }
phase_create_chore_pr || { generate_report; exit 3; }
phase_await_merge_chore_pr || { generate_report; exit 3; }
phase_post_close_milestone || { generate_report; exit 3; }
phase_manual_close_release_issues || { generate_report; exit 3; }
phase_run_verification || { generate_report; exit 3; }
phase_publish_github_release || { generate_report; exit 3; }          # Phase 15.5 — Layer-1 dual-write Surface 1
phase_invoke_orphan_cleanup || { generate_report; exit 3; }
phase_pattern_scan || { generate_report; exit 3; }

generate_report
exit 0
