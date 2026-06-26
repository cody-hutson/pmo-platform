# Characterization: people-graph-consumption

Stage 0 five-tuple (per `core/skills/eval-writer/references/canonical-workflow.md`) for the system under test — the 4 skills' consumption of the people capability/coverage graph view.

- **Single-agent vs multi-agent:** single-agent. Each skill (comms-writer, tracker-manager, ppm-agent, delivery-engine) is a single dispatch performing a read of the composed view. The suite exercises four skills, but each consumption is independent — there is no multi-agent coordination under test.
- **Tool use:** yes — the consumption is a file read of the operator-instance roster (resolved via `pmo_people_roster()` in `core/deploy/lib-instance-path.sh`) joined with the frozen Person + Resource entities. The eval grades the *result* of that read, not the tool mechanics.
- **HITL present:** yes — the operator reviews skill outputs, and the clarification-queue maintenance path is the Tier-1 operator gate for any identity creation. The consuming skills themselves never create identity; an unresolved name is surfaced for operator confirmation.
- **Dev vs production:** production-in-pmo-context — all four skills are routinely used in workflows; the consumption contract is live as of v2.23 (instructional) and verified here in v2.26.
- **Safety criticality:** elevated-routine. The roster holds real people's names (PII-adjacent) and the read-only invariant is load-bearing: a write leak would mutate or commit roster-derived data, re-introducing the never-commit hazard the design exists to prevent. Hence the read-only assertion is a first-class, non-optional check.
- **Topology:** N/A (single-agent per consumption).

## Triggered decision-tree rules

Per `core/skills/eval-writer/references/decision-tree.md`, off the 5-tuple:

- **RULE F-A1** (all systems) → Stages 1–4 required: characterization, failure taxonomy, judge, calibration protocol. Satisfied by this suite.
- **RULE B-A1** (tool use) → tool-call / read correctness in scope: the deterministic runner is the read-correctness check (does the read resolve the right value).
- **RULE B-A2** (structured / code-checkable output) → code assertions preferred where the output is deterministic: the resolution + read-only + non-triviality checks are mechanical (the runner), with the binary LLM judge reserved for the skill-behavior layer where the output is a prose artifact.

## What does NOT apply

- MAS coordination rules (C-A*) do not fire — single-agent per consumption.
- A 1–5 ordinal rubric is rejected (A-04) — the decision is binary.
- Trajectory-matching as the sole check is rejected (A-02) — the binary judge is a state-based outcome check on the resolved value + read-only invariant, paired with the deterministic runner.

## Reversibility

Characterization is a descriptive artifact (not a decision the operator acts on) — no reversibility tier required. The decision-class artifacts in this suite (judge prompt design, calibration thresholds) carry tiers in `rubrics.md` and `calibration-protocol.md`.
