---
title: Stage I/O Contracts
purpose: Defines the structured input/output contract at each pipeline stage boundary — exactly what artifacts cross a boundary, in what format, and how the receiving stage validates them.
type: schema
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: every pipeline stage at its boundary; the handoff-coordinator-spec (contract pre-check); gate-evaluation-spec.md; the receiving-stage validators
---
<!-- reference-durability: allow-link -->
# Stage I/O Contracts
<!-- design-artifact: flow-class=data-flow; name=stage-io-contracts; depicts=release/references/pipeline/README.md -->

## Purpose

Defines structured input/output contracts per pipeline stage boundary. Each contract specifies exactly what artifacts cross a boundary, in what format, and how the receiving stage validates them.

This file complements three existing references:
- **[pipeline/](../../release/references/pipeline/)** provides prose context for each stage's inputs (§4) and outputs (§6) — the *why* and *sources*. This file provides the structured, machine-parseable *what*.
- **[ticket-information-architecture.md](../../release/references/specs/ticket-information-architecture.md)** defines the "Output for Stage N+1" delivery mechanism on sub-task comments. Contracts define what content goes into that delivery mechanism.
- **[per-skill-output-contracts.md](per-skill-output-contracts.md)** defines output contracts per skill. This file defines I/O contracts per stage boundary — a parallel pattern at the pipeline layer.
- **[field-lifecycle-matrix.md](field-lifecycle-matrix.md)** defines field-level gate requirements per stage. Contracts define artifact deliverables; the matrix defines field state — together they form the complete "Definition of Ready" per boundary.
- **[handoff-coordinator-spec.md](handoff-coordinator-spec.md)** consumes this file at Phase 1 (Pre-Transition Validation) — the coordinator matches handoff payloads against boundary contracts defined here before invoking the gate evaluator. Missing or malformed artifacts per these contracts trigger a HOLD without an evaluator invocation.

Contracts are organized **per-boundary** (what crosses Stage N → Stage N+1), not per-stage. This matches the "Output for Stage N+1" delivery pattern and eliminates duplication — each artifact appears once at the boundary it crosses.

---

## Schema Definition

Each boundary contract uses a 7-field table:

| Field | Type | Purpose |
|-------|------|---------|
| **Artifact** | String | Name of the artifact crossing the boundary |
| **Format** | Enum | Physical format: MD file, table section, Projects field, comment section, label, GitHub Issue |
| **Required** | YES / NO / CONDITIONAL | Must be present for target stage to proceed. CONDITIONAL = depends on path |
| **Human Decision** | NO or description + Tier | If this artifact requires a human decision, what decision and at what automation tier |
| **Cognitive Load** | Summary / Detail / Evidence | Maps to tiered presentation from ticket-information-architecture.md |
| **Delivery** | String | Where/how the artifact is physically delivered |
| **Validation** | String | How target stage confirms receipt and completeness |

---

## Boundary: Stage 1 → Stage 2 (Intake → Triage)

Stage 1 (Intake) produces the demand artifact (the GitHub Issue) for Stage 2 (Triage) to classify, validate, and prioritize. The artifact carries a structural premise — its Proposed Change and Affected Files — which crosses this boundary as a **directional** proposal, not a binding structure. The boundary contract encodes that directionality as an informational handoff property; it introduces no gate at the 1 → 2 boundary (enforcement lives downstream at the Stage 5 → 6 design-handoff gate).

| Artifact | Format | Required | Human Decision | Cognitive Load | Delivery | Validation |
|----------|--------|----------|----------------|----------------|----------|------------|
| Proposal artifact | GitHub Issue (`improvement.yml`) | YES | NO | Detail | GitHub Issue in Proposed status with all template fields | All required template fields present (enforced by template validation); evidence section carries ≥1 evidence-labeled claim |
| Structural-premise directionality | Handoff property (stated in stage-01-intake §6 Outputs + stage-02-triage §4 Inputs prose) | NO (informational) | NO | Summary | Issue body Proposed Change + Affected Files fields | Downstream design treats the ticket's structure as a proposal to confirm or overturn at Solutioning — not a binding structure. Not enforced by this contract; enforced at the Stage 5 → 6 design-handoff gate. |

### Validation Rules

1. **Structural premise is directional:** Triage, Planning, and Solutioning may overturn the ticket's structure (its Proposed Change and Affected Files) with justification; perpetuating the existing structure is a choice to justify, not a default. Enforcement lives at the Stage 5 → 6 design-handoff gate (the structure-reviewed → retained/changed determination) — *now authored — see this file's Stage 5→6 Validation Rule 4 + [`stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) §7.2 SR-G1..SR-G4* — not at this boundary; this boundary states the property, it does not gate on it.
2. **No 1 → 2 gate added:** The directionality row is `Required = NO / Human Decision = NO` by design — it encodes the handoff property without creating a blocking gate at the intake/triage boundary, keeping all enforcement teeth at Stage 5.
3. **Section scope:** This section authors the directionality contract plus the Proposal artifact it qualifies; remaining Stage 1 → Stage 2 artifacts are added when the boundary is next exercised per the schema convention.

---

## Boundary: Stage 5 → Stage 6 (Solutioning → Engineering)

Stage 5 (Solutioning) produces design specifications for Stage 6 (Engineering). This boundary has two paths depending on whether Solutioning was activated for the release.

### Path A: Solutioning Activated

| Artifact | Format | Required | Human Decision | Cognitive Load | Delivery | Validation |
|----------|--------|----------|----------------|----------------|----------|------------|
| Refined change specs | Structured section in stage review comment | YES | Design decisions — Tier 3 | Detail | "Output for Stage 6" section on Stage 5 sub-task | Per-issue specs present; structure-level not file-level |
| ADR issues (closed) | GitHub Issues with `adr` label | CONDITIONAL (when created) | Accept/redirect/escalate — Tier 3 | Summary (link) + Detail (body) | Linked GitHub Issues, closed = accepted | All ADR issues closed; decisions documented in issue body |
| Blast radius analysis | Structured section in stage review comment | YES | NO | Detail | "Output for Stage 6" section | Transitive deps mapped; affected files listed |
| Implementability assessment | Flags in stage review comment | YES | NO | Summary | Inline in "Output for Stage 6" | Mode 3/4 flags resolved or documented |
| Tech debt flags | Flags in stage review comment | NO | NO | Summary | Inline in "Output for Stage 6" | Informational — no gate |
| Spec depth indicator | Explicit declaration | YES | NO | Summary | First line of "Output for Stage 6" | States "Solutioning-level" explicitly |
| Structure-review determination | Structured section in stage review comment | CONDITIONAL (when §3.2 structural-premise-review obligation recorded) | Structural decision — Tier 3 | Detail | "Output for Stage 6" section | Per changed structure: `reviewed → {retained\|changed} because {evidence}` + 3-axis (best-practice/scalability/maintainability) assertion present; gated by [`stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) §7.2 SR-G1..SR-G4 |

### Path B: Solutioning Skipped

| Artifact | Format | Required | Human Decision | Cognitive Load | Delivery | Validation |
|----------|--------|----------|----------------|----------------|----------|------------|
| Skip rationale | Text in release plan | YES | Routing decision — Tier 3 | Summary | Release plan Stage Applicability Matrix | Rationale present; activation criteria evaluated |
| Planning-level change specs | Section in release plan | YES | NO | Detail | Release plan File Change Matrix | File-level specs present per issue |
| Spec depth indicator | Implicit from skip | YES | NO | Summary | Absence of Stage 5 sub-task | Engineering infers Planning-level from absence per applicability matrix |

### Validation Rules

1. **Spec depth must be deterministic:** Engineering A1 checks for either (a) closed Stage 5 sub-task with "Output for Stage 6" → Solutioning-level, or (b) no Stage 5 sub-task per applicability matrix → Planning-level. Ambiguity = HOLD.
2. **ADR closure gate:** If Solutioning created ADR issues, ALL must be closed before Engineering proceeds.
3. **No open questions:** "Output for Stage 6" must not contain unresolved questions — Solutioning resolves or escalates. Engineering receives answers, not questions.
4. **Structure-review determination gate:** When the T3 structural-premise-review obligation ([`planning-solutioning-handoff.md`](../standards/planning-solutioning-handoff.md#structural-premise-review-obligation) §3.2) was recorded, the `Structure-review determination` artifact MUST be present and pass [`stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) §7.2 (SR-G1..SR-G4). Absent-or-failing = HOLD. This is the enforcement point the Stage 1→2 boundary Validation Rule 1 forward-references (*the structure-reviewed → retained/changed determination*).

---

## Boundary: Stage 12 → Stage 13 (Execute → Close)

Stage 12 (Execute) deploys the release and produces deployment evidence for Stage 13 (Close). This boundary has a single path — every release passes through Stage 12 before Close. Conditional artifacts depend on release content (e.g., whether skill files or rules were changed).

| Artifact | Format | Required | Human Decision | Cognitive Load | Delivery | Validation |
|----------|--------|----------|----------------|----------------|----------|------------|
| Merged PR | GitHub PR (MERGED status) | YES | Merge authorization — Tier 3 (from Stage 9) | Summary | PR on GitHub; merge commit SHA in deployment log | `gh pr view --json state` returns MERGED |
| Version tag | Git tag on main (vX.Y) | YES | NO | Summary | Git tag pushed to origin | `git tag -l vX.Y` returns tag; tag exists on remote |
| Deployment execution log | RELEASE_LOG.md table row + HTML detail block | YES | NO | Detail | RELEASE_LOG.md on main branch (post-merge commit) | vX.Y entry present with status DEPLOYED; per-file evidence in detail block |
| Post-deploy verification results | Structured checklist (PASS/FAIL per check) | YES | NO | Evidence | Appended to deployment log or release plan Verification Evidence section | All checks PASS or exceptions documented with rationale |
| Deployed file copies | Files at installed paths (S-2 copy mechanism) | CONDITIONAL (release includes skill/rule changes) | NO | Detail | Installed paths per skill-deployment.md | Zero diff between source and installed; `deploy.sh --check` PASS |
| Deferred items list | Flagged items with rationale | CONDITIONAL (items deferred during execution) | Deferred item disposition — Tier 3 | Summary | Release plan or PR body section | All deferred items have rationale; none block close without documented exception |
| Documentation Impact resolution table | Table section in PR body | CONDITIONAL (when ≥1 in-PR issue declared non-None Documentation Impact at Intake) | NO | Detail | PR body `### Documentation Impact` section per [`.github/PULL_REQUEST_TEMPLATE.md`](../../.github/PULL_REQUEST_TEMPLATE.md) | Per-issue row present; declared docs verified against `git log --follow <docs> origin/main..HEAD`; resolution gate at Gate 13 G-CL8 per [`gate-criteria-spec.md`](gate-criteria-spec.md#gate-13-close-readiness). Cutover discipline: applies to all releases going forward. |
| Stage 13 readiness signal | Phase D completion confirmation | YES | NO | Summary | "Output for Stage 13" section on Stage 12 sub-task | Signal present; references merged PR, tag, and deployment log |

### Validation Rules

1. **PR merge is irreversible:** MERGED state is the Stage 12 completion anchor. Stage 13 verifies via `gh pr view --json state`. If PR is not MERGED, Stage 13 cannot proceed — HOLD.
2. **Tag must exist and be pushed:** Version tag on main is required for release identification. `git tag -l vX.Y` must return the tag on both local and remote. Missing tag = HOLD.
3. **RELEASE_LOG.md entry gates Close:** Stage 12 writes status DEPLOYED. Stage 13 transitions status to VERIFIED after its own verification. Entry must exist before Stage 13 proceeds.
4. **Verification completeness:** All post-deploy checks must be PASS or have documented exceptions. "Not run" or missing checks = HOLD. Stage 13 A3 compiles these results into final verification evidence.
5. **Deployed copies must be zero-diff:** When applicable, `diff source installed` returns no differences. Non-zero diff = HOLD until resolved or documented as exception.
6. **Deferred items must not block closure:** Deferred items are acceptable if rationale is documented and items are tracked for a future release. Undocumented deferrals = HOLD.

---

## Boundary: Stage 3 → Stage 4 (Bundle → Planning)

Stage 3 (Bundle) produces a versioned Milestone for Stage 4 (Planning) to plan against. Post-cutover (per [`triage-design-rereview.md`](../../release/references/standards/triage-design-rereview.md) § 4), the boundary requires a re-review artifact at Stage 4 Phase A0 entry per issue.

| Artifact | Format | Required | Human Decision | Cognitive Load | Delivery | Validation |
|----------|--------|----------|----------------|----------------|----------|------------|
| Milestone | GitHub Milestone (`<slug>`) with assigned issues | YES | Bundle approval — Tier 3 (Stage 3 Phase B) | Summary | GitHub Milestone with issues + due date (slug-named; the version is not bound until the Stage-12 claim) | `gh milestone view <slug>` returns Milestone with ≥1 issue assigned |
| Dependency graph | Structured section in Stage 3 sub-task comment | YES | NO | Detail | "Output for Stage 4" section on Stage 3 sub-task | All `#N` dependency refs validated; no circular deps; compatible states per Gate 3 G3-04 |
| Capacity assessment | Structured section in Stage 3 sub-task comment | YES | NO | Summary | "Output for Stage 4" section on Stage 3 sub-task | Capacity heuristics applied per Stage 3 Bundle sizing |
| Bundle rationale | Text in Stage 3 sub-task comment | YES | NO | Summary | "Output for Stage 4" section on Stage 3 sub-task | Rationale text present per Gate 3 G3-06 |
| Re-review artifact | Structured section at HEAD of Stage 4 sub-task comment | YES (post-cutover) | C3 → operator decision Tier 0 — Tier 3 (Phase 1) | Detail | Stage 4 sub-task comment, BEFORE "Output for Stage 5" | Header metadata present (8 fields); per-requirement table covers all ACs + proposed-changes + risks; D1/D2/D3 findings + citations per Rule 3; classification per requirement; PT taxonomy if C3. Validated per [`triage-design-rereview.md`](../../release/references/standards/triage-design-rereview.md) § 1-3. |

### Validation Rules

1. **Cutover applicability:** Re-review artifact required for all releases entering Stage 4 going forward.
2. **Effort tier required:** Header metadata `effort_tier` field (trivial / standard / complex) determines artifact form per [`triage-design-rereview.md`](../../release/references/standards/triage-design-rereview.md) § 7.
3. **C3 classification HOLDs the boundary:** When any requirement is classified C3, the Stage 4 sub-task HOLDS pending Tier 0 — Premise Rejection routing. Stage 5 cannot claim the issue until Tier 0 resolution.
4. **Dependency state validation:** Per Gate 3 G3-04, all `#N` dependency refs must be in compatible states (Approved / Bundled / In Progress / Done) before Stage 4 proceeds.

---

## Boundary: Stage 4 → Stage 5 (Planning → Solutioning)

Stage 4 (Planning) produces a release plan for Stage 5 (Solutioning) when activation criteria are met. Post-cutover, the boundary requires a re-review delta artifact at Stage 5 Phase 0.5 entry per issue.

| Artifact | Format | Required | Human Decision | Cognitive Load | Delivery | Validation |
|----------|--------|----------|----------------|----------------|----------|------------|
| Release plan | MD file on release branch | YES | Plan approval — Tier 3 (Stage 4 Phase B) | Detail | `release/releases/plans/<slug>_RELEASE_PLAN.md` committed (slug-primary / pre-claim; renamed to `vX.Y_RELEASE_PLAN.md` at the Stage-12 claim) | File present on release branch; Implementation Sequence + File Change Matrix + Risk Register + Verification Plan + Rollback Strategy sections present |
| Stage Applicability Matrix | Table in release plan | YES | Routing decision — Tier 3 (Stage 4 Phase B) | Summary | Release plan §Stage Applicability Matrix | Stage 5 marked ACTIVATE or SKIPPED with rationale |
| Risk register | Table in release plan | YES | NO | Detail | Release plan §Risk Register | All risks have ID + tier/confidence + mitigation + owner |
| Re-review delta | Structured section at HEAD of Stage 5 sub-task comment | YES (post-cutover, CONDITIONAL on activation) | C3 → operator decision Tier 0 — Tier 3 (Phase 1) | Detail | Stage 5 sub-task comment, BEFORE "Output for Stage 6" | Delta-only when Stage 4 re-review ≤7 days AND no new blast-radius context (D2 + D3 columns only); FULL re-review when >7 days OR new context OR operator-requested. Validated per [`triage-design-rereview.md`](../../release/references/standards/triage-design-rereview.md) § 6. |

### Validation Rules

1. **Cutover applicability:** Re-review delta required for all releases entering Stage 4 going forward.
2. **Activation gate:** Re-review delta fires only when Stage 5 Solutioning is activated (per Stage 4 Stage Applicability Matrix). Skipped Solutioning means no Stage 5 sub-task and no re-review delta.
3. **Delta vs. full determination:** Spoke determines delta vs. full per [`triage-design-rereview.md`](../../release/references/standards/triage-design-rereview.md) § 6 conditions (>7-day staleness OR new blast-radius context OR operator request).
4. **C3 classification HOLDs the boundary:** When any requirement is classified C3 in the delta or full re-review, the Stage 5 sub-task HOLDS pending Tier 0 — Premise Rejection routing.
5. **Effort tier may upgrade:** Tier upgrades from Stage 4 → Stage 5 are autonomous; tier downgrades require operator approval.

---

## Boundary: Stage 2 → Stage 3 (Triage → Bundle)

Stage 2 (Triage) produces the classified, prioritized, DoR-validated issue for Stage 3 (Bundle) to compose into a versioned Milestone. The board-status decision (Approved / Deferred / Rejected) is the gating human decision — only `Approved` issues are eligible for bundling.

| Artifact | Format | Required | Human Decision | Cognitive Load | Delivery | Validation |
|----------|--------|----------|----------------|----------------|----------|------------|
| Board Status | Projects field (Approved / Rejected / Deferred) | YES | Approve/Defer/Reject verdict — Tier 3 | Summary | Projects board status field, set by agent | Only `Approved` issues are bundle-eligible; verified per Gate 3 G3-01 (issue in Approved state). Rejected/Deferred do not cross. |
| Decision Date | Projects Date field | YES | NO | Summary | `gh project item-edit --date` (agent-set) | Date field populated on the item |
| Priority (confirmed/adjusted) | Label | YES | Priority-adjust — Tier 2 | Summary | Priority label on issue, verified at triage | Priority label present and current |
| Category Label (verified) | Label | YES | NO | Summary | Category label per `label-taxonomy.md` | Label verified against taxonomy |
| Native dependencies (mirrored) | Native `blocked-by` links | CONDITIONAL (issue has body `FS+0d` deps) | NO | Summary | Native dep links mirrored from body `FS+0d` subset per Stage 2 A3.5 | `#N` refs resolvable; mirror consistent with body (non-gate-blocking per shard) |
| Triage decision comment | Comment section (stage review header format) | YES | NO | Detail | Stage 2 sub-task comment, standard stage review header | Comment posted; per-issue Approve/Defer/Reject rationale present |

### Validation Rules

1. **Approved-only crossing:** Only issues in `Approved` board status are eligible for Stage 3 bundling; `Deferred` / `Rejected` issues do not cross this boundary. Verified per Gate 3 **G3-01** (issue in Approved state — LIVE in gate-criteria-spec.md § Gate 3).
2. **Dependency-state compatibility fed forward:** the mirrored native `blocked-by` set feeds Stage 3's dependency-graph build; state compatibility is validated downstream at Gate 3 **G3-04** (all `#N` refs in Approved/Bundled/In-Progress/Done). This boundary supplies the substrate; it does not itself gate on dep-state.
3. **State-anchor completeness:** Board Status + Decision Date + Priority + Category label MUST all be set before bundling — a partially-triaged issue (missing any state anchor) is not bundle-ready.

### Failure Handling

- **Board Status absent / issue not Approved:** issue is held out of the bundle; Stage 3 does not pull it. Return to Stage 2 for the verdict (Tier 3 operator decision).
- **Category / Priority label missing:** Tier 1 — Triage completes the label set before the issue is bundle-eligible.
- **Native-dep mirror inconsistent with body:** non-gate-blocking per the Stage 2 shard; log the drift and re-run the A3.5 mirror. Does not HOLD the boundary.

---

## Boundary: Stage 6 → Stage 7 (Engineering → Dev Testing)

Stage 6 (Engineering) produces committed changes on the release branch + the PR with verification evidence for Stage 7 (Dev Testing) to review. This boundary is the exit of the build stage; its structural completeness is gated by Gate 6 (Engineering Completeness).

| Artifact | Format | Required | Human Decision | Cognitive Load | Delivery | Validation |
|----------|--------|----------|----------------|----------------|----------|------------|
| Committed changes on release branch | Commits on `release/<slug>` | YES | NO | Detail | Git commits on the release branch (slug-primary / pre-claim) | Every release-scoped issue has ≥1 commit referencing its `#N` — Gate 6 **G6-02** (commits link source issues) |
| Pull request | GitHub PR | YES | NO | Summary | PR opened for the release branch | PR exists — Gate 6 **G6-01** (`gh pr list --head <branch>` returns ≥1) |
| PR body (parser-clean) | PR body (metadata sections) | YES | NO | Detail | PR body: implementation summary + per-issue status | Parses without a BLOCKING/parse-error signal — Gate 6 **G6-03** |
| Verification evidence | PR-body section (per-issue PASS/FAIL) | YES | NO | Evidence | PR body `Verification Evidence` section | Per-issue PASS/FAIL present — Gate 6 **G6-04** |
| Change Description | `## Change Description` section in release plan FILE | YES | NO | Detail | Release plan on branch, per RELEASE_PROTOCOL § Change Description Protocol | Section present + committed before PR ready — Gate 6 **G6-05** |
| Sub-task decomposition status | GitHub sub-issues (closed) OR PR-body checklist rows | CONDITIONAL (per A2 container threshold) | NO | Summary | Sub-issues closed, or checklist rows checked | Decomposition rows resolved per the A2 threshold |
| Deviation log | Section in release plan | CONDITIONAL (deviations occurred) | NO | Summary | Release plan deviation-log section | Deviations recorded with rationale |

### Validation Rules

1. **Gate 6 Engineering Completeness is the structural exit gate.** Stage 7 entry requires **G6-01..G6-05** (PR exists / commits link source issues / parser-clean PR body / verification-evidence present / Change Description section present) per [`gate-criteria-spec.md § Gate 6`](gate-criteria-spec.md#gate-6-engineering-completeness). *Forward-pointer note: Gate 6 co-lands with this contract in the same release PR (the G6 criteria and this 6→7 boundary are authored together — the G6-01..G6-05 IDs bind when the PR merges). This mirrors the Stage 1→2 contract, which forward-references the Stage 5→6 design-handoff gate.*
2. **Commit-linkage completeness:** `issues_with_commits / total_release_issues = 1.0` — every release-scoped issue is traceable to a commit, or has a documented deviation-log entry if descoped (G6-02).
3. **PR carries verification, not questions:** the PR body's Verification Evidence section carries per-issue PASS/FAIL results (G6-04); Stage 7 receives evidence to review, not an untested build.

### Failure Handling

- **No PR / commits unlinked / PR body unparseable / verification absent / Change Description absent:** return to Stage 6 Engineering at the Phase named in the matching G6-0N self-repair row (C2 for PR, B1 for commit linkage, C4 for verification, C1 for Change Description). **Warn-mode (author-time):** G6 ships warn-mode initially — log to `core/hooks/gate-g6-warn-log.jsonl` and PROCEED; flip-to-enforce deferred to a 2-3-release shakedown (G-CL6/G3-14 precedent).
- **Deviation without a log entry:** Tier 1 `[ADJUST]` — Engineering records the deviation in the release-plan deviation log.

---

## Boundary: Stage 7 → Stage 8 (Dev Testing → QA Testing)

Stage 7 (Dev Testing) produces the Quality Review Report, terminating in the structured Handoff Payload that is Stage 8's authoritative input. This contract formalizes the de-facto DT↔QA Handoff Payload already defined in `stage-07-dev-testing.md` — it lifts, it does not re-derive.

| Artifact | Format | Required | Human Decision | Cognitive Load | Delivery | Validation |
|----------|--------|----------|----------------|----------------|----------|------------|
| Quality Review Report | Structured report (section scores + findings) | YES | Accept/override findings — Tier 3 (Phase E) | Detail | Stage 7 sub-task; terminates in `### Output for Stage 8` | Report present; section scores (1-5) + finding list with severity + escape rate |
| Verdict | Enum: PASS / CONDITIONAL PASS / FAIL | YES | NO | Summary | First line of `### Output for Stage 8`: `**Verdict:** <enum> — <rationale>` | Phase A entry gate — only PASS / CONDITIONAL PASS advance to Stage 8 |
| AC map | Table: `AC · Issue # · Verdict · Evidence` | YES | NO | Detail | Handoff Payload AC-map table | Primary input for Stage 8 Phase B acceptance review |
| Findings | Table: `F-ID · Severity · Dimension · Routing tier · Origin · Status · Evidence · Recommendation` | YES | NO | Detail | Handoff Payload findings table | 5-bucket severity vocabulary; F-IDs stable across iterations |
| Escape summary | Table: `Origin stage · Count` | YES | NO | Summary | Handoff Payload escape table | Stage 7 escape count for calibration |
| Test-results | Table: `Suite · Selected-by · Result · Pass/Fail · Env · Evidence · Event ts` | YES | NO | Evidence | Handoff Payload (Phase A8 runtime-gate outcome) | Confirms the runtime-code gate ran; single `NONE — no runtime code path changed` line when no code path changed |
| Iteration count / PR reference / Files reviewed / Downstream attention / Cross-issue notes | Fields per the Forward-Handoff schema | YES (Downstream attention & Cross-issue notes may be `None`) | NO | Summary/Detail | `### Output for Stage 8` fields | Extracted by Stage 8 Phase A Entry Validation |

### Validation Rules

1. **Verdict is the entry gate:** only `PASS` / `CONDITIONAL PASS` advance to Stage 8. `FAIL` routes back — Tier 1 findings to Engineering (DT↔Engineering Iteration Loop), Tier 2/3 to operator — and does not cross this boundary.
2. **Handoff Payload is the authoritative interface:** Stage 8 Phase A extracts required fields from the `### Output for Stage 8` section per the DT↔QA Handoff Protocol. Missing required fields = malformed handoff → Stage 8 Phase A entry-validation HOLD.
3. **Severity vocabulary reconciliation:** the Findings-table `Severity` column uses the 5-bucket vocabulary (Blocker/Major/Minor/Cosmetic/Informational); a report emitting Phase-D 3-bucket verdict severities in the Findings table fails parse validation (per the protocol's reconciliation rule).
4. **Layered-review preservation:** QA findings re-enter the quality layer (Stage 7) before the fix layer (Stage 6); this boundary does not route DT output directly to Engineering.

### Failure Handling

- **Verdict = FAIL (Tier 1):** classified finding list returns to Engineering per the DT↔Engineering Iteration Loop; DT re-enters at targeted re-review scope; a new Handoff Payload (Iteration N) is produced before re-crossing.
- **Verdict = FAIL (Tier 2/3):** escalation package to operator per the Inter-Stage Feedback Protocol; boundary HOLDS.
- **Malformed Handoff Payload (missing anchor / fields):** Stage 8 Phase A entry validation HOLDs; return to Stage 7 Phase D to complete the payload.

---

## Boundary: Stage 8 → Stage 9 (QA Testing → Plan Review)

Stage 8 (QA Testing) produces the Acceptance Report for Stage 9 (Plan Review) to assemble into its Go/No-Go evidence package. The upstream-reports-present check at Stage 9 (G-PR2) makes this report a required input to Plan Review.

| Artifact | Format | Required | Human Decision | Cognitive Load | Delivery | Validation |
|----------|--------|----------|----------------|----------------|----------|------------|
| Acceptance Report | Structured report | YES | Accept/override — Tier 3 | Detail | Stage 8 sub-task; downstream to Stage 9 | Report present; consumed by Gate 9 **G-PR2** (all upstream reports present — Stage 7 quality report + Stage 8 acceptance report + Stage 6 PR + Stage 4 release plan) |
| Acceptance matrix | Table (per-criterion verdict) | YES | NO | Detail | Acceptance Report matrix section | Per-criterion verdict present for every AC |
| Acceptance score | Numeric | YES | NO | Summary | Acceptance Report | Score present |
| Fitness assessment | Structured assessment | YES | NO | Summary | Acceptance Report | Fitness-for-release stated |
| Stage 7 escape log | Table | YES | NO | Summary | Acceptance Report | Stage 7 escapes carried forward (feeds Stage 9 escape/calibration) |
| Lane distribution | Table | YES | NO | Summary | Acceptance Report | Lane breakdown present |
| Overall verdict | Enum (PASS / CONDITIONAL / FAIL) | YES | NO | Summary | Acceptance Report top line | Only passing verdicts advance to Stage 9; Lane 2 findings route back to Stage 7 (QA Return to Dev Testing) |

### Validation Rules

1. **Gate 9 Plan Review consumes this report:** the Acceptance Report is a required member of the Stage 9 evidence package per Gate 9 **G-PR2** (all upstream reports present) and feeds **G-PR1** (evidence package complete, Phase A1–A6). Cite the existing **G-PR1..G-PR9** IDs — LIVE in `gate-criteria-spec.md` § Gate 9.
2. **Passing-verdict-only crossing:** a FAIL / Lane-2 outcome routes back to Stage 7 as a QA Return to Dev Testing payload (per the DT↔QA Handoff Protocol § Return Path); it does not cross into Plan Review.
3. **Escape provenance preserved:** the Stage 7 escape log crosses forward so Stage 9 calibration and escape-rate accounting see the full upstream escape history.

### Failure Handling

- **Acceptance Report absent at Stage 9:** Gate 9 **G-PR2** self-repair — escalate per the Inter-Stage Feedback Protocol Tier 2 (SCOPE CHANGE); the upstream stage owes a return-to-Stage-9; Plan Review decision blocked.
- **Overall verdict FAIL (Lane 2):** findings emitted as the QA Return to Dev Testing payload; boundary routes back to Stage 7, not forward.
- **Methodology note (Waterfall/PRINCE2, Hybrid):** per the `## Methodology Variation` table, the 8→9 boundary carries an **additional** phase-gate-review / end-stage-assessment artifact (Waterfall) or BOTH phase-gate + sprint-review families (Hybrid at Stage 9). This contract is the universal baseline; `handoff-coordinator` merges the archetype's supplementary artifact per `delivery_approach`.

---

## Boundary: Stage 9 → Stage 12 (Plan Review → Execute, compressed)

Stage 9 (Plan Review) produces the Go/No-Go decision record — the deployment authorization — for Stage 12 (Execute). The boundary is compressed: Stages 10 (Dry Run) and 11 (Snapshot) are git-native no-material-artifact stages (Dry Run validates procedure; git history IS the snapshot), so the load-bearing authorization crosses 9 → 12 directly.

| Artifact | Format | Required | Human Decision | Cognitive Load | Delivery | Validation |
|----------|--------|----------|----------------|----------------|----------|------------|
| Go/No-Go decision record | Decision record (verdict + rationale + conditions + authorization) | YES | GO/NO-GO — Tier 3 (the merge authorization) | Detail | Stage 9 sub-task + parent issue, per the decision-record format | Decision record posted — Gate 9 **G-PR6**; the record IS the deployment authorization (no separate authorization doc) |
| Evidence package | Assembled reports + PR scope + risk status + deployment readiness | YES | NO | Detail | Stage 9 evidence package | Complete per Gate 9 **G-PR1** (Phase A1–A6 populated) |
| Release Readiness Scan output | 13-dimension scan (markdown table + `gate-outcome` log row) | YES | NO | Detail | Stage 9 sub-task comment + `pipeline-event-log.md` | Aggregate verdict (ALL-PASS / ANY-FAIL / ANY-PARTIAL) per Phase A6 (G-PR1) |
| Deployment-readiness verdict | Checklist (PR mergeable / branch current / metadata / rollback) | YES | NO | Summary | Decision record deployment-readiness section | All PASS — Gate 9 **G-PR5** (`gh pr view --json mergeable`) |
| GO baseline SHA | H3 in release plan `## Cross-PR Overlap Audit → ### Baseline SHA` | YES | NO | Summary | Release plan Baseline-SHA H3 | Recorded per Gate 9 **G-PR9** (makes the GO falsifiable; sibling-merge revalidation predicate) |

### Validation Rules

1. **Decision record IS the authorization:** Stage 12 proceeds only on a GO verdict recorded per Gate 9 **G-PR6**. A NO-GO returns the release to re-bundle / re-plan; it does not cross to Execute.
2. **Compression is explicit:** Stages 10–11 add no material artifact to this boundary (Dry Run = procedure validation; Snapshot = git history). The 9 → 12 contract carries the Stage 9 authorization directly; no Stage-10/11 deliverable is required to cross.
3. **Execute-side gate is G-EX (cite the existing IDs):** once the authorization crosses, Stage 12 must satisfy Gate 12 **G-EX1..G-EX8** (PR MERGED / tag on main / zero-diff deploy / RELEASE_LOG appended / release row present / Phase C verification PASS / no Layer-2 leakage / deferred items documented) per `gate-criteria-spec.md` § Gate 12 (LIVE). This contract hands Execute a GO; **G-EX** governs what Execute produces from it.
4. **GO baseline currency:** the GO records its baseline SHA (G-PR9) so a sibling merge landing between GO and Execute triggers STALE-REVALIDATE / STALE-VOID revalidation rather than a silently-stale merge.

### Failure Handling

- **NO-GO verdict:** release returns to Stage 4 Planning / Stage 3 Bundle per the decision-record conditions; boundary does not cross.
- **Decision record missing (G-PR6):** operator posts it — the decision record IS the closure artifact (no separate escalation tier).
- **PR not mergeable at authorization (G-PR5):** return to Stage 6 Engineering per the Inter-Stage Feedback Protocol Tier 1/2; GO cannot be rendered until mergeable.
- **Baseline STALE-VOID (G-PR9):** Tier 2 `[SCOPE CHANGE]` — re-baseline the release branch on `main`, return to Stage 9 for a fresh GO (fresh-Stage-9-GO-mandatory precedent).
- **Methodology note (Waterfall/PRINCE2):** per the `## Methodology Variation` table, Stage 12 Execute requires a **change-control-board-approval** artifact when downstream stages modify upstream-locked specs. Universal baseline here; `handoff-coordinator` merges the CCB artifact per `delivery_approach`.

---

## Future Boundaries

All primary pipeline-flow boundaries (Stage 1 → 2 through Stage 12 → 13) are now authored above. Any new boundary follows the schema definition above and is appended as an H2 section per the append convention.

---

## Methodology Variation — Contract Applicability

The inter-stage contracts above are the canonical set — the Process itself is methodology-invariant. What varies per [Methodology](../specs/terminology-glossary.md#term-methodology) is WHICH supplementary artifacts accompany the universal contract at a given boundary. The table below covers archetypes that add or substitute artifacts at specific boundaries; all other archetypes carry the universal contract schema without supplementary artifacts.

| Archetype | Variation | Applies to | Notes |
|---|---|---|---|
| **Scrum / XP / SAFe** | Stage 3→4 boundary carries an additional **sprint-plan** or **PI-plan** artifact (sprint backlog with commitment, or PI objectives with team-level breakdowns) in addition to the universal Milestone contract. Stage 13 Close adds **sprint-retro** or **inspect-and-adapt** artifact. | §Stage 3→4, §Stage 13 | [SOURCE] Scrum Guide + SAFe 6.0 — timebox-bound planning artifacts. |
| **Waterfall / PRINCE2** | Stage 8→9 boundary carries an additional **phase-gate-review** or **end-stage-assessment** artifact (formal gate decision package with rollback-authorization statement). Stage 12 Execute requires **change-control-board-approval** artifact when downstream stages modify upstream-locked specs. | §Stage 8→9, §Stage 12 | [SOURCE] PMBOK phase-gate reviews + PRINCE2 2017 end-stage assessments. |
| **Kanban** | Stage 3 Bundle boundary contract is SOFT — Milestone membership can change inter-stage as cards flow through the board. Stage 8→9 carries a **service-delivery-review** artifact (cumulative-flow + aging metrics) instead of batch-release artifacts. | §Stage 3, §Stage 8→9 | [SOURCE] Kanban Method — pull-based release vs. batch Milestone. |
| **Hybrid** | Contract artifacts partition by phase: predictive-phase stages carry phase-gate-review artifacts (Waterfall-style); iterative-phase stages carry sprint-plan / sprint-review artifacts (Scrum-style). Stage 9 Plan Review boundary carries BOTH artifact families (phase-gate package + sprint-level verification). | §Stage 9 specifically | [INFERRED] Composition of Waterfall upstream + Scrum downstream contracts. |
| **Custom** | See the `custom_methodology_definition` block in PROJECT.md; supplementary artifacts at each boundary derive from declared `artifacts` and `ceremonies` fields. Skills MUST consult the block BEFORE defaulting to any archetype's contract schema. | All boundaries | [SOURCE] [`methodology-parameterization-v1.md § Custom Extension Protocol`](../../release/references/specs/methodology-parameterization-v1.md). |
| **All archetypes (universal contract baseline)** | Every stage boundary carries the universal contract schema (required artifacts, blocking conditions, rollback authority) regardless of archetype. Methodology variation ADDS artifacts; it does not REPLACE the universal contract. | All boundaries | [INFERRED] Process invariance — the 13-stage Process is methodology-agnostic. |

**Consumer guidance.** `handoff-coordinator` reads `delivery_approach` at each boundary and merges the archetype's supplementary artifacts with the universal contract. When contract artifacts conflict (e.g., Hybrid at Stage 9 carries both phase-gate + sprint-review), the handoff coordinator SHALL present both for the operator to reconcile — not silently prefer one.
