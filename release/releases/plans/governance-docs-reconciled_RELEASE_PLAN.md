<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
---
title: Release Plan — governance-docs-reconciled (ten independent governance-surface corrections, coherent by surface rather than by cause)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; concrete number binds at the Stage-12 atomic claim)
milestone: governance-docs-reconciled
release_class: routine
reversibility: CHEAP / Confidence HIGH — every change is prose, spec, schema or generated-corpus text; the one deploy-parity limb is MODERATE
---
# Release Plan — `governance-docs-reconciled`

**Milestone:** `governance-docs-reconciled` (#387) · hub sub-task **#7049** = Stage 4 plan source and the operator decision record · **#7092**–**#7101** = the ten Stage-5 sub-tasks · **#7102** = the Stage-6 Engineering sub-task that authored this file
**Version identity:** **versioned** — bump-class **`minor`**; the concrete `vX.Y` binds only at the Stage-12 atomic claim (ADR-092), so the plan file and the branch stay **slug-primary** while the release is in flight and the Header `**Version**` cell carries the unresolved stamp token rather than a digit.
**Topology:** D-C **SINGLE** — one release branch (`release/governance-docs-reconciled`), one PR, one merge, base `main`; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial** — one Engineering spoke at a time, in Implementation-Sequence order, on the single branch. Force-push on the shared release branch is prohibited, `--force-with-lease` included.
**Release class:** `routine` — declared in the milestone description's `## Release Class` H2 and confirmed at the Stage-4 gate (D-ReleaseClass).

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-05, domain: governance }`

**Domain classification.** Every matrix row is an internal pmo-platform artifact — pipeline specs, K1 standards, a gate schema, skill `references/`, governance prose, and release-corpus records — so the release is **sourcing-exempt (Form X)**. Dominant domain `governance`; the label's `domain:` class resolves the downstream guide at `core/standards/domain-best-practices/governance.md`. Being sourcing-exempt does not make the release domain-less.

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #7049, reconciled to every **Decision Recorded** comment on that sub-task (Procedure 0 entry · plan-approval gate · Procedure 1 scaffold-review · Stage 5 Wave A gate · Stage 5 Wave B gate) and to the ten Stage-5 dispositions (seven designs, three determinate skip-closures). Where a later ratified disposition superseded a Stage-4 assumption, the transcribed section carries the **ratified** value and § Deviation Log records the delta with its authority. Authored at Engineering Commit 0 by the first Stage-6 Engineering spoke (sub-task #7102, card #6396).

---

## Header

| Field | Value |
|---|---|
| **Milestone** | `governance-docs-reconciled` (#387) |
| **Version** | `{{RELEASE_VERSION}}` |
| **Bump Class** | `minor` — the durable determination. It sets the floor and binds no concrete number; the digit binds only at the **Stage-12 atomic claim**, when `claim-version.sh --stamp-slug governance-docs-reconciled` resolves the token above and renames this file into `plans/v<MAJOR>/` (ADR-092). Recomputed at Engineering Commit 0 against freshly-fetched authoritative host state — see § Commit-0 Version Re-Verify Record. |
| **Topology** | **D-C SINGLE** — one branch, one PR, one merge gate |
| **Concurrency posture** | **P0 fully-serial** (operator-ratified at the Stage-4 gate) |
| **Release Class** | `routine` — milestone-declared, confirmed at the Stage-4 gate. G3-10 reads the declaration, not the `default_release_class` fallback. |
| **Differentiation posture** | Engagement density **standard** · Stage 9 review depth **standard** · Stage 5 activation bias **not elevated** · Stage 13 outcome-window **standard** |
| **Size** | **24 pts** across 10 issues · `routine` × 1.0 ⇒ `effective_pts` **24** against a 25 ceiling — **one point of headroom** |
| **Date Created** | 2026-09-05 (Friday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/governance-docs-reconciled` |
| **Baseline pin** | `origin/main` @ `18e3e787fe56efeab50a8f96660cffaa322e9d6c` (`18e3e787`), read 2026-09-05 |
| **PR** | (populated at PR creation — one PR opened after all ten cards land) |

---

## Commit-0 Version Re-Verify Record

The first Engineering spoke under SINGLE topology re-runs the authoritative-version-selection check across the plan-file write and its commit. This release is `versioned`, so every step applies in full and each carries its executed result.

| Step | Result | Evidence |
|---|---|---|
| **1 — refresh authoritative refs** | RAN | `git fetch --tags origin && git fetch origin main` at Commit-0 time. `origin/main` = `18e3e787fe56efeab50a8f96660cffaa322e9d6c`, unmoved from the Stage-4 pin. |
| **2 — recompute next-free for bump-class `minor`** | **`v4.57`** | The host-agnostic allocation rule consuming the adapter's `anchor()` + `claimed_set()`. `claimed_set()` is the union of published Releases, origin tags, and `RELEASE_LOG` rows in DEPLOYED state; `anchor()` = its maximum = **`v4.56`**; the `minor` floor is `(4, 57, 0)`; the walk finds `(4, 57, 0)` free. Corroborated end-to-end by the adapter itself: `claim-version.sh --sha 18e3e787… --bump minor --dry-run` → `dry-run — would claim v4.57 (no tag pushed)`. Any ledger input was read via `git show origin/main:` and never from the worktree copy. |
| **3 — PROCEED / HALT** | **PROCEED** | `v4.57` is **not** in the claimed set (highest origin tag `v4.56`; `v4.57` carries no tag, no published Release, no `RELEASE_LOG` row, no `plans/v4/` file) **and** equals the recomputed next-free. Both conjuncts hold, so the plan file was written. |
| **3b — stamp-manifest assertion** | **exit 0** | `release/tools/claim-version.sh --verify-stamp governance-docs-reconciled` run after the plan file was written and before it was committed. Read-only and network-free; it runs the identical pre-flight the Stage-12 compare-and-swap runs, so this PROCEED rehearses the real claim rather than a lookalike. Verdict line: `verify-stamp OK`. |

**The Stage-4 figure and the Commit-0 figure agree.** That is a result, not an assumption: the Stage-4 reading was taken at `18e3e787` and mainline had not advanced, so the anchor did not move under this plan. The stamp token in the Header is what makes a later move cost nothing.

**Cross-release contention — recorded, not acted on.** The Stage-4 In-Flight Release Roster measured **n=0** siblings at `18e3e787`. That measurement is now **superseded**: `release/external-seam-conduct-binds` opened **draft PR #7174** after the pin. It is a live claimant on the same version sequence — it computes the same next-free `v4.57` from the same anchor. Nothing is broken by that: ADR-092 binds the number only at the Stage-12 atomic claim, and the claim is a compare-and-swap, so whichever release reaches Stage 12 first wins `v4.57` and the other's CAS walks to the next free slot. This plan carries no digit precisely so that outcome is free. Stage 9 Phase A6.6 re-measures the population fresh pre-GO and renders the `CONTENTION-*` verdict; this paragraph is that phase's updated baseline input, never its substitute.

**A second, file-level cross-release edge on the same sibling.** PR #7174 also writes `core/rules/bypass-mode-readiness/_cross-cutting.md`, which this release's card #5893 writes. That fragment feeds the **generated** `core/rules/bypass-mode-readiness.md`, and `deploy.sh` Check 38 is always-enforce on its regeneration freshness. **Whichever of the two releases merges second must regenerate** the composed file after taking the other's fragment change; a merge that lands the fragment without re-running the generator leaves Check 38 red. Recorded here as a Stage-9/Stage-12 obligation (**R-14**), not acted on at Commit 0.

---

## Scope

Ten independent bug fixes against the platform's own governance and pipeline corpus, coherent by **surface** rather than by cause — a Shape-3 audit-driven surface batch. Zero hard dependency edges; four contended files; one PR.

| # | Issue | Title (abbreviated) | Pts | Stage-5 |
|---|---|---|---|---|
| 1 | **#6396** | Procedure 4a step 6's BLOCK rule is unscoped, so a whole-population sweep blocks every close on other releases' debt | S | skip (determinate) |
| 2 | **#6395** | The Parallelization-Map reconfirm query is a broken probe — keyword screen over free prose | S | designed |
| 3 | **#6117** | G3-15 never re-fires on re-classification, so a Stage-4 class change silently moves the size bound | S | designed |
| 4 | **#6421** | Vertical-slice principle is operationalized as a bundle-level dep walk | S | designed |
| 5 | **#5582** | Stage-7 deprecated-path scan is structurally blind to relocations | S | designed |
| 6 | **#6121** | The mandated A8 sandbox override manufactures a false red for at least one suite class | S | designed |
| 7 | **#5594** | The Commit-0 version re-verify has a false-PROCEED window: two authorities, no declared precedence | S | skip (determinate) |
| 8 | **#6215** | `gh api -f body=@file` posts the literal path, so a pipeline PR body becomes a path string | M | designed |
| 9 | **#5890** | Four corpus close-out surfaces still assert a signed tag and GitHub Release that were never created | S | skip (determinate) |
| 10 | **#5893** | Hook layer has no specificity owner: three syntactic rules dominate the firing population | M | designed |

**Composition LOCKED** at Stage-4 entry (2026-09-05). `issues_added` is **0** for every refresh disposition; removals remain legal. The Stage-5 scope policy widened three cards' *write sets* but added no member, so the lock is undisturbed.

**Scope authority.** The milestone description was amended and re-verified at the Procedure 1 scaffold-review gate (D-DescriptionAmendApplied), so description and plan now agree on the ten members and on `Raw 24 pts`. Where they ever diverge, **this plan governs**.

---

## Change Description

Four of the ten cards are themselves defects in **probes** — a query, a scan, a gate, and a sweep that each return a confident wrong answer. The remaining six correct governance prose that has drifted from what the platform actually does. Nothing in this release adds a capability, a component, or an enforcement surface; every change either corrects a false statement or scopes an over-broad one.

Three cross-cutting properties bind the ten:

1. **No new file.** Every design confirmed it explicitly, and #5582 recorded the net-new alternative (`release/tools/check-deprecated-paths.sh`) as **considered and rejected** in favour of extending the governed home. The single ADD in this release is this plan file.
2. **No new gate, criterion, or `G3-` identifier.** #6421 AC-5 grades this directly; #6117 and #5893 each carry a hard constraint forbidding it.
3. **Every null verdict carries a fired control arm.** Four cards' acceptance criteria demand it individually; CIAC-3 makes it a release-level condition.

---

## Dependency Graph

**Hard edges: zero.** Read from the **structured** `blocked-by` / `blocking` fields of all ten members, not from a prose keyword screen — the section-structured read #6395 exists to mandate.

- **PV-0 invocation:** `gh issue view <N>` per member, reading the `blocked-by:` / `blocking:` fields.
- **PV-1 denominator:** 10 of 10 members. The fields are **absent**, not present-and-empty — a distinction that is load-bearing in this bundle specifically, because #6395 is a card about a probe that conflates absence with a negative result.
- **PV-2 sensitivity:** the same extraction returns a populated `parent:` on all ten (#6618 for #6421; #6428 for the other nine) and populated `milestone:` / `labels:`, so the extraction is live and a blank dependency field is a real blank rather than a failed read.
- **PV-3 specificity:** the prose-keyword screen the platform shipped (`blocked by|depends on|requires|after #N`) is deliberately **not** used here — #6395 measures it as false-positive and false-negative by construction, at 142 matches over 550 open issues against a designed form's 19.

Ten isolated nodes. Four **soft** (file-contention) edges, directed only by sequencing choice and never by prerequisite:

- **[A]** #6117 → #6421 on `release/references/standards/bundle-composition-doctrine.md` (§ 3 Step 5 vs § 3 Step 3 — disjoint)
- **[B]** #5582 → #6121 on `release/references/pipeline/stage-07-dev-testing.md` (`:42` vs `:90-92` — disjoint)
- **[C]** #5594 → #6215 on `release/references/how-to/hub-spoke-bridge.md` (`:290-298` vs `:1197` — disjoint, ~900 lines apart)
- **[D]** #5582 → #6395 on `release/governance/release-process.md` (`:529` vs `:343` + `:403` — disjoint, ≥126 lines apart)

Contention is not dependency: any of the ten can be built in any order without a prerequisite failing. These arrows record **merge-safety sequencing under a single branch**.

Edge **[D]** did not exist at Stage 4. It was created by the ratified inclusion of #6395's third site (D-ThirdSiteInclude) and its `:403` widening (D-ScopePolicy E-1), which moved `release-process.md` from a one-claimant file to a two-claimant one. See § Deviation Log **DEV-3**.

---

## Implementation Sequence

Ordering principle, in precedence order: (1) execution-mode constraint first — lead with a card requiring a sanctioned session so a gate failure surfaces at the first spoke rather than the second; (2) contended files adjacent, so a rebase is trivial; (3) largest first within a pair.

| # | Card | Rationale |
|---|---|---|
| 1 | **#6396** | Sanctioned-session batch. Leads so the `pmo-skill-editor` path is proven before nine other cards depend on the branch. |
| 2 | **#6395** | Same sanctioned session — pays the fixed per-session overhead once. Also the larger of the two. |
| 3 | **#6117** | Doctrine pair, larger first (3 files). § 3 Step 5. |
| 4 | **#6421** | Doctrine pair (1 file). § 3 Step 3 — disjoint from #6117's hunk. |
| 5 | **#5582** | Stage-07 pair, and the first claimant of `release-process.md` (`:529`). |
| 6 | **#6121** | Stage-07 pair (`:90-92`) plus the two ratified widenings — disjoint from #5582's hunk. |
| 7 | **#5594** | Bridge pair, determinate remedy (`:290-298`). |
| 8 | **#6215** | Bridge pair (`:1197`). Runs after #5594 so it can cite the settled section. |
| 9 | **#5890** | Contention-free. Four release-corpus files; target wording already exists. |
| 10 | **#5893** | Contention-free, largest, re-scoped. Last so its re-scope has maximum settling time. |

**Sequencing note on `release-process.md`.** #5582 (position 5) claims `:529` and #6395 (position 2) claims `:343` + `:403`. #6395 therefore lands **first** on this file, inverting the Stage-4 assumption that #5582 leads it. The hunks are disjoint by ≥126 lines, so the inversion is immaterial to merge safety; #6395's post-edit assertion **V3** (line 529 byte-identical) is consequently asserted against #5582's *post-state* rather than against the baseline. Recorded so the assertion is not graded against the wrong reference.

---

## Stage Applicability Matrix

Default is all stages. Stage 5 is skipped only for a determinate fix whose remedy the acceptance criteria already state; Stages 7/8 are skipped only for a change with no functional impact — **no member qualifies for a 7/8 skip**, because every card's criteria demand an executed verification.

| Card | S5 | S6 | S7 | S8 | S9 | S10–11 | S12 | S13 | Stage-5 basis |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|---|
| #6421 | **YES** | ✓ | ✓ | ✓ | ✓ | compressed | ✓ | ✓ | Frame-independence plus an explicit boundary statement — a design constraint, not a reword |
| #6396 | skip | ✓ | ✓ | ✓ | ✓ | compressed | ✓ | ✓ | Determinate: scope one sentence to the closing release's slug; both criteria state the remedy |
| #6395 | **YES** | ✓ | ✓ | ✓ | ✓ | compressed | ✓ | ✓ | A section-slicing query plus a control fixture must be designed; two sites must stay byte-identical |
| #6215 | **YES** | ✓ | ✓ | ✓ | ✓ | compressed | ✓ | ✓ | Re-scope settled before build; detector shape undesigned at Stage 4 |
| #6121 | **YES** | ✓ | ✓ | ✓ | ✓ | compressed | ✓ | ✓ | Requires a suite-class taxonomy and a both-arms empirical demonstration |
| #6117 | **YES** | ✓ | ✓ | ✓ | ✓ | compressed | ✓ | ✓ | The card's criterion offered an explicit either/or remedy — a design choice |
| #5893 | **YES** | ✓ | ✓ | ✓ | ✓ | compressed | ✓ | ✓ | A specificity criterion, an owner, and a cadence had to be designed |
| #5890 | skip | ✓ | ✓ | ✓ | ✓ | compressed | ✓ | ✓ | Determinate: target wording already exists in `RELEASE_LOG_ARCHIVE-version-less.md`; reuse rather than invent |
| #5594 | skip | ✓ | ✓ | ✓ | ✓ | compressed | ✓ | ✓ | Determinate: the criteria state which arm binds and which corroborates |
| #5582 | **YES** | ✓ | ✓ | ✓ | ✓ | compressed | ✓ | ✓ | A four-verdict distinguishability rule was undesigned; the deploy-side exclusion had to be specified |

**Parallel-eligible counts — Stage 5: 7 · Stage 7: 10 · Stage 8: 10.** Stages 10–11 compress for a git-native release. Stages 9, 12, 13 are release-scoped (one spoke each). All ten Stage-5 sub-tasks are CLOSED: seven designed, three skip-closed.

---

## Contention Map

**Within-release contention: 4 contended files, 4 pairs, 0 three-way.**

| File | Claimants | Hunks | Class | Resolution |
|---|---|---|---|---|
| `release/references/standards/bundle-composition-doctrine.md` | #6117, #6421 | § 3 Step 5 (`:185`, `:163`) vs § 3 Step 3 (`:132`) | `line-range-overlap` (disjoint) | Sequence #6117 → #6421. **§ 9 (`:387-427`) must remain untouched by both** — graded by CIAC-1. Both append a § 14 Version-History row per that file's own convention. |
| `release/references/pipeline/stage-07-dev-testing.md` | #5582, #6121 | Phase A scan (`:42`) vs A8 gate (`:90-92`) | `line-range-overlap` (disjoint) | Sequence #5582 → #6121. Both edits are referenced from the same Phase A enumeration at `:40` — graded by CIAC-2. |
| `release/references/how-to/hub-spoke-bridge.md` | #5594, #6215 | `:290-298` vs `:1197` | `line-range-overlap` (disjoint, ~900 lines apart) | Sequence #5594 → #6215. The edge is **no longer conditional** — D-BridgeEditIn rendered #6215's bridge edit **IN**. |
| `release/governance/release-process.md` | #5582, #6395 | `:529` vs `:343` + `:403` | `line-range-overlap` (disjoint, ≥126 lines apart) | #6395 lands first by sequence position. **New at Stage 5** — created by D-ThirdSiteInclude and D-ScopePolicy E-1. |

**PV-1 denominator:** 24 edit rows + 1 add row over 21 distinct paths; 4 paths carry more than one claimant. **PV-2 sensitivity:** the same path-frequency count returns 17 single-claimant paths — a non-degenerate distribution, so "4 contended" is a discriminated result rather than a uniform one. **PV-3 specificity:** a deliberately mis-keyed count (grouping by card instead of by path) yields 10 uniform singletons and is distinguishable from the right answer.

---

## Cross-PR Overlap Audit

### Baseline SHA

`origin/main` @ `18e3e787fe56efeab50a8f96660cffaa322e9d6c`, read 2026-09-05. Re-fetched unchanged at Engineering Commit 0.

### In-Flight Release Roster

**Measured at:** Engineering Commit 0, 2026-09-05 · **Population:** n=1 sibling.

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `external-seam-conduct-binds` | #7174 (draft) | (head as of Commit 0) | `minor` | (carried provisional-display) | `v4.57` | `core/rules/bypass-mode-readiness/_cross-cutting.md` |

**This supersedes the Stage-4 roster**, which recorded `none in flight at 18e3e787 / 2026-09-05` with an explicit denominator caveat: total open PRs was 0, so the sensitivity arm did not fire and an empty release-PR population was indistinguishable from an empty PR population generally. The Stage-4 row was honest about resting on a transiently-empty population; the population has since become non-empty, which is exactly the outcome that caveat anticipated. The zero is not retracted as wrong — it is superseded as stale.

**Two contention axes, both recorded and neither acted on here:**

1. **Version slot.** Both releases compute next-free `v4.57`. Resolved by construction at the Stage-12 compare-and-swap; this plan carries the stamp token rather than a digit, so a loss costs a rename and nothing else.
2. **File.** One path intersects: `core/rules/bypass-mode-readiness/_cross-cutting.md`. That fragment feeds the generated `core/rules/bypass-mode-readiness.md`, and `deploy.sh` Check 38 is always-enforce on regeneration freshness — so **whichever release merges second must regenerate**. Tracked as **R-14**.

**Structural-blast-radius sub-audit (Tier-S): no edges.** This release's mover-set is empty — the File Change Matrix carries zero rename, relocate, or delete rows (24 edits + 1 add). With an empty mover-set, `SURFACE(R)` is empty and no `EDITSET(sibling) ∩ SURFACE(R)` intersection is possible.

---

## File Change Matrix

One path per line. `edit` rows are modifications to tracked files; the single `add` row is this plan file. All Stage-4 CONDITIONAL rows are **resolved** — see § Deviation Log.

```
# ── #6396 — Procedure 4a step 6 BLOCK scope ──────────────────────────
release/skills/release-hub/references/orchestration-playbook.md  edit

# ── #6395 — Parallelization-Map reconfirm query ──────────────────────
release/references/pipeline/stage-03-bundle.md  edit
release/skills/release-planner/references/dependency-analysis.md  edit
release/governance/release-process.md  edit

# ── #6117 — G3-15 re-fire on re-classification ───────────────────────
release/references/specs/release-class-taxonomy.md  edit
release/references/standards/bundle-composition-doctrine.md  edit
core/schemas/gate-criteria-spec.md  edit

# ── #6421 — vertical-slice subject (same file as #6117, § 3 Step 3) ──
release/references/standards/bundle-composition-doctrine.md  edit

# ── #5582 — deprecated-path scan relocation blindness ────────────────
release/references/pipeline/stage-07-dev-testing.md  edit
release/governance/release-process.md  edit

# ── #6121 — A8 sandbox suite-class scoping ───────────────────────────
release/references/standards/runtime-suite-selection-map.md  edit
release/references/pipeline/stage-07-dev-testing.md  edit
release/references/pipeline/stage-06-engineering.md  edit
release/references/pipeline/stage-08-qa-testing.md  edit

# ── #5594 — Commit-0 version re-verify binding arm ───────────────────
release/references/how-to/hub-spoke-bridge.md  edit

# ── #6215 — gh api body-posting (re-scoped to AC-3 + AC-4) ───────────
core/standards/gh-api-convention.md  edit
release/references/how-to/hub-spoke-bridge.md  edit

# ── #5890 — tag-claim residue (4 surfaces, 7 live claims) ────────────
CHANGELOG.md  edit
release/releases/RELEASE_DIGEST.md  edit
release/releases/RELEASE_INDEX.md  edit
release/releases/notes/_unversioned/parallel-launch-quota-budget-gate_RELEASE_NOTES.md  edit

# ── #5893 — hook specificity owner (re-scoped) ───────────────────────
core/standards/gate-efficacy-standard.md  edit
core/rules/bypass-mode-readiness/_cross-cutting.md  edit
core/rules/bypass-mode-readiness.md  edit

# ── Release-wide ─────────────────────────────────────────────────────
release/releases/plans/governance-docs-reconciled_RELEASE_PLAN.md  add
```

**24 edit rows + 1 add row over 21 distinct paths. Zero CONDITIONAL rows remain; zero rename, relocate or delete rows.**

### Generated and derived consequences

Three tracked files change in this PR without being hand-authored: each is produced by a named generator, in the same PR as the source edit that causes it. They are stated here as prose rather than as matrix rows **on purpose** — the fenced block above is a machine-read declaration surface, and a row whose intent marker is `GENERATED` or `DERIVED` rather than `edit` is read as an undeclared intent, which is worse than not appearing at all.

- **`core/rules/bypass-mode-readiness.md`** — regenerated from the fragment set; never hand-edited. It **is** a declared matrix row above, under #5893, because regenerating it is a mandatory consequence of that card's fragment edit. `deploy.sh` Check 38 is always-enforce on its freshness.
- **`packages/release-hub.skill`** — rebuilt by `build-skill-packages.sh release-hub`, caused by #6396's `references/` edit. Check 7 is content-resolving, so a merged edit without the rebuild trips the gate on an unrelated later PR (**R7**).
- **`packages/release-planner.skill`** — rebuilt by `build-skill-packages.sh release-planner`, caused by #6395's `references/` edit. Same gate, same reason.

The two `.skill` artifacts are deliberately **not** declared as matrix rows: the matrix declares what Engineering authors, and a build artifact that appears in the diff without a corresponding authored row is expected rather than anomalous. Both are named here so no reviewer reads them as undeclared scope.

### Read-only inputs

```
release/references/standards/triage-design-rereview.md  READ
release/references/standards/bundle-composition-doctrine.md  READ  (§ 9 Sequence Rules — must survive #6421 and #6117 unchanged)
core/config/platform-config.toml.template  READ  (class_weight source for #6117)
core/ADRs/ADR-166-split-predicate-gate-graduation.md  READ  (#6117 — the ADR that forecloses the card's first remedy limb)
core/hooks/block-autonomy-ceiling.sh  READ  (agent-editability derivation)
core/hooks/block-skill-direct-edit.sh  READ  (sanctioned-session gate derivation)
release/releases/RELEASE_LOG_ARCHIVE-version-less.md  READ  (#5890 target wording; correction-record, NOT edited)
```

### Release-wide explicit non-scope

```
core/deploy/deploy.sh  NOT EDITED  (its --diff-filter=D at :4745 is the skill-deploy deletion detector, a different mechanism from #5582's scan; the Check-71 rule-prefix generalization is a #5893 follow-up, not this card)
core/hooks/git-post-merge-deploy.sh  NOT EDITED  (same skill-deploy detector — :115)
core/hooks/block-fs-boundary.sh  NOT EDITED  (Stage-4 CONDITIONAL withdrawn by #5893's design)
core/hooks/block-shell-injection.sh  NOT EDITED  (Stage-4 CONDITIONAL withdrawn by #5893's design)
core/hooks/block-destructive.sh  NOT EDITED  (Stage-4 CONDITIONAL withdrawn by #5893's design)
core/hooks/block-rm-prefer-trash.sh  NOT EDITED  (enters as a named-gap register row only)
core/rules/bypass-mode-readiness/block-fs-boundary.md  NOT EDITED  (Stage-4 CONDITIONAL withdrawn)
core/rules/bypass-mode-readiness/block-shell-injection.md  NOT EDITED  (Stage-4 CONDITIONAL withdrawn)
core/rules/bypass-mode-readiness/block-destructive.md  NOT EDITED  (Stage-4 CONDITIONAL withdrawn)
release/references/pipeline/stage-04-planning.md  NOT EDITED  (#6395 Change 3 CONDITIONAL resolved NO-EDIT; the :160 widening is DEFERRED per D-ScopePolicy)
release/tools/check-deprecated-paths.sh  NOT CREATED  (#5582 considered and rejected the net-new script in favour of extending the governed home)
release/releases/plans/_unversioned/hub-spoke-run-and-planning-discipline_RELEASE_PLAN.md  NOT EDITED  (historical record carrying the #6395 alternation; not a convention site)
```

No `*.sh` **add** row exists, so the `core/config/allowlists/script-execution-allowlist.txt` companion obligation does **not** fire.

---

## Agent-Editability Read

Two cards write under `*/skills/*/references/*.md`, where all three conjuncts of the sanctioned-session gate hold: the path matches `block-skill-direct-edit.sh`'s scope regex; the owning `SKILL.md` carries the `skill_discipline_migrated_v10_2` arming marker; and neither skill appears on the exemption list (which holds exactly one entry). The arming-marker reading discriminates rather than being uniform — 52 of 57 tracked `SKILL.md` files carry it.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Execution path |
|---|---|---|---|---|
| #6396 | `release/skills/release-hub/references/orchestration-playbook.md` | no | **yes** | `sanctioned-session: pmo-skill-editor` (targeted edit) |
| #6395 | `release/skills/release-planner/references/dependency-analysis.md` | no | **yes** | `sanctioned-session: pmo-skill-editor` (targeted edit) |
| #6395 | `stage-03-bundle.md` · `release-process.md` | no | no | ordinary Engineering spoke |
| all others | see § File Change Matrix | no | no | ordinary Engineering spoke |

**The #5893 row is the one worth reading twice.** A careless read floors it — the Tier-0 arms literally name `hooks` and `rules`. They anchor on the **deployed** `${PRIMARY_ROOT}/.claude/` tree; the repo sources at `core/hooks/` and `core/rules/` match no arm, in either the anchored or the membership block. The card is editable by an ordinary spoke. What it does carry is a deploy-parity obligation, recorded as **R6**.

`unconstrained` means no control refuses the write. It never means the change is ungoverned — every member still runs the governed Issue + plan + PR flow.

---

## Risk Register

| ID | Risk | Sev | Reversibility | Mitigation |
|---|---|---|---|---|
| **R1** | Two cards are un-editable by an ordinary spoke; an Engineering spoke would be refused mid-build, after spending its budget reaching the wall | HIGH | CHEAP | Route #6396 and #6395 through `pmo-skill-editor`, batched in **one** session, sequenced **first** so a gate failure surfaces at the first spoke. **Discharged at Engineering Commit 0** — both cards ran through the sanctioned path. |
| **R2** | #6215 would author a duplicate governed home; `core/standards/gh-api-convention.md` § 2 already codifies the mechanism, added three weeks before the card was filed | HIGH | CHEAP | Re-scoped at the Stage-4 gate to AC-3 + AC-4; the design extends the existing standard rather than creating a parallel one. **Discharged.** |
| **R3** | #5582's mechanical sweep would break deploy — `--diff-filter=D` also appears in the skill-deploy deletion detector | HIGH | MODERATE | Explicit non-scope block above. Read → classify → edit per file; never delete-on-match. The design specifies the exclusion. |
| **R4** | #6395 and #5582 named affected files that were wrong or absent, each with a real second site the card omitted | MED | CHEAP | Both bodies corrected at the scaffold-review gate. Rename-reference-cascade discipline: pre-count and post-count every site. **Discharged.** |
| **R5** | #5893's AC-2 conflated a declared warn-log with a populated one; read literally it was already satisfied and the card would ship nothing | MED | CHEAP | Restated as the warn-**mode** posture plus a named owner and cadence. **Discharged.** |
| **R6** | #5893's changes require a deploy to reach runtime; merged-without-deploy leaves repo/runtime drift that reads green in CI | MED | MODERATE | Stage 12 runs `./deploy.sh --deploy` then `--check`; record the Check 9 and Check 38 results in the close-out. |
| **R7** | #6396 and #6395 edit skill `references/`, which package-drift Check 7 covers; a merged edit without a package rebuild trips CI on an unrelated later PR | MED | CHEAP | Rebuild both packages in the same PR: `build-skill-packages.sh release-hub release-planner`. |
| **R8** | Milestone description stale and self-contradictory | MED | CHEAP | Amended and read-back-verified at the scaffold-review gate. **Discharged.** |
| **R9** | Parallelization Map absent on a milestone postdating the convention | LOW | CHEAP | Added at amendment time, carrying #6395's **corrected** anchored query — verified with all three arms before it was written. **Discharged.** |
| **R10** | Quota WARN — worst parallel batch is 10 spokes at Stage 7/8, ~50% of a 5-hour usage window | MED | CHEAP | Two-batch split rendered at the Stage-4 gate. Checkpoint B re-validates at every launch and is the load-bearing gate. |
| **R11** | One point of band headroom — effective 24 against a 25 ceiling. Any re-size upward, or any re-classification away from `routine`, breaches — and #6117 is in this bundle precisely because nothing re-fires the check | MED | CHEAP | Hold the class at `routine`; treat any re-size as requiring a manual `effective_pts` recompute. Composition is LOCKED, so additions are already barred. |
| **R12** | #5890's line numbers have drifted since filing (1374→1500, 450→503, 176→204) | LOW | CHEAP | Locate by content, as the card directs. Target wording already exists — reuse it. |
| **R13** | Seven Stage-5 activations on a `routine` release is heavy for a surface batch and drove the quota WARN | LOW | CHEAP | Recorded, not taken. Stage 5 is now complete; the risk is closed by elapse. |
| **R-14** | **Cross-release regeneration.** PR #7174 also writes `core/rules/bypass-mode-readiness/_cross-cutting.md`; `deploy.sh` Check 38 is always-enforce on the generated composite's freshness | MED | CHEAP | Whichever release merges **second** regenerates `core/rules/bypass-mode-readiness.md` after taking the other's fragment. Verified at Stage 9 A6.6 and again at Stage 12 pre-merge. |

**Rollback strategy.** One PR, merged with a two-parent merge commit (plain `gh pr merge --merge`), so `git revert -m 1 <merge-sha>` restores prior state for all ten cards in one operation. Every change is prose, spec, schema, or generated-corpus text. **Reversibility: CHEAP overall; MODERATE for the #5893 limb**, which additionally requires `./deploy.sh --deploy` after the revert to restore runtime/repo parity — a revert alone leaves the deployed hooks and rules mirror ahead of the repo. No data migration. No version-tag implication: the tag is claimed at Stage 12 and a rollback **retains** it per tag-retention policy — the withdrawal is recorded, the tag is not deleted.

---

## Cross-Issue Acceptance Criteria

Three release-scoped predicates. Each spans two or more issues with no dependency edge required, and each is graded at Stage 9 QC3.5 on the merged PR.

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#6421 × #6117 on `release/references/standards/bundle-composition-doctrine.md`):** **zero hunks in § 9 (lines 387–427); every other hunk within § 3 (lines 98–204) or § 14 (lines 616–624).** *Method:* `git diff --unified=0 18e3e787..<head> -- release/references/standards/bundle-composition-doctrine.md` — read each hunk header's line range against the § 9, § 3 and § 14 offsets. *Null expectation carries its arms:* zero hunks in § 9 · **control:** the same invocation must return **at least one** hunk within § 3 (non-zero observed), proving the diff reaches the file rather than resolving an unchanged or missing path. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#5582 × #6121 on `release/references/pipeline/stage-07-dev-testing.md`):** after both land, the single Phase A enumeration at `:40` still names both amended checks and each name still resolves to a defining sub-section in the same file — neither edit orphans the other's cross-reference. *Method:* `grep -nE 'deprecated-path scan|A8 Runtime-Suite Gate' release/references/pipeline/stage-07-dev-testing.md` — assert at least two distinct line numbers for each phrase (one in the `:40` enumeration, one at its defining sub-section). *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#5890 × #5582 × #6395 × #6215 on the release's Verification Evidence):** four cards carry a criterion demanding a control arm. After the release lands, **every** null, zero, or absent verdict recorded for these four carries a named control invocation run on the same instrument against the same target, with a non-zero observed result. *Method:* named read of the Stage-7 and Stage-8 Verification-Evidence blocks for #5890, #5582, #6395 and #6215 — for each null verdict, assert the presence of a `control:` clause naming an invocation and its observed non-zero result. A verdict of zero with no fired control arm is **NOT MET**, not PARTIAL. *Graded at Stage 9 QC3.5 on the merged PR.*

**The first criterion above carries an amendment, and the amendment is the point.** As authored at Stage 4 the predicate asserted *"every diff hunk in this file lies within § 3"*. Both accepted doctrine designs add a `## 14. Version History` row, which is that file's own evidenced convention — three `—`-versioned precedents at `:622`–`:624`. The predicate therefore over-reached, and the criterion's own **Method** measured only the § 9 half, so predicate and method already disagreed before any code was written. The operative form above was ratified at the Stage-5 Wave B gate (**D-CIAC1Amend**) to match the Method. The protective intent — § 9's layer-ordered Sequence Rules survive untouched, which #6421's own AC-3 exists to guarantee — is preserved exactly, and the control arm is unchanged.

**The third criterion is the one to defend if challenged:** this bundle is four-tenths probe-defect cards, and a release that fixes broken probes while recording its own results on unarmed probes would have failed on its own terms.

*(Both paragraphs above deliberately refer to the criteria by position rather than by a bolded identifier. The machine reader for this section treats a bolded identifier at the head of a line as the start of a new entry, so naming them that way in commentary would inject phantom entries into the parsed set — which is precisely the class of defect this release exists to correct.)*

---

## Verification Plan

### AC baseline

Per-issue acceptance-criterion counts **as read at Engineering Commit 0**, against `origin/main` @ `18e3e787fe56efeab50a8f96660cffaa322e9d6c`:

`#6421 = 5 · #6396 = 2 · #6395 = 2 · #6215 = 4 · #6121 = 4 · #6117 = 4 · #5893 = 6 · #5890 = 6 · #5594 = 3 · #5582 = 4` — **40 criteria total.**

This is a pinned measurement and carries no verdict. It is **unchanged from the Stage-4 baseline**, per-card and in total, which is the useful fact: six card bodies were amended between Stage 4 and Stage 5, and none of those amendments changed a criterion **count**. The ordinal references below are therefore stable against the Stage-4 reading. A count that later diverges from this line is a mechanical signal to re-bind, not a verdict.

### Per-Issue Verification

One row per criterion, in criterion order. The `AC` cell holds an identifier only; the `Verification Method` cell holds a reproducible probe, never a paraphrase of the criterion.

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #6421 | AC-1 | `grep -c 'to deliver end-user observable change' release/references/standards/bundle-composition-doctrine.md` and a named read of § 3 Step 3 for the discovery framing | Value clause present in Step 3 (count rises from 1 to 2); discovery framing present; conformance re-pointed at Step 1 |
| #6421 | AC-2 | `grep -c 'skill-core' release/references/standards/bundle-composition-doctrine.md` restricted to the amended § 3 Step 3 region, repeated for `foundation` and `infrastructure` | 0 occurrences in the amended region · control: the same three terms over the whole file return non-zero (the taxonomy is defined elsewhere in it), proving the probe reaches the corpus |
| #6421 | AC-3 | `git diff --unified=0 18e3e787..HEAD -- release/references/standards/bundle-composition-doctrine.md`; assert no hunk header is present whose range falls inside § 9 (`:387-427`) | 0 hunks present in § 9 · control: at least 1 hunk present in § 3 (`:98-204`), proving the diff reaches the file |
| #6421 | AC-4 | `git diff 18e3e787..HEAD -- release/references/standards/bundle-composition-doctrine.md` filtered to the § 3 Step 3 Output line and its five discovery bullets; assert no such line is present in the diff | Those six lines absent from the diff, i.e. byte-identical to baseline · control: the same diff is non-empty elsewhere in § 3, proving it reaches the file |
| #6421 | AC-5 | `grep -coE 'G3-[0-9]+' release/references/standards/bundle-composition-doctrine.md` at baseline and at head, comparing the distinct sets | Both sets equal `{G3-07, G3-10, G3-12, G3-15}` · control: the extractor returns 4 distinct identifiers present at baseline, so an empty post-set would be a dead reader rather than a pass |
| #6396 | AC-1 | `grep -c 'attributable' release/skills/release-hub/references/orchestration-playbook.md` plus a named read of § Procedure 4a step 6 | The BLOCK sentence names attribution to the closing release's slug; the unscoped sentence is absent · control: `grep -c 'BLOCKS close'` is non-zero at baseline, proving the probe reaches the file |
| #6396 | AC-2 | Named read of the same step for the disposition of whole-population findings; `grep -c 'reported' release/skills/release-hub/references/orchestration-playbook.md` | Prior-release findings present as reported and explicitly non-blocking |
| #6395 | AC-1 | `grep -c 'Dependencies' release/references/pipeline/stage-03-bundle.md` and the same on `release/skills/release-planner/references/dependency-analysis.md`, then a byte-comparison of the canonical block extracted from both | Slicer present at both sites, keyed on a `Dependencies` heading at level 2 or 3 and terminating at the next heading; the two extractions byte-identical · control: an extraction of the legacy text differs, proving the comparator discriminates |
| #6395 | AC-2 | Reproduction-and-observe: run the canonical block against the two-arm fixture — the dependency phrase inside a `### Dependencies` block, then outside it | in-section → `EDGE`; out-of-section → not matched. Both arms observed at Stage 5 across 27 fixtures with 0 failures |
| #6215 | AC-1 | `grep -rc 'body=@' release/tools core/deploy` and a named read of every `gh api` invocation that sets a `body` field | 0 call sites present using `-f` with an `@`-prefixed value · control: the sensitivity arm `-F body=@` returns 7 over the same 2006-file denominator, so the zero is a real absence rather than a dead reader |
| #6215 | AC-2 | Reproduction-and-observe: post a two-line body to a scratch artifact through the fixed path, retrieve it, and compare | Retrieved body equals the file contents; line count 2, not 1 |
| #6215 | AC-3 | `grep -c 'call site' core/standards/gh-api-convention.md` to confirm both § 2.1 predicates are present, then run each against its seeded fixture and its negative fixture | Both predicates present. Seeded `-f body=@x` flagged; legitimate `-f` on a non-`@` scalar not flagged. Each predicate discloses its own denominator and both arms fire |
| #6215 | AC-4 | `grep -c 'depersonalization' core/standards/gh-api-convention.md` plus a named read of the surrounding clause | An explicit scope statement present, stating the true scope of PR and issue bodies; no implied coverage |
| #6121 | AC-1 | `grep -c 'hermetic' release/references/standards/runtime-suite-selection-map.md` plus a named read of § 3 | Both the valid-for and not-valid-for suite-class lists present and disjoint · control: `grep -c 'Sandbox'` is non-zero at baseline, proving the probe reaches the file |
| #6121 | AC-2 | Reproduction-and-observe: execute the identified suite under `HOME=$(mktemp -d)` and again without it, recording both | Fails under the override (`ModuleNotFoundError: No module named 'pytest'`), passes without it. Both results recorded — the defect is shown, not described |
| #6121 | AC-3 | Reproduction-and-observe: follow the amended map literally against the named suite class and record the verdict a reviewer would reach | No false Blocker producible for the named class |
| #6121 | AC-4 | `grep -c 'self (per' release/references/standards/runtime-suite-selection-map.md` and a named read of every `Sandbox` cell whose value is not the override | Every skip states what replaces it, present in the cell; no cell leaves a skipped sandbox silently equivalent to a satisfied one |
| #6117 | AC-1 | `grep -c 'effective_pts' release/references/specs/release-class-taxonomy.md` plus a named read of the Re-Classification Protocol `### Mechanics` | The recomputed value and its band disposition present at the moment of re-classification, not at a later stage's incidental discovery · control: the term is non-zero in `bundle-composition-doctrine.md` at baseline, proving the probe reaches the corpus |
| #6117 | AC-2 | Reproduction-and-observe, both arms: run the recompute on an in-band re-classification and on a breaching one | In-band → no finding; breaching → a finding. A check that cannot be made to fire has not been shown to work |
| #6117 | AC-3 | `grep -c 'size bound' release/references/specs/release-class-taxonomy.md` plus a named read of the Protocol | Statement that a class change alters the size bound present, and the recording location for the recomputed disposition named |
| #6117 | AC-4 | `grep -c 'release_class_capacity_weights' release/references/specs/release-class-taxonomy.md` and the same for `release_size_target_pts` | Both field names present, and identical to the fields G3-15 reads, so the modelled target and the enforced bound remain single-source |
| #5893 | AC-1 | `grep -c 'cadence' core/standards/gate-efficacy-standard.md` plus a named read of the block-log clause | Owner named and cadence stated, both present · control: `grep -c 'sensitivity'` is non-zero at baseline, proving the probe reaches the file |
| #5893 | AC-2 | `grep -c 'warn' core/rules/bypass-mode-readiness/_cross-cutting.md` plus a named read of each of the three rules' posture declarations | Each of the three present in, or confirmed already in, a warn-mode posture with owner and cadence named |
| #5893 | AC-3 | `grep -c 'denominator' core/rules/bypass-mode-readiness/_cross-cutting.md` plus a named read of the recorded triage | Each sampled firing classified true-positive, benign-shape or mandated-tool-blocked, with its denominator present |
| #5893 | AC-4 | `grep -c 'specificity' core/standards/gate-efficacy-standard.md` | Specificity criterion present alongside the sensitivity criterion · control: the sensitivity criterion is present at baseline (non-zero), so a zero on the new one is a real absence rather than a dead reader |
| #5893 | AC-5 | `grep -c 'flip register' core/rules/bypass-mode-readiness/_cross-cutting.md` plus a named read of the disposition | Any benign-shape-dominated rule narrowed to a semantic predicate or moved to warn, with the decision present in the flip register |
| #5893 | AC-6 | `grep -c 'Control firings' core/standards/gate-efficacy-standard.md` plus a named read of the agent instruction | Threshold and reporting channel both present and named |
| #5890 | AC-1 | `grep -c 'no tag' release/releases/RELEASE_DIGEST.md` and per-occurrence inspection of the 7 live claims across the 4 named files against the phrasing landed in `RELEASE_LOG_ARCHIVE-version-less.md` | All 7 corrected to the version-less no-tag / no-Release form, reusing the landed phrasing |
| #5890 | AC-2 | `grep -c 'version-less' release/releases/RELEASE_DIGEST.md` plus a named read of the precedent sentence | It places this release with the five named version-less precedents; no tag-and-Release-bearing distinction present |
| #5890 | AC-3 | Re-run the residue `grep` probe over all tracked files with `git ls-files` as the denominator, inspecting each hit per-occurrence | 0 live claim occurrences present · the `RELEASE_LOG_ARCHIVE-version-less.md` correction-records excluded by inspection, not by a file-level filter · control: see AC-4 |
| #5890 | AC-4 | Run both control arms of the residue `grep` probe: a sensitivity arm matching the corrected form, and a dead arm on a fabricated claim shape | Sensitivity arm returns non-zero, proving reach; dead arm returns 0. A bare zero without a fired sensitivity arm grades NOT MET |
| #5890 | AC-5 | Reproduction-and-observe: `git ls-remote --tags origin` and `gh release view parallel-launch-quota-budget-gate`, each with a live control | No non-`v`-prefixed tag; Release not-found · controls: a known-present tag and `gh release view v4.35` each return their positive result |
| #5890 | AC-6 | `git diff 18e3e787..HEAD` over the four files; assert no altered line is present that carries an `#N` token, a tag name or a merge SHA | 0 such tokens altered; edits insert and remove prose only |
| #5594 | AC-1 | `grep -c 'tag arm' release/references/how-to/hub-spoke-bridge.md` plus a named read of the amended step 3 | The tag arm present and named as the binding authority · control: `grep -c 'claimed set'` is non-zero at baseline, proving the probe reaches the file |
| #5594 | AC-2 | `grep -c 'corroborat' release/references/how-to/hub-spoke-bridge.md` plus a named read of the same step | The ledger present as corroborating and never authorizing, so a lagging ledger row cannot produce a false PROCEED |
| #5594 | AC-3 | Reproduction-and-observe, both arms: run the procedure's decision against a genuinely free version and against one already claimed by tag | Free → PROCEED; claimed → HALT. Both arms observed |
| #5582 | AC-1 | Reproduction-and-observe: construct a branch that `git mv`s a referenced file and run the amended scan | The old path is reported · control: the baseline selector on the same fixture prints nothing and `--diff-filter=DR` prints the rename destination — both wrong answers, proving the fixture discriminates |
| #5582 | AC-2 | Reproduction-and-observe: run the amended scan against a genuine deletion fixture | The deleted path is still caught. Both arms run, not just the new one |
| #5582 | AC-3 | Reproduction-and-observe: exercise the four-verdict rule against each of its four states, asserting every verdict discloses `denominator: <N>` | Empty range → Blocker; rename rows present while the selector is blind → the distinguishing verdict; all four verdicts distinct, each disclosing its denominator |
| #5582 | AC-4 | `grep -c 'relocation' release/references/pipeline/stage-07-dev-testing.md` plus a named read of the amended stage reference | Deletion and relocation both present and named as the change classes the scan covers |

### Stage-6 C4 self-verification — the plan graded against itself at Commit 0

`release/tools/verify-release-plan.sh` was run against this file at Engineering Commit 0. **The result is recorded with its counts rather than summarized as a verdict**, because a plan authored *before* its implementation cannot grade green and saying so is the point.

**13 PASS · 19 FAIL · 7 SKIP · 10 ERROR, over 40 indexed per-issue rows · 3 CIAC entries · 4 provenance checks.**

Read each band for what it actually means here:

- **The 19 FAIL rows are "not built yet", not "wrong".** The executor runs each `grep` probe against the working tree, and the amended text those probes look for is what the ten Engineering slices are about to write. A probe for `attributable` in `orchestration-playbook.md` returns 0 today **by construction**. These rows are graded at Stage 7 and Stage 8, against a tree where the edits exist. A pre-implementation plan whose content probes all passed would be asserting that the release had nothing to do.
- **The 13 PASS rows are the ones whose token already exists at baseline** — mostly control arms and existing-surface reads. They confirm the probes reach the corpus, which is the property a null verdict needs and the reason the arms are written down.
- **The 7 SKIP rows** are `git`-invoking probes routed outside the executor's allowlist (their mechanical guarantee belongs to that tool's own self-test) plus the deferred-delta provenance limb, which has no producer surface to compare against at Commit 0.
- **The 10 ERROR rows are a named residual, and they are all one class:** every one is a `Reproduction-and-observe` method — execute the thing, observe both arms. The executor classifies a method by keyword and recognizes no token for that class, so it emits `unclassified-method (no family match)` and calls that honest in its own source: it cannot tell what such a row is asking for. These are **declared methods whose executor is not yet built**, which the AC→method mapping standard admits explicitly — declaration is what makes the criterion honest at planning time; building and running the executor is a separate, later concern. They are not deferred, not dropped, and not rewritten into a lookalike `grep` that would grade green while testing nothing. **The count is 10 and this line is the record.**

Two mechanical results are load-bearing and both are clean: **zero** table-row parity errors, unindexable tables, or empty method cells — so no row was silently dropped — and the Cross-Issue section parses to **exactly 3** entries. The second was not clean on the first run: two explanatory paragraphs in that section began with a bolded criterion identifier, which the parser reads as the head of a new entry, and they injected two phantom entries into the parsed set. They were reworded to refer to the criteria by position. That defect is worth recording rather than quietly fixing, because it is the same shape as the four probe defects this release exists to correct — a reader saw three criteria, the machine saw five, and nothing announced the difference.

**Limb 2 honesty note.** Every null expectation above names a control arm on the same instrument against the same target. Nothing today mechanically enforces that: the executor that grades per-issue rows receives the expected-result cell and does not read it, so a conforming control arm, a fabricated one, and no arm at all all produce the same verdict. The arms above are the rule an author was asked to follow, and a human reader can check them — they are not evidence that a null verdict *was* checked. CIAC-3 is what converts the obligation into a graded release-level predicate for the four cards where it matters most.

---

## Delivery Strategy

Single branch `release/governance-docs-reconciled` off `origin/main` @ `18e3e787`. Ten Engineering slices land serially in Implementation-Sequence order, each as one or more coherent commits pushed as they complete. **One PR**, opened after all ten cards land, transitioned to ready-for-review at the Stage-9 gate.

Two skill `references/` paths route through a sanctioned `pmo-skill-editor` session, batched together at sequence positions 1–2 so the fixed per-session overhead is paid once and a gate failure surfaces at the first spoke rather than the ninth.

---

## Quota Budget

**Verdict:** **WARN** (Checkpoint A)
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: **7** · Stage 7: **10** · Stage 8: **10**
**Per-spoke cost estimate:** ~5% of a 5-hour usage window per spoke (size-bucket band, heuristic pending telemetry medians). The bundle is 8 × S + 2 × M, so the band's low end dominates and 5% is the conservative read.
**Assumed/stated remaining usage-window envelope:** conservative default — a full 5-hour window. The operator stated no quota position at hub start.
**Estimated cumulative draw % (worst parallel batch):** 10 spokes × ~5% = **~50%** (Stage 7 or Stage 8 fan-out, whichever runs widest).
**Routing:** WARN → window-aware launch timing plus quota-budgeting by split batch. **Rendered:** two batches of five, cleaved so no batch holds both claimants of a contended file. Stage 5 ran under that posture (Wave A = #6117, #5582, #6395, #6215; Wave B = #6421, #6121, #5893) and is complete.
**Note:** Checkpoint B re-validates at **every** launch — wave or singleton, every stage — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton. Checkpoint B also gates on a second axis these fields deliberately do not carry: the host-API quota pools, read at runtime and combined DEFER-dominant. Checkpoint A stays usage-window-only, because a plan-time pool reading has no predictive value at Engineering time. Bands, cumulative-draw budget and host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

This estimate is **advisory**. It sizes a cumulative draw against a usage window; it is not a rate-limit or stagger problem, and staggering launches would not reduce the number computed above.

---

## Release Class Declaration

`routine` — declared in the milestone description's `## Release Class` H2, so G3-10 reads the declaration rather than the `default_release_class` fallback.

Trigger-condition evidence: ten independent point corrections, coherent by **surface** (Shape 3, audit-driven batch) rather than by cause; no new capability; no architectural reshaping; zero cross-milestone dependencies. No `novel` trigger fires — the release is pipeline-internal and sourcing-exempt, so there is no unfamiliar domain. No `cross-cutting` trigger fires — blast radius is per-card, and the only multi-layer member, #5893, narrowed under its re-scope from seven conditional write targets to three edits. No `hotfix` trigger.

**One caution, and it is this release's own subject matter.** `effective_pts = round_half_up(24 × 1.0)` = **24** against a 25 ceiling — one point of headroom. Re-classifying to `cross-cutting` would yield `round_half_up(24 × 1.3)` = **31**, a six-point breach — and **#6117 is in this very bundle precisely because nothing re-fires G3-15 on a re-classification.** If the class is changed at any later stage, the recompute is manual, and this line is the record that it was foreseen.

---

## Operator Decisions (recorded)

Rendered at the Stage-4 plan-approval gate, the Procedure 1 scaffold-review gate, and the two Stage-5 design gates. Each is transcribed with the value that governs Engineering.

| ID | Decision | Rendered | Reversibility |
|---|---|---|---|
| **D-Version** | What version this release claims | `{{RELEASE_VERSION}}` — bump-class `minor`, rule-determined, recorded not gated. Re-verified at Commit 0. | CHEAP · HIGH |
| **D-ReleaseClass** | Release class | **CONFIRM `routine`** | CHEAP · HIGH |
| **D-Concurrency** | Concurrency posture | **P0 fully-serial** | CHEAP · HIGH |
| **D-C Branch Topology** | Branch topology | **SINGLE** — one branch, one PR, plan file as Engineering Commit 0 | CHEAP · HIGH |
| **D-PlanApproval** | Stage 4 release plan + Release Outcome Statement | **APPROVE** | MODERATE · HIGH |
| **D-DescriptionAmend** | Milestone description amendment | **Hub drafts → operator approves → PATCH, before Engineering Commit 0** | CHEAP · HIGH |
| **D-TierOneAdjust** | Four `re-scope-changed` body corrections | **Confirm all four; #6215 RE-SCOPED, not dropped** | CHEAP · HIGH |
| **D-QuotaPosture** | Stage-5 wave posture | **Two-batch split**, cleaved so no batch holds both claimants of a contended file | CHEAP · MEDIUM |
| **D-DescriptionAmendApplied** | Milestone description reconciliation | **APPROVED and APPLIED**, carrying the **corrected** anchored query in the Parallelization Map rather than the convention's defective text | CHEAP · HIGH |
| **D-ScaffoldReview** | Procedure 1 scaffold | **APPROVE — route to Stage 5** | MODERATE · HIGH |
| **D-QueryCorrection** | The falsified reconfirm query in the milestone description | **Swap to #6395's designed form**, plus `--limit 500` | CHEAP · HIGH |
| **D-WaveADesignAccept** | Four Wave-A Stage-5 designs | **Accept all four** | MODERATE · HIGH |
| **D-BridgeEditIn** | #6215's conditional `hub-spoke-bridge.md:1197` edit | **IN** — contention edge `[C]` stands | CHEAP · HIGH |
| **D-ThirdSiteInclude** | #6395's `release-process.md:343` third site | **Include with explicit fencing** | MODERATE · MEDIUM |
| **D-CIAC1Amend** | CIAC-1's falsified predicate | **Amend to match its own Method** | CHEAP · HIGH |
| **D-ScopePolicy** | Eight outstanding scope widenings | **Include only contradiction-causers** — five IN; E-3 and the offered ADR DEFERRED | MODERATE · MEDIUM |
| **D-WaveBAccept** | Four Wave-B designs | **Accept all four; amend the five declined criteria** | MODERATE · HIGH |
| **D-HookDriftDeploy** | Live `block-destructive.sh` repo↔runtime drift | **Operator runs `./deploy.sh --all`**; hub verifies byte-identity after | MODERATE · HIGH |

### Release scope policy — stated once so the next discovery answers itself

> **Include a widening only where this release's own change makes an adjacent line FALSE.**

| Site | Owner | Disposition | Basis |
|---|---|---|---|
| `release/governance/release-process.md:403` | #6395 | **IN** | The `:343` change causes the contradiction — `:343` would describe a section-scoped classifier while `:403` still says "regex-grep over issue bodies" |
| `release/skills/release-planner/references/dependency-analysis.md:65` | #6395 | **IN** | The identical claim at `:73` is already being rewritten; leaving `:65` leaves the file self-contradictory |
| `release/references/pipeline/stage-06-engineering.md:71` and `:127` | #6121 | **IN** | Both restate the A8 sandbox mandate and become false once the selection map's § 3 changes |
| `release/references/pipeline/stage-08-qa-testing.md:174` | #6121 | **IN** | Quotes the selection map's Row 3 `Sandbox` cell verbatim and goes stale on the same change |
| `release/references/pipeline/stage-04-planning.md:160` | #6395 | **DEFERRED** | A third file, no measured contention, and not a contradiction this release creates |
| An offered ADR on over-firing as a content-assertion failure | #5893 | **DEFERRED** | Offered rather than assumed; nothing in the design depends on it |

`issues_added` remains **0** — this widens write sets, it adds no member, so the Composition Lock is not disturbed.

### Acceptance criteria reconciled at Stage 5 — five cards

Five of seven designs declined their card's acceptance criterion as literally written, each on evidence the hub independently verified. Rather than let Stage 8 grade designs while the cards say something else, each declined criterion was amended to what the design will deliver:

| Card | Criterion | Reconciled to |
|---|---|---|
| #6117 | AC-1 | The disjunction's first limb — re-firing G3-15 over live backlog state — is ADR-166's rejected alternative A3, the alternative that ADR exists to rule out, with the live half held permanently advisory. The surviving limb stands alone |
| #5582 | AC-3 | A four-verdict distinguishability rule; the literal "empty population + non-empty range ⇒ FAIL" would fail every edit-only release |
| #6215 | AC-3 | Two predicates — call site and artifact body — neither of which can see the other; both canonicalized in `gh-api-convention.md` § 2.1 |
| #6395 | AC-1 | H2-**or-H3** slicing; measured H2 = 50, H3 = 127, none = 373 over 550 open issues |
| #6421 | AC-1 | Restore the truncated value clause, name Step 3 as discovery, re-point conformance at Step 1 — with a discrimination arm |

---

## Deviation Log

Ratified deltas between the Stage-4 plan of record and what Engineering builds. The Stage-4 position is preserved above wherever it still reads true; this table records where it does not.

| ID | Stage-4 position | Ratified delta | Authority |
|---|---|---|---|
| **DEV-1** | CIAC-1: *every diff hunk in this file lies within § 3* | Zero hunks in § 9 (`:387-427`); every other hunk within § 3 (`:98-204`) **or § 14 (`:616-624`)**. Both doctrine designs add a § 14 Version-History row per that file's own convention | D-CIAC1Amend |
| **DEV-2** | Three contended files | **Four** — `release/governance/release-process.md` joins, claimed by #5582 (`:529`) and #6395 (`:343` + `:403`) | D-ThirdSiteInclude + D-ScopePolicy |
| **DEV-3** | Three soft contention edges [A] [B] [C] | **Four** — edge [D] (#5582 → #6395 on `release-process.md`) is new | Consequence of DEV-2 |
| **DEV-4** | #6215's `hub-spoke-bridge.md:1197` edit CONDITIONAL | **Unconditional — IN.** Edge [C] stands rather than dissolving | D-BridgeEditIn |
| **DEV-5** | #6395 writes `stage-04-planning.md` CONDITIONAL | **NOT EDITED.** Change 3's conditional resolved NO-EDIT; the separate `:160` widening is DEFERRED | #6395 Stage-5 design + D-ScopePolicy |
| **DEV-6** | #5893 writes 1 unconditional + 6 CONDITIONAL paths (three hooks, three rules fragments) | **3 edits.** All six conditionals **withdrawn**; `core/rules/bypass-mode-readiness/_cross-cutting.md` and the generated `core/rules/bypass-mode-readiness.md` added instead | #5893 Stage-5 design, accepted at D-WaveBAccept |
| **DEV-7** | #6121 writes 2 paths | **4 paths** — `stage-06-engineering.md` and `stage-08-qa-testing.md` added as contradiction-causers | D-ScopePolicy |
| **DEV-8** | #6117 writes `bundle-composition-doctrine.md`, `gate-criteria-spec.md`, `release-class-taxonomy.md` | Unchanged in membership; the design additionally fixes seven hard constraints on the shared doctrine file (Check 73 conjuncts C73-b and C73-c, the § 9 prohibition, the frontmatter `version:` freeze) | #6117 Stage-5 design |
| **DEV-9** | In-Flight Release Roster: **n=0** siblings at `18e3e787` | **n=1** — `external-seam-conduct-binds` (draft PR #7174) opened after the pin. Two contention axes recorded: the version slot, and `core/rules/bypass-mode-readiness/_cross-cutting.md` | Commit-0 re-measurement; recorded as R-14 |
| **DEV-10** | Implementation Sequence assumed #5582 leads `release-process.md` | #6395 (position 2) lands the file before #5582 (position 5). Hunks disjoint by ≥126 lines; #6395's assertion V3 is graded against #5582's post-state | Consequence of DEV-2 |

---

## Non-coverage — what this release does NOT deliver

- **`release/references/pipeline/stage-04-planning.md:160`** carries the same stale "regex-grep over issue bodies" framing #6395 corrects elsewhere. DEFERRED under the scope policy: it is a third file, carries no measured contention, and is not a contradiction this release creates.
- **An ADR on over-firing as a content-assertion failure** was offered by #5893's design and deferred. Nothing in the accepted design depends on it.
- **`release/releases/plans/_unversioned/hub-spoke-run-and-planning-discipline_RELEASE_PLAN.md:116`** carries the same broken alternation #6395 fixes. It is a historical release-plan record, not a convention site, so it is correctly out of scope — a future reader grepping for the pattern will find a third hit that should not be "fixed."
- **Back-population of already-written milestone descriptions.** The reconfirm-query defect shipped in every milestone description written under the previous convention. Correcting the convention sites does not retroactively repair those descriptions.
- **PR #6190's corrupted body**, the artifact that motivated #6215, remains as-is. The card defers this to the operator; the edit history is retained by the host, so an in-place edit would not erase the original.
- **The path-leak primitive's blindness to the harness path form** (`-Users-<name>-Claude`), surfaced as OOS-1 during #6215's design. Real, measured, and outside this release's scope.
- **`deploy.sh` Check-71 rule-prefix generalization**, surfaced by #5893's design as a follow-up rather than part of this card.

---

## Verification Evidence

Populated by Stage 6 self-verification (C4), Stage 7 dev testing, and Stage 8 acceptance review. Each per-issue block records the criterion identifier, the invocation run, and the observed result — with a fired control arm alongside every null, zero, or absent verdict, per CIAC-3.

*(Populated during execution.)*

---

## Deployment Execution Log

Populated at Stage 12. Must record, at minimum: the atomic version claim and the tag it resolved; `./deploy.sh --deploy` followed by `--check`; and the **Check 9** (rules-mirror sync), **Check 38** (generated `bypass-mode-readiness.md` freshness) and **Check 7** (package drift) results, per R6, R-14 and R7.

*(Populated at Stage 12.)*

---

## Closure Posture

All ten members remain `status: bundled` through Engineering. Ticket state changes at Stage 13, via the Issue References block of the release PR body — each member is **marked as closed at Stage 13**, and no close-family verb appears beside an issue reference anywhere in this plan or in its transcription into the PR body.
