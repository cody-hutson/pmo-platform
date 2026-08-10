<!-- reference-durability: allow-link -->
---
title: "ADR-132 — Initiative-coextension is an advisory conjunct on Check 55, not a second epic-tiering check"
status: Proposed
date: 2026-08-10
release: triage-and-backlog-instrumentation
deciders: "operator (Stage-5 Decision Recorded — lexical conjunct ACCEPTED with the stated containment) + Stage 5 Solutioning spoke (design) + Stage 6 Engineering spoke (implementation)"
tags: [work-hierarchy, deploy-check, label-taxonomy, advisory-severity, precision, extend-before-create, ADR-049]
source_observations:
  - "The card's own stated detection signal — an open type:epic sharing a project: label with N other open epics that are not its native children — was implemented literally and measured against the live tracker: it flags 39 of 42 open epics (92.9%)."
  - "The over-fire is structural, not a threshold to tune. The project:-family shape is SYMMETRIC: a leaf epic inside a family shares its label with exactly the same non-children its container does, so every leaf matches the container's signature by construction."
  - "The enforcement surface the card deferred to design already half-existed. check-work-hierarchy.py (Check 55) carries H1 (no normative doc asserts a banned parent tier) and H2 (no open type:epic has a type:epic parent), and H2 fires on live edges today."
  - "H2 cannot reach the residue. The two live containers the card names carry NO epic-parent edge — the mis-tiered families return parent NONE — which is precisely why a native-link-only check never saw them."
  - "The three-way conjunction measures at 2 flagged / 42 denominator / 0 false positives, catching exactly the two live containers. Each conjunct ALONE over-fires: family shape 39, title coextension 4, in-family fan-out 6."
  - "The platform's only other multi-invariant deploy check extends ONE letter series to a third member and makes that third member the advisory one — structurally identical to what this record adopts."
---

# ADR-132 — Initiative-coextension is an advisory conjunct on Check 55, not a second epic-tiering check

## Status

**Proposed.** Authored at Engineering for the `triage-and-backlog-instrumentation` release; ratified at that release's plan-review gate.

## Context

The platform's initiative tier is, by design, a `project:` label plus an operator-local roadmap — never a standalone issue ([ADR-049](ADR-049-canonical-initiative-roadmap-vocabulary.md) §Decision 1/2; [`label-taxonomy.md § Initiative Labels`](../specs/label-taxonomy.md)). Because no initiative issue class exists, early initiatives were filed as `type:epic` — there was no other issue type that could hold them. Once decomposed into genuine epics, those containers had no tier to be re-homed to and simply kept their epic type.

That rule was stated in the taxonomy as a **concept** and carried **no enforcement**. Closing the gap raised two questions that had to be answered in the right order, because the second only looks easy until the first is measured.

**The detection signal.** The intake card proposed one: *an open `type:epic` whose `project:` label is shared by N other open `type:epic` issues that are not its native children*. Implemented literally over the live population, it flags **39 of 42 open epics (92.9%)**. The reason is not a threshold: the family shape is **symmetric**. In any multi-epic family, a textbook leaf epic shares its label with exactly the same set of non-children the container does. Every leaf is a false positive **by construction**, and raising N cannot separate two things whose signatures are identical. Shipping it would have put a 93%-false-positive lint into the very release whose sibling card authors the obligation against precision failures of exactly this shape.

**The enforcement surface.** The card deferred this to design as an open assumption, naming a new check as a candidate. But `core/deploy/tools/check-work-hierarchy.py` (Check 55) already owns this subject: its `BANNED_PARENT_TIERS` is sourced to the same ADR-049 decision the taxonomy cites; its **H1** leg asserts that no normative doc names `Initiative`/`Roadmap` as a parent tier; its **H2** leg asserts that no open `type:epic` has a `type:epic` parent, over the identical `issues(states:OPEN, labels:["type:epic"])` GraphQL population; and it already carries an exemption loader, a self-test harness, and a `deploy.sh` block self-described as the multi-invariant container shape.

What H2 **cannot** reach is the residue the card actually names. The live containers carry **no epic-parent edge at all** — the mis-tiered families return `parent: NONE`. A check reading native sub-issue links alone misses the entire population, which is exactly how these survived.

## Decision

**D1 — Extend Check 55 with a third invariant `H3`; do not create a sibling check, and do not consume a new check number.** The primitive already owns the population, the ADR-049 basis, and six shipped components (the batched GraphQL fetch, the exemption loader, the TSV emitter, the self-test harness, the fail-loud discipline, the `deploy.sh` wiring). A sibling would duplicate all six and stand up a **second authority on epic tiering**, with two independent readings of one ADR free to drift apart. The check slot the design phase had reserved is released back to the unrelated card contending for it.

**D2 — `H3` is a three-way conjunction, and no limb may be dropped for simplicity.** An open `type:epic` is reported **iff all three** hold:

1. **Family shape** — it carries a `project:<slug>` label whose family, excluding its own native sub-issue children, holds **≥ 2** other open epics.
2. **Title coextension** — every token of `<slug>` appears in the issue's normalized **title head** (lowercased, a leading `[Epic]` prefix stripped, truncated at the first em-dash or spaced hyphen, tokenized on non-alphanumerics). A container names the whole domain; a thrust names its own thrust.
3. **In-family fan-out** — the issue's body references **≥ 2** distinct members of that family. A container enumerates its family; a sibling cites a neighbour or two.

Measured on the live population: **2 flagged / 42 / 0 false positives**, catching exactly the two containers the card names. Each conjunct **alone** over-fires — 39, 4 and 6 respectively — so the conjunction is doing the discrimination rather than decorating it. Seven near-miss classes, each differing from a true positive in **exactly one** conjunct, are pinned as must-not-fire fixtures, and the self-test additionally proves that the family conjunct alone over-fires on its own fixture, so a future "simplify to the family shape" edit fails there rather than shipping.

**D3 — `H3` is advisory-only, and the constraint is expressed structurally rather than as a default.** Its findings are **excluded from the primitive's exit-code arithmetic**, and `deploy.sh` routes them through the emitter that has no mode case and no issue-count increment. The leg therefore cannot gate in `warn` **or** `enforce` mode, and cannot be flipped to a failure when the shared check graduates. It performs **no write**: no relabel, no re-tier, no mutation of any kind. The precedent is the platform's other multi-invariant deploy check, whose third leg is advisory for the same reason — a predicate that cannot distinguish a violation from a legitimate record must report and never block.

**D4 — The lexical conjunct is a knowing exception to this check's stated predicate principle, accepted on three containments that travel together.** `check-work-hierarchy.py` states its design principle as *closed-vocabulary membership inside a structural arrow-chain, not prose similarity*. Conjunct 2 reads a title, which is a partial exception to that principle. It is accepted because the measurement is decisive — 2/42 with zero false positives, against 39/42 for the structural conjunct alone — and because refusing it would uphold the principle's letter while defeating its purpose: a check with a 92.9% false-positive rate has no falsifiable predicate at all. The exception is bounded by three containments, all shipped, and **none of them may be removed independently of this decision**:

- **(i)** the leg is advisory and can never gate (D3);
- **(ii)** the exemption file takes a fixed `#<issue> initiative-coextension` entry form — fixed rather than keyed to the issue's `project:` label, so an operator's judgment survives a relabel;
- **(iii)** every finding **emits its own evidence** — the matched slug tokens and the in-family references — so a row can be falsified in one read rather than re-derived.

**D5 — A structurally-empty `H3` population is an input failure, never a clean zero.** `H3` reads `labels`, `title` and `body`; the `H2` leg reads only `parent`. A fixture written for `H2` therefore leaves `H3`'s population structurally empty, and **every specificity assertion returns a vacuous zero and passes for the wrong reason** — the same shape as a scan whose baseline silently resolved to empty. A node set missing that field triple **exits 3 with the missing fields named**. Correspondingly, a leg that did not run emits an explicit `SKIP` row and **no count row at all**, so "not evaluated" can never be read as "zero"; a genuinely empty epic population is likewise a skip, not a zero.

**D6 — The taxonomy assertion is scoped to *materialization*.** The rule states that an initiative **must not be filed as a standalone `type:epic` issue** — it is represented by its `project:` label plus its operator-local roadmap. It deliberately does **not** say "an epic is not a container": the taxonomy's own applicability rules call an epic a container / grouping tier, and that remains true. Both statements have to stand together, and wording the assertion as a claim about epics would contradict the rule the `type:epic` status-label exemption rests on.

## Alternatives Considered

1. **Ship the card's stated predicate (family shape alone).** Rejected on measurement: 39 of 42 open epics, 37 of them false positives. The failure is symmetry, not calibration, so no value of N rescues it.
2. **A new `check-initiative-tiering.py` on its own check number** — the design the planning phase had assumed. Rejected: it duplicates six shipped components and creates a second epic-tiering authority reading the same ADR, for no gain — a new file does not make the predicate any easier, which was the actual hard part.
3. **Assertion only; no lint.** Rejected: it leaves the card's central acceptance criterion — that a lint exists — unmet, and reproduces the exact condition the card was filed against (a rule stated and unenforced).
4. **`H2` alone, with the acceptance criterion re-scoped.** The honest fallback if the lexical conjunct were refused, and retained here as such. Rejected because `H2` misses both live containers — they carry no epic-parent edge — so the detection the card exists to provide would not ship at all.
5. **Mechanize "is this epic coextensive with its initiative?" as a semantic classifier.** Rejected: the property is a *judgment about scope*, not a graph property. Two epics with byte-identical structure can differ solely in prose scope, so such a check is unfalsifiable at the acceptance surface and cannot state an expected zero. This is the alternative every future reader will propose on seeing a lexical conjunct, which is why it is recorded rather than left implicit.
6. **A fresh invariant letter series for the new leg.** Rejected: the existing series' dimension is "work-hierarchy invariant", and initiative-coextension is a member of it. A second series inside one check would assert a new dimension where none exists, and the platform's other multi-invariant check has the opposite precedent.
7. **Extend the green summary line to claim "no coextension advisory".** Rejected on a correctness argument that is easy to miss: because `H3` is excluded from the exit code, an `H3`-only run lands on the *clean* exit path — so that line would print "no coextension advisory" precisely when the advisory had fired. The leg is given its own always-emitted line instead, which is the stronger form of the same guarantee.

## Consequences

- **+** The taxonomy's initiative rule stops being an unenforced concept and gains one named home, discoverable from the rule text itself.
- **+** The platform keeps **one** authority on epic tiering. `H1`, `H2` and `H3` share a population, an exemption file, an emitter and a self-test.
- **+** No new file, no new check number, no new CLI parameter, no CI change, and no script-allowlist row. The reserved check slot returns to the card contending for it.
- **+** The measured over-fire is recorded in the taxonomy, in the primitive's own header, and here — so the broken signal is not re-proposed as an obvious simplification.
- **+** The anti-vacuity rule generalizes: this check now treats a structurally-empty leg population as an input failure rather than a clean result, in the leg where the trap is live.
- **−** A **lexical** conjunct now sits inside a check whose stated principle is structural. This is real debt, not a technicality: renaming an epic changes `H3`'s verdict, and a single-token slug weakens the conjunct. Tolerable only because the leg reports and never blocks — if `H3` were ever proposed for enforcement, this record is the reason to refuse.
- **−** The fixture parameter now carries more than a parent map. Accepted rather than renamed: a rename is a breaking parameter change to a live check, for a naming nit. Recorded in the primitive's own documentation.
- **−** `H3` reports for review and never re-tiers, so a flagged container stays mis-tiered until an operator acts. That is the intended posture — automatic reclassification on a lexical signal is precisely what the containments exist to prevent.
- **−** Three fields were added to the shared GraphQL selection set, so the `H2` fetch now returns issue bodies. One query, one call, unchanged call count; a larger payload.

## Reversibility

**CHEAP · confidence HIGH.** Every change is additive behind an advisory branch that cannot move an exit code, so reverting the merge restores the prior behaviour exactly and no consumer's verdict changes in either direction. Nothing was migrated, renamed or moved; no state is written. Acting on a finding — re-tiering a flagged container to a `project:` label plus a roadmap entry — is itself a single relabel.

## Related ADRs

- [ADR-049](ADR-049-canonical-initiative-roadmap-vocabulary.md) — the canonical initiative/roadmap vocabulary. It governs the *vocabulary* ("Initiative is not a level") and supplies this check's banned-tier set; it does not govern *how that rule is detected in the backlog when the structural edge is absent*, which is the gap this record fills.
