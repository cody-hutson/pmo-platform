---
title: Orchestration Mechanisms — Comparative Survey
purpose: Comparative research survey of named agent-orchestration mechanisms across a defined contract interface and a coordination problem-class taxonomy — the evidence base the platform's stalled orchestration decisions need in order to become decidable.
type: discipline
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
composes_with: actor-model-and-governance-as-contract.md, corpus-curation.md, knowledge-architecture.md
parallel_to: architecture-evaluative-lens.md
domain: governance
---
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->

# Orchestration Mechanisms — Comparative Survey

This document is a **comparative survey**, not a standard. It enumerates named agent-orchestration mechanisms, characterizes each against a common contract interface, and maps which coordination problem classes each mechanism actually serves. It **prescribes nothing**: it selects no mechanism, defines no configuration field, and changes no skill. Its warrant is narrower and more specific than "a survey exists" — see §1.

The mechanisms surveyed here are **objects of study**. The platform adopts none of them in this release. That distinction governs the framework-catalog reconciliation in §4 and the deferrals in §7.

---

## 1. Purpose, Scope, and Method

### 1.1 Why this artifact exists

The platform's target operating model — [`actor-model-and-governance-as-contract.md`](actor-model-and-governance-as-contract.md) — carries five open sub-decisions. Two of them are stalled for want of evidence rather than for want of argument:

- **D3 — *Orchestration-as-Skill vs. Orchestration-as-Agent*.** Marked `[DEFERRED]` in that document's own words because *"its only current seed is itself forward-looking."* It has no non-forward-looking evidence base.
- **D5 — *Migration Path from Hub-Spoke*.** Unratified. Its Now/Next/Later table is asserted prose whose "Today (hub-spoke)" column is **unmeasured**, so no sequencing claim is grounded and no migration cost is known.

**This artifact's success condition is that D3 and D5 become *renderable* — not that a comprehensive survey exists.** A survey that is thorough and leaves both decisions exactly as stuck is a failed deliverable. §6 states, per decision, what it needs and what this artifact supplies; that section is the primary acceptance surface.

### 1.2 Scope boundary

| In scope | Out of scope |
|---|---|
| Named coordination mechanisms and their contract-dimension values | Selecting a mechanism for the platform |
| A problem-class taxonomy with mechanism-fit mapping | Designing a selection layer, resolution algorithm, or schema |
| The incumbent's measured current-state values | Declaring or naming any configuration field |
| Rules that would *bound* a future selection layer | Changing any consumer skill |

### 1.3 Method

**Evidence rubric — reused, not invented.** This survey grades evidence on the platform's existing five-tier vocabulary **ET1–ET5** and its evidence labels, both defined in [`corpus-curation.md`](corpus-curation.md) §1 and §4. No tier and no label is minted here; a parallel rubric would be duplicate-source debt. This document adds only two bindings on top of that vocabulary:

> **Minimum-grade rule.** A claim is **load-bearing only at ET1–ET3**. ET4 (platform-internal observed pattern) is load-bearing **only** for internal current-state claims, never for a claim about the external design space. **ET5 is never load-bearing on its own** — it may corroborate or illustrate an ET1–ET3 claim, and only with its mandatory paired contraindication. No SWOT quadrant rests solely on ET4 plus ET5.

> **Citation-identity rule.** Every external citation carries **author or issuing body + year + venue or publisher**, so it resolves without a live URL. A bare link is not a citation. Internal claims instead carry a re-runnable probe against a stated baseline.

**Sampling frame — survey-anchored, not author-enumerated.** The candidate set was built from published survey and taxonomy sources **first**, then unioned with the platform's own vernacular. That ordering is deliberate: enumerating from the incumbent's vocabulary first would have produced a set that flatters the incumbent.

**Dimension ordering.** §2's dimensions were derived from external sources **first**, and the incumbent's value filled in **second** — never the reverse. A dimension with no external attestation is a feature of the incumbent, not a contract dimension, and was dropped.

**A note on presentation order.** §3 presents the surveyed set before §4 states the inclusion criteria. That is a **presentation** order fixed by this artifact's required section structure; the **derivation** order was criteria-first. §4 states the criteria and records every exclusion with its reason, so the selection remains auditable independent of reading order.

### 1.4 Validity threats, declared before the findings

| # | Threat | Mitigation applied |
|---|---|---|
| VT-1 | **Selection bias toward the incumbent** — a set chosen to make hub-spoke look sufficient | Frame built survey-first; §4 criteria stated and applied explicitly; hard requirement that ≥2 mechanisms differ from the incumbent on ≥3 dimensions |
| VT-2 | **Coverage gap** — contemporary agent patterns are young and vendor-dominated; ET1/ET2 sourcing is thin | **Antecedent-anchoring** (below): each modern mechanism anchored to a classical structural antecedent carrying ET1/ET2 sourcing |
| VT-3 | **Reproducibility** — external citations cannot be re-run like a probe | Citation-identity rule for external claims; re-runnable probe plus baseline for internal claims |
| VT-4 | **Incumbent-framing bias** — deriving dimensions *from* hub-spoke guarantees the incumbent satisfies its own contract | Dimension-ordering constraint above; every dimension carries an external attestation |
| VT-5 | **Warrant pressure to over-deliver** — the artifact exists to unblock D3/D5, creating pressure to *resolve* them | §6 states what each decision *needs*; §7 states the no-encroachment boundary |
| VT-6 | **Alias collapse** — treating the platform's "hub-spoke" and the literature's "centralized / star / orchestrator-worker" as distinct, double-counting the incumbent | One coordination semantics equals one mechanism; alias sets recorded in §3 |

> **Antecedent-anchoring rule.** A mechanism whose contemporary instantiation is sourced below ET3 **must** be anchored to a named classical structural antecedent carrying ET1/ET2 sourcing. The three-citation bar is then met as *≥1 ET1/ET2 on the antecedent structure + ≥2 attesting the contemporary instantiation* — never by treating a vendor engineering post as peer-reviewed.

---

## 2. The Orchestration Contract — Twelve Dimensions

A **contract dimension** is a question with at least two different answers across mechanisms. A candidate that every mechanism answers identically is not a dimension and was dropped or merged.

Each dimension below carries three fields: a **definition**, an **external attestation** that it is a real axis, and the **current-state value for hub-spoke** — the platform's incumbent mechanism. Internal values are `[EMERGENT]` per the evidence-label extension and are sourced to [`hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md) at baseline `origin/main` for the release that introduces this document; section names are cited in preference to line numbers because sections survive edits that line numbers do not.

| # | Dimension | Definition | External attestation | Hub-spoke current-state value `[EMERGENT]` |
|---|---|---|---|---|
| **DIM-1** | **Control locus / dispatch determinism** | Is the next-actor decision **computed from state**, or **inferred by judgment**? | Control-hierarchy axis, `[CONSENSUS: Moore 2025, arXiv preprint 2508.12683]`; control-distribution dimension, `[EMPIRICAL: Horling & Lesser 2005, Knowledge Engineering Review 19(4)]` | **Judgment-inferred.** The hub reads the release plan's Implementation Sequence and renders a routing decision per § *Procedure 2: Routing*; the verdict is not computed from a state predicate. |
| **DIM-2** | **Communication topology** | Who may talk to whom — star, mesh, broadcast, or chain? | Communication-structure axis, `[CONSENSUS: Moore 2025]`; paradigm topologies, `[EMPIRICAL: Horling & Lesser 2005]` | **Star, strictly.** Spokes never address one another; all inter-stage content passes through durable thread comments the hub reads (§ *Procedure 4*). |
| **DIM-3** | **Task-allocation mechanism** | Is work **assigned**, **bid for**, or **self-selected**? | Negotiation-based allocation, `[FRAMEWORK: Smith 1980, IEEE Transactions on Computers C-29(12):1104–1113]`; markets paradigm, `[EMPIRICAL: Horling & Lesser 2005]` | **Pre-planned assignment.** The hub assigns from a Stage-4 Implementation Sequence. No bidding, no capability advertisement, no award step. |
| **DIM-4** | **State-sharing substrate** | Where does shared state live — private messages, a shared workspace, or a durable ledger? | Blackboard data structure as an explicit architectural part, `[EMPIRICAL: Nii 1986, AI Magazine 7(2)]`; shared-resource dependency, `[EMPIRICAL: Malone & Crowston 1994, ACM Computing Surveys 26(1):87–119]` | **Durable ledger.** The work-item body is the single source of truth and the thread is the stage-I/O channel (§ *Procedure 3*); ephemeral chat-resident prompt blocks are explicitly rejected as a parallel tracking surface. |
| **DIM-5** | **Concurrency posture** | May participants act simultaneously, and what serializes them? | Parallel-split and synchronization patterns, `[FRAMEWORK: van der Aalst et al. 2003, Distributed and Parallel Databases 14:5–51]`; shared-resource dependency, `[EMPIRICAL: Malone & Crowston 1994]` | **Per-stage, not global.** Solutioning and the two testing stages are parallel-safe; Engineering and Close are write-serialized. Default posture is fully-serial when undeclared (§ *Parallelism Rules per Stage*, and [`parallelism-posture-taxonomy.md`](../../release/references/standards/parallelism-posture-taxonomy.md)). |
| **DIM-6** | **Isolation boundary** | Does a participant get its own execution context and workspace? | Resource-contention failure class, `[FRAMEWORK: Cemri et al. 2025, arXiv preprint 2503.13657]`; organizational-boundary treatment, `[EMPIRICAL: Horling & Lesser 2005]` | **Per-spoke source-control worktree isolation**, provisioned at spawn. Nesting a worktree inside a spoke's own worktree is prohibited; a spoke detects its location first, then branches (§ *Worktree discipline*). |
| **DIM-7** | **Handoff / commitment protocol** | How is a transfer of work pledged, and how is the pledge monitored? | Commitments and conventions as the foundation of coordination, `[FRAMEWORK: Jennings 1993, Knowledge Engineering Review 8(3):223–250]`; standardized interaction protocols, `[CONSENSUS: FIPA Contract Net Interaction Protocol SC00029, 2002]` | **Two-channel, asymmetric.** A closed-enum four-field return value carries **routing only**; all content, findings, and rationale travel on the durable thread comment (§ *Return Value to Hub*). A spoke never closes its own sub-task. |
| **DIM-8** | **Observability / audit trail** | Is the coordination history durably inspectable after the fact? | Task-verification failure category, `[FRAMEWORK: Cemri et al. 2025]`; organizational-performance measurability, `[EMPIRICAL: Horling & Lesser 2005]` | **Durable and external.** Every stage's output persists as a thread comment plus a pipeline event-log row; the record outlives the session that produced it. |
| **DIM-9** | **Failure containment and recovery** | What survives when a participant dies mid-task? | Robustness and load-balancing trade-offs across middle-agent types, `[FRAMEWORK: Decker, Sycara & Williamson 1997, IJCAI-97]`; robustness criterion, `[EMPIRICAL: Horling & Lesser 2005]` | **Committed work survives; the report does not.** A spoke that terminates after pushing leaves its artifacts intact and its narrative lost — witnessed in this artifact's own release, where a sibling spoke's Stage-6 record had to be hub-reconstructed from commit messages. Resume-of-a-completed-spoke is unreliable; the remedy is a fresh spawn. |
| **DIM-10** | **Trust boundary on inputs** | Which inputs are authoritative, and how is that decided? | Specification-issue and inter-agent-misalignment failure categories, `[FRAMEWORK: Cemri et al. 2025]`; agent-communication semantics, `[CONSENSUS: FIPA Agent Communication Language specifications, 2002]` | **Authorship-scoped, not position-scoped.** Thread comments are stage input only when authored by a trusted set; selection by thread position is explicitly rejected because an external party can occupy any position (§ *Comment-Ingestion Trust Boundary*). |
| **DIM-11** | **Resource envelope** | Is there a shared budget that concurrency draws down? | Resource-contention failure class, `[FRAMEWORK: Cemri et al. 2025]`; token-cost multiple of multi-agent over single-agent operation, `[EXPERT-OPINION: Anthropic Engineering 2025, "How we built our multi-agent research system"; paired contraindication in §3 MECH-1]` | **Shared and cumulative.** Concurrent spokes draw cumulatively against one per-account usage window even when they have no file-contention surface; a budget check fires before **every** launch, including a single serial one (§ *Quota check before parallel launch*). |
| **DIM-12** | **Bottleneck locus** | Where does the mechanism stop scaling? | Scalability and computational-cost criteria, `[EMPIRICAL: Horling & Lesser 2005]`; layered-abstraction motivation for hierarchy, `[CONSENSUS: Moore 2025]` | **The hub itself.** Every routing decision, every content read, and every gate verdict passes through one session's context and attention; adding spokes does not add routing capacity. |

**Dimension-set note (VT-4 audit).** Every dimension above carries an external attestation predating and independent of the platform's own design. Three candidate axes were **dropped** for failing that test: *sub-task granularity*, *chip-prompt length*, and *stage-numbering convention* — each is an implementation property of the incumbent with no external attestation as a coordination axis, and each collapses to a single value across the surveyed mechanisms.

---

## 3. Mechanism Survey — SWOT per Mechanism

Eight mechanisms survive §4's criteria. Each carries an alias set (VT-6), a citation register meeting the three-citation bar with at least one ET1/ET2 source, and a SWOT mapped against §2's dimensions. **Strengths and weaknesses are intrinsic** to the mechanism; **opportunities and threats are contingent** on the adopting context — here, the pmo-platform release pipeline.

### MECH-1 — Centralized orchestration (the incumbent)

**Aliases:** hub-spoke · star · orchestrator-worker · centralized coordination · lead-agent-with-subagents.

**Citations (3).** `[EMPIRICAL: Horling & Lesser 2005, Knowledge Engineering Review 19(4):281–316]` — surveys centralized/hierarchical control and its quantitative performance effects. `[CONSENSUS: Moore 2025, arXiv preprint 2508.12683]` — control-hierarchy and communication-structure axes. `[EXPERT-OPINION: Anthropic Engineering 2025, "How we built our multi-agent research system"; **contraindication:** a single vendor's engineering report on one workload, reporting roughly an order-of-magnitude token multiple over single-agent operation — its accuracy claims do not generalize to a governance pipeline and are not load-bearing here]`. Antecedent-anchored: the ET1 source attests the *structure*; the vendor report attests only one *instantiation*.

| | |
|---|---|
| **Strengths** | Single point of global state (DIM-4) makes sequencing decisions cheap and consistent. Strict star topology (DIM-2) means zero inter-participant protocol to design or debug. Assignment (DIM-3) is deterministic and auditable. Failure containment is simple: one supervisor, one recovery path (DIM-9). |
| **Weaknesses** | The coordinator is the bottleneck **and** the single point of failure (DIM-12, DIM-9) — the two are the same node. Dispatch quality is bounded by one context window. Scalability degrades non-linearly as participant count rises `[EMPIRICAL: Horling & Lesser 2005]`. |
| **Opportunities** | The routine-dispatch portion of DIM-1 is separable from the judgment portion — precisely the cut D3 must draw. A measured DIM-1 value makes that separation testable rather than asserted. |
| **Threats** | Coordinator context exhaustion mid-release (observed: DIM-9's witnessed spoke-termination class). Cumulative resource draw (DIM-11) makes the incumbent's parallel-safe stages less parallel in practice than the coordination model implies. |

### MECH-2 — Hierarchical / multi-level supervision

**Aliases:** supervisor tree · holarchy · multi-level MAS · matrix organization (partial).

**Citations (3).** `[EMPIRICAL: Horling & Lesser 2005]` — hierarchies and holarchies as distinct paradigms with stated advantages and disadvantages. `[CONSENSUS: Moore 2025, arXiv preprint 2508.12683]` — a five-axis taxonomy of hierarchical multi-agent systems including temporal layering and delegation. `[EMPIRICAL: Guo et al. 2024, Proceedings of IJCAI-24, pp. 8048–8057]` — LLM-based multi-agent survey covering layered organization.

| | |
|---|---|
| **Strengths** | Relieves DIM-12 by distributing routing across levels; each supervisor's context covers only its subtree. Supports **temporal layering** — different decision cadences at different levels `[CONSENSUS: Moore 2025]`. Degrades gracefully: losing one mid-level supervisor costs one subtree, not the run (DIM-9). |
| **Weaknesses** | Introduces cross-level information loss: a summary that ascends is lossy, and the loss is invisible at the level that consumes it. Adds a genuinely new coordination surface (DIM-7) — inter-supervisor handoff — that centralization does not have. |
| **Opportunities** | Directly addresses the incumbent's DIM-12 weakness without changing DIM-3 or DIM-4. It is the **smallest-delta** mechanism from the incumbent: it differs on DIM-1, DIM-2, and DIM-12, and matches on the rest. |
| **Threats** | Governance surfaces assume a single accountable coordinator; a multi-level variant would need the accountability question answered before, not after, adoption. |

### MECH-3 — Market / auction allocation

**Aliases:** contract net · negotiated allocation · bidding · market paradigm.

**Citations (3).** `[FRAMEWORK: Smith 1980, IEEE Transactions on Computers C-29(12):1104–1113]` — the founding contract-net formulation of allocation by negotiation between task-holders and capable executors. `[CONSENSUS: FIPA Contract Net Interaction Protocol, specification SC00029, 2002]` — the standardized protocol adding explicit rejection and confirmation acts. `[EMPIRICAL: Horling & Lesser 2005]` — markets as an organizational paradigm with stated trade-offs.

| | |
|---|---|
| **Strengths** | Allocation adapts to **actual current capability** rather than a plan authored earlier (DIM-3). Load balances without a central load model. Handles heterogeneous participants natively. |
| **Weaknesses** | Requires participants that can *evaluate* a task before accepting it — a real precondition, not a formality. Adds a full negotiation round-trip to DIM-7, raising latency and resource draw (DIM-11). Award criteria are themselves a judgment surface, so DIM-1 is not made deterministic by adopting a market — it is relocated. |
| **Opportunities** | Where the platform's plan-time assignment is provably wrong (a spoke assigned work it cannot do), a bid step would surface that **before** the work starts rather than at Stage 8. |
| **Threats** | The platform's participants are spawned on demand and are homogeneous by construction, so there is no capability variance for a market to exploit. Adopting one would pay the negotiation cost for no allocation gain. |

### MECH-4 — Blackboard / shared workspace

**Aliases:** shared-workspace coordination · opportunistic control · blackboard architecture.

**Citations (3).** `[EMPIRICAL: Nii 1986, AI Magazine 7(2)]` — the survey establishing the three-part model (knowledge sources, blackboard data structure, control component) and its evolution. `[FRAMEWORK: Erman, Hayes-Roth, Lesser & Reddy 1980, ACM Computing Surveys 12(2):213–253]` — Hearsay-II, the founding system, resolving uncertainty by integrating diverse knowledge. `[FRAMEWORK: Decker, Sycara & Williamson 1997, IJCAI-97]` — characterizes blackboard agents as a distinct middle-agent type.

| | |
|---|---|
| **Strengths** | Contribution order is **not fixed in advance** — participants act when the shared state makes their contribution possible. This is the only surveyed mechanism whose control regime is genuinely opportunistic (DIM-1, DIM-4). Excellent for incremental problem-solving under uncertainty. |
| **Weaknesses** | Shared mutable state is a contention surface by construction (DIM-5); the control component becomes a scheduling problem of its own. Audit trails are harder to read: *why* a contribution fired at a given moment is not recorded by the structure itself (DIM-8). |
| **Opportunities** | The platform already has a durable shared substrate (DIM-4 is a ledger). The distance to a blackboard regime is smaller than it appears: what is missing is opportunistic activation, not the workspace. |
| **Threats** | The pipeline's value depends on **stage ordering being a governance guarantee**. Opportunistic activation is in direct tension with a gated pipeline; adopting it wholesale would dissolve the gate semantics rather than reorganize them. |

### MECH-5 — Federated / middle-agent mediation

**Aliases:** matchmaker · broker · facilitator · federation.

**Citations (3).** `[FRAMEWORK: Decker, Sycara & Williamson 1997, IJCAI-97]` — the spectrum of middle-agents, characterizing three types and reporting performance trade-offs across load balancing, robustness, changing capability, and privacy. `[FRAMEWORK: Sycara, Widoff, Klusch & Lu 2002, Autonomous Agents and Multi-Agent Systems 5(2):173–203]` — dynamic matchmaking among heterogeneous agents. `[EMPIRICAL: Horling & Lesser 2005]` — federations as an organizational paradigm.

| | |
|---|---|
| **Strengths** | Separates *finding* a capable participant from *using* it — the incumbent conflates these in DIM-3. A matchmaker preserves participant privacy and autonomy; a broker trades those for load control. Both keep DIM-2 from becoming a full mesh. |
| **Weaknesses** | The mediator inherits the coordinator's bottleneck properties (DIM-12) in the broker variant. Advertisement freshness is a live correctness problem: a stale capability advertisement mis-routes silently. |
| **Opportunities** | Directly relevant to a future in which specialist skills are the participants: the actor model's specialist-skill actor is exactly the kind of participant a matchmaker resolves. |
| **Threats** | Requires a capability-description vocabulary the platform does not have. Introducing one is a substantial governance artifact in its own right and would not be a side effect of adopting the mechanism. |

### MECH-6 — Decentralized / stigmergic coordination

**Aliases:** swarm · peer-to-peer · self-organizing · societies and congregations.

**Citations (3).** `[FRAMEWORK: Bonabeau, Dorigo & Theraulaz 1999, *Swarm Intelligence: From Natural to Artificial Systems*, Oxford University Press]` — self-organization, robustness, and flexibility from local interaction without central control. `[EMPIRICAL: Horling & Lesser 2005]` — societies and congregations as paradigms with explicit scalability and predictability trade-offs. `[CONSENSUS: Moore 2025, arXiv preprint 2508.12683]` — flat versus layered control as the contrasting design pole.

| | |
|---|---|
| **Strengths** | No coordinator, therefore no coordinator bottleneck and no coordinator single point of failure (DIM-12, DIM-9). Highest robustness to individual participant loss of any surveyed mechanism. |
| **Weaknesses** | Global outcomes are **emergent, not specified** — the mechanism cannot guarantee a particular sequence was followed. Audit trails (DIM-8) record what happened but not what was *supposed* to happen. Requires many participants to produce useful behavior. |
| **Opportunities** | None identified for a governance pipeline at current scale. Recorded as an honest empty quadrant rather than a manufactured one. |
| **Threats** | **Structurally incompatible with a gated pipeline.** A gate is a specified checkpoint; emergence does not produce specified checkpoints. Included in the survey as the far pole of DIM-1 — its value is showing where the design space *ends*, not proposing it. |

### MECH-7 — Sequential / pipeline chaining

**Aliases:** chained handoff · sequence pattern · assembly line · producer-consumer chain.

**Citations (3).** `[FRAMEWORK: van der Aalst, ter Hofstede, Kiepuszewski & Barros 2003, Distributed and Parallel Databases 14:5–51]` — the workflow-pattern catalogue whose Sequence pattern is the canonical formulation, framed as language-independent requirements. `[EMPIRICAL: Malone & Crowston 1994, ACM Computing Surveys 26(1):87–119]` — producer/consumer (flow) dependency and the coordination processes that manage it. `[EMPIRICAL: Guo et al. 2024, Proceedings of IJCAI-24, pp. 8048–8057]` — sequential organization among LLM-based multi-agent topologies.

| | |
|---|---|
| **Strengths** | Simplest possible DIM-1: the next actor is **computed**, not inferred — it is the next stage. Handoff (DIM-7) is fully specifiable. Strongest audit story (DIM-8): the trace *is* the sequence. |
| **Weaknesses** | Zero adaptivity — a chain cannot re-route around a failed step without an external decision. No parallelism (DIM-5) by construction, so throughput is bounded by the slowest step. |
| **Opportunities** | **This is the mechanism the platform's *stage sequence* already is.** The platform is not purely centralized: it is a sequential pipeline whose per-stage dispatch is centralized. Naming that composite is a finding, not a proposal — see §3.5 and §6. |
| **Threats** | Treating the whole platform as sequential would misdescribe the parallel-safe stages and the hub's judgment role, which is exactly the conflation this survey exists to prevent. |

### MECH-8 — Conversational / group-chat multi-agent

**Aliases:** group chat · multi-agent conversation · round-robin discussion.

**Citations (3).** `[CONSENSUS: Wu et al. 2023, AutoGen, arXiv preprint 2308.08155]` — a broadly-adopted open-source framework whose unifying abstraction is conversation among customizable, conversable agents; ET3 as widely-adopted framework documentation, **applicability note:** framework adoption evidences the pattern's practicality, not its correctness for governed work. `[EMPIRICAL: Guo et al. 2024, Proceedings of IJCAI-24, pp. 8048–8057]` — survey placement of conversational topologies. `[FRAMEWORK: Cemri et al. 2025, arXiv preprint 2503.13657]` — empirical failure taxonomy over 200+ tasks and 1,600+ traces across seven frameworks, reporting failure rates high enough to be a first-order design input. Antecedent-anchored to MECH-4: an unstructured shared conversation is a blackboard whose control component is implicit.

| | |
|---|---|
| **Strengths** | Lowest specification cost — no explicit protocol to author (DIM-7). Naturally accommodates human participation in the same channel. Handles under-specified tasks where the decomposition is not known in advance. |
| **Weaknesses** | **Inter-agent misalignment is an empirically dominant failure category** `[FRAMEWORK: Cemri et al. 2025]`. Implicit control (DIM-1) means no one is accountable for the next step. Resource draw (DIM-11) scales with conversation length, not with work completed. |
| **Opportunities** | Applicable to genuinely exploratory work where the stage sequence is not yet known — the class the pipeline handles today by *stopping* and asking the operator. |
| **Threats** | Directly hostile to DIM-8 and DIM-10: an open conversational channel dissolves the authorship-scoped trust boundary the platform depends on. |

## 3.5 Coordination Problem-Class Taxonomy

A **problem class** is a coordination problem that different mechanisms answer differently. Classes with identical mechanism-fit verdicts across every dimension are one class, not two. Seven survive.

Each class carries a literature citation, **indicator signals** (how you recognize you are in it), and a **pmo-platform worked example** `[EMERGENT]`.

---

**PC-1 — Allocation under capability uncertainty.** *Which participant should do this, when capability is not known in advance?*

- **Citation:** `[FRAMEWORK: Smith 1980, IEEE Transactions on Computers C-29(12)]` — the founding statement of allocation by negotiation precisely because capability is distributed and not centrally known.
- **Indicators:** assignments are revised after work starts; a participant reports mid-task that it cannot complete the work; the assigning party maintains a capability model that goes stale.
- **Platform example:** a Stage-6 spoke assigned a file-set that a concurrent merge has already changed, discovering the mismatch only after checkout.
- **Mechanism fit:** MECH-3 (native) · MECH-5 (native) · MECH-1 (poor — assignment is plan-time) · MECH-7 (poor).

---

**PC-2 — Dependency management across activities.** *What must happen before what, and who enforces it?*

- **Citation:** `[EMPIRICAL: Malone & Crowston 1994, ACM Computing Surveys 26(1):87–119]` — coordination as the management of dependencies among activities, with named process families for shared resources, producer/consumer relations, simultaneity, and task/subtask structure.
- **Indicators:** work products arrive out of order; a downstream step consumes a stale upstream output; ordering is enforced by convention rather than by structure.
- **Platform example:** the Stage-5 → Stage-6 handoff, where a design record must exist and be ratified before a build spoke may act on it — enforced by hub sequencing, not by a structural interlock.
- **Mechanism fit:** MECH-7 (native — the sequence *is* the enforcement) · MECH-2 (good) · MECH-1 (good) · MECH-6 (poor).

---

**PC-3 — Shared-state contention.** *Multiple participants need to write the same substrate.*

- **Citation:** `[EMPIRICAL: Malone & Crowston 1994]` — shared-resource dependency as a distinct coordination process family; `[FRAMEWORK: Cemri et al. 2025, arXiv preprint 2503.13657]` names resource contention among architectural failure modes.
- **Indicators:** concurrent participants serialize at a substrate the coordination model claims is parallel; conflicts appear at commit time rather than at design time.
- **Platform example:** Engineering under a single-branch topology — file-disjoint commits still serialize at push, so file-disjointness does not buy parallelism (DIM-5).
- **Mechanism fit:** MECH-4 (native — the workspace *is* the contention model) · MECH-1 (adequate via serialization) · MECH-6 (poor).

---

**PC-4 — Opportunistic problem-solving under uncertainty.** *The order of useful contributions is not knowable in advance.*

- **Citation:** `[EMPIRICAL: Nii 1986, AI Magazine 7(2)]` — the blackboard model as the architecture for opportunistically applying diverse knowledge; `[FRAMEWORK: Erman et al. 1980, ACM Computing Surveys 12(2)]` for the founding system.
- **Indicators:** a fixed stage order forces work to wait for information it could have used earlier; participants repeatedly discover that a later stage's input was available at an earlier one.
- **Platform example:** a Stage-6 build discovering a detector constraint that would have changed the Stage-5 design — information available in the corpus the whole time, but not activated until a stage reached it.
- **Mechanism fit:** MECH-4 (native) · MECH-8 (adequate) · MECH-7 (poor by construction).

---

**PC-5 — Scale and bottleneck relief.** *The coordinator cannot hold the whole problem.*

- **Citation:** `[EMPIRICAL: Horling & Lesser 2005, Knowledge Engineering Review 19(4)]` — organizational design has a quantitative effect on performance, with scalability an explicit evaluation criterion; `[CONSENSUS: Moore 2025]` motivates layering exactly as complexity and scale management.
- **Indicators:** coordinator capacity, not participant capacity, sets throughput; the coordinator summarizes rather than reads; decisions degrade late in a run.
- **Platform example:** hub context pressure across a multi-card release, where routing quality depends on how much of the release history the hub can still hold.
- **Mechanism fit:** MECH-2 (native) · MECH-6 (native) · MECH-5 (partial) · MECH-1 (this is its named weakness).

---

**PC-6 — Commitment and handoff integrity.** *A transfer of responsibility must be pledged and monitored, not assumed.*

- **Citation:** `[FRAMEWORK: Jennings 1993, Knowledge Engineering Review 8(3):223–250]` — commitments as pledges to a course of action and conventions as the means of monitoring them under change, argued as the foundation of coordination.
- **Indicators:** a participant's completion signal and its actual output diverge; a handoff is inferred from silence; ownership of an in-flight item is ambiguous.
- **Platform example:** the four-field return value carrying routing only while content travels on the durable thread — a deliberate convention that makes the pledge (`output-posted`) checkable against the artifact, and whose failure mode was witnessed when a spoke's pledge never arrived though its work had landed (DIM-9).
- **Mechanism fit:** MECH-3 (native — award and confirm are protocol steps) · MECH-1 (adequate by convention) · MECH-6 (poor — no commitment concept).

---

**PC-7 — Output verification and error propagation.** *Who checks the work, and what stops a bad output from travelling?*

- **Citation:** `[FRAMEWORK: Cemri et al. 2025, arXiv preprint 2503.13657]` — task verification as one of three top-level failure categories in an empirically-derived taxonomy of 14 failure modes, built from 1,600+ traces with reported inter-annotator agreement.
- **Indicators:** defects surface downstream of where they were introduced; verification is performed by the same actor that produced the work; a passing check has no sensitivity arm.
- **Platform example:** the platform's separated Dev-Test and QA stages, and the standing requirement that a probe returning zero carry a control proving the probe is live.
- **Mechanism fit:** MECH-7 (native — verification is a stage) · MECH-2 (native — the supervisor verifies) · MECH-8 (its named weakness) · MECH-6 (poor).

---

**Discriminability audit.** Two candidate classes were **merged** for failing the discriminability test: *"load balancing"* collapsed into PC-1 (identical fit verdicts across all eight mechanisms), and *"trust and authorization"* collapsed into PC-7 (both are answered by the same verification-locus property). Merging rather than padding keeps the count honest.

---

## 4. Inclusion Criteria and the Surveyed Set

### 4.1 Candidate criteria menu — stated before the set

The criteria below were selected from a research-derived menu, not authored to fit a predetermined list. The menu considered: *(a)* attestation in a published survey or taxonomy; *(b)* distinct coordination semantics; *(c)* platform vernacular presence; *(d)* contemporary framework adoption; *(e)* dimensional contrast against the incumbent.

**Adopted criteria.** A candidate is **included** when it satisfies **all four**:

1. **Externally named.** The mechanism is named as a distinct coordination or organizational paradigm in at least one published survey or taxonomy source — menu item *(a)*. Rationale: this is the VT-1 mitigation; it prevents the set from being enumerated out of the incumbent's vocabulary.
2. **Distinct coordination semantics.** It answers at least one §2 dimension differently from every other included mechanism — menu item *(b)*. Rationale: mechanisms that agree on every dimension are aliases, not alternatives.
3. **Citable to the bar.** It reaches three external citations with at least one at ET1/ET2, after antecedent-anchoring where needed — menu items *(a)* and *(d)*. Rationale: the minimum-grade rule; a mechanism that cannot be sourced cannot be reasoned about.
4. **Contrast-bearing set property.** The **set** must contain the incumbent and at least two mechanisms differing from it on ≥3 dimensions — menu item *(e)*. Rationale: a comparison with no contrast cannot discharge §6.

**Exclusion rules.** A candidate is **excluded** when: *(i)* it is a deployment topology rather than a coordination mechanism; *(ii)* it is a vendor product name with no coordination semantics distinct from an underlying pattern (route to the pattern); *(iii)* it cannot reach three citations with ≥1 ET1/ET2 even after antecedent-anchoring.

### 4.2 The selected set — criteria applied

| Mechanism | Externally named | Distinct semantics | Citations (≥1 ET1/ET2) | Differs from incumbent on ≥3 dims |
|---|---|---|---|---|
| MECH-1 Centralized | ✅ | ✅ (the incumbent baseline) | 3 ✅ | — (is the incumbent) |
| MECH-2 Hierarchical | ✅ | ✅ DIM-1/2/12 | 3 ✅ | ✅ (3) |
| MECH-3 Market | ✅ | ✅ DIM-3/7 | 3 ✅ | ✅ (4) |
| MECH-4 Blackboard | ✅ | ✅ DIM-1/4/5 | 3 ✅ | ✅ (4) |
| MECH-5 Federated | ✅ | ✅ DIM-3/12 | 3 ✅ | ✅ (3) |
| MECH-6 Decentralized | ✅ | ✅ DIM-1/2/9/12 | 3 ✅ | ✅ (5) |
| MECH-7 Sequential | ✅ | ✅ DIM-1/5 | 3 ✅ | ✅ (3) |
| MECH-8 Conversational | ✅ | ✅ DIM-1/7/10 | 3 ✅ | ✅ (4) |

**Set property satisfied:** the incumbent plus **seven** mechanisms differing on ≥3 dimensions, against a floor of two.

### 4.3 Exclusions, with reasons

| Candidate | Excluded under | Reason |
|---|---|---|
| Coalitions | rule (ii) | Named in `[EMPIRICAL: Horling & Lesser 2005]`, but its coordination semantics are a *transient* market or federation; it answers no §2 dimension differently. Routed to MECH-3 / MECH-5. |
| Teams | rule (ii) | Distinguished in the source literature by shared-goal commitment, not by a distinct coordination structure; dimension values duplicate MECH-2. Routed to MECH-2. |
| Named vendor agent frameworks (as products) | rule (ii) | Product names, not coordination semantics. Each routes to the pattern it implements; the pattern is what this survey characterizes. |
| Sharded / replicated deployment layouts | rule (i) | Deployment topology, not a coordination mechanism — participants do not coordinate differently because of how they are deployed. |
| Emerging agent-negotiation protocol proposals | rule (iii) | Cannot reach three citations with ≥1 ET1/ET2 after antecedent-anchoring; single-source preprints without a classical antecedent. **Exclusion-with-reason is a valid outcome** — recording it is more honest than padding the set to a target number. |

### 4.4 Framework-catalog reconciliation

Named external frameworks the platform **adopts** are registered in [`framework-catalog.md`](../specs/framework-catalog.md), per [`framework-corpus-discipline.md`](../standards/framework-corpus-discipline.md) §5–§7. That discipline's registration trigger is **adoption**, and §7 codifies a third disposition for net-new frameworks referenced in prose: *accept as intentionally inline-only*. The reconciliation here is therefore a **three-way split, not a binary**.

**(a) Surveyed mechanisms → out of catalog scope; zero rows.** Each mechanism below is an **object of study** in a comparative survey. The platform adopts none of them as a methodology in this release; per the discipline's inline-only disposition they are accepted as referenced-in-prose. Adoption, if it ever happens, occurs at the selection layer deferred in §7 — that is the release that would register them.

| Mechanism | Catalog disposition |
|---|---|
| MECH-1 Centralized orchestration | Out of scope — surveyed, not adopted. Its platform *instantiation* is documented operationally elsewhere; the mechanism as a named framework is not adopted here. |
| MECH-2 Hierarchical supervision | Out of scope — surveyed, not adopted. |
| MECH-3 Market / contract net | Out of scope — surveyed, not adopted. No allocation protocol is adopted. |
| MECH-4 Blackboard | Out of scope — surveyed, not adopted. |
| MECH-5 Federated / middle-agent | Out of scope — surveyed, not adopted. |
| MECH-6 Decentralized / stigmergic | Out of scope — surveyed, not adopted. |
| MECH-7 Sequential / pipeline chaining | Out of scope — surveyed, not adopted. The workflow-pattern catalogue is cited as evidence for the mechanism, not adopted as the platform's process language. |
| MECH-8 Conversational multi-agent | Out of scope — surveyed, not adopted. |

**(b) Adopted analytic apparatus → registered.** Two published frameworks are not merely cited but **built upon** — §4's paradigm frame derives from the first, and §3.5's problem-class structure derives from the second. That is adoption of analytic apparatus, and both are registered in the catalog this release with `canonical_doc: —`.

| Framework | Where this document adopts it |
|---|---|
| MAS Organizational Paradigms (Horling & Lesser) | §4's candidate frame and §3's paradigm set are constructed from its enumeration and its evaluation criteria. |
| Coordination Theory (Malone & Crowston) | §3.5's problem classes are structured on its dependency-family formulation. |

**Why `canonical_doc` is `—` and not this document.** Naming a document in that column makes a `framework_version_anchor:` frontmatter field REQUIRED on it and creates a live machine-asserted consistency check between the two. This document is a **consumer** of both frameworks, not their canonical platform treatment. Pointing the column here would manufacture a drift-assertion coupling for no benefit — the same posture every other externally-sourced row in the catalog takes.

**(c) This document as an internal framework → deferred.** It is a survey, not a platform-adopted framework. Its dimension set and taxonomy only *become* adopted apparatus when something consumes them for a decision — which is the deferred selection layer. Registration as an internal framework is therefore deferred; see §7.

**SWOT itself** is used as an analytic presentation format and is deliberately **not** registered: it has no issuing body and no version-anchorable edition, so a catalog row could not carry the `version_anchor` the schema requires as non-empty.

---

## 5. Extension Protocol — Admitting a New Mechanism

This protocol is written so that a reader can produce a complete intake work item **from this section alone**, without consulting the survey's authors.

### 5.1 Preconditions

Do not open an intake item until all three hold:

1. The candidate has a **name used outside this platform**.
2. You can state **one §2 dimension** on which it differs from every mechanism in §4.2. If you cannot, it is an alias — record it in the alias set of the mechanism it matches and stop.
3. You have **at least one ET1 or ET2 source**, or a named classical antecedent that carries one.

### 5.2 Intake fields to produce

Produce each field below; an item missing any field is not ready.

| Field | Content required |
|---|---|
| **Mechanism name** | The externally-used canonical name. |
| **Alias set** | Every other name for the same coordination semantics, so §3's one-semantics-one-mechanism rule can be checked. |
| **Distinctness claim** | The named §2 dimension(s) on which it differs, with the differing value stated for each. |
| **Citation register** | Three external citations, each as author-or-body + year + venue-or-publisher, each tagged ET1–ET5. At least one at ET1/ET2. If the contemporary instantiation is below ET3, name the classical antecedent supplying the ET1/ET2 anchor. |
| **Dimension row** | The candidate's value for **all twelve** §2 dimensions. A dimension you cannot answer is a research gap — say so; do not guess. |
| **SWOT** | Four quadrants, with strengths/weaknesses intrinsic and opportunities/threats stated against the pmo-platform context. No quadrant resting solely on ET4 plus ET5. |
| **Problem-class fit** | For each §3.5 class, one of native / good / adequate / poor, with a one-line reason. |
| **Inclusion verdict** | Criteria 1–4 of §4.1 evaluated explicitly, or the exclusion rule triggered with its reason. |
| **Set-property impact** | Whether admission changes §4.2's contrast property. |

### 5.3 Review path

The item is reviewed against §4.1's criteria exactly as the existing set was. **An exclusion verdict is a successful outcome** and is recorded in §4.3 with its reason — the exclusion register is part of the artifact's evidence, not a record of failure.

### 5.4 What extension may **not** do

Adding a mechanism may not: introduce a selection rule, declare a configuration field, or assign a mechanism to any platform scope. Those are §7's deferrals, and extension does not reopen them.

## 5.5 Selection Discipline — Four Rules, No Selection Layer

These four rules **bound** any future selection layer. They are stated here because they are properties of the mechanisms — not of a resolution algorithm — and because a selection layer designed without them would be designed wrong. **This section designs no selection layer**: it defines no field, no schema, no precedence order, and no resolution procedure.

> **Rule 1 — One mechanism per scope (default).** A given coordination scope runs **one** mechanism at a time. Mixing two mechanisms within one scope means two answers to the same §2 dimension are live simultaneously — most destructively DIM-1, where two control loci produce two "next actors" and neither is accountable. This is the default, not a prohibition: Rule 3 names the exception.

> **Rule 2 — Parent cascade.** A scope that declares no mechanism **inherits its parent scope's**. Inheritance rather than a global default means the answer is always traceable to a declared decision somewhere up the chain, and no scope silently runs an unstated mechanism. A child scope may declare its own, which then governs the child and *its* children.

> **Rule 3 — Operator-authorized composition, with a risk warning.** Composing more than one mechanism within a scope is permitted **only** on explicit operator authorization, and the authorization must be accompanied by a statement of which §2 dimensions now carry conflicting values and what the resolution is for each. Composition without that statement is the failure Rule 1 exists to prevent, performed deliberately. The warning is mandatory because the failure mode is **silent**: composed mechanisms do not error, they diverge.

> **Rule 4 — An agent NEVER composes autonomously.** No agent may combine mechanisms on its own initiative — not to route around a blocker, not as an optimization, not because a scope appears under-specified. An under-specified scope resolves by Rule 2, and if inheritance yields nothing the correct action is to **surface the gap**, never to select or compose. This rule is absolute and has no efficiency exception.

**Decision points and inputs a future selection layer would need — named, not designed:**

| Decision point | Inputs it would consume |
|---|---|
| What is a "scope"? | The scope taxonomy is undefined today — candidates include the release, the stage, and the work item. This is a genuine open question, not an omission. |
| Which mechanism fits this scope? | §3.5 problem-class fit + the scope's dominant problem class + §2 values the scope requires. |
| Is a declared mechanism admissible here? | §4.2 membership + §2 dimension compatibility with the scope's constraints. |
| Has composition been authorized? | The operator authorization and the per-dimension conflict resolution required by Rule 3. |
| What happens on conflict? | Rule 1 default, Rule 2 inheritance, Rule 3 exception — the **resolution procedure over these is deliberately not specified here.** |

---

## 6. Composition — What This Artifact Feeds

This is the section the artifact's warrant rests on. It states, per open decision, **what that decision needs to become renderable** and what this artifact supplies. It **does not render any of them** — the consuming document's stated posture is that each open decision decomposes into its own small decision record when ready, and resolving one here would violate that posture and encroach on the deferred selection layer.

### 6.1 Which open decisions this artifact feeds

The target operating model — [`actor-model-and-governance-as-contract.md`](actor-model-and-governance-as-contract.md) — carries five open sub-decisions. This artifact feeds **two primarily and one indirectly**, and explicitly **does not** feed the other two. Stating the non-coverage is part of the discharge, so §6 does not over-claim.

| Decision | Coverage |
|---|---|
| **D3** — orchestration-as-skill vs. orchestration-as-agent | **Primary** — §6.2 |
| **D5** — migration sequencing from hub-spoke | **Primary** — §6.3 |
| D1 — the actor ownership split | **Indirect** — DIM-1's determinism axis informs where the split can fall, but the split itself is not decided by mechanism evidence. |
| D2 — the consuming document's own posture | **Not fed.** |
| D4 — the form the governance contract takes | **Not fed.** A contract's *form* is orthogonal to which coordination mechanism it constrains. |

### 6.2 D3 discharge — *Orchestration-as-Skill vs. Orchestration-as-Agent*

D3 is stalled because its only seed is itself forward-looking. It needs a non-forward-looking evidence base, an axis, and a mapping.

| What D3 needs | What this artifact supplies | Where |
|---|---|---|
| **N1 — A non-forward-looking external seed**: prior art where the dispatch-versus-judgment cut is actually drawn in working systems | §3 shows the cut drawn **differently** by different mechanisms: MECH-3 separates mechanical bid collection from judgment-laden award criteria; MECH-4 separates mechanical workspace updates from judgment-laden activation; MECH-7 computes the next actor outright; MECH-8 leaves control implicit. **That variance is what makes D3 a decision rather than a definition.** | §3, MECH-3 / MECH-4 / MECH-7 / MECH-8 |
| **N2 — A named axis**, so the cut is a dimension rather than a vibe | **DIM-1 (control locus / dispatch determinism)** — *is the next-actor decision computed from state, or inferred?* — externally attested and carrying the incumbent's measured value (**judgment-inferred**). **DIM-1 is D3's decision variable.** | §2, DIM-1 |
| **N3 — Which behaviours sit on which side** | §3.5 provides the mapping: **PC-2 and PC-7 are served natively by deterministic dispatch** (MECH-7, MECH-2 — the next actor and the verifier are both computable); **PC-1 and PC-4 require judgment-laden conducting** (award criteria and opportunistic activation are irreducibly evaluative). The taxonomy **is** D3's cut, expressed as a mapping over problem classes. | §3.5 |
| **N4 — What evidence would settle it** | Stated below as the residual. | §6.2 residual |

**Residual for D3 — what remains after this artifact.** Two things, neither of which is a survey question: *(a)* an enumeration of the platform's own orchestration behaviours classified against DIM-1 — this artifact supplies the axis, not the per-behaviour classification; and *(b)* a decision on whether a skill may hold a DIM-1 value of *judgment-inferred* at all, which is a governance question about what a bounded capability may own, not an empirical one.

**Boundary.** §6 does **not** state which platform behaviours are skill-eligible. It hands D3 an axis, a variance set, and a class mapping.

### 6.3 D5 discharge — *Migration Path from Hub-Spoke*

D5 is stalled because its Now/Next/Later table asserts a migration over an **unmeasured baseline**. It needs a measured before-state, a cost model, bounding rules, and a grounded motivation.

| What D5 needs | What this artifact supplies | Where |
|---|---|---|
| **N5 — A measured BEFORE** | §2's hub-spoke column: **twelve dimensions, each with the incumbent's actual current-state value**, each sourced to a durable section of the operating guide. This converts D5's baseline from assertion to measurement. | §2 |
| **N6 — Migration cost and reversibility between mechanisms** | A mechanism's **dimension-value delta from the incumbent is its migration surface**. §4.2 records that delta per mechanism: MECH-2 and MECH-5 and MECH-7 differ on 3 dimensions; MECH-6 on 5. Migration cost is therefore ordered, not guessed — MECH-2 is the smallest-delta move and MECH-6 the largest. | §2 + §3 + §4.2 |
| **N7 — Admissible shapes of a *partial* migration** | §5.5 Rules 1 and 2 bound it: one mechanism per scope, with parent-cascade inheritance. Together they make a **scoped** partial migration admissible — a child scope may adopt a different mechanism while its parent does not — which is exactly the shape a Now/Next/Later sequence takes. Rules 3 and 4 bound who may authorize it. | §5.5 |
| **N8 — A grounded motivation, not aesthetics** | **PC-5 (scale and bottleneck relief) is the class the incumbent serves worst**, and the binding weakness is named: in MECH-1 the coordinator is simultaneously the bottleneck (DIM-12) and the single point of failure (DIM-9). That is a specific, evidenced motivation for migration — and PC-5's own platform example is an observed condition, not a hypothetical. | §3 MECH-1 + §3.5 PC-5 |

**Residual for D5 — what remains after this artifact.** The **sequence itself**: which scope migrates first, in what order, and against what trigger. This artifact deliberately supplies the four inputs and not the ordering — sequencing is a planning decision that consumes this evidence, not a finding derivable from it.

**Boundary.** §6 does **not** propose a migration sequence.

### 6.4 An incidental finding worth recording

The platform is commonly described as "hub-spoke," i.e. MECH-1. §2's measured values show that description is **incomplete**: the platform is a **MECH-7 sequential pipeline whose per-stage dispatch is MECH-1 centralized**. DIM-5's per-stage split and DIM-1's judgment-inferred value cannot both be properties of a single pure mechanism. This is a composite, and naming it matters for D5 — a migration from "hub-spoke" that does not distinguish the sequential outer structure from the centralized inner dispatch would migrate the wrong layer. Recorded as a finding of §2's measurement, not as a proposal.

### Issue References

The composition points below name where each referenced work item plugs into this artifact's output. Each entry states the integration point, not merely the relationship.

| Work item | Integration point |
|---|---|
| **#28** — unified configuration | The deferred selection layer would read its scope-and-mechanism declaration from the unified configuration surface; §5.5's Rule 2 parent-cascade is the inheritance semantics that surface would have to implement, and §5.5's decision-point table is the input list it would need to resolve. This artifact declares no field for it to carry. |
| **#41** — per-space configuration split | Rule 1's "scope" is undefined here on purpose; the per-space split is the candidate that would supply a concrete scope boundary, making Rule 2's cascade a real inheritance chain rather than an abstract one. The scope taxonomy question in §5.5's table is the specific input this work item would answer. |
| **#104** — localized-context guardrail | This artifact is subject to that guardrail as a consumer: its dimension values and problem-class examples are platform-current-state claims that must stay localized and verifiable rather than hardcoded, which is why §2 cites durable section names and a stated baseline instead of embedding volatile counts. |
| **#32** — single canonical edit surface | The deferred selection layer must not become a second place where orchestration behaviour is declared; §5.5's Rule 1 and Rule 2 are the discipline that keeps one declaration authoritative per scope, and that work item is where the single-surface constraint is enforced for Part 2. |

**Consuming document.** [`actor-model-and-governance-as-contract.md`](actor-model-and-governance-as-contract.md) is the primary consumer. This artifact supplies the evidence base for its open decisions **D3** (§6.2) and **D5** (§6.3), and informs **D1** indirectly. It supplies nothing to D2 or D4, stated so the consumer does not over-read the dependency.

---

## 7. Deferrals, Boundary, and Cutover

### 7.1 Explicit deferrals

This artifact is **research-only**. The following are deferred in full to the selection-layer work that consumes it:

1. **The selection layer itself** — any procedure, algorithm, or precedence order that resolves which mechanism governs a scope. §5.5 names the decision points and their inputs; it specifies no resolution.
2. **Any configuration field** — this artifact declares, names, and defines **no configuration field** for orchestration. §5.5's rules are stated as discipline, not as a schema, and no field name is introduced by this document.
3. **The scope taxonomy** — what counts as a coordination "scope" is an open question recorded in §5.5, not answered.
4. **Consumer integration** — no skill, no gate, and no pipeline stage is changed by this artifact. It is consumed by reading.
5. **Registration of this document as an internal framework** — deferred per §4.4(c); it is a survey until something consumes its apparatus for a decision.
6. **Mechanism adoption** — no mechanism is selected, recommended, or assigned to any platform scope. §6.4's composite finding is a description of current state, not a proposal to change it.
7. **The D3 and D5 residuals** — §6.2 and §6.3 each name what remains; neither decision is rendered here.

### 7.2 The no-encroachment boundary, stated as a checkable claim

> This document defines no configuration field, changes no consumer skill, and specifies no mechanism-selection procedure. Its §5.5 rules constrain a future selection layer; they do not constitute one.

### 7.3 Cutover

**Cutover discipline.** The selection-discipline rules in §5.5 apply to orchestration decisions taken strictly **after** this artifact's introducing-release merge SHA as recorded in the release log; the introducing release itself is exempt (reflexive-pipeline-loop discipline). The exemption is not a convenience: this release *produces* the artifact, so it cannot have consulted it, and a rule that retroactively bound its own introducing release would be unsatisfiable by construction.

Because §5.5 binds no automated gate today, the practical effect of the cutover is limited to how a future selection layer is designed — which is precisely the scope §7.1 defers.

---

### 7.4 Provenance — consumed surfaces

This document **consumes and does not restate** the following. Each is cited for a specific contribution.

| Surface | What is consumed |
|---|---|
| [`corpus-curation.md`](corpus-curation.md) | The ET1–ET5 evidence-tier vocabulary and the evidence-label extension used throughout §2 and §3. No tier or label is redefined here. |
| [`knowledge-architecture.md`](knowledge-architecture.md) | The K1 placement model and the §4.1 host-binding discipline governing how this document may describe host-bound mechanisms. |
| [`actor-model-and-governance-as-contract.md`](actor-model-and-governance-as-contract.md) | The three-actor target model and its open sub-decisions — the consumer this artifact serves. |
| [`hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md) | The incumbent's operational current state, read-only, as the source for §2's hub-spoke column. |
| [`parallelism-posture-taxonomy.md`](../../release/references/standards/parallelism-posture-taxonomy.md) | The named concurrency postures cited in DIM-5. |
| [`framework-catalog.md`](../specs/framework-catalog.md) · [`framework-corpus-discipline.md`](../standards/framework-corpus-discipline.md) | The registration contract and the adoption-versus-mention trigger applied in §4.4. |
