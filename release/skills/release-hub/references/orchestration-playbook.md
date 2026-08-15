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

After plan approval the hub creates the release's **stage sub-tasks** via `gh issue create` (hub mechanical work, NOT a spoke launch) — **per-issue for Stages 5–8, one release-scoped sub-task for each of Stages 9–13**, Stage 4's having been created at Procedure 0 Step 5. Scope follows the **stage number**, never the title grammar. Every creating call carries `--milestone`, `--label sub-task` and the body's `<!-- subtask-scope: issue:#N -->` / `<!-- subtask-scope: release -->` marker; a sub-task created without its milestone is invisible to every milestone-scoped query the pipeline runs. The hub then reads the Release Class, immediately closes skipped sub-tasks with the **Skip Closure Format**, and sequences the rest.
- **Step 6.5 — completeness verification:** run `check-milestone-epic-membership.py --milestone "{MILESTONE}" --leg M3` before presenting; a non-empty load-bearing finding set blocks the presentation, and so does a `SKIP_MS … not-yet-scaffolded` row — `COUNT_M3 0` alone cannot tell a clean scaffold from an absent one (read the rows, not the count).
- **GATE (operator):** review the scaffold (incl. the skipped list, `M3_DENOM` and `SCAFFOLD_MARKER`) before routing.

(Verbatim Sub-Task Template + Skip Closure Format: `hub-spoke-bridge.md` § Procedure 1.)

## Procedure 2 — Routing (what's next)

The control-flow core. The hub:
1. Lists sub-tasks; identifies the **dependency-met actionable subset** (never spawns an unmet-dependency sub-task).
2. Runs the **Collective Review check** before any Stage-6 routing (fires when ≥2 issues have Solutioning active and all Stage-5 sub-tasks are closed → operator scope-lock GATE).
3. Runs the action-item scan ([`hub-action-tracking.md`](../../../../core/standards/hub-action-tracking.md)).
4. Before **every** spawn: runs the **quota-budget gate** — wave *or* singleton, at every stage including the write-serialized 6/13 — and honors the **parallelism class**, which is the stage-scoped half of the pair ([`spoke-launch.md`](spoke-launch.md)). A wave renders the full four-value verdict; a singleton renders the reduced PROCEED/DEFER form. The verdict is rendered on every launch, PROCEED included — the gate emits no event, so an unrendered verdict is indistinguishable from a gate that never ran.
5. **Per-wave concurrent-PR check (pre-spawn):** before spawning a build spoke for issue #N, query open PRs referencing that issue (`gh pr list --state open --search "#N"` or equivalent; N = the target issue number). If an open PR already references it, **surface to the operator — proceed / adopt / skip — BEFORE spawning**, never deferred to the Stage 7/8 coherence review. **Re-run every wave** (not once at Stage 4): the open-PR population changes mid-run, so a clean planning-time scan does not carry ([`spoke-launch.md`](spoke-launch.md)).
6. **Per-launch spoke-brief path scan (pre-spawn):** scans the **rendered** brief — not the template — with `core/deploy/tools/path-leak-patterns.sh --scan-file`, and does not spawn on a non-exempt hit. Exit 2 (unreadable file, or a copy of the primitive predating the arm) is UNKNOWN, not clean; assert the arm exists before trusting a verdict. This is the fourth standing pre-spawn guard ([`spoke-launch.md`](spoke-launch.md)).
7. Spawns the wave.

## Procedure 3 — Spoke prompt construction

When spawning a per-issue stage spoke (5–13), the hub builds the prompt from the **Spoke Template** (`hub-spoke-bridge.md` § Procedure 3 — read verbatim) + the stage's persona card (`release-personas.md`, via the Stage-to-Persona Mapping). The prompt-construction disciplines (PR-body parser-clean, repo-integrity, spec-anchor, worktree detect-first, hook-safe git, hook-response, sanctioned path form in every path the brief emits, the per-stage chip patterns) are authoring rules the hub applies — each cites its canonical pipeline-shard in `hub-spoke-bridge.md` § Procedure 3. The hub is the ONLY spawner; a spoke never self-spawns (recursion-prohibition: [`spoke-launch.md`](spoke-launch.md)).

## Procedure 4 — Spoke completion handling

After a spoke (or batch) returns: read the return value + output comment; verify closure; assess sufficiency; **evaluate the spoke's recommendations adversarially** against release-wide context (verify, don't rubber-stamp — R1 in [`decision-briefing.md`](decision-briefing.md)); produce a **Decision Briefing**; route only after the operator renders every decision. The action-item scan composes here.

## Procedure 4a — Emit on decision (MANDATORY)

Every operator-rendered decision and every hub-rendered determination emits BOTH surfaces
before routing continues. Neither alone is sufficient (`core/standards/hub-session-continuity.md` § 6).

1. Post the "Decision Recorded" comment on the relevant sub-task.
2. Invoke `release/tools/append-pipeline-event.sh` once per decision. Take
   `event_type` / `event_subtype` from the mapping table in
   `core/standards/hub-session-continuity.md` § 3.2 — that table is the ONLY
   mapping source; this playbook does not restate it. For AI-NNN status
   transitions the mapping source is `core/standards/hub-action-tracking.md` § 3.
   For the autonomous `self-repair/*` seams (retry / escalate / rollback) the
   mapping source is `core/disciplines/autonomous-execution-model.md` § Emission,
   which also owns their emit points — this is the same step, not a second procedure.
   For the spawn-vs-hub-direct fork (`decision`/`delegation`) the mapping source
   is `core/disciplines/decision-discipline.md` § 3.1, which owns the merit test
   that decides whether the fork emits at all — routine template routing emits
   nothing, and that silence is correct.
3. Set `--subject` to the decision's scope (`milestone:#N` / `issue:#N` / `sub-task:#N`)
   and open `--payload` with the release-stable token `ms:#<milestone-number>;`
   (see § 4a.2 Join-key note).
4. Render the "Events emitted this routing point" block in the Decision Briefing.
   Omission is a structural defect. **Read every row back from the log before that
   block renders** — the block reports what the log CONTAINS, not what this routing
   point intended, and a block claiming rows the log does not hold is the worse
   defect of the two.

   Run the read-back from the repository root, once per emitted class, taking the
   count TWICE with the identical invocation: once immediately before the step-2
   append (`PRE`) and once after it (`POST`). The `PRE` read belongs to this step
   even though it happens at step 2's moment — a delta cannot be observed from one
   side.

   ```bash
   release/tools/query-pipeline-event.sh --release "<MILESTONE_SLUG>" \
     --event-type <t> --event-subtype <s> --stage <the value step 2 passed> --count
   ```

   Assert `POST == PRE + N`, where `N` is the number of rows this routing point
   emitted for that class at that stage.

   **Assert the delta; never a non-zero absolute.** An absolute count answers "does
   a row of this class exist ANYWHERE in this release" — a question an earlier
   routing point has usually already made true, so a rule written about a zero can
   never fire. Measured on a completed release: the unqualified count of
   `gate-outcome/plan-review-go` read **10**, of which **8** rows already existed
   when the Stage-9 gate opened. `--stage` plus the `PRE`/`POST` pair is what
   narrows the question to THIS write. A pre-emit ABSENCE check asks the opposite
   question, and an absolute zero is the right answer for it — do not transplant
   its shape to a post-emit PRESENCE check.

   Exactly four outcomes, and only the first continues routing:

   | Observed | Reading | Routing |
   |---|---|---|
   | `POST == PRE + N` | the rows landed | continue |
   | `POST < PRE + N` (incl. `POST == PRE`, and `0`) | the write did not land | **BLOCKED** — structural defect. Emit the missing row, then re-read. |
   | `POST > PRE + N` | a surplus row of this class exists | **BLOCKED** — structural defect. Do NOT emit again; reconcile the surplus first. |
   | no integer on stdout, or a non-zero exit | the probe could not answer | **BLOCKED** — unverified, which is neither a zero nor a pass. Fix the invocation and re-read. |

   **Why a surplus blocks, and why "emit the row" is not the reflex remedy.**
   `gate-outcome/plan-review-go` is consumed downstream as the EARLIEST matching row
   of the release, so a second row of it silently re-anchors the release's measured
   GO→deploy duration. Writing another row to clear a false alarm converts a
   reporting error into permanent corruption of an append-only log.

   **State the reader's bound, so a zero is not over-read.** `--release` matches the
   milestone slug in the `version` column — rung 1 of the read ladder in
   `release/references/standards/pipeline-event-log-schema.md` § 2a. It does NOT
   resolve the `subject == milestone:#N` rung. Every row this procedure writes
   carries the slug (step 3 and § 4a.2), so the bound holds by construction here —
   but a `0` from this reader is not a verdict about rows written any other way.
   Pass `--release "<MILESTONE_SLUG>"`, never `--version vX.Y`: the version column
   is provisional pre-claim, and a `vX.Y` filter returns zero rows for a slug-keyed
   release — a silent zero indistinguishable from a failed emission.

   Attest the observed `PRE` → `POST` pair per class in the line BENEATH the block,
   alongside the total already recorded there. The block's own column set is
   normatively declared in `release/skills/release-hub/references/decision-briefing.md`
   § Principle item 5 and is NOT changed here — the read-back is attested beside the
   table, never as a new column inside it.
5. When the hub or a spoke makes a durable commitment — one of the `category`
   values below — append an `AI-NNN` row to `action-items.md` per
   `core/standards/hub-action-tracking.md` § 2 (13 fields; zero-padded id; not
   reused), run § 4a.1 first if the file does not exist, and emit the matching
   `decision`/`action-item-opened` row. Every subsequent status transition emits
   its mapped `action-item-*` subtype per that standard's § 3.

<!-- Restated from core/standards/hub-action-tracking.md § 2.1, which is NOT
     deployed: this file ships inside packages/release-hub.skill and is read at
     ~/.claude/skills/release-hub/references/. Held in parity by deploy.sh
     Check 68 (enum-parity). Edit the standard first, never this line.
category enum: deferred-edit / reminder / cleanup / decision-to-post /
               cross-issue-merge / verification / decision-deferred
-->

A routing step that advances with a rendered decision and no emitted row is incomplete.

### 4a.1 — Hub-state lazy creation (first write only)

Before the FIRST write to any hub-state surface this release (`pending-approvals.md`,
`action-items.md`, `sessions.md`), and never before: copy the tracked template from
`release/releases/hub-state/<surface>.md.template` into the runtime directory and
substitute the milestone slug into the frontmatter. The canonical template-copy
protocol is `core/standards/hub-session-continuity.md` § 7.3 — run it verbatim; do
not hand-roll the copy.

The runtime directory is keyed on the MILESTONE SLUG, not the version: the version is
provisional until the Stage-12 claim (ADR-092), and a release can be re-versioned
mid-pipeline when a sibling claims the slot ahead of it. READERS resolve the directory
slug-first, version-second (§ 4a.3) so releases created under the older version-keyed
convention stay readable.

Do NOT pre-create empty per-release directories (`core/standards/hub-session-continuity.md` § 2).

### 4a.2 — Join-key note (release-stable key in `--payload`)

The event log's `version` column is **not** a release identity. It is written pre-claim
from a provisional value (ADR-092), so it is neither unique across releases nor stable
within one — concurrent hubs rule-compute the same next-free slot, and a release that is
re-versioned mid-pipeline emits rows under two or three different values.

Therefore every hub-emitted row opens `--payload` with `ms:#<milestone-number>;`. The
milestone number is immutable and unique, costs ~9 characters of the 300-character
payload budget, contains no pipe, and needs no schema or validator change. Pass the
milestone slug (not `vX.Y`) to `--version` for the same reason — the slug is bound
pre-claim, the version is not.

**The key surface has landed, and the token is deliberately RETAINED.** The canonical
release join key is now the `version` column carrying the milestone slug —
`pipeline-event-log-schema.md` § 2a (the read ladder + the release→rows inverse). This
step already writes that key, so no re-point is needed. The `ms:#N` payload token is
NOT dropped: it is the only release anchor on rows whose `subject` is `issue:#N` /
`sub-task:#N` / `suite:…` (measured: 29 of 152 live rows carry no milestone subject),
and it costs ~9 of the 300-character budget. Read it as a **redundant secondary
anchor**, not a competing key surface — § 2a rung 1 is canonical, and any conflict
resolves to the `version` column.

**Why `version-claim` is CONDITIONAL, not MUST.** Stage 13 documents version-less
releases, so a version claim is not total over completed releases; tagging it MUST would
make the class assertable by a downstream gate and produce false failures on that path.

### 4a.3 — Resolving the runtime hub-state directory (readers)

```bash
HS="<OPERATOR_INSTANCE_HUB_STATE_PATH>"
DIR="$HS/$MILESTONE_SLUG"                       # canonical (write target)
[ -d "$DIR" ] || DIR="$HS/$RELEASE_VERSION"     # legacy fallback (read only)
```

Writers ALWAYS use the slug form. Readers probe slug then version so pre-cutover
releases remain readable. The fallback is read-only — never create the version form.

### 4a.4 — When a revision takes effect (splits by load path)

The effective moment splits by **load path**, because this file and the Procedure 7a gate
reach the hub differently.

**This playbook (Procedure 4a and § 4a.1) — effective at the next deploy.** This file
reaches the hub only through the Stage-12 deployed mirror, never from the repo tree. A
revision therefore binds releases entering **Stage 4** after the deploy that publishes it
(the deploy row recorded in `release/releases/RELEASE_LOG.md`), while a release already
past Stage 4 keeps the text it started under. The release carrying the revision runs on
the previously deployed copy for its whole run, so its own Procedure 4a obligations do
not fire. That is a structural property of the load path rather than a granted exemption:
an unpublished edit is unreachable by the hub, so no mechanism exists by which a revision
could bind the release that ships it.

**The Procedure 7a predicate — live on merge, no exemption.** `hub-spoke-bridge.md` is not
deployed; it loads from the repo tree, so the revised gate is in force from the merge,
including for the release that ships it. That is safe by construction rather than by
exemption: the gate is warn-mode, so states `NOT-RECORDED` and `EMPTY-LEDGER` surface for
operator attestation and do **not** block, and only an unresolved row blocks. A release
whose emitter has not yet reached it therefore closes honestly through the attestation
path, leaving an auditable trace instead of a silent pass.

## Procedure 5 — Gate handling (the two hard human gates)

**Do NOT spawn a spoke — gates are operator decisions.** The hub reads the prior outputs, runs the action-item scan + (Stage-9 only) the Release Readiness Scan + the goal-conformance check, and presents:
- **Stage 9 — Plan Review (GO / NO-GO):** the release-authorization decision. The hub assembles the evidence; the operator renders GO/NO-GO. **NEVER auto-crossed.**
- **Stage 12 — Execute:** merge + deploy authorization. **NEVER auto-crossed** — the operator renders the Execute decision (not a spoke). **Once authorized, the hub routes the Stage-12 *mechanics* through the spawned `pmo-release-manager` tail** — **B1** (merge) + **B3** (atomic version-claim / signed-tag via `claim-version.sh`) + **B5** (the DEPLOYED RELEASE_LOG-row chore PR), run via `release-executor` — **never a bare `gh pr merge` by the hub** (the orchestrator running stage mechanics directly is the ADR-019 fat-orchestrator anti-pattern; "No stage mechanics" per SKILL.md `## What This Skill Does NOT Do`). **Guard:** a merged release left with no DEPLOYED RELEASE_LOG row + no version tag **blocks / flags before close-out with a remediation prompt** (not a bare preflight FAIL) — this catches a Stage-12 that landed merge-only.

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

### The emission contract

Each gate above emits the named event per Procedure 4a. `MUST` rows fire in every completed
release and are the ONLY rows a downstream gate may assert on. `CONDITIONAL` rows fire only
when their gate fires.

<!-- EMISSION-CONTRACT:BEGIN -->
| gate | procedure | event_type | event_subtype | actor | obligation |
|---|---|---|---|---|---|
| plan-approval | 0 | decision | scope-lock | operator | MUST |
| stage-9-go | 5 | gate-outcome | plan-review-go | operator | MUST |
| stage-12-execute | 5 | decision | d-class | operator | MUST |
| outcome-statement | 0 | decision | outcome-statement-authored | operator | CONDITIONAL |
| d-version | 0 | decision | d-class | hub | CONDITIONAL |
| scaffold-review | 1 | decision | d-class | operator | CONDITIONAL |
| collective-review | 2 | decision | scope-lock | operator | CONDITIONAL |
| quota-budget | 2 | decision | d-class | operator | CONDITIONAL |
| inter-stage-escalation | 4 | escalation | tier-2 | hub | CONDITIONAL |
| version-claim | 5 | decision | d-class | hub | CONDITIONAL |
| early-merge | 6 | decision | d-class | operator | CONDITIONAL |
| action-item-open | 4 | decision | action-item-opened | hub | CONDITIONAL |
| action-item-close | 7 | decision | action-item-resolved | operator | CONDITIONAL |
| 7a-attestation | 7 | decision | empirical-verification-finding | operator | CONDITIONAL |
| orphan-cleanup-apply | 7 | decision | d-class | operator | CONDITIONAL |
| self-repair | 4 | self-repair | retry | hub | CONDITIONAL |
| delegation-fork | 2 | decision | delegation | hub | CONDITIONAL |
<!-- EMISSION-CONTRACT:END -->

**Why exactly three `MUST` rows.** The partition predicate is *structural guarantee in a
completed release*, not observed frequency. Procedure 1 scaffolding is unreachable without
Procedure 0 plan approval; Procedure 5 Stage-12 is unreachable without a Stage-9 GO;
Procedure 7 close is unreachable without Stage-12 Execute. Those three are total over
completed releases. Every other gate has a reachable path that skips it, so asserting on it
would produce false failures.

**Extension seam.** A downstream slice that adds an emitting gate adds its row *inside* the
`EMISSION-CONTRACT` delimiters — tagged `CONDITIONAL` unless it is total over completed
releases — and extends Procedure 4a step 2 rather than introducing a second emit procedure.
It MUST NOT create a parallel table: exactly one delimited `EMISSION-CONTRACT` block exists
in this file, and the subset lint below reads that block alone.

**Mechanical enforcement.** `release/tools/check-emission-contract-subset.sh` asserts that
the set of event classes a downstream gate *asserts on* is a subset of the `MUST` rows above
— `comm -23 asserted instructed` must be empty. A gate asserting a class this playbook never
instructs fails CI rather than review.
