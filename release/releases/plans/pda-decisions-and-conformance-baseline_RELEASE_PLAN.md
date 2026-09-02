<!-- reference-durability: allow-link -->
---
title: Release Plan — pda-decisions-and-conformance-baseline (PDA decisions + instance conformance baseline)
type: release-plan
plan_type: release
status: ACTIVE
release: version-less (capability-slug identity; no tag claimed)
milestone: 357-pda-decisions-and-conformance-baseline
release_class: novel
reversibility: CHEAP rollback (single additive PR) / Confidence HIGH
---
# Release Plan — `pda-decisions-and-conformance-baseline`

**Milestone:** `pda-decisions-and-conformance-baseline` (#357) · hub sub-task #6647 = Stage 4 plan source · #6650 = #5840 Stage 5 Solutioning source · #6651 = first Engineering slice (#5840)
**Version identity:** **version-less / capability-slug** (D-Version valve B, pre-decided in the milestone description). The release's identity is the capability slug `pda-decisions-and-conformance-baseline`. **No version key is claimed and no tag is cut at Stage 12.** The version half of the Engineering-Commit-0 re-verify and the Stage-12 atomic version claim are **INAPPLICABLE** — there is no version slot to contend for, and no next-free computation is performed (computing one would falsely re-open a decided valve). No `RELEASE_VERSION` stamp token (double-brace form) is emitted anywhere in this plan — deliberately not even as a prose mention, since the stamp tooling greps for the literal token and a mention would read as a stamp manifest; `claim-version.sh --verify-stamp <slug>` therefore reports `TOKEN-LESS PLAN` by design, and that verdict is recorded as the declared identity mode rather than a manifest defect.
**Topology:** D-C SINGLE — one release branch (`release/pda-decisions-and-conformance-baseline`), one PR, one merge; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** P0 fully-serial (operator-ratified at Collective Review) — Stage 6 slices route one at a time in dependency order on the single branch; no force-push (including `--force-with-lease`) on the shared branch.
**Release class:** `novel` (D-ReleaseClass recorded at Stage 3 Phase B3, validated at Stage 4 — triggers (a)/(b)/(c) fire; see § Operator Decisions).
**Domain-practice provenance:** `domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-02, domain: governance }` — Form X, determined at Stage 4 Phase A1.5 (the entire File Change Matrix is internal pmo-platform artifacts: ADR corpus + release plan = governance deliverable class; sourcing-exempt).

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #6647, reconciled to the approved **Stage-5 Solutioning** designs (#6650 for #5840; sibling sub-tasks for #5841/#5836/#5838) and to the **Collective Review scope-lock decision** (operator, 2026-09-02): scope LOCKED with the adversarial-review findings carried as **named Stage-6 entry conditions**, graded at Stage 8. Where a scope-lock disposition supersedes a Stage-4 assumption, the transcribed sections preserve the Stage-4 plan of record and the **§ Deviation Log** records the ratified delta. Authored at Engineering Commit 0 by the first Engineering spoke (#6651, issue #5840).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | version-less (capability-slug identity; no tag, no stamp manifest — declared mode, not an absent field) |
| **Date Created** | 2026-09-02 (Wednesday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/pda-decisions-and-conformance-baseline` |
| **Baseline pin (branch base)** | `origin/main` @ `bd961c0583c845c8eb391d742147d750b28391d8` (Engineering Commit 0 instant) |
| **Stage-4 A0 pin** | `origin/main` @ `1c857727e79efc8bde0d839138e659a45ff50fa6` (fetched 2026-09-02T16:56Z; Stage-5 design pin `539c4440` — mainline advanced between the pins with no divergence relevant to any bundled card found at re-read) |
| **PR** | (populated at PR creation, Stage 6 — hub sequences after Wave-1 slices land) |
| **Milestone** | `pda-decisions-and-conformance-baseline` (#357) |

---

## Scope

### Summary

Four small work items (9 raw pts, 10 effective, novel class, version-less identity): one read-only conformance-measurement spike against the operator instance (#5840), one validator-surface investigation (#5841), and two ADR decision records (#5836 key form, #5838 lifecycle-trail carrier). Repo deliverables are additive only (2–3 new ADRs + this plan file) → CHEAP rollback. Internal graph: #5840's baseline informs #5841 (cadence) and #5836 (re-key volume discharges its open assumption); #5838 has no inbound edge and is parallel-eligible. All four Phase A0 rows are C1 — no premise problems. Externally #357 hard-blocks #358/#360/#361 (verified live at Stage 4); #359 has fully shipped (0 open / 29 closed), so its dissolved edge is moot. Primary contention is the `core/ADRs/` numbering namespace — a governed serialization point, not a defect. Posture: D-C SINGLE topology, P0 fully-serial Stage-6 dispatch, one PR. Quota Checkpoint A: PASS.

### Issues Included

| # | Issue | Title (short) | Size | Wave |
|---|-------|---------------|------|------|
| 1 | #5840 | Measure live project-instance conformance against the entity and frontmatter schemas (spike) | M | 1 |
| 2 | #5841 | Instance-conformance validator surface recommendation | S | 1 (finalizes Wave 2) |
| 3 | #5838 | Lifecycle audit-trail carrier-or-retirement ADR | XS | 1 |
| 4 | #5836 | Cross-boundary key form ADR | S | 2 |

---

## Dependency Graph

**Internal (edge direction = tail must land before head finalizes):**

| Edge | Type | Evidence |
|---|---|---|
| #5840 → #5836 | soft-informational, **finish-to-finish binding on the Decision section** | #5836 body: "Informed by the conformance-baseline spike (how many live records would a re-key touch)" + its open `[ASSUMPTION – CONFIRM]` on bare-slug resolution, discharged by the baseline's datum. Drafting alternatives is NOT build-blocked; finalizing the Decision is. Deliberately classified finish-to-finish, not start-to-start — alternatives work may proceed in parallel. |
| #5840 → #5841 | soft-informational (cadence input) | #5841 body: "Informed by R1 (baseline volume shapes the cadence choice)". Same finish-to-finish shape: investigation parallel; recommendation finalizes after baseline volume is known (or states the cadence contingently). |
| (none) → #5838 | — | #5838 body declares no inbound edge from any bundle member (Stage-4 dep-regex scan, probe P2). Parallel-eligible from Wave 1. |

**Circular chains: zero** (3-edge DAG, both edges terminate at leaves — full-graph inspection at Stage 4).

**External (re-verified live at Stage 4, REST reads 2026-09-02):**

| Edge | Status |
|---|---|
| #158 → #5840 (consumed engine) | SATISFIED — #158 closed, `be36561b` merged |
| #357 → #358 (entity-key-and-referential-contract — consumes #5836's decision) | LIVE hard edge |
| #357 → #360 (conformance-and-stewardship-mechanized, incl. #5842 named runner — consumes #5840/#5841) | LIVE hard edge |
| #357 → #361 (index-and-tracker-carry-the-schema — consumes #5838) | LIVE hard edge |
| #357 ⇸ #359 | DISSOLVED 2026-08-28 and moot — #359 reads 0 open / 29 closed (fully shipped) |

---

## Implementation Sequence

Dependency-ordered; no timeline estimates (single-operator PMO — scope and sequence only). Under P0 fully-serial Stage-6 dispatch the serial order is the top-to-bottom reading of the waves.

| Wave | Work | Rationale |
|---|---|---|
| 0 | Release plan committed as Engineering Commit 0 on the release branch (D-C SINGLE) — includes `renumber-adr.py --detect` re-run to bind ADR-numbering state at commit time | Commit-0 Survival Set per `stage-04-planning.md` § 6; version half of the Commit-0 re-verify is INAPPLICABLE (version-less — no version to collide), and the ADR-number allocation takes its place as the contended-namespace check |
| 1 | **#5840** conformance-baseline measurement (read-only vs operator instance; report per its AC set + Stage-6 entry conditions B1–B5) ∥ **#5841** investigation/trade-off draft ∥ **#5838** ADR authoring | #5840+#5841 parallel per the milestone's recorded internal sequence; #5838 promoted to Wave 1 as parallel-eligible (no inbound edge — Stage-4 R-1) |
| 2 | **#5836** ADR (Decision finalized citing the measured re-key volume) · **#5841** recommendation finalized (cadence grounded in baseline volume) | Both finish-to-finish edges discharge here; #5836's open ASSUMPTION is discharged with a measured datum (or an explicit UNMEASURED disposition), never a label |
| 3 | Release-scoped Stages 9–13: Deep Stage-9 review (novel posture) → merge → deploy → Stage-13 close with 30-day outcome window | Per the recorded differentiation posture (milestone description) |

Delivery strategy: **one release branch, one PR** (milestone ships as a single PR; issues are delivery slices on the branch). Rollback strategy: revert the single PR — all repo changes are additive new files (CHEAP, no data loss; #5840 writes nothing anywhere in the instance by construction, so there is nothing instance-side to roll back).

---

## Stage Applicability Matrix

Release class posture: Stage 5 activation bias ALL; Stage 9 depth Deep (release-scoped). Reasoned per-deliverable, not mechanical:

| Issue | S5 Solutioning | S6 Engineering | S7 Dev Testing | S8 QA/Acceptance | Notes |
|---|---|---|---|---|---|
| #5840 (M, spike) | **APPLY** — design the measurement: per-class predicates, envelope-preserving aggregation, control-arm fixtures, reporting granularity | APPLY — run measurement, author report | **APPLY** — DT = independent reproduction: re-run the stated method and assert count equality (AC-2 is literally "a second run reproduces the counts"). DT inherits the PII constraint: counts only, never content, no writes into `projects/` | APPLY — per-criterion verdicts on all 6 ACs + entry conditions B1–B5 | Deliverable = measurement report (operator-local analysis artifact), not a repo fix. DT/QA grade the report's reproducibility and probe validity, not code. |
| #5841 (S, investigation) | **APPLY** — the trade-off space (deploy-check family / doctor mode / scheduled task / health-check mode) IS the design work | APPLY — author recommendation (ADR if architectural — CONDITIONAL matrix row) | **APPLY** — DT grades the record against the named-runner obligation (`gate-efficacy-standard.md`) and AC-3 (#158 dispositioned) | APPLY — 3 ACs + entry conditions 8–9 | Document-class DT: grading is artifact-conformance, not execution |
| #5836 (S, ADR) | **APPLY** — candidate key forms + FK-convention analysis; reconciled against the ADR corpus #359 shipped | APPLY — author ADR | **APPLY** — DT: AC-2 grep-the-record check, X-rule enumeration completeness (AC-3), unconditional-rule assertion | APPLY — 3 ACs + entry conditions 6–7 | Decision record; Stage 5 ADR trigger is itself a novel-class trigger |
| #5838 (XS, ADR) | **APPLY** (bias ALL; option (a) reopens the "index is disposable" design principle — deserves the design pass) | APPLY — author ADR | **APPLY** — DT: AC-2 (Check 6.2 + Domain-C dispositions named), AC-3 (surviving guarantee stated) | APPLY — 3 ACs + entry condition 10 | Smallest item; skipping S5 was considered and rejected under the recorded ALL bias |

No stage is skipped for any issue. Parallel-eligible spoke count (feeds Quota Budget): Stage 5 = 4, Stage 7 = 4, Stage 8 = 4.

---

## Contention Map

**Within-release, literal path overlap: 0 of 6 unordered issue pairs** (Stage-4 probe P1). Each repo deliverable is a distinct new file.

**Within-release, namespace contention: 1** — the `core/ADRs/` number sequence. #5836 and #5838 each add an ADR; #5841 conditionally adds a third. Resolution: sequential allocation at Engineering-commit time from `renumber-adr.py --detect` (`next-free = anchor(origin/main)+1`, never `max(claimed)+1`; branch-only claims are detection-only and never bind).

**Cross-PR / cross-release:** Stage-4 pinned measurement at `1c857727` (2026-09-02T16:56Z): in-flight sibling population n=6 (roster below). Our matrix is new-files-only, so literal-path `EDITSET(sibling) ∩ FCM` = ∅ [INFERRED — rests on our side being additive-only]. The real intersection is the **ADR-number virtual namespace** — a GOVERNED serialization point (whichever release merges later re-runs `--detect` and renumbers), recorded as risk R2, not a Tier-S blocker. One CONDITIONAL literal surface: `core/ADRs/README.md` — if the corpus maintains an index requiring registration of new ADRs, that file is shared with the `adr-corpus-*` sibling releases; Engineering checks via the adr-helper discipline before editing.

**In-Flight Release Roster** — Stage-4 pinned measurement (`1c857727` · 2026-09-02T16:56Z · population n=6 siblings: open PRs with `release/*` heads, drafts included, plus `release/*` remote heads with no open PR; minus this release, which had no branch yet). The roster is a pinned measurement, no verdict; Stage 9 Phase A6.6 re-measures fresh.

| Slug | PR | Head SHA | Bump-class | EDITSET ∩ FCM |
|---|---|---|---|---|
| release/label-and-reference-integrity | #6638 (draft) | `b849424` | UNRESOLVABLE | — |
| release/hub-spoke-run-and-planning-discipline | #6634 (draft) | `5404600` | UNRESOLVABLE | — |
| release/adr-corpus-status-integrity | #6626 (draft) | `90fa03d` | UNRESOLVABLE | ADR-number namespace (R2) |
| release/kit-unit-and-selection | #6621 (draft) | `8746006` | UNRESOLVABLE | — |
| release/adr-corpus-integrity | — | `5b953cb` | UNRESOLVABLE | ADR-number namespace (R2) |
| release/operational-folder-enforcement-migration | — | `9dcb960` | UNRESOLVABLE | — |

Bump-class renders UNRESOLVABLE per the roster rule (unknown ≠ absent); this release contributes no `Δversion/<claim-key>` token — version-less identity claims no version slot, so version-slot contention is structurally inapplicable on our side. *Commit-0 instant delta (recorded, not re-verdicted): at Engineering Commit 0 the remote holds 5 `release/*` sibling heads — `adr-corpus-status-integrity` merged during the session window (one driver of the ADR anchor moving 170 → 172; see § Deviation Log).*

---

## File Change Matrix

`domain_practice` label for this matrix is recorded in the plan header (Form X — pipeline-internal, `domain: governance`).

```
release/releases/plans/pda-decisions-and-conformance-baseline_RELEASE_PLAN.md  ADD
core/ADRs/ADR-NNN-cross-boundary-key-form-for-entity-and-tracker-identifiers.md  ADD
core/ADRs/ADR-NNN-lifecycle-audit-trail-carrier-or-retirement.md  ADD

# ── CONDITIONAL rows ── (both resolved at the #5841 slice: the validator-surface row PROMOTED —
#    the recommendation implies an architectural decision, ADR authored; the README row DROPPED —
#    core/ADRs/README.md declares itself a curated thematic document, NOT an index, so no
#    registration is required and no edit is made)
core/ADRs/ADR-174-instance-conformance-validator-surface.md  ADD

#### Read-only inputs
operations/skills/health-check/SKILL.md  READ
core/disciplines/project-entity-model.md  READ
core/schemas/entity-field-schemas.md  READ
core/schemas/sqlite-index-schema.md  READ
core/standards/gate-efficacy-standard.md  READ

#### Release-wide explicit non-scope
projects/**  NOT TOUCHED
core/disciplines/project-entity-model.md  NOT EDITED
core/schemas/sqlite-index-schema.md  NOT EDITED
core/standards/gate-efficacy-standard.md  NOT EDITED
```

`NNN` placeholders resolve at each ADR's Engineering-commit moment via `release/tools/renumber-adr.py --detect` (`next-free = anchor(origin/main)+1`; at Engineering Commit 0 the tool reads ANCHOR 172 / NEXT-FREE 173 / branch-only claims 173,174,175,176 — detection-only, never binding; the committing slice re-derives). #5840's measurement report is an operator-local analysis artifact (its body declares "no repo file changes" and "Documentation Impact: None") and therefore carries no matrix row; the consuming edits its findings size land inside the ADR rows above. The two `CONDITIONAL:` rows promote or drop in the same commit their conditions resolve, per the matrix contract. If #5841's recommendation resolves to a non-ADR home, its finding lands as an operator-local analysis record and the row is recorded `NOT DELIVERED` in the § Deviation Log.

---

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (#5836 × #5838 × #5841-conditional on `core/ADRs/` numbering namespace):** every ADR this release adds carries a distinct number, sequentially allocated from the merge-time anchor, with zero duplicate claims inside the merged PR. *Method:* `python3 release/tools/renumber-adr.py --detect` on the merged tree → CLAIM rows show this release's ADRs with no duplicate number; null-arm control per AC-Binding Limb 2: the same instrument at plan time already returned a non-zero claims set (`CLAIMED-SET-BRANCH-ONLY 171,172,173` at the Stage-4 pin; `173,174,175,176` at Commit 0), so a clean post-merge zero-duplicate read is distinguishable from a dead detector. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#5840 × #5836 on the #5836 ADR's Evidence/Decision sections):** the key-form ADR cites the conformance baseline's measured re-key touch-count (or an explicit UNMEASURED disposition from the baseline report) — its bare-slug-resolution `[ASSUMPTION – CONFIRM]` is discharged with #5840's datum, not left open and not silently dropped. Per the operator's D-CIAC2 scope extension, the datum is the **bare-slug cross-boundary census + instance-wide id-collision count** measured by #5840's instance-grain classes (C8/C9), not a form-blind proxy. *Method:* `grep -iE "baseline|conformance|re-key|bare-slug" core/ADRs/ADR-*key-form*.md` → non-empty, and the matched line carries a count or an UNMEASURED token. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#5840 × #5841 on the health-check `structure` engine):** the two artifacts agree on the same measurement engine — #5840's report attributes its covered classes to `health-check structure` mode, and #5841's recommendation names and dispositions that same engine (adopt-as-home or reject-with-reason), never a silently parallel surface. *Method:* `grep -c "structure" core/ADRs/ADR-174-instance-conformance-validator-surface.md` → non-zero AND the #5841 deliverable names #158's engine in its disposition section (ADR-174 Decision §6 partition + § Provenance disposition line); co-occurrence check against #5840's report's engine-attribution section. (Placeholder resolved to the concrete path at the #5841 slice per the same-commit promotion rule.) *Graded at Stage 9 QC3.5 on the merged PR.*

---

## Risk Register

| ID | Risk | Class | Owner (role) | Mitigation | Reversibility / Confidence |
|---|---|---|---|---|---|
| R1 | **PII exposure via #5840** — the spike (and its Stage-7 DT reproduction) reads operator project data under `projects/` containing PII | Compliance / scope | Engineering + DT spokes | Hard constraints carried into both spoke prompts: report **counts and rule classes only, never record content**; **no writes into `projects/`**. Write-guard backstop (corrected per scope-lock condition 2): the applicable control for the `pmo-platform` → `projects/` direction is **`BLOCK-AUTONOMY-004` — mode-gated** (below the master and scope gates; not reached under master-OFF), so it is defense-in-depth only, never the design; read-only-by-construction of the invocation is the design (entry condition B1). `BLOCK-AUTONOMY-002` guards the opposite (projects → platform disclosure) direction. Report lands in the operator-local git-ignored analysis workspace — nothing instance-derived enters the public repo. AC-6 requires stated evidence. | CHEAP (nothing written) / HIGH |
| R2 | **ADR-number collision** — in-flight siblings hold branch-only claims; this release adds 2–3 ADRs | Contention | Engineering spokes | Governed, not a defect: allocate at each ADR's commit from a fresh `--detect` (`anchor(origin/main)+1`), re-check at Stage 9 entry (sibling-merge trigger); the later-merging release renumbers. Never bind numbers at plan time. Anchor already moved 170 → 172 during the Stage-5 wave — confirming the re-derive-at-commit rule. | CHEAP / HIGH |
| R3 | **Downstream cascade** — #357 hard-blocks #358/#360/#361; a slip or a weak decision record idles three milestones | Dependency | Operator + Stage-9 review | Deep Stage-9 review (recorded posture) grades the two ADRs against their consuming children; finish-to-finish edge classification keeps parallel work flowing rather than over-serializing | MODERATE / MEDIUM |
| R4 | **Stale-corpus decision risk** — #359 shipped 29 items AFTER this bundle was composed; its system-of-record and health-RAG-mastering decisions may constrain #5836 (key form touches FK/SSOT conventions) and #5838 (carrier choice touches SSOT-vs-cache doctrine) | Scope / currency | Stage-5/6 spokes for #5836/#5838 | The corpus through ADR-170+ (everything #359 landed) is read and reconciled before alternatives freeze; a contradiction found there routes Tier 1 [ADJUST] or Tier 2 per the Inter-Stage Feedback Protocol | CHEAP (read) / MEDIUM |
| R5 | **Residual-class unmeasurability** (#5840) — RAID-row, tracker-parity, or ADR-080 folder classes may prove unmeasurable against live data | Scope | Engineering spoke | AC-3 licenses "reported unmeasurable states why" — an honest UNMEASURED is a valid deliverable; the coverage envelope carries forward un-flattened (AC-4); a zero without a firing control arm is reported as a broken probe, never a clean class (AC-5) | CHEAP / HIGH |
| R6 | **#5841 recommendation outruns its input** — fully parallel start means the cadence choice could be authored before baseline volume exists | Sequencing | Engineering spoke | Wave-2 finalization rule: the recommendation's cadence section lands (or is made explicitly contingent) only after #5840's volume datum | CHEAP / HIGH |
| R7 | **Conditional-row ambiguity** (#5841 ADR-or-analysis home) | Plan integrity | Engineering spoke | `CONDITIONAL:` token in the matrix + same-commit promotion rule + Deviation-Log `NOT DELIVERED` row if the analysis-record path is taken | CHEAP / HIGH |

Rollback complexity, release-wide: **LOW** — single PR, additive files only, no version claim to unwind (version-less), no instance-side writes. Rollback = revert the PR; downstream milestones simply remain blocked as they are today.

---

## Delivery Strategy

| Aspect | Decision |
|--------|---------|
| **Implementation approach** | Wave-ordered per § Implementation Sequence: Commit 0 (this plan) → Wave 1 (#5840 ∥ #5841 draft ∥ #5838) → Wave 2 (#5836 Decision + #5841 finalization) — dispatched P0 serial |
| **Commit strategy** | Grouped commits per issue slice on the single release branch (this plan = Engineering Commit 0); commit messages reference their source issue; close-family verbs bound to an issue number appear only in the PR body's dedicated Issue References block |
| **Review approach** | Single PR for the entire release (D-C SINGLE), created in draft, transitioned ready at Stage 9 |
| **Deployment mechanism** | Git merge only — no skill copies, no `.skill` rebuilds, no Layer-2 propagation targets in the matrix (ADRs + plan are repo-corpus files) |
| **Concurrency posture** | P0 fully-serial — no force-push on the shared release branch |
| **Sub-task container** | GitHub sub-issues (hub-owned): per-issue Stage-6 sub-tasks exist under the release hub; special sub-tasks (sync N/A — no propagation targets; plan-update; verification) tracked on the same surface |

---

## Verification Plan

### AC baseline

Per-issue acceptance-criterion counts as read at Engineering Commit 0, with the commit the read was taken against. The ordinal in the `AC` column is positional, so this baseline is what makes ordinal drift countable rather than silent. **The baseline is a pinned measurement and carries no verdict.**

| Issue | AC count at Commit 0 | Read at |
|-------|---------------------|---------|
| #5840 | **6** | issue body revision 2026-08-29T03:44:14Z |
| #5841 | **3** | issue body revision 2026-08-29T03:37:54Z |
| #5836 | **3** | issue body revision 2026-08-22T21:44:34Z |
| #5838 | **3** | issue body revision 2026-08-29T03:37:51Z |

### Per-Issue Verification

| Issue | AC | Predicate class | Verification Method | Expected Result |
|-------|----|-----------------|--------------------|-----------------|
| #5840 | AC-1 | content | Verification deferred to Stage-7 DT re-execution + Stage-8 acceptance review (the baseline report is operator-local in the git-ignored analysis workspace; this plan's repo-side executor cannot reach it): read the baseline report's class table; assert per-class conforming/non-conforming counts, a stated denominator per class, and a per-class engine-attribution column | ≥6 named rule classes (design: 7 core classes C1–C7 + 2 instance-grain extension classes C8–C9 per D-CIAC2), each with counts, denominator, and engine attribution (`health-check structure` for C1–C4; named spike-local predicate for C5–C9) |
| #5840 | AC-2 | content | Verification deferred to Stage-7 DT re-execution + Stage-8 acceptance review (the baseline report is operator-local in the git-ignored analysis workspace; this plan's repo-side executor cannot reach it): read the report's Method section + run manifest; Stage 7 re-runs the stated method and compares per-class counts (script classes byte-reproducible; engine classes compared as per-rule-class finding sets with the delta-adjudication rule) | Method names its engine per class with the exact invocation set + enumerated project population; a second run reproduces the counts (post-adjudication equality for engine classes) |
| #5840 | AC-3 | content | Verification deferred to Stage-7 DT re-execution + Stage-8 acceptance review (the baseline report is operator-local in the git-ignored analysis workspace; this plan's repo-side executor cannot reach it): read the report; assert the three residual classes (RAID rows vs machine schema; tracker header-to-schema column parity; ADR-080 folder membership) are each present with counts, or carry an explicit unmeasurable-with-why state | All three named with counts and denominators, or `UNMEASURED(reason)` / `PROBE-BROKEN` stated per class — never silently absent |
| #5840 | AC-4 | content | Verification deferred to Stage-7 DT re-execution + Stage-8 acceptance review (the baseline report is operator-local in the git-ignored analysis workspace; this plan's repo-side executor cannot reach it): read the report's coverage section; assert per-project excluded entity types are enumerated (named per project, never unioned) and any `UNMEASURED` project renders as `UNMEASURED` in aggregates | Coverage envelope carried verbatim per project; instance totals computed over measured projects only ("k of n measured; UNMEASURED: keys"); no composite instance score anywhere |
| #5840 | AC-5 | content | Verification deferred to Stage-7 DT re-execution + Stage-8 acceptance review (the baseline report is operator-local in the git-ignored analysis workspace; this plan's repo-side executor cannot reach it): read the report's control-arm record; assert a two-arm record per class (sensitivity arm observed non-zero; specificity arm observed zero; extraction non-empty for subject and both arms) | Every reported class admitted only with green two-arm controls; a class whose control failed renders `PROBE-BROKEN`, never a clean zero |
| #5840 | AC-6 | content | Verification deferred to Stage-7 DT re-execution + Stage-8 acceptance review (the baseline report is operator-local in the git-ignored analysis workspace; this plan's repo-side executor cannot reach it): read the report's read-only evidence: pre/post metadata manifests over `projects/**` (path·size·mtime, hashed) + the pinned invocation form (entry condition B1) | Manifest byte-equality pre vs post (or any delta fully ⊆ the declared, enumerated engine-staging surface with an operator disposition row per staged artifact); invocation form named; zero writes into `projects/` by this spike's own tooling |
| #5841 | AC-1 | content | Verification deferred to Stage-7 document-class DT + Stage-8 acceptance review (deliverable home is CONDITIONAL — ADR or operator-local analysis record, risk R7 — so no stable repo path exists to probe from this plan): read the recommendation; assert a Decision naming exactly one surface plus an Alternatives section with ≥2 rejected alternatives and their trade-offs | One named surface; ≥2 rejected alternatives with trade-offs stated |
| #5841 | AC-2 | content | Verification deferred to Stage-7 document-class DT + Stage-8 acceptance review (deliverable home is CONDITIONAL — ADR or operator-local analysis record, risk R7 — so no stable repo path exists to probe from this plan): read the recommendation; assert the warn-to-enforce path and flip-justifying evidence are named explicitly (per scope-lock condition 8, against an instrument that can actually evidence the flip criterion) | Warn-to-enforce path stated; flip evidence named against a run-grain-capable instrument (or the criterion restated to one) |
| #5841 | AC-3 | content | Verification deferred to Stage-7 document-class DT + Stage-8 acceptance review (deliverable home is CONDITIONAL — ADR or operator-local analysis record, risk R7 — so no stable repo path exists to probe from this plan): read the recommendation's disposition section; assert #158 (health-check `structure` mode) is named and dispositioned | #158 named; adopt-as-home or reject-with-reason stated (CIAC-3 co-verifies engine agreement with #5840's report) |
| #5836 | AC-1 | content | `grep -cE '^#+.*(Decision\|Alternatives)' core/ADRs/ADR-*key-form*.md` → ≥2 (both sections present); then read the record: exactly one cross-tier key form decided, ≥2 rejected alternatives with trade-offs | One key form decided; ≥2 alternatives rejected with trade-offs |
| #5836 | AC-2 | content | `grep` the ADR for the rule binding `id` and `<entity>_id` for the eight dual-key entities; assert it is unconditional, not hedged | One unconditional binding rule present (anchored on `project_id` per scope-lock condition 6 — the ninth identity binding added) |
| #5836 | AC-3 | content | `grep -cE 'X-[0-9]+' core/ADRs/ADR-*key-form*.md` → non-zero (affected X-rule ids enumerated); then read the record for the surviving FK-target convention statement | Surviving convention named; affected X-rule ids enumerated |
| #5838 | AC-1 | content | `grep -cE '^#+.*Decision' core/ADRs/ADR-*lifecycle-audit-trail*.md` → non-zero; then read the Decision section: exactly one carrier option selected with rationale | One carrier option selected with rationale |
| #5838 | AC-2 | content | `grep -ciE 'Check 6\.2\|Domain-C' core/ADRs/ADR-*lifecycle-audit-trail*.md` → non-zero; then read the record: dispositions of health-check Check 6.2 and the Domain-C checklist items both named (per scope-lock condition 10: govern the approval-class vocabulary + pin absent-semantics, or mark the control UNVERIFIED and defer the predicate to the validator seam) | Both dispositions named; the Check-6.2 predicate soundness issue resolved per condition 10 |
| #5838 | AC-3 | content | `grep -ciE 'surviving guarantee' core/ADRs/ADR-*lifecycle-audit-trail*.md` → non-zero; then read the record: it states whether "rebuild is identical" or "audit trail" survives | The contradiction resolved explicitly; one surviving guarantee stated |

---

## Release-Scoped Verification

Held in its own H2, deliberately: the plan verifier parses every markdown table under `## Verification Plan` as per-issue check rows, so a differently-shaped table must live outside that section.

| # | Release-scoped check | Invocation | Result required |
|---|----------------------|-----------|-----------------|
| **V-1** | ADR numbering contiguity | `python3 release/tools/check-adr-numbers.py` on the release branch pre-merge | Zero duplicates, zero gaps across both ADR homes |
| **V-2** | Plan conformance | `bash release/tools/verify-release-plan.sh release/releases/plans/pda-decisions-and-conformance-baseline_RELEASE_PLAN.md` | Every family PASS or a named SKIP. The `release-version-stamp` element is **correctly absent** — it fires only when a version-stamp token is present, and a version-less plan emits none |
| **V-3** | Doc-link integrity | `deploy.sh --check` Check 14 over the modified `.md` files | Every internal markdown link in a modified file resolves |
| **V-4** | Stamp-manifest declaration honesty | `bash release/tools/claim-version.sh --verify-stamp pda-decisions-and-conformance-baseline` | Verdict `TOKEN-LESS PLAN` (exit 1) — the *declared* version-less state, recorded verbatim; any OTHER non-zero verdict (HALT) is a real manifest defect and blocks |
| **V-5** | CIAC-1..3 verdicts | Per § Cross-Issue Acceptance Criteria methods | Graded release-level at Stage 9 QC3.5 on the merged PR |
| **V-6** | Instance read-only proof (#5840) | Pre/post metadata-manifest comparison over `projects/**` banked in the baseline report's evidence folder | Byte-equal manifests (or delta fully ⊆ declared engine-staging surface, enumerated + dispositioned); reproduced independently at Stage 7 |

---

## Quota Budget

**Verdict:** PASS (per `quota-budget-protocol.md` Checkpoint A)
**Parallel-eligible spokes per parallel stage (from A2 Stage Applicability Matrix):** Stage 5: 4 · Stage 7: 4 · Stage 8: 4
**Per-spoke cost estimate:** size-bucket ordinal band (source: heuristic — § 5; no telemetry-median supersession asserted): 1× low–moderate (`size:M` #5840) + 2× lowest (`size:S`) + 1× lowest (`size:XS`)
**Assumed/stated remaining usage-window envelope:** [ASSUMPTION – CONFIRM] unstated at spoke launch → conservative-default fresh-window envelope assumed
**Estimated cumulative draw % (worst parallel batch):** < 50% — worst batch is 4 spokes dominated by lowest-band items; ordinal reasoning, not an absolute token figure (bands are `[CALIBRATE-AFTER-3]` MEDIUM)
**Routing:** PASS — proceed parallel at Stages 5/7/8; Stage 6 dispatch is P0 serial regardless (D-Concurrency)
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton; STAGGER is a secondary rate-limit-only defense. Checkpoint B also gates the host-API axis (`core`/`graphql` pools) DEFER-dominant per § 4.3b — of live relevance this run: the GraphQL pool was observed rejecting writes while reporting a full quota during this release's session; the pools are separate — on a rate-limit error, SWITCH to REST rather than wait. Checkpoint A stays usage-window-only by design (§ 3.1).

---

## Operator Decisions (recorded)

### D-ReleaseClass — RECORDED (validated at Stage 4, no re-ask): `novel`
Class rendered at Stage 3 Phase B3 and validated against `release-class-taxonomy.md`: novel triggers (a) ≥1 new decision record/ADR (2 unconditional), (b) D-class decisions in this plan, and (c) Stage 5 activated with ADR-shaped design work all fire; cross-cutting counter-check does not fire (0 `pipeline/stage-*.md` edits, 0 rule-defining governance surfaces touched, 2 in-bundle compositional edges < 3). Differentiation posture carried: engagement Standard · Stage 9 Deep · Stage 5 ALL · Stage 13 30-day. Reversibility CHEAP / Confidence HIGH.

### D-Version — RECORDED DETERMINATION (valve B; not an operator gate): version-less
Identity = capability slug `pda-decisions-and-conformance-baseline`; no version key claimed at Stage 12; plan file is slug-primary. No next-free computation performed (deliberately — computing one would falsely re-open a decided valve). Consequences bound into this plan: no `Δversion` token in the Tier-S surface; the Commit-0 version-half re-verify is INAPPLICABLE; the `RELEASE_VERSION` stamp-manifest row (Survival-Set row 5, double-brace token form) is INAPPLICABLE under version-less identity — this Header records the identity mode explicitly so `verify-release-plan.sh` and Stage 12 read a *declared* mode, not an absent field. Reversibility CHEAP / Confidence HIGH.

### D-C Branch Topology — SINGLE (ratified)
One release branch, plan as Engineering Commit 0, one PR (4 small issues, one coherent capability boundary, additive-only matrix, milestone-ships-as-one-PR precedent). Reversibility CHEAP / Confidence HIGH.

### D-Concurrency Posture — P0 Fully Serial (operator-ratified at Collective Review)
Default, safe-by-construction; the ADR-number allocation is inherently serial and the bundle is small enough that parallel Stage-6 dispatch buys little. No force-push (incl. `--force-with-lease`) on the shared branch. Reversibility CHEAP / Confidence HIGH.

### D-ScopeLock — Collective Review (operator, 2026-09-02): SCOPE LOCKED
Bundle membership unchanged (#5840, #5841, #5836, #5838); scope hard-locked through Stage 9; any further change is a governed override. Documented override rationale (4 N-way disagreement rows + 1 Blocker would otherwise block): every finding is repairable inside its spec before Stage 6 writes anything, and no adversarial finding reopened a surface verdict. The findings are carried as **named Stage-6 entry conditions** (transcribed in § Deviation Log) and graded at Stage 8, rather than resolved by another design wave. Reversibility MODERATE / Confidence HIGH.

### D-CIAC2 — operator scope extension on #5840 (Tier-2, recorded at Collective Review)
CIAC-2 was found unsatisfiable as designed: #5836 consumes a **bare-slug cross-boundary census and an instance-wide id-collision count**, and no class in #5840's 7-class design measures form, boundary, or cross-project collisions (found independently by two adversarial reviewers). Resolution: **extend #5840's card** — add the instance-grain classes measuring what #5836 consumes (bare-slug/cross-boundary reference census; `project_id` collision check), so `{{P_REKEY_DATUM}}` discharges against a real measured datum rather than an `UNMEASURED` token. Recorded in § Deviation Log; graded at Stage 8.

---

## Deviation Log

Departures from the Stage-4 plan of record, ratified at the **Collective Review scope-lock** (operator, 2026-09-02, decision recorded on the release thread). Scope hard-locked through Stage 9. The adversarial findings reconcile in Stage 6 (return-to-Solutioning NOT warranted). Transcribed per issue:

| Item | Severity | Disposition (binding Stage-6 entry condition) |
|---|---|---|
| **#5840 / B1 — invocation-mode pin** (adversarial PR-1/FM-1/CD-1) | Blocker | "Read-only by construction" holds only for the **interactive `--scope <project>`** invocation form; the health-check SKILL.md contract writes **scheduled** output to `08-Generated/_health-check/YYYY-MM-DD-<mode>.md` (a declared auto-write folder) and stages `Rollup-Diffs` proposals there. The method must name the invocation form and handle the Rollup-Diffs class explicitly — read-only true *by construction of the invocation*, with the construction stated. *Correction to the finding as filed:* the write mandate is in `health-check/SKILL.md`, NOT `structure-mode.md` § 7 (that file contains zero occurrences of the path and says "never a live write"). |
| **#5840 / B2 — write-guard re-attribution** (adversarial PR-3) | Minor | `BLOCK-AUTONOMY-002` guards the projects → platform (disclosure) direction only after the #5293 split; the applicable control for platform → projects is **`BLOCK-AUTONOMY-004`, mode-gated** (below master and scope gates; NOT reached under master-OFF). Cited honestly as conditional defense-in-depth, never as an irreducible floor. |
| **#5840 / B3 — D-CIAC2 scope extension** | Tier-2 scope change | Add the instance-grain classes measuring the bare-slug cross-boundary census and the instance-wide id-collision count that #5836 consumes (see § Operator Decisions § D-CIAC2). |
| **#5840 / B4 — enumeration fixes** (adversarial PR-2/FM-4/FM-5) | Major | Casefold + inode dedup in the enumeration (the Stage-5 "holding area" is inode-identical to the archive under a case-variant name — double-counted); root-dir ground truth re-derived (a file was counted as a root dir); shadow-copy count corrected for archive leakage; canonical-filename token resolution pinned (FM-5). |
| **#5840 / B5 — machine-composed public surface** (adversarial FM-3/CD-2) | Major | The public sub-task body is machine-composed from the aggregate counts JSON with a PII lint (both arms fixture-tested); the spoke posts the emitted file verbatim — "counts and rule classes only" holds by construction, not discipline. |
| **#5836 / conditions 6–7 — root re-anchoring** | Binding entry condition | `Project.id` derives from the mutable folder slug; the sole-join-key rule governs `project_id` in frontmatter — different fields. Anchor the qualified composite on `project_id`; add the ninth identity binding. Reconcile the R-REF-1 / R-REF-3 contradiction on bare Person references, and X-05's `.id` binding against the "no inbound edge ever breaks" claim. |
| **#5841 / conditions 8–9 — flip-evidence repair** | Binding entry condition | The warn sink writes a row only when a violation fires (no run-grain record), so "K consecutive runs with zero WARNs" cannot be read from it — add a run-grain record or restate the flip criterion against an instrument that can evidence it. Close the scheduled-path emitter bifurcation (direct engine invocation bypasses the mode resolver and warn emitter). |
| **#5838 / condition 10 — predicate repair** | Binding entry condition | The restated Check 6.2 predicate mis-classifies the platform's only two `published` fixtures (both carry `lifecycle_trigger: retroactive-backfill`; the field is free-text with no governed vocabulary, so the equality test is unsound). Govern the approval-class vocabulary and pin absent-semantics, or mark the control UNVERIFIED and defer the predicate to the validator seam. |
| **ADR anchor movement** (recorded delta) | Context | The scope-lock recorded anchor **172** / next-free **173** (moved 170 → 172 during the Stage-5 wave as sibling releases merged). At Engineering Commit 0, `--detect` reads ANCHOR 172 / NEXT-FREE 173 / branch-only claims 173,174,175,176 / CLAIM NONE (this plan adds no ADR). Allocation stays at each ADR slice's commit moment and is re-derived there — never inherited from this row. |
| **Sibling-roster delta** (recorded) | Context | Stage-4 roster pinned n=6 sibling `release/*` heads; at Commit 0 the remote holds 5 — `adr-corpus-status-integrity` merged during the session window. Pinned measurement stands; Stage 9 A6.6 re-measures fresh. |
| **Systemic pattern** (scope-lock, recorded for Stage 13) | Context | Nearly every Major finding is one defect class: **a zero that cannot distinguish "measured and empty" from "never measured"** (an equality test against an ungoverned free-text field; a flip criterion reading a failure-only instrument; a read-only claim resting on an unexamined engine contract). For a release whose subject IS conformance measurement, this is a systemic finding, not four coincidences. |
| **#5840 SUMMARY.md not spoke-authored** (Stage 6 execution note) | Minor | The measurement run completed in full (runs/ + evidence/ + scripts/ in the analysis home; all ACs discharged), but a harness control (subagent report-file guard) refused the spoke's SUMMARY.md write. Disposition: the summary prose (method, coverage, validity threats, consumption notes, reproduction) is carried on the #6651 Stage-6 comment and in `evidence/run-manifest.json`; the operator may materialize SUMMARY.md from it. No content was lost; no control was bypassed. |
| **#5840 analysis-home landing** (Stage 6 execution note) | Minor | `block-destructive.sh` rule BLOCK-DESTRUCTIVE-019 blocks primary-checkout `analysis/` writes from a non-worktree session cwd, so the run landed in the release worktree's git-ignored `analysis/conformance-baseline-2026-09-02/` (same repo-relative home). A user-side copy step into the primary checkout's analysis workspace is handed off on #6651. |

---

## Non-coverage — what this release does NOT deliver

1. **No instance remediation.** #5840 measures conformance; it fixes nothing instance-side. Disposition of shadow copies, the case-variant archive spelling, and any staged engine artifacts is operator scope, enumerated in the baseline report for operator action.
2. **No durable validator.** #5840's residual predicates are deliberately throwaway spike-local scripts in the git-ignored analysis workspace; the durable home for recurring conformance validation is exactly #5841's open question (and #5842 is the named runner child). Promoting the spike scripts without that decision would be intermediate-artifact debt.
3. **No re-key execution.** #5836 decides the key form; the consuming re-key work belongs to #358's children.
4. **The measurement report is not a repo artifact.** It lands in the operator-local git-ignored analysis workspace per the analysis-workspace standard; the repo carries only this plan + the ADRs. Its acceptance evidence is the per-stage sub-task record (counts-only public surface) — recorded as the `artifact-accepted` end state for the #5840 deliverable, with the canonical path declared operator-local by design.

---

## Change Description

(Authored per `release/governance/RELEASE_PROTOCOL.md` § Change Description Protocol; refreshed as slices land on this branch — as of Engineering Commit 0 plus the #5840 and #5838 slices, the baseline measurement and the lifecycle audit-trail carrier ADR (ADR-173) are the engineered portion; the cross-boundary key-form ADR and the #5841 recommendation land in subsequent slices.)

### Outcome

This release converts the PDA remediation arc's biggest unknowns into decided, measured ground: an instance-wide **conformance baseline** measuring how many live records violate which rule class (consuming the shipped health-check `structure` engine per project and measuring the residual classes it does not reach), a **validator-surface recommendation** grounded in the measured volume, and two **decision records** — the cross-boundary key form and the lifecycle audit-trail carrier — that unblock the three downstream delivery milestones consuming them.

### Issues resolved

| Issue | Deliverable | End state |
|---|---|---|
| #5840 | Instance conformance baseline (operator-local measurement report; counts + rule classes only) | `artifact-accepted` (operator-local canonical path, declared by design; acceptance evidence = per-stage sub-task record) |
| #5841 | Validator-surface recommendation (ADR conditional) | pending slice |
| #5836 | Cross-boundary key-form ADR | pending slice |
| #5838 | Lifecycle audit-trail carrier ADR | `artifact-accepted` (`core/ADRs/ADR-173-lifecycle-audit-trail-carrier-or-retirement.md` on this branch) |

### Key decisions

Recorded in § Operator Decisions: version-less identity (valve B) · SINGLE topology · P0 serial · scope-lock with named Stage-6 entry conditions · D-CIAC2 instance-grain scope extension on #5840.

### Reversibility

CHEAP — single additive PR; revert restores prior state fully. Instance-side: nothing written by construction (#5840 read-only invocation + counts-only reporting).

### Downstream impact

#358 / #360 / #361 consume the two ADRs and the baseline; they remain blocked until this release lands, and their sizing reads the baseline's per-class counts.

### Cross-references

Stage-4 plan source: hub sub-task #6647. Stage-5 designs: #6650 (#5840) + sibling sub-tasks. Scope-lock: release-thread decision comment (2026-09-02). Baseline engine: #158 (health-check `structure` mode).

---

## Verification Evidence

Populated per slice as it lands (stage-06 Phase C4 self-verification); the PR-assembly slice consolidates.

### #5840 slice (Engineering spoke #6651, 2026-09-02)

| Check | Evidence | Verdict |
|---|---|---|
| AC-1 (≥6 classes, denominators, engine attribution) | 9-class table machine-composed at `evidence/public-body.md` (posted verbatim on #6651): C1–C4 engine-attributed, C5–C9 spike-predicate-attributed, denominator per class | PASS |
| AC-2 (reproducible method, engine named per class) | `evidence/run-manifest.json` — repo pin, skill version, invocation form, per-script reproduction sequence; scripts byte-reproducible; engine-class delta-adjudication rule recorded | PASS |
| AC-3 (3 residual classes measured or unmeasurable-with-why) | C5 209/68 rows · C6 7 of 9 present slots divergent (18-slot frame) · C7 1 unknown / 24 dirs — all three MEASURED | PASS |
| AC-4 (envelope carried; UNMEASURED never a zero) | Per-project envelope rows verbatim in public body; measured-only sums; no composite score; fixture-proven UNMEASURED propagation (malformed punch list renders UNMEASURED) | PASS |
| AC-5 (control arm per class) | `evidence/fixture-controls.json` — 15/15 arms green; engine-layer sensitivity = live non-zero findings in all four C1–C4 families + live PASS rows | PASS |
| AC-6 (no instance file modified) | Pre/post metadata manifests over the projects tree: 3,598 files, sha256 `bd54eee5…89a86` byte-equal; declared engine-staging envelope delta EMPTY; invocation form pinned interactive (B1) | PASS |
| Entry conditions B1–B5 | B1 invocation pinned + Rollup-Diffs handled (banked-punch-list construction, envelope armed, zero arose) · B2 BLOCK-AUTONOMY-004 cited mode-gated, verified at source · B3 C8/C9 built + measured · B4 casefold/inode dedup + root ground truth (13=9+4) + shadow-count corrected · B5 machine-composed public body, lint self-test FIRES, clean render | DISCHARGED |

**Artifact-Acceptance Record (deliverable_state: `artifact-accepted`):**

| Deliverable | Declared canonical path | Acceptance evidence |
|---|---|---|
| Instance conformance baseline (#5840, task-class, operator-local by design) | `analysis/conformance-baseline-2026-09-02/` in the git-ignored analysis workspace (landed in the release worktree per the Deviation Log; user-side copy to the primary checkout handed off on #6651) | #6651 Stage-6 comment (counts-only public body, verbatim) + `evidence/run-manifest.json` + `evidence/fixture-controls.json` + banked punch lists `runs/P1..P3-structure.md` |

### #5838 slice (Engineering spoke #6663, 2026-09-02)

| Check | Evidence | Verdict |
|---|---|---|
| AC-1 (exactly one carrier option selected, with rationale) | ADR-173 Decision §§1–2 select option (b) — retire `lifecycle_events`; the frontmatter last-transition triple is the only lifecycle state. Alternatives Considered carries the full 5-candidate carrier table with kill-reasons + the 2-survivor trade-off. Method probe: `grep -cE '^#+.*Decision'` → 1 | PASS |
| AC-2 (Check 6.2 + Domain-C checklist dispositions both named) | Decision §4 names health-check **Check 6.2** — RESTATE as a frontmatter predicate over the governed approval-class trigger vocabulary with fail-closed absent semantics — and both **Domain-C** checklist items: published-without-approval → RESTATE (identical predicate); per-transition audit-trail item → RETIRE-AND-REPLACE with the last-transition claim. Method probe: `grep -ciE 'Check 6\.2|Domain-C'` → 3 | PASS |
| AC-3 (surviving guarantee stated explicitly) | Decision §5 "The surviving guarantee": **"rebuild is identical" survives, now unqualified; "audit trail" is retired as an index claim**, with the honest residual stated (per-transition history recorded nowhere until the re-open conditions hold). Method probe: `grep -ciE 'surviving guarantee'` → 1 | PASS |
| Entry condition 10 (Check 6.2 predicate repair — binding, scope-lock) | Repair path **(a)** selected and recorded: closed two-member approval-class vocabulary (`human-approval`, `human-re-validation`) bound one-to-one to the protocol's exhaustive two human edges into `published`; absent value = violation pinned on BOTH evaluation substrates (frontmatter read AND SQL NULL); fixture disposition = reconcile the two committed `published`+`retroactive-backfill` fixtures in the delivery child, NO grandfather clause (affected stock closed at 2 committed files, 0 live). Rejected forms recorded in ADR-173 Alternatives (P1 predicate-as-drafted, P3 UNVERIFIED-defer, P4 grandfather) | DISCHARGED |
| ADR numbering (CIAC-1 input) | `renumber-adr.py --detect` at the commit instant: `ANCHOR 172 origin/main / NEXT-FREE 173 / CLAIMED-SET-BRANCH-ONLY 173,174,175,176 (never binds) / CLAIM NONE` for this tree → union = mainline anchor alone → allocated **ADR-173**; post-write re-run reports `CLAIM ADR-173 … BINDS`. Numbering-provenance block recorded in the record's Status section | PASS |
| Durability lint (governed check, with control arm) | `check-adr-durability.py --files core/ADRs/ADR-173-… --diff-base origin/main` → `COUNT 0` (R5 net-new structural rule ACTIVE); control arm — `## Reversibility` heading temporarily broken → `R5-NEW` fired, `COUNT 1`, exit 1 — instrument verified live, then restored and re-run green | PASS |
| Consumer fan-out reproduction (probe integrity) | Independent python3 walk at this branch tip: 5 files / 28 reference lines (29 token occurrences — the schema invocation-table row carries the token twice) over denominator 1,538; sensitivity arm `lifecycle_state` → 105 files; specificity arm fabricated token → 0; ADR-home ownership probe 0/174 with control fired | PASS |

**Artifact-Acceptance Record (deliverable_state: `artifact-accepted`):**

| Deliverable | Declared canonical path | Acceptance evidence |
|---|---|---|
| Lifecycle audit-trail carrier decision record (#5838, task-class) | `core/ADRs/ADR-173-lifecycle-audit-trail-carrier-or-retirement.md` (this branch) | The record itself (durability lint COUNT 0 with fired control arm; AC method probes above; status `Proposed` pending Stage 9 ratification) + #6663 Stage-6 comment |
