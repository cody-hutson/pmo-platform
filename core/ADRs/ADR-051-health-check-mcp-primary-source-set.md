---
title: health-check MCP-primary / local-fallback canonical source set + graceful-degradation contract
status: Accepted
tags: [health-check, mcp-source-set, graceful-degradation, drift-resolution, integration-boundary]
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->

# ADR-051 — health-check MCP-primary / local-fallback canonical source set + graceful-degradation contract

## Status

Accepted — ratified at the 06-HEALTH-project-health-check Stage 5 Decision Gate (operator: Approve & route to Stage 6, 2026-06-29). Authored at Stage 6 alongside the skill it governs, per the core-ADR convention (a decision captured as a committed ADR document written in the same release as the artifact it governs).

**Deciders:** operator · **Date:** 2026-06-29

## Context

The `health-check` skill audits a single project's tracked state against its canonical sources. Audience-facing sources — Confluence, Jira, Smartsheet, SharePoint — are the source of truth; the local artifact set (`04-PMO-Operations/*` trackers, `PROJECT.md`, `PORTFOLIO.md`, transcripts, emails, generated artifacts) is fallback and cross-validation. Two facts make the source contract non-obvious and worth recording:

1. **SharePoint has no MCP connector today.** A mode that wants to verify a SharePoint-hosted test tracker cannot read its content; it can only confirm a link exists.
2. **Scheduled runs may hit an unavailable MCP at fire time.** A daily timeline check at 0800 may find Jira unreachable; the run must be deterministic about what it does then.

Without a fixed drift-resolution direction and a fixed missing-source behavior, the skill would either crash on an unreachable connector, silently skip the checks that connector fed (hiding the coverage gap), or — worse — treat a single surviving local source as authoritative and auto-action on it. The decision crosses a component/integration boundary (four external MCP connectors, one with no MCP), which is the ADR trigger.

## Decision

1. **MCP sources are canonical; local is fallback / supplement.** The skill reads MCP-primary {Confluence, Jira, Smartsheet, SharePoint-when-available} and local-fallback {`04-PMO-Operations/*`, `PROJECT.md`, `PORTFOLIO.md`, `05-Transcripts/`, `06-Emails/`, `08-Generated/`}.
2. **Drift resolves by recency, with a priority twist.** MCP and local disagree, MCP more recent → flag local for update (`S2`). MCP and local disagree, **local more recent → flag MCP at higher priority** — audience-facing drift is worse than internal drift (`S2`/`S3`).
3. **Both stale → operator decision, no auto-resolve.** A both-stale conflict is surfaced in `## Decisions`; the skill does not pick a winner.
4. **An unreachable MCP → continue local-only + a header banner.** The run probes each expected connector at start; an unreachable one does not crash the run — the run continues local-only for that source's checks, and the output header carries `[MCP UNAVAILABLE: <connector>] — findings limited to local sources`. A finding that could not be cross-validated because its source was unavailable is **capped at MEDIUM confidence and never enters `## Auto-Actionable`** — degradation reduces coverage, it must never silently downgrade rigor into an auto-action.
5. **SharePoint degrades to "links exist; content unverifiable"** until/unless an MCP connector exists; it is listed under missing-but-expected sources rather than asserted fresh.

The skill projects findings onto the canonical `S0-NONE..S3-STRUCTURAL` staleness-depth scale defined in `core/specs/staleness-confidence-standard.md` (ADR-043) and emits tracker proposals in the existing `TRACKER_UPDATES:` schema (tracker-manager) — it authors no new scale and no new emit contract.

## Consequences

- **(+)** Deterministic, audience-drift-prioritized, fail-soft: the skill never crashes on a missing connector and never hides the gap — the banner makes the coverage envelope explicit to every consumer.
- **(+)** Composes with existing platform contracts: the `TRACKER_UPDATES:` schema and the S0–S3 band scale, both consumed by reference. No new schema.
- **(+)** The MEDIUM cap on uncross-validated findings closes the most dangerous degradation path — a single surviving local source can never silently drive an auto-action.
- **(−)** SharePoint coverage is partial until an MCP lands — a named, accepted residual.
- **(−)** Adds an MCP-probe step to run start — cheap (a try/fallback per connector).
- **Reversibility: MODERATE · Confidence: MEDIUM.** The source-set and drift-direction are a documented rule (a doc edit to change — CHEAP); the degradation envelope is MODERATE but isolated to one skill. Confidence is MEDIUM on the SharePoint gap (it resolves if/when an MCP appears) and HIGH on the drift-resolution direction and the MEDIUM-cap rule.

## Alternatives considered

| Option | Decision | Rationale |
|---|---|---|
| **Local-primary, MCP-supplement** | Rejected | Inverts the source of truth — audience-facing systems are what stakeholders read; treating local trackers as canonical would let internal drift mask the drift that actually reaches stakeholders. |
| **Crash / hard-skip on an unreachable MCP** | Rejected | A scheduled run must be deterministic and fail-soft; crashing loses the local-only findings that are still valuable, and a silent skip hides the coverage gap (the silent-pass anti-pattern). |
| **Continue local-only with no confidence cap** | Rejected | Lets a single surviving local source drive a HIGH-confidence auto-action with no corroboration — the exact rigor-downgrade the degradation contract exists to prevent. |
| **MCP-primary + local-fallback + recency resolution + MEDIUM-capped degradation** | **Accepted** | Keeps the audience-facing source authoritative, prioritizes the worse (audience-facing) drift, and degrades by reducing coverage rather than rigor. |

## Cross-references

- `core/specs/staleness-confidence-standard.md` (ADR-043) — the S0–S3 band scale this skill projects onto.
- `operations/skills/health-check/SKILL.md` — the skill this ADR governs.
- `operations/skills/health-check/references/evidence-matrix.md` — the per-mode source map that applies this contract.

### Provenance

Specified in the Stage 5 Solutioning design for the 06-HEALTH-project-health-check milestone (sub-task #2474); the build slice is #1125.
