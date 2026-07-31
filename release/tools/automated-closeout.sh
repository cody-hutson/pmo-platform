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
#   3  read_state         RELEASE_LOG row + visible-H4 Deployment Log + Milestone state + release-PR MERGE_SHA (#1682)
#   4  detect_open_issues auto-close anomaly enumeration (#38: --exclude-issue + Stage-13-subtask title-regex auto-exclude)
#   5  create_chore_branch chore/v<X.Y>-stage-13-corpus-update
#   6  transition_release_log  DEPLOYED → VERIFIED
#   6.5 inject_outcome_field  **Outcome:** field on the visible-H4 Deployment Log block (#37; default SUCCESS, --outcome overrides)
#   7  append_release_index    new row in RELEASE_INDEX.md
#   8  append_release_digest   new entry under v<MAJOR>.* H2 in RELEASE_DIGEST.md
#   8.5 append_reversions   append re-version row(s) to RELEASE_REVERSIONS.md (#1679; N/A on the common no-collision path)
#   9  scaffold_release_notes  frontmatter + section H2 placeholders (SCAFFOLD-ONLY)
#   9.2 lint_release_notes  §3.2 note-content close gate — a finding for THIS version BLOCKS close
#   9.5 append_changelog   prepend ## [vX.Y] section to CHANGELOG.md (Layer-1 dual-write Surface 2)
#   9.55 assert_derived_surfaces  version-scoped scaffold-residue assert on the CHANGELOG + DIGEST entries for THIS version (read-only)
#   9.6 bump_version       write .version=$VERSION (versioned releases; SKIP version-less)
#   9.9 ledger_guard       pre-commit §220 I1/I2 read-modify-write guard on the 4 append-only ledgers (#1680)
#   9.95 rebuild_skill_packages  rebuild changed skills' .skill packages into the chore commit (content-sidecar-gated; N/A when no skill source changed)
#   10 commit_chore_pr     git add + git commit (parser-clean message)
#   11 create_chore_pr     gh pr create with safe-phrasing body throughout
#   12 await_merge_chore_pr poll mergeStateStatus (#1705: CI-realistic budget, default 300s; --no-merge skips; BLOCKED/UNSTABLE keep-polling)
#   12.5 reparse_ledgers   post-merge structural re-parse of the ledgers (#1680; detective-only)
#   13 post_close_milestone gh api -X PATCH state=closed (#2919: DEFERS under --no-merge)
#   14 manual_close_release_issues operator-authorized D-1 with structured comment (#2919: DEFERS under --no-merge)
#   15 run_verification + post_gate_passage_proof per the gate-passage-proof template
#   15.5 publish_github_release gh release create | edit (Layer-1 dual-write Surface 1; #2919: DEFERS under --no-merge, as does 15.6 check_release_body_drift)
#   15.6 check_release_body_drift  post-emit §5.1 published-body drift assert (gated genuine drift BLOCKS; #2919: DEFERS under --no-merge)
#   16 invoke_orphan_cleanup cleanup-orphan-state.sh --release-close <slug> --dry-run
#   16.5 pattern_scan      optional synthesize-release-learnings.sh --mode pattern-detect (only with --with-pattern-scan)
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
#     --outcome <ENUM>         **Outcome:** value on the Deployment Log block (#37):
#                              SUCCESS (default) / PARTIAL / ROLLBACK / DEFERRED
#     --outcome-rationale <t>  One-line rationale; REQUIRED when --outcome != SUCCESS
#     --exclude-issue <N>      Filter issue #N out of the auto-close loop (#38;
#                              repeatable) — pass the Stage-13 sub-task # so it
#                              cannot self-close mid-run
#     --close-comment <N>:<t>  Per-issue close-comment override (#38; repeatable)
#     --merge-timeout <N>      Chore-PR await-merge poll budget, seconds (#1705;
#                              default 300 — CI-realistic, not the old 30s cap)
#     --no-merge               Create the chore PR but do NOT poll/merge it (#1705);
#                              exit cleanly leaving the PR for the operator. The
#                              post-merge-dependent phases — post_close_milestone,
#                              manual_close_release_issues, publish_github_release,
#                              check_release_body_drift — DEFER under this flag
#                              (#2919); re-run --apply after the chore PR merges to
#                              complete milestone close + Release publish.
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
RELEASE_REVERSIONS="$REPO_ROOT/release/releases/RELEASE_REVERSIONS.md"
RELEASE_NOTES_DIR="$REPO_ROOT/release/releases/notes"
RELEASE_PLANS_DIR="$REPO_ROOT/release/releases/plans"
CLEANUP_TOOL="$SCRIPT_DIR/cleanup-orphan-state.sh"
COMPUTE_CYCLE_TIME="$SCRIPT_DIR/compute-cycle-time.sh"
SYNTHESIZE_LEARNINGS="$SCRIPT_DIR/synthesize-release-learnings.sh"
# Scaffold-residue token source (AC1 single-source seam). The token set has exactly
# ONE definition — SCAFFOLD_RESIDUE_TOKENS in lint_release_corpus.py — and the shell
# anchors read it from there via --print-scaffold-tokens. Retyping the literals in
# bash would open a cross-language drift seam: the scaffold heredoc could gain a
# placeholder the python anchor catches and the shell anchors silently miss.
# Captured HERE at load time from the script-derived $REPO_ROOT, so a self-test that
# sandboxes REPO_ROOT still reads the REAL token set — exercising the shipped tokens
# is the entire value of the round-trip test.
LINT_RELEASE_CORPUS="$REPO_ROOT/core/deploy/tools/lint_release_corpus.py"
# Body-source-of-record drift check (release-notes-standard.md §5.1). The SINGLE
# source of the published-body-vs-stripped-note equality logic; phase 15.6 below
# invokes it as the post-emit assert. Genuine drift BLOCKS the close (cutoff-gated,
# sharing deploy.sh Check 47's cutoff so the two surfaces cannot disagree); the
# capability-absent and artifact-missing exits stay non-blocking.
DRIFT_CHECK_TOOL="$SCRIPT_DIR/check-release-body-drift.sh"
# Shared with deploy.sh Check 47 — see phase 15.6 for why the close-path block is
# cutoff-gated at all. Same complete-token default; __none__ is the opt-out.
DRIFT_CHECK_CUTOFF="${RELEASE_BODY_DRIFT_CHECK_CUTOFF:-v3.78}"
# NOTE (#667 Finding 6): phase_append_release_index no longer invokes the
# deterministic INDEX generator (core/deploy/tools/generate_release_index.py).
# The full-regenerate path could re-sort/reorder unrelated rows (the churn root),
# and the generator's own within-date-sort + find_artifact bugs are separable
# (they also affect deploy.sh Check 23). The phase is now a pure single-row
# insert in the live 6-column schema; the generator stays tracked separately and
# is intentionally NOT called from this tool.

# ─── Defaults ────────────────────────────────────────────────────────────────

PR_NUMBER=""
VERSION=""
MILESTONE=""
MODE="dry-run"           # dry-run | apply
OUTPUT="markdown"        # markdown | json
WITH_PATTERN_SCAN=0
SELF_TEST=0
CHECK_PATHS=0            # offline corpus-path resolution probe (CI smoke gate)
REVERSION_SPEC=""        # --reversion "<final>|<claimed-seq>|<merge_sha>|<collided>|<stage>|<residual>"
                         # set ONLY when this release re-versioned mid-pipeline;
                         # empty => phase_append_reversions records N/A (common path)
OUTCOME=""               # --outcome <ENUM> (#37); empty => default SUCCESS at inject time
                         # (per decision-outcome-tracking.md §4 autonomous path).
                         # Closed enum: SUCCESS / PARTIAL / ROLLBACK / DEFERRED.
OUTCOME_RATIONALE=""     # --outcome-rationale "<text>"; REQUIRED when OUTCOME != SUCCESS
                         # (§5 conditional-required), OPTIONAL for SUCCESS.
EXCLUDE_ISSUES=()        # --exclude-issue <N> (#38; repeatable). Issues filtered out
                         # of the auto-close-anomaly close loop — primarily the
                         # Stage-13 orchestration sub-task (passed by number so it
                         # cannot self-close mid-run, erasing its own Tier-0 evidence).
CLOSE_COMMENTS=()        # --close-comment <N>:"<text>" (#38; repeatable). Per-issue
                         # close-comment override for a Tier-0 disposition so it gets
                         # the correct comment, not the generic auto-close-anomaly text.
MERGE_TIMEOUT=300        # --merge-timeout <N> (#1705). Await-merge poll budget in
                         # seconds. Default 300s (CI-realistic: required CI on this
                         # repo runs ~2-3min); the prior 30s cap was a detection-
                         # pending budget, not a CI-completion budget.
NO_MERGE=0               # --no-merge (#1705). Create the chore PR but do NOT poll/merge
                         # it — exit cleanly leaving the PR for the operator to merge.
CHORE_PR_SKIPPED=0       # set by phase_create_chore_pr's zero-commit guard so
                         # phase_await_merge_chore_pr SKIPs gracefully (un-strands the
                         # terminal phases on the idempotent already-up-to-date path).
MERGE_POLL_STEP=10       # await-merge poll interval (seconds). Not a CLI flag —
                         # internal; the self-test overrides it to keep hermetic
                         # runs fast.

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
MERGE_SHA=""              # release-PR merge commit (#1682). Captured ONCE at
                         # read-state from the RELEASE PR (not the chore PR — the
                         # release content merged via the release PR, and the
                         # signed tag is cut at that SHA per stage-12 Phase B3).
                         # phase_publish_github_release binds the Release --target
                         # to it and asserts the tag points at it.

# .skill packages rebuilt by phase_rebuild_skill_packages (Phase 9.95): one
# "packages/<skill>.skill" + "packages/<skill>.skill.sha256" pair per skill whose
# source (or an injected canonical) changed in the release diff. Populated there,
# consumed by phase_commit_chore_pr's files=() staging array + its post-commit
# staging-completeness assertion. Empty on a release that touches no skill source.
REBUILT_PACKAGES=()

# Phase outcomes (PASS / FAIL / SKIPPED / N/A / DRY-RUN / MANUAL)
# Bash 3.2 (macOS default) lacks associative arrays — use parallel indexed arrays
# keyed by phase name. Lookup is O(n) but phase count is small (<20).
PHASE_NAMES=()
PHASE_RESULTS=()
PHASE_DETAILS=()

# ─── Helpers ─────────────────────────────────────────────────────────────────

usage() {
  /usr/bin/sed -n '2,83p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
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

# Version-grammar SSOT (#1676) sourced for validate_version (#1801) — set-e-safe:
# pure functions, empty positional so its --self-test stays inert. A pre-#1676
# checkout (lib absent) degrades validate_version to a minimal non-empty vX.Y check.
if [[ -f "$SCRIPT_DIR/version-grammar.sh" ]]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/version-grammar.sh" ""
  _ACO_HAVE_GRAMMAR=1
else
  _ACO_HAVE_GRAMMAR=0
fi

# Validate the current release version against the canonical grammar SSOT (#1676:
# ^v[0-9]+\.[0-9]+(\.[0-9]+)?$ — vX.Y or vX.Y.Z hotfix; suffix forms REJECTED).
# #1801: was a permissive local regex accepting vX.Ysuffix — that form never shipped
# on the reachable lineage, and validate_version only ever gates the current $VERSION
# (always canonical), so the laxness was unneeded. Source, don't copy the regex (the
# SSOT consumer contract: a copied-inline regex is a divergence defect).
validate_version() {
  local v="$1"
  if [[ "${_ACO_HAVE_GRAMMAR:-0}" == "1" ]]; then
    version_canonical "$v"
  else
    [[ -n "$v" && "$v" == v*.* ]]   # SSOT absent (pre-#1676) — minimal degrade
  fi
}

# TRUE when this release is version-less — $VERSION is not a canonical vX.Y[.Z]
# (the milestone slug stands in for the version). Corpus convention (#2048):
#   INDEX  Version cell -> "<slug> (version-less)"
#   DIGEST H3           -> "### <slug> (<date>, version-less) — <headline>"
#   notes link/path     -> notes/_unversioned/<slug>_RELEASE_NOTES.md
#   .version + CHANGELOG-> SKIP (nothing to stamp; no `## [vX.Y]` key to write)
# Mirrors the phase_bump_version SKIP predicate so all four Stage-13 emits agree
# on what "version-less" means. Previously only bump_version branched on it; the
# INDEX/DIGEST/CHANGELOG emits did not, so a version-less close produced entries
# that diverged from the corpus convention (#2048 residual).
is_version_less() { ! validate_version "$VERSION"; }

# The notes path/link for this release — version-less notes live under
# notes/_unversioned/ (per the shipped corpus), versioned notes sit flat.
notes_rel_path() {
  if is_version_less; then
    printf 'notes/_unversioned/%s_RELEASE_NOTES.md' "$VERSION"
  else
    printf 'notes/%s_RELEASE_NOTES.md' "$VERSION"
  fi
}

# The INDEX Version-cell label: version-less rows carry the "(version-less)" marker.
index_version_cell() {
  if is_version_less; then printf '%s (version-less)' "$VERSION"; else printf '%s' "$VERSION"; fi
}

# Scaffold-residue token set (AC1) — one token per line on stdout, read from the
# single definition in lint_release_corpus.py (see LINT_RELEASE_CORPUS above).
#
# FAIL-LOUD CONTRACT (#459): returns 1 with NO output when the token source cannot
# be read or yields an empty set. A caller MUST treat that as a gate failure — an
# empty token set makes every residue check trivially pass, which is precisely the
# green-for-the-wrong-reason vacuity these anchors exist to eliminate. Never treat
# "no tokens" as "no residue".
scaffold_residue_tokens() {
  [[ -f "$LINT_RELEASE_CORPUS" ]] || return 1
  [[ -x "/usr/bin/python3" ]] || return 1
  local out
  out="$(/usr/bin/python3 "$LINT_RELEASE_CORPUS" --print-scaffold-tokens 2>/dev/null)" || return 1
  [[ -n "$out" ]] || return 1
  printf '%s\n' "$out"
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
# Schema-aware:
#   - Current 8-column schema `| Version | Milestone | … |`: field 1 is the bare
#     Version (e.g. v3.18); the milestone slug is field 2
#     (e.g. v3.18-corpus-integrity-enforcement).
#   - Legacy 5-column schema `| Milestone | Date | … |`: the slug is field 1.
# Resolution rule: forward-scan the fields and emit the FIRST that matches a
# milestone-slug shape — EITHER a version-prefixed key `v<MAJOR>.<MINOR>` (optional
# letter / -N qualifier) carrying a `-<alpha…>` slug tail (e.g. v3.18-corpus-integrity),
# OR an NN-prefixed Epic-Readiness-Playbook slug `<digits>-<alpha…>`
# (e.g. 63-finding-disposition-discipline), OR a pure-alpha kebab-or-word slug
# (e.g. knowledge-corpus-hygiene, or a hyphen-less word like "hardening"). A bare
# Version field (v3.18) carries a dot / has no slug tail, and the trailing date column
# (2026-06-20) is digits-hyphen-digits, so both are skipped.
#
# TRUE safety invariant — this is a first-match-wins FORWARD scan that exits on the
# first shape-match; it is NOT position-independent (inserting a kebab-valued column
# before Milestone would make the scan return that column instead — verified). The
# resolver is correct ONLY because Milestone is field 2 and the single column preceding
# it, Version, is contractually dot-bearing (validate_version() below enforces the dot),
# and a dot cannot pass any of the three slug-shape branches. So "first shape-match ==
# Milestone slug" holds only because exactly one contractually-dot-bearing column
# precedes Milestone. If a column is ever inserted before Milestone this resolver
# mis-resolves — and the D-3 fail-loud preflight gate (phase_preflight → log_row_match)
# is what catches it before any mutation.
# Fallback (defensive): if no field matches (a pure-version row with no slug column),
# return field 1 stripped — preserving the prior behavior. A field-1 value matches zero
# LOG rows under the slug-keyed predicate, so the D-3 gate flags the mis-resolution.
#
# Three regex branches cover the milestone-title shapes that appear in RELEASE_LOG:
#   1. version-prefixed slugs   — vX.Y-name (older rows, e.g. v3.18-corpus-integrity-enforcement)
#   2. NN-prefixed slugs        — NN-name (Epic-Readiness-Playbook, e.g. 69-triage-and-bundling-signals)
#   3. pure-alpha theme-named   — name-with-hyphens (e.g. knowledge-corpus-hygiene) — per #2539
# The downstream `gh pr create --milestone` / `gh issue list --milestone` consume the
# milestone TITLE, and the milestone title IS the slug — so each shape resolves to the
# exact milestone title.
#
# Branch 3 closes the residual that #667 Finding 2 described and #2539 re-observed:
# branches 1+2 alone fall through on a pure-alpha title, so the fallback returned the
# Version field as the slug. That mis-derivation is silent and two-headed — phase 6
# anchors the Version as a non-first RELEASE_LOG column (0 row matches → --apply abort)
# while phase 4's `gh issue list --milestone <version>` matches no milestone and reports
# 0 open release issues (a false PASS). Note --dry-run does NOT surface either symptom:
# it resolves the row via find_log_row on the Version key. The self-test below carries a
# case per branch, including pure-alpha versioned and version-less rows.
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
        # version-prefixed slug (vMAJOR.MINOR[letter][-N]) followed by a hyphenated slug tail,
        # OR an NN-prefixed Epic-Readiness-Playbook milestone slug (e.g. 63-finding-disposition-discipline),
        # OR a pure-alpha theme-named slug (e.g. pda-rollup-and-portfolio, knowledge-corpus-hygiene,
        # or a hyphen-less single word like "hardening").
        # NOTE: no apostrophes in this awk block — it is one single-quoted shell argument.
        # Branch 3 (a4) is anchored end-to-end (^...$) so it matches ONLY a full lowercase
        # kebab-or-word field. It cannot match the Version field of a version-less row
        # ("name (version-less)" — contains a space) nor a bare Version (v3.78 — contains a
        # dot, and [a-z0-9-] excludes dots; validate_version guarantees every Version is
        # dot-bearing). It DOES match a hyphen-less single word — the case the prior
        # hyphen-requiring recognizer missed (#2539).
        if (f ~ /^v[0-9]+\.[0-9]+[a-z]?(-[0-9]+)?-[a-z]/ || f ~ /^[0-9]+-[A-Za-z]/ || f ~ /^[a-z][a-z0-9-]*$/) { print f; exit }
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

# Unified RELEASE_LOG row-match predicate (#2539 AC-3 — dry-run/apply parity).
# Matches the row whose Milestone column is <slug> (any field position) and whose
# State field is one of <state-regex> (an alternation, e.g. 'DEPLOYED' or
# 'DEPLOYED|VERIFIED'). ONE predicate for all three call sites — the D-3 preflight
# gate (count), the phase-6 dry-run check (count), and the phase-6 apply write
# (apply) — so a green dry-run CANNOT diverge from a red apply. That divergence (two
# different match keys against the same row) is the defect-hiding pattern behind the
# v3.24 / v3.66 / v3.71 close-out aborts.
#
#   log_row_match <slug> <state-regex> <count|apply>
#
#   count : print the TRUE number of matching rows (Python findall — NOT capped), and
#           write nothing. rc 0 iff exactly one row matches; rc 1 otherwise.
#   apply : flip the single matching row's State field to VERIFIED in place. print the
#           number flipped; rc 0 iff exactly one row flipped; rc 1 otherwise.
#
# The count path MUST be a true findall count, never subn(count=1): a capped count
# returns 1 for an over-match (n>=2) and would silently disarm the D-3 preflight gate
# (A6.5 FMF-1 — an unfireable gate is worse than no gate). The write cap (count=1)
# lives ONLY on the apply path, where flipping exactly one row is the intended write.
# A field-1 (Version) value matches zero rows here: `^\|.*\| <slug> \|` requires a
# field separator BEFORE the slug, which a leading Version field cannot supply — so a
# mis-resolution that falls back to the Version is caught as n=0, fail-loud.
log_row_match() {
  local slug="$1" state_re="$2" action="$3"
  /usr/bin/python3 - "$RELEASE_LOG" "$slug" "$state_re" "$action" <<'PY'
import sys, re
log_path, slug, state_re, action = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(log_path, "r", encoding="utf-8") as f:
    txt = f.read()
# Row carrying `| <slug> |` (any field) whose State field is one of <state_re>.
pat = re.compile(r"(^\|.*\| " + re.escape(slug) + r" \|.*\| )(?:" + state_re + r")( \|)", re.MULTILINE)
if action == "apply":
    # Flip exactly one matching row's State field to VERIFIED (count=1 = the write cap).
    new_txt, n = pat.subn(r"\1VERIFIED\2", txt, count=1)
    if n == 1:
        with open(log_path, "w", encoding="utf-8") as f:
            f.write(new_txt)
    print(n)
    sys.exit(0 if n == 1 else 1)
else:
    # TRUE count — findall, never capped — so an over-match (n>=2) is visible to D-3.
    n = len(pat.findall(txt))
    print(n)
    sys.exit(0 if n == 1 else 1)
PY
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

  # (b) clean working tree — with ONE tolerated exception: an UNTRACKED release
  # note for the version being closed. The operator-authored-ahead path is the
  # supported authoring path (release-notes-standard.md), and step (f) below
  # rejects that same note if it still carries scaffold residue. Without this
  # tolerance the two gates deadlock: scaffold writes the note -> (f) fails ->
  # the re-run is blocked HERE by the untracked scaffold it just wrote.
  #
  # Scoping is deliberately exact, not prefix-based:
  #   - notes_rel_path() is RELATIVE TO release/releases/, git porcelain paths are
  #     repo-root-relative, so the release/releases/ prefix is REQUIRED.
  #   - grep -x forces a WHOLE-LINE match, so ' M <that path>' (modified-tracked)
  #     and '?? <that path>.bak' still FAIL. Only '?? <that exact path>' passes.
  local _allowed_note="release/releases/$(notes_rel_path)"
  local _dirty
  _dirty="$($GIT -C "$REPO_ROOT" status --porcelain 2>/dev/null \
            | /usr/bin/grep -vxF "?? ${_allowed_note}" || true)"
  if [[ -n "$_dirty" ]]; then
    mark_phase "preflight" "FAIL" "working tree not clean: $(echo "$_dirty" | /usr/bin/head -3 | /usr/bin/tr '\n' ' ')"
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

  # (d.1) D-3 fail-loud slug-resolution gate (#2539 / A6.5). The resolved milestone
  # slug must match EXACTLY ONE RELEASE_LOG row under the SAME slug-keyed predicate
  # phase 6 apply will use (log_row_match, TRUE count). A mis-resolved slug — an
  # unenumerated name shape that falls back to the Version (n=0), or a kebab-valued
  # column that shadows Milestone (n>=2) — is caught HERE, before any mutation, rather
  # than aborting 4 phases later at --apply or silently writing a bad INDEX cell. The
  # state alternation is required because an idempotent re-run reads VERIFIED, not DEPLOYED.
  local _slug_match_n
  _slug_match_n="$(log_row_match "$STATE_MILESTONE_SLUG" 'DEPLOYED|VERIFIED' count)"
  if [[ "$_slug_match_n" != "1" ]]; then
    mark_phase "preflight" "FAIL" "resolved milestone slug '$STATE_MILESTONE_SLUG' matches $_slug_match_n RELEASE_LOG rows (expected 1) — slug resolution failed for this milestone naming pattern"
    return 2
  fi

  # (e) annotated tag exists for version
  if $GIT -C "$REPO_ROOT" tag -l "$VERSION" 2>/dev/null | /usr/bin/grep -qE "^${VERSION}$"; then
    STATE_TAG_EXISTS=1
  fi

  # (f) scaffold-residue gate on a PRE-EXISTING note for this version (AC1 anchor A1).
  # Composes with (b): (b) now ACCEPTS a pre-authored note; (f) REJECTS one that is
  # still an unfilled scaffold. Fires BEFORE any mutation, which is why it lives in
  # preflight rather than beside the §3.2 lint at 9.2.
  #
  # The token set is NOT retyped here — it is read from lint_release_corpus.py via
  # --print-scaffold-tokens, so the producer (the scaffold heredoc), the python
  # anchor (A2) and the two shell anchors (A1, A3) cannot drift apart.
  local _note="${RELEASE_NOTES_DIR}/${VERSION}_RELEASE_NOTES.md"
  is_version_less && _note="${RELEASE_NOTES_DIR}/_unversioned/${VERSION}_RELEASE_NOTES.md"
  if [[ -f "$_note" ]]; then
    local _tokens
    if ! _tokens="$(scaffold_residue_tokens)"; then
      mark_phase "preflight" "FAIL" "scaffold-residue token set unreadable from ${LINT_RELEASE_CORPUS} (--print-scaffold-tokens) — the AC1 residue gate cannot be evaluated; failing loud rather than passing vacuously (#459)"
      return 2
    fi
    local _tok _hit
    while IFS= read -r _tok; do
      [[ -z "$_tok" ]] && continue
      _hit="$(/usr/bin/grep -nF -- "$_tok" "$_note" | /usr/bin/head -1 || true)"
      if [[ -n "$_hit" ]]; then
        mark_phase "preflight" "FAIL" "unfilled scaffold token in ${_note} at line ${_hit%%:*} — token '${_tok}'; author the release note before close-out (release-notes-standard.md §3.2)"
        return 2
      fi
    done <<< "$_tokens"
  fi

  mark_phase "preflight" "PASS" "gh auth OK; tree clean; cwd worktree; RELEASE_LOG row state=$STATE_LOG_ROW_STATE; tag_exists=$STATE_TAG_EXISTS; no scaffold residue in ${VERSION} note"
  return 0
}

# ─── Phase 3: read_state ─────────────────────────────────────────────────────

phase_read_state() {
  STATE_MILESTONE_STATE="$($GH api "repos/${REPO_SLUG}/milestones/${MILESTONE}" --jq '.state' 2>/dev/null || echo "unknown")"

  # MERGE_SHA capture (#1682) — ONCE, here, from the RELEASE PR. The release
  # identity is the release PR's merge commit to main (what the RELEASE_LOG row's
  # Merge SHA column records and where stage-12 Phase B3 cuts the signed tag) —
  # NOT the chore PR (corpus-only). The release PR has already merged before
  # close-out runs (a precondition), so its mergeCommit is available. Both #1705
  # and #1682's publish consumer read this single global (no double-population).
  MERGE_SHA="$($GH pr view "$PR_NUMBER" --repo "$REPO_SLUG" --json mergeCommit --jq '.mergeCommit.oid // ""' 2>/dev/null || echo "")"

  # Cycle time (read-only; may be N/A pre-instrumentation)
  if [[ -x "$COMPUTE_CYCLE_TIME" ]]; then
    STATE_CYCLE_TIME="$("$COMPUTE_CYCLE_TIME" --version "$VERSION" 2>/dev/null || echo "N/A")"
  else
    STATE_CYCLE_TIME="N/A (compute-cycle-time.sh not executable)"
  fi

  mark_phase "read_state" "PASS" "milestone state=$STATE_MILESTONE_STATE; cycle_time=$STATE_CYCLE_TIME; release-PR merge SHA=${MERGE_SHA:-<unresolved>}"
  return 0
}

# ─── Phase 4: detect_open_release_issues (D6 — auto-close anomaly) ───────────

phase_detect_open_issues() {
  local slug="$STATE_MILESTONE_SLUG"
  [[ -z "$slug" ]] && slug="$VERSION"

  # Fetch number+title so the Stage-13-subtask auto-exclude (title-regex fallback)
  # can run. Format: "<number>\t<title>" per line (tab-separated).
  local raw
  raw="$($GH issue list --repo "$REPO_SLUG" --milestone "$slug" --state open --json number,title --jq '.[] | "\(.number)\t\(.title)"' 2>/dev/null || true)"

  # Build the explicit-exclude set (#38 primary path). The Stage-13 orchestration
  # sub-task is passed by NUMBER (--exclude-issue <N>) so it is deterministically
  # filtered and cannot self-close mid-run (Risk R5).
  local _excluded_detail=""
  _is_excluded() {
    local n="$1" e
    for e in "${EXCLUDE_ISSUES[@]:-}"; do
      [[ -n "$e" && "$n" == "$e" ]] && return 0
    done
    return 1
  }

  OPEN_ISSUE_LIST=""
  local _n _title _line
  while IFS= read -r _line; do
    [[ -z "$_line" ]] && continue
    _n="${_line%%$'\t'*}"
    _title="${_line#*$'\t'}"
    # (1) explicit --exclude-issue (deterministic, primary)
    if _is_excluded "$_n"; then
      _excluded_detail="${_excluded_detail}#${_n} (explicit --exclude-issue) "
      continue
    fi
    # (2) title-regex fallback: a Stage-13 close orchestration sub-task that the
    # hub did NOT pass by number is still excluded so it cannot self-close.
    # Pattern: title matches `stage.?13` AND `close` (case-insensitive).
    if /usr/bin/printf '%s' "$_title" | /usr/bin/grep -qiE 'stage.?13.*close'; then
      _excluded_detail="${_excluded_detail}#${_n} (title-regex stage-13-close) "
      continue
    fi
    OPEN_ISSUE_LIST="${OPEN_ISSUE_LIST}${_n}"$'\n'
  done <<< "$raw"
  # Trim a trailing newline so grep -c counts correctly.
  OPEN_ISSUE_LIST="$(/usr/bin/printf '%s' "$OPEN_ISSUE_LIST" | /usr/bin/sed '/^$/d')"

  if [[ -z "$OPEN_ISSUE_LIST" ]]; then
    OPEN_ISSUE_COUNT=0
  else
    OPEN_ISSUE_COUNT="$(/usr/bin/printf '%s\n' "$OPEN_ISSUE_LIST" | /usr/bin/grep -c .)"
  fi

  if [[ "$OPEN_ISSUE_COUNT" -gt 10 ]]; then
    mark_phase "detect_open_issues" "FAIL" "$OPEN_ISSUE_COUNT open release issues exceeds D-1 threshold (>10); escalate Tier 2 [SCOPE CHANGE] — possible Stage 12 chore PR did not land"
    return 2
  fi

  local _exdetail=""
  [[ -n "$_excluded_detail" ]] && _exdetail=" (excluded: ${_excluded_detail% })"
  mark_phase "detect_open_issues" "PASS" "$OPEN_ISSUE_COUNT open release issues (auto-close anomaly candidates)${_exdetail}"
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

  # VERIFIED re-derivation guard (#1681) — runs FIRST, BEFORE the idempotent
  # SKIP-on-VERIFIED early-return. A row flipped to VERIFIED by a partial or
  # concurrent run would otherwise SKIP-as-PASS with no independent check that
  # the release actually landed. Re-derive from deploy reality: a VERIFIED row is
  # only legitimate if THIS release's PR ($PR_NUMBER) actually merged to main.
  #   - confirmed MERGED to main → legitimate idempotent re-run → SKIP-as-PASS
  #   - NOT merged (open / closed-unmerged) yet row reads VERIFIED → the
  #     concurrency-induced false-VERIFIED #1681 targets → FAIL (do not trust the
  #     in-memory string blind). Check 48 detects this post-hoc; this prevents it
  #     at source.
  # gh-offline degradation: if `gh pr view` cannot resolve (no network / bad PR),
  # the merge fact is UNVERIFIABLE — FAIL fail-loud rather than vacuously SKIP.
  if [[ "$STATE_LOG_ROW_STATE" == "VERIFIED" ]]; then
    local pr_json pr_state pr_base
    pr_json="$($GH pr view "$PR_NUMBER" --repo "$REPO_SLUG" --json state,baseRefName --jq '"\(.state)/\(.baseRefName)"' 2>/dev/null || echo "")"
    pr_state="${pr_json%%/*}"
    pr_base="${pr_json#*/}"
    if [[ "$pr_json" == "MERGED/main" || ( "$pr_state" == "MERGED" && "$pr_base" == "main" ) ]]; then
      mark_phase "transition_release_log" "SKIPPED" "row already VERIFIED and release PR #${PR_NUMBER} is MERGED to main — legitimate idempotent re-run"
      return 0
    fi
    mark_phase "transition_release_log" "FAIL" "row reads VERIFIED but release PR #${PR_NUMBER} is not confirmed MERGED to main (got '${pr_json:-<unresolved>}') — false-VERIFIED (partial/concurrent run, or gh unresolvable); re-derive, do not SKIP-as-PASS (#1681)"
    return 3
  fi

  local row
  row="$(find_log_row "$VERSION")"
  if [[ -z "$row" ]]; then
    mark_phase "transition_release_log" "FAIL" "row not found"
    return 3
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    # AC-3: the dry-run tests the SAME slug-keyed predicate the apply will use, so a
    # green dry-run cannot mask a red apply (the v3.24/v3.66/v3.71 defect-hiding gap).
    local _dry_n
    _dry_n="$(log_row_match "$slug" 'DEPLOYED' count)"
    if [[ "$_dry_n" != "1" ]]; then
      mark_phase "transition_release_log" "FAIL" "DEPLOYED→VERIFIED transition would match $_dry_n rows for slug=$slug (expected 1) — dry-run predicts --apply abort (AC-3 parity)"
      return 3
    fi
    mark_phase "transition_release_log" "DRY-RUN" "would replace trailing '| DEPLOYED |' with '| VERIFIED |' on $slug row (log_row_match n=1)"
    return 0
  fi

  # AC-3: apply calls the SAME predicate the dry-run tested, in apply mode — one code
  # path, so dry-run PASS ⟺ apply PASS by construction. Schema-agnostic: matches the
  # row whose Milestone column is <slug> at any field position and flips its DEPLOYED
  # state field to VERIFIED (legacy 5-col: slug field 1, State trailing; current 8-col:
  # slug field 2, Date trailing the State field). Python edit avoids BSD-sed -i.
  local _apply_n
  _apply_n="$(log_row_match "$slug" 'DEPLOYED' apply)"
  if [[ "$_apply_n" != "1" ]]; then
    mark_phase "transition_release_log" "FAIL" "RELEASE_LOG DEPLOYED→VERIFIED transition matched $_apply_n rows for slug=$slug (expected 1) — regex/schema mismatch or slug resolution failure"
    return 3
  fi

  STATE_LOG_ROW_STATE="VERIFIED"
  mark_phase "transition_release_log" "PASS" "transitioned $slug row DEPLOYED → VERIFIED"
  return 0
}

# ─── Phase 6.5: inject_outcome_field (#37 — Outcome field on Deployment Log) ──
#
# Injects the structurally-elevated `**Outcome:**` field into the visible-H4
# `#### Deployment Log v<X.Y>` block per decision-outcome-tracking.md §2-§5. A
# SEPARATE phase (not folded into phase_transition_release_log) so the Deployment-
# Log-block edit does not contend with #1681's VERIFIED-re-derivation guard and
# #1680's concurrency wrapper on the table-row write (the 3-writer collision the
# plan flagged — extraction reduces that function to 2 writers).
#
# Enum (closed, §2): SUCCESS / PARTIAL / ROLLBACK / DEFERRED.
#   Default = SUCCESS (the §4 autonomous Stage-13-spoke path: QC4-clean close).
#   --outcome <ENUM> overrides; an unknown value is rejected with `die`.
# Rationale (§5): OPTIONAL for SUCCESS; REQUIRED for non-SUCCESS — a non-SUCCESS
#   --outcome with no --outcome-rationale FAILs the phase (the §5 forcing fn).
# Placement (§3): the `**Outcome:**` line lands immediately AFTER the `**Result:**`
#   line in the v<X.Y> Deployment-Log block. Idempotent: skip if a `**Outcome:**`
#   line is already present in that block.
phase_inject_outcome_field() {
  # Resolve + validate the outcome value (default SUCCESS per §4).
  local outcome="${OUTCOME:-SUCCESS}"
  case "$outcome" in
    SUCCESS|PARTIAL|ROLLBACK|DEFERRED) : ;;
    *) die "Invalid --outcome '$outcome' (closed enum: SUCCESS / PARTIAL / ROLLBACK / DEFERRED)" ;;
  esac

  # §5 conditional-required: non-SUCCESS demands a rationale.
  if [[ "$outcome" != "SUCCESS" && -z "$OUTCOME_RATIONALE" ]]; then
    mark_phase "inject_outcome_field" "FAIL" "--outcome $outcome requires --outcome-rationale (decision-outcome-tracking.md §5 REQUIRED for non-SUCCESS)"
    return 3
  fi

  # Idempotent: skip if the v<X.Y> Deployment-Log block already carries Outcome.
  # (Scope the grep to the block via awk so a sibling release's Outcome line does
  # not false-positive.)
  if /usr/bin/awk -v ver="$VERSION" '
      $0 == "#### Deployment Log " ver { inblk=1; next }
      /^#### / && inblk { inblk=0 }
      inblk && /^\*\*Outcome:\*\*/ { found=1 }
      END { exit(found ? 0 : 1) }
    ' "$RELEASE_LOG" 2>/dev/null; then
    mark_phase "inject_outcome_field" "SKIPPED" "**Outcome:** already present in the $VERSION Deployment Log block"
    return 0
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    local _r=""
    [[ -n "$OUTCOME_RATIONALE" ]] && _r=" + **Outcome rationale:** $OUTCOME_RATIONALE"
    mark_phase "inject_outcome_field" "DRY-RUN" "would inject '**Outcome:** $outcome'${_r} after **Result:** in the $VERSION Deployment Log block"
    return 0
  fi

  # In-place edit: within the v<X.Y> Deployment-Log block, insert the Outcome
  # line(s) immediately after the first `**Result:**` line. Bounded to the block
  # (next `#### ` heading or EOF) so a later release's `**Result:**` is untouched.
  /usr/bin/python3 - "$RELEASE_LOG" "$VERSION" "$outcome" "$OUTCOME_RATIONALE" <<'PY'
import sys
log_path, version, outcome, rationale = sys.argv[1:5]
with open(log_path, "r", encoding="utf-8") as f:
    lines = f.read().splitlines()

block_hdr = f"#### Deployment Log {version}"
start = None
for i, line in enumerate(lines):
    if line.strip() == block_hdr:
        start = i
        break
if start is None:
    print(f"ERROR: Deployment Log block for {version} not found", file=sys.stderr)
    sys.exit(3)

# Block end = next `#### ` heading after start, or EOF.
end = len(lines)
for j in range(start + 1, len(lines)):
    if lines[j].startswith("#### "):
        end = j
        break

# Find the `**Result:**` line within the block; insert after it.
result_idx = None
for j in range(start, end):
    if lines[j].startswith("**Result:**"):
        result_idx = j
        break
if result_idx is None:
    print(f"ERROR: **Result:** line not found in the {version} Deployment Log block", file=sys.stderr)
    sys.exit(3)

inject = [f"**Outcome:** {outcome}"]
if rationale:
    inject.append(f"**Outcome rationale:** {rationale}")
out = lines[:result_idx + 1] + inject + lines[result_idx + 1:]
with open(log_path, "w", encoding="utf-8") as f:
    f.write("\n".join(out) + "\n")
PY
  if [[ $? -ne 0 ]]; then
    mark_phase "inject_outcome_field" "FAIL" "could not inject **Outcome:** into the $VERSION Deployment Log block (block or **Result:** line not found)"
    return 3
  fi

  local _detail="injected **Outcome:** $outcome after **Result:** in the $VERSION Deployment Log block"
  [[ -n "$OUTCOME_RATIONALE" ]] && _detail="$_detail (+ **Outcome rationale:**)"
  mark_phase "inject_outcome_field" "PASS" "$_detail"
  return 0
}

# ─── Phase 7: append_release_index (#667 Finding 6 — 6-col single-row insert) ─
#
# Emits ONE row in the LIVE 6-column RELEASE_INDEX schema:
#   | Version | Milestone | Date | Theme | Release PR | Release Notes |
# (header at RELEASE_INDEX.md line 5; generate_release_index.py emits the same 6).
#
# #667 Finding 6 fixes two live defects:
#   (a) the prior hand-append fallback emitted an 8-COLUMN row
#       (| slug | date | class | scope | plan | note | [LOG] | status |) against
#       the 6-column live schema — a malformed row that deploy.sh Check 32(a)
#       tolerates (it only asserts the version is the first cell) but that breaks
#       the table and #1680's structural re-parse;
#   (b) the generate_release_index.py FULL-regenerate branch could re-sort /
#       reorder unrelated rows (the churn root). We DROP that branch entirely and
#       make this phase a pure single-row insert. The generator's own within-date
#       sort + find_artifact bugs are separable (they also affect deploy.sh Check
#       23) and stay tracked under #667 Finding 6 as out-of-scope for THIS tool.
#
# Column sourcing: Version = bare version (field-1); Milestone = slug; Theme
# defaults to `—` (the Theme prose is authored at note time, not derivable here —
# operator fills post-merge); Release PR = `#${PR_NUMBER}`; Release Notes =
# `[notes/${VERSION}_RELEASE_NOTES.md](notes/${VERSION}_RELEASE_NOTES.md)`. The
# row inserts immediately after the `|---` separator (top = most-recent),
# matching the live "Chronological-recent-first" header convention + §220 I1.
phase_append_release_index() {
  local slug="$STATE_MILESTONE_SLUG"
  [[ -z "$slug" ]] && slug="$VERSION"

  # Idempotent: skip if a row keyed on this version is already present (version is
  # the first table cell in the 6-col schema — matches Check 32(a)). The optional
  # " (version-less)" marker is accepted so a version-less row is recognised too
  # (#2048 — without it the guard missed the marked cell and re-appended a dup).
  if /usr/bin/grep -qE "^\|[[:space:]]*${VERSION//./\\.}([[:space:]]+\(version-less\))?[[:space:]]*\|" "$RELEASE_INDEX" 2>/dev/null; then
    mark_phase "append_release_index" "SKIPPED" "INDEX row for $VERSION already present"
    return 0
  fi

  local ver_cell note_rel
  ver_cell="$(index_version_cell)"   # "<version>" | "<slug> (version-less)"
  note_rel="$(notes_rel_path)"       # notes/… | notes/_unversioned/…

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "append_release_index" "DRY-RUN" "would insert a 6-col row (| $ver_cell | $slug | $(date_today) | — | #${PR_NUMBER} | $note_rel |) at the top of RELEASE_INDEX.md"
    return 0
  fi

  local date_str note_link pr_cell
  date_str="$(date_today)"
  note_link="[${note_rel}](${note_rel})"
  pr_cell="#${PR_NUMBER}"

  # Pure single-row insert in the 6-column schema. Insert immediately after the
  # first separator line (`|---`), keeping chronological-recent-first order.
  /usr/bin/python3 - "$RELEASE_INDEX" "$ver_cell" "$slug" "$date_str" "$pr_cell" "$note_link" <<'PY'
import sys
path, version, slug, date, pr_cell, note_link = sys.argv[1:7]
with open(path, "r", encoding="utf-8") as f:
    lines = f.read().splitlines()
# 6-column live schema: | Version | Milestone | Date | Theme | Release PR | Release Notes |
new_row = f"| {version} | {slug} | {date} | — | {pr_cell} | {note_link} |"
out = []
inserted = False
for line in lines:
    out.append(line)
    if (not inserted) and line.startswith("|---"):
        out.append(new_row)
        inserted = True
if not inserted:
    out.append(new_row)
with open(path, "w", encoding="utf-8") as f:
    f.write("\n".join(out) + "\n")
PY
  mark_phase "append_release_index" "PASS" "inserted 6-col row for $VERSION (Version | Milestone | Date | Theme | Release PR | Release Notes)"
  return 0
}

# ─── Phase 8: append_release_digest (#667 Finding 3 — H3 under topmost H2) ────
#
# The load-bearing structural fix. The LIVE RELEASE_DIGEST is a flat list of
#   ### vX.Y (date) — <headline>
# H3 entries directly under the topmost working H2 (today `## Knowledge Corpus`,
# RELEASE_DIGEST.md line 6), most-recent-first. deploy.sh Check 32(b) asserts
# `^### vX\.Y[[:space:](]` (deploy.sh:5115) AND Check 48 close-completeness
# delegates to the same. The §220 concurrent-conflict doctrine (stage-13-close.md
# § Concurrent Stage-13 corpus conflict resolution) explicitly mandates the
# normal append targets "the topmost working H2 … intra-section date/insertion-
# ordered … not re-homed to a `## vN.*` family section."
#
# The prior emit searched for a `## {major}.* —` family H2, found none, and fell
# into an EOF branch that appended a NEW H2 + a `### Releases` table scaffold + a
# 3-column `| Version | Date | Headline |` table ROW — a structure that
# `^### vX\.Y` will NEVER match. (Legacy `## v3.* —` / `## v1.* —` / `## v2.* —`
# family H2s still exist LOWER in the file as historical arc sections; they are
# not the append target.) This rewrite emits the H3 form directly. Headline
# source: the H1 of notes/${VERSION}_RELEASE_NOTES.md minus the `# ` prefix (the
# same extraction phase_publish_github_release uses), falling back to a
# placeholder only when the note is not yet authored.
phase_append_release_digest() {
  local slug="$STATE_MILESTONE_SLUG"
  [[ -z "$slug" ]] && slug="$VERSION"

  # Idempotent: skip if an H3 entry keyed on this version is already present
  # (matches Check 32(b)'s own key: `### vX.Y` with space or `(` terminator).
  if /usr/bin/grep -qE "^### ${VERSION//./\\.}[[:space:](]" "$RELEASE_DIGEST" 2>/dev/null; then
    mark_phase "append_release_digest" "SKIPPED" "DIGEST H3 entry for $VERSION already present"
    return 0
  fi

  # Headline from the note H1 (minus `# `); placeholder only when the note is
  # absent (e.g. dry-run before scaffold, or scaffold-without-prose).
  # Version-less notes live under notes/_unversioned/ (#2048). Resolve off
  # RELEASE_NOTES_DIR (not a hardcoded root) so the self-test override is honored.
  local notes_path="${RELEASE_NOTES_DIR}/${VERSION}_RELEASE_NOTES.md"
  if is_version_less; then notes_path="${RELEASE_NOTES_DIR}/_unversioned/${VERSION}_RELEASE_NOTES.md"; fi
  local headline=""
  if [[ -f "$notes_path" ]]; then
    headline="$(/usr/bin/grep -m1 '^# ' "$notes_path" 2>/dev/null | /usr/bin/sed 's/^# //' || echo "")"
  fi
  [[ -z "$headline" || "$headline" == "$VERSION" ]] && headline="<headline — populated by operator at chore PR review>"

  # The date cell carries the "(<date>, version-less)" marker for a version-less
  # release, matching the shipped DIGEST convention (#2048).
  local date_cell
  if is_version_less; then date_cell="$(date_today), version-less"; else date_cell="$(date_today)"; fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "append_release_digest" "DRY-RUN" "would prepend '### $VERSION ($date_cell) — $headline' under the topmost working H2 in RELEASE_DIGEST.md"
    return 0
  fi

  # Prepend the H3 entry under the topmost `## ` working H2 (the most-recent
  # entry sits immediately after the H2 + its blank line, above the current top
  # `### ` entry). Drop the family-H2 search + the `### Releases` table scaffold.
  /usr/bin/python3 - "$RELEASE_DIGEST" "$VERSION" "$date_cell" "$headline" <<'PY'
import sys
path, version, date, headline = sys.argv[1:5]
with open(path, "r", encoding="utf-8") as f:
    lines = f.read().splitlines()

new_entry = f"### {version} ({date}) — {headline}"

# Locate the topmost working H2 (first `## ` line).
h2_idx = None
for i, line in enumerate(lines):
    if line.startswith("## "):
        h2_idx = i
        break

if h2_idx is None:
    # No H2 at all — append the entry at EOF (degraded; should not happen on a
    # well-formed corpus, but never silently drops the entry).
    out = lines + ["", new_entry]
else:
    # Insert after the H2 and any immediately-following blank line, ABOVE the
    # current top `### ` entry — making this the most-recent entry.
    insert_at = h2_idx + 1
    while insert_at < len(lines) and lines[insert_at].strip() == "":
        insert_at += 1
    out = lines[:insert_at] + [new_entry, ""] + lines[insert_at:]

with open(path, "w", encoding="utf-8") as f:
    f.write("\n".join(out) + "\n")
PY
  mark_phase "append_release_digest" "PASS" "prepended '### $VERSION (date) — …' H3 under the topmost working H2"
  return 0
}

# ─── Phase 8.5: append_reversions (#1679; SLIM #3109 — orphan-tag recovery record) ─
#
# Appends row(s) to RELEASE_REVERSIONS.md — the append-only re-version ledger —
# ONE row per ABANDONED version, ONLY when this release re-versioned mid-pipeline.
# The common no-collision release records `N/A` and writes nothing (non-ceremony,
# mirroring the phase_bump_version version-less SKIP + the phase_append_changelog
# pre-CHANGELOG SKIP idioms).
#
# Re-version input is EXPLICIT (the honest manual path — the prose-only Stage 12
# Deployment Log carries no structured re-version field to auto-detect from):
#   --reversion "<final>|<claimed-seq>|<merge_sha>|<collided>|<stage>|<residual>"
# where <claimed-seq> is the full ordered claim sequence joined by " -> " (or "->"),
# e.g. "v2.12 -> v2.14 -> v2.12". The phase DERIVES the abandoned-version set
# positionally — DISTINCT versions of claimed-seq[0:-1] that differ from <final>,
# de-duplicated — so a round-trip v2.12 -> v2.14 -> v2.12 (final v2.12) yields the
# single abandoned version v2.14, KEEPING v2.12 as final (the set-minus-is-wrong fix).
#
# disposition is grounded, not asserted: for each abandoned version the phase probes
# `git ls-remote --tags origin <abandoned>` — ABSENT or canonical-elsewhere => `none`
# (no orphan to reap; the reaper's canonical-version guard would refuse it anyway);
# present-and-not-canonical => `tag-orphaned` (the reaper READS this). `unknown`
# abandoned_tag_pushed maps to `unrecoverable` only via an explicit pre-instrumentation
# marker, never inferred here.
#
# SLIM (#3109): only a `tag-orphaned` disposition is RECORDED going forward — a `none`
# abandoned version (no orphan tag; the common defer-to-merge path, or a version that is
# canonical for a live sibling row) is gated out AFTER the probe, so an all-`none`
# re-version records N/A and writes nothing. Historical `none`/`unrecoverable` rows are
# retained (append-only). The ledger is an orphan-tag recovery record — the input the
# recovery-doctrine reaper reads — not a collision-rate telemetry surface.
#
# Idempotent: a (slug, abandoned_version) row already present is skipped. Append is
# chronological-recent-first (below the `|---` separator), matching the sibling
# corpus surfaces. The consumer (recovery doctrine) transitions disposition/reaped_ref
# in place; this producer ONLY appends.

# reversion_disposition <abandoned_version> — ground the disposition by probing origin
# for the abandoned tag. Echoes "<disposition>|<abandoned_tag_pushed>". Read-only.
reversion_disposition() {
  local abv="$1" on_origin
  on_origin="$(git ls-remote --tags "${REMOTE_NAME:-origin}" "refs/tags/${abv}" 2>/dev/null | /usr/bin/grep -c "refs/tags/${abv}$" 2>/dev/null || true)"; on_origin="${on_origin:-0}"
  if [[ "$on_origin" -gt 0 ]]; then
    # Present on origin. If it is the canonical Tag of a live RELEASE_LOG row, it
    # belongs to a sibling (never reap) => disposition none. Otherwise an orphan
    # of THIS release awaiting the reaper => tag-orphaned.
    if /usr/bin/grep -qE "^\| ${abv} \|" "$RELEASE_LOG" 2>/dev/null \
       || /usr/bin/grep -qE "\| \`?${abv}\`? \| (VERIFIED|DEPLOYED) \|" "$RELEASE_LOG" 2>/dev/null; then
      /usr/bin/printf 'none|false\n'
    else
      /usr/bin/printf 'tag-orphaned|true\n'
    fi
  else
    /usr/bin/printf 'none|false\n'
  fi
}

# reversion_classify <slug> <abandoned_version> — THE single decision point for whether a
# row gets written. Echoes "<outcome>|<disposition>|<tag_pushed>" where outcome is:
#   present — a (slug, abandoned_version) row already exists (idempotency skip)
#   gated   — disposition=none: no orphan tag, so SLIM (#3109) records nothing
#   record  — disposition=tag-orphaned: a row IS written
#
# PARITY (#3109 F-01, the #2539 dry-run/apply parity-gap class): the dry-run preview and
# the apply loop BOTH route through this helper, so the preview counts exactly the rows
# apply will write. The two paths previously duplicated the predicate — the SLIM gate was
# added to the apply loop only, and the preview kept counting every abandoned version. A
# dry-run that misstates the mutation defeats the governance control it exists to provide
# (RELEASE_PROTOCOL.md § Dry-Run Protocol), so the predicate lives in ONE place. Read-only
# in every branch (a `git ls-remote` probe + greps), hence safe to run in dry-run mode.
reversion_classify() {
  local slug="$1" abv="$2" d
  if /usr/bin/grep -qE "^\| ${slug} \| ${abv} \|" "$RELEASE_REVERSIONS" 2>/dev/null; then
    /usr/bin/printf 'present|none|false\n'
    return 0
  fi
  d="$(reversion_disposition "$abv")"
  if [[ "${d%%|*}" == "none" ]]; then
    /usr/bin/printf 'gated|%s\n' "$d"
  else
    /usr/bin/printf 'record|%s\n' "$d"
  fi
}

phase_append_reversions() {
  local slug="$STATE_MILESTONE_SLUG"
  [[ -z "$slug" ]] && slug="$VERSION"

  # (1) No-reversion common path — record N/A, write nothing (non-ceremony).
  if [[ -z "$REVERSION_SPEC" ]]; then
    mark_phase "append_reversions" "N/A" "no re-version this release (RELEASE_REVERSIONS.md untouched)"
    return 0
  fi

  # (2) Parse the explicit --reversion spec.
  #     <final>|<claimed-seq>|<merge_sha>|<collided>|<stage>|<residual>
  local rv_final rv_seq rv_sha rv_collided rv_stage rv_residual
  IFS='|' read -r rv_final rv_seq rv_sha rv_collided rv_stage rv_residual <<<"$REVERSION_SPEC"
  rv_collided="${rv_collided:-—}"
  rv_stage="${rv_stage:-S12}"
  rv_residual="${rv_residual:-—}"
  rv_sha="${rv_sha:-—}"
  if [[ -z "$rv_final" || -z "$rv_seq" ]]; then
    mark_phase "append_reversions" "FAIL" "--reversion needs at least <final>|<claimed-seq> (got '$REVERSION_SPEC')"
    return 3
  fi

  # (3) Derive the abandoned-version set positionally (claimed[0:-1], distinct,
  #     != final). Python keeps the round-trip semantics unambiguous + order-stable.
  local abandoned_list
  abandoned_list="$(/usr/bin/python3 - "$rv_final" "$rv_seq" <<'PY'
import sys, re
final, seq = sys.argv[1], sys.argv[2]
# Split on the arrow separator (tolerate "->" with or without surrounding spaces).
parts = [p.strip() for p in re.split(r'\s*->\s*', seq) if p.strip()]
# Abandoned = distinct members of the sequence EXCLUDING its last element, != final.
seen, out = set(), []
for v in parts[:-1]:
    if v != final and v not in seen:
        seen.add(v); out.append(v)
print("\n".join(out))
PY
)"
  if [[ -z "$abandoned_list" ]]; then
    # A claim sequence whose only non-final entries equal the final (degenerate) —
    # nothing was actually abandoned. Record N/A rather than an empty row.
    mark_phase "append_reversions" "N/A" "claim sequence '$rv_seq' abandoned no version distinct from final '$rv_final'"
    return 0
  fi

  # Normalize the claimed sequence to the canonical " → " arrow for the row payload.
  local rv_seq_disp
  rv_seq_disp="$(/usr/bin/python3 - "$rv_seq" <<'PY'
import sys, re
parts = [p.strip() for p in re.split(r'\s*->\s*', sys.argv[1]) if p.strip()]
print(" → ".join(parts))
PY
)"

  # (4) Classify EVERY abandoned version through the one shared decision point, before
  #     either path acts. `reversion_classify` applies the idempotency skip and the SLIM
  #     gate (#3109) and is read-only, so dry-run and apply necessarily agree on the row
  #     count — the parity the two duplicated predicates used to break (F-01).
  local to_write="" gated_list="" present_list=""
  local n_write=0 gated=0 n_present=0
  local abv cls outcome rest
  while IFS= read -r abv; do
    [[ -z "$abv" ]] && continue
    cls="$(reversion_classify "$slug" "$abv")"
    outcome="${cls%%|*}"; rest="${cls#*|}"   # rest = "<disposition>|<tag_pushed>"
    case "$outcome" in
      record)  n_write=$((n_write+1));   to_write="${to_write}${abv}|${rest}"$'\n' ;;
      gated)   gated=$((gated+1));       gated_list="${gated_list}${abv}," ;;
      *)       n_present=$((n_present+1)); present_list="${present_list}${abv}," ;;
    esac
  done <<<"$abandoned_list"
  gated_list="${gated_list%,}"; present_list="${present_list%,}"

  if [[ "$MODE" == "dry-run" ]]; then
    # Preview the POST-gate count — the rows apply will actually write. Reporting the raw
    # abandoned-version count here is what broke parity on the dominant `none` path.
    local detail="would append ${n_write} row(s) to RELEASE_REVERSIONS.md for slug '$slug' (final $rv_final)"
    if [[ "$n_write" -eq 0 && "$gated" -gt 0 ]]; then
      detail="${detail} — re-version left no orphan tag, nothing to record (SLIM #3109)"
    elif [[ "$n_write" -eq 0 ]]; then
      detail="${detail} — all abandoned-version rows for $slug already present (idempotent)"
    fi
    [[ "$gated" -gt 0 ]] && detail="${detail}; gated ${gated} (no orphan tag: ${gated_list})"
    [[ "$n_present" -gt 0 ]] && detail="${detail}; already present ${n_present} (${present_list})"
    mark_phase "append_reversions" "DRY-RUN" "$detail"
    return 0
  fi

  # (5) Apply — write exactly the rows classified `record` above (no re-probe; the
  #     disposition/tag_pushed carried through from the shared classifier).
  local date_str; date_str="$(date_today)"
  local appended=0 disp tag_pushed
  while IFS='|' read -r abv disp tag_pushed; do
    [[ -z "$abv" ]] && continue
    # Hand-append below the first `|---` separator (chronological-recent-first).
    /usr/bin/python3 - "$RELEASE_REVERSIONS" "$slug" "$abv" "$rv_final" "$rv_seq_disp" "$tag_pushed" "$rv_sha" "$rv_collided" "$rv_stage" "$disp" "$rv_residual" "$date_str" <<'PY'
import sys
path, slug, abv, final, seq, pushed, sha, collided, stage, disp, residual, date = sys.argv[1:13]
with open(path, "r", encoding="utf-8") as f:
    lines = f.read().splitlines()
row = f"| {slug} | {abv} | {final} | {seq} | {pushed} | {sha} | {collided} | {stage} | {disp} | {residual} | — | {date} |"
out, inserted = [], False
for line in lines:
    out.append(line)
    if (not inserted) and line.startswith("|---"):
        out.append(row); inserted = True
if not inserted:
    out.append(row)
with open(path, "w", encoding="utf-8") as f:
    f.write("\n".join(out) + "\n")
PY
    appended=$((appended+1))
  done <<<"$to_write"

  if [[ "$appended" -eq 0 ]]; then
    # SLIM (#3109): separate an all-`none` re-version (gated — no orphan tag to record)
    # from a true idempotent re-run (its rows already present). The former is N/A — not a
    # PASS-with-rows and not the stale "already present" SKIPPED.
    if [[ "$gated" -gt 0 ]]; then
      mark_phase "append_reversions" "N/A" "re-version left no orphan tag — not recorded (SLIM #3109)"
    else
      mark_phase "append_reversions" "SKIPPED" "all abandoned-version rows for $slug already present (idempotent)"
    fi
    return 0
  fi
  # Surface the gated count so a PARTIALLY-gated fan-out (mixed orphan + none) is
  # observable in the report rather than silently under-reported as a plain append.
  local pass_detail="appended ${appended} re-version row(s) for $slug (final $rv_final)"
  [[ "$gated" -gt 0 ]] && pass_detail="${pass_detail}; gated ${gated} (no orphan tag: ${gated_list})"
  mark_phase "append_reversions" "PASS" "$pass_detail"
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

# ─── Phase 9.2: lint_release_notes (§3.2 note-content close gate) ─────────────
#
# Binds release-notes-standard.md §3.2 "Lint failures block Milestone close" to
# the CLOSE EVENT (any authoring path), not just the release-executor self-lint.
# Runs AFTER scaffold (the note now exists — whether scaffolded this run or
# authored ahead by the operator) and BEFORE commit / milestone-close, so a
# finding aborts the close before post_close_milestone.
#
# Exit contract is INHERITED from lint_release_corpus.py (mirrors deploy.sh
# Check 20), NOT invented:
#   0 → clean (proceed)
#   1 → content finding(s); BLOCK iff ≥1 finding names ${VERSION}_RELEASE_NOTES.md.
#       Findings for ONLY other (legacy) versions do NOT block this close
#       (audit-baseline discipline — a pre-existing non-conformant note for an
#       unrelated version must not block this version's close).
#   3 → path-resolution failure (CORPUS-PATH-UNRESOLVED); BLOCK as unverifiable,
#       never a vacuous pass (#459 fail-loud).
# Version scoping lives in this CALLER (grep on the note path the lint already
# prints in every finding line) — no --version flag added to the lint, so the
# lint's interface stays decoupled from this binding.
#
# Idempotent with release-executor Mode E's self-lint: identical read-only
# command, lint mutates nothing — running it twice in one close is safe. Dry-run
# RUNS the lint (side-effect-free) so the operator sees findings at the review
# gate; this is shift-left value, not a DRY-RUN skip.
phase_lint_release_notes() {
  local lint_script="${REPO_ROOT}/core/deploy/tools/lint_release_corpus.py"
  local note_rel="release/releases/notes/${VERSION}_RELEASE_NOTES.md"

  if [[ ! -f "$lint_script" ]]; then
    mark_phase "lint_release_notes" "FAIL" "lint tooling missing: ${lint_script} — cannot enforce the §3.2 note-content close gate"
    return 1
  fi
  if [[ ! -x "/usr/bin/python3" ]]; then
    mark_phase "lint_release_notes" "FAIL" "/usr/bin/python3 not executable; cannot run the §3.2 note-content lint"
    return 1
  fi

  local out exit_code=0
  out="$(/usr/bin/python3 "$lint_script" --check note-content 2>&1)" || exit_code=$?

  if [[ $exit_code -eq 3 ]]; then
    mark_phase "lint_release_notes" "FAIL" "path-resolution failure (exit 3): $(echo "$out" | /usr/bin/head -1) — corpus unverifiable; close BLOCKED (fail-loud)"
    echo "$out" | /usr/bin/head -20 >&2
    return 1
  fi

  if [[ $exit_code -ne 0 ]]; then
    # Scope to the version being closed: grep the finding lines for THIS note's
    # repo-root-relative path (the lint emits it in every finding).
    local v_findings
    v_findings="$(echo "$out" | /usr/bin/grep -F "$note_rel" || true)"
    if [[ -n "$v_findings" ]]; then
      mark_phase "lint_release_notes" "FAIL" "§3.2 note-content finding(s) for ${VERSION} — close BLOCKED per release-notes-standard.md §3.2 'Lint failures block Milestone close'"
      echo "$v_findings" >&2
      return 1
    fi
    # Findings exist but none for THIS version → pre-existing legacy debt for
    # another version; do NOT block this close on it (audit-baseline discipline).
    local legacy_count
    legacy_count="$(echo "$out" | /usr/bin/grep -c . || true)"
    mark_phase "lint_release_notes" "PASS" "no §3.2 finding for ${VERSION} (${legacy_count} pre-existing legacy finding(s) for other versions — out of scope for this close)"
    return 0
  fi

  mark_phase "lint_release_notes" "PASS" "§3.2 note-content clean for ${VERSION}"
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

  # (0) Version-less SKIP — CHANGELOG is keyed on `## [vX.Y]`; a version-less
  # release has no version to key an entry on, so there is nothing to write
  # (#2048 — mirrors the phase_bump_version version-less SKIP. Previously this
  # phase had no version-less branch and would have emitted `## [<slug>]`).
  if is_version_less; then
    mark_phase "append_changelog" "SKIPPED" \
      "version-less release ('$VERSION'): no ## [vX.Y] key to write; CHANGELOG intentionally untouched"
    return 0
  fi

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

# ─── Phase 9.55: assert_derived_surfaces (AC1 anchor A3) ─────────────────────
#
# The note is not the only surface a Stage-13 close writes. phase_append_changelog
# copies the note's frontmatter `summary:` into CHANGELOG.md, and
# phase_append_release_digest writes a DIGEST H3 whose headline falls back to a
# placeholder when the note does not exist yet — it runs at 8.x, BEFORE the note is
# scaffolded at 9.1, so on the unattended path it emits a placeholder every time.
# Both surfaces therefore persist scaffold residue even when the note is authored
# afterwards, which is precisely how the live corpus accumulated its placeholder rows.
# The §3.2 note lint never looked at either surface.
#
# VERSION-SCOPED BY CONSTRUCTION — the single most important property of this phase.
# It reads ONLY the closing version's CHANGELOG H2 block and DIGEST H3 line, never
# either file whole. Pre-existing placeholder rows for already-shipped versions are
# owned by a separate data-backfill work item; a corpus-wide scan here would block
# every future close on legacy debt. This is the same audit-baseline discipline
# phase_lint_release_notes applies when it greps its findings for THIS version's path.
#
# Read-only and idempotent — it asserts, never mutates, so a resumed close re-runs it
# safely. Dry-run RUNS it (side-effect-free) so the operator sees findings at the
# review gate rather than after the commit, mirroring phase_lint_release_notes.
#
# Version-less releases: CHANGELOG is SKIPPED (there is no `## [vX.Y]` key to slice —
# mirrors phase_append_changelog step (0)); the DIGEST assertion still runs, because
# phase_append_release_digest writes an H3 for a version-less release too.
phase_assert_derived_surfaces() {
  local changelog_path="$REPO_ROOT/CHANGELOG.md"

  local _tokens
  if ! _tokens="$(scaffold_residue_tokens)"; then
    mark_phase "assert_derived_surfaces" "FAIL" "scaffold-residue token set unreadable from ${LINT_RELEASE_CORPUS} (--print-scaffold-tokens) — derived-surface residue cannot be evaluated; failing loud rather than passing vacuously (#459)"
    return 1
  fi

  # Slice extractors emit "<file-line-number><TAB><line>" so a finding can name the
  # real line in the real file. Header matching is literal (index()==1), not regex,
  # so a version containing '.' needs no escaping and cannot mis-anchor.
  local _cl_slice="" _dg_slice=""
  if is_version_less; then
    :   # CHANGELOG has no version key for a version-less release — nothing to slice.
  elif [[ -f "$changelog_path" ]]; then
    _cl_slice="$(/usr/bin/awk -v v="$VERSION" '
      /^## / {
        if (started) { exit }
        if (index($0, "## [" v "]") == 1 || index($0, "## " v " ") == 1) { started = 1; print NR "\t" $0; next }
        next
      }
      started { print NR "\t" $0 }
    ' "$changelog_path")"
  fi
  if [[ -f "$RELEASE_DIGEST" ]]; then
    # The DIGEST entry is a single H3 line: `### vX.Y (date) — headline`.
    _dg_slice="$(/usr/bin/awk -v v="$VERSION" '
      index($0, "### " v " ") == 1 || index($0, "### " v "(") == 1 { print NR "\t" $0 }
    ' "$RELEASE_DIGEST")"
  fi

  local _tok _hit _surface _line
  while IFS= read -r _tok; do
    [[ -z "$_tok" ]] && continue
    for _surface in CHANGELOG DIGEST; do
      local _slice _file
      if [[ "$_surface" == "CHANGELOG" ]]; then _slice="$_cl_slice"; _file="CHANGELOG.md"
      else _slice="$_dg_slice"; _file="release/releases/RELEASE_DIGEST.md"; fi
      [[ -z "$_slice" ]] && continue
      _hit="$(printf '%s\n' "$_slice" | /usr/bin/grep -F -- "$_tok" | /usr/bin/head -1 || true)"
      if [[ -n "$_hit" ]]; then
        _line="${_hit%%$'\t'*}"
        mark_phase "assert_derived_surfaces" "FAIL" "unfilled scaffold residue on a derived surface: ${_file}:${_line} in the ${VERSION} entry carries token '${_tok}' — author the release note and re-derive the entry before close-out (release-notes-standard.md § Part 5 Layer-1 dual-write)"
        return 1
      fi
    done
  done <<< "$_tokens"

  local _detail="${VERSION} entries clean"
  if is_version_less; then
    _detail="${_detail} (CHANGELOG SKIPPED — version-less release has no ## [vX.Y] key; DIGEST asserted)"
  elif [[ -z "$_cl_slice" ]]; then
    _detail="${_detail} (no CHANGELOG entry for ${VERSION} yet — nothing to assert)"
  fi
  [[ -z "$_dg_slice" ]] && _detail="${_detail} (no DIGEST entry for ${VERSION} yet)"
  mark_phase "assert_derived_surfaces" "PASS" "$_detail"
  return 0
}

# ─── Phase 9.6: bump_version ─────────────────────────────────────────────────
#
# Stamp the repo-root .version source-of-truth to $VERSION on a *versioned*
# release, so the SessionStart version-skew hook (core/hooks/notify-version-skew.sh)
# reads the shipped version instead of a frozen stale one. .version is the
# platform's version source-of-truth; nothing in the release pipeline previously
# owned its bump, so it survived as an unwritten manual habit that became
# permanently absent once Stage 13 was automated (#1643 — PROC + HAND class).
#
# SKIP-with-PASS for version-less / non-vX.Y $VERSION (D-A: recorded log line) —
# mirrors the phase_append_changelog pre-CHANGELOG SKIP idiom. There is nothing
# to stamp for a version-less release, so the file is intentionally left untouched
# and the no-op is made auditable rather than silent.
#   NOTE: line ~1501 `validate_version "$VERSION" || die` means the script
#   normally never reaches this phase with an invalid $VERSION; the in-phase SKIP
#   guard is defensive + forward-compatible (and is what --self-test / the
#   regression test exercise when invoking the phase directly).
# Idempotent: no-op if .version already == $VERSION (re-run safe; satisfies AC-2).
# Write mechanism: printf to a temp file + mv (atomic; single trailing-newline
# line — the exact shape the hook's `head -1 | tr -d '[:space:]'` expects).
# Staging: this phase WRITES but does not `git add`; staging happens in
# phase_commit_chore_pr via the files=() array (write/stage separation the script
# already uses for the other corpus surfaces).
phase_bump_version() {
  local version_file="$REPO_ROOT/.version"

  # (1) SKIP gate — version-less / non-vX.Y $VERSION (D-A: explicit recorded line).
  if ! validate_version "$VERSION"; then
    mark_phase "bump_version" "SKIPPED" \
      "version-less / non-vX.Y release ('$VERSION'): .version intentionally left untouched (no version to stamp)"
    return 0
  fi

  # (2) Defensive: source file must exist (advisory — mirror snapshot consumers).
  if [[ ! -f "$version_file" ]]; then
    mark_phase "bump_version" "SKIPPED" ".version not present at repo root; nothing to stamp"
    return 0
  fi

  # (3) Idempotency guard — already at target.
  local current
  current="$(/usr/bin/head -1 "$version_file" 2>/dev/null | /usr/bin/tr -d '[:space:]')"
  if [[ "$current" == "$VERSION" ]]; then
    mark_phase "bump_version" "SKIPPED" ".version already == $VERSION (idempotency guard)"
    return 0
  fi

  # (4) Dry-run preview.
  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "bump_version" "DRY-RUN" "would write .version: '$current' -> '$VERSION' (staged in commit_chore_pr)"
    return 0
  fi

  # (5) Apply — write atomically (printf to temp + mv keeps a single clean line).
  if /usr/bin/printf '%s\n' "$VERSION" > "${version_file}.tmp" 2>/dev/null \
     && /bin/mv "${version_file}.tmp" "$version_file" 2>/dev/null; then
    mark_phase "bump_version" "PASS" "wrote .version: '$current' -> '$VERSION' (staged by commit_chore_pr files[])"
    return 0
  fi
  /bin/rm -f "${version_file}.tmp" 2>/dev/null || true
  mark_phase "bump_version" "FAIL" "failed to write .version"
  return 3
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
| release/releases/RELEASE_LOG.md | EDIT | Transition ${slug} row state DEPLOYED → VERIFIED (Surface 3 of Layer-1 dual-write) + inject \`**Outcome:**\` on the visible-H4 Deployment Log block |
| release/releases/RELEASE_INDEX.md | EDIT | Append ${slug} row per D6 |
| release/releases/RELEASE_DIGEST.md | EDIT | Prepend \`### ${VERSION} (date) — …\` H3 under the topmost working H2 per D6 |
| release/releases/RELEASE_REVERSIONS.md | EDIT | Append re-version row(s) — one per abandoned version — ONLY when this release re-versioned mid-pipeline (N/A on the common no-collision path) |
| release/releases/notes/${VERSION}_RELEASE_NOTES.md | NEW | Scaffolded per release-notes-standard.md Part 1 Template; operator-filled prose |
| CHANGELOG.md | EDIT | Prepend ## [${slug}] - YYYY-MM-DD section per Keep-a-Changelog 1.1.0 (Surface 2 of Layer-1 dual-write — SKIPPED if CHANGELOG.md absent) |
| .version | EDIT | Stamp repo-root .version source-of-truth to ${VERSION} (release-cut-owned; read by the SessionStart version-skew hook — SKIPPED if version-less) |

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

# ─── Phase 9.9: ledger_guard (#1680 — pre-commit read-modify-write guard) ─────
#
# Before phase_commit_chore_pr stages the 4 append-only ledgers, validate the
# working-tree diff vs origin/main against the §220 I1/I2 invariants (the
# concurrent-conflict doctrine #1092 codified). The platform has no lock
# primitive — git IS the concurrency substrate; this guard makes the tool REFUSE
# to commit a contaminated working copy.
#
# Adversarial-review mitigation: the guard does NOT assert "ONLY my row changed
# vs origin/main" — after a correct §220 concurrent merge, main legitimately
# carries a SIBLING release's additive row, so an exclusive-single-change
# assertion would FALSE-FAIL a correctly-merged concurrent close. Instead it
# encodes the actual invariants the doctrine defines:
#   I1 (additive ledgers — INDEX/DIGEST/CHANGELOG): MY entry is PRESENT in the
#      working tree, and every line REMOVED vs origin/main is one of MINE (a
#      sibling's additive row is an ADD, never a removal — removing a foreign row
#      is contamination).
#   I2 (state-bearing — RELEASE_LOG status): no PRIOR row regressed VERIFIED →
#      DEPLOYED (the dangerous state-lattice case — a blanket side-pick that
#      overwrites a sibling's VERIFIED with my stale DEPLOYED).
# §237 boundary: the `**Outcome:**` / Deployment-Log prose block is I1 (take-both
# / presence), NEVER I2 — this guard does not apply the status-lattice rule to it.
phase_ledger_guard() {
  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "ledger_guard" "DRY-RUN" "would validate the 4-ledger working-tree diff vs origin/main against §220 I1 (additive: no foreign-row removal) + I2 (no VERIFIED→DEPLOYED regression)"
    return 0
  fi

  local guard_findings=""

  # I1 — additive ledgers: assert no line containing a FOREIGN `| vX.Y |` row (or
  # `### vX.Y` DIGEST entry) was REMOVED vs origin/main. A removed line that names
  # a version OTHER than mine is contamination (a 3-way merge that clobbered a
  # sibling's additive entry).
  local ledger
  for ledger in "release/releases/RELEASE_INDEX.md" "release/releases/RELEASE_DIGEST.md" "CHANGELOG.md"; do
    [[ -f "$REPO_ROOT/$ledger" ]] || continue
    # Removed lines = diff lines starting with '-' (not the '---' header).
    local removed_foreign
    removed_foreign="$(git_net -C "$REPO_ROOT" diff "origin/main" -- "$ledger" 2>/dev/null \
      | /usr/bin/grep -E '^-' | /usr/bin/grep -vE '^---' \
      | /usr/bin/grep -E '(\| v[0-9]+\.[0-9]|^-### v[0-9]+\.[0-9])' \
      | /usr/bin/grep -vF "$VERSION" || true)"
    if [[ -n "$removed_foreign" ]]; then
      guard_findings="${guard_findings}I1 contention in ${ledger}: a foreign version row/entry was removed vs origin/main (re-sync main + re-apply per §220 I1 additive — take-both, never re-sort). "
    fi
  done

  # I2 — RELEASE_LOG status lattice: assert no PRIOR row regressed VERIFIED →
  # DEPLOYED. Detect a removed `| ... | VERIFIED | ... |` line for a version OTHER
  # than mine whose paired added line shows DEPLOYED (a blanket side-pick that
  # overwrote a sibling's VERIFIED). A simpler robust check: any removed line that
  # carries `| VERIFIED |` for a NON-$VERSION row is an I2 regression candidate.
  if [[ -f "$REPO_ROOT/release/releases/RELEASE_LOG.md" ]]; then
    local regressed
    regressed="$(git_net -C "$REPO_ROOT" diff "origin/main" -- "release/releases/RELEASE_LOG.md" 2>/dev/null \
      | /usr/bin/grep -E '^-' | /usr/bin/grep -vE '^---' \
      | /usr/bin/grep -E '\| VERIFIED \|' \
      | /usr/bin/grep -E '^\-\| v[0-9]+\.[0-9]' \
      | /usr/bin/grep -vF "| $VERSION " || true)"
    if [[ -n "$regressed" ]]; then
      guard_findings="${guard_findings}I2 regression in RELEASE_LOG.md: a prior VERIFIED row for another version was removed/regressed (per-row max over DEPLOYED<VERIFIED — never a blanket side-pick that writes a false audit record). "
    fi
  fi

  if [[ -n "$guard_findings" ]]; then
    mark_phase "ledger_guard" "FAIL" "ledger contention vs origin/main — ${guard_findings}"
    return 3
  fi
  mark_phase "ledger_guard" "PASS" "4-ledger working-tree diff is §220-clean (I1 no-foreign-removal; I2 no VERIFIED→DEPLOYED regression)"
  return 0
}

# ─── Phase 9.95: rebuild_skill_packages (#3322 — .skill package rebuild) ──────
#
# Fold the .skill package rebuild into the Stage-13 chore PR so a release that
# changes a skill's source (or an injected canonical) ships the rebuilt package
# ATOMICALLY with the corpus, BEFORE Milestone close — closing the post-close
# orphan-rebuild gap (a package rebuilt after close cannot attach to the closed
# milestone). Placed downstream of ledger_guard so a guard FAIL (exit 3) aborts
# before this phase mutates the packages/ working tree.
#
# Detection = union of two rules over the release diff:
#   (a) direct source — any changed path matching ^(core|operations|release)/
#       skills/<skill>/ → <skill> (covers SKILL.md, references/**, scripts/**,
#       evals/** — everything build-skill-packages.sh's `cp -R` carries).
#   (b) injected canonical — any changed path under core/standards/ or
#       operations/templates/ whose basename is the middle field of a
#       TEMPLATE_SYNC_MAP entry → every skill in field 1 of a matching entry.
#       Load-bearing: template-*.md inject into a package at build time with no
#       skills/ path of their own, so editing a canonical stales the package
#       while touching zero skills/ path.
# The TEMPLATE_SYNC_MAP is read from deploy.sh AT RUNTIME (never copied) via the
# same awk window build-skill-packages.sh:34–36 uses — single-sourced.
#
# R8 (zip non-determinism): the .skill archive embeds per-entry mtimes, so a
# content-identical rebuild differs at the byte level. Stage a rebuilt package
# ONLY when its content-manifest sidecar (packages/<skill>.skill.sha256) shows a
# working-tree change (or the skill is newly-tracked); otherwise discard the
# mtime-only churn with `git checkout --`. The .skill bytes are NEVER compared.
#
# Staging: this phase WRITES + populates REBUILT_PACKAGES=(); it does not `git
# add` (write/stage separation — commit_chore_pr stages via files=()).
# --no-merge: pre-commit phase; does NOT defer (the chore PR is still created, so
# the rebuild must ride its commit) — hence no NO_MERGE guard here and no entry
# in either deferral list.

# changed_skills_from_paths — pure function: read newline-separated changed paths
# on stdin, emit the deduped candidate skill set (one per line) per rules (a)+(b).
# Offline: its only external read is deploy.sh's TEMPLATE_SYNC_MAP.
changed_skills_from_paths() {
  local deploy_sh="$REPO_ROOT/core/deploy/deploy.sh"
  # (b) reverse TEMPLATE_SYNC_MAP: canonical-basename -> skills. Read the map from
  # deploy.sh at runtime — same awk window as build-skill-packages.sh:34–36.
  local map=""
  if [[ -f "$deploy_sh" ]]; then
    map="$(/usr/bin/awk '/^TEMPLATE_SYNC_MAP=\(/,/^\)/' "$deploy_sh" 2>/dev/null \
      | /usr/bin/grep -E '^[[:space:]]*"[^"]+:[^"]+:[^"]+"' \
      | /usr/bin/sed 's/^[[:space:]]*"//; s/"$//; s/[[:space:]]*#.*//' || true)"
  fi
  local path base entry m_skill m_canonical
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    # (a) direct source
    if [[ "$path" =~ ^(core|operations|release)/skills/([^/]+)/ ]]; then
      /usr/bin/printf '%s\n' "${BASH_REMATCH[2]}"
    fi
    # (b) injected canonical
    case "$path" in
      core/standards/*|operations/templates/*)
        base="$(/usr/bin/basename "$path")"
        while IFS= read -r entry; do
          [[ -z "$entry" ]] && continue
          m_skill="${entry%%:*}"
          m_canonical="${entry#*:}"; m_canonical="${m_canonical%%:*}"
          [[ "$m_canonical" == "$base" ]] && /usr/bin/printf '%s\n' "$m_skill"
        done <<< "$map"
        ;;
    esac
  done | /usr/bin/sort -u | /usr/bin/grep -vE '^$' || true
}

phase_rebuild_skill_packages() {
  local builder="$REPO_ROOT/core/deploy/tools/build-skill-packages.sh"

  # Resolve the release-diff path set: MERGE_SHA first-parent diff, else the
  # release PR's file list. D-4d: if BOTH yield an empty set, staleness is
  # undeterminable → FAIL loud (never SKIP — a silent SKIP re-opens the gap).
  local changed=""
  if [[ -n "$MERGE_SHA" ]]; then
    changed="$($GIT -C "$REPO_ROOT" diff --name-only "${MERGE_SHA}^1" "${MERGE_SHA}" 2>/dev/null || true)"
  fi
  if [[ -z "$changed" ]]; then
    changed="$($GH pr view "$PR_NUMBER" --repo "$REPO_SLUG" --json files --jq '.files[].path' 2>/dev/null || true)"
  fi
  if [[ -z "$changed" ]]; then
    mark_phase "rebuild_skill_packages" "FAIL" "release diff base unresolvable (MERGE_SHA empty + gh pr view fallback empty) — .skill staleness undeterminable; re-run --apply once the release-PR merge SHA resolves, or rebuild + stage the affected package(s) per core/rules/skill-deployment.md before closing"
    return 3
  fi

  # Detection (rules a+b). || true keeps set -e safe on a zero-candidate diff.
  local candidates
  candidates="$(/usr/bin/printf '%s\n' "$changed" | changed_skills_from_paths || true)"

  if [[ -z "$candidates" ]]; then
    mark_phase "rebuild_skill_packages" "N/A" "no skill source or injected canonical changed in the release diff — no package to rebuild (0 deferred)"
    return 0
  fi

  local names count
  names="$(/usr/bin/printf '%s' "$candidates" | /usr/bin/tr '\n' ' ' | /usr/bin/sed 's/ *$//')"
  count="$(/usr/bin/printf '%s\n' "$candidates" | /usr/bin/grep -c . || true)"

  # Dry-run: enumerate only (a --dry-run creates no chore branch + no diff).
  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "rebuild_skill_packages" "DRY-RUN" "would rebuild ${count} package(s): ${names}"
    return 0
  fi

  # Apply: rebuild, then sidecar-gate the staging set (R8).
  if [[ ! -x "$builder" ]]; then
    mark_phase "rebuild_skill_packages" "FAIL" "build-skill-packages.sh not executable at $builder"
    return 3
  fi

  # Guarded call (M3-3): the builder runs set -euo pipefail + exit 1 on failure;
  # the subshell isolates its set -e so its exit does not abort this script
  # before mark_phase runs. Word-split $candidates into per-skill args.
  if ! ( /bin/bash "$builder" $candidates ) >/dev/null 2>&1; then
    mark_phase "rebuild_skill_packages" "FAIL" "build-skill-packages.sh failed for one of: ${names} — package(s) not rebuilt; close blocked (re-run after resolving the build error)"
    return 3
  fi

  # R8 content-sidecar gate: stage a package ONLY when its .sha256 sidecar shows a
  # working-tree change (real content drift) OR the skill is newly-tracked;
  # otherwise revert the mtime-only zip churn so it cannot enter the commit.
  REBUILT_PACKAGES=()
  local skill pkg sidecar sidecar_changed pkg_untracked
  for skill in $candidates; do
    pkg="packages/${skill}.skill"
    sidecar="packages/${skill}.skill.sha256"
    sidecar_changed="$($GIT -C "$REPO_ROOT" diff --name-only -- "$sidecar" 2>/dev/null || true)"
    pkg_untracked="$($GIT -C "$REPO_ROOT" ls-files --others --exclude-standard -- "$pkg" "$sidecar" 2>/dev/null || true)"
    if [[ -n "$sidecar_changed" || -n "$pkg_untracked" ]]; then
      REBUILT_PACKAGES+=("$pkg" "$sidecar")
    else
      # Content-identical rebuild — discard mtime-only churn (never compare bytes).
      $GIT -C "$REPO_ROOT" checkout -- "$pkg" "$sidecar" 2>/dev/null || true
    fi
  done

  if [[ ${#REBUILT_PACKAGES[@]} -eq 0 ]]; then
    mark_phase "rebuild_skill_packages" "PASS" "${count} skill(s) rebuilt (${names}); all content-identical by sidecar — nothing to stage (0 deferred)"
    return 0
  fi

  mark_phase "rebuild_skill_packages" "PASS" "rebuilt + staged ${#REBUILT_PACKAGES[@]} package file(s) for: ${names} (content-sidecar drift; 0 deferred)"
  return 0
}

phase_commit_chore_pr() {
  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "commit_chore_pr" "DRY-RUN" "would: git add RELEASE_LOG.md RELEASE_INDEX.md RELEASE_DIGEST.md RELEASE_REVERSIONS.md (if re-versioned) RELEASE_NOTES.md CHANGELOG.md (if present) .version (if versioned) packages/<skill>.skill + .sha256 (per rebuilt skill) && git commit -m 'chore(${VERSION}): Stage 13 — INDEX + DIGEST + RELEASE_NOTES + CHANGELOG'"
    return 0
  fi

  local files=(
    "release/releases/RELEASE_LOG.md"
    "release/releases/RELEASE_INDEX.md"
    "release/releases/RELEASE_DIGEST.md"
    "release/releases/RELEASE_REVERSIONS.md"
    "release/releases/notes/${VERSION}_RELEASE_NOTES.md"
    "CHANGELOG.md"
    ".version"
    "${REBUILT_PACKAGES[@]:-}"      # .skill packages + .sha256 sidecars staged by
  )                                 # phase_rebuild_skill_packages (Phase 9.95); empty
                                    # on a release that touches no skill source.

  # Stage only files that actually exist + have changes
  local staged=0
  for f in "${files[@]}"; do
    [[ -z "$f" ]] && continue       # "${ARR[@]:-}" on an empty array yields one
                                    # empty element under bash 3.2 + set -u
    if [[ -f "$REPO_ROOT/$f" ]]; then
      $GIT -C "$REPO_ROOT" add "$f" 2>/dev/null || true
      staged=1
    fi
  done

  if [[ -z "$($GIT -C "$REPO_ROOT" diff --staged --name-only 2>/dev/null)" ]]; then
    mark_phase "commit_chore_pr" "SKIPPED" "nothing staged — phases 6-9 + 9.5 + 9.6 were no-op (already up-to-date)"
    return 0
  fi

  local commit_msg="chore(${VERSION}): Stage 13 — INDEX + DIGEST + RELEASE_NOTES + CHANGELOG"
  if $GIT -C "$REPO_ROOT" commit -m "$commit_msg" >/dev/null 2>&1; then
    # Staging-completeness assertion (#3322 E9): every path phase_rebuild_skill_
    # packages reported as staged MUST be in the commit just created. Reads the
    # COMMIT, not the phase's own report — the phase does not certify itself.
    # Structurally general: catches the same omission for any future phase that
    # populates REBUILT_PACKAGES.
    local _committed _missing="" _rp
    _committed="$($GIT -C "$REPO_ROOT" diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null || true)"
    for _rp in "${REBUILT_PACKAGES[@]:-}"; do
      [[ -z "$_rp" ]] && continue
      /usr/bin/printf '%s\n' "$_committed" | /usr/bin/grep -qxF "$_rp" || _missing="${_missing}${_rp} "
    done
    if [[ -n "$_missing" ]]; then
      mark_phase "commit_chore_pr" "FAIL" "staging-completeness: rebuilt package(s) NOT in the chore commit — ${_missing% }; the chore PR would ship a stale package while every phase reported PASS"
      return 3
    fi
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

  # Zero-commit guard (#1705): a chore PR with no commits ahead of main either
  # errors at `gh pr create` or creates an empty PR that can never merge —
  # STRANDING the 4 terminal phases (post_close → manual_close → verify → publish
  # → drift → orphan → pattern). The guard distinguishes the two zero-commit
  # causes (adversarial-review mitigation):
  #   (a) idempotent re-run — the corpus already merged to main (DIGEST H3 +
  #       INDEX row + NOTES file present on origin/main) → SKIP create + skip
  #       await BENIGNLY, terminal phases proceed (un-stranding).
  #   (b) FIRST-run no-op bug — 0 commits AND the corpus is NOT on main → FAIL
  #       loudly rather than skip into a broken publish (publish reads the NOTES
  #       file and would FAIL or publish an empty body).
  # The check only runs in --apply (dry-run never pushes/commits).
  if [[ "$MODE" != "dry-run" ]]; then
    local commits_ahead
    commits_ahead="$(git_net -C "$REPO_ROOT" rev-list --count "origin/main..${CHORE_BRANCH}" 2>/dev/null || echo 0)"
    if [[ "$commits_ahead" -eq 0 ]]; then
      # Corpus-presence-on-main gate: only SKIP benignly if the close outputs are
      # actually already on main (idempotent re-run), else FAIL loud.
      local _dig_on_main _idx_on_main _notes_on_main _corpus_present=1
      _dig_on_main="$(git_net -C "$REPO_ROOT" show "origin/main:release/releases/RELEASE_DIGEST.md" 2>/dev/null | /usr/bin/grep -cE "^### ${VERSION//./\\.}[[:space:](]" || true)"
      _idx_on_main="$(git_net -C "$REPO_ROOT" show "origin/main:release/releases/RELEASE_INDEX.md" 2>/dev/null | /usr/bin/grep -cE "^\|[[:space:]]*${VERSION//./\\.}[[:space:]]*\|" || true)"
      _notes_on_main="$(git_net -C "$REPO_ROOT" cat-file -e "origin/main:release/releases/notes/${VERSION}_RELEASE_NOTES.md" 2>/dev/null && echo 1 || echo 0)"
      [[ "${_dig_on_main:-0}" -ge 1 && "${_idx_on_main:-0}" -ge 1 && "${_notes_on_main:-0}" -ge 1 ]] || _corpus_present=0
      if [[ "$_corpus_present" -eq 1 ]]; then
        CHORE_PR_SKIPPED=1
        mark_phase "create_chore_pr" "SKIPPED" "0 commits ahead of origin/main and the close outputs (DIGEST H3 + INDEX row + NOTES) are already present on main — idempotent re-run; terminal phases proceed"
        return 0
      fi
      mark_phase "create_chore_pr" "FAIL" "0 commits ahead of origin/main but the close outputs are NOT on main (DIGEST=${_dig_on_main:-0}/INDEX=${_idx_on_main:-0}/NOTES=${_notes_on_main:-0}) — the scaffold/commit phases no-op'd on a FIRST run (a real bug); failing loud rather than skipping into a broken publish"
      return 3
    fi
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
  # Zero-commit SKIP propagation (#1705): if phase_create_chore_pr SKIPped on the
  # idempotent already-up-to-date path, there is no PR to merge — SKIP gracefully
  # so the terminal phases proceed (un-stranding).
  if [[ "$CHORE_PR_SKIPPED" -eq 1 ]]; then
    mark_phase "await_merge_chore_pr" "SKIPPED" "chore PR was SKIPPED (0 commits ahead, corpus already on main) — nothing to merge"
    return 0
  fi

  # --no-merge mode (#1705): create-only — leave the PR for the operator to merge.
  if [[ "$NO_MERGE" -eq 1 ]]; then
    mark_phase "await_merge_chore_pr" "SKIPPED" "--no-merge: chore PR #${CHORE_PR_NUMBER:-?} left open for operator merge (no poll/merge)"
    return 0
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "await_merge_chore_pr" "DRY-RUN" "would poll mergeStateStatus (CI-realistic budget ~${MERGE_TIMEOUT}s; BLOCKED/UNSTABLE = keep-polling) then gh pr merge --merge --delete-branch"
    return 0
  fi

  if [[ -z "$CHORE_PR_NUMBER" ]]; then
    mark_phase "await_merge_chore_pr" "FAIL" "no chore PR number recorded"
    return 3
  fi

  # CI-realistic poll budget (#1705). The prior 30s cap was a detection-pending
  # budget (GitHub computing mergeability), NOT a CI-completion budget — a real
  # chore PR must wait for required status checks to go green before
  # MERGEABLE/CLEAN. Poll with a fixed 10s step up to MERGE_TIMEOUT (default 300s,
  # tunable via --merge-timeout). MERGEABLE/BLOCKED + MERGEABLE/UNSTABLE are
  # KEEP-POLLING states (checks pending / non-required-failing), not terminal —
  # only CONFLICTING / DIRTY HALT; only CLEAN proceeds to merge.
  local step="$MERGE_POLL_STEP"
  local elapsed=0
  local merge_state="UNKNOWN"
  while [[ "$elapsed" -lt "$MERGE_TIMEOUT" ]]; do
    merge_state="$($GH pr view "$CHORE_PR_NUMBER" --repo "$REPO_SLUG" --json mergeStateStatus,mergeable --jq '"\(.mergeable)/\(.mergeStateStatus)"' 2>/dev/null || echo "ERROR")"
    case "$merge_state" in
      MERGEABLE/CLEAN) break ;;
      CONFLICTING/*|MERGEABLE/DIRTY) mark_phase "await_merge_chore_pr" "FAIL" "merge state=$merge_state; HALT — escalate Tier 2 [SCOPE CHANGE]"; return 3 ;;
      # MERGEABLE/BLOCKED, MERGEABLE/UNSTABLE, */UNKNOWN, ERROR → keep polling
    esac
    /bin/sleep "$step"
    elapsed=$((elapsed + step))
  done

  if [[ "$merge_state" != "MERGEABLE/CLEAN" ]]; then
    mark_phase "await_merge_chore_pr" "FAIL" "merge state still=$merge_state after ${elapsed}s polling (budget ${MERGE_TIMEOUT}s) — escalate (raise --merge-timeout if CI runs longer, or --no-merge to leave the PR for manual merge)"
    return 3
  fi

  if $GH pr merge "$CHORE_PR_NUMBER" --repo "$REPO_SLUG" --merge --delete-branch >/dev/null 2>&1; then
    mark_phase "await_merge_chore_pr" "PASS" "merged PR #${CHORE_PR_NUMBER} (after ${elapsed}s poll)"
    return 0
  fi
  mark_phase "await_merge_chore_pr" "FAIL" "gh pr merge failed"
  return 3
}

# ─── Phase 12.5: reparse_ledgers (#1680 — post-merge structural re-parse) ─────
#
# DETECTIVE-ONLY post-merge validation that the 3-way auto-merge landed a
# well-formed corpus on main. After phase_await_merge_chore_pr succeeds, fetch
# origin/main and structurally validate each of the 4 ledgers against #667's
# CORRECTED schema (this is why #1680 builds AFTER #667 — the assertions must
# encode the 6-col INDEX / H3 DIGEST shape, not the broken one):
#   (a) RELEASE_INDEX — MY version row present, 6-column (no row with ≠6 fields);
#   (b) RELEASE_DIGEST — exactly one `### vX.Y (` H3 for my version under the
#       topmost working H2 (NOT duplicated — the §220 dedup);
#   (c) RELEASE_LOG — exactly one row for my version; no DEPLOYED-regression on a
#       previously-VERIFIED row;
#   (d) CHANGELOG — `## [vX.Y]` block present once (SKIP if pre-CHANGELOG).
# §237 boundary: the `**Outcome:**`/Deployment-Log prose block is I1 (presence/
# dedup), NEVER I2 — this re-parse does not state-lattice it. On a structural
# break → FAIL "manual reconcile required"; it NEVER auto-fixes (re-emitting a
# merged ledger is out of scope). SKIPs cleanly when the chore PR was SKIPPED
# (#1705 zero-commit) or under --no-merge (nothing newly merged to re-parse).
phase_reparse_ledgers() {
  if [[ "$CHORE_PR_SKIPPED" -eq 1 ]]; then
    mark_phase "reparse_ledgers" "SKIPPED" "chore PR SKIPPED (zero-commit) — corpus already on main; nothing newly merged to re-parse"
    return 0
  fi
  if [[ "$NO_MERGE" -eq 1 ]]; then
    mark_phase "reparse_ledgers" "SKIPPED" "--no-merge: chore PR not merged; post-merge re-parse N/A"
    return 0
  fi
  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "reparse_ledgers" "DRY-RUN" "would fetch origin/main and structurally validate the 4 ledgers (6-col INDEX / single H3 DIGEST / single LOG row + no VERIFIED→DEPLOYED regression / single CHANGELOG block)"
    return 0
  fi

  git_net -C "$REPO_ROOT" fetch origin main >/dev/null 2>&1 || true
  local reparse_findings=""
  local vkey="${VERSION//./\\.}"

  # (a) RELEASE_INDEX — my row present + 6-column.
  local idx_content; idx_content="$(git_net -C "$REPO_ROOT" show "origin/main:release/releases/RELEASE_INDEX.md" 2>/dev/null || echo "")"
  local idx_row; idx_row="$(/usr/bin/printf '%s\n' "$idx_content" | /usr/bin/grep -E "^\|[[:space:]]*${vkey}[[:space:]]*\|" | /usr/bin/head -1)"
  if [[ -z "$idx_row" ]]; then
    reparse_findings="${reparse_findings}INDEX: no row for ${VERSION} on main. "
  else
    local idx_pipes; idx_pipes="$(/usr/bin/printf '%s' "$idx_row" | /usr/bin/tr -cd '|' | /usr/bin/wc -c | /usr/bin/tr -d ' ')"
    [[ "$idx_pipes" -eq 7 ]] || reparse_findings="${reparse_findings}INDEX: ${VERSION} row is not 6-column (${idx_pipes} pipes; expected 7). "
  fi

  # (b) RELEASE_DIGEST — exactly one `### vX.Y (` H3.
  local dig_n; dig_n="$(git_net -C "$REPO_ROOT" show "origin/main:release/releases/RELEASE_DIGEST.md" 2>/dev/null | /usr/bin/grep -cE "^### ${vkey}[[:space:](]" || true)"; dig_n="${dig_n:-0}"
  if [[ "$dig_n" -eq 0 ]]; then
    reparse_findings="${reparse_findings}DIGEST: no '### ${VERSION} (' H3 on main. "
  elif [[ "$dig_n" -gt 1 ]]; then
    reparse_findings="${reparse_findings}DIGEST: ${dig_n} duplicate '### ${VERSION}' H3 entries (concurrent merge dup — §220 dedup violated). "
  fi

  # (c) RELEASE_LOG — exactly one row for my version (the status-lattice regression
  # is caught pre-commit by phase_ledger_guard; here we assert single-row presence).
  local log_n; log_n="$(git_net -C "$REPO_ROOT" show "origin/main:release/releases/RELEASE_LOG.md" 2>/dev/null | /usr/bin/grep -cE "^\| ${vkey} \|" || true)"; log_n="${log_n:-0}"
  if [[ "$log_n" -eq 0 ]]; then
    reparse_findings="${reparse_findings}RELEASE_LOG: no row for ${VERSION} on main. "
  elif [[ "$log_n" -gt 1 ]]; then
    reparse_findings="${reparse_findings}RELEASE_LOG: ${log_n} rows for ${VERSION} (duplicate — concurrent merge dup). "
  fi

  # (d) CHANGELOG — `## [vX.Y]` block once (SKIP if pre-CHANGELOG).
  if git_net -C "$REPO_ROOT" cat-file -e "origin/main:CHANGELOG.md" 2>/dev/null; then
    local cl_n; cl_n="$(git_net -C "$REPO_ROOT" show "origin/main:CHANGELOG.md" 2>/dev/null | /usr/bin/grep -cE "^## \[?${vkey}\]?[[:space:]]" || true)"; cl_n="${cl_n:-0}"
    if [[ "$cl_n" -eq 0 ]]; then
      reparse_findings="${reparse_findings}CHANGELOG: no '## [${VERSION}]' block on main. "
    elif [[ "$cl_n" -gt 1 ]]; then
      reparse_findings="${reparse_findings}CHANGELOG: ${cl_n} duplicate '## [${VERSION}]' blocks. "
    fi
  fi

  if [[ -n "$reparse_findings" ]]; then
    mark_phase "reparse_ledgers" "FAIL" "post-merge ledger malformed — ${reparse_findings}— concurrent 3-way auto-merge landed badly per §220; manual reconcile required (this phase never auto-fixes)"
    return 3
  fi
  mark_phase "reparse_ledgers" "PASS" "post-merge corpus structurally well-formed on main (6-col INDEX row / single DIGEST H3 / single LOG row / single CHANGELOG block)"
  return 0
}

# ─── Phase 13: post_close_milestone (Hub Tier-1 mechanical) ──────────────────

phase_post_close_milestone() {
  # --no-merge (#2919): the Stage 13 chore PR is left open for the operator, so the
  # DEPLOYED→VERIFIED transition has NOT landed on main. Closing the milestone now
  # would record a false audit state (main still shows DEPLOYED). Defer per the
  # stage-13-close.md § Phase B sequencing invariant ("chore PR MUST land on main
  # BEFORE Phase C C1 Milestone close"); the operator re-runs --apply post-merge.
  if [[ "$NO_MERGE" -eq 1 ]]; then
    mark_phase "post_close_milestone" "SKIPPED" "DEFERRED under --no-merge — chore PR #${CHORE_PR_NUMBER:-?} left open; milestone #${MILESTONE} close waits for it to land on main (re-run --apply after merge)"
    return 0
  fi

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
  # --no-merge (#2919): D-1 manual issue-close is part of the post-milestone-close
  # ceremony, which itself defers until the chore PR lands on main. Defer here too so
  # the operator's single follow-up --apply (post-merge) performs milestone close +
  # issue close together.
  if [[ "$NO_MERGE" -eq 1 ]]; then
    mark_phase "manual_close_release_issues" "SKIPPED" "DEFERRED under --no-merge — chore PR left open; D-1 issue close waits for milestone-close after merge (re-run --apply)"
    return 0
  fi

  if [[ "$OPEN_ISSUE_COUNT" -eq 0 ]]; then
    mark_phase "manual_close_release_issues" "SKIPPED" "no open release issues to manually close"
    return 0
  fi

  local plan_ref="release/releases/plans/${VERSION}_RELEASE_PLAN.md"
  # Default comment for the genuine auto-close-anomaly case. #38 Defect 1: this
  # generic anomaly text must NOT be the single hardcoded template applied to
  # every issue — a Tier-0 disposition needs the correct comment. Per-issue
  # `--close-comment <N>:"<text>"` overrides the default for issue N.
  local anomaly_template="Manually closed at Stage 13 per D-1 — auto-close anomaly (constituent PRs merged to release branch, not default-branch). Per release plan ${plan_ref}."

  # Resolve the per-issue comment override: scan CLOSE_COMMENTS for an "<N>:<text>"
  # entry; echo the override text if present, else the anomaly default.
  _comment_for() {
    local issue_n="$1" entry e_n e_text
    for entry in "${CLOSE_COMMENTS[@]:-}"; do
      [[ -z "$entry" ]] && continue
      e_n="${entry%%:*}"
      if [[ "$e_n" == "$issue_n" ]]; then
        e_text="${entry#*:}"
        /usr/bin/printf '%s' "$e_text"
        return 0
      fi
    done
    /usr/bin/printf '%s' "$anomaly_template"
  }

  if [[ "$MODE" == "dry-run" ]]; then
    local issue_list
    issue_list="$(/usr/bin/printf '%s' "$OPEN_ISSUE_LIST" | /usr/bin/tr '\n' ',' | /usr/bin/sed 's/,$//')"
    local _override_note=""
    [[ "${#CLOSE_COMMENTS[@]}" -gt 0 ]] && _override_note=" (${#CLOSE_COMMENTS[@]} per-issue --close-comment override(s))"
    mark_phase "manual_close_release_issues" "DRY-RUN" "would close ${OPEN_ISSUE_COUNT} issue(s) [#${issue_list//,/, #}] — anomaly default comment unless overridden${_override_note}"
    return 0
  fi

  local closed_count=0
  while IFS= read -r issue_n; do
    [[ -z "$issue_n" ]] && continue
    local _c; _c="$(_comment_for "$issue_n")"
    if $GH issue close "$issue_n" --repo "$REPO_SLUG" --comment "$_c" >/dev/null 2>&1; then
      closed_count=$((closed_count + 1))
    fi
  done <<< "$OPEN_ISSUE_LIST"

  mark_phase "manual_close_release_issues" "PASS" "closed ${closed_count}/${OPEN_ISSUE_COUNT} release issues per D-1 (per-issue --close-comment overrides honored)"
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
  # Check 4 (#1681): the row-state string is NOT trusted blind — a VERIFIED PASS
  # is corroborated by the merge fact (release PR $PR_NUMBER MERGED to main). In
  # --apply, query `gh pr view`; a VERIFIED string with an unmerged/unresolvable
  # PR reads FALSE-VERIFIED rather than PASS. (Dry-run keeps the string-only read
  # — it is a preview, and the transition guard already fail-loud'd the apply.)
  if [[ "$STATE_LOG_ROW_STATE" == "VERIFIED" ]]; then
    if [[ "$MODE" == "dry-run" ]]; then
      v_log="PASS"
    else
      local _v_pr; _v_pr="$($GH pr view "$PR_NUMBER" --repo "$REPO_SLUG" --json state,baseRefName --jq '"\(.state)/\(.baseRefName)"' 2>/dev/null || echo "")"
      if [[ "$_v_pr" == "MERGED/main" ]]; then v_log="PASS"; else v_log="FALSE-VERIFIED (PR #${PR_NUMBER}=${_v_pr:-<unresolved>})"; fi
    fi
  else
    v_log="PENDING"
  fi
  v_subs="$([[ "$OPEN_ISSUE_COUNT" -eq 0 ]] && echo PASS || echo "PARTIAL (${OPEN_ISSUE_COUNT} open)")"

  VERIFICATION_RESULTS=$(/bin/cat <<EOF
| # | Check | Method | Result |
|---|-------|--------|--------|
| 1 | RELEASE_NOTES.md present | test -f releases/notes/${VERSION}_RELEASE_NOTES.md | ${v_notes} |
| 2 | Annotated tag present | git tag -l ${VERSION} | ${v_tag} |
| 3 | Milestone closed | gh api milestones/${MILESTONE} | ${v_milestone} |
| 4 | RELEASE_LOG row VERIFIED (corroborated by release-PR merge to main) | grep + gh pr view ${PR_NUMBER} | ${v_log} |
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
  # --no-merge (#2919): Surface 1 (the GitHub Release) is published from the
  # RELEASE_NOTES file, which lands on main only when the Stage 13 chore PR merges.
  # Under --no-merge the note is still on the open chore branch, so publishing now
  # would bind a public Release to unmerged content. Defer BEFORE the tag/notes
  # preflights (avoids a needless network call) per the stage-13-close.md § Phase B
  # sequencing invariant; the operator re-runs --apply post-merge.
  if [[ "$NO_MERGE" -eq 1 ]]; then
    mark_phase "publish_github_release" "SKIPPED" "DEFERRED under --no-merge — RELEASE_NOTES land on main only when the chore PR merges; Surface 1 publish waits (re-run --apply after merge)"
    return 0
  fi

  local notes_path="${RELEASE_NOTES_DIR}/${VERSION}_RELEASE_NOTES.md"

  # Preflight 1: tag must exist on origin (Stage 12 Phase B3 push pre-requisite).
  # git_net layers the gh-backed credential helper (locked-Keychain degradation).
  if ! git_net -C "$REPO_ROOT" ls-remote --tags origin "$VERSION" 2>/dev/null | /usr/bin/grep -q "$VERSION"; then
    mark_phase "publish_github_release" "FAIL" "tag $VERSION not present on origin (Stage 12 Phase B3 may not have run; canonical recovery: git push origin $VERSION OR re-invoke Stage 12 spoke)"
    return 3
  fi

  # Preflight 1.5: tag ↔ MERGE_SHA identity assertion (#1682). The tag must point
  # at THIS release's merge commit (captured at read-state from the release PR).
  # If the tag resolves to a different SHA, a Release bound to it would tie to the
  # wrong commit — do NOT publish. Skipped only when MERGE_SHA is unresolved (e.g.
  # gh offline at read-state) — degrade to a warning rather than block on a
  # capture miss, but never publish a KNOWN mismatch.
  if [[ -n "$MERGE_SHA" ]]; then
    local tag_sha
    tag_sha="$(git_net -C "$REPO_ROOT" rev-list -n1 "$VERSION" 2>/dev/null || echo "")"
    if [[ -n "$tag_sha" && "$tag_sha" != "$MERGE_SHA" ]]; then
      mark_phase "publish_github_release" "FAIL" "tag $VERSION points at $tag_sha, not the release-PR merge commit $MERGE_SHA — identity mismatch (#1682); do NOT publish a Release bound to the wrong commit (re-cut the tag at the merge SHA, or re-verify the release PR)"
      return 3
    fi
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

  # MERGE_SHA --target is NON-OPTIONAL on create (#1682): the Release is explicitly
  # bound to the release-PR merge commit (the identity assertion above proved the
  # tag agrees with it). If MERGE_SHA is unresolved (gh offline at read-state),
  # FAIL rather than create an unbound Release — binding is the point of #1682.
  if [[ -z "$MERGE_SHA" ]]; then
    mark_phase "publish_github_release" "FAIL" "MERGE_SHA unresolved (release-PR merge commit not captured at read-state) — cannot bind the GitHub Release --target (#1682); re-run with gh online so the release-PR merge SHA resolves"
    return 3
  fi

  if $GH release create "$VERSION" \
    --repo "$REPO_SLUG" \
    --title "$VERSION — $headline" \
    --notes "$notes_body" \
    --target "$MERGE_SHA" >/dev/null 2>&1; then
    mark_phase "publish_github_release" "PASS" "created GitHub Release $VERSION bound to merge SHA $MERGE_SHA (Surface 1 of Layer-1 dual-write; title='$VERSION — $headline')"
    return 0
  fi
  mark_phase "publish_github_release" "FAIL" "gh release create failed for new release $VERSION (canonical recovery: re-run Phase 15.5 OR invoke release-executor Mode F standalone)"
  return 3
}

# _drift_block_in_scope <version> — is <version> inside the body-drift gate's
# cutoff scope? (Helper for Phase 15.6 below.) Replicates deploy.sh Check 47's
# predicate EXACTLY rather than approximating it with a version compare:
# enumerate RELEASE_LOG rows in FILE order (date-ascending, NOT version-ordered),
# latch on the first row whose version PREFIX-matches the cutoff, and treat the
# contiguous suffix from there to EOF as in scope. A semantic or lexical version
# compare would diverge from Check 47 on exactly the rows where ordering matters,
# reintroducing the two-surfaces-disagree defect this change exists to remove.
# Returns 0 (in scope, block eligible) / 1 (out of scope, warn only).
# Out of scope on: the __none__ opt-out, an unreadable LOG, or a version carrying
# no LOG row. The last case is unreachable on the close path (preflight already
# asserts this version's DEPLOYED row exists); defaulting it OUT means a missing
# row can never manufacture a block.
_drift_block_in_scope() {
  local _v="$1"
  if [[ "$DRIFT_CHECK_CUTOFF" == "__none__" ]]; then return 1; fi
  if [[ ! -f "$RELEASE_LOG" ]]; then return 1; fi
  local _rows _row _past=0
  _rows="$(/usr/bin/grep -E '^\|[[:space:]]*v[0-9]+\.[0-9]+' "$RELEASE_LOG" 2>/dev/null \
    | /usr/bin/awk -F ' \\| ' '{
        v=$1; sub(/^\|[[:space:]]*/,"",v); sub(/[[:space:]]*$/,"",v); print v
      }')" || _rows=""
  while IFS= read -r _row; do
    if [[ -z "$_row" ]]; then continue; fi
    if [[ "$_past" -eq 0 && "$_row" == "$DRIFT_CHECK_CUTOFF"* ]]; then _past=1; fi
    if [[ "$_past" -eq 0 ]]; then continue; fi
    if [[ "$_row" == "$_v" ]]; then return 0; fi
  done <<<"$_rows"
  return 1
}

# ─── Phase 15.6: check_release_body_drift (post-emit §5.1 drift assert) ──────────
#
# DETECTIVE-ONLY post-emit verification that the just-published Release body
# equals the frontmatter-stripped in-repo note (release-notes-standard.md §5.1).
# Runs AFTER phase_publish_github_release converges Surface 1 — a standing assert
# that the emit landed the canonical body, catching the v2.26-class defect
# (ad-hoc body / un-stripped frontmatter) on the mandated close path.
#
# This phase COEXISTS with phase_lint_release_notes (§3.2 note-content close
# gate): that phase lints the in-repo note file (network-free, BLOCKS close on a
# this-version finding); THIS phase compares the published Release body against
# the note (network-dependent). Distinct concerns, distinct phases.
#
# BLOCKING ON GENUINE DRIFT ONLY. Tool exit 1 (the published body differs from the
# frontmatter-stripped note) marks FAIL and returns non-zero, which the dispatch
# tail turns into a report-and-exit. This RECONCILES the implementation to the
# governance surface that already specifies it — stage-13-close.md's Phase B5.6
# states "A failure blocks closure: the canonical note is corrected first, then all
# surfaces re-emit from it per §5.6" — it does not escalate past it. The prior
# "close NOT blocked" marks were the drifted half of that pair.
#
# EXIT 2 (a needed capability is absent) and EXIT 3 (no published Release / no note
# to compare) STAY NON-BLOCKING, deliberately. Those are the mid-close timing
# states: Surface 1 not yet published, or the note not yet on origin/main. Blocking
# them is the reflexive-pipeline-loop pathology — a close failing itself for a
# timing reason rather than a defect. Keeping them non-blocking is what makes the
# blocking arm safe to ship in the release that introduces it.
#
# CUTOFF-GATED (shares deploy.sh Check 47's RELEASE_BODY_DRIFT_CHECK_CUTOFF). The
# block applies only to versions in the same scope Check 47 scans. Close-out is
# re-runnable against an OLDER version — a §5.6 re-emit, or a historical-row
# backfill — and without the gate such a re-run would hard-block on drift that
# Check 47 deliberately exempts. With it, the standing gate and the close gate are
# consistent BY CONSTRUCTION rather than by coincidence. A drift finding outside
# the cutoff scope is still surfaced, as a non-blocking WARN.
#
# Still detective-only in the remediation sense: it never re-emits the Release
# (auto-remediation would raise an autonomy-tier decision, out of scope).
phase_check_release_body_drift() {
  # --no-merge (#2919): this detective phase compares the just-published Surface 1
  # Release body against the in-repo note. Under --no-merge publish_github_release
  # deferred, so there is no fresh Release to drift-check. Defer (avoids a needless
  # network call); re-runs with the publish on the post-merge --apply.
  if [[ "$NO_MERGE" -eq 1 ]]; then
    mark_phase "check_release_body_drift" "SKIPPED" "DEFERRED under --no-merge — no Surface 1 published this run to drift-check (re-run --apply after merge)"
    return 0
  fi

  if [[ ! -x "$DRIFT_CHECK_TOOL" ]]; then
    mark_phase "check_release_body_drift" "SKIPPED" "check-release-body-drift.sh not executable at $DRIFT_CHECK_TOOL"
    return 0
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "check_release_body_drift" "DRY-RUN" "would assert published Release body == frontmatter-stripped in-repo note for $VERSION (per release-notes-standard.md §5.1; genuine drift BLOCKS close when $VERSION is at/after cutoff $DRIFT_CHECK_CUTOFF)"
    return 0
  fi

  # If Surface 1 was not published this run (publish phase FAILed / SKIPPED via a
  # missing tag/notes), there is nothing to compare — record N/A, never WARN.
  local pub_result
  pub_result="$(get_phase "publish_github_release")"
  pub_result="${pub_result%%|*}"

  local drift_out drift_exit=0
  drift_out="$(REPO="$REPO_SLUG" "$DRIFT_CHECK_TOOL" "$VERSION" --quiet 2>&1)" || drift_exit=$?

  # Blocking flag, set ONLY by the genuine-drift arm below when $VERSION is inside
  # the shared cutoff scope. Every other arm leaves it 0 and the phase returns 0.
  local drift_blocking=0

  case "$drift_exit" in
    0)
      mark_phase "check_release_body_drift" "PASS" "published Release body matches the frontmatter-stripped in-repo note for $VERSION (§5.1 invariant holds)"
      ;;
    1)
      # DRIFT — the genuine defect. Blocks the close for an in-scope version;
      # surfaced as a non-blocking WARN for a version the standing gate exempts
      # (a §5.6 re-emit or a historical backfill re-run), so this phase and
      # deploy.sh Check 47 never disagree about the same version.
      if _drift_block_in_scope "$VERSION"; then
        drift_blocking=1
        mark_phase "check_release_body_drift" "FAIL" "DRIFT — published Release body != frontmatter-stripped in-repo note for $VERSION; close BLOCKED per stage-13-close.md Phase B5.6. Correct the canonical note first, then re-emit every surface from it per §5.6 (gh release edit) or release-executor Mode F. $(/usr/bin/printf '%s' "$drift_out" | /usr/bin/head -1)"
      else
        mark_phase "check_release_body_drift" "WARN" "DRIFT — published Release body != frontmatter-stripped in-repo note for $VERSION; re-emit per §5.6 (gh release edit) or release-executor Mode F. NOT blocking: $VERSION is outside the body-drift cutoff scope (cutoff $DRIFT_CHECK_CUTOFF), which deploy.sh Check 47 also exempts. $(/usr/bin/printf '%s' "$drift_out" | /usr/bin/head -1)"
      fi
      ;;
    2)
      # N/A — a capability needed to compare is absent. Exit 2 now spans gh
      # (offline/unauth) AND git (origin/main unresolvable / corrupt object): the
      # tool writes the failing subsystem to stderr unconditionally, and $drift_out
      # captured it (2>&1), so a git failure is NOT mis-reported as "gh offline".
      mark_phase "check_release_body_drift" "N/A" "body-drift check N/A for $VERSION — a required capability is unavailable (gh or git); never FAIL. $(/usr/bin/printf '%s' "$drift_out" | /usr/bin/head -1)"
      ;;
    3)
      # MISSING note or Release. If publish phase did not land Surface 1 this run,
      # this is expected (N/A); otherwise it is a genuine gap (still warn-mode).
      if [[ "$pub_result" != "PASS" ]]; then
        mark_phase "check_release_body_drift" "N/A" "no published Release / note to compare for $VERSION (Surface 1 not emitted this run: publish phase=$pub_result)"
      else
        mark_phase "check_release_body_drift" "WARN" "post-emit body-drift check could not resolve note or Release for $VERSION (non-blocking: an artifact-missing state, not a drift finding — see the exit 2/3 rationale above). $(/usr/bin/printf '%s' "$drift_out" | /usr/bin/head -1)"
      fi
      ;;
    *)
      mark_phase "check_release_body_drift" "WARN" "body-drift check returned unexpected exit $drift_exit for $VERSION (non-blocking: only the genuine-drift exit blocks; an unexpected exit is a tool-contract anomaly, not a §5.1 finding)"
      ;;
  esac

  # Non-zero ONLY on gated genuine drift; the dispatch tail maps that to
  # generate_report + a non-zero close-out exit.
  if [[ "$drift_blocking" -eq 1 ]]; then
    return 1
  fi
  return 0
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
  local phases=(preflight read_state detect_open_issues create_chore_branch transition_release_log inject_outcome_field append_release_index append_release_digest append_reversions scaffold_release_notes lint_release_notes append_changelog assert_derived_surfaces bump_version ledger_guard rebuild_skill_packages commit_chore_pr create_chore_pr await_merge_chore_pr reparse_ledgers post_close_milestone manual_close_release_issues run_verification post_gate_passage_proof publish_github_release check_release_body_drift invoke_orphan_cleanup pattern_scan)
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
  # --no-merge (#2919): the post-merge-dependent phases deferred (see the guard
  # clauses in phases 13/14/15.5/15.6). Emit the deferred set + the exact idempotent
  # follow-up command so the operator has a single unambiguous next step — the step
  # whose absence forced a manual milestone reopen/re-close on the v3.45 close.
  if [[ "$NO_MERGE" -eq 1 ]]; then
    local _excl_hint="" _ei
    for _ei in "${EXCLUDE_ISSUES[@]:-}"; do
      [[ -z "$_ei" ]] && continue
      _excl_hint+=" --exclude-issue ${_ei}"
    done
    echo "## Deferred Under --no-merge"
    echo
    echo "The Stage 13 chore PR${CHORE_PR_NUMBER:+ #${CHORE_PR_NUMBER}} was left open (\`--no-merge\`). Post-merge-dependent phases were deferred to preserve the Stage 13 sequencing invariant — the chore PR MUST land on main before milestone close / Release publish (release/references/pipeline/stage-13-close.md § Phase B):"
    echo
    echo "- \`post_close_milestone\` — Milestone #${MILESTONE} left OPEN"
    echo "- \`manual_close_release_issues\` — D-1 anomaly issue-close deferred"
    echo "- \`publish_github_release\` — Surface 1 (GitHub Release) not emitted"
    echo "- \`check_release_body_drift\` — no published Release to drift-check"
    echo
    echo "**Follow-up — after the chore PR merges (CI-green):**"
    echo
    echo '```'
    echo "automated-closeout.sh --pr ${PR_NUMBER} --version ${VERSION} --milestone ${MILESTONE} --apply${_excl_hint}"
    echo '```'
    echo
    echo "Re-run WITHOUT \`--no-merge\` (preserve any \`--outcome\` / \`--close-comment\` flags from this run). Idempotent: the already-landed corpus SKIPs, then milestone close + Release publish run."
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
    "$STATE_CYCLE_TIME" "$OPEN_ISSUE_COUNT" "$CHORE_PR_NUMBER" "$OPEN_ISSUE_LIST" "$NO_MERGE" <<'PY'
import sys, json
ts, mode, pr, version, milestone, slug, log_state, ms_state, tag, cycle, open_n, chore_pr, open_list, no_merge = sys.argv[1:15]
issues = [int(x) for x in open_list.split("\n") if x.strip()]
# --no-merge (#2919): the post-merge-dependent phases defer; surface which ones so a
# JSON consumer sees the same deferral the markdown report's "Deferred Under --no-merge"
# section shows. Empty list on the normal (merge) path.
deferred = ["post_close_milestone", "manual_close_release_issues", "publish_github_release", "check_release_body_drift"] if no_merge == "1" else []
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
    "deferred_under_no_merge": deferred,
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
  validate_version "v2.12" || { echo "FAIL: validate_version v2.12 (canonical vX.Y)"; failures=$((failures+1)); }
  validate_version "v2.06.1" || { echo "FAIL: validate_version v2.06.1 (canonical vX.Y.Z hotfix)"; failures=$((failures+1)); }
  ! validate_version "v2.07b" || { echo "FAIL: validate_version must REJECT suffix v2.07b (#1801 SSOT tighten)"; failures=$((failures+1)); }
  ! validate_version "v2.04b-1" || { echo "FAIL: validate_version must REJECT suffix v2.04b-1 (#1801 SSOT tighten)"; failures=$((failures+1)); }
  ! validate_version "2.12" || { echo "FAIL: validate_version should reject 2.12 (no v prefix)"; failures=$((failures+1)); }
  ! validate_version "" || { echo "FAIL: validate_version should reject empty"; failures=$((failures+1)); }

  # Test 1b: phase_bump_version (#1643) — offline, hermetic. Drives the phase
  # against a sandbox REPO_ROOT/.version and asserts the SKIP/apply/idempotency
  # branches via the recorded mark_phase outcome (get_phase "bump_version").
  local _bv_saved_root="$REPO_ROOT" _bv_saved_mode="$MODE" _bv_saved_version="$VERSION"
  local _bv_tmp; _bv_tmp="$(/usr/bin/mktemp -d -t bumpver-selftest.XXXXXX)"
  REPO_ROOT="$_bv_tmp"; MODE="apply"
  /usr/bin/printf 'v2.08\n' > "$_bv_tmp/.version"

  # (a) version-less / non-vX.Y $VERSION → SKIPPED, .version untouched (D-A line)
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  VERSION="release-version-stamping"
  phase_bump_version >/dev/null 2>&1
  [[ "$(get_phase bump_version)" == SKIPPED\|* ]] || { echo "FAIL: phase_bump_version should SKIP for version-less \$VERSION, got '$(get_phase bump_version)'"; failures=$((failures+1)); }
  [[ "$(/usr/bin/head -1 "$_bv_tmp/.version")" == "v2.08" ]] || { echo "FAIL: phase_bump_version must leave .version untouched for version-less release"; failures=$((failures+1)); }

  # (b) versioned $VERSION, current != target → PASS, .version written
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  VERSION="v2.11"
  phase_bump_version >/dev/null 2>&1
  [[ "$(get_phase bump_version)" == PASS\|* ]] || { echo "FAIL: phase_bump_version should PASS (apply) for versioned \$VERSION, got '$(get_phase bump_version)'"; failures=$((failures+1)); }
  [[ "$(/usr/bin/head -1 "$_bv_tmp/.version")" == "v2.11" ]] || { echo "FAIL: phase_bump_version must write .version=v2.11, got '$(/usr/bin/head -1 "$_bv_tmp/.version")'"; failures=$((failures+1)); }

  # (c) idempotency — re-run at target → SKIPPED, no churn
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_bump_version >/dev/null 2>&1
  [[ "$(get_phase bump_version)" == SKIPPED\|* ]] || { echo "FAIL: phase_bump_version should SKIP on idempotent re-run, got '$(get_phase bump_version)'"; failures=$((failures+1)); }

  # (d) dry-run preview → DRY-RUN, no write
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  /usr/bin/printf 'v2.08\n' > "$_bv_tmp/.version"; MODE="dry-run"
  phase_bump_version >/dev/null 2>&1
  [[ "$(get_phase bump_version)" == DRY-RUN\|* ]] || { echo "FAIL: phase_bump_version should DRY-RUN preview, got '$(get_phase bump_version)'"; failures=$((failures+1)); }
  [[ "$(/usr/bin/head -1 "$_bv_tmp/.version")" == "v2.08" ]] || { echo "FAIL: phase_bump_version dry-run must NOT write .version"; failures=$((failures+1)); }

  /bin/rm -rf "$_bv_tmp" 2>/dev/null || true
  REPO_ROOT="$_bv_saved_root"; MODE="$_bv_saved_mode"; VERSION="$_bv_saved_version"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # Test 1c: phase_append_reversions (#1679; SLIM #3109) — offline, hermetic. Drives the
  # phase against a sandbox RELEASE_REVERSIONS + RELEASE_LOG and asserts the SLIM gate:
  # a disposition=none re-version is NOT recorded (records N/A, writes no row) across the
  # round-trip derivation (the set-minus-is-wrong fix), the multi-abandoned fan-out, a
  # re-run (no accretion), and a historical-none-row immutability check; a tag-orphaned
  # re-version DOES record exactly one row with abandoned_tag_pushed=true. The none-path
  # tag probe is offline: the sandbox REPO_ROOT is not a git repo, so `git ls-remote`
  # fails => on_origin=0 => disposition `none`. The positive (g) fixture installs a `git`
  # shim to force the probe positive, and also covers the dry-run no-write + orphan-row
  # idempotency.
  local _rv_saved_root="$REPO_ROOT" _rv_saved_mode="$MODE" _rv_saved_version="$VERSION"
  local _rv_saved_slug="$STATE_MILESTONE_SLUG" _rv_saved_log="$RELEASE_LOG" _rv_saved_rev="$RELEASE_REVERSIONS"
  local _rv_saved_spec="$REVERSION_SPEC"
  local _rv_tmp; _rv_tmp="$(/usr/bin/mktemp -d -t reversions-selftest.XXXXXX)"
  REPO_ROOT="$_rv_tmp"; MODE="apply"; VERSION="v9.99"
  RELEASE_REVERSIONS="$_rv_tmp/RELEASE_REVERSIONS.md"
  RELEASE_LOG="$_rv_tmp/RELEASE_LOG.md"
  /bin/cat > "$RELEASE_REVERSIONS" <<'EOF'
# RELEASE_REVERSIONS
| slug | abandoned_version | final_version | claimed_versions | abandoned_tag_pushed | merge_sha | collided_with | resolved_at_stage | disposition | residual_labels | reaped_ref | date |
|---|---|---|---|---|---|---|---|---|---|---|---|
EOF
  /usr/bin/printf '# RELEASE_LOG\n' > "$RELEASE_LOG"
  local _rv_rows

  # (a) no --reversion → N/A, file untouched (common no-collision path)
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  STATE_MILESTONE_SLUG="some-clean-release"; REVERSION_SPEC=""
  phase_append_reversions >/dev/null 2>&1
  [[ "$(get_phase append_reversions)" == N/A\|* ]] || { echo "FAIL: phase_append_reversions should be N/A with no --reversion, got '$(get_phase append_reversions)'"; failures=$((failures+1)); }
  _rv_rows="$(/usr/bin/grep -cE '^\| [A-Za-z0-9.-]+ \| v' "$RELEASE_REVERSIONS" 2>/dev/null || true)"; _rv_rows="${_rv_rows:-0}"
  [[ "$_rv_rows" -eq 0 ]] || { echo "FAIL: phase_append_reversions N/A path must write no rows, got $_rv_rows"; failures=$((failures+1)); }

  # Deterministic tag probe: the phase's `git ls-remote` runs in the invoker's cwd (which
  # may be a real repo where an abandoned version IS a live tag), so grounding cannot be
  # left to a "sandbox is offline" assumption — under SLIM the disposition VALUE decides
  # the outcome. Install a `git` shim keyed on _selftest_lsremote_hit: 0 => probe returns
  # empty (disposition=none, the gated path); 1 => probe reports the abandoned tag PRESENT
  # (disposition=tag-orphaned). Unset after the block.
  # _selftest_lsremote_only pins the hit to ONE version, so a single fan-out can mix a
  # tag-orphaned and a `none` abandoned version (the (h) mixed fixture); it takes
  # precedence over the all-or-nothing _selftest_lsremote_hit flag when set.
  local _selftest_lsremote_hit=0 _selftest_lsremote_only=""
  git() {
    if [[ "$1" == "ls-remote" ]]; then
      # $4 is the "refs/tags/<v>" refspec; emit a matching ref line only on a hit.
      local _st_v="${4##refs/tags/}"
      if [[ -n "$_selftest_lsremote_only" ]]; then
        [[ "$_st_v" == "$_selftest_lsremote_only" ]] && /usr/bin/printf '2222222222222222222222222222222222222222\t%s\n' "$4"
      else
        [[ "$_selftest_lsremote_hit" == "1" ]] && /usr/bin/printf '2222222222222222222222222222222222222222\t%s\n' "$4"
      fi
      return 0
    fi
    command git "$@"
  }

  # (b) round-trip v2.12 → v2.14 → v2.12 (final v2.12): the set-minus-is-wrong derivation
  #     still yields the single abandoned v2.14, but disposition grounds to `none`, so the
  #     SLIM gate suppresses it → N/A, ZERO rows (the gate is what changes the outcome).
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  STATE_MILESTONE_SLUG="round-trip-release"
  REVERSION_SPEC="v2.12|v2.12 -> v2.14 -> v2.12|deadbeefdeadbeefdeadbeefdeadbeefdeadbeef|sibling@v2.14|S12|branch named v2.12"
  phase_append_reversions >/dev/null 2>&1
  [[ "$(get_phase append_reversions)" == N/A\|* ]] || { echo "FAIL: round-trip none-path must be N/A under the SLIM gate, got '$(get_phase append_reversions)'"; failures=$((failures+1)); }
  _rv_rows="$(/usr/bin/grep -cE '^\| round-trip-release \|' "$RELEASE_REVERSIONS" 2>/dev/null || true)"; _rv_rows="${_rv_rows:-0}"
  [[ "$_rv_rows" -eq 0 ]] || { echo "FAIL: round-trip none-path must write 0 rows (gated), got $_rv_rows"; failures=$((failures+1)); }

  # (c) multi-abandoned v1.18 → v1.19 → v1.20 (final v1.20): both abandoned versions ground
  #     to `none` → both gated → N/A, ZERO rows (fan-out composes with the gate).
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  STATE_MILESTONE_SLUG="multi-abandoned-release"
  REVERSION_SPEC="v1.20|v1.18 -> v1.19 -> v1.20|cafebabecafebabecafebabecafebabecafebabe|a@v1.18,b@v1.19|S12|legacy branch"
  phase_append_reversions >/dev/null 2>&1
  [[ "$(get_phase append_reversions)" == N/A\|* ]] || { echo "FAIL: multi-abandoned none-path must be N/A under the SLIM gate, got '$(get_phase append_reversions)'"; failures=$((failures+1)); }
  _rv_rows="$(/usr/bin/grep -cE '^\| multi-abandoned-release \|' "$RELEASE_REVERSIONS" 2>/dev/null || true)"; _rv_rows="${_rv_rows:-0}"
  [[ "$_rv_rows" -eq 0 ]] || { echo "FAIL: multi-abandoned none-path must write 0 rows (both gated), got $_rv_rows"; failures=$((failures+1)); }

  # (d) re-run the round-trip none-path → still N/A, still 0 rows. The gate writes nothing,
  #     so there is nothing to be idempotent about: it is stable and accretes no row across
  #     re-runs (orphan-row idempotency is covered on the positive (g) fixture).
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  STATE_MILESTONE_SLUG="round-trip-release"
  REVERSION_SPEC="v2.12|v2.12 -> v2.14 -> v2.12|deadbeefdeadbeefdeadbeefdeadbeefdeadbeef|sibling@v2.14|S12|branch named v2.12"
  phase_append_reversions >/dev/null 2>&1
  [[ "$(get_phase append_reversions)" == N/A\|* ]] || { echo "FAIL: re-run of a none-path must stay N/A, got '$(get_phase append_reversions)'"; failures=$((failures+1)); }
  _rv_rows="$(/usr/bin/grep -cE '^\| round-trip-release \|' "$RELEASE_REVERSIONS" 2>/dev/null || true)"; _rv_rows="${_rv_rows:-0}"
  [[ "$_rv_rows" -eq 0 ]] || { echo "FAIL: re-run of a gated none-path must not accrete a row, got $_rv_rows"; failures=$((failures+1)); }

  # (e) immutability: the SLIM gate NEVER disturbs a pre-existing historical `none` row.
  #     Seed one, run a fresh none-path re-version (different slug) → N/A + 0 new rows for
  #     that slug + the historical row still present (append-only history is preserved).
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  /usr/bin/printf '| legacy-none-release | v0.90 | v0.92 | v0.90 → v0.92 | false | 1111111111111111111111111111111111111111 | s@v0.90 | S12 | none | historical | — | 2026-06-01 |\n' >> "$RELEASE_REVERSIONS"
  STATE_MILESTONE_SLUG="immutability-release"
  REVERSION_SPEC="v5.02|v5.01 -> v5.02|3333333333333333333333333333333333333333|z@v5.01|S12|—"
  phase_append_reversions >/dev/null 2>&1
  [[ "$(get_phase append_reversions)" == N/A\|* ]] || { echo "FAIL: fresh none-path must be N/A, got '$(get_phase append_reversions)'"; failures=$((failures+1)); }
  _rv_rows="$(/usr/bin/grep -cE '^\| immutability-release \|' "$RELEASE_REVERSIONS" 2>/dev/null || true)"; _rv_rows="${_rv_rows:-0}"
  [[ "$_rv_rows" -eq 0 ]] || { echo "FAIL: gated none-path must write 0 rows for its slug, got $_rv_rows"; failures=$((failures+1)); }
  /usr/bin/grep -qE '^\| legacy-none-release \| v0\.90 \|.*\| none \|' "$RELEASE_REVERSIONS" || { echo "FAIL: SLIM gate must preserve the pre-existing historical none row (append-only immutability)"; failures=$((failures+1)); }

  # (f) DRY-RUN on the `none` path — restores the coverage Stage-5 design §3 named as
  #     "(e) dry-run: re-assert to the gated behavior". THE parity fixture: the preview must
  #     report the rows apply ACTUALLY writes (0), not the raw abandoned-version count. It is
  #     asserted as an explicit preview-then-apply comparison, because the escape it guards
  #     (#3109 F-01, the #2539 parity-gap class) is invisible to any single-mode assertion —
  #     and invisible on the tag-orphaned path (g.1), where the two counts coincide.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  MODE="dry-run"; STATE_MILESTONE_SLUG="dryrun-none-release"
  REVERSION_SPEC="v7.02|v7.01 -> v7.02|7777777777777777777777777777777777777777|x@v7.01|S12|—"
  phase_append_reversions >/dev/null 2>&1
  [[ "$(get_phase append_reversions)" == DRY-RUN\|* ]] || { echo "FAIL: none-path dry-run should DRY-RUN preview, got '$(get_phase append_reversions)'"; failures=$((failures+1)); }
  [[ "$(get_phase append_reversions)" == *"would append 0 row(s)"* ]] || { echo "FAIL: none-path dry-run must preview 0 rows (SLIM gate), got '$(get_phase append_reversions)'"; failures=$((failures+1)); }
  /usr/bin/grep -qE '^\| dryrun-none-release \|' "$RELEASE_REVERSIONS" && { echo "FAIL: none-path dry-run must NOT write a row"; failures=$((failures+1)); }
  #     …now apply the SAME spec: 0 rows written => preview == actual.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  MODE="apply"
  phase_append_reversions >/dev/null 2>&1
  [[ "$(get_phase append_reversions)" == N/A\|* ]] || { echo "FAIL: none-path apply must be N/A, got '$(get_phase append_reversions)'"; failures=$((failures+1)); }
  _rv_rows="$(/usr/bin/grep -cE '^\| dryrun-none-release \|' "$RELEASE_REVERSIONS" 2>/dev/null || true)"; _rv_rows="${_rv_rows:-0}"
  [[ "$_rv_rows" -eq 0 ]] || { echo "FAIL: none-path dry-run predicted 0 rows but apply wrote $_rv_rows (dry-run/apply parity broken)"; failures=$((failures+1)); }

  # (g) POSITIVE — the tag-orphaned path (the sole disposition still recorded). Flip the
  #     shim so the probe reports the abandoned tag PRESENT on origin; the sandbox
  #     RELEASE_LOG has no canonical row for it, so the phase grounds tag-orphaned +
  #     abandoned_tag_pushed=true. Covers dry-run no-write, the positive write, and
  #     orphan-row idempotency.
  _selftest_lsremote_hit=1
  # (g.1) dry-run of the orphan spec → DRY-RUN preview, no row written.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  MODE="dry-run"; STATE_MILESTONE_SLUG="orphan-release"
  REVERSION_SPEC="v4.02|v4.01 -> v4.02|abcabcabcabcabcabcabcabcabcabcabcabcabca|w@v4.01|S12|branch named v4.01"
  phase_append_reversions >/dev/null 2>&1
  [[ "$(get_phase append_reversions)" == DRY-RUN\|* ]] || { echo "FAIL: orphan dry-run should DRY-RUN preview, got '$(get_phase append_reversions)'"; failures=$((failures+1)); }
  /usr/bin/grep -qE '^\| orphan-release \|' "$RELEASE_REVERSIONS" && { echo "FAIL: orphan dry-run must NOT write a row"; failures=$((failures+1)); }
  # (g.2) apply the orphan spec → PASS, exactly 1 row, abandoned_tag_pushed=true, disposition=tag-orphaned.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  MODE="apply"
  phase_append_reversions >/dev/null 2>&1
  [[ "$(get_phase append_reversions)" == PASS\|* ]] || { echo "FAIL: tag-orphaned path should PASS, got '$(get_phase append_reversions)'"; failures=$((failures+1)); }
  _rv_rows="$(/usr/bin/grep -cE '^\| orphan-release \|' "$RELEASE_REVERSIONS" 2>/dev/null || true)"; _rv_rows="${_rv_rows:-0}"
  [[ "$_rv_rows" -eq 1 ]] || { echo "FAIL: tag-orphaned path must write exactly 1 row, got $_rv_rows"; failures=$((failures+1)); }
  /usr/bin/grep -qE '^\| orphan-release \| v4\.01 \| v4\.02 \|' "$RELEASE_REVERSIONS" || { echo "FAIL: tag-orphaned row must be abandoned=v4.01 final=v4.02"; failures=$((failures+1)); }
  /usr/bin/grep -qE '^\| orphan-release \|.*\| true \|' "$RELEASE_REVERSIONS" || { echo "FAIL: tag-orphaned row must carry abandoned_tag_pushed=true"; failures=$((failures+1)); }
  /usr/bin/grep -qE '^\| orphan-release \|.*\| tag-orphaned \|' "$RELEASE_REVERSIONS" || { echo "FAIL: tag-orphaned row must carry disposition=tag-orphaned"; failures=$((failures+1)); }
  # (g.3) re-run apply → SKIPPED (idempotent), still exactly 1 row.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_append_reversions >/dev/null 2>&1
  [[ "$(get_phase append_reversions)" == SKIPPED\|* ]] || { echo "FAIL: tag-orphaned re-run must be SKIPPED (idempotent), got '$(get_phase append_reversions)'"; failures=$((failures+1)); }
  _rv_rows="$(/usr/bin/grep -cE '^\| orphan-release \|' "$RELEASE_REVERSIONS" 2>/dev/null || true)"; _rv_rows="${_rv_rows:-0}"
  [[ "$_rv_rows" -eq 1 ]] || { echo "FAIL: tag-orphaned idempotent re-run must not duplicate the row, got $_rv_rows"; failures=$((failures+1)); }

  # (h) MIXED fan-out — ONE tag-orphaned + ONE `none` abandoned version in the same
  #     re-version. Neither the all-`none` nor the all-orphan fixture can see a preview that
  #     counts pre-gate: only the mixed case makes "2 predicted / 1 written" observable.
  #     Pin the probe to v8.01 so v8.02 grounds `none`.
  _selftest_lsremote_hit=0; _selftest_lsremote_only="v8.01"
  # (h.1) dry-run must predict exactly 1 (the orphan), not 2, and write nothing.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  MODE="dry-run"; STATE_MILESTONE_SLUG="mixed-release"
  REVERSION_SPEC="v8.03|v8.01 -> v8.02 -> v8.03|8888888888888888888888888888888888888888|y@v8.01|S12|—"
  phase_append_reversions >/dev/null 2>&1
  [[ "$(get_phase append_reversions)" == DRY-RUN\|* ]] || { echo "FAIL: mixed dry-run should DRY-RUN preview, got '$(get_phase append_reversions)'"; failures=$((failures+1)); }
  [[ "$(get_phase append_reversions)" == *"would append 1 row(s)"* ]] || { echo "FAIL: mixed dry-run must preview 1 row (1 orphan + 1 gated), got '$(get_phase append_reversions)'"; failures=$((failures+1)); }
  /usr/bin/grep -qE '^\| mixed-release \|' "$RELEASE_REVERSIONS" && { echo "FAIL: mixed dry-run must NOT write a row"; failures=$((failures+1)); }
  # (h.2) apply the SAME spec → exactly 1 row, and it is the ORPHAN (v8.01), not the gated
  #       v8.02; the PASS detail surfaces the gated version so the fan-out is observable.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  MODE="apply"
  phase_append_reversions >/dev/null 2>&1
  [[ "$(get_phase append_reversions)" == PASS\|* ]] || { echo "FAIL: mixed apply should PASS, got '$(get_phase append_reversions)'"; failures=$((failures+1)); }
  _rv_rows="$(/usr/bin/grep -cE '^\| mixed-release \|' "$RELEASE_REVERSIONS" 2>/dev/null || true)"; _rv_rows="${_rv_rows:-0}"
  [[ "$_rv_rows" -eq 1 ]] || { echo "FAIL: mixed dry-run predicted 1 row but apply wrote $_rv_rows (dry-run/apply parity broken)"; failures=$((failures+1)); }
  /usr/bin/grep -qE '^\| mixed-release \| v8\.01 \|.*\| tag-orphaned \|' "$RELEASE_REVERSIONS" || { echo "FAIL: mixed apply must record the tag-orphaned v8.01 row"; failures=$((failures+1)); }
  /usr/bin/grep -qE '^\| mixed-release \| v8\.02 \|' "$RELEASE_REVERSIONS" && { echo "FAIL: mixed apply must NOT record the gated none v8.02"; failures=$((failures+1)); }
  [[ "$(get_phase append_reversions)" == *"gated 1"* ]] || { echo "FAIL: mixed apply PASS detail must surface the gated count, got '$(get_phase append_reversions)'"; failures=$((failures+1)); }
  _selftest_lsremote_only=""
  unset -f git

  /bin/rm -rf "$_rv_tmp" 2>/dev/null || true
  REPO_ROOT="$_rv_saved_root"; MODE="$_rv_saved_mode"; VERSION="$_rv_saved_version"
  STATE_MILESTONE_SLUG="$_rv_saved_slug"; RELEASE_LOG="$_rv_saved_log"; RELEASE_REVERSIONS="$_rv_saved_rev"
  REVERSION_SPEC="$_rv_saved_spec"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

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
  # #667 Finding 2 (VERIFY-then-close): an NN-prefixed theme-named row resolves to the
  # slug == milestone title (what `--milestone` consumes). Confirms the forward-scan
  # resolver (NOT position-independent — see extract_milestone_slug's TRUE-invariant
  # note) handles the NN case Finding 2 described.
  sample_row="| v2.36 | 69-triage-and-bundling-signals | #500 | #2284 | sha | v2.36 | VERIFIED | 2026-06-28 |"
  [[ "$(extract_milestone_slug "$sample_row")" == "69-triage-and-bundling-signals" ]] || { echo "FAIL: extract_milestone_slug (8-col, bare theme-named slug) should return field-2 slug, got '$(extract_milestone_slug "$sample_row")'"; failures=$((failures+1)); }
  [[ "$(extract_milestone_slug "$sample_row")" != "v2.36" ]] || { echo "FAIL: extract_milestone_slug returned the bare Version, not the theme-named slug"; failures=$((failures+1)); }
  # #2539 (branch 3): a PURE-ALPHA theme-named slug (no vX.Y- and no NN- prefix) on a
  # versioned row must resolve to the field-2 title, not fall back to the Version field.
  # Regression anchor: the v3.78 close-out, milestone pda-rollup-and-portfolio.
  sample_row="| v3.78 | pda-rollup-and-portfolio | #157 | #3549 | sha | v3.78 | DEPLOYED | 2026-07-17 |"
  [[ "$(extract_milestone_slug "$sample_row")" == "pda-rollup-and-portfolio" ]] || { echo "FAIL: extract_milestone_slug (8-col, pure-alpha slug) should return field-2 slug, got '$(extract_milestone_slug "$sample_row")'"; failures=$((failures+1)); }
  [[ "$(extract_milestone_slug "$sample_row")" != "v3.78" ]] || { echo "FAIL: extract_milestone_slug (#2539) returned the bare Version, not the pure-alpha slug"; failures=$((failures+1)); }
  # #2539 (branch 3, anchoring): a VERSION-LESS row carries the slug plus a
  # " (version-less)" suffix in field 1; the end-anchor must reject field 1 so the loop
  # reaches the clean field-2 title.
  sample_row="| public-flip-install-blockers (version-less) | public-flip-install-blockers | #606 | #627 | sha | (none) | VERIFIED | 2026-06-04 |"
  [[ "$(extract_milestone_slug "$sample_row")" == "public-flip-install-blockers" ]] || { echo "FAIL: extract_milestone_slug (version-less row) should return the clean field-2 slug, got '$(extract_milestone_slug "$sample_row")'"; failures=$((failures+1)); }
  # #2539 (branch 3 = a4): a HYPHEN-LESS single-word milestone must resolve to the
  # field-2 title. This is the exact case the prior hyphen-requiring recognizer
  # (^[a-z][a-z0-9]*(-[a-z0-9]+)+$, needs >=1 hyphen group) MISSED and a4
  # (^[a-z][a-z0-9-]*$) fixes — the #2539 divergence signature.
  sample_row="| v3.99 | hardening | #1 | #2 | sha | v3.99 | DEPLOYED | 2026-07-18 |"
  [[ "$(extract_milestone_slug "$sample_row")" == "hardening" ]] || { echo "FAIL: extract_milestone_slug (8-col, hyphen-less pure-alpha) should return field-2 slug 'hardening', got '$(extract_milestone_slug "$sample_row")'"; failures=$((failures+1)); }
  [[ "$(extract_milestone_slug "$sample_row")" != "v3.99" ]] || { echo "FAIL: extract_milestone_slug (hyphen-less) returned the bare Version, not the slug — a4 branch regression"; failures=$((failures+1)); }

  # Test 4b: phase_append_release_digest + phase_append_release_index (#667 F3/F6)
  # — offline, hermetic. Drives both append phases against sandbox corpus files
  # and asserts: DIGEST emits a `### vX.Y (date)` H3 under the topmost working H2
  # (the exact form deploy.sh Check 32(b) `^### vX\.Y[[:space:](]` asserts); INDEX
  # emits a 6-pipe-field row keyed on the bare version; both re-runs are idempotent.
  local _ai_saved_root="$REPO_ROOT" _ai_saved_mode="$MODE" _ai_saved_version="$VERSION"
  local _ai_saved_slug="$STATE_MILESTONE_SLUG" _ai_saved_idx="$RELEASE_INDEX" _ai_saved_dig="$RELEASE_DIGEST"
  local _ai_saved_pr="$PR_NUMBER" _ai_saved_notesdir="$RELEASE_NOTES_DIR"
  local _ai_tmp; _ai_tmp="$(/usr/bin/mktemp -d -t appendidx-selftest.XXXXXX)"
  REPO_ROOT="$_ai_tmp"; MODE="apply"; VERSION="v9.97"; STATE_MILESTONE_SLUG="88-some-theme-named-milestone"; PR_NUMBER=9999
  RELEASE_INDEX="$_ai_tmp/RELEASE_INDEX.md"; RELEASE_DIGEST="$_ai_tmp/RELEASE_DIGEST.md"
  RELEASE_NOTES_DIR="$_ai_tmp/notes"   # absent dir => headline placeholder path
  /bin/cat > "$RELEASE_INDEX" <<'EOF'
# RELEASE_INDEX

| Version | Milestone | Date | Theme | Release PR | Release Notes |
|---|---|---|---|---|---|
| v9.96 | 87-prior | 2026-06-27 | prior | #9000 | [notes/v9.96_RELEASE_NOTES.md](notes/v9.96_RELEASE_NOTES.md) |
EOF
  /bin/cat > "$RELEASE_DIGEST" <<'EOF'
# RELEASE_DIGEST

## Knowledge Corpus

### v9.96 (2026-06-27) — Prior release headline

Prior body.

## v1.* — Pipeline Discipline

### v1.00 (2026-01-01) — Legacy
EOF

  # (a) DIGEST emit → exactly one `### v9.97 (date) — …` H3, under `## Knowledge Corpus`
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_append_release_digest >/dev/null 2>&1
  [[ "$(get_phase append_release_digest)" == PASS\|* ]] || { echo "FAIL: phase_append_release_digest should PASS, got '$(get_phase append_release_digest)'"; failures=$((failures+1)); }
  local _ai_dig_n; _ai_dig_n="$(/usr/bin/grep -cE '^### v9\.97[[:space:](]' "$RELEASE_DIGEST" 2>/dev/null || true)"; _ai_dig_n="${_ai_dig_n:-0}"
  [[ "$_ai_dig_n" -eq 1 ]] || { echo "FAIL: DIGEST must carry exactly 1 '### v9.97 (' H3 (Check-32(b) form), got $_ai_dig_n"; failures=$((failures+1)); }
  # the new entry must sit under `## Knowledge Corpus`, above the legacy `## v1.*` family H2
  local _ai_kc _ai_new _ai_legacy
  _ai_kc="$(/usr/bin/grep -nF '## Knowledge Corpus' "$RELEASE_DIGEST" | /usr/bin/head -1 | /usr/bin/cut -d: -f1)"
  _ai_new="$(/usr/bin/grep -nE '^### v9\.97[[:space:](]' "$RELEASE_DIGEST" | /usr/bin/head -1 | /usr/bin/cut -d: -f1)"
  _ai_legacy="$(/usr/bin/grep -nE '^## v1\.\* ' "$RELEASE_DIGEST" | /usr/bin/head -1 | /usr/bin/cut -d: -f1)"
  [[ "$_ai_kc" -lt "$_ai_new" && "$_ai_new" -lt "$_ai_legacy" ]] || { echo "FAIL: new DIGEST H3 (line $_ai_new) must sit under '## Knowledge Corpus' (line $_ai_kc) and above the legacy '## v1.*' family (line $_ai_legacy)"; failures=$((failures+1)); }

  # (b) INDEX emit → exactly one row keyed on bare v9.97, with exactly 6 fields
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_append_release_index >/dev/null 2>&1
  [[ "$(get_phase append_release_index)" == PASS\|* ]] || { echo "FAIL: phase_append_release_index should PASS, got '$(get_phase append_release_index)'"; failures=$((failures+1)); }
  local _ai_row; _ai_row="$(/usr/bin/grep -E '^\| v9\.97 \|' "$RELEASE_INDEX" | /usr/bin/head -1)"
  [[ -n "$_ai_row" ]] || { echo "FAIL: INDEX must carry a row keyed on bare v9.97"; failures=$((failures+1)); }
  # 6-column schema ⇒ a well-formed row has exactly 7 pipes (| a | b | c | d | e | f |).
  local _ai_pipes; _ai_pipes="$(/usr/bin/printf '%s' "$_ai_row" | /usr/bin/tr -cd '|' | /usr/bin/wc -c | /usr/bin/tr -d ' ')"
  [[ "$_ai_pipes" -eq 7 ]] || { echo "FAIL: INDEX row must be 6-column (7 pipes), got $_ai_pipes pipes in: $_ai_row"; failures=$((failures+1)); }

  # (c) idempotency — re-run both phases → SKIPPED on the H3 / bare-version guards
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_append_release_digest >/dev/null 2>&1
  [[ "$(get_phase append_release_digest)" == SKIPPED\|* ]] || { echo "FAIL: phase_append_release_digest re-run must SKIP (H3 idempotency), got '$(get_phase append_release_digest)'"; failures=$((failures+1)); }
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_append_release_index >/dev/null 2>&1
  [[ "$(get_phase append_release_index)" == SKIPPED\|* ]] || { echo "FAIL: phase_append_release_index re-run must SKIP (bare-version idempotency), got '$(get_phase append_release_index)'"; failures=$((failures+1)); }
  _ai_dig_n="$(/usr/bin/grep -cE '^### v9\.97[[:space:](]' "$RELEASE_DIGEST" 2>/dev/null || true)"; _ai_dig_n="${_ai_dig_n:-0}"
  [[ "$_ai_dig_n" -eq 1 ]] || { echo "FAIL: idempotent re-run must not duplicate the DIGEST H3, got $_ai_dig_n"; failures=$((failures+1)); }

  # (d) VERSION-LESS emit (#2048) — a non-canonical $VERSION (the milestone slug
  # stands in for the version) must follow the shipped corpus convention: INDEX
  # Version cell carries the "(version-less)" marker + a notes/_unversioned/ link;
  # DIGEST H3 carries the "(<date>, version-less)" marker; CHANGELOG SKIPs (there
  # is no `## [vX.Y]` key); and the marker-aware idempotency guards still fire.
  # Before the fix only phase_bump_version branched on version-less, so these
  # emits produced entries that diverged from every shipped version-less row.
  local _vl="77-some-version-less-theme"
  VERSION="$_vl"; STATE_MILESTONE_SLUG="$_vl"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_append_release_digest >/dev/null 2>&1
  phase_append_release_index >/dev/null 2>&1
  /usr/bin/grep -qE "^### ${_vl} \([0-9-]+, version-less\)" "$RELEASE_DIGEST" \
    || { echo "FAIL: version-less DIGEST H3 must be '### $_vl (<date>, version-less) — …'"; failures=$((failures+1)); }
  local _vl_row; _vl_row="$(/usr/bin/grep -E "^\| ${_vl} \(version-less\) \|" "$RELEASE_INDEX" | /usr/bin/head -1 || true)"
  [[ -n "$_vl_row" ]] || { echo "FAIL: version-less INDEX row must key on '| $_vl (version-less) |'"; failures=$((failures+1)); }
  /usr/bin/printf '%s' "$_vl_row" | /usr/bin/grep -q "notes/_unversioned/${_vl}_RELEASE_NOTES.md" \
    || { echo "FAIL: version-less INDEX row must link notes/_unversioned/${_vl}_RELEASE_NOTES.md; got: $_vl_row"; failures=$((failures+1)); }
  # marker-aware idempotency — both re-runs must SKIP (the guard must recognise
  # the marked cell; the bare-version pattern alone would re-append a duplicate)
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_append_release_digest >/dev/null 2>&1
  [[ "$(get_phase append_release_digest)" == SKIPPED\|* ]] || { echo "FAIL: version-less DIGEST re-run must SKIP"; failures=$((failures+1)); }
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_append_release_index >/dev/null 2>&1
  [[ "$(get_phase append_release_index)" == SKIPPED\|* ]] || { echo "FAIL: version-less INDEX re-run must SKIP (marker-aware guard)"; failures=$((failures+1)); }
  # CHANGELOG must SKIP for a version-less release, and write nothing
  /usr/bin/printf '# Changelog\n\n## [Unreleased]\n' > "$_ai_tmp/CHANGELOG.md"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_append_changelog >/dev/null 2>&1
  [[ "$(get_phase append_changelog)" == SKIPPED\|* ]] || { echo "FAIL: version-less CHANGELOG must SKIP, got '$(get_phase append_changelog)'"; failures=$((failures+1)); }
  ! /usr/bin/grep -q "\[${_vl}\]" "$_ai_tmp/CHANGELOG.md" || { echo "FAIL: version-less release must not write a ## [$_vl] CHANGELOG entry"; failures=$((failures+1)); }

  /bin/rm -rf "$_ai_tmp" 2>/dev/null || true
  REPO_ROOT="$_ai_saved_root"; MODE="$_ai_saved_mode"; VERSION="$_ai_saved_version"
  STATE_MILESTONE_SLUG="$_ai_saved_slug"; RELEASE_INDEX="$_ai_saved_idx"; RELEASE_DIGEST="$_ai_saved_dig"
  PR_NUMBER="$_ai_saved_pr"; RELEASE_NOTES_DIR="$_ai_saved_notesdir"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # Test 4c: phase_inject_outcome_field (#37) — offline, hermetic. Drives the
  # phase against a sandbox RELEASE_LOG carrying a v9.95 Deployment-Log block and
  # asserts: default-SUCCESS injects `**Outcome:** SUCCESS` immediately after
  # `**Result:**`; a non-SUCCESS --outcome without a rationale FAILs; a non-SUCCESS
  # --outcome WITH a rationale emits both lines; an unknown enum value is rejected;
  # the inject is idempotent (skip when **Outcome:** already present in the block).
  local _oc_saved_root="$REPO_ROOT" _oc_saved_mode="$MODE" _oc_saved_version="$VERSION"
  local _oc_saved_log="$RELEASE_LOG" _oc_saved_outcome="$OUTCOME" _oc_saved_rat="$OUTCOME_RATIONALE"
  local _oc_tmp; _oc_tmp="$(/usr/bin/mktemp -d -t outcome-selftest.XXXXXX)"
  RELEASE_LOG="$_oc_tmp/RELEASE_LOG.md"; MODE="apply"; VERSION="v9.95"
  # Fixture: two Deployment-Log blocks (v9.95 target + a sibling v9.94) so the
  # block-bounded edit + idempotency grep are proven scoped to v9.95 only.
  local _oc_write_log
  _oc_write_log() {
    /bin/cat > "$RELEASE_LOG" <<'EOF'
# RELEASE_LOG

#### Deployment Log v9.95
**Mechanism:** git merge.
**Timestamp:** 2026-06-28.
**Result:** SUCCESS — green CI.
**Velocity:** 3 issues.

#### Deployment Log v9.94
**Result:** SUCCESS — prior release.
EOF
  }

  # (a) default-SUCCESS → `**Outcome:** SUCCESS` immediately after `**Result:**`.
  # NOTE: assertion greps use -F/-Fx (fixed-string) because the leading `**` is a
  # repetition-operator to BSD grep under a regex pattern.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _oc_write_log; OUTCOME=""; OUTCOME_RATIONALE=""
  phase_inject_outcome_field >/dev/null 2>&1
  [[ "$(get_phase inject_outcome_field)" == PASS\|* ]] || { echo "FAIL: phase_inject_outcome_field default should PASS, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  # the Outcome line must directly follow the v9.95 Result line (grep -A1)
  /usr/bin/grep -A1 -F '**Result:** SUCCESS — green CI.' "$RELEASE_LOG" | /usr/bin/grep -qFx '**Outcome:** SUCCESS' || { echo "FAIL: '**Outcome:** SUCCESS' must directly follow the v9.95 **Result:** line"; failures=$((failures+1)); }
  # the sibling v9.94 block must be untouched (no Outcome injected there)
  /usr/bin/awk '/^#### Deployment Log v9\.94/{b=1} /^#### Deployment Log v9\.95/{b=0} b && /^\*\*Outcome:/{print "LEAK"}' "$RELEASE_LOG" | /usr/bin/grep -q LEAK && { echo "FAIL: Outcome leaked into the sibling v9.94 block"; failures=$((failures+1)); }

  # (b) non-SUCCESS without rationale → FAIL (§5 conditional-required)
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _oc_write_log; OUTCOME="PARTIAL"; OUTCOME_RATIONALE=""
  if phase_inject_outcome_field >/dev/null 2>&1; then
    echo "FAIL: phase_inject_outcome_field --outcome PARTIAL without rationale must FAIL"; failures=$((failures+1))
  fi
  [[ "$(get_phase inject_outcome_field | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: non-SUCCESS-no-rationale must mark FAIL"; failures=$((failures+1)); }

  # (c) non-SUCCESS WITH rationale → PASS; both lines emitted
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _oc_write_log; OUTCOME="PARTIAL"; OUTCOME_RATIONALE="constituent 3 of 5 failed Phase H deploy"
  phase_inject_outcome_field >/dev/null 2>&1
  [[ "$(get_phase inject_outcome_field)" == PASS\|* ]] || { echo "FAIL: --outcome PARTIAL with rationale should PASS, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  /usr/bin/grep -qFx '**Outcome:** PARTIAL' "$RELEASE_LOG" || { echo "FAIL: '**Outcome:** PARTIAL' line missing"; failures=$((failures+1)); }
  /usr/bin/grep -qF '**Outcome rationale:** constituent 3 of 5 failed Phase H deploy' "$RELEASE_LOG" || { echo "FAIL: '**Outcome rationale:**' line missing"; failures=$((failures+1)); }

  # (d) unknown enum value → rejected. phase_inject_outcome_field calls `die`
  # (which exits) on a bad enum, so run it in a SUBSHELL and assert non-zero exit.
  _oc_write_log
  if ( OUTCOME="BOGUS"; OUTCOME_RATIONALE=""; phase_inject_outcome_field ) >/dev/null 2>&1; then
    echo "FAIL: phase_inject_outcome_field must reject an unknown --outcome value"; failures=$((failures+1))
  fi

  # (e) idempotency — inject once (PASS) on a FRESH block, then re-run → SKIPPED.
  # (Case (d) rewrote the fixture; write a clean block first so this is a true
  # inject-then-reinject sequence, not a re-run over a wiped block.)
  _oc_write_log; OUTCOME=""; OUTCOME_RATIONALE=""
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_inject_outcome_field >/dev/null 2>&1   # first inject → PASS
  [[ "$(get_phase inject_outcome_field)" == PASS\|* ]] || { echo "FAIL: phase_inject_outcome_field first inject should PASS, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_inject_outcome_field >/dev/null 2>&1   # second run → SKIPPED
  [[ "$(get_phase inject_outcome_field)" == SKIPPED\|* ]] || { echo "FAIL: phase_inject_outcome_field re-run must SKIP (idempotency), got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  [[ "$(/usr/bin/grep -c '^\*\*Outcome:\*\*' "$RELEASE_LOG")" -eq 1 ]] || { echo "FAIL: idempotent re-run must not duplicate the **Outcome:** line"; failures=$((failures+1)); }

  /bin/rm -rf "$_oc_tmp" 2>/dev/null || true
  unset -f _oc_write_log
  REPO_ROOT="$_oc_saved_root"; MODE="$_oc_saved_mode"; VERSION="$_oc_saved_version"
  RELEASE_LOG="$_oc_saved_log"; OUTCOME="$_oc_saved_outcome"; OUTCOME_RATIONALE="$_oc_saved_rat"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # Test 4d: phase_detect_open_issues exclude filter (#38) — offline, hermetic.
  # Stubs $GH so `gh issue list … --json number,title --jq …` returns a fixed
  # `<number>\t<title>` fixture (gh applies --jq server-side, so the stub emits the
  # already-jq'd lines), then drives phase_detect_open_issues and asserts the
  # filter: explicit --exclude-issue removes a number; the Stage-13 sub-task is
  # excluded by explicit number; the title-regex `(?i)stage.?13.*close` fallback
  # excludes an un-numbered Stage-13-close sub-task; the AC-4 mixed fixture leaves
  # ONLY the anomaly issue in OPEN_ISSUE_LIST.
  local _ex_saved_gh="$GH" _ex_saved_mode="$MODE" _ex_saved_slug="$STATE_MILESTONE_SLUG"
  local _ex_saved_list="$OPEN_ISSUE_LIST" _ex_saved_count="$OPEN_ISSUE_COUNT"
  local _ex_tmp; _ex_tmp="$(/usr/bin/mktemp -d -t excl-selftest.XXXXXX)"
  local _ex_stub="$_ex_tmp/gh-stub.sh"
  # Stub: fixture has a normal anomaly issue (#401), an explicit-exclude target
  # (#999), the Stage-13 orchestration sub-task (#500, title matches the regex),
  # and a decoy with "stage 13" but NOT "close" (#600, must NOT be excluded).
  /bin/cat > "$_ex_stub" <<'STUB'
#!/usr/bin/env bash
# Minimal gh stub for the #38 detect_open_issues self-test. Emits the jq'd
# number<TAB>title lines for `issue list`; no-op (exit 0) for anything else.
case "$1" in
  issue)
    if [[ "$2" == "list" ]]; then
      printf '%s\t%s\n' 401 "Normal auto-close anomaly issue"
      printf '%s\t%s\n' 999 "Some explicitly-excluded sub-task"
      printf '%s\t%s\n' 500 "Stage 13 — Close: corpus update orchestration"
      printf '%s\t%s\n' 600 "Stage 13 plan-review follow-up task"
      exit 0
    fi
    ;;
esac
exit 0
STUB
  /bin/chmod +x "$_ex_stub"
  GH="$_ex_stub"; MODE="apply"; STATE_MILESTONE_SLUG="88-some-milestone"

  # (a) AC-4 mixed fixture: exclude #999 explicitly + #500 (Stage-13 sub-task) by
  #     number → ONLY #401 + #600 survive (the decoy #600 stays — it is NOT a
  #     close task). Asserts no Stage-13 self-close + no decoy over-exclude.
  EXCLUDE_ISSUES=(999 500)
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_detect_open_issues >/dev/null 2>&1
  [[ "$(get_phase detect_open_issues)" == PASS\|* ]] || { echo "FAIL: phase_detect_open_issues should PASS, got '$(get_phase detect_open_issues)'"; failures=$((failures+1)); }
  /usr/bin/printf '%s\n' "$OPEN_ISSUE_LIST" | /usr/bin/grep -qx '401' || { echo "FAIL: #401 (anomaly) must survive the exclude filter"; failures=$((failures+1)); }
  /usr/bin/printf '%s\n' "$OPEN_ISSUE_LIST" | /usr/bin/grep -qx '600' || { echo "FAIL: #600 (decoy 'stage 13' but not 'close') must NOT be excluded"; failures=$((failures+1)); }
  /usr/bin/printf '%s\n' "$OPEN_ISSUE_LIST" | /usr/bin/grep -qx '999' && { echo "FAIL: #999 (explicit --exclude-issue) must be filtered out"; failures=$((failures+1)); }
  /usr/bin/printf '%s\n' "$OPEN_ISSUE_LIST" | /usr/bin/grep -qx '500' && { echo "FAIL: #500 (Stage-13 sub-task by number) must be filtered out — cannot self-close (R5)"; failures=$((failures+1)); }

  # (b) title-regex fallback alone (no explicit number for #500): #500 is still
  #     excluded by `(?i)stage.?13.*close`; #401 + #600 survive.
  EXCLUDE_ISSUES=()
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_detect_open_issues >/dev/null 2>&1
  /usr/bin/printf '%s\n' "$OPEN_ISSUE_LIST" | /usr/bin/grep -qx '500' && { echo "FAIL: #500 must be excluded by the title-regex fallback when not passed by number"; failures=$((failures+1)); }
  /usr/bin/printf '%s\n' "$OPEN_ISSUE_LIST" | /usr/bin/grep -qx '401' || { echo "FAIL: #401 must survive (title-regex fallback path)"; failures=$((failures+1)); }
  [[ "$OPEN_ISSUE_COUNT" -eq 3 ]] || { echo "FAIL: title-regex-only path must leave 3 issues (401,600,999), got $OPEN_ISSUE_COUNT"; failures=$((failures+1)); }

  # (c) per-issue --close-comment override resolution (Defect 1): the override
  #     text is returned for the named issue; the anomaly default for others.
  CLOSE_COMMENTS=("401:Tier-0 disposition — closed per design, not an anomaly")
  OPEN_ISSUE_COUNT=1; OPEN_ISSUE_LIST="401"; MODE="dry-run"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_manual_close_release_issues >/dev/null 2>&1
  [[ "$(get_phase manual_close_release_issues)" == DRY-RUN\|* ]] || { echo "FAIL: manual_close dry-run should be DRY-RUN, got '$(get_phase manual_close_release_issues)'"; failures=$((failures+1)); }
  get_phase manual_close_release_issues | /usr/bin/grep -qF 'per-issue --close-comment override' || { echo "FAIL: dry-run detail must note the per-issue --close-comment override"; failures=$((failures+1)); }

  /bin/rm -rf "$_ex_tmp" 2>/dev/null || true
  GH="$_ex_saved_gh"; MODE="$_ex_saved_mode"; STATE_MILESTONE_SLUG="$_ex_saved_slug"
  OPEN_ISSUE_LIST="$_ex_saved_list"; OPEN_ISSUE_COUNT="$_ex_saved_count"
  EXCLUDE_ISSUES=(); CLOSE_COMMENTS=()
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # Test 4d.2: phase_detect_open_issues ARMED-gate classification (#2539 / A6.5 FMF-2)
  # — offline, hermetic. Before the resolver fix, `gh issue list --milestone <slug>` was
  # called with the MIS-RESOLVED Version (e.g. "v3.79"); gh returns an empty list + exit
  # 0 for a nonexistent milestone, so OPEN_ISSUE_COUNT=0 — a SILENT false-negative on
  # every one of the 32 prior pure-alpha releases (the D6 auto-close-anomaly gate never
  # queried the real milestone). Once the fixed resolver yields the real pure-alpha slug,
  # the gate ARMS and counts real open issues. This is the operator-ruled "verify, do NOT
  # assume the count drains to zero" fixture: prove BOTH legs against a MILESTONE-AWARE
  # stub (populated for the correct slug; empty+exit0 for a wrong key — gh's real behavior).
  local _ag_saved_gh="$GH" _ag_saved_mode="$MODE" _ag_saved_slug="$STATE_MILESTONE_SLUG"
  local _ag_saved_list="$OPEN_ISSUE_LIST" _ag_saved_count="$OPEN_ISSUE_COUNT"
  local _ag_tmp; _ag_tmp="$(/usr/bin/mktemp -d -t armedgate-selftest.XXXXXX)"
  local _ag_stub="$_ag_tmp/gh-stub.sh"
  /bin/cat > "$_ag_stub" <<'STUB'
#!/usr/bin/env bash
# Milestone-aware gh stub: emulate `gh issue list --milestone <slug>` returning open
# issues ONLY for the correct pure-alpha milestone title, and an EMPTY list + exit 0
# for any other (mis-resolved) key — gh's real behavior for a nonexistent milestone.
if [[ "$1" == "issue" && "$2" == "list" ]]; then
  ms=""
  while [[ $# -gt 0 ]]; do
    [[ "$1" == "--milestone" ]] && { ms="$2"; break; }
    shift
  done
  if [[ "$ms" == "close-out-reliability-hardening" ]]; then
    printf '%s\t%s\n' 2578 "Some open sub-task"
    printf '%s\t%s\n' 1771 "Another open sub-task"
  fi
  exit 0
fi
exit 0
STUB
  /bin/chmod +x "$_ag_stub"
  GH="$_ag_stub"; MODE="apply"; EXCLUDE_ISSUES=(); CLOSE_COMMENTS=()

  # (a) ARMED: the correct pure-alpha slug (what the fixed resolver returns) → the gate
  #     queries the real milestone and counts its open issues — NOT a false 0.
  STATE_MILESTONE_SLUG="close-out-reliability-hardening"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_detect_open_issues >/dev/null 2>&1
  [[ "$OPEN_ISSUE_COUNT" -eq 2 ]] || { echo "FAIL: armed gate must count 2 open issues for the correct pure-alpha slug (not a false 0), got $OPEN_ISSUE_COUNT"; failures=$((failures+1)); }

  # (b) Pre-fix false-negative (documented, pins the ARMED classification): a MIS-RESOLVED
  #     Version key queries a nonexistent milestone → gh empty + exit 0 → false 0. This is
  #     the silent failure the fixed resolver eliminates; the gate was decorative for 32
  #     releases and now bites.
  STATE_MILESTONE_SLUG="v9.99"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_detect_open_issues >/dev/null 2>&1
  [[ "$OPEN_ISSUE_COUNT" -eq 0 ]] || { echo "FAIL: mis-resolved Version key must reproduce the historical false-0 (gh empty+exit0), got $OPEN_ISSUE_COUNT"; failures=$((failures+1)); }

  /bin/rm -rf "$_ag_tmp" 2>/dev/null || true
  GH="$_ag_saved_gh"; MODE="$_ag_saved_mode"; STATE_MILESTONE_SLUG="$_ag_saved_slug"
  OPEN_ISSUE_LIST="$_ag_saved_list"; OPEN_ISSUE_COUNT="$_ag_saved_count"
  EXCLUDE_ISSUES=(); CLOSE_COMMENTS=()
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # Test 4e: phase_await_merge_chore_pr budget + escape modes (#1705) — offline,
  # hermetic. Asserts: the zero-commit SKIP propagation (CHORE_PR_SKIPPED=1 →
  # await SKIPPED, un-stranding terminal phases); --no-merge → await SKIPPED;
  # BLOCKED-then-CLEAN keep-polling reaches a merge (mock $GH, tiny step/timeout);
  # and the --merge-timeout / --no-merge flags parse into their globals.
  local _mt_saved_gh="$GH" _mt_saved_mode="$MODE" _mt_saved_pr="$CHORE_PR_NUMBER"
  local _mt_saved_skipped="$CHORE_PR_SKIPPED" _mt_saved_nomerge="$NO_MERGE"
  local _mt_saved_timeout="$MERGE_TIMEOUT" _mt_saved_step="$MERGE_POLL_STEP" _mt_saved_slug="$REPO_SLUG"
  MODE="apply"; CHORE_PR_NUMBER="7777"; REPO_SLUG="x/y"

  # (a) zero-commit SKIP propagation: CHORE_PR_SKIPPED=1 → await SKIPPED (no gh call)
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  CHORE_PR_SKIPPED=1; NO_MERGE=0
  phase_await_merge_chore_pr >/dev/null 2>&1
  [[ "$(get_phase await_merge_chore_pr)" == SKIPPED\|* ]] || { echo "FAIL: await_merge must SKIP when CHORE_PR_SKIPPED=1 (zero-commit propagation), got '$(get_phase await_merge_chore_pr)'"; failures=$((failures+1)); }

  # (b) --no-merge → await SKIPPED (PR left open for operator)
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  CHORE_PR_SKIPPED=0; NO_MERGE=1
  phase_await_merge_chore_pr >/dev/null 2>&1
  [[ "$(get_phase await_merge_chore_pr)" == SKIPPED\|* ]] || { echo "FAIL: await_merge must SKIP under --no-merge, got '$(get_phase await_merge_chore_pr)'"; failures=$((failures+1)); }

  # (c) BLOCKED-then-CLEAN keep-polling reaches a merge. Stub $GH so `pr view`
  #     returns MERGEABLE/BLOCKED on the first call and MERGEABLE/CLEAN after
  #     (proving BLOCKED is keep-polling, not terminal), and `pr merge` exits 0.
  local _mt_tmp; _mt_tmp="$(/usr/bin/mktemp -d -t mergeawait-selftest.XXXXXX)"
  local _mt_ctr="$_mt_tmp/calls"; /usr/bin/printf '0' > "$_mt_ctr"
  local _mt_stub="$_mt_tmp/gh-stub.sh"
  /bin/cat > "$_mt_stub" <<STUB
#!/usr/bin/env bash
# #1705 await-merge stub. \`pr view\` → BLOCKED first, CLEAN after; \`pr merge\` → ok.
ctr_file="$_mt_ctr"
if [[ "\$1" == "pr" && "\$2" == "view" ]]; then
  n="\$(/bin/cat "\$ctr_file" 2>/dev/null || echo 0)"
  /usr/bin/printf '%s' "\$((n+1))" > "\$ctr_file"
  if [[ "\$n" -eq 0 ]]; then echo "MERGEABLE/BLOCKED"; else echo "MERGEABLE/CLEAN"; fi
  exit 0
fi
if [[ "\$1" == "pr" && "\$2" == "merge" ]]; then exit 0; fi
exit 0
STUB
  /bin/chmod +x "$_mt_stub"
  GH="$_mt_stub"; CHORE_PR_SKIPPED=0; NO_MERGE=0; MERGE_TIMEOUT=5; MERGE_POLL_STEP=0
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_await_merge_chore_pr >/dev/null 2>&1
  [[ "$(get_phase await_merge_chore_pr)" == PASS\|* ]] || { echo "FAIL: await_merge must PASS after BLOCKED→CLEAN keep-polling, got '$(get_phase await_merge_chore_pr)'"; failures=$((failures+1)); }
  [[ "$(/bin/cat "$_mt_ctr")" -ge 2 ]] || { echo "FAIL: await_merge must POLL again after BLOCKED (>=2 pr view calls), got $(/bin/cat "$_mt_ctr")"; failures=$((failures+1)); }

  # (d) CONFLICTING → FAIL (terminal HALT, regression guard)
  /usr/bin/printf '0' > "$_mt_ctr"
  local _mt_stub2="$_mt_tmp/gh-stub2.sh"
  /bin/cat > "$_mt_stub2" <<'STUB'
#!/usr/bin/env bash
if [[ "$1" == "pr" && "$2" == "view" ]]; then echo "CONFLICTING/DIRTY"; exit 0; fi
exit 0
STUB
  /bin/chmod +x "$_mt_stub2"
  GH="$_mt_stub2"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  if phase_await_merge_chore_pr >/dev/null 2>&1; then
    echo "FAIL: await_merge must FAIL (HALT) on CONFLICTING"; failures=$((failures+1))
  fi
  [[ "$(get_phase await_merge_chore_pr | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: CONFLICTING must mark FAIL"; failures=$((failures+1)); }

  /bin/rm -rf "$_mt_tmp" 2>/dev/null || true
  GH="$_mt_saved_gh"; MODE="$_mt_saved_mode"; CHORE_PR_NUMBER="$_mt_saved_pr"
  CHORE_PR_SKIPPED="$_mt_saved_skipped"; NO_MERGE="$_mt_saved_nomerge"
  MERGE_TIMEOUT="$_mt_saved_timeout"; MERGE_POLL_STEP="$_mt_saved_step"; REPO_SLUG="$_mt_saved_slug"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # Test 4e.2: --no-merge post-merge phase-gating (#2919) — offline, hermetic.
  # Asserts the four post-merge-dependent phases DEFER (SKIP with a "no-merge" detail)
  # under NO_MERGE=1 EVEN WHEN their normal precondition to act is met (open milestone,
  # open issues) — i.e. the guard is unconditional under --no-merge and fires before any
  # network preflight. Then a NO_MERGE=0 negative check (dry-run, hermetic) confirms the
  # guard is --no-merge-scoped and does NOT fire on the normal path. Regression guard for
  # the Stage 13 sequencing invariant (stage-13-close.md § Phase B): a --no-merge run must
  # NOT close the milestone / publish the Release while the chore PR is still open.
  local _nm_saved_nomerge="$NO_MERGE" _nm_saved_mode="$MODE" _nm_saved_gh="$GH"
  local _nm_saved_mstate="$STATE_MILESTONE_STATE" _nm_saved_oic="$OPEN_ISSUE_COUNT"
  local _nm_saved_oil="$OPEN_ISSUE_LIST" _nm_saved_cpn="$CHORE_PR_NUMBER" _nm_saved_ms="$MILESTONE"
  # A false GH proves the assertions never touch the network: a correct guard returns
  # before any $GH / git_net call, so a phase that reached one would error, not SKIP.
  GH="/bin/false"; CHORE_PR_NUMBER="8888"; MILESTONE="9999"; CLOSE_COMMENTS=()

  # (a) NO_MERGE=1 → all four phases DEFER (SKIPPED + "no-merge" detail), even with an
  #     OPEN milestone and OPEN issues (preconditions that would otherwise act).
  NO_MERGE=1; MODE="apply"; STATE_MILESTONE_STATE="open"; OPEN_ISSUE_COUNT=2; OPEN_ISSUE_LIST=$'401\n402'
  local _nm_ph
  for _nm_ph in post_close_milestone manual_close_release_issues publish_github_release check_release_body_drift; do
    PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
    "phase_${_nm_ph}" >/dev/null 2>&1
    [[ "$(get_phase "$_nm_ph" | /usr/bin/cut -d'|' -f1)" == "SKIPPED" ]] || { echo "FAIL: $_nm_ph must SKIP (defer) under --no-merge, got '$(get_phase "$_nm_ph")'"; failures=$((failures+1)); }
    get_phase "$_nm_ph" | /usr/bin/grep -qiF 'no-merge' || { echo "FAIL: $_nm_ph defer detail must cite --no-merge, got '$(get_phase "$_nm_ph")'"; failures=$((failures+1)); }
  done

  # (b) NO_MERGE=0 negative check (dry-run, hermetic): post_close_milestone +
  #     manual_close_release_issues must NOT emit the defer sentinel on the normal path
  #     (they hit their DRY-RUN branch instead). publish/drift NO_MERGE=0 behavior is
  #     covered by the tag-stub / drift tests elsewhere in the self-test.
  NO_MERGE=0; MODE="dry-run"; STATE_MILESTONE_STATE="open"; OPEN_ISSUE_COUNT=1; OPEN_ISSUE_LIST="401"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_post_close_milestone >/dev/null 2>&1
  get_phase post_close_milestone | /usr/bin/grep -qiF 'DEFERRED under --no-merge' && { echo "FAIL: post_close_milestone must NOT defer when NO_MERGE=0"; failures=$((failures+1)); }
  [[ "$(get_phase post_close_milestone | /usr/bin/cut -d'|' -f1)" == "DRY-RUN" ]] || { echo "FAIL: post_close_milestone NO_MERGE=0 dry-run should be DRY-RUN, got '$(get_phase post_close_milestone)'"; failures=$((failures+1)); }
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_manual_close_release_issues >/dev/null 2>&1
  get_phase manual_close_release_issues | /usr/bin/grep -qiF 'DEFERRED under --no-merge' && { echo "FAIL: manual_close_release_issues must NOT defer when NO_MERGE=0"; failures=$((failures+1)); }
  [[ "$(get_phase manual_close_release_issues | /usr/bin/cut -d'|' -f1)" == "DRY-RUN" ]] || { echo "FAIL: manual_close_release_issues NO_MERGE=0 dry-run should be DRY-RUN, got '$(get_phase manual_close_release_issues)'"; failures=$((failures+1)); }

  NO_MERGE="$_nm_saved_nomerge"; MODE="$_nm_saved_mode"; GH="$_nm_saved_gh"
  STATE_MILESTONE_STATE="$_nm_saved_mstate"; OPEN_ISSUE_COUNT="$_nm_saved_oic"
  OPEN_ISSUE_LIST="$_nm_saved_oil"; CHORE_PR_NUMBER="$_nm_saved_cpn"; MILESTONE="$_nm_saved_ms"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # Test 4f: phase_transition_release_log VERIFIED re-derivation guard (#1681) —
  # offline, hermetic. Stubs $GH so `pr view` reports the release-PR merge state,
  # then asserts: a VERIFIED row + MERGED-to-main PR → SKIPPED-as-PASS (legitimate
  # idempotent re-run); a VERIFIED row + UNMERGED PR → FAIL (false-VERIFIED, do not
  # trust the string blind); a DEPLOYED row → normal transition (regression guard).
  local _td_saved_gh="$GH" _td_saved_mode="$MODE" _td_saved_state="$STATE_LOG_ROW_STATE"
  local _td_saved_pr="$PR_NUMBER" _td_saved_slug="$REPO_SLUG" _td_saved_log="$RELEASE_LOG"
  local _td_saved_msslug="$STATE_MILESTONE_SLUG" _td_saved_version="$VERSION"
  local _td_tmp; _td_tmp="$(/usr/bin/mktemp -d -t transition-selftest.XXXXXX)"
  PR_NUMBER="4242"; REPO_SLUG="x/y"; STATE_MILESTONE_SLUG="88-some-milestone"; VERSION="v9.93"
  RELEASE_LOG="$_td_tmp/RELEASE_LOG.md"
  local _td_stub_merged="$_td_tmp/gh-merged.sh" _td_stub_open="$_td_tmp/gh-open.sh"
  /bin/cat > "$_td_stub_merged" <<'STUB'
#!/usr/bin/env bash
if [[ "$1" == "pr" && "$2" == "view" ]]; then echo "MERGED/main"; exit 0; fi
exit 0
STUB
  /bin/cat > "$_td_stub_open" <<'STUB'
#!/usr/bin/env bash
if [[ "$1" == "pr" && "$2" == "view" ]]; then echo "OPEN/main"; exit 0; fi
exit 0
STUB
  /bin/chmod +x "$_td_stub_merged" "$_td_stub_open"

  # (a) VERIFIED row + MERGED-to-main PR → SKIPPED-as-PASS
  GH="$_td_stub_merged"; MODE="apply"; STATE_LOG_ROW_STATE="VERIFIED"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_transition_release_log >/dev/null 2>&1
  [[ "$(get_phase transition_release_log)" == SKIPPED\|* ]] || { echo "FAIL: transition VERIFIED+merged-PR must SKIP-as-PASS, got '$(get_phase transition_release_log)'"; failures=$((failures+1)); }

  # (b) VERIFIED row + UNMERGED PR → FAIL (false-VERIFIED)
  GH="$_td_stub_open"; STATE_LOG_ROW_STATE="VERIFIED"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  if phase_transition_release_log >/dev/null 2>&1; then
    echo "FAIL: transition VERIFIED+unmerged-PR must FAIL (false-VERIFIED)"; failures=$((failures+1))
  fi
  [[ "$(get_phase transition_release_log | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: VERIFIED+unmerged must mark FAIL (#1681)"; failures=$((failures+1)); }

  # (c) DEPLOYED row → normal transition to VERIFIED (regression guard). Needs a
  #     sandbox RELEASE_LOG with a DEPLOYED row for slug=88-some-milestone.
  /bin/cat > "$RELEASE_LOG" <<'EOF'
# RELEASE_LOG
| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |
|---|---|---|---|---|---|---|---|
| v9.93 | 88-some-milestone | #1 | #4242 | sha | v9.93 | DEPLOYED | 2026-06-28 |
EOF
  GH="$_td_stub_merged"; STATE_LOG_ROW_STATE="DEPLOYED"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_transition_release_log >/dev/null 2>&1
  [[ "$(get_phase transition_release_log)" == PASS\|* ]] || { echo "FAIL: transition DEPLOYED row must PASS (normal transition), got '$(get_phase transition_release_log)'"; failures=$((failures+1)); }
  /usr/bin/grep -qE '^\| v9\.93 \| 88-some-milestone \|.*\| VERIFIED \|' "$RELEASE_LOG" || { echo "FAIL: DEPLOYED→VERIFIED transition must flip the v9.93 row state"; failures=$((failures+1)); }

  # (d) #2539 AC-2 + AC-3 — END-TO-END pure-alpha parity. The blind-spot that let #2539
  #     ship: Test 4 tests the resolver in isolation and case (c) hard-assigns the global
  #     — neither drives the resolver → phase-6 COMPOSITION. Here the slug is RESOLVED
  #     FROM THE ROW (not hard-assigned), then phase 6 runs in BOTH modes: AC-3 dry-run
  #     verdict <=> apply verdict (one predicate); AC-2 the pure-alpha row flips to VERIFIED.
  /bin/cat > "$RELEASE_LOG" <<'EOF'
# RELEASE_LOG
| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |
|---|---|---|---|---|---|---|---|
| v9.94 | close-out-reliability-hardening | #2539 | #4242 | sha | v9.94 | DEPLOYED | 2026-07-18 |
EOF
  VERSION="v9.94"
  STATE_MILESTONE_SLUG="$(extract_milestone_slug "$(find_log_row "$VERSION")")"
  [[ "$STATE_MILESTONE_SLUG" == "close-out-reliability-hardening" ]] || { echo "FAIL: AC-2 end-to-end resolver must yield the pure-alpha slug from the row, got '$STATE_MILESTONE_SLUG'"; failures=$((failures+1)); }
  GH="$_td_stub_merged"; MODE="dry-run"; STATE_LOG_ROW_STATE="DEPLOYED"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_transition_release_log >/dev/null 2>&1
  [[ "$(get_phase transition_release_log | /usr/bin/cut -d'|' -f1)" == "DRY-RUN" ]] || { echo "FAIL: AC-3 pure-alpha dry-run must be DRY-RUN (predict apply), got '$(get_phase transition_release_log)'"; failures=$((failures+1)); }
  MODE="apply"; STATE_LOG_ROW_STATE="DEPLOYED"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_transition_release_log >/dev/null 2>&1
  [[ "$(get_phase transition_release_log)" == PASS\|* ]] || { echo "FAIL: AC-3 pure-alpha apply must PASS (parity with dry-run), got '$(get_phase transition_release_log)'"; failures=$((failures+1)); }
  /usr/bin/grep -qE '^\| v9\.94 \| close-out-reliability-hardening \|.*\| VERIFIED \|' "$RELEASE_LOG" || { echo "FAIL: AC-2 pure-alpha DEPLOYED->VERIFIED transition must flip the row"; failures=$((failures+1)); }

  # (e) #2539 AC-3 negative (the load-bearing parity assertion): a slug matching NO row
  #     must make the dry-run FAIL too. Under the pre-delta code the dry-run only printed
  #     (never tested the slug predicate), so it passed while --apply aborted — the exact
  #     defect-hiding gap. With log_row_match, dry-run FAILs for a no-match slug.
  MODE="dry-run"; STATE_MILESTONE_SLUG="no-such-milestone-slug"; STATE_LOG_ROW_STATE="DEPLOYED"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  # `if …; then` wraps the expected-FAIL phase (suppresses set -e inside it, per the
  # existing self-test idiom); the phase returning non-zero means the then-branch is skipped.
  if phase_transition_release_log >/dev/null 2>&1; then
    echo "FAIL: AC-3 negative — dry-run must return non-zero for a no-match slug (parity with apply)"; failures=$((failures+1))
  fi
  [[ "$(get_phase transition_release_log | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: AC-3 negative — dry-run must mark transition FAIL for a no-match slug, got '$(get_phase transition_release_log)'"; failures=$((failures+1)); }

  # (f) #2539 D-3 true-count (A6.5 FMF-1): log_row_match `count` must return the TRUE
  #     number of matching rows (findall), NOT a capped count=1 — else an over-match
  #     (n>=2) returns 1 and silently disarms the D-3 preflight gate. Two rows sharing a
  #     slug must count as 2 (rc!=0 => D-3 FAILs); a unique slug counts as 1 (rc 0).
  /bin/cat > "$RELEASE_LOG" <<'EOF'
# RELEASE_LOG
| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |
|---|---|---|---|---|---|---|---|
| v9.95 | dup-slug | #1 | #10 | sha | v9.95 | DEPLOYED | 2026-07-18 |
| v9.96 | dup-slug | #2 | #11 | sha | v9.96 | DEPLOYED | 2026-07-18 |
| v9.97 | uniq-slug | #3 | #12 | sha | v9.97 | DEPLOYED | 2026-07-18 |
EOF
  local _d3_dup _d3_uniq
  # `|| true` keeps the count-substitution from tripping set -e when log_row_match
  # exits non-zero (n!=1) — the printed count is still captured; we assert the VALUE.
  _d3_dup="$(log_row_match "dup-slug" 'DEPLOYED|VERIFIED' count)" || true
  [[ "$_d3_dup" == "2" ]] || { echo "FAIL: D-3 true-count must return 2 for a 2-row over-match (findall, not capped count=1), got '$_d3_dup'"; failures=$((failures+1)); }
  log_row_match "dup-slug" 'DEPLOYED|VERIFIED' count >/dev/null 2>&1 && { echo "FAIL: D-3 gate — log_row_match count must exit non-zero for an over-match (n=2); a passing rc would disarm the gate"; failures=$((failures+1)); }
  _d3_uniq="$(log_row_match "uniq-slug" 'DEPLOYED|VERIFIED' count)" || true
  [[ "$_d3_uniq" == "1" ]] || { echo "FAIL: D-3 true-count must return 1 for a unique slug, got '$_d3_uniq'"; failures=$((failures+1)); }
  log_row_match "uniq-slug" 'DEPLOYED|VERIFIED' count >/dev/null 2>&1 || { echo "FAIL: D-3 gate — log_row_match count must exit zero for a unique slug (n=1)"; failures=$((failures+1)); }

  /bin/rm -rf "$_td_tmp" 2>/dev/null || true
  GH="$_td_saved_gh"; MODE="$_td_saved_mode"; STATE_LOG_ROW_STATE="$_td_saved_state"
  PR_NUMBER="$_td_saved_pr"; REPO_SLUG="$_td_saved_slug"; RELEASE_LOG="$_td_saved_log"
  STATE_MILESTONE_SLUG="$_td_saved_msslug"; VERSION="$_td_saved_version"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # Test 4g: phase_ledger_guard + phase_reparse_ledgers (#1680) — offline,
  # hermetic via a REAL local git sandbox (a working repo + a `origin` bare remote
  # so `git_net diff origin/main` / `git_net show origin/main:...` resolve without
  # a network). Asserts: a clean additive working-tree diff → guard PASS; a diff
  # that REMOVES a foreign version row (I1 contention) → guard FAIL; a diff that
  # regresses a prior VERIFIED row (I2) → guard FAIL; a well-formed merged corpus →
  # reparse PASS; a malformed corpus (8-col INDEX row OR duplicate DIGEST H3) →
  # reparse FAIL. git is REQUIRED for this test — if absent, the block self-skips.
  if [[ -x "$GIT" ]]; then
    local _lg_saved_root="$REPO_ROOT" _lg_saved_mode="$MODE" _lg_saved_version="$VERSION"
    local _lg_saved_skipped="$CHORE_PR_SKIPPED" _lg_saved_nomerge="$NO_MERGE"
    local _lg_tmp; _lg_tmp="$(/usr/bin/mktemp -d -t ledgerguard-selftest.XXXXXX)"
    local _lg_origin="$_lg_tmp/origin.git" _lg_work="$_lg_tmp/work"
    # Build a bare origin + a working clone seeded with a baseline corpus carrying
    # MY version (v9.91) AND a sibling (v9.90), all committed on main.
    $GIT init --bare -q "$_lg_origin" 2>/dev/null
    $GIT init -q -b main "$_lg_work" 2>/dev/null || { $GIT init -q "$_lg_work"; ( cd "$_lg_work" && $GIT checkout -q -b main 2>/dev/null ); }
    /bin/mkdir -p "$_lg_work/release/releases/notes"
    /bin/cat > "$_lg_work/release/releases/RELEASE_INDEX.md" <<'EOF'
# RELEASE_INDEX

| Version | Milestone | Date | Theme | Release PR | Release Notes |
|---|---|---|---|---|---|
| v9.91 | 91-mine | 2026-06-28 | — | #9100 | [notes/v9.91_RELEASE_NOTES.md](notes/v9.91_RELEASE_NOTES.md) |
| v9.90 | 90-sibling | 2026-06-27 | sibling | #9000 | [notes/v9.90_RELEASE_NOTES.md](notes/v9.90_RELEASE_NOTES.md) |
EOF
    /bin/cat > "$_lg_work/release/releases/RELEASE_DIGEST.md" <<'EOF'
# RELEASE_DIGEST

## Knowledge Corpus

### v9.91 (2026-06-28) — Mine
### v9.90 (2026-06-27) — Sibling
EOF
    /bin/cat > "$_lg_work/release/releases/RELEASE_LOG.md" <<'EOF'
# RELEASE_LOG
| v9.91 | 91-mine | #1 | #9100 | sha | v9.91 | VERIFIED | 2026-06-28 |
| v9.90 | 90-sibling | #2 | #9000 | sha | v9.90 | VERIFIED | 2026-06-27 |
EOF
    /usr/bin/printf '# Changelog\n\n## [v9.91] - 2026-06-28\nmine\n\n## [v9.90] - 2026-06-27\nsibling\n' > "$_lg_work/CHANGELOG.md"
    ( cd "$_lg_work" \
      && $GIT -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1 \
      && $GIT -c user.email=t@t -c user.name=t commit -qm baseline >/dev/null 2>&1 \
      && $GIT remote add origin "$_lg_origin" >/dev/null 2>&1 \
      && $GIT push -q origin main >/dev/null 2>&1 \
      && $GIT branch -q --set-upstream-to=origin/main main >/dev/null 2>&1 ) || true

    REPO_ROOT="$_lg_work"; MODE="apply"; VERSION="v9.91"; CHORE_PR_SKIPPED=0; NO_MERGE=0

    # (a) clean additive diff (touch only MY rows): re-write MY DIGEST headline +
    #     MY INDEX theme — additive-style edit to my own entries → guard PASS.
    /usr/bin/sed -i.bak 's/### v9.91 (2026-06-28) — Mine/### v9.91 (2026-06-28) — Mine updated/' "$_lg_work/release/releases/RELEASE_DIGEST.md" 2>/dev/null; /bin/rm -f "$_lg_work/release/releases/RELEASE_DIGEST.md.bak"
    PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
    phase_ledger_guard >/dev/null 2>&1
    [[ "$(get_phase ledger_guard)" == PASS\|* ]] || { echo "FAIL: ledger_guard must PASS on a clean my-own-rows diff, got '$(get_phase ledger_guard)'"; failures=$((failures+1)); }

    # (b) I1 contention: REMOVE the sibling v9.90 INDEX row → guard FAIL.
    ( cd "$_lg_work" && $GIT checkout -q -- . 2>/dev/null )   # reset working tree to baseline
    /usr/bin/sed -i.bak '/^| v9.90 | 90-sibling |/d' "$_lg_work/release/releases/RELEASE_INDEX.md" 2>/dev/null; /bin/rm -f "$_lg_work/release/releases/RELEASE_INDEX.md.bak"
    PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
    if phase_ledger_guard >/dev/null 2>&1; then
      echo "FAIL: ledger_guard must FAIL when a foreign (v9.90) INDEX row is removed (I1 contention)"; failures=$((failures+1))
    fi
    [[ "$(get_phase ledger_guard | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: I1 foreign-row removal must mark ledger_guard FAIL"; failures=$((failures+1)); }

    # (c) I2 regression: regress the sibling v9.90 LOG row VERIFIED→DEPLOYED → FAIL.
    ( cd "$_lg_work" && $GIT checkout -q -- . 2>/dev/null )
    /usr/bin/sed -i.bak 's/| v9.90 | 90-sibling | #2 | #9000 | sha | v9.90 | VERIFIED |/| v9.90 | 90-sibling | #2 | #9000 | sha | v9.90 | DEPLOYED |/' "$_lg_work/release/releases/RELEASE_LOG.md" 2>/dev/null; /bin/rm -f "$_lg_work/release/releases/RELEASE_LOG.md.bak"
    PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
    if phase_ledger_guard >/dev/null 2>&1; then
      echo "FAIL: ledger_guard must FAIL when a prior VERIFIED row (v9.90) regresses to DEPLOYED (I2)"; failures=$((failures+1))
    fi
    [[ "$(get_phase ledger_guard | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: I2 VERIFIED→DEPLOYED regression must mark ledger_guard FAIL"; failures=$((failures+1)); }
    ( cd "$_lg_work" && $GIT checkout -q -- . 2>/dev/null )

    # (d) reparse: well-formed merged corpus (origin/main as-seeded) → PASS.
    PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
    phase_reparse_ledgers >/dev/null 2>&1
    [[ "$(get_phase reparse_ledgers)" == PASS\|* ]] || { echo "FAIL: reparse_ledgers must PASS on a well-formed merged corpus, got '$(get_phase reparse_ledgers)'"; failures=$((failures+1)); }

    # (e) reparse FAIL: push a MALFORMED corpus to origin/main (duplicate DIGEST H3
    #     for my version) → reparse FAIL.
    /usr/bin/printf '### v9.91 (2026-06-28) — Mine DUP\n' >> "$_lg_work/release/releases/RELEASE_DIGEST.md"
    ( cd "$_lg_work" \
      && $GIT -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1 \
      && $GIT -c user.email=t@t -c user.name=t commit -qm dup >/dev/null 2>&1 \
      && $GIT push -q origin main >/dev/null 2>&1 ) || true
    PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
    if phase_reparse_ledgers >/dev/null 2>&1; then
      echo "FAIL: reparse_ledgers must FAIL on a duplicate DIGEST H3 (concurrent-merge dup)"; failures=$((failures+1))
    fi
    [[ "$(get_phase reparse_ledgers | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: duplicate DIGEST H3 must mark reparse_ledgers FAIL"; failures=$((failures+1)); }

    /bin/rm -rf "$_lg_tmp" 2>/dev/null || true
    REPO_ROOT="$_lg_saved_root"; MODE="$_lg_saved_mode"; VERSION="$_lg_saved_version"
    CHORE_PR_SKIPPED="$_lg_saved_skipped"; NO_MERGE="$_lg_saved_nomerge"
    PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  else
    echo "  (skipped #1680 ledger-guard/reparse self-test — git not executable at $GIT)" >&2
  fi

  # Test 4h: MERGE_SHA capture + tag↔SHA identity assertion (#1682) — offline,
  # hermetic. Part 1 (capture) stubs $GH so `pr view --json mergeCommit` returns a
  # fixed oid and asserts phase_read_state populates MERGE_SHA. Part 2 (identity)
  # uses a real local git sandbox with a tag at a known commit pushed to origin,
  # and a $GH stub (release view fails → create path; release create records its
  # args) to assert: tag-at-MERGE_SHA → publish PASS + `--target <sha>` on the
  # create command; tag-at-different-SHA → publish FAIL (identity mismatch).
  local _ms_saved_gh="$GH" _ms_saved_pr="$PR_NUMBER" _ms_saved_slug="$REPO_SLUG" _ms_saved_mergesha="$MERGE_SHA"

  # Part 1 — capture
  local _ms_tmp; _ms_tmp="$(/usr/bin/mktemp -d -t mergesha-selftest.XXXXXX)"
  local _ms_cap_stub="$_ms_tmp/gh-cap.sh"
  /bin/cat > "$_ms_cap_stub" <<'STUB'
#!/usr/bin/env bash
# pr view --json mergeCommit → fixed oid; api milestones → state; else empty.
if [[ "$1" == "pr" && "$2" == "view" ]]; then echo "feedfacecafebeadfeedfacecafebeadfeedface"; exit 0; fi
if [[ "$1" == "api" ]]; then echo "closed"; exit 0; fi
exit 0
STUB
  /bin/chmod +x "$_ms_cap_stub"
  GH="$_ms_cap_stub"; PR_NUMBER="5151"; REPO_SLUG="x/y"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_read_state >/dev/null 2>&1
  [[ "$MERGE_SHA" == "feedfacecafebeadfeedfacecafebeadfeedface" ]] || { echo "FAIL: phase_read_state must capture MERGE_SHA from the release PR, got '$MERGE_SHA'"; failures=$((failures+1)); }

  # Part 2 — identity assertion (needs git)
  if [[ -x "$GIT" ]]; then
    local _ms_saved_root="$REPO_ROOT" _ms_saved_mode="$MODE" _ms_saved_version="$VERSION" _ms_saved_notesdir="$RELEASE_NOTES_DIR"
    local _ms_origin="$_ms_tmp/origin.git" _ms_work="$_ms_tmp/work"
    $GIT init --bare -q "$_ms_origin" 2>/dev/null
    $GIT init -q -b main "$_ms_work" 2>/dev/null || { $GIT init -q "$_ms_work"; ( cd "$_ms_work" && $GIT checkout -q -b main 2>/dev/null ); }
    /bin/mkdir -p "$_ms_work/release/releases/notes"
    /usr/bin/printf -- '---\nversion: v9.89\n---\n\n# Real headline\n\nbody\n' > "$_ms_work/release/releases/notes/v9.89_RELEASE_NOTES.md"
    local _ms_commit
    ( cd "$_ms_work" \
      && $GIT -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1 \
      && $GIT -c user.email=t@t -c user.name=t commit -qm seed >/dev/null 2>&1 \
      && $GIT -c user.email=t@t -c user.name=t tag -a -m v9.89 v9.89 >/dev/null 2>&1 \
      && $GIT remote add origin "$_ms_origin" >/dev/null 2>&1 \
      && $GIT push -q origin main >/dev/null 2>&1 \
      && $GIT push -q origin v9.89 >/dev/null 2>&1 ) || true
    _ms_commit="$( cd "$_ms_work" && $GIT rev-list -n1 v9.89 2>/dev/null )"

    # $GH stub: release view → fail (State 0 / create path); release create → ok +
    # record its argv so we can assert --target was passed; ls-remote is git_net.
    local _ms_argfile="$_ms_tmp/create-args"
    local _ms_pub_stub="$_ms_tmp/gh-pub.sh"
    /bin/cat > "$_ms_pub_stub" <<STUB
#!/usr/bin/env bash
if [[ "\$1" == "release" && "\$2" == "view" ]]; then exit 1; fi
if [[ "\$1" == "release" && "\$2" == "create" ]]; then printf '%s\n' "\$*" > "$_ms_argfile"; exit 0; fi
exit 0
STUB
    /bin/chmod +x "$_ms_pub_stub"
    GH="$_ms_pub_stub"; REPO_ROOT="$_ms_work"; MODE="apply"; VERSION="v9.89"
    RELEASE_NOTES_DIR="$_ms_work/release/releases/notes"

    # (a) tag-at-MERGE_SHA → PASS + --target on the create command
    MERGE_SHA="$_ms_commit"
    PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
    phase_publish_github_release >/dev/null 2>&1
    [[ "$(get_phase publish_github_release)" == PASS\|* ]] || { echo "FAIL: publish must PASS when the tag == MERGE_SHA, got '$(get_phase publish_github_release)'"; failures=$((failures+1)); }
    /usr/bin/grep -qF -- "--target $_ms_commit" "$_ms_argfile" 2>/dev/null || { echo "FAIL: gh release create must include '--target <MERGE_SHA>' (#1682 non-optional bind)"; failures=$((failures+1)); }

    # (b) tag-at-different-SHA → FAIL (identity mismatch)
    MERGE_SHA="deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
    PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
    if phase_publish_github_release >/dev/null 2>&1; then
      echo "FAIL: publish must FAIL when the tag points at a different SHA than MERGE_SHA (#1682 identity mismatch)"; failures=$((failures+1))
    fi
    [[ "$(get_phase publish_github_release | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: tag↔MERGE_SHA mismatch must mark publish FAIL"; failures=$((failures+1)); }

    REPO_ROOT="$_ms_saved_root"; MODE="$_ms_saved_mode"; VERSION="$_ms_saved_version"; RELEASE_NOTES_DIR="$_ms_saved_notesdir"
  else
    echo "  (skipped #1682 identity-assertion self-test — git not executable at $GIT)" >&2
  fi

  /bin/rm -rf "$_ms_tmp" 2>/dev/null || true
  GH="$_ms_saved_gh"; PR_NUMBER="$_ms_saved_pr"; REPO_SLUG="$_ms_saved_slug"; MERGE_SHA="$_ms_saved_mergesha"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # Test 5: check_parser_clean — must reject close-family + #N
  check_parser_clean "Safe summary text" || { echo "FAIL: parser-clean on safe text"; failures=$((failures+1)); }
  ! check_parser_clean "This closes #123" || { echo "FAIL: parser-clean should reject 'closes #123'"; failures=$((failures+1)); }
  ! check_parser_clean "fixes #45" || { echo "FAIL: parser-clean should reject 'fixes #45'"; failures=$((failures+1)); }
  ! check_parser_clean "resolves #999" || { echo "FAIL: parser-clean should reject 'resolves #999'"; failures=$((failures+1)); }
  ! check_parser_clean "does not close #234" || { echo "FAIL: parser-clean should reject negated form 'close #234' (lexical, not semantic)"; failures=$((failures+1)); }
  check_parser_clean "mark #234 as closed" || { echo "FAIL: parser-clean should ACCEPT safe phrasing 'mark #N as closed'"; failures=$((failures+1)); }

  # Test 5.5: phase_lint_release_notes — §3.2 note-content close gate (#2082).
  # Hermetic: point REPO_ROOT at a sandbox carrying a STUB lint script whose
  # exit code + output we control, then assert the phase's version-scoped
  # block/proceed decision. The stub stands in for lint_release_corpus.py so the
  # test exercises the CALLER's grep-scoping logic without touching the live
  # corpus (the lint's own checks are covered by the linter's own tests).
  local _ln_saved_root="$REPO_ROOT" _ln_saved_version="$VERSION"
  local _ln_tmp; _ln_tmp="$(/usr/bin/mktemp -d -t lintnotes-selftest.XXXXXX)"
  /bin/mkdir -p "$_ln_tmp/core/deploy/tools"
  local _ln_stub="$_ln_tmp/core/deploy/tools/lint_release_corpus.py"
  # Stub reads desired exit code from env LN_EXIT and prints LN_OUT verbatim.
  /bin/cat > "$_ln_stub" <<'STUB'
import os, sys
sys.stdout.write(os.environ.get("LN_OUT", ""))
sys.exit(int(os.environ.get("LN_EXIT", "0")))
STUB
  REPO_ROOT="$_ln_tmp"; VERSION="v9.99"
  # Reset phase tallies so get_phase reads only this test's marks.
  local _ln_saved_names=("${PHASE_NAMES[@]:-}") _ln_saved_results=("${PHASE_RESULTS[@]:-}") _ln_saved_details=("${PHASE_DETAILS[@]:-}")

  # (a) clean corpus (exit 0) → PASS
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  LN_EXIT=0 LN_OUT="" phase_lint_release_notes >/dev/null 2>&1 || true
  [[ "$(get_phase lint_release_notes | /usr/bin/cut -d'|' -f1)" == "PASS" ]] || { echo "FAIL: lint_release_notes clean corpus (exit 0) must PASS"; failures=$((failures+1)); }

  # (b) finding for THIS version (exit 1) → FAIL (close BLOCKED)
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  if LN_EXIT=1 LN_OUT="NOTE-6A-MISSING: release/releases/notes/v9.99_RELEASE_NOTES.md lacks section" phase_lint_release_notes >/dev/null 2>&1; then
    echo "FAIL: lint_release_notes must return non-zero (BLOCK) on a finding for THIS version"; failures=$((failures+1))
  fi
  [[ "$(get_phase lint_release_notes | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: lint_release_notes this-version finding must mark FAIL"; failures=$((failures+1)); }

  # (c) finding ONLY for a DIFFERENT version (exit 1) → PASS (out-of-scope legacy debt)
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  LN_EXIT=1 LN_OUT="NOTE-6A-MISSING: release/releases/notes/v2.19_RELEASE_NOTES.md lacks section" phase_lint_release_notes >/dev/null 2>&1 || { echo "FAIL: lint_release_notes must NOT block on another version's pre-existing finding"; failures=$((failures+1)); }
  [[ "$(get_phase lint_release_notes | /usr/bin/cut -d'|' -f1)" == "PASS" ]] || { echo "FAIL: lint_release_notes other-version-only finding must PASS (audit-baseline)"; failures=$((failures+1)); }

  # (d) path-resolution failure (exit 3) → FAIL (unverifiable; fail-loud)
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  if LN_EXIT=3 LN_OUT="CORPUS-PATH-UNRESOLVED: notes dir does not resolve" phase_lint_release_notes >/dev/null 2>&1; then
    echo "FAIL: lint_release_notes must BLOCK (non-zero) on exit-3 path-unresolved"; failures=$((failures+1))
  fi
  [[ "$(get_phase lint_release_notes | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: lint_release_notes exit-3 must mark FAIL (fail-loud, not vacuous pass)"; failures=$((failures+1)); }

  # (e) missing lint tooling → FAIL (never a silent skip)
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  /bin/rm -f "$_ln_stub"
  if phase_lint_release_notes >/dev/null 2>&1; then
    echo "FAIL: lint_release_notes must FAIL when the lint tooling is missing"; failures=$((failures+1))
  fi

  /bin/rm -rf "$_ln_tmp" 2>/dev/null || true
  REPO_ROOT="$_ln_saved_root"; VERSION="$_ln_saved_version"
  PHASE_NAMES=("${_ln_saved_names[@]:-}"); PHASE_RESULTS=("${_ln_saved_results[@]:-}"); PHASE_DETAILS=("${_ln_saved_details[@]:-}")

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
  if ! /usr/bin/sed -n '2,83p' "${BASH_SOURCE[0]}" | /usr/bin/grep -q "Usage:"; then
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

  # Test 10: corpus append-ledger merge-immunity (#3108, AC1). Two release
  # branches each PREPEND a distinct row into the same top-of-ledger region — the
  # concurrent Stage-13 append shape. Under a `merge=union` driver the second-to-
  # merge reconcile auto-resolves with ZERO conflict markers and keeps BOTH rows
  # (the #117 version-slot-loss blocker removed); the SAME merge WITHOUT the driver
  # CONFLICTS, proving the driver is load-bearing (not a vacuous green). A third
  # control merges a state-bearing status column under union and asserts it
  # CORRUPTS (the transitioned row is duplicated) — locking in WHY RELEASE_LOG and
  # RELEASE_REVERSIONS are EXCLUDED from the union set (Stage-5 empirical Test B).
  # Hermetic: scratch git repos under mktemp; seeds its OWN .gitattributes, so it
  # exercises the driver behavior independent of the repo's root file; no network.
  if [[ -x "$GIT" ]]; then
    local _ua_tmp; _ua_tmp="$(/usr/bin/mktemp -d -t union-attr-selftest.XXXXXX)"
    local _ua_attr _ua_dir

    # (a)+(b) additive ledger: build once with the driver, once without.
    for _ua_attr in union none; do
      _ua_dir="$_ua_tmp/$_ua_attr"; /bin/mkdir -p "$_ua_dir"
      # `) || true` neutralizes the intentional non-zero exit of the non-union
      # merge (it conflicts by design) under the script's `set -e` — same guard
      # the #1680/#1682 scratch-git subshells above use.
      ( cd "$_ua_dir"
        $GIT init -q -b main . >/dev/null 2>&1 || { $GIT init -q . >/dev/null 2>&1; $GIT checkout -q -b main >/dev/null 2>&1; }
        /usr/bin/printf '%s\n' '| Version | Milestone | Date |' '|---|---|---|' '| v9.79 | prior | 2026-01-01 |' > ledger.md
        if [[ "$_ua_attr" == union ]]; then /usr/bin/printf 'ledger.md merge=union\n' > .gitattributes; fi
        $GIT -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
        $GIT -c user.email=t@t -c user.name=t commit -qm seed >/dev/null 2>&1
        $GIT checkout -q -b relA >/dev/null 2>&1
        /usr/bin/printf '%s\n' '| Version | Milestone | Date |' '|---|---|---|' '| v9.80 | branchA | 2026-02-01 |' '| v9.79 | prior | 2026-01-01 |' > ledger.md
        $GIT -c user.email=t@t -c user.name=t commit -qam A >/dev/null 2>&1
        $GIT checkout -q main >/dev/null 2>&1; $GIT checkout -q -b relB >/dev/null 2>&1
        /usr/bin/printf '%s\n' '| Version | Milestone | Date |' '|---|---|---|' '| v9.81 | branchB | 2026-03-01 |' '| v9.79 | prior | 2026-01-01 |' > ledger.md
        $GIT -c user.email=t@t -c user.name=t commit -qam B >/dev/null 2>&1
        $GIT checkout -q relA >/dev/null 2>&1
        $GIT -c user.email=t@t -c user.name=t merge -q --no-edit relB >/dev/null 2>&1
      ) || true
    done

    # (a) union → CLEAN auto-merge: no conflict markers, BOTH rows kept exactly once
    if /usr/bin/grep -qE '^(<<<<<<<|=======|>>>>>>>)' "$_ua_tmp/union/ledger.md" 2>/dev/null; then
      echo "FAIL: #3108 union driver must auto-resolve a two-branch additive append with NO conflict markers"; failures=$((failures+1))
    fi
    if [[ "$(/usr/bin/grep -c 'v9.80' "$_ua_tmp/union/ledger.md" 2>/dev/null)" != "1" \
       || "$(/usr/bin/grep -c 'v9.81' "$_ua_tmp/union/ledger.md" 2>/dev/null)" != "1" ]]; then
      echo "FAIL: #3108 union merge must keep BOTH concurrent rows exactly once (take-both, never drop a release's row)"; failures=$((failures+1))
    fi

    # (b) CONTROL — same merge WITHOUT the driver MUST conflict (driver is load-bearing)
    if ! /usr/bin/grep -qE '^(<<<<<<<|=======|>>>>>>>)' "$_ua_tmp/none/ledger.md" 2>/dev/null; then
      echo "FAIL: #3108 control — a default (non-union) merge of the same concurrent append MUST conflict; a green here means the test proves nothing"; failures=$((failures+1))
    fi

    # (c) EXCLUSION control — a state-bearing status column under union CORRUPTS:
    #     each branch transitions a DIFFERENT row DEPLOYED->VERIFIED; union takes
    #     both sides -> the rows duplicate with contradictory status. This is why
    #     RELEASE_LOG / RELEASE_REVERSIONS are EXCLUDED. If this stops corrupting,
    #     the exclusion premise changed and must be re-evaluated.
    local _ua_log="$_ua_tmp/logexcl"; /bin/mkdir -p "$_ua_log"
    ( cd "$_ua_log"
      $GIT init -q -b main . >/dev/null 2>&1 || { $GIT init -q . >/dev/null 2>&1; $GIT checkout -q -b main >/dev/null 2>&1; }
      /usr/bin/printf '%s\n' '| Version | State |' '|---|---|' '| v9.79 | DEPLOYED |' '| v9.78 | DEPLOYED |' > LOG.md
      /usr/bin/printf 'LOG.md merge=union\n' > .gitattributes
      $GIT -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
      $GIT -c user.email=t@t -c user.name=t commit -qm seed >/dev/null 2>&1
      $GIT checkout -q -b relA >/dev/null 2>&1
      /usr/bin/printf '%s\n' '| Version | State |' '|---|---|' '| v9.79 | VERIFIED |' '| v9.78 | DEPLOYED |' > LOG.md
      $GIT -c user.email=t@t -c user.name=t commit -qam A >/dev/null 2>&1
      $GIT checkout -q main >/dev/null 2>&1; $GIT checkout -q -b relB >/dev/null 2>&1
      /usr/bin/printf '%s\n' '| Version | State |' '|---|---|' '| v9.79 | DEPLOYED |' '| v9.78 | VERIFIED |' > LOG.md
      $GIT -c user.email=t@t -c user.name=t commit -qam B >/dev/null 2>&1
      $GIT checkout -q relA >/dev/null 2>&1
      $GIT -c user.email=t@t -c user.name=t merge -q --no-edit relB >/dev/null 2>&1
    ) || true
    if [[ "$(/usr/bin/grep -c 'v9.79' "$_ua_log/LOG.md" 2>/dev/null)" -lt 2 ]]; then
      echo "FAIL: #3108 exclusion control — union on a state-bearing status column MUST duplicate the transitioned row (Test B corruption); if it no longer does, re-evaluate the RELEASE_LOG/RELEASE_REVERSIONS exclusion"; failures=$((failures+1))
    fi

    /bin/rm -rf "$_ua_tmp" 2>/dev/null || true
  else
    echo "  (skipped #3108 union-merge self-test — git not executable at $GIT)" >&2
  fi

  # Test 11: changed_skills_from_paths + files=() composition (#3322 — offline,
  # hermetic; catches the P1 staging omission in CI before any live close).
  local _csp_out
  # (a) direct source — a references/ path stales the whole skill (cp -R), and a
  #     non-skill path emits nothing.
  _csp_out="$(/usr/bin/printf '%s\n' 'core/skills/eval-writer/references/release-notes-eval-rubric.md' 'release/releases/RELEASE_LOG.md' | changed_skills_from_paths || true)"
  if ! /usr/bin/printf '%s\n' "$_csp_out" | /usr/bin/grep -qx 'eval-writer'; then
    echo "FAIL: changed_skills_from_paths must detect eval-writer from a core/skills/eval-writer/ path (rule a direct-source)"; failures=$((failures+1))
  fi
  if /usr/bin/printf '%s\n' "$_csp_out" | /usr/bin/grep -qx 'RELEASE_LOG.md'; then
    echo "FAIL: changed_skills_from_paths must NOT emit a non-skill path"; failures=$((failures+1))
  fi
  # (b) injected canonical — template-taxonomy.md maps to eval-writer per the
  #     deploy.sh TEMPLATE_SYNC_MAP (read at runtime); stales it with zero skills/ path.
  _csp_out="$(/usr/bin/printf '%s\n' 'core/standards/template-taxonomy.md' | changed_skills_from_paths || true)"
  if ! /usr/bin/printf '%s\n' "$_csp_out" | /usr/bin/grep -qx 'eval-writer'; then
    echo "FAIL: changed_skills_from_paths must detect eval-writer from core/standards/template-taxonomy.md (rule b reverse TEMPLATE_SYNC_MAP)"; failures=$((failures+1))
  fi
  # negative — a non-skill, non-canonical path set yields nothing.
  _csp_out="$(/usr/bin/printf '%s\n' 'CHANGELOG.md' 'core/disciplines/knowledge-architecture.md' | changed_skills_from_paths || true)"
  if [[ -n "$_csp_out" ]]; then
    echo "FAIL: changed_skills_from_paths must emit nothing for non-skill/non-canonical paths, got '$_csp_out'"; failures=$((failures+1))
  fi
  # files=() composition (P1 regression guard) — the commit phase MUST expand
  # "${REBUILT_PACKAGES[@]:-}" in its files=() array, else a rebuilt package is
  # silently dropped from the chore commit.
  if ! declare -f phase_commit_chore_pr | /usr/bin/grep -qF '"${REBUILT_PACKAGES[@]:-}"'; then
    echo "FAIL: phase_commit_chore_pr files=() must expand \"\${REBUILT_PACKAGES[@]:-}\" (P1 staging-omission guard)"; failures=$((failures+1))
  fi

  if [[ "$failures" -gt 0 ]]; then
    echo "self-test: FAIL ($failures failures)" >&2
    exit 1
  fi

  echo "self-test: PASS" >&2
  echo "  validate_version + extract_major validated" >&2
  echo "  phase_bump_version validated (#1643 — version-less SKIP / versioned apply / idempotency / dry-run)" >&2
  echo "  phase_append_reversions validated (#1679; SLIM #3109 — N/A common path / none-path SLIM gate → N/A no-row across round-trip + multi-abandoned fan-out + re-run + historical-none immutability / tag-orphaned positive → 1 row abandoned_tag_pushed=true / dry-run no-write + orphan-row idempotency); dry-run<=>apply parity validated on the GATED paths (F-01 — none-path preview 0 == apply 0; mixed orphan+none preview 1 == apply 1, orphan recorded, gated surfaced)" >&2
  echo "  phase_lint_release_notes validated (§3.2 close gate — clean PASS / this-version finding FAIL / other-version PASS / exit-3 fail-loud / missing-tool FAIL)" >&2
  echo "  extract_row_state + extract_milestone_slug validated (3 shapes: vX.Y- / NN- / pure-alpha incl. hyphen-less #2539 a4 branch; version-less end-anchor; #667 F2 bare theme-named slug → title)" >&2
  echo "  phase_append_release_digest + phase_append_release_index validated (#667 F3/F6 — DIGEST H3 under topmost H2 / INDEX 6-col single-row / idempotency; #2048 — version-less marker + _unversioned notes link + marker-aware idempotency + CHANGELOG SKIP)" >&2
  echo "  phase_inject_outcome_field validated (#37 — default-SUCCESS after Result / non-SUCCESS-no-rationale FAIL / non-SUCCESS+rationale both-lines / unknown-enum reject / idempotency / block-scoped)" >&2
  echo "  phase_detect_open_issues exclude filter validated (#38 — explicit --exclude-issue / Stage-13-subtask title-regex / AC-4 mixed fixture / decoy-not-over-excluded / per-issue --close-comment); ARMED-gate classified (#2539/A6.5 — correct slug counts real issues, mis-resolved Version reproduces historical false-0)" >&2
  echo "  phase_await_merge_chore_pr budget/escape validated (#1705 — zero-commit SKIP propagation / --no-merge SKIP / BLOCKED→CLEAN keep-poll merges / CONFLICTING HALT)" >&2
  echo "  --no-merge post-merge phase-gating validated (#2919 — post_close_milestone / manual_close_release_issues / publish_github_release / check_release_body_drift DEFER under --no-merge, even with open milestone/issues; NO_MERGE=0 negative)" >&2
  echo "  phase_transition_release_log VERIFIED re-derivation validated (#1681 — VERIFIED+merged-PR SKIP / VERIFIED+unmerged-PR FAIL false-VERIFIED / DEPLOYED normal transition); #2539 end-to-end validated (AC-2 pure-alpha resolve+flip / AC-3 dry-run<=>apply parity + no-match negative / D-3 true-count over-match fires)" >&2
  echo "  phase_ledger_guard + phase_reparse_ledgers validated (#1680 — clean-diff PASS / I1 foreign-row-removal FAIL / I2 VERIFIED→DEPLOYED FAIL / well-formed reparse PASS / duplicate-H3 reparse FAIL)" >&2
  echo "  changed_skills_from_paths + files=() composition validated (#3322 — rule a direct-source / rule b reverse-TEMPLATE_SYNC_MAP / non-skill negative / P1 staging-array guard)" >&2
  echo "  MERGE_SHA capture + tag↔SHA identity validated (#1682 — read-state captures release-PR merge SHA / tag==SHA publish PASS w/ --target / tag!=SHA publish FAIL)" >&2
  echo "  check_parser_clean validated (D9 — close-family + #N rejection; negated-form rejection; safe-phrasing acceptance)" >&2
  echo "  chore-PR body builder is parser-clean (D9 self-check)" >&2
  echo "  JSON report renders valid JSON" >&2
  echo "  usage block extractable" >&2
  echo "  corpus paths resolve (RELEASE_LOG/INDEX/DIGEST + notes dir)" >&2
  echo "  corpus append-ledger merge-immunity validated (#3108 AC1 — union two-branch append CLEAN + both rows kept / non-union control CONFLICTS / state-column union CORRUPTS → LOG+REVERSIONS exclusion)" >&2
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
    --reversion) REVERSION_SPEC="$2"; shift 2 ;;
    --outcome) OUTCOME="$2"; shift 2 ;;
    --outcome-rationale) OUTCOME_RATIONALE="$2"; shift 2 ;;
    --exclude-issue) EXCLUDE_ISSUES+=("$2"); shift 2 ;;
    --close-comment) CLOSE_COMMENTS+=("$2"); shift 2 ;;
    --merge-timeout) MERGE_TIMEOUT="$2"; shift 2 ;;
    --no-merge) NO_MERGE=1; shift ;;
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
validate_version "$VERSION" || die "Invalid version format: '$VERSION' (expected canonical vX.Y or vX.Y.Z per version-grammar.sh; suffix forms are not accepted)"

workspace_boundary_check
RUN_TS="$(ts_now)"

# Run phases sequentially; halt on FAIL from any phase
phase_preflight || { generate_report; exit 2; }
phase_read_state || { generate_report; exit 3; }
phase_detect_open_issues || { generate_report; exit 2; }
phase_create_chore_branch || { generate_report; exit 3; }
phase_transition_release_log || { generate_report; exit 3; }
phase_inject_outcome_field || { generate_report; exit 3; }            # Phase 6.5 — **Outcome:** field on the visible-H4 Deployment Log block (#37)
phase_append_release_index || { generate_report; exit 3; }
phase_append_release_digest || { generate_report; exit 3; }
phase_append_reversions || { generate_report; exit 3; }                # Phase 8.5 — re-version ledger (#1679; N/A on the common no-collision path)
phase_scaffold_release_notes || { generate_report; exit 3; }
phase_lint_release_notes || { generate_report; exit 3; }              # Phase 9.2 — §3.2 note-content close gate; a finding for THIS version BLOCKS close
phase_append_changelog || { generate_report; exit 3; }                # Phase 9.5 — Layer-1 dual-write Surface 2
phase_assert_derived_surfaces || { generate_report; exit 3; }         # Phase 9.55 — AC1 anchor A3: version-scoped scaffold-residue assert on CHANGELOG + DIGEST
phase_bump_version || { generate_report; exit 3; }                    # Phase 9.6 — stamp .version (versioned releases; SKIP version-less)
phase_ledger_guard || { generate_report; exit 3; }                    # Phase 9.9 — pre-commit §220 I1/I2 read-modify-write guard (#1680)
phase_rebuild_skill_packages || { generate_report; exit 3; }          # Phase 9.95 — .skill package rebuild into the chore commit (#3322; content-sidecar-gated)
phase_commit_chore_pr || { generate_report; exit 3; }
phase_create_chore_pr || { generate_report; exit 3; }
phase_await_merge_chore_pr || { generate_report; exit 3; }
phase_reparse_ledgers || { generate_report; exit 3; }                 # Phase 12.5 — post-merge structural re-parse (#1680; detective-only)
phase_post_close_milestone || { generate_report; exit 3; }
phase_manual_close_release_issues || { generate_report; exit 3; }
phase_run_verification || { generate_report; exit 3; }
phase_publish_github_release || { generate_report; exit 3; }          # Phase 15.5 — Layer-1 dual-write Surface 1
phase_check_release_body_drift || { generate_report; exit 3; }        # Phase 15.6 — post-emit §5.1 drift assert (genuine drift inside the cutoff scope BLOCKS; capability-absent / artifact-missing stay non-blocking)
phase_invoke_orphan_cleanup || { generate_report; exit 3; }
phase_pattern_scan || { generate_report; exit 3; }

generate_report
exit 0
