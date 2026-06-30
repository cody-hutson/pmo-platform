<!-- Binary LLM judge — health-check `sources` mode -->
<!-- repo-integrity: allow-issue-ref -->
# Judge: `sources` mode (binary)

You are grading the output of the `health-check` skill run in `sources` mode against a seeded-drift fixture. Return **PASS** or **FAIL** with a one-line reason. Binary judge — no partial credit. `sources`'s load-bearing behaviors are (1) **emitting a canonical-source inventory that names its source-of-truth set**, and (2) **flagging missing-but-expected and stale sources** (the AC-5 requirement).

## PASS criteria (ALL must hold)

1. **Five section headers present, in order** (empty sections read `_(none)_`).
2. **Canonical-source inventory emitted** — the output lists the source-of-truth set it checks (the MCP-primary set: Confluence / Jira / Smartsheet / SharePoint, plus the local fallback set) with a per-source freshness verdict. The inventory is the headline `sources` deliverable.
3. **Stale source flagged** — a recorded sync timestamp that lags the live source (e.g., PROJECT.md records Confluence synced April 2 but the live page was edited April 20) is flagged as external-source freshness drift, with a sync-direction recommendation → `## Auto-Actionable` (HIGH, two timestamps corroborate) or `## Decisions`.
4. **Missing-but-expected source flagged** — a source that is expected but has no MCP connector (SharePoint) is listed as missing-but-expected / link-only / content-unverifiable, and is NOT asserted fresh.
5. **Fresh sources confirmed** — a source whose recorded sync matches recent activity (Jira) lands in `## Confirmed`.
6. **Zero seeded-fresh sources flagged stale** (false positive).
7. **Every finding carries a `[confidence: … · S…]` label.**

## FAIL triggers (any one)

- No canonical-source inventory emitted (the headline `sources` failure — the source-of-truth set is not named).
- A stale recorded sync NOT flagged, or a SharePoint (no-MCP) source asserted fresh instead of flagged missing-but-expected.
- A genuinely-fresh source flagged stale (false positive).
- Missing/reordered section header, or `TRACKER_UPDATES:` inconsistent with `## Auto-Actionable`.

## Verdict

`PASS` — the canonical-source inventory is emitted and names its source-of-truth set, the stale sync is flagged with a direction, SharePoint is flagged missing-but-expected (not asserted fresh), fresh sources are confirmed, zero fresh false-flags. Otherwise `FAIL` with the first violated criterion cited.
