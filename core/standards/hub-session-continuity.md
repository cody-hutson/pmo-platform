---
title: Hub Session Continuity
purpose: K1 codified-knowledge standard defining how a new hub session reconstructs release-scoped state from durable artifacts — persistence format, 3-surface state schema, the write-ahead resume pointer and its cadence, 9-step Resume Procedure, composite session-ID, dual-surface Decision Log Mechanism, and the durable-state contract that the queued-approval mechanism rides on
type: standard
status: ACTIVE
source: ""
parallel_to: "agent-handoff-framework.md (sibling K1 standard defining cross-agent handoff contracts; this standard scopes cross-session continuity within a single hub role), hub-action-tracking.md (sibling K1 standard defining action-item schema; rides on this standard's release-scoped substrate convention), pipeline-event-log-schema.md (REUSED by Surface B without schema extension; closed-enum discipline preserved), hub-spoke-bridge.md § Procedure 0b (thin procedural cross-reference pointing to this standard for full schema + behavior)"
reversibility: MODERATE / HIGH confidence (file creation + cross-reference reversible via git revert until downstream consumers — queued-approval mechanism, action-item tracking — build against the schema at their Stage 6)
consumers: "Queued-approval mechanism (consumes Surface A pending-approvals.md schema for queued-approval persistence + Resume Procedure Step 7 for main-thread surfacing); hub-action-tracking standard (consumes the file-based markdown substrate convention — templates at release/releases/hub-state/*.template, runtime instance at <OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/ — for action-item-list placement); agent-handoff framework (composes-with — Agent Handoff Framework's disposition state machine T2 trigger may reference this standard's session-boundary semantics); hub-spoke-bridge.md Procedure 0b (thin procedural binding to Resume Procedure)"
version: ""
---
<!-- reference-durability: allow-link -->

# Hub Session Continuity

## Purpose + Scope

This standard defines how a NEW hub session reconstructs the in-flight state of an active release without operator hand-holding. Three concerns: (1) WHAT state the hub persists across sessions, (2) WHERE that state lives (file paths + schema), (3) HOW a fresh session reads and validates it before routing new work.

The parent issue framed the gap as "a new hub is a shift change with no shift notes." That framing overstates the missing infrastructure — three persistence surfaces already exist per [`hub-spoke-bridge.md` Framework Alignment table, State Persistence row](../../release/references/how-to/hub-spoke-bridge.md): the release plan file at `release/releases/plans/<slug>_RELEASE_PLAN.md`, sub-task comments, and `projects/_config/SESSION_STATE.md`. The actual gap has three parts that this standard closes: (1) NO codified startup read-order knitting the existing surfaces into a coherent context-rebuild; (2) NO release-scoped durable substrate for the queued-approval mechanism; (3) NO explicit drift-detection between hub state and operator decisions across sessions.

**Scope.** Hub state persistence across SESSION boundaries within a single release. Cross-RELEASE state lives in workspace-level surfaces (`SESSION_STATE.md` for workspace handoff, `SWAP_HANDOFF.md` for cross-account handoff) and is out of scope here. Cross-AGENT handoffs (skill-to-skill, spoke-to-spoke, stage-to-stage) are owned by [`agent-handoff-framework.md`](agent-handoff-framework.md). Action-item schemas (deferred edits, follow-ups, reminders) are owned by [`hub-action-tracking.md`](hub-action-tracking.md) (sibling standard) and ride on the substrate convention this standard defines.

**Out of scope.** Skill-internal state. Operator-to-agent prompts. Workspace-level session handoff (Layer 2 — Cowork-owned per [`operations-bridge.md`](<OPERATOR_INSTANCE_CLAUDE_DIR>/rules/operations-bridge.md)). Action-item schema details (owned by `hub-action-tracking.md`). The Agent Handoff Framework's 9-field manifest, disposition state machine, and tier-cascade ordering (owned by `agent-handoff-framework.md`). Schema extensions to `pipeline-event-log.md` (no new event_type proposed; closed-enum discipline preserved).

## 1. D-2 Placement Verdict

Per Stage 5 D-2 verdict on the hub-session-continuity sub-task: the persistence schema + state contract + resume procedure are normative spec material — `core/standards/` is the canonical K1 home per [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md). The verdict IS this file's existence at this path. Sibling NEW standards files (`agent-handoff-framework.md` for the handoff framework, `hub-action-tracking.md` for action-item tracking) converge on the same placement, satisfying R4 N-way consistency at Collective Review. A thin Procedure 0b cross-reference in [`hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md) points operators to this standard for full schema + behavior; the bridge doc does NOT duplicate normative content.

## 2. Persistence Format

**Verdict:** File-based markdown — schema templates tracked at `release/releases/hub-state/*.template`; runtime instance written to the operator-instance path `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/`. The split-class treatment is governed by [`public-repo-vs-operator-instance-taxonomy.md`](public-repo-vs-operator-instance-taxonomy.md) §4.3 — templates ship as CUSTOMIZABLE-PUBLIC so operators have the schema to seed first emit; the runtime instance is OPERATOR-INSTANCE because hub-state mutates on every routing decision (10–50+ writes per release) and tracking the runtime would create release-branch noise with no cross-operator readership benefit.

**Placement class and target home.** The runtime instance is **working state**: its governed home is `/local-state/` in the repository the release belongs to, per the [placement standard](instance-data-placement-standard.md). Until this repository's cutover it still resolves to today's operator-instance path through `<OPERATOR_INSTANCE_HUB_STATE_PATH>`, and every runtime path in this standard reads through that token, so a running hub resumes from where it wrote. The event log Surface B reuses is working state too and resolves through `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>` until the same cutover. An embargoed security-fix run is **leak-risk** until disclosure and is homed with that class, per the same standard; until the resolver takes a run's class, it resolves through `<OPERATOR_INSTANCE_HUB_STATE_PATH>` like every other run, so the Resume Procedure reads it where it was written.

**Rationale (composition with existing infrastructure):** File-based markdown composes directly with [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) (append-only, schema-validated, `append-pipeline-event.sh` writer per [`pipeline-event-log-schema.md`](../../release/references/standards/pipeline-event-log-schema.md)) — both Surface A (pending-approvals) and Surface B (pipeline-event-log) write to operator-instance paths, so the persistence surfaces converge on the same Layer-classification. Hub state is NOT a new file format; it is a release-scoped instantiation of the established workspace pattern.

**Trade-off matrix (file-based markdown vs. external store):**

| Dimension | File-based markdown | External store (SQLite / Redis / etc.) |
|---|---|---|
| Concurrency safety | last-write-wins; acceptable at single-operator PMO scale | transactional semantics |
| Ops surface added | zero new dependencies | runtime dependency; new ops surface |
| Pattern composition | composes with existing `pipeline-event-log.md` append-only pattern | second persistence paradigm in workspace |
| Audit trail | `pipeline-event-log.md` + GitHub Issue comments (Decision Briefing context) ARE the audit trail; runtime hub-state is working state, not audit | external state divergence risk vs. file-based surfaces |
| Query mechanism | `grep` / `gh` CLI / Read tool native | wrapper required for hub agent |
| Reversibility | operator-local file edit / restore | snapshot/restore mechanism needed |
| Cost-to-implement | markdown spec + edit conventions | schema definition + wrapper tooling + migration story |
| Single-operator-PMO fit | matches workspace scale | overkill |
| **Verdict** | **PREFERRED** | rejected |

**Layer classification:** **Templates** ship at Layer 1 (`release/releases/hub-state/*.template` — tracked under `pmo-platform/`). **Runtime instance** is Layer 2 and never tracked: it is working state, its governed home is the placement standard's (see *Placement class and target home* above), and until this repository's cutover it lives at `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/` — operator-local. The split avoids dozens of micro-commits per release for state with no cross-operator readership. Per [`operations-bridge.md`](<OPERATOR_INSTANCE_CLAUDE_DIR>/rules/operations-bridge.md), the existing Layer 2 `projects/_config/SESSION_STATE.md` is preserved for workspace-level handoff (cross-release, ephemeral, Cowork-owned). The three surfaces are complementary — hub-state runtime is release-scoped + operator-local + durable across hub sessions; SESSION_STATE is workspace-scoped + ephemeral.

**Directory creation discipline:** The template directory `release/releases/hub-state/` (with `*.template` files) is created at this standard's landing and lives in pmo-platform. Per-release runtime subdirectories at `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/` are created LAZILY by the hub on first surface emit (the hub copies the template, substitutes the milestone slug into the frontmatter, and appends the first row). Hubs do NOT pre-create empty per-release runtime directories.

## 3. State Schema

Hub state partitions across THREE surfaces by concern. The three partition the run's record, and each grows by appended rows rather than being rewritten. The resume pointer (§ 3.4) is a further file in the run folder, not a fourth partition of that record: it is one file, rewritten whole at each checkpoint, that says where the run stands and holds what no record carries. Where the pointer and the record disagree, the record wins.

### 3.1 Surface A: Pending-Approval Queue (NEW substrate for queued approvals)

**Template (tracked):** [`release/releases/hub-state/pending-approvals.md.template`](../../release/releases/hub-state/pending-approvals.md.template)
**Runtime instance (operator-local):** `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/pending-approvals.md`

**Frontmatter (YAML):**

```yaml
---
schema_version: "v1.0"
milestone: "<milestone-slug>"
created_at: "<ISO 8601 UTC of first row enqueue>"
last_updated: "<ISO 8601 UTC of most recent row mutation>"
last_session_id: "<worktree>__<ISO-start>__<short-sha>"
---
```

**Body (markdown table — append-only with status column):**

```markdown
## Pending Approvals

| id | created_at | source_stage | source_sub_task | decision_type | options | recommended | context_pointer | reversibility | confidence | status | resolved_at | resolution |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| PA-001 | 2026-05-23T14:22:01Z | 5 | #NNNN | d-class:D-2 | NEW-file,section | NEW-file | sub-task:#issuecomment-N | CHEAP | HIGH | pending | — | — |
```

**Field semantics:**

| Field | Type | Required | Purpose |
|---|---|---|---|
| `id` | string `PA-NNN` | YES | Stable identifier within release; zero-padded; not reused |
| `created_at` | ISO 8601 UTC | YES | Original enqueue time |
| `source_stage` | int 1..13 | YES | Pipeline stage that generated the approval |
| `source_sub_task` | string `#NNNN` | YES | GitHub Issue (sub-task) carrying the originating context |
| `decision_type` | enum: `d-class:D-N` / `scope-lock` / `gate:go-no-go` / `tier-N-escalation` / `disposition` / `override` | YES | Maps to existing decision taxonomy |
| `options` | comma-list | YES | Verbatim from Decision Briefing (≤ 80 chars; longer → context_pointer) |
| `recommended` | string | YES | Spoke + hub aligned recommendation (or `divergence-noted`) |
| `context_pointer` | URL or `file:section` | YES | Where the full Decision Briefing context lives (sub-task comment URL preferred) |
| `reversibility` | enum: CHEAP/MODERATE/EXPENSIVE/IRREVERSIBLE | YES | Per [`reversibility-protocol.md`](../specs/reversibility-protocol.md) |
| `confidence` | enum: HIGH/MEDIUM/LOW | YES | Per recommendation |
| `status` | enum: `pending` / `resolved` / `superseded` / `withdrawn` | YES | Append-only state column; rows mutate in-place ONLY to update status + resolved_at + resolution |
| `resolved_at` | ISO 8601 UTC or `—` | YES | Resolution time; `—` when status=pending |
| `resolution` | string or `—` | YES | Operator's chosen option (verbatim from `options`); `—` when status=pending |

**Schema enforcement:** Hub validates the table at read-time. Malformed rows surface as drift to operator; hub does NOT auto-repair (operator-write only when modifying rows).

### 3.2 Surface B: Hub Decisions Log (REUSE existing `pipeline-event-log.md`)

**No new file.** Hub decisions emit existing event types per [`pipeline-event-log-schema.md § 3`](../../release/references/standards/pipeline-event-log-schema.md):

| Decision class | event_type | event_subtype | actor |
|---|---|---|---|
| D-class verdict rendered | `decision` | `d-class` | `operator` |
| Collective Review scope-lock | `decision` | `scope-lock` | `operator` |
| Stage 9 GO / NO-GO | `gate-outcome` | `plan-review-go` / `plan-review-no-go` | `operator` |
| Tier 1/2/3 escalation | `escalation` | `tier-1` / `tier-2` / `tier-3` | `hub` or `spoke:#N` |
| Empirical verification finding (R3) | `decision` | `empirical-verification-finding` | `hub` |
| Spoke-recommendation override (operator) | `decision` | `d-class` (subject = recommendation context) | `operator` |

**Codified obligation:** Hub MUST emit a `decision` event row when operator renders a decision through Decision Briefing, citing the originating sub-task comment URL in `payload`. This converts the existing-but-discretionary practice into a documented contract. No new event_type proposed — closed-enum schema preserved.

### 3.3 Surface C: Hub Session Boundaries (OPTIONAL lightweight log)

**Template (tracked):** [`release/releases/hub-state/sessions.md.template`](../../release/releases/hub-state/sessions.md.template)
**Runtime instance (operator-local):** `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/sessions.md` (created lazily on first session emit; OPTIONAL)

**Purpose:** Informational audit trail for cross-session lineage. NOT load-bearing for resume — release-scoped surfaces A + B are the load-bearing continuity mechanism. Surface C exists for operator-facing session-boundary inspection.

**Body (append-only):**

```markdown
## Hub Sessions

| session_id | started_at | ended_at | worktree | commit_sha_start | commit_sha_end | events_emitted |
|---|---|---|---|---|---|---|
| quirky-lederberg-11aafc__2026-05-23T14:22:01Z__abc1234 | 2026-05-23T14:22:01Z | 2026-05-23T17:45:33Z | quirky-lederberg-11aafc | abc1234 | def5678 | 7 |
```

`events_emitted` is best-effort hub-self-report (count of `pipeline-event-log` rows emitted during the session). Drift acceptable — Surface C is informational only.

### 3.4 The resume pointer and its write-ahead cadence

**What it is for.** A hub session can stop mid-turn — at an account's usage cap, for one — and be resumed by a fresh session, under the same account or another, that has no transcript of the first. Surfaces A, B and C let that session rebuild the record; they do not say what the stopped session was in the middle of. The resume pointer does. It is written ahead of each action the hub takes, so a resuming hub finds the stage and the gate, the next action, every spoke in flight with a test for whether it died, and everything the stopped session held that was bound to its account.

**Home and class.** Runtime instance (operator-local): `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/resume-pointer.md`, at the root of the run folder beside `pending-approvals.md` and `action-items.md` — never under `staging/`, which holds bodies awaiting posting and ends at the release's close (the hub-spoke bridge's Hub Staging Discipline). The pointer is a member of the placement standard's surface S-01, the release-hub run folders. Its class is **Working state**; its governed home is `/local-state/release-runs/` in the main checkout of the repository the run belongs to — an external target's run, that target's own home; and until that repository's cutover it resolves through `<OPERATOR_INSTANCE_HUB_STATE_PATH>` at the path above. It is one more file inside a run folder S-01 already registers, so it registers no new surface, path token, resolver or home subfolder. It has no tracked template: the hub writes it whole at every checkpoint, so the § 7.3 copy-then-append protocol does not apply to it. It is never committed or pushed; a resume reads it from the run folder, never from a branch.

**It is not a ledger row.** Its content changes at every checkpoint, and an action-item row may change only `status`, `resolved_at` and `resolution` once it is appended (`hub-action-tracking.md` § Action-Item Schema), so the pointer's content cannot live in the ledger. The ledger needs no row for it, because Resume Procedure Step 7 reads it at the fixed path above. A run that keeps one keeps at most one, appended once: category `reminder`, trigger_type `time`, trigger_detail `next session start`, target the pointer's path, carrying none of the pointer's content. That row is resolved at Procedure 7, before the action-item gate: `done`, with resolution `pointer retired at close`, once a resume has moved it to `in-flight`; otherwise `cancelled` at the operator's Procedure 7 review, with resolution `no resume read it`.

**Contents.** Frontmatter as the sibling surfaces carry it, plus one field, `checkpoint`:

```yaml
---
schema_version: "v1.0"
milestone: "<milestone-slug>"
created_at: "<ISO 8601 UTC of the run's first pointer write>"
last_updated: "<ISO 8601 UTC of this write>"
last_session_id: "<worktree>__<ISO-start>__<short-sha>"
checkpoint: "<before-launch | after-return | after-decision | before-stop | before-handle>: <the sub-task, decision or gate it concerns>"
---
```

Then four sections, in this order, each present on every write and reading `none` where empty:

| Section | Holds |
|---|---|
| `## Where the run stands` | The stage, and the gate it is at or heads to; what the run waits on — spokes, the operator at a named gate (with its pending-approval id where the gate is queued), or nothing; the release branch, its head commit at this write, and the release pull request where one exists; for each spoke that has returned and whose worktree is not yet removed, that worktree's path as its Agent result named it; and where the audit-output rows are: the run's `action-items.md`, the rows whose description begins `analysis output of spoke #` |
| `## Next action` | Exactly one action, in the imperative, naming the sub-task, decision or gate it serves |
| `## Spokes in flight` | One row per spoke launched and not yet returned: its sub-task, its stage, `launched_at`, its launch shape — background or foreground, and isolation (`worktree` or none), with the worktree path or agent ID once the launch returns it — the exact output heading literal that its sub-task body's Output line names, the action-item id of any audit-output row opened for it, and its died-test |
| `## Bound to the account` | One row per handle the run holds outside the record — a background spoke, a background shell task or monitor, a wakeup or session-only timer, each of which ends with the session that armed it, and a scheduled task or routine registered through the scheduler adapter, which outlives every session — giving the handle, its kind, that lifetime, when it was armed and when it is due, what it is for, and what a resume does with it (§ 4.2 step 4) |

A section the hub adds after these four is its own note; the Resume Procedure does not read it.

**The died-test.** Each in-flight row states the observable that tells a resuming hub whether the spoke returned. A spoke whose output is a sub-task comment has returned when its sub-task carries a comment from the trusted set, created after `launched_at` minus five minutes, that either opens with the heading literal its row records or carries the `Post-push mergeability:` line every spoke output is obliged to render. A spoke that commits has also done part of its work when the release branch carries commits after the head `## Where the run stands` records. A spoke with neither has died only when § 4.2's liveness read finds that nothing which launched or holds it is still alive. Absence of output is never a died verdict on its own: the stopped session may still be running in another app instance, capped and waiting for its reset, with its spokes and its transcript.

**Current state only.** Decisions, approvals, action items and history stay in the record, named by id where the pointer needs them and never copied: a copy is a second source that drifts. Paths are written in token-relative or repository-relative form. No account's name or address is ever recorded — the handle and its purpose are enough, and an account identifier would turn the run folder into leak-risk content under the placement standard.

**The write-ahead cadence.** The hub rewrites the pointer:

1. **before each spoke launch** — after the launch's pre-spawn guards and any action-item row the launch opens, immediately before the launch, with the spoke named in `## Spokes in flight`; a wave is written once, naming every spoke, before its first launch;
2. **after each spoke return** — once the return value and the output comment are read, before the return is evaluated or briefed;
3. **after each decision** — every operator-rendered decision and every hub-rendered determination, once its Decision Recorded comment and its event-log row are written and read back, before routing continues;
4. **before each stop gate** — every operator gate (the touchpoints the release-hub orchestration playbook's Hub Gate Register marks `STOP` or `STOP-IF`, or the bridge's Procedure 5 gates for a hub run by hand), before the gate is presented; where the gate is queued to Surface A (§ 7.2), the pending-approval row is appended first and the pointer names it.

It also rewrites the pointer **before it arms any handle bound to the account, or pauses the run on purpose**, so the handle or the pause is on record before it exists; and **once a launch or an arming returns its identifier** — an isolated spoke's worktree path or agent ID, a job ID — so the identifier is on record while the spoke or the handle lives. That write keeps the `checkpoint` of the launch or the arming it completes; for a foreground launch the after-return write already covers it. Two of these moments with no action between them are served by one write.

**Order within a checkpoint.** At each moment the record is written first — the comment, the event-log row, the ledger row, the pending-approval row — and the pointer last, so the pointer never names a record entry that does not exist. "Before" in moments 1 and 4 is relative to the launch and to the presentation, not to those record writes. A pointer that names a spoke before the spoke exists is safe: if the session ends between the write and the launch, no worktree and no output exist, the died-test reads died once the liveness read clears, and the spoke is launched again.

**How it is written.** Only the hub writes it; a spoke never does. Each write replaces the whole file in one write — never an append and never a partial edit. `last_updated`, and each `launched_at` the write records, are copied from `date -u +%Y-%m-%dT%H:%M:%SZ`, run in the same turn immediately before the write — never typed, rounded or prefixed with `~`. The write is read back: `last_updated` equals the value just written and lies within two minutes of the file's modification time, or the file is written again; and `## Spokes in flight` names exactly what the hub is about to launch or already holds in flight. No earlier copy is kept beside it; the record carries the history.

**The lease.** Each session keeps the `last_updated` value it last read or wrote. Before every pointer write it re-reads the pointer. If `last_updated` has moved and `last_session_id` names another session, this session has been superseded: it writes nothing more, routes nothing, and tells the operator. A resuming session takes the lease at its first write (§ 4.2 step 6). A stopped session that wakes — at its usage-cap reset, for one — meets the lease at its next checkpoint, which falls before any launch or gate.

**Honest scope — a discipline, not an interlock.** **Runner:** NONE — a registered named gap. Nothing observes whether a hub wrote at each moment: the pointer lands on a path no CI job reads, and a skipped write issues no tool call to observe. The gap is recorded in the gate-coverage register of `core/standards/gate-efficacy-standard.md`. The declared observable is the pointer itself at the next resume: a compliant hub leaves a pointer no older than every entry of the comparison set (§ 4.2 step 1), apart from the entries of the one checkpoint it was cut off in, and Resume Procedure Step 9 reports a pointer that is older than that, or absent, as drift (§ 4.1). A skipped write followed at once by a stop reads the same as a stop mid-checkpoint; the record wins in both, so that residual is safe. A run that is never resumed is never checked this way.

## 4. Resume Procedure

**Trigger:** Hub session start (operator paste of Hub Prompt, OR scheduled-task hub spawn, OR any new hub session reading from a worktree where a release is in flight).

**The case the resume pointer exists for** is a session that stopped mid-turn, resumed by a fresh session under the same account or another. A resuming session also takes on the write side: from its first routing decision it keeps the resume pointer current at the moments § 3.4 names.

**Read order (9 steps):**

| # | Read source | Purpose | Required? |
|---|---|---|---|
| 1 | `CLAUDE.md` + `.claude/rules/` (every file in the deployed rules set — the cardinality is owned by `core/deploy/deploy.sh` Check 9 `MIRROR_PAIRS`, not restated here) | Workspace governance baseline | YES |
| 2 | `projects/_config/SESSION_STATE.md` (Layer 2) | Workspace-level session handoff (cross-release context) | YES — if exists |
| 3 | `gh api repos/[OPERATOR_GITHUB]/pmo-platform/milestones?state=open --paginate` | Identify active milestone(s) | YES |
| 4 | `release/releases/plans/<slug>_RELEASE_PLAN.md` from release branch OR main | Stage 4 release plan (scope, sequence, D-Gate verdicts) | YES — if file exists; fallback: Stage 4 sub-task comment per [`hub-spoke-bridge.md` Procedure 0 § Canonical location](../../release/references/how-to/hub-spoke-bridge.md) |
| 5 | `gh issue list --milestone "<name>" --label sub-task --state all --limit 500 --json number,title,state,labels,projectItems` | Per-stage sub-task states + GitHub Projects field anchors | YES |
| 6 | `grep "\| v<X.Y> \|" <OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md` | Release-scoped decision history (D-class verdicts, scope-lock, gate outcomes, escalations) | YES |
| 7 | `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/resume-pointer.md` (§ 3.4), then `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/pending-approvals.md` | Where the previous session stopped and what it held in flight, read per § 4.2; then the queued approvals awaiting the current session | YES — each if it exists |
| 8 | `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/sessions.md` | Session lineage (informational) | OPTIONAL |
| 9 | Drift check: cross-reference event-log decisions vs. release plan deviation log vs. sub-task closure states | Surface inconsistencies before acting | YES |

**Step 6 grep semantics:** Pipe-delimited version match avoids false positives for substring versions (e.g., `v1.2` matching `v1.23`). The leading and trailing pipe characters bracket the `version` field per `pipeline-event-log.md` table schema.

**Output of resume procedure:** Hub posts a "Hub session start" Decision Briefing summarizing:

1. Active release + milestone state (open/closed counts, Stage anchors)
2. Pending approvals (count + brief; full enumeration if > 0)
3. Last operator decisions (most recent 5 event-log rows for this release)
4. Drift findings (if any)
5. Recommended next routing (per [`hub-spoke-bridge.md` Procedure 2](../../release/references/how-to/hub-spoke-bridge.md))
6. The resume read (§ 4.2): where the pointer says the run stopped; whether the liveness read found that the stopped session may still be running — and if so, that session and its live handles, with the ask to close that session or its app instance, or to tell this hub to stand down; each in-flight spoke's died-test verdict; each audit output still awaiting promotion; and each account-bound handle lost and whether it is re-armed — or that no pointer was found, and why

### 4.1 Drift Detection (Step 9)

| Drift class | Detection mechanism | Severity | Action |
|---|---|---|---|
| Event-log decision absent from release plan deviation log | Cross-reference D-class events vs. plan section | LOW | Surface to operator; recommend log entry |
| Sub-task closed without expected event-log emission (e.g., Stage 9 GO closed without `gate-outcome/plan-review-go`) | Per-stage cross-check | MEDIUM | Surface to operator; ask whether to backfill or accept |
| Pending-approval row marked `pending` but originating sub-task closed | Per-pending-approval cross-check | HIGH | Surface to operator immediately — possible orphaned approval |
| Release plan file out-of-sync with milestone scope (e.g., milestone added issue post-Stage-4) | Compare plan's issue list to current milestone enumeration | MEDIUM | Per A7 Bundle Mutability Protocol per [`release-process.md` Stage 3 A7](../../release/governance/release-process.md) — surface refresh-trigger to operator |
| Resume pointer older than the record — its `last_updated` precedes the newest entry of the comparison set (§ 4.2 step 1) | Compare `last_updated` with the newest such entry (§ 4.2 step 1) | MEDIUM; LOW, and read as cut off mid-checkpoint rather than as a missed write, when every newer entry concerns the checkpoint the pointer's `checkpoint` field names or the one immediately after it | The record wins: take the stage, the gate and the next action from the record, and report which write the pointer missed, or the checkpoint it was cut off in |
| Resume pointer names a spoke in flight whose output already exists | The row's died-test reads returned (§ 4.2 step 2) | LOW | The spoke returned after the last write: handle it per Procedure 4 |
| No readable resume pointer — none at the run root or a legacy place (§ 4.2), or one missing a § 3.4 section — while the release has routed past Stage 4 | Step 7 read | MEDIUM | Rebuild from the record, and report that the write-ahead cadence did not run |

Drift findings emit `decision/empirical-verification-finding` rows per the existing R3 discipline (per [`evidence-grounding-standard.md`](evidence-grounding-standard.md)); NOT a new subtype.

### 4.2 Resuming from the resume pointer (Step 7)

The resume pointer (§ 3.4) gives a resuming hub the stage and the gate the run is at (`## Where the run stands`), the next action, every spoke in flight with the test for whether it died, and the handles bound to the stopped session's account. Each is a lead, not a fact: the hub checks each field against the record before it acts on it.

**The liveness read comes first.** The session that stopped may not have ended: it can be capped and waiting in another app instance, with a wake timer of its own due at its reset. Before any died verdict, any re-arm and any routing, the hub reads the stopped session's live handles:

- for each isolated in-flight spoke, its worktree's lock in `git worktree list --porcelain` — found by the worktree path the row records, or by step 2's discovery step — and whether the process the lock names is alive;
- for each `## Bound to the account` row, whether its due time has passed.

If a lock's host process is alive, or a wake handle is still pending, the stopped session may be running. The resuming hub then does not relaunch, re-arm or route: briefing item 6 names the stopped session and those handles, and asks the operator to close that session or its app instance, or to tell this hub to stand down. A live lock host means the hub cannot conclude that the spoke died; it does not show that the spoke is alive.

After Step 7 reads the pointer and the liveness read has cleared, and before any routing:

1. **Freshness.** Compare `last_updated` with the newest entry of the comparison set: event-log rows whose `actor` is `hub` or `operator`, Decision Recorded comments, and action-item and pending-approval mutations. Rows whose actor is `spoke:#N` or `skill:NAME` are excluded, because they are expected while a spoke is in flight. A newer entry means a write was missed or cut off. When every newer entry concerns the checkpoint the pointer's `checkpoint` field names, or the one immediately after it, the stop came mid-checkpoint and no write was missed. Either way the record wins, and the stage, the gate and the next action are taken from the record (§ 4.1).
2. **Spokes in flight.** Open on the liveness read's result: a spoke whose host may still be running is not judged. Run each other row's died-test (§ 3.4).
   - **Returned** — handle the return per Procedure 4.
   - **Partly done** — a spoke that commits and pushed part of its work: launch it again on the release branch, where those commits are.
   - **Died** — launch it again, in a fresh run directory, when its stage is safe to re-run from the record: Stages 4, 5, 7 and 8, whose output is a sub-task comment, and Stage 6, which resumes from the pushed branch. A Stage 12 or Stage 13 spoke is never launched again blind: a merge, a version claim, a tag, a deploy and a close-out are not safe to repeat, so the hub first reads the release pull request's state, the version tag, the release-log row and the close-out pull request, and brings anything partial to the operator.
   - Before launching an isolated spoke again, the hub reads that spoke's worktree for uncommitted work or a staged analysis folder, and nothing removes the worktree first.
   - **Discovery, for a died isolated spoke with no recorded path.** List the `git worktree list --porcelain` entries under `.claude/worktrees/agent-*` whose directory was created at or after `launched_at`. For each candidate, read its lock, its `git status --porcelain` and its git-ignored files before any relaunch, and remove none before that read. When a wave leaves several candidates, surface the set to the operator.
3. **Audit output.** Read the action items in the run's `action-items.md` whose description begins `analysis output of spoke #` and whose `status` is `open` or `in-flight`. Each names a spoke — still in flight, or returned before the stop — whose dated analysis folder is not yet confirmed at the analysis home. Finish each through the promotion steps in the release-hub skill's spoke-launch reference, § Audit output, which owns those items. The pointer's in-flight rows name the same items by id, but the ledger is the source, because it also holds the spokes that returned before the stop. The worktree path of each spoke that returned, as `## Where the run stands` records it from the Agent result, is the tree those steps list; a spoke that died in flight is found by step 2's discovery step.
4. **Handles bound to the account.** Read each `## Bound to the account` row by its lifetime, never by session id alone. A session-scoped handle — a background spoke, a shell task, a monitor, an in-session wakeup or a session-only timer — ends when its host session ends: read that from the liveness read, never assume it. A routine registered through the scheduler adapter outlives every session. Its lifecycle belongs to that adapter (`scheduler-adapter-routine-firing.md` § `register(id)` / `deregister(id)`), so the resume reads its registration and never re-arms a duplicate. Re-arm each ended handle the run still needs, and record the rest retired.
5. **The next action.** Before taking it, read the record for evidence it was already taken — the comment posted, the row appended, the pull request merged, the spoke's output present. Take it only when that evidence is absent and the record agrees with it; otherwise route from the record (Procedure 2).
6. **The write side.** This session's first pointer write falls at the next moment § 3.4 names, taking the lease against the value read at Step 7.

**Where the pointer is found.** At the run root. A run folder with no `resume-pointer.md` there is read at the places hubs kept it before this section named its home — `staging/resume-pointer.md`, then `RESUME.md`, then `staging/RESUME.md` — read-only; the next write goes to the run root.

**Limit, stated.** The pointer is machine-local. A resume that runs on another machine — a cloud routine, for one — cannot read it, and rebuilds from the record alone.

## 5. Session-ID Tracking

**Format:** `<worktree-name>__<ISO-start-timestamp>__<short-sha-at-start>`

**Example:** `quirky-lederberg-11aafc__2026-05-23T14:22:01Z__abc1234`

**Components:**

| Component | Source | Uniqueness contribution |
|---|---|---|
| `worktree-name` | `basename "$(pwd)"` (per CLAUDE.md worktree convention) | High — harness assigns unique adjective-name-N triples per spawn |
| `ISO-start-timestamp` | `date -u +%Y-%m-%dT%H:%M:%SZ` at session-first-action | High — second-level resolution; collisions require sub-second simultaneity |
| `short-sha-at-start` | `git rev-parse --short HEAD` at session start | Medium — disambiguates same-worktree-second collisions |

**Why composite (vs. UUID):**

| Option | Pro | Con | Verdict |
|---|---|---|---|
| UUID (RFC 4122 v4) | Globally unique by construction | Opaque; no operator-readable context | Rejected — opacity loses operator-readable lineage value |
| ISO timestamp only | Operator-readable | Sub-second collision risk | Rejected — insufficient uniqueness |
| Worktree-name only | Operator-readable | Worktree reuse possible across long timespans | Rejected — insufficient temporal anchor |
| **Composite (worktree + timestamp + sha)** | Operator-readable + temporal + git-anchored | Longer (~60 chars) | **PREFERRED** |

**Persistence:** session_id emits as `payload` field in the FIRST `pipeline-event-log` row of the session (any event_type — typically the first `decision` or `gate-outcome` emission). Optionally logged to `sessions.md` (Surface C) for explicit session-boundary auditability.

**Cross-session usage:** session_id values are INFORMATIONAL — they identify which session emitted which event for audit lineage, but they are NOT load-bearing for resume. A NEW hub session does NOT need to find or replay a PRIOR session's state; it reads release-scoped state (Surfaces A + B + C above) directly. The "persist across re-entries" parent-issue requirement is satisfied by release-scoped state files, not by session-ID tracking.

## 6. Decision Log Mechanism

**Verdict:** CODIFY the existing dual-surface convention. No new dedicated decision-log file.

**Dual-surface convention:**

| Surface | Role | Required when | Reader convention |
|---|---|---|---|
| Sub-task comment | Human-readable Decision Briefing context (full options table, spoke recommendation, hub evaluation, rationale) | EVERY operator decision in a Decision Briefing | `gh issue view <N> --comments` |
| `pipeline-event-log.md` row | Structured, queryable, append-only audit row (compact payload + URL pointer to sub-task comment) | EVERY operator decision rendered in a Decision Briefing | `grep "\| v<X.Y> \|" pipeline-event-log.md` |

**Hub obligation (codified):**

After operator renders a decision in a Decision Briefing, the hub MUST:

1. Post a "Decision Recorded" comment on the relevant sub-task (typically the release planning sub-task for release-level decisions; the per-issue stage sub-task for per-issue decisions) containing the operator's verdict, options chosen, and any rationale the operator provided.
2. Invoke `append-pipeline-event.sh decision <subtype> ...` to emit the event-log row, with `payload` carrying the sub-task comment URL as the context pointer.
3. Update `pending-approvals.md` status column from `pending` to `resolved` (with `resolved_at` + `resolution`) if the decision was queued.

**Failure mode:** Hub posts comment WITHOUT emitting event-log row → decision is human-readable but not machine-queryable. Hub emits event-log row WITHOUT posting comment → decision is auditable but operator-context-lost. The standard's load-bearing test rejects either-or: BOTH surfaces required.

**Cross-reference to existing precedent:** The dual-surface convention already exists informally — `pipeline-event-log.md` Stage 13 audit-trail capture per [`release-process.md` Stage 13](../../release/governance/release-process.md) explicitly pairs `learnings-triple` event-log rows with the Stage 13 chore PR's `#### Release Learnings v<X.Y>` block. This standard generalizes the pattern across all hub decisions.

## 7. Durable-State Contract for the Queued-Approval Mechanism

**Substrate:** `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/pending-approvals.md` (Surface A per § 3.1 — operator-instance runtime instance, per [`public-repo-vs-operator-instance-taxonomy.md`](public-repo-vs-operator-instance-taxonomy.md) §4.3) is the persistence target for the queued-resumption mechanism.

### 7.1 Contract Elements

**1. Schema:** Per Surface A above (frontmatter + table with 13 fields).

**2. Queue ordering:** FIFO by `created_at`. Multiple pending rows at same `created_at` timestamp: tie-break by `id` ascending. NO priority field — single-operator PMO scale does not need pre-emption; if operator wants to resolve in non-FIFO order, they pick from the surfaced enumeration freely.

**3. Resumption procedure (consumed by the main-thread session-start flow):**

- On hub session start, hub executes Resume Procedure Step 7 (read `pending-approvals.md`).
- Hub surfaces all `status:pending` rows to operator BEFORE routing to new work — preserving the "engage with approvals on the main thread" operator framing per the queued-approval ACs.
- Operator renders verdict for each (or defers; deferred rows stay `pending`).
- For each resolved row, hub updates status + emits event-log decision row per Decision Log Mechanism (§ 6).
- **No-re-surface guard (resolved approvals are not re-queued).** Once a decision has been rendered to the operator and answered — i.e., its Surface A row is `status: resolved` (or `superseded` / `withdrawn`) — the hub MUST NOT re-enqueue or re-surface the **identical** decision in a later routing point or a later session. On Resume Procedure Step 7 the hub surfaces only `status: pending` rows; `resolved` rows are read for lineage but never re-presented. **Decision identity for this guard = the tuple `(decision_type, option_set_hash)` scoped to the release** — provenance-independent. `source_stage` and `source_sub_task` are retained as **non-identity audit fields** (where the decision was raised), NOT identity components: the same operator-facing decision raised from two different sub-tasks in one release is the **same ask** and must not surface twice. A genuinely new decision — a different option set, or the same touchpoint re-opened by an explicit scope change / `Adjust` at Collective Review — has a different `option_set_hash` and is a **new** `PA-NNN` row, not a re-surface. Re-presenting an already-resolved identical decision is the operator-facing symptom the unauthorized-gate metric ([`decision-discipline.md` § 6](../disciplines/decision-discipline.md), metric 5) counts. This refines the existing append-only `status` column (§ 3.1) — no schema change; it is the inverse of the § 4.1 Drift Detection stale-`pending` detector (a resolved row must not re-fire).

**4. Conflict resolution (multi-session edge case):** Single-operator PMO context — multi-session is not expected. If two hub sessions both consume the same `pending-approvals.md` (operator opens two Claude Code windows on same release), conflict semantics are last-write-wins on file commit, with the second session detecting drift via Resume Procedure Step 9 (event-log decision rows that reference rows the second session reads as still `pending`). Drift surfaces to operator as HIGH severity; operator reconciles. NO file-locking mechanism (would add ops complexity for an unlikely failure mode).

### 7.2 Enqueue Mechanism (consumed by the queued-approval mechanism)

When hub is running autonomously (e.g., scheduled trigger) and reaches an approval gate with NO active main-thread session, hub:

1. Computes the pending-approval row per Surface A schema.
2. Appends the row to `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/pending-approvals.md` (creating the per-release directory + the file from the tracked template at `release/releases/hub-state/pending-approvals.md.template` if first row, substituting milestone slug into frontmatter).
3. NO commit — the runtime instance is operator-instance per [`public-repo-vs-operator-instance-taxonomy.md`](public-repo-vs-operator-instance-taxonomy.md) §4.3 and lives outside the git-tracked surface. Persistence happens via the local file write; durability across hub sessions comes from the operator's machine-local state.
4. Suspends the work-item that generated the approval (per the mechanism's "queued resumption" semantics).
5. Next main-thread session start triggers Resume Procedure → operator sees queued approvals → renders verdict → hub resumes work-item.

**Cross-issue references in pending-approvals rows:** When a pending approval's context spans multiple sub-tasks (e.g., a Collective Review scope-lock covering 7 sub-tasks), `context_pointer` carries the release planning sub-task URL; `source_sub_task` carries the release planning sub-task number. Per-issue context is reachable from there.

### 7.3 Template-to-runtime copy mechanism (consumed by Step 2 of § 7.2)

When § 7.2 Step 2 reads *"creating the per-release directory + the file from the tracked template ... if first row"*, the canonical bash protocol is:

```bash
# Inputs:
#   MILESTONE   — the milestone/theme slug (slug-primary / pre-claim), e.g.,
#                 "release-identity-and-plan-naming". The runtime hub-state dir
#                 is created DURING the release (pre-claim) and is keyed on this
#                 slug, never on the version (which is not bound until the claim).
#   SURFACE     — "pending-approvals" | "action-items" | "sessions"
#   SOURCE_REPO — repo root (where release/releases/hub-state/*.template lives)

# Resolve <OPERATOR_INSTANCE_HUB_STATE_PATH> per
# core/standards/depersonalization-spec.md §4 — read operator.toml
# [paths].operator_instance_hub_state_path; empty → canonical default.
HUB_STATE_PATH="$(read_operator_toml_field paths.operator_instance_hub_state_path)"
[ -z "${HUB_STATE_PATH}" ] && HUB_STATE_PATH="${CLAUDE_WORKSPACE_ROOT}/pmo-instance/hub-state"

RUNTIME_DIR="${HUB_STATE_PATH}/${MILESTONE}"   # slug-keyed (pre-claim; the version is not bound yet)
RUNTIME_FILE="${RUNTIME_DIR}/${SURFACE}.md"
TEMPLATE_FILE="${SOURCE_REPO}/release/releases/hub-state/${SURFACE}.md.template"

if [ ! -f "${RUNTIME_FILE}" ]; then
  mkdir -p "${RUNTIME_DIR}"
  cp "${TEMPLATE_FILE}" "${RUNTIME_FILE}"
  # Substitute the milestone slug into the frontmatter + header + runtime-path
  # markers (created_at, last_updated set to current UTC). Pre-claim, the template
  # is keyed on the slug placeholder <milestone-slug> — there is no version to
  # substitute (it binds only at the Stage-12 claim; ADR-092).
  NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  sed -i.bak \
    -e "s|<milestone-slug>|${MILESTONE}|g" \
    -e "s|<ISO 8601 UTC of first row enqueue>|${NOW}|g" \
    -e "s|<ISO 8601 UTC of most recent row mutation>|${NOW}|g" \
    "${RUNTIME_FILE}"
  rm -f "${RUNTIME_FILE}.bak"
fi

# Append the first row to the runtime file (caller's responsibility).
```

**Why this is the canonical protocol and not skill-internal:** Documenting the protocol here means every consumer (the hub, hub-orchestration skill, scheduled triggers, future replacements) derives from the same source. Skill-internal implementations MAY wrap this in helpers (e.g., a `hub-state-init` skill helper) but the wrapper's contract MUST honor this protocol verbatim.

**Per-surface specialization:** Action-items and sessions surfaces follow the same protocol with their own schema templates — `release/releases/hub-state/action-items.md.template` per [`hub-action-tracking.md` § 2](hub-action-tracking.md) and `release/releases/hub-state/sessions.md.template` per § 3.3 above. Sessions are OPTIONAL — operators may skip the Surface C copy if they don't maintain it.

**Setup-workspace prerequisite:** `setup-workspace.sh` installs the templates at `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<basename>` (the hub-state tier in `core/deploy/composition-surface-manifest.sh`). The hub's first-emit copy uses the source repo's tracked template (not the installed copy at `<OPERATOR_INSTANCE_HUB_STATE_PATH>/`), so install-time copy is not a strict prerequisite for the protocol — but it provides a local reference copy operators can inspect without consulting the source repo.

## 8. Cutover

**Cutover discipline:** Applies to all releases going forward. The resume pointer and its cadence (§ 3.4) bind from the merge that ships them, because this standard loads from the repository tree rather than from a deployed copy; a run already in flight then is read where it kept its pointer (§ 4.2) until its next write.

## 9. Cross-References

| Reference | Relationship |
|---|---|
| Parent design discussion | Parent issue — establishes the gap and 5 ACs |
| Stage 5 Solutioning spec | D-2 verdict, schema design, R4 N-way convergence |
| Queued-approval mechanism | Substrate consumer — queued-approval mechanism rides on Surface A + Resume Procedure Step 7 + § 7 contract |
| Hub-action-tracking standard | Substrate consumer — action-item tracking rides on the file-based markdown convention under `releases/hub-state/`; action-item schema details owned by [`hub-action-tracking.md`](hub-action-tracking.md) |
| Agent-handoff framework | Framework composer — `agent-handoff-framework.md` disposition state machine T2 trigger composes with this standard's session-boundary semantics |
| [`agent-handoff-framework.md`](agent-handoff-framework.md) | Sibling K1 standard — cross-agent handoff contracts (this standard scopes cross-session continuity within a single hub role) |
| [`hub-action-tracking.md`](hub-action-tracking.md) | Sibling K1 standard — action-item schema rides on this standard's release-scoped substrate convention |
| [`pipeline-event-log-schema.md`](../../release/references/standards/pipeline-event-log-schema.md) | REUSED by Surface B without schema extension; closed-enum discipline preserved |
| [`evidence-grounding-standard.md`](evidence-grounding-standard.md) | Drift findings emit discipline (`decision/empirical-verification-finding`) |
| [`reversibility-protocol.md`](../specs/reversibility-protocol.md) | `reversibility` field enum source for Surface A schema |
| [`hub-spoke-bridge.md` § Procedure 0b](../../release/references/how-to/hub-spoke-bridge.md) | Thin procedural cross-reference pointing operators to this standard |
| [`hub-spoke-bridge.md` Procedure 0 § Canonical location](../../release/references/how-to/hub-spoke-bridge.md) | Release plan file location convention per D-C topology — anchors Resume Procedure Step 4 fallback |
| [`hub-spoke-bridge.md` Procedure 0a — Audit-Aware Orientation](../../release/references/how-to/hub-spoke-bridge.md) | Drift-detection precedent (audit-snapshot vs current state) — anchors Resume Procedure Step 9 |
| [`operations-bridge.md`](<OPERATOR_INSTANCE_CLAUDE_DIR>/rules/operations-bridge.md) | Layer 1 / Layer 2 partition rationale; SESSION_STATE.md Cowork-ownership boundary |
| [`instance-data-placement-standard.md`](instance-data-placement-standard.md) | The runtime instance's risk class (working state) and its governed home; § 2 *Placement class and target home* states the target wording, and § 3.4 names the resume pointer a member of its surface S-01 |
| [`release-process.md` Stage 3 A7](../../release/governance/release-process.md) | Bundle Mutability Protocol — anchor for Step 9 "Release plan file out-of-sync" drift class |
| [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) | K1 codified-knowledge convention placing standards in `core/standards/` |
| [`gate-efficacy-standard.md`](gate-efficacy-standard.md) § Gate-coverage register (seed) | Records the write-ahead cadence of § 3.4 as a named gap, with its declared observable and its population |
| [`spoke-launch.md`](../../release/skills/release-hub/references/spoke-launch.md) § Audit output | Owns the audit-output action items § 4.2 step 3 reads and the promotion steps a resuming hub runs; this standard restates neither |
| [`scheduler-adapter-routine-firing.md`](scheduler-adapter-routine-firing.md) § `register(id)` / `deregister(id)` | Owns a registered routine's lifecycle, which § 4.2 step 4 reads rather than re-arms |

## 10. Version History

| Version | Date | Author | Change |
|---|---|---|---|
| — | 2026-11-28 | Stage 6 Engineering (per release sub-task) | § 3.4 resume pointer and its write-ahead cadence — before each spoke launch, after each spoke return, after each decision, before each stop gate, before arming an account-bound handle, and once a launch returns its identifier; clock-sourced stamps, a file-time read-back and a one-comparison lease; a member of the placement standard's S-01, with no template and no ledger content. § 4 Step 7 reads it, § 4.1 gains three drift classes, § 4.2 resumes from it behind a liveness read, and the session-start briefing gains item 6. The surface count and the step count are unchanged |
| — | 2026-05-23 | Stage 6 Engineering (per parent release sub-task) | Initial authoring per Stage 5 spec; 3-surface state schema; 9-step Resume Procedure; composite session-ID format; dual-surface Decision Log Mechanism; durable-state contract for the queued-approval mechanism |
