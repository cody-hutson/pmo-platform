---
title: ADR-001 — Cross-PR Overlap Audit baseline policy when open-PR set is empty
status: Accepted
date: 2026-05-01
release: file-overlap-audit
deciders: "cody-hutson (operator) + Stage 5 Solutioning spoke"
tags: [audit, baseline, release-ops, file-overlap]
source_observations:
  - "Operator observation 2026-05-01 — first encounter of the empty open-PR set condition during a cross-PR file-overlap audit. `gh pr list --state open` returned `[]` at the audit-start commit SHA. The single-operator workspace produces bursty open-PR populations (commonly 0 or 1 open at any moment) — the empty-target-population condition is the expected default state between merges, not an exception. Recorded as N=1 of theme `audit-baseline-when-target-population-is-empty` and surfaced into Stage 5 Solutioning as the trigger for this ADR."
---

# ADR-001 — Cross-PR Overlap Audit baseline policy when open-PR set is empty

## Status
Accepted (promoted from Proposed at Stage 6 Engineering Commit
2026-05-01). Stage 5 design output; promotes to Accepted at
release-plan commit per ADR governance convention.

## Context

Stage 4 file contention resolution (release-process.md / pipeline/stage-04-planning.md
§5 A4) presumes cross-PR contention exists in live open PRs. The
historical schema for contention analysis was scoped to
`gh pr list --state open` results — fine when the open-PR set is non-empty.

On 2026-05-01, `gh pr list --state open` returned `[]`. This is
the first encounter of the "empty-target-population" condition. Two failure
modes:
- **(a)** the audit fails silently — zero data → no findings → false-negative
  HIGH-file flags at downstream Stage 5 design surface analysis
- **(b)** ad-hoc per-audit decisions — each audit operator chooses a different
  baseline; outputs not comparable across releases

The single-operator workspace produces bursty open-PR populations (often 0-1
open at any moment). The empty condition is not exceptional — it is the
expected default state between merges.

## Decision

**Hybrid baseline = (last-N merged PRs sorted by `mergedAt`, descending)
∪ (open PRs at audit-start commit SHA).**

- **Default N = 20** — covers ~6 days at current cadence (~3-4 PRs/day)
- **SHA pin** — at audit start, `git rev-parse HEAD` recorded in
  SUMMARY.md header `audit_baseline_sha:` field
- **Open-PR drift handling** — live-read at SUMMARY.md write time; drift
  documented in SUMMARY.md methodology section

Tooling: `gh pr list --state merged --limit 20 --search
'sort:updated-desc' --json number,state,mergedAt,title,files,url`.

## Consequences

**Positive:**
- Audits produce non-trivial findings even when open-PR set is empty;
  merged-PR cadence gives statistical signal
- Baseline policy is deterministic and reproducible across audit re-runs
- Schema (`pr_state` enum: merged|open) accommodates both states without
  forking the format
- N is tunable per-audit; future audits adjust based on observed cadence

**Negative:**
- Merged-PR signal is retrospective (already-merged conflicts don't predict
  future conflicts directly; they signal hot files)
- Introduces "what's N" tunability requiring per-audit defense
- Mixing merged + open in one matrix conflates two semantically-different
  populations; analysts must read `pr_state` to disambiguate

**Mitigation of negatives:**
- N=20 defended by current cadence (~6-day window); SUMMARY.md methodology
  section documents the cadence-window rationale
- Tunability is a desirable feature for evolving release cadence, not a bug
- Schema column `pr_state` is mandatory; downstream analysts filter by state
  when conflation would mislead

## Alternatives Considered

- **(A) Defer audit until concurrent open-PR work** — REJECTED. Loses signal
  from recent merges; doesn't help if open-PR cadence stays at 0 (likely
  for solo-operator workspace). Indefinite deferral risk.
- **(B) Open-PR-only baseline** — REJECTED. Zero data when open-PR set is
  empty (the observed case). Audit produces no findings; false-negative.
- **(C) Hybrid (selected).**
- **(D) Synthesized PR list from forward-looking milestones** — REJECTED.
  Speculative; not actual contention data; risks confirmation bias (audit
  finds the contention the auditor expected).

## Reversibility

CHEAP — analysis artifacts can be regenerated with a different baseline
policy. Source observations remain in the observation log; ADR can be
superseded by ADR-NNN with new policy.

## References

- Source observation: observation-log theme
  `audit-baseline-when-target-population-is-empty` (2026-05-01, N=1)
