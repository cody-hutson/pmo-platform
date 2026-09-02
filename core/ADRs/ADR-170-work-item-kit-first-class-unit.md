<!-- reference-durability: allow-link -->
---
title: "ADR-170 — Work-item kit as a first-class unit: a third pack role that is kind-bearing without naming an archetype, neutral at the kind level, discriminated by kit class, and selected on the existing configuration cascade"
status: Proposed — flips to Accepted when the operator ratifies it at the Stage 9 Plan Review gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure or from a review comment.
date: 2026-09-01
release: kit-unit-and-selection
deciders: "Stage 5 Solutioning spoke (design, evidence-grounding) + independent adversarial review (falsification by execution) + operator ratification at Collective Review (D-CompatShape, D-MapHome, D-FixtureHome, D-ReadmeSplit, D-EmptyKitRetire, D-OutcomeAmend, D-CarryFindings) + Stage 6 Engineering spoke (authoring, correction-carrying, re-grounding)"
tags: [work-item-kit, pack-grammar, role-discriminator, kit-class, archetype-neutral, methodology-projection, configuration-cascade, additive-extension, open-value-domain, cross-cutting, ADR-018, ADR-069, ADR-070, ADR-077]
source_observations:
  - "The pack grammar welds kind-bearing to archetype identity, but not at the field the founding ticket named. The ticket named `applies_to` as reserved to a base pack; read against the live grammar that constraint is one-directional — a base pack MUST be methodology-neutral, and nothing forbids an archetype pack from being neutral too. The actual weld is one level down: every kind's methodology projection carries a REQUIRED archetype key whose value domain is the eight archetype names or Custom, with no neutral member. A change relaxing only the pack-level field would validate a kit whose every kind still names an archetype: the capability would appear to land and would be absent."
  - "The grammar disagrees with itself about whether a base pack may declare kinds. The prose says a base pack carries no per-kind declarations; the field table says kinds are optional-or-absent for that role. The permissive reading leaves a second, undesigned way to express a cross-methodology kind set, which would re-open the very decision this record closes."
  - "The kit set is open by the operator's own framing — field, workflow and form kits are plausible successors — so the unit must not be shaped as the work-item kit alone. Making the unit generic costs one field while no consumer exists and is expensive to retrofit after a second class ships."
  - "An independent adversarial review falsified the first draft of this record's generality claim. The claim was that conditioning facet requiredness on the kit class discharges the second-class problem by construction; the rule set that same design handed downstream conditioned requiredness on the role instead, unconditionally for every kit, so a field or workflow kit declaring no work-item kinds would be hard-rejected and the second class would still cost a grammar re-open. The same root cause made the open kit-class domain unreachable: an unknown class was to yield a caveat, but the role-conditioned rule rejected the same pack on a different rule first."
  - "A second premise was falsified by execution rather than by reading. The claim that selecting a kit while licensing no archetype pack resolves to an empty vocabulary and fails loud is false: a conforming kit is mandatorily kind-bearing, so a kit-only root resolves the kit's own kinds. Run against the shipped reader, a kit-only pack root emits its kind and exits 0; the sensitivity arm — a root whose only pack declares no kinds — exits 3, so the detector is live. Three prior verification passes had confirmed the claim by checking that the failing line of code exists, which is not the same as exercising the path."
  - "The restriction axis was unnamed by the ticket and is the one shape that can invalidate a previously-valid pack: making the neutral value illegal on an archetype pack. Measured against the shipped packs, zero of three combine that role with that value, with a live control arm, so the byte-identity guarantee for shipped packs holds and the restriction closes a door no shipped pack walked through."
  - "Container tiers cannot be typed by a kind and that is structural, not a shortcoming. Every kind's base is the constant Work Item with no other base permitted, and the entity model holding Portfolio, Program, Project and Milestone/Workstream is frozen — so a kind declared at a container tier would be the new entity node the level-coverage work explicitly forbids. Coverage of every organizational level is therefore achieved by projection, not by declaration."
---

# ADR-170 — Work-item kit as a first-class unit

## Status

**Proposed.** Authored at Stage 6 Engineering of the `kit-unit-and-selection` release, after the Collective Review scope-lock that ratified the design and carried its corrections forward. It flips to **Accepted** when the operator ratifies it at the Stage 9 Plan Review gate; the flip is recorded in this file's own `status:` field, which is the authority. A green release close-out is not evidence that the flip landed, and neither is a review comment.

`Proposed` is the honest value here rather than the `Accepted`-at-authoring that the two sibling pack records took, and the difference is not stylistic: those records were written after their deciding gate had already run, whereas this record's deciding gate is still ahead of it.

## Subordinate to

[ADR-018 — Work-Item Type Layer](ADR-018-work-item-type-layer.md). This record extends ADR-018's declarative type-layer grammar for the **kit** surface, at the same altitude and by the same mechanism that [ADR-070](ADR-070-methodology-pack-composition-grammar.md) extended it for the pack-composition surface and [ADR-039](ADR-039-declarative-gate-conditions.md) extended it for the gate-condition surface. It opens **no competing kernel**: ADR-018's disciplines bind it — the grammar projects onto the work-organization mapping framework and never onto a release-pipeline ticket model, the work-item type set stays an open external value domain, and no core governance surface acquires a coupling to release-pipeline tooling.

## Context

A **methodology pack** bundles a methodology's operational surface as one selectable manifest; the **composition grammar** gives that manifest a role discriminator, delta-inheritance from a shared root, a label-contribution facet and a work-status projection. Both are settled. What neither expresses is a set of work-item kinds a deployment selects **independently of the methodology it runs** — a *kit*.

Three welds stand between the grammar and that capability, and the first one has to be named precisely because the founding ticket named it wrong.

**The ticket's stated blocker is not the binding one.** It records that the methodology-neutral value of the pack-level `applies_to` field is reserved to a base pack, and that a base pack cannot bear kinds. Read against the live grammar, the reservation is **one-directional**: a base pack MUST set the neutral value, and nothing forbids an archetype pack from setting it. The field is under-specified rather than restrictive — its requiredness cell points at a role-conditional note that the section never states for it.

**The binding weld is one level down, on the kind.** Each kind carries a `methodology_projection` object whose `archetype` key is REQUIRED, with a value domain of the eight delivery-approach archetype names or `Custom`, and no neutral member. Every kind names an archetype regardless of what its pack's `applies_to` says. A change that relaxed only the pack-level field would produce a pack that validates, passes every gate, and delivers nothing — the capability would appear to land and would be absent. That is the same quiet-degradation shape the release's own precedent cites, where a consumer read-refit shipped correctly against a registry that turned out to be empty and every surface degraded silently rather than failing.

**The grammar disagrees with itself about the base pack.** Its prose says a base pack carries no per-kind declarations; its field table says kinds are optional-or-absent for that role. The two readings are not interchangeable here: the permissive one leaves a second, undesigned way to express a cross-methodology kind set — make the base pack kind-bearing — which would re-open this decision the moment someone noticed it.

Two further forces shape the unit rather than the mechanism.

**The kit set is open.** Field, workflow and form kits are plausible successors. A unit shaped as *the work-item kit* would have to be re-founded for the second one. Generality is cheapest to establish now, while no consumer resolves against a kit at all.

**Container tiers cannot be typed by a kind, and that is structural.** Every kind's `base` is the constant `Work Item`, with no other base permitted, and the entity model holding Portfolio, Program, Project and Milestone/Workstream is frozen. A kind declared at a container tier would be exactly the new entity node the level-coverage work forbids. Work-Item-level typing is therefore mandatory, not a limitation to be engineered around — a point the release's own outcome statement originally had backwards and which was corrected at Collective Review.

## Decision

**A work-item kit is a third value of the existing pack `role` discriminator — not a new unit, not a facet nested inside an existing pack, and not a second grammar.** Seven sub-decisions.

### D1 — A kit is a third `role`

The `role` enumeration widens from `{archetype, base}` to `{archetype, base, kit}`. A `role = "kit"` pack:

- MUST set `applies_to` to the methodology-neutral value;
- is **kind-bearing** (see D3 for the requiredness rule);
- MAY declare `extends`, targeting a `role = "base"` pack;
- MUST NOT itself be an `extends` target — only a base pack is an inheritance root.

**Kind-bearing now follows from `role ∈ {archetype, kit}`, not from naming an archetype.** That sentence is the decoupling.

D1 also closes the under-specified pack-level field by stating its rule for **all three** roles rather than for one: a `base` pack MUST be neutral; a `kit` MUST be neutral; an `archetype` pack MUST name an archetype and MUST NOT be neutral. The third clause is a restriction and is accounted for as one in D6.

### D2 — Decouple at the kind level, via a neutral archetype sentinel

The `methodology_projection.archetype` value domain admits the neutral sentinel `"*"`, permitted **only** on a kind declared inside a `role = "kit"` pack. An archetype pack's kinds still MUST name their archetype: the existing rule is untouched and no shipped pack migrates.

D2 is **non-severable from D1**. Shipping the role widening without the kind-level sentinel produces a pack that validates while every one of its kinds remains archetype-welded — the failure mode § Context describes.

**A kit's kinds perform no Layer-2 join, and the record says so rather than borrowing a mechanism that has no input.** The projection object exists to cite the work-organization mapping framework's row for an archetype; the neutral sentinel is not an archetype and has no such row. So:

- `archetype = "*"` **declares the absence of a row** rather than naming one.
- `general_level` is asserted **directly** on the kind, and for a kit it is constrained to `Work Item` (D6's level-closure clause).
- `projects_as` degenerates to the display-name form the grammar already documents as the common case.
- `level_name_ref` is **omitted**. It is an optional anchor into a Layer-2 row, and a neutral kind has no row to anchor into.

The last point corrects the design draft this record supersedes, which said a neutral kind would resolve through the same `derive` path the `Custom` archetype uses. It cannot: `derive` resolves through a custom block's `base_archetype`, and a neutral kind has neither. Naming a mechanism the release does not use would have left the grammar edit graded against a fiction.

**Why `"*"` rather than a new token.** The grammar already uses `"*"` as its methodology-neutral value at the pack level and as its spans-all value in the controls facet, and no token meaning *any* or *neutral* exists anywhere else in it. Minting a second neutrality token would fork the sentinel vocabulary inside one grammar.

### D3 — `kit_class` is the requiredness discriminator, and the requiredness rule is two-level

`kit_class` is REQUIRED when `role = "kit"` and absent otherwise. Its v1 value is `work-item`. Its value domain is **OPEN**.

`kit_class` selects **which facet the kit must carry**. The requiredness rule it drives is stated here in full, because a rule stated only at one altitude was this decision's first defect:

> `kinds` is **forbidden** when `role = "base"`; **required, at least one,** when `role = "archetype"`; and when `role = "kit"`, requiredness is **selected by `kit_class`** — `work-item` requires at least one kind, and an **unregistered** class asserts **no facet requirement**, emitting a caveat that names the unregistered value.

**This is a correction, carried deliberately, and the record states what it corrects.** The first draft of this decision claimed the second-kit-class problem was discharged *by construction rather than by promise*, while the rule set it handed downstream conditioned `kinds` on `role` alone — unconditionally for every kit. Under that rule a `field` or `workflow` kit declaring no work-item kinds is hard-rejected, so registering a second class means editing the requiredness rule, which is a grammar re-open: precisely what the claim said was avoided. The same root cause made the open value domain unreachable — an unknown class was to yield a caveat, but the role-conditioned rule rejected the same pack on a different rule first. Two rules in one table, mutually defeating.

**What a second kit class costs under the rule as now stated.** Registering a `field` kit costs: one entry in the class-to-facet registry naming the facet that class must carry, one rule implementing that facet's requiredness, and one configuration entry so a deployment can select it. It costs **no** change to `role`, no second unit, no new resolver, and no re-opening of the requiredness rule's shape. That is the generality, and it is real only because the rule branches on `kit_class`.

**The cost of the branch, stated rather than elided.** Conditioning on an open domain introduces a failure mode a closed one does not have: a mistyped `kit_class` falls through to the unregistered arm and silently relieves a work-item kit of its `kinds` obligation. The mitigation is that the unregistered arm is **never silent** — it emits a caveat naming the value it did not recognize, so a typo is legible as an unrecognized class rather than as a pack that simply passed. An unknown class is a caveat, never an error; a caveat nobody sees would be worse than the error it replaces.

**The obligation this places on the grammar edit.** This record's generality claim is true only if the grammar states the two-level rule. If the grammar instead conditions `kinds` on `role` alone, the claim is false and the open domain is unreachable, and the record's consequences must be read as if D3 had been declined.

### D4 — Binding rides the existing configuration cascade; no parallel resolver

Kit selection resolves through the **same five-rung cascade** that already resolves a deployment's methodology: a global default, then portfolio, program, project and individual rungs, most-specific-wins. A project overrides on the same frontmatter surface its delivery approach already uses. **No second resolution path is introduced** — a parallel resolver would be the shadow-source failure the selection work explicitly forbids.

Selection is **per kit class**, so a deployment selects at most one kit per class. Whether that is expressed as a class-keyed map or as one configuration key per class is a **configuration-surface decision deferred to the selection work at Stage 6** and deliberately not fixed here: the two candidate shapes were argued from opposite premises about cost, and the cost argument that favoured the map was falsified — a new key costs a schema entry under either shape. Under either shape a second class costs one configuration entry plus its schema row, and the resolver is unchanged.

**No kit selected is not an error.** It is the pre-kit status quo, which is what keeps this additive for every existing deployment.

**This record carries no empty-vocabulary constraint, and the omission is deliberate.** A draft of this decision asserted that the kit axis and the methodology axis are independently optional but not jointly empty, on the ground that a deployment selecting a kit while licensing no archetype pack would resolve an empty kind vocabulary and fail loud. That is false, and it was falsified by running the shipped reader rather than by reading it: a conforming kit is mandatorily kind-bearing, so a kit-only root resolves the kit's own kinds and exits successfully; the failing path is reached only by a root that licenses **no kind-bearing pack at all**. The distinction that makes the false premise possible is that the vocabulary reader unions what is **licensed on disk**, reading no selection at any rung — so *selected* and *licensed* are different populations, and substituting one for the other made a kit-only deployment look like a hard error. The correct constraint belongs to the selection work, which owns the criterion that inherited the false predicate; stating a replacement here on this record's own authority would repeat the mistake in the other direction.

### D5 — Composition order and precedence

Resolution order is: the shared **base** pack, then the selected **archetype** pack, then the selected **kit**, then project-level overrides. Most-specific-wins, field-level merge, default-as-base — the same merge model the grammar already defines for overrides. On a colliding kind identifier the kit wins over the archetype pack, and a project override wins over the kit.

**Orthogonality holds by construction, not by test alone.** The methodology axis reads the delivery-approach field; the kit axis reads the kit-selection field. Two independent lookups against two independent fields, neither reading the other. Changing the methodology cannot change the kit, which is the property the selection work's own predicate tests for.

### D6 — Level closure: a kit types work, it does not type tiers

**A kit types work at the Work-Item level, and only there.** Every kind's `base` is the constant `Work Item`, no other base is permitted, and the entity model holding the container tiers is frozen. A kind declared at Portfolio, Program or Project would be a new entity node, which the level-coverage work forbids on its own terms.

Coverage of every organizational level is therefore achieved by **projection, not by declaration**: a rollup traversing container tiers resolves an **entity type** at each tier from the frozen entity model, and a **kit-declared kind** at the Work-Item level. Nothing at a container tier becomes a kind, and no level acquires a second vocabulary.

The grouping-versus-execution distinction that a traversal needs gains its carrier inside the existing projection object as `level_role`, with the domain `{execution, grouping}` and an absent value meaning `execution`.

**`level_role`'s domain is CLOSED — an unknown value is an error — and the asymmetry with `kit_class`'s OPEN domain is deliberate.** `kit_class` names a successor set the platform expects to grow, so an unrecognized member is a gap to report and work around. `level_role` names a binary distinction internal to how a rollup traverses: there is no third role to discover, and silently admitting one would make a traversal unanalyzable rather than merely under-specified. An open domain is right where the set is genuinely open; asserting openness where the set is closed is not generosity, it is an unenforced invariant.

### D7 — A base pack MUST NOT declare kinds

The grammar's self-contradiction resolves toward the **prohibitive** reading. Grounds: the shipped base pack's own header comment already asserts it is non-kind-bearing; the composition-grammar record's stated intent is that a base pack declares no kinds of its own; and the permissive reading leaves a second, undesigned way to express a kit, re-opening the decision this record closes.

Result, in one sentence with no ambiguity: **`role ∈ {archetype, kit}` bears kinds; `role = "base"` does not.**

This is on the critical path rather than opportunistic cleanup — the kit design turns on which roles bear kinds.

## Alternatives Considered

Five candidates were generated across three altitude bands and narrowed on hard-constraint breach rather than on score.

| Candidate | Mechanism | Altitude | Verdict |
|---|---|---|---|
| A | Relax the pack-level field so the neutral value is legal on an archetype pack | point-fix | **Eliminated** |
| B | Make the base pack kind-bearing | point-fix | **Eliminated** |
| C | Third `role` value, kit-class discriminator, kind-level neutral sentinel | extend-seam | **Selected** |
| D | An optional kit sub-facet nested inside an existing pack | extend-seam | **Eliminated** |
| E | A new unit under its own directory with its own grammar | new-abstraction | **Runner-up** |

**A — eliminated on the weld.** It does not clear the kind-level requirement: every kind would still name an archetype, so the capability does not land. It also makes the archetype role's own stated semantics — projects kinds for one archetype — false.

**B — eliminated on blast radius and on governance conformance.** The base pack is the inheritance root and `extends` names exactly one base, so a deployment would get exactly one kit and no way to select among kits, defeating the selection requirement outright. It also collapses *inheritance root* and *kind carrier* into one concept and silently re-decides the composition grammar's own base-pack sub-decision. It does not clear the kind-level weld either.

**D — eliminated on orthogonality.** A kit riding inside a methodology pack means changing the methodology changes the kit, which is exactly the property the selection work's predicate tests against.

**E — the honest runner-up, and the reason it did not prevail.** A separate unit outside the pack directory is the only candidate that puts kits **structurally out of reach** of the licensed-kind union that scans that directory, rather than relying on a placement convention a later author can violate. Its cost is a second grammar to maintain forever: kinds, labels, controls and delta-inheritance all re-authored, a duplicate-source breach, and the opposite of the generality this decision is asked for. The union hazard is instead handled directly and at lower cost — test fixtures live outside the pack directory by decision, and an explicit skip rule in the union is available as further hardening if the convention ever proves insufficient. Judgment: the duplication cost is certain and permanent; the union risk is bounded and cheaply made structural.

**On whether to ship `kit_class` at all.** A sixth option was raised late by the adversarial review: drop the discriminator from v1 and introduce one when a genuine second facet arrives. It is a real option, and the completion condition this record answers permits ruling extensibility out with a reason. It was not taken because the reason for ruling it out would be weaker than the reason for designing it in: generality is cheapest before consumers exist, and the fix that makes the discriminator actually discriminate is one clause. The option becomes the correct call only if the two-level rule in D3 is declined — because a required field with no working rule is more expensive to correct than an absent one is to add.

## Consequences

### Positive

- A kind set becomes expressible **without naming an archetype**, which is the capability the release exists to deliver, and it is expressible in the grammar that already exists rather than in a second one.
- Kind-bearing and archetype identity are **separable concepts** in the grammar for the first time; a validator selects its completeness rule from the role rather than from a single rigid assumption.
- The unit is **generic over kit classes** — conditional on the grammar implementing D3's two-level rule — so a field, workflow or form kit registers a class and its facet without a role change, a second unit, or a grammar re-open.
- **Selection is orthogonal to methodology by construction**, because the two axes are two independent lookups against two independent fields. No test is load-bearing for the property; the test confirms a structural fact.
- **Every shipped pack is byte-identical and still valid.** No migration, no version bump, no shim.
- The base-pack contradiction is **closed** rather than carried, removing a second undesigned way to express a kit.

### Negative / cost

- **The change is not purely additive in grammar.** Four optional adds and one relaxation are symmetric or theoretical, but making the neutral value illegal on an archetype pack is a **restriction** — the one shape that can invalidate a previously-valid pack. The blast radius is measured rather than asserted: zero of three shipped packs combine that role with that value, with a live control arm, so the byte-identity guarantee holds. **The population that can be measured is not the whole population**: pack instances are operator-local configuration by design, so a deployment could hold an archetype pack using the neutral value. The restriction ships with no enforcing validator in the tree it would break, and the grammar states the restriction axis explicitly so an adopting deployment reads it before it bites.
- **The relaxation is asymmetric on the forward axis.** Widening `extends` to the kit role means a pre-existing validator asserting that only an archetype pack may extend would reject a now-valid kit pack. Currently theoretical — no tracked executable validates against this grammar today — and the first validator is authored kit-aware from the start rather than retrofitted, which is the obligation the composition-grammar record transferred forward and this record discharges.
- **An open value domain conditioning a requiredness rule buys a new failure mode.** A mistyped kit class falls through to the unregistered arm and relieves a work-item kit of an obligation it should carry. Bounded by the caveat, not by the type system, and named here so it is a known cost rather than a discovered one.
- **The unit acquires a placement convention that a later author can violate.** Fixture packs must live outside the directory the licensed-kind union scans, because that union has no allowlist and no naming filter. A convention, not a barrier — the alternative that would have made it a barrier is candidate E, which was rejected for a larger cost.
- **The definition is load-bearing for work outside this release.** Several downstream initiatives resolve against it, so a defect in the definition is expensive in a way a defect in one consumer is not. The compensating control is that the consumer map is authored inside the same release, before the grammar moves.

### Cross-D upstream-compat

The widened grammar inherits the kernel's open-value-domain discipline, and this record adds two members to the set of things no consumer may treat as closed:

- **The `role` set is OPEN.** It has just been widened from two members to three, which is itself the proof. A consumer branching exhaustively on role values will be wrong at the next widening.
- **The `kit_class` set is OPEN.** Its v1 value is `work-item` and it will grow. A consumer that branches on the literal `work-item` re-creates, one altitude up, the frozen-roster anti-pattern the kernel forbids for the work-item type set. An unrecognized class is handled generically with an explicit caveat, never a silent default and never an error.
- **The kit set itself is OPEN.** Which kits a deployment authors is its own data; nothing may enumerate them.

**`level_role` is the deliberate exception and is CLOSED.** `{execution, grouping}`, absent meaning `execution`, unknown being an error. It is closed because the distinction it names is binary and internal to a traversal, not an extensible successor set — and the difference between the two domains is stated here so that a later reader finds a decision rather than an inconsistency.

## Reversibility

**MODERATE / Confidence HIGH pre-consumption.** Before any deployment authors kit packs and before any consumer resolves against one, the additions are optional and no contract is live: the adds are absent-by-default, the relaxation lands ahead of any validator it could break, and the restriction closes a door no shipped pack walked through.

Crosses to **EXPENSIVE** once a deployment authors kit packs **and** the consumer read-refit resolves against them — at that point the grammar is a contract and undo means a migration plus unwinding every consumer. This is the same posture the two sibling pack records carry, and for the same reason.

**Deciding now is the cheap moment**, and the specific cheap-now/expensive-later item is D3: making the unit generic over kit classes costs one field and one branch today, and is expensive to retrofit once a second kit class exists and consumers have hardcoded the first.

## Related ADRs

- [ADR-018 — Work-Item Type Layer](ADR-018-work-item-type-layer.md) — the parent kernel this record extends at grammar altitude: the thin generic Work Item entity, the declarative type layer, and the open-value-domain discipline the Cross-D section above inherits and widens. This record opens no competing kernel.
- [ADR-070 — Methodology-pack composition grammar](ADR-070-methodology-pack-composition-grammar.md) — **extended, not superseded.** ADR-070 introduced the role discriminator with two members and the delta-inheritance model; this record widens the role set to three and adds the kind-level neutral sentinel that role alone cannot express. ADR-070 stays Accepted and its body is unmodified — its two-role prose is the historical record of a two-role decision, and its own cross-compatibility clause already forbids treating the role set as closed, which is what makes widening it conformant rather than a breach.
- [ADR-069 — Methodology pack as the plug-and-play composing unit](ADR-069-methodology-pack-composing-unit.md) — the sibling that fixes the composing unit, its placement and its selection. A kit is a pack under that same unit: one grammar, one loader, one parity check.
- [ADR-039 — Declarative gate-condition construct](ADR-039-declarative-gate-conditions.md) — the on-precedent shape for an additive extension of the kernel grammar: an optional construct whose absence is byte-identical to prior behavior. The four adds follow it. The relaxation and the restriction deliberately do not, and are grounded separately for that reason.
- [ADR-077 — Cross-cutting control-field layer](ADR-077-cross-cutting-control-field-layer.md) — the second prior extension of this grammar that landed without a version bump, and the other half of the precedent that keeps the grammar at v1 through this one.
- [ADR-022 — platform-config vs operator-config split](ADR-022-platform-config-vs-operator-toml-split.md) — establishes the configuration surface D4's selection field lands on and the additive-bump discipline the grammar version follows.
- [ADR-062](ADR-062-substrate-vs-canonical-precedent.md) — the rule this record follows in leaving the founding ticket's imprecise premise unamended on its own surface while correcting it here, where the canonical decision lives.

## Provenance

The decision kernel was designed at Stage 5 Solutioning of the `kit-unit-and-selection` release by the Principal Engineer persona, from a five-candidate exploration across three altitude bands with kill-reasons recorded for each elimination. The operator rendered the placement decisions and the corrected compatibility shape at Collective Review scope-lock.

**Three of this record's statements exist because an independent adversarial review falsified an earlier draft, and the provenance is recorded rather than smoothed over.** Every Stage-5 adversarial pass in this release was self-administered — no independent reviewer agent definition exists in this deployment, and each spoke labelled the caveat rather than claiming independence it did not have. A single independent pass was commissioned before Engineering and falsified, by execution, three premises that prior verification had confirmed by reading. The three corrections it produced are carried in D2 (the Layer-2 join mechanism, which had named a resolution path with no input), D3 (the generality claim, which the design's own requiredness rule foreclosed) and D4 (the empty-vocabulary constraint, which asserted that this release's headline capability is a hard error).

The lesson generalizes past this record and is the reason the corrections are stated at length rather than quietly applied: **a check that a line of code exists is not an exercise of the path it sits on.** Three verification passes confirmed a failure mode by locating its `return` statement; one reviewer falsified it by building the input and running the tool. A claim about behavior is verified by producing the behavior.

The grammar edits this record governs are implemented by the grammar slice of the same release, the selection surface by the selection slice, and the level-role carrier by the level-coverage slice; this record fixes the decision those edits implement.
