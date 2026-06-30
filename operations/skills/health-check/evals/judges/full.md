<!-- Binary LLM judge — health-check `full` mode -->
# Judge: `full` mode (binary)

You are grading the output of the `health-check` skill run in `full` mode against a seeded-drift fixture. Return **PASS** or **FAIL** with a one-line reason. This is a binary judge — there is no partial credit.

## Inputs

- The fixture's ground-truth "Expected categorization" block (the seeded drifts + the seeded-clean items + the expected section for each).
- The skill's actual 5-section output.

## PASS criteria (ALL must hold)

1. **All five section headers present, in order:** `## Confirmed`, `## Auto-Actionable`, `## Decisions`, `## Unknowns`, `## Rollup-Diffs`. (An empty section reads `_(none)_`.)
2. **Every seeded drift surfaced** — each appears somewhere in the output.
3. **Every seeded drift in the correct section** per its expected confidence/band: the multi-source date disagreement (HIGH, two agreeing sources) in `## Auto-Actionable`; the owner replacement candidate (MEDIUM) in `## Decisions`; the empty-owner item in `## Unknowns`; the Rollup-Diff staged (not written) in `## Rollup-Diffs`.
4. **`TRACKER_UPDATES:` block present iff there is an `## Auto-Actionable` item** — and absent if `## Auto-Actionable` is `_(none)_`.
5. **Day-of-week + no-generalized-dates honored** for any date finding `full` surfaces (it runs the `timeline` checks): a wrong weekday is flagged; no date is reported as a range.
6. **Zero seeded-clean items flagged** — the items the fixture marks CLEAN do not appear as findings.
7. **Every finding carries a `[confidence: … · S…]` label.**

## FAIL triggers (any one)

- A missing or reordered section header.
- A seeded drift not surfaced, or surfaced in the wrong section (especially a single-source or degraded finding landing in `## Auto-Actionable`).
- A `TRACKER_UPDATES:` block emitted with no `## Auto-Actionable` item, or missing when one exists.
- A seeded-clean item flagged as drift (false positive).
- A generalized date range in the body, or an unvalidated weekday.
- A Rollup-Diff written to a live file rather than staged.

## Verdict

`PASS` — all seeded drifts correctly categorized AND zero seeded-clean false-flags. Otherwise `FAIL` with the first violated criterion cited.
