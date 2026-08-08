<!-- reference-durability: allow-link -->
# Mode O — Spoke Launch

How Mode O spawns spokes. Elaborates `## Mode O` in [`../SKILL.md`](../SKILL.md); cites [`hub-spoke-bridge.md`](../../../references/how-to/hub-spoke-bridge.md) § Spoke Launch Mechanisms for the verbatim parameter contract + the empirical anchors.

## Spawn, not skill-chain

Mode O launches every spoke with the **`Agent` tool** (a fresh session) — never in-context Skill-tool invocation. Each spoke is depth-0, so the C1 depth bound (≤ 2 Skill-tool invocations) never engages across a 13-stage run, and the `pmo-release-manager` tail (itself a composer of `release-executor`) is spawned, not Skill-invoked into a depth-3 chain. **The hub is the only spawner.**

## Launch parameters

`Agent({subagent_type, prompt, description, model, isolation, run_in_background})`. Two are load-bearing:
- **`model` — REQUIRED-EXPLICIT** at the PMO surface (never rely on the implicit default).
- **`isolation: "worktree"`** — MUST be pinned for the write stages (6, 12, 13); MAY be used for read-only stages (5, 7, 8).

(Full signature table: `hub-spoke-bridge.md` § Spoke Launch Mechanisms § Default.)

## Concurrency — two composing gates (NOT a fixed count)

Concurrency is governed by two gates that compose; there is **no fixed concurrent-count cap** — the doc is explicit that a fixed count is not the binding predictor. Note the asymmetry between them: gate 1 is scoped by stage, gate 2 is **not scoped at all** — it fires on every launch, including the singleton launches gate 1's write-serialized stages produce.

1. **Stage parallelism class** — Stage 5 / 7 / 8 are **parallel-safe** (output channel = a GitHub Issue comment; no file-contention surface); Stage 6 / 13 are **write-serialized** (commit / main mutation — one at a time).
2. **Quota-budget gate (Procedure 2 Step 5.5 / Checkpoint B)** — before **EVERY `Agent`-tool launch, wave or singleton, at every stage**, weigh `tokens_per_spoke × N` against the *remaining* per-account 5-hour usage-window envelope. Verdict depth follows launch shape: a wave (N ≥ 2) renders ∈ {**PROCEED** / **SERIALIZE** / **DEFER** / **REDUCE-scope**}; a singleton (N = 1) renders the reduced ∈ {**PROCEED** / **DEFER**} — `SERIALIZE` is meaningless at N=1 and `REDUCE-scope` stays a pre-verdict mitigation, not a singleton verdict. This is a standing pre-launch step for every launch (each faces a different remaining envelope — mid-release drift, window-boundary crosses), not a one-time Stage-4 estimate; a serial stage bounds the concurrent-batch surface, never the envelope. The check costs **zero tool calls**, which is what makes per-launch firing affordable. **Render the verdict every time, including PROCEED** — it emits no event, so the rendered line is the only way a skipped gate is distinguishable from a cleared one. When no envelope is stated, render `UNSTATED` + the conservative default and never a synthesized percentage. A non-PROCEED verdict surfaces to the operator; it does NOT reclassify any stage's Autonomy Tier.

"Parallel-safe" is a *coordination* property (no shared write surface) — it is orthogonal to the usage-window envelope, against which concurrent spokes still draw cumulatively. (Spec: `hub-spoke-bridge.md` § Per-Account Usage Window Constraint + `quota-budget-protocol.md`.)

## Output path

Every spoke prompt Mode O renders MUST carry the run-directory clause verbatim: the spoke resolves ONE run directory (`mktemp -d` under a session scratch base, suffixed with the stage and sub-task number), writes every scratch artifact inside it, reads scratch input only from it, and echoes the resolved path in its output comment. Uniqueness is by construction, so a re-run of the same stage on the same sub-task cannot land on the prior run's leftovers — the failure a sub-task-keyed path allows. Canonical clause + its honest read-side boundary: `hub-spoke-bridge.md` § Run-Directory Discipline (Spoke Template). Cite it; do not restate it here.

## Worktree detect-first guard

A spawned spoke can land in the **primary checkout** instead of an isolated worktree (observed). The spoke prompt MUST instruct the spoke to **detect first, then act**:
- Detect the working tree: `git rev-parse --show-toplevel`.
- If in the primary checkout → create an isolated worktree and `cd` into it before any branch work.
- If already in an isolated session worktree → operate in it directly; do **not** nest a worktree-inside-a-worktree.
- On orphaned worktrees, `git worktree prune` from the primary before the next launch.

## Concurrent-PR collision check (pre-spawn, per wave)

Before spawning a **build spoke** for issue #N, check whether an open PR already references it — a concurrent process may have built the same issue on another branch. Observed: a mid-run collision produced two divergent, both-mergeable builds of the same issues and a release-integrity fork, caught only at the Stage 7/8 coherence review (~40 min of double build cost later).

- **Query:** `gh pr list --state open --search "#N"` (or equivalent; N = the target issue number).
- **If an open PR already references #N → surface to the operator (proceed / adopt / skip) BEFORE spawning** — never defer the collision to a later coherence review.
- **Re-run every wave**, not once at Stage 4: the open-PR population changes mid-run (a clean planning-time scan does not carry). This is the third standing pre-spawn guard, composing with the quota-budget gate + the worktree detect-first guard above.

## Stage-Conditional Launch Policy (when to spawn vs gate)

Auto-launch is bound to the stage's Autonomy Tier: spawn autonomously for Tier-2/3 stages; **preserve the operator gate at Tier-0 — Stage 9 (Plan Review) and Stage 12 (Execute) are NEVER auto-launched.** (Stage-to-Autonomy-Tier table: `hub-spoke-bridge.md` § Stage-Conditional Launch Policy.)

## Recursion prohibition

A spawned spoke MUST NOT invoke the `Agent` tool or `spawn_task`. The hub is the only caller of spoke-launch primitives. (Full posture: [`subagent-security-posture.md`](../../../../core/standards/subagent-security-posture.md).)

## Fallback — manual copy/paste

When the `Agent` tool is unavailable, or an edit-before-launch / debug / cross-session-carry condition applies, the hub prints the full spoke prompt for the operator to paste into a new session. (Conditions F1–F6: `hub-spoke-bridge.md` § Fallback.)
