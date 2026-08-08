<!-- reference-durability: allow-link -->
---
title: ADR-121 — Domain is a parameter of the architect role, exactly as altitude is
status: Proposed
date: 2026-08-06
release: 102-specialist-role-coverage
deciders: "Workspace owner — decision rendered 2026-08-06 at the skill-matrix decision gate; durable form authored at this release's Stage 5 Solutioning; flips to Accepted at the Stage-5 Collective Review scope-lock"
tags: [architecture, skill, role-skills, specialists, skill-boundary, decomposition-axis, security, data, reversibility-moderate]
source_observations:
  - "The decision recorded here was rendered by the operator on 2026-08-06 and is held at the operator-local skill matrix, <OPERATOR_INSTANCE_ROADMAPS_PATH>/skill-matrix.md section 5 decision 3b. This record is the durable form of an existing decision; it does not re-decide it."
  - "Three separate proposals — an enterprise architect, a security architect, and a data architect — each proposed a NEW Specialist for one point in the architecture space. The matrix's own boundary-test column marks every one of them 'not demonstrated'. The corpus's single conformant precedent, the product-owner / business-analyst split, carries the verdict 'NEW (split per the boundary test)' and names the test it passed. None of the three architect proposals does."
  - "The altitude axis was already parameterized without a decision record. The shipped architect skill states the system-versus-solution cut as 'the same design axis at different altitudes', which is a parameter, not a second role. The domain axis had no equivalent record, so each domain proposal re-litigated the boundary from scratch."
  - "Write-scope is not separable by domain. A security-architecture decision and a system-architecture decision write the identical artifact set — a design decision, a blast-radius statement, and an ADR in the same monotonic sequence — so conjunct 2 of the three-conjunct boundary test fails by construction on the domain axis, and conjunct 3 fails with it because both occupy the architect seat."
  - "Splitting an architect per domain multiplies role peers over one vocabulary. Measured on the live cross-skill trigger audit at the time of authoring: 54 skills, 1431 pairs, corpus maximum Jaccard 0.188 against a 0.201 watch floor, with architect-versus-principal-engineer the sixth-highest pair at 0.160. Two role peers phrased with a uniform ownership scaffold score 0.750 against each other — above the escalate threshold — which is the mechanism behind the recorded regression where a uniform-scaffold pass cleared every role-versus-function collision while creating five new role-versus-role collisions."
  - "The shipped architect description already claims cross-component, middleware, and data architecture, so the data domain was inside the incumbent's declared scope before any data-architect proposal was filed. This is corroboration only. The axis rule is NOT rested on that wording, because a description claim is not itself a capability."
---

# ADR-121 — Domain is a parameter of the architect role, exactly as altitude is

## Status

**Proposed.** Rendered by the operator on 2026-08-06 at the skill-matrix decision gate; this record is the durable form of that decision, authored at the Stage 5 Solutioning of the specialist-role-coverage release. It flips to **Accepted** at that release's Stage-5 Collective Review scope-lock. The flip is verified against this file's frontmatter `status:` field, never inferred from a review comment, a plan row, or milestone closure.

**Numbering.** This record's number was derived against the mainline anchor per the rule that an ADR number is allocated at authorship and bound at merge: the mainline held 119, so this record takes 120. At that instant two sibling branches held unmerged claims on 120 and one held a claim on 121. Under the rejected `max(claimed_set) + 1` reading this record would have taken 122 and landed a two-number hole on the mainline, which the contiguity gate fails as readily as a duplicate. A merge-time renumber is therefore expected and is the tooled path; a gap is not.

**Numbering provenance — `120 → 121`.** Held **ADR-120** branch-local; renumbered to **ADR-121** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 120. In-release citations that read "ADR-120" denote this record.

## Context

The platform's skill-boundary rule splits a role into more than one Specialist only when all three conjuncts hold together — distinct trigger surface **and** distinct write-scope **and** distinct primary role — and otherwise the capability belongs in the existing Specialist as a mode. The rule is settled. What was not settled is **which axes it ranges over**.

Altitude was already treated as a parameter, but only implicitly. The system architect and the principal engineer sit on the same design axis at different altitudes, and that framing is stated inside the architect skill itself rather than in any decision record. Because it was never recorded as an *axis rule*, it generalized to nothing: when three proposals arrived — an enterprise architect, a security architect, and a data architect — each was evaluated as a fresh boundary question rather than as the same question already answered one axis over.

The consequence is a proliferation pressure with no principled stopping point. Architecture has as many domains as an organization has technical concerns. If each domain warrants a Specialist, the suite grows one role per concern, every one of them named "architect", every one of them competing for the same vocabulary on the routing surface. That competition is measurable, and it has already produced a regression once: a pass that phrased role triggers with a uniform ownership scaffold cleared every role-versus-function collision and simultaneously created five new role-versus-role collisions, because the scaffold itself became the shared vocabulary.

Meanwhile the burden the boundary rule places on a NEW Specialist was going unmet in a specific way. The rule puts the burden on NEW, never on EXTEND. Each of the three proposals asserted that the test would pass; none demonstrated a conjunct. An assertion that a test will pass is not a demonstration, and its absence has to resolve somewhere — either to the default, or to a deferred question that blocks the work indefinitely.

## Decision

**Domain is a parameter of the architect role, exactly as altitude is.**

A domain-scoped architecture capability — security, data, or any future technical domain — is a **mode or dimension on the existing architect Specialist by default**, not a separate Specialist. The domain axis and the altitude axis are governed by the same rule, and that rule is the existing three-conjunct skill-boundary test.

**A split remains available, but only by demonstration.** A domain may be carved into its own Specialist when all three conjuncts are demonstrated for it — distinct trigger surface **and** distinct write-scope **and** distinct primary role. Assertion that the test would pass is not a demonstration. **Absence of a demonstration resolves to the default**, not to a deferred question: the capability lands as a mode and the proposal for a separate Specialist is closed, rather than parking the work behind an open boundary question.

**Mode-versus-parameter within the default is a method question, not a scope question.** Once a domain resolves to the default, how it is expressed on the incumbent is decided by whether it brings a distinct *method*. A domain reached by the incumbent's existing method at a different scope is a **parameter** on an existing mode; a domain whose reasoning runs a genuinely different procedure and terminates in a different output shape earns its own **mode**. The default is not a licence to ship a thin dimension: a domain that cannot be authored to the depth of the incumbent's existing modes is evidence to revisit this decision, not evidence to lower the bar.

**Scope — this decision governs the architect axis only.** It ranges over architecture roles distinguished by altitude or by technical domain. It does **not** reach engineer-role proposals, which are compared against the engineering skills on their own axis and each still owe their own three-conjunct demonstration. Nothing here discharges that burden for them.

## Alternatives Considered

| Option | Verdict | Why |
|---|---|---|
| **(A) Domain is a parameter of the architect role — this record** | **Selected** | It is the only option that applies the *existing* boundary rule rather than coining a new one, and it bounds proliferation at O(1) role peers in the number of domains. The alternative growth curve is the measured collision problem. |
| **(B) A Specialist per architecture domain** | **Rejected** | It fails the boundary rule it would have to satisfy. Write-scope is identical across domains — every architecture domain writes a design decision, a blast-radius statement, and an ADR in one shared sequence — and the primary role is identical, since all of them occupy the architect seat. Two of three conjuncts fail by construction, so this option is not merely undesirable, it is non-conformant. |
| **(C) Decide each domain case-by-case with no axis rule** | **Rejected** | The status quo. It is what produced three simultaneous proposals none of which demonstrated a conjunct, and it re-derives the same answer at every future domain while leaving each proposal free to reach a different one. |
| **(D) Extend the boundary rule with a fourth conjunct for domain** | **Rejected** | It solves a problem the rule does not have. The three conjuncts already discriminate correctly on the domain axis — they return "do not split" — so a fourth conjunct would add a test that changes no verdict, while creating a second definition of the boundary for future authors to diverge from. |

## Consequences

**Easier.** The suite gains a stopping rule for architecture-role growth: domains accrete as modes and dimensions on one skill rather than as role peers, so the routing surface stays discriminable and the number of pairs the collision gate must keep apart grows with roles rather than with domains. The three superseded proposals resolve by rule rather than by re-litigation, and a future domain proposal has a recorded answer to start from. The burden on NEW is now enforceable in a specific way: a proposal that asserts the test will pass is now visibly incomplete rather than arguably sufficient.

**Harder, stated plainly.** **This decision trades Specialist proliferation for incumbent breadth**, and the trade is real, not notional. One skill now carries the architecture space across altitudes and domains; its body grows, its trigger set grows, and its mode set grows.

**The flagged risk is security.** Threat modeling has a genuinely different *method* from cross-component design even where the two overlap in scope — it reasons from adversary goals inward through trust boundaries and terminates in a control set and a residual-risk statement, rather than reasoning from coupling cost outward to a topology. It is therefore the dimension most likely to be under-served if expressed as a thin parameter. **The disconfirming test is explicit: if the security dimension cannot be authored to the same depth as the incumbent's general-architecture modes, that is evidence for revisiting this decision — not permission to ship a thin mode.** The remedy available inside this decision is the mode-versus-parameter clause above: a domain with a distinct method takes a full mode. Reaching for that clause is conformance; skipping it and shipping a sentence is the failure this paragraph exists to make visible.

**A second-order effect worth naming.** Because the default resolves silently, a genuinely separable domain could be absorbed as a mode simply because nobody did the work to demonstrate the conjuncts. That is the intended asymmetry — the burden sits on NEW — but it means the mode boundary should be revisited when a dimension's trigger set, write-scope, or output contract visibly diverges from its host's, rather than treated as settled forever by this record.

**Not changed.** The three-conjunct boundary test is unchanged, not relaxed. The compose-not-absorb discipline is unchanged: a domain expressed as a mode still reaches the function-skills it needs by invoking them. No existing skill is retired, and no engineer-role proposal is affected.

## Reversibility

**MODERATE / Confidence HIGH.** The decision is cheap to reverse **now** and materially harder **later**, and the crossing point is a shipped dimension.

Pre-ship, this is a rule in a text file: reversing it re-opens three closed proposals and changes what a future author is told to do, and nothing else. Once a domain dimension ships, its **trigger surface is claimed** — the routing vocabulary is live, the registry row and the consultation map name the mode, the packaged skill carries it, and extracting the dimension into its own Specialist becomes a cross-reference sweep across the skill body, its reference files, the registry, the consultation map, and the packaged artifact, plus a fresh collision audit over the newly-separated pair.

The two halves unwind at different costs, and the distinction is the honest one. The **axis rule** is CHEAP to supersede at any time — superseding it does not un-ship anything, it changes the default for the next domain. The **absorbed dimensions** are MODERATE once shipped, for the sweep reason above. Reverting the rule while leaving the dimensions in place is coherent and is what a partial reversal would look like in practice; reverting the dimensions while keeping the rule is not, because the rule is what put them there.

## Related ADRs

- [ADR-019](ADR-019-specialists-compose-not-absorb.md) — Specialists compose, not absorb. The direct parent: this record does not modify the three-conjunct boundary test, it records which axes that test ranges over. Every clause above is an application of ADR-019, never an amendment to it.
- [ADR-044](ADR-044-skill-output-ownership-model.md) — skill-output ownership. Load-bearing on the default: because a domain dimension produces renderings rather than owning a data entity, absorbing a domain adds no second Maintainer and cannot violate invariant I1 or I3. A domain split into its own Specialist would have to re-run that reconciliation; a mode does not.
- [ADR-114](ADR-114-composition-aware-trigger-collision-gate.md) — the composition-aware trigger-collision gate. The enforcement surface for this record's proliferation argument: it is the check that scores role pairs, and it is why a domain-anchored dimension is safer than a domain-named peer.
- [ADR-038](ADR-038-registry-as-cmdb.md) — the registry as skill CMDB. A domain absorbed as a mode edits one existing CI row; a domain split into a Specialist appends a new one and a new routing target. This record's default is the one that leaves the catalog's cardinality alone.
- [ADR-094](../../release/ADRs/ADR-094-extend-before-create.md) — extend before create. The general form of this record's default, on a different trigger: that record governs any infrastructure surface where existing infrastructure plausibly covers the capability; this one settles the specific axis question for architecture roles, where the covering surface is a role rather than a file.
- [ADR-115](../../release/ADRs/ADR-115-adr-number-claim-binds-at-merge.md) — an ADR number is allocated at authorship and bound at merge. Cited for this record's own numbering, recorded in § Status.
