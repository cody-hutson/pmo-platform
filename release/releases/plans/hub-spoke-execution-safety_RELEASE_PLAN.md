---
title: Release Plan — hub-spoke-execution-safety (spawned spokes carry the execution-safety guarantees single-session use provides)
type: release-plan
plan_type: release
status: ACTIVE
release: slug-only (ADR-092 — the concrete version binds at the Stage-12 atomic claim)
milestone: hub-spoke-execution-safety
release_class: novel
reversibility: MODERATE / Confidence HIGH
---
# Release Plan — `hub-spoke-execution-safety`

**Milestone:** `hub-spoke-execution-safety` (milestone 301). Seven members, one branch, one pull request, one merge.
**Version identity:** **slug-only** per **ADR-092**. This file is `hub-spoke-execution-safety_RELEASE_PLAN.md` and the branch is `release/hub-spoke-execution-safety`; no version stem appears in the filename, the branch name, or this plan's identity prose. Bump class is `minor`. The concrete number binds at the **Stage-12 atomic compare-and-swap**, which renames this file into its major-version bucket and resolves the `{{RELEASE_VERSION}}` token carried below.
**Topology:** **SINGLE** — one release branch, one pull request, one merge gate; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial.** Stage-6 work routes one card at a time in the approved sequence on the single branch. Force-push, including the lease-guarded form, is prohibited on the shared branch under any multi-chip activity.
**Release class:** **`novel`** (operator verdict at the Stage-4 gate, correcting the Stage-3 declaration). Posture: engagement density **Standard** · Stage-9 review depth **Deep** · Stage-5 activation bias **ALL** · Stage-13 outcome window **30-day**. Class weight **1.15**.

> **Provenance.** This file transcribes the Stage-4 Release Planning output, reconciled forward through the Stage-5 Solutioning designs (two runs for four cards, plus an independent adversarial pass), the Collective Review scope-lock, the serialization hold and its discharge, and the Commit-0 version re-verify recorded below. Where a later measurement superseded a Stage-4 figure, **this file carries the decided state** and the Deviation Log records the delta. The Stage-4 output comment is the historical record and is not edited. Authored at Engineering Commit 0 by the first Stage-6 Engineering spoke.

---

## Header

| Field | Value |
|-------|-------|
| **Version** | `{{RELEASE_VERSION}}` — slug-only pre-claim (ADR-092); bump class `minor` |
| **Date Created** | 2026-08-05 (Wednesday) — Stage-4 planning |
| **Commit 0 authored** | 2026-08-07 (Friday) |
| **Release Manager** | Agent-assisted (`release-hub` Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Baseline** | Stage-4 planning measured at an earlier mainline head; **Stage 6 builds on the post-serialization-discharge mainline** — see the Deviation Log |
| **Topology** | SINGLE — one branch, one pull request, one merge |
| **Rollback** | Revert the release merge commit; two carve-outs recorded under Rollback |

### Commit-0 version re-verify

The Stage-4 version determination is **provisional** until the Stage-12 atomic claim. This rung is not ceremony here: it **fired on its first ever exercise** in this release. The originally-planned slot was taken by a sibling release four minutes after that release landed, and the collision was visible on **one surface only**.

**That is the finding this release carries forward: freeness must be read from the tag surface, not the ledger.** A tag is written atomically at the instant of the claim; the release-ledger row and the published-release row land later, through separate follow-up pull requests. At the moment the first re-verify ran, the ledger reported the taken slot as **free** and the tag reported it as **claimed**. A check consulting the ledger alone returns a false PROCEED and authors a plan file against a slot already bound to another merge.

Re-run at this Commit 0 against the re-rendered version, with a controlled probe on every arm:

| Arm | Probe | Result |
|---|---|---|
| **Target** | planned version present on the origin tag surface? | **0 occurrences** — not claimed |
| **Sensitivity control** (known PRESENT) | the immediately preceding version on the same surface | **1 occurrence** — the probe detects a real claim |
| **Specificity control** (known ABSENT) | a version never allocated in this repository's history | **0 occurrences** — a zero is reachable, not a regex artifact |
| **Independent recomputation** | the version adapter's own next-free computation for a `minor` bump, dry-run against the current mainline head | recomputed next-free **equals** the planned version, exit 0, no tag pushed |
| **Ledger cross-read** | release-ledger row for the previously-contested slot, read from the mainline rather than any worktree copy | **present** — the sibling's follow-up pull request has since landed, so the ledger and tag surfaces now **agree** |

**Verdict: PROCEED.** The planned version is absent from the claimed set on the authoritative surface and equals the independently recomputed next-free. The branch and this plan file stay slug-primary and do not rename on any later re-derivation. Freeness re-verifies once more at the Stage-12 pre-merge check; **that check reads the tag surface, and the ledger is not sufficient evidence of freeness at any rung.**

---

## Change Description

*Operator-facing. Authored at Stage 6 Phase C1 as required before the pull request is marked ready for review; refreshed by the final Engineering slice.*

**Outcome.** When the release hub spawns a stage spoke, that spoke loses safety properties a single session takes for granted. Two spokes can write to the same scratch path, so one can pick up another's leftover file and post it to the wrong place. A single spoke launch is never checked against the remaining usage window, so it can start work it cannot finish and die mid-run having posted nothing. And the script allowlist the platform cites as a control over what a spoke may execute is, on the path where release close-out actually runs, a convention rather than an enforced guard. This release closes the first two outright, and for the third it wires a named enforcement point, states its coverage boundary honestly, and specifies the proof it cannot yet run.

**The through-line.** Every card here is an instance of one shape: **a control that is claimed but not exercised.** An allowlist nobody enforces. A remediation nobody could run. A category enum a template contradicts. A worked example that shows the wrong shape for the contract it illustrates. A test that reports PASS while its strongest assertion silently does not execute. A retention policy enforced by the host and written down nowhere. The remedy in each case is the same — make the control either produce a real verdict or say plainly what it does not cover.

**Key decisions.** The enforcement point ships **wired but unproven**, and the release says so rather than grading an inert control as satisfied. The proof obligation is specified precisely enough to execute and is explicitly deferred to the window after its operator-executed preconditions land; it is not waived. The release-tag retention question resolved into **codify what the host already enforces** — the policy was never missing, only undocumented, and the live defect turned out to be a recovery runbook prescribing a deletion the repository actively rejects. The blast-radius test card was **re-scoped** away from the defect it was filed for, which a prior change had already fixed, onto the worse defect that change introduced: a fallback that emits a pass instead of a skip, so the strong assertion stops running while the suite reports green.

**Reversibility.** **MODERATE** at the release level, **CHEAP** for most individual cards. Whole-release rollback is a revert of the merge commit. Two carve-outs are recorded under Rollback and are the reason the release-level tier is not CHEAP.

**Downstream impact.** Operators gain one new targeted command that refreshes composition surfaces without running a full update. Contributors will notice that the deploy script now states plainly that composition surfaces are outside its scope instead of reporting nothing-to-do. Three operator-executed preconditions are required before the Edit-class control becomes live; none of them is performed by this release, and all three are named.

**What this release does NOT claim.** It does not claim the enforcement point fires from a spawned session — that proof is deferred, by name, with its instrument specified. It does not claim the orphan version tag is removed; it is not, the host blocks its deletion, and no removal is authorized here.

---

## Scope

### Summary

Seven members. Four form the hub-and-spoke execution and record-surface cluster; one is the upstream dependency that cluster turned out to have; two are release-tooling defects on the same pipeline that share only a project label.

### Members

| Card | Size | What it is |
|---|---|---|
| Spoke execution hardening | L (8) | Spoke output-path namespacing; a remaining-envelope check on singleton launches, not only waves; Edit-class hook coverage for spawned sessions |
| Subagent Bash hook bypass | M (4) | The destructive-command guard does not govern the path where close-out actually runs; states the real coverage boundary and re-sizes the residuals sized against the assumed one |
| Composition-surface refresh gap | M (4) | The deploy script cannot refresh a composition surface, so the standing remediation for a stale allowlist was never executable. **Stage-5 late add** |
| Release-tag retention | S (2) | Codify the retention rule the host already enforces; reconcile the recovery runbook, which prescribes a blocked operation |
| Blast-radius test determinism | S (2) | The recovery-failure path emits a pass instead of a skip, so the strong before-and-after assertion silently stops running while the suite reports green |
| Action-item enum parity | S (2) | The runtime template disagrees with the standard on three of six category values, two further enums diverge, and a declared deferral has no category at all |
| Decision-item worked examples | S (2) | The bridge document's worked examples show the pre-change decision-item shape, missing the reversibility field the contract requires |

Raw member points **24**. Class weight **1.15**. Effective points **28** against a band upper bound of **25** — a **3-point breach on a recorded override**, taken because the added card is a precondition of work already committed rather than discretionary scope. The remedy if the breach binds is the recorded bundle split, never a re-size.

### Scope lock

The design set was **locked at Collective Review** before Engineering. Stage 5 ran two rounds for four cards plus an independent adversarial pass returning seven blockers and more than twenty majors. Four record corrections landed with the lock and are carried in the Deviation Log. Two open counting disputes were **routed to Stage 6 with the requirement that whoever settles them publishes the scope and both probe arms in-band** — the release accumulated five measurement errors and will not settle a count with a sixth crude probe.

---

## Dependency Graph

Directed, hard edges only.

```
composition-surface refresh gap ──(hard, upstream)──▶ subagent Bash hook bypass
                                                          │
                                                          ▼ (hard, co-design)
                                              spoke execution hardening, premise (c)

spoke hardening (a) · spoke hardening (b) · tag retention · test determinism ·
enum parity · worked examples                                     [independent]
```

**Two hard edges.** The co-design edge is stronger than sequencing and weaker than a merge: both cards' third acceptance criterion is satisfied by **the same artifact** — one named enforcement point for the spawned-session path. A fix for the Bash class that does not generalize to the Edit and Write classes leaves half the class open. One design decision, two consumers.

The upstream edge was **absent from the Stage-4 dependency graph and is real**: the enforcement fix depends on the allowlist-refresh path, and that path is structurally inoperative. Shipping enforcement without it enables a control whose refresh path does not work.

**File-contention edges** (Contention Map only, not the graph): worked examples against spoke hardening premise (b) on the bridge document; the refresh gap against the enforcement cluster on the allowlist file.

---

## Implementation Sequence

Write-serialized, posture P0. **No dates** — sequence and scope only.

```
Commit 0   this plan file (first Engineering spoke; runs the Commit-0 version re-verify first)
   1. composition-surface refresh gap   the targeted refresh mode + a scope-honest deploy message
   2. subagent Bash hook bypass         coverage boundary, residual re-size, enforcement point (Bash class)
   3. spoke hardening (c)               the same enforcement point applied to the Edit and Write classes
   4. spoke hardening (a)               spoke output-path namespacing
   5. spoke hardening (b)               singleton envelope check + four-surface scope reconcile
   6. decision-item worked examples     three shape sites in the bridge document
   7. action-item enum parity           three enums, three surfaces, plus a parity check
   8. release-tag retention             retention doctrine, runbook reconcile, four ledger rows, one decision record
   9. blast-radius test determinism     golden fixture re-derived against the current tool, skip-not-pass semantics
```

**Fixed constraints:** 1 before 2 (upstream edge); 2 before 3 (co-design edge); 5 before 6 (same file, disjoint ranges). Steps 4 and 7 through 9 are order-flexible.

**Three Stage-6 sequencing obligations carried from the scope lock:**

1. The enforcement-point block **changed at the second Stage-5 round** — scope narrowed to the pre-tool-use object only, authority moved from the deployed file to the template, the guard moved to a dedicated library with an inverted fail direction as a named fourth precedence layer, and the coverage boundary widened from two conditions to four. The earlier byte-identity fingerprint recorded for that block is **stale**. Step 3 must re-quote from the second round, and step 2 must land the re-quote before either card's block is written.
2. The operator-executed hook-loading probe **gates this stage** for the enforcement-point cards. It is the instrument that answers whether pre-tool-use hooks load at all in a worktree-rooted session — the standing candidate mechanism. Three of its six arms are executable before merge and are **not** deferred, because pre-fix baselines are unrecoverable once the wiring lands.
3. The golden fixture digest recorded at Stage 5 is **invalidated** and **must not be adopted**. The tool it was derived from changed on the mainline after the digest was verified: it now emits a populated second-order block where the earlier tool scoped it out, while deliberately not bumping its schema version. Step 9 re-derives the golden against the current tool and publishes its own three-root by ten-iteration verification. A mismatch is a finding to report, never a constant to update.

---

## Stage Applicability Matrix

Stage 5 is all-or-nothing per release and **activated** for the whole release; all six activation triggers fired.

| Card | 5 Sol | 6 Eng | 7 DT | 8 QA | 9 PR | 10 Dry | 11 Snap | 12 Exec | 13 Close | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| Spoke execution hardening | Y | Y | Y | Y | Y | Y | Y | Y | Y | Three premises; (c) gated on the co-design verdict |
| Subagent Bash hook bypass | Y | Y | Y | Y | Y | Y | Y | Y | Y | Enforcement-point owner |
| Composition-surface refresh gap | Y | Y | Y | Y | Y | Y | Y | Y | Y | Upstream of the enforcement cluster |
| Release-tag retention | Y | Y | Y | Y | Y | Y | Y | Y | Y | Dev test and QA verify doctrine text and ledger rows, **never a tag deletion** |
| Blast-radius test determinism | Y | Y | Y | Y | Y | Y | Y | Y | Y | Dev test is load-bearing: the strong arm must be observed to run |
| Action-item enum parity | Y | Y | Y | Y | Y | Y | Y | Y | Y | Parity check ships warn-mode-initial |
| Decision-item worked examples | Y | Y | Y | Y | Y | Y | Y | Y | Y | Its second criterion is a grep with a live control — dev-test gradable |

**Zero skips, and that is the honest answer rather than a default.**

---

## Contention Map

### Within-release — two clusters, both resolved by sequencing on one branch

| Contended surface | Cards | Class | Mitigation |
|---|---|---|---|
| The hub-and-spoke bridge document | worked examples, spoke hardening (b) | line-range overlap, **disjoint in fact** | Sequence spoke hardening (b) before worked examples. Disjoint ranges, so no merge conflict on one branch. Low severity |
| The hook-coverage-boundary cluster — the security-posture standard, the hook registry index and its two shards, the script-promotion framework, the workspace context template, the skill-deployment rule, the canonical-skill-structure standard, the autonomy-tier spec, the allowlist file itself, the solutioning output template, and the blast-radius protocol | subagent Bash hook bypass, spoke hardening (c) | **co-design, not conflict** | **Do not split by file.** One author lands the boundary statement across the whole cluster at step 2; step 3 adds only the Edit and Write class deltas. Splitting by file guarantees two divergent boundary statements. **High severity if mishandled** |

**No contention:** tag retention, test determinism, and enum parity each own their files uniquely.

**The hook registry index is a generated file.** Editing it directly instead of its shards is silently reverted by the next deploy. Edit the shards, then regenerate.

### Cross-release

The planning-time parallelization scan measured clean and **did not carry** — a concurrent release opened hours after it ran and collided on three files plus a decision-record number. That release has since merged and the hold is discharged; the three surfaces were re-derived against the merged mainline and two Stage-5 designs were materially affected. Details under Deviation Log.

**The re-check is not optional and does not carry either.** The open-pull-request population changes mid-run, so the concurrent-release check re-runs at every wave rather than once at planning.

---

## Risk Register

| ID | Risk | Sev | Owner-stage | Reversibility / Confidence | Mitigation |
|---|---|---|---|---|---|
| R-1 | The enforcement point ships wired but unproven; its negative control cannot execute in-pipeline for either arm, because both preconditions are operator-executed and land after dev test and QA run | **HIGH** | 6→12 | MODERATE / HIGH | The success indicator was amended to what the release can demonstrate. The control is specified precisely enough to execute and explicitly deferred; the obligation is tracked, not waived |
| R-2 | The hook-coverage cluster split across two authors produces two divergent boundary statements — the exact failure the co-design edge exists to prevent | **HIGH** | 6 | CHEAP / HIGH | Step 2 lands the whole cluster under one author; step 3 adds only the Edit and Write deltas. Byte-identity is graded as a cross-issue criterion |
| R-3 | Duplicate ownership with an open card in another milestone that retains acceptance-criterion text on the same class. Two milestones can ship divergent enforcement points | **HIGH** | 5→6 | MODERATE / HIGH | Coordination point named at the Stage-5 Collective Review, before any Engineering spoke launches. Live and accepted, not resolved |
| R-4 | The golden fixture digest recorded at Stage 5 is stale — a correct constant whose subject moved | **HIGH** | 6 | CHEAP / HIGH | Re-derive against the current tool; **do not adopt the recorded digest**. Publish a fresh three-root by ten-iteration verification |
| R-5 | The Edit-class control is inert on delivery: its hook is workflow-class and a workflow-class hook exits without acting while the master switch is off | **MED** | 6→12 | MODERATE / HIGH | Ship the wiring and state the activation precondition plainly. The flip is not performed here — it activates six workflow-class hooks at once, well beyond this milestone's blast radius |
| R-6 | Cards under-declare blast radius; a grader working from card criteria alone passes a partial fix | **MED** | 4→8 | CHEAP / HIGH | Five cardinality amendments applied before the change matrix froze; the control-claim surface is graded as a set, not a sample |
| R-7 | The hook registry index is generated; a hand-edit is silently reverted at the next deploy | **MED** | 6 | CHEAP / HIGH | Edit the two shards and regenerate via the registry builder |
| R-8 | Skill-reference edits trip the very hook whose spawned-session coverage this release is investigating. A spoke may be blocked, or may proceed **because the hook does not fire** — which is itself evidence | **MED** | 6 | CHEAP / HIGH | Route those edits through the skill-editor discipline and **instrument the result**; whichever way it goes is a live datum. Capture it in the Stage-6 record |
| R-9 | Usage-window exhaustion. The worst parallel batch is six spokes; the release's own evidence includes a singleton spoke dying at window exhaustion after a preceding wave was correctly gated to proceed | **MED** | 7/8 | CHEAP / MEDIUM | Split dev test and QA into two sub-waves of three; capture operator quota state before the first wave. The runtime checkpoint is the binding gate |
| R-10 | The targeted refresh mode creates a permanent per-phase synchronization obligation: every future phase added to the update sequence needs a verdict against the mode | **MED** | 6+ | CHEAP / HIGH | Implement as a **named flow**, not as negative guards inside the shared sequence. An unlisted phase then cannot join the mode — the failure class becomes structurally impossible rather than caught by review. **The obligation already defaulted wrong once at spec time**, which is why the structural form is required |
| R-11 | A stale citation sits **inside this release's own edit surface** — the security-posture standard cites a tracking item as open which closed months ago | **LOW** | 6 | CHEAP / HIGH | Reconcile in the same edit that states the coverage boundary. Reconcile, never annotate beside the stale claim |
| R-12 | Rollback complexity is LOW for the repository content, but two carve-outs prevent a clean CHEAP release-level tier | **LOW** | 12 | see Rollback | Recorded under Rollback |

---

## Cross-Issue Acceptance Criteria

Graded on the merged pull request at the Stage-9 release-integration check.

- [ ] **CIAC-1 — one enforcement-point statement, byte-identical.** The enforcement-point block — the named mechanism, the tool classes it covers, and the negative-control design — is byte-identical wherever it appears across both hook cards' shipped edits. A mechanism named for the Bash class but not the Edit and Write classes, or the reverse, is NOT MET. Method: extract the block from each site and diff pairwise; zero differences required. **The authoritative text is the second Stage-5 round's, not the first's.**
- [ ] **CIAC-2 — the control-claim surface is a set, not a sample.** Every live site that cites the script-execution allowlist or the skill-edit hook **as a control** carries the coverage-boundary statement. Method: grep the corpus for those two names excluding immutable audit records, then assert each remaining file contains the boundary sentinel; the set difference must be empty. **A sensitivity arm is required — the grep must return non-zero before the difference is computed.**
- [ ] **CIAC-3 — the restate-versus-cite question is answered once.** The release answers it consistently across all three divergence surfaces: the action-item category enum, the singleton-gate scope statement, and the decision-item shape. Three different answers — one cites, one restates, one is silent — is NOT MET.
- [ ] **INT-1 — the refresh path and the enforcement point name the same surface.** The enforcement design must read the **deployed, token-resolved** allowlist that the refresh path writes, never the repository source. MET only if both name the deployed surface.
- [ ] **INT-2 — one mechanism statement.** Both outputs state the **hook-loading** mechanism. Zero occurrences of the falsified inheritance-bypass framing in either card's added text.
- [ ] **INT-3 — the ledger mechanism line is corrected exactly once**, by the refresh-gap card, with the hook-bypass card citing rather than duplicating it.
- [ ] **INT-4 — withdrawn-claim containment.** Zero occurrences of the withdrawn cross-tool asymmetry claim in the pull-request diff, the release ledger, or the Stage-9 record.
- [ ] **INT-5 — the precondition set is rendered with all three members**, with the allowlist precondition bound to the settings-wiring member **only** and the other two members' independence stated. A single unlabelled step is NOT MET.

---

## File Change Matrix

Machine-readable path list — one path per line, for deterministic extraction by downstream stage prompts. Derived from the Stage-4 change matrix reconciled forward through each card's Stage-5 declarations.

```
core/CLAUDE.md.template
core/config/allowlists/script-execution-allowlist.txt
core/deploy/allowlists/hub-state-enum-parity-map.txt
core/deploy/composition-surface-manifest.sh
core/deploy/deploy.sh
core/deploy/tests/test_refresh_surfaces.sh
core/deploy/tools/check-enum-parity.sh
core/hooks/block-destructive.sh
core/hooks/block-skill-direct-edit.sh
core/hooks/lib/scope-guard.sh
core/hooks/tests/subagent-hook-inheritance-probe.md
core/rules/bypass-mode-readiness.md
core/rules/bypass-mode-readiness/_cross-cutting.md
core/rules/bypass-mode-readiness/block-destructive.md
core/rules/git-workflow.md
core/rules/skill-deployment.md
core/settings.json.template
core/specs/autonomy-tiers.md
core/standards/agent-script-promotion-framework.md
core/standards/canonical-skill-structure.md
core/standards/composition-surface-spec.md
core/standards/duplicate-source-discipline.md
core/standards/hub-action-tracking.md
core/standards/subagent-security-posture.md
docs/UPDATE.md
docs/scripts/setup-workspace.sh
docs/scripts/validate-install.sh
update.sh
release/references/how-to/hub-spoke-bridge.md
release/references/how-to/re-version-recovery.md
release/references/protocols/blast-radius-protocol.md
release/references/specs/release-personas.md
release/references/standards/quota-budget-protocol.md
release/references/standards/solutioning-output-template.md
release/releases/RELEASE_LOG.md
release/releases/RELEASE_REVERSIONS.md
release/releases/hub-state/action-items.md.template
release/releases/plans/hub-spoke-execution-safety_RELEASE_PLAN.md
release/skills/release-hub/references/decision-briefing.md
release/skills/release-hub/references/orchestration-playbook.md
release/skills/release-hub/references/spoke-launch.md
release/tools/cleanup-orphan-state.sh
release/tools/tests/fixtures/blast-radius-prerefactor.sh
release/tools/tests/test_domain_blast_radius.sh
.github/workflows/release-tooling-smoke.yml
```

**45 paths.** Three additions are deliberately absent from the machine-readable list and are named here so the omission is visible rather than silent:

1. **One architecture decision record**, an ADD under the release decision-record directory, carrying the tag-retention decision. Its filename is **not yet allocatable** — the number is globally monotonic across both decision-record directories plus in-flight pull requests, and a number claimed before the file is written risks a second collision. It takes its number **at authoring**, not now.
2. **Test fixtures** accompanying the enum-parity check, whose filenames are a Stage-6 naming decision.
3. **Nothing else.** Any path a Stage-6 card needs beyond this list is a matrix widening and is recorded in the Deviation Log at the time it is taken.

**Per-card intent:**

| Card | Path | Operation | Notes |
|---|---|---|---|
| Refresh gap | `update.sh` (**repository root** — there is no such file under the docs scripts directory) | **edit** | Add a targeted surfaces-only flow as a **named flow function** dispatched from the top-level sequence, mirroring the shipped hook-refresh flow. Plus one argument-parse case and one usage stanza. **The shared sequence is left untouched — every default run stays byte-identical.** The regeneration routine itself is not modified. Excluded members stated in a prose header |
| Refresh gap | deploy script | **edit** | The no-changes message becomes scope-honest; the usage stanza gains one out-of-scope line. **Exit code stays 0.** No manifest sourcing, no fourth change-set array, no write path |
| Refresh gap | new refresh-surfaces suite | **add** | Seven arms: hermetic pre-flight, negative control, branch-independent byte-identity, branch-targeted message check that **skips with a reason and never emits a pass on the fallback**, the corrected path, the criterion assertion, and a no-collateral arm. Model: the shipped hook-refresh suite. Hermetic pattern: the shipped deploy sandbox suite |
| Refresh gap | update documentation | **edit** | A flags-table row for the new mode, plus a blast-radius paragraph stated as a **stable shape with a measurement instruction**, never frozen counts |
| Refresh gap | release ledger | **edit** | **Surgical.** Two lines. On the first, only the clause naming the deploy command as the discharge is wrong; the surrounding sentence is correct and must be preserved. On the second, the falsified mechanism is replaced with the hook-loading one |
| Refresh gap | composition-surface spec | **edit** | The update subsection gains one sentence naming the targeted primitive alongside the full-update path |
| Hook bypass | security-posture standard | **edit** | State the four-condition coverage boundary; **reconcile the stale open-item citation in the same edit** |
| Hook bypass | script-promotion framework | **edit** | The corpus's strongest false control claim |
| Hook bypass | hook registry shards, then regenerate the index | **edit** | Never hand-edit the generated index |
| Hook bypass | autonomy-tier spec, workspace context template, solutioning output template, blast-radius protocol, allowlist header | **edit** | The remaining control-claim citation surfaces; graded as a set |
| Hook bypass | scope-guard library, settings template, setup and validation scripts, composition-surface manifest | **add / edit** | The enforcement point and its wiring. **Registering the settings file as a composition surface is not optional** — without it the fix installs wiring that nothing can ever refresh, reproducing this release's own upstream defect on a new surface |
| Hook bypass | hook-inheritance probe document | **edit** | Fill the worktree column with the probe result and extend its arm list. **Extend the standing artifact; do not create a parallel one** |
| Spoke hardening | spoke-launch reference, quota-budget standard, bridge document | **edit** | Namespacing directive; singleton envelope check reconciled across **four** surfaces, not the two the card named |
| Spoke hardening | skill-deployment rule, canonical-skill-structure standard, skill-edit hook | **edit** | Edit-class coverage boundary and wiring |
| Worked examples | bridge document, decision-briefing reference | **edit** | **Three** shape sites, not the two the card named. The briefing's description of those examples as canonical is narrowed in the same change — that word is the root cause of the divergence |
| Enum parity | action-item standard, runtime template, orchestration playbook | **edit** | **All three** restated enums re-derived from the standard; a seventh category added for a declared deferral |
| Enum parity | deploy script, new parity check, parity map | **add / edit** | A new check registered in the duplicate-source discipline, **warn-mode-initial** |
| Tag retention | git-workflow rule, recovery runbook, reversions ledger, orphan-state tool, one decision record | **add / edit** | Codify what the host enforces; reconcile the runbook, which prescribes a blocked operation; correct **four** ledger rows to cite the host rule rather than an unsourced policy. **No tag is deleted** |
| Test determinism | blast-radius suite, golden fixture, smoke workflow | **add / edit** | Golden fixture **re-derived against the current tool**; skip-with-reason replaces the false pass; the deep-clone retention answer written **against** the new doctrine the concurrent release landed, not around it |
| Release | this plan file | **add** | Engineering Commit 0, slug-primary |

---

## Verification Plan

| Card | Verification method | Expected result |
|---|---|---|
| Spoke hardening (a) | file-content assertion plus a negative control | The namespacing directive is present. **The control must fail if the contract clause were deleted** — a control that instead tests the temp-directory utility's own uniqueness guarantee passes with the clause removed and does not count |
| Spoke hardening (b) | file-content assertion across **four** surfaces | All four scope statements agree; a grep for the wave-only phrasing returns zero against a live sensitivity control |
| Spoke hardening (c) and hook bypass | reproduction-and-observe from a spawned session, with a negative control | **Declared now; executor does not yet exist.** Grading contract is witness file AND log row AND tool result against a pre-fix baseline — **a hook log row alone is not evidence**, the row is forgeable from a piped stdin because the schema carries no session identifier. Three probe arms are executable before merge and are not deferred |
| Refresh gap | the seven-arm suite plus a file-content assertion | After the corrected path runs, the sandbox allowlist contains the named script in all four resolved forms. **The suite must skip with a reason, never pass, on the branch-targeted arm's fallback** |
| Tag retention | file-content assertion plus an explicit predicate | The retention rule is present at its codified home; runbook and rule are non-contradictory; four ledger rows reconciled; **the orphan tag still resolves — a disappeared tag is a verification FAILURE, not a success** |
| Test determinism | reproduction-and-observe, ten runs under concurrent load | Ten of ten green **with the strong arm observed to have run in every round.** A green suite that skipped it does not satisfy this — that is the defect itself |
| Enum parity | explicit predicate plus system state | Template enums equal the standard's enums by set equality across all three; a declared deferral maps to a category; the parity check exits non-error |
| Worked examples | file-content assertion with a live control | All **three** sites carry the reversibility and confidence field, against a live sensitivity control |

---

## Quota Budget

**Verdict: WARN.** Worst parallel batch is six spokes at dev test and QA. The remaining envelope was unstated at hub start, so the conservative default applies — assume partial, not fresh. That assumption is the largest single source of uncertainty and is the first thing the runtime checkpoint should replace.

**Routing:** split dev test and QA into two sub-waves of three, putting the two heaviest spokes in different sub-waves; capture operator quota state before the first wave.

**This is a usage-window budget, not a rate-limit problem, and the plan-time estimate is advisory.** The load-bearing gate is the runtime checkpoint, re-validated at **every** parallel wave against the *remaining* envelope. This release's own evidence is a singleton spoke dying at window exhaustion **after** a preceding wave had been correctly gated to proceed — the exact mid-release drift a one-time plan-time estimate structurally cannot catch.

---

## Delivery Strategy

Single release branch `release/hub-spoke-execution-safety`, one pull request, one merge — **milestone equals one pull request equals one merge**. This plan lands as Engineering Commit 0 after the Commit-0 version re-verify. Stage-6 spokes commit sequentially on the shared branch under posture P0.

The pull request opens in **draft** at Commit 0 plus the first card, so later Engineering slices land against a live pull request; it is marked ready only after the remaining cards land and the Stage-9 gate renders GO.

All seven members are **marked as closed at Stage 13** through the pull request's Issue References block. Close-family keywords appear **only** in that block, never in the summary or implementation sections.

---

## Rollback

**Reversibility: MODERATE / Confidence HIGH.** Revert the release merge commit. No schema migration, no data mutation, no destructive host operation, no tag deletion.

Two carve-outs, which are why the release-level tier is MODERATE rather than CHEAP:

1. **The hook registry index is generated.** A revert must also revert its two shards, or the next deploy regenerates the reverted content.
2. **Three operator-executed preconditions live outside the repository** — the user-scope pre-tool-use wiring, the master security-hook switch, and the skill-edit hook's enforce mode. The repository can neither see nor gate any of them. Reverting the merge does not unwind them; they are unwound by the operator, in the operator's own configuration.

---

## Deviation Log

Each entry states what changed, the basis, and the reversibility and confidence tier.

**D-1 · Bundle spans more than one capability — operator-accepted.** Two members share only a project label with the hub-and-spoke cluster. The operator elected to keep all members rather than split. The outcome statement is therefore deliberately multi-item and names the two out-of-theme members rather than papering over them. MODERATE / HIGH.

**D-2 · Release class corrected to `novel`.** Every trigger for the stricter class was tested individually and none fires: the change matrix touches zero pipeline stage specifications against a threshold of three; the governance-surface criterion is a closed seven-item list of which the matrix touches exactly one against a threshold of three; and the bundle carries one in-bundle compositional edge against a threshold of three. The prior rationale enumerated nine surfaces without applying the closed list. This is a stricter-to-cheaper reclassification and required explicit operator risk acceptance, which is recorded. CHEAP / HIGH.

**D-3 · Size-bound breach, override recorded.** Effective points moved to 28 against a ceiling of 25 when the upstream dependency was added. The override basis is that the added card is a **precondition of work already committed**, so deferring it does not reduce the release's real surface — it only hides the dependency, which the planning graph already did once. If the breach binds, the remedy is the recorded bundle split, **not** a re-size. MODERATE / HIGH.

**D-4 · Duplicate ownership with another milestone — live and accepted.** A card in another milestone retains acceptance-criterion text on the same enforcement class and was deliberately not edited. Accepted means coordinated, not ignored: the coordination point is the Stage-5 Collective Review, before any Engineering spoke launches, and it renders one of three dispositions on the record. MODERATE / HIGH.

**D-5 · Tag retention inverted from the filed premise.** The supposedly-uncodified no-deletion policy **is** enforced, by an active host ruleset targeting version tags with deletion and non-fast-forward rules. The source observations' search denominator was documentation-only and could not observe host configuration. The live defect is therefore the inverse of the one filed: the recovery runbook prescribes an operation the repository actively rejects. Disposition: codify what is enforced, reconcile the runbook, correct the ledger rationale. **The orphan tag is NOT removed** — removal would require first disabling an active ruleset to perform an irreversible deletion, and is not authorized. CHEAP / HIGH.

**D-6 · Test-determinism card re-scoped to the false-pass.** Two independent staleness findings landed against the card as filed. First, its claim that the affected job sits in the required set is false — the mainline's required contexts are nine, all security and governance gates, and this job is not among them, so a flake reds a check without blocking merge. Second, a change three days before the criteria were authored had already touched the file. A worse defect survives: the recovery-failure path emits a pass rather than a skip, so the strong before-and-after assertion **silently stops running while the suite reports PASS**. That change converted a false red into a silent false green. CHEAP / HIGH.

**D-7 · Enforcement point ships wired, not proven — and the earlier record of this was wrong.** The degraded-ship authorization was conditioned on first testing whether pre-tool-use hooks **load** in a worktree session. The first Stage-5 round was recorded as satisfying that condition; **it did not** — it ran a hook-*firing* test, while the condition names a hook-*loading* test. The condition remains unsatisfied and the trigger unevaluated. The probe designed in the second round is the instrument that would satisfy it, it is operator-executed, and it **gates this stage**. MODERATE / MEDIUM.

**D-8 · The Edit-class control is inert on delivery, and the release says so.** The skill-edit hook is workflow-class and a workflow-class hook exits without acting while the master switch is off; the destructive-command hook is security-class and is never inert on that condition alone. So the wiring makes the Bash arm live and leaves the Edit arm dormant. The repository ships the enforcement point and **states plainly** that Edit-class activation requires the master switch. The flip is not performed here — it activates six workflow-class hooks at once. **Explicitly rejected: re-classing the workflow hook to security.** Widening a security class so one acceptance criterion can pass is the move that manufactures the next uncodified-policy defect. MODERATE / HIGH.

**D-9 · Success indicator amended to what the release can demonstrate.** The negative control cannot execute in-pipeline for **either** arm, because both preconditions are operator-executed and sit after dev test and QA. Four amendments each replace an assertion the release cannot make with one it can: the enforcement-point arm becomes wired-and-bounded with the control specified and deferred; the enum-parity arm covers all three restated enums rather than one; the determinism arm requires the strong arm to be **observed to have run** rather than the suite to be green; and the namespacing arm requires a control that would **fail if the contract clause were deleted**. The coverage boundary is **four-condition**, not two — the bypass environment variable sits at the first layer and exits both hook classes, so the class asymmetry holds at the second layer only. CHEAP / HIGH.

**D-10 · The enforcement-point block changed at the second Stage-5 round.** Scope narrowed to the pre-tool-use object only; authority moved from the deployed file to the template; the guard moved to a dedicated library with an inverted fail direction as a named fourth precedence layer; the boundary widened from two conditions to four; and a "changes nothing about how any hook behaves" clause was deleted. **The byte-identity fingerprint recorded against the first round is stale.** Stage 6 must sequence the re-quote before either card's block is written. CHEAP / HIGH.

**D-11 · The precondition set is three members, not two, and they do not bind uniformly.** It was recorded with two. The Edit control also requires the skill-edit hook at enforce mode. The allowlist precondition binds the **settings-wiring member only**, because the destructive-command hook is security-class and never inert on the master switch alone. CHEAP / HIGH.

**D-12 · Stage 6 was serialized behind a concurrent release, and the hold is now discharged.** The per-wave concurrent-pull-request check fired **before any Engineering spoke was spawned** and found not a stray pull request but a live concurrent release colliding on three files plus a decision-record number. The disposition was to serialize: that release was live and advancing while this one had zero commits, so waiting cost wall-clock only and eliminated the contention entirely. It has since merged; the three surfaces were re-derived against the merged mainline and **the rebase was not mechanical**. The deep-clone setting survives and its wrong comment with it, so the correction is still needed. A **new doctrinal tension** landed: the concurrent release's added job argues against blanket deep clones, while this release's card argued to retain one on the grounds that three other scripts need history. These are not contradictory in direction — the golden fixture removes the history dependency, which is what the new doctrine prescribes — but the retention justification must now be written **against** it rather than around it. And the golden fixture digest is **invalidated**. CHEAP / HIGH.

**D-13 · Version re-rendered after the first re-verify HALTED.** The Commit-0 re-verify fired on its first ever exercise and halted correctly: the planned slot had been claimed by the concurrent release minutes after that release landed, inside the window in which this release's Engineering tasking was authored. Next-free is rule-computed with **zero degrees of freedom**, so the determination was recorded and the release proceeded rather than manufacturing an operator gate with one legal answer. **Nothing needed unwinding** — under slug-primary identity the branch, filename, and Commit 0 are all slug-named and the version binds only at the atomic claim. The finding that outlives this release is recorded under Commit-0 version re-verify above: **the tag is the authoritative freeness surface; the ledger alone returns a false PROCEED.** CHEAP / HIGH.

**D-14 · Two counting disputes routed to Stage 6 unresolved.** A template-versus-deployed count disagreement and a zero-executor census disagreement were both left open at the scope lock, with the requirement that whoever settles them **publishes the definition, the population, and both probe arms in-band**. This release accumulated five measurement errors; shipping a disputed count as settled would be the same defect in a new place. CHEAP / HIGH.

**D-15 · Enum-parity registry filed under the deploy-check allowlists, not the hook allowlists — path list corrected in place.** The change matrix placed the new registry under the **runtime/hook** allowlist directory while placing its own primitive under the deploy-tools directory on the next line. The two directories are not interchangeable: the hook directory holds runtime permission surfaces read by pre-tool-use hooks (egress, filesystem boundary, script execution, shell injection), while the deploy directory holds the registries that deploy-time checks read as their denominator — including the directly analogous duplicate-source registry that the complementary-pair check consumes. A registry filed in the hook directory would sit beside permission surfaces it has nothing in common with and away from every structural sibling. The registry ships in the deploy-check directory and the machine-readable path list is corrected to match, rather than the file being misfiled to preserve a stale line. CHEAP / HIGH.

**D-16 · The historical-alias table ships without a row-count column.** The design specified a "rows affected" census beside each alias. That column is dropped and the alias mapping — the load-bearing content, and the whole of what the acceptance criterion asks for, which is a **read** rule — ships unchanged. Two reasons, both disqualifying on their own. It is a point-in-time census of **git-ignored operator-instance files the repository does not own**, embedded in a durable standard: the counts are stale the next time any ledger is written, which is the hardcoded-value pattern the platform's own authoring guardrail rejects. And this stage **could not verify them** — the live ledger population is outside this repository, and the only reachable copy is a backup snapshot days older than the figures. Authoring unverifiable counts into a standard would be invention. The census remains on the Stage-5 evidence record, where it is timestamped and attributable. CHEAP / HIGH.

---

## References

Designated reference block. Each entry pairs the tracker number with a summary noun phrase, so the meaning survives even if the number does not.

| Number | What it is |
|---|---|
| Milestone **301** | `hub-spoke-execution-safety` — this release's milestone; seven members, effective points 28 on a recorded override, composition locked at Stage-4 planning entry. |
| **#3815** | Spoke execution hardening — output-path namespacing, a singleton envelope check, and Edit-class hook coverage for spawned sessions. |
| **#4436** | The subagent Bash hook bypass — the destructive-command guard does not govern the path where close-out actually runs. |
| **#4447** | The composition-surface refresh gap — the deploy command cannot refresh a composition surface, so the standing remediation was never executable. |
| **#3814** | Release-tag retention doctrine — codify what the host ruleset already enforces and reconcile the recovery runbook. |
| **#3818** | Blast-radius test determinism — the recovery-failure path emits a pass instead of a skip, so the strong arm stops running silently. |
| **#4181** | Action-item enum parity — the runtime template disagrees with the standard across three separate enums. |
| **#4184** | Decision-item worked examples — the bridge document shows the pre-change shape, missing the reversibility field. |
| **#4777** | The Stage-4 release-planning sub-task carrying this plan's source output and the version determination. |
| **#4893** | The Stage-6 Engineering sub-task for the refresh-gap card, where this Commit 0 is reported. |
| **#1531** | The duplicate-ownership card in another milestone that retains criterion text on the same enforcement class. |
| **#1472** | The worktree-session hook-loading question — closed as not planned, and the standing candidate mechanism behind the observed bypass. |
| **#4325** | The close-out path's zero-allowlist exposure, which the enforcement work lands on top of. |
| **#4915** | The settings file is an unregistered composition surface — no refresh path at all, filed from this release's second Stage-5 round. |
| **#4916** | The close-out action-item gate reports resolved over ledger rows it cannot parse. |
| **#4917** | The never-fail class — three sub-shapes needing three different fixes, shipped with an unresolved marker on its own count. |
| **#4918** | The Edit-control re-scope alternative, declined here deliberately and filed for its own design rather than taken as a shortcut. |
| **#4919** | Verification by declaration — the class card, drawn from six instances measured across this release. |
| **#4920** | Claim-versus-residual reconciliation, from a planning-time out-of-scope discovery. |
| **#4921** | Nothing asserts that the tag-protection ruleset still exists. |
| **ADR-092** | The version-identity decision record: release branches and plan files are slug-primary, and the concrete version binds at the Stage-12 atomic claim. |
| **ADR-014** | The dual-hash composition model separating the source-template hash from the post-substitution tamper anchor. |
| **ADR-030** | The generated-hook-registry decision record: edit the shards, never the generated index. |
| **ADR-042** | The two-layer subagent hook probe, which is the reuse basis for this release's loading probe. |
