---
title: Automation Registry — the routine-spec rows
purpose: The platform's catalog of recurring automations, one routine-spec row each, declaring what runs on what cadence invoking what entrypoint under what governance ceiling. This is the admission surface — an automation is governed only if it has a row here that validates against the routine-spec contract.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: core/deploy/tools/check-automation-registry.sh (validates every row against the contract); the registry-currency gate (asserts every automation the platform ships has a row); the scheduler adapter (reads a row's declared cadence and entrypoint at fire time)
---
<!-- reference-durability: allow-link -->
# Automation Registry

**Purpose:** The routine-spec rows. Each row declares one recurring automation.
**Contract:** [`core/schemas/automation-registry-schema.md`](../schemas/automation-registry-schema.md) — the field list, the closed value spaces, the cross-field rules and the rejection classes. This file carries rows, never contract.
**Layer:** 1 (Engineering, git-tracked)

**The registry is the admission gate.** An automation is admitted only if it has a row here that validates. A registry with no admission predicate has no forcing function, and its coverage decays to whatever the last author remembered.

## Routines

| id | cadence | trigger | entrypoint | automation_level_default | reversibility |
|---|---|---|---|---|---|
| `ambient-intake-sweep` | `0 6 * * *` | `time-driven` | `core/standards/c2-intake-sweep-path-a.md` | `recommend` | `CHEAP` |
| `security-scan` | `0 6 * * 1` | `time-driven` | `.github/workflows/security.yml` | `bounded_auto` | `CHEAP` |
| `external-sync-path-b` | `0 6 * * *` | `time-driven` | `core/standards/c3-external-sync-path-b.md` | `recommend` | `CHEAP` |
| `architecture-conformance-sentinel` | `0 9 * * 1` | `hybrid` | `release/references/protocols/architecture-conformance-cadence.md` | `recommend` | `CHEAP` |
| `process-fitness-sentinel` | `0 9 * * 1` | `hybrid` | `release/references/protocols/process-fitness-cadence.md` | `recommend` | `CHEAP` |
| `structural-audit-sentinel` | `0 9 * * 1` | `hybrid` | `release/references/protocols/structural-audit-cadence.md` | `recommend` | `CHEAP` |
| `decision-audit-sentinel` | `0 9 * * 1` | `hybrid` | `release/references/protocols/decision-audit-cadence.md` | `recommend` | `CHEAP` |
| `platform-health-quarterly-audit` | `0 9 1 1,4,7,10 *` | `hybrid` | `release/references/protocols/platform-health-audit-framework.md` | `recommend` | `CHEAP` |
| `platform-health-drift-watch` | `0 9 * * 1` | `time-driven` | `release/references/protocols/platform-health-audit-framework.md` | `recommend` | `CHEAP` |

Every cell is a single backticked token. **`entrypoint` is a bare repo-relative path, never a markdown link** — the path is stated from the repository root so it resolves identically for every consumer, and a link carrying a root-relative target reads as broken to the platform's link checker, which resolves relative to the source file and has no workspace-root fallback.

### Reading a row

- **`cadence` is the cadence the platform ships, not the schedule that runs.** The effective schedule is instance-local, resolved by the scheduler adapter from the operator's own registration. The row declares; the instance resolves.
- **`reversibility` is of the routine's actions at its declared level**, not of shipping the document named by `entrypoint`. The two legitimately differ — the intake sweep's own spec document is `MODERATE` to ship, while what the sweep does at `recommend` is `CHEAP`.
- **`automation_level_default` is a ceiling, not an effective value.** Effective autonomy is `min(automation_level, per-action max)`, with the operator's dial and the irreducible-human-task floor applying above it.

### Authoring notes on the rows above

- `ambient-intake-sweep` — its own spec states the cadence semantically (once daily, at an early-morning local hour) rather than as a literal expression, because the cadence is an operator-configurable registration parameter. `0 6 * * *` is this registry's `[RECOMMENDED]` rendering of that statement, and an operator whose registration differs is not in drift.
- `external-sync-path-b` — the C3 sweep, registered alongside `ambient-intake-sweep` by the same install step, which states one cadence covering both. It therefore takes the **identical** `0 6 * * *` default rather than an invented offset; an offset would be precision the corpus does not carry. Its `reversibility` is `CHEAP` while its spec document's own frontmatter reads `MODERATE` — the split the contract predicts, and the first row to exhibit it: shipping the spec is the `MODERATE` act, while what the sweep does at `recommend` is emit a proposal and write a git-ignored snapshot.
- **The four `-sentinel` rows** — the 90-day staleness sentinels of the audit-cadence set, one per axis. Their `0 9 * * 1` cadence is **`[RECOMMENDED]`**, not in-corpus: hour 9 is inherited from the `platform-health` row below, which carries it verbatim, and Monday matches the tree's only other weekly cron. **The 90-day figure in each spec is a threshold, not a period** — a sentinel that woke only once its own threshold elapsed could not detect that the threshold elapsed, and cron cannot express 90 days in any case. A weekly poll bounds detection latency at 7 days. `cadence` is a declared default, so an instance resolving a different schedule is not in drift.
- **`platform-health-*` — two rows, one entrypoint, and that is the shape the marker is list-valued for.** The framework document declares a quarterly cadence and a reactive drift-watch as separate registrations, so its `automation_id` carries both ids and each gets its own row; a scalar marker could not express it without splitting a document whose two routines genuinely share one policy. The quarterly row's `0 9 1 1,4,7,10 *` is **verbatim in-corpus**. The two rows differ on `trigger`: the quarterly audit is `hybrid` (its own mechanism section carries a manual limb beside the automated one), while `platform-health-drift-watch` is `time-driven` — the drift-trigger taxonomy is what it **detects**, not what **fires** it. Both carry a cron either way, so the cross-field matrix holds under either reading.
- `security-scan` — **self-firing.** Its entrypoint is a workflow path, so the host fires it on the cadence written in the workflow's own `schedule:` block and the scheduler adapter must NOT also register it; a second registration would double-fire it. That is derivable from `entrypoint` and needs no field (schema § 8). Its `cadence` is therefore not a `[RECOMMENDED]` default like the row above but a **mirror of a value the host already enforces**, and the two are asserted equal rather than left to drift. It is also the first row whose routine is not a PMO cadence, which is the point: the six fields carry a scheduled scanner with nothing widened — `trigger` is `time-driven` because the schedule is what registers, not the push and pull-request limbs the workflow also carries. `bounded_auto` records that the scan runs and reports unattended within a declared scope; it opens no pull request and merges nothing.

## Sources of truth — do not duplicate here

Three facts about every routine belong to other surfaces, and copying any of them into a row is a defect rather than a convenience.

| Fact | Where it lives | Why it is not a column |
|---|---|---|
| **which backend actually fires the routine** | the `scheduler` selector on the operator-configuration adapter table, read by the scheduler adapter at fire time | it is instance-local and permission-restricted; a git-tracked copy writes a non-portable fact into public corpus, which is the leak this registry exists to close |
| **the effective automation level** | computed as `min(automation_level, per-action max)` against the operator's dial | a stored effective value drifts the instant the operator moves the dial |
| **what the routine actually does** | the tracked document named by `entrypoint` | a row that restates the behavior contract can drift from it; a row that points at it cannot |
