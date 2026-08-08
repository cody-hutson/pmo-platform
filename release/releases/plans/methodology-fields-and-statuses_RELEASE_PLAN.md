---
title: Release Plan — methodology-fields-and-statuses (the delivery work-status axis gets a field, a label surface, a maintenance contract, and an epic-rollup audit)
type: release-plan
plan_type: release
status: ACTIVE
release: slug-only (ADR-092 — the concrete version binds at the Stage-12 atomic claim)
milestone: methodology-fields-and-statuses
release_class: cross-cutting
domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-06, domain: governance }
reversibility: MIXED / Confidence HIGH
---
# Release Plan — `methodology-fields-and-statuses`

**Milestone:** `methodology-fields-and-statuses` (milestone 265). Four build cards, 24 points, one branch, one pull request, one merge.
**Version identity:** **slug-primary** per **ADR-092**. The plan file is `methodology-fields-and-statuses_RELEASE_PLAN.md` and the branch is `release/265-methodology-fields-and-statuses`; no version stem appears in either. Bump class is `minor` — a capability release, not corrective, so the patch floor does not apply. The concrete number binds at the **Stage-12 atomic claim**, which renames this file into the major-version bucket.
**Topology:** **SINGLE** — one release branch, one pull request, one merge gate; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial.** Stage-6 work routes one card at a time in the approved sequence on the single branch. Force-push, including the lease-guarded form, is prohibited on the shared branch under any multi-chip activity.
**Release class:** **`cross-cutting`** (operator verdict at the Stage-4 gate, independently re-derived by the planning spoke). Posture: engagement density **Tight** · Stage-9 review depth **Deep** · Stage-5 activation bias **ALL** · Stage-13 outcome window **30-day**.

> **Provenance.** This file transcribes the Stage-4 Release Planning output, reconciled forward through the four approved Stage-5 Solutioning designs and the Collective Review scope-lock of 2026-08-07 (Friday). Where a later measurement or decision superseded a Stage-4 figure, **this file carries the decided state** and the § Deviation Log records the delta against the Stage-4 plan of record. The Stage-4 output comment is the historical record and is not edited. Authored at Engineering Commit 0 by the first Stage-6 Engineering spoke.

---

## Header

| Field | Value |
|-------|-------|
| **Version** | slug-primary pre-claim (ADR-092); bump class `minor`; rule-computed next-free recorded as a determination, not a claim |
| **Date Created** | 2026-08-07 (Friday) |
| **Release Manager** | Agent-assisted (`release-hub` Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/265-methodology-fields-and-statuses` |
| **Pull Request** | (populated at pull-request creation) |
| **Milestone** | `methodology-fields-and-statuses` (265) |
| **Baseline** | `origin/main` @ `f157a811` — Commit-0 re-pin **confirms** the Stage-4 pin; zero commits of drift |

### Commit-0 version re-verify

The Stage-4 version determination is **provisional** until the Stage-12 atomic claim, and three sibling releases were live-but-unmerged when this release entered Engineering — one of them declaring the **same `minor` bump class** — so this rung is the one most likely to fire rather than ceremony. It was re-run at Commit 0 against freshly fetched authoritative refs, with a known-taken sensitivity arm on every surface. Ledger input was read from `origin/main` with a brace-delimited ref, never from a worktree copy.

| Surface | Subject (next-free minor) | Sensitivity arm | Denominator |
|---|---|---|---|
| Origin git tags, freshly fetched | **0** occurrences | the immediately preceding version: **1** | full tag set |
| Release-ledger version rows, read from `origin/main` | **0** occurrences | the immediately preceding version: **1** row | 162 version rows |
| Versioned plan files across `origin/main` and all three in-flight release refs | **0** occurrences | a known-present preceding-version plan file on `origin/main`: **1**; per-ref plan-file denominator **155** on each of the three siblings | 4 refs |
| Recomputed next-free for bump class `minor` | recomputed next-free **equals** the planned version | — | — |

**Verdict: PROCEED.** The planned version is absent from the claimed set on all four arms and equals the recomputed next-free. No colliding tag, ledger row, or plan file exists. The branch and this plan file stay slug-primary and do not rename on any later re-derivation.

### Commit-0 ADR-number allocation

Allocation is **by rule**, not by a number carried forward from a design comment. What the rule *is*, however, was measured at Commit 0 rather than assumed — and the measurement **overturned the allocation this release entered Engineering with.**

The global sweep ran first. Across **121 local and remote refs**, both ADR directories: mainline anchor **119**; the next slot **triple-claimed** across the three in-flight release refs; the slot after it **claimed** by one of them. Sensitivity arm — the same shape recovers the known mainline anchor and 129 ADR files in total across all refs. Specificity arm — a series well above every claim returns zero on that same non-empty population, so the absences are real.

The plan carried into Engineering was to reserve a slot **strictly above every in-flight claim**, leaving two slots free for the siblings that must renumber. **That is the one allocation the ratified rule forbids by name.** ADR-115 states that a number is allocated at authorship and **bound at merge**, that next-free is the mainline anchor plus one, that it is *never* the maximum of the claimed set, and that an unmerged sibling claim is **advisory**. Its § Context names the reservation strategy explicitly as *worse* than a duplicate: the contiguity gate fails a gap exactly as readily as a duplicate, so a branch that steps above an unmerged claim and merges first lands a hole on the mainline that fails **every** subsequent pull request until someone fills it. A duplicate inconveniences one branch; a gap blocks the repository.

This was verified against the enforcing gate rather than argued from the document, with four arms:

| Arm | Candidate | Gate verdict |
|---|---|---|
| Baseline (no new record) | — | **PASS** — the probe is not stuck red |
| Subject | the reserved slot above every in-flight claim | **FAIL — GAP**, naming all four missing numbers |
| Comparator | mainline anchor plus one | **PASS** |
| Specificity | a deliberate duplicate | **FAIL — DUPLICATE**, so the gate is not gap-only and the comparator's PASS is meaningful |

**Allocated for the first card: mainline anchor plus one.** The record carries a numbering note in its own § Status recording the advisory sibling claims and the rejected reservation. If a sibling merges first, the record renumbers at merge by the sanctioned tool — the designed workflow, tested in CI — and gains a numbering-provenance note. The two further ADRs this release ships bind at their own cards' build steps under the same rule, re-verified at that moment; they are deliberately **not** pre-assigned here, because a pre-assigned number is exactly the stale artifact the rule exists to avoid.

**This was surfaced for operator re-ratification and has since been CLOSED (2026-08-07):** the hub confirmed against ADR-115 that next-free is the mainline anchor plus one — a **rule, not a judgment** — so no ratification was required and the reservation was withdrawn. The record stands as authored; the remedy, were the number ever to move at merge, remains one invocation of the renumber tool.

---

## Scope

Four build cards under one epic, all slices of the same model: the platform ships a generic Axis-1 delivery state machine at the entity layer, and almost nothing writes to it, reads it, or projects it onto a surface an operator can see.

**Card 1 — the Axis-1 field and its label surface.** The generic work-status enum has shipped at the entity layer with no field definition, no documented two-axis boundary, and no label projection. This card defines the field, documents the boundary against the release-pipeline status axis, adds a seventh label **group** to the grammar, and contributes the six concrete rows from the shared base pack.

**Card 2 — the status-maintenance contract.** Three absences were claimed; the design probed all three and **two of them exist already**. Only the configured-versus-unconfigured adapter duality is genuinely absent. This card ships that one rule and cites the five existing surfaces rather than authoring a seventh restatement of an obligation the corpus already carries.

**Card 3 — the pipeline label materialization gap.** Two declared pipeline-status rows have never existed as live labels. Four candidate root causes were falsified: detection already works, and the parity gate is what surfaced the defect in the first place. The real cause is that **no materialization path exists anywhere in the corpus** — nothing creates a label from a declaration. The fix surface moves from enforcement to materialization.

**Card 4 — the epic rollup-close audit.** No mechanism closes an epic whose children are all done, and epics are structurally invisible to every lifecycle mechanism because the taxonomy exempts them from the status invariant. A gate cannot assert over a governance-exempted field, so the surface must be a report-only audit.

**The through-line.** Every card in this release is an instance of one failure shape: **specification without binding.** A state machine with no writer, a label declaration with no materializer, an obligation named on six surfaces and wired into none, a container tier exempted from the very mechanism that would close it. The remedy differs per card, but the diagnosis is shared, and it is recorded here so a later reader sees the release as one argument rather than four errands.

---

## Dependency Graph

Three directional edges over four nodes, acyclic by structural peel (the first card has in-degree zero; removing it frees two more; the fourth is last).

| Edge | Class | Basis |
|---|---|---|
| Card 1 → Card 2 | **HARD (blocks)** | Bidirectionally attested in both card bodies: the maintenance contract maintains the field the first card defines, so the field lands first. |
| Card 1 → Card 3 | **SOFT (pattern establishment)** | The label-materialization card reuses the pack contribution-and-parity mechanism the first card establishes; both bodies call for build-sequencing on one branch rather than parallel work. |
| Card 2 → Card 4 | **SOFT (compositional containment)** | The rollup-close trigger is an epic-altitude read of the cross-altitude status contract; the contract card's own scope-boundary table states the containment. |

**Not an edge:** cards 3 and 4 share a file but assert no compositional claim about each other. That pair is **file contention**, a distinct class — the Stage-4 planning spoke corrected the milestone's original edge set on exactly this point, and the class verdict survived the correction because a third genuine compositional edge (card 2 → card 4) replaced the misclassified one.

---

## Implementation Sequence

Serial, one card at a time, on one branch. This order satisfies all three dependency edges **and** makes each contended file's touches adjacent, so the second author on any shared file edits a file whose first edit is one commit old.

| Position | Card | Points | Why here | Contended file touched |
|---|---|---|---|---|
| **1** | Axis-1 field + label surface | 4 | In-degree zero. Establishes the grammar group and pins the value domain to the shipped enum — the prerequisite for both downstream consumers. Carries Commit-0 duties. | the pack meta-schema (1st touch); the label grammar (1st touch) |
| **2** | Status-maintenance contract | 4 | Satisfies the HARD edge immediately, while the pack meta-schema is still the working context. | the pack meta-schema (2nd touch — **adjacent**) |
| **3** | Pipeline label materialization | 8 | Satisfies the SOFT pattern edge. Opens the release-process governance file. | the label grammar (2nd touch); release-process governance (1st touch) |
| **4** | Epic rollup-close audit | 8 | Satisfies the SOFT containment edge. Closes release-process governance while it is still the working context. | release-process governance (2nd touch — **adjacent**) |

The alternative order front-loads the largest card for earlier risk surfacing. It was weighed and not taken: everything lands on one branch as sequential commits, so a blocker found one position later costs one commit of rework rather than a re-plan, and the root-cause investigation that motivated the front-loading already ran at Stage 5, ahead of every position.

---

## Stage Applicability Matrix

**Stage 5: ACTIVATED for the whole release** — five of six activation triggers fire, on their own merits, so activation is over-determined and does not rest on the class bias. The one trigger recorded as **non-firing** is the cross-cutting-governance-file-count trigger: the matrix touches two governance-set members, below the three-member threshold. It is recorded so the activation is never later mis-read as resting on it.

| Card | S5 | S6 | S7 | S8 | S9 | S12 | S13 |
|---|---|---|---|---|---|---|---|
| Axis-1 field + label surface | APPLY | APPLY | APPLY | APPLY | APPLY (release-scoped, **Deep**) | APPLY | APPLY |
| Status-maintenance contract | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY |
| Pipeline label materialization | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY |
| Epic rollup-close audit | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY |

**No stage is skipped for any card.** Stages 10 and 11 are release-scoped and closed as platform-satisfied by git-native compression — the Stage-9 pull-request diff **is** the dry run, and the pre-merge commit on the mainline **is** the snapshot. They were created and then closed rather than omitted: applicability closes a sub-task, it never removes one.

---

## Contention Map

**Within-release.** Three shared paths, all resolved by build-order serialization on the single branch.

| Shared path | Cards | Overlap class | Resolution |
|---|---|---|---|
| `core/schemas/work-item-type-schema.md` | 1, 2 | disjoint regions | Card 1 edits the label-group enum in the contribution-facet section and its restatement in the cross-references table; card 2 inserts a new peer subsection in the type-pack grammar. Adjacent positions 1 → 2. **New at Stage 5** — the Stage-4 map assigned this path to card 2 alone. |
| `core/specs/label-taxonomy.md` | 1, 3 | disjoint regions | Card 1 edits the group section, the rules list (a new rule appended), the methodology-variation paragraph, and the instance-model *contribution* bullet. Card 3 edits the instance-model *reconciliation* bullet. Adjacent bullets, non-overlapping. **New at Stage 5** for card 1. |
| `release/governance/release-process.md` | 3, 4 | append-pattern | Different sections — card 3 appends to the Stage-6 section, card 4 appends one paragraph to the Stage-13 section. Adjacent positions 3 → 4. |

**Dropped from the Stage-4 map:** `release/references/specs/ticket-information-architecture.md` was the release's largest contended surface (both cards targeting the same region). Card 2's Stage-5 design **dropped the path entirely** — card 1's acceptance criteria *are* that edit — which removes 100% of that contention rather than serializing it.

**Cross-pull-request, re-measured at Commit 0.** Three in-flight sibling release branches. The Stage-4 audit found exactly one collision (the deploy script) and recorded that excluding it removes all cross-release contention. **That claim is corrected here on two counts**, both measured with sensitivity and specificity arms per sibling:

| Sibling branch | Edit-set size | Intersection with this release's matrix |
|---|---|---|
| `release/96-update-install-config-safety` | 32 | ADR directory only (the number-allocation contention, resolved by the Commit-0 rule) |
| `release/hub-spoke-execution-safety` | 38 | `script-execution-allowlist.txt`, `selftest-coverage-manifest.txt` |
| `release/release-check-enforcement-gates` | 14 | **`core/specs/label-taxonomy.md`**, `script-execution-allowlist.txt`, ADR directory |

The label-grammar edge is **new and was absent from the Stage-4 map**. The sibling rewrites the sub-task-mirror rule in place; this release appends a new rule two lines below it and leaves the sub-task-mirror rule untouched. The regions are disjoint but within a three-line diff context, so the exposure is **merge-order friction at hunk level, not semantic conflict**. All sibling edits in the intersection are additive.

**Cross-milestone, latent.** One card in a different milestone touches the label grammar. Re-checked at Commit 0: still open, still milestoned elsewhere, **no branch and no open pull request** — so the edge is latent, not live. Its scope is a lint over initiative-versus-epic labelling, disjoint from every region this release edits.

---

## Risk Register

| ID | Risk | Severity | Mitigation | Reversibility · Confidence |
|---|---|---|---|---|
| **R1** | **Two-axis label-name collision.** The delivery enum and the pipeline status set share the tokens for active work and for completion, and the label namespace is flat. | **HIGH** | **Resolved at Stage 5, mechanically.** The status-label invariant check discriminates by **name prefix**, not by grammar group — the group field is read nowhere in the deploy script. So both halves are required and both ship: a distinct grammar group **and** a distinct name prefix outside the check's match. A prefix alone is necessary but not sufficient; a correct group alone does nothing at runtime. Graded by CIAC-2. | CHEAP · HIGH |
| **R2** | **Sub-task-mirror rule tension.** One card's criterion required a resync the grammar declares deliberately absent. | **HIGH** | Resolved: the rule is **not amended**; a new decision record captures the non-resync design and the criterion is graded satisfied-by-intent. Scaffolding is not edited against a standing rule. | MODERATE · MEDIUM |
| **R3** | **Materialization root cause.** Why the parity gate never surfaced two missing rows. | **MED** | **Resolved at Stage 5, and it was none of the four candidates.** Detection works; enforcement mode is not the cause either, because no code path anywhere creates a label. The gap is materialization. | CHEAP · HIGH |
| **R4** | **Version-slot contention.** One sibling declares the same bump class; two declare none, so their slots are unresolvable rather than absent. | **MED** | Version is atomic-claimed at Stage 12. The Commit-0 re-verify above is detection rung 1 and ran **PROCEED**. | CHEAP · HIGH |
| **R5** | **Declared-but-not-live rows.** Card 1's six new rows land declared; the parity gate's missing count would rise rather than fall. | **MED** | **Resolved:** the materialization card's apply-set was extended at Collective Review to cover card 1's six rows **and** the one declared-but-absent kind label. The emit path is group-agnostic by construction, so the marginal design cost is zero. | CHEAP · HIGH |
| **R6** | **Cardinality is documentation-only.** The new rule's one-per-item constraint has no enforcing invariant, because the deploy script is excluded from the matrix. | **LOW** | Named and accepted, not hidden. Routed as a follow-on for a sibling invariant to the existing status-label check. | CHEAP · HIGH |
| **R7** | **Non-git rollback surface.** Materialization creates live labels, which are repository state rather than repository content. A revert does not remove them. | **MED** | The rollback section names the out-of-band step explicitly. Do not report a rollback complete on the revert alone. | CHEAP but **manual** · HIGH |
| **R8** | **Pack-coverage generalization.** The contract is validated against two built packs; the archetype set declares eight. | **MED** | Kind resolution goes through the resolved pack's declared kinds, never a hardcoded list — a criterion on two cards. Card 1's rows are archetype-invariant by construction, so they hold for all eight with zero further rows. | CHEAP · MEDIUM |
| **R9** | **New-executable companion obligation.** Card 4 ships a new script, so the allowlist row and the self-test coverage manifest are **mandatory same-release companions**, and both sit in sibling edit-sets. | **MED** | Both are in the matrix below. The coverage manifest is **generated, never hand-edited** — its reconcile mode hard-fails on divergence in either direction, so a merge conflict there is resolved by re-running the generator. | CHEAP · HIGH |
| **R10** | **Epic-audit false positives.** All-children-closed is necessary but not sufficient; the practical rubric is three-gate. | **MED** | The three-gate rubric was **promoted from a risks note to graded criteria** at Stage 5. Two of the three gates are **not mechanically decidable from label topology** — both candidate predicates over-matched — so the design **annotates rather than adjudicates** on them, and the surface is report-only. | CHEAP (reopen) · HIGH |

---

## Cross-Issue Acceptance Criteria

Four criteria, each spanning two or more cards, each asserting a cohesion constraint on the **integrated** release, all graded at Stage 9 on the merged pull request. Distinct namespace from the per-pair integration criteria authored at Stage 5.

- **CIAC-1 (cards 1 × 2, on the shared corpus surface).** The field definition and the status read surface reference **one** Axis-1 value set — no parallel vocabulary, no duplicated enum. *Method:* extract every enum value list from both edits and assert set-equality against the entity-layer schema; assert the enum literal appears exactly once per file.

- **CIAC-2 (cards 1 × 3, on the flat label namespace).** The Axis-1 rows and the Axis-2 pipeline rows occupy **disjoint label names**. *Method:* extract every label name from each pack contribution; assert the intersection is empty **and** assert each set is independently non-empty — an empty extraction would satisfy disjointness trivially and falsely. **This is the release's highest-value criterion: it is the direct grader for R1.**

- **CIAC-3 (cards 3 × 4, on the release-process governance file).** Both cards' named pipeline steps are present in the merged file and neither edit removed, renumbered, or absorbed the other's section. *Method:* assert both step names resolve; diff the heading list against the baseline and assert the delta is **additive only**.

- **CIAC-4 (cards 2 × 4, on the epic-altitude definition).** The rollup-close trigger predicate is expressed in the contract's altitude terms rather than as a parallel definition of epic completion. *Method:* locate the trigger; assert it cites the contract rather than defining its own completion predicate.

---

## File Change Matrix

Machine-readable path list — one path per line, for deterministic extraction by downstream stage prompts.

```
core/specs/label-taxonomy.md
core/schemas/work-item-type-schema.md
core/packs/_common/pack.toml
release/references/specs/ticket-information-architecture.md
core/schemas/field-lifecycle-matrix.md
core/ADRs/ADR-124-axis1-work-status-label-surface.md
core/deploy/tools/check-label-parity.py
release/governance/release-process.md
release/references/how-to/hub-spoke-bridge.md
release/tools/audit-epic-rollup-close.sh
core/config/allowlists/script-execution-allowlist.txt
core/deploy/allowlists/selftest-coverage-manifest.txt
release/tools/automated-closeout.sh
release/releases/plans/methodology-fields-and-statuses_RELEASE_PLAN.md
```

**Two further paths under `core/ADRs/` bind at their own cards' build steps** — one for the status-maintenance contract, one for the label-materialization decision. Their numbers are allocated **by rule at that moment**, not pre-assigned here, per § Commit-0 ADR-number allocation. Downstream extraction should treat the block above as the deterministic set and the two ADR additions as expected, named, and non-surprising.

**Per-card intent:**

| Card | Path | Operation | Notes |
|---|---|---|---|
| Axis-1 field | label grammar | **edit** | New group section defining the seventh group; one new composition rule; four count-and-enumeration cascade updates. The status-group rule and the sub-task-mirror rule are **not touched**. |
| Axis-1 field | pack meta-schema | **edit** | Two enum-row updates admitting the new group. The no-pack-level-machine rule, the Axis-1 state count, and the version-bump sections are **not touched** — appending an enum member is not a breaking shape change. |
| Axis-1 field | shared base pack | **edit** | Six additive label rows plus a header-note reconcile and one enum-comment update. **Both archetype packs stay byte-unchanged** — see the Deviation Log. |
| Axis-1 field | ticket information architecture | **edit** | New peer section carrying the field row, the valid-transition diagram, and the two-axis comparison table. The categorization section is **not touched** — its static-after-assignment framing must not acquire a dynamic label. |
| Axis-1 field | field-lifecycle matrix | **edit** | One additive row plus a footnote stating the all-dashes reading is **by design, not omission**. |
| Axis-1 field | ADR-124 | **add** | The seventh-group decision, the prefix as a hard runtime constraint, the base-pack homing, and the blocked-is-derived ruling. Number is the mainline anchor plus one per the binding rule — see § Commit-0 ADR-number allocation. |
| Status contract | pack meta-schema | **edit** | One new peer subsection: status resolution when no platform adapter is configured. The adjacent worked-example subsection, the adapter-binding line, and the existing kind-fallback caveat are **not altered**. |
| Status contract | a new ADR | **add** | Binding-not-restatement: the contract is K1, the adapter binding stays K4. |
| Materialization | parity checker | **edit** | Additive read-only emit flag as its own boolean flag — **not** a new output-format value, which the deploy script pins. Sibling parser so the existing signature is untouched. |
| Materialization | label grammar | **edit** | Instance-model reconciliation bullet only. |
| Materialization | release-process governance | **edit** | Stage-6 section, additive. The transition must be a paired add-and-remove call so the mutex invariant is never transiently violated. |
| Materialization | hub-and-spoke bridge | **edit** | Scaffolding procedure, additive. |
| Materialization | a new ADR | **add** | The sub-task status mirror is a point-in-time mirror and is deliberately not resynced. |
| Epic audit | new audit script | **add** | Report-only. Fetch separated from classify so the self-test runs offline. Findings **never** produce a non-zero exit. |
| Epic audit | script-execution allowlist | **edit** | **Mandatory companion.** The canonical four-form block; no directory glob. |
| Epic audit | self-test coverage manifest | **edit** | **Mandatory companion, generated.** Regenerate with the emit-manifest mode; **do not hand-edit** — reconcile hard-fails on divergence in either direction. |
| Epic audit | automated close-out | **edit** | One signal-only phase plus its header row and dispatch line. Returns zero on findings. |
| Epic audit | release-process governance | **edit** | Stage-13 section, one appended paragraph modelled on the adjacent orphan-cleanup paragraph. Append only. |
| Release | this plan file | **add** | Engineering Commit 0, slug-primary; binds to the version-keyed path only at the Stage-12 atomic claim. |

**Files deliberately NOT in the matrix, with the reason stated so each omission is visible:** the **deploy script** (excluded by ratified Stage-4 constraint; it collided with all three in-flight siblings, and no card's Stage-5 design needs it — the epic-audit card additionally rejected hosting **on the merits**, because a blocking gate over a non-decidable predicate is a false-positive engine); **both archetype packs** (card 1's rows are archetype-invariant, so there is no sub-state delta to declare — see the Deviation Log); the **release-hub orchestration playbook** (it cites rather than copies the bridge, which also removes the skill-package rebuild obligation); the **entity lifecycle protocol** (frozen transcription contract); the **parity checker's diff logic** (already correct — there is no defect in the detection layer); and **every skill file** (the propagation refit that would bind the contract to its consumers is routed as a follow-on, not absorbed here).

**Skill-package rebuild: NOT triggered.** No rostered skill file is edited by any card, so no package rebuild and no content-baseline sidecar is required.

**Meta-schema version bump: NOT triggered.** Appending a member to a label-group enum is neither a new required field nor a criteria-structure change, which is what the bump rule names as its trigger.

---

## Verification Plan

| Card | Verification method | Expected result |
|---|---|---|
| Axis-1 field | field-content assertion over the ticket-architecture spec | The field definition resolves. **Baseline is 0 occurrences at the pinned commit**, so a non-zero post-state is the differential. The workspace-root context file is **dropped** from the method — it is not in this repository. |
| Axis-1 field | section-presence assertion | The two-axis section is present **after this change**. The grading target is presence, not extension of a pre-existing model — the cited two-axis model did not exist in that file. |
| Axis-1 field | set-equality diff | The documented value list equals the entity-layer enum exactly: no added blocked state, no collapsed first two states, terminal cancellation retained. |
| Axis-1 field | pack-contribution assertion | Six rows present in the **shared base pack** with the new group, **and both archetype packs byte-unchanged**. Graded against ADR-124, not against the original criterion text. |
| Axis-1 field | applied to both packs' declared kinds | Holds unchanged; no hardcoded kind list anywhere in the delta. Both packs are literally untouched, so this holds by construction. |
| Status contract | one traversal plus two projections | The read path resolves without baking a methodology-specific kind into the neutral toolkit. |
| Status contract | section presence plus caveat cross-check | Both configured and unconfigured paths defined; the unconfigured path emits an **explicit caveat**, never a silent default. |
| Materialization | live-label assertion | Both previously-missing rows live, with name, colour, and description matching their declarations. |
| Materialization | gate-detects-the-gap behavioural check | With a declared row removed in a test context, the parity gate **reports** the gap. |
| Materialization | population probe **with a control arm** | Positive arm at least one item in the active state; **control arm zero** on a known-not-in-engineering item. A zero with a zero control is a broken probe, not a pass. |
| Epic audit | run against the live tracker | Surfaces at least one all-children-closed epic. **Denominator pinned** at the baseline commit. |
| Epic audit | dual-mechanism read | An epic with an open label-linked-only child is **correctly excluded**. Reading one mechanism alone would mark epics closed while linked work is still open. |
| Epic audit | three-gate rubric | The report surfaces all three gates, annotating the two that are not mechanically decidable rather than adjudicating them. |

**Release-level verification.** The four cross-issue criteria are graded on the merged pull request at Stage 9. Every Stage-4 reproduction is re-run post-merge and asserted **inverted** — each defect in this release was defined by a measured zero at the baseline, so those four zeros becoming non-zero is the tightest available release-level check.

---

## Quota Budget

**Checkpoint A verdict: WARN** — advisory. Four parallel-eligible spokes at each of Stages 5, 7 and 8; half the cards are in the larger size bucket. Ordinal bands are retained rather than replaced by observed medians, because the cutover conditions are unmet — no eligible comparable set exists for this release. Recommended routing is a two-plus-two split with the heavier pair first.

The load-bearing gate is **Checkpoint B**, re-validated at every parallel wave at runtime, because each wave faces a different remaining envelope. Staggering is a rate-limit defence, not a usage-window mitigation; the envelope problem routes to serialize, defer, or reduce scope.

---

## Delivery Strategy

Single branch, one pull request, one merge, write-serialized. Commits reference their source cards. The plan file is Engineering Commit 0.

**Atomicity constraint (gate-able).** For card 1, the **grammar edit and the pack rows must land in the same commit**. An intermediate state in which a pack declares a group the grammar does not yet define is a pack-validation error by the meta-schema's own text **and** a mid-branch violation of the integration criterion asserting that every pack group value is grammar-defined. Card 1's remaining changes may be separate commits.

**Colour is load-bearing, not decoration.** Every new label row **must** carry a colour: the materialization card's emit path skips a row with no colour and prints it as unresolved. A colourless row is unmaterializable through the exact path the integration criterion promises.

---

## Acceptance-Criteria Reconciliation (ratified at the Stage-7 wave-1 gate, 2026-08-07)

**#1825 AC-4 — method text reconciled to the ratified Report shape.** AC-4's method previously required **G2 and G3** as evidence columns, while the Stage-5 "Report shape" — the ratified artifact — specifies no G3 column; G3 surfaces only under `--json`. Dev Test correctly graded the criterion **PARTIAL** against the method text where Stage 6 recorded **MET** against the Report shape.

**Resolution:** the *method text* is what drifted, not the tool. AC-4's method is reconciled to read: *assert G2 appears as an evidence column in the default report, and that G3 is retrievable under `--json`.* Both gates remain **annotate-only** — neither is adjudicated, because G2 is not mechanically decidable from label topology (`label-taxonomy.md:50–57` places `project:*` on container and children alike). Stage 8 grades AC-4 against this reconciled method, not against Stage 6's inherited MET.

## Re-baseline (Stage 7, 2026-08-07)

**The pinned baseline `f157a811` is superseded.** `release/release-check-enforcement-gates` (PR #4932) merged to `main` as **`52d8a55e`** while this release was in flight, advancing the mainline by 11 commits. Every figure in this plan measured against `f157a811` remains a correct historical measurement **at that anchor** and is retained as such; it is not current state.

**Actions taken at the Stage-7 wave-2 gate:**
- `git merge origin/main` into the release branch (repo convention per `core/rules/git-workflow.md` — **not** a rebase, which would rewrite 15 commits that several worktrees hold and force a push).
- **ADR-120 → ADR-124.** The merge brought the sibling's own `ADR-120` to mainline, making this release's claim a genuine duplicate. `renumber-adr.py --detect` independently returned `ANCHOR 120 · NEXT-FREE 121 · ADR-120 DUPLICATE next=124`, with 121/122/123 reported `BINDS` — they sit inside the merged union's slot set and the mainline does not claim them, so ADR-115's exclusion clause leaves them in place. A single-record move, 9 citations swept across 3 files, provenance note written. The sibling's ADR-120 was not touched.
- **ADR-123** gained its three missing durability sections (`Alternatives Considered`, `Reversibility`, `Related ADRs`).
- **The Axis-1 transition graph is no longer restated here.** `ticket-information-architecture.md` now cites `entity-lifecycle-protocol.md` §3.10 as the owner. An earlier draft diverged from it at one edge, asserting `cancelled` reachable from *any* non-terminal state where §3.10 enumerates three sources — the exact second-source failure the document's own two-axis boundary forbids.

**Governance the merge brings into force for this release:** `05c965a3 — feat(#3826): make a failing required PR check a Stage-9 NO-GO input`. This release's own Stage 9 runs under that rule. Re-baselining before Stage 8 is what makes that true; holding would have run our GO/NO-GO under superseded rules.

**Stage 9 must re-measure every population figure.** The open-issue denominator was observed moving 44 in ~17 hours during Stage 7; no count in this plan may be carried forward to a gate.

## Rollback

**Whole release:** revert the merge commit, first-parent form. Every corpus surface returns in one operation.

**Per card:** available in **reverse** sequence order without breaking a dependency. Reverting card 1 alone is **not** safe — it is the in-degree-zero foundation for the other three.

**The part a revert does not cover.** Materialization creates live labels. Labels are repository *state*, not repository *content*: a revert cannot remove them, and any item that acquired one keeps it. Label deletion is a repository-settings mutation and is therefore a **user-side action**, run by the operator against the repository, and it must be named explicitly in the Stage-12 rollback record. **Order matters:** revert the merge first, then delete the labels — reverting first restores the parity checker to its pre-release state so the gate does not immediately re-flag the deletion as drift. If the extended apply-set lands, the manual deletion obligation covers the Axis-1 rows and the kind label as well, not only the two pipeline rows.

**Rollback is operator-authorized. No autonomous rollback.**

**The eight created label rows (rollback names them explicitly — a runbook that says "delete the eight rows" without naming them is not executable):**

```bash
# STEP 1 — revert the merge FIRST (first-parent form), so the parity checker
# returns to its pre-release state and does not re-flag the deletion as drift.
# STEP 2 — then remove the eight rows this release created:
gh label delete "status: done"            --yes --repo <owner>/<repo>
gh label delete "type:card"               --yes --repo <owner>/<repo>
gh label delete "work-status: backlog"    --yes --repo <owner>/<repo>
gh label delete "work-status: ready"      --yes --repo <owner>/<repo>
gh label delete "work-status: in-progress" --yes --repo <owner>/<repo>
gh label delete "work-status: in-review"  --yes --repo <owner>/<repo>
gh label delete "work-status: done"       --yes --repo <owner>/<repo>
gh label delete "work-status: cancelled"  --yes --repo <owner>/<repo>
```

**`status: in-progress` is NOT in that list and must NOT be deleted — it is forward-only.** It existed before this release carrying a default colour and a null description; this release *reconciled* it rather than creating it. Deleting it removes a row the pipeline is now using, and restoring its prior value would restore a malformed row.

---

## Deviation Log

Deltas against the Stage-4 plan of record. The Stage-4 output comment is historical and is not edited; **this file carries the decided state.**

| ID | Stage-4 plan of record | Corrected state in this file | Source |
|---|---|---|---|
| **Δ-row-home** | Card 1's rows contributed by **both archetype packs**, with the shared base pack asserted **unchanged**; the card stated the base pack "cannot host them" | **Rows home in the shared base pack; both archetype packs stay untouched.** The premise was falsified by ratified governance: two decision records name the base pack as the home for the Axis-1 work-status base, and the release plan that **created** the file scoped it to exactly that. Every *prohibition* in the corpus is scoped to the state **machine**; every *homing* statement names the base pack. The card's two criteria were **mutually unsatisfiable** — one pins the values archetype-invariant, the other pins the home archetype-variant; honouring both writes six identical rows into two packs today and forty-eight across the eight declared archetypes. The criterion is **amended**. | Stage 5 design, operator-ratified at the wave-2 gate |
| **Δ-label-group** | The label grammar was **absent** from card 1's affected files, so the card could not emit its own rows | **The grammar file enters the matrix**, and a **seventh group** is added. Reusing the status group was rejected on a harder ground than inelegance: each group definition carries its own cardinality rule, and the status group's rule **is** the mutex — filing Axis-1 rows there would make the two axes mutually exclusive, the exact inverse of the card's purpose. | Stage 5 design, operator-ratified |
| **Δ-prefix-is-mechanical** | The collision was framed as a naming preference | **The naming decision is load-bearing independently of the group decision.** The status-label invariant discriminates by **name prefix**; the grammar group is read nowhere in the deploy script. Both halves are required: a distinct group for the documentation contract, a distinct prefix for runtime disjointness. | Stage 5 measurement, hub-verified |
| **Δ-blocked-resolved** | Blocked-ness was an open assumption: flag versus state | **Neither — it ships no artifact.** Blocked is a *derived condition* of an unsatisfied dependency edge, which the platform already carries. In-corpus precedent: a legacy escalated state was crosswalked to the active state plus an orthogonal condition, explicitly "not a state". Nothing is dropped, because nothing was missing. A control-facet home is pre-registered should a surfaced marker later be wanted. | Stage 5 design, operator-ratified |
| **Δ-contract-scope** | Card 2 would author a new corpus contract document covering three absences | **Two of the three already exist**; only the unconfigured-adapter duality is absent. A new document would have been the **seventh** restatement. The card ships **one subsection** in the existing meta-schema and cites the rest. The real gap is **binding, not authorship**, and the propagation refit routes as a follow-on. | Stage 5 probes, operator-ratified |
| **Δ-symptom-honesty** | Implicitly, the contract card would change what an operator sees | **The operator-visible symptom does not change this release.** That is an accepted, deliberate outcome, and it **must be stated plainly at Stage 9** so a green Stage 8 is not read as the symptom being fixed. | Operator ruling at the wave-2 gate |
| **Δ-tia-dropped** | The ticket-architecture spec was contended between cards 1 and 2 with the release's only line-range overlap | **Dropped from card 2's matrix entirely** — card 1's criteria *are* that edit. This removes the release's largest contended surface rather than serializing it. | Stage 5 design |
| **Δ-materialization-root-cause** | Root cause undetermined among four candidates (not run / not enforcing / not covering the group / scaffolding gap) | **All four falsified.** Detection works — the gate reported both rows, and the card was filed from that output. Enforcement mode is not the cause either: with no label-creation call anywhere in the corpus, even a hard-enforcing check could only convert a silent warning into a permanent red. **The declared-to-live materialization step has no owner and no implementation.** | Stage 5 probes, hub-verified |
| **Δ-apply-set-extended** | Card 3 would materialize its own two rows | **Extended** to cover card 1's six Axis-1 rows **and** the one declared-but-absent kind label. The emit path is group-agnostic by construction, so the marginal design cost is zero — and without the extension this release would *widen* the declared-to-live gap it exists to close. | Operator ruling at the wave-2 gate |
| **Δ-mirror-rule-not-amended** | Card 3's criterion required a resync the grammar declares deliberately absent | **The rule is not amended.** A new decision record captures the non-resync design; the criterion is graded satisfied-by-intent. | Operator ruling at the wave-1 gate |
| **Δ-epic-mechanism** | Card 4's closure mechanism deferred, detective audit versus pipeline step | **Hybrid:** a net-new report-only audit script, a signal-only close-out phase, and one appended governance paragraph. Two mandatory companions ship in the same release: the allowlist row and the generated coverage manifest. | Stage 5 design, operator-ratified |
| **Δ-epic-gates-annotate** | The three-gate rubric sat in a risks note, ungraded | **Promoted to graded criteria** — and two of the three gates are **not mechanically decidable from label topology**. Both candidate predicates over-matched at fourteen of fifteen, and the narrower one also produced a false negative. The cause is structural: the taxonomy places the same grouping label on the container **and** its children, so the two are label-identical by construction. The design therefore **annotates, not adjudicates**, and both probes are reported over-matching rather than as findings. | Stage 5 measurement |
| **Δ-epic-population** | Roughly 53 open epics | **42** at the pinned baseline, of which 15 are naive candidates and **6** survive gating. The headline defect — zero rollup-close logic — reproduces exactly; the population figure was supporting context, and a 21% shrink does not change the remediation. | Stage 4 re-measurement |
| **Δ-cross-pr-contention** | Excluding the deploy script "removes 100% of cross-release contention" | **False as a release-wide claim.** It was true for card 3's matrix alone. Cards 1 and 4 add three further sibling intersections, including a **new** one on the label grammar found at Commit 0. All sibling edits are additive, so the exposure is merge-order friction rather than corruption. | Stage 5 (card 4) + Commit-0 re-measurement |
| **Δ-adr-allocation** | Two design comments named concrete ADR numbers | **Numbers are allocated by rule at Commit 0, never carried forward.** One of the named numbers was already taken on a sibling branch. Three separate probes in one session returned stale or incomplete sets minutes apart, which is precisely why the rule replaces the number. | Operator ruling; Commit-0 measurement |
| **Δ-adr-rule-corrected** | The rule was *reserve the first slot strictly above every in-flight sibling claim*, leaving two slots for the siblings that must renumber | **The rule is the mainline anchor plus one.** ADR-115 states the number binds at merge, that next-free is never the maximum of the claimed set, and that an unmerged sibling claim is advisory — and it names the reservation strategy as **worse than a duplicate**, because the contiguity gate fails a gap as readily as a duplicate and a merged hole then fails every subsequent pull request. Verified against the enforcing gate with four arms: the reserved slot returns **FAIL — GAP**; the anchor-plus-one returns **PASS**; a duplicate control returns **FAIL — DUPLICATE**, so the PASS is meaningful. **This reversed a hub ruling and was CLOSED on 2026-08-07 as rule-determined, not a judgment call** — ADR-115 governs and no operator ratification was required; the remedy, were the number ever to move at merge, remains one invocation of the sanctioned renumber tool. | Commit-0 measurement against ratified governance |

---

## References

Designated reference block. Each entry pairs the tracker number with a summary noun phrase, so the meaning survives even if the number does not.

| Number | What it is |
|---|---|
| Milestone **265** | `methodology-fields-and-statuses` — this release's milestone; four build cards, 24 points, composition locked at Stage-4 planning entry. |
| **#1963** | The parent epic — Fields and Statuses. Open; this release delivers four of its slices. |
| **#1969** | Axis-1 work-status field and label surface — the foundation card, position 1, carrying Commit-0 duties. |
| **#4179** | The status-maintenance contract — position 2; ships the unconfigured-adapter fallback only. |
| **#1828** | Pipeline-status label materialization — position 3; two declared rows have never existed live, and no materialization path exists anywhere. |
| **#1825** | Epic rollup-close audit — position 4; no mechanism closes an epic whose children are all done. |
| **#4935** | The Stage-4 release-planning sub-task carrying this plan's source output and the operator's plan-approval decision record. |
| **#4926** | An initiative-versus-epic labelling lint in a different milestone that touches the label grammar. **Not in this release's scope;** latent contention only — open, milestoned elsewhere, no branch and no pull request as of Commit 0. |
| **ADR-092** | The version-identity decision record: release branches and plan files are slug-primary, and the concrete version binds at the Stage-12 atomic claim. |
| **ADR-018** | The work-item-type layer — the thin entity plus declarative type layer; the Axis-1 base machine is owned by the entity layer, and packs project over it. |
| **ADR-069** | The methodology pack as the plug-and-play composing unit — placement, manifest, selection. |
| **ADR-070** | The pack composition grammar — pack role and inheritance, the label contribution facet, the work-status projection over the entity base, and the role-conditional kinds relaxation. |
| **ADR-077** | The cross-cutting control field layer — the pre-registered home should a surfaced blocked marker ever be wanted. |
| **ADR-115** | The ADR-number binding rule: a number is allocated at authorship and bound at merge, next-free is the mainline anchor plus one and never the maximum of the claimed set, and reserving a slot above an unmerged sibling claim is worse than a duplicate. |
| **ADR-124** | This release's first decision record: the Axis-1 delivery work-status label surface — seventh grammar group, load-bearing name prefix, base-pack homing, and blocked-is-derived. |
| **ADR-125** | This release's second decision record: the status-resolution fallback when no platform adapter is configured, and the binding of that contract to the adapter layer. Its § Consequences is the citable home for the symptom-honesty statement. |
| **ADR-126** | This release's third decision record: the sub-task status mirror stays a point-in-time snapshot, and label materialization gets a read-only emit path rather than an automated one. |
| **ADR-123** | This release's fourth decision record: the epic rollup-close surface is an audit rather than a gate, and its two undecidable gates are annotated rather than adjudicated. |

---

## Change Description

Authored at Stage 6 by the position-4 Engineering spoke, which owns the release-scoped Phase C under this release's one-branch / one-PR topology. Covers the whole release, not one card.

### Outcome

This release gives the delivery **work-status axis** a field, a live label surface, a maintenance contract, and an epic-rollup audit. Concretely: a seventh label group with six work-status rows homed in the shared base pack; a documented contract for how status resolves when no platform adapter is configured; a read-only emit path that renders the commands to reconcile declared label rows against live ones (8 rows created, 1 malformed row reconciled); and a report-only detective audit that surfaces open epics whose children have all finished, invoked by default from an existing close-out beat.

**One thing this release deliberately does not change: what an operator sees.** The status-maintenance card ships its unconfigured-adapter fallback only; the binding refit that would make a skill consume the contract is routed as a follow-on. A green Stage 8 therefore means the shipped scope is correct — it does not mean the originating symptom is fixed. ADR-125 § Consequences carries this statement in the corpus so it survives past this plan.

### Issues resolved

| # | Outcome | Status |
|---|---|---|
| **#1969** | Axis-1 work-status label group (a seventh grammar group, not a reuse of the status group — that group's cardinality rule *is* the mutex, so filing there would have made the two axes mutually exclusive), six base-pack rows each carrying a colour, plus the field documentation and the two-axis boundary. | **DONE** |
| **#4179** | Status resolution when no platform adapter is configured — a new peer subsection in the meta-schema plus the ADR binding it to the adapter layer. Two of the card's three declared absences already existed and are cited rather than restated. | **PARTIAL** — the unconfigured-adapter fallback ships; the `delivery-engine` binding refit is **deferred** (that skill carries zero references to the field across all twelve of its files, so the refit is net-new work, not an edit). |
| **#1828** | Read-only label materialization path (`--emit-fix`) and the Stage-6 precondition it enforces: a status transition can only apply a label that already exists. Applying an unrecognized label auto-creates it malformed, which the name-only parity diff then reports as reconciled. | **DONE** |
| **#1825** | Epic rollup-close detective audit, a signal-only close-out phase invoking it, and the Stage-13 step name. Report-only: it gates nothing and closes nothing without explicit per-issue authorization. | **DONE** |

### Key decisions

- **The epic rollup surface is an audit, not a gate** — because the taxonomy exempts the epic type from the status-label invariant, and a gate cannot assert on a field governance explicitly exempts. Hosting it as a deploy-time lint was rejected **on the merits**, not merely on scope.
- **Its two undecidable gates annotate, never adjudicate.** Two topological predicates for true-epic-versus-mislabelled-initiative both over-matched at 14 of 15, and the narrower one returned a false negative on the one candidate carrying the shape it was built to catch. The taxonomy places the grouping label on the container **and** its children, so the two are label-identical by construction.
- **Suppression is a comment marker, with zero new labels** — a new trigger for an existing state does not earn a parallel label, and the epic type is status-label-exempt regardless.
- **The sub-task status mirror is not resynced and the grammar rule is not amended** — a whole-corpus probe found zero behavioural sites that read the mirrored value, against a non-zero sensitivity arm.
- **Materialization gets a read-only emit path rather than an automated one**, and that path **reconciles as well as creates** — a create-only fix would have run green and left the malformed row exactly as it found it.
- **Axis-1 rows home in the shared base pack**, and the name prefix is load-bearing independently of the group: the runtime invariant discriminates by prefix, and the grammar group is read nowhere in the deploy script.
- **ADR numbers are the mainline anchor plus one**, never the maximum of the claimed set. This **reverses an earlier hub directive** to reserve a slot above every sibling claim; the reversal was verified against the enforcing gate, where the reservation returns FAIL-GAP and the anchor-plus-one returns PASS against a duplicate control.

### Reversibility

**MIXED · confidence HIGH.** The corpus half is **CHEAP** — revert the merge commit in first-parent form and every file surface returns in one operation. The label half is **not git-native**: label creation is repository *state*, and no revert removes it. Rollback order is therefore **revert the merge first, then delete the eight created label rows** as a user-side repository action — reverting first restores the parity checker to its pre-release state so the gate does not immediately re-flag the deletion as drift. **The reconciled row is forward-only**: it existed before this release carrying a default colour and a null description, so deleting it would remove a row the pipeline is now using, and restoring its prior value would restore a malformed row. Rollback is operator-authorized; there is no autonomous rollback.

### Downstream impact

- **Parity residual: MISSING goes 11 → 3, reduced by 8.** The remaining three are the deliberately-excluded `triage:` rows. This corrects an earlier figure of 12 → 3: the row that was reconciled rather than created was *name*-present all along, so it was never counted in MISSING and reconciling it moves that count by zero.
- **A systemic declared-versus-live mismatch is surfaced, not fixed.** At baseline only 2 of 34 declared-and-live rows matched their declaration on both colour and description. It is correctly not auto-applied — some live values may be deliberate overrides and the gate cannot distinguish an override from drift. Needs per-row operator disposition.
- **The `delivery-engine` binding refit** is the named follow-on that would change the operator-visible symptom.
- **The epic audit's tier gate can upgrade from annotation to filter** if the separate initiative-versus-epic lint lands. Declared, not absorbed, not blocking.
- **The audit's first live fire surfaces 5 clean and 10 flagged candidates from 42 open epics**, with every exclusion carrying a stated reason.
- **An availability defect is routed**: the parity check returns an error status when the GraphQL quota is exhausted. The new audit avoids this class by using REST throughout.
- **An inherited pre-existing package-drift failure** (`pmo-skill-refiner`) is present on the mainline, byte-identical to `origin/main`, and is **not caused by this release**. It must be resolved or explicitly justified before Stage 12.
- **Cross-release contention re-measured at Commit 0 and again at Phase C:** 5 of this release's 12 matrix files are touched by at least one of the four in-flight sibling branches; one sibling touches none of them. Sibling edits are **not** uniformly additive — three carry single-line paragraph replacements — but every deletion sits in a region disjoint from this release's edits, the nearest being seven lines from this release's Stage-13 append. The exposure is merge-order friction, not corruption. Four sibling branches also hold advisory claims on a decision-record number below this release's; those resolve by merge-time renumber, which is governed behaviour.

### Cross-references

- Release plan: this file, top — `release/releases/plans/methodology-fields-and-statuses_RELEASE_PLAN.md`
- Milestone: `methodology-fields-and-statuses` (milestone 265) — see § References for the per-card index
- User-facing release note: authored at Stage 13 Close at `release/releases/notes/vX.Y_RELEASE_NOTES.md`, where the version binds at the Stage-12 atomic claim per ADR-092. This section is the operator-facing pre-merge artifact and does not substitute for that note.
- Decision records: ADR-124, ADR-125, ADR-126, ADR-123 — summarized in § References
