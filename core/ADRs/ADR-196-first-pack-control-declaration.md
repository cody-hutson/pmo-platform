---
title: "ADR-196 — The first pack-level control declaration: source is required on it, and the stub it replaces was held on an overbroad premise"
status: Accepted (rendered at the pack-conformance-and-parity Stage 5 Solutioning pass, gated to the operator as a reversibility-band decision, and carried into Engineering as decided)
date: 2026-09-10
release: pack-conformance-and-parity
deciders: Stage 5 Solutioning spoke (three ≥2-candidate design explorations, each alternative eliminated on in-corpus evidence) + the operator at the Stage 5 wave-1 gate, who rendered the band-crossing decision + Stage 6 Engineering on the schema siting and the version-analysis form
tags: [packs, type-packs, controls, control-field, set-aggregate, wip-limit, kanban, content-provenance, source-key, reversibility-band, population-zero, k4-boundary, ADR-018, ADR-039, ADR-070, ADR-077, ADR-189]
source_observations:
  - "As measured at this record's authoring, immediately before the declaration it records: the count of [[controls]] entries across every pack.toml the corpus holds — 17 tracked manifests, shipped and fixture alike — is zero. The same reader over the same files returns 21 for [[kinds]] and 48 for [[labels]], and a fabricated array name returns zero, so the reading is a measured absence rather than a dead reader."
  - "No consumer anywhere evaluates a set-aggregate condition. The tokens set-aggregate, limit_ref, guards_transition and on_unresolved each occur zero times across the tracked code files, against a live control on the same reader over the same population. The declaration this record governs is therefore inert on the day it ships."
  - "Three pack-validation errors the grammar declares on this exact construct are unenforced as measured at this record's authoring: a limit_ref naming a non-integer control, both limit and limit_ref present, and a dangling limit_ref each validate clean with a zero exit. The sensitivity arm — an identity mutation on the same roots — fires and exits non-zero, so the three zeros are measured absences of a rule rather than a dead instrument."
  - "The grammar validator does not read any key inside a criteria block and does not read the controls facet's content. The token checks occurs zero times in it, against live controls on the same reader over the same file."
  - "The kanban manifest's own gate-block provenance string records that the Kanban Method prescribes that a WIP limit exist and leaves its number to the service running the board. That string is the reason no corpus-wide default number is available, and it was authored before this record."
supersedes: none
---

# ADR-196 — The first pack-level control declaration: `source` is required on it, and the stub it replaces was held on an overbroad premise

## Status

**Accepted** — designed at the `pack-conformance-and-parity` Stage 5 Solutioning pass, surfaced to the operator as a reversibility-band decision because the first control declaration spends a property the corpus cannot get back, and carried into Engineering as decided.

**Numbering provenance.** Authored at the next free number computed from the mainline anchor, from a single anchor read shared with the sibling record this release also authors, so that two spokes could not compute next-free independently and collide. A branch-only claim is detection-only and never binds for mainline purposes; if the mainline advances before merge, the merge-time renumberer moves this record and in-release prose citing the slug token `ADR-196` resolves correctly either way.

## Context

The type-pack grammar has carried a cross-cutting `[[controls]]` facet since the control-field layer landed, and a gate arm that reads a cap from it by `limit_ref`. Until this release **no pack used either**. The facet was grammar with no instance.

Three things were pending on that emptiness at once, and binding one gate collapses all three.

**One — a gate held unbound on a premise about a single key.** The Kanban manifest shipped its `[kinds.criteria.gate]` deliberately unpopulated, and its inline comment gave the reason: a `set-aggregate` WIP condition needs a `scope_ref`, a `scope_ref` for a board is an instance entity id, and an instance id cannot be sourced into a git-tracked default. The last two limbs are true. **The first is not.** The grammar makes `scope_ref` required only at `scope = "board"`; at `parent` and `project` the counted population resolves from the item's own context and no `scope_ref` is carried at all. The premise was true of one *value* and was applied to the whole *construct*.

**Two — a provenance boundary explicitly left to whoever declared first.** The content-provenance rule requires a `source` on every criteria check entry and every kind-specific field declaration. It did **not** reach `[[controls]]`, and the schema said so deliberately, assigning the extension to *whichever change first declares a control*. That change is this one.

**Three — a cap that has no number, by the practice's own account.** The Method grounds the **existence** of a WIP limit and leaves its magnitude to the service running the board. The grammar requires exactly one of `{limit, limit_ref}`, so the option space is genuinely two-valued: invent a corpus-wide number the practice does not support, or resolve a `limit_ref` against a control. **There is no third option in which the gate binds and the control declaration is deferred to a later change** — that is what makes these three one decision rather than three.

## Decision

**Bind the gate at `scope = "parent"`, declare the control it resolves against, and require `source` on that declaration.**

**D-a — The gate binds, and the cap is separated from the structure.** The check guards `ready -> in-progress` on a `set-aggregate` count over the item's own container, filtered to the in-progress state and to the `card` kind. No `scope_ref` is carried, so nothing instance-local enters the corpus. The cap is a `limit_ref` into a control declared in the same pack — not the base pack, because a WIP limit is not archetype-invariant and the grammar's own firing rule says so: a timeboxed project may declare the same check and decline to fire it, bounding WIP by sprint commitment instead.

The control declares an integer domain with a floor of zero and **no `default`**, deliberately. A default would be exactly the invented number the practice forbids, and its absence is what routes an unconfigured deployment to the gate's `on_unresolved`. That disposition is **WARN-HEALTH, not BLOCK-TRANSITION**: with no default, a blocking disposition stops every pull on every deployment that has not configured a cap, which is every deployment on the day the pack ships. A default whose out-of-the-box behaviour is that nothing moves is not a default.

**D-b — `source` is REQUIRED on every `[[controls]]` entry, at the entry altitude only.** The block altitude is not exempted; it is **structurally inapplicable**. The two-altitude construct pairs an entry requirement with a block-level `source` on the table that would have held the entries, so a reasoned empty set has a site to state its basis on. `[[controls]]` is an optional top-level array-of-tables with no enclosing required table: a pack declaring no control writes nothing, and no reader can distinguish an absent array from an unwritten one. No reasoned-empty-controls construct is minted to manufacture a site.

**The requiredness is grounded on the population, and the population is the whole argument.** The restriction meets **zero** existing declarations, so it invalidates nothing and no pack is retrofitted. The immediately preceding provenance extension could not write that sentence — it recorded itself as the first extension whose restriction met a non-empty population, and named its own remediation cost. **A population empties exactly once.** Requiring the key now costs one authoring decision; requiring it after a second and third pack declare controls reproduces that retrofit one facet over.

**D-c — The stub's premise is recorded as falsified, not merely deleted.** The gate comment and the schema paragraph that held the gate unbound are both rewritten by this change, which removes the only surviving statement of *why the stub existed*. That reasoning is worth keeping, because the error in it is a reusable one: **a constraint that binds one field of a construct was read as binding the construct**, and the effect was to decline a default the platform could in fact ground. The narrower rule the boundary actually states — *decline to ship the value you cannot ground, never the structure you can* — is more useful than the verdict it replaces, and it is only visible once the premise is written down beside its correction.

## Alternatives Considered

**(a) Bind the gate with a literal `limit`.** *Rejected — it invents the number the practice declines to give.* The manifest's own provenance string records that the Method leaves the magnitude to the service running the board. A literal cap is a corpus-wide answer to a question the corpus is not entitled to answer, and it violates the boundary that keeps deployment config out of git-tracked defaults.

**(b) Bind the gate with a `limit_ref` at a control the corpus does not declare.** *Rejected — it ships a knowingly dangling reference.* The grammar makes an unresolvable reference a pack-validation error. That this is currently **undetectable** — measured, and recorded in the observation block — is an argument against doing it, not a licence.

**(c) Bind the gate now and split the control declaration into later work.** *Not available, rather than rejected.* The grammar requires exactly one of `{limit, limit_ref}` to be present, so this option collapses into (a) or (b). It is recorded because it is the natural scope-reduction instinct and the reason it fails is not obvious from outside the grammar.

**(d) Leave the gate unbound and preserve the empty band.** *Available, and it was the real alternative.* It keeps the single-commit-revert property. Its costs are that the stale premise survives in two governing surfaces, the provenance boundary stays open with no assignee, and the corpus's only pack-content fill does not land. The operator weighed this against (a)–(c) at the wave-1 gate and took the binding.

## Consequences

**Positive.**

- The gate a continuous lifecycle most needs is expressible as a shipped default, and the split between structure and value is now demonstrated rather than asserted.
- The provenance rule is uniform: every content-bearing declaration site carries a `source`, with no controls exemption for a later reader to discover.
- The version analysis for this extension can state what its predecessor could not — no declaration is invalidated — and the record of why that window existed survives.
- A deployment wanting a named board overrides to `scope = "board"` with its own `scope_ref`, so the corpus default degrades to the instance-precise form rather than blocking it.

**Negative, and stated rather than smoothed.**

- **The declaration is inert.** No consumer evaluates a `set-aggregate` condition. What ships is a statement of what the practice prescribes, for a deployment's adapter to bind. Acceptance grades its conformance, never its behaviour, and reading a green pack check as validation of its semantics would be a category error.
- **It manufactures the first instance of a construct nothing validates.** Three grammar-declared pack-validation errors on this exact surface are unenforced as measured. This change does not close them; it makes them consequential for the first time, and it supplies the first real-file fixture against which a content lint can be graded.
- **The resolution scope of `limit_ref` is undeclared.** The control-field arm carries an explicit scope key with reserved values; the set-aggregate arm carries none, so the grammar does not say at which level a consumer reads the cap. This record mitigates by declaring the control at both the container and the item level, so either reading resolves — but the ambiguity is real, it is a grammar hole rather than an authoring choice, and it is routed to intake rather than patched here.
- **A control id is now a shipped identifier.** It is named by a gate's `limit_ref` and by a deployment's config; renaming it is a cascade rather than a local edit.

## Reversibility

**MODERATE — HIGH confidence.** The control-field layer's own record bands itself CHEAP *pre-consumption* and MODERATE **once packs declare controls**, on the reasoning that while zero packs declare one, a single-PR revert restores the prior grammar byte-for-byte. **This change completes that crossing**, and the property it spends does not come back: after merge a control has existed in a shipped pack, and withdrawing the declaration does not restore the state in which none ever had.

**The adjacent crossing is NOT performed, and the distinction is load-bearing.** The declarative-gate record bands its own surface MODERATE pre-consumption and crosses to EXPENSIVE *once packs declare conditions **and** in-flight items are judged against them*. That trigger is a **conjunction**. This change satisfies the first conjunct and **cannot** satisfy the second: no resolver exists anywhere in the tree, so nothing can judge an item against the condition. The accurate statement is **conjunct 1 of 2**, and the second closes when a deployment ships a resolver — an event outside this repository's control and gated by no release here. An earlier framing of this decision described the EXPENSIVE crossing as performed; it was corrected against the record's own wording before the decision was rendered, and the correction is preserved here because a band recorded one step too high licenses ceremony the change does not warrant.

## Related ADRs

- The **cross-cutting control-field layer** record introduced the `[[controls]]` facet and the `limit_ref` composition this change first consumes, and its own reversibility clause is the one this change completes. Its statement that zero packs declare controls *at introduction* is self-anchoring and is preserved unrewritten.
- The **declarative gate-conditions** record owns the three-arm discriminated union. This change consumes the set-aggregate arm exactly as specified and adds no arm, no member and no reserved value; its conjunctive band trigger is read verbatim above.
- The **content-provenance `source` key** record is the boundary this change closes. It named the controls facet as an adjacent scope and assigned the extension to whichever change first declared a control; that assignment is discharged here, and the record itself is a decision-time artifact preserved unrewritten rather than amended.
- The **work-item type-layer** kernel record is unaffected: no kind, no entity and no field is added, and the thin generic entity is untouched.
- The **methodology-pack composition grammar** record is unaffected: no `role`, `extends` or kit classification changes, and the control is sited in the archetype pack rather than the base pack precisely because a WIP limit is not archetype-invariant.
