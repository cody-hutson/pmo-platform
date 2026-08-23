---
title: Hub Session Continuity
purpose: K1 codified-knowledge standard defining how a new hub session reconstructs release-scoped state from durable artifacts — persistence format, 3-surface state schema, 9-step Resume Procedure, composite session-ID, dual-surface Decision Log Mechanism, and the durable-state contract that the queued-approval mechanism rides on
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

The parent issue framed the gap as "a new hub is a shift change with no shift notes." That framing overstates the missing infrastructure — three persistence surfaces already exist per [`hub-spoke-bridge.md` Framework Alignment row 20 (State Persistence)](../../release/references/how-to/hub-spoke-bridge.md): the release plan file at `release/releases/plans/<slug>_RELEASE_PLAN.md`, sub-task comments, and `projects/_config/SESSION_STATE.md`. The actual gap has three parts that this standard closes: (1) NO codified startup read-order knitting the existing surfaces into a coherent context-rebuild; (2) NO release-scoped durable substrate for the queued-approval mechanism; (3) NO explicit drift-detection between hub state and operator decisions across sessions.

**Scope.** Hub state persistence across SESSION boundaries within a single release. Cross-RELEASE state lives in workspace-level surfaces (`SESSION_STATE.md` for workspace handoff, `SWAP_HANDOFF.md` for cross-account handoff) and is out of scope here. Cross-AGENT handoffs (skill-to-skill, spoke-to-spoke, stage-to-stage) are owned by [`agent-handoff-framework.md`](agent-handoff-framework.md). Action-item schemas (deferred edits, follow-ups, reminders) are owned by [`hub-action-tracking.md`](hub-action-tracking.md) (sibling standard) and ride on the substrate convention this standard defines.

**Out of scope.** Skill-internal state. Operator-to-agent prompts. Workspace-level session handoff (Layer 2 — Cowork-owned per [`operations-bridge.md`](<OPERATOR_INSTANCE_CLAUDE_DIR>/rules/operations-bridge.md)). Action-item schema details (owned by `hub-action-tracking.md`). The Agent Handoff Framework's 9-field manifest, disposition state machine, and tier-cascade ordering (owned by `agent-handoff-framework.md`). Schema extensions to `pipeline-event-log.md` (no new event_type proposed; closed-enum discipline preserved).

## 1. D-2 Placement Verdict

Per Stage 5 D-2 verdict on the hub-session-continuity sub-task: the persistence schema + state contract + resume procedure are normative spec material — `core/standards/` is the canonical K1 home per [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md). The verdict IS this file's existence at this path. Sibling NEW standards files (`agent-handoff-framework.md` for the handoff framework, `hub-action-tracking.md` for action-item tracking) converge on the same placement, satisfying R4 N-way consistency at Collective Review. A thin Procedure 0b cross-reference in [`hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md) points operators to this standard for full schema + behavior; the bridge doc does NOT duplicate normative content.

## 2. Persistence Format

**Verdict:** File-based markdown — schema templates tracked at `release/releases/hub-state/*.template`; runtime instance written to the operator-instance path `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/`. The split-class treatment is governed by [`public-repo-vs-operator-instance-taxonomy.md`](public-repo-vs-operator-instance-taxonomy.md) §4.3 — templates ship as CUSTOMIZABLE-PUBLIC so operators have the schema to seed first emit; the runtime instance is OPERATOR-INSTANCE because hub-state mutates on every routing decision (10–50+ writes per release) and tracking the runtime would create release-branch noise with no cross-operator readership benefit.

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

**Layer classification:** **Templates** ship at Layer 1 (`release/releases/hub-state/*.template` — tracked under `pmo-platform/`). **Runtime instance** lives at Layer 2 (`<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/` — operator-local). The split avoids dozens of micro-commits per release for state with no cross-operator readership. Per [`operations-bridge.md`](<OPERATOR_INSTANCE_CLAUDE_DIR>/rules/operations-bridge.md), the existing Layer 2 `projects/_config/SESSION_STATE.md` is preserved for workspace-level handoff (cross-release, ephemeral, Cowork-owned). The three surfaces are complementary — hub-state runtime is release-scoped + operator-local + durable across hub sessions; SESSION_STATE is workspace-scoped + ephemeral.

**Directory creation discipline:** The template directory `release/releases/hub-state/` (with `*.template` files) is created at this standard's landing and lives in pmo-platform. Per-release runtime subdirectories at `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/` are created LAZILY by the hub on first surface emit (the hub copies the template, substitutes the milestone slug into the frontmatter, and appends the first row). Hubs do NOT pre-create empty per-release runtime directories.

## 3. State Schema

Hub state partitions across THREE surfaces by concern.

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

## 4. Resume Procedure

**Trigger:** Hub session start (operator paste of Hub Prompt, OR scheduled-task hub spawn, OR any new hub session reading from a worktree where a release is in flight).

**Read order (9 steps):**

| # | Read source | Purpose | Required? |
|---|---|---|---|
| 1 | `CLAUDE.md` + `.claude/rules/` (every file in the deployed rules set — the cardinality is owned by `core/deploy/deploy.sh` Check 9 `MIRROR_PAIRS`, not restated here) | Workspace governance baseline | YES |
| 2 | `projects/_config/SESSION_STATE.md` (Layer 2) | Workspace-level session handoff (cross-release context) | YES — if exists |
| 3 | `gh api repos/[OPERATOR_GITHUB]/pmo-platform/milestones?state=open --paginate` | Identify active milestone(s) | YES |
| 4 | `release/releases/plans/<slug>_RELEASE_PLAN.md` from release branch OR main | Stage 4 release plan (scope, sequence, D-Gate verdicts) | YES — if file exists; fallback: Stage 4 sub-task comment per [`hub-spoke-bridge.md` Procedure 0 § Canonical location](../../release/references/how-to/hub-spoke-bridge.md) |
| 5 | `gh issue list --milestone "<name>" --label sub-task --state all --limit 500 --json number,title,state,labels,projectItems` | Per-stage sub-task states + GitHub Projects field anchors | YES |
| 6 | `grep "\| v<X.Y> \|" <OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md` | Release-scoped decision history (D-class verdicts, scope-lock, gate outcomes, escalations) | YES |
| 7 | `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/pending-approvals.md` | Queued approvals awaiting current session | YES — if exists |
| 8 | `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/sessions.md` | Session lineage (informational) | OPTIONAL |
| 9 | Drift check: cross-reference event-log decisions vs. release plan deviation log vs. sub-task closure states | Surface inconsistencies before acting | YES |

**Step 6 grep semantics:** Pipe-delimited version match avoids false positives for substring versions (e.g., `v1.2` matching `v1.23`). The leading and trailing pipe characters bracket the `version` field per `pipeline-event-log.md` table schema.

**Output of resume procedure:** Hub posts a "Hub session start" Decision Briefing summarizing:

1. Active release + milestone state (open/closed counts, Stage anchors)
2. Pending approvals (count + brief; full enumeration if > 0)
3. Last operator decisions (most recent 5 event-log rows for this release)
4. Drift findings (if any)
5. Recommended next routing (per [`hub-spoke-bridge.md` Procedure 2](../../release/references/how-to/hub-spoke-bridge.md))

### 4.1 Drift Detection (Step 9)

| Drift class | Detection mechanism | Severity | Action |
|---|---|---|---|
| Event-log decision absent from release plan deviation log | Cross-reference D-class events vs. plan section | LOW | Surface to operator; recommend log entry |
| Sub-task closed without expected event-log emission (e.g., Stage 9 GO closed without `gate-outcome/plan-review-go`) | Per-stage cross-check | MEDIUM | Surface to operator; ask whether to backfill or accept |
| Pending-approval row marked `pending` but originating sub-task closed | Per-pending-approval cross-check | HIGH | Surface to operator immediately — possible orphaned approval |
| Release plan file out-of-sync with milestone scope (e.g., milestone added issue post-Stage-4) | Compare plan's issue list to current milestone enumeration | MEDIUM | Per A7 Bundle Mutability Protocol per [`release-process.md` Stage 3 A7](../../release/governance/release-process.md) — surface refresh-trigger to operator |

Drift findings emit `decision/empirical-verification-finding` rows per the existing R3 discipline (per [`evidence-grounding-standard.md`](evidence-grounding-standard.md)); NOT a new subtype.

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

**Cutover discipline:** Applies to all releases going forward.

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
| [`release-process.md` Stage 3 A7](../../release/governance/release-process.md) | Bundle Mutability Protocol — anchor for Step 9 "Release plan file out-of-sync" drift class |
| [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) | K1 codified-knowledge convention placing standards in `core/standards/` |

## 10. Version History

| Version | Date | Author | Change |
|---|---|---|---|
| — | 2026-05-23 | Stage 6 Engineering (per parent release sub-task) | Initial authoring per Stage 5 spec; 3-surface state schema; 9-step Resume Procedure; composite session-ID format; dual-surface Decision Log Mechanism; durable-state contract for the queued-approval mechanism |
