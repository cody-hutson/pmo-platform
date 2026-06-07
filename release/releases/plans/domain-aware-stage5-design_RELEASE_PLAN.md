---
version: domain-aware-stage5-design
date: 2026-06-07
type: plan
issues: ["#1", "#345", "#346"]
pr: null
links:
  note: null
  log_anchor: "#domain-aware-stage5-design"
reversibility-tier: CHEAP
themes: ["cluster:pipeline-definitions", "cluster:knowledge-architecture"]
domain_practice: "{ source: N/A — pipeline-internal release, date: 2026-06-07, name: domain best-practice corpus (self-referential) }"
domain: governance
---

<!-- reference-durability: allow-version-ref -->

# domain-aware-stage5-design Release Plan

**Milestone:** domain-aware-stage5-design
**Release Class:** `novel` (Stage 4 proposal; operator-rendered at the Collective Review scope-lock, 2026-06-07). Basis: new reference docs (`design-exploration.md` + the `domain-best-practices/` guide class) and ≥4 D-class decisions (D-A…D-E). Cross-cutting's ≥3-`pipeline/stage-*.md`-file threshold is NOT met (only stage-04 + stage-05 in this #1a scope).
**Branch Topology:** `D-C SINGLE` (operator-rendered) — one release branch `release/domain-aware-stage5-design`; sequential Engineering commits; one DRAFT release PR (shared-release-PR append model — #345/#346 commits accrue to this branch and PR later). This plan is committed as the first Engineering commit (Commit 0).
**Differentiation posture (per `novel`):** Engagement density Standard; Stage 9 review depth Deep; Stage 5 activation bias ALL; Stage 13 outcome-window 30-day. Reversibility CHEAP / Confidence HIGH.

**Reflexivity note (this release governs its own domain class):** This release is itself a pipeline-internal / governance deliverable AND its subject is the domain-best-practice machinery. The `domain_practice` label carries the canonical pipeline-internal-exempt form (`source: N/A — pipeline-internal release`) per stage-04 §5.7's exemption, and ALSO carries the new `domain:` class field this very release introduces (`domain: governance`). The release thus self-demonstrates the substrate it builds — the reflexive-cutover discipline (below) keeps the new Stage-5 protocol from firing on its own Stage 5 authoring.

**Stage 4 plan content of record:** Stage 4 Release Planning comment on sub-task #479 (operator-reviewed at the Stage 4 Decision Briefing, 2026-06-07).
**Stage 5 Collective Review verdict:** GO — minimal substrate, scope-locked 2026-06-07 (operator-rendered at the release hub thread; scope-lock DECISION comment of record). Stage 6 Engineering authorized as Tier-3 (autonomous within the locked scope), routed sequentially write-serialized on the single release branch.

---

## Scope — #1a (this PR) + the shared keystone substrate

This release makes Stage 5/7 design **domain-aware** instead of pmo-markdown-bound. Three independent mechanisms layer onto the existing §5.7 `domain_practice` provenance machinery: **#1** (design-exploration protocol + per-domain best-practice guide class), **#345** (domain-appropriate impact-analysis method), **#346** (domain-best-practice review criterion). The keystone scope-lock established that all three branch on an abstract domain signal that had **no concrete substrate** — the `domain_practice` label carried no domain-class field. The corrected build order is: **keystone substrate → #1 (#1a) → #345 (rebased) → #346**.

**This PR (DRAFT) ships #1a + the shared keystone substrate.** #345 and #346 land later on this same branch; this is why the PR opens as a DRAFT and uses non-closing `References` for all three issues. Close-family keywords are added at Stage 12 when the full release merges.

### The keystone substrate (shared, build-FIRST — owned by #1's Stage 6)

The first foundational commit adds a `domain:` class field to the `domain_practice` label schema in `release/references/pipeline/stage-04-planning.md` §5.7 (the "A1.5" sourcing-or-flag step), populated across **Mode A**, **Mode B**, AND the **pipeline-internal exemption** — so every mode carries a domain class. It adds A3-time deliverable-domain classification (the Planning/Solutioning spoke classifies the deliverable's domain from the File-Change-Matrix — the adversarial CD-1 mechanism), and reconciles the "already encoded" exemption to reference the new domain guides at `core/standards/domain-best-practices/`. #345 and #346 consume this one field.

### #1a deliverables (this PR)

1. **`release/references/standards/design-exploration.md`** (NEW) — a Stage-5 Phase-A4 micro-protocol inserting *divergent generation → convergent narrowing* BEFORE the trade-off matrix (today's de-facto entry point). Closes the gap that `design-review-checklist.md` 4.3 demands "≥3 alternatives" with no governed generation step.
2. **`core/standards/domain-best-practices/software.md` + `governance.md`** (NEW) — Applicability-Profile-bearing K1 guides; the domain-best-practice corpus class governed by the four shipped protocols (corpus-curation / framework-corpus-discipline + framework-catalog / applicability-framework / knowledge-architecture + km-protocols). Invention drops to zero on this half — it is conformance.
3. **Additive wiring** of design-exploration + the domain-guide index into `stage-05-solutioning.md` (A4 / §5.7) and the Stage-5 chip pattern in `hub-spoke-bridge.md`; framework-catalog registration of the guide frameworks.

## Locked Stage-6 obligations (from the scope-lock record)

- **K — keystone (shared, build FIRST):** add a `domain:` class field to the `domain_practice` label (stage-04 §5.7), populated across Modes A/B + the pipeline-internal exemption; classify the deliverable's domain at A3 from the File-Change-Matrix; reconcile the "already encoded" exemption to reference the new domain guides. All three issues consume this one field.
- **#1a:** design-exploration + guides consume `domain:`; tighten the guide-vs-`corpus-curation §3` distinction (guide = design-consumption content carrying an Applicability Profile; §3 = sourcing input); guide *content* quality gated at Stage 7/8 (not just structural).
- **#345 (later PR commits):** A3 method-selector consumes `domain:`; accommodate non-markdown methods in the Stage-5 exit gate (`design-review-checklist.md` Section 1); the code-fan-out `.sh` tool is DEFERRED to a follow-up issue (spec-level admission only this release).
- **#346 (later PR commits):** criterion consumes `domain:`; resolve the AC3 internal contradiction by running the governance-walk (drop the exemption short-circuit); apply the `stage-07` dimension-count cascade fix.

## Implementation sequence (write-serialized on the shared branch)

Corrected build order from the scope-lock: **keystone substrate → #1 → #345 (rebased) → #346.** This PR covers the keystone + #1 (#1a). #345 and #346 are sequenced onto this branch in subsequent Stage-6 spokes.

| Order | Step | Issue | File(s) | Notes |
|---|---|---|---|---|
| 0 | Release plan (this file) | hub | `release/releases/plans/domain-aware-stage5-design_RELEASE_PLAN.md` | Engineering Commit 0 |
| 1 | KEYSTONE substrate | #1 | `stage-04-planning.md` §5.7 | Shared — build FIRST. #345/#346 consume the `domain:` field. |
| 2 | design-exploration protocol | #1 | `design-exploration.md` (NEW) | Net-new Stage-5 process tool. |
| 3 | domain best-practice guides | #1 | `core/standards/domain-best-practices/{software,governance}.md` (NEW) | Web-researched, ET-labeled, Applicability-Profile-bearing. |
| 4 | stage-05 wiring | #1 | `stage-05-solutioning.md` (A4 / §5.7) | SHARED FILE with #345 — additive only. **#1 commits FIRST; #345 rebases.** |
| 5 | framework-catalog | #1 | `core/specs/framework-catalog.md` | EXTERNAL rows (GoF / ADR-Nygard / Fowler) + INTERNAL rows for the 2 guides. |
| 6 | chip pattern | #1 | `hub-spoke-bridge.md` Stage-5 chip pattern | D-D second landing. |

## Contention Map + build order

| Live file path | #1 | #345 | #346 | Serialization rule |
|---|:--:|:--:|:--:|---|
| `release/references/pipeline/stage-04-planning.md` (§5.7) | **edit (keystone)** | consumes | consumes | **Shared keystone — build FIRST.** #1 owns the substrate; #345/#346 read the `domain:` field. |
| `release/references/pipeline/stage-05-solutioning.md` | **edit** | **edit** | — | **HARD SERIALIZE.** Both edit this file (#1 A4/§5.7 vs #345 A3). Sequence #1 → #345 on the release branch; #345's Stage 6 spoke rebases onto #1's commit before editing. No concurrent Stage 6 spokes on this file (concurrent-spoke same-branch contention class). |
| `release/references/standards/design-exploration.md` (NEW) | **add** | — | — | No contention. New file. |
| `core/standards/domain-best-practices/` (NEW dir) | **add** | — | — | No contention. New dir + 2 seed files. |
| `core/standards/domain-best-practices/software.md` (NEW) | **add** | — | — | No contention. |
| `core/standards/domain-best-practices/governance.md` (NEW) | **add** | — | — | No contention. |
| `core/specs/framework-catalog.md` | **edit** | — | — | Single-owner (#1). |
| `release/references/how-to/hub-spoke-bridge.md` (Stage-5 chip) | **edit** | — | — | Single-owner (#1). |
| `release/references/templates/design-review-checklist.md` | — | **edit** | **edit** | #345 (Section 1) ∩ #346 (Section 4) → serialize. Not in #1a scope. |
| `release/references/pipeline/stage-07-dev-testing.md` | — | — | **edit** | Single-owner (#346). Not in #1a scope. |
| `release/tools/blast-radius.sh` | — | *(deferred)* | — | #345 code-fan-out `.sh` DEFERRED to a follow-up issue (spec-level admission only this release). |

**Order:** keystone substrate → **#1** → **#345** (rebased) → **#346**.

**Cross-PR Overlap Audit (Stage 6 entry re-check, per audit-baseline discipline):** Baseline RE-PINNED at `3816746` (release-branch base = `origin/main` HEAD). Open-PR population at re-check (2026-06-07): one open PR — **#496** (`release/v3.20-release-corpus-verification-surface`, 17 files). Verified **NO intersection** with any of the 6 in-scope #1a files (`stage-04-planning.md`, `stage-05-solutioning.md`, `design-review-checklist.md`, `hub-spoke-bridge.md`, `framework-catalog.md`, and the new `core/standards/domain-best-practices/` paths). Most recent merge to a contended file: `e51fe53` (v1.05, `design-review-checklist.md` + `stage-05-solutioning.md`) — already on `main`. The Stage 4 default-to-zero open-PR finding is now corrected: the population is non-empty (#496) but non-overlapping. Re-check again at Stage 7/8 entry.

## Stage Applicability Matrix (#1a scope)

| Stage | #1 | Notes |
|---|:--:|---|
| 5 Solutioning | DONE | Activated; adversarial review (#481/#482/#483) + Collective Review scope-lock complete (GO). |
| 6 Engineering | THIS PR | #1a + keystone substrate. |
| 7 Dev Testing | pending | Content-quality review (guide content gated here, not just structural). Domain-Practice Provenance Verification Step fires (this release emits a `domain_practice` label). |
| 8 QA Testing | pending | Governance-touching corpus → QA applies. Check 18 (catalog) inherited via `deploy.sh --check`. |
| 9 Plan Review | pending | Release-scoped GO/NO-GO; `novel` → Deep depth. Operator gate (PR diff). |
| 10–13 | pending | Default. Stage 13: INDEX + DIGEST + RELEASE_NOTES + RELEASE_LOG VERIFIED. |

## Risk Register

| # | Risk | Trigger | Owner | Mitigation | Residual | Reversibility/Confidence |
|---|---|---|---|---|---|---|
| R-1 | Shared-file contention on stage-05 (#1 vs #345) | concurrent Stage 6 spokes | operator/hub | Serialize: #1 commits first, #345 rebases on #1's commit; detached-HEAD refspec-push if parallel pressure arises | LOW | CHEAP / HIGH |
| R-2 | Guide drifts from a 2nd schema over time | future author adds a non-Applicability-Profile field to a guide | operator | The Applicability-Profile schema (applicability-framework §2) is the single shared contract — the K1↔K2–K5 seam REQUIRES schema identity; Check 18 + applicability §2 are the standing controls | LOW | CHEAP / HIGH |
| R-3 | ET5 source (Fowler) authored without paired contraindication | Stage 6 guide authoring | Stage 6 spoke | corpus-curation ET5 row load-bearing test (mandatory paired contraindication); applied in `software.md` | LOW | CHEAP / HIGH |
| R-4 | Catalog row omitted for GoF/ADR/Fowler | guide cites uncataloged framework | Stage 6 spoke | framework-corpus §6 checklist #1 + framework-catalog row append; Check 18a surfaces at deploy | LOW | CHEAP / HIGH |
| R-5 | Reflexive loop — the new Stage-5 protocol fires on its own introducing release | this release's own Stage 5 already ran | Stage 6 author | Reflexive-cutover clause carried in design-exploration §8 + the stage-04 substrate + the guides (introducing-release-exempt) | NONE | CHEAP / HIGH |
| R-6 | Domain-guide staleness | guide cites external sources that drift | operator | Each guide carries dated ET-labeled sources; low-ET (ET5 Fowler) entries carry higher staleness criticality per km-protocols §2 (ET5 → 3mo + forced upgrade-or-retire); catalog `next_review_due` is the standing hook | MODERATE | MODERATE / MEDIUM |

## Verification Plan (Stage 6 → Stage 7/8)

- `test -f release/references/standards/design-exploration.md`; `test -d core/standards/domain-best-practices/`; `grep -l "UNIVERSALITY:" core/standards/domain-best-practices/*.md` returns BOTH guides (Applicability Profile present — the conformance proof).
- `grep -n "design-exploration" release/references/pipeline/stage-05-solutioning.md release/references/how-to/hub-spoke-bridge.md` (AC3 + AC4).
- `grep -n "domain:" release/references/pipeline/stage-04-planning.md` (substrate present in the label schema, all modes + exemption).
- `python3 core/deploy/tools/check-version-anchors.py --catalog-path core/specs/framework-catalog.md` → expect 18a-clean.
- `./deploy.sh --check` Check 18 warn-clean for the new catalog rows (content-resolving — resolves when these commits land per stage-05 §5.5 forecast discipline).
- Each #1 AC1–AC6 verified per the #1a design AC-mapping table.
- Reference-durability: new durable-corpus docs use unconditional inline rules; version-cutover idiom only under a per-file `allow-version-ref` marker; bare `#N` only in a designated reference block.
- Cutover clause present in the stage-04 substrate + design-exploration.md + the guides.

## Tier-A activated design artifacts

| Artifact path | Flow class | Trigger that fired | Tier-A (new) / Tier-B (refresh) |
|---|---|---|---|
| `release/references/standards/design-exploration.md` §7 | Agent process (process-flow) | Process-flow with ≥1 gate AND cited as canonical by stage-05 A4 (design-artifact-standard §7 Tier-A activation row) | Tier-A (new) |

The 2 domain guides are reference docs with tables/profiles, not process flows — **Tier-C exempt** (single-file additive structured prose, no new process flow). Declared explicitly to scope Stage 13 G-CL6.

## Rollback Strategy

All changes are additive durable-corpus edits + new files; no schema migration, no data mutation, no deploy-state change to skills. New protocols carry introducing-release-exempt cutover clauses, so reverting them affects only forward releases. Revert = `git revert` of the release-branch merge. Reversibility: CHEAP / Confidence HIGH.

## File Change Matrix (machine-readable)

One **live** path per line; `intent` = `add` / `edit`. Downstream Stage 7/8/9 chips extract this block deterministically.

```
release/releases/plans/domain-aware-stage5-design_RELEASE_PLAN.md   add    # hub — this plan (Engineering Commit 0)
release/references/pipeline/stage-04-planning.md                    edit   # #1 KEYSTONE — domain: class field in domain_practice label (Mode A/B + pipeline-internal exemption); A3 deliverable-domain classification; reconcile exemption to reference the domain guides; cutover clause
release/references/standards/design-exploration.md                  add    # #1 — NEW divergent-generation→convergent-narrowing→trade-off-matrix Stage-5 micro-protocol (8 sections incl. AC5 worked example + Tier-A process-flow §7 + cutover §8)
core/standards/domain-best-practices/software.md                    add    # #1 — NEW seed guide (D4: GoF/ADR-Nygard/Fowler, ET-labeled, paired CI on ET5 Fowler); Applicability Profile + §5 rubric
core/standards/domain-best-practices/governance.md                  add    # #1 — NEW seed guide (D1/D3: PMBOK7/PRINCE2/Nonaka SECI/Diátaxis, ET-labeled, paired applicability note on ET3 Diátaxis, CI-3 contraindication); Applicability Profile + §5 rubric
release/references/pipeline/stage-05-solutioning.md                 edit   # #1 — additive: A4 reference to design-exploration + §5.7 domain-guide index + #346 interplay forward-note. SHARED with #345 — serialize #1→#345.
core/specs/framework-catalog.md                                     edit   # #1 — EXTERNAL rows (GoF/ADR-Nygard/Fowler) + INTERNAL rows for the 2 guide docs (tier emerging, canonical_doc = guide path)
release/references/how-to/hub-spoke-bridge.md                       edit   # #1 — Stage-5 chip pattern invokes design-exploration (D-D second landing)
```

**Later on this branch (NOT in this PR's #1a commits):**

```
release/references/pipeline/stage-05-solutioning.md                edit   # #345 — A3 admits domain-appropriate impact-analysis method/opt-out (rebased on #1)
release/references/templates/design-review-checklist.md            edit   # #345 (Section 1 non-markdown methods) + #346 (Section 4 domain-best-practice review dimension)
release/references/pipeline/stage-07-dev-testing.md                edit   # #346 — domain-practice review criterion to Phase A/C; dimension-count cascade fix
```

---

### Issue References

- References #1 — domain-aware Stage 5/7 design: design-exploration protocol + per-domain best-practice guide class (#1a scope + keystone substrate ship in this PR).
- References #345 — domain-aware impact analysis (later commits on this branch).
- References #346 — domain-best-practice review criterion (later commits on this branch).
