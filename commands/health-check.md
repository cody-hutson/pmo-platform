---
description: Audit one project for drift between its tracked state and its canonical sources, and emit a categorized 5-section drift report (never auto-applied).
---

Run the `health-check` skill (`operations/skills/health-check/SKILL.md`).

Arguments (mode + scope): "$ARGUMENTS"

- First token = mode. v1 modes: `full` (default), `timeline`, `attribution`. (`comms` / `plan <name>` / `raid` / `sources` are v2 — not yet implemented.)
- `--scope <project>` names the project; default = the active project from session context. If no mode is given, use `full`. If no scope is given and none resolves from session context, ask "which project?" — do not default to an arbitrary project.

Emit the 5-section output exactly: `## Confirmed` / `## Auto-Actionable` / `## Decisions` / `## Unknowns` / `## Rollup-Diffs`. Carry a `[confidence: HIGH|MEDIUM|LOW · S0|S1|S2|S3]` label on every finding. `## Auto-Actionable` items emit a `TRACKER_UPDATES:` block and are **never auto-applied** — route to `/tracker-manager` on approval. Probe MCP connectors at start; an unreachable one → continue local-only + a `[MCP UNAVAILABLE: <connector>]` header banner, and cap any uncross-validatable finding at MEDIUM (never auto-action).
