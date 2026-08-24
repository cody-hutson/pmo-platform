---
title: Release Plan — release-identity-and-plan-lifecycle
purpose: Stage-4 release plan for the nine identity-and-lifecycle defects — a release plan's identity and lifecycle state are inconsistent from claim through close, and the instruments that verify them measure a version-shaped subset.
type: release-plan
plan_type: release
status: ACTIVE
reversibility: MODERATE / Confidence HIGH
consumers: Stage 5-9 spokes; the release hub; Stage 9 Plan Review
---
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->

# Release Plan: release-identity-and-plan-lifecycle — A Plan's Identity and Lifecycle State Stay Consistent From Claim Through Close

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination. The concrete number binds only at the Stage-12 atomic claim (ADR-092). Recomputed at Engineering Commit 0 per the authoritative-version-selection procedure against tags, published Releases, ledger rows, and in-flight sibling holds; anchor **v4.38**. |
| **Date Created** | 2026-08-24 (Monday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/release-identity-and-plan-lifecycle` |
| **PR** | not yet opened — the release ships as a SINGLE PR with one merge gate; opened after the last Engineering spoke |
| **Milestone** | `release-identity-and-plan-lifecycle` (#343) |
| **Release Class** | `cross-cutting` — re-classified from `routine` at the Stage-4 D1 gate (2026-08-23, Sunday) |
| **Composition** | capability-slice; Frame F1 (SAFe Feature-Slicing + Vertical Slice) |
| **Effective points** | **24** across 9 issues — 25 at bundling, less 1 after #4445 was re-scoped 2 → 1 pt at D2. One point of headroom below the 25-pt band ceiling. |
| **Branch topology** | **SINGLE** — one branch, one PR, one merge gate; this plan lands as Engineering Commit 0 |
| **Concurrency posture** | **P0 fully-serial** — undeclared at the Stage-4 D-Gate, so the rule default applies; Stage 4 independently recommended P0 on the contention map. Force-push on the shared release branch is prohibited, including `--force-with-lease`. |
| **Baseline** | `origin/main` @ `8dc00db1` — fetched at Engineering Commit 0; identical to the Stage-4 and Stage-5 pins, so no re-baseline was required |

## Release Outcome Statement

**AFTER** this release: A release plan's identity and lifecycle state are consistent from claim through close, and the instruments that verify them see every release rather than a version-shaped subset.

**BEFORE:** Plan files carry two naming conventions; no plan in the corpus has ever carried a terminal status. Of **178** plan files, **32** carry a frontmatter `status:` field and **all 32 read `ACTIVE`** — the frontmatter enum has exactly one live value, and no terminal value is defined. A 33rd file, `release/releases/plans/v3.83_RELEASE_PLAN.md`, carries `Status: operator-APPROVED` as a **body prose line, not frontmatter**. Three status surfaces exist — the frontmatter field (32 files), a body `**Status**` row (36 files, 12 free-prose values), and the `RELEASE_LOG` `State` column — with 22 files carrying two of them in disagreement. Five close-out enumerators and one plan verifier each measure something narrower than they report.

*Amended 2026-08-23 (Sunday):* the original BEFORE named a claim-state oracle as a third defect surface. That limb is historical — the oracle was re-based on `{{RELEASE_VERSION}}` token-presence by #5063 in `plan-file-identity-adr-092`. #4445 is retained here re-scoped to the residual gate-efficacy register row; the oracle's remaining 1-dimensionality is owned by open #5468 in `plan-authoring-contract-and-claim-state`.

## Scope

### Issues Included

| # | Issue | Title (abbreviated) | Layer | Size | Stage 5 |
|---|-------|---------------------|-------|------|---------|
| 1 | #4562 | A7-T4 / stage-04 Phase A0 phantom tool citation | foundation | XS (1) | APPLIED (conditional → activated) |
| 2 | #4749 | plan-file naming convention + ADR-092 ratification | foundation | S (2) | APPLIED |
| 3 | #5549 | terminal plan `status:` value + close-out transition | foundation | M (4) | APPLIED |
| 4 | #5234 | five version-anchored `RELEASE_LOG` enumerators | infrastructure | M (4) | APPLIED |
| 5 | #4445 | Check 59 gate-efficacy register row (re-scoped) | infrastructure | S (1) | SKIP-where-trivial |
| 6 | #4713 | `verify-release-plan.sh` field splitting + CIAC counter | infrastructure | S (2) | APPLIED (light) |
| 7 | #4218 | residual version-keyed event-log read sites | infrastructure | M (4) | APPLIED |
| 8 | #5092 | bind plan verification-method rows to the AC they test | eval / verification | M (4) | APPLIED |
| 9 | #4563 | `release-planner` SKILL.md gate enumeration | skill-core | S (2) | SKIP-where-trivial |

Effective scope is **9 members / 24 pts**. Stages 7 and 8 apply to **9 of 9** — no card qualifies for the no-functional-impact skip.

### Composition Lock

**Locked at:** Stage 4 Planning entry · 2026-08-23 (Sunday) · planning sub-task #5953

### Scope Lock

**Locked at:** Stage 5 Collective Review · 2026-08-24 (Monday) · all nine Solutioning sub-tasks resolved

Collective Review ran the six protocol steps over the nine Solutioning outputs. Cross-issue dependencies: all seven edges resolved. Design conflicts: five contended surfaces, every one measured disjoint rather than asserted. Cumulative risk: the Stage-4 top risk collapsed — seven of nine cards carry an empty `core/deploy/deploy.sh` edit set, and the two that touch it have a proven-empty interval intersection re-anchored independently with a live control arm. Scope: 24 pts / 9 issues, unchanged across sixteen decisions, with roughly thirty findings routed out of scope rather than absorbed.

**Additions to the bundle are FORBIDDEN from this point (hard lock); removals require a governed override.**

**N-way consistency — six rows read `disagreement`, all overridden**, each because the divergence *is* the defect this release repairs: the `G-PL` gate enumeration (repaired by #4563); the plan `status:` surfaces (#5549); the event-log release join key (#4218); the AC identifier form (#5092); the check-mode committed default (folded into #4218 at the Stage-5 D13 gate); and the plan-file naming authority, resolved to `RELEASE_PROTOCOL.md` § Versioning at the Stage-5 D6 gate (#4749). Each deviation is logged for the Stage 13 retrospective.

**Protocol step 5 — cross-D upstream-compatibility scan — recorded NOT-RUN, not clean.** The scan aggregates each D-decision's `Upstream compatibility` subsection from the D-Gate template. This release rendered its sixteen decisions as consolidated Decision Briefings with structured operator prompts rather than through the formal D-Gate template, so no such subsection exists to aggregate. Per the protocol's own words a missing subsection is a structural defect, and it is reported as one. Routed to next intake.

**ADR-092 RATIFIED at this gate (D15)** — `Proposed` → `Accepted`. Its original ratifying release closed on 2026-07-25 without putting the flip on its agenda, and because the close gate is release-scoped by design no later release owned the escaped promise. The Stage-5 Solutioning pass declined to backdate a ratification the record does not evidence and re-anchored the promise here. The frontmatter edit itself lands in #4749's Stage-6 work, not as a hub write.

## Dependency Graph

Directional. `A → B` = B consumes A's output or must land after A.

```
#4562 ──────┬──────────────► #4563        (E1) corrected spec is #4563's AC3 diff target
            └──────────────► #5092        (E2) same file: stage-04-planning.md

#4749 ─────────────────────► #5549        (E3) identity premise + same file: release-corpus-schema.md

#5234 ─────► #4445 ────────► #4218        (E4,E5) deploy.sh serialization (file contention, not logic)

#4563 ─────────────────────► #5092        (E6) same file: release-planner/SKILL.md

#4713 ─────────────────────► #5092        (E7) a truthful plan verifier must exist before the
                                                AC→method binding it parses is graded
```

**Edge classification.** E1, E3, E7 are **logical** (downstream consumes upstream's semantics). E2, E4, E5, E6 are **file-contention serializations** — no logical dependency, ordered only to avoid concurrent edits to one file.

**Circular chains: zero.** The graph is a DAG, verified by topological sort over the seven edges.

**Cross-milestone edges (declared, none blocking).** This milestone **sequences after `plan-file-identity-adr-092`**, which owns the claim-time plan rename mechanism and its Check-59 token window; this milestone's identity and claim-state work reads against the post-fix state. The edge is `milestone-position(release-identity-and-plan-lifecycle) ≥ milestone-position(plan-file-identity-adr-092)` — the **conforming** direction under the cross-milestone dependency-sequence criterion, a declaration rather than a registered exception. That milestone is CLOSED (0 open / 40 resolved). Rationale, recorded because it is load-bearing: reconciling historical plan filenames ahead of the mechanism repairs the symptom while the mechanism keeps producing new instances, so the corpus re-drifts on the next close-out. Running this milestone first would be undone by the next close-out.

Coordination edges, none blocking: #4749 ↔ #4727 (ledger-vs-filename gate — this milestone confirms agreement, it does not re-implement); #4445 ↔ #5063 and ↔ #5468 (three views of one oracle, consolidated at Solutioning); #5092 ↔ #4762 (a fifth instance of the same drift class; `relates`, not `blocks`).

## Implementation Sequence

Layer-ordered per the bundle-composition doctrine § 9 (foundation → infrastructure → skill-core → eval/verification), with file-contention order applied within the infrastructure layer, and positions 8/9 swapped per D3 and re-based at the Stage-5 D11 gate.

| # | Issue | Layer | Pts | Why here |
|---|-------|-------|-----|----------|
| 1 | #4562 | foundation | 1 | Repairs the phantom `check-bundle-refresh.sh` citation in `release-process.md` § A7 T4 and `stage-04-planning.md` Phase A0. Anyone reading the planning spec downstream reads it first. Two independent outbound edges pin it first. |
| 2 | #4749 | foundation | 2 | Fixes the naming convention and ratifies its governing decision. Establishes the identity premise the status and claim-state work rests on. |
| 3 | #5549 | foundation | 4 | Defines the terminal `status:` value in `release-corpus-schema.md`, then sweeps the plans holding the field. The definition must exist before anything can transition to it. |
| 4 | #5234 | infrastructure | 4 | Widens the LOG-row selector across five `deploy.sh` enumerators. Lands first among the `deploy.sh` edits because it establishes the denominator the others report against. |
| 5 | #4445 | infrastructure | 1 | Adds the residual gate-efficacy register row. Second `deploy.sh`-layer card — serialized behind #5234 for file contention. Re-scoped 2 → 1 pt at D2; its filename-oracle premise was falsified against live state. |
| 6 | #4713 | infrastructure | 2 | Fixes `verify-release-plan.sh` field splitting and the CIAC counter. Independent file; ordered here so a truthful plan verifier exists before the AC→method binding it parses is graded (E7). |
| 7 | #4218 | infrastructure | 4 | Sweeps the residual version-keyed event-log read sites. Third `deploy.sh`-touching change — serialized last in the layer. |
| 8 | #5092 | eval / verification | 4 | Binds each plan verification-method row to the acceptance criterion it tests. `references/release-plan-template.md` sits inside `packages/release-planner.skill`, so this card's template edit changes the package hash on its own; #4563 at position 9 owns the single rebuild. This card does **not** rebuild. Edits `stage-04-planning.md` at lines 371-406. |
| 9 | #4563 | skill-core | 2 | Brings `release-planner` SKILL.md's gate enumeration to G-PL1…G-PL5 (the spec defines exactly five). **Owns the single package rebuild for the release**, performed once and last, discharging the double-rebuild exposure to the Check-7 package-drift class. Its enumeration is authored as a re-derivation command naming the definition lines, not a transcribed list, so a mover is detectable. |

**Sequence re-basing (recorded 2026-08-24, Monday, Stage-5 D11 gate).** The 8↔9 swap was originally argued on three grounds, and **all three were falsified by Solutioning**. Two — that #5092 and #4563 share `release/skills/release-planner/SKILL.md`, causing a double edit and a double package rebuild — died at Wave 1: #5092's issue body names that file zero times. The third and last, that #5092's edits would leave #4563's AC3 true-when-graded and stale-at-merge, died at Wave 3 on measurement: all 18 `G-PL` occurrences in `stage-04-planning.md` lie at lines 44-169, while #5092 edits 371-406. Zero overlap; #5092 cannot stale #4563's AC3.

The swap is **retained** on a ground neither the Stage-4 plan nor the D3 decision had in view: `references/release-plan-template.md` is a member of the release-planner package, so #5092's template edit changes the package hash regardless of the skill file. Ordering #4563 last lets one rebuild cover both cards. The #5092 and #4563 Solutioning spokes reached this conclusion independently, from opposite sides of the contention.

Recorded in full because a retired premise left in an authoritative artifact is a premise someone will build on.

## Stage Applicability Matrix

Default is all stages apply. Stage 5 skips only on triviality; Stages 7-8 skip only on no functional impact.

| Issue | S5 | S6 | S7 | S8 | S9 | S10-13 | Rationale |
|-------|----|----|----|----|----|--------|-----------|
| #4562 | APPLIED | ✅ | ✅ | ✅ | ✅ | ✅ | Filed CONDITIONAL on the D-4562 resolution fork. Activated: the fork was a structural design decision with ≥2 valid approaches, and Solutioning resolved it to a third candidate neither branch posed. |
| #4749 | APPLIED | ✅ | ✅ | ✅ | ✅ | ✅ | ADR-092 ratification + reconciling competing convention statements is a decision surface, not a mechanical edit. |
| #5549 | APPLIED | ✅ | ✅ | ✅ | ✅ | ✅ | The card defers a design question explicitly — the close-out path that should perform the transition was named at Solutioning. |
| #5234 | APPLIED | ✅ | ✅ | ✅ | ✅ | ✅ | Predicate design across five enumerators + the enumerate-vs-declare-excluded decision + where the rationale is recorded. |
| #4445 | SKIP-where-trivial | ✅ | ✅ | ✅ | ✅ | ✅ | Re-scoped at D2 to the residual gate-efficacy register row. |
| #4713 | APPLIED (light) | ✅ | ✅ | ✅ | ✅ | ✅ | Both defect mechanisms are known and concrete, but AC5 requires a regression fixture **executed by CI** — fixture placement + workflow wiring needs design. |
| #4218 | APPLIED | ✅ | ✅ | ✅ | ✅ | ✅ | Sweep scope + the intentional-vs-unconverted marking scheme is a design decision; `read-both` compatibility constrains it. |
| #5092 | APPLIED | ✅ | ✅ | ✅ | ✅ | ✅ | Three named candidate mechanisms with an argued recommendation — a genuine design decision. |
| #4563 | SKIP-where-trivial | ✅ | ✅ | ✅ | ✅ | ✅ | Add three gate IDs, cite-don't-restate. Genuinely mechanical. |

## Contention Map

### Within-release

| Path | Claims | Issues | Disposition |
|------|--------|--------|-------------|
| `core/deploy/deploy.sh` | **3×** | #5234, #4445, #4218 | **Serialize 5234 → 4445 → 4218.** No scope split needed — the three edit disjoint check blocks. At Scope Lock the three Solutioning outputs measured their intervals disjoint rather than asserting it. |
| `release/references/pipeline/stage-04-planning.md` | 2× | #4562, #5092 | Serialize 4562 → 5092. #4562 repairs a phantom citation at line 171; #5092 adds the AC→method binding obligation at lines 371-406. ~200 lines of separation; no shared hunk. |
| `release/references/standards/release-corpus-schema.md` | 2× | #4749, #5549 | Serialize 4749 → 5549. #4749 makes it the sole naming-convention home; #5549 adds the `status:` enum. **Same frontmatter-contract section** — highest genuine merge-conflict probability of the five. Graded by CIAC-1. |
| `release/skills/release-planner/SKILL.md` | 2× | #4563, #5092 | Resolved by the 8↔9 swap — a single edit and a single package rebuild, owned by #4563 at position 9. |
| `release/tools/automated-closeout.sh` | 2× | #5549, #4218 | Serialize 5549 → 4218. Disjoint concerns, same file. Graded by CIAC-5. |
| `release/governance/release-process.md` | 2× | #4562, #4749 | Serialize 4562 → 4749. #4562 edits the A7 T4 Mechanism cell; #4749 edits the canonical-home pointer. Disjoint regions. |

Contended paths: **6**. All serialized by the Implementation Sequence above.

### Cross-release

Three releases are in flight simultaneously. Measured from sibling milestone-member bodies and, where a sibling has branched, from its committed plan file.

| Shared surface | This release | `checks-see-whole-subject` | `selftests-actually-test` | Total |
|----------------|--------------|----------------------------|----------------------------|-------|
| **`core/deploy/deploy.sh`** | #5234, #4445, #4218 | #4992, #4931, #4734, #4440 | #5241 | **8 issues / 3 releases** |
| `core/standards/gate-efficacy-standard.md` | #4445 | #5252 | — | 2 issues / 2 releases |
| `release/tools/**` | #4713, #4218 | #5260, #5074 | #5238, #4913 | 6 issues / 3 releases (**disjoint basenames** — informational, not a collision) |
| `.github/workflows/**` | #4713 | #5252 | #5239 | 3 issues / 3 releases |

`core/deploy/deploy.sh` is a genuine `line-range-overlap` risk, not an `append-pattern` one — all eight edits modify existing check blocks in place. Per ADR-005 that retains the ADR-001 sequencing and scope-split mitigation guidance; it is not informational.

## File Change Matrix (machine-readable)

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-24, domain: governance }`

*Classification rationale:* the matrix is entirely internal platform artifacts — pipeline specs, standards, ADRs, deploy/release tooling, one skill. Dominant domain `governance`; secondary `software` (the shell and python surfaces). Sourcing-exempt per the pipeline-internal clause; **not** domain-exempt.

```
# ── #4562  A7-T4 / stage-04 Phase A0 phantom tool citation ──
release/governance/release-process.md                                  edit
release/references/pipeline/stage-04-planning.md                       edit

# ── #4749  plan-file naming convention + ADR-092 ratification ──
release/references/standards/release-corpus-schema.md                  edit
core/ADRs/ADR-092-plan-file-claim-time-stamping.md                     edit
release/governance/release-process.md                                  edit
release/references/how-to/hub-spoke-bridge.md                          edit  CONDITIONAL:canonical-location-reconcile

# ── #5549  terminal plan status value + close-out transition ──
release/references/standards/release-corpus-schema.md                  edit
release/releases/plans/**/*_RELEASE_PLAN.md                            edit
release/tools/automated-closeout.sh                                    edit
release/tools/tests/test_plan_status_terminal_transition.sh            add

# ── #5234  five version-anchored RELEASE_LOG enumerators ──
core/deploy/deploy.sh                                                  edit

# ── #4445  Check 59 gate-efficacy register row (re-scoped) ──
core/standards/gate-efficacy-standard.md                               edit

# ── #4713  verify-release-plan.sh field splitting + CIAC counter ──
release/tools/verify-release-plan.sh                                   edit
release/tools/tests/test_verify_release_plan_field_parity.sh           add
.github/workflows/release-tooling-smoke.yml                            edit

# ── #4218  residual version-keyed event-log read sites ──
core/deploy/deploy.sh                                                  edit
release/references/standards/pipeline-event-log-schema.md              edit
release/tools/append-pipeline-event.sh                                 edit
release/tools/query-pipeline-event.sh                                  edit
release/tools/compute-cycle-time.sh                                    edit
release/tools/synthesize-release-learnings.sh                          edit
release/tools/produce-learnings-register.sh                            edit
release/tools/reemit-release-bodies.sh                                 edit
release/tools/automated-closeout.sh                                    edit
release/references/pipeline/stage-12-execute.md                        edit  CONDITIONAL:read-site-not-narrative
release/references/pipeline/stage-13-close.md                          edit  CONDITIONAL:read-site-not-narrative

# ── #5092  bind plan verification-method rows to the AC they test ──
release/references/pipeline/stage-04-planning.md                       edit
release/references/pipeline/stage-09-plan-review.md                    edit
release/skills/release-planner/references/release-plan-template.md     edit
release/skills/release-planner/SKILL.md                                edit

# ── #4563  release-planner SKILL.md gate enumeration ──
release/skills/release-planner/SKILL.md                                edit
packages/release-planner.skill                                         edit
packages/release-planner.skill.sha256                                  edit
```

```
#### Read-only inputs
release/references/pipeline/stage-03-bundle.md                         READ
release/references/standards/quota-budget-protocol.md                  READ
core/schemas/gate-criteria-spec.md                                     READ
core/deploy/tools/check-approved-queue-depth.py                        READ
core/deploy/allowlists/selftest-coverage-manifest.txt                  READ
core/config/allowlists/script-execution-allowlist.txt                  READ
```

```
#### Release-wide explicit non-scope
release/releases/plans/v4/v4.07_RELEASE_PLAN.md                        NOT EDITED
```

`v4.07_RELEASE_PLAN.md:429` is the **third** `check-bundle-refresh` citation. It is a shipped release plan recording the finding as a Stage-5 observation — durable audit trail, not a live instruction. #4562's AC1 was amended at the Stage-5 D7 gate to carry an **instructional-citation scope predicate**: drop instructional citations, preserve audit-trail citations in `release/releases/plans/`, `release/releases/notes/`, and the release log. Editing a shipped plan to satisfy a grep would corrupt the record. Basis: ADR-012 § Decision item 5 (*baselined release plans are left unedited*) and `core/artifact-workflow-protocol.md:161` (*immutable release audit trail — never rewritten*).

**Two Stage-4 CONDITIONAL rows were DROPPED at Stage 5.** `release/tools/check-bundle-refresh.sh` (add) and `core/config/allowlists/script-execution-allowlist.txt` (edit) were both conditional on #4562 resolution (a); that candidate was eliminated on the blast-radius ceiling, so neither row exists. `core/deploy/deploy.sh` is **not** touched by #4562 — it is cited read-only.

## Risk Register

| ID | Risk | Sev | Reversibility | Owner-action / mitigation |
|----|------|-----|---------------|---------------------------|
| **R1** | **Cross-release `deploy.sh` contention.** Eight issues across three concurrent releases edit one file, all as in-place block edits. Whichever release merges second re-baselines. | **CRITICAL** → downgraded at Scope Lock | MODERATE | Seven of nine cards carry an empty `deploy.sh` edit set; the two that touch it have a proven-empty interval intersection re-anchored with a live control arm. Cross-release order is not in this release's gift. Re-validate at Stage 9 A6.5/A6.6. |
| **R2** | **#4445 premise falsified.** The claim-state oracle is token-based, not filename-based. | **HIGH** → discharged | CHEAP | Dispositioned at D2: retained, re-scoped to the register-row residual (2 → 1 pt), coordinating with #5468 rather than re-implementing it. |
| **R3** | **Version-slot contention.** Two siblings hold provisional `v4.39`; this release holds the next slot above it. Provisional until the Stage-12 atomic claim (ADR-092). | MEDIUM | CHEAP | Commit-0 re-verify recomputes next-free before the plan-file write and HALTs on collision. Exercised at Commit 0 — see § Deviation Log. |
| **R4** | **Within-release `deploy.sh` serialization** forces sequential Engineering steps in one layer; a defect in #5234's shared predicate blocks #4218. | MEDIUM | CHEAP | Serialize 5234 → 4445 → 4218. Land #5234's denominator change with its own DevTest gate before #4218 builds on it. |
| **R5** | **Cross-release contention is structurally unmeasurable from git at the Stage-4 baseline.** Zero open PRs; siblings unbranched. | **HIGH** → partially discharged | — | Two siblings have since branched and their Commit-0 plans are readable. Stage 9 Phase A6.6 renders the `CONTENTION-*` verdict against a fresh re-measure. |
| **R6** | **`release-corpus-schema.md` frontmatter-contract collision** (#4749 × #5549) — both edit the plan-file frontmatter section, not merely the same file. | MEDIUM | CHEAP | Serialize; consider a single Engineering spoke authoring both edits to that file. Graded by CIAC-1. |
| **R7** | **Reflexive-edit hazard:** #4562 and #5092 both edit `stage-04-planning.md` — the spec the Stage-4 spoke reads. A subsequent Stage-4 run reads a spec mutated mid-release. | LOW | CHEAP | No action; noted for Stage 9. The release does not re-enter Stage 4. |
| **R8** | **Skill-package drift (Check 7).** #4563 edits `release/skills/release-planner/SKILL.md` and #5092 edits a package-member template, each requiring `build-skill-packages.sh release-planner`. A missed rebuild is a known recurring Check-7 failure. | MEDIUM | CHEAP | The 8↔9 order collapses this to one rebuild, owned by #4563 at position 9. Assert Check 7 clean at Stage 7. `pmo-skill-editor` discipline applies to the SKILL.md edit. |
| **R9** | **Scope at band ceiling.** 24 pts against a 15-25 band, one point of headroom. Any scope growth fires the >25 split disposition. | MEDIUM | MODERATE | Scope Lock is a hard lock. Route discoveries to new cards. |
| **R10** | **ADR-092 ratification is unverifiable by the close-out check.** The ADR flip check is advisory-only and cannot fail by design. A green close-out is not evidence the flip landed. | MEDIUM | CHEAP | #4749's AC2 mandates the correct method — read the file, not a check result. Stage 8 reads `core/ADRs/ADR-092-…md` `status:` directly. Reads `Proposed` at baseline. |
| **R11** | **#5549 magnitude drift.** Filed as 167 plans / 23 field-carrying; at baseline 178 plans / 32 field-carrying / still 0 terminal. | LOW | CHEAP | Tier 1 [ADJUST] — restate the denominator at fix time. The card's AC already requires reporting the verified row count. |
| **R12** | **Line-number rot across cards.** Cited positions in issue bodies and Stage-5 specs are historical; `deploy.sh` and the pipeline specs have grown, and sibling cards move lines within this release. | MEDIUM | CHEAP | **Edit by marker or content, never by line number.** Every Engineering spoke locates its edit site by anchor text. |
| **R13** | **Rollback complexity is asymmetric.** `deploy.sh` *is* the platform's verification instrument. A defective edit does not merely fail — it blinds every subsequent check, including the ones that would detect the defect. | **HIGH** | MODERATE | Rollback is `git revert` of the release merge (CHEAP mechanically). The hazard is *detection*, not reversal: capture a full `deploy.sh --check` transcript **pre-merge** as the diff baseline, and re-run post-merge check-by-check. Graded by CIAC-2. |
| **R14** | **Quota:** worst parallel batch is 8-9 spokes (Stages 7/8) against an unstated envelope, and three releases share one usage window. | MEDIUM | CHEAP | Split the wide Stage 7/8 batches into two waves. Checkpoint B is the load-bearing gate at every launch. |

**Rollback strategy (release-level).** Single-branch topology → the release is one PR, one merge. Rollback = `git revert -m 1 <merge-sha>` — **CHEAP / HIGH confidence** mechanically. Two qualifications: R13 — the instrument-blinding class means detection, not reversal, is the binding constraint; and #5549's sweep touches many plan files, so a revert restores files whose `status:` was intentionally transitioned. Neither changes the tier.

## Quota Budget

**Verdict:** WARN. **Parallel-eligible spokes per parallel stage:** Stage 7: 9 · Stage 8: 9. **Per-spoke cost estimate:** size-bucket ordinal band — 1× `size:XS`, 4× `size:S`, 4× `size:M`; no `size:L` or `size:XL`, so the batch is wide but individually cheap. **Remaining usage-window envelope:** `UNSTATED` — no operator quota state was supplied. Per the refuse-to-synthesize rule, **no draw figure is rendered as a measurement**; the worst parallel batch is placed in a **50-80% band** as `[ASSUMPTION – CONFIRM]`, never `[SOURCE]`.

**Routing:** WARN → window-aware launch timing. **Split the 9-wide Stage 7 and Stage 8 batches into two waves.**

**Unmodeled additive draw — stated explicitly.** Checkpoint A models one release. Three releases share one per-account usage window. If the siblings fan out concurrently, true cumulative draw is roughly 3× this estimate, which would cross into FAIL. This is a real limitation of the plan-time estimate, not a hedge. **The load-bearing gate is Checkpoint B, not this estimate.**

## Cross-Issue Acceptance Criteria

Release-scoped cohesion predicates spanning ≥2 issues. Graded at Stage 9 on the merged PR.

- [ ] **CIAC-1 (#4749 × #5549 on `release/references/standards/release-corpus-schema.md`):** The plan-file frontmatter contract states **both** the naming-convention rule and the `status:` enum *including its terminal value* at that single home, and no second file restates either. *Method:* `python3` extraction of both sections from the schema, asserting non-empty; plus a repo-wide search over `git ls-files` for a competing convention statement returning only that home. **Sensitivity arm:** the pre-fix schema carries no terminal value → the extraction returns empty, so the post-fix non-empty is discriminating.

- [ ] **CIAC-2 (#5234 × #4218 × #4445 on `core/deploy/deploy.sh`):** After all `deploy.sh` edits in this release, `bash core/deploy/deploy.sh --check` runs to completion and introduces **zero new FAIL** relative to the pre-merge baseline transcript, and every check the set touches emits its denominator alongside its findings. *Method:* capture `deploy.sh --check` output pre-merge and post-merge; diff check-by-check. **Control:** the diff must be non-empty in the *expected* direction (the version-less rows now enumerated) — an identical transcript means #5234 changed nothing.

- [ ] **CIAC-3 (#4562 × #4563 × #5092 on the Stage-4 gate vocabulary):** The set of `G-PL<N>` identifiers named in `release/skills/release-planner/SKILL.md` is **exactly equal** to the set defined in `release/references/pipeline/stage-04-planning.md` — no gate in the spec absent from the skill, and none named in the skill absent from the spec. *Method:* `python3` regex-extract `G-PL[0-9]+` from both files into sets; assert equality. **Sensitivity arm:** at baseline the skill yields `{G-PL1, G-PL2}` and the spec yields `{G-PL1..G-PL5}` — unequal, so the probe detects. **This is the release's most valuable CIAC** — three issues edit these two files, and the sequence lets them drift apart *within* the release.

- [ ] **CIAC-4 (#5092 × #4713 on this release's own plan file):** Running the fixed `release/tools/verify-release-plan.sh` against **this release's own release plan** yields zero FAILs attributable to field-splitting or the CIAC counter, and every verification-method row carries the AC binding #5092 introduces. *Method:* run the verifier against this file; assert no pipe-induced field-count mismatch and a non-zero CIAC hit count. **Control:** this plan uses the escaped-pipe convention, so it is a true positive for the field-splitting defect — the pre-fix verifier must FAIL on it. **Reflexive by design:** the release's own plan is the fixture.

- [ ] **CIAC-5 (#5549 × #4218 on `release/tools/automated-closeout.sh`):** The close-out path performs the plan-status terminal transition **and** reads the event log by slug join key — the two independent edits to one script compose without either reverting the other. *Method:* read the script and assert both behaviors present; run its `--dry-run` and confirm both a status-transition action and a slug-keyed event read appear. **Specificity arm:** a historical version-keyed event-log row still resolves through the read path, so the slug conversion did not break backward resolution.

## Delivery Strategy

Single release branch `release/release-identity-and-plan-lifecycle` off `origin/main` @ `8dc00db1`. The plan file lands as **Engineering Commit 0**, before any card's commits. Each card commits in the Implementation Sequence order above, referencing its source issue number in the commit message body. **D-Concurrency Posture: P0 fully-serial** — one Engineering chip at a time; the next chip waits until the prior commit lands on the release branch. Force-push on the shared release branch is prohibited, including `--force-with-lease`.

The release ships as a **single PR with one merge gate**, opened after the last Engineering spoke and created in draft, transitioned to ready-for-review at the Stage 9 gate.

## Verification Plan

Per-issue: each card's own acceptance criteria, verified by the method the criterion names. Every claim of the form *zero occurrences* / *no findings* / *clean* carries a probe record — the invocation, the denominator, a sensitivity arm with a non-zero observed result, and a specificity arm where applicable. A zero whose control arm also returned zero is a broken probe, not a clean result.

Integration: `core/deploy/deploy.sh --check` for doc-link integrity on modified markdown (Check 14); Check 7 package freshness after the single `release-planner` rebuild at position 9.

Regression: the runtime suites mapped to the touched code paths, run under the `/tmp` `HOME`-override sandbox.

Cross-issue: the five CIAC methods above, run by the plan-verification executor as the sole runner of those methods.

## Rollback Strategy

Single-branch topology → one PR, one merge. Rollback is `git revert -m 1` on the release merge commit — CHEAP / HIGH confidence mechanically. The binding constraint is detection rather than reversal on the `deploy.sh` surface (R13): a defective edit to the platform's verification instrument blinds the checks that would detect it, which is why CIAC-2 requires a pre-merge baseline transcript diffed check-by-check post-merge.

## Operational Deployment Manifest

One deployed-copy propagation target: the `release-planner` skill package (`packages/release-planner.skill` + its `.sha256` content-baseline sidecar), rebuilt once at position 9 by #4563 and committed in the same PR. Every other surface is a governance document, a pipeline spec, an ADR, a repo tool, or a CI workflow — no Layer-2 propagation target. Confirm at Stage 12.

## Verification Evidence

Populated by each Engineering spoke as its card lands, and by the plan-verification executor at Stage 6 Phase C4.

## Hub-Rendered D-Decisions

| # | Decision | Verdict | Reversibility |
|---|----------|---------|---------------|
| D1 | Release Class | **`cross-cutting`** — re-classified from `routine`. Rule-determined: trigger (c), ≥3 in-bundle compositional edges, fires on both readings of the DAG (7 total edges; 3 logical after removing file-contention serializations). Multi-trigger resolution makes `cross-cutting` dominant. | CHEAP · HIGH |
| D2 | #4445 disposition | **Retain, re-scoped to the ~1 pt residual.** Premise falsified against live state: the claim-state oracle is token-presence based, not filename-based. The oracle residual is owned by open #5468 in another milestone. | MODERATE · HIGH |
| D3 | Implementation sequence | **Swap positions 8↔9** — #5092 before #4563. Accepted on the AC3-staleness limb; the double-edit and double-rebuild limbs were not supported. Re-based at D11 — see § Implementation Sequence. | CHEAP · MEDIUM |
| D4 | Plan approval | **Approved with two amendments** — add the required `## Parallelization Map`; amend the Outcome Statement BEFORE clause, whose claim-state-oracle limb is historical. | MODERATE · HIGH |
| D6 | Plan-file naming canonical home | **`RELEASE_PROTOCOL.md` § Versioning.** All five governed surfaces agree on the convention; what diverged was the canonical-home claim. | CHEAP · HIGH |
| D7 | #4562 AC1 scope + resolution | **AC1 amended with an instructional-citation scope predicate** (drop instructional, preserve audit-trail). **Resolution: a third candidate** — two surgical cell edits pointing A7 T4 at the mechanisms it already delegates to, citing `deploy.sh` Check 53. No new executable, no allowlist row, no CI wiring. | CHEAP to amend; IRREVERSIBLE if missed · HIGH |
| D11 | Sequence re-basing | **Swap retained on new evidence** — the template file is a release-planner package member, so one rebuild at position 9 covers both cards. All three original grounds falsified and recorded. | CHEAP · HIGH |
| D13 | Check-mode committed default | **Folded into #4218** as a two-file lockstep change. | CHEAP · MEDIUM |
| D14 | `release-process.md` gate enumeration | **Folded into #4563** — the second diverged surface joins the first. | CHEAP · MEDIUM |
| D15 | ADR-092 ratification | **RATIFIED** `Proposed` → `Accepted`, re-anchored here after its original ratifying release closed without the flip. The edit lands in #4749's Stage-6 work. | CHEAP · HIGH |
| D-Version | Version selection | **minor bump**; anchor `v4.38`. Next-free recomputed at Engineering Commit 0 against tags, published Releases, ledger rows, and in-flight sibling holds. The number binds only at the Stage-12 atomic claim. | CHEAP · HIGH |
| D-Concurrency | Concurrency posture | **P0 fully-serial** — undeclared at the D-Gate, so the rule default applies; independently recommended by Stage 4 on the contention map. Force-push prohibited on the shared branch, including `--force-with-lease`. | CHEAP · HIGH |

## Parallelization Map

**Verdict:** Tier-B soft-coupled — bidirectional scan. No blocking dependency outstanding; the material coupling is file contention on one high-traffic surface.

| Other milestone | Direction | Edge type | Confirmation |
|-----------------|-----------|-----------|--------------|
| `plan-file-identity-adr-092` | other-blocks-this | hard (DISCHARGED) | Milestone CLOSED, 0 open / 40 resolved. Sequencing precondition satisfied; plan against post-fix state. |
| `checks-see-whole-subject` | bidirectional | file-contention | Both milestones carry issues editing `core/deploy/deploy.sh` in place. Line-range-overlap class. Unbranched at Commit 0. |
| `selftests-actually-test` | bidirectional | file-contention | Same surface, same class. **Branched**, with a committed Commit-0 plan holding the slot below this release's. |
| `plan-authoring-contract-and-claim-state` | other-blocks-this | soft | #5468 owns the oracle residual #4445 was re-scoped away from. Informational; does not enter the dep graph. |
| `adr-corpus-status-integrity` | bidirectional | soft | #4762 is a further instance of the same drift class #5092 addresses. `relates`, not `blocks`. |

**Structural-blast-radius axis: DEFERRED, not cleared.** At the Stage-4 baseline no `git`-computable sibling edit-set existed to intersect. Two siblings have since branched; the intersection predicate is re-tested at Stage 9 Phase A6.6. A Tier-A "clean" verdict on this axis would be unsupported and is not claimed.

## Deviation Log

A deviation is flagged, never silently taken. Recorded per spoke as deviations arise.

**DEV-0 (Engineering Commit 0, position 1 spoke) — version-half re-verify, disclosed probe correction.** The Commit-0 recomputation was run twice. The first pass applied the GitHub/git reference mapping literally — tags ∪ published Releases ∪ ledger rows — and returned the slot immediately above the anchor as next-free. That pass was **broken and is discarded**: its specificity control arm (a version-shaped string that must be absent) returned present, because the ledger arm matched version-shaped substrings in ledger *prose* rather than parsing table rows, which also produced a nonsensical anchor two major versions above the live line. The second pass parses the ledger as a table and reads the Version column of `DEPLOYED`/`VERIFIED` rows only; its sensitivity arms fire and its specificity arms stay silent, and it returns anchor `v4.38`.

The corrected reference-mapping result still sat one slot below the planned version. The gap is resolved by the adapter contract itself: `repo-host-adapter-versioning.md` § 2.2 makes it **normative** that `claimed_set()` include in-flight claims — *"the held-but-unclaimed window is exactly where a naive implementation would miss a contender"* — while § 4's three-surface table is explicitly labelled a reference mapping and *"not part of the contract"*. A measurement of in-flight holds found the sibling release `selftests-actually-test` carrying a committed Engineering-Commit-0 plan that records the intervening slot as its own recomputed next-free. Including that in-flight hold, the recomputed next-free equals the planned version, both HALT conjuncts hold, and the version half returns **PROCEED**. Recorded because the intermediate result would otherwise read as an unexplained divergence.

## Change Description

Authored at Stage 6 Phase C1 once the implementation sequence has landed, and committed on the release branch before the PR is transitioned to ready-for-review at the Stage 9 gate.

## Issue References

Members of this release: #4562, #4749, #5549, #5234, #4445, #4713, #4218, #5092, #4563.

Each member is marked as closed at Stage 13 per the block-close protocol. No close-family verb appears against these numbers anywhere else in this document.
