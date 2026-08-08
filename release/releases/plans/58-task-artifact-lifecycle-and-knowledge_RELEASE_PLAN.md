---
title: Release Plan — 58-task-artifact-lifecycle-and-knowledge (close task-class work on artifact acceptance, and ship the two knowledge artifacts that need it)
type: release-plan
plan_type: release
status: ACTIVE
release: {{RELEASE_VERSION}}
milestone: 58-task-artifact-lifecycle-and-knowledge
release_class: novel
reversibility: CHEAP-to-MODERATE / Confidence HIGH
---
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->
# Release Plan — `58-task-artifact-lifecycle-and-knowledge`

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Version identity** | **Slug-primary / pre-claim per ADR-092.** The plan filename and the branch carry the milestone slug and no `vX.Y` stem; the declared identity is the **bump class `minor`**, not a number. The concrete version binds at the Stage-12 atomic claim, when `claim-version.sh --stamp-slug` resolves every `RELEASE_VERSION` placeholder in this file post-CAS and `git mv`s the plan to `plans/v<MAJOR>/<version>_RELEASE_PLAN.md`. |
| **Date Created** | 2026-08-07 (Friday) |
| **Release Manager** | Agent-assisted (`release-hub` Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/58-task-artifact-lifecycle-and-knowledge` |
| **PR** | (populated at PR creation — Stage 6 Phase C2) |
| **Milestone** | `58-task-artifact-lifecycle-and-knowledge` (179) |
| **Baseline** | `origin/main` @ `10433f92` (Commit-0 re-pin; the Stage-4 pin `0186e10b` and the Stage-5 pin `876f8632` are both superseded — `main` advanced five times during planning) |
| **Release class** | **`novel`** (operator-ratified at the Stage-4 gate; re-affirmed at Collective Review under ruling **R-D**). Posture: engagement density **Standard** · Stage-9 review depth **Deep** · Stage-5 activation bias **ALL** · Stage-13 outcome window **30-day** |
| **Topology** | **D-C SINGLE** — one release branch, sequential Engineering commits, one PR, one merge |
| **Concurrency posture** | **P0 fully-serial.** Stage-6 chips route one at a time in the approved sequence on the single branch; force-push (including `--force-with-lease`) is prohibited on the shared branch under any multi-chip activity |

> **Provenance.** This file transcribes the Stage-4 Release Planning output, reconciled to the **Stage-4 plan-approval gate** verdicts (2026-08-07), the **Stage-5 D-A gate** verdicts (2026-08-07), and the **Collective Review scope-lock** (2026-08-07). Where a later disposition superseded a Stage-4 assumption, the transcribed section carries the **decided** state and § Deviation Log records the delta against the Stage-4 plan of record. Authored at Engineering Commit 0 by the Stage-6 Engineering spoke for #101.

---

## Version identity — why this plan carries a token and not a number

Three versions were claimed in roughly five hours during this release's planning window. Two consecutive D-Version determinations (`v4.15`, then `v4.16`) were each rule-computed as free and each lost to a concurrent release before Engineering could open. The second loss fired the Stage-6 Commit-0 version re-verify as a HALT.

The operator's ruling was **not** to re-render a third number. Chasing the digit treats a structural race as an arithmetic error. Instead this plan is authored **token-bearing**: filesystem identity (filename, branch) stays slug-keyed, and only file **content** carries the `RELEASE_VERSION` placeholder. `claim-version.sh` resolves it on the CAS-win path only — so a lost candidate is never written to any filename or file body, and the collision class disappears rather than being survived.

**Two consequences this plan is responsible for carrying:**

- **AI-006 — Stage 12 MUST invoke `claim-version.sh --stamp-slug 58-task-artifact-lifecycle-and-knowledge`.** Absent the flag the stamping pass is skipped **entirely** and the unresolved token ships into the versioned plan. Backward compatibility makes that failure *silent*, not loud. The pre-flight (`_preflight_stamp`) is the guard: it fails closed when the pre-claim plan carries no token, so the token count below is load-bearing.
- **AI-007 — no verification method in this plan keys on a version digit.** A probe of the form `grep -cE '^\| v4\.NN'` rots on re-versioning and fails in the *worse* direction — it returns `0`, which a grader reads as *absent* rather than *mis-keyed*. Every release-level probe here keys on the milestone slug, which does not move.

---

## Scope

### Issues Included

| # | Issue | Title | Priority | Category | Labels |
|---|-------|-------|----------|----------|--------|
| 1 | #101 | Add a non-deliverable / task-artifact lifecycle that closes on artifact-acceptance rather than deployment | P2 | pipeline-definitions | `type:story`, `size:L`, `structure`, `project:portability-distribution` |
| 2 | #335 | Codify the `gh api` typed-vs-raw field discipline as a K1 standard | P2 | codification | `type:story`, `size:L` |
| 3 | #21 | Author the orchestration-mechanisms K1 discipline doc | P2 | research | `type:story`, `size:L` |

**Raw points 24 · risk-weighted `effective_pts` 28 · band 15–25.** The 12% overage is a **recorded, accepted residual** carried from the Stage-3 size-band reframe on dep-coherence grounds (the three cards are one dep-connected component through the keystone; splitting #101 from its dependents would put a blocker in a different milestone from the work it gates). Re-assessed at plan scope and unchanged: the mitigation *is* the internal sequence, and that sequence survives intact.

### Dependency Graph

```
#101  ──blocks──▶  #335        (artifact-acceptance close path)
  │
  └───blocks──▶  #21          (artifact-acceptance close path)

#335  ⟂  #21                   (no edge — verified disjoint, see File Contention Map)
```

**In-bundle compositional edges = 2.** This is the count `cross-cutting` trigger (c) tests against a ≥3 threshold.

**Edge semantics — soft, not hard.** #101 does not block #335 or #21 from being *authored*; it blocks them from *closing cleanly on artifact-acceptance*. Both artifact cards can be fully built and reviewed before #101 lands; only their Stage-13 close path depends on it. Because all three ship in one release with one merge, the edge is satisfied by construction — and it is why steps 2 and 3 are parallel-safe.

**Routing nuance (recorded, not resolved).** The two edges were mirrored as *native* GitHub dependency links at the Stage-4 gate, because hub routing reads native state and a prose-only edge is invisible to it. But GitHub's native dependency model is issue-level and binary, so it cannot represent a **close-time-only** edge. Read literally, `#335 blocked_by #101` with #101 still OPEN would gate wave 2 forever, since #101 does not close until Stage 13. **Resolution:** the native edge governs **close ordering**; this plan's Implementation Sequence governs **stage-wave ordering**.

**External edge — satisfied.** #101 `blocked_by` #351 (the `deliverable_type` keystone). #351 CLOSED 2026-06-29 under milestone `18-pmbok-coverage-and-project-schema`. Dependency-clear.

#### Topologically Sorted Sequence

| Position | Issue | Priority | Status | Dependencies (in-release) | Edge Type |
|---|---|---|---|---|---|
| 1 | #101 | P2 | bundled | (none — root) | — |
| 2 | #335 | P2 | bundled | #101 | BLOCKS |
| 3 | #21 | P2 | bundled | #101 | BLOCKS |

Positions 2 and 3 tied on priority; broken by issue-number ascending is **not** applied — the two are genuinely order-free (disjoint file sets), and the plan records them in the Stage-4 sequence order (#335 then #21) as a convention, not a constraint.

#### Artifact Relationship Graph

| Source | Type | Target | Direction | Derived from |
|---|---|---|---|---|
| #101 | BLOCKS | #335 | #101 → #335 | native `blocks` (mirrored at the Stage-4 gate) |
| #101 | BLOCKS | #21 | #101 → #21 | native `blocks` (mirrored at the Stage-4 gate) |
| #335 | GENERATES | `core/standards/gh-api-convention.md` | #335 → file | File Change Matrix (Create) |
| #21 | GENERATES | `core/disciplines/orchestration-mechanisms.md` | #21 → file | File Change Matrix (Create) |

### File Change Matrix

**Machine-readable path list** (one path per line, for deterministic extraction by Stage 7/8/9 chip prompts):

```
core/schemas/gate-criteria-spec.md
release/references/pipeline/stage-13-close.md
release/references/pipeline/stage-06-engineering.md
release/governance/release-process.md
core/specs/domain-token-registry.md
core/standards/gh-api-convention.md
core/rules/git-workflow.md
core/disciplines/orchestration-mechanisms.md
core/specs/framework-catalog.md
core/disciplines/README.md
release/releases/plans/58-task-artifact-lifecycle-and-knowledge_RELEASE_PLAN.md
release/releases/RELEASE_LOG.md
```

**Annotated (add / edit / delete intent per file):**

| Path | Intent | Issue | Note |
|---|---|---|---|
| `core/schemas/gate-criteria-spec.md` | **edit** | #101 | **E1.** Refine the `G-CL3` + `G-CL4` criterion bodies; add the § Close-Class Conditioning Disposition referenced predicate block; bump `**Schema version:**`. **Zero criterion IDs added / renumbered / removed / re-typed.** |
| `release/references/pipeline/stage-13-close.md` | **edit** | #101 | **E2.** Add the class-resolution step + `artifact-acceptance` branch in Phase A before A8; define the Artifact-Acceptance Record block schema; state the fall-through report line. |
| `release/references/pipeline/stage-06-engineering.md` | **edit** | #101 | **E3.** Name the positive task-class deliverable state `deliverable_state: artifact-accepted` in § 6 Outputs, as a first-class sibling of the deployed-copy state. |
| `release/governance/release-process.md` | **edit** | #101 | **E4.** Close-class routing in § Stage 13 Close — **cites** the `G-CL` rows as authority, never restates them. Re-baselined at Commit 0; this file changed twice during planning. |
| `core/specs/domain-token-registry.md` | **edit** | #101 | **E5 (AI-001).** Register `task-artifact` in §2 Concept 1's value-space cell. One cell; nothing else changes. **Added to the matrix at Commit 0** — the Stage-4 FCM predates the Stage-5 R-1 recommendation. |
| `core/standards/gh-api-convention.md` | **add** | #335 | Path **RATIFIED singular** at Collective Review (D-2; 6/0 repo precedent). Resolves §4.1 clean-by-construction — **no allowlist entry**. |
| `core/rules/git-workflow.md` | **edit** | #335 | Single cross-reference line to the new standard. Contended with in-flight PR #4924 — see § File Contention Map. |
| `core/disciplines/orchestration-mechanisms.md` | **add** | #21 | 7 H2 sections + §3.5 + §5.5, `type: discipline` frontmatter. Resolves §4.1 clean-by-construction — **no allowlist entry**. |
| `core/specs/framework-catalog.md` | **edit** | #21 | Register the named mechanisms, or record the out-of-scope rationale (AC9). `deploy.sh` Check 18 reads this file for version-anchor drift. |
| `core/disciplines/README.md` | **edit** | #21 | Index row for the new discipline doc (30/33 dominant convention). Added at Collective Review. |
| `release/releases/plans/58-…_RELEASE_PLAN.md` | **add** | release | This file. Slug-primary in flight; binds to `plans/v<MAJOR>/` at the Stage-12 claim. |
| `release/releases/RELEASE_LOG.md` | **edit** | release | Mandatory Stage-12 row. **Does NOT count toward `cross-cutting` trigger (b)** — ruled at Collective Review (R-D). |

**Locked scope — net movement is DOWN vs. the Stage-4 matrix.** #335 lost three conditional files (the hook, its allowlist row, and the script-execution-allowlist row) when D-3 ratified **SKIP-AS-RESIDUAL**; the release stays single-domain `governance`. #101 gained one (E5); #21 gained one (README index row).

**Not in the matrix (stated, not omitted):** Stage-13 close outputs (`RELEASE_INDEX.md`, `RELEASE_DIGEST.md`, `releases/notes/`, `CHANGELOG.md`, `.version`) land via the Stage-13 chore PR per the standard close-out set and are not enumerated here.

**Deliverable-domain classification (A3-time) + provenance label.**

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-07, domain: governance }`

*Classification rationale (per `stage-04-planning.md` §5.7):* every path in the matrix is an internal pmo-platform artifact — pipeline specs, governance, a schema, two K1 corpus docs, and the release-corpus files. Dominant domain = **`governance`**, whose guide ships at `core/standards/domain-best-practices/governance.md`. The **conditional secondary `software` domain evaporated** when D-3 ratified SKIP-AS-RESIDUAL — no `core/hooks/*.sh` ships, so the § 6 new-executable companion obligation does not fire. **Sourcing-exempt, domain-classified** — the two properties are distinct and both are recorded.

**This classification is also why the release does not exercise its own new branch.** `domain: governance` resolves to the **deployable** branch, so `G-CL3`'s substitution ships correct and fail-safe but is never executed by this release's own close. The Release Outcome Statement was amended accordingly at the Stage-5 gate: ship-and-document, not ship-and-demonstrate.

### File Contention Map

**Within-release contention: NONE.** Pairwise intersection of the three issues' declared path sets:

| Pair | Shared paths | Intent Mix | Severity | Result |
|---|---|---|---|---|
| #101 ∩ #335 | — | — | NONE | disjoint |
| #101 ∩ #21 | — | — | NONE | disjoint |
| #335 ∩ #21 | — | — | NONE | disjoint |

**Probe record.** Denominator = the 10 issue-attributed paths in the matrix (the 2 release-scoped paths belong to no issue). **Sensitivity arm:** the same intersection run against `{#101, #101}` returns **5** paths — non-empty, so the intersection operator is live and the three zeros are true zeros. **Specificity arm:** intersecting #21's set against a synthetic empty set returns 0.

This zero is what makes steps 2 and 3 genuinely parallel-safe — on evidence, not assertion.

**Cross-PR contention.** Re-measured at Commit 0 (`10433f92`); the Stage-4 measurement at `0186e10b` is superseded.

| File | Colliding party | Class | `overlap_class` | Mitigation |
|---|---|---|---|---|
| `release/governance/release-process.md` | PRs #4985 and #4980 both **MERGED** during planning | resolved — traffic settled | n/a | **R4 resolved favourably.** Engineering re-baselines against settled `main` rather than racing an open PR. Residual drops MODERATE → LOW. |
| `core/rules/git-workflow.md` | in-flight `release/hub-spoke-execution-safety` (#4924) | 1 in-flight + this release | `line-range-overlap` | #335's touch is a **single cross-reference line** — low collision surface. Prefer landing after #4924, or accept a trivial rebase. Not a sequencing blocker. |

`overlap_class` is recorded as **assumed, not computed** — `check-line-range-overlap.py` is optional at ≤3 concurrent PRs and was not run. Flagged as the weakest evidence in this section.

**Structural-blast-radius (Tier-S) sub-audit: no edge.** The mover-set is **empty** — zero renames, zero relocates, zero deletes in the matrix — so `SURFACE(R)` collapses to the same-path overlap set above.

**Version-slot contention: structurally eliminated.** The Stage-4 roster recorded a `Δversion` virtual token whose collision predicate was **unevaluable** — no sibling declared a bump class or version slot. That residual is now moot: this plan declares a bump class and no digit, and the token binds only on the CAS-win path. The predicate has nothing to collide with.

### Exclusions

- **#231** — rehomed 2026-08-06 to `model-router-and-connectors` under its owning epic #1153. It benefits from this close class but does not gate on it.
- **The end-to-end task-artifact *release* path** — Stage-12 `G-EX4`/`G-EX5` and the `hub-spoke-bridge.md` Step-4 completion table still hard-require a `RELEASE_LOG` row, so no task-artifact-class *release* can complete Stage 12 today. Deliberately out of scope: conditioning them adds a third named-governance-surface touch and re-renders the Release Class on a bundle already over its size band. Routed to follow-up. See § Tech-Debt Register TD-1.
- **A `domain-best-practices/task-artifact.md` guide** — the guide's absence *is* the codified demand signal, and CASE D-2 (named class, no guide) is already the majority state (4 guides / 8 named classes). Enriched an existing owner rather than filing a duplicate.

---

## Implementation Sequence

| # | Issue | Layer | Rationale | Parallel-safe with |
|---|---|---|---|---|
| **1** | **#101** | *foundation* | The close-lifecycle mechanism. Lands first — it is the blocker for both artifact cards' close path, and its edits touch the highest-traffic files in the bundle. Dependency-clear. | — (serial) |
| **2** | **#335** | *skill-core / codification* | K1 `gh api` typed-field standard at the ratified singular path + the `git-workflow.md` cross-reference. | **#21** |
| **3** | **#21** | *skill-core / research* | K1 orchestration-mechanisms discipline doc + framework-catalog reconciliation + README index row. | **#335** |

**Stage-6 dispatch caveat.** Parallel-safe here is a *file-contention* property. Under **P0 fully-serial**, the hub routes ONE Engineering chip at a time regardless of disjointness. Steps 2/3 parallelism is realizable at Stages 5/7/8, not at Stage 6.

**Degradation property (why this order):** #101 lands first and independently, so the bundle degrades gracefully — if #335 or #21 slips, the keystone has still shipped and the bundle can close on a reduced set. This is the mitigation the Stage-3 size-band reframe recorded as its accepted-residual answer, and it survives at plan scope.

### Issue #101 — Change Specification

**Files modified:** `core/schemas/gate-criteria-spec.md` · `release/references/pipeline/stage-13-close.md` · `release/references/pipeline/stage-06-engineering.md` · `release/governance/release-process.md` · `core/specs/domain-token-registry.md`

**Change description.** Introduce a **declaration-gated typed branch** on the Stage-13 close path: when a release's resolved deliverable class is the named value `task-artifact`, the close is satisfied by an **Artifact-Acceptance Record** rather than a `RELEASE_LOG` `DEPLOYED → VERIFIED` transition. The branch is a **criterion-body refinement** on the existing `G-CL` rows — it adds no criterion ID, no second gate spec, and no parallel close path.

**Estimated complexity:** High (keystone; four governance/pipeline/schema surfaces plus one registry cell).

**Dependencies:** None in-release (#351 closed).

**The six invariants Engineering must not break** — carried verbatim from the ratified Stage-5 design:

1. **The deployable path is byte-unchanged** (AC4 regression). Any diff altering deployable-class behavior is a defect.
2. **One gate spec** (AC5). No second criterion set, no sibling close spec.
3. **Absent / unrecognized axis ⇒ deployable**, and the fall-through is **reported**, never silent.
4. **The AAR is mandatory when the class resolves `task-artifact`** — absent ⇒ FAIL, never N/A.
5. **No `RELEASE_LOG.md` convention edit and no `hub-spoke-bridge.md` edit.** The mandatory Stage-12 row does not count toward the class trigger (ruled at Collective Review, R-D), but a *convention* edit to either file would.
6. **Introducing-release-exempt cutover** on every new clause (reflexive-pipeline-loop discipline).

### Issue #335 — Change Specification

**Files modified:** `core/standards/gh-api-convention.md` (add) · `core/rules/git-workflow.md` (one line)

**Change description.** Codify the `gh api` typed-vs-raw field discipline as a K1 standard: both degenerate write forms (the unexpanded `@path` literal under `-f`, and the field-clearing empty value from an unset variable), both preventive rules (non-empty operand validation, and post-mutation structural read-back), and the pagination discipline for resolvers.

**Estimated complexity:** Medium.

**Dependencies:** #101 (close path only — does not gate authoring).

### Issue #21 — Change Specification

**Files modified:** `core/disciplines/orchestration-mechanisms.md` (add) · `core/specs/framework-catalog.md` · `core/disciplines/README.md`

**Change description.** Author the K1 orchestration-mechanisms discipline doc — a comparative design-space model of multi-agent orchestration mechanisms with a contract-dimension matrix, per-mechanism SWOT, and a problem-class taxonomy — then reconcile the named mechanisms against the framework catalog.

**Estimated complexity:** High (research-class; 11 acceptance criteria).

**Dependencies:** #101 (close path only).

**AI-005 (carried).** §3.5 and §5.5 must be authored as **H2** headings. AC1's method is `grep '^## '`, which does not match `### `, and a fenced `## ` inflates the count.

---

## Risk Register

| # | Risk | Class | Evidence | Mitigation | Reversibility · Confidence |
|---|---|---|---|---|---|
| **R1** | **The close-gate set grew 7 → 9 after these cards were authored.** `G-CL8` (Documentation Impact) and `G-CL9` (ADR ratification-flip) were not in the card's field of view, and **both are warn-mode** — so a mis-conditioned branch fails silently to a log rather than blocking. | Scope | Live IDs `G-CL1…G-CL9` in `gate-criteria-spec.md` § Gate 13. | **RESOLVED at Stage 5.** The ratified design renders a per-gate disposition across all 9 gates — 2 conditioned, **7 explicit no-ops**, 0 unstated. Both warn-mode gates land in the explicit-no-op column with stated reasons, so the branch adds **no** new silent-miss surface. | MODERATE · HIGH |
| **R2** | **One more governance-surface touch re-renders the class `cross-cutting`.** Trigger (b) counts ≥3 of a named 7-file set. | Scope / classification | Set membership re-counted at each gate. | **RESOLVED.** The design adds no third touch: the count stands at **2** (`gate-criteria-spec.md`, `release-process.md`). `RELEASE_LOG.md`'s mandatory Stage-12 row was ruled **not counting** (R-D); `hub-spoke-bridge.md` is deliberately untouched (invariant 5). E5's `core/specs/` target is in neither the 7-set nor the stage-file set. | CHEAP · HIGH |
| **R3** | **#21 carries the same Check-42 host-binding exposure that was flagged only on #335** — Check 42's glob covers `core/disciplines/**/*.md`, and #21 authors a doc about orchestration that naturally cites `gh`/`git`. | Scope / CI | Check 42 target glob includes both `core/standards/**/*.md` and `core/disciplines/**/*.md`. | **RESOLVED at Collective Review (D-B).** Both new K1 docs resolve §4.1 on its *first* limb — **clean of prescribed-host-mechanism signature**, no allowlist entry. Empirically grounded: the real detector run on two authorings of the same semantic content fired 3 findings on the naive form and **0** on the constrained form. **Whether a doc trips Check 42 depends on how it is written, not where it lives.** CIAC-2 is retained as the release-scoped catch. | CHEAP · HIGH |
| **R4** | **`release/governance/release-process.md` carried 3-way traffic** — two sibling releases plus this one. | Contention | Both siblings merged during planning. | **RESOLVED favourably.** Engineering re-baselines against settled `main`. Residual MODERATE → LOW. | CHEAP · HIGH |
| **R5** | **Native dependency state was wrong in two directions** — the `#101 blocks {…}` edges existed only as body prose, and #21 carried a stale native `blocking: #208` its own body said was withdrawn. | Dependency | Dependencies API probes with a live sensitivity arm. | **REPAIRED at the Stage-4 gate.** Both real edges mirrored natively; the stale edge removed. The residual is the *semantic* one recorded under § Dependency Graph: a native edge cannot express a close-time-only dependency. | CHEAP · HIGH |
| **R6** | **#101's reversibility was declared EXPENSIVE.** It changes how a whole class of work closes; a wrong typed-branch shape propagates into every subsequent task-class close. | Rollback | Card Notes (intake grade). | **RE-GRADED → `CHEAP-to-MODERATE · HIGH`** (operator, Stage-5 D-A gate). Basis: D-A resolved to a **declaration-gated** value and this release resolves `domain: governance`, so it takes the deployable path and never exercises the new branch. **No issue's closure state becomes path-dependent**, so `git revert` of the release PR restores prior state with no migration and no backfill. **The cheap window closes at the first task-artifact-class release, not at this one** — which cannot occur before this release ships. The `novel` class's Deep Stage-9 review is unchanged either way. | CHEAP-to-MODERATE · HIGH |
| **R7** | **The version slot could not be collision-checked** — no in-flight sibling declared a bump class or version slot, so the predicate had no operand. | Contention | Stage-4 roster: zero version tokens across all three sibling PR bodies. | **STRUCTURALLY ELIMINATED.** This plan declares a bump class and no digit; `claim-version.sh` binds the number atomically post-CAS. **Two D-Version determinations were lost to this exact race before the token shape was adopted** — the risk materialized twice, and the mitigation removes the surface rather than narrowing the window. | CHEAP · HIGH |
| **R8** | **Size-band breach (28 effective vs. a 25 ceiling), accepted at Stage 3.** | Scope | Milestone § Size-band reframe. | **Nothing changes at plan scope.** The accepted-residual mitigation *was* the internal sequence, and that sequence survives unmodified — #101 lands first and independently. | — |
| **R9** | **#21's problem-evidence was `PV-D` (unsourced)** — anticipatory motivation sourced to operator direction rather than a witnessed instance. | Warrant | §11.1 classification; card's own flag. | **RE-ANCHORED to `PV-A`** (operator, Stage-4 gate) against the stalled D3/D5 open decisions in `core/disciplines/actor-model-and-governance-as-contract.md`. | CHEAP · HIGH |
| **R10** | **#335's hook decision could have added a runtime surface**, triggering the new-executable companion obligation and a warn-mode rollout checklist. | Scope | AC5: *"if a hook is added: warn-mode-initial."* | **RESOLVED — D-3 ratified SKIP-AS-RESIDUAL.** No hook ships; the release stays single-domain `governance`; three conditional files leave the matrix. | CHEAP · HIGH |
| **R11** | **Baseline-pin staleness is demonstrated, not theoretical** — `main` advanced during the Stage-4 audit, again during Stage-5, and three more times before Engineering opened. | Process | Five mainline advances across the planning window. | Stated as an explicit residual. Commit 0 re-pins to `10433f92`; Stage-9 Phase A6.6 re-measures fresh pre-GO. | — |
| **R12** | **Stage 12 silently skips the stamping pass if `--stamp-slug` is omitted**, shipping an unresolved `RELEASE_VERSION` placeholder into the versioned plan. | Execution | `claim-version.sh` runs the stamp pass **only** when the flag is supplied; backward compatibility makes the omission a no-op rather than an error. | **AI-006.** The flag is a named, gated Stage-12 obligation recorded in § Version identity above and in the Verification Plan below. The pre-flight is the second line of defence — it fails closed when the pre-claim plan carries no token, which is why the token count is verified at Commit 0. | CHEAP · HIGH |

---

## Tech-Debt Register

Recorded rather than silently absorbed, per the Stage-5 Mode-4 flags.

- **TD-1 — the end-to-end task-artifact *release* path is incomplete by design.** Stage-12 `G-EX4`/`G-EX5` and the `hub-spoke-bridge.md` Step-4 completion table still hard-require a `RELEASE_LOG` row, so a task-artifact-class *release* would fail Stage 12 before reaching Stage 13. This release ships the **close-gate semantics**, not the whole lifecycle. **Mitigated by the declaration gate** — the incomplete path is *unreachable*, not merely unlikely, because no release declares the class. Routed to follow-up.
- **TD-2 — no automated completeness enforcement for a task-artifact close.** `deploy.sh` Checks 32 and 48 both iterate `RELEASE_LOG` rows, so a row-less release is invisible to both. This is also why there is **no false FAIL** (favourable). Enforcement rests on the Step-4 completion table plus `G-CL4`/AAR. Proportionate under the governance guide's `CI-3` contraindication, but it is a real gap and is recorded as one.
- **TD-3 — the deliverable-class named lists have already diverged.** `core/specs/domain-token-registry.md` carries `support`; `core/schemas/project-schema.md` does not, although `support` ships a guide. Pre-existing, unrelated to #101, surfaced by the Stage-5 canonicalization survey. Routed to follow-up.

---

## Cross-Issue Acceptance Criteria

Both CIACs span ≥2 issues, assert a constraint the *integrated* release must hold, and are graded at Stage 9 QC3.5 / Phase A3.6 on the merged PR.

- [ ] **CIAC-1 (#101 × #335 × #21 — the Stage-13 task-artifact close branch admits this release's own artifacts):** the artifact-acceptance close path #101 authors actually admits the two artifacts this release produces — the release records artifact-acceptance for #335 and #21 with **no per-card `RELEASE_LOG` release row and no per-card release note manufactured for either**, while the release's own deployable-class close proceeds unchanged.

  *Shared surface:* the task-class branch in `release/references/pipeline/stage-13-close.md` + the `G-CL` conditioning in `core/schemas/gate-criteria-spec.md`.

  *Method:* `grep -nEi 'task-artifact|artifact-acceptance' release/references/pipeline/stage-13-close.md` returns the branch **and** the branch text names an acceptance condition that #335's and #21's deliverables satisfy.

  *Corroborating probe (AI-007 — version-independent by construction):*
  ```bash
  grep -cE '^\| [^|]* \| 58-task-artifact-lifecycle-and-knowledge \|' release/releases/RELEASE_LOG.md
  ```
  Expected **1** — exactly one row for the release as a whole, none per artifact card. The probe keys on `RELEASE_LOG` **column 2 (the milestone slug)**, not on a version digit, so it survives re-versioning. Hub-verified against mainline: sensitivity **1** on a known release, specificity **0** on a nonexistent slug. **Do not substitute a `^\| v4\.NN` form** — it rots on re-versioning and fails in the worse direction, returning `0`, which a grader reads as *absent* rather than *mis-keyed*.

  *Graded at Stage 9 QC3.5 on the merged PR.*

  *Why this one exists:* it is the milestone's own Success Indicator, and it is the only predicate that fails if #101 ships a close path that is technically present but does not actually fit its two in-bundle consumers.

- [ ] **CIAC-2 (#335 × #21 — the Check-42 host-binding surface):** **both** new K1 docs are adjudicated against `knowledge-architecture.md` §4.1 — each is either clean of prescribed-host-mechanism signature, or carries an explicit, rationale-bearing entry in `core/deploy/allowlists/skip-host-binding-check.txt`. Neither leaves an unresolved `host-binding-leak` finding.

  *Shared surface:* `core/deploy/allowlists/skip-host-binding-check.txt` + `deploy.sh` Check 42.

  *Method (AI-003 — filename corrected to the ratified singular):*
  ```bash
  bash core/deploy/deploy.sh --check 2>&1 | grep -i 'host-binding-leak'
  ```
  reports no unresolved finding against `core/standards/gh-api-convention.md` **or** `core/disciplines/orchestration-mechanisms.md`.

  **⚠ The filename is `gh-api-convention.md` — singular.** D-2 ratified the singular form at Collective Review on 6/0 repo precedent; #335's body still carries the pre-ratification **plural** (`gh-api-conventions.md`), and so did the Stage-4 plan text at five places. **Left stale, this probe greps a path that will never exist and reads as a pass.** Note also that *neither* spelling exists on mainline today — the doc is created by #335 later on this same branch — so the probe is a **forward reference**: it legitimately returns 0 until #335 lands, and would return 0 **forever** if the name stayed wrong.

  *Graded at Stage 9 QC3.5 on the merged PR.*

  *Why this one exists:* the §4.1 constraint was surfaced on **#335 only**, but Check 42's glob covers `core/disciplines/**/*.md` too. No per-issue AC spans both docs — exactly the CIAC shape, with **no dependency edge between the two issues**.

*(No third CIAC. #101's regression criterion — deployable-class closes as today — is a single-issue predicate (#101 AC4) and is correctly graded per-issue. Manufacturing a CIAC for it would inflate the section.)*

---

## Verification Plan

### Per-Issue Verification — AC → method mapping

| Issue | AC | Predicate class | Verification method | Expected result |
|---|---|---|---|---|
| **#101** | AC1 Stage 13 admits an artifact-acceptance close | file-path+state (b) | `grep -nEi 'task-artifact\|artifact-acceptance' release/references/pipeline/stage-13-close.md` | ≥1 hit naming a task-class close branch (baseline: **0**) |
| **#101** | AC2 `G-CL` carries a criterion satisfiable by artifact-acceptance | file-path+state (b) | read the `G-CL` rows in § Gate 13; the artifact-acceptance path is referenced across the **9**-gate set with a per-gate disposition | each of `G-CL1`–`G-CL9` carries a conditioning disposition or an **explicit** no-op |
| **#101** | AC2.1 every gate carries a *recorded* disposition, no-ops included | explicit `predicate:` (c) | read § Close-Class Conditioning Disposition — count the rows | **9/9** gate IDs present; 2 conditioned, 7 explicit no-ops, 0 unstated |
| **#101** | AC3 Stage 6 names a positive task-class deliverable state | file-path+state (b) | `grep -c 'deliverab' release/references/pipeline/stage-06-engineering.md` **and** the hit is a named *state*, not an `(if applicable)` omission | ≥1, qualitatively a positive state (baseline: **0**) |
| **#101** | AC4 regression: deployable-class closes as today | behavioral/domain (d) | walk a deployable-class release through Stage 13; inspect `git diff` on the deployable clause of `G-CL3`/`G-CL5` | no new required step; the deployable branch is byte-unchanged |
| **#101** | AC5 ONE gate spec with a typed branch | explicit `predicate:` (c) | read the spec — a single `G-CL` set with a typed branch, not two parallel close specs | single spec; **zero** criterion IDs added / renumbered / removed / re-typed |
| **#335** | CC1 K1 doc cites symptom + correct form + verification step | file-path+state (b) | the doc exists at `core/standards/gh-api-convention.md` and contains all three elements | 3/3 present |
| **#335** | CC2 both degenerate forms + both preventive rules | file-path+state (b) | `grep` for the unexpanded-`@path` form, the empty-from-unset-variable form, the non-empty-validation rule, and the pagination rule | 2 forms + 2 rules present |
| **#335** | CC3 hook-coverage decision recorded | explicit `predicate:` (c) | the enforce / warn / skip-as-residual decision + rationale appear in the K1 doc | **SKIP-AS-RESIDUAL** recorded with rationale (D-3) |
| **#335** | CC4 §4.1 host-binding disposition recorded **and** CI-clean | file-path+state (b) **+** behavioral (d) | disposition recorded **AND** `bash core/deploy/deploy.sh --check 2>&1 \| grep -i 'host-binding-leak'` | disposition present (clean-by-construction, no allowlist entry); **no unresolved finding** |
| **#335** | CC5 hook (if added) ships warn-mode-initial | explicit `predicate:` (c) | — | **N/A — no hook ships** (D-3) |
| **#335** | CC6 memory cross-ref + verify-before-recommend composition | file-path+state (b) | the doc documents post-mutation structural read-back and composes with the verify-before-recommend discipline | both present |
| **#21** | AC1 artifact at the target path with 7+2 sections | file-path+state (b) | `grep '^## ' core/disciplines/orchestration-mechanisms.md` + `type: discipline` frontmatter | 7 H2 + §3.5 + §5.5 (**all H2** per AI-005); frontmatter present |
| **#21** | AC2 ≥9 contract dimensions with hub-spoke current-state values | explicit `predicate:` (c) | count named dimensions; each carries a hub-spoke value | ≥9, each with a value |
| **#21** | AC3 SWOT, ≥3 external citations per mechanism | explicit `predicate:` (c) | per-mechanism citation count | ≥3 each |
| **#21** | AC3.5 ≥5 problem classes × (citation + indicators + worked example) | explicit `predicate:` (c) | count classes; each has all three | ≥5, 3/3 each |
| **#21** | AC4–AC7 inclusion criteria · extension protocol · §5.5 four rules · §6 integration points | behavioral/domain (d) | judge-rubric read against the AC's declared method | criteria named before the set; §5.5 carries all four rules + the no-design boundary; §6 names **D3 and D5** |
| **#21** | AC9 framework-catalog reconciliation | file-path+state (b) | each §3 mechanism resolves to a `core/specs/framework-catalog.md` row **or** a stated exclusion; `deploy.sh` Check 18 clean | every mechanism resolved; no version-anchor drift |
| **#21** | AC10 §7 defers the selection layer | file-path+state (b) | §7 lists the deferrals; the artifact declares no config field | deferrals present; zero config declarations. **AI-004:** the `orchestration_pattern` probe must be **diff-scoped**, not repo-wide — one occurrence already exists in a test fixture, so the repo-wide form false-fails on day one |
| **#21** | AC11 cutover / exemption clause | file-path+state (b) | `grep` for the clause + the introducing-release-exempt form | clause present |

**Declared, verification deferred:** none. Every AC maps to a method executable at Stage 7/8 with tooling that exists today.

### Release-Level Verification

Per `verification-checklist.md`:

- [ ] File Integrity
- [ ] Content Correctness
- [ ] Cross-Reference Validity — `core/deploy/deploy.sh --check` Check 14 (doc-link integrity) clean on all modified `.md` files
- [ ] Skill Invocation — **N/A: this release touches no skill source and no `.skill` package.** Checks 1/2/7/12 have no target.
- [ ] Output Contract Compliance
- [ ] **Token-resolution readiness** — run, against the **pre-claim** plan:
  ```bash
  grep -cE '\{\{RELEASE_VERSION\}\}' release/releases/plans/58-task-artifact-lifecycle-and-knowledge_RELEASE_PLAN.md
  ```
  Expected: **non-zero**. A zero means `claim-version.sh`'s stamp pre-flight fails closed, the claim HALTs, and the plan never renames (AI-006 / R12). The probe is written with escaped braces deliberately: the stamper substitutes the *bare* literal globally, so a command spelling it bare would itself be rewritten at claim time and stop being a usable check on the post-claim file.

**Forecast discipline (§5.5):** this release forecasts **no** deploy-resolution of any `deploy.sh --check` finding. It touches no skill source, no `.skill` package, and no harness artifact; and it makes **no** claim about the history-level Checks 8/10, which no deploy can resolve.

---

## Delivery Strategy

| Aspect | Decision |
|--------|---------|
| **Branch** | `release/58-task-artifact-lifecycle-and-knowledge` off `origin/main` |
| **Topology** | **D-C SINGLE** — one release branch, sequential Engineering commits, one PR, one merge |
| **Implementation approach** | Sequential (dependency-ordered) |
| **Commit strategy** | One commit per change-spec unit, referencing its source issue |
| **Parallelism posture** | **P0 fully-serial** at Stage 6. Stages 5/7/8 run parallel-safe, subject to the Quota-Budget WARN split |
| **Review approach** | Single PR for the entire release, opened **draft** at Engineering start, transitioned ready at the Stage 9 gate |
| **Merge** | Single merge at Stage 12. Release merges typically require `gh pr merge --admin` — branch protection blocks a plain merge even when CLEAN |
| **Deployment mechanism** | Git merge. **No S-2 skill copy and no manifest execution** — the manifest is empty (see § Operational Deployment Manifest) |
| **Plan file** | This file, as **Engineering Commit 0**. Slug-primary in flight; `git mv`'d into the versioned bucket by `claim-version.sh --stamp-slug` at the Stage-12 claim |
| **Commit-0 version re-verify** | **NOT APPLICABLE — structurally retired for this release.** The re-verify exists to detect a literal version claimed out from under the plan. This plan carries no literal version, so there is no digit to collide. The equivalent Commit-0 obligation is the **token-count check** above |
| **Stacked-base cleanup posture** | Phase B0 base-shift per dep (default — Option A). No stacked-base waves are planned |

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Complexity |
|---|---|---|
| **#21** | Delete `core/disciplines/orchestration-mechanisms.md` + revert the `framework-catalog.md` rows and the README index row. Purely additive, zero consumers at ship time (its consumers D3/D5 are *open decisions*, not code) | **CHEAP** |
| **#335** | Delete the K1 standard + revert the `git-workflow.md` cross-reference line. No hook shipped, no allowlist row | **CHEAP** |
| **#101** | `git revert` of the release PR. **Re-graded from EXPENSIVE.** The branch is declaration-gated and this release resolves `domain: governance`, so no issue's closure state becomes path-dependent — reverting the keystone orphans nothing and requires no migration or backfill | **CHEAP-to-MODERATE** |

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|----------|---------|-----------|
| **Partial Revert** | Isolated issue failure | Revert the specific commits per `rollback-protocol.md` |
| **Full Restore** | Systemic failure | `git revert -m 1 <merge-commit>` — SINGLE topology produces a true two-parent merge commit, so the `-m 1` form applies. **Precondition:** merge via a real merge commit, not squash |
| **Forward Fix** | Minor issue, fix well-understood | Fix branch per `rollback-protocol.md` |

**Rollback ordering is the inverse of the implementation sequence:** #21 / #335 first (cheap, independent), #101 last.

**The one condition that would make #101 expensive, stated plainly:** a *subsequent* release actually closing as `task-artifact` class. That cannot occur before this release ships. **The cheap window therefore closes at the first task-artifact-class release, not at this one** — correcting the Stage-4 plan's reading, which placed the window's close at this release's own Stage 13.

---

## Operational Deployment Manifest

**EMPTY — N/A: no Layer 2 propagation targets in this release.**

No skill source changes, so no S-2 copy; no schema migration; no content sync. Per `stage-13-close.md` Phase B-OPS1, an empty manifest skips directly to Phase C1. This is the **existing** empty-set path — it is deliberately *not* conditioned by this release's new branch (`G-CL5` explicit no-op), because adding a class branch would duplicate a working trivial-pass and create two routes to one verdict.

### Schema Migrations

**N/A — no schema migrations in this release.** The `deliverable_type` value space is an **open** enum whose openness is exercised, not a closed enumeration being changed; registering a value adds no field, changes no shape, and migrates no data.

---

## Tier-A activated design artifacts

Read by `G-CL6` at Stage 13.

| Artifact | Flow class | Trigger | Tier |
|---|---|---|---|
| Close-class resolution + typed-branch decision flow | Process-flow (decision) | ≥1 gate (9) + ≥2 actors (hub / spoke / operator) | **Tier-A** |
| `stage-13-close.md` Layer-1 dual-write emit-sequence flow-block | Process-flow (agent-process) | the design adds a class-resolution step to the depicted sequence | **Tier-B (refresh)** |

---

## Quota Budget

**Verdict: WARN** (per `quota-budget-protocol.md` Checkpoint A)

- **Parallel-eligible spokes per parallel stage:** Stage 5: **3** · Stage 7: **3** · Stage 8: **3**
- **Per-spoke cost estimate:** **moderate–high** ordinal band — all three cards are `size:L`. The §5.1 cutover to observed medians has **not** fired for the `L` bucket, so the ordinal band is retained as the floor.
- **Envelope:** not operator-stated at hub start → conservative default, further discounted by the planning-window draw (a Mode R run, a Stage-4 spoke, two Stage-5 spokes, and a re-spawned Stage-6 spoke).
- **Estimated cumulative draw:** **50–80% band** for the worst parallel batch. A point estimate is withheld — multiplying an *ordinal* band into a percentage would manufacture precision the heuristic does not carry.
- **Routing: WARN → window-aware launch timing + split batch.** Split each parallel wave **2 + 1** (#335 ∥ #21 first — the verified-disjoint pair; #101's wave is single-spoke anyway). **Not STAGGER** — a `sleep` spreads momentary peak and changes nothing about cumulative consumption within the window.
- **Note:** this estimate is advisory and one-time. The load-bearing gate is Checkpoint B, re-run **per wave**. Bands are `[CALIBRATE-AFTER-3]`, MEDIUM confidence.

---

## In-Flight Release Roster

**Measured at:** `10433f92` · `2026-08-08T03:33Z` (Commit-0 re-measurement; the Stage-4 roster at `0186e10b` is superseded)

**Population definition:** open PRs with a `release/*` head (drafts included) ∪ remote `release/*` heads carrying no open PR, minus this release.

**Version-slot contention is not evaluated, and does not need to be.** The Stage-4 roster's central finding was that every sibling rendered `UNRESOLVABLE` on the version slot, leaving the collision predicate with no operand — an unknown, never an absence. That residual is **retired by construction** in this plan: it declares a bump class and no digit, and the number binds atomically at the Stage-12 CAS. A sibling's slot can no longer collide with a slot this release does not hold.

**Explicit residual.** A roster is baseline-pinned by construction; a sibling that branches after this pin is invisible to it. This section is a **pinned measurement carrying no verdict** — the verdict is rendered at Stage 9 Phase A6.6, which re-measures fresh pre-GO. The planning window's five mainline advances are live proof the residual is real rather than theoretical.

---

## Hub-Rendered D-Decisions

| ID | Decision | Verdict | Rendered at |
|---|---|---|---|
| **D-A** | #101 typed-branch shape | **RATIFIED** — a `deliverable_type` **value** (`task-artifact`) consumed as a criterion-body refinement on the existing `G-CL` rows. No parallel path, no new axis, no new gate ID | Stage-5 D-A gate |
| **D-A.1** | `G-CL3` treatment | **RATIFIED** — class-appropriate terminal-record substitution via the Artifact-Acceptance Record. Not exemption, not lattice extension | Stage-5 D-A gate |
| **D-A.2** | Gate coverage | **RATIFIED** — 2 conditioned, **7 explicit no-ops**, both warn-mode gates deliberately unconditioned | Stage-5 D-A gate |
| **D-A.3** | Evidence home | **RATIFIED** — the existing release-plan `### Verification Evidence` section. No new ledger | Stage-5 D-A gate |
| **D-B** | §4.1 host-binding disposition (both new K1 docs) | **RATIFIED** — clean-by-construction, **no allowlist entry**. An allowlist entry would be actively harmful: it permanently exempts the file, so a *future* edit that does prescribe goes undetected | Collective Review |
| **D-2** | #335 doc path | **RATIFIED** — `core/standards/gh-api-convention.md` (**singular**; 6/0 repo precedent) | Collective Review |
| **D-3** | Hook coverage | **RATIFIED — SKIP-AS-RESIDUAL.** Release stays single-domain `governance` | Collective Review |
| **D-C** | Branch topology + Stage-6 concurrency posture | **SINGLE / P0 fully-serial** | Stage-4 gate |
| **D-Version** | Release identity | **TOKEN-BEARING per ADR-092** — bump class `minor`; no digit in the plan; the `RELEASE_VERSION` placeholder resolved post-CAS at the Stage-12 claim. Supersedes both the `v4.15` and `v4.16` determinations, each of which was lost to a concurrent release | Operator, post-Stage-6 HALT |
| **R-D** | Does the mandatory `RELEASE_LOG` row count toward `cross-cutting` trigger (b)? | **RULED: NO.** Count stands at 2 of 7; class remains `novel`. `G-EX4`/`G-EX5`/`G-CL3` make the row mandatory for *every* release, so counting it hands every release a free trigger-(b) touch and fires a nominally-≥3 threshold at **2** substantive touches. Recorded as a specification gap and routed for binding codification beyond this milestone | Collective Review |
| **Outcome Statement** | Scope of the demonstration claim | **AMENDED** — ship-and-document, not ship-and-demonstrate. The release resolves `domain: governance` ⇒ deployable, so `G-CL3`'s substitution is never executed by its own close. The claim is withdrawn rather than left to fail at Stage 9 | Stage-5 D-A gate |
| **#101 reversibility** | Intake grade `EXPENSIVE · MEDIUM` | **RE-GRADED → `CHEAP-to-MODERATE · HIGH`** | Stage-5 D-A gate |
| **#21 provenance** | `PV-D` (unsourced) | **RE-ANCHORED → `PV-A`** against the stalled D3/D5 open decisions | Stage-4 gate |

---

## Open Action-Item Ledger

| id | What | Discharges at | State at Commit 0 |
|---|---|---|---|
| **AI-001** | The File Change Matrix must include `core/specs/domain-token-registry.md` (E5). The Stage-4 FCM predates it | Engineering Commit 0 | **DISCHARGED** — present in § File Change Matrix above |
| **AI-002** | ADR-127 allocated from **mainline** (`git ls-tree -r --name-only origin/main`), re-derived at Commit 0. `check-adr-numbers.py` reads the *worktree* and would PASS on an already-taken number | Engineering Commit 0 | **DISCHARGED** — see § Deviation Log |
| **AI-003** | CIAC-2's method cites the pre-ratification **plural** filename; D-2 renamed it singular. Left stale, the Stage-9 grader greps a nonexistent path and reads it as a **pass** | Engineering Commit 0 | **DISCHARGED** — corrected to `gh-api-convention.md` in CIAC-2 above, with the forward-reference caveat stated |
| **AI-004** | The Stage-9 research-only probe must be **diff-scoped**, not a repo-wide `grep orchestration_pattern = 0` — one occurrence already exists in a test fixture, so the repo-wide form false-fails on day one | Stage 9 | **OPEN** — carried into the #21 AC10 row above |
| **AI-005** | #21 authoring: §3.5 / §5.5 must be **H2**. AC1's `grep '^## '` does not match `### `, and a fenced `## ` inflates the count | Stage 6 (#21) | **OPEN** — carried into § Issue #21 above |
| **AI-006** | Stage 12 MUST invoke `claim-version.sh --stamp-slug 58-task-artifact-lifecycle-and-knowledge`. **Absent the flag the stamping pass is skipped ENTIRELY** and the unresolved token ships into the versioned plan — silently | Stage 12 | **OPEN** — recorded in § Version identity and § Delivery Strategy |
| **AI-007** | CIAC-1's corroborating probe must be **version-independent** — keyed on `RELEASE_LOG` column 2 (the milestone slug), not a version digit | Engineering Commit 0 | **DISCHARGED** — the slug-keyed form is authored into CIAC-1 above, with the anti-pattern named |

All open rows are hard-gated at Stage 13 close.

---

## Deviation Log

Deltas against the Stage-4 plan of record.

| id | What the Stage-4 plan assumed | What was decided / found | Where |
|---|---|---|---|
| **Δ-version-shape** | The plan would carry a literal version (`v4.15`, then `v4.16` per the binding correction), restamped across nine places including CIAC-1's method | **Token-bearing per ADR-092.** Two consecutive literal determinations were lost to concurrent releases in the same session — the second fired the Stage-6 Commit-0 HALT. Chasing a third digit would have raced again; the token removes the surface. CIAC-1's corroborating probe was additionally re-keyed to the milestone slug so it cannot rot | Operator D-Version re-render |
| **Δ-fcm-registry** | 11 paths, without `core/specs/domain-token-registry.md` | **+1 (AI-001).** A value a gate branches on must resolve in the corpus's single lookup surface. `core/specs/` is in neither the named 7-set nor the stage-file set, so the addition **moves neither class trigger** | Stage-5 R-1 |
| **Δ-fcm-hook-evaporates** | #335 carried a conditional `core/hooks/*.sh` plus two allowlist rows, and a conditional secondary `software` domain | **−3 files.** D-3 ratified SKIP-AS-RESIDUAL; the release stays single-domain `governance` and the § 6 new-executable obligation never fires | Collective Review |
| **Δ-doc-path-singular** | `core/standards/gh-api-conventions.md` (**plural**), cited at five places in the plan text | **Singular** — `gh-api-convention.md`, on 6/0 repo precedent (D-2). #335's issue body still carries the plural; that is a body-level staleness for #335's own Engineering to `[ADJUST]`, not a scope change here | Collective Review / AI-003 |
| **Δ-hostbinding-clean** | The §4.1 disposition was expected to need an allowlist entry, on the premise that a `gh api` standard is *"squarely in the detector's signature"* | **Premise empirically wrong.** Check 42 requires a prescriptive marker within ~40 chars of a `gh`/`git` token **outside fenced code blocks**; the real detector run on two authorings of the same semantic content fired **3** findings on the naive form and **0** on the constrained form. **Whether a doc trips Check 42 depends on how it is written, not where it lives.** Classified C2 (substantive, non-invalidating), not C3 | Collective Review |
| **Δ-relog-row-not-counted** | Stage 3 and Stage 4 both counted trigger (b) at **2**, excluding the `RELEASE_LOG` row implicitly | A Stage-5 re-count read the taxonomy **literally** and got **3 of 7** — the named set includes `RELEASE_LOG.md`, the FCM lists it, and the taxonomy states no exclusion for mechanical touches. **R-D ruled NO** and made the exclusion explicit. Both readings were defensible against the text as written, which is exactly why it was ruled rather than left as a one-off judgment | Collective Review |
| **Δ-reversibility** | `EXPENSIVE · MEDIUM`, with the cheap-revert window closing at **this** release's own Stage 13 | **`CHEAP-to-MODERATE · HIGH`**, window closing at the **first task-artifact-class release**. Basis: the branch is declaration-gated and this release takes the deployable path, so no issue's closure state becomes path-dependent | Stage-5 D-A gate |
| **Δ-outcome-claim** | The milestone claimed the release *"proves the path by exercising it on its own two knowledge artifacts"* | **Withdrawn rather than left to fail at Stage 9.** `G-CL3`'s substitution is not executed by a `domain: governance` release. CIAC-1 *as literally written* still holds; the stronger "exercises it" claim did not | Stage-5 D-A gate |
| **Δ-schema-version** | — | `**Schema version:**` **re-derived against mainline at Commit 0**: mainline held **2.10**, so this bump takes **2.11** in a fresh block. The v2.10 block's own append-rather-than-fresh-block instruction is **branch-scoped** (*"the next editor of this block **on this branch**"*) and that branch has merged; the first editor on a new branch re-derives from mainline and takes a number. The instruction is carried forward for the next editor of this branch | Stage-6 Commit 0 |
| **Δ-adr-127** | ADR-127 next-free, with a worktree-vs-mainline trap flagged | **Confirmed and allocated.** Mainline max **ADR-126**, union of `core/ADRs/` + `release/ADRs/` contiguous at `001..126` with no gaps — so 127 is genuinely next-free, not merely unused. Re-derived at Commit 0 | Stage-6 Commit 0 |
| **Δ-commit0-reverify** | The Commit-0 version re-verify is *"load-bearing, not ceremonial"* and a HALT there is expected behavior | **Structurally retired for this release.** The re-verify detects a literal version claimed out from under the plan; a token-bearing plan holds no literal to collide. Its Commit-0 obligation is replaced by the token-count check — a zero there is the failure this release must not ship | Stage-6 Commit 0 |

---

## Deferred Items

*(Populated at Stage 12 / Stage 13 per `deferred-item-tracking.md`. Zero incoming deferred items target this release.)*

---

## Verification Evidence

*(Populated post-merge — see `verification-checklist.md` for format. The **Artifact-Acceptance Record** for #335 and #21 lands in this section in its ADDITIVE mode: the release's own `G-CL3` takes the unchanged deployable path, while `G-CL4` carries the AAR rows recording each artifact's acceptance.)*

---

## Deployment Execution Log

*(Populated during Stage 12 — see `execution-checklist.md`.)*

| Step | Timestamp | Result | Notes |
|------|-----------|--------|-------|
| Pre-execution check | | PASS/FAIL | |
| Merge PR | | PASS/FAIL | |
| Claim version (`claim-version.sh --stamp-slug`) | | PASS/FAIL | **AI-006** — the `--stamp-slug` flag is mandatory; its omission silently skips the stamping pass |
| Tag release | | PASS/FAIL | |
| Skill deployment | | **N/A** | No skill source changed |
| Manifest execution | | **N/A** | Manifest empty |
| State anchor update | | PASS/FAIL | |
| Post-execution verification | | PASS/FAIL | |

---

## Change Description

*(Authored at Stage 6 Phase C1 per `release/governance/RELEASE_PROTOCOL.md` § Change Description Protocol. Operator-facing, pre-merge. Distinct from the user-facing release note authored at Stage 13.)*

### Outcome

The 13-stage pipeline gains a **positive lifecycle state for task-class work**. A release whose deliverable class is declared `task-artifact` now closes on **artifact acceptance** — the artifact exists at its governed path, its acceptance is recorded, and the close completes — without manufacturing a deployment, a `RELEASE_LOG` release row, or a release note. What the operator sees at Stage 13 is one gate spec with a typed branch, and a per-gate record of which of the nine close gates the branch conditions and which it deliberately leaves alone.

Alongside the mechanism, the release ships the two knowledge artifacts whose definition of done that mechanism serves: a K1 standard for the `gh api` typed-vs-raw field discipline, and a K1 discipline doc modelling the multi-agent orchestration design space.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #101 | Stage 13 admits an artifact-acceptance close, conditioned on `G-CL3`/`G-CL4` with seven explicit no-ops; Stage 6 names `deliverable_state: artifact-accepted` as a positive state | *(set at PR assembly)* |
| #335 | The `gh api` typed-vs-raw field discipline is codified as a K1 standard, cross-referenced from the git workflow rules | *(set at PR assembly)* |
| #21 | The orchestration-mechanisms design space is captured as a K1 discipline doc and reconciled against the framework catalog | *(set at PR assembly)* |

### Key decisions

- **D-A:** the typed branch is a `deliverable_type` **value**, consumed as a criterion-body refinement on the existing `G-CL` rows — not a parallel close path, not a new axis, not a new gate ID.
- **D-A.1:** `G-CL3` is conditioned by **class-appropriate terminal-record substitution** (the AAR), not by exemption and not by extending the `RELEASE_LOG` status lattice.
- **D-B / D-2 / D-3:** both new K1 docs resolve §4.1 clean-by-construction with **no allowlist entry**; the #335 doc path is **singular**; hook coverage is **SKIP-AS-RESIDUAL**.
- **D-Version:** the plan is **token-bearing** — bump class `minor`, no digit — after two literal determinations were lost to concurrent releases in a single session.

### Reversibility

**CHEAP-to-MODERATE — HIGH confidence.** `git revert -m 1 <merge-commit>` of the release PR restores prior state with no migration and no backfill. The new branch is declaration-gated and this release resolves `domain: governance`, so it takes the deployable path and no issue's closure state becomes path-dependent. The cheap window closes at the **first task-artifact-class release**, not at this one.

### Downstream impact

- Enables a clean artifact-acceptance close for future research-, analysis-, and codification-class work.
- **Does not yet enable a task-artifact-class *release*** — Stage-12 `G-EX4`/`G-EX5` and the `hub-spoke-bridge.md` Step-4 completion table still hard-require a `RELEASE_LOG` row. That path is unreachable by construction (declaration-gated), and its completion is routed as follow-up (TD-1).
- The `deliverable_type` value space gains a named member; the registry is the single lookup surface a gate branches on.
- No CI engine, no `deploy.sh` check, and no `.skill` package is touched.

### Cross-references

- Release plan: this file
- Milestone: `58-task-artifact-lifecycle-and-knowledge` (179)
- ADR: `release/ADRs/ADR-127-close-class-is-a-declared-deliverable-value-conditioning-one-gate-spec.md`
- User-facing release notes: `release/releases/notes/{{RELEASE_VERSION}}_RELEASE_NOTES.md` (authored at Stage 13 Close per `release/references/standards/release-notes-standard.md`)

---

## Issue References

- #101 — the keystone: a task-artifact close lifecycle that closes on artifact acceptance rather than deployment.
- #335 — codify the `gh api` typed-vs-raw field discipline as a K1 standard.
- #21 — author the orchestration-mechanisms K1 discipline doc.
- #351 — the `deliverable_type` deliverable-domain axis this release's branch reads (closed 2026-06-29; the external dependency, satisfied).
- #1185 — the epic this milestone is a sized slice of (Portability & Distribution).
