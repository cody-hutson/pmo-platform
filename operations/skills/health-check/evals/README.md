<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Health-Check Eval Set

Per-mode binary-judge evals for the `health-check` skill, authored via the `eval-writer` framework and runnable through the `pmo-skill-refiner` preserved harness. **v1 (#1125) covers the 3 v1 modes** — `full`, `timeline`, `attribution` — against ≥2 seeded-drift project-state fixtures plus an MCP-degradation case. #1126 extends this set to the 4 v2 modes.

## Layout

| Path | Contents |
|---|---|
| `evals.json` | The harness-runnable case set (skill_name + per-case prompt / expected_output / files) — the `pmo-skill-refiner` harness entry point. |
| `fixtures/` | ≥2 historical project-state snapshots with **seeded drift** (stakeholder names sanitized) + one MCP-unavailable fixture. |
| `judges/` | One **binary** LLM-judge prompt per v1 mode (`full.md`, `timeline.md`, `attribution.md`). |
| `cases/` | Case → expected-section-membership mappings (one YAML per case), the structured assertion the judge applies. |

## What each binary judge asserts

For each seeded drift in a fixture, the per-mode judge returns PASS only if the mode:

1. **surfaced the drift** (it appears in the output),
2. **placed it in the correct of the 5 sections** by its confidence/band (`## Confirmed` / `## Auto-Actionable` / `## Decisions` / `## Unknowns` / `## Rollup-Diffs`),
3. **emitted a `TRACKER_UPDATES:` block iff the item was `## Auto-Actionable`**, and
4. for `timeline`, **validated day-of-week + refused a generalized range**; for `attribution`, **flagged the missing/unverifiable owner**.

**PASS = all seeded drifts correctly categorized AND zero seeded-clean items false-flagged.** A mode that finds the drift but mis-routes it (e.g., a single-source finding shipped as `## Auto-Actionable`) FAILS.

## The MCP-degradation case (exercises ADR-049)

One fixture (`fixtures/uat-window-mcp-degraded.md`) marks an MCP source unavailable. Its judge asserts (a) the header banner `[MCP UNAVAILABLE: <connector>]` fired, and (b) the finding that could not be cross-validated because that source was unavailable did **not** land in `## Auto-Actionable` (it is capped at MEDIUM and routed to `## Decisions`/`## Unknowns`). This is the drift-resolution + degradation rule under test.

## Fixtures (v1)

| Fixture | Project state | Seeded drift |
|---|---|---|
| `fixtures/pre-cutover.md` | A project the week before cutover | a moved date (timeline), a swapped owner (attribution), a multi-source disagreement (full), and clean items that must NOT be flagged |
| `fixtures/uat-window-mcp-degraded.md` | A project mid-UAT with Jira unreachable | a single-source-only finding (must cap at MEDIUM, not auto-action) + the degradation banner |

Coverage maps to #1125 AC-7: ≥2 project states, each seeded with known drift of each v1 class — a date moved (`timeline`), an owner swapped (`attribution`), a multi-source disagreement (`full`) — plus the degradation case. Expandable to ≥3 states and the 4 v2 modes at #1126.

## Running

```bash
# via the pmo-skill-refiner preserved harness (variance analysis + binary judge)
python3 -m scripts.run_evals operations/skills/health-check/evals/evals.json   # (from the pmo-skill-refiner module)
```

The harness reads `evals.json`; the `judges/` + `cases/` files are the human-and-LLM-readable assertion specs the judge prompts encode.
