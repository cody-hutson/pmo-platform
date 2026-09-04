<!-- reference-durability: allow-link -->
---
title: "ADR-187 — A methodology pack's default is the kind set it declares, and no pack-header field names a kit"
status: Accepted (operator-ratified at the kit-content-and-defaults Stage 5 Collective Review scope-lock 2026-09-04; one ground of the rejection re-grounded at Stage 6 after an independent Phase A6.5 adversarial pass falsified it by execution)
date: 2026-09-04
release: kit-content-and-defaults
deciders: Stage 5 Solutioning spoke + an independent Phase A6.5 adversarial reviewer + operator at the Collective Review scope-lock + the Stage 6 Engineering spoke on the re-grounded rejection ground
tags: [type-pack, methodology-packs, pack-default, kit-selection, resolution-order, named-gap, class-3-O, ADR-180, ADR-185, ADR-186]
source_observations:
  - "The resolution over the shipped corpus already returns each methodology pack's own kinds and nothing else. --resolve Scrum over the three shipped packs returns COUNT 3 (epic, story, task), all attributed to scrum, with kanban EXCLUDED; --resolve Kanban returns COUNT 1 (card) with scrum EXCLUDED. Both exit 0. The two kind sets are disjoint. Nothing had to be built to make that true."
  - "No kit ships. The pack corpus holds three packs and none carries role = \"kit\", so a pack-header field naming a kit would have exactly one shipped value -- the empty one -- unless the corpus reversed its own direction that a kit is deployment data."
  - "A cross-archetype eligibility edge DOES exist, and it is not the archetype join. The eligibility predicate is two limbs: limb (a) is a byte-identical applies_to match, and limb (b) is applies_to == \"*\" AND role == \"kit\". Limb (b) tests the pack's own neutrality and role, never the requested archetype, so it fires under EVERY archetype. The only guard that could suppress it excludes OTHER kits and is itself gated on a kit having been selected, so with no selection it never fires. Composition rank then places a kit above an archetype pack."
  - "Executed on two otherwise byte-identical conforming fixture roots differing by exactly one directory, both --validate-packs COUNT 0 exit 0 rules_evaluated=20. ARM 1 (a base pack plus a Waterfall archetype pack): --resolve Waterfall with no kit selected returns COUNT 2, zero role=kit rows, and the Waterfall pack owns its own pd-work-package. ARM 2 (the same two packs plus one methodology-neutral conforming kit declaring a colliding pd-work-package): the identical invocation returns COUNT 3 and pd-work-package is owned by the KIT. A neutral kit displaced a plan-driven pack's own declaration with nothing selected and no pack-header field anywhere."
  - "The same behaviour is observable over the shipped selection fixture root without adding anything to it: sel-shared is declared by both sel-kit-alpha (role=kit) and sel-k4-override (role=archetype, applies_to=Scrum), and an unnarrowed --resolve Scrum returns COUNT 5 with four kit-attributed rows, sel-shared among them, owned by the kit."
  - "There is no invocation that expresses 'resolved to no kit' over a kit-bearing root. Exhausted over the three reachable argument shapes: naming the kit leaves the kit winning; omitting the flag leaves the kit winning; and the empty string and the literal 'none' each exit 3 by the selection-resolves-or-fails-loudly rule, because both are read as a selection naming an absent pack. The flag's domain is a pack id or absent, and absent means UNNARROWED, never NONE SELECTED."
  - "The pack-header validator has no unknown-key rule. It reads named keys individually and asserts nothing about keys it does not name; its only two 'unknown' rules are value-domain rules over the role value and the kit-class value. The corpus already carries one declared-but-unread pack header key, on all three shipped packs, whose non-enforcement is an open finding of this same release's wave-1 spike."
  - "The corpus's stated reason for keeping the shipped-pack rationale out of each pack's header comment was that a header comment would break the byte-identity the kit extension guaranteed for all three shipped packs. That guarantee no longer holds: two of the three manifests changed in this release. The base pack alone is byte-identical to its pre-change state; the Scrum and Kanban manifests are not."
supersedes: none
---

# ADR-187 — A methodology pack's default is the kind set it declares, and no pack-header field names a kit

## Status

**Accepted.** Operator-ratified at the `kit-content-and-defaults` Stage 5 Collective Review scope-lock on 2026-09-04.

**One of the four grounds under D3 was re-grounded at Stage 6 and the record says so rather than shipping the original.** An independent Phase A6.5 adversarial review falsified ground 2 *by execution* — it built two conforming fixture roots differing by one directory and showed the property that ground claimed the rejected option would create is **already present**. The decision is unchanged and the record is stronger: it now rests on a ground that is true. The original wording, and why it was wrong, are preserved in D3 so a later reader does not re-derive the falsified premise and reopen a settled question on it.

## Context

The card this record serves asked that every shipped methodology pack **name a default kit**. Three facts about the corpus make that sentence unsatisfiable as written, and the third is the one that decides the shape of the answer.

1. **A "kit" is a defined unit, and none ships.** [ADR-180](ADR-180-work-item-kit-first-class-unit.md) froze a kit as a `role = "kit"` pack, methodology-neutral at the pack level and at every one of its kinds. The pack corpus holds three packs — a base and two methodology packs — and none is a kit. The corpus states the reason: a kit is *deployment* data, and this tracked tree ships best-practice defaults rather than one deployment's instance configuration.
2. **A selection naming an absent pack is a hard error, never a fall-through.** The resolver's selection rule makes a `--kit` naming a pack that is not in the read root exit non-zero, precisely so that a *failed* selection and an *absent* selection are different observations. So a pack-header field naming a kit could not degrade gracefully to "no kit": it would either name nothing, or name something the corpus must then ship.
3. **The word "default" is used at three altitudes in this neighbourhood, and conflating them is what makes the request read as a grammar request.** Only one of the three has no name today, and naming it is a different act from minting a field for it.

The forces are three.

- **A rule a reader cannot find is not a rule.** The pack's kinds already *are* its default and the resolution already returns exactly them. But a reader opening a pack manifest cannot tell "these kinds are the default" from "there is no default", and neither can a grader. Whatever ships must make that distinction stateable.
- **Whatever ships must not create a route to the thing the card exists to forbid.** The card asks that a plan-driven methodology's default not be a Scrum-shaped one. Any mechanism that lets one methodology-neutral declaration stand as *every* pack's default works directly against that.
- **Whatever ships must not move the deploy-time pack-conformance check.** That check runs a discrimination control before its live-corpus run and increments its issue counter **outside** the warn-mode gate, so a new pack-validation rule firing on either control fixture turns the check red regardless of mode. This constraint eliminated one design option before it was scored and constrained the fixture's shape.

## Decision

### D1 — "Default" is three things at three altitudes, and only the third is what this record decides

| Altitude | The thing | Where it is set | Whose default it is |
|---|---|---|---|
| **Deployment** | which kit this deployment tracks | the operator configuration's work-item-kit field; empty means none | the *deployment's* default kit |
| **Project** | this project's override | the project's own frontmatter kit field | the *project's* kit |
| **Pack** | what a pack contributes when nothing narrows it | the pack's own `[[kinds]]` | **the pack's default kind set — what this record names** |

The first two are decided at the configuration rung and are already documented. The third had no name. Naming it is the deliverable.

### D2 — A methodology pack's default is the kind set it declares

**A methodology pack's default is the kind set it declares.** When no kit is selected, a pack contributes exactly its own `[[kinds]]` — that is the pack's default, it needs no pointer, and it is what the resolution returns. A selected kit composes *above* it and wins a colliding `kind_id`; a project's own override wins above that. **A pack does not name a kit**, because a kit is deployment data and no kit ships in this corpus.

The rule is stated **once**, at the corpus's own selection-and-precedence home, and is cited from here rather than restated. It is `O(1)` in the number of packs: a seventh methodology pack adds no row anywhere, because the rule quantifies over packs instead of enumerating them.

### D3 — A `default_kit` pack-header field is rejected, on four grounds, one of which is a re-grounding

The option considered and rejected was a greenfield `default_kit` key in the pack header, each shipped pack naming the kit that is its default.

**Ground 1 — the field's only shipped value would be the empty one.** No kit ships, and the corpus directs that kits are deployment data rather than tracked corpus content. A selection naming an absent pack is a hard error, so the field cannot fall through. Its shipped value on all three packs would therefore be `""` **unless the corpus reversed that direction** — at which point the field's premise is a corpus change, not a pack-header change. *This ground is stated as a consequence of a standing corpus direction, not as an impossibility.* An earlier form said the field **cannot** hold a value; a norm restated as an impossibility overstates, and a sibling card in this same release narrowed the scoping of the very passage that norm rests on.

**Ground 2 — RE-GROUNDED. The field would sanction and name a route to a breach that is already reachable; it does not create the property.**

> **The original ground, preserved because a durable record must not quietly swap a premise:** *"The field makes a plan-driven pack's default violable; the rule makes it true by construction."*
>
> **That is false, and it was falsified by execution rather than by argument.** The eligibility predicate has two limbs. Limb (a) is a byte-identical `applies_to` match — no methodology pack ever reaches a foreign methodology through it. **Limb (b) is a separate, unconditional edge**: it tests `applies_to == "*"` **and** `role == "kit"`, both properties of the *pack being examined*, and reads the requested archetype not at all. It therefore fires under **every** archetype. The one guard that could suppress it excludes *other* kits and is itself conditioned on a kit having been selected, so with nothing selected it never fires. Composition rank then places a kit **above** the methodology pack. Two otherwise byte-identical conforming fixture roots, differing by exactly one directory, were built and run: with no kit present a Waterfall resolution returned the Waterfall pack's own work-package kind; with one methodology-neutral conforming kit added and **nothing selected**, the identical invocation returned that same kind owned by the **kit**. Both roots validate clean.

**The corrected ground.** A plan-driven pack's default is **already** displaceable through limb (b), with no pack-header field anywhere and nothing selected. A `default_kit` field would not create that property — it would make that route the **sanctioned** one and give it a name in the grammar: each pack names a kit, a kit is methodology-neutral by grammar, nothing reads a check's content, so **one** methodology-flavoured neutral kit becomes nameable as **every** methodology's default. The rejection stands on the difference between a reachable state and a blessed mechanism, which is a stronger ground than the one it replaces because it is true.

**Ground 3 — the field would ship declared, unread and unvalidated.** The pack-header validator has no unknown-key rule: it reads named keys individually and asserts nothing about the rest, and its only two "unknown" rules are value-domain rules over the role value and the kit-class value. A `default_kit` key would be the **third** declared-but-unread pack key, while the second is an open finding raised by this same release's own wave-1 spike. A field no rule reads is a declaration that cannot be wrong — the symmetric form, one altitude up, of the principle that an id with no runner is a gate that cannot fail.

**Ground 4 — the field would shadow this release's own content.** On a colliding `kind_id` the kit wins. A shipped default kit declaring the same kinds the methodology packs declare would make the criteria content this release authors into those packs dead in the default configuration.

### D4 — The forward path is named, so nothing is foreclosed

When a genuinely cross-methodology kind set appears — one **authentically** methodology-neutral, rather than one methodology's content wearing a neutral header — it ships as a `role = "kit"` pack, and a pack-header pointer earns its place **at that time**. That is the moment the field has something to name and a value to carry. This record forecloses nothing; it declines to mint the field ahead of its subject.

### D5 — The resolver has no arity for "resolved to no kit". The gap is REGISTERED, not closed here

`--resolve <archetype>` **without** `--kit` does not mean *no kit selected*. It means **unnarrowed**: every kit in the read root is eligible under every archetype, and each outranks the methodology pack. The flag's domain is a pack id or absent, and there is no third value meaning *deliberately none*. The deployment state "this deployment tracks no kit" therefore has **no representation** in the tool that makes the resolution executable.

**Exhausted over a kit-bearing root, three reachable argument shapes, none of which returns the methodology pack's kinds alone:** naming the kit leaves the kit winning; omitting the flag leaves the kit winning; and both the empty string and the literal `none` exit non-zero, because each is read as a selection naming an absent pack.

This is the same class the selection-resolves-or-fails-loudly rule closed one step over — it separated a *failed* selection from an *absent* one, and left a *deliberately-empty* selection sharing an invocation with an *unnarrowed* one.

**It is registered rather than fixed here, for three reasons stated so the deferral is a decision rather than an omission.** (i) The fix is new tool arity on a card whose deliverable is a rule and a fixture. (ii) The `--resolve` mode's own scope boundary makes it a *diagnostic* that reads no configuration file and is not a second resolver — so the arity question belongs to the consumer refit, not here. (iii) The state is unreachable over the shipped corpus, so a change made now would ship untested against any real deployment kit. **The gap is stated at the selection-and-precedence home in the gate-coverage register's form — invariant, enforcing gate (empty), declared observable — and its behaviour is pinned executably by a read-only self-test arm** over the existing selection fixture root, so the deferred defect is a green arm that must be edited when the arity lands rather than a prose row nobody re-reads.

### D6 — The acceptance evidence's boundary is DECLARED, because the fixture cannot exercise the configuration in which the rule can fail

The fixture root this record's card ships holds **zero** kits, and the shipped pack corpus holds zero kits. So the two zeros its arms assert — *no `role=kit` row in the resolution* over the fixture root, and *an empty plan-driven resolution* over the shipped corpus — are guaranteed by the **population** as well as by the rule. A control arm proving the reader finds `role=kit` rows where they exist proves the **reader** is live; it does not and cannot prove that **this** population could have exhibited the behaviour.

**Per D5 no fixture can currently do better**, because *"resolved to no kit"* is inexpressible. The honest disposition is therefore to say so: **this record's acceptance evidence excludes the only configuration in which the pack-default rule can be violated**, and the read-only arm named in D5 is what makes that configuration's actual behaviour visible and regression-guarded in the meantime.

## Alternatives Considered

| Option | Why not |
|---|---|
| **Change nothing; the populated kinds are the default by observation.** | True, and it is what D2 formalizes — but a reader who does not already know the rule cannot tell "these kinds are the default" from "there is no default", so the card's discoverability criterion has nothing to grade. D2 is this option **plus** the one sentence that makes it gradable. |
| **A `default_kit` pack-header field.** | Rejected on D3's four grounds. |
| **Reuse the kit-class key on the methodology packs** to declare "this pack's kinds are its work-item facet". | **A validation error today**, not a caveat: the pack validator permits that key only on `role = "kit"`. Adding it to the two shipped methodology packs puts them into pack-conformance findings. Eliminated on executable evidence before scoring. |
| **A sentinel value on the existing deployment-level kit field.** | Off-axis. That field is the *deployment* rung (D1) — a sentinel there states what this deployment does, not what a pack's default is, and it cannot vary per pack, which is exactly what a per-methodology default requires. |
| **A comment line in each shipped methodology pack naming its own kinds as its default.** | **Not taken here, and the reason is scope rather than merit.** It is immune to all four of D3's grounds — a comment declares nothing, so there is no unknown-key exposure, no validation surface, no shadowing and no empty-value problem — and the corpus's own stated objection to pack-header comments was that they would break a byte-identity guarantee that **this release has already falsified** on two of three manifests. It would, however, put two manifests back into a write set this release deliberately narrowed. It is recorded here as a live, costed option rather than a closed one. |

## Consequences

- The pack-default rule is stated once, at the home three other corpus documents already point to, and is `O(1)` in the number of packs.
- A methodology pack's default is **maximally local** — it is the pack's own declaration, with no pointer to follow. Whether that satisfies *discoverable from the pack* on a literal reading is a separate question from whether it is the right rule; the rule is right either way, and the literal reading is answered by the option in the last row of the table above, which remains open.
- Two named gaps become countable rather than invisible: the resolver's missing arity (D5), and the fact that a methodology-flavoured neutral kit is grammatically valid and outranks the methodology pack while nothing reads a check's content.
- Nothing gains a pack-validation rule id, so the deploy-time pack-conformance check's discrimination control is untouched by construction.

## Reversibility

**CHEAP · confidence HIGH.** One additive documentation subsection, one fixture root of two files, self-test arms, and this record. No file is deleted, no path relocated, no consumer contract narrowed, no meta-schema version moved, no pack-validation rule added, and no resolver output shape changed. Standard branch revert. The one caveat worth naming: reverting after the methodology packs' content has landed leaves that content in place and removes only the rule that names it as the default — the correct partial state, not a broken one.

## Related ADRs

- [ADR-180](ADR-180-work-item-kit-first-class-unit.md) — froze the kit as a first-class unit, its neutrality mechanism and the composition order this record's D2 cites rather than restates. This record is subordinate to it.
- [ADR-185](ADR-185-pack-configurable-vs-platform-fixed-boundary.md) — the configurable/fixed boundary for type packs; the sibling record from this same release that decides which of a pack's declarations a methodology owns.
- [ADR-186](ADR-186-kit-content-provenance-key.md) — content provenance on a pack's declarations; the sibling record that makes the authored content say where it came from.
- [ADR-062](ADR-062-substrate-vs-canonical-precedent.md) — why the originating card's body is not amended when a design renders one of its criteria against current capability.
