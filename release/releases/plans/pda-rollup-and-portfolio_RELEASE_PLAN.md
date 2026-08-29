---
title: Release Plan — pda-rollup-and-portfolio (deterministic PORTFOLIO rollup)
type: release-plan
plan_type: release
status: CLOSED
release: version-agnostic (binds at Stage 12)
milestone: 264-pda-rollup-and-portfolio
release_class: cross-cutting
reversibility: MODERATE / Confidence HIGH
---
# Release Plan — `pda-rollup-and-portfolio`

**Milestone:** `pda-rollup-and-portfolio` (#264) · hub sub-task #3444 = Stage 4 plan source
**Provisional version:** **version-agnostic** — binds at Stage 12 via next-free. The Stage-4 provisional was **v3.75**, but that version has since been **claimed by the concurrent `skill-and-data-entity-hygiene` release** (merged during this Stage-6 window at `2e83741` "chore(v3.75): Stage 12 — RELEASE_LOG DEPLOYED row"); a second concurrent draft (`#267 skill-hardening`) also held provisional v3.75. This release therefore ships **version-agnostic** branch / PR / plan labels and anchors the actual version at Stage 12 (recomputed next-free). Re-check at Stage 9 entry + Stage 12.
**Topology:** D-C SINGLE — one release branch (`release/pda-rollup-and-portfolio`), one PR, one merge; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** P0 fully-serial (default-when-undeclared) — Stage 6 chips route one at a time in dep order on the single branch.
**Release class:** `cross-cutting` (trigger (c) — 6 in-bundle compositional edges).

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #3444 (issuecomment-4953833465), reconciled to the approved Stage-5 Solutioning designs and the **Collective-Review scope-lock dispositions** (issuecomment-4998973138). Where a scope-lock disposition superseded a Stage-4 assumption, the transcribed sections below preserve the Stage-4 plan of record and the **§ Deviation Log** records the ratified delta. Authored at Engineering Commit 0 by the first Engineering spoke (#3525, issue #2578).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | version-agnostic (provisional was v3.75 — now claimed; binds next-free at Stage 12) |
| **Date Created** | 2026-07-16 (Thursday) |
| **Release Manager** | Agent-assisted (release-hub) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/pda-rollup-and-portfolio` |
| **PR** | (populated at PR creation, Stage 6) |
| **Milestone** | `pda-rollup-and-portfolio` (#264) |

---

## Scope

### Summary

Five issues compose a single deterministic `PORTFOLIO.md` write-back surface: a governed rollup **contract** (#157) → a deterministic **composer** engine (#1771) → freshness-validated **health scoring** (#276) → cross-component **risk aggregation** (#1169), on a methodology-neutral **tier taxonomy** foundation (#2578). Ship as **ONE unit** — CONFIRMED. The contention map (`PORTFOLIO.md` staging, `weekly-status-rollup/SKILL.md`, and `core/governance/OPERATIONS.md` are each edited by 3–4 issues) independently validates the coherence-over-split override: a split would fork one file's write-back path across two releases.

Subsumption re-verified CLEAR at Stage 4: `core/standards/portfolio-writeback-contract.md` ABSENT; the #255-absorbed content (capacity dashboard / RAID / R-G-T / integrity multiplier / A–F grade) grep-count 0 in live `PORTFOLIO.md` → all net-new. #1769 (SQLite substrate) CLOSED/COMPLETED; #255/#374/#373 CLOSED/NOT_PLANNED (net-new absorptions); #2577 (PMI presentation) correctly OPEN/out-of-scope.

### Issues Included

| # | Issue | Title | Category | Size (operative) | Build order |
|---|-------|-------|----------|------------------|-------------|
| 1 | #2578 | Operational tier taxonomy & naming conventions (neutral structural layer) | architecture | M | 1 (FOUNDATION) |
| 2 | #157 | Portfolio rollup contract + per-project rollup entity | — | L | 2 |
| 3 | #1771 | Deterministic PORTFOLIO composer engine | — | M | 3 |
| 4 | #276 | Portfolio health scoring (freshness + hard-gate, right-sized) | — | S | 4 |
| 5 | #1169 | Cross-component risk aggregation | — | S | 5 |

---

## Dependency Graph

Directional (X → Y = "X lands before Y" / "Y consumes X"):

```
#2578 ──[MODERATE]──▶ #157 ──[HARD]──▶ #1771
 (tier taxonomy)   (rollup      │        (composer engine)
                    contract)   │           ▲
                                │           │ [CO-DESIGN: shared PORTFOLIO.md
                                │           │  + weekly-status-rollup surface]
                                ├──[HARD]───┴─▶ #276 (health score)
                                │                     │
                                └──[SOFT]──▶ #1169 ◀──[SEQUENCE] (build after #276's
                                          (risk aggregation)      RAID section — CIAC-3,
                                                                  compose not duplicate)
```

| Edge | Type | Evidence |
|---|---|---|
| #2578 → #157 | MODERATE | #157's entity placement (`[Project]/…`, `projects/_config/` portfolio tier) references the tier taxonomy + naming conventions #2578 codifies; #2578 edits `project-entity-model.md §7` which #157 reconciles against. |
| #157 → #1771 | **HARD** | #1771 body: "Requires … #157 (contract)"; composer consumes the rollup contract. |
| #157 → #276 | **HARD** | #157 "Blocks #276"; #276 "Blocked by #157" — composed-health reads per-project rollups (contract before composed-health). |
| #157 → #1169 | SOFT | #1169 reads rollup risk fields where available; no hard blocker ("no external co-delivery dependency remains"). |
| #1771 ↔ #276 | CO-DESIGN | Engine renders the health sections #276 defines; both edit `PORTFOLIO.md` staging + `weekly-status-rollup/SKILL.md`. |
| #276 → #1169 | SEQUENCE | Both converge on `PORTFOLIO.md §Top Risks` / cross-project RAID; build #1169 after #276 so they compose (CIAC-3), not duplicate. |

**Compositional-edge count = 6 (2 HARD + 2 MODERATE/co-design + 2 soft/sequence) ≥ 3 → cross-cutting trigger (c) FIRES.**

---

## Implementation Sequence

Dep-ordered on one branch:

**#2578 → #157 → #1771 → #276 → #1169**

1. **#2578** (tier taxonomy) — foundation: edit `project-entity-model.md §7` + `CLAUDE.md.template` Governance File Map + `OPERATIONS.md` first, so #157/#1169 read the reconciled tier structure. **(This release plan's Commit 1 — built by this spoke.)**
2. **#157** (rollup contract) — hard prereq for #1771 + #276; authors the new standard + entity template + skill emit/consume wiring. Scope-lock adds an **8th contract field** `cross_project_conflicts[]` (XC-2) and **pins the staleness anchor** in the contract (XC-1); **omits** `completeness_score` until a producer ships.
3. **#1771** (composer engine) — the deterministic rendering framework consuming #157's contract + the shipped SQLite index (#1769). **Composer home = `core/deploy/tools/compose-portfolio.py`** (scope-lock Option A). Fixed `--as-of` scoped to `--self-test` fixture only (XC-1).
4. **#276** (health score) — plugs the **right-sized** (freshness + hard-gate) health sections into the composer; write-back staging. Freshness age = `today − last_published` business days (XC-1).
5. **#1169** (risk aggregation) — aggregation layer on `§Top Risks`, composed after #276's RAID section; S6 XRC rendered from the new `cross_project_conflicts[]` field (XC-2).

**Sequencing note (Stage-5 co-design, not a reorder):** the seed order puts #1771 (engine) before #276 (section content); this holds because #1771 is built as a schema-agnostic rendering framework with section schemas injected — Stage 5 designed #1771 and #276 together on the shared surface. Hard edges (#157-first, #2578-foundation) are firm.

---

## Stage Applicability Matrix

Release Class `cross-cutting` → Stage 5 activation bias **ALL**; Stage 9 review depth **Deep**. No issue skips a stage entirely; two REDUCE Stage 7 (no executable surface).

| Issue | S5 Solutioning | S6 Eng | S7 Dev Test | S8 QA/Accept |
|---|---|---|---|---|
| **#2578** | YES — program-tier design (frontmatter physicalization; naming conventions) | YES | **REDUCE** → doc-conformance grep (program tier registered in `CLAUDE.md.template` + `OPERATIONS.md`) | YES |
| **#157** | YES — contract schema (≥6 fields + per-field cadence), entity-template shape | YES | YES — staleness `[STALE]` rendering + emit/consume behavioral | YES |
| **#1771** | YES — composer engine design; composer home (script vs skill-procedure) = D-class decision | YES | YES — idempotency (double-run hash compare); query→render | YES |
| **#276** | YES — MANDATORY right-size (trim article-sourced three-layer/integrity-multiplier/freshness-decay; keep freshness + hard-gate core) | YES | YES — integrity multiplier / freshness decay behavioral | YES |
| **#1169** | YES — LIGHT (standalone-file vs fold-into-`§Top Risks`) | YES | **REDUCE** → doc-conformance grep (≥3 risk categories, entity refs, no `/Users/`, RAID-source citation) | YES |

Release-level (once, D-C SINGLE): **S9 Plan Review = Deep** (cross-cutting) · S10 Release Prep · S12 Execute · S13 Close.

---

## Contention Map

Shared affected surfaces (why one-unit ship is correct):

| Surface | Issues touching | Type | Handling |
|---|---|---|---|
| **`PORTFOLIO.md`** (Layer-2 **staging** target — composed, never Claude-written) | #157, #276, #1771, #1169 (4) | Design-coherence (not merge-conflict — one branch) | One agreed section schema; CIAC-1/3/4 enforce coherence + bridge boundary |
| **`operations/skills/weekly-status-rollup/SKILL.md`** | #157 (consume), #276 (write-back sections), #1771 (composer ref) (3) | File contention | Sequential layered edits in dep order on one branch |
| **`core/governance/OPERATIONS.md`** | #157 (register entity+contract in artifact index), #276 (health-scoring protocol), #2578 (program-tier ref) (3) | File contention | Sequential edits in dep order |
| **`core/disciplines/project-entity-model.md`** | #2578 (EDIT §7 Program physicalization), #157 (read/reconcile entity template), #1169 (read RAID / XPD / XRC) | Read-after-write | Build #2578 first so #157/#1169 read reconciled §7 |
| `operations/skills/ppm-agent/SKILL.md` | #157 (emit) | Low | Single editor |
| `core/CLAUDE.md.template` | #2578 (Governance File Map) | Low | Single editor |
| `core/standards/portfolio-writeback-contract.md` (NEW) · `operations/templates/…-rollup-template.md` (NEW) | #157 | None | Net-new |

No cross-milestone structural collision surfaced at plan time (single-PR release; baseline-pin at the release branch base SHA; re-check at Stage 9 entry per the sibling-merge trigger).

---

## File Change Matrix

Transcribed from Stage 4; ratified deltas from scope-lock are recorded in **§ Deviation Log** (container dropped, 8th field added, composer home resolved, `completeness_score` omitted).

```
# ADD (net-new)
core/standards/portfolio-writeback-contract.md        ADD    #157  — G7 rollup contract + per-project publishing schema (≥6 fields, per-field cadence; +8th field cross_project_conflicts[]; staleness anchor pinned; completeness_score OMITTED)
operations/templates/<project>-rollup-template.md     ADD    #157  — per-project rollup entity template (name set at Stage 5/6; canonical template home)
core/deploy/tools/compose-portfolio.py                ADD    #1771 — [scope-lock Option A] deterministic composer consuming the SQLite-index portfolio-rollup query; fixed --as-of scoped to --self-test fixture only

# EDIT — engineering (Layer-1, tracked; in the PR)
operations/skills/ppm-agent/SKILL.md                  EDIT   #157  — emit rollup per contract on scheduled cadence
operations/skills/weekly-status-rollup/SKILL.md       EDIT   #157,#276,#1771 — consume rollup (#157) + write-back health/capacity/RAID/R-G-T sections (#276) + reference deterministic composer (#1771); §6 passes --as-of=today in production
core/governance/OPERATIONS.md                         EDIT   #157,#276,#2578 — register rollup entity+contract in operational-artifact index (#157); health-scoring protocol + per-project timestamp-narrowing note (#276); program-tier routing reference (#2578)
core/CLAUDE.md.template                                EDIT   #2578 — Governance File Map: program tier + portfolio/program/project naming conventions  [NOT a repo-root CLAUDE.md]
core/disciplines/project-entity-model.md              EDIT   #2578 — §7 physicalization NOTE for Program (frontmatter-primary; no mandatory folder); read/light-touch by #157, #1169
core/deploy/deploy.sh                                 EDIT?  #157  — register new rollup template in TEMPLATE_SYNC_MAP (verify need at Stage 6)

# STAGE-ONLY — Layer-2, Cowork-owned bridge (composed content staged; Claude Code NEVER writes)
projects/_config/PORTFOLIO.md                          STAGE  #157,#276,#1771,#1169 — right-sized(trimmed) health + capacity/RAID/R-G-T (#276) + deterministic composition (#1771) + risk aggregation (#1169); staged for the Cowork writer

# PACKAGE REBUILD (Stage 12, post-skill-edit — Check 7)
packages/ppm-agent.skill                               REBUILD  — build-skill-packages.sh
packages/weekly-status-rollup.skill                    REBUILD  — build-skill-packages.sh

# RELEASE ARTIFACTS (pipeline-standard)
release/releases/plans/pda-rollup-and-portfolio_RELEASE_PLAN.md   ADD    — this plan (Engineering Commit 0)
release/releases/RELEASE_LOG.md                        EDIT   — Stage 12 DEPLOYED row (chore PR)
release/releases/notes/<version>_RELEASE_NOTES.md      ADD    — Stage 13 (chore PR)
CHANGELOG.md                                           EDIT   — Stage 13 (chore PR)
```

**domain_practice:** `{ source: N/A — pipeline-internal release, date: 2026-07-16, domain: governance }` — the File Change Matrix is entirely internal pmo-platform artifacts (governance + skill + standard edits) → sourcing-exempt, `domain: governance`.

---

## Cross-Issue Acceptance Criteria

Testable predicates spanning ≥2 issues, graded on the merged PR at Stage 9 (QC3.5). Reconciled to the scope-lock dispositions (XC-1 anchor, XC-2 8th field):

- [ ] **CIAC-1 (#157 × #1771 on PORTFOLIO.md composition):** the composer renders `PORTFOLIO.md` sections from #157's contract field set (`status`, `top_risks[]`, `key_dependencies[]`, `capacity_signal`, `milestone_delta`, `cross_project_conflicts[]`, `last_published` — `completeness_score` omitted until a producer ships), not re-derived prose. *Method:* grep the composer's input schema references the contract fields; double-run hash-compare for idempotency. *Surface:* `PORTFOLIO.md` ↔ `portfolio-writeback-contract.md` field set.
- [ ] **CIAC-2 (#157 × #276 on freshness):** one staleness mechanism, not two — #276's freshness rule (`>3bd [STALE]`, `>5bd auto-degrade`, business days) consumes the SAME `last_published`/per-field cadence #157 defines, and both measure age against the **contract-pinned anchor** (`today − last_published`); no parallel freshness field or divergent anchor invented. *Method:* grep both the contract and the `OPERATIONS.md` health-scoring protocol reference the same `last_published`/cadence key and the same age anchor. *Surface:* freshness field in `portfolio-writeback-contract.md` ↔ `OPERATIONS.md` health-scoring protocol.
- [ ] **CIAC-3 (#276 × #1169 on §Top Risks / RAID):** #276's cross-project RAID section (absorbed #255) and #1169's risk aggregation compose ONE cross-project risk surface (RAID + Cross-Project Dependency + Cross-Project Resource Conflict) without duplication; each risk row carries risk + owner + mitigation (no passive voice). *Method:* grep one shared cross-project risk surface referenced by both; spot-check risk/owner/mitigation triples. *Surface:* `PORTFOLIO.md` cross-project RAID / `§Top Risks`.
- [ ] **CIAC-4 (#157 × #276 × #1771 on the Cowork-owned bridge boundary):** NONE performs a direct Claude-side write to `projects/_config/PORTFOLIO.md` — all STAGE composed content for the Cowork writer (Layer-3 boundary; autonomy-tiers §Irreducible Human Task). *Method:* grep the skill edits + composer for any write path resolving into `projects/` → zero Claude-side write; staging-only. *Surface:* `PORTFOLIO.md` write boundary. **(Most load-bearing — release-wide invariant.)**
- [ ] **CIAC-5 (#2578 × #157 on tier taxonomy/placement):** #157's per-project rollup-entity placement and portfolio-tier staging conform to the tier structure + naming conventions #2578 codifies in the `CLAUDE.md.template` Governance File Map (`§ Operational Tier Taxonomy & Naming Conventions`). *Method:* grep #157's entity-template placement + #1169's portfolio-tier placement match the #2578 naming conventions (kebab-case `*_id` classifier fields; `projects/_config/` portfolio home). *Surface:* `CLAUDE.md.template` Governance File Map tier structure.

---

## Risk Register

| # | Risk | Likelihood | Impact | Mitigation | Owner | Reversibility |
|---|------|-----------|--------|-----------|-------|---------------|
| R1 | The "≥1 active project demonstrates end-to-end rollup" AC (#157, #276) needs a live `PORTFOLIO.md` write-back, which is Cowork-owned Layer-2 — the engineering PR cannot write `projects/_config/PORTFOLIO.md`. | High | Med | PR delivers + verifies the staging shape / composer idempotency / skill emit-consume against a fixture; the live demo AC is verified post-merge in the operations domain (Cowork). Stage 8 marks it "declared, verification deferred to post-merge Cowork run" — must NOT FAIL an in-PR-unverifiable predicate. | Stage 8 + operator | MODERATE / HIGH |
| R2 | #2578 "edits CLAUDE.md" — but the tracked surface is `core/CLAUDE.md.template`; a repo-root CLAUDE.md does not exist and the workspace-root file is git-ignored. | — | High | File Change Matrix targets `core/CLAUDE.md.template`; deploy propagates to runtime. **RESOLVED this Commit 1.** | Stage 6 | CHEAP / HIGH |
| R3 | #276's three-layer health + integrity-multiplier + freshness-decay is article-sourced, not pain-sourced, and heavy for a single-operator dashboard. | Med | Med | MANDATORY Stage-5 right-size: keep freshness + hard-gate core; trim the multi-layer scoring elaboration. **Scope-lock: TRIM confirmed.** | Stage 5 spoke | MODERATE / HIGH |
| R4 | `weekly-status-rollup/SKILL.md`, `OPERATIONS.md`, `PORTFOLIO.md` staging each edited by 3–4 issues; out-of-order edits clobber a prior issue's section. | Med | Med | Single branch; strict dep-order build (#2578→#157→#1771→#276→#1169); one merge. | Stage 6 | CHEAP / HIGH |
| R5 | Two tracked `OPERATIONS.md` files: `core/governance/OPERATIONS.md` (canonical) and `operations/OPERATIONS.md` (module pointer stub). | Low | Med | Target `core/governance/OPERATIONS.md`. **Stage-5 R5: `operations/OPERATIONS.md` is a pure pointer — NO mirror (would create a shadow SSOT).** | Stage 6 | CHEAP / HIGH |
| R6 | Editing `ppm-agent` + `weekly-status-rollup` SKILL.md triggers pmo-skill-editor discipline + .skill package rebuild at release-cut (Check 7). | — | Low | Run pmo-skill-editor discipline at Stage 6 (#157 chip); rebuild via `build-skill-packages.sh` before Stage 12. | Stage 6 / 12 | CHEAP / HIGH |
| R7 | #1771 composer's concrete home was TBD at Stage 4 (executable script vs skill-embedded procedure). | — | Med | Surfaced as a Stage-5 D-class decision. **Scope-lock: Option A — `core/deploy/tools/compose-portfolio.py`.** | Stage 5 | MODERATE / HIGH (RESOLVED) |
| R8 | Staleness anchor / XRC field coverage under-specified at #157's composition seam (adversarial-review Blockers XC-1/XC-2) — invisible to the CIAC grep-tests. | Med | High | Scope-lock reconciliations: XC-1 pin anchor `today − last_published` business days in the contract; XC-2 add 8th field `cross_project_conflicts[]`. Disposition BEFORE the §6 edit chain begins. | Stage 6 (#157 chip) | MODERATE / HIGH |

**Rollback strategy (D-C SINGLE):** one PR → rollback = `git revert <merge-sha>` + rebuild `.skill` packages. All changes additive/reversible: the new standard + entity template + composer are deletable; contract/skill edits revert via git; `PORTFOLIO.md` restructure is cosmetic (replaces handwritten content — no data migration, no irreversible step). **Overall release reversibility: MODERATE / HIGH.**

---

## Delivery Strategy

| Aspect | Decision |
|--------|---------|
| **Implementation approach** | Sequential (dependency-ordered): #2578 → #157 → #1771 → #276 → #1169 |
| **Commit strategy** | Grouped commits per issue on the single release branch (this plan = Engineering Commit 0; #2578 edits = Commit 1) |
| **Review approach** | Single PR for the entire release (D-C SINGLE), created in draft, transitioned ready at Stage 9 |
| **Deployment mechanism** | Git merge + S-2 skill copy + `build-skill-packages.sh` rebuild (Stage 12) |
| **Concurrency posture** | P0 fully-serial (default-when-undeclared) — no force-push on the shared release branch |
| **Stacked-base cleanup posture** | Phase B0 base-shift per dep (default — Option A) |

---

## Verification Plan

### Per-Issue Verification

| Issue | Verification Method | Expected Result |
|-------|-------------------|----------------|
| #2578 | doc-conformance grep: program tier registered in `CLAUDE.md.template` (`### Operational Tier Taxonomy & Naming Conventions` + 3-tier table + disambiguation) + `OPERATIONS.md` (program-tier routing note); §7 physicalization NOTE additive; **no `_config/programs/` reference anywhere** | All greps PASS; frozen §7 storage_tier/persistence_mode UNCHANGED; no container path introduced |
| #157 | contract field set (8 fields incl. `cross_project_conflicts[]`, `completeness_score` omitted); staleness anchor pinned in contract; emit/consume behavioral against fixture | Contract fields present; anchor = `today − last_published` business days |
| #1771 | idempotency (double-run hash compare); query→render from contract fields; `--as-of` fixed only under `--self-test` | Byte-identical double-run; production passes `--as-of=today` |
| #276 | freshness (`>3bd`/`>5bd`) + hard-gate ("can't-show-Green-over-failing"); per-project `Last-Validated`; article-sourced layers absent | Freshness + hard-gate present; trimmed layers absent |
| #1169 | doc-conformance grep: ≥3 risk categories, entity refs, no `/Users/`, RAID-source citation; S6 XRC rendered from `cross_project_conflicts[]` | Grep PASS; no duplication of #276's RAID |

### Release-Level Verification

Per verification-checklist.md:
- [ ] File Integrity
- [ ] Content Correctness
- [ ] Cross-Reference Validity (doc-link integrity via `deploy.sh --check` Check 14)
- [ ] Skill Invocation
- [ ] Output Contract Compliance
- [ ] CIAC-1..5 verdicts (graded release-level at Stage 9)

---

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Complexity |
|-------|----------------|------------|
| #2578 | `git revert <commit>` — additive governance edits, isolated | Low |
| #157 | `git revert` — new standard/template deletable; skill edits revert | Low–Med |
| #1771 | delete `compose-portfolio.py` + revert skill ref | Low |
| #276 | `git revert` — health sections are additive | Low |
| #1169 | `git revert` — aggregation folds into `§Top Risks`, revertable | Low |

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|----------|---------|-----------|
| **Partial Revert** | Isolated issue failure | Revert specific commits per rollback-protocol.md |
| **Full Restore** | Systemic failure | Revert merge commit + rebuild `.skill` packages per rollback-protocol.md |
| **Forward Fix** | Minor issue, fix well-understood | Fix branch per rollback-protocol.md |

---

## Operational Deployment Manifest

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|-----------------|-----------------|-----------|-------------|
| 1 | `operations/skills/ppm-agent/SKILL.md` | Installed skill path | S-2 direct copy + `.skill` rebuild | diff shows no differences; Check 7 |
| 2 | `operations/skills/weekly-status-rollup/SKILL.md` | Installed skill path | S-2 direct copy + `.skill` rebuild | diff shows no differences; Check 7 |
| 3 | `core/CLAUDE.md.template` | runtime `~/Claude/CLAUDE.md` | deploy propagation | template deploys to runtime |

### Schema Migrations

N/A — no schema migrations in this release. The `PORTFOLIO.md` restructure replaces handwritten content (cosmetic; no data migration).

---

## Deviation Log

Departures from the Stage-4 plan of record, ratified at the **Collective-Review scope-lock** (issuecomment-4998973138, operator APPROVED-with-dispositions, 2026-07-16 Thursday). Scope hard-locked through Stage 9. Both adversarial-review Blockers reconcile in Stage 6 (return-to-Solutioning NOT warranted). Recorded verbatim:

| Item | Severity | Disposition (verbatim) |
|---|---|---|
| **XC-1** — staleness age-anchor contradiction (#276 `today` vs #1771 `max(last_published)`) | Blocker | **APPROVED reconciliation:** pin the anchor in #157's contract → age = `today − last_published`, **business days**; #1771's fixed `--as-of` scoped to the `--self-test` fixture only; `weekly-status-rollup §6` passes `--as-of=today` in production. Idempotency preserved. |
| **XC-2** — S6 XRC composition-boundary gap (#157 ↔ #1771 ↔ #1169) | Blocker | **PATH 1 chosen:** add an **8th contract field `cross_project_conflicts[]`** (sourced from Cross-Project Resource Conflict) to #157's net-new contract → S6 fully deterministic/contract-driven, honors CIAC-1, avoids post-freeze retrofit. |
| **#2578-F1** — net-new `_config/programs/<slug>/` folder container | Major | **DROP the container**; revert to the pure-frontmatter home (artifacts under `projects/_config/`, keyed by `program_id`) — honors `embedded-in-parent`, no new convention. |
| **Composer-home (#1771 D-class)** | D-class | **Option A** — `core/deploy/tools/compose-portfolio.py` (idempotency forecloses embedded-prose; co-located with the doc-warehouse FK chain). |
| **#276 R3 right-size** | design | **TRIM** — keep freshness + hard-gate (Rules 1–3; "can't-show-Green-over-failing" delivered by the live worst-component dominance rule); cut the article-sourced A–F grade / multi-layer rubric / integrity-multiplier (0 corpus footprint). |
| **`completeness_score`** | Minor | **OMIT until a G6 producer ships** (0 producers/consumers live; add the field atomically with its producer). |
| **4 Minors** (deviation-log) | Minor | (1) #276 per-category→per-project timestamp narrowing — name in `OPERATIONS.md`; (2) #1771 exit-code — separate `[STALE]` from drift; (3) XC-3 — trust #276's live 7-column S1 over Part A's "bare" wording; (4) `completeness_score` handling (above). |
| **entity-model roster base-shift** | context | Entity-model roster is now **19 entities** (ADR-044 added Finding #19, 2026-07-12) — up from the 18 assumed in the earlier #2578 Stage-5 survey (`5ac42b3`). The #2578 §7 physicalization NOTE is additive and orthogonal to the Finding-#19 content; edits that restate a roster count write **19**. |

**Version determination (recorded delta):** the Stage-4 provisional **v3.75** has been **claimed by the concurrent `skill-and-data-entity-hygiene` release** (merged during this Stage-6 window at `2e83741`/`55cdecc`). This release ships **version-agnostic** and binds the actual version (next-free) atomically at Stage 12. Re-check at Stage 9 entry + Stage 12.

---

## Change Description

(Authored by the Stage 6 release-engineering spoke at PR-creation time per `release/governance/RELEASE_PROTOCOL.md` § Change Description Protocol. Operator-facing, pre-merge. As of Engineering Commit 1, only #2578 (foundation) is engineered; the section is completed as chips 2–5 land on this branch.)

### Outcome

Registers a methodology-neutral **operational tier taxonomy** (portfolio → program → project) and its naming conventions into platform governance, then builds a deterministic `PORTFOLIO.md` write-back surface on that foundation. At Stage 9 Plan Review the operator sees: the program tier registered in `CLAUDE.md.template` + `OPERATIONS.md` with an explicit "Program-scoped ≠ Program tier" disambiguation, a governed rollup contract, a deterministic composer, right-sized health scoring, and cross-component risk aggregation.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #2578 | Program tier + portfolio/program/project naming conventions registered (frontmatter-primary; no program folder) | DONE (Commit 1) |
| #157 | Governed rollup contract + per-project rollup entity | PENDING (chip 2) |
| #1771 | Deterministic PORTFOLIO composer engine | PENDING (chip 3) |
| #276 | Right-sized health scoring (freshness + hard-gate) | PENDING (chip 4) |
| #1169 | Cross-component risk aggregation | PENDING (chip 5) |

### Key decisions

- **XC-1:** staleness anchor pinned in #157's contract (`today − last_published`, business days). See § Deviation Log.
- **XC-2:** 8th contract field `cross_project_conflicts[]` added. See § Deviation Log.
- **#2578-F1:** `_config/programs/` container DROPPED — pure-frontmatter program home. See § Deviation Log.
- **Composer home:** Option A `core/deploy/tools/compose-portfolio.py`. See § Deviation Log.

### Reversibility

**MODERATE — HIGH confidence.** Whole-release rollback = `git revert <merge-sha>` + rebuild `.skill` packages; all changes additive/reversible (new standard/template/composer deletable, governance edits revert, `PORTFOLIO.md` restructure cosmetic).

### Downstream impact

- Enables the deterministic PORTFOLIO write-back the operations-domain (Cowork) rollup consumes post-merge.
- The tier taxonomy (#2578) is the naming SSOT the #157 rollup-entity placement conforms to (CIAC-5).
- The methodology-specific portfolio-artifact set (#2577) remains out of scope — this release ships only the neutral structural layer.

### Cross-references

- Release plan: this file, top section
- Milestone: `pda-rollup-and-portfolio` (#264)
- User-facing release notes: authored at Stage 13 Close per the release-notes standard.
