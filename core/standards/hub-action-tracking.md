---
title: Hub Action Tracking
purpose: K1 codified-knowledge standard defining the schema, persistence mechanism, and review cadence for hub-tracked action items (AI-NNN) — durable commitments the hub or operator must execute at a future routing point. Rides on the hub-session-continuity substrate (file-based markdown — template at release/releases/hub-state/action-items.md.template; runtime instance at <OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/action-items.md); composes with the agent-handoff framework when action items are handed off to spoke owners; surfaces via the main-thread Decision Briefing mechanism governed by the hub-orchestration layer.
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

This standard defines how the hub tracks **action items** — durable commitments to execute work at a future routing point (deferred edits, reminders, cleanups, decisions deferred for posting, cross-issue merge waits, post-action verifications). It complements the hub-session-continuity substrate (which governs hub state across session boundaries) and the agent-handoff framework (which governs cross-agent handoff manifests) by adding the third surface: **what the hub OWES** between now and release close.

The parent design discussion framed the gap as the absence of a tracking mechanism for the obligations that operators and hub repeatedly emit during a release ("dedup that guide after the PR merges," "add a web UI config reminder for Stage 10," "close issue A after issue B merges"). These commitments currently live in sub-task comments, Decision Briefing prose, and operator memory — easy to drop, easy to drift, easy to leak past release close. This standard codifies the surface so commitments are explicit, schema-validated, surfaced at 5 routing points, and **gated at Stage 13 Close** so no `status:open` row leaks across release boundaries.

**Scope.** Action items emitted by the hub OR by spokes during release execution; persisted within a single release lifecycle. Cross-release carry-forward uses an explicit `superseded` transition with a successor AI-NNN in the next release's `action-items.md` — implicit carry-forward is prohibited.

**Out of scope.** Pending-approval queue mechanics (owned by [`hub-session-continuity.md` § 3.1](hub-session-continuity.md) — PA-NNN rows in `pending-approvals.md`). Session-boundary state schema (owned by `hub-session-continuity.md` §§ 3, 5). Agent handoff manifests (owned by [`agent-handoff-framework.md`](agent-handoff-framework.md)). Main-thread surfacing semantics (owned by the hub-orchestration layer — this standard extends that surface to AI-NNN rows but does NOT govern the surfacing mechanism). Skill-internal action queues (out of scope by Layer-1 / Layer-2 boundary per [`operations-bridge.md`](<OPERATOR_INSTANCE_CLAUDE_DIR>/rules/operations-bridge.md)).

## 1. D-2 Placement Verdict

Per Stage 5 D-2 verdict on : the action-item schema + persistence-substrate-binding + review-cadence rule + Procedure 7 hard gate are normative spec material — `core/standards/` is the canonical K1 home per [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) (Q1 universality classifier: TRUE for any PMO-platform deployment; K1 codified-knowledge tier). The verdict IS this file's existence at this path. Sibling NEW standards files converge on the same placement, satisfying R4 N-way consistency at Collective Review: `hub-session-continuity.md` , `agent-handoff-framework.md` , and this file. Thin Procedure 4a + 7a cross-references in [`hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md) plus subsection additions to the Operating Principle Decision Briefing template + Procedures 2 / 5 point operators to this standard for full schema + behavior; the bridge doc does NOT duplicate normative content.

## 2. Action-Item Schema

**Template (tracked):** [`release/releases/hub-state/action-items.md.template`](../../release/releases/hub-state/action-items.md.template)
**Runtime instance (operator-local):** `<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/action-items.md` — sibling to [the hub-session-continuity `pending-approvals.md` runtime instance](hub-session-continuity.md). Created LAZILY on first action-item emit per the directory-creation discipline in [`hub-session-continuity.md` § 2](hub-session-continuity.md).

**Frontmatter (YAML — parallel to the hub-session-continuity Surface A; session-ID format inherited verbatim per [`hub-session-continuity.md` § 5](hub-session-continuity.md)):**

```yaml
---
schema_version: "v1.0"
milestone: "vX.Y-<milestone-slug>"
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
| `category` | enum (6 values; see § 2.1) | YES | Action-specific classification (drives owner/surface defaults) |
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

### 2.1 Category enum (6 values)

| Category | Definition | Example (from parent design discussion Evidence) |
|---|---|---|
| `deferred-edit` | A file edit deferred to a later trigger point | "github-projects-guide.md dedup after PR merge" |
| `reminder` | A note-to-self the hub must surface at a future routing point | "web UI config reminder for Stage 10" |
| `cleanup` | A removal or tidy-up obligation at a future point | "test project cleanup at Stage 12" |
| `decision-to-post` | A decision rendered now whose announcement is deferred (e.g., comment to post after a sibling issue closes) | "D5 sub-issue initialization decision to post on parent issue" |
| `cross-issue-merge` | An action gated on another issue's resolution (e.g., close issue A after issue B merges) | "issue #NNNN close after sibling #NNNN merge" |
| `verification` | A post-action check to confirm an executed action produced the expected state | "verify deploy.sh --check passes after skill X deploys" |

Categories cover all 5 evidence cases enumerated in the parent design discussion verbatim — each evidence case maps to exactly one category. `verification` adds a post-execution-confirmation surface (parent evidence does not enumerate a case, but hub frequently emits verification action items in practice). Enum expansion is governed via this standard's revision per [`pipeline-event-log-schema.md § 3`](../../release/references/standards/pipeline-event-log-schema.md) closed-enum discipline.

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

**Substrate (cited from [`hub-session-continuity.md` § 2](hub-session-continuity.md)):** schema templates tracked at `release/releases/hub-state/*.template`; runtime instance written to the operator-instance path `<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/` per [`public-repo-vs-operator-instance-taxonomy.md`](public-repo-vs-operator-instance-taxonomy.md) §4.3; file-based markdown; frontmatter + table format; append-only-with-status-mutation discipline.

**Resulting runtime directory contents per release (at the operator-instance path):**

```
<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/
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

**Why ride the hub-session-continuity substrate rather than separate (rationale archive):** One persistence pattern for operator to learn; Resume Procedure reads both files at hub-session-continuity Step 7 (generalized from `pending-approvals.md` to all `*-state.md` files in `hub-state/vX.Y/`); single-directory edit reduces commit overhead; future skill replacement consumes the standard substrate uniformly; citation-graph clarity (this standard cites hub-session-continuity for substrate without re-canonicalizing).

## 4. Review Cadence — 5-Routing-Point Binding

Hub reads `action-items.md` and scans for triggered rows at FIVE routing points. At each, surfaced action items appear in the Decision Briefing alongside the standard procedure output.

| # | Routing point | When | What hub scans for | Action |
|---|---|---|---|---|
| 1 | **Procedure 0b — Resume Procedure** (per [`hub-session-continuity.md` § 4](hub-session-continuity.md) Operating Principle template item 4 forcing-function) | Hub session start | `status:open` rows with `trigger_type:time` whose deadline has passed | Surface in "Hub session start" Decision Briefing as `in-flight` candidates |
| 2 | **Procedure 2 — Routing (What's Next)** | Operator asks "what's next?" OR spoke completes | `status:open` rows with `trigger_type:event` or `trigger_type:cross-issue-merge` whose predicate matches current GitHub state | Surface alongside next-actionable sub-tasks; operator MAY elect to route action item ahead of pipeline work |
| 3 | **Procedure 4 — Spoke Completion** (via thin Procedure 4a binding) | Spoke posts and closes its sub-task | `status:open` rows with `trigger_type:event` whose `trigger_detail` references this spoke's completion (e.g., "after Stage 5 sub-task #NNNN closes, post substrate-alignment note on sibling issue") | Auto-transition T2 (`open → in-flight`); hub or operator executes |
| 4 | **Procedure 5 — Gate Handling** | Release reaches a gate (Stage 9, Stage 12) | `status:open` rows with `trigger_type:stage-boundary` whose `trigger_detail` matches the gate's stage | Surface in gate-decision briefing; operator MAY resolve action item as part of gate decision |
| 5 | **Procedure 7 — Close** (via thin Procedure 7a binding — HARD GATE) | Stage 13 Milestone close | ALL `status:open` AND `status:in-flight` rows | **HARD GATE.** Operator MUST resolve each remaining row (transition to `done`, `cancelled`, or `superseded`) before Milestone close. Carry-forward to next release is via `superseded` with explicit successor AI-NNN in the next release's `action-items.md`. |

**Cadence-binding rule (canonical):** Hub MUST scan `action-items.md` at all 5 routing points. Skipping the scan is a structural defect surfaced by Stage 8 QA + Stage 13 Procedure 7a HARD GATE (§ 4 row 5). Stage 13 automated-closeout per the release-process protocol MAY add a programmatic open-row check before Phase 5 RELEASE_LOG transition when consumer-side adoption is timely (ACCEPT-AS-RESIDUAL).

**Composition with existing Decision Briefing template:** The Decision Briefing template at [`hub-spoke-bridge.md` Operating Principle](../../release/references/how-to/hub-spoke-bridge.md) gains an "Action items surfaced this routing point" subsection at each routing point. Subsection format:

```markdown
**Action items surfaced this routing point:**

| AI-NNN | Category | Description | Trigger fired | Recommended disposition |
|---|---|---|---|---|
| AI-003 | reminder | web UI config reminder for Stage 10 | stage-boundary: Stage 10 reached | execute now |
```

When zero rows trigger, the subsection reads "No action items triggered at this routing point" — omission is a structural defect (forcing-function makes the scan observable).

**Procedure 7 hard-gate rationale:** Open action items at release close are by definition a "to-do list without resolution" — CLAUDE.md "Push-to-resolve" universal preference (*"Resolve actionable items as far as possible. [OPERATOR_NAME] reviews completed work — not to-do lists."*) makes this prohibited at release boundary. The hard gate forces operator disposition (`done` / `cancelled` / `superseded`) before Milestone close. Carry-forward via `superseded` is an acceptable resolution; leaving `open` rows past Milestone close is the prohibited state.

## 5. Cross-Cutting Composition Notes

**With the agent-handoff framework ([Agent Handoff Framework](agent-handoff-framework.md)).** Action items handed off between hub and spoke (or hub and operator) MAY compose with that framework's 9-field manifest. When `owner = spoke:#N`, the handoff to that spoke includes the AI-NNN row's `description` in the manifest `inputs` field; `intent = "execute action item AI-NNN"`; `confirmation_requirement = ack`; `error_handling = escalate`. Composition is opportunistic; the handoff framework cites this standard at Stage 6 only if downstream-skill spec needs the cross-reference (no modification required).

**With the main-thread-only approval surface.** Pending approvals (PA-NNN per hub-session-continuity) and action items (AI-NNN per this standard) are surfaced via the same main-thread mechanism the hub-orchestration layer governs. The "engage with approvals on the main thread" framing extends naturally to "engage with action items on the main thread" — both are hub-surfaced items requiring operator awareness. The 5-routing-point cadence binding above is the surfacing schedule.

**With CLAUDE.md "Push-to-resolve" universal preference.** Open action items at release close violate the universal preference. Procedure 7 hard gate enforces push-to-resolve discipline at release-scope. Cancelling with rationale or superseding with an explicit successor AI-NNN are acceptable resolutions; leaving `open` rows past Milestone close is the prohibited state.

**With the release-synthesizer.** When cross-release pattern detection enables first-class AI-NNN queryability (future-state), the synthesizer composes the `action-item-cancelled` / `action-item-superseded` event-log row patterns to detect chronic carry-forward across releases (signal: same `description` text appearing in successive `superseded` chains across ≥3 releases → systemic deferral pattern worth surfacing). The synthesizer composes with this standard's event-log emissions starting at first post-cutover release.

## 6. Cutover

Each of the THREE NEW protocols shipping in this standard carries the cutover clause separately. The umbrella cutover sentence applies to the standard's existence; the protocol-specific cutovers govern individual surfaces.

**Umbrella cutover.** Applies to all releases entering Stage 5 going forward. The release that shipped this standard is exempt — reflexive-pipeline-loop discipline (a standard cannot fire on its own Stage 5 / 6 / 7 / 8 / 12 / 13 hub action-item-tracking operations without creating a loop; that release's own hub action-item-tracking pattern uses the pre-cutover discretionary practice — sub-task comments, Decision Briefing inline mentions). Pre-existing in-flight releases are grandfathered.

**Protocol 1 — Action-item schema (§ 2).** Cutover applies to all action items created going forward. The release that shipped this schema is exempt — reflexive-pipeline-loop discipline (a schema cannot fire on its own release's action-item creations without creating a loop; that release's own hub action items use the pre-cutover discretionary practice — sub-task comments, Decision Briefing inline mentions).

**Protocol 2 — Pipeline-event-log subtype additions (`action-item-*` 5 subtypes).** Cutover applies to all event-log emissions going forward. The release that shipped these subtypes is exempt — reflexive-pipeline-loop discipline. That release's own Stage 13 audit-trail captures (per the audit-trail protocol) MAY emit these subtypes if the operator manually invokes them, but the standard does NOT require it.

**Protocol 3 — Review-cadence binding (§ 4, 5 routing points including Procedure 7 hard gate).** Cutover applies to hub sessions on all releases entering Stage 5 going forward. The release that shipped this cadence-binding is exempt — reflexive-pipeline-loop discipline (a cadence-binding cannot fire on its own release's Stage 13 Close action-item-resolution gate without creating a loop; that release's own Procedure 7 close uses the pre-cutover practice — operator-discretion review).

## 7. Cross-References

| Reference | Relationship |
|---|---|
| Parent design discussion | Parent issue — establishes the gap (5 evidence cases) and 3 ACs (schema, persistence, cadence) |
| Stage 5 Solutioning spec | D-2 verdict, 13-field schema, 6-value category enum, 4-value trigger-type enum, 5-state status lifecycle, 5-routing-point cadence binding, R1 Evidence-Grounding artifacts (5 canonicalizations) |
| Hub-session-continuity substrate | **Substrate canonical** — this standard rides on `hub-session-continuity.md`'s file-based markdown convention (templates at `release/releases/hub-state/*.template`, runtime instance at `<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/`); AI-NNN schema parallels PA-NNN schema |
| [`hub-session-continuity.md`](hub-session-continuity.md) | Sibling K1 standard — durable substrate this standard rides on; `consumers` field declares this standard explicitly; Surface A schema parallelism + Surface B decision-log integration + § 5 session-ID format inheritance |
| Agent-handoff framework | Framework composer — 9-field handoff manifest composes with action items handed off to spoke owners (opportunistic; no modification required) |
| [`agent-handoff-framework.md`](agent-handoff-framework.md) | Sibling K1 standard — cross-agent handoff manifest format; composes with this standard's action-item handoff surface |
| Main-thread approval surface | Main-thread surfacing extension — action items surface on main-thread alongside pending approvals per Decision Briefing template extension |
| [`pipeline-event-log-schema.md`](../../release/references/standards/pipeline-event-log-schema.md) | REUSED — 5 new `action-item-*` subtypes additive on existing `decision` event_type; closed-enum discipline preserved; subtype-additive expansion governed by this standard's revision |
| [`hub-spoke-bridge.md` Procedure 4a + Procedure 7a + Operating Principle + Procedures 2/5](../../release/references/how-to/hub-spoke-bridge.md) | Thin procedural cross-references — Operating Principle Decision Briefing template gains "Action items surfaced this routing point" subsection; Procedures 2/5 add scan-step; Procedure 4a is the scan binding at spoke completion; Procedure 7a is the HARD GATE binding at release close |
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
|  | 2026-05-23 | Stage 6 Engineering (per parent release sub-task) | Initial authoring per Stage 5 spec; 13-field action-item schema with AI-NNN namespace; 6-value category enum; 4-value trigger-type enum; 5-state status lifecycle with 7 named transitions; persistence rides on the hub-session-continuity substrate (no parallel persistence directory, no parallel ID namespace, no parallel decision log, no parallel session-ID format); 5-routing-point review cadence (Procedure 0b/2/4/5/7) with Procedure 7 HARD GATE for release-close; 3 protocol-specific cutover clauses (schema, pipeline-event-log subtype additions, review-cadence binding) plus umbrella cutover; cross-cutting composition with the agent-handoff framework + main-thread surfacing + CLAUDE.md push-to-resolve + release-synthesizer |
