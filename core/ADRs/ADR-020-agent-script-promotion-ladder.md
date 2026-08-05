---
title: "ADR-020 — Agent-script promotion ladder: form-anchored five-rung enum (AS0–AS4)"
status: Accepted
date: 2026-06-11
release: v1.09
deciders: "Stage 5 Solutioning (Principal Engineer — Architecture Assessment) + operator at the 2026-06-10 Stage 5 scope-lock"
tags: [architecture, governance, automation, promotion-ladder, script-estate]
source_observations:
  - "Current-state survey at 3f91d05: five distinct implementation forms live in the estate (prose procedure / documented command block / tracked agent-invoked tool / checkpoint-wired primitive / event-triggered guard), each with members; no governed vocabulary names them. Re-verified at the v1.09 audit SHA 353ad8b — census 71 tracked scripts (47 sh / 24 py) reproduces exactly."
  - "gate-criteria-spec.md Check enum (structural/metrics/judgment) classifies work class, not implementation form — a structural check lives at any of three forms; overloading it as a ladder would leak a parallel vocabulary."
  - "autonomy-tiers.md §Tier Disambiguation manages four numbered tier conventions and forbids bare-tier citations — a fifth unprefixed 'Tier' vocabulary was a hard constraint on naming."
---

# ADR-020 — Agent-script promotion ladder: form-anchored five-rung enum (AS0–AS4)

## Status

Accepted — operator-ratified at the v1.09 Stage 5 scope-lock (2026-06-10), the
single-issue-release equivalent of Collective Review per the Status enum in
core/ADRs/README.md ("Operator-ratified at Collective Review or equivalent gate").
Drafted Proposed by the v1.09 Stage 5 Solutioning spoke; the scope-lock verdict
(RATIFY + FOLD ALL 8) promoted it and folded the adversarial-review refinements,
including the caller-type AS2/AS3 boundary test recorded under Consequences below.

## Context

The agent-to-script promotion framework needs a target vocabulary for "how
scripted is this pattern." Four genuinely distinct shapes were generated and
narrowed at Stage 5:

- **(A) 5-rung form-anchored enum** — rungs encode the implementation form of
  the work: prose procedure → documented command → tracked tool →
  checkpoint-wired → autonomous guard.
- **(B) Reuse of the gate-criteria Check enum** (structural / metrics /
  judgment) as the ladder.
- **(C) 4-rung collapse** merging documented-command into agent-procedure.
- **(D) Continuous readiness score** (0–100, no discrete rungs).

Constraints that shaped the narrowing: the parent work item's acceptance
criteria require a discrete, schema-validatable "target promotion level" value
(kills D — a continuous score cannot populate the field deterministically, and
decision tables cannot branch on it); the duplicate-source discipline and the
skill-pipeline-alignment standard's parallel-vocabulary decision-test forbid
overloading an existing enum with second semantics (kills B — the Check enum
classifies what kind of check a criterion is, not what form its implementation
takes); and the autonomy-tiers disambiguation table forbids a fifth bare-numbered
tier vocabulary (drives the `AS` prefix, which a corpus collision grep confirmed
free). The 4-rung collapse (C) survived to the trade-off matrix and lost on
estate evidence: the documented-command rung has real current members (the
composite-OR detection blocks, the parser-clean pre-submit grep, the native-dep
mirror pseudocode), and prose→command-block is the cheapest, most common first
promotion — collapsing it erases the rung where most promotions begin.

## Decision

Adopt the form-anchored five-rung enum **AS0** (agent procedure) / **AS1**
(documented command) / **AS2** (tracked tool, agent-invoked) / **AS3**
(checkpoint-wired) / **AS4** (autonomous guard), with the split-promotion rule:
judgment-class steps (per the gate-criteria Check enum) promote only their
evidence-gathering substrate; structural/metrics steps may promote fully. The
canonical definition lives in core/standards/agent-script-promotion-framework.md.

## Alternatives Considered

Recorded from this record's own § Context, which generates four candidate shapes at Stage 5 and states the constraint that eliminated each.

| Option | Verdict | Why |
|---|---|---|
| **(A) 5-rung form-anchored enum** (prose procedure → documented command → tracked tool → checkpoint-wired → autonomous guard) | **SELECTED** | Discrete and schema-validatable; every estate member classifies into exactly one rung; the cheapest and most common first promotion keeps its own rung. |
| **(B) Reuse of the gate-criteria Check enum** (structural / metrics / judgment) | Rejected | The duplicate-source discipline and the skill-pipeline-alignment standard's parallel-vocabulary decision-test forbid overloading an existing enum with second semantics — the Check enum classifies what kind of check a criterion is, not what form its implementation takes. |
| **(C) 4-rung collapse** merging documented-command into agent-procedure | Rejected — survived to the trade-off matrix | Lost on estate evidence: the documented-command rung has real current members, and prose→command-block is the cheapest, most common first promotion, so collapsing it erases the rung where most promotions begin. |
| **(D) Continuous readiness score** (0–100, no discrete rungs) | Rejected | The parent work item's acceptance criteria require a discrete, schema-validatable target-promotion-level value; a continuous score cannot populate the field deterministically and decision tables cannot branch on it. |

A related vocabulary constraint shaped the naming rather than the shape: the autonomy-tiers disambiguation table forbids a fifth bare-numbered tier vocabulary, which drove the `AS` prefix (confirmed collision-free by a corpus grep).

## Consequences

Positive: every estate member classifies into exactly one rung
(census-verified at the audit SHA); the cheapest promotion step (prose→command
block) is first-class; the AS prefix is corpus-collision-free; per-rung
requirement tables (testing/drift/review) attach cleanly.

Negative: a new enum to maintain; rung-boundary calls at the AS2/AS3 seam —
mitigated by the **caller-type boundary test** adopted at the scope-lock (a
script is AS3 iff its invoker is another governed executable; AS2 iff
agent-invoked; at AS3/AS4 the audit derives `invocation_path` from the caller
registration rather than citation topology), which makes the seam mechanically
checkable; renaming rungs after downstream citation accumulates becomes a
coordinated sweep (see Reversibility).

## Reversibility

CHEAP at ship (the framework standard owns the enum definition; git revert).
At ship the rung literals already appear on several tracked surfaces authored
in the same release (the framework doc, this ADR's title and body, the
framework-catalog row's scope text, the release plan) — a day-one rename is a
small same-release coordinated edit, hours-scale, still CHEAP. The tier trends
**MODERATE** as downstream artifacts (audits, inventories, promotion decisions)
accumulate rung citations — a later rename becomes a coordinated sweep across
the framework, audit artifacts, and every promotion decision line. That drift
is the reason this decision is ADR-recorded.

## Related ADRs

- ADR-011 (analysis-class methodology treatment) — the audit that grounds the
  ladder ran under its Research-Methodology variant.
- ADR-019 (specialists-compose-not-absorb) — the ladder composes with, not
  absorbs, the Check-enum work-class axis; the same compose-don't-overload
  discipline applied to vocabulary instead of skills.
