---
title: ADR-196 — The per-kind authoring bar is a reading of the declared grammar, not a new carrier
status: Accepted
date: 2026-09-11
release: authoring-bar-and-consumers
deciders: Workspace owner (Stage-4 D-StandardHome gate; Stage-5 Collective Review scope-lock), Stage-5 Solutioning spoke, Stage-5 Phase A6.5 adversarial reviewer, Stage-6 Engineering spoke
tags: [work-item-types, methodology-packs, authoring, standards, grammar-placement, criteria]
source_observations:
  - "Measured 2026-09-11 against the tracked tree at e8665feb: the shipped methodology pack manifests already declare per-kind criteria checks and kind-specific field declarations, every one of them carrying a non-empty source naming the body of practice it derives from, and every present-and-empty criteria or fields table carrying one at block level. The content the originating work item described as absent had landed six days after that item was filed."
  - "Measured over the same manifests with a live control arm on a declared key that is genuinely present: relationships.required_edges[] has zero instances, and methodology_projection.level_role has zero instances. methodology_projection.general_level, base and axis1_state_machine each carry one identical value across every declared kind. Two kinds at visibly different altitudes declare byte-identical relationships.allowed_types[] sets. The only key that varies with every kind is methodology_projection.projects_as, whose value is a methodology vernacular name."
  - "The placement sequent in the type-pack meta-schema's configurable/fixed boundary was executed against a Kind-level authoring-depth key and returned NOT PLACED, reached through the identity, join, aggregation and firing questions in order and routing through the counter-test arm for a declaration nothing reads. The run was executed independently a second time by the adversarial reviewer, from the section text rather than from the first run's report, and reached the same arm."
  - "The type-pack grammar states that a block-level source never satisfies an entry's requirement and an entry's never satisfies the block's, because the two answer different questions — why this declaration exists, versus why none does."
  - "The gate-coverage register's content-provenance row is scoped to a declaration site and to a present-and-empty array. A dimension of the authoring bar can read zero inside a populated array, which that row's declared observable cannot detect."
supersedes: none
---

# ADR-196 — The per-kind authoring bar is a reading of the declared grammar, not a new carrier

## Status

Accepted. Ratified at the Stage-5 Collective Review scope-lock for the `authoring-bar-and-consumers` release, with two structural findings from the independent Phase-A6.5 adversarial review routed Tier-1 and applied inside the design shape rather than reopening it.

## Context

An author writing a work item of some declared kind needs to know what good looks like for that kind — its expected structure, the content it must carry, and the depth appropriate to its altitude. The cross-kind authoring rules were already owned and written down. What was missing was the per-kind half.

Two prior facts bound the shape of any answer. **The public corpus stays methodology-neutral** — no methodology is privileged in the codified corpus, and the grammar stays archetype-invariant while the concrete rows live in the selected packs ([ADR-069](ADR-069-methodology-pack-composing-unit.md) D3). And **per-kind content lives in the pack manifests**, whose physical form is TOML on the config surface rather than the `.md` grammar surface ([ADR-069](ADR-069-methodology-pack-composing-unit.md) D4). The operator rendered the placement decision as a **cleave**: the archetype-invariant rubric in the standards corpus naming no kind, the per-kind content staying in the manifests.

**The premise the originating work item was filed on was true when filed and had been refined by the time the design ran.** At filing, nothing stated how a good item of one kind differed from a good item of another. Six days later a commit populated the shipped manifests with per-kind criteria checks and field declarations, every one carrying its own practice citation. Measured at the baseline in `source_observations:`, the per-kind *content* exists and is practice-cited throughout. So the question stopped being *what content is missing* and became *what reading of the existing declarations is missing*.

That reframing is what this record exists to fix in place, because the naive reading of "per-kind content lives in the manifests" points straight at a carrier — a new key, or a new prose file beside each manifest — and that carrier is the wrong answer for reasons a future author would otherwise re-derive from scratch.

## Decision

**Part 1 — The per-kind authoring bar is a reading of declarations the grammar already carries. No carrier is added.** The authoring standard names three dimensions — expected structure, required content, appropriate depth — and states which already-declared per-kind keys realize each. It adds no key to the grammar, no file class to a pack directory, and no value to any shipped manifest. Because it names no kind, a kit declaring a further archetype adds no rule to it.

**Part 2 — The assignment of a declaration to a dimension is an ordered procedure, not a set of named classes matched by inspection.** A declaration routinely satisfies more than one dimension on its face. Asked as an ordered question — shape first, then presence, then altitude-and-adequacy — every declared element lands in exactly one dimension and the partition sums to the kind's declaration count. Asked as a set of names, it does not, and two reviewers reading one manifest produce two partitions. **The precedence rules are the load-bearing part**: shape precedes presence, so an edge-asserting declaration is structure even when reading a field's presence is how it asserts; and presence precedes adequacy, because where a machine-evaluable declaration tests a field's presence, a judgment-level declaration over the same field tests its adequacy, and the declared field is the subject of that judgment rather than its resolution.

**Part 3 — The bar is necessarily a two-part artifact, and the standard says so.** Under the cleave, a rule stating one kind's depth bar would have to name a kind. So the standard states the dimensions and the reading, the manifests carry the values, and neither half is the whole bar. This is recorded as a consequence of the placement decision rather than absorbed silently, because a reader who expects one artifact will otherwise read the standard as incomplete.

**Part 4 — A dimension of zero inside a populated array is an accepted residual, not a reasoned zero.** The grammar's block-level provenance key certifies a *present-and-empty* table — it states why nothing was declared there. It does not reach a gap **inside** a table that is not empty, and the grammar forbids the inheritance that would let it: a block-level provenance value never satisfies an entry's requirement, because the two answer different questions. A dimension reading zero while the kind's arrays are populated is therefore recorded, named, with its reason, in the measurement record that observed it — never discharged by a provenance value at another altitude.

**Part 5 — The depth test takes its input from a kind's own criteria statements, and the standard says so explicitly.** No declared key expresses a kind's altitude. Two candidate keys have zero instances in the shipped manifests; three more carry one identical value across every declared kind; the relationship-type sets do not separate two kinds at visibly different altitudes; and the only key that varies with every kind carries a methodology vernacular name, which a methodology-neutral standard may not read altitude from. Stating the test's actual input is what keeps a downstream grader from hunting for a key that does not exist.

## Methodology

The candidate carriers were generated first and eliminated against hard constraints before any scoring, so the record below is a set of executed tests rather than a preference ordering. Two of the eliminations are executions of instruments the corpus already owns, and those are the durable half of this record.

**The placement sequent, executed.** A `Kind`-level authoring-depth key was run through the configurable/fixed boundary's own ordered placement test in [`work-item-type-schema.md`](../schemas/work-item-type-schema.md) § 1.5.5. The identity question answers no — authoring depth is derivative of what a kind is, not constitutive of it; what the entity *is* is already carried by its base, its projection and its relationships. The join question answers no on both limbs and carries the no-consumer flag: no shipped reader resolves such a key, and no specified reader is named for one in the consumer designs that would have to read it. The aggregation question is reached with no aggregate reading an admissible-value set for such a key. The firing question answers no. All four negative with the flag routes to the counter-test arm for a declaration nothing reads at all, and the verdict is **NOT PLACED** — routing to the coverage register as an unclassified declaration rather than into the grammar.

**Counter-test A is recorded N/A rather than skipped.** That section requires both counter-tests answered in writing. Counter-test A is scoped to a candidate placed FIXED; this candidate is not placed at all, so it has no subject, and the N/A is written down so an absent line cannot be read as an unconsidered one. A future author re-opening the key applies the test **prospectively** — a reading the section itself distinguishes from the retrospective one — and the join question's specified-consumer limb is the one that can change the arm.

**The run was independently reproduced.** The adversarial reviewer executed the same sequent from the section text, without reading the first run's arm-by-arm report, and reached the same verdict. A placement result reproduced by two independent executions is the evidence this record carries forward; the first run's report alone would not have been.

**The no-inheritance clause, read at source.** The candidate that would reuse the grammar's block-level provenance key to state a chosen depth was eliminated on the grammar's own words rather than on judgment: the two altitudes answer different questions, and repurposing one mints a same-name-different-meaning pair inside a single dialect.

## Alternatives Considered

Four carriers were weighed. Each was eliminated on a breached hard constraint, and the constraint is named so a future author can test whether it still holds rather than re-deriving the elimination.

- **A `Kind`-level authoring-depth key in the manifest grammar.** The literal reading of "per-kind content lives in the manifests". **Rejected on the grammar's own placement test**, executed and independently reproduced: **NOT PLACED**, for want of any reader — shipped or specified — that resolves such a key. **Re-entry condition:** a named, tracked consumer specified to read the key flips the join question's prospective limb, and the sequent is then re-run prospectively. The elimination is a property of the current consumer set, not a permanent verdict on the idea.
- **A prose sidecar file beside each pack manifest.** **Rejected on the pack corpus's own layout statement**, which declares one directory per pack holding a single manifest, and on the new pack-member file class it would introduce — itself a grammar question needing its own record. A per-archetype prose file also re-opens the shared-layer duplication the cleave exists to prevent, unless it carries per-kind rows only, at which point it is the chosen option with a redundant file in front of it.
- **Generalizing the block-level provenance key to state the basis for any block's chosen depth.** **Rejected in terms** by the grammar's no-inheritance clause: a block-level provenance value never satisfies an entry's requirement, nor an entry's the block's, because the two answer different questions. Reusing the block altitude for a third question mints a same-name-different-meaning pair inside one dialect.
- **Authoring the depth statements as ordinary criteria-check entries in the manifests.** This one is **not rejected on its merits** — the shipped manifests already carry depth-expressing checks in exactly this form, and the chosen option is the description of what they are. What was rejected is **adding more of them as this work item's deliverable**, on a scheduling constraint rather than an architectural one: the release measuring the declared check set and the release consuming that measurement are the same release, and moving the denominator between the measurement and its consumption would invalidate the consumption. **Re-entry condition:** a re-measurement of the declared check set landing in the same change that adds to it. Recorded as deferred-by-release-arithmetic, not as wrong.

## Consequences

**Positive.**

- The rubric quantifies over any kind in any resolved kit and names none, so a further archetype adds no rule to it. That is what makes the standard methodology-neutral by construction rather than by review.
- The ordered assignment procedure is re-runnable by a reader, so a published partition can be disagreed with. A partition stated only as a set of named dimensions cannot be.
- Nothing in the shipped manifests moves, so the declared check set that this release measures is the same set its consumers evaluate against.
- The executed placement result is recorded with its arm-by-arm reasoning and its re-entry condition, so re-opening the key starts from the test rather than from first principles.

**Negative, and carried rather than closed.**

- **The bar is two artifacts.** A reader who expects the standard to state a specific kind's depth bar will not find it there, and must read that kind's declarations through the standard. This is the cleave's cost, and it is paid in reader effort every time.
- **The depth test's input is the set of statements whose adequacy it assesses.** Read against the practice each statement cites, that is not circular; read against the manifest alone, it is. The standard states this rather than hiding it, but no instrument enforces the distinction.
- **A dimension can read zero inside a populated array and no declared key speaks to it.** The provenance obligation the grammar carries is scoped to a declaration site, so this residual is recorded in a measurement record rather than certified anywhere in the corpus. It is visible only where someone runs the partition.
- **The authoring standard's rules are, by the gate-efficacy admission test, not admissible** — they state no verdict and name no firing moment. That is the correct classification and it is declared per rule, but it means the standard is guidance enforced by review, and nothing in the tree will notice a kit that ignores it.
- **The enforceability dimension ships declared and unresolved**, because the judgment-level evaluability measurement it depends on is outstanding. An unresolved dimension is not a licence to leave normative predicates standing and unrun, and the standard says so — but the resolution is owed by a later release.

## Reversibility

**MODERATE.** Pre-consumption, reverting the merge restores the tree exactly: the standard is a net-new file with no inbound references, the pack-corpus pointer is a single appended list item, and no shipped manifest is touched. It crosses toward **EXPENSIVE** once the elicitation and gate consumers cite the standard, at which point the reading becomes a contract with readers — the same crossing [ADR-069](ADR-069-methodology-pack-composing-unit.md) names on this surface. Both land in one merge, so the crossing is same-merge rather than deferred. Confidence **HIGH**.

## Related ADRs

- [ADR-069](ADR-069-methodology-pack-composing-unit.md) — the methodology pack as composing unit. D3 owns the methodology-neutrality requirement that makes this standard name no kind; D4 owns the placement of per-kind content in the manifests. Cited and not amended.
- [ADR-070](ADR-070-methodology-pack-composition-grammar.md) — the pack composition grammar the manifests conform to. A new pack-member file class is a question for that record, which is why the sidecar alternative was not decided here.
- [ADR-195](ADR-195-l3-judgment-criteria-evaluability.md) — criterion evaluability as a per-check measured property. Owns the judgment-level verdict the standard's enforceability section cites by identifier, its measurement state, and the routing rule the standard takes its branch from; also the presence-versus-adequacy finding this record's ordered procedure grounds its second precedence rule on.
- [ADR-018](ADR-018-work-item-type-layer.md) — the Work-Item Type Layer. The thin generic entity plus declarative type layer this record reads rather than extends.

## References

- [`core/standards/work-item-authoring-standard.md`](../standards/work-item-authoring-standard.md) — the standard this decision authorizes.
- [`core/schemas/work-item-type-schema.md`](../schemas/work-item-type-schema.md) — the type-pack grammar; § 1.2 the declared per-kind key set, § 1.2.1 the content-provenance obligation and its no-inheritance clause, § 1.5 the configurable/fixed boundary and § 1.5.5 the placement test executed above.
- [`core/standards/gate-efficacy-standard.md`](../standards/gate-efficacy-standard.md) — the admission test each of the standard's rules declares its class under, and the gate-coverage register this decision adds no row to.
- [`core/packs/README.md`](../packs/README.md) — the pack corpus's governing document, which carries the reader's pointer from that corpus into the standard.

## Provenance

Rendered across the `authoring-bar-and-consumers` release. The placement decision between an archetype-invariant rubric and per-archetype prose was taken by the operator at the Stage-4 decision gate; the design was produced at Stage 5, independently adversarially reviewed at Phase A6.5, and scope-locked at Collective Review with the review's two structural findings routed Tier-1 into Engineering. The measurements in `source_observations:` were taken by the Stage-6 Engineering spoke against the tracked tree named there, each with a control arm on a declared key that is genuinely present, so a zero reads as a measured absence rather than as a dead probe.
