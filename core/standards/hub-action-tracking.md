---
title: Hub Action Tracking
purpose: K1 codified-knowledge standard defining the schema, persistence mechanism, and review cadence for hub-tracked action items (AI-NNN) — durable commitments the hub or operator must execute at a future routing point. Rides on the hub-session-continuity substrate (file-based markdown — template at release/releases/hub-state/action-items.md.template; runtime instance at <OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/action-items.md); composes with the agent-handoff framework when action items are handed off to spoke owners; surfaces via the main-thread Decision Briefing mechanism governed by the hub-orchestration layer.
type: standard
status: ACTIVE
source: ""
parallel_to: "hub-session-continuity.md (sibling K1 standard defining the durable substrate this standard rides on; PA-NNN/AI-NNN namespaces partitioned by record-type), agent-handoff-framework.md (sibling K1 standard defining cross-agent handoff manifests; composes with action items handed off to spoke owners), pipeline-event-log-schema.md (REUSED — 5 new action-item-* subtypes additive on existing decision event_type, closed-enum discipline preserved), hub-spoke-bridge.md § Procedure 4a + § Procedure 7a (thin procedural cross-references pointing to this standard for full schema + behavior)"
reversibility: MODERATE / HIGH confidence (file creation + cross-reference removal + event-subtype revert reversible via git revert until downstream consumers — Stage 13 automated-closeout, future hub-replacement skills — build against the schema + hard gate)
consumers: "hub-spoke-bridge.md Procedure 0b/2/4a/5/7a (5-routing-point review-cadence binding); Stage 13 automated-closeout (MAY add action-item-resolution gate when consumer-side adoption is timely; ACCEPT-AS-RESIDUAL for this release); release-synthesizer (composes with action-item carry-forward signal when cross-release pattern detection enables first-class AI-NNN queryability)"
version: ""
---
<!-- reference-durability: allow-link -->

# Hub Action Tracking

## Purpose + Scope

This standard defines how the hub tracks **action items** — durable commitments to execute work at a future routing point (deferred edits, reminders, cleanups, decisions deferred for posting, cross-issue merge waits, post-action verifications, decisions deferred for briefing). It complements the hub-session-continuity substrate (which governs hub state across session boundaries) and the agent-handoff framework (which governs cross-agent handoff manifests) by adding the third surface: **what the hub OWES** between now and release close.

The parent design discussion framed the gap as the absence of a tracking mechanism for the obligations that operators and hub repeatedly emit during a release ("dedup that guide after the PR merges," "add a web UI config reminder for Stage 10," "close issue A after issue B merges"). These commitments currently live in sub-task comments, Decision Briefing prose, and operator memory — easy to drop, easy to drift, easy to leak past release close. This standard codifies the surface so commitments are explicit, schema-validated, surfaced at 5 routing points, and **gated at Stage 13 Close** so no `status:open` row leaks across release boundaries.

**Scope.** Action items emitted by the hub OR by spokes during release execution; persisted within a single release lifecycle. Cross-release carry-forward uses an explicit `superseded` transition with a successor AI-NNN in the next release's `action-items.md` — implicit carry-forward is prohibited.

**Out of scope.** Pending-approval queue mechanics (owned by [`hub-session-continuity.md` § 3.1](hub-session-continuity.md) — PA-NNN rows in `pending-approvals.md`). Session-boundary state schema (owned by `hub-session-continuity.md` §§ 3, 5). Agent handoff manifests (owned by [`agent-handoff-framework.md`](agent-handoff-framework.md)). Main-thread surfacing semantics (owned by the hub-orchestration layer — this standard extends that surface to AI-NNN rows but does NOT govern the surfacing mechanism). Skill-internal action queues (out of scope by Layer-1 / Layer-2 boundary per [`operations-bridge.md`](<OPERATOR_INSTANCE_CLAUDE_DIR>/rules/operations-bridge.md)).

## 1. D-2 Placement Verdict

Per Stage 5 D-2 verdict on : the action-item schema + persistence-substrate-binding + review-cadence rule + Procedure 7 hard gate are normative spec material — `core/standards/` is the canonical K1 home per [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) (Q1 universality classifier: TRUE for any PMO-platform deployment; K1 codified-knowledge tier). The verdict IS this file's existence at this path. Sibling NEW standards files converge on the same placement, satisfying R4 N-way consistency at Collective Review: `hub-session-continuity.md` , `agent-handoff-framework.md` , and this file. Thin Procedure 4a + 7a cross-references in [`hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md) plus subsection additions to the Operating Principle Decision Briefing template + Procedures 2 / 5 point operators to this standard for full schema + behavior; the bridge doc does NOT duplicate normative content.

## 2. Action-Item Schema

**Template (tracked):** [`release/releases/hub-state/action-items.md.template`](../../release/releases/hub-state/action-items.md.template)
**Runtime instance (operator-local):** `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/action-items.md` — sibling to [the hub-session-continuity `pending-approvals.md` runtime instance](hub-session-continuity.md). Created LAZILY on first action-item emit per the directory-creation discipline in [`hub-session-continuity.md` § 2](hub-session-continuity.md). The run key is the milestone slug. A small number of directories predate that convention and are keyed on a version; the resolver reads the slug form first and falls back to the version form, which it treats as read-only. The resolver contract is specified in the release-hub orchestration playbook § 4a.3 and the hub-session-continuity standard § 7.3.

**Frontmatter (YAML — parallel to the hub-session-continuity Surface A; session-ID format inherited verbatim per [`hub-session-continuity.md` § 5](hub-session-continuity.md)):**

```yaml
---
schema_version: "v1.0"
milestone: "<milestone-slug>"
created_at: "<ISO 8601 UTC of first row enqueue>"
last_updated: "<ISO 8601 UTC of most recent row mutation>"
last_session_id: "<worktree>__<ISO-start>__<short-sha>"
---
```

**Body (markdown table — append-only with in-place status mutation):**

```markdown
## Action Items

| id | created_at | source_stage | source_sub_task | category | owner | description | trigger_type | trigger_detail | target | status | resolved_at | resolution |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AI-001 | 2026-05-23T14:22:01Z | 5 | #NNNN | deferred-edit | hub | dedup github-projects-guide.md after PR #NNNN merges | event | after merge of PR #NNNN | file:core/disciplines/github-projects-guide.md | open | — | — |
```

**Field semantics (13 fields):**

| Field | Type | Required | Purpose |
|---|---|---|---|
| `id` | string `AI-NNN` | YES | Stable identifier within release; zero-padded; not reused; `AI-` namespace disjoint from the hub-session-continuity `PA-` namespace to prevent cross-record confusion |
| `created_at` | ISO 8601 UTC | YES | Original enqueue time |
| `source_stage` | int 1..13 | YES | Pipeline stage that generated the action item |
| `source_sub_task` | string `#NNNN` | YES | GitHub Issue (sub-task) carrying the originating context |
| `category` | enum (7 values; see § 2.1) | YES | Action-specific classification (drives owner/surface defaults) |
| `owner` | enum: `hub` / `operator` / `spoke:#N` / `external` | YES | Who is responsible to execute the action |
| `description` | string | YES | Imperative one-liner — what specifically to do |
| `trigger_type` | enum (4 values; see § 2.2) | YES | When the action fires |
| `trigger_detail` | string | YES | Specific trigger predicate (e.g., "after PR #NNNN merges to main"; "at Stage 12 entry"; "next session start") |
| `target` | URL or `file:section` or `issue:#N` or `release-plan:section` | YES | Where the action lands |
| `status` | enum (5 values; see § 2.3) | YES | Lifecycle state; rows mutate in-place ONLY for `status` + `resolved_at` + `resolution` columns |
| `resolved_at` | ISO 8601 UTC or `—` | YES | Transition time to `done`/`cancelled`/`superseded`; `—` when `status ∈ {open, in-flight}` |
| `resolution` | string or `—` | YES | One-liner outcome (e.g., "merged to main at 0a11f2d"; "cancelled — superseded by AI-007"); `—` when `status ∈ {open, in-flight}` |

**Schema overlap with the hub-session-continuity PA-NNN namespace:** Four field names (`id`, `created_at`, `source_stage`, `source_sub_task`) share names AND semantics with PA-NNN — intentional overlap aids cross-record reader pattern recognition. Divergence on `category`/`owner`/`trigger_type`/`trigger_detail` (action-specific surfaces absent in approvals) and `status` enum vocabulary (commitment lifecycle vs. approval lifecycle).

**Schema enforcement:** Hub validates the table at read-time (every routing-point scan per § 4). Malformed rows surface as drift to operator per [`hub-session-continuity.md` § 4.1 Drift Detection](hub-session-continuity.md); hub does NOT auto-repair (operator-write only when modifying rows).

### 2.1 Category enum (7 values)

| Category | Definition | Example (from parent design discussion Evidence) |
|---|---|---|
| `deferred-edit` | A file edit deferred to a later trigger point | "github-projects-guide.md dedup after PR merge" |
| `reminder` | A note-to-self the hub must surface at a future routing point | "web UI config reminder for Stage 10" |
| `cleanup` | A removal or tidy-up obligation at a future point | "test project cleanup at Stage 12" |
| `decision-to-post` | A decision rendered now whose announcement is deferred (e.g., comment to post after a sibling issue closes) | "D5 sub-issue initialization decision to post on parent issue" |
| `cross-issue-merge` | An action gated on another issue's resolution (e.g., close issue A after issue B merges) | "issue #NNNN close after sibling #NNNN merge" |
| `verification` | A post-action check to confirm an executed action produced the expected state | "verify deploy.sh --check passes after skill X deploys" |
| `decision-deferred` | A decision **surfaced but not yet rendered** to the operator, carried forward to a later consolidated briefing per [`decision-briefing.md` § The 5 information-sufficiency gates](../../release/skills/release-hub/references/decision-briefing.md), declared-deferral form. `trigger_detail` MUST name the operator-facing consolidation touchpoint. Discharges when that touchpoint carries the briefing. Distinct from `decision-to-post`, where the decision **is** rendered and only its announcement is deferred | "D-4 scope-lock alternative carried to the Collective Review briefing" |

Categories cover all 5 evidence cases enumerated in the parent design discussion verbatim — each evidence case maps to exactly one category. `verification` adds a post-execution-confirmation surface (parent evidence does not enumerate a case, but hub frequently emits verification action items in practice). `decision-deferred` adds the declared-deferral surface: a well-formed declared deferral is a durable commitment that otherwise conforms at surface time and can then silently never discharge, because nothing carries it to the named touchpoint and § 4 routing point 5 never sees it. Enum expansion is governed via this standard's revision per [`pipeline-event-log-schema.md § 3`](../../release/references/standards/pipeline-event-log-schema.md) closed-enum discipline.

**Why a 7th value rather than a widened `decision-to-post`.** The two discharge differently: `decision-to-post` discharges by *posting* a decision that is already rendered; a declared deferral discharges by *rendering* an unrendered decision to the operator. They carry different trigger shapes, different discharge evidence, and different stakes. Collapsing them into one value would also defeat `category`'s stated purpose in § 2 (it drives owner/surface defaults) — one category with two default surfaces has no defaults.

### 2.1a Historical value aliases

Runtime ledgers seeded before this revision carry values this enum does not admit, because the template that seeds them restated all three enums (§ 2.1 `category`, § 2.2 `trigger_type`, § 2.3 `status`) and diverged from every one. Those ledgers are operator-instance files the platform does not rewrite — most are closed-release audit records, and rewriting a closed release's ledger to a later vocabulary would falsify the record the Stage-13 gate verdict was rendered against. They are made READABLE against this enum instead, by the alias table below. No ledger is migrated; no alias changes any § 4 routing-point-5 gate verdict, because the gate keys on `status ∈ {open, in-flight}` and every alias below is terminal-to-terminal or non-status.

**Why the standard's value set won, and not the template's.** The two sides were never symmetric in blast radius, and that asymmetry is the ground for the verdict. § 2.1's values are **load-bearing**: the § 2 field-semantics row names that section as the enum's home (`enum (7 values; see § 2.1)`), the § 2.1 definitions table is what `category`'s stated purpose in § 2 — driving owner/surface defaults — resolves against, and the § 4 routing-point bindings and their Decision Briefing subsection format are written in that vocabulary. The template's divergent values are cited nowhere: `merge-wait` and `post-action-verification` each occur exactly once in the corpus — in the alias table below — and occur there as values being *read*, never as values any surface *invokes*. Reconciling toward the standard therefore rewrote one file; reconciling toward the template would have rewritten every surface that cites § 2.1, in order to adopt a vocabulary no surface had ever cited.

| Field | Pre-revision value | Reads as |
|---|---|---|
| `category` | `merge-wait` | `cross-issue-merge` |
| `category` | `post-action-verification` | `verification` |
| `category` | `decision-deferred` | `decision-to-post` — **time-scoped; see the rider below** |
| `status` | `resolved` | `done` |
| `status` | `withdrawn` | `cancelled` |
| `trigger_type` | `manual` | `stage-boundary` or `event`, per the row's `trigger_detail` — **not mechanically decidable; read the trigger predicate** |

**Time-scope rider — `decision-deferred` is the one ambiguous alias, and the ambiguity is bounded.** This revision gives `decision-deferred` a new and different meaning, so the value means one thing before the revision and another after it. A row whose `created_at` precedes this revision reads as `decision-to-post` (the pre-revision template used the word as a synonym for it); a row created after reads as the declared deferral defined in § 2.1. This is mechanically decidable because every row already carries `created_at` — the schema holds the discriminator the ambiguity needs, which is why the ambiguity is tolerable rather than disqualifying. The alternative — coining a fresh name — avoids the rider only by deleting a value that live ledgers already carry and orphaning those rows.

**What this section is NOT.** It is a read rule, not a conformance claim. Ledger rows carrying values in **neither** vocabulary — free-text `category` values drawn from a finding-register vocabulary rather than a commitment one — are not aliased here and are not made conformant by this revision. That is a substrate-repurposing defect, categorically distinct from the vocabulary-parity defect this section closes, and it is tracked separately.

**Cutover.** Applies to all releases entering Stage 5 going forward; pre-existing in-flight releases are grandfathered (§ 6 umbrella shape).

### 2.2 Trigger-type enum (4 values)

| Trigger type | Definition | Detection mechanism |
|---|---|---|
| `stage-boundary` | Fires at a specific pipeline stage entry | Hub matches `trigger_detail = "Stage N"` against current stage anchor at Procedure 5 (Gate Handling) |
| `event` | Fires on a specific platform event (PR merge, issue close, sub-task close, spoke completion) | Hub matches `trigger_detail` against recent events at Procedure 4 (Spoke Completion) + Procedure 2 (Routing) |
| `time` | Fires at a wall-clock time (next session start, after 24h, by specific date) | Hub matches `trigger_detail` against current time at Procedure 0b (Resume Procedure) |
| `cross-issue-merge` | Fires when a specific blocking issue's PR merges to main | Hub matches `trigger_detail = "after #N merges to main"` against `gh pr list --state merged --search "<branch-or-issue>"` at Procedure 2 (Routing) |

The 4-value taxonomy covers all observable trigger surfaces hub has detection access to (pipeline stage anchors, GitHub events via `gh`, wall-clock time, git ref state). Future trigger types are additive (e.g., `external-callback` when L3 connectors per the agent-handoff framework Dimension 4 land); enum expansion is governed via this standard's revision.

### 2.3 Status enum + lifecycle

5 states; 7 named transitions. Parallel to the hub-session-continuity PA-NNN lifecycle (4 states) — distinct vocabulary because **actions are commitments** (open → in-flight → done) while **approvals are decisions** (pending → resolved).

| # | State | Definition |
|---|---|---|
| 1 | `open` | Created; trigger has not yet fired |
| 2 | `in-flight` | Trigger has fired AND owner has begun execution but action is not yet complete |
| 3 | `done` | Owner executed the action successfully; outcome recorded in `resolution` |
| 4 | `cancelled` | Action is no longer needed (e.g., the deferred edit was made directly during another change; the reminder is no longer relevant); `resolution` records the rationale |
| 5 | `superseded` | A later AI-NNN supersedes this one (e.g., scope changed); `resolution` carries the superseding ID |

**Transitions (7 named):**

| # | From → To | Trigger | Authority |
|---|---|---|---|
| T1 | (none) → `open` | Action item created by hub/spoke during execution | Skill/hub-internal |
| T2 | `open` → `in-flight` | Trigger fires AND owner begins execution | Hub (autonomous, on trigger match) or operator (manual claim) |
| T3 | `in-flight` → `done` | Owner reports completion + evidence | Hub (on confirmation read) or operator (manual mark) |
| T4 | `open` → `cancelled` | Action no longer needed (no trigger fire, or trigger fired but no longer applicable) | Operator (review at Procedure 7 Close) |
| T5 | `in-flight` → `cancelled` | Action started but discovered to be unnecessary | Operator (escalation from owner) |
| T6 | `open` → `superseded` | A later action item replaces this one | Hub (on emit of replacement AI-N+M) |
| T7 | `in-flight` → `superseded` | A later action item replaces a partially-executed one | Operator (rare; documented in `resolution`) |

**State-machine composition with the agent-handoff disposition state machine:** The agent-handoff disposition states (`staged` / `promoted` / `confirmed-sent` / `stale` / `archived`) govern **ARTIFACT** lifecycle (file outputs from skills). This standard's `status` states govern **OBLIGATION** lifecycle (hub-tracked work commitments). The two state machines operate on disjoint surfaces — no overlap, no field-name collision (the handoff framework uses `disposition_state`; this standard uses `status`). Composition surface: an action item's `target` MAY be an artifact whose disposition is tracked by the handoff framework (e.g., AI-005 description: "promote 08-Generated/draft.md to canonical path after Stage 9 GO"; target: artifact whose handoff-framework disposition is `staged`).

## 3. Persistence Mechanism — Substrate Alignment with

This standard rides the hub-session-continuity substrate verbatim. No parallel persistence directory, no parallel ID namespace, no parallel decision log, no parallel session-ID format.

**Substrate (cited from [`hub-session-continuity.md` § 2](hub-session-continuity.md)):** schema templates tracked at `release/releases/hub-state/*.template`; runtime instance written to the operator-instance path `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/` per [`public-repo-vs-operator-instance-taxonomy.md`](public-repo-vs-operator-instance-taxonomy.md) §4.3; file-based markdown; frontmatter + table format; append-only-with-status-mutation discipline.

**Resulting runtime directory contents per release (at the operator-instance path):**

```
<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/
├── pending-approvals.md     (per hub-session-continuity Surface A — PA-NNN approval queue)
├── action-items.md          (per this standard — AI-NNN action-item ledger)
└── sessions.md              (per hub-session-continuity Surface C — lazy, informational; optional)
```

**Substrate-integration contract (4 elements):**

1. **Schema parallelism.** `action-items.md` frontmatter format matches `pending-approvals.md` verbatim (`schema_version`, `milestone`, `created_at`, `last_updated`, `last_session_id`). Body table format matches the append-only-with-status-mutation pattern. NO new file-write convention; NO new format primitive.

2. **Lifecycle parallelism.** Status enum vocabulary differs (commitment lifecycle vs. approval lifecycle), but the in-place row-mutation discipline is identical — rows append on create, mutate only `status` + `resolved_at` + `resolution` columns on transition. Operator-write only; hub does NOT auto-repair malformed rows.

3. **Decision-log integration (Surface B REUSE per [`hub-session-continuity.md` § 3.2](hub-session-continuity.md)).** Status transitions on AI-NNN rows emit existing `pipeline-event-log.md` `decision` event rows per 's dual-surface contract. Event_type/subtype mapping:

   | AI-NNN transition | `pipeline-event-log` event_type | event_subtype | actor |
   |---|---|---|---|
   | T1 — (none) → `open` | `decision` | `action-item-opened` | `hub` or `spoke:#N` (per source) |
   | T2 — `open` → `in-flight` | `decision` | `action-item-started` | `hub` or `operator` |
   | T3 — `in-flight` → `done` | `decision` | `action-item-resolved` | `hub` or `operator` |
   | T4/T5 — `*` → `cancelled` | `decision` | `action-item-cancelled` | `operator` |
   | T6/T7 — `*` → `superseded` | `decision` | `action-item-superseded` | `hub` or `operator` |

   These are NEW SUBTYPES on the existing `decision` event_type — preserves closed-enum schema-stability discipline per [`pipeline-event-log-schema.md § 3`](../../release/references/standards/pipeline-event-log-schema.md) (subtypes are additive within an event_type; no new event_type introduced). The 5 subtypes land in `pipeline-event-log-schema.md § 3` `decision` row as part of this standard's Stage 6 commit.

4. **No competing substrate.** This standard explicitly does NOT introduce a parallel persistence directory, parallel ID namespace, parallel decision log, or parallel session-ID format. All four mechanisms reuse.

**Why ride the hub-session-continuity substrate rather than separate (rationale archive):** One persistence pattern for operator to learn; Resume Procedure reads both files at hub-session-continuity Step 7 (generalized from `pending-approvals.md` to all `*-state.md` files in `hub-state/<milestone-slug>/`); single-directory edit reduces commit overhead; future skill replacement consumes the standard substrate uniformly; citation-graph clarity (this standard cites hub-session-continuity for substrate without re-canonicalizing).

## 4. Review Cadence — 5-Routing-Point Binding

Hub reads `action-items.md` and scans for triggered rows at FIVE routing points. At each, surfaced action items appear in the Decision Briefing alongside the standard procedure output.

| # | Routing point | When | What hub scans for | Action |
|---|---|---|---|---|
| 1 | **Procedure 0b — Resume Procedure** (per [`hub-session-continuity.md` § 4](hub-session-continuity.md) Operating Principle template item 4 forcing-function) | Hub session start | `status:open` rows with `trigger_type:time` whose deadline has passed | Surface in "Hub session start" Decision Briefing as `in-flight` candidates |
| 2 | **Procedure 2 — Routing (What's Next)** | Operator asks "what's next?" OR spoke completes | `status:open` rows with `trigger_type:event` or `trigger_type:cross-issue-merge` whose predicate matches current GitHub state | Surface alongside next-actionable sub-tasks; operator MAY elect to route action item ahead of pipeline work |
| 3 | **Procedure 4 — Spoke Completion** (via thin Procedure 4a binding) | Spoke posts and closes its sub-task | `status:open` rows with `trigger_type:event` whose `trigger_detail` references this spoke's completion (e.g., "after Stage 5 sub-task #NNNN closes, post substrate-alignment note on sibling issue") | Auto-transition T2 (`open → in-flight`); hub or operator executes |
| 4 | **Procedure 5 — Gate Handling** | Release reaches a gate (Stage 9, Stage 12) | `status:open` rows with `trigger_type:stage-boundary` whose `trigger_detail` matches the gate's stage | Surface in gate-decision briefing; operator MAY resolve action item as part of gate decision |
| 5 | **Procedure 7 — Close** (via thin Procedure 7a binding — HARD GATE) | Stage 13 Milestone close | TWO counts over the whole AI-row population: the row total, and the `status:open` + `status:in-flight` subset | **HARD GATE, 3-valued.** `UNRESOLVED` (≥1 open/in-flight) **BLOCKS** — operator MUST resolve each remaining row (transition to `done`, `cancelled`, or `superseded`) before Milestone close. `RESOLVED` (≥1 row, none unresolved) is the only silent pass. `NOT-RECORDED` (no ledger file) and `EMPTY-LEDGER` (ledger present, zero rows) **SURFACE for operator attestation** — a release may legitimately record no commitments, but so does a release whose emit step was skipped, and the gate must not conflate them. Carry-forward to next release is via `superseded` with explicit successor AI-NNN in the next release's `action-items.md`. Predicate + decision table: [`hub-spoke-bridge.md` § Procedure 7a](../../release/references/how-to/hub-spoke-bridge.md). |

**Cadence-binding rule (canonical):** Hub MUST scan `action-items.md` at all 5 routing points. Skipping the scan is a structural defect surfaced by Stage 8 QA + Stage 13 Procedure 7a HARD GATE (§ 4 row 5). Stage 13 automated-closeout per the release-process protocol MAY add a programmatic open-row check before Phase 5 RELEASE_LOG transition when consumer-side adoption is timely (ACCEPT-AS-RESIDUAL).

**Composition with existing Decision Briefing template:** The Decision Briefing template at [`hub-spoke-bridge.md` Operating Principle](../../release/references/how-to/hub-spoke-bridge.md) gains an "Action items surfaced this routing point" subsection at each routing point. Subsection format:

```markdown
**Action items surfaced this routing point:**

| AI-NNN | Category | Description | Trigger fired | Recommended disposition |
|---|---|---|---|---|
| AI-003 | reminder | web UI config reminder for Stage 10 | stage-boundary: Stage 10 reached | execute now |
```

When zero rows trigger, the subsection reads "No action items triggered at this routing point" — omission is a structural defect (forcing-function makes the scan observable).

**The symmetric second half — the commitment sweep.** The subsection above renders a **read**: action items whose trigger already fired. It has no counterpart for the **write**, and that asymmetry is the defect this subsection closes. Procedure 4a step 5 obliges an `AI-NNN` row *"when the hub or a spoke makes a durable commitment"* — a state the agent must recognise **in itself**, where every other step of that procedure fires at an observable routing point. Nothing ever asks the question, so the answer is frequently never given: measured across the hub-state population, ledgers are absent on releases that emitted decision-class events throughout. Sharpening the words fixes nothing, and adding a second instruction fixes nothing. **The repair relocates the test from the commitment moment to a routing point that already happens**, and makes its result a rendering whose omission a reader sees. The Decision Briefing template therefore gains a second subsection beside the first:

```markdown
**Commitments opened this routing point:**

| AI-NNN | Category | Description | Which limb of the test it satisfies |
|---|---|---|---|
| AI-004 | verification | re-run `deploy.sh --check` after the skill deploys | L1 deferral · L2 owed in-release, carried by no other durable record |
```

**Exactly three renderings are admissible, and omission of all three is a structural defect** — the same clause the sibling subsection above already carries, for the same reason:

1. **The table**, when ≥ 1 commitment was opened.
2. `"Commitment sweep run — no durable commitment made in this window."`
3. `"Commitment sweep run — N UNDECIDED candidate(s), surfaced for operator disposition: <candidate>."`

**Where the sweep fires — four routing points, and the distinction from the scan cadence is load-bearing.** The sweep fires at the four routing points at which a commitment can be **created**: **Procedure 2** (Routing), **Procedure 4** (Spoke completion), **Procedure 5** (Gate handling), and **Procedure 7** (Close). It does **not** fire at **Procedure 0b** (Resume), which reads and creates nothing. This is a strict subset of the five *scan* points enumerated in the table above, and the two obligations are different acts on one substrate: the **scan** is a read and is owed at **all five** points per the cadence-binding rule; the **sweep** is a write-decision and is owed at **four**. The five-point table is unchanged and **no count in this section changes** — a reader auditing "§ 4 at all 5 routing points" is reading the scan, which is still total.

**Catch-up limb.** Each sweep covers this routing point **and every preceding routing point of this release at which no sweep was rendered.** Procedures 0, 1 and 6 are never sweep points, so a commitment arising there is rendered at the next sweep. Procedure 7 Close is total over completed releases, so **no commitment escapes the sweep in a completed release.** This is a **window, not a new routing point**: the four firing points and the five-point scan cadence are both unchanged by it. The limb is not hypothetical — the release that introduced this subsection created its first three commitments at **Procedure 0**, before any sweep point existed, which is exactly the case the window covers and a point-scoped rendering would have missed.

**The zero-state is emitted, not merely rendered.** A routing point whose sweep opened nothing emits a `decision` / `action-item-opened` row carrying the payload token `sweep:none-owed`. This rides the **existing** `action-item-open` EMISSION-CONTRACT row in the release-hub orchestration playbook — **no new event type, no new subtype, no new EMISSION-CONTRACT row, no new enum value**. The reuse is deliberate rather than approximate: the point of the row is to make the sweep's *firing* durable and readable after the session that rendered it has ended, and it follows the corpus's own explicit-zero-state discipline, under which a session that produced no learning emits a `no-learning` row rather than nothing. Without it, *"the sweep ran and found nothing"* and *"the sweep never ran"* are the same silence — which is the distinction this whole subsection exists to draw.

**The test the sweep applies (L1/L2).** Applied to **the routing point's own outputs**, never to the agent's inner state. Both limbs must hold:

> **L1 — Deferral.** The output states that something *will be done*, and does not do it now.
> **L2 — Unowned in-release.** The deferred thing is owed by hub, spoke, or operator **inside this release**, **and its completion is not already carried by another durable record that a gate reads.**

L2's second clause is the discriminator, and it is what makes the follow-up-card route legitimate rather than merely tolerated: a filed work item **is** a durable record, read by the Stage-2 triage gate — a different gate, deliberately. That is why findings routed to follow-up cards can leave the ledger empty without the ledger being wrong.

| # | Scenario | L1 | L2 | Verdict | Category |
|---|---|---|---|---|---|
| 1 | **A deferred edit** — "dedup the guide after PR #N merges" | ✔ the edit is named, not made | ✔ hub owes it this release; no other durable record carries it | **COMMITMENT** | `deferred-edit` |
| 2 | **A finding routed to a follow-up card** — the spoke files a work item and moves on | ✔ the work is deferred | ✘ **the work item IS the durable record**, read by triage, not by the Procedure 7 gate | **NOT a commitment** — no row | — |
| 3 | **A verification owed at a later stage** — "confirm `deploy.sh --check` passes after the skill deploys at Stage 12" | ✔ named for later | ✔ owed in-release; the plan's Verification Plan *describes* it, but no gate reads that description for **completion** | **COMMITMENT** | `verification` |

**The residue gets its own state, and is never folded into a verdict.** Scenario 4: *a spoke files a follow-up card **and** states that this release will land a pointer to it in the corpus before close.* L1 holds. L2 **splits by object** — the *finding* is carried by the card (no row); the *pointer edit* is owed in-release and carried by nothing (row). One utterance, two objects, two opposite per-object readings. The rule **names this `UNDECIDED` rather than classifying it**, the sweep renders it under form 3, and the operator dispositions it. The claim this test makes is not *"it resolves everything"*; it is *"it either resolves, or it names the residue."*

`UNDECIDED` is a **briefing rendering, never a gate state**: it surfaces in-run for operator disposition and enters no gate verdict. It is a deliberately fresh token rather than a reuse of an existing residue name. A gate-side residue — a classification the platform cannot make, rendered as an `UNCLASSIFIABLE` verdict that **fails closed** — belongs to a different register, carries a different authority, and has a different remedy, so the two must never be collapsed into one.

**The release plan may cite the ledger; it may never substitute for it.** A plan legitimately *summarises* open commitments. A plan-embedded register that carries commitments the ledger does not is drift, not an alternative home — the ledger is the only surface the Procedure 7 gate reads.

**What the hub attests at Procedure 7 Close.** States `NOT-RECORDED` and `EMPTY-LEDGER` require the operator to attest a cause from the closed two-value set `no-commitments` / `emit-skipped` — the latter meaning the Procedure 4a emit step was skipped. The hub applies this table to its own sweep renderings and brings the recommended cause **with its basis**, and it **states which routing points of this release rendered a sweep and which did not** — an unrendered sweep is itself the finding, and a gap left unstated reads identically to no gap:

| Observed across this release's routing points | Recommended cause | Basis stated with it |
|---|---|---|
| every routing point rendered the sweep, all reported none owed | `no-commitments` | *"N/N routing points swept; 0 commitments"* — sound only because the catch-up limb makes the windows tile the release |
| ≥ 1 routing point rendered **no sweep at all** | `emit-skipped` | *"the forcing function itself did not run at N of M routing points"* |
| ≥ 1 sweep rendered a commitment **and no ledger row exists** | `emit-skipped` | *"a commitment was rendered at `<routing point>` with no `AI-NNN`"* — a contradiction that can be named precisely rather than inferred |

This table is the **hub's** rule, and it sits here because every one of its rows reads what a sweep *rendered* — evidence the hub holds and a close-time tool cannot see, since the briefing renders in chat. The Stage-13 close-out tool measures what the event log can support and **declines to recommend** where its basis cannot separate the two causes; the two instruments are complements, and the operator still attests either way. **The measurement is the evidence behind the choice, never the choice.**

**Procedure 7 hard-gate rationale:** Open action items at release close are by definition a "to-do list without resolution" — CLAUDE.md "Push-to-resolve" universal preference (*"Resolve actionable items as far as possible. [OPERATOR_NAME] reviews completed work — not to-do lists."*) makes this prohibited at release boundary. The hard gate forces operator disposition (`done` / `cancelled` / `superseded`) before Milestone close. Carry-forward via `superseded` is an acceptable resolution; leaving `open` rows past Milestone close is the prohibited state.

## 5. Cross-Cutting Composition Notes

**With the agent-handoff framework ([Agent Handoff Framework](agent-handoff-framework.md)).** Action items handed off between hub and spoke (or hub and operator) MAY compose with that framework's 9-field manifest. When `owner = spoke:#N`, the handoff to that spoke includes the AI-NNN row's `description` in the manifest `inputs` field; `intent = "execute action item AI-NNN"`; `confirmation_requirement = ack`; `error_handling = escalate`. Composition is opportunistic; the handoff framework cites this standard at Stage 6 only if downstream-skill spec needs the cross-reference (no modification required).

**With the main-thread-only approval surface.** Pending approvals (PA-NNN per hub-session-continuity) and action items (AI-NNN per this standard) are surfaced via the same main-thread mechanism the hub-orchestration layer governs. The "engage with approvals on the main thread" framing extends naturally to "engage with action items on the main thread" — both are hub-surfaced items requiring operator awareness. The 5-routing-point cadence binding above is the surfacing schedule.

**With CLAUDE.md "Push-to-resolve" universal preference.** Open action items at release close violate the universal preference. Procedure 7 hard gate enforces push-to-resolve discipline at release-scope. Cancelling with rationale or superseding with an explicit successor AI-NNN are acceptable resolutions; leaving `open` rows past Milestone close is the prohibited state.

**With the release-synthesizer.** When cross-release pattern detection enables first-class AI-NNN queryability (future-state), the synthesizer composes the `action-item-cancelled` / `action-item-superseded` event-log row patterns to detect chronic carry-forward across releases (signal: same `description` text appearing in successive `superseded` chains across ≥3 releases → systemic deferral pattern worth surfacing). The synthesizer composes with this standard's event-log emissions starting at first post-cutover release.

## 6. Cutover

Each of the THREE NEW protocols shipping in this standard carries the cutover clause separately. The umbrella cutover sentence applies to the standard's existence; the protocol-specific cutovers govern individual surfaces. **`THREE` names the protocols this standard *introduced* — a historical statement about this standard's own introducing release, not a ceiling on this section.** A protocol-grade obligation added to this standard by a later release carries its own **named** cutover clause below, and changes no count here.

**Umbrella cutover.** Applies to all releases entering Stage 5 going forward. The release that shipped this standard is exempt — reflexive-pipeline-loop discipline (a standard cannot fire on its own Stage 5 / 6 / 7 / 8 / 12 / 13 hub action-item-tracking operations without creating a loop; that release's own hub action-item-tracking pattern uses the pre-cutover discretionary practice — sub-task comments, Decision Briefing inline mentions). Pre-existing in-flight releases are grandfathered.

**Protocol 1 — Action-item schema (§ 2).** Cutover applies to all action items created going forward. The release that shipped this schema is exempt — reflexive-pipeline-loop discipline (a schema cannot fire on its own release's action-item creations without creating a loop; that release's own hub action items use the pre-cutover discretionary practice — sub-task comments, Decision Briefing inline mentions).

**Protocol 2 — Pipeline-event-log subtype additions (`action-item-*` 5 subtypes).** Cutover applies to all event-log emissions going forward. The release that shipped these subtypes is exempt — reflexive-pipeline-loop discipline. That release's own Stage 13 audit-trail captures (per the audit-trail protocol) MAY emit these subtypes if the operator manually invokes them, but the standard does NOT require it.

**Protocol 3 — Review-cadence binding (§ 4, 5 routing points including Procedure 7 hard gate).** Cutover applies to hub sessions on all releases entering Stage 5 going forward. The release that shipped this cadence-binding is exempt — reflexive-pipeline-loop discipline (a cadence-binding cannot fire on its own release's Stage 13 Close action-item-resolution gate without creating a loop; that release's own Procedure 7 close uses the pre-cutover practice — operator-discretion review).

**Sweep cutover (§ 4 Composition block — the commitment sweep).** The sweep obligation is **warn-mode-initial**, and unlike the four clauses above it carries **no introducing-release exemption**, because it cannot have one. This standard is **not deployed** — it loads from the repo tree, so by the second limb of the release-hub orchestration playbook's § 4a.4 the obligation is in force **from the merge, including for the release that ships it**. That is a property of the load path, not a grant.

The asymmetry is what makes warn-mode required rather than merely prudent. The sweep's **definition** lands here, in a non-deployed file, and binds on merge; the **invocation** that triggers it — Procedure 4a step 5 — ships inside the deployed skill package and binds only at the next deploy. Between those two moments the obligation is live with no forcing function behind it, which is the exact defect class the sweep exists to close, reproduced by its own rollout. Warn-mode is what makes that window survivable: for the shipping release's remaining routing points, a routing point that advances with no rendered sweep is **reported, not blocked**, and § 4's omission-is-a-structural-defect clause acquires blocking force for releases entering Stage 5 after this one. Graduation warn → enforce follows the standard shakedown in [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md).

This clause is **named rather than numbered into the Protocol 1–3 series**, and the choice is load-bearing in both directions. Numbering it `Protocol 4` would require the `THREE` above to read `FOUR` — a count cascade this revision otherwise does not fire — and would make that sentence assert the sweep shipped in this standard's introducing release, which is false. Leaving it unnamed inside § 4 would have hidden a cutover posture in a section nobody reads for cutover.

## 7. Cross-References

| Reference | Relationship |
|---|---|
| Parent design discussion | Parent issue — establishes the gap (5 evidence cases) and 3 ACs (schema, persistence, cadence) |
| Stage 5 Solutioning spec | D-2 verdict, 13-field schema, 6-value category enum, 4-value trigger-type enum, 5-state status lifecycle, 5-routing-point cadence binding, R1 Evidence-Grounding artifacts (5 canonicalizations) |
| Hub-session-continuity substrate | **Substrate canonical** — this standard rides on `hub-session-continuity.md`'s file-based markdown convention (templates at `release/releases/hub-state/*.template`, runtime instance at `<OPERATOR_INSTANCE_HUB_STATE_PATH>/<milestone-slug>/`); AI-NNN schema parallels PA-NNN schema |
| [`hub-session-continuity.md`](hub-session-continuity.md) | Sibling K1 standard — durable substrate this standard rides on; `consumers` field declares this standard explicitly; Surface A schema parallelism + Surface B decision-log integration + § 5 session-ID format inheritance |
| Agent-handoff framework | Framework composer — 9-field handoff manifest composes with action items handed off to spoke owners (opportunistic; no modification required) |
| [`agent-handoff-framework.md`](agent-handoff-framework.md) | Sibling K1 standard — cross-agent handoff manifest format; composes with this standard's action-item handoff surface |
| Main-thread approval surface | Main-thread surfacing extension — action items surface on main-thread alongside pending approvals per Decision Briefing template extension |
| [`pipeline-event-log-schema.md`](../../release/references/standards/pipeline-event-log-schema.md) | REUSED — 5 new `action-item-*` subtypes additive on existing `decision` event_type; closed-enum discipline preserved; subtype-additive expansion governed by this standard's revision |
| [`hub-spoke-bridge.md` Procedure 4a + Procedure 7a + Operating Principle + Procedures 2/5](../../release/references/how-to/hub-spoke-bridge.md) | Thin procedural cross-references — Operating Principle Decision Briefing template gains "Action items surfaced this routing point" + "Events emitted this routing point" subsections; Procedures 2/5 add scan-step; Procedure 4a is the scan binding at spoke completion; Procedure 7a is the HARD GATE binding at release close — **canonical for the gate's 3-valued predicate and decision table** (this standard states the obligation; the bridge states the probe) |
| [`orchestration-playbook.md` Procedure 4a](../../release/skills/release-hub/references/orchestration-playbook.md) | Write-side binding — the AI-NNN append step, the § 4a.1 lazy hub-state creation discipline, and the emission of this standard's § 3 `action-item-*` subtypes. This standard defines the schema and the cadence; the playbook is where the hub is instructed to WRITE it |
| Stage 13 automated-closeout | Stage 13 automated-closeout consumer (FUTURE) — `automated-closeout.sh` MAY add an `action-items.md` open-row check before Phase 5 RELEASE_LOG transition when consumer-side adoption is timely. ACCEPT-AS-RESIDUAL. |
| Release-synthesizer | Release-synthesizer composer (FUTURE) — cross-release pattern detection MAY surface chronic-carry-forward signals from `action-item-superseded` chains across ≥3 releases when first-class AI-NNN queryability is enabled |
| [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) | K1 codified-knowledge convention placing standards in `core/standards/`; Q1 universality classifier (action-item tracking is universal — TRUE for any PMO-platform deployment) |
| [`canonical-skill-structure.md § 2`](canonical-skill-structure.md) | `standards/` houses enforcement-carrying specs; schema + lifecycle + review-cadence + hard-gate are enforcement-carrying |
| [`duplicate-source-discipline.md`](duplicate-source-discipline.md) | Register-or-remove rule; cross-reference over restatement — this standard CITES the hub-session-continuity substrate without re-canonicalizing |
| [`evidence-grounding-standard.md`](evidence-grounding-standard.md) | R1 Evidence-Grounding artifact format for the 5 canonicalizations the Stage 5 spec produced |
| [`reversibility-protocol.md`](../specs/reversibility-protocol.md) | Reversibility tier source for this standard's frontmatter declaration |
| [`gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) | G-CL6 design-artifact refresh-gate at Stage 13 — this standard is a Tier-A activated artifact per [`design-artifact-standard.md`](design-artifact-standard.md) |
| CLAUDE.md § Universal Preferences "Push-to-resolve" | Procedure 7 hard-gate rationale — open action items at release close violate the workspace-global preference |

## 8. Version History

| Version | Date | Author | Change |
|---|---|---|---|
| — | 2026-08-07 | Stage 6 Engineering (per release sub-task) | **Category enum expanded 6 → 7** — `decision-deferred` added for the declared-deferral form (a decision surfaced but not yet rendered, carried to a named operator-facing consolidation touchpoint), which previously had no category and so could conform at surface time and never reach the § 4 routing-point-5 hard gate. Governed act per § 2.1's closed-enum discipline; both cardinality carriers (§ 2 field-semantics row, § 2.1 heading) updated with it. **New § 2.1a Historical value aliases** — a READ rule for ledgers seeded before this revision from a template that had diverged on all three restated enums (`category`, `trigger_type`, `status`); no ledger is migrated, and every alias is verdict-neutral at the routing-point-5 gate. Carries the `created_at` time-scope rider for `decision-deferred`, whose meaning changes across this revision boundary. The § 2.1 / § 2.2 / § 2.3 value sets are unchanged apart from the 7th category value; the template was re-derived from them, not the reverse, and `deploy.sh --check` Check 68 (`enum-parity`) now holds the two in parity mechanically |
|  | 2026-05-23 | Stage 6 Engineering (per parent release sub-task) | Initial authoring per Stage 5 spec; 13-field action-item schema with AI-NNN namespace; 6-value category enum; 4-value trigger-type enum; 5-state status lifecycle with 7 named transitions; persistence rides on the hub-session-continuity substrate (no parallel persistence directory, no parallel ID namespace, no parallel decision log, no parallel session-ID format); 5-routing-point review cadence (Procedure 0b/2/4/5/7) with Procedure 7 HARD GATE for release-close; 3 protocol-specific cutover clauses (schema, pipeline-event-log subtype additions, review-cadence binding) plus umbrella cutover; cross-cutting composition with the agent-handoff framework + main-thread surfacing + CLAUDE.md push-to-resolve + release-synthesizer |
