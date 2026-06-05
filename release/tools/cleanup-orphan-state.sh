#!/usr/bin/env bash
# cleanup-orphan-state.sh — Orphan git state cleanup
# Sweeps merged-no-active-work branches and worktrees per 4 outcomes:
#   1. Release-close terminus    (--release-close <slug>)
#   2. Spawn-task lifecycle      (--spawn-task)
#   3. Historical sweep          (--historical)
#   4. Observability             (always — report at end)
#
# Per the Stage 5 spec (Tier 4.1). D-D LOCKED SCRIPT-ONLY.
#
# Usage:
#   ./pmo-platform/engineering/tools/cleanup-orphan-state.sh                       # safe default: --all --dry-run --markdown
#   ./pmo-platform/engineering/tools/cleanup-orphan-state.sh --release-close v2.07b-stage-execution-and-process-discipline
#   ./pmo-platform/engineering/tools/cleanup-orphan-state.sh --spawn-task --apply
#   ./pmo-platform/engineering/tools/cleanup-orphan-state.sh --historical --apply --json
#   ./pmo-platform/engineering/tools/cleanup-orphan-state.sh --apply --force       # double opt-in for git branch -D / worktree remove --force
#
# Flags:
#   SCOPE (one of, default --all):
#     --release-close <slug>   Outcome 1 only — scope to one release
#     --spawn-task             Outcome 2 only — claude/* orphans
#     --historical             Outcome 3 only — all merged-no-active-work
#     --all                    All 3 outcomes (default)
#   MODE (one of, default --dry-run):
#     --dry-run                Enumerate + report; no mutation (default)
#     --apply                  Execute removals after enumeration (opt-in). The apply
#                              phase runs in order: (1) remove REMOVE-action branches /
#                              worktrees via git porcelain; (2) verify — re-check each
#                              REMOVED target is actually gone, reclassifying any survivor
#                              to "SKIPPED — survived apply" (never silently claim success);
#                              (3) prune — drop stale remote-tracking refs (origin/<branch>)
#                              whose server-side branch was already deleted (e.g. on PR
#                              merge), via `git remote prune`, so the report's remote view
#                              matches reality. Steps 2-3 are no-ops in --dry-run.
#   OUTPUT (one of, default --markdown):
#     --markdown               Human-readable report (default)
#     --json                   Machine-readable
#   SAFETY (additive):
#     --force                  Allow git branch -D + git worktree remove --force; requires --apply
#   META:
#     --help, -h               Usage
#     --self-test              Validate detection logic + apply path + post-apply verify +
#                              stale-ref prune (via isolated throwaway branches + synthetic
#                              survivor candidate, net-zero state); exit 0 on success
#
# Hook compatibility (verified per Stage 5 spec §Evidence-Grounding):
#   - All deletions via git porcelain (broad exemption per Hub Decision 1) —
#     incl. `git remote prune <remote>` (local-tracking-ref reconciliation only;
#     read-only against the server, no server-side ref deletion)
#   - gh api -X DELETE git/refs/heads/* permitted via the egress allowlist
#   - Zero rm/rmdir/unlink usage
#
# Exit codes: 0 = success, 1 = validation failure, 2 = workspace-boundary check failed
#
# Cutover: applies to releases entering Stage 13 strictly AFTER the cutover merge SHA
# (the cutover release itself exempt). Script-side enforcement is operator-mediated via the
# Stage 13 chip prompt — script does not gate by version.

set -euo pipefail

# Pin PATH to system tools per bypass-mode-readiness.md
export PATH="/usr/bin:/bin"

# ─── Repo-relative paths ─────────────────────────────────────────────────────

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

# WORKSPACE_ROOT resolution (env-override → operator.toml → default).
# Operators can override by exporting WORKSPACE_ROOT or CLAUDE_WORKSPACE_ROOT.
# Defense-in-depth boundary at line 87 keys on this value; resolution MUST occur
# before that check, and the value MUST match the actual workspace path where the
# operator runs pmo-platform from.
WORKSPACE_ROOT="${WORKSPACE_ROOT:-${CLAUDE_WORKSPACE_ROOT:-}}"
if [[ -z "$WORKSPACE_ROOT" ]]; then
  _operator_toml="${HOME}/.config/pmo-platform/operator.toml"
  if [[ -r "$_operator_toml" ]]; then
    _wr=$(grep -E '^claude_workspace_root' "$_operator_toml" 2>/dev/null | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
    [[ -n "$_wr" ]] && WORKSPACE_ROOT="$_wr"
  fi
fi
WORKSPACE_ROOT="${WORKSPACE_ROOT:-${HOME}/Claude}"

PROTECT_LIST="$WORKSPACE_ROOT/.claude/cleanup-protect-list.txt"

# Repo slug resolution (env-override → operator.toml → default).
# Operators can override REPO_SLUG to point cleanup at a fork.
REPO_SLUG="${REPO_SLUG:-}"
if [[ -z "$REPO_SLUG" ]] && [[ -r "${HOME}/.config/pmo-platform/operator.toml" ]]; then
  _gh=$(grep -E '^operator_github' "${HOME}/.config/pmo-platform/operator.toml" 2>/dev/null | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
  _repo=$(grep -E '^pmo_platform_repo_name' "${HOME}/.config/pmo-platform/operator.toml" 2>/dev/null | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
  [[ -z "$_repo" ]] && _repo="pmo-platform"
  [[ -n "$_gh" ]] && REPO_SLUG="${_gh}/${_repo}"
fi
[[ -z "$REPO_SLUG" ]] && REPO_SLUG="pmo-platform"

REMOTE_NAME="origin"
MAIN_BRANCH="main"

# ─── Defaults ────────────────────────────────────────────────────────────────

SCOPE="all"               # all | release-close | spawn-task | historical
MILESTONE_SLUG=""
MODE="dry-run"            # dry-run | apply
OUTPUT="markdown"         # markdown | json
FORCE=0
SELF_TEST=0

# Always-protected names (never touched regardless of protect-list state)
PROTECTED_ALWAYS=("$MAIN_BRANCH" "master" "HEAD")

# ─── Helpers ─────────────────────────────────────────────────────────────────

usage() {
  /usr/bin/sed -n '2,38p' "$0" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

die() { echo "ERROR: $*" >&2; exit 1; }

workspace_boundary_check() {
  local cwd
  cwd="$(pwd -P)"
  case "$cwd" in
    "$WORKSPACE_ROOT"*) return 0 ;;
    *) echo "ERROR: invoked from $cwd — outside workspace $WORKSPACE_ROOT (defense-in-depth boundary)" >&2; exit 2 ;;
  esac
}

load_protect_list() {
  PROTECT_PATTERNS=()
  if [[ -f "$PROTECT_LIST" ]]; then
    while IFS= read -r line; do
      [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
      PROTECT_PATTERNS+=("$line")
    done < "$PROTECT_LIST"
  fi
}

is_protected() {
  local branch="$1"
  for p in "${PROTECTED_ALWAYS[@]}"; do [[ "$branch" == "$p" ]] && return 0; done
  for p in "${PROTECT_PATTERNS[@]:-}"; do
    [[ -z "$p" ]] && continue
    case "$branch" in $p) return 0 ;; esac
  done
  return 1
}

# Returns 0 if branch is fully merged into origin/main (no unique commits).
is_fully_merged() {
  local branch="$1"
  local count
  count=$(git rev-list --count "${REMOTE_NAME}/${MAIN_BRANCH}..${branch}" 2>/dev/null) || return 1
  [[ "$count" == "0" ]]
}

# Returns 0 if branch has an associated MERGED PR; 1 otherwise. Empty PR list = 1.
has_merged_pr() {
  local branch="$1"
  local n
  n=$(gh pr list --repo "$REPO_SLUG" --head "$branch" --state merged --json number --jq 'length' 2>/dev/null || echo "0")
  [[ "$n" -ge 1 ]]
}

# Returns 0 if a worktree is currently attached to the branch.
branch_has_worktree() {
  local branch="$1"
  git worktree list --porcelain | grep -q "^branch refs/heads/${branch}$" 2>/dev/null
}

# Returns disk size in MB for a worktree path (rounded).
worktree_size_mb() {
  local path="$1"
  [[ -d "$path" ]] || { echo "0"; return; }
  local kb
  kb=$(du -sk "$path" 2>/dev/null | awk '{print $1}')
  echo $((kb / 1024))
}

worktree_is_clean() {
  local path="$1"
  [[ -d "$path" ]] || return 0
  [[ -z "$(git -C "$path" status --porcelain 2>/dev/null)" ]]
}

# ─── Outcome detection ───────────────────────────────────────────────────────

# Populated by detect_*. Format per record: tab-separated fields.
LOCAL_BRANCH_CANDIDATES=()    # name<TAB>unique_commits<TAB>last_date<TAB>pr_number<TAB>pr_state<TAB>action
REMOTE_BRANCH_CANDIDATES=()   # name<TAB>pr_number<TAB>pr_state<TAB>action
WORKTREE_CANDIDATES=()        # path<TAB>branch<TAB>status<TAB>disk_mb<TAB>action

# Populated by prune_remote_tracking (--apply only): stale remote-tracking refs
# (refs/remotes/<remote>/*) that git pruned because their server-side branch was
# already deleted (the usual case: branch auto-deleted on PR merge). One short-name
# per element (e.g., release/v1.03-foo). The emitter reports these so the report's
# remote view matches reality after server-side merge deletions.
PRUNED_TRACKING_REFS=()

classify_local() {
  local branch="$1" require_pr="${2:-0}"
  local unique last pr_n pr_s action="REMOVE"

  if is_protected "$branch"; then action="SKIP — protected"; fi
  if [[ "$action" == "REMOVE" ]] && branch_has_worktree "$branch"; then action="SKIP — active worktree attached"; fi

  unique=$(git rev-list --count "${REMOTE_NAME}/${MAIN_BRANCH}..${branch}" 2>/dev/null || echo "?")
  if [[ "$action" == "REMOVE" && "$unique" != "0" ]]; then action="SKIP — unique commits exist ($unique)"; fi

  last=$(git log -1 --format='%cs' "$branch" 2>/dev/null || echo "?")
  pr_n=$(gh pr list --repo "$REPO_SLUG" --head "$branch" --state all --json number --jq '.[0].number // ""' 2>/dev/null || echo "")
  pr_s="(none)"
  if [[ -n "$pr_n" ]]; then
    pr_s=$(gh pr view "$pr_n" --repo "$REPO_SLUG" --json state --jq '.state' 2>/dev/null || echo "?")
  fi

  if [[ "$action" == "REMOVE" && "$require_pr" == "1" && "$pr_s" != "MERGED" ]]; then
    action="SKIP — PR not merged ($pr_s)"
  fi

  LOCAL_BRANCH_CANDIDATES+=("${branch}	${unique}	${last}	${pr_n}	${pr_s}	${action}")
}

classify_remote() {
  local branch="$1"
  local pr_n pr_s action="REMOVE"

  if is_protected "$branch"; then action="SKIP — protected"; fi

  pr_n=$(gh pr list --repo "$REPO_SLUG" --head "$branch" --state all --json number --jq '.[0].number // ""' 2>/dev/null || echo "")
  pr_s="(none)"
  if [[ -n "$pr_n" ]]; then
    pr_s=$(gh pr view "$pr_n" --repo "$REPO_SLUG" --json state --jq '.state' 2>/dev/null || echo "?")
  fi
  if [[ "$action" == "REMOVE" && "$pr_s" != "MERGED" ]]; then action="SKIP — PR not merged ($pr_s)"; fi

  REMOTE_BRANCH_CANDIDATES+=("${branch}	${pr_n}	${pr_s}	${action}")
}

classify_worktree() {
  local path="$1" branch="$2"
  local status="clean" disk action="REMOVE"

  worktree_is_clean "$path" || status="dirty"
  disk=$(worktree_size_mb "$path")

  if [[ "$path" == "$WORKSPACE_ROOT" ]]; then action="SKIP — primary checkout"
  elif [[ "$status" == "dirty" ]]; then action="SKIP — uncommitted changes"
  elif [[ -n "$branch" ]] && is_protected "$branch"; then action="SKIP — protected branch"
  elif [[ -n "$branch" ]] && ! is_fully_merged "$branch"; then action="SKIP — branch not fully merged"
  fi

  WORKTREE_CANDIDATES+=("${path}	${branch}	${status}	${disk}	${action}")
}

detect_release_close() {
  local slug="$1"
  [[ -z "$slug" ]] && return 0
  local b
  for b in $(git for-each-ref "refs/heads/release/${slug}*" "refs/heads/chore/${slug}*" --format='%(refname:short)' 2>/dev/null); do
    classify_local "$b" 0
  done
  for b in $(git ls-remote --heads "$REMOTE_NAME" "release/${slug}*" "chore/${slug}*" 2>/dev/null | awk '{print $2}' | sed 's|^refs/heads/||'); do
    classify_remote "$b"
  done
  while IFS= read -r line; do
    [[ "$line" =~ ^worktree[[:space:]](.*)$ ]] || continue
    local wpath="${BASH_REMATCH[1]}" wbranch=""
    local next
    next=$(git worktree list --porcelain | awk -v p="$wpath" 'BEGIN{found=0} /^worktree /{if (found) exit; if ($2==p) found=1; next} found && /^branch /{print $2; exit}')
    wbranch="${next#refs/heads/}"
    [[ -z "$wbranch" || "$wbranch" == "$next" ]] && continue
    case "$wbranch" in
      release/${slug}*|chore/${slug}*) classify_worktree "$wpath" "$wbranch" ;;
    esac
  done < <(git worktree list --porcelain)
}

detect_spawn_task() {
  local b
  for b in $(git for-each-ref 'refs/heads/claude/*' --format='%(refname:short)' 2>/dev/null); do
    classify_local "$b" 0
  done
  for b in $(git ls-remote --heads "$REMOTE_NAME" 'claude/*' 2>/dev/null | awk '{print $2}' | sed 's|^refs/heads/||'); do
    classify_remote "$b"
  done
  while IFS= read -r line; do
    [[ "$line" =~ ^worktree[[:space:]](.*)$ ]] || continue
    local wpath="${BASH_REMATCH[1]}" wbranch=""
    wbranch=$(git worktree list --porcelain | awk -v p="$wpath" 'BEGIN{found=0} /^worktree /{if (found) exit; if ($2==p) found=1; next} found && /^branch /{print $2; exit}')
    wbranch="${wbranch#refs/heads/}"
    case "$wbranch" in claude/*) classify_worktree "$wpath" "$wbranch" ;; esac
  done < <(git worktree list --porcelain)
}

detect_historical() {
  local b
  for b in $(git for-each-ref 'refs/heads/' --format='%(refname:short)' 2>/dev/null); do
    is_protected "$b" && continue
    branch_has_worktree "$b" && continue
    is_fully_merged "$b" || continue
    classify_local "$b" 0
  done
  while IFS= read -r line; do
    [[ "$line" =~ ^worktree[[:space:]](.*)$ ]] || continue
    local wpath="${BASH_REMATCH[1]}" wbranch=""
    [[ "$wpath" == "$WORKSPACE_ROOT" ]] && continue
    wbranch=$(git worktree list --porcelain | awk -v p="$wpath" 'BEGIN{found=0} /^worktree /{if (found) exit; if ($2==p) found=1; next} found && /^branch /{print $2; exit}')
    wbranch="${wbranch#refs/heads/}"
    if [[ -z "$wbranch" ]] || is_fully_merged "$wbranch"; then
      classify_worktree "$wpath" "$wbranch"
    fi
  done < <(git worktree list --porcelain)
}

# ─── Output ──────────────────────────────────────────────────────────────────

emit_markdown() {
  local ts; ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local lc=${#LOCAL_BRANCH_CANDIDATES[@]} rc=${#REMOTE_BRANCH_CANDIDATES[@]} wc=${#WORKTREE_CANDIDATES[@]}
  local pc=${#PRUNED_TRACKING_REFS[@]}
  local lr=0 rr=0 wr=0 disk_total=0 bfails=0 wfails=0 a ref

  # Mode-aware report vocabulary. In --apply, apply_removals (which now runs BEFORE this
  # emitter) has rewritten each acted-on candidate's action field to REMOVED (deleted) or
  # "FAILED — …" (git porcelain refused); in --dry-run the field stays REMOVE. The
  # counters below therefore reflect what ACTUALLY happened, not merely the plan.
  local want="REMOVE" verb="would be removed" noun="removable" recov="recoverable"
  if [[ "$MODE" == "apply" ]]; then want="REMOVED"; verb="removed"; noun="removed"; recov="recovered"; fi

  for r in "${LOCAL_BRANCH_CANDIDATES[@]:-}"; do
    [[ -z "$r" ]] && continue
    a=$(awk -F'\t' '{print $6}' <<<"$r")
    [[ "$a" == "$want" ]] && ((lr++)) || true
    [[ "$a" == FAILED* ]] && ((bfails++)) || true
  done
  for r in "${REMOTE_BRANCH_CANDIDATES[@]:-}"; do
    [[ -z "$r" ]] && continue
    a=$(awk -F'\t' '{print $4}' <<<"$r")
    [[ "$a" == "$want" ]] && ((rr++)) || true
    [[ "$a" == FAILED* ]] && ((bfails++)) || true
  done
  for r in "${WORKTREE_CANDIDATES[@]:-}"; do
    [[ -z "$r" ]] && continue
    local action disk
    action=$(awk -F'\t' '{print $5}' <<<"$r"); disk=$(awk -F'\t' '{print $4}' <<<"$r")
    [[ "$action" == "$want" ]] && { ((wr++)) || true; disk_total=$((disk_total + disk)); }
    [[ "$action" == FAILED* ]] && ((wfails++)) || true
  done

  cat <<EOF
# Orphan-State Cleanup Report — $ts

**Scope:** $SCOPE${MILESTONE_SLUG:+ ($MILESTONE_SLUG)}
**Mode:** $MODE$([[ "$FORCE" == "1" ]] && echo " --force")

## Summary
- **Local branches:** $lc total ($lr $verb)
- **Remote branches:** $rc total ($rr $verb)
- **Stale remote-tracking refs:** $pc $([[ "$MODE" == "apply" ]] && echo "pruned" || echo "stale (run --apply to prune)")
- **Worktrees:** $wc total ($wr $verb, ≈${disk_total} MB disk $recov)

## Detail — Local branches

| Branch | Unique commits vs origin/main | Last commit | PR | PR state | Action |
|---|---|---|---|---|---|
EOF
  for r in "${LOCAL_BRANCH_CANDIDATES[@]:-}"; do
    [[ -z "$r" ]] && continue
    echo "$r" | awk -F'\t' '{printf "| `%s` | %s | %s | %s | %s | %s |\n",$1,$2,$3,$4,$5,$6}'
  done
  echo
  cat <<EOF
## Detail — Remote branches

| Branch | PR | PR state | Action |
|---|---|---|---|
EOF
  for r in "${REMOTE_BRANCH_CANDIDATES[@]:-}"; do
    [[ -z "$r" ]] && continue
    echo "$r" | awk -F'\t' '{printf "| `%s` | %s | %s | %s |\n",$1,$2,$3,$4}'
  done
  echo
  # Stale remote-tracking refs — only populated in --apply (prune_remote_tracking).
  # These are local origin/<branch> entries whose server-side branch was already
  # deleted (typically on PR merge); `git branch -r` listed them until pruned.
  if [[ "$pc" -gt 0 ]]; then
    cat <<EOF
## Detail — Stale remote-tracking refs pruned

| Tracking ref | Action |
|---|---|
EOF
    for ref in "${PRUNED_TRACKING_REFS[@]}"; do
      # shellcheck disable=SC2016  # single-quoted printf FORMAT; $REMOTE_NAME/$ref are args
      printf '| `%s/%s` | PRUNED |\n' "$REMOTE_NAME" "$ref"
    done
    echo
  elif [[ "$MODE" == "dry-run" ]]; then
    echo "## Detail — Stale remote-tracking refs"
    echo
    echo "_Pruned only in \`--apply\`; run \`--apply\` to reconcile stale \`$REMOTE_NAME/*\` tracking refs._"
    echo
  fi
  cat <<EOF
## Detail — Worktrees

| Path | Branch | Status | Disk (MB) | Action |
|---|---|---|---|---|
EOF
  for r in "${WORKTREE_CANDIDATES[@]:-}"; do
    [[ -z "$r" ]] && continue
    echo "$r" | awk -F'\t' '{printf "| `%s` | %s | %s | %s | %s |\n",$1,$2,$3,$4,$5}'
  done
  echo
  echo "## Totals"
  echo "- $((lr + rr)) branches $noun, $((lc + rc - lr - rr - bfails)) skipped, $wr worktrees $noun, ≈${disk_total} MB $recov$([[ "$MODE" == "apply" ]] && echo ", $pc stale tracking ref(s) pruned")"
  if [[ "$MODE" == "apply" && $((bfails + wfails)) -gt 0 ]]; then
    echo "- ⚠ $((bfails + wfails)) removal(s) FAILED — see the PASS/FAIL log on stderr; a git safety guard refused (\`git branch -d\` on an unmerged branch, or \`git worktree remove\` on a dirty tree). Re-run with \`--force\` only if the deletion is intentional."
  fi
  # Plain `if` — NOT `[[ … ]] && echo`. As the function's last statement, a short-circuit
  # test that evaluates false returns non-zero, making emit_markdown return non-zero; under
  # `set -e` that aborted the caller before the apply phase (the v1.02 apply-path no-op
  # defect). An `if` returns 0 when its condition is false. Do not "simplify" this back.
  if [[ "$MODE" == "dry-run" ]]; then
    echo "- Run \`--apply\` to execute"
  fi
}

emit_json() {
  local ts; ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  printf '{"timestamp":"%s","scope":"%s","milestone_slug":"%s","mode":"%s","force":%s,\n' "$ts" "$SCOPE" "$MILESTONE_SLUG" "$MODE" "$FORCE"
  printf '  "local_branches":[\n'
  local first=1
  for r in "${LOCAL_BRANCH_CANDIDATES[@]:-}"; do
    [[ -z "$r" ]] && continue
    [[ $first -eq 0 ]] && printf ',\n'; first=0
    awk -F'\t' '{printf "    {\"name\":\"%s\",\"unique_commits\":\"%s\",\"last_date\":\"%s\",\"pr_number\":\"%s\",\"pr_state\":\"%s\",\"action\":\"%s\"}",$1,$2,$3,$4,$5,$6}' <<<"$r"
  done
  printf '\n  ],\n  "remote_branches":[\n'
  first=1
  for r in "${REMOTE_BRANCH_CANDIDATES[@]:-}"; do
    [[ -z "$r" ]] && continue
    [[ $first -eq 0 ]] && printf ',\n'; first=0
    awk -F'\t' '{printf "    {\"name\":\"%s\",\"pr_number\":\"%s\",\"pr_state\":\"%s\",\"action\":\"%s\"}",$1,$2,$3,$4}' <<<"$r"
  done
  printf '\n  ],\n  "worktrees":[\n'
  first=1
  for r in "${WORKTREE_CANDIDATES[@]:-}"; do
    [[ -z "$r" ]] && continue
    [[ $first -eq 0 ]] && printf ',\n'; first=0
    awk -F'\t' '{printf "    {\"path\":\"%s\",\"branch\":\"%s\",\"status\":\"%s\",\"disk_mb\":\"%s\",\"action\":\"%s\"}",$1,$2,$3,$4,$5}' <<<"$r"
  done
  printf '\n  ],\n  "pruned_tracking_refs":[\n'
  first=1
  for ref in "${PRUNED_TRACKING_REFS[@]:-}"; do
    [[ -z "$ref" ]] && continue
    [[ $first -eq 0 ]] && printf ',\n'; first=0
    # shellcheck disable=SC2016  # single-quoted printf FORMAT; $REMOTE_NAME/$ref are args
    printf '    "%s/%s"' "$REMOTE_NAME" "$ref"
  done
  printf '\n  ]\n}\n'
}

# ─── Apply (mutation) ────────────────────────────────────────────────────────

# Execute REMOVE actions via git porcelain ONLY (git branch -d/-D, gh api DELETE,
# git worktree remove [--force]) — never rm/rmdir/unlink, per core/rules/git-workflow.md
# § PR Process Step 10. Runs BEFORE the emitter and rewrites each acted-on candidate's
# action field IN PLACE: REMOVE → REMOVED on success, REMOVE → "FAILED — …" on refusal;
# SKIP rows are left untouched. The index is tracked with a counter (not "${!arr[@]}")
# to stay safe on bash 3.2 under `set -u` and to match the array idiom used elsewhere.
# Returns 0 unconditionally so the caller (under set -e) proceeds to emit the report.
# Pipeline exit status (git → sed) is git's, not sed's, because `set -o pipefail` is on.
apply_removals() {
  echo "── Apply phase — executing REMOVE actions ──" >&2
  local branch_flag="-d" wt_flag=""
  if [[ "$FORCE" == "1" ]]; then branch_flag="-D"; wt_flag="--force"; fi

  local r name path action idx

  idx=-1
  for r in "${LOCAL_BRANCH_CANDIDATES[@]:-}"; do
    ((idx++)) || true
    [[ -z "$r" ]] && continue
    name=$(awk -F'\t' '{print $1}' <<<"$r"); action=$(awk -F'\t' '{print $6}' <<<"$r")
    [[ "$action" != "REMOVE" ]] && { echo "SKIPPED local $name — $action" >&2; continue; }
    if git branch $branch_flag "$name" 2>&1 | sed 's/^/  git: /' >&2; then
      echo "PASS local $name removed" >&2
      LOCAL_BRANCH_CANDIDATES[$idx]="${r%$'\t'*}"$'\t'"REMOVED"
    else
      echo "FAIL local $name — git branch refused (likely safety guard); use --force if intentional" >&2
      LOCAL_BRANCH_CANDIDATES[$idx]="${r%$'\t'*}"$'\t'"FAILED — git branch refused"
    fi
  done

  idx=-1
  for r in "${REMOTE_BRANCH_CANDIDATES[@]:-}"; do
    ((idx++)) || true
    [[ -z "$r" ]] && continue
    name=$(awk -F'\t' '{print $1}' <<<"$r"); action=$(awk -F'\t' '{print $4}' <<<"$r")
    [[ "$action" != "REMOVE" ]] && { echo "SKIPPED remote $name — $action" >&2; continue; }
    if gh api -X DELETE "repos/${REPO_SLUG}/git/refs/heads/${name}" --silent 2>&1 | sed 's/^/  gh: /' >&2; then
      echo "PASS remote $name removed" >&2
      REMOTE_BRANCH_CANDIDATES[$idx]="${r%$'\t'*}"$'\t'"REMOVED"
    else
      echo "FAIL remote $name — gh api DELETE failed" >&2
      REMOTE_BRANCH_CANDIDATES[$idx]="${r%$'\t'*}"$'\t'"FAILED — gh api DELETE failed"
    fi
  done

  idx=-1
  for r in "${WORKTREE_CANDIDATES[@]:-}"; do
    ((idx++)) || true
    [[ -z "$r" ]] && continue
    path=$(awk -F'\t' '{print $1}' <<<"$r"); action=$(awk -F'\t' '{print $5}' <<<"$r")
    [[ "$action" != "REMOVE" ]] && { echo "SKIPPED worktree $path — $action" >&2; continue; }
    if git worktree remove $wt_flag "$path" 2>&1 | sed 's/^/  git: /' >&2; then
      echo "PASS worktree $path removed" >&2
      WORKTREE_CANDIDATES[$idx]="${r%$'\t'*}"$'\t'"REMOVED"
    else
      echo "FAIL worktree $path — git worktree remove refused (likely uncommitted state); use --force if intentional" >&2
      WORKTREE_CANDIDATES[$idx]="${r%$'\t'*}"$'\t'"FAILED — git worktree remove refused"
    fi
  done

  return 0
}

# ─── Stale remote-tracking prune (--apply only) ──────────────────────────────

# Remove stale remote-tracking refs (refs/remotes/<remote>/*) whose server-side
# branch no longer exists — the common case being a branch auto-deleted on PR
# merge, which leaves a dangling origin/<branch> entry that `git branch -r` keeps
# listing until a separate `git fetch --prune` clears it. classify_remote already
# reports LIVE remote heads via `git ls-remote` (server truth), so the prune does
# NOT change which remote branches are deletion candidates; it only reconciles the
# LOCAL remote-tracking view so the report's remote count matches reality (AC3).
#
# Mechanism: `git remote prune <remote>` — git porcelain, no rm/rmdir/unlink. It is
# read-only against the server (no ref deletion server-side) and only drops local
# tracking refs git already knows are gone. Runs in --apply only (dry-run mutates
# nothing). `--dry-run` of git itself is used first to enumerate what WOULD be
# pruned so the accumulator is populated even when the subsequent prune is a no-op.
prune_remote_tracking() {
  echo "── Prune phase — reconciling stale remote-tracking refs ──" >&2
  PRUNED_TRACKING_REFS=()

  # Enumerate stale tracking refs first (git's own dry-run; non-mutating). Output
  # lines look like " * [would prune] origin/release/v1.03-foo"; capture the
  # short-name after the remote prefix. Tolerate absent remote / offline (|| true).
  local line ref
  while IFS= read -r line; do
    case "$line" in
      *"[would prune]"*|*"[pruned]"*)
        ref="${line##* }"                       # last whitespace-delimited token
        ref="${ref#"${REMOTE_NAME}/"}"          # strip "origin/"
        [[ -n "$ref" ]] && PRUNED_TRACKING_REFS+=("$ref")
        ;;
    esac
  done < <(git remote prune "$REMOTE_NAME" --dry-run 2>/dev/null || true)

  if [[ ${#PRUNED_TRACKING_REFS[@]} -eq 0 ]]; then
    echo "PASS prune — no stale remote-tracking refs (local view already matches remote)" >&2
    return 0
  fi

  # Execute the prune (idempotent; safe if the dry-run list raced to empty).
  if git remote prune "$REMOTE_NAME" 2>&1 | sed 's/^/  git: /' >&2; then
    echo "PASS prune — removed ${#PRUNED_TRACKING_REFS[@]} stale remote-tracking ref(s)" >&2
  else
    echo "FAIL prune — git remote prune refused; stale tracking refs may persist" >&2
  fi
  return 0
}

# ─── Post-apply self-verification ────────────────────────────────────────────

# AC4: never silently claim success. After apply_removals rewrites action fields to
# REMOVED, independently re-check that each REMOVED target is ACTUALLY gone (a branch
# that git reported deleted but that survives — e.g., re-created by a racing worktree,
# or a ref the porcelain only soft-failed — must surface). Survivors are rewritten to
# "SKIPPED — survived apply (still present)" so the emitter's counters and the operator
# both see them, rather than the report asserting a removal that did not hold.
# Runs in --apply only; returns 0 so the emitter still runs under set -e.
verify_apply() {
  local r name path idx survivors=0

  idx=-1
  for r in "${LOCAL_BRANCH_CANDIDATES[@]:-}"; do
    ((idx++)) || true
    [[ -z "$r" ]] && continue
    [[ "$(awk -F'\t' '{print $6}' <<<"$r")" != "REMOVED" ]] && continue
    name=$(awk -F'\t' '{print $1}' <<<"$r")
    if git show-ref --verify --quiet "refs/heads/${name}"; then
      echo "SKIPPED-VERIFY local $name — reported REMOVED but branch still present" >&2
      LOCAL_BRANCH_CANDIDATES[$idx]="${r%$'\t'*}"$'\t'"SKIPPED — survived apply (still present)"
      ((survivors++)) || true
    fi
  done

  idx=-1
  for r in "${WORKTREE_CANDIDATES[@]:-}"; do
    ((idx++)) || true
    [[ -z "$r" ]] && continue
    [[ "$(awk -F'\t' '{print $5}' <<<"$r")" != "REMOVED" ]] && continue
    path=$(awk -F'\t' '{print $1}' <<<"$r")
    if [[ -d "$path" ]]; then
      echo "SKIPPED-VERIFY worktree $path — reported REMOVED but path still present" >&2
      WORKTREE_CANDIDATES[$idx]="${r%$'\t'*}"$'\t'"SKIPPED — survived apply (still present)"
      ((survivors++)) || true
    fi
  done

  if [[ "$survivors" -eq 0 ]]; then
    echo "PASS verify — every REMOVED target confirmed gone (zero survivors)" >&2
  else
    echo "WARN verify — $survivors target(s) reported REMOVED but survived; reclassified SKIPPED" >&2
  fi
  return 0
}

# ─── Self-test ───────────────────────────────────────────────────────────────

# Apply-path regression guard. Reproduces the v1.02 defect class in miniature: an
# isolated, fully-merged throwaway branch is run through the REAL apply path and must
# come back actually DELETED, and the emitters must return 0 in --apply mode (the
# set -e short-circuit that previously aborted the run before apply_removals). The
# throwaway lives under refs/heads/cleanup-selftest/ (matches no release/chore/claude
# detection pattern) and is cleaned up on every exit path — net-zero workspace state.
selftest_apply_path() {
  local base tmp
  base=$(git rev-parse --verify --quiet HEAD 2>/dev/null || true)
  if [[ -z "$base" ]]; then
    echo "self-test: apply-path check SKIPPED — no HEAD commit to branch from" >&2
    return 0
  fi
  tmp="cleanup-selftest/orphan-$$"   # PID-scoped; merged into HEAD so `git branch -d` (non-force) deletes it
  if ! git branch "$tmp" "$base" >/dev/null 2>&1; then
    echo "self-test: apply-path check SKIPPED — could not create throwaway branch '$tmp'" >&2
    return 0
  fi

  # Isolate: act on ONLY the throwaway branch (do NOT sweep real orphans).
  LOCAL_BRANCH_CANDIDATES=("${tmp}"$'\t'"0"$'\t'"selftest"$'\t'""$'\t'"(none)"$'\t'"REMOVE")
  REMOTE_BRANCH_CANDIDATES=()
  WORKTREE_CANDIDATES=()

  local saved_mode="$MODE"
  MODE="apply"
  apply_removals >/dev/null 2>&1 || true          # exercises the real `git branch -d`

  # Guard 1 — emitters must NOT abort under set -e in --apply (the core v1.02 defect).
  if ! emit_markdown >/dev/null 2>&1; then
    git branch -D "$tmp" >/dev/null 2>&1 || true; MODE="$saved_mode"
    echo "self-test: apply-path check FAILED — emit_markdown returned non-zero in --apply (set -e abort regression)" >&2
    exit 1
  fi
  if ! emit_json >/dev/null 2>&1; then
    git branch -D "$tmp" >/dev/null 2>&1 || true; MODE="$saved_mode"
    echo "self-test: apply-path check FAILED — emit_json returned non-zero in --apply" >&2
    exit 1
  fi
  MODE="$saved_mode"

  # Guard 2 — the branch must be ACTUALLY gone, not merely reported removable.
  if git show-ref --verify --quiet "refs/heads/${tmp}"; then
    git branch -D "$tmp" >/dev/null 2>&1 || true
    echo "self-test: apply-path check FAILED — throwaway branch '$tmp' survived --apply (apply path is a no-op)" >&2
    exit 1
  fi

  echo "self-test: apply-path check PASS — throwaway branch deleted and emitters set -e-safe in --apply" >&2
  return 0
}

# AC4 + AC3 regression guard. verify_apply must reclassify a "REMOVED" candidate whose
# branch actually SURVIVED to SKIPPED-with-reason (never silently claim success); and
# prune_remote_tracking must run set -e-safe and return 0 even with no stale refs. Both
# operate on synthetic in-memory candidates / a real isolated branch — net-zero state.
selftest_verify_and_prune() {
  local base tmp saved_mode="$MODE"

  # ── AC4: survivor reclassification ──
  base=$(git rev-parse --verify --quiet HEAD 2>/dev/null || true)
  if [[ -z "$base" ]]; then
    echo "self-test: verify-path check SKIPPED — no HEAD commit to branch from" >&2
  else
    tmp="cleanup-selftest/survivor-$$"
    if ! git branch "$tmp" "$base" >/dev/null 2>&1; then
      echo "self-test: verify-path check SKIPPED — could not create throwaway branch '$tmp'" >&2
    else
      # Seed a candidate the apply phase CLAIMS it removed, but leave the branch in place.
      LOCAL_BRANCH_CANDIDATES=("${tmp}"$'\t'"0"$'\t'"selftest"$'\t'""$'\t'"(none)"$'\t'"REMOVED")
      REMOTE_BRANCH_CANDIDATES=()
      WORKTREE_CANDIDATES=()
      MODE="apply"
      verify_apply >/dev/null 2>&1 || true
      MODE="$saved_mode"
      local action
      action=$(awk -F'\t' '{print $6}' <<<"${LOCAL_BRANCH_CANDIDATES[0]}")
      git branch -D "$tmp" >/dev/null 2>&1 || true   # cleanup regardless of outcome
      case "$action" in
        SKIPPED*survived*)
          echo "self-test: verify-path check PASS — surviving 'REMOVED' branch reclassified SKIPPED" >&2 ;;
        *)
          echo "self-test: verify-path check FAILED — survivor not reclassified (action='$action'); AC4 regression" >&2
          exit 1 ;;
      esac
    fi
  fi

  # ── AC3: prune is set -e-safe and idempotent ──
  PRUNED_TRACKING_REFS=()
  MODE="apply"
  if ! prune_remote_tracking >/dev/null 2>&1; then
    MODE="$saved_mode"
    echo "self-test: prune-path check FAILED — prune_remote_tracking returned non-zero (set -e abort)" >&2
    exit 1
  fi
  MODE="$saved_mode"
  echo "self-test: prune-path check PASS — prune_remote_tracking set -e-safe (${#PRUNED_TRACKING_REFS[@]} stale ref(s) enumerated)" >&2

  # Reset accumulators the seeded checks dirtied, so a caller can reuse them cleanly.
  LOCAL_BRANCH_CANDIDATES=(); REMOTE_BRANCH_CANDIDATES=(); WORKTREE_CANDIDATES=(); PRUNED_TRACKING_REFS=()
  return 0
}

self_test() {
  echo "self-test: running detection logic against current workspace (read-only)..." >&2
  workspace_boundary_check
  load_protect_list
  detect_spawn_task
  echo "self-test: detection completed — ${#LOCAL_BRANCH_CANDIDATES[@]} local / ${#REMOTE_BRANCH_CANDIDATES[@]} remote / ${#WORKTREE_CANDIDATES[@]} worktree candidates" >&2
  echo "self-test: exercising apply path against an isolated throwaway branch..." >&2
  selftest_apply_path
  echo "self-test: exercising post-apply verify + stale-ref prune paths..." >&2
  selftest_verify_and_prune
  echo "self-test: PASS" >&2
  exit 0
}

# ─── Arg parsing ─────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release-close) SCOPE="release-close"; MILESTONE_SLUG="${2:-}"; shift 2 ;;
    --spawn-task)    SCOPE="spawn-task"; shift ;;
    --historical)    SCOPE="historical"; shift ;;
    --all)           SCOPE="all"; shift ;;
    --dry-run)       MODE="dry-run"; shift ;;
    --apply)         MODE="apply"; shift ;;
    --markdown)      OUTPUT="markdown"; shift ;;
    --json)          OUTPUT="json"; shift ;;
    --force)         FORCE=1; shift ;;
    --self-test)     SELF_TEST=1; shift ;;
    --help|-h)       usage ;;
    *) die "unknown flag: $1 (try --help)" ;;
  esac
done

[[ "$FORCE" == "1" && "$MODE" != "apply" ]] && die "--force requires --apply (double opt-in)"
[[ "$SCOPE" == "release-close" && -z "$MILESTONE_SLUG" ]] && die "--release-close requires a milestone slug"

# ─── Main ────────────────────────────────────────────────────────────────────

workspace_boundary_check
[[ "$SELF_TEST" == "1" ]] && self_test
load_protect_list

case "$SCOPE" in
  all)
    detect_spawn_task
    detect_historical
    ;;
  release-close) detect_release_close "$MILESTONE_SLUG" ;;
  spawn-task)    detect_spawn_task ;;
  historical)    detect_historical ;;
esac

# Apply BEFORE emitting: apply_removals rewrites candidate action fields to REMOVED /
# FAILED so the emitted report reflects ACTUAL execution, not just the planned action.
# verify_apply re-checks REMOVED targets and reclassifies any survivor to SKIPPED (AC4);
# prune_remote_tracking reconciles the local remote-tracking view (AC3). All three run in
# --apply only and return 0 so emit still runs after them under set -e. Plain `if` (not
# `[[ … ]] && …`) keeps control flow obvious and immune to set -e short-circuit semantics.
if [[ "$MODE" == "apply" ]]; then
  apply_removals
  verify_apply
  prune_remote_tracking
fi

case "$OUTPUT" in
  markdown) emit_markdown ;;
  json)     emit_json ;;
esac

exit 0
