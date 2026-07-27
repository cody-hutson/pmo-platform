<!-- reference-durability: allow-link -->
---
title: "ADR-098 — Portability as the seventh first-class build-philosophy value"
status: Proposed
date: 2026-07-27
release: build-philosophy-corpus
deciders: "operator (D-ValueShape rendered at Stage-4 Plan Review; value name rendered at Stage-5 Collective Review) + Stage-5 Principal Engineer design spoke + hub adversarial design review"
tags: [build-philosophy, first-class-value, portability, adapters, host-agnostic, coverage-matrix, charter-amendment, design-principle-register]
source_observations:
  - "The platform IMPLEMENTS the adapter-boundary property across the portability-distribution initiative and proves it concretely for one port, but no first-class value and no design-principle entry named it — so each new adapter card independently re-derived the same rule ('classify against the adapter-config foundation first; extend, do not duplicate')."
  - "A host-binding-leak detector and its registered leakage class already shipped before this decision was taken. It catches a leak MECHANICALLY in text it already scans; it is structurally blind to a design decision. A detector without a principle has no conformance axis to escalate against."
  - "The charter's gap-finder is structural — an empty matrix cell is a named gap, but the finder only fires for rows that EXIST. With no Portability row, a missing adapter-boundary enforcer on any surface could never surface as an empty cell."
  - "The term originally proposed for this value had zero occurrences in the corpus and would have been coined by this decision, while the corpus already names the same quality in an existing ADR's consequences ('Portability — the capability survives a host change') and in the leak class's own canonical rule ('defeating the portability the adapter seam exists to provide')."
---

# ADR-098 — Portability as the seventh first-class build-philosophy value

## Status

**Proposed.** Authored at Engineering alongside the charter amendment it records. Ratified by the operator at the Collective Review scope-lock, at which point this status flips to **Accepted**. The deciding gates already ran — D-ValueShape (value-or-discipline shape) was rendered at Plan Review and the value's *name* was rendered at Collective Review — so this record documents decisions the operator fixed, and the deep plan review verifies implementation conformance rather than re-deciding the elevation. Status conformance is verified against this field, not against the intent stated here.

## Context

The build-philosophy charter ([`build-philosophy.md`](../disciplines/build-philosophy.md)) is a naming-and-routing spine: it names the first-class engineering values and makes their enforcement **coverage** across every toolkit surface visible in a philosophy × surface matrix, where an empty cell is a **named gap**. Its gap-finder is structural — it can only surface a missing enforcer for a value that *has a row*.

The platform already **implements** the adapter-boundary property. The governed core binds to external systems through anti-corruption adapters whose host mechanism stays inside the adapter; the config seam that selects them is codified, and the property is proved concretely for one port in the repo-host adapter standard. The platform also already **detects** the corresponding failure: a host-binding-leak class is registered in the knowledge-architecture discipline with a rubric, a worked instance, and a remediation pattern, and a deploy-time detector scans the governance and skill corpus for a host tool prescribed as *the* mechanism inside host-agnostic capability text.

What was missing is the **conformance axis**. With no value row and no design-principle entry, there was nothing for the Operator Decision Gate or acceptance review to score an adapter or external-binding option *against*. Each new port card re-derived the same rule ad hoc — the duplicate-source signal the charter's own Maintainability value exists to eliminate. The detector does not close this: it catches a leak mechanically, in text it already scans, and is structurally blind to a *design decision* that has not yet become text. A detector without a principle is a lint without a standard.

The two rungs are complementary, and naming the value is what lets them compose: the detector is the mechanical rung, the principle is the design-review rung.

## Decision

Elevate **Portability** to the **seventh first-class engineering value** in the build-philosophy charter, alongside Scalability, Best-Practice-per-Domain, Maintainability, Simplicity, Stability, and Security. Concretely:

**D1 — A first-class value row plus a full coverage-matrix row.** Portability gains a value-table entry (the governed core binds to an external system only through an adapter; the external system's model lives inside that adapter and never redefines a governed concept; host mechanism never leaks into host-agnostic capability text; litmus — *does the governed concept survive a substrate swap?*) and a philosophy × surface matrix row, so a missing adapter-boundary enforcer on any surface now surfaces as a **named GAP** the charter's gap-finder can see. The row lands with honest markings, each derived from the detector's literal scan-glob list rather than asserted: **Skills** enforced, **Agents** GAP, **Hub / Spokes** thin, **Hooks** `n/a` with rationale, **Slash-commands** GAP. It is indexed in the design-principle register as an **index-only** entry whose `scope_predicate` selects adapter, config-selector, and host-mechanism-in-capability-text changes — and explicitly routes the path-portability axis elsewhere, so the two leak axes do not double-fire on one principle.

**D2 — Introduced paired with its existing enforcer, never naming-only.** The value ships with a working detector and a conformance checklist that already exist. A value with no enforcer is a shelf document; this preserves the invariant established when Security was elevated, and is why the Skills cell reads as enforced rather than GAP.

**D3 — Home in `core/ADRs/`.** The charter is core-scoped and the value system is a platform-wide concern, not a release or SDLC decision, so this record lives in `core/ADRs/`.

**D4 — The value is named `Portability`.** The originally proposed name was a coined hyphenated compound with **zero** occurrences in the corpus. Three grounds decided against it, and they are recorded here because the naming is the part most likely to be re-litigated later:

1. **The corpus already names this quality.** An existing ADR's consequences name the property exactly — *"Portability — because the capability is host-agnostic … the capability survives a host change"* — which is the swap-survival litmus itself; and the leak class's canonical rule says a host binding *"defeat[s] the portability the adapter seam exists to provide."* The governing initiative carries the same word. Coining a second vocabulary for a quality the corpus already names is a **vocabulary fork** — precisely the duplicate-source failure the value being added is meant to model, and a self-contradiction at the moment of authoring.
2. **The rejected term is overloaded.** `substrate` already carries multiple live senses in this corpus — most prominently the mutable-body-versus-canonical-spec sense that governs ticket reconciliation, plus a bare-toolkit sense and a policy sense. A term carrying several senses degrades the conformance signal at the most visible naming surface in the corpus: a reviewer scoring an option against the principle would first have to disambiguate which sense is meant.
3. **Morphology encodes shape.** In this corpus, values are single quality nouns and cross-cutting disciplines are hyphenated compounds. A hyphenated-compound name would read as a *discipline*, visually contradicting D1's own value-not-discipline decision.

The design-review **litmus phrasing is retained verbatim** — *"does the governed concept survive a substrate swap?"* In-row, adjacent to "external system" and "adapter", the word is unambiguous; the ambiguity only bites when it becomes a compound identifier cited in conformance verdicts. Only the value's *name* changed; its content did not.

## Alternatives rejected

| Option | Trade-off | Verdict |
|---|---|---|
| **A. A cross-cutting *discipline*, not a value** | The charter defines its disciplines as those that apply to *every* domain and surface, rather than being a best-practice of one domain. Portability binds only **external-binding** surfaces — an internal-only change never engages it — so it fails the disciplines' own defining test. (Symmetric with the Security elevation's rejected discipline option, which failed the same test for the opposite reason: Security has a codified domain body. Both rejections turn on the charter's own definition of a discipline.) | **Rejected** — misclassifies a surface-scoped value as a universal discipline. |
| **B. No charter change — rely on the detector alone** | Catches leaks in text the detector already scans, but leaves the **design surface ungoverned**: a decision that has not yet become text is invisible to it, and there remains no axis to score an option against at a decision gate. | **Rejected** — leaves the actual gap unaddressed. |
| **C. A separate portability-philosophy document** | Fragments the single coverage matrix that IS the charter's purpose — one surface making coverage visible. | **Rejected** — defeats the spine (the same ground on which a separate security document was rejected). |
| **D. Name it with the originally proposed coined compound** | Coins a term where the corpus names the quality already, collides with several live senses of an overloaded word, and carries the corpus's *discipline* morphology. | **Rejected** — see D4. |
| **E (chosen). Seventh value + matrix row + index-only register entry, paired with the existing enforcer, named `Portability`** | Adds one row plus a bounded enumeration cascade. Makes adapter-boundary GAPs first-class and auditable, and gives decision gates a scored conformance axis. | **Chosen.** |

## Consequences

- **+** Adapter-boundary GAPs on the Agents and Slash-commands surfaces become **named backlog** rather than silent omissions; the charter's gap-finder can now see the class.
- **+** The Operator Decision Gate and acceptance review gain a scored conformance axis for adapter and external-binding work, replacing the per-card ad-hoc re-derivation.
- **+** The existing host-binding-leak detector gains a **principle to escalate against** — a mechanical finding can now be routed to a named design principle instead of standing alone.
- **+** The naming choice **removes** a vocabulary fork rather than creating one, and keeps the value's name aligned with the term the corpus already uses for the property.
- **−** The charter grows from six values to seven, cascading to the charter frontmatter enum, the value count, and the disciplines-index enum — all reconciled in this change.
- **−** Inserting a value row **shifts the design-principle register's line pins** for every entry at or below the insertion point. Two entries shifted and were repointed here. The register's deploy-time guard resolves a pin only to a non-empty line and never compares content, so it cannot detect a mis-pin; the mitigation is a whole-population name-match verification at every charter edit, not the existing guard.
- **−** The **path-portability** axis stays routed to Scalability rather than here. The two leak axes route to distinct principles by design, and the charter's enforcer-citation bullet carries that boundary marker explicitly — but it is a boundary reviewers must hold, and the shared word invites double-routing.
- **−** The workspace-root operator context file enumerates the value set and **lives outside this repository**; it will read one value short until updated out of band. The same residual was flagged when Security was elevated and was never resolved. Re-flagged here rather than dropped a third time.

## Reversibility

**CHEAP** / Confidence **HIGH**. The amendment is a naming-and-routing row plus a bounded enumeration cascade plus one register entry; removing it is a documentation edit and a revert of the single release PR. The paired enforcer is pre-existing and additive — reverting the row does not remove the detector. The name itself is a single substitutable token appearing in a small, enumerated set of places across four files, with no executable, schema, or identifier depending on the string.

## Related ADRs

- [ADR-081](ADR-081-security-sixth-first-class-value.md) — Security as the sixth first-class value. The same-surface precedent: the value-elevation shape, the never-naming-only invariant, and the core-scoped ADR home all follow it.
- [ADR-036](../../release/ADRs/ADR-036-version-claim-determinism.md) — the host-agnostic capability whose Portability consequence this generalizes from one capability to a platform-wide value.
- [ADR-017](ADR-017-distribution-architecture.md) / [ADR-022](ADR-022-platform-config-vs-operator-toml-split.md) — the adapters home and selector table this value's config seam depends on.
- [ADR-094](../../release/ADRs/ADR-094-extend-before-create.md) — the sibling value-extension precedent on the same charter row set.
- [ADR-019](ADR-019-specialists-compose-not-absorb.md) — compose-by-reference; the discipline under which the charter cites enforcers instead of restating them.
