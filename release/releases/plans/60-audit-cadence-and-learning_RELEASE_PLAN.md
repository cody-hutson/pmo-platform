# Release Plan — 60-audit-cadence-and-learning (v2.39)

> **Plan-of-record** for the v2.39 audit-cadence-and-learning release. Three issues establish the platform's self-assessment cadence (two audit-cadence axes) plus a recommendation↔choice learning-capture surface. Planned via release-hub Mode O (Stage 4 Planning + Stage 5 Solutioning seeds recorded in the issue bodies + milestone #151 description); this plan-of-record is the canonical `plans/` backfill of that planning. Class **novel**, 18 effective pts (raw 16 ×1.15), dependency-clean.

## Summary

Three work items on one coherent theme — the platform's continuous-improvement loop at two grains:

- **#167** — release process-fitness audit cadence (PMBOK 7 / DORA / Stage-Gate / ITIL 4 / Lean / CD axis)
- **#168** — structural audit cadence (Diátaxis / NARA / ISO 15489 / ADR / Keep-a-Changelog axis)
- **#46** — recommendation↔choice delta capture + retrospective look-back surface

Two new protocol docs + a new `event_subtype` (+ tool/reference edits) + a shared 3-axis cross-reference. Release Class **novel** (trigger a: ≥1 new reference doc/schema). Milestone = one PR / one merge (integration PR #2421).

## Dependency graph

Dependency-CLEAN — every prerequisite is CLOSED (#181, #979, #358, #161, #169); zero in-bundle edges among the three cards (external-dep count 0, target ≤2 satisfied). #167 and #168 are co-author axis-siblings (shared cadence-doc skeleton, distinct rosters). #46 is synthesis-last (composes-with multiple sibling surfaces + the shipped decision-confidence pause-to-learn).

- **Deferred (different capability):** #912 (cross-chain architecture index) — OPEN, intentionally not bundled.
- **Trimmed at pre-flight (2026-06-29):** #1097 (as-built architecture-conformance audit) — was deferred + dep-blocked on #912 + not in the declared card set.
- **Filed for a later release:** #2423 (per-session self-retrospective — the session-grained learning counterpart).

## Implementation sequence (commit order on ONE branch)

| # | Issue | Size | Why here |
|---|---|---|---|
| 1 | #167 | M (4) | Cadence axis; foundation; issue-number-asc among the two siblings |
| 2 | #168 | M (4) | Cadence axis sibling; co-authored from the shared skeleton |
| 3 | shared | — | 3-axis cross-ref into `platform-health-audit-framework.md` (completes once both docs exist) |
| 4 | #46 | L (8) | Synthesis-last — composes-with multiple surfaces + the shipped pause-to-learn |

## Design approach (from Stage 5 Solutioning seeds)

**#167 / #168 — shared cadence-doc skeleton.** One parameterized 8-section skeleton (purpose+scope-boundary / event triggers / 90-day fallback / analysis-folder output / benchmark continuity / mechanism / cross-refs / reversibility), instantiated per axis. Each states it is the *when-to-re-run* cadence layer atop `AUDIT_FRAMEWORK.md`'s how-to-run methodology. **Mechanism: HYBRID** — manual event-triggers + an `mcp__scheduled-tasks` 90-day staleness sentinel (mirrors the live Anthropic-axis cron+sentinel split; sentinel registration is operator-instance).

**#46 — recommendation↔choice delta capture.** A new `event_subtype = recommendation-choice-delta` under `event_type=decision` in the pipeline-event-log (4-tuple in payload: rec/chose/delta/why + via-provenance), a `--window` look-back read-model, and a Stage-13 Phase A7.1 roll-up into the F7 retro register. **Signal-only** — aggregated patterns promote to an `improvement.yml` CANDIDATE via the governance gate, never an auto-change. Re-confirmed orthogonal to decision-confidence pause-to-learn (forward gate vs retrospective capture; pause-to-learn E3 escalations *feed* #46).

## Release Outcome Statement

See milestone #151 description (the canonical Outcome Statement: AFTER/BEFORE + Release Class + sequence + dependency resolution).

## Execution note (Stage 12 remediation)

The integration merge (PR #2421) initially landed via a hub-driven `gh pr merge` that skipped the documented Stage-12 B3 (signed-tag claim) + B5 (DEPLOYED RELEASE_LOG row) steps. Both were completed as a remediation on 2026-06-29 (tag `v2.39` at merge SHA `711f81d`; DEPLOYED row via chore PR #2430), then Stage 13 close-out ran. The durable Mode-O fix (route Stage 12 through the tail / enforce a preflight guard) is tracked in #2428.

## Reversibility

CHEAP / HIGH — two additive protocol docs + one additive `event_subtype` + a read-only tool flag + a reference-shard edit + one cross-reference paragraph. No data migration, no breaking change; the capture surface + look-back are signal-only. Whole-release rollback = `git revert -m 1` of PR #2421.
