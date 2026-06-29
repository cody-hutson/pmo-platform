<!-- reference-durability: allow-link -->
# Stage I/O Contracts

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

1. **Structural premise is directional:** Triage, Planning, and Solutioning may overturn the ticket's structure (its Proposed Change and Affected Files) with justification; perpetuating the existing structure is a choice to justify, not a default. Enforcement lives at the Stage 5 → 6 design-handoff gate (the structure-reviewed → retained/changed determination), not at this boundary — this boundary states the property, it does not gate on it.
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
| Versioned Milestone | GitHub Milestone (vX.Y) with assigned issues | YES | Bundle approval — Tier 3 (Stage 3 Phase B) | Summary | GitHub Milestone with issues + version + due date | `gh milestone view vX.Y` returns Milestone with ≥1 issue assigned |
| Dependency graph | Structured section in Stage 3 sub-task comment | YES | NO | Detail | "Output for Stage 4" section on Stage 3 sub-task | All `#N` dependency refs validated; no circular deps; compatible states per Gate 3 G3-04 |
| Capacity assessment | Structured section in Stage 3 sub-task comment | YES | NO | Summary | "Output for Stage 4" section on Stage 3 sub-task | Capacity heuristics applied per Gate 3 G3-05 |
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
| Release plan | MD file on release branch | YES | Plan approval — Tier 3 (Stage 4 Phase B) | Detail | `release/releases/plans/vX.Y_RELEASE_PLAN.md` committed | File present on release branch; Implementation Sequence + File Change Matrix + Risk Register + Verification Plan + Rollback Strategy sections present |
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

## Future Boundaries

Remaining stage boundaries will be added as stages are exercised per-release. Each new boundary follows the schema definition above and is appended as an H2 section. Priority order based on pipeline flow:

- Stage 2 → Stage 3 (Triage → Bundle)
- Stage 6 → Stage 7 (Engineering → Dev Testing)
- Stage 7 → Stage 8 (Dev Testing → QA Testing)
- Stage 8 → Stage 9 (QA Testing → Plan Review)
- Stage 9 → Stage 12 (Plan Review → Execute, compressed)

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
