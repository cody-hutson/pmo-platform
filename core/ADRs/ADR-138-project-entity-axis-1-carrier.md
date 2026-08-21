<!-- reference-durability: allow-link -->
---
title: "ADR-138 — The Axis-1 carrier is resolved per entity, not named once; Project's carrier is `status`"
status: Accepted
date: 2026-08-21
release: operational-folder-enforcement-and-migration
deciders: "operator (D-22 seed-rather-than-defer; D-27 carrier ratification; D-40 amendment pricing; D-42 enforcement-path residual; D-47 scope-lock) + Stage 5 Solutioning spoke (design, rounds 1 and 3) + Phase A6.5 adversarial reviewers (the Blocker, and the two routed amendment defects) + Stage 6 Engineering spoke (build, re-derivation)"
tags: [entity-model, validation-rules, axis-1, lifecycle-state, persistence-dialect, frozen-surface, seeding, project-entity]
source_observations:
  - "V-CORE-03 named one key verbatim — `lifecycle_state` — and asserted its membership in the entity's Axis-1 enum. The Project entity's Axis-1 does not live in that key: the entity model states Axis-1 'reconciles 1:1 with `project-schema.md status`', and V-PRJ-03 keys its own rule on `status`. The rule and the entity therefore disagreed, and no Project record could satisfy both."
  - "The disagreement is not a naming accident. PROJECT.md is the only entity-backing file in the 19-roster that is ALSO a stamped ecosystem node, so it is the only file where one `lifecycle_state` key would have to carry two enums at once — the file's content-maturity machine and the entity's operational machine."
  - "The amendment was initially priced as a Tier-2 SCOPE CHANGE against a frozen surface. Read at source, the owning file's own handoff clause distinguishes the two limbs verbatim: 'field-list changes require reopening via a Tier-2 SCOPE CHANGE; validation-rule changes are owned here.' No field is added, removed, retyped or re-required by this change."
  - "The first drafted discriminator keyed on the literal `= Axis-1`. Measured over the owning file: that literal matches 2 rows, against a control arm of 51 `Axis-1` mentions and a specificity arm of 0 for a bogus literal. The file's own FROZEN house-style exemplar annotates its carrier as bolded `**Axis-1**` with no `=`, so a future override written in the named exemplar's style would have been silently mis-resolved."
  - "The proposed repair — key on the per-entity Axis-1 restatement row instead, 'uniform 19/19' — was re-derived at build and does NOT hold: the restatement appears on 18 of 19 entity sections. The FROZEN exemplar section carries no such header at all, declaring its Axis-1 in the field table instead. Neither single discriminator is uniform; their union is."
  - "One entity's Axis-1 delegates to Axis-2 rather than enumerating, so the amended rule's membership limb has no literal enum to resolve against there unless the rule admits delegation explicitly."
  - "After the carrier is resolved per entity, `lifecycle_state` — a ✅-required member of the frozen Core-7 — loses its only enforcement path on the one entity that overrides. Declared requiredness is unchanged; nothing would have checked it."
  - "The alternative rule id `V-CORE-08` was rejected on measurement: the range literal `V-CORE-01..07` occurs 20 times across 2 tracked files, one of which is outside this release's file-change matrix. A companion id inside the existing range costs zero cascade."
---

# ADR-138 — The Axis-1 carrier is resolved per entity, not named once

## Status

**Accepted.** Authored at Engineering for the `operational-folder-enforcement-and-migration` release, against the operator's D-22 decision to seed the corpus rather than defer the capability that consumes it, and D-27's ratification that `status` discharges the Project entity's Axis-1. Priced by D-40, guarded by D-42, scope-locked at D-47.

**Depends on:** [ADR-040](ADR-040-leadership-owner-person-ref.md) for the exactly-one-of owner invariant the seeded records must satisfy, and [ADR-058](ADR-058-pmo-entity-page-ssot.md) for the one-Person cap the seeding protocol honours.

## Context

Every entity in the 19-roster carries an **Axis-1** — its operational state machine. The Core validation rule that enforces it, V-CORE-03, was written as a single verbatim key: *`lifecycle_state` present ∧ ∈ this entity's Axis-1 enum*. For eighteen entities that is exactly right.

For the Project entity it is unsatisfiable. The entity model states Project's Axis-1 *"reconciles 1:1 with `project-schema.md status`"*, and the entity's own rule V-PRJ-03 keys on `status`. So a conformant Project record carries its operational state in `status`, and V-CORE-03 — reading `lifecycle_state` — either finds nothing or finds a value drawn from a different machine entirely. Either way it fails. Not for some Project records: for **all** of them, by construction.

The disagreement has a structural cause rather than a stylistic one. `PROJECT.md` is the backing file of the Project entity **and** a stamped node in the file ecosystem — the only file in the roster that is both. The node axis writes `lifecycle_state` to record *how mature the file's content is*; the entity axis needs a key to record *where the project sits in its delivery lifecycle*. Those are two machines with disjoint value sets. A single key cannot carry both, so the dialect renames one of them, and the rule set had never been told.

That mattered abstractly until a consumer arrived that would measure it. A completeness score whose factors resolve against an empty population reads zero regardless of implementation quality — so the corpus had to be seeded with conformant records for the score to mean anything. Seeding against a rule no record can satisfy would have produced records that were `entity_type`-present and V-CORE-03-invalid on every one, which is not a seeded population; it is a populated defect.

The question this record answers is therefore narrow and load-bearing: **where does the fix land, and what does it cost?**

## Decision

**D1 — V-CORE-03 resolves the carrier *per entity*; it does not name a key.** The amended rule reads: *this entity's Axis-1 carrier field present ∧ its value ∈ that entity's Axis-1 enum*, with both limbs resolved in the entity's own §3.N section. The default carrier is `lifecycle_state`; an entity overrides it by annotating a different field as its Axis-1 carrier. Today exactly one entity overrides — Project, to `status`. **Eighteen of nineteen entities are behaviourally unchanged by construction**, because their sections annotate no alternate carrier and the rule resolves to `lifecycle_state` exactly as before.

**D2 — The amendment is a validation-rule change, owned in-file, not a Tier-2 SCOPE CHANGE.** The owning file's §8 handoff clause draws the line verbatim: *"field-list changes require reopening via a Tier-2 SCOPE CHANGE; validation-rule changes are owned here."* The frozen artifact is the **field list** — type, requiredness, cardinality — and this change alters none of them: no field is added, removed, retyped or re-required. The entity model's own field-validation deferral says the same thing from the other side, assigning cross-field validation rules downstream of the freeze. The earlier Tier-2 pricing was applied to the wrong limb, and pricing a cheap fix as expensive is how a correct repair gets designed around.

**D3 — The carrier discriminator keys on the *annotation*, never on its punctuation.** The first draft keyed on the literal `= Axis-1`. Measured: **2** matching rows, sensitivity arm **51** (all `Axis-1` mentions), specificity arm **0** (bogus literal). The file's own FROZEN house-style exemplar annotates its carrier as bolded `**Axis-1**` with no `=`. A lexical discriminator would therefore have mis-resolved any future override written in the style the file itself names as exemplary — silently, and as a false L1 FAIL on every record of that type. The rule now names both live forms and states that the annotation rather than its punctuation is what discriminates.

**The recommended alternative was falsified at build and is recorded so it is not re-proposed.** Keying on the per-entity Axis-1 restatement row instead was offered as *uniform 19/19*. Re-derived against the tree: **18 of 19**. The FROZEN exemplar section carries no such header, declaring its Axis-1 in the field table. Neither discriminator alone is uniform — the *union* is, which is precisely why the rule cites both surfaces rather than picking one.

**D4 — The membership limb admits delegation, because one entity delegates.** One entity's Axis-1 delegates to Axis-2 rather than enumerating a machine of its own. A rule demanding *"∈ this entity's Axis-1 enum"* has nothing to resolve against there. The amended text resolves the enum to the machine the section restates **or the machine it names by delegation where it delegates**, which closes the gap at zero additional cost and stops a downstream consumer inheriting it.

**D5 — A separate presence guard retains the enforcement path the rename would otherwise remove (D-42).** `lifecycle_state` is a ✅-required member of the frozen Core-7. Once V-CORE-03 resolves per entity, nothing checks its presence on the entity that overrides — declared requiredness unchanged, enforcement silently gone. **V-CORE-03b** restates that requiredness independently: presence only, no membership limb, because on an override entity the key carries the backing file's node-axis value and is not drawn from the entity's Axis-1 enum. For the eighteen default-carrier entities it is subsumed by V-CORE-03 and changes nothing.

**D6 — The guard is `V-CORE-03b`, not `V-CORE-08`, and the reason is measured rather than aesthetic.** The range literal `V-CORE-01..07` occurs **20** times across **2** tracked files — 19 of them in the owning file's own per-entity headers, one in a sibling schema outside this release's file-change matrix. An eighth numbered rule would force a 20-line restatement cascade, including a delivery on an undeclared path. A companion id **inside** the existing range costs zero cascade and leaves every range label and the ≥7-inherited floor literally true. The row says so in its own text so the reading is stated rather than argued at review.

**D7 — The two writers stay non-interfering by disjoint key sets, and the ordering is a consequence of that, not a convenience.** The entity dialect writes `status` and never writes `lifecycle_state` or `created_date`; those two belong to the node stamper. The intersection of the seeded key set with the stamper's core field set is therefore empty, which is what makes a seed run and a stamp run commutative *in content*. They are **not** commutative in *time*: V-CORE-03b is discharged on a `PROJECT.md` by the stamper's value, so seeding a project whose file has not been stamped leaves the guard unsatisfied through no fault of the seed. The backfill runs first.

## Decision kernel (version-agnostic)

**When one validation rule must hold across a family of types and exactly one member persists the governed concept under a different name, resolve the field *per type* from the type's own declaration rather than naming the field once in the shared rule — and when you do, restate the displaced field's requiredness as its own rule, because a rename silently retires every check that named the old key.** Resolve the per-type declaration by what it *means*, not by the punctuation it happens to use: a lexical discriminator measured against fewer rows than the family has members is a false negative waiting for the first member that writes it differently.

## Alternatives Considered

1. **Bind the single consuming validator by acceptance criterion — tell it how to resolve the carrier — and leave the rule alone.** Rejected. It leaves the record **still invalid against the rule as written**, so any second validator, or the first one's next revision, re-opens the defect. That is a shadow contract: a fact true only inside one consumer's implementation, unrecorded on the surface that governs it. The criterion is retained — but as the *grading* instrument for this record's closure, not as the mechanism.

2. **Restate the carrier in the persistence dialect only.** Rejected on the falsifying observation that the validator reads the schema, not the dialect. A dialect note describes how the file serializes the entity; it has no standing to relax a Core rule, and asserting otherwise was the round-1 design's error.

3. **Reopen the frozen surface as a Tier-2 SCOPE CHANGE.** Rejected as the wrong instrument, per D2. The Tier-2 path is reserved for field-list changes, exercised twice on this roster and recorded inline both times. Invoking it for a rule-text change would both overpay and blur the boundary the §8 clause exists to keep sharp.

4. **Rename the field on one side — either lift `status` into the Core-7 for Project, or drop `status` in favour of `lifecycle_state`.** Rejected as genuinely Tier-2 and genuinely destructive. The first changes the frozen field list; the second breaks the 1:1 reconciliation the entity model states and every §8 consumer that parses `status` today.

5. **Number the presence guard `V-CORE-08`.** Rejected on the D6 measurement — a 20-occurrence cascade across two files, one outside the matrix. Worth restating because it is the *tidier* option and would be re-proposed by anyone who has not counted.

6. **Fold the presence guard into V-CORE-03 as a second conjunct.** Rejected because it makes the guard unfalsifiable on its own: a record failing the combined rule cannot be told apart from one failing the carrier limb, and the negative test that pins the override case would have no way to assert a PASS on one limb and a FAIL on the other. D-42 asked for a *separate* rule for exactly this reason.

7. **Extend the portfolio write-back contract with an entity-frontmatter section, so the Portfolio record has a declared producer.** Rejected — and this is a scope *reduction*, recorded because it reverses an earlier design position. That contract's §1 clause, which it labels load-bearing, states that no producer of the contract has an output path resolving into the operations tree. The proposed section would have been the first. The Portfolio record needs no new surface: its fields and V-rules already exist, and its home is already fixed.

## Consequences

**Positive.** A conformant Project record becomes expressible for the first time — the rule and the entity agree, so seeded records are *actually* valid rather than valid-by-agreement-with-one-consumer. The resolution is stated in V-CORE-03's own text, so a downstream consumer gets the right answer by doing what it already says it does: cite the schema and read it. Eighteen entities are untouched. Two defects routed from a sibling milestone are closed at the amendment, where they cost nothing, instead of after it merges, where they would not have.

**Negative, named.**

- **The rule is now indirect.** Reading V-CORE-03 no longer tells you which key is checked; you must resolve the entity's section first. That is a genuine legibility cost, paid to make the rule true for all nineteen instead of eighteen. It is mitigated by the rule naming the sole override inline, which is accurate today and is exactly the kind of statement that goes stale if a second override is ever added without updating it.
- **The `folder`-style two-category problem recurs on `lifecycle_state`.** On a Project backing file the key is present, required, and *not* the entity's Axis-1. A consumer that reads `lifecycle_state` as "the entity's state" will be wrong about this one entity — which is why the dialect's two-record key table, not this record, is the surface a writer should be reading.
- **V-CORE-03b is a rule id in a form this file has not used before.** The lettered companion is a new convention with exactly one instance. It was chosen over a numbered rule on cascade cost (D6), and the tradeoff is that a reader meets a convention with no second example to generalize from.
- **The blast radius is the whole rule set.** All 19 entities inherit the Core V-rules, so a four-line change here is the highest blast-radius-per-line change in its release. It is backward-compatible on 18 of them *by construction* rather than by review, which is the property that makes the radius tolerable — but the property is structural, and a future override would put a second entity on the changed path.
- **The corpus consequence does not revert with the repository.** A `git revert` of this record's commit restores the rule text and the dialect; it does not remove `status`, `entity_type` or any other seeded key from a live file. The reversal path there is the pre-write snapshot, restored by path, and it is independent of the repository path.

**Blast radius.** Four tracked surfaces: the Core V-rule table (V-CORE-03 amended, V-CORE-03b added), the §3.0 framing sentence, the Project entity's V-PRJ-03 annotation and negative-test list, and the persistence dialect that documents the resulting two-record shape. Additive on all four; no field table's Req / Type / Card column is touched anywhere.

## Reversibility

**MODERATE · confidence HIGH** for the repository side. The amendment is four modified lines and one added rule row in a single additive commit, with no vocabulary migration behind it and no field-list change to unwind.

**EXPENSIVE · confidence MEDIUM** once the seeding protocol has run. The seeded records live on a git-ignored tree that no revert reaches, and the write adds only absent keys, so it will not self-correct on a re-run. Reverting the rule after the seed has landed leaves a corpus whose Project records are valid against a rule the tree no longer defines. Confidence is medium rather than high because the snapshot restore is specified and, as of this record, demonstrated on no record — S6 exists to convert that to high before the release closes.

## Related ADRs

- [ADR-137](ADR-137-project-root-is-a-non-bin-sentinel.md) — the non-bin sentinel that makes a project's own governance files classifiable. Its stamp supplies the `lifecycle_state` value that discharges D5's presence guard on a `PROJECT.md`, which is why D7's ordering constraint runs backfill-then-seed.
- [ADR-040](ADR-040-leadership-owner-person-ref.md) — the leadership-owner type lift and the exactly-one-of owner invariant. It is the reason the seeding protocol's tier order is forced: an unresolved owner reference is BLOCK-WRITE, so the Person record must exist before any record references it.
- [ADR-058](ADR-058-pmo-entity-page-ssot.md) — the shared-entity store and the one-Person cap. The seeding protocol never auto-creates a second Person; unresolved names route to the operator clarification queue.
