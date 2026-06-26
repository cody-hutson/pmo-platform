<!-- reference-durability: allow-link -->
# GitHub Projects Guide

Operational reference for the PMO Pipeline GitHub Project. Covers project architecture, fields, views, automations, and agent integration.

**Source issue:**
**Project URL:** [OPERATOR_GITHUB_PROJECT_URL]
**Project number:** 4
**Project node ID:** [OPERATOR_PROJECT_NODE_ID]

> **Depersonalization note:** GitHub Project IDs (`PVT_*`, `PVTF_*`, `PVTSSF_*`) and single-select option IDs (`single-select-option-id <hex>` 8-char strings in example commands) are operator-instance per [universal-vs-localized-context.md](../standards/universal-vs-localized-context.md) DC1–DC4. The bracketed `[OPERATOR_GITHUB_PROJECT_URL]` / `[OPERATOR_PROJECT_NODE_ID]` / `[OPERATOR_PROJECTS_*_FIELD_ID]` tokens above and below have their **canonical home at `~/.config/pmo-platform/operator.toml` `[projects]`** (registered in [depersonalization-spec.md §1.1](../standards/depersonalization-spec.md)) — set your board's values there once, centrally. **Fallback / one-time discovery** of the values: `gh project field-list --owner <YOUR_HANDLE> --number <YOUR_PROJECT_NUMBER> --format json`. The single-select option IDs embedded in example commands below are NOT tokenized — preserved literally for traceability; your project will have different option IDs, obtained via `gh project field-list ... --format json | jq '.fields[] | select(.name=="Status") | .options'`. **Enforcement:** `deploy.sh --check` Check 44 (depersonalization-token) ratchets against reintroducing a literal `PVT*` ID outside this guide and asserts every `[OPERATOR_*]` token used in the corpus is registered in the §1/§1.1 vocabulary (warn-mode initial).

---

## Architecture

**Single project, multiple views.** All pipeline issues live in one GitHub Project ("PMO Pipeline") with four saved views that provide different lenses on the same data. This avoids field duplication across projects and simplifies agent integration to a single project ID.

**Rationale:** State Anchor fields (Status, Stage) defined in ticket-information-architecture.md are per-project. A single project ensures one authoritative field value per issue. The 50K item limit is orders of magnitude beyond current needs.

**Relationship to other tracking mechanisms:**
- **Issue body** = source of truth (per ticket-information-architecture.md)
- **Labels** = categorization (type, cluster, disposition)
- **Projects fields** = pipeline state (Status, Stage, Priority)
- **Milestones** = release assignment

Projects fields and labels are **parallel state anchors** — both exist per the ticket information architecture. Labels are visible on issue cards; fields enable board views and API queries. Agents update both atomically at stage transitions.

---

## Custom Fields

Four custom fields implement the State Anchor layer defined in ticket-information-architecture.md.

### Status (Single-Select)

Tracks pipeline lifecycle position. Parallels `status: *` labels.

| Option | Description | Set By |
|---|---|---|
| Proposed | Awaiting triage | Automation (item added) or agent (Intake) |
| Approved | Triaged and approved | Agent (Triage gate pass) |
| Bundled | Assigned to release Milestone | Agent (Bundle) |
| In Progress | Active engineering work | Agent (Engineering start) |
| Done | Complete | Automation (item closed, PR merged) or agent (Close) |

**Valid transitions:**

```
Proposed → Approved → Bundled → In Progress → Done
              ↘ Rejected (close issue)
              ↘ Deferred (close issue) → Approved (reopen)
```

### Stage (Single-Select)

Tracks current pipeline stage position. Advances linearly through the pipeline.

| Option | Pipeline Stage |
|---|---|
| 1-Intake | Stage 1: Intake |
| 2-Triage | Stage 2: Triage |
| 3-Bundle | Stage 3: Bundle |
| 4-Planning | Stage 4: Planning |
| 5-Solutioning | Stage 5: Solutioning |
| 6-Engineering | Stage 6: Engineering |
| 7-DevTest | Stage 7: Dev Testing |
| 8-QA | Stage 8: QA Testing |
| 9-PlanReview | Stage 9: Plan Review |
| 12-Execute | Stage 12: Execute |
| 13-Close | Stage 13: Close |

Stages 10-11 are omitted per pipeline compression — satisfied by git-native mechanisms.

### Priority (Single-Select)

Surfaces the body-level Priority field for board sorting and filtering.

| Option | Description |
|---|---|
| P1-Critical | Blocks pipeline operation |
| P2-High | Important for next release |
| P3-Medium | Standard priority |
| P4-Low | Nice to have |

Set at Triage (Stage 2) when agent updates body priority.

### Decision Date (Date)

Records the date when the triage decision was rendered. Set automatically by the agent at the CER Resolve phase of Stage 2 for all three triage outcomes (Approve, Reject, Defer).

| Attribute | Value |
|---|---|
| Type | Date |
| Set By | Agent (Triage — CER Resolve) |
| Trigger | Status change from Proposed → Approved/Rejected/Deferred |

### Status-Stage Valid Combinations

Agents validate that an issue's Status and Stage form a valid pair before executing transitions. Derived from the T1-T5 transitions in [ticket-information-architecture.md](../../release/references/specs/ticket-information-architecture.md).

| Status | Valid Stage Range | Transition In | Transition Out |
|---|---|---|---|
| Proposed | 1-Intake, 2-Triage | T1: automation (item added) | T2: agent (Triage approves → Approved) |
| Approved | 2-Triage (exit), 3-Bundle (entry) | T2: agent (Triage) | T3: agent (Bundle assigns → Bundled) |
| Bundled | 3-Bundle (exit), 4-Planning, 5-Solutioning | T3: agent (Bundle) | T4: agent (Engineering starts → In Progress) |
| In Progress | 6-Engineering through 12-Execute | T4: agent (Engineering entry) | T5: automation (close/merge → Done) |
| Done | 13-Close | T5: automation (close/merge) | N/A |

**Invalid combinations** (e.g., Proposed + 6-Engineering, Done + 4-Planning) indicate a process violation or transient inconsistency. Agents should flag, not silently execute. See [Reopen Behavior](#reopen-behavior) for the one expected transient inconsistency.

---

## Field IDs (for Agent Integration)

These IDs are required for `gh project item-edit` commands.

| Field | Field ID |
|---|---|
| Status | `[OPERATOR_PROJECTS_STATUS_FIELD_ID]` |
| Stage | `[OPERATOR_PROJECTS_STAGE_FIELD_ID]` |
| Priority | `[OPERATOR_PROJECTS_VIEW_FIELD_ID]` |
| Decision Date | `[OPERATOR_PROJECTS_DATE_FIELD_ID]` |

**JSON key convention for `gh project item-list --format json`:** Custom-field JSON keys are derived from the field's display name **verbatim** (not camelCased). Multi-word display names produce space-containing JSON keys — e.g., `Decision Date` → `"decision Date"`. When parsing item-list JSON via `jq`, address such keys with quoted-key syntax: `."decision Date"`, not `.decisionDate`. For name-stable read-back (resilient to future field renames), prefer GraphQL `fieldValueByName(name:"Decision Date")`. Originating evidence: .

### Status Option IDs

| Option | Option ID |
|---|---|
| Proposed | `c68a9820` |
| Approved | `b0279534` |
| Bundled | `f13a846b` |
| In Progress | `60ae500b` |
| Done | `73089699` |

### Stage Option IDs

| Option | Option ID |
|---|---|
| 1-Intake | `4ed64776` |
| 2-Triage | `4c3c1ac8` |
| 3-Bundle | `e3b07e2d` |
| 4-Planning | `de247978` |
| 5-Solutioning | `5d085026` |
| 6-Engineering | `5be66538` |
| 7-DevTest | `8199192e` |
| 8-QA | `316a954f` |
| 9-PlanReview | `f0c6d940` |
| 12-Execute | `69854b03` |
| 13-Close | `1d9b0e7b` |

### Priority Option IDs

| Option | Option ID |
|---|---|
| P1-Critical | `2b8db1ae` |
| P2-High | `bed9ce34` |
| P3-Medium | `eb268470` |
| P4-Low | `1a052636` |

---

## Saved Views

Four views provide different lenses on the same issue set.

### Pipeline (Board)

Full pipeline visibility — where is every issue?

| Setting | Value |
|---|---|
| Layout | Board |
| Column field | Stage |
| Sort | Priority ascending (P1 first) |
| Filter | None |

### Backlog (Table)

Triage and bundling workflow — what needs decisions?

| Setting | Value |
|---|---|
| Layout | Table |
| Visible columns | Title, Status, Stage, Priority, Milestone, Labels |
| Filter | `status:Proposed,Approved,Bundled` |
| Sort | Priority ascending |
| Group by | Status |

The **Stage** column is required here: this view groups the `Proposed/Approved/Bundled` cohort by Status, and `Bundled` spans Stages 3–5. Without Stage visible, every `Bundled` issue collapses into one group with no way to tell Stage-3 (Bundle) from Stage-4 (Planning) from Stage-5 (Solutioning) apart. Status is the coarse lifecycle axis; Stage renders the fine pipeline position the coarse axis cannot. (See [`ticket-information-architecture.md`](../../release/references/specs/ticket-information-architecture.md) § State Anchors → Design rationale.)

### Active Release (Board)

Current release execution — where is active work?

| Setting | Value |
|---|---|
| Layout | Board |
| Column field | Stage |
| Filter | `status:"In Progress"` |
| Sort | Priority ascending |
| Slice by | Milestone |

### Roadmap (Roadmap)

Cross-milestone timeline — what is coming when?

| Setting | Value |
|---|---|
| Layout | Roadmap |
| Group by | Milestone |
| Filter | `status:Approved,Bundled,"In Progress"` |

---

## Built-in Automations

### Configured Workflows

| Workflow | Trigger | Action |
|---|---|---|
| Item added to project | Any item added | Status → Proposed |
| Item closed | Issue/PR closed | Status → Done |
| Item reopened | Issue/PR reopened | Status → Proposed |
| Pull request merged | PR merged | Status → Done |
| Auto-archive | Status = Done, 14 days | Archive item |

### Auto-add Workflow

| Setting | Value |
|---|---|
| Filter | `is:issue repo:[OPERATOR_GITHUB]/pmo-platform` |
| Limit | 1 workflow (Free plan) |

Auto-add captures issues created AFTER the workflow is enabled. Existing issues were bulk-added at project setup.

### Reopen Behavior

When an issue is reopened, the built-in automation resets Status → Proposed, but Stage retains its last value (e.g., Stage = 8-QA). This creates a temporarily invalid Status-Stage combination. The transient inconsistency is expected and self-correcting — the next agent that claims the issue validates prerequisites via the CER pattern and resets Stage appropriately (typically 2-Triage for re-triage).

### What Automations Cannot Do

Built-in automations handle **bookend** transitions (add→Proposed, close→Done). **Intermediate** transitions require agent writes:

| Gap | Fill Mechanism |
|---|---|
| Status based on label change | Agent updates Status field when updating labels at stage transitions |
| Stage field on any trigger | Agent sets Stage via `gh project item-edit` at stage entry |
| Priority field | Agent sets Priority via `gh project item-edit` at Triage |
| Intermediate statuses (Approved, Bundled, In Progress) | Agent handles programmatically at stage gates |
| Decision Date on triage decision | Agent sets via `gh project item-edit --date` at Triage CER Resolve |

---

## Agent Integration

### Prerequisites

Token must have `project` scope:
```bash
gh auth refresh -s read:project -s project
```

### Read Pattern

```bash
# List all items with field values
gh project item-list 4 --owner [OPERATOR_GITHUB] --format json

# List fields and option IDs
gh project field-list 4 --owner [OPERATOR_GITHUB] --format json
```

### Write Pattern

```bash
# Update a single-select field value
gh project item-edit \
  --project-id [OPERATOR_PROJECT_NODE_ID] \
  --id <ITEM_ID> \
  --field-id <FIELD_ID> \
  --single-select-option-id <OPTION_ID>
```

### Add Pattern

```bash
# Add single issue
gh project item-add 4 --owner [OPERATOR_GITHUB] \
  --url https://github.com/[OPERATOR_GITHUB]/pmo-platform/issues/<N>
```

### Stage Transition Pattern

See [Ticket Lifecycle Protocol](../../release/references/specs/ticket-information-architecture.md#ticket-lifecycle-protocol) for the authoritative stage transition sequence (CER pattern, T1-T5 transitions, per-stage protocol).

### Stage Transition Commands

Copy-paste ready CLI commands for every pipeline transition. All commands use the same project prefix:

```
--project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID}
```

Replace `{ITEM_ID}` with the issue's project item ID (from `gh project item-list 4 --owner [OPERATOR_GITHUB] --format json`).

**Status transitions (agent-driven):**

| Transition | Command |
|---|---|
| T2: → Approved | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_STATUS_FIELD_ID] --single-select-option-id b0279534` |
| T3: → Bundled | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_STATUS_FIELD_ID] --single-select-option-id f13a846b` |
| T4: → In Progress | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_STATUS_FIELD_ID] --single-select-option-id 60ae500b` |

T1 (→ Proposed) and T5 (→ Done) are automation-handled. Agents do not set these Status values.

**Stage transitions (agent-driven, all stages):**

| Stage Entry | Command |
|---|---|
| → 1-Intake | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_STAGE_FIELD_ID] --single-select-option-id 4ed64776` |
| → 2-Triage | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_STAGE_FIELD_ID] --single-select-option-id 4c3c1ac8` |
| → 3-Bundle | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_STAGE_FIELD_ID] --single-select-option-id e3b07e2d` |
| → 4-Planning | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_STAGE_FIELD_ID] --single-select-option-id de247978` |
| → 5-Solutioning | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_STAGE_FIELD_ID] --single-select-option-id 5d085026` |
| → 6-Engineering | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_STAGE_FIELD_ID] --single-select-option-id 5be66538` |
| → 7-DevTest | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_STAGE_FIELD_ID] --single-select-option-id 8199192e` |
| → 8-QA | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_STAGE_FIELD_ID] --single-select-option-id 316a954f` |
| → 9-PlanReview | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_STAGE_FIELD_ID] --single-select-option-id f0c6d940` |
| → 12-Execute | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_STAGE_FIELD_ID] --single-select-option-id 69854b03` |
| → 13-Close | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_STAGE_FIELD_ID] --single-select-option-id 1d9b0e7b` |

**Priority (set at Triage):**

| Priority | Command |
|---|---|
| → P1-Critical | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_VIEW_FIELD_ID] --single-select-option-id 2b8db1ae` |
| → P2-High | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_VIEW_FIELD_ID] --single-select-option-id bed9ce34` |
| → P3-Medium | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_VIEW_FIELD_ID] --single-select-option-id eb268470` |
| → P4-Low | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_VIEW_FIELD_ID] --single-select-option-id 1a052636` |

**Decision Date (set at Triage — all outcomes):**

| Transition | Command |
|---|---|
| Triage decision | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id {ITEM_ID} --field-id [OPERATOR_PROJECTS_DATE_FIELD_ID] --date YYYY-MM-DD` |

### Preferred Verification Patterns

Per-Issue field reads (Stage 2 B2a Verification, ad-hoc state checks, post-transition validation) use **single-item GraphQL via `fieldValueByName`** as the canonical form. Bulk reads (Decision Date Backfill detection, full-board audits, status reconciliation scans) use the **literal-key batch query** with `jq`. The two patterns address distinct use cases with distinct credit profiles; using the wrong tool for the job exhausts the GraphQL rate-limit pool after ~3 invocations.

**Pattern routing matrix:**

| Use case | Pattern | Credits per call | Throughput per hour |
|---|---|---|---|
| Single-field single-item read (B2a Verification, ad-hoc state check) | `gh api graphql -f query='query { node(id: "<ITEM_ID>") { ... on ProjectV2Item { fieldValueByName(name: "<FIELD_NAME>") { ... on <ProjectV2ItemField<TYPE>Value> { <projection> } } } } }'` | ~1 GraphQL credit | ~5000 |
| Multi-field single-item read (post-transition validation, debug state dump) | `gh api graphql -f query='query { node(id: "<ITEM_ID>") { ... on ProjectV2Item { fieldValues(first: 20) { nodes { ... } } } } }'` | ~1 GraphQL credit | ~5000 |
| Bulk single-field read (backfill detection, full-board scan) | `gh project item-list 4 --owner [OPERATOR_GITHUB] --format json --limit 5000 \| jq -r '.items[] \| select(."<field-name>" == null) \| .content.number'` | ~5000 REST credits | ~1 |
| Bulk multi-field read (full-board state extraction) | Same as bulk single-field, multiple `jq` projections | ~5000 REST credits | ~1 |

**Field-type projection (GraphQL `... on <ProjectV2ItemField<TYPE>Value>` fragments):**

| Field type | Fragment | Projection |
|---|---|---|
| Date | `... on ProjectV2ItemFieldDateValue` | `date` |
| Single-select | `... on ProjectV2ItemFieldSingleSelectValue` | `name` |
| Text | `... on ProjectV2ItemFieldTextValue` | `text` |
| Number | `... on ProjectV2ItemFieldNumberValue` | `number` |
| Iteration | `... on ProjectV2ItemFieldIterationValue` | `title`, `startDate`, `duration` |

**Worked examples:**

Decision Date single-item verification (Stage 2 B2a — canonical example):
```bash
gh api graphql -f query='
query { node(id: "<ITEM_ID>") { ... on ProjectV2Item {
  fieldValueByName(name: "Decision Date") {
    ... on ProjectV2ItemFieldDateValue { date }
  }
}}}' --jq '.data.node.fieldValueByName.date'
```

Status single-item verification (e.g., post-transition state-anchor check):
```bash
gh api graphql -f query='
query { node(id: "<ITEM_ID>") { ... on ProjectV2Item {
  fieldValueByName(name: "Status") {
    ... on ProjectV2ItemFieldSingleSelectValue { name }
  }
}}}' --jq '.data.node.fieldValueByName.name'
```

Multi-field single-item dump (debug — Status + Stage + Decision Date in one call):
```bash
gh api graphql -f query='
query { node(id: "<ITEM_ID>") { ... on ProjectV2Item {
  fieldValues(first: 20) { nodes {
    ... on ProjectV2ItemFieldDateValue { field { ... on ProjectV2FieldCommon { name } } date }
    ... on ProjectV2ItemFieldSingleSelectValue { field { ... on ProjectV2FieldCommon { name } } name }
  } }
}}}' --jq '.data.node.fieldValues.nodes[] | select(.field != null)'
```

Bulk Decision Date null-detection (used by § Decision Date Backfill (Retroactive)):
```bash
gh project item-list 4 --owner [OPERATOR_GITHUB] --format json --limit 5000 \
  | jq -r '.items[] | select((."decision Date" == null) and (.content.number != null)) | .content.number'
```

**Anti-pattern:** Using `gh project item-list 4 --owner [OPERATOR_GITHUB] --format json --limit 5000` followed by `jq '.items[] | select(.content.number == <N>) | ."<field>"'` to read a single field of one item. This pattern fetches up to 5000 Project items per invocation (~5000 REST credits) and exhausts the hourly pool after ~3 invocations. The Stage 2 Triage operation is rate-limit-constrained to ~3 per hour when this pattern is used — recovered by ~19-minute pool reset. **Use the single-item GraphQL pattern instead.** Originating evidence: .

**Item-ID resolution:** Single-item GraphQL requires the Project Item ID (`PVTI_*`). For Stage 2 B2a Verification specifically, the item-ID is already in agent context from the B2a Command step (`stage-02-triage.md` § Phase B B2a "Command" row: `gh project item-edit --id <ITEM_ID>`); no separate lookup is needed at Verification. For other consumers where the item-ID is unknown (fresh entry, ad-hoc state check), perform a one-time lookup (`gh project item-list` or `gh api graphql -f query='query { repository(owner:"[OPERATOR_GITHUB]", name:"pmo-platform") { issue(number:<N>) { projectItems(first:1) { nodes { id } } } } }'`) and cache the ID for subsequent reads in the session.

**Cutover discipline:** Applies to all releases going forward.

### PR Integration

PRs created with `--project "PMO Pipeline"` appear on the project board alongside their linked issues. The "PR merged" automation sets Status → Done.

---

## Sub-Issue Projects Field Management

Sub-issues (engineering sub-tasks, review passes) follow the same Projects field lifecycle as all other issues.

### Initialization

Sub-issues start as **Proposed** via the auto-add automation — the same path as every other issue. No special initialization override is needed at creation time. Proposed is the correct initial state: the sub-issue has been proposed (created) but not yet claimed by an agent.

### State Transitions via CER

When an agent begins work on a sub-issue, the CER Claim phase handles the state transition:

1. **Claim:** Agent reads the sub-issue, validates prerequisites, updates Status → In Progress and Stage → appropriate stage (e.g., 6-Engineering for sub-tasks, 7-DevTest for review passes)
2. **Execute:** Agent performs the work
3. **Resolve:** Agent posts results, closes the sub-issue

This is consistent with the [Ticket Lifecycle Protocol](../../release/references/specs/ticket-information-architecture.md) — CER governs all state transitions regardless of whether the issue is a parent or sub-issue.

### Sub-Issue Lifecycle Summary

| Event | Status | Stage | Actor |
|---|---|---|---|
| Sub-issue created + auto-added | Proposed (automation) | Inherits no stage (unset until claimed) | Automation |
| Agent claims sub-issue | In Progress (agent) | Set to current pipeline stage (agent) | Agent (CER Claim) |
| Work complete | — | — | Agent (CER Resolve) |
| Sub-issue closed | Done (automation on close) | Retains last value | Agent closes |

---

## Maintenance

### Adding New Issues

New issues are auto-added via the auto-add workflow. Agent or automation sets initial Status to Proposed.

### Archiving

Items with Status = Done are auto-archived after 14 days. Archived items remain in the project but are hidden from views.

### Field Value Drift

If a field value conflicts with the issue body or labels, the body is authoritative (per ticket-information-architecture.md conflict resolution rules). Fix the field to match the body.

### Decision Date Backfill (Retroactive)

One-time + on-demand maintenance protocol for issues triaged before the B2a forcing-function enforcement. Identifies issues with Decision Date in the triage decision comment but missing the Projects Date field, and backfills the Projects field while preserving the comment as the canonical historical record.

**Source-of-truth precedence (canonical-preservation rule):** When backfilling, the comment-stated date is authoritative. The Projects Date field is being brought into alignment with the comment, not vice versa. The backfill never overwrites a Decision Date that is already set in the Projects field, and never edits the original triage decision comment.

**Detection query:**
```bash
# Issues with empty Projects Decision Date but plausible triage history
# (closed-Rejected/Deferred or open with status: approved/bundled)
gh project item-list 4 --owner [OPERATOR_GITHUB] --format json --limit 5000 \
  | jq -r '.items[]
      | select((."decision Date" == null) and (.content.number != null))
      | select(.content.state == "OPEN" or .content.state == "CLOSED")
      | .content.number'
```

For each candidate issue, the agent must parse comment history for a triage decision comment matching the standard header format and extract a `Decision Date: YYYY-MM-DD` value (or equivalent).

**Backfill procedure (per candidate issue):**

1. **Pre-condition check:** Re-query Projects API for the item. Confirm the `"decision Date"` JSON key is null. If already set, skip (idempotency guarantee).
2. **Parse Decision Date from comment(s):** Read issue comments via `gh issue view <N> --comments`. Identify the triage decision comment(s). Extract the Decision Date value. If multiple triage comments (re-triage), use the most recent.
3. **Validation:** Parsed date must match `^\d{4}-\d{2}-\d{2}$`. If unparseable, ambiguous, or absent → flag for operator review; do NOT guess or default to today's date.
4. **Conflict check:** If parsed comment date conflicts with any other comment-stated date in the same issue's history → flag for operator review; do NOT auto-resolve.
5. **Set Projects Date field:** `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id <ITEM_ID> --field-id [OPERATOR_PROJECTS_DATE_FIELD_ID] --date <PARSED_DATE>`
6. **Verify:** Re-query the Projects API; confirm the `"decision Date"` JSON key is now `<PARSED_DATE>`.
7. **Append backfill audit comment** to the issue:
   ```
   ## Decision Date Backfill (Retroactive)
   Backfilled Projects Decision Date field to <PARSED_DATE> from triage decision comment dated <COMMENT_DATE>.
   Source comment: <comment_url>
   Backfill protocol: github-projects-guide.md § Decision Date Backfill (Retroactive)
   ```
8. **Do NOT modify** the original triage decision comment.

**Idempotency:**
- Re-running on an issue with the field already set: pre-condition check (Step 1) fails → skip; no audit comment appended.
- Re-running on an issue with no triage decision comment: validation (Step 3) flags for operator; no Projects field write.
- The detection query returning zero candidates is a valid steady-state result post-enforcement.

**Operator invocation:** This is a maintenance protocol, not an automatic gate. Operator invokes on demand (typically once post-deployment to clear backlog, then on-demand if drift is detected). No scheduled triggering; no agent-initiated backfill without operator request.

**Coverage scope:**
- Closed issues (Rejected/Deferred) — eligible. Projects field is queryable-historical regardless of Status.
- Open issues (Approved/Bundled/In Progress) — eligible.
- Issues that never reached Triage (Proposed, no triage decision comment) — NOT eligible. They have no Decision Date by design; running the detection query against them is expected to skip.

### Project Limits (Free Plan)

| Resource | Limit |
|---|---|
| Items per project | 50,000 |
| Fields per project | 50 |
| Auto-add workflows | 1 |
| View types | Board, Table, Roadmap |

---

## Methodology Variation — Board Configuration

The Saved Views and field schema documented above serve the platform's core pipeline workflow — they are methodology-agnostic at the structural level. What varies per [Methodology](../specs/terminology-glossary.md#term-methodology) is the **recommended board view composition** and **column/field emphasis** for a given `delivery_approach`. The matrix below names the archetype-specific view that SHOULD supplement the 4 canonical Saved Views when PROJECT.md declares the matching archetype.

| Archetype | Variation | Applies to | Notes |
|---|---|---|---|
| **Scrum** | Add **Sprint Board** view grouped by Sprint field (if enabled) or Milestone; columns = Backlog / Sprint-Ready / In Progress / Review / Done. Add **Burndown** view (Projects Insights chart) tracking story points remaining per sprint. | §Saved Views, §Fields | [SOURCE] Scrum Guide 2020 sprint board. |
| **Kanban** | Add **Flow Board** view with WIP limits enforced per column (Backlog / Ready / In Progress / Review / Done); column-header displays WIP limit count. Add **Cycle-Time** view (cumulative-flow chart if Projects Insights is available) tracking flow metrics. | §Saved Views, §Fields | [SOURCE] Kanban Method — WIP-limited board. |
| **XP** | Inherit Scrum sprint-board view PLUS an **Engineering Health** view grouping by CI-status + pair-rotation label fields (if configured). Pair-rotation tracking via custom `pair` field or label. | §Saved Views, §Fields | [SOURCE] XP engineering-practice governance. |
| **Waterfall** | Add **Milestone Roadmap** view (use Roadmap view type) showing phases as time blocks; Gantt-style critical path visualization. Group by Phase field (if added) or Milestone. Add **Phase-Gate Log** view filtered to phase-gate review items. | §Saved Views, §Fields, §Roadmap | [SOURCE] PMBOK predictive visualization. |
| **PRINCE2** | Add **Management Stage** view grouped by Stage field (aligned to PRINCE2 management stages, NOT pipeline Stages 1-13) showing work packages per stage. Add **Highlight Reports** view filtered to `type: highlight-report` items. | §Saved Views, §Fields | [SOURCE] PRINCE2 2017 stage-boundary visualization. |
| **SAFe** | Add **PI Board** view grouped by PI field or Milestone (where Milestone = PI); feature-level swim lanes across multiple team/ART rows. Add **ART-Metrics** view (Insights chart) tracking predictability + program-velocity per PI. | §Saved Views, §Fields | [SOURCE] SAFe 6.0 PI Planning board. |
| **Hybrid** | Partition boards by phase: predictive-phase items use Milestone Roadmap view; iterative-phase items use Sprint Board or Flow Board. Add **Phase-Switch Marker** view to signal when a project transitions between predictive and iterative posture. | §Saved Views | [INFERRED] Composition of Waterfall + Scrum/Kanban board views. |
| **Custom** | See the `custom_methodology_definition` block in PROJECT.md; derive board composition from declared `lifecycle`, `ceremonies`, `artifacts`, `cadence` fields. Lifecycle drives view shape: continuous → Flow Board; phased → Milestone Roadmap; timeboxed → Sprint Board. Each declared artifact may warrant a dedicated view; Custom field names in Projects SHOULD mirror declared `artifacts` when board fidelity matters. | §Saved Views, §Fields | [SOURCE] [`methodology-parameterization-v1.md § Custom Extension Protocol`](../../release/references/specs/methodology-parameterization-v1.md). |

**Consumer guidance.** `release-executor` and `delivery-engine` read `delivery_approach` from PROJECT.md and parameterize their board-state updates against the archetype's recommended view composition. Board views documented in §Saved Views above are the pipeline baseline and remain applicable regardless of archetype — archetype-specific views SUPPLEMENT, not REPLACE, the pipeline baseline.
