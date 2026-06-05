# Traceability Matrix — PMO Reference

## Purpose

This file provides the framework for requirements traceability — the practice of
linking every requirement to its upstream justification and downstream implementation,
test, and deployment artifacts. The pmo-process-designer skill reads this file in
Mode D (Cross-Functional Process Integration) to guide traceability decisions,
matrix construction, and chain integrity validation.

---

## Traceability Chain

The complete forward chain links strategic intent to operational verification:

| Chain Position | Artifact | Traced From | Traced To | Owner |
|---------------|----------|-------------|-----------|-------|
| 1. Strategy | Strategic Theme / OKR | Enterprise Vision | Portfolio Backlog | Executive / Strategy |
| 2. Portfolio | Epic / Initiative | Strategic Theme | Features / Capabilities | Portfolio Manager |
| 3. Program | Feature / Capability | Epic | User Stories | Product Manager / PO |
| 4. Project | User Story / Requirement | Feature | Tasks + Test Cases | Product Owner |
| 5. Design | Design Element / FDD | Requirement | Implementation | Architect / Tech Lead |
| 6. Implementation | Code / Configuration | Design Element | Test Cases | Developer |
| 7. Test | Test Case | Requirement + Design | Test Execution Result | QA / Developer |
| 8. Deployment | Deployment Artifact | Release Plan | Verification Result | Release Manager |
| 9. Verification | Verification Result | Test Case + Deployment | PIR / Lessons Learned | PM / QA Lead |

---

## Traceability Matrix Template

### Column Structure

| Column | Description | Source |
|--------|-------------|--------|
| **Requirement ID** | Unique identifier from requirements management | Requirements register |
| **Requirement Description** | Brief description of the requirement | Requirements register |
| **Priority** | Business priority (H/M/L or WSJF score) | Prioritization framework |
| **Design Element** | Architecture or design artifact that addresses this requirement | Design documentation |
| **Implementation Reference** | Code module, configuration item, or build artifact | Source control / config management |
| **Test Case ID(s)** | Test cases that verify this requirement | Test management |
| **Test Execution Status** | Pass/Fail/Not Run/Blocked per test case | Test execution results |
| **Deployment Artifact** | Release package, deployment script, or configuration change | Release management |
| **Verification Result** | Post-deployment verification status | Production verification |
| **Traceability Status** | Full Chain / Partial / Broken (computed from completeness) | Computed |

### Row Example

| Req ID | Description | Priority | Design | Implementation | Test Cases | Test Status | Deploy | Verify | Chain |
|--------|-------------|----------|--------|---------------|------------|-------------|--------|--------|-------|
| REQ-042 | System shall send email notification within 5 min of order status change | H | FDD-Notifications §3.2 | OrderNotificationService.cs | TC-142, TC-143, TC-144 | Pass, Pass, Pass | REL-2.4.0 | Verified 2026-03-15 | Full |
| REQ-043 | System shall support batch order import via CSV | M | FDD-OrderImport §2.1 | BatchImportController.cs | TC-201, TC-202 | Pass, Blocked | — | — | Partial |
| REQ-044 | System shall log all data access for audit | H | FDD-AuditLog §1.3 | AuditLogMiddleware.cs | — | — | — | — | Broken |

---

## Bidirectional Linking Rules

Traceability links must be maintained in both directions:

| Direction | Purpose | Validation Question |
|-----------|---------|-------------------|
| **Forward (requirement → test)** | Ensures every requirement is verified | "Is there at least one test for every requirement?" |
| **Backward (test → requirement)** | Ensures every test has a purpose | "Does this test trace to a requirement? If not, is it testing something we don't need?" |
| **Upward (requirement → strategy)** | Ensures every requirement serves strategic intent | "Can I trace this requirement to a strategic theme or business objective?" |
| **Downward (strategy → requirement)** | Ensures strategy is decomposed into actionable requirements | "Does every strategic theme have requirements that implement it?" |

**Bidirectional integrity rule:** A link that exists in one direction must exist in the
other. A requirement that links to a test case means that test case must link back to
the requirement. Unidirectional links indicate a maintenance gap.

---

## Chain Integrity Metrics

| Metric | Formula | Target | Warning | Critical |
|--------|---------|--------|---------|----------|
| **Full Chain %** | (Requirements with complete chain from strategy to verification) / (Total requirements) | > 90% | 70-90% | < 70% |
| **Orphan Count** | Requirements with no upward trace to strategy | 0 | 1-3 | > 3 |
| **Dead-End Count** | Requirements with no downward trace to test cases | 0 | 1-5 (with documented rationale) | > 5 or any without rationale |
| **Untested Requirement Count** | Requirements with no linked test case | 0 for high priority | < 5% of total for medium priority | Any high-priority untested |
| **Purposeless Test Count** | Test cases with no linked requirement | 0 | < 3% of tests | > 3% (test suite has drift) |
| **Stale Link Count** | Links where one endpoint has been modified since link was last validated | 0 | < 10% of links | > 10% |

**Audit cadence:** Run chain integrity metrics at every major gate. Track trend over
time — declining integrity signals process decay.

---

## Investment Decision: When to Use Full RTM

| Context | Investment Level | Rationale |
|---------|-----------------|-----------|
| **Regulated industry** (FDA, SOX, HIPAA, government contracts, DO-178C, ISO 26262) | Full RTM — always required | Audit trail required; regulatory expectation; liability protection |
| **Complex multi-vendor integration** | Full RTM — valuable | Cross-vendor traceability prevents integration gaps; contract verification |
| **High-severity risk profile** | Full RTM — valuable | Impact of missed requirements justifies traceability investment |
| **Large Waterfall / Hybrid projects** | Full RTM — valuable | Phase-gated delivery needs bidirectional traceability across handoffs |
| **Small agile teams (< 10 people)** | Lightweight — tool-based linking | Acceptance criteria on stories provide implicit traceability; separate RTM is overhead |
| **Low-risk internal tools** | Lightweight — tool-based linking | Risk does not justify formal matrix investment |
| **Prototype / spike work** | None — intentionally skip | Throwaway work; traceability investment has zero return |
| **Agile at scale (SAFe)** | Hybrid — tooling + selective RTM for compliance items | 4-level backlog hierarchy provides implicit traceability; supplement with RTM for regulated features only |

**Agile alternative:** Embed traceability in tooling (backlog item → test case linking
in Jira/Azure DevOps) rather than maintaining a separate matrix document. This provides
the same linkage with lower maintenance cost. The tool IS the RTM.

---

## Governance Gate Artifact Evidence

Ten major gates with required artifact evidence and traceability implications:

| # | Gate | Required Artifacts | Traceability Check | Kill Signal |
|---|------|-------------------|-------------------|------------|
| 1 | Portfolio Intake | Intake form, preliminary business case | Trace to strategic theme exists | Zero alignment; no funding |
| 2 | Program Initiation | Detailed business case, charter, RACI | Trace from strategy through program charter | Business case fails scrutiny |
| 3 | Project Kickoff | Project plan, resource assignments, risk register | Requirements trace to program scope | Core team unavailable |
| 4 | Sprint DoR | INVEST criteria met; acceptance criteria defined | Story traces to feature; acceptance criteria testable | Deferred (not killed) |
| 5 | Dev Complete (DoD) | Code reviewed, tests >= 80% coverage, integration passing | All stories have linked test cases; all tests pass | Technical approach flawed |
| 6 | QA Gate | Test reports, coverage >= 80%, defect density < 0.5 P1+P2/KLOC | Full forward trace: requirement → test → result | Systemic architectural flaw |
| 7 | Release Readiness | QA sign-off, tested runbook, rollback validated | Full chain validated; no dead-ends for high-priority items | Critical staging defect |
| 8 | Go-Live | UAT sign-off, smoke test, data migration validation | Backward trace: every deployment artifact traces to tested requirement | Critical integration failure |
| 9 | Post-Implementation Review | PIR with objectives vs. actuals | Chain integrity metrics reported; gaps logged as lessons | N/A (retrospective) |
| 10 | Closure | Deliverable acceptance, final cost report, archived docs | Complete chain archived for audit; stale links resolved or documented | N/A (mandatory) |

**Governance health indicator:** A portfolio that never kills projects at gates is not
governing. Track gate decision distribution; target > 20% non-approvals as governance health.

---

## Methodology-Specific Implementation

| Aspect | Waterfall / PRINCE2 | Scrum | Kanban | SAFe | Hybrid |
|--------|-------------------|-------|--------|------|--------|
| **Traceability mechanism** | Formal RTM document (bidirectional, in DOORS or Jama Connect) | Implicit in backlog hierarchy: Epic → Feature → Story → Task/Test | Minimal; board state + explicit policies | Explicit 4-level hierarchy: Portfolio Epic → Capability → Feature → Story | RTM for compliance + backlog hierarchy for daily work |
| **Chain maintenance** | Dedicated role (BA or QA); reviewed at each gate | PO maintains backlog links; QA links tests to stories | Flow manager ensures commitment point criteria include traceability | Multiple altitudes maintain their own links; ART-level integration | BA maintains RTM upstream; team maintains backlog links downstream |
| **Audit artifact** | RTM document with version history | Tool export of backlog-test links | Board snapshot + policy documentation | Solution Intent + backlog exports | RTM + tool export (merged view) |
| **Refresh cadence** | Per gate (at each phase transition) | Per sprint (refinement and review) | Continuous (per item at delivery point) | Per PI (PI planning and I&A) | Per gate upstream; per sprint downstream |

---

## Anti-Patterns

| Anti-Pattern | Signal | Remediation |
|-------------|--------|-------------|
| **RTM created once, never updated** | Matrix created at project start; version unchanged at testing | Integrate RTM update into gate checklists; track stale link count |
| **Forward-only traceability** | Requirements link to tests but tests do not link back | Enforce bidirectional linking rule; audit backward trace at QA gate |
| **Traceability theater** | RTM exists but nobody consults it for decisions | Connect RTM to gate decisions; make chain integrity metrics a gate criterion |
| **Over-investment in low-risk projects** | Full RTM on a 3-person, 2-sprint project | Apply investment decision model; lightweight tool-based linking for low-risk |
| **Orphan accumulation** | Growing count of requirements with no strategic trace | Monthly orphan audit; every orphan gets classified (legitimate or trace-gap) |
