<!-- Binary LLM judge — health-check `raid` mode -->
<!-- repo-integrity: allow-issue-ref -->
# Judge: `raid` mode (binary)

You are grading the output of the `health-check` skill run in `raid` mode against a seeded-drift fixture. Return **PASS** or **FAIL** with a one-line reason. Binary judge — no partial credit. `raid`'s load-bearing behavior is **enforcing the RAID guardrails** — flagging any risk stated in passive voice or missing a named owner/mitigation, and flagging stale (unreviewed) RAID entries (the AC-4 requirement) — while never auto-closing a risk (cautious bias).

## PASS criteria (ALL must hold)

1. **Five section headers present, in order** (empty sections read `_(none)_`).
2. **Passive-voice risk flagged** — a risk stated without a named actor (e.g., "Performance may be impacted under peak load") is flagged as a guardrail violation (no passive risk voice).
3. **Missing owner flagged** — a RAID entry with an empty/`TBD` owner is flagged (no item without exactly one named owner).
4. **Missing mitigation flagged** — a risk with no mitigation/response strategy is flagged (identification is not sufficient — the "so what?" discipline).
5. **Stale entry flagged** — a RAID entry not reviewed in >30 days is flagged as a closure-or-refresh candidate (the >30d auto-escalate rule).
6. **Cautious bias honored** — no risk is auto-closed; closure candidates route to `## Decisions` (operator decides, closing a risk needs evidence), NOT `## Auto-Actionable`, unless a two-source-corroborated mechanical fix exists.
7. **Zero seeded-clean RAID entries flagged** — an active-voice entry with a named owner, a named mitigation, and a recent review date is NOT flagged.
8. **Every finding carries a `[confidence: … · S…]` label.**

## FAIL triggers (any one)

- A seeded passive-voice / missing-owner / missing-mitigation / stale entry NOT flagged (the headline `raid` failure — a guardrail violation passed through).
- A risk auto-closed, or a closure routed to `## Auto-Actionable` without two-source corroboration.
- A seeded-clean RAID entry flagged (false positive).
- Missing/reordered section header, or `TRACKER_UPDATES:` inconsistent with `## Auto-Actionable`.

## Verdict

`PASS` — all seeded RAID guardrail violations flagged, stale entry flagged, no risk auto-closed, zero clean false-flags. Otherwise `FAIL` with the first violated criterion cited.
