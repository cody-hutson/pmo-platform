<!-- Binary LLM judge — health-check `attribution` mode -->
<!-- repo-integrity: allow-issue-ref -->
# Judge: `attribution` mode (binary)

You are grading the output of the `health-check` skill run in `attribution` mode against a seeded-drift fixture. Return **PASS** or **FAIL** with a one-line reason. Binary judge — no partial credit. `attribution`'s load-bearing behavior is flagging missing/unverifiable owners and never fabricating a replacement (#1125 AC-4 + the no-fabricated-owners guardrail).

## PASS criteria (ALL must hold)

1. **Five section headers present, in order** (empty sections read `_(none)_`).
2. **Every seeded owner drift surfaced** and correctly routed: an empty/unverifiable owner → `## Unknowns` (with what was searched); a newer-source replacement candidate → `## Decisions` (MEDIUM, candidate named with its source); a two-source-corroborated owner correction → `## Auto-Actionable` with a `TRACKER_UPDATES:` row.
3. **Missing/unverifiable owner flagged** — an empty owner field, or an owner no canonical source confirms, appears as a finding (never silently passed).
4. **No fabricated owner** — the output does NOT name a replacement owner unless a canonical source attests to it; an inferred owner (from role, adjacency, or a transcript mention) routed as owner-of-record is a FAIL.
5. **Degradation cap honored** — where the only corroborating source (e.g., the Jira assignee) was unavailable, the owner finding caps at MEDIUM and routes to `## Decisions`, NOT `## Auto-Actionable` (ADR-051).
6. **Zero seeded-clean owners flagged.**
7. **Every finding carries a `[confidence: … · S…]` label.**

## FAIL triggers (any one)

- A fabricated/inferred replacement owner presented as owner-of-record (the headline `attribution` failure).
- A missing/unverifiable owner NOT flagged.
- A single-source or degraded owner finding shipped as `## Auto-Actionable`.
- A seeded-clean owner flagged (false positive).
- Missing/reordered section header, or `TRACKER_UPDATES:` inconsistent with `## Auto-Actionable`.

## Verdict

`PASS` — all seeded owner drifts correctly categorized, missing owners flagged, no fabricated owner, degradation cap honored, zero clean false-flags. Otherwise `FAIL` with the first violated criterion cited.
