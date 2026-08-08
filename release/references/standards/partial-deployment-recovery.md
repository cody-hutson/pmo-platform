---
title: Partial Deployment Recovery
purpose: Decision tree + assessment checklist + fix-forward/rollback paths for S-2 skill-deploy partial-failure class
type: standard
parallel_to: autonomous-execution-model.md
reversibility: CHEAP (forward-only protocol; pre-cutover releases exempt)
adr: "(none — D-AssessmentToolForm rendered at Stage 5 Collective Review, not as a separate ADR)"
consumers: "release/governance/release-process.md Stage 12 § Self-repair (cross-reference); release-executor SKILL.md Mode C (decision-tree-branching consumer, no Mode C semantic change)"
glossary_anchor: "(none)"
version: v12.12
---
<!-- reference-durability: allow-link -->

# Partial Deployment Recovery

## 1. Purpose

Stage 12 deployment can produce three distinct end states. Two of them — full success and full failure — are already governed: full success proceeds to Stage 13 Close; full failure invokes the [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md) Rollback Pattern under operator authorization. The third state — **partial failure**, where the git merge succeeds but individual S-2 skill-file `cp` operations partially fail — was previously unnamed. `RELEASE_LOG.md` declared the `Result: PARTIAL` enum value but no protocol governed the recovery branch.

This standard codifies a thin extension to the parent patterns in [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md): it does NOT introduce a 4th platform pattern. The 3-state decision tree below maps 1:1 to the existing Retry / Escalate / Rollback patterns, parameterizing them for the S-2 partial-failure class.

**Scope:** S-2 skill-file copy partial failure (git merge succeeds; one or more `cp` operations in `core/deploy/deploy.sh --deploy` fail). Pre-merge failure is **out of scope** — those phases (`pipeline/stage-12-execute.md` § Phase A.5 main-divergence pre-check / § Phase A.6 mergeStateStatus polling / § Phase B0 dependent-PR check) have their own escalation paths and nothing was deployed.

**Relationship to parent patterns:** Extends, does not duplicate. The parent patterns define the recovery primitives (Retry / Escalate / Rollback); this standard names the partial-state branch that the parent patterns left implicit, and parameterizes the trigger conditions + assessment + fix-forward / rollback mechanics for the S-2 partial-failure class.

## 2. Trigger conditions

The protocol fires at Stage 12 **Phase C Post-Deploy Verification** when verification surfaces a divergence from full-success state. The trigger condition is observable in three concrete ways:

- **Per-skill `diff` non-clean** — one or more deployed `SKILL.md` files do not match their git source (`diff -q <git-source> <Cowork-installed>` returns non-empty).
- **`core/deploy/deploy.sh --check` new FAILures attributable to this release** — at least one Check N in `core/deploy/deploy.sh --check` returns FAIL on a file touched by the release.
- **Operator manual observation** — operator notices a deployed skill behaves inconsistently with its source.

When ANY of the three is observed, the spoke proceeds to § 5 Assessment Checklist before rendering a recovery decision.

Upstream trigger reference: [`release/governance/release-process.md`](../../governance/release-process.md) § Stage 12 § Self-repair line (which cross-references this standard).

## 3. Decision tree

Three outcome states; each maps 1:1 to a parent pattern in [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md):

| Outcome state | Trigger | Pattern (per `autonomous-execution-model.md`) | Per-stage entry |
|---|---|---|---|
| **full-success** | Every deployed file: `diff` source-vs-installed clean AND `core/deploy/deploy.sh --check` returns zero new FAILures attributable to this release | (none required) | Proceed to Stage 13 Close per [`release-process.md`](../../governance/release-process.md) Stage 12 § Phase D |
| **partial-failure** | ≥1 deployed file `diff` non-clean OR ≥1 `core/deploy/deploy.sh --check` new FAILure attributable to this release, AND ≥1 deployed file `diff` clean | **Escalate Pattern** (Stage 12 escalate triggers: "retry-exhausted deploy") composes with assessment-then-fix-forward-or-rollback decision | § 5 (assessment) → § 6 (fix-forward) OR § 7 (rollback) |
| **full-failure** | All deployed files `diff` non-clean OR `core/deploy/deploy.sh --check` reports systemic regression (Check 1 / Check 2 / Check 7 mass-FAIL on the new release contents) | **Rollback Pattern** (operator-authorized only) | § 7 (rollback) |

The mapping is the load-bearing contribution of this standard — naming the partial-failure branch explicitly so spokes can route deterministically.

## 4. Per-state recovery actions

Each outcome state has a deterministic routing decision:

| Outcome | Spoke action | Operator gate | Reference section |
|---|---|---|---|
| full-success | Proceed to Stage 13 Close | None — automatic | (no recovery needed) |
| partial-failure | Run § 5 Assessment Checklist → present results to operator → operator renders fix-forward OR rollback decision | Operator decision required after assessment | § 6 (fix-forward) OR § 7 (rollback) |
| full-failure | Surface assessment results → recommend rollback → await explicit operator authorization | **Operator authorization required** per [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md) § Rollback Pattern Authorization requirement — OPERATOR-ONLY | § 7 (rollback) |

The spoke NEVER auto-initiates rollback even on full-failure — the assessment SURFACES the recommendation; the operator AUTHORIZES the execution.

## 5. Assessment checklist (5 checks)

Form factor: **inline checklist composing existing tooling** (per D-AssessmentToolForm (A) rendered at Stage 5 Collective Review). No new script is introduced. Each Check composes existing primitives (`diff`, `core/deploy/deploy.sh --check`, `python3 -c zipfile`).

Stage 12 spoke runs all 5 checks; records per-check outcome in sub-task output.

### Check 1 — Per-skill copy integrity (file-level)

- **Command:** `git -C ${HOME}/Claude diff --name-only` (primary; expects post-deploy clean state)
- **Per-skill repeat:** `diff -q <git-source-SKILL.md> <Cowork-install-SKILL.md>` AND `diff -q <git-source-SKILL.md> <~/<OPERATOR_INSTANCE_SKILLS_PATH>/<name>/SKILL.md>`
- **Outcome enum:** PASS (zero diff per skill) / FAIL-PARTIAL (≥1 skill diff non-clean, others clean) / FAIL-SYSTEMIC (every skill diff non-clean)

### Check 2 — `core/deploy/deploy.sh --check` regression (release-attribution)

- **Command:** `core/deploy/deploy.sh --check 2>&1 | tee /tmp/v<X.Y>-postdeploy-check.txt`
- **Filter:** subtract pre-merge baseline (Stage 9 `core/deploy/deploy.sh --check` output recorded in release plan Verification Evidence) from post-merge output
- **Outcome enum:** PASS (zero new FAILs attributable to this release) / FAIL-PARTIAL (≥1 new FAIL on a subset of release-touched artifacts) / FAIL-SYSTEMIC (new FAILs span every release-touched artifact)
- **Attribution rule:** a Check N FAILure on file F is attributable to this release iff F is in the release plan's File Change Matrix OR `git log --follow --oneline F` shows the release branch's merge SHA as F's most recent touch

### Check 3 — `.skill` package freshness (per modified skill)

- **Command (per skill):**
  ```bash
  python3 -c "import zipfile; z = zipfile.ZipFile('packages/<name>.skill'); print(z.read('SKILL.md').decode() == open('release/skills/<name>/SKILL.md').read())"
  ```
- **Equivalently:** re-run `core/deploy/deploy.sh --check` Check 7 (package freshness) filtered to release-touched skills
- **Outcome enum:** PASS (True per skill) / FAIL-PARTIAL (≥1 False, others True) / FAIL-SYSTEMIC (all False)

### Check 4 — Mirror-pair byte-identical (when release touches `core/rules/` ↔ `core/rules/`)

- **Command:** `core/deploy/deploy.sh --check` Check 9 outcome
- **Outcome enum:** PASS (all mirrors byte-identical) / FAIL-PARTIAL (≥1 mirror divergent, others identical) / FAIL-SYSTEMIC (every mirror divergent)

### Check 5 — Platform-consistency aggregator

- **Aggregation:** PASS iff Checks 1-4 all PASS; FAIL-PARTIAL iff ≥1 Check returns FAIL-PARTIAL AND zero return FAIL-SYSTEMIC; FAIL-SYSTEMIC iff ≥1 Check returns FAIL-SYSTEMIC
- **Outcome enum (decision-tree input):** full-success / partial-failure / full-failure (1:1 mapping to per-check outcomes)

**Why inline checklist over standalone script** (D-AssessmentToolForm (A) rationale): (a) each Check composes existing primitives — a wrapper adds maintenance burden without enabling behaviors not already accessible; (b) judgment-required steps (Check 2 attribution rule; Check 5 aggregation tiebreakers) require human triage and cannot be reduced to deterministic logic; (c) the protocol fires rarely (zero PARTIAL events across 50+ logged releases per RELEASE_LOG.md grep at survey commit `c0841ca`); (d) future iteration to a script wrapper is CHEAP if firing-frequency justifies it.

## 6. Fix-forward path

Triggered by Check 5 = partial-failure AND operator-authorized "fix-forward" decision (rendered after assessment review).

### Mechanism (4 steps, Tier 1 auto-execute after authorization)

1. **Identify failed copies** from Check 1 / Check 3 / Check 4 outcome enums (the per-skill / per-mirror divergence list).
2. **Retry per failure class:**
   - **S-2 SKILL.md copy failure** → `core/deploy/deploy.sh --deploy <name1> <name2> ...` with explicit skill list (manual mode, not auto-detect).
   - **Package staleness** → re-run `python3 -m scripts.package_skill <skill-dir> packages/` per affected skill; commit per Phase J.5 rebuild-then-commit pattern (chore PR with message `chore(<version>): rebuilt skill packages from Phase H deploy` — the canonical precedent message form).
   - **Mirror divergence (`core/rules/` ↔ `engineering/rules/`)** → manual `cp` of the canonical source over the divergent mirror; commit per Stage 12 chore-PR pattern.
3. **Re-verify via Check 1 + Check 3 + Check 4 + Check 5** until aggregator returns full-success.
4. **Update RELEASE_LOG.md visible-H4 Deployment Log** — append `Result: PARTIAL → SUCCESS (fix-forward: <N> retries; details: <file list>)` to the existing block. Per FM3 (§ 9), this update MUST land via the Stage 13 chore-PR pattern per [`release-process.md`](../../governance/release-process.md) Stage 13 § Chore PR convention — NEVER via direct-to-main commit.

### Precedent (Phase J.5 rebuild-then-commit pattern)

The Stage 12 Phase J.5 rebuilt-package commit pattern is structurally a fix-forward primitive for the cascade-modified-package class. Commit message: `chore(<version>): rebuilt skill packages from Phase H deploy`. Extension to S-2 partial-deploy: the same commit-and-verify discipline applies to S-2 retries; the difference is the failure class (orphan packages → rebuild script; partial S-2 copies → re-run `core/deploy/deploy.sh --deploy`).

**Gap closed:** Phase J.5 addresses the orphan-package class (Phase H ran successfully but the rebuild commit was missing); this standard addresses the partial-copy class (Phase H itself partially failed). Distinct mechanisms; complementary protocols.

### Self-repair posture

Retry the failed copy operations using Stage 12's production-impacting **cap=2** (per [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md) § Retry Pattern Production-impacting cap exception). On cap exhaustion: escalate to operator with the partial-state assessment; operator decides fix-forward-with-different-mechanism OR rollback.

## 7. Rollback path

Triggered by Check 5 = full-failure OR (Check 5 = partial-failure AND operator-authorized "rollback" decision after assessment review).

### Mechanism (8 steps per `autonomous-execution-model.md` § Rollback Pattern, agent-executed under operator authorization)

1. **Operator authorizes rollback** — explicit confirmation in chat or sub-task comment ("approved", "rollback v<X.Y>").
2. **Identify rollback target** — release merge commit SHA via `gh pr view <release-PR> --json mergeCommit --jq '.mergeCommit.oid'`.
3. **Execute** `git revert -m 1 <release-merge-SHA>` on a fresh worktree branch (e.g., `rollback/v<X.Y>`); push and create PR.
4. **Re-deploy previous skill versions** — `git revert` of the release merge naturally restores skill source content; `core/deploy/deploy.sh --deploy <name>` re-syncs the (now-reverted) source to install paths.
5. **Retain the release tag** — do NOT delete it. Version tags are host-protected and the remote delete is rejected for every account, the owner included, per [`git-workflow.md`](../../../core/rules/git-workflow.md) § Tag Retention. The tag stays as the historical record that the version was claimed and then withdrawn; step 8's RELEASE_LOG rollback entry is what records the withdrawal.
6. **Revert Stage 12 / Stage 13 chore PRs independently** — the chore PRs (RELEASE_LOG row + INDEX/DIGEST/RELEASE_NOTES updates) are separable from the release content. Per the chore-PR convention each chore PR is its own merge SHA and can be `git revert`ed independently. Sequence: revert release PR first → revert Stage 13 chore PR → revert Stage 12 chore PR.
7. **Reopen** all release issues; restore Status=Bundled; reassign Milestone v<X.Y>; revert `status: done` → `status: bundled` labels.
8. **Append `RELEASE_LOG.md` rollback entry** per [`RELEASE_PROTOCOL.md`](../../governance/RELEASE_PROTOCOL.md) § Rollback protocol — release version, files rolled back, reason, date. Update visible-H4 Deployment Log block: `Result: PARTIAL → ROLLED BACK (rollback PR <#>, reverted SHAs: <list>)`.

### Mode C invocation

[`release-executor` SKILL.md Mode C](../../skills/release-executor/SKILL.md) is the existing rollback entrypoint. **This standard extends the decision-tree branching (when to invoke Mode C from a partial-deploy outcome) but does NOT modify Mode C semantics.** Mode C reads `references/rollback-protocol.md` for the full procedure; the 8-step mechanism above is the git-native sequence Mode C executes.

### Authorization requirement — OPERATOR-ONLY

Per [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md) § Rollback Pattern Authorization requirement: "Agents do **NOT** initiate rollback autonomously. The Rollback Pattern is operator-authorized at every invocation — explicit confirmation in chat or a sub-task comment is required before the agent executes any of the 8 mechanism steps." This is the load-bearing distinction between Rollback and the other two patterns.

### Tag retention

The release tag created at Stage 12 Phase B3 is permanent. Version tags are protected at the repository host, so the tag cannot be deleted on the remote by any account — a rollback reverts the merge and leaves the tag in place, per [`git-workflow.md`](../../../core/rules/git-workflow.md) § Tag Retention. This costs nothing: the tag points at a commit that remains in history after the revert, and the RELEASE_LOG rollback entry is what records that the version was withdrawn. Reversibility of the rollback itself is unchanged (IRREVERSIBLE for the consumer-visible deployed-then-reverted state); no tag mutation is involved, so no tag-deletion reversibility grade applies.

### Reversibility tier (this rollback path)

**`IRREVERSIBLE · confidence HIGH`** per [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md) § Rollback Pattern — the revert action itself is reversible (re-merge restores), but consumer-visible "deployed-then-reverted" state is committed in git history.

### Cowork-domain rollback (non-git)

Per [`RELEASE_PROTOCOL.md`](../../governance/RELEASE_PROTOCOL.md) § Rollback protocol — restore from `Releases/_snapshots/[version]/` if within the 15-release active window; reconstruct from the Dry-Run Record otherwise. Cowork has no git as a recovery surface; the snapshot mechanism IS the rollback target.

## 8. Verification commands (consolidated reference table)

| Check | Command | Expected (full-success) |
|---|---|---|
| Check 1 — Per-skill copy integrity | `diff -q <git-source-SKILL.md> <Cowork-install-SKILL.md>` (per skill) | empty output (zero diff) |
| Check 1 — Per-skill copy integrity (user-local mirror) | `diff -q <git-source-SKILL.md> ~/<OPERATOR_INSTANCE_SKILLS_PATH>/<name>/SKILL.md` | empty output |
| Check 2 — `core/deploy/deploy.sh --check` regression | `core/deploy/deploy.sh --check 2>&1 \| tee /tmp/v<X.Y>-postdeploy-check.txt` | zero new FAILs attributable to release |
| Check 3 — `.skill` package freshness | `python3 -c "import zipfile; z = zipfile.ZipFile('packages/<name>.skill'); print(z.read('SKILL.md').decode() == open('release/skills/<name>/SKILL.md').read())"` | `True` |
| Check 3 — `.skill` package freshness (aggregator) | `core/deploy/deploy.sh --check` Check 7 (package-freshness) | PASS |
| Check 4 — Mirror-pair byte-identical | `core/deploy/deploy.sh --check` Check 9 (rules-mirror sync) | PASS |
| Check 5 — Platform-consistency aggregator | (composition of Checks 1-4) | PASS |
| Attribution helper (Check 2) | `git log --follow --oneline <file>` | release branch's merge SHA appears as most recent touch |
| Rollback target lookup (§ 7 step 2) | `gh pr view <release-PR> --json mergeCommit --jq '.mergeCommit.oid'` | release merge SHA |

## 9. Failure modes

Per [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md), every K1 standard documents ≥3 domain-specific "do NOT do X when Y, because Z" scenarios distinct from platform-wide guardrails. Each entry uses the 5-field schema (Signature / Conditional / Root cause / Mitigation / Principal-vs-junior response) and carries one of 5 category tags (TRIG / INPUT / PROC / OUT / HAND).

| # | Tag | Signature | Conditional | Root cause | Mitigation | Principal-vs-junior response |
|---|---|---|---|---|---|---|
| FM1 | **PROC** | Treating pre-merge failure as partial-deploy class | When Phase A.5 / A.6 / B0 surface a pre-merge problem, do NOT invoke this standard's protocol — those phases have their own escalation paths and nothing was deployed | Spec scope confusion: partial-deploy specifically covers post-merge / partial-copy failure | Stage 12 Self-repair line cross-reference explicitly scopes to "Phase C post-deploy verification surfaces partial-failure"; phases A.5/A.6/B0 are unambiguously pre-merge | Principal: routes to the correct pre-merge phase + escalates per [`release-process.md`](../../governance/release-process.md) Inter-Stage Feedback Protocol. Junior: invokes this protocol → escalates a wrong-class diagnosis to operator |
| FM2 | **HAND** | Auto-initiating rollback without operator authorization | When Check 5 = full-failure, do NOT auto-execute `git revert` — rollback is operator-only per [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md) § Rollback Pattern Authorization requirement | Convenience pressure: "the failure is obviously catastrophic, why wait for authorization?" | This standard § 7 includes the verbatim authorization requirement from `autonomous-execution-model.md` ("Agents do NOT initiate rollback autonomously"); assessment Check 5 outcome SURFACES recommendation but does NOT execute rollback | Principal: surfaces the assessment + recommends rollback with rollback-mechanism preview; awaits explicit operator authorization. Junior: "obvious catastrophe → execute" → bypasses governance gate, audit trail incomplete |
| FM3 | **OUT** | Updating Deployment Log Result field via direct-to-main commit | When transitioning `Result: PARTIAL` → `PARTIAL → SUCCESS` (post fix-forward) OR `PARTIAL → ROLLED BACK` (post rollback), do NOT commit directly to main — use the existing Stage 13 chore-PR pattern per the chore-PR convention | Per [`git-workflow.md`](../../../core/rules/git-workflow.md) § "What NOT To Do" — direct-to-main commit prohibited regardless of update size | This standard § 6 step 4 explicitly requires the chore-PR mechanism for Deployment Log Result transitions; cross-references Stage 13 chore-PR pattern | Principal: opens a `chore/v<X.Y>-stage-13-partial-recovery-update` branch, edits RELEASE_LOG.md, opens chore PR per the existing chore-PR convention. Junior: pushes directly to main "because it's a documentation-only update" → triggers Stage 12/13 chore-PR convention violation |

## 10. Integration with autonomous-execution-model.md

This standard is a **parameterization**, not a replacement, of the parent patterns in [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md). The cross-reference is explicit at every layer:

| This standard | Parent pattern | Composition |
|---|---|---|
| § 3 Decision tree — full-success | (no recovery required) | Proceed to Stage 13 |
| § 3 Decision tree — partial-failure | **Escalate Pattern** | Compose with § 5 assessment + § 6 fix-forward OR § 7 rollback |
| § 3 Decision tree — full-failure | **Rollback Pattern** | Compose with § 7 rollback |
| § 6 Fix-forward step 2 retries | **Retry Pattern** (production-impacting cap=2) | Inherit cap=2 from `autonomous-execution-model.md` § Retry Pattern Production-impacting cap exception |
| § 7 Rollback (8 steps) | **Rollback Pattern** (operator-only) | Inherit OPERATOR-ONLY authorization requirement from `autonomous-execution-model.md` § Rollback Pattern Authorization requirement |
| § 9 FM2 Auto-initiating rollback | Authorization requirement | Verbatim quoted: "Agents do NOT initiate rollback autonomously" |

Skip-permissions and pattern composition rules (Retry → Escalate → Rollback chain; Skip-Escalate-to-Rollback prohibited) inherit unchanged from the parent patterns. This standard adds only the S-2 partial-deploy parameterization.

### Cross-reference from decision-outcome-tracking.md

decision-outcome-tracking.md (sibling) declares a PARTIAL outcome value for the Deployment Log Outcome field. The **interpretation** of PARTIAL — what counts as partial, what to do when it fires — is governed by THIS standard. decision-outcome-tracking.md is the schema authority for the field; this standard is the protocol authority for the value's recovery semantics.

## 11. Cutover

**Applies to:** all Stage 12 deployments going forward. If any partial-failure surfaces, recovery follows the decision tree in § 3 (standard fix-forward via the Phase J.5 rebuild-then-commit pattern, or rollback per § 7).

## 12. Cross-references

| Surface | Reference | Role |
|---|---|---|
| Parent patterns (Retry / Escalate / Rollback) | [`autonomous-execution-model.md`](../../../core/disciplines/autonomous-execution-model.md) | This standard parameterizes; inherits all composition rules + authorization requirements |
| Upstream trigger (Stage 12 Self-repair line) | [`release/governance/release-process.md`](../../governance/release-process.md) § Stage 12 | Stage 12 Self-repair line cross-references this standard when Phase C surfaces partial-failure |
| Rollback procedure authority | [`RELEASE_PROTOCOL.md`](../../governance/RELEASE_PROTOCOL.md) § Rollback protocol | Canonical rollback procedure including snapshot-restore semantics for Cowork's non-git surface |
| Rollback skill entrypoint | [`release-executor` SKILL.md](../../skills/release-executor/SKILL.md) Mode C | Existing rollback entrypoint; this standard does NOT modify Mode C semantics |
| Fix-forward precedent | [`pipeline/stage-12-execute.md`](../pipeline/stage-12-execute.md) § Phase J.5 rebuild-then-commit pattern | Rebuilt-package commit pattern; structurally a fix-forward primitive for cascade-modified-package class |
| Failure-mode schema | [`failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md) | 5-field schema + 5 category tags (TRIG / INPUT / PROC / OUT / HAND) |
| Chore PR convention | [`release-process.md`](../../governance/release-process.md) Stage 13 § Chore PR convention | Deployment Log Result field updates land via chore PR, never direct-to-main |
| K1 placement | [`knowledge-architecture.md § 3`](../../../core/disciplines/knowledge-architecture.md) | K1 standards live at `core/standards/` |
| Cross-issue (PARTIAL semantics) | `decision-outcome-tracking.md` (sibling release) | decision-outcome-tracking.md defines the Outcome field; this standard defines PARTIAL's recovery semantics |
| Source Stage 5 spec | Stage 5 Solutioning canonical spec | Stage 5 Solutioning canonical spec |

## Version History

Tracked in git history.
