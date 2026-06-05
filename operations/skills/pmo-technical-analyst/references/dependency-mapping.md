# Dependency Mapping — PMO Reference

## Purpose

This file provides the methodology for identifying, classifying, visualizing,
tracking, and resolving dependencies across projects, programs, and portfolios.
The pmo-technical-analyst skill reads this file in Mode E (Dependency Mapping)
to perform structured dependency analysis.

---

## Dependency Mapping Methodology

Dependency mapping follows a five-stage process. Each stage produces artifacts
that feed the next.

### Stage 1: Identification

**Objective:** Discover all dependencies — declared and latent.

| Method | Description | Finds | Misses |
|--------|-------------|-------|--------|
| **Artifact cross-reference** | Scan FDDs, integration specs, architecture docs, and project plans for references to external systems, teams, or deliverables | Documented dependencies; interface-level dependencies | Undocumented tribal knowledge; organizational dependencies |
| **Stakeholder interviews** | Ask team leads and architects: "What could block you that is not under your control?" | Organizational dependencies; vendor dependencies; political dependencies | Dependencies the team does not yet know about |
| **Architecture diagram analysis** | Review system architecture for integration points, shared services, shared data stores | System-to-system dependencies; data dependencies | Timing dependencies; environmental dependencies |
| **Backlog/plan mining** | Scan sprint backlogs, PI plans, and project plans for items with external prerequisites | Execution-level dependencies; cross-team handoffs | Strategic dependencies; long-lead-time dependencies |
| **Historical pattern analysis** | Review past project retrospectives and issue logs for dependency-related failures | Recurring dependency patterns; organizational bottlenecks | Novel dependencies in new technology or vendor contexts |

**Completeness check:** A dependency inventory is never complete. Re-run identification
at every planning boundary (PI Planning, sprint boundary, phase gate). New dependencies
emerge as work progresses.

### Stage 2: Classification

Every identified dependency is classified along two axes: type and criticality.

**Dependency Types:**

| Type | Definition | Examples | Typical Owner |
|------|-----------|----------|---------------|
| **System-to-system** | Technical dependency between software systems | API integration, shared database, message queue, file exchange | Technical Architect / Integration Lead |
| **Service-to-service** | Dependency on a shared service or platform capability | Authentication service, notification service, reporting platform | Platform team / Service owner |
| **Data** | Dependency on data availability, quality, or format from another source | Data migration from legacy, master data from MDM, reference data | Data Architect / Data Owner |
| **Vendor** | Dependency on an external vendor deliverable, timeline, or decision | Vendor API availability, vendor bug fix, vendor configuration | Vendor Manager / PM |
| **Environmental** | Dependency on infrastructure, environment, or tooling availability | Test environment, deployment pipeline, license availability | Infrastructure / DevOps |
| **Organizational** | Dependency on a person, team, decision, or organizational action | SME availability, executive approval, cross-team resource sharing | PM / Resource Manager |
| **Temporal** | Dependency on timing or sequencing that cannot be parallelized | Data freeze before migration, code freeze before release, training before go-live | PM / Release Manager |

**Criticality Classification:**

| Level | Definition | Consequence if Unresolved | Escalation Trigger |
|-------|-----------|--------------------------|-------------------|
| **Critical** | Blocks delivery entirely; no workaround exists | Project/program milestone at risk; work cannot proceed | Immediate escalation to program level; 24-hour resolution SLA |
| **High** | Significantly impacts delivery; workaround exists but is costly | Schedule delay; quality compromise; increased cost | Escalation within 48 hours; weekly tracking |
| **Medium** | Affects delivery but manageable within normal planning | Minor delay; scope adjustment possible | Track at project level; escalate if unresolved in 1 week |
| **Low** | Informational; dependency exists but is not currently at risk | Minimal impact if delayed; alternatives available | Monitor; no active escalation |

### Stage 3: Visualization

Dependencies must be visual to be manageable. Different visualization formats
serve different audiences and purposes.

| Format | Description | Best For | Audience |
|--------|-------------|----------|----------|
| **Dependency Matrix** | Grid showing source (rows) vs. target (columns) with dependency type/criticality in cells | Identifying all pairwise dependencies; detecting clusters and hotspots | Technical teams; architects; PM |
| **Network Diagram** | Nodes (systems/teams/deliverables) connected by directed edges (dependencies) with edge labels | Understanding dependency chains; identifying critical paths; spotting circular dependencies | Program managers; stakeholders; steering committee |
| **Program Board** | Physical or digital board with team swim lanes and dependency threads (strings/lines) connecting items across lanes | SAFe PI Planning; cross-team sprint planning; visual dependency negotiation | Teams during planning events; RTE/SM |
| **Timeline / Gantt Overlay** | Dependencies overlaid on project timeline showing which deliverables must complete before others can start | Schedule impact analysis; critical path identification; milestone dependency tracking | PM; steering committee; portfolio |
| **Directed Acyclic Graph (DAG)** | Formal graph structure with no cycles; nodes = work items, edges = precedence relationships | Automated analysis; topological sorting; blast radius computation | Platform engineering; automated dependency validation |

**Visualization selection logic:**
- If audience is technical → Dependency Matrix or DAG
- If audience is management → Network Diagram or Timeline Overlay
- If context is planning event → Program Board
- If context is automated validation → DAG

### Stage 4: Tracking

Active dependency tracking prevents known dependencies from becoming surprise blockers.

| Field | Description | Required? |
|-------|-------------|-----------|
| **Dependency ID** | Unique identifier (DEP-001, DEP-002) | Yes |
| **Description** | Clear statement of the dependency | Yes |
| **Type** | Classification from Stage 2 type taxonomy | Yes |
| **Criticality** | Classification from Stage 2 criticality scale | Yes |
| **Source** | The deliverable/team/system that needs the dependency resolved | Yes |
| **Target** | The deliverable/team/system that must provide or resolve the dependency | Yes |
| **Owner** | Named individual responsible for dependency resolution | Yes |
| **Status** | Current state: Identified → Tracked → At Risk → Resolved / Accepted | Yes |
| **Needed By Date** | Date by which the dependency must be resolved to avoid impact | Yes |
| **Last Reviewed** | Date of most recent status review | Yes |
| **Escalation History** | Record of escalations with dates and outcomes | If escalated |
| **Resolution** | How the dependency was resolved (or accepted with rationale) | When resolved |

**Status Definitions:**

| Status | Definition | Required Action |
|--------|-----------|-----------------|
| **Identified** | Dependency discovered but not yet assessed or assigned | Classify (type + criticality); assign owner; set needed-by date |
| **Tracked** | Assigned, classified, actively monitored; on track | Review at regular cadence; no intervention needed |
| **At Risk** | Resolution timeline threatened; may impact delivery | Active mitigation; escalation per SLA (48h team, 1wk program, 2wk portfolio) |
| **Unverified** | Dependency assumed resolved but not confirmed | Verification action required; do not treat as resolved until confirmed |
| **Resolved** | Dependency confirmed resolved; deliverable available | Close tracking; document resolution for lessons learned |
| **Accepted** | Dependency will not be resolved; impact accepted with rationale | Document business rationale; communicate accepted impact to stakeholders |

### Stage 5: Resolution

Resolution strategies depend on dependency type and criticality:

| Strategy | Description | When to Use |
|----------|-------------|-------------|
| **Eliminate** | Remove the dependency by redesigning the approach | Dependency is high-risk and an alternative approach exists |
| **Absorb** | Bring the dependent capability in-house or within the team | External dependency is unreliable; team has capacity |
| **Decouple** | Use interfaces, mocks, or stubs to allow parallel progress | Teams need to work independently; dependency is on a timeline |
| **Negotiate** | Agree on delivery timeline, format, and quality with the dependency provider | Organizational or vendor dependencies with cooperative parties |
| **Escalate** | Raise to higher authority for resolution when negotiation fails | Dependency resolution blocked; requires authority intervention |
| **Accept** | Document the dependency risk and proceed with mitigation plan | Dependency cannot be eliminated or decoupled; risk is acceptable |

**Escalation SLA triggers:** [SOURCE: C02 §3.5]
- Team-level unresolved > 48 hours → escalate to program
- Program-level unresolved > 1 week → escalate to portfolio
- Portfolio-level unresolved > 2 weeks → escalate to executive

---

## Cross-Artifact Dependency Detection

Detect dependencies by cross-referencing artifacts rather than relying solely on
declaration. Dependencies live in the artifacts even when nobody has explicitly
identified them.

| Artifact Pair | Detection Method | Dependency Signal |
|--------------|------------------|-------------------|
| **FDD ↔ FDD** | Scan for references to the same system, API, or data entity across different FDDs | Two FDDs reference the same integration point = potential dependency |
| **FDD ↔ Integration Spec** | Cross-reference FDD system interfaces with integration spec endpoints | FDD assumes an interface that the integration spec does not define = gap dependency |
| **Architecture Doc ↔ FDD** | Validate that FDD technical decisions align with architecture constraints | FDD proposes a technology not in the approved architecture = decision dependency |
| **Project Plan ↔ Project Plan** | Cross-reference milestone dates and deliverables across project plans | Project A milestone depends on Project B deliverable = timeline dependency |
| **Sprint Backlog ↔ Sprint Backlog** | Scan for cross-team stories or shared service dependencies in parallel sprints | Team A story requires Team B API that is also in-sprint = execution dependency |
| **Risk Register ↔ Dependency Log** | Cross-reference risk entries mentioning external factors with dependency inventory | Risk entry describing external dependency not in dependency log = undeclared dependency |

---

## Blast Radius Computation

For any proposed change, compute the blast radius — the set of all artifacts,
systems, and teams that could be affected through transitive dependencies.

**Algorithm:** [SOURCE: C17]
1. Identify the changed artifact/system/deliverable (the root node)
2. Find all artifacts that directly depend on the root (first-order dependencies)
3. For each first-order dependency, find all artifacts that depend on IT (second-order)
4. Continue until no new dependencies are found (transitive closure)
5. The complete set = blast radius

**Blast radius determines review scope:**

| Blast Radius | Review Scope | Approval Level |
|-------------|-------------|----------------|
| **Contained** (1-3 artifacts, single team) | Team-level review | Team lead / SM |
| **Cross-team** (4-10 artifacts, 2-3 teams) | Cross-team review; affected teams notified | PM / RTE |
| **Program-wide** (10+ artifacts, 4+ teams) | Program-level review; impact assessment required | Program Manager / Steering Committee |
| **Portfolio-wide** (cross-program impact) | Portfolio-level review; executive notification | Portfolio Manager / Executive |

---

## Anti-Patterns

| Anti-Pattern | Signal | Impact | Remediation |
|-------------|--------|--------|-------------|
| **Dependency discovery at integration** | Dependencies found during testing, not planning | Late discovery = expensive rework; schedule impact | Run dependency identification at every planning boundary; use cross-artifact detection |
| **Single-owner dependency tracking** | One person tracks all dependencies; tracking stops when they are unavailable | Hero dependency; bus factor = 1 | Distribute ownership; each dependency has its own owner; program-level aggregation view |
| **Declared but untracked** | Dependencies identified during PI Planning but never reviewed again | Identified dependencies become surprise blockers | Weekly dependency review cadence; aging report for "Identified" status items |
| **Circular dependencies** | A depends on B which depends on C which depends on A | Deadlock; no team can proceed | Break the cycle with mocks, stubs, or interface contracts; redesign if necessary |
| **Optimistic dependency status** | Dependencies reported as "on track" without verification | False confidence; "green until suddenly red" | Require verification evidence for "Tracked" status; "Unverified" status for assumptions |
| **Blast radius blindness** | Changes reviewed in isolation without computing transitive impact | Downstream breakage discovered after deployment | Compute blast radius for every proposed change; scope review to blast radius |
