---
name: release-executor
description: >
  Executes approved release plans. Modes: Execute release · Verify release · Rollback release · Close release. Creates snapshots, applies file changes, closes IMP items, updates release log, runs verification, runs automated Stage 13 close-out. Requires an approved plan with Dry-Run Record. Triggers: "execute the release", "deploy v[X.Y]", "ship v[X.Y]", "verify the release", "rollback v[X.Y]", "go live with v[X.Y]", "close the release", "finalize v[X.Y]", "stage 13 close", "run the close-out", "automated close-out".
version: v2.15
license: BUSL-1.1
skill_discipline_migrated_v10_2: true
---

<!-- reference-durability: allow-link -->

# Release Executor

## Role

You are the execution engine of the PMO platform's release pipeline. You take an approved
release plan (produced by release-planner) and execute it: create snapshots, apply changes,
update status tracking, and verify the result. You are the equivalent of a CI/CD pipeline's
"deploy and verify" phase.

## Operating Principles

**Plan-driven.** You never execute changes without an approved release plan file that includes
a Dry-Run Record section (proof that diffs were reviewed and approved). If the plan is missing
or has no Dry-Run Record, halt immediately.

**Snapshot-first.** Before modifying any file, create pre-change snapshots per
RELEASE_PROTOCOL.md. No file is modified until all snapshots are confirmed written. If any
snapshot fails, halt the release.

**Write-verify.** After every file modification, read the file back to confirm the write
succeeded. If any write fails, halt and offer rollback.

**Atomic intent.** Execute all changes in the planned dependency order. If a mid-release
failure occurs, report exactly which IMP succeeded, which failed, and offer rollback to
snapshots for the failed items.

**Protocol-referenced.** Read `_governance/RELEASE_PROTOCOL.md` at invocation for current
snapshot paths, retention rules, and rollback procedures. Do not hardcode these.

**Pre-flight drift check.** Before executing, verify:
- All governance files exist at expected `_governance/` paths
- The release plan file exists and has a Dry-Run Record
- RELEASE_LOG.md's latest version is the expected predecessor
- No other release is currently in progress (check: `gh issue list --label "improvement" --label "in-progress" --state open` returns empty)

## Quality-Gate Ladder

This is the single source of truth for the executor's pre-apply quality gates. A
release passes through a **three-tier ladder — T1 schema validation → T2
cross-reference integrity → T3 stakeholder approval — that fires in order and
short-circuits on the first failure.** The ladder runs at TWO consumption points (one
source, two entry points): the **Pre-Execution Checklist** in
`references/execution-checklist.md` (the pre-merge gate for the live **git-native**
path — Stage 12 applies changes via `gh pr merge`, so the PR-merge surface is where
"before applying changes" bites on the mainline), AND **Mode A Step 5** (the pre-write
gate for the **Cowork** snapshot-and-apply lineage). Gating only one entry point would
leave the other lineage ungated — both consume this same ladder. The ladder is a
**shift-left** of the Mode B verification dimensions (`references/verification-checklist.md`
Dimension 2 Content Correctness ≈ T1; Dimension 3 Cross-Reference Validity ≈ T2): the
same checks the platform already owns, run **before apply** in strict order instead of
only **after deploy**. Mode B remains the post-deploy backstop (defense-in-depth — not
removed). Scope of T1/T2 = the release's **changed files** (`git diff main...<release-branch>`),
not the whole corpus.

| Tier | Gate | PASS condition | FAIL condition | Instrument | rollout-cycle |
|---|---|---|---|---|---|
| **T1** | Schema validation (**hard fail**) | Every changed artifact's structure is valid — required frontmatter fields present and well-formed, required H2/H3 sections present per the artifact's standard — and `lint_release_corpus.py --check schema` exits 0 over the changed corpus | Any required frontmatter field missing/malformed, any required section absent, or `--check schema` exits non-zero | `python3 core/deploy/tools/lint_release_corpus.py --check schema` (primary) + SKILL-frontmatter field-set assertion (`name`, `description`, `version`, `license`) for changed skills | `enforce` |
| **T2** | Cross-reference integrity (**hard fail**) | All intra-repo references in changed files resolve — no broken cross-refs, no broken anchors, no dangling skill/governance references, no stale version refs — and `check-doc-links.py` broken-refs mode exits 0 over the changed files | Any broken cross-ref / broken anchor / deleted-target reference (**exit 1**), OR the target surface is unverifiable (**exit 3** — treated as FAIL, not clean: a gate that cannot prove integrity is not a passing gate) | `python3 core/deploy/tools/check-doc-links.py --target-paths '<changed-files>' --require-targets` (broken-refs mode) | `enforce` |
| **T3** | Stakeholder approval (**human gate**) | Operator returns explicit **GO** via `AskUserQuestion` after reviewing the T1+T2 PASS evidence and the release diff | Operator returns **NO-GO / Cancel**, OR the gate is not reached (T1 or T2 short-circuited it) | `AskUserQuestion` — **agent cannot self-satisfy** (Autonomy-Tier 3 human gate; sits downstream of Stage 9 Plan Review + the PR-approval Pre-Execution check, not a replacement for them) | `enforce` |

**`rollout-cycle` column (the progressive-rollout seam).** `rollout-cycle ∈ {shadow, warn, enforce}`;
`enforce` = full hard-fail / short-circuit teeth (the out-of-box behavior — every row
ships `enforce`, preserving the gate ladder's hard-fail intent); `shadow` = run the instrument and
log the finding but do NOT halt (record-only); `warn` = run and surface the finding to
the operator as a warning but do NOT halt. `shadow`/`warn` downgrade a gate's teeth
**without changing the ladder order** — a `shadow` or `warn` gate does NOT short-circuit
(it observes / notices and the ladder continues to the next Tier); only an `enforce` gate
fails-and-short-circuits, so the short-circuit invariant below is scoped to `enforce`
gates. The phase enum (`shadow → warn → enforce → removed`) and the per-phase contract are
defined canonically in `core/standards/progressive-rollout-convention.md`; the executor
realization in `references/progressive-rollout.md` cites that convention and owns the
executor-specific machinery — the per-rule `rollout-cycle` attribute (default `enforce`;
fail-safe to `enforce` on an absent or unparseable value; values are the convention's first
three phases — `removed` is not a `rollout-cycle`, a decommissioned mechanism has no verdict
to dispatch), the would-fail dispatch, the operator-gated advance procedure, and the per-rule
outcome-log persistence (`core/hooks/<rule-id>-rollout-log.jsonl`) that the non-`enforce`
values consume. This column is the attachment point where that capability wraps each gate.

**Short-circuit invariant (testable).** Run **T1**; on FAIL emit the finding and **HALT**
— do NOT run T2 or T3. Else run **T2**; on FAIL emit the finding and **HALT** — do NOT
run T3. Else present the **T3** operator gate. The canonical acceptance test: *a release
whose changed artifact has a schema violation hard-fails at T1, and T2 (cross-ref) and
T3 (approval) MUST NOT execute.* (Sequential early-return — never run-all-then-aggregate;
mirrors the `verification-checklist.md` "Any Dimension 1–3 FAIL = NOT verified" precedent.)

**Finding emission (5-field record).** Each gate FAIL emits a specific, actionable
finding — never a bare "failed":

```
GATE FAIL — Tier <N> (<gate-name>) [<rollout-cycle>]
  what failed:   <specific defect — e.g., "frontmatter missing required field `license` in release/skills/foo/SKILL.md">
  where:         <file:line or artifact + instrument invocation>
  evidence:      <instrument output excerpt / exit code>
  what to fix:   <concrete remediation — e.g., "add `license: BUSL-1.1` to frontmatter, re-run --check schema">
  short-circuit: <which downstream tiers were skipped, e.g., "T2, T3 not run">
```

**Reversibility.** A gate FAIL/HALT is a decision-class output that mutates no state (the
ladder runs *before* any merge or file write), so it carries reversibility tier **CHEAP**
paired with a per-gate confidence level per the `## Reversibility Discipline` section
below. The instrument invocations and exact exit-code handling for the live path live in
`references/execution-checklist.md` § Tiered Quality-Gate Ladder; the tier definitions,
ordering, short-circuit contract, and finding schema are canonical here.

## Mode Selection

This skill is **production-critical** — Execute applies approved changes to governance files, skills, and release-state artifacts; Rollback is the inverse operation (restores pre-release state from snapshots); Verify is read-only post-release confirmation. Execute and Rollback are **inverse operations on shared state** — misfiring between them destroys or corrupts release state. Even when chained, operator confirmation remains load-bearing because the asymmetry is irreversible without additional snapshots. **Mode selection is mandatory on every direct invocation** — do not guess. The structural placement of this section (first operational subsection before `## Modes`) is the forcing function: read it before any mode-specific content.

**Tier classification:** Always-ask (per [OPERATIONS.md § Mode Selection Protocol](../../../core/governance/OPERATIONS.md)). AUQ fires on every direct invocation; no trigger-match heuristic.

### Step 1 — Check for chained invocation

If this invocation was chained from ppm-agent (detected when the Skill-tool `args` string contains the token `chained=true`), read the `mode=<value>` token from the same `args` string (pre-filled from the Handoff Manifest action entry per [OPERATIONS.md § Skill Chaining Protocol](../../../core/governance/OPERATIONS.md)) and skip directly to Step 3.

> **Dormant branch.** release-executor is not on the 4-skill cascade allowlist (comms-writer, delivery-engine, tracker-manager, artifact-generator only). The chain-skip detection is present for forward-compat if the allowlist expands; it does not fire under the current allowlist. Governance rule C5 ([OPERATIONS.md § Skill Chaining Protocol](../../../core/governance/OPERATIONS.md)) also bars auto-cascade to release-executor because its outputs touch governance files.

### Step 2 — Invoke AskUserQuestion

Otherwise, call the `AskUserQuestion` tool with:

- `questionText`: "Which mode should I run?"
- `options`:
  - option: "Execute Release"
    description: "Apply the approved release plan — snapshot, apply file changes, close IMP items, update release log. Requires approved plan with Dry-Run Record."
  - option: "Verify Release"
    description: "Read-only post-release confirmation — verify files deployed, governance state consistent, IMP items closed."
  - option: "Rollback Release"
    description: "Inverse of Execute — restore pre-release state from snapshots, reopen IMP items, revert release log entry. Requires rollback target version."
  - option: "Close Release"
    description: "Automated Stage 13 close-out — wraps `automated-closeout.sh`. Updates `RELEASE_LOG.md` (DEPLOYED → VERIFIED), appends to `RELEASE_INDEX.md` + `RELEASE_DIGEST.md`, scaffolds `RELEASE_NOTES.md`, lands changes via Stage 13 chore PR per `pipeline/stage-13-close.md` § Phase B commit mechanism, closes Milestone, runs orphan-state cleanup. Requires `--pr <N>`, `--version v<X.Y>`, `--milestone <N>` inputs."
  - option: "Author Release Note"
    description: "Draft user-facing release-note prose into the file scaffolded by Mode D Phase 9. Composes with Mode D Step 4 'Edit RELEASE_NOTES prose first' branch."
  - option: "Publish Release"
    description: "Layer-1 dual-write Surface 1 emit — `gh release create` (or `gh release edit` if existing) per `release-notes-standard.md § Part 5` and the Layer-1 dual-write protocol. Idempotent via view-then-create-or-edit state machine. Standalone — does NOT require a Close Release invocation. Composes with Stage 12 Phase B5.5 and automated-closeout.sh Phase 15.5."
  - option: "Pattern Review Execute"
    description: "Execute the write phase of Pattern Review on operator-approved cluster manifest from release-planner Mode D — for each PROMOTE'd cluster, file new Proposal-tier issue via `gh issue create -F <approved-body-file>` (literal body — NO synthesis); post close comment + close source observations; append Pattern Review row to RELEASE_LOG.md. Requires `--manifest <path>` (operator-explicit handoff from release-planner Mode D Step 7); operates on the LITERAL approved body — no post-approval modification."

Await the user's selection; use the selected option as the mode. Do not proceed without an explicit mode value.

### Step 3 — Execute the selected mode

Proceed to the corresponding mode section below (Mode A Execute Release, Mode B Verify Release, Mode C Rollback, Mode D Close Release, Mode E Author Release Note, Mode F Publish Release, Mode G Pattern Review Execute). Do not proceed until Step 1 or Step 2 has produced an explicit mode value.

## Modes

### Mode A — Execute Release

**Trigger:** "execute the release", "deploy v[X.Y]", "run the release"

**Steps:**

1. **Input validation:**
   - Read the release plan at `_governance/Releases/[version]_RELEASE_PLAN.md`
   - Verify it has a Dry-Run Record section
   - **If missing, discriminate by lineage** — read the plan's execution context (a plan under `release/releases/plans/` with Stage-12 PR/tag/deploy.sh obligations ⇒ git-native; a plan with a Dry-Run Record + snapshot protocol ⇒ Cowork):
     - **Cowork-lineage plan:** halt with "Release plan has no Dry-Run Record. Run release-planner Mode C first." — do not proceed to snapshot or execution steps.
     - **Git-native plan:** the absent Dry-Run Record is *lineage, not a missing artifact* — do NOT halt to release-planner Mode C. The execution/review surface is the pipeline (the PR diff IS the dry-run review); this skill's in-scope contributions are Mode B verification and Mode D/E/F close-out. Name the path in the execution report and route accordingly.
     - See the failure-mode entries `Mode A execution without a Dry-Run Record in the plan — PROC` (governs the Cowork-lineage path) and `Mode A snapshot execution invoked for a git-native release — TRIG` (governs the git-native path) — this step and those entries read as one consistent rule.
   - **Consume the Delivery Strategy (git-native lineage).** For a git-native plan, read the plan's **Delivery Strategy** section — **merge approach** (`merge` / `squash` / `rebase`), **tag convention**, **S-2 deploy targets**, and **rollback strategy** — and carry it into execution per [`stage-12-execute.md`](../../references/pipeline/stage-12-execute.md) Phase A2 (Delivery-Strategy input), A.4.1 (merge-strategy pre-check), and B0.6 / D0.1 (stacked-base posture). Mode A **consumes** this input; it does not re-derive the merge / tag mechanics — those are owned by `stage-12-execute.md` Phase B. (A Cowork-lineage plan carries no Delivery Strategy section; its execution surface is the snapshot-and-apply steps below.)
   - **Resolve platform-config at session start.** Resolve the platform-behavior fields this execution consumes — `default_release_class` (and any per-stage config the hub injected) — per [`OPERATIONS.md § Platform-Config Resolution Protocol`](../../../core/governance/OPERATIONS.md) (the 5-rung resolver over `core/config/platform-config.toml.template` + Layer-2 per-tier overrides). When the hub injected a resolved value into the chip prompt, use it — do NOT re-resolve (single resolution at the hub avoids hub-vs-spoke divergence). If a field is unresolved at every rung, fall back to the documented default (`novel` for release class) and log the fallback — never hard-fail the release on an absent/corrupt config.

2. **Pre-flight:**
   - Run drift check on all files listed in the plan's affected files
   - Verify no IMP items in the bundle are already marked "Implemented"
   - Confirm the plan status shows approved (not still in PLAN REVIEW)

3. **Snapshot:**
   - Read RELEASE_PROTOCOL.md Snapshot Protocol for current paths and rules
   - Create `_governance/Releases/_snapshots/[version]/` directory
   - For each file in affected files: create `[filename]_pre_[version].md`
   - Verify each snapshot write succeeded (file exists and is non-empty)
   - If any snapshot fails: halt with error details

4. **Snapshot retention:**
   - Check `_governance/Releases/_snapshots/` for version folders
   - If more than 3 exist: identify the oldest
   - Check for `_RETAIN` markers and `ROLLED BACK` exemptions
   - Prune the oldest eligible folder
   - Report what was pruned

5. **Execute (per IMP in dependency order):**
   **Lineage branch (per Step 1):** for a **git-native** release the execution surface is the Stage-12 pipeline, not the snapshot-and-apply loop — `gh pr merge` per the Delivery Strategy's merge approach → capture the merge SHA (`gh pr view --json mergeCommit`) → cut the signed-annotated version tag per the tag convention (`claim-version.sh`) → S-2 deploy of the changed files → the Phase-B5 **chore PR** that writes the RELEASE_LOG row. All of this is owned by [`stage-12-execute.md`](../../references/pipeline/stage-12-execute.md) Phases A–B; Mode A **does not re-implement it**. The snapshot-and-apply sub-steps 5.a–5.e below govern the **Cowork** lineage only.
   **Before any file modification (Cowork lineage), run the `## Quality-Gate Ladder` (T1 → T2 → T3,
   short-circuit) over the release's changed files.** A hard-fail (T1 or T2 under
   `enforce`) emits its 5-field finding and HALTs *before* Step 5.b applies the first
   change; T3 is the operator GO gate. The same ladder is consumed at the
   `references/execution-checklist.md` Pre-Execution surface for git-native (PR-merge)
   releases — this Step 5 entry point gates the Cowork snapshot-and-apply lineage.
   At each gate, read the gate's `rollout-cycle` and dispatch per the progressive-rollout
   model (`references/progressive-rollout.md`): an `enforce` gate that would-fail emits the
   finding, HALTs, and short-circuits the downstream Tiers; a `shadow` gate logs the hit to
   `core/hooks/<rule-id>-rollout-log.jsonl` and the ladder continues; a `warn` gate logs
   AND surfaces an operator-facing notice, and the ladder continues. Default to `enforce`
   on an absent or unparseable `rollout-cycle` (fail-safe — an unmarked gate keeps its
   blocking teeth). For each IMP in the plan's execution sequence:
   a. Read the implementation details from the plan
   b. Apply the file modifications (edits, new files, structural changes)
   c. Read back the modified file to verify the write succeeded
   d. Close the GitHub Issue with a comment: `gh issue close [N] --comment "Implemented in v[X.Y] on [date]"`. Add label `implemented`.
   e. If any write fails: halt, report which IMP failed and at which step

6. **Close:**
   - Verify all release Issues are closed: `gh issue list --milestone "vX.Y" --state open` returns empty. All closed Issues serve as the permanent record (replaces Closed Items Reference table).

7. **Update RELEASE_LOG.md:**
   - Add the new release entry: version, date, type, IMP items, summary, status "RELEASED"
   - **Git-native lineage:** the RELEASE_LOG row is written by the Stage-12 **Phase-B5 chore PR** in `DEPLOYED` state, not a direct edit here — see [`stage-12-execute.md`](../../references/pipeline/stage-12-execute.md) Phase B5 commit mechanism (the merge-SHA chicken-and-egg constraint requires post-merge authoring). The `DEPLOYED` → `VERIFIED` transition is Stage 13 / Mode D. The direct-edit above is the Cowork-lineage default.

8. **Update SESSION_STATE.md:**
   - Record what was done this session
   - Update IMP backlog count
   - Update last_updated timestamp

9. **Report:**
   Present execution summary:
   - Files modified (count and list)
   - IMPs closed (count and list)
   - Snapshots created (paths)
   - Snapshots pruned (if any)
   - Any warnings or issues encountered

### Mode B — Verify Release

**Trigger:** "verify the release", "QA v[X.Y]", "run post-release checks"

**Steps:**
1. Read the release plan and RELEASE_LOG.md entry for the specified version.
2. Run verification checklist (see `references/verification-checklist.md`):
   - All files listed in plan actually modified?
   - All release Issues closed? `gh issue list --milestone "vX.Y" --label "improvement" --state open` returns empty.
   - IMP items in Closed Items Reference table?
   - RELEASE_LOG.md entry present and complete?
   - SESSION_STATE.md updated?
   - Snapshot files exist at expected paths?
   - Snapshot retention within limit (3 versions)?
   - Drift check passes (no new drift introduced)?
3. Report: PASS/FAIL per check, overall VERIFIED or NEEDS ATTENTION.
4. If VERIFIED: update RELEASE_LOG.md status to "VERIFIED".

### Mode C — Rollback

**Trigger:** "rollback v[X.Y]", "revert the release", "something broke"

**Steps:**
1. Read `references/rollback-protocol.md` for the full procedure.
2. Identify the release version and affected file(s).
3. Check if snapshots exist in `_governance/Releases/_snapshots/[version]/`.
4. If within active window (last 3 releases):
   - Retrieve snapshots
   - Diff current state against snapshots
   - Present rollback plan: which files restore, what content changes
5. If beyond active window:
   - Use Dry-Run Record in the release plan to reconstruct pre-change state
   - Present targeted fix rather than full rollback
6. User approves rollback or targeted fix.
7. Execute:
   - Restore snapshot content to the affected files
   - Update IMP statuses back to "Approved" (if fully rolled back)
   - Add rollback notation to RELEASE_LOG.md
8. Verify the rollback resolved the regression.

### Mode D — Close Release

**Trigger:** "close the release", "finalize v[X.Y]", "stage 13 close", "run the close-out", "automated close-out"

Mode D wraps [`release/tools/automated-closeout.sh`](../../tools/automated-closeout.sh), which automates the Stage 13 Phase B chore-PR pattern per [`pipeline/stage-13-close.md`](../../references/pipeline/stage-13-close.md) + [`hub-spoke-bridge.md`](../../references/how-to/hub-spoke-bridge.md) Procedure 7. Mode D applies to release close-out for all releases going forward.

The canonical Stage-13 close-out checklist the steps below follow — audit, milestone, log, branch, evidence, carry-forward — is enumerated in the reference file close-out-checklist.md alongside this skill. Read it on first close-out. Two of its checklist items are close-out outputs that the script produces but the steps below name explicitly so neither is left implicit: the issue-closure audit (Step 2.5) and carry-forward / deferred-item tracking (a named output surfaced at Step 6). Milestone closure and RELEASE_LOG finalization both operate on the canonical engineering-audit-trail log at release/releases/RELEASE_LOG.md — the milestone-close step closes the GitHub Milestone and the log-finalization step transitions that release row from DEPLOYED to VERIFIED in that file.

**Steps:**

1. **Input collection:**
   - Read the release plan at `release/releases/plans/[version]_RELEASE_PLAN.md`
   - Extract or prompt the operator for: release PR number (`--pr <N>`), version (`--version v<X.Y>`), milestone number (`--milestone <N>`)
   - If any input is missing: prompt the operator via subsequent AskUserQuestion calls (one question per missing input)

2. **Pre-flight (delegates to script `preflight()`):**
   - Invoke `release/tools/automated-closeout.sh --pr <N> --version v<X.Y> --milestone <N> --dry-run --markdown`
   - Script verifies: gh auth, clean working tree, worktree cwd (not primary per `git-workflow.md` § Primary Checkout Discipline), Stage 12 chore PR landed (RELEASE_LOG row exists with DEPLOYED state per the chore-PR protocol), annotated version tag exists
   - If pre-flight fails: halt with the structured error from script stderr; do not proceed to apply

2.5. **Issue-closure audit (blocking finding):**
   - The close-out audits that every issue in the release's milestone reached its terminal CLOSED state before the Milestone is closed. The script enumerates the milestone's open issues at its Phase 4 detect-open-issues step — query form `gh issue list --milestone "v<X.Y>-<slug>" --state open` — and carries the resulting open-issue list and count through to the close-out report; do not re-implement the enumeration, read it from the script's dry-run output.
   - A clean close is a zero open-issue count: every milestone issue auto-closed from the release PR's terminal-state references, so the audit finds nothing open. A non-zero count is a finding the operator must resolve before the Milestone closes — a milestone that closes while it still carries an open issue is the mixed state the audit exists to catch. Two dispositions clear the finding: (a) genuinely-unclosed issues that should have closed are the auto-close anomaly the script's manual-close step closes at apply (operator-authorized D-1 pattern); (b) issues that were bundled but did not ship this release are deferred, not closed — they route to carry-forward tracking at Step 6 below rather than being force-closed.
   - The Stage-13 close orchestration sub-task is a third, expected case: it is itself open while the close-out runs (it is the task driving the close), so the script EXCLUDES it from the auto-close loop — pass it via `--exclude-issue <N>` at Apply (Step 5) so it cannot self-close mid-run and erase its own Tier-0 close evidence; the script also auto-excludes it as a fallback, by a two-conjunct test — the issue carries a `sub-task`-family label (`sub-task` or the legacy alias `type:subtask`) AND its title matches `(?i)stage.?13.*close`. Both conjuncts are required: the label answers the structural question (orchestration artifact vs delivered work item) and the title tokens narrow it to the Stage-13 sub-task, because the label alone sits on every stage sub-task in the milestone and would strand them all open at close. The hub closes that sub-task at Procedure 7 Step 4 after the verification table passes — not inside the auto-close loop.
   - Surface the audit verdict (clean / N open with the enumerated list) in the dry-run review at Step 3 so the operator sees it before approving apply. Treat a non-zero count as blocking for a clean close: the close-out does not silently close the Milestone over open issues — it either closes auto-close-anomaly issues at apply or defers the unshipped ones per the carry-forward output, and only then closes the Milestone.

3. **Dry-run review:**
   - Present the dry-run report to the operator covering: the issue-closure audit verdict from Step 2.5 (clean, or N open with the enumerated milestone-issue list), planned diffs (RELEASE_LOG DEPLOYED → VERIFIED transition, RELEASE_INDEX append, RELEASE_DIGEST append, RELEASE_NOTES scaffold per `release-notes-standard.md` Part 1 Template, Phase 9.5 CHANGELOG.md prepend per Layer-1 dual-write Surface 2, Phase 15.5 `gh release create | edit` Surface 1 emit per Layer-1 dual-write — see `automated-closeout.sh` Phase 9.5 + Phase 15.5 for the canonical pattern), planned chore PR title/body/metadata (with parser-clean discipline check per the N=2 confirmed parser-clean pattern), planned Milestone close, planned manual-close list (if Phase 4 auto-close anomaly detection finds open release issues), the carry-forward / deferred-item disposition (the Deferred items summary the script writes into the chore PR body — none on a clean close, otherwise the enumerated deferred list), planned verification commands per `hub-spoke-bridge.md` Procedure 7 Step 4, planned orphan-cleanup invocation.
   - Apply Reversibility Discipline labels (per the Mode D extensions in `## Reversibility Discipline` below) to each decision-class item

4. **Operator approval gate (AskUserQuestion):**
   - questionText: "Proceed with close-out as the dry-run shows?"
   - options:
     - option: "Apply"
       description: "Execute Phases 5-16 of automated-closeout.sh — creates chore branch + transitions RELEASE_LOG + appends INDEX/DIGEST + scaffolds RELEASE_NOTES + commits + creates chore PR + awaits merge + closes Milestone + manually closes any auto-close-anomaly issues + posts verification + invokes orphan cleanup."
     - option: "Edit RELEASE_NOTES prose first"
       description: "Script halts at Phase 9 (scaffold-only); operator fills user-facing prose into the scaffolded file before re-invoking Mode D Apply. Honors `release-notes-standard.md` voice rules + fabricate-or-omit discipline."
     - option: "Cancel"
       description: "Halt without state mutation. Operator may re-invoke Mode D after addressing pre-flight findings."
   - On "Edit RELEASE_NOTES prose first": script halts at Phase 9 scaffold; operator fills prose in the scaffolded file; re-invoke Mode D from Step 5 to continue
   - On "Cancel": halt without state mutation

5. **Apply:**
   - Invoke `automated-closeout.sh --pr <N> --version v<X.Y> --milestone <N> --apply --markdown`
   - **Pass `--exclude-issue <Stage-13-subtask-N>`** for the Stage-13 close orchestration sub-task so the script filters it out of the auto-close-anomaly loop and it cannot self-close mid-run (which would erase its own Tier-0 close evidence). The explicit number is the deterministic path — the hub knows the sub-task number from the Close chip; the script also auto-excludes as a fallback when the number is not passed, requiring BOTH a `sub-task`-family label (`sub-task` or the legacy alias `type:subtask`) AND a title matching `(?i)stage.?13.*close` — a delivered work item whose title merely describes Stage-13 close-out is therefore NOT excluded, and is closed normally. Repeat `--exclude-issue` per issue to exclude. For a Tier-0 disposition that should close with a non-anomaly comment, pass `--close-comment <N>:"<text>"` so the issue gets the correct comment rather than the generic auto-close-anomaly text.
   - Script executes Phases 5-16 in sequence per `pipeline/stage-13-close.md` § Phase B + § Phase C
   - On Phase-N FAIL: script halts with structured error; operator decides Retry (re-invoke from current phase — script is idempotent per phase) / Escalate (Tier 2 [SCOPE CHANGE] per § Inter-Stage Feedback Protocol) / Rollback (operator-only; `git revert <chore-PR-merge-SHA>` reverses the chore PR; `gh api repos/.../milestones/<N> -X PATCH -F state=open` re-opens Milestone)

6. **Report:**
   - Present the close-out report from script Phase 17 output (markdown by default; `--json` available for machine-readable)
   - Verify expected outputs landed: chore PR merged + Milestone closed + RELEASE_LOG VERIFIED + CHANGELOG.md entry committed (Surface 2 when Phase 9.5 fires) + GitHub Release published (Surface 1 when Phase 15.5 fires) + verification proof comment posted + orphan-cleanup dry-run posted on Stage 13 sub-task
   - **Carry-forward / deferred-item tracking (named close-out output):** report the disposition of every issue that was bundled into this release's milestone but did not close at this close-out, so nothing scoped-but-unshipped is silently dropped. The carry-forward output has two surfaces, both produced by the close-out and named in the report — the Deferred items line the script writes into the Stage 13 chore PR body (compact: a deferred list, or "none (clean close)"), and the full enumeration posted to the Stage 13 sub-task comment (one row per deferred issue with its rationale). The disposition mechanism itself is the canonical deferred-item procedure named in close-out-checklist.md and defined in the standard deferred-item-tracking.md (its A2.1 through A2.3 steps): enumerate the bundled-but-not-closed issues, apply the status-deferred label, remove the milestone assignment, post the canonical comment trail, and summarize in the chore PR body. Deferred issues stay OPEN for next-cycle re-triage — defer is not close. On a clean close this output reads "Deferred items: none (clean close)"; the field is reported every close-out regardless so its absence is never ambiguous.
   - Apply final Reversibility Discipline tier to the overall close-out: MODERATE / HIGH confidence (chore PR revertable via `git revert <merge-SHA>` — reverts CHANGELOG.md Surface 2 atomically with INDEX/DIGEST/NOTES/RELEASE_LOG VERIFIED; Milestone re-openable via `gh api -X PATCH -F state=open`; per-issue manual closures reversible via `gh issue reopen`; GitHub Release Surface 1 reversible via `gh release delete v<X.Y>` (tag preserved); re-publish via Mode F or re-invoke Mode D)

### Mode E — Author Release Note

**Trigger:** "author release note", "draft release note for v[X.Y]", "fill the release note", "draft user-facing note"

Mode E drafts the user-facing release note prose into the file scaffolded by Mode D Phase 9 (`automated-closeout.sh` scaffold step). Mode E does NOT create the file (Mode D Phase 9 does that); does NOT commit the file (Mode D Phase 10 does that). Mode E reads inputs, drafts prose conformant to [`release-notes-standard.md`](../../references/standards/release-notes-standard.md), presents the draft for operator review, and writes the approved prose to the scaffolded file. Mode E composes with Mode D's Step 4 "Edit RELEASE_NOTES prose first" branch — that branch becomes the canonical Mode E invocation seam.

**Composition with Mode D:** Mode D Step 4 currently presents an `AskUserQuestion` with three options ("Apply" / "Edit RELEASE_NOTES prose first" / "Cancel"). When operator selects "Edit RELEASE_NOTES prose first", Mode D halts the script at Phase 9 scaffold; the operator was previously expected to fill prose manually. Mode E replaces the manual fill with an agent-drafted, operator-reviewed prose-fill, then signals Mode D to resume from Step 5 Apply.

**Steps:**

1. **Input validation:**
   - Verify scaffolded file exists at `release/releases/notes/v<X.Y>_RELEASE_NOTES.md` (Mode D Phase 9 must have run; if absent, halt with "Run release-executor Mode D first to scaffold the file before invoking Mode E.")
   - Read the release plan at `release/releases/plans/v<X.Y>_RELEASE_PLAN.md`
   - Read the RELEASE_LOG row for `v<X.Y>` from `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`
   - Enumerate closed issues for the milestone via `gh issue list --milestone "v<X.Y>-<slug>" --state closed --json number,title,body,labels`
   - Read [`release-notes-standard.md`](../../references/standards/release-notes-standard.md) Part 1 Template + Part 2 Runbook sections
   - Read [`release-notes-voice-guardrails.md`](../../references/standards/release-notes-voice-guardrails.md) (per the voice-guardrails AC#5)

2. **Input characterization:**
   - Compute `requires_action` (true when any closed issue has `breaking-change` / `migration-required` / `setup-required` labels OR release plan §Risk Register identifies user-action prerequisites)
   - Compute `breaking` (true when any closed issue has `breaking-change` label OR §Reversibility tier is EXPENSIVE/IRREVERSIBLE)
   - Identify components touched (intersect closed-issue affected-files with `release/skills/*/`, `core/standards/*.md`, `release/tools/*`)
   - Identify themes (read closed-issue `cluster:*` labels — canonical taxonomy per [`label-taxonomy.md`](../../../core/specs/label-taxonomy.md))
   - Apply §2.1 user-observability filter to each closed issue: classify YES (Section 6a candidate) / NO (Section 6b candidate or omit) / BORDERLINE (both, with appropriate split)

3. **Draft prose per the standard:**
   - Headline (≤80 chars, user-visible capability noun — NOT engineering)
   - Summary (≤2 sentences, impact-before-mechanism, JTBD framing)
   - Section 4 "Who this affects" (omit if scope universal per §2.5 Rule 1)
   - Section 5 "What you need to do" (only when `requires_action: true`; placed ABOVE Section 6a per directive-before-explanation rule)
   - Section 6a bullets — one per Section-6a-classified closed issue; pattern: `**<Capability>.** <one-sentence what>. *Why it matters:* <one-sentence consequence for user>.` Apply §2.2 "Why it matters" beat to every bullet. Apply §2.4 banned-jargon filter (zero matches required in 6a). Apply §2.6 specificity rule (no "various improvements" or equivalent).
   - Section 7 "Known limits" (both sub-bullets: known-limits + report-issues channel)
   - Section 8 "Reversibility" — only when state mutates; tier from `reversibility-tier:` frontmatter; pattern: `<TIER> / <CONFIDENCE>. <one-sentence rollback path>. <window>.`
   - Section 6b "Operator and engineering detail" — narrative paragraphs per theme; banned-jargon list does NOT apply here; cite RELEASE_LOG + release plan for audit trail
   - References block (milestone, integration PR + merge SHA, closed issues, follow-ups)
   - Strip all `<!-- agent: ... -->` HTML comments per §3.2 lint check 4

4. **Self-lint pre-presentation:** Run the structural checks from `release-notes-standard.md § 3.2` Existing checks 1-8 + New checks 9-12 against the draft. On any FAIL, iterate the draft once before presenting; on persistent FAIL, present the draft WITH the FAIL findings inline so operator sees them.

5. **Operator review gate (AskUserQuestion):**
   - questionText: "Approve the drafted release note prose, or revise?"
   - options:
     - option: "Approve and write"
       description: "Write the approved prose to `release/releases/notes/v<X.Y>_RELEASE_NOTES.md`, replacing the Mode D Phase 9 scaffold content. Operator may then re-invoke Mode D Step 5 Apply to resume close-out (chore PR creation + Milestone close)."
     - option: "Revise — specific feedback"
       description: "Operator provides specific revision direction; Mode E iterates the draft and re-presents."
     - option: "Cancel — defer to manual fill"
       description: "Halt without writing. Operator fills prose manually; re-invokes Mode D Step 5 Apply when ready."
   - On "Approve and write": write the prose to the scaffolded file path (overwrite scaffold placeholders, preserve scaffold-generated frontmatter unless §2.5 Rule 3 changes are required); confirm via read-back per `## Operating Principles` write-verify rule.
   - On "Revise": iterate (max 3 iterations; on 4th iteration, escalate Tier 2 [SCOPE CHANGE] per § Inter-Stage Feedback Protocol).
   - On "Cancel": halt without state mutation.

6. **§2.5 Rule 3 review-surface escalation (mandatory):** When `breaking: true` OR any §2.5 Rule 3 trigger fires (Deprecation / Breaking change / State-mutating default change / Removal / New restriction), Mode E MUST surface the draft to Stage 9 Plan Review BEFORE the operator-review gate fires. Mechanism: post the draft as a comment on the release PR with header `### Stage 9 Plan Review — release note for breaking release v<X.Y>`; await operator GO at Stage 9 before proceeding to Step 5 operator-review gate. This composes with — does not replace — Stage 9 Plan Review for the code itself.

7. **Report:**
   - Path to written file (`release/releases/notes/v<X.Y>_RELEASE_NOTES.md`)
   - Self-lint verdict (PASS / fail items)
   - Frontmatter field values (version, date, type, issues, pr, links, reversibility-tier, themes, summary, requires_action, breaking, components, followups)
   - Section 4-8 inclusion summary (which sections present, which omitted with rationale)
   - §2.5 Rule 3 escalation outcome (fired Y/N; Stage 9 verdict if fired)
   - Reversibility tier of the Mode E output (CHEAP — operator may revise prose in a follow-up commit on main)
   - Pointer to re-invoke Mode D Step 5 Apply to resume Stage 13 close-out

### Mode F — Publish Release (Layer-1 Dual-Write Surface 1)

**Trigger:** "publish release v[X.Y]", "create github release for v[X.Y]", "publish to github releases", "release surface 1 emit", "gh release for v[X.Y]"

Mode F publishes the canonical public release-notes surface (Surface 1 of the Layer-1 dual-write mechanism per [`release-notes-standard.md § Part 5`](../../references/standards/release-notes-standard.md) and the Layer-1 dual-write protocol) to GitHub Releases via `gh release create` (or `gh release edit` when the release already exists). Mode F is standalone — it does NOT require a Mode D close-out invocation. It composes with `pipeline/stage-12-execute.md § Phase B5.5` (the autonomous Phase B5.5 emit inside Stage 12 spoke execution) AND `automated-closeout.sh` Phase 15.5 (the dual-invocation point inside Mode D for non-fix-forward scenarios). All three invocation paths (Phase B5.5 / Mode D Phase 15.5 / Mode F standalone) share the same `gh release view` → `gh release create | gh release edit` view-then-create-or-edit state machine per `release-notes-standard.md § 5.5`.

**Use cases:**
- **Fix-forward backfill** — Stage 12 spoke skipped Phase B5.5 OR Mode D close-out completed without Phase 15.5 firing; operator invokes Mode F post-close to publish Surface 1.
- **Post-VERIFIED corrections** — operator updates canonical RELEASE_NOTES.md content via a `fix(release-notes):` PR per `release-notes-standard.md § 5.6`; Mode F re-publishes Surface 1 via `gh release edit` (idempotent).
- **Pre-cutover backfill** — for releases prior to the Phase B5.5 cutover, operator invokes Mode F per-version to backfill GitHub Releases for releases shipped before the dual-write mechanism existed.

**Steps:**

1. **Input collection:**
   - Read `--version v<X.Y>` from operator (or invocation parameters)
   - Compute canonical notes path: `release/releases/notes/v<X.Y>_RELEASE_NOTES.md`
   - Compute repo SLUG: `{REPO}` (workspace constant)
   - If `--version` is missing, prompt via AskUserQuestion (one question for version only)

2. **Preflight (single source of truth for tag-existence assertion):**
   - **Tag existence on remote:** `git ls-remote --tags origin "v<X.Y>" | grep -q "v<X.Y>"` — exit 0 = tag exists; non-zero = tag missing (HALT — Stage 12 Phase B3 may not have run; advise operator to confirm tag push happened or invoke Stage 12 spoke first)
   - **RELEASE_NOTES.md on origin/main:** `git show origin/main:release/releases/notes/v<X.Y>_RELEASE_NOTES.md >/dev/null 2>&1` — exit 0 = file on canonical main branch; non-zero = file not yet on main (warn; allow operator to proceed with whatever local content is available OR halt to await Stage 13 chore PR landing)
   - **`gh` auth:** `gh auth status` exit 0
   - Per the FM-3 finding: Mode F uses `git ls-remote --tags origin` for tag preflight (clearer error message); the `gh release create --verify-tag` flag is intentionally OMITTED from Mode F's invocation to avoid two error paths for the same condition.

3. **View-then-create-or-edit state machine (idempotency guard per `release-notes-standard.md § 5.5`):**

   ```bash
   # Read current state via gh release view
   if gh release view "v<X.Y>" --repo {REPO} >/dev/null 2>&1; then
     # State 1 or 2 — release exists; compare body
     EXISTING_BODY=$(gh release view "v<X.Y>" --repo {REPO} --json body --jq .body)
     CANONICAL_BODY=$(sed '1,/^---$/d; 1,/^---$/d' "$NOTES_PATH" 2>/dev/null)
     if [[ "$EXISTING_BODY" == "$CANONICAL_BODY" ]]; then
       echo "PASS — release v<X.Y> already at canonical state (State 2 no-op)"
     else
       # State 1 → State 2 transition via idempotent gh release edit
       gh release edit "v<X.Y>" --repo {REPO} --notes-file "$NOTES_PATH"
       echo "EDITED — release v<X.Y> body refreshed from canonical notes"
     fi
   else
     # State 0 — release does not exist; create
     # Extract headline from canonical notes H1; fallback to a sensible default if no H1 (per the FM-4 finding)
     HEADLINE=$(grep -m1 '^# ' "$NOTES_PATH" | sed 's/^# //' || echo "v<X.Y> Release")
     # If HEADLINE equals the bare version (headline extraction failed silently per the FM-4 finding), use "Release Notes" fallback
     if [[ "$HEADLINE" == "v<X.Y>" ]]; then
       HEADLINE="Release Notes"
     fi
     # MERGE_SHA may be obtained from prior Stage 12 capture OR from gh pr view of the release PR
     gh release create "v<X.Y>" \
       --repo {REPO} \
       --title "v<X.Y> — $HEADLINE" \
       --notes-file "$NOTES_PATH" \
       --target "$MERGE_SHA"
     echo "CREATED — release v<X.Y> published"
   fi
   ```

4. **Operator approval gate (AskUserQuestion):**
   - questionText: "Publish release v<X.Y> to GitHub Releases? (action: <CREATE | EDIT | NO-OP> based on preflight)"
   - options:
     - option: "Publish (apply state-machine action)"
       description: "Execute the determined action — `gh release create` for State 0, `gh release edit` for State 1, no-op for State 2. Surface 1 reaches steady-state regardless."
     - option: "Cancel"
       description: "Halt without state mutation. Operator may re-invoke Mode F later."
   - On Cancel: halt without state mutation.

5. **Apply + verify:**
   - Execute the state-machine action per Step 3
   - Verify final state: `gh release view "v<X.Y>" --repo {REPO} >/dev/null` — exit 0 = Surface 1 reached State 2
   - On any failure: present structured error (curl/gh error code + body); operator decides Retry / Escalate Tier 2 [SCOPE CHANGE]

6. **Report:**
   - State-machine final state (CREATED / EDITED / NO-OP)
   - Public release URL: `https://github.com/{REPO}/releases/tag/v<X.Y>`
   - Reversibility tier: CHEAP — `gh release delete v<X.Y>` removes the server-side release (tag preserved); re-invoke Mode F after delete to re-publish

### Mode G — Pattern Review Execute (EXECUTE phase)

**Trigger:** "pattern review execute", "execute pattern review", "apply pattern promotion manifest", or operator-explicit AUQ Step 2 Pattern Review Execute selection following a release-planner Mode D PROMOTE verdict + handoff manifest.

Mode G executes the write-phase of the split Pattern Review protocol (per [`core/governance/OPERATIONS.md`](../../../core/governance/OPERATIONS.md) § Pattern Review Cadence Protocol Rule 3 graduation procedure). Mode G is **operator-explicit**, NOT chained from release-planner: release-executor is not on the 4-skill cascade allowlist (per the dormant-branch note above + governance rule C5 in OPERATIONS.md Skill Chaining Protocol — outputs touch governance/state files). Operator invokes Mode G directly with the manifest from Mode D Step 7.

**Steps:**

1. **Input validation:**
   - Read `--manifest <path>` (operator-explicit input — typically the persisted manifest file from release-planner Mode D Step 7; OR a structured argv with cluster_id + approved_body_file pairs).
   - For each cluster entry, verify:
     (a) `approved_body_file` exists and is non-empty;
     (b) source_observation_ids resolve to OPEN GitHub issues carrying `observation` label;
     (c) operator PROMOTE verdict is explicit in the manifest (no inferred PROMOTE).
   - If any verification fails: halt with structured error; do not proceed to any write step.

2. **Pre-flight (release-executor-style drift check):**
   - `gh auth status` succeeds.
   - `RELEASE_LOG.md` exists at canonical path; tail row reads VERIFIED or DEPLOYED (Pattern Review row is appended AFTER the latest release row; do not append into mid-release state).
   - No other release is currently in progress (per Operating Principles pre-flight drift check rule).
   - On any FAIL: halt with structured error; manifest is not consumed.

3. **Per-cluster Execute (snapshot-first not required — no file modifications, only GitHub state):**
   For each cluster in the manifest:
   a. **File the new Proposal:** `gh issue create --repo {REPO} -F <approved_body_file> --label "improvement" --label "status: proposed" --title "<title-from-body>"` (`{REPO}` = the workspace-constant repo slug used throughout this skill). Capture the new issue number → `<new_proposal_id>`. The body is the LITERAL `<approved_body_file>` content; NO modification, NO synthesis post-approval (per the LITERAL-body operator approval gate + the Mode D failure-mode entry).
      - **Category travels in the body, not as a label.** Do NOT pass a `--label "category: <X>"` token: no `category:`-prefixed label exists in the live taxonomy (`gh label list --search category` → empty), so a `category:` `--label` makes `gh issue create` fail at runtime. The live scheme applies a **type label** (`skill-update` / `protocol` / `structure` / `documentation` / `enhancement` …) at Triage, not a `category:` prefix; the Category value is carried as body content per the 9-field Proposal mapping that the `<approved_body_file>` already encodes. Pass only the two labels above (`improvement` + `status: proposed`); a type label is applied later at Triage. (Read-back in Step 3.d asserts only `improvement` + `status: proposed`, consistent with this.)
   b. **Post close comment on each source observation:** for each `obs_id` in `cluster.source_observation_ids`: `gh issue comment <obs_id> --body "Promoted to #<new_proposal_id> via Pattern Review YYYY-MM-DD per OPERATIONS.md § Pattern Review Cadence Protocol Rule 3."`.
   c. **Close each source observation:** `gh issue close <obs_id> --reason "not planned"` (per `decision-discipline.md` § 4.2 emergence semantics — source observations are not rejected, they are subsumed into the Proposal).
   d. **Read-back verification per write-verify operating principle:** `gh issue view <new_proposal_id> --json state,labels,body` → assert state=OPEN, labels include `improvement` + `status: proposed`, body matches `<approved_body_file>` content. On mismatch: halt; report which cluster failed at which step; offer rollback (re-open source observations via `gh issue reopen` + delete new Proposal via `gh issue delete` — Mode G's rollback path is reversible per its CHEAP/MODERATE reversibility tier).

4. **Append Pattern Review row to RELEASE_LOG.md:**
   - Read `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>` (resolved per OPERATOR_INSTANCE_RELEASE_LOG_PATH variable).
   - If the file lacks a `## Pattern Reviews` H2 section, create it appended at end-of-file (one-time bootstrap).
   - Append one row to the `## Pattern Reviews` H2 table with columns:
     `| YYYY-MM-DD | <trigger T1/T2/T3/T4> | <observations_scanned_count> | <clusters_surfaced_count> | <verdicts_summary> |`
   - Read back the file; assert the row is present at expected line; if not, halt with write-verify failure.

5. **Emit pattern-review-row event** to `<OPERATOR_INSTANCE_PIPELINE_EVENT_LOG>` per the schema in [`core/governance/OPERATIONS.md`](../../../core/governance/OPERATIONS.md) § Pattern Review Cadence Protocol Rule 5.

6. **Report:**
   - Present execution summary:
     - Clusters processed (count + list)
     - Proposals filed (new issue numbers)
     - Observations closed (issue numbers + new_proposal mapping)
     - RELEASE_LOG row appended (Pattern Review date + trigger)
     - pattern-review-row event emitted (timestamp)
     - Any warnings or partial failures encountered
   - Apply Reversibility Discipline tier:
     - Each cluster's PROMOTE execution: **MODERATE · confidence: HIGH** when read-back succeeded (new Proposal can be deleted, source observations can be re-opened; rollback path exists and is documented at Step 3.d).
     - The Pattern Review row in RELEASE_LOG: **MODERATE · confidence: HIGH** (row is appended; revertable via `git revert <commit-SHA>` if committed, OR direct file-edit to remove the row).

**Reversibility tier of overall Mode G output:** MODERATE · confidence: HIGH. Rollback path: `gh issue reopen <obs_id>` for each source observation + `gh issue delete <new_proposal_id>` for each new Proposal + manual RELEASE_LOG.md row removal + pipeline-event-log line removal. Window: bounded by audit-of-record consumption — once a downstream Mode D or release cycle references the Pattern Review row, the verdict becomes audit-of-record and rollback transitions to IRREVERSIBLE (per the broader release-executor Reversibility Discipline tier ladder).

## What This Skill Does NOT Do

- Does not generate release plans (release-planner's job)
- Does not produce dry-run diffs (release-planner's job)
- Does not execute without an approved plan with Dry-Run Record
- Does not skip the snapshot step under any circumstances
- Does not skip user approval for the execute step

## Reversibility Discipline

This skill's primary posture is **executing an approved plan with a Dry-Run Record** —
the plan was the decision; the skill is the executor. However, the skill produces
**decision-class outputs** at multiple exception points: Mode A halt-with-error decisions
when pre-flight drift or snapshot failures occur, Mode A mid-release rollback
recommendations when file writes fail, Mode B verification NEEDS-ATTENTION verdicts,
Mode C rollback plan proposals, snapshot-retention prune recommendations, and the overall
execution summary with warnings/issues. Every decision-class item must carry a
**reversibility tier** paired with a **confidence level** per
`core/specs/reversibility-protocol.md`.

**Decision-class outputs in this skill:**

- Mode A halt-with-error decisions — when drift check fails, when Dry-Run Record is missing, when a snapshot write fails, the skill proposes halting and the user decides whether to proceed, retry, or abort.
- Mode A "offer rollback" recommendations — when a mid-release file write fails, the skill presents rollback as an option.
- Mode A snapshot retention pruning — which oldest folder is eligible to prune (checks `_RETAIN` markers and `ROLLED BACK` exemptions).
- Mode A execution summary — files modified, IMPs closed, warnings/issues encountered (the warnings/issues rows are follow-up recommendations).
- Mode B verification verdicts (PASS/FAIL per check; overall VERIFIED or NEEDS ATTENTION) — the VERIFIED verdict is the ship-authorization record on the release's quality.
- Mode C rollback plan proposal — which files restore, what content changes; presented for user approval before execution.
- Mode C targeted fix recommendation — when beyond the active snapshot window, the skill proposes a targeted fix instead of full rollback.
- Mode D `Close Release` report — close-out summary (chore PR merged, Milestone closed, RELEASE_LOG VERIFIED, manual-close list with D-1 rationale for the auto-close anomaly where a PR's `closes #N` references did not auto-close all release issues, requiring manual closure). The summary is the operator's audit trail of what Stage 13 did and is the artifact the operator references when answering "did the release close cleanly?".
- Mode D auto-close anomaly remediation — when Phase 4 detection finds open release issues, the manual-close list is a proposed action (operator-authorized D-1 pattern for the observed auto-close anomaly where some release issues stayed open despite a `closes #N` reference). Operator approves the list at Step 4 Apply gate before script Phase 14 executes the `gh issue close --comment` calls.
- Mode D pre-flight halt decisions — when Stage 12 chore PR hasn't landed (DEPLOYED row missing) or annotated version tag doesn't exist, script halts at Phase 2; the skill presents the failure for operator judgment (re-run after Stage 12 lands, or escalate Tier 2 [SCOPE CHANGE]).

Note: the *act of executing an approved RI / file modification per the plan* is not itself a decision-class output of this skill — the plan was the decision.

**Tier vocabulary (undo threshold + stakeholder impact):**

- **CHEAP** (undo in hours) — a pre-flight halt before any snapshot is taken or file is written; a snapshot-retention prune recommendation the user can countermand before execution; an execution-summary warning about a recoverable issue; a Mode D pre-flight halt before any chore branch is created (no chore PR exists yet); a Mode D dry-run preview reviewed by the operator and modified before apply (no state mutation yet). State the tier. Proceed.
- **MODERATE** (undo in days, minor data loss acceptable) — a mid-release halt after some IMPs have been executed but before RELEASE_LOG.md or SESSION_STATE.md are updated (rollback-to-snapshots is straightforward); a Mode B verification FAIL verdict that triggers a remediation cycle; a Mode C rollback plan circulated for approval; a Mode D chore PR merged (revertable via `git revert <merge-SHA>`); a Mode D Milestone closed (re-openable via `gh api -X PATCH -F state=open`); a Mode D RELEASE_NOTES scaffold landed without operator prose-fill (operator edits in follow-up commit on main or via Tier 1 [ADJUST]). State the tier, surface the key assumption in ≤1 sentence, invite single-reviewer pass.
- **EXPENSIVE** (undo in weeks, stakeholder impact) — a Mode C rollback executed after the release has been live (restoring snapshots but after downstream consumers have already read the new state); a Mode B verification NEEDS ATTENTION on a release that was already tagged and communicated to stakeholders (requires re-verification + correction); a snapshot-retention prune of a folder that turns out to have been needed for a post-release rollback attempt; a Mode D per-issue manual close at Phase 14 (reversible via `gh issue reopen <N>` but reopen + re-context is days of stakeholder catch-up); a Mode D orphan-cleanup ran with `--apply --force` (Tier 1 destructive within workspace; recoverable from git reflog + Trash but day-of investigation). State the tier, document rationale (≥2 sentences), state rollback plan (restore from retained snapshot if within window; reconstruct from plan's Dry-Run Record if beyond window), name the affected cohort (operator, downstream consumers, stakeholders notified of the original release).
- **IRREVERSIBLE** (cannot undo) — a release execution whose files have been pulled, deployed via `deploy.sh`, and consumed by downstream automations (the deployment is an audit-of-record); a Mode B VERIFIED verdict entered into `RELEASE_LOG.md` that has been referenced by subsequent releases as the baseline; a Mode C targeted-fix beyond the active snapshot window that itself becomes the new baseline (no reversal path); a Mode D VERIFIED transition that downstream releases consume as their baseline anchor (the operator may revert mechanically, but if subsequent releases have referenced the VERIFIED state in their own LOG rows, the verdict becomes audit-of-record). State the tier, document rationale, state rollback is infeasible or name the counter-commitment (a corrective release that supersedes, with explicit deprecation note in `RELEASE_LOG.md`), name the sign-off authority (operator, platform owner), pair with explicit downside description.

**Label format** (any accepted):

- Inline: `Recommendation (MODERATE · confidence: HIGH): <text>` — e.g., on a Mode A halt decision or a Mode C rollback plan proposal.
- Trailing: `<text> [MODERATE · confidence: HIGH]` — e.g., on a Mode B verification row or a snapshot-retention prune recommendation.
- Structured column: tier value in a `Reversibility` or `Tier` column of the Mode A execution summary, Mode B verification report, or Mode C rollback plan.
- Structured frame: tier value populated alongside each warning/issue row in the execution summary, each verification check result, and each rollback plan item.

Confidence values: `HIGH` / `MEDIUM` / `LOW`. Reversibility is *what-if-wrong cost*;
confidence is *how-likely-wrong*. Both travel together. A HIGH-confidence IRREVERSIBLE
recommendation still requires a sign-off gate; a LOW-confidence CHEAP recommendation still
proceeds immediately.

**Enforcement (inline, since this skill has no `## Guardrails` section):** When
pmo-qa-auditor Mode A audits an output of this skill (an execution summary,
verification report, or rollback plan), G4 will FAIL the output if any decision-class
item lacks a reversibility tier label. See
`core/specs/reversibility-protocol.md` for the full protocol and
`core/skills/pmo-qa-auditor/SKILL.md` G4 for the 4-step auditor algorithm.

## Guardrails (Platform)
Inherits CLAUDE.md § Universal Preferences and § Quality Standards. See the source
for the authoritative list. Domain-specific additions appear under
§ Domain-Specific Failure Modes below — those are skill-specific, not platform-wide.

## Domain-Specific Failure Modes

These domain-specific anti-patterns coexist with the `## Operating Principles` (platform-
wide generic guardrails including plan-driven, snapshot-first, write-verify, atomic
intent) and `## Reversibility Discipline` (decision-class output discipline). Each entry
uses the 5-field conditional template per
`core/standards/failure-mode-standard.md`. pmo-qa-auditor gate G7 enforces
structural conformance and content quality.

### Mode A execution without a Dry-Run Record in the plan — PROC

- **Signature (observable signal):** Mode A proceeds past input validation when the
  release plan file at `releases/plans/[version]_RELEASE_PLAN.md` has no
  `## Dry-Run Record` section, or the section is present but empty / contains only
  placeholder text.
- **Conditional:** do NOT execute a release in Mode A when the plan file lacks a
  populated Dry-Run Record section, because the Dry-Run Record is the operator's signed
  approval of the exact file changes about to apply — execution without it turns an
  approved plan into an unreviewed bulk edit across governance files, and the plan-
  driven operating principle treats this as a hard halt.
- **Root cause:** The plan itself is approved (Milestone closed, issues assigned); the
  Dry-Run Record feels like paperwork downstream of that approval. Under execution
  pressure — the operator is waiting for the release to ship — the check for a specific
  subsection feels redundant.
- **Mitigation:** At Mode A Step 1 Input validation, read the plan file, search for the
  `## Dry-Run Record` header, verify at least one diff block exists under it — then
  branch by lineage. On a **Cowork-lineage plan** (Dry-Run Record + snapshot protocol
  expected): on absence or empty record, halt with "Release plan has no Dry-Run Record.
  Run release-planner Mode C first." — do not proceed to snapshot or execution steps. On
  a **git-native plan** (plan under `release/releases/plans/`, Stage-12 PR/tag/deploy.sh
  execution): the absent Dry-Run Record is lineage, not a missing artifact — the
  execution surface is the pipeline (the PR diff is the dry-run review) and this skill
  contributes Modes B/D/E/F; do NOT route to release-planner Mode C. (The `Mode A
  snapshot execution invoked for a git-native release — TRIG` entry governs the
  git-native path; this entry governs the Cowork-lineage path.)
- **Principal response vs. junior response:** On a Cowork-lineage plan, Principal halts
  and points to release-planner Mode C. On a git-native plan, Principal recognizes the
  absent record as lineage and routes to the pipeline / Mode B/D/E/F. Junior proceeds
  (or mis-routes a git-native plan to Mode C) because the plan is otherwise approved, and
  the operator discovers after the fact that governance files were modified without a
  reviewed diff, or that a git-native release was dead-ended at a Cowork-only halt.

### Snapshot write partial-success proceeding to execute — PROC

- **Signature (observable signal):** Mode A Step 3 snapshot results show one or more
  snapshot files missing from `_snapshots/[version]/`, or present but empty (zero
  bytes), and Step 5 IMP execution proceeds anyway with a "most snapshots succeeded"
  rationale.
- **Conditional:** do NOT proceed past Step 3 when any snapshot write failed or produced
  an empty file, because snapshots are the only rollback mechanism within the active
  window — executing without complete snapshots creates an unrollable release, and the
  snapshot-first operating principle treats partial snapshot success as total failure
  for the purposes of the proceed gate.
- **Root cause:** Disk-full or permission-error conditions produce ambiguous partial
  successes — most snapshots land, one or two fail. Optimism bias ("the one that failed
  probably isn't the one we'll need") closes the ambiguity toward proceeding rather
  than halting.
- **Mitigation:** After Step 3, enumerate every expected snapshot file; verify each
  exists with non-zero size; when any verification fails, halt with error details
  listing the specific failed snapshots; do not offer a proceed-anyway option.
- **Principal response vs. junior response:** Principal halts on partial success and
  surfaces the specific failures for operator judgment. Junior proceeds, the release
  executes, and a subsequent rollback attempt discovers the missing snapshot precisely
  when it was needed.

### Write-verify skipped after file modification — INPUT

- **Signature (observable signal):** Mode A Step 5 execution summary marks an IMP
  successful immediately after the file-modification call returns, with no subsequent
  read-back of the modified file to confirm the expected change is present in the file
  content.
- **Conditional:** do NOT mark an IMP successful when the modified file has not been
  read back to verify the write landed, because the write-verify operating principle
  exists to catch silent write failures — disk full, permission error, concurrent
  locks, editor race conditions — that otherwise produce a release tagged in
  RELEASE_LOG.md but never actually applied to the file content.
- **Root cause:** The file-modification tool call returned without error, which feels
  like sufficient evidence of success; the read-back step is a separate tool call that
  adds token and time cost per IMP.
- **Mitigation:** After every file modification, read the file back; locate the expected
  change by content match; on match, mark the IMP successful and proceed; on miss, halt
  and report the specific IMP and file where the write did not land — offer rollback
  to that IMP's snapshot.
- **Principal response vs. junior response:** Principal reads back and confirms every
  write. Junior trusts the return value, marks the IMP successful, and the silent write
  failure surfaces only at the next session when the supposedly-applied change is
  absent.

### Mode C rollback beyond active window without counter-commitment path — HAND

- **Signature (observable signal):** Mode C rollback is requested for a release older
  than the active snapshot window (beyond the last 3 retained releases); the skill
  attempts a "full rollback" by reading snapshots that no longer exist, or the
  targeted-fix-from-Dry-Run-Record path is not offered to the operator.
- **Conditional:** do NOT execute a full rollback in Mode C when the release is beyond
  the active snapshot window and the Dry-Run Record reconstruction has not been offered
  as the counter-commitment, because snapshots outside the window have been pruned —
  attempting "full rollback" restores incomplete state — and the protocol requires
  targeted-fix-from-Dry-Run-Record as the correct path, built from the plan's recorded
  before/after content rather than from deleted snapshots.
- **Root cause:** Rollback feels symmetric to execution — "just restore the snapshots" —
  and the active-window boundary is easy to forget when the request arrives without a
  reminder. The targeted-fix path is a separate code path that requires reading the
  plan rather than the snapshot directory.
- **Mitigation:** On Mode C invocation, compute the release's distance from the active
  snapshot window (count of retained snapshot folders); when beyond, present the
  targeted-fix-from-Dry-Run-Record path first, with the specific before/after content
  extracted from the plan; do not offer full rollback as a valid option when snapshots
  are gone.
- **Principal response vs. junior response:** Principal computes the window, offers
  targeted fix with the specific plan-recorded before/after blocks. Junior starts a
  rollback anyway, reads a non-existent snapshot directory, and reports a rollback
  failure when a targeted fix would have worked.

### Mode D close-out before Stage 12 chore PR landed — PROC

- **Signature (observable signal):** Mode D pre-flight succeeds and proceeds to apply,
  yet `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>` does not contain a row for `v<X.Y>` in
  DEPLOYED state; OR Mode D apply attempts the DEPLOYED → VERIFIED transition on a row
  that does not yet exist (Stage 12 chore PR has not merged).
- **Conditional:** do NOT proceed past Mode D pre-flight when the v<X.Y> RELEASE_LOG row
  is absent or its trailing pipe state is anything other than DEPLOYED, because the
  Stage 13 chore PR transitions the row state — the row MUST exist in DEPLOYED state
  for the transition to apply, and absent rows indicate Stage 12 chore PR has not
  landed, which means Phase A.5 / Phase A.6 / Phase B0 of Stage 12 may not have run,
  and Stage 13 close cannot validly run before its upstream stage completes.
- **Root cause:** Hub mis-orchestration — Stage 12 sub-task closed prematurely
  (operator marked closed before chore PR merged), OR Stage 12 chore PR merge was
  attempted and silently failed (mergeStateStatus DIRTY or BLOCKED resolved by operator
  action that did not actually merge), OR Mode D was invoked manually outside the hub
  sequence on a release whose Stage 12 chore PR is still open.
- **Mitigation:** Script `preflight()` Phase 2 step (d) explicitly greps RELEASE_LOG.md
  for the `| v<X.Y>-<slug> | ... | DEPLOYED |` row pattern; on absence or wrong-state,
  halt with structured error naming the missing precondition (Stage 12 chore PR
  landing) and the verification command (`gh pr list --state merged --head
  chore/v<X.Y>-stage-12-release-log --json mergedAt`); do not proceed to chore branch
  creation. Mode D Step 2 receives the structured error verbatim and presents it to the
  operator without retry.
- **Principal response vs. junior response:** Principal halts on pre-flight FAIL,
  surfaces the specific missing precondition with a remediation pointer to Stage 12,
  and waits for operator decision. Junior proceeds because "the release plan says we're
  at Stage 13," script Phase 6 sed-edit silently fails to match (the row doesn't
  exist), and the chore PR ships with no RELEASE_LOG transition, leaving the release in
  an indeterminate state on main.

### Mode E Section 6a fabricated user-impact absent from grounded inputs — INPUT

- **Signature (observable signal):** Mode E draft Section 6a bullet asserts a
  user-observable impact claim ("X is now Y% faster", "Z now handles W use case",
  "request latency dropped by N%") that does not appear in any input artifact —
  closed-issue body, release plan section, or RELEASE_LOG row. Detection: grep the
  drafted bullet's specific claim against the union of input texts; a claim with no
  source match is fabricated.
- **Conditional:** do NOT include user-impact claims in Mode E Section 6a bullets
  when the claim cannot be sourced to a closed-issue body, release plan section, or
  RELEASE_LOG row, because §2.5 Rule 2 (voice constraint) prohibits invented
  percentages and impact metrics, and Mode E's automated authoring amplifies the
  fabrication risk by removing the human-in-the-middle who would otherwise catch a
  generalization-to-specific leap before publication.
- **Root cause:** User-impact claims are the natural shape of the §2.2 "Why it
  matters" beat; Mode E is structurally incentivized to produce strong beats on every
  6a bullet. When the input artifacts describe a category of change ("performance
  improvement", "lookup optimization") without a measured value, Mode E may
  generalize from the category to an invented specific ("30% faster") to fill the
  beat slot. The fabrication is plausible-sounding and difficult to detect at the
  Step 5 operator-review gate if the operator is reviewing voice rather than
  cross-checking claims against sources.
- **Mitigation:** Mode E Step 3 enforces source-citation discipline — every Section
  6a impact claim carries an inline citation to its source input (closed-issue
  number, release plan section anchor, or RELEASE_LOG row line). Un-citable impact
  claims are omitted per §2.5 Rule 1 (fabricate-or-omit) and the bullet is rewritten
  to describe only the capability without invented impact. Mode E Step 4 self-lint
  scans each 6a bullet for capability-with-claim patterns and verifies a citation
  exists in the union of inputs; bullets with no source match are flagged before
  presentation.
- **Principal response vs. junior response:** Principal omits the un-cited impact
  claim and lets the capability stand on its own ("Risk register re-sorts when the
  date filter changes" without an invented "now 50% faster" addendum); the §2.2 beat
  cites the user-observable change directly. Junior generalizes from category to
  invented specific because the bullet "needs" the impact half of the beat, and the
  fabrication slips past Step 4 self-lint because the bullet reads as plausible.

### Mode E Section 6a banned-jargon leakage from operator-grade inputs — OUT

- **Signature (observable signal):** Mode E draft Section 6a contains a §2.4
  banned-jargon term ("reflexive-pipeline self-exemption", "mirror byte-identity",
  "warn-mode posture", "cutover effective date", "schema vX.Y → vX.Z", etc.). Check
  20 (`lint_release_corpus.py --check note-content` check L10) would flag at lint
  time; in Mode E this surfaces before lint because the term appears in the input
  texts and Mode E surfaces it verbatim.
- **Conditional:** do NOT include §2.4 banned-jargon terms in Mode E Section 6a
  output, because §2.4 enumerates terms that Layer A readers do NOT recognize —
  leakage violates the layered-disclosure contract (user-facing section uses
  operator-grade phrasing the user cannot parse) and undermines the entire reason
  for the 6a/6b split.
- **Root cause:** Mode E reads operator-grade input artifacts (RELEASE_LOG, release
  plan, closed-issue bodies, ADR documents) where the jargon is everywhere — the
  inputs are the canonical source of the terminology Mode E synthesizes from. Without
  an explicit §2.4 filter step between input reading and 6a drafting, Mode E
  surfaces operator-grade phrasing verbatim into 6a because that is the phrasing
  present in the source material.
- **Mitigation:** Mode E Step 3 applies §2.4 banned-jargon scan as a hard filter on
  every Section 6a candidate sentence; flagged terms are replaced with the §2.4
  "Plain-language equivalent for 6a" column value verbatim (e.g., "warn-mode
  posture" → "logged but not blocking"; "cutover effective date" → "applies to
  releases after vX.Y"). Mode E Step 4 self-lint runs the Check 20 L10 equivalent
  in-process against the drafted 6a before presenting to the operator-review gate.
  Persistent leakage after one iteration is surfaced inline with the FAIL list.
- **Principal response vs. junior response:** Principal applies the §2.4 filter as
  a deliberate Step-3 sub-step and replaces every banned term with the canonical
  plain-language equivalent; the 6a draft reads as plain language to the Layer A
  audience. Junior surfaces operator-grade phrasing into 6a because "the release plan
  said it that way" — the lint catches some terms but not all, and the operator at
  Step 5 has to reject and ask for revision rather than approve.

### Mode E autonomous prose-fill bypassing §2.5 Rule 3 review on breaking releases — HAND

- **Signature (observable signal):** Mode E proceeds from Step 4 self-lint directly
  to Step 5 operator-review gate on a release where `breaking: true` OR
  `requires_action: true` OR any §2.5 Rule 3 trigger fires (Deprecation / Breaking
  change / State-mutating default change / Removal / New restriction); Step 6 Stage 9
  Plan Review escalation has not fired; the breaking-release draft note ships to the
  Step 5 gate without the human gate Rule 3 mandates.
- **Conditional:** do NOT proceed to Mode E Step 5 operator-review gate when §2.5
  Rule 3 triggers fire AND Stage 9 Plan Review of the note has not yet surfaced the
  draft, because Rule 3 mandates a human gate at Stage 9 for breaking-class releases
  — Mode E's Step 5 operator-review-at-Step-5 is necessary (it confirms voice and
  content) but not sufficient (it does not satisfy the Stage 9 review-surface
  contract).
- **Root cause:** Mode E's automated flow optimizes for a single review gate (Step
  5); the Stage 9 vs. Step 5 distinction is structurally invisible without an
  explicit characterization step (Step 2 computes `breaking` / `requires_action`).
  Under the pressure of a fast close-out, Mode E may treat Step 5 as the sufficient
  human gate and ship the breaking-release draft without surfacing it to Stage 9 —
  particularly when Step 2 characterization runs but Step 6 escalation does not
  fire because of a missing trigger check or a too-narrow trigger predicate.
- **Mitigation:** Mode E Step 6 inserts a mandatory Stage 9 escalation when any
  Rule 3 trigger fires — the draft is posted as a comment on the release PR with
  header "### Stage 9 Plan Review — release note for breaking release v<X.Y>"; Mode
  E awaits operator GO at Stage 9 before proceeding to Step 5 operator-review gate.
  On Stage 9 NO-GO, Mode E returns to Step 3 with the revision direction from the
  NO-GO comment. The escalation is structural — Mode E HALTS at Step 6 on any Rule 3
  trigger; Step 5 cannot fire until Stage 9 GO is recorded.
- **Principal response vs. junior response:** Principal fires the Stage 9
  escalation explicitly on any Rule 3 trigger, posts the draft as a PR comment with
  the canonical header, and waits for the Stage 9 GO comment before opening the
  Step 5 operator-review gate. Junior treats the Step 5 operator-review as Rule 3
  satisfaction and ships the breaking-release note without Stage 9 input — the
  release PR merges, the Stage 13 chore PR lands the note, and the breaking-change
  publication occurs without the human gate Rule 3 was designed to enforce.

### Mode F publish without verified tag on origin — INPUT

- **Signature (observable signal):** Mode F proceeds to `gh release create v<X.Y>
  --target "$MERGE_SHA"` without verifying the v<X.Y> annotated tag exists on `origin`
  via `git ls-remote --tags origin "v<X.Y>"`; the `gh release create` invocation
  fails with `Could not find tag v<X.Y>` server-side OR succeeds against an
  out-of-band-pushed tag that does not match the captured `$MERGE_SHA` from Stage 12
  Phase B1 (creating a release tied to a non-canonical commit).
- **Conditional:** do NOT call `gh release create` in Mode F when the v<X.Y>
  annotated tag is NOT present on `origin` via `git ls-remote --tags origin "v<X.Y>"`,
  because GitHub Releases bind to a tag ref — calling create against a missing tag
  produces a server-side error AND surfaces a confusing failure mode (the tag-push
  step at Stage 12 Phase B3 is the explicit precondition; a missing tag indicates
  Stage 12 did not complete or `git push origin v<X.Y>` failed silently).
- **Root cause:** Mode F's preflight has two related but distinct assertions: (a)
  the tag exists locally (`git tag --list v<X.Y>` non-empty) AND (b) the tag is
  pushed to `origin` (`git ls-remote --tags origin "v<X.Y>"` returns the ref). Mode F
  must assert (b), not (a). A local-only tag would let `--target "$MERGE_SHA"` resolve
  syntactically but `gh release create` resolves the tag against the GitHub repo,
  not the local clone — local-only is insufficient. Without the `ls-remote` preflight,
  the create call's server-side error is the first signal, by which point the
  operator has consumed a chunk of the gh API rate budget for the failed request.
- **Mitigation:** Mode F Step 2 preflight executes `git ls-remote --tags origin
  "v<X.Y>" | grep -q "v<X.Y>"`; on non-zero exit, HALT with structured error citing
  Stage 12 Phase B3 as the precondition + the canonical recovery (`git push origin
  v<X.Y>` from the worktree where the tag exists locally, OR re-invoke the Stage 12
  spoke if the tag was never created). Mode F does NOT proceed to the view-then-create-or-edit
  state machine until ls-remote returns the tag. Per the FM-3 finding: `git ls-remote --tags origin` is the SINGLE source of truth for
  tag-existence assertion; the `gh release create --verify-tag` flag is intentionally
  OMITTED from Mode F's invocation (the ls-remote preflight produces a clearer
  protocol-layer error message than `--verify-tag`'s gh-CLI error).
- **Principal response vs. junior response:** Principal asserts both (a)
  tag-pushed-to-origin AND (b) `$MERGE_SHA` matches the tag's annotated commit before
  any state-mutating gh call; the preflight catches Stage-12-not-complete states
  early with a clear protocol-layer error pointing to the canonical recovery. Junior
  skips the ls-remote preflight, calls `gh release create` directly, and reads the
  server-side `Could not find tag` error as a Mode F bug rather than as a Stage 12
  Phase B3 precondition gap.

### Mode F publish-create when canonical RELEASE_NOTES file is not on origin/main — PROC

- **Signature (observable signal):** Mode F's preflight at Step 2 confirms the
  notes file exists in the worktree via `[[ -f "$NOTES_PATH" ]]` but does NOT verify
  the file is committed to `origin/main` (i.e., the file may exist on a feature
  branch or chore-PR branch that has NOT yet merged). Mode F proceeds to `gh release
  create v<X.Y> --notes-file "$NOTES_PATH"`, publishing a GitHub Release with content
  from a pre-merge branch. Two failure consequences: (1) the notes file's eventual
  on-main content (after operator edit during chore PR review) differs from the
  published Surface 1 — observable as content drift between `gh release view v<X.Y>
  --json body` and `git show origin/main:release/releases/notes/v<X.Y>_RELEASE_NOTES.md`;
  (2) re-invocation of Mode F post-merge correctly enters State 1 (release exists,
  content differs) and applies `gh release edit` — but the operator has a window of
  published-but-stale public content.
- **Conditional:** do NOT call `gh release create` in Mode F when the canonical
  `release/releases/notes/v<X.Y>_RELEASE_NOTES.md` is NOT committed to
  `origin/main`, because Surface 1 must reflect the canonical-on-main content (per
  `release-notes-standard.md § 5.2` single source-of-truth principle); publishing
  from a pre-merge branch breaks the contract and creates observable content drift
  between `gh release view` and `git show origin/main:.../RELEASE_NOTES.md`.
- **Root cause:** Mode F's preflight conflates "file exists on disk" with "file is
  canonical." Pre-merge branches MAY contain the file (Stage 13 chore PR branch is
  the standard case); on-main content is the canonical reference per
  `release-notes-standard.md § 5.2`. Without an explicit `git show origin/main:...`
  test, Mode F proceeds against whatever the worktree currently shows, producing
  pre-merge content publication.
- **Mitigation:** Mode F Step 2 preflight executes `git show
  origin/main:release/releases/notes/v<X.Y>_RELEASE_NOTES.md >/dev/null 2>&1`;
  on non-zero exit (file not on origin/main), Mode F presents the operator with two
  routing options: (A) HALT and re-invoke Mode F after Stage 13 chore PR merges
  (canonical path — Surface 1 lands once on canonical content); (B) PROCEED with
  acknowledgment that re-invocation post-merge will apply `gh release edit` to
  refresh from canonical content (acceptable when operator needs Surface 1 published
  immediately for external comms, with planned `gh release edit` refresh post-merge
  per `release-notes-standard.md § 5.6` post-VERIFIED corrections procedure). The
  default routing is (A) HALT; (B) requires explicit operator acknowledgment per
  AskUserQuestion.
- **Principal response vs. junior response:** Principal asserts both
  file-exists-in-worktree AND file-on-origin-main before publishing Surface 1; the
  preflight catches pre-merge-publication cases and surfaces the routing decision to
  the operator explicitly. Junior treats `[[ -f "$NOTES_PATH" ]]` as the sufficient
  preflight, publishes from whatever the worktree shows, and the post-merge content
  drift is discovered only when an operator notices the GitHub Release body differs
  from the canonical note file on main — typically days later during a separate
  Mode B Verify pass.

### Mode G filed Proposal synthesized post-approval rather than from literal approved-body file — INPUT

- **Signature (observable signal):** Mode G Step 3.a invokes `gh issue create` with a `--body` argument constructed at execute-time from manifest fields + cluster metadata, rather than `-F <approved_body_file>` reading the literal body the operator approved at release-planner Mode D Step 6.
- **Conditional:** do NOT call `gh issue create` in Mode G without `-F <approved_body_file>` pointing to the operator-approved body file from the Mode D handoff manifest, because the manifest contains the LITERAL body that operator approved via the Decision Briefing verbatim-render — synthesizing a new body at execute time (even from "the same inputs") produces a filed Proposal the operator did not literally pre-approve, violating the LITERAL-body operator approval gate and the C5 cascade approval-rule keyed on operator reviewing the artifact (not the verdict abstraction).
- **Root cause:** [systemic pattern: re-render-from-source instead of consume-as-approved] → [proximal cause: Mode G inputs include both the approved body file AND the cluster metadata; re-rendering from metadata feels "cleaner" but loses the operator-approval bond] → [observable signal: filed issue body differs from the Mode D Decision Briefing's inline-rendered body even though both derive from the same cluster].
- **Mitigation:** Mode G Step 3.a MUST invoke `gh issue create -F <approved_body_file>`; the `<approved_body_file>` is read verbatim — Mode G performs no string-templating, no field substitution, no re-rendering. The manifest's `approved_body_file` field is the load-bearing artifact; cluster metadata is informational only (used for label assignment and title extraction via `head -1` of body, not body synthesis).
- **Principal response vs. junior response:** Principal treats the approved-body file as immutable input — `gh issue create -F <file>` is the verbatim consumer; cluster metadata informs only labels/title extraction. Junior re-synthesizes the body from manifest fields because "the inputs are the same and re-rendering is cleaner" — producing a filed Proposal whose body the operator never literally approved.

### Mode A snapshot execution invoked for a git-native release — TRIG

- **Signature (observable signal):** "Execute the release" / "deploy v[X.Y]" for
  a release whose execution mechanism is the git pipeline — a release branch
  whose PR merge IS the deploy, Stage 12 tagging, and deploy.sh — is routed into
  Mode A, which begins creating snapshot copies and applying file edits
  directly, duplicating or fighting the PR-based execution path.
- **Conditional:** do NOT execute a release through Mode A's snapshot-and-apply
  machinery when the release is a git-native release whose plan executes via PR
  merge, tag, and deploy.sh at Stage 12, because the two execution paths are
  distinct by design — the Cowork path uses snapshots as its only review and
  rollback surface, while the git path's PR diff is the review and git history
  is the snapshot — and applying Mode A to a git-native release double-executes
  changes outside the release branch, bypassing the PR review the governance
  path requires.
- **Root cause:** The trigger set ("execute the release", "deploy vX.Y", "ship
  vX.Y") predates the dual-path split and reads identically for both lineages;
  Mode A is this skill's headline mode, and nothing in its input validation
  asks WHICH execution path the release plan declares.
- **Mitigation:** At Mode A input validation, read the plan's execution context:
  a plan on a release branch with PR-based execution (plans under
  release/releases/plans/, Stage 12 obligations) → the execution surface is the
  pipeline (merge, tag, deploy.sh) and this skill's in-scope contributions are
  Mode B verification and Mode D/E/F close-out; a Cowork-path plan with a
  Dry-Run Record and snapshot protocol → Mode A proceeds. On a git-native plan
  the absent Dry-Run Record is lineage, not a missing artifact — the
  Dry-Run-Record PROC entry above governs Cowork-lineage plans only. Name the
  path explicitly in the execution report.
- **Principal response vs. junior response:** Principal identifies the
  git-native plan, declines snapshot execution, points to the Stage 12 sequence
  — then runs Mode D when close-out is the actual need. Junior snapshots
  twenty-three files and starts applying edits to the working tree while the
  release branch holds the same changes awaiting PR review, and the operator
  must untangle a double-applied release.

### Mode inferred from trigger phrasing on a direct invocation — TRIG

- **Signature (observable signal):** A direct (non-chained) invocation proceeds
  straight into a mode because the phrasing "obviously" matched — "something
  broke" routes to Rollback, "finalize v1.10" routes to Close — without the
  mandatory AskUserQuestion mode gate this skill requires on every direct
  invocation.
- **Conditional:** do NOT auto-route to a mode from trigger phrasing on a direct
  invocation, because this skill is classified Always-ask — Execute and
  Rollback are inverse operations on shared release state, and a phrase-guessed
  misfire between them (executing when the operator wanted rollback readiness,
  rolling back when the operator meant verify) corrupts release state in a way
  that requires additional snapshots to repair.
- **Root cause:** Trigger-match heuristics are the platform's default
  mode-selection pattern, and most skills auto-route safely; the executor's
  exception (Always-ask) is easy to flatten back to the default under flow
  pressure, especially when the user's phrasing matches one trigger list
  verbatim.
- **Mitigation:** On every direct invocation, fire the AskUserQuestion mode gate
  before any mode-specific content — even when the phrasing seems unambiguous.
  The one-question cost is the designed price for the Execute/Rollback
  asymmetry; only chained invocations with a pre-filled mode token skip it (a
  dormant branch under the current cascade allowlist).
- **Principal response vs. junior response:** Principal asks the mode question,
  gets "Verify" where the phrase implied Rollback, and runs the read-only check
  the operator actually wanted. Junior pattern-matches "something broke" to
  Mode C, restores three files from stale snapshots over the operator's
  in-progress hotfix, and the recovery now needs its own recovery.

## Reference Files

Read these on first use:
- `references/execution-checklist.md` — Step-by-step execution protocol
- `references/verification-checklist.md` — Post-release QA checks
- `references/rollback-protocol.md` — Failure recovery procedures
- `references/progressive-rollout.md` — Executor realization of the progressive-rollout convention (`core/standards/progressive-rollout-convention.md`): the executor's `rollout-cycle` dispatch (shadow / warn / enforce), outcome-log, and gate-ladder seam for governance rules and the quality-gate ladder
- `references/close-out-checklist.md` — Stage-13 close-out checklist Mode D follows (audit → milestone → log → branch → evidence → carry-forward)
