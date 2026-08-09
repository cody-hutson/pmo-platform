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

Every spoke prompt Mode O renders MUST carry the run-directory clause verbatim: the spoke resolves ONE run directory (`mktemp -d` under a session scratch base, suffixed with the stage and sub-task number), writes every scratch artifact inside it, reads scratch input only from it, and echoes that directory **in `${SCRATCH_BASE}`-relative form — never the resolved absolute path**, because on a default install the scratch base embeds the operator's OS username and the output comment is a public surface. Uniqueness is by construction, so a re-run of the same stage on the same sub-task cannot land on the prior run's leftovers — the failure a sub-task-keyed path allows. Canonical clause + its honest read-side boundary: `hub-spoke-bridge.md` § Run-Directory Discipline (Spoke Template). Cite it; do not restate it here.

**Honest scope — this MUST is a discipline, not an interlock.** Nothing asserts it per launch, and measurement says it is routinely unmet: across the renders observed in the release that added this note, carriage of a required block ranged from fully intact to entirely absent, and the same untouched clause reached one spoke complete and another at roughly three-quarters. Fidelity varies per launch, so no finite set of observations can discharge a claim of this shape — only a per-launch presence assertion could, and none exists yet. The MUST is retained deliberately rather than softened to match practice: its value is that a deviation is a citable violation instead of a judgment call, and that value survives the absence of enforcement. What does not survive is reading a green pipeline as evidence the clause arrived. It is not evidence; nothing checks.

**Path form — the hub's own obligation, and a different question from the one above.** The run-directory clause governs *where* a spoke's scratch goes and that it is unique. It says nothing about the form of the **other** paths Mode O writes into a brief: the repo working copy, a corpus location, a cited file, a command a spoke is told to run. Those are the hub's own emissions. Every one of them uses a sanctioned form per `core/standards/analysis-workspace-standard.md` § 6.1 — repo-relative, `$HOME`-relative, the sanctioned default-expansion, or a registered operator-instance token. An absolute machine path carrying a username segment, and a bare relative operator-instance path, are never emitted. Where no sanctioned form fits — a harness-supplied ephemeral directory, say — emit the relative name, never the resolved absolute path.

**Why the hub is the fix point, not the spoke.** A brief carries a path into a spoke; the spoke echoes it into a public comment; that echo is IRREVERSIBLE, because editing a published comment does not scrub its edit history. Repairing the brief repairs every downstream spoke at once. Repairing the echo repairs one comment that is already public. The observed instance was 19 occurrences across 8 public issues in a single release, all of them injected by the orchestrator and echoed back.

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

## Spoke-brief path scan (pre-spawn, per launch)

Before each `Agent({…})` call, scan the **rendered** brief — the exact prompt string about to be passed, not the template it came from — and do not spawn on a non-exempt hit.

```
bash core/deploy/tools/path-leak-patterns.sh --scan-file <rendered-brief-file>
```

Exit **0** clean · **1** at least one non-exempt leak, every hit printed as `file:line: text` · **2** the file could not be read, or the flag was not recognized. **Treat 2 as UNKNOWN and do not spawn.** A `--scan-file` invocation against a copy of the primitive that predates that arm returns a usage line and — before this guard shipped — exit 0, which is indistinguishable from clean. Assert the capability before trusting the verdict:

```
grep -q -- '--scan-file' core/deploy/tools/path-leak-patterns.sh
```

Repair a hit by rewriting the path into a sanctioned § Output path form and re-scanning. A line that legitimately must carry a flagged form — a worked example of the leak itself — carries the `path-leak: allow` marker the primitive honors.

**What this guard does not cover, stated so no reader assumes otherwise.**

- **It is hub conformance, not an interlock.** As currently configured, the `PreToolUse` matcher set in `core/settings.json.template` is `Bash` / `Write` / `Edit` / `Read` / `WebFetch` / `mcp__.*` — none of which covers the `Agent` tool, so no wired hook sees a brief. That is a statement about the configuration, not about what the matcher field can express; wiring an `Agent`-tool matcher has not been tested and is not foreclosed.
- **It sees the brief, not the output.** A path a spoke discovers and posts itself is downstream of this scan. `core/hooks/block-gh-path-leak.sh` is the backstop on that surface, subject to its own four-condition coverage boundary.
- **It cannot see a form the detector does not model.** The permitted vocabulary is the set-complement of the primitive's active classes; a form in neither set falls through. `analysis-workspace-standard.md` § 6.1 names the known instance and the rule for it.

**This is where the deferred mechanical check for the hook-response discipline landed, and the routing is deliberate.** It is not static template-to-template parity: both observed failures were **render**-time losses — the template carried the clause and the rendered prompt did not — so a template-parity check would have been green on exactly the failures in evidence. Scanning the rendered artifact is the only form of the check that could have caught them, and even then only for the path class; the obfuscation class remains undetectable by construction.

This is the **fourth** standing pre-spawn guard, composing with the quota-budget gate, the worktree detect-first guard, and the concurrent-PR collision check above.

## Stage-Conditional Launch Policy (when to spawn vs gate)

Auto-launch is bound to the stage's Autonomy Tier: spawn autonomously for Tier-2/3 stages; **preserve the operator gate at Tier-0 — Stage 9 (Plan Review) and Stage 12 (Execute) are NEVER auto-launched.** (Stage-to-Autonomy-Tier table: `hub-spoke-bridge.md` § Stage-Conditional Launch Policy.)

## Recursion prohibition

A spawned spoke MUST NOT invoke the `Agent` tool or `spawn_task`. The hub is the only caller of spoke-launch primitives. (Full posture: [`subagent-security-posture.md`](../../../../core/standards/subagent-security-posture.md).)

## Hook-response guard

Every spoke prompt Mode O renders MUST carry the hook-response clause verbatim. A spoke that trips a hook, guard, or permission control has exactly two moves — **reword** the offending text, or **surface it to the hub** — and never obfuscates a token, nor re-routes a refused action through a second tool, to reach an outcome a control declined. Surfacing is a first-class outcome, not a failure. Every spoke output renders the `Control firings: none | <list>` line whether or not anything fired, so a routed-around control is distinguishable from an absent one. Canonical clause + its honest enforcement boundary: `hub-spoke-bridge.md` § Hook-Response Discipline (Spoke Template). Cite it; do not restate it here.

**Honest scope — this MUST is a discipline, not an interlock.** Nothing asserts it per launch, and measurement says it is routinely unmet: across the renders observed in the release that added this note, carriage of a required block ranged from fully intact to entirely absent, and the same untouched clause reached one spoke complete and another at roughly three-quarters. Fidelity varies per launch, so no finite set of observations can discharge a claim of this shape — only a per-launch presence assertion could, and none exists yet. The MUST is retained deliberately rather than softened to match practice: its value is that a deviation is a citable violation instead of a judgment call, and that value survives the absence of enforcement. What does not survive is reading a green pipeline as evidence the clause arrived. It is not evidence; nothing checks.

## Fallback — manual copy/paste

When the `Agent` tool is unavailable, or an edit-before-launch / debug / cross-session-carry condition applies, the hub prints the full spoke prompt for the operator to paste into a new session. (Conditions F1–F6: `hub-spoke-bridge.md` § Fallback.)
