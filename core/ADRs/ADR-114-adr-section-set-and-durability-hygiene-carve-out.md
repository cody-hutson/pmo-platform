<!-- reference-durability: allow-link -->
---
title: ADR-114 — The alternatives section is required with conditional content, and Accepted ADRs admit durability-hygiene edits
status: Proposed (flips to Accepted at this release's Stage 9 plan-review gate)
date: 2026-08-03
release: adr-corpus-conformance
deciders: "Workspace owner (ratifies at this release's Stage 9 plan-review gate); requirement level and carve-out shape designed at Stage 5 Solutioning, the heading-equivalence and public-surface calls rendered at the Stage-4 and consolidated Wave-1 gates, authored at Stage 6"
tags: [architecture, adr, governance, schema, immutability, conformance, single-source-of-truth, reversibility-cheap]
source_observations:
  - "The requirement level for the ADR alternatives section was stated on five surfaces at four mutually incompatible levels: the schema omitted the section from its required set entirely; the authoring guide called it 'the load-bearing section — it is why the ADR exists' without stating a formal level; the operations template marked it '(optional — recommended whenever >=2 viable options existed)'; the intake issue template marked its Considered-Options field `required: true`; and the scaffolding procedure emitted it by construction as one of seven sections. The originating ticket named only the first three."
  - "A live heading inventory over the corpus at the release baseline: 38 files carry the canonical `## Alternatives Considered`, 26 carry a case or wording variant, 13 carry `## Alternatives rejected`, and 32 carry no alternatives-family H2 at all. Of those 32, 10 record their options under `## Options considered` / `## Options Considered` / `## Decision Drivers` and 1 records them at H3, leaving 21 with no recall content at any level. Partition re-verified to the full corpus with sensitivity and specificity arms."
  - "ADR-027 is the authoring guide's own named witness for the trigger 'rejected alternatives recorded' — and a heading-string omission test scores it an omission. The standard's own exemplar fails the standard's own test, which demonstrates that the heading-string test measures the wrong property."
  - "Every finding the shipped ADR durability lint reports sits on an `Accepted` record; none sits on a `Proposed` or frozen one. Under a literal reading of the guide's 'the body stays byte-frozen', the lint's entire remediation path is a policy violation, and the guide's own enforce-flip clause — which gates the flip on a full structural-conformance pass — presupposes edits the same guide forbids."
  - "The lint's whole-file exemption covers `Superseded` and `Deprecated` records only, on the stated ground that 'flagging them would demand an edit the immutability policy forbids'. Its authors therefore read the freeze as attaching to frozen records, not to all Accepted ones. Read literally, the exemption would cover almost the whole corpus and the lint would be pointless."
  - "The acceptance criteria of the originating ticket contradict each other as literally written: one requires adding a missing required section to an Accepted ADR, and another forbids an in-place edit that changes 'the alternatives'. For the files missing that section, the mandated edit is the forbidden one."
  - "`core/standards/evidence-grounding-standard.md` already applies the required-section / conditional-content construction to its own drift section: 'the section must always be present; its contents may be empty… The omission test is structural, not content-based.'"
---

# ADR-114 — The alternatives section is required with conditional content, and Accepted ADRs admit durability-hygiene edits

## Status

**Proposed.** Authored at Stage 6 per the Stage-6 ADR-authoring precedent. It flips to **Accepted** at this release's Stage-9 plan-review gate; per the established precedent the flip is verified against this file's own `status:` field and never assumed from milestone closure.

This record is the first ADR authored under the section set it defines, and it carries that set in full.

**Numbering provenance — `110 → 114`.** Authored branch-local as **ADR-110**; renumbered to **ADR-114** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 110. In-release citations that read "ADR-110" denote this record.

## Context

The ADR standard contradicted itself in two places, and both contradictions blocked the same downstream work — the corpus conformance sweep.

**First, the requirement level for `## Alternatives Considered` had no single answer.** It was stated on five surfaces at four mutually incompatible levels, ranging from *absent from the required set* through *optional* to *required: true*. "Author to the standard" therefore named a target that did not exist, and "bring the corpus into conformance" could not be sized, because the size of the job depended on which surface you believed.

**Second, immutability and durability hygiene were in direct conflict.** The authoring guide said an Accepted ADR's body stays byte-frozen, with a single named mechanical exception. The shipped durability lint reports findings that can only be cleared by editing Accepted ADR bodies. The guide's own clause gating the lint's enforce-flip on a full structural-conformance pass presupposes exactly those edits. So the guide simultaneously forbade the edits, shipped a tool that demanded them, and made its own graduation conditional on them.

These are not independent defects. The conformance sweep is blocked by both: it cannot author to a self-contradictory standard, and — more sharply — without a carve-out its edits are not merely mis-targeted but **unauthorized**. A policy that no one can comply with is not a policy; it is a rule everyone quietly breaks, which is worse than no rule because it makes the audit trail's protection unfalsifiable.

The underlying failure in both halves is the same, and it is the one this release exists to eliminate: **a rule stated in more than one place, where the copies drifted and nothing reconciled them.**

## Decision

**(1) `## Alternatives Considered` is `Required — content conditional`, defined once in [`adr-schema.md`](../schemas/adr-schema.md) §3 and cited by every other surface.**

Every ADR carries the section. Where ≥2 viable options were weighed, it records each option and why it was rejected. Where a single forced approach existed — an ADR written because it binds a cross-artifact contract or supersedes a prior record rather than because options were weighed — it says so explicitly. An **absent** section is a conformance defect; a section declaring a single forced approach is **conformant**.

The conditionality attaches to the section's **content**, never to its presence. The canonical heading is the exact string `## Alternatives Considered`, H2, at position 4. The required set is a **minimum, not a closed vocabulary**: an ADR may carry additional H2 sections, and a conformance check asserts that each required section is present, never that nothing else is.

The set is **defined** in the schema and **cited** everywhere else. §3.2 of the schema carries the authority chain as a table — one row per surface, each declaring DEFINES or CITES — so a surface added later inherits the citing obligation instead of becoming the next divergent statement.

**(2) Editability is a three-state model keyed on the existing `status:` field**, with the boundary at **record vs. revise**. `Proposed` records are freely editable. `Accepted` records admit **durability-hygiene edits only**. `Superseded` and `Deprecated` records are **frozen** and admit nothing.

An edit that *records* something the decision already contained — or removes an anchor that has since rotted — is hygiene. An edit that *revises what the decision was* requires a new superseding ADR, always, with no in-place path. The permitted list is **open** (each entry is an instance of the invariant, so a new hygiene class needs no governance change); the forbidden list is **closed** (decision, alternatives-as-weighed, consequences, and any non-Nygard status change), so the hard edge sits on the side that protects the audit trail.

A **no-fabrication clause** binds the backfill: record only alternatives evidenced by the ADR's own artifacts, and where the artifacts do not evidence what was weighed, do not reconstruct it — write the single-forced-approach declaration instead. Without that clause, a backfill across ratified architecture records is a fabrication engine rather than a conformance pass. The full carve-out lives in [`adr-authoring-guide.md`](../standards/adr-authoring-guide.md) § Supersession + immutability, which owns immutability *policy* while the schema owns *representation*.

**(3) The durability lint declares its scope, and enforces the set on the delta only.** It states in its own docstring what it checks and what it does not, names the schema as the defining authority, carries a cited copy of the set, and asserts in its self-test that the copy still equals the schema's table.

*Amended in place at this release's Collective Review, before ratification.* The original text read "structural conformance stays unenforced by design until the corpus conformance pass lands", and rejected an enforcing structural rule on the ground that *"the corpus is mid-remediation, so an enforcing structural rule would emit a large body of findings against records the sweep has not reached yet."* **That reason is sound, and it reaches exactly one of the two possible scopings.** A **whole-corpus** structural rule is still rejected, on that ground, unchanged. A **delta-scoped** rule is admitted, because its population over the existing corpus is empty by construction: rule **R5** fires only on a **net-new** ADR that lacks a §3 section, or on a **changed** ADR that has **lost** a section it carried at the diff base. It is silent on a gap that pre-dates the diff base, silent on position, silent on heading-form counts, silent on frozen records, and silent entirely without a diff base — where it reports a visible skip rather than reading green. Warn-mode at the CI surface; the enforce-flip is unchanged and still deferred.

The scoping is measured, not asserted. As of this release's conformance exit, **29 of 111** sweepable records still carried a §3 gap that this release scoped OUT with a named blocking authority — backfilling `## Reversibility`, `## Related ADRs` or `## Consequences` on a ratified record is authoring decision content, which point (2)'s closed forbidden list prohibits. A rule asserting over *changed* files would therefore fire on roughly a quarter of ADR-touching PRs against records nobody is permitted to fix, which is the rejected condition wearing a different hat. The NEW/LOST split keeps the delta posture and keeps the population empty.

## Alternatives Considered

**On the requirement level (T-ADR-1 fired — all four are defensible and the rejected ones will be re-litigated):**

| Option | Verdict | Why |
|---|---|---|
| **Hard-required, unconditional** — every ADR must record weighed options | **Rejected** | Forces vacuous content onto records where a single forced approach genuinely existed, and makes the standard reward writing something rather than writing something true. |
| **Conditional-required** — presence conditional on ≥2 viable options having existed (the originating ticket's own suggestion) | **Rejected** | Its predicate is **not derivable from the artifact**: nothing in an ADR records how many options existed, so no check can ever discharge "no drift between the standard and its linter", and the sweep cannot size its work without per-file judgment. Worse, it re-opens the exact silent opt-out that produced the gap — "only one option existed" becomes an unstated escape hatch. |
| **Required section, conditional content** | **SELECTED** | Keeps everything the conditional option wanted — the author still decides what the section says, and a single forced approach remains a legitimate answer — but moves the conditionality from presence to content, where it is honest and mechanically checkable. Absence becomes a defect; "no alternatives were weighed" becomes a reviewable claim on the record rather than an invisible omission. |
| **Recommended-only** | **Rejected** | Guts the guide's "load-bearing section" claim, checks nothing, and forces two surfaces that already require the field to weaken. |

A fifth option — requiring the section only for ADRs written under the options-weighed trigger — was discarded before evaluation: the trigger that produced an ADR is not recorded in the ADR, so the predicate is underivable from the artifact.

**On the carve-out's shape:**

| Option | Verdict | Why |
|---|---|---|
| **Closed enumerated permit-list** | **Rejected** | Every new hygiene class (a link repoint, a heading normalization) would require a governance change before anyone could perform it. |
| **Open principle only** — "any edit that preserves the recorded decision" | **Rejected** | Unfalsifiable at review time, and scope creep into decision edits is precisely the failure mode the immutability rule exists to prevent. |
| **Invariant + open permit-list + closed forbid-list** | **SELECTED** | Reviewable, because the forbidden list is closed and concrete. Survives the next hygiene class, because new classes test against the invariant. And it is the only shape that resolves the contradiction between "add the missing required section" and "never edit the alternatives" — via the record-vs-revise boundary. |

A fourth option — annotating each hygiene edit in-file with an edit-history note — was discarded before evaluation: it puts mutable content inside the immutable artifact, git already carries that history, and annotating instead of reconciling is a named platform anti-pattern.

**On discharging the standard-vs-linter drift requirement:** adding a **whole-corpus** enforcing structural rule to the lint is **rejected**. The corpus is mid-remediation, so it would emit a large body of findings against records the sweep has not reached yet — the same guarding-before-cleaning hazard that keeps the lint in warn mode. A scope declaration plus a self-tested citation assertion discharges the requirement mechanically without adding a single finding.

| Structural-rule scoping | Verdict | Why |
|---|---|---|
| **Whole-corpus, enforcing** | **Rejected** | Fires on every record the sweep did not reach; guarding before cleaning. Unchanged from the original text. |
| **Over added-or-CHANGED files** | **Rejected on measurement** | Population is not empty: as of this release's conformance exit, 29 of 111 sweepable records carried a §3 gap it scoped OUT with a named blocking authority, so ~26% of ADR-touching PRs would warn about a record nobody is permitted to fix. The whole-corpus objection reaches this scoping too, at lower volume. |
| **Over NET-NEW files + LOST sections** (R5) | **SELECTED** | Both limbs have an **empty population on the existing corpus by construction** — a record the repository has never seen has no condition to grandfather, and a section that vanishes inside a diff is a net-new defect on any corpus. The rejection's own reason does not reach it. Warn-mode; the enforce-flip stays deferred. |
| **A separate net-new checker** | **Rejected** | Would need a second frontmatter parser, a second frozen-record exemption, a second CI job and a second section-set citation to keep pinned to §3. The lint already has all four, and its self-test already pins the copy. |

## Consequences

**Easier.** "Author to the ADR standard" and "bring the corpus to it" name one target. The sweep can size its work by a structural predicate instead of per-file judgment. The sweep's edits become legal, and so do the shipped lint's own remediations. A reader who wondered whether green durability CI implied a conformant ADR now finds that question answered in the tool that would otherwise have implied it. The authority chain makes the recurrence structurally visible: a sixth surface joins a table that tells it to cite rather than restate.

**Harder.** Records for which a single forced approach genuinely existed now carry a short declarative section that adds no decision content — the deliberate price of a checkable predicate over an invisible omission. The lint's self-test acquires a read dependency on the schema; that coupling is real, and it is the honest cost of making the drift assertion mechanical rather than a promise in prose. It degrades to a visible SKIP rather than a silent pass when the schema does not resolve.

**Load-bearing on the carve-out.** The forbidden list is closed, so extending it is a governance change and not a judgment call at edit time. That is intentional, and it means a genuinely new *forbidden* class — as opposed to a new permitted one — needs a superseding record.

**Not changed.** No rule behavior in the durability lint changes, and its corpus verdict is byte-identical before and after. The operations ADR template keeps its own section order, section count, and numbering scope; the two populations share only the alternatives requirement level, because a rendered project ADR that silently omits its alternatives has the same defect regardless of which corpus it lands in.

## Reversibility

**CHEAP.** Content-only across the schema, the authoring guide, the operations template, the intake template, and the lint's docstring plus one additive self-test case. No schema migration, no data change, no deploy step, no skill package rebuild. Revert is a `git revert` on the release merge.

The two halves are independently revertible: the requirement level can be reverted without the carve-out and the reverse. Reverting the carve-out alone would re-block the conformance sweep and re-strand the shipped lint's own findings, so the halves are cheap to unwind separately but not independently useful.

## Related ADRs

- [ADR-027](ADR-027-release-bundle-risk-weight-keys-on-release-class.md) — the authoring guide's named witness for "rejected alternatives recorded". Its options are recorded under a non-canonical heading, which is the evidence that the contract for the section is decision-recall content and not the heading string. Normalizing that heading is a permitted hygiene edit under this record's carve-out.
- [ADR-005](../../release/ADRs/ADR-005-append-pattern-aware-cross-pr-contention-scoring.md) — the canonical worked exemplar named in both ADR READMEs; its alternatives section is the shape the required-content case describes.
- [ADR-062](ADR-062-substrate-vs-canonical-precedent.md) — canonical-spec-edit-wins. Applied here: the originating ticket's surface enumeration and its section-omission figures were both superseded by live state, and the design was rendered against live state while the ticket body was left as historical record.
- Composes with, and does not supersede, the schema/guide boundary: the schema owns the **data contract** (fields, sections, supersession representation) and the guide owns **policy and ergonomics** (when-to-write, template, supersede-not-edit). This record adds a section to the first and a carve-out to the second, and preserves the boundary between them.
