# Release Plan — 15-generated-vs-source-provenance

> **Version:** provisional **v2.28** (bump-class **minor**; binds at the Stage 12 atomic version claim). Theme-named branch/path bake in NO version — the number may drift if a sibling claims v2.28 first; the durable plan-time declaration is the bump-class. Anchor at plan time: highest mainline tag = **v2.27** (v2.28 confirmed unclaimed at Engineering Commit 0; v3.20 excluded as orphan lineage).
> **Branch:** `release/15-generated-vs-source-provenance` (theme-named, D-C SINGLE).
> **Card:** #205 (single open card). Siblings #200 (absorbed) + #201 (superseded) verified CLOSED on `origin/main` — not in this build.
> **Source:** Stage 4 Release Planning sub-task (#2086). Reformatted as a plan doc; the File Change Matrix fenced block is preserved verbatim.

---

## Summary (30 seconds)

This release delivers a **single open card — #205** (provenance marker fields for AI-generated artifacts). Siblings #200 (absorbed; closed on 2026-06-15) and #201 (superseded by shipped lifecycle/promotion work; closed on 2026-06-26) are verified CLOSED on `origin/main`; this release does not touch them. The two design decisions are **pre-locked by the operator** (D2: canonicalize `source_inputs`, deprecate `synthesis_scope` → alias; D3: add a stable artifact `id` here, route structured `source_ref`/`relationships[]` to the structured-edge follow-on).

Every AC was verified against `origin/main` with grep:
- **`generated_by`** — genuinely absent from `frontmatter-schema.md` (0 hits). The only repo hit is the *template-population* `generated_by` in `template-protocol.md`, which **forward-references the instance-side field as its comparison anchor** — a currently-dangling reference (AC-1/AC-1b confirmed load-bearing).
- **`source_inputs`** — named-but-undefined in `frontmatter-schema.md` (explicit "not yet defined in this schema"). AC-2 residual confirmed.
- **stable `id`** — absent from Category 3 (AC-2b residual confirmed).
- **AC-3 (generated-vs-source domain/folder split)** — already present (`domain` A/B/C + `folder` enum including `08-generated` + Domain A/B/C field tables). Confirm-only; do not rebuild.
- **4 emitters** (`artifact-generator`, `comms-writer`, `daily-status`, `ppm-agent`) — 0 hits for `generated_by`/`source_inputs` (AC-4 residual confirmed; all 4 live in `operations/skills/`).
- **OPERATIONS.md** — no instance-marker/forward-only section (AC-5 residual confirmed).
- **pmo-qa-auditor** — no `generated_by`/provenance check (AC-6 residual confirmed; lives in `core/skills/`).

**Recommendations at a glance:** Release Class = **`novel`**; D-Version bump-class = **`minor`**, provisional **v2.28**; D-C topology = **SINGLE**; Stage 5 = **REDUCE** (design pre-decided — confirm-the-three-fields only); Stages 7/8 = **REDUCE** to a grep/lint conformance pass (no executable surface).

---

## Dependency Graph

This is a single-card release, so the cross-issue graph is trivial; the load-bearing dependency is the **intra-#205 build order** and one **external compatibility edge**.

```
Cross-issue (release scope):
  #205  --(no outbound edge in-scope)-->  none
  #200 [CLOSED, absorbed]    not in build
  #201 [CLOSED, superseded]  not in build

External edges (out-of-scope, carry forward):
  template-protocol.md S4.2/S8  --forward-ref-->  frontmatter-schema.md generated_by (instance)
      ^ DANGLING today; #205 AC-1/AC-1b RESOLVES it (reciprocal flag both sides)
  #205  --relates-to-->  structured-edge follow-on   (structured source_ref tracker field +
                                  relationships[] edges; D3 routes the graph-population half there;
                                  #205 owns ONLY the header id field)

Intra-#205 build order (the real sequence):
  AC-1/AC-1b/AC-2/AC-2b  (schema field-adds, incl. reciprocal S8 flag)
        |  (skills must emit fields the schema defines)
        v
  AC-4  (4 emitters wire generated_by + source_inputs on write; synthesis_scope->alias migration tail)
        |  (governance + QA reference the now-defined marker)
        v
  AC-5 (OPERATIONS.md marker + forward-only policy)  ||  AC-6 (pmo-qa-auditor presence spot-check)
  AC-3  (confirm-only; no edge — already shipped)
```

**Evidence for the schema-before-emitter edge:** AC-4's emit rule and AC-6's presence check both reference field names (`generated_by`, `source_inputs`) that do not exist in `frontmatter-schema.md` today. Wiring a skill to emit, or auditing for the presence of, an undefined field is incoherent — the schema definition lands first. This is a true `DEPENDS_ON`.

**Evidence for the AC-1b reciprocity edge:** `template-protocol.md` §8 drift-prevention **rule 5** states verbatim: *"Dual-semantics field names MUST be flagged in BOTH locations. Specifically: `generated_by` (template-author vs instance-generator)…"* Adding the instance-side field (AC-1) WITHOUT the reciprocal flag (AC-1b) leaves the §8 contract half-satisfied and recreates the reader-conflation §8 exists to prevent. AC-1 and AC-1b are a single atomic edit.

---

## Implementation Sequence

1. **Schema field-adds — `frontmatter-schema.md` Category 3 (Provenance)** *(atomic group)*
   - **AC-1** — add `generated_by` (`<skill-name> v<semver>`, e.g. `ppm-agent v6.3`); instance-population semantics; version-bearing; distinct from `created_by` (name-or-skill, no version).
   - **AC-1b** — add the reciprocal dual-semantics flag (the §8 both-locations contract) in `frontmatter-schema.md`, cross-referencing `template-protocol.md` §8 rule 5. **Resolves the dangling forward-reference.**
   - **AC-2** — define `source_inputs` as the canonical cross-domain provenance carrier (upstream human evidence: TR-### / MSG-### / paths). Replace the "not yet defined" placeholder with a real definition.
   - **AC-2b (D3)** — add a stable, filename-independent artifact `id` to Category 3 so `blast_radius(source)` is deterministic and a missing back-link is a detectable dangling edge.
   - **AC-2 migration half (D2)** — mark Domain-C `synthesis_scope` as **deprecated → alias** of `source_inputs` with a migration window; one live field for the concept. `trigger_source` is a distinct concern ("what triggered") and stays.

2. **Emitter wiring — AC-4** *(after the schema defines the fields)*
   - `operations/skills/{artifact-generator,comms-writer,daily-status,ppm-agent}/SKILL.md` — each emits `generated_by` + `source_inputs` on write; document the **missing-header → regenerate-with-header** rule.
   - **Migration tail:** wherever a skill currently writes `synthesis_scope`, migrate the emit to `source_inputs` within the alias window (ppm-agent in particular).

3. **Governance + QA references — AC-5 || AC-6** *(parallel-safe; different files)*
   - **AC-5** — `core/governance/OPERATIONS.md`: record the provenance-marker requirement + the **forward-only (no-backfill)** policy.
   - **AC-6** — `core/skills/pmo-qa-auditor/SKILL.md`: add a `generated_by`-presence spot-check (random sample/week).

4. **AC-3 — confirm-only** *(no edit beyond the optional §Scope one-liner; #200 closed as absorbed)*

**Note on skill-edit path (5 skill files):** all five emitter/QA SKILL.md files carry `skill_discipline_migrated_v10_2: true`. The `block-skill-direct-edit.sh` PreToolUse hook gates raw edits; the active hook `.mode` is **warn** (shakedown), so edits surface a warn message but are not blocked. The `pmo-skill-editor` **discipline** (impact + coherence + regression) is applied inline per edit. `.skill` packages for the 5 skills rebuild at release-cut (Stage 13 / Check 7 freshness) — NOT in this Engineering stage.

---

## Stage Applicability Matrix

| Stage | Applies? | Rationale |
|---|---|---|
| **5 Solutioning** | **REDUCE** | Design is pre-decided (D2/D3 locked at prework); Stage-5-grade field specs already exist. Confirm-the-three-field-specs + the AC-1b reciprocity wiring. No new ADR (design rationale folds into the schema edit + this plan). |
| **6 Engineering** | **APPLIES** | The substantive build: schema field-adds + 4 emitter edits + OPERATIONS.md + pmo-qa-auditor. Single writer, sequential. |
| **7 Dev Testing** | **REDUCE** | No executable surface — every AC verifies by `grep`/lint over markdown. DT reduces to a doc-conformance grep pass. |
| **8 QA Testing** | **REDUCE** | Review-only over committed diff. QA re-runs the AC greps, the cross-doc `generated_by` both-locations coherence check, and confirms exactly one live field for the `source_inputs`/`synthesis_scope` concept. |
| **9 Plan Review** | **APPLIES (Deep)** | Release-scoped gate. `novel` class → Deep depth: PR diff review includes the cross-doc §8 contract closure + blast-radius on the 4 emitters + alias-migration completeness. The human GO/NO-GO. |
| **12 Execute** | **APPLIES** | Merge, atomic version claim (provisional v2.28 binds here per defer-to-merge), tag, RELEASE_LOG row + visible-H4 Deployment Log. |
| **13 Close** | **APPLIES** | INDEX + DIGEST + RELEASE_NOTES + RELEASE_LOG `VERIFIED`; `.version` stamp + CHANGELOG append + `.skill` package rebuild for the 5 edited skills; mark #205 closed. `novel` → 30-day outcome-window. |

---

## File Change Matrix

```
core/schemas/frontmatter-schema.md            EDIT  AC-1 add generated_by + AC-1b reciprocal dual-semantics flag + AC-2 define source_inputs (replace lines 119-132 placeholder) + AC-2b add stable id + AC-2/D2 mark synthesis_scope deprecated->alias; Category 3 (lines 80-88) is the add-target; AC-3 confirm-only (domain/folder already present lines 161/164)
operations/skills/artifact-generator/SKILL.md EDIT  AC-4 emit generated_by + source_inputs on write; missing-header->regenerate rule; synthesis_scope->source_inputs emit migration; via pmo-skill-editor Mode A (migrated skill)
operations/skills/comms-writer/SKILL.md        EDIT  AC-4 emit generated_by + source_inputs on write; missing-header->regenerate rule; via pmo-skill-editor Mode A (migrated skill)
operations/skills/daily-status/SKILL.md        EDIT  AC-4 emit generated_by + source_inputs on write; missing-header->regenerate rule; via pmo-skill-editor Mode A (migrated skill)
operations/skills/ppm-agent/SKILL.md           EDIT  AC-4 emit generated_by + source_inputs on write; missing-header->regenerate rule; via pmo-skill-editor Mode A (migrated skill)
core/governance/OPERATIONS.md                  EDIT  AC-5 record provenance-marker requirement + forward-only (no-backfill) policy
core/skills/pmo-qa-auditor/SKILL.md            EDIT  AC-6 add generated_by-presence spot-check (random sample/week); via pmo-skill-editor Mode A (migrated skill)
core/standards/template-protocol.md            EDIT-CONDITIONAL  AC-1b read-side; the S8 dual-semantics flag for generated_by already exists. SKIP per hub resolution — the S8 contract is satisfied by the schema-side reciprocal note alone; NO edit
release/releases/plans/15-generated-vs-source-provenance_RELEASE_PLAN.md   ADD   Stage 4 release plan, committed as Engineering Commit 0 under D-C SINGLE (theme-named path; insulated from version drift)
packages/artifact-generator.skill              EDIT  rebuild at release-cut (Check 7 freshness) — AC-4 skill changed [Stage 13]
packages/comms-writer.skill                    EDIT  rebuild at release-cut — AC-4 skill changed [Stage 13]
packages/daily-status.skill                    EDIT  rebuild at release-cut — AC-4 skill changed [Stage 13]
packages/ppm-agent.skill                       EDIT  rebuild at release-cut — AC-4 skill changed [Stage 13]
packages/pmo-qa-auditor.skill                  EDIT  rebuild at release-cut — AC-6 skill changed [Stage 13]
.version                                        EDIT  Stage 13 version stamp (close-out tool gap — stamp manually)
CHANGELOG.md                                    EDIT  Stage 13 Keep-a-Changelog append (close-out tool gap — append manually)
```

**Domain classification:** `domain: governance`. The entire matrix is internal pmo-platform artifacts (schema, governance, skill SKILL.md files, packages) — no application source/tests. Sourcing-exempt (pipeline-internal release) but domain-classified `governance`. Secondary surface: a thin `software` slice (5 SKILL.md files).

---

## Risk Register

| ID | Class | Risk | Likelihood | Impact | Owner | Mitigation |
|---|---|---|---|---|---|---|
| R1 | **Contract / scope** | **Dual-semantics-flag omission.** Shipping AC-1 (instance `generated_by`) WITHOUT AC-1b (reciprocal §8 flag) leaves `template-protocol.md` §8 rule 5 half-satisfied and recreates the reader-conflation the flag exists to prevent. | MEDIUM | HIGH | Engineering + Stage 8 QA | Treat AC-1 + AC-1b as ONE atomic schema edit. Stage 8 coherence check: confirm `generated_by` dual-semantics flag appears in BOTH `frontmatter-schema.md` and `template-protocol.md` §8. Stage 9 Deep review names the §8 closure as the highest-value diff check. |
| R2 | **Alias-migration / duplicate-source** | **Two live fields for one concept.** If `synthesis_scope` is not actually marked deprecated→alias (D2) and emitters keep writing it alongside `source_inputs`, the schema ships two live fields for "upstream evidence". | MEDIUM | MEDIUM | Engineering | One canonical (`source_inputs`); `synthesis_scope` → alias with a documented migration window; AC-4 migrates the emit sites; Stage 8 confirms exactly one live field. |
| R3 | **Scope creep** | #205 owns the header `id` field ONLY (D3). Pulling in the structured `source_ref` tracker field or `relationships[]` edge population over-runs the release. | LOW | MEDIUM | Engineering + hub | Hold the line at the header field. Any structured-edge work → note for the structured-edge follow-on, do not build here. |
| R4 | **Migration-tail sizing** | The `synthesis_scope` emit-site count is unknown at plan time. A larger-than-expected tail could expand AC-4 effort. | MEDIUM | LOW–MEDIUM | Engineering | Count emit sites at Engineering start; the alias keeps existing reads valid so migration completes inside the window without blocking the release. |
| R5 | **Skill-edit governance path** | 5 of 8 edited files are migrated SKILL.md files. Edits route through the `pmo-skill-editor` discipline; `.skill` packages must rebuild at cut (Check 7). | LOW | MEDIUM | Engineering | Apply the editor discipline inline; rebuild the 5 packages at release-cut; run `./deploy.sh --check`. |
| R6 | **Rollback complexity** | Low. Schema + governance + SKILL.md edits are additive markdown; no data migration, no destructive change, no executable surface. | LOW | LOW | — | **Rollback = revert the release PR.** Additive fields default-absent (recommended-not-required). Reversibility: **CHEAP**. |

**Aggregate rollback strategy:** Revert the single release PR. Every field added is `Required: No`, so reverting cannot orphan existing frontmatter; the forward-only policy guarantees no historical artifacts were rewritten. CHEAP across the board.

---

## Operator Decisions

- **D-ReleaseClass: `novel`.** Trigger: enum (a) "≥1 issue introduces a new reference doc, schema, or skill" — #205 adds new schema fields (`generated_by`, `source_inputs`, stable `id`) and resolves a load-bearing cross-doc contract. Differentiation posture: Engagement **Standard**; Stage 9 **Deep**; Stage 5 bias **ALL** (operationalized as REDUCE-confirm); Stage 13 **30-day** outcome-window. CHEAP / HIGH.
- **D-Version: bump-class `minor`; provisional v2.28 (accept).** Feature/field-add release (additive schema + skill capability), not a patch. Authoritative highest mainline = **v2.27**; v2.28 confirmed unclaimed. Number binds at the Stage 12 atomic claim per defer-to-merge. CHEAP pre-Engineering / HIGH.
- **D-C: SINGLE.** A single card has no per-issue PR-isolation benefit. SINGLE is the default; the plan commits as Engineering Commit 0 on `release/15-generated-vs-source-provenance`. CHEAP / HIGH.

---

## Verification Plan

| AC | Verification Method | Expected Result |
|---|---|---|
| **AC-1** | `grep -n 'generated_by' core/schemas/frontmatter-schema.md` | ≥1 hit in Category 3 defining the instance-side `generated_by` (`<skill> v<semver>`), distinct from `created_by`. |
| **AC-1b** | `grep -niE 'dual.?semantic\|both location\|generated_by' core/schemas/frontmatter-schema.md` AND confirm it references `template-protocol.md` §8 | Flag present on the schema side; the §8 both-locations contract satisfied on both sides — forward-reference no longer dangling. |
| **AC-2** | `grep -n 'source_inputs' core/schemas/frontmatter-schema.md` | `source_inputs` DEFINED (not merely named) as the canonical cross-domain provenance carrier; placeholder replaced. |
| **AC-2 (alias)** | `grep -n 'synthesis_scope' core/schemas/frontmatter-schema.md` | `synthesis_scope` marked deprecated → alias; exactly ONE live field. |
| **AC-2b** | `grep -nE '\| .id. ' core/schemas/frontmatter-schema.md` | A stable artifact `id` field defined in the provenance header. |
| **AC-3** | `grep -niE 'domain\|folder\|08-generated' core/schemas/frontmatter-schema.md` (confirm-only) | Already PASS; #200 noted as absorbed. |
| **AC-4** | `for s in artifact-generator comms-writer daily-status ppm-agent; do grep -c generated_by operations/skills/$s/SKILL.md; done` | Each of the 4 SKILL.md files emits `generated_by` + `source_inputs`; missing-header → regenerate rule documented. |
| **AC-5** | `grep -niE 'provenance\|no-backfill\|forward-only' core/governance/OPERATIONS.md` | Marker requirement + forward-only (no-backfill) policy. |
| **AC-6** | `grep -niE 'generated_by\|provenance' core/skills/pmo-qa-auditor/SKILL.md` | A `generated_by`-presence spot-check (random sample/week). |
| **Cross-doc coherence (Stage 8)** | `grep -l generated_by core/schemas/frontmatter-schema.md core/standards/template-protocol.md` | BOTH files carry the dual-semantics flag (the §8 contract closure). |

---

## Recommendations

1. **Approve the plan as scoped: #205 only.** Do not re-open #200 (absorbed) or #201 (superseded).
2. **Render the three operator decisions:** D-ReleaseClass = `novel`; D-Version = bump-class `minor`, provisional v2.28; D-C = SINGLE.
3. **Stage posture:** Stage 5 **REDUCE** (no new ADR); Stages 7 + 8 **REDUCE** (grep + cross-doc coherence). Stage 9 stays **Deep**.
4. **Treat AC-1 + AC-1b as one atomic edit** — closing the `template-protocol.md` §8 dangling forward-reference is the headline review item.
5. **Apply the `pmo-skill-editor` discipline to the 5 SKILL.md edits** (migrated skills) and **rebuild their `.skill` packages at release-cut** (Check 7).
6. **Count the `synthesis_scope` emit-site tail at Engineering start**; the alias keeps existing reads valid so the release is not blocked on a long tail.
7. **Out-of-scope, route to the structured-edge follow-on:** the structured `source_ref` tracker field and `relationships[]` edge population. #205 owns ONLY the header `id` field (D3 seam).
8. **Stage 13 close-out tool gap (carry-forward):** theme-named milestone — **manually** stamp `.version`, append `CHANGELOG.md`, and ensure `cleanup-orphan-state.sh` sweeps the `chore/15-*` / `release/15-*` branches.
9. **Audit-baseline re-check at Stage 9:** re-run the open-PR check over the 8 touched files at Stage 9 entry — a single later PR against `frontmatter-schema.md` invalidates the default-to-zero.
