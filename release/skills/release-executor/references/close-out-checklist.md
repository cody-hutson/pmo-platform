# Release Close-Out Checklist

## Purpose

This checklist governs Stage-13 release close-out for PMO platform releases. The
release-executor skill (Mode D — Close Release) follows this checklist to finalize a
shipped release: confirm every release issue is closed, transition the engineering audit
log to its verified state, close the Milestone, clean up the release branch, persist
verification evidence, and track any scoped-but-unshipped work as carry-forward so
nothing is silently dropped.

Mode D wraps the automated close-out script automated-closeout.sh, which sequences the
Stage-13 Phase B chore-PR pattern as a set of idempotent phases. This checklist is the
operator-and-agent-facing enumeration of WHAT the close-out must accomplish; the script
is the mechanism that accomplishes most of it. Where the script already produces an item,
this checklist names it so the item is explicit rather than buried in script internals —
the issue-closure audit and the carry-forward output are the two such items. Read this
checklist on the first close-out; it is the durable companion to the Mode D step list in
SKILL.md.

The canonical Stage-13 process this checklist serves is defined in the pipeline shard
stage-13-close.md and the release governance file release-process.md; the chore-PR
landing mechanism is defined in git-workflow.md (release-corpus governance artifacts land
via a chore PR, never via a direct-to-main commit). This checklist does not restate those
sources — it sequences the close-out for the skill that runs it.

## The six checklist items

Mode D follows these six items in order: **audit, milestone, log, branch, evidence,
carry-forward**. The order is not arbitrary — the audit gates the milestone close (a
milestone must not close while it carries open issues), the log transition and the
milestone close are the two terminal-state mutations, the branch cleanup and evidence
persistence finalize the record, and carry-forward captures whatever the audit found
unshipped so it survives into the next cycle.

### 1. Issue-closure audit

Confirm every issue in the release's milestone reached its terminal CLOSED state before
the Milestone is closed.

- **Enumerate the milestone's open issues.** The script does this at its Phase 4
  detect-open-issues step — query form `gh issue list --milestone "v<X.Y>-<slug>"
  --state open` — and carries the resulting open-issue list and count through to the
  close-out report. Do NOT re-implement the enumeration; read it from the script's
  dry-run output.
- **A clean close is a zero open-issue count.** Every milestone issue auto-closed from
  the release PR's terminal-state references, so the audit finds nothing open. This is the
  expected steady-state outcome.
- **A non-zero count is a blocking finding.** A milestone that closes while it still
  carries an open issue is exactly the mixed state the audit exists to catch. The finding
  blocks a clean close until it is dispositioned one of two ways:
  - **(a) Auto-close anomaly.** An issue that should have closed from the release PR's
    terminal-state reference but did not. The script's manual-close phase closes these at
    apply (operator-authorized D-1 pattern), with a structured comment recording the
    manual closure. The dry-run review presents the manual-close list before apply.
  - **(b) Bundled-but-unshipped.** An issue that was bundled into the release but did not
    ship this release. These are deferred, not closed — they route to item 6
    (carry-forward) below. Do NOT force-close a bundled-but-unshipped issue: defer is not
    close, and closing it would drop it from the next-cycle re-triage pool.
- **Surface the verdict in the dry-run review** so the operator sees it (clean, or N open
  with the enumerated list) before approving apply.

### 2. Milestone closure

Close the GitHub Milestone for the release.

- The Milestone closes only AFTER item 1's audit is satisfied — every milestone issue is
  CLOSED, the auto-close-anomaly issues have been manually closed at apply, and every
  bundled-but-unshipped issue has been de-milestoned via the carry-forward disposition
  (item 6). A non-zero open-issue count at milestone-close time is the mixed state the
  audit blocks.
- Milestone closure is a mechanical post-merge step once its preconditions hold; it is
  reversible by re-opening the Milestone if a later issue must be re-bound.

### 3. RELEASE_LOG finalization

Transition the release's row in the engineering audit log from its deployed state to its
verified state.

- The canonical engineering-audit-trail log lives at the path
  release/releases/RELEASE_LOG.md. The close-out edits that file to transition the
  release row from DEPLOYED to VERIFIED (this is one surface of the platform's dual-write
  release-corpus mechanism). The transition lands via the Stage-13 chore PR, not via a
  direct-to-main commit.
- The DEPLOYED row MUST already exist (written by the upstream Stage-12 chore PR) for the
  transition to apply; the close-out pre-flight asserts this precondition and halts if the
  row is absent or in a state other than DEPLOYED.
- RELEASE_LOG.md is distinct from the user-facing release note and from the release plan
  file: it is the engineering audit trail. The user-facing note and the release-corpus
  index and digest are separate Stage-13 outputs landed by the same chore PR.

### 4. Release-branch cleanup

Delete the merged release branch.

- After the release PR has merged and the Milestone has closed, the merged release branch
  is deleted (local and remote). Branch cleanup runs from the primary checkout after the
  Milestone close, not from a session worktree mid-close.
- Branch cleanup is the lowest-risk close-out mutation: the branch's history is preserved
  in the merge commit on the mainline, so deletion loses nothing recoverable.

### 5. Verification-evidence persistence

Persist the verification record to a durable location — never leave it only in chat.

- The verification evidence (the post-deploy verification results, the per-assertion
  release-plan invariant re-verification, and the gate-passage proof) is persisted in the
  release plan's Verification Evidence section and surfaced as a gate-passage proof comment
  on the Stage-13 sub-task. The close-out report names where each evidence surface landed.
- The verification record is the operator's durable answer to "did this release close
  cleanly?"; a record that lives only in the close-out chat session is not persisted and
  does not satisfy this item.

### 6. Carry-forward / deferred-item tracking

Track every issue that was bundled into the release's milestone but did not close at this
close-out, so nothing scoped-but-unshipped is silently dropped. This is a named close-out
output, reported every close-out regardless of whether anything was deferred.

- **The disposition procedure is the canonical deferred-item procedure** defined in the
  standard deferred-item-tracking.md (its A2.1 through A2.3 steps). The close-out does not
  invent a parallel mechanism — it follows the standard:
  - **A2.1 — Enumerate** the bundled-but-not-closed issues (the open-issue list from item
    1's audit, minus any that closed as auto-close-anomaly resolutions at apply).
  - **A2.2 — For each deferred issue:** apply the status-deferred label (the same label the
    triage-stage defer protocol uses — no new label is introduced), remove the milestone
    assignment, and post the canonical comment trail recording the originating release, the
    one-line rationale, and the next-cycle re-entry path. The milestone is removed because
    the issue is no longer bound to the closing release; the comment trail is the pointer
    that preserves the originating-release link once the milestone is gone.
  - **A2.3 — Summarize the disposition in two surfaces:** the full enumeration (one row per
    deferred issue, with rationale) on the Stage-13 sub-task comment, and a compact
    Deferred items line in the Stage-13 chore PR body — a deferred list, or "none (clean
    close)".
- **Deferred is not closed.** A deferred issue stays OPEN so the next release cycle's
  triage picks it up for re-evaluation. Closing a bundled-but-unshipped issue at Stage 13
  drops it from the re-triage pool and is the anti-pattern the standard explicitly forbids.
- **Clean-close case.** When the audit at item 1 found nothing open, the carry-forward
  output reads "Deferred items: none (clean close)". The output is still reported so its
  absence is never ambiguous.
- **Distinct from terminal-archive.** Deferral (open, awaiting re-triage) is the default
  for unshipped work. Closing an issue as not-planned with the milestone retained as a
  historical record is the separate terminal-archive disposition, reserved for work the
  operator has confirmed obsolete — it is not the carry-forward path and is chosen only on
  an explicit operator obsolescence decision.

## Fallback when the script cannot run

The close-out is outcome-bound, not tool-bound: what is mandated is the complete output
set produced and verified on the mainline, not a single mechanism. The script's pre-flight
hard-exits on exactly the conditions a close can legitimately hit — authentication
unavailable, working tree not clean, the deployed RELEASE_LOG row not yet landed, the
version tag absent. When the pre-flight cannot pass, the operator MAY produce the same
output set by hand via the Stage-13 chore-PR mechanism defined in stage-13-close.md; the
close is satisfied when the deploy-check release-corpus completeness check and the
hub-side completion-verification table both pass. Binding the outcome rather than the tool
keeps the close satisfiable even when the tool's pre-flight blocks. The six checklist items
above are the outcome the fallback must still produce — including the issue-closure audit
and the carry-forward output.

## Relationship to Mode B verification

Mode B (Verify Release) is the read-only post-release confirmation pass; this close-out
checklist is the finalization pass that transitions the release to its closed,
verified-of-record state. The two compose: Mode B's verification dimensions are the
evidence item 5 persists, and a Mode B verdict of NEEDS ATTENTION is a reason to halt the
close-out rather than proceed to milestone closure. Run Mode B's verification before the
close-out reaches the milestone-close and log-finalization mutations.
