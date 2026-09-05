<!-- reference-durability: allow-link -->
---
title: "ADR-188 — The boundary between methodology-configurable and platform-fixed is a classification over the existing grammar, mapped to the runners that execute it"
status: Accepted (operator-ratified at the kit-content-and-defaults Stage 5 Collective Review scope-lock 2026-09-04)
date: 2026-09-04
release: kit-content-and-defaults
deciders: Stage 5 Solutioning spoke (re-spawned once; two independent Phase A6.5 adversarial passes) + operator at the Stage 5 close and the Collective Review scope-lock
tags: [type-pack, methodology-packs, configurable-fixed-boundary, placement-test, gate-coverage, named-gap, pack-validation, ADR-018, ADR-070, ADR-077, ADR-180, ADR-170]
source_observations:
  - "The type-pack meta-schema declares what a pack MAY declare across four subsections, and states no rule about which of those declarations a methodology owns versus which the platform fixes. An author therefore had no way to tell an over-reach from an under-delivery until a second methodology was authored against the boundary — which is the condition this record is written before, not after."
  - "The pack validator ships exactly 20 executable rule ids, read by syntax-tree traversal of its rule-id tuple and confirmed by the validator's own per-run rules_evaluated telemetry on 21 independent invocations. A naive PACK-[A-Z]?[0-9]+ regex over the same file yields 19 distinct ids, because it drops the one id carrying a lowercase suffix. Two correct counts over different extraction rules look exactly like one wrong count."
  - "The check-shape key `automatable` occurs 8 times in the grammar and 0 times in the validator, against live controls of 37 and 54 on adjacent tokens and a 0 specificity arm on a homoglyph. The grammar's materialization step switches on it; nothing enforces it."
  - "The per-kind `lifecycle_behavior` block IS enforced for presence: it is a member of the validator's kind-level required-field tuple, evaluated by a truthiness test. Removing the block at all three sites fires that rule with exit 1. Setting its value outside the closed 3-set validates clean. Presence and value are separate coverage questions and the corpus answers them differently."
  - "The relationship-type invariant is stated over the whole relationships object, which carries both allowed_types[] and required_edges[]. The validator reads the first (5 occurrences) and not the second (0). The same unknown type fires a rule in one key and validates clean in the other — an opposite-verdict pair on one token, over one corpus and one invocation."
  - "Neither the presence nor the format of criteria_version is enforced. It is not a member of the kind-level required-field tuple, and the semver matcher is applied once, to a different key. Removing it from all nine blocks returns exit 0 with zero findings, against a live control firing on the same corpus and the same invocation."
  - "The kit-scoped altitude rules decline to fire on archetype packs, and the exemption is deliberate, documented and self-tested: the validator carries dedicated negative arms for both rules on a role=archetype pack, under a comment stating that a rule which also fired on archetype packs would pass every positive arm while silently migrating shipped packs. A real published methodology models one grouping altitude above another, which is why the freedom exists."
  - "The deploy-time pack-conformance check runs a discrimination control before its live-corpus run, and that branch increments the issue counter outside the warn-mode gate. Across 15 shipped pack manifests there are 57 criteria tables (19 kinds x 3) carrying 12 `checks =` keys, all empty — so 45 tables omit the key entirely, including both discrimination fixtures. An array-scoped completeness rule therefore hard-fails the check on both control arms; an entry-scoped rule fires on zero entries and is trap-safe."
  - "The gate-coverage register's verdict is recomputed by extracting resolution pointers file-wide rather than table-scoped. The standard carries 26 such pointers, of which only 15 sit inside register rows. No executable anywhere counts named gaps: zero hits across 11 phrasings, against live controls of 28, 16 and 34 and a zero specificity arm."
  - "The register already contains three rows carrying an explicit named-gap marker, and none of them has an empty enforcing-gate cell. Two are the no-resolvable-runner-exists class; one is the runner-scheduled class, authored as a gap and later resolved when its detector shipped."
supersedes: none
---

# ADR-188 — The boundary between methodology-configurable and platform-fixed is a classification over the existing grammar, mapped to the runners that execute it

## Status

**Accepted.** Operator-ratified at the `kit-content-and-defaults` Stage 5 Collective Review scope-lock on 2026-09-04.

This section is a projection of the frontmatter `status:` field, which is the value-bearing surface per [`adr-schema.md`](../schemas/adr-schema.md) §3; the two are reconciled body → frontmatter, never the inverse.

**Numbering provenance — `185 → 188`.** Held **ADR-185** branch-local; renumbered to **ADR-188** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 185. In-release citations that read "ADR-185" denote this record.

## Context

A methodology pack declares kinds, fields, criteria, labels and controls. Readiness and done are the obvious configurable cases — what "ready" means is genuinely methodology-specific. But not everything is: some behaviour is platform-invariant and must not become a per-methodology knob, or every deployment becomes a bespoke fork and no cross-pack consumer can rely on anything.

The risk runs in both directions, and neither failure is visible until a second methodology is authored against the boundary. That is why the boundary is decided **before** the remaining archetype packs rather than after them.

Two options were live, and the second is invalid on evidence a reader will not have:

- **(A) Classify over the existing grammar, cite the existing runners.** The boundary extends the meta-schema with a classification section; invariant ids are local to that section and cite existing `PACK-*` rule ids; invariants no rule enforces are registered as named gaps.
- **(B) Mint a `PACK-C*` criteria-content rule family** so every classified invariant has an id of its own.

**(B) is rejected.** An id earned by a table rather than by a runner is a gate that cannot fail — the exact class this milestone lineage is paying to close. The validator already applies this rule to itself: one of its rules carries a code comment recording that a specified predicate was **refused** because no field carries its input. Minting ids for rules nothing executes would re-commit that error at scale.

A third option — a dedicated sibling `*-boundary.md` standard — was surveyed and rejected on the corpus: the meta-schema defines itself as the grammar every type-pack conforms to, and a rule about what a pack may declare **is** grammar. A sibling file would be a second grammar home and a duplicate-source breach.

## Decision

### D1 — The boundary is a three-tier census over the existing grammar

**T-I Shape** (the platform fixes which keys exist and are required; the pack chooses the values) · **T-II Domain** (the platform fixes the admissible set; the pack chooses the member) · **T-III Content** (the platform fixes **nothing**; no runner exists). `criteria` is required-present and its interior is unread.

The load-bearing refinement is that **the enforced unit is the `criteria` object, never its three named members**: the covering rule's predicate is a truthiness test over a kind-level required-field tuple, so removing all three sub-objects fires it while renaming one away does not. A name census cannot see that distinction; a falsification arm can, and did.

### D2 — Six invariants (F1–F6), each with its reason **and its falsification test**

F1 entity identity · F2 read-by-name keys (the join surface) · F3 aggregation contracts · F4 firing-not-asserting · F5 layer scope closure · F6 neutrality of the kit axis.

**Every row carries a falsification test that was executed**, not described. F5's cell records **by-construction** rather than covered, because there is no key to tamper with and therefore no arm to run — a distinction the column exists to preserve.

**Restoring this column is the decision, not a formatting choice.** An earlier pass of this design dropped it and filled its coverage cells from a token census of the validator's source instead. Four errors followed, and the column is the mechanism that would have obliged the author to introduce each defect and observe the verdict. It is retained for that reason.

### D3 — The placement test is an ordered first-YES sequent with two three-armed counter-tests

Q1 identity → Q2 join → Q3 aggregation → Q4 firing; first YES wins. Q2 and Q3 each carry a **prospective** arm, because a question asked in the present indicative over the live consumer set is unanswerable for a *new* candidate, which by construction has no live consumer. Both counter-tests carry a third arm: A gains **invariant-scoped-to-a-role**, B gains **nothing-reads-it-at-all ⇒ NOT PLACED**.

**Four defect shapes are recorded here because each was observed on this test before it shipped, and the arms exist to answer them.**

| # | Defect | The arm that answers it |
|---|---|---|
| 1 | **Q2's predicate was a name-match, not a read of *this* key.** The grammar declares one key name in two facets, and the validator carries an explicit comment defending against the collision plus a self-test arm asserting the second facet must **not** reach a verdict. A citation could therefore be correct and still be about a different key — or be evidence of deliberate **non**-consumption | Q2 gains a **facet clause** (cite the table or section whose key it reads) and a **self-test exclusion** (an arm asserting the key must NOT reach a verdict is not a consumer) |
| 2 | **Q3 was repaired on its object, not its tense or its domain-closure presupposition.** Q3 assumed a closed domain; this grammar's default posture for extensible sets is OPEN, so Q3 was unanswerable on the class the platform prefers | Q3 gains the **prospective arm** verbatim from Q2 and an explicit **OPEN-domain arm** (`Q3 is N/A`; the candidate proceeds to Q4 carrying its flag) |
| 3 | **Coverage was inherited from a rule firing on the parent object.** Two nested keys were credited to a rule whose predicate iterates the *container's* required-field tuple, which passes on any non-empty container | Each F/C cell naming a rule was re-run with the removal arm on **the exact key the row governs**, never on its parent. Two cells changed as a result |
| 4 | **Counter-test A's output was binary while its own worked example produced a third value.** Its shipped-corpus instance is an invariant that is fixed for kits and free for archetypes — *invariant, scoped to a role* — for which A had no arm | A gains the **scoping arm**: name the scope **and the self-test arm that asserts the exemption** |

**Scope note carried into the section itself:** the test places a **new** candidate. Applied retrospectively to a key the grammar already declares it is **diagnostic**, and a NOT PLACED result there is a coverage finding for the register rather than a re-placement.

### D4 — Content home: the boundary extends the meta-schema; it is not a new standard file

The section lands in the meta-schema after §1.4, anchored, and is mirrored as a **pointer** from the packs README — the pointer form that file already applies to the grammar itself. The three named gaps land in the gate-coverage register.

### D5 — Three named gaps, and their runner is NOT the pack validator

F2 (check shape + the three sub-objects), F3 (`required_edges[]`), F4 (the `lifecycle_behavior` value + the readiness/done `condition` prohibition). All three are class 3-O prose-declared normative predicates.

**They are not closed in this release, and the reason is mechanical.** The runner must be **entry-scoped**; an **array-scoped** rule fires on every criteria table that omits the `checks` key — the large majority of the shipped population, including both of the deploy-time conformance check's discrimination fixtures — and that branch increments the issue counter **outside** the warn-mode gate, so it hard-fails on both control arms. **Derive the population rather than reading a number here** (it grows with every pack): count `^\[kinds\.criteria\.(readiness|done|gate)\]` blocks against `^checks\s*=` keys across every tracked `pack.toml` under `core/packs/` and `core/deploy/tests/fixtures/packs/`; the tables-minus-keys difference is the array-scoped rule's firing set, and the release plan for this milestone records the reading taken at its baseline pin. The runner is therefore the pack/kit content-completeness lint over the live pack root, in a later milestone.

**The register rows are authored on the runner-scheduled row form, not on the no-resolvable-runner-exists form and not as empty cells.** The register's shipped named-gap rows are the authority for that form: none has an empty enforcing-gate cell, and one is the worked precedent of a row authored as a gap and resolved when its detector shipped — which is exactly F2/F3/F4's trajectory. Copying the no-runner-can-exist marker would ship a **false** claim, since a resolvable runner demonstrably can exist and this record specifies it.

### D6 — The kit/archetype asymmetry is a deliberate Counter-test-A outcome, recorded as such

Two altitude rules are guarded `role == "kit"` and decline to fire on archetype packs. That is not a gap. The validator carries a dedicated negative arm for each on a `role = "archetype"` pack, under a comment stating that a rule which also fired on archetype packs would pass every positive arm while silently migrating shipped packs — and the paired control confirms the identical mutation on a **kit** fires. The platform declined to widen a rule because a real published methodology's practice needs the freedom. **The register ships 3 gaps, not 4.**

## Placement-test results — both candidate sets, each with its denominator

**Two independent sets were run, and both are reported.** Reporting only the design's own set is not acceptance evidence: a set assembled to exercise the repairs and a set assembled to exercise the declared input class measure different things, and **two correct results over different denominators look exactly like one wrong result** unless both are stated.

### Set 1 — the design's own eight (denominator 8)

| # | Candidate | Verdict under the repaired test | Against the design's own placement |
|---|---|---|---|
| 1 | `base` | Q1 YES ⇒ **FIXED (F1)** | matches |
| 2 | `criteria_version` **value** | key already F2; the value is a value inside a declared key, so B arm 3's carve-out does not reach it ⇒ **CONFIGURABLE (C3)** | matches |
| 3 | a new DoR check on a Scrum `story` | member inside `checks[]`; carve-out applies ⇒ **CONFIGURABLE (C1)** | matches |
| 4 | `lifecycle` value domain | Q4 YES ⇒ **FIXED (F4), project-owned**. **Derivation corrected:** the design reached this at Q2 by citing the project-side schema's validation rule, which under the new facet clause is a *different key of the same name* — the same verdict now rests on Q4 instead | matches (verdict); derivation corrected |
| 5 | `source` | Q2 YES (b) ⇒ **FIXED key (F2), PROVISIONAL**; value configurable | matches |
| 6 | `[[controls]] value_domain.type` | Q2 NO both ⇒ flag. Q3's YES rested on a filter over materialized properties that no shipped materializer emits, and no open tracked work item ships one ⇒ **Q3 NO**. Q4 NO ⇒ **B arm 3 ⇒ NOT PLACED**, registered under C8's gap | **CHANGED** — the design placed it FIXED domain (F3) with a named gap. The repaired Q3 is stricter about what may be called FIXED with no consumer. Both readings agree a gap exists; they disagree on whether an unread key may be called fixed |
| 7 | `[meta].schema_version` | Q1–Q4 all NO with the flag ⇒ **B arm 3 ⇒ NOT PLACED** | matches |
| 8 | `required_edges[]` membership | Q2 NO ⇒ flag; Q3 YES on the shipped tree (the 7-type set is what the cross-kind rollup traverses) ⇒ **FIXED domain (F3)**, subset configurable, **with a named gap** | matches |

**Result: 8 of 8 place determinately. 7 of 8 match the design's placement; 1 changes (candidate 6), and the change is the repair working rather than a regression.**

### Set 2 — the adversarial reviewer's eight, built to the declared input class (denominator 8)

This set placed **2 of 8** against the pre-repair test. It is re-run here unchanged.

| # | Candidate | Verdict under the repaired test | Which arm resolved it | Was |
|---|---|---|---|---|
| **M1** | `materialization.enforcement_mode` value domain | **NOT PLACED**, registered | Q3's prospective arm requires a **named, tracked** consumer; this one's owner is closed as not-planned, and a withdrawn specification is not a specification | AMBIGUOUS |
| **M2** | `[[controls]].applies_to` | **NOT PLACED**, registered under C8's gap | Q2's **facet clause** excludes the cited reads — they resolve a same-named key in the header facet — and the **self-test exclusion** excludes the arm asserting the control facet must not reach the verdict | BREAK (FIXED on a citation about a different key) |
| **M3** | `[[controls]].control_id` | **NOT PLACED**, registered | Q2's **self-test exclusion**: its only executable occurrence is a fixture arm whose assertion is **non**-consumption | BREAK (a citation satisfiable by evidence of deliberate non-consumption) |
| **M4** | `criteria_version` presence **and** format | **NOT PLACED as a new candidate**; diagnostically, a grammar-declared key with no runner on either limb ⇒ C3's cell and F2's register row | The **scope note** (D3) separates the diagnostic use from the constitutive one; the coverage claim itself was corrected by re-running the removal arm on the exact key | BREAK (the table said FIXED and credited a rule that does not read it) |
| **M5** | `kit_class` value domain | **FIXED key (F2)**; domain declared OPEN, so membership is configurable | Q2 YES (a) places the key at first-YES; Q3's **OPEN-domain arm** makes the domain question `N/A` instead of unanswerable | BREAK (Q3 unanswerable on an OPEN domain) |
| **M6** | `methodology_projection.level_role` | **FIXED (F2 key, F3 closed domain)** | Q2 YES (a), Q3 YES — unchanged | CLEAN |
| **M7** | `[[labels]].projects_kind` | **FIXED key (F2)**, value configurable | Q2 YES (a) — unchanged | CLEAN |
| **M8** | `checks[].id` uniqueness within a kind's check set | **NOT PLACED**, registered | B arm 3's carve-out now states **how far up to walk** — to the nearest enclosing key the grammar declares, which is `checks[]`, whose consumer set is empty — so the flag propagates instead of terminating | BREAK (the carve-out was silent on the walk, so the candidate could never reach arm 3) |

**Result: 8 of 8 place determinately, from 2 of 8. Five breaks and the one ambiguity all resolve, each to a named arm rather than to a judgement call.**

**The honest residual:** the repaired test has not faced an independent attacker. Two adversarial passes ran against the *design*; Dev Testing and acceptance grade the *implementation*. If completion condition 4 is later found weak in use, this is the record of the decision that let it through.

## Consequences

**Positive.** An author placing a new field has an ordered test with citable evidence and a written record of what the answer must look like. Three invariants the platform states and does not enforce are now countable rather than invisible, each with a declared observable and an executed falsification arm. No new rule id is minted, so the reachable verdict set of the deploy-time conformance check is unchanged and no new gate can fail vacuously.

**Negative, and stated rather than smoothed.** Three of six fixed rows ship unenforced, so the fixed surface is partly declared-not-executed until the content lint lands. The deploy-time conformance check is warn-mode, so any fixed-surface claim reading as *"enforced"* is over-stated until that flip — recorded in the section's own posture column. And the boundary's own conformance is reviewer-read: nothing mechanically compares the classification to the validator, which is why the falsification column exists — drift is detectable by **executing one column** rather than by diffing two documents.

**Neutral.** The register's verdict is unchanged. Its resolution-pointer count is 26 before and after, because a named-gap row correctly carries none; the rows buy **register-anchoring and discoverability, which are review-time properties**, and no computed count moves. That is stated narrowly on purpose: an earlier pass claimed the rows would raise a named-gap count, and no executable anywhere counts named gaps.

## Alternatives Considered

| Option | Why not |
|---|---|
| Mint a `PACK-C*` criteria-content rule family | An id with no runner is a gate that cannot fail. The validator already refused a specified predicate on this exact ground |
| A dedicated sibling `*-boundary.md` standard | A rule about what a pack may declare **is** grammar; a sibling file is a second grammar home and a duplicate-source breach |
| A numeric-scored placement rubric | Every placement construct surveyed in this grammar is an ordered discriminated branch with an explicit negative arm. A score cannot express the negative arm, and it would break the *which question did you answer NO to* evidence contract the content cards' acceptance depends on |
| Close the three gaps in this release by extending the pack validator | An array-scoped completeness rule hard-fails the deploy-time check on **both** of its discrimination arms. The trap is measured, not predicted |
| Leave the gaps unstated | An invariant with no enforcing surface and no register row is invisible. The register row is what makes a miss countable instead of silent |

## Reversibility

**CHEAP · confidence HIGH.** The decision is additive and documentary: one classification section appended to the type-pack meta-schema after §1.4 (D4), a pointer from the packs README in the form that file already applies to the grammar itself, and three named-gap rows in the gate-coverage register (D5). **No `PACK-C*` rule id is minted** — that is the decision, not a side effect — so the deploy-time pack-conformance check's reachable verdict set is unchanged, its discrimination arms are untouched, and no new gate can fail vacuously. No pack manifest value moves, no runner changes, no meta-schema version advances and no consumer contract narrows. Standard branch revert.

The caveat worth naming is the one D5 already records rather than a new one: a revert removes the register rows that make F2/F3/F4 countable, returning three declared-but-unenforced invariants to being **invisible** rather than merely unenforced. That is a loss of review-time visibility, not a broken gate — the correct partial state.

## Related ADRs

- [ADR-018](ADR-018-work-item-type-layer.md) — the work-item type layer whose meta-schema this boundary classifies over; D1's three-tier census is a census *of* that grammar.
- [ADR-070](ADR-070-methodology-pack-composition-grammar.md) — the methodology-pack composition grammar this record **extends rather than sits beside**; the Context's rejection of a sibling `*-boundary.md` standard rests on that record owning the grammar home.
- [ADR-077](ADR-077-cross-cutting-control-field-layer.md) — the pack-level `[[controls]]` facet whose same-named key across two facets is the collision Q2's facet clause (D3, defect 1) and candidate M2 exist to answer.
- [ADR-170](ADR-170-portfolio-framework-axis-lands-as-template-registry-subtree.md) — the portfolio-framework axis cited for F5: variability that is not work-item-type variability does not belong in the type layer.
- [ADR-180](ADR-180-work-item-kit-first-class-unit.md) — froze the kit as a first-class unit; its archetype-neutral sense of *kit* is the sense F6's neutrality invariant uses. This record is subordinate to it.
- [ADR-189](ADR-189-kit-content-provenance-key.md) — sibling record from this same release; the `source` key it makes required at two altitudes is candidate 5 of Set 1's placement run above.
- [ADR-190](ADR-190-pack-default-is-the-declared-kind-set.md) — sibling record from this same release; decides what a pack's default kind set is, over the same grammar this record classifies.

## Cross-references

- Subordinate to the kernel-discipline ADR that forbids coupling core governance to release-pipeline tooling.
- Extends the pack-composition, controls-facet and work-item-kit ADRs; the kit ADR's frozen archetype-neutral sense of *kit* is the sense F6 uses.
- Cites the portfolio-framework ADR for F5: variability that is not work-item-type variability does not belong in the type layer.
- The gate-coverage register's method, the named-gap row form, and the falsification-test requirement are owned by the gate-efficacy standard and are cited here, never redefined.
