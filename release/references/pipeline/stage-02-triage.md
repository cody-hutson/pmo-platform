# Stage 2: Triage

> **Source:** Stage 2 originating spec
> **Part of:** [13-stage pipeline](README.md) — [Process layer](../../../core/disciplines/execution-framework.md) of governance hierarchy.

<!-- reference-durability: allow-link -->
<!-- Navigational pipeline shard carrying many pre-existing intra-repo cross-reference links;
     retained (not summarized inline) per operator decision, consistent with the sibling
     de-reference-pass entries in core/hooks/reference-durability-allowlist.txt. Scopes only
     the markdown-link gate for this file; the other reference-durability gates stay active. -->

## 1. Purpose
Classify, validate, and prioritize each Proposed improvement so the operator can render an Approved/Rejected/Deferred decision with minimum friction and full traceability.

## 2. Reference Model Alignment

| Ref Model Attribute | Part 6 Definition | Our Implementation |
|---|---|---|
| Purpose | Classify, size, prioritize | Same — "size" is lightweight for single-operator PMO |
| Governance Focus | Completeness check; Tier assignment | DoR validation; P1-P4 priority confirmation |
| Artifact Inputs | Intake ticket | GitHub Issue in Proposed status with all template fields |
| Artifact Outputs | Triage decision, Tier assignment, routing | Board status change, Decision Date, priority confirmed |

Key compression: "Request more info" deliberately absent — one-and-done intake pushes quality upstream. Insufficient info = Reject with rationale or Defer with note.

## 3. Persona

| Role | Skills-Map Ref | Autonomy |
|---|---|---|
| Decision maker: Human operator | — | Tier 3 (Human-only) |
| Analysis assist: PO/BA Skill 7, Mode 1 | Completeness, INVEST criteria, quality validation | Tier 1 (Auto) |
| Priority validation: Portfolio Mgr Skill 1, Mode 3 | Priority assessment, strategic alignment | Tier 2 (Recommend) |

> **Persona card:** see [`release-personas.md §Stage 2`](../specs/release-personas.md) for the chip-prompt persona card embedded in hub-spoke prompts.

## 4. Inputs
From Intake: title, priority, category, description, evidence, affected files, proposed change, dependencies, acceptance criteria, labels, board status (Proposed).
Set at Triage: Decision Date, Board Status (Approved/Rejected/Deferred).
Contextual: full backlog (duplicate detection), current file state (feasibility).

## 5. Process
**Ticket interaction:** Read issue body (source of truth layer). Per [ticket-information-architecture.md](../specs/ticket-information-architecture.md).
**Phase A (Agent, Tier 1):** A1 DoR completeness check (template-aware per [gate-criteria-spec.md applies-to column triple](../../../core/schemas/gate-criteria-spec.md#gate-1-triage-readiness) + Template Detection Logic — bug.yml issues use Adapter G1-06-Bug / G1-05-Bug / G1-02-Bug / G1-01-Bug semantic mappings; observation.yml issues route via G1-02 observation-branch promotability test then surface to Template-Conversion Rule at Stage 3 Phase A1; applies to all releases going forward), A2 duplicate/overlap/subsumption detection (per [subsumption-convention.md](../protocols/subsumption-convention.md)), A2.5 similarity composite-signal detection (per [gate-criteria-spec.md G2-09](../../../core/schemas/gate-criteria-spec.md#gate-2-workflow-readiness) Similarity Composite-Signal Detection block; applies to all releases going forward), A3 dependency state validation (per procedure below), A3.5 native-dep mirror (per the Native-Dep Mirror (A3.5) block below; fires after G2-04 passes; mirrors body `FS+0d` deps to native `blocked-by`; applies to all releases going forward), A4 feasibility quick-check, A5 priority validation (validates the **body** `### Priority` P-level against full backlog context per [G2-01](../../../core/schemas/gate-criteria-spec.md#gate-2-workflow-readiness) + the § Gate 1 Priority-Model block — body-canonical, label-NOT-a-surface; the body→Projects-Priority-field mirror is written + gate-checked at Resolve per the B2a Priority-Field Mirror block below, enforcement point for [G2-12](../../../core/schemas/gate-criteria-spec.md#gate-2-workflow-readiness)), A5.5 oversize-decomposition routing — composite predicate per [G2-10](../../../core/schemas/gate-criteria-spec.md#gate-2-workflow-readiness) (`size:XL`-only 4-option routing; applies to all releases going forward) AND [G2-11](../../../core/schemas/gate-criteria-spec.md#gate-2-workflow-readiness) (COMPOSITE-OR oversize predicate per § Composite-OR Oversize Predicate block — P1 `size:XL` OR P2 declared decomposition-hook (literal `Decomposition hook` OR enumerated `(a) (b) (c)` scope-split pattern in body) OR P3 AC count ≥ 7 OR Affected Files count ≥ 5; 3-outcome enum: kept-as-one with rationale / split per [fission-convention.md](../protocols/fission-convention.md) / escalate per Tier 2 [SCOPE CHANGE]; applies to all releases going forward per the `Cutover (G2-11 / G3-12)` clause in gate-criteria-spec.md). G2-11 SUBSUMES G2-10 when its predicate fires (one routing decision under G2-11, not duplicate routing). On SPLIT outcome: invoke fission-convention.md Procedure Steps 1-4 BEFORE Phase B verdict per its Integration with Triage Step 4. `size:L` advisory unchanged, A6 triage summary per issue (DoR status, duplicates, similarity-pair candidates, dependency flags, feasibility flags, priority assessment, size routing, recommendation), A6.5 management-task identification per batch (per [Management-Task Signals (A6.5)](#management-task-signals-a65) below; fires once per triage batch after A6 per-issue summaries complete; applies to all releases going forward).

**Template-aware gate evaluation (per gate-criteria-spec.md):** Phase A1 evaluates G1 criteria using the applies-to column triple in [`gate-criteria-spec.md`](../../../core/schemas/gate-criteria-spec.md). For `bug`-labeled issues, Adapter Blocks G1-01-Bug / G1-02-Bug / G1-05-Bug / G1-06-Bug provide the lexical/semantic translation (Severity ↔ Priority, bug-narrative AC pattern, `[Bug]:` title prefix, conjunction of Reproduction Steps + Expected Behavior + Actual Behavior). For `observation`-labeled issues, G1-04 / G1-05 / G1-06 are `n/a` (fields don't exist); G1-02 evaluates against the observation-branch promotability test (3-field signal sufficient to draft an improvement.yml Description). Promotability PASS at observation surface routes to Stage 3 Phase A1 Template-Conversion Rule (per the Template-Conversion Rule in `gate-criteria-spec.md`) when the operator subsequently surfaces the issue for bundling. **Cutover discipline:** Applies to all releases going forward.

**Untriaged-view filter.** Stage 2 Triage's "untriaged" query excludes observation-tier intake artifacts from the no-status-label review surface. Observations carry `observation` category + `status: proposed` at intake (per `label-taxonomy.md`) but their triage is NOT the Approve/Defer/Reject decision — observations route via the G1-02 observation-branch promotability test and surface to the Pattern Review Cadence Protocol (per `core/governance/OPERATIONS.md` § Pattern Review Cadence Protocol) for cross-release emergence detection, not per-issue triage. Operator's "untriaged" filter:

    gh issue list --search 'is:open is:issue label:"status: proposed" -label:observation'

excludes observations. Pattern-detection skills query the complement set (`--label observation --state open`) when running Pattern Review per OPERATIONS.md Rule 1 triggers.
**Phase B (Human, Tier 3):** B1 review summary, B2 render Approve/Reject/Defer, B2a set Decision Date in the GitHub Projects Date field (see B2a Forcing-Function and Failure-Handling block below — REQUIRED, gate-blocking at G2-06), B3 cadence: **on-arrival for P1** (claim and render verdict within 1 business day [CALIBRATE-AFTER-3 — single-operator PMO posture; tune to N business days when team_size ≥ 2] per `release-process.md § Stage 2: Triage § Triage cadence`); **batch for P2-P4** (triaged immediately before the next bundling session per the ceremony sequence Triage → Bundle → Plan); **weekly minimum floor** (operator reviews all `status: proposed` issues at least once per calendar week regardless of bundling-session timing).

**B2a Forcing-Function and Failure-Handling (REQUIRED — gate-blocking at G2-06):**

The Decision Date MUST be set in the GitHub Projects Date field for all three outcomes (Approve / Reject / Defer) before CER Resolve completes. The Projects Date field is the queryable source of truth; the triage decision comment is human-readable narrative, non-authoritative for downstream automation (release-planner Bundle queries, decision-outcome correlation per capacity analysis).

| Aspect | Specification |
|---|---|
| Trigger | CER Resolve, executed BEFORE posting the triage decision comment and BEFORE the Status anchor update (Approved/Rejected/Deferred). |
| Command | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id <ITEM_ID> --field-id [OPERATOR_PROJECTS_DATE_FIELD_ID] --date YYYY-MM-DD` (field IDs per [github-projects-guide.md](../../../core/disciplines/github-projects-guide.md#field-ids-for-agent-integration)). |
| Date value | The calendar date (UTC) on which the operator rendered the B2 decision. In standard CER Resolve cadence (B2 and B2a are agent-adjacent), this is today's date. |
| Verification | `gh api graphql -f query='query { node(id: "<ITEM_ID>") { ... on ProjectV2Item { fieldValueByName(name: "Decision Date") { ... on ProjectV2ItemFieldDateValue { date } } } } }' --jq '.data.node.fieldValueByName.date'` — confirm the returned date equals the set value. Single-item GraphQL consumes ~1 GraphQL credit (~5000-fold reduction vs. the `item-list --limit 5000` batch pattern); accurately reflects newly-set field values without delay; name-stable across field-display-name renames. The item-ID is already in agent context from the B2a Command step above — no separate lookup needed at Verification. For bulk verification of multiple items (e.g., Decision Date Backfill detection, full-board audits), see [github-projects-guide.md § Preferred Verification Patterns](../../../core/disciplines/github-projects-guide.md#preferred-verification-patterns). **Cutover discipline:** Applies to all releases going forward.
| Gate effect | G2-06 fails until the Projects Date field reflects the Decision Date. Status anchor advancement to Approved/Rejected/Deferred is blocked until G2-06 passes. |
| Idempotency | Re-execution with the same `--date` value is a no-op. Safe to retry. |

**Failure-handling specification:**

| Failure mode | Detection signal | Outcome |
|---|---|---|
| Transient API error (HTTP 5xx, network timeout, 429 rate-limit) | `gh project item-edit` non-zero exit + stderr matches `5\d\d` / `timeout` / `network` / `rate limit` | Retry policy: one retry with 2s backoff. On retry success → proceed. On retry failure → escalate (treat as persistent). |
| Permission / scope failure (HTTP 401/403, missing `project` scope) | stderr matches `401` / `403` / `scope` / `permission` | Escalate immediately — no retry. CER Resolve blocked. |
| Missing project / wrong field ID (HTTP 404) | stderr matches `404` / `not found` | Escalate immediately — no retry. CER Resolve blocked. |
| Persistent failure after retry | Both retry attempts non-zero | CER Resolve blocked; operator action required. |

**Failure outcome — what CER Resolve does NOT do on persistent failure:**
- Does NOT advance Status (Approved/Rejected/Deferred) — anchor update is post-B2a in the sequence.
- Does NOT post the triage decision comment as if Resolve completed.
- Does NOT close the issue on Reject/Defer.
- Does NOT mark the sub-task as resolved or update the Decision Date field retrospectively without an explicit backfill (see [github-projects-guide.md § Decision Date Backfill (Retroactive)](../../../core/disciplines/github-projects-guide.md#decision-date-backfill-retroactive)).

**Failure outcome — what CER Resolve DOES do on persistent failure:**
- Posts a CER Resolve failure comment on the issue documenting: failure mode (per table above), retry attempts and exit codes, escalation rationale, operator action required (e.g., "`gh auth refresh -s project`" for scope failures).
- Issue remains in its current Status (Proposed) with current Stage (2-Triage); the triage Claim state anchor is preserved.
- Per [release-process.md Inter-Stage Feedback Protocol](../../governance/release-process.md) Tier 3 (Plan Rejection) applies if the failure is fundamentally unworkable (e.g., Projects API has been migrated and field IDs no longer resolve).

**B2a Priority-Field Mirror (REQUIRED — gate-blocking at G2-12, enforcement point for the body→Projects-Priority sync):**

After A5 confirms the body `### Priority` P-level (the canonical surface per [G2-01](../../../core/schemas/gate-criteria-spec.md#gate-2-workflow-readiness) + the § Gate 1 Priority-Model block), CER Resolve mirrors that P-level to the GitHub Projects **Priority** field — the queryable surface for downstream automation (release-planner Bundle queries, capacity/priority correlation). This is the concrete enforcement point for [G2-12](../../../core/schemas/gate-criteria-spec.md#gate-2-workflow-readiness). The model is symmetric to the Decision-Date forcing-function above: the body is canonical, the Projects field is its body-derived mirror.

| Aspect | Specification |
|---|---|
| Trigger | CER Resolve, alongside the B2a Decision-Date write (before posting the triage decision comment and before the Status anchor update). |
| Command | `gh project item-edit --project-id [OPERATOR_PROJECT_NODE_ID] --id <ITEM_ID> --field-id [OPERATOR_PROJECTS_VIEW_FIELD_ID] --single-select-option-id <P-LEVEL_OPTION_ID>` — the Priority Projects-field write that already exists (the Field IDs table maps Priority → `[OPERATOR_PROJECTS_VIEW_FIELD_ID]`; per-P-level option IDs per [github-projects-guide.md § Field IDs](../../../core/disciplines/github-projects-guide.md#field-ids-for-agent-integration)). |
| Value | The P-level digit (1-4) read from the body `### Priority` (improvement) / `### Severity` (bug, per Adapter G2-12-Bug) — the digit is canonical, not the qualifier word. |
| Canonical-source rule | **Body wins on mismatch.** If the Projects field already holds a different P-level, re-derive it from the body P-level; never edit the body to match the field. The body→field direction is the only direction this mirrors. |
| Verification | Query the Projects Priority field via the GraphQL `fieldValueByName(name: "Priority")` pattern (single-item, name-stable across field renames; ~1 GraphQL credit) and confirm the returned P-level equals the body P-level. |
| Gate effect | G2-12 fails until the Projects Priority field reflects the body P-level. Status-anchor advancement to Approved/Rejected/Deferred is blocked until G2-12 (and G2-06) pass. |
| Failure-handling | Identical posture to the Decision-Date B2a block above (transient → one retry w/ 2s backoff; 401/403 scope → escalate, operator runs `gh auth refresh -s project`; 404 → escalate; persistent → documented CER Resolve failure comment, no silent auto-pass). |
| Idempotency | Re-execution with the same P-level option is a no-op. Safe to retry. |

**Cutover discipline:** G2-12 applies to issues entering Stage 2 Triage strictly AFTER this criterion's introducing-release merge SHA recorded in the release log; pre-cutover issues are grandfathered; the introducing release itself is exempt (it cannot fire its own new gate).

**Phase B Output State Semantics:**

Triage produces one of three terminal verdicts, each with a distinct label outcome and downstream behavior. Apply the corresponding `status: *` label and remove `status: proposed` atomically; the Projects Status field follows per [ticket-information-architecture.md § Automation vs. Agent Responsibility](../specs/ticket-information-architecture.md#automation-vs-agent-responsibility).

| Verdict | Status label | Issue state | Milestone | Downstream |
|---|---|---|---|---|
| **Approve** | `status: approved` (removes `status: proposed`) | OPEN | unchanged (assigned at Stage 3 Bundle) | Advances to Stage 3 Bundle. Bundle applies `status: bundled` and assigns Milestone. |
| **Defer** | `status: deferred` (removes `status: proposed`) | OPEN | REMOVED if any (`gh issue edit N --remove-milestone`) | Issue parks in backlog; re-triage required for re-bundling (returns to `status: proposed` for full re-evaluation, or `status: approved` if scope/priority unchanged). |
| **Reject** | `status: rejected` (removes `status: proposed`) | CLOSED with reason `not planned` (`gh issue close N --reason "not planned"`) | unchanged (typically none — Rejected issues rarely had a Milestone) | Terminal. Reactivates only via T6 reopen, which automatically resets Status → Proposed; Triage agent then re-applies `status: proposed`. |

The `status: deferred` and `status: rejected` labels are part of the canonical Status Labels catalog — see [label-taxonomy.md § Status Labels](../../../core/specs/label-taxonomy.md#status-labels).

**Note on SPLIT verdicts (per [fission-convention.md](../protocols/fission-convention.md)):** When the 5-test rule (T1 atomicity per [intake-style-guide.md](../how-to/intake-style-guide.md)) returns SPLIT, the triage agent executes the fission protocol per [fission-convention.md](../protocols/fission-convention.md) BEFORE rendering the parent verdict; the parent then resolves via the standard 3-verdict semantics (typically Reject via close-as-fissioned path, or Approve via convert-to-tracking path). Applies to all releases going forward.

**Dependency State Validation (A3):**
Before an issue can be Approved, validate all `#N` references in the Dependencies field against compatible states. Operationalizes [gate-criteria-spec.md](../../../core/schemas/gate-criteria-spec.md) G2-04 ("Dependencies reference valid open issues or 'None'").

| Dependency State | Action |
|---|---|
| Approved, Bundled, In Progress, Done | Compatible — no action |
| Proposed | **Warn** — dependency has not yet been triaged, outcome unknown. Flag for operator review in A6 summary |
| Deferred | **Warn** — may Approve if dependency is non-blocking. Flag for operator review in A6 summary |
| Rejected | **Block** — cannot Approve. Flag: "Dependency #N is Rejected — resolve before approval (remove link, substitute, or re-open dependency)" |
| Invalid reference (not found, self-ref) | **Block** — fix Dependencies field before approval |

Automation: Tier 1 (Auto) — agent validates states via `gh issue view`. Blocks/warnings surface in A6 triage summary for operator review at Phase B.

**Native-Dep Mirror (A3.5) — REQUIRED, fires after G2-04 passes:**

After A3 dependency state validation passes (G2-04 PASS — no Rejected/invalid blockers), the agent mirrors the body Dependencies field's `FS+0d` subset to GitHub's native issue dependencies surface (`blocks` / `blocked-by`). Body remains authoritative; native is a one-way projected display surface per [ticket-information-architecture.md § Native Dependencies](../specs/ticket-information-architecture.md#native-dependencies).

| Aspect | Specification |
|---|---|
| Trigger | After A3 returns PASS (G2-04 passes); within Phase A, before A4 feasibility quick-check |
| Eligible body deps | `FS+0d #N` only (default / untyped). Non-FS-zero-lag types (`SS`, `FF`, `SF`, `FS±Nd`) are body-only by design — not mirrored. |
| Action — body cites `#X` not in native | Call GraphQL `addIssueDependency` to add `#X` to native `blocked-by` (body wins; auto-resolve) |
| Action — native has `#Y` not in body | Flag drift in A6 triage summary for operator review at Phase B; do NOT auto-modify body (body remains authoritative) |
| Cap handling | If `addIssueDependency` returns "dependency cap reached" (50/issue), flag to operator; suspend further mirror writes for this issue; body remains authoritative without native projection |
| Idempotency | Re-running A3.5 with the same body state is a no-op modulo API eventual consistency |
| Token scope | `repo` typically sufficient. If GraphQL mutation returns 401/403 / scope error: escalate per CER Resolve failure-handling — operator runs `gh auth refresh -s project` (see B2a failure-handling block precedent) |

**Mirror algorithm (pseudocode — invoked once per issue at A3.5):**

```text
FUNCTION mirror_body_to_native(issue_number):
  body_deps = parse_body_dependencies(issue_number)      # List[{type, offset_days, target}]
  mirror_eligible = filter(body_deps,                    # FS-zero-lag subset only
                           lambda d: d.type == "FS" AND d.offset_days == 0)
  native_blocked_by = read_native_blocked_by(issue_number)
  to_add = set(mirror_eligible.target) - set(native_blocked_by)
  drift  = set(native_blocked_by) - set(mirror_eligible.target)

  FOR target IN to_add:
    addIssueDependency(blocked=issue_number, blocking=target)   # body wins
  FOR target IN drift:
    flag_drift_in_a6_summary(issue=issue_number, native_extra=target)
```

**Failure-handling specification (matches A3 + B2a posture):**

| Failure mode | Detection signal | Outcome |
|---|---|---|
| Transient API error (HTTP 5xx, network timeout, 429 rate-limit) | GraphQL non-zero exit + stderr matches `5\d\d` / `timeout` / `network` / `rate limit` | Retry policy: one retry with 2s backoff. On retry success → proceed. On retry failure → log warning in A6 summary; A3.5 proceeds for remaining deps; A4 advances. |
| Scope failure (HTTP 401/403, missing `project` scope) | stderr matches `401` / `403` / `scope` / `permission` | Escalate — operator runs `gh auth refresh -s project`; A3.5 mirror writes suspended for this issue; A4 advances (mirror is not gate-blocking; body remains authoritative). |
| Cap reached (HTTP 422 — 50/issue limit) | stderr matches `cap` / `limit` / `50` / `422` | Flag in A6 summary; A3.5 mirror writes suspended for this issue; A4 advances. |

**Gate effect — A3.5 is NOT gate-blocking:** G2-04 (dependency state validation) remains the gate-blocking criterion. A3.5 native-mirror is an additive sync step; its failure surfaces in A6 summary for operator awareness but does NOT block Phase B verdict. Body Dependencies field remains the authoritative source for all downstream agent consumption regardless of native-mirror outcome.

**Cutover discipline:** Applies to all releases going forward.

**Management-Task Identification (A6.5) — REQUIRED, fires once per triage batch after A6 per-issue summaries complete:**

> NOTE on `.5` convention: A6.5 reuses the platform's `.5` sub-phase naming pattern (precedents: A2.5 similarity composite-signal; A3.5 native-dep mirror; A5.5 oversize-decomposition routing) with a SEMANTIC EXTENSION — existing `.5` precedents fire per-ISSUE; A6.5 fires per-BATCH (operating on the aggregate A6 outputs across all issues in the triage batch). Per-batch firing is documented in the trigger condition above ("once per triage batch") and is a recognized semantic extension of the `.5` convention per operator-rendered NW-2 decision at Iteration 1 Collective Review. Not a new naming pattern.

After all A6 per-issue triage summaries are produced for a triage batch (Phase B3 cadence: P1 on-arrival batches contain single issues; P2-P4 batches contain ≥1 issue), the agent runs a cross-batch sweep to detect **management-task signals** — actionable program-management tasks that emerge from triage but are NOT per-issue Approve/Reject/Defer decisions. Four detection patterns fire per the table below. Each detected signal surfaces in the triage decision comment as a `### Management-Task Signals` H3 block with the pattern name, evidence (issue refs), and recommended operator action.

Management-task signals are **advisory** — they do not gate Phase B verdict on the parent triage issues. The operator decides at Phase B1 whether to act on each signal (file a follow-up issue, escalate, decompose, etc.).

| Pattern | Detection predicate (reproducible) | Recommended operator action |
|---|---|---|
| **(1) Backlog hygiene** — stale issues, orphaned dependencies, conflicting scope | (1a) Stale issues: `gh issue list --repo [OPERATOR_GITHUB]/pmo-platform --state open --label "status: proposed" --json number,createdAt,updatedAt --jq '.[] \| select((.updatedAt \| fromdateiso8601) < (now - {STALE_SECONDS})) \| .number'` where `{STALE_SECONDS}` is derived from the triage cadence SLA per [Phase B B3](#5-process). (1b) Orphaned dependencies: for each open Proposed issue, parse body Dependencies via `awk 'BEGIN{flag=0} /^### Dependencies/{flag=1;next} /^### /{flag=0} flag' \| grep -oE 'FS\+0d #[0-9]+'` → `gh issue view #DEP --json state,stateReason` — flag if `state=CLOSED AND stateReason=NOT_PLANNED` (Rejected dependency) OR if dep does not resolve. (1c) Conflicting scope: cross-reference batch issues' `### Affected Files` per multi-extractor (Pattern 2c); identify shared paths via line-set intersection | File `[Backlog Hygiene]` issue per matched signal; OR fold into next bundle as cleanup |
| **(2) Escalation signals** — P1 blocked by lower-priority, dependency chains >3 deep, file contention | (2a) P1-blocked-by-lower (body-field Priority extraction — canonical, no `P1` labels exist in repo): `gh issue list --repo [OPERATOR_GITHUB]/pmo-platform --label "status: approved" --state open --json number,body --jq '.[] \| select(.body \| test("(?m)^### Priority\\s*\\n.*P1\\b")) \| .number'` → for each P1 issue parse body Dependencies via `awk 'BEGIN{flag=0} /^### Dependencies/{flag=1;next} /^### /{flag=0} flag' \| grep -oE 'FS\+0d #[0-9]+'` → for each blocker extract body Priority via `awk 'BEGIN{flag=0} /^### Priority/{flag=1;next} /^### /{flag=0} flag' \| grep -oE '^P[1-4]'` → flag if blocker Priority ≠ P1. (2b) Chain-depth (native blockedBy — canonical platform native-dep surface per A3.5 mirror): `gh api graphql -f query='query($number:Int!){repository(owner:"[OPERATOR_GITHUB]",name:"pmo-platform"){issue(number:$number){blockedBy(first:50){nodes{number}}}}}' -F number=N` → recursive trace through `blockedBy.nodes[].number`; halt at depth-3 OR `nodes:[]`; flag if depth >3. Fallback for unmigrated issues (pre-A3.5 cutover): parse body Dependencies as in (2a). (2c) File contention (multi-extractor — backticked + unbackticked fallback): aggregate `### Affected Files` from batch issues; extractor (a) `grep -oE '\`[^\`]+\`' \| tr -d '\`'` (canonical intake-style backticked paths); extractor (b) `grep -oE '\b[a-zA-Z0-9_./-]+/[a-zA-Z0-9_./-]+\.[a-z]+\b'` (unbackticked path-like tokens, heuristic fallback); de-duplicate; flag any path appearing in ≥2 batch issues. Skips correctly when Affected Files cites issue refs not file paths. | Escalate to operator in Phase B1; recommend re-prioritization OR sequencing intervention |
| **(3) Coordination needs** — cross-domain issues, research prerequisites | (3a) Cross-domain: `gh issue view #N --json labels --jq '[.labels[].name \| select(startswith("cluster:"))]'` → flag if count ≥2 OR a single issue with `cluster: process-protocol` + `cluster: documentation` (cross-cluster pairing). (3b) Research prerequisite: `gh issue view #N --json body --jq '.body' \| grep -cE '^(Research\|Prerequisite\|Discovery):'` → flag if count ≥1 | Surface for operator coordination; recommend pairing with sister-issue in same release OR research spike issue |
| **(4) Decomposition candidates** — large issues, multiple AC that could be separate items | Composite predicate (parallel to G2-11 oversize predicate per [gate-criteria-spec.md](../../../core/schemas/gate-criteria-spec.md#gate-2-workflow-readiness)). (4a) Large AC count: `gh issue view #N --json body --jq '.body'` → extract `### Acceptance Criteria` section → `grep -cE '^[0-9]+\. \|^- \[ \] '` → flag if count >5 (below G2-11 hard threshold of 7 but above advisory threshold). (4b) Multi-file scope: extract `### Affected Files` paths via multi-extractor (Pattern 2c) → flag if count ≥4 | Recommend SPLIT routing per [`fission-convention.md`](../protocols/fission-convention.md) OR scope reduction via AC edit |

**Detection-pattern formatting note (Pattern 2c specifically):** Backticked file paths (`intake-style-guide.md` convention) are the canonical case (extractor a). Unbackticked path-like tokens are captured via fallback regex (extractor b) but with reduced precision (may capture false-positives from prose). Issues whose Affected Files cite ISSUE refs (`#NNN`) rather than file paths are correctly skipped by both extractors — no file contention to detect in that case. Future-state issue (out of scope for this release): standardize Affected Files formatting per intake-style-guide.md across the corpus.

**Operator-routing format.** Management-task signals surface inline in the per-batch triage decision comment under a `### Management-Task Signals` H3 block, NOT as separate sub-task issues. Rationale: signals are advisory and contextual to the triage batch — surfacing them inline keeps them adjacent to the triage decisions they reference; converting each signal to a separate sub-task would inflate the open-sub-task count without operator decision value. Operator may choose to file a follow-up issue from a signal (e.g., file a P3 decomposition follow-up for a flagged Pattern 4 candidate) — that filing is an operator action at Phase B1, not an A6.5 automatic side-effect.

**Signal-block format (per-batch triage decision comment H3):**

```markdown
### Management-Task Signals (A6.5)

#### Pattern (1) Backlog Hygiene
- **(1a) Stale issues:** #N1, #N2 (updated >SLA-defined-threshold ago)
  - **Recommended action:** File `[Backlog Hygiene]` issue OR fold into next bundle as cleanup
- **(1b) Orphaned dependencies:** #N3 cites Rejected #N4 as `FS+0d` dependency
  - **Recommended action:** Edit body Dependencies field; resolve or substitute

#### Pattern (2) Escalation Signals
- **(2a) P1 blocked by lower-priority:** #N5 (P1) blocked by #N6 (P3)
  - **Recommended action:** Re-prioritize #N6 OR de-link

#### Pattern (3) Coordination Needs
- (none detected in this batch)

#### Pattern (4) Decomposition Candidates
- **(4a) Large AC count:** #N7 has 8 AC entries (>5 threshold)
  - **Recommended action:** Consider SPLIT per fission-convention.md OR scope reduction
```

**Failure-handling specification (matches A3.5 + A5.5 posture):**

| Failure mode | Detection signal | Outcome |
|---|---|---|
| Transient API error (`gh` HTTP 5xx, network timeout, 429 rate-limit) on any detection-pattern query | non-zero exit + stderr matches `5\d\d` / `timeout` / `network` / `rate limit` | Retry policy: one retry with 2s backoff. On retry failure → emit partial-signals warning in A6.5 block ("Pattern N skipped: transient API error"); proceed with remaining patterns. |
| Scope failure (HTTP 401/403, missing token scope) | stderr matches `401` / `403` / `scope` / `permission` | Suspend A6.5 for this batch; emit "A6.5 management-task identification skipped — token scope refresh required (`gh auth refresh -s repo`)" in triage decision comment; Phase B advances (A6.5 is non-gate-blocking). |
| Detection-pattern false positive surfaced by operator at Phase B1 (e.g., a Pattern 1 stale flag the operator considers expected/intentional) | Operator B1 feedback | Operator may add a `meta: management-task-exempt` label on the flagged issue to suppress re-detection in subsequent batches; agent honors the label in subsequent A6.5 sweeps. |

**Gate effect — A6.5 is NOT gate-blocking:** Phase B verdict for the parent issues in the batch is unaffected by A6.5. The block surfaces advisory program-management signals for operator awareness; per-issue Approve/Reject/Defer decisions proceed per A1-A6 outputs.

**Composition with A6 per-issue summary:** The A6 per-issue summary surface (line 37 — DoR status, duplicates, similarity-pair candidates, dependency flags, feasibility flags, priority assessment, size routing, recommendation) is unchanged. A6.5 runs AFTER all A6 summaries in the batch are produced; its inputs are the aggregated A6 outputs across the batch.

**Cutover discipline:** Applies to all releases going forward.

**Ticket lifecycle:** Claim: validate Status=Proposed, set Stage→2-Triage. Execute: triage analysis (A1-A6 + B1-B3). Resolve: (1) set Decision Date in Projects Date field per § Phase B B2a (forcing-function and failure-handling block), (2) verify the Projects Date field reflects the set value, (3) post the triage decision comment (which references the verified Projects Date field), (4) apply the verdict-specific label outcome per § Phase B Output State Semantics — Approve → `status: approved` + Status→Approved; Defer → `status: deferred` + Milestone removed (issue stays OPEN); Reject → `status: rejected` + close with reason `not planned`. Steps (3) and (4) do not execute on B2a persistent failure — see failure outcome specification. Per [ticket-information-architecture.md](../specs/ticket-information-architecture.md) Ticket Lifecycle Protocol.

**Framework dimensions touched:** Tracking (Decision Date, labels); Handoff (Approve/Reject/Defer). Per [execution-framework.md](../../../core/disciplines/execution-framework.md).

## 6. Outputs
Board Status (Approved/Rejected/Deferred), Decision Date (Projects Date field, set by agent via `gh project item-edit --date`), Priority (confirmed/adjusted), Category Label (verified). Native dependencies mirrored from body `FS+0d` subset per A3.5 (applies to all releases going forward; non-gate-blocking). No separate triage document — issue body updated (source of truth layer) + state anchors updated (board status, labels, Decision Date) + triage decision comment posted using standard stage review header format.

## 7. Stage-Transition Gate
Transition orchestration: per [handoff-coordinator-spec.md](../../../core/schemas/handoff-coordinator-spec.md) (invokes [gate-evaluation-spec.md](../../../core/schemas/gate-evaluation-spec.md)). Criteria below.
**Workflow Readiness** — per [gate-criteria-spec.md](../../../core/schemas/gate-criteria-spec.md#gate-2-workflow-readiness). Triage Readiness criteria pass (quality), no unresolved duplicates, dependency state validation passed (A3 — Rejected deps block, Deferred deps warn per G2-04), body `### Priority` P-level validated against backlog context (G2-01 — the canonical priority surface per the § Gate 1 Priority-Model block; label-NOT-a-surface), category label matches, Decision Date set in the Projects Date field (G2-06), Projects Priority field mirrored from the body P-level (G2-12 — body wins on mismatch; the body→Projects-Priority sync per the B2a Priority-Field Mirror block; applies to issues entering Triage after this criterion's introducing-release merge SHA), similarity composite-signal candidate pairs routed (G2-09 — fold / decompose-into-roadmap / keep-separate-with-rationale / defer; applies to all releases going forward), size:XL decomposition routing recorded (G2-10 — applies to all releases going forward), oversize-predicate decomposition routing recorded when ANY composite-OR predicate fires (G2-11 — 3-outcome enum kept-as-one / split per [fission-convention.md](../protocols/fission-convention.md) / escalate per Tier 2 [SCOPE CHANGE]; applies to all releases going forward). Approved issues sit in queue until bundled at Stage 3.

## 8. Automation Level
Overall Tier 2. Today: fully manual on GitHub Projects board. Target: skill mode runs A1-A6, human does B1-B3. Decision (Tier 3) stays human-only.

**The Tier 2 (Recommend) level refers to the final Approve/Defer/Reject verdict — NOT to per-action approval of the enrichment steps inside Phase A.** Run the full Phase A sequence (gate checks, enrichment comments, dependency links, native-dep mirror, management-task identification) end-to-end and present a single consolidated summary for the human decision. Do not gate on each individual action — each comment, each edit, each link. Per-action approval does not scale across a batch; the operator renders one verdict per issue from the summary, not an approval per enrichment step.

## 9. Gap Summary
8 gaps identified. Key: no triage skill mode (P2), stage defs have no persistent repo home (P2, resolved).

## 10. Retro
Key lessons: 15-stage model compresses heavily for single-operator — valid per Part 6. Priority doing triple duty (urgency, importance, scope). Approved queue is critical buffer between Triage and Bundle. Gap analysis is the compounding deliverable. "Request more info" absence is a feature.

## 11. Audit-Trail Capture

This stage emits the following events to [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) per the [unified schema](../standards/pipeline-event-log-schema.md):

| Event type | Subtype | When | Actor |
|---|---|---|---|
| `gate-outcome` | `g1-g2` | Per-issue triage decision rendered at Phase B (Approve / Reject / Defer); same event ALSO captured in `calibration-data.md` gate-outcome view — pipeline-event-log row carries `projects_to: calibration-data.md:<row-anchor>` in payload | `spoke:#N` (the per-issue triage spoke) |

Cutover: emit for all releases going forward.

## 12. Enforcement Surface

Stage 2 Triage has tooling enforcement at parity with Stages 1/3/4/12/13 via **Layer (b) detection** in `deploy.sh --check` (check-only variant). Operator-rendered Option 3 (check-only) at the Collective Review 2026-05-22 selected the lowest-blast-radius variant; layers (a) intake-time hook and (c) scheduled cadence are deferred as calibrated follow-ons IF Layer (b) shakedown surfaces need.

**Enforcement primitive:** `deploy.sh --check` Check 22 evaluates **all nine** G1 criteria (per [`gate-criteria-spec.md` § Gate 1](../../../core/schemas/gate-criteria-spec.md#gate-1-triage-readiness)) across all open `status: bundled` issues — it **enforces** the five structural criteria (G1-01 / G1-03 / G1-05a / G1-06 / G1-09, FAIL-capable) and **recommend-flags** the four judgment criteria (G1-02 / G1-04 / G1-05b / G1-08, advisory, never FAIL). This is the Layer-B (gate) surface of the two-layer model: the gate validates issue-body *content*. Intake-time field *presence* is delivered separately by **Layer-A form-required** (intake template `validations: required: true`), which HARD-STOPs blank required fields at submission — see the G1 Enforcement-Layer Split in [`gate-criteria-spec.md` § Gate 1](../../../core/schemas/gate-criteria-spec.md#gate-1-triage-readiness). Structural findings emit via the `flag_g1_enforcement` helper (gating, mode-aware) and judgment findings via `recommend_g1_enforcement` (non-gating advisory) to `core/hooks/deploy-check-warn-log.jsonl`. Check 22's mode is **decoupled** from the shared `deploy-check.mode` cohort — it resolves from a dedicated `g1-enforcement.mode` file (falling back to the shared mode when absent), so G1 enforcement can graduate warn→enforce independently; it ships **warn**.

**When-not-applicable (per operator framing 2026-05-11 — *"right tool, right time"*):**
- Issues that have not yet entered bundling (`status: proposed` / `status: approved`) are out of scope; the `status: proposed` content-sweep remains **deferred — and Layer-A supersedes it**: the intake-time HARD-STOP that a proposed-status sweep would target is now delivered earlier and cheaper by Layer-A form-required (intake template `validations: required: true`), so extending Check 22 to `status: proposed` is not pursued. The intake-scope determination stands as bundled-only.
- Check 22 applies to bundled issues going forward.
- Judgment-class criteria (G1-02 / G1-04 / G1-05b / G1-08) are *not gate-enforced* — they emit as **non-gating advisory RECOMMENDs** (via `recommend_g1_enforcement`), never as FAILs. Treating them as gating warnings would over-gate routine intake and contradict the *"right tool, right time"* framing; surfacing them as advisory keeps them visible without blocking.

**Cutover discipline:** Applies to all releases going forward.

**Shakedown:** Warn-mode initial per [`bypass-mode-readiness.md`](../../../core/rules/bypass-mode-readiness.md) §Shakedown precedent (matches Checks 8/9/10/14/15/18/19/20/21). Flip-to-enforce after ≥3-day warn-log review with zero false positives — flipped via the **dedicated `g1-enforcement.mode` file** (not the shared `deploy-check.mode`), so Check 22 graduates independently of the shared-mode cohort.
