## Stage 4 Release Planning — 16-knowledge-management-discipline

### Summary (30 seconds)

6 open issues in two independent tracks. **Track A — memory-architecture cluster (#1073→#1074→{#1075,#1076,#1077}):** generalizes the already-shipped `knowledge-architecture.md §6` Knowledge-cut model (ADR-029) across all four memory types (Work/Knowledge/People/Learning), reconciles it against the three existing classification axes (K1–K5 / Tier 1–4 / Document-Tier 1–4), stands up a unified cross-surface read/write SSOT doc, adds a People-memory surface, an operational-state lifecycle, and a skill adoption audit + pilot. **Track B — #249 (standalone):** adds a KM-scanning check-set to `pmo-qa-auditor` Mode E (doc-debt register + staleness report) consuming the in-tree `km-protocols.md` §2/§5/§6 + `lifecycle-states-canonical.md`.

All dependency context VERIFIED against live tree: the consumed upstreams (`km-protocols.md`, `lifecycle-states-canonical.md`, `knowledge-architecture.md §6`, ADR-029) all exist; #249's #90/#311 footer blockers are renumber-rot (real capabilities ship in-tree); #1071 is the containment epic (OPEN, milestone:none), not an execution gate.

**Recommendation:** **Release Class `novel`** · bump-class **MINOR** (provisional next-free above anchor v2.28, defer-to-merge) · **D-C SINGLE** branch topology. Sizing **PASS** (band-edge: 6 issues / ~19 effective pts). Top merge/split call: **#1073 + #1074 are ONE Stage-5 design** (the taxonomy table is a section of the SSOT doc, not a separable artifact); **#1075 People-row and #1076 lifecycle fields co-locate by reference in the #1074 doc** but land their normative content in their own homes.

---

### Dependency Graph

Directional, across the 6 open issues. `→` = "blocks / must precede".

```
#1071 (epic, OPEN, milestone:none) ──BELONGS_TO (containment, NOT a gate)──> {#1073,#1074,#1075,#1076,#1077}

#1073 ──Blocks──> #1074 ──Blocks──> #1077
                    │
                    ├──pairs-with──> #1075   (contract hosts the People-memory row)
                    └──governs─────> #1076   (governed-by once #1074 lands; not a hard blocker)

#249  (standalone — no edge to the cluster)
   consumes (merged-upstream, in-tree): km-protocols.md §2/§5/§6 + lifecycle-states-canonical.md
   Blocks: #172 (OUT of this milestone — downstream, not gated here)
```

**Edge classification (verified):**

| Edge | Type | Hard/Soft | Evidence |
|---|---|---|---|
| #1071 → cluster | BELONGS_TO (containment) | Not a gate | Epic does not block its own slices; #1071 OPEN/milestone:none confirms umbrella-parent role (per-issue prework + verified). |
| #1073 → #1074 | DEPENDS_ON | **HARD** | #1074 absorbs #1073's four-axis reconciliation table into its unified contract; #1074 body lists #1073 as a real internal dependency. |
| #1074 → #1077 | DEPENDS_ON | **HARD** | #1077 audits skills against the #1074 contract — needs the contract to exist to adopt it. |
| #1074 ↔ #1075 | pairs-with | **SOFT** | The #1074 contract table hosts the People-memory ROW; #1075's normative content (surface/location/schema/PII) is operator-local. Co-locatable in one Stage-5 design. |
| #1074 → #1076 | governed-by | **SOFT** | #1076 extends `operational-artifact-inventory.md` + `OPERATIONS.md`; once #1074 lands the lifecycle surfaces are governed by the contract, but #1076 has no hard build-order blocker (prework: "no real blocker"). |
| #249 → cluster | none | — | Different skill surface (`pmo-qa-auditor/SKILL.md`), different consumed upstreams. Fully parallel to Track A. |

**Cross-links (preserve, do NOT duplicate — NOT blockers):** #530 (memory↔corpus boundary, CLOSED — §6 invariant preserved) · #72 (company-knowledge ingestion, OPEN — #1075 de-overlap target) · #46 (cross-session learning, OPEN — #1077 candidate read/write surface) · #288 (CLOSED-superseded by km-protocols + km-governance + diataxis — note only).

---

### Implementation Sequence

Dependency-ordered. Two independent tracks; #249 may run any time (recommend interleaving it early so its single Engineering commit lands without waiting on the cluster's serialized chain).

1. **#1073** — Memory-type taxonomy + four-axis reconciliation table. *Foundation; unblocks the cluster.* (size:S)
2. **#1074** — Unified cross-surface read/write contract (SSOT doc). *Linchpin; absorbs #1073's table; #1075/#1076/#1077 compose on it.* (size:L)
3. **#1075** — People-memory surface (operator-local). *After #1074 (row hosted in the contract).* (size:M)
4. **#1076** — Operational-state memory lifecycle. *After #1074 (governed-by); parallel-eligible with #1075/#1077 at Stage 5/7/8.* (size:M)
5. **#1077** — Active-use memory adoption audit + pilot skill. *Sequenced LAST in-cluster (needs the #1074 contract to adopt + pilot).* (size:L)
6. **#249** — KM scanning → pmo-qa-auditor Mode E. *Standalone; sequence anywhere — recommend early-interleave.* (size:S)

**Stage-6 (Engineering) serialization note (D-C SINGLE):** #1073→#1074→#1075/#1076/#1077 commit sequentially on the release branch; #249's single Engineering commit interleaves freely (zero file overlap with the cluster). Stages 5/7/8 are parallel-eligible across issues subject to the Quota Budget gate.

---

### File Change Matrix

Per issue, files touched with add/edit/delete intent. One path per line in fenced blocks for deterministic downstream extraction. (a) = add, (e) = edit, (d) = delete. All `[ASSUMPTION – CONFIRM]` on exact mechanism → resolved at Stage 5; the matrix reflects the prework-confirmed landing spots verified against the live tree.

**#1073 — Memory-type taxonomy + four-axis reconciliation:**
```
core/disciplines/knowledge-architecture.md (e)
```
Intent: additive — insert the Work/Knowledge/People/Learning ↔ K1–K5 / Tier 1–4 / Document-Tier 1–4 reconciliation table into `knowledge-architecture.md` (prework closed the table home here, §2 where the K1–K5 axis lives; §6 already carries the four-type model from ADR-029). Preserve the §1 classifier + §2 universality/authorship axes (regression AC).

**#1074 — Unified cross-surface read/write contract (SSOT doc):**
```
core/disciplines/memory-architecture.md (a)
core/governance/OPERATIONS.md (e)
core/CLAUDE.md.template (e)
core/rules/governance-files.md (e)
```
Intent: NEW SSOT doc (`core/disciplines/memory-architecture.md`, sibling of knowledge-architecture.md per #1074 prework) — per-surface contract table (surface · memory-type · reader · writer · write-authority/Autonomy Tier · cadence · class {read-only|auto-write|operator-write-only} · trigger) + no-shadow-SSOT invariant absorbed verbatim from ADR-029. EDIT OPERATIONS.md + CLAUDE.md.template to link the contract (the live link targets per #1074 body). AC requires ≥1 consumer to cite the contract path → `core/rules/governance-files.md` (or a SKILL.md) is the citing consumer. `[ASSUMPTION – CONFIRM @ Stage 5]`: exact doc path + whether the citing consumer is a rule file vs. a SKILL.md; enforcement gate (Check-NN analog) is explicitly DEFERRED to a follow-up (#1074 prework item 5 — do NOT gate v1 on it).

**#1075 — People-memory surface:**
```
core/disciplines/memory-architecture.md (e)
```
Intent: add a People-memory ROW + section to the #1074 contract doc defining the home (operator-local `~/.claude/memory/people/`, **never repo-tracked** — PII/self-containment), minimal schema (contact · organization · relationship · context · last-touched), explicit PII posture, one-line #72 de-overlap note. **No repo-tracked PII file is created** — the surface is *described* in the contract; the store itself is operator-local. `[ASSUMPTION – CONFIRM @ Stage 5]`: storage mechanism (folder vs. single file) + keep schema operator-SCOPED (multi-operator-ready per the 2026-06-26 operator note).

**#1076 — Operational-state memory lifecycle:**
```
core/specs/operational-artifact-inventory.md (e)
core/governance/OPERATIONS.md (e)
```
Intent: EXTEND `operational-artifact-inventory.md` with a sibling lifecycle section (growth-pattern · cleanup-trigger · archive-path · retention) — additive, preserve the frozen Two-Axis Entity Lifecycle schema + derived-signals rules (regression AC). Add the CORRECTIONS.md graduation/expiry rule to `OPERATIONS.md` (observation → confirmed-pattern → governance via release process, VERIFY-CORPUS-gated, generalizing ADR-029 §Decision step 3). `[ASSUMPTION – CONFIRM @ Stage 5]`: whether the graduation rule lands in OPERATIONS.md vs. the inventory (prework leans OPERATIONS.md).

**#1077 — Active-use memory adoption audit + pilot skill:**
```
core/standards/memory-adoption-requirement.md (a)
operations/skills/daily-status/SKILL.md (e)   [pilot — ASSUMPTION, confirm at Stage 5]
packages/daily-status.skill (e)
packages/daily-status.skill.sha256 (e)
```
Intent: NEW adoption requirement doc (audit table: skill × reads-memory × writes-memory × surface + future-skill adoption requirement) under `core/standards/`. EXTEND ONE pilot SKILL.md to actively read AND write a memory surface through the #1074 contract (prework recommends `daily-status` or `ppm-agent` — both consume trackers; `daily-status:97` is also the canonical positive parameterization exemplar). Skill edit routes through **pmo-skill-editor discipline** + package rebuild (Check 7 sidecar). `[ASSUMPTION – CONFIRM @ Stage 5]`: pilot skill identity (audit output decides) + whether the audit table lives in the new standard or the #1074 doc.

> **Migration check (#1077 pilot):** confirm at Stage 5 whether the chosen pilot carries `skill_discipline_migrated_v10_2: true`. If yes → Stage 6 routes through `pmo-skill-editor` Mode A (same constraint as #249). `daily-status` migration flag MUST be read at Stage 5 before the pilot is locked.

**#249 — KM scanning → pmo-qa-auditor Mode E:**
```
core/skills/pmo-qa-auditor/SKILL.md (e)
core/skills/pmo-qa-auditor/references/failure-mode-detectors.md (e)   [ASSUMPTION — where the KM check-set spec lands; confirm at Stage 5]
packages/pmo-qa-auditor.skill (e)
packages/pmo-qa-auditor.skill.sha256 (e)
```
Intent: add KM scanning as a NEW check-set WITHIN Mode E (Platform Health Audit) — lower blast radius than a new mode on a migrated skill (prework-confirmed HOW). Emit a doc-debt register + staleness report (ranked by criticality) consuming `km-protocols.md` §2 (staleness-by-criticality) / §5 (doc-debt formula, range 0–24) / §6 (in-flight capture) + `lifecycle-states-canonical.md` (artifact lifecycle states) — NOT redefining thresholds. **Migrated skill** (`skill_discipline_migrated_v10_2: true` — VERIFIED in frontmatter) → Stage 6 MUST route through `pmo-skill-editor` Mode A + package rebuild + `deploy.sh --check` Checks 6/7/10. `[ASSUMPTION – CONFIRM @ Stage 5]`: whether the new check-set's output schema extends `references/failure-mode-detectors.md` or a new `references/km-scanning.md`.

**Aggregate distinct-file touch list (for contention extraction):**
```
core/disciplines/knowledge-architecture.md
core/disciplines/memory-architecture.md
core/governance/OPERATIONS.md
core/CLAUDE.md.template
core/rules/governance-files.md
core/specs/operational-artifact-inventory.md
core/standards/memory-adoption-requirement.md
operations/skills/daily-status/SKILL.md
core/skills/pmo-qa-auditor/SKILL.md
core/skills/pmo-qa-auditor/references/failure-mode-detectors.md
packages/daily-status.skill
packages/daily-status.skill.sha256
packages/pmo-qa-auditor.skill
packages/pmo-qa-auditor.skill.sha256
```

**`domain:` classification (A3-time, from the matrix):** `domain: governance`. The matrix consists entirely of internal pmo-platform artifacts (disciplines, governance docs, specs, standards, skill SKILL.md + references, packages) — **sourcing-exempt** (`source: N/A — pipeline-internal release`) but domain-classified `governance` (the secondary domain `software` applies to the skill-package rebuilds, noted not dominant).

---

### Stage Applicability Matrix

Default: all of Stages 5–13 apply. Skip Stage 5 only if trivial; skip Stages 7–8 only if no functional impact. Every card defers its build mechanism to Stage 5 (`[ASSUMPTION – CONFIRM]`) → **Solutioning is genuinely required release-wide; this is NOT a pre-rendered/verify-only release.**

| Issue | S5 Solutioning | S6 Eng | S7 DevTest | S8 QA | S9 Review | S10 Deploy | S11 Verify | S12 Execute | S13 Close | Rationale |
|---|---|---|---|---|---|---|---|---|---|---|
| **#1073** | **APPLY** | APPLY | REDUCE→doc-conformance | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | Doc-only (grep-verifiable ACs); S7 reduces to AC-grep pass (no executable surface). S5 needed — table structure + final placement deferred. |
| **#1074** | **APPLY** | APPLY | REDUCE→doc-conformance | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | NEW SSOT doc — design uncertainty (structure + classification columns). Doc-only → S7 reduces. |
| **#1075** | **APPLY** | APPLY | REDUCE→doc-conformance | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | NEW surface design (schema/PII/location). Operator-local store described, not executed → S7 reduces. |
| **#1076** | **APPLY** | APPLY | REDUCE→doc-conformance | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | Governance-spec edits — design needed (where graduation rule lands). Doc-only → S7 reduces. |
| **#1077** | **APPLY** | APPLY | **APPLY** | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | Skill edit = functional change to a pilot SKILL.md → S7 APPLIES (skill-behavior conformance + package rebuild verify). Audit table design needed at S5. |
| **#249** | **APPLY** | APPLY | **APPLY** | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | Migrated-skill behavior change (new Mode E check-set + output contract) → S7 APPLIES (run pmo-qa-auditor, confirm doc-debt register + staleness report emit; Checks 6/7/10). S5 needed — output schema deferred. |

**Parallel-eligible spoke counts (parallel-safe stages 5/7/8 per Procedure 2 Step 5):**
- **Stage 5:** up to **6** (all issues activate S5). Realistic worst wave after #1073→#1074 land: **4** ({#1075,#1076,#1077,#249} — #1075/#1076/#1077 design against the landed contract; #249 independent).
- **Stage 7:** **2** functional (#1077, #249) + 4 reduced doc-conformance passes (cheap).
- **Stage 8:** up to **6** (QA review-only, parallel-safe).

---

### Contention Map

Which issues share affected files. The cluster is intentionally documentation-heavy → file contention is the primary execution risk (per Stage 4 retro: "File contention is the primary challenge for documentation-heavy releases").

| File | Issues touching | Class | Resolution |
|---|---|---|---|
| **`core/disciplines/memory-architecture.md`** (NEW) | **#1074 (a), #1075 (e)** | line-range-overlap (sequential) | #1074 creates it; #1075 appends the People-row/section AFTER #1074 commits. Sequence #1074→#1075 (already the dependency order). **No #1073 here** — its table lands in `knowledge-architecture.md`, NOT the new doc (the prework decision that broke the #1073↔#1074 ordering deadlock). |
| **`core/governance/OPERATIONS.md`** | **#1074 (e), #1076 (e)** | append-pattern (distinct sections) | #1074 adds a contract cross-link; #1076 adds the CORRECTIONS graduation rule — disjoint sections. Sequence #1074→#1076; low merge-conflict risk but **serializes at commit/push under D-C SINGLE** regardless. |
| `core/disciplines/knowledge-architecture.md` | #1073 only | single-pr | No contention. |
| `core/specs/operational-artifact-inventory.md` | #1076 only | single-pr | No contention. |
| `core/CLAUDE.md.template` / `core/rules/governance-files.md` | #1074 only | single-pr | No contention. |
| `core/standards/memory-adoption-requirement.md` (NEW) | #1077 only | single-pr | No contention. |
| `operations/skills/daily-status/SKILL.md` + package | #1077 only | single-pr | No contention (pilot). |
| `core/skills/pmo-qa-auditor/SKILL.md` + references + package | #249 only | single-pr | No contention — fully disjoint from the cluster. |

**Key answer to the hub's contention question:** #1074's new SSOT doc, #1073's taxonomy, and #1075's People-row do **NOT** all land in the same file. #1073's table lands in `knowledge-architecture.md`; #1074's doc + #1075's People-row land in the new `memory-architecture.md`. The only two genuine shared-file edges are **#1074↔#1075** (the new doc) and **#1074↔#1076** (OPERATIONS.md) — both resolved by the existing dependency sequence. **No cross-PR/sibling-milestone structural contention** (#249's migrated-skill edit and the cluster's doc edits touch disjoint surfaces; no sibling milestone is declaring a rename/relocate over these paths at this baseline).

**Baseline pin:** contention assessed at the current worktree HEAD (anchor v2.28, recent window through commit 2cb3548). Re-check at Stage 9 mid-pipeline divergence if a sibling release merges over `core/disciplines/` or `core/governance/OPERATIONS.md` before this release's Stage 9.

---

### Risk Register

| ID | Class | Risk | Owner | Mitigation | Reversibility |
|---|---|---|---|---|---|
| R1 | **Dependency** | #1073→#1074 hard edge: if #1074's contract is designed before #1073's reconciliation table is settled, the contract's classification columns drift from the taxonomy. | Stage 5 | **Merge #1073+#1074 into ONE Stage-5 design** (see Recommendations) so the table and the contract are designed coherently; #1073's table commits first at Engineering, #1074 cites it. | CHEAP |
| R2 | **Contention** | #1074↔#1075 share the new `memory-architecture.md`; #1074↔#1076 share OPERATIONS.md. Concurrent Engineering chips would race on branch HEAD (D-C SINGLE). | Hub (Procedure 2) | Route Engineering chips sequentially per Implementation Sequence; hub refuses concurrent Stage-6 chips touching the shared files. Append-pattern (OPERATIONS.md) is low-conflict but still serialized. | CHEAP |
| R3 | **PII (#1075)** | Authoring a People-memory surface risks introducing a repo-tracked PII file or a sample contact with real data → self-containment / no-PII-in-repo violation + CI depersonalization-gate failure. | Stage 5/6 | **Surface is DESCRIBED in the contract; the store is operator-local `~/.claude/memory/people/`, NEVER repo-tracked.** Schema fields only, no sample PII. State PII posture explicitly (AC). Engineering `git diff` audit before commit; CI depersonalization gate is the backstop. | MODERATE |
| R4 | **Migrated-skill edit (#249)** | `pmo-qa-auditor` carries `skill_discipline_migrated_v10_2: true` (VERIFIED). A direct Write/Edit is hook-blocked (BLOCK-SKILL-EDIT-001..002); a hand-rolled edit would fail deploy Checks 6/7/10. | Stage 6 | Stage 6 MUST route through **`pmo-skill-editor` Mode A** (impact + coherence + regression) → package rebuild via `build-skill-packages.sh` → `deploy.sh --check` Checks 6/7/10 green. Same constraint applies to the #1077 pilot IF it is a migrated skill (confirm `daily-status` flag at Stage 5). | MODERATE |
| R5 | **Scope (#1074)** | The enforcement gate (a `deploy.sh --check` analog to Check 36) is a tempting v1 inclusion that would balloon #1074 from a doc into a tooling change → over-scope + CI surface. | Stage 5 | **DEFER the enforcement gate to a follow-up** (explicit in #1074 prework item 5 — do NOT gate v1 on it). v1 ships the contract doc + ≥1 citing consumer only. Note the follow-up in Recommendations. | CHEAP |
| R6 | **Scope (#1077)** | "Audit which skills read/write memory" across the full roster could expand into a corpus-wide skill edit if the audit recommends adopting more than the one pilot. | Stage 5 | AC requires **≥1 pilot** only; the audit table is the deliverable, broader adoption is future. Pilot identity from the audit, locked at Stage 5. | MODERATE |
| R7 | **Rollback complexity** | Cluster lands 4 governed docs + 1 new doc + 1 skill edit; #249 a second skill edit. A post-merge defect could span the contract + its consumers. | Stage 12/13 | Per-issue commits on the release branch (D-C SINGLE) keep each issue's change individually revertible (`git revert <issue-commit>`); skill edits revert via `pmo-skill-editor` revert + redeploy + package rebuild. Governance docs are additive (no deletions) → revert is clean. See Rollback Strategy below. | MODERATE |
| R8 | **Drift / staleness** | #1073/#1074 build on `knowledge-architecture.md §6` + ADR-029. If ADR-029 is re-opened by #1074 (its prework says ratifying #1074 "re-opens ADR-029 to fold the Knowledge cut in"), an un-coordinated ADR edit could drift from the shipped §6. | Stage 5/6 | Treat the ADR-029 fold as part of #1074's Stage-5 design (cite it, don't silently re-author); the §6 no-shadow-SSOT invariant is absorbed VERBATIM (regression check). ADR edits follow the immutable-ADR / governed-change path. | MODERATE |

**Rollback Strategy (release-level):** D-C SINGLE → all changes on one `release/<slug>` branch, one PR. Pre-merge: PR diff IS the dry-run (Stage 9 gate). Post-merge rollback = `git revert` of the merge commit (whole release) or per-issue commit reverts (granular — each issue is a discrete commit). Skill edits (#249, #1077) additionally require `pmo-skill-editor` revert + `deploy.sh --deploy` + package rebuild to restore the runtime mirror + package. Governance/discipline docs are additive-only → no data loss on revert. No operator-local PII is repo-tracked (#1075) → nothing to roll back outside the worktree. Operator-authorized per RELEASE_PROTOCOL.md § Rollback.

---

### Quota Budget

**Verdict:** PASS (per `quota-budget-protocol.md` Checkpoint A)
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: 4 (worst realistic wave — {#1075,#1076,#1077,#249} after #1073→#1074 land; 6 if all S5 fired at once but #1075/#1076/#1077 gate on the #1074 contract) · Stage 7: 2 functional (#1077,#249) + 4 reduced doc-conformance · Stage 8: 6
**Per-spoke cost estimate:** size-bucket ordinal band (source: heuristic per `quota-budget-protocol.md` §5 — no telemetry medians yet). Worst Stage-5 wave mix = S/M/L/S; worst Stage-8 wave = the 6-issue size vector S/L/M/M/L/S.
**Assumed/stated remaining usage-window envelope:** operator did not state quota at hub start → **conservative default** (treat the 5-hour window as partially consumed; assume ~1 full envelope available for the worst wave).
**Estimated cumulative draw % (worst parallel batch):** worst wave is the Stage-8 6-issue QA batch (review-only, low per-spoke cost) OR the Stage-5 4-spoke design wave (higher per-spoke cost, fewer spokes). Both estimate **< 50%** of a conservative single-window envelope — 4–6 doc/skill-review spokes is a modest cumulative draw. → **< 50% → PASS.**
**Routing:** PASS → proceed parallel; no warning in plan.
**Note:** Checkpoint B re-validates at every parallel wave (runtime, load-bearing) with PROCEED/SERIALIZE/DEFER/REDUCE-scope; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Bands + cumulative-draw budget are `[CALIBRATE-AFTER-3]` MEDIUM. If the operator states a heavily-consumed window at any wave, the Stage-5 4-spoke wave is the one to SERIALIZE first (highest per-spoke cost).

---

### Operator Decisions (D-ReleaseClass / D-Version / D-C Branch Topology)

#### D-ReleaseClass: What Release Class does this release carry?
**Gate input:** Spoke-proposed class + trigger evidence per `release/references/specs/release-class-taxonomy.md` § Class Enum.
**Gate decision:** Choose between (A) routine, (B) novel, (C) cross-cutting, (D) hotfix.
**Blocks:** Stage 3 Phase B3 milestone-description authoring (already bundled — applies as confirmation here); downstream per-class differentiation posture (engagement density / Stage 9 depth / Stage 5 bias).
**Upstream compatibility:** N/A — Release Class is PMO platform internal taxonomy; no Anthropic upstream surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP / HIGH (re-classifiable later per § Re-Classification Protocol).
**Recommendation: (B) `novel`.** Trigger evidence:
- **novel trigger (a) FIRES** — the release introduces ≥1 NEW reference doc: `core/disciplines/memory-architecture.md` (#1074) + `core/standards/memory-adoption-requirement.md` (#1077). New file class (cross-surface memory SSOT contract).
- **novel trigger (b) FIRES** — ≥1 D-class decision in the release plan (this block + D-Version + D-C; plus Stage-5 design decisions on doc structure).
- **`cross-cutting` weighed and REJECTED:** trigger (a) needs ≥3 `pipeline/stage-*.md` files — **zero** touched. Trigger (b) needs ≥3 of {CLAUDE.md, OPERATIONS.md, RELEASE_PROTOCOL.md, RELEASE_LOG.md, hub-spoke-bridge.md, gate-criteria-spec.md, release-process.md} — this release touches **OPERATIONS.md + CLAUDE.md.template = 2** of that set (CLAUDE.md.template is the seed-template, arguably the CLAUDE.md member; even counting it, 2 < 3). Trigger (c) needs ≥3 in-bundle compositional edges per the A2 DAG — the cluster has 2 hard edges (#1073→#1074, #1074→#1077) + 2 soft (#1074↔#1075, #1074→#1076); the hard-edge count is 2. **Below the cross-cutting floor on all three triggers** → `novel` is correct, not `cross-cutting`. The release introduces new doc surfaces (novel) without modifying ≥3 pipeline stages or ≥3 core governance files (not cross-cutting).
- Differentiation posture (novel): Engagement density **Standard** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** (novel cross-issue compositional surface surfaces design questions per-issue triggers miss) · Stage 13 outcome-window **30-day**.

#### D-Version: What version does this release claim?
**Gate input:** Spoke-recommended next-free version, computed at recommendation time against authoritative host state. Anchor = `gh releases/latest` per the repo-host adapter (provisional-display; the durable declaration is the **bump-class**, bound to a number only at the Stage-12 atomic claim — defer-to-merge).
**Gate decision:** Operator renders version identity — (A) accept spoke-recommended next-free, (B) version-less milestone (theme-named; no tag at Stage 12), or (C) operator-specified override.
**Blocks:** release branch name, plan-file path, Stage 12 atomic claim, any `version:` frontmatter the release writes (the #249 + #1077 skill edits WILL bump skill `version:` fields → those carry this release's version).
**Upstream compatibility:** N/A — version identity is PMO platform internal; no Anthropic upstream surface. (The skill `version:` fields the release writes carry this version, but their upstream posture is owned by the skill-editing D-decisions, not D-Version.)
**Reversibility / Confidence:** CHEAP pre-Engineering (recommendation only); MODERATE after Engineering Commit 0 (identity propagates into branch name + plan-file path + skill frontmatter) / HIGH.
**Recommendation: (A) accept next-free — bump-class MINOR.** Evidence:
- Anchor is **v2.28** (current shipped latest; `.version` + the 5-skill v2.28 bump landed at commit 7cb5cbb). This release ships NEW capability (new docs + new skill check-set), not a patch → **MINOR** bump-class floor.
- Provisional next-free above the v2.28 anchor at the MINOR floor → **v2.29** (provisional-display only; **defer-to-merge** — siblings may claim mid-run, so the number binds at the Stage-12 atomic claim. The repo's lineage history shows provisional drift is normal — v2.23→v2.25→v2.27 drifted as siblings claimed. Do NOT hard-code v2.29 into durable corpus; the durable declaration is "MINOR bump").
- Re-verify at Engineering Commit 0 per Procedure 0 § Canonical location (`git fetch --tags origin && git fetch origin main`, recompute next-free, HALT-on-collision).

#### D-C Branch Topology: SINGLE branch or per-issue (OPTION-A) branches?
**Gate input:** Contention Map + the 6-issue scope + the cluster's serialized dependency chain.
**Pre-decided:** OMIT (no per-decision stance on record; no `Gate-Class Framing Directives` block in the milestone description).
**Gate decision:** (A) **SINGLE** — one `release/<slug>` branch, sequential Engineering commits, one PR (PR diff IS the dry-run). (B) **OPTION-A** — per-issue branches + per-issue PRs (parallel Engineering, contention shifts to PR-merge order at Stage 12).
**Blocks:** release branch creation; the plan-file commit mechanism (Engineering Commit 0 vs. Stage-4 chore-PR); Procedure 2 Stage-6 routing rules.
**Upstream compatibility:** N/A — branch topology does not modify skill-authoring surface. Upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP / HIGH (topology is a per-release choice; re-selectable before Engineering).
**Recommendation: (A) SINGLE (default).** Evidence:
- Contention is **low and already dependency-ordered** — only 2 shared-file edges (#1074↔#1075 on the new doc; #1074↔#1076 on OPERATIONS.md), both resolved by the existing Implementation Sequence. SINGLE's sequential Engineering commits naturally serialize these without per-issue-branch overhead.
- #249 is fully disjoint → it interleaves as a single commit on the same branch with zero contention.
- OPTION-A buys parallel Engineering, but the cluster's hard chain (#1073→#1074→#1077) is inherently serial — parallelism would only help #1075/#1076/#1077/#249, and the contention map shows their file overlaps are already minimal. The per-issue-branch + 3-chore-PR overhead is not justified by a 6-issue, low-contention, doc-heavy release. SINGLE is the lower-ceremony correct choice.

---

### Recommendations

1. **Merge #1073 + #1074 into ONE Stage-5 Solutioning design.** The four-axis reconciliation table (#1073) is a *section of* the unified contract's conceptual model, not a separable artifact — designing them apart risks the contract's classification columns drifting from the taxonomy (R1). They land in **different files** at Engineering (#1073 → `knowledge-architecture.md §2`; #1074 → new `memory-architecture.md`), so they remain two Engineering commits — but ONE design spoke. This is a Stage-5 *design-scope* merge, not an issue merge; keep the two issues distinct for closure.

2. **#1075 People-row and #1076 lifecycle fields: co-locate by REFERENCE in the #1074 doc, land normative content in their own homes.** #1075's People-memory ROW belongs in the #1074 contract table (it IS a surface the contract enumerates); its operator-local store + schema are described there. #1076's lifecycle fields extend `operational-artifact-inventory.md` (NOT the #1074 doc) + the CORRECTIONS rule lands in OPERATIONS.md. The #1074 contract *references* both (one table row each) so the SSOT stays single-home. Do NOT collapse #1075/#1076 into #1074 — they have distinct homes and distinct ACs.

3. **#1074 v1 ships the doc + ≥1 citing consumer ONLY — DEFER the enforcement gate.** The `deploy.sh --check` Check-36-analog is explicitly a follow-up per #1074 prework (R5). File a follow-up issue for the enforcement gate post-merge; do NOT gate this release on it.

4. **Confirm the #1077 pilot's migration flag at Stage 5 BEFORE locking the pilot.** If `daily-status` (or `ppm-agent`) carries `skill_discipline_migrated_v10_2: true`, its Stage 6 edit routes through `pmo-skill-editor` Mode A — same path as #249. `daily-status:97` is the canonical positive parameterization exemplar (per knowledge-architecture.md §3), which makes it a natural pilot, but verify the flag.

5. **#249 + #1077 both touch skill packages — budget Stage 6 for the package-rebuild + Check-7-sidecar discipline.** Each skill edit requires `build-skill-packages.sh <skill>` → committed `.skill` + `.skill.sha256` sidecar → `deploy.sh --check` Checks 6/7/10 green. Two skills (`pmo-qa-auditor`, the #1077 pilot) → two rebuilds. This is mechanical but non-skippable.

6. **Stage 13 reflexive close-out reminder (out-of-scope note, for the hub):** per the close-out tool-gap pattern, theme-named milestones can drop the `.version` stamp + CHANGELOG append + miss `chore/<slug>-*` Stage-12/13 branches in `cleanup-orphan-state.sh`. The hub should verify these MANUALLY at Stage 13 for this theme-named milestone (`16-knowledge-management-discipline`).

7. **Discovery outside scope (noted, not actioned):** (a) #72 (company-knowledge ingestion, OPEN) is the #1075 de-overlap target and a candidate for a future companion milestone — the People/Knowledge surface split defined here sets up #72's eventual home. (b) #46 (cross-session learning, OPEN) is the #1077 candidate read/write surface — a future adoption-expansion beyond the single pilot. (c) #1074's ratification re-opens ADR-029 to fold the Knowledge cut into the generalized contract — coordinate the ADR edit as part of #1074's Stage-5 design (R8), do not author it standalone.

---

**Decision-discipline patterns scanned + applied (per CLAUDE.md Stage-4 obligation):**
- *feedback_reevaluate_ticket_against_architecture* — applied: re-verified every consumed upstream against live tree (km-protocols.md, lifecycle-states-canonical.md, knowledge-architecture.md §6, ADR-029 all exist; #90/#311 footer blockers confirmed renumber-rot). Ticket-age-vs-architecture staleness check passed.
- *feedback_self_containment_no_pii* — applied to R3: #1075 People-surface is operator-local, never repo-tracked; no sample PII; CI depersonalization gate is the backstop.
- *feedback_skill_edit_discipline* + *feedback_dont_subvert_locked_controls* — applied to R4/Rec 5: #249 (migrated) + the #1077 pilot route through `pmo-skill-editor` Mode A; no hand-rolled SKILL.md edits; package rebuild + Checks 6/7/10.
- *feedback_no_hedge_defer_at_planning* — applied to D-Version + #1074 enforcement gate: did NOT reflex-defer; recommended a real MINOR bump with a tag (novel capability ships), and deferred ONLY the enforcement gate where the prework explicitly scoped it out.
- *feedback_composition_is_judgment_not_binpacking* — applied to the merge/split recs: #1073+#1074 merged by design-coherence (R1 dep-edge), NOT bin-packed; #1075/#1076 kept distinct by single-home discipline.
- *Audit-baseline discipline* (CLAUDE.md) — applied to the Contention Map: baseline pinned at HEAD (anchor v2.28, window through 2cb3548); cross-PR/sibling structural contention re-checkable at Stage 9.

## Collective Review Outcomes (2026-06-26)
- Scope-lock APPROVED → Stage 6 Engineering (D-C SINGLE).
- #1075: reconcile-and-cite — People-graph already shipped (v2.23); folds into #1073 (§2.1/§6 descriptor) + #1074 (People contract row citing the shipped operator-instance roster). No new surface; no separate commit.
- #1077: future-skill memory-adoption requirement = SHOULD (forward-only; pilot = daily-status).
- #1074 cited by core/rules/governance-files.md (doc-only); #1076 CORRECTIONS graduation piggybacks the existing pattern-review cadence; enforcement gate DEFERRED to a follow-up.
- Version: bump-class MINOR; provisional drifted v2.29 → (re-verify at this commit); defer-to-merge binds at Stage 12.
