<!-- reference-durability: allow-link -->
---
title: ADR-121 — The unconfigured-adapter status fallback is K1 while the adapter binding stays K4, and the card ships that one rule because the defect is binding rather than authorship
status: Proposed — flips to Accepted when the operator ratifies it at the release close gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure.
date: 2026-08-07
release: methodology-fields-and-statuses
deciders: "Workspace owner (scope and grading ratified at the Stage-5 wave-2 gate; the knowledge-tier placement resolved at the same gate); designed at Stage 5 Solutioning, authored at Stage 6 Engineering"
tags: [architecture, knowledge-architecture, adapters, work-item, lifecycle, methodology-packs, schema, plug-and-play, single-source-of-truth, reversibility-cheap]
source_observations:
  - "The originating card claimed three absences. Two were falsified by probe. The advance obligation exists at core/standards/entity-lifecycle-protocol.md §3.10 as a transition table carrying a Triggering agent and a Qualifying evidence column for every edge of the base machine, with delivery-engine named on all five intermediate rows. The read surface exists at core/schemas/work-item-type-schema.md §4 as a two-step rollup, and core/disciplines/project-entity-model.md names its three reader skills. Only the configured-versus-unconfigured adapter duality survived."
  - "An earlier correction cited five surfaces as the advance obligation. All five write the release-pipeline status label, not the entity's lifecycle_state field — they are the other axis. Reaching the right verdict through the wrong axis is the exact conflation this release exists to end, and it is recorded here so the citation is not re-made."
  - "A whole-corpus sweep for an unconfigured-adapter rule returned two general statements and zero status-specific ones. Its sensitivity arm recovered the known general rule; its specificity arm returned zero against a non-empty input confirmed to carry the near-miss kind fallback, so the absence is real rather than an empty extraction."
  - "A K1 tracked standard already reads the operator-local adapter config and defines the unconfigured outcome itself — poll only adapters that are configured and reachable; an unconfigured or unreachable one is a recorded skipped run-record outcome, never a hard failure. The contract-in-K1 / config-in-K4 split is live precedent, not invention."
  - "A second K1 record states the constraints a future corpus-home adapter must honour while stating in its own text that it defines no adapter and no selector. That is precisely the object distinction the meta-schema's adapter line leaves open: an adapter, and a constraint on adapters."
  - "The meta-schema already owns the structurally identical fallback one axis over. When a kind is unresolvable, a consumer emits a generic Work Item treatment WITH an explicit caveat, and never silently substitutes a default kind. Homing the status fallback elsewhere would split a symmetric pair across knowledge tiers."
  - "The meta-schema's own propagation section states that teaching each reader skill to read the registry instead of its hardcoded vocabulary is a separate refit slice and is not in that document. A per-consumer probe found one of the five named consumers repointed. The consumer named as the sole obligated advancer of the base machine carries no reference to the lifecycle_state field anywhere in its own definition, while owning the readiness and done gates the transition table cites as its qualifying evidence."
  - "The card's own acceptance criteria were mutually unsatisfiable. One required an altitude row for a grouping label that two ratified surfaces state is not a hierarchy level and that one shipped archetype pack does not declare at all; another forbade hardcoded kinds. Honouring the first violates the second."
---

# ADR-121 — The unconfigured-adapter status fallback is K1 while the adapter binding stays K4, and the card ships that one rule because the defect is binding rather than authorship

## Status

**Proposed** — flips to **Accepted** when the operator ratifies it at the release close gate. Authored at Stage 6 per the Stage-6 ADR-authoring precedent. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Numbering.** This record's number is `anchor(mainline) + 1` where the mainline anchor already includes this release's first record, derived at build time per the rule ADR-115 ratifies. At that moment three sibling branches held unmerged claims on the number below this one and one of them also held this one. Those claims are **advisory** and do not bind the sequence. A reservation strictly above them was considered and rejected on ADR-115's own ground: it lands a multi-number hole, and the contiguity gate fails a gap exactly as readily as a duplicate — a duplicate inconveniences one branch, a gap blocks the repository. The rejection was verified against the enforcing gate rather than argued from the document, with four arms: baseline **PASS** (the probe is not stuck red), the reserved slot **FAIL — GAP** naming the number it skipped, this number **PASS**, and a deliberate duplicate **FAIL — DUPLICATE**, which is what makes the subject's PASS meaningful rather than gap-blind. If a sibling merges first, this record renumbers at merge time by the sanctioned tool and this section gains a numbering-provenance note.

## Context

The platform ships a generic Axis-1 delivery state machine at the entity layer, and an operator still cannot say where a given work item is without issue archaeology. The originating card read that symptom as three absences — nobody advances the state, nothing defines what happens when no platform adapter is configured, and there is no defined way to read the state back — and proposed a new corpus contract document covering all three.

**Two of the three were falsified.** The advance obligation is already transcribed as a transition table with a *triggering agent* column and a *qualifying evidence* column on every edge of the base machine, naming one skill as the maintainer throughout. The read surface is already specified in the meta-schema as a two-step rollup — one kind-agnostic parent-edge traversal, then a group-by-discriminator projection — with its consuming skill named, and the entity model names the three reader skills besides. A new contract document would have restated an obligation the corpus already carries on multiple surfaces, and every restatement is a drift target that outlives the release which wrote it.

**One survived.** The meta-schema binds a kind's state to a host system through an operator-local adapter, and states plainly that the adapter expression is not committed to this corpus. It does not say what a consumer does when **no** adapter is configured. A whole-corpus sweep for such a rule found general statements about unreachable adapters in other subsystems and nothing status-specific, on a probe whose sensitivity arm recovered the known general rule and whose specificity arm returned zero against a non-empty input carrying the near-miss.

**And the defect is neither.** The meta-schema's own propagation section already declares that teaching each reader skill to read the type registry instead of its hardcoded vocabulary is a separate refit slice held outside that document. That refit has not shipped. The skill the transition table names as the sole obligated advancer references the entity's Axis-1 field nowhere in its own definition, while owning the readiness and done gates the table cites as its qualifying evidence. **The contract names an actor that does not know it is the actor.** That is a *binding* failure, not an authorship one, and no amount of further authorship moves it.

Two questions therefore had to be settled before anything could be written: which knowledge tier the surviving rule belongs to, and whether this release should absorb the refit that would actually move the symptom.

## Decision

**(1) The unconfigured-adapter status fallback is a K1 contract; the adapter binding stays K4.**

The rule lives in the meta-schema as a new peer subsection stating a two-path duality. When an adapter is configured, a consumer resolves the item's Axis-1 state through the adapter, and this grammar states no host vocabulary and names no host field. When none is configured, the consumer maintains and reads the entity's own Axis-1 field directly — under the actor and the qualifying evidence the entity-lifecycle protocol already names for every transition — and **emits an explicit caveat naming the unresolved binding**. It never infers a state, never substitutes a host vocabulary, and never reads *no adapter configured* as *no status*.

**The decisive argument is that the unconfigured path is exactly the path on which the K4 artifact is absent.** A rule homed in an absent file cannot state the rule for its own absence. Homing the fallback operator-locally would leave the one case it exists to govern ungoverned in precisely the deployments that hit it.

This **does not re-decide** the meta-schema's adapter line, which remains unchanged. That line places the *adapter expression* in K4. An adapter and a constraint on adapters are different objects, and the corpus already separates them: one K1 standard reads the operator-local adapter config and defines the unconfigured outcome itself, and a second K1 record states the constraints a future adapter must honour while saying in its own text that it defines no adapter and no selector. The seam test agrees — K1 is the universal shape, K4 is the instance selection, and *what a consumer does when nothing is configured* must hold for every deployment including one with zero adapters.

**(2) The rule is stated over the resolved pack's declared kinds, never over a kind list.**

The subsection names no kind, no archetype, and no state literal. A consumer reads the resolved pack's declared kinds and each kind's state-machine field, so the rule holds byte-unchanged across every archetype pack — those shipped today and those not yet built. This is the same defence the meta-schema already states against hardcoded kind branching, applied to the status axis.

The same property holds against this release's own first card. The subsection references no label row, no label group, and no state literal, so a later change to the label grammar requires **zero** edits here. The dependency between the two cards is **parameterized, not coupled** — a sequencing fact, not a shared surface.

**(3) The read surface is cited, not restated — and it is one traversal with two projections, not a table of altitudes.**

The card asked for a read procedure covering leaf, epic and initiative altitude. That framing draws from three different taxonomies and inverts the entity graph. *Epic* is a **kind**, not a level: one shipped archetype pack declares it at the same general level as its other kinds and the other does not declare it at all, and a ratified framework states in its own words that such grouping labels are not hierarchy levels. *Initiative* is a **label grouping** with no parent edge to traverse, and a ratified decision record excludes it as a level by name. Meanwhile the level the card marked out of scope is the canonical rollup target.

An epic altitude row would therefore hardcode one methodology's kind into the neutral toolkit — **directly contradicting the card's own criterion forbidding hardcoded kinds.** The two criteria were mutually unsatisfiable as written. The corpus-canonical model is the one already specified: **one kind-agnostic traversal, plus two projections** — a kind filter and a label filter. The criteria are graded against that, satisfied by intent.

**(4) The propagation refit is routed, not absorbed — and the symptom does not change this release.**

Binding the named consumers to the field is out of this release's file change matrix: it is a skill-definition change, each edit carries its own editing discipline plus a package rebuild and a content-baseline sidecar in the same pull request, and it exposes a package-drift gate this release does not otherwise touch. It routes as a follow-on.

The consequence is stated plainly rather than papered over: **shipping this rule does not change what an operator sees.** A passing acceptance review must not be read as the symptom being fixed. That honesty obligation is part of the decision, not commentary on it.

## Alternatives Considered

**On what the card ships:**

| Option | Verdict | Why |
|---|---|---|
| A new standalone status-maintenance contract document | **Rejected** | It restates an obligation the corpus already carries across several surfaces, creating a permanent drift target and a competing source of truth for an actor-and-trigger table that is already frozen elsewhere. The extend-over-new bar is *necessary*, not *plausible*, and a new file did not clear it. |
| Extend the entity-lifecycle protocol's transition table instead | **Rejected** | That document states in its own opening that it is transcription rather than design, and that any change requires reopening its establishing issue as a scope change. Adding a design rule there breaches a declared freeze to save one file hop. |
| Ship nothing; route the whole card | **Rejected** | The fallback is a real, probe-confirmed absence with a live consequence. Routing everything would under-deliver against the one thing the card got right. |
| **Extend the meta-schema with the fallback only, cite the rest, and route the refit** | **SELECTED** | Puts the one absent rule in the file that *creates* the gap and that already carries the structurally identical fallback one axis over. Everything else the card asked for resolves to a citation. |

**On the knowledge tier:**

| Option | Verdict | Why |
|---|---|---|
| Home the fallback operator-locally, as the card's reading of the adapter line suggests | **Rejected — fatally** | The unconfigured case is the case where the operator-local artifact does not exist. The rule would be unreachable in exactly the deployments it governs. |
| **K1 contract, K4 binding** | **SELECTED** | Two live precedents already split this way, and the meta-schema already owns the symmetric kind fallback in K1. Splitting a symmetric pair across tiers would be the anomaly. |
| Split it — abstract rule in K1, resolution order operator-local | **Rejected** | Adds a seam for no benefit. The resolution order *is* the universal rule, and the fatal objection above applies to the operator-local half. |

**On the altitude model:**

| Option | Verdict | Why |
|---|---|---|
| Grade the altitude criterion literally, as written | **Rejected** | It canonicalizes a category error and ships a methodology-specific kind into the neutral toolkit, breaking the sibling criterion in the same card. |
| **Regrade to one traversal plus two projections** | **SELECTED** | Satisfies the read-surface intent using the model the corpus already specifies, and keeps the toolkit methodology-neutral. |

## Consequences

**Easier.** A deployment with no adapter now has a stated behaviour instead of an undefined one, and it is the *loud* behaviour: an explicit caveat rather than a silent default, matching the discipline the same file already applies when a kind cannot be resolved. The adapter seam gains a constraint it can be held to before any adapter exists, which is the cheap moment to state it. And the corpus gains one fewer candidate site for a seventh restatement of the advance obligation.

**Harder, stated plainly.** **This decision does not change the operator-visible symptom.** The state machine still has no bound writer, because the skill the corpus names as its maintainer still does not reference the field. Anyone reading a green acceptance review as *status now works* will be wrong, and this record exists partly so that misreading has somewhere to be corrected. The remaining work is a skill-binding refit, routed as a follow-on with its own package-rebuild and drift-gate obligations.

**A second-order effect worth naming.** Two cards in this release resolve to the same diagnosis — **specification without binding**. One found a state machine whose named advancer is unwired; the other found a label declaration with no materializer. That the shape recurs across independently-filed cards is a signal about the corpus rather than about either card: the platform specifies obligations without a gate that verifies an actor is wired to them. It is recorded here as an observation, not legislated into a rule by this record.

**Not changed.** The adapter line stays K4. The condition-construct arms, their disjointness clause, and the kind-fallback caveat are untouched. No section is renumbered, no meta-schema version bumps — a new peer subsection is neither a new required field nor a change to the criteria structure, which is what the bump rule names as its trigger. No pack file, no skill file, and no deploy tooling is edited.

## Reversibility

**CHEAP.** Confidence **HIGH**.

Two markdown surfaces: one new peer subsection plus one appended cross-reference row in an existing schema, and this record. No file is renamed, moved, or deleted; no heading is removed; no existing prose is rewritten; no code path changes; no schema version bumps; no skill package rebuilds. A single revert of the merge restores both surfaces, and nothing outside the repository acquires state as a result of this decision — unlike the sibling card in the same release, whose live-label creation a revert cannot undo.

The one asymmetry worth naming is temporal rather than technical: once the routed refit binds the named consumers to the field, reverting *this* record would strip the fallback rule out from under a binding that then assumes it. Reverting both together stays CHEAP; reverting this one alone after the refit lands would be MODERATE. The ordering constraint is stated here so it is a known dependency rather than a discovered one.

## Related ADRs

| ADR | Relationship |
|---|---|
| **ADR-018** | The establishing work-item-type decision — the thin entity plus declarative type layer, and the kernel discipline that this grammar must not depend on release-pipeline tooling. The cited entity-lifecycle surface is intra-core, so the delegation in Decision (1) honours that discipline rather than testing it. |
| **ADR-069** | The methodology pack as the plug-and-play composing unit. Decision (2)'s parameterization is stated over the pack's declared kinds precisely because the pack is the composing unit. |
| **ADR-070** | The pack composition grammar. Its work-status projection over the entity base is the layer this fallback governs the *resolution* of; this record adds a constraint on adapters and re-founds nothing. |
| **ADR-077** | The cross-cutting control layer, whose adapter-expression posture Decision (1) mirrors: the value domain is declared in the grammar, the host expression is operator-local. |
| **ADR-115** | The ADR-number binding rule this record's numbering follows, and whose rejection of reserving a slot above unmerged sibling claims this record's § Status applies and verifies against the gate. |
| **ADR-124** | This release's first record, the Axis-1 label surface. Decision (2) states the relationship deliberately: the dependency is parameterized, not coupled — this record references none of that record's label rows, groups, or state literals. |
| **ADR-062** | Canonical-spec-edit-wins. Applied here: the originating card's premises were superseded by live state at design time, and its body was left as historical record rather than amended. |
| **ADR-092** | The version-identity decision governing the release this record ships in — slug-primary in flight, version bound at the atomic claim. |
