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

## Procedure 4a — Emit on decision (MANDATORY)

Every operator-rendered decision and every hub-rendered determination emits BOTH surfaces
before routing continues. Neither alone is sufficient (`core/standards/hub-session-continuity.md` § 6).

1. Post the "Decision Recorded" comment on the relevant sub-task.
2. Invoke `release/tools/append-pipeline-event.sh` once per decision. Take
   `event_type` / `event_subtype` from the mapping table in
   `core/standards/hub-session-continuity.md` § 3.2 — that table is the ONLY
   mapping source; this playbook does not restate it. For AI-NNN status
   transitions the mapping source is `core/standards/hub-action-tracking.md` § 3.
3. Set `--subject` to the decision's scope (`milestone:#N` / `issue:#N` / `sub-task:#N`)
   and open `--payload` with the release-stable token `ms:#<milestone-number>;`
   (see § 4a.2 Join-key note).
4. Render the "Events emitted this routing point" block in the Decision Briefing.
   Omission is a structural defect.
5. When the hub or a spoke makes a durable commitment (a deferred edit, reminder,
   cleanup, decision-to-post, cross-issue-merge wait, or post-action verification),
   append an `AI-NNN` row to `action-items.md` per
   `core/standards/hub-action-tracking.md` § 2 (13 fields; zero-padded id; not reused),
   run § 4a.1 first if the file does not exist, and emit the matching
   `decision`/`action-item-opened` row. Every subsequent status transition emits its
   mapped `action-item-*` subtype per `core/standards/hub-action-tracking.md` § 3.

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

This token is **subordinate to whatever release key the join-key work canonicalizes**:
when a dedicated key surface lands, step 3 re-points to it and the payload token is
dropped. This playbook does not canonicalize the join key; it makes sure the write side
carries enough to fix it.

### 4a.3 — Resolving the runtime hub-state directory (readers)

```bash
HS="<OPERATOR_INSTANCE_HUB_STATE_PATH>"
DIR="$HS/$MILESTONE_SLUG"                       # canonical (write target)
[ -d "$DIR" ] || DIR="$HS/$RELEASE_VERSION"     # legacy fallback (read only)
```

Writers ALWAYS use the slug form. Readers probe slug then version so pre-cutover
releases remain readable. The fallback is read-only — never create the version form.

**Cutover (introducing-release-exempt).** Procedure 4a, the § 4a.1 lazy-creation
discipline, and the revised Procedure 7a predicate apply to releases entering **Stage 4**
strictly AFTER this release's deploy SHA recorded in `release/releases/RELEASE_LOG.md`.
**The introducing release is itself exempt** — the playbook reaches the hub only via the
Stage-12 deployed mirror, so it cannot fire on the release that ships it
(reflexive-pipeline-loop discipline). Releases already in flight are grandfathered. Gate
states `NOT-RECORDED` and `EMPTY-LEDGER` surface with operator attestation and do **not**
block, per the shadow→warn→enforce posture.

## Procedure 5 — Gate handling (the two hard human gates)

**Do NOT spawn a spoke — gates are operator decisions.** The hub reads the prior outputs, runs the action-item scan + (Stage-9 only) the 13-dimension Release Readiness Scan + the goal-conformance check, and presents:
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
| early-merge | 6 | decision | d-class | operator | CONDITIONAL |
| action-item-open | 4 | decision | action-item-opened | hub | CONDITIONAL |
| action-item-close | 7 | decision | action-item-resolved | operator | CONDITIONAL |
| 7a-attestation | 7 | decision | empirical-verification-finding | operator | CONDITIONAL |
| orphan-cleanup-apply | 7 | decision | d-class | operator | CONDITIONAL |
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
