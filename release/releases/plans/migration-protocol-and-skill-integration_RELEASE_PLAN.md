---
title: Release Plan — migration-protocol-and-skill-integration
purpose: Stage-4 release plan for the skill/protocol half of the operational-folder enforcement bundle.
type: release-plan
status: ACTIVE
reversibility: MODERATE / Confidence HIGH
consumers: Stage 5-9 spokes; the release hub; Stage 9 Plan Review
---
<!-- reference-durability: allow-link -->

# Release Plan — `migration-protocol-and-skill-integration`

## Header

| Field | Value |
|---|---|
| Milestone | `migration-protocol-and-skill-integration` |
| Version | **Not claimed.** Rule-computed at Stage 12 per `claim-version.sh`. Sequenced behind `operational-folder-enforcement-and-migration` per **D-38**, so the next-free value is not determinable at planning time. **`v4.36` has since been claimed by milestone #346** (the concurrent release, merged to `main` while this branch was in flight) — this release therefore resolves to **next-free at its own Stage-12 claim** per **ADR-092**. No version is pinned here, and none is owed before Stage 12. |
| Release Class | `novel` — `class_weight` 1.15 (`core/config/platform-config.toml.template` `[bundling].release_class_capacity_weights`) |
| Raw points | **22** — #153 M=4 · #5659 M=4 · #5660 S=2 · #158 L=8 · #5671 M=4 |
| `effective_pts` | **25** — `round_half_up(22 × 1.15)`. In band (15–25), **at the ceiling, zero headroom**. No override required. |
| Branch topology | **SINGLE** — one branch, one PR, one merge gate |
| Concurrency | Stage 6 **fully serial** — three cards claim `operations/skills/project-initiator/SKILL.md` |
| Baseline | `origin/main` @ `e4052fec` |
| Provenance | Split from `operational-folder-enforcement-and-migration` at Stage 5 exit, operator decision **D-37** |

## Scope

**Outcome.** The migration-enforcement protocol becomes a written artifact with computable telemetry; `project-initiator` registers a scaffolded project as a routing target, copies its bin orientation cards, drains the unsorted hold before archive, and gains a migration mode; `health-check` gains a `structure` mode that scores entity completeness and escalates a stalled migration by name with a remediation link.

**Out of scope.** The corpus half — classifier legacy-only repair, the node-frontmatter backfill, and entity-record seeding — ships in `operational-folder-enforcement-and-migration`. CIAC-1 (#5668 × #3123) belongs to that milestone and is not graded here.

## Card Labels

| Card | Size | Type | Cluster |
|---|---|---|---|
| #153 | `size:M` | `type:task` | `cluster: process-protocol` |
| #5659 | `size:M` | `type:task` | `cluster: process-protocol` |
| #5660 | `size:S` | `type:task` | `cluster: documentation` |
| #158 | `size:L` | `type:story` | `cluster: skill-modes` |
| #5671 | `size:M` | `type:task` | `cluster: process-protocol` |

`#5671`'s `size:M` is confirmed against the Stage-5 ROUND-3 measurement (Mode D at 168 lines; the design states "`size:M` holds"). `#158`'s `size:L` is a Stage-5 measurement correction from `size:M`, already reflected on the label.

## Dependency Graph

```
#153 ──────────────┐
                   ├──> #5671   (protocol is #5671's input contract)
#158 ──────────────┤
#5659 ──> #5660 ───┘

External, BLOCKING:
  milestone operational-folder-enforcement-and-migration
    └── #5741 (seed entity records) ──> #158 AC-3
```

**Internal order:** `#153` → `#5659` → `#5660` → `#158` → `#5671`. Acyclic. `#158`'s own blocker `#1125` is CLOSED.

**External blocker — D-38.** `#158`'s completeness score reads entity records that do not exist: `entity_type:` returns **0 files** across the live operations corpus (control arm: `project_id:` → 9 files; 1,395 files carry frontmatter). `#5741` seeds them and is OPEN in `operational-folder-enforcement-and-migration`. **That milestone deploys first.** This release does not enter Engineering until it does.

## Implementation Sequence

Single branch, serial commits, in dependency order.

| Commit | Card | Deliverable |
|---|---|---|
| 0 | — | Branch cut; contention sweep re-run; **D-R2 rebuild ownership assigned**; **`D-5659-OPTION` resolved** and its conditional rows promoted |
| 1 | #153 | The protocol document with `MM-0`–`MM-3` |
| 2 | #5659 | Routing-target registration + pre-archive drain |
| 3 | #5660 | Bin orientation card copy + `TEMPLATE_SYNC_MAP` registration |
| 4 | #158 | `structure` mode + reference doc + eval set |
| 5 | #5671 | Mode D + stalled-migration escalation |
| 6 | — | Single coordinated `version:` bump + package rebuild (owner assigned at Commit 0) |

## File Change Matrix

Path-first columnar form with explicit intent verbs per the FCM authoring contract. A marker-less path is `unknown`, never `edit` — every row below carries a verb.

```
# ── #153 — migration-enforcement protocol ──
core/standards/migration-enforcement-protocol.md                          add

# ── #5659 — intake wiring (both options) ──
operations/skills/project-initiator/SKILL.md                              edit
operations/templates/project-md-composed-index-template.md                edit
core/schemas/project-schema.md                                            edit

# ── #5659 — CONDITIONAL:D-5659-OPTION (Option 2 only; both or neither) ──
operations/skills/file-router/SKILL.md                                    edit    CONDITIONAL:D-5659-OPTION
core/schemas/routing-rules.md                                             edit    CONDITIONAL:D-5659-OPTION
packages/file-router.skill                                                edit    CONDITIONAL:D-5659-OPTION
packages/file-router.skill.sha256                                         edit    CONDITIONAL:D-5659-OPTION

# ── #5660 — bin orientation cards ──
core/deploy/deploy.sh                                                     edit
core/standards/template-storage.md                                        edit
core/deploy/tests/test_resolve_canonical_source.sh                        edit

# ── #158 — health-check structure mode ──
operations/skills/health-check/references/structure-mode.md               add
operations/skills/health-check/SKILL.md                                   edit
operations/skills/health-check/references/mode-intents.md                 edit
operations/skills/health-check/evals/judges/structure.md                  add
operations/skills/health-check/evals/cases/structure-missing-entity.yaml  add
operations/skills/health-check/evals/cases/structure-empty-required-field.yaml  add
operations/skills/health-check/evals/cases/structure-broken-relationship.yaml   add
operations/skills/health-check/evals/evals.json                           edit
operations/skills/health-check/evals/README.md                            edit
operations/skills/health-check/evals/fixtures/hypercare-window.md         edit

# ── #158 — CONDITIONAL:D-158-ADR (number allocated via adr-helper; never hardcoded) ──
core/ADRs/ADR-*.md                                                        add     CONDITIONAL:D-158-ADR

# ── #5671 — migration mode + escalation ──
docs/module-apis.md                                                       edit

# ── Package rebuilds (tool-generated; owner assigned at Commit 0 per D-R2) ──
packages/health-check.skill                                               edit
packages/health-check.skill.sha256                                        edit
packages/project-initiator.skill                                          edit
packages/project-initiator.skill.sha256                                   edit

#### Read-only inputs
core/ADRs/ADR-060-project-md-composed-index.md                            READ
core/ADRs/ADR-080-project-folder-taxonomy-closed-5-bin-set.md             READ
core/schemas/entity-field-schemas.md                                      READ
core/specs/health-check-specification.md                                  READ
operations/templates/project-md-template.md                               READ
operations/templates/project-bins/_inbox/README.md                        READ

#### Release-wide explicit non-scope
operations/skills/weekly-status-rollup/SKILL.md                           NOT EDITED
operations/skills/project-initiator/references/scaffold-output-verification.md  NOT EDITED
core/deploy/lib-template-sync-source.sh                                   NOT EDITED
operations/templates/project-bins/                                        NOT EDITED
operations/skills/pmo-technical-analyst/SKILL.md                          NOT EDITED
operations/skills/ppm-agent/SKILL.md                                      NOT EDITED
operations/skills/daily-status/SKILL.md                                   NOT EDITED
```

**Shared-file note.** `operations/skills/project-initiator/SKILL.md` appears once as an obligation but is written by **three** cards (#5659, #5660, #5671). See the Contention Map. The last three non-scope rows are the ADR-060 reader-cascade surfaces identified at Phase A6.5; they are named here so their absence from the diff reads as a recorded decision rather than an oversight.

**Conditional-promotion rule.** `D-5659-OPTION` and `D-158-ADR` resolve at or before Engineering Commit 0. A row left CONDITIONAL after its condition has fired is an authoring defect — promote it in the same commit, carrying its concrete path.

**⚠️ The automated FCM check reads only part of this matrix — bug #5757.** `verify-release-plan.sh`'s `pathof()` matches declared paths against a closed prefix allowlist (`core|release|docs|packages|projects|roadmaps|.github|.claude`) that **omits `operations/`**. Every `operations/` row below is dropped before classification, and dropped rows are not counted as `uninterpreted` — so the checker reports `declared=19 uninterpreted=0 pathless=0` and **PASS** while 21 of this matrix's 40 path rows are invisible to it, including 5 of its 6 unconditional ADDs. Measured on this plan; the reconciliation is exact (19 parsed = the non-`operations/` rows).

**Consequence for Stage 9.** **G-PR11's `fcm-delivery` verdict on this release is partial, not clean.** It cannot detect a declared-but-undelivered `operations/` file, which is where every skill edit in this release lands. Until #5757 ships, the `operations/` rows must be graded by **direct diff inspection** against this matrix rather than by the checker's verdict. Treating a `fcm-delivery` PASS as full coverage here would be a false green.

## Contention Map

| File | Claimants | Order | Resolution |
|---|---|---|---|
| `operations/skills/project-initiator/SKILL.md` | #5659, #5660, #5671 | 2 → 3 → 5 | **Fully serial.** One `version:` bump and one package rebuild in the last writer. **Ownership is D-R2 and is currently unassigned — assign at Commit 0.** |
| `operations/skills/health-check/evals/judges/structure.md` | #158 (add), #5671 (edit) | 4 → 5 | Serial; #5671 appends to #158's landed file |
| `operations/skills/health-check/references/structure-mode.md` | #158 (add), #5671 (edit) | 4 → 5 | Serial; #5671 fills the reserved emission seam |
| `packages/*.skill` | #5660, #158, #5671 | Commit 6 | One rebuild per skill, after the last source edit |

## Integration Points

| # | Seam | Cards | Contract |
|---|---|---|---|
| INT-1 | `MM-0` composite consumed by the `structure` mode | #153 → #158 | #153 defines `MM-0`–`MM-3`; the mode computes them. **Recorded UNVERIFIED at Stage 5** — the consuming rule does not exist until #158 lands |
| INT-2 | Stalled-migration FAIL emitted through the `structure` mode | #5671 → #158 | #5671 fills a reserved seam in #158's reference doc |
| INT-3 | Mode D composes the `structure` mode for measurement | #5671 → #158 | ADR-019 compose seam; Mode D derives no metric |
| INT-4 | Entity records seeded before the score is meaningful | **#5741 (external)** → #158 | **BLOCKING.** Governed by D-38 |

## Cross-Issue Acceptance Criteria

Four cohesion constraints spanning two or more cards, graded at Stage 9 on the merged PR. CIAC-1 belongs to the corpus milestone and is not graded here.

- [ ] **CIAC-2 (#5659 × #5660 × #5671 — the serial-write invariant):** `operations/skills/project-initiator/SKILL.md` carries exactly **one** `version:` value in the merged state, and the `project-initiator` package hash matches its source. *Method:* file inspection of the final combined state — read the `version:` field and assert a single value; run the deploy package-freshness check for `project-initiator` and assert FRESH. Control arm: the same hash probe against an unrebuilt package returns STALE. **Graded by file inspection, not by a scaffold run** — no executor runs LLM-interpreted `SKILL.md` prose.
- [ ] **CIAC-3a (#153 × #158 — the identifier family):** #153 **defines** the `MM-*` metric identifiers and #158 **cites** them; neither mints a competing family. *Method:* extract every `MM-[0-9]` token from both deliverables; assert the sets are equal and non-empty. Control arm: a nonsense prefix (`ZZQ-[0-9]`) returns zero over the same population.
- [ ] **CIAC-3b (#5671 × #153 — bidirectional metric co-occurrence):** every telemetry metric defined by #153's protocol is computable by the `structure` mode, **and** the mode defines no metric the protocol does not specify. *Method:* verbatim-citation match for each `MM-*` token across both files; **co-occurrence required in both directions**. A one-directional pass is a FAIL.
- [ ] **CIAC-4 (#5660 × #153 — the back-fill boundary):** #5660's card copy applies to newly scaffolded projects only and does not pre-empt the existing-project migration #153 governs. *Method:* assert #5660's deliverable contains no back-fill step, and that #153's protocol is the sole home of the existing-project deadline.

## Verification Plan

| Family | Check | Applies to | AC → method |
|---|---|---|---|
| Per-issue | Each card's own acceptance criteria graded at Stage 8 | all five | per card |
| Integration | The four cross-issue criteria above | cross-cutting | CIAC-2/3a/3b/4 |
| Regression | `pmo-skill-editor` regression pass, run **once against the final combined state** of `project-initiator/SKILL.md`, not per-card intermediates | #5659, #5660, #5671 | #5671 AC-5 |
| Regression | Existing `health-check` modes still pass after the edit | #158, #5671 | #158 AC-7 |
| Regression | The deploy check suite green, including package freshness and byte-identity | all | — |
| Sync | Deployed skill copies re-synced where the change edits a mirrored surface | Commit 6 | — |
| Runtime suite | The health-check eval suite, including the three new `structure` cases | #158 | #158 AC-6 |

**Gate-coverage caveat, stated rather than implied.** Two of this release's guarantees have **no merge-time gate**. `.github/skill-package-freshness.enforce` carries the token `warn`, so a stale package merges green and fails at deploy time. The deploy CI required-subset enumerates **Check 38 only**, so the byte-identity verdict does not gate CI either. Both fire after merge. #5660's correctness depends on the package rebuild, so **the rebuild-and-diff must be executed in the PR** rather than deferred to the gates — grading AC-1/AC-2 against a gate that does not fire would be a false pass.

## Risk Register

| # | Risk | Owner | Mitigation | Reversibility |
|---|---|---|---|---|
| R1 | Package rebuild unowned — #5660 declares it correctness-critical, #5671 withdrew "I am last" (D-R2), #5659 never engaged | hub | Assign at Commit 0; execute rebuild-and-diff in the PR | CHEAP |
| R2 | `D-5659-OPTION` unresolved — the ADR-060 reader cascade is 5+ readers, not the 2-file mirror pair, so both options are mis-costed | operator | Re-cost against the real population before Commit 0; conditional rows gate the FCM | CHEAP |
| R3 | #5671's Mode D snapshot destination contradicts **ADR-060 `:51`/`:55` (Accepted)** and `project-schema.md:570` (§7 M1) — which Mode D's own D5 cites as authority | operator | ADR-060 amendment as an in-release deliverable, or a signed exception with an expiry | MODERATE |
| R4 | #158's X1/X2 findings against #5741's `= Axis-1` discriminator were never routed to #5741 or #5742 (0 signal on both). D-38 makes 251 ship first, so the defect would ship and #158 would inherit it | hub | Route to #5742 before that milestone's Collective Review | CHEAP now, EXPENSIVE after 251 merges |
| R5 | Zero band headroom — `effective_pts` 25 is exactly the ceiling; any Stage-6 re-size breaches | hub | Re-size triggers a re-bundle decision, not a silent override | CHEAP |
| R6 | Invoking Mode D against a live project relocates operator files on a tree with no git history | operator | Pre-migration snapshot is the rollback path; operator gate before the first move | **EXPENSIVE** |

## Delivery Strategy

Single branch, one PR, one merge gate. Stage 6 fully serial. Stages 5, 7, 8 are parallel-eligible per card; Stages 6 and 13 are write-serialized. Stages 10 and 11 are **compressed** for git-native releases — the git history is the snapshot and the PR diff is the dry run — and their sub-tasks are created then immediately closed so the rationale has a durable home.

## Stage Applicability Matrix

| Stage | Applies | Note |
|---|---|---|
| 4 Planning | ✅ | this document |
| 5 Solutioning | ✅ | complete for all five; A6.5 re-reviewed 2026-08-21 |
| 6 Engineering | ✅ | fully serial |
| 7 Dev Testing | ✅ | parallel-eligible ×5 |
| 8 QA Testing | ✅ | parallel-eligible ×5 |
| 9 Plan Review | ✅ | **Deep** review depth per `novel` class |
| 10 Dry Run | ⏭️ | compressed — PR diff is the dry run |
| 11 Snapshot | ⏭️ | compressed — git history is the snapshot |
| 12 Execute | ✅ | version claimed here |
| 13 Close | ✅ | 30-day outcome window per `novel` class |

## Quota Budget

**Verdict:** PASS (per `quota-budget-protocol.md` Checkpoint A)
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: 0 (complete) · Stage 7: 5 · Stage 8: 5

Stage 6 is serial, so its five commits draw sequentially rather than concurrently. The gate is re-rendered before **every** launch — wave or singleton — per the spoke-launch contract.

## Rollback Strategy

### Per-Issue Rollback

Every authored file is git-tracked; each card's commit is revertible in isolation, in reverse dependency order (#5671 → #158 → #5660 → #5659 → #153). Package artifacts are regenerated, not hand-edited, so a revert plus a package rebuild restores them.

### Whole-Release Rollback

Revert the merge commit. Reversibility **MODERATE · confidence HIGH** for the release itself.

**Asymmetry, stated.** The release is CHEAP-to-MODERATE to reverse. The *capability* it ships is not: invoking Mode D against a live project is **EXPENSIVE**, and its rollback path is the pre-migration snapshot plus the manifest replay, not a git revert. That asymmetry is the point and is recorded on #5671.

## Operator Decisions Recorded

| # | Decision | Verdict | Reversibility |
|---|---|---|---|
| D-37 | Bundle split at Stage 5 exit | Skill/protocol half separated from the corpus half | MODERATE · HIGH |
| D-38 | Sequencing vs the corpus milestone | **Corpus milestone ships first.** Declined: restating #158 AC-3 against a fixture; shipping a known-zero score; re-homing #158 (would break CIAC-3a/3b) | MODERATE · HIGH |
| D-2 | #153 split | Protocol retained on #153; skill integrations to #5671 | CHEAP · HIGH |
| D-6 | Completeness-score population | Entity-record population, not the file population | CHEAP · HIGH |
| D-8 | #158 AC-5 surface | The skill's own mode-selection surface, not the deleted orphan command file | CHEAP · HIGH |
| D-14 | Package rebuild | Required; CI gate ships `warn`, so green CI is not evidence | CHEAP · HIGH |
| D-23 | #5659 ships writer-only | AC-1 restated to grade the writer-side deliverable | CHEAP · MEDIUM |
| D-24 | #5660 target path form | Repo-relative canonical target per ratified **ADR-104** | CHEAP · HIGH |
| D-27 | Project Axis-1 carrier | `status`, not `lifecycle_state`; amendable in-file | CHEAP · HIGH |
| D-R2 | `project-initiator` rebuild ownership | **RESOLVED by D-42** — rule-determined to the last writer, not assigned by hand | CHEAP · HIGH |
| D-5659-OPTION | Reader-cascade scope | **RESOLVED by D-39** — no reader cascade; B1 is a documentation reconciliation with zero live edit targets | CHEAP · MEDIUM |

## Decisions of Record — this release (D-39 … D-49)

The rows above are the decisions carried **into** this release from planning. The rows below are the
decisions rendered **during** it, at Stages 5–9. They are recorded here because the release plan is the
surface a spoke greps: a decision that exists only in the pipeline event log and in issue comments is,
from inside a spoke, indistinguishable from a decision that was never made. That failure has already
occurred once on this release — a spoke told a conflict was "known-open per D-48" searched the plan,
found nothing, and correctly reported the decision non-existent. This section closes that gap.

| # | Decision |
|---|---|
| **D-39** | B1 resolves as a **documentation reconciliation**, not a reader-cascade repair. `## Key People` is a **ratified retained fallback** (ADR-025 § 5), so there are **zero live edit targets** and no cascade is owed. Supersedes the open D-5659-OPTION. |
| **D-40** | B3 is **falsified**. The `= Axis-1` discriminator and the § 3.6 RAID Item exemplar **shipped in v4.35**; `V-CORE-03` reaches **19 of 19**. No routing work is owed. |
| **D-41** | B4's defect is **real**, but the remedy is the **already-shipped workspace-root snapshot convention**, not a signed exception. Carries an **ADR-060 supersession note**. |
| **D-42** | Package-rebuild ownership is **rule-determined to the last writer** (#5671) rather than assigned by hand. Lifecycle **Check 7 is always-enforce**, not warn-only. Resolves the open D-R2. |
| **D-43** | B5 is **partly falsified**. The CI gate **does** exit non-zero; Check 7's absence from the required subset is **by design** — it runs on a dedicated CI mirror. |
| **D-44** | #5660's hook-blocked `SKILL.md` Step 2c **folds into #5671's combined edit**, per the v4.35 precedent. **No sentinel was minted** for it. |
| **D-45** | The coordinated rebuild set is extended from **1 package to 6** — the `template-storage.md` mirror consumers. |
| **D-46** | #158 is **unblocked**: #5815 reached terminal state and the Layer-2 corpus write landed, so the completeness score now measures a **real population** rather than an empty one. |
| **D-47** | **Amends D-45** — the rebuild set is **7, not 6**. `health-check` is **not** a `template-storage.md` mirror consumer; it was staled independently and must be rebuilt on its own basis. |
| **D-48** | The **`MM-3` semantic conflict** resolves in favour of the **protocol as definitional home**, per **CIAC-3a**: `MM-3` is **Composed-Index Conformance, a per-project state** (`composed` / `partial` / `monolith`) — **not** a link ratio and **not** "relationships valid". Every downstream surface cites; none redefines. |
| **D-49** | **Split-debt repaired.** All **10** Stage 7/8 sub-tasks carried pre-D-37 **parent-milestone metadata** (wrong milestone, wrong plan path, wrong Stage-4 pointer). Corrected and **read-back verified**. |

## Deviation Log

| Path or token | Status | Basis |
|---|---|---|
| *(none yet — populated at Engineering)* | — | A declared ADD that legitimately does not ship requires a row here carrying the literal `NOT DELIVERED` and the declared path |
