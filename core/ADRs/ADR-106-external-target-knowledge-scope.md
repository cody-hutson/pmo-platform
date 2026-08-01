---
title: "ADR-106 — External-target knowledge scope: the target is the source of truth for its own facts"
status: Proposed — authored at Stage 6 Engineering for the governance-hardening release; flips to Accepted when the Stage 9 Plan Review renders GO (the ratifying review; a still-pending review means Proposed is correct).
date: 2026-08-01
release: governance-hardening (version bound at Stage 12)
deciders: "Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + Phase A6.5 independent adversarial design reviewer + operator (Stage 5 Collective Review scope-lock, which narrowed the scope and directed the placement-rationale reconciliation); ratification at the Stage 9 Plan Review"
tags: [architecture, knowledge-management, memory, ssot, external-target, adapters, no-shadow-ssot, host-binding, read-live, reversibility-split]
source_observations:
  - "THE GAP IS A REAL ABSENCE, NOT A BROKEN PROBE. Command: `grep -cniE 'external[- ]target|target[- ]repo|cross-repo|another repo|other repo|external repo' core/disciplines/memory-architecture.md core/disciplines/knowledge-architecture.md`. Observed: 0 and 0. Control proving the pattern resolves: the same expression over `core release --include='*.md'` returns non-zero across many files. Baseline: repo commit c4dde614, re-confirmed by the independent reviewer at f97c5ff2 and again at Engineering authoring time. FALSIFIER: either discipline file gaining external-target vocabulary from another change."
  - "THE VERSION-CLAIM ADAPTER INTERFACE CANNOT SERVE A REFERENT READ. Method: read `core/standards/repo-host-adapter-versioning.md` end to end. Observed: the standard is titled a version-claim operation interface, scopes itself to the deterministic-version-claiming capability, requires exactly four operations (anchor / claimed_set / atomic_claim / lineage), and states that the operation set must not change without re-touching every adapter and the claim mechanism. None of the four returns a label name, an item state, a milestone title, or file content. Observed separately in `core/config/operator.toml.template`: the repo-host selector is documented as naming where THIS platform's git surface and code review live — this install, not an arbitrary external target. CONSEQUENCE: the design's first-draft phrasing, which cited that interface as the read path, asserted a binding the interface forbids. FALSIFIER: a governed amendment adding a read operation to that interface, with its conformance-checklist cost paid."
  - "A STALE ADDRESS DOES NOT RELIABLY FAIL HARD. Method: live host probe with a two-way control, run by the independent reviewer. Observed: resolving a renamed repository address returned a successfully-resolved repository under a DIFFERENT name, exit 0, no warning — output indistinguishable from resolving the current name. Control 1: resolving the current name returned the same shape. Control 2: resolving a genuinely absent address returned a not-found error, proving the probe can fail loudly for the absence case but does not for the rename case. CONSEQUENCE: the one item this decision permits to be stored is the one item that can go stale invisibly, and a released address may later be re-taken by a different subject. This is why the decision carries an identity guard rather than a hard-failure assertion. FALSIFIER: a host that returns a distinguishable signal on redirect for every supported destination platform."
  - "THE ADDRESS FIELD IS A COMMENTED EXEMPLAR, NOT A POPULATED SURFACE, AND DECLARING IT IS NOT FREE. Method: read the multi-destination tracker block in `core/config/operator.toml.template`. Observed: the block ships commented on purpose; a fresh install has no live tracker section and resolves to a single back-compat destination. Observed in the same block: once ANY tracker destination is declared, filing resolution becomes fail-closed for a private-scope project whose tracker is unset, and each destination carries a scope value that arms the scope-segregation content guardrail. Observed also: the field's documented domain spans a repository path, a project key, or a board identifier depending on the destination platform, so it is not always a repository address. FALSIFIER: the template shipping the block uncommented, or the fail-closed clause being removed."
  - "THE STALE PLACEMENT CITATIONS WERE COUNTED BY A SEMANTIC PROBE, NOT A SUBSTRING ONE. Method: enumerate every section-numbered citation of the knowledge-architecture document corpus-wide TOGETHER WITH the anchor each carries, then classify by whether the anchor resolves inside the cited section. Observed: six citations name section 6 while their anchors resolve inside section 7 — five in the memory-architecture contract and one in the cross-surface memory ADR; two of those six also state a drift-class count of three where the live count is five. Control: the same probe returns correctly-numbered citations elsewhere in the same files, so the six are a real mismatch rather than a pattern artifact. WHY A SUBSTRING PROBE FAILS HERE: section 6 is a real section, so matching the string alone cannot distinguish a correct citation from a stale one — only the anchor does. The superseded predecessor ADR is deliberately excluded: its statements were true when ratified and its record is immutable. FALSIFIER: a renumbering that makes section 6 the memory-corpus boundary again."
---
<!-- reference-durability: allow-link -->

# ADR-106 — External-target knowledge scope: the target is the source of truth for its own facts

## Status

**Proposed.** Authored at Stage 6 Engineering for the `governance-hardening` release. It flips to **Accepted** when the Stage 9 Plan Review renders GO; until that review closes, `Proposed` is the correct state rather than an un-flipped one.

This record **extends** — it does **not** supersede — [ADR-045](ADR-045-cross-surface-memory-contract.md), which generalized [ADR-029](ADR-029-memory-corpus-ssot-boundary.md)'s Knowledge cut into the cross-surface memory contract. Both prior records are left byte-unchanged in their decision content, the same immutable-record posture ADR-045 adopted toward ADR-029.

*Numbering provenance.* The number was allocated at Engineering commit time, not at design time. The ADR-numbering checker reported a contiguous sequence across both ADR directories at the authoring commit, and the one other open pull request carried no competing ADR claim. Per the merge-time claim rule, a number is allocated at authorship but **claimed at merge**, so this record is referenced everywhere by its **slug** (`external-target-knowledge-scope`) and never by its integer. If a sibling merges ahead of it, the file renumbers and no reference moves.

## Context

The platform's memory contract resolves the source of truth between two surfaces that are both **this install's own**: the codified corpus and the operator auto-memory store. A defect surfaced that neither pole covers.

Operating a release workflow against an **external target** — a repository or system the toolkit *operates upon* rather than *is* — the agent read that target's conventions out of the operator's memory store, where they had been cached from prior sessions. One cached value had gone stale: memory asserted a ratification gate named by one label, while the target had since moved to a differently-named one and retired the original. The stale value was authoritative for the whole session and was caught only by an unrelated live re-read. Nothing structural had forced that read.

### The card's own framing does not survive inspection, and correcting it collapses the design

The originating report offered a three-tier model — live target state, target *conventions*, and operator-tacit context — and asked where the first two should live. On inspection **the conventions tier does not exist as a distinct class.** Every "convention" in the report's own evidence decomposes into an *operator-practice* half (legitimately holdable) and a *target-side referent* half (observable in the target). The defect was a **fused fact**: one entry welded "I ratify via a status label" — the operator's own practice — to the label's *name*, a target-side referent that must never be held. The classifier had no step that split a fact before homing it, so the fused fact was homed by the half the classifier could see, and its live half rode along as an unowned payload that nothing ever refreshed.

Run against the report's four stated examples, the decomposition leaves **no residue**: a ratification-gate name splits into a practice plus a label name; a one-pull-request-per-milestone rule is pure operator practice; a close-out definition-of-done is operator practice plus, where the target documents it, a live file read; and a milestone-filter method was never a target fact at all — it is host mechanics belonging in this platform's own corpus, mis-homed twice over. That a single entry held all four classes side by side is the clearest evidence that no decomposition step existed.

### Why the existing invariants were structurally blind to it

The no-shadow-SSOT invariant prohibits a *second copy of a fact whose source of truth is another surface*. For a target-side referent, the owning surface — the target itself — **is not in the contract table at all**, so there is no owner for the memory entry to shadow: the invariant is structurally silent rather than violated. The standing drift audit's classes each key on an issue tie or an internal link; a target referent has neither. The gap was therefore unreachable from the existing machinery, which is why the report is correctly typed a defect rather than an enhancement.

### The scope this record does *not* claim

The decomposition evidence above is drawn entirely from a target the operator **controls**, where every referent is observable and every practice is the operator's own. Generalizing the rule beyond that population would be generalizing beyond the evidence that validated it. Two adjacent cases — a target the operator does not control, and a referent a practice cannot resolve uniquely — are named and excluded rather than absorbed silently. That bound is part of the decision, not a caveat on it.

## Decision

1. **The classifier gains a pre-step (Q0)** that asks whether a fact asserts something about a repository or system other than this install's own platform, and **decomposes** it before homing. Decomposition is a precondition of homing, not an optional refinement.
2. **The target is the source of truth for its own facts.** No surface of this install holds a resolved target-side referent — not the corpus, not the auto-memory store, not operator config. Referents are read live at every use. This is a rule about *homing*; it does not by itself mandate a retroactive sweep.
3. **The only permitted stored item is the target's address**, which the existing per-destination operator-config field already expresses where a destination is declared. **No new config surface is created.** Two properties are stated rather than assumed: the field ships commented, so it is not guaranteed to exist in a given install and declaring it changes filing-resolution behaviour; and a stale address can resolve silently to the wrong subject, so the address is **an assertion to verify** — resolve it, confirm the resolved identity matches the configured address, halt on mismatch — never a fact to trust.
4. **A target-side referent is resolved by a live read of the target through the platform's configured host-adapter seam**, stated at capability altitude and host-agnostically; the host mechanism lives only inside the adapter. This applies the canonical host-binding rule the knowledge-architecture document itself owns. That rule's preferred form names the adapter **operation** the capability calls — and **no such operation exists today**: the shipped adapter interface covers version-claiming and its operation set is closed by its own contract. The read operation is therefore recorded as **owed and unspecified**, to be filed as its own governed interface slice with its own conformance cost. It is deliberately not back-doored into a standard that forbids the change.
5. **Divergence surfaces as a halting resolution failure, never a stale value.** A live read returning zero matches, or more than one where the practice's predicate expects exactly one, is a loud signal the agent surfaces to the operator. There is **no offline fallback, by design** — a fallback cache would reintroduce the defect being removed.
6. **Scope bound.** The rule covers only facts whose source of truth is a repository or system other than this install's platform, and within that only **operator-controlled targets with uniquely-resolvable referents**. Content whose source of truth is the corpus (`core/`, `release/`) is **definitionally excluded**; the encode-and-evict lifecycle, its verification gate, its archive-first step, and its ordering guarantee are untouched. A fact outside the bound is surfaced to the operator for an explicit homing decision, never homed by nearest fit.

## Alternatives Considered

Five candidates were generated across three altitude bands. Four were eliminated on hard-constraint breach, before any scoring.

| Candidate | Disposition | Kill-reason |
|---|---|---|
| **Prohibition only** — forbid caching target facts, name no home | eliminated | Leaves the fact homeless. The agent still needs it, so it re-caches. Fails the report's own criterion, which asks *where* the knowledge should authoritatively live. |
| **A new per-target config registry** | eliminated | A second registry keyed on the same address the existing per-destination field already holds is itself a shadow source of truth, at the config layer. Also breaches extend-before-create with a covering surface available, and carries a wider blast radius (setup round-trip preservation, migration, token review). |
| **Conventions stored on the existing per-destination subtable** | eliminated | **Does not solve the defect.** Storing conventions is storing a cache; the drift class survives intact, merely relocated from a memory file to a configuration file. This is the answer most readers reach for, and it dies on the defect it fails to fix, not on a close score. |
| **The target self-describes its conventions in-target** | eliminated as the primary, **folded in** | Requires write access to a system the operator may not control, and creates a cross-repository dependency this platform can neither enforce nor verify. Retained as the *preferred source* where a target does self-describe — reading that document is itself a target-side derivation, which the selected design already covers. |
| **Decomposition gate + read-live contract; store only the address** | **selected** | The only candidate that eliminates drift *structurally* rather than relocating the cache. |

**The one real cost, not minimised.** With nothing cached there is no offline fallback: a session that cannot reach the target cannot resolve a target-side referent and must halt. That is deliberate and it is the correct trade here, because the defect under repair is precisely "served a stale value silently" — a fallback cache would reintroduce the defect as a feature. The workload makes the cost negligible: a handful of reads per release, where latency is irrelevant.

**A counter-design was considered and declined at the correct altitude.** Adding a fifth, read-shaped operation to the existing adapter interface would satisfy the host-binding rule's preferred form directly. It is declined *here* — not rejected in principle — because that interface's own contract closes its operation set, so the change is a governed interface amendment with a conformance-checklist cost that this decision did not buy. Recording the operation as owed is the honest disposition; asserting a binding that does not exist would not be.

## Consequences

**Positive.**

- **Drift is eliminated by construction, not by detection.** With no value stored, compliant behaviour cannot drift. The primary teeth are structural; a detector would only catch non-compliance.
- **The failure mode inverts from silent to loud.** A divergence that previously produced a plausible wrong answer now produces a halt at the point of use.
- **Zero net-new surfaces.** No new configuration table, no new file except this record, no new anchor any existing consumer must learn. The classifier, the boundary section, and the existing per-destination address field each already covered their half.
- **An Nth target costs zero governance.** The rule is stated over any repository or system other than this install's platform, so adding a target adds only its address.

**Negative, and accepted.**

- **No offline resolution.** Stated above; the halt is the design, not a defect.
- **The rule ships doc-only, with no detector.** A drift class is named (`external-target-referent-stored`) and its detector is **deferred** — adding one would move the standing audit's class count and cascade across a discipline document, a check, a how-to and a fixture, which this scope did not buy. The deferral matches the standing deferred-enforcement posture already recorded on the memory contract.
- **The bound leaves two cases ungoverned, by choice.** Non-controlled targets and non-uniquely-resolvable referents route to the operator rather than to a rule. That is honest for now and is separate work; shipping rows for them without their own adversarial pass would have been the worse error.
- **The read operation is owed.** Until the adapter interface gains one, the read path is specified at capability altitude only. A future implementer must add the operation rather than infer that a binding exists — which is why the gap is recorded in the rule text rather than left to be discovered.

## Reversibility

**Split by limb — a single tier would misstate the profile of the package an operator acts on.**

- **The corpus rule: CHEAP / Confidence HIGH.** Additive text in two discipline documents plus this record; reverting the merge commit restores prior state. No configuration migration, no runtime surface, no package.
- **Any operator-side retirement performed under the rule: IRREVERSIBLE by git / Confidence HIGH.** Retiring an existing entry is an action on a Layer-2 operator surface that an engineering commit cannot make and a revert cannot undo. Its compensating control is the archive-before-deletion posture the encode-and-evict lifecycle already establishes — not the revert. Grading this package on its file diff alone would have hidden the only irreversible limb it has.

## Related ADRs

- [ADR-029](ADR-029-memory-corpus-ssot-boundary.md) — the original memory↔corpus source-of-truth boundary and the encode-then-evict ordering guarantee. Superseded by ADR-045; left byte-unchanged.
- [ADR-045](ADR-045-cross-surface-memory-contract.md) — generalizes the Knowledge cut into the cross-surface memory contract across all four memory types. **This record extends that cut with a third scope; it does not supersede it.**
- [ADR-022](ADR-022-platform-config-vs-operator-toml-split.md) — establishes the operator-config home for the adapter selectors this record's read path composes with.
