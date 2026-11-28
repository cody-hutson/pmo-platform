<!-- reference-durability: allow-link -->
# Mode O — Spoke Launch

How Mode O spawns spokes. Elaborates `## Mode O` in [`../SKILL.md`](../SKILL.md); cites `release/references/how-to/hub-spoke-bridge.md` § Spoke Launch Mechanisms for the verbatim parameter contract + the empirical anchors.

> **Path convention in this file.** A repo path written as **text** (`core/…`, `release/…`) names a file that is **not deployed with this skill** — it resolves in the repository and would fail from the installed tree, so it is deliberately not a link. A **markdown link** names a file that *is* deployed beside this one and resolves at runtime. Every clause this file tells the hub to carry verbatim is stated here; the cited canonical homes are provenance the hub reads in the repository, not at launch time.

## Spawn, not skill-chain

Mode O launches every spoke with the **`Agent` tool** (a fresh session) — never in-context Skill-tool invocation. Each spoke is depth-0, so the C1 depth bound (≤ 2 Skill-tool invocations) never engages across a 13-stage run, and the `pmo-release-manager` tail (itself a composer of `release-executor`) is spawned, not Skill-invoked into a depth-3 chain. **The hub is the only spawner.**

## Launch parameters

`Agent({subagent_type, prompt, description, model, isolation, run_in_background})`. Two are load-bearing:
- **`model` — REQUIRED-EXPLICIT** at the PMO surface (never rely on the implicit default).
- **`isolation: "worktree"`** — MUST be pinned for the write stages (6, 12, 13); MAY be used for read-only stages (5, 7, 8), except for a spoke that runs an audit mode and changes no tracked file, which is launched without it (§ Audit output below).

(Full signature table: `hub-spoke-bridge.md` § Spoke Launch Mechanisms § Default.)

## Concurrency — two composing gates (NOT a fixed count)

Concurrency is governed by two gates that compose; there is **no fixed concurrent-count cap** — the doc is explicit that a fixed count is not the binding predictor. Note the asymmetry between them: gate 1 is scoped by stage, gate 2 is **not scoped at all** — it fires on every launch, including the singleton launches gate 1's write-serialized stages produce.

1. **Stage parallelism class** — Stage 5 / 7 / 8 are **parallel-safe** (output channel = a GitHub Issue comment; no file-contention surface); Stage 6 / 13 are **write-serialized** (commit / main mutation — one at a time).
2. **Quota-budget gate (Procedure 2 Step 5.5 / Checkpoint B)** — fires before **EVERY `Agent`-tool launch, wave or singleton, at every stage**. It is a standing pre-launch step (each launch faces a different remaining envelope — mid-release drift, window-boundary crosses), not a one-time Stage-4 estimate; a serial stage bounds the concurrent-batch surface, never the envelope. **What it weighs — two independent axes, either sufficient to block:** the *remaining* per-account 5-hour **usage-window** envelope (`tokens_per_spoke × N` against what is left) and the **host-API quota** (the host's separate `core`/REST and `graphql` pools). **Verdict depth follows launch shape:** a wave (N ≥ 2) renders ∈ {**PROCEED** / **SERIALIZE** / **DEFER** / **REDUCE-scope**}; a singleton (N = 1) renders the reduced ∈ {**PROCEED** / **DEFER**} — `SERIALIZE` is meaningless at N=1 and `REDUCE-scope` stays a pre-verdict mitigation, not a singleton verdict. **Wave width is a second output, not a verdict:** alongside the verdict the gate returns **`W_max`** — the cap on spokes in flight at once — keyed on the same remaining-envelope basis, with `⌈N/W_max⌉` re-gated sub-waves when `W_max < N` and `W_max n/a` at N=1. Render it on the same line. Cumulative draw does not change with width; **interruption cost does** — a wave that dies mid-flight loses every spoke in it, so width is the only lever on that loss. Cite the table; do not restate it. **The host-API axis** is evaluated once per *routing turn* by running `release/tools/host-api-axis-verdict.sh` from the repository root (a repository path, not deployed with this skill): one REST probe and two GraphQL probes, each pool's counter read in-band from the probe's own response. It renders ∈ {**PROCEED** / **DEFER**} — DEFER for a pool below the 20 %-remaining floor, `CONTRADICTED`, or `UNANCHORED` — and combines **DEFER-dominant**: a host-API DEFER makes Checkpoint B render DEFER, otherwise the usage-window verdict passes through unchanged — **no new verdict token is minted**. **Cost — stated per axis, because the two differ:** the usage-window axis is zero tool calls (a hub-side reasoning step over state the hub already holds, not an instrument, so it cannot draw against the envelope it protects); the host-API axis is one evaluator run per *routing turn*, reused for every launch issued in that turn: three metered requests (at most five, with re-probes), certain and bounded, plus one hub tool call against the *usage-window* axis — its **cross-axis** cost. At that draw, per-launch firing stays affordable and no launch shape is too small to gate. **Render the verdict every time, including PROCEED, naming BOTH bases** — the gate emits no event, so the rendered line is the only way a skipped gate is distinguishable from a cleared one, and with two axes a verdict naming no basis cannot say which axis produced it; for the host-API axis the line carries the evaluator's `RENDER` output verbatim: per pool, its basis, and for an anchored reading only, `remaining/limit` and that reading's evidence grade. **`UNSTATED` handling:** with no stated envelope, render `UNSTATED` + the conservative default and never a synthesized percentage; on the host-API axis, a transport or non-quota failure, a probe answered without a counter, or a non-zero evaluator exit gives basis `UNSTATED` and **fails open** to PROCEED with the reason rendered — none of them carries an exhaustion signal, and a non-zero run is never read as a verdict. **A host-API PROCEED attests that reads were available at the probe. It does not attest that writes will be**: the write-scoped half of presentation (c) — content creation, mutation weight — stays a named residual (§ 4.3b). **Fail-open has a carve-out:** a *real call refused on quota grounds* is not a probe failure — it is the axis's strongest positive evidence, renders basis **`CONTRADICTED`** and verdict **DEFER**, and does not inherit fail-open; a real call failing for a **non-quota** reason still does. The classifier is the refusal reason, never the fact of failure (§ 4.3b, and `review-discipline-principles.md` § 8.1 PV-7/PV-7b for the obligation this satisfies). It reads only the refusing call's own response; quota wording elsewhere (a quoted comment, an agent-runtime notice) is never a refusal (§ 4.3b — Refusal-reason classifier). **DEFER names only the recovery its evidence supports:** the reset epoch of an anchored reading or a primary refusal; the retry-after of a secondary refusal; a re-run at the next routing turn for an `UNANCHORED` reading; otherwise at least `60 × 2^N` s, capped at 3600, N being the consecutive-refusal count held on the open DEFER action item — the `refusals_in_a_row` the previous run reported — and passed back as `--prior-refusals` (§ 4.3b). A non-PROCEED verdict surfaces to the operator; it does NOT reclassify any stage's Autonomy Tier. (Spec: `quota-budget-protocol.md` §§ 4.2, 4.3b, 4.3c.)

"Parallel-safe" is a *coordination* property (no shared write surface) — it is orthogonal to the usage-window envelope, against which concurrent spokes still draw cumulatively. It is not a licence for width either: `W_max` comes from Checkpoint B, never from the stage's parallelism class. (Spec: `hub-spoke-bridge.md` § Per-Account Usage Window Constraint + `quota-budget-protocol.md`.)

## Output path

Every spoke prompt Mode O renders MUST carry the run-directory clause verbatim: the spoke resolves ONE run directory (`mktemp -d` under a session scratch base, suffixed with the stage and sub-task number), writes every scratch artifact inside it, reads scratch input only from it, and echoes that directory **in `${SCRATCH_BASE}`-relative form — never the resolved absolute path**, because on a default install the scratch base embeds the operator's OS username and the output comment is a public surface. Uniqueness is by construction, so a re-run of the same stage on the same sub-task cannot land on the prior run's leftovers — the failure a sub-task-keyed path allows. Canonical clause + its honest read-side boundary: `hub-spoke-bridge.md` § Run-Directory Discipline (Spoke Template). Cite it; do not restate it here.

**Honest scope — this MUST is a discipline, not an interlock.** Nothing asserts it per launch, and measurement says it is routinely unmet: across the renders observed in the release that added this note, carriage of a required block ranged from fully intact to entirely absent, and the same untouched clause reached one spoke complete and another at roughly three-quarters. Fidelity varies per launch, so no finite set of observations can discharge a claim of this shape — only a per-launch presence assertion could, and none exists yet. The MUST is retained deliberately rather than softened to match practice: its value is that a deviation is a citable violation instead of a judgment call, and that value survives the absence of enforcement. What does not survive is reading a green pipeline as evidence the clause arrived. It is not evidence; nothing checks.

**Path form — the hub's own obligation, and a different question from the one above.** The run-directory clause governs *where* a spoke's scratch goes and that it is unique. It says nothing about the form of the **other** paths Mode O writes into a brief: the repo working copy, a corpus location, a cited file, a command a spoke is told to run. Those are the hub's own emissions. Every one of them uses a sanctioned form per `core/standards/analysis-workspace-standard.md` § 6.1 — repo-relative, `$HOME`-relative, the sanctioned default-expansion, or a registered operator-instance token. An absolute machine path carrying a username segment, and a bare relative operator-instance path, are never emitted. Where no sanctioned form fits — a harness-supplied ephemeral directory, say — emit the relative name, never the resolved absolute path.

**Paths the hub writes TO — the other half of that same obligation.** The rule above governs the paths Mode O *emits*. The paths Mode O *writes to* are governed too, and by exactly one location: every body the hub stages before posting — issue and PR bodies, decision-record and stage comments, milestone-description revisions, cross-milestone notices — is written inside the release run's staging directory under the operator-instance hub-state path, and nowhere else, for the life of the run. That staging ends at the release close's orphan-state cleanup step, and a body the operator means to keep past the run is moved to the operator's own area rather than left in it. Canonical clause, its lifecycle, and its honest scope: `release/references/how-to/hub-spoke-bridge.md` § Hub Staging Discipline. Cite it; do not restate it here.

**Why the hub is the fix point, not the spoke.** A brief carries a path into a spoke; the spoke echoes it into a public comment; that echo is IRREVERSIBLE, because editing a published comment does not scrub its edit history. Repairing the brief repairs every downstream spoke at once. Repairing the echo repairs one comment that is already public. The observed instance was 19 occurrences across 8 public issues in a single release, all of them injected by the orchestrator and echoed back.

## Audit output — launch shape, staging and promotion

A spoke briefed to run an audit mode that emits a dated analysis folder gets that folder to the analysis home according to the shape it is launched in. The rule and its reasons are stated in `core/standards/analysis-workspace-standard.md` § Spoke-run analysis. The hub's steps are stated here in full, because the hub runs them from the installed skill.

**At launch.**

1. **Choose the shape.** A spoke whose run changes no tracked file launches **without** `isolation`. A spoke whose run also changes a tracked file launches **with** `isolation: "worktree"`: an audit mode that overwrites a committed summary surface, or any Stage 6, 12 or 13 spoke.
2. **Choose the folder name.** List the home for the mode's own name for the day, `<name>-<UTC date>/`. If that name is taken, brief the spoke `<name>-run<N>-<UTC date>/`, with `N` the lowest number from 2 not already taken at the home. The date stays last, as the analysis standard's folder convention requires, and the mode's own pointers then carry the final name. Step R-4 still stops on a name taken after this check.
3. **Open the record before the spawn.** Add one full 13-field row to the run's `action-items.md`, per `core/standards/hub-action-tracking.md` § 2:
   - `id` the next free `AI-NNN`; `created_at` now; `source_stage` the launching stage; `source_sub_task` the spoke's sub-task;
   - `category` `verification`, `owner` `hub`;
   - `description` `analysis output of spoke #<sub-task>: confirm it at the analysis home` without isolation, or `analysis output of spoke #<sub-task>: promote it to the analysis home and confirm it` with isolation;
   - `trigger_type` `event`, `trigger_detail` `return of the spoke for #<sub-task>, before any removal of its worktree`;
   - `target` `file:<OPERATOR_INSTANCE_ANALYSIS_PATH>/`, `status` `open`, `resolved_at` `—`, `resolution` `—`.

   Read the row back. The commitment sweep renders it. Only `status`, `resolved_at` and `resolution` change afterwards.
4. **Render the matching clause verbatim** into the brief, with step 2's folder name in place of `<folder>`. Write the home in a § Output path form; in the clause without isolation, write it in the `$HOME`-relative form or as the token, never repo-relative.
   - *Without isolation:* "**Audit output.** Write your run's dated analysis folder at the analysis home, `<home>/<folder>/`. That is the main checkout's git-ignored workspace, which the registered-homes carve-out admits from any working directory. You share the launching session's working tree, and its own git-ignored `analysis/` is not the home: before you write, confirm that the target sits under the main checkout's root, the parent of `git rev-parse --path-format=absolute --git-common-dir`, and not under `git rev-parse --show-toplevel` where the two differ. Use the file-write tools or a shell write. A write any control refused is never re-attempted through the shell. End your output's Evidence section with one line: `Analysis output: written — <OPERATOR_INSTANCE_ANALYSIS_PATH>/<folder>/ (<N> files)`, or `Analysis output: none — <reason>` if the run wrote no folder."
   - *With isolation:* "**Audit output (isolated spoke).** You write the analysis home on no channel: the harness confines your file-write tools to your own worktree, and the hub promotes your folder after you return. A refusal is reported, never re-attempted through the shell.
     - Write your run's dated analysis folder at the same relative path inside your own worktree, `analysis/<folder>/` under `git rev-parse --show-toplevel`, with the file-write tools.
     - Make the tracked change your run requires and leave it in place. Do not remove the folder.
     - End your output's Evidence section with one line: `Analysis output: staged — <your worktree root relative to the main checkout's root>/analysis/<folder>/ (<N> files)`, or `Analysis output: none — <reason>`. The main checkout's root is the parent of `git rev-parse --path-format=absolute --git-common-dir`."

**At return.** Two steps fire inside Procedure 4, before routing: the listing R-0, for every spoke, and, for a briefed spoke, its row, which the Procedure 4 action-item scan fires (`open` → `in-flight`). Then:

- **R-0.** For every spoke, briefed or not, list the `analysis/` folder of the tree it ran in: the spoke's own worktree, at the path its Agent result names, or the hub's own worktree for a spoke launched without isolation. An entry there other than `README.md` is a folder a run left in a worktree. If no row covers it, open one now as in launch step 3, in the isolated form, and carry it through R-3 to R-7 with that tree as the source. The same listing runs once more at Stage 13, before the orphan-state sweep, over every worktree the run's spokes ran in, using the paths their Agent results named.
- **R-1.** Read the spoke's `Analysis output:` line from its output comment, from a trusted author only.
  - On `none` with R-0's listing empty, set `status` `done` and `resolution` `no folder — <reason>`: the check ran and found nothing to promote. If R-0 found a folder, go on by R-3 with that tree as the source. The hub never cancels a row; that transition is the operator's.
  - With no `Analysis output:` line at all, list both the home and the spoke's tree for a folder dated that UTC day. Go on by R-2 if it is at the home, by R-3 if it is in the tree, or leave the row `in-flight` and surface it if it is in neither.
- **R-2.** On `written`, list the folder at the home and run `git -C <main checkout> check-ignore -q` on its `SUMMARY.md` (exit 0). Set `status` `done` and `resolution` `at home — <folder in token form> (<N> files)`. Stop here. If the folder is absent from the home, list `<hub worktree>/analysis/<folder>/`: when it is there, promote it by R-3 to R-7 with the hub's worktree as the source; when it is nowhere, leave the row `in-flight` and surface it.
- **R-3.** On `staged`:
  - The source is the main checkout's root joined with the reported path. The destination is the home plus the folder name.
  - Count the source's files.
  - If the source is absent, leave the row `in-flight` and surface the loss to the operator. A lost folder never resolves its own row: only the operator's ruling moves it to `cancelled`, with `resolution` `lost — <the ruling>`.
- **R-4.** If the destination already exists and `diff -r` shows it identical to the source, go to R-6. Otherwise stop and surface it. Never overwrite a folder at the home.
- **R-5.** Copy the folder with `mkdir -p <destination>`, then `cp -R <source>/. <destination>/`. The hub's file tools reach the main checkout, so the registered-homes carve-out sanctions this shell write inside the home.
  - If a control refuses the copy, fall back to the file-write tools, the channel the carve-out is enforced on: read each file of the source (the Read tool, or a shell read) and write it with `Write` to the same relative path under the destination.
  - A file too large for one `Write`, or a `Write` a control refused, goes to the operator, never back to the shell. Give a one-line copy command in a fenced block, with its reversibility tier and the read-back you will run. The row stays `in-flight` until the operator reports the copy done.
- **R-6.** Verify all three: `diff -r <source> <destination>` exits 0; the two file counts match; `git -C <main checkout> check-ignore -q <destination>/SUMMARY.md` exits 0.
- **R-7.** Set `status` `done` and `resolution` `promoted <folder> (<N> files) from <reported path>; diff -r clean`, and read the row back.
  - Then dispose of the run's tracked change. When the launching stage commits (6, 12 or 13), the spoke has committed it on its branch as that stage requires. Otherwise, in the same routing turn, carry the change onto the release branch from the spoke's worktree or open a `deferred-edit` row for it. After either, the change no longer depends on the worktree.
  - Retire the staged copy with `trash <absolute source path>`, so the orphan-state sweep can reap the worktree later. That sweep never removes a worktree holding git-ignored files.

**A hub resuming after a cut-off** reads the `open` and `in-flight` rows whose description begins `analysis output of spoke #`. For each, it takes the spoke's `Analysis output:` line from the spoke's output comment and runs R-1 to R-7 unchanged. A row left unresolved blocks the release's close at the Stage 13 action-item gate.

**Honest scope — a discipline, not an interlock.** Nothing asserts per launch that the shape was chosen, the row opened or the clause rendered, nor per return that the listing ran. For a briefed run the row is the observable: an audit spoke with no row, or a row still open at close, makes the gap visible. A run no brief predicted is visible only through R-0's listing.

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

Auto-launch is bound to the stage's Autonomy Tier: spawn autonomously for Tier-2/3 stages; **preserve the operator gate at Tier-0 — the Procedure 5 gates (the Hub Gate Register rows whose `Proc` is 5 — `orchestration-playbook.md`) are NEVER auto-launched.** (Stage-to-Autonomy-Tier table: `decision-briefing.md` § Gate 0, Input 1.)

## Recursion prohibition

A spawned spoke MUST NOT invoke the `Agent` tool or `spawn_task`. The hub is the only caller of spoke-launch primitives. (Full posture: `core/standards/subagent-security-posture.md`.)

## Hook-response guard

Every spoke prompt Mode O renders MUST carry the hook-response clause verbatim. A spoke that trips a hook, guard, or permission control has exactly two moves — **reword** the offending text, or **surface it to the hub** — and never obfuscates a token, nor re-routes a refused action through a second tool, to reach an outcome a control declined. Surfacing is a first-class outcome, not a failure. Every spoke output renders the `Control firings: none | <list>` line whether or not anything fired, so a routed-around control is distinguishable from an absent one. Canonical clause + its honest enforcement boundary: `hub-spoke-bridge.md` § Hook-Response Discipline (Spoke Template). Cite it; do not restate it here.

**Honest scope — this MUST is a discipline, not an interlock.** Nothing asserts it per launch, and measurement says it is routinely unmet: across the renders observed in the release that added this note, carriage of a required block ranged from fully intact to entirely absent, and the same untouched clause reached one spoke complete and another at roughly three-quarters. Fidelity varies per launch, so no finite set of observations can discharge a claim of this shape — only a per-launch presence assertion could, and none exists yet. The MUST is retained deliberately rather than softened to match practice: its value is that a deviation is a citable violation instead of a judgment call, and that value survives the absence of enforcement. What does not survive is reading a green pipeline as evidence the clause arrived. It is not evidence; nothing checks.

## Write-early guard

Every spoke prompt Mode O renders MUST carry the write-early clause verbatim. A spoke produces output early and banks it as it goes, ordering its work so an interruption costs the least-valuable part; the form is channel-differentiated — the **commit** channel (Stages 6 / 12 / 13) pushes each coherent slice rather than saving one terminal push, while the **comment** channel (Stages 5 / 7 / 8) has one atomic write by design and so banks by **ordering, not incrementality**: load-bearing analysis before elaborative reads, composed output accrued into `$SPOKE_OUT` as evidence lands. Canonical clause + its honest bounded-loss boundary: `hub-spoke-bridge.md` § Write-Early Discipline (Spoke Template). Cite it; do not restate it here.

**Honest scope — this MUST is a discipline, not an interlock.** Nothing asserts it per launch, and measurement says it is routinely unmet: across the renders observed in the release that added this note, carriage of a required block ranged from fully intact to entirely absent, and the same untouched clause reached one spoke complete and another at roughly three-quarters. Fidelity varies per launch, so no finite set of observations can discharge a claim of this shape — only a per-launch presence assertion could, and none exists yet. The MUST is retained deliberately rather than softened to match practice: its value is that a deviation is a citable violation instead of a judgment call, and that value survives the absence of enforcement. What does not survive is reading a green pipeline as evidence the clause arrived. It is not evidence; nothing checks.

**A second boundary this block owns and its two siblings do not.** Even when the clause *is* carried and followed, what it buys a comment-channel spoke is bounded to a **resumable session**: it does not bank work across a re-spawn, because a fresh spawn resolves a fresh run directory and § Output path forbids reading another run's artifacts. So a spoke killed and re-spawned starts from nothing regardless of how early it wrote. State that when rendering the block; a reader who takes "bank as you go" to mean re-spawn-durable has over-read it.

## Fallback — manual copy/paste

When the `Agent` tool is unavailable, or an edit-before-launch / debug / cross-session-carry condition applies, the hub prints the full spoke prompt for the operator to paste into a new session. (Conditions F1–F6: `hub-spoke-bridge.md` § Fallback.)
