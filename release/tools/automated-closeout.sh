#!/usr/bin/env bash
# selftest-runner: macos
#   Read by release/tools/check-selftest-coverage.py. This script hard-exits at LOAD
#   time (before argument parsing) unless `gh` resolves at /opt/homebrew/bin/gh or
#   /usr/local/bin/gh — the macOS Homebrew locations — so `--self-test` is unreachable
#   on a runner that installs gh anywhere else. The requirement is a property of THIS
#   TOOL, so it is declared here rather than as a workflow exclusion: an exclusion
#   would let a runner constraint masquerade as a coverage decision, and a workflow
#   entry would re-create the hardcoded roster this gate exists to retire.
# automated-closeout.sh — Automated Stage 13 close-out
#
# Wraps the Stage 13 chore-PR pattern per pipeline/stage-13-close.md § Phase B
# commit mechanism + hub-spoke-bridge.md Procedure 7. Per the
# Stage 5 spec (relayed; canonical content).
#
# Phases (sequenced; each idempotent — re-running is safe):
#   1  parse_args         CLI validation
#   2  preflight          gh auth, clean tree, worktree cwd, DEPLOYED row + unique slug match, tag RECORDED (not gated), no scaffold residue in the note, Phase-A7 learnings-triple captured
#   3  read_state         RELEASE_LOG row + visible-H4 Deployment Log + Milestone state + release-PR MERGE_SHA (#1682)
#   4  detect_open_issues auto-close anomaly enumeration (#38: --exclude-issue + Stage-13-subtask sub-task-label+title-regex auto-exclude, #3665)
#   5  create_chore_branch chore/v<X.Y>-stage-13-corpus-update
#   6  transition_release_log  DEPLOYED → VERIFIED
#   6.5 inject_outcome_field  **Outcome:** field on the visible-H4 Deployment Log block (#37; default SUCCESS, --outcome overrides; key resolved through the shared field-key grammar — a non-conformant key FAILs loudly rather than injecting past, #4222)
#   6.6 inject_velocity_field **Velocity:** field after **Cycle-Time:** in that block (stage-13-close.md Phase B-velocity; surface-resolved)
#   6.7 append_release_learnings  sibling H4 `#### Release Learnings v<X.Y>` after the Deployment Log block (stage-13-close.md Phase A7; hot ledger only)
#   6.8 inject_close_class_telemetry_field  **Close-Class-Telemetry:** field after **Outcome rationale:**/**Outcome:** in that block (close-class-telemetry.md § 3.2; surface-resolved; anchor STRING resolved through the same shared field-key grammar as 6.5, #4222)
#   7  append_release_index    new row in RELEASE_INDEX.md
#   8  append_release_digest   new entry under v<MAJOR>.* H2 in RELEASE_DIGEST.md
#   8.5 append_reversions   append re-version row(s) to RELEASE_REVERSIONS.md (#1679; N/A on the common no-collision path)
#   9  scaffold_release_notes  frontmatter + section H2 placeholders (SCAFFOLD-ONLY)
#   9.2 lint_release_notes  §3.2 note-content close gate — a finding for THIS version BLOCKS close
#   9.3 lint_plan_identity  ADR-092 plan-file identity/placement close gate — a finding for THIS version BLOCKS close (SKIP version-less)
#   9.5 append_changelog   prepend ## [vX.Y] section to CHANGELOG.md (Layer-1 dual-write Surface 2)
#   9.55 assert_derived_surfaces  version-scoped scaffold-residue assert on the CHANGELOG + DIGEST entries for THIS version (read-only)
#   9.56 assert_output_set  pre-commit completeness assert over the Step-4 output-set manifest — every `required` (and armed `required-if`) member must be PRESENT in the tree about to be committed, so the DEPLOYED→VERIFIED stamp cannot reach main ahead of its own outputs (read-only; #5288)
#   9.6 bump_version       write .version=$VERSION (versioned releases; SKIP version-less)
#   9.9 ledger_guard       pre-commit §220 I1/I2 read-modify-write guard on the 4 append-only ledgers (#1680)
#   9.95 rebuild_skill_packages  rebuild changed skills' .skill packages into the chore commit (content-sidecar-gated; N/A when no skill source changed)
#   10 commit_chore_pr     git add + git commit (parser-clean message)
#   11 create_chore_pr     gh pr create with safe-phrasing body throughout
#   12 await_merge_chore_pr poll mergeStateStatus (#1705: CI-realistic budget, default 300s; --no-merge skips; BLOCKED/UNSTABLE keep-polling)
#   12.2 sync_primary_checkout  fast-forward the primary checkout to origin/main (git -C only; ff-only; non-fatal)
#   12.5 reparse_ledgers   post-merge structural re-parse of the ledgers (#1680; detective-only)
#   12.9 action_item_gate  Procedure 7a HARD GATE (#4439) — 3-valued AI-NNN ledger verdict, evaluated
#                          BEFORE the milestone close. UNRESOLVED BLOCKS at --apply; NOT-RECORDED /
#                          EMPTY-LEDGER SURFACE and require --attest-action-items to pass; RESOLVED is
#                          the only silent pass
#   13 post_close_milestone gh api -X PATCH state=closed (#2919: DEFERS under --no-merge)
#   14 manual_close_release_issues operator-authorized D-1 with structured comment (#2919: DEFERS under --no-merge)
#   15 run_verification + post_gate_passage_proof per the gate-passage-proof template
#   15.5 publish_github_release gh release create | edit (Layer-1 dual-write Surface 1; #2919: DEFERS under --no-merge, as does 15.6 check_release_body_drift)
#   15.55 assert_anchor_hygiene  SET-based annotated-tag <-> published-Release parity + tagger identity (dated exemption sets)
#   15.6 check_release_body_drift  post-emit §5.1 published-body drift assert (gated genuine drift BLOCKS; #2919: DEFERS under --no-merge)
#   16 invoke_orphan_cleanup cleanup-orphan-state.sh --release-close <slug> --dry-run
#   16.5 pattern_scan      synthesize-release-learnings.sh --mode pattern-detect (ON by default;
#                          --no-pattern-scan suppresses). Report body is surfaced in the close-out
#                          report, incl. the near-threshold band (sub-threshold disposition). Signal-only.
#   16.7 audit_epic_rollup audit-epic-rollup-close.sh --dry-run (ON by default; --no-epic-audit
#                          suppresses). Surfaces open type:epic issues whose children all reached a
#                          COMPLETED terminal state, for operator disposition. Signal-only — gates nothing.
#   17 generate_report     structured markdown or JSON close-out report
#
# ─── MODE-BRANCH PLACEMENT — the class rule every phase_* above obeys ────────
#
# ASSERT AT --apply, PREDICT AT --dry-run. Ratified by #4765 at phase 9.55,
# applied by #5142 at 15.5, swept to 9.5 and 15.55 by #5268. Recorded HERE, once,
# because it had lived only as three comments buried in three separate phase
# bodies — which is why three instances of ONE defect were found one at a time, by
# three different stages, across three releases. See
# release/ADRs/ADR-146-dry-run-predicts-apply-asserts-mode-branch-placement.md.
#
# WHY IT BITES. Every phase is dispatched as `phase_x || { generate_report; exit 3; }`,
# so ONE non-zero phase kills the run and no later phase enumerates. A phase that
# resolves an input ABOVE its mode test, where that input is written by an earlier
# phase which no-ops under --dry-run, therefore aborts the whole dry-run on this
# script's own no-op — invisibly, until the first dry-run over a release that has
# not already closed.
#
# THE RULE. The `MODE == dry-run` test is placed
#   - BELOW every guard whose inputs are mode-INVARIANT and whose --apply behaviour
#     is something other than performing the phase's write (a SKIP, a deferral, a
#     malformed-input FAIL). Predicting "would do X" below such a guard would be a
#     FALSE prediction, and surfacing a genuinely bad input at --dry-run is what
#     --dry-run is for; and
#   - ABOVE every statement whose input is written by a phase that no-ops under
#     --dry-run.
# It is NOT "put the mode test first": a phase whose --apply path SKIPs must not
# predict that it will write.
#
# TWO CONSTRAINTS THAT MAKE IT SAFE.
#   1. The prediction is STATIC. It states what --apply will do; it does not
#      pre-evaluate any of it. A dry-run limb that stats a file, reaches a remote,
#      or reads a projector exit code is the same defect in a new shape.
#   2. The DRY-RUN detail is a two-valued vocabulary. It carries no '|' (the record
#      is `RESULT|detail` and --markdown renders it as a table row), and it carries
#      the literal `would FAIL` if and ONLY if --apply would fail —
#      _output_set_dryrun_class reads that token to classify a producer.
#
# WHERE A PHASE HAS NO SINGLE BRANCH POINT — because some limbs are mode-invariant
# and must keep running — scope the ONE mode-dependent limb instead of relocating
# the whole phase (phase_preflight, phase_assert_output_set,
# phase_assert_anchor_hygiene). Scope it as a CONJUNCTION bounded to the exact state
# the no-op produces, never as a mode-wide suppression. A whole-phase relocation
# there is the mode-blindness defect inverted.
#
# EVERY FIX UNDER THIS RULE SHIPS A PAIRED ARM. The dry arm must reach the limb and
# record literally DRY-RUN; the apply arm, on the IDENTICAL fixture, must still
# abort with its message preserved. A presence check ("does a MODE test exist in
# this function?") PASSES ON THE DEFECTIVE CODE — the branch was always there, just
# stranded below the abort.
#
# Usage:
#   ./automated-closeout.sh --pr <N> --version v<X.Y> --milestone <N> [--dry-run|--apply] [--markdown|--json] [--no-pattern-scan]
#   ./automated-closeout.sh --self-test
#   ./automated-closeout.sh --check-paths
#   ./automated-closeout.sh --help
#
# Flags:
#   REQUIRED:
#     --pr <N>                 Release PR number
#     --version v<X.Y>         Version key matching RELEASE_LOG row. Canonical
#                              vX.Y[.Z] ONLY — a version-less release is rejected
#                              here, before any phase runs, and closes via the
#                              Phase-B chore-PR mechanism per
#                              release/references/pipeline/stage-13-close.md
#                              Phase A8. That is the expected path for the
#                              version-less identity mode, not a deviation.
#     --milestone <N>          Milestone number
#   MODE (one of, default --dry-run):
#     --dry-run                Enumerate + preview; no state mutation (default)
#     --apply                  Execute state mutations after enumeration (opt-in)
#   OUTPUT (one of, default --markdown):
#     --markdown               Human-readable close-out report (default)
#     --json                   Machine-readable
#   OPTIONAL:
#     --no-pattern-scan        Suppress the post-close synthesize-release-learnings.sh
#                              --mode pattern-detect scan (it runs by default)
#     --with-pattern-scan      Accepted, no-op — the scan is now the default
#     --no-epic-audit          Suppress the post-close audit-epic-rollup-close.sh epic
#                              rollup-close audit (it runs by default, report-only)
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
#     --attest-action-items <c> Operator attestation clearing a Procedure 7a SURFACE
#                              state (#4439). Closed enum: no-commitments (this
#                              release genuinely recorded no action items) or
#                              emit-skipped (the Procedure 4a emit step was missed).
#                              REQUIRED at --apply when the gate resolves
#                              NOT-RECORDED or EMPTY-LEDGER — those states pass on
#                              attestation, never silently. The attestation is
#                              itself emitted as a `decision` /
#                              `empirical-verification-finding` row, actor
#                              `operator`. It does NOT clear an UNRESOLVED verdict:
#                              an open row is dispositioned, not attested away.
#   ENV:
#     HUB_STATE_PATH           Override the hub-state root the Procedure 7a gate
#                              reads. Composite precedence, highest first:
#                                1. $HUB_STATE_PATH  (this variable)
#                                2. operator.toml    operator_instance_hub_state_path
#                                3. $PMO_INSTANCE_PATH — inherited, because the
#                                   default is now resolved through
#                                   core/deploy/lib-instance-path.sh's
#                                   pmo_instance_path_for() rather than spelled
#                                   inline, and that accessor honors it
#                                4. the ${WORKSPACE_ROOT}-rooted canonical default
#                                   (that same accessor's fallback), with a
#                                   `hub-state` leaf appended
#                              Rung 3 sits BELOW rung 2 deliberately, and that is
#                              worth stating because it INVERTS the resolver's own
#                              PMO_INSTANCE_PATH-is-highest convention for this one
#                              surface: a config key naming THIS directory
#                              specifically beats a coarse whole-instance
#                              relocation. Rung 3 is new as of the resolver
#                              convergence; before it, a PMO_INSTANCE_PATH-relocated
#                              instance left hub-state behind at the old root.
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
    # SIGPIPE-REWRITE + `|| true`, identical in form AND in reason to the
    # HUB_STATE_PATH read further down — see that block for the full rationale,
    # which was PROVEN by breaking this script and is not restated here.
    #
    # Both halves are load-bearing, and this site had neither. `claude_workspace_root`
    # is OPTIONAL: an operator.toml that exists but omits it makes this grep exit 1,
    # `pipefail` propagates that through the pipeline, and `set -e` aborts at LOAD
    # time — before argument parsing, on EVERY invocation including --self-test and
    # --check-paths — with exit 1 and no output at all. That is a silent total
    # failure of the close-out tool caused by the ABSENCE of an optional config key.
    # The `| head -1` folds into `grep -m1` for the same SIGPIPE reason: grep reads
    # the FILE directly, so it is the leftmost producer and there is no upstream
    # writer left for an early-closing reader to signal.
    _wr=$(/usr/bin/grep -m1 -E '^claude_workspace_root' "$_operator_toml" 2>/dev/null | /usr/bin/awk -F= '{gsub(/[" ]/,"",$2); print $2}' || true)
    [[ -n "$_wr" ]] && WORKSPACE_ROOT="$_wr"
  fi
fi
WORKSPACE_ROOT="${WORKSPACE_ROOT:-${HOME}/Claude}"

# ─── Instance-path resolver (sourced fail-closed) ────────────────────────────
#
# The single resolution site for operator-instance paths (ADR-017 § operator-
# instance surface convergence; ADR-032 § "invent no new variable"). Sourced here
# so the two instance-root call sites below — CORPUS_INSTANCE_ROOT and the
# HUB_STATE_PATH default — resolve THROUGH it instead of spelling the leaf
# themselves. A relocation of the operator-instance home then re-points ONE
# function and this tool follows automatically, rather than needing a coordinated
# edit here.
#
# Sourced AFTER WORKSPACE_ROOT is fully resolved, because both call sites pass it
# to pmo_instance_path_for() and that accessor keeps the base its caller hands it.
#
# The EMPTY POSITIONAL is deliberate, and is copied from
# release/tools/produce-learnings-register.sh along with its reason: a sourced file
# inherits the CALLER's positionals when `source` passes none, and this source runs
# BEFORE argument parsing, so $1 is still --check-paths or --self-test at this
# point. lib-instance-path.sh carries no direct-run guard today; passing "" is
# defence-in-depth so a future one cannot break this caller.
#
# FAIL-CLOSED, NOT FAIL-OPEN — and the alternative was considered rather than
# skipped. A `[[ -r ]] && source || <inline expansion>` degrade (the shape the
# version-grammar source further down uses) would leave this tool resolving the
# instance root two different ways: through the resolver on a real checkout, and
# through a stale inline copy anywhere the library is missing. Today those two
# expressions are identical, so the degrade would look free; after the relocation
# they resolve to DIFFERENT directories, and no gate anywhere would see it. A
# path degrade is not the same class as the version-grammar degrade, which is
# behavioural and documented as such.
#
# Fail-closed has a cost and it is paid explicitly: every tree that runs this
# script must carry the resolver beside it. Three do, and each is treated —
# the tolerance suite's fixtures copy it in build_repo(), the CI precision probe
# copies it into its temp tree, and the version-stamping harness pins this
# variable to the real library in its sed neutralization pipeline. The CI probe
# is the one that MUST be treated: its rule reads any non-zero exit as a
# successful detection, so an untreated load-time abort there would turn the
# probe green while it measured nothing.
#
# die() is not defined until much later in this file, so the guard uses the
# pre-die error idiom already used at the gh-resolution block above. Exit 2 is
# this file's documented preflight-failure code.
INSTANCE_LIB="$REPO_ROOT/core/deploy/lib-instance-path.sh"
if [[ ! -r "$INSTANCE_LIB" ]]; then
  echo "ERROR: instance-path resolver missing at $INSTANCE_LIB" >&2
  exit 2
fi
# shellcheck source=/dev/null
source "$INSTANCE_LIB" ""

# Repo slug resolution (env-override → operator.toml → default). Empty operator
# config → bare "pmo-platform"; gh calls below tolerate a non-resolving slug.
#
# THAT TOLERANCE IS FALSE OF ONE CONSUMER. phase_append_changelog persists this
# value into a durable CHANGELOG.md Release URL rather than passing it to a
# tolerant API, so a non-resolving slug there is not a soft failure — it is a
# permanently broken link in a shipped artifact, and the bare fallback below is
# not owner/repo-shaped. That phase therefore gates on WELL-FORMEDNESS before it
# writes, and fails loudly rather than emitting a plausible-looking wrong row —
# the same posture the frontmatter `date:` accessor in that phase already takes.
REPO_SLUG="${REPO_SLUG:-}"
if [[ -z "$REPO_SLUG" ]] && [[ -r "${HOME}/.config/pmo-platform/operator.toml" ]]; then
  _gh=$(/usr/bin/grep -E '^operator_github' "${HOME}/.config/pmo-platform/operator.toml" 2>/dev/null | /usr/bin/head -1 | /usr/bin/awk -F= '{gsub(/[" ]/,"",$2); print $2}')
  _repo=$(/usr/bin/grep -E '^pmo_platform_repo_name' "${HOME}/.config/pmo-platform/operator.toml" 2>/dev/null | /usr/bin/head -1 | /usr/bin/awk -F= '{gsub(/[" ]/,"",$2); print $2}')
  [[ -z "$_repo" ]] && _repo="pmo-platform"
  [[ -n "$_gh" ]] && REPO_SLUG="${_gh}/${_repo}"
fi
[[ -z "$REPO_SLUG" ]] && REPO_SLUG="pmo-platform"
# ─── Corpus home resolution — the corpus-home adapter seam ───────────────────
#
# Implements CH-1..CH-4 of
# release/references/standards/corpus-home-adapter-constraints.md, which
# release/tools/tests/test_corpus_home_tolerance.sh asserts executably.
#
# Three states, resolved in this precedence order:
#
#   1. IN-TREE corpus PRESENT  -> repo-homed. Byte-identical to the pre-adapter
#      behaviour, so every ordinary checkout and every CI runner is unaffected
#      by this seam. This tier is deliberately FIRST: the adapter exists for the
#      post-split world in which the corpus has been REMOVED from the tree
#      (ADR-032), not to re-home a corpus that is sitting right here. Putting
#      the instance tier first would change the resolved path on machines that
#      happen to carry an instance corpus, for no constraint's benefit.
#   2. in-tree ABSENT, instance corpus PRESENT -> instance-homed (CH-2). A
#      present instance corpus MUST resolve THROUGH the active corpus home; a
#      resolver that tolerates absence without resolving presence is the
#      degenerate answer CH-2 exists to forbid. Both published layouts are
#      probed because both are in use.
#   3. NEITHER present -> no corpus home resolves (CH-1). check_paths() records
#      a per-path N/A and exits 0. Absence is TOLERATED, never hard-failed, and
#      never silently downgraded to OK (CH-4).
#
# An EMPTY $CORPUS_HOME is the one and only signal check_paths() reads for the
# tolerance branch, so the three states cannot drift apart into two encodings.
#
# The instance root is RESOLVED, not spelled. pmo_instance_path_for() honors
# PMO_INSTANCE_PATH and otherwise appends the canonical instance leaf to the
# workspace root it is handed — which is why the arg-taking accessor is the
# correct one here and the no-arg pmo_instance_path() is not: the no-arg form
# rebuilds its own two-step base and would DISCARD the $WORKSPACE_ROOT env
# override and the operator.toml claude_workspace_root key that the cascade above
# resolves. Measured across nine configurations before this converged: the
# arg-taking accessor agrees with the previous inline expression in 9 of 9; the
# no-arg accessor diverges in 5 of 9, in every case by silently dropping one of
# those two documented overrides.
#
# HISTORY — this block used to carry the leaf inline, and stated that the library
# was deliberately NOT sourced because the tolerance suite's fixtures copy only
# this script into their fixture repos. That reason was TRUE and it was
# REPAIRABLE: the fixtures now copy the resolver alongside the script, as does the
# CI precision probe, and the version-stamping harness pins it. Two of those three
# consumers were not named by the original rationale, and one of them would have
# gone silently green rather than red. See the fail-closed source block above.
CORPUS_INSTANCE_ROOT="$(pmo_instance_path_for "$WORKSPACE_ROOT")"
CORPUS_HOME=""
CORPUS_HOME_KIND="none"
if [[ -d "$REPO_ROOT/release/releases" ]]; then
  CORPUS_HOME="$REPO_ROOT/release/releases"
  CORPUS_HOME_KIND="repo"
else
  for _corpus_cand in "$CORPUS_INSTANCE_ROOT/release/releases" "$CORPUS_INSTANCE_ROOT/releases"; do
    [[ -d "$_corpus_cand" ]] || continue
    CORPUS_HOME="$_corpus_cand"
    CORPUS_HOME_KIND="instance"
    break
  done
fi
# Where the corpus WOULD live when nothing resolved. The CH-4 N/A records name
# this rather than a bare leaf, so a tolerated absence still says which location
# was consulted instead of emitting a rootless path.
CORPUS_HOME_EFFECTIVE="${CORPUS_HOME:-$CORPUS_INSTANCE_ROOT/release/releases}"

RELEASE_LOG="$CORPUS_HOME_EFFECTIVE/RELEASE_LOG.md"
RELEASE_INDEX="$CORPUS_HOME_EFFECTIVE/RELEASE_INDEX.md"
RELEASE_DIGEST="$CORPUS_HOME_EFFECTIVE/RELEASE_DIGEST.md"
RELEASE_REVERSIONS="$CORPUS_HOME_EFFECTIVE/RELEASE_REVERSIONS.md"
RELEASE_NOTES_DIR="$CORPUS_HOME_EFFECTIVE/notes"
RELEASE_PLANS_DIR="$CORPUS_HOME_EFFECTIVE/plans"
CLEANUP_TOOL="$SCRIPT_DIR/cleanup-orphan-state.sh"
COMPUTE_CYCLE_TIME="$SCRIPT_DIR/compute-cycle-time.sh"
SYNTHESIZE_LEARNINGS="$SCRIPT_DIR/synthesize-release-learnings.sh"
AUDIT_EPIC_ROLLUP="$SCRIPT_DIR/audit-epic-rollup-close.sh"
# Velocity producer for the Phase 6.6 `**Velocity:**` field. Sibling of
# COMPUTE_CYCLE_TIME above, same form factor and same exit-code contract.
# Deliberately NOT registered in check_paths(): that probe enumerates the four
# CORPUS paths, and a TOOL dependency is guarded inline by its consuming phase —
# the precedent PROJECTOR below already sets (an `[[ ! -f ]]` guard inside
# emit_derived_entry rather than a fifth check_paths row).
COMPUTE_VELOCITY="$SCRIPT_DIR/compute-release-velocity.sh"
# Pipeline-event writer. Used by ONE caller: phase_action_item_gate, to emit the
# Procedure 7a operator attestation (`decision` / `empirical-verification-finding`)
# the gate's own decision table requires. Guarded inline by its consuming phase
# (the COMPUTE_VELOCITY precedent above), deliberately NOT a fifth check_paths row.
AI_EVENT_WRITER="$SCRIPT_DIR/append-pipeline-event.sh"

# Hub-state root holding this release's AI-NNN action-item ledger. OPERATOR-INSTANCE
# content (<OPERATOR_INSTANCE_HUB_STATE_PATH>), never in the repo tree. Resolution is
# the same env-override → operator.toml → canonical-default form WORKSPACE_ROOT and
# REPO_SLUG already use above, and the append-pipeline-event.sh sibling uses for its
# own operator-instance path. The env tier is load-bearing, not incidental: it is
# what lets the self-test point the resolver at a sandbox instead of the operator's
# live ledger.
#
# FOUR tiers now, not three, and the fourth is INHERITED rather than written here:
# the canonical default is resolved through pmo_instance_path_for(), which honors
# PMO_INSTANCE_PATH. So the composite precedence is
#   $HUB_STATE_PATH → operator.toml operator_instance_hub_state_path
#                   → $PMO_INSTANCE_PATH → the ${WORKSPACE_ROOT}-rooted default
# and PMO_INSTANCE_PATH sits BELOW the operator.toml key — the inverse of the
# resolver's own PMO_INSTANCE_PATH-is-highest convention, for this one surface.
# That relation is defensible (a key naming THIS directory beats a coarse
# whole-instance relocation) but it is new, so it is stated rather than inferred;
# the ENV banner at the top of this file states the same ladder.
#
# BEHAVIOUR DELTA, stated rather than smuggled: on an instance relocated by
# PMO_INSTANCE_PATH, hub-state now follows the instance root where before it
# stayed behind at the ${WORKSPACE_ROOT}-rooted location. Measured: 1 of 4
# configurations moves, and it moves toward canonical semantics — hub-state IS
# operator-instance content, and the omission was an omission (the tier list this
# very comment used to give did not mention PMO_INSTANCE_PATH at all), not a
# decision. The env tier still wins, and --self-test reassigns HUB_STATE_PATH at
# runtime, so no self-test or fixture verdict moves.
#
# THE `|| true` IS LOAD-BEARING AND WAS PROVEN SO BY BREAKING THIS SCRIPT. The key
# is optional — most operator.toml files do not carry it — and this file runs under
# `set -euo pipefail`. A no-match `grep` exits 1, `pipefail` propagates that through
# the pipeline, and `set -e` then aborts at LOAD time, before argument parsing:
# every invocation, including --self-test and --check-paths, exits 1 with no output
# at all. That is a silent total failure of the close-out tool caused by the ABSENCE
# of an optional config key — the same shape as the defect this phase exists to fix,
# so it is guarded here and the reason is written down. The sibling writer
# append-pipeline-event.sh carries the identical guard for the identical reason.
HUB_STATE_PATH="${HUB_STATE_PATH:-}"
if [[ -z "$HUB_STATE_PATH" ]] && [[ -r "${HOME}/.config/pmo-platform/operator.toml" ]]; then
  # SIGPIPE-REWRITE. Was: `grep -E … file | head -1 | awk …`. `grep` reads the file
  # directly, so it is the leftmost producer and the `| head -1` folds into `-m1`
  # with no upstream producer left to signal; the downstream `awk` reads to EOF and
  # short-circuits nothing. Same first-matching-line semantics, and the `|| true`
  # below still spans the whole substitution for the load-bearing reason above.
  _hs=$(/usr/bin/grep -m1 -E '^operator_instance_hub_state_path' "${HOME}/.config/pmo-platform/operator.toml" 2>/dev/null | /usr/bin/awk -F= '{gsub(/[" ]/,"",$2); print $2}' || true)
  [[ -n "$_hs" ]] && HUB_STATE_PATH="$_hs"
fi
HUB_STATE_PATH="${HUB_STATE_PATH:-$(pmo_instance_path_for "$WORKSPACE_ROOT")/hub-state}"
# Close-class telemetry producer for the Phase 6.8 `**Close-Class-Telemetry:**`
# field. Same form factor and same non-registration rationale as COMPUTE_VELOCITY
# above — a TOOL dependency guarded inline by its consuming phase, not a fifth
# check_paths() row (that probe enumerates the four CORPUS paths).
COMPUTE_CLOSE_CLASS_TELEMETRY="$SCRIPT_DIR/compute-close-class-telemetry.sh"
# Scaffold-residue token source (AC1 single-source seam). The token set has exactly
# ONE definition — SCAFFOLD_RESIDUE_TOKENS in lint_release_corpus.py — and the shell
# anchors read it from there via --print-scaffold-tokens. Retyping the literals in
# bash would open a cross-language drift seam: the scaffold heredoc could gain a
# placeholder the python anchor catches and the shell anchors silently miss.
# Captured HERE at load time from the script-derived $REPO_ROOT, so a self-test that
# sandboxes REPO_ROOT still reads the REAL token set — exercising the shipped tokens
# is the entire value of the round-trip test.
LINT_RELEASE_CORPUS="$REPO_ROOT/core/deploy/tools/lint_release_corpus.py"
# Release-corpus PROJECTOR — the single writer of the three DERIVED ledger
# surfaces (RELEASE_INDEX / RELEASE_DIGEST / CHANGELOG). Phases 7, 8 and 9.5 no
# longer synthesise their own entry content; each asks the projector for ONE
# entry and inserts it. Captured HERE at load time from the script-derived
# $REPO_ROOT for the same reason as the line above: a self-test that sandboxes
# REPO_ROOT must still invoke the REAL projector, against its sandbox corpus.
PROJECTOR="$REPO_ROOT/core/deploy/tools/generate_release_index.py"
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
# Pattern scan runs BY DEFAULT. It was previously opt-in behind --with-pattern-scan,
# and no executable caller anywhere ever passed that flag — so the phase always
# short-circuited to N/A and the sub-threshold disposition never reached the
# operator on the mandated close path. A disposition that depends on remembering a
# flag is not a disposition. --no-pattern-scan is the escape hatch; the old
# --with-pattern-scan is still accepted as a compatible no-op.
WITH_PATTERN_SCAN=1
PATTERN_SCAN_REPORT=""   # captured pattern-detect report body, surfaced in the close-out report

# Epic rollup-close audit (phase 16.7). ON by default for the same reason the
# pattern scan is: a detective capability nobody remembers to invoke is the exact
# failure mode the epic-rollup gap already demonstrates. --no-epic-audit is the
# escape hatch. Report-only — the phase records counts and surfaces the body, and
# gates nothing.
WITH_EPIC_AUDIT=1
EPIC_AUDIT_REPORT=""     # captured epic rollup-close report body, surfaced in the close-out report
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
VERIFY_RECHECK_DELAY=2   # check-5 post-close re-read replication-lag delay, in
                         # seconds (#3587 D-4). `gh issue close` writes via REST
                         # while `gh issue list` reads via GraphQL, so a
                         # milestone-filtered read is not guaranteed
                         # read-after-write. Not a CLI flag — internal; the
                         # self-test overrides it to 0 to stay hermetic.
ATTEST_ACTION_ITEMS=""   # --attest-action-items <cause> (Procedure 7a SURFACE
                         # clause). Closed 2-value enum: no-commitments |
                         # emit-skipped. The gate's SURFACE states resolve
                         # "requires explicit operator attestation to PASS"
                         # (hub-action-tracking.md § 4 routing point 5;
                         # hub-spoke-bridge.md § Procedure 7a decision table rows
                         # 1-2), and the attestation IS the discriminator — the
                         # operator states WHICH of the two causes holds. Empty at
                         # --apply on a SURFACE state therefore BLOCKS; it is not a
                         # silent pass. See phase_action_item_gate.

# State populated by phases (used by generate_report)
RUN_TS=""
STATE_LOG_ROW_PRESENT=0
STATE_LOG_ROW_STATE=""
STATE_MILESTONE_STATE=""
STATE_MILESTONE_SLUG=""
STATE_CYCLE_TIME=""
STATE_TAG_EXISTS=0
OPEN_ISSUE_LIST=""        # newline-separated list of issue numbers. PRE-CLOSE
                         # SNAPSHOT, taken once at Phase 4 (#3587): 6 of its 7
                         # consumers document the population as it stood BEFORE
                         # the D-1 manual close (chore-PR "Deferred items" body,
                         # the `closed N/M` denominator, the D-1 Manual-Close
                         # Candidates report section, the JSON payload). Only
                         # verification check 5 wants post-close truth, and it
                         # re-derives into LOCALS rather than refreshing these.
OPEN_ISSUE_COUNT=0        # pre-close snapshot — see OPEN_ISSUE_LIST above
COLLECTED_OPEN_ISSUES=""  # collect_open_release_issues output channel (#3587):
                         # newline-separated surviving issue numbers from the most
                         # recent call. Write-then-immediately-read; no phase holds
                         # it across a later call.
EXCLUDED_DETAIL=""        # collect_open_release_issues side channel (#3587): the
                         # "#N (<reason>) " fragments for the caller's mark_phase
                         # detail string. phase_detect_open_issues reads it;
                         # phase_run_verification ignores it.
CHORE_BRANCH=""
CHORE_PR_NUMBER=""
VERIFICATION_RESULTS=""
STATE_AI_GATE=""          # Procedure 7a verdict computed at Phase 12.9, BEFORE the
                          # milestone close. One of the gate's four states:
                          # NOT-RECORDED / EMPTY-LEDGER / RESOLVED / UNRESOLVED.
                          # phase_run_verification RENDERS this value in row 6 —
                          # it never recomputes, because a verdict re-derived after
                          # the close is not the verdict the close was gated on.
STATE_OUTPUT_SET_ROWS=""  # per-member output-set verdicts recorded at Phase 9.56,
                          # PRE-COMMIT. One "<id><TAB><verdict>" line per manifest
                          # member (#5288). phase_run_verification RENDERS these in
                          # rows 7-9 — it never recomputes, for the same reason row 6
                          # does not: 9.56 is the moment the close was actually gated
                          # on, and a value re-derived after the close is a different
                          # claim wearing the same cell.
STATE_AI_TOTAL=0          # whole AI-row population at Phase 12.9 (the denominator)
STATE_AI_UNRES=0          # status:open + status:in-flight subset (the numerator)
STATE_AI_DIR=""           # resolved hub-state dir for this release (diagnostic)
STATE_AI_EMIT="n/a"       # attestation-emission outcome: n/a | emitted | dry-run |
                          # failed:<reason>. The spec requires the attestation to be
                          # EMITTED, not merely accepted; when the emit cannot land
                          # this value says so rather than leaving the close looking
                          # attested-and-recorded when only half of that is true.
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

# Archive segments this run WROTE INTO (#4710): repo-relative
# "release/releases/RELEASE_LOG_ARCHIVE-<family>.md" paths, populated by
# _record_touched_archive_segment at the phase 6.5 / 6.6 write sites and
# consumed by phase_commit_chore_pr's files=() staging array. Empty on a release
# whose Deployment Log block is still in the hot ledger — i.e. every release
# until its block ages out of the archival sweep window.
TOUCHED_ARCHIVE_SEGMENTS=()

# The exact `**Not-produced:**` bytes composed by the most recent
# _write_not_produced_marker call (#5288). The writer still echoes the line on
# stdout — its documented contract, and what the self-test's direct callers
# redirect — but the PRODUCTION call sites read it from HERE instead, because
# capturing stdout requires a command substitution and a command substitution is
# a SUBSHELL: the writer's `_record_touched_archive_segment` append would die
# with it, and the marker it just wrote to an archive segment would be dropped at
# commit while the phase reported "Absence RECORDED". Assigned unconditionally at
# the single point the line is composed, so it can never go stale relative to
# stdout and a second call cannot read the first call's bytes.
NOT_PRODUCED_MARKER_LINE=""

# Phase outcomes (PASS / FAIL / SKIPPED / N/A / DRY-RUN / MANUAL)
# Bash 3.2 (macOS default) lacks associative arrays — use parallel indexed arrays
# keyed by phase name. Lookup is O(n) over a small, dispatch-bounded set (one
# entry per mark_phase call, so the bound is the dispatch block's length — no
# pinned count here, because a pinned count is false the next time a phase lands).
#
# This record is the ONLY in-file surface that observes EXECUTION rather than
# declaration, which is why generate_markdown_report and generate_json_report
# both DERIVE their phase set from it instead of carrying a parallel enumeration.
PHASE_NAMES=()
PHASE_RESULTS=()
PHASE_DETAILS=()

# ─── Helpers ─────────────────────────────────────────────────────────────────

usage() {
  # Self-terminating on the header block's real end (the first line after the
  # shebang that is not a comment) rather than a hardcoded line count. The old
  # fixed `sed -n '2,92p'` window truncated mid-sentence and silently dropped the
  # whole META section, so `--help` never mentioned --self-test — the flag the
  # version-less REACHABILITY note depends on. A fixed window re-breaks every
  # time the header grows; this one cannot.
  /usr/bin/awk 'NR==1 {next} /^#/ {sub(/^# ?/, ""); print; next} {exit}' "${BASH_SOURCE[0]}"
  exit 0
}

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

ts_now() { /bin/date -u +%Y-%m-%dT%H:%M:%SZ; }
date_today() { /bin/date -u +%Y-%m-%d; }

# Match-count that cannot fail open. THE ONLY sanctioned way to capture a
# `grep -c` result in this file.
#
# THE DEFECT THIS REPLACES (#3113 QA F-QA-3). A zero-match `grep -c` prints `0`
# AND exits 1. So the common substitution that appends a fallback
#   ... || echo 0
# emits a SECOND `0` and captures the two-line string `0\n0`. A subsequent
# `[[ "$x" -ne "$y" ]]` then raises "syntax error in expression" and — because a
# failed arithmetic test evaluates FALSE — takes the PASS branch. A *missing*
# ledger correctly FAILs (grep prints nothing, exit 2, the value is empty); a
# *present-but-empty* ledger, which is the worse case, passed clean. That guard
# mechanizes LEDGER-ROW-PARITY, this release's own CIAC-2 acceptance criterion.
#
# `|| true` keeps grep's own single `0` on a zero-match hit; `${n:-0}` covers the
# paths that emit NOTHING (missing/unreadable file, exit 2). The captured value is
# therefore always exactly one integer, and the missing-file FAIL is preserved.
#
# Callers pass ONE file (or read stdin); a multi-file count emits `file:count`
# lines and is not a supported call shape. Self-test Test 14 (g) asserts the
# single-integer contract, drives the shipped phase against a present-but-empty
# ledger, and blocks reintroduction of the fallback idiom structurally.
grep_count() {
  local n
  n="$(/usr/bin/grep -c "$@" 2>/dev/null || true)"
  /usr/bin/printf '%s' "${n:-0}"
}

# Run-scoped CLOSE-OUT anchor (#3718). Sampled ONCE at script load and reused by
# every close-out-anchored write: RELEASE_DIGEST, the release-note frontmatter
# `date:` (and thence CHANGELOG, which derives its date from that frontmatter),
# and RELEASE_REVERSIONS. Before this, each phase called date_today() freshly, so
# a close-out run spanning a UTC midnight could write TWO different dates into
# ONE atomic Stage-13 chore PR — the same "sampled more than once" defect the
# Stage-5 date variable exists to prevent, at a smaller unit of work. Per
# core/standards/date-variable-convention.md § Emission-Time Anchors
# (sample-once-per-unit-of-work; the unit here is one close-out run).
#
# NOT used for the RELEASE_INDEX Date cell — that column carries the MERGE
# anchor and is read from the RELEASE_LOG row. See phase_append_release_index.
CLOSEOUT_ANCHOR_UTC="$(date_today)"

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
#
# REACHABILITY — read this before deleting any is_version_less branch.
# These branches are NOT reachable through --apply or --dry-run. Main validates
# --version against the canonical grammar and dies before phase dispatch, so a
# version-less $VERSION exits 1 at the CLI boundary and no phase ever runs. They
# are live and maintained for three reasons:
#   1. --self-test dispatches BEFORE that gate and drives the branches directly.
#      The ordering is the whole reason they are reachable, so it is ASSERTED,
#      not merely documented: self-test arm VL-ORDER resolves both lines from
#      this file's own text and fails if the dispatch stops preceding the gate.
#      The VL-0..VL-7 arms are the branches' regression coverage, and CI runs
#      --self-test on this file (core/deploy/allowlists/selftest-coverage-manifest.txt).
#   2. They are the executable statement of the corpus convention that a
#      hand-assembled Phase-B chore-PR close must follow for a version-less
#      release — release/references/pipeline/stage-13-close.md, Phase A8, which
#      states that scope once for every version-less N/A and SKIP rule in the
#      stage. Shipped version-less releases in the RELEASE_LOG follow it.
#   3. version-less is a live Stage-3 release-identity mode (stage-03-bundle.md,
#      asserted at G3-19), so the convention cannot be retired from here.
# Do NOT delete these branches without first retiring the identity mode at
# Stage 3. Deleting them would leave the convention with no executable statement
# while releases are still closing under it.
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

# The SAME file as notes_rel_path(), as an ABSOLUTE path. Every phase that opens,
# writes or stats the release note resolves it HERE — producer and consumers alike.
#
# Why a second resolver rather than a second copy of the conditional: the version-less
# branch was previously retyped at each site, and the PRODUCER
# (phase_scaffold_release_notes) was the one site that never got it. It wrote a
# version-less note FLAT while preflight (f) read notes/_unversioned/ and the
# preflight (b) tolerance whitelisted notes/_unversioned/ — so the residue gate was a
# silent no-op, and preflight (b) FAILED on the scaffold the script itself had just
# written. That is the resume deadlock the (b) tolerance exists to prevent, and it did
# not clear when the operator authored the note: the blocking record is the untracked
# FLAT path, which no tolerance names. One resolver, one rule, no site left behind.
#
# DERIVED from notes_rel_path() rather than restating its conditional, so the two
# forms cannot drift apart — the whole defect above was two hand-kept copies of one
# rule. Resolved off $RELEASE_NOTES_DIR (never a hardcoded root) so a self-test that
# sandboxes the notes dir is honored. The relative form stays in notes_rel_path() —
# git porcelain and the INDEX link are repo-root-relative, this is filesystem-absolute.
notes_abs_path() {
  local rel; rel="$(notes_rel_path)"
  printf '%s/%s' "$RELEASE_NOTES_DIR" "${rel#notes/}"
}

# ─── The release's PLAN file — selected by EXISTENCE, never by layout ─────────
#
# The plans-corpus analogue of notes_rel_path()/notes_abs_path() above, and the
# same defect one corpus over. Three emitters below (the scaffolded note's
# links.plan frontmatter, the chore-PR body's Cross-references block, and the D-1
# issue-close comment) each retyped release/releases/plans/<VERSION>_RELEASE_PLAN.md
# — a FOURTH form matching none of the homes the corpus actually uses — so every
# close-out minted a plan pointer that dangled on arrival. One resolver, one rule,
# no site left behind.
#
# This function AUTHORS no layout — it PROBES one. It walks the homes
# release/releases/plans/README.md § Disposition rule already documents, in that
# rule's own order, and returns the first that EXISTS. Because existence IS the
# selection criterion it structurally cannot emit a path that is not there; a
# future corpus-layout change degrades to a loud "unresolved" rather than to a
# silently wrong pointer. release/tools/claim-version.sh remains the sole
# WRITE-SIDE hardcoder of the versioned home (search it for `plans/v${vM}`) and is
# NOT modified here — one WRITER of the layout, and this side never writes it.
#
# WHAT THIS SIDE DOES HOLD. An earlier form of the line above claimed this side
# "holds no layout literal at all", which was false on its own surface: the
# resolver pair below carries a layout literal on 12 code lines — 10 in
# plan_rel_path(), 2 in plan_rel_path_expected() — and the block enumerates five
# layout forms a dozen lines further down. Re-derive rather than trust the
# figure: grep the two function bodies for `_RELEASE_PLAN.md`. The distinction
# that actually binds is READ-side versus WRITE-side, not literal-count: every
# literal here is a probe guarded by existence, so a stale one resolves nothing
# and says so, where a stale literal on the write side mints a pointer that
# dangles on arrival. That asymmetry is the reason the two sides are allowed to
# hold layout knowledge on different terms.
#
# FIVE candidates, not three, because the shipped corpus carries five structural
# forms and a resolver blind to one of them turns a model gap into a dangling
# pointer rather than a fallback:
#
#   1  v<MAJOR>/<VERSION>_RELEASE_PLAN.md    nested, version-named  rule 1 (ADR-092)
#   2  v<MAJOR>/<SLUG>_RELEASE_PLAN.md       nested, slug-named     rule 1, rename never fired
#   3  _unversioned/<SLUG>_RELEASE_PLAN.md   version-less           rule 2
#   4  <SLUG>_RELEASE_PLAN.md                flat, slug-named       rule 0 (pre-claim / in flight)
#   5  <VERSION>_RELEASE_PLAN.md             flat, version-named    rule 0 legacy
#
# Candidate 2 is not hypothetical and is the one a three-valued reading of the
# disposition rule misses: the mainline carries plans nested under a major-version
# folder whose basename is the milestone SLUG, not the version. They match no other
# candidate. Candidate 5 is not vestigial either — v3-era notes point at flat
# version-named plans that resolve today.
#
# Ordered rule-1-first so a correctly-claimed release binds its canonical home even
# if a stale flat copy lingers, and so the order is an asserted property (see the
# PL-* self-test arms) rather than an incidental one.
#
# Resolved off $RELEASE_PLANS_DIR, never a hardcoded root — exactly as
# notes_abs_path() resolves off $RELEASE_NOTES_DIR and for the same stated reason:
# so a self-test that sandboxes the plans dir is honored rather than silently
# reading the live repository tree. The repo-relative prefix is DERIVED from
# $RELEASE_PLANS_DIR rather than retyped, so there is no second expression of the
# corpus root to drift.
#
# Contract: echoes the REPO-RELATIVE path of the first existing candidate and
# returns 0; echoes NOTHING and returns 1 when no candidate exists. Pure query —
# reads only, mutates nothing, no network.
plan_rel_path() {
  local slug="${STATE_MILESTONE_SLUG:-$VERSION}"
  local root="${RELEASE_PLANS_DIR#"$REPO_ROOT"/}"
  local vM=""
  is_version_less || vM="$(extract_major "$VERSION")"

  if [[ -n "$vM" ]]; then
    if [[ -f "${RELEASE_PLANS_DIR}/${vM}/${VERSION}_RELEASE_PLAN.md" ]]; then
      printf '%s/%s/%s_RELEASE_PLAN.md' "$root" "$vM" "$VERSION"; return 0
    fi
    if [[ "$slug" != "$VERSION" && -f "${RELEASE_PLANS_DIR}/${vM}/${slug}_RELEASE_PLAN.md" ]]; then
      printf '%s/%s/%s_RELEASE_PLAN.md' "$root" "$vM" "$slug"; return 0
    fi
  fi
  if [[ -f "${RELEASE_PLANS_DIR}/_unversioned/${slug}_RELEASE_PLAN.md" ]]; then
    printf '%s/_unversioned/%s_RELEASE_PLAN.md' "$root" "$slug"; return 0
  fi
  if [[ -f "${RELEASE_PLANS_DIR}/${slug}_RELEASE_PLAN.md" ]]; then
    printf '%s/%s_RELEASE_PLAN.md' "$root" "$slug"; return 0
  fi
  if [[ "$slug" != "$VERSION" && -f "${RELEASE_PLANS_DIR}/${VERSION}_RELEASE_PLAN.md" ]]; then
    printf '%s/%s_RELEASE_PLAN.md' "$root" "$VERSION"; return 0
  fi
  return 1
}

# The canonical home this release's plan WOULD occupy — the annotation fallback,
# never a resolution. Used only when plan_rel_path() finds nothing, so the emitted
# artifact still says which home was expected instead of going blank.
plan_rel_path_expected() {
  local slug="${STATE_MILESTONE_SLUG:-$VERSION}"
  local root="${RELEASE_PLANS_DIR#"$REPO_ROOT"/}"
  if is_version_less; then
    printf '%s/_unversioned/%s_RELEASE_PLAN.md' "$root" "$slug"
  else
    printf '%s/%s/%s_RELEASE_PLAN.md' "$root" "$(extract_major "$VERSION")" "$VERSION"
  fi
}

# The value the three emitters WRITE — ONE producer for all three, which is what
# makes "3 sites, 1 resolver" an asserted property (arm PL-8) rather than a
# convention. When the plan resolves this is that path verbatim. When it does not,
# it is the expected home carrying the literal ` (unresolved at close-out)` suffix
# and the function returns 1, so the caller can additionally notice on stderr.
#
# ANNOTATE-AND-CONTINUE, not halt, and the choice is deliberate. Refusing to write
# the note would put the FIRST failure path into phase_scaffold_release_notes —
# a phase that today returns 0 on every branch and runs at position 12 of 38, after
# the chore branch is cut and after the RELEASE_LOG DEPLOYED->VERIFIED transition
# and seven further ledger writers. Pre-merge partial state is explicitly out of
# scope in core/rules/../partial-deployment-recovery, so the abort would land in a
# governed gap. It is also unnecessary: phase_lint_release_notes runs ONE phase
# later and blocks the close on any finding naming this release's note, and the
# corpus lint now emits exactly such a finding for an unresolved links.plan value
# at or above the ADR-092 cutover. Same blocking outcome, no new abort point, and
# the behaviour is identical across all three sites instead of asymmetric.
plan_ref_for_emit() {
  local p
  if p="$(plan_rel_path)"; then
    printf '%s' "$p"
    return 0
  fi
  printf '%s (unresolved at close-out)' "$(plan_rel_path_expected)"
  return 1
}

# The INDEX Version-cell label: version-less rows carry the "(version-less)" marker.
index_version_cell() {
  if is_version_less; then printf '%s (version-less)' "$VERSION"; else printf '%s' "$VERSION"; fi
}

# ─── Derived-surface projection (#4455) ──────────────────────────────────────
#
# ONE writer for the three DERIVED ledgers. Phases 7 / 8 / 9.5 used to synthesise
# their entry content inline — three independent write paths for one release
# fact, which is the duplication this card exists to end. Each now asks the
# projector for ONE ENTRY on stdout and performs the insertion itself.
#
# The projector emits ENTRIES, NEVER FILES. That division is deliberate and is
# the design's central safety property: the majority of historical DIGEST and
# CHANGELOG entries carry post-emission operator edits that exist nowhere else,
# so a component able to rewrite a whole ledger makes a silent, clean-diff
# destruction of ~100 hand-authored entries reachable. Insertion stays here.
#
# Two rules this function owns:
#
#  (1) FAIL-CLOSED ON AN EMPTY EMISSION. The inline heredocs could not emit
#      nothing — they wrote the file directly. A `$(...)` capture CAN, and an
#      unguarded capture inserts a blank line and returns 0. This is a failure
#      mode the refactor CREATES, so it is gated in the same change: non-zero
#      exit OR empty stdout is a FAIL, never a silent no-op insertion.
#  (2) EVERY NON-FILE INPUT IS PASSED, NEVER RE-DERIVED. Both date anchors and
#      the repo slug are sampled or resolved exactly once, by this script, which
#      already owns them. The projector cannot reach a clock or an operator
#      config; a value it could re-derive is a second writer of a fact that
#      already has one, which is exactly what produced the permanent INDEX-Date
#      grandfathering enumeration in the checker.
#
# Corpus paths are passed as arguments too, so the hermetic self-test drives the
# projector against its sandbox fixtures instead of the live corpus.
#
# The MERGE anchor is resolved for every surface, not just the INDEX, so one rule
# covers all three. Preflight already asserts the LOG row exists at DEPLOYED
# before any of these phases run, so an unresolvable Date here is a real schema
# anomaly — fail loudly rather than substitute a clock.
#
# stdout: the emitted entry, trailing newlines intact (the CHANGELOG block ends
# with a blank line, and that blank line is load-bearing separation).
# stderr: the projector's own diagnostics. Return: 0, or non-zero on any failure.
emit_derived_entry() {
  local _surface="$1"

  if [[ ! -f "$PROJECTOR" ]]; then
    printf 'release-corpus projector not found at %s\n' "$PROJECTOR" >&2
    return 3
  fi

  local _merge_anchor
  _merge_anchor="$(extract_row_date "$(find_log_row "$VERSION")")"
  if [[ -z "$_merge_anchor" ]]; then
    printf 'could not resolve the merge-anchored Date from the RELEASE_LOG row for %s\n' "$VERSION" >&2
    return 3
  fi

  local -a _args=(
    --emit "$_surface"
    --version "$VERSION"
    --merge-anchor "$_merge_anchor"
    --closeout-anchor "$CLOSEOUT_ANCHOR_UTC"
    --repo-slug "$REPO_SLUG"
    --log-path "$RELEASE_LOG"
    --index-path "$RELEASE_INDEX"
    --notes-dir "$RELEASE_NOTES_DIR"
  )
  if is_version_less; then _args+=(--version-less); fi

  # The `printf X` sentinel preserves trailing newlines that $( ) would strip,
  # and the explicit `exit` propagates the PROJECTOR's status rather than
  # printf's — the same class of mistake as reading `$?` after a pipe.
  local _out _rc=0
  _out="$(/usr/bin/python3 "$PROJECTOR" "${_args[@]}"; _prc=$?; /usr/bin/printf 'X'; exit "$_prc")" || _rc=$?
  _out="${_out%X}"

  if [[ $_rc -ne 0 ]]; then
    printf 'projector exited %s emitting the %s entry for %s\n' "$_rc" "$_surface" "$VERSION" >&2
    return "$_rc"
  fi
  # Emptiness is tested on the WHITESPACE-STRIPPED value: a projector that
  # emitted only a newline would otherwise read as non-empty and insert a blank
  # line, which is the exact silent no-op this rule exists to prevent.
  local _out_stripped
  _out_stripped="$(/usr/bin/printf '%s' "$_out" | /usr/bin/tr -d '[:space:]')"
  if [[ -z "$_out_stripped" ]]; then
    printf 'projector emitted an EMPTY %s entry at exit 0 — refusing to insert a blank line\n' "$_surface" >&2
    return 3
  fi
  printf '%s' "$_out"
  return 0
}

# Working-tree tolerance for preflight step (b). Reads `git status --porcelain` text
# on stdin and emits the records that BLOCK a close — i.e. everything except the one
# tolerated record: an UNTRACKED release note for the version being closed.
#
# Whole-line matching (`grep -x`) is load-bearing. A substring match would also
# tolerate ' M <that path>' (a modified TRACKED note — real uncommitted work) and
# '?? <that path>.bak'. Only the exact untracked record passes.
#
# The `release/releases/` prefix is REQUIRED: notes_rel_path() is relative to
# release/releases/, while porcelain paths are repo-root-relative. Dropping it makes
# the filter match nothing and the tolerance silently stops working.
filter_tolerated_worktree_state() {
  /usr/bin/grep -vxF "?? release/releases/$(notes_rel_path)" || true
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

# The single residue scanner both shell anchors (A1 preflight, A3 derived surfaces)
# call, so there is one implementation to test and one to keep correct.
#
# Input:  pre-numbered "<line-no><TAB><text>" records on stdin. Callers number their
#         own input because A1 scans a whole file while A3 scans a version-scoped
#         SLICE whose line numbers must still refer to the real file.
# Output: "<token>|<line-no>" for the FIRST hit.
# Return: 0 clean · 1 residue found · 2 token set unreadable.
#
# Return 2 is NOT clean. A caller that collapses it into 0 reintroduces exactly the
# green-for-the-wrong-reason failure this gate exists to remove.
scan_scaffold_residue() {
  local tokens
  tokens="$(scaffold_residue_tokens)" || return 2
  local input; input="$(/bin/cat)"
  [[ -z "$input" ]] && return 0
  local tok hit
  while IFS= read -r tok; do
    [[ -z "$tok" ]] && continue
    hit="$(printf '%s\n' "$input" | /usr/bin/grep -F -- "$tok" | /usr/bin/head -1 || true)"
    if [[ -n "$hit" ]]; then
      printf '%s|%s\n' "$tok" "${hit%%$'\t'*}"
      return 1
    fi
  done <<< "$tokens"
  return 0
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

# Extract the MERGE-anchored Date column from a RELEASE_LOG row (#3718).
#
# Pinned by HEADER NAME, not by ordinal: the Date column's position has moved
# before (the legacy 5-column schema had no Date at all), and an ordinal pin
# reads the wrong cell silently the next time it moves. Resolves the column index
# from the RELEASE_LOG header row, then returns that field iff it is a
# well-formed YYYY-MM-DD. Emits EMPTY — never a guess — when the header, the
# column, or a well-formed value cannot be resolved, so the caller can fail
# loudly rather than substitute the close-out clock and re-open the divergence.
extract_row_date() {
  local row="$1"
  [[ -z "$row" ]] && return 0
  /usr/bin/python3 - "$RELEASE_LOG" "$row" <<'PY'
import re, sys

log_path, row = sys.argv[1], sys.argv[2]

def cells(line):
    s = line.strip()
    if s.startswith("|"):
        s = s[1:]
    if s.endswith("|"):
        s = s[:-1]
    return [c.strip() for c in s.split("|")]

col = None
try:
    with open(log_path, encoding="utf-8") as f:
        for line in f:
            if not line.lstrip().startswith("|"):
                continue
            header = cells(line)
            if "Version" in header and "Date" in header:
                col = header.index("Date")
                break
except OSError:
    pass

if col is None:
    sys.exit(0)

fields = cells(row)
if col < len(fields) and re.fullmatch(r"\d{4}-\d{2}-\d{2}", fields[col]):
    sys.stdout.write(fields[col])
PY
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

# True when phase-record index $1 holds the FIRST occurrence of its phase name.
# Both report renderers walk the record through this predicate, so a name marked
# more than once emits exactly ONE row carrying its FIRST result — the semantics
# get_phase already has (its lookup returns on the first name hit above), which
# is what makes the derived render provably additive: the row SET grows by the
# previously-omitted phases and no existing row changes.
#
# Deliberately NOT named phase_* — that prefix is the dispatchable-phase
# namespace, and `grep '^phase_'` over this file is a live survey/self-test form.
is_first_phase_occurrence() {
  local i="$1" j
  for ((j=0; j<i; j++)); do
    if [[ "${PHASE_NAMES[$j]}" == "${PHASE_NAMES[$i]}" ]]; then return 1; fi
  done
  return 0
}

# ─── Shared: the Phase-A7 learnings-capture predicate — ONE definition, two sites
#
# Phase 6.7 (append_release_learnings) owns the D-1 refusal: a render reporting
# ZERO source events is the synthesizer's honest "nothing was captured" sentinel,
# and appending it writes an absence of EVIDENCE into a permanent record as a
# statement of FACT. That refusal fires at dispatch position 8 — after
# create_chore_branch, transition_release_log and two field injections have
# already written, on a tree the operator then has to reset by hand.
#
# Preflight asserts the SAME condition at dispatch position 1. The predicate
# therefore lives HERE, in ONE definition both call, rather than being re-probed
# inside preflight: phase_append_release_learnings already rejects that shape in
# its own words — "a second composer here would be a second writer of a fact that
# already has one" — and the file's shared-resolver precedent
# (_resolve_deployment_log_target, consumed by 6.5 / 6.6 / 6.8 so BOTH lookups
# resolve through the ONE resolver and can never disagree about which file they
# mean) is exactly the guarantee a gate and its backstop owe each other.
#
# Deliberately NOT named phase_* — that prefix is the dispatchable-phase namespace.

# Placement-idempotency probe. Returns 0 when `#### Release Learnings <VERSION>`
# is ALREADY the next `#### ` heading after `#### Deployment Log <VERSION>`.
# Expressed as PLACEMENT rather than presence: a bare presence grep is also
# satisfied by a learnings block sitting somewhere else in the ledger entirely,
# and would then skip a genuine placement defect.
# HOT LEDGER ONLY (RECORDS_POLICY KEEP_CLASS) — deliberately NOT routed through
# _resolve_deployment_log_target: a Release Learnings block is never written to,
# and so never read from, an archive segment.
_learnings_block_placed() {
  local _lbp_next
  _lbp_next="$(/usr/bin/awk -v ver="$VERSION" '
      { line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line) }
      seen && line ~ /^#### / { print line; exit }
      line == "#### Deployment Log " ver { seen = 1 }
    ' "$RELEASE_LOG" 2>/dev/null || true)"
  [[ "$_lbp_next" == "#### Release Learnings $VERSION" ]]
}

# The capture remedy, as ONE string. The preflight gate and the 6.7 backstop both
# print it, so an operator who hits either is told the same command.
_learnings_capture_remedy() {
  /usr/bin/printf '%s' "capture the release's learnings triple FIRST, then re-run close-out: release/tools/append-pipeline-event.sh --version $VERSION --stage 13 --event-type release-synthesis --event-subtype learnings-triple --actor <actor> --subject <subject> --payload '<surprise/would-change/watch-for>' (run it with --help for the required flag set, and --dry-run to validate the row before appending)"
}

# THE CAPTURE-GAP PREDICATE — returns 0 for EXACTLY ONE condition: the
# `release-synthesis/learnings-triple` row for this release was never captured.
# Returns 1 in every other case, INCLUDING every degraded case.
#
# It mirrors phase 6.7's arm PRECEDENCE, not merely 6.7's last arm. 6.7 evaluates
# an ordered ladder — anchor presence, placement-idempotency SKIPPED,
# synthesizer-not-executable SKIPPED, render-failure FAIL, structural FAIL, and
# only THEN the D-1 zero-source-event BLOCK. Lifting the last arm without its
# predecessors inverts that precedence and manufactures a false block: a resumed
# close whose block is already correctly placed, or a run on a host without the
# synthesizer, would then be refused at the door by the gate that exists to
# protect 6.7. Preflight has LESS information than 6.7 and must not pretend
# otherwise.
#
# DEGRADE NEVER ESCALATES. A missing or non-executable synthesizer, a render that
# exits non-zero, and a whitespace-only render all return 1 here. FAILing on them
# would convert a degraded ENVIRONMENT into a close-out failure — the judgement
# phase_inject_close_class_telemetry_field already records for its own producer.
# 6.7 still owns those arms, with its richer diagnostic, at position 8.
#
# The parity property this owes 6.7 — a 0 here implies 6.7 returns 3 — is
# asserted as MECHANISM by the Test 4c.5 parity arm, not left to convention: this
# predicate is a fixed conjunction while 6.7 is an ordered ladder later cards will
# extend, and two shapes cannot be held in agreement by construction.
_learnings_capture_gap() {
  # Arm 1 — already placed. 6.7 SKIPs this; so does the gate. A re-entry the
  # backstop waves through is never blocked by the gate that protects it.
  if _learnings_block_placed; then return 1; fi

  # Arm 2 — synthesizer unavailable. 6.7 SKIPs; the gate asserts nothing.
  if [[ ! -x "$SYNTHESIZE_LEARNINGS" ]]; then return 1; fi

  # Arm 3 — render. Sentinel-preserved capture, identical to 6.7's, so the
  # producer's trailing newlines are not eaten by `$( )` and the explicit exit
  # propagates the PRODUCER's status rather than printf's.
  local _lcg_render _lcg_rc=0 _lcg_prc
  _lcg_render="$("$SYNTHESIZE_LEARNINGS" --mode per-release --version "$VERSION" 2>/dev/null; _lcg_prc=$?; /usr/bin/printf 'X'; exit "$_lcg_prc")" || _lcg_rc=$?
  _lcg_render="${_lcg_render%X}"
  local _lcg_stripped
  _lcg_stripped="$(/usr/bin/printf '%s' "$_lcg_render" | /usr/bin/tr -d '[:space:]')"
  if [[ "$_lcg_rc" -ne 0 || -z "$_lcg_stripped" ]]; then return 1; fi

  # Arm 4 — the ONE condition this predicate owns. `grep` reads a HERE-STRING,
  # never `producer | grep -q`: under `set -euo pipefail` grep -q exits at the
  # first match and SIGPIPEs the writer, so pipefail promotes a SUCCESSFUL match
  # to a non-zero status and the assert silently inverts.
  /usr/bin/grep -qE '^\*\*Source events:\*\* 0([^0-9]|$)' <<<"$_lcg_render"
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
  local _dirty
  _dirty="$($GIT -C "$REPO_ROOT" status --porcelain 2>/dev/null | filter_tolerated_worktree_state)"
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
  local _note; _note="$(notes_abs_path)"
  if [[ -f "$_note" ]]; then
    local _res _rc=0
    _res="$(/usr/bin/awk '{print NR "\t" $0}' "$_note" | scan_scaffold_residue)" || _rc=$?
    if [[ $_rc -eq 2 ]]; then
      mark_phase "preflight" "FAIL" "scaffold-residue token set unreadable from ${LINT_RELEASE_CORPUS} (--print-scaffold-tokens) — the residue gate cannot be evaluated; failing loud rather than passing vacuously (#459)"
      return 2
    elif [[ $_rc -eq 1 ]]; then
      mark_phase "preflight" "FAIL" "unfilled scaffold token in ${_note} at line ${_res#*|} — token '${_res%%|*}'; author the release note before close-out (release-notes-standard.md §3.2)"
      return 2
    fi
  fi

  # (g) Phase-A7 learnings-triple capture gate — the LAST sub-check, and it must
  # stay last. The predicate renders through synthesize-release-learnings.sh,
  # which resolves `--release <slug>` through the RELEASE_LOG join ladder; (d)
  # and (d.1) are what guarantee that ladder sees EXACTLY ONE matching row. The
  # constraint is diagnostic PRECEDENCE, not resolution correctness: reordering
  # does not change what the ladder reads, because (d)/(d.1) verify the row and
  # never mutate it. What it changes is WHICH remedy the operator is handed. Run
  # first, (g) would tell an operator whose Stage-12 chore PR never landed to
  # "capture your learnings triple" — wrong remedy, wrong stage, and a triple
  # captured in response would not clear it. Placed last, the run has ALREADY
  # died on the true cause, so the misdiagnosis is unreachable rather than merely
  # unlikely.
  #
  # This condition is a MISSING INPUT, not a not-yet-ready state, and the two
  # classes have different remedies — see stage-13-close.md Phase A8.
  if _learnings_capture_gap; then
    local _g_msg="the release-synthesis/learnings-triple row for $VERSION was never captured — the $VERSION learnings render reports 0 source events, so phase 6.7 would refuse to append the '#### Release Learnings $VERSION' block seven phases from here, with four write phases already applied. Stopping at the door instead leaves a clean tree and nothing to reset. This is a MISSING INPUT, not a not-yet-ready state: the Phase-A8 hand-assembly fallback does NOT apply to it, because hand-assembling the block would produce by hand exactly the unevidenced record phase 6.7 exists to refuse. Remedy: $(_learnings_capture_remedy)"
    if [[ "$MODE" == "dry-run" ]]; then
      mark_phase "preflight" "WARN" "$_g_msg — NOT blocking under --dry-run (nothing is committed, so no record can be corrupted here); this same condition FAILS the close at --apply"
      return 0
    fi
    mark_phase "preflight" "FAIL" "$_g_msg"
    return 2
  fi

  mark_phase "preflight" "PASS" "gh auth OK; tree clean; cwd worktree; RELEASE_LOG row state=$STATE_LOG_ROW_STATE; tag_exists=$STATE_TAG_EXISTS; no scaffold residue in ${VERSION} note; A7 learnings-triple: no capture gap"
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

# ─── Shared: collect_open_release_issues (#3665 matcher · #3587 single home) ──
#
# Enumerate the milestone's OPEN release issues minus the Stage-13 orchestration
# exclusions. This is the SINGLE home of the exclusion predicate, called by both
# the PRE-close detect (Phase 4) and the POST-close verification re-read (Phase 15
# check 5), so the count the close-out reports and the count it verifies cannot
# disagree with themselves (#3587 x #3665). A second copy of the matcher would make
# that agreement a discipline promise instead of a structural invariant.
#
# Projection `--json number,title,labels`; line format "<number>\t<labels-csv>\t<title>".
# The TITLE IS LAST deliberately: `${_rest#*$'\t'}` is non-greedy, so a title
# containing a literal tab still parses intact.
#
# Outputs (globals, NOT stdout — bash runs `$( … )` in a subshell, which would
# discard the EXCLUDED_DETAIL side channel and silently empty the "(excluded: …)"
# fragment of the Phase-4 report line):
#   COLLECTED_OPEN_ISSUES — surviving issue numbers, newline-separated, trimmed
#   EXCLUDED_DETAIL       — "#N (<reason>) " fragments for the caller's mark_phase
# Returns 0 = query succeeded (empty output legitimately means zero open)
#         1 = `gh issue list` failed — output undefined. The caller MUST NOT read
#             empty as zero: Phase 4 deliberately keeps today's tolerant behaviour
#             (pre-existing fail-open, routed separately), check 5 fails closed.
#
# ─── Shared predicate: _is_stage13_close_subtask (#3819) ─────────────────────
#
# "Is this issue the Stage-13 Close ORCHESTRATION SUB-TASK?" — the label test
# (`sub-task` canonical ∪ `type:subtask` tolerated legacy alias, EXACT
# comma-wrapped membership) AND the stage-13-close title regex. Both conjuncts
# required, semantics byte-identical to the inline arm this replaces.
#
# TWO callers, and the boundary between them matters: `collect_open_release_issues`
# uses it to EXCLUDE the sub-task from auto-close (a `--state open` query is
# correct there — a closed sub-task cannot self-close), and `resolve_stage13_subtask`
# uses it to FIND the sub-task as a comment target (a `--state open` query is WRONG
# there — on an idempotent re-run or a `--no-merge` re-entry the sub-task may already
# be closed, and a closed sub-task is still the correct durable home for the proof).
# THE SHARED INVARIANT IS THE PREDICATE, NOT THE QUERY. Do not "unify" the two
# callers onto one query state: that would either resurrect a closed sub-task into
# the auto-close set or make the proof target unresolvable on every re-run.
#
# Args: $1 = labels CSV (as projected by --json labels)  ·  $2 = title
# Returns 0 = is the Stage-13 close sub-task · 1 = is not
_is_stage13_close_subtask() {
  local _labels="$1" _title="$2" _is_subtask
  # Set unconditionally — never `[[ … ]] && _is_subtask=1` alone: bash 3.2 does not
  # scope loop-body assignments, and a leaked value would make the test STICKY.
  case ",${_labels}," in
    *",sub-task,"*|*",type:subtask,"*) _is_subtask=1 ;;
    *)                                 _is_subtask=0 ;;
  esac
  [[ "$_is_subtask" -eq 1 ]] \
    && /usr/bin/printf '%s' "$_title" | /usr/bin/grep -qiE 'stage.?13.*close'
}

collect_open_release_issues() {
  local slug="$1"
  local raw _rc=0
  raw="$($GH issue list --repo "$REPO_SLUG" --milestone "$slug" --state open --json number,title,labels --jq '.[] | "\(.number)\t\(.labels|map(.name)|join(","))\t\(.title)"' 2>/dev/null)" || _rc=1

  # Explicit-exclude set (#38 primary path). The Stage-13 orchestration sub-task is
  # passed by NUMBER (--exclude-issue <N>) so it is deterministically filtered and
  # cannot self-close mid-run (Risk R5).
  _is_excluded() {
    local n="$1" e
    for e in "${EXCLUDE_ISSUES[@]:-}"; do
      [[ -n "$e" && "$n" == "$e" ]] && return 0
    done
    return 1
  }

  COLLECTED_OPEN_ISSUES=""
  EXCLUDED_DETAIL=""
  # Declared here, not in the loop body: bash 3.2 does not scope loop-body
  # assignments. The `_is_subtask` scoping hazard now lives inside
  # `_is_stage13_close_subtask`, which sets it unconditionally per iteration.
  local _n _title _labels _rest _line
  while IFS= read -r _line; do
    [[ -z "$_line" ]] && continue
    _n="${_line%%$'\t'*}"
    _rest="${_line#*$'\t'}"
    _labels="${_rest%%$'\t'*}"
    _title="${_rest#*$'\t'}"
    # (1) explicit --exclude-issue (deterministic, primary)
    if _is_excluded "$_n"; then
      EXCLUDED_DETAIL="${EXCLUDED_DETAIL}#${_n} (explicit --exclude-issue) "
      continue
    fi
    # (2) label+title fallback: a Stage-13 close ORCHESTRATION SUB-TASK that the hub
    # did NOT pass by number is still excluded so it cannot self-close (R5). BOTH
    # conjuncts are required — see `_is_stage13_close_subtask` above, which is the
    # single home of the predicate. The label answers the structural question
    # (orchestration artifact vs delivered work item); the title tokens narrow it to
    # the STAGE-13 sub-task — the label alone matches every stage sub-task in the
    # milestone. Title text alone was the defect: it false-excluded 13 delivered work
    # items across the repo's history whose SUBJECT MATTER is Stage-13 close-out (#3665).
    if _is_stage13_close_subtask "$_labels" "$_title"; then
      EXCLUDED_DETAIL="${EXCLUDED_DETAIL}#${_n} (sub-task label + title-regex stage-13-close) "
      continue
    fi
    COLLECTED_OPEN_ISSUES="${COLLECTED_OPEN_ISSUES}${_n}"$'\n'
  done <<< "$raw"
  # Trim a trailing newline so grep -c counts correctly.
  COLLECTED_OPEN_ISSUES="$(/usr/bin/printf '%s' "$COLLECTED_OPEN_ISSUES" | /usr/bin/sed '/^$/d')"
  return "$_rc"
}

# ─── Shared: resolve_stage13_subtask (#3819 — gate-passage-proof rung 1) ─────
#
# Resolve the milestone's Stage-13 Close sub-task as a COMMENT TARGET. Unlike
# `collect_open_release_issues` this queries `--state all` — see the boundary note
# on `_is_stage13_close_subtask`: the shared invariant is the predicate, not the
# query. `--state open` is load-bearing for the collector's auto-close purpose and
# WRONG here, because a Stage-13 sub-task closed by an earlier pass of an idempotent
# run is still the correct durable home for the proof.
#
# STDOUT (always exactly one TAB-separated line, so the caller needs no global and
# there is no cross-phase lifetime to reset — the Bash-3.2 sticky-scope hazard
# cannot arise):
#   "<number>\t<state>\t"            — resolved; state is OPEN or CLOSED
#   "\t\t<observed reason>"          — unresolved; reason is what was OBSERVED,
#                                      never a generic "unresolved"
# Return code is always 0: a resolution miss is a routing fact for the rung ladder,
# not a script failure.
resolve_stage13_subtask() {
  local slug="$1"
  local raw _rc=0 _line _n _rest _labels _title _state

  if [[ -z "$slug" ]]; then
    /usr/bin/printf '\t\t%s\n' "milestone slug unresolved at read-state"
    return 0
  fi

  raw="$($GH issue list --repo "$REPO_SLUG" --milestone "$slug" --state all \
          --json number,title,labels,state \
          --jq '.[] | "\(.number)\t\(.labels|map(.name)|join(","))\t\(.state)\t\(.title)"' 2>&1)" || _rc=1
  if [[ "$_rc" -ne 0 ]]; then
    # First line only, and strip tabs/pipes: this string reaches a mark_phase detail
    # (pipe-delimited) and a Markdown table cell.
    /usr/bin/printf '\t\t%s\n' "gh query failed: $(/usr/bin/printf '%s' "$raw" | /usr/bin/head -1 | /usr/bin/tr '\t|' '  ')"
    return 0
  fi

  while IFS= read -r _line; do
    [[ -z "$_line" ]] && continue
    _n="${_line%%$'\t'*}"
    _rest="${_line#*$'\t'}"
    _labels="${_rest%%$'\t'*}"
    _rest="${_rest#*$'\t'}"
    _state="${_rest%%$'\t'*}"
    # Title last so a title containing a literal tab still parses intact.
    _title="${_rest#*$'\t'}"
    if _is_stage13_close_subtask "$_labels" "$_title"; then
      /usr/bin/printf '%s\t%s\t\n' "$_n" "$_state"
      return 0
    fi
  done <<< "$raw"

  /usr/bin/printf '\t\t%s\n' "not found in milestone ${slug} (all states)"
  return 0
}

# ─── Phase 4: detect_open_release_issues (D6 — auto-close anomaly) ───────────

phase_detect_open_issues() {
  local slug="$STATE_MILESTONE_SLUG"
  [[ -z "$slug" ]] && slug="$VERSION"

  # Tolerant by design: a `gh` failure reads as "zero open" here, exactly as it did
  # before the helper extraction. Preserved deliberately — tightening it changes
  # Phase-4 semantics and is routed to its own ticket, not fixed in passing.
  collect_open_release_issues "$slug" || true
  OPEN_ISSUE_LIST="$COLLECTED_OPEN_ISSUES"
  local _excluded_detail="$EXCLUDED_DETAIL"

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
# ─── Two-surface Deployment-Log block resolution ──────────────────────────────
#
# The archival sweep relocates aged-out `#### Deployment Log` block BODIES into
# same-directory `RELEASE_LOG_ARCHIVE-<family>.md` segments, leaving the heading
# plus an `_Archived: …_` pointer in the hot ledger so every anchor still
# resolves. A lookup scoped to the hot ledger alone therefore finds the heading
# and an effectively empty body for every archived release.
#
# BOTH lookups in phase_inject_outcome_field — the idempotency probe and the
# injection itself — resolve through the ONE resolver below, so they can never
# disagree about which file they mean. This is not a stylistic preference: a
# single-surface idempotency probe paired with a two-surface injection is
# strictly WORSE than the defect it fixes. The probe would read the hot ledger,
# see the stub, conclude nothing had been injected, and inject a SECOND time
# into the segment — trading a loud, visible failure for a silent duplication
# inside an archived record.
#
# A genuine absence still fails. Some early releases never carried a
# `**Result:**` field at all, and no amount of segment-awareness recovers a
# field that was never written; those must remain a hard failure, and the
# failure now names every surface it searched.

# Sets DEPLOYMENT_LOG_FILES to the hot ledger followed by its same-directory
# archive segments, in that order. A repository with no segments yields the hot
# ledger alone, so pre-sweep behaviour is unchanged.
_collect_deployment_log_files() {
  DEPLOYMENT_LOG_FILES=( "$RELEASE_LOG" )
  local _dir _f
  _dir="$(/usr/bin/dirname "$RELEASE_LOG")"
  for _f in "$_dir"/RELEASE_LOG_ARCHIVE-*.md; do
    if [[ -f "$_f" ]]; then DEPLOYMENT_LOG_FILES+=( "$_f" ); fi
  done
  return 0
}

# Space-joined basenames of every surface a block lookup consults — the
# "searched:" evidence carried in the failure message.
_deployment_log_surfaces_desc() {
  _collect_deployment_log_files
  local _f _out=""
  for _f in "${DEPLOYMENT_LOG_FILES[@]}"; do
    _out="${_out:+$_out }$(/usr/bin/basename "$_f")"
  done
  printf '%s\n' "$_out"
}

# Probe ONE file for the `#### Deployment Log <version>` block.
#   exit 0 — block present AND carries a `**Result:**` line (the injection anchor)
#   exit 1 — block present, but no `**Result:**` line inside it
#   exit 2 — block heading absent from this file
# Lines are compared after trimming surrounding whitespace so this probe and the
# Python injection below (which compares on a stripped line) resolve the same
# block rather than diverging on a heading with trailing space.
_probe_deployment_log_block() {
  /usr/bin/awk -v ver="$2" '
    { line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line) }
    line == "#### Deployment Log " ver { inblk = 1; seen = 1; next }
    inblk && line ~ /^#### / { inblk = 0 }
    inblk && line ~ /^\*\*Result:\*\*/ { found = 1 }
    END { exit(found ? 0 : (seen ? 1 : 2)) }
  ' "$1" 2>/dev/null
}

# Echo the first surface whose `#### Deployment Log <version>` block carries a
# `**Result:**` line — the file the `**Outcome:**` field belongs in. Returns 1
# and echoes nothing when no surface carries one.
_resolve_deployment_log_target() {
  local _ver="$1" _f
  _collect_deployment_log_files
  for _f in "${DEPLOYMENT_LOG_FILES[@]}"; do
    if _probe_deployment_log_block "$_f" "$_ver"; then
      printf '%s\n' "$_f"
      return 0
    fi
  done
  return 1
}

# Record an archive segment this run actually WROTE INTO, so
# phase_commit_chore_pr can stage it (#4710). Call AFTER a successful write,
# with the resolved target.
#
# WHY THIS EXISTS. The resolver above can route a write to an archive segment,
# but the chore-PR staging array is a fixed enumeration that names only the hot
# ledger. A resolver-routed write therefore landed on disk and was DROPPED at
# commit — exit 0, no diagnostic, the phase reporting PASS while a mandated
# output never reached the PR. Silence was the worse half of that defect.
#
# TOUCHED-ONLY, NOT A GLOB. Staging `RELEASE_LOG_ARCHIVE-*.md` blanket would
# sweep unrelated local modifications to sibling segments into a chore PR, which
# trades a dropped output for an unreviewed one. Only a segment this run wrote
# into is recorded.
#
# The hot ledger is skipped — files=() already names it. Paths are stored
# repo-relative because that is what the staging loop resolves against
# ("$REPO_ROOT/$f"); a target outside REPO_ROOT keeps its absolute form and is
# then simply not matched by that loop's `[[ -f ]]` guard, which is the same
# benign no-op every other non-existent entry gets. Deduped: phases 6.5 and 6.6
# resolve to the SAME segment for a given version.
_record_touched_archive_segment() {
  local _abs="$1" _rel _e
  [[ -z "$_abs" ]] && return 0
  [[ "$_abs" == "$RELEASE_LOG" ]] && return 0
  _rel="${_abs#"$REPO_ROOT"/}"
  for _e in "${TOUCHED_ARCHIVE_SEGMENTS[@]:-}"; do
    [[ "$_e" == "$_rel" ]] && return 0
  done
  TOUCHED_ARCHIVE_SEGMENTS+=( "$_rel" )
  return 0
}

# ─── Shared block-insert primitive ────────────────────────────────────────────
#
#   _insert_field_after_in_block <target-log> <version> <anchor-prefix> <line…>
#
# Inserts one or more field lines inside a version's `#### Deployment Log`
# block, immediately after the first line whose raw text starts with
# <anchor-prefix>. Bounded to the block (next `#### ` heading or EOF), so a
# later release's identically-named field is never the anchor.
#
# <target-log> is the RESOLVED surface (see _resolve_deployment_log_target),
# never `$RELEASE_LOG` unconditionally. Post-sweep an aged-out block's body
# lives in an archive segment, and a hot-ledger-hardcoded target writes the
# field into the STUB while the rest of the record sits one file over. That
# split record still passes a presence check and still parses under the
# consumer grammar — it fails silently, which is why the target is an argument
# rather than a constant read inside this function.
#
# Passing the block heading itself (`#### Deployment Log <version>`) as the
# anchor inserts immediately AFTER the heading — the documented fallback for a
# block that carries no instrument field to anchor on yet.
#
# Exit: 0 inserted · 3 block heading absent · 4 block present, anchor absent.
# The two failure modes are DISTINGUISHED so a caller can fall back to the
# heading on 4 while still failing loudly on 3 — collapsing them would make a
# missing block indistinguishable from a missing field.
_insert_field_after_in_block() {
  local _log="$1" _ver="$2" _anchor="$3"; shift 3
  /usr/bin/python3 - "$_log" "$_ver" "$_anchor" "$@" <<'PY'
import os
import sys
log_path, version, anchor = sys.argv[1:4]
inject = list(sys.argv[4:])
log_name = os.path.basename(log_path)
with open(log_path, "r", encoding="utf-8") as f:
    lines = f.read().splitlines()

block_hdr = f"#### Deployment Log {version}"
start = None
for i, line in enumerate(lines):
    if line.strip() == block_hdr:
        start = i
        break
if start is None:
    print(f"ERROR: Deployment Log block for {version} not found in {log_name}", file=sys.stderr)
    sys.exit(3)

# Block end = next `#### ` heading after start, or EOF.
end = len(lines)
for j in range(start + 1, len(lines)):
    if lines[j].startswith("#### "):
        end = j
        break

# Anchor resolution. The block heading is matched on its STRIPPED form because
# that is how the block itself was located; every OTHER anchor keeps the
# original raw-prefix semantics, so an indented look-alike inside a fenced
# example is not mistaken for the field.
anchor_idx = None
if anchor.strip() == block_hdr:
    anchor_idx = start
else:
    for j in range(start, end):
        if lines[j].startswith(anchor):
            anchor_idx = j
            break
if anchor_idx is None:
    print(f"ERROR: {anchor} line not found in the {version} Deployment Log block in {log_name}", file=sys.stderr)
    sys.exit(4)

out = lines[:anchor_idx + 1] + inject + lines[anchor_idx + 1:]
with open(log_path, "w", encoding="utf-8") as f:
    f.write("\n".join(out) + "\n")
PY
}

# ─── NOT-PRODUCED marker (#5288) ─────────────────────────────────────────────
#
#   _write_not_produced_marker <output-id> <phase-name> <reason>
#
# Records, as corpus bytes, that a close-out output was NOT produced and why.
#
# WHY IT EXISTS. Two producing phases refuse to write when their producer tool is
# unavailable, and both refuse for a CORRECT reason: composing the output without
# its mechanism would fabricate the very claim the output exists to carry. The
# defect was never the refusal — it was that the refusal left NO trace anywhere
# durable. The only record was a SKIPPED row in an ephemeral run report, so a
# release that dropped an output and one that never owed it were indistinguishable
# in the permanent record. This marker is the difference between "absence is
# silent" and "absence is recorded". It is deliberately NOT the output rendered
# with N/A values — that is the fabrication the producers correctly refuse.
#
# EVIDENCE, NEVER AN EXEMPTION. A marker naming a `required` member does NOT
# satisfy phase 9.56 and does NOT suppress deploy.sh Check 48. Both key on the
# MEMBER; a marker is not the member, and phase_assert_output_set reads this line
# only into a report suffix, never into a verdict branch. Without that separation
# the mechanism degrades into a self-service waiver — the opposite of its purpose.
# What it IS for: durability (the absence becomes bytes on main), and `optional`
# members, whose absence would otherwise be indistinguishable from a silent drop.
#
# ANCHOR — DECLARED, not incidental. The marker is inserted immediately after
# `**Result:**` — the same line _resolve_deployment_log_target uses to RESOLVE the
# surface, so the anchor is present by construction whenever the target resolved
# at all. Declaring it is load-bearing: the block's field order is asserted by
# EXACT STRING EQUALITY in the self-test (_vl_seq extracts every `**Key:**` in
# block order), and an undeclared insertion point would shift fields under those
# literals. Markers land after `**Result:**`, so the governed prefix
# `Mechanism … Cycle-Time Velocity Result` is preserved; relative order among
# multiple markers is not asserted anywhere and is not a contract.
#
# HOME. The `#### Deployment Log <V>` block on the RESOLVED surface — the
# release's per-release record, the surface Check 48 already reaches through home
# resolution and asserts co-location on, and the one place a single probe finds
# every marker regardless of which output is absent. A learnings-block marker
# cannot live in the learnings block: the block is what is absent.
#
# Idempotent (a marker for this id already in the block is left alone) and a
# no-op under --dry-run (the caller reports what it WOULD record). Echoes the
# marker line on stdout so the caller can quote the exact bytes in its phase
# detail. Returns 0 when the marker is recorded (or already was, or would be
# under --dry-run) and 1 when it could NOT be recorded — so a caller never
# reports a durable record it does not have. Recording the absence is a best
# effort that never escalates on its own: phase 9.56 is the gate, and an
# unrecordable marker surfaces there as a still-ABSENT member.
_write_not_produced_marker() {
  local _id="$1" _phase="$2" _reason="$3" _tgt _line
  _line="**Not-produced:** ${_id} — ${_reason}; recorded at $(ts_now) by automated-closeout.sh phase ${_phase}"
  # MUST NOT BE CALLED IN A COMMAND SUBSTITUTION. This function records into
  # TOUCHED_ARCHIVE_SEGMENTS below; `$( )` is a subshell, so that append would be
  # discarded and a marker written to an archive segment would be dropped at
  # commit while the caller reported "Absence RECORDED". Callers that need the
  # bytes read NOT_PRODUCED_MARKER_LINE, set here on EVERY exit path (dry-run,
  # already-present, unresolvable target and success alike) so it cannot
  # disagree with what stdout emitted.
  NOT_PRODUCED_MARKER_LINE="$_line"
  /usr/bin/printf '%s' "$_line"
  [[ "$MODE" == "dry-run" ]] && return 0
  _tgt="$(_resolve_deployment_log_target "$VERSION" || true)"
  [[ -n "$_tgt" ]] || return 1
  _not_produced_marker_present "$_id" && return 0
  _insert_field_after_in_block "$_tgt" "$VERSION" '**Result:**' "$_line" >/dev/null 2>&1 || return 1
  # The resolver can route this write into an archive segment, and the chore-PR
  # staging array names only the hot ledger — an unrecorded segment write lands
  # on disk and is DROPPED at commit.
  _record_touched_archive_segment "$_tgt"
  return 0
}

# ─── Shared field-key grammar + block classifier (#4222) ──────────────────────
#
# THE DEFECT THIS CLOSES. Two sites independently assumed the Outcome field's key
# is the bare literal `**Outcome:**` — phase 6.5's idempotency probe and phase
# 6.8's insert anchor. A Deployment Log authored with a QUALIFIED key
# (`**Outcome (Stage-12 read; finalized at Stage 13 VERIFIED):**`) is invisible to
# both: 6.5 reads "absent" and injects a SECOND, contradicting `**Outcome:**` line
# into the audit record, and 6.8 fails to resolve its anchor. Producer and
# consumer had no shared specification to agree on, so each re-derived one — which
# is why the fix is a single shared definition rather than two patched matchers.
#
# THE SINGLE SHARED DEFINITION is the pair below: one qualifier grammar
# (`_FIELD_KEY_QUALIFIER_RE`) plus one block-scoped classifier, consumed by BOTH
# sites. Extending the grammar moves both sites at once, and that one-variable
# property is the falsifiable form of "one resolver serves both sites" — a
# one-site fix demonstrably fails it.
#
# CHARACTER CLASSES, NOT BACKSLASH ESCAPES — load-bearing, not style. The grammar
# reaches awk through `-v`, and `-v` performs escape-sequence EXPANSION on its
# value: a ` \([^)]*\)` literal arrives inside awk as ` ([^)]*)`, which is a
# CAPTURE GROUP over "any run of non-`)` characters". That silently widens the
# grammar so the real sibling field `**Outcome rationale:**` classifies as a
# qualified Outcome key, AND narrows it so a genuine qualified key stops matching
# — both directions wrong, both silent. Verified on this platform's awk before
# this line was written. The bracket form carries no backslash and survives `-v`
# byte for byte.
_FIELD_KEY_QUALIFIER_RE=' [(][^)]*[)]'

# The governance choice, in one place, HARD-ASSIGNED ON PURPOSE.
#   reject — `**Outcome:**` at column 0 is the SOLE conformant key form; a
#            qualified key is RECOGNIZED and REJECTED loudly, never silently
#            injected past. Corpus evidence: 171 bare keys, 0 qualified, across
#            the ledger and all four archive segments.
#   accept — a qualified key is conformant; the phase SKIPs with a diagnostic.
# The AUTHORITY is release/references/standards/decision-outcome-tracking.md
# § 2.1, not this line — the constant mirrors the standard, it does not decide.
#
# DO NOT convert this to the `${VAR:-default}` env-overridable idiom this file
# uses for tunables. The two settings encode two DIFFERENT governance rulings; no
# gate anywhere in the repo asserts on the Outcome field, so an env-overridable
# form would let the ruling be flipped per-invocation with no PR, no review, and
# no trace in git. A self-test arm asserts that construct's ABSENCE from the
# production region, with an anti-vacuity control on a known-bad source form.
OUTCOME_QUALIFIED_KEY_POLICY="reject"      # reject | accept

#   _resolve_field_key_in_block <target-log> <version> <base-field-name>
#     → stdout: "<CLASS>\t<raw-key-prefix>"   ·   exit 0 always
#
# CLASS ∈ CANONICAL · QUALIFIED · UNPARSEABLE · DUPLICATE · ABSENT · UNREADABLE
#
# THE CLASS SET IS WIDER THAN THE GRAMMAR ON PURPOSE. A three-value class
# (present / qualified / absent) is narrower than its callers' state space, and
# every state it cannot represent collapses into a member that already means
# something else — which is the same shape as the defect this function exists to
# close, one level up. So each reachable state gets its OWN member:
#   CANONICAL   exactly one bare `**<base>:**` key
#   QUALIFIED   exactly one `**<base> (<qualifier>):**` key
#   UNPARSEABLE a key IS present on this base but does not satisfy the grammar
#               (nested parens, a doubled space, a missing space). Collapsing this
#               into ABSENT is precisely what lets a PRESENT key drive a duplicate
#               injection, so it is reported rather than absorbed.
#   DUPLICATE   more than one Outcome-family key in the block — the fourth
#               dispatch row is reachable only because the class carries it
#   ABSENT      no key on this base. THE ONLY CLASS THAT EMITS AN EMPTY PREFIX.
#   UNREADABLE  awk could not read the surface. A degraded read never shares a
#               member with a clean one.
#
# THE PREFIX IS RAW, INCLUDING ANY LEADING WHITESPACE — load-bearing. The old
# probe compared on a STRIPPED line while `_insert_field_after_in_block` matches
# the RAW line; returning the raw prefix keeps classifier and anchor identical BY
# CONSTRUCTION, which is the producer/consumer disagreement this card roots out.
#
# CONSUMERS MUST BRANCH ON THE CLASS BEFORE READING THE PREFIX. An empty anchor is
# not a benign no-op downstream: `str.startswith("")` is True for every string, so
# an empty prefix matches the block's FIRST line, the primitive's exit-4
# "anchor absent" path becomes unreachable, and a field lands silently at the top
# of the block at exit 0.
#
# GRAMMAR BOUNDARY, STATED NOT DISCOVERED. A key whose continuation is a plain
# word (`**Outcome rationale:**`, `**Outcomes:**`) is a DIFFERENT FIELD, not a
# malformed Outcome key — that is exactly how the real, distinct
# `**Outcome rationale:**` field survives this classifier, and it is asserted in
# BOTH directions by a self-test arm. The consequence is symmetric and bounded: a
# qualifier written WITHOUT a delimiter (`**Outcome Stage-12 read:**`) is
# indistinguishable from a sibling field name by grammar alone, and classifies as
# a different field. § 2.1 states the delimiter requirement for that reason.
_resolve_field_key_in_block() {
  local _out _rc=0
  _out="$(/usr/bin/awk -v ver="$2" -v base="$3" -v qre="$_FIELD_KEY_QUALIFIER_RE" '
    function classify(key,   rem) {
      if (index(key, base) != 1) return ""
      rem = substr(key, length(base) + 1)
      if (rem == "") return "CANONICAL"
      if (rem ~ ("^" qre "$")) return "QUALIFIED"
      if (rem ~ /^[ -]?[A-Za-z0-9][A-Za-z0-9 -]*$/) return ""
      return "UNPARSEABLE"
    }
    { raw = $0; line = raw; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line) }
    line == "#### Deployment Log " ver { inblk = 1; next }
    inblk && line ~ /^#### / { inblk = 0 }
    inblk && substr(line, 1, 2) == "**" {
      key = substr(line, 3)
      p = index(key, ":**")
      if (p > 0) {
        key = substr(key, 1, p - 1)
        cls = classify(key)
        if (cls != "") {
          n++
          if (n == 1) {
            first = cls
            match(raw, /^[ \t]*/)
            firstpfx = substr(raw, 1, RLENGTH) "**" key ":**"
          }
        }
      }
    }
    END {
      if (n + 0 == 0) { printf "ABSENT\t\n"; exit 0 }
      if (n + 0 > 1)  { printf "DUPLICATE\t%s\n", firstpfx; exit 0 }
      printf "%s\t%s\n", first, firstpfx
    }
  ' "$1" 2>/dev/null)" || _rc=$?
  if [[ "$_rc" -ne 0 || -z "$_out" ]]; then
    # A surface that could not be read is NOT an absent field. Reporting it as
    # ABSENT would hand the caller a clean-looking answer and an empty prefix.
    printf 'UNREADABLE\t\n'
    return 0
  fi
  printf '%s\n' "$_out"
}

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

  # LOOKUP SITE 1 of 2 — resolve which surface holds this version's block body.
  # Post-sweep that may be an archive segment rather than the hot ledger. Both
  # lookups consume this ONE answer, so the idempotency probe below can never
  # read a different file than the injection writes.
  local target_log _surfaces
  target_log="$(_resolve_deployment_log_target "$VERSION" || true)"
  _surfaces="$(_deployment_log_surfaces_desc)"

  if [[ -z "$target_log" ]]; then
    # No surface carries a `**Result:**` line for this version. This is a
    # genuine absence — the field never existed for some early releases — not
    # an archival artefact, so it stays a hard failure. The message names every
    # file it looked in, which the pre-fix diagnostic did not: that failure said
    # only "not found in the block", implying a malformed record when the record
    # was intact one file over.
    if [[ "$MODE" == "dry-run" ]]; then
      mark_phase "inject_outcome_field" "DRY-RUN" "would FAIL: no **Result:** line in the $VERSION Deployment Log block on any surface (searched: $_surfaces)"
      return 0
    fi
    mark_phase "inject_outcome_field" "FAIL" "**Result:** line not found in the $VERSION Deployment Log block on any surface (searched: $_surfaces)"
    return 3
  fi
  local target_name; target_name="$(/usr/bin/basename "$target_log")"

  # LOOKUP SITE 2 of 2 — idempotent, block-scoped, ON THE RESOLVED SURFACE, and
  # resolved through the SHARED key grammar rather than a bare literal (#4222).
  # A bare literal is structurally incapable of distinguishing ABSENT from
  # QUALIFIED, and that distinction IS the defect: a qualified key read as absent
  # drives a second, contradicting `**Outcome:**` line into the audit record —
  # the surface least likely to be re-read. Every class that is neither a clean
  # canonical key nor a genuine absence now stops the write instead of falling
  # through it.
  local _okg_res _okg_cls _okg_pfx _okg_why _okg_msg
  _okg_res="$(_resolve_field_key_in_block "$target_log" "$VERSION" 'Outcome')"
  _okg_cls="${_okg_res%%$'\t'*}"; _okg_pfx="${_okg_res#*$'\t'}"

  case "$_okg_cls" in
    CANONICAL)
      mark_phase "inject_outcome_field" "SKIPPED" "**Outcome:** already present in the $VERSION Deployment Log block ($target_name)"
      return 0
      ;;
    ABSENT)
      : # genuine absence — fall through to the injection path below, unchanged
      ;;
    *)
      if [[ "$_okg_cls" == "QUALIFIED" && "$OUTCOME_QUALIFIED_KEY_POLICY" == "accept" ]]; then
        mark_phase "inject_outcome_field" "SKIPPED" "an Outcome field is already present in the $VERSION Deployment Log block ($target_name) under the NON-CANONICAL qualified key '$_okg_pfx' — accepted under OUTCOME_QUALIFIED_KEY_POLICY=accept, nothing injected. A silent skip over a non-conformant key is how a divergent record stays invisible, so the skip carries this diagnostic."
        return 0
      fi
      case "$_okg_cls" in
        QUALIFIED)   _okg_why="carries a NON-CONFORMANT qualified Outcome key '$_okg_pfx'" ;;
        DUPLICATE)   _okg_why="carries MORE THAN ONE Outcome-family key (first: '$_okg_pfx')" ;;
        UNPARSEABLE) _okg_why="carries an Outcome key this grammar cannot parse, '$_okg_pfx' — a nested parenthesis, a doubled space, or a missing space before the qualifier" ;;
        *)           _okg_why="could not be read for an Outcome key (classifier returned '$_okg_cls')" ;;
      esac
      # The remedy names the shape the standard ALREADY sanctions. Moving the
      # qualifier into the VALUE would satisfy this phase and then break the
      # § 6 JOIN's value extraction — the same corruption the strict key form
      # exists to prevent, relocated one field to the right.
      _okg_msg="the $VERSION Deployment Log block ($target_name) $_okg_why. decision-outcome-tracking.md § 2.1 makes '**Outcome:**' at column 0 the sole conformant key form and its value exactly one enum token; the qualification belongs on the '**Outcome rationale:**' line. Normalize the key, move the qualifier to the rationale line, then re-run. Nothing was written."
      if [[ "$MODE" == "dry-run" ]]; then
        mark_phase "inject_outcome_field" "WARN" "$_okg_msg NOT blocking under --dry-run (nothing is committed, so no record can be corrupted here); this same condition FAILS the close at --apply"
        return 0
      fi
      mark_phase "inject_outcome_field" "FAIL" "$_okg_msg"
      return 3
      ;;
  esac

  if [[ "$MODE" == "dry-run" ]]; then
    local _r=""
    [[ -n "$OUTCOME_RATIONALE" ]] && _r=" + **Outcome rationale:** $OUTCOME_RATIONALE"
    mark_phase "inject_outcome_field" "DRY-RUN" "would inject '**Outcome:** $outcome'${_r} after **Result:** in the $VERSION Deployment Log block ($target_name)"
    return 0
  fi

  # In-place edit: within the v<X.Y> Deployment-Log block, insert the Outcome
  # line(s) immediately after the first `**Result:**` line. Bounded to the block
  # (next `#### ` heading or EOF) so a later release's `**Result:**` is untouched.
  # The mechanics live in the shared _insert_field_after_in_block primitive —
  # phase 6.6 writes into the same block against a different anchor, and two
  # copies of a block-bounded insert would be two chances to drift.
  local _inject=( "**Outcome:** $outcome" )
  [[ -n "$OUTCOME_RATIONALE" ]] && _inject+=( "**Outcome rationale:** $OUTCOME_RATIONALE" )
  local _irc=0
  _insert_field_after_in_block "$target_log" "$VERSION" '**Result:**' "${_inject[@]}" || _irc=$?
  if [[ $_irc -ne 0 ]]; then
    mark_phase "inject_outcome_field" "FAIL" "could not inject **Outcome:** into the $VERSION Deployment Log block (block or **Result:** line not found in $target_name; searched: $_surfaces)"
    return 3
  fi

  # The write landed. If it landed in an archive segment rather than the hot
  # ledger, register it for staging (#4710) — files=() names only the ledger.
  _record_touched_archive_segment "$target_log"

  local _detail="injected **Outcome:** $outcome after **Result:** in the $VERSION Deployment Log block ($target_name)"
  [[ -n "$OUTCOME_RATIONALE" ]] && _detail="$_detail (+ **Outcome rationale:**)"
  mark_phase "inject_outcome_field" "PASS" "$_detail"
  return 0
}

# ─── Phase 6.6: inject_velocity_field (stage-13-close.md § Phase B-velocity) ──
#
# Emits the `**Velocity:**` field into the version's Deployment Log block,
# immediately after `**Cycle-Time:**` — the field order
# `Timestamp -> Cycle-Time -> Velocity -> Result -> Outcome` that
# release-velocity-tracking.md § 3.3 fixes. Both are machine-computed instrument
# fields; keeping them adjacent and ahead of the prose-and-verdict fields is the
# "instruments first, narrative last" reading order.
#
# WHY THIS PHASE EXISTS. stage-13-close.md has mandated this field since the
# velocity instrument shipped, and until now the mandate had no mechanism: the
# field was a human's memory, hand-added in a follow-up commit AFTER this
# script's own chore commit. It landed on some releases and not others, and a
# miss is invisible until somebody reads the ledger.
#
# THREE PROPERTIES THIS PHASE OWES. Each has a naive implementation that still
# exits 0, which is why each is stated rather than assumed:
#
#  (1) THE RIGHT SURFACE. The write target is resolved through
#      _resolve_deployment_log_target, exactly as phase 6.5 resolves its own. A
#      `$RELEASE_LOG`-hardcoded write on an ARCHIVED release puts the field in
#      the hot STUB while `**Result:**` and `**Outcome:**` sit in the segment.
#      That split record exits 0 AND parses under the shipped consumer grammar
#      — presence and grammar checks both pass on a broken record, so neither
#      is a sufficient observable. The idempotency probe reads the SAME resolved
#      surface: a hot-scoped probe paired with a resolved write reads zero on an
#      archived release and injects a SECOND copy into the segment, trading a
#      loud failure for a silent duplication inside an archived record.
#
#  (2) A REAL VALUE OR AN HONEST N/A — NEVER A PLAUSIBLE ONE. The value comes
#      from compute-release-velocity.sh, captured with the sentinel idiom. A
#      `$( )` capture can return EMPTY at exit 0 where an inline computation
#      could not, and an unguarded capture then writes `**Velocity:** ` with
#      nothing after it and returns 0. Emptiness is therefore tested on the
#      WHITESPACE-STRIPPED capture — a producer that emitted only a newline
#      otherwise reads as non-empty. Same rule emit_derived_entry owns for the
#      projector, created for the same shape of failure.
#
#  (3) A FIELD THE SHIPPED CONSUMER CAN ACTUALLY READ. The velocity accessor in
#      core/skills/finops-usage-extractor/scripts/estimate-usage.sh requires
#      UNBOLDED `planned <N> pts` AND `class <release-class>`; a row that bolds
#      its numerals (`planned **28** pts`) is dropped as `unkeyable` with no
#      diagnostic anywhere. Two such rows exist in the corpus today, both
#      hand-authored, and nothing told their authors. The conformance
#      self-assert rejects a non-conformant line AT EMIT TIME rather than
#      shipping a field that reads fine to a human and parses to nothing.
#      Prevention only — this phase never rewrites a field it did not author.

# Conformance predicate for a composed `**Velocity:**` line, expressed against
# the SHIPPED consumer grammar rather than a second one written here. The two
# regexes below are byte-identical to the accessor's own
# `match(line, /planned [0-9]+ pts/)` and `match(line, /class [a-z][a-z-]*/)`;
# a producer and its consumer encoding the same token shape twice is the drift
# seam this predicate exists to close.
# Returns 0 conformant, 1 non-conformant.
_velocity_line_conformant() {
  local _l="$1"
  # The sanctioned "cannot derive" emit. Anchored, so a narrative line that
  # merely mentions N/A later does not qualify.
  if /usr/bin/printf '%s\n' "$_l" | /usr/bin/grep -qE '^\*\*Velocity:\*\* N/A([^A-Za-z0-9]|$)'; then
    return 0
  fi
  /usr/bin/printf '%s\n' "$_l" | /usr/bin/grep -qE 'planned [0-9]+ pts' || return 1
  /usr/bin/printf '%s\n' "$_l" | /usr/bin/grep -qE 'class [a-z][a-z-]*'  || return 1
  return 0
}

phase_inject_velocity_field() {
  # LOOKUP SITE 1 of 2 — resolve which surface holds this version's block body,
  # before anything else. Both the idempotency probe and the write consume this
  # ONE answer, so they can never disagree about which file they mean.
  local target_log _surfaces
  target_log="$(_resolve_deployment_log_target "$VERSION" || true)"
  _surfaces="$(_deployment_log_surfaces_desc)"

  if [[ -z "$target_log" ]]; then
    # Near-unreachable in the sequenced runner: phase 6.5 hard-FAILs on this
    # exact condition immediately before. Implemented anyway — the phase has to
    # be correct when driven standalone (the self-test does precisely that), and
    # a guard whose correctness depends on its caller is not a guard.
    if [[ "$MODE" == "dry-run" ]]; then
      mark_phase "inject_velocity_field" "DRY-RUN" "would FAIL: no **Result:** line in the $VERSION Deployment Log block on any surface, so the write target is unresolvable (searched: $_surfaces)"
      return 0
    fi
    mark_phase "inject_velocity_field" "FAIL" "write target unresolvable — no **Result:** line in the $VERSION Deployment Log block on any surface (searched: $_surfaces)"
    return 3
  fi
  local target_name; target_name="$(/usr/bin/basename "$target_log")"

  # LOOKUP SITE 2 of 2 — idempotent, block-scoped, ON THE RESOLVED SURFACE.
  if /usr/bin/awk -v ver="$VERSION" '
      { line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line) }
      line == "#### Deployment Log " ver { inblk = 1; next }
      inblk && line ~ /^#### / { inblk = 0 }
      inblk && line ~ /^\*\*Velocity:\*\*/ { found = 1 }
      END { exit(found ? 0 : 1) }
    ' "$target_log" 2>/dev/null; then
    # Present is present — this phase does not overwrite a field it did not
    # author, and a historical backfill is a separate, operator-gated concern.
    # But a SILENT skip over a non-conformant field is how the two unparseable
    # rows in the corpus stayed invisible, so the skip carries the diagnostic.
    local _existing
    _existing="$(/usr/bin/awk -v ver="$VERSION" '
        { line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line) }
        line == "#### Deployment Log " ver { inblk = 1; next }
        inblk && line ~ /^#### / { inblk = 0 }
        inblk && line ~ /^\*\*Velocity:\*\*/ && !done { print line; done = 1 }
      ' "$target_log" 2>/dev/null || true)"
    local _skip="**Velocity:** already present in the $VERSION Deployment Log block ($target_name)"
    if ! _velocity_line_conformant "$_existing"; then
      _skip="$_skip — WARNING: the existing field is NOT readable by the shipped velocity consumer (it needs unbolded 'planned <N> pts' AND 'class <release-class>', or an 'N/A' field): '$_existing'. Left exactly as authored; correcting a historical row is a separate, operator-gated change."
    fi
    mark_phase "inject_velocity_field" "SKIPPED" "$_skip"
    return 0
  fi

  # ── Value. Resolved BEFORE the dry-run branch, so a dry run prints the exact
  # bytes --apply will write — including an N/A degrade or a conformance
  # failure. A dry run that renders a PREDICTED string is a green rehearsal for
  # a red run.
  # Declared on BOTH branches — the file runs under `set -u`, so a note set only
  # inside the else would be an unbound-variable crash on the unavailable-tool path.
  local _line _vnote=""
  if [[ ! -x "$COMPUTE_VELOCITY" ]]; then
    _line="**Velocity:** N/A — compute-release-velocity.sh unavailable or returned no value"
  else
    local _cv_args=( "$VERSION" --milestone "$MILESTONE" )
    [[ -n "$MERGE_SHA" ]] && _cv_args+=( --merge-sha "$MERGE_SHA" )
    # Sentinel-preserved capture with explicit status propagation — the
    # emit_derived_entry idiom, for the same two reasons: `$( )` strips trailing
    # newlines, and `$?` after a pipeline reports the wrong command's status.
    # stderr is CAPTURED, not discarded. The producer's diagnostics are the only
    # channel that carries an exit-2 reason or a degraded Phase-A2 planned-recovery
    # notice, and a phase that throws them away can only ever report "no value".
    local _out _rc=0 _errf
    _errf="$(/usr/bin/mktemp -t velocity-stderr.XXXXXX)"
    _out="$("$COMPUTE_VELOCITY" "${_cv_args[@]}" 2>"$_errf"; _prc=$?; /usr/bin/printf 'X'; exit "$_prc")" || _rc=$?
    _out="${_out%X}"
    local _err
    _err="$(/usr/bin/head -c 800 "$_errf" 2>/dev/null | /usr/bin/tr '\n' ' ' || true)"
    /bin/rm -f "$_errf" 2>/dev/null || true

    # Exit 2 is the producer's source-integrity / implausible-measurement
    # contract, and it must NOT fall through to the N/A degrade below. An N/A
    # would record "this release could not be measured" for a release the tool
    # measured fine and found WRONG — trading a loud refusal for a quiet
    # permanent row, which is the exact trade this phase exists to stop making.
    # Dry-run/apply posture per the release-wide ruling: non-blocking WARN under
    # --dry-run, fatal at --apply.
    if [[ "$_rc" -eq 2 ]]; then
      local _v2="compute-release-velocity.sh REFUSED the measurement (exit 2) for the $VERSION **Velocity:** field: ${_err:-<the producer wrote nothing to stderr>}"
      if [[ "$MODE" == "dry-run" ]]; then
        mark_phase "inject_velocity_field" "WARN" "$_v2 — NOT blocking under --dry-run (nothing is committed, so no record can be corrupted here); this same condition FAILS the close at --apply"
        return 0
      fi
      mark_phase "inject_velocity_field" "FAIL" "$_v2"
      return 3
    fi

    local _stripped
    _stripped="$(/usr/bin/printf '%s' "$_out" | /usr/bin/tr -d '[:space:]')"
    if [[ "$_rc" -ne 0 || -z "$_stripped" ]]; then
      # Exit-0-with-empty-stdout is a real failure mode of a captured producer
      # and is NOT covered by an exit-code check. Degrade to an explicit,
      # readable N/A. Never invent a value.
      _line="**Velocity:** N/A — compute-release-velocity.sh unavailable or returned no value"
    else
      # The field is ONE line by contract (release-velocity-tracking.md § 3.3).
      # Take the first; a producer that emitted more is caught by the
      # conformance assert below rather than smuggled into the ledger.
      _line="**Velocity:** ${_out%%$'\n'*}"
      # A successful run can still have something to say — most importantly that
      # the Phase-A2 planned-recovery DEGRADED, which silently under-reports
      # planned. It cannot go in the field (the consumer grammar is fixed), so it
      # rides the phase detail into the run report, where the operator reads it.
      if [[ -n "$_err" ]]; then _vnote=" [producer stderr: ${_err}]"; fi
    fi
  fi

  # ── Conformance self-assert, BEFORE any write.
  if ! _velocity_line_conformant "$_line"; then
    local _why="carries neither an unbolded 'planned <N> pts' with a 'class <release-class>' nor an 'N/A' field"
    if /usr/bin/printf '%s\n' "$_line" | /usr/bin/grep -qE 'planned \*\*[0-9]+\*\* pts'; then
      _why="bolds its numerals ('planned **<N>** pts') — emphasis inside the numeral makes the field unreadable to the shipped velocity consumer, which matches an UNBOLDED 'planned <N> pts'"
    fi
    if [[ "$MODE" == "dry-run" ]]; then
      mark_phase "inject_velocity_field" "DRY-RUN" "would FAIL: the composed **Velocity:** field is not consumer-parseable — it $_why: '$_line'"
      return 0
    fi
    mark_phase "inject_velocity_field" "FAIL" "the composed **Velocity:** field is not consumer-parseable — it $_why: '$_line'"
    return 3
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "inject_velocity_field" "DRY-RUN" "would insert '$_line' after **Cycle-Time:** in the $VERSION Deployment Log block ($target_name)${_vnote}"
    return 0
  fi

  # ── Insert after `**Cycle-Time:**`, falling back to the block heading when
  # the block carries no Cycle-Time field yet (exit 4 = block present, anchor
  # absent — distinguishable from exit 3 = block absent, which stays fatal).
  local _irc=0 _anchor_desc="after **Cycle-Time:**"
  _insert_field_after_in_block "$target_log" "$VERSION" '**Cycle-Time:**' "$_line" || _irc=$?
  if [[ "$_irc" -eq 4 ]]; then
    _irc=0
    _anchor_desc="after the block heading (the block carries no **Cycle-Time:** field)"
    _insert_field_after_in_block "$target_log" "$VERSION" "#### Deployment Log $VERSION" "$_line" || _irc=$?
  fi
  if [[ "$_irc" -ne 0 ]]; then
    mark_phase "inject_velocity_field" "FAIL" "could not insert **Velocity:** into the $VERSION Deployment Log block (block not found in $target_name; searched: $_surfaces)"
    return 3
  fi

  # Same registration as phase 6.5 — this phase resolves the same target and is
  # subject to the same staging omission (#4710).
  _record_touched_archive_segment "$target_log"

  mark_phase "inject_velocity_field" "PASS" "injected '$_line' $_anchor_desc in the $VERSION Deployment Log block ($target_name)${_vnote}"
  return 0
}

# ─── Phase 6.7: append_release_learnings (stage-13-close.md § Phase A7) ───────
#
# Appends the sibling H4 `#### Release Learnings v<X.Y>` block immediately after
# the version's `#### Deployment Log v<X.Y>` block.
#
# THE TARGET IS `$RELEASE_LOG`, UNCONDITIONALLY. It does NOT go through
# _resolve_deployment_log_target, and that asymmetry with phase 6.6 is the whole
# point rather than an oversight: the two block artifacts sit in DIFFERENT
# records classes. release/tools/sweep-release-corpus.py declares
# SWEEP_CLASS = "Deployment Log" and KEEP_CLASS = "Release Learnings", and
# core/governance/RECORDS_POLICY.md ratifies the split. A Release Learnings
# block is NEVER relocated — heading and body stay in the hot ledger at every
# archival window — because its named consumer degrades to a legitimate "no
# novel learning this release" sentinel at exit zero when the body is absent. A
# register reading a swept learnings block would assert there WERE no learnings
# rather than that the learnings moved.
#
# Resolving this write would therefore be a records-policy VIOLATION, not a
# style difference: on an archived release it would place the learnings block
# inside a segment the policy forbids it to enter. A single uniform strategy for
# both artifacts is wrong in one direction or the other, and it is wrong
# precisely on archived releases.
#
# The anchor is the `#### Deployment Log <V>` HEADING in the hot ledger, which
# is always present: the sweep retains every heading plus an `_Archived:_`
# pointer, so no archived block lacks a hot counterpart to anchor on.
phase_append_release_learnings() {
  local _log_name; _log_name="$(/usr/bin/basename "$RELEASE_LOG")"

  # ── Anchor presence in the HOT ledger.
  if ! /usr/bin/awk -v ver="$VERSION" '
      { line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line) }
      line == "#### Deployment Log " ver { found = 1 }
      END { exit(found ? 0 : 1) }
    ' "$RELEASE_LOG" 2>/dev/null; then
    if [[ "$MODE" == "dry-run" ]]; then
      mark_phase "append_release_learnings" "DRY-RUN" "would FAIL: no '#### Deployment Log $VERSION' heading in $_log_name to anchor the sibling block on"
      return 0
    fi
    mark_phase "append_release_learnings" "FAIL" "no '#### Deployment Log $VERSION' heading in $_log_name — the Release Learnings block is a SIBLING of that heading and has nothing to anchor on"
    return 3
  fi

  # ── Idempotency, expressed as PLACEMENT rather than presence. A bare presence
  # grep would also be satisfied by a learnings block sitting somewhere else in
  # the ledger entirely, and would then skip a genuine placement defect.
  # The probe itself lives in _learnings_block_placed, which the Phase-2 preflight
  # gate calls too — ONE definition, so the gate and this backstop cannot disagree
  # about whether the block is already placed.
  if _learnings_block_placed; then
    mark_phase "append_release_learnings" "SKIPPED" "'#### Release Learnings $VERSION' is already the sibling H4 after the $VERSION Deployment Log block ($_log_name)"
    return 0
  fi

  # ── Render. Never hand-composed: synthesize-release-learnings.sh owns the
  # block's shape AND its source-events accounting, and a second composer here
  # would be a second writer of a fact that already has one.
  if [[ ! -x "$SYNTHESIZE_LEARNINGS" ]]; then
    # EMIT ON ABSENCE (#5288). The refusal to hand-compose the block stands —
    # this phase still writes no learnings block. What changes is that the
    # absence stops being silent: a `**Not-produced:**` marker records it as
    # corpus bytes rather than as a SKIPPED row in an ephemeral run report.
    # The marker is EVIDENCE, not an exemption: `learnings-block` is a required
    # member of the Step-4 output-set manifest, so phase 9.56 still BLOCKS the
    # close on it. The marker says WHY, it does not say "allowed".
    # Called DIRECTLY, never in a command substitution: the writer records the
    # resolved surface into TOUCHED_ARCHIVE_SEGMENTS, and `$( )` would run it in
    # a subshell that discards the append. The bytes come back through
    # NOT_PRODUCED_MARKER_LINE instead. The `|| _lrc=$?` is unchanged and still
    # the tolerance boundary — it also keeps `set -e` disabled for the whole
    # call, exactly as the subshell did.
    local _lm _lrc=0
    _write_not_produced_marker "learnings-block" "append_release_learnings" \
            "synthesize-release-learnings.sh not executable at $SYNTHESIZE_LEARNINGS, so the $VERSION learnings block could not be rendered; hand-composing one would fabricate the source-events accounting the block exists to carry" >/dev/null || _lrc=$?
    _lm="$NOT_PRODUCED_MARKER_LINE"
    local _lnote="Absence RECORDED in the $VERSION Deployment Log block: '$_lm'"
    [[ "$MODE" == "dry-run" ]] && _lnote="Absence WOULD be recorded in the $VERSION Deployment Log block: '$_lm'"
    [[ "$_lrc" -ne 0 ]] && _lnote="Absence could NOT be recorded — no resolvable Deployment Log block to carry the marker. The absence itself still blocks at phase 9.56"
    mark_phase "append_release_learnings" "SKIPPED" "synthesize-release-learnings.sh not executable — cannot render the $VERSION learnings block. $_lnote. This does NOT exempt the output: learnings-block is a required member of the close-out output set and phase 9.56 blocks the close on it"
    return 0
  fi

  local _render _rc=0
  _render="$("$SYNTHESIZE_LEARNINGS" --mode per-release --version "$VERSION" 2>/dev/null; _prc=$?; /usr/bin/printf 'X'; exit "$_prc")" || _rc=$?
  # Sentinel-preserved capture, and the explicit `exit "$_prc"` propagates the
  # PRODUCER's status rather than printf's. The sentinel keeps the render's own
  # trailing newlines rather than letting `$( )` eat them, so the structural
  # assert below and the dry-run preview both see the producer's exact bytes.
  # NOTE on why the block's separation does NOT depend on this: the insert below
  # normalises separation itself (rstrip + one explicit blank line either side),
  # so a producer that forgot its trailing newline still lands correctly. That
  # is deliberate — trusting a producer to terminate its own block is a weaker
  # guarantee than establishing the separation at the insert site.
  _render="${_render%X}"
  local _rstripped
  _rstripped="$(/usr/bin/printf '%s' "$_render" | /usr/bin/tr -d '[:space:]')"
  if [[ "$_rc" -ne 0 ]] || [[ -z "$_rstripped" ]]; then
    local _rwhy="exited $_rc"
    [[ "$_rc" -eq 0 ]] && _rwhy="exited 0 with an EMPTY render (whitespace-only stdout) — refusing to append a blank block"
    if [[ "$MODE" == "dry-run" ]]; then
      mark_phase "append_release_learnings" "DRY-RUN" "would FAIL: synthesize-release-learnings.sh --mode per-release --version $VERSION $_rwhy"
      return 0
    fi
    mark_phase "append_release_learnings" "FAIL" "synthesize-release-learnings.sh --mode per-release --version $VERSION $_rwhy"
    return 3
  fi

  # ── Structural self-assert on the render, before it becomes corpus bytes.
  local _missing="" _f
  /usr/bin/printf '%s\n' "$_render" | /usr/bin/grep -qxF "#### Release Learnings $VERSION" || _missing="the '#### Release Learnings $VERSION' heading; "
  for _f in 'Synthesized at' 'Source events' 'Source-row anchors' 'Surprise' 'Would-change' 'Watch-for'; do
    /usr/bin/printf '%s\n' "$_render" | /usr/bin/grep -qE "^\*\*${_f}:\*\*" || _missing="${_missing}**${_f}:** ; "
  done
  if [[ -n "$_missing" ]]; then
    if [[ "$MODE" == "dry-run" ]]; then
      mark_phase "append_release_learnings" "DRY-RUN" "would FAIL: the rendered $VERSION learnings block is missing ${_missing%; }"
      return 0
    fi
    mark_phase "append_release_learnings" "FAIL" "the rendered $VERSION learnings block is missing ${_missing%; } — refusing to append a structurally incomplete block"
    return 3
  fi

  # ── D-1 = BLOCK (operator-decided). A render whose source-event count is ZERO
  # is the synthesizer's honest "nothing was captured" sentinel, not a learning.
  # Appending it writes "no novel learning this release" into a permanent record
  # when the truth is that the `release-synthesis/learnings-triple` row was never
  # captured — an assertion about the release the evidence does not support, and
  # one that reads identically to a release that genuinely had no learning.
  #
  # stage-13-close.md already ratifies the shape of this call one layer down:
  # "a projected entry that never reaches its file is a close-out FAILURE." The
  # same proposition applies to an entry produced empty rather than dropped.
  # The remedy is mechanical and belongs BEFORE the close, not during it.
  if /usr/bin/printf '%s\n' "$_render" | /usr/bin/grep -qE '^\*\*Source events:\*\* 0([^0-9]|$)'; then
    # Same string the Phase-2 preflight gate prints — ONE definition, so an
    # operator who hits either site is handed the identical command.
    local _remedy; _remedy="$(_learnings_capture_remedy)"
    if [[ "$MODE" == "dry-run" ]]; then
      mark_phase "append_release_learnings" "DRY-RUN" "would FAIL: the $VERSION learnings render reports 0 source events — the release-synthesis/learnings-triple row was never captured, so the block would record 'no novel learning this release' as a fact rather than as an absence of evidence. Remedy: $_remedy"
      return 0
    fi
    mark_phase "append_release_learnings" "FAIL" "the $VERSION learnings render reports 0 source events — the release-synthesis/learnings-triple row was never captured, so appending would record 'no novel learning this release' as a fact rather than as an absence of evidence. Remedy: $_remedy"
    return 3
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "append_release_learnings" "DRY-RUN" "would append the '#### Release Learnings $VERSION' sibling H4 immediately after the $VERSION Deployment Log block ($_log_name)"
    return 0
  fi

  # ── Insert: sibling H4 immediately after the Deployment Log block, one blank
  # line either side. Trailing blank lines already inside the block are absorbed
  # rather than doubled.
  local _arc=0
  /usr/bin/python3 - "$RELEASE_LOG" "$VERSION" "$_render" <<'PY' || _arc=$?
import os
import sys
log_path, version, render = sys.argv[1:4]
log_name = os.path.basename(log_path)
with open(log_path, "r", encoding="utf-8") as f:
    lines = f.read().splitlines()

block_hdr = f"#### Deployment Log {version}"
start = None
for i, line in enumerate(lines):
    if line.strip() == block_hdr:
        start = i
        break
if start is None:
    print(f"ERROR: Deployment Log block for {version} not found in {log_name}", file=sys.stderr)
    sys.exit(3)

# Block end = next `#### ` heading after start, or EOF.
end = len(lines)
for j in range(start + 1, len(lines)):
    if lines[j].startswith("#### "):
        end = j
        break

# Separation is established HERE, not inherited from the producer. Blank lines
# already trailing inside the block are ABSORBED (ins walks back past them) and
# the tail resumes at the original block end, so those absorbed blanks are not
# re-emitted after the insert. Getting this wrong yields a doubled blank line
# after the block — which renders identically in most viewers and is invisible
# to every presence check, so the self-test asserts the exact count on both
# sides rather than the block's mere existence.
ins = end
while ins > start + 1 and lines[ins - 1].strip() == "":
    ins -= 1

render_lines = render.rstrip("\n").split("\n")
tail = lines[end:]
out = lines[:ins] + [""] + render_lines + ([""] + tail if tail else [])
with open(log_path, "w", encoding="utf-8") as f:
    f.write("\n".join(out) + "\n")
PY
  if [[ "$_arc" -ne 0 ]]; then
    mark_phase "append_release_learnings" "FAIL" "could not append the '#### Release Learnings $VERSION' block after the $VERSION Deployment Log block in $_log_name"
    return 3
  fi

  mark_phase "append_release_learnings" "PASS" "appended the '#### Release Learnings $VERSION' sibling H4 immediately after the $VERSION Deployment Log block ($_log_name)"
  return 0
}

# ─── Phase 6.8: inject_close_class_telemetry_field (close-class-telemetry.md) ──
#
# Emits the `**Close-Class-Telemetry:**` field into the version's Deployment Log
# block, after `**Outcome rationale:**` (falling back to `**Outcome:**`) — the
# close-quality read-model sits BELOW the verdict fields it summarises, which is
# why this phase is seated after 6.5 rather than beside the instrument fields.
#
# WHY THIS PHASE EXISTS. close-class-telemetry.md § 3.2 has mandated this field
# on every post-cutover release since the standard merged, and until now the
# mandate had no mechanism: no close-out phase produced it and no check asserted
# it. Zero of the ~30 post-cutover releases that closed carried it; the two rows
# that do were hand-emitted, and the more recent of those records the mandated
# tool ABORTING rather than a value. That is the same producer/gate gap #4329
# records for `**Velocity:**` — a codified field with no writer.
#
# THREE PROPERTIES THIS PHASE OWES.
#
#  (1) THE RIGHT SURFACE. Resolved through _resolve_deployment_log_target,
#      exactly as 6.5 and 6.6 resolve theirs, and the idempotency probe reads
#      that SAME resolved answer. A `$RELEASE_LOG`-hardcoded write on an ARCHIVED
#      release splits the record across two files at exit 0, and both a
#      corpus-wide grep and the field grammar read identical on the split.
#
#  (2) A MEASURED VALUE OR NOTHING — NEVER A PLAUSIBLE ONE. The value comes from
#      compute-close-class-telemetry.sh and from nowhere else. If that tool is
#      absent or non-executable this phase SKIPs rather than composing a field:
#      the field carries a literal `mechanism: compute-close-class-telemetry.sh`
#      claim, so writing one the mechanism did not produce would be precisely the
#      declaration-vs-behaviour divergence the field exists to measure. (The
#      corpus already records a release that refused to hand-fill it for exactly
#      this reason; that judgement is encoded here rather than left to the next
#      operator's memory.)
#
#      The tool's exit contract, stated against its MEASURED behaviour and relied
#      on here: 0 = success INCLUDING every degraded path (absent register,
#      unavailable gh, unresolvable repo each set an N/A reason and still emit a
#      conformant eight-slot line); 1 = argument validation ONLY; 2 = a register
#      that exists but is UNREADABLE — a source-integrity condition, escalated
#      rather than degraded. A CALLER CANNOT DISTINGUISH THE gh-LESS PATH BY EXIT
#      CODE and must not try: that disposition is readable only from the emitted
#      line, which is what the measuredness arm below reads.
#
#  (3) A FIELD THE SHIPPED CONSUMERS CAN READ, PLUS A VISIBLE DISPOSITION. Two
#      separate assertions, deliberately with two different severities:
#
#      GRAMMAR (fatal). The eight slots in order per § 3.2. A malformed field is
#      never written — the same prevention-only posture 6.6 takes.
#
#      MEASUREDNESS (diagnostic, NOT fatal). All four rate slots can be `N/A`
#      simultaneously on a lawful run: no gh degrades Indicators 3 and 6, no
#      register degrades 1 and 2, and those conditions co-occur. Such a line is
#      structurally perfect and asserts nothing. FAILING on it would convert a
#      degraded ENVIRONMENT into a close-out failure, so this phase writes the
#      field and says so in its own outcome detail instead. The gate-side twin
#      (deploy.sh Check 48 sub-check l-3a) is where the same reading IS a
#      finding — a gate may fail a row for carrying no measurement; a producer
#      may not refuse to record one honestly.

# Schema predicate for a composed `**Close-Class-Telemetry:**` line, expressed as
# ONE ordered pattern over the eight § 3.2 slots rather than eight independent
# presence tests: eight unordered tests accept a scrambled line, and the field's
# consumers read it positionally. `grep` reads a HERE-STRING, never `producer |
# grep -q`: under `set -euo pipefail` grep -q exits at the first match and
# SIGPIPEs the writer, so pipefail promotes a SUCCESSFUL match to a non-zero
# pipeline status and the assert silently inverts.
# Returns 0 conformant, 1 non-conformant.
_close_class_line_conformant() {
  local _l="$1"
  /usr/bin/grep -qE '^\*\*Close-Class-Telemetry:\*\* retro-conformance .+; lessons-population .+; carry-forward-closure .+; pattern-emergence .+; rollup-presence .+; evidence-preservation .+; evidence-close-gate .+; mechanism: .+$' <<<"$_l"
}

# Measuredness (anti-vacuity) predicate — a SUPPLEMENT to the schema predicate
# above, never a replacement. Schema conformance is satisfied by a line whose
# every rate slot reads `N/A`, which is a reachable and lawful emission; this
# predicate asks the different question of whether the line carries at least one
# COMPUTED ratio (`<n>/<d> (<r>)`). Note the property this does NOT have: its
# freedom from false positives is conditional on the cutover anchor admitting no
# pre-mechanism row, and it is asserted here as a diagnostic precisely because
# that condition is not something a producer can establish.
# Returns 0 measured, 1 vacuous.
_close_class_line_measured() {
  local _l="$1"
  /usr/bin/grep -qE '[0-9]+/[0-9]+ \([01]\.[0-9]{2}\)' <<<"$_l"
}

phase_inject_close_class_telemetry_field() {
  # LOOKUP SITE 1 of 2 — resolve the surface first; probe and write consume this
  # ONE answer so they cannot disagree about which file they mean.
  local target_log _surfaces
  target_log="$(_resolve_deployment_log_target "$VERSION" || true)"
  _surfaces="$(_deployment_log_surfaces_desc)"

  if [[ -z "$target_log" ]]; then
    # Near-unreachable in the sequenced runner (6.5 hard-FAILs on this exact
    # condition three phases earlier), implemented anyway: the phase has to be
    # correct when driven standalone, and a guard whose correctness depends on
    # its caller is not a guard.
    if [[ "$MODE" == "dry-run" ]]; then
      mark_phase "inject_close_class_telemetry_field" "DRY-RUN" "would FAIL: no **Result:** line in the $VERSION Deployment Log block on any surface, so the write target is unresolvable (searched: $_surfaces)"
      return 0
    fi
    mark_phase "inject_close_class_telemetry_field" "FAIL" "write target unresolvable — no **Result:** line in the $VERSION Deployment Log block on any surface (searched: $_surfaces)"
    return 3
  fi
  local target_name; target_name="$(/usr/bin/basename "$target_log")"

  # LOOKUP SITE 2 of 2 — idempotent, block-scoped, ON THE RESOLVED SURFACE.
  if /usr/bin/awk -v ver="$VERSION" '
      { line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line) }
      line == "#### Deployment Log " ver { inblk = 1; next }
      inblk && line ~ /^#### / { inblk = 0 }
      inblk && line ~ /^\*\*Close-Class-Telemetry:\*\*/ { found = 1 }
      END { exit(found ? 0 : 1) }
    ' "$target_log" 2>/dev/null; then
    mark_phase "inject_close_class_telemetry_field" "SKIPPED" "**Close-Class-Telemetry:** already present in the $VERSION Deployment Log block ($target_name)"
    return 0
  fi

  # ── Value. Resolved BEFORE the dry-run branch so a dry run prints the exact
  # bytes --apply will write. Under the Indicator-5 fix those bytes no longer
  # depend on anything an earlier phase in THIS run wrote, so dry-run and apply
  # resolve identically by construction rather than by convention.
  if [[ ! -x "$COMPUTE_CLOSE_CLASS_TELEMETRY" ]]; then
    # EMIT ON ABSENCE (#5288). Same shape as phase 6.7's capability arm: the
    # refusal to compose a field without its mechanism stands, and the absence
    # is recorded instead of dropped. `close-class-telemetry` is a
    # `required-if telemetry-cutover-armed` member of the output-set manifest —
    # the marker records the absence either way, and phase 9.56 blocks on it
    # only when that cutover is armed. The marker never decides that question.
    # Called DIRECTLY, never in a command substitution — same reason as phase
    # 6.7's site above: `$( )` is a subshell and the writer's
    # TOUCHED_ARCHIVE_SEGMENTS append would not survive it.
    local _tm _trc=0
    _write_not_produced_marker "close-class-telemetry" "inject_close_class_telemetry_field" \
            "compute-close-class-telemetry.sh not executable at $COMPUTE_CLOSE_CLASS_TELEMETRY, so no field was written; composing one without that mechanism would fabricate the claim the field exists to measure" >/dev/null || _trc=$?
    _tm="$NOT_PRODUCED_MARKER_LINE"
    local _tnote="Absence RECORDED in the $VERSION Deployment Log block: '$_tm'"
    [[ "$MODE" == "dry-run" ]] && _tnote="Absence WOULD be recorded in the $VERSION Deployment Log block: '$_tm'"
    [[ "$_trc" -ne 0 ]] && _tnote="Absence could NOT be recorded — no resolvable Deployment Log block to carry the marker"
    mark_phase "inject_close_class_telemetry_field" "SKIPPED" "compute-close-class-telemetry.sh not executable — no field written. The field asserts 'mechanism: compute-close-class-telemetry.sh'; composing one without that mechanism would fabricate the claim the field exists to measure. $_tnote"
    return 0
  fi

  local _cct_args=( "$VERSION" --milestone "$MILESTONE" )
  # Sentinel-preserved capture with explicit status propagation — the
  # emit_derived_entry / 6.6 idiom, for the same two reasons: `$( )` strips
  # trailing newlines, and `$?` after a pipeline reports the wrong status.
  local _out _rc=0
  _out="$("$COMPUTE_CLOSE_CLASS_TELEMETRY" "${_cct_args[@]}" 2>/dev/null; _prc=$?; /usr/bin/printf 'X'; exit "$_prc")" || _rc=$?
  _out="${_out%X}"
  local _stripped
  _stripped="$(/usr/bin/printf '%s' "$_out" | /usr/bin/tr -d '[:space:]')"

  if [[ "$_rc" -eq 2 ]]; then
    # Source integrity, not a degraded environment: a register that exists but
    # cannot be read. Escalate rather than record an N/A that would misreport a
    # permissions fault as an absent artifact.
    local _e2="compute-close-class-telemetry.sh exited 2 — a register exists but is UNREADABLE (source-integrity condition, not an absent register). No field written; fix the register's readability and re-run."
    if [[ "$MODE" == "dry-run" ]]; then
      mark_phase "inject_close_class_telemetry_field" "DRY-RUN" "would FAIL: $_e2"
      return 0
    fi
    mark_phase "inject_close_class_telemetry_field" "FAIL" "$_e2"
    return 3
  fi
  if [[ "$_rc" -ne 0 || -z "$_stripped" ]]; then
    # rc 1 is argument validation — a defect in THIS call site, not a condition
    # of the release. Exit-0-with-empty-stdout is a real failure mode of a
    # captured producer and is NOT covered by an exit-code check.
    local _e1="compute-close-class-telemetry.sh failed (exit $_rc) or returned no value — no field written. Exit 1 is argument validation, i.e. a defect in this invocation rather than a property of the release; every degraded environment (no gh, no register) exits 0 with an N/A-bearing line instead."
    if [[ "$MODE" == "dry-run" ]]; then
      mark_phase "inject_close_class_telemetry_field" "DRY-RUN" "would FAIL: $_e1"
      return 0
    fi
    mark_phase "inject_close_class_telemetry_field" "FAIL" "$_e1"
    return 3
  fi

  # The field is ONE line by contract (close-class-telemetry.md § 3.2). Take the
  # first; a producer that emitted more is caught by the grammar assert below
  # rather than smuggled into the ledger.
  local _line="**Close-Class-Telemetry:** ${_out%%$'\n'*}"

  # ── Grammar self-assert, BEFORE any write. FATAL.
  if ! _close_class_line_conformant "$_line"; then
    local _why="does not carry the eight § 3.2 slots in order (retro-conformance; lessons-population; carry-forward-closure; pattern-emergence; rollup-presence; evidence-preservation; evidence-close-gate; mechanism:)"
    if [[ "$MODE" == "dry-run" ]]; then
      mark_phase "inject_close_class_telemetry_field" "DRY-RUN" "would FAIL: the composed **Close-Class-Telemetry:** field is not schema-conformant — it $_why: '$_line'"
      return 0
    fi
    mark_phase "inject_close_class_telemetry_field" "FAIL" "the composed **Close-Class-Telemetry:** field is not schema-conformant — it $_why: '$_line'"
    return 3
  fi

  # ── Measuredness arm. DIAGNOSTIC, not fatal (see property 3 above). The
  # disposition is read from the emitted LINE because the exit code cannot carry
  # it — the tool exits 0 on the gh-less path exactly as it does on a fully
  # measured one.
  local _vac=""
  if ! _close_class_line_measured "$_line"; then
    _vac=" — WARNING: this field carries NO computed ratio (every rate slot resolved N/A), so it records that the release closed without a measurable close-quality reading rather than a reading itself."
    if /usr/bin/grep -qF 'gh unavailable' <<<"$_line"; then
      _vac="$_vac Disposition read from the emitted line: gh was unavailable, which degrades Indicators 3 and 6 together."
    fi
    if /usr/bin/grep -qF 'no retro register found' <<<"$_line"; then
      _vac="$_vac Disposition read from the emitted line: no retro register resolved, which degrades Indicators 1, 2 and 5 together."
    fi
    _vac="$_vac Written as measured — an honest N/A is the mandated form; deploy.sh Check 48 sub-check (l) is where the same reading becomes a finding."
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "inject_close_class_telemetry_field" "DRY-RUN" "would insert '$_line' after **Outcome rationale:** in the $VERSION Deployment Log block ($target_name)${_vac}"
    return 0
  fi

  # ── Insert after `**Outcome rationale:**`, falling back to `**Outcome:**` when
  # the block carries no rationale line. TWO live limbs, not more:
  # _resolve_deployment_log_target only resolves blocks carrying `**Result:**`,
  # and 6.5 has already placed `**Outcome:**` in the same block, so a third
  # fallback would be unreachable code.
  #
  # THE ANCHOR STRING IS RESOLVED FIRST, THROUGH THE SHARED KEY GRAMMAR (#4222),
  # and the resolved RAW prefix is what the primitive receives — so a qualified
  # key anchors exactly as a bare one does and `_insert_field_after_in_block`
  # keeps its exact-prefix semantics, signature and body UNCHANGED. Generalizing
  # the primitive's matcher instead would have reached all five of its call sites,
  # including phase 6.6's; resolving the string upstream reaches none of them.
  #
  # AN UNRESOLVED PREFIX IS NEVER PASSED THROUGH. `str.startswith("")` is True for
  # every string, so an EMPTY anchor matches the block's FIRST line: the
  # primitive's exit-4 "anchor absent" path becomes UNREACHABLE and the field
  # lands silently at the top of the block at exit 0 — a PASS verdict over a
  # misplaced audit field, which is this card's own failure signature. The
  # classifier emits an empty prefix ONLY for ABSENT, the class is branched on
  # BEFORE the prefix is read, and the literal canonical key is the floor. That
  # floor preserves the pre-fix loud exit-4 failure for a block that genuinely
  # carries no Outcome anchor rather than trading it for a silent misplacement.
  local _ckg_res _ckg_cls _ckg_pfx
  local _irc=0 _anchor="" _anchor_desc=""
  # ANCHORABLE CLASSES ARE AN ALLOWLIST, not "anything but ABSENT". Only a key
  # this grammar actually RECOGNIZED may become an anchor: an UNPARSEABLE key is
  # not a recognized field, a DUPLICATE block is already broken, and UNREADABLE
  # is a failed read. Each of those falls to the literal floor below and fails
  # loudly, which is the correct standalone behaviour and is also what makes the
  # grammar arm falsifiable — flipping _FIELD_KEY_QUALIFIER_RE must move BOTH
  # sites, and with the constant at its default the same key must be accepted at
  # NEITHER.
  _ckg_res="$(_resolve_field_key_in_block "$target_log" "$VERSION" 'Outcome rationale')"
  _ckg_cls="${_ckg_res%%$'\t'*}"; _ckg_pfx="${_ckg_res#*$'\t'}"
  if [[ ( "$_ckg_cls" == "CANONICAL" || "$_ckg_cls" == "QUALIFIED" ) && -n "$_ckg_pfx" ]]; then
    _anchor="$_ckg_pfx"; _anchor_desc="after **Outcome rationale:**"
  else
    _ckg_res="$(_resolve_field_key_in_block "$target_log" "$VERSION" 'Outcome')"
    _ckg_cls="${_ckg_res%%$'\t'*}"; _ckg_pfx="${_ckg_res#*$'\t'}"
    if [[ ( "$_ckg_cls" == "CANONICAL" || "$_ckg_cls" == "QUALIFIED" ) && -n "$_ckg_pfx" ]]; then
      _anchor="$_ckg_pfx"
      _anchor_desc="after **Outcome:** (the block carries no **Outcome rationale:** field)"
    fi
  fi
  if [[ -z "$_anchor" ]]; then
    _anchor='**Outcome:**'
    _anchor_desc="after **Outcome:** (the block carries no **Outcome rationale:** field)"
  fi
  _insert_field_after_in_block "$target_log" "$VERSION" "$_anchor" "$_line" || _irc=$?
  if [[ "$_irc" -ne 0 ]]; then
    mark_phase "inject_close_class_telemetry_field" "FAIL" "could not insert **Close-Class-Telemetry:** into the $VERSION Deployment Log block (block or **Outcome:** anchor not found in $target_name; searched: $_surfaces)"
    return 3
  fi

  # Same registration as 6.5/6.6 — this phase resolves the same target and is
  # subject to the same staging omission (#4710).
  _record_touched_archive_segment "$target_log"

  mark_phase "inject_close_class_telemetry_field" "PASS" "injected the **Close-Class-Telemetry:** field $_anchor_desc in the $VERSION Deployment Log block ($target_name): '$_line'${_vac}"
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

  # Date cell — MERGE anchor (#3718). Read from the RELEASE_LOG row for this
  # version, NOT sampled from the close-out clock. LOG and INDEX are the only
  # ledger pair carrying an automated cross-assertion
  # (generate_release_index.py --verify, invoked by deploy.sh Check 23, asserts
  # the INDEX row equals the LOG row field-for-field). While this phase sampled
  # the close-out clock, that check was red BY CONSTRUCTION on every close-out
  # that crossed a UTC midnight — it reported the design working correctly and
  # so could no longer report real drift. The close-out instant is not lost: it
  # is carried by DIGEST, the release note, and CHANGELOG, each declaring so.
  # Per core/standards/date-variable-convention.md § Emission-Time Anchors.
  #
  # Resolved BEFORE the dry-run branch so dry-run predicts exactly what --apply
  # writes, including the failure (#2539 AC-3 dry-run/apply parity). Preflight
  # already asserted the LOG row exists at DEPLOYED, so an unresolvable Date is
  # a real schema anomaly — fail loudly rather than silently substituting the
  # clock and re-opening the very divergence this phase now closes.
  local date_str
  date_str="$(extract_row_date "$(find_log_row "$VERSION")")"
  if [[ -z "$date_str" ]]; then
    mark_phase "append_release_index" "FAIL" "could not resolve the merge-anchored Date from the RELEASE_LOG row for $VERSION (expected a YYYY-MM-DD cell under the 'Date' header); refusing to substitute the close-out clock — see date-variable-convention.md § Emission-Time Anchors"
    return 3
  fi

  # PROJECT the row (#4455). Resolved BEFORE the dry-run branch so dry-run shows
  # the exact bytes --apply will write, including a failure — the same
  # dry-run/apply parity rule the Date resolution above follows. Content
  # synthesis now has exactly one owner; this phase owns only the INSERTION.
  # The `printf X` sentinel is required at EVERY capture site, not only inside
  # the helper: `$( )` strips trailing newlines at each nesting level, and the
  # CHANGELOG block's trailing blank line is load-bearing separation. Applying it
  # only once let two release entries run together on one line — caught by the
  # self-test limb below, not by reading the code.
  local new_row _emit_rc=0
  new_row="$(emit_derived_entry index; _erc=$?; /usr/bin/printf 'X'; exit "$_erc")" || _emit_rc=$?
  new_row="${new_row%X}"
  if [[ $_emit_rc -ne 0 ]]; then
    mark_phase "append_release_index" "FAIL" "release-corpus projector could not emit the INDEX row for $VERSION (exit $_emit_rc) — see the diagnostic above; refusing to insert an unprojected or empty row"
    return 3
  fi
  new_row="${new_row%$'\n'}"

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "append_release_index" "DRY-RUN" "would insert the projected 6-col row ($new_row) at the top of RELEASE_INDEX.md (Date = merge anchor, read from the RELEASE_LOG row)"
    return 0
  fi

  # Pure single-row insert in the 6-column schema. Insert immediately after the
  # first separator line (`|---`), keeping chronological-recent-first order.
  # Head-insert, NOT append: "chronological-recent-first" is a declared invariant
  # of RELEASE_INDEX.md, rendered into its own header prose and asserted by the
  # projector's verify() row-order limb.
  #
  # The row travels through ENVIRON rather than `awk -v`, which processes
  # backslash escapes in the value and would corrupt a Theme cell containing one.
  local _idx_tmp; _idx_tmp="$(/usr/bin/mktemp -t aco-index.XXXXXX)"
  NEW_ROW="$new_row" /usr/bin/awk '
    { print }
    !ins && /^\|---/ { print ENVIRON["NEW_ROW"]; ins=1 }
    END { if (!ins) print ENVIRON["NEW_ROW"] }
  ' "$RELEASE_INDEX" > "$_idx_tmp" && /bin/mv "$_idx_tmp" "$RELEASE_INDEX"

  mark_phase "append_release_index" "PASS" "inserted the projected 6-col row for $VERSION (Version | Milestone | Date | Theme | Release PR | Release Notes)"
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
# source: the H1 of the release note at notes_abs_path() minus the `# ` prefix (the
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

  # PROJECT the entry (#4455). Headline source (the note's `# ` H1, with the
  # operator placeholder when the note is absent) and the run-scoped CLOSE-OUT
  # anchor are both the projector's job now; this phase owns only the INSERTION.
  # Resolved BEFORE the dry-run branch so dry-run shows the exact bytes --apply
  # will write, including a failure.
  #
  # The note is normally ABSENT at this point — this phase runs before the note
  # is scaffolded — so the placeholder is the expected fresh-close path, not an
  # error. That is deliberately different from the CHANGELOG phase, which runs
  # after the scaffold and fails loudly on an absent note.
  # Sentinel-preserved capture — see phase_append_release_index for why.
  local new_entry _emit_rc=0
  new_entry="$(emit_derived_entry digest; _erc=$?; /usr/bin/printf 'X'; exit "$_erc")" || _emit_rc=$?
  new_entry="${new_entry%X}"
  if [[ $_emit_rc -ne 0 ]]; then
    mark_phase "append_release_digest" "FAIL" "release-corpus projector could not emit the DIGEST entry for $VERSION (exit $_emit_rc) — see the diagnostic above; refusing to insert an unprojected or empty entry"
    return 3
  fi
  new_entry="${new_entry%$'\n'}"

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "append_release_digest" "DRY-RUN" "would prepend the projected entry '$new_entry' under the topmost working H2 in RELEASE_DIGEST.md"
    return 0
  fi

  # Prepend the H3 entry under the topmost `## ` working H2 (the most-recent
  # entry sits immediately after the H2 + its blank line, above the current top
  # `### ` entry). No family-H2 search, no `### Releases` table scaffold.
  #
  # The awk below reproduces the prior insertion arithmetic exactly: print
  # through the first `## ` H2 and any blank lines immediately following it, then
  # the entry plus a blank, then the remainder. The two EOF branches are kept
  # distinct — H2-seen appends "entry, blank"; no-H2-at-all appends "blank,
  # entry" — because those were two different degraded paths and collapsing them
  # would change the bytes on a malformed corpus.
  local _dg_tmp; _dg_tmp="$(/usr/bin/mktemp -t aco-digest.XXXXXX)"
  NEW_ENTRY="$new_entry" /usr/bin/awk '
    {
      if (!ins && seen && $0 != "") { print ENVIRON["NEW_ENTRY"]; print ""; ins=1 }
      print
      if (!seen && substr($0,1,3) == "## ") seen=1
    }
    END {
      if (!ins) {
        if (seen) { print ENVIRON["NEW_ENTRY"]; print "" }
        else      { print ""; print ENVIRON["NEW_ENTRY"] }
      }
    }
  ' "$RELEASE_DIGEST" > "$_dg_tmp" && /bin/mv "$_dg_tmp" "$RELEASE_DIGEST"

  mark_phase "append_release_digest" "PASS" "prepended the projected '### $VERSION (date) — …' H3 under the topmost working H2"
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
  # CLOSE-OUT anchor, run-scoped (#3718) — one sample per close-out run.
  local date_str; date_str="$CLOSEOUT_ANCHOR_UTC"
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
  # PRODUCER/CONSUMER AGREEMENT (#3113 Records 2+3). This phase writes the file that
  # preflight (f) scans for residue and that the preflight (b) tolerance whitelists.
  # All three MUST name the same path, which is why all three resolve it through
  # notes_abs_path()/notes_rel_path() instead of retyping the version-less branch.
  local notes_path; notes_path="$(notes_abs_path)"

  if [[ -f "$notes_path" ]]; then
    mark_phase "scaffold_release_notes" "SKIPPED" "RELEASE_NOTES.md already present for $VERSION (preserving operator prose)"
    return 0
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "scaffold_release_notes" "DRY-RUN" "would scaffold $notes_path (frontmatter + section H2 placeholders per release-notes-standard.md Part 1 Template); operator MUST fill prose before chore-PR merge"
    return 0
  fi

  # CLOSE-OUT anchor, run-scoped (#3718). This frontmatter `date:` is ALSO the
  # source CHANGELOG derives its date from, so the two surfaces cannot disagree.
  local date_str
  date_str="$CLOSEOUT_ANCHOR_UTC"

  # A version-less note lands one level deeper (notes/_unversioned/). `cat >` does
  # not create the parent, so a corpus that has never held a version-less note would
  # fail the redirect outright. Idempotent and a no-op for the versioned path.
  /bin/mkdir -p "$(/usr/bin/dirname "$notes_path")"

  # Resolve the plan pointer into a local BEFORE the heredoc. A non-zero return
  # from inside an unquoted heredoc is invisible — the substitution simply expands
  # to whatever was printed and the write proceeds — so the unresolved branch has
  # to be observable out here to be noticeable at all.
  local plan_ref
  if ! plan_ref="$(plan_ref_for_emit)"; then
    printf 'NOTICE: no plan file resolves for %s at any documented home (plans/v<MAJOR>/, plans/_unversioned/, plans/ — see release/releases/plans/README.md § Disposition rule); writing the expected home annotated as unresolved. The note-content lint blocks this close one phase later.\n' "$VERSION" >&2
  fi

  /bin/cat > "$notes_path" <<EOF
---
version: ${VERSION}
date: ${date_str}
type: note
issues: []
pr: "#${PR_NUMBER}"
links:
  plan: ${plan_ref}
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
  # Repo-root-relative, because that is the form the lint prints in every finding.
  # Built from notes_rel_path() so a version-less release scopes to the note that
  # actually exists — a hand-typed flat path would be a needle nothing can match.
  local note_rel; note_rel="release/releases/$(notes_rel_path)"

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

# ─── Phase 9.3: lint_plan_identity (ADR-092 plan-file identity close gate) ────
#
# WHY A DEDICATED PHASE RATHER THAN A LIMB INSIDE check_note_content(). Homing a
# plan assertion inside the note-content check is reachable and INERT: Phase 9.2
# blocks on `grep -F "$note_rel"`, a `release/releases/notes/…` needle, and a
# finding naming a `release/releases/plans/…` path structurally cannot contain
# it — so the caller takes its explicit "no finding for THIS version" PASS branch
# and the close proceeds with the finding sitting unread in its own output.
# Measured before this phase was written; the arms PI-6/PI-7 below re-assert it.
# "Already blocking" is a property of a CALLER PLUS A PREDICATE, never of a
# function. Recorded here so the co-location is not re-proposed.
#
# TWO NEEDLES, ORed, AND THE SECOND ONE IS NOT OPTIONAL. The obvious needle is
# the plan's EXPECTED path. It reaches the placement limb — whose finding names
# that path by construction — and it reaches the two identity sub-cases where the
# offending file already sits there. It does NOT reach this card's canonical
# defect: a plan NAMED FOR THE WRONG VERSION emits its ACTUAL path, which is by
# definition not the expected one, and neither does PLAN-MAJOR-DIR-MISMATCH.
# Measured: 2 of 5 identity findings reachable on the path needle alone. The
# second needle is version-keyed and closes that gap directly, so the identity
# limb has a blocking predicate of its own rather than depending on the placement
# limb it absorbed. Arm PI-4 is the arm that distinguishes the two.
#
# ADVISORY LINES ARE FILTERED OUT BEFORE EITHER NEEDLE RUNS. The lint's plan
# advisories legitimately carry `release/releases/plans/…` paths (unlike the note
# advisories, which may not, per the lint's ADVISORY_PREFIX invariant 2). An
# advisory is by definition not a blocking finding, so letting one reach the
# needle would false-block a close on a known residual. Arm PI-8 asserts it.
phase_lint_plan_identity() {
  local lint_script="${REPO_ROOT}/core/deploy/tools/lint_release_corpus.py"

  # A version-less release claims no concrete Version cell, so both limbs are
  # structurally N/A. This branch is NOT where the version-less exclusion is
  # obtained — that is the Version-cell SHAPE classification inside the lint's
  # ledger parser, which is what makes the exclusion structural rather than a
  # special case. It is also not reachable through --apply/--dry-run (main
  # validates --version and dies first, per the REACHABILITY note above
  # is_version_less); it is kept and driven by --self-test arm PI-5 for the same
  # three reasons that note gives. The close gate for a version-less release is
  # the event-bound Step 4 command, not this phase — see stage-13-close.md Phase
  # A8.3, which binds plan-identity to the close EVENT across every close path.
  if is_version_less; then
    mark_phase "lint_plan_identity" "SKIP" "version-less release — no concrete Version cell to bind a plan filename to; the plan-identity close gate for this path is the Step 4 completion-verification command (stage-13-close.md Phase A8.3)"
    return 0
  fi

  # The EXPECTED home, repo-root-relative — the form the lint prints. Derived
  # from plan_rel_path_expected() rather than retyped, so this needle and the
  # emitters cannot express two different layouts.
  local plan_rel; plan_rel="$(plan_rel_path_expected)"
  # The version-keyed needle. Dots are escaped so `v4.28` cannot match `v4028`,
  # and both boundaries exclude digits and dots so `v4.2` does not match inside
  # `v4.28` and `v4.28` does not match inside `v14.28`.
  local v_esc; v_esc="$(printf '%s' "$VERSION" | /usr/bin/sed 's/\./\\./g')"
  local ver_needle="^PLAN-[A-Z-]+:.*[^0-9.]${v_esc}([^0-9.]|\$)"

  if [[ ! -f "$lint_script" ]]; then
    mark_phase "lint_plan_identity" "FAIL" "lint tooling missing: ${lint_script} — cannot enforce the ADR-092 plan-identity close gate"
    return 1
  fi
  if [[ ! -x "/usr/bin/python3" ]]; then
    mark_phase "lint_plan_identity" "FAIL" "/usr/bin/python3 not executable; cannot run the plan-identity lint"
    return 1
  fi

  local out exit_code=0
  out="$(/usr/bin/python3 "$lint_script" --check plan-identity 2>&1)" || exit_code=$?

  if [[ $exit_code -eq 3 ]]; then
    # Both slices read `$out` from a HERE-STRING rather than through a pipe.
    # `writer | head` is the SIGPIPE idiom: `head` stops reading at its line
    # budget, the writer's next write fails on the closed pipe, and `pipefail`
    # promotes THAT status to the pipeline's — so a successful slice can report
    # failure. Removing the pipe removes the hazard outright; this is the same
    # capture-then-read disposition 7b147ba0 applied to two claim-version
    # assertions, not a gate exemption. Effect is unchanged: `head` still slices
    # the same bytes, and a here-string is the safer writer besides (bash's
    # `echo` would mangle an `$out` beginning `-n`/`-e`).
    mark_phase "lint_plan_identity" "FAIL" "path-resolution failure (exit 3): $(/usr/bin/head -1 <<<"$out") — plan corpus unverifiable; close BLOCKED (fail-loud)"
    /usr/bin/head -20 <<<"$out" >&2
    return 1
  fi

  if [[ $exit_code -ne 0 ]]; then
    local blocking v_findings
    blocking="$(echo "$out" | /usr/bin/grep -v '^ADVISORY' || true)"
    v_findings="$(echo "$blocking" | /usr/bin/grep -F "$plan_rel" || true)"
    v_findings="${v_findings}$(echo "$blocking" | /usr/bin/grep -E "$ver_needle" || true)"
    if [[ -n "$v_findings" ]]; then
      mark_phase "lint_plan_identity" "FAIL" "ADR-092 plan-identity finding(s) for ${VERSION} — close BLOCKED (the release plan's filename or its nested home disagrees with the RELEASE_LOG row)"
      echo "$blocking" | /usr/bin/grep -F "$plan_rel" >&2 || true
      echo "$blocking" | /usr/bin/grep -E "$ver_needle" >&2 || true
      return 1
    fi
    # Findings exist but none for THIS release → pre-existing debt for another
    # version; do NOT block this close on it (audit-baseline discipline, the
    # same contract Phase 9.2 carries).
    local legacy_count
    legacy_count="$(echo "$blocking" | /usr/bin/grep -c . || true)"
    mark_phase "lint_plan_identity" "PASS" "no plan-identity finding for ${VERSION} (${legacy_count} pre-existing finding(s) for other versions — out of scope for this close)"
    return 0
  fi

  mark_phase "lint_plan_identity" "PASS" "plan-identity clean for ${VERSION} (filename and nested home agree with the RELEASE_LOG row)"
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
  local notes_path; notes_path="$(notes_abs_path)"
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

  # REPO_SLUG WELL-FORMEDNESS GATE. Unlike every other consumer of this value,
  # the block below persists it into a durable CHANGELOG Release URL rather than
  # passing it to a `gh` call that tolerates a non-resolving slug. The module-load
  # fallback is a bare repo name, which is NOT owner/repo-shaped and would ship a
  # permanently broken link — a plausible-looking wrong row, which is exactly the
  # class this phase's own `date:` accessor was changed to reject. Fail loudly,
  # BEFORE anything is written.
  if [[ "$REPO_SLUG" != */* || "$REPO_SLUG" == */*/* || "$REPO_SLUG" == /* || "$REPO_SLUG" == */ ]]; then
    mark_phase "append_changelog" "FAIL" \
      "REPO_SLUG '${REPO_SLUG}' is not owner/repo-shaped — set REPO_SLUG in the environment, or set operator_github + pmo_platform_repo_name in the operator config. Refusing to write a permanently broken Release URL into a durable CHANGELOG row"
    return 3
  fi

  # ASSERT AT --apply, PREDICT AT --dry-run (#4765 convention, swept here by #5268).
  # The projector capture below used to sit ABOVE this mode test, under a comment
  # claiming the ordering was deliberate — "resolved BEFORE the dry-run branch so
  # dry-run shows the exact bytes --apply will write, including the failure."
  # That comment (39284a2d, 2026-08-04) is a git ANCESTOR of the commit that
  # ratified the convention (da363fdd, #4765, 2026-08-09) and of the one that
  # applied it at 15.5 (6cb75e8e, #5142, 2026-08-10). It was never an exemption
  # from the rule; it is an unreconciled predecessor the two ratifying commits
  # never swept back over — which is why this was found third, separately, by a
  # different stage. Its stated benefit is also unreachable in the case that
  # matters: the projector reads the release note, and phase_scaffold_release_notes
  # deliberately writes none under --dry-run, so on a first close the pre-branch
  # capture showed not the apply bytes but a failure state --apply never enters.
  # Every --dry-run therefore aborted here, the runner exited 3, and no phase after
  # this one enumerated — the identical defect #4765 fixed at 9.55 and #5142 fixed
  # at 15.5, with the identical consequence for the dry-run review gate
  # stage-13-close.md Phase A8 mandates. The capture is correct and is kept
  # byte-for-byte; only its mode-blindness was the defect.
  #
  # The prediction is STATIC. It states what --apply will do; it does not
  # pre-evaluate any of it. Do NOT "improve" it by having the dry-run limb stat the
  # note or read a projector exit code — a dry-run that computes a result is the
  # mode-blindness defect wearing a different shape.
  #
  # ORDERING — this is 15.5's shape, NOT 9.55's literal-first-line shape. The four
  # guards above stay ABOVE the mode test on purpose. Three of them (version-less,
  # CHANGELOG-absent, idempotency) SKIP at --apply, so predicting "would prepend"
  # below them would be a FALSE prediction. The fourth (REPO_SLUG well-formedness)
  # reads a module-load value no phase writes, so it evaluates identically in both
  # modes, and surfacing a permanently broken Release URL at --dry-run is exactly
  # what --dry-run is for. The mode test belongs above the ONE statement whose input
  # a dry-run-no-op phase owns — the projector capture — and no higher.
  #
  # Residual, accepted and named: --dry-run no longer PREVIEWS a projector failure
  # in the resume case (a close re-run after the note landed but the CHANGELOG entry
  # did not). The gate loses nothing — the capture still runs at --apply, before
  # anything is inserted, and 9.55 assert_derived_surfaces remains the post-append
  # detector. What is lost is the preview, and only in that case.
  #
  # The detail carries no '|' (it would corrupt the RESULT|detail record and the
  # --markdown phase table) and no literal `would FAIL` (_output_set_dryrun_class
  # reads that token to classify a producer would-absent, and at --apply this phase
  # writes). Both constraints are asserted by the F-9.5-S-dry self-test arm.
  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "append_changelog" "DRY-RUN" "would prepend the projected ## [${VERSION}] section to CHANGELOG.md (summary sourced from ${notes_path} frontmatter per release-notes-standard.md § 5.3 transform). Not evaluated under --dry-run: the projector emission itself. Its input is the release note, which phase_scaffold_release_notes deliberately does not write under --dry-run, so resolving it here would only fail on this script's own no-op. The projection runs for real at --apply, after the note is scaffolded and before anything is inserted"
    return 0
  fi

  # PROJECT the block (#4455). The note's frontmatter `summary:` (with its silent
  # "(see release notes)" fallback) and the run-scoped CLOSE-OUT anchor are the
  # projector's job now; this phase owns only the INSERTION. An unresolvable note
  # is a LOUD failure at --apply — by then phase_scaffold_release_notes has run, so
  # an absent note is a real anomaly rather than an ordering artifact.
  # Sentinel-preserved capture. This is the site where losing it corrupts the
  # artifact: the emitted block ENDS with a blank line, and that blank line is
  # the separation between two release entries. See phase_append_release_index.
  local block _emit_rc=0
  block="$(emit_derived_entry changelog; _erc=$?; /usr/bin/printf 'X'; exit "$_erc")" || _emit_rc=$?
  block="${block%X}"
  if [[ $_emit_rc -ne 0 ]]; then
    mark_phase "append_changelog" "FAIL" "release-corpus projector could not emit the CHANGELOG block for $VERSION (exit $_emit_rc) — see the diagnostic above (release note unreadable or missing); refusing to insert an unprojected or empty block"
    return 3
  fi

  # Insertion point, Keep-a-Changelog 1.1.0 convention — the SAME three branches,
  # in the same precedence, as the heredoc this replaces:
  #   (a) `## [Unreleased]` present → insert at the start of the next `## ` H2;
  #       if there is no following H2, append at EOF VERBATIM (no reflow)
  #   (b) otherwise → insert before the first `## [vN…` entry
  #   (c) otherwise → trailing-whitespace-strip, blank line, then the block
  # The branch is chosen up front, not in-stream, so a `## [vN` line appearing
  # ABOVE Unreleased cannot win — that is what the original `if/elif` guaranteed.
  #
  # Insertion is a LINE SPLIT (head + block + tail) rather than a filter, because
  # the block's own bytes — including its trailing blank line, which is the
  # separation between two release entries — must pass through untouched. An
  # earlier filter-shaped version of this code lost exactly that blank line and
  # ran two entries together; it was caught by diffing against the original
  # implementation on four fixtures rather than by reading the code.
  local _cl_mode="eof" _ins_line=0
  if /usr/bin/grep -qE '^## \[Unreleased\]' "$changelog_path"; then
    _cl_mode="unreleased"
    _ins_line="$(/usr/bin/awk '
      seen && substr($0,1,3) == "## " { print NR; exit }
      /^## \[Unreleased\]/ { seen=1 }
    ' "$changelog_path")"
    _ins_line="${_ins_line:-0}"
  elif /usr/bin/grep -qE '^## \[?v[0-9]' "$changelog_path"; then
    _cl_mode="first-version"
    _ins_line="$(/usr/bin/awk '/^## \[?v[0-9]/ { print NR; exit }' "$changelog_path")"
    _ins_line="${_ins_line:-0}"
  fi

  local _cl_tmp; _cl_tmp="$(/usr/bin/mktemp -t aco-changelog.XXXXXX)"
  if [[ "$_ins_line" -gt 0 ]]; then
    { /usr/bin/head -n "$((_ins_line - 1))" "$changelog_path"
      /usr/bin/printf '%s' "$block"
      /usr/bin/tail -n "+${_ins_line}" "$changelog_path"; } > "$_cl_tmp"
  elif [[ "$_cl_mode" == "unreleased" ]]; then
    { /bin/cat "$changelog_path"; /usr/bin/printf '%s' "$block"; } > "$_cl_tmp"
  else
    { /usr/bin/awk 'BEGIN { RS="\1" } { sub(/[[:space:]]+$/, ""); printf "%s", $0 }' "$changelog_path"
      /usr/bin/printf '\n\n%s' "$block"; } > "$_cl_tmp"
  fi
  /bin/mv "$_cl_tmp" "$changelog_path"

  mark_phase "append_changelog" "PASS" "prepended the projected ## [${VERSION}] section to CHANGELOG.md (Surface 2 of Layer-1 dual-write)"
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
# safely.
#
# ASSERT AT --apply, PREDICT AT --dry-run (#4765). This phase used to run in BOTH
# modes, on the theory that a read-only check is always free to run early. It is not.
# The append phases at 8.x/9.5 deliberately write nothing under --dry-run, so by the
# time control reaches here BOTH slices are empty BY CONSTRUCTION, and the presence
# limb below fires on the script's own no-op. Since this phase returns 1 and the
# runner exits 3 on it, the FIRST dry-run of any release aborted right here and EVERY
# phase after it never enumerated — which made the dry-run review gate that
# stage-13-close.md Phase A8 mandates structurally unreachable for any release that
# had not already closed. The presence limb is correct and is kept; only its
# mode-blindness was the defect. So --dry-run PREDICTS the assertion and returns 0,
# and --apply runs it byte-for-byte unchanged.
#
# Residual, accepted and named: --dry-run no longer PREVIEWS a residue finding on an
# idempotent re-run (a close resumed after the entries already landed). The gate
# itself loses nothing — the assertion still runs at --apply at 9.55, which is BEFORE
# the chore commit at 9.95, so residue is still caught loud before anything is
# committed, and Checks 32 + 48 remain the corpus-wide detector. What is lost is the
# preview, and only in the re-run case. Do NOT "fix" that by moving the mode test
# down into the loop: the presence limb and the two N/A limbs below are co-tenanted
# and the mode test does not belong inside either.
#
# Version-less releases: CHANGELOG is SKIPPED (there is no `## [vX.Y]` key to slice —
# mirrors phase_append_changelog step (0)); the DIGEST assertion still runs, because
# phase_append_release_digest writes an H3 for a version-less release too.
phase_assert_derived_surfaces() {
  local changelog_path="$REPO_ROOT/CHANGELOG.md"

  # DRY-RUN branch — deliberately the FIRST statement in the body, above all three
  # is_version_less guards and outside the presence loop, so the apply path below is
  # reached with exactly the control flow it had before. Detail carries no '|' so it
  # cannot break the markdown phase table in --markdown reports.
  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "assert_derived_surfaces" "DRY-RUN" "would assert that the ${VERSION} entries on CHANGELOG.md and release/releases/RELEASE_DIGEST.md are present and carry no unfilled scaffold residue. Not evaluated under --dry-run: the append phases wrote nothing, so both slices are absent by construction and a presence check here would only fail on this script's own no-op. The assertion runs for real at --apply, after the appends land and before the chore commit"
    return 0
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

  local _surface _slice _file _res _rc
  for _surface in CHANGELOG DIGEST; do
    if [[ "$_surface" == "CHANGELOG" ]]; then _slice="$_cl_slice"; _file="CHANGELOG.md"
    else _slice="$_dg_slice"; _file="release/releases/RELEASE_DIGEST.md"; fi
    # PRESENCE (#4455). An empty slice means the closing version has NO entry on
    # this surface — the caller dropped it — and this phase used to treat that as
    # "nothing to check" and pass. So `projector emitted, caller dropped it` had
    # no close-out-time detector anywhere; Checks 32 and 48 were its only gate in
    # the whole platform. That failure is made MORE reachable by moving synthesis
    # behind a `$(...)` capture, so it is gated in the same change, and the phase
    # name finally describes what the phase does.
    #
    # The two legitimate N/A branches are preserved exactly and are handled ABOVE
    # this loop, not here: a version-less release has no `## [vX.Y]` CHANGELOG key
    # to slice, and a pre-CHANGELOG repo has no CHANGELOG file. Both leave
    # _cl_slice empty for a reason that is not a dropped write.
    if [[ -z "$_slice" ]]; then
      if [[ "$_surface" == "CHANGELOG" ]] && { is_version_less || [[ ! -f "$changelog_path" ]]; }; then
        continue
      fi
      mark_phase "assert_derived_surfaces" "FAIL" "no ${VERSION} entry on the derived surface ${_file} — the projector emitted an entry but it is not in the file, or the append phase was skipped. Re-run the ${_surface} append phase; do NOT regenerate the file"
      return 1
    fi
    _rc=0
    _res="$(printf '%s\n' "$_slice" | scan_scaffold_residue)" || _rc=$?
    if [[ $_rc -eq 2 ]]; then
      mark_phase "assert_derived_surfaces" "FAIL" "scaffold-residue token set unreadable from ${LINT_RELEASE_CORPUS} (--print-scaffold-tokens) — derived-surface residue cannot be evaluated; failing loud rather than passing vacuously (#459)"
      return 1
    elif [[ $_rc -eq 1 ]]; then
      mark_phase "assert_derived_surfaces" "FAIL" "unfilled scaffold residue on a derived surface: ${_file}:${_res#*|} in the ${VERSION} entry carries token '${_res%%|*}' — author the release note and re-derive the entry before close-out (release-notes-standard.md § Part 5 Layer-1 dual-write)"
      return 1
    fi
  done

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

# ─── Phase 9.56: assert_output_set ───────────────────────────────────────────
#
# PRE-COMMIT close-out output-set completeness (#5288).
#
# THE DEFECT THIS CLOSES. The RELEASE_LOG row is flipped DEPLOYED -> VERIFIED at
# Phase 6, in the WORKING TREE, long before that tree is committed. Every phase
# between the flip and phase_commit_chore_pr asserts something else: 9.55 reads
# the CHANGELOG + DIGEST slices, 9.9 reads the append-only-ledger diff. NOTHING
# between them reads the close-out OUTPUT SET. So a producing phase that marks
# SKIPPED and returns 0 leaves its output unwritten, the stamp commits anyway,
# and VERIFIED reaches main meaning only "the close-out ran" rather than "the
# close-out output set is complete".
#
# The post-stamp lane (deploy.sh Check 48 sub-checks (j)/(k)/(l)) does report the
# absence — but it selects rows whose State cell ALREADY reads VERIFIED, so by
# construction it cannot fire before the stamp, and its warn posture maps a
# finding to exit 0. It is a regression catch on main, not a gate on the close.
# This phase is the lane-1 half that was missing: it reads the bytes about to be
# committed, and a missing REQUIRED member aborts the run BEFORE
# phase_commit_chore_pr, so the stamp never leaves the tree.
#
# READ-ONLY. This phase writes nothing and stages nothing. If it ever wrote,
# phase_commit_chore_pr's "nothing staged" branch and phase_ledger_guard's
# diff-versus-origin/main would both change behaviour on an otherwise-no-op run.
#
# NO --no-merge BRANCH, NO VERSION-LESS SKIP — both deliberate. This phase runs
# pre-commit, so --no-merge (which defers post-merge phases) cannot reach it; a
# --no-merge branch here would create a mode in which the completeness gate
# silently does not run. And for a version-less close the post-stamp lane is
# structurally blind (its row selector is version-shaped), so lane 1 is the ONLY
# enforcement — a version-less skip would remove the only gate there is.
#
# SCOPE OF THE MANIFEST — the PRE-COMMIT-ASSERTABLE subset, and why it is one.
# The canonical Stage 13 output set is the Step-4 Verification table in
# hub-spoke-bridge.md Procedure 7. Most of its rows name post-merge, on-main
# facts (the annotated tag, the closed milestone, the published GitHub Release)
# that do not yet exist at 9.56 and cannot be asserted here without asserting a
# falsehood. The members below are the ones the CHORE COMMIT ITSELF must carry —
# and they are exactly the three the lane-1 table historically did not name,
# which is why they are the three that went missing silently. Adding a future
# member is one row in _output_set_manifest plus its probe arm: membership is
# DATA, not control flow.
#
# WHY THIS IS A GUARDED PHASE AND NOT ANOTHER STEP-4 TABLE ROW. The Step-4
# table's blocking authority is narrative: phase_run_verification computes its
# cells and then marks the phase PASS unconditionally, so a FAIL cell blocks only
# if a human reads it. Anyone tempted to "simplify" this phase into a table row
# would silently remove the gate.

# Membership vocabulary — the `Req` column on the Step-4 Verification table:
#   required                 owed by every close; absent => BLOCK
#   required-if <predicate>  owed when the named predicate holds
#   optional                 never owed; absent => recorded, never blocks
#
# MEMBERSHIP IS NOT OUTCOME. Before this column existed, `N/A` did two
# incompatible jobs — "this output does not apply to this release" and "this
# output is not owed". The flag carries membership; the Result cell carries
# outcome.
#
# THE THIRD PREDICATE STATE IS NOT "FALSE". A `required-if` predicate that cannot
# be EVALUATED resolves INDETERMINATE, and INDETERMINATE BLOCKS. Grading an
# unevaluable predicate false would resolve the row N/A — a SATISFIED state — so
# an owed output would be recorded satisfied because its membership test could
# not run. That is this ticket's own defect ("absence emits nothing")
# reintroduced inside its own fix, at the one membership state it invented. Per
# core/disciplines/review-discipline-principles.md § 8: when a required value
# cannot be established the verdict is INDETERMINATE naming the missing element,
# never a pass.
#
# Row shape: <id>|<flag>|<producing-phase>|<human description>. The `|` is the
# file's own in-array record separator (see check_paths); it is confined to this
# array and NEVER reaches a phase DETAIL string, because `|` is simultaneously
# get_phase's field separator and the markdown report table's column separator.
# The per-member REPORT line uses ` / ` within a row and ` · ` between rows.
_output_set_manifest() {
  /bin/cat <<EOF
velocity-field|required|inject_velocity_field|Velocity field in the ${VERSION} Deployment Log block
learnings-block|required|append_release_learnings|Release Learnings ${VERSION} block, the sibling H4 of that Deployment Log block (hot ledger)
close-class-telemetry|required-if telemetry-cutover-armed|inject_close_class_telemetry_field|Close-Class-Telemetry field in the ${VERSION} Deployment Log block
EOF
}

# THE CUTOFF SEAM (#5288 P-1). deploy.sh's Check 48 sub-check (l) owns the
# telemetry cutover value; THIS process must read the same value to decide
# whether the Close-Class-Telemetry field is an owed member. It is READ, never
# COPIED — a second literal here would be a shadow source of truth that drifts
# the moment the cutover is armed in deploy.sh, and would make "arming is a
# one-value change" false.
#
# Resolution order mirrors deploy.sh's own: an exported
# CLOSE_COMPLETENESS_TELEMETRY_CUTOFF wins (so one env value drives BOTH lanes
# identically), otherwise the COMMITTED DEFAULT is extracted from deploy.sh's
# shape-frozen assignment. The frozen shape is documented at the assignment
# itself, under `CROSS-TOOL READ CONTRACT`.
#
# Echoes the cutoff and returns 0 on success. Echoes NOTHING and returns 1 when
# the value cannot be established. It NEVER falls back to a literal: a fallback
# would make an unreadable seam indistinguishable from a deliberately dormant
# cutover, which is the exact fail-open this phase exists to close.
CLOSE_COMPLETENESS_SOURCE="${CLOSE_COMPLETENESS_SOURCE:-$REPO_ROOT/core/deploy/deploy.sh}"

_resolve_telemetry_cutoff() {
  if [[ -n "${CLOSE_COMPLETENESS_TELEMETRY_CUTOFF:-}" ]]; then
    /usr/bin/printf '%s' "$CLOSE_COMPLETENESS_TELEMETRY_CUTOFF"
    return 0
  fi
  [[ -f "$CLOSE_COMPLETENESS_SOURCE" ]] || return 1
  local _hits _n
  _hits="$(/usr/bin/sed -n 's/^[[:space:]]*local cc_telemetry_cutoff="\${CLOSE_COMPLETENESS_TELEMETRY_CUTOFF:-\([^}"]*\)}"[[:space:]]*$/\1/p' "$CLOSE_COMPLETENESS_SOURCE" 2>/dev/null || true)"
  # EXACTLY ONE match. Zero means the frozen shape changed; two or more means the
  # live value is ambiguous. Both are INDETERMINATE — never a guess at which one
  # deploy.sh would actually have used.
  _n="$(/usr/bin/printf '%s\n' "$_hits" | grep_count .)"
  [[ "$_n" -eq 1 ]] || return 1
  [[ -n "$_hits" ]] || return 1
  /usr/bin/printf '%s' "$_hits"
  return 0
}

# Resolve ONE manifest member's membership state. TOTAL over the flag vocabulary,
# with an explicit default that lands on INDETERMINATE rather than on a pass.
# Echoes: required | not-owed | indeterminate:<reason>
_output_set_membership() {
  local _flag="$1" _cut
  case "$_flag" in
    required) /usr/bin/printf 'required' ;;
    optional) /usr/bin/printf 'not-owed' ;;
    "required-if telemetry-cutover-armed")
      if ! _cut="$(_resolve_telemetry_cutoff)"; then
        /usr/bin/printf 'indeterminate:the telemetry cutover value could not be read from %s — the cross-tool read contract at that file'"'"'s cc_telemetry_cutoff assignment is broken (renamed local, split assignment, or more than one assignment). Repair the seam or export CLOSE_COMPLETENESS_TELEMETRY_CUTOFF explicitly; this is NEVER defaulted' "${CLOSE_COMPLETENESS_SOURCE#"$REPO_ROOT"/}"
      elif [[ "$_cut" == "__none__" ]]; then
        /usr/bin/printf 'not-owed'
      else
        /usr/bin/printf 'required'
      fi ;;
    *)
      /usr/bin/printf 'indeterminate:unknown membership flag %s — the flag vocabulary is required / required-if <predicate> / optional' "$_flag" ;;
  esac
}

# Block-scoped field presence on the RESOLVED surface — the same two-surface
# resolution phases 6.5 / 6.6 / 6.8 write through, so a field that legitimately
# lives in an archive segment is not read as absent.
_block_field_present() {
  local _key="$1" _tgt
  _tgt="$(_resolve_deployment_log_target "$VERSION" || true)"
  [[ -n "$_tgt" ]] || return 1
  /usr/bin/awk -v ver="$VERSION" -v key="$_key" '
      { line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line) }
      line == "#### Deployment Log " ver { inblk = 1; next }
      inblk && line ~ /^#### / { inblk = 0 }
      inblk && index(line, key) == 1 { found = 1 }
      END { exit(found ? 0 : 1) }
    ' "$_tgt" 2>/dev/null
}

# Tree-PRESENCE probe for ONE member. PRESENCE — not phase result — is the
# --apply predicate deliberately: an idempotent re-run whose producing phase
# SKIPPED *because the output was already there* must pass.
_output_set_member_present() {
  case "$1" in
    velocity-field)        _block_field_present '**Velocity:**' ;;
    learnings-block)       _learnings_block_placed ;;
    close-class-telemetry) _block_field_present '**Close-Class-Telemetry:**' ;;
    *) return 1 ;;
  esac
}

# Is a `**Not-produced:**` marker for this member recorded in the block?
#
# READ FOR THE REPORT ONLY. No verdict branch in phase_assert_output_set consults
# this predicate — see the EVIDENCE-NOT-EXEMPTION note on _write_not_produced_marker.
_not_produced_marker_present() {
  local _id="$1" _tgt
  _tgt="$(_resolve_deployment_log_target "$VERSION" || true)"
  [[ -n "$_tgt" ]] || return 1
  /usr/bin/awk -v ver="$VERSION" -v id="$_id" '
      { line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line) }
      line == "#### Deployment Log " ver { inblk = 1; next }
      inblk && line ~ /^#### / { inblk = 0 }
      inblk && index(line, "**Not-produced:** " id " ") == 1 { found = 1 }
      END { exit(found ? 0 : 1) }
    ' "$_tgt" 2>/dev/null
}

# --dry-run classifier. TOTAL over (producing-phase, recorded RESULT), with an
# explicit default that lands on INDETERMINATE.
#
# WHY IT IS ADDRESSED BY (phase, result) AND NOT BY DETAIL PROSE. get_phase
# returns the in-band sentinel `—|—` at exit status 0 for a phase that never ran,
# so "not found" cannot be read off the status and MUST be handled as a value.
# And SKIPPED is ambiguous BY PHASE: phase_append_release_learnings marks SKIPPED
# both when the block is ALREADY PLACED (output PRESENT) and when the synthesizer
# is not executable (output ABSENT) — two opposite meanings a detail-prefix match
# cannot separate. SKIPPED is therefore resolved by re-probing the TREE, which is
# the ground truth the two arms disagree about. Row-pattern-matching English prose
# is the failure this file's own decoy arm (self-test group AI arm B2) exists to
# prove a gate does not commit.
#
# Echoes: would-present | would-absent | indeterminate:<reason>
_output_set_dryrun_class() {
  local _id="$1" _phase="$2" _rec _res
  _rec="$(get_phase "$_phase")"
  _res="${_rec%%|*}"
  case "$_res" in
    PASS) /usr/bin/printf 'would-present' ;;
    DRY-RUN)
      # The producers' dry-run vocabulary is two-valued by construction: a
      # would-fail preview carries a literal `would FAIL` detail; every other
      # DRY-RUN preview is a would-write.
      if /usr/bin/grep -qF 'would FAIL' <<<"$_rec"; then
        /usr/bin/printf 'would-absent'
      else
        /usr/bin/printf 'would-present'
      fi ;;
    WARN|FAIL) /usr/bin/printf 'would-absent' ;;
    SKIPPED)
      if _output_set_member_present "$_id"; then
        /usr/bin/printf 'would-present'
      else
        /usr/bin/printf 'would-absent'
      fi ;;
    *)
      /usr/bin/printf 'indeterminate:producing phase %s recorded result %s, which this classifier does not enumerate (an unrecorded phase reads as the in-band get_phase sentinel and lands here). Fail-closed by construction' "$_phase" "${_res:-<empty>}" ;;
  esac
}

# Row 7-9 cell for phase_run_verification's Step-4 render. A PURE PROJECTION of
# the STATE_OUTPUT_SET_ROWS record written at Phase 9.56 — no I/O, no re-probe,
# no membership evaluation. Same contract as _ai_verification_cell and for the
# same reason: 9.56 is where the close was gated, and re-deriving a cell after
# the close renders a verdict nothing was gated on. An unset record renders
# UNVERIFIED, never a green cell.
_output_set_verification_cell() {
  local _id="$1" _hit
  _hit="$(/usr/bin/awk -F'\t' -v id="$_id" '$1 == id { print $2; exit }' <<<"$STATE_OUTPUT_SET_ROWS")"
  if [[ -z "$_hit" ]]; then
    /usr/bin/printf 'UNVERIFIED (phase 9.56 output-set assert did not run before this phase)'
  else
    /usr/bin/printf '%s' "$_hit"
  fi
}

phase_assert_output_set() {
  local _row _id _flag _phase _desc
  local _report="" _missing="" _indet="" _total=0
  local _memb _verdict _marker _cls
  # Reset before the sweep: the phase is re-invocable in-process (--self-test
  # drives it repeatedly), and an accumulating record would let a prior run's
  # verdict render in this run's table.
  STATE_OUTPUT_SET_ROWS=""

  while IFS='|' read -r _id _flag _phase _desc; do
    [[ -z "$_id" ]] && continue
    _total=$((_total+1))
    _memb="$(_output_set_membership "$_flag")"

    # A `**Not-produced:**` marker naming this member is EVIDENCE, never an
    # EXEMPTION. It is read HERE, into a report suffix, and is deliberately not
    # referenced by any branch below that assigns _verdict or appends to
    # _missing. Structurally, no marker can move a verdict.
    _marker=""
    if _not_produced_marker_present "$_id"; then
      _marker=" [Not-produced marker recorded — evidence, not an exemption]"
    fi

    case "$_memb" in
      indeterminate:*)
        _verdict="INDETERMINATE"
        _indet="${_indet}${_id} (${_memb#indeterminate:}); "
        ;;
      not-owed)
        _verdict="N-A (predicate false — not owed by this close)"
        ;;
      *)
        if [[ "$MODE" == "dry-run" ]]; then
          _cls="$(_output_set_dryrun_class "$_id" "$_phase")"
          case "$_cls" in
            would-present) _verdict="WOULD-BE-PRESENT" ;;
            would-absent)  _verdict="WOULD-BE-ABSENT"; _missing="${_missing}${_id}; " ;;
            *)             _verdict="INDETERMINATE"; _indet="${_indet}${_id} (${_cls#indeterminate:}); " ;;
          esac
        elif _output_set_member_present "$_id"; then
          _verdict="PRESENT"
        else
          _verdict="ABSENT"; _missing="${_missing}${_id}; "
        fi
        ;;
    esac
    _report="${_report}${_id} / ${_flag} / ${_verdict}${_marker} / ${_desc} · "
    STATE_OUTPUT_SET_ROWS="${STATE_OUTPUT_SET_ROWS}${_id}	${_verdict}
"
  done <<EOF
$(_output_set_manifest)
EOF

  _report="${_report% · }"
  local _sfx="manifest (${_total} members): ${_report}"

  # INDETERMINATE first: a membership test that could not run is a stronger
  # finding than a member that is merely absent, and it must not be masked by a
  # clean presence sweep over the members whose tests DID run.
  if [[ -n "$_indet" ]]; then
    local _im="output-set membership INDETERMINATE for ${_indet%; } — an unevaluable membership test is never a pass, so this BLOCKS rather than recording an owed output as satisfied. ${_sfx}"
    if [[ "$MODE" == "dry-run" ]]; then
      mark_phase "assert_output_set" "WARN" "$_im — NOT blocking under --dry-run (nothing is committed, so no record can be corrupted here); this same condition FAILS the close at --apply"
      return 0
    fi
    mark_phase "assert_output_set" "FAIL" "$_im"
    return 3
  fi

  if [[ -n "$_missing" ]]; then
    local _mm="required close-out output(s) missing from the tree about to be committed: ${_missing%; }. The ${VERSION} RELEASE_LOG row is ALREADY stamped VERIFIED in this tree — committing it now would land the stamp on main ahead of its own outputs, which is exactly what VERIFIED is supposed to rule out. A **Not-produced:** marker records WHY a member is absent and NEVER satisfies this gate. ${_sfx}"
    if [[ "$MODE" == "dry-run" ]]; then
      mark_phase "assert_output_set" "WARN" "$_mm — NOT blocking under --dry-run (nothing is committed, so no record can be corrupted here); this same condition FAILS the close at --apply"
      return 0
    fi
    mark_phase "assert_output_set" "FAIL" "$_mm"
    return 3
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "assert_output_set" "DRY-RUN" "every owed close-out output would be present in the committed tree. Predicted from the producing phases' own recorded results this run, not from the tree (the producers wrote nothing under --dry-run). ${_sfx}"
    return 0
  fi
  mark_phase "assert_output_set" "PASS" "every owed close-out output is present in the tree about to be committed. ${_sfx}"
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
#   NOTE: main's `validate_version "$VERSION" || die` gate means the script never
#   reaches this phase with an invalid $VERSION under --apply or --dry-run; the
#   in-phase SKIP guard is the executable statement of the version-less rule and
#   is what --self-test / the regression test exercise when invoking the phase
#   directly. Full rationale in the REACHABILITY note above is_version_less —
#   cited by name rather than by line number, which rots (this pointer read
#   "line ~1501" against a file that has since more than quintupled).
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
  # Same resolver the note frontmatter uses — this body becomes a PUBLIC GitHub PR
  # body that no in-repo sweep can ever reach back and correct, so getting it right
  # at emission is the only chance there is. Resolved before the heredoc for the
  # same reason as the note scaffold: a non-zero return inside it is invisible.
  local plan_ref; plan_ref="$(plan_ref_for_emit)" || true

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
| release/releases/$(notes_rel_path) | NEW | Scaffolded per release-notes-standard.md Part 1 Template; operator-filled prose |
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

- Release plan: ${plan_ref}
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
# DETECTION IS DELEGATED, NOT RESTATED (#4722). The affected-skill set is resolved
# by `build-skill-packages.sh --skills-for-paths`, the package builder's own query
# mode. This phase owns WHAT TO DO with the set; the builder owns WHAT THE SET IS.
#
# Why (the defect this closes): the detection used to live here as a local
# `changed_skills_from_paths()` carrying a hand-written prefix `case` over
# core/standards/ and operations/templates/. Canonicals do not all live under those
# two prefixes — tracker-schemas.md homes to core/schemas/ (its own arm in
# lib-template-sync-source.sh) — so a core/schemas/ canonical edit stales
# tracker-manager's package while this phase resolved an EMPTY set and reported
# green "nothing to rebuild". That is the last line of defence against a staled
# package at release close, and it was 26/27 canonicals wide. The builder's query
# decides rule (b) by CALLING resolve_template_sync_source() — the same resolver its
# injection loop calls to find the file it copies — so query and injection agree by
# construction and a future resolver arm is picked up here for free.
# claim-version.sh:747-751 already consumes this same query for the same reason, and
# records it: "A second copy here would be a shadow SSOT." This function WAS that
# second copy.
#
# COUPLING, PRICED HONESTLY (do not restate this as "the narrowest coupling"). The
# builder dispatches its query AFTER three hard `exit 1` preconditions —
# TEMPLATE_SYNC_MAP non-empty, the per-module roster arrays non-empty, and the shared
# resolver lib present — so a deploy.sh reshape that empties any of them hard-FAILs a
# release close here.
#
# The roster precondition USED TO BE provably irrelevant to this query, and this
# comment used to say so in those words. That is no longer true and the claim is
# retired rather than left standing: query rule (a) now gates each candidate on
# resolve_skill_module(), so the query READS the roster arrays. The coupling is real
# on all three preconditions, not two. A roster reshape no longer trips this query
# only through an unrelated guard — it changes the query's own answer.
#
# That is the price of making "the query emits it" and "the build accepts it" a
# biconditional rather than an agreement, and it is the right trade: the alternative
# is a query that emits arguments no consumer can build, which is precisely what fed
# this phase an unbuildable candidate and failed a whole batch on it.
#
# The delegation is still right, but on MINIMUM CONTENTION — the resolution rules
# live in ONE place and both live consumers (this phase and claim-version.sh) get the
# same answer from it — not on narrowest surface.
#
# WHAT THIS DOES NOT PROPAGATE TO (the "every consumer" claim is over-stated).
# .github/workflows/skill-package-freshness.yml is the repo's only pre-merge package-
# freshness gate, and its trigger `paths:` filter names NONE of the three canonical
# trees. A canonical-only edit therefore does not fire it, with no compensating
# coverage elsewhere. This phase is the close-time net, not a redundant one.
#
# RESIDUAL — TOTAL ABSENCE, NOT PARTIAL DEGRADATION (F3). The fail-loud guard below
# catches "the builder could not answer at all" (absent, or non-zero exit). It does
# NOT catch a map that silently degrades from 49 entries to a handful: the builder's
# own precondition tests `-eq 0`, so a truncated map answers successfully and wrongly,
# and this phase cannot second-guess it without re-deriving the very rules it just
# delegated — which would reintroduce the shadow SSOT. A partial-degradation detector
# belongs at the builder's precondition, not here. Named, not silently accepted: this
# guard would NOT have caught the 26/27 defect it ships beside.
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

  # ── Detection: DELEGATED to build-skill-packages.sh --skills-for-paths ──────
  # Deliberately ABOVE the dry-run branch: the release diff is real in BOTH modes,
  # so the set is genuinely computable at --dry-run and the operator must see the
  # true "would rebuild" list at the review gate, not a mode-degraded one. Moving
  # this below the dry-run return would make the dry-run preview vacuous.
  #
  # --root is NOT optional. The builder derives its own REPO_ROOT from its own file
  # location, so a close-out running against any tree other than the builder's own
  # (the --self-test sandbox below, and any future non-self-rooted invocation) would
  # silently answer from the WRONG tree. Same reason claim-version.sh:747-751 passes
  # it. Here-string, never `producer | builder`: a pipeline conflates the producer's
  # status with the consumer's, and this call's exit code is the fail-loud signal.
  #
  # NO `|| true`. That idiom is the defect class this phase exists to close: it maps
  # every delegation failure onto the same empty string as a legitimately-empty diff,
  # and the N/A limb below then reports green "nothing to rebuild" over an
  # undeterminable set. Failure and emptiness are now distinguishable.
  local candidates="" detect_rc=0
  if [[ ! -f "$builder" ]]; then
    detect_rc=127
  else
    candidates="$(/bin/bash "$builder" --root "$REPO_ROOT" --skills-for-paths <<< "$changed" 2>/dev/null)" || detect_rc=$?
    [[ $detect_rc -ne 0 ]] && candidates=""
  fi

  # Fail-loud guard on an UNDETERMINABLE set — mirrors the D-4d diff-base guard above.
  #
  # C1 (#4765 convention): ASSERT AT --apply, PREDICT AT --dry-run. #4765 established
  # that a --dry-run must never abort a phase — its own abort at 9.55 cost every phase
  # after it, and an abort HERE would cost the fourteen after 9.95, taking the
  # dry-run review gate with it. So the ABORT is scoped to --apply. The FINDING is
  # not: --dry-run still reports it, as a non-blocking WARN (the outcome this file
  # already uses at 15.6 for a real finding held outside its blocking scope), because
  # a dry-run commits nothing and therefore cannot stale a package — it can only
  # mislead. Silence here would be the same green-over-unknown this card closes.
  if [[ $detect_rc -ne 0 ]]; then
    local _d_why="build-skill-packages.sh --skills-for-paths exited ${detect_rc}"
    [[ $detect_rc -eq 127 ]] && _d_why="package builder absent at core/deploy/tools/build-skill-packages.sh"
    local _d_fix="affected-skill set UNDETERMINABLE, so .skill staleness cannot be ruled out. The builder exits 1 before answering when deploy.sh yields no TEMPLATE_SYNC_MAP, no per-module roster arrays (which this query now READS, to filter out path segments that are not packageable skills — so a roster reshape changes this query's own answer), or when core/deploy/lib-template-sync-source.sh is missing. Resolve the builder, then re-run; or rebuild + stage the affected package(s) per core/rules/skill-deployment.md before closing"
    if [[ "$MODE" == "dry-run" ]]; then
      mark_phase "rebuild_skill_packages" "WARN" "${_d_why} — ${_d_fix}. NOT blocking under --dry-run (nothing is committed, so no package can be staled here); this same condition FAILS the close at --apply"
      return 0
    fi
    mark_phase "rebuild_skill_packages" "FAIL" "${_d_why} — ${_d_fix}"
    return 3
  fi

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

  # PER-SKILL INVOCATION, not one batched call. A batched build collapses every
  # skill's outcome onto ONE exit code, so this phase could only ever name the whole
  # candidate set — "failed for one of: <21 skills>" — and a single unresolvable
  # argument discarded twenty-one rebuilds that had already succeeded. Looping makes
  # each skill's exit code its own: failures accumulate BY NAME, successes survive.
  #
  # THE LOUD STOP IS DELIBERATELY KEPT. A genuinely unbuildable skill still marks
  # FAIL and returns 3. What changes is attribution, not tolerance. The tempting
  # alternative — re-derive the rebuilt set from the working tree instead of trusting
  # exit codes — is a SILENT PASS and was rejected for that reason: the R8 sidecar
  # gate immediately below means a successful content-identical rebuild produces NO
  # working-tree change, which is byte-for-byte indistinguishable from a skill that
  # never built at all. Observed state cannot tell those two apart; exit codes can.
  #
  # --root is passed here for the same reason the detection call above passes it, and
  # with more force: the builder derives its own REPO_ROOT from its own file location.
  # Answering from the wrong tree is a wrong answer; BUILDING into the wrong tree
  # writes packages there. Today $builder is resolved under $REPO_ROOT so the two
  # coincide by construction, but that is a coincidence, not a guarantee — and the
  # self-test sandbox below is exactly the case where they do not.
  #
  # Guarded per-skill subshell (M3-3): the builder runs set -euo pipefail + exit 1 on
  # failure; the subshell isolates its set -e so its exit does not abort this script
  # before mark_phase runs.
  local _rb_skill _rb_failed="" _rb_ok="" _rb_detail=""
  for _rb_skill in $candidates; do
    if ! ( /bin/bash "$builder" --root "$REPO_ROOT" "$_rb_skill" ) >/dev/null 2>&1; then
      _rb_failed="${_rb_failed:+$_rb_failed }$_rb_skill"
    else
      _rb_ok="${_rb_ok:+$_rb_ok }$_rb_skill"
    fi
  done
  if [[ -n "$_rb_failed" ]]; then
    # THE EXONERATION LIST IS THE SUCCEEDED SET, NOT $names. $names is the FULL
    # candidate set, so naming it here placed the skill that had just failed inside its
    # own "not implicated" list — "failed for: _shared ... (_shared) are not
    # implicated". Whoever reads this line is mid-diagnosis of that exact failure, which
    # is the only moment the message is read and the one moment it must not contradict
    # itself. When every candidate failed the clause has no members and says so, rather
    # than printing an empty parenthetical that reads like a truncated list.
    _rb_detail="build-skill-packages.sh failed for: ${_rb_failed} — package(s) not rebuilt; close blocked (re-run after resolving the build error)."
    if [[ -n "$_rb_ok" ]]; then
      _rb_detail="${_rb_detail} Other candidates in this release's set (${_rb_ok}) are not implicated"
    else
      _rb_detail="${_rb_detail} No other candidate in this release's set built successfully"
    fi
    mark_phase "rebuild_skill_packages" "FAIL" "$_rb_detail"
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

  # The note entry is resolved, not retyped: staging is guarded by `[[ -f ]]`, so a
  # path that disagrees with the producer does not error — it silently stages
  # nothing, and the release note never reaches the chore commit.
  local files=(
    "release/releases/RELEASE_LOG.md"
    "release/releases/RELEASE_INDEX.md"
    "release/releases/RELEASE_DIGEST.md"
    "release/releases/RELEASE_REVERSIONS.md"
    "release/releases/$(notes_rel_path)"
    "CHANGELOG.md"
    ".version"
    "${REBUILT_PACKAGES[@]:-}"      # .skill packages + .sha256 sidecars staged by
                                    # phase_rebuild_skill_packages (Phase 9.95); empty
                                    # on a release that touches no skill source.
    "${TOUCHED_ARCHIVE_SEGMENTS[@]:-}"  # RELEASE_LOG_ARCHIVE-<family>.md segments the
  )                                     # 6.5/6.6 resolver actually WROTE INTO (#4710);
                                        # empty until a block ages out of the sweep
                                        # window. Touched-only by design — a blanket
                                        # RELEASE_LOG_ARCHIVE-*.md glob would sweep
                                        # unrelated local edits into the chore PR.

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
    # Staging-completeness assertion, empty-staged-set arm (#4710). The E9 assert
    # below runs only AFTER a commit exists, so this early-return escapes it —
    # which is exactly how the worse half of #4710 stayed silent: 6.5 and 6.6
    # reported an injected write and this branch then reported green "no-op"
    # directly beneath them, with no chore commit at all. An inject_* phase marked
    # PASS wrote a field to disk (its SKIPPED/FAIL limbs write nothing), so an
    # EMPTY staged set contradicts its own report.
    #   Reads the PHASE RECORD, not TOUCHED_ARCHIVE_SEGMENTS. A guard that consults
    # the same recorder whose omission IS the defect cannot catch that omission —
    # it would go vacuous the moment a future write site forgets to record, which
    # is the regression this exists to catch. Structurally general: any future
    # inject_* phase is covered without touching this code.
    local _iw="" _i
    for ((_i=0; _i<${#PHASE_NAMES[@]}; _i++)); do
      if [[ "${PHASE_NAMES[$_i]}" == inject_* && "${PHASE_RESULTS[$_i]}" == "PASS" ]]; then _iw="${_iw}${PHASE_NAMES[$_i]} "; fi
    done
    if [[ -n "$_iw" ]]; then
      mark_phase "commit_chore_pr" "FAIL" "staging-completeness: ${_iw% } reported an injected write but the staged set is EMPTY — the write landed on a surface files=() does not name, so a mandated output would be dropped from the chore PR while every phase reported green"
      return 3
    fi
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

    # Staging-completeness assertion, TOUCHED-SURFACE arm (#4710 AC-3). Reads the
    # COMMIT, like the rebuilt-packages arm above — but that arm iterates
    # REBUILT_PACKAGES only, so a resolver-routed write to any other surface was
    # covered by nothing here. The empty-staged-set guard at the top of this phase
    # does cover it in principle, but it sits behind `[[ -z "$(git diff --staged
    # --name-only)" ]]` and can therefore fire ONLY when nothing at all is staged —
    # a condition a real close-out never reaches, because RELEASE_LOG.md is always
    # present. Between the two, an unrecorded segment write was dropped from the
    # commit while this phase still reported PASS.
    #
    #   INDEPENDENCE (the binding Stage 5 constraint). The expected set is derived
    # from the PHASE RECORD — the surface each inject_* phase NAMED in its own PASS
    # detail — never from TOUCHED_ARCHIVE_SEGMENTS. A guard that consults the same
    # recorder whose omission IS the defect goes vacuous the instant a future write
    # site forgets to call _record_touched_archive_segment, which is exactly the
    # regression this exists to catch. Same property the empty-set guard above was
    # built on, and it is what makes this arm fail on a MISSING recorder call rather
    # than agree with it.
    #
    #   Matched by basename against the committed path list, so a future surface
    # that lands in a different directory is still adjudicated instead of silently
    # excluded. The hot ledger is skipped — files=() names it unconditionally.
    local _reported="" _rmissing="" _rfound="" _sfc _sfc_re _hot _i2 _tok
    _hot="$(/usr/bin/basename "$RELEASE_LOG")"
    for ((_i2=0; _i2<${#PHASE_NAMES[@]}; _i2++)); do
      [[ "${PHASE_NAMES[$_i2]}" == inject_* && "${PHASE_RESULTS[$_i2]}" == "PASS" ]] || continue
      # Parenthesized "(<surface>.md)" is the shape every inject_* PASS detail uses
      # to name the surface it resolved to. Non-.md parentheticals (e.g. the
      # "(+ **Outcome rationale:**)" suffix) do not match and are ignored.
      for _tok in $(/usr/bin/printf '%s\n' "${PHASE_DETAILS[$_i2]}" \
                      | /usr/bin/grep -oE '\([A-Za-z0-9._-]+\.md\)' | /usr/bin/tr -d '()' || true); do
        [[ "$_tok" == "$_hot" ]] && continue
        case " $_reported " in *" $_tok "*) continue ;; esac
        _reported="${_reported}${_tok} "
      done
    done
    for _sfc in $_reported; do
      _sfc_re="${_sfc//./\\.}"
      # Here-string, not `printf … | grep -q`: the reader short-circuits on its
      # first match and can SIGPIPE the writer. The empty-haystack difference is
      # inert here — `<<<""` presents one empty line, and the needle is anchored
      # on a basename ending in `.md`, so it cannot match an empty line.
      if /usr/bin/grep -qE "(^|/)${_sfc_re}\$" <<<"$_committed"; then
        _rfound="${_rfound}${_sfc} "
      else
        _rmissing="${_rmissing}${_sfc} "
      fi
    done
    if [[ -n "$_rmissing" ]]; then
      mark_phase "commit_chore_pr" "FAIL" "staging-completeness: surface(s) an inject_* phase reported writing into are NOT in the chore commit — ${_rmissing% }; the write landed on disk but files=() does not name it, so a mandated output would be dropped from the chore PR while every phase reported green"
      return 3
    fi

    # Report the resolved write targets that were actually staged, so a surface
    # outside the fixed files=() enumeration is visible in the phase log instead of
    # vanishing into a green PASS.
    local _detail="committed: $commit_msg"
    [[ -n "$_rfound" ]] && _detail="$_detail; resolved write target(s) staged: ${_rfound% }"
    mark_phase "commit_chore_pr" "PASS" "$_detail"
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
      _notes_on_main="$(git_net -C "$REPO_ROOT" cat-file -e "origin/main:release/releases/$(notes_rel_path)" 2>/dev/null && echo 1 || echo 0)"
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

# ─── Phase 12.2: sync_primary_checkout (AC7) ─────────────────────────────────
#
# "The primary checkout sits at origin/main" is a STANDING invariant
# (core/rules/git-workflow.md § Primary Checkout Discipline), and that file
# explicitly forbids leaving it as a "want me to sync it?" handoff. Close-out
# previously neither executed nor emitted the sync — the only mention of the primary
# anywhere in this script is preflight (c), which REJECTS running from it. This phase
# executes the sync, once, at the earliest point origin/main actually carries the
# merge.
#
# HARD CONSTRAINTS (git-workflow.md § Primary Checkout Discipline):
#   - `git -C <primary>` ONLY. Never `cd` into the primary.
#   - Fast-forward ONLY. Never reset, never stash, never checkout, never force.
#   - Only when the primary is actually ON main — fast-forwarding some other branch
#     to origin/main would silently move work the operator did not ask to move.
#
# NON-FATAL BY DESIGN — every path returns 0. The chore PR has already merged by the
# time this runs; a primary-sync problem must never fail a close that already
# succeeded. It must also stay hermetic: in CI there is no primary checkout at all,
# so "absent" is a clean SKIP, not an error.
#
# Runs under --no-merge too: the invariant is "primary tracks origin/main", which is
# worth holding regardless of whether this release's chore PR landed.
phase_sync_primary_checkout() {
  # Resolution order: explicit override (the self-test seam) → git's own record of the
  # main working tree. Asking git is exact and, unlike a ${WORKSPACE_ROOT}/<name>
  # convention, assumes nothing about what the clone directory is called.
  local _primary="${PRIMARY_CHECKOUT:-}"
  if [[ -z "$_primary" ]]; then
    _primary="$($GIT -C "$REPO_ROOT" worktree list --porcelain 2>/dev/null \
                | /usr/bin/awk 'NR==1 && $1=="worktree" {print $2; exit}')"
  fi

  if [[ -z "$_primary" || ! -d "${_primary}/.git" ]]; then
    mark_phase "sync_primary_checkout" "SKIPPED" "primary checkout not resolvable${_primary:+ at $_primary} — nothing to sync (expected in CI and in a clean clone; hermetic no-op)"
    return 0
  fi

  # A linked worktree's .git is a FILE, not a directory, so the check above already
  # excludes them; this guards the degenerate "primary is me" case.
  if [[ "$_primary" == "$REPO_ROOT" ]]; then
    mark_phase "sync_primary_checkout" "SKIPPED" "resolved primary is this checkout — close-out is not running in a linked worktree; no sync to perform"
    return 0
  fi

  local _pbranch
  _pbranch="$($GIT -C "$_primary" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
  if [[ "$_pbranch" != "main" ]]; then
    mark_phase "sync_primary_checkout" "SKIPPED" "primary at ${_primary} is on '${_pbranch:-<detached>}', not main — fast-forwarding a non-main branch to origin/main would move work that was not asked to move; reporting, not forcing"
    return 0
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "sync_primary_checkout" "DRY-RUN" "would fetch origin main and fast-forward the primary checkout at ${_primary} (currently on main)"
    return 0
  fi

  if ! git_net -C "$_primary" fetch origin main --quiet 2>/dev/null; then
    mark_phase "sync_primary_checkout" "SKIPPED" "fetch origin main failed at ${_primary} (offline or credential-less) — primary left untouched"
    return 0
  fi

  # --ff-only is the whole safety contract: it refuses on a diverged primary, on a
  # dirty tree whose changes would be overwritten, and on conflicting local commits.
  # A refusal is a SKIP, never an escalation to a force.
  if $GIT -C "$_primary" merge --ff-only origin/main --quiet 2>/dev/null; then
    mark_phase "sync_primary_checkout" "PASS" "primary checkout at ${_primary} fast-forwarded to origin/main ($($GIT -C "$_primary" rev-parse --short HEAD 2>/dev/null || echo '?'))"
  else
    mark_phase "sync_primary_checkout" "SKIPPED" "primary at ${_primary} is not fast-forwardable (diverged, or a local change would be overwritten) — reporting, not forcing; sync it by hand per git-workflow.md § Primary Checkout Discipline"
  fi
  return 0
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

# ─── Phase 12.9: action_item_gate (Procedure 7a HARD GATE) ───────────────────
#
# THE DEFECT THIS CLOSES (#4439). Procedure 7a declares itself the HARD GATE that
# fires "BEFORE the Milestone-close PATCH (current Procedure 7 Step 5)". Nothing
# called it. Across this file's whole length there were ZERO references to action
# items, AI-NNN, or hub-state, and in the bridge document every `7a` occurrence sat
# inside 7a's own section — the gate was referenced only by itself. Milestone #304
# closed at 2026-08-01T11:30:58Z with the gate recorded SURFACED-not-RESOLVED and a
# ledger that did not yet exist; once built it carried six open rows.
#
# So the fix is not "run the gate earlier". It is: run the gate AT ALL, at a point
# where its BLOCK verdict makes the close structurally unreachable. This phase is
# dispatched immediately before phase_post_close_milestone, and the dispatcher's
# pre-existing `|| { generate_report; exit 3; }` guard supplies the fail-closed
# semantics — no new control flow is invented. The GUARD, not the ordering, is what
# makes the close unreachable: a line at the right position carrying `|| true`
# passes every position-only assertion while blocking nothing. Self-test group AI
# arm (F) therefore EXECUTES the two dispatch lines lifted verbatim from this
# file's own text, with a constructed `|| true` degenerate as its negative control.
#
# THREE-VALUED, DELIBERATELY (hub-action-tracking.md § 4 routing point 5). A gate
# that only counts unresolved rows cannot tell "every commitment was resolved" from
# "no commitment was ever recorded" — and a release that never emitted an action
# item is exactly the release whose emit step was skipped. Two counts over the
# whole population separate them:
#
#   NOT-RECORDED   ledger file absent          -> SURFACE (attestation required)
#   EMPTY-LEDGER   file present, 0 AI rows     -> SURFACE (attestation required)
#   RESOLVED       >=1 row, 0 open/in-flight   -> PASS  (the only silent pass)
#   UNRESOLVED     >=1 open or in-flight       -> BLOCK
#
# SURFACE IS ATTESTATION-GATED, NOT ATTESTATION-FREE. The decision table's rows 1-2
# end "-> requires explicit operator attestation to pass", and the same section
# states the attestation "is the discriminator: the operator states which of the two
# causes holds, and that attestation is itself emitted (`decision` /
# `empirical-verification-finding`, actor `operator`)". A SURFACE state that passes
# with no attestation input and emits no attestation row implements neither clause —
# and it is precisely the state #304 was in at close, so a gate that passed it
# silently would not have caught its own motivating incident. Hence:
# --attest-action-items <cause> is REQUIRED to pass a SURFACE state at --apply.
#
# States 1 and 2 still SURFACE rather than FAIL in the sense the spec means: the
# STATE is legitimate, and the operator clears it with one flag naming the cause.
# What is refused is the silent pass. The remedy is named verbatim in the FAIL
# detail, so the "a gate that fails a legitimate state gets routed around" risk is
# answered by a one-word remedy rather than by looking away.
#
# WHY WARN-MODE COULD NOT REST ON "ALL OF CI". An earlier form of this rationale
# argued that a blocking SURFACE state "would fail every CI close on day one". That
# population is EMPTY: `--apply` appears in zero workflow files, and every CI
# invocation of this script is --check-paths or --self-test. CI never executes the
# close path in any state. The corrected statement is the one that matters and is
# stronger: because CI never runs the close dispatch, the self-test fixture below is
# the ONLY automated execution this phase will ever get, which is exactly why it is
# four-armed, witness-backed, and executes the shipped dispatch text.
#
# NON-BLOCKING BY MODE, for reasons that each cost something to get wrong:
#   --dry-run    nothing closes, so a return 3 would abort a preview run. The detail
#                carries the literal "would BLOCK at --apply" (the :3385 precedent).
#   --no-merge   phase_post_close_milestone already DEFERS, so blocking would abort a
#                run whose close was deferred anyway. The gate evaluates and records.
#                It deliberately does NOT join the --no-merge deferred set — that set
#                is hand-enumerated at five sites this file's own comment warns about.
#   already-closed  an idempotent re-run must not fail. It records instead — and when
#                the recorded STATE is UNRESOLVED it NAMES that as the #304 shape,
#                turning the re-run into a detector for the originating incident.
#
# Offline, hermetic, no network and no `gh`: a read of one local markdown file plus
# two integer comparisons.

# Evaluate the Procedure 7a predicate over a hub-state directory.
# Emits "STATE TOTAL UNRES" on stdout. Never fails; an unreadable dir is
# NOT-RECORDED, which is a SURFACE state, never a silent pass.
#
# The awk program is the block shipped at hub-spoke-bridge.md § Procedure 7a,
# implemented here rather than sourced (that file is documentation, not a library).
# Self-test group AI arm (G) runs BOTH copies over the same fixtures and fails
# naming both sides if they ever diverge — the Check 68 `enum-parity` posture.
#
# TWO THINGS IN THAT awk INVOCATION ARE LOAD-BEARING AND LOOK LIKE STYLE:
#   FS is ' [|] ' — space, BRACKETED pipe, space. Do NOT "simplify" to ' \| ': awk
#   puts the -F value through string-escape processing first, which reduces \| to a
#   bare | (ERE alternation) and the row then splits on every space.
#   The split is on " | ", never on a bare '|'. GFM writes a literal pipe inside a
#   cell as \|, and description / owner / trigger_detail / target are all free-text
#   columns AHEAD of status — under -F'|' an escaped pipe shifts status off $11 and
#   the gate returns RESOLVED on an unresolved ledger.
_ai_eval_predicate() {
  local _dir="$1" _ai _t=0 _u=0 _state
  _ai="$_dir/action-items.md"
  if [[ ! -f "$_ai" ]]; then
    /usr/bin/printf 'NOT-RECORDED 0 0\n'
    return 0
  fi
  read -r _t _u <<<"$(/usr/bin/awk -F' [|] ' '
      $1 ~ /^\| *AI-[0-9]+ *$/ { t++; gsub(/ /,"",$11);
                                 if ($11=="open" || $11=="in-flight") u++ }
      END { print (t+0), (u+0) }' "$_ai" 2>/dev/null)"
  _t="${_t:-0}"; _u="${_u:-0}"
  if   [[ "$_t" -eq 0 ]]; then _state="EMPTY-LEDGER"
  elif [[ "$_u" -gt 0 ]]; then _state="UNRESOLVED"
  else                         _state="RESOLVED"
  fi
  /usr/bin/printf '%s %s %s\n' "$_state" "$_t" "$_u"
}

# Resolve this release's hub-state directory per the orchestration-playbook § 4a.3
# resolver: slug-keyed FIRST, version-keyed as a READ-ONLY legacy fallback. The
# writer creates only the slug form, so the version form is read and never created.
# Emits the resolved directory on stdout; falls back to the slug form (which then
# reads NOT-RECORDED) when neither exists, so the diagnostic names a real intent.
_ai_resolve_dir() {
  local _slugdir="" _verdir=""
  [[ -n "$STATE_MILESTONE_SLUG" ]] && _slugdir="${HUB_STATE_PATH}/${STATE_MILESTONE_SLUG}"
  [[ -n "$VERSION" ]] && _verdir="${HUB_STATE_PATH}/${VERSION}"
  if [[ -n "$_slugdir" && -d "$_slugdir" ]]; then /usr/bin/printf '%s' "$_slugdir"; return 0; fi
  if [[ -n "$_verdir"  && -d "$_verdir"  ]]; then /usr/bin/printf '%s' "$_verdir";  return 0; fi
  /usr/bin/printf '%s' "${_slugdir:-$_verdir}"
}

# Emit the operator attestation the SURFACE clause requires. Sets STATE_AI_EMIT.
# Never aborts the run: an unwritable event log must not block a close the operator
# has legitimately attested — but the outcome is RECORDED either way, so "attested
# and durably traced" and "attested, trace failed" stay distinguishable outputs.
_ai_emit_attestation() {
  local _cause="$1" _slug="${STATE_MILESTONE_SLUG:-$VERSION}"
  if [[ ! -x "$AI_EVENT_WRITER" ]]; then
    STATE_AI_EMIT="failed:writer-not-executable"
    return 0
  fi
  if [[ "$MODE" == "dry-run" ]]; then
    STATE_AI_EMIT="dry-run"
    return 0
  fi
  if "$AI_EVENT_WRITER" --version "$_slug" --stage 13 \
       --event-type decision --event-subtype empirical-verification-finding \
       --actor operator --subject "milestone:#${MILESTONE}" \
       --payload "procedure-7a-attestation; state:${STATE_AI_GATE}; attested-cause:${_cause}" \
       >/dev/null 2>&1; then
    STATE_AI_EMIT="emitted"
  else
    STATE_AI_EMIT="failed:writer-returned-nonzero"
  fi
  return 0
}

# Render the Procedure 7a cell for Verification-table row 6 FROM THE GLOBALS Phase
# 12.9 set. A pure projection with no I/O and no predicate evaluation — that is the
# contract, not an implementation detail. phase_run_verification runs AFTER the
# milestone close, so any recomputation here would produce a verdict the close was
# never gated on: the #4439 ordering defect reintroduced one phase later, where it
# is harder to see. Self-test group AI arm (K) mutates STATE_AI_GATE and asserts the
# cell follows the global, plus asserts this file's own text carries no predicate
# evaluation inside phase_run_verification.
_ai_verification_cell() {
  local _attest=" (attestation required)"
  [[ -n "$ATTEST_ACTION_ITEMS" ]] && _attest=" (attested: ${ATTEST_ACTION_ITEMS}; emit=${STATE_AI_EMIT})"
  case "${STATE_AI_GATE:-}" in
    RESOLVED)      /usr/bin/printf 'RESOLVED (%s/%s)' "$STATE_AI_TOTAL" "$STATE_AI_TOTAL" ;;
    UNRESOLVED)    /usr/bin/printf 'BLOCKED (%s unresolved of %s)' "$STATE_AI_UNRES" "$STATE_AI_TOTAL" ;;
    NOT-RECORDED)  /usr/bin/printf 'SURFACED — NOT-RECORDED%s' "$_attest" ;;
    EMPTY-LEDGER)  /usr/bin/printf 'SURFACED — EMPTY-LEDGER%s' "$_attest" ;;
    *)             /usr/bin/printf 'UNVERIFIED (Procedure 7a gate did not run before this phase)' ;;
  esac
}

phase_action_item_gate() {
  # Evaluate FIRST, in every mode. The report carries a real verdict even on a
  # preview run, and the mode branches below decide only what to DO about it.
  local _dir _res _state _total _unres
  _dir="$(_ai_resolve_dir)"
  _res="$(_ai_eval_predicate "$_dir")"
  _state="${_res%% *}"; _res="${_res#* }"
  _total="${_res%% *}"; _unres="${_res##* }"

  STATE_AI_DIR="$_dir"
  STATE_AI_GATE="$_state"
  STATE_AI_TOTAL="$_total"
  STATE_AI_UNRES="$_unres"
  STATE_AI_EMIT="n/a"

  # TOKENISED, NEVER ABSOLUTE. The ledger lives under the operator-instance root, so
  # its absolute path embeds the operator's home directory — and this detail string
  # is rendered into the close-out report, which is pasted into a sub-task comment on
  # a PUBLIC repository. Name the surface by its registered token plus the key that
  # actually varies (the milestone slug); an operator debugging a resolution failure
  # needs the KEY, not the prefix, and the prefix is the part that must not ship.
  local _dirlabel="<OPERATOR_INSTANCE_HUB_STATE_PATH>/${_dir##*/}"

  # Is a BLOCK verdict allowed to halt the run at this call site?
  local _blocking=0
  [[ "$MODE" == "apply" && "$NO_MERGE" -eq 0 && "$STATE_MILESTONE_STATE" != "closed" ]] && _blocking=1

  local _mode_note=""
  if [[ "$MODE" == "dry-run" ]]; then
    _mode_note=" — would BLOCK at --apply"
  elif [[ "$NO_MERGE" -eq 1 ]]; then
    _mode_note=" — recorded, not blocking: --no-merge defers the milestone close"
  elif [[ "$STATE_MILESTONE_STATE" == "closed" ]]; then
    _mode_note=" — recorded, not blocking: milestone already closed. THIS IS THE #304 SHAPE — the close preceded the verdict; the rows below were never gated"
  fi

  case "$_state" in
    RESOLVED)
      mark_phase "action_item_gate" "PASS" "Procedure 7a: RESOLVED (${_unres}/${_total} unresolved of ${_total} recorded) — every action item dispositioned before milestone close"
      return 0
      ;;
    UNRESOLVED)
      # Enumerate the unresolved rows so the operator can act without re-reading
      # the ledger. Column-addressed exactly as the predicate is.
      local _rows
      _rows="$(/usr/bin/awk -F' [|] ' '
          $1 ~ /^\| *AI-[0-9]+ *$/ { s=$11; gsub(/ /,"",s);
            if (s=="open" || s=="in-flight") {
              id=$1; gsub(/[| ]/,"",id); ow=$6; gsub(/^ +| +$/,"",ow);
              tg=$9; gsub(/^ +| +$/,"",tg);
              printf "%s(owner:%s; trigger:%s) ", id, ow, tg } }' \
          "${_dir}/action-items.md" 2>/dev/null || true)"
      [[ -z "$_rows" ]] && _rows="(row enumeration returned empty — read ${_dirlabel}/action-items.md directly) "
      if [[ "$_blocking" -eq 1 ]]; then
        mark_phase "action_item_gate" "FAIL" "Procedure 7a HARD GATE: UNRESOLVED — ${_unres} of ${_total} action items still open/in-flight; milestone close BLOCKED until each is transitioned to done / cancelled / superseded: ${_rows}"
        return 3
      fi
      mark_phase "action_item_gate" "WARN" "Procedure 7a: UNRESOLVED — ${_unres} of ${_total} action items still open/in-flight${_mode_note}: ${_rows}"
      return 0
      ;;
    NOT-RECORDED|EMPTY-LEDGER)
      local _cause_text
      if [[ "$_state" == "NOT-RECORDED" ]]; then
        _cause_text="No action-item ledger exists for this release (looked in ${_dirlabel}). Either no commitments were made, or the Procedure 4a emit step was skipped."
      else
        _cause_text="The action-item ledger at ${_dirlabel} exists and carries zero AI rows — initialized, never appended. Either no commitments were made, or the Procedure 4a emit step was skipped."
      fi
      if [[ -n "$ATTEST_ACTION_ITEMS" ]]; then
        case "$ATTEST_ACTION_ITEMS" in
          no-commitments|emit-skipped) ;;
          *)
            mark_phase "action_item_gate" "FAIL" "Procedure 7a: --attest-action-items '${ATTEST_ACTION_ITEMS}' is not a licensed cause; the closed enum is no-commitments | emit-skipped (state ${_state})"
            return 3
            ;;
        esac
        _ai_emit_attestation "$ATTEST_ACTION_ITEMS"
        mark_phase "action_item_gate" "WARN" "Procedure 7a: ${_state} — SURFACED, attested by operator as '${ATTEST_ACTION_ITEMS}' (attestation-emitted=${STATE_AI_EMIT}); ${_cause_text}"
        return 0
      fi
      if [[ "$_blocking" -eq 1 ]]; then
        mark_phase "action_item_gate" "FAIL" "Procedure 7a HARD GATE: ${_state} — SURFACE states require explicit operator attestation to pass, and none was supplied. ${_cause_text} Re-run with --attest-action-items no-commitments (the release genuinely made none) or --attest-action-items emit-skipped (the emit step was missed); the attestation is itself emitted as a decision / empirical-verification-finding row. Milestone close BLOCKED until then"
        return 3
      fi
      mark_phase "action_item_gate" "WARN" "Procedure 7a: ${_state} — SURFACED, unattested${_mode_note}. ${_cause_text} Pass --attest-action-items no-commitments|emit-skipped to clear it"
      return 0
      ;;
  esac

  # Unreachable: _ai_eval_predicate emits one of four states. Fail loudly rather
  # than falling through to a silent 0 — an unrecognised state is the vacuity
  # shape this whole phase exists to refuse.
  mark_phase "action_item_gate" "FAIL" "Procedure 7a: predicate returned an unrecognised STATE '${_state}' — refusing to grade the close on a verdict this gate cannot read"
  return 3
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

  # Same resolver as the note frontmatter and the chore-PR body. This one is
  # interpolated into a comment posted onto a PUBLIC GitHub issue — permanent,
  # unrewritable content — so it gets the resolved path or a loudly-annotated one,
  # never a silently-wrong guess.
  local plan_ref
  if ! plan_ref="$(plan_ref_for_emit)"; then
    printf 'NOTICE: no plan file resolves for %s; the D-1 issue-close comment will name the expected home annotated as unresolved (see release/releases/plans/README.md § Disposition rule).\n' "$VERSION" >&2
  fi
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

  # 9 universal verification commands per hub-spoke-bridge.md Procedure 7 Step 4.
  # The count is stated once here and once on the mark_phase detail below; both
  # track the rendered row set, and both are reconciled against the doc's own two
  # statements of it. It read `5` against a render that already emitted 6 (the
  # Procedure-7a row landed without the prose being updated) — corrected rather
  # than incremented, so all four sites now agree on one number.
  local v_notes v_tag v_milestone v_log v_subs
  # notes_abs_path(), not a retyped flat path: the note this release actually
  # produced is the note this verification must stat, version-less included.
  v_notes="$([[ -f "$(notes_abs_path)" ]] && echo PASS || echo FAIL)"
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
  # Check 5 (#3587): OPEN_ISSUE_COUNT is a PRE-CLOSE snapshot, written once in
  # Phase 4 and never re-read — and Phase 14 (manual_close_release_issues) runs
  # immediately before this phase. Reading it here made every successful close
  # render `PARTIAL (N open)` for the very N issues the same run had just closed,
  # and that text propagates into the durable Gate-Passage Proof comment. Re-derive
  # at point of use, into LOCALS: 6 of the 7 OPEN_ISSUE_COUNT consumers legitimately
  # want the pre-close population (chore-PR "Deferred items", the `closed N/M`
  # denominator, the D-1 Manual-Close Candidates section, the JSON payload), so a
  # blanket refresh would trade a display bug for an erased audit record. The
  # re-read goes through collect_open_release_issues, NOT a raw query: stage
  # sub-tasks carry the release milestone and the Stage-13 sub-task is open by
  # construction at this moment, so an unfiltered read would render PARTIAL on every
  # run. Dry-run keeps the cached read — it closes nothing, so cached == live
  # (mirrors check 4 above).
  if [[ "$MODE" == "dry-run" ]]; then
    v_subs="$([[ "$OPEN_ISSUE_COUNT" -eq 0 ]] && echo PASS || echo "PARTIAL (${OPEN_ISSUE_COUNT} open)")"
  else
    # Declare first, assign second — `local x="$(cmd)"` masks cmd's exit status,
    # and this branch's whole point is discriminating query-failure from empty.
    local _v5_rc _v5_list _v5_count _v5_nums _v5_straggler _v5_all_ours
    _v5_rc=0
    collect_open_release_issues "$slug" || _v5_rc=1
    _v5_list="$COLLECTED_OPEN_ISSUES"

    # D-4 bounded replication-lag guard: `gh issue close` writes via REST while
    # `gh issue list` reads via GraphQL, so the re-read is not guaranteed
    # read-after-write and could reproduce a smaller instance of the very bug this
    # fixes. Retry ONCE, and only when every straggler is an issue this run just
    # attempted to close — a straggler outside that set is real news, report it now.
    if [[ "$_v5_rc" -eq 0 && -n "$_v5_list" ]]; then
      _v5_all_ours=1
      while IFS= read -r _v5_straggler; do
        [[ -z "$_v5_straggler" ]] && continue
        /usr/bin/printf '%s\n' "$OPEN_ISSUE_LIST" | /usr/bin/grep -qx "$_v5_straggler" \
          || { _v5_all_ours=0; break; }
      done <<< "$_v5_list"
      if [[ "$_v5_all_ours" -eq 1 ]]; then
        /bin/sleep "${VERIFY_RECHECK_DELAY:-2}"
        collect_open_release_issues "$slug" || _v5_rc=1
        _v5_list="$COLLECTED_OPEN_ISSUES"
      fi
    fi

    if [[ "$_v5_rc" -ne 0 ]]; then
      # Fail closed. UNVERIFIED, not FAIL: a query that could not run establishes
      # nothing about whether issues are open — but it must never read as PASS.
      v_subs="UNVERIFIED (post-close re-query failed)"
    elif [[ -z "$_v5_list" ]]; then
      v_subs="PASS"
    else
      _v5_count="$(/usr/bin/printf '%s\n' "$_v5_list" | /usr/bin/grep -c .)"
      _v5_nums="$(/usr/bin/printf '%s' "$_v5_list" | /usr/bin/tr '\n' ',' | /usr/bin/sed 's/,$//')"
      # Enumerate the numbers so the operator can act without re-querying.
      v_subs="PARTIAL (${_v5_count} open: #${_v5_nums//,/, #})"
    fi
  fi

  # Row 6 — Procedure 7a composition clause (hub-spoke-bridge.md § Procedure 7a):
  # "Procedure 7 Step 4's Verification table SHALL include a row carrying the
  # resolved STATE, not a bare PASS/FAIL."
  #
  # IT RENDERS THE GLOBALS PHASE 12.9 SET. It does NOT recompute. This is the whole
  # point: this phase runs AFTER the milestone close, so a verdict re-derived here
  # would be a verdict the close was never gated on — the exact ordering defect
  # #4439 exists to close, reintroduced one phase later and harder to see.
  local v_ai; v_ai="$(_ai_verification_cell)"

  # Rows 7-9 — the close-out output-set members (#5288). RENDERED from the Phase
  # 9.56 record, never recomputed: 9.56 is the pre-commit moment the close was
  # gated on. Their presence here is the point — these three outputs were absent
  # from the lane-1 verification set for its whole life, which is exactly why
  # they were the three that went missing without a signal.
  local v_vel v_lrn v_cct
  v_vel="$(_output_set_verification_cell velocity-field)"
  v_lrn="$(_output_set_verification_cell learnings-block)"
  v_cct="$(_output_set_verification_cell close-class-telemetry)"

  VERIFICATION_RESULTS=$(/bin/cat <<EOF
| # | Check | Method | Result |
|---|-------|--------|--------|
| 1 | RELEASE_NOTES.md present | test -f release/releases/$(notes_rel_path) | ${v_notes} |
| 2 | Annotated tag present | git tag -l ${VERSION} | ${v_tag} |
| 3 | Milestone closed | gh api milestones/${MILESTONE} | ${v_milestone} |
| 4 | RELEASE_LOG row VERIFIED (corroborated by release-PR merge to main) | grep + gh pr view ${PR_NUMBER} | ${v_log} |
| 5 | All release issues closed | gh issue list --milestone | ${v_subs} |
| 6 | Action items resolved (Procedure 7a) | Phase 12.9 verdict, rendered not recomputed | ${v_ai} |
| 7 | Velocity field present (required) | Phase 9.56 output-set verdict, rendered not recomputed | ${v_vel} |
| 8 | Release Learnings block present (required) | Phase 9.56 output-set verdict, rendered not recomputed | ${v_lrn} |
| 9 | Close-Class-Telemetry field present (required-if telemetry-cutover-armed) | Phase 9.56 output-set verdict, rendered not recomputed | ${v_cct} |
EOF
)

  mark_phase "run_verification" "PASS" "9 universal checks evaluated"

  # ── Gate-passage proof: three-rung target ladder (#3819) ───────────────────
  #
  # This phase used to be an unconditional `mark_phase … MANUAL`: it did not FAIL
  # to find a Stage-13 sub-task, it never LOOKED. A MANUAL that never attempted a
  # target is indistinguishable from one where both targets were genuinely
  # unavailable, which is why milestone #264's close-out reported MANUAL with no
  # signal that its gate sub-tasks were detached from the milestone.
  #
  #   rung 1  Stage-13 Close sub-task in the milestone, ANY state  (primary)
  #   rung 2  the release PR                                       (fallback)
  #   rung 3  MANUAL — names BOTH attempted targets and EACH observed failure,
  #           with the full proof text still carried in the report (non-fatal)
  local _r1 _s13_num _s13_state _s13_reason _rest _closed_note _body _post_err
  _r1="$(resolve_stage13_subtask "$slug")"
  _s13_num="${_r1%%$'\t'*}"
  _rest="${_r1#*$'\t'}"
  _s13_state="${_rest%%$'\t'*}"
  _s13_reason="${_rest#*$'\t'}"
  _closed_note=""
  [[ "$_s13_state" == "CLOSED" ]] && _closed_note=" (closed)"

  if [[ "$MODE" == "dry-run" ]]; then
    if [[ -n "$_s13_num" ]]; then
      mark_phase "post_gate_passage_proof" "DRY-RUN" "would post gate-passage proof to Stage 13 sub-task #${_s13_num}${_closed_note} (rung 1)"
    elif [[ -n "$PR_NUMBER" ]]; then
      mark_phase "post_gate_passage_proof" "DRY-RUN" "would post gate-passage proof to release PR #${PR_NUMBER} (fallback rung 2); Stage-13 sub-task ${_s13_reason}"
    else
      mark_phase "post_gate_passage_proof" "DRY-RUN" "no target resolvable — Stage-13 sub-task ${_s13_reason}; release PR number empty; would emit comment text in the report (rung 3)"
    fi
    return 0
  fi

  _body="$(/bin/cat <<EOF
## Gate-Passage Proof — ${VERSION} Stage 13 Close

**Recorded at:** $(ts_now)
**Milestone:** ${slug}
**Release-PR merge SHA:** ${MERGE_SHA:-<unresolved>}

### Verification

${VERIFICATION_RESULTS}
EOF
)"

  # Rung 1 — the Stage-13 sub-task, any state.
  if [[ -n "$_s13_num" ]]; then
    if _post_err="$($GH issue comment "$_s13_num" --repo "$REPO_SLUG" --body "$_body" 2>&1)"; then
      mark_phase "post_gate_passage_proof" "PASS" "posted to Stage 13 sub-task #${_s13_num}${_closed_note}"
      return 0
    fi
    _s13_reason="post to #${_s13_num} failed: $(/usr/bin/printf '%s' "$_post_err" | /usr/bin/head -1 | /usr/bin/tr '\t|' '  ')"
  fi

  # Rung 2 — the release PR, with the OBSERVED rung-1 reason recorded in the body.
  if [[ -n "$PR_NUMBER" ]]; then
    if _post_err="$($GH pr comment "$PR_NUMBER" --repo "$REPO_SLUG" \
        --body "_Fallback target (rung 2): the Stage-13 sub-task ${_s13_reason}._

${_body}" 2>&1)"; then
      mark_phase "post_gate_passage_proof" "PASS" "Stage-13 sub-task ${_s13_reason}; posted to release PR #${PR_NUMBER} (fallback rung 2)"
      return 0
    fi
    mark_phase "post_gate_passage_proof" "MANUAL" "both targets attempted and failed — Stage-13 sub-task: ${_s13_reason}; release PR #${PR_NUMBER}: $(/usr/bin/printf '%s' "$_post_err" | /usr/bin/head -1 | /usr/bin/tr '\t|' '  '); comment text emitted in final report"
    return 0
  fi

  # Rung 3 — terminal, reasoned: name both attempted targets and each observation.
  mark_phase "post_gate_passage_proof" "MANUAL" "both targets attempted — Stage-13 sub-task: ${_s13_reason}; release PR: number unresolved at read-state; comment text emitted in final report"
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
# ASSERT AT --apply, PREDICT AT --dry-run (#4765 convention, applied here by #5142).
# All three preflights below used to run in BOTH modes, above the mode test. Their
# inputs do not exist at dry-run time and cannot: the tag is pushed at Stage 12 Phase
# B3, and phase_scaffold_release_notes deliberately writes no note under --dry-run. So
# every dry-run aborted on this script's own no-op, the runner exited 3, and no phase
# after this one enumerated — the identical defect #4765 fixed at 9.55, with the
# identical consequence for the dry-run review gate stage-13-close.md Phase A8
# mandates. The preflights are correct and are kept byte-for-byte; only their
# mode-blindness was the defect. --dry-run PREDICTS them and returns 0.
#
# The prediction is STATIC. It states what --apply will assert; it does not
# pre-evaluate any of it. Do NOT "improve" it by having the dry-run limb compute a
# result — a dry-run that reaches a remote or stats the note is the mode-blindness
# defect wearing a different shape.
#
# Residual, accepted and named: --dry-run no longer PREVIEWS a publish failure on the
# case where the inputs DO exist (a close resumed after the tag and note landed). The
# gate loses nothing — all three preflights still run at --apply, before anything is
# published, and Phases 15.55/15.6 remain the post-emit detectors.
#
# ORDERING: the --no-merge deferral above stays ABOVE the mode test on purpose. Under
# --no-merge the --apply behaviour is to defer, so predicting a publish there would be
# a false prediction. The mode test belongs above the three ABORTING preflights, which
# is where it now is — not at the literal first line.
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

  # DRY-RUN branch — deliberately above all three aborting preflights, so the apply
  # path below is reached with exactly the control flow it had before. Detail carries
  # no '|' so it cannot break the markdown phase table in --markdown reports.
  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "publish_github_release" "DRY-RUN" "would invoke view-then-create-or-edit state machine: gh release view $VERSION → create OR edit OR no-op (per release-notes-standard.md § 5.5). Not evaluated under --dry-run: the tag-on-origin, tag↔merge-SHA and notes-file preflights. Their inputs do not exist yet — Stage 12 Phase B3 has not pushed the tag and the scaffold phase deliberately wrote no note — so checking them here would only fail on this script's own no-op. All three run for real at --apply, before anything is published"
    return 0
  fi

  local notes_path; notes_path="$(notes_abs_path)"

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
      # Post-merge ancestry repair (#1682 follow-on). A release PR merged with the
      # wrong strategy can be repaired after the fact — revert the squash, re-merge
      # with --no-ff — which restores per-issue rollback and leaves the tag at a
      # DESCENDANT of the release-PR merge commit with an IDENTICAL tree. That is
      # not a wrong-commit binding: MERGE_SHA is in the tag's own history and the
      # content is byte-identical, so a Release cut at the tag ships exactly the
      # reviewed bytes with strictly better ancestry. Accept EXACTLY that case;
      # any other divergence still blocks. Both limbs are required — descendancy
      # alone would admit a tag carrying later commits.
      local repair_ancestor=1 repair_identical=1
      git_net -C "$REPO_ROOT" merge-base --is-ancestor "$MERGE_SHA" "$tag_sha" 2>/dev/null || repair_ancestor=0
      [[ -z "$(git_net -C "$REPO_ROOT" diff --name-only "$MERGE_SHA" "$tag_sha" 2>/dev/null)" ]] || repair_identical=0
      if [[ "$repair_ancestor" -eq 1 && "$repair_identical" -eq 1 ]]; then
        mark_phase "publish_github_release" "WARN" "tag $VERSION points at $tag_sha, a DESCENDANT of the release-PR merge commit $MERGE_SHA with an identical tree — accepted as a post-merge ancestry repair (#1682 follow-on), not a wrong-commit binding; publishing at the tag"
      else
        mark_phase "publish_github_release" "FAIL" "tag $VERSION points at $tag_sha, not the release-PR merge commit $MERGE_SHA — identity mismatch (#1682); do NOT publish a Release bound to the wrong commit (re-cut the tag at the merge SHA, or re-verify the release PR). Descendant-of-merge=$repair_ancestor identical-tree=$repair_identical"
        return 3
      fi
    fi
  fi

  # Preflight 2: notes file should be resolvable (warning, not blocker)
  if [[ ! -f "$notes_path" ]]; then
    mark_phase "publish_github_release" "FAIL" "RELEASE_NOTES file not present at $notes_path (Stage 13 chore PR may not have merged or scaffold step may not have run)"
    return 3
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

# ─── Phase 15.55: assert_anchor_hygiene (AC4 + AC5) ──────────────────────────
#
# Every shipped release is anchored by three artifacts that must agree: an ANNOTATED
# git tag, a published GitHub Release, and a row in each of RELEASE_INDEX/RELEASE_LOG.
# Nothing asserted that they stay in step, and the drift that resulted is invisible to
# a count: there are 143 annotated tags and 143 published Releases, and the sets are
# NOT equal — two tags have no Release, and two Releases sit on lightweight tags. A
# count comparison grades that PASS. This guard is therefore SET-based, and must stay
# set-based; regressing it to `wc -l` reintroduces the exact false negative it exists
# to remove.
#
# EXEMPTION SETS, NOT A BARE GUARD. Four parity divergences and one tagger-hygiene
# violation exist today. A bare guard would fail on merge, and the platform does not
# ship red CI. Each known divergence is listed below WITH its date and reason, so the
# guard blocks every NEW divergence while the recorded ones stand. Remediating them is
# separately owned: publishing the two missing Releases is a public-surface mutation,
# and re-tagging v3.80 force-updates a published tag (EXPENSIVE, operator-gated).
# Neither is performed here. The idiom follows the linter's existing
# PRE_CUTOVER_EXEMPT_VERSIONS / NOTE_LINK_EXEMPT_VERSIONS sets rather than inventing a
# new suppression mechanism.
#
# Recorded 2026-07-30. Removing an entry once its divergence is remediated is the
# intended lifecycle — these are not permanent.
ANCHOR_PARITY_EXEMPT_TAGS=(
  v3.31    # annotated tag, no published GitHub Release; Release-publication routed out of this card
  v3.65.1  # annotated tag, no published GitHub Release; Release-publication routed out of this card
  v3.28    # published Release sitting on a LIGHTWEIGHT tag; re-tag is operator-gated
  v3.29    # published Release sitting on a LIGHTWEIGHT tag; re-tag is operator-gated
)
TAGGER_HYGIENE_EXEMPT_TAGS=(
  v3.80    # annotated tag whose tagger is the placeholder identity `t <t@t>`; the fix
           # force-updates a tag that a published Release points at (EXPENSIVE) and is
           # a discrete operator decision, deliberately not executed by close-out
)

# Emits the annotated tags (one per line, sorted) of the repo at $1.
# `%(objecttype)` filtering is the load-bearing part: a LIGHTWEIGHT tag has
# objecttype `commit` and carries no tagger at all, so an unfiltered probe mixes two
# different defect classes and cannot be driven to empty.
annotated_tags_of() {
  $GIT -C "$1" for-each-ref refs/tags --format='%(objecttype) %(refname:short)' 2>/dev/null \
    | /usr/bin/awk '$1=="tag"{print $2}' | /usr/bin/sort
}

# AC5 — emits annotated tags whose tagger identity is neither a GitHub noreply address
# nor an accepted exemption. Reads the repo at $1.
tagger_hygiene_violations() {
  local exempt; exempt="$(/usr/bin/printf '%s\n' "${TAGGER_HYGIENE_EXEMPT_TAGS[@]}" | /usr/bin/sort -u)"
  local line name
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    name="$(/usr/bin/printf '%s' "$line" | /usr/bin/awk '{print $2}')"
    if /usr/bin/printf '%s\n' "$exempt" | /usr/bin/grep -qxF "$name"; then continue; fi
    /usr/bin/printf 'TAGGER-IDENTITY %s\n' "$line"
  done < <($GIT -C "$1" for-each-ref refs/tags --format='%(objecttype) %(refname:short) %(taggeremail)' 2>/dev/null \
           | /usr/bin/awk '$1=="tag"' | /usr/bin/grep -v 'users.noreply.github.com' || true)
}

# AC4 — emits the two-way set difference between the annotated-tag list in file $1 and
# the published-Release tag list in file $2, minus the recorded exemptions. Both files
# must be sorted. Taking files (not live probes) is what makes this testable offline:
# the self-test drives it with fixtures, no gh and no network.
anchor_parity_violations() {
  local ann_file="$1" rel_file="$2"
  local exempt; exempt="$(/usr/bin/printf '%s\n' "${ANCHOR_PARITY_EXEMPT_TAGS[@]}" | /usr/bin/sort -u)"
  local t
  while IFS= read -r t; do
    [[ -z "$t" ]] && continue
    if /usr/bin/printf '%s\n' "$exempt" | /usr/bin/grep -qxF "$t"; then continue; fi
    /usr/bin/printf 'MISSING-RELEASE %s (annotated tag with no published GitHub Release)\n' "$t"
  done < <(/usr/bin/comm -23 "$ann_file" "$rel_file")
  while IFS= read -r t; do
    [[ -z "$t" ]] && continue
    if /usr/bin/printf '%s\n' "$exempt" | /usr/bin/grep -qxF "$t"; then continue; fi
    /usr/bin/printf 'MISSING-ANNOTATED-TAG %s (published GitHub Release with no annotated tag)\n' "$t"
  done < <(/usr/bin/comm -13 "$ann_file" "$rel_file")
}

# #5268 — the ONE bounded --dry-run state in which an INDEX/LOG version-row gap is
# this script's own no-op rather than corpus drift, and is therefore PREDICTED
# rather than reported. Returns 0 to predict, 1 to report. Emits nothing.
# Args: <idx_count> <log_count> <index_file> <log_file> <version> <mode>
#
# ASSERT AT --apply, PREDICT AT --dry-run (#4765 convention). Phase 15.55 had NO
# mode branch at all, and this limb is structurally off-by-one on every first
# close: Stage 12 Phase B5 lands the RELEASE_LOG row BEFORE close-out runs
# (phase_preflight hard-FAILs without it), while the RELEASE_INDEX row is added by
# phase_append_release_index at 8.x — which deliberately writes nothing under
# --dry-run. So at --dry-run _idx == _log - 1 BY CONSTRUCTION, a finding
# accumulated, the phase returned 1, and the runner exited 3 one phase-group short
# of Phase 16. Fixing 9.5 alone only MOVED the halt here.
#
# This is the V4 per-limb downgrade shape (phase_preflight, phase_assert_output_set),
# NOT the 9.55/15.5 whole-phase relocation, and the difference is load-bearing: the
# tagger-identity and tag<->Release limbs are mode-INVARIANT and must keep running
# at --dry-run. Only this limb is scoped, and it is scoped as a CONJUNCTION bounded
# to the exact state the no-op produces — never a mode-wide suppression. Predict
# only when ALL FOUR hold:
#
#   (1) MODE is dry-run
#   (2) the gap is EXACTLY one row, with LOG ahead of INDEX
#   (3) the RELEASE_LOG carries a version row for THIS version (Stage 12 wrote it)
#   (4) the RELEASE_INDEX carries NO row for THIS version (8.x adds it at --apply)
#
# Any other gap — two rows, INDEX ahead, a one-row gap that is not this version's,
# or ANY gap at --apply — reports exactly as before. Version-less releases fall out
# on (3): neither ledger's version-row regex matches a slug key, so the counts do
# not move and the limb never fires for them either way.
#
# Takes both ledger paths and the version as ARGUMENTS rather than reading the
# globals, for the same reason anchor_parity_violations takes files: the self-test
# drives every leg from fixtures, offline, with no close-out state.
ledger_gap_is_this_close() {
  local _i="$1" _l="$2" _idx_file="$3" _log_file="$4" _ver="$5" _mode="$6"
  [[ "$_mode" == "dry-run" ]] || return 1
  [[ "$_i" =~ ^[0-9]+$ && "$_l" =~ ^[0-9]+$ ]] || return 1
  (( _l - _i == 1 )) || return 1
  # Row keys in the two ledgers' OWN shipped idioms — find_log_row's first-column
  # match for the LOG, phase_append_release_index's idempotency regex for the INDEX
  # — so a schema change moves all three together rather than leaving this behind.
  /usr/bin/grep -qE "^\| ${_ver//./\\.}(-[a-z0-9.-]+)? \|" "$_log_file" 2>/dev/null || return 1
  ! /usr/bin/grep -qE "^\|[[:space:]]*${_ver//./\\.}([[:space:]]+\(version-less\))?[[:space:]]*\|" "$_idx_file" 2>/dev/null || return 1
  return 0
}

phase_assert_anchor_hygiene() {
  local findings="" tmp
  tmp="$(/usr/bin/mktemp -d -t anchorhygiene.XXXXXX)"

  # (1) AC5 — tagger identity on annotated tags. Offline; always runs.
  local _tg; _tg="$(tagger_hygiene_violations "$REPO_ROOT")"
  [[ -n "$_tg" ]] && findings="${findings}${_tg}"$'\n'

  # (2) AC4a — INDEX/LOG row parity. Offline; always runs. COMPUTED, never hardcoded:
  # a sibling card backfills ledger rows in this same release, so a pinned magnitude
  # would go stale inside one merge.
  local _idx _log _parity_pred=""
  # grep_count, never a raw count with an appended fallback: that shape captures
  # `0\n0` on a present-but-empty ledger, which makes the `-ne` below throw and
  # evaluate FALSE, silently taking the PASS branch (#3113 QA F-QA-3).
  _idx="$(grep_count -E '^\|[[:space:]]*v[0-9]' "$RELEASE_INDEX")"
  _log="$(grep_count -E '^\|[[:space:]]*v[0-9]+\.[0-9]+' "$RELEASE_LOG")"
  if [[ "$_idx" -ne "$_log" ]]; then
    # #5268 — PREDICT the one bounded dry-run gap this close would itself close;
    # REPORT every other gap, in both modes. See ledger_gap_is_this_close above.
    if ledger_gap_is_this_close "$_idx" "$_log" "$RELEASE_INDEX" "$RELEASE_LOG" "$VERSION" "$MODE"; then
      _parity_pred="; LEDGER-ROW-PARITY PREDICTED not asserted under --dry-run — the single missing INDEX row is ${VERSION}'s own, and phase_append_release_index adds it at --apply while deliberately writing nothing here, so the gap is this script's own no-op. Parity is asserted for real at --apply, after the 8.x append lands"
    else
      findings="${findings}LEDGER-ROW-PARITY RELEASE_INDEX has ${_idx} version rows, RELEASE_LOG has ${_log}"$'\n'
    fi
  fi

  # (3) AC4b — annotated-tag <-> published-Release set parity. NETWORK. A gh failure is
  # SKIPPED-with-a-loud-reason, never a silent pass: "could not check" and "checked and
  # clean" must never render the same.
  local _net_note=""
  annotated_tags_of "$REPO_ROOT" > "$tmp/ann"
  if $GH release list --limit 400 --json tagName -q '.[].tagName' 2>/dev/null | /usr/bin/sort > "$tmp/rel" \
     && [[ -s "$tmp/rel" ]]; then
    local _ap; _ap="$(anchor_parity_violations "$tmp/ann" "$tmp/rel")"
    [[ -n "$_ap" ]] && findings="${findings}${_ap}"$'\n'
  else
    _net_note="; tag<->Release set parity NOT CHECKED (gh release list unavailable — offline or credential-less)"
  fi

  /bin/rm -rf "$tmp" 2>/dev/null || true

  if [[ -n "${findings//[$'\n']/}" ]]; then
    mark_phase "assert_anchor_hygiene" "FAIL" "release-anchor drift: $(/usr/bin/printf '%s' "$findings" | /usr/bin/tr '\n' ' ' | /usr/bin/sed 's/  */ /g')— a NEW divergence appeared outside the recorded exemption sets; reconcile the anchors before closing"
    /usr/bin/printf '%s' "$findings" >&2
    return 1
  fi

  # Same idiom, same fix: an empty tag list made this render as `0\n0` inside the
  # PASS/SKIPPED detail line (a mangled status message, not a wrong verdict).
  local _annn; _annn="$(grep_count . <<< "$(annotated_tags_of "$REPO_ROOT")")"
  # The parity clause must never claim `INDEX n == LOG n` on the predicted path —
  # the counts genuinely differ there, and a status line that says otherwise is the
  # plausible-looking wrong row this file rejects everywhere else.
  local _ledger_txt="INDEX ${_idx} == LOG ${_log} rows"
  [[ -n "$_parity_pred" ]] && _ledger_txt="INDEX ${_idx} vs LOG ${_log} rows${_parity_pred}"
  if [[ -n "$_net_note" ]]; then
    mark_phase "assert_anchor_hygiene" "SKIPPED" "offline assertions clean (${_annn} annotated tags; ${_ledger_txt})${_net_note}"
  else
    mark_phase "assert_anchor_hygiene" "PASS" "release anchors in step (${_annn} annotated tags; tag<->Release sets equal modulo ${#ANCHOR_PARITY_EXEMPT_TAGS[@]} recorded exemptions; ${_ledger_txt})"
  fi
  return 0
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
    mark_phase "pattern_scan" "N/A" "suppressed by --no-pattern-scan"
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

  # CAPTURE the report; do not discard it. The previous `>/dev/null` meant the
  # phase could only ever report an exit status — and the exit status is 0 whether
  # the scan finds 0 clusters or N, so "PASS" asserted nothing. The phase note now
  # carries the two COUNTS parsed out of the report body, and the body itself is
  # surfaced in the close-out report so the operator reads it at the same beat they
  # author the Phase-A7.2 register. Signal-only: this phase still gates nothing.
  local _scan_out _scan_rc _qual _near
  _scan_out="$("$SYNTHESIZE_LEARNINGS" --mode pattern-detect --window 5 2>&1)"
  _scan_rc=$?
  if [[ "$_scan_rc" -eq 0 ]]; then
    PATTERN_SCAN_REPORT="$_scan_out"
    _qual="$(/usr/bin/printf '%s\n' "$_scan_out" | /usr/bin/awk -F ':\\*\\* ' '/^\*\*Qualifying clusters/ { print $2; exit }')"
    _near="$(/usr/bin/printf '%s\n' "$_scan_out" | /usr/bin/awk -F ':\\*\\* ' '/^\*\*Near-threshold clusters/ { print $2; exit }')"
    mark_phase "pattern_scan" "PASS" \
      "qualifying=${_qual:-unparsed}, near-threshold=${_near:-unparsed} (dry-run default; no Issues created)"
    return 0
  fi
  mark_phase "pattern_scan" "FAIL" "synthesizer pattern-detect failed (rc=${_scan_rc})"
  return 3
}

# ─── Phase 16.7: audit_epic_rollup ───────────────────────────────────────────
#
# Third instance of the established signal-only pattern (phases 16 and 16.5):
# invoke a population-scoped detective tool, capture its report, gate nothing.
#
# Placed AFTER phases 13/14 have closed this release's issues and milestone, so
# the audit reads fresh state — an epic whose last child closed as part of THIS
# release is visible on this run rather than a release later.
#
# The audit is report-only by construction: it renders no close verdict, and its
# G2/G3 signals are operator-judgment annotations. This phase therefore never
# returns non-zero on findings; only a tool-level failure is a phase failure.

phase_audit_epic_rollup() {
  if [[ "$WITH_EPIC_AUDIT" -eq 0 ]]; then
    mark_phase "audit_epic_rollup" "N/A" "suppressed by --no-epic-audit"
    return 0
  fi

  if [[ ! -x "$AUDIT_EPIC_ROLLUP" ]]; then
    mark_phase "audit_epic_rollup" "SKIPPED" "audit-epic-rollup-close.sh not executable at $AUDIT_EPIC_ROLLUP"
    return 0
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    mark_phase "audit_epic_rollup" "DRY-RUN" "would invoke: $AUDIT_EPIC_ROLLUP --dry-run --markdown"
    return 0
  fi

  # CAPTURE the report; do not discard it. An exit status alone asserts nothing
  # here — the tool exits 0 whether it surfaces 0 candidates or 40 — so the phase
  # note carries the counts parsed out of the report body, and the body itself is
  # surfaced in the close-out report so the operator dispositions candidates at
  # the same beat they close the release.
  local _audit_out _audit_rc _clean _flagged
  _audit_out="$("$AUDIT_EPIC_ROLLUP" --dry-run --markdown 2>&1)"
  _audit_rc=$?
  if [[ "$_audit_rc" -eq 0 ]]; then
    EPIC_AUDIT_REPORT="$_audit_out"
    _clean="$(/usr/bin/printf '%s\n' "$_audit_out" | /usr/bin/awk -F '\\| ' '/^\| Clean candidates \|/ { gsub(/[^0-9]/,"",$3); print $3; exit }')"
    _flagged="$(/usr/bin/printf '%s\n' "$_audit_out" | /usr/bin/awk -F '\\| ' '/^\| Flagged candidates \|/ { gsub(/[^0-9]/,"",$3); print $3; exit }')"
    mark_phase "audit_epic_rollup" "PASS" \
      "clean-candidates=${_clean:-unparsed}, flagged-candidates=${_flagged:-unparsed} (report-only; no Issues closed)"
    return 0
  fi
  mark_phase "audit_epic_rollup" "FAIL" "audit-epic-rollup-close.sh returned non-zero (rc=${_audit_rc})"
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
**Chore PR:** $([[ -n "$CHORE_PR_NUMBER" ]] && echo "#${CHORE_PR_NUMBER}" || echo "N/A — dry-run or not-yet-created")

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
  # ── Phase-outcomes rows: DERIVED from the phase record, never enumerated ─────
  # Rows come from PHASE_NAMES/PHASE_RESULTS/PHASE_DETAILS, which mark_phase
  # writes at execution time. A phase added to the dispatch self-reports here with
  # no edit to this function. This replaced a hand-maintained `phases=()` array
  # that drifted twice (v4.12's 6.6/6.7, then 16.7) and was silently omitting
  # three recorded phases: inject_velocity_field, append_release_learnings,
  # audit_epic_rollup.
  #
  # SCOPE OF THAT CONTRACT — narrow on purpose. It holds for THIS table, not for
  # the report as a whole. Two partial phase enumerations remain hardcoded and DO
  # need hand-editing when a phase joins the --no-merge deferred set: the
  # "Deferred Under --no-merge" bullets further down in this function, and the
  # `deferred` literal in generate_json_report. Do NOT read this as "there is no
  # report list to edit" — there is; it is simply not this one.
  #
  # WHY THE RECORD AND NOT THE phase_*() DEFINITIONS: the record is the only
  # in-file surface that observes EXECUTION rather than declaration. A definition
  # scan silently drops post_gate_passage_proof, which is marked inside
  # phase_run_verification and has no phase_*() function of its own — which would
  # turn a three-phase omission into a one-phase omission that reads as fixed.
  #
  # WHERE THE CROSS-CHECK LIVES: deriving makes the record the sole input to this
  # audit table, so a dispatched phase that never calls mark_phase is silently
  # ABSENT. The dispatch<->record cross-check that catches that is a self_test arm,
  # and that placement is forced, not stylistic: the dispatch block sits BELOW the
  # "# ─── Argument parsing" banner and is therefore absent from the function-only
  # slice core/deploy/tests/test_version_stamping.sh sources, so a render-path
  # self-parse of the dispatch would read zero phases and go vacuous under exactly
  # the harness that exercises this file.
  #
  # Index-loop form is required: under bash 3.2 + set -u, "${PHASE_NAMES[@]}" on
  # an empty array yields one empty element. Arrays are read directly rather than
  # through get_phase, whose "RESULT|DETAIL" round-trip mis-splits any detail
  # containing a literal pipe.
  local _pr_i
  for ((_pr_i=0; _pr_i<${#PHASE_NAMES[@]}; _pr_i++)); do
    is_first_phase_occurrence "$_pr_i" || continue
    /usr/bin/printf '| %s | %s | %s |\n' \
      "${PHASE_NAMES[$_pr_i]}" "${PHASE_RESULTS[$_pr_i]}" "${PHASE_DETAILS[$_pr_i]}"
  done
  echo
  echo "Rows are the phases this run executed, in execution order. A phase absent from the table did not run — the table is a record of execution, not a declaration of the planned sequence. The full declared sequence is in \`--help\`."
  # A halted run states the fact of truncation, not just the semantics of absence.
  # 32 of the 33 in-run generate_report call sites are abort paths
  # (`phase_X || { generate_report; exit N; }`), so the truncated run is the
  # DOMINANT artifact a reader sees, and a derived table alone cannot separate
  # "did not run" from "does not exist". Derived purely from the record — no
  # second enumeration, no dispatch coupling. Honest bound: this fires only on a
  # FAIL-terminated run; a signal kill or a die() never reaches generate_report at
  # all, and no marker helps there.
  local _pr_last=$(( ${#PHASE_NAMES[@]} - 1 ))
  if [[ "$_pr_last" -ge 0 ]]; then
    if [[ "${PHASE_RESULTS[$_pr_last]}" == "FAIL" ]]; then
      echo
      echo "**Run halted** at \`${PHASE_NAMES[$_pr_last]}\` — phases after it did not execute."
    fi
  fi
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
  # Cross-release pattern scan (phase 16.5). The body is emitted here rather than
  # discarded, so the sub-threshold disposition is visible at the close beat: the
  # near-threshold band names the learnings that are one release short of the
  # unchanged auto-promotion threshold, and they are the input to the operator's
  # `Type (one-off / pattern)` + `Disposition` calls in the Phase-A7.2 register.
  # Signal-only — it gates nothing and files nothing.
  if [[ -n "$PATTERN_SCAN_REPORT" ]]; then
    echo "## Cross-Release Pattern Scan"
    echo
    echo "Signal-only (gates nothing, files nothing). Near-threshold rows are captured learnings that span >= 2 versions but sit below the auto-promotion threshold — record each one's disposition in the Phase-A7.2 learnings register (\`Type\` = one-off / pattern; \`Disposition\` = backlog issue # / carry-forward / accepted-residual)."
    echo
    /usr/bin/printf '%s\n' "$PATTERN_SCAN_REPORT"
    echo
  fi
  # Epic rollup-close audit (phase 16.7). Same discipline as the pattern scan: the
  # body is emitted rather than discarded, so the candidate list is in front of the
  # operator at the close beat. Signal-only — it closes nothing and files nothing;
  # G2 (true epic vs mislabelled initiative) and G3 (body scope shipped) are
  # annotations for operator judgment, not verdicts.
  if [[ -n "$EPIC_AUDIT_REPORT" ]]; then
    echo "## Epic Rollup-Close Audit"
    echo
    echo "Signal-only (gates nothing, closes nothing). Candidates are epics whose children have ALL reached a completed terminal state; flagged candidates additionally carry abandoned (\`NOT_PLANNED\`) or research-only children. Disposition is the operator's — close the epic, or decline it with a \`rollup-close-disposition\` comment so later runs skip it."
    echo
    /usr/bin/printf '%s\n' "$EPIC_AUDIT_REPORT"
    echo
  fi
  if [[ "$MODE" == "dry-run" ]]; then
    echo "**Next step:** review this dry-run report, then re-invoke with \`--apply\` to execute Phases 5-16."
  fi
}

generate_json_report() {
  local slug="$STATE_MILESTONE_SLUG"
  [[ -z "$slug" ]] && slug="$VERSION"
  # Phase outcomes for the JSON consumer, derived from the SAME phase record and
  # the SAME first-occurrence rule the markdown table uses — a `--json` reader had
  # zero phase visibility before this. Passed as flat argv triples rather than a
  # delimited blob so a detail containing a pipe, a tab or a newline cannot
  # desync the fields. argv[15] carries the triple COUNT, which (a) lets python
  # validate the operand count instead of trusting it and (b) keeps this array
  # non-empty, so no `"${ARR[@]}"`-on-empty guard is owed under set -u
  # (ADR-008 Rule 2 — explicit gate over the bash 4.2 `:+` substitution).
  local _pj_i _pj_n=0
  for ((_pj_i=0; _pj_i<${#PHASE_NAMES[@]}; _pj_i++)); do
    is_first_phase_occurrence "$_pj_i" || continue
    _pj_n=$((_pj_n+1))
  done
  local _pj_rec=("$_pj_n")
  for ((_pj_i=0; _pj_i<${#PHASE_NAMES[@]}; _pj_i++)); do
    is_first_phase_occurrence "$_pj_i" || continue
    _pj_rec+=("${PHASE_NAMES[$_pj_i]}" "${PHASE_RESULTS[$_pj_i]}" "${PHASE_DETAILS[$_pj_i]}")
  done
  /usr/bin/python3 - "$RUN_TS" "$MODE" "$PR_NUMBER" "$VERSION" "$MILESTONE" "$slug" \
    "$STATE_LOG_ROW_STATE" "$STATE_MILESTONE_STATE" "$STATE_TAG_EXISTS" \
    "$STATE_CYCLE_TIME" "$OPEN_ISSUE_COUNT" "$CHORE_PR_NUMBER" "$OPEN_ISSUE_LIST" "$NO_MERGE" \
    "${_pj_rec[@]}" <<'PY'
import sys, json
ts, mode, pr, version, milestone, slug, log_state, ms_state, tag, cycle, open_n, chore_pr, open_list, no_merge = sys.argv[1:15]
issues = [int(x) for x in open_list.split("\n") if x.strip()]
# Phase outcomes: argv[15] is the triple count, then flat (name, result, detail)
# triples. Fail loud on a count mismatch rather than emitting a truncated audit
# record that reads as complete.
_pn = int(sys.argv[15])
_pf = sys.argv[16:]
if len(_pf) != 3 * _pn:
    raise SystemExit("phase-record argv mismatch: declared %d triples, got %d operands" % (_pn, len(_pf)))
phases = [{"name": _pf[i], "result": _pf[i + 1], "detail": _pf[i + 2]} for i in range(0, len(_pf), 3)]
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
    "phases": phases,
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
  local _ai_saved_log="$RELEASE_LOG" _ai_saved_anchor="$CLOSEOUT_ANCHOR_UTC"
  local _ai_saved_repo_slug="$REPO_SLUG"
  local _ai_tmp; _ai_tmp="$(/usr/bin/mktemp -d -t appendidx-selftest.XXXXXX)"
  REPO_ROOT="$_ai_tmp"; MODE="apply"; VERSION="v9.97"; STATE_MILESTONE_SLUG="88-some-theme-named-milestone"; PR_NUMBER=9999
  # HERMETICITY — REPO_SLUG is a fixture input and must be PINNED, not inherited.
  # The emit phases below hand REPO_SLUG to the projector, which validates it as
  # owner/repo-shaped. This script's own resolution is env -> operator.toml ->
  # the bare literal `pmo-platform`, so on a developer machine (operator.toml
  # present) the ambient value is well-formed and every phase passes, while on a
  # hermetic runner (no env var, no config) it falls through to the bare literal,
  # the projector rejects it, and the phase returns non-zero. These calls are
  # bare under `set -euo pipefail`, so that aborted the ENTIRE self-test with
  # exit 3 and `self-test: starting` as its only output — a green local run and
  # a red CI run from one unpinned input. Pin it exactly as REPO_ROOT / MODE /
  # VERSION are pinned. `x/y` is the fixture-slug convention already used
  # elsewhere in this self-test and embeds no real repo name.
  REPO_SLUG="x/y"
  # Assert the pin took, in the shape the projector actually validates. This is
  # the limb that fails NAMED if a later edit drops the pin, instead of the
  # silent `set -e` abort that shipped it.
  [[ "$REPO_SLUG" == */* && "$REPO_SLUG" != */*/* && "$REPO_SLUG" != /* && "$REPO_SLUG" != */ ]] \
    || { echo "FAIL: the append-emit fixture must PIN an owner/repo-shaped REPO_SLUG rather than inherit ambient resolution (got '$REPO_SLUG')"; failures=$((failures+1)); }
  RELEASE_INDEX="$_ai_tmp/RELEASE_INDEX.md"; RELEASE_DIGEST="$_ai_tmp/RELEASE_DIGEST.md"
  RELEASE_LOG="$_ai_tmp/RELEASE_LOG.md"
  RELEASE_NOTES_DIR="$_ai_tmp/notes"   # absent dir => headline placeholder path
  # #3718 merge-anchor fixture. The LOG Date deliberately differs from BOTH the
  # close-out anchor and any plausible "today", so an INDEX row carrying it
  # proves the phase read the LOG rather than sampling the clock. The Date column
  # sits at a NON-terminal position here (Notes trails it) so the header-name pin
  # in extract_row_date is exercised rather than an incidental last-field guess.
  local _ai_log_date="2026-03-04"
  CLOSEOUT_ANCHOR_UTC="2026-09-09"   # deliberately != _ai_log_date
  /bin/cat > "$RELEASE_LOG" <<EOF
# RELEASE_LOG

| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date | Notes |
|---|---|---|---|---|---|---|---|---|
| v9.97 | 88-some-theme-named-milestone | #1 | #9999 | \`abc\` | \`v9.97\` | DEPLOYED | ${_ai_log_date} | — |
| 77-some-version-less-theme | 77-some-version-less-theme | #2 | #9998 | \`def\` | — | DEPLOYED | ${_ai_log_date} | — |
EOF
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
  # `|| true` so a non-zero return REPORTS on the next line instead of aborting
  # the whole self-test under `set -e` with no diagnostic. This is the first
  # emit-phase call in the run, so it is the one an unpinned fixture input
  # reaches first — the message below is what an operator sees instead of a bare
  # `self-test: starting` and exit 3.
  phase_append_release_digest >/dev/null 2>&1 || true
  [[ "$(get_phase append_release_digest)" == PASS\|* ]] || { echo "FAIL: phase_append_release_digest should PASS, got '$(get_phase append_release_digest)' (fixture REPO_SLUG='$REPO_SLUG' — an unpinned, non-owner/repo-shaped slug is rejected by the projector and fails this phase)"; failures=$((failures+1)); }
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
  # (b2) #3718 MERGE ANCHOR — the INDEX Date must equal the RELEASE_LOG Date, and
  # must NOT be the close-out anchor. This is the regression surface for the
  # writer/checker reconciliation: while this phase sampled the close-out clock,
  # generate_release_index.py --verify (deploy.sh Check 23) was red by
  # construction on every UTC-midnight-crossing close.
  local _ai_date; _ai_date="$(/usr/bin/printf '%s' "$_ai_row" | /usr/bin/awk -F ' \\| ' '{print $3}')"
  [[ "$_ai_date" == "$_ai_log_date" ]] || { echo "FAIL: INDEX Date must carry the MERGE anchor from the RELEASE_LOG row ($_ai_log_date), got '$_ai_date' in: $_ai_row"; failures=$((failures+1)); }
  [[ "$_ai_date" != "$CLOSEOUT_ANCHOR_UTC" ]] || { echo "FAIL: INDEX Date must NOT be the close-out anchor ($CLOSEOUT_ANCHOR_UTC) — the merge anchor is canonical for the LOG/INDEX pair"; failures=$((failures+1)); }
  # (b3) #3718 — DIGEST keeps the CLOSE-OUT anchor (the two anchors are distinct
  # by design; collapsing them would destroy the close-out instant).
  /usr/bin/grep -qE "^### v9\.97 \(${CLOSEOUT_ANCHOR_UTC}\)" "$RELEASE_DIGEST" \
    || { echo "FAIL: DIGEST H3 must carry the run-scoped CLOSE-OUT anchor ($CLOSEOUT_ANCHOR_UTC)"; failures=$((failures+1)); }
  # (b4) #3718 — unresolvable LOG Date must FAIL loudly, never fall back to the
  # clock. Point RELEASE_LOG at a row whose Date cell is malformed.
  local _ai_badlog="$_ai_tmp/RELEASE_LOG_bad.md" _ai_savedlog2="$RELEASE_LOG" _ai_savedidx2="$RELEASE_INDEX"
  /bin/cat > "$_ai_badlog" <<'EOF'
# RELEASE_LOG

| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |
|---|---|---|---|---|---|---|---|
| v9.95 | 86-bad | #3 | #9997 | `ghi` | `v9.95` | DEPLOYED | (unrecoverable) |
EOF
  RELEASE_LOG="$_ai_badlog"; RELEASE_INDEX="$_ai_tmp/RELEASE_INDEX_bad.md"
  /usr/bin/printf '# RELEASE_INDEX\n\n| Version | Milestone | Date | Theme | Release PR | Release Notes |\n|---|---|---|---|---|---|\n' > "$RELEASE_INDEX"
  local _ai_saved_v2="$VERSION"; VERSION="v9.95"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  # `|| true` per the existing self-test idiom — the phase now returns 3 on this
  # path by design, and `set -e` would otherwise abort the whole self-test.
  phase_append_release_index >/dev/null 2>&1 || true
  [[ "$(get_phase append_release_index)" == FAIL\|* ]] || { echo "FAIL: unresolvable RELEASE_LOG Date must FAIL append_release_index (no clock fallback), got '$(get_phase append_release_index)'"; failures=$((failures+1)); }
  ! /usr/bin/grep -qE '^\| v9\.95 \|' "$RELEASE_INDEX" || { echo "FAIL: a FAILed append_release_index must write no INDEX row"; failures=$((failures+1)); }
  VERSION="$_ai_saved_v2"; RELEASE_LOG="$_ai_savedlog2"; RELEASE_INDEX="$_ai_savedidx2"

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

  # (e) VERSIONED CHANGELOG emit (#4455) — the branch the version-less SKIP above
  # never reaches, and the one whose insertion arithmetic is most intricate
  # (Keep-a-Changelog: insert at the next H2 after `## [Unreleased]`). Asserts the
  # projected block lands with its own trailing blank line intact, so two release
  # entries do not run together, and that the projector — not this phase — is the
  # source of the summary and the close-out anchor.
  VERSION="v9.97"; STATE_MILESTONE_SLUG="88-some-theme-named-milestone"
  /bin/mkdir -p "$RELEASE_NOTES_DIR"
  /bin/cat > "${RELEASE_NOTES_DIR}/v9.97_RELEASE_NOTES.md" <<'EOF'
---
version: v9.97
date: 2026-09-09
summary: "A self-test summary line."
---
# A self-test headline
EOF
  /usr/bin/printf '# Changelog\n\n## [Unreleased]\n\n## [v9.96] - 2026-06-27\n\nprior\n\n' > "$_ai_tmp/CHANGELOG.md"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_append_changelog >/dev/null 2>&1 || true
  [[ "$(get_phase append_changelog)" == PASS\|* ]] || { echo "FAIL: versioned phase_append_changelog should PASS, got '$(get_phase append_changelog)'"; failures=$((failures+1)); }
  /usr/bin/grep -qE "^## \[v9\.97\] - ${CLOSEOUT_ANCHOR_UTC}\$" "$_ai_tmp/CHANGELOG.md" \
    || { echo "FAIL: CHANGELOG block must be '## [v9.97] - <close-out anchor>'"; failures=$((failures+1)); }
  /usr/bin/grep -q 'A self-test summary line.' "$_ai_tmp/CHANGELOG.md" \
    || { echo "FAIL: CHANGELOG block must carry the note frontmatter summary"; failures=$((failures+1)); }
  # The new block must sit ABOVE the prior entry, and a BLANK LINE must separate
  # them — a filter-shaped insertion loses that blank and runs the entries
  # together, which is a silent corruption of a durable artifact.
  local _cl_new _cl_prior
  _cl_new="$(/usr/bin/grep -n '^## \[v9\.97\]' "$_ai_tmp/CHANGELOG.md" | /usr/bin/head -1 | /usr/bin/cut -d: -f1)"
  _cl_prior="$(/usr/bin/grep -n '^## \[v9\.96\]' "$_ai_tmp/CHANGELOG.md" | /usr/bin/head -1 | /usr/bin/cut -d: -f1)"
  [[ -n "$_cl_new" && -n "$_cl_prior" && "$_cl_new" -lt "$_cl_prior" ]] \
    || { echo "FAIL: new CHANGELOG block (line ${_cl_new:-none}) must precede the prior entry (line ${_cl_prior:-none})"; failures=$((failures+1)); }
  [[ -n "$_cl_prior" ]] && [[ -z "$(/usr/bin/sed -n "$((_cl_prior - 1))p" "$_ai_tmp/CHANGELOG.md")" ]] \
    || { echo "FAIL: the projected CHANGELOG block must end with a blank line — two entries ran together"; failures=$((failures+1)); }
  # Idempotent re-run must SKIP, not duplicate.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_append_changelog >/dev/null 2>&1 || true
  [[ "$(get_phase append_changelog)" == SKIPPED\|* ]] || { echo "FAIL: versioned CHANGELOG re-run must SKIP, got '$(get_phase append_changelog)'"; failures=$((failures+1)); }
  # (f) REPO_SLUG well-formedness gate — a bare repo name must FAIL LOUDLY before
  # a permanently broken Release URL reaches a durable row.
  local _ai_saved_slug2="$REPO_SLUG"
  REPO_SLUG="pmo-platform"; VERSION="v9.97"
  /usr/bin/printf '# Changelog\n\n## [Unreleased]\n\n' > "$_ai_tmp/CHANGELOG.md"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_append_changelog >/dev/null 2>&1 || true
  [[ "$(get_phase append_changelog)" == FAIL\|* ]] || { echo "FAIL: a non-owner/repo-shaped REPO_SLUG must FAIL append_changelog, got '$(get_phase append_changelog)'"; failures=$((failures+1)); }
  # Assert against the malformed value UNDER TEST rather than a hardcoded literal:
  # the fixture sets REPO_SLUG above, so this tracks it and embeds no repo name.
  ! /usr/bin/grep -q "github.com/${REPO_SLUG}/" "$_ai_tmp/CHANGELOG.md" || { echo "FAIL: a FAILed append_changelog must write no broken Release URL"; failures=$((failures+1)); }
  REPO_SLUG="$_ai_saved_slug2"

  # (g) REACHABILITY OF THE DRY-RUN LIMB (#5268; #4765 convention; modelled on the
  # #5142 F-01-N pair at phase_publish_github_release). Phase 9.5's dry-run branch
  # used to sit BELOW the projector capture's `return 3`, so on a first close every
  # --dry-run aborted here before the mode was ever read and no phase after it
  # enumerated.
  #
  # These arms assert REACHABILITY, not presence. A presence check (does a
  # `MODE == dry-run` branch exist in this function?) passes on the DEFECTIVE code —
  # the branch was always there, just stranded below the abort. Each fixture is
  # therefore driven through BOTH modes: the dry arm must reach the limb and return
  # 0 with the literal outcome DRY-RUN, and the apply arm on the IDENTICAL fixture
  # must behave exactly as before. Without the apply arm the dry arm is satisfiable
  # by gutting the capture or by a fixture that does not actually omit what it
  # claims to omit; without the literal-DRY-RUN assertion it is satisfiable by a
  # vacuous PASS.
  local _cl_rc _cl_detail

  # Fixture N — NOTE ABSENT. This is the artifact phase_scaffold_release_notes
  # deliberately does not write under --dry-run, so on the real dry-run path the
  # projector capture fires on this script's own no-op. All four guards above the
  # mode test are satisfied here (versioned, CHANGELOG present, version absent from
  # it, REPO_SLUG owner/repo-shaped), so the capture is provably the abort under test.
  VERSION="v9.97"
  RELEASE_NOTES_DIR="$_ai_tmp/empty-notes"; /bin/mkdir -p "$RELEASE_NOTES_DIR"
  /usr/bin/printf '# Changelog\n\n## [Unreleased]\n\n' > "$_ai_tmp/CHANGELOG.md"
  # FIXTURE PRECONDITIONS — a fixture that failed to omit the note, or that already
  # carries the entry, would make both arms below pass for the wrong reason.
  [[ -z "$(/bin/ls -A "$RELEASE_NOTES_DIR" 2>/dev/null)" ]] || { echo "FAIL: F-9.5-N fixture — RELEASE_NOTES_DIR must be EMPTY; a present note exercises the wrong branch"; failures=$((failures+1)); }
  ! /usr/bin/grep -q '\[v9\.97\]' "$_ai_tmp/CHANGELOG.md" || { echo "FAIL: F-9.5-N fixture — the CHANGELOG must NOT already carry the entry, or the idempotency guard SKIPs above the mode test"; failures=$((failures+1)); }

  MODE="dry-run"; PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=(); _cl_rc=0
  phase_append_changelog >/dev/null 2>&1 || _cl_rc=$?
  [[ "$_cl_rc" -eq 0 ]] || { echo "FAIL: F-9.5-N-dry — under --dry-run the phase must reach its mode branch and return 0 when the note is absent (it is absent by construction; phase_scaffold_release_notes wrote nothing), got rc=$_cl_rc"; failures=$((failures+1)); }
  [[ "$(get_phase append_changelog | /usr/bin/cut -d'|' -f1)" == "DRY-RUN" ]] || { echo "FAIL: F-9.5-N-dry — the outcome must be literally DRY-RUN (a vacuous PASS also returns 0 and must not count), got '$(get_phase append_changelog)'"; failures=$((failures+1)); }
  ! /usr/bin/grep -q '\[v9\.97\]' "$_ai_tmp/CHANGELOG.md" || { echo "FAIL: F-9.5-N-dry — a --dry-run must write NOTHING to CHANGELOG.md"; failures=$((failures+1)); }

  MODE="apply"; PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=(); _cl_rc=0
  phase_append_changelog >/dev/null 2>&1 || _cl_rc=$?
  [[ "$_cl_rc" -ne 0 ]] || { echo "FAIL: F-9.5-N-apply anti-vacuity — the SAME note-absent fixture MUST still abort under --apply; rc=0 means the projector capture was gutted rather than mode-scoped, or the fixture is not actually missing the note"; failures=$((failures+1)); }
  _cl_detail="$(get_phase append_changelog)"
  /usr/bin/grep -qF 'release-corpus projector could not emit the CHANGELOG block' <<<"$_cl_detail" || { echo "FAIL: F-9.5-N-apply — the --apply failure message must be preserved verbatim (the apply limb is unchanged), got '$_cl_detail'"; failures=$((failures+1)); }

  # Fixture S — NOTE PRESENT, CHANGELOG entry absent: the resume-after-partial-apply
  # case, and the one where --apply genuinely succeeds. It pins the two constraints
  # the DRY-RUN detail carries. It must contain no '|' — the record is `RESULT|detail`
  # and --markdown renders it as a table row — and no literal `would FAIL`, the token
  # _output_set_dryrun_class reads to classify a producer would-absent, which this
  # phase is NOT (at --apply it writes). A future reword of the detail cannot
  # silently flip phase 9.56's output-set classification.
  RELEASE_NOTES_DIR="$_ai_tmp/notes"
  /usr/bin/printf '# Changelog\n\n## [Unreleased]\n\n' > "$_ai_tmp/CHANGELOG.md"
  [[ -f "${RELEASE_NOTES_DIR}/v9.97_RELEASE_NOTES.md" ]] || { echo "FAIL: F-9.5-S fixture — the v9.97 note must be PRESENT for the resume-case arms; without it this is fixture N again"; failures=$((failures+1)); }

  MODE="dry-run"; PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=(); _cl_rc=0
  phase_append_changelog >/dev/null 2>&1 || _cl_rc=$?
  [[ "$_cl_rc" -eq 0 ]] || { echo "FAIL: F-9.5-S-dry — with the note PRESENT the dry-run must still return 0, got rc=$_cl_rc"; failures=$((failures+1)); }
  _cl_detail="$(get_phase append_changelog)"
  [[ "${_cl_detail%%|*}" == "DRY-RUN" ]] || { echo "FAIL: F-9.5-S-dry — the outcome must be literally DRY-RUN, got '$_cl_detail'"; failures=$((failures+1)); }
  if /usr/bin/grep -qF 'would FAIL' <<<"$_cl_detail"; then
    echo "FAIL: F-9.5-S-dry — the DRY-RUN detail must NOT contain the literal 'would FAIL'; _output_set_dryrun_class reads that token and would classify the CHANGELOG output-set member would-absent, but --apply writes it"; failures=$((failures+1))
  fi
  [[ "$(/usr/bin/awk -F'|' '{print NF; exit}' <<<"$_cl_detail")" == "2" ]] || { echo "FAIL: F-9.5-S-dry — the RESULT|detail record must carry EXACTLY one '|'; a pipe inside the detail corrupts get_phase and the --markdown phase table, got '$_cl_detail'"; failures=$((failures+1)); }
  ! /usr/bin/grep -q '\[v9\.97\]' "$_ai_tmp/CHANGELOG.md" || { echo "FAIL: F-9.5-S-dry — a --dry-run must write NOTHING to CHANGELOG.md"; failures=$((failures+1)); }
  # SPECIFICITY CONTROL for the pipe arm: the probe must return >2 on a record that
  # genuinely carries an embedded pipe, or a broken awk would score every detail as
  # conformant and the arm above would be measuring nothing.
  [[ "$(/usr/bin/awk -F'|' '{print NF; exit}' <<<"DRY-RUN|a|b")" == "3" ]] || { echo "FAIL: F-9.5-S-dry control — the pipe-count probe does not detect an embedded pipe; the constraint arm above is vacuous"; failures=$((failures+1)); }

  # F-9.5-S-apply — the PREDICTION-IS-TRUE control. The dry arm above asserts the
  # phase predicts "would prepend"; this asserts that on the IDENTICAL fixture
  # --apply actually does prepend. Without it, "would prepend" could be a false
  # prediction over a fixture --apply cannot satisfy, and the whole pair would be
  # asserting reachability of a lie.
  MODE="apply"; PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=(); _cl_rc=0
  phase_append_changelog >/dev/null 2>&1 || _cl_rc=$?
  [[ "$_cl_rc" -eq 0 ]] || { echo "FAIL: F-9.5-S-apply — the resume-case fixture must PASS at --apply; the dry-run prediction 'would prepend' is only true if it does, got rc=$_cl_rc"; failures=$((failures+1)); }
  [[ "$(get_phase append_changelog | /usr/bin/cut -d'|' -f1)" == "PASS" ]] || { echo "FAIL: F-9.5-S-apply — the outcome must be PASS, got '$(get_phase append_changelog)'"; failures=$((failures+1)); }
  /usr/bin/grep -qE '^## \[v9\.97\] - ' "$_ai_tmp/CHANGELOG.md" || { echo "FAIL: F-9.5-S-apply — --apply must actually prepend the ## [v9.97] section the dry-run predicted"; failures=$((failures+1)); }

  MODE="$_ai_saved_mode"; VERSION="v9.97"; RELEASE_NOTES_DIR="$_ai_tmp/notes"

  /bin/rm -rf "$_ai_tmp" 2>/dev/null || true
  REPO_ROOT="$_ai_saved_root"; MODE="$_ai_saved_mode"; VERSION="$_ai_saved_version"
  REPO_SLUG="$_ai_saved_repo_slug"
  STATE_MILESTONE_SLUG="$_ai_saved_slug"; RELEASE_INDEX="$_ai_saved_idx"; RELEASE_DIGEST="$_ai_saved_dig"
  PR_NUMBER="$_ai_saved_pr"; RELEASE_NOTES_DIR="$_ai_saved_notesdir"
  RELEASE_LOG="$_ai_saved_log"; CLOSEOUT_ANCHOR_UTC="$_ai_saved_anchor"
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

  # (f)–(h) POST-ARCHIVAL two-surface resolution. After the sweep an aged-out
  # block's BODY lives in a same-directory `RELEASE_LOG_ARCHIVE-<family>.md`
  # segment and the hot ledger keeps only the heading plus a pointer. A separate
  # tmp dir so the segment glob cannot see, or be seen by, cases (a)–(e).
  local _oc_atmp; _oc_atmp="$(/usr/bin/mktemp -d -t outcome-archived.XXXXXX)"
  local _oc_aseg="$_oc_atmp/RELEASE_LOG_ARCHIVE-v9.md"
  local _oc_write_archived
  _oc_write_archived() {
    /bin/cat > "$RELEASE_LOG" <<'EOF'
# RELEASE_LOG

#### Deployment Log v9.93
_Archived: [segment](RELEASE_LOG_ARCHIVE-v9.md)_

#### Deployment Log v9.92
_Archived: [segment](RELEASE_LOG_ARCHIVE-v9.md)_
EOF
    /bin/cat > "$_oc_aseg" <<'EOF'
# RELEASE_LOG_ARCHIVE-v9

#### Deployment Log v9.93
**Mechanism:** git merge.
**Result:** SUCCESS — archived body.
**Velocity:** 2 issues.

#### Deployment Log v9.92
**Mechanism:** git merge.
**Velocity:** 1 issue.
EOF
  }
  RELEASE_LOG="$_oc_atmp/RELEASE_LOG.md"

  # (f) the body lives in a segment → PASS, and the Outcome lands in the SEGMENT
  # directly after its **Result:** line, with the hot ledger left untouched.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _oc_write_archived; VERSION="v9.93"; OUTCOME=""; OUTCOME_RATIONALE=""
  # `|| true`: a regression here returns 3, and a BARE call under `set -e` would
  # abort the whole self-test with `self-test: starting` as its only output. The
  # get_phase assertions below are the reporting surface.
  phase_inject_outcome_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_outcome_field)" == PASS\|* ]] || { echo "FAIL: archived-block inject should PASS, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  /usr/bin/grep -A1 -F '**Result:** SUCCESS — archived body.' "$_oc_aseg" | /usr/bin/grep -qFx '**Outcome:** SUCCESS' || { echo "FAIL: '**Outcome:** SUCCESS' must directly follow the **Result:** line in the archive segment"; failures=$((failures+1)); }
  [[ "$(/usr/bin/grep -c '^\*\*Outcome:\*\*' "$RELEASE_LOG")" -eq 0 ]] || { echo "FAIL: nothing may be injected into the hot ledger when the body is archived"; failures=$((failures+1)); }
  # and it must not leak into the sibling v9.92 block in the same segment
  /usr/bin/awk '/^#### Deployment Log v9\.92/{b=1} /^#### Deployment Log v9\.93/{b=0} b && /^\*\*Outcome:/{print "LEAK"}' "$_oc_aseg" | /usr/bin/grep -q LEAK && { echo "FAIL: Outcome leaked into the sibling v9.92 block in the segment"; failures=$((failures+1)); }

  # (g) idempotency ACROSS surfaces — the hazard a single-site fix would create.
  # The idempotency probe must read the SEGMENT (where the field now is), not the
  # hot ledger (where the stub is), or a re-run double-injects silently.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_inject_outcome_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_outcome_field)" == SKIPPED\|* ]] || { echo "FAIL: archived-block re-run must SKIP (cross-surface idempotency), got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  [[ "$(/usr/bin/grep -c '^\*\*Outcome:\*\*' "$_oc_aseg")" -eq 1 ]] || { echo "FAIL: archived-block re-run must not duplicate the **Outcome:** line in the segment"; failures=$((failures+1)); }

  # (h) a GENUINE absence still fails, and names the surfaces it searched. v9.92
  # exists on both surfaces but never carried a **Result:** field — segment
  # awareness cannot recover a field that was never written, so this must stay a
  # hard failure rather than degrade into a silent success.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _oc_write_archived; VERSION="v9.92"; OUTCOME=""; OUTCOME_RATIONALE=""
  if phase_inject_outcome_field >/dev/null 2>&1; then
    echo "FAIL: a version whose **Result:** field genuinely does not exist must FAIL"; failures=$((failures+1))
  fi
  [[ "$(get_phase inject_outcome_field | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: genuine **Result:** absence must mark FAIL"; failures=$((failures+1)); }
  # Assert the RESOLVER-MISS diagnostic specifically, not merely that some
  # message carried a surface list. A resolver that silently fell back to the hot
  # ledger would still fail and would still print a surface list from the
  # downstream message — this needle is what distinguishes the two.
  /usr/bin/grep -qF '**Result:** line not found in the v9.92 Deployment Log block on any surface (searched: RELEASE_LOG.md RELEASE_LOG_ARCHIVE-v9.md)' <<<"$(get_phase inject_outcome_field)" || { echo "FAIL: the failure must report a resolver miss naming every surface searched, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  [[ "$(/usr/bin/grep -c '^\*\*Outcome:\*\*' "$_oc_aseg")" -eq 0 ]] || { echo "FAIL: a failed lookup must write nothing"; failures=$((failures+1)); }

  # (i) the dry run must not promise what the apply run cannot deliver. For a
  # version whose **Result:** field genuinely does not exist, dry-run reports
  # that it WOULD fail — a dry run that says "would inject" here is a green
  # rehearsal for a red run.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  local _oc_saved_mode2="$MODE"; MODE="dry-run"
  _oc_write_archived
  phase_inject_outcome_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_outcome_field | /usr/bin/cut -d'|' -f1)" == "DRY-RUN" ]] || { echo "FAIL: dry-run over a genuinely absent **Result:** must mark DRY-RUN, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'would FAIL' <<<"$(get_phase inject_outcome_field)" || { echo "FAIL: dry-run must say it would FAIL for a genuinely absent **Result:**, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  # control: the same dry run over the RECOVERABLE archived version says it would inject, naming the segment
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  VERSION="v9.93"
  phase_inject_outcome_field >/dev/null 2>&1 || true
  /usr/bin/grep -qF 'would inject' <<<"$(get_phase inject_outcome_field)" || { echo "FAIL: dry-run control — a recoverable archived block must report it would inject, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'RELEASE_LOG_ARCHIVE-v9.md' <<<"$(get_phase inject_outcome_field)" || { echo "FAIL: dry-run must name the segment it would write to, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  [[ "$(/usr/bin/grep -c '^\*\*Outcome:\*\*' "$_oc_aseg")" -eq 0 ]] || { echo "FAIL: dry-run must not write"; failures=$((failures+1)); }
  MODE="$_oc_saved_mode2"

  /bin/rm -rf "$_oc_atmp" 2>/dev/null || true
  unset -f _oc_write_archived

  /bin/rm -rf "$_oc_tmp" 2>/dev/null || true
  unset -f _oc_write_log
  REPO_ROOT="$_oc_saved_root"; MODE="$_oc_saved_mode"; VERSION="$_oc_saved_version"
  RELEASE_LOG="$_oc_saved_log"; OUTCOME="$_oc_saved_outcome"; OUTCOME_RATIONALE="$_oc_saved_rat"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # ── Test 4c.1: the Outcome field-key GRAMMAR (#4222) — offline, hermetic ─────
  #
  # WHY THIS ARM EXISTS. The shipped defect is invisible on the bare-literal path,
  # which is every path the pre-existing arms exercise — which is exactly why it
  # shipped. Test 4c above drives phase 6.5 nine ways and every one of them seeds
  # a bare `**Outcome:**` key. Seed a QUALIFIED key instead and the idempotency
  # probe reads "absent" and injects a SECOND, contradicting Outcome line into the
  # audit record at exit 0. So the deliverable is this arm, not the matcher.
  #
  # THE POSITION AND THE LABEL AGREE. This arm sits between `Test 4c` (the phase
  # it extends) and `Test 4c.5`, and its label sorts there. The insertion anchor is
  # the `# ── Test 4c.5:` comment line, probed at exactly ONE occurrence — the
  # teardown idiom one line above it occurs 187 times and is a line number wearing
  # a construct's clothes.
  #
  # EVERY SYMBOL IS PREFIXED `_ockg_` so no sibling arm can collide on a name.
  local _ockg_saved_log="$RELEASE_LOG" _ockg_saved_ver="$VERSION" _ockg_saved_mode="$MODE"
  local _ockg_saved_outcome="$OUTCOME" _ockg_saved_rat="$OUTCOME_RATIONALE"
  local _ockg_saved_tool="$COMPUTE_CLOSE_CLASS_TELEMETRY" _ockg_saved_ms="$MILESTONE"
  local _ockg_saved_qre="$_FIELD_KEY_QUALIFIER_RE"
  local _ockg_tmp; _ockg_tmp="$(/usr/bin/mktemp -d -t outcomekey-selftest.XXXXXX)"
  RELEASE_LOG="$_ockg_tmp/RELEASE_LOG.md"; MODE="apply"; VERSION="v9.90"; MILESTONE="999"
  OUTCOME=""; OUTCOME_RATIONALE=""

  local _ockg_qual='**Outcome (Stage-12 read; finalized at Stage 13 VERIFIED):** ALIGNED, UNOBSERVED'
  local _ockg_res _ockg_rc _ockg_n _ockg_before _ockg_line

  # Fixture: the v9.90 target block plus an untouched v9.89 sibling, so every
  # assertion is proven block-scoped. $1/$2 are the Outcome-family line(s) seeded
  # into v9.90; omit both for a genuinely Outcome-less block.
  local _ockg_write
  _ockg_write() {
    {
      /bin/echo "# RELEASE_LOG"
      /bin/echo ""
      /bin/echo "#### Deployment Log v9.90"
      /bin/echo "**Cycle-Time:** 2d 0h."
      /bin/echo "**Result:** SUCCESS — green CI."
      if [[ -n "${1:-}" ]]; then /usr/bin/printf '%s\n' "$1"; fi
      if [[ -n "${2:-}" ]]; then /usr/bin/printf '%s\n' "$2"; fi
      /bin/echo ""
      /bin/echo "#### Deployment Log v9.89"
      /bin/echo "**Result:** SUCCESS — untouched sibling."
      /bin/echo "**Outcome:** SUCCESS"
    } > "$RELEASE_LOG"
  }
  # Count Outcome-FAMILY key lines (any `**Outcome…`) inside one version's block.
  local _ockg_count
  _ockg_count() {
    /usr/bin/awk -v ver="$2" '
      { line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line) }
      line == "#### Deployment Log " ver { inblk = 1; next }
      inblk && line ~ /^#### / { inblk = 0 }
      inblk && substr(line, 1, 9) == "**Outcome" { n++ }
      END { print n + 0 }
    ' "$1" 2>/dev/null || /bin/echo 0
  }
  # The RAW line immediately following the first line in <ver>'s block whose raw
  # text starts with <prefix>. Position is asserted on the raw line and NOT via
  # _cc_seq, whose `[A-Za-z -]*` field-name class excludes parentheses and so
  # cannot see a qualified key at all.
  local _ockg_after
  _ockg_after() {
    /usr/bin/awk -v ver="$2" -v pfx="$3" '
      hit && !shown { print $0; shown = 1 }
      { line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line) }
      line == "#### Deployment Log " ver { inblk = 1; next }
      inblk && line ~ /^#### / { inblk = 0 }
      inblk && !hit && index($0, pfx) == 1 { hit = 1 }
    ' "$1" 2>/dev/null || true
  }
  # The RAW line immediately following a version's block HEADING — i.e. the TOP of
  # the block. Separate from _ockg_after because the heading rule there consumes
  # its record; this is the position an empty anchor writes to.
  local _ockg_firstline
  _ockg_firstline() {
    /usr/bin/awk -v ver="$2" '
      hit && !shown { print $0; shown = 1 }
      { line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line) }
      line == "#### Deployment Log " ver { hit = 1 }
    ' "$1" 2>/dev/null || true
  }
  # Conformant § 3.2 telemetry stub, so the 6.8 arms below reach the anchor code
  # rather than stopping at the grammar assert.
  local _ockg_cct="$_ockg_tmp/cct.sh"
  /bin/cat > "$_ockg_cct" <<'EOF'
#!/bin/sh
echo "retro-conformance 10/10 (1.00); lessons-population 8/10 (0.80); carry-forward-closure 2/3 (0.67); pattern-emergence deferred-to-aggregate (see synthesize-release-learnings.sh); rollup-presence present; evidence-preservation 12/13 (0.92); evidence-close-gate pass; mechanism: compute-close-class-telemetry.sh"
EOF
  /bin/chmod +x "$_ockg_cct"
  COMPUTE_CLOSE_CLASS_TELEMETRY="$_ockg_cct"

  # (k1) AC-1 — A QUALIFIED KEY IS RECOGNIZED AND REJECTED, never injected past.
  # The block keeps exactly one Outcome-family line and the record is byte-identical.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _ockg_write "$_ockg_qual"
  _ockg_before="$(/bin/cat "$RELEASE_LOG")"
  phase_inject_outcome_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_outcome_field | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: #4222 k1 — a qualified Outcome key must FAIL loudly at --apply under the C1 grammar, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  _ockg_n="$(_ockg_count "$RELEASE_LOG" v9.90)"
  [[ "$_ockg_n" -eq 1 ]] || { echo "FAIL: #4222 k1 — the block must still carry exactly ONE Outcome-family line, got $_ockg_n"; failures=$((failures+1)); }
  [[ "$(/bin/cat "$RELEASE_LOG")" == "$_ockg_before" ]] || { echo "FAIL: #4222 k1 — a rejected key must leave the record BYTE-UNCHANGED"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'Outcome rationale' <<<"$(get_phase inject_outcome_field)" || { echo "FAIL: #4222 k1 — the FAIL diagnostic must name the sanctioned remedy (the rationale line), not merely the rejection; got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }

  # (k1s) EXECUTABLE SENSITIVITY — re-demonstrated on EVERY run, not once at
  # authoring time. The PRE-FIX bare-literal probe is inlined verbatim and must
  # read this same fixture as ABSENT (rc 1) — i.e. must be the thing that would
  # inject the second line. Without this arm, k1's green result is uninformative:
  # a phase that FAILed for any other reason would satisfy it.
  _ockg_rc=0
  /usr/bin/awk -v ver="v9.90" '
      { line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line) }
      line == "#### Deployment Log " ver { inblk = 1; next }
      inblk && line ~ /^#### / { inblk = 0 }
      inblk && line ~ /^\*\*Outcome:\*\*/ { found = 1 }
      END { exit(found ? 0 : 1) }
    ' "$RELEASE_LOG" 2>/dev/null || _ockg_rc=$?
  [[ "$_ockg_rc" -eq 1 ]] || { echo "FAIL: #4222 k1 SENSITIVITY — the PRE-FIX bare-literal probe must read this fixture as ABSENT (rc 1) so k1 is exercising the real defect; it returned rc $_ockg_rc"; failures=$((failures+1)); }
  _ockg_res="$(_resolve_field_key_in_block "$RELEASE_LOG" v9.90 'Outcome')"
  [[ "${_ockg_res%%$'\t'*}" == "QUALIFIED" ]] || { echo "FAIL: #4222 k1 SENSITIVITY — the new classifier must read the SAME fixture as QUALIFIED, got '${_ockg_res%%$'\t'*}'"; failures=$((failures+1)); }

  # (k2) AC-2 — the bare-literal path is UNREGRESSED: SKIPPED, nothing injected.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _ockg_write '**Outcome:** SUCCESS'
  _ockg_before="$(/bin/cat "$RELEASE_LOG")"
  phase_inject_outcome_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_outcome_field)" == SKIPPED\|* ]] || { echo "FAIL: #4222 k2 — a bare canonical key must still SKIP, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  [[ "$(/bin/cat "$RELEASE_LOG")" == "$_ockg_before" ]] || { echo "FAIL: #4222 k2 — the SKIP path must write nothing"; failures=$((failures+1)); }
  # (k2c) SPECIFICITY — the probe has NOT simply been made to match everything: a
  # block carrying NO Outcome line at all must still inject exactly one.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _ockg_write
  phase_inject_outcome_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_outcome_field)" == PASS\|* ]] || { echo "FAIL: #4222 k2 SPECIFICITY — a genuinely Outcome-less block must still inject, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  _ockg_n="$(_ockg_count "$RELEASE_LOG" v9.90)"
  [[ "$_ockg_n" -eq 1 ]] || { echo "FAIL: #4222 k2 SPECIFICITY — exactly one Outcome line must be injected, got $_ockg_n"; failures=$((failures+1)); }
  [[ "$(_ockg_count "$RELEASE_LOG" v9.89)" -eq 1 ]] || { echo "FAIL: #4222 k2 — the sibling v9.89 block must be untouched"; failures=$((failures+1)); }

  # (k3) AC-3 — PHASE 6.8's ANCHOR RESOLVES UNDER A QUALIFIED KEY. Seed a
  # qualified key with NO `**Outcome rationale:**` line and drive 6.8 standalone:
  # the field lands IMMEDIATELY AFTER the qualified key rather than failing anchor
  # resolution. Asserted on the RAW line (see _ockg_after).
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _ockg_write "$_ockg_qual"
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_close_class_telemetry_field)" == PASS\|* ]] || { echo "FAIL: #4222 k3 — 6.8 must resolve its anchor under a qualified Outcome key, got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }
  _ockg_line="$(_ockg_after "$RELEASE_LOG" v9.90 '**Outcome (Stage-12 read')"
  case "$_ockg_line" in
    '**Close-Class-Telemetry:**'*) : ;;
    *) echo "FAIL: #4222 k3 — the field must land immediately after the QUALIFIED key; the following line was '$_ockg_line'"; failures=$((failures+1)) ;;
  esac
  # (k3c) CONTROL — the same phase on a BARE key still lands after `**Outcome:**`,
  # so k3 is not passing because 6.8 now anchors on anything at all.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _ockg_write '**Outcome:** SUCCESS'
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  _ockg_line="$(_ockg_after "$RELEASE_LOG" v9.90 '**Outcome:**')"
  case "$_ockg_line" in
    '**Close-Class-Telemetry:**'*) : ;;
    *) echo "FAIL: #4222 k3 CONTROL — the bare-key fallback anchor must be unregressed; the following line was '$_ockg_line'"; failures=$((failures+1)) ;;
  esac

  # (k4) AC-4 — ONE RESOLVER SERVES BOTH SITES. Extend the SHARED key definition
  # with an additional conformant form and BOTH the 6.5 probe and the 6.8 anchor
  # must move. One variable, two sites: a one-site fix demonstrably fails here.
  local _ockg_brk='**Outcome [Stage-12 read]:** SUCCESS'
  _FIELD_KEY_QUALIFIER_RE=' [[][^]]*[]]'
  _ockg_write "$_ockg_brk"
  _ockg_res="$(_resolve_field_key_in_block "$RELEASE_LOG" v9.90 'Outcome')"
  [[ "${_ockg_res%%$'\t'*}" == "QUALIFIED" ]] || { echo "FAIL: #4222 k4 — with the shared constant extended, the bracketed key must classify QUALIFIED, got '${_ockg_res%%$'\t'*}'"; failures=$((failures+1)); }
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _ockg_before="$(/bin/cat "$RELEASE_LOG")"
  phase_inject_outcome_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_outcome_field | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: #4222 k4 — SITE 1 (6.5) must recognize the extended form and reject it, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  [[ "$(/bin/cat "$RELEASE_LOG")" == "$_ockg_before" ]] || { echo "FAIL: #4222 k4 — SITE 1 must write nothing on a recognized non-conformant key"; failures=$((failures+1)); }
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  _ockg_line="$(_ockg_after "$RELEASE_LOG" v9.90 '**Outcome [Stage-12 read]:**')"
  case "$_ockg_line" in
    '**Close-Class-Telemetry:**'*) : ;;
    *) echo "FAIL: #4222 k4 — SITE 2 (6.8) must anchor on the extended form too; the following line was '$_ockg_line'"; failures=$((failures+1)) ;;
  esac
  # (k4c) CONTROL — restore the constant to its default and the SAME bracketed key
  # must be accepted at NEITHER site. Without this arm k4 passes on a resolver that
  # accepts everything, and the constant is proven to be read rather than incidental.
  _FIELD_KEY_QUALIFIER_RE="$_ockg_saved_qre"
  _ockg_write "$_ockg_brk"
  _ockg_res="$(_resolve_field_key_in_block "$RELEASE_LOG" v9.90 'Outcome')"
  [[ "${_ockg_res%%$'\t'*}" == "UNPARSEABLE" ]] || { echo "FAIL: #4222 k4 CONTROL — at the DEFAULT constant the bracketed key must NOT classify QUALIFIED, got '${_ockg_res%%$'\t'*}'"; failures=$((failures+1)); }
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_close_class_telemetry_field | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: #4222 k4 CONTROL — SITE 2 must NOT anchor on a key the default grammar does not recognize, got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }

  # (k5) GRAMMAR NON-COLLISION, ASSERTED IN BOTH DIRECTIONS. `**Outcome rationale:**`
  # is a real, distinct field with live instances in the corpus; a matcher that
  # swallowed it would collapse 6.8's primary and fallback anchors onto each other
  # and make that pair unfalsifiable. The pair must DISAGREE both ways.
  _ockg_write '**Outcome rationale:** every declared limb landed.'
  _ockg_res="$(_resolve_field_key_in_block "$RELEASE_LOG" v9.90 'Outcome')"
  [[ "${_ockg_res%%$'\t'*}" == "ABSENT" ]] || { echo "FAIL: #4222 k5 — '**Outcome rationale:**' must classify ABSENT for base 'Outcome', got '${_ockg_res%%$'\t'*}'"; failures=$((failures+1)); }
  _ockg_res="$(_resolve_field_key_in_block "$RELEASE_LOG" v9.90 'Outcome rationale')"
  [[ "${_ockg_res%%$'\t'*}" == "CANONICAL" ]] || { echo "FAIL: #4222 k5 — '**Outcome rationale:**' must classify CANONICAL for base 'Outcome rationale', got '${_ockg_res%%$'\t'*}'"; failures=$((failures+1)); }
  _ockg_write '**Outcome:** SUCCESS'
  _ockg_res="$(_resolve_field_key_in_block "$RELEASE_LOG" v9.90 'Outcome')"
  [[ "${_ockg_res%%$'\t'*}" == "CANONICAL" ]] || { echo "FAIL: #4222 k5 — '**Outcome:**' must classify CANONICAL for base 'Outcome', got '${_ockg_res%%$'\t'*}'"; failures=$((failures+1)); }
  _ockg_res="$(_resolve_field_key_in_block "$RELEASE_LOG" v9.90 'Outcome rationale')"
  [[ "${_ockg_res%%$'\t'*}" == "ABSENT" ]] || { echo "FAIL: #4222 k5 — '**Outcome:**' must classify ABSENT for base 'Outcome rationale', got '${_ockg_res%%$'\t'*}'"; failures=$((failures+1)); }

  # (k6) RAW-PREFIX FIDELITY. The classifier returns the prefix VERBATIM, leading
  # whitespace included — the old probe stripped while the insert primitive matches
  # the raw line, and that asymmetry is the producer/consumer seam this card closes.
  # An indented key must classify AND anchor through the unchanged primitive.
  _ockg_write "  $_ockg_qual"
  _ockg_res="$(_resolve_field_key_in_block "$RELEASE_LOG" v9.90 'Outcome')"
  [[ "${_ockg_res%%$'\t'*}" == "QUALIFIED" ]] || { echo "FAIL: #4222 k6 — an INDENTED qualified key must still classify QUALIFIED, got '${_ockg_res%%$'\t'*}'"; failures=$((failures+1)); }
  [[ "${_ockg_res#*$'\t'}" == "  **Outcome (Stage-12 read; finalized at Stage 13 VERIFIED):**" ]] || { echo "FAIL: #4222 k6 — the returned prefix must carry the leading whitespace verbatim, got '${_ockg_res#*$'\t'}'"; failures=$((failures+1)); }
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  _ockg_line="$(_ockg_after "$RELEASE_LOG" v9.90 '  **Outcome (Stage-12 read')"
  case "$_ockg_line" in
    '**Close-Class-Telemetry:**'*) : ;;
    *) echo "FAIL: #4222 k6 — the raw indented prefix must anchor through the unchanged primitive; the following line was '$_ockg_line'"; failures=$((failures+1)) ;;
  esac
  # (k6c) CONTROL — the same fixture UNINDENTED behaves identically, so k6 is
  # measuring whitespace fidelity rather than a coincidence of the fixture.
  _ockg_write "$_ockg_qual"
  _ockg_res="$(_resolve_field_key_in_block "$RELEASE_LOG" v9.90 'Outcome')"
  [[ "${_ockg_res#*$'\t'}" == "**Outcome (Stage-12 read; finalized at Stage 13 VERIFIED):**" ]] || { echo "FAIL: #4222 k6 CONTROL — the unindented prefix must carry NO leading whitespace, got '${_ockg_res#*$'\t'}'"; failures=$((failures+1)); }

  # (k7) BOTH-PRESENT PRECEDENCE. A block carrying a canonical AND a qualified key
  # is a distinct reachable state, and it must be REPRESENTABLE — a three-value
  # class would have collapsed it into "canonical" and the duplicate diagnostic
  # would silently never fire.
  _ockg_write '**Outcome:** SUCCESS' "$_ockg_qual"
  _ockg_res="$(_resolve_field_key_in_block "$RELEASE_LOG" v9.90 'Outcome')"
  [[ "${_ockg_res%%$'\t'*}" == "DUPLICATE" ]] || { echo "FAIL: #4222 k7 — a both-present block must classify DUPLICATE, got '${_ockg_res%%$'\t'*}'"; failures=$((failures+1)); }
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _ockg_before="$(/bin/cat "$RELEASE_LOG")"
  phase_inject_outcome_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_outcome_field | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: #4222 k7 — a both-present block must FAIL at --apply, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'MORE THAN ONE' <<<"$(get_phase inject_outcome_field)" || { echo "FAIL: #4222 k7 — the duplicate diagnostic must fire and say so, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  [[ "$(/bin/cat "$RELEASE_LOG")" == "$_ockg_before" ]] || { echo "FAIL: #4222 k7 — a duplicate-key block must be left byte-unchanged"; failures=$((failures+1)); }
  # (k7c) CONTROL — the bare-only fixture SKIPs with NO duplicate diagnostic.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _ockg_write '**Outcome:** SUCCESS'
  phase_inject_outcome_field >/dev/null 2>&1 || true
  if /usr/bin/grep -qF 'MORE THAN ONE' <<<"$(get_phase inject_outcome_field)"; then
    echo "FAIL: #4222 k7 CONTROL — a bare-only block must NOT raise the duplicate diagnostic"; failures=$((failures+1))
  fi

  # (k8) PRESENT-BUT-UNPARSEABLE IS NOT ABSENT. Three key shapes satisfy neither
  # the canonical nor the qualified form: a NESTED parenthesis, a DOUBLED space,
  # and a MISSING space. Under a three-value class each classifies "absent" and
  # drives a silent duplicate injection — the original defect, unfixed. Each must
  # classify UNPARSEABLE and stop the write.
  local _ockg_shape
  for _ockg_shape in \
    '**Outcome (Stage-12 read (final)):** ALIGNED' \
    '**Outcome  (Stage-12 read):** ALIGNED' \
    '**Outcome(Stage-12 read):** ALIGNED'
  do
    _ockg_write "$_ockg_shape"
    _ockg_res="$(_resolve_field_key_in_block "$RELEASE_LOG" v9.90 'Outcome')"
    [[ "${_ockg_res%%$'\t'*}" == "UNPARSEABLE" ]] || { echo "FAIL: #4222 k8 — '$_ockg_shape' must classify UNPARSEABLE, not '${_ockg_res%%$'\t'*}'"; failures=$((failures+1)); }
    PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
    _ockg_before="$(/bin/cat "$RELEASE_LOG")"
    phase_inject_outcome_field >/dev/null 2>&1 || true
    [[ "$(get_phase inject_outcome_field | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: #4222 k8 — '$_ockg_shape' must FAIL rather than inject past, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
    [[ "$(/bin/cat "$RELEASE_LOG")" == "$_ockg_before" ]] || { echo "FAIL: #4222 k8 — '$_ockg_shape' must leave the record byte-unchanged"; failures=$((failures+1)); }
  done
  # (k8c) CONTROL — a genuinely absent key still classifies ABSENT and still
  # injects, so k8 is not passing on a classifier that rejects everything.
  _ockg_write
  _ockg_res="$(_resolve_field_key_in_block "$RELEASE_LOG" v9.90 'Outcome')"
  [[ "${_ockg_res%%$'\t'*}" == "ABSENT" ]] || { echo "FAIL: #4222 k8 CONTROL — an Outcome-less block must classify ABSENT, got '${_ockg_res%%$'\t'*}'"; failures=$((failures+1)); }

  # (k9) NO EMPTY ANCHOR EVER REACHES THE SHARED PRIMITIVE. This is the arm the
  # whole anchor-resolution design turns on. `str.startswith("")` is True for every
  # string, so an empty anchor matches the block's FIRST line: the primitive's
  # exit-4 "anchor absent" path becomes unreachable, the field lands at the TOP of
  # the block, and the phase reports success. A misplaced audit field under a PASS
  # verdict is this card's own failure signature.
  _ockg_write                      # no Outcome line at all → ABSENT → empty prefix
  _ockg_res="$(_resolve_field_key_in_block "$RELEASE_LOG" v9.90 'Outcome')"
  [[ -z "${_ockg_res#*$'\t'}" ]] || { echo "FAIL: #4222 k9 — ABSENT must emit an EMPTY prefix (it is the only class that may), got '${_ockg_res#*$'\t'}'"; failures=$((failures+1)); }
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_close_class_telemetry_field | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: #4222 k9 — with no resolvable anchor, 6.8 must FAIL LOUDLY rather than place the field anywhere, got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }
  _ockg_line="$(_ockg_firstline "$RELEASE_LOG" v9.90)"
  case "$_ockg_line" in
    '**Close-Class-Telemetry:**'*) echo "FAIL: #4222 k9 — the field landed at the TOP of the block, which is exactly the empty-anchor signature"; failures=$((failures+1)) ;;
    *) : ;;
  esac
  [[ -n "$_ockg_line" ]] || { echo "FAIL: #4222 k9 — the top-of-block reader returned nothing, so the arm above asserted over an empty string"; failures=$((failures+1)); }
  # (k9s) ANTI-VACUITY / EXECUTABLE SENSITIVITY — the hazard is REAL and is
  # re-demonstrated on every run: handing the UNCHANGED primitive an empty anchor
  # on this very fixture exits 0 and inserts at the top of the block. Without this
  # arm, k9's clean result is indistinguishable from a primitive that never had the
  # weakness. The fixture is rewritten immediately afterwards.
  _ockg_write
  _ockg_rc=0
  _insert_field_after_in_block "$RELEASE_LOG" v9.90 '' '**Close-Class-Telemetry:** SENSITIVITY-PROBE' >/dev/null 2>&1 || _ockg_rc=$?
  [[ "$_ockg_rc" -eq 0 ]] || { echo "FAIL: #4222 k9 ANTI-VACUITY — the empty-anchor probe must reproduce the exit-0 path on the unchanged primitive, got rc $_ockg_rc"; failures=$((failures+1)); }
  _ockg_line="$(_ockg_firstline "$RELEASE_LOG" v9.90)"
  case "$_ockg_line" in
    '**Close-Class-Telemetry:** SENSITIVITY-PROBE') : ;;
    *) echo "FAIL: #4222 k9 ANTI-VACUITY — the empty anchor must demonstrably land at the TOP of the block, or k9 is measuring nothing; the following line was '$_ockg_line'"; failures=$((failures+1)) ;;
  esac

  # (k10) MODE DIMENSION — the release-wide dry-run/apply ruling. `--dry-run` must
  # never return non-zero, yet must still EVALUATE and name the condition that
  # FAILs at `--apply`. The runner's guard is mode-blind: a phase returning 3 under
  # --dry-run aborts the preview and truncates every phase after it from the
  # report — which is the very review the historical incident was caught in.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  MODE="dry-run"
  _ockg_write "$_ockg_qual"
  _ockg_before="$(/bin/cat "$RELEASE_LOG")"
  _ockg_rc=0
  phase_inject_outcome_field >/dev/null 2>&1 || _ockg_rc=$?
  [[ "$_ockg_rc" -eq 0 ]] || { echo "FAIL: #4222 k10 — --dry-run over a qualified key must return 0 (the documented '0 = success (dry-run or apply)' contract), got rc $_ockg_rc"; failures=$((failures+1)); }
  [[ "$(get_phase inject_outcome_field | /usr/bin/cut -d'|' -f1)" == "WARN" ]] || { echo "FAIL: #4222 k10 — --dry-run must mark WARN per the in-file non-blocking-preview precedent, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'FAILS the close at --apply' <<<"$(get_phase inject_outcome_field)" || { echo "FAIL: #4222 k10 — the dry-run WARN must name the condition that fails at --apply, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }
  [[ "$(/bin/cat "$RELEASE_LOG")" == "$_ockg_before" ]] || { echo "FAIL: #4222 k10 — --dry-run must write nothing"; failures=$((failures+1)); }
  # (k10c) CONTROL — the SAME fixture at --apply is fatal. Without this arm the
  # WARN could be a phase that simply never blocks.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  MODE="apply"
  _ockg_rc=0
  phase_inject_outcome_field >/dev/null 2>&1 || _ockg_rc=$?
  [[ "$_ockg_rc" -eq 3 ]] || { echo "FAIL: #4222 k10 CONTROL — the same condition must return 3 at --apply, got rc $_ockg_rc"; failures=$((failures+1)); }
  [[ "$(get_phase inject_outcome_field | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: #4222 k10 CONTROL — the same condition must mark FAIL at --apply, got '$(get_phase inject_outcome_field)'"; failures=$((failures+1)); }

  # (k11) THE GOVERNANCE CONSTANT IS NOT A RUNTIME FLAG. Its two settings encode
  # two different governance rulings and no gate anywhere reads the Outcome field,
  # so an env-overridable form would let the ruling be flipped per invocation with
  # no PR, no review and no trace in git. Scoped to the PRODUCTION region above
  # `self_test` — the same production-region discipline the sibling arm uses — so
  # this arm's own known-bad literal cannot satisfy its own probe.
  local _ockg_prod _ockg_bad
  _ockg_prod="$(/usr/bin/sed -n '1,/^self_test() {/p' "${BASH_SOURCE[0]}" || true)"
  _ockg_bad='OUTCOME_QUALIFIED_KEY_POLICY="${OUTCOME_QUALIFIED_KEY_POLICY:-reject}"'
  if /usr/bin/grep -qF 'OUTCOME_QUALIFIED_KEY_POLICY:-' <<<"$_ockg_prod"; then
    echo "FAIL: #4222 k11 — the policy constant must NOT take the env-overridable \${VAR:-} form"; failures=$((failures+1))
  fi
  /usr/bin/grep -qF 'OUTCOME_QUALIFIED_KEY_POLICY:-' <<<"$_ockg_bad" || { echo "FAIL: #4222 k11 ANTI-VACUITY — the same matcher must MATCH the known-bad source form, or k11's zero is a broken probe rather than a measurement"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'OUTCOME_QUALIFIED_KEY_POLICY="reject"' <<<"$_ockg_prod" || { echo "FAIL: #4222 k11 ANTI-VACUITY — the production region must actually carry the hard-assigned constant, or the probe above is reading the wrong region"; failures=$((failures+1)); }

  /bin/rm -rf "$_ockg_tmp" 2>/dev/null || true
  unset -f _ockg_write _ockg_count _ockg_after _ockg_firstline
  _FIELD_KEY_QUALIFIER_RE="$_ockg_saved_qre"
  RELEASE_LOG="$_ockg_saved_log"; VERSION="$_ockg_saved_ver"; MODE="$_ockg_saved_mode"
  OUTCOME="$_ockg_saved_outcome"; OUTCOME_RATIONALE="$_ockg_saved_rat"
  COMPUTE_CLOSE_CLASS_TELEMETRY="$_ockg_saved_tool"; MILESTONE="$_ockg_saved_ms"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # ── Test 4c.5: phase_inject_velocity_field (6.6) + phase_append_release_learnings (6.7)
  #
  # Offline, hermetic. Both producers are STUBBED (the real ones reach `gh` and
  # the operator-instance event log) but every stub emits the REAL shape, so the
  # conformance and structural asserts run against realistic bytes.
  #
  # ASSERT ON CONTENT AND ON TARGET FILE — NOT ON EXIT CODE. Three observables
  # that look sufficient are all vacuous for this pair, and each was measured
  # rather than assumed:
  #   * exit code — a wrong-SURFACE write exits 0;
  #   * "did RELEASE_LOG change?" — phases 6 and 6.5 already mutate it every
  #     run, so a bare file-diff passes with these phases entirely absent;
  #   * the shipped consumer grammar alone — a field written into the hot stub
  #     while the rest of its block sits in a segment still parses cleanly.
  # Hence the CO-LOCATION limbs (f)/(i): the field and its block must be in the
  # same file, not merely both present somewhere.
  local _vl_saved_log="$RELEASE_LOG" _vl_saved_ver="$VERSION" _vl_saved_mode="$MODE"
  local _vl_saved_cv="$COMPUTE_VELOCITY" _vl_saved_sl="$SYNTHESIZE_LEARNINGS"
  local _vl_saved_ms="$MILESTONE" _vl_saved_sha="$MERGE_SHA"
  local _vl_tmp; _vl_tmp="$(/usr/bin/mktemp -d -t velocity-selftest.XXXXXX)"
  MODE="apply"; MILESTONE="999"; MERGE_SHA=""

  local _vl_cv="$_vl_tmp/cv-ok.sh" _vl_cv_bold="$_vl_tmp/cv-bold.sh" _vl_cv_empty="$_vl_tmp/cv-empty.sh"
  local _vl_sl="$_vl_tmp/sl-ok.sh" _vl_sl_zero="$_vl_tmp/sl-zero.sh" _vl_sl_empty="$_vl_tmp/sl-empty.sh"
  /bin/cat > "$_vl_cv" <<'EOF'
#!/bin/sh
echo "planned 12 pts / delivered 12 pts (1.00); files-changed 9; allocation 0/12/0 pts (feature/debt/protocol-slack); class routine; mechanism: compute-release-velocity.sh"
EOF
  /bin/cat > "$_vl_cv_bold" <<'EOF'
#!/bin/sh
echo "planned **12** pts / delivered **12** pts (1.00); class routine; mechanism: compute-release-velocity.sh"
EOF
  /bin/cat > "$_vl_cv_empty" <<'EOF'
#!/bin/sh
printf '   \n'
exit 0
EOF
  /bin/cat > "$_vl_sl" <<'EOF'
#!/bin/sh
V=""
while [ $# -gt 0 ]; do case "$1" in --version) V="$2"; shift 2 ;; *) shift ;; esac; done
cat <<INNER
#### Release Learnings $V

**Synthesized at:** 2026-06-28T00:00:00Z
**Source events:** 2 \`release-synthesis/learnings-triple\` row(s) from \`pipeline-event-log.md\` (filter: version=\`$V\`)
**Source-row anchors:** row 41; row 42

**Surprise:** the archival sweep moved which file the record lives in.
**Would-change:** resolve the surface before writing, not after.
**Watch-for:** a split record that still parses.

INNER
EOF
  /bin/cat > "$_vl_sl_zero" <<'EOF'
#!/bin/sh
V=""
while [ $# -gt 0 ]; do case "$1" in --version) V="$2"; shift 2 ;; *) shift ;; esac; done
cat <<INNER
#### Release Learnings $V

**Synthesized at:** 2026-06-28T00:00:00Z
**Source events:** 0 \`release-synthesis/learnings-triple\` row(s) from \`pipeline-event-log.md\` (filter: version=\`$V\`)
**Source-row anchors:** N/A

**Surprise:** N/A — no novel learning this release
**Would-change:** N/A — no novel learning this release
**Watch-for:** N/A — no novel learning this release

INNER
EOF
  /bin/cat > "$_vl_sl_empty" <<'EOF'
#!/bin/sh
printf '  \n \n'
exit 0
EOF
  /bin/chmod +x "$_vl_cv" "$_vl_cv_bold" "$_vl_cv_empty" "$_vl_sl" "$_vl_sl_zero" "$_vl_sl_empty"

  # HOT fixture. v9.95 is the clean target; v9.94 is an untouched sibling; v9.93
  # carries the DECOY — a hand-authored `**Velocity:** 3 issues.` that satisfies
  # a presence probe and satisfies NO part of the consumer grammar. It is the
  # shape two live corpus rows already have.
  RELEASE_LOG="$_vl_tmp/RELEASE_LOG.md"
  local _vl_write
  _vl_write() {
    /bin/cat > "$RELEASE_LOG" <<'EOF'
# RELEASE_LOG

#### Deployment Log v9.95
**Mechanism:** git merge.
**Timestamp:** 2026-06-28.
**Cycle-Time:** 3d 4h; mechanism: compute-cycle-time.sh
**Result:** SUCCESS — green CI.

#### Deployment Log v9.94
**Cycle-Time:** 1d 0h.
**Result:** SUCCESS — prior release.

#### Deployment Log v9.93
**Cycle-Time:** 2d 0h.
**Velocity:** 3 issues.
**Result:** SUCCESS — decoy row: reads fine, parses to nothing.
EOF
  }

  # Field order inside a block, as a space-joined sequence of field NAMES. A
  # sequence is falsifiable in a way a pair of greps is not: it proves position,
  # not merely presence.
  local _vl_seq
  _vl_seq() {
    /usr/bin/awk -v ver="$2" '
      { line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line) }
      line == "#### Deployment Log " ver { inblk = 1; next }
      inblk && line ~ /^#### / { inblk = 0 }
      inblk && line ~ /^\*\*[A-Za-z][A-Za-z-]*:\*\*/ {
        n = line; sub(/:\*\*.*$/, "", n); sub(/^\*\*/, "", n); printf "%s ", n
      }
    ' "$1" 2>/dev/null || true
  }
  # Count `**Velocity:**` lines inside ONE version's block on ONE file.
  local _vl_count
  _vl_count() {
    /usr/bin/awk -v ver="$2" '
      { line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line) }
      line == "#### Deployment Log " ver { inblk = 1; next }
      inblk && line ~ /^#### / { inblk = 0 }
      inblk && line ~ /^\*\*Velocity:\*\*/ { n++ }
      END { print n + 0 }
    ' "$1" 2>/dev/null || echo 0
  }
  # The H4 heading immediately following a version's Deployment Log block.
  local _vl_next_h4
  _vl_next_h4() {
    /usr/bin/awk -v ver="$2" '
      { line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line) }
      seen && line ~ /^#### / { print line; exit }
      line == "#### Deployment Log " ver { seen = 1 }
    ' "$1" 2>/dev/null || true
  }

  COMPUTE_VELOCITY="$_vl_cv"; SYNTHESIZE_LEARNINGS="$_vl_sl"

  # (a) velocity lands BETWEEN **Cycle-Time:** and **Result:** on a clean block.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _vl_write; VERSION="v9.95"
  phase_inject_velocity_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_velocity_field)" == PASS\|* ]] || { echo "FAIL: phase_inject_velocity_field on a clean block should PASS, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  local _vl_got; _vl_got="$(_vl_seq "$RELEASE_LOG" v9.95)"
  [[ "$_vl_got" == "Mechanism Timestamp Cycle-Time Velocity Result " ]] || { echo "FAIL: v9.95 field order must be 'Mechanism Timestamp Cycle-Time Velocity Result ', got '$_vl_got'"; failures=$((failures+1)); }
  /usr/bin/grep -qF '**Velocity:** planned 12 pts / delivered 12 pts (1.00)' "$RELEASE_LOG" || { echo "FAIL: the producer's value must reach the ledger verbatim"; failures=$((failures+1)); }

  # (b) the sibling blocks are untouched — v9.94 gains nothing, and the v9.93
  # decoy is neither rewritten nor duplicated.
  [[ "$(_vl_count "$RELEASE_LOG" v9.94)" -eq 0 ]] || { echo "FAIL: velocity leaked into the sibling v9.94 block"; failures=$((failures+1)); }
  [[ "$(_vl_count "$RELEASE_LOG" v9.93)" -eq 1 ]] || { echo "FAIL: the v9.93 decoy block must still carry exactly 1 **Velocity:** line"; failures=$((failures+1)); }
  /usr/bin/grep -qFx '**Velocity:** 3 issues.' "$RELEASE_LOG" || { echo "FAIL: the v9.93 decoy line must be left exactly as authored"; failures=$((failures+1)); }

  # (e) the learnings block is the H4 IMMEDIATELY following its Deployment Log
  # block — placement, not mere presence.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_append_release_learnings >/dev/null 2>&1 || true
  [[ "$(get_phase append_release_learnings)" == PASS\|* ]] || { echo "FAIL: phase_append_release_learnings should PASS, got '$(get_phase append_release_learnings)'"; failures=$((failures+1)); }
  local _vl_nh; _vl_nh="$(_vl_next_h4 "$RELEASE_LOG" v9.95)"
  [[ "$_vl_nh" == "#### Release Learnings v9.95" ]] || { echo "FAIL: the H4 immediately after the v9.95 Deployment Log block must be '#### Release Learnings v9.95', got '$_vl_nh'"; failures=$((failures+1)); }
  /usr/bin/grep -qE '^\*\*Watch-for:\*\* a split record that still parses\.$' "$RELEASE_LOG" || { echo "FAIL: the rendered learnings body must reach the ledger intact (last field lost => capture truncated)"; failures=$((failures+1)); }
  # the v9.94 block must not have been displaced or absorbed
  /usr/bin/grep -qFx '#### Deployment Log v9.94' "$RELEASE_LOG" || { echo "FAIL: the sibling v9.94 heading was destroyed by the learnings insert"; failures=$((failures+1)); }
  # EXACT separation — one blank line either side of the inserted block. Neither
  # zero (the H4 fuses to the preceding field line) nor two (the producer's own
  # trailing newline doubled onto the insert's). The insert site owns this, so
  # it is asserted at the insert site rather than trusted to the producer.
  local _vl_sep
  _vl_sep="$(/usr/bin/awk '
    { l[NR] = $0 }
    END {
      for (i = 1; i <= NR; i++) if (l[i] == "#### Release Learnings v9.95") h = i
      if (!h) { print "NOHEADING"; exit }
      b = 0; i = h - 1; while (i >= 1 && l[i] == "") { b++; i-- }
      n = 0; for (j = h + 1; j <= NR; j++) if (l[j] ~ /^#### /) { n = j; break }
      if (n) { a = 0; i = n - 1; while (i > h && l[i] == "") { a++; i-- } } else a = -1
      printf "before=%d after=%d", b, a
    }' "$RELEASE_LOG" 2>/dev/null || true)"
  [[ "$_vl_sep" == "before=1 after=1" ]] || { echo "FAIL: the learnings block must sit with exactly one blank line either side, got '$_vl_sep'"; failures=$((failures+1)); }

  # (c) idempotent re-run — both phases SKIP and neither duplicates.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_inject_velocity_field >/dev/null 2>&1 || true
  phase_append_release_learnings >/dev/null 2>&1 || true
  [[ "$(get_phase inject_velocity_field)" == SKIPPED\|* ]] || { echo "FAIL: velocity re-run must SKIP, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  [[ "$(get_phase append_release_learnings)" == SKIPPED\|* ]] || { echo "FAIL: learnings re-run must SKIP, got '$(get_phase append_release_learnings)'"; failures=$((failures+1)); }
  [[ "$(_vl_count "$RELEASE_LOG" v9.95)" -eq 1 ]] || { echo "FAIL: velocity re-run duplicated the field"; failures=$((failures+1)); }
  [[ "$(/usr/bin/grep -c '^#### Release Learnings v9\.95$' "$RELEASE_LOG")" -eq 1 ]] || { echo "FAIL: learnings re-run duplicated the block"; failures=$((failures+1)); }

  # (h) the DECOY arm — a non-conformant existing field SKIPs (this phase never
  # rewrites a field it did not author) but the skip is NOT silent: the detail
  # must name the surface AND flag that the field is unreadable to the consumer.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _vl_write; VERSION="v9.93"
  phase_inject_velocity_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_velocity_field)" == SKIPPED\|* ]] || { echo "FAIL: a block already carrying a **Velocity:** line must SKIP, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'RELEASE_LOG.md' <<<"$(get_phase inject_velocity_field)" || { echo "FAIL: the SKIPPED detail must name the surface it read"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'NOT readable by the shipped velocity consumer' <<<"$(get_phase inject_velocity_field)" || { echo "FAIL: a SKIP over a NON-CONFORMANT field must say so — a silent skip is how the two unparseable corpus rows stayed invisible; got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  [[ "$(_vl_count "$RELEASE_LOG" v9.93)" -eq 1 ]] || { echo "FAIL: the decoy block must not gain a second **Velocity:** line"; failures=$((failures+1)); }
  # control: the same detail string over a CONFORMANT existing field must NOT
  # carry the warning — otherwise the needle above fires on every skip and
  # proves nothing.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _vl_write; VERSION="v9.95"
  phase_inject_velocity_field >/dev/null 2>&1 || true   # inject a conformant field
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_inject_velocity_field >/dev/null 2>&1 || true   # re-run over it
  /usr/bin/grep -qF 'NOT readable by the shipped velocity consumer' <<<"$(get_phase inject_velocity_field)" && { echo "FAIL: control — a SKIP over a CONFORMANT field must NOT carry the non-conformance warning"; failures=$((failures+1)); }

  # (d) a BOLDED-NUMERAL value is REJECTED by the conformance self-assert, and
  # nothing is written. This is the guard that would have caught the two live
  # `planned **N** pts` rows at emit time.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _vl_write; VERSION="v9.95"; COMPUTE_VELOCITY="$_vl_cv_bold"
  phase_inject_velocity_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_velocity_field | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: a bolded-numeral velocity value must FAIL the conformance self-assert, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'bolds its numerals' <<<"$(get_phase inject_velocity_field)" || { echo "FAIL: the conformance failure must name the bolded-numeral cause, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  [[ "$(_vl_count "$RELEASE_LOG" v9.95)" -eq 0 ]] || { echo "FAIL: a rejected value must write NOTHING"; failures=$((failures+1)); }

  # (j-velocity) empty capture at exit 0 degrades to an explicit N/A field —
  # never `**Velocity:** ` with nothing after it, and never an invented number.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _vl_write; VERSION="v9.95"; COMPUTE_VELOCITY="$_vl_cv_empty"
  phase_inject_velocity_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_velocity_field)" == PASS\|* ]] || { echo "FAIL: an empty producer capture must degrade to an N/A field, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  /usr/bin/grep -qF '**Velocity:** N/A — compute-release-velocity.sh unavailable or returned no value' "$RELEASE_LOG" || { echo "FAIL: the N/A degrade line is missing from the ledger"; failures=$((failures+1)); }
  /usr/bin/grep -qE '^\*\*Velocity:\*\*[[:space:]]*$' "$RELEASE_LOG" && { echo "FAIL: an empty capture must never write a bare '**Velocity:**' with no value"; failures=$((failures+1)); }
  COMPUTE_VELOCITY="$_vl_cv"

  # (j) the LEARNINGS producer emitting only whitespace at exit 0 FAILs and
  # writes nothing. An exit-code check alone does not cover this: the stub
  # exits 0. The DIAGNOSTIC is asserted, not merely the verdict — the structural
  # assert downstream would also reject a whitespace render, so a bare
  # FAIL-and-wrote-nothing check cannot tell which guard fired, and the
  # empty-capture guard could be deleted with the limb still green.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _vl_write; VERSION="v9.95"; SYNTHESIZE_LEARNINGS="$_vl_sl_empty"
  phase_append_release_learnings >/dev/null 2>&1 || true
  [[ "$(get_phase append_release_learnings | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: a whitespace-only render at exit 0 must FAIL, got '$(get_phase append_release_learnings)'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'exited 0 with an EMPTY render' <<<"$(get_phase append_release_learnings)" || { echo "FAIL: the whitespace-only render must be caught by the EMPTY-CAPTURE guard and say so, got '$(get_phase append_release_learnings)'"; failures=$((failures+1)); }
  [[ "$(/usr/bin/grep -c '^#### Release Learnings' "$RELEASE_LOG")" -eq 0 ]] || { echo "FAIL: an empty render must append nothing"; failures=$((failures+1)); }

  # (k) D-1 = BLOCK. A zero-source-event render is the synthesizer's "nothing was
  # captured" sentinel; appending it would record an absence of EVIDENCE as a
  # statement of FACT. The close blocks instead, and the remedy is printed.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _vl_write; VERSION="v9.95"; SYNTHESIZE_LEARNINGS="$_vl_sl_zero"
  phase_append_release_learnings >/dev/null 2>&1 || true
  [[ "$(get_phase append_release_learnings | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: D-1 — a 0-source-event learnings render must BLOCK the close, got '$(get_phase append_release_learnings)'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'append-pipeline-event.sh' <<<"$(get_phase append_release_learnings)" || { echo "FAIL: the D-1 block must print the capture remedy, got '$(get_phase append_release_learnings)'"; failures=$((failures+1)); }
  [[ "$(/usr/bin/grep -c '^#### Release Learnings' "$RELEASE_LOG")" -eq 0 ]] || { echo "FAIL: a D-1 block must append nothing"; failures=$((failures+1)); }
  # control: the SAME phase over a >0-source-event render PASSes and appends —
  # otherwise the FAIL above could be any failure at all, not the D-1 branch.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  SYNTHESIZE_LEARNINGS="$_vl_sl"
  phase_append_release_learnings >/dev/null 2>&1 || true
  [[ "$(get_phase append_release_learnings)" == PASS\|* ]] || { echo "FAIL: D-1 control — a >0-source-event render must PASS, got '$(get_phase append_release_learnings)'"; failures=$((failures+1)); }
  [[ "$(/usr/bin/grep -c '^#### Release Learnings v9\.95$' "$RELEASE_LOG")" -eq 1 ]] || { echo "FAIL: D-1 control — the block must be appended exactly once"; failures=$((failures+1)); }

  # ── (l) THE GATE PREDICATE — the same D-1 condition, now readable at Phase 2.
  # Arm (k) above covers the PREVIOUSLY-COVERED path: the zero-source-event
  # condition caught by phase_append_release_learnings at dispatch position 8,
  # after four write phases. This arm covers the PREVIOUSLY-UNCOVERED path: the
  # identical condition read by _learnings_capture_gap, which phase_preflight
  # calls at dispatch position 1. Against the pre-fix construct there is no helper
  # and no call site, so this arm cannot be satisfied by it.
  _vl_write; VERSION="v9.95"; MODE="apply"; SYNTHESIZE_LEARNINGS="$_vl_sl_zero"
  _learnings_capture_gap || { echo "FAIL: (l) A7-gate — a 0-source-event render must read as a capture GAP (_learnings_capture_gap must return 0)"; failures=$((failures+1)); }
  # control: the SAME predicate over a >0-source-event render must NOT report a
  # gap. Without it the assertion above is satisfied by a predicate that returns
  # 0 for every input, which is indistinguishable from a working gate.
  SYNTHESIZE_LEARNINGS="$_vl_sl"
  ! _learnings_capture_gap || { echo "FAIL: (l) control — a >0-source-event render must NOT read as a capture gap"; failures=$((failures+1)); }

  # ── (m) THE SHORT-CIRCUITS — the gate inherits 6.7's arm PRECEDENCE, not merely
  # its last arm. Each state below is one 6.7 SKIPs; a gate that blocked them
  # would refuse at the door a close the backstop waves through, which is the
  # precise failure that moving an assertion earlier invites.
  #
  # (m.1) ALREADY PLACED — a resumed close whose block is correctly placed is not
  # a capture gap, EVEN under a zero-source-event stub.
  _vl_write; VERSION="v9.95"; SYNTHESIZE_LEARNINGS="$_vl_sl"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_append_release_learnings >/dev/null 2>&1 || true
  [[ "$(_vl_next_h4 "$RELEASE_LOG" v9.95)" == "#### Release Learnings v9.95" ]] || { echo "FAIL: (m.1) setup — the block was not placed, so the idempotency assertion below is untestable"; failures=$((failures+1)); }
  SYNTHESIZE_LEARNINGS="$_vl_sl_zero"
  ! _learnings_capture_gap || { echo "FAIL: (m.1) — an already-placed learnings block must NOT read as a capture gap; a resumed close 6.7 SKIPs would be blocked at preflight"; failures=$((failures+1)); }
  # sensitivity: remove the block, keep the SAME stub — now it IS a gap. Without
  # this the assertion above also passes for a predicate that never returns 0.
  _vl_write; VERSION="v9.95"
  _learnings_capture_gap || { echo "FAIL: (m.1) sensitivity — with the block REMOVED and the same 0-event stub, the predicate must report a gap"; failures=$((failures+1)); }
  #
  # (m.2) DEGRADED ENVIRONMENT NEVER ESCALATES. A missing synthesizer and a
  # whitespace-only render are 6.7 SKIP / FAIL arms it owns with a richer
  # diagnostic; blocking preflight on them converts a degraded ENVIRONMENT into a
  # close-out failure and widens this gate past the one condition it owns.
  SYNTHESIZE_LEARNINGS="$_vl_tmp/definitely-not-here.sh"
  ! _learnings_capture_gap || { echo "FAIL: (m.2) — a non-executable synthesizer must NOT read as a capture gap"; failures=$((failures+1)); }
  SYNTHESIZE_LEARNINGS="$_vl_sl_empty"
  ! _learnings_capture_gap || { echo "FAIL: (m.2) — a whitespace-only render at exit 0 must NOT read as a capture gap"; failures=$((failures+1)); }

  # ── (n) THE GATE IS WIRED, AND WIRED EARLY ENOUGH. A predicate that exists but
  # is never called from phase_preflight is the dead-check class one level up; a
  # preflight dispatched after the first write phase does not save the tree.
  # Both facts are derived from the SHIPPED text (the PI-10 producer-derived
  # detector idiom) — asserting against a restated copy would stay green while
  # the production ladder moved underneath it.
  local _pfg_body; _pfg_body="$(/usr/bin/sed -n '/^phase_preflight() {/,/^}/p' "${BASH_SOURCE[0]}" || true)"
  /usr/bin/grep -qE '_learnings_capture_gap' <<<"$_pfg_body" || { echo "FAIL: (n) — phase_preflight does not call _learnings_capture_gap; the gate is defined but never fires"; failures=$((failures+1)); }
  # control: the same extraction must NOT match a fabricated symbol.
  ! /usr/bin/grep -qE '_learnings_zzfabricatedzz' <<<"$_pfg_body" || { echo "FAIL: (n) control — the phase_preflight extractor matched a fabricated symbol"; failures=$((failures+1)); }
  # The gate must PRINT the remedy, not merely detect the gap. A block whose message
  # does not name the one command that clears it sends the operator to read source.
  /usr/bin/grep -qE '_learnings_capture_remedy' <<<"$_pfg_body" || { echo "FAIL: (n) — phase_preflight does not embed _learnings_capture_remedy; the block would name the condition without naming its remedy"; failures=$((failures+1)); }
  # ...and the remedy must name the capture command AND the event subtype, because
  # append-pipeline-event.sh alone is not runnable — the subtype is what makes the
  # row a learnings triple rather than some other event.
  local _pfg_rem; _pfg_rem="$(_learnings_capture_remedy)"
  /usr/bin/grep -qF 'append-pipeline-event.sh' <<<"$_pfg_rem" || { echo "FAIL: (n) — the capture remedy must name append-pipeline-event.sh"; failures=$((failures+1)); }
  /usr/bin/grep -qF -- '--event-subtype learnings-triple' <<<"$_pfg_rem" || { echo "FAIL: (n) — the capture remedy must name --event-subtype learnings-triple; without it the command does not produce the row the gate wants"; failures=$((failures+1)); }
  # control: the same matcher over the same string must NOT find a subtype that is
  # not there, or the two assertions above would pass on any non-empty remedy.
  ! /usr/bin/grep -qF -- '--event-subtype zzfabricatedzz' <<<"$_pfg_rem" || { echo "FAIL: (n) control — the remedy matcher matched a fabricated subtype"; failures=$((failures+1)); }

  # ── (n.1) THE MANDATED WARN SHAPE. Collective Review ruled that this release
  # adopts the in-file non-blocking-preview precedent for the capture gap: a
  # non-blocking WARN under --dry-run, fatal at --apply. phase_preflight
  # implements it — and NO arm asserted it, so a regression flipping that
  # `mark_phase … "WARN"` back to `"PASS"` (precisely the shape the ruling
  # rejected) shipped green.
  #
  # Asserted over the SAME _pfg_body extraction this arm already performs, not by
  # driving the phase: phase_preflight demands gh auth, a clean tree, a worktree
  # cwd and a DEPLOYED RELEASE_LOG row before it ever reaches (g), which is why it
  # is driven by 0 arms and why the sibling phases' runtime idiom does not reach
  # here. The extraction is already floored against vacuity by the assertions
  # above — an empty _pfg_body reddens them first.
  #
  # THREE LIMBS, one per half-of-the-ruling the sibling arms grade at their own
  # phases (#4222 k10 / #5288 m7 / #4927 q each assert result-token + non-blocking
  # rc + tail clause): the result TOKEN, the NON-BLOCKING return, and the TAIL
  # CLAUSE naming what fails at --apply. The token alone would wave through a WARN
  # that still blocks the dry run; a WARN that never names --apply reads to the
  # operator as a permanent waiver rather than a deferred failure.
  /usr/bin/grep -qF 'mark_phase "preflight" "WARN"' <<<"$_pfg_body" || { echo "FAIL: (n.1) — phase_preflight does not mark WARN for the capture gap; the --dry-run branch must record a non-blocking WARN per the in-file non-blocking-preview precedent, never PASS"; failures=$((failures+1)); }
  # control: the same matcher over the same extraction must NOT find a result
  # token that is not there, or the assertion above passes on any mark_phase line.
  ! /usr/bin/grep -qF 'mark_phase "preflight" "ZZFABRICATEDZZ"' <<<"$_pfg_body" || { echo "FAIL: (n.1) control — the mark_phase matcher matched a fabricated result token"; failures=$((failures+1)); }
  # NON-BLOCKING is the half a token grep cannot see: `return 2` under the same
  # WARN would block the very dry run the ruling exempts. Bound to the WARN line
  # by CONTEXT — phase_preflight carries two bare `return 0` lines, so an unbound
  # grep is satisfied by the function's own terminal return and measures nothing.
  # Captured, not piped: `… | grep -q` short-circuits and can SIGPIPE the writer,
  # which under `set -o pipefail` reddens this arm on a healthy file.
  local _pfg_warn; _pfg_warn="$(/usr/bin/grep -A2 -F 'mark_phase "preflight" "WARN"' <<<"$_pfg_body" || true)"
  /usr/bin/grep -qE '^[[:space:]]*return 0$' <<<"$_pfg_warn" || { echo "FAIL: (n.1) — the preflight capture-gap WARN must be NON-blocking (return 0 on the WARN branch); a WARN that returns non-zero blocks the dry run the ruling exempts"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'FAILS the close at --apply' <<<"$_pfg_body" || { echo "FAIL: (n.1) — the --dry-run WARN must name the condition that FAILS at --apply; without the tail clause the WARN reads as a permanent waiver rather than a deferred failure"; failures=$((failures+1)); }

  local _pfg_prod; _pfg_prod="$(/usr/bin/sed -n '/^phase_preflight || {/,/^phase_audit_epic_rollup/p' "${BASH_SOURCE[0]}" || true)"
  local _pfg_n_pf _pfg_n_br _pfg_n_log
  _pfg_n_pf="$(/usr/bin/grep -n '^phase_preflight ||' <<<"$_pfg_prod" | /usr/bin/cut -d: -f1)"
  _pfg_n_br="$(/usr/bin/grep -n '^phase_create_chore_branch ||' <<<"$_pfg_prod" | /usr/bin/cut -d: -f1)"
  _pfg_n_log="$(/usr/bin/grep -n '^phase_transition_release_log ||' <<<"$_pfg_prod" | /usr/bin/cut -d: -f1)"
  [[ -n "$_pfg_n_pf" && -n "$_pfg_n_br" && -n "$_pfg_n_log" && "$_pfg_n_pf" -lt "$_pfg_n_br" && "$_pfg_n_br" -lt "$_pfg_n_log" ]] || { echo "FAIL: (n) — dispatch order must be preflight < create_chore_branch < transition_release_log (got $_pfg_n_pf / $_pfg_n_br / $_pfg_n_log)"; failures=$((failures+1)); }
  # control: the same extraction finds a genuinely absent phase → nothing.
  ! /usr/bin/grep -qE '^phase_zzfabricatedzz \|\|' <<<"$_pfg_prod" || { echo "FAIL: (n) control — the dispatch extractor matched a fabricated phase name"; failures=$((failures+1)); }

  # ── (o) GATE↔BACKSTOP PARITY, as MECHANISM rather than convention. The gate is
  # a fixed conjunction; 6.7 is an ordered ladder that later cards will extend.
  # Two shapes cannot be held in agreement by construction, so the implication is
  # asserted directly, over the SAME fixture matrix:
  #     _learnings_capture_gap returns 0  ==>  phase_append_release_learnings returns 3
  # No arm above can catch a violation: (l) and (m) grade the gate alone, and the
  # 6.7 arms grade the backstop alone. A new SKIP arm added to 6.7 without a
  # matching arm here reddens THIS assertion and nothing else.
  local _pfg_cell _pfg_gap _pfg_rc _pfg_gaps=0
  for _pfg_cell in placed synth-absent synth-empty render-0 render-N; do
    _vl_write; VERSION="v9.95"; MODE="apply"; SYNTHESIZE_LEARNINGS="$_vl_sl"
    case "$_pfg_cell" in
      placed)
        PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
        phase_append_release_learnings >/dev/null 2>&1 || true
        SYNTHESIZE_LEARNINGS="$_vl_sl_zero" ;;
      synth-absent) SYNTHESIZE_LEARNINGS="$_vl_tmp/definitely-not-here.sh" ;;
      synth-empty)  SYNTHESIZE_LEARNINGS="$_vl_sl_empty" ;;
      render-0)     SYNTHESIZE_LEARNINGS="$_vl_sl_zero" ;;
      render-N)     SYNTHESIZE_LEARNINGS="$_vl_sl" ;;
    esac
    _pfg_gap=0; _learnings_capture_gap || _pfg_gap=1
    PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
    _pfg_rc=0; phase_append_release_learnings >/dev/null 2>&1 || _pfg_rc=$?
    if [[ "$_pfg_gap" -eq 0 && "$_pfg_rc" -ne 3 ]]; then
      echo "FAIL: (o) parity [$_pfg_cell] — the gate reports a capture gap but phase_append_release_learnings returned $_pfg_rc, not 3: preflight would block a close the backstop waves through"; failures=$((failures+1))
    fi
    if [[ "$_pfg_gap" -eq 0 ]]; then _pfg_gaps=$((_pfg_gaps+1)); fi
  done
  # control: the implication is VACUOUSLY true if no cell ever produces a gap.
  # Assert the matrix actually exercised the antecedent, or this arm is inert and
  # indistinguishable from a passing one.
  [[ "$_pfg_gaps" -ge 1 ]] || { echo "FAIL: (o) control — no matrix cell produced a capture gap, so the parity implication was vacuous and this arm asserted nothing"; failures=$((failures+1)); }
  SYNTHESIZE_LEARNINGS="$_vl_sl"; VERSION="v9.95"; MODE="apply"

  # ── (f)(g)(i) POST-ARCHIVAL. Separate tmp dir so the segment glob cannot see,
  # or be seen by, the hot-only cases above.
  local _vl_atmp; _vl_atmp="$(/usr/bin/mktemp -d -t velocity-archived.XXXXXX)"
  local _vl_aseg="$_vl_atmp/RELEASE_LOG_ARCHIVE-v9.md"
  local _vl_write_archived
  _vl_write_archived() {
    /bin/cat > "$RELEASE_LOG" <<'EOF'
# RELEASE_LOG

#### Deployment Log v9.93
_Archived: [segment](RELEASE_LOG_ARCHIVE-v9.md)_

#### Deployment Log v9.92
_Archived: [segment](RELEASE_LOG_ARCHIVE-v9.md)_
EOF
    /bin/cat > "$_vl_aseg" <<'EOF'
# RELEASE_LOG_ARCHIVE-v9

#### Deployment Log v9.93
**Mechanism:** git merge.
**Cycle-Time:** 5d 0h.
**Result:** SUCCESS — archived body.

#### Deployment Log v9.92
**Mechanism:** git merge.
**Cycle-Time:** 4d 0h.
**Result:** SUCCESS — archived sibling.
EOF
  }
  RELEASE_LOG="$_vl_atmp/RELEASE_LOG.md"
  COMPUTE_VELOCITY="$_vl_cv"; SYNTHESIZE_LEARNINGS="$_vl_sl"

  # (f) CO-LOCATION. The velocity field must land in the SEGMENT — the same file
  # and the same block as this version's **Result:** line — with the hot stub
  # left at zero. A hot-ledger write here exits 0 and still parses under the
  # consumer grammar, so co-location is the only observable that separates the
  # two.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _vl_write_archived; VERSION="v9.93"
  phase_inject_velocity_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_velocity_field)" == PASS\|* ]] || { echo "FAIL: archived-block velocity inject should PASS, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  [[ "$(_vl_count "$_vl_aseg" v9.93)" -eq 1 ]] || { echo "FAIL: the velocity field must land in the ARCHIVE SEGMENT for an archived block"; failures=$((failures+1)); }
  [[ "$(_vl_count "$RELEASE_LOG" v9.93)" -eq 0 ]] || { echo "FAIL: nothing may be written into the hot stub when the body is archived (split record: parses fine, still broken)"; failures=$((failures+1)); }
  local _vl_aseq; _vl_aseq="$(_vl_seq "$_vl_aseg" v9.93)"
  [[ "$_vl_aseq" == "Mechanism Cycle-Time Velocity Result " ]] || { echo "FAIL: segment field order must be 'Mechanism Cycle-Time Velocity Result ', got '$_vl_aseq'"; failures=$((failures+1)); }
  [[ "$(_vl_count "$_vl_aseg" v9.92)" -eq 0 ]] || { echo "FAIL: velocity leaked into the sibling v9.92 block inside the segment"; failures=$((failures+1)); }

  # (g) cross-surface idempotency — the probe must read the SEGMENT, not the hot
  # stub, or the re-run silently injects a SECOND copy into an archived record.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_inject_velocity_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_velocity_field)" == SKIPPED\|* ]] || { echo "FAIL: archived-block velocity re-run must SKIP (cross-surface idempotency), got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  [[ "$(_vl_count "$_vl_aseg" v9.93)" -eq 1 ]] || { echo "FAIL: archived-block re-run must not duplicate the **Velocity:** line in the segment"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'RELEASE_LOG_ARCHIVE-v9.md' <<<"$(get_phase inject_velocity_field)" || { echo "FAIL: the archived SKIP detail must name the SEGMENT it read, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }

  # (i) LEARNINGS NEVER RESOLVES TO A SEGMENT. Over the same archived fixture the
  # learnings block must land in the HOT ledger — RECORDS_POLICY KEEP_CLASS — and
  # every segment's Release Learnings count must stay 0. This is the limb that
  # would red if 6.7 were "simplified" to share 6.6's resolver.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_append_release_learnings >/dev/null 2>&1 || true
  [[ "$(get_phase append_release_learnings)" == PASS\|* ]] || { echo "FAIL: archived-block learnings append should PASS, got '$(get_phase append_release_learnings)'"; failures=$((failures+1)); }
  [[ "$(/usr/bin/grep -c '^#### Release Learnings v9\.93$' "$RELEASE_LOG")" -eq 1 ]] || { echo "FAIL: the learnings block must land in the HOT ledger even when the Deployment Log body is archived (RECORDS_POLICY KEEP_CLASS)"; failures=$((failures+1)); }
  [[ "$(/usr/bin/grep -c '^#### Release Learnings' "$_vl_aseg")" -eq 0 ]] || { echo "FAIL: a Release Learnings block must NEVER be written into an archive segment"; failures=$((failures+1)); }
  local _vl_anh; _vl_anh="$(_vl_next_h4 "$RELEASE_LOG" v9.93)"
  [[ "$_vl_anh" == "#### Release Learnings v9.93" ]] || { echo "FAIL: the learnings block must be the H4 immediately after the hot v9.93 stub, got '$_vl_anh'"; failures=$((failures+1)); }

  # dry-run parity: over the SAME archived fixture, dry-run names the real target
  # surface and writes nothing. A dry run that renders a predicted string rather
  # than the resolved one is a green rehearsal for a red run.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _vl_write_archived; VERSION="v9.93"; MODE="dry-run"
  phase_inject_velocity_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_velocity_field | /usr/bin/cut -d'|' -f1)" == "DRY-RUN" ]] || { echo "FAIL: dry-run velocity must mark DRY-RUN, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'RELEASE_LOG_ARCHIVE-v9.md' <<<"$(get_phase inject_velocity_field)" || { echo "FAIL: dry-run must name the segment it would write to, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'planned 12 pts' <<<"$(get_phase inject_velocity_field)" || { echo "FAIL: dry-run must print the RESOLVED bytes, not a predicted string, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  [[ "$(_vl_count "$_vl_aseg" v9.93)" -eq 0 ]] || { echo "FAIL: dry-run must not write"; failures=$((failures+1)); }
  MODE="apply"

  /bin/rm -rf "$_vl_atmp" 2>/dev/null || true
  /bin/rm -rf "$_vl_tmp" 2>/dev/null || true
  unset -f _vl_write _vl_write_archived _vl_seq _vl_count _vl_next_h4
  RELEASE_LOG="$_vl_saved_log"; VERSION="$_vl_saved_ver"; MODE="$_vl_saved_mode"
  COMPUTE_VELOCITY="$_vl_saved_cv"; SYNTHESIZE_LEARNINGS="$_vl_saved_sl"
  MILESTONE="$_vl_saved_ms"; MERGE_SHA="$_vl_saved_sha"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # ── Test 4c.5b: phase_inject_velocity_field × the producer's EXIT-CLASS contract
  #
  # Offline, hermetic, self-contained (own tmp dir, own fixture, own teardown),
  # and deliberately SEPARATE from Test 4c.5 above: 4c.5 grades WHERE the field
  # lands, this grades whether the phase may write one AT ALL. Arm letters
  # continue the group's space, which 4c.5 currently ends at (o).
  #
  # THE REGRESSION THIS EXISTS FOR: a producer exit 2 used to fall into the same
  # branch as "the tool is missing" and be recorded as `**Velocity:** N/A`. A
  # refusal to measure became a measurement — written to a permanent ledger row,
  # at exit 0, with the phase reporting PASS. The distinguishing observable is
  # NOT the exit code but WHAT REACHES THE FILE, so every arm below asserts on
  # the fixture's contents as well as on the phase verdict.
  local _vd_saved_log="$RELEASE_LOG" _vd_saved_ver="$VERSION" _vd_saved_mode="$MODE"
  local _vd_saved_cv="$COMPUTE_VELOCITY" _vd_saved_ms="$MILESTONE" _vd_saved_sha="$MERGE_SHA"
  local _vd_tmp; _vd_tmp="$(/usr/bin/mktemp -d -t velocity-exitclass.XXXXXX)"
  MODE="apply"; MILESTONE="999"; MERGE_SHA=""; VERSION="v9.95"

  # One stub per exit class the phase must treat DIFFERENTLY.
  local _vd_cv_ok="$_vd_tmp/cv-ok.sh" _vd_cv_e2="$_vd_tmp/cv-exit2.sh"
  local _vd_cv_e1="$_vd_tmp/cv-exit1.sh" _vd_cv_note="$_vd_tmp/cv-note.sh"
  /bin/cat > "$_vd_cv_ok" <<'EOF'
#!/bin/sh
echo "planned 12 pts / delivered 12 pts (1.00); files-changed 9; allocation 0/12/0 pts (feature/debt/protocol-slack); class routine; mechanism: compute-release-velocity.sh"
EOF
  /bin/cat > "$_vd_cv_e2" <<'EOF'
#!/bin/sh
echo "ERROR: implausible Velocity measurement for milestone 999 - planned 18 pts against delivered 0 pts over 5 sized member(s)" >&2
exit 2
EOF
  /bin/cat > "$_vd_cv_e1" <<'EOF'
#!/bin/sh
echo "ERROR: gh CLI not found - required to read milestone membership labels" >&2
exit 1
EOF
  /bin/cat > "$_vd_cv_note" <<'EOF'
#!/bin/sh
echo "NOTE: Phase-A2 planned-recovery degraded (could not list issues carrying 'status: deferred')" >&2
echo "planned 12 pts / delivered 12 pts (1.00); files-changed 9; allocation 0/12/0 pts (feature/debt/protocol-slack); class routine; mechanism: compute-release-velocity.sh"
EOF
  /bin/chmod +x "$_vd_cv_ok" "$_vd_cv_e2" "$_vd_cv_e1" "$_vd_cv_note"

  RELEASE_LOG="$_vd_tmp/RELEASE_LOG.md"
  local _vd_write
  _vd_write() {
    /bin/cat > "$RELEASE_LOG" <<'EOF'
# RELEASE_LOG

#### Deployment Log v9.95
**Mechanism:** git merge.
**Cycle-Time:** 3d 4h; mechanism: compute-cycle-time.sh
**Result:** SUCCESS — green CI.
EOF
  }
  local _vd_vcount
  _vd_vcount() { /usr/bin/grep -c '^\*\*Velocity:\*\*' "$RELEASE_LOG" 2>/dev/null || true; }
  local _vd_rc

  # (p) EXIT 2 AT --apply = FAIL, return 3, and NOTHING written.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _vd_write; COMPUTE_VELOCITY="$_vd_cv_e2"; MODE="apply"
  _vd_rc=0; phase_inject_velocity_field >/dev/null 2>&1 || _vd_rc=$?
  [[ "$(get_phase inject_velocity_field | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: (p) — a producer exit 2 must FAIL the phase at --apply, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  [[ "$_vd_rc" -eq 3 ]] || { echo "FAIL: (p) — the phase must return 3 on a producer exit 2 so the runner halts before the close, got $_vd_rc"; failures=$((failures+1)); }
  [[ "$(_vd_vcount)" -eq 0 ]] || { echo "FAIL: (p) — nothing may be written to the ledger when the producer refuses the measurement"; failures=$((failures+1)); }
  # The detail must carry the PRODUCER's own words. A generic "tool failed" sends
  # the operator to re-run the tool to find out what it already said.
  /usr/bin/grep -qF 'implausible' <<<"$(get_phase inject_velocity_field)" || { echo "FAIL: (p) — the FAIL detail must quote the producer's stderr, not a generic message, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }

  # (p) control — the SAME fixture with a conformant producer must PASS and write
  # exactly one field. Without it, (p) is satisfied by a phase that always fails.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _vd_write; COMPUTE_VELOCITY="$_vd_cv_ok"
  phase_inject_velocity_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_velocity_field | /usr/bin/cut -d'|' -f1)" == "PASS" ]] || { echo "FAIL: (p) control — the same fixture with a conformant producer must PASS, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  [[ "$(_vd_vcount)" -eq 1 ]] || { echo "FAIL: (p) control — the conformant run must write exactly one **Velocity:** line, got $(_vd_vcount)"; failures=$((failures+1)); }

  # (q) EXIT 2 UNDER --dry-run = non-blocking WARN per the release-wide dry-run /
  # apply ruling, naming the condition that fails at apply, and still writing
  # nothing. A dry run that BLOCKED here would halt a rehearsal that corrupts
  # nothing; one that stayed silent would rehearse green for a red run.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _vd_write; COMPUTE_VELOCITY="$_vd_cv_e2"; MODE="dry-run"
  _vd_rc=0; phase_inject_velocity_field >/dev/null 2>&1 || _vd_rc=$?
  [[ "$(get_phase inject_velocity_field | /usr/bin/cut -d'|' -f1)" == "WARN" ]] || { echo "FAIL: (q) — a producer exit 2 under --dry-run must mark WARN per the in-file non-blocking-preview precedent, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  [[ "$_vd_rc" -eq 0 ]] || { echo "FAIL: (q) — the dry-run WARN must be NON-blocking (return 0), got $_vd_rc"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'FAILS the close at --apply' <<<"$(get_phase inject_velocity_field)" || { echo "FAIL: (q) — the dry-run WARN must name the condition that fails at --apply, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  [[ "$(_vd_vcount)" -eq 0 ]] || { echo "FAIL: (q) — a dry run must not write"; failures=$((failures+1)); }
  MODE="apply"

  # (r) EXIT 2 IS NOT AN N/A. The refusal must not be laundered into the explicit
  # N/A form, which parses cleanly and reads as an honest "not measurable".
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _vd_write; COMPUTE_VELOCITY="$_vd_cv_e2"
  phase_inject_velocity_field >/dev/null 2>&1 || true
  ! /usr/bin/grep -q '^\*\*Velocity:\*\* N/A' "$RELEASE_LOG" || { echo "FAIL: (r) — a producer exit 2 was degraded to an 'N/A' field; a refusal to measure must never be recorded as a measurement"; failures=$((failures+1)); }

  # (r) SENSITIVITY — exit 1 is the generic-unavailable class and MUST still
  # degrade to N/A at PASS. Without this arm (r) is equally satisfied by a phase
  # that blanket-fails every non-zero exit, which would break the legitimate
  # gh-unavailable path the standard's manual-fill fallback rests on.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _vd_write; COMPUTE_VELOCITY="$_vd_cv_e1"
  phase_inject_velocity_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_velocity_field | /usr/bin/cut -d'|' -f1)" == "PASS" ]] || { echo "FAIL: (r) sensitivity — a producer exit 1 must STILL degrade to an N/A field at PASS, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  /usr/bin/grep -q '^\*\*Velocity:\*\* N/A' "$RELEASE_LOG" || { echo "FAIL: (r) sensitivity — the exit-1 degrade must write the explicit N/A field, or the exit-2 arm above proves nothing about exit 2 specifically"; failures=$((failures+1)); }

  # (s) A SUCCESSFUL run's stderr still reaches the report. The producer announces
  # a DEGRADED Phase-A2 planned-recovery there — a condition that under-reports
  # `planned`, i.e. makes the ratio look HEALTHIER than the truth. Discarded
  # stderr is how that becomes invisible.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _vd_write; COMPUTE_VELOCITY="$_vd_cv_note"
  phase_inject_velocity_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_velocity_field | /usr/bin/cut -d'|' -f1)" == "PASS" ]] || { echo "FAIL: (s) — a producer that writes a NOTE to stderr but a conformant field to stdout must still PASS, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'planned-recovery degraded' <<<"$(get_phase inject_velocity_field)" || { echo "FAIL: (s) — a degraded planned-recovery notice must reach the run report; on stderr alone it is discarded and 'planned' under-reports invisibly, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }
  [[ "$(_vd_vcount)" -eq 1 ]] || { echo "FAIL: (s) — the stderr note must not disturb the write; expected exactly one **Velocity:** line, got $(_vd_vcount)"; failures=$((failures+1)); }

  # (s) control — a SILENT producer must add no note, or the note is decoration
  # rather than a signal that something happened.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _vd_write; COMPUTE_VELOCITY="$_vd_cv_ok"
  phase_inject_velocity_field >/dev/null 2>&1 || true
  ! /usr/bin/grep -qF 'producer stderr:' <<<"$(get_phase inject_velocity_field)" || { echo "FAIL: (s) control — a silent producer must add no stderr note to the phase detail, got '$(get_phase inject_velocity_field)'"; failures=$((failures+1)); }

  /bin/rm -rf "$_vd_tmp" 2>/dev/null || true
  unset -f _vd_write _vd_vcount
  RELEASE_LOG="$_vd_saved_log"; VERSION="$_vd_saved_ver"; MODE="$_vd_saved_mode"
  COMPUTE_VELOCITY="$_vd_saved_cv"; MILESTONE="$_vd_saved_ms"; MERGE_SHA="$_vd_saved_sha"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # ── Test 4c.6: phase_inject_close_class_telemetry_field (6.8) — offline, hermetic.
  #
  # The producer is STUBBED (the real one reaches `gh` and the operator-instance
  # registers) but every stub emits the REAL § 3.2 shape, so the grammar and
  # measuredness asserts run against realistic bytes.
  #
  # THE ARM THAT MATTERS IS THE VACUITY PAIR. A structurally perfect line whose
  # every rate slot reads `N/A` is REACHABLE at exit 0 (no gh degrades Indicators
  # 3 and 6; no register degrades 1, 2 and 5; the conditions co-occur), and it
  # satisfies the grammar assert completely. Two runs identical except for that
  # property must produce DIFFERENT outcome details — a fixture whose two arms
  # agree would be measuring nothing, which is the same broken-probe shape the
  # Indicator-5 fix exists to remove. Note the deliberate severity asymmetry:
  # producer-side the vacuity reading is a WARNING on a written field, gate-side
  # (deploy.sh Check 48 sub-check l-3a) the same reading is a finding.
  #
  # Indicator 5's own bivalence (marker present -> present / absent -> absent /
  # no register -> N/A) is NOT re-tested here: it is a property of
  # compute-close-class-telemetry.sh and is asserted in that tool's own
  # --self-test (its Tests 5b-5d, including the substring-vs-whole-line control).
  # Re-driving it through a stub here would assert the stub, not the tool.
  local _cc_saved_log="$RELEASE_LOG" _cc_saved_ver="$VERSION" _cc_saved_mode="$MODE"
  local _cc_saved_tool="$COMPUTE_CLOSE_CLASS_TELEMETRY" _cc_saved_ms="$MILESTONE"
  local _cc_tmp; _cc_tmp="$(/usr/bin/mktemp -d -t closeclass-selftest.XXXXXX)"
  MODE="apply"; MILESTONE="999"
  RELEASE_LOG="$_cc_tmp/RELEASE_LOG.md"

  local _cc_ok="$_cc_tmp/cct-ok.sh" _cc_vac="$_cc_tmp/cct-vac.sh" _cc_bad="$_cc_tmp/cct-bad.sh"
  local _cc_empty="$_cc_tmp/cct-empty.sh" _cc_e2="$_cc_tmp/cct-e2.sh" _cc_noexec="$_cc_tmp/cct-noexec.sh"
  /bin/cat > "$_cc_ok" <<'EOF'
#!/bin/sh
echo "retro-conformance 10/10 (1.00); lessons-population 8/10 (0.80); carry-forward-closure 2/3 (0.67); pattern-emergence deferred-to-aggregate (see synthesize-release-learnings.sh); rollup-presence present; evidence-preservation 12/13 (0.92); evidence-close-gate pass; mechanism: compute-close-class-telemetry.sh"
EOF
  # Conformant AND vacuous: the reachable gh-less + no-register shape.
  /bin/cat > "$_cc_vac" <<'EOF'
#!/bin/sh
echo "retro-conformance N/A — no retro register found for v9.96; lessons-population N/A — no lessons register found; carry-forward-closure N/A — gh unavailable — carry-forward closure not computed; pattern-emergence deferred-to-aggregate (see synthesize-release-learnings.sh); rollup-presence N/A — no retro register found; evidence-preservation N/A — gh unavailable — phase-evidence preservation not computed; evidence-close-gate N/A; mechanism: compute-close-class-telemetry.sh"
EOF
  /bin/cat > "$_cc_bad" <<'EOF'
#!/bin/sh
echo "retro-conformance 10/10 (1.00); rollup-presence present; mechanism: compute-close-class-telemetry.sh"
EOF
  /bin/cat > "$_cc_empty" <<'EOF'
#!/bin/sh
printf '  \n'
exit 0
EOF
  /bin/cat > "$_cc_e2" <<'EOF'
#!/bin/sh
echo "ERROR: retro register exists but is unreadable" >&2
exit 2
EOF
  /bin/cat > "$_cc_noexec" <<'EOF'
#!/bin/sh
echo "this stub is deliberately NOT chmod +x"
EOF
  /bin/chmod +x "$_cc_ok" "$_cc_vac" "$_cc_bad" "$_cc_empty" "$_cc_e2"

  # v9.96 carries **Outcome rationale:** (primary anchor); v9.97 carries only
  # **Outcome:** (fallback anchor); v9.98 is an untouched sibling.
  local _cc_write
  _cc_write() {
    /bin/cat > "$RELEASE_LOG" <<'EOF'
# RELEASE_LOG

#### Deployment Log v9.96
**Cycle-Time:** 3d 4h.
**Result:** SUCCESS — green CI.
**Outcome:** SUCCESS
**Outcome rationale:** every declared limb landed.

#### Deployment Log v9.97
**Cycle-Time:** 1d 0h.
**Result:** SUCCESS — no rationale line.
**Outcome:** SUCCESS

#### Deployment Log v9.98
**Cycle-Time:** 2d 0h.
**Result:** SUCCESS — untouched sibling.
**Outcome:** SUCCESS
EOF
  }
  # Count `**Close-Class-Telemetry:**` lines inside ONE version's block on ONE file.
  local _cc_count
  _cc_count() {
    /usr/bin/awk -v ver="$2" '
      { line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line) }
      line == "#### Deployment Log " ver { inblk = 1; next }
      inblk && line ~ /^#### / { inblk = 0 }
      inblk && line ~ /^\*\*Close-Class-Telemetry:\*\*/ { n++ }
      END { print n + 0 }
    ' "$1" 2>/dev/null || echo 0
  }
  # Field-name sequence inside a version's block — proves POSITION, not presence.
  # The field-name class admits a SPACE: `**Outcome rationale:**` is a real field
  # in this block and the space-less class used elsewhere silently drops it,
  # which would collapse the primary-anchor arm and the fallback-anchor arm onto
  # the same expected string and make the pair unfalsifiable.
  local _cc_seq
  _cc_seq() {
    /usr/bin/awk -v ver="$2" '
      { line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line) }
      line == "#### Deployment Log " ver { inblk = 1; next }
      inblk && line ~ /^#### / { inblk = 0 }
      inblk && line ~ /^\*\*[A-Za-z][A-Za-z -]*:\*\*/ {
        n = line; sub(/:\*\*.*$/, "", n); sub(/^\*\*/, "", n); printf "%s ", n
      }
    ' "$1" 2>/dev/null || true
  }

  COMPUTE_CLOSE_CLASS_TELEMETRY="$_cc_ok"

  # (a) clean block, primary anchor — PASS, positioned after **Outcome rationale:**.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _cc_write; VERSION="v9.96"
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_close_class_telemetry_field)" == PASS\|* ]] || { echo "FAIL: close-class inject on a clean block should PASS, got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }
  local _cc_s; _cc_s="$(_cc_seq "$RELEASE_LOG" v9.96)"
  [[ "$_cc_s" == "Cycle-Time Result Outcome Outcome rationale Close-Class-Telemetry " ]] || { echo "FAIL: field order must place Close-Class-Telemetry after 'Outcome rationale', got '$_cc_s'"; failures=$((failures+1)); }
  [[ "$(_cc_count "$RELEASE_LOG" v9.98)" -eq 0 ]] || { echo "FAIL: the field leaked into the sibling v9.98 block"; failures=$((failures+1)); }

  # (b) idempotent re-run — SKIPPED, no duplicate.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_close_class_telemetry_field)" == SKIPPED\|* ]] || { echo "FAIL: close-class re-run must SKIP, got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }
  [[ "$(_cc_count "$RELEASE_LOG" v9.96)" -eq 1 ]] || { echo "FAIL: re-run must not duplicate the **Close-Class-Telemetry:** line"; failures=$((failures+1)); }

  # (c) FALLBACK ANCHOR — a block with **Outcome:** but no rationale line still
  # lands the field, immediately after **Outcome:**.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _cc_write; VERSION="v9.97"
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_close_class_telemetry_field)" == PASS\|* ]] || { echo "FAIL: fallback-anchor inject should PASS, got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }
  _cc_s="$(_cc_seq "$RELEASE_LOG" v9.97)"
  [[ "$_cc_s" == "Cycle-Time Result Outcome Close-Class-Telemetry " ]] || { echo "FAIL: fallback anchor must place the field after **Outcome:**, got '$_cc_s'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'carries no **Outcome rationale:** field' <<<"$(get_phase inject_close_class_telemetry_field)" || { echo "FAIL: the fallback path must name which anchor it used, got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }

  # (d) THE VACUITY PAIR — the arm this phase exists to make observable. Both
  # lines are grammar-conformant; only one carries a computed ratio. The two
  # arms MUST disagree.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _cc_write; VERSION="v9.96"; COMPUTE_CLOSE_CLASS_TELEMETRY="$_cc_vac"
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_close_class_telemetry_field)" == PASS\|* ]] || { echo "FAIL: an all-N/A but conformant field must still be WRITTEN (an honest N/A is the mandated form; a degraded environment is not a close-out failure), got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }
  [[ "$(_cc_count "$RELEASE_LOG" v9.96)" -eq 1 ]] || { echo "FAIL: the vacuous-but-conformant field must be written exactly once"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'carries NO computed ratio' <<<"$(get_phase inject_close_class_telemetry_field)" || { echo "FAIL: a field with no computed ratio must say so — silence here is how a vacuous row reads as a measured one; got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'gh was unavailable' <<<"$(get_phase inject_close_class_telemetry_field)" || { echo "FAIL: the disposition must be read from the emitted LINE (the exit code cannot carry it — the gh-less path exits 0), got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }
  # CONTROL — the measured line must NOT carry the vacuity warning. Without this
  # arm the assert above is satisfied by a phase that always warns.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _cc_write; COMPUTE_CLOSE_CLASS_TELEMETRY="$_cc_ok"
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  if /usr/bin/grep -qF 'carries NO computed ratio' <<<"$(get_phase inject_close_class_telemetry_field)"; then
    echo "FAIL: control — a MEASURED field must NOT carry the vacuity warning (the arm above would be vacuous)"; failures=$((failures+1))
  fi

  # (e) non-conformant producer output — FAIL, and nothing is written.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _cc_write; COMPUTE_CLOSE_CLASS_TELEMETRY="$_cc_bad"
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_close_class_telemetry_field | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: a line missing § 3.2 slots must FAIL the grammar self-assert, got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }
  [[ "$(_cc_count "$RELEASE_LOG" v9.96)" -eq 0 ]] || { echo "FAIL: a grammar failure must write nothing"; failures=$((failures+1)); }

  # (f) empty capture at exit 0 — FAIL, writes nothing. A `$( )` capture can be
  # EMPTY at exit 0, which an exit-code check alone cannot see.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _cc_write; COMPUTE_CLOSE_CLASS_TELEMETRY="$_cc_empty"
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_close_class_telemetry_field | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: an empty producer capture at exit 0 must FAIL, never write a bare field, got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }
  [[ "$(_cc_count "$RELEASE_LOG" v9.96)" -eq 0 ]] || { echo "FAIL: an empty capture must write nothing"; failures=$((failures+1)); }

  # (g) exit 2 — SOURCE INTEGRITY, escalated with its own diagnostic rather than
  # folded into the generic failure. Exit 2 means a register EXISTS but is
  # UNREADABLE; recording an N/A here would misreport a permissions fault as an
  # absent artifact.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _cc_write; COMPUTE_CLOSE_CLASS_TELEMETRY="$_cc_e2"
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_close_class_telemetry_field | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: producer exit 2 must FAIL, got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'UNREADABLE' <<<"$(get_phase inject_close_class_telemetry_field)" || { echo "FAIL: exit 2 must be reported as a source-integrity condition, not a generic producer failure, got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }
  [[ "$(_cc_count "$RELEASE_LOG" v9.96)" -eq 0 ]] || { echo "FAIL: a source-integrity abort must write nothing"; failures=$((failures+1)); }

  # (h) producer NOT executable — SKIP, write nothing. The field asserts
  # `mechanism: compute-close-class-telemetry.sh`; composing one without that
  # mechanism fabricates the claim the field exists to measure.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _cc_write; COMPUTE_CLOSE_CLASS_TELEMETRY="$_cc_noexec"
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_close_class_telemetry_field)" == SKIPPED\|* ]] || { echo "FAIL: a non-executable producer must SKIP, got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }
  [[ "$(_cc_count "$RELEASE_LOG" v9.96)" -eq 0 ]] || { echo "FAIL: a missing producer must write nothing — a hand-composed field would fabricate its own mechanism claim"; failures=$((failures+1)); }

  # (i) dry-run — marks DRY-RUN, prints the RESOLVED bytes, writes nothing. Under
  # the Indicator-5 fix the resolved value reads nothing an earlier phase in this
  # run wrote, so dry-run and apply resolve the same bytes by construction.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _cc_write; COMPUTE_CLOSE_CLASS_TELEMETRY="$_cc_ok"; MODE="dry-run"
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_close_class_telemetry_field | /usr/bin/cut -d'|' -f1)" == "DRY-RUN" ]] || { echo "FAIL: dry-run must mark DRY-RUN, got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'retro-conformance 10/10 (1.00)' <<<"$(get_phase inject_close_class_telemetry_field)" || { echo "FAIL: dry-run must print the RESOLVED bytes, not a predicted string, got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }
  [[ "$(_cc_count "$RELEASE_LOG" v9.96)" -eq 0 ]] || { echo "FAIL: dry-run must not write"; failures=$((failures+1)); }
  MODE="apply"

  # (j) CO-LOCATION over an ARCHIVED block. The field must land in the SEGMENT,
  # beside its own **Result:**, with the hot stub left at zero. A hot-ledger write
  # exits 0, passes a corpus-wide grep AND passes the grammar assert — co-location
  # is the only observable that separates the two, and it is the producer-side
  # twin of Check 48 sub-check l-1.
  local _cc_atmp; _cc_atmp="$(/usr/bin/mktemp -d -t closeclass-arch.XXXXXX)"
  local _cc_aseg="$_cc_atmp/RELEASE_LOG_ARCHIVE-v9.md"
  RELEASE_LOG="$_cc_atmp/RELEASE_LOG.md"
  /bin/cat > "$RELEASE_LOG" <<'EOF'
# RELEASE_LOG

#### Deployment Log v9.96
_Archived: [segment](RELEASE_LOG_ARCHIVE-v9.md)_
EOF
  /bin/cat > "$_cc_aseg" <<'EOF'
# RELEASE_LOG_ARCHIVE-v9

#### Deployment Log v9.96
**Cycle-Time:** 5d 0h.
**Result:** SUCCESS — archived body.
**Outcome:** SUCCESS
EOF
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  VERSION="v9.96"
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_close_class_telemetry_field)" == PASS\|* ]] || { echo "FAIL: archived-block close-class inject should PASS, got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }
  [[ "$(_cc_count "$_cc_aseg" v9.96)" -eq 1 ]] || { echo "FAIL: the close-class field must land in the ARCHIVE SEGMENT for an archived block"; failures=$((failures+1)); }
  [[ "$(_cc_count "$RELEASE_LOG" v9.96)" -eq 0 ]] || { echo "FAIL: nothing may be written into the hot stub when the body is archived (split record: parses fine, still broken)"; failures=$((failures+1)); }
  # cross-surface idempotency — the probe must read the SEGMENT, not the stub.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  [[ "$(get_phase inject_close_class_telemetry_field)" == SKIPPED\|* ]] || { echo "FAIL: archived-block re-run must SKIP (cross-surface idempotency), got '$(get_phase inject_close_class_telemetry_field)'"; failures=$((failures+1)); }
  [[ "$(_cc_count "$_cc_aseg" v9.96)" -eq 1 ]] || { echo "FAIL: archived-block re-run must not duplicate the field in the segment"; failures=$((failures+1)); }

  # ── (j.1) THE NOT-PRODUCED MARKER'S STAGING RECORD MUST SURVIVE THE CALL.
  # THE DEFECT (#5288 DT AI-028). _write_not_produced_marker ends by calling
  # _record_touched_archive_segment — the recorder whose array phase_commit_chore_pr's
  # files=() consumes. Both production call sites invoked the writer inside a COMMAND
  # SUBSTITUTION, so that append died with the subshell. Neither independent guard
  # covers it: the commit phase's files=() carries no archive glob, and the
  # staging-completeness arm filters to `inject_*` phases with a PASS result, and
  # neither marker site carries both (6.7 is not inject_*; this one is inject_* but
  # marks SKIPPED). The live path — archived block + producer unavailable + dormant
  # cutover, today's default — wrote the marker to a segment, never staged the
  # segment, dropped the marker at commit, and reported "Absence RECORDED".
  #
  # This arm drives the REAL production call site (not the writer directly) over the
  # archived fixture above and asserts the RECORD, because the record is the interface
  # files=() reads. Pre-fix it fails on the staging assertion ALONE: the marker still
  # reaches disk (the subshell's file write persists), so the sensitivity floor below
  # stays green and the differential isolates exactly the lost append.
  local _np_e _np_joined="" _np_hit=0
  /bin/cat > "$RELEASE_LOG" <<'EOF'
# RELEASE_LOG

#### Deployment Log v9.96
_Archived: [segment](RELEASE_LOG_ARCHIVE-v9.md)_
EOF
  /bin/cat > "$_cc_aseg" <<'EOF'
# RELEASE_LOG_ARCHIVE-v9

#### Deployment Log v9.96
**Cycle-Time:** 5d 0h.
**Result:** SUCCESS — archived body.
**Outcome:** SUCCESS
EOF
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  TOUCHED_ARCHIVE_SEGMENTS=()
  MODE="apply"; VERSION="v9.96"
  COMPUTE_CLOSE_CLASS_TELEMETRY="$_cc_atmp/definitely-not-here.sh"
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  # sensitivity floor: the marker must genuinely have been written to the SEGMENT.
  # Without it the staging assertion below could pass-by-absence on a run in which
  # the emit path never fired at all.
  [[ "$(grep_count -F '**Not-produced:** close-class-telemetry ' "$_cc_aseg")" -eq 1 ]] || { echo "FAIL: (j.1) sensitivity — the capability skip must have written a **Not-produced:** marker into the ARCHIVE SEGMENT; without it the staging assertion below is untestable"; failures=$((failures+1)); }
  for _np_e in "${TOUCHED_ARCHIVE_SEGMENTS[@]:-}"; do
    [[ -z "$_np_e" ]] && continue
    _np_joined="${_np_joined}${_np_e} "
  done
  case " $_np_joined" in *" $_cc_aseg "*) _np_hit=1 ;; esac
  [[ "$_np_hit" -eq 1 ]] || { echo "FAIL: (j.1) — the marker was written into an archive segment but the segment was NOT recorded in TOUCHED_ARCHIVE_SEGMENTS, so files=() never names it and the marker is DROPPED at commit while the phase reports 'Absence RECORDED' (got: '${_np_joined:-<empty>}'). The writer must not be called in a command substitution — the append does not survive the subshell"; failures=$((failures+1)); }
  # CONTROL — a marker that lands in the HOT LEDGER must NOT be recorded. That skip
  # is BY DESIGN (files=() names the hot ledger unconditionally), and without this
  # arm the assertion above is equally satisfied by a recorder that appends every
  # target it is handed. Same producer, same mode, one variable moved: the block is
  # no longer archived.
  /bin/cat > "$RELEASE_LOG" <<'EOF'
# RELEASE_LOG

#### Deployment Log v9.96
**Cycle-Time:** 5d 0h.
**Result:** SUCCESS — hot body.
**Outcome:** SUCCESS
EOF
  /bin/rm -f "$_cc_aseg" 2>/dev/null || true
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  TOUCHED_ARCHIVE_SEGMENTS=()
  phase_inject_close_class_telemetry_field >/dev/null 2>&1 || true
  # the control's own vacuity floor — it must pass because the hot ledger is SKIPPED,
  # never because the emit path failed to fire.
  [[ "$(grep_count -F '**Not-produced:** close-class-telemetry ' "$RELEASE_LOG")" -eq 1 ]] || { echo "FAIL: (j.1) control vacuity — the hot-ledger fixture must also have written a marker, or the control below passes for the wrong reason"; failures=$((failures+1)); }
  [[ "${#TOUCHED_ARCHIVE_SEGMENTS[@]}" -eq 0 ]] || { echo "FAIL: (j.1) control — a marker written into the HOT LEDGER must NOT be recorded as a touched segment (files=() already names it); the recorder is appending every target it is handed, so the assertion above measures nothing"; failures=$((failures+1)); }
  TOUCHED_ARCHIVE_SEGMENTS=()

  # ── (j.2) STRUCTURAL, BOTH SITES AND EVERY FUTURE ONE. (j.1) drives the 6.8
  # telemetry site only; the IDENTICAL shape at 6.7's learnings site is fixed the
  # same way and would not redden (j.1) if it regressed alone. Asserted over the
  # SHIPPED text of each calling phase: no call may sit inside a command
  # substitution, because that subshell is the defect. Read from the FUNCTION
  # BODIES rather than the whole file, so this arm's own needle cannot match
  # itself — a whole-file grep for this pattern is satisfied by the line you are
  # reading and measures nothing.
  local _np_67 _np_68 _np_sub
  _np_sub='$(_write_not_produced_marker'
  _np_67="$(/usr/bin/sed -n '/^phase_append_release_learnings() {/,/^}/p' "${BASH_SOURCE[0]}" || true)"
  _np_68="$(/usr/bin/sed -n '/^phase_inject_close_class_telemetry_field() {/,/^}/p' "${BASH_SOURCE[0]}" || true)"
  # vacuity floors — each extraction must actually contain the call it grades.
  /usr/bin/grep -qF '_write_not_produced_marker' <<<"$_np_67" || { echo "FAIL: (j.2) vacuity — phase_append_release_learnings does not call _write_not_produced_marker; the emit-on-absence site is gone, so the shape assertion below grades nothing"; failures=$((failures+1)); }
  /usr/bin/grep -qF '_write_not_produced_marker' <<<"$_np_68" || { echo "FAIL: (j.2) vacuity — phase_inject_close_class_telemetry_field does not call _write_not_produced_marker; the emit-on-absence site is gone, so the shape assertion below grades nothing"; failures=$((failures+1)); }
  ! /usr/bin/grep -qF "$_np_sub" <<<"$_np_67" || { echo "FAIL: (j.2) — phase_append_release_learnings invokes _write_not_produced_marker inside a command substitution; the writer records into TOUCHED_ARCHIVE_SEGMENTS and that append does not survive a subshell, so the marker lands on disk and is DROPPED at commit while the phase reports 'Absence RECORDED'"; failures=$((failures+1)); }
  ! /usr/bin/grep -qF "$_np_sub" <<<"$_np_68" || { echo "FAIL: (j.2) — phase_inject_close_class_telemetry_field invokes _write_not_produced_marker inside a command substitution; same lost-append defect as the 6.7 site"; failures=$((failures+1)); }
  # capability-to-fail: the SAME matcher over a CONSTRUCTED bad call site must
  # MATCH. Without it, both negatives above are equally satisfied by a pattern that
  # can never fire, which is indistinguishable from a clean file.
  /usr/bin/grep -qF "$_np_sub" <<<'    _x="$(_write_not_produced_marker a b c)"' || { echo "FAIL: (j.2) capability-to-fail — the command-substitution matcher does not match a constructed bad call site, so its two clean readings above measure nothing"; failures=$((failures+1)); }

  /bin/rm -rf "$_cc_atmp" 2>/dev/null || true
  /bin/rm -rf "$_cc_tmp" 2>/dev/null || true
  unset -f _cc_write _cc_count _cc_seq
  RELEASE_LOG="$_cc_saved_log"; VERSION="$_cc_saved_ver"; MODE="$_cc_saved_mode"
  COMPUTE_CLOSE_CLASS_TELEMETRY="$_cc_saved_tool"; MILESTONE="$_cc_saved_ms"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # Test 4d: phase_detect_open_issues exclude filter (#38, #3665) — offline, hermetic.
  # Stubs $GH so `gh issue list … --json number,title,labels --jq …` returns a fixed
  # `<number>\t<labels-csv>\t<title>` fixture (gh applies --jq server-side, so the
  # stub emits the already-jq'd lines), then drives phase_detect_open_issues and
  # asserts the filter: explicit --exclude-issue removes a number; the Stage-13
  # sub-task is excluded by explicit number; the `sub-task`-label + title-regex
  # `(?i)stage.?13.*close` fallback excludes an un-numbered Stage-13-close sub-task;
  # a delivered work item whose TITLE matches but which carries no sub-task label
  # SURVIVES (#3665 AC-4); and a sub-task labelled but NOT Stage-13 also survives —
  # the guard proving the label alone is not the matcher.
  local _ex_saved_gh="$GH" _ex_saved_mode="$MODE" _ex_saved_slug="$STATE_MILESTONE_SLUG"
  local _ex_saved_list="$OPEN_ISSUE_LIST" _ex_saved_count="$OPEN_ISSUE_COUNT"
  local _ex_tmp; _ex_tmp="$(/usr/bin/mktemp -d -t excl-selftest.XXXXXX)"
  local _ex_stub="$_ex_tmp/gh-stub.sh"
  # Stub: fixture has a normal anomaly issue (#401), an explicit-exclude target
  # (#999), the Stage-13 orchestration sub-task (#500, label + title match), a decoy
  # with "stage 13" but NOT "close" (#600), the #3665 regression fixture (#2678 —
  # delivered work item, Stage-13-close TITLE, NO sub-task label), the legacy-alias
  # sub-task (#501, `type:subtask`), and the anti-over-exclude control (#502 —
  # sub-task label but a Stage-5 title).
  /bin/cat > "$_ex_stub" <<'STUB'
#!/usr/bin/env bash
# Minimal gh stub for the #38 / #3665 detect_open_issues self-test. Emits the jq'd
# number<TAB>labels<TAB>title lines for `issue list`; no-op (exit 0) otherwise.
case "$1" in
  issue)
    if [[ "$2" == "list" ]]; then
      printf '%s\t%s\t%s\n' 401 "bug" "Normal auto-close anomaly issue"
      printf '%s\t%s\t%s\n' 999 "sub-task" "Some explicitly-excluded sub-task"
      printf '%s\t%s\t%s\n' 500 "sub-task,status: bundled" "Stage 13 — Close: corpus update orchestration"
      printf '%s\t%s\t%s\n' 600 "improvement,type:task" "Stage 13 plan-review follow-up task"
      printf '%s\t%s\t%s\n' 2678 "bug,project:pipeline" "Stage-13 automated close-out publishes GitHub Release with placeholder notes"
      printf '%s\t%s\t%s\n' 501 "type:subtask" "Stage 13 Close — legacy-alias-milestone"
      printf '%s\t%s\t%s\n' 502 "sub-task" "Stage 5 Solutioning — matcher design (release-closeout-integrity)"
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

  # (b) label+title fallback alone (no explicit numbers): #500 and #501 are still
  #     excluded; #401, #600, #999, #2678 and #502 survive. Legs (b1)-(b6) below are
  #     the #3665 contract — (b2) and (b4) FAIL against the pre-#3665 title-only
  #     matcher, which is what makes this fixture a regression test rather than
  #     decoration.
  EXCLUDE_ISSUES=()
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_detect_open_issues >/dev/null 2>&1
  # (b1) R5 preserved: a real Stage-13 orchestration sub-task is still excluded.
  /usr/bin/printf '%s\n' "$OPEN_ISSUE_LIST" | /usr/bin/grep -qx '500' && { echo "FAIL: #500 must be excluded by the label+title fallback when not passed by number"; failures=$((failures+1)); }
  /usr/bin/printf '%s\n' "$OPEN_ISSUE_LIST" | /usr/bin/grep -qx '401' || { echo "FAIL: #401 must survive (label+title fallback path)"; failures=$((failures+1)); }
  # (b2) #3665 AC-4 regression: a DELIVERED work item whose title matches the
  #      Stage-13-close regex but which carries no sub-task label must SURVIVE and be
  #      closed. Title-only matching false-excluded 13 such issues.
  /usr/bin/printf '%s\n' "$OPEN_ISSUE_LIST" | /usr/bin/grep -qx '2678' || { echo "FAIL: #2678 (delivered work item, Stage-13-close title, NO sub-task label) must SURVIVE — this is the #3665 false-exclusion"; failures=$((failures+1)); }
  # (b3) legacy alias `type:subtask` is accepted as a sub-task-family label.
  /usr/bin/printf '%s\n' "$OPEN_ISSUE_LIST" | /usr/bin/grep -qx '501' && { echo "FAIL: #501 (type:subtask legacy alias + Stage-13-close title) must be excluded"; failures=$((failures+1)); }
  # (b4) anti-over-exclude control: the LABEL ALONE IS NOT THE MATCHER. A sub-task
  #      with a non-Stage-13 title must survive — without this leg, a naive
  #      label-only implementation would pass (b1)-(b3) while stranding every
  #      Stage 5-8 sub-task open at close.
  /usr/bin/printf '%s\n' "$OPEN_ISSUE_LIST" | /usr/bin/grep -qx '502' || { echo "FAIL: #502 (sub-task label, Stage-5 title) must SURVIVE — the label alone must not exclude"; failures=$((failures+1)); }
  # (b5) decoy preserved (unchanged behaviour): "stage 13" without "close".
  /usr/bin/printf '%s\n' "$OPEN_ISSUE_LIST" | /usr/bin/grep -qx '600' || { echo "FAIL: #600 (decoy 'stage 13' but not 'close') must NOT be excluded"; failures=$((failures+1)); }
  # (b6) count: 401, 600, 999, 2678, 502.
  [[ "$OPEN_ISSUE_COUNT" -eq 5 ]] || { echo "FAIL: label+title fallback path must leave 5 issues (401,600,999,2678,502), got $OPEN_ISSUE_COUNT"; failures=$((failures+1)); }
  # (b7) the excluded-detail side channel survives the helper extraction (#3587):
  #      the report's only window into WHY an issue was excluded must name BOTH
  #      conjuncts, and must not be silently emptied by the extraction.
  get_phase detect_open_issues | /usr/bin/grep -qF 'sub-task label + title-regex stage-13-close' || { echo "FAIL: detect detail must name both conjuncts of the fallback exclusion, got '$(get_phase detect_open_issues)'"; failures=$((failures+1)); }

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

  # Test 4d.3: check 5 re-reads issue state AFTER the close phase (#3587) — offline,
  # hermetic. Phase 14 (manual_close_release_issues) runs immediately before Phase 15
  # (run_verification), and OPEN_ISSUE_COUNT is a pre-close snapshot written once in
  # Phase 4, so every run that closed all N issues still rendered `PARTIAL (N open)`
  # — text that propagates into the durable Gate-Passage Proof comment. Drives
  # detect -> close -> verification against a CALL-COUNTER stub whose `issue list`
  # returns the pre-close fixture on call 1 and a controllable post-close fixture on
  # every later call, so the re-read is observed rather than assumed.
  local _v5_saved_gh="$GH" _v5_saved_mode="$MODE" _v5_saved_slug="$STATE_MILESTONE_SLUG"
  local _v5_saved_list="$OPEN_ISSUE_LIST" _v5_saved_count="$OPEN_ISSUE_COUNT"
  local _v5_saved_rowstate="$STATE_LOG_ROW_STATE" _v5_saved_results="$VERIFICATION_RESULTS"
  local _v5_saved_delay="$VERIFY_RECHECK_DELAY" _v5_saved_nomerge="$NO_MERGE"
  local _v5_row
  local _v5_tmp; _v5_tmp="$(/usr/bin/mktemp -d -t verify5-selftest.XXXXXX)"
  local _v5_stub="$_v5_tmp/gh-stub.sh"
  /bin/cat > "$_v5_stub" <<'STUB'
#!/usr/bin/env bash
# Call-counter gh stub for the #3587 check-5 re-read self-test. `issue list` returns
# the PRE-close fixture on call 1 (Phase 4 detect) and the contents of ./post on
# every later call (Phase 15 check-5 re-read). `issue close` is a no-op exit 0.
_d="$(dirname "$0")"
if [[ "$1" == "issue" && "$2" == "list" ]]; then
  n=$(( $(cat "$_d/calls" 2>/dev/null || echo 0) + 1 ))
  printf '%s' "$n" > "$_d/calls"
  if [[ "$n" -eq 1 ]]; then
    printf '%s\t%s\t%s\n' 401 "bug" "Normal auto-close anomaly issue"
    printf '%s\t%s\t%s\n' 402 "bug" "Another auto-close anomaly issue"
  else
    cat "$_d/post" 2>/dev/null || true
  fi
  exit 0
fi
exit 0
STUB
  /bin/chmod +x "$_v5_stub"
  GH="$_v5_stub"; MODE="apply"; STATE_MILESTONE_SLUG="88-some-milestone"
  STATE_LOG_ROW_STATE=""; NO_MERGE=0; EXCLUDE_ISSUES=(); CLOSE_COMMENTS=()
  VERIFY_RECHECK_DELAY=0   # keep the D-4 replication-lag retry hermetic + instant

  # (a) post-close truth: the close drains the milestone, so the re-read finds it
  #     empty and check 5 renders PASS — NOT the pre-close `PARTIAL (2 open)`.
  : > "$_v5_tmp/post"; : > "$_v5_tmp/calls"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_detect_open_issues >/dev/null 2>&1
  phase_manual_close_release_issues >/dev/null 2>&1
  phase_run_verification >/dev/null 2>&1
  _v5_row="$(/usr/bin/printf '%s\n' "$VERIFICATION_RESULTS" | /usr/bin/grep '^| 5 |')"
  [[ "$_v5_row" == *"| PASS |"* ]] || { echo "FAIL: check 5 must render PASS once the close phase drained the milestone, got '$_v5_row'"; failures=$((failures+1)); }

  # (d) blast-radius regression guard: the re-read writes LOCALS ONLY. The pre-close
  #     globals must survive untouched — 6 of their 7 consumers (chore-PR body, the
  #     closed N/M denominator, the D-1 Manual-Close Candidates section, the JSON
  #     payload) document the population as it stood BEFORE the close.
  [[ "$OPEN_ISSUE_COUNT" -eq 2 ]] || { echo "FAIL: check 5 must NOT clobber the pre-close OPEN_ISSUE_COUNT (expected 2), got $OPEN_ISSUE_COUNT"; failures=$((failures+1)); }
  [[ "$OPEN_ISSUE_LIST" == $'401\n402' ]] || { echo "FAIL: check 5 must NOT clobber the pre-close OPEN_ISSUE_LIST (expected 401,402), got '${OPEN_ISSUE_LIST//$'\n'/,}'"; failures=$((failures+1)); }

  # (b) regression-direction control: #401 is STILL open at re-read time, so check 5
  #     must render PARTIAL and enumerate it. Without this leg a hardcoded PASS would
  #     satisfy legs (a) and (d) — this is what proves the read is live.
  /usr/bin/printf '%s\t%s\t%s\n' 401 "bug" "Normal auto-close anomaly issue" > "$_v5_tmp/post"
  : > "$_v5_tmp/calls"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_detect_open_issues >/dev/null 2>&1
  phase_manual_close_release_issues >/dev/null 2>&1
  phase_run_verification >/dev/null 2>&1
  _v5_row="$(/usr/bin/printf '%s\n' "$VERIFICATION_RESULTS" | /usr/bin/grep '^| 5 |')"
  [[ "$_v5_row" == *"PARTIAL (1 open: #401)"* ]] || { echo "FAIL: check 5 must render the LIVE post-close state 'PARTIAL (1 open: #401)', got '$_v5_row'"; failures=$((failures+1)); }

  # (c) fail closed: an unevaluable re-query reads UNVERIFIED, never PASS. UNVERIFIED
  #     rather than FAIL because a query that could not run establishes nothing about
  #     whether issues are open.
  GH="/bin/false"; MODE="apply"; OPEN_ISSUE_LIST=$'401\n402'; OPEN_ISSUE_COUNT=2
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_run_verification >/dev/null 2>&1
  _v5_row="$(/usr/bin/printf '%s\n' "$VERIFICATION_RESULTS" | /usr/bin/grep '^| 5 |')"
  [[ "$_v5_row" == *"UNVERIFIED"* ]] || { echo "FAIL: check 5 must fail closed to UNVERIFIED when the post-close re-query fails, got '$_v5_row'"; failures=$((failures+1)); }
  [[ "$_v5_row" == *"| PASS |"* ]] && { echo "FAIL: a failed re-query must NEVER read as PASS, got '$_v5_row'"; failures=$((failures+1)); }

  # (e) dry-run non-regression: preview mode closes nothing, so cached == live and no
  #     second query fires. $GH is /bin/false — a query here would render UNVERIFIED.
  MODE="dry-run"; OPEN_ISSUE_LIST=$'401\n402'; OPEN_ISSUE_COUNT=2
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_run_verification >/dev/null 2>&1
  _v5_row="$(/usr/bin/printf '%s\n' "$VERIFICATION_RESULTS" | /usr/bin/grep '^| 5 |')"
  [[ "$_v5_row" == *"PARTIAL (2 open)"* ]] || { echo "FAIL: dry-run check 5 must read the cached pre-close count and fire no query, got '$_v5_row'"; failures=$((failures+1)); }

  /bin/rm -rf "$_v5_tmp" 2>/dev/null || true
  GH="$_v5_saved_gh"; MODE="$_v5_saved_mode"; STATE_MILESTONE_SLUG="$_v5_saved_slug"
  OPEN_ISSUE_LIST="$_v5_saved_list"; OPEN_ISSUE_COUNT="$_v5_saved_count"
  STATE_LOG_ROW_STATE="$_v5_saved_rowstate"; VERIFICATION_RESULTS="$_v5_saved_results"
  VERIFY_RECHECK_DELAY="$_v5_saved_delay"; NO_MERGE="$_v5_saved_nomerge"
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
    # 3-field format: number \t comma-joined LABELS \t title — the shape
    # collect_open_release_issues parses (--jq emits labels as field 2). Row 3 is the
    # exclusion probe: it is the ONLY row whose classification depends on field 2 being
    # the LABEL set rather than the title. See leg (c).
    printf '%s\t%s\t%s\n' 2578 "sub-task" "Some open sub-task"
    printf '%s\t%s\t%s\n' 1771 "sub-task" "Another open sub-task"
    printf '%s\t%s\t%s\n' 3990 "sub-task,release" "Stage 13 close-out orchestration"
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

  # (c) STUB-FORMAT regression guard (F-01). Legs (a) and (b) assert COUNTS only, and
  #     the counts are identical under the pre-migration 2-field stub (number \t title)
  #     — so reverting this stub to 2 fields left the whole suite green and the
  #     migration had no covering test. This leg makes field 2 load-bearing: #3990 is a
  #     `sub-task`-LABELLED Stage-13-close orchestration issue, which collect_open_
  #     release_issues must EXCLUDE via the label+title conjunct so the close cannot
  #     self-close its own orchestration sub-task (R5). Under a 2-field stub field 2
  #     holds the TITLE, `,<title>,` cannot contain `,sub-task,`, the conjunct never
  #     fires, and #3990 is counted — 3 instead of 2. The exclusion REASON is asserted
  #     too, so a count that happens to be right for the wrong reason still reddens.
  STATE_MILESTONE_SLUG="close-out-reliability-hardening"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_detect_open_issues >/dev/null 2>&1
  [[ "$OPEN_ISSUE_COUNT" -eq 2 ]] || { echo "FAIL: the sub-task-labelled Stage-13-close issue #3990 must be EXCLUDED from the open count (expected 2, got $OPEN_ISSUE_COUNT) — field 2 of the stub must be the LABEL set, not the title"; failures=$((failures+1)); }
  /usr/bin/printf '%s\n' "$OPEN_ISSUE_LIST" | /usr/bin/grep -qx '3990' && { echo "FAIL: #3990 must not appear in OPEN_ISSUE_LIST — a close that lists its own orchestration sub-task can self-close it (R5)"; failures=$((failures+1)); }
  [[ "$(get_phase detect_open_issues)" == *"#3990 (sub-task label + title-regex stage-13-close)"* ]] || { echo "FAIL: the exclusion of #3990 must be reported with its structural reason, got '$(get_phase detect_open_issues)'"; failures=$((failures+1)); }
  #     Anti-vacuity control: the OTHER two sub-task-labelled rows carry no stage-13-close
  #     title, so the label alone must NOT exclude them — proving the conjunct is a
  #     conjunct and leg (c) is not passing because everything labelled sub-task is dropped.
  /usr/bin/printf '%s\n' "$OPEN_ISSUE_LIST" | /usr/bin/grep -qx '2578' || { echo "FAIL: control — a sub-task label WITHOUT a stage-13-close title must NOT be excluded (#2578 missing); the conjunct has degraded to a label-only test"; failures=$((failures+1)); }

  /bin/rm -rf "$_ag_tmp" 2>/dev/null || true
  GH="$_ag_saved_gh"; MODE="$_ag_saved_mode"; STATE_MILESTONE_SLUG="$_ag_saved_slug"
  OPEN_ISSUE_LIST="$_ag_saved_list"; OPEN_ISSUE_COUNT="$_ag_saved_count"
  EXCLUDE_ISSUES=(); CLOSE_COMMENTS=()
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # Test 4i: post_gate_passage_proof three-rung target ladder (#3819) — offline,
  # hermetic, credential-free. REFLEXIVITY NOTE: this is the phase that runs at the
  # close-out of the very release that introduced it, so the ladder is tested against
  # the shape that actually broke (#264: gate sub-task absent from the milestone) and
  # against the shape an idempotent re-run produces (sub-task already CLOSED).
  #
  #   T-13  rung 1 resolves a CLOSED Stage-13 sub-task — the arm that fails if the
  #         resolver inherits the collector's `--state open` query. Asserts the phase
  #         PASSes, names #N and "(closed)", posts a body containing "### Verification",
  #         and does NOT touch `pr comment`.
  #   (b)   rung 2 — no Stage-13 sub-task in the milestone (the #264 shape): must post
  #         to the release PR and record the OBSERVED reason, not a generic string.
  #   (c)   rung 3 — no sub-task AND no PR number: MANUAL that names BOTH attempted
  #         targets. A bare MANUAL is the defect this card exists to remove.
  local _gp_saved_gh="$GH" _gp_saved_mode="$MODE" _gp_saved_slug="$STATE_MILESTONE_SLUG"
  local _gp_saved_pr="$PR_NUMBER" _gp_saved_ver="$VERSION" _gp_saved_res="$VERIFICATION_RESULTS"
  local _gp_saved_sha="$MERGE_SHA" _gp_saved_state="$STATE_MILESTONE_STATE"
  local _gp_tmp; _gp_tmp="$(/usr/bin/mktemp -d -t gateproof-selftest.XXXXXX)"
  local _gp_stub="$_gp_tmp/gh-stub.sh"
  # Stub records every invocation to $GH_CALLS and every posted body to $GH_BODY.
  # `issue list --state all` returns the CLOSED Stage-13 sub-task ONLY when the
  # caller actually asked for all states — an open-only query returns nothing, so a
  # regression to `--state open` turns T-13 red rather than silently green.
  /bin/cat > "$_gp_stub" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GH_CALLS"
case "$1 $2" in
  "issue list")
    [[ "$*" == *"--state all"* ]] || exit 0
    [[ "$GP_NO_SUBTASK" == "1" ]] && exit 0
    printf '%s\t%s\t%s\t%s\n' 4700 "sub-task,status: bundled" "CLOSED" "Stage 13 Close — release-bundle-and-sequence-gates (release-scoped)"
    printf '%s\t%s\t%s\t%s\n' 4701 "sub-task" "OPEN" "Stage 6 Engineering — #3819 (release-bundle-and-sequence-gates)"
    exit 0 ;;
  "issue comment"|"pr comment")
    # --body is the last argument in both call sites.
    printf '%s\n' "${@: -1}" >> "$GH_BODY"
    exit 0 ;;
esac
exit 0
STUB
  /bin/chmod +x "$_gp_stub"
  GH="$_gp_stub"; MODE="apply"; STATE_MILESTONE_SLUG="release-bundle-and-sequence-gates"
  VERSION="v9.99"; MERGE_SHA="deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
  export GH_CALLS="$_gp_tmp/calls.log" GH_BODY="$_gp_tmp/body.log" GP_NO_SUBTASK=0
  : > "$GH_CALLS"; : > "$GH_BODY"
  VERIFICATION_RESULTS="| 1 | RELEASE_NOTES.md present | test -f | PASS |"

  # (T-13) rung 1 — CLOSED sub-task is still the correct durable home.
  PR_NUMBER="8888"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  local _gp_r1; _gp_r1="$(resolve_stage13_subtask "$STATE_MILESTONE_SLUG")"
  [[ "${_gp_r1%%$'\t'*}" == "4700" ]] || { echo "FAIL: T-13 resolve_stage13_subtask must find the CLOSED Stage-13 sub-task #4700 via --state all, got '$_gp_r1'"; failures=$((failures+1)); }
  phase_run_verification >/dev/null 2>&1
  [[ "$(get_phase post_gate_passage_proof)" == PASS\|* ]] || { echo "FAIL: T-13 rung 1 must PASS against a CLOSED Stage-13 sub-task, got '$(get_phase post_gate_passage_proof)'"; failures=$((failures+1)); }
  [[ "$(get_phase post_gate_passage_proof)" == *"#4700"* ]] || { echo "FAIL: T-13 rung-1 detail must name the resolved sub-task #4700, got '$(get_phase post_gate_passage_proof)'"; failures=$((failures+1)); }
  [[ "$(get_phase post_gate_passage_proof)" == *"(closed)"* ]] || { echo "FAIL: T-13 rung-1 detail must record that the target was closed, got '$(get_phase post_gate_passage_proof)'"; failures=$((failures+1)); }
  /usr/bin/grep -qF '### Verification' "$GH_BODY" || { echo "FAIL: T-13 the posted gate-passage proof body must carry the Verification table section"; failures=$((failures+1)); }
  /usr/bin/grep -q '^pr comment' "$GH_CALLS" && { echo "FAIL: T-13 rung 1 succeeded, so the rung-2 release-PR fallback must NOT be invoked"; failures=$((failures+1)); }
  /usr/bin/grep -q '^issue comment 4700' "$GH_CALLS" || { echo "FAIL: T-13 must post to sub-task #4700 via issue comment"; failures=$((failures+1)); }

  # (b) rung 2 — the #264 shape: no Stage-13 sub-task resolvable in the milestone.
  GP_NO_SUBTASK=1; : > "$GH_CALLS"; : > "$GH_BODY"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_run_verification >/dev/null 2>&1
  [[ "$(get_phase post_gate_passage_proof)" == PASS\|* ]] || { echo "FAIL: rung 2 must PASS by posting to the release PR when no Stage-13 sub-task exists, got '$(get_phase post_gate_passage_proof)'"; failures=$((failures+1)); }
  [[ "$(get_phase post_gate_passage_proof)" == *"not found in milestone"* ]] || { echo "FAIL: rung 2 must record the OBSERVED rung-1 reason, not a generic 'unresolved', got '$(get_phase post_gate_passage_proof)'"; failures=$((failures+1)); }
  [[ "$(get_phase post_gate_passage_proof)" == *"release PR #8888"* ]] || { echo "FAIL: rung 2 must name the fallback target it posted to, got '$(get_phase post_gate_passage_proof)'"; failures=$((failures+1)); }
  /usr/bin/grep -q '^pr comment 8888' "$GH_CALLS" || { echo "FAIL: rung 2 must actually invoke pr comment on the release PR — never PASS without an observed post"; failures=$((failures+1)); }
  /usr/bin/grep -qF '### Verification' "$GH_BODY" || { echo "FAIL: rung 2's fallback post must still carry the Verification table"; failures=$((failures+1)); }

  # (c) rung 3 — terminal, reasoned. MANUAL must name BOTH attempted targets.
  PR_NUMBER=""; : > "$GH_CALLS"; : > "$GH_BODY"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_run_verification >/dev/null 2>&1
  [[ "$(get_phase post_gate_passage_proof)" == MANUAL\|* ]] || { echo "FAIL: rung 3 must be MANUAL when neither target resolves, got '$(get_phase post_gate_passage_proof)'"; failures=$((failures+1)); }
  [[ "$(get_phase post_gate_passage_proof)" == *"Stage-13 sub-task"* && "$(get_phase post_gate_passage_proof)" == *"release PR"* ]] || { echo "FAIL: rung 3's MANUAL must name BOTH attempted targets — a bare MANUAL is indistinguishable from never having looked (#3819), got '$(get_phase post_gate_passage_proof)'"; failures=$((failures+1)); }
  [[ "$(get_phase post_gate_passage_proof)" == *"comment text emitted in final report"* ]] || { echo "FAIL: rung 3 must state that the proof text survives in the report, got '$(get_phase post_gate_passage_proof)'"; failures=$((failures+1)); }

  # Test 4j (T-14): two collect_open_release_issues calls in one run — the Phase-15
  # check-5 replication-lag retry. This is the leg where a Bash-3.2 sticky-scope
  # hazard would surface: if the extracted predicate leaked `_is_subtask` across
  # iterations or across calls, the second call's exclusion set would differ from the
  # first's. Asserts EXCLUDED_DETAIL is not doubled, COLLECTED_OPEN_ISSUES is
  # identical, and resolve_stage13_subtask is stable across repeated invocation.
  GP_NO_SUBTASK=0
  /bin/cat > "$_gp_stub" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GH_CALLS"
case "$1 $2" in
  "issue list")
    if [[ "$*" == *"--state all"* ]]; then
      printf '%s\t%s\t%s\t%s\n' 4700 "sub-task" "CLOSED" "Stage 13 Close — slug (release-scoped)"
      exit 0
    fi
    printf '%s\t%s\t%s\n' 401 "bug" "Normal anomaly issue"
    printf '%s\t%s\t%s\n' 4700 "sub-task" "Stage 13 Close — slug (release-scoped)"
    printf '%s\t%s\t%s\n' 402 "sub-task" "Stage 6 Engineering — #3819 (slug)"
    exit 0 ;;
esac
exit 0
STUB
  /bin/chmod +x "$_gp_stub"
  collect_open_release_issues "slug" || true
  local _t14_list1="$COLLECTED_OPEN_ISSUES" _t14_excl1="$EXCLUDED_DETAIL"
  local _t14_r1; _t14_r1="$(resolve_stage13_subtask "slug")"
  collect_open_release_issues "slug" || true
  local _t14_list2="$COLLECTED_OPEN_ISSUES" _t14_excl2="$EXCLUDED_DETAIL"
  local _t14_r2; _t14_r2="$(resolve_stage13_subtask "slug")"
  [[ "$_t14_list1" == "$_t14_list2" ]] || { echo "FAIL: T-14 COLLECTED_OPEN_ISSUES must be identical across two calls in one run, got '$_t14_list1' then '$_t14_list2'"; failures=$((failures+1)); }
  [[ "$_t14_excl1" == "$_t14_excl2" ]] || { echo "FAIL: T-14 EXCLUDED_DETAIL must not accumulate across calls (Bash-3.2 sticky-scope hazard), got '$_t14_excl1' then '$_t14_excl2'"; failures=$((failures+1)); }
  [[ "$_t14_r1" == "$_t14_r2" ]] || { echo "FAIL: T-14 resolve_stage13_subtask must return the same value on both calls, got '$_t14_r1' then '$_t14_r2'"; failures=$((failures+1)); }
  # Anti-vacuity: the fixture must actually exercise an exclusion and a survivor,
  # otherwise "identical across calls" is satisfied by two empty results.
  [[ "$_t14_excl1" == *"#4700 (sub-task label + title-regex stage-13-close)"* ]] || { echo "FAIL: T-14 fixture must exclude the Stage-13 sub-task #4700 — an empty exclusion set makes the idempotence assertion vacuous, got '$_t14_excl1'"; failures=$((failures+1)); }
  /usr/bin/printf '%s\n' "$_t14_list1" | /usr/bin/grep -qx '402' || { echo "FAIL: T-14 control — a sub-task-labelled NON-Stage-13 issue must survive; the conjunct has degraded to a label-only test"; failures=$((failures+1)); }

  /bin/rm -rf "$_gp_tmp" 2>/dev/null || true
  unset GH_CALLS GH_BODY GP_NO_SUBTASK
  GH="$_gp_saved_gh"; MODE="$_gp_saved_mode"; STATE_MILESTONE_SLUG="$_gp_saved_slug"
  PR_NUMBER="$_gp_saved_pr"; VERSION="$_gp_saved_ver"; VERIFICATION_RESULTS="$_gp_saved_res"
  MERGE_SHA="$_gp_saved_sha"; STATE_MILESTONE_STATE="$_gp_saved_state"
  COLLECTED_OPEN_ISSUES=""; EXCLUDED_DETAIL=""
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

    # (c)/(d) REACHABILITY OF THE DRY-RUN LIMB (#5142 F-01; #4765 convention).
    # Phase 15.5's dry-run branch used to sit BELOW three `return 3` preflights, so
    # every --dry-run aborted here before the mode was ever read and the phases after
    # it never enumerated — the same defect class #4765 fixed at 9.55, with the same
    # consequence for the dry-run review gate stage-13-close.md Phase A8 mandates.
    #
    # These arms assert REACHABILITY, not presence. A presence check (does a
    # `MODE == dry-run` branch exist in this function?) passes on the DEFECTIVE code —
    # the branch was always there, just stranded below the aborts. Each fixture is
    # therefore driven through BOTH modes: the dry arm must reach the limb and return
    # 0 with the literal outcome DRY-RUN, and the apply arm on the IDENTICAL fixture
    # must still abort. Without the apply arm the dry arm is satisfiable by a gutted
    # guard or by a fixture that does not actually omit what it claims to omit; without
    # the literal-DRY-RUN assertion it is satisfiable by a vacuous PASS.
    local _pg_saved_nomerge="$NO_MERGE"
    NO_MERGE=0   # the deferral guard sits above the dry-run branch; keep it out of the way
    local _pg_rc _pg_detail

    # Fixture N — NOTES ABSENT. This is the artifact phase_scaffold_release_notes
    # deliberately does not write under --dry-run, so on the real dry-run path this
    # preflight fires on the script's own no-op. Tag present and at MERGE_SHA, so the
    # two preflights above it pass and this one is provably the abort under test.
    MERGE_SHA="$_ms_commit"; VERSION="v9.89"
    RELEASE_NOTES_DIR="$_ms_tmp/empty-notes"; /bin/mkdir -p "$RELEASE_NOTES_DIR"

    MODE="dry-run"; PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=(); _pg_rc=0
    phase_publish_github_release >/dev/null 2>&1 || _pg_rc=$?
    [[ "$_pg_rc" -eq 0 ]] || { echo "FAIL: F-01-N-dry — under --dry-run the phase must reach its mode branch and return 0 when the note is absent (it is absent by construction; phase_scaffold_release_notes wrote nothing), got rc=$_pg_rc"; failures=$((failures+1)); }
    [[ "$(get_phase publish_github_release | /usr/bin/cut -d'|' -f1)" == "DRY-RUN" ]] || { echo "FAIL: F-01-N-dry — the outcome must be literally DRY-RUN (a vacuous PASS also returns 0 and must not count), got '$(get_phase publish_github_release)'"; failures=$((failures+1)); }

    MODE="apply"; PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=(); _pg_rc=0
    phase_publish_github_release >/dev/null 2>&1 || _pg_rc=$?
    [[ "$_pg_rc" -ne 0 ]] || { echo "FAIL: F-01-N-apply anti-vacuity — the SAME notes-absent fixture MUST still abort under --apply; rc=0 means the preflight was gutted rather than mode-scoped, or the fixture is not actually missing the note"; failures=$((failures+1)); }
    _pg_detail="$(get_phase publish_github_release)"
    /usr/bin/grep -qF 'RELEASE_NOTES file not present' <<<"$_pg_detail" || { echo "FAIL: F-01-N-apply — the --apply preflight message must be preserved verbatim (the apply limb is unchanged), got '$_pg_detail'"; failures=$((failures+1)); }

    # Fixture T — TAG ABSENT. The FIRST of the three preflights, and the one a genuine
    # pre-close dry-run hits first: the tag is pushed at Stage 12 Phase B3, which has
    # not run when the operator dry-runs the close. v9.87 was never tagged in the
    # sandbox origin, so ls-remote returns an empty set with no network call.
    VERSION="v9.87"

    MODE="dry-run"; PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=(); _pg_rc=0
    phase_publish_github_release >/dev/null 2>&1 || _pg_rc=$?
    [[ "$_pg_rc" -eq 0 ]] || { echo "FAIL: F-01-T-dry — under --dry-run the phase must reach its mode branch and return 0 when the tag is not yet on origin (Stage 12 Phase B3 has not run at dry-run time), got rc=$_pg_rc"; failures=$((failures+1)); }
    [[ "$(get_phase publish_github_release | /usr/bin/cut -d'|' -f1)" == "DRY-RUN" ]] || { echo "FAIL: F-01-T-dry — the outcome must be literally DRY-RUN, got '$(get_phase publish_github_release)'"; failures=$((failures+1)); }

    MODE="apply"; PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=(); _pg_rc=0
    phase_publish_github_release >/dev/null 2>&1 || _pg_rc=$?
    [[ "$_pg_rc" -ne 0 ]] || { echo "FAIL: F-01-T-apply anti-vacuity — the SAME tag-absent fixture MUST still abort under --apply; rc=0 means the tag preflight was gutted, or v9.87 is unexpectedly present on the sandbox origin"; failures=$((failures+1)); }
    _pg_detail="$(get_phase publish_github_release)"
    /usr/bin/grep -qF 'not present on origin' <<<"$_pg_detail" || { echo "FAIL: F-01-T-apply — the --apply tag preflight must be the abort under test and its message preserved verbatim, got '$_pg_detail'"; failures=$((failures+1)); }

    NO_MERGE="$_pg_saved_nomerge"
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

  # ── Test 5.6: phase_lint_plan_identity — the ADR-092 plan-identity close gate ──
  #
  # Same stub seam as Test 5.5, and the same reason: these arms grade the CALLER's
  # needle logic. The lint's own limbs are graded by its `--self-test`.
  #
  # PI-4 IS THE ARM THAT EARNS THIS BLOCK. A suite that only ever stubs a finding
  # whose path EQUALS the caller's needle is green by construction on the one
  # sub-case that matches and blind to the ones that do not — it proves the needle
  # reaches paths equal to itself, which is not the claim. PI-4 stubs the card's
  # CANONICAL defect: a plan named for the WRONG version, whose finding therefore
  # names a path the expected-path needle cannot match. It fails on a
  # single-needle implementation and passes on the shipped two-needle one.
  local _pi_saved_root="$REPO_ROOT" _pi_saved_version="$VERSION" _pi_saved_plansdir="$RELEASE_PLANS_DIR"
  local _pi_tmp; _pi_tmp="$(/usr/bin/mktemp -d -t lintplanid-selftest.XXXXXX)"
  /bin/mkdir -p "$_pi_tmp/core/deploy/tools" "$_pi_tmp/release/releases/plans"
  local _pi_stub="$_pi_tmp/core/deploy/tools/lint_release_corpus.py"
  /bin/cat > "$_pi_stub" <<'STUB'
import os, sys
sys.stdout.write(os.environ.get("LN_OUT", ""))
sys.exit(int(os.environ.get("LN_EXIT", "0")))
STUB
  REPO_ROOT="$_pi_tmp"; VERSION="v9.99"; RELEASE_PLANS_DIR="$_pi_tmp/release/releases/plans"
  local _pi_expected; _pi_expected="$(plan_rel_path_expected)"

  # PI-0 — clean (exit 0) → PASS.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  LN_EXIT=0 LN_OUT="" phase_lint_plan_identity >/dev/null 2>&1 || true
  [[ "$(get_phase lint_plan_identity | /usr/bin/cut -d'|' -f1)" == "PASS" ]] || { echo "FAIL: PI-0 — a clean plan corpus (exit 0) must PASS"; failures=$((failures+1)); }

  # PI-1 — the placement finding (names the EXPECTED path) BLOCKS. This is the
  # absorbed #4707 AC4 limb reaching the caller.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  if LN_EXIT=1 LN_OUT="PLAN-MISSING-FOR-LEDGER-ROW: v9.99 (release/releases/RELEASE_LOG.md:5) has no plan at ${_pi_expected} (ADR-092 claim-time home)" phase_lint_plan_identity >/dev/null 2>&1; then
    echo "FAIL: PI-1 — a placement finding naming this release's expected plan path must BLOCK the close"; failures=$((failures+1))
  fi
  [[ "$(get_phase lint_plan_identity | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: PI-1 — the phase must mark FAIL on a this-version placement finding"; failures=$((failures+1)); }

  # PI-1b — the expected-path needle carries INDEPENDENT reach. Measured while
  # building this suite: every finding class the check emits today also names the
  # version, so PI-1 alone is satisfied by the version needle and proves nothing
  # about the path needle. This arm stubs a finding that names this release's plan
  # path under a prefix the version needle's `^PLAN-` anchor does not admit — the
  # shape a future finding class added by a sibling would have. Both needles are
  # kept because they fail independently: the path needle survives a
  # finding-vocabulary change, the version needle survives a path-rendering change.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  if LN_EXIT=1 LN_OUT="PLANFILE-FUTURE-CLASS: ${_pi_expected} is malformed" phase_lint_plan_identity >/dev/null 2>&1; then
    echo "FAIL: PI-1b — a blocking finding naming this release's plan path must BLOCK even when its prefix is outside the version needle's anchor; the path needle is dead"; failures=$((failures+1))
  fi

  # PI-2 — CONTROL: another release's finding must NOT block (audit-baseline).
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  LN_EXIT=1 LN_OUT="PLAN-VERSION-MISMATCH: release/releases/plans/v2/v2.42_RELEASE_PLAN.md declares v2.42; release/releases/RELEASE_LOG.md:93 records v3.21 (ADR-092)" phase_lint_plan_identity >/dev/null 2>&1 || { echo "FAIL: PI-2 — a finding naming neither this release's plan path nor this version must NOT block"; failures=$((failures+1)); }
  [[ "$(get_phase lint_plan_identity | /usr/bin/cut -d'|' -f1)" == "PASS" ]] || { echo "FAIL: PI-2 — another release's finding must resolve to PASS (audit-baseline discipline)"; failures=$((failures+1)); }

  # PI-3 — exit 3 → FAIL, fail-loud. Never a vacuous pass.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  if LN_EXIT=3 LN_OUT="CORPUS-PATH-UNRESOLVED: release ledger does not resolve" phase_lint_plan_identity >/dev/null 2>&1; then
    echo "FAIL: PI-3 — exit-3 (corpus unverifiable) must BLOCK the close"; failures=$((failures+1))
  fi
  [[ "$(get_phase lint_plan_identity | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: PI-3 — exit 3 must mark FAIL (fail-loud, not a vacuous pass)"; failures=$((failures+1)); }

  # PI-4 — THE UNMASKING ARM. The card's canonical defect: this release's plan is
  # named for the WRONG version, so the finding names `…/v9.98_RELEASE_PLAN.md`
  # while the expected-path needle is `…/v9.99_RELEASE_PLAN.md`. The path needle
  # CANNOT match it; only the version-keyed needle can. This arm fails on a
  # single-needle caller — which is the whole reason the second needle exists.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  if LN_EXIT=1 LN_OUT="PLAN-VERSION-MISMATCH: release/releases/plans/v9/v9.98_RELEASE_PLAN.md declares v9.98; release/releases/RELEASE_LOG.md:7 records v9.99 — the filename names a version the release did not ship as (ADR-092)" phase_lint_plan_identity >/dev/null 2>&1; then
    echo "FAIL: PI-4 — a plan NAMED FOR THE WRONG VERSION emits its ACTUAL path, which the expected-path needle cannot match. The version-keyed needle must catch it and BLOCK; it did not, so the identity limb has no blocking predicate."; failures=$((failures+1))
  fi
  [[ "$(get_phase lint_plan_identity | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: PI-4 — the wrong-version-named plan must mark the phase FAIL"; failures=$((failures+1)); }

  # PI-4b — the same shape for PLAN-MAJOR-DIR-MISMATCH (the second finding class
  # the path needle misses: right version, wrong major folder).
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  if LN_EXIT=1 LN_OUT="PLAN-MAJOR-DIR-MISMATCH: release/releases/plans/v8/v9.99_RELEASE_PLAN.md declares v9.99 but sits under v8/ (ADR-092)" phase_lint_plan_identity >/dev/null 2>&1; then
    echo "FAIL: PI-4b — a MAJOR-DIR finding for this version names a path under the WRONG major, which the expected-path needle cannot match; the version-keyed needle must catch it"; failures=$((failures+1))
  fi

  # PI-4c — SPECIFICITY for the version-keyed needle. A neighbouring version must
  # not match: `v9.9` is a prefix of `v9.99`, and `v19.99` contains it. Without
  # the boundary guards this arm goes red, so the needle is a real predicate
  # rather than a substring search.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  LN_EXIT=1 LN_OUT="PLAN-VERSION-MISMATCH: release/releases/plans/v9/v9.999_RELEASE_PLAN.md declares v9.999; release/releases/RELEASE_LOG.md:3 records v19.99 (ADR-092)" phase_lint_plan_identity >/dev/null 2>&1 || { echo "FAIL: PI-4c — the version needle must not match v9.999 (trailing guard) or v19.99 (leading guard) when closing v9.99; without both guards this is a substring search, not a predicate"; failures=$((failures+1)); }
  [[ "$(get_phase lint_plan_identity | /usr/bin/cut -d'|' -f1)" == "PASS" ]] || { echo "FAIL: PI-4c — a neighbouring-version finding must resolve to PASS"; failures=$((failures+1)); }

  # PI-5 — version-less → SKIP with PASS. Driven here because --self-test
  # dispatches BEFORE main()'s version-grammar gate; production cannot reach it.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  local _pi_savedv2="$VERSION"; VERSION="widget-three"
  LN_EXIT=1 LN_OUT="PLAN-MISSING-FOR-LEDGER-ROW: v9.99 has no plan at ${_pi_expected}" phase_lint_plan_identity >/dev/null 2>&1 || { echo "FAIL: PI-5 — a version-less release must SKIP the phase, not block"; failures=$((failures+1)); }
  [[ "$(get_phase lint_plan_identity | /usr/bin/cut -d'|' -f1)" == "SKIP" ]] || { echo "FAIL: PI-5 — a version-less release must mark SKIP, got '$(get_phase lint_plan_identity)'"; failures=$((failures+1)); }
  VERSION="$_pi_savedv2"

  # PI-6 — NEEDLE INDEPENDENCE, this direction: a NOTE finding must not block the
  # plan phase. The two gates own disjoint predicates; either one capturing the
  # other's findings means a §3.2 defect could red-line the plan gate (or mask it).
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  LN_EXIT=1 LN_OUT="NOTE-6A-MISSING: release/releases/notes/v9.99_RELEASE_NOTES.md lacks section" phase_lint_plan_identity >/dev/null 2>&1 || { echo "FAIL: PI-6 — a NOTE-path finding must not block the plan-identity phase; the two needles are independent"; failures=$((failures+1)); }

  # PI-7 — NEEDLE INDEPENDENCE, the other direction, and the measurement that
  # produced this whole phase: a PLANS-path finding provably does NOT reach
  # phase_lint_release_notes' note-path needle. If this arm ever goes red the
  # co-location counter-design has become viable and this phase can be revisited;
  # while it is green, homing a plan limb inside check_note_content() is fail-open.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  local _pi_saved_notesdir="${RELEASE_NOTES_DIR:-}"
  LN_EXIT=1 LN_OUT="PLAN-VERSION-MISMATCH: release/releases/plans/v9/v9.98_RELEASE_PLAN.md declares v9.98; records v9.99" phase_lint_release_notes >/dev/null 2>&1 || { echo "FAIL: PI-7 — a plans-path finding must NOT match the note-path needle. It did, which means the fail-open measurement this phase is built on no longer holds."; failures=$((failures+1)); }
  [[ "$(get_phase lint_release_notes | /usr/bin/cut -d'|' -f1)" == "PASS" ]] || { echo "FAIL: PI-7 — phase_lint_release_notes must take its PASS branch on a plans-path finding (the fail-open property)"; failures=$((failures+1)); }
  RELEASE_NOTES_DIR="$_pi_saved_notesdir"

  # PI-8 — an ADVISORY line naming this release's expected path must NOT block.
  # The lint's plan advisories legitimately carry plans paths; a caller that fed
  # them to the needle would false-block every close on a known residual.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  LN_EXIT=1 LN_OUT="ADVISORY: PLAN-VERSION-MISMATCH: ${_pi_expected} declares v9.99 [KNOWN RESIDUAL]
PLAN-VERSION-UNKNOWN: release/releases/plans/v2/v2.98_RELEASE_PLAN.md declares v2.98" phase_lint_plan_identity >/dev/null 2>&1 || { echo "FAIL: PI-8 — an ADVISORY line naming this release's plan path must not block; advisories are filtered before the needles run"; failures=$((failures+1)); }
  [[ "$(get_phase lint_plan_identity | /usr/bin/cut -d'|' -f1)" == "PASS" ]] || { echo "FAIL: PI-8 — the advisory-only case must resolve to PASS"; failures=$((failures+1)); }

  # PI-9 — missing lint tooling → FAIL. A gate that cannot run is not a passing gate.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  /bin/rm -f "$_pi_stub"
  if phase_lint_plan_identity >/dev/null 2>&1; then
    echo "FAIL: PI-9 — the phase must FAIL when the lint tooling is missing, never silently skip"; failures=$((failures+1))
  fi

  # PI-10 — the phase is DISPATCHED, and dispatched in the right window: after
  # phase_transition_release_log and BEFORE phase_commit_chore_pr, so a finding
  # halts before the chore branch is committed, PR'd, or merged. A phase function
  # that exists but is never dispatched is the dead-check class one level up.
  local _pi_prod; _pi_prod="$(/usr/bin/sed -n '/^phase_preflight || {/,/^phase_audit_epic_rollup/p' "${BASH_SOURCE[0]}" || true)"
  /usr/bin/grep -qE '^phase_lint_plan_identity \|\|' <<<"$_pi_prod" || { echo "FAIL: PI-10 — phase_lint_plan_identity is not in the production dispatch ladder"; failures=$((failures+1)); }
  local _pi_n_id _pi_n_log _pi_n_commit
  _pi_n_id="$(/usr/bin/grep -n '^phase_lint_plan_identity ||' <<<"$_pi_prod" | /usr/bin/cut -d: -f1)"
  _pi_n_log="$(/usr/bin/grep -n '^phase_transition_release_log ||' <<<"$_pi_prod" | /usr/bin/cut -d: -f1)"
  _pi_n_commit="$(/usr/bin/grep -n '^phase_commit_chore_pr ||' <<<"$_pi_prod" | /usr/bin/cut -d: -f1)"
  [[ -n "$_pi_n_id" && -n "$_pi_n_log" && -n "$_pi_n_commit" && "$_pi_n_log" -lt "$_pi_n_id" && "$_pi_n_id" -lt "$_pi_n_commit" ]] || { echo "FAIL: PI-10 — dispatch order must be transition_release_log < lint_plan_identity < commit_chore_pr (got $_pi_n_log / $_pi_n_id / $_pi_n_commit)"; failures=$((failures+1)); }
  # Control: the same extraction finds a phase that is genuinely absent → nothing.
  ! /usr/bin/grep -qE '^phase_nonexistent_control \|\|' <<<"$_pi_prod" || { echo "FAIL: PI-10 control — the dispatch extractor matched a fabricated phase name"; failures=$((failures+1)); }

  # PI-11 — the hand-maintained `usage()` phase roster carries a 9.3 row. That
  # roster IS the --help output (usage() prints the header comment block
  # verbatim), and nothing asserts roster<->dispatch parity, so a phase added to
  # the ladder is silently absent from --help. Reading the "the table is derived"
  # comment answers a different question: the DERIVED table is the runtime Phase
  # Outcomes report, not this one.
  local _pi_help; _pi_help="$(usage 2>&1 || true)"
  /usr/bin/grep -qE '^[[:space:]]*9\.3 lint_plan_identity' <<<"$_pi_help" || { echo "FAIL: PI-11 — the usage()/--help phase roster has no 9.3 lint_plan_identity row"; failures=$((failures+1)); }
  /usr/bin/grep -qE '^[[:space:]]*9\.2 lint_release_notes' <<<"$_pi_help" || { echo "FAIL: PI-11 control — the roster extractor cannot see the shipped 9.2 row, so its 9.3 result is not interpretable"; failures=$((failures+1)); }

  /bin/rm -rf "$_pi_tmp" 2>/dev/null || true
  REPO_ROOT="$_pi_saved_root"; VERSION="$_pi_saved_version"; RELEASE_PLANS_DIR="$_pi_saved_plansdir"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
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

  # Test 7: usage block extractable AND not truncated. The old arm ran its own
  # copy of the fixed `sed -n '2,92p'` window and grepped only for "Usage:",
  # which sits near the top — so it passed while the window silently evicted the
  # META section. Drive the REAL renderer (no second copy to drift) and assert
  # both ends of the block: the opening "Usage:" and the last META flag.
  local _u7_out; _u7_out="$(usage || true)"
  # Here-strings, not `echo … | grep -q`: grep -q short-circuits and SIGPIPEs the
  # writer (SIGPIPE-idiom gate). Both needles are non-empty, so the `<<<""`
  # one-empty-line degenerate case cannot produce a false match.
  /usr/bin/grep -q "Usage:" <<<"$_u7_out" \
    || { echo "FAIL: usage block extraction — 'Usage:' absent from the rendered help"; failures=$((failures+1)); }
  /usr/bin/grep -q -- "--self-test" <<<"$_u7_out" \
    || { echo "FAIL: usage block truncated — the META section (--self-test) is absent from the rendered help"; failures=$((failures+1)); }

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

  # Test 11: phase_rebuild_skill_packages detection + files=() composition
  # (#3322 staging omission; #4722 delegated detection). Offline, hermetic.
  #
  # THESE ARMS DRIVE THE REAL PHASE, NOT THE BUILDER (#4722 C2). Detection is now
  # delegated, so any arm that pipes paths straight into
  # build-skill-packages.sh --skills-for-paths would be testing the BUILDER and would
  # pass green on an unmodified pre-fix close-out — the same
  # cannot-fail-on-its-own-defect pattern this release exists to close. Every arm
  # below therefore invokes phase_rebuild_skill_packages itself and reads the phase
  # record, the Test 4g idiom; block (c) additionally pins the phase's structure, the
  # Test 12-T1 idiom ("a detector derived from its own producer cannot silently
  # diverge from it"). Falsification: on a pre-fix close-out — local
  # changed_skills_from_paths with its core/standards + operations/templates prefix
  # case — arm (a1) marks N/A instead of naming tracker-manager, and every arm in
  # block (c) fails. git is REQUIRED; if absent the behavioural block self-skips and
  # the structural block still runs.
  if [[ -x "$GIT" ]]; then
    local _rp_root="$REPO_ROOT" _rp_mode="$MODE" _rp_merge="$MERGE_SHA"
    local _rp_tmp; _rp_tmp="$(/usr/bin/mktemp -d -t rebuildpkg-selftest.XXXXXX)"
    local _rp_work="$_rp_tmp/work"
    /bin/mkdir -p "$_rp_work/core/deploy/tools"
    # Copy the REAL builder, the REAL deploy.sh (TEMPLATE_SYNC_MAP + roster arrays)
    # and the REAL shared resolver into the sandbox, so the arms exercise the ACTUAL
    # --skills-for-paths rules rather than a restatement of them — the fixture idiom
    # claim-version.sh's package self-test uses for the same query.
    /bin/cp "$_rp_root/core/deploy/tools/build-skill-packages.sh" "$_rp_work/core/deploy/tools/" 2>/dev/null || true
    /bin/cp "$_rp_root/core/deploy/deploy.sh" "$_rp_work/core/deploy/" 2>/dev/null || true
    /bin/cp "$_rp_root/core/deploy/lib-template-sync-source.sh" "$_rp_work/core/deploy/" 2>/dev/null || true
    # The --apply arms (d1/d2) drive the builder's BUILD path, which fails CLOSED on an
    # absent complementary-pair registry BEFORE it dispatches any skill. So the sandbox
    # needs the real registry. Inert for the --dry-run arms: the query mode dispatches
    # and exits ABOVE that guard, so those arms never read it.
    /bin/mkdir -p "$_rp_work/core/deploy/allowlists"
    /bin/cp "$_rp_root/core/deploy/allowlists/complementary-reference-pairs.txt" "$_rp_work/core/deploy/allowlists/" 2>/dev/null || true
    # The apply path tests `[[ ! -x "$builder" ]]` before invoking it, and cp's mode
    # preservation is not worth depending on across platforms.
    /bin/chmod +x "$_rp_work/core/deploy/tools/build-skill-packages.sh" 2>/dev/null || true
    $GIT init -q -b main "$_rp_work" 2>/dev/null || { $GIT init -q "$_rp_work" 2>/dev/null; ( cd "$_rp_work" && $GIT checkout -q -b main 2>/dev/null ); }
    ( cd "$_rp_work" && $GIT -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1 \
      && $GIT -c user.email=t@t -c user.name=t commit -qm base >/dev/null 2>&1 ) || true

    # _rp_touch <repo-rel-path>... — commit a one-line change to EVERY given path in ONE
    # commit and set MERGE_SHA to it, so the phase's own `diff --name-only SHA^1 SHA`
    # yields exactly those paths. The phase resolves its diff itself; nothing is stubbed.
    # Multi-path support exists for the mixed-set arm (a7), which needs one commit
    # touching a buildable and an unbuildable path together — the shape the real defect
    # took. Existing single-path callers are unaffected.
    _rp_touch() {
      local _p
      for _p in "$@"; do
        /bin/mkdir -p "$_rp_work/$(/usr/bin/dirname "$_p")" 2>/dev/null || true
        /usr/bin/printf 'fixture edit: %s\n' "$_p" >> "$_rp_work/$_p"
      done
      ( cd "$_rp_work" && $GIT -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1 \
        && $GIT -c user.email=t@t -c user.name=t commit -qm "touch $*" >/dev/null 2>&1 ) || true
      MERGE_SHA="$($GIT -C "$_rp_work" rev-parse HEAD 2>/dev/null)"
      PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
    }
    REPO_ROOT="$_rp_work"; MODE="dry-run"

    # (a1) SENSITIVITY — THE DEFECT CASE. tracker-schemas.md homes to core/schemas/,
    #      a tree no prefix-enumerated rule named. Pre-fix this marked N/A.
    _rp_touch "core/schemas/tracker-schemas.md"
    phase_rebuild_skill_packages >/dev/null 2>&1
    if [[ "$(get_phase rebuild_skill_packages)" != DRY-RUN*tracker-manager* ]]; then
      echo "FAIL: a core/schemas/ canonical edit MUST resolve tracker-manager (#4722 — the third canonical tree), got '$(get_phase rebuild_skill_packages)'"; failures=$((failures+1))
    fi
    # (a2) CONTROL — an already-covered tree. Distinguishes "the fix works" from
    #      "the fixture resolves everything"; a2 passed pre-fix and must still pass.
    _rp_touch "core/standards/template-taxonomy.md"
    phase_rebuild_skill_packages >/dev/null 2>&1
    if [[ "$(get_phase rebuild_skill_packages)" != DRY-RUN*eval-writer* ]]; then
      echo "FAIL: core/standards/template-taxonomy.md MUST resolve eval-writer (rule b, already-covered tree), got '$(get_phase rebuild_skill_packages)'"; failures=$((failures+1))
    fi
    # (a3) rule (a) direct source — a references/ path stales the whole skill (cp -R).
    _rp_touch "core/skills/eval-writer/references/release-notes-eval-rubric.md"
    phase_rebuild_skill_packages >/dev/null 2>&1
    if [[ "$(get_phase rebuild_skill_packages)" != DRY-RUN*eval-writer* ]]; then
      echo "FAIL: a core/skills/eval-writer/ path MUST resolve eval-writer (rule a direct-source), got '$(get_phase rebuild_skill_packages)'"; failures=$((failures+1))
    fi
    # (a4) SPECIFICITY — an untouched skill is NOT rebuilt. Without this, an arm that
    #      resolved every skill for every path would satisfy a1-a3.
    _rp_touch "CHANGELOG.md"
    phase_rebuild_skill_packages >/dev/null 2>&1
    if [[ "$(get_phase rebuild_skill_packages | /usr/bin/cut -d'|' -f1)" != "N/A" ]]; then
      echo "FAIL: a non-skill non-canonical diff MUST resolve no package (specificity), got '$(get_phase rebuild_skill_packages)'"; failures=$((failures+1))
    fi

    # (a5) SENSITIVITY — a NON-SKILL directory under a skills/ root. Rule (a) is a
    #      regex capture over changed paths, so it yields whatever segment sits under
    #      the root: here `_shared`, a directory of behavioral markers with no SKILL.md
    #      that is in no deploy.sh roster and cannot be built. Emitting it hands this
    #      phase an argument that CANNOT succeed. Pre-fix this marked
    #      "DRY-RUN|would rebuild 1 package(s): _shared".
    _rp_touch "operations/skills/_shared/behavioral-markers.md"
    phase_rebuild_skill_packages >/dev/null 2>&1
    if [[ "$(get_phase rebuild_skill_packages | /usr/bin/cut -d'|' -f1)" != "N/A" ]]; then
      echo "FAIL: a path under operations/skills/_shared/ MUST NOT resolve a rebuild candidate — _shared is in no deploy.sh roster and cannot be built, got '$(get_phase rebuild_skill_packages)'"; failures=$((failures+1))
    fi
    # (a6) SECOND-DIRECTORY — proves the filter is a ROSTER-RESOLVABILITY TEST and not
    #      a hardcoded `_shared` exclusion. operations/skills/_templates/ is a LIVE
    #      second non-skill directory: it holds skill TEMPLATES whose own SKILL.md files
    #      sit one level deeper, so rule (a) captures `_templates`, which is in no
    #      roster. A hardcoded `_shared` exclusion would ship already broken against it,
    #      and this arm is what says so.
    _rp_touch "operations/skills/_templates/system-specialist/SKILL.md"
    phase_rebuild_skill_packages >/dev/null 2>&1
    if [[ "$(get_phase rebuild_skill_packages | /usr/bin/cut -d'|' -f1)" != "N/A" ]]; then
      echo "FAIL: a path under operations/skills/_templates/ MUST NOT resolve a rebuild candidate — the filter must test roster resolvability, not exclude a hardcoded _shared, got '$(get_phase rebuild_skill_packages)'"; failures=$((failures+1))
    fi
    # (a7) MIXED SET — the shape the real defect took. ONE commit touching an
    #      unbuildable path AND a real skill: the phase must KEEP the buildable
    #      candidate and DROP the unbuildable one. This is the anti-over-filtering
    #      arm — a filter that dropped everything would still satisfy a5 and a6.
    _rp_touch "operations/skills/_shared/behavioral-markers.md" "operations/skills/comms-writer/SKILL.md"
    phase_rebuild_skill_packages >/dev/null 2>&1
    if [[ "$(get_phase rebuild_skill_packages)" != *comms-writer* ]]; then
      echo "FAIL: a mixed commit MUST still resolve the real skill (comms-writer) — dropping every candidate is over-filtering, got '$(get_phase rebuild_skill_packages)'"; failures=$((failures+1))
    fi
    if [[ "$(get_phase rebuild_skill_packages)" == *_shared* ]]; then
      echo "FAIL: a mixed commit MUST drop the unbuildable candidate (_shared) while keeping the real skill, got '$(get_phase rebuild_skill_packages)'"; failures=$((failures+1))
    fi

    # (d) ANTI-REGRESSION PAIR, --apply. The fix changes WHICH skill a build failure is
    #     attributed to; it must NOT change WHETHER a real build failure stops the close.
    #     d1 and d2 share one sandbox, one mode, and one rule — rule (a), a path under a
    #     skills/ root — and differ in EXACTLY ONE variable: whether the captured segment
    #     is in the deploy.sh rosters. That is what makes roster-resolvability provably
    #     the variable under test rather than an assumed one.
    local _rp_rc=0
    MODE="apply"
    # (d1) A roster-RESOLVABLE skill that cannot build MUST still FAIL, BY NAME. This
    #      arm passes both pre- and post-fix BY DESIGN: its job is to fail if the fix
    #      ever over-filters a real skill or swallows a genuine build failure.
    #      Hermetic — `comms-writer` resolves, so the builder proceeds, and its
    #      canonical injection then returns 1 because the sandbox carries no canonical
    #      source tree. It returns before the complementary-pair post-condition and
    #      before any packager, so nothing is written to packages/ and python3 is never
    #      invoked. (The source dir itself DOES exist here — _rp_touch creates every
    #      path it commits — so the early `! -d` guard is not the one that fires.)
    _rp_touch "operations/skills/comms-writer/SKILL.md"
    phase_rebuild_skill_packages >/dev/null 2>&1 || _rp_rc=$?
    if [[ $_rp_rc -ne 3 ]]; then
      echo "FAIL: a roster-resolvable skill that cannot build MUST still return 3 under --apply — the loud stop is kept, only its attribution changes, got rc $_rp_rc"; failures=$((failures+1))
    fi
    if [[ "$(get_phase rebuild_skill_packages | /usr/bin/cut -d'|' -f1)" != "FAIL" ]]; then
      echo "FAIL: a real build failure MUST mark FAIL, not a green outcome, got '$(get_phase rebuild_skill_packages)'"; failures=$((failures+1))
    fi
    if [[ "$(get_phase rebuild_skill_packages)" != *comms-writer* ]]; then
      echo "FAIL: the FAIL detail MUST name the skill that actually failed, not the whole candidate set, got '$(get_phase rebuild_skill_packages)'"; failures=$((failures+1))
    fi
    # (d2) THE CONVERSE, same sandbox and same mode: an unbuildable-BY-FILTER path must
    #      reach the N/A limb and return 0, never the FAIL limb. Pre-fix this returned 3
    #      and marked FAIL, because `_shared` was handed to a real build.
    _rp_rc=0
    _rp_touch "operations/skills/_shared/behavioral-markers.md"
    phase_rebuild_skill_packages >/dev/null 2>&1 || _rp_rc=$?
    if [[ $_rp_rc -ne 0 ]]; then
      echo "FAIL: a non-skill directory under a skills/ root must NOT reach the builder under --apply (pre-fix this returned 3), got rc $_rp_rc"; failures=$((failures+1))
    fi
    if [[ "$(get_phase rebuild_skill_packages | /usr/bin/cut -d'|' -f1)" != "N/A" ]]; then
      echo "FAIL: a filtered-out candidate must mark N/A, not FAIL, got '$(get_phase rebuild_skill_packages)'"; failures=$((failures+1))
    fi
    MODE="dry-run"

    # (b) C1 — the fail-loud guard's MODE SCOPING (#4765 convention: assert at
    #     --apply, predict at --dry-run). ONE fixture — the builder removed, so
    #     delegation cannot answer — driven in BOTH modes, so the mode is provably
    #     the variable under test. The dry-run arm is the #4765 regression guard: a
    #     return 3 here would abort the run and EVERY phase after 9.95 would
    #     never enumerate, re-breaking the dry-run review gate #4765 just restored.
    #     The apply arm is the anti-vacuity half: it proves the fixture really is
    #     broken and that the guard still blocks a real close.
    /bin/rm -f "$_rp_work/core/deploy/tools/build-skill-packages.sh"
    _rp_touch "core/schemas/tracker-schemas.md"
    local _rp_rc=0
    MODE="dry-run"; phase_rebuild_skill_packages >/dev/null 2>&1 || _rp_rc=$?
    if [[ $_rp_rc -ne 0 ]]; then
      echo "FAIL: C1 — an undeterminable set under --dry-run must NOT abort (rc $_rp_rc); every phase after 9.95 would never enumerate (#4765)"; failures=$((failures+1))
    fi
    if [[ "$(get_phase rebuild_skill_packages | /usr/bin/cut -d'|' -f1)" != "WARN" ]]; then
      echo "FAIL: C1 — an undeterminable set under --dry-run must mark WARN, not a green outcome, got '$(get_phase rebuild_skill_packages)'"; failures=$((failures+1))
    fi
    PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=(); _rp_rc=0
    MODE="apply"; phase_rebuild_skill_packages >/dev/null 2>&1 || _rp_rc=$?
    if [[ $_rp_rc -ne 3 ]]; then
      echo "FAIL: C1 — the SAME undeterminable set under --apply must return 3 (fail-loud), got rc $_rp_rc"; failures=$((failures+1))
    fi
    if [[ "$(get_phase rebuild_skill_packages | /usr/bin/cut -d'|' -f1)" != "FAIL" ]]; then
      echo "FAIL: C1 — an undeterminable set under --apply must mark FAIL, got '$(get_phase rebuild_skill_packages)'"; failures=$((failures+1))
    fi

    unset -f _rp_touch
    REPO_ROOT="$_rp_root"; MODE="$_rp_mode"; MERGE_SHA="$_rp_merge"
    PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
    /bin/rm -rf "$_rp_tmp" 2>/dev/null || true
  else
    echo "  (skipped #4722 rebuild-detection behavioural arms — git not executable at $GIT)" >&2
  fi

  # (c) STRUCTURAL anti-regression, asserted against the REAL function body. These
  #     pin the three regressions C2 named as leaving a delegated suite green:
  #     re-adding `|| true`, dropping --root, and moving the guard below the dry-run
  #     return. (declare -f strips comments, so every anchor below is code.)
  #     Every grep below reads a HERE-STRING and is `|| true`-terminated. The
  #     here-string is the SIGPIPE-idiom gate's prescribed form: `writer | head` lets
  #     the reader short-circuit and SIGPIPE the writer, making rc=1 indistinguishable
  #     from "no match"; with no writer upstream there is nothing to signal. The
  #     `|| true` is the set -euo pipefail half — a no-match grep inside a command
  #     substitution would ABORT the suite rather than report, and it would abort on
  #     exactly the regression the arm exists to catch, turning a red into a crash
  #     with no verdict. (Scaffold safety on the TEST's own greps; unrelated to the
  #     production `|| true` c3 forbids, which sits on the delegation's exit code.)
  local _rp_body _rp_detect
  _rp_body="$(declare -f phase_rebuild_skill_packages)"
  _rp_detect="$(/usr/bin/grep -F -m1 -- '--skills-for-paths' <<< "$_rp_body" || true)"
  # c1 — the shadow-SSOT copy must stay deleted (claim-version.sh:743-746 states the
  #      rule; changed_skills_from_paths WAS the second copy it warns about).
  if declare -F changed_skills_from_paths >/dev/null 2>&1; then
    echo "FAIL: changed_skills_from_paths must NOT exist — detection is delegated to build-skill-packages.sh --skills-for-paths (#4722 shadow SSOT)"; failures=$((failures+1))
  fi
  # c2 — --root is load-bearing: without it the builder answers from ITS OWN tree.
  if [[ "$_rp_detect" != *'--root "$REPO_ROOT" --skills-for-paths'* ]]; then
    echo "FAIL: detection must delegate as --root \"\$REPO_ROOT\" --skills-for-paths; dropping --root answers from the builder's own tree, got '$_rp_detect'"; failures=$((failures+1))
  fi
  # c3 — the delegation's exit code IS the fail-loud signal; `|| true` would map every
  #      failure back onto the empty string and re-open the green-over-unknown gap.
  if [[ "$_rp_detect" != *'detect_rc=$?'* || "$_rp_detect" == *'|| true'* ]]; then
    echo "FAIL: the delegation must capture its exit code (|| detect_rc=\$?) and must NOT swallow it with '|| true', got '$_rp_detect'"; failures=$((failures+1))
  fi
  # c4 — ORDERING: the fail-loud guard must sit ABOVE the dry-run enumerate branch.
  #      Below it, a dry-run reports a green "would rebuild 0" over an undeterminable
  #      set — the exact silent-empty this card closes.
  #      grep -n -m1 over a here-string, then `%%:*` to take the line number — pure
  #      parameter expansion rather than a `| cut`, so the statement carries no
  #      pipeline at all and cannot be a SIGPIPE-idiom finding.
  local _rp_ln_guard _rp_ln_dry
  _rp_ln_guard="$(/usr/bin/grep -n -m1 '_d_fix=' <<< "$_rp_body" || true)"; _rp_ln_guard="${_rp_ln_guard%%:*}"
  _rp_ln_dry="$(/usr/bin/grep -nF -m1 'would rebuild' <<< "$_rp_body" || true)"; _rp_ln_dry="${_rp_ln_dry%%:*}"
  if [[ -z "$_rp_ln_guard" || -z "$_rp_ln_dry" || "$_rp_ln_guard" -ge "$_rp_ln_dry" ]]; then
    echo "FAIL: the undeterminable-set guard must precede the dry-run enumerate branch (guard line '$_rp_ln_guard', dry-run line '$_rp_ln_dry')"; failures=$((failures+1))
  fi
  # c5 — BUILD-INVOCATION SHAPE. The build call must sit inside a PER-SKILL loop that
  #      accumulates failures by name, not a single batched call over $candidates. A
  #      batched call collapses every skill's outcome onto one exit code, so the phase
  #      can only ever name the whole candidate set — which IS the defect. It must also
  #      pass --root, for the same reason c2 requires it on the detection call and with
  #      more force: detection answering from the wrong tree is a wrong answer, but
  #      BUILDING into the wrong tree writes packages there. Anchored on code, since
  #      declare -f strips comments.
  local _rp_build
  _rp_build="$(/usr/bin/grep -F -m1 -- '"$builder" --root "$REPO_ROOT" "$_rb_skill"' <<< "$_rp_body" || true)"
  if [[ -z "$_rp_build" ]]; then
    echo "FAIL: the BUILD invocation must run per skill as \"\$builder\" --root \"\$REPO_ROOT\" \"\$_rb_skill\" — a batched call cannot attribute a failure, and without --root the builder builds into its OWN tree"; failures=$((failures+1))
  fi
  if [[ "$_rp_body" != *'for _rb_skill in $candidates'* ]]; then
    echo "FAIL: the build invocation must sit inside a 'for _rb_skill in \$candidates' loop; a single batched call re-opens the whole-set attribution defect"; failures=$((failures+1))
  fi
  if [[ "$_rp_body" != *'_rb_failed='* ]]; then
    echo "FAIL: the build loop must accumulate failures in _rb_failed so the FAIL detail names only the skills that actually failed"; failures=$((failures+1))
  fi
  # files=() composition (P1 regression guard) — the commit phase MUST expand
  # "${REBUILT_PACKAGES[@]:-}" in its files=() array, else a rebuilt package is
  # silently dropped from the chore commit.
  if ! declare -f phase_commit_chore_pr | /usr/bin/grep -qF '"${REBUILT_PACKAGES[@]:-}"'; then
    echo "FAIL: phase_commit_chore_pr files=() must expand \"\${REBUILT_PACKAGES[@]:-}\" (P1 staging-omission guard)"; failures=$((failures+1))
  fi

  # Test 11d — TOUCHED-SURFACE staging completeness (#4710 AC-3), BEHAVIORAL.
  #
  # The P1 guard directly above is a `declare -f | grep`, and a grep cannot observe
  # an assertion FAILING — it only observes that a string is present. An assertion
  # never seen to fire is indistinguishable from one that cannot fire, which is the
  # exact condition #4710 AC-3 was filed against: the empty-staged-set guard was
  # unreachable on any real close-out and nothing noticed. So this arm drives the
  # REAL phase_commit_chore_pr against a sandbox git repo in BOTH polarities:
  # (a) recorded -> PASS and the resolved target is NAMED in the phase detail, and
  # (b) recorder omitted -> FAIL. (b) is the sensitivity control; without it (a)
  # proves only that the phase can say PASS.
  #
  # Hermetic + offline: `git init` and a local commit, no network and no gh token.
  local _tsc_saved_root="$REPO_ROOT" _tsc_saved_mode="$MODE" _tsc_saved_version="$VERSION"
  local _tsc_saved_log="$RELEASE_LOG"
  local _tsc_tmp; _tsc_tmp="$(/usr/bin/mktemp -d -t touchedsurface-selftest.XXXXXX)"
  /bin/mkdir -p "$_tsc_tmp/release/releases"
  $GIT -C "$_tsc_tmp" init -q >/dev/null 2>&1
  $GIT -C "$_tsc_tmp" config user.email "selftest@example.invalid" >/dev/null 2>&1
  $GIT -C "$_tsc_tmp" config user.name "selftest" >/dev/null 2>&1
  $GIT -C "$_tsc_tmp" config commit.gpgsign false >/dev/null 2>&1
  local _tsc_ledger="$_tsc_tmp/release/releases/RELEASE_LOG.md"
  local _tsc_seg="$_tsc_tmp/release/releases/RELEASE_LOG_ARCHIVE-v9.md"
  /usr/bin/printf 'seed\n' > "$_tsc_ledger"
  /usr/bin/printf 'seed\n' > "$_tsc_seg"
  # A parent commit, so the chore commit is never a ROOT commit: `diff-tree -r HEAD`
  # emits nothing for a root commit without --root, which would make BOTH polarities
  # look identical and the arm vacuous.
  $GIT -C "$_tsc_tmp" add -A >/dev/null 2>&1
  $GIT -C "$_tsc_tmp" commit -q -m "seed" >/dev/null 2>&1

  REPO_ROOT="$_tsc_tmp"; MODE="apply"; VERSION="v9.99"; RELEASE_LOG="$_tsc_ledger"

  local _tsc_pol _tsc_rc _tsc_detail
  for _tsc_pol in recorded omitted; do
    /usr/bin/printf 'seed\n%s edit\n' "$_tsc_pol" > "$_tsc_ledger"
    /usr/bin/printf 'seed\n%s segment write\n' "$_tsc_pol" > "$_tsc_seg"
    # The phase record is the assertion's ONLY source for what was written — an
    # inject_* phase that reported PASS and NAMED the segment it resolved to.
    PHASE_NAMES=("inject_velocity_field"); PHASE_RESULTS=("PASS")
    PHASE_DETAILS=("injected '**Velocity:** 1' after **Cycle-Time:** in the v9.99 Deployment Log block (RELEASE_LOG_ARCHIVE-v9.md)")
    REBUILT_PACKAGES=()
    if [[ "$_tsc_pol" == "recorded" ]]; then
      TOUCHED_ARCHIVE_SEGMENTS=("release/releases/RELEASE_LOG_ARCHIVE-v9.md")
    else
      # The defect under test: the write site forgot to call
      # _record_touched_archive_segment, so files=() never names the segment.
      TOUCHED_ARCHIVE_SEGMENTS=()
    fi
    _tsc_rc=0
    phase_commit_chore_pr >/dev/null 2>&1 || _tsc_rc=$?
    _tsc_detail="$(get_phase commit_chore_pr)"
    if [[ "$_tsc_pol" == "recorded" ]]; then
      [[ "$_tsc_rc" -eq 0 ]] || { echo "FAIL: AC-3 recorded polarity must succeed, got rc=$_tsc_rc ('$_tsc_detail')"; failures=$((failures+1)); }
      /usr/bin/grep -qF 'resolved write target(s) staged: RELEASE_LOG_ARCHIVE-v9.md' <<<"$_tsc_detail" \
        || { echo "FAIL: AC-3 the PASS detail must NAME the resolved write target it staged, got '$_tsc_detail'"; failures=$((failures+1)); }
    else
      [[ "$_tsc_rc" -eq 3 ]] || { echo "FAIL: AC-3 SENSITIVITY — an unrecorded segment write must FAIL the phase (rc=3), got rc=$_tsc_rc ('$_tsc_detail')"; failures=$((failures+1)); }
      /usr/bin/grep -qF 'RELEASE_LOG_ARCHIVE-v9.md' <<<"$_tsc_detail" \
        || { echo "FAIL: AC-3 the failure must NAME the dropped surface, got '$_tsc_detail'"; failures=$((failures+1)); }
    fi
  done

  # Independence guard: the assertion must NOT read TOUCHED_ARCHIVE_SEGMENTS to
  # decide what to expect. It reads the phase record for exactly the reason the
  # empty-staged-set guard does — a check sourced from the recorder whose omission
  # IS the defect goes vacuous the moment a write site stops recording.
  # The anchor is CODE, not a comment: `declare -f` renders a function body with
  # comments stripped, so a comment anchor silently never matches and the guard
  # reads the whole body — passing or failing for the wrong reason.
  local _tsc_body; _tsc_body="$(declare -f phase_commit_chore_pr)"
  local _tsc_anchor='local _reported='
  if ! /usr/bin/grep -qF "$_tsc_anchor" <<<"$_tsc_body"; then
    echo "FAIL: AC-3 independence guard lost its anchor ('$_tsc_anchor') — the guard cannot be evaluated"; failures=$((failures+1))
  else
    local _tsc_after; _tsc_after="${_tsc_body#*"$_tsc_anchor"}"
    if /usr/bin/grep -qF 'TOUCHED_ARCHIVE_SEGMENTS' <<<"$_tsc_after"; then
      echo "FAIL: AC-3 the touched-surface assertion must not consult TOUCHED_ARCHIVE_SEGMENTS — it is the recorder whose omission is the defect"; failures=$((failures+1))
    fi
  fi

  REPO_ROOT="$_tsc_saved_root"; MODE="$_tsc_saved_mode"; VERSION="$_tsc_saved_version"
  RELEASE_LOG="$_tsc_saved_log"
  REBUILT_PACKAGES=(); TOUCHED_ARCHIVE_SEGMENTS=()
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  /bin/rm -rf "$_tsc_tmp"

  # Test 12: scaffold-residue detector (AC1) + pre-authored-note tolerance (AC2).
  # Offline, hermetic, credential-free — the CI smoke job runs --self-test with no
  # network and no gh token.
  #
  # T1 is the ANTI-DRIFT test and the reason this block exists: it runs the REAL
  # phase_scaffold_release_notes into a sandbox notes dir and asserts the REAL token
  # set trips on the REAL output. Add a placeholder to the scaffold heredoc without
  # adding its token to SCAFFOLD_RESIDUE_TOKENS and this test goes red. A detector
  # derived from its own producer cannot silently diverge from it.
  local _sr_saved_root="$REPO_ROOT" _sr_saved_mode="$MODE" _sr_saved_version="$VERSION"
  local _sr_saved_notesdir="$RELEASE_NOTES_DIR" _sr_saved_digest="$RELEASE_DIGEST"
  # RELEASE_PLANS_DIR is saved and rebound below for the same reason RELEASE_NOTES_DIR
  # is: it is set at load time from the REAL $REPO_ROOT, so a block that rebinds only
  # REPO_ROOT would leave the plans resolver reading the LIVE repository tree and the
  # PL-* arms below would assert against whatever the working copy happens to contain.
  local _sr_saved_plansdir="$RELEASE_PLANS_DIR"
  local _sr_saved_pr="$PR_NUMBER" _sr_saved_slug="$STATE_MILESTONE_SLUG"
  local _sr_tmp; _sr_tmp="$(/usr/bin/mktemp -d -t scaffoldresidue-selftest.XXXXXX)"
  /bin/mkdir -p "$_sr_tmp/notes"
  REPO_ROOT="$_sr_tmp"; MODE="apply"; VERSION="v9.99"
  RELEASE_NOTES_DIR="$_sr_tmp/notes"; RELEASE_DIGEST="$_sr_tmp/RELEASE_DIGEST.md"
  RELEASE_PLANS_DIR="$_sr_tmp/plans"; /bin/mkdir -p "$RELEASE_PLANS_DIR"
  PR_NUMBER="9999"; STATE_MILESTONE_SLUG="selftest-slug"

  # (a) AC1-T1 round-trip — the real scaffold must trip the real detector.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_scaffold_release_notes >/dev/null 2>&1
  local _sr_note="$RELEASE_NOTES_DIR/${VERSION}_RELEASE_NOTES.md"
  if [[ ! -f "$_sr_note" ]]; then
    echo "FAIL: AC1-T1 setup — phase_scaffold_release_notes wrote no note at $_sr_note"; failures=$((failures+1))
  else
    local _sr_res _sr_rc=0
    _sr_res="$(/usr/bin/awk '{print NR "\t" $0}' "$_sr_note" | scan_scaffold_residue)" || _sr_rc=$?
    [[ "$_sr_rc" -eq 1 ]] || { echo "FAIL: AC1-T1 round-trip — the byte-exact scaffold MUST trip the residue detector (rc=$_sr_rc); the token set has drifted from phase_scaffold_release_notes"; failures=$((failures+1)); }
    [[ -n "${_sr_res%%|*}" ]] || { echo "FAIL: AC1-T1 must NAME the offending token, got '$_sr_res'"; failures=$((failures+1)); }
    [[ "${_sr_res#*|}" =~ ^[0-9]+$ ]] || { echo "FAIL: AC1-T1 must report a numeric line, got '$_sr_res'"; failures=$((failures+1)); }
  fi

  # (b) AC1-T2 — a fully-authored note trips nothing (no false positive). Written
  # into the sandbox notes dir so (b1) below can use it as the negative control.
  local _sr_authored="$RELEASE_NOTES_DIR/v9.98_RELEASE_NOTES.md"
  /bin/cat > "$_sr_authored" <<'AUTHORED'
---
version: v9.98
summary: "A real one-sentence summary written by a human."
---
# Close-out now refuses to ship an unauthored release note

## What changed for everyone using the platform

- **Unfilled release notes no longer reach the Releases page.** *Why it matters:* the
  note you read is the note someone actually wrote.
AUTHORED
  local _sr_rc2=0
  /usr/bin/awk '{print NR "\t" $0}' "$_sr_authored" | scan_scaffold_residue >/dev/null || _sr_rc2=$?
  [[ "$_sr_rc2" -eq 0 ]] || { echo "FAIL: AC1-T2 — an authored note must produce NO residue finding (rc=$_sr_rc2)"; failures=$((failures+1)); }

  # (b1) AC1-T5 — the PYTHON anchor (lint_release_corpus.py check_note_content).
  # Drives the real check against a 2-note sandbox population: the scaffold from (a)
  # and the authored note from (b). Asserts on a NON-EMPTY population with a control —
  # exactly one NOTE-SCAFFOLD-RESIDUE, naming the scaffold and not the authored note.
  # Hermetic: the module is imported and NOTES_DIR / PLANS_DIR / WORKSPACE_ROOT are
  # ALL rebound, so the live corpus is never read and no network or credential is
  # involved. WORKSPACE_ROOT and PLANS_DIR matter because check_note_content()'s
  # Tier-1 links.plan limb resolves pointer values against them — leaving them at
  # their module defaults would resolve this sandbox's notes against the real
  # repository's plans, which is not a sandbox.
  local _sr_lintout
  _sr_lintout="$(/usr/bin/python3 - "$LINT_RELEASE_CORPUS" "$RELEASE_NOTES_DIR" "$_sr_tmp" "$RELEASE_PLANS_DIR" <<'PY' 2>&1 || true
import importlib.util, pathlib, sys
lint_path, notes_dir, ws_root, plans_dir = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
spec = importlib.util.spec_from_file_location("lint_rc_selftest", lint_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
mod.NOTES_DIR = pathlib.Path(notes_dir)
mod.WORKSPACE_ROOT = pathlib.Path(ws_root)
mod.PLANS_DIR = pathlib.Path(plans_dir)
for finding in mod.check_note_content():
    print(finding)
PY
)"
  local _sr_resn
  _sr_resn="$(printf '%s\n' "$_sr_lintout" | /usr/bin/grep -c 'NOTE-SCAFFOLD-RESIDUE' || true)"
  [[ "$_sr_resn" -eq 1 ]] || { echo "FAIL: AC1-T5 — check_note_content() must emit EXACTLY 1 NOTE-SCAFFOLD-RESIDUE over the 2-note sandbox (scaffold + authored), got $_sr_resn"; failures=$((failures+1)); }
  printf '%s\n' "$_sr_lintout" | /usr/bin/grep 'NOTE-SCAFFOLD-RESIDUE' | /usr/bin/grep -qF 'v9.99_RELEASE_NOTES.md' || { echo "FAIL: AC1-T5 — the residue finding must name the SCAFFOLD note (v9.99)"; failures=$((failures+1)); }
  if printf '%s\n' "$_sr_lintout" | /usr/bin/grep 'NOTE-SCAFFOLD-RESIDUE' | /usr/bin/grep -qF 'v9.98_RELEASE_NOTES.md'; then
    echo "FAIL: AC1-T5 — the AUTHORED note (v9.98) must NOT be flagged as residue"; failures=$((failures+1))
  fi

  # (c) AC1-T4 — residue in THIS version's CHANGELOG slice FAILs and names the token.
  /bin/cat > "$_sr_tmp/CHANGELOG.md" <<'CL'
# Changelog

## [v9.99] - 2026-07-30

<one-sentence ≤140 chars; plain language; agent-search target>

## [v9.98] - 2026-07-01

A properly authored earlier entry.
CL
  /bin/cat > "$RELEASE_DIGEST" <<'DG'
## v9.x

### v9.99 (2026-07-30) — <headline — populated by operator at chore PR review>
DG
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  if phase_assert_derived_surfaces >/dev/null 2>&1; then
    echo "FAIL: AC1-T4 — phase_assert_derived_surfaces must return non-zero on residue in THIS version's entry"; failures=$((failures+1))
  fi
  [[ "$(get_phase assert_derived_surfaces | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: AC1-T4 must mark the phase FAIL, got '$(get_phase assert_derived_surfaces)'"; failures=$((failures+1)); }
  get_phase assert_derived_surfaces | /usr/bin/grep -qF 'CHANGELOG.md:' || { echo "FAIL: AC1-T4 detail must name the surface and line, got '$(get_phase assert_derived_surfaces)'"; failures=$((failures+1)); }

  # (d) AC1-T3 audit-baseline control — residue for ANOTHER version must NOT block
  # this version's close. This is the control that proves the phase is version-scoped;
  # without it a corpus-wide scan would pass every other assertion in this block.
  /bin/cat > "$_sr_tmp/CHANGELOG.md" <<'CL2'
# Changelog

## [v9.99] - 2026-07-30

A properly authored current entry.

## [v9.98] - 2026-07-01

<one-sentence ≤140 chars; plain language; agent-search target>
CL2
  /bin/cat > "$RELEASE_DIGEST" <<'DG2'
## v9.x

### v9.99 (2026-07-30) — A properly authored current headline

### v9.98 (2026-07-01) — <headline — populated by operator at chore PR review>
DG2
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_assert_derived_surfaces >/dev/null 2>&1 || { echo "FAIL: AC1-T3 — another version's pre-existing residue must NOT block this close (audit-baseline discipline)"; failures=$((failures+1)); }
  [[ "$(get_phase assert_derived_surfaces | /usr/bin/cut -d'|' -f1)" == "PASS" ]] || { echo "FAIL: AC1-T3 must mark PASS, got '$(get_phase assert_derived_surfaces)'"; failures=$((failures+1)); }

  # (d1) AC1-T6/T7 — MODE-AWARENESS OF THE PRESENCE LIMB (#4765). Two arms over ONE
  # fixture, differing only in $MODE, so the mode is provably the variable under test
  # and not the fixture.
  #
  # The fixture is the real defect state: a release whose entries are ABSENT from both
  # derived surfaces. That is what every first --dry-run of a release looks like, because
  # the append phases at 8.x/9.5 deliberately wrote nothing. Pre-fix, BOTH arms below
  # returned non-zero, the runner exited 3, and the phases after this one never
  # enumerated — so the dry-run review gate could not be produced for any release that
  # had not already closed.
  #
  # T7 is the anti-vacuity arm. Without it, T6 is satisfiable by a phase that has been
  # gutted (presence limb deleted) rather than made mode-aware, and by a fixture that
  # accidentally contains the v9.99 entries it claims to omit. T7 observes non-zero on
  # the identical bytes, which proves the fixture really does omit them AND that the
  # apply-mode limb still fires. T6's outcome assertion is the specificity half: it
  # demands the literal string DRY-RUN, so a phase that returns 0 by PASSing vacuously
  # is caught rather than counted as a pass.
  /bin/cat > "$_sr_tmp/CHANGELOG.md" <<'CL3'
# Changelog

## [v9.98] - 2026-07-01

A properly authored earlier entry.
CL3
  /bin/cat > "$RELEASE_DIGEST" <<'DG3'
## v9.x

### v9.98 (2026-07-01) — A properly authored earlier headline
DG3
  # T6 (must-not-fail arm) — dry-run over absent entries: rc 0, outcome DRY-RUN.
  MODE="dry-run"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  local _sr_drrc=0
  phase_assert_derived_surfaces >/dev/null 2>&1 || _sr_drrc=$?
  [[ "$_sr_drrc" -eq 0 ]] || { echo "FAIL: AC1-T6 — under --dry-run the phase must NOT return non-zero when the ${VERSION} entries are absent (they are absent by construction; the append phases wrote nothing), got rc=$_sr_drrc"; failures=$((failures+1)); }
  [[ "$(get_phase assert_derived_surfaces | /usr/bin/cut -d'|' -f1)" == "DRY-RUN" ]] || { echo "FAIL: AC1-T6 — under --dry-run the outcome must be literally DRY-RUN (a vacuous PASS would also return 0 and must not count), got '$(get_phase assert_derived_surfaces)'"; failures=$((failures+1)); }

  # T7 (must-fail arm / anti-vacuity control) — SAME fixture under --apply: rc non-zero,
  # outcome FAIL, and the original dropped-write message preserved verbatim.
  MODE="apply"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  local _sr_aprc=0
  phase_assert_derived_surfaces >/dev/null 2>&1 || _sr_aprc=$?
  [[ "$_sr_aprc" -ne 0 ]] || { echo "FAIL: AC1-T7 anti-vacuity — under --apply the SAME absent-entry fixture MUST still fail; rc=0 means either the presence limb was gutted rather than made mode-aware, or the fixture is not actually missing the ${VERSION} entries it claims to omit"; failures=$((failures+1)); }
  [[ "$(get_phase assert_derived_surfaces | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: AC1-T7 must mark the phase FAIL under --apply, got '$(get_phase assert_derived_surfaces)'"; failures=$((failures+1)); }
  # Captured, then matched from a here-string: `writer | grep -q` would short-circuit
  # and SIGPIPE get_phase, and on CI that rc=1 is indistinguishable from "no match" —
  # the assertion would read as a clean fail rather than a broken probe.
  local _sr_t7detail; _sr_t7detail="$(get_phase assert_derived_surfaces)"
  /usr/bin/grep -qF 'no v9.99 entry on the derived surface' <<<"$_sr_t7detail" || { echo "FAIL: AC1-T7 — the --apply presence message must be preserved verbatim (AC2: the apply limb is unchanged), got '$_sr_t7detail'"; failures=$((failures+1)); }

  # (e) AC2 — preflight working-tree tolerance. Drives the shipped predicate with
  # synthetic porcelain text (no git, no network).
  local _sr_tol
  _sr_tol="$(printf '%s\n' "?? release/releases/notes/v9.99_RELEASE_NOTES.md" | filter_tolerated_worktree_state)"
  [[ -z "$_sr_tol" ]] || { echo "FAIL: AC2-T1 — an untracked note for THIS version must be tolerated, got '$_sr_tol'"; failures=$((failures+1)); }
  _sr_tol="$(printf '%s\n' "?? release/releases/notes/v9.98_RELEASE_NOTES.md" | filter_tolerated_worktree_state)"
  [[ -n "$_sr_tol" ]] || { echo "FAIL: AC2-T2 — an untracked note for ANOTHER version must still block"; failures=$((failures+1)); }
  _sr_tol="$(printf '%s\n' " M release/releases/notes/v9.99_RELEASE_NOTES.md" | filter_tolerated_worktree_state)"
  [[ -n "$_sr_tol" ]] || { echo "FAIL: AC2-T3 — a MODIFIED-tracked note must still block (tolerance is untracked-only)"; failures=$((failures+1)); }
  _sr_tol="$(printf '%s\n' "?? CHANGELOG.md" | filter_tolerated_worktree_state)"
  [[ -n "$_sr_tol" ]] || { echo "FAIL: AC2-T4 — an unrelated untracked file must still block (tolerance must not generalize)"; failures=$((failures+1)); }
  # T5 makes `grep -x` load-bearing: a same-prefix sibling must NOT inherit the
  # tolerance. Without this case a substring match would pass every other AC2 test.
  _sr_tol="$(printf '%s\n' "?? release/releases/notes/v9.99_RELEASE_NOTES.md.bak" | filter_tolerated_worktree_state)"
  [[ -n "$_sr_tol" ]] || { echo "FAIL: AC2-T5 — a same-prefix sibling (.bak) must still block; the tolerance is a whole-line match, not a prefix"; failures=$((failures+1)); }

  # (f) AC1/AC2 VERSION-LESS SHAPE (#3113 Records 2+3). Every fixture above binds a
  # canonical vX.Y version, so the whole AC1/AC2 block was green over a population
  # that structurally excluded the failing case — the corpus carries version-less
  # releases (notes live under notes/_unversioned/), and for those the producer and
  # the two preflight consumers named DIFFERENT files. Consequences, all reproduced
  # by the assertions below: preflight (f) scanned a path that never existed, so the
  # residue gate was a silent no-op; and preflight (b) rejected the untracked
  # scaffold the script itself had just written — the resume deadlock the (b)
  # tolerance exists to prevent, and one that does NOT clear when the operator
  # authors the note, because the blocking record is the flat path no rule names.
  #
  # This block re-runs the SAME contract as (a) and (e) with is_version_less TRUE.
  # It is the mutation-sensitive fixture: revert phase_scaffold_release_notes to a
  # hand-typed flat path and VL-1, VL-3 and VL-4 all go red.
  local _sr_vl="77-selftest-version-less-theme"
  local _sr_vl_other="78-selftest-other-version-less-theme"
  VERSION="$_sr_vl"
  is_version_less || { echo "FAIL: AC1/AC2-VL setup — '$_sr_vl' must classify as version-less; the fixture is not exercising the branch it claims"; failures=$((failures+1)); }

  # VL-0 — the two resolvers must name the SAME file. notes_abs_path() is DERIVED
  # from notes_rel_path(), so this is the structural guard against them drifting
  # apart again; it is asserted in BOTH identity modes.
  local _sr_vl_expect="${RELEASE_NOTES_DIR}/_unversioned/${_sr_vl}_RELEASE_NOTES.md"
  [[ "$(notes_abs_path)" == "$_sr_vl_expect" ]] || { echo "FAIL: AC1/AC2-VL-0 — notes_abs_path() must resolve to '$_sr_vl_expect', got '$(notes_abs_path)'"; failures=$((failures+1)); }
  VERSION="v9.97"
  [[ "$(notes_abs_path)" == "${RELEASE_NOTES_DIR}/v9.97_RELEASE_NOTES.md" ]] || { echo "FAIL: AC1/AC2-VL-0 (versioned control) — notes_abs_path() must stay FLAT for a canonical version, got '$(notes_abs_path)'"; failures=$((failures+1)); }
  VERSION="$_sr_vl"

  # VL-1 — the PRODUCER writes where the consumers read. The _unversioned/ dir is
  # deliberately NOT pre-created: a corpus that has never held a version-less note
  # must still work, so the producer owns creating it.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  # `|| true` so a producer that cannot write (e.g. the parent dir does not exist)
  # is reported by VL-1's assertion rather than aborting the suite under `set -e`
  # with no diagnostic — a red run nobody can read is barely better than a green one.
  phase_scaffold_release_notes >/dev/null 2>&1 || true
  [[ -f "$_sr_vl_expect" ]] || { echo "FAIL: AC1/AC2-VL-1 — phase_scaffold_release_notes must write the version-less note to $_sr_vl_expect (producer/consumer path agreement); the phase reported: $(get_phase scaffold_release_notes)"; failures=$((failures+1)); }
  # Anti-vacuity twin: VL-1 must not be satisfiable by writing BOTH paths.
  [[ ! -f "${RELEASE_NOTES_DIR}/${_sr_vl}_RELEASE_NOTES.md" ]] || { echo "FAIL: AC1/AC2-VL-2 — a version-less note must NOT be written FLAT; that is the shape preflight (b) cannot tolerate and preflight (f) cannot see"; failures=$((failures+1)); }

  # VL-3 — preflight (f)'s residue gate must FIRE on the version-less scaffold. On
  # the defective shape this returned "file absent" and the gate passed vacuously,
  # which is why an entirely unauthored version-less note could reach the Releases
  # page. rc MUST be 1 (residue found), never 0 (clean) and never 2 (unreadable).
  local _sr_vlres _sr_vlrc=0
  _sr_vlres="$(/usr/bin/awk '{print NR "\t" $0}' "$(notes_abs_path)" 2>/dev/null | scan_scaffold_residue)" || _sr_vlrc=$?
  [[ "$_sr_vlrc" -eq 1 ]] || { echo "FAIL: AC1/AC2-VL-3 — the version-less scaffold must trip the residue detector, got rc=$_sr_vlrc (0 = the gate read the file and saw nothing; 2 = it could not read the file at all — on the defective shape there is no file at this path). Either way the residue gate does not see this shape"; failures=$((failures+1)); }
  [[ "${_sr_vlres#*|}" =~ ^[0-9]+$ ]] || { echo "FAIL: AC1/AC2-VL-3 must report a numeric line, got '$_sr_vlres'"; failures=$((failures+1)); }

  # VL-4 — preflight (b) must TOLERATE the untracked record for the file the
  # producer just wrote. The porcelain record is built by DISCOVERING the produced
  # file, never by re-deriving it from notes_rel_path() — a record built from the
  # consumer's own rule would be tolerated by construction and could never catch a
  # producer that writes somewhere else. This is the deadlock closure assertion.
  local _sr_vlfound
  _sr_vlfound="$(cd "$RELEASE_NOTES_DIR" && /usr/bin/find . -name "${_sr_vl}_RELEASE_NOTES.md" 2>/dev/null | /usr/bin/sed 's|^\./||' | /usr/bin/head -1)"
  if [[ -z "$_sr_vlfound" ]]; then
    echo "FAIL: AC1/AC2-VL-4 — the producer wrote no version-less note anywhere under $RELEASE_NOTES_DIR; nothing to tolerate"; failures=$((failures+1))
  else
    _sr_tol="$(printf '%s\n' "?? release/releases/notes/${_sr_vlfound}" | filter_tolerated_worktree_state)"
    [[ -z "$_sr_tol" ]] || { echo "FAIL: AC1/AC2-VL-4 — preflight (b) must tolerate the untracked note this run PRODUCED ('?? release/releases/notes/${_sr_vlfound}'), got '$_sr_tol' — RESUME DEADLOCK on the script's own scaffold"; failures=$((failures+1)); }
  fi

  # VL-5 — controls. The tolerance must not have generalized: the FLAT form of THIS
  # slug (the defective bucket) and the _unversioned/ note of ANOTHER version-less
  # release must both still block. Without these, VL-4 would pass on a tolerance
  # that had simply stopped discriminating.
  _sr_tol="$(printf '%s\n' "?? release/releases/notes/${_sr_vl}_RELEASE_NOTES.md" | filter_tolerated_worktree_state)"
  [[ -n "$_sr_tol" ]] || { echo "FAIL: AC1/AC2-VL-5 — the FLAT form of this version-less slug is the wrong bucket and must still block"; failures=$((failures+1)); }
  _sr_tol="$(printf '%s\n' "?? release/releases/notes/_unversioned/${_sr_vl_other}_RELEASE_NOTES.md" | filter_tolerated_worktree_state)"
  [[ -n "$_sr_tol" ]] || { echo "FAIL: AC1/AC2-VL-5 — another version-less release's note must still block (tolerance is scoped to THIS release)"; failures=$((failures+1)); }

  # VL-6 — the §3.2 lint's version-scoping needle must name the file that exists.
  # A flat needle can never match a version-less finding, so a real content finding
  # would be mis-classified as another version's legacy debt and NOT block the close.
  # Same LN_EXIT/LN_OUT stub Test 5.5 uses, planted under THIS block's sandbox root
  # so the phase reaches its grep-scoping logic instead of the missing-tooling FAIL.
  /bin/mkdir -p "$_sr_tmp/core/deploy/tools"
  /bin/cat > "$_sr_tmp/core/deploy/tools/lint_release_corpus.py" <<'VLSTUB'
import os, sys
sys.stdout.write(os.environ.get("LN_OUT", ""))
sys.exit(int(os.environ.get("LN_EXIT", "0")))
VLSTUB
  local _sr_vlneedle; _sr_vlneedle="release/releases/$(notes_rel_path)"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  if LN_EXIT=1 LN_OUT="NOTE-6A-MISSING: ${_sr_vlneedle} lacks section" phase_lint_release_notes >/dev/null 2>&1; then
    echo "FAIL: AC1/AC2-VL-6 — a §3.2 finding naming THIS version-less release's note must BLOCK the close"; failures=$((failures+1))
  fi
  [[ "$(get_phase lint_release_notes | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: AC1/AC2-VL-6 — the this-release finding must mark the phase FAIL, got '$(get_phase lint_release_notes)'"; failures=$((failures+1)); }
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  LN_EXIT=1 LN_OUT="NOTE-6A-MISSING: release/releases/notes/_unversioned/${_sr_vl_other}_RELEASE_NOTES.md lacks section" phase_lint_release_notes >/dev/null 2>&1 || { echo "FAIL: AC1/AC2-VL-6 — another release's finding must NOT block (audit-baseline control)"; failures=$((failures+1)); }
  [[ "$(get_phase lint_release_notes | /usr/bin/cut -d'|' -f1)" == "PASS" ]] || { echo "FAIL: AC1/AC2-VL-6 — the other-release-only finding must mark PASS (audit-baseline), got '$(get_phase lint_release_notes)'"; failures=$((failures+1)); }

  # VL-7 — the commit stage list must name the produced note. Staging is `[[ -f ]]`
  # guarded, so a disagreeing path does not error: it silently stages nothing and
  # the release note never reaches the chore commit.
  local _sr_vlstage; _sr_vlstage="$(build_chore_pr_body 2>/dev/null | /usr/bin/grep -cF "release/releases/$(notes_rel_path) | NEW" || true)"
  [[ "$_sr_vlstage" -eq 1 ]] || { echo "FAIL: AC1/AC2-VL-7 — the chore-PR File Change Matrix must name the version-less note's real path (matches=$_sr_vlstage)"; failures=$((failures+1)); }

  # VL-ORDER — the reachability property, ASSERTED rather than documented.
  # Every VL-* arm above drives an is_version_less branch directly, which is only
  # possible because main dispatches --self-test BEFORE the canonical-version
  # gate. Move the dispatch below the gate and all of them become unreachable
  # while still "passing" in the sense that they were never run. This arm reads
  # both lines out of this file's own text and fails if the ordering inverts, so
  # the REACHABILITY note above is_version_less cites an executable invariant
  # instead of a line number. Both needles are column-1 anchored, so the indented
  # copies inside this arm cannot match themselves.
  local _vlo_dispatch _vlo_gate
  _vlo_dispatch="$(/usr/bin/grep -nE '^\[\[ "\$SELF_TEST" -eq 1 \]\] && self_test$' "${BASH_SOURCE[0]}" | /usr/bin/cut -d: -f1 || true)"
  _vlo_gate="$(/usr/bin/grep -nE '^validate_version "\$VERSION" \|\| die' "${BASH_SOURCE[0]}" | /usr/bin/cut -d: -f1 || true)"
  if ! [[ "$_vlo_dispatch" =~ ^[0-9]+$ && "$_vlo_gate" =~ ^[0-9]+$ ]]; then
    echo "FAIL: VL-ORDER anti-vacuity — a needle did not resolve to exactly one top-level line (dispatch='$_vlo_dispatch' gate='$_vlo_gate'); the arm would otherwise pass without asserting anything"; failures=$((failures+1))
  elif [[ "$_vlo_dispatch" -ge "$_vlo_gate" ]]; then
    echo "FAIL: VL-ORDER — the --self-test dispatch (line $_vlo_dispatch) must PRECEDE the canonical-version gate (line $_vlo_gate); below it, --self-test dies on the gate and every is_version_less branch becomes unreachable and untestable"; failures=$((failures+1))
  fi

  VERSION="v9.99"

  # (g) PL-* — the PLAN-PATH RESOLVER (#4706). Every arm drives the REAL
  # plan_rel_path() against a sandboxed $RELEASE_PLANS_DIR, so nothing here reads
  # the live corpus. The block exists because the three emitters below used to
  # retype release/releases/plans/<VERSION>_RELEASE_PLAN.md — a form matching NONE
  # of the homes the corpus actually uses — and every close-out therefore minted a
  # links.plan pointer that dangled on arrival, with no test that could have seen
  # it. These are that test.
  local _pl_saved_slug2="$STATE_MILESTONE_SLUG"
  /bin/mkdir -p "$RELEASE_PLANS_DIR/v9" "$RELEASE_PLANS_DIR/_unversioned"
  local _pl_root="plans"   # $RELEASE_PLANS_DIR with $REPO_ROOT/ stripped, in-sandbox

  # PL-0 — SPECIFICITY, and the arm that makes every other one mean something.
  # With no plan file anywhere the resolver must return NON-ZERO and print NOTHING.
  # Without this a resolver that always echoed a path would pass PL-1..PL-5.
  VERSION="v9.97"; STATE_MILESTONE_SLUG="pl-selftest-slug"
  local _pl_out _pl_rc=0
  _pl_out="$(plan_rel_path)" || _pl_rc=$?
  [[ "$_pl_rc" -ne 0 ]] || { echo "FAIL: PL-0 — with no plan file in the sandbox plan_rel_path() must return non-zero, got rc=0 and '$_pl_out'"; failures=$((failures+1)); }
  [[ -z "$_pl_out" ]] || { echo "FAIL: PL-0 — an unresolved plan_rel_path() must print NOTHING (a path printed alongside a non-zero rc is exactly the dangling pointer this card removes), got '$_pl_out'"; failures=$((failures+1)); }

  # PL-1 — rule 1, the ADR-092 claim-time home: nested + version-named.
  /usr/bin/touch "$RELEASE_PLANS_DIR/v9/v9.97_RELEASE_PLAN.md"
  [[ "$(plan_rel_path)" == "${_pl_root}/v9/v9.97_RELEASE_PLAN.md" ]] || { echo "FAIL: PL-1 — rule 1 (plans/v<MAJOR>/<VERSION>) must resolve, got '$(plan_rel_path)'"; failures=$((failures+1)); }

  # PL-2 — PRECEDENCE, asserted rather than incidental. With a flat slug-named copy
  # ALSO present the nested claim-time home must still win, so a stale flat residue
  # cannot capture a correctly-claimed release.
  /usr/bin/touch "$RELEASE_PLANS_DIR/pl-selftest-slug_RELEASE_PLAN.md"
  [[ "$(plan_rel_path)" == "${_pl_root}/v9/v9.97_RELEASE_PLAN.md" ]] || { echo "FAIL: PL-2 — rule 1 must take precedence over a lingering flat slug-named copy, got '$(plan_rel_path)'"; failures=$((failures+1)); }

  # PL-3 — rule 0, pre-claim / in-flight: flat + slug-named. Same fixture as PL-2
  # with the nested home removed, so PL-2 and PL-3 differ in exactly one property.
  /bin/rm -f "$RELEASE_PLANS_DIR/v9/v9.97_RELEASE_PLAN.md"
  [[ "$(plan_rel_path)" == "${_pl_root}/pl-selftest-slug_RELEASE_PLAN.md" ]] || { echo "FAIL: PL-3 — rule 0 (flat slug-primary, pre-claim) must resolve, got '$(plan_rel_path)'"; failures=$((failures+1)); }

  # PL-4 — the NESTED SLUG-NAMED form. This is the candidate a three-valued reading
  # of the disposition rule omits, and the corpus carries plans in exactly this shape
  # (nested under a major-version folder, basename = the milestone slug). Omit it and
  # the resolver falls through to a wrong answer or to none at all.
  /bin/rm -f "$RELEASE_PLANS_DIR/pl-selftest-slug_RELEASE_PLAN.md"
  /usr/bin/touch "$RELEASE_PLANS_DIR/v9/pl-selftest-slug_RELEASE_PLAN.md"
  [[ "$(plan_rel_path)" == "${_pl_root}/v9/pl-selftest-slug_RELEASE_PLAN.md" ]] || { echo "FAIL: PL-4 — the nested slug-named form (plans/v<MAJOR>/<SLUG>) must resolve; a resolver blind to it turns a real corpus shape into a dangling pointer, got '$(plan_rel_path)'"; failures=$((failures+1)); }
  /bin/rm -f "$RELEASE_PLANS_DIR/v9/pl-selftest-slug_RELEASE_PLAN.md"

  # PL-5 — rule 2, version-less: _unversioned/. Anti-vacuity twin asserts the answer
  # is NOT the flat form, which is what the pre-fix emitters produced here.
  VERSION="77-selftest-version-less-theme"; STATE_MILESTONE_SLUG="77-selftest-version-less-theme"
  is_version_less || { echo "FAIL: PL-5 setup — the fixture must classify as version-less or the arm tests nothing"; failures=$((failures+1)); }
  /usr/bin/touch "$RELEASE_PLANS_DIR/_unversioned/77-selftest-version-less-theme_RELEASE_PLAN.md"
  [[ "$(plan_rel_path)" == "${_pl_root}/_unversioned/77-selftest-version-less-theme_RELEASE_PLAN.md" ]] || { echo "FAIL: PL-5 — rule 2 (plans/_unversioned/<SLUG>) must resolve for a version-less release, got '$(plan_rel_path)'"; failures=$((failures+1)); }
  [[ "$(plan_rel_path)" != "${_pl_root}/77-selftest-version-less-theme_RELEASE_PLAN.md" ]] || { echo "FAIL: PL-5 anti-vacuity — a version-less plan must NOT resolve to the FLAT form"; failures=$((failures+1)); }

  # PL-6 — ANNOTATE AND CONTINUE at the note producer. With no plan resolvable the
  # scaffold must STILL be written (no new abort path in a phase that has never had
  # one) and its links.plan value must carry the loud marker, so the corpus lint
  # blocks the close one phase later instead of a mid-pipeline exit doing it.
  VERSION="v9.96"; STATE_MILESTONE_SLUG="pl-noplan-slug"
  MODE="apply"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  local _pl_prc=0
  phase_scaffold_release_notes >/dev/null 2>&1 || _pl_prc=$?
  [[ "$_pl_prc" -eq 0 ]] || { echo "FAIL: PL-6 — an unresolvable plan must NOT introduce a failure path into phase_scaffold_release_notes (it returns 0 on every branch today, and nine ledger-mutating phases precede it), got rc=$_pl_prc"; failures=$((failures+1)); }
  local _pl_note="$RELEASE_NOTES_DIR/v9.96_RELEASE_NOTES.md"
  if [[ ! -f "$_pl_note" ]]; then
    echo "FAIL: PL-6 — the note must still be written when the plan does not resolve; refusing to write is the abort path this design deliberately does not add"; failures=$((failures+1))
  else
    /usr/bin/grep -qF 'plan: plans/v9/v9.96_RELEASE_PLAN.md (unresolved at close-out)' "$_pl_note" || { echo "FAIL: PL-6 — the unresolved pointer must name the EXPECTED home and carry the '(unresolved at close-out)' marker; got: $(/usr/bin/grep -F 'plan:' "$_pl_note" || true)"; failures=$((failures+1)); }
  fi

  # PL-7 — DRY-RUN must not fail, and must write nothing. The no-regression arm for
  # the behaviour change: a review-gate dry run against a not-yet-claimed plan is the
  # normal case, not an error.
  /bin/rm -f "$_pl_note"
  MODE="dry-run"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  local _pl_drc=0
  phase_scaffold_release_notes >/dev/null 2>&1 || _pl_drc=$?
  [[ "$_pl_drc" -eq 0 ]] || { echo "FAIL: PL-7 — --dry-run must never fail on an unresolvable plan, got rc=$_pl_drc"; failures=$((failures+1)); }
  [[ ! -f "$_pl_note" ]] || { echo "FAIL: PL-7 — --dry-run must write no note"; failures=$((failures+1)); }
  MODE="apply"

  # PL-8 — ALL THREE EMITTERS AGREE. The direct analogue of VL-0 for the plans
  # corpus, and the arm that makes "3 sites, 1 resolver" an ASSERTED property rather
  # than a convention someone has to keep. The scaffolded note's frontmatter and the
  # chore-PR body's Cross-references line must carry the SAME string, and that string
  # must be the resolved one — the anti-vacuity limb, because two sites agreeing on a
  # wrong value would otherwise pass.
  VERSION="v9.95"; STATE_MILESTONE_SLUG="pl-agree-slug"
  /usr/bin/touch "$RELEASE_PLANS_DIR/v9/v9.95_RELEASE_PLAN.md"
  local _pl_expect="${_pl_root}/v9/v9.95_RELEASE_PLAN.md"
  [[ "$(plan_rel_path)" == "$_pl_expect" ]] || { echo "FAIL: PL-8 setup — the fixture plan must resolve, got '$(plan_rel_path)'"; failures=$((failures+1)); }
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_scaffold_release_notes >/dev/null 2>&1 || true
  local _pl_note2="$RELEASE_NOTES_DIR/v9.95_RELEASE_NOTES.md"
  /usr/bin/grep -qF "plan: ${_pl_expect}" "$_pl_note2" || { echo "FAIL: PL-8 — site 1 (note frontmatter) must emit the RESOLVED path '${_pl_expect}'; got: $(/usr/bin/grep -F 'plan:' "$_pl_note2" 2>/dev/null || echo '<no note>')"; failures=$((failures+1)); }
  # `-- ` before the pattern is load-bearing: the needle begins with a hyphen (it is
  # a markdown list item) and grep would otherwise parse it as an option bundle.
  local _pl_prbody; _pl_prbody="$(build_chore_pr_body 2>/dev/null | /usr/bin/grep -cF -- "- Release plan: ${_pl_expect}" || true)"
  [[ "$_pl_prbody" -eq 1 ]] || { echo "FAIL: PL-8 — site 2 (chore-PR body) must name the SAME resolved path as site 1 (matches=$_pl_prbody); this body becomes a public GitHub PR no in-repo sweep can correct"; failures=$((failures+1)); }
  [[ -n "$_pl_expect" ]] || { echo "FAIL: PL-8 anti-vacuity — the agreed string must be non-empty; two sites agreeing on nothing is not agreement"; failures=$((failures+1)); }

  # PL-9 — THE CALLER'S PREDICATE REACHES THE FINDING. "Already blocking" is a
  # property of a caller PLUS a predicate, never of a function. phase_lint_release_notes
  # scopes the lint to this release by grepping the output for THIS NOTE's
  # repo-root-relative path; a links.plan finding that named only the PLANS path would
  # miss that needle and take the caller's explicit "no finding for this version" PASS
  # branch — blocking in name, fail-open in fact. This arm drives the REAL phase with
  # the REAL finding shape and asserts it BLOCKS, then proves with two controls that
  # the arm discriminates rather than blocking on everything.
  local _pl_needle; _pl_needle="release/releases/$(notes_rel_path)"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  if LN_EXIT=1 LN_OUT="NOTE-PLAN-LINK-UNRESOLVED: ${_pl_needle} links.plan -> 'release/releases/plans/v9/nope_RELEASE_PLAN.md' does not resolve to an existing file under release/releases/plans/" phase_lint_release_notes >/dev/null 2>&1; then
    echo "FAIL: PL-9 — a links.plan finding naming THIS release's note MUST block the close; it did not, which means the finding text and the caller's version-scoping needle have drifted apart"; failures=$((failures+1))
  fi
  [[ "$(get_phase lint_release_notes | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: PL-9 — the blocking finding must mark the phase FAIL, got '$(get_phase lint_release_notes)'"; failures=$((failures+1)); }
  # PL-9a control — the SAME finding class for a DIFFERENT release must NOT block
  # (audit-baseline discipline), so PL-9 is not passing on a caller that blocks on
  # everything.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  LN_EXIT=1 LN_OUT="NOTE-PLAN-LINK-UNRESOLVED: release/releases/notes/v9.01_RELEASE_NOTES.md links.plan -> 'release/releases/plans/v9/other_RELEASE_PLAN.md' does not resolve" phase_lint_release_notes >/dev/null 2>&1 || { echo "FAIL: PL-9a control — another release's links.plan finding must NOT block this close"; failures=$((failures+1)); }
  # PL-9b control — a finding naming ONLY the PLANS path is exactly the fail-open
  # shape this arm exists to forbid: the caller cannot see it. Asserted as a
  # PROPERTY OF THE CALLER, so if someone later reshapes the finding to lead with the
  # plans path, PL-9 goes red and this control explains why.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  LN_EXIT=1 LN_OUT="NOTE-PLAN-LINK-UNRESOLVED: release/releases/plans/v9/v9.95_RELEASE_PLAN.md does not resolve" phase_lint_release_notes >/dev/null 2>&1 || { echo "FAIL: PL-9b control — a plans-path-only finding does not match the caller's note-path needle, so the caller MUST take its PASS branch; it did not, which means the needle changed"; failures=$((failures+1)); }

  # PL-10 — END TO END: the REAL linter's finding, fed to the REAL caller.
  # PL-9 pins the caller's behaviour given a finding SHAPE, but a hand-written
  # LN_OUT cannot notice if the linter later stops producing that shape. This arm
  # closes that seam: it builds a layout-faithful sandbox (release/releases/... so
  # the linter's repo-root-relative rendering is byte-identical to production),
  # runs the REAL check_note_content() over a v4-era note whose links.plan names an
  # absent file, and pipes the REAL finding into the REAL phase_lint_release_notes.
  # Emitter and predicate are therefore verified as one composed mechanism rather
  # than as two independently-plausible halves.
  local _pl_e2e; _pl_e2e="$(/usr/bin/mktemp -d -t planlink-e2e.XXXXXX)"
  /bin/mkdir -p "$_pl_e2e/release/releases/notes" "$_pl_e2e/release/releases/plans/v9"
  /bin/cat > "$_pl_e2e/release/releases/notes/v9.94_RELEASE_NOTES.md" <<'E2E'
---
version: v9.94
date: 2026-08-15
type: note
issues: []
pr: "#1"
links:
  plan: release/releases/plans/v9/v9.94_RELEASE_PLAN.md
  log_anchor: "#x"
---

# H

## What changed for everyone using the platform

- **A bullet.** *Why it matters:* it matters.
E2E
  local _pl_e2eout
  _pl_e2eout="$(/usr/bin/python3 - "$LINT_RELEASE_CORPUS" "$_pl_e2e" <<'PY' 2>&1 || true
import importlib.util, pathlib, sys
lint_path, root = sys.argv[1], pathlib.Path(sys.argv[2])
spec = importlib.util.spec_from_file_location("lint_rc_e2e", lint_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
mod.WORKSPACE_ROOT = root
mod.NOTES_DIR = root / "release" / "releases" / "notes"
mod.PLANS_DIR = root / "release" / "releases" / "plans"
for finding in mod.check_note_content():
    print(finding)
PY
)"
  /usr/bin/grep -qF 'NOTE-PLAN-LINK-UNRESOLVED' <<<"$_pl_e2eout" || { echo "FAIL: PL-10 setup — the real linter must emit NOTE-PLAN-LINK-UNRESOLVED for a v4-era note whose plan is absent; got: $_pl_e2eout"; failures=$((failures+1)); }
  # The binding assertion: drive the REAL caller with the REAL output.
  local _pl_savedv="$VERSION"
  VERSION="v9.94"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  if LN_EXIT=1 LN_OUT="$_pl_e2eout" phase_lint_release_notes >/dev/null 2>&1; then
    echo "FAIL: PL-10 — the linter's REAL links.plan finding must reach phase_lint_release_notes' version-scoping needle and BLOCK the close. It did not, which means the finding no longer carries this note's repo-root-relative path and the gate is fail-open. Finding was: $_pl_e2eout"; failures=$((failures+1))
  fi
  [[ "$(get_phase lint_release_notes | /usr/bin/cut -d'|' -f1)" == "FAIL" ]] || { echo "FAIL: PL-10 — the composed emitter+caller must mark the phase FAIL, got '$(get_phase lint_release_notes)'"; failures=$((failures+1)); }
  VERSION="$_pl_savedv"
  /bin/rm -rf "$_pl_e2e" 2>/dev/null || true

  VERSION="v9.99"; STATE_MILESTONE_SLUG="$_pl_saved_slug2"

  /bin/rm -rf "$_sr_tmp" 2>/dev/null || true
  REPO_ROOT="$_sr_saved_root"; MODE="$_sr_saved_mode"; VERSION="$_sr_saved_version"
  RELEASE_NOTES_DIR="$_sr_saved_notesdir"; RELEASE_DIGEST="$_sr_saved_digest"
  RELEASE_PLANS_DIR="$_sr_saved_plansdir"
  PR_NUMBER="$_sr_saved_pr"; STATE_MILESTONE_SLUG="$_sr_saved_slug"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # Test 13: phase_sync_primary_checkout (AC7) — offline, hermetic, no network and no
  # credential. Builds REAL local git repos (a bare "origin", a "primary" clone) and
  # drives the phase via the PRIMARY_CHECKOUT seam, so the assertions are about
  # observable repo state (did the primary's HEAD actually move?) rather than exit 0.
  local _sp_saved_mode="$MODE" _sp_saved_primary="${PRIMARY_CHECKOUT:-}"
  if [[ -x "$GIT" ]]; then
    local _sp_tmp; _sp_tmp="$(/usr/bin/mktemp -d -t syncprimary-selftest.XXXXXX)"
    (
      set +e
      # init.defaultBranch is pinned: macOS ships a system gitconfig setting it to
      # "main", while git's built-in default (what a Linux CI runner uses) is
      # "master". Left ambient, the bare repo's HEAD would point at an unborn branch
      # in CI and the clone below would come up with no branch checked out — the
      # fixture would silently test something different there than here.
      $GIT -c init.defaultBranch=main init -q --bare "$_sp_tmp/origin.git" 2>/dev/null
      $GIT clone -q "$_sp_tmp/origin.git" "$_sp_tmp/seed" 2>/dev/null
      $GIT -C "$_sp_tmp/seed" -c user.email=t@t -c user.name=t checkout -q -b main 2>/dev/null
      /usr/bin/printf 'one\n' > "$_sp_tmp/seed/f.txt"
      $GIT -C "$_sp_tmp/seed" add f.txt 2>/dev/null
      $GIT -C "$_sp_tmp/seed" -c commit.gpgsign=false -c user.email=t@t -c user.name=t commit -q -m c1 2>/dev/null
      $GIT -C "$_sp_tmp/seed" push -q origin main 2>/dev/null
    ) >/dev/null 2>&1 || true
    if [[ -d "$_sp_tmp/origin.git" ]]; then
      $GIT clone -q "$_sp_tmp/origin.git" "$_sp_tmp/primary" >/dev/null 2>&1
      # Advance origin one commit so the primary is genuinely BEHIND.
      (
        set +e
        /usr/bin/printf 'two\n' >> "$_sp_tmp/seed/f.txt"
        $GIT -C "$_sp_tmp/seed" add f.txt
        $GIT -C "$_sp_tmp/seed" -c commit.gpgsign=false -c user.email=t@t -c user.name=t commit -q -m c2
        $GIT -C "$_sp_tmp/seed" push -q origin main
      ) >/dev/null 2>&1 || true
      local _sp_before _sp_after _sp_target
      _sp_before="$($GIT -C "$_sp_tmp/primary" rev-parse HEAD 2>/dev/null || echo x)"
      _sp_target="$($GIT -C "$_sp_tmp/seed" rev-parse HEAD 2>/dev/null || echo y)"

      # (a) primary on main and behind → PASS, and HEAD actually moves to origin/main.
      MODE="apply"; PRIMARY_CHECKOUT="$_sp_tmp/primary"
      PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
      phase_sync_primary_checkout >/dev/null 2>&1
      _sp_after="$($GIT -C "$_sp_tmp/primary" rev-parse HEAD 2>/dev/null || echo z)"
      [[ "$(get_phase sync_primary_checkout | /usr/bin/cut -d'|' -f1)" == "PASS" ]] || { echo "FAIL: AC7-a — a behind-but-fast-forwardable primary on main must PASS, got '$(get_phase sync_primary_checkout)'"; failures=$((failures+1)); }
      [[ "$_sp_after" == "$_sp_target" ]] || { echo "FAIL: AC7-a — the primary must actually be fast-forwarded to origin/main (before=$_sp_before after=$_sp_after target=$_sp_target)"; failures=$((failures+1)); }
      [[ "$_sp_after" != "$_sp_before" ]] || { echo "FAIL: AC7-a — the primary HEAD did not move; a no-op cannot evidence a sync"; failures=$((failures+1)); }

      # (b) primary NOT on main → SKIPPED, and HEAD must NOT move. Without this the
      # phase would happily fast-forward an unrelated branch to origin/main.
      $GIT -C "$_sp_tmp/primary" checkout -q -b sidebranch "$_sp_before" >/dev/null 2>&1
      local _sp_side_before; _sp_side_before="$($GIT -C "$_sp_tmp/primary" rev-parse HEAD 2>/dev/null || echo x)"
      PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
      phase_sync_primary_checkout >/dev/null 2>&1
      [[ "$(get_phase sync_primary_checkout | /usr/bin/cut -d'|' -f1)" == "SKIPPED" ]] || { echo "FAIL: AC7-b — a primary on a non-main branch must SKIP, got '$(get_phase sync_primary_checkout)'"; failures=$((failures+1)); }
      [[ "$($GIT -C "$_sp_tmp/primary" rev-parse HEAD 2>/dev/null)" == "$_sp_side_before" ]] || { echo "FAIL: AC7-b — a non-main primary must NOT be moved"; failures=$((failures+1)); }

      # (c) primary absent → SKIPPED, exit 0 (hermeticity; this is the CI path).
      PRIMARY_CHECKOUT="$_sp_tmp/does-not-exist"
      PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
      phase_sync_primary_checkout >/dev/null 2>&1 || { echo "FAIL: AC7-c — an absent primary must be a clean no-op (exit 0), not an error"; failures=$((failures+1)); }
      [[ "$(get_phase sync_primary_checkout | /usr/bin/cut -d'|' -f1)" == "SKIPPED" ]] || { echo "FAIL: AC7-c — an absent primary must mark SKIPPED, got '$(get_phase sync_primary_checkout)'"; failures=$((failures+1)); }

      # (d) dry-run → no mutation.
      $GIT -C "$_sp_tmp/primary" checkout -q main >/dev/null 2>&1
      $GIT -C "$_sp_tmp/primary" reset -q --hard "$_sp_before" >/dev/null 2>&1
      MODE="dry-run"; PRIMARY_CHECKOUT="$_sp_tmp/primary"
      PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
      phase_sync_primary_checkout >/dev/null 2>&1
      [[ "$(get_phase sync_primary_checkout | /usr/bin/cut -d'|' -f1)" == "DRY-RUN" ]] || { echo "FAIL: AC7-d — dry-run must preview, got '$(get_phase sync_primary_checkout)'"; failures=$((failures+1)); }
      [[ "$($GIT -C "$_sp_tmp/primary" rev-parse HEAD 2>/dev/null)" == "$_sp_before" ]] || { echo "FAIL: AC7-d — dry-run must NOT move the primary"; failures=$((failures+1)); }

      # (e) STRUCTURAL guard on the phase source: an ALLOWLIST of the git subcommands
      # it may invoke, not a denylist of forbidden words (a denylist false-fires on the
      # phase's own name and on its prose). Every `-C` git call must be one of
      # {worktree, rev-parse, fetch, merge}; anything else — reset, stash, checkout,
      # push — fails here. This is the assertion that keeps a future edit from quietly
      # escalating a refused fast-forward into a force.
      local _sp_verbs _sp_bad
      _sp_verbs="$(/usr/bin/sed -n '/^phase_sync_primary_checkout() {/,/^}/p' "$SCRIPT_DIR/$(/usr/bin/basename "${BASH_SOURCE[0]}")" \
                   | /usr/bin/grep -oE '(\$GIT|git_net) -C "[^"]+" [a-z-]+' \
                   | /usr/bin/awk '{print $NF}' | /usr/bin/sort -u)"
      if [[ -z "$_sp_verbs" ]]; then
        echo "FAIL: AC7-e — could not extract any git subcommand from phase_sync_primary_checkout; the structural guard would pass vacuously"; failures=$((failures+1))
      fi
      _sp_bad="$(/usr/bin/printf '%s\n' "$_sp_verbs" | /usr/bin/grep -vE '^(worktree|rev-parse|fetch|merge)$' || true)"
      [[ -z "$_sp_bad" ]] || { echo "FAIL: AC7-e — phase_sync_primary_checkout may only run {worktree, rev-parse, fetch, merge} against a checkout; found: $(echo "$_sp_bad" | /usr/bin/tr '\n' ' ') (git-workflow.md § Primary Checkout Discipline forbids reset/stash/checkout/push on the primary)"; failures=$((failures+1)); }
      # And it must address the primary with `git -C`, never by changing directory.
      if /usr/bin/sed -n '/^phase_sync_primary_checkout() {/,/^}/p' "$SCRIPT_DIR/$(/usr/bin/basename "${BASH_SOURCE[0]}")" \
         | /usr/bin/grep -vE '^[[:space:]]*#' | /usr/bin/grep -qE '(^|[;&|[:space:]])cd[[:space:]]'; then
        echo "FAIL: AC7-e — phase_sync_primary_checkout must never cd; address the primary with git -C"; failures=$((failures+1))
      fi
    else
      echo "  (skipped AC7 sync-primary self-test — could not build the local git fixture)" >&2
    fi
    /bin/rm -rf "$_sp_tmp" 2>/dev/null || true
  else
    echo "  (skipped AC7 sync-primary self-test — git not executable at $GIT)" >&2
  fi
  MODE="$_sp_saved_mode"; PRIMARY_CHECKOUT="$_sp_saved_primary"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # Test 14: release-anchor hygiene (AC4 + AC5). Offline, hermetic, CREDENTIAL-FREE —
  # the CI smoke job runs --self-test with no gh token and no network, so the AC4 half
  # is driven with FIXTURE tag/release lists and the AC5 half against a real local git
  # repo. Neither touches gh.
  #
  # The anti-vacuity controls are the point of this block: a guard that cannot fail is
  # the exact defect this release exists to eliminate, and a count-based parity check
  # is green today on a corpus that is genuinely divergent.
  local _ah_tmp; _ah_tmp="$(/usr/bin/mktemp -d -t anchorhygiene-selftest.XXXXXX)"

  # ---- AC4: set parity, fixture-driven ----
  # Baseline: the only divergences are the four recorded exemptions -> clean.
  /bin/cat > "$_ah_tmp/ann" <<'ANN'
v3.31
v3.65.1
v9.01
v9.02
ANN
  /bin/cat > "$_ah_tmp/rel" <<'REL'
v3.28
v3.29
v9.01
v9.02
REL
  local _ah_out
  _ah_out="$(anchor_parity_violations "$_ah_tmp/ann" "$_ah_tmp/rel")"
  [[ -z "$_ah_out" ]] || { echo "FAIL: AC4-a — the four RECORDED divergences must be exempt, got: $_ah_out"; failures=$((failures+1)); }

  # (b) ANTI-VACUITY CONTROL — inject a fifth, unrecorded divergence. Without this the
  # whole AC4 assertion could be satisfied by a guard that never fires.
  /usr/bin/printf 'v9.03\n' >> "$_ah_tmp/ann"; /usr/bin/sort -o "$_ah_tmp/ann" "$_ah_tmp/ann"
  _ah_out="$(anchor_parity_violations "$_ah_tmp/ann" "$_ah_tmp/rel")"
  /usr/bin/printf '%s' "$_ah_out" | /usr/bin/grep -qF 'MISSING-RELEASE v9.03' || { echo "FAIL: AC4-b — a NEW annotated-tag-without-Release divergence must be reported, got: $_ah_out"; failures=$((failures+1)); }

  # (c) the OTHER direction — a published Release with no annotated tag.
  /usr/bin/printf 'v9.04\n' >> "$_ah_tmp/rel"; /usr/bin/sort -o "$_ah_tmp/rel" "$_ah_tmp/rel"
  _ah_out="$(anchor_parity_violations "$_ah_tmp/ann" "$_ah_tmp/rel")"
  /usr/bin/printf '%s' "$_ah_out" | /usr/bin/grep -qF 'MISSING-ANNOTATED-TAG v9.04' || { echo "FAIL: AC4-c — a Release-without-annotated-tag divergence must be reported, got: $_ah_out"; failures=$((failures+1)); }

  # (d) COUNT-PARITY CONTROL — this is the false negative AC4 exists to kill. The two
  # lists below have EQUAL LENGTH and UNEQUAL MEMBERSHIP, exactly like the live corpus
  # (143 == 143, sets divergent). A count comparison grades this PASS; the set guard
  # must not.
  /bin/cat > "$_ah_tmp/ann_eq" <<'ANNEQ'
v9.10
v9.11
ANNEQ
  /bin/cat > "$_ah_tmp/rel_eq" <<'RELEQ'
v9.10
v9.12
RELEQ
  _ah_out="$(anchor_parity_violations "$_ah_tmp/ann_eq" "$_ah_tmp/rel_eq")"
  [[ -n "$_ah_out" ]] || { echo "FAIL: AC4-d — equal COUNTS with unequal SETS must still be reported; a count comparison is the exact false negative this guard replaces"; failures=$((failures+1)); }

  # ---- AC5: tagger identity, real local git repo ----
  if [[ -x "$GIT" ]]; then
    local _ah_repo="$_ah_tmp/repo"
    # Signing is disabled explicitly on every fixture command. An operator whose
    # global config sets tag.gpgsign/commit.gpgsign turns a BARE `git tag` into a
    # signed (therefore annotated) tag that then fails for want of a message — which
    # silently destroys the lightweight-tag fixture and leaves the objecttype
    # assertions passing against a tag that was never created. CI, with no global
    # config, would build a different fixture than a developer machine.
    local _ah_nosign=(-c tag.gpgsign=false -c commit.gpgsign=false)
    (
      set +e
      $GIT -c init.defaultBranch=main init -q "$_ah_repo"
      /usr/bin/printf 'x\n' > "$_ah_repo/f.txt"
      $GIT -C "$_ah_repo" add f.txt
      $GIT -C "$_ah_repo" "${_ah_nosign[@]}" -c user.email=a@users.noreply.github.com -c user.name=a commit -q -m c1
      # A conformant annotated tag (noreply tagger) — must NOT be flagged.
      $GIT -C "$_ah_repo" "${_ah_nosign[@]}" -c user.email=a@users.noreply.github.com -c user.name=a tag -a v9.50 -m t
      # A NON-conformant annotated tag (placeholder identity) — MUST be flagged.
      $GIT -C "$_ah_repo" "${_ah_nosign[@]}" -c user.email=t@t -c user.name=t tag -a v9.51 -m t
      # An EXEMPTED tag with the same defect — must NOT be flagged.
      $GIT -C "$_ah_repo" "${_ah_nosign[@]}" -c user.email=t@t -c user.name=t tag -a v3.80 -m t
      # A LIGHTWEIGHT tag. Written with update-ref, not `git tag`, so no signing or
      # tagging config can turn it into an annotated one behind our back.
      $GIT -C "$_ah_repo" update-ref refs/tags/v9.52 HEAD
    ) >/dev/null 2>&1 || true
    if [[ -d "$_ah_repo/.git" ]]; then
      # FIXTURE PRECONDITIONS. Assert the fixture is actually shaped the way the
      # assertions below assume — one annotated tag and one lightweight tag must both
      # exist. Without this, a fixture that fails to build leaves every "must NOT be
      # flagged" assertion passing for the wrong reason.
      local _ah_kinds
      _ah_kinds="$($GIT -C "$_ah_repo" for-each-ref refs/tags --format='%(objecttype) %(refname:short)' 2>/dev/null)"
      /usr/bin/printf '%s\n' "$_ah_kinds" | /usr/bin/grep -qx 'tag v9.51' || { echo "FAIL: AC5 fixture — annotated tag v9.51 was not created; the tagger assertions would be vacuous"; failures=$((failures+1)); }
      /usr/bin/printf '%s\n' "$_ah_kinds" | /usr/bin/grep -qx 'commit v9.52' || { echo "FAIL: AC5 fixture — LIGHTWEIGHT tag v9.52 was not created (objecttype must be 'commit'); the objecttype-filter assertions would be vacuous"; failures=$((failures+1)); }
      local _ah_tg; _ah_tg="$(tagger_hygiene_violations "$_ah_repo")"
      /usr/bin/printf '%s' "$_ah_tg" | /usr/bin/grep -qF 'v9.51' || { echo "FAIL: AC5-a — an annotated tag with a non-noreply tagger MUST be flagged, got: $_ah_tg"; failures=$((failures+1)); }
      if /usr/bin/printf '%s' "$_ah_tg" | /usr/bin/grep -qF 'v9.50'; then
        echo "FAIL: AC5-b — a conformant noreply-tagger tag must NOT be flagged"; failures=$((failures+1))
      fi
      if /usr/bin/printf '%s' "$_ah_tg" | /usr/bin/grep -qF 'v3.80'; then
        echo "FAIL: AC5-c — the RECORDED exemption must suppress its tag"; failures=$((failures+1))
      fi
      if /usr/bin/printf '%s' "$_ah_tg" | /usr/bin/grep -qF 'v9.52'; then
        echo "FAIL: AC5-d — a LIGHTWEIGHT tag has no tagger and must be excluded by the objecttype filter, not reported as a tagger violation"; failures=$((failures+1))
      fi
      # annotated_tags_of must list annotated tags only (the lightweight one is out).
      local _ah_at; _ah_at="$(annotated_tags_of "$_ah_repo")"
      /usr/bin/printf '%s\n' "$_ah_at" | /usr/bin/grep -qx 'v9.50' || { echo "FAIL: AC5-e — annotated_tags_of must list annotated tags"; failures=$((failures+1)); }
      if /usr/bin/printf '%s\n' "$_ah_at" | /usr/bin/grep -qx 'v9.52'; then
        echo "FAIL: AC5-e — annotated_tags_of must EXCLUDE lightweight tags (objecttype filter)"; failures=$((failures+1))
      fi
    else
      echo "  (skipped AC5 tagger self-test — could not build the local git fixture)" >&2
    fi
  else
    echo "  (skipped AC5 tagger self-test — git not executable at $GIT)" >&2
  fi

  # (f) STRUCTURAL — the parity guard must stay SET-based. `comm` is the mechanism;
  # a `wc -l` comparison of the two lists is the regression this guard replaces.
  declare -f anchor_parity_violations | /usr/bin/grep -qF 'comm' || { echo "FAIL: AC4-f — anchor_parity_violations must be comm-based (set difference), not a count comparison"; failures=$((failures+1)); }

  # (g) FAIL-OPEN CONTROL on the LEDGER-ROW-PARITY half (#3113 QA F-QA-3), driven
  # end-to-end through the SHIPPED phase rather than a re-implementation.
  #
  # The defect: a zero-match count exits 1 while still printing `0`, so appending a
  # fallback captured `0\n0`; `[[ "$_idx" -ne "$_log" ]]` then raised "syntax error
  # in expression", and a failed arithmetic test evaluates FALSE — so the PASS
  # branch was taken. A MISSING RELEASE_INDEX correctly FAILed, which is precisely
  # why the hole survived review: the obvious negative control exercised the one
  # input shape that still worked. The input that failed open is the WORSE one — a
  # ledger that is present and readable and simply has no rows.
  #
  # This half mechanizes CIAC-2, this release's own cross-issue acceptance
  # criterion, so a fail-open here grades the release's own thesis green for the
  # wrong reason.
  #
  # Hermetic and credential-free: REPO_ROOT is redirected at a bare temp dir (not a
  # git repo, so the tag probes return empty — which also exercises the third fixed
  # site, `_annn`) and GH at a nonexistent binary, so the network half
  # deterministically takes the SKIPPED branch. Safe for the CI smoke job.
  local _fo_saved_idx="$RELEASE_INDEX" _fo_saved_log="$RELEASE_LOG"
  local _fo_saved_root="$REPO_ROOT" _fo_saved_gh="$GH"
  local _fo_tmp; _fo_tmp="$(/usr/bin/mktemp -d -t failopen-selftest.XXXXXX)"
  REPO_ROOT="$_fo_tmp/norepo"; /bin/mkdir -p "$REPO_ROOT"
  GH="$_fo_tmp/no-such-gh"

  /bin/cat > "$_fo_tmp/LOG_3" <<'FOLOG'
| v9.60 | a-slug | 2026-01-01 | #1 | merge | v9.60 | VERIFIED | 2026-01-01 |
| v9.61 | b-slug | 2026-01-02 | #2 | merge | v9.61 | VERIFIED | 2026-01-02 |
| v9.62 | c-slug | 2026-01-03 | #3 | merge | v9.62 | VERIFIED | 2026-01-03 |
FOLOG
  /bin/cp "$_fo_tmp/LOG_3" "$_fo_tmp/IDX_3"
  : > "$_fo_tmp/IDX_EMPTY"   # PRESENT and readable, zero version rows

  # FIXTURE PRECONDITIONS — a fixture that failed to build must FAIL the suite, not
  # quietly satisfy the assertions below.
  [[ "$(grep_count -E '^\|[[:space:]]*v[0-9]' "$_fo_tmp/IDX_3")" == "3" ]] || { echo "FAIL: AC4-g fixture — the 3-row ledger fixture did not build; every assertion below would be vacuous"; failures=$((failures+1)); }
  [[ -f "$_fo_tmp/IDX_EMPTY" && ! -s "$_fo_tmp/IDX_EMPTY" ]] || { echo "FAIL: AC4-g fixture — the degenerate INDEX must exist and be EMPTY (an absent file tests the wrong branch)"; failures=$((failures+1)); }

  # (g1) THE DEFECT — a present-but-empty INDEX against a 3-row LOG is a real
  # 3-row breach and MUST be reported.
  local _fo_rc
  RELEASE_INDEX="$_fo_tmp/IDX_EMPTY"; RELEASE_LOG="$_fo_tmp/LOG_3"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _fo_rc=0; phase_assert_anchor_hygiene >/dev/null 2>&1 || _fo_rc=$?
  [[ "$_fo_rc" -ne 0 ]] || { echo "FAIL: AC4-g1 — a present-but-empty RELEASE_INDEX against a 3-row RELEASE_LOG must FAIL the phase (the #3113 F-QA-3 fail-open)"; failures=$((failures+1)); }
  [[ "$(get_phase assert_anchor_hygiene)" == FAIL\|* ]] || { echo "FAIL: AC4-g1 — phase must mark FAIL, got '$(get_phase assert_anchor_hygiene)'"; failures=$((failures+1)); }
  /usr/bin/printf '%s' "$(get_phase assert_anchor_hygiene)" | /usr/bin/grep -qF 'LEDGER-ROW-PARITY RELEASE_INDEX has 0 version rows, RELEASE_LOG has 3' || { echo "FAIL: AC4-g1 — the finding must name LEDGER-ROW-PARITY with SINGLE-INTEGER counts 0 and 3, got '$(get_phase assert_anchor_hygiene)'"; failures=$((failures+1)); }

  # (g2) CONTROL — equal, POPULATED ledgers must still pass, and the counts must
  # render as single integers (the two-line value mangled this status line too).
  RELEASE_INDEX="$_fo_tmp/IDX_3"; RELEASE_LOG="$_fo_tmp/LOG_3"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _fo_rc=0; phase_assert_anchor_hygiene >/dev/null 2>&1 || _fo_rc=$?
  [[ "$_fo_rc" -eq 0 ]] || { echo "FAIL: AC4-g2 — equal populated ledgers must PASS the phase, got rc=$_fo_rc"; failures=$((failures+1)); }
  /usr/bin/printf '%s' "$(get_phase assert_anchor_hygiene)" | /usr/bin/grep -qF 'INDEX 3 == LOG 3 rows' || { echo "FAIL: AC4-g2 — the clean detail must read 'INDEX 3 == LOG 3 rows', got '$(get_phase assert_anchor_hygiene)'"; failures=$((failures+1)); }

  # (g3) BOTH-EMPTY — two present-but-empty ledgers genuinely agree (0 == 0) and
  # must NOT be reported. Without this, "always FAIL on empty" would pass g1.
  RELEASE_INDEX="$_fo_tmp/IDX_EMPTY"; RELEASE_LOG="$_fo_tmp/IDX_EMPTY"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _fo_rc=0; phase_assert_anchor_hygiene >/dev/null 2>&1 || _fo_rc=$?
  [[ "$_fo_rc" -eq 0 ]] || { echo "FAIL: AC4-g3 — two empty ledgers agree at 0 == 0 and must NOT be reported as a breach"; failures=$((failures+1)); }
  /usr/bin/printf '%s' "$(get_phase assert_anchor_hygiene)" | /usr/bin/grep -qF 'INDEX 0 == LOG 0 rows' || { echo "FAIL: AC4-g3 — the detail must render single-integer zeroes 'INDEX 0 == LOG 0 rows' (the old idiom rendered '0\\n0'), got '$(get_phase assert_anchor_hygiene)'"; failures=$((failures+1)); }

  # (g4) REGRESSION FLOOR — a MISSING INDEX already FAILed before the fix and must
  # keep FAILing after it; the fix must not trade one hole for another.
  RELEASE_INDEX="$_fo_tmp/does-not-exist.md"; RELEASE_LOG="$_fo_tmp/LOG_3"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _fo_rc=0; phase_assert_anchor_hygiene >/dev/null 2>&1 || _fo_rc=$?
  [[ "$_fo_rc" -ne 0 ]] || { echo "FAIL: AC4-g4 — a MISSING RELEASE_INDEX must still FAIL (pre-fix behaviour preserved)"; failures=$((failures+1)); }

  # (g5) UNIT — grep_count's single-integer contract on every shape that made the
  # old idiom emit two lines, or none.
  local _fo_zero _fo_missing _fo_hit _fo_stdin
  _fo_zero="$(grep_count -E '^\|[[:space:]]*v[0-9]' "$_fo_tmp/IDX_EMPTY")"
  _fo_missing="$(grep_count -E 'anything' "$_fo_tmp/does-not-exist.md")"
  _fo_hit="$(grep_count -E '^\|[[:space:]]*v[0-9]' "$_fo_tmp/IDX_3")"
  _fo_stdin="$(grep_count . <<< "")"
  [[ "$_fo_zero" == "0" ]] || { echo "FAIL: AC4-g5 — grep_count on a present-but-empty file must be exactly '0', got $(/usr/bin/printf '%q' "$_fo_zero")"; failures=$((failures+1)); }
  [[ "$_fo_missing" == "0" ]] || { echo "FAIL: AC4-g5 — grep_count on a MISSING file must be exactly '0', got $(/usr/bin/printf '%q' "$_fo_missing")"; failures=$((failures+1)); }
  [[ "$_fo_hit" == "3" ]] || { echo "FAIL: AC4-g5 — grep_count must still count matches, expected 3, got $(/usr/bin/printf '%q' "$_fo_hit")"; failures=$((failures+1)); }
  [[ "$_fo_stdin" == "0" ]] || { echo "FAIL: AC4-g5 — grep_count over an empty stdin must be exactly '0' (the _annn call shape), got $(/usr/bin/printf '%q' "$_fo_stdin")"; failures=$((failures+1)); }

  # (g6) STRUCTURAL — reintroduction guard. `declare -f` emits the parsed body with
  # comments stripped, so this cannot be satisfied or defeated by prose.
  if declare -f phase_assert_anchor_hygiene | /usr/bin/grep -qE '\|\|[[:space:]]*echo[[:space:]]'; then
    echo "FAIL: AC4-g6 — the parity guard must not reintroduce an '|| echo' count fallback; it captures a two-line value and makes the arithmetic test evaluate FALSE"; failures=$((failures+1))
  fi
  # Whole-file sweep. The needle is ASSEMBLED at runtime so this probe cannot match
  # its own source line, and it requires the absolute-path call convention so the
  # explanatory prose above (which writes the idiom bare and split) cannot match it.
  local _fo_needle; _fo_needle="$(/usr/bin/printf '/usr/bin/gre%s -c[A-Za-z]*.*\\|\\|[[:space:]]*ech%s' 'p' 'o')"
  [[ "$(grep_count -E "$_fo_needle" "${BASH_SOURCE[0]}")" == "0" ]] || { echo "FAIL: AC4-g6 — a raw count with an appended '|| echo' fallback survives in this file; use grep_count"; failures=$((failures+1)); }
  # Anti-vacuity for the sweep itself: the needle must match a KNOWN-BAD line, or a
  # typo in it would make the whole-file probe pass by matching nothing. The control
  # line is ASSEMBLED at runtime for the same reason as the needle — writing the
  # defective idiom literally here would make the whole-file sweep flag this file.
  /usr/bin/printf 'x="$(/usr/bin/gre%s -cE foo bar || ech%s 0)"\n' 'p' 'o' > "$_fo_tmp/needle-control"
  [[ "$(grep_count -E "$_fo_needle" "$_fo_tmp/needle-control")" == "1" ]] || { echo "FAIL: AC4-g6 — the reintroduction needle does not match a known-bad line; the whole-file sweep is vacuous"; failures=$((failures+1)); }

  # (h) #5268 — PHASE 15.55 MODE-SCOPING of the LEDGER-ROW-PARITY limb. The limb is
  # structurally off-by-one at --dry-run on a first close: Stage 12 lands the LOG row
  # before close-out runs, while phase_append_release_index adds the INDEX row at 8.x
  # and writes nothing under --dry-run. Before this, the phase returned 1 there and
  # the runner exited 3 one phase-group short of Phase 16 — so fixing 9.5 alone only
  # MOVED the halt here.
  #
  # The scoping is a CONJUNCTION, not a mode-wide suppression, and these arms are
  # what make that difference observable: ONE positive (the bounded state) against
  # FOUR negatives that must each still report, plus an apply-side anti-vacuity arm
  # on the identical fixture and a sibling-limb arm proving --dry-run still FAILs on
  # a violation this scoping has no business masking.
  local _fo_saved_mode="$MODE" _fo_saved_version="$VERSION"

  # Ledger fixtures. LOG_3 carries v9.60/v9.61/v9.62; the close under test is v9.62.
  /usr/bin/printf '| v9.60 | a-slug | 2026-01-01 | #1 | merge | v9.60 | VERIFIED | 2026-01-01 |\n| v9.61 | b-slug | 2026-01-02 | #2 | merge | v9.61 | VERIFIED | 2026-01-02 |\n' > "$_fo_tmp/IDX_2"
  /usr/bin/printf '| v9.60 | a-slug | 2026-01-01 | #1 | merge | v9.60 | VERIFIED | 2026-01-01 |\n' > "$_fo_tmp/IDX_1"
  /usr/bin/printf '| v9.61 | b-slug | 2026-01-02 | #2 | merge | v9.61 | VERIFIED | 2026-01-02 |\n| v9.62 | c-slug | 2026-01-03 | #3 | merge | v9.62 | VERIFIED | 2026-01-03 |\n' > "$_fo_tmp/IDX_2_OTHER"
  /usr/bin/printf '| v9.60 | a-slug | 2026-01-01 | #1 | merge | v9.60 | VERIFIED | 2026-01-01 |\n| v9.61 | b-slug | 2026-01-02 | #2 | merge | v9.61 | VERIFIED | 2026-01-02 |\n' > "$_fo_tmp/LOG_2"

  # FIXTURE PRECONDITIONS — every arm below is a count comparison, so a fixture that
  # did not build at the declared magnitude would make the arms measure nothing.
  [[ "$(grep_count -E '^\|[[:space:]]*v[0-9]' "$_fo_tmp/IDX_2")" == "2" ]] || { echo "FAIL: h fixture — IDX_2 must carry exactly 2 version rows"; failures=$((failures+1)); }
  [[ "$(grep_count -E '^\|[[:space:]]*v[0-9]' "$_fo_tmp/IDX_1")" == "1" ]] || { echo "FAIL: h fixture — IDX_1 must carry exactly 1 version row"; failures=$((failures+1)); }
  [[ "$(grep_count -E '^\|[[:space:]]*v[0-9]' "$_fo_tmp/IDX_2_OTHER")" == "2" ]] || { echo "FAIL: h fixture — IDX_2_OTHER must carry exactly 2 version rows"; failures=$((failures+1)); }
  # ...and IDX_2_OTHER must differ from IDX_2 in WHICH row is missing, or the
  # this-version leg (h4) is indistinguishable from the gap-magnitude leg (h1).
  /usr/bin/grep -q 'v9\.62' "$_fo_tmp/IDX_2_OTHER" || { echo "FAIL: h fixture — IDX_2_OTHER must CONTAIN v9.62 (its missing row is v9.60's); otherwise h4 duplicates h1"; failures=$((failures+1)); }
  ! /usr/bin/grep -q 'v9\.62' "$_fo_tmp/IDX_2" || { echo "FAIL: h fixture — IDX_2 must OMIT v9.62 (the row this close would add)"; failures=$((failures+1)); }

  VERSION="v9.62"; RELEASE_LOG="$_fo_tmp/LOG_3"

  # (h1) THE BOUNDED STATE — one-row gap, and the missing row is this close's own.
  # Must PREDICT: rc 0, no LEDGER-ROW-PARITY finding, and a detail that reports the
  # two counts honestly rather than claiming they are equal.
  RELEASE_INDEX="$_fo_tmp/IDX_2"; MODE="dry-run"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _fo_rc=0; phase_assert_anchor_hygiene >/dev/null 2>&1 || _fo_rc=$?
  [[ "$_fo_rc" -eq 0 ]] || { echo "FAIL: h1 — under --dry-run a one-row INDEX gap that is THIS version's own row is this script's own no-op and must NOT halt the run, got rc=$_fo_rc"; failures=$((failures+1)); }
  local _fo_d; _fo_d="$(get_phase assert_anchor_hygiene)"
  /usr/bin/grep -qF 'LEDGER-ROW-PARITY PREDICTED' <<<"$_fo_d" || { echo "FAIL: h1 — the phase must RECORD the prediction rather than pass silently (a silent pass is indistinguishable from a deleted limb), got '$_fo_d'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'INDEX 2 vs LOG 3 rows' <<<"$_fo_d" || { echo "FAIL: h1 — the detail must report the two counts as they ARE; rendering 'INDEX 2 == LOG 3' would be a plausible-looking wrong row, got '$_fo_d'"; failures=$((failures+1)); }

  # (h2) ANTI-VACUITY — the IDENTICAL fixture at --apply must STILL FAIL and still
  # name both counts. rc=0 here would mean the limb was deleted, not mode-scoped.
  MODE="apply"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _fo_rc=0; phase_assert_anchor_hygiene >/dev/null 2>&1 || _fo_rc=$?
  [[ "$_fo_rc" -ne 0 ]] || { echo "FAIL: h2 anti-vacuity — the SAME one-row-gap fixture MUST still FAIL under --apply; rc=0 means the parity limb was gutted rather than mode-scoped"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'LEDGER-ROW-PARITY RELEASE_INDEX has 2 version rows, RELEASE_LOG has 3' <<<"$(get_phase assert_anchor_hygiene)" || { echo "FAIL: h2 — the --apply finding must be preserved verbatim, got '$(get_phase assert_anchor_hygiene)'"; failures=$((failures+1)); }

  # (h3) GAP MAGNITUDE — a TWO-row gap at --dry-run is corpus drift, not this close's
  # no-op, and must still FAIL. Without this, the scoping is a mode-wide suppression.
  RELEASE_INDEX="$_fo_tmp/IDX_1"; MODE="dry-run"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _fo_rc=0; phase_assert_anchor_hygiene >/dev/null 2>&1 || _fo_rc=$?
  [[ "$_fo_rc" -ne 0 ]] || { echo "FAIL: h3 — a TWO-row gap at --dry-run is real drift and must still FAIL; only a gap of exactly one is this close's own no-op"; failures=$((failures+1)); }

  # (h4) ROW IDENTITY — a ONE-row gap at --dry-run whose missing row is NOT this
  # version's must still FAIL. This is the arm a bare `gap == 1` test cannot pass,
  # and it is what makes h1 a statement about THIS close rather than about arithmetic.
  RELEASE_INDEX="$_fo_tmp/IDX_2_OTHER"; MODE="dry-run"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _fo_rc=0; phase_assert_anchor_hygiene >/dev/null 2>&1 || _fo_rc=$?
  [[ "$_fo_rc" -ne 0 ]] || { echo "FAIL: h4 — a one-row gap whose missing INDEX row is NOT ${VERSION}'s must still FAIL; the scoping is bound to THIS close's row, not to the gap magnitude"; failures=$((failures+1)); }

  # (h5) DIRECTION — INDEX AHEAD of LOG is never this close's no-op (8.x only ever
  # adds the row the LOG already has) and must still FAIL in both modes.
  RELEASE_INDEX="$_fo_tmp/IDX_3"; RELEASE_LOG="$_fo_tmp/LOG_2"; MODE="dry-run"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  _fo_rc=0; phase_assert_anchor_hygiene >/dev/null 2>&1 || _fo_rc=$?
  [[ "$_fo_rc" -ne 0 ]] || { echo "FAIL: h5 — an INDEX-ahead gap at --dry-run must still FAIL; the prediction is directional"; failures=$((failures+1)); }
  RELEASE_LOG="$_fo_tmp/LOG_3"

  # (h6) UNIT — ledger_gap_is_this_close, driven directly. One positive against four
  # negatives, one per conjunct, so a conjunct silently dropped in a later edit fails
  # a NAMED arm instead of widening the prediction unnoticed.
  ledger_gap_is_this_close 2 3 "$_fo_tmp/IDX_2" "$_fo_tmp/LOG_3" "v9.62" "dry-run" || { echo "FAIL: h6-a — the bounded state must predict (dry-run, gap 1, LOG has v9.62, INDEX does not)"; failures=$((failures+1)); }
  if ledger_gap_is_this_close 2 3 "$_fo_tmp/IDX_2" "$_fo_tmp/LOG_3" "v9.62" "apply"; then
    echo "FAIL: h6-b — conjunct (1): --apply must never predict"; failures=$((failures+1))
  fi
  if ledger_gap_is_this_close 1 3 "$_fo_tmp/IDX_1" "$_fo_tmp/LOG_3" "v9.62" "dry-run"; then
    echo "FAIL: h6-c — conjunct (2): a two-row gap must never predict"; failures=$((failures+1))
  fi
  if ledger_gap_is_this_close 2 3 "$_fo_tmp/IDX_2" "$_fo_tmp/LOG_3" "v9.99" "dry-run"; then
    echo "FAIL: h6-d — conjunct (3): a version with NO RELEASE_LOG row must never predict"; failures=$((failures+1))
  fi
  if ledger_gap_is_this_close 2 3 "$_fo_tmp/IDX_2_OTHER" "$_fo_tmp/LOG_3" "v9.62" "dry-run"; then
    echo "FAIL: h6-e — conjunct (4): an INDEX that ALREADY carries this version must never predict"; failures=$((failures+1))
  fi

  # (h7) SIBLING LIMBS ARE UNTOUCHED AT --dry-run. This is the claim the per-limb
  # shape was chosen for, and the one a whole-phase relocation would have broken:
  # with a REAL tagger-identity violation present AND the bounded parity gap present,
  # --dry-run must STILL FAIL, and on the tagger finding — the scoping bounds itself
  # to its own trigger and cannot mask a co-tenanted violation.
  if [[ -n "${_ah_repo:-}" && -d "${_ah_repo}/.git" ]]; then
    local _fo_saved_root2="$REPO_ROOT"
    REPO_ROOT="$_ah_repo"; RELEASE_INDEX="$_fo_tmp/IDX_2"; MODE="dry-run"
    PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
    _fo_rc=0; phase_assert_anchor_hygiene >/dev/null 2>&1 || _fo_rc=$?
    [[ "$_fo_rc" -ne 0 ]] || { echo "FAIL: h7 — a tagger-identity violation must STILL FAIL at --dry-run; the parity scoping must not suppress the mode-invariant limbs"; failures=$((failures+1)); }
    _fo_d="$(get_phase assert_anchor_hygiene)"
    /usr/bin/grep -qF 'TAGGER-IDENTITY' <<<"$_fo_d" || { echo "FAIL: h7 — the --dry-run failure must name TAGGER-IDENTITY, got '$_fo_d'"; failures=$((failures+1)); }
    if /usr/bin/grep -qF 'LEDGER-ROW-PARITY RELEASE_INDEX has' <<<"$_fo_d"; then
      echo "FAIL: h7 — the co-tenanted parity gap is this close's own no-op and must still be PREDICTED, not reported, even on a run that FAILs for another reason; got '$_fo_d'"; failures=$((failures+1))
    fi
    REPO_ROOT="$_fo_saved_root2"
  fi

  # (h8) STRUCTURAL — the fix must keep the PER-LIMB shape. A whole-phase dry-run
  # relocation (the 9.55/15.5 shape) would return 0 before the tagger and
  # tag<->Release limbs ever ran, which is the mode-blindness defect inverted.
  # `declare -f` emits the parsed body with comments stripped, so prose cannot
  # satisfy or defeat this.
  if declare -f phase_assert_anchor_hygiene | /usr/bin/grep -qF 'mark_phase "assert_anchor_hygiene" "DRY-RUN"'; then
    echo "FAIL: h8 — phase 15.55 must NOT take the whole-phase dry-run relocation; two of its three limbs are mode-invariant and must keep running at --dry-run"; failures=$((failures+1))
  fi
  declare -f phase_assert_anchor_hygiene | /usr/bin/grep -qF 'ledger_gap_is_this_close' || { echo "FAIL: h8 — the parity limb must route through ledger_gap_is_this_close; an inlined mode test is not the arm set above"; failures=$((failures+1)); }

  MODE="$_fo_saved_mode"; VERSION="$_fo_saved_version"

  RELEASE_INDEX="$_fo_saved_idx"; RELEASE_LOG="$_fo_saved_log"
  REPO_ROOT="$_fo_saved_root"; GH="$_fo_saved_gh"
  /bin/rm -rf "$_fo_tmp" 2>/dev/null || true

  /bin/rm -rf "$_ah_tmp" 2>/dev/null || true
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # ── #3121: pattern_scan default + report capture ───────────────────────────
  # The phase was previously opt-in behind a flag NO executable caller passed, so
  # it always resolved N/A; and it piped its report to /dev/null and marked PASS on
  # an exit code that is 0 in every arm. These assertions are on the phase's
  # RECORDED DETAIL and the emitted report SECTION, never on exit status.
  local _ps_saved_wps="$WITH_PATTERN_SCAN" _ps_saved_mode="$MODE"
  local _ps_saved_syn="$SYNTHESIZE_LEARNINGS" _ps_saved_rep="$PATTERN_SCAN_REPORT"
  local _ps_tmp; _ps_tmp="$(/usr/bin/mktemp -d)"

  # a) DEFAULT IS ON. Parse the initializer from source rather than reading the
  # live global, so a later re-assignment cannot make this pass vacuously.
  if ! /usr/bin/grep -qE '^WITH_PATTERN_SCAN=1$' "${BASH_SOURCE[0]}"; then
    echo "FAIL: #3121 — WITH_PATTERN_SCAN must default to 1; a flag-gated disposition never fires"; failures=$((failures+1))
  fi
  # b) --no-pattern-scan is parsed (the escape hatch exists), and the retired
  #    --with-pattern-scan is still accepted so no existing invocation breaks.
  #    Needles are ASSEMBLED at runtime: written literally, each would match its
  #    OWN source line here and pass even after the parser arm was deleted. That
  #    is not hypothetical — the literal form of this probe SURVIVED the
  #    escape-hatch-removal mutant, which is how the self-match was caught.
  local _ps_no _ps_with
  _ps_no="$(/usr/bin/printf -- '\\-\\-no\\-pattern\\-sca%s) WITH_PATTERN_SCAN=0; shift' 'n')"
  _ps_with="$(/usr/bin/printf -- '\\-\\-with\\-pattern\\-sca%s) WITH_PATTERN_SCAN=1; shift' 'n')"
  [[ "$(grep_count -E -- "$_ps_no" "${BASH_SOURCE[0]}")" == "1" ]] \
    || { echo "FAIL: #3121 — --no-pattern-scan escape hatch missing from the flag parser"; failures=$((failures+1)); }
  [[ "$(grep_count -E -- "$_ps_with" "${BASH_SOURCE[0]}")" == "1" ]] \
    || { echo "FAIL: #3121 — --with-pattern-scan must remain accepted as a compatible no-op"; failures=$((failures+1)); }
  # c) The report must NOT be discarded. A `/dev/null` redirect on the synthesizer
  #    invocation is the exact defect this closed; assert it cannot come back.
  if declare -f phase_pattern_scan | /usr/bin/grep -q '/dev/null'; then
    echo "FAIL: #3121 — phase_pattern_scan discards its report to /dev/null again"; failures=$((failures+1))
  fi
  # d) Suppression path records the honest reason.
  WITH_PATTERN_SCAN=0; MODE="apply"; PATTERN_SCAN_REPORT=""
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_pattern_scan >/dev/null 2>&1
  [[ "$(get_phase pattern_scan)" == "N/A|suppressed by --no-pattern-scan" ]] \
    || { echo "FAIL: #3121 — suppressed run should record N/A with the --no-pattern-scan reason, got '$(get_phase pattern_scan)'"; failures=$((failures+1)); }
  # e) CONTENT SIGNAL, not a status token: with the scan on, the phase detail must
  #    carry the two parsed COUNTS, and the captured body must reach the report.
  #    A stub synthesizer keeps this hermetic (no live event log, no network).
  {
    echo '#!/bin/bash'
    echo 'echo "## Pattern-Detect Report (window=5; cluster-min=3)"'
    echo 'echo ""'
    echo 'echo "**Qualifying clusters (size >= 3, spans >= 2 versions):** 0"'
    echo 'echo "**Near-threshold clusters (2 <= size < 3, spans >= 2 versions):** 2"'
    echo 'echo "### Near-threshold (no promotion)"'
    echo 'echo "| \`widget\` | surprise | 2 | v9.01, v9.02 |"'
    echo 'exit 0'
  } > "$_ps_tmp/synth.sh"
  /bin/chmod +x "$_ps_tmp/synth.sh"
  SYNTHESIZE_LEARNINGS="$_ps_tmp/synth.sh"
  WITH_PATTERN_SCAN=1; MODE="apply"; PATTERN_SCAN_REPORT=""
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_pattern_scan >/dev/null 2>&1
  local _ps_rd; _ps_rd="$(get_phase pattern_scan)"
  [[ "$_ps_rd" == "PASS|qualifying=0, near-threshold=2 (dry-run default; no Issues created)" ]] \
    || { echo "FAIL: #3121 — phase detail must carry the parsed counts, got '$_ps_rd'"; failures=$((failures+1)); }
  # Anti-vacuity control: a report with DIFFERENT counts must produce a DIFFERENT
  # detail. Without this, a hardcoded string would satisfy the assertion above.
  /usr/bin/sed -i '' 's/\*\*} 0"/**} 0"/' "$_ps_tmp/synth.sh" 2>/dev/null || true
  /usr/bin/sed -i '' 's/versions):\*\* 0"/versions):** 7"/' "$_ps_tmp/synth.sh"
  PATTERN_SCAN_REPORT=""; PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_pattern_scan >/dev/null 2>&1
  [[ "$(get_phase pattern_scan)" == *"qualifying=7"* ]] \
    || { echo "FAIL: #3121 — the count in the phase detail is not actually parsed from the report (control arm did not move), got '$(get_phase pattern_scan)'"; failures=$((failures+1)); }
  # f) The captured body reaches the operator-facing markdown report.
  local _ps_saved_out="$OUTPUT"; OUTPUT="markdown"
  local _ps_report; _ps_report="$(generate_markdown_report 2>/dev/null)"
  echo "$_ps_report" | /usr/bin/grep -q '^## Cross-Release Pattern Scan$' \
    || { echo "FAIL: #3121 — the close-out report must carry the Cross-Release Pattern Scan section"; failures=$((failures+1)); }
  echo "$_ps_report" | /usr/bin/grep -q 'Near-threshold (no promotion)' \
    || { echo "FAIL: #3121 — the captured pattern-scan body did not reach the close-out report"; failures=$((failures+1)); }
  # Specificity: with NO captured report the section must be ABSENT, not empty.
  PATTERN_SCAN_REPORT=""
  if generate_markdown_report 2>/dev/null | /usr/bin/grep -q '^## Cross-Release Pattern Scan$'; then
    echo "FAIL: #3121 — the pattern-scan section must be omitted when nothing was captured"; failures=$((failures+1))
  fi
  OUTPUT="$_ps_saved_out"
  WITH_PATTERN_SCAN="$_ps_saved_wps"; MODE="$_ps_saved_mode"
  SYNTHESIZE_LEARNINGS="$_ps_saved_syn"; PATTERN_SCAN_REPORT="$_ps_saved_rep"

  # ── #1825: audit_epic_rollup (phase 16.7) default + report capture ──────────
  # Same shape as the pattern-scan arms above, and for the same reason: the phase
  # invokes a tool that exits 0 whether it surfaces 0 candidates or 40, so an exit
  # status asserts nothing. Every assertion is on the RECORDED DETAIL and the
  # emitted report SECTION. A stub audit keeps this hermetic — no gh, no network.
  local _ea_saved_wea="$WITH_EPIC_AUDIT" _ea_saved_mode="$MODE"
  local _ea_saved_tool="$AUDIT_EPIC_ROLLUP" _ea_saved_rep="$EPIC_AUDIT_REPORT"
  local _ea_tmp; _ea_tmp="$(/usr/bin/mktemp -d)"

  # a) DEFAULT IS ON — parsed from source, so a later re-assignment cannot make
  #    this pass vacuously. A detective phase nobody invokes is the failure mode
  #    the epic-rollup gap itself demonstrates.
  if ! /usr/bin/grep -qE '^WITH_EPIC_AUDIT=1$' "${BASH_SOURCE[0]}"; then
    echo "FAIL: #1825 — WITH_EPIC_AUDIT must default to 1; a flag-gated audit never fires"; failures=$((failures+1))
  fi
  # b) The escape hatch is parsed. Needle ASSEMBLED at runtime so it cannot match
  #    its own source line and survive deletion of the parser arm.
  local _ea_no
  _ea_no="$(/usr/bin/printf -- '\\-\\-no\\-epic\\-audi%s) WITH_EPIC_AUDIT=0; shift' 't')"
  [[ "$(grep_count -E -- "$_ea_no" "${BASH_SOURCE[0]}")" == "1" ]] \
    || { echo "FAIL: #1825 — --no-epic-audit escape hatch missing from the flag parser"; failures=$((failures+1)); }
  # c) The report must NOT be discarded to /dev/null — the defect phase 16.5 had.
  if declare -f phase_audit_epic_rollup | /usr/bin/grep -q '/dev/null'; then
    echo "FAIL: #1825 — phase_audit_epic_rollup discards its report to /dev/null"; failures=$((failures+1))
  fi
  # d) Suppression path records the honest reason.
  WITH_EPIC_AUDIT=0; MODE="apply"; EPIC_AUDIT_REPORT=""
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_audit_epic_rollup >/dev/null 2>&1
  [[ "$(get_phase audit_epic_rollup)" == "N/A|suppressed by --no-epic-audit" ]] \
    || { echo "FAIL: #1825 — suppressed run should record N/A with the --no-epic-audit reason, got '$(get_phase audit_epic_rollup)'"; failures=$((failures+1)); }
  # e) CONTENT SIGNAL: the detail must carry the two counts PARSED from the report.
  {
    echo '#!/bin/bash'
    echo 'echo "# Epic Rollup-Close Audit"'
    echo 'echo ""'
    echo 'echo "| Bucket | Count |"'
    echo 'echo "|---|---|"'
    echo 'echo "| Clean candidates | 5 |"'
    echo 'echo "| Flagged candidates | 10 |"'
    echo 'echo "## Candidates — clean rollup"'
    echo 'exit 0'
  } > "$_ea_tmp/audit.sh"
  /bin/chmod +x "$_ea_tmp/audit.sh"
  AUDIT_EPIC_ROLLUP="$_ea_tmp/audit.sh"
  WITH_EPIC_AUDIT=1; MODE="apply"; EPIC_AUDIT_REPORT=""
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_audit_epic_rollup >/dev/null 2>&1
  local _ea_rd; _ea_rd="$(get_phase audit_epic_rollup)"
  [[ "$_ea_rd" == "PASS|clean-candidates=5, flagged-candidates=10 (report-only; no Issues closed)" ]] \
    || { echo "FAIL: #1825 — phase detail must carry the parsed counts, got '$_ea_rd'"; failures=$((failures+1)); }
  # Anti-vacuity control: DIFFERENT counts must produce a DIFFERENT detail.
  # Without this arm a hardcoded string satisfies the assertion above.
  /usr/bin/sed -i '' 's/| Clean candidates | 5 |/| Clean candidates | 3 |/' "$_ea_tmp/audit.sh"
  EPIC_AUDIT_REPORT=""; PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_audit_epic_rollup >/dev/null 2>&1
  [[ "$(get_phase audit_epic_rollup)" == *"clean-candidates=3"* ]] \
    || { echo "FAIL: #1825 — the count in the phase detail is not actually parsed from the report (control arm did not move), got '$(get_phase audit_epic_rollup)'"; failures=$((failures+1)); }
  # f) A FAILING audit is a phase FAIL — but findings alone never are. This is the
  #    line between "the tool broke" and "the tool found something".
  echo '#!/bin/bash
exit 4' > "$_ea_tmp/audit.sh"
  /bin/chmod +x "$_ea_tmp/audit.sh"
  EPIC_AUDIT_REPORT=""; PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_audit_epic_rollup >/dev/null 2>&1 || true
  [[ "$(get_phase audit_epic_rollup)" == FAIL\|* ]] \
    || { echo "FAIL: #1825 — a non-zero audit exit must record a phase FAIL, got '$(get_phase audit_epic_rollup)'"; failures=$((failures+1)); }
  # g) The captured body reaches the operator-facing markdown report.
  local _ea_saved_out="$OUTPUT"; OUTPUT="markdown"
  EPIC_AUDIT_REPORT="# Epic Rollup-Close Audit
| Clean candidates | 5 |
## Candidates — clean rollup"
  local _ea_report; _ea_report="$(generate_markdown_report 2>/dev/null)"
  echo "$_ea_report" | /usr/bin/grep -q '^## Epic Rollup-Close Audit$' \
    || { echo "FAIL: #1825 — the close-out report must carry the Epic Rollup-Close Audit section"; failures=$((failures+1)); }
  echo "$_ea_report" | /usr/bin/grep -q 'Candidates — clean rollup' \
    || { echo "FAIL: #1825 — the captured audit body did not reach the close-out report"; failures=$((failures+1)); }
  # Specificity: with NO captured report the section must be ABSENT, not empty.
  EPIC_AUDIT_REPORT=""
  if generate_markdown_report 2>/dev/null | /usr/bin/grep -q '^## Epic Rollup-Close Audit$'; then
    echo "FAIL: #1825 — the epic-audit section must be omitted when nothing was captured"; failures=$((failures+1))
  fi
  OUTPUT="$_ea_saved_out"
  WITH_EPIC_AUDIT="$_ea_saved_wea"; MODE="$_ea_saved_mode"
  AUDIT_EPIC_ROLLUP="$_ea_saved_tool"; EPIC_AUDIT_REPORT="$_ea_saved_rep"
  /bin/rm -rf "$_ea_tmp" 2>/dev/null || true
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  echo "  phase_audit_epic_rollup wiring validated (#1825 — default ON (source-parsed) / --no-epic-audit suppresses with the honest reason / NO /dev/null discard / detail carries the PARSED counts with a moved-control anti-vacuity arm / tool failure is a phase FAIL while findings are not / captured body reaches the close-out report, and the section is ABSENT when nothing was captured)" >&2
  /bin/rm -rf "$_ps_tmp" 2>/dev/null || true
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # ── #4773: the close-out report's phase set is DERIVED from the phase record ──
  # Every assertion below reads the rendered report, never an enumeration, so the
  # suite cannot be satisfied by re-declaring the answer. Arms (a)-(f) cover
  # render<->record; arm (g) covers dispatch<->record, which is the invariant the
  # derivation newly makes load-bearing and which NO seeded arm can reach.
  # `grep` reads a here-string throughout, never `echo … | grep -q`: under this
  # script's `set -euo pipefail`, grep -q exits on first match and SIGPIPEs the
  # writer, so pipefail promotes a SUCCESSFUL match to a non-zero pipeline status.
  local _dr_saved_out="$OUTPUT"; OUTPUT="markdown"
  local _dr_report _dr_name _dr_missing="" _dr_n=0
  # `|| true` is load-bearing, not defensive noise: under `set -euo pipefail` a
  # grep that matches NOTHING fails the pipeline and kills the shell inside the
  # command substitution — which would abort the whole suite silently and leave
  # the vacuity floor below unreachable. Absorb the status here so an empty parse
  # reaches the floor and is REPORTED rather than crashing the run.
  local _dr_subjects
  _dr_subjects="$(/usr/bin/grep -oE 'mark_phase "[a-z0-9_]+"' "${BASH_SOURCE[0]}" \
    | /usr/bin/sed 's/mark_phase "//;s/"$//' | /usr/bin/sort -u || true)"

  # (a) COMPLETENESS — every recorded phase renders. The denominator is parsed
  #     from this file's own mark_phase subjects, so it grows with the file rather
  #     than pinning a count that rots. Pre-fix this arm reports exactly three
  #     missing (inject_velocity_field, append_release_learnings,
  #     audit_epic_rollup) — the measured defect, not a predicted one.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  while IFS= read -r _dr_name; do
    [[ -z "$_dr_name" ]] && continue
    mark_phase "$_dr_name" "PASS" "seeded by self-test"
    _dr_n=$((_dr_n+1))
  done <<< "$_dr_subjects"
  # Anti-vacuity floor: if the subject parse ever returns a near-empty set (a
  # mark_phase reformat, or the function-only slice), the arms below would pass on
  # an empty denominator. Fail loudly instead of going green on nothing.
  if [[ "$_dr_n" -lt 25 ]]; then
    echo "FAIL: #4773 — mark_phase subject parse found only ${_dr_n} phases; the completeness arm would be vacuous"
    failures=$((failures+1))
  fi
  _dr_report="$(generate_markdown_report 2>/dev/null)"
  while IFS= read -r _dr_name; do
    [[ -z "$_dr_name" ]] && continue
    /usr/bin/grep -qE "^\| ${_dr_name} \|" <<< "$_dr_report" || _dr_missing="${_dr_missing}${_dr_name} "
  done <<< "$_dr_subjects"
  if [[ -n "$_dr_missing" ]]; then
    echo "FAIL: #4773 — recorded phases absent from the close-out report: ${_dr_missing}"
    failures=$((failures+1))
  fi

  # (b) THE AC-2 ARM — a phase name in NO enumeration anywhere still renders. This
  #     is the arm that fails if the derivation is ever replaced by a list.
  #     Every synthetic probe name below is passed through a VARIABLE, never as a
  #     quoted string literal in the mark_phase call, so these test fixtures stay
  #     out of the production record-subject census that arm (a) and the dispatch
  #     cross-check parse out of this file's own text. (Prose in this file is part
  #     of that census's denominator too — spelling the literal form here would
  #     itself register a phantom subject.)
  local _dr_probe="zz_synthetic_probe_phase"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  mark_phase "$_dr_probe" "PASS" "synthetic — declared in no enumeration"
  _dr_report="$(generate_markdown_report 2>/dev/null)"
  /usr/bin/grep -qE '^\| zz_synthetic_probe_phase \| PASS \|' <<< "$_dr_report" \
    || { echo "FAIL: #4773 — a recorded phase in no enumeration must still render (the derivation regressed to a list)"; failures=$((failures+1)); }

  # (c) ANTI-VACUITY CONTROL — a name never marked must NOT render. Without this,
  #     arms (a) and (b) would be satisfied by a renderer that emits everything.
  if /usr/bin/grep -qE '^\| zz_never_marked_probe \|' <<< "$_dr_report"; then
    echo "FAIL: #4773 — an unmarked phase name rendered; the table is not record-derived"
    failures=$((failures+1))
  fi

  # (d) SUB-PHASE RETENTION (specificity) — post_gate_passage_proof is recorded by
  #     mark_phase inside phase_run_verification and has NO phase_*() function, so
  #     any future "simplification" to a definition scan silently drops it. Assert
  #     both halves: that it really is definition-less, and that it renders.
  if /usr/bin/grep -qE '^phase_post_gate_passage_proof\(\)' "${BASH_SOURCE[0]}"; then
    echo "FAIL: #4773 — post_gate_passage_proof now HAS a phase_*() function; this arm's premise is stale, re-derive it"
    failures=$((failures+1))
  fi
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  mark_phase "post_gate_passage_proof" "PASS" "sub-phase of run_verification"
  /usr/bin/grep -qE '^\| post_gate_passage_proof \|' <<< "$(generate_markdown_report 2>/dev/null)" \
    || { echo "FAIL: #4773 — post_gate_passage_proof must render; a definition-derived set would drop it"; failures=$((failures+1)); }

  # (e) DUPLICATE SAFETY — a name marked twice renders ONCE, carrying the FIRST
  #     result, matching get_phase's first-match lookup. This is what makes the
  #     change provably additive rather than a silent output change.
  local _dr_dup="zz_dup_probe"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  mark_phase "$_dr_dup" "PASS" "first mark"
  mark_phase "$_dr_dup" "FAIL" "second mark"
  _dr_report="$(generate_markdown_report 2>/dev/null)"
  local _dr_dups
  _dr_dups="$(/usr/bin/grep -cE '^\| zz_dup_probe \|' <<< "$_dr_report" || true)"
  [[ "$_dr_dups" -eq 1 ]] \
    || { echo "FAIL: #4773 — a double-marked phase must render exactly one row, got ${_dr_dups}"; failures=$((failures+1)); }
  /usr/bin/grep -qE '^\| zz_dup_probe \| PASS \| first mark \|' <<< "$_dr_report" \
    || { echo "FAIL: #4773 — the surviving duplicate row must carry the FIRST result (get_phase semantics)"; failures=$((failures+1)); }

  # (f) HALTED MARKER — a FAIL-terminated run states the fact of truncation, and a
  #     clean run does NOT. Both directions asserted on the SAME record, one mark
  #     apart, because a marker that always prints carries no information.
  local _dr_ok="zz_ok_probe" _dr_halt="zz_halt_probe"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  mark_phase "$_dr_ok" "PASS" "ran"
  if /usr/bin/grep -qF 'Run halted' <<< "$(generate_markdown_report 2>/dev/null)"; then
    echo "FAIL: #4773 — the halted marker must NOT appear when the last recorded result is not FAIL"
    failures=$((failures+1))
  fi
  mark_phase "$_dr_halt" "FAIL" "blew up"
  /usr/bin/grep -qF '**Run halted** at `zz_halt_probe`' <<< "$(generate_markdown_report 2>/dev/null)" \
    || { echo "FAIL: #4773 — a FAIL-terminated run must name the phase it halted at"; failures=$((failures+1)); }

  # (g) DISPATCH <-> RECORD CROSS-CHECK — the arm every other arm structurally
  #     cannot be. Arms (a)-(f) SEED the record, so they verify render<->record and
  #     are green by construction against the failure this derivation newly makes
  #     silent: a phase added to the dispatch that never calls mark_phase is absent
  #     from the record, therefore absent from the report, and no seeded arm
  #     notices. This arm reads the DISPATCH from the file's own text — a second,
  #     independent recorder — and asserts every dispatched phase is a record
  #     subject. Two recorders, cross-checked, per the staging guard's own
  #     rationale: a guard that consults the same recorder whose omission IS the
  #     defect cannot catch that omission.
  #
  #     It lives in the TEST path by necessity, not preference: the dispatch block
  #     sits BELOW the "# ─── Argument parsing" banner, so it is absent from the
  #     function-only slice core/deploy/tests/test_version_stamping.sh sources. A
  #     render-path self-parse would read zero dispatched phases under exactly that
  #     harness and go vacuous.
  #     The record side is read from the PRODUCTION region only (everything above
  #     the self_test definition). Searching the whole file would let a self-test
  #     arm that happens to mark a phase by string literal satisfy this check on
  #     the production code's behalf — the test vouching for the code it tests.
  local _dr_dispatched _dr_dn=0 _dr_unrecorded="" _dr_prod
  _dr_prod="$(/usr/bin/sed -n '1,/^self_test() {/p' "${BASH_SOURCE[0]}" || true)"
  # See the note on the subject parse above — an empty dispatch parse must reach
  # the vacuity floor, not kill the suite.
  _dr_dispatched="$(/usr/bin/grep -oE '^phase_[a-z0-9_]+ \|\|' "${BASH_SOURCE[0]}" \
    | /usr/bin/sed 's/^phase_//;s/ ||$//' | /usr/bin/sort -u || true)"
  while IFS= read -r _dr_name; do
    [[ -z "$_dr_name" ]] && continue
    _dr_dn=$((_dr_dn+1))
    /usr/bin/grep -qF "mark_phase \"${_dr_name}\"" <<< "$_dr_prod" \
      || _dr_unrecorded="${_dr_unrecorded}${_dr_name} "
  done <<< "$_dr_dispatched"
  if [[ "$_dr_dn" -lt 25 ]]; then
    echo "FAIL: #4773 — dispatch parse found only ${_dr_dn} dispatched phases; the cross-check would be vacuous"
    failures=$((failures+1))
  fi
  if [[ -n "$_dr_unrecorded" ]]; then
    echo "FAIL: #4773 — dispatched phases that never call mark_phase (they would be silently ABSENT from the close-out report): ${_dr_unrecorded}"
    failures=$((failures+1))
  fi
  # Sensitivity + specificity on the dispatch parse itself: a phase known to be
  # dispatched must appear in the parsed set, and a fabricated name must not.
  /usr/bin/grep -qx 'audit_epic_rollup' <<< "$_dr_dispatched" \
    || { echo "FAIL: #4773 — the dispatch parse missed a known dispatched phase; the cross-check is not reading the dispatch"; failures=$((failures+1)); }
  if /usr/bin/grep -qx 'zz_not_a_dispatched_phase' <<< "$_dr_dispatched"; then
    echo "FAIL: #4773 — the dispatch parse matched a fabricated name; it is matching indiscriminately"
    failures=$((failures+1))
  fi

  # (h) JSON TWIN — the machine-readable report carries the same derived set, so a
  #     `--json` consumer is not blind to phase outcomes. Additive key only.
  local _dr_jprobe="zz_json_probe"
  OUTPUT="json"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  mark_phase "$_dr_jprobe" "PASS" "detail with a | pipe and a \"quote\""
  mark_phase "$_dr_jprobe" "FAIL" "duplicate, must not appear"
  local _dr_json; _dr_json="$(generate_json_report)"
  /usr/bin/python3 - "$_dr_json" <<'PY' || { echo "FAIL: #4773 — JSON report phase set malformed"; failures=$((failures+1)); }
import sys, json
d = json.loads(sys.argv[1])
p = d.get("phases")
assert isinstance(p, list) and len(p) == 1, "expected exactly one de-duplicated phase, got %r" % (p,)
assert p[0]["name"] == "zz_json_probe", p[0]
assert p[0]["result"] == "PASS", "first-occurrence-wins violated: %r" % (p[0],)
assert "|" in p[0]["detail"] and '"' in p[0]["detail"], "detail round-trip lost characters: %r" % (p[0],)
for k in ("timestamp", "mode", "release_pr", "version", "milestone", "release_log",
          "cycle_time", "chore_pr", "d1_manual_close_candidates", "deferred_under_no_merge"):
    assert k in d, "pre-existing key %s was dropped — the phases key must be ADDITIVE" % k
PY
  OUTPUT="$_dr_saved_out"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # ── #4322: the Gate-Passage-Proof **Chore PR:** field renders ONCE, both paths ──
  #
  # The shipped defect was a PAIRED set-arm / unset-arm parameter expansion on ONE
  # variable: the set-arm fires when the variable is set, and the unset-arm ALSO passes
  # the value through when it is set, so the populated path emitted the number twice —
  # a '#'-prefixed number immediately followed by the bare number. It shipped because
  # the only path the pre-existing report arms exercise is the dry-run/unset one, where
  # the two arms are indistinguishable. (b1)/(b3) are therefore the PREVIOUSLY-UNCOVERED
  # path; (b2) is the previously-covered one, kept so the fix is asserted in both
  # directions rather than swapping one blind spot for another.
  #
  # The prose above names the arms in words rather than spelling the brace form. This
  # file's own census-denominator rule (stated with the zz-prefix rationale in the #4773
  # group below) is that PROSE IN THIS FILE IS PART OF A CENSUS'S DENOMINATOR TOO, so
  # writing the literal paired form here would register a phantom instance of the exact
  # class (b5) guards. The one deliberate literal instance is the _cp_src fixture, which
  # (b5) excludes by construction because it scopes itself above self_test.
  #
  # MUTATION EXPECTATION — recorded because it was EXECUTED, not reasoned. Reverting the
  # render line alone makes b1, b3 and b5 name themselves. b7 does NOT fire, and that is
  # a DESIGNED property rather than a gap: it strips the **Chore PR:** line from both
  # renders before comparing, so it is structurally invariant to this mutation, which is
  # what makes it a clean collateral check instead of a second copy of b1. An
  # expected-kill set that disagrees with execution turns a falsifiability proof into an
  # instruction to "fix" whichever correct arm disagrees with it.
  #
  # grep reads a HERE-STRING throughout, never a pipe into a short-circuiting reader:
  # under this script's `set -euo pipefail` a piped `grep -q` exits at the first match
  # and SIGPIPEs the writer, so pipefail promotes a SUCCESSFUL match to a non-zero
  # status. That form is also what the repo-integrity SIGPIPE-idiom gate reddens on an
  # added line in a changed *.sh, and that gate is enforce-day-one with no warn mode.
  # Matchers are BSD-ERE and BACKREFERENCE-FREE: this suite runs on the macOS partition
  # only (see the selftest-runner directive at the top of this file), where /usr/bin/grep
  # is BSD grep 2.6.0 and -P exits 2 — which, under grep_count's own `|| true` plus its
  # default-zero, renders exactly 0 and ships a broken probe INSIDE the test.
  local _cp_saved_out="$OUTPUT" _cp_saved_pr="$CHORE_PR_NUMBER" _cp_saved_nm="$NO_MERGE"
  local _cp_rep _cp_n _cp_line _cp_occ _cp_pre _cp_prod _cp_paired _cp_ctl _cp_a _cp_b _cp_as _cp_bs
  local _cp_tok _cp_rest _cp_dbl _cp_ctl_occ
  # The pre-fix construct as SOURCE text, single-quoted so it never expands here, and the
  # ONE fixture (b3), (b4) and (b5) all read — so the source form and the expanded form
  # cannot drift apart.
  local _cp_src='**Chore PR:** ${CHORE_PR_NUMBER:+#${CHORE_PR_NUMBER}}${CHORE_PR_NUMBER:-N/A — dry-run or not-yet-created}'
  local _cp_rx='\$\{CHORE_PR_NUMBER:\+.*\}\$\{CHORE_PR_NUMBER:-'
  OUTPUT="markdown"; NO_MERGE=0
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  mark_phase "zz_chore_pr_probe" "PASS" "seeded by the #4322 arm"

  # (b1) POPULATED path (AC-1) — THE PREVIOUSLY-UNCOVERED PATH. Exactly one
  #      **Chore PR:** line, and it carries the number exactly once.
  CHORE_PR_NUMBER="3697"
  _cp_rep="$(generate_markdown_report 2>/dev/null)"
  _cp_n="$(grep_count -E '^\*\*Chore PR:\*\* ' <<< "$_cp_rep")"
  [[ "$_cp_n" -eq 1 ]] || { echo "FAIL: #4322 — the report must carry exactly ONE **Chore PR:** line, got ${_cp_n}"; failures=$((failures+1)); }
  /usr/bin/grep -qxF '**Chore PR:** #3697' <<< "$_cp_rep" \
    || { echo "FAIL: #4322 — populated path must render '**Chore PR:** #3697' exactly"; failures=$((failures+1)); }
  if /usr/bin/grep -qF '36973697' <<< "$_cp_rep"; then
    echo "FAIL: #4322 — the doubled rendering is back; the set-arm and unset-arm are both contributing"; failures=$((failures+1))
  fi

  # (b2) UNSET path (AC-2) — the previously-covered path. The fallback verbatim,
  #      with no '#' prefix and no bare number.
  CHORE_PR_NUMBER=""
  _cp_rep="$(generate_markdown_report 2>/dev/null)"
  /usr/bin/grep -qxF '**Chore PR:** N/A — dry-run or not-yet-created' <<< "$_cp_rep" \
    || { echo "FAIL: #4322 — unset path must render the fallback verbatim, with no '#' prefix"; failures=$((failures+1)); }

  # (b3) SPECIFICITY (AC-3) — a fabricated value matches exactly ONE arm, never both
  #      and never neither. A numeric fixture cannot show this: '#3697' contains '3697',
  #      so "no bare number" is unfalsifiable on a numeric input. A non-numeric token
  #      makes the occurrence count decisive.
  #
  #      THE COUNT IS PURE BASH, NOT `grep_count -oF`. grep_count is /usr/bin/grep -c,
  #      which counts matching LINES, and on the BSD grep this suite runs against, -o
  #      does not change that. Measured on this runner: `grep -c -oF` returns 1 for BOTH
  #      the doubled rendering and the single one — the PASS value on the very defect
  #      this arm exists to catch. Zero of this file's other grep_count call sites pass
  #      -o, and the helper's own contract comment describes a LINE count. The
  #      length-delta form below needs no external tool and no pipe, so neither the
  #      BSD/GNU divergence nor the SIGPIPE-idiom gate can reach it.
  CHORE_PR_NUMBER="zz4322"
  _cp_rep="$(generate_markdown_report 2>/dev/null)"
  /usr/bin/grep -qxF '**Chore PR:** #zz4322' <<< "$_cp_rep" \
    || { echo "FAIL: #4322 — specificity: a fabricated value must render under the prefixed arm, exactly"; failures=$((failures+1)); }
  _cp_tok='zz4322'
  _cp_line="$(/usr/bin/grep -E '^\*\*Chore PR:\*\* ' <<< "$_cp_rep" || true)"
  _cp_rest="${_cp_line//$_cp_tok/}"
  _cp_occ=$(( (${#_cp_line} - ${#_cp_rest}) / ${#_cp_tok} ))
  [[ "$_cp_occ" -eq 1 ]] || { echo "FAIL: #4322 — the value must appear ONCE on the **Chore PR:** line, got ${_cp_occ}"; failures=$((failures+1)); }
  # Anti-vacuity on the occurrence counter ITSELF — the control this assertion shipped
  # without, and the reason its predecessor was inert. The IDENTICAL computation over the
  # pre-fix expansion of the one source fixture must return 2. A counter that cannot see
  # the doubled form makes the 1 above a coincidence rather than a measurement.
  _cp_dbl="$(eval "printf %s \"$_cp_src\"")"
  _cp_rest="${_cp_dbl//$_cp_tok/}"
  _cp_ctl_occ=$(( (${#_cp_dbl} - ${#_cp_rest}) / ${#_cp_tok} ))
  [[ "$_cp_ctl_occ" -eq 2 ]] || { echo "FAIL: #4322 — the occurrence counter did not see the doubled form (got ${_cp_ctl_occ}); its 1 above proves nothing"; failures=$((failures+1)); }

  # (b4) SENSITIVITY — EXECUTABLE, re-demonstrated on every run rather than asserted in
  #      a comment. (b1) is only informative if its matcher REJECTS the pre-fix
  #      rendering; a matcher that accepted anything would pass (b1) silently. Expand the
  #      ONE source fixture and assert both directions.
  CHORE_PR_NUMBER="3697"
  _cp_pre="$(eval "printf %s \"$_cp_src\"")"
  /usr/bin/grep -qF '36973697' <<< "$_cp_pre" \
    || { echo "FAIL: #4322 sensitivity — the pre-fix fixture no longer reproduces the doubled rendering; this arm can no longer tell a fixed line from a broken one"; failures=$((failures+1)); }
  if /usr/bin/grep -qxF '**Chore PR:** #3697' <<< "$_cp_pre"; then
    echo "FAIL: #4322 sensitivity — the (b1) matcher ACCEPTED the pre-fix rendering; (b1)'s green result is uninformative"; failures=$((failures+1))
  fi

  # (b5) REINTRODUCTION GUARD — the PRODUCTION region carries ZERO same-variable paired
  #      set-arm/unset-arm expansions on CHORE_PR_NUMBER. Repo-wide that construct
  #      occurred exactly once before this fix (the defect); after it, zero. Scoped to
  #      everything above `self_test` by the same production-region discipline arm (g) of
  #      the #4773 group uses — otherwise the (b4) fixture would satisfy this guard on
  #      the production code's behalf: the test vouching for the code. The guard is
  #      variable-scoped rather than class-scoped by deliberate choice: the class has
  #      exactly one member and this change removes it, so a class-wide gate would guard
  #      an empty population.
  _cp_prod="$(/usr/bin/sed -n '1,/^self_test() {/p' "${BASH_SOURCE[0]}" || true)"
  _cp_paired="$(grep_count -E "$_cp_rx" <<< "$_cp_prod")"
  [[ "$_cp_paired" -eq 0 ]] || { echo "FAIL: #4322 — the production region carries ${_cp_paired} same-variable paired set/unset expansion(s) on CHORE_PR_NUMBER; the defect idiom is back"; failures=$((failures+1)); }
  # Anti-vacuity on the guard itself: the SAME matcher must return 1 against the pre-fix
  # SOURCE form. A zero whose control also returns zero is a broken probe, not an empty
  # population.
  _cp_ctl="$(grep_count -E "$_cp_rx" <<< "$_cp_src")"
  [[ "$_cp_ctl" -eq 1 ]] || { echo "FAIL: #4322 — the reintroduction-guard matcher did not match the known-bad source form (got ${_cp_ctl}); its zero above proves nothing"; failures=$((failures+1)); }

  # (b6) OUT-OF-SCOPE SITE UNCHANGED — the --no-merge deferral message's SOLITARY set-arm
  #      is correct and is an explicit NOT-EDITED row. Assert the fix did not generalize
  #      into it, in BOTH directions.
  NO_MERGE=1; CHORE_PR_NUMBER="3697"
  _cp_rep="$(generate_markdown_report 2>/dev/null)"
  /usr/bin/grep -qF 'The Stage 13 chore PR #3697 was left open' <<< "$_cp_rep" \
    || { echo "FAIL: #4322 — the out-of-scope --no-merge message must still carry the number when set"; failures=$((failures+1)); }
  CHORE_PR_NUMBER=""
  _cp_rep="$(generate_markdown_report 2>/dev/null)"
  /usr/bin/grep -qF 'The Stage 13 chore PR was left open' <<< "$_cp_rep" \
    || { echo "FAIL: #4322 — the out-of-scope --no-merge message must carry NO number when unset"; failures=$((failures+1)); }

  # (b7) NO COLLATERAL (AC-5) — at NO_MERGE=0 the ONLY line whose content depends on
  #      CHORE_PR_NUMBER is the **Chore PR:** line. Two renders on identical globals are
  #      byte-identical (the run timestamp is sampled once at load), so this is exact
  #      rather than approximate. The anti-vacuity arm comes FIRST: without it, "stripped
  #      remainders are equal" is satisfied by two identical renders.
  NO_MERGE=0
  CHORE_PR_NUMBER="3697"; _cp_a="$(generate_markdown_report 2>/dev/null)"
  CHORE_PR_NUMBER="";     _cp_b="$(generate_markdown_report 2>/dev/null)"
  [[ "$_cp_a" != "$_cp_b" ]] \
    || { echo "FAIL: #4322 AC-5 anti-vacuity — the two renders are identical, so the comparison below proves nothing"; failures=$((failures+1)); }
  _cp_as="$(/usr/bin/grep -vE '^\*\*Chore PR:\*\* ' <<< "$_cp_a" || true)"
  _cp_bs="$(/usr/bin/grep -vE '^\*\*Chore PR:\*\* ' <<< "$_cp_b" || true)"
  [[ "$_cp_as" == "$_cp_bs" ]] \
    || { echo "FAIL: #4322 AC-5 — a field other than **Chore PR:** changed with CHORE_PR_NUMBER; the fix has collateral"; failures=$((failures+1)); }

  OUTPUT="$_cp_saved_out"; CHORE_PR_NUMBER="$_cp_saved_pr"; NO_MERGE="$_cp_saved_nm"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # ── Test AI: phase_action_item_gate (Procedure 7a HARD GATE, #4439) ─────────
  #
  # THE ARM SET IS THE ONLY AUTOMATED EXECUTION THIS GATE EVER GETS. CI runs no
  # apply-mode close at all — `--apply` appears in zero workflow files, and every
  # CI invocation of this script is --check-paths or --self-test — so the close
  # dispatch path is never exercised outside this block. That is why the arms
  # execute the shipped dispatch text rather than modelling it.
  #
  # WHAT MAKES THE SET NON-VACUOUS, stated as the property rather than the count:
  # arms (A) and (B) are each other's control over one differential harness where
  # only the ledger changes — a gate that never blocks fails (A), a gate that
  # always blocks fails (B), and a gate reading the wrong path resolves
  # NOT-RECORDED for both and fails BOTH. Arm (F) closes the gap that shape alone
  # cannot: it EXECUTES the two dispatch lines lifted verbatim from this file and
  # carries a constructed `|| true` degenerate as its negative control, because a
  # dispatch line at the correct POSITION carrying `|| true` passes every
  # position-only assertion while blocking nothing. Arms assert the VERDICT GLOBAL
  # (STATE_AI_GATE), not the detail prose — the detail is a rendering, and the
  # global is what row 6 and every downstream consumer read.
  local _ai_s_hs="$HUB_STATE_PATH" _ai_s_mode="$MODE" _ai_s_ver="$VERSION"
  local _ai_s_slug="$STATE_MILESTONE_SLUG" _ai_s_mstate="$STATE_MILESTONE_STATE"
  local _ai_s_nomerge="$NO_MERGE" _ai_s_attest="$ATTEST_ACTION_ITEMS"
  local _ai_s_writer="$AI_EVENT_WRITER" _ai_s_ms="$MILESTONE"
  local _ai_tmp; _ai_tmp="$(/usr/bin/mktemp -d -t aigate-selftest.XXXXXX)"
  HUB_STATE_PATH="$_ai_tmp/hub-state"
  VERSION="v9.99"; MILESTONE="999"; NO_MERGE=0; ATTEST_ACTION_ITEMS=""
  STATE_MILESTONE_STATE="open"
  # MODE is the variable under test in arms (H) and (J); every other arm needs the
  # blocking mode explicitly, because the script's DEFAULT is dry-run and a dry-run
  # gate never returns non-zero. Leaving it defaulted made every blocking arm go
  # green-by-mode rather than green-by-behaviour — caught by running the set.
  MODE="apply"
  /bin/mkdir -p "$HUB_STATE_PATH/ai-unresolved" "$HUB_STATE_PATH/ai-resolved" \
                "$HUB_STATE_PATH/ai-notrecorded" "$HUB_STATE_PATH/ai-empty" \
                "$HUB_STATE_PATH/ai-decoy"

  # Fixtures. Quoted heredocs — the escaped pipe and the em-dashes are content.
  /bin/cat > "$HUB_STATE_PATH/ai-unresolved/action-items.md" <<'AIFIX'
---
schema_version: "v1.0"
---
## Action Items

| id | created_at | source_stage | source_sub_task | category | owner | description | trigger_type | trigger_detail | target | status | resolved_at | resolution |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AI-001 | 2026-08-14T10:00:00Z | 5 | #5379 | verification | operator | dispose the rows \| then carry forward | stage-boundary | before Stage 13 close | issue:#4439 | open | — | — |
| AI-002 | 2026-08-14T10:05:00Z | 6 | #5380 | reminder | hub | rebuild the packages | event | after merge | file:packages | done | 2026-08-14T11:00:00Z | merged |
AIFIX
  /bin/cat > "$HUB_STATE_PATH/ai-resolved/action-items.md" <<'AIFIX'
## Action Items

| id | created_at | source_stage | source_sub_task | category | owner | description | trigger_type | trigger_detail | target | status | resolved_at | resolution |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AI-001 | 2026-08-14T10:00:00Z | 5 | #1 | reminder | hub | a | event | after merge | file:a | done | 2026-08-14T11:00:00Z | landed |
| AI-002 | 2026-08-14T10:01:00Z | 5 | #2 | cleanup | hub | b | event | after merge | file:b | cancelled | 2026-08-14T11:01:00Z | not needed |
| AI-003 | 2026-08-14T10:02:00Z | 5 | #3 | deferred-edit | hub | c | event | after merge | file:c | superseded | 2026-08-14T11:02:00Z | see AI-002 |
AIFIX
  # Decoy: every row TERMINAL, but two carry the literal words `open` and
  # `in-flight` in trigger_detail. A row-pattern probe reports 2 unresolved here;
  # a column-addressed one reports 0. This is the false-positive control the
  # Procedure 7a probe note names, and it is why the gate addresses $11.
  /bin/cat > "$HUB_STATE_PATH/ai-decoy/action-items.md" <<'AIFIX'
## Action Items

| id | created_at | source_stage | source_sub_task | category | owner | description | trigger_type | trigger_detail | target | status | resolved_at | resolution |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AI-010 | 2026-08-14T10:00:00Z | 5 | #1 | reminder | hub | x | event | open | file:x | done | 2026-08-14T11:00:00Z | ok |
| AI-011 | 2026-08-14T10:01:00Z | 5 | #2 | cleanup | hub | y | event | in-flight | file:y | cancelled | 2026-08-14T11:01:00Z | ok |
AIFIX
  /bin/cat > "$HUB_STATE_PATH/ai-empty/action-items.md" <<'AIFIX'
## Action Items

| id | created_at | source_stage | source_sub_task | category | owner | description | trigger_type | trigger_detail | target | status | resolved_at | resolution |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
AIFIX

  # $AI_EVENT_WRITER stub: appends its full argv to a per-arm witness file. The
  # attestation EMISSION is a spec obligation ("that attestation is itself
  # emitted"), so it is asserted on the witness CONTENT, never on the phase record.
  local _ai_witness="$_ai_tmp/attest-witness.txt"
  # A shell function is not an executable file, and the phase guards its writer
  # with `[[ -x ]]`, so the stub is a real file — the `_mt_stub` GH-stub idiom this
  # suite already uses in 15+ arms.
  /bin/cat > "$_ai_tmp/writer-stub" <<AISTUB
#!/bin/sh
printf '%s\n' "\$*" >> "$_ai_witness"
exit 0
AISTUB
  /bin/chmod +x "$_ai_tmp/writer-stub"
  AI_EVENT_WRITER="$_ai_tmp/writer-stub"

  # Drive the gate against one fixture, leaving the phase record and the STATE_AI_*
  # globals in place for assertion.
  #
  # IT REPORTS THROUGH A GLOBAL, NOT THROUGH STDOUT, AND THAT IS DELIBERATE. Calling
  # this in `$( )` would run the whole phase in a subshell, so every global it sets
  # — STATE_AI_GATE above all — would be discarded on return and each arm below
  # would assert against a stale value from the previous arm. That is the
  # lost-in-the-subshell defect, and it produces arms that agree with whatever ran
  # last rather than with what they drove.
  _ai_drive() {
    _AI_RC=0
    PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
    STATE_MILESTONE_SLUG="$1"
    phase_action_item_gate >/dev/null 2>&1 || _AI_RC=$?
  }

  local _ai_rc _ai_rec

  # (A) BLOCK — one open row, --apply. The close must become unreachable.
  _ai_drive ai-unresolved; _ai_rc="$_AI_RC"
  [[ "$_ai_rc" -eq 3 ]] || { echo "FAIL: AI-A — an UNRESOLVED ledger at --apply must return 3 (the dispatcher's guard is what halts the run), got rc $_ai_rc"; failures=$((failures+1)); }
  [[ "$STATE_AI_GATE" == "UNRESOLVED" ]] || { echo "FAIL: AI-A — STATE_AI_GATE must be UNRESOLVED, got '$STATE_AI_GATE'"; failures=$((failures+1)); }
  [[ "$STATE_AI_TOTAL" -eq 2 && "$STATE_AI_UNRES" -eq 1 ]] || { echo "FAIL: AI-A — counts must be TOTAL=2 UNRES=1 (the escaped pipe must NOT shift the status column), got TOTAL=$STATE_AI_TOTAL UNRES=$STATE_AI_UNRES"; failures=$((failures+1)); }
  _ai_rec="$(get_phase action_item_gate)"
  [[ "$_ai_rec" == FAIL\|* ]] || { echo "FAIL: AI-A — the phase must record FAIL, got '$_ai_rec'"; failures=$((failures+1)); }
  /usr/bin/grep -qE 'AI-[0-9]+' <<<"$_ai_rec" || { echo "FAIL: AI-A — the FAIL detail must ENUMERATE the unresolved rows so the operator can act without re-reading the ledger, got '$_ai_rec'"; failures=$((failures+1)); }

  # (B) PASS — three terminal rows. The close must stay reachable. (A)'s control.
  _ai_drive ai-resolved; _ai_rc="$_AI_RC"
  [[ "$_ai_rc" -eq 0 ]] || { echo "FAIL: AI-B — a RESOLVED ledger must return 0, got rc $_ai_rc"; failures=$((failures+1)); }
  [[ "$STATE_AI_GATE" == "RESOLVED" ]] || { echo "FAIL: AI-B — STATE_AI_GATE must be RESOLVED, got '$STATE_AI_GATE'"; failures=$((failures+1)); }
  [[ "$STATE_AI_TOTAL" -eq 3 && "$STATE_AI_UNRES" -eq 0 ]] || { echo "FAIL: AI-B — counts must be TOTAL=3 UNRES=0, got TOTAL=$STATE_AI_TOTAL UNRES=$STATE_AI_UNRES"; failures=$((failures+1)); }
  [[ "$(get_phase action_item_gate)" == PASS\|* ]] || { echo "FAIL: AI-B — a RESOLVED ledger must record PASS, got '$(get_phase action_item_gate)'"; failures=$((failures+1)); }

  # (B2) COLUMN-ADDRESSING — the false-positive control. Every row is terminal;
  #      two carry `open` / `in-flight` in trigger_detail. A row-pattern probe
  #      reports 2 unresolved. Without this arm the gate could ship a probe that
  #      blocks a clean close, which is the shape that gets a gate switched off.
  _ai_drive ai-decoy; _ai_rc="$_AI_RC"
  [[ "$_ai_rc" -eq 0 ]] || { echo "FAIL: AI-B2 — a terminal ledger carrying the literals 'open'/'in-flight' in trigger_detail must NOT block (column-addressed, not row-matched), got rc $_ai_rc"; failures=$((failures+1)); }
  [[ "$STATE_AI_GATE" == "RESOLVED" && "$STATE_AI_UNRES" -eq 0 ]] || { echo "FAIL: AI-B2 — decoy fixture must resolve RESOLVED/0, got '$STATE_AI_GATE'/$STATE_AI_UNRES"; failures=$((failures+1)); }

  # (C) NOT-RECORDED, UNATTESTED — the state milestone #304 was in at close. The
  #     spec's decision table row 1 ends "requires explicit operator attestation
  #     to pass", so an unattested SURFACE state does NOT pass.
  _ai_drive ai-notrecorded; _ai_rc="$_AI_RC"
  [[ "$_ai_rc" -eq 3 ]] || { echo "FAIL: AI-C — an UNATTESTED NOT-RECORDED state at --apply must NOT pass (this is the #304 state; a silent pass is the defect), got rc $_ai_rc"; failures=$((failures+1)); }
  [[ "$STATE_AI_GATE" == "NOT-RECORDED" ]] || { echo "FAIL: AI-C — STATE_AI_GATE must be NOT-RECORDED, got '$STATE_AI_GATE'"; failures=$((failures+1)); }
  local _ai_c_state="$STATE_AI_GATE"
  /usr/bin/grep -qF -- '--attest-action-items' <<<"$(get_phase action_item_gate)" || { echo "FAIL: AI-C — the FAIL detail must NAME the remedy flag, or the gate is one an operator routes around"; failures=$((failures+1)); }

  # (D) EMPTY-LEDGER, UNATTESTED — same posture, distinct STATE.
  _ai_drive ai-empty; _ai_rc="$_AI_RC"
  [[ "$_ai_rc" -eq 3 ]] || { echo "FAIL: AI-D — an UNATTESTED EMPTY-LEDGER state at --apply must NOT pass, got rc $_ai_rc"; failures=$((failures+1)); }
  [[ "$STATE_AI_GATE" == "EMPTY-LEDGER" ]] || { echo "FAIL: AI-D — STATE_AI_GATE must be EMPTY-LEDGER, got '$STATE_AI_GATE'"; failures=$((failures+1)); }

  # (E) DISCRIMINATOR — asserted on the VERDICT, not on the prose. The two SURFACE
  #     states must not collapse into one, or the gate is 2-valued again. Comparing
  #     detail strings would pass on any two distinct sentences; comparing the
  #     globals compares the thing row 6 and every consumer actually read.
  [[ "$_ai_c_state" != "$STATE_AI_GATE" ]] || { echo "FAIL: AI-E — NOT-RECORDED and EMPTY-LEDGER must resolve DISTINCT STATE_AI_GATE values; both read '$STATE_AI_GATE' and the 3-valued gate has collapsed"; failures=$((failures+1)); }
  [[ "$(_ai_verification_cell)" == *"EMPTY-LEDGER"* ]] || { echo "FAIL: AI-E — the row-6 cell must carry the resolved STATE, got '$(_ai_verification_cell)'"; failures=$((failures+1)); }

  # (C'/D') ATTESTED SURFACE — passes, AND the attestation is EMITTED. The spec
  #         makes the emission part of the contract: "that attestation is itself
  #         emitted ... so a skipped emit step leaves an auditable trace rather
  #         than a silent pass." Asserted on the witness CONTENT.
  : > "$_ai_witness"
  ATTEST_ACTION_ITEMS="no-commitments"
  _ai_drive ai-notrecorded; _ai_rc="$_AI_RC"
  [[ "$_ai_rc" -eq 0 ]] || { echo "FAIL: AI-C2 — an ATTESTED NOT-RECORDED state must pass, got rc $_ai_rc"; failures=$((failures+1)); }
  [[ "$(get_phase action_item_gate)" == WARN\|* ]] || { echo "FAIL: AI-C2 — an attested SURFACE state records WARN (surfaced, not silently green), got '$(get_phase action_item_gate)'"; failures=$((failures+1)); }
  [[ "$STATE_AI_EMIT" == "emitted" ]] || { echo "FAIL: AI-C2 — the attestation must be EMITTED, STATE_AI_EMIT='$STATE_AI_EMIT'"; failures=$((failures+1)); }
  [[ -s "$_ai_witness" ]] || { echo "FAIL: AI-C2 — the event-writer witness is empty; the attestation row was never emitted"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'empirical-verification-finding' "$_ai_witness" || { echo "FAIL: AI-C2 — the emitted row must carry the spec's subtype (decision / empirical-verification-finding), witness: $(/bin/cat "$_ai_witness")"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'attested-cause:no-commitments' "$_ai_witness" || { echo "FAIL: AI-C2 — the emitted row must carry the ATTESTED CAUSE; the attestation IS the discriminator between 'no commitments' and 'emit skipped'"; failures=$((failures+1)); }
  /usr/bin/grep -qF -- '--actor operator' "$_ai_witness" || { echo "FAIL: AI-C2 — the attestation is the OPERATOR's, so actor must be operator"; failures=$((failures+1)); }
  : > "$_ai_witness"
  ATTEST_ACTION_ITEMS="emit-skipped"
  _ai_drive ai-empty; _ai_rc="$_AI_RC"
  [[ "$_ai_rc" -eq 0 ]] || { echo "FAIL: AI-D2 — an ATTESTED EMPTY-LEDGER state must pass, got rc $_ai_rc"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'attested-cause:emit-skipped' "$_ai_witness" || { echo "FAIL: AI-D2 — the second cause must round-trip into the emitted row, witness: $(/bin/cat "$_ai_witness")"; failures=$((failures+1)); }

  # (P) PUBLIC-SURFACE PATH HYGIENE. This phase's detail lands in the close-out
  #     report, which is pasted into a sub-task comment on a PUBLIC repository, and
  #     the ledger it names lives under the operator-instance root — so an absolute
  #     path here publishes the operator's home directory. The detail must carry the
  #     registered token and the milestone slug, never the resolved prefix. Both
  #     limbs are needed: the token alone could sit alongside a leaked path.
  ATTEST_ACTION_ITEMS=""
  _ai_drive ai-notrecorded
  _ai_rec="$(get_phase action_item_gate)"
  /usr/bin/grep -qF 'OPERATOR_INSTANCE_HUB_STATE_PATH' <<<"$_ai_rec" || { echo "FAIL: AI-P — the detail must name the ledger surface by its registered token, got '$_ai_rec'"; failures=$((failures+1)); }
  if /usr/bin/grep -qF "$HUB_STATE_PATH" <<<"$_ai_rec"; then
    echo "FAIL: AI-P — the detail carries the RESOLVED absolute hub-state path; in a real run that publishes the operator's home directory into a public comment"; failures=$((failures+1))
  fi
  # Sensitivity: the needle IS findable when the leak is present, so the clean
  # result above is a property of the detail and not of an inert probe.
  /usr/bin/grep -qF "$HUB_STATE_PATH" <<<"prefix $HUB_STATE_PATH suffix" || { echo "FAIL: AI-P sensitivity — the leak probe cannot match its own needle; the clean result above proves nothing"; failures=$((failures+1)); }

  # (E2) ATTESTATION IS A CLOSED ENUM — any-string attestation would let the gate
  #      be cleared by a typo, which is attestation-shaped noise, not attestation.
  ATTEST_ACTION_ITEMS="yes"
  _ai_drive ai-notrecorded; _ai_rc="$_AI_RC"
  [[ "$_ai_rc" -eq 3 ]] || { echo "FAIL: AI-E2 — an unlicensed attestation cause must NOT clear a SURFACE state, got rc $_ai_rc"; failures=$((failures+1)); }

  # (L) ATTESTATION DOES NOT CLEAR AN OPEN ROW. An unresolved commitment is
  #     dispositioned (done / cancelled / superseded), never attested away. Without
  #     this arm the new flag would be a universal gate bypass.
  ATTEST_ACTION_ITEMS="no-commitments"
  _ai_drive ai-unresolved; _ai_rc="$_AI_RC"
  [[ "$_ai_rc" -eq 3 ]] || { echo "FAIL: AI-L — --attest-action-items must NOT clear an UNRESOLVED verdict; an open row is dispositioned, not attested away (rc $_ai_rc)"; failures=$((failures+1)); }
  ATTEST_ACTION_ITEMS=""

  # (H) DRY-RUN — evaluates, records, never halts, and says what it WOULD do.
  MODE="dry-run"
  _ai_drive ai-unresolved; _ai_rc="$_AI_RC"
  [[ "$_ai_rc" -eq 0 ]] || { echo "FAIL: AI-H — --dry-run must never return non-zero (a preview run must not abort), got rc $_ai_rc"; failures=$((failures+1)); }
  [[ "$STATE_AI_GATE" == "UNRESOLVED" ]] || { echo "FAIL: AI-H — --dry-run must still EVALUATE (record a real verdict), got '$STATE_AI_GATE'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'would BLOCK at --apply' <<<"$(get_phase action_item_gate)" || { echo "FAIL: AI-H — the dry-run detail must name the condition that FAILS at --apply (the :3385 precedent), got '$(get_phase action_item_gate)'"; failures=$((failures+1)); }
  MODE="apply"

  # (J) --no-merge — the close is already deferred, so blocking would abort a run
  #     whose close was never going to happen.
  NO_MERGE=1
  _ai_drive ai-unresolved; _ai_rc="$_AI_RC"
  [[ "$_ai_rc" -eq 0 ]] || { echo "FAIL: AI-J — under --no-merge the gate records rather than blocks (post_close_milestone already DEFERS), got rc $_ai_rc"; failures=$((failures+1)); }
  [[ "$STATE_AI_GATE" == "UNRESOLVED" ]] || { echo "FAIL: AI-J — --no-merge must still evaluate, got '$STATE_AI_GATE'"; failures=$((failures+1)); }
  NO_MERGE=0

  # (I) IDEMPOTENT RE-RUN over an already-closed milestone: record, do not block —
  #     and NAME it as the originating incident's shape, so a re-run of a run that
  #     closed before the verdict becomes a detector for exactly that.
  STATE_MILESTONE_STATE="closed"
  _ai_drive ai-unresolved; _ai_rc="$_AI_RC"
  [[ "$_ai_rc" -eq 0 ]] || { echo "FAIL: AI-I — an idempotent re-run over an already-closed milestone must not fail, got rc $_ai_rc"; failures=$((failures+1)); }
  /usr/bin/grep -qF '#304 SHAPE' <<<"$(get_phase action_item_gate)" || { echo "FAIL: AI-I — an UNRESOLVED verdict over an ALREADY-CLOSED milestone is the close-before-verdict shape and the detail must say so, got '$(get_phase action_item_gate)'"; failures=$((failures+1)); }
  STATE_MILESTONE_STATE="open"

  # (K) ROW 6 RENDERS, NEVER RECOMPUTES. phase_run_verification runs AFTER the
  #     close; a verdict re-derived there was never the verdict the close was
  #     gated on. Two limbs: the projection FOLLOWS a mutated global (behavioural),
  #     and phase_run_verification's own text contains no predicate evaluation
  #     (structural — the limb that survives a later refactor).
  STATE_AI_GATE="RESOLVED"; STATE_AI_TOTAL=7; STATE_AI_UNRES=0; ATTEST_ACTION_ITEMS=""
  [[ "$(_ai_verification_cell)" == "RESOLVED (7/7)" ]] || { echo "FAIL: AI-K — the row-6 cell must follow the GLOBAL Phase 12.9 set, got '$(_ai_verification_cell)'"; failures=$((failures+1)); }
  STATE_AI_GATE="UNRESOLVED"; STATE_AI_UNRES=4
  [[ "$(_ai_verification_cell)" == "BLOCKED (4 unresolved of 7)" ]] || { echo "FAIL: AI-K — mutating STATE_AI_GATE must change the cell; it does not, so the cell is not reading the pre-close verdict, got '$(_ai_verification_cell)'"; failures=$((failures+1)); }
  STATE_AI_GATE=""
  [[ "$(_ai_verification_cell)" == UNVERIFIED* ]] || { echo "FAIL: AI-K — an unset verdict must render UNVERIFIED, never a green cell, got '$(_ai_verification_cell)'"; failures=$((failures+1)); }
  local _ai_verifun
  _ai_verifun="$(/usr/bin/awk '/^phase_run_verification\(\) \{$/{f=1} f{print} f&&/^\}$/{exit}' "${BASH_SOURCE[0]}")"
  [[ -n "$_ai_verifun" ]] || { echo "FAIL: AI-K — could not extract phase_run_verification from this file; the structural limb would pass without asserting anything"; failures=$((failures+1)); }
  if /usr/bin/grep -qF '_ai_eval_predicate' <<<"$_ai_verifun"; then
    echo "FAIL: AI-K — phase_run_verification must NOT evaluate the Procedure 7a predicate; it runs after the close, so a recomputed verdict is not the one the close was gated on"; failures=$((failures+1))
  fi
  # Specificity on that extraction: the needle IS present in the phase that is
  # supposed to carry it, so a zero above is a property of the subject and not of
  # a broken extractor.
  local _ai_gatefun
  _ai_gatefun="$(/usr/bin/awk '/^phase_action_item_gate\(\) \{$/{f=1} f{print} f&&/^\}$/{exit}' "${BASH_SOURCE[0]}")"
  /usr/bin/grep -qF '_ai_eval_predicate' <<<"$_ai_gatefun" || { echo "FAIL: AI-K — the extractor found no predicate call in phase_action_item_gate either; the arm above is not reading what it claims to read"; failures=$((failures+1)); }

  # (F) DISPATCH WIRING — THE ARM THE DRAFTED FIX COULD NOT REACH.
  #
  #     Every arm above proves the gate RETURNS 3. None of them proves that return
  #     is WIRED TO THE CLOSE, because self_test calls phases directly and the
  #     dispatch block is main-body code below the argument-parsing banner —
  #     structurally outside every arm's reach. Constructed and measured: three
  #     dispatch variants (guarded / `|| true` / bare) all satisfy a
  #     position-only ordering assertion.
  #
  #     This arm closes that by EXECUTING the two shipped dispatch lines, lifted
  #     verbatim from this file's own text, with the two phases stubbed and a
  #     witness on the close. The `|| true` degenerate is the negative control: if
  #     the harness cannot tell the honest form from it, the arm fails and says so.
  local _ai_gate_ln _ai_close_ln _ai_gate_txt _ai_close_txt
  _ai_gate_ln="$(/usr/bin/grep -nE '^phase_action_item_gate ' "${BASH_SOURCE[0]}" | /usr/bin/cut -d: -f1 || true)"
  _ai_close_ln="$(/usr/bin/grep -nE '^phase_post_close_milestone ' "${BASH_SOURCE[0]}" | /usr/bin/cut -d: -f1 || true)"
  if ! [[ "$_ai_gate_ln" =~ ^[0-9]+$ && "$_ai_close_ln" =~ ^[0-9]+$ ]]; then
    echo "FAIL: AI-F anti-vacuity — a dispatch needle did not resolve to exactly ONE top-level line (gate='$_ai_gate_ln' close='$_ai_close_ln'); the arm would otherwise pass without asserting anything"; failures=$((failures+1))
  else
    [[ "$_ai_gate_ln" -lt "$_ai_close_ln" ]] || { echo "FAIL: AI-F — the Procedure 7a gate (line $_ai_gate_ln) must be dispatched BEFORE the milestone close (line $_ai_close_ln); 7a's own trigger clause requires it"; failures=$((failures+1)); }
    _ai_gate_txt="$(/usr/bin/sed -n "${_ai_gate_ln}p" "${BASH_SOURCE[0]}")"
    _ai_close_txt="$(/usr/bin/sed -n "${_ai_close_ln}p" "${BASH_SOURCE[0]}")"

    # Execute the two lines with both phases stubbed. $1 = gate line text,
    # $2 = the gate stub's return code, $3 = close witness path. Emits the
    # dispatch block's own exit status.
    _ai_exec_dispatch() {
      local _dl="$1" _drc="$2" _dw="$3" _dst=0
      (
        AI_DISPATCH_RC="$_drc"; AI_DISPATCH_W="$_dw"
        generate_report() { :; }
        phase_action_item_gate() { return "$AI_DISPATCH_RC"; }
        phase_post_close_milestone() { /usr/bin/printf 'CLOSED\n' >> "$AI_DISPATCH_W"; return 0; }
        eval "$_dl"
        eval "$_ai_close_txt"
        exit 0
      ) || _dst=$?
      /usr/bin/printf '%s' "$_dst"
    }

    # F-honest-block: gate returns 3 on the SHIPPED line -> close never fires.
    local _ai_w1="$_ai_tmp/w-honest-block.txt" _ai_w2="$_ai_tmp/w-honest-pass.txt" _ai_w3="$_ai_tmp/w-degenerate.txt"
    local _ai_dst
    _ai_dst="$(_ai_exec_dispatch "$_ai_gate_txt" 3 "$_ai_w1")"
    [[ "$_ai_dst" -eq 3 ]] || { echo "FAIL: AI-F1 — the SHIPPED dispatch line must propagate the gate's 3 and halt the run, got exit $_ai_dst"; failures=$((failures+1)); }
    if [[ -e "$_ai_w1" ]]; then
      echo "FAIL: AI-F1 — the milestone close FIRED behind a BLOCKING gate; the gate's return is not wired to the close: $(/bin/cat "$_ai_w1")"; failures=$((failures+1))
    fi
    # F-honest-pass: the SENSITIVITY arm. It proves the harness CAN fire the
    # close, so F1's absence is caused by the guard and not by an inert harness —
    # the "a zero whose control also returns zero is a broken probe" case.
    _ai_dst="$(_ai_exec_dispatch "$_ai_gate_txt" 0 "$_ai_w2")"
    [[ "$_ai_dst" -eq 0 ]] || { echo "FAIL: AI-F2 — a PASSING gate must leave the run running, got exit $_ai_dst"; failures=$((failures+1)); }
    /usr/bin/grep -qF 'CLOSED' "$_ai_w2" 2>/dev/null || { echo "FAIL: AI-F2 sensitivity — the harness never fired the close even on a PASSING gate; AI-F1's clean result would be meaningless"; failures=$((failures+1)); }
    # F-degenerate: the NEGATIVE CONTROL. Same position, same phase name, guard
    # replaced by `|| true`. The close MUST fire here. If it does not, this arm
    # cannot discriminate a fail-closed gate from a no-op one and says so rather
    # than shipping green.
    _ai_dst="$(_ai_exec_dispatch 'phase_action_item_gate || true' 3 "$_ai_w3")"
    /usr/bin/grep -qF 'CLOSED' "$_ai_w3" 2>/dev/null || { echo "FAIL: AI-F3 negative control — a '|| true' dispatch line did NOT let the close through, so this arm cannot tell a fail-closed gate from a no-op one; the whole (F) set is uninformative"; failures=$((failures+1)); }
  fi

  # (F4) GUARDED-FORM INVARIANT over the whole dispatch block. A bare
  #      `phase_action_item_gate` with no guard is invisible to the pre-existing
  #      dispatch<->record cross-check, whose parse is `^phase_[a-z0-9_]+ \|\|`.
  #      Assert the FORM, not just the presence: every dispatched phase carries
  #      the fail-closed guard.
  local _ai_disp_n _ai_guard_n _ai_unguarded
  _ai_disp_n="$(/usr/bin/grep -cE '^phase_[a-z0-9_]+ ' "${BASH_SOURCE[0]}" || true)"; _ai_disp_n="${_ai_disp_n:-0}"
  _ai_guard_n="$(/usr/bin/awk '/^phase_[a-z0-9_]+ / && index($0, "|| { generate_report; exit ") {n++} END {print n+0}' "${BASH_SOURCE[0]}")"
  if [[ "$_ai_disp_n" -lt 25 ]]; then
    echo "FAIL: AI-F4 anti-vacuity — the dispatch parse found only ${_ai_disp_n} lines; the guarded-form invariant would be vacuous"; failures=$((failures+1))
  fi
  if [[ "$_ai_disp_n" -ne "$_ai_guard_n" ]]; then
    _ai_unguarded="$(/usr/bin/awk '/^phase_[a-z0-9_]+ / && !index($0, "|| { generate_report; exit ") {print $1}' "${BASH_SOURCE[0]}" | /usr/bin/tr "\n" " ")"
    echo "FAIL: AI-F4 — ${_ai_guard_n}/${_ai_disp_n} dispatch lines carry the fail-closed guard; an unguarded line runs a phase whose non-zero return halts nothing: ${_ai_unguarded}"; failures=$((failures+1))
  fi
  # Specificity: the guarded-form filter must REJECT an unguarded line, or the
  # equality above is satisfied by a filter that matches everything.
  # SIGPIPE-REWRITE. Was: `awk 'BEGIN{print "<specimen>"}' | awk '<filter>'`. The
  # generator is now a here-string, so there is no writer to signal. The filter is
  # kept BYTE-IDENTICAL to the AI-F4 filter above — that identity is the whole point
  # of this arm, so the filter is what must not be rewritten. (The gate reads this
  # pipeline as `writer | awk (exit)` because the filter's program text contains the
  # literal `exit ` inside an `index()` string operand; the filter carries no `exit`
  # statement and reads to EOF. Removing the pipe answers the finding without
  # touching the filter.)
  local _ai_specimen; _ai_specimen="$(/usr/bin/awk '/^phase_[a-z0-9_]+ / && index($0, "|| { generate_report; exit ") {n++} END {print n+0}' <<<'phase_zz_probe || true')"
  [[ "$_ai_specimen" -eq 0 ]] || { echo "FAIL: AI-F4 specificity — the guarded-form filter matched a '|| true' line; it is not reading the guard"; failures=$((failures+1)); }

  # (G) PREDICATE PARITY — this file's implementation vs the block shipped at
  #     hub-spoke-bridge.md § Procedure 7a, extracted VERBATIM and run over the
  #     same fixtures. The doc is canonical; a second copy here is a shadow-SSOT
  #     risk, and this is the Check-68 `enum-parity` answer to it. Divergence
  #     fails naming both sides.
  local _ai_doc _ai_block _ai_blk_lines
  _ai_doc="$SCRIPT_DIR/../references/how-to/hub-spoke-bridge.md"
  _ai_block=""
  [[ -r "$_ai_doc" ]] && _ai_block="$(/usr/bin/awk '/^AI="\$DIR\/action-items\.md"$/{f=1} f{print} f && /^fi$/{exit}' "$_ai_doc")"
  _ai_blk_lines="$(/usr/bin/printf '%s\n' "$_ai_block" | /usr/bin/grep -c . || true)"; _ai_blk_lines="${_ai_blk_lines:-0}"
  if [[ "$_ai_blk_lines" -lt 8 ]] || ! /usr/bin/grep -qF "awk -F' [|] '" <<<"$_ai_block"; then
    echo "FAIL: AI-G anti-vacuity — the canonical Procedure 7a predicate did not extract from ${_ai_doc#$REPO_ROOT/} (${_ai_blk_lines} lines); a parity arm over an empty block asserts nothing"; failures=$((failures+1))
  else
    local _ai_fx _ai_mine _ai_theirs _ai_seen=""
    for _ai_fx in ai-unresolved ai-resolved ai-decoy ai-empty ai-notrecorded; do
      _ai_mine="$(_ai_eval_predicate "$HUB_STATE_PATH/$_ai_fx")"
      _ai_theirs="$(
        DIR="$HUB_STATE_PATH/$_ai_fx"
        eval "$_ai_block"
        /usr/bin/printf '%s %s %s\n' "$STATE" "${TOTAL:-0}" "${UNRES:-0}"
      )"
      [[ "$_ai_mine" == "$_ai_theirs" ]] || { echo "FAIL: AI-G — predicate FORK on fixture ${_ai_fx}: automated-closeout.sh says '${_ai_mine}', hub-spoke-bridge.md § Procedure 7a says '${_ai_theirs}'"; failures=$((failures+1)); }
      _ai_seen="${_ai_seen}${_ai_theirs%% *} "
    done
    # Sensitivity on the canonical copy: it must return DIFFERENT verdicts across
    # the fixture set. A doc block that returned one constant would agree with any
    # implementation on every fixture and the parity arm would prove nothing.
    local _ai_distinct
    _ai_distinct="$(/usr/bin/printf '%s\n' $_ai_seen | /usr/bin/sort -u | /usr/bin/grep -c . || true)"
    [[ "${_ai_distinct:-0}" -ge 4 ]] || { echo "FAIL: AI-G sensitivity — the canonical predicate returned only ${_ai_distinct} distinct STATEs across 5 fixtures; it is not discriminating, so agreement with it is not evidence"; failures=$((failures+1)); }
  fi

  unset -f _ai_drive _ai_exec_dispatch 2>/dev/null || true
  unset _AI_RC 2>/dev/null || true
  /bin/rm -rf "$_ai_tmp" 2>/dev/null || true
  HUB_STATE_PATH="$_ai_s_hs"; MODE="$_ai_s_mode"; VERSION="$_ai_s_ver"
  STATE_MILESTONE_SLUG="$_ai_s_slug"; STATE_MILESTONE_STATE="$_ai_s_mstate"
  NO_MERGE="$_ai_s_nomerge"; ATTEST_ACTION_ITEMS="$_ai_s_attest"
  AI_EVENT_WRITER="$_ai_s_writer"; MILESTONE="$_ai_s_ms"
  STATE_AI_GATE=""; STATE_AI_TOTAL=0; STATE_AI_UNRES=0; STATE_AI_DIR=""; STATE_AI_EMIT="n/a"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

  # Test 15: phase_assert_output_set — pre-commit close-out output-set
  # completeness (#5288). Offline, hermetic, credential-free.
  #
  # WHAT THIS GROUP HAS TO PROVE, beyond "the phase can fail". Three things the
  # design turns on, each of which is silently defeatable:
  #   (1) the `required-if` predicate is READ FROM deploy.sh, not copied — so
  #       arming the cutover stays a one-value change and an UNREADABLE seam
  #       BLOCKS instead of grading the row N/A-satisfied;
  #   (2) a `**Not-produced:**` marker is EVIDENCE and never an EXEMPTION —
  #       asserted differentially, with the marker provably present;
  #   (3) the dry-run classifier is TOTAL and fails CLOSED — the get_phase
  #       not-found sentinel returns at exit 0, so an unrecorded phase is a
  #       VALUE this classifier must handle, not an error it can lean on.
  #
  # FIXTURE VERSIONS ARE DELIBERATELY v9.8x, NOT v9.9x. The velocity/learnings
  # group asserts Deployment Log field ORDER by exact string equality over every
  # bold key in its v9.95 / v9.93 blocks. A `**Not-produced:**` marker matches
  # that same key pattern, so seeding one into those fixtures would shift the
  # sequence under the literals and redden a sibling group. Separate blocks.
  local _os_s_log="$RELEASE_LOG" _os_s_ver="$VERSION" _os_s_mode="$MODE"
  local _os_s_sl="$SYNTHESIZE_LEARNINGS" _os_s_src="$CLOSE_COMPLETENESS_SOURCE"
  local _os_s_cut="${CLOSE_COMPLETENESS_TELEMETRY_CUTOFF:-}"
  local _os_tmp; _os_tmp="$(/usr/bin/mktemp -d -t outputset-selftest.XXXXXX)"
  MODE="apply"; VERSION="v9.80"; RELEASE_LOG="$_os_tmp/RELEASE_LOG.md"
  unset CLOSE_COMPLETENESS_TELEMETRY_CUTOFF

  # Fixture writer. `$1` selects which members are PRESENT.
  local _os_write
  _os_write() {
    /bin/cat > "$RELEASE_LOG" <<EOF
# RELEASE_LOG

#### Deployment Log v9.80
**Mechanism:** git merge.
**Cycle-Time:** 2d 0h.
$( [[ "$1" == *vel* ]] && echo '**Velocity:** planned 4 pts / delivered 4 pts (1.00); class routine; mechanism: compute-release-velocity.sh' )
**Result:** SUCCESS — fixture.
$( [[ "$1" == *cct* ]] && echo '**Close-Class-Telemetry:** retro-conformance N/A; mechanism: compute-close-class-telemetry.sh' )
EOF
    if [[ "$1" == *lrn* ]]; then
      /bin/cat >> "$RELEASE_LOG" <<'EOF'

#### Release Learnings v9.80
**Source events:** 1 row.
EOF
    fi
  }
  # Drive the phase in a clean record. The exit status lands in the GLOBAL
  # _OS_RC and the verdict is read from the parent's phase record afterwards —
  # deliberately NOT `$(...)`, which would run the drive in a subshell and leave
  # every later `get_phase` in this group reading the empty-record sentinel.
  local _os_drive _os_verdict
  _os_drive() {
    PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
    _OS_RC=0
    phase_assert_output_set >/dev/null 2>&1 || _OS_RC=$?
  }
  _os_verdict() { /usr/bin/printf '%s %s' "$_OS_RC" "$(get_phase assert_output_set | /usr/bin/cut -d'|' -f1)"; }

  # ── (m1) THE SEAM. The cutoff is READ out of deploy.sh, never copied here.
  # The subject is the shipped reader; the oracle is a SECOND, INDEPENDENT
  # extractor (awk, not sed) over the same governed file — so this is not the
  # subject serving as its own control.
  CLOSE_COMPLETENESS_SOURCE="$REPO_ROOT/core/deploy/deploy.sh"
  local _os_read _os_oracle
  _os_read="$(_resolve_telemetry_cutoff || echo "<UNREADABLE>")"
  # The oracle must skip COMMENT lines. deploy.sh's read-contract note documents
  # the frozen shape by quoting it, so a naive matcher reads the DOCUMENTATION's
  # `<default>` placeholder instead of the live assignment. The shipped reader is
  # already immune (it anchors on leading whitespace, which `#` is not); this
  # oracle has to be made immune independently or it is not an oracle.
  _os_oracle="$(/usr/bin/awk -F'CLOSE_COMPLETENESS_TELEMETRY_CUTOFF:-' '/^[[:space:]]*local cc_telemetry_cutoff=/ { v = $2; sub(/}".*$/, "", v); print v; exit }' "$CLOSE_COMPLETENESS_SOURCE" 2>/dev/null)"
  [[ -n "$_os_oracle" ]] || { echo "FAIL: #5288 m1 anti-vacuity — the independent oracle read NOTHING from deploy.sh, so agreement with it would prove nothing"; failures=$((failures+1)); }
  [[ "$_os_read" == "$_os_oracle" ]] || { echo "FAIL: #5288 m1 — the shipped reader must return deploy.sh's OWN committed default; reader='$_os_read' independent-oracle='$_os_oracle'"; failures=$((failures+1)); }
  # SENSITIVITY: point the seam at an ARMED fixture. A reader that hardcoded the
  # shipped `__none__` passes m1 and fails here.
  local _os_fake="$_os_tmp/deploy-armed.sh" _os_none="$_os_tmp/deploy-noline.sh" _os_dup="$_os_tmp/deploy-dup.sh"
  /usr/bin/printf '%s\n' '  local cc_telemetry_cutoff="${CLOSE_COMPLETENESS_TELEMETRY_CUTOFF:-v9.01}"' > "$_os_fake"
  /usr/bin/printf '%s\n' '  local something_else="nothing to see"' > "$_os_none"
  /bin/cat > "$_os_dup" <<'EOF'
  local cc_telemetry_cutoff="${CLOSE_COMPLETENESS_TELEMETRY_CUTOFF:-v9.01}"
  local cc_telemetry_cutoff="${CLOSE_COMPLETENESS_TELEMETRY_CUTOFF:-v9.02}"
EOF
  CLOSE_COMPLETENESS_SOURCE="$_os_fake"
  [[ "$(_resolve_telemetry_cutoff || echo "<UNREADABLE>")" == "v9.01" ]] || { echo "FAIL: #5288 m1 sensitivity — an ARMED seam must resolve to its own value, not to a hardcoded default"; failures=$((failures+1)); }
  # SPECIFICITY: a broken shape resolves NOTHING and says so — it never defaults.
  CLOSE_COMPLETENESS_SOURCE="$_os_none"
  local _os_rc1=0; _resolve_telemetry_cutoff >/dev/null 2>&1 || _os_rc1=$?
  [[ "$_os_rc1" -ne 0 ]] || { echo "FAIL: #5288 m1 specificity — a deploy.sh with no cutoff assignment must resolve UNREADABLE, not a silent default"; failures=$((failures+1)); }
  CLOSE_COMPLETENESS_SOURCE="$_os_dup"
  local _os_rc2=0; _resolve_telemetry_cutoff >/dev/null 2>&1 || _os_rc2=$?
  [[ "$_os_rc2" -ne 0 ]] || { echo "FAIL: #5288 m1 ambiguity — TWO cutoff assignments must resolve UNREADABLE, never a guess at which one is live"; failures=$((failures+1)); }

  # ── (m2) AN UNEVALUABLE PREDICATE BLOCKS. This is the arm that proves the
  # `required-if` state is not a fail-open hole: both `required` members are
  # PRESENT, so the ONLY thing wrong is that the membership test could not run.
  _os_write "vel lrn"
  CLOSE_COMPLETENESS_SOURCE="$_os_none"
  local _os_r; _os_drive; _os_r="$(_os_verdict)"
  [[ "$_os_r" == "3 FAIL" ]] || { echo "FAIL: #5288 m2 — an UNREADABLE membership predicate must BLOCK (expected '3 FAIL'), got '$_os_r'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'INDETERMINATE' <<<"$(get_phase assert_output_set)" || { echo "FAIL: #5288 m2 — the block must be reported as INDETERMINATE naming the missing element, got '$(get_phase assert_output_set)'"; failures=$((failures+1)); }
  # CONTROL, same fixture, one variable changed: a READABLE dormant seam PASSes.
  # Without this the m2 block is indistinguishable from a gate that always fails.
  CLOSE_COMPLETENESS_SOURCE="$REPO_ROOT/core/deploy/deploy.sh"
  _os_drive; _os_r="$(_os_verdict)"
  [[ "$_os_r" == "0 PASS" ]] || { echo "FAIL: #5288 m2 control — a READABLE dormant seam over a complete fixture must PASS (expected '0 PASS'), got '$_os_r'"; failures=$((failures+1)); }

  # ── (m3) AC-3: a required member ABSENT blocks; present passes (paired).
  _os_write "lrn"
  _os_drive; _os_r="$(_os_verdict)"
  [[ "$_os_r" == "3 FAIL" ]] || { echo "FAIL: #5288 m3 — an ABSENT required member must BLOCK, got '$_os_r'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'velocity-field' <<<"$(get_phase assert_output_set)" || { echo "FAIL: #5288 m3 — the finding must NAME the missing member, got '$(get_phase assert_output_set)'"; failures=$((failures+1)); }
  _os_write "vel"
  _os_drive; _os_r="$(_os_verdict)"
  [[ "$_os_r" == "3 FAIL" ]] || { echo "FAIL: #5288 m3 — an ABSENT learnings block must BLOCK, got '$_os_r'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'learnings-block' <<<"$(get_phase assert_output_set)" || { echo "FAIL: #5288 m3 — the finding must NAME the missing learnings block, got '$(get_phase assert_output_set)'"; failures=$((failures+1)); }

  # ── (m4) AC-5: membership separates required from not-owed. ONE variable moves
  # between the two runs — the cutoff value — so the differing verdicts are
  # attributable to membership and to nothing else.
  _os_write "vel lrn"
  CLOSE_COMPLETENESS_TELEMETRY_CUTOFF="v9.01"
  _os_drive; _os_r="$(_os_verdict)"
  [[ "$_os_r" == "3 FAIL" ]] || { echo "FAIL: #5288 m4 — an ARMED required-if predicate makes the member OWED, so its absence must BLOCK, got '$_os_r'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'close-class-telemetry' <<<"$(get_phase assert_output_set)" || { echo "FAIL: #5288 m4 — the armed finding must NAME the telemetry member, got '$(get_phase assert_output_set)'"; failures=$((failures+1)); }
  CLOSE_COMPLETENESS_TELEMETRY_CUTOFF="__none__"
  _os_drive; _os_r="$(_os_verdict)"
  [[ "$_os_r" == "0 PASS" ]] || { echo "FAIL: #5288 m4 — a FALSE required-if predicate resolves N/A, a SATISFIED state that must not block, got '$_os_r'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'N-A (predicate false' <<<"$(get_phase assert_output_set)" || { echo "FAIL: #5288 m4 — a not-owed member must be REPORTED as N-A rather than silently omitted, got '$(get_phase assert_output_set)'"; failures=$((failures+1)); }
  unset CLOSE_COMPLETENESS_TELEMETRY_CUTOFF

  # ── (m5) THE MARKER IS EVIDENCE, NEVER AN EXEMPTION. The load-bearing arm.
  # Differential over ONE fixture: the learnings block is absent throughout, and
  # the only thing that changes between the two drives is that a real marker is
  # recorded. The verdict must NOT move.
  _os_write "vel"
  _os_drive; _os_r="$(_os_verdict)"
  [[ "$_os_r" == "3 FAIL" ]] || { echo "FAIL: #5288 m5 pre-arm — the absent member must block BEFORE a marker exists, got '$_os_r'"; failures=$((failures+1)); }
  _write_not_produced_marker "learnings-block" "append_release_learnings" "self-test fixture" >/dev/null 2>&1 || true
  # SENSITIVITY: the arm is only meaningful if a marker is genuinely present.
  _not_produced_marker_present "learnings-block" || { echo "FAIL: #5288 m5 sensitivity — no marker was actually recorded, so the exemption arm below would pass vacuously"; failures=$((failures+1)); }
  _os_drive; _os_r="$(_os_verdict)"
  [[ "$_os_r" == "3 FAIL" ]] || { echo "FAIL: #5288 m5 — A MARKER MUST NOT SATISFY THE GATE. With the marker recorded and the member still absent, the verdict must be unchanged (expected '3 FAIL'), got '$_os_r'"; failures=$((failures+1)); }
  # And the gate must have SEEN it — a verdict unchanged because the marker was
  # invisible would prove nothing about exemption.
  /usr/bin/grep -qF 'Not-produced marker recorded' <<<"$(get_phase assert_output_set)" || { echo "FAIL: #5288 m5 — the gate must REPORT the marker it read (evidence), while still blocking; got '$(get_phase assert_output_set)'"; failures=$((failures+1)); }
  # SPECIFICITY, the converse direction: supply the member and the SAME marker
  # stays present, yet the gate now passes — so the marker is inert in both
  # directions and the m5 block is caused by absence, not by the marker.
  local _os_saved_marker; _os_saved_marker="$(/usr/bin/grep -F '**Not-produced:** learnings-block' "$RELEASE_LOG" || true)"
  _os_write "vel lrn"
  /usr/bin/printf '%s\n' "$_os_saved_marker" >> "$RELEASE_LOG"
  _os_drive; _os_r="$(_os_verdict)"
  [[ "$_os_r" == "0 PASS" ]] || { echo "FAIL: #5288 m5 specificity — with the member PRESENT the same marker must be inert and the gate must PASS, got '$_os_r'"; failures=$((failures+1)); }

  # ── (m6) EMIT ON ABSENCE, at the real producer site. A non-executable
  # synthesizer must leave a `**Not-produced:**` line in the block, anchored
  # immediately after `**Result:**` — the declared anchor.
  _os_write "vel"
  SYNTHESIZE_LEARNINGS="$_os_tmp/definitely-not-here.sh"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_append_release_learnings >/dev/null 2>&1 || true
  [[ "$(get_phase append_release_learnings)" == SKIPPED\|* ]] || { echo "FAIL: #5288 m6 — the capability arm must still SKIP (the refusal to hand-compose stands), got '$(get_phase append_release_learnings)'"; failures=$((failures+1)); }
  _not_produced_marker_present "learnings-block" || { echo "FAIL: #5288 m6 — a capability skip must now RECORD the absence as corpus bytes; no **Not-produced:** marker was written"; failures=$((failures+1)); }
  local _os_after; _os_after="$(/usr/bin/awk '/^\*\*Result:\*\*/ { getline; print; exit }' "$RELEASE_LOG")"
  [[ "$_os_after" == '**Not-produced:** learnings-block'* ]] || { echo "FAIL: #5288 m6 — the marker must land at its DECLARED anchor, immediately after **Result:**; the following line was '$_os_after'"; failures=$((failures+1)); }
  # CONTROL: a WORKING producer writes no marker, so the marker tracks the
  # capability condition rather than firing on every run. The synthesizer is
  # minted HERE rather than reused from the velocity group — that group removes
  # its own sandbox before this one runs, so its path is a dangling reference.
  local _os_sl_ok="$_os_tmp/sl-ok.sh"
  /bin/cat > "$_os_sl_ok" <<'EOF'
#!/bin/sh
V=""
while [ $# -gt 0 ]; do case "$1" in --version) V="$2"; shift 2 ;; *) shift ;; esac; done
cat <<INNER
#### Release Learnings $V

**Synthesized at:** 2026-08-21T00:00:00Z
**Source events:** 1 row.
**Source-row anchors:** row 1
**Surprise:** none.
**Would-change:** nothing.
**Watch-for:** nothing.

INNER
EOF
  /bin/chmod +x "$_os_sl_ok"
  _os_write "vel"
  SYNTHESIZE_LEARNINGS="$_os_sl_ok"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  phase_append_release_learnings >/dev/null 2>&1 || true
  ! _not_produced_marker_present "learnings-block" || { echo "FAIL: #5288 m6 control — a SUCCESSFUL render must write no marker; the marker is not tracking the capability condition"; failures=$((failures+1)); }
  SYNTHESIZE_LEARNINGS="$_os_s_sl"

  # ── (m7) MODE POSTURE — the release-wide dry-run/apply ruling. Same fixture,
  # same missing member: WARN and rc 0 under --dry-run, FAIL and rc 3 at --apply.
  _os_write "lrn"
  MODE="dry-run"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  mark_phase "inject_velocity_field" "DRY-RUN" "would FAIL: fixture producer unavailable"
  local _os_drc=0; phase_assert_output_set >/dev/null 2>&1 || _os_drc=$?
  [[ "$_os_drc" -eq 0 ]] || { echo "FAIL: #5288 m7 — --dry-run must be NON-blocking (return 0), got $_os_drc"; failures=$((failures+1)); }
  [[ "$(get_phase assert_output_set | /usr/bin/cut -d'|' -f1)" == "WARN" ]] || { echo "FAIL: #5288 m7 — a would-be-absent required member under --dry-run must mark WARN per the in-file non-blocking-preview precedent, got '$(get_phase assert_output_set)'"; failures=$((failures+1)); }
  /usr/bin/grep -qF 'FAILS the close at --apply' <<<"$(get_phase assert_output_set)" || { echo "FAIL: #5288 m7 — the dry-run WARN must name the condition that fails at --apply, got '$(get_phase assert_output_set)'"; failures=$((failures+1)); }
  MODE="apply"
  _os_drive; _os_r="$(_os_verdict)"
  [[ "$_os_r" == "3 FAIL" ]] || { echo "FAIL: #5288 m7 anti-vacuity — the SAME fixture at --apply must FAIL and return 3, got '$_os_r'"; failures=$((failures+1)); }

  # ── (m8) THE DRY-RUN CLASSIFIER IS TOTAL AND FAILS CLOSED. get_phase returns
  # its not-found sentinel at EXIT 0, so an unrecorded producing phase is a VALUE
  # the classifier must handle. Unhandled, it would read as neither-absent and
  # green a preview over an incomplete set.
  MODE="dry-run"
  _os_write "lrn"
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  [[ "$(_output_set_dryrun_class velocity-field inject_velocity_field)" == indeterminate:* ]] || { echo "FAIL: #5288 m8 — an UNRECORDED producing phase must classify INDETERMINATE, got '$(_output_set_dryrun_class velocity-field inject_velocity_field)'"; failures=$((failures+1)); }
  _os_drc=0; phase_assert_output_set >/dev/null 2>&1 || _os_drc=$?
  [[ "$(get_phase assert_output_set | /usr/bin/cut -d'|' -f1)" == "WARN" ]] || { echo "FAIL: #5288 m8 — an INDETERMINATE classification must surface (WARN under --dry-run), never green, got '$(get_phase assert_output_set)'"; failures=$((failures+1)); }
  # CONTROL: a RECORDED pass classifies would-present, so the INDETERMINATE above
  # is a real discrimination and not a classifier that answers one way always.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  mark_phase "inject_velocity_field" "PASS" "wrote the field"
  [[ "$(_output_set_dryrun_class velocity-field inject_velocity_field)" == "would-present" ]] || { echo "FAIL: #5288 m8 control — a PASS record must classify would-present, got '$(_output_set_dryrun_class velocity-field inject_velocity_field)'"; failures=$((failures+1)); }
  # And the ambiguous SKIPPED result is resolved by the TREE, not by detail prose:
  # the SAME result string classifies differently on a present vs absent member.
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()
  mark_phase "inject_velocity_field" "SKIPPED" "already present"
  _os_write "vel"
  [[ "$(_output_set_dryrun_class velocity-field inject_velocity_field)" == "would-present" ]] || { echo "FAIL: #5288 m8 — SKIPPED over a PRESENT member is would-present (the idempotency arm), got '$(_output_set_dryrun_class velocity-field inject_velocity_field)'"; failures=$((failures+1)); }
  _os_write "lrn"
  [[ "$(_output_set_dryrun_class velocity-field inject_velocity_field)" == "would-absent" ]] || { echo "FAIL: #5288 m8 — the SAME SKIPPED string over an ABSENT member is would-absent; the classifier is reading the detail prose instead of the tree, got '$(_output_set_dryrun_class velocity-field inject_velocity_field)'"; failures=$((failures+1)); }
  MODE="apply"

  # ── (m9) ROSTER<->DISPATCH parity for the new phase. Nothing in this file
  # asserts that parity generally, so `--help` silently under-reports a phase
  # added to the ladder. Shipped 9.55 row is the interpretability control.
  local _os_roster; _os_roster="$(/usr/bin/awk 'NR==1 {next} /^#/ {sub(/^# ?/, ""); print; next} {exit}' "${BASH_SOURCE[0]}")"
  /usr/bin/grep -qE '^[[:space:]]*9\.56 assert_output_set' <<<"$_os_roster" || { echo "FAIL: #5288 m9 — the hand-maintained usage()/--help phase roster must carry the 9.56 row"; failures=$((failures+1)); }
  /usr/bin/grep -qE '^[[:space:]]*9\.55 assert_derived_surfaces' <<<"$_os_roster" || { echo "FAIL: #5288 m9 control — the shipped 9.55 row is missing, so the roster extraction itself is broken and the 9.56 result above is uninformative"; failures=$((failures+1)); }

  # ── (m10) READ-ONLY. The phase must not write or stage. Compared by content
  # hash, with an anti-vacuity arm proving the same instrument DOES move when a
  # byte changes — otherwise "unchanged" could mean "the hash never changes".
  _os_write "vel lrn"
  local _os_h1 _os_h2 _os_h3
  _os_h1="$(/usr/bin/shasum "$RELEASE_LOG" | /usr/bin/cut -d' ' -f1)"
  _os_drive; _os_r="$(_os_verdict)"
  _os_h2="$(/usr/bin/shasum "$RELEASE_LOG" | /usr/bin/cut -d' ' -f1)"
  [[ "$_os_r" == "0 PASS" ]] || { echo "FAIL: #5288 m10 precondition — the read-only arm needs a PASSing run, got '$_os_r'"; failures=$((failures+1)); }
  [[ "$_os_h1" == "$_os_h2" ]] || { echo "FAIL: #5288 m10 — phase_assert_output_set MUST be read-only; the ledger changed across the run"; failures=$((failures+1)); }
  _write_not_produced_marker "velocity-field" "inject_velocity_field" "anti-vacuity" >/dev/null 2>&1 || true
  _os_h3="$(/usr/bin/shasum "$RELEASE_LOG" | /usr/bin/cut -d' ' -f1)"
  [[ "$_os_h3" != "$_os_h1" ]] || { echo "FAIL: #5288 m10 anti-vacuity — the hash instrument did not move on a KNOWN write, so the unchanged result above is not a measurement"; failures=$((failures+1)); }

  # ── (m11) THE GUARD, AND ITS WINDOW. The gate is only a gate because the
  # dispatch line carries the fail-closed guard, and it only closes THIS defect
  # because it sits after the producers and before the chore commit. Both read
  # from this file's own shipped text.
  local _os_disp; _os_disp="$(grep_count -E '^phase_assert_output_set \|\| \{ generate_report; exit 3; \}' "${BASH_SOURCE[0]}")"
  [[ "$_os_disp" -eq 1 ]] || { echo "FAIL: #5288 m11 — expected EXACTLY ONE guarded top-level dispatch of phase_assert_output_set, found $_os_disp"; failures=$((failures+1)); }
  local _os_ln_ads _os_ln_new _os_ln_commit
  # The trailing `head -1` folds into `grep -m1`: grep reads the FILE directly, so it
  # is the leftmost producer and no upstream writer is left for an early-closing
  # consumer to signal, while `cut` drains what remains. Selection-preserving because
  # no needle here carries `-o` — `-m` bounds matching LINES, not matches.
  _os_ln_ads="$(/usr/bin/grep -m1 -nE '^phase_assert_derived_surfaces \|\|' "${BASH_SOURCE[0]}" | /usr/bin/cut -d: -f1)"
  _os_ln_new="$(/usr/bin/grep -m1 -nE '^phase_assert_output_set \|\|' "${BASH_SOURCE[0]}" | /usr/bin/cut -d: -f1)"
  _os_ln_commit="$(/usr/bin/grep -m1 -nE '^phase_commit_chore_pr \|\|' "${BASH_SOURCE[0]}" | /usr/bin/cut -d: -f1)"
  [[ -n "$_os_ln_ads" && -n "$_os_ln_new" && -n "$_os_ln_commit" ]] || { echo "FAIL: #5288 m11 anti-vacuity — one of the three dispatch needles resolved to nothing, so the ordering assert below is unfalsifiable"; failures=$((failures+1)); }
  [[ "$_os_ln_new" -gt "$_os_ln_ads" && "$_os_ln_new" -lt "$_os_ln_commit" ]] || { echo "FAIL: #5288 m11 — phase 9.56 must dispatch AFTER assert_derived_surfaces and BEFORE commit_chore_pr, or the stamp commits ahead of the assert (ads=$_os_ln_ads new=$_os_ln_new commit=$_os_ln_commit)"; failures=$((failures+1)); }
  local _os_fab; _os_fab="$(grep_count -E '^phase_assert_output_set_zz \|\|' "${BASH_SOURCE[0]}")"
  [[ "$_os_fab" -eq 0 ]] || { echo "FAIL: #5288 m11 specificity — a fabricated phase name matched $_os_fab dispatch lines, so the needle is over-matching"; failures=$((failures+1)); }

  unset -f _os_write _os_drive 2>/dev/null || true
  /bin/rm -rf "$_os_tmp" 2>/dev/null || true
  RELEASE_LOG="$_os_s_log"; VERSION="$_os_s_ver"; MODE="$_os_s_mode"
  SYNTHESIZE_LEARNINGS="$_os_s_sl"; CLOSE_COMPLETENESS_SOURCE="$_os_s_src"
  if [[ -n "$_os_s_cut" ]]; then CLOSE_COMPLETENESS_TELEMETRY_CUTOFF="$_os_s_cut"; else unset CLOSE_COMPLETENESS_TELEMETRY_CUTOFF; fi
  STATE_OUTPUT_SET_ROWS=""
  PHASE_NAMES=(); PHASE_RESULTS=(); PHASE_DETAILS=()

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
  echo "  phase_append_release_digest + phase_append_release_index + phase_append_changelog validated (#667 F3/F6 — DIGEST H3 under topmost H2 / INDEX 6-col single-row / idempotency; #2048 — version-less marker + _unversioned notes link + marker-aware idempotency + CHANGELOG SKIP; #4455 — all three entries PROJECTED by generate_release_index.py, versioned CHANGELOG block lands above the prior entry WITH its separating blank line intact, re-run SKIPs, and a non-owner/repo-shaped REPO_SLUG FAILs before writing a broken Release URL)" >&2
  echo "  phase_inject_outcome_field validated (#37 — default-SUCCESS after Result / non-SUCCESS-no-rationale FAIL / non-SUCCESS+rationale both-lines / unknown-enum reject / idempotency / block-scoped; #3715 two-surface — archived body resolves to its segment and the hot ledger is left untouched / cross-surface idempotency re-run SKIPs without duplicating / a genuine **Result:** absence still hard-FAILs naming every surface searched / no sibling leak within a segment); Outcome KEY GRAMMAR validated (#4222 — k1 a QUALIFIED key is recognized and REJECTED at --apply leaving the record byte-unchanged, with an EXECUTABLE SENSITIVITY arm re-demonstrating on every run that the pre-fix bare-literal probe reads the same fixture as ABSENT and would inject the second line / k2 the bare path is unregressed (SKIP, no write) with a SPECIFICITY arm proving an Outcome-less block still injects exactly one / k3 phase 6.8 anchors under a qualified key, asserted on the RAW line because the field-name class used elsewhere cannot see parentheses, with the bare-key fallback as its control / k4 ONE RESOLVER, TWO SITES: extending the shared key constant moves BOTH the 6.5 probe and the 6.8 anchor, and at the default constant the same key is accepted at NEITHER — a one-site fix fails here / k5 grammar non-collision asserted in BOTH directions against the real sibling field **Outcome rationale:** / k6 raw-prefix fidelity — an INDENTED key classifies and anchors through the UNCHANGED primitive, with the unindented twin as control / k7 both-present classifies DUPLICATE and FAILs writing nothing, control: bare-only raises no duplicate diagnostic / k8 three PRESENT-BUT-UNPARSEABLE shapes (nested paren, doubled space, missing space) classify UNPARSEABLE rather than ABSENT and stop the write, control: a genuine absence still injects / k9 NO EMPTY ANCHOR REACHES THE PRIMITIVE — an unresolvable anchor FAILs loudly instead of landing the field at the top of the block, paired with an ANTI-VACUITY arm that hands the unchanged primitive an empty anchor and demonstrates it exits 0 writing to the top, so k9 is a measurement and not a tautology / k10 MODE: --dry-run returns 0 and marks WARN naming the condition that FAILS at --apply, control: the same fixture at --apply returns 3 and marks FAIL / k11 the governance constant is hard-assigned, not env-overridable, scoped to the production region with an anti-vacuity control on the known-bad form)" >&2
  echo "  phase_inject_velocity_field + phase_append_release_learnings validated (velocity — field ORDER 'Cycle-Time Velocity Result' on a clean block / no sibling leak / idempotent re-run / bolded-numeral value REJECTED writing nothing / empty capture at exit 0 degrades to an explicit N/A never a bare field / non-conformant existing field SKIPs WITH the warning, conformant control WITHOUT it; CO-LOCATION — an archived block's field lands in the SEGMENT beside its own **Result:** and the hot stub stays at 0, cross-surface re-run SKIPs, dry-run names the segment and prints the RESOLVED bytes. learnings — sibling H4 placed IMMEDIATELY after its Deployment Log block / body intact through the sentinel capture / idempotent re-run / whitespace-only render at exit 0 FAILs writing nothing / D-1 zero-source-events BLOCKS the close and prints the capture remedy, >0-events control PASSes / over an ARCHIVED block the block still lands in the HOT ledger and every segment stays at 0 Release Learnings — RECORDS_POLICY KEEP_CLASS. A7 capture gate — the SAME 0-source-event condition read at Phase 2 by _learnings_capture_gap reports a gap, >0-events control does NOT / an already-placed block is NOT a gap even under the 0-event stub, block-removed sensitivity IS / neither a missing synthesizer nor a whitespace-only render escalates to a gap / phase_preflight actually CALLS the predicate and is dispatched before create_chore_branch and transition_release_log, both derived from the shipped text with fabricated-symbol controls / n.1 THE MANDATED WARN SHAPE — the Collective-Review dry-run posture asserted over that same shipped text in three limbs, one per half of the ruling: the WARN result TOKEN (a regression back to PASS reddens here and nowhere else), the NON-BLOCKING return bound to the WARN line BY CONTEXT (phase_preflight carries two bare 'return 0' lines, so an unbound grep measures nothing), and the TAIL CLAUSE naming what FAILS at --apply, with a fabricated-result-token specificity control / GATE-BACKSTOP PARITY over the placed x synth-absent x synth-empty x render-0 x render-N matrix — a gap implies 6.7 returns 3, with a non-vacuity control asserting the antecedent actually fired)" >&2
  echo "  phase_inject_velocity_field EXIT-CLASS contract validated (#4927, group 4c.5b — this line is the group's conformant-arm extraction, without which a passing run is indistinguishable from a run in which the group never executed): (p) a producer exit 2 FAILs at --apply, returns 3 so the runner halts, writes NOTHING, and quotes the producer's OWN stderr rather than a generic message — with a control proving the same fixture PASSes and writes exactly one field under a conformant producer, so the arm is not just a phase that always fails / (q) the same exit 2 under --dry-run marks a NON-blocking WARN that names the condition failing at --apply, and still writes nothing / (r) exit 2 is never laundered into the explicit 'N/A' form — a refusal to measure must not be recorded as a measurement — with a SENSITIVITY arm requiring exit 1 to STILL degrade to N/A at PASS, so a blanket fail-on-any-nonzero phase reddens here instead of passing / (s) a successful run's stderr still reaches the run report, so a DEGRADED Phase-A2 planned-recovery (which under-reports 'planned' and makes the ratio look healthier than the truth) is visible rather than discarded, with a control proving a silent producer manufactures no note" >&2
  echo "  phase_inject_close_class_telemetry_field validated (#4437 — clean block PASSes with the field positioned after **Outcome rationale:** and no sibling leak / idempotent re-run SKIPs / fallback anchor lands after **Outcome:** and names which anchor it used / VACUITY PAIR: an all-N/A-but-conformant line is WRITTEN and carries the no-computed-ratio warning WITH the disposition read from the emitted line, measured-line control carries NO warning / a line missing § 3.2 slots FAILs writing nothing / an empty capture at exit 0 FAILs writing nothing / producer exit 2 escalates as a source-integrity condition writing nothing / a non-executable producer SKIPs rather than hand-composing a field that would fabricate its own mechanism claim / dry-run prints the RESOLVED bytes and writes nothing / CO-LOCATION: an archived block's field lands in the SEGMENT beside its own **Result:** with the hot stub at 0, and the cross-surface re-run SKIPs; #5288 AI-028 NOT-PRODUCED MARKER STAGING — j.1 drives the REAL 6.8 call site over an archived block with the producer unavailable and asserts the resolved SEGMENT reaches TOUCHED_ARCHIVE_SEGMENTS, the array files=() consumes, with a sensitivity floor proving the marker genuinely reached the segment (pre-fix the marker still lands on disk, so the differential isolates the LOST APPEND alone) and a HOT-LEDGER control proving the by-design skip is preserved and the recorder is not appending every target it is handed / j.2 STRUCTURAL over the shipped text of BOTH calling phases — neither may invoke the writer inside a command substitution, read from the FUNCTION BODIES so the needle cannot match itself, with per-site vacuity floors and a capability-to-fail arm matching a CONSTRUCTED bad call site so a clean reading is a measurement)" >&2
  echo "  phase_detect_open_issues exclude filter validated (#38 — explicit --exclude-issue / Stage-13-subtask sub-task-label+title-regex / AC-4 mixed fixture / decoy-not-over-excluded / per-issue --close-comment; #3665 — delivered Stage-13-titled work item survives / type:subtask alias excluded / label-alone-does-not-exclude control / both-conjunct exclusion detail); ARMED-gate classified (#2539/A6.5 — correct slug counts real issues, mis-resolved Version reproduces historical false-0); check-5 post-close re-read validated (#3587 — PASS after drain / live PARTIAL enumerates stragglers / UNVERIFIED fail-closed / pre-close globals unclobbered / dry-run reads cache)" >&2
  echo "  post_gate_passage_proof three-rung target ladder validated (#3819 — T-13 rung 1 resolves a CLOSED Stage-13 sub-task via --state all and does NOT fall through to the PR / rung 2 posts to the release PR naming the OBSERVED rung-1 reason / rung 3 MANUAL names BOTH attempted targets; T-14 two collect_open_release_issues calls in one run keep EXCLUDED_DETAIL undoubled, COLLECTED_OPEN_ISSUES identical and resolve_stage13_subtask stable, with a non-empty-exclusion anti-vacuity control)" >&2
  echo "  phase_action_item_gate validated (#4439, group AI — 21 arms; this line is the group's conformant-arm extraction, without which a passing run is indistinguishable from a run in which the group never executed): A and B are each other's control over ONE differential harness where only the ledger changes — a gate that never blocks fails A, one that always blocks fails B, one reading the wrong path resolves NOT-RECORDED for both and fails BOTH / B2 decoy: a terminal ledger carrying the literal words 'open' and 'in-flight' in trigger_detail still resolves RESOLVED, so the gate is column-addressed and not row-pattern-matched / all four verdict states drive distinct fixtures and are asserted on the STATE_AI_GATE global rather than the detail prose — UNRESOLVED (A) · RESOLVED (B, B2) · NOT-RECORDED (C unattested blocks, C2 attested passes WARN with the operator-actor attestation EMITTED carrying its cause and the spec subtype) · EMPTY-LEDGER (D unattested blocks, D2 attested round-trips the second cause) / E the two SURFACE states must resolve DISTINCT values, because comparing detail strings passes on any two different sentences / E2 an unlicensed attestation cause does NOT clear a SURFACE state / F EXECUTES the two dispatch lines lifted VERBATIM from this file's own text, refusing to pass unless each needle resolves to exactly one top-level line, under three mutually-controlling limbs — F1 blocking gate leaves the close UNFIRED at exit 3, F2 SENSITIVITY a passing gate does fire it (without which F1's clean result is meaningless), F3 NEGATIVE CONTROL a constructed '|| true' line must let the close through (without which a fail-closed gate is indistinguishable from a no-op one) — so capability-to-fail is re-demonstrated on EVERY run, not only under one-time mutation / F4 whole-block invariant: every top-level dispatch line carries the fail-closed guard, with an anti-vacuity floor on the parse and a specificity control proving the filter rejects an unguarded line / G doc<->code parity on the canonical Procedure 7a predicate across the fixture set, with an anti-vacuity floor on the extraction and a sensitivity arm requiring >=4 distinct STATEs / H --dry-run never returns non-zero yet still EVALUATES, and names the condition that would FAIL at --apply / I an idempotent re-run over an already-closed milestone, where an UNRESOLVED verdict is the close-before-verdict shape itself / J --no-merge still evaluates and records rather than blocks / K Verification row 6 reads the Phase-12.9 GLOBAL — unset renders UNVERIFIED never a green cell, mutating the global moves the cell, and phase_run_verification is asserted NOT to re-evaluate the predicate after the close / L an attestation does NOT clear an UNRESOLVED verdict — an open row is dispositioned, never attested away / P operator-instance path tokenisation, with a sensitivity arm proving the leak probe can match its own needle" >&2
  echo "  phase_await_merge_chore_pr budget/escape validated (#1705 — zero-commit SKIP propagation / --no-merge SKIP / BLOCKED→CLEAN keep-poll merges / CONFLICTING HALT)" >&2
  echo "  --no-merge post-merge phase-gating validated (#2919 — post_close_milestone / manual_close_release_issues / publish_github_release / check_release_body_drift DEFER under --no-merge, even with open milestone/issues; NO_MERGE=0 negative)" >&2
  echo "  phase_transition_release_log VERIFIED re-derivation validated (#1681 — VERIFIED+merged-PR SKIP / VERIFIED+unmerged-PR FAIL false-VERIFIED / DEPLOYED normal transition); #2539 end-to-end validated (AC-2 pure-alpha resolve+flip / AC-3 dry-run<=>apply parity + no-match negative / D-3 true-count over-match fires)" >&2
  echo "  phase_ledger_guard + phase_reparse_ledgers validated (#1680 — clean-diff PASS / I1 foreign-row-removal FAIL / I2 VERIFIED→DEPLOYED FAIL / well-formed reparse PASS / duplicate-H3 reparse FAIL)" >&2
  echo "  phase_rebuild_skill_packages detection + files=() composition validated (#4722 — core/schemas sensitivity / core/standards control / rule-a direct-source / specificity negative / C1 dry-run WARN vs apply FAIL / delegation structure / P1 staging-array guard; #4755 — a5 _shared filter sensitivity (a non-skill dir under a skills/ root resolves NO candidate) / a6 _templates second-directory proving the filter is a roster-resolvability test and not a hardcoded _shared exclusion / a7 mixed set keeps the buildable candidate and drops the unbuildable one (anti-over-filtering) / d1 --apply anti-regression: a roster-resolvable skill that cannot build still returns 3, marks FAIL, and names ITSELF / d2 the converse in the same sandbox and mode: a filtered-out candidate reaches the N/A limb at rc 0 / c5 build-invocation shape — per-skill loop over \$candidates, --root passed on the BUILD call, failures accumulated by name in _rb_failed)" >&2
  echo "  release-anchor hygiene validated (AC4/AC5 — recorded divergences exempt / a NEW divergence reported in BOTH directions / EQUAL-COUNT-UNEQUAL-SET fixture still reported (the count-parity false negative) / non-noreply tagger flagged, noreply tagger not, recorded exemption suppressed, lightweight tag excluded by objecttype / guard is comm-based by construction)" >&2
  echo "  phase_append_changelog dry-run REACHABILITY validated (#5268, arms F-9.5-N/S — the mode branch now sits ABOVE the projector capture and BELOW the four mode-invariant guards, in 15.5's shape: N-dry reaches the limb and records literally DRY-RUN with a note absent by construction and writes nothing / N-apply anti-vacuity, the IDENTICAL fixture still aborts at --apply with its message verbatim, so the dry arm cannot be satisfied by gutting the capture / S-dry pins both detail constraints, no embedded '|' and no literal would-FAIL token, each with its own firing control / S-apply proves the prediction TRUE by actually prepending the predicted section, so 'would prepend' is not a false forecast)" >&2
  echo "  phase_assert_anchor_hygiene LEDGER-ROW-PARITY mode-scoped (#5268, group h — the second class member: 15.55 had NO mode branch, so fixing 9.5 alone only MOVED the halt here, one phase-group short of Phase 16. Per-limb V4 downgrade, not a whole-phase relocation: h1 the bounded state predicts and RECORDS the prediction with honest counts / h2 anti-vacuity, same fixture at --apply still FAILs verbatim / h3 a two-row gap still FAILs / h4 a one-row gap that is NOT this version's row still FAILs, the arm a bare gap==1 test cannot pass / h5 INDEX-ahead still FAILs / h6 the predicate driven directly, one positive against one negative per conjunct / h7 a co-tenanted TAGGER-IDENTITY violation still FAILs at --dry-run while the parity gap stays predicted, so the scoping bounds itself to its own trigger / h8 structural: the whole-phase DRY-RUN relocation is refused by construction)" >&2
  echo "  LEDGER-ROW-PARITY fail-open closed (#3113 F-QA-3 — present-but-empty INDEX vs 3-row LOG now FAILs naming both counts / equal populated ledgers still PASS / both-empty 0==0 correctly clean / missing INDEX still FAILs / grep_count single-integer contract on empty-file, missing-file, match and empty-stdin shapes / reintroduction blocked structurally, needle proven against a known-bad control)" >&2
  echo "  phase_sync_primary_checkout validated (AC7 — behind-primary-on-main fast-forwards and HEAD verifiably MOVES to origin/main / non-main primary SKIPPED and NOT moved / absent primary clean no-op (CI hermeticity) / dry-run no-write / source carries no reset-stash-checkout-push-force-cd)" >&2
  echo "  scaffold-residue detector + pre-authored-note tolerance validated (AC1/AC2 — T1 round-trip: the REAL scaffold trips the REAL token set (anti-drift) / T2 authored note clean / T4 this-version CHANGELOG+DIGEST residue FAILs naming surface:line / T3 audit-baseline control: another version's residue does NOT block / T6 mode-awareness: --dry-run over ABSENT entries returns 0 and marks literally DRY-RUN, never a vacuous PASS / T7 anti-vacuity: the SAME absent-entry fixture under --apply still returns non-zero, FAILs, and preserves the dropped-write message verbatim / AC2 tolerance: this-version untracked note passes, other-version + modified-tracked + unrelated-untracked all still block)" >&2
  echo "  AC1/AC2 VERSION-LESS shape validated (#3113 Records 2+3 — VL-0 notes_abs_path()==notes_rel_path() in BOTH identity modes / VL-1 producer writes notes/_unversioned/ and creates the dir / VL-2 anti-vacuity: NOT written flat / VL-3 preflight (f) residue gate FIRES (no longer a silent no-op) / VL-4 preflight (b) tolerates the note this run produced (deadlock closed) / VL-5 controls: flat bucket + another version-less release still block / VL-6 §3.2 needle blocks this release, not another / VL-7 chore-PR File Change Matrix names the real path / VL-ORDER the --self-test dispatch verifiably PRECEDES the canonical-version gate, which is what makes every arm above reachable — asserted from source, with an anti-vacuity arm on both needles)" >&2
  echo "  plan-path resolver validated (#4706 — PL-0 specificity: no plan anywhere returns non-zero AND prints nothing / PL-1 rule 1 nested version-named / PL-2 precedence: rule 1 beats a lingering flat copy / PL-3 rule 0 flat slug-primary / PL-4 the nested SLUG-named form a three-valued reading omits / PL-5 rule 2 _unversioned with an anti-vacuity twin that it is NOT the flat form / PL-6 an unresolvable plan ANNOTATES and the note is still written — no new abort path in a phase that has never had one / PL-7 --dry-run never fails and writes nothing / PL-8 all three emitters carry the SAME resolved string / PL-9 the caller PLUS its predicate: a note-path finding blocks, another release does not, and a plans-path-only finding provably does NOT reach the needle / PL-10 end-to-end: the REAL linter finding piped into the REAL phase_lint_release_notes blocks the close)" >&2
  echo "  plan-identity close gate validated (ADR-092 Phase 9.3 — PI-0 clean PASS / PI-1 a this-version placement finding BLOCKS / PI-1b the expected-path needle carries INDEPENDENT reach (every finding class today also names the version, so PI-1 alone proves nothing about it) / PI-2 audit-baseline control: another release does NOT block / PI-3 exit-3 fails loud / PI-4 THE UNMASKING ARM: a plan NAMED FOR THE WRONG VERSION emits its ACTUAL path, which the expected-path needle cannot match — only the version-keyed needle catches it, so a single-needle caller fails here / PI-4b same shape for MAJOR-DIR / PI-4c both version-needle boundary guards / PI-5 version-less SKIPs / PI-6 + PI-7 needle INDEPENDENCE in both directions — and PI-7 is the standing measurement this phase exists for: a plans-path finding provably does NOT reach the note-path needle, so homing a plan limb inside check_note_content() is fail-open / PI-8 advisories are filtered before the needles, so a known residual cannot false-block / PI-9 missing tooling FAILs / PI-10 the phase is DISPATCHED and in the right window (transition_release_log < 9.3 < commit_chore_pr), with a fabricated-name control / PI-11 the hand-maintained usage()/--help phase roster carries the 9.3 row, with the shipped 9.2 row as its control)" >&2
  echo "  MERGE_SHA capture + tag↔SHA identity validated (#1682 — read-state captures release-PR merge SHA / tag==SHA publish PASS w/ --target / tag!=SHA publish FAIL)" >&2
  echo "  check_parser_clean validated (D9 — close-family + #N rejection; negated-form rejection; safe-phrasing acceptance)" >&2
  echo "  close-out report phase set is RECORD-DERIVED validated (#4773 — every recorded phase renders against a denominator parsed from this file's own mark_phase subjects (pre-fix: 3 missing — inject_velocity_field / append_release_learnings / audit_epic_rollup) / a phase in NO enumeration still renders (AC-2) / an unmarked name does NOT render (anti-vacuity) / post_gate_passage_proof renders AND is asserted definition-less, so a definition-derived set cannot silently drop it / a double-marked name renders ONE row carrying the FIRST result / the halted marker fires on a FAIL-terminated run and is absent on a clean one / DISPATCH<->RECORD cross-check: every dispatched phase is a record subject, with vacuity floors on both parses plus sensitivity and specificity arms — the one invariant no seeded arm can reach / JSON twin carries the same de-duplicated set with pre-existing keys intact)" >&2
  echo "  Gate-Passage-Proof **Chore PR:** field renders ONCE on BOTH paths (#4322 — b1 POPULATED path, the path the pre-existing report arms never exercised: exactly one **Chore PR:** line carrying the number once, and the doubled form absent / b2 UNSET path, the previously-covered one, renders the fallback verbatim with no '#' / b3 SPECIFICITY on a NON-numeric fixture, because '#3697' contains '3697' so 'no bare number' is unfalsifiable on a numeric input: the value occurs exactly once on the line, counted in PURE BASH by length-delta rather than by grep_count -o, which counts LINES on this suite's BSD grep and so returns the PASS value on the doubled form — paired with the anti-vacuity control asserting the identical computation returns 2 over the pre-fix expansion / b4 EXECUTABLE SENSITIVITY: the pre-fix construct is expanded from a single-quoted source fixture and must BOTH reproduce the doubling AND be rejected by b1's matcher, without which b1's green result is uninformative / b5 REINTRODUCTION GUARD: the production region above self_test carries ZERO same-variable paired set/unset expansions on CHORE_PR_NUMBER, with an anti-vacuity control asserting the same matcher returns 1 on the known-bad source form, so the zero is a measurement rather than a broken probe / b6 the out-of-scope --no-merge deferral message's solitary set-arm is asserted unchanged in BOTH directions, so the fix did not generalize into a correct site / b7 AC-5: with the **Chore PR:** line stripped, two renders differing only in CHORE_PR_NUMBER are byte-identical, preceded by the anti-vacuity arm that the unstripped renders differ — b7 is invariant to a render-line revert BY DESIGN, so the executed mutation-kill set is b1/b3/b5)" >&2
  echo "  chore-PR body builder is parser-clean (D9 self-check)" >&2
  echo "  JSON report renders valid JSON" >&2
  echo "  usage block extractable" >&2
  echo "  corpus paths resolve (RELEASE_LOG/INDEX/DIGEST + notes dir)" >&2
  echo "  corpus append-ledger merge-immunity validated (#3108 AC1 — union two-branch append CLEAN + both rows kept / non-union control CONFLICTS / state-column union CORRUPTS → LOG+REVERSIONS exclusion)" >&2
  echo "  phase_assert_output_set validated (#5288, group m — 11 arms; this line is the group's conformant-arm extraction, without which a passing run is indistinguishable from a run in which the group never executed): m1 THE SEAM — the required-if cutoff is READ out of core/deploy/deploy.sh rather than copied, asserted against a SECOND INDEPENDENT extractor over the same file (awk, not the shipped sed) with an anti-vacuity floor on the oracle, plus a SENSITIVITY arm on an ARMED fixture that a hardcoded default fails, and two SPECIFICITY arms (no assignment / two assignments) that must both resolve UNREADABLE and never a silent default / m2 AN UNEVALUABLE PREDICATE BLOCKS: both required members PRESENT and the only fault is that the membership test could not run — the phase FAILs, returns 3, and reports INDETERMINATE, with a same-fixture one-variable CONTROL proving a readable dormant seam PASSes, so the block is attributable to the seam and not to a gate that always fails / m3 AC-3 a required member's absence blocks and NAMES itself, both members driven, with the present twin as the paired positive / m4 AC-5 membership vs outcome: the SAME absent telemetry field blocks under an ARMED cutover and resolves a REPORTED N-A under a dormant one, one variable apart / m5 THE MARKER IS EVIDENCE, NEVER AN EXEMPTION — differential over one fixture where the only change is that a real **Not-produced:** marker is recorded: the verdict must NOT move, with a SENSITIVITY arm proving the marker is genuinely present (else the arm passes vacuously), an assert that the gate REPORTED reading it (an invisible marker would prove nothing), and a converse SPECIFICITY arm where the member is supplied and the same marker is inert / m6 EMIT ON ABSENCE at the real producer site: a non-executable synthesizer still SKIPs but now records the absence as corpus bytes at its DECLARED anchor, the line immediately after **Result:**, with a working-producer control proving the marker tracks the capability condition and does not fire every run / m7 MODE: --dry-run returns 0 and marks WARN naming the condition that FAILS at --apply, anti-vacuity: the same fixture at --apply returns 3 and FAILs / m8 THE CLASSIFIER IS TOTAL AND FAILS CLOSED: an UNRECORDED producing phase (get_phase's not-found sentinel returns at exit 0, so it is a value and not an error) classifies INDETERMINATE and surfaces, with a PASS-record control proving real discrimination, and the ambiguous SKIPPED result shown to be resolved by the TREE — the identical result string classifies would-present over a present member and would-absent over an absent one, so the classifier is not row-pattern-matching detail prose / m9 the hand-maintained usage()/--help phase roster carries the 9.56 row, with the shipped 9.55 row as its interpretability control / m10 READ-ONLY by content hash across a PASSing run, with an anti-vacuity arm proving the same instrument DOES move on a known write / m11 EXACTLY ONE guarded top-level dispatch line, positioned AFTER assert_derived_surfaces and BEFORE commit_chore_pr (so the stamp cannot commit ahead of the assert), with vacuity floors on all three needles and a fabricated-name specificity control" >&2
  echo "  phase_pattern_scan wiring validated (#3121 — default ON (source-parsed, not live-global) / --no-pattern-scan suppresses with the honest reason / --with-pattern-scan still accepted / NO /dev/null discard / phase detail carries the PARSED counts with a moved-control anti-vacuity arm / captured body reaches the close-out report, and the section is ABSENT when nothing was captured)" >&2
  exit 0
}

# ─── Corpus path-resolution probe (offline; CI smoke gate) ───────────────────
#
# OFFLINE by construction: stats the four corpus paths and exits 0 (all resolve)
# or 1 (any missing/wrong-type). Touches NO git remote and NO gh/network call, so
# the CI smoke job is deterministic and credential-free. This is the hard-fail
# path-resolution check the smoke gate runs to catch re-pathing drift (the
# migration-drift failure mode) BEFORE the next release does.
#
# CONSTRAINT (corpus-home adapter seam): if you are making this resolution
# instance-aware / adapter-driven, read
# release/references/standards/corpus-home-adapter-constraints.md FIRST. Three of
# its four constraints bind the code you are about to write, and satisfying only
# the first is the documented way to ship a broken resolver behind a green gate:
#   CH-1  instance-corpus root ABSENT  -> record N/A and exit 0, never HARD-FAIL
#         (this probe is a REQUIRED CI gate; a HARD-FAIL reddens every PR from a
#         fresh clone). A crash is not tolerance either — any non-zero fails.
#   CH-2  instance-corpus root PRESENT -> resolve all four corpus paths through
#         the active corpus home and exit 0. An unconditional exit 0 satisfies
#         CH-1 while resolving nothing at all; CH-2 exists to forbid exactly that.
#   CH-4  emit the N/A outcome as a distinguishable PER-PATH record, never an
#         undifferentiated OK — otherwise an unresolved path reads as a resolved
#         one and CH-3 is defeated.
# release/tools/tests/test_corpus_home_tolerance.sh ASSERTS CH-3 unconditionally,
# and asserts CH-1 / CH-2 / CH-4 by reading the fixtures' OUTPUT once it detects
# instance-resolution vocabulary in this file (or fixture A starts exiting 0). It
# does NOT assert them for a resolver that names none of that vocabulary AND leaves
# its fixture A non-zero — if you introduce a new spelling, extend ARMING_NEEDLE
# there in the same change.
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
  local entry
  # CH-1 + CH-4 — the tolerance branch. No corpus home resolved: the in-tree
  # corpus is absent AND no instance corpus exists under the operator-instance
  # root. Absence is TOLERATED (exit 0), and it is recorded as a DISTINGUISHABLE
  # per-path N/A record for every corpus label rather than an undifferentiated
  # OK. The per-path form is the load-bearing part: a single N/A banner beside
  # four OK rows would satisfy the letter of CH-1 while making a genuine
  # resolution defect indistinguishable from a tolerated absence, which is
  # exactly what CH-4 closes and what would defeat CH-3.
  if [[ -z "$CORPUS_HOME" ]]; then
    echo "check-paths: no corpus home resolves — in-tree corpus absent at $REPO_ROOT/release/releases, and no instance corpus under $CORPUS_INSTANCE_ROOT" >&2
    for entry in "${checks[@]}"; do
      label="${entry%%|*}"
      path="${entry#*|}"; path="${path%|*}"
      echo "  N/A  $label -> $path (instance-corpus root absent — tolerated, not resolved)" >&2
    done
    echo "check-paths: PASS (instance-corpus root absent; every corpus path recorded N/A, nothing downgraded to OK)" >&2
    exit 0
  fi
  echo "check-paths: resolving corpus paths under $CORPUS_HOME ($CORPUS_HOME_KIND-homed)" >&2
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
    --with-pattern-scan) WITH_PATTERN_SCAN=1; shift ;;   # compatible no-op: now the default
    --no-pattern-scan) WITH_PATTERN_SCAN=0; shift ;;
    --no-epic-audit) WITH_EPIC_AUDIT=0; shift ;;
    --reversion) REVERSION_SPEC="$2"; shift 2 ;;
    --outcome) OUTCOME="$2"; shift 2 ;;
    --outcome-rationale) OUTCOME_RATIONALE="$2"; shift 2 ;;
    --exclude-issue) EXCLUDE_ISSUES+=("$2"); shift 2 ;;
    --close-comment) CLOSE_COMMENTS+=("$2"); shift 2 ;;
    --merge-timeout) MERGE_TIMEOUT="$2"; shift 2 ;;
    --no-merge) NO_MERGE=1; shift ;;
    --attest-action-items) ATTEST_ACTION_ITEMS="$2"; shift 2 ;;
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
phase_inject_velocity_field || { generate_report; exit 3; }           # Phase 6.6 — **Velocity:** field after **Cycle-Time:** (stage-13-close.md Phase B-velocity); ordered AFTER 6.5 so the write surface is already proven to resolve
phase_append_release_learnings || { generate_report; exit 3; }        # Phase 6.7 — `#### Release Learnings v<X.Y>` sibling H4 (stage-13-close.md Phase A7); hot ledger only per RECORDS_POLICY KEEP_CLASS
phase_inject_close_class_telemetry_field || { generate_report; exit 3; }  # Phase 6.8 — **Close-Class-Telemetry:** field (close-class-telemetry.md § 3.2); ordered AFTER 6.5 so the **Outcome:** insert anchor already exists
phase_append_release_index || { generate_report; exit 3; }
phase_append_release_digest || { generate_report; exit 3; }
phase_append_reversions || { generate_report; exit 3; }                # Phase 8.5 — re-version ledger (#1679; N/A on the common no-collision path)
phase_scaffold_release_notes || { generate_report; exit 3; }
phase_lint_release_notes || { generate_report; exit 3; }              # Phase 9.2 — §3.2 note-content close gate; a finding for THIS version BLOCKS close
phase_lint_plan_identity || { generate_report; exit 3; }              # Phase 9.3 — ADR-092 plan-file identity/placement close gate; a finding for THIS version BLOCKS close (before the chore branch is committed)
phase_append_changelog || { generate_report; exit 3; }                # Phase 9.5 — Layer-1 dual-write Surface 2
phase_assert_derived_surfaces || { generate_report; exit 3; }         # Phase 9.55 — AC1 anchor A3: version-scoped scaffold-residue assert on CHANGELOG + DIGEST
phase_assert_output_set || { generate_report; exit 3; }               # Phase 9.56 — pre-commit output-set completeness over the Step-4 manifest (#5288). The GUARD on this line is what keeps the VERIFIED stamp off main when a required output is missing: it aborts before phase_commit_chore_pr
phase_bump_version || { generate_report; exit 3; }                    # Phase 9.6 — stamp .version (versioned releases; SKIP version-less)
phase_ledger_guard || { generate_report; exit 3; }                    # Phase 9.9 — pre-commit §220 I1/I2 read-modify-write guard (#1680)
phase_rebuild_skill_packages || { generate_report; exit 3; }          # Phase 9.95 — .skill package rebuild into the chore commit (#3322; content-sidecar-gated)
phase_commit_chore_pr || { generate_report; exit 3; }
phase_create_chore_pr || { generate_report; exit 3; }
phase_await_merge_chore_pr || { generate_report; exit 3; }
phase_sync_primary_checkout || { generate_report; exit 3; }           # Phase 12.2 — AC7: fast-forward the primary checkout to origin/main (non-fatal; git -C only)
phase_reparse_ledgers || { generate_report; exit 3; }                 # Phase 12.5 — post-merge structural re-parse (#1680; detective-only)
phase_action_item_gate || { generate_report; exit 3; }                # Phase 12.9 — Procedure 7a HARD GATE (#4439); MUST precede the close. The GUARD on this line, not its position, is what makes the close unreachable on a BLOCK — self-test group AI arm (F) executes these two lines verbatim from this file's own text
phase_post_close_milestone || { generate_report; exit 3; }
phase_manual_close_release_issues || { generate_report; exit 3; }
phase_run_verification || { generate_report; exit 3; }
phase_publish_github_release || { generate_report; exit 3; }          # Phase 15.5 — Layer-1 dual-write Surface 1
phase_assert_anchor_hygiene || { generate_report; exit 3; }           # Phase 15.55 — AC4/AC5: set-based tag<->Release parity + tagger identity (both anchors exist by now)
phase_check_release_body_drift || { generate_report; exit 3; }        # Phase 15.6 — post-emit §5.1 drift assert (genuine drift inside the cutoff scope BLOCKS; capability-absent / artifact-missing stay non-blocking)
phase_invoke_orphan_cleanup || { generate_report; exit 3; }
phase_pattern_scan || { generate_report; exit 3; }
phase_audit_epic_rollup || { generate_report; exit 3; }              # Phase 16.7 — epic rollup-close audit (#1825); signal-only, gates nothing

generate_report
exit 0
