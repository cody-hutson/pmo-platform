<!-- reference-durability: allow-link -->
# Ticket Information Architecture

Defines how GitHub Issues are structured, read, and written by agents across all 13 pipeline stages. This is the information model that ticket lifecycle, system configuration, field lifecycle, and I/O contracts implement against.

**Source issue:** Ticket-information-architecture spec

---

## Three-Layer Model

Every ticket carries information in three distinct layers. Each layer has a defined role, write rules, and read pattern.

| Layer | Mechanism | Role | Who Writes | Who Reads |
|---|---|---|---|---|
| **Source of Truth** | Issue body | Current authoritative state — structured fields, AC, dependencies, priority. Updated in-place when facts change. | Intake author (create), Triage/Planning agents (update fields), operator (corrections) | Every stage's agent. Read first. |
| **Stage Reviews** | Comments (single-pass) or sub-issues (multi-pass) | Per-stage analysis, findings, decisions, evidence. Append-only comments form immutable audit trail. Sub-issues enable iterative review with independent lifecycle. | Stage agents (Stages 2-13), operator (decisions) | Downstream stages for context. |
| **State Anchors** | Projects fields, labels, Milestones | Machine-readable pipeline position. Fields track state, labels categorize, Milestones assign releases. | Automated (on stage transition) or agent (at stage entry/exit) | Agents (routing), operator (visibility), automation (triggers) |

### Methodology Variation — Work Item Types

The Three-Layer Model above is methodology-agnostic at its structural level (Source of Truth / Stage Reviews / State Anchors invariant across archetypes). What varies by [Methodology](../../../core/specs/terminology-glossary.md#term-methodology) is the *semantics of the work item type* an Issue represents. Rows below cover archetypes where the work-item-type semantics diverge from the platform default; all other archetypes inherit the canonical Issue-as-GitHub-Issue model without modification.

| Archetype | Variation | Applies to | Notes |
|---|---|---|---|
| **Scrum** | Issue = **User Story** with story-point estimation. Body carries As-a/I-want/So-that framing; AC section maps to Scrum acceptance criteria. Stage 3 Bundle = Product Backlog grooming; Milestone = Sprint. | §Source of Truth, §State Anchors | [SOURCE] Scrum Guide 2020 — product backlog items. |
| **Kanban** | Issue = **Work Item / Card** pulled through board columns. No estimation field required; class-of-service (expedite / standard / fixed-date / intangible) may be tracked via a `class-of-service` label. Stage 3 Bundle is soft — cards enter/exit release based on WIP limits. | §State Anchors, [`label-taxonomy.md`](../../../core/specs/label-taxonomy.md) | [SOURCE] Kanban Method — class-of-service categorization. |
| **Waterfall** | Issue = **Task / Deliverable** tied to a WBS node. Body carries WBS path + phase assignment; priority maps to schedule criticality, not business value. Dependencies express phase-gate chains (Req → Design → Build → Test → Deploy). | §Source of Truth, §Dependencies | [SOURCE] PMBOK predictive-lifecycle work breakdown. |
| **SAFe** | Issue = **Feature** at Milestone=PI scale; sub-tasks = Stories within the Feature. Body carries PI objective linkage; Milestone = Program Increment (typically 8-12 weeks spanning multiple sprints). | §State Anchors, §Source of Truth | [SOURCE] SAFe 6.0 Feature + PI vocabulary. |
| **PRINCE2** | Issue = **Work Package** produced within a management Stage. Body carries Product Description (PRINCE2 "Products" = deliverables); dependency chains express stage-boundary authorization. Milestone = Management Stage. | §Source of Truth, §State Anchors | [SOURCE] PRINCE2 2017 — work package + product description. |
| **Custom** | See the `custom_methodology_definition` block in PROJECT.md; derive work-item-type semantics from declared `artifacts` list. Body structure, estimation, and dependency semantics follow the declared `lifecycle` pattern. | All sections | [SOURCE] [`methodology-parameterization-v1.md § Custom Extension Protocol`](methodology-parameterization-v1.md). |
| **All others (Kanban-variant, XP, Hybrid — inherit Three-Layer Model as-is)** | Issue-as-GitHub-Issue model applies without modification. Standard body schema + standard stage-review comments + standard state anchors. | §Three-Layer Model | [INFERRED] XP shares Scrum user-story semantics at the work-item layer; Hybrid inherits the layer matching the current stage's methodology posture. |

### Agent Read Pattern

1. **Read the body first** — this is the current authoritative state
2. **Read the last stage review** — for single-pass stages, the last comment with the matching stage header; for multi-pass stages, the last sub-issue
3. **Read state anchors** — Projects fields for pipeline position, labels for categorization
4. **Do not parse full comment history** unless performing a retrospective or audit

> **Note:** Stage reviews may appear as comments on the parent issue (target model for direct skill posting) or as comments on stage sub-tasks linked to the parent (current hub-spoke execution pattern). The Agent Read Pattern applies in both cases — locate the relevant stage's output by its structured header regardless of where it is posted.

---

## Source of Truth: Issue Body

The issue body is the single authoritative record of what this issue IS. It is structured by the `improvement.yml` template at Intake and updated in-place as facts change.

### Body Update Protocol

| Trigger | Update Type | Example |
|---|---|---|
| Field value changes | In-place field update | Priority P3 → P2 at Triage |
| New structured data | Section added or replaced | Gap summary with issue numbers added at definition |
| Stage finding changes requirements | AC updated + comment explaining why | Stage 8 drift → revised AC in body |
| Consolidation | Subsumption note added | Per subsumption convention |
| Dependency resolution | Dependencies field updated | Dependency closed → "Resolved" annotation |

### What Goes in the Body

- Priority, category, description, evidence, affected files, proposed change
- Dependencies and acceptance criteria
- Structured data sections (gap summaries, scope notes)
- Subsumption notes (per subsumption convention)

### What Does NOT Go in the Body

- Stage reviews — comments or sub-issues (immutable audit trail)
- Execution evidence — comments, linked to specific runs
- Discussion and back-and-forth — comments (conversation thread)
- Temporal observations — comments (timestamped naturally)

> **See also:** the Solutioning Pre-Read convention
> ([`solutioning-output-template.md` § 3.5](../standards/solutioning-output-template.md))
> relies on this rule — a Stage-5 advisory pre-read posted on the parent issue
> is a stage-review comment (non-binding context), never body content; the issue
> body stays the sole authoritative contract.

### Dependencies Field — Typed Schema (PMBOK CPM convention)

The body `### Dependencies` section supports typed dependency edges per the PMBOK CPM convention. Type prefix and offset are optional; untyped references default to `FS+0d` (finish-to-start, zero lag) and remain backward-compatible.

**Token grammar:**

```
DEPENDENCY ::= [TYPE_PREFIX][OFFSET] HASH_REF
TYPE_PREFIX ::= "FS" | "SS" | "FF" | "SF"           (optional; default "FS")
OFFSET      ::= ("+" | "-") INTEGER "d"             (optional; default "0d")
HASH_REF    ::= "#" INTEGER                          (required)
```

**Type semantics (PMBOK):**

| Prefix | Name | Meaning |
|---|---|---|
| `FS` | Finish-to-Start | Predecessor must finish before successor starts (default) |
| `SS` | Start-to-Start | Predecessor must start before successor starts |
| `FF` | Finish-to-Finish | Predecessor must finish before successor finishes |
| `SF` | Start-to-Finish | Predecessor must start before successor finishes |

**Offset semantics:**

| Form | Meaning |
|---|---|
| `+Nd` | Lead — predecessor finishes N days BEFORE successor starts (overlap allowed in successor) |
| `-Nd` | Lag — predecessor finishes N days; successor cannot start until N days later (gap between) |
| (omitted) | Zero lag — predecessor and successor are immediately adjacent |

**Examples:**

```markdown
### Dependencies
- #N              # default: FS+0d (finish-to-start, no lag)
- FS #N           # explicit FS, equivalent to above
- SS #N           # start-to-start
- FF #N           # finish-to-finish
- FS+3d #N        # FS with 3-day lead
- FS-2d #N        # FS with 2-day lag
- SS+1d #N        # SS with 1-day lead
```

**Parser semantics:**

- Untyped `#N` is normalized to `FS+0d #N` (backward-compatibility shim — existing untyped references continue to parse without modification)
- Typed `FS|SS|FF|SF[±Nd]` is captured as structured fields per dependency edge: `{type: "FS"|"SS"|"FF"|"SF", offset_days: integer, target: integer}`
- The canonical parser lives at `release/tools/bundle-issues-parser.py` and consumes the body `### Dependencies` section

**Consumers (read body Dependencies field):**

| Consumer | Use |
|---|---|
| Stage 2 G2-04 dependency validation | Validate every `#N` reference against compatible state (type prefix transparent to validation) |
| Stage 3 G3-04 / G3-07 / G3-08 gates | Read body; prefix transparent (validation operates on `#N` substring) |
| release-planner Bundle mode | `IssueRecord.dependencies` carries typed edges for dependency-graph construction |
| Critical-path / longest-chain algorithms | Consume full typed schema (FS/SS/FF/SF + lead/lag) for forward-pass / backward-pass calculations |

**Cutover:** The typed schema applies to all body `### Dependencies` content going forward. Untyped Dependencies fields continue to parse correctly through the backward-compatibility shim (handled as untyped FS+0d per default), so historical body deps need no migration.

---

## Stage Reviews

Each pipeline stage that produces analysis, findings, or decisions posts its output as either a **structured comment** (single-pass stages) or a **sub-issue** (multi-pass iterative stages). The mechanism depends on whether the stage iterates.

### Single-Pass Reviews (Structured Comments)

For stages that produce a single review output (Triage, Planning, Bundle, Solutioning, Plan Review), post a comment with a standardized header. Comments are append-only and never edited after posting — they form an immutable audit trail.

**Standard comment header format:**

```markdown
## Stage [N] [Name] — [Release Version]

### Summary (30 seconds)
[Verdict/score/key finding — operator reads this first]

### Detail
[Per-finding or per-criterion analysis]

### Evidence
[References to PR files, line numbers, specific checks]

### Output for Stage [N+1]
[Explicitly: what the next stage receives from this review]
```

**Tiered presentation:** Summary → Detail → Evidence → Handoff. Respects the operator's cognitive load — read the summary to decide whether to dig deeper.

### Multi-Pass Reviews (Sub-Issues)

For stages that iterate through multiple review passes (Dev Testing, QA Testing), each pass is a **sub-issue** of the parent issue being reviewed. Sub-issues provide:

- **Own body** — the review findings are the sub-issue's source of truth, not a comment
- **Independent lifecycle** — open = in progress, closed = pass complete
- **Linkage** — parent issue's sub-issue list shows progress across passes
- **Discussion** — comments on the sub-issue for back-and-forth within that pass

**Sub-issue naming convention:**

```
Stage [N] [Name] — [Version] Pass [M]
```

Examples:
- `Stage 7 Dev Testing — v1.03 Pass 1`
- `Stage 7 Dev Testing — v1.03 Pass 2`

**Sub-issue body follows the same tiered format** as single-pass comments (Summary → Detail → Evidence → Output for Stage N+1).

**Revision handling:** When engineering responds to a review pass (code changes, explanations), they comment on the pass's sub-issue. The next pass is a new sub-issue, not a comment on the previous one.

| Action | Mechanism | Example |
|---|---|---|
| Initial review | Create sub-issue (Pass 1) | Agent creates `Stage 7 Dev Testing — v1.03 Pass 1` |
| Engineer responds | Comment on Pass 1 sub-issue | Engineer explains changes, links commit |
| Re-review | Create sub-issue (Pass 2) | Agent creates `Stage 7 Dev Testing — v1.03 Pass 2` |
| Final verdict | Last sub-issue body | Downstream reads the last pass's body |

**Authoritative pass rule:** The last sub-issue from a given stage is the authoritative output. Earlier passes are history. An agent finds the latest by reading the parent's sub-issue list in reverse.

### When to Use Which

| Condition | Mechanism | Examples |
|---|---|---|
| Stage produces one output | Structured comment | Triage, Planning, Bundle, Solutioning |
| Stage may iterate | Sub-issues per pass | Dev Testing, QA Testing |
| Operator renders a decision | Structured comment | Plan Review (Stage 9) decision record |
| Lightweight discussion | Comment on issue or sub-issue | Any stage, within-pass back-and-forth |

---

## State Anchors

State anchors are machine-readable metadata that indicate where an issue sits in the pipeline. They are **derived from** the source of truth (body) and stage reviews — they do not replace them.

State anchors use three distinct GitHub mechanisms, each with a defined role. Mixing mechanisms (e.g., using labels for pipeline state) creates ambiguity and breaks automation.

### Pipeline State (GitHub Projects Fields)

Projects single-select fields track an issue's pipeline position. These are the primary mechanism for automation, filtering, and dashboard views.

| Field | Type | Valid Values | Set By | Updated At |
|---|---|---|---|---|
| **Status** | Single-select | Proposed, Approved, Bundled, In Progress, Done | Agent or automation | Stage transitions (gate pass) |
| **Stage** | Single-select | 1-Intake, 2-Triage, 3-Bundle, 4-Planning, 5-Solutioning, 6-Engineering, 7-DevTest, 8-QA, 9-PlanReview, 12-Execute, 13-Close | Agent | Stage entry |

**Status transitions (valid):**

```
Proposed → Approved → Bundled → In Progress → Done
   ↘    ↘ Rejected (terminal — issue closed)        ↓
   ↘    ↘ Deferred (open, Milestone removed)    Proposed (reopened, T6)
              ↓
           re-triage → Proposed or Approved
```

The Triage stage produces three terminal verdicts via labels:
- **Approved** → `status: approved` applied; issue advances to Bundle (becomes `status: bundled`).
- **Deferred** → `status: deferred` applied; Milestone removed; issue stays OPEN. Re-triage required before re-bundling (returns to `status: proposed` for full re-evaluation, or `status: approved` if priority/scope unchanged).
- **Rejected** → `status: rejected` applied; issue CLOSED with reason `not planned`. Terminal unless reopened (T6).

Invalid transitions (e.g., Proposed → Done, Bundled → Proposed) indicate a process violation. Agents should flag, not execute.

**Stage field** tracks current pipeline position independently of status. An issue can be Status:In Progress and Stage:7-DevTest. Stage advances linearly; status may not (e.g., Deferred issues return to Approved, not Proposed).

### Categorization (Labels)

Labels classify issues by type and area. They are **static after assignment** and are not used for pipeline state tracking.

| Label Category | Examples | Set At | Mutability |
|---|---|---|---|
| **Type** | `improvement`, `protocol`, `skill-update`, `structure`, `documentation`, `enhancement` | Intake (template auto-label) | Rarely changed — only at Triage if mis-categorized |
| **Area/Cluster** | `cluster:pipeline-definitions`, `cluster:eval-quality`, `cluster:system-config` | Triage (Run-1) | Static after assignment |
| **Lifecycle** | `duplicate`, `wontfix` | Triage or consolidation | One-time application |

### Release Assignment (Milestones)

Milestones assign issues to versioned releases. Set at Stage 3 (Bundle).

| Mechanism | Example | Set By | Updated At |
|---|---|---|---|
| **Milestone** | `v1.03`, `v2.0` | Release Manager agent or operator | Stage 3 (Bundle), modified if re-scoped |

### Conflict Resolution

**Body fields are authoritative.** When a state anchor conflicts with the issue body, the body wins.

| Conflict | Resolution |
|---|---|
| Body says P2, label implies P3 | Update the label to match body |
| Projects field says "Done" but body AC not met | Revert field to previous state, investigate |
| Milestone says v1.03 but body Dependencies not met | Flag to operator — do not auto-resolve |
| Body cites `FS+0d #X`, native `blocked-by` missing `#X` | Auto-resolve — agent calls GraphQL `addIssueDependency` to add `#X` to native (body wins). No operator action required. Per § Native Dependencies. |
| Native has `blocked-by: #Y`, body Dependencies field does NOT cite `#Y` | Flag drift to operator — do NOT auto-modify body (body remains authoritative). Operator decides: (a) add `#Y` to body if intended, (b) remove from native if the UI edit was inadvertent. Per § Native Dependencies. |
| Body cites typed non-FS-zero-lag dep (`SS #Z`, `FS+3d #W`, etc.) NOT in native | No action — non-FS-zero-lag types are body-only by design (native API lacks expressivity for these). Informational; not a conflict. Per § Native Dependencies. |

### Transition Contract

This section defines the contract that PT-4 (Label/Status Rationalization) implements. The values and transitions above are the architecture; PT-4 deploys them as actual GitHub Projects fields, labels, and automation rules.

---

## Native Dependencies

**Source:** Native Dependencies spec — Stage 5 design.

GitHub Issue Dependencies (GA Aug 2025, 50-per-issue cap; upstream API catalogued in [`upstream-reference-catalog.md` entry `github-issue-dependencies`](../../../core/standards/upstream-reference-catalog.md)) provide native `blocks` / `blocked-by` relationships visible on project boards. The PMO platform adopts native dependencies as a **projected display surface** — body Dependencies field remains authoritative; native is a one-way mirror of the expressible subset.

### Adoption Model (Model A — body→native one-way mirror)

**Direction:** body → native, one-way.
**Authoritative source:** Body Dependencies field. Native is canonical for nothing — it's a projected display surface. Operator UI edits to native are observable but not authoritative.

**Mirror subset rules:**

| Body dep type | Mirrored to native? | Native side | Rationale |
|---|---|---|---|
| `FS+0d #N` (default / untyped) | YES | `blocked-by: #N` on this issue; `blocks: #current` on `#N` | Native supports the simple "blocks" semantic verbatim |
| `FS±Nd #N` (FS with lead/lag) | NO | — | Native lacks lead/lag expressivity; offset would be lost |
| `SS #N`, `FF #N`, `SF #N` | NO | — | Native `blocks`/`blocked-by` has only one semantic; non-FS types not representable |

The 50-per-issue native cap is non-binding at current scale (largest observed dep set ~10 per issue). Future re-evaluation if any issue approaches the cap.

### Reframed AC#4 (per Stage 5 design — operator-rendered ACCEPT at Collective Review 2026-05-22)

The native-dependency adoption respects this acceptance principle:

> **AC#4 (reframed):** Operator and agent intent stays **observable**. Body edits propagate to native within the mirror's expressive subset (`FS+0d`). Native edits surface as drift findings for operator-mediated reconciliation. Body remains authoritative; native is a projected display surface.

This reframes the original literal AC#4 ("intent stays in sync regardless of which surface is edited first") because literal bidirectional auto-sync would invert body-as-authority (§ Conflict Resolution, "Body fields are authoritative"). The reframe preserves the invariant by replacing literal bidirectional sync with one-way mirror + drift-detection. Operator-rendered ACCEPT at the Collective Review per the D-AC#4 decision record.

### Mirror Trigger Points

| Stage | Trigger | Action |
|---|---|---|
| 2 (Triage) | After G2-04 dependency validation passes (Phase A) | Substep **A3.5 native-mirror** — for each body `FS+0d #N`, call GraphQL `addIssueDependency`; for each existing native dep not in body, flag drift |
| 5 (Solutioning) | If a spoke refines body Dependencies field as part of AC refinement | Re-trigger A3.5 mirror logic |
| 6 (Engineering) | Parent issue decomposed into sub-tasks with sub-task-to-sub-task `FS+0d` body deps | Sub-task native deps populated via mirror |
| 13 (Close) | QC4 verification (parity-check) | Re-run mirror as parity-check; report drift findings in Verification Evidence |

### Mirror Algorithm (Stage 2 A3.5)

```text
FUNCTION mirror_body_to_native(issue_number):
  # 1. Read body Dependencies field
  body_deps = parse_body_dependencies(issue_number)  # returns List[{type, offset_days, target}]

  # 2. Filter to mirror-eligible subset (FS + zero offset)
  mirror_eligible = filter(body_deps, lambda d: d.type == "FS" AND d.offset_days == 0)

  # 3. Read native deps
  native_blocked_by = read_native_blocked_by(issue_number)  # GraphQL

  # 4. Compute diff
  to_add = mirror_eligible - native_blocked_by  # body has, native lacks
  drift  = native_blocked_by - mirror_eligible  # native has, body lacks

  # 5. Add missing (body wins)
  FOR target IN to_add:
    addIssueDependency(blocked_issue=issue_number, blocking_issue=target)

  # 6. Surface drift (body remains authoritative; no auto-modify)
  FOR target IN drift:
    flag_drift_to_operator(issue=issue_number, native_extra=target)
```

The algorithm is **idempotent** — re-running with the same body state produces the same native state (modulo the API's eventual consistency window).

### Drift Detection (Check 21 in `deploy.sh --check`)

`deploy.sh --check` Check 21 performs a workspace-wide drift-detection pass (per the canonical numbering — Stage 5 design referenced "Check 19" but Checks 19 and 20 were already in place; numbering reconciled at Stage 6):

1. Reads every open issue's body Dependencies field; parses typed schema; computes expected `FS+0d` native-mirror set
2. Reads native dependencies via GraphQL per issue (paginated; honors 50-cap)
3. Computes diff: body→native missing entries (auto-resolvable at next Stage 2 trigger), native→body orphans (drift flag for operator)
4. Initial posture: **warn-mode** (per [`bypass-mode-readiness.md`](../../../core/rules/bypass-mode-readiness.md) Shakedown → Enforce Transition Checklist precedent); logs to `core/hooks/deploy-check-warn-log.jsonl` via the standard `flag_warn_or_issue` helper
5. Flip-to-enforce: operator-driven after 2-3 release shakedown (matches Check 14/15/18 precedent)

### Native API — Token Scope + Invocation Pattern

Native dependency mutations require GraphQL `addIssueDependency` / `removeIssueDependency`. Token scope `repo` is sufficient for most operations; project-scoped semantics may require `gh auth refresh -s project` per the [`upstream-reference-catalog.md` entry `github-issue-dependencies`](../../../core/standards/upstream-reference-catalog.md).

Invocation pattern via `gh`:

```bash
# Add native dep — issue #N is blocked by issue #M
gh api graphql -f query='
  mutation($blocked: ID!, $blocking: ID!) {
    addIssueDependency(input: {issueId: $blocked, blockingIssueId: $blocking}) {
      issue { id }
    }
  }' -F blocked="$BLOCKED_ID" -F blocking="$BLOCKING_ID"
```

Issue node IDs are resolved via `gh api graphql -f query='{ repository(owner: "{OWNER}", name: "{REPO_NAME}") { issue(number: <N>) { id } } }'` (where `{OWNER}/{REPO_NAME}` is the operator's fork of `{REPO}`).

### Cap Handling

When `addIssueDependency` returns a "dependency cap reached" error (issue has 50 native blocked-by entries):

- Flag to operator
- Suspend further native mirroring for that issue until operator resolves
- Body remains authoritative without native projection — degraded display only, not loss of dependency information

### Cutover (Reflexive-Pipeline-Loop Discipline)

**Applies to:** all issues entering Stage 2 (Triage) going forward. The typed-schema parser remains backward-compatible (untyped `#N` parsing unchanged), so historical body deps continue to parse without modification and native mirror is not invoked retroactively for them.

**Drift-check Check 21:** Applies to drift detections on all issues going forward. Issues whose body legitimately lacks a native mirror (e.g., untyped historical deps) are not flagged as defects.

### Cross-References

| Surface | Reference | Role |
|---|---|---|
| Stage 2 substep | [`pipeline/stage-02-triage.md`](../pipeline/stage-02-triage.md) § Phase A | A3.5 native-mirror substep — fires after G2-04 |
| Drift check | [`deploy.sh`](../../../core/deploy/deploy.sh) Check 21 | Workspace-wide body↔native drift detection |
| Upstream catalog entry | [`upstream-reference-catalog.md` entry `github-issue-dependencies`](../../../core/standards/upstream-reference-catalog.md) | Native API codification |
| Conflict resolution | § State Anchors → Conflict Resolution above | 3-row drift handling matrix |
| Agent write permissions | § Agent Write Permissions below | Native Deps column |
| GitHub feature strategy | [`github-feature-strategy.md`](../../../core/disciplines/github-feature-strategy.md) Entry 7 | "Adopt per Model A" |

---

## Agent Write Permissions

Each pipeline stage's agent has explicitly defined write permissions. This follows the "safe-outputs" pattern — agents get broad read access but can only write through declared channels.

| Stage | Body Updates | Comments | Sub-Issues | Labels | Projects Fields | Native Deps | Operator Approval Required |
|---|---|---|---|---|---|---|---|
| 1 (Intake) | Create issue | — | — | `improvement` (auto) | status: Proposed | — | No |
| 2 (Triage) | Priority, category | Decision comment | — | Category label applied (from body Category dropdown per `improvement.yml`, or fallback to `improvement` if no specific category fits) | status: Approved/Rejected/Deferred | Mirror body `FS+0d #N` deps to native `blocked-by` via A3.5 substep (per § Native Dependencies) | Decision (Tier 3) |
| 3 (Bundle) | — | Bundle rationale comment | — | — | status: Bundled; Milestone assignment | — | Scope approval (Tier 3) |
| 4 (Planning) | — | Plan reference comment | — | — | stage: 4-Planning | — | No |
| 5 (Solutioning) | AC refinement (if needed) | Design review comment | — | — | stage: 5-Solutioning | Re-trigger mirror logic if AC refinement touches Dependencies field (conditional) | Design decisions (Tier 3) |
| 6 (Engineering) | — | — | Create sub-tasks | — | stage: 6-Engineering, status: In Progress | Populate sub-task native deps when parent is decomposed into sub-tasks with native-meaningful (`FS+0d`) edges | Decomposition checkpoint |
| 7 (Dev Testing) | — | — | Create review pass sub-issues | — | stage: 7-DevTest | — | No |
| 8 (QA Testing) | — | — | Create review pass sub-issues | — | stage: 8-QA | — | Acceptance (Tier 3) |
| 9 (Plan Review) | — | Decision record comment | — | — | stage: 9-PlanReview | — | Go/No-Go (Tier 3) |
| 12 (Execute) | — | Deployment log comment | — | — | stage: 12-Execute | — | Authorization (Tier 3) |
| 13 (Close) | — | Verification evidence comment | — | — | status: Done, stage: 13-Close | Re-run drift-check as QC4 verification parity-check (per § Native Dependencies) | No |

> **Note:** Stages 10 and 11 are compressed into the git workflow (per release-process.md) and have no independent agent write permissions.

**Read permissions:** All stages have full read access to all layers (body, comments, sub-issues, labels, fields).

**Operator approval column** maps to the automation tier from pipeline/: Tier 1 (Auto) = No, Tier 2 (Recommend) = varies, Tier 3 (Human-only) = Yes.

**Field update sequencing:** The Ticket Lifecycle Protocol (below) defines the exact order and timing of Projects field updates at each stage transition. The permissions in this table define WHAT each stage can write; the lifecycle protocol defines WHEN and HOW.

---

## Ticket Lifecycle Protocol

Defines when and how agents update ticket state before, during, and after work at every pipeline stage. This protocol operationalizes the write permissions above and the state anchor model.

**Source issue:** Ticket lifecycle / write-discipline spec

### Claim-Execute-Resolve (CER) Pattern

Every pipeline stage follows a three-phase protocol when operating on a ticket:

```
┌─────────────────────────────────────────────────────────┐
│                    CLAIM PHASE                          │
│  1. Read issue body (source of truth)                   │
│  2. Read last stage review (context)                    │
│  3. Validate entry gate (status/stage prerequisites)    │
│  4. Update state anchors → stage entry state            │
│     - Status label (if status changes)                  │
│     - Projects Status field (if status changes)         │
│     - Projects Stage field (always — new stage)         │
│  5. Post "Stage N started" marker (optional, for long   │
│     stages like Engineering)                            │
├─────────────────────────────────────────────────────────┤
│                   EXECUTE PHASE                         │
│  6. Perform stage work (analysis, implementation, etc.) │
│  7. Create sub-issues if multi-pass (DT, QA)            │
│  8. Track progress via sub-issue lifecycle               │
├─────────────────────────────────────────────────────────┤
│                   RESOLVE PHASE                         │
│  9. Post stage review comment/sub-issue                 │
│ 10. Update body fields if changed (AC, priority, etc.)  │
│ 11. Update state anchors → stage exit state              │
│     - Status label (if status changes at this gate)     │
│     - Projects Status field (if status changes)         │
│     - Projects Stage field (remains — next stage claims)│
│ 12. Verify state anchor consistency                     │
└─────────────────────────────────────────────────────────┘
```

### Transition Table

Six status transitions and twelve stage transitions define the complete pipeline lifecycle.

| Transition Point | Status Change | Stage Change | Label Update | Projects Status | Projects Stage | Mechanism | Actor |
|---|---|---|---|---|---|---|---|
| **T1: Intake → Triage** | Proposed (set) | 1-Intake → 2-Triage | `status: proposed` applied | Proposed (automation: item added) | 1-Intake (agent) → 2-Triage (agent) | Automation (Status) + Agent (Stage) | Intake automation + Triage agent |
| **T2: Triage → Bundle** | Proposed → Approved | 2-Triage → 3-Bundle | `status: proposed` → `status: approved` | Proposed → Approved | 2-Triage → 3-Bundle | Agent (atomic sync) | Triage agent (approval) + Bundle agent (entry) |
| **T3: Bundle → Planning** | Approved → Bundled | 3-Bundle → 4-Planning | `status: approved` → `status: bundled` | Approved → Bundled | 3-Bundle → 4-Planning | Agent (atomic sync) | Bundle agent (bundled) + Planning agent (entry) |
| **T4: Planning → Engineering** | Bundled → In Progress | 4-Planning → 5/6-* | `status: bundled` → `status: in-progress` | Bundled → In Progress | Advances through 5/6 | Agent (atomic sync) | Stage entry agent |
| **T5: Close** | In Progress → Done | *-current → 13-Close | `status: in-progress` → `status: done` | In Progress → Done (automation: close/merge) | 13-Close (agent) | Automation (Status on close/merge) + Agent (Stage) | Close agent + GitHub automation |
| **T6: Reopen** | Done → Proposed | 13-Close → 2-Triage | `status: done` → `status: proposed` | Done → Proposed (automation: reopen) | Retains last value → 2-Triage (agent) | Automation (Status) + Agent (Stage + Label) | GitHub automation + Triage agent |

> **T6 transient inconsistency:** When an issue is reopened, GitHub automation resets Status → Proposed immediately, but the Stage field retains its last value (e.g., 13-Close). This creates a brief Status-Stage mismatch. The CER pattern self-corrects: when the Triage agent claims the reopened issue, it sets Stage → 2-Triage as part of the standard Claim phase (step 4), restoring consistency.

**Transition ownership rules:**
- **Status transitions at gates:** The agent that PASSES the gate updates the status. Triage agent sets Approved (not Bundle agent). This ensures the decision-maker records the state change.
- **Stage transitions at entry:** The agent that ENTERS a stage sets its own Stage field. This is a "claim" operation — the agent declares it is now working in this stage.
- **Exception — bookend automations:** GitHub built-in automations handle add→Proposed and close/merge→Done for the Status field. Agents still set the Stage field at these boundaries.

### Per-Stage Protocol Detail

**Stage 1 (Intake):**
- Claim: N/A (issue creation IS the claim)
- Execute: Issue created via template with all required fields
- Resolve: Automation sets Status→Proposed. Agent sets Stage→1-Intake. Label `status: proposed` applied. Label `improvement` (or category) auto-applied.

**Stage 2 (Triage):**
- Claim: Agent reads body, validates Status=Proposed. Sets Stage→2-Triage.
- Execute: Completeness check, duplicate detection, priority validation, feasibility assessment.
- Resolve: Agent posts triage decision comment, then renders one of three terminal verdicts via labels:
  - **Approve:** sets `status: approved` label (removes `status: proposed`), Status→Approved. Cluster label applied. Issue advances to Bundle.
  - **Defer:** sets `status: deferred` label (removes `status: proposed`), removes Milestone assignment if any, leaves issue OPEN. Cluster label applied. Re-triage required for re-bundling.
  - **Reject:** sets `status: rejected` label (removes `status: proposed`), closes issue with reason `not planned`. Cluster label applied. Terminal unless reopened (T6).

**Stage 3 (Bundle):**
- Claim: Agent reads body, validates Status=Approved. Sets Stage→3-Bundle.
- Execute: Dependency analysis, capacity assessment, scope evaluation, Milestone assignment.
- Resolve: Agent posts bundle rationale comment. Sets `status: bundled` label, Status→Bundled. Milestone assigned.

**Stage 4 (Planning):**
- Claim: Agent reads body, validates Status=Bundled and Milestone assigned. Sets Stage→4-Planning.
- Execute: Release plan creation — sequencing, file change matrix, risk register.
- Resolve: Agent posts plan reference comment. Release plan committed to branch. Stage remains 4-Planning (no status change — still Bundled until Engineering starts).

**Stage 5 (Solutioning):**
- Claim: Agent reads body, validates Stage>=4-Planning. Sets Stage→5-Solutioning.
- Execute: Design analysis, blast radius, ADR drafting. ADR issues created with `adr` label.
- Resolve: Agent posts design review comment. AC refined in body if needed. ADRs closed when accepted. Stage remains 5-Solutioning (no status change).

**Stage 6 (Engineering):**
- Claim: Agent reads body + plan + design specs. Validates dependencies met. Sets Stage→6-Engineering. **Sets Status→In Progress** (this is the Bundled→In Progress transition). Sets `status: in-progress` label.
- Execute: Sub-task decomposition (sub-issues created, start as Proposed via auto-add — see [Sub-Issue Projects Field Management](../../../core/disciplines/github-projects-guide.md#sub-issue-projects-field-management)). Implementation per plan. PR assembly.
- Resolve: Agent posts implementation summary. PR created with full metadata. Sub-tasks closed as completed. Stage remains 6-Engineering.

**Stage 7 (Dev Testing):**
- Claim: Agent reads PR, plan, Engineering evidence. Sets Stage→7-DevTest.
- Execute: Quality review. Creates review pass sub-issues if iterating.
- Resolve: Agent posts quality review (final pass sub-issue). No status change.

**Stage 8 (QA Testing):**
- Claim: Agent reads PR + DT results. Sets Stage→8-QA.
- Execute: Acceptance validation. Creates review pass sub-issues if iterating.
- Resolve: Agent posts QA results (final pass sub-issue). Acceptance decision rendered. No status change.

**Stage 9 (Plan Review):**
- Claim: Operator reviews PR diff. Sets Stage→9-PlanReview.
- Execute: Go/No-Go decision.
- Resolve: Operator posts decision record comment. No status change (In Progress until Execute).

**Stage 12 (Execute):**
- Claim: Agent validates Go decision. Sets Stage→12-Execute.
- Execute: Merge PR, tag release, deploy files (S-2 copy for skills).
- Resolve: **Automation sets Status→Done on PR merge.** Agent sets `status: done` label. Agent posts deployment log comment. Verification evidence appended. **Agent explicitly closes remaining open sub-issues** (sub-issues do not auto-close via PR `Closes #N`).

**Stage 13 (Close):**
- Claim: Agent validates deployment complete. Sets Stage→13-Close.
- Execute: Update RELEASE_LOG.md, close Milestone, verify production state.
- Resolve: Agent posts verification evidence comment. Issues auto-closed via PR `Closes #N`. Milestone closed. **Agent explicitly closes any remaining open sub-issues.**

### State Anchor Sync Pattern

When an agent updates state anchors at a transition point, it executes this sequence atomically:

```
FUNCTION sync_state_anchors(issue_number, new_status?, new_stage):
  # 1. Get item ID from project
  item_id = gh project item-list 4 --owner {OWNER} --format json
            | filter by issue number

  # 2. Update label (if status changing)
  IF new_status:
    old_label = "status: {current_status}"
    new_label = "status: {new_status}"
    gh issue edit {issue_number} --remove-label "{old_label}" --add-label "{new_label}"

  # 3. Update Projects Status field (if status changing AND not automation-handled)
  IF new_status AND transition NOT IN [add→Proposed, close→Done, merge→Done, reopen→Proposed]:
    gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] \
      --id {item_id} \
      --field-id [OPERATOR_PROJECTS_STATUS_FIELD_ID] \
      --single-select-option-id {status_option_id}

  # 4. Update Projects Stage field (always)
  gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] \
    --id {item_id} \
    --field-id [OPERATOR_PROJECTS_STAGE_FIELD_ID] \
    --single-select-option-id {stage_option_id}

  # 4.5. Update Decision Date (only at triage transitions)
  IF new_status IN [Approved] OR action IN [close_rejected, close_deferred]:
    gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] \
      --id {item_id} \
      --field-id [OPERATOR_PROJECTS_DATE_FIELD_ID] \
      --date {TODAY_YYYY-MM-DD}

  # 5. Verify consistency (read back and check)
  # Body status matches label matches Projects Status field
```

This pattern is **idempotent** — running it twice with the same arguments produces the same state. Safe for session recovery. Field IDs reference the PMO Pipeline project (see [github-projects-guide.md](../../../core/disciplines/github-projects-guide.md) for option IDs per status/stage value).

#### Invariant Enforcement (`deploy.sh --check` Check 16)

State Anchor Sync drift is detected at session-boundary by `core/deploy/deploy.sh --check` Check 16, which asserts 4 atomic invariants on open `improvement` issues:

| Invariant | Rule | Failure message |
|---|---|---|
| **I1 mutex** | At most one `status: *` label per issue | `issue #N has >1 status:* label` |
| **I2 presence** | At least one `status: *` label per issue | `issue #N missing all status:* labels` |
| **I3 contradiction-A** | `status: proposed` is incompatible with milestone set | `issue #N is status: proposed but milestone is set` |
| **I4 contradiction-B** | `status: bundled` is incompatible with milestone unset | `issue #N is status: bundled but no milestone` |

Check 16 is status-label vocabulary-agnostic (`startswith("status: ")`) — any present or future `status:` label values participate automatically. Ships in warn-mode (`core/hooks/deploy-check.mode`) for ≥3-day shakedown per [bypass-mode-readiness.md § Shakedown → Enforce Transition Checklist](../../../core/rules/bypass-mode-readiness.md). Legitimate exceptions register in `core/config/allowlists/status-label-invariant-exemption-list.txt` per the "No ungoverned changes" protocol.

### Mechanism Selection Matrix

| Update | Mechanism | CLI Command | When |
|---|---|---|---|
| Status label change | Agent label swap | `gh issue edit N --add-label "status: X" --remove-label "status: Y"` | At status transitions (T1-T5) |
| Projects Status field | Agent field edit OR automation | `gh project item-edit --project-id ... --field-id [OPERATOR_PROJECTS_STATUS_FIELD_ID] --single-select-option-id OPT` | At status transitions. Automation handles add→Proposed and close/merge→Done. |
| Projects Stage field | Agent field edit (always) | `gh project item-edit --project-id ... --field-id [OPERATOR_PROJECTS_STAGE_FIELD_ID] --single-select-option-id OPT` | At stage entry (Claim phase) |
| Projects Priority field | Agent field edit | `gh project item-edit --project-id ... --field-id [OPERATOR_PROJECTS_VIEW_FIELD_ID] --single-select-option-id OPT` | At Triage (Stage 2) when body priority confirmed |
| Milestone assignment | Agent | `gh issue edit N --milestone "vX.Y"` | At Bundle (Stage 3) |
| Body field update | Agent | `gh issue edit N --body "..."` or GraphQL | When facts change (Triage priority, Solutioning AC) |
| Decision Date field | Agent field edit | `gh project item-edit --project-id ... --field-id [OPERATOR_PROJECTS_DATE_FIELD_ID] --date YYYY-MM-DD` | At Triage decision (Approve, Reject, Defer) |

### Automation vs. Agent Responsibility

| Transition | Status Field | Stage Field | Label | Decision Date |
|---|---|---|---|---|
| Item added to project | **Automation** → Proposed | Agent → 1-Intake | Agent → `status: proposed` | — |
| Triage approves | **Agent** → Approved | Agent → 2-Triage | Agent → `status: approved` | **Agent** → today's date |
| Triage rejects (close) | **Automation** → Done (on close, reason `not planned`) | Stays at 2-Triage | Agent → `status: rejected` (removes `status: proposed`) | **Agent** → today's date (before close) |
| Triage defers | Stays at Proposed (no field change — issue stays OPEN) | Stays at 2-Triage | Agent → `status: deferred` (removes `status: proposed`); Milestone removed | **Agent** → today's date |
| Bundle assigns | **Agent** → Bundled | Agent → 3-Bundle | Agent → `status: bundled` | No change (locked) |
| Engineering starts | **Agent** → In Progress | Agent → 6-Engineering | Agent → `status: in-progress` | No change (locked) |
| PR merged / issue closed | **Automation** → Done | Agent → 13-Close | Agent → `status: done` | No change (locked) |
| Issue reopened | **Automation** → Proposed | Agent reassesses | Agent → `status: proposed` | No change (locked) |
| Stage advances (4→5→6→...→12) | No change (stays In Progress) | **Agent** → next stage | No change | No change (locked) |

Key insight: **Automations own the bookends (Proposed, Done). Agents own everything in between.** Stage field is ALWAYS agent-driven — no automation touches it.

### Sub-Issue Lifecycle Rules

| Event | Parent Issue | Sub-Issue |
|---|---|---|
| Sub-task created (Engineering) | Remains open, In Progress | Created open. Inherits parent's Milestone. Gets `sub-task` label. |
| Sub-task completed | Remains open | Closed. Body updated with outcome. |
| All sub-tasks completed | Ready for next stage | N/A |
| Stage review pass created (DT/QA) | Remains open | Created as sub-issue with pass naming convention. |
| Review pass complete | Remains open | Closed. Last pass is authoritative. |
| PR merged | **Automation closes** (via `Closes #N`) | **Must be explicitly closed by agent** — sub-issues do NOT auto-close via PR `Closes #N`. Stage 12/13 agent responsibility. |
| Parent closed | Auto-closed by GitHub (if sub-issue) | Auto-closed by GitHub (if sub-issue) |

### Session Recovery Protocol

If a session terminates mid-stage:

1. **Next session reads state anchors** — Stage field tells you where the issue was
2. **Read last comment** — determines how far the stage progressed
3. **Resume from last checkpoint** — the CER pattern means either Claim completed (state anchors updated) or it didn't (state anchors still at prior stage)
4. **No cleanup needed** — idempotent transitions mean re-running Claim is safe

### Execution-Model Agnosticism

The protocol works identically for hub-spoke (current), skill-based (future), or hybrid execution. CER defines WHAT happens at each transition, not WHO executes it. The "agent" in the transition table is whichever entity (spoke, skill, operator) is responsible for that stage.

**Field lifecycle per stage:** For field-level lifecycle details — which fields are created, required, updated, or locked at each pipeline stage — see [field-lifecycle-matrix.md](../../../core/schemas/field-lifecycle-matrix.md).

---

## Cross-Reference: Stage Integration

Each stage definition (in `pipeline/`) should reference this architecture in its Process and Outputs sections:

- **Inputs:** "Read issue body (source of truth) and last Stage N-1 review (comment or sub-issue)"
- **Process:** "Post Stage N review using [comment/sub-issue] per ticket architecture"
- **Outputs:** "Stage review posted. State anchors updated (status/stage fields)."
- **Gate:** "Projects fields reflect post-gate status"

---

## Design Principles

1. **Body = current truth, reviews = history.** The body is always up-to-date. Comments and sub-issues are append-only.
2. **Structured headers enable parsing.** Agents find what they need by header pattern, not by reading everything.
3. **Last review wins.** For iterative stages, the last sub-issue is authoritative. For single-pass stages, the last matching comment.
4. **State anchors are derived, not primary.** They reflect what the body and reviews say — they don't replace them.
5. **Cognitive load managed.** The tiered format (summary → detail → evidence) respects the operator's attention budget.
6. **Single canonical location per data point.** Each piece of information has exactly one authoritative location. Derived copies (labels mirroring body priority) are secondary — on conflict, the canonical location wins.
7. **Labels categorize, fields track state.** Labels are for classification (type, area, cluster). Projects fields are for pipeline position (status, stage). Never use labels for pipeline state.
8. **CER protocol at every stage.** Every pipeline stage follows Claim (validate prerequisites, update state anchors to entry state), Execute (perform stage work), Resolve (post review, update state anchors to exit state). No stage skips Claim or Resolve — even if Execute is trivial.
