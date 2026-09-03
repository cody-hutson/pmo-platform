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

Every cell is a single backticked token. **`entrypoint` is a bare repo-relative path, never a markdown link** — the path is stated from the repository root so it resolves identically for every consumer, and a link carrying a root-relative target reads as broken to the platform's link checker, which resolves relative to the source file and has no workspace-root fallback.

### Reading a row

- **`cadence` is the cadence the platform ships, not the schedule that runs.** The effective schedule is instance-local, resolved by the scheduler adapter from the operator's own registration. The row declares; the instance resolves.
- **`reversibility` is of the routine's actions at its declared level**, not of shipping the document named by `entrypoint`. The two legitimately differ — the intake sweep's own spec document is `MODERATE` to ship, while what the sweep does at `recommend` is `CHEAP`.
- **`automation_level_default` is a ceiling, not an effective value.** Effective autonomy is `min(automation_level, per-action max)`, with the operator's dial and the irreducible-human-task floor applying above it.

### Authoring notes on the rows above

- `ambient-intake-sweep` — its own spec states the cadence semantically (once daily, at an early-morning local hour) rather than as a literal expression, because the cadence is an operator-configurable registration parameter. `0 6 * * *` is this registry's `[RECOMMENDED]` rendering of that statement, and an operator whose registration differs is not in drift.

## Sources of truth — do not duplicate here

Three facts about every routine belong to other surfaces, and copying any of them into a row is a defect rather than a convenience.

| Fact | Where it lives | Why it is not a column |
|---|---|---|
| **which backend actually fires the routine** | the `scheduler` selector on the operator-configuration adapter table, read by the scheduler adapter at fire time | it is instance-local and permission-restricted; a git-tracked copy writes a non-portable fact into public corpus, which is the leak this registry exists to close |
| **the effective automation level** | computed as `min(automation_level, per-action max)` against the operator's dial | a stored effective value drifts the instant the operator moves the dial |
| **what the routine actually does** | the tracked document named by `entrypoint` | a row that restates the behavior contract can drift from it; a row that points at it cannot |
