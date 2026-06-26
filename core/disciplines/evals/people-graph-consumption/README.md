<!-- repo-integrity: allow-memory-ref -->
# People-graph consumption eval — roster → composed view → skill consumption

This suite proves the people capability/coverage graph is a **wired capability**, not a movable file. It verifies that each of the four consuming skills resolves a real name / owner / coverage answer from a populated roster through the composed view, and that the read stays read-only. It is the executable answer to the parent issue's finding: the consumption was *instructional-but-unverified* — the four SKILL.md files instruct the read, but nothing exercised it.

## What this verifies (the wiring)

```
  fixtures/roster-fixture.yaml            operator fills ONE roster (functional attributes)
            │   (joined on person_id)
            ▼
  people-coverage-graph.md  ──────────►   composed VIEW (read-time join, never materialized):
   the three queries                        roster  +  Person (identity)  +  Resource (allocation)
            │
            ├── who-does-what ───────────►  comms-writer   (preferred name/spelling for the message)
            ├── who-does-what ───────────►  tracker-manager (RAID owner_person_id → full_name/role)
            ├── who-covers-whom ─────────►  ppm-agent       (escalates_to → escalation target)
            │   + coverage-by-capability                    (status-filtered backup)
            └── coverage-by-capability ──►  delivery-engine (who covers capability X right now)
                + who-does-what (Resource)                  (project allocation)
```

The roster is filled **once**; four skills read it; **none writes it**. That is the capability — one source, every consumer, read-only.

## The adoption path

The end-to-end operator adoption narrative — where the roster lives, how to fill it, how each tier's owner-ref points into it, and how the four skills consume it — is the GETTING_STARTED guide's people-graph section (added in this release's earlier docs commit). This README does not duplicate it; it is the **verification companion** to that adoption narrative: the adoption guide says *how to wire it*, this suite *proves the wiring holds*. See `docs/GETTING_STARTED.md` §7 "People-graph adoption — one roster, every tier".

In short, the adoption path is: (1) the filled roster is auto-seeded on install to the operator-instance path resolved by `pmo_people_roster()` in `core/deploy/lib-instance-path.sh` (never committed); (2) the operator fills one entry per person using only the allow-list fields; (3) each tier's owner field is a typed reference into the roster, resolving on `person_id`, with an `*_external` free-text fallback for an owner not in the roster; (4) the four skills resolve people from the composed view at read-time. This suite exercises step (4) against a populated fixture standing in for step (2).

## The fixture

`fixtures/roster-fixture.yaml` is a **populated, de-identified** roster of six synthetic people. It is named `roster-fixture.yaml` — **not** `people-roster.yaml` — on purpose: the `.gitignore` rule `**/people-roster.yaml` (with the `!**/people-roster-template.yaml` carve-out) makes any `people-roster.yaml` un-committable so a real operator roster can never enter git. A fixture must be tracked to be useful, so it carries a distinct name; `git check-ignore` does not match it.

The fixture conforms to the shipped schema (`operations/templates/people-roster-template.yaml`): only allow-list fields appear, capability is a list of tags (never a rating), provenance-bearing fields carry `{value, source, last_verified}`, and `status` is the tombstone enum. No excluded shadow-HR field appears. Two scaffolding blocks (`_fixture_person_entity`, `_fixture_resource_allocations`) stand in for the frozen Person and Resource entities the view composes over, so the runner can exercise all three queries self-contained; a real roster consumer ignores keys outside the `people:` list.

The fixture deliberately includes an **on-leave** person (person-id-003) and a **departed** person (person-id-006) so the `coverage-by-capability` status filter has something to exclude — "who can cover right now" must not surface an unavailable person.

## Two-layer grading

Per `rubrics.md`:

1. **Deterministic resolution + read-only + non-triviality** — `run_consumption_eval.py`. Code-checkable, no LLM, no live skill dispatch. This is the layer Stage-6 self-verification runs.
2. **Skill-behavior (binary judge)** — `judge_prompts/people-graph-read-resolution.md`. A binary PASS/FAIL LLM judge that grades real skill output (resolution fired from the graph / status filter applied / no graph write), executed downstream by a harness (pmo-skill-refiner / CI / Stage 7 DT) on captured output. The eval-writer convention is author-not-run; this layer is authored here and executed there.

## Run it

```bash
cd core/disciplines/evals/people-graph-consumption
python3 run_consumption_eval.py
```

Exit `0` = all three layers pass. The runner prints PASS/FAIL per skill assertion, confirms the fixture is byte-identical before/after (read-only), and re-runs every resolution against an **empty** roster to prove the populated passes are load-bearing (an empty roster resolves nothing → the suite is not a no-op). Point `--fixture` at an empty roster to see the suite correctly FAIL (exit `1`), which is the non-triviality property by demonstration.

## Files

| File | Role |
|---|---|
| `fixtures/roster-fixture.yaml` | Populated de-identified roster the eval resolves against (tracked; not `people-roster.yaml`) |
| `evals.json` | The 4 skill-consumption test prompts with per-skill resolution + read-only + non-triviality assertions |
| `judge_prompts/people-graph-read-resolution.md` | Binary (PASS/FAIL) LLM judge for the skill-behavior layer |
| `rubrics.md` | Binary scoring scale, two-layer grading, per-eval pass criteria, calibration thresholds |
| `characterization.md` | Stage 0 five-tuple + triggered decision-tree rules |
| `failure-taxonomy.md` | The consumption failure modes this suite catches (read-does-not-fire, invented resolution, write leak, status-filter miss) |
| `calibration-protocol.md` | Gold-set + α/κ thresholds + bias tests for the binary judge |
| `run_consumption_eval.py` | Self-contained deterministic runner (resolution + read-only + non-triviality) |

## Provenance

This suite is the consumption-verification leg of the people-graph activation work. It composes the view contract defined in `core/disciplines/people-coverage-graph.md` (the three queries, the `person_id` join, the read-only / never-invent posture) and the roster schema in `operations/templates/people-roster-template.yaml`, and verifies the four consuming skills' people-graph read blocks. The eval framework (binary judge, fixture layout, characterization, calibration) follows `core/skills/eval-writer`.
