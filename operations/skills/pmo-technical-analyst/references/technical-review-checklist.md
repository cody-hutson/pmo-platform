# Technical Review Checklist — PMO Reference

## Purpose

This file provides the structured review checklists for technical artifacts across
all pmo-technical-analyst modes (A-E). Each checklist defines assessment criteria,
RAG scoring, and methodology-specific calibration. The skill reads this file on
invocation to apply the appropriate checklist to the artifact under review.

---

## Six-Dimension Technical Risk Assessment

Every technical deliverable carries risk across six dimensions. Assess each
independently using the RAG scoring below.

### RAG Scoring Definition

| Score | Color | Meaning | Action Required |
|-------|-------|---------|-----------------|
| **Green** | Low risk | Dimension is well-managed; no significant concerns | Monitor; no intervention |
| **Amber** | Medium risk | Dimension has identified concerns that are manageable with attention | Active mitigation plan required; track at project level |
| **Red** | High risk | Dimension has critical concerns that threaten delivery | Escalation required; mitigation plan with executive visibility |

### Dimension Assessment Criteria

#### 1. Integration Risk

| Criterion | Green | Amber | Red |
|-----------|-------|-------|-----|
| **Interface definition** | All interfaces documented with data contracts, protocols, error handling | Most interfaces defined; some gaps in error handling or edge cases | Interfaces undefined or incomplete; integration points discovered during testing |
| **Integration test coverage** | Automated integration tests for all critical interfaces; >80% path coverage | Integration tests exist for primary paths; edge cases untested | No integration tests; manual integration testing only |
| **Dependency stability** | All upstream/downstream systems stable; APIs versioned; no breaking changes expected | Some dependencies undergoing change; mitigation plans in place | Critical dependencies unstable; breaking changes expected; no mitigation |
| **Data mapping** | Complete field-level mapping between systems; transformation rules documented | Mapping exists but incomplete for non-critical fields | No formal mapping; data transformation logic undocumented |

#### 2. Data Risk

| Criterion | Green | Amber | Red |
|-----------|-------|-------|-----|
| **Data quality** | Source data profiled; quality metrics meet thresholds; cleansing rules defined | Data profiled but quality gaps identified; cleansing in progress | No data profiling; quality unknown; cleansing not planned |
| **Migration integrity** | Migration scripts tested with production-volume data; reconciliation automated | Migration tested with subset; reconciliation manual | Migration untested or tested with synthetic data only |
| **Data governance** | Ownership, retention, classification defined; PII/sensitive data identified and protected | Governance partially defined; PII identified but protection incomplete | No data governance; sensitive data handling unspecified |
| **Rollback capability** | Data rollback tested and validated; recovery point objectives met | Rollback plan exists but untested | No data rollback capability; schema changes are one-way |

#### 3. Performance Risk

| Criterion | Green | Amber | Red |
|-----------|-------|-------|-----|
| **Performance targets** | NFRs defined with specific thresholds (response time, throughput, concurrent users) | NFRs exist but vague ("the system should be fast") or incomplete | No performance requirements defined |
| **Load testing** | Load tested at 2x expected peak; results meet NFRs; bottlenecks identified and resolved | Load tested at 1x peak; results acceptable; some bottlenecks unresolved | No load testing; performance characteristics unknown |
| **Scalability assessment** | Architecture supports horizontal/vertical scaling; scaling tested | Architecture can scale but untested; theoretical assessment only | Architecture has known scaling limitations; no scaling path |
| **Monitoring** | Performance monitoring configured with alerting thresholds; baseline established | Monitoring exists but thresholds not calibrated; no baseline | No performance monitoring in place |

#### 4. Security Risk

| Criterion | Green | Amber | Red |
|-----------|-------|-------|-----|
| **Threat model** | Threat model completed; STRIDE or equivalent applied; mitigations implemented | Partial threat model; critical threats identified; some mitigations pending | No threat model; security considered ad hoc |
| **Vulnerability scanning** | SAST/DAST completed; zero critical/high vulnerabilities; scan integrated in CI/CD | Scans completed; critical vulnerabilities resolved; high vulnerabilities tracked | No vulnerability scanning; or critical vulnerabilities unresolved |
| **Authentication/authorization** | AuthN/AuthZ implemented per security architecture; tested including edge cases | AuthN/AuthZ implemented for primary flows; edge cases untested | AuthN/AuthZ incomplete or not implemented |
| **Secrets management** | All secrets in vault/secret manager; no hardcoded credentials; rotation policy defined | Most secrets managed; some legacy hardcoded items with remediation plan | Secrets in code or configuration files; no management infrastructure |

#### 5. Environment Risk

| Criterion | Green | Amber | Red |
|-----------|-------|-------|-----|
| **Environment parity** | Staging mirrors production (configuration, data volume, infrastructure) | Staging similar to production; known differences documented and assessed | Staging significantly different from production; "works on staging" unreliable |
| **Infrastructure-as-code** | All environments provisioned via IaC; configuration changes version-controlled | Most infrastructure as code; some manual components | Manual environment management; configuration drift between environments |
| **Deployment automation** | Fully automated deployment pipeline; no manual steps in standard path | Mostly automated; 1-2 manual steps documented | Significant manual deployment steps; deployment is error-prone |
| **Disaster recovery** | DR plan tested; RTO/RPO validated; failover tested | DR plan exists but untested; RTO/RPO defined but not validated | No DR plan; or DR plan with no testing |

#### 6. Operational Risk

| Criterion | Green | Amber | Red |
|-----------|-------|-------|-----|
| **Runbook completeness** | Operational runbooks cover all critical scenarios; tested by operations team | Runbooks exist for primary scenarios; operations team aware but not trained | No runbooks; or runbooks not reviewed by operations |
| **Monitoring and alerting** | Application and infrastructure monitoring configured; alert routing defined; escalation paths documented | Monitoring exists; alerting partially configured | No monitoring beyond basic infrastructure |
| **Support readiness** | L1/L2/L3 support model defined; knowledge transfer completed; support documentation available | Support model defined; knowledge transfer in progress | Support model undefined; no knowledge transfer planned |
| **Rollback tested** | Rollback procedure tested in staging; rollback time measured; data implications validated | Rollback plan documented but untested | No rollback plan; or rollback impossible due to data migration |

---

## FDD Review Checklist

For reviewing Functional Design Documents:

| Category | Criterion | Assessment Question |
|----------|-----------|-------------------|
| **Completeness** | Scope coverage | Does the FDD cover all requirements in scope? Can every requirement trace to an FDD section? |
| **Completeness** | Interface documentation | Are all system interfaces documented with data flows, protocols, and error handling? |
| **Completeness** | Non-functional requirements | Are NFRs (performance, security, availability) addressed, not just functional requirements? |
| **Consistency** | Internal consistency | Do different sections of the FDD agree? No contradictory statements? |
| **Consistency** | External consistency | Does the FDD align with the architecture document, integration specs, and upstream requirements? |
| **Technical clarity** | Implementation feasibility | Can a developer implement from this FDD without asking clarifying questions? |
| **Technical clarity** | Technology choices justified | Are technology decisions documented with rationale and alternatives considered? |
| **Dependency clarity** | Dependencies identified | Are all system, service, data, and organizational dependencies listed with status? |
| **Dependency clarity** | Dependency risks assessed | For each dependency, is the risk level assessed and a mitigation identified? |
| **Risk identification** | Technical risks named | Are technical risks explicitly identified with probability, impact, and response? |
| **Risk identification** | Assumptions documented | Are technical assumptions stated explicitly and flagged for validation? |

---

## FDD Quality Score

The qualitative FDD Review Checklist above answers *whether* each category is covered.
This section answers *how well* — it produces a single numeric quality score so an FDD's
completeness is **measured rather than asserted**. The score quantifies the same checklist
categories; it does not introduce a parallel review axis. The 5-point scale and the
PASS/CONDITIONAL/FAIL threshold gradient reuse the platform's established rubric format
(`core/skills/pmo-qa-auditor/references/push-to-resolve-rubric.md`) so technical-governance
scoring is consistent with the rest of the suite.

**Method:** Score each of the **6 dimensions** below on the 1–5 scale; the FDD quality
score is the **mean** of the six (1.0–5.0). Each dimension maps 1:1 onto a category already
in the FDD Review Checklist (dimensions 1–5), with **Operational-readiness coverage** added
as dimension 6 to bind FDD scoring to the skill's 6-dimension risk model and the
Rollback-Trigger Gate below.

| # | Dimension (← checklist category) | 5 (Exemplary) | 3 (Marginal) | 1 (Failure) |
|---|---|---|---|---|
| 1 | **Completeness** (scope + interface + NFR coverage) | Every in-scope requirement traces to a section; all interfaces + NFRs documented | Functional scope covered; NFRs or some interfaces missing | Scope gaps; no NFRs |
| 2 | **Consistency** (internal + external) | No contradictions; aligns with architecture + integration specs | Minor unreconciled differences | Contradictory sections |
| 3 | **Technical clarity** (implementability + justified choices) | A dev implements with zero clarifying questions; choices justified | Implementable with some questions | Ambiguous; not implementable as written |
| 4 | **Dependency clarity** (identified + risk-assessed) | All deps listed with status + risk + mitigation | Deps listed, risks not assessed | Deps undocumented |
| 5 | **Risk identification** (named + assumptions flagged) | Risks named w/ probability·impact·response; assumptions flagged for validation | Some risks named; assumptions implicit | No risk section |
| 6 | **Operational-readiness coverage** (failure paths, rollback, monitoring) | Failure modes, rollback, monitoring all addressed | Happy path only; rollback/monitoring thin | No failure-path content |

Score 2 and 4 are the intermediate points between the anchors above (2 = closer to Failure;
4 = closer to Exemplary), scored on the same evidence basis as the named anchors.

**Score thresholds** (mirrors push-to-resolve-rubric PASS/CONDITIONAL/FAIL):

| Band | Mean | Disposition |
|---|---|---|
| **READY** | ≥ 4.0 | FDD is implementation-ready; proceed |
| **CONDITIONAL** | 3.0–3.9 | Targeted remediation on the sub-4 dimensions before build; gaps enumerated as drafted ACs |
| **NOT READY** | < 3.0 | Fundamental rework; do not pass to Engineering |

**Push-to-resolve binding (mandatory).** The score is a **decision-class output** — it gates
downstream build — so it carries a reversibility tier + confidence per the skill's
Reversibility Discipline (a NOT-READY verdict is typically `MODERATE · confidence: …`).
**Every sub-4 dimension MUST emit a drafted per-dimension remediation** (a drafted AC, NFR,
or gap entry the technical owner can confirm in one sentence). A bare mean with no
per-dimension gap drafts is a task dump, not a review — see the
`## Domain-Specific Failure Modes` guard in SKILL.md.

---

## Rollback-Trigger Gate

Applies whenever a reviewed artifact contains a rollback plan — an FDD operational section,
an architecture deployment strategy, or an SOP. It sharpens the Operational-dimension
"Rollback tested" checklist row from *"tested?"* to *"tested **and** numerically triggered?"*.
A rollback plan is only executable under incident pressure if its triggers are
**quantitative**: a trigger is acceptable only when it names a **metric + a numeric threshold
+ a window**.

| Trigger form | Verdict | Example |
|---|---|---|
| Metric + numeric threshold + window | **PASS** | "Roll back if error rate > 2% sustained over 5 min" |
| Qualitative / subjective | **REJECT → request numeric threshold** | "Roll back if the system seems unstable" / "if there are problems" |
| Absent | **REJECT → rollback plan incomplete** | (no trigger stated) |

**On REJECT, push-to-resolve:** draft the quantitative trigger — propose an industry-default
starting value and flag the threshold `[ASSUMPTION – CONFIRM]` with the technical owner; never
leave it open. A rollback-gate rejection is decision-class → carry a reversibility tier +
confidence label. This gate also ties to the Mode D destructive-operation rollback check and
the Change-failure-rate DORA metric below.

---

## DORA Metric Awareness

When a reviewed artifact describes a deployment or operational surface, the skill **names the
relevant DORA (Accelerate) metric(s)** alongside the finding and flags where the design does
or does not make that metric **measurable**. This is an **awareness surface, not a measurement
surface** — the skill names the metric and assesses measurability; it does **not compute DORA
values** (computing telemetry is a separate, out-of-scope concern). No in-corpus authoritative
4-metric list exists to cite; the set below is the industry-standard four
(`[ASSUMPTION – CONFIRM]` against the canonical Accelerate definition).

| DORA metric | What the skill surfaces in a review | Ties to |
|---|---|---|
| **Deployment frequency** | Does the architecture/deployment strategy support the target release cadence? | "Deployment strategy" checklist row |
| **Lead time for changes** | Does the design's build/test/deploy path keep change lead-time bounded? | CI/CD + deployment-automation rows |
| **Change failure rate** | Is there a measurable quality gate that bounds the % of changes causing incidents? | Rollback-Trigger Gate above |
| **Mean time to restore (MTTR)** | Is recovery instrumented — detection + automated/manual restore path? | "Recovery strategy" + monitoring rows |

**Boundary statement:** surface awareness (name the metric + flag whether the design makes it
measurable); do **not** compute the metric's value. A finding reads "the deployment strategy
does not bound change failure rate — no quality gate caps incident-causing changes
[Change failure rate, not measurable as designed]", not a computed percentage.

---

## Integration Spec Review Checklist

For reviewing integration specifications and interface designs:

| Category | Criterion | Assessment Question |
|----------|-----------|-------------------|
| **Interface completeness** | All interfaces identified | Are all system-to-system interfaces documented? Cross-reference with architecture diagram. |
| **Interface completeness** | Data contract defined | For each interface: request/response schemas, field mappings, data types, required vs. optional? |
| **Protocol compliance** | Protocol specified | REST/SOAP/gRPC/file transfer/messaging — protocol and version documented? |
| **Protocol compliance** | Authentication mechanism | How does each system authenticate to the other? Token, certificate, API key, OAuth? |
| **Error handling** | Error taxonomy | What error types can occur? HTTP status codes, business errors, timeout, circuit breaker? |
| **Error handling** | Retry strategy | For transient failures: retry count, backoff strategy, dead letter queue? |
| **Error handling** | Graceful degradation | What happens when a dependency is unavailable? Fallback behavior documented? |
| **Data mapping** | Field-level mapping | Complete mapping from source to target fields with transformation rules? |
| **Data mapping** | Data volume and frequency | Expected data volume per transaction and per batch? Peak load estimates? |
| **Testing approach** | Integration test plan | How will the integration be tested? Contract testing, end-to-end, mock services? |

---

## Architecture Review Checklist

For reviewing architecture decisions and system designs:

| Category | Criterion | Assessment Question |
|----------|-----------|-------------------|
| **Scalability** | Horizontal scaling | Can the system scale horizontally? What are the scaling limits? |
| **Scalability** | Performance under load | Is there evidence of performance at target scale? Load test results? |
| **Security** | Attack surface | Is the attack surface minimized? Are all entry points documented? |
| **Security** | Data protection | Are data-at-rest and data-in-transit encryption requirements met? |
| **Operational readiness** | Monitoring strategy | Is the monitoring architecture defined? Metrics, logs, traces (observability triad)? |
| **Operational readiness** | Deployment strategy | Is the deployment strategy appropriate for the architecture (Blue-Green, Canary, Rolling, Feature Flags)? |
| **Dependency clarity** | External dependencies | Are all external dependencies (third-party services, libraries, infrastructure) documented with SLAs? |
| **Dependency clarity** | Internal dependencies | Are service-to-service dependencies mapped? Is the dependency graph acyclic? |
| **Resilience** | Failure modes identified | Are failure modes analyzed? Blast radius documented? |
| **Resilience** | Recovery strategy | For each failure mode: detection mechanism, automated recovery, manual escalation criteria? |

---

## Methodology Variation

| Aspect | Waterfall / V-Model | Agile / Scrum | SAFe | Hybrid |
|--------|-------------------|---------------|------|--------|
| **Testing alignment** | V-Model: unit ↔ detailed design, integration ↔ architecture, system ↔ requirements, UAT ↔ business needs; sequential phases | Continuous within sprint; TDD for unit, integration in CI pipeline, E2E selective | Per-iteration + System Demo (biweekly) + PI-level I&A; layered DoD | Per-stream testing + integration points at phase boundaries |
| **Review formality** | Formal reviews at phase gates; documented sign-off required; steering committee approval | Peer review via PR; Sprint Review for acceptance; informal architecture discussions | Architect review at PI Planning; System Demo for integration; I&A for retrospective | Formal at phase gates; informal within sprints; dual governance |
| **CI/CD integration** | No CI (big-bang integration at test phase); build automation may exist but not continuous | CI required; CD optional but recommended; 10-minute build target (XP) | Continuous Delivery Pipeline (Explore → Integrate → Deploy → Release on Demand) | Limited CI within agile streams; integration at phase boundaries |
| **Risk review cadence** | At each phase gate (monthly-quarterly) | Sprint Retrospective (every 1-4 weeks); continuous in daily standup | PI Planning (quarterly); ART Sync (weekly); I&A (quarterly) | Phase gate (quarterly) + sprint retro (biweekly) |
| **Technical debt tracking** | Accumulated during build phase; addressed in maintenance | Managed in backlog; 15-20% sprint capacity reserved | Enabler Stories/Features; Architectural Runway; 20-30% enabler capacity | Often underfunded (known gap); recommend 10-20% capacity allocation |

---

## Anti-Patterns

| Anti-Pattern | Signal | Impact | Remediation |
|-------------|--------|--------|-------------|
| **Review without criteria** | Review completed with "looks good" but no checklist applied | Defects pass through; review provides false confidence | Apply appropriate checklist from this file; require substantive comments |
| **Single-dimension review** | Only security or only performance reviewed; other dimensions ignored | Unreviewed dimensions carry unmanaged risk | Require all 6 dimensions assessed; accept "N/A with rationale" for non-applicable dimensions |
| **Late review** | Technical review happens after implementation is complete | Review findings require rework; Boehm cost escalation applies | Shift review left: review designs before implementation begins |
| **Review without action** | Findings documented but no remediation tracked | Known risks accepted without decision; accountability gap | Every finding requires disposition: fix, accept with rationale, or escalate |
| **Checklist without judgment** | All items checked "Green" without evidence or analysis | Coverage theater; checklist provides false assurance | Require evidence for each assessment; RAG must be justified, not defaulted |
