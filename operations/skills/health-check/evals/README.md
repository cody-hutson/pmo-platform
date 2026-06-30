<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Health-Check Eval Set

Per-mode binary-judge evals for the `health-check` skill, authored via the `eval-writer` framework and runnable through the `pmo-skill-refiner` preserved harness. **v1 (#1125) covers the 3 v1 modes** — `full`, `timeline`, `attribution` — against seeded-drift project-state fixtures plus an MCP-degradation case. **v2 (#1126) extends the set to all 7 modes** — adding `comms`, `plan <name>` (with a no-arg "which plan?" prompt case), `raid`, and `sources` against a third seeded-drift fixture (the hypercare-window state). The bank now spans three project states (pre-cutover, UAT-degraded, hypercare-window).

## Layout

| Path | Contents |
|---|---|
| `evals.json` | The harness-runnable case set (skill_name + per-case prompt / expected_output / files) — the `pmo-skill-refiner` harness entry point. |
| `fixtures/` | Historical project-state snapshots with **seeded drift** (stakeholder names sanitized) + one MCP-unavailable fixture: `pre-cutover.md` (v1 modes), `uat-window-mcp-degraded.md` (degradation), `hypercare-window.md` (v2 modes). |
| `judges/` | One **binary** LLM-judge prompt per mode (`full.md`, `timeline.md`, `attribution.md`, `comms.md`, `plan.md`, `raid.md`, `sources.md`). |
| `cases/` | Case → expected-section-membership mappings (one YAML per case), the structured assertion the judge applies. |

## What each binary judge asserts

For each seeded drift in a fixture, the per-mode judge returns PASS only if the mode:

1. **surfaced the drift** (it appears in the output),
2. **placed it in the correct of the 5 sections** by its confidence/band (`## Confirmed` / `## Auto-Actionable` / `## Decisions` / `## Unknowns` / `## Rollup-Diffs`),
3. **emitted a `TRACKER_UPDATES:` block iff the item was `## Auto-Actionable`**, and
4. **enforced the mode's load-bearing behavior** — `timeline`: validated day-of-week + refused a generalized range; `attribution`: flagged the missing/unverifiable owner; `comms`: classified lifecycle state + status-only updates + no inferred response; `plan <name>`: scoped to the named plan AND prompted "which plan?" when no name was supplied; `raid`: flagged passive voice / missing owner / missing mitigation / stale entries without auto-closing; `sources`: emitted the canonical-source inventory + flagged missing-but-expected and stale sources.

**PASS = all seeded drifts correctly categorized AND zero seeded-clean items false-flagged.** A mode that finds the drift but mis-routes it (e.g., a single-source finding shipped as `## Auto-Actionable`) FAILS.

## The MCP-degradation case (exercises ADR-051)

One fixture (`fixtures/uat-window-mcp-degraded.md`) marks an MCP source unavailable. Its judge asserts (a) the header banner `[MCP UNAVAILABLE: <connector>]` fired, and (b) the finding that could not be cross-validated because that source was unavailable did **not** land in `## Auto-Actionable` (it is capped at MEDIUM and routed to `## Decisions`/`## Unknowns`). This is the drift-resolution + degradation rule under test.

## Fixtures

| Fixture | Project state | Seeded drift | Modes exercised |
|---|---|---|---|
| `fixtures/pre-cutover.md` | A project the week before cutover | a moved date (timeline), a swapped owner (attribution), a multi-source disagreement (full), and clean items that must NOT be flagged | `full`, `timeline`, `attribution` |
| `fixtures/uat-window-mcp-degraded.md` | A project mid-UAT with Jira unreachable | a single-source-only finding (must cap at MEDIUM, not auto-action) + the degradation banner | `full` (degradation) |
| `fixtures/hypercare-window.md` | A project in the hypercare window after go-live | a stale-SENT + obsolete-DRAFT + unsent-READY comm (comms); a plan-promised-but-unreflected item (plan); a passive-voice + ownerless + mitigation-less risk and a stale RAID entry (raid); a stale external-source sync + a no-MCP source (sources); clean items per mode | `comms`, `plan <name>`, `raid`, `sources` |

Coverage maps to #1125 AC-7 (the 3 v1 modes against ≥2 project states, each seeded with known drift of each v1 class — a date moved (`timeline`), an owner swapped (`attribution`), a multi-source disagreement (`full`) — plus the degradation case) and #1126 AC-7 (the 4 v2 modes against the hypercare-window state, including the `plan` no-arg "which plan?" prompt case). The bank now spans three project states.

## Running

```bash
# via the pmo-skill-refiner preserved harness (variance analysis + binary judge)
python3 -m scripts.run_evals operations/skills/health-check/evals/evals.json   # (from the pmo-skill-refiner module)
```

The harness reads `evals.json`; the `judges/` + `cases/` files are the human-and-LLM-readable assertion specs the judge prompts encode.
