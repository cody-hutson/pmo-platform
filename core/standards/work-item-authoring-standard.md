---
title: Work-Item Authoring Standard
purpose: States what good looks like for an authored work item of any kind — the three dimensions its bar is read along, the ordered procedure that assigns a declaration to one of them, and the enforceability each dimension currently carries — naming no kind, so a kit declaring a seventh archetype adds no rule here.
type: standard
status: ACTIVE
reversibility: MODERATE (pre-consumption a revert restores the tree exactly; EXPENSIVE once the elicitation and gate consumers cite it and the reading becomes a contract — the crossing the methodology-pack composing-unit ADR names on this surface) / Confidence HIGH
consumers: authors of a methodology type-pack manifest; the intake elicitation loop, which elicits to a resolved kit's depth; the readiness and done gates, which evaluate a resolved kit's criteria; reviewers grading an authored kind's bar
composes_with: gate-efficacy-standard.md, work-item-type-schema.md, intake-style-guide.md
domain: governance
---
<!-- reference-durability: allow-link -->
<!-- The cross-references below are load-bearing and are deliberately carried as links rather
     than as summaries: this file's whole method is "cite the owner, restate nothing", and
     core/standards/ is inside the doc-link checker's declared scan scope, so every one of
     them is resolved at deploy time and at PR time. Summarizing them inline would move
     content into a second home, which is the defect the citations exist to avoid. -->

# Work-Item Authoring Standard

An author — human or agent — writing a work item of some declared kind needs to know three things: what shape the item is expected to take, what content it must carry, and how much of it belongs at this kind's altitude rather than a neighbour's. This standard states those three dimensions, and states which already-declared parts of a type-pack manifest realize each one.

**It names no kind.** It quantifies over any kind in any resolved kit, so a kit declaring a seventh archetype adds no rule here. That is a requirement, not a stylistic preference: the public corpus stays methodology-neutral per [`ADR-069`](../ADRs/ADR-069-methodology-pack-composing-unit.md) D3, and the grammar stays archetype-invariant while the concrete rows live in the selected packs.

## 1. What this standard is, and what it is not

**This standard is a reading of declarations that already exist. It introduces no carrier.** It adds no key to the type-pack grammar, no file class to a pack directory, and no value to any shipped manifest. Every dimension below is realized by a key the per-kind meta-schema already declares.

**The bar for an item of a given kind is therefore carried in two places, and saying so is part of the standard.** This file states the dimensions and the reading; the resolved kit's `pack.toml` manifests carry the per-kind values. Neither half is the whole bar. The cleave is forced: a rule stating *this kind's depth bar is X* would have to name a kind, and naming a kind in the public corpus is what methodology-neutrality forbids. A reader who wants to know a specific kind's bar reads that kind's declarations **through** this standard; a reader who wants to know what a good bar looks like reads this standard alone.

**What this standard does not own.** The cross-kind authoring rules — over-definition, scope-altitude consistency, acceptance-criterion shape, title informativeness — are owned by [`intake-style-guide.md`](../../release/references/how-to/intake-style-guide.md) and are cited, never restated, in § 7. The grammar those manifests conform to is owned by [`work-item-type-schema.md`](../schemas/work-item-type-schema.md). Whether a check's judgment reproduces is owned by [`ADR-195`](../ADRs/ADR-195-l3-judgment-criteria-evaluability.md).

## 2. The three dimensions, and the ordered procedure that assigns a declaration to one

### 2.1 What each dimension asks, and which declared keys realize it

| Dimension | The question it asks of an authored item | Realized by these already-declared keys |
|---|---|---|
| **Expected structure** | What shape is this item expected to take — which fields exist on it, which edges it may or must carry, which states it moves through? | `fields.core` · `fields.kind_specific[]` · `relationships.allowed_types[]` and `relationships.required_edges[]` · `axis1_state_machine`; plus any `criteria.*.checks[]` entry whose `statement` asserts over a relationship type or a state |
| **Required content** | What must actually be filled in — which of the declared fields and edges must be **present and populated** before the item is usable? | any `FieldDecl` whose `required` is `✅`; plus any `criteria.*.checks[]` entry whose `statement` turns on the presence or population of something the kind declares |
| **Appropriate depth** | How much belongs **here** — what this kind decides versus what it defers to a neighbour, and whether what is declared is *adequate* rather than merely present | any `criteria.*.checks[]` entry whose `statement` bounds altitude or adequacy; plus the block-level `source` on a present-and-empty `[kinds.criteria.*]` or `[kinds.fields]` table, which states the practice basis for declaring nothing at this altitude |

### 2.2 The assignment procedure is ordered, and that is what makes it decidable

A declaration routinely satisfies more than one dimension on its face — a check asserting that a required field is populated reads as structure *and* as content. Applied as a set of named dimensions matched by inspection, the rubric yields no determinate assignment for that declaration, and independent reviewers reading one manifest produce partitions that disagree. Applied as an **ordered question**, it yields exactly one.

Take each declared element of a kind — each `checks[]` entry, each `FieldDecl`, each relationship and state-machine declaration — and ask, stopping at the first yes:

1. Does the element assert over the item's **shape** — which fields exist, which edge types are permitted or required, which states the item moves through? → **expected structure**.
2. Otherwise: does the element turn on whether a declared field or edge is **present and populated**? → **required content**.
3. Otherwise: the element bounds **how much belongs at this kind's altitude**, or asserts the **adequacy** of what is declared rather than its presence. → **appropriate depth**.

**Both precedence rules are load-bearing, and each closes a specific ambiguity.**

- **Shape precedes presence.** A declaration that asserts over shape is structure even when reading a field's presence is how it does so. Without this, every edge-asserting check is contestably content and the structure dimension collapses.
- **Presence precedes adequacy.** Where a machine-evaluable declaration tests a field's *presence*, a judgment-level declaration over that same field tests its *adequacy* — and the declared field is the **subject** of that judgment, never its resolution. That is not this standard's observation; it is a recorded finding of [`ADR-195`](../ADRs/ADR-195-l3-judgment-criteria-evaluability.md), which reached it by partitioning the shipped judgment-level set and finding the field-decidable class empty. Ordering presence ahead of adequacy is what keeps the content and depth dimensions from both claiming the same declaration.

Ordered, the procedure is **disjoint by construction**: every declared element lands in exactly one dimension, so a partition over a kind's declarations sums to that kind's declaration count and a reviewer can check that it does.

### 2.3 This standard carries no census, deliberately

A count of how many declarations of each dimension a shipped kit currently carries is a **measurement of a corpus at a moment**, not a rule. It belongs in the release record that measured it, where it is dated and re-runnable, and not in a durable standard, where it rots silently and a reader cannot tell a stale number from a current one. What is carried here instead is § 2.2's procedure — which is what lets any reader produce the census themselves, against whatever kit is resolved, and disagree with a published one.

This is the same discipline the standard applies to its own rules: state the predicate, not the point-in-time result of running it.

## 3. Appropriate depth is check-derived, and the reason is measurable

A depth test needs an altitude to test against. **No declared key expresses a kind's altitude**, and an author looking for one should stop looking rather than conclude they have missed it. Measured across the shipped manifests, with a live control arm on a key that is genuinely present:

- `methodology_projection.general_level` reads `Work Item` for every declared kind — it records that a kind projects onto the Work-Item level of the general hierarchy, which every kind does; it does not separate them.
- `base` and `axis1_state_machine` are likewise constant across the shipped kinds, the first by grammar (it is a `const`) and the second by authoring choice.
- `relationships.required_edges[]` and `methodology_projection.level_role` have **zero** instances in the shipped manifests. Both are declarable and neither is declared.
- `relationships.allowed_types[]` varies, but not reliably by altitude: two kinds at visibly different altitudes declare byte-identical sets.
- The one signal that varies with every kind is `methodology_projection.projects_as` — and that is a **name**. Reading altitude off a name is exactly what a methodology-neutral standard may not do.

**So the altitude test takes its input from the kind's own criteria checks**, and this standard says so rather than leaving a grader hunting for a key. The test an author applies:

> Read the kind's own `criteria.*.checks[]` statements, and ask what each one makes this item **responsible for deciding**. An item is at the right depth when every question its checks make it answer is a question it can answer *from its own scope*, and every question it defers is one a neighbouring declaration answers. Over-definition at this kind is a check that makes the item answer a question a narrower kind will answer better with information it does not have yet. Under-definition is a question nothing in the resolved kit answers at all.

**The consequence, stated rather than left implicit.** The test's input is the set of statements whose adequacy the test exists to assess. That is circular only if a kit is read alone; read against the body of practice each statement's `source` names, it is not — the practice, not the manifest, is what says whether a question belongs at this altitude. An author who cannot resolve a depth question from the kit plus its cited practice has found a gap in the kit, which is a finding, not a failure of the test.

**Where an altitude-expressing declaration would go if one is ever wanted:** it is a candidate for the configurable/fixed placement test in [`work-item-type-schema.md`](../schemas/work-item-type-schema.md) § 1.5.5, and it has already been run once against a key of that class. The result and its reasoning are recorded in this standard's own ADR, so a future author starts from the executed test rather than from first principles.

## 4. Reading rules

Four readings an author or reviewer needs, each stated once here and nowhere else.

### 4.1 Provenance — relied on, not restated

Every criteria-check entry and every kind-specific field declaration in a type pack carries a non-empty `source` naming the body of practice it derives from, and a present-and-empty criteria or fields table carries one at block level stating the practice basis for the emptiness. That obligation is **declared** at [`work-item-type-schema.md`](../schemas/work-item-type-schema.md) § 1.2.1 and **registered** as a named-gap row in the gate-coverage register in [`gate-efficacy-standard.md`](gate-efficacy-standard.md); it is not restated here and this standard adds no row to that register.

What it means for a reader of this standard: **the practice basis of every value you read is already on the page beside it.** A dimension assessment never has to be argued from the manifest alone.

### 4.2 A dimension of zero

A kind whose declaration count in some dimension is zero is not thereby non-conformant. Read the zero in this order:

1. Does the kind carry a **present-and-empty** criteria or fields table whose block-level `source` states the practice basis for declaring nothing there? Then the zero is **reasoned** — the practice this kind draws on prescribes nothing at that altitude, and the manifest says so at the site where nothing was declared.
2. Otherwise the zero sits **inside a populated array** — declarations exist, and none of them lands in this dimension. No `source` anywhere in the manifest speaks to that, because a block-level `source` answers *why this table is empty* and is silent about a gap inside a table that is not.

**A zero of the second shape is an accepted residual, not a reasoned zero, and it is recorded as one** — named, with its reason, in the measurement record that observed it. It is never discharged by a `source` at another altitude. Borrowing a block-level `source` to certify a gap inside a populated array is precisely the inheritance the grammar forbids in terms: a block `source` never satisfies an entry's requirement, because the two answer different questions.

### 4.3 `level` and `automatable` select different sets, and both are correct

A check's `level` and its `automatable` flag can diverge — a check can carry a level whose evidence shape the platform could in principle read, while declaring that this deployment cannot render its verdict mechanically. The divergence is a legitimate authored state, not a defect to repair:

- **`level`** states the **shape of the evidence** the check reads. Its domain is declared fixed and closed because the materialization branches on it as a switch.
- **`automatable`** states whether **this deployment can render the verdict mechanically**.

They are orthogonal, and neither determines the other at any level. **When the two diverge, read the check's `statement` for the referent the platform cannot resolve** — characteristically something instance-local that no repository read reaches, such as a team's own written-down policy. A divergence with no such referent named in the statement is the case worth raising with the pack's author.

### 4.4 `Content` is a tier of the grammar and a dimension of an item, and the two nest

`Content` is also a declared tier in the meta-schema's three-tier census, where it names the layer at which the platform fixes nothing and the pack chooses everything. The relationship is **nesting, not rivalry**: all three dimensions of this standard live inside that tier. The platform bounds none of them, and this standard is the authoring guidance for the space the configurable/fixed boundary deliberately leaves open — it is not a second, quieter bound on pack content.

## 5. Enforceability

Whether a rule instantiating one of these dimensions can *gate* — block a transition — rather than only *guide* is a measured property, and it is measured per check rather than assumed from a check's level.

**The measurement is outstanding, and this standard states that rather than omitting it.** The judgment-level evaluability verdict is recorded in [`ADR-195`](../ADRs/ADR-195-l3-judgment-criteria-evaluability.md), which is the single verdict identifier; this standard cites it and restates none of its per-check dispositions. At the baseline stamped in § 8 that record's count of gate-capable judgment-level checks is `NOT-EVALUATED` — **an absence of measurement, emphatically not a measured zero** — and that record's own routing rule names the conservative branch this standard takes while it stands.

**So every dimension here reads `unresolved pending measurement` for its judgment-level layer.** Declared and unresolved, never silently absent:

| Dimension | Machine-evaluable layer | Judgment-level layer |
|---|---|---|
| Expected structure | as declared by each check's own `automatable` flag | unresolved pending measurement |
| Required content | as declared by each check's own `automatable` flag | unresolved pending measurement |
| Appropriate depth | as declared by each check's own `automatable` flag | unresolved pending measurement |

The machine-evaluable column is deliberately a **pointer to a declaration rather than a count**: which checks a deployment can evaluate mechanically is a property of that deployment's resolved kit, readable from the kit, and a number written here would be a second copy of it.

**An unresolved enforceability layer is not a licence to leave normative predicates standing and unrun.** A per-kind rule whose enforceability is unresolved still takes a disposition — a downgrade to non-normative description, or a registered named gap carrying a declared observable. The disposition ladder and the admission test that assigns it are owned by [`gate-efficacy-standard.md`](gate-efficacy-standard.md) § Scope boundary, and the plain-language discriminator between an agent-executed and a machine-executed outcome is owned by [`intake-style-guide.md`](../../release/references/how-to/intake-style-guide.md) § 4c. Both are cited; neither is written out here, because the second is a registered two-surface prose pair and a third copy of it would be an unregistered duplicate.

## 6. Every rule in this standard carries its gate-efficacy class

Each rule's class is **computed** by applying the admission test in [`gate-efficacy-standard.md`](gate-efficacy-standard.md) § Scope boundary to the rule as written — a verdict limb, an obligation limb with a named trigger, and the prose-only limb — so a reviewer can re-run the assignment against this file's own text rather than trusting a label. No marking vocabulary is minted here.

| Rule | Class | Why the test lands there |
|---|---|---|
| § 2.2 — the ordered assignment procedure | **not admissible** | It states no verdict for a negation, and it names no moment at which an author must act. It is a method a reader applies, which is what this standard calls guidance. |
| § 3 — the depth test | **not admissible** | Same: a test an author applies to their own draft, with no verdict for its negation and no observable firing moment. |
| § 4.1 — every declaration names its practice basis | **class 3-O, cited** | The predicate is declared in the grammar and already carries a named-gap row in the gate-coverage register. This standard cites that row and adds none. |
| § 4.2 — a dimension of zero | **not admissible**, and this is a correction | A *dimension* is a reading over declarations, not a declaration site, so there is no site at which the act could land and no observable moment at which a runner could fire. The register's provenance row does **not** cover it: that row is scoped to a declaration site and to a present-and-empty array, while a dimension can read zero inside a populated array. Citing that row here would register an obligation it does not carry — which is why § 4.2 states a reading and routes the residual to the measurement record instead. |
| § 4.3 — the `level` / `automatable` divergence reading | **not admissible** | A reading rule over an authored state. No verdict, no trigger. |
| § 4.4 — the `Content` nesting | **not admissible** | A disambiguation. |
| § 5 — the enforceability branch | **cited, not minted** | The obligation that every rule declares its disposition is the gate-efficacy standard's own governing requirement, and the branch taken while the measurement stands is the evaluability record's own routing rule. Restating either as a rule of this standard would create a second home for it. |

**Zero rows and zero runner pointers are added to the gate-coverage register by this standard.** That is a consequence of the table above, not an aspiration: every rule this file states is not admissible, and a rule that is not admissible has no row to add.

## 7. Sources

This standard's rules derive from the following, each cited and none restated:

- [`work-item-type-schema.md`](../schemas/work-item-type-schema.md) — the type-pack grammar. § 1.2 declares the per-kind key set every dimension in § 2.1 is realized by; § 1.2.1 declares the content-provenance obligation § 4.1 relies on, including its no-inheritance clause; § 1.5 owns the configurable/fixed boundary § 4.4 nests inside, and § 1.5.5 owns the placement test § 3 points at.
- [`gate-efficacy-standard.md`](gate-efficacy-standard.md) — § Scope boundary owns the admission test and the disposition ladder § 6 applies; its gate-coverage register owns the provenance row § 4.1 cites.
- [`ADR-195`](../ADRs/ADR-195-l3-judgment-criteria-evaluability.md) — owns the judgment-level evaluability verdict, its measurement state, and the routing rule § 5 takes its branch from; also the presence-versus-adequacy finding § 2.2 grounds its second precedence rule on.
- [`ADR-069`](../ADRs/ADR-069-methodology-pack-composing-unit.md) — D3 owns the methodology-neutrality requirement that makes this standard name no kind; D4 owns the placement of per-kind content in the pack manifests.
- [`intake-style-guide.md`](../../release/references/how-to/intake-style-guide.md) — owns the cross-kind authoring rules this standard does not duplicate: § 4's over-definition test and § 4c's scope-altitude consistency rule with its agent-executed versus machine-executed discriminator.
- Each shipped pack manifest's own `source` values — the bodies of practice the per-kind content derives from. This standard reads them; it never re-authors them.

## 8. Measurement stamp

The measured claims in § 3 were taken against the tracked tree at `e8665feb` on 2026-09-11, over the shipped pack manifests enumerated by `core/packs/*/pack.toml`, with a control arm on a declared key that is genuinely present so a zero reads as a measured absence rather than as a dead probe. The per-dimension census those manifests currently yield is **not** recorded here, for the reason § 2.3 gives; it lives in the release record that measured it, and § 2.2 is what lets a reader reproduce it.
