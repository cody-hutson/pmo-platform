<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-163 — The Project entity masters health RAG as a derived projection
status: Proposed — flips to Accepted when the operator ratifies it at this release's Stage 9 Plan Review gate. The flip is recorded in this file's own `status:` field, which is where it must be verified — never inferred from milestone closure, from a merged pull request, or from a review comment.
date: 2026-08-29
release: one-system-of-record-per-element
deciders: "Stage 5 Solutioning spoke on the decision card (options analysis, evidence-grounding, blast radius) + Stage 5 Solutioning spoke on the delivery child (provenance-chain correction, enforceability correction) + release hub (carried constraints on roster count and on the concurrent-file non-scope) + operator (Stage 4 plan-review determination that the entity surface is reopened once, not twice) + Stage 6 Engineering spoke (authorship)"
tags: [architecture, entity-model, project-health, rag, derived-value, provenance, anti-watermelon, tier-2-amendment, roster-exemption]
source_observations:
  - "The portfolio rollup contract declares that its RAG status field reads the Project entity's status field, but that field is the Axis-1 lifecycle enum whose values are the three lifecycle states. The contract therefore names a source that cannot hold the value it claims to read, and the rollup is the surface the portfolio file publishes — so the platform publishes a health colour with no mastered source."
  - "No entity field masters project health anywhere in the frozen entity surface. The Project entity's frozen field list carries seven fields and none of them is a health or RAG field."
  - "The prior health-RAG record homes only the BANDS — the thresholds that map a metric to a colour — and explicitly declines to move them. A threshold home is not a value home, so the band decision left the mastering question open rather than answering it."
  - "The comms channel-format reference states that RAG indicators must be formula-driven and not self-reported, and carries a watermelon detection rule for a project reporting green over a worse component. A health field specified as a bare enum an agent may set by hand would legalise, on the frozen entity surface, precisely the reporting failure those two rules exist to prevent."
  - "The metric registry disclaims ownership of the project-level composition in its own words: it produces per-metric RAG, and states that the single project-level RAG is composed upstream by the transparent-roll-up rule in the channel-format reference. An inbound design that named the registry the derivation owner asserted an ownership the cited file denies."
  - "The registry further records that the composing skill's roll-up is currently expressed as qualitative prose rather than a formal algorithm, and names formalizing it as a candidate follow-on. Any materialization of that rule inherits that condition rather than creating it."
  - "A field-list amendment and a roster extension are different amendment classes with different costs. The leadership-owner record amended a per-entity field list and re-froze the surface with the roster count untouched; the skill-output-ownership record extended the roster and dragged an entity record, a relationship row, an owning-agent row and a storage row with it."
  - "A sibling card in an unstarted milestone owns the repair of a stale roster count carried in the entity core rule text, and its acceptance criterion is a counting assertion over that number. A decision that moved the roster count in this release would move a number a sibling card is concurrently asserting against."
  - "The rollup record's entity-type value is read as an executable discovery key by the portfolio composer, which enumerates rollups by matching that exact literal. Assigning the record a roster-legal entity-type value would make the composer discover zero rollups."
  - "A measured probe over the tracked corpus found that the entire core-validation rule family — nine distinct rule identifiers, one hundred fifty-nine occurrences — appears zero times across the two hundred thirty-eight executable files, while a control token inside that same executable population fires strongly. The rule family is declared blocking and is mechanically unenforced."
---

# ADR-163 — The Project entity masters health RAG as a derived projection

## Status

**Proposed.** Flips to **Accepted** at this release's Stage 9 Plan Review gate; per the established precedent the flip is verified against this file's own `status:` field and never assumed from milestone closure or from a merged pull request.

**Supersedes nothing.** [ADR-065](ADR-065-health-rag-band-canonical-home.md) remains the canonical home of the health-RAG bands and of the transparent worst-component roll-up rule, unchanged and undisturbed by this record. This record decides *where the composed value is mastered*; that record decides *what the thresholds are*. They answer different questions and neither displaces the other.

**Numbering.** ADR numbers are platform-global monotonic across both homes (`core/ADRs/` and `release/ADRs/`). This record was allocated from the binding oracle at authorship time and is **claimed at merge, never reserved**. Two concurrent unmerged sibling releases have each claimed the immediately preceding number on their own branches, as has this release's own first decision record; an unmerged claim is advisory, a gap blocks the repository while a duplicate is tooled, and whichever release merges later renumbers via the platform's renumbering tool. Downstream surfaces cite this record **by slug**, never by number, for exactly that reason.

## Context

The portfolio rollup is the surface the portfolio file publishes. Its `status` field is a RAG colour — green, yellow, or red — and the writeback contract declares that it READS the Project entity's `status` field.

**That source cannot hold that value.** The Project entity's `status` is the Axis-1 lifecycle enum, whose values are the three lifecycle states. It is a lifecycle machine, not a health scale. The contract names a field of the wrong type, and no other entity field masters project health: the Project entity's frozen field list carries seven fields and none of them is a health or RAG field.

So the platform publishes a health colour with no mastered source. The rollup is composed and published; the value arrives from a derivation that is real but is not written down as anyone's field; and the contract's account of where it comes from is wrong.

**The band decision left this open rather than answering it.** [ADR-065](ADR-065-health-rag-band-canonical-home.md) settled where the RAG *thresholds* live and deliberately retained them in the comms channel-format reference. A threshold home tells you which colour a metric earns. It does not tell you which record holds the colour once earned, nor who is permitted to set it. That is the question this record answers.

**Why the answer cannot be a bare enum.** The channel-format reference states that RAG indicators must be formula-driven and not self-reported, and carries a watermelon detection rule for a project reporting green while a component is worse. Those two rules are the platform's defence against the reporting failure where a green headline conceals a red interior. A `health_rag` field specified as a free enum that an agent sets by hand would legalise that failure *on the frozen entity surface* — it would put a schema blessing on the exact hole the surrounding rules exist to close. The mastering decision and the anti-self-reporting binding are therefore not two decisions, one of which could be deferred. They are one decision, and the binding is its substance.

**Where the derivation actually lives.** The corpus already contains the full chain, spread across four surfaces, and it is easy to cite it backwards. The metric registry disclaims project-level composition in its own words: it produces per-metric RAG, and states that the single project-level RAG is composed **upstream** by the transparent-roll-up rule in the channel-format reference. The registry is an index, not the derivation owner. Getting this direction right is not pedantry — a record that named the index as the owner would assert an ownership the cited file denies, and would read as a fresh duplicate-source defect at the next audit.

**The shape of the choice.** Health has an honest modelling tension. It is refreshed on a fast cadence, it needs its own as-of stamp, and it is composed from several inputs — three signatures of a *measure*, not of an *attribute*. A measure argues for its own record. But a separate record is a roster extension, and a roster extension in this release would move a count that a sibling card in an unstarted milestone is concurrently asserting against with a counting acceptance criterion, against a corpus where the entity core rule text still carries a stale earlier count. That is the decision's real tension, and the section below resolves it explicitly rather than letting the cheaper option win by default.

## Decision

### 1. The Project entity masters the project-level health RAG

**The Project entity gains two OPTIONAL fields: `health_rag` and `health_derived_date`.** `health_rag` is the project-level composed RAG colour. `health_derived_date` is an ISO calendar date stamping when the derivation that produced it last ran.

Both are optional. The amendment is therefore **additive**: no live project record becomes malformed by this change, and no migration is owed. This is the property that makes the amendment safe on a surface with a large referrer fan-out — every existing consumer keeps reading exactly the fields it read before.

### 2. `health_rag` is a materialized derived projection, never a self-reported value

This is the load-bearing clause. `health_rag` does not hold whatever an agent decides to put in it; it holds the **materialization of a named derivation**, and the field declaration cites that derivation's owners rather than restating them.

The chain has four layers, each with a different owner, and the record states them in the direction the cited files themselves state:

| Layer | Owner |
|---|---|
| The **bands** — which metric value earns which colour — and the **transparent worst-component roll-up rule** | the comms channel-format reference's RAG Threshold Standards section, retained as owner by [ADR-065](ADR-065-health-rag-band-canonical-home.md) |
| The **index** — which metric drives which colour at which level, with per-row provenance back to the bands | the weekly-status-rollup skill's metric registry, which self-declares as the index and disclaims the composition |
| The **composition** of the single project-level colour from its components | the transparent-roll-up rule as executed in the weekly-status-rollup skill's Section 1, under worst-component dominance |
| The **production** of the value onto the record | the `ppm-agent` skill, which the project schema already assigns RAG derivation |

**A `health_rag` set by hand, with no derivation behind it, is malformed — not merely stale.** The bands are not restated here and the roll-up rule is not restated here; both keep their existing single home. This record adds a value home and binds it to those homes, which is the whole of what it adds.

### 3. The binding is enforced by an invariant, not asserted by a note

A prose note in a schema's Notes column is not a validator. Shipping clause 2 as commentary would ship the watermelon hole with a schema blessing on it, which is the outcome clause 2 exists to prevent.

**`V-PRJ-11`: `health_derived_date` is present if and only if `health_rag` is present.** Level L1, blocking schema parse. Both directions are malformed — a colour with no derivation stamp is a self-reported value, which the channel-format reference forbids; a stamp with no colour is a stamp for nothing.

This is the smallest mechanism that makes the record's own central claim true, and it is precedented rather than novel: `V-PRJ-02` is a record-level conditional tightening of exactly this shape, sitting beside generated siblings on the same entity. The two membership rules that the new fields' types mechanically generate — an enum-membership rule and an ISO-date rule — remain separate from it, so that what was *generated* stays distinguishable from what was *authored*.

### 4. The amendment class is a field list, not the roster — the roster stays at 19

**This is an amendment to the per-entity field lists (Frozen Artifact 3), not to the entity roster (Frozen Artifact 1).** The roster stays at **19**. No entity is added; no owning-agent row, relationship row or storage row changes; the Project entity already has rows in all of them and none of them move.

The precedent is exact. The leadership-owner record amended a per-entity field list, added an optional companion field, and re-froze the surface with the roster count untouched. The skill-output-ownership record extended the roster and dragged an entity record, a relationship row, an owning-agent row and a storage row behind it. This decision is the first class, and says so.

**The alternative was better modelling and was rejected on release topology, which is recorded here rather than buried.** A separate Project-Health fact record is the architecturally honest shape for a measure, and it is named in Alternatives Considered as the available successor. It loses because moving the roster count in this release would move a number that a sibling card in an unstarted milestone is concurrently asserting against with a counting criterion, on a surface whose core rule text still carries a stale earlier count that the same sibling card owns. Adding a third value to a count two cards are already reconciling is how a release ships a self-inconsistent frozen surface.

### 5. The rollup record stays non-roster, and is explicitly exempt from `V-CORE-02`

**The per-project rollup record is a composed read-surface and is NOT made roster-legal.** Its `entity_type` value stays exactly as it is.

The reason is mechanical, not stylistic: that value is read by the portfolio composer as an **executable discovery key** — the composer enumerates rollups by matching that literal. A roster-legal value would make the composer discover **zero** rollups. The one place `entity_type` is load-bearing in executable code is the one place a roster-legal rewrite would break.

The writeback contract therefore gains an exemption sentence **naming the literal rule token `V-CORE-02`**, and likewise naming the lifecycle-state and created-date core rules the record also does not satisfy. Naming the token literally is required because the contract's existing prose classifying the record as a composed read-surface is a *classification*, not an *exemption*, and must not be accepted as one.

**The exemption's honest status, stated so it is not overclaimed.** `V-CORE-02` is declared L1-blocking in the entity field schema. It is also **mechanically unenforced**: measured over the tracked corpus, the entire core-validation rule family — nine distinct rule identifiers, one hundred fifty-nine occurrences — appears **zero** times across the two hundred thirty-eight executable files, against a control token that fires strongly inside that same executable population; and the deploy check engine carries no reference to the family at all. The unenforcement is family-wide, not particular to this rule.

**This exemption therefore closes no live enforcement gap, and this record does not claim it does.** It is a governance-correctness act: it states, before any mechanization exists, that this record is deliberately outside the roster, so that a future enforcer fails the records that should fail rather than the one the contract intends to exclude.

### 6. Sequencing — batched into the single Tier-2 reopening

**The entity-surface change this record specifies is batched into this release's single Tier-2 re-freeze beat, together with the sibling delivery child's field-group amendment.** The frozen surface is reopened **once**, not twice.

The two amendments are disjoint by construction — this one amends the Project entity's section, the sibling amends the work-item and RAID-item sections in the same two files — so the only genuinely shared artifact is the amendment note block, which is authored once after both field edits land.

**This record specifies the change; it does not make it.** The field rows, the validation rules, the negative tests, the contract repointing and the composer's join-key repair are the delivery child's work, executed in that batched beat. A decision record that also performed its own delivery would collapse the gate the release is built around.

### 7. The project-identity mapping sentence homes in the project schema

The declared mapping between a project's identifier slug and its folder basename lands in **`core/schemas/project-schema.md`**, not in the workspace charter template.

That schema already owns a named resolution procedure for the same file, so the new rule is a sibling in its established home; the charter template is a heavier governance surface, is contended with an unstarted sibling milestone and with a concurrent unmerged release, and is **explicitly out of scope for this release**. Reuse-first placement and minimal-change both point the same way.

The rule's stated reach is **identifier derivation only**. A folder basename may legitimately populate a display-name field; what the rule forbids is crossing from the display namespace into the identifier namespace. The scope clause is not decorative — without it the rule would declare two shipped tools malformed on the day it ships, because both derive a display key from a basename and neither produces an identifier.

## Alternatives Considered

Four homes were weighed for the value, and two forms for the binding.

### The home

| Option | Decision | Rationale |
|---|---|---|
| **A field on the Project entity** — a field-list amendment, roster untouched | **Accepted** | Lowest amendment class for the outcome; zero collision with the sibling roster-counting card; batches exactly with the other Tier-2 field-group amendment already in this release; and its one real weakness — an attribute slot holding a measure — is mitigable inside this record by binding the field to a named derivation. That mitigation is what makes it correct rather than merely cheapest. |
| **A separate Project-Health record admitted to the entity roster** | Rejected — **on release topology, not on architecture** | The architecturally honest shape for a measure: time-series-capable, carries per-dimension rows natively, and does not store a measure in an attribute slot. It loses because it moves the roster count in the one release where a sibling card ships a counting assertion over that number, on a surface whose rule text still carries a stale earlier count owned by that same card. Its cost is also several times higher — an entity record, validation rules, negative tests, an owning-agent row and a storage row. **Retained as the named successor** if health ever needs history. |
| **A separate non-roster composed record** | Rejected | Buys the modelling win only by creating a second un-rostered record class beside the rollup — two exemptions where the platform currently carries one — and puts no RAG-valued field on the frozen entity surface, which the delivery child's verification requires. |
| **No new store — declare the rollup's own field derived and cite the derivation** | Rejected | The cheapest and, on modelling grounds, defensible: it makes the derivation the value. It fails mechanically, because it leaves no field on the entity surface for the delivery child's verification to resolve against. **Its insight survives and is the content of Decision 2** — the derivation citation is carried onto the field rather than instead of it. |

### The form of the anti-self-reporting binding

| Option | Decision | Rationale |
|---|---|---|
| **A note in the schema's Notes column** | Rejected | Decorative. A hand-set colour with no stamp remains L1-valid, so "malformed" would be asserted in prose that no rule reads — shipping the record's central claim as commentary. |
| **Both fields made required** | Rejected | Over-strong and not additive: it makes every live project record malformed on the day it ships, for a value nothing yet populates. |
| **An optional pair bound by a record-level presence invariant** | **Accepted** | Keeps the amendment additive while making the binding enforceable at L1. Precedented by the existing exactly-one-of invariant on the same entity, so it adopts a house form rather than minting one. |

## Consequences

- **(+)** The published health colour gains a mastered source. The contract stops naming a lifecycle enum as the source of a RAG value.
- **(+)** The anti-self-reporting rule reaches the entity surface as an invariant rather than as prose. A colour cannot be asserted without a stamp saying when it was derived.
- **(+)** One home per fact is preserved. The bands stay where the band decision put them, the index stays an index, and this record adds a value home that cites both and restates neither.
- **(+)** The amendment is additive and optional, so a large referrer fan-out does not become a large edit, no live record becomes malformed, and the completeness measure that scores required-field presence is unmoved.
- **(+)** The roster stays at 19, so the sibling counting card's assertion is undisturbed by this release.
- **(+)** The frozen surface is reopened once for two amendments rather than twice for one each.
- **(−)** A measure is stored in an attribute slot. This is a real modelling compromise, accepted knowingly, with the successor named in Alternatives Considered. It mirrors the band decision's own posture of accepting a placement residual rather than concealing it.
- **(−)** The materialized value inherits a derivation that is currently expressed as qualitative prose rather than as a formal algorithm — a condition the metric registry itself records, with formalization already named there as a candidate follow-on. This record inherits that condition; it does not create it, and it is not grounds for new scope.
- **(−)** The scalar masters the composed project-level colour only. The per-dimension indicators remain derivation inputs with no entity home, and the mapping from them to the registry's rows is not one-to-one. The contract must describe that posture honestly rather than implying five independent sources exist.
- **(−)** The roster exemption is stated against a rule family that nothing currently enforces. Its value is anticipatory, and a reader who mistakes it for a live gate would overestimate what shipped.

## Reversibility

Split, because the halves genuinely differ.

- **The mastering decision and its field pair: `EXPENSIVE` · confidence `HIGH`.** Once the fields are on the frozen surface and the contract reads them, reversing means a third record, a second reopening of a frozen artifact, and re-editing every consumer the delivery child touched — weeks, with stakeholder-visible impact on the published portfolio surface. Confidence is HIGH because the option set was closed by a mechanical constraint rather than by preference, and because the rejected roster option is recorded as the named successor rather than foreclosed.
- **The provenance wording and the exemption sentence: `CHEAP` · confidence `HIGH`.** Prose edits in two files, reversible in a single commit. Confidence is HIGH because the chain's direction was verified against each cited file's own words rather than inferred, and because the exemption's honest status was measured over the tracked corpus with a control arm firing inside the population being measured.

## Related ADRs

- [ADR-065](ADR-065-health-rag-band-canonical-home.md) — the canonical home of the health-RAG bands and of the transparent worst-component roll-up rule. **Not superseded and not amended by this record**: it owns the thresholds, this record owns the value home. Its stated posture of accepting a placement residual rather than fixing it is the precedent for the modelling compromise recorded under Consequences.
- [ADR-040](ADR-040-leadership-owner-person-ref.md) — the field-list amendment precedent: a per-entity field list amended, an optional companion field added, the surface re-frozen with the roster count untouched. The amendment class this record adopts.
- [ADR-044](ADR-044-skill-output-ownership-model.md) — the roster-extension precedent, and the record that re-froze the roster at 19. The amendment class this record deliberately does **not** adopt, and the source of the count that stays unchanged.
- [ADR-019](ADR-019-specialists-compose-not-absorb.md) — cited by the writeback contract as the architectural basis for the rollup being a composed read-surface rather than a roster entity; the framing this record's roster exemption makes explicit.
- [ADR-162](ADR-162-system-of-record-per-mirrored-element.md) — this release's sibling decision record. Disjoint subject matter — externally-mirrored data authority, versus where a locally-composed value is mastered — and no edge between them; their delivery children share the frozen surface this record's sequencing clause batches.

### Provenance

- Decision card: #5839 — decide where project health RAG is mastered; this record is its sole deliverable.
- Delivery child: #5846 — the health-field-home delivery, which adds the field rows, the validation rules and the negative tests, repoints the writeback contract, homes the identity-resolution rule in the project schema, and repairs the composer's join key.
- Coordination: #5847 owns the stale roster count in the entity core rule text; this record does not touch it and the roster count stays 19 after this release.
- Release: the `one-system-of-record-per-element` milestone; designed at Stage 5 Solutioning on the decision card (sub-task #6281) and on the delivery child (sub-task #6289), built at Stage 6 Engineering (sub-task #6282).
