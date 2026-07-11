<!-- reference-durability: allow-link -->
# Artifact Workflow Protocol

> **Status:** Stage 6 Engineering
> **Authority:** Operational-protocol home for the **Artifact** entity's workflow. This is the doc `lifecycle-states-canonical.md §3.2` / §6.2 reserved as the planned home (`core/artifact-workflow-protocol.md`). It **binds** the Artifact entity's two lifecycle axes to their existing canonical homes and defines the one genuinely-new field (`promotion_state`). It does **not** redefine the canonical state vocabularies — those live at their cited homes (duplicate-source-discipline §1).
> **Reversibility tier:** MODERATE / Confidence: HIGH — the doc + the `frontmatter-schema.md §Cat-2` field add + the `lifecycle-states-canonical.md §3.2` remap are atomically revertable via `git revert`; the skill-side blast radius (the `artifact_state` reference migration) is carried by the migration sibling card, not this doc.

---

## §1 Purpose & Scope

This protocol expresses the **Artifact** entity's operational workflow **once**. It is the operational realization of `project-entity-model.md §4 entity 9` (the Artifact reconciliation seam) for the `artifact-generator` skill surface.

The Artifact's workflow has **two orthogonal concerns**, which a single legacy field (`artifact_state`) historically conflated:

| Concern | Question it answers | Canonical home |
|---|---|---|
| **Content-maturity** | *How authoritative is the content?* | `lifecycle_state` + Domain-A/B/C — the §4 entity 9 delegation. Authoritative schema: [`core/schemas/frontmatter-schema.md`](schemas/frontmatter-schema.md) § Category 2. |
| **Promotion-location** | *Where does the file physically sit?* | `promotion_state` (defined at §4 of this doc; schema-homed at `frontmatter-schema.md` § Domain C). |

**In scope.** The two-concern model; the content-maturity binding (cite, not restate); the promotion-location field definition (`promotion_state`); the `artifact_state` deprecation + migration contract; the Consumer-registry hook into `lifecycle-states-canonical.md §6.1`.

**Out of scope (deferred / disjoint — do NOT edit here).**
- The **frozen** Artifact Axis-1↔Axis-2 delegation in `project-entity-model.md §4 entity 9` — this doc *aligns to* the freeze, it does not change it (a change there requires reopening the establishing issue via a Tier-2 SCOPE CHANGE).
- **Registration of a new `promotion_state` state machine into `lifecycle-states-canonical.md §3`** — that is the operator-gated G8/G10 governance touch (parallel to the entity Axis-1 family registration `project-entity-model.md §2` already defers to G8/G10). **FLAGGED, not executed** (see §5.3).
- The skill-side `artifact_state` reference migration (SKILL.md edits, the artifact-lint dual-read removal) — the executable target is **handed to the migration sibling card** (see §5.2); this doc ships the reconciled model the migration sibling card migrates onto.

---

## §2 Two-Concern Model (the load-bearing separation)

**Content-maturity is orthogonal to promotion-location.** The two answer different questions about the same Artifact and vary independently:

- `lifecycle_state` (Domain-keyed) answers *how mature is the content?* — `draft` / `validated` / `published` / `stale` / `archived` (Domain C).
- `promotion_state` answers *where does the file physically sit?* — `staged` / `promoted` / `archived-in-place`.

A `published` (content-mature) artifact may still be `staged` (not yet moved out of `08-Generated/`) — the two states do not imply one another. This is the [`project-entity-model.md §2`](disciplines/project-entity-model.md) **boundary axiom** in action: *a logical entity is a data record the PMO tracks; the file(s) that persist it are a separate concern with their own lifecycle. Conflating the two is forbidden.* The §3 two-axis model (`lifecycle_state` Axis-1 / `content_lifecycle_pattern` Axis-2) is the conceptual basis; `promotion_state` is a **third, file-location dimension that sits outside the two-axis entity model** (the boundary axiom's "the file… is a separate concern") and therefore does not perturb the frozen §3/§4 two-axis schema.

### §2.1 Retired `artifact_state` value → new home (the mapping)

The legacy `lifecycle-states-canonical.md §3.2` "Artifact Workflow" 5-state machine (`DRAFT → REVIEWED → APPROVED → PROMOTED → ARCHIVED`) is split along the two concerns. Each value maps to an **existing** canonical field — no third maturity field is minted:

| `artifact_state` value (legacy) | Concern | New canonical home | Mapped value |
|---|---|---|---|
| `DRAFT` | content-maturity (entry) | `lifecycle_state` (Domain C) | `lifecycle_state: draft` |
| `REVIEWED` | content-maturity (agent QA passed) | `approval_state` (Domain A) | `approval_state: under-review` |
| `APPROVED` | content-maturity (human-confirmed) | `approval_state` (Domain A) | `approval_state: approved` |
| `PROMOTED` | **promotion-location** | `promotion_state` (NEW) | `promotion_state: promoted` |
| `ARCHIVED` | content-maturity (terminal) **and/or** location (Auto-Archive) | `lifecycle_state` / `promotion_state` | `lifecycle_state: archived` (content terminal) · `promotion_state: archived-in-place` (staging-sweep terminal) — disambiguated by concern |

**Mapping notes (operator-ratified at Collective Review):**
- `REVIEWED`/`APPROVED` reuse the **existing** `approval_state` field (`frontmatter-schema.md § Domain A`, enum `draft / under-review / approved / rejected`) rather than minting a third maturity field. `REVIEWED → approval_state: under-review`; `APPROVED → approval_state: approved`. This honors duplicate-source-discipline §1 (consolidate to the existing canonical carrier).
- `DRAFT` is the content-maturity **entry** state on the Domain-C content machine (`frontmatter-schema.md § Category 2` / `domain-c-lifecycle-protocol.md`).
- `ARCHIVED` is concern-disambiguated: a content-retirement is `lifecycle_state: archived`; a staging-area Auto-Archive sweep is `promotion_state: archived-in-place`.

This is a **carve, not a rename**: four of the five legacy values are content-maturity (and map cleanly onto the existing `lifecycle_state` / `approval_state` carriers); only `PROMOTED` is an orphan location fact needing a new home. A wholesale rename (`artifact_state → promotion_state`) would mis-file the four content states into a location field — the data forbids it (the artifact-state RCA enum-mapping table).

---

## §3 Content-Maturity Binding (`lifecycle_state` + Domain)

For a generated Artifact (Domain C, originating in `08-Generated/`):

- **Entry state:** `lifecycle_state: draft` — stamped by `artifact-generator` at emit (the artifact-generator Step-5 metadata header). artifact-generator only ever stamps the **entry** state; later content states are governed transitions, not generation-time stamps.
- **Authoritative content machine:** the Domain-C content-lifecycle machine `draft → validated → published → stale → archived` is the authoritative content-maturity machine. It is **defined at** [`core/schemas/frontmatter-schema.md`](schemas/frontmatter-schema.md) § Category 2 and [`domain-c-lifecycle-protocol.md`](../release/references/how-to/domain-c-lifecycle-protocol.md) — **not restated here** (duplicate-source-discipline §1).
- **Approval signal:** the `approval_state` field (`frontmatter-schema.md § Domain A`, enum `draft / under-review / approved / rejected`) carries the agent-QA / human-confirm signal that the legacy `REVIEWED` / `APPROVED` states expressed (per the §2.1 mapping).
- **The frozen delegation:** the Artifact entity's Axis-1 *delegates to Axis-2* — `lifecycle_state` mirrors `frontmatter-schema.md § Category 2` for the backing file's domain (`project-entity-model.md §4 entity 9`). This protocol is the operational realization that makes the `artifact-generator` implementation finally honor that delegation (today it stamps a third machine, `artifact_state`, into the Axis-1 slot — the drift this reconciliation closes).

**Cross-reference:** `entity-field-schemas.md` V-ART-05 (the `lifecycle_state`-delegates-to-Axis-2 validation rule, `DEFER-G8`) is the validation-layer expression of this binding; it is unchanged by this reconciliation.

---

## §4 Promotion-Location Protocol (`promotion_state`)

The genuinely-new field this protocol defines. It carves the promotion-location concern (the legacy `PROMOTED` folder-move) out of `artifact_state` into its own first-class, queryable slot.

| Property | Specification |
|---|---|
| **Field** | `promotion_state` |
| **Type / Required** | enum · NO (Domain-C generated artifacts only; absent ⇒ not-yet-staged / not-applicable) |
| **Enum** | `staged → promoted → archived-in-place` |
| **Owner** | `artifact-generator` (creates the Artifact) |
| **Schema home** | [`core/schemas/frontmatter-schema.md`](schemas/frontmatter-schema.md) § Domain C — Synthesized Intelligence (alongside the existing `promoted_from`) |
| **Semantics** | `staged` = file lives in `08-Generated/` (the staging area). `promoted` = file has been physically moved to its `01-07` target folder. `archived-in-place` = file moved to `08-Generated/_archived/` (the Auto-Archive sweep target) — a *location* terminal, distinct from the content-maturity `lifecycle_state: archived`. |
| **Relationship to `lifecycle_state`** | **Orthogonal** (see §2). Content-maturity ≠ file-location. |
| **Relationship to existing fields** | Composes with `folder` (§ Category 6 — the current folder) and `promoted_from` (§ Domain C — promotion provenance). Consistency rule: `promotion_state: promoted ⇒ folder ∉ {08-generated, _generated}` (a promoted file has left the staging area — both the legacy `08-generated` and the new ADR-078 `_generated` staging bin; the rule artifact-lint Check 4 already enforces, now expressed on a dedicated field instead of inferred from `artifact_state: PROMOTED`). |

### §4.1 Transitions

| From | To | Trigger | Authority |
|---|---|---|---|
| (none) | `staged` | Artifact emitted into `08-Generated/` (artifact-generator Step 5) | artifact-generator (Tier-2 staging auto-write) |
| `staged` | `promoted` | Promotion Workflow move `08-Generated/` → `01-07` | operator-gated (the move IS the authorization) |
| `staged` | `archived-in-place` | 10-business-day Auto-Archive sweep (unreviewed staged artifact) | Auto-Archive sweep |

**No `promoted → archived-in-place` transition.** A promoted file has left staging; its later retirement is a content-maturity event (`lifecycle_state: archived`), not a staging-location move.

### §4.1.1 Frontmatter is preserved across the `staged → promoted` move (move-with-preserve)

The promotion **executor** is the **`artifact-generator` Promotion Workflow** (§ Promotion Workflow in that skill; the operator-gated move is the authorization). On promotion it mutates **only** `promotion_state` → `promoted`, `folder` → the target bin, and the `lifecycle_changed` stamp; the rest of the frontmatter block — `domain`, `lifecycle_state`, `generated_by`, `source_inputs`, `trigger_source`, `id`, and every lineage field — is **retained, never stripped**. This realizes the #201 **move-with-preserve** semantic: promotion changes *where the file sits*, never *what it records about its origin*, so a promoted artifact stays queryable as `domain: generated`. Content-maturity (`lifecycle_state`) is not re-derived by the move — it advances only through its own governed transitions.

### §4.1.2 Retirement cadence + archive-before-delete invariant (never-delete upheld)

The generated-artifact lifecycle runs a regular **lint → promote → archive** cadence with **no hard-delete terminal**:
- **lint** — `artifact-lint` (graph-integrity checks; recommend-only).
- **promote** — the `artifact-generator` Promotion Workflow above (`staged → promoted`, provenance preserved).
- **archive** — `artifact-generator` Auto-Archive (unreviewed `staged` > 10 business days → `_generated/_archived/`, `promotion_state: archived-in-place`) **plus** the `generated-cleanup` skill (Tier-1 recommend-only retirement proposals; `/schedule`-able, so the cadence "runs regularly").

Every retirement terminal is **recoverable** — a file is moved to `_generated/_archived/` or flipped to `lifecycle_state: archived` **in place**, **never hard-deleted** (the platform never-delete guarantee). This upholds **archive-before-delete**: archive *is* the terminal. No autonomous **purge** (hard-delete) step is defined; a retention-windowed purge, if ever wanted, is a scope expansion under its own governed Issue — it is not self-authorized in this protocol.

### §4.2 Refusal / autonomy

- `staged` is stamped at **Autonomy Tier 2** (the `08-Generated/` staging boundary auto-write per `core/specs/autonomy-tiers.md`).
- `staged → promoted` is the **operator-gated** Promotion Workflow move — `artifact-generator` never self-advances `promotion_state` past `staged` (mirrors the existing "never stamp a later state at generation time" discipline for content-maturity).

### §4.3 Why a dedicated field (not a rename, not folded into `lifecycle_state`, not inferred)

| Rejected approach | Why rejected |
|---|---|
| Rename `artifact_state → promotion_state` wholesale | Drags the four content-maturity states (`DRAFT/REVIEWED/APPROVED/ARCHIVED`) into a location field; the the artifact-state RCA enum table proves four of five values are content. |
| Fold `PROMOTED` into `lifecycle_state` (add a `promoted` content state) | `PROMOTED` has no content-maturity meaning — content is equally `published` before and after the move. Forging a content state from a location fact is the exact §4 entity 9 mis-realization the RCA root-caused; the boundary axiom forbids it. |
| Drop `PROMOTED`, infer from `folder` | Loses the queryable Auto-Archive-vs-promotion distinction (the 10-day staging-timeout the lint + health-check key on). `promoted_from` already proves the model wants promotion as explicit data, not string-parsed inference. |

---

## §5 Deprecation + Migration Contract

### §5.1 `artifact_state` is DEPRECATED as a content-maturity field

`artifact_state` is **deprecated**. It is not a second field for the content-maturity concept; its content-maturity states converge onto `lifecycle_state` / `approval_state` (§2.1) and its promotion-location concern carves into `promotion_state` (§4). During the migration window it remains readable (the artifact-lint dual-read continues to resolve it as a fallback) until the migration sibling card retires that dual-read. After migration, `artifact_state` is absent from the live `core/schemas/` + `operations/skills/` surface (excluding the deprecation note in `lifecycle-states-canonical.md §3.2` itself).

### §5.2 Executable migration target (handed to the migration sibling card — blocked by this card)

The migration sibling card consumes the reconciled model this card ships and executes the mechanical reference migration. **Scope: live references in `core/schemas/` + `operations/skills/` ONLY** — NOT `release/releases/` history (immutable audit trail) and NOT `core/standards/` (the `lifecycle-states-canonical.md §3.2` deprecation note + the W0a `entity-lifecycle-protocol.md` forward-reference are prose, not stamps). All SKILL.md edits route through `pmo-skill-editor` per `skill-deployment.md`; `.skill` packages rebuild at release-cut.

**Reference inventory (survey @ anchor `ae0a204`, 2026-06-22):**

| Target | Migration action | Refs |
|---|---|---|
| `operations/skills/artifact-generator/SKILL.md` | Replace the `artifact_state: DRAFT` Step-5 stamp with `lifecycle_state: draft` (content) + `promotion_state: staged` (location). Re-point the Promotion Workflow (`APPROVED→PROMOTED` ⇒ set `promotion_state: promoted` + move). Re-point Auto-Archive (`artifact_state: DRAFT` sweep ⇒ `promotion_state: staged` sweep) and Health Check / zombie (`artifact_state ≠ ARCHIVED` ⇒ `lifecycle_state ≠ archived`). | 20 |
| `operations/skills/artifact-generator/references/lifecycle-states.md` | Rewrite the application-layer mapping table onto the reconciled model (content states → `lifecycle_state`/`approval_state`; promotion → `promotion_state`). | 8 |
| `operations/skills/artifact-generator/references/{wrapper-mode,tech-doc-routing,prd-routing}.md` | Re-point the `artifact_state: DRAFT` stamp reference (1 each). | 3 |
| `operations/skills/artifact-lint/SKILL.md` | **Remove the dual-read** (the `artifact_state` primary + `lifecycle_state` fallback collapses to a single `lifecycle_state` read; the "reading only one state field" failure mode collapses). Re-point Check 4 displaced-content to read `promotion_state` (+ `folder`) instead of `artifact_state: PROMOTED`. | 14 |
| `operations/skills/artifact-lint/references/{edge-cases,work-plan-taxonomy}.md` | Re-point the promoted-but-not-moved cross-read to `promotion_state` (+ `folder`). | 3 |
| `core/schemas/per-skill-output-contracts.md` | Update the artifact-lint output-contract (dual-read line → single read; staged-report header `artifact_state: DRAFT` ⇒ `lifecycle_state: draft` + `promotion_state: staged`). | 3 |
| `operations/skills/{pmo-tier-1-support,pmo-tier-2-support,pmo-knowledge-manager}/SKILL.md` (+ `pmo-tier-1-support/references/escalation-handoff-record.md`) | **Mechanical secondary consumers** — these reference `artifact_state: DRAFT` only via *composing* artifact-generator Generate Mode (they do not independently key on later states). Update the composed-staging reference to `lifecycle_state: draft` + `promotion_state: staged`. | 4 + 2 + 2 + 2 |

**Verification (post-migration):** `grep -rl 'artifact_state' core/schemas operations/skills` returns **zero** (excluding the deprecation note in `lifecycle-states-canonical.md §3.2`, which is in `core/standards/`, outside this grep scope). Because counts drift as the branch advances, the migration sibling card SHOULD re-run the live inventory (`grep -rln 'artifact_state' core/schemas operations/skills`) at execution time rather than relying on the @-anchor figures above.

### §5.3 Out-of-migration scope (immutable / disjoint — DO NOT touch)

| Surface | Why excluded | Routing |
|---|---|---|
| `release/releases/{RELEASE_LOG,RELEASE_DIGEST,RELEASE_INDEX,*_RELEASE_NOTES,*_RELEASE_PLAN}` | immutable release audit trail — never rewritten | accepted-residual |
| `core/standards/template-protocol.md` `review_status` machine | a SEPARATE template-lifecycle machine for the **template** object — same lexical 5 states, different object (DISJOINT per `lifecycle-states-canonical.md §5`) | not a migration target |
| `core/standards/km-governance-framework.md` `PROMOTED → KM-Active` seam | different object (KM corpus); cite `promotion_state` once the model ships | next-release/roadmap note — flag for a follow-up, not the migration sibling card |
| `core/standards/entity-lifecycle-protocol.md` (W0a) `artifact_state` forward-reference | prose narrative pointing at this reconciliation; in `core/standards/`, not in the migration sibling card's `core/schemas/`+`operations/skills/` scope | leave as-is (it correctly names this card and its migration sibling as the owner) |

---

## §6 Consumer-Registry Hook

This protocol registers as a Consumer of [`core/standards/lifecycle-states-canonical.md`](standards/lifecycle-states-canonical.md) (the planned Stage-13-close action named at that doc's §3.2 / §6.2):

- It cites `lifecycle-states-canonical.md §3.2` for the object-typed `Artifact-<STATE>` naming convention.
- The `lifecycle-states-canonical.md §6.1` Consumer Registry adds a row for this doc, and the §3.2 authoritative-source pointer updates to cross-reference this protocol as the **operational-protocol home** (with `lifecycle_state` + Domain as the content-maturity authority and `promotion_state` as the promotion-location authority). Those §3.2 / §6.1 / §6.2 edits land in `lifecycle-states-canonical.md` under this card.

---

## §7 Provenance

| Field | Value |
|---|---|
| **Authored** | Stage 6 Engineering (Wave 0b) |
| **Source design** | LOCKED Stage-5 Solutioning spec (the Stage-5 Solutioning sub-task); operator-ratified mapping/field/§3-defer decisions at Collective Review |
| **Design input** | RCA on the artifact-state defect (verdict: AXIS-2-CARRIER-LEGITIMATE-but-misnamed; the enum-mismatch table; Q1 = the promotion-vs-fact question this protocol resolves) |
| **Companion edits (this card)** | `frontmatter-schema.md § Category 2 / § Domain C` (`promotion_state` add); `lifecycle-states-canonical.md §3.2 / §5 / §6` (deprecate `artifact_state` content-maturity, remap, register this doc) |
| **Aligns to (FROZEN — not edited)** | `project-entity-model.md §4 entity 9` (Artifact Axis-1 delegates to Axis-2) + §2 boundary axiom |
| **Migration sibling** | the migration sibling card (executes the `artifact_state` reference migration onto this reconciled model; blocked by this card) |
| **Reversibility tier** | MODERATE — doc + schema + §3.2 remap revert atomically via `git revert`; the migration sibling card carries the skill-side blast radius |
| **Confidence** | HIGH on the separation (RCA TRULY-DISTINCT-AXES falsification + the lint's `folder` cross-read are decisive); the field NAME `promotion_state` is the operator-confirmed canonicalization |
| **Change protocol** | Modifications to the two-concern model (§2), the `promotion_state` field (§4), or the deprecation/migration contract (§5) require an Issue + plan + approval per CLAUDE.md "No ungoverned changes". |
| **Deferred governance touch (FLAGGED, NOT executed)** | Registering `promotion_state` as a new in-scope machine in `lifecycle-states-canonical.md §3` is the operator-gated G8/G10 governance change — deferred to the same cycle that registers the entity Axis-1 family (`project-entity-model.md §2`). |
