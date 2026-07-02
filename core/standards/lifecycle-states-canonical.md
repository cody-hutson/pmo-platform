---
title: Lifecycle States — Canonical Source
purpose: The canonical source for the platform's seven independent state-vocabulary spaces — the single place each lifecycle state enum (Context, Domain C, Artifact, and the rest) is defined.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: every skill and schema referencing a lifecycle-state enum (Context / Domain C / Artifact / and the other state spaces); frontmatter-schema.md; the health-check and document-ecosystem specs
---
<!-- reference-durability: allow-link -->
# Lifecycle States — Canonical Source

> **Status:** Stage 6 Engineering
> **Authority:** Standards-doc CROSSWALK. Designates the platform's lifecycle state vocabulary, the `<Object>-<State>` naming convention, and the authoritative-home registry for each state machine. Does NOT redefine states that already have canonical homes — references them.
> **Reversibility tier:** CHEAP / Confidence: HIGH — single new standards doc + 1-line additive cross-reference in `domain-c-lifecycle-protocol.md` + milestone description PATCHes; all atomically revertable via `git revert` (file commits) or `gh api PATCH` with text snapshot in the release plan (milestone descriptions).

---

## §1 Purpose

The platform has **seven independent state-vocabulary spaces** spanning inbound content lifecycle (Context), outbound synthesis lifecycle (Domain C), generated-artifact workflow (Artifact — content-maturity reconciled onto `lifecycle_state`/`approval_state`; promotion-location on `promotion_state`; operational home [`artifact-workflow-protocol.md`](../artifact-workflow-protocol.md)), source-artifact lifecycle (Domain A), managed-knowledge lifecycle (Domain B), trust classification (Trust), and KM-artifact lifecycle (KM). Several share lexically identical state names (`archived`, `draft`, `superseded`, `stale`, `Reviewed`, `Approved`) with different semantics in different machines — a documented collision risk for cross-machine prose, agent reasoning, and downstream consumers.

This document is the **canonical source** for lifecycle state semantics. It:

- **Designates** which state machines exist in the platform and where each is authoritatively defined
- **Prescribes** the `<Object>-<State>` naming convention that disambiguates cross-machine vocabulary
- **Documents** which vocabularies are scoped-out with rationale
- **Enumerates** the cross-machine collision map so consumers and agents can resolve ambiguity at the lexical level
- **Registers** the downstream consumer list — who cites this canonical source as authoritative

**What this canonical source is:**

- A REGISTRY (designates the authoritative home for each state machine) + a CONVENTION (`<Object>-<State>` naming rule for cross-machine prose contexts) + a COLLISION MAP (lists lexical clashes with disambiguation)
- Authoritative for the **naming convention** itself (object-typed prefix discipline applies platform-wide)
- Authoritative for **cross-machine reconciliation** (when two state machines collide, the canonical source resolves)

**What this canonical source is NOT:**

- A self-contained CATALOG that duplicates per-machine state definitions. Per-machine state semantics live at each machine's authoritative home (cited in §3); duplicating them here would create dual-canonical-home drift exposure.
- A replacement for any existing state-machine protocol. Domain C continues to live at [`domain-c-lifecycle-protocol.md`](../../release/references/how-to/domain-c-lifecycle-protocol.md). Context Lifecycle continues to live at [`context-lifecycle-model.md`](../disciplines/context-lifecycle-model.md). Domain A/B lifecycle vocabulary continues to live at [`schemas/frontmatter-schema.md`](../schemas/frontmatter-schema.md) § Category 2. Trust classification continues to live at [`schemas/frontmatter-schema.md`](../schemas/frontmatter-schema.md) § Category 5 and [`document-ecosystem-design.md`](../disciplines/document-ecosystem-design.md) §5.
- A scheduler or enforcement mechanism. The naming convention is grep-verifiable; agents and downstream skills are responsible for applying it.

---

## §2 Object-Typing Convention

The platform's load-bearing semantic contribution from this canonical source is the **`<Object>-<State>` naming rule** for cross-machine vocabulary.

### §2.1 The rule

In **cross-machine prose contexts** (governance docs, skill outputs, briefings, this canonical source), reference any lifecycle state with the form:

```
<Object>-<State>
```

where:

- **Object** ∈ `Context | Artifact | Domain-A | Domain-B | Domain-C | Trust | KM`
- **State** is the bare state name from the authoritative source for that object (verbatim — no renames, no aliases)

**Examples (binding):**

- `Context-Reviewed` (NOT `Reviewed` alone — collides with `Artifact-REVIEWED`)
- `Artifact-APPROVED` (NOT `APPROVED` alone — collides with `Context-Decided`-adjacent semantics)
- `Domain-C-published` (NOT `published` alone — collides with intent across machines)
- `Domain-A-archived` (NOT `archived` alone — 4-way collision per §5)

### §2.2 Bare-name contexts (object prefix NOT required)

Object-prefix discipline applies in **cross-machine prose**. In **schema-field-value contexts** the bare name is correct because the field already declares the object scope:

| Context | Form | Rationale |
|---|---|---|
| YAML frontmatter field value | `lifecycle_state: active` | The field `lifecycle_state` together with the file's `domain: source` (or `managed`, or `generated`) declares the object scope. |
| SQL `WHERE` clause | `WHERE lifecycle_state = 'archived'` | The query's table/column scope already constrains the object. |
| Authoritative-source-internal references | `domain-c-lifecycle-protocol.md` text uses bare `draft / validated / published / stale / archived` | The protocol doc IS the authoritative home for those names; object scope is unambiguous within the doc. |
| `context-lifecycle-model.md` internal state-definition table | `Context-Captured` is fine; bare `Captured` would also be valid within that doc | The framework doc is authoritative for Context states; either form is internally unambiguous. (The framework doc uses object-prefix form for grep-verifiability and to match the canonical convention.) |

### §2.3 Grep-verifiability

The `<Object>-<State>` convention is mechanical:

- A cross-machine prose document that names a state MUST use the object-prefixed form for any state name that appears in §5 Cross-Machine Collision Map.
- Verification: `grep -E '(^|[^A-Za-z-])(Reviewed|Approved|draft|archived|superseded|stale)([^A-Za-z-]|$)' <file>` should return zero hits in cross-machine prose contexts (excluding YAML field-value contexts and authoritative-doc-internal contexts).
- Object-typed forms are themselves grep-verifiable: `grep -E '(Context|Artifact|Domain-A|Domain-B|Domain-C|KM|Trust)-[A-Za-z]+' <file>` enumerates all object-typed references.

---

## §3 In-Scope Machines

This canonical source covers three state machines in scope: Context Lifecycle, Artifact Workflow (operational home [`artifact-workflow-protocol.md`](../artifact-workflow-protocol.md); content-maturity reconciled onto `lifecycle_state`/`approval_state` per §3.2), and Domain C Lifecycle.

### §3.1 Context Lifecycle

**Object prefix:** `Context-`

**Authoritative source:** [`core/disciplines/context-lifecycle-model.md`](../disciplines/context-lifecycle-model.md) — Context Lifecycle Model framework.

**States (5):**

| Object-typed name | Bare name | Brief semantic |
|---|---|---|
| `Context-Captured` | `Captured` | Content arrived in workspace; not yet classified or registered. |
| `Context-Structured` | `Structured` | Classified by file-router AND registered (TR-### entry OR routed to a 01-08 folder with metadata). |
| `Context-Reviewed` | `Reviewed` | Processed by an analytical skill; items extracted; follow-up tags emitted. |
| `Context-Decided` | `Decided` | Items routed to trackers OR rejected with rationale. |
| `Context-Closed` | `Closed` | Items resolved per Evidence Gate (terminal). |

See `context-lifecycle-model.md` for transition diagram (§3), per-state stall detection (§4), and the 17-mechanism map (§5).

### §3.2 Artifact Workflow

**Object prefix:** `Artifact-`

> **⚠️ `artifact_state` DEPRECATED as the content-maturity carrier (reconciled this release).** The legacy single-field `artifact_state` machine (`DRAFT → REVIEWED → APPROVED → PROMOTED → ARCHIVED`) **conflated two orthogonal concerns** onto one field: *content-maturity* (how authoritative the content is) and *promotion-location* (where the file physically sits). Per the artifact-state RCA, those are split:
> - **Content-maturity** (`DRAFT / REVIEWED / APPROVED / ARCHIVED`) converges onto the **canonical `lifecycle_state` + Domain** model (the `project-entity-model.md §4 entity 9` delegation) and the existing `approval_state` field — `artifact_state` is **deprecated** as a content-maturity field (it is not a second field for the same concept; duplicate-source-discipline §1).
> - **Promotion-location** (`PROMOTED` — the `08-Generated/` → `01-07` folder move) carves into a **new orthogonal field `promotion_state`** (enum `staged → promoted → archived-in-place`), schema-homed at `frontmatter-schema.md § Domain C`, owned by `artifact-generator`.
>
> See the §3.2 mapping table below. The **operational-protocol home** is now [`core/artifact-workflow-protocol.md`](../artifact-workflow-protocol.md) (the doc this §3.2 reserved). The content-maturity authority is `frontmatter-schema.md § Category 2` (`lifecycle_state` + Domain); the promotion-location authority is `frontmatter-schema.md § Domain C` (`promotion_state`) + `artifact-workflow-protocol.md §4`.

**Authoritative source:** the **operational protocol** (transitions, gates, the `promotion_state` field, the deprecation + migration contract) lives at [`core/artifact-workflow-protocol.md`](../artifact-workflow-protocol.md). The **content-maturity vocabulary** is the canonical Domain-C / Domain-A vocabulary at `frontmatter-schema.md § Category 2`. This §3.2 retains the legacy `Artifact-<STATE>` object-typed naming convention for cross-machine prose and documents the deprecation + the 3-way mapping (below); it no longer claims the in-repo content-maturity state machine as canonical.

**The 3-way mapping (the legacy `artifact_state` values → their reconciled canonical homes):**

| `artifact_state` value (legacy, deprecated) | Concern | Reconciled canonical home | Mapped value |
|---|---|---|---|
| `DRAFT` | content-maturity (entry) | `lifecycle_state` (Domain C) — `frontmatter-schema.md § Category 2` | `lifecycle_state: draft` |
| `REVIEWED` | content-maturity (agent QA passed) | `approval_state` (Domain A) — `frontmatter-schema.md § Domain A` | `approval_state: under-review` |
| `APPROVED` | content-maturity (human-confirmed) | `approval_state` (Domain A) | `approval_state: approved` |
| `PROMOTED` | **promotion-location** | `promotion_state` (NEW) — `frontmatter-schema.md § Domain C` + `artifact-workflow-protocol.md §4` | `promotion_state: promoted` |
| `ARCHIVED` | content-maturity (terminal) **or** location (Auto-Archive) | `lifecycle_state` / `promotion_state` | `lifecycle_state: archived` (content terminal) · `promotion_state: archived-in-place` (staging-sweep terminal) |

`REVIEWED` / `APPROVED` reuse the **existing** `approval_state` field (no third maturity field is minted — duplicate-source-discipline §1). The four content-maturity values map cleanly onto the existing `lifecycle_state` / `approval_state` carriers; only `PROMOTED` (a folder-move with no content-Domain analogue) needs the new `promotion_state` home — so this is a **carve, not a rename**.

**Object-typed naming convention (retained for cross-machine prose):** the `Artifact-<STATE>` object-prefixed forms (`Artifact-DRAFT`, `Artifact-REVIEWED`, etc.) remain the cross-machine disambiguation convention per §2.1. They now denote the *reconciled* values (e.g., `Artifact-DRAFT` ≡ the Domain-C `draft` content-maturity entry, not a separate `artifact_state: DRAFT` stamp).

**Lineage fields:** the artifact-instance lineage fields (`parent_artifact`, `sibling_topic`, `supersedes`/`superseded_by`) are schema-defined at `core/schemas/frontmatter-schema.md` (Domain A / Domain C) — unchanged by this reconciliation; field types, the inverse pair, and the lineage-vs-provenance boundary are defined there.

> **§3-registration — DEFERRED to G8 / G10 (operator-gated; FLAGGED, NOT executed here).** Registering `promotion_state` as a **new in-scope state machine in §3** (a §3.4-style sibling to §3.1 Context / §3.2 Artifact / §3.3 Domain C) is an Autonomy-Tier-0 governance touch — the same class `project-entity-model.md §2` already defers (the registration of the entity Axis-1 state-machine family into `lifecycle-states-canonical.md §3` is owned by G8 / G10). To avoid a half-registration (`promotion_state` in §3 while the entity Axis-1 family is not), **`promotion_state` is defined this release in `artifact-workflow-protocol.md §4` + `frontmatter-schema.md § Domain C` only**, and its §3 machine-registration is deferred to the same G8/G10 cycle. *This §3.2 content edit — deprecating `artifact_state` as content-maturity and documenting the mapping — is authorized by the artifact-state reconciliation work item under the §8 Change Protocol (Issue + plan + Collective Review approval); it does not register a new §3 machine and does not change the count of registered in-scope machines (still three: §3.1, §3.2, §3.3).*

### §3.3 Domain C Lifecycle

**Object prefix:** `Domain-C-`

**Authoritative source:** [`release/references/how-to/domain-c-lifecycle-protocol.md`](../../release/references/how-to/domain-c-lifecycle-protocol.md) — Domain C Lifecycle Protocol for synthesized-intelligence artifacts.

**States (5):**

| Object-typed name | Bare name | Brief semantic |
|---|---|---|
| `Domain-C-draft` | `draft` | Newly generated by Artifact Generator; not yet validated. |
| `Domain-C-validated` | `validated` | Passed agent consistency checks; awaiting human confirmation. |
| `Domain-C-published` | `published` | Human-confirmed as authoritative synthesis. |
| `Domain-C-stale` | `stale` | Source material has changed since creation/publication. |
| `Domain-C-archived` | `archived` | No longer current; retained for historical reference (terminal). |

See `domain-c-lifecycle-protocol.md` for transition rules, agent vs. human authority, and the staleness-detection trigger (source-file change via Query 6 of `schemas/sqlite-index-schema.md`).

### §3.4 Relationship to Context Lifecycle

The Context Lifecycle (inbound) and Domain C Lifecycle (outbound synthesis) are **complementary** machines, not overlapping. Inbound content moves through Context states; when a skill synthesizes an output into `08-Generated/`, the output enters Domain C at `Domain-C-draft`. The Context state of the source file does NOT determine the Domain C state of a derived synthesis. See `context-lifecycle-model.md` §7 for the framework-side distinction.

---

## §4 Scoped-Out Vocabularies

Four additional state-vocabulary spaces exist in the platform with already-canonical homes. This canonical source **registers them with rationale** but does NOT redefine their state semantics (per §1 — duplication creates dual-canonical-home drift exposure).

### §4.1 Domain A Lifecycle

**Object prefix:** `Domain-A-`

**Authoritative source:** [`core/schemas/frontmatter-schema.md`](../schemas/frontmatter-schema.md) § Category 2 — Lifecycle. Domain A files follow the **Baselined Document** pattern (formal state changes, explicit approval; C12).

**States (5):** `created / draft / active / superseded / archived`

**Scope-out rationale:** Domain A state vocabulary is already canonical in `frontmatter-schema.md` § Category 2. The schema is the authoritative source for `lifecycle_state` field values and the Baselined Document pattern. Object-prefix form `Domain-A-<state>` applies to this vocabulary in cross-machine prose; bare form applies in YAML/SQL contexts per §2.2.

### §4.2 Domain B Lifecycle

**Object prefix:** `Domain-B-`

**Authoritative source:** [`core/schemas/frontmatter-schema.md`](../schemas/frontmatter-schema.md) § Category 2 — Lifecycle. Domain B files follow the **Living Document** pattern (continuous updates, no formal baseline; C12).

**States (7):** `created / emerging / current / needs-review / stale / superseded / archived`

**Scope-out rationale:** Same as Domain A — authoritative source already established at `frontmatter-schema.md` § Category 2. Object-prefix form `Domain-B-<state>` applies in cross-machine prose; bare form applies in YAML/SQL contexts.

### §4.3 Trust Categories

**Object prefix:** `Trust-`

**Authoritative source:** [`core/schemas/frontmatter-schema.md`](../schemas/frontmatter-schema.md) § Category 5 — Trust, and [`core/disciplines/document-ecosystem-design.md`](../disciplines/document-ecosystem-design.md) §5 (Trust Model). Defined per design brief §14.

**Categories (5):** `evidence / controlled-truth / interpretation / working-context / historical-record`

**Scope-out rationale:** Trust is an **orthogonal classification dimension**, not a lifecycle state. Lifecycle states answer "where is this content in its production workflow?"; Trust categories answer "how authoritative is this content right now?". The two dimensions co-vary in places (Trust-lifecycle consistency rules in `frontmatter-schema.md` § Category 5) but remain conceptually distinct. Including Trust in this canonical source would conflate dimensions; scoping-out preserves dimensional clarity. Object-prefix form `Trust-<category>` applies in any cross-machine prose where a Trust value appears alongside a lifecycle state (rare, but possible in cross-domain consistency checks); bare form applies in YAML/SQL contexts.

### §4.4 KM-Artifact Lifecycle

**Object prefix:** `KM-`

**Authoritative source:** [`core/disciplines/km-protocols.md`](../disciplines/km-protocols.md#km-artifact-lifecycle) — Knowledge-Management Protocols §1, KM-Artifact Lifecycle. Defines the state machine for K1-tier managed-knowledge artifacts (ADRs, promoted lessons-learned, codified-practice docs, the reference corpus docs themselves). Composes with — does not duplicate — [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) (K1-K5 tiers) and [`corpus-curation.md`](../disciplines/corpus-curation.md) (ET1-ET5 evidence tiers).

**States (5):** `KM-Proposed / KM-Active / KM-Deprecated / KM-Superseded / KM-Rejected`

**Scope-out rationale:** KM-artifact lifecycle state vocabulary is already canonical in `km-protocols.md` §1. That doc is the authoritative source for state definitions, transition rules (`KM-Proposed → KM-Active → {KM-Deprecated | KM-Superseded}` + `KM-Rejected`), and the ADR-as-canonical-instance binding (Nygard 2011 vocabulary preserved). Object-prefix form `KM-<State>` applies in cross-machine prose per §2.1; the bare form applies in frontmatter / SQL contexts per §2.2. The KM- machine is genuinely new (it is not Domain A's Baselined `created/draft/active/superseded/archived` set nor Domain B's Living set — see km-protocols.md §8 ADR record); this registration satisfies the §8 Change Protocol governance requirement deliberately deferred out of the km-protocols work.

---

## §5 Cross-Machine Collision Map

The table below enumerates **bare state names** that appear in two or more state machines, with disambiguation guidance. This is the master reference for cross-machine vocabulary resolution.

| Bare state name | Appears in | Object-typed forms | Disambiguation |
|---|---|---|---|
| `Reviewed` / `REVIEWED` | Context (§3.1), Artifact (§3.2 — deprecated `artifact_state`; now `approval_state: under-review`) | `Context-Reviewed`, `Artifact-REVIEWED` | Context-Reviewed = inbound content processed by analytical skill; Artifact-REVIEWED = outbound artifact passed agent/skill review gate — now carried by `approval_state: under-review` per the §3.2 mapping (the standalone `artifact_state: REVIEWED` is deprecated). Different actors, different evidence. |
| `Approved` / `APPROVED` | (none currently — semantically adjacent to `Context-Decided` and `Artifact-APPROVED`) | `Artifact-APPROVED` only | The bare term "Approved" is intuitive but ambiguous. Context Lifecycle uses `Context-Decided` (item routed/rejected); the Artifact Workflow's human-approved gate is now carried by `approval_state: approved` (the deprecated `artifact_state: APPROVED` per the §3.2 mapping). Cross-machine prose should use the object-typed form to avoid implying the wrong actor/gate. |
| `draft` / `DRAFT` | Artifact (§3.2 — now `lifecycle_state: draft`), Domain A (§4.1), Domain C (§3.3) | `Artifact-DRAFT`, `Domain-A-draft`, `Domain-C-draft` | 3-way collision. `Artifact-DRAFT` = generated artifact at content-maturity entry — reconciled to the Domain-C `lifecycle_state: draft` (the deprecated `artifact_state: DRAFT` per §3.2); `Domain-A-draft` = source artifact in formal-baseline draft; `Domain-C-draft` = synthesis artifact newly generated by Artifact Generator. Different actors (AI / human author / Artifact Generator) and different transition semantics. |
| `archived` / `ARCHIVED` | Artifact (§3.2 — now `lifecycle_state: archived`), Domain A (§4.1), Domain B (§4.2), Domain C (§3.3) | `Artifact-ARCHIVED`, `Domain-A-archived`, `Domain-B-archived`, `Domain-C-archived` | **4-way collision.** Terminal state across four machines with different retention semantics. The Artifact content-terminal is reconciled to `lifecycle_state: archived` (the staging-area Auto-Archive sweep is the *location* terminal `promotion_state: archived-in-place`, a separate concern — see §3.2). Trust-lifecycle rule (`frontmatter-schema.md` § Category 5): `archived` lifecycle state requires `Trust-historical-record`. |
| `stale` | Domain B (§4.2), Domain C (§3.3) | `Domain-B-stale`, `Domain-C-stale` | Both = content no longer current. `Domain-B-stale` = tracker content past `staleness_threshold_days` without new evidence; `Domain-C-stale` = synthesis output where source material has changed (Query 6 staleness detection). Different detection mechanisms. |
| `superseded` / `Superseded` | Domain A (§4.1), Domain B (§4.2), KM (§4.4) | `Domain-A-superseded`, `Domain-B-superseded`, `KM-Superseded` | All three = replaced by a newer artifact. `Domain-A-superseded` and `Domain-B-superseded` typically carry a `superseded_by` field pointing to the replacement; `KM-Superseded` follows the same convention per `km-protocols.md` §1 (mirrors `frontmatter-schema.md` § Category 2). Trust-lifecycle rule: `superseded` shifts `Trust-` to `historical-record`. |
| `created` | Domain A (§4.1), Domain B (§4.2) | `Domain-A-created`, `Domain-B-created` | Both = entry-point state on ingest. `Domain-A-created` typically transitions to `Domain-A-draft` then `Domain-A-active` (Baselined pattern); `Domain-B-created` typically transitions to `Domain-B-emerging` then `Domain-B-current` (Living pattern). |
| `Captured` | Context (§3.1) only | `Context-Captured` | No current collision, but reserved for future-proofing. Use object-typed form in cross-machine prose. |
| `Structured` | Context (§3.1) only | `Context-Structured` | Same as above — reserved. |
| `Decided` | Context (§3.1) only | `Context-Decided` | Same as above — reserved. |
| `Closed` / `closed` | Context (§3.1); Plan operational-terminal (hypercare subtype — `entity-field-schemas.md` §3.4a / V-PLN-05); RAID-Item Axis-1 (`entity-field-schemas.md` §3.6) | `Context-Closed`, `Plan-closed`, `RAID-Item-closed` | 3-way collision (case-variant `Closed`/`closed`). `Context-Closed` = inbound items resolved per Evidence Gate (terminal); `Plan-closed` = a hypercare Plan's operational-terminal (pre-`archived`, subtype-conditioned extension of the V-PLN-05 base — NOT a new §3 machine, DEFER-G8); `RAID-Item-closed` = a RAID-Item Axis-1 terminal. Different actors/machines — use the object-typed form in cross-machine prose. |
| `delivered` | Plan operational-terminal (training subtype — `entity-field-schemas.md` §3.4a / V-PLN-05) only | `Plan-delivered` | No current collision — reserved. A training Plan's operational-terminal (pre-`archived`, subtype-conditioned extension of the V-PLN-05 base — NOT a new §3 machine, DEFER-G8). |
| `executed` | Plan operational-terminal (cutover subtype — `entity-field-schemas.md` §3.4a / V-PLN-05) only | `Plan-executed` | No current collision — reserved. A cutover Plan's operational-terminal (pre-`archived`, subtype-conditioned extension of the V-PLN-05 base — NOT a new §3 machine, DEFER-G8). |
| `validated` | Domain C (§3.3) only | `Domain-C-validated` | No current collision — reserved. |
| `published` | Domain C (§3.3) only | `Domain-C-published` | No current collision — reserved. |
| `promoted` / `PROMOTED` | Artifact promotion-location (§3.2 → `promotion_state`) only | `Artifact-PROMOTED` | No current collision. Carries the **promotion-location** concern (the `08-Generated/` → `01-07` folder move), now homed on the `promotion_state` field (enum `staged → promoted → archived-in-place`; `frontmatter-schema.md § Domain C` + `artifact-workflow-protocol.md §4`) — orthogonal to content-maturity (`lifecycle_state`). The deprecated `artifact_state: PROMOTED` is superseded by `promotion_state: promoted`. |
| `active` / `Active` | Domain A (§4.1), KM (§4.4) | `Domain-A-active`, `KM-Active` | Case-variant collision (`active` lowercase vs `Active` Title-Case). `Domain-A-active` = source artifact in Baselined-pattern active state; `KM-Active` = managed-knowledge artifact ratified / published as current authoritative knowledge. Different machines, different actors, different evidence. |
| `current` | Domain B (§4.2) only | `Domain-B-current` | No current collision — reserved. |
| `emerging` | Domain B (§4.2) only | `Domain-B-emerging` | No current collision — reserved. |
| `needs-review` | Domain B (§4.2) only | `Domain-B-needs-review` | Semantically adjacent to `Context-Reviewed` but distinct (tracker-side staleness signal vs. inbound-content review). Use object-typed form. |
| `evidence` | Trust (§4.3) only | `Trust-evidence` | No lifecycle collision (Trust is orthogonal per §4.3), but use object-typed form in any cross-dimension prose. |
| `controlled-truth` | Trust (§4.3) only | `Trust-controlled-truth` | Same. |
| `interpretation` | Trust (§4.3) only | `Trust-interpretation` | Same. |
| `working-context` | Trust (§4.3) only | `Trust-working-context` | Same. |
| `historical-record` | Trust (§4.3) only | `Trust-historical-record` | Same. |
| `Proposed` | KM (§4.4) only | `KM-Proposed` | No current collision — reserved. Per `km-protocols.md` §1, `KM-Proposed` = authored, awaiting operator ratification (Nygard ADR "Proposed" alias). |
| `Deprecated` | KM (§4.4) only | `KM-Deprecated` | No current collision — reserved. Per `km-protocols.md` §1, `KM-Deprecated` = no longer recommended; **no successor** authored (terminal state, Nygard ADR "Deprecated" alias). |
| `Rejected` | KM (§4.4) only | `KM-Rejected` | No current collision — reserved. Per `km-protocols.md` §1, `KM-Rejected` = proposed then operator-declined; retained for why-not traceability (terminal state, Nygard ADR "Rejected" alias). |

**Cross-machine consistency rule (R5 mitigation):** All bare state names in the table above MUST match the authoritative source for the machine in question, verbatim. State name renames in any authoritative source require updating this canonical source's collision map (Issue + plan + approval per CLAUDE.md "No ungoverned changes").

---

## §6 Consumer Registry

Downstream consumers that cite this canonical source as authoritative for lifecycle vocabulary register here.

### §6.1 Registered consumers (initial ship)

| Consumer | Consumption surface | Reference location |
|---|---|---|
| [`core/disciplines/context-lifecycle-model.md`](../disciplines/context-lifecycle-model.md) | Adopts `<Object>-<State>` convention for the 5 Context states; cross-references this doc in §2 (State Definitions) and §7 (Distinction from Domain C) | Framework doc §2 header note + §7 cross-reference + §8 Consumers table |
| [`release/references/how-to/domain-c-lifecycle-protocol.md`](../../release/references/how-to/domain-c-lifecycle-protocol.md) | Registers Domain C 5 states under `Domain-C-` prefix; additive 1-line cross-reference in Purpose section | Domain C protocol Purpose section (additive line per F2 / Collective Review approval) |
| [`core/artifact-workflow-protocol.md`](../artifact-workflow-protocol.md) | The operational-protocol home for the Artifact entity. Cites this canonical source's §3.2 for the `Artifact-<STATE>` object-typed naming convention; documents the `artifact_state` deprecation + the 3-way mapping (content-maturity → `lifecycle_state`/`approval_state`; promotion-location → `promotion_state`). | §6 Consumer-Registry Hook of `artifact-workflow-protocol.md`; registered at this release's Stage 6. The content-maturity vocabulary is canonical at `frontmatter-schema.md § Category 2`; the operational protocol + `promotion_state` are canonical at `artifact-workflow-protocol.md`. |

### §6.2 Forward-citation consumers (future releases)

These consumers are designed but not yet authored. They will register here when their releases ship.

| Consumer | Planned release | Expected consumption |
|---|---|---|
| file-router ingest and KB capability | future | file-router attaches Context Lifecycle state metadata to routed files using `Context-Captured` / `Context-Structured` (soft outbound). |
| Future cross-domain consistency checker | TBD | Reads §5 Collision Map programmatically; enforces object-prefix discipline in cross-machine prose. |

### §6.3 Registration protocol

A new consumer registers by:

1. Adding a cross-reference to this canonical source in the consumer's own doc (e.g., `## Framework Reference` subsection in SKILL.md per `context-lifecycle-model.md` §6).
2. Optionally adding a row to §6.1 of this canonical source. New rows do NOT require a separate Issue if the consumer's release ships with a cross-reference that grep-verifies. New rows DO require a PR (same release branch as the consumer change) so reviewers can see both ends of the registration.

---

## §7 Cross-Reference Discipline

This section makes the bare-name vs. object-typed boundary explicit with examples.

### §7.1 Object-typed form REQUIRED

Any of the following contexts MUST use the object-typed `<Object>-<State>` form for state names that appear in §5 Collision Map:

| Context | Example |
|---|---|
| Cross-machine prose in governance docs | "When `Context-Reviewed` content gets routed to a tracker, the resulting tracker entry is independent of any `Domain-C-` lifecycle for an associated synthesis." |
| Skill output that references multiple machines | "Daily processing summary: 3 transcripts moved to `Context-Decided`; 1 RAID register entry transitioned to `Domain-B-needs-review`." |
| Cross-reference tables (like §5 here) | Always object-typed in the comparison columns. |
| Briefings and exec-level docs | "This release introduces the `<Object>-<State>` naming convention to disambiguate `Reviewed` and `Approved` across Context Lifecycle and Artifact Workflow." |

### §7.2 Bare-name form ACCEPTABLE

Any of the following contexts MAY use bare state names (object-prefix optional):

| Context | Example |
|---|---|
| YAML frontmatter field value | `lifecycle_state: active` (the `domain: source` field declares the object scope) |
| SQL `WHERE` clause | `WHERE lifecycle_state = 'archived' AND domain = 'generated'` |
| Inside an authoritative-source doc | `domain-c-lifecycle-protocol.md` § Lifecycle States uses bare `draft / validated / published / stale / archived` — the doc IS the authoritative home; the object scope is unambiguous within the doc. |
| Inside a framework-doc state-definition table | `context-lifecycle-model.md` §2 may use bare `Captured / Structured / Reviewed / Decided / Closed` in the "State" column header alongside object-typed form. (The framework doc currently uses object-typed form throughout for grep-verifiability.) |

### §7.3 Grep verification patterns

For automated cross-reference integrity checks (Stage 7 DT regression set per the release plan):

```bash
# 1. Find all object-typed state references in a file
grep -E '(Context|Artifact|Domain-A|Domain-B|Domain-C|KM|Trust)-[A-Za-z]+' <file>

# 2. Find bare state names that should be object-typed (collision-risk audit)
grep -E '(^|[^A-Za-z-])(Reviewed|REVIEWED|Approved|APPROVED|draft|DRAFT|archived|ARCHIVED|superseded|stale)([^A-Za-z-]|$)' <file>
# Filter the result: hits inside YAML field-value, SQL WHERE, or authoritative-doc-internal context are acceptable; cross-machine prose hits are violations.

# 3. Verify a consumer registers in §6.1
grep 'standards/lifecycle-states-canonical.md' <consumer-file>
```

---

## §8 Provenance

| Field | Value |
|---|---|
| **Authored** | Initial release (Stage 6 Engineering) |
| **Release branch** | `release/context-lifecycle-and-retrieval` |
| **Source design** | Stage 5 Solutioning — Candidate 1 (Standards-doc CROSSWALK) approved at Collective Review |
| **Companion artifact** | [`core/disciplines/context-lifecycle-model.md`](../disciplines/context-lifecycle-model.md) — Context Lifecycle Model framework — shipped same release |
| **Reversibility tier** | CHEAP (single new file + 1-line additive Domain C edit + 2 milestone description PATCHes; all atomically revertable) |
| **Confidence** | HIGH (object-typed convention is grep-verifiable; references-not-duplicate avoids drift exposure; ≥2 demonstrating consumers at ship time) |
| **Cutover applicability** | Applies to all docs going forward. Pre-existing docs continue to use bare state names; new docs adopt object-typed form. |
| **Change protocol** | Modifications to §2 convention, §3 in-scope machines, §4 scope-out rationale, or §5 collision map require an Issue + plan + approval per CLAUDE.md "No ungoverned changes". Additions to §6.1 registered consumers are exempt (consumer adds cross-reference in own release; PR diff carries both ends). |
