<!-- Binary LLM judge — health-check `rollup` mode (mode 8, v3 slice) -->
# Judge: `rollup` mode (binary)

You are grading the output of the `health-check` skill run in `rollup` mode against a
seeded fixture. Return **PASS** or **FAIL** with a one-line reason. This is a binary judge —
there is no partial credit. `rollup` has three sub-modes; grade against the invocation that
was run.

## Inputs

- The fixture's ground-truth "Expected categorization" block (the seeded drift / rollup
  entities + the seeded-clean items + the expected section for each).
- The skill's actual 5-section output.
- The sub-mode invoked (`--scope portfolio` / `--scope project --depth full` / `--scope project --depth status`).

## PASS criteria — ALL invocations

1. **All five section headers present, in order:** `## Confirmed`, `## Auto-Actionable`, `## Decisions`, `## Unknowns`, `## Rollup-Diffs`. (An empty section reads `_(none)_`.)
2. **Every finding carries a `[confidence: … · S…]` label**, and every decision-class item carries a reversibility tier.
3. **Zero seeded-clean items flagged** — items the fixture marks CLEAN do not appear as findings.
4. **Read-only:** the skill writes no tracker and no bridge file; every proposed change is staged or routed for approval, never applied within the run.

## Invocation A — `--scope portfolio` (compose, not absorb)

PASS only if ALL hold:

1. **Per-project rollup-entity freshness is audited** — the stale PORTFOLIO.md field(s) vs the newer rollup entity are surfaced (the seeded Alpha Phase/Health drift), and the current project row (Beta) is NOT flagged.
2. **Composition is ROUTED to `weekly-status-rollup` Section 6** — the output states the PORTFOLIO.md composition is invoked/routed to `weekly-status-rollup`, and does **NOT** re-derive the portfolio aggregation (the Health-Indicators / Top-Risks field set) inside health-check itself.
3. **The composed PORTFOLIO.md proposal is STAGED** in `08-Generated/_health-check/` and appears in `## Rollup-Diffs` with a reversibility tier.
4. **PORTFOLIO.md is NOT written directly** — no live-file write; the proposal is diff-only/staged.
5. No `TRACKER_UPDATES:` block is emitted for the portfolio bridge-file proposal (it is a `## Rollup-Diffs` item, not a project-tracker update).

**FAIL triggers (any one):** PORTFOLIO.md written directly; the portfolio aggregation re-implemented inside health-check (the ADR-019 absorb anti-pattern) rather than routed to `weekly-status-rollup`; the proposal placed anywhere but `## Rollup-Diffs`/`08-Generated/_health-check/`; the clean project row flagged.

## Invocation B — `--scope project --depth full` (sub-entity scan)

PASS only if ALL hold:

1. **Full sub-entity scan** — the output reflects a scan of the project's Milestones, RAID Items, Plans, and Resources (the four project-entity classes), not just one.
2. **The refreshed rollup entity is proposed via a `TRACKER_UPDATES:` block in `## Auto-Actionable`** — routed to `/tracker-manager` on approval, and **NOT** placed in `## Rollup-Diffs` (that section is reserved for PROJECT.md / PORTFOLIO.md proposals).
3. **Never auto-applied** — the block is emitted for approval; the run does not write the tracker.
4. **Contract-tolerant** — because the portfolio-writeback rollup-contract / rollup entity is not yet shipped, the output surfaces a `## Unknowns` coverage note (schema not yet shipped; fields mapped best-effort) and does **NOT** crash and does **NOT** fabricate a rollup entity as if the contract existed.

**FAIL triggers (any one):** the rollup-entity update placed in `## Rollup-Diffs`; the update auto-applied; a crash or an invented rollup entity on the absent contract; only one sub-entity class scanned.

## Invocation C — `--scope project --depth status` (quick status refresh)

PASS only if ALL hold:

1. **Status-fields-only** — the refresh touches only the rollup entity's `status` field(s); it does **NOT** perform a full Milestones/RAID/Plans/Resources re-derivation. This is the load-bearing **distinctness** assertion: `--depth status` is observably lighter than `--depth full`.
2. **Same `TRACKER_UPDATES:` routing** — the proposed status change lands in a `TRACKER_UPDATES:` block in `## Auto-Actionable`, never auto-applied, never in `## Rollup-Diffs`.
3. **Contract-tolerant** — the absent contract degrades to a `## Unknowns` coverage note, never a crash or fabrication.

**FAIL triggers (any one):** behavior indistinguishable from `--depth full` (a full sub-entity re-derivation); the update auto-applied or mis-routed to `## Rollup-Diffs`; a crash/fabrication on the absent contract.

## Verdict

`PASS` — the invocation's criteria all hold AND the ALL-invocations criteria hold. Otherwise `FAIL` with the first violated criterion cited.
