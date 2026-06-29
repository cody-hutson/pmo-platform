<!-- reference-durability: allow-link -->
# Health-Check Evidence Matrix

The source map per mode and the drift-resolution rule the modes apply. The canonical source set, the drift-resolution direction, and the graceful-degradation envelope are owned by [ADR-049](../../../../core/ADRs/ADR-049-health-check-mcp-primary-source-set.md) — this doc maps which sources each mode reads and summarizes the rule for the author; it does not re-decide it.

## Canonical source set

| Tier | Sources | Role |
|---|---|---|
| **MCP-primary** (audience-facing → authoritative) | Confluence (plans, on-call, hypercare) · Jira (ticket state, due dates, assignees) · Smartsheet (live operational trackers) · SharePoint (test trackers, scoreboards — **when an MCP exists**) | The source of truth. Audience-facing drift is the worst drift. |
| **Local fallback / supplement** | `04-PMO-Operations/*` trackers · `PROJECT.md` · `PORTFOLIO.md` · `05-Transcripts/` · `06-Emails/` · `08-Generated/` | Fallback + cross-validation. Two locals agreeing can reach HIGH. |

## Source map per mode

| Mode | Primary MCP sources read | Primary local sources read | Cross-validates by |
|---|---|---|---|
| `full` (v1) | All available connectors | All local | Union of the per-mode checks below |
| `timeline` (v1) | Jira (due dates) · Confluence (plan dates) · Smartsheet (tracker dates) | `PROJECT.md` dates · carry-forward tracker · canonical schedule | MCP date vs local date; most-recent-source-wins |
| `attribution` (v1) | Jira (assignees) · Confluence (on-call / RACI) | RAID owner column · tracker owner fields · `PROJECT.md` team | Recorded owner vs canonical owner |
| `comms` (v2) | Confluence (published comms) | Communications Tracker · `06-Emails/` | Tracker lifecycle vs sent/draft state |
| `plan <name>` (v2) | Confluence (the named plan) | The plan artifact · trackers it touched | Plan-promised vs trackers-reflected |
| `raid` (v2) | Jira (risk/issue tickets) | RAID Log | Closure candidates · orphan IDs |
| `sources` (v2) | All connectors (freshness probe) | `PROJECT.md` sync timestamps | External freshness vs recorded sync |

## Drift-resolution rule (MCP-primary, local-fallback — per ADR-049)

When an MCP source and a local source disagree:

| Situation | Resolution | Band |
|---|---|---|
| MCP & local disagree, **MCP more recent** | Flag **local** for update | `S2` |
| MCP & local disagree, **local more recent** | Flag **MCP** for update — **higher priority** (audience-facing drift is worse) | `S2` / `S3` |
| **Both stale** | Flag the conflict to the operator in `## Decisions`; **do not auto-resolve** | per finding |

## Graceful degradation (the missing-source behavior — per ADR-049)

1. At run start, **probe each expected MCP connector.** An unreachable connector → the run continues **local-only** for that source's checks; it does not crash or silently skip.
2. The output header carries `[MCP UNAVAILABLE: <connector>] — findings limited to local sources` so every consumer knows the coverage envelope.
3. **SharePoint has no MCP today** → SharePoint targets degrade to "links exist; content not verifiable," and SharePoint is listed under missing-but-expected sources rather than asserted fresh.
4. A finding that could not be cross-validated **because its source was unavailable** is capped at **MEDIUM** confidence (never HIGH) and routed to `## Decisions`/`## Unknowns`, **never `## Auto-Actionable`** — degradation reduces coverage, it must never silently downgrade rigor into auto-action.

## What each section the finding lands in expects

The 5-section routing (`## Confirmed` / `## Auto-Actionable` / `## Decisions` / `## Unknowns` / `## Rollup-Diffs`) and the confidence gate per section are defined in SKILL.md `## Output Structure`. This matrix governs only **which sources feed which mode**; the band a finding carries is governed by `confidence-framework.md`.
