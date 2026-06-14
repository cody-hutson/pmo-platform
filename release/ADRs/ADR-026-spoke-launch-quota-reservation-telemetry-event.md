---
title: "ADR-026 — Per-spoke quota telemetry: a new `spoke-launch` event_type, not a `test-run` payload key"
status: Proposed
date: 2026-06-13
release: parallel-launch-quota-budget-gate
deciders: "Stage 5 Solutioning (Principal Engineer — Architecture Assessment) D-EventTelemetrySurface; rendered at Collective Review scope-lock"
tags: [architecture, telemetry, pipeline-event-log, quota-budget, schema-governance]
source_observations:
  - "The quota-budget gate's per-spoke cost estimate (Checkpoint A input + Checkpoint B refinement) consumes per-spoke startup-token telemetry, but the event-log schema § 3 enum has no spoke-completion or spoke-launch event_type — the term `spoke-completion` is Procedure-4 prose only."
  - "The candidate of carrying `tokens_used:` as a payload key on the existing `test-run` event is mechanically unwritable: append-pipeline-event.sh makes --event-subtype mandatory and enum-validates it, and the only legal test-run subtypes are suite-pass / suite-fail / suite-skip. A spawn-time reservation has no honest test-run subtype, so the route either dies or emits a false suite-pass that poisons the canonical suite query and the Stage-13 synthesizer JOIN."
  - "The schema § 3 governance rule states that adding a subtype requires a governance change; there is therefore no zero-surface telemetry route — the cheapest honest surface is a two-surface edit (schema § 3 enum row + the append-pipeline-event.sh static-fallback mirror kept in lockstep with § 3)."
---

# ADR-026 — Per-spoke quota telemetry: a new `spoke-launch` event_type, not a `test-run` payload key

## Status
Proposed — rendered at the D-EventTelemetrySurface gate during Stage 5 Solutioning
for the parallel-launch-quota-budget-gate release; carried to Collective Review
scope-lock for operator render. (Numbering: platform-global monotonic. Renumbered
from the draft ADR-024 to ADR-026 at merge time — the concurrent
`cross-release-impact-model` release claimed ADR-024 and the `sior-escalation`
release claimed ADR-025, so this telemetry ADR resumes the release-scoped thread at
the next-free slot ADR-026.)

## Context
The dual-checkpoint quota-budget gate estimates a parallel batch's cumulative
usage-window draw from a per-spoke cost estimate. Until telemetry exists the
estimate is a size-bucket heuristic; the estimate becomes accurate only once the
pipeline records *observed* per-spoke startup-token consumption. That telemetry
needs a home in the pipeline-event-log schema.

The schema § 3 event-type enum carries no per-spoke event. The term
`spoke-completion` appears only in Procedure-4 prose of the hub-spoke bridge — it
is not an enum value. So the telemetry surface is genuinely net-new, and the
schema's own governance rule ("adding a subtype requires a governance change")
means it cannot be added silently.

A lighter-looking alternative — carrying a `tokens_used:` key in the payload of
the existing `test-run` event — fails on the writer contract. The writer
`append-pipeline-event.sh` makes `--event-subtype` mandatory and enum-validates
it; the only legal `test-run` subtypes are `suite-pass` / `suite-fail` /
`suite-skip`. A spawn-time quota reservation has no honest `test-run` subtype, so
the payload-key route either aborts (`die`) or is forced to emit a false
`suite-pass` — which would poison both the canonical suite query
(`--event-subtype suite-pass`) and the Stage-13 release-synthesizer's `test-run`
JOIN. There is therefore no zero-surface route; the cheapest *honest* surface is a
two-surface coordinated edit.

## Decision
Add a new top-level `event_type = spoke-launch` with a single subtype
`quota-reservation`, carrying `tokens_used:` in the payload. This is a two-surface
change that must land together:

1. **Schema § 3 enum table** (`pipeline-event-log-schema.md`) — a new row defining
   `spoke-launch` / `quota-reservation`; the data-driven source of truth the writer
   parses at runtime.
2. **`append-pipeline-event.sh` static-fallback mirror** (`_FALLBACK_SUBTYPES_LINES`)
   — a new `spoke-launch\tquota-reservation` line, kept in lockstep with § 3. The
   schema is the data-driven source; the mirror is the offline fallback used only
   when the schema file is unreadable (invoked outside the repo tree).

The event fires at spoke-launch time on the parallel-safe stages (5 / 7 / 8); its
`tokens_used:` payload feeds the quota-budget protocol's per-spoke cost estimate
(Checkpoint B refinement; the heuristic's eventual replacement by observed
medians).

## Alternatives considered and rejected
- **`tokens_used:` payload key on the existing `test-run` event** (the lightest
  on paper, "zero-surface"): rejected as mechanically unwritable. `--event-subtype`
  is mandatory and enum-validated; `test-run` admits only `suite-pass/fail/skip`. A
  reservation has no honest subtype, so the route dies or emits a corrupting false
  `suite-pass`. The "zero-surface" framing modeled only the payload column and
  missed the writer's mandatory-subtype guard.
- **A new `test-run`-adjacent subtype `startup-cost`** (the strongest surviving
  alternative — one enum row, no new top-level type, queryable via
  `--event-subtype startup-cost`): rejected on semantics + query-isolation. A
  spawn-time quota reservation is not a runtime code-test-suite execution; folding
  it under `test-run` re-overloads the type whose schema-defined scope is "Runtime
  code-test suite execution at Stage 6/7." A dedicated `event_type` keeps the
  canonical suite query and the Stage-13 synthesizer's `test-run` JOIN
  uncontaminated and reads honestly at spoke-launch time. Both options pay the
  identical two-surface + ADR cost; the new event_type wins on semantic honesty and
  query isolation. (This option is sound and equally ADR-warranted if the operator
  prefers the lighter subtype.)

## Consequences
- The event-type enum grows from 10 to 11 values; the schema heading count and the
  frontmatter purpose line are updated in lockstep.
- The two surfaces must stay synchronized — the schema § 3 row is the source of
  truth; the static mirror is the offline fallback. Drift between them is caught by
  the writer's `--self-test` (it reports the enum source and event-type count) and
  by the schema-vs-mirror lockstep discipline already documented in the script.
- The telemetry is additive and backwards-compatible: existing event types and
  queries are unchanged; readers that do not know `spoke-launch` simply ignore the
  new rows.
- The quota-budget gate's per-spoke cost estimate has a defined telemetry input;
  the heuristic (size-bucket bands) is replaced by observed medians once the event
  accumulates a distribution.

## Reversibility
MODERATE — the surface is a two-surface coordinated revert (drop the schema § 3
row + the mirror line + restore the count). Confidence HIGH on mechanism: the
writer contract is verified executable evidence (`--event-subtype` mandatory +
enum-validated; legal `test-run` subtypes = suite-pass/fail/skip only), and the
`--self-test` confirms the new type round-trips through both the data-driven and
fallback paths.

## Related ADRs
None upstream. Platform-global monotonic numbering: this ADR landed at ADR-026
(renumbered from the draft ADR-024) after the concurrent `cross-release-impact-model`
(ADR-024) and `sior-escalation` (ADR-025) releases claimed the intervening slots.
