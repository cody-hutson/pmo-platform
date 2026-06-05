<!-- reference-durability: allow-link -->
# Lifecycle States — Canonical Source

> **Status:** Stage 6 Engineering
> **Authority:** Standards-doc CROSSWALK. Designates the platform's lifecycle state vocabulary, the `<Object>-<State>` naming convention, and the authoritative-home registry for each state machine. Does NOT redefine states that already have canonical homes — references them.
> **Reversibility tier:** CHEAP / Confidence: HIGH — single new standards doc + 1-line additive cross-reference in `domain-c-lifecycle-protocol.md` + milestone description PATCHes; all atomically revertable via `git revert` (file commits) or `gh api PATCH` with text snapshot in the release plan (milestone descriptions).

---

## §1 Purpose

The platform has **seven independent state-vocabulary spaces** spanning inbound content lifecycle (Context), outbound synthesis lifecycle (Domain C), generated-artifact workflow (Artifact, planned), source-artifact lifecycle (Domain A), managed-knowledge lifecycle (Domain B), trust classification (Trust), and KM-artifact lifecycle (KM). Several share lexically identical state names (`archived`, `draft`, `superseded`, `stale`, `Reviewed`, `Approved`) with different semantics in different machines — a documented collision risk for cross-machine prose, agent reasoning, and downstream consumers.

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
| YAML frontmatter field value | `lifecycle_state: active` | The field `lifecycle_state` together with the file's `domain: A` (or `B`, or `C`) declares the object scope. |
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

This canonical source covers three state machines in scope: Context Lifecycle (this release), Artifact Workflow (planned), and Domain C Lifecycle (existing).

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

**Authoritative source (forward-binding to the planned protocol doc):** the Artifact Workflow state machine (`DRAFT → REVIEWED → APPROVED → PROMOTED → ARCHIVED`) is defined in-repo by this §3.2. The states + transition rules + frontmatter convention + lineage-graph fields are restated below; a future release will ship a co-located protocol doc at `pmo-platform/reference/artifact-workflow-protocol.md` that will become the authoritative home for the operational protocol (transitions, gates, automation hooks). Until then, this §3.2 is the canonical source for the vocabulary + state machine. The future implementation MUST use these state names verbatim per forward-binding contract (provenance: state semantics shipped this release; see `pmo-platform/governance/RELEASE_LOG.md`).

**States (5):**

| Object-typed name | Bare name | Brief semantic |
|---|---|---|
| `Artifact-DRAFT` | `DRAFT` | AI-generated artifact authored; not yet reviewed. |
| `Artifact-REVIEWED` | `REVIEWED` | Reviewed by an analytical skill / agent QA gate. |
| `Artifact-APPROVED` | `APPROVED` | Human-approved as ready for downstream consumption. |
| `Artifact-PROMOTED` | `PROMOTED` | Promoted from `08-Generated/` to the target project folder (01-07). |
| `Artifact-ARCHIVED` | `ARCHIVED` | No longer current; retained per archive policy. |

**State-transition rules (in-repo restatement; supersedes external citation):**

| From state | To state | Trigger | Authority |
|---|---|---|---|
| (none) | `Artifact-DRAFT` | New artifact authored by AI / agent | Authoring skill |
| `Artifact-DRAFT` | `Artifact-REVIEWED` | Analytical skill or agent QA gate completes | Skill / gate |
| `Artifact-REVIEWED` | `Artifact-APPROVED` | Human reviewer marks ready for downstream consumption | Operator |
| `Artifact-APPROVED` | `Artifact-PROMOTED` | Promotion from `08-Generated/` to target project folder (01-07) | Skill / operator |
| `Artifact-PROMOTED` | `Artifact-ARCHIVED` | No longer current; retained per archive policy | Skill / operator |
| any | `Artifact-ARCHIVED` | Out-of-band archival (terminal state) | Operator |

**Frontmatter convention (in-repo restatement; the planned protocol doc will extend with automation hooks):**

| Field | Type | Required | Semantic |
|---|---|---|---|
| `artifact_state` | enum | YES | One of the 5 bare-name states above |
| `parent_artifact` | string | NO | Path to the artifact this derives from |
| `supersedes` | string | NO | Path to an artifact this replaces |
| `sibling_topic` | string | NO | Topic identifier for sibling-artifact grouping |
| `origin_transcript` | string | NO | Path to the source transcript when artifact derives from one |

State semantics are a forward-binding contract — the future implementation MUST use these state names verbatim. That release's Stage 13 close action: register `pmo-platform/reference/artifact-workflow-protocol.md` as an additional Consumer Registry row at §6.1; the §3.2 authoritative-source pointer (this paragraph) updates to cross-reference the new protocol doc as the operational-protocol home, while the state machine + frontmatter restated above remains the vocabulary canonical source.

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

**Authoritative source:** [`pmo-platform/reference/schemas/frontmatter-schema.md`](../schemas/frontmatter-schema.md) § Category 2 — Lifecycle. Domain A files follow the **Baselined Document** pattern (formal state changes, explicit approval; C12).

**States (5):** `created / draft / active / superseded / archived`

**Scope-out rationale:** Domain A state vocabulary is already canonical in `frontmatter-schema.md` § Category 2. The schema is the authoritative source for `lifecycle_state` field values and the Baselined Document pattern. Object-prefix form `Domain-A-<state>` applies to this vocabulary in cross-machine prose; bare form applies in YAML/SQL contexts per §2.2.

### §4.2 Domain B Lifecycle

**Object prefix:** `Domain-B-`

**Authoritative source:** [`pmo-platform/reference/schemas/frontmatter-schema.md`](../schemas/frontmatter-schema.md) § Category 2 — Lifecycle. Domain B files follow the **Living Document** pattern (continuous updates, no formal baseline; C12).

**States (7):** `created / emerging / current / needs-review / stale / superseded / archived`

**Scope-out rationale:** Same as Domain A — authoritative source already established at `frontmatter-schema.md` § Category 2. Object-prefix form `Domain-B-<state>` applies in cross-machine prose; bare form applies in YAML/SQL contexts.

### §4.3 Trust Categories

**Object prefix:** `Trust-`

**Authoritative source:** [`pmo-platform/reference/schemas/frontmatter-schema.md`](../schemas/frontmatter-schema.md) § Category 5 — Trust, and [`core/disciplines/document-ecosystem-design.md`](../disciplines/document-ecosystem-design.md) §5 (Trust Model). Defined per design brief §14.

**Categories (5):** `evidence / controlled-truth / interpretation / working-context / historical-record`

**Scope-out rationale:** Trust is an **orthogonal classification dimension**, not a lifecycle state. Lifecycle states answer "where is this content in its production workflow?"; Trust categories answer "how authoritative is this content right now?". The two dimensions co-vary in places (Trust-lifecycle consistency rules in `frontmatter-schema.md` § Category 5) but remain conceptually distinct. Including Trust in this canonical source would conflate dimensions; scoping-out preserves dimensional clarity. Object-prefix form `Trust-<category>` applies in any cross-machine prose where a Trust value appears alongside a lifecycle state (rare, but possible in cross-domain consistency checks); bare form applies in YAML/SQL contexts.

### §4.4 KM-Artifact Lifecycle

**Object prefix:** `KM-`

**Authoritative source:** [`pmo-platform/reference/how-to/km-protocols.md`](../disciplines/km-protocols.md#km-artifact-lifecycle) — Knowledge-Management Protocols §1, KM-Artifact Lifecycle. Defines the state machine for K1-tier managed-knowledge artifacts (ADRs, promoted lessons-learned, codified-practice docs, the reference corpus docs themselves). Composes with — does not duplicate — [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) (K1-K5 tiers) and [`corpus-curation.md`](../disciplines/corpus-curation.md) (ET1-ET5 evidence tiers).

**States (5):** `KM-Proposed / KM-Active / KM-Deprecated / KM-Superseded / KM-Rejected`

**Scope-out rationale:** KM-artifact lifecycle state vocabulary is already canonical in `km-protocols.md` §1. That doc is the authoritative source for state definitions, transition rules (`KM-Proposed → KM-Active → {KM-Deprecated | KM-Superseded}` + `KM-Rejected`), and the ADR-as-canonical-instance binding (Nygard 2011 vocabulary preserved). Object-prefix form `KM-<State>` applies in cross-machine prose per §2.1; the bare form applies in frontmatter / SQL contexts per §2.2. The KM- machine is genuinely new (it is not Domain A's Baselined `created/draft/active/superseded/archived` set nor Domain B's Living set — see km-protocols.md §8 ADR record); this registration satisfies the §8 Change Protocol governance requirement deliberately deferred out of the km-protocols work.

---

## §5 Cross-Machine Collision Map

The table below enumerates **bare state names** that appear in two or more state machines, with disambiguation guidance. This is the master reference for cross-machine vocabulary resolution.

| Bare state name | Appears in | Object-typed forms | Disambiguation |
|---|---|---|---|
| `Reviewed` / `REVIEWED` | Context (§3.1), Artifact (§3.2) | `Context-Reviewed`, `Artifact-REVIEWED` | Context-Reviewed = inbound content processed by analytical skill; Artifact-REVIEWED = outbound artifact passed agent/skill review gate. Different actors, different evidence. |
| `Approved` / `APPROVED` | (none currently — semantically adjacent to `Context-Decided` and `Artifact-APPROVED`) | `Artifact-APPROVED` only | The bare term "Approved" is intuitive but ambiguous. Context Lifecycle uses `Context-Decided` (item routed/rejected); Artifact Workflow uses `Artifact-APPROVED` (human-approved for downstream consumption). Cross-machine prose should use the object-typed form to avoid implying the wrong actor/gate. |
| `draft` / `DRAFT` | Artifact (§3.2), Domain A (§4.1), Domain C (§3.3) | `Artifact-DRAFT`, `Domain-A-draft`, `Domain-C-draft` | 3-way collision. `Artifact-DRAFT` = AI-generated artifact not yet reviewed; `Domain-A-draft` = source artifact in formal-baseline draft; `Domain-C-draft` = synthesis artifact newly generated by Artifact Generator. Different actors (AI / human author / Artifact Generator) and different transition semantics. |
| `archived` / `ARCHIVED` | Artifact (§3.2), Domain A (§4.1), Domain B (§4.2), Domain C (§3.3) | `Artifact-ARCHIVED`, `Domain-A-archived`, `Domain-B-archived`, `Domain-C-archived` | **4-way collision.** Terminal state across four machines with different retention semantics. Trust-lifecycle rule (`frontmatter-schema.md` § Category 5): `archived` lifecycle state requires `Trust-historical-record`. |
| `stale` | Domain B (§4.2), Domain C (§3.3) | `Domain-B-stale`, `Domain-C-stale` | Both = content no longer current. `Domain-B-stale` = tracker content past `staleness_threshold_days` without new evidence; `Domain-C-stale` = synthesis output where source material has changed (Query 6 staleness detection). Different detection mechanisms. |
| `superseded` / `Superseded` | Domain A (§4.1), Domain B (§4.2), KM (§4.4) | `Domain-A-superseded`, `Domain-B-superseded`, `KM-Superseded` | All three = replaced by a newer artifact. `Domain-A-superseded` and `Domain-B-superseded` typically carry a `superseded_by` field pointing to the replacement; `KM-Superseded` follows the same convention per `km-protocols.md` §1 (mirrors `frontmatter-schema.md` § Category 2). Trust-lifecycle rule: `superseded` shifts `Trust-` to `historical-record`. |
| `created` | Domain A (§4.1), Domain B (§4.2) | `Domain-A-created`, `Domain-B-created` | Both = entry-point state on ingest. `Domain-A-created` typically transitions to `Domain-A-draft` then `Domain-A-active` (Baselined pattern); `Domain-B-created` typically transitions to `Domain-B-emerging` then `Domain-B-current` (Living pattern). |
| `Captured` | Context (§3.1) only | `Context-Captured` | No current collision, but reserved for future-proofing. Use object-typed form in cross-machine prose. |
| `Structured` | Context (§3.1) only | `Context-Structured` | Same as above — reserved. |
| `Decided` | Context (§3.1) only | `Context-Decided` | Same as above — reserved. |
| `Closed` | Context (§3.1) only | `Context-Closed` | Same as above — reserved. |
| `validated` | Domain C (§3.3) only | `Domain-C-validated` | No current collision — reserved. |
| `published` | Domain C (§3.3) only | `Domain-C-published` | No current collision — reserved. |
| `PROMOTED` | Artifact (§3.2) only | `Artifact-PROMOTED` | No current collision — reserved. |
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
| Artifact Workflow release (planned; `pmo-platform/reference/artifact-workflow-protocol.md` once shipped) | Cites canonical source as authoritative for `Artifact-REVIEWED` / `Artifact-APPROVED` semantics; the Artifact Workflow uses object-typed names verbatim per forward-binding contract restated at §3.2 | Forward-binding row — the planned protocol doc registers as an additional Consumer Registry row at that release's Stage 13 close; the vocabulary + state machine are canonically defined in-repo at §3.2 |

### §6.2 Forward-citation consumers (future releases)

These consumers are designed but not yet authored. They will register here when their releases ship.

| Consumer | Planned release | Expected consumption |
|---|---|---|
| `pmo-platform/reference/artifact-workflow-protocol.md` | planned | When the protocol doc ships, this canonical source's §3.2 authoritative-source citation updates from "in-repo §3.2 restatement (vocabulary canonical source)" to additionally cross-reference the protocol doc as the operational-protocol home. The §3.2 vocabulary + state machine restatement remains the canonical source. Handled at that release's Stage 13 close. |
| file-router ingest and KB capability | future | file-router attaches Context Lifecycle state metadata to routed files using `Context-Captured` / `Context-Structured` (soft outbound). |
| Knowledge Architecture doc | shipped | Parallel companion to this canonical source; cites this doc for lifecycle vocabulary. |
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
| YAML frontmatter field value | `lifecycle_state: active` (the `domain: A` field declares the object scope) |
| SQL `WHERE` clause | `WHERE lifecycle_state = 'archived' AND domain = 'C'` |
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
