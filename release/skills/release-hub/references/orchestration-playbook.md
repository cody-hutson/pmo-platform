<!-- reference-durability: allow-link -->
# Mode O — Orchestration Playbook (Procedures 0→7)

Elaborates `## Mode O — Orchestrate Release` in [`../SKILL.md`](../SKILL.md). The SKILL.md is the authoritative contract; this file is the executable playbook the hub follows to drive a milestone through Stages 4→13.

**Built from, coexists with, and cites — not copies — [`hub-spoke-bridge.md`](../../../references/how-to/hub-spoke-bridge.md) `## For the Hub Agent`.** The manual hub remains valid and unchanged; Mode O is its triggerable form. Where a block below names a `hub-spoke-bridge.md` section, the hub READS that section for the verbatim template/detail at runtime — the orchestration logic here is the skill's own; the reusable templates stay in the doc.

## The run loop

Mode O is **stateless + resumable**: each invocation reads durable state, advances the milestone to the next human gate, writes state back, and exits. The loop:

`resume (0b) → plan (0) → scaffold (1) → route (2) → spawn wave (3) → complete (4) → gate (5) → [early-merge (6)] → close (7)`

The hub holds the state machine + compact handoff summaries; the spokes hold the per-stage work (fan-out keeps the hub's context lean).

## Procedure 0b — Resume first (every invocation)

Before any routing, read hub-state and decide resume-vs-start. **Canonical spec: [`hub-session-continuity.md`](../../../../core/standards/hub-session-continuity.md)** — the 3-surface state schema (pending-approvals / event-log / sessions), the 9-step Resume Procedure (incl. drift detection), and the composite session-ID. The hub imports it; it is not restated here.
- A run is in flight (open sub-tasks / pending approvals for the milestone) → resume at its next unsatisfied gate.
- Else → start fresh at Procedure 0.

## Procedure 0 — Release Planning (Stage 4)

Runs once per milestone at release scope. The hub:
1. Reads all milestone issues (titles, bodies, states, deps, sub-issues).
2. Resolves platform-config ONCE and injects the resolved values into the spoke prompt (single resolution at the hub; spokes do not re-resolve).
3. **Spawns the planning spoke** ([`spoke-launch.md`](spoke-launch.md)) — the Release Planning Spoke Template + the Stage-4 persona card. (Verbatim template + the D-Gate Template + the recurring D-decisions (D-ReleaseClass, D-Version) live in `hub-spoke-bridge.md` § Procedure 0 / § D-Gate Template — read there.)
4. Reads the spoke's plan (dependency graph, implementation sequence, contention map, stage applicability, risk register) → **Decision Briefing** ([`decision-briefing.md`](decision-briefing.md)).
5. **GATE (operator):** approve the plan + the Release Outcome Statement. After approval the hub PATCHes the Outcome Statement into the Milestone description.

**D-Version is a recorded determination, not a gate** — the next-free version is rule-computed (authoritative-version-selection, `hub-spoke-bridge.md` § Recurring D-decisions); the hub records it and proceeds (SKILL.md FM "rule-determined call as an operator gate").

## Procedure 1 — Scaffolding

After plan approval the hub creates one **sub-task per stage per issue** via `gh issue create` (hub mechanical work, NOT a spoke launch), reads the Release Class, immediately closes skipped sub-tasks with the **Skip Closure Format**, and sequences the rest.
- **GATE (operator):** review the scaffold (incl. the skipped list) before routing.

(Verbatim Sub-Task Template + Skip Closure Format: `hub-spoke-bridge.md` § Procedure 1.)

## Procedure 2 — Routing (what's next)

The control-flow core. The hub:
1. Lists sub-tasks; identifies the **dependency-met actionable subset** (never spawns an unmet-dependency sub-task).
2. Runs the **Collective Review check** before any Stage-6 routing (fires when ≥2 issues have Solutioning active and all Stage-5 sub-tasks are closed → operator scope-lock GATE).
3. Runs the action-item scan ([`hub-action-tracking.md`](../../../../core/standards/hub-action-tracking.md)).
4. For a parallel wave (Stage 5/7/8): runs the **quota-budget gate** + honors the **parallelism class** before spawning ([`spoke-launch.md`](spoke-launch.md)).
5. **Per-wave concurrent-PR check (pre-spawn):** before spawning a build spoke for issue #N, query open PRs referencing that issue (`gh pr list --state open --search "#N"` or equivalent; N = the target issue number). If an open PR already references it, **surface to the operator — proceed / adopt / skip — BEFORE spawning**, never deferred to the Stage 7/8 coherence review. **Re-run every wave** (not once at Stage 4): the open-PR population changes mid-run, so a clean planning-time scan does not carry ([`spoke-launch.md`](spoke-launch.md)).
6. Spawns the wave.

## Procedure 3 — Spoke prompt construction

When spawning a per-issue stage spoke (5–13), the hub builds the prompt from the **Spoke Template** (`hub-spoke-bridge.md` § Procedure 3 — read verbatim) + the stage's persona card (`release-personas.md`, via the Stage-to-Persona Mapping). The prompt-construction disciplines (PR-body parser-clean, repo-integrity, spec-anchor, worktree detect-first, hook-safe git, the per-stage chip patterns) are authoring rules the hub applies — each cites its canonical pipeline-shard in `hub-spoke-bridge.md` § Procedure 3. The hub is the ONLY spawner; a spoke never self-spawns (recursion-prohibition: [`spoke-launch.md`](spoke-launch.md)).

## Procedure 4 — Spoke completion handling

After a spoke (or batch) returns: read the return value + output comment; verify closure; assess sufficiency; **evaluate the spoke's recommendations adversarially** against release-wide context (verify, don't rubber-stamp — R1 in [`decision-briefing.md`](decision-briefing.md)); produce a **Decision Briefing**; route only after the operator renders every decision. The action-item scan composes here.

## Procedure 5 — Gate handling (the two hard human gates)

**Do NOT spawn a spoke — gates are operator decisions.** The hub reads the prior outputs, runs the action-item scan + (Stage-9 only) the 13-dimension Release Readiness Scan + the goal-conformance check, and presents:
- **Stage 9 — Plan Review (GO / NO-GO):** the release-authorization decision. The hub assembles the evidence; the operator renders GO/NO-GO. **NEVER auto-crossed.**
- **Stage 12 — Execute:** merge + deploy authorization. **NEVER auto-crossed.**

Strict ordering at the close steps: post the gate-passage proof → close the sub-task → route.

## Procedure 6 — Early merge

When routing finds a downstream issue blocked on an upstream issue's changes needing to be on main: 4 criteria (incl. operator approval) → Decision Briefing → `gh pr merge` + branch sync; track the early-merged PR for Stage 12.

## Procedure 7 — Release Close (Stage 13)

When all sub-tasks are closed, the hub:
- Applies the **Standing-GO Authorization Model** — the Stage 9 GO authorizes the downstream mechanical state-flips as Tier-1; the hub closes the Milestone itself at the close step (not a manual operator step).
- Produces the **complete canonical Stage 13 output set** (the Step-4 Verification table — `hub-spoke-bridge.md` § Procedure 7; default path = the automated close-out; fallback = the Phase-B chore-PR mechanism when preflight blocks). Hand-assembling the corpus row-by-row is prohibited (it silently drops outputs).
- **HARD GATE (7a):** the action-item resolution gate — all open / in-flight action items resolved before Milestone close (`hub-action-tracking.md`).
- Records the gate-passage proof; closes the Milestone; spawns the orphan-state cleanup chip (operator approves its `--apply` at a Tier-1 gate).

## The gate set — where Mode O STOPS for the operator

| Gate | Procedure | Nature |
|---|---|---|
| Plan + Outcome Statement approval | 0 | judgment |
| Scaffold review | 1 | judgment |
| Collective Review scope-lock | 2 | judgment (release-level) |
| Quota-budget SERIALIZE / DEFER / REDUCE | 2 (5.5) | surfaced when non-PROCEED |
| **Stage 9 — GO / NO-GO** | 5 | **release-authorization gate** |
| **Stage 12 — Execute** | 5 | **deploy authorization** |
| Tier 2/3 inter-stage escalation · Tier 0 premise rejection · D-class | 4 | judgment (as they fire) |
| Early-merge approval | 6 | judgment |
| Action-item resolution (7a) | 7 | HARD gate before close |
| Post-deploy `--apply` (orphan cleanup) | 7 | Tier-1 recommend |

Rule-determined values (e.g. D-Version next-free) are **recorded determinations, not gates** (SKILL.md FM "rule-determined call as an operator gate").
