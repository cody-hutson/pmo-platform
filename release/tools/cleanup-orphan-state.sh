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
#   ./release/tools/cleanup-orphan-state.sh                       # safe default: --all --dry-run --markdown
#   ./release/tools/cleanup-orphan-state.sh --release-close v2.07b-stage-execution-and-process-discipline
#   ./release/tools/cleanup-orphan-state.sh --spawn-task --apply
#   ./release/tools/cleanup-orphan-state.sh --historical --apply --json
#   ./release/tools/cleanup-orphan-state.sh --apply --force       # double opt-in for git branch -D / worktree remove --force
#
# Flags:
#   SCOPE (one of, default --all):
#     --release-close <slug>   Outcome 1 only — scope to one release
#                              (matches release/<slug>, release/vX.Y-<slug>, the
#                               sibling chore/<slug>-* / chore/vX.Y-<slug>-* branches,
#                               and — when the slug carries a leading vX.Y version —
#                               the Stage 12/13 chore/vX.Y-stage-* branches, anchored
#                               on the literal -stage- so vX.Y never over-matches vX.YY)
#     --spawn-task             Outcome 2 only — claude/* and agent-* orphans
#     --historical             Outcome 3 only — all merged-no-active-work
#     --all                    All 3 outcomes (default)
#     --reap-orphan-tags       Outcome 4 (re-version recovery) — settle the orphaned git
#                              tag of an ABANDONED version. SEPARATE opt-in scope: it is
#                              NOT run by --all / --release-close (any deletion needs
#                              ledger authority + double opt-in). Reads the re-version
#                              ledger (RELEASE_REVERSIONS.md) for rows with disposition=
#                              tag-orphaned, then classifies each against HOST TAG POLICY:
#                                protected    → RETAINED; row → tag-retained; NO push is
#                                               issued and --force is not required. This
#                                               is the branch that fires wherever a tag
#                                               ruleset with a deletion rule is active —
#                                               per core/rules/git-workflow.md
#                                               § Tag Retention, a version tag is kept.
#                                unprotected  → the pre-existing reap path (non-force
#                                               git push --delete + git tag -d, behind
#                                               --apply --force), writing the row back
#                                               (disposition→tag-reaped, reaped_ref).
#                                undetermined → nothing attempted, no row transitioned;
#                                               the reason is named. Host policy could
#                                               not be READ, and indeterminacy fails
#                                               CLOSED (see tag_protection_state()).
#                              Also reports stale-version corpus rows needing the
#                              runbook's R-3 roll-forward (report-only — never edits
#                              corpus prose). See
#                              release/references/how-to/re-version-recovery.md.
#         --abandoned <tag>    Pre-ledger explicit authority — consider THIS tag (the only
#                              path that does not require a ledger row). Never inferred.
#         --assume-unprotected Operator assertion that this deployment's host carries no
#                              tag protection. Skips the host query and takes the
#                              unprotected branch. Use only when host policy is genuinely
#                              unreadable AND you know the host does not protect tags;
#                              it asserts host state, it does not override a host that
#                              does protect (the push is still rejected server-side).
#         --ledger <path>      Point at a re-version ledger other than the default
#                              (release/releases/RELEASE_REVERSIONS.md).
#   MODE (one of, default --dry-run):
#     --dry-run                Enumerate + report; no mutation (default)
#     --apply                  Execute removals after enumeration (opt-in). The apply
#                              phase runs in order: (1) remove REMOVE-action branches /
#                              worktrees via git porcelain; (2) resolve — one bounded
#                              re-evaluation pass removing local branches freed by this
#                              run's worktree removals (fixed point in a single
#                              invocation); (3) verify — re-check each REMOVED target
#                              (incl. resolve-pass removals) is actually gone,
#                              reclassifying any survivor to "SKIPPED — survived apply"
#                              (never silently claim success); (4) prune — drop stale
#                              remote-tracking refs (origin/<branch>) whose server-side
#                              branch was already deleted (e.g. on PR merge), via
#                              `git remote prune`, so the report's remote view matches
#                              reality. Steps 2-4 are no-ops in --dry-run.
#   OUTPUT (one of, default --markdown):
#     --markdown               Human-readable report (default)
#     --json                   Machine-readable
#   SAFETY (additive):
#     --force                  Allow git branch -D + git worktree remove --force; requires --apply
#     SELF — the script's own runtime worktree is never removed (a new SELF action
#     class; --force does not override)
#     LIVE — worktrees held by a live process are skipped ("SKIP — live session
#     (pid …)"; re-checked at apply time); fail-closed when lsof is unavailable;
#     --force does not override
#   META:
#     --help, -h               Usage
#     --self-test              Validate detection logic + apply path + post-apply verify +
#                              stale-ref prune + SELF-guard, liveness, fixed-point, and
#                              orphan-tag-reap fixtures (via isolated throwaway branches /
#                              a PID-scoped FIXTURE bare remote / a throwaway ledger +
#                              synthetic survivor candidate + synthetic live holder,
#                              net-zero state; the reap NEVER touches the real origin);
#                              exit 0 on success
#
# Hook compatibility (verified per Stage 5 spec §Evidence-Grounding):
#   - All deletions via git porcelain (broad exemption per Hub Decision 1) —
#     incl. `git remote prune <remote>` (local-tracking-ref reconciliation only;
#     read-only against the server, no server-side ref deletion) and, for the
#     re-version-recovery reap, `git push --delete <remote> <tag>` + `git tag -d <tag>`
#     (NON-FORCE — a forward removal of a ref, NOT a history rewrite; confirmed not in
#     the destructive-action hook's blocked set, which blocks only force-push forms:
#     `grep -nE 'push.*(-d|--delete)|tag[[:space:]]+-d' core/hooks/block-destructive.sh`
#     returns 0 across all rules, and the settings.json deny array carries no tag/delete
#     entry — only `git push --force`/`-f`)
#   - gh api -X DELETE git/refs/heads/* permitted via the egress allowlist
#   - lsof is read-only inspection, invoked by absolute path (PATH pin intact)
#   - Zero rm/rmdir/unlink in the PRODUCTION mutation path (the ledger write-back uses an
#     awk-into-variable here-string rewrite, no temp file). The --self-test path uses a
#     bounded, PID-scoped `/bin/rm` to tear down its own fixture remote/ledger in a
#     `<tmpdir>/cleanup-selftest-<pid>` dir (mirrors deploy.sh's guarded bounded-rm
#     precedent) — never a workspace, repo, or origin path.
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
# Physically-resolved twin of REPO_ROOT, consumed ONLY by workspace_boundary_check.
# The guard compares against `pwd -P`, so a LOGICAL root silently fails to match
# behind a symlinked checkout — the macOS /tmp → /private/tmp case this file's own
# physical_path() documents, and which physical_path() itself cannot serve here
# because it is defined further down. REPO_ROOT is left byte-identical so every
# existing $REPO_ROOT consumer is untouched.
REPO_ROOT_PHYS="$( cd "$SCRIPT_DIR/../.." && pwd -P )"

# WORKSPACE_ROOT resolution (env-override → operator.toml → default).
# Operators can override by exporting WORKSPACE_ROOT or CLAUDE_WORKSPACE_ROOT.
# Defense-in-depth boundary at line 87 keys on this value; resolution MUST occur
# before that check, and the value MUST match the actual workspace path where the
# operator runs pmo-platform from.
WORKSPACE_ROOT="${WORKSPACE_ROOT:-${CLAUDE_WORKSPACE_ROOT:-}}"
if [[ -z "$WORKSPACE_ROOT" ]]; then
  _operator_toml="${HOME}/.config/pmo-platform/operator.toml"
  if [[ -r "$_operator_toml" ]]; then
    _wr=$(grep -m1 -E '^claude_workspace_root' "$_operator_toml" 2>/dev/null | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
    [[ -n "$_wr" ]] && WORKSPACE_ROOT="$_wr"
  fi
fi
WORKSPACE_ROOT="${WORKSPACE_ROOT:-${HOME}/Claude}"

PROTECT_LIST="$WORKSPACE_ROOT/.claude/cleanup-protect-list.txt"

# Repo slug resolution (env-override → operator.toml → default).
# Operators can override REPO_SLUG to point cleanup at a fork.
REPO_SLUG="${REPO_SLUG:-}"
if [[ -z "$REPO_SLUG" ]] && [[ -r "${HOME}/.config/pmo-platform/operator.toml" ]]; then
  _gh=$(grep -m1 -E '^operator_github' "${HOME}/.config/pmo-platform/operator.toml" 2>/dev/null | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
  _repo=$(grep -m1 -E '^pmo_platform_repo_name' "${HOME}/.config/pmo-platform/operator.toml" 2>/dev/null | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
  [[ -z "$_repo" ]] && _repo="pmo-platform"
  [[ -n "$_gh" ]] && REPO_SLUG="${_gh}/${_repo}"
fi
[[ -z "$REPO_SLUG" ]] && REPO_SLUG="pmo-platform"

REMOTE_NAME="origin"
MAIN_BRANCH="main"

# ─── Defaults ────────────────────────────────────────────────────────────────

SCOPE="all"               # all | release-close | spawn-task | historical | reap-orphan-tags
MILESTONE_SLUG=""
MODE="dry-run"            # dry-run | apply
OUTPUT="markdown"         # markdown | json
FORCE=0
SELF_TEST=0

# Re-version recovery (--reap-orphan-tags scope). The tool consumes the
# machine-readable re-version ledger to learn which abandoned-version tags an
# AUTHORITY has declared orphaned, classifies each against host tag policy, and writes
# the outcome back. Abandonment is NEVER inferred — only the ledger's
# `disposition = tag-orphaned` rows or an explicit --abandoned <tag> put a tag in
# scope. Field names + the disposition enum are the ledger's frozen schema
# (RELEASE_REVERSIONS.md): the tool READS disposition / abandoned_version /
# abandoned_tag_pushed / merge_sha and WRITES the two mutable cells disposition
# (→ tag-retained where the host protects the tag, → tag-reaped where it does not) and
# reaped_ref, keyed on (slug, abandoned_version), header-resolved.
LEDGER_PATH="${REVERSION_LEDGER:-$REPO_ROOT/release/releases/RELEASE_REVERSIONS.md}"
ABANDONED_ARG=""          # explicit pre-ledger authority (one tag); never inferred
ASSUME_UNPROTECTED=0      # operator assertion of host state; see tag_protection_state()
RELEASE_LOG_PATH="$REPO_ROOT/release/releases/RELEASE_LOG.md"

# Always-protected names (never touched regardless of protect-list state)
PROTECTED_ALWAYS=("$MAIN_BRANCH" "master" "HEAD")

# ─── Helpers ─────────────────────────────────────────────────────────────────

usage() {
  # End-anchored header extraction (#669): print the header comment block from
  # line 2 up to (but not including) the `# Hook compatibility` divider, instead
  # of a fixed line-range. A fixed window (formerly `2,74p`) silently drops the
  # SAFETY (--force / SELF / LIVE) and META (--help / --self-test) lines the
  # moment the header grows past the hard-coded offset — a real regression this
  # tool already suffered (#1678 widened 42→74). Anchoring on the structural
  # divider means header growth can never push the protective-guarantee lines
  # outside --help. Fallback: if the divider is ever renamed/removed, print
  # through the last leading-`#` line so --help still renders the whole header.
  /usr/bin/awk '
    NR==1 { next }                    # skip the shebang
    /^# Hook compatibility/ { exit }  # stop at the structural divider
    /^#/ { print }                    # header comment line (block is contiguous #-lines)
  ' "$0" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

die() { echo "ERROR: $*" >&2; exit 1; }

# Defense-in-depth boundary. Accepts a UNION of two roots:
#   (1) $WORKSPACE_ROOT   — the operator workspace, resolved by the cascade above;
#   (2) $REPO_ROOT_PHYS   — the script's own physical checkout, so the tool stays
#                           reachable on a CI runner or any clone where
#                           WORKSPACE_ROOT resolves somewhere else entirely.
# Arm (2) is ADDITIVE: nothing accepted before it existed can now be rejected, so
# the Stage-13 automated-closeout invocation and every operator path are unaffected
# by construction. It admits no unrelated clone either — REPO_ROOT_PHYS derives from
# $0, not from the environment.
# Matching is SEPARATOR-ANCHORED. The former bare `"$ROOT"*` prefix also matched a
# SIBLING directory whose name merely extends the root (…/Claude-scratch passed for
# root …/Claude); a second arm would have doubled that surface, so both arms match
# the root exactly or the root followed by "/".
# See release/ADRs/ADR-142 for why the guard is widened rather than exempted.
workspace_boundary_check() {
  local cwd
  cwd="$(pwd -P)"
  case "$cwd" in
    "$WORKSPACE_ROOT"|"$WORKSPACE_ROOT"/*) return 0 ;;
    "$REPO_ROOT_PHYS"|"$REPO_ROOT_PHYS"/*) return 0 ;;
    *) echo "ERROR: invoked from $cwd — outside workspace $WORKSPACE_ROOT and outside checkout $REPO_ROOT_PHYS (defense-in-depth boundary)" >&2; exit 2 ;;
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
  ensure_gh_bin
  [[ -z "$GH_BIN" ]] && return 1   # no gh → cannot confirm a merged PR (fail-closed)
  n=$("$GH_BIN" pr list --repo "$REPO_SLUG" --head "$branch" --state merged --json number --jq 'length' 2>/dev/null || echo "0")
  [[ "$n" -ge 1 ]]
}

# ─── PR-state prefetch map (#655) ────────────────────────────────────────────
#
# Replaces the per-branch `gh pr list --head` + `gh pr view` pair in
# classify_local()/classify_remote() with a SINGLE run-scoped prefetch — an O(1)
# `gh pr list --state all` — so an --all/--historical sweep over ~100 branches
# issues one list call instead of ~200 serial gh calls. The map is a bash-3.2 tab-
# string array + linear-scan accessor, cloning the LIVE_CWD_ENTRIES[]/worktree_is_live
# idiom verbatim (NO `declare -A`, per the associative-array constraint at L309).
#
# Design (per the Stage 5 design, #2781):
#  - Lazy + memoized (ensure_pr_map / PR_MAP_BUILT): a scope that classifies zero
#    branches pays zero — mirrors ensure_liveness_map().
#  - FAIL-CLOSED: PR_MAP_STATE defaults to `degraded`; build promotes to `ok` ONLY
#    after a truncation guard confirms the map is complete (returned == probed AND
#    the probe did not hit the ceiling, per git-workflow.md § Batch CLI Query Limits).
#    Any gh failure / truncation leaves it `degraded` → pr_lookup runs the VERBATIM
#    current per-branch calls (offline tolerance identical to the pre-#655 path).
#  - Map-miss = "no PR" (never re-query): a COMPLETE map makes misses trustworthy;
#    per-miss fallback was rejected (it reintroduces the pagination-misclassification
#    risk the guard exists to prevent).
#  - Identity linchpin: `gh pr list` is NEWEST-first; the per-branch path takes
#    `.[0]` (newest); the map keeps FIRST-SEEN per head (= newest) → byte-identical
#    pr_n/pr_s. (The pr_s="?" transient-error state is eliminated in map mode — a
#    strict improvement.)
PR_MAP_ENTRIES=()          # "headRefName<TAB>number<TAB>state" strings; first-seen (newest) per head wins
PR_MAP_BUILT=0             # lazy-memo marker
PR_MAP_STATE="degraded"    # degraded | ok — FAIL-CLOSED default (host evidence only via build)
PR_MAP_CEILING=5000        # safe ceiling for this repo per git-workflow.md § Batch CLI Query Limits
PR_LOOKUP_N=""             # out: pr_number for the last pr_lookup ("" = none)
PR_LOOKUP_S="(none)"       # out: pr_state for the last pr_lookup ("(none)" = no PR)

build_pr_map() {
  PR_MAP_ENTRIES=(); PR_MAP_STATE="degraded"; PR_MAP_BUILT=1
  local raw probed returned=0 line head seen
  ensure_gh_bin
  if [[ -z "$GH_BIN" ]]; then
    echo "WARN pr-map prefetch unavailable — gh not resolvable under the pinned PATH; per-branch PR classification (offline-tolerant)" >&2
    return 0
  fi
  # Probe the true dataset size independently, then fetch at the same ceiling. If
  # the probe fails, stay degraded (per-branch fallback). Both queries share the
  # ceiling: probed < ceiling proves no truncation; returned == probed cross-checks
  # the parse. gh emits newest-first; first-seen per head is therefore the newest PR.
  probed=$("$GH_BIN" pr list --repo "$REPO_SLUG" --state all --limit "$PR_MAP_CEILING" --json number --jq 'length' 2>/dev/null || echo "")
  if [[ -z "$probed" || ! "$probed" =~ ^[0-9]+$ ]]; then
    echo "WARN pr-map prefetch unavailable — count probe failed; per-branch PR classification (offline-tolerant)" >&2
    return 0
  fi
  raw=$("$GH_BIN" pr list --repo "$REPO_SLUG" --state all --limit "$PR_MAP_CEILING" --json headRefName,number,state --jq '.[] | [.headRefName, (.number|tostring), .state] | @tsv' 2>/dev/null || true)
  if [[ -n "$raw" ]]; then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      head="${line%%	*}"
      # First-seen (newest) per head wins — skip a later (older) row for the same head.
      seen=0
      local e
      for e in "${PR_MAP_ENTRIES[@]:-}"; do
        [[ -z "$e" ]] && continue
        if [[ "${e%%	*}" == "$head" ]]; then seen=1; break; fi
      done
      [[ "$seen" -eq 1 ]] && continue
      PR_MAP_ENTRIES+=("$line")
      ((returned++)) || true
    done <<<"$raw"
  fi
  # Truncation guard: the map is trustworthy ONLY if the probe did not hit the
  # ceiling AND every probed PR is represented. Distinct heads collapse duplicates,
  # so the parse cross-check counts TOTAL rows read, not distinct heads.
  local total_rows
  total_rows=$(awk 'END{print NR}' <<<"$raw" 2>/dev/null || echo 0)
  [[ -z "$raw" ]] && total_rows=0
  if [[ "$probed" -lt "$PR_MAP_CEILING" && "$total_rows" -eq "$probed" ]]; then
    PR_MAP_STATE="ok"
    echo "PASS pr-map prefetch — ${#PR_MAP_ENTRIES[@]} head(s) mapped from ${probed} PR(s) in one gh list" >&2
  else
    echo "WARN pr-map prefetch degraded — probe=${probed} rows=${total_rows} ceiling=${PR_MAP_CEILING} (truncation-suspect); per-branch fallback" >&2
  fi
  return 0
}

ensure_pr_map() {
  if [[ "$PR_MAP_BUILT" -eq 0 ]]; then
    build_pr_map
  fi
  return 0
}

# pr_lookup <branch> — sets PR_LOOKUP_N / PR_LOOKUP_S. In `ok` map mode: linear scan,
# map-miss = "no PR". In `degraded` mode: the VERBATIM pre-#655 per-branch calls.
pr_lookup() {
  local branch="$1" e head
  PR_LOOKUP_N=""; PR_LOOKUP_S="(none)"
  if [[ "$PR_MAP_STATE" == "ok" ]]; then
    for e in "${PR_MAP_ENTRIES[@]:-}"; do
      [[ -z "$e" ]] && continue
      head="${e%%	*}"
      if [[ "$head" == "$branch" ]]; then
        local rest="${e#*	}"
        PR_LOOKUP_N="${rest%%	*}"
        PR_LOOKUP_S="${rest#*	}"
        return 0
      fi
    done
    return 0   # map-miss = no PR (complete map → trustworthy)
  fi
  # Degraded: identical to the pre-#655 per-branch path (offline tolerance).
  ensure_gh_bin
  [[ -z "$GH_BIN" ]] && return 0   # no gh → leave PR_LOOKUP_N="" / PR_LOOKUP_S="(none)"
  PR_LOOKUP_N=$("$GH_BIN" pr list --repo "$REPO_SLUG" --head "$branch" --state all --json number --jq '.[0].number // ""' 2>/dev/null || echo "")
  if [[ -n "$PR_LOOKUP_N" ]]; then
    PR_LOOKUP_S=$("$GH_BIN" pr view "$PR_LOOKUP_N" --repo "$REPO_SLUG" --json state --jq '.state' 2>/dev/null || echo "?")
  fi
  return 0
}

# One-shot snapshot of the porcelain worktree list, reused by every worktree
# reader below through here-strings. It replaces per-call live pipes that
# SIGPIPE the generator when a consumer (grep -q, or awk that calls exit) closes
# the read end while git is still writing — fatal under set -o pipefail once the
# list is non-trivially long (the exit-141-at-scale defect). Refreshed at the
# top of each detect_* pass; built on demand for any earlier reader. [WTPIPEGUARD]
WT_SNAPSHOT=""
WT_SNAPSHOT_BUILT=0
refresh_wt_snapshot() {
  WT_SNAPSHOT="$(git worktree list --porcelain 2>/dev/null || true)"
  WT_SNAPSHOT_BUILT=1
}

# Branch ref (refs/heads/…) attached to a worktree path, parsed from WT_SNAPSHOT.
# Empty for a detached or absent worktree. Here-string input — no live pipe that
# an early awk-exit could SIGPIPE. [WTPIPEGUARD]
branch_for_worktree() {
  local wpath="$1"
  [[ "$WT_SNAPSHOT_BUILT" == "1" ]] || refresh_wt_snapshot
  awk -v p="$wpath" 'BEGIN{found=0} /^worktree /{if (found) exit; if ($2==p) found=1; next} found && /^branch /{print $2; exit}' <<<"$WT_SNAPSHOT"
}

# Returns 0 if a worktree is currently attached to the branch. Always LIVE — the
# resolve pass re-checks this against post-removal state, so it must reflect
# current reality, not the enumeration snapshot. The here-string is fed by a
# completed command substitution (git finishes before grep reads), so there is
# no live pipe for an early grep-q to SIGPIPE, even at scale. [WTPIPEGUARD]
branch_has_worktree() {
  local branch="$1"
  grep -q "^branch refs/heads/${branch}$" <<<"$(git worktree list --porcelain 2>/dev/null)"
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

# ─── Self-worktree + path normalization (#333) ──────────────────────────────

# Physical-path normalization: resolves symlink components (macOS /tmp →
# /private/tmp; $TMPDIR under /private/var) by cd-ing in a subshell. Falls back
# to the input string when the path does not exist — the safe direction for
# both consumers (a nonexistent path can be neither SELF nor live-held).
physical_path() {
  (cd -- "$1" 2>/dev/null && pwd -P) || printf '%s\n' "$1"
}

# SCRIPT_WORKTREE: physical toplevel of the worktree containing the script's
# runtime cwd. EMPTY when (a) cwd is not inside a git worktree, or (b) cwd is
# the PRIMARY checkout — #333 AC4: from the primary, the SELF logic is a
# structural no-op. MAIN_WORKTREE: physical path of the repo's main worktree
# (first `git worktree list --porcelain` entry — upstream git lists it first).
SCRIPT_WORKTREE=""
MAIN_WORKTREE=""

compute_self_worktree() {
  local top main snap
  top="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
  # Snapshot then here-string (not a live pipe): the primary is the first entry,
  # so this awk never needs an early exit, but keeping the no-live-pipe idiom
  # uniform means a later "add exit for speed" edit cannot reintroduce the
  # SIGPIPE-at-scale defect here either. [WTPIPEGUARD]
  snap="$(git worktree list --porcelain 2>/dev/null || true)"
  main="$(awk 'NR==1 && /^worktree /{sub(/^worktree /,""); print}' <<<"$snap" || true)"
  if [[ -n "$main" ]]; then MAIN_WORKTREE="$(physical_path "$main")"; fi
  if [[ -n "$top" ]]; then
    top="$(physical_path "$top")"
    if [[ -n "$MAIN_WORKTREE" && "$top" == "$MAIN_WORKTREE" ]]; then
      SCRIPT_WORKTREE=""   # primary: SELF never fires (#333 AC4)
    else
      SCRIPT_WORKTREE="$top"
    fi
  fi
}

# ─── Liveness oracle (#326, ADR-021) ────────────────────────────────────────

# One-shot all-process cwd snapshot via lsof (absolute path — the pinned PATH
# /usr/bin:/bin cannot see /usr/sbin where macOS keeps lsof). Entries are
# "pid<TAB>command<TAB>cwd" strings (bash-3.2-safe; no associative arrays).
# ORACLE_STATE: ok | unavailable. FAIL-CLOSED: consumers in classify_worktree
# convert any residual REMOVE to a conservative SKIP when not ok. Self-canary:
# a scan that cannot see this script's own cwd is malfunctioning → unavailable.
# ORACLE_BUILT distinguishes never-consulted (lazy memo never fired — e.g. a
# scope that classifies zero worktrees) from consulted-and-degraded: the
# "unavailable" initializer is a fail-closed default, not host evidence, so
# the report emitters claim UNAVAILABLE only when ORACLE_BUILT=1 (DT F-01).
LSOF_BIN=""
LIVE_CWD_ENTRIES=()
ORACLE_STATE="unavailable"
ORACLE_BUILT=0
LIVE_HIT=""   # "pid <pid>, <command>" of the most recent worktree_is_live match

# GitHub CLI resolved by ABSOLUTE path (#2790) — the pinned PATH /usr/bin:/bin
# cannot see /opt/homebrew/bin or /usr/local/bin where Homebrew keeps gh, so a
# bare `gh` fails command-not-found (exit 127) and the PR-state layer silently
# resolves to (none). Mirrors LSOF_BIN/resolve_lsof_bin. FAIL-CLOSED: when no gh
# binary exists GH_BIN stays "" and every call site degrades to its offline path
# ((none) PR state / skipped remote delete), preserving offline tolerance.
GH_BIN=""
GH_BIN_RESOLVED=0   # lazy-memo marker: ensure_gh_bin resolves + WARNs once

resolve_lsof_bin() {
  LSOF_BIN=""
  local c
  for c in /usr/sbin/lsof /usr/bin/lsof; do
    if [[ -x "$c" ]]; then LSOF_BIN="$c"; break; fi
  done
}

# gh resolver — mirror of resolve_lsof_bin for the pinned-PATH gap (#2790).
# Scans the two Homebrew prefixes (Apple-silicon, Intel) then the system path.
resolve_gh_bin() {
  GH_BIN=""
  local c
  for c in /opt/homebrew/bin/gh /usr/local/bin/gh /usr/bin/gh; do
    if [[ -x "$c" ]]; then GH_BIN="$c"; break; fi
  done
}

# Lazy guard: resolve GH_BIN once, WARN once on miss. Every gh call site calls
# this first, then degrades (see call sites) when GH_BIN stays "". Mirrors the
# ensure_liveness_map / ensure_pr_map memo idiom. Returns 0 always (offline-safe).
ensure_gh_bin() {
  if [[ "$GH_BIN_RESOLVED" -eq 0 ]]; then
    GH_BIN_RESOLVED=1
    resolve_gh_bin
    if [[ -z "$GH_BIN" ]]; then
      echo "WARN gh unavailable — not found at /opt/homebrew/bin/gh, /usr/local/bin/gh, or /usr/bin/gh under the pinned PATH; PR-state features degrade to (none) (offline-tolerant)" >&2
    fi
  fi
  return 0
}

build_liveness_map() {
  LIVE_CWD_ENTRIES=(); ORACLE_STATE="unavailable"
  ORACLE_BUILT=1   # consultation marker — set by the builder itself so the
                   # A-Recheck direct call also counts as a consultation
  resolve_lsof_bin
  if [[ -z "$LSOF_BIN" ]]; then
    echo "WARN liveness oracle unavailable — lsof not found at /usr/sbin/lsof or /usr/bin/lsof; fail-closed (would-be-REMOVE worktrees will be conservatively SKIPPED)" >&2
    return 0
  fi
  local line pid="" cmd=""
  while IFS= read -r line; do
    case "$line" in
      p*) pid="${line#p}" ;;
      c*) cmd="${line#c}" ;;
      n*) if [[ -n "$pid" ]]; then LIVE_CWD_ENTRIES+=("${pid}	${cmd}	${line#n}"); fi ;;
    esac
  done < <("$LSOF_BIN" -a -d cwd -Fcn 2>/dev/null || true)
  # Self-canary: this bash process holds its own cwd — it MUST be in the map.
  # Necessary-not-sufficient: it witnesses that the scan RAN and parsed, not
  # that the enumeration is complete (ADR-021 Consequences).
  local own e rest cwd found=0
  own="$(pwd -P)"
  for e in "${LIVE_CWD_ENTRIES[@]:-}"; do
    [[ -z "$e" ]] && continue
    rest="${e#*	}"; cwd="${rest#*	}"
    if [[ "$cwd" == "$own" ]]; then found=1; break; fi
  done
  if [[ "$found" -eq 1 ]]; then
    ORACLE_STATE="ok"
    echo "PASS liveness oracle — ${#LIVE_CWD_ENTRIES[@]} live cwd(s) mapped via $LSOF_BIN" >&2
  else
    echo "WARN liveness oracle unavailable — scan missing the script's own cwd (self-canary); fail-closed" >&2
  fi
  return 0
}

ensure_liveness_map() {
  if [[ "$ORACLE_BUILT" -eq 0 ]]; then
    build_liveness_map
  fi
  return 0
}

# Returns 0 when a live process has its cwd at or under the candidate path;
# sets LIVE_HIT to "pid <pid>, <command>" for the report label.
worktree_is_live() {
  local cand e pid rest cmd cwd
  cand="$(physical_path "$1")"
  LIVE_HIT=""
  for e in "${LIVE_CWD_ENTRIES[@]:-}"; do
    [[ -z "$e" ]] && continue
    pid="${e%%	*}"; rest="${e#*	}"; cmd="${rest%%	*}"; cwd="${rest#*	}"
    case "$cwd" in
      "$cand"|"$cand"/*) LIVE_HIT="pid ${pid}, ${cmd}"; return 0 ;;
    esac
  done
  return 1
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
  local unique last pr_n pr_s action="REMOVE" existing

  # Dedup guard (#670) — mirrors the classify_worktree guard: under the default
  # --all scope detect_spawn_task (claude/* branches) and detect_historical (all
  # merged-unattached branches) both classify the same merged claude/* branches,
  # double-counting rows + counters. First row wins so the emitters and protective
  # counters stay truthful (one row per branch). Plain `if` per the set -e discipline.
  for existing in "${LOCAL_BRANCH_CANDIDATES[@]:-}"; do
    [[ -z "$existing" ]] && continue
    if [[ "${existing%%$'\t'*}" == "$branch" ]]; then
      return 0
    fi
  done

  if is_protected "$branch"; then action="SKIP — protected"; fi
  if [[ "$action" == "REMOVE" ]] && branch_has_worktree "$branch"; then action="SKIP — active worktree attached"; fi

  unique=$(git rev-list --count "${REMOTE_NAME}/${MAIN_BRANCH}..${branch}" 2>/dev/null || echo "?")
  last=$(git log -1 --format='%cs' "$branch" 2>/dev/null || echo "?")

  # PR-state read moved ABOVE the ancestry SKIP (#2216, #2779 Option B): under
  # --release-close (require_pr=1) a CONFIRMED MERGED PR is authoritative proof
  # the branch content is on main even when the source commits are not ancestors
  # of main — the squash-merge case. Without this, the ancestry SKIP below fires
  # unconditionally on every squash-merged branch ("unique commits exist (N)") and
  # --release-close reaps nothing. The PR-state source is the #655 prefetch map
  # (ensure_pr_map / pr_lookup), so BOTH the report row AND the MERGED rescue ride
  # one run-scoped gh list — zero surviving per-branch gh calls on --release-close
  # in map-`ok` mode; a degraded map falls back to the verbatim per-branch calls.
  ensure_pr_map
  pr_lookup "$branch"
  pr_n="$PR_LOOKUP_N"
  pr_s="$PR_LOOKUP_S"

  # Ancestry SKIP yields ONLY to a confirmed MERGED-PR rescue on the release-close
  # path (require_pr=1 && pr_s=="MERGED"). On require_pr=0 the rescue clause is
  # false, so this SKIP fires exactly as before — behavior byte-identical to the
  # pre-#2216 ordering for every non-release-close caller.
  if [[ "$action" == "REMOVE" && "$unique" != "0" ]] \
     && ! { [[ "$require_pr" == "1" && "$pr_s" == "MERGED" ]]; }; then
    action="SKIP — unique commits exist ($unique)"
  fi

  # Non-MERGED downgrade (retained stale/reopened-PR safety guard, #2779 R2): on
  # the release-close path a branch whose PR is anything but MERGED is SKIPped
  # even if ancestry would have passed it — the rescue never over-removes.
  if [[ "$action" == "REMOVE" && "$require_pr" == "1" && "$pr_s" != "MERGED" ]]; then
    action="SKIP — PR not merged ($pr_s)"
  fi

  LOCAL_BRANCH_CANDIDATES+=("${branch}	${unique}	${last}	${pr_n}	${pr_s}	${action}")
}

classify_remote() {
  local branch="$1"
  local pr_n pr_s action="REMOVE" existing

  # Dedup guard (#670) — symmetric with classify_local. Remote heads are not
  # double-enumerated under --all today (only detect_spawn_task rows remotes), but
  # the guard keeps the row set duplicate-free if a future scope re-enumerates.
  for existing in "${REMOTE_BRANCH_CANDIDATES[@]:-}"; do
    [[ -z "$existing" ]] && continue
    if [[ "${existing%%$'\t'*}" == "$branch" ]]; then
      return 0
    fi
  done

  if is_protected "$branch"; then action="SKIP — protected"; fi

  # PR-state via the #655 prefetch map (see classify_local); degraded → per-branch.
  ensure_pr_map
  pr_lookup "$branch"
  pr_n="$PR_LOOKUP_N"
  pr_s="$PR_LOOKUP_S"
  if [[ "$action" == "REMOVE" && "$pr_s" != "MERGED" ]]; then action="SKIP — PR not merged ($pr_s)"; fi

  REMOTE_BRANCH_CANDIDATES+=("${branch}	${pr_n}	${pr_s}	${action}")
}

classify_worktree() {
  local path="$1" branch="$2"
  local status="clean" disk action="REMOVE" cand_phys existing detached_ahead

  # Dedup guard (v1.11 operator scope call): under the default --all scope,
  # detect_spawn_task and detect_historical can both row the same worktree;
  # the first row wins so the emitters and the protective counters stay
  # truthful (one row per candidate). Plain `if` per the set -e discipline.
  for existing in "${WORKTREE_CANDIDATES[@]:-}"; do
    [[ -z "$existing" ]] && continue
    if [[ "${existing%%$'\t'*}" == "$path" ]]; then
      return 0
    fi
  done

  ensure_liveness_map
  cand_phys="$(physical_path "$path")"

  worktree_is_clean "$path" || status="dirty"
  disk=$(worktree_size_mb "$path")

  # Clause precedence (v1.11 combined design spec, D-3): protective context
  # classes first (primary → SELF → live), tree-state classes second (dirty →
  # protected → not-merged). A dirty SELF tree reports SELF; a dirty live-held
  # tree reports the live session. Protective classes are facts about WHO holds
  # the tree, are stable across tree-state changes, and are never overridden by
  # --force (the apply loops act only on action == "REMOVE"). The primary
  # clause also matches the physically-normalized main-worktree path — the
  # WORKSPACE_ROOT comparison alone never fires on the real primary (the
  # primary checkout is a child of the workspace root, not the root itself).
  # Fail-closed conversion runs after the chain so state labels stay
  # informative when the oracle is down and only unprovable would-be-removals
  # are blocked.
  if [[ "$path" == "$WORKSPACE_ROOT" ]] || [[ -n "$MAIN_WORKTREE" && "$cand_phys" == "$MAIN_WORKTREE" ]]; then
    action="SKIP — primary checkout"
  elif [[ -n "$SCRIPT_WORKTREE" && "$cand_phys" == "$SCRIPT_WORKTREE" ]]; then
    action="SELF — script's own runtime worktree (protected)"
  elif [[ "$ORACLE_STATE" == "ok" ]] && worktree_is_live "$cand_phys"; then
    action="SKIP — live session (${LIVE_HIT})"
  elif [[ "$status" == "dirty" ]]; then
    action="SKIP — uncommitted changes"
  elif [[ -n "$branch" ]] && is_protected "$branch"; then
    action="SKIP — protected branch"
  elif [[ -n "$branch" ]] && ! is_fully_merged "$branch"; then
    action="SKIP — branch not fully merged"
  elif [[ -z "$branch" && "$FORCE" != "1" ]] && [[ -d "$path" ]] \
       && { detached_ahead=$(git -C "$path" rev-list --count "${REMOTE_NAME}/${MAIN_BRANCH}..HEAD" 2>/dev/null || echo "?"); [[ "$detached_ahead" != "0" ]]; }; then
    # EDIT 5 (operator-locked BROAD, v2.09): the branch not-merged clauses above are
    # [[ -n "$branch" ]]-guarded, so a detached-HEAD worktree (empty branch — the
    # common case for agent-* trees) bypasses the merge gate entirely and would
    # classify REMOVE, discarding the only checkout pointing at possibly-unmerged
    # work. This clause closes that data-loss class for ALL detached worktrees
    # (not just agent-*): a detached tree whose HEAD has commits not in
    # origin/main — or whose count cannot be computed ("?" ≠ "0") → fail-closed —
    # is preserved. Strictly additive (adds SKIPs, never new removals). The
    # distinct counted reason surfaces the retained set + per-tree ahead-count
    # (no silent skip), mirroring the "unique commits exist ($unique)" branch idiom.
    # Force-overridable: gated on FORCE != 1 so `--apply --force` re-promotes the
    # tree to REMOVE (operator escape hatch for a reviewed backlog); deliberately
    # NOT in the SELF/LIVE never-override set.
    # Merge-strategy note: this test assumes a merge-commit strategy (this repo
    # merges via merge-commits, so a merged tree returns rev-list origin/main..HEAD
    # = 0 → auto-REMOVE; only genuinely-unmerged work SKIPs, bounding the backlog).
    # If squash-merge is ever adopted, switch to content-aware detection
    # (git cherry / patch-id) to avoid a false-positive pileup.
    action="SKIP — detached, unmerged commits (${detached_ahead})"
  fi

  if [[ "$action" == "REMOVE" && "$ORACLE_STATE" != "ok" ]]; then
    action="SKIP — liveness oracle unavailable (fail-closed)"
  fi

  WORKTREE_CANDIDATES+=("${path}	${branch}	${status}	${disk}	${action}")
}

# Derive the leading version prefix (v<major>.<minor>) from a milestone slug, or
# empty when the slug carries none. Parameter-expansion only — bash 3.2's
# BASH_REMATCH is unreliable on macOS (matches but does not populate captures),
# so this avoids =~ entirely. Rejects patch-form (v1.2.3) and non-numeric (vX.Y).
version_prefix_of() {
  local slug="$1" vp rest maj min
  case "$slug" in
    v[0-9]*.[0-9]*-*) vp="${slug%%-*}" ;;   # up to first '-': v1.11-foo -> v1.11
    *) printf ''; return 0 ;;
  esac
  rest="${vp#v}"; maj="${rest%%.*}"; min="${rest#*.}"
  case "$maj$min" in *[!0-9]*) printf ''; return 0 ;; esac   # non-digit -> reject
  case "$min" in *.*) printf ''; return 0 ;; esac            # second dot (v1.2.3) -> reject
  printf '%s' "$vp"
}

detect_release_close() {
  local slug="$1"
  [[ -z "$slug" ]] && return 0
  refresh_wt_snapshot
  local b
  # Match the bare slug form (release/<slug>), the version-prefixed form
  # (release/vX.Y-<slug>) — release branches are routinely version-prefixed when a
  # release re-versions mid-flight — AND (#684) the Stage 12/13 chore branches
  # named chore/vX.Y-stage-<N>-<purpose>. Those chore branches carry the VERSION
  # prefix but NOT the slug, so the chore/v*-${slug}* pattern (version + slug)
  # cannot reach them; git-workflow.md § Step 10 documents them as in-scope. We
  # derive vX.Y from the slug's leading version token and add chore/vX.Y-stage-*,
  # anchored on the literal `-stage-` after the exact version so v1.1 cannot
  # over-match v1.11 (proven: `chore/v1.1-stage-*` never matches `chore/v1.11-...`).
  # When the slug carries no version token, no stage-glob is added (nothing to
  # derive) and behavior is unchanged.
  local vprefix stage_local="" stage_remote="" stage_case=""
  vprefix=$(version_prefix_of "$slug")
  if [[ -n "$vprefix" ]]; then
    stage_local="refs/heads/chore/${vprefix}-stage-*"
    stage_remote="chore/${vprefix}-stage-*"
    stage_case="chore/${vprefix}-stage-*"
  fi
  for b in $(git for-each-ref \
      "refs/heads/release/${slug}*" "refs/heads/chore/${slug}*" \
      "refs/heads/release/v*-${slug}*" "refs/heads/chore/v*-${slug}*" \
      ${stage_local:+"$stage_local"} \
      --format='%(refname:short)' 2>/dev/null); do
    classify_local "$b" 1   # require_pr=1 (#2216): a MERGED PR rescues a squash-merged release branch from the ancestry SKIP
  done
  for b in $(git ls-remote --heads "$REMOTE_NAME" \
      "release/${slug}*" "chore/${slug}*" \
      "release/v*-${slug}*" "chore/v*-${slug}*" \
      ${stage_remote:+"$stage_remote"} \
      2>/dev/null | awk '{print $2}' | sed 's|^refs/heads/||'); do
    classify_remote "$b"
  done
  while IFS= read -r line; do
    [[ "$line" =~ ^worktree[[:space:]](.*)$ ]] || continue
    local wpath="${BASH_REMATCH[1]}" wbranch=""
    local next
    next=$(branch_for_worktree "$wpath")
    wbranch="${next#refs/heads/}"
    [[ -z "$wbranch" || "$wbranch" == "$next" ]] && continue
    case "$wbranch" in
      release/${slug}*|chore/${slug}*|release/v*-${slug}*|chore/v*-${slug}*)
        classify_worktree "$wpath" "$wbranch" ;;
      *)
        # #684 stage-branch arm — separate case so the derived glob is a real
        # pattern (not a literal). Plain `if` per the set -e discipline.
        if [[ -n "$stage_case" ]]; then
          case "$wbranch" in
            $stage_case) classify_worktree "$wpath" "$wbranch" ;;
          esac
        fi
        ;;
    esac
  done <<<"$WT_SNAPSHOT"
}

detect_spawn_task() {
  refresh_wt_snapshot
  local b
  for b in $(git for-each-ref 'refs/heads/claude/*' --format='%(refname:short)' 2>/dev/null); do
    classify_local "$b" 0
  done
  for b in $(git ls-remote --heads "$REMOTE_NAME" 'claude/*' 2>/dev/null | awk '{print $2}' | sed 's|^refs/heads/||'); do
    classify_remote "$b"
  done
  while IFS= read -r line; do
    [[ "$line" =~ ^worktree[[:space:]](.*)$ ]] || continue
    local wpath="${BASH_REMATCH[1]}" wbranch="" wbase=""
    wbranch=$(branch_for_worktree "$wpath")
    wbranch="${wbranch#refs/heads/}"
    wbase="${wpath##*/}"                       # path basename: agent-<hash> / claude-<name>
    # claude/* spawn_task worktrees (branch-keyed, unchanged) OR agent-* Agent-tool
    # worktrees (path-keyed: live evidence shows most agent-* trees are detached →
    # no branch to match on). Both lineages route through the unchanged
    # classify_worktree so every liveness / dirty / SELF / primary gate is
    # preserved verbatim. The ::: separator is a literal that cannot appear in a
    # refname or a worktree basename; the dedup guard (classify_worktree :410)
    # rows a tree matching both lineages exactly once.
    case "$wbranch:::$wbase" in
      claude/*:::*)  classify_worktree "$wpath" "$wbranch" ;;
      *:::agent-*)   classify_worktree "$wpath" "$wbranch" ;;
    esac
  done <<<"$WT_SNAPSHOT"
}

detect_historical() {
  refresh_wt_snapshot
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
    wbranch=$(branch_for_worktree "$wpath")
    wbranch="${wbranch#refs/heads/}"
    if [[ -z "$wbranch" ]] || is_fully_merged "$wbranch"; then
      classify_worktree "$wpath" "$wbranch"
    fi
  done <<<"$WT_SNAPSHOT"
}

# ─── Orphan-tag + abandoned-version-row detection (--reap-orphan-tags) ────────
#
# A fourth outcome class: an orphaned git tag of an ABANDONED version. It reuses
# the script's classify → apply → verify → report skeleton, but on a separate
# accumulator (TAG_CANDIDATES) and a separate, opt-in scope — it does NOT run in
# the default --all / --release-close close path (a reap needs ledger authority +
# double opt-in). Authority is the #1679 re-version ledger or an explicit
# --abandoned <tag>; abandonment is never inferred from "not the latest version."
#
# Record per TAG_CANDIDATES entry (TAB-separated, action LAST so the in-place
# rewrite idiom `${r%$'\t'*}$'\t'<new>` used everywhere else applies unchanged):
#   tag <TAB> slug <TAB> reshipped_as <TAB> merge_sha <TAB> action
TAG_CANDIDATES=()
STALE_VERSION_ROWS=()     # slug<TAB>abandoned_version<TAB>final_version (R-3 runbook pointers; report-only)

# Resolve a column's 0-based index from a markdown pipe-table header line by NAME,
# not ordinal — robust to the column-order changes the closeout-tooling rework
# (RELEASE_LOG state/date reorder) introduces, so this reader cannot drift against
# it. Header is the first `| a | b | … |` line in the file. Prints the index or
# nothing (caller treats empty as "column absent"). Cells are trimmed of spaces.
table_col_index() {
  local file="$1" want="$2"
  [[ -r "$file" ]] || return 0
  awk -F'|' -v want="$want" '
    /^\|/ {
      for (i = 1; i <= NF; i++) { c = $i; gsub(/^[ \t]+|[ \t]+$/, "", c); if (c == want) { print i - 1; exit } }
      exit   # only inspect the first table row (the header)
    }' "$file"
}

# Read a single cell from a markdown data row by header-resolved column index.
# row = the raw `| … |` line; idx = 0-based index from table_col_index. Trims spaces.
table_cell() {
  local row="$1" idx="$2"
  awk -F'|' -v i="$((idx + 1))" '{ c = $i; gsub(/^[ \t]+|[ \t]+$/, "", c); print c }' <<<"$row"
}

# Is this a ledger DATA row (a re-version entry), not the header / separator / prose?
# A data row starts with `|`, is not a `---` separator, and its first NON-EMPTY cell is
# not the literal `slug` (the header). Inspecting the first non-empty cell — rather than a
# fixed column index — is robust to the leading-`|` table form (where awk -F'|' makes
# field 1 empty) AND to header column reordering.
_is_ledger_data_row() {
  [[ "$1" == \|* ]] || return 1
  case "$1" in *---*) return 1 ;; esac
  local first
  first=$(awk -F'|' '{ for (i=1;i<=NF;i++){ c=$i; gsub(/^[ \t]+|[ \t]+$/,"",c); if (c!="") { print c; exit } } }' <<<"$1")
  [[ -n "$first" && "$first" != "slug" ]]
}

# Look up a ledger cell for a (slug, abandoned_version) row, by header-resolved column.
# Echoes the cell value, or empty if the row/column is absent. The composite key is
# (slug, abandoned_version) per the ledger's frozen grain (one row per abandoned ver).
ledger_cell_for() {
  local slug="$1" ver="$2" col="$3" ci si vi line
  [[ -r "$LEDGER_PATH" ]] || return 0
  ci=$(table_col_index "$LEDGER_PATH" "$col");                  [[ -n "$ci" ]] || return 0
  si=$(table_col_index "$LEDGER_PATH" "slug")
  vi=$(table_col_index "$LEDGER_PATH" "abandoned_version")
  [[ -n "$si" && -n "$vi" ]] || return 0
  while IFS= read -r line; do
    _is_ledger_data_row "$line" || continue
    [[ "$(table_cell "$line" "$si")" == "$slug" ]] || continue
    [[ "$(table_cell "$line" "$vi")" == "$ver" ]] || continue
    table_cell "$line" "$ci"; return 0
  done < "$LEDGER_PATH"
  return 0     # not found — explicit (a while-read loop returns 1 at EOF; set -e trap)
}

# Load the abandonment authority into ABANDONED_SET as tag<TAB>slug records.
# Priority: the #1679 ledger (every row with disposition=tag-orphaned AND no
# reaped_ref yet — equivalently abandoned_tag_pushed=true, unreaped), THEN an
# explicit --abandoned <tag> (slug unknown → empty). Never infers abandonment.
ABANDONED_SET=()
load_abandonment_authority() {
  ABANDONED_SET=()
  local di si vi ai ri line disp slug ver pushed reaped
  if [[ -r "$LEDGER_PATH" ]]; then
    di=$(table_col_index "$LEDGER_PATH" "disposition")
    si=$(table_col_index "$LEDGER_PATH" "slug")
    vi=$(table_col_index "$LEDGER_PATH" "abandoned_version")
    ai=$(table_col_index "$LEDGER_PATH" "abandoned_tag_pushed")
    ri=$(table_col_index "$LEDGER_PATH" "reaped_ref")
    if [[ -n "$di" && -n "$si" && -n "$vi" ]]; then
      while IFS= read -r line; do
        _is_ledger_data_row "$line" || continue
        disp=$(table_cell "$line" "$di")
        [[ "$disp" == "tag-orphaned" ]] || continue          # the reap-authority disposition
        slug=$(table_cell "$line" "$si"); ver=$(table_cell "$line" "$vi")
        # Defensive cross-checks against the frozen enum's field mapping:
        if [[ -n "$ai" ]]; then pushed=$(table_cell "$line" "$ai"); [[ "$pushed" == "true" ]] || continue; fi
        if [[ -n "$ri" ]]; then reaped=$(table_cell "$line" "$ri"); [[ -z "$reaped" || "$reaped" == "—" ]] || continue; fi
        ABANDONED_SET+=("${ver}	${slug}")
      done < "$LEDGER_PATH"
    fi
  fi
  [[ -n "$ABANDONED_ARG" ]] && ABANDONED_SET+=("${ABANDONED_ARG}	")   # explicit, slug unknown
  return 0     # explicit — the trailing [[ … ]] && … returns 1 when ABANDONED_ARG is empty (set -e trap)
}

# Is <tag> a canonical (live) Tag-column value of a RELEASE_LOG row? Header-resolved
# (NOT `^| <tag> |`) so the v1.03 row — which carries literal text in three cells —
# cannot false-match. A tag that is canonical for a live row is NEVER reaped, even if
# wrongly declared abandoned (it is typically the sibling release that won the slot).
tag_is_canonical_release() {
  local tag="$1" ti line cell
  [[ -r "$RELEASE_LOG_PATH" ]] || return 1
  ti=$(table_col_index "$RELEASE_LOG_PATH" "Tag"); [[ -n "$ti" ]] || return 1
  while IFS= read -r line; do
    [[ "$line" == \|* ]] || continue
    case "$line" in *---*) continue ;; esac
    cell=$(table_cell "$line" "$ti")
    [[ "$cell" == "Tag" ]] && continue       # header
    [[ "$cell" == "$tag" ]] && return 0
  done < "$RELEASE_LOG_PATH"
  return 1
}

# ─── Host tag-protection preflight ───────────────────────────────────────────
#
# Answers, for ONE tag: does the REMOTE's host actively forbid deleting it? Echoes
# exactly one of three states — never a boolean, because the third state is the point:
#
#   protected     an ACTIVE host ruleset targets tags, carries a `deletion` rule, and
#                 its ref-name include set matches this tag
#   unprotected   DETERMINATELY not protected — either the remote is not a
#                 policy-bearing host at all (a local path or non-GitHub URL, where no
#                 such ruleset can exist), or its policy WAS read and covers nothing
#   undetermined  the remote IS a policy-bearing host but its policy could not be read
#                 (gh absent, unauthenticated, or the endpoint errored)
#
# FAIL DIRECTION — deliberate, and the reason this preflight is worth its lines.
# `undetermined` is NOT folded into `unprotected`. A preflight that failed open would
# fall through to the reap path's "--force required; tag delete is MODERATE-reversible"
# message on exactly the credential class that cannot read host policy — telling an
# operator a deletion is moderately reversible on a repository where it cannot execute
# at all. So indeterminacy fails CLOSED to no-attempt.
#
# Failing closed costs nothing on a genuinely unprotected deployment, because the
# capability is preserved two ways that do not require reading a host:
#   (1) a NON-policy-bearing remote resolves `unprotected` determinately with no host
#       query — which is also why every pre-existing self-test keeps its behaviour
#       unchanged: the reap fixtures push to a local bare-directory remote, so they
#       take this arm on its merits, not by an exemption; and
#   (2) an operator who knows their deployment carries no tag protection asserts it
#       with --assume-unprotected — the same shape as --abandoned: state the authority
#       the tool refuses to infer.
#
# Reversibility of this preflight: CHEAP / confidence HIGH (one read-only branch).
#
# CALLING CONVENTION — the answer is returned in the GLOBAL `TAG_PROTECTION_STATE`, and
# this function must be called DIRECTLY, never as `$(tag_protection_state …)`. Command
# substitution forks a subshell, so the two companion globals below would be set in the
# child and lost — yielding an `undetermined` with an empty reason, which reads as a
# populated classification and is not one. The three values are one answer and travel
# together.
TAG_PROTECTION_STATE=""       # protected | unprotected | undetermined
TAG_PROTECTION_REASON=""      # populated on `undetermined`; empty otherwise
TAG_PROTECTION_RULESET=""     # populated on `protected`; empty otherwise
tag_protection_state() {
  local tag="$1" url owner_repo ids id row name has_del incs pat
  TAG_PROTECTION_STATE=""; TAG_PROTECTION_REASON=""; TAG_PROTECTION_RULESET=""

  # Operator assertion of host state — an explicit claim, never an inference.
  if [[ "$ASSUME_UNPROTECTED" == "1" ]]; then TAG_PROTECTION_STATE="unprotected"; return 0; fi

  # Arm 1 — is the remote a policy-bearing host at all? A bare directory path, a
  # file:// URL, or any non-GitHub remote cannot carry a GitHub ruleset, so
  # `unprotected` here is a DETERMINATION, not a guess. No network call is made.
  url=$(git remote get-url "$REMOTE_NAME" 2>/dev/null || printf '%s' "$REMOTE_NAME")
  case "$url" in
    *github.com[:/]*) : ;;
    *) TAG_PROTECTION_STATE="unprotected"; return 0 ;;
  esac
  owner_repo=$(printf '%s' "$url" \
    | sed -E 's#^[a-z]+://[^@]*@#https://#; s#^[^@]*@github\.com:#https://github.com/#' \
    | sed -E 's#^https?://[^/]*github\.com/##; s#\.git$##; s#/+$##')
  if [[ -z "$owner_repo" || "$owner_repo" != */* ]]; then
    TAG_PROTECTION_STATE="undetermined"
    TAG_PROTECTION_REASON="could not derive owner/repo from the remote URL"
    return 0
  fi

  # Arm 2 — read host policy. Any failure to READ is `undetermined`, never
  # `unprotected`. gh is invoked through the script's resolved absolute path, NOT via
  # `command -v`: this script pins PATH to the system directories, so a bare `gh`
  # lookup misses a Homebrew install and would report every host undetermined.
  # gh's embedded --jq is used, so no external jq is required.
  ensure_gh_bin
  if [[ -z "$GH_BIN" ]]; then
    TAG_PROTECTION_STATE="undetermined"
    TAG_PROTECTION_REASON="gh CLI unavailable, so host policy is unreadable"
    return 0
  fi
  if ! ids=$("$GH_BIN" api "repos/${owner_repo}/rulesets" --paginate \
               --jq '.[] | select(.target == "tag" and .enforcement == "active") | .id' 2>/dev/null); then
    TAG_PROTECTION_STATE="undetermined"
    TAG_PROTECTION_REASON="rulesets endpoint unreadable by the invoking credential"
    return 0
  fi
  for id in $ids; do
    if ! row=$("$GH_BIN" api "repos/${owner_repo}/rulesets/${id}" \
                 --jq '[.name, ((([.rules[].type] | index("deletion")) != null)), (.conditions.ref_name.include // [] | join(" "))] | @tsv' 2>/dev/null); then
      TAG_PROTECTION_STATE="undetermined"
      TAG_PROTECTION_REASON="ruleset detail unreadable by the invoking credential"
      return 0
    fi
    name=$(awk -F'\t' '{print $1}' <<<"$row")
    has_del=$(awk -F'\t' '{print $2}' <<<"$row")
    incs=$(awk -F'\t' '{print $3}' <<<"$row")
    [[ "$has_del" == "true" ]] || continue
    for pat in $incs; do
      # `~ALL` is GitHub's every-ref sentinel. Otherwise glob-match the full ref form,
      # and the bare tag name as a tolerant fallback. RHS is deliberately UNQUOTED so
      # [[ == ]] performs pattern matching, which is what a ruleset include pattern is.
      # shellcheck disable=SC2053
      if [[ "$pat" == "~ALL" ]] || [[ "refs/tags/${tag}" == $pat ]] || [[ "$tag" == $pat ]]; then
        TAG_PROTECTION_STATE="protected"
        TAG_PROTECTION_RULESET="$name"
        return 0
      fi
    done
  done
  TAG_PROTECTION_STATE="unprotected"   # policy WAS read and covers nothing — a determination
  return 0
}

# Classify one authority-declared-abandoned tag: REMOVE if it is genuinely an orphan
# on origin AND the host permits removing it, else a counted RETAINED/SKIP reason.
# Guards (in order): authority gate (must be in ABANDONED_SET — held by construction
# here), canonical-version guard, on-origin probe (idempotency), host tag-protection
# preflight. reshipped_as/merge_sha come from the ledger row (the re-create source
# for a wrongly-reaped tag).
classify_tag() {
  local tag="$1" slug="$2" action="REMOVE" on_origin reshipped="?" merge_sha="?"
  if [[ -n "$slug" ]]; then
    reshipped=$(ledger_cell_for "$slug" "$tag" "final_version"); [[ -n "$reshipped" ]] || reshipped="?"
    merge_sha=$(ledger_cell_for "$slug" "$tag" "merge_sha");     [[ -n "$merge_sha" ]] || merge_sha="?"
  fi
  # Guard 1 — canonical-version guard: refuse to reap a tag that is the live canonical
  # Tag of a RELEASE_LOG row (the abandoned version of one release is often the live
  # tag of the sibling that won the slot).
  if tag_is_canonical_release "$tag"; then
    action="SKIP — canonical version of a live RELEASE_LOG row (not an orphan)"
  fi
  # Guard 2 — idempotency: already absent from origin → nothing to reap. Ordered BEFORE
  # the protection preflight because an absent tag needs no host answer, and "already
  # absent" is the more informative classification than "retained".
  if [[ "$action" == "REMOVE" ]]; then
    on_origin=$(git ls-remote --tags "$REMOTE_NAME" "refs/tags/${tag}" 2>/dev/null | grep -c "refs/tags/${tag}$" || true)
    [[ -z "$on_origin" ]] && on_origin=0
    [[ "$on_origin" == "0" ]] && action="SKIP — already absent from origin (nothing to reap)"
  fi
  # Guard 3 — host tag-protection preflight. A protected tag is RETAINED per the
  # tag-retention rule (core/rules/git-workflow.md § Tag Retention): the reap path is
  # unreachable for it, so the tool says so up front instead of demanding a double
  # opt-in for a push the host will reject. An UNDETERMINED host fails closed to
  # no-attempt — see tag_protection_state() for why that direction is deliberate.
  if [[ "$action" == "REMOVE" ]]; then
    # Called DIRECTLY, never in a command substitution — the answer travels in three
    # globals, and a subshell would strand the reason and the ruleset name.
    tag_protection_state "$tag"
    case "$TAG_PROTECTION_STATE" in
      protected)
        action="RETAINED — host tag protection active${TAG_PROTECTION_RULESET:+ (ruleset '${TAG_PROTECTION_RULESET}', deletion rule)}"
        ;;
      undetermined)
        action="SKIP — tag protection undetermined (${TAG_PROTECTION_REASON:-reason unreported}); nothing attempted"
        ;;
    esac
  fi
  TAG_CANDIDATES+=("${tag}	${slug:-?}	${reshipped}	${merge_sha}	${action}")
}

# Report-only: flag a RELEASE_LOG row that needs the R-3 corpus roll-forward — i.e. THE
# ABANDONING RELEASE'S OWN row still carries the abandoned version in its Version cell
# (it never got restamped to its final version). Keyed on (Milestone-slug, Version) so it
# does NOT false-fire on the SIBLING row that legitimately SHIPPED the version (the
# abandoned version of one release is usually the live Tag of the sibling that won the
# slot — that sibling's row is canonical, not stale). Excludes the `unrecoverable`
# historical case (its RELEASE_LOG version is correct by design). NEVER edits corpus prose.
detect_stale_version_rows() {
  STALE_VERSION_ROWS=()
  [[ -r "$LEDGER_PATH" && -r "$RELEASE_LOG_PATH" ]] || return 0
  local vi si fi line slug ver final
  local lvi lmi lline lver lmile
  vi=$(table_col_index "$LEDGER_PATH" "abandoned_version")
  si=$(table_col_index "$LEDGER_PATH" "slug")
  fi=$(table_col_index "$LEDGER_PATH" "final_version")
  lvi=$(table_col_index "$RELEASE_LOG_PATH" "Version")
  lmi=$(table_col_index "$RELEASE_LOG_PATH" "Milestone")
  [[ -n "$vi" && -n "$si" && -n "$lvi" && -n "$lmi" ]] || return 0
  while IFS= read -r line; do
    _is_ledger_data_row "$line" || continue
    ver=$(table_cell "$line" "$vi"); slug=$(table_cell "$line" "$si"); final=$(table_cell "$line" "$fi")
    [[ -n "$ver" && -n "$slug" ]] || continue
    [[ "$final" == "unrecoverable" ]] && continue          # historical case — version is correct by design
    [[ "$final" == "$ver" ]] && continue                   # final == abandoned (round-trip settled back) — not stale
    # Flag ONLY the abandoning release's OWN row (Milestone == slug) if its Version cell
    # still carries the abandoned version (i.e. it was never rolled forward to `final`).
    while IFS= read -r lline; do
      [[ "$lline" == \|* ]] || continue
      case "$lline" in *---*) continue ;; esac
      lmile=$(table_cell "$lline" "$lmi"); lver=$(table_cell "$lline" "$lvi")
      [[ "$lver" == "Version" ]] && continue               # header
      if [[ "$lmile" == "$slug" && "$lver" == "$ver" ]]; then
        STALE_VERSION_ROWS+=("${slug}	${ver}	${final:-?}")
        break
      fi
    done < "$RELEASE_LOG_PATH"
  done < "$LEDGER_PATH"
  return 0     # explicit — a while-read loop returns 1 at EOF (set -e trap)
}

detect_orphan_tags() {
  load_abandonment_authority
  local rec tag slug
  for rec in "${ABANDONED_SET[@]:-}"; do
    [[ -z "$rec" ]] && continue
    tag=$(awk -F'\t' '{print $1}' <<<"$rec"); slug=$(awk -F'\t' '{print $2}' <<<"$rec")
    [[ -n "$tag" ]] && classify_tag "$tag" "$slug"
  done
  detect_stale_version_rows
  return 0     # explicit — keep the detector set -e-safe regardless of the last call's status
}

# ─── Output ──────────────────────────────────────────────────────────────────

emit_markdown() {
  local ts; ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local lc=${#LOCAL_BRANCH_CANDIDATES[@]} rc=${#REMOTE_BRANCH_CANDIDATES[@]} wc=${#WORKTREE_CANDIDATES[@]}
  local pc=${#PRUNED_TRACKING_REFS[@]}
  local lr=0 rr=0 wr=0 disk_total=0 bfails=0 wfails=0 sc=0 lvc=0 fcc=0 a ref

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
    case "$action" in
      SELF*) ((sc++)) || true ;;
      "SKIP — live session"*) ((lvc++)) || true ;;
      "SKIP — liveness oracle unavailable"*) ((fcc++)) || true ;;
    esac
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
- **Protected worktrees:** $sc SELF (script's own runtime), $lvc held by live sessions$([[ "$ORACLE_BUILT" -eq 1 && "$ORACLE_STATE" != "ok" ]] && echo " — liveness oracle UNAVAILABLE (fail-closed; $fcc removal(s) blocked)")

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
  # Orphan-tag reaping + stale-version-row pointers (--reap-orphan-tags scope only).
  if [[ "$SCOPE" == "reap-orphan-tags" ]]; then
    cat <<EOF
## Detail — Orphan tags ${MODE/apply/reaped}

| Abandoned tag | Slug | Reshipped as | Merge SHA (re-create source) | Action |
|---|---|---|---|---|
EOF
    for r in "${TAG_CANDIDATES[@]:-}"; do
      [[ -z "$r" ]] && continue
      echo "$r" | awk -F'\t' '{printf "| `%s` | %s | %s | `%s` | %s |\n",$1,$2,$3,$4,$5}'
    done
    echo
    cat <<EOF
## Detail — Stale-version corpus rows (runbook R-3 roll-forward needed)

_Report-only — the tool never edits corpus prose. A row below has a RELEASE_LOG
Version cell still naming an abandoned version; restamp it forward per the
re-version recovery runbook (Step 1, R-3)._

| Slug | Abandoned version (in RELEASE_LOG) | Canonical version it should carry |
|---|---|---|
EOF
    for r in "${STALE_VERSION_ROWS[@]:-}"; do
      [[ -z "$r" ]] && continue
      echo "$r" | awk -F'\t' '{printf "| %s | %s | %s |\n",$1,$2,$3}'
    done
    echo
  fi
  echo "## Totals"
  echo "- $((lr + rr)) branches $noun, $((lc + rc - lr - rr - bfails)) skipped, $wr worktrees $noun, ≈${disk_total} MB $recov$([[ "$MODE" == "apply" ]] && echo ", $pc stale tracking ref(s) pruned")"
  if [[ "$MODE" == "apply" && $((bfails + wfails)) -gt 0 ]]; then
    echo "- ⚠ $((bfails + wfails)) removal(s) FAILED — see the PASS/FAIL log on stderr; a git safety guard refused (\`git branch -d\` on an unmerged branch, or \`git worktree remove\` on a dirty tree). Re-run with \`--force\` only if the deletion is intentional."
  fi
  if [[ "$sc" -gt 0 ]]; then
    echo "- $sc worktree(s) protected as script's own runtime (SELF)"
  fi
  if [[ "$lvc" -gt 0 ]]; then
    echo "- $lvc worktree(s) skipped — held by live sessions"
  fi
  if [[ "$fcc" -gt 0 ]]; then
    echo "- $fcc removal(s) blocked — liveness oracle unavailable (fail-closed)"
  fi
  if [[ "$FREED_RESOLVED" -gt 0 ]]; then
    echo "- $FREED_RESOLVED branch(es) removed after being freed by this run's worktree removals (resolve pass)"
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
  # Never-consulted must not read "unavailable" (DT F-01): a never-built map
  # carries no host-health evidence in either direction, so report the third
  # state rather than overclaiming degradation (or health).
  local oracle_field="$ORACLE_STATE"
  if [[ "$ORACLE_BUILT" -eq 0 ]]; then oracle_field="not-consulted"; fi
  printf '{"timestamp":"%s","scope":"%s","milestone_slug":"%s","mode":"%s","force":%s,"liveness_oracle":"%s",\n' "$ts" "$SCOPE" "$MILESTONE_SLUG" "$MODE" "$FORCE" "$oracle_field"
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
  printf '\n  ],\n  "orphan_tags":[\n'
  first=1
  for r in "${TAG_CANDIDATES[@]:-}"; do
    [[ -z "$r" ]] && continue
    [[ $first -eq 0 ]] && printf ',\n'; first=0
    awk -F'\t' '{printf "    {\"tag\":\"%s\",\"slug\":\"%s\",\"reshipped_as\":\"%s\",\"merge_sha\":\"%s\",\"action\":\"%s\"}",$1,$2,$3,$4,$5}' <<<"$r"
  done
  printf '\n  ],\n  "stale_version_rows":[\n'
  first=1
  for r in "${STALE_VERSION_ROWS[@]:-}"; do
    [[ -z "$r" ]] && continue
    [[ $first -eq 0 ]] && printf ',\n'; first=0
    awk -F'\t' '{printf "    {\"slug\":\"%s\",\"abandoned_version\":\"%s\",\"canonical_version\":\"%s\"}",$1,$2,$3}' <<<"$r"
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
  local wt_flag=""
  if [[ "$FORCE" == "1" ]]; then wt_flag="--force"; fi

  local r name path action idx unique del_flag

  idx=-1
  for r in "${LOCAL_BRANCH_CANDIDATES[@]:-}"; do
    ((idx++)) || true
    [[ -z "$r" ]] && continue
    name=$(awk -F'\t' '{print $1}' <<<"$r"); action=$(awk -F'\t' '{print $6}' <<<"$r")
    unique=$(awk -F'\t' '{print $2}' <<<"$r")
    [[ "$action" != "REMOVE" ]] && { echo "SKIPPED local $name — $action" >&2; continue; }
    # #683 (#2780 Option A') deletability-baseline fix: classification proves
    # merged-ness against origin/main (is_fully_merged / field-2 unique==0), but
    # `git branch -d` is HEAD-relative — from a behind-HEAD checkout (the Stage 13
    # hub-worktree case) it refuses a genuinely-merged branch and it survives. Use
    # -D when the branch is proven merged on the SAME ref classification used:
    # field-2 unique==0 AND a re-verify of is_fully_merged at the delete site
    # (collapses the staleness window between the classify loop and here). Fall
    # back to -d otherwise, so an unmerged branch (unique!=0 — never reaches this
    # loop as REMOVE, doubly-guarded) still requires --force. FORCE=1 keeps -D.
    del_flag="-d"
    if [[ "$FORCE" == "1" ]]; then
      del_flag="-D"
    elif [[ "$unique" == "0" ]] && is_fully_merged "$name"; then
      del_flag="-D"
    fi
    if git branch $del_flag "$name" 2>&1 | sed 's/^/  git: /' >&2; then
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
    ensure_gh_bin
    if [[ -z "$GH_BIN" ]]; then
      echo "FAIL remote $name — gh unavailable under the pinned PATH; cannot delete remote ref" >&2
      REMOTE_BRANCH_CANDIDATES[$idx]="${r%$'\t'*}"$'\t'"FAILED — gh unavailable"
      continue
    fi
    if "$GH_BIN" api -X DELETE "repos/${REPO_SLUG}/git/refs/heads/${name}" --silent 2>&1 | sed 's/^/  gh: /' >&2; then
      echo "PASS remote $name removed" >&2
      REMOTE_BRANCH_CANDIDATES[$idx]="${r%$'\t'*}"$'\t'"REMOVED"
    else
      echo "FAIL remote $name — gh api DELETE failed" >&2
      REMOTE_BRANCH_CANDIDATES[$idx]="${r%$'\t'*}"$'\t'"FAILED — gh api DELETE failed"
    fi
  done

  # Apply-time liveness re-verification (v1.11 amendment A-Recheck): the
  # classification-time map ages across the multi-minute branch/remote phases
  # above (per-branch gh calls), while removal is the LAST step — and git
  # porcelain does NOT refuse removal of a clean live-held tree. Rebuild the
  # map once at the worktree-apply-loop entry and re-check each row still
  # REMOVE: a fresh hit rewrites the row in place to the live-session skip;
  # oracle-unavailable at re-check time converts residual REMOVEs fail-closed
  # (same labels as classification time). Residual exposure after this
  # re-check is the seconds between it and the porcelain call.
  build_liveness_map
  idx=-1
  for r in "${WORKTREE_CANDIDATES[@]:-}"; do
    ((idx++)) || true
    [[ -z "$r" ]] && continue
    path=$(awk -F'\t' '{print $1}' <<<"$r"); action=$(awk -F'\t' '{print $5}' <<<"$r")
    [[ "$action" != "REMOVE" ]] && continue
    if [[ "$ORACLE_STATE" == "ok" ]]; then
      if worktree_is_live "$path"; then
        echo "SKIPPED worktree $path — live session detected at apply time (${LIVE_HIT})" >&2
        WORKTREE_CANDIDATES[$idx]="${r%$'\t'*}"$'\t'"SKIP — live session (${LIVE_HIT})"
      fi
    else
      echo "SKIPPED worktree $path — liveness oracle unavailable at apply time; fail-closed" >&2
      WORKTREE_CANDIDATES[$idx]="${r%$'\t'*}"$'\t'"SKIP — liveness oracle unavailable (fail-closed)"
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

# ─── Orphan-tag reap (--reap-orphan-tags apply) ──────────────────────────────
#
# Reap = delete the abandoned-version orphan tag on origin (non-force) THEN locally.
# Non-force `git push --delete` / `git tag -d` are git porcelain and are NOT in the
# destructive-action hook's blocked set (only force-push forms are) — a tag delete is
# a forward removal of a ref, not a history rewrite. Two safety properties this loop
# enforces that a borrowed branch-delete pattern does not:
#   (1) TWO-SURFACE ORDERING — origin first, local ONLY on origin success. A `git tag
#       -d` that ran past a failed origin delete would leave origin and local
#       divergent (origin keeps the tag, local loses it). So the local delete is GATED
#       on the origin delete succeeding — never `|| true` past a failed origin delete.
#   (2) REFUSED vs network-FAILED — a policy refusal (tag protected / in use) means
#       STOP; a transport failure (origin unreachable) is retry-safe and idempotent.
#       They are recorded distinctly, not collapsed into one "FAILED".
# Double opt-in: an actual reap needs --apply AND --force (a tag delete is
# MODERATE-reversibility), the same gate the existing branch -D path uses. On success,
# transitions the ledger row to tag-reaped + writes reaped_ref (consumer → producer).
reap_orphan_tags() {
  echo "── Reap phase — deleting authority-declared-abandoned orphan tags (non-force) ──" >&2
  local r tag slug action idx out rc
  idx=-1
  for r in "${TAG_CANDIDATES[@]:-}"; do
    ((idx++)) || true
    [[ -z "$r" ]] && continue
    tag=$(awk -F'\t' '{print $1}' <<<"$r"); slug=$(awk -F'\t' '{print $2}' <<<"$r")
    action=$(awk -F'\t' '{print $5}' <<<"$r")
    # Retained-under-host-protection: settle the ledger row and move on. No push is
    # issued and --force is NOT required, because nothing destructive is attempted.
    # Ordered ahead of the generic non-REMOVE skip so the row transition happens; every
    # other non-REMOVE action (canonical guard, already-absent, protection undetermined)
    # still falls through to that skip and transitions nothing.
    if [[ "$action" == RETAINED* ]]; then
      echo "RETAINED tag $tag — $action; no deletion attempted" >&2
      [[ -n "$slug" && "$slug" != "?" ]] && ledger_mark_retained "$slug" "$tag"
      continue
    fi
    [[ "$action" != "REMOVE" ]] && { echo "SKIPPED tag $tag — $action" >&2; continue; }
    # Double opt-in: --force required (MODERATE-reversibility — re-pushable but
    # transiently breaks any reference that resolved the tag).
    if [[ "$FORCE" != "1" ]]; then
      echo "SKIPPED tag $tag — reap requires --apply --force (double opt-in; tag delete is MODERATE-reversible)" >&2
      TAG_CANDIDATES[$idx]="${r%$'\t'*}"$'\t'"SKIP — needs --force"
      continue
    fi
    # Surface 1: origin. Capture stderr so REFUSED can be discriminated from a
    # transport failure. NON-FORCE delete (git push --delete) — never +refspec.
    rc=0
    out=$(git push --delete "$REMOTE_NAME" "refs/tags/${tag}" 2>&1) || rc=$?
    printf '%s\n' "$out" | sed 's/^/  git: /' >&2
    if [[ "$rc" -eq 0 ]]; then
      # Surface 2: local — ONLY after origin succeeded (avoids origin/local divergence).
      git tag -d "$tag" >/dev/null 2>&1 || true
      echo "PASS tag $tag reaped from origin + local" >&2
      TAG_CANDIDATES[$idx]="${r%$'\t'*}"$'\t'"REMOVED"
      [[ -n "$slug" && "$slug" != "?" ]] && ledger_mark_reaped "$slug" "$tag"
    elif grep -qiE 'remote rejected|protected|denied|permission|refusing|pre-receive|hook declined' <<<"$out"; then
      echo "FAIL tag $tag — push --delete REFUSED (policy/protection); stop — do not retry" >&2
      TAG_CANDIDATES[$idx]="${r%$'\t'*}"$'\t'"REFUSED — push --delete rejected (policy/protection)"
    else
      # Transport / unreachable-origin / unknown-non-policy: retry-safe, idempotent.
      # Local tag is intentionally LEFT in place — the ledger-authoritative state is
      # "tag on origin"; a local-only delete would create divergence.
      echo "FAIL tag $tag — push --delete FAILED (network/transport); retry when origin is reachable" >&2
      TAG_CANDIDATES[$idx]="${r%$'\t'*}"$'\t'"FAILED — network/transport (retry-safe)"
    fi
  done
  return 0
}

# Post-reap verification (AC4: never silently claim success). Re-probe origin for each
# tag the reap rewrote to REMOVED; a survivor (still on origin) is reclassified, so the
# report never asserts a reap that did not hold. Runs in --apply only; returns 0.
verify_tag_apply() {
  local r tag idx survivors=0 on_origin
  idx=-1
  for r in "${TAG_CANDIDATES[@]:-}"; do
    ((idx++)) || true
    [[ -z "$r" ]] && continue
    [[ "$(awk -F'\t' '{print $5}' <<<"$r")" != "REMOVED" ]] && continue
    tag=$(awk -F'\t' '{print $1}' <<<"$r")
    on_origin=$(git ls-remote --tags "$REMOTE_NAME" "refs/tags/${tag}" 2>/dev/null | grep -c "refs/tags/${tag}$" || true)
    [[ -z "$on_origin" ]] && on_origin=0
    if [[ "$on_origin" != "0" ]]; then
      echo "SKIPPED-VERIFY tag $tag — reported REMOVED but still present on origin" >&2
      TAG_CANDIDATES[$idx]="${r%$'\t'*}"$'\t'"SKIPPED — survived apply (still on origin)"
      ((survivors++)) || true
    fi
  done
  if [[ "$survivors" -eq 0 ]]; then
    echo "PASS tag-verify — every reaped tag confirmed gone from origin (zero survivors)" >&2
  else
    echo "WARN tag-verify — $survivors tag(s) reported REMOVED but survived; reclassified SKIPPED" >&2
  fi
  return 0
}

# Write-back (consumer → producer): transition the matched ledger row IN PLACE,
# mutating ONLY the two cells #1679's frozen schema permits — disposition (→ tag-reaped)
# and reaped_ref — keyed on (slug, abandoned_version), header-resolved. Honors the
# ledger's append-only invariant: exactly ONE row changes; no row is added or removed;
# no other cell is touched. reaped_ref is set to the current HEAD short SHA (the cleanup
# commit reference) when it is not already set.
ledger_mark_reaped() {
  local slug="$1" ver="$2"
  [[ -w "$LEDGER_PATH" ]] || { echo "WARN ledger-writeback — $LEDGER_PATH not writable; skipped" >&2; return 0; }
  local di ri si vi ncol ref
  di=$(table_col_index "$LEDGER_PATH" "disposition")
  ri=$(table_col_index "$LEDGER_PATH" "reaped_ref")
  si=$(table_col_index "$LEDGER_PATH" "slug")
  vi=$(table_col_index "$LEDGER_PATH" "abandoned_version")
  if [[ -z "$di" || -z "$ri" || -z "$si" || -z "$vi" ]]; then
    echo "WARN ledger-writeback — could not resolve disposition/reaped_ref columns; skipped" >&2
    return 0
  fi
  ncol=$(awk -F'|' '/^\|/ {print NF; exit}' "$LEDGER_PATH")     # field count incl. the empty edges
  ref=$(git rev-parse --short HEAD 2>/dev/null || echo "reaped")
  # Transform into a variable (here-string back to the same path) — NO temp file, NO
  # rm/mv, preserving the script's "zero rm/rmdir/unlink" contract. awk exits 3 when no
  # row matched, so a non-match leaves the ledger byte-for-byte unchanged.
  local rewritten rc=0
  rewritten=$(awk -F'|' -v OFS='|' \
      -v slug="$slug" -v ver="$ver" -v di="$((di + 1))" -v ri="$((ri + 1))" \
      -v si="$((si + 1))" -v vi="$((vi + 1))" -v ref="$ref" -v nf="$ncol" '
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    {
      # Rewrite ONLY a single matching DATA row; pass everything else through verbatim.
      if ($0 ~ /^\|/ && NF == nf && trim($si) == slug && trim($vi) == ver && trim($di) == "tag-orphaned") {
        $di = " tag-reaped "
        $ri = " " ref " "
        changed = 1
      }
      print
    }
    END { if (!changed) exit 3 }
  ' "$LEDGER_PATH") || rc=$?
  if [[ "$rc" -eq 0 ]]; then
    printf '%s\n' "$rewritten" > "$LEDGER_PATH"     # in-place content replace; no rm/mv
    echo "PASS ledger-writeback — ($slug, $ver) → disposition=tag-reaped, reaped_ref=$ref" >&2
  else
    echo "WARN ledger-writeback — no matching tag-orphaned row for ($slug, $ver); ledger unchanged" >&2
  fi
  return 0
}

# Write-back sibling for the RETAINED outcome: transition the matched ledger row IN
# PLACE from `tag-orphaned` to the terminal `tag-retained`, mutating ONE cell —
# `disposition`. `reaped_ref` is deliberately LEFT UNSET: it is the back-reference the
# reaper fills when it reaps, and nothing was reaped. The transition is what
# de-authorizes the row for any future reap, because load_abandonment_authority()
# selects only on `tag-orphaned` — so idempotency holds by construction, with no extra
# guard. Same append-only invariant as ledger_mark_reaped(): exactly one row changes,
# no row is added or removed, no other cell is touched, and a non-match leaves the
# ledger byte-for-byte unchanged.
ledger_mark_retained() {
  local slug="$1" ver="$2"
  [[ -w "$LEDGER_PATH" ]] || { echo "WARN ledger-writeback — $LEDGER_PATH not writable; skipped" >&2; return 0; }
  local di si vi ncol
  di=$(table_col_index "$LEDGER_PATH" "disposition")
  si=$(table_col_index "$LEDGER_PATH" "slug")
  vi=$(table_col_index "$LEDGER_PATH" "abandoned_version")
  if [[ -z "$di" || -z "$si" || -z "$vi" ]]; then
    echo "WARN ledger-writeback — could not resolve disposition/slug/abandoned_version columns; skipped" >&2
    return 0
  fi
  ncol=$(awk -F'|' '/^\|/ {print NF; exit}' "$LEDGER_PATH")
  local rewritten rc=0
  rewritten=$(awk -F'|' -v OFS='|' \
      -v slug="$slug" -v ver="$ver" -v di="$((di + 1))" \
      -v si="$((si + 1))" -v vi="$((vi + 1))" -v nf="$ncol" '
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    {
      if ($0 ~ /^\|/ && NF == nf && trim($si) == slug && trim($vi) == ver && trim($di) == "tag-orphaned") {
        $di = " tag-retained "
        changed = 1
      }
      print
    }
    END { if (!changed) exit 3 }
  ' "$LEDGER_PATH") || rc=$?
  if [[ "$rc" -eq 0 ]]; then
    printf '%s\n' "$rewritten" > "$LEDGER_PATH"     # in-place content replace; no rm/mv
    echo "PASS ledger-writeback — ($slug, $ver) → disposition=tag-retained (no reap; reaped_ref left unset)" >&2
  else
    echo "WARN ledger-writeback — no matching tag-orphaned row for ($slug, $ver); ledger unchanged" >&2
  fi
  return 0
}

# ─── Fixed-point resolve pass (#53) ─────────────────────────────────────────

# After the worktree loop, branches that were "SKIP — active worktree attached"
# at detection — or, under --historical, never enumerated at all (attached
# branches are filtered at detect time) — may have become removable. Exactly
# ONE bounded re-evaluation pass: worktree removal frees branches; branch
# removal frees nothing further, so a single pass reaches the fixed point for
# the enumerated input. Invariant: ONLY worktrees this run actually REMOVED
# free their branches — SELF / live-session / dirty / FAILED worktrees keep
# their branches attached-and-skipped. Runs between apply_removals and
# verify_apply; verify then re-checks pass-2 REMOVED rows exactly like pass-1
# rows. Returns 0 unconditionally (set -e discipline).
FREED_RESOLVED=0

resolve_freed_branches() {
  echo "── Resolve phase — re-evaluating branches freed by this run's worktree removals (single bounded pass) ──" >&2
  local r wbranch waction freed del_flag
  freed=()
  for r in "${WORKTREE_CANDIDATES[@]:-}"; do
    [[ -z "$r" ]] && continue
    waction=$(awk -F'\t' '{print $5}' <<<"$r")
    [[ "$waction" != "REMOVED" ]] && continue
    wbranch=$(awk -F'\t' '{print $2}' <<<"$r")
    [[ -z "$wbranch" ]] && continue
    if git show-ref --verify --quiet "refs/heads/${wbranch}"; then
      freed+=("$wbranch")
    fi
  done
  if [[ ${#freed[@]} -eq 0 ]]; then
    echo "PASS resolve — no branches freed by this run's worktree removals" >&2
    return 0
  fi

  local b i c idx row name action unique
  for b in "${freed[@]:-}"; do
    [[ -z "$b" ]] && continue
    idx=-1; row=""; i=-1
    for c in "${LOCAL_BRANCH_CANDIDATES[@]:-}"; do
      ((i++)) || true
      [[ -z "$c" ]] && continue
      name=$(awk -F'\t' '{print $1}' <<<"$c")
      if [[ "$name" == "$b" ]]; then idx=$i; row="$c"; break; fi
    done

    if [[ $idx -lt 0 ]]; then
      # Unrowed (the --historical case): classify fresh — post-removal state.
      classify_local "$b" 0
      idx=$(( ${#LOCAL_BRANCH_CANDIDATES[@]} - 1 ))
      row="${LOCAL_BRANCH_CANDIDATES[$idx]}"
    fi

    action=$(awk -F'\t' '{print $6}' <<<"$row")
    if [[ "$action" == "SKIP — active worktree attached" ]]; then
      # Re-evaluate the recorded skip against live post-removal state.
      if is_protected "$b"; then
        echo "SKIPPED resolve $b — protected" >&2; continue
      fi
      if branch_has_worktree "$b"; then
        echo "SKIPPED resolve $b — still attached to a worktree" >&2; continue
      fi
      unique=$(git rev-list --count "${REMOTE_NAME}/${MAIN_BRANCH}..${b}" 2>/dev/null || echo "?")
      if [[ "$unique" != "0" ]]; then
        echo "SKIPPED resolve $b — unique commits exist ($unique)" >&2; continue
      fi
      action="REMOVE"
    fi
    if [[ "$action" != "REMOVE" ]]; then
      echo "SKIPPED resolve $b — $action" >&2; continue
    fi

    # #683 (#2780 Option A') — same deletability-baseline fix as apply_removals:
    # every REMOVE path above proves unique==0 vs origin/main (the fresh classify,
    # or the re-eval's explicit unique=="0" gate), so re-verify is_fully_merged at
    # the delete site and use -D on confirmation (HEAD-relative -d would refuse a
    # merged branch from a behind-HEAD checkout). FORCE=1 keeps -D; the -d fallback
    # holds for any branch not re-provable merged.
    del_flag="-d"
    if [[ "$FORCE" == "1" ]]; then
      del_flag="-D"
    elif is_fully_merged "$b"; then
      del_flag="-D"
    fi
    if git branch $del_flag "$b" 2>&1 | sed 's/^/  git: /' >&2; then
      echo "PASS resolve $b removed (freed by same-run worktree removal)" >&2
      LOCAL_BRANCH_CANDIDATES[$idx]="${row%$'\t'*}"$'\t'"REMOVED"
      ((FREED_RESOLVED++)) || true
    else
      echo "FAIL resolve $b — git branch refused; use --force if intentional" >&2
      LOCAL_BRANCH_CANDIDATES[$idx]="${row%$'\t'*}"$'\t'"FAILED — git branch refused"
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

# ── SKIP ledger (#4913) ──
# A green self-test that SKIPPED half its checks is indistinguishable, in a CI log,
# from a green self-test that ran all of them — which is the very failure class this
# suite exists to catch, one level up. Several checks gate on ambient state that a
# shallow PR checkout does not have (the origin/main remote-tracking ref, lsof, gh),
# so a runner can legitimately reach "self-test: PASS" having exercised a fraction of
# the suite. The ledger does not make those SKIPs go away; it makes a shallow-green
# run DISTINGUISHABLE from a complete-green one, and it is the evidence a future
# hermetic-fixture rewrite would be sized from.
#
# Counting invariant: at most ONE entry can be recorded per check, so the ledger can
# never exceed its denominator. Every recording site either returns immediately or
# returns after its cleanup, and the only two sites that do not end their check
# (selftest_verify_and_prune) are mutually exclusive branches of a single if/else.
SELFTEST_CHECK_COUNT=16
SELFTEST_SKIPS=()

# Records a check-level SKIP and emits the historical message shape VERBATIM:
# `self-test: <label> SKIPPED — <reason>`. Output is unchanged by construction, so
# no existing consumer of these lines can regress.
selftest_skip() {
  local label="$1"; shift
  SELFTEST_SKIPS+=("${label} — $*")
  echo "self-test: ${label} SKIPPED — $*" >&2
}

# Prints the ledger immediately before the terminal verdict.
selftest_skip_ledger() {
  local n="${#SELFTEST_SKIPS[@]}" s
  echo "self-test: SKIP ledger — ${n} of ${SELFTEST_CHECK_COUNT} checks SKIPPED" >&2
  for s in "${SELFTEST_SKIPS[@]:-}"; do
    [[ -z "$s" ]] && continue
    echo "self-test:   SKIPPED ${s}" >&2
  done
}

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
    selftest_skip "apply-path check" "no HEAD commit to branch from"
    return 0
  fi
  tmp="cleanup-selftest/orphan-$$"   # PID-scoped; merged into HEAD so `git branch -d` (non-force) deletes it
  if ! git branch "$tmp" "$base" >/dev/null 2>&1; then
    selftest_skip "apply-path check" "could not create throwaway branch '$tmp'"
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
    selftest_skip "verify-path check" "no HEAD commit to branch from"
  else
    tmp="cleanup-selftest/survivor-$$"
    if ! git branch "$tmp" "$base" >/dev/null 2>&1; then
      selftest_skip "verify-path check" "could not create throwaway branch '$tmp'"
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

# #333 — SELF-guard fixture. End-to-end via inner invocation: re-runs this
# script from INSIDE a throwaway worktree (recursion-safe — inner runs are
# --dry-run, never --self-test) and asserts the SELF action class; then from
# the PRIMARY checkout (read-only dry-run; zero git state change) and asserts
# no SELF row appears (AC4). PID-scoped chore/ branch + --release-close slug
# keep the inner scope away from real branches. Net-zero via git porcelain.
selftest_self_guard() {
  local script_abs slug branch wt base out_inside out_main fail=0
  script_abs="${SCRIPT_DIR}/$(/usr/bin/basename -- "${BASH_SOURCE[0]}")"
  slug="cleanup-selftest-self-$$"
  branch="chore/${slug}"
  wt="${REPO_ROOT}/.claude/worktrees/${slug}"
  base=$(git rev-parse --verify --quiet HEAD 2>/dev/null || true)
  if [[ -z "$base" ]]; then
    selftest_skip "SELF-guard check" "no HEAD commit"; return 0
  fi
  if ! git worktree add -b "$branch" "$wt" "$base" >/dev/null 2>&1; then
    selftest_skip "SELF-guard check" "could not create throwaway worktree"; return 0
  fi

  out_inside=$(cd "$wt" && "$script_abs" --release-close "$slug" --dry-run --json 2>/dev/null) || fail=1
  if [[ "$fail" -eq 1 ]]; then
    echo "self-test: SELF-guard check FAILED — inner dry-run (cwd inside worktree) exited non-zero" >&2
  # `grep -F … | grep -q …` is still the SIGPIPE idiom: converting the WRITER half
  # to a here-string left a live producer feeding a reader that closes on its first
  # match. Measured firing at 2.1 MB. Collapsing the first stage into a command
  # substitution leaves no writer process to signal; the here-string is built only
  # after it has exited. Same tools, same order, same fixed-string semantics.
  elif ! grep -q '"action":"SELF' <<<"$(grep -F "${slug}" <<<"$out_inside" || true)"; then
    echo "self-test: SELF-guard check FAILED — worktree not classified SELF when script cwd is inside it" >&2
    fail=1
  fi

  # AC4 — from the primary checkout the SELF logic is a structural no-op.
  if [[ "$fail" -eq 0 && -n "$MAIN_WORKTREE" && -d "$MAIN_WORKTREE" ]]; then
    out_main=$(cd "$MAIN_WORKTREE" && "$script_abs" --release-close "$slug" --dry-run --json 2>/dev/null) || true
    if grep -q '"action":"SELF' <<<"$out_main"; then
      echo "self-test: SELF-guard check FAILED — SELF row emitted when invoked from the primary (AC4)" >&2
      fail=1
    fi
  fi

  git worktree remove "$wt" >/dev/null 2>&1 || git worktree remove --force "$wt" >/dev/null 2>&1 || true
  git branch -D "$branch" >/dev/null 2>&1 || true
  if [[ "$fail" -ne 0 ]]; then exit 1; fi
  echo "self-test: SELF-guard check PASS — SELF from inside; no SELF from primary" >&2
  return 0
}

# #326 — liveness-gate fixture. Unit canaries on the oracle (own cwd MUST read
# live; a never-created path MUST NOT), then end-to-end: a synthetic live
# holder (background sleep cwd-anchored in a throwaway worktree) must classify
# the tree "SKIP — live session"; after the holder dies, a fresh inner run must
# drop the label (each inner run builds its own map — no memo staleness).
# Holder self-expires (sleep 20) even on abnormal exit. Net-zero via porcelain.
selftest_liveness_gate() {
  resolve_lsof_bin
  if [[ -z "$LSOF_BIN" ]]; then
    selftest_skip "liveness check" "lsof not found (runtime is fail-closed on this host)"
    return 0
  fi
  ensure_liveness_map
  if [[ "$ORACLE_STATE" != "ok" ]]; then
    echo "self-test: liveness check FAILED — oracle unavailable despite lsof at $LSOF_BIN (self-canary missing)" >&2
    exit 1
  fi
  if ! worktree_is_live "$(pwd -P)"; then
    echo "self-test: liveness check FAILED — script's own cwd not detected live (under-detection)" >&2
    exit 1
  fi
  if worktree_is_live "${TMPDIR:-/tmp}/cleanup-selftest-nolive-$$-${RANDOM}"; then
    echo "self-test: liveness check FAILED — never-created path detected live (over-detection)" >&2
    exit 1
  fi

  local script_abs slug branch wt base out holder="" fail=0
  script_abs="${SCRIPT_DIR}/$(/usr/bin/basename -- "${BASH_SOURCE[0]}")"
  slug="cleanup-selftest-live-$$"
  branch="chore/${slug}"
  wt="${REPO_ROOT}/.claude/worktrees/${slug}"
  base=$(git rev-parse --verify --quiet HEAD 2>/dev/null || true)
  if [[ -z "$base" ]] || ! git worktree add -b "$branch" "$wt" "$base" >/dev/null 2>&1; then
    selftest_skip "liveness end-to-end" "could not create throwaway worktree"
    return 0
  fi

  ( cd "$wt" && exec /bin/sleep 20 ) & holder=$!
  /bin/sleep 1   # settle: let the holder reach its cwd

  out=$("$script_abs" --release-close "$slug" --dry-run --json 2>/dev/null) || fail=1
  if [[ "$fail" -eq 1 ]]; then
    echo "self-test: liveness end-to-end FAILED — inner dry-run exited non-zero" >&2
  elif ! grep -q '"action":"SKIP — live session' <<<"$(grep -F "${slug}" <<<"$out" || true)"; then
    echo "self-test: liveness end-to-end FAILED — live-held worktree not labeled live-session" >&2
    fail=1
  fi

  kill "$holder" >/dev/null 2>&1 || true
  wait "$holder" 2>/dev/null || true
  if [[ "$fail" -eq 0 ]]; then
    out=$("$script_abs" --release-close "$slug" --dry-run --json 2>/dev/null) || true
    if grep -q '"action":"SKIP — live session' <<<"$(grep -F "${slug}" <<<"$out" || true)"; then
      echo "self-test: liveness end-to-end FAILED — live label persisted after holder exit" >&2
      fail=1
    fi
  fi

  git worktree remove "$wt" >/dev/null 2>&1 || git worktree remove --force "$wt" >/dev/null 2>&1 || true
  git branch -D "$branch" >/dev/null 2>&1 || true
  if [[ "$fail" -ne 0 ]]; then exit 1; fi
  echo "self-test: liveness check PASS — canaries + synthetic-holder end-to-end" >&2
  return 0
}

# #53 — fixed-point fixture. A clean throwaway worktree on a branch based at
# the merge-base of HEAD and origin/main (v1.11 amendment A-Fixture: an
# ancestor of BOTH baselines — zero unique commits vs origin/main, so
# REMOVE-eligible, AND merged into the invoking HEAD, so `git branch -d`
# deletable from any legal invocation state) goes through a REAL --apply: the
# worktree must be removed AND its freed branch must be removed in the SAME
# run (resolve pass), with the branch row reading REMOVED in the same report.
# Slug-scoped --release-close bounds the inner apply to fixture objects; the
# inner prune is reconciliation-class (existing selftest_verify_and_prune
# precedent).
selftest_fixed_point() {
  if ! git rev-parse --verify --quiet "refs/remotes/${REMOTE_NAME}/${MAIN_BRANCH}" >/dev/null 2>&1; then
    selftest_skip "fixed-point check" "no ${REMOTE_NAME}/${MAIN_BRANCH} ref"
    return 0
  fi
  local script_abs slug branch wt base out fail=0
  base=$(git merge-base HEAD "${REMOTE_NAME}/${MAIN_BRANCH}" 2>/dev/null || true)
  if [[ -z "$base" ]]; then
    selftest_skip "fixed-point check" "no merge-base between HEAD and ${REMOTE_NAME}/${MAIN_BRANCH}"
    return 0
  fi
  script_abs="${SCRIPT_DIR}/$(/usr/bin/basename -- "${BASH_SOURCE[0]}")"
  slug="cleanup-selftest-fp-$$"
  branch="chore/${slug}"
  wt="${REPO_ROOT}/.claude/worktrees/${slug}"
  if ! git worktree add -b "$branch" "$wt" "$base" >/dev/null 2>&1; then
    selftest_skip "fixed-point check" "could not create throwaway worktree"
    return 0
  fi
  if is_protected "$branch"; then
    selftest_skip "fixed-point check" "operator protect-list matches '$branch'"
    git worktree remove --force "$wt" >/dev/null 2>&1 || true
    git branch -D "$branch" >/dev/null 2>&1 || true
    return 0
  fi

  out=$("$script_abs" --release-close "$slug" --apply --json 2>/dev/null) || fail=1
  if [[ "$fail" -eq 1 ]]; then
    echo "self-test: fixed-point check FAILED — inner --apply exited non-zero" >&2
  else
    if git show-ref --verify --quiet "refs/heads/${branch}"; then
      echo "self-test: fixed-point check FAILED — freed branch '$branch' survived the same --apply run (#53 regression)" >&2
      fail=1
    fi
    if [[ -d "$wt" ]]; then
      echo "self-test: fixed-point check FAILED — worktree '$wt' survived --apply" >&2
      fail=1
    fi
    if [[ "$fail" -eq 0 ]] && ! grep -q '"action":"REMOVED"' <<<"$(grep -F "\"name\":\"${branch}\"" <<<"$out" || true)"; then
      echo "self-test: fixed-point check FAILED — branch row not REMOVED in the same-run report" >&2
      fail=1
    fi
  fi

  git worktree remove --force "$wt" >/dev/null 2>&1 || true
  git branch -D "$branch" >/dev/null 2>&1 || true
  if [[ "$fail" -ne 0 ]]; then exit 1; fi
  echo "self-test: fixed-point check PASS — worktree + freed branch removed in one --apply" >&2
  return 0
}

# v2.09 EDIT 7 — version-prefixed release-branch fixture (covers EDIT 1/2/3).
# detect_release_close's bare pattern release/${slug}* cannot match a
# version-prefixed branch release/vX.Y-<slug> (the version token precedes the
# slug). EDIT 1/2/3 add the anchored pattern release/v*-${slug}*. This fixture
# creates a throwaway release/v0.0-<slug> branch at origin/main (0 unique
# commits → REMOVE-eligible, fully-merged so `git branch -D` cleans it) and
# asserts --release-close <slug> ENUMERATES it (its name appears in the JSON
# local_branches). Before the fix the run reported zero local branches — the
# documented Stage-4 defect. Net-zero teardown via git porcelain.
selftest_version_prefix_release() {
  if ! git rev-parse --verify --quiet "refs/remotes/${REMOTE_NAME}/${MAIN_BRANCH}" >/dev/null 2>&1; then
    selftest_skip "version-prefix check" "no ${REMOTE_NAME}/${MAIN_BRANCH} ref"
    return 0
  fi
  local script_abs slug branch out fail=0
  script_abs="${SCRIPT_DIR}/$(/usr/bin/basename -- "${BASH_SOURCE[0]}")"
  slug="cleanup-selftest-vp-$$"
  branch="release/v0.0-${slug}"            # version-prefixed: bare release/${slug}* would MISS this
  if is_protected "$branch"; then
    selftest_skip "version-prefix check" "operator protect-list matches '$branch'"
    return 0
  fi
  if ! git branch "$branch" "${REMOTE_NAME}/${MAIN_BRANCH}" >/dev/null 2>&1; then
    selftest_skip "version-prefix check" "could not create throwaway branch '$branch'"
    return 0
  fi

  out=$("$script_abs" --release-close "$slug" --dry-run --json 2>/dev/null) || fail=1
  if [[ "$fail" -eq 1 ]]; then
    echo "self-test: version-prefix check FAILED — inner --release-close dry-run exited non-zero" >&2
  elif ! grep -F "\"name\":\"${branch}\"" <<<"$out" >/dev/null; then
    echo "self-test: version-prefix check FAILED — version-prefixed branch '$branch' NOT enumerated by --release-close (EDIT 1/2/3 regression)" >&2
    fail=1
  fi

  git branch -D "$branch" >/dev/null 2>&1 || true
  if [[ "$fail" -ne 0 ]]; then exit 1; fi
  echo "self-test: version-prefix check PASS — release/vX.Y-<slug> enumerated by --release-close" >&2
  return 0
}

# #684 — Stage 12/13 chore-branch sweep + anti-over-match.
# The Stage 12/13 chore branches are named chore/vX.Y-stage-<N>-<purpose> (version
# prefix, NO slug), so the pre-#684 chore/v*-${slug}* pattern (version + slug) never
# reached them. #684 derives vX.Y from the slug and adds chore/vX.Y-stage-*. This
# fixture creates, at origin/main (0 unique → REMOVE-eligible, cleans with -D):
#   (1) chore/v0.1-stage-12-<slug>       — MUST be enumerated by --release-close v0.1-<slug>
#   (2) chore/v0.11-stage-12-<slug>      — a DIFFERENT version sharing the v0.1 string;
#                                          MUST NOT be enumerated (no v0.1 vs v0.11 collision)
# and asserts the scope includes (1) and excludes (2). Net-zero teardown.
selftest_stage_branch_release_close() {
  if ! git rev-parse --verify --quiet "refs/remotes/${REMOTE_NAME}/${MAIN_BRANCH}" >/dev/null 2>&1; then
    selftest_skip "stage-branch check" "no ${REMOTE_NAME}/${MAIN_BRANCH} ref"
    return 0
  fi
  local script_abs slug wanted decoy out fail=0
  script_abs="${SCRIPT_DIR}/$(/usr/bin/basename -- "${BASH_SOURCE[0]}")"
  slug="v0.1-cleanup-selftest-stage-$$"        # version-prefixed so version_prefix_of derives v0.1
  wanted="chore/v0.1-stage-12-cleanup-selftest-$$"
  decoy="chore/v0.11-stage-12-cleanup-selftest-$$"
  if is_protected "$wanted" || is_protected "$decoy"; then
    selftest_skip "stage-branch check" "operator protect-list matches a fixture branch"
    return 0
  fi
  if ! git branch "$wanted" "${REMOTE_NAME}/${MAIN_BRANCH}" >/dev/null 2>&1; then
    selftest_skip "stage-branch check" "could not create '$wanted'"
    return 0
  fi
  if ! git branch "$decoy" "${REMOTE_NAME}/${MAIN_BRANCH}" >/dev/null 2>&1; then
    selftest_skip "stage-branch check" "could not create decoy '$decoy'"
    git branch -D "$wanted" >/dev/null 2>&1 || true
    return 0
  fi

  out=$("$script_abs" --release-close "$slug" --dry-run --json 2>/dev/null) || fail=1
  if [[ "$fail" -eq 1 ]]; then
    echo "self-test: stage-branch check FAILED — inner --release-close dry-run exited non-zero" >&2
  else
    if ! grep -F "\"name\":\"${wanted}\"" <<<"$out" >/dev/null; then
      echo "self-test: stage-branch check FAILED — chore/vX.Y-stage-* branch '$wanted' NOT enumerated by --release-close (#684 regression)" >&2
      fail=1
    fi
    if grep -F "\"name\":\"${decoy}\"" <<<"$out" >/dev/null; then
      echo "self-test: stage-branch check FAILED — decoy '$decoy' over-matched (v0.1 vs v0.11 collision)" >&2
      fail=1
    fi
  fi

  git branch -D "$wanted" >/dev/null 2>&1 || true
  git branch -D "$decoy" >/dev/null 2>&1 || true
  if [[ "$fail" -ne 0 ]]; then exit 1; fi
  echo "self-test: stage-branch check PASS — chore/vX.Y-stage-* swept; no vX.Y vs vX.YY over-match" >&2
  return 0
}

# #683 — behind-HEAD apply (FMF-2 production gap). Classification proves merged-ness
# against origin/main, but `git branch -d` is HEAD-relative — from a checkout whose
# HEAD is behind origin/main (the Stage 13 hub-worktree case) it refuses a genuinely-
# merged branch. #683 re-verifies is_fully_merged at BOTH delete sites (apply_removals
# + resolve_freed_branches) and uses -D on confirmation. Two sub-cases:
#   (1) AC-1 END-TO-END (resolve delete site): a merged branch (0 unique vs origin/main)
#       attached to a throwaway worktree at origin/main tip, invoked via
#       --release-close --apply (NO --force) from a SEPARATE detached worktree whose
#       HEAD is behind origin/main. The worktree removal frees the branch; the resolve
#       pass removes it with -D. Without the fix the resolve -d refuses → branch
#       survives with "FAILED — git branch refused" (verified). This is the exact
#       documented FMF-2 scenario. --release-close keeps the scope slug-local (safe /
#       net-zero) — a workspace-wide --historical --apply would delete real branches.
#       (The direct apply_removals delete site is unreachable for a no-PR branch under
#       --release-close require_pr=1 (#2216), so AC-1 exercises the resolve twin.)
#   (2) AC-2 UNIT (apply_removals delete site + fallback): a REAL unmerged branch
#       (≥1 unique vs origin/main) seeded as a REMOVE row and run through apply_removals
#       IN-PROCESS. del_flag must be -d (unique!=0), so `git branch -d` refuses (the
#       branch is not merged into the self-test HEAD) → row FAILED, branch SURVIVES —
#       proving an unmerged branch is never force-deleted without --force (no guard
#       regression). If the fix wrongly forced -D unconditionally the branch would
#       vanish. Net-zero teardown via git porcelain on every exit path.
selftest_behind_head_apply() {
  if ! git rev-parse --verify --quiet "refs/remotes/${REMOTE_NAME}/${MAIN_BRANCH}" >/dev/null 2>&1; then
    selftest_skip "behind-HEAD apply check" "no ${REMOTE_NAME}/${MAIN_BRANCH} ref"
    return 0
  fi
  local script_abs tip base slug merged_branch attach_wt inv_wt out fail=0
  script_abs="${SCRIPT_DIR}/$(/usr/bin/basename -- "${BASH_SOURCE[0]}")"
  tip=$(git rev-parse --verify --quiet "${REMOTE_NAME}/${MAIN_BRANCH}" 2>/dev/null || true)
  base=$(git rev-parse --verify --quiet "${REMOTE_NAME}/${MAIN_BRANCH}~1" 2>/dev/null || true)
  if [[ -z "$tip" || -z "$base" ]]; then
    selftest_skip "behind-HEAD apply check" "${REMOTE_NAME}/${MAIN_BRANCH} has no parent to anchor a behind-HEAD checkout"
    return 0
  fi

  # ── (1) AC-1: resolve-site behind-HEAD removal ──
  slug="v0.0-cleanup-selftest-bh-$$"
  merged_branch="release/v0.0-cleanup-selftest-bh-$$"
  attach_wt="${REPO_ROOT}/.claude/worktrees/cleanup-selftest-bh-$$"
  inv_wt="${REPO_ROOT}/.claude/worktrees/cleanup-selftest-bhinv-$$"
  if is_protected "$merged_branch"; then
    selftest_skip "behind-HEAD apply check" "operator protect-list matches '$merged_branch'"
    return 0
  fi
  if ! git worktree add -b "$merged_branch" "$attach_wt" "$tip" >/dev/null 2>&1; then
    selftest_skip "behind-HEAD apply check" "could not create attached worktree at origin/main"
    return 0
  fi
  if ! git worktree add --detach "$inv_wt" "$base" >/dev/null 2>&1; then
    selftest_skip "behind-HEAD apply check" "could not create behind-HEAD invoking worktree"
    git worktree remove --force "$attach_wt" >/dev/null 2>&1 || true
    git branch -D "$merged_branch" >/dev/null 2>&1 || true
    return 0
  fi

  out=$(cd "$inv_wt" && "$script_abs" --release-close "$slug" --apply --json 2>/dev/null) || fail=1
  if [[ "$fail" -eq 1 ]]; then
    echo "self-test: behind-HEAD apply check FAILED — inner --release-close --apply exited non-zero" >&2
  elif git show-ref --verify --quiet "refs/heads/${merged_branch}"; then
    echo "self-test: behind-HEAD apply check FAILED — merged branch '$merged_branch' survived --apply from a behind-HEAD checkout without --force (#683 / FMF-2 regression)" >&2
    fail=1
  fi
  git worktree remove --force "$attach_wt" >/dev/null 2>&1 || true
  git worktree remove --force "$inv_wt" >/dev/null 2>&1 || true
  git branch -D "$merged_branch" >/dev/null 2>&1 || true

  # ── (2) AC-2: apply_removals must NOT force-delete an unmerged branch ──
  if [[ "$fail" -eq 0 ]]; then
    local ub tmpwt saved_mode="$MODE" action
    ub="chore/cleanup-selftest-bhum-$$"
    tmpwt="${REPO_ROOT}/.claude/worktrees/cleanup-selftest-bhum-$$"
    if is_protected "$ub"; then
      echo "self-test: behind-HEAD apply check — AC-2 sub-case SKIPPED (protect-list matches '$ub')" >&2
    elif ! git worktree add -b "$ub" "$tmpwt" "$tip" >/dev/null 2>&1; then
      echo "self-test: behind-HEAD apply check — AC-2 sub-case SKIPPED (could not create unmerged branch)" >&2
    else
      git -C "$tmpwt" commit --allow-empty -m "cleanup-selftest behind-HEAD AC-2 unmerged fixture $$" >/dev/null 2>&1 || true
      git worktree remove --force "$tmpwt" >/dev/null 2>&1 || true   # detach so it is a plain local branch
      # Seed a REMOVE row with a non-zero unique so del_flag must fall back to -d.
      LOCAL_BRANCH_CANDIDATES=("${ub}"$'\t'"5"$'\t'"selftest"$'\t'""$'\t'"(none)"$'\t'"REMOVE")
      REMOTE_BRANCH_CANDIDATES=()
      WORKTREE_CANDIDATES=()
      MODE="apply"
      apply_removals >/dev/null 2>&1 || true
      MODE="$saved_mode"
      action=$(awk -F'\t' '{print $6}' <<<"${LOCAL_BRANCH_CANDIDATES[0]}")
      if git show-ref --verify --quiet "refs/heads/${ub}"; then
        case "$action" in
          FAILED*) : ;;   # -d refused the unmerged branch — the guard held
          *) echo "self-test: behind-HEAD apply check FAILED — unmerged branch survived but row action='$action' (expected FAILED)" >&2; fail=1 ;;
        esac
      else
        echo "self-test: behind-HEAD apply check FAILED — unmerged branch '$ub' was force-deleted by apply_removals without --force (AC-2 guard regression)" >&2
        fail=1
      fi
      git branch -D "$ub" >/dev/null 2>&1 || true
      LOCAL_BRANCH_CANDIDATES=(); REMOTE_BRANCH_CANDIDATES=(); WORKTREE_CANDIDATES=()
    fi
  fi

  if [[ "$fail" -ne 0 ]]; then exit 1; fi
  echo "self-test: behind-HEAD apply check PASS — merged branch removed from behind-HEAD checkout (no --force); unmerged branch stays guarded (-d fallback)" >&2
  return 0
}

# #670 — local-branch dedup under --all. detect_spawn_task (claude/* branches) and
# detect_historical (all merged-unattached branches) both classify a merged claude/*
# branch, so before #670 it produced two LOCAL_BRANCH_CANDIDATES rows (report +
# counter double-count). This fixture creates a merged claude/* branch (0 unique →
# eligible under both passes, unattached so detect_historical enumerates it), runs
# --all --dry-run, and asserts the branch name appears EXACTLY ONCE in local_branches.
# Without the guard the count is 2 (verified). Net-zero teardown via git porcelain.
selftest_dedup_local_branches() {
  if ! git rev-parse --verify --quiet "refs/remotes/${REMOTE_NAME}/${MAIN_BRANCH}" >/dev/null 2>&1; then
    selftest_skip "dedup check" "no ${REMOTE_NAME}/${MAIN_BRANCH} ref"
    return 0
  fi
  local script_abs branch out count fail=0
  script_abs="${SCRIPT_DIR}/$(/usr/bin/basename -- "${BASH_SOURCE[0]}")"
  branch="claude/cleanup-selftest-dedup-$$"     # claude/* so detect_spawn_task rows it; merged+unattached so detect_historical also rows it
  if is_protected "$branch"; then
    selftest_skip "dedup check" "operator protect-list matches '$branch'"
    return 0
  fi
  if ! git branch "$branch" "${REMOTE_NAME}/${MAIN_BRANCH}" >/dev/null 2>&1; then
    selftest_skip "dedup check" "could not create throwaway branch '$branch'"
    return 0
  fi

  out=$("$script_abs" --all --dry-run --json 2>/dev/null) || fail=1
  if [[ "$fail" -eq 1 ]]; then
    echo "self-test: dedup check FAILED — inner --all dry-run exited non-zero" >&2
  else
    count=$(grep -oF "\"name\":\"${branch}\"" <<<"$out" | wc -l | tr -d ' ')
    if [[ "$count" != "1" ]]; then
      echo "self-test: dedup check FAILED — merged claude/* branch appears ${count}x in --all local_branches (expected 1; #670 regression)" >&2
      fail=1
    fi
  fi

  git branch -D "$branch" >/dev/null 2>&1 || true
  if [[ "$fail" -ne 0 ]]; then exit 1; fi
  echo "self-test: dedup check PASS — one local-branch row per branch under --all (spawn-task + historical overlap deduped)" >&2
  return 0
}

# #655 — PR-map identity. The prefetch map must return byte-identical (pr_n, pr_s)
# to the per-branch path for the same branch (the correctness precondition for
# replacing ~2 gh calls per branch with one run-scoped list). This fixture samples
# real local branches and, for each, compares pr_lookup in the built-map state
# against pr_lookup in a FORCED-degraded state (the per-branch fallback). They must
# agree. Also asserts the map's own state is honestly self-reported (built → ok or
# degraded, never a silent claim). In-process; saves/restores the PR_MAP_* globals.
# Offline / gh-unreachable degrades both paths to the same per-branch calls, so the
# equality still holds (and pr_s="?" transient state is absent in map mode — a strict
# improvement). Net-zero (read-only; no branch/worktree state touched).
selftest_pr_map_identity() {
  local saved_built="$PR_MAP_BUILT" saved_state="$PR_MAP_STATE"
  local saved_entries_n=${#PR_MAP_ENTRIES[@]}
  # Snapshot the entries array so we can restore it (bash-3.2 copy).
  local saved_entries=(); local e
  for e in "${PR_MAP_ENTRIES[@]:-}"; do [[ -n "$e" ]] && saved_entries+=("$e"); done

  local b sample=() n=0 fail=0
  # Sample up to 8 real local branches (deterministic: first-listed). Read-only.
  for b in $(git for-each-ref 'refs/heads/' --format='%(refname:short)' 2>/dev/null); do
    sample+=("$b"); ((n++)) || true
    [[ "$n" -ge 8 ]] && break
  done
  if [[ "$n" -eq 0 ]]; then
    selftest_skip "pr-map identity check" "no local branches to sample"
    return 0
  fi

  # Build the map once, record its honestly-reported state.
  PR_MAP_BUILT=0; PR_MAP_ENTRIES=(); PR_MAP_STATE="degraded"
  build_pr_map >/dev/null 2>&1 || true
  case "$PR_MAP_STATE" in
    ok|degraded) : ;;
    *) echo "self-test: pr-map identity check FAILED — PR_MAP_STATE='$PR_MAP_STATE' (must be ok|degraded)" >&2; fail=1 ;;
  esac

  local map_n map_s deg_n deg_s
  for b in "${sample[@]}"; do
    # Map-mode lookup (whatever state build produced).
    pr_lookup "$b"; map_n="$PR_LOOKUP_N"; map_s="$PR_LOOKUP_S"
    # Forced-degraded lookup (the verbatim per-branch fallback).
    local hold_state="$PR_MAP_STATE"; PR_MAP_STATE="degraded"
    pr_lookup "$b"; deg_n="$PR_LOOKUP_N"; deg_s="$PR_LOOKUP_S"
    PR_MAP_STATE="$hold_state"
    if [[ "$map_n" != "$deg_n" || "$map_s" != "$deg_s" ]]; then
      echo "self-test: pr-map identity check FAILED — branch '$b': map=($map_n,$map_s) != per-branch=($deg_n,$deg_s)" >&2
      fail=1
    fi
  done

  # Restore globals for the rest of the suite.
  PR_MAP_BUILT="$saved_built"; PR_MAP_STATE="$saved_state"
  PR_MAP_ENTRIES=()
  for e in "${saved_entries[@]:-}"; do [[ -n "$e" ]] && PR_MAP_ENTRIES+=("$e"); done

  if [[ "$fail" -ne 0 ]]; then exit 1; fi
  echo "self-test: pr-map identity check PASS — map-path (pr_n,pr_s) identical to per-branch over ${n} sampled branch(es) [map state: ${saved_state}→built]" >&2
  return 0
}

# #669 — --help protective-guarantee assertion. The end-anchored usage() window must
# always surface the SAFETY (--force / SELF) and META (--self-test) lines. This fixture
# runs the real --help and asserts each token is present, so a future window/header edit
# that drops a protective line fails the suite instead of silently regressing (the #1678
# defect class). Also asserts the Hook-compatibility divider stays OUTSIDE --help (the
# window's end-anchor holds). Pure read of --help output; net-zero.
selftest_help_surface() {
  local script_abs help fail=0 tok
  script_abs="${SCRIPT_DIR}/$(/usr/bin/basename -- "${BASH_SOURCE[0]}")"
  help=$("$script_abs" --help 2>/dev/null) || {
    echo "self-test: help-surface check FAILED — --help exited non-zero" >&2
    exit 1
  }
  for tok in "--force" "SELF" "--self-test"; do
    if ! grep -qF -- "$tok" <<<"$help"; then
      echo "self-test: help-surface check FAILED — --help omits the protective token '$tok' (#669 / #1678 regression)" >&2
      fail=1
    fi
  done
  # The end-anchor must stop BEFORE the Hook-compatibility divider (proves the window
  # is bounded by structure, not runaway to EOF).
  if grep -qF "Hook compatibility" <<<"$help"; then
    echo "self-test: help-surface check FAILED — --help leaked past the 'Hook compatibility' divider (end-anchor broken)" >&2
    fail=1
  fi
  if [[ "$fail" -ne 0 ]]; then exit 1; fi
  echo "self-test: help-surface check PASS — --help surfaces --force / SELF / --self-test; bounded at the Hook-compatibility divider" >&2
  return 0
}

# v2.09 EDIT 7 — agent-* detached-worktree fixtures (covers EDIT 4 + EDIT 5).
# EDIT 4 adds a path-basename arm (*:::agent-*) to detect_spawn_task so the
# Agent-tool worktree pool (mostly detached → no branch for the claude/* arm to
# match) is swept. EDIT 5 adds the detached-unmerged merge gate in
# classify_worktree. Two throwaway DETACHED worktrees whose dir basename is
# agent-* (so the path-keyed arm reaches them):
#   (1) at origin/main exactly (0 ahead, clean, not-live) → REMOVE — proves the
#       agent-* path arm classifies a sweepable tree.
#   (2) at origin/main + 1 throwaway commit (1 ahead, clean, not-live) →
#       "SKIP — detached, unmerged commits (1)" — proves EDIT 5 closes the
#       headless-tree data-loss class with the distinct counted reason.
# --spawn-task is workspace-wide; the fixtures assert only on their own paths.
# Net-zero teardown via `git worktree remove --force`.
selftest_agent_detached_sweep() {
  if ! git rev-parse --verify --quiet "refs/remotes/${REMOTE_NAME}/${MAIN_BRANCH}" >/dev/null 2>&1; then
    selftest_skip "agent-* sweep check" "no ${REMOTE_NAME}/${MAIN_BRANCH} ref"
    return 0
  fi
  local script_abs base wt_rm wt_skip out fail=0
  script_abs="${SCRIPT_DIR}/$(/usr/bin/basename -- "${BASH_SOURCE[0]}")"
  base=$(git rev-parse --verify --quiet "${REMOTE_NAME}/${MAIN_BRANCH}" 2>/dev/null || true)
  if [[ -z "$base" ]]; then
    selftest_skip "agent-* sweep check" "could not resolve ${REMOTE_NAME}/${MAIN_BRANCH}"
    return 0
  fi
  # Dir basename MUST be agent-* so the path-keyed *:::agent-* arm reaches it.
  wt_rm="${REPO_ROOT}/.claude/worktrees/agent-selftest-rm-$$"
  wt_skip="${REPO_ROOT}/.claude/worktrees/agent-selftest-um-$$"

  # (1) detached at origin/main (0 ahead) — REMOVE-eligible
  if ! git worktree add --detach "$wt_rm" "$base" >/dev/null 2>&1; then
    selftest_skip "agent-* sweep check" "could not create detached worktree (1)"
    return 0
  fi
  # (2) detached at origin/main + 1 throwaway commit (1 ahead) — EDIT 5 SKIP
  if ! git worktree add --detach "$wt_skip" "$base" >/dev/null 2>&1; then
    selftest_skip "agent-* sweep check" "could not create detached worktree (2)"
    git worktree remove --force "$wt_rm" >/dev/null 2>&1 || true
    return 0
  fi
  if ! git -C "$wt_skip" commit --allow-empty -m "cleanup-selftest detached-unmerged fixture $$" >/dev/null 2>&1; then
    selftest_skip "agent-* sweep check" "could not add throwaway commit to detached worktree (2)"
    git worktree remove --force "$wt_rm" >/dev/null 2>&1 || true
    git worktree remove --force "$wt_skip" >/dev/null 2>&1 || true
    return 0
  fi

  out=$("$script_abs" --spawn-task --dry-run --json 2>/dev/null) || fail=1
  if [[ "$fail" -eq 1 ]]; then
    echo "self-test: agent-* sweep check FAILED — inner --spawn-task dry-run exited non-zero" >&2
  else
    # (1) the clean+merged+not-live detached agent-* tree must be reached AND REMOVE.
    if ! grep -q '"action":"REMOVE"' <<<"$(grep -F "\"path\":\"${wt_rm}\"" <<<"$out" || true)"; then
      echo "self-test: agent-* sweep check FAILED — detached agent-* tree not classified REMOVE (EDIT 4 path arm regression)" >&2
      fail=1
    fi
    # (2) the detached tree with an unmerged commit must SKIP with the counted reason.
    if ! grep -q '"action":"SKIP — detached, unmerged commits (1)"' <<<"$(grep -F "\"path\":\"${wt_skip}\"" <<<"$out" || true)"; then
      echo "self-test: agent-* sweep check FAILED — detached-unmerged agent-* tree not SKIPPED with counted reason (EDIT 5 regression)" >&2
      fail=1
    fi
  fi

  git worktree remove --force "$wt_rm" >/dev/null 2>&1 || true
  git worktree remove --force "$wt_skip" >/dev/null 2>&1 || true
  if [[ "$fail" -ne 0 ]]; then exit 1; fi
  echo "self-test: agent-* sweep check PASS — detached agent-* tree REMOVE; detached-unmerged tree SKIP (N)" >&2
  return 0
}

# Regression guard for the exit-141-at-scale defect (SIGPIPE on a worktree-list
# generator whose consumer closes the read end early, fatal under set -o pipefail).
# Two layers:
#   (1) STRUCTURAL: scan our own source for a live worktree-list generator piped
#       into an early-closing consumer (grep -q, or awk containing exit). After
#       the snapshot+here-string refactor there must be none. Lines that mention
#       the search text for legitimate reasons carry a WTPIPEGUARD tag and are
#       exempt so the guard never flags itself.
#   (2) FUNCTIONAL: the replacement idiom extracts the right branch from an
#       800-entry synthetic list under pipefail and exits 0.
selftest_no_live_worktree_pipes() {
  local src hits
  src="${SCRIPT_DIR}/$(/usr/bin/basename -- "${BASH_SOURCE[0]}")"
  hits=$(grep -nE 'git worktree list --porcelain[^|]*\|[^|]*grep -q' "$src" | grep -v 'WTPIPEGUARD' || true)   # WTPIPEGUARD
  if [[ -n "$hits" ]]; then
    echo "self-test: worktree-pipe guard FAILED — live worktree-list-into-grep-q pipe reintroduced:" >&2
    printf '%s\n' "$hits" >&2; exit 1
  fi
  hits=$(grep -nE 'git worktree list --porcelain[^|]*\|[^|]*awk' "$src" | grep 'exit' | grep -v 'WTPIPEGUARD' || true)   # WTPIPEGUARD
  if [[ -n "$hits" ]]; then
    echo "self-test: worktree-pipe guard FAILED — live worktree-list-into-awk-exit pipe reintroduced:" >&2
    printf '%s\n' "$hits" >&2; exit 1
  fi
  local big i out rc=0
  big="$(for ((i=0; i<800; i++)); do printf 'worktree /tmp/wt-%s\nHEAD %040d\nbranch refs/heads/scale/%s\n\n' "$i" 0 "$i"; done)"
  ( set -o pipefail
    out=$(awk -v p="/tmp/wt-7" 'BEGIN{found=0} /^worktree /{if (found) exit; if ($2==p) found=1; next} found && /^branch /{print $2; exit}' <<<"$big")
    [[ "$out" == "refs/heads/scale/7" ]] || exit 7
    grep -q "^branch refs/heads/scale/7$" <<<"$big" || exit 8
  ) || rc=$?
  if [[ "$rc" -ne 0 ]]; then
    echo "self-test: worktree-pipe guard FAILED — snapshot+here-string idiom errored at scale (rc=$rc)" >&2
    exit 1
  fi
  echo "self-test: worktree-pipe guard PASS — no live early-closing worktree-list pipes; idiom survives 800-entry list" >&2
  return 0
}

# Orphan-tag fixtures (T-1..T-11). HERMETIC: never touches the real origin, and issues
# no host-policy query. The real-reap / verify-after cases (T-3/T-7) run
# `git push --delete` and `git ls-remote` against a PID-scoped FIXTURE BARE REMOTE (a
# local `git init --bare`), with REMOTE_NAME temporarily repointed at it — so the reap
# primitive is observed FIRING against a throwaway, not assumed and not aimed at origin.
# Classification/guard/write-back cases run in-process on injected state + a throwaway
# ledger (LEDGER_PATH override). Net-zero: the fixture remote + its tags + the throwaway
# ledgers are removed on every exit path.
#
# Why T-1..T-9 are unaffected by the host tag-protection preflight, and why that is a
# property rather than an exemption: the fixture remote is a bare DIRECTORY, so
# tag_protection_state() resolves `unprotected` on its first arm — the remote is not a
# policy-bearing host, therefore no ruleset can exist on it — and returns without any
# network call. These tests exercise the unprotected code path on its merits. T-10/T-11
# cover the two new branches by stubbing the preflight, because a hermetic self-test
# must not depend on a live host.
selftest_orphan_tag_reap() {
  local base saved_remote="$REMOTE_NAME" saved_ledger="$LEDGER_PATH" saved_log="$RELEASE_LOG_PATH"
  local saved_force="$FORCE" saved_aband="$ABANDONED_ARG" saved_scope="$SCOPE" saved_mode="$MODE"
  # Fixtures live in a PID-scoped dir under the system temp — NOT under the repo (a
  # linked worktree's `.git` is a gitdir-pointer FILE, not a directory) and NOT origin.
  local fix_base="${TMPDIR:-/tmp}/cleanup-selftest-$$"
  local fix_remote_dir="${fix_base}/reap-remote" fix_ledger fix_log
  local fail=0 tag="cleanup-selftest-rv-$$" slug="cleanup-selftest-slug-$$" action
  base=$(git rev-parse --verify --quiet HEAD 2>/dev/null || true)
  if [[ -z "$base" ]]; then
    selftest_skip "orphan-tag reap check" "no HEAD commit"
    return 0
  fi
  if ! mkdir -p "$fix_base" >/dev/null 2>&1; then
    selftest_skip "orphan-tag reap check" "could not create fixture dir '$fix_base'"
    return 0
  fi

  # ── Throwaway ledger (a single tag-orphaned row the reader must authorize) ──
  fix_ledger="${fix_base}/ledger.md"
  fix_log="${fix_base}/release-log.md"
  {
    echo '| slug | abandoned_version | final_version | claimed_versions | abandoned_tag_pushed | merge_sha | collided_with | resolved_at_stage | disposition | residual_labels | reaped_ref | date |'
    echo '|---|---|---|---|---|---|---|---|---|---|---|---|'
    echo "| ${slug} | ${tag} | v9.99 | ${tag} → v9.99 | true | ${base} | — | S12 | tag-orphaned | branch retains label | — | 2026-06-21 |"
  } > "$fix_ledger"
  # Throwaway RELEASE_LOG: one canonical row whose Tag is a DIFFERENT fixture tag, used
  # by the canonical-version guard (T-5). Header-keyed so column order is irrelevant.
  {
    echo '| Version | Milestone | Issues | Merge SHA | Tag | State | Date |'
    echo '|---|---|---|---|---|---|---|'
    echo "| v8.88 | canon-${slug} | #1 | ${base} | cleanup-selftest-canon-$$ | VERIFIED | 2026-06-21 |"
  } > "$fix_log"

  # ── T-1: authority gate — NO authority (no ledger row, no --abandoned) = no reap ──
  LEDGER_PATH="/nonexistent-$$"; RELEASE_LOG_PATH="$fix_log"; ABANDONED_ARG=""; TAG_CANDIDATES=(); ABANDONED_SET=()
  detect_orphan_tags >/dev/null 2>&1 || true
  if [[ "${#TAG_CANDIDATES[@]}" -ne 0 ]]; then
    echo "self-test: orphan-tag reap check FAILED — T-1: a tag was classified with NO abandonment authority" >&2; fail=1
  fi

  # ── T-2: declared-abandoned via ledger → REMOVE in dry-run (mutates nothing) ──
  # (Probe origin via a fixture remote with the tag present so on-origin != 0.)
  # Lightweight tag via plumbing (git update-ref) — config-immune (the operator may set
  # tag.gpgsign=true, which makes `git tag <name> <sha>` demand an annotation message).
  if git init --bare -q "$fix_remote_dir" >/dev/null 2>&1 \
     && git push -q "$fix_remote_dir" "HEAD:refs/heads/selftest-base-$$" >/dev/null 2>&1 \
     && git update-ref "refs/tags/${tag}" "$base" >/dev/null 2>&1 \
     && git push -q "$fix_remote_dir" "refs/tags/${tag}" >/dev/null 2>&1; then
    REMOTE_NAME="$fix_remote_dir"; LEDGER_PATH="$fix_ledger"; RELEASE_LOG_PATH="$fix_log"; ABANDONED_ARG=""
    TAG_CANDIDATES=(); ABANDONED_SET=()
    detect_orphan_tags >/dev/null 2>&1 || true
    action=$(awk -F'\t' '{print $5}' <<<"${TAG_CANDIDATES[0]:-}")
    if [[ "$action" != "REMOVE" ]]; then
      echo "self-test: orphan-tag reap check FAILED — T-2: ledger-declared on-origin tag not classified REMOVE (got '$action')" >&2; fail=1
    fi
    # dry-run must mutate nothing — the tag is still on the fixture remote.
    if ! grep -q "refs/tags/${tag}$" <<<"$(git ls-remote --tags "$fix_remote_dir" "refs/tags/${tag}" 2>/dev/null || true)"; then
      echo "self-test: orphan-tag reap check FAILED — T-2: dry-run deleted the tag (must not mutate)" >&2; fail=1
    fi

    # ── T-4: double-opt-in — --apply WITHOUT --force → SKIP, not deleted ──
    FORCE=0; reap_orphan_tags >/dev/null 2>&1 || true
    action=$(awk -F'\t' '{print $5}' <<<"${TAG_CANDIDATES[0]:-}")
    if [[ "$action" != "SKIP — needs --force" ]]; then
      echo "self-test: orphan-tag reap check FAILED — T-4: --apply without --force did not SKIP (got '$action')" >&2; fail=1
    fi
    if ! grep -q "refs/tags/${tag}$" <<<"$(git ls-remote --tags "$fix_remote_dir" "refs/tags/${tag}" 2>/dev/null || true)"; then
      echo "self-test: orphan-tag reap check FAILED — T-4: tag deleted without --force (double opt-in breached)" >&2; fail=1
    fi

    # ── T-3: REAP actually deletes (reproduction-and-observe) — --apply --force ──
    # Re-classify (the prior reap rewrote the row to SKIP), then reap with force.
    LEDGER_PATH="$fix_ledger"; TAG_CANDIDATES=(); ABANDONED_SET=(); detect_orphan_tags >/dev/null 2>&1 || true
    FORCE=1; reap_orphan_tags >/dev/null 2>&1 || true
    action=$(awk -F'\t' '{print $5}' <<<"${TAG_CANDIDATES[0]:-}")
    if [[ "$action" != "REMOVED" ]]; then
      echo "self-test: orphan-tag reap check FAILED — T-3: reap did not report REMOVED (got '$action')" >&2; fail=1
    fi
    # OBSERVE the absence on the fixture remote (the load-bearing assertion).
    if grep -q "refs/tags/${tag}$" <<<"$(git ls-remote --tags "$fix_remote_dir" "refs/tags/${tag}" 2>/dev/null || true)"; then
      echo "self-test: orphan-tag reap check FAILED — T-3: tag still present on fixture remote after reap" >&2; fail=1
    fi
    # Local tag must be gone too (two-surface).
    if git show-ref --tags --verify --quiet "refs/tags/${tag}"; then
      echo "self-test: orphan-tag reap check FAILED — T-3: local tag survived the reap" >&2; fail=1
    fi
    # T-9 (write-back): the throwaway ledger row transitioned to tag-reaped + reaped_ref set,
    # EXACTLY one row, ONLY the two cells (assert disposition flipped and reaped_ref non-empty,
    # and row/column counts unchanged).
    if ! grep -q '| tag-reaped |' "$fix_ledger"; then
      echo "self-test: orphan-tag reap check FAILED — T-9: ledger disposition not transitioned to tag-reaped" >&2; fail=1
    fi
    if grep -q '| tag-orphaned |' "$fix_ledger"; then
      echo "self-test: orphan-tag reap check FAILED — T-9: ledger still carries tag-orphaned (in-place transition failed)" >&2; fail=1
    fi
    if [[ "$(grep -c '^|' "$fix_ledger")" -ne 3 ]]; then
      echo "self-test: orphan-tag reap check FAILED — T-9: ledger row count changed (append-only invariant breached)" >&2; fail=1
    fi

    # ── T-6: idempotency — re-classify the now-absent tag → SKIP already-absent ──
    LEDGER_PATH="$fix_ledger"; TAG_CANDIDATES=(); ABANDONED_SET=(); detect_orphan_tags >/dev/null 2>&1 || true
    # The ledger row is now tag-reaped (not tag-orphaned) → no authority → no candidate.
    if [[ "${#TAG_CANDIDATES[@]}" -ne 0 ]]; then
      echo "self-test: orphan-tag reap check FAILED — T-6: a reaped (tag-reaped) row was re-authorized for reap" >&2; fail=1
    fi
    # Idempotency via explicit --abandoned on the already-absent tag → SKIP already-absent.
    ABANDONED_ARG="$tag"; LEDGER_PATH="/nonexistent-$$"; TAG_CANDIDATES=(); ABANDONED_SET=(); detect_orphan_tags >/dev/null 2>&1 || true
    action=$(awk -F'\t' '{print $5}' <<<"${TAG_CANDIDATES[0]:-}")
    if [[ "$action" != "SKIP — already absent from origin (nothing to reap)" ]]; then
      echo "self-test: orphan-tag reap check FAILED — T-6: already-absent tag not SKIPPED idempotently (got '$action')" >&2; fail=1
    fi
    ABANDONED_ARG=""

    # ── T-7: verify-after never silently claims success ──
    # Push the tag back, inject a TAG_CANDIDATE pre-marked REMOVED, run verify — it must
    # reclassify (the tag survived on the fixture remote).
    git update-ref "refs/tags/${tag}" "$base" >/dev/null 2>&1 || true
    git push -q "$fix_remote_dir" "refs/tags/${tag}" >/dev/null 2>&1 || true
    TAG_CANDIDATES=("${tag}	${slug}	v9.99	${base}	REMOVED")
    verify_tag_apply >/dev/null 2>&1 || true
    action=$(awk -F'\t' '{print $5}' <<<"${TAG_CANDIDATES[0]:-}")
    if [[ "$action" != "SKIPPED — survived apply (still on origin)" ]]; then
      echo "self-test: orphan-tag reap check FAILED — T-7: verify-after did not reclassify a surviving tag (got '$action')" >&2; fail=1
    fi
    git tag -d "$tag" >/dev/null 2>&1 || true

    # ── T-10 / T-11: host tag-protection preflight ──
    # The real preflight needs a live policy-bearing host, which a hermetic self-test
    # must not depend on — so it is STUBBED per case and restored afterwards. What is
    # observed is the reap loop's behaviour given each preflight answer, which is the
    # part that can regress. Fresh tag + fresh throwaway ledger, because the T-1..T-9
    # fixtures are already spent (their row is tag-reaped and carries no authority).
    local tag2="cleanup-selftest-prot-$$" slug2="cleanup-selftest-protslug-$$"
    local fix_ledger2="${fix_base}/ledger-protection.md" saved_tps
    saved_tps=$(declare -f tag_protection_state)
    _write_protection_fixture_ledger() {
      {
        echo '| slug | abandoned_version | final_version | claimed_versions | abandoned_tag_pushed | merge_sha | collided_with | resolved_at_stage | disposition | residual_labels | reaped_ref | date |'
        echo '|---|---|---|---|---|---|---|---|---|---|---|---|'
        echo "| ${slug2} | ${tag2} | v9.99 | ${tag2} → v9.99 | true | ${base} | — | S12 | tag-orphaned | branch retains label | — | 2026-06-21 |"
      } > "$fix_ledger2"
    }
    if git update-ref "refs/tags/${tag2}" "$base" >/dev/null 2>&1 \
       && git push -q "$fix_remote_dir" "refs/tags/${tag2}" >/dev/null 2>&1; then

      # ── T-10: PROTECTED → RETAINED, no push issued, row → tag-retained, no --force ──
      _write_protection_fixture_ledger
      tag_protection_state() { TAG_PROTECTION_STATE="protected"; TAG_PROTECTION_RULESET="selftest-protect"; TAG_PROTECTION_REASON=""; }
      REMOTE_NAME="$fix_remote_dir"; LEDGER_PATH="$fix_ledger2"; RELEASE_LOG_PATH="$fix_log"; ABANDONED_ARG=""
      TAG_CANDIDATES=(); ABANDONED_SET=()
      detect_orphan_tags >/dev/null 2>&1 || true
      action=$(awk -F'\t' '{print $5}' <<<"${TAG_CANDIDATES[0]:-}")
      if [[ "$action" != RETAINED* ]]; then
        echo "self-test: orphan-tag reap check FAILED — T-10: protected tag not classified RETAINED (got '$action')" >&2; fail=1
      fi
      # --force deliberately OFF: the retained path must need no double opt-in, because
      # it attempts nothing destructive.
      FORCE=0; reap_orphan_tags >/dev/null 2>&1 || true
      if ! grep -q "refs/tags/${tag2}$" <<<"$(git ls-remote --tags "$fix_remote_dir" "refs/tags/${tag2}" 2>/dev/null || true)"; then
        echo "self-test: orphan-tag reap check FAILED — T-10: a protected tag was DELETED (no push may be issued)" >&2; fail=1
      fi
      if ! grep -q '| tag-retained |' "$fix_ledger2"; then
        echo "self-test: orphan-tag reap check FAILED — T-10: ledger row not transitioned to tag-retained" >&2; fail=1
      fi
      if grep -q '| tag-orphaned |' "$fix_ledger2"; then
        echo "self-test: orphan-tag reap check FAILED — T-10: ledger still carries tag-orphaned (in-place transition failed)" >&2; fail=1
      fi
      # reaped_ref must stay unset — nothing was reaped, so the back-reference is empty.
      if ! grep -qE '\| tag-retained \|[^|]*\| — \|' "$fix_ledger2"; then
        echo "self-test: orphan-tag reap check FAILED — T-10: reaped_ref was written on a retain (must stay unset)" >&2; fail=1
      fi
      # Re-classification must find no authority — idempotency by construction.
      TAG_CANDIDATES=(); ABANDONED_SET=(); detect_orphan_tags >/dev/null 2>&1 || true
      if [[ "${#TAG_CANDIDATES[@]}" -ne 0 ]]; then
        echo "self-test: orphan-tag reap check FAILED — T-10: a retained (tag-retained) row was re-authorized" >&2; fail=1
      fi

      # ── T-11: UNDETERMINED fails CLOSED — nothing attempted even WITH --force ──
      # The load-bearing assertion of the preflight's fail direction: an unreadable host
      # policy must never fall through to the deletion path, and must name its reason
      # rather than emitting the reversibility grade of an operation it cannot assess.
      _write_protection_fixture_ledger
      tag_protection_state() { TAG_PROTECTION_STATE="undetermined"; TAG_PROTECTION_RULESET=""; TAG_PROTECTION_REASON="selftest: host policy unreadable"; }
      LEDGER_PATH="$fix_ledger2"; TAG_CANDIDATES=(); ABANDONED_SET=()
      detect_orphan_tags >/dev/null 2>&1 || true
      action=$(awk -F'\t' '{print $5}' <<<"${TAG_CANDIDATES[0]:-}")
      # The reason must be present AND non-empty. Asserting only the surrounding shape
      # would pass on "undetermined ()" — an empty reason reads as a populated
      # classification and is not one. That exact defect shipped once, from a
      # command-substitution subshell stranding the reason global, and was caught by a
      # live run rather than by this test; the assertion is tightened so the reverse
      # holds next time.
      case "$action" in
        "SKIP — tag protection undetermined (selftest: host policy unreadable); nothing attempted") : ;;
        *) echo "self-test: orphan-tag reap check FAILED — T-11: undetermined host not classified with its named reason (got '$action')" >&2; fail=1 ;;
      esac
      FORCE=1; reap_orphan_tags >/dev/null 2>&1 || true
      if ! grep -q "refs/tags/${tag2}$" <<<"$(git ls-remote --tags "$fix_remote_dir" "refs/tags/${tag2}" 2>/dev/null || true)"; then
        echo "self-test: orphan-tag reap check FAILED — T-11: undetermined host FAILED OPEN — the tag was deleted under --force" >&2; fail=1
      fi
      if ! grep -q '| tag-orphaned |' "$fix_ledger2"; then
        echo "self-test: orphan-tag reap check FAILED — T-11: undetermined host transitioned a ledger row (must transition nothing)" >&2; fail=1
      fi

      eval "$saved_tps"
      git push -q --delete "$fix_remote_dir" "refs/tags/${tag2}" >/dev/null 2>&1 || true
      git tag -d "$tag2" >/dev/null 2>&1 || true
    else
      eval "$saved_tps"
      echo "self-test: orphan-tag reap check SKIPPED (T-10/T-11) — could not stage the protection fixture tag" >&2
    fi
    unset -f _write_protection_fixture_ledger
  else
    echo "self-test: orphan-tag reap check SKIPPED (T-2/T-3/T-4/T-6/T-7) — could not set up fixture remote" >&2
  fi

  # ── T-5: canonical-version guard — a tag that IS a live RELEASE_LOG Tag is never reaped ──
  REMOTE_NAME="$saved_remote"   # canonical check is corpus-only; remote irrelevant
  ABANDONED_ARG="cleanup-selftest-canon-$$"; LEDGER_PATH="/nonexistent-$$"; RELEASE_LOG_PATH="$fix_log"
  TAG_CANDIDATES=(); ABANDONED_SET=(); detect_orphan_tags >/dev/null 2>&1 || true
  action=$(awk -F'\t' '{print $5}' <<<"${TAG_CANDIDATES[0]:-}")
  if [[ "$action" != "SKIP — canonical version of a live RELEASE_LOG row (not an orphan)" ]]; then
    echo "self-test: orphan-tag reap check FAILED — T-5: canonical-guard did not refuse a live-Tag value (got '$action')" >&2; fail=1
  fi

  # ── T-8: stale-version-row detection (report-only; never edits prose) ──
  # The throwaway ledger names abandoned=${tag}, slug=${slug}, final=v9.99. Seed the
  # ABANDONING RELEASE'S OWN RELEASE_LOG row (Milestone == ${slug}) still carrying the
  # abandoned version in Version → it must surface in STALE_VERSION_ROWS (keyed on
  # (Milestone-slug, Version)), prose untouched. Also seed a SIBLING row (different
  # Milestone) carrying the same version → it must NOT be flagged (false-positive guard).
  {
    echo '| Version | Milestone | Issues | Merge SHA | Tag | State | Date |'
    echo '|---|---|---|---|---|---|---|'
    echo "| ${tag} | ${slug} | #2 | ${base} | sometag | VERIFIED | 2026-06-21 |"
    echo "| ${tag} | sibling-${slug} | #3 | ${base} | ${tag} | VERIFIED | 2026-06-21 |"
  } > "$fix_log"
  LEDGER_PATH="$fix_ledger"; RELEASE_LOG_PATH="$fix_log"; ABANDONED_ARG=""; TAG_CANDIDATES=(); ABANDONED_SET=(); STALE_VERSION_ROWS=()
  detect_orphan_tags >/dev/null 2>&1 || true
  # sigpipe-idiom: allow — array expansion; `<<<"${A[@]}"` space-joins every element onto ONE line, defeating this `^`-anchored per-row match (U2).
  if ! printf '%s\n' "${STALE_VERSION_ROWS[@]:-}" | grep -q "^${slug}	${tag}	"; then
    echo "self-test: orphan-tag reap check FAILED — T-8: abandoning-release stale row not flagged for R-3 roll-forward" >&2; fail=1
  fi
  # False-positive guard: the sibling row (Milestone=sibling-${slug}) must NOT be flagged.
  # sigpipe-idiom: allow — array expansion; same U2 reason as the row-match above.
  if printf '%s\n' "${STALE_VERSION_ROWS[@]:-}" | grep -q "^sibling-${slug}	"; then
    echo "self-test: orphan-tag reap check FAILED — T-8: sibling canonical row wrongly flagged as stale (false positive)" >&2; fail=1
  fi
  if ! grep -q "| ${tag} | ${slug} |" "$fix_log"; then
    echo "self-test: orphan-tag reap check FAILED — T-8: stale-version detector mutated the RELEASE_LOG (must be report-only)" >&2; fail=1
  fi

  # ── Teardown (bounded; PID-scoped fixture only — never the real origin) ──
  REMOTE_NAME="$saved_remote"; LEDGER_PATH="$saved_ledger"; RELEASE_LOG_PATH="$saved_log"
  FORCE="$saved_force"; ABANDONED_ARG="$saved_aband"; SCOPE="$saved_scope"; MODE="$saved_mode"
  TAG_CANDIDATES=(); ABANDONED_SET=(); STALE_VERSION_ROWS=()
  git tag -d "$tag" >/dev/null 2>&1 || true
  # Bounded fixture cleanup — PID-scoped single dir under the system temp; mirrors
  # deploy.sh's guarded bounded-rm. The case-guard refuses any path not matching the
  # exact `<tmp>/cleanup-selftest-<pid>` shape (defense against an unset/odd fix_base).
  case "$fix_base" in
    "${TMPDIR:-/tmp}/cleanup-selftest-$$") /bin/rm -rf "$fix_base" 2>/dev/null || true ;;
  esac

  if [[ "$fail" -ne 0 ]]; then exit 1; fi
  echo "self-test: orphan-tag reap check PASS — T-1 authority gate / T-2 dry-run / T-3 real-reap-observed / T-4 double-opt-in / T-5 canonical-guard / T-6 idempotency / T-7 verify-after / T-8 stale-row report-only / T-9 ledger write-back / T-10 protected-host retain / T-11 undetermined-host fail-closed" >&2
  return 0
}

# #2216 — squash-merge MERGED-PR rescue on the --release-close path.
# The production defect: a squash-merged release branch has source commits that
# are NOT ancestors of main, so the ancestry SKIP ("unique commits exist (N)")
# fires and --release-close reaps nothing even though the PR is MERGED.
#
# A live MERGED PR is UN-FORGEABLE in-harness (has_merged_pr / gh pr view against
# a synthetic branch always return not-merged; there is no gh stub seam), so this
# fixture proves the fix at TWO levels (#2779 E3 / scope-lock D5):
#   (1) SEAM-LEVEL (AC-1): a throwaway branch with a REAL unique commit (ancestry
#       SKIP would fire) is run through classify_local IN-PROCESS in a subshell
#       where `gh` is shadowed to report a MERGED PR. Assert require_pr=1 yields
#       REMOVE (the rescue overrode the ancestry SKIP) AND require_pr=0 yields the
#       ancestry SKIP (no rescue off the release-close path) — the precedence.
#   (2) BLACK-BOX (AC-2/R2): the SAME unique-commit branch, with NO PR (real gh),
#       run through `--release-close <slug> --dry-run` stays SKIP — proving the
#       rescue never over-removes a genuinely-unmerged, un-PR'd branch.
# The "real shipped release reports non-zero removable" AC is a Stage-8 manual
# integration check, not a fixture. Net-zero teardown via git porcelain.
selftest_release_close_merged_pr() {
  if ! git rev-parse --verify --quiet "refs/remotes/${REMOTE_NAME}/${MAIN_BRANCH}" >/dev/null 2>&1; then
    selftest_skip "merged-PR rescue check" "no ${REMOTE_NAME}/${MAIN_BRANCH} ref"
    return 0
  fi
  local script_abs base slug branch wt out fail=0
  script_abs="${SCRIPT_DIR}/$(/usr/bin/basename -- "${BASH_SOURCE[0]}")"
  base=$(git rev-parse --verify --quiet "${REMOTE_NAME}/${MAIN_BRANCH}" 2>/dev/null || true)
  if [[ -z "$base" ]]; then
    selftest_skip "merged-PR rescue check" "could not resolve ${REMOTE_NAME}/${MAIN_BRANCH}"
    return 0
  fi
  slug="cleanup-selftest-mpr-$$"
  branch="release/v0.0-${slug}"            # version-prefixed so detect_release_close enumerates it
  if is_protected "$branch"; then
    selftest_skip "merged-PR rescue check" "operator protect-list matches '$branch'"
    return 0
  fi
  # A throwaway worktree at origin/main + 1 unique commit: source commit is NOT an
  # ancestor of main (the squash-merge shape), so the ancestry SKIP would fire.
  wt="${REPO_ROOT}/.claude/worktrees/${slug}"
  if ! git worktree add -b "$branch" "$wt" "$base" >/dev/null 2>&1; then
    selftest_skip "merged-PR rescue check" "could not create throwaway worktree"
    return 0
  fi
  if ! git -C "$wt" commit --allow-empty -m "cleanup-selftest merged-PR-rescue fixture $$" >/dev/null 2>&1; then
    selftest_skip "merged-PR rescue check" "could not add unique commit"
    git worktree remove --force "$wt" >/dev/null 2>&1 || true
    git branch -D "$branch" >/dev/null 2>&1 || true
    return 0
  fi

  # ── (1) SEAM-LEVEL: classify_local in a subshell with a shadowed MERGED PR ──
  # Shell-function `gh` shadows the pinned-PATH binary (functions resolve first),
  # so the classifier reads pr_s="MERGED" for this branch. The subshell isolates
  # the LOCAL_BRANCH_CANDIDATES mutation and the shadow from the rest of the suite.
  # branch_has_worktree would SKIP-active-worktree this branch, so the seam case
  # runs against the branch name only after the worktree is detached below is NOT
  # possible (we still need the tree for the black-box run); instead the seam case
  # uses a SEPARATE detached-free branch pointer at the same unique commit.
  local seam_branch="chore/v0.0-${slug}-seam"
  local unique_tip
  unique_tip=$(git -C "$wt" rev-parse HEAD 2>/dev/null || true)
  if [[ -n "$unique_tip" ]] && git branch "$seam_branch" "$unique_tip" >/dev/null 2>&1; then
    # Shadow gh so the classifier reads a MERGED PR for this branch. The two
    # arms key on the sub-command ($2): `pr list` → a PR number; `pr view` →
    # MERGED. Shell functions resolve ahead of the pinned-PATH binary.
    _selftest_gh_merged() {
      case "${2:-}" in
        list) echo "9990" ;;
        view) echo "MERGED" ;;
      esac
    }
    local seam_remove seam_skip
    seam_remove=$(
      gh() { _selftest_gh_merged "$@"; }
      GH_BIN=gh; GH_BIN_RESOLVED=1   # route "$GH_BIN" through the gh() shadow (#2790)
      # Force the degraded per-branch path so pr_lookup exercises the shadowed gh
      # (a globally-built ok map has no synthetic-seam entry → map-miss → (none),
      # which would defeat the shadow now that gh is reachable). BUILT=1 skips a
      # real rebuild; the reset is subshell-local (#2790).
      PR_MAP_BUILT=1; PR_MAP_STATE=degraded; PR_MAP_ENTRIES=()
      LOCAL_BRANCH_CANDIDATES=()
      classify_local "$seam_branch" 1
      awk -F'\t' '{print $6}' <<<"${LOCAL_BRANCH_CANDIDATES[0]}"
    )
    seam_skip=$(
      gh() { _selftest_gh_merged "$@"; }
      GH_BIN=gh; GH_BIN_RESOLVED=1   # route "$GH_BIN" through the gh() shadow (#2790)
      # Force degraded per-branch path (see the require_pr=1 arm above) (#2790).
      PR_MAP_BUILT=1; PR_MAP_STATE=degraded; PR_MAP_ENTRIES=()
      LOCAL_BRANCH_CANDIDATES=()
      classify_local "$seam_branch" 0
      awk -F'\t' '{print $6}' <<<"${LOCAL_BRANCH_CANDIDATES[0]}"
    )
    if [[ "$seam_remove" != "REMOVE" ]]; then
      echo "self-test: merged-PR rescue check FAILED — require_pr=1 + MERGED PR did not rescue the unique-commit branch (got '$seam_remove', want REMOVE)" >&2
      fail=1
    fi
    case "$seam_skip" in
      "SKIP — unique commits exist"*) : ;;
      *) echo "self-test: merged-PR rescue check FAILED — require_pr=0 must NOT rescue (got '$seam_skip', want ancestry SKIP)" >&2; fail=1 ;;
    esac
    git branch -D "$seam_branch" >/dev/null 2>&1 || true
  else
    echo "self-test: merged-PR rescue check — seam sub-case SKIPPED (could not create seam branch)" >&2
  fi

  # ── (2) BLACK-BOX: real gh, no PR → unique-commit branch stays SKIP (no over-removal) ──
  # Detach the worktree's branch so classify_local sees a plain local branch (not
  # active-worktree-attached) yet the unique commit persists on the branch ref.
  out=$("$script_abs" --release-close "$slug" --dry-run --json 2>/dev/null) || fail=1
  if [[ "$fail" -eq 0 ]]; then
    # The branch is worktree-attached, so its row reads "SKIP — active worktree
    # attached"; the load-bearing black-box assertion is that it is NOT REMOVE
    # (no false rescue for a branch with no MERGED PR).
    if grep -q '"action":"REMOVE"' <<<"$(grep -F "\"name\":\"${branch}\"" <<<"$out" || true)"; then
      echo "self-test: merged-PR rescue check FAILED — unique-commit branch with NO PR classified REMOVE under --release-close (over-removal / R2 regression)" >&2
      fail=1
    fi
  else
    echo "self-test: merged-PR rescue check FAILED — inner --release-close dry-run exited non-zero" >&2
  fi

  git worktree remove --force "$wt" >/dev/null 2>&1 || true
  git branch -D "$branch" >/dev/null 2>&1 || true
  if [[ "$fail" -ne 0 ]]; then exit 1; fi
  echo "self-test: merged-PR rescue check PASS — MERGED PR rescues squash-merged branch (require_pr=1); ancestry SKIP holds otherwise; no-PR branch never over-removed" >&2
  return 0
}

# #2790 — gh reachability under the pinned PATH. The shadow-based fixtures
# (selftest_release_close_merged_pr) redefine `gh` as a function and so
# STRUCTURALLY cannot catch binary-unreachability: a function shadow resolves
# regardless of PATH. This fixture exercises the REAL resolution path — it
# asserts resolve_gh_bin finds an executable absolute-path binary AND that a
# live `"$GH_BIN" pr list` runs without the /usr/bin:/bin pin blocking it
# (the exact production symptom). SKIP-guarded (stays green) when no gh binary
# exists at all — offline / CI hosts — so it never turns those runs red.
selftest_gh_bin_resolves() {
  local saved_bin="$GH_BIN" saved_res="$GH_BIN_RESOLVED"
  GH_BIN=""; GH_BIN_RESOLVED=0
  resolve_gh_bin
  if [[ -z "$GH_BIN" ]]; then
    selftest_skip "gh-reachability check" "no gh binary at /opt/homebrew/bin/gh, /usr/local/bin/gh, or /usr/bin/gh (offline/CI)"
    GH_BIN="$saved_bin"; GH_BIN_RESOLVED="$saved_res"
    return 0
  fi
  local fail=0
  if [[ ! -x "$GH_BIN" ]]; then
    echo "self-test: gh-reachability check FAILED — resolve_gh_bin set GH_BIN='$GH_BIN' but it is not executable" >&2
    fail=1
  fi
  # ── Hermetic arm (UNCONDITIONAL) ──
  # The #2790 subject is binary REACHABILITY under the pinned PATH=/usr/bin:/bin —
  # a bare `gh` would exit 127. `--version` asserts exactly that production symptom
  # with no network, no credential and no repo slug. This is the arm that must hold
  # on every host, and it is the reason the fixture no longer needs an auth token.
  if [[ "$fail" -eq 0 ]] && ! "$GH_BIN" --version >/dev/null 2>&1; then
    echo "self-test: gh-reachability check FAILED — \"\$GH_BIN\" --version did not run under the pinned PATH" >&2
    fail=1
  fi
  # ── Credential-bearing arm (CONDITIONALLY ARMED) ──
  # Auth, network reachability and REPO_SLUG validity are NOT the #2790 subject —
  # they are incidental couplings that made this fixture non-hermetic and turned an
  # unauthenticated runner red. Armed only when a credential is present AND
  # REPO_SLUG actually carries owner/name: on CI the slug falls through to the bare
  # literal "pmo-platform" (no operator.toml), so the query fails EVEN WITH a token.
  # When unarmed the arm is REPORTED SKIPPED with its reason — never silently dropped.
  local live="RAN" live_why=""
  if [[ "$fail" -eq 0 ]]; then
    if [[ -z "${GH_TOKEN:-}${GITHUB_TOKEN:-}" ]] && ! "$GH_BIN" auth status >/dev/null 2>&1; then
      live="SKIPPED"; live_why="no credential (GH_TOKEN/GITHUB_TOKEN unset and \`gh auth status\` non-zero)"
    elif [[ ! "$REPO_SLUG" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]; then
      live="SKIPPED"; live_why="REPO_SLUG='$REPO_SLUG' is not owner/name"
    elif ! "$GH_BIN" pr list --repo "$REPO_SLUG" --limit 1 --json number >/dev/null 2>&1; then
      echo "self-test: gh-reachability check FAILED — live \"\$GH_BIN\" pr list did not resolve (auth or reachability)" >&2
      fail=1
    fi
  fi
  GH_BIN="$saved_bin"; GH_BIN_RESOLVED="$saved_res"
  if [[ "$fail" -ne 0 ]]; then exit 1; fi
  if [[ "$live" == "RAN" ]]; then
    echo "self-test: gh-reachability check PASS — resolve_gh_bin found an executable gh by absolute path; \"\$GH_BIN\" --version ran under the pinned PATH; live \"\$GH_BIN\" pr list resolved (#2790)" >&2
  else
    echo "self-test: gh-reachability check PASS — resolve_gh_bin found an executable gh by absolute path; \"\$GH_BIN\" --version ran under the pinned PATH; live pr-list arm SKIPPED — ${live_why} (#2790)" >&2
  fi
  return 0
}

self_test() {
  echo "self-test: running detection logic against current workspace (read-only)..." >&2
  workspace_boundary_check
  load_protect_list
  compute_self_worktree
  detect_spawn_task
  echo "self-test: detection completed — ${#LOCAL_BRANCH_CANDIDATES[@]} local / ${#REMOTE_BRANCH_CANDIDATES[@]} remote / ${#WORKTREE_CANDIDATES[@]} worktree candidates" >&2
  echo "self-test: exercising apply path against an isolated throwaway branch..." >&2
  selftest_apply_path
  echo "self-test: exercising post-apply verify + stale-ref prune paths..." >&2
  selftest_verify_and_prune
  echo "self-test: exercising SELF-guard via inner invocation (inside worktree + from primary)..." >&2
  selftest_self_guard
  echo "self-test: exercising liveness gate (oracle canaries + synthetic live holder)..." >&2
  selftest_liveness_gate
  echo "self-test: exercising fixed-point apply (worktree + freed branch in one run)..." >&2
  selftest_fixed_point
  echo "self-test: exercising version-prefixed release matcher (release/vX.Y-<slug>; EDIT 1/2/3)..." >&2
  selftest_version_prefix_release
  echo "self-test: exercising squash-merge MERGED-PR rescue on --release-close (#2216)..." >&2
  selftest_release_close_merged_pr
  echo "self-test: exercising chore/vX.Y-stage-* sweep + anti-over-match (#684)..." >&2
  selftest_stage_branch_release_close
  echo "self-test: exercising behind-HEAD apply removes merged branch without --force (#683)..." >&2
  selftest_behind_head_apply
  echo "self-test: exercising local-branch dedup under --all (spawn-task + historical overlap) (#670)..." >&2
  selftest_dedup_local_branches
  echo "self-test: exercising PR-map prefetch identity vs per-branch (#655)..." >&2
  selftest_pr_map_identity
  echo "self-test: exercising gh reachability under the pinned PATH (real resolve + live query) (#2790)..." >&2
  selftest_gh_bin_resolves
  echo "self-test: exercising agent-* detached sweep + detached-unmerged merge gate (EDIT 4/5)..." >&2
  selftest_agent_detached_sweep
  echo "self-test: exercising worktree-list pipe guard (no live early-closing pipes; idiom survives scale)..." >&2
  selftest_no_live_worktree_pipes
  echo "self-test: exercising orphan-tag reap (authority gate, real-reap-observed, double-opt-in, canonical-guard, verify-after, ledger write-back)..." >&2
  selftest_orphan_tag_reap
  echo "self-test: exercising --help protective-guarantee surface (--force / SELF / --self-test) (#669)..." >&2
  selftest_help_surface
  selftest_skip_ledger
  echo "self-test: PASS" >&2
  exit 0
}

# ─── Arg parsing ─────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release-close) SCOPE="release-close"; MILESTONE_SLUG="${2:-}"; shift 2 ;;
    --spawn-task)    SCOPE="spawn-task"; shift ;;
    --historical)    SCOPE="historical"; shift ;;
    --reap-orphan-tags) SCOPE="reap-orphan-tags"; shift ;;
    --abandoned)     ABANDONED_ARG="${2:-}"; shift 2 ;;
    --assume-unprotected) ASSUME_UNPROTECTED=1; shift ;;
    --ledger)        LEDGER_PATH="${2:-}"; shift 2 ;;
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
[[ -n "$ABANDONED_ARG" && "$SCOPE" != "reap-orphan-tags" ]] && die "--abandoned requires --reap-orphan-tags"
[[ "$ASSUME_UNPROTECTED" == "1" && "$SCOPE" != "reap-orphan-tags" ]] && die "--assume-unprotected requires --reap-orphan-tags"

# ─── Main ────────────────────────────────────────────────────────────────────

# ORDERING IS DELIBERATE — do NOT "fix" this to match the sibling tools.
# audit-epic-rollup-close.sh and automated-closeout.sh both dispatch --self-test
# BEFORE their boundary check, exempting the fixture run. Their justification is
# that the self-test is hermetic — "no network, no workspace, no gh". That premise
# is FALSE here: this self-test creates 9 worktrees and runs `git branch -D`,
# `git worktree remove --force` and `git push --delete` against a fixture remote.
# It is the one self-test in the corpus that performs real destructive git
# operations, i.e. precisely the case the guard exists for. Reachability on a CI
# runner is restored by WIDENING the boundary (arm 2 of workspace_boundary_check),
# never by exempting the fixture. Recorded in release/ADRs/ADR-142.
workspace_boundary_check
[[ "$SELF_TEST" == "1" ]] && self_test
load_protect_list
compute_self_worktree

case "$SCOPE" in
  all)
    detect_spawn_task
    detect_historical
    ;;
  release-close) detect_release_close "$MILESTONE_SLUG" ;;
  spawn-task)    detect_spawn_task ;;
  historical)    detect_historical ;;
  reap-orphan-tags) detect_orphan_tags ;;
esac

# Apply BEFORE emitting, FOUR phases in order: (1) apply_removals rewrites candidate
# action fields to REMOVED / FAILED so the emitted report reflects ACTUAL execution,
# not just the planned action; (2) resolve_freed_branches runs ONE bounded
# re-evaluation pass removing local branches freed by this run's worktree removals
# (fixed point in a single invocation — #53); (3) verify_apply re-checks REMOVED
# targets (incl. resolve-pass removals) and reclassifies any survivor to SKIPPED
# (AC4); (4) prune_remote_tracking reconciles the local remote-tracking view (AC3).
# All four run in --apply only and return 0 so emit still runs after them under
# set -e. Plain `if` (not `[[ … ]] && …`) keeps control flow obvious and immune to
# set -e short-circuit semantics.
#
# The branch/worktree four-phase fixed point is GUARDED OFF the reap scope: the tag
# reap is a separate accumulator (TAG_CANDIDATES) with no interaction with the
# branch/worktree fixed point, so it runs as a SCOPE-GATED SIBLING (below) with its own
# tag-verify — NOT nested in this block. This keeps the default --all / --release-close
# close path reap-free (a reap needs ledger authority + double opt-in).
if [[ "$MODE" == "apply" && "$SCOPE" != "reap-orphan-tags" ]]; then
  apply_removals
  resolve_freed_branches
  verify_apply
  prune_remote_tracking
fi

# Reap sibling — scope-gated, with its own verify (AC4). Only the --reap-orphan-tags
# scope ever reaps; the reap requires --apply (and, inside reap_orphan_tags, --force).
if [[ "$MODE" == "apply" && "$SCOPE" == "reap-orphan-tags" ]]; then
  reap_orphan_tags
  verify_tag_apply
fi

case "$OUTPUT" in
  markdown) emit_markdown ;;
  json)     emit_json ;;
esac

exit 0
