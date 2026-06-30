<!-- Binary LLM judge — health-check `timeline` mode -->
<!-- repo-integrity: allow-issue-ref -->
# Judge: `timeline` mode (binary)

You are grading the output of the `health-check` skill run in `timeline` mode against a seeded-drift fixture. Return **PASS** or **FAIL** with a one-line reason. Binary judge — no partial credit. `timeline`'s load-bearing behaviors are day-of-week validation and the refusal of generalized dates (#1125 AC-4).

## PASS criteria (ALL must hold)

1. **Five section headers present, in order** (empty sections read `_(none)_`).
2. **Every seeded date drift surfaced** and placed in the correct section by confidence/band — a two-source-corroborated date mismatch (HIGH, S2) in `## Auto-Actionable` with a `TRACKER_UPDATES:` row; a single-source or unresolved date mismatch in `## Decisions`; an unverifiable date in `## Unknowns`.
3. **Day-of-week validated on every reported date** — where the fixture seeds a weekday/date mismatch (e.g., "Wednesday April 2" when April 2 is a Thursday), the output flags it as a finding; where the weekday is correct (e.g., "Friday April 17"), it is NOT flagged for that reason.
4. **No generalized date range in the body** — the output never reports a project date as "week of …", "early …", or any relative range; an unverifiable date is surfaced in `## Unknowns` with what was searched, not generalized.
5. **`TRACKER_UPDATES:` block present iff there is an `## Auto-Actionable` date finding.**
6. **Zero seeded-clean dates flagged.**
7. **Every finding carries a `[confidence: … · S…]` label**; a currency mismatch is `S2` (not `S3` on elapsed time alone).

## FAIL triggers (any one)

- A weekday/date mismatch the fixture seeded is NOT flagged (the headline `timeline` failure).
- A generalized date range appears in the output body.
- A correct weekday is wrongly flagged as a mismatch (false positive).
- A single-source date finding shipped as `## Auto-Actionable`.
- Missing/reordered section header, or `TRACKER_UPDATES:` present/absent inconsistently with `## Auto-Actionable`.

## Verdict

`PASS` — all seeded date drifts correctly categorized, day-of-week validated, no generalized range, zero clean false-flags. Otherwise `FAIL` with the first violated criterion cited.
