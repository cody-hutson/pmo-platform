<!-- reference-durability: allow-link -->
---
title: ADR-111 — The P-level digit is the canonical priority satisfier; the carrier is not part of the contract
status: Proposed
date: 2026-08-03
release: release-bundle-and-sequence-gates
deciders: "Workspace owner — the body-parse-vs-doc-only fork was an open two-way resolution on the originating ticket and was settled at the Stage-4 gate in favour of body-parse. The carrier-agnostic grammar was designed at Stage 5, survived an independent Stage-5 Phase-A6.5 adversarial review with no blockers, and was implemented at Stage 6 with the review's two Major constraints (the sign-convention reconciliation and the dead-acceptance-probe repair) treated as mandatory."
tags: [release-pipeline, priority-model, issue-body-parse, tie-breaker, detector-canonicalization, duplicate-logic]
source_observations:
  - "The gate-criteria specification already declared the rule — a single template-agnostic detector spanning both field names, with the P-level digit as the canonical satisfier — and no implementation in the repository followed it. The declaration and its implementations had diverged without anyone noticing, because each implementation degraded silently rather than erroring."
  - "Three separate implementations of this one concept existed at the same time, each binding a different carrier: the bundle parser bound a priority LABEL regex (a surface the label taxonomy forbids, so it resolved nothing at all); the deploy check bound the bold-inline form only (so it failed most of its own population); the approved-queue-depth tool binds a label prefix set and reports the whole population as unlabelled. None of the three agreed, and none of the three failed loudly."
  - "The corpus carries this field under two live carriers with EXACTLY ZERO overlap — a markdown heading (the intake form's dropdown render) and a bold inline field (agent-authored bodies and readiness blocks) — plus a governed Severity adapter on bug-typed issues. A heading-only reader resolves two of this release's own six cards; a bold-only reader resolves four; neither is the majority carrier."
  - "The qualifier vocabulary is deliberately template-divergent (the improvement form offers Urgent/High/Medium/Low, the bug form offers Blocker/Material/Annoyance/Cosmetic) and the live corpus adds more words still. Binding the qualifier word cannot work across templates; binding the digit can."
  - "An unanchored form of the governed regex matched a mid-prose sentence and resolved a priority its author never set. Line-anchoring rejects it. Specificity, not only recall, decides this grammar."
  - "The tie-breaker's own document expressed the ordering with a negated key over an inverse scale, and left the function undefined. Introducing a rank function beside it without reconciling the sign would have inverted the rule end to end with nothing failing loudly."
---

# ADR-111 — The P-level digit is the canonical priority satisfier; the carrier is not part of the contract

## Status

**Proposed.** Authored at Stage 6 per the Stage-6 ADR-authoring precedent. It flips to **Accepted** at this release's Stage-9 plan-review gate; per the established precedent the flip is verified against this file's own `status:` field and never assumed from Milestone closure.

**Numbering.** ADR numbers are platform-global monotonic across **both** homes (`core/ADRs/` and `release/ADRs/`), and the claimed set includes **in-flight branch and pull-request claims**, not only what is on the mainline. This record's number was re-derived immediately before authoring by enumerating both ADR directories across the mainline, every unmerged remote branch, and the ADRs already added on this release branch. A working-tree glob is not the authority here: this record's design-time allocation was invalidated when a sibling release merged five ADRs between Stage-5 exit and Engineering start, and a second allocation would have collided with an ADR added by an earlier slice of this same release.

## Context

The release planner documents a priority-descending tie-breaker over its topological sort. That tie-breaker had never executed. The parser sourced priority from a `priority:` label regex, but the label taxonomy tracks priority in the issue **body** and forbids a priority label family — so no such label exists, the field resolved to `None` for every issue on every run, and bundle sequencing silently degraded to issue-number ordering. No test caught it, because no test asserted that extraction was ever non-empty.

Repairing that required choosing where priority is read from, and the obvious choice was wrong. The intuitive fix — read the `### Priority` heading the intake form renders — resolves **two of this release's own six cards**. The corpus carries the field under two live carriers whose populations do not overlap at all: the heading form from the form's dropdown, and a bold inline form (`**Priority:** …`) used by agent-authored bodies and readiness blocks. Bug-typed issues carry no Priority field whatsoever; their template offers `### Severity` with the same P-level values, and a governed adapter already declares the two equivalent. A heading-only reader is blind to the bold carrier and to every bug; a bold-only reader is blind to the heading majority.

The deeper finding is that **the rule already existed and nothing implemented it**. The gate-criteria specification states plainly that a single template-agnostic detector covers both field names and that the P-level digit — not the field name, not the qualifier word — is the canonical satisfier. Three implementations existed in the repository at the same time and none of them was that detector:

| Implementation | Carrier it bound | Consequence |
|---|---|---|
| The bundle parser | a `priority:` **label** | resolved nothing; the tie-breaker was inert for the whole release history |
| The deploy-time gate check | the **bold-inline** form only | fails the large majority of the population it evaluates, most of it purely for using the heading carrier |
| The approved-queue-depth tool | a **label prefix set** | reports its entire population as unlabelled priority |

Each degraded silently. That is the shape of the problem this record exists to close: not a wrong detector, but the absence of one authority a fourth implementer would reuse.

## Decision

**The P-level digit is the canonical priority satisfier. The carrier is not part of the contract.** Any consumer of this field reads it through the shared detector rather than authoring its own.

### 1. One carrier-agnostic detector, line-anchored

`PRIORITY_FIELD_RE` in `release/tools/bundle-issues-parser.py` is the reference implementation. It spans `Priority` and `Severity`, under a markdown heading of any level or as a bold inline field, with or without a list bullet, tolerating the dash variants and an optional bracketed evidence label. It binds `P[1-4]` and **discards the qualifier word**, because the qualifier vocabulary is deliberately template-divergent and only the digit is common across templates.

The detector is **line-anchored**, and that anchor is load-bearing rather than incidental. The governed regex, taken literally and unanchored, matches a priority mentioned mid-sentence in prose and resolves a level the author never set. Line-anchoring rejects every such construction in the live corpus. The accepted cost is precise and small: a carrier appearing mid-line after other fields on the same line is not resolved. **Specificity is part of this decision, not a side effect of it** — a detector that resolves more by widening into prose is worse, not better.

### 2. Absent, word-only, and out-of-range all resolve to `None` — never a default, never an error

A default (say, treating unset as a middle priority) makes an unset field indistinguishable from a deliberately-middle one and manufactures ordering signal no author supplied. An error is equally wrong: the field is optional at intake and is not defined at all by the bug, observation, story, epic, or ADR templates, so absence is **conformance**. Accordingly **priority never contributes to `parse_status`** — routing it there would depress a gated parse-rate metric on conformant bodies, and would additionally drop those records from the contention map and set a non-zero exit code, both of which are strictly worse outcomes than a `None`.

### 3. The tie-breaker rank is ascending and is never negated

`priority_rank` maps P1..P4 to 1..4 and unset to **5**, so unset sorts last, and the sort key is `(priority_rank, issue_number)` **ascending**. This direction is canonical and is stated once, because the tie-breaker's own document previously expressed the same intent as a negated key over the **inverse** scale (larger number meaning higher priority) with the function left undefined — including for unset. Introducing a rank function beside that form without reconciling the sign would have produced a **silent full inversion**: unset first, P1 last, with nothing failing loudly and no executable assertion anywhere to catch it. The document is reconciled to the single ascending direction, and the sort direction is asserted empirically in the parser's self-test alongside an inversion control that proves the assertion can fail.

### 4. The record shape does not change

`IssueRecord.priority` keeps its type, its domain (`P1`..`P4` or unset), its JSON key and its position. Only the **source** moves. No consumer migrates, no shim exists, no version gate is needed. `priority_rank` is exposed as a module-level function and is **deliberately not serialized** — a consumer derives it from `priority` in one line, and adding a key would change an output contract for no gain.

## Consequences

**Positive.**

- The documented tie-breaker executes. On this release's own milestone the parser resolves a P-level for **six of six** parent cards, where it previously resolved none.
- The declared rule and its implementation agree for the first time. A future consumer has one authority to point at.
- Zero output-contract change means zero consumer migration — the repair is invisible to everything downstream except in the values it now supplies.
- The detector is protected against regressing to silence: a non-empty-extraction guard fails if the detector ever resolves nothing across the frozen sample. That guard is the artifact whose absence let the original defect survive undetected for the full release history.

**Negative, and accepted.**

- **A mid-line carrier is not resolved.** This is the price of line-anchoring, paid deliberately (see Decision 1). It affects a very small number of bodies and is preferable to resolving prose.
- **The specificity guards cover the shapes the corpus contains, not every shape the grammar admits.** Constructed bodies that quote the tie-breaker rule verbatim under a Priority heading, or that state a priority in line-initial prose, will resolve. This is a known residual, recorded here rather than silently carried.
- **A severity vocabulary the detector does not bind has begun appearing.** Some recently-filed bug bodies carry an `S<digit>` severity token (`S2 - Major`) rather than the `P<digit>` form their own template declares; those resolve to unset. **This is deliberately not fixed by widening the grammar** — no template declares an `S` vocabulary, so binding it would infer a level the author did not write, which is the same invention this record rejects for word-only values. The correct home is intake conformance, not the parser. It is named here so the next consumer does not have to rediscover it.
- **Two unreconciled implementations remain.** The deploy-time gate check and the approved-queue-depth tool still bind their own carriers and are out of scope for the change that produced this record. This record is the authority they should be reconciled to; until they are, the platform holds three readings of one field.

**Binding consequence for future work.** A consumer that needs an issue's priority **reuses the shared detector**. Authoring a fourth carrier-specific matcher re-creates precisely the divergence documented in the Context table.

## Reversibility

**CHEAP** · confidence **HIGH**. The change is one function swap plus one helper in a single stdlib-only module, and one reference-document reconcile. Revert is a `git revert` of a single commit; no data is migrated, no contract is versioned, and no consumer holds state derived from the new values. The decision's *durability* is the reason to record it, not the difficulty of undoing it.

## Related ADRs

- [ADR-019 — Specialists compose, not absorb](../../core/ADRs/ADR-019-specialists-compose-not-absorb.md) — the duplicate-logic hazard this record generalizes from skills to detectors: one concept, one implementation, cited rather than restated.
- [ADR-094 — Extend before create](ADR-094-extend-before-create.md) — the existing heading-section extractor was evaluated as the host for this read and rejected on structure (it returns a heading-delimited section; the dominant real carrier is an inline field inside another section), so the detector ships as a sibling pure function that leaves the extractor byte-unchanged.
- [ADR-062 — Substrate vs canonical precedent](../../core/ADRs/ADR-062-substrate-vs-canonical-precedent.md) — why the originating ticket's superseded population figures were corrected in the release record rather than by rewriting the issue body.
