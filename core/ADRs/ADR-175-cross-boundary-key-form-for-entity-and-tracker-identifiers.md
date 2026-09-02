<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: "ADR-175 — The cross-boundary key form is a qualified composite anchored on the project's frontmatter join key"
status: Proposed — flips to Accepted at Stage 13 Close (Phase A13, the ratification beat; gate row G-CL9 verifies). The flip is recorded in this file's `status:` field, which is where it must be verified — the automated ratification-flip check is advisory-only and structurally cannot fail, so this line is the authority, never a milestone state or a review comment.
date: 2026-09-02
release: pda-decisions-and-conformance-baseline
deciders: "Stage 5 Solutioning spoke (candidate generation, constraint elimination, blast radius, evidence-grounding) + adversarial design review (root-anchor rejection, falsified repair guarantee, rule-pair contradiction, cross-design datum contract) + operator at Collective Review scope-lock (two binding entry conditions: re-anchor the namespace root on the frontmatter join key and add the ninth identity binding; reconcile the bare-reference rule pair and the alias-bound edge guarantee) + Stage 6 Engineering spoke (authorship, entry-condition discharge, measured-datum discharge)"
tags: [architecture, entity-model, identifiers, key-form, reference-grammar, referential-integrity, dual-key-binding, namespace-root, tier-2-precursor, governance]
source_observations:
  - "An entity `id` is unique only within its storage tier, and the project-scoped tier is scoped per project — so a bare tier-local slug is ambiguous the moment a reference crosses a project boundary. Portfolio-level fields reference project-scoped ids with bare slugs, the typed-ref carries a type-tag claim with no grammar anywhere, and tracker row ids have no qualified form at all."
  - "A scan of every tracked markdown file at the authoring baseline found zero occurrences of any URI, URN, or global-entity-id scheme; the control pattern (the tier-uniqueness rule text) fired 12 times on the same instrument and population, and the specificity arm returned zero. There is no incumbent scheme to extend or migrate from."
  - "The project persistence dialect derives the Project entity's `id` from the project folder slug, while the project-identity resolution rule declares `project_id` — the kebab slug carried in PROJECT.md frontmatter — the sole join key by which a record resolves to a project, forbids ever deriving a `project_id` from a folder basename, and states in terms that the two are not required to be equal and that equality is never assumed. They are two distinct named keys with contradictory derivation rules in one dialect, the persisted key set carries no `project_id` row, and no rule anywhere binds the pair."
  - "Eight entities in the 19-entity roster carry both a core `id` and their own `<entity>_id` natural key with no stated binding between them. Project is not one of them: its entity field table carries no `project_id` field, so the project join key lives in the persistence dialect rather than in the entity model."
  - "Every dual-key worked example in the corpus already carries the entity-specific id byte-equal to the core id — 3 of 3, with zero counter-examples — but no rule stated the binding, so the agreement was convention rather than contract."
  - "The referential-integrity rule family carried 37 X-rules at authoring, of which 16 bind inbound edges to a natural key and 14 to the surrogate `.id` alias. The Person anchor note in the schema states that the anchor grounds 12 inbound person-FK rules, which an independent row census at the authoring baseline reproduced exactly."
  - "The instance-wide conformance baseline measured, across 3 live projects with zero unmeasured cells: 93 stored cross-entity reference values, of which 7 are bare slugs crossing a project boundary; 68 RAID owner cells all carried in person-NAME form with no id-form value present, of which 20 resolve only under kebab name-fold tolerance and 48 resolve to nothing; 5 template-token references; and 0 pairwise Project-id collisions across 3 live ids, every one of them read on the frontmatter basis."
supersedes: none
---

# ADR-175 — The cross-boundary key form is a qualified composite anchored on the project's frontmatter join key

## Status

**Proposed** — flips to **Accepted** at Stage 13 Close (Phase A13, which owns the `Proposed → Accepted` performing beat; gate row G-CL9 verifies the flip). The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified — the automated ratification-flip check is advisory-only and structurally cannot fail, so the field is the authority, never a milestone state, a stage comment, or a green close-out.

**Numbering provenance.** Allocated at this Engineering commit as the next number above the union of the mainline anchor and this branch's own in-flight claims — never `max(claimed)+1`. `renumber-adr.py --detect` at the commit instant reported `ANCHOR 172 origin/main`, `NEXT-FREE 173`, `CLAIMED-SET-BRANCH-ONLY 173,174,175,176 (detection only — never binds)`, and two binding branch claims: `ADR-173 … BINDS` and `ADR-174 … BINDS`. This branch already carries the sibling lifecycle-carrier record at 173 and the sibling validator-surface record at 174, so the union is `{…172} ∪ {173, 174}` and **175** binds here. The branch-only claims on 175 and 176 belong to other in-flight branches and never bind; a cross-branch collision is governed — resolved by the renumber tool at merge time — and is never a reason to skip ahead or reserve a higher slot.

## Context

An entity `id` is unique only **within its storage tier**, and the project-scoped tier is scoped **per project**. A bare tier-local slug is therefore ambiguous the moment a reference leaves the project that owns it — and the model is full of such references. Portfolio-level fields cite project-scoped ids as bare slugs. The polymorphic typed-ref is declared "tagged in the typed-ref value" with no grammar defined anywhere to say what that tag looks like. Tracker row ids (`TR-###`, `MSG-###`, `DEC-###`, and the RAID `[TYPE]-[SKILL]-[COUNTER]` dialect) have no qualified form for cross-project citation. No URI or global-id scheme exists anywhere in the corpus to fall back on.

Underneath that sits a second, quieter gap. Eight entities carry both a core `id` and their own `<entity>_id` natural key, and **no rule binds the pair** — the FK-target convention mixes natural keys and surrogate `.id` targets, so the same record is addressable two ways with nothing guaranteeing the two spellings agree.

And underneath *that* sits the namespace root itself. The project persistence dialect derives the Project entity's `id` from the **project folder slug**, while the project-identity resolution rule names `project_id` — the kebab slug in `PROJECT.md` frontmatter — the **sole join key** by which a record resolves to a project, forbids deriving a `project_id` from a folder basename, and states plainly that the two "are **not required to be equal**, and equality is never assumed." Two distinct keys, contradictory derivation rules, no binding.

Every downstream schema change consumes one answer to all of this at once, which is why the answer is decided here, before the frozen entity surface is reopened, rather than improvised three times inside the reopening.

## Decision

**D1 — The cross-boundary key form is the qualified composite `<project_id>/<id>`, carried by one canonical reference-value grammar.** `ENTITY_REF_RE` is defined **once** — in the entity-field schema's reference-grammar section, the delivery child's edit — and cited, never restated, by every consumer:

~~~
REF      := [ TAG ":" ] BODY
TAG      := PRJ|MIL|WS|PLN|DEC|RAID|MTG|RES|ART|PER|SYS|VEN|PORT|PROG|XPD|XRC|INIT|WI|FND
BODY     := LOCAL | PROJECT "/" LOCAL
PROJECT  := the target project's project_id (the frontmatter join key — see D2)
LOCAL    := a single reference token drawn from the naming standard's T1 charset
            [A-Za-z0-9_-], containing neither "/" nor ":"

ENTITY_REF_RE = ^(?:(PRJ|MIL|WS|PLN|DEC|RAID|MTG|RES|ART|PER|SYS|VEN|PORT|PROG|XPD|XRC|INIT|WI|FND):)?(?:([a-z0-9][a-z0-9-]*)/)?([A-Za-z0-9][A-Za-z0-9_-]*)$
~~~

`TAG` reuses the entity short-code registry the schema already carries as its V-rule prefix authority; no second code vocabulary is minted.

**`LOCAL` is a single reference token, not a single naming-standard segment, and the widening is deliberate.** The naming standard's T1 tier makes `_` the *primary segment separator* and `-` intra-segment only, so a token containing `_` is multi-segment by that authority, and the entity-slug convention is lowercase kebab. `LOCAL` admits uppercase and `_` regardless, because the tracker row-id dialects it must carry (`TR-004`, `R-PPM-001`, `I-DE-003`) are legitimate reference targets that a kebab-only production would reject. The grammar therefore states the charset it accepts rather than borrowing a segment rule that does not describe it — a validator built from this regex admits exactly what the prose says it admits.

**D2 — The namespace root is `project_id`, and `Project.id` is bound to it.** This is the load-bearing correction to the design this record ratifies, and it is stated as three clauses that hold together:

1. **`PROJECT` in the grammar resolves to the target project's `project_id`** — the kebab-case slug carried in that project's `PROJECT.md` frontmatter, which the project persistence dialect already declares the **sole join key** by which any record resolves to a project.
2. **The ninth identity binding.** A Project record's core `id` MUST be byte-identical to that project's `project_id`. **This rule is unconditional.** A record where the two differ is malformed. `project_id` is the **anchor**; core `id` is its record-level alias; a divergent record repairs `id` toward `project_id`, never the inverse.
3. **Seed idempotency.** The folder-slug derivation in the persistence dialect is re-scoped from *source of truth* to **seed-time fallback**: it supplies `id` only on the first write of a Project record whose frontmatter carries no `project_id`, and `id` is never re-derived afterwards. A folder rename followed by a re-seed therefore cannot move the namespace root.

The reason this is the anchor and the folder-derived surrogate is not: **the folder basename is a cosmetic display projection**, free to change without breaking an edge, and the identity-resolution rule forbids crossing it from the display namespace into the identifier namespace *and declines to require the two equal*. Anchoring a qualifier that is embedded in **every** cross-boundary reference value on that surrogate would have made the namespace root the least-governed key in the entire scheme: a cosmetic rename plus a re-seed would dangle every qualified value in the instance — precisely the blast radius the qualified composite was chosen to avoid. The eight dual-key entities anchor on their natural keys with `id` as the repaired alias; the ninth key, the one every qualified value embeds, gets the same discipline rather than an exemption.

**Project is not the eight entities' ninth member, and the binding is shaped accordingly.** Project's entity field table carries **no** `project_id` field — the join key lives in the *persistence dialect* while `id` lives in the *entity model*, so this binding crosses a layer boundary the other eight do not. Its enforcement row must therefore sit where both keys are visible (the project persistence dialect, alongside the persisted key set), not inside the entity-model dual-key companion rule. Naming the asymmetry is part of the decision: a binding filed in the wrong layer would be unenforceable at the only surface that sees both values.

`Project.id` is instance-unique as a **consequence** of this binding rather than as an independent promotion — a sole join key that collided across the instance could not be one. This also settles the core-`id` scope reading: **per-project** scope for project-scoped entities other than Project, **instance** scope for Project itself.

**D3 — The dual-key binding rule, and the exact scope of what its repair preserves.** For each of the eight dual-key entities — Person, System, Vendor, Portfolio, Program, Cross-Project Dependency, Cross-Project Resource Conflict, Strategic Initiative — the `<entity>_id` field value MUST be byte-identical to the core `id` value. **This rule is unconditional.** A record where the two differ is malformed. The `<entity>_id` natural key is the anchor; core `id` is its record-level alias; a divergent legacy record repairs `id` to match `<entity>_id`, never the inverse.

**Repairing `id` is a two-step procedure, and the second step is not optional.** The repair preserves every edge bound to the **natural key** — the person-FK rules, the portfolio-FK rules, the program-FK rules — because those edges never named `id` in the first place. It does **not** preserve edges bound through the **`.id` alias**: the cross-project-dependency reference rule targets `<any entity>.id`, the relationship-edge target resolves against `.id`, and the dependency validity rules resolve "any roster `.id`". A value written against a pre-repair `id` **dangles the moment the repair lands**. The procedure is therefore: (1) repair `id` to match `<entity>_id`; (2) re-point every alias-bound inbound reference whose value equals the pre-repair `id`. A repair that stops after step 1 breaks the alias-bound edges silently.

The earlier formulation of this rule claimed that "no inbound edge ever breaks." That claim is **false as stated** and is corrected here rather than carried: it holds for the natural-key edges and fails for the alias-bound ones. The distinction matters because a decision record's invariants become a delivery child's repair script.

Enforcement lands as a **companion rule inside the core rule family**, conditionally inherited by the eight dual-key entities only — deliberately *not* an eighth core rule, so the `V-CORE-01..07` range label repeated in every entity section stays untouched and no cascade sweep is owed. The empirical basis is that every dual-key worked example in the corpus already satisfies identity, with no counter-example; what was missing was the contract, not the conformance.

**D4 — Reference resolution: one chain, one condition, one admissible spelling per position.** These rules are stated unconditionally and are mutually consistent by construction; the enforcement rows are the delivery child's to add.

- **R-REF-1 — the resolution chain for a bare `LOCAL`.** A bare `LOCAL` resolves against the referencing record's chain, in order: (1) the referencing record's **own project scope**, when it lives in one; (2) the **two singleton global tiers** — the cross-project-shared tier and the portfolio-level tier — which are instance-wide and therefore always in the chain; (3) **Project** itself, which is instance-unique by D2. A target outside that chain MUST be qualified.
- **R-REF-2 — when qualification applies.** Qualification (`PROJECT "/" LOCAL`) is **REQUIRED exactly when** the declared target is a project-scoped entity other than Project **and** the referencing record does not live in that project's scope. It is **FORBIDDEN in every other position.**
- **R-REF-3 — the corollary, stated so it cannot be read against R-REF-1.** References to Project, and to any id in the two singleton global tiers, are **never qualified**. This is not an independent rule competing with R-REF-1; it is R-REF-2's forbidden limb applied to targets that R-REF-1's chain already reaches from everywhere. The predecessor formulation omitted the global tiers from R-REF-1's chain, which made R-REF-1 demand qualification on exactly the references R-REF-3 forbids qualifying — a contradiction firing on **every bare person reference in the model**, the single largest reference class. Extending the chain to the singleton tiers removes it: a bare `owner_person_id` is in-chain, so R-REF-1 never asks it to qualify, and R-REF-3 forbids it. Worked example: a RAID row in one project citing a Person is written `ada-lovelace`, bare, from any project in the instance.
- **R-REF-4 — the TAG.** The `TAG` is **REQUIRED** on a field whose declared target set admits more than one entity type, and **FORBIDDEN** on a monomorphic field. Under tier-wide id uniqueness the tag is a **type assertion** the resolver checks against the target's `entity_type`, not a disambiguator. The tag is closed rather than left optional so that each (referencing-scope, declared-target) pair has **exactly one admissible spelling**: an optional decoration would let one referent exist as two byte-distinct values, and the platform's byte-comparison rules and string-probe tooling would read them as two referents — a silent false negative arriving precisely during the migration window D6 opens.
- **R-REF-5 — tracker row ids.** Tracker row ids take the same `BODY` production with **no TAG** (the row-id prefix already discriminates type): `<project_id>/TR-004`. This **extends the existing provenance token domain** — the `source_ref` / `source_inputs[]` domain, whose declared values already include `TR-###`, `MSG-###`, an artifact `id`-slug, and a source-file path — with a qualified alternative for cross-project citation. The rule rests on that extension and on nothing else: the predecessor formulation grounded it on a claim that tracker row ids are a "view of" entity `id`, attributed to a schema line that carries no such note, and the transcript register's `TR-###` has no entity in the roster to be a projection *of*. A row-id dialect token is a token in a governed domain; it is not an entity alias, and it does not need to be one to take a scope qualifier.
- **R-REF-6 — separators.** `/` denotes scope (containment reading), `:` denotes type. Neither can appear inside an id under the naming standard's T1 charset, so a single split is deterministic in both positions.

**D5 — The surviving FK-target convention, and the exact X-rule delta.** A reference declares its target as the target entity's **anchor key**: `<Entity>.<entity>_id` for the eight dual-key entities, `<Entity>.id` for the eleven single-key entities. Both conventions survive in their own lanes, and D3's identity rule is what makes the two spellings co-referential where both exist — which is what makes the generic `<any entity>.id` target form coherent rather than ambiguous.

Exactly **three** rules change target form:

| Rule | Change | New form |
|---|---|---|
| Cross-project-dependency `{from,to}_entity_ref` | value grammar: TAG required (polymorphic target set) + scope qualifier per R-REF-2; declaration cites `ENTITY_REF_RE` | `TAG:project-slug/local-id` for foreign project-scoped targets; `TAG:local-id` otherwise |
| Work-Item `parent_ref` | TAG required (`MIL:` / `WS:`); plus a same-project consistency clause — a Work Item's parent MUST resolve within its own project scope, so it is never qualified | `MIL:local-id` / `WS:local-id` |
| Work-Item `BELONGS_TO` rollup edge | as above, on the relationship-edge `target` value | `MIL:local-id` / `WS:local-id` |

The resource-conflict rule targeting `Project.id` is **explicitly unchanged**: D2 dissolves it rather than re-serializing it, because a Project reference is self-qualifying. One further value grammar is touched — the relationship-edge `target` admits the qualified form for a cross-project edge — and that is a value note, not a schema change. Every remaining row is unchanged in both declaration and value form. As of this record's authoring the family carried 37 rules, of which 16 bind a natural key and 14 the `.id` alias; the schema's own Person anchor note records 12 inbound person-FK rules, and an independent row census at the authoring baseline reproduced that figure exactly. A predecessor draft of this decision stated 13; the corpus and the census agree on 12, and the corrected figure is the one that stands.

**D6 — Rollout valve, bound to the measured conformance baseline.** The baseline spike closes one parameter — the **migration volume**, never the key form. Measured at survey baseline across the live instance: **7** bare-slug cross-boundary reference values out of 93 stored cross-entity reference values, and **0** pairwise Project-id collisions across 3 live project ids.

The valve reads: **non-zero volume → the grammar lands with a migration step sized by the baseline's own enumeration, and the tightened rules stay at warn level until the enumerated values are migrated.** (Had the measurement returned zero, the delivery child would have tightened immediately; had it returned unmeasured, the grammar would have landed warn-only until measured. Neither branch was taken.)

Two properties of the measurement are load-bearing for D2 and are recorded rather than assumed. First, the collision count was read **on the frontmatter basis** — the same key this record anchors the namespace root on — so the zero is a measurement of the anchor actually chosen, not of the surrogate that was rejected. Second, the baseline found the largest reference class in the instance carries person references in **NAME form with no id-form value present at all**, and that most of them resolve to nothing. That is a conformance defect the key form does not cause and does not cure; it is named here because a delivery child reading only the bare-slug count would badly under-size the reference-repair work waiting behind this grammar.

## Alternatives Considered

1. **A URI scheme (`pmo:<tier>:<project_id>:<entity>:<id>`)** — rejected on **blast-radius ceiling**. Three of its four coordinates are derivable (tier from entity type; entity from the field's declared target or from the TAG), zero occurrences of any such scheme exist in the corpus to anchor a migration, and adoption re-serializes every reference value in every live record and restates every X-rule target form — total migration cost for redundant coordinates, where an extend-seam form resolves the same defect additively. The strongest argument for it — that a URI survives external export and future tiers — is answered by the system-of-record decision that already fixed the external boundary: external keys are opaque strings outside the entity graph, so no current or planned surface consumes a self-describing internal URI, and a future tier extends `BODY` with one production instead of forcing a re-key.

2. **Promote every tier-local `id` to globally unique** — rejected on **irreversibility class**. It mutates the frozen core uniqueness semantics for all 19 entities on a surface with a large first-order consumer population, and instance-global uniqueness **is not enforceable at write** in the current architecture: L1 rules are single-record-decidable by construction and no cross-project index exists, so the invariant would be declared and unpoliced. Informal prefixing would then re-emerge ad hoc — this decision's grammar, minus its governance. **Which legs carry this elimination is stated precisely, because one leg does not:** the write-time unenforceability, the frozen-surface semantics change across all 19 entities, and the consumer blast radius are all independent of migration volume and are what kill the candidate. The fourth leg cited in an earlier draft — the cost of re-keying colliding ids and their inbound edges — **is** volume-dependent, and with the collision count now measured at zero it carries no weight; it is withdrawn from the argument rather than left standing. The bounded form of this candidate is adopted for Project alone in D2, and only as a consequence of the join-key binding.

3. **Type-tag only (`<Entity>:<id>`)** — rejected on **requirement failure**: it leaves two projects' identical local ids indistinguishable, which is the exact defect under decision. It survives as a *component* of the selected form (R-REF-4), not as the form.

4. **Anchor the qualifier on the folder-derived `Project.id`** — the predecessor draft's own position, rejected here on **governance grounds**. It borrowed the durability properties of the frontmatter join key (sole-join-key status, never-basename-derived, rename-is-supersession) for a *different* key whose own derivation rule has none of them, and left the namespace root the only key in the scheme with no binding at all. See D2. Rejecting it costs no value migration — the qualifier is a kebab slug either way — and buys the one guarantee the whole grammar rests on.

5. **Drop the redundant `<entity>_id` fields** on the entities where no inbound FK targets them — rejected: a larger frozen-field-list amendment that breaks the verbatim entity-model-to-schema transcription for zero resolution gain. D3's identity rule tames the redundancy instead of excising it.

## Consequences

The delivery child on the key-scheme milestone executes **one bounded reopening** of the frozen surface: a single Notes-cell annotation on the core `id` row recording the scope reading, an additive reference-grammar section carrying `ENTITY_REF_RE` + R-REF-1..6 + the dual-key companion rule, the three changed X-rows, and the enumerated consumer edits (the work-item referential target string, the tracker provenance token domains, the relationship-edge value note).

**The consuming edit set is larger than the predecessor design declared, by exactly one surface.** D2's seed-idempotency clause re-scopes the folder-slug derivation in the **project persistence dialect** from source-of-truth to seed-time fallback, and D2's enforcement row lands in that same dialect because it is the only surface where both `id` and `project_id` are visible. That file was previously listed as a consumer owing no edit. It owes two. This is a decision consequence, not a scope expansion of the present release — no consuming edit lands here.

**Same-scope references — the overwhelming majority of live values — never change form.** The migration set is the enumerated cross-boundary population, and the tightened rules stay at warn level until it is migrated.

**What this decision does not fix, named so it is not mistaken for fixed.** The instance's largest reference class carries person references in name form rather than id form, and most of those resolve to nothing. A grammar cannot repair a value that never carried an identifier. That work is real, it is larger than the key-form migration, and it belongs to the conformance-remediation track rather than to this decision. Likewise, four monomorphic fields are labelled `typed-ref` while their monomorphic peers are labelled `ref` — under R-REF-4 they are unaffected behaviourally, so this is recorded as an observation for the delivery child, not an edit obligation.

**A divergence scan is owed before any repair runs.** Every dual-key worked example in the corpus conforms, and the live Project ids were all read on the frontmatter basis — but no measurement has compared `id` against `<entity>_id` record-by-record on live data, nor `Project.id` against `project_id`. The divergent population is therefore *expected* empty and *known* unmeasured. The delivery child measures it before executing D3's repair procedure, because step 2 of that procedure is only correct if it runs against a known set.

External-system keys stay out of scope by construction: they are opaque strings outside the entity graph, carry no X-row, and this key form owes them nothing.

## Reversibility

**MODERATE / Confidence HIGH.** The record itself is CHEAP to revert while unconsumed — one additive file, revert the PR. Once the delivery child lands the grammar and downstream milestones build on it, reversal means re-serializing qualified values back to bare slugs and unwinding two identity bindings: days of work, no data loss, no stakeholder-visible impact. The genuinely irreversible branch was the global-promotion candidate, and this decision deliberately does not take it.

The D2 re-anchoring is CHEAP in isolation and was made *before* consumption for exactly that reason: after the delivery child ships, changing which key the qualifier embeds would touch every qualified value in the instance.

## Related ADRs

- The status-surface authority record (ADR-171) — the value-bearing-surface-versus-projection shape reused by D2 and D3, and the flip discipline this record's Status section follows.
- The partial-supersession grammar record (ADR-172) — the defined-once-cited-everywhere canonical-regex convention that D1's single grammar home follows.
- The system-of-record-per-mirrored-element record (ADR-164) — fixes the external-identity boundary, which is what lets this key form owe external systems nothing and answers the URI candidate's strongest argument.
- The instance-conformance validator record (ADR-174) — the recurring validator whose rule set will enforce the X-rows this decision re-forms; sibling record in this release.
- Amendment-class precedents for a bounded reopening of the frozen entity surface: the work-item entity record (ADR-018), the leadership-owner type-lift (ADR-040), the finding entity (ADR-044), and the project-health home (ADR-163).

## References

<!-- repo-integrity: allow-issue-ref -->
- Establishing decision card: #5836 (milestone pda-decisions-and-conformance-baseline); conformance-baseline measurement input: #5840; consuming delivery child: milestone #358.
