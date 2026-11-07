---
title: "ADR-232 — Each delivery stage's documents are declared once, keyed to a shared layer of delivery spans, and projected onto the release pipeline and project delivery"
status: Accepted — ratified with amendments by the operator at the Stage 9 gate of the stage-document-model-decision release, 2026-11-05
date: 2026-11-05
release: stage-document-model-decision
deciders: "Workspace owner (operator) — ratified with amendments at the Stage 9 gate, 2026-11-05"
tags: [architecture, documentation, stage-document-model, lifecycle, methodology, process-catalog, delivery-spans]
source_observations:
  - "Release-pipeline inventory, verified at head on 2026-11-05 and corrected after its Stage-7 review (Revision 2): 133 (stage, document) rows across all 13 stages, built as the original 112-row inventory plus a 46-row delta, including five conditional-path records bound by the inter-stage signal protocol (Tier-2 HALT and scope-change records at Stages 9 and 12, signal event rows and comments at Stages 7 and 8, a resolving review-thread reply at Stage 8); none of its lifecycle-in-practice cells and only 4 of its readers cells are verified, so those columns support and never decide; of the 11 Stage 5 outputs the stage contract names, 4 reach a durable home by contract and 7 live only in a stage comment, and 1 is a candidate for a catalog page."
  - "Project-delivery inventory, verified on 2026-11-05: 90 document rows, 46 disagreements between the two stage tables of the operational-artifacts standard plus 4 observations noted beside it, five project-phase vocabularies none of which is mapped to another, and no design slot in the gap-detection table."
  - "Stage and phase crosswalk, verified on 2026-11-05: 18 aligned rows and three candidate shared vocabularies; renaming the stages outright would touch 614 live files and leave 402 release records on the old names, while a class layer touches about 18 files plus catalog pages; the project agent states and the catalog page statuses both collide with names the lifecycle register already holds, and neither machine is registered."
  - "Methodology-variation discovery, 2026-11-05: 32 archetype cells, 19 with a source-stated cadence; 14 of the 18 source-stated classes are Baselined, 7 of them from the frozen Plan entity; no source states a class for an iterative design document, the nearest statement being sprint-embedded documentation updates for Scrum and hybrids in the process designer's documentation-philosophy table, which a Stage-7 review found the census had missed (it also makes Kanban's test documents mixed, its policies being living documentation); three archetype pairs sharing a Lifecycle value differ in document behaviour; eight hook options, two eliminated on hard constraints."
  - "Design record for this decision, delivery-doc-practice-design-2026-11-05 in the analysis workspace (Revision 2): 223 coded rows, nine model decisions with their candidates, eliminators and reduction rule, and the self-check against the design criteria."
supersedes: none
---

# ADR-232 — Each delivery stage's documents are declared once, keyed to a shared layer of delivery spans, and projected onto the release pipeline and project delivery

## Status

Accepted. Authored `Proposed` at Stage 6 Engineering of the `stage-document-model-decision` release from the design record named in `source_observations:`, and ratified with amendments by the operator at that release's Stage 9 gate on 2026-11-05, before the merge. It is an EXPENSIVE scope-lock: every declaration row, stage-spec edit and catalog check in the delivery milestones it cuts is shaped by it.

**The ratification's amendments.** The operator settled the questions this record left to the gate:

- **Point-in-time binds to Domain C** (§ 4). A point-in-time document takes Domain C's publish-then-freeze path. The frozen Axis-2 value set is reopened only if a point-in-time document is shown to need Domain C's `stale` state.
- **The design default is a labelled default** (§ 6). Timeboxed and continuous design documents default to living, amended each increment. The declaration marks this as a default, not a sourced value.
- **The vocabulary stands as proposed** (§ 3): the term "delivery span" and its eight names.
- **Where the ratified design lives.** This record holds it. The declaration slice carries the row-level data into the declaration, and the methodology slice the cell-level resolution, before the analysis record that holds them sunsets.
- **The risk-class home decision, re-checked** (§ 5). It was still `Proposed` at ratification. Every home its draft names is nameable by § 5's classes, so no class was added and § 5 stays provisional.
- **The node-delta lint is adopted on a supporting-grade premise** (§ 7). Its deciding premise has the design record's weakest grade, a supporting reading rather than a deciding one. The operator accepted that knowingly; the lint ships warn-mode first.

Other branch-authored files cite this record by its slug token until the release claim binds its number.

**Numbering provenance — `230 → 232`.** Held **ADR-230** branch-local; renumbered to **ADR-232** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 230. In-release citations that read "ADR-230" denote this record.

## Context

**The question.** What does each delivery stage write, how long does each document stay current, where does it live, who reads it next — and how does one model say that for both the 13-stage release pipeline and the delivery of a project, under any delivery methodology?

**What the platform has today.** Four discovery cards measured the current state before this design was written. At authoring, their findings were:

- **Two tables that do not join.** `core/standards/operational-artifacts.md` holds the three lifecycle patterns (living, point-in-time, baselined), a Stage-Artifact Mapping keyed to eleven stage names, and a Gap Detection Reference keyed to six project phases. The mapping includes a "Verify" stage the pipeline does not define and omits Bundle, Dry Run and Snapshot; the gap table has no design phase and no hypercare row. No row in either carries a lifecycle class, template, home or reader. The file is injected into two operations skills (`comms-writer` and `ppm-agent`); no release-pipeline surface reads it.
- **The release pipeline writes far more than the mapping says, and much of it does not persist.** The verified release inventory found documents at every one of the 13 stages. At authoring, more than half of its rows were homed first in a GitHub issue, comment, pull request, tag or Release rather than in a tracked file, and its lifecycle-in-practice column was unverified throughout. The Stage 5 design output is delivered as sections of a stage comment; only an ADR, a skip rationale and the planning-level specs carried into the plan reach a durable home. The node-level part of a refined change spec — the target steps of a process the change alters — is the one Stage 5 output that belongs on a catalog page.
- **Project delivery speaks five phase vocabularies.** The gap table's six phases, the mapping's eleven stage names, the agent-state machine (ACTIVE, CLOSING, CLOSED), the project agent's nine gates and the delivery engine's fifteen stages coexist, unmapped. The project inventory found that 46 points on which the two tables disagree were recorded at the inventory's baseline — owners named three ways, a closure record with three names, design documents placed in no phase.
- **Three candidate vocabularies, three universes.** The crosswalk proposed a pipeline-native vocabulary (C1), the five process groups of the function spine as a layer (C2), and neutral life-cycle classes after ISO/IEC/IEEE 15288 and PMBOK 7 (C3). Since then the process catalog (ADR-224) adopted three universes — release, project delivery and the engineering harness — placed each pipeline Stage at catalog level L2, and made the platform-doc `status` field (DRAFT, ACTIVE, SUPERSEDED, DEPRECATED) the page lifecycle. Those four status words, and the project agent states ACTIVE and CLOSED, collide with names `core/standards/lifecycle-states-canonical.md` already reserves for other machines; neither machine is registered there.
- **A second lifecycle vocabulary already exists per file.** The frontmatter schema binds Domain A files to the baselined pattern, Domain B to living and Domain C to a hybrid publish path, and the project entity model's Axis 2 (`content_lifecycle_pattern`) inherits that per file, with the Plan entity frozen at Baselined. Point-in-time has no equivalent there.
- **Methodology changes cadence, but barely changes class.** Where the corpus names documents per delivery approach, it states when they are written (at the gate for phased approaches, inside the increment for timeboxed ones, per item for continuous flow). It rarely states a class other than baselined. For iterative work it says only that documentation is updated within the sprint (Scrum and hybrids) or kept as living policy (Kanban); it states no class for any iterative design document. The methodology-blind default is predictive: the Test Plan is "per phase" and gap detection runs by predictive phase, which is wrong for the four approaches that have no phases. The variation that does exist is dispersed across about two dozen surfaces.

**What forced a decision.** The parent epic requires one declaration of the stage-to-document set, projected twice, with six attributes per document and a methodology hook. Its 2026-10-24 widening adds the full loop — read the current state, design the future state, build and document it in the same release, validate it, feed it back into the current-state catalog, and review it over time — with a leading hypothesis (a node-delta block at Stage 5, DRAFT page edits at scope lock, a flip to ACTIVE at Stage 6, four checks in code). The operator's four design constraints bound the answer: no bloat; content reviewed over releases so it never goes stale; best practice for what lives in the repository versus local git-ignored folders; repeatable for every adopter.

## Decision

### 1. One file carries the declaration

The stage-to-document set is declared once, in a **new standard under `core/standards/`** (working name `stage-document-model.md`; the build slice confirms the name). `core/standards/operational-artifacts.md` keeps its Artifact Lifecycle Patterns — the governed definition of the three classes — and its artifact inventory, and replaces its Stage-Artifact Mapping and Gap Detection Reference with a citation of the new standard. Every other surface that lists stage artifacts cites the declaration and does not restate it.

The standard is net-new because extending `operational-artifacts.md` in place is infeasible under the constraints: that file is a single-source canonical injected into two operations skills, so release-pipeline rows would ship inside the operations module's packages, against the platform's rule that each module is independently consumable and against "no bloat". The process catalog is not the carrier: it is a derived, descriptive index of the platform, not a source of its rules (`core/standards/design-artifact-standard.md` § 13).

### 2. What a declaration row states

| Attribute | Meaning |
|---|---|
| projection | `release` or `project-delivery` |
| native stage or phase | the pipeline stage (1–13), or the project phase as the project names it |
| span | the delivery span of § 3, or `continuous` for a document maintained across spans |
| document type | one row per type; aliases unified on the row |
| produced at, updated at | the stages or phases that create and change it |
| lifecycle class | living, point-in-time or baselined (§ 4) |
| template family | a `core/standards/template-taxonomy.md` family, or `none` |
| home class | § 5 |
| readers | `same-change: <stage>` and `future-change: <consumer>` |
| status carrier | the machine that holds its instance state (§ 4) |
| cadence | from the methodology hook (§ 6) |

**Minimal-set rule.** A document earns a row only when it names a reader: a later stage of the same change or a future change to the same area. A document no one reads is listed in the declaration's excluded list with its reason, never silently dropped. A document that exists only as a section of another is declared as a member of its host's row, not as a document of its own.

**Records bound by cross-cutting protocol text.** A record that the inter-stage feedback protocol binds rather than one stage spec — a signal comment, a signal event row, a HALT record — is declared at each stage that raises it, marked conditional, with the protocol named as its binding source. Its class follows its home: a comment is point-in-time, an event row is an append-only state log. No protocol-level projection is added.

### 3. The shared vocabulary is a layer of eight delivery spans

Every pipeline stage, and every project phase or stage, belongs to exactly one **delivery span**: **Concept, Define, Design, Build, Test, Transition, Operate, Close**. The spans are a methodology-neutral position in the life of a change or a project. They are a **layer**: no stage is renamed or renumbered, the stage integers and every machine identifier stay as they are, and the five-function spine keeps its role as the classifier of the kind of work (Initiating … Closing), which is a different axis from position.

| Span | Release pipeline | Project delivery | Delivery-engine lifecycle (its 15 stages) |
|---|---|---|---|
| Concept | 1 Intake, 2 Triage | Initiation; agent state ACTIVE begins | 1 Identify, 2 Capture, 3 Classify & Prioritize |
| Define | 3 Bundle (release-only), 4 Planning | Planning | 4 Define Requirements, 5 Plan & Sequence |
| Design | 5 Solutioning | design work (the gap table has no design phase today) | 6 Design / Solution |
| Build | 6 Engineering | Execution | 7 Build / Develop |
| Test | 7 Dev Testing, 8 QA Testing | Testing | 8 Developer Testing, 9 QA / Acceptance Testing |
| Transition | 9 Plan Review (the span's entry gate), 10 Dry Run (release-only), 11 Snapshot (release-only), 12 Execute | Deployment and cutover | 10 Plan Review / Authorize, 11 Release Preparation, 12 Deploy / Execute |
| Operate | — (the outcome window sits inside Stage 13) | hypercare; agent state CLOSING | 13 Verify, 14 Clean / Stabilize |
| Close | 13 Close | Closure; agent state CLOSED follows | 15 Close / Post-Implementation |

- **Project phases are mapped, not enumerated.** A phase maps to one span when its whole extent sits in one, as the gap table's phases and the phases of a project's own timeline do; the model imposes no phase list. A phase whose stages fall in several spans maps **per member stage**, and the declaration keys its rows on the stage. The delivery engine's lifecycle — the project delivery lifecycle its skill runs, fifteen stages grouped into five phases (Capture, Prepare, Build, Validate, Deliver) — is such a case: only Capture sits in one span, so it is mapped at stage grain (the table's last column). The project agent's nine-gate checklist is reached through gap detection's re-key onto spans (slice S4).
- **One name crosses the two models: `Build`.** The delivery engine's phase `Build` holds its stage 8 Developer Testing, which the spans place in Test, so it is wider than the span `Build`. Wherever the two meet — the delivery engine's lifecycle reference, and the navigation-layer schema that reuses its phases — the name is written object-typed: `Span-Build` for the delivery span, `Engine-Build` for the engine's phase.
- **Catalog placement.** The span is an attribute an L2 page template adds, which `design-artifact-standard.md` § 13.3 already permits; it is not a new catalog level. Each release L2 page (one per stage) carries its stage's span. A project-delivery L2 sub-process carries a span where it has a position in the project's life and `continuous` otherwise. Value streams (L1) are capabilities, not positions, and carry no span; they join the declaration through the documents their sub-processes produce.
- **The term** "delivery span" is registered in the terminology glossary beside Stage, Phase and Step. Its members avoid the reserved and colliding words the crosswalk named: no "Verify", no "Phase", no "Process"; the one cross-model collision, `Build`, is object-typed as above.

### 4. Lifecycle class and status are two axes with one crosswalk

- **Class** is the update discipline of a document type: a later change **amends** a living document, **versions** a baselined one (a new version, the old one kept), and **leaves** a point-in-time document as the record. The declaration states one class per document type, or per member where a type's members differ.
- **Status** is the instance state of one document, held by the machine its home carries: the platform-doc `status` field for tracked platform documents and catalog pages (`status: DRAFT`, `ACTIVE`, `SUPERSEDED`, `DEPRECATED`); the frontmatter `lifecycle_state` of its domain for a project file; the host's own state for a ticketing or repository-host record; none for an append-only state log.
- **One crosswalk, no second home for the class.** The class binds to the per-file field that already carries it: living → Domain B (`content_lifecycle_pattern: Living`); baselined → Domain A (Baselined); point-in-time → Domain C's publish-then-freeze path. Domain C is a hybrid pattern, so the ratification settled this last mapping explicitly: point-in-time takes Domain C's path, and the frozen Axis-2 value set is reopened, through the entity model's own change path, only if a point-in-time document is shown to need Domain C's `stale` state.
- **Frozen members stay frozen.** Every member persisted by the Plan entity keeps class baselined under every methodology; only its cadence varies.
- **No new state names.** Cross-machine prose names a state in the object-typed form once the page-status machine and the project agent-state machine are registered in the lifecycle register; until then a state is written in its field-value form (`status: ACTIVE`), which the register exempts.

### 5. The home-class rule

A document is **tracked in the repository only when a future change by any adopter reads it and its content is platform-general**: `tracked-durable` for the document itself, `tracked-template` where a template ships and each project keeps its own instance. Everything else takes one of these home classes, named by role rather than by one host's object types:

| Home class | What lives there |
|---|---|
| `platform-instance` | an operator-local instance of platform working data — not a project's — that exists only on the operator's install and is never tracked; whether it sits in a git-ignored folder of the repository (as `analysis/` and `roadmaps/` do) or in a per-user home outside every tree is the risk-class model's to decide |
| `project-instance` | a file in a project's own folder in the operations domain |
| `ticketing-record` | an issue body or comment, a milestone, a label or a board field, on the host `[adapters].ticketing` names |
| `repo-host-record` | a pull request, tag, Release or the git history, on the host `[adapters].repo_host` names |
| `kb-page` | a page on the knowledge base `[adapters].kb` names |
| `state-log` | an append-only event or audit log |

An operator-local instance is durable only for the operator who holds it: it never homes anything a fresh clone needs. Where a non-tracked home physically lives — a git-ignored folder in the repository, or a per-user home outside every repository and workspace — is decided outside this record, by the risk-class model for non-tracked data and by the project data architecture; this rule fixes only the class, which is a role, not a location. It is **provisional** on the pending decision that homes non-tracked data by risk class. That decision's record is `Proposed` on its own release branch at authoring: it keeps analysis and roadmap instances in the repository, moves release and run state to a git-ignored folder in each repository, and places leak-risk content and install-wide telemetry in per-user homes outside every tree — homes this table already names as `platform-instance` (or `state-log` for telemetry) and `project-instance`. If the ratified decision introduces a home this table cannot name — a private tracked store, for example — the table gains that class and nothing else in this record moves. At this record's ratification that decision was still `Proposed`; its draft's homes were re-checked against this table, and each is nameable, so no class was added.

### 6. The methodology hook

- **Carrier.** A "Methodology Variation — Document Applicability" section in the declaration, at **member grain**: per archetype, per document, the cadence and — only where it differs from the neutral row — the class. It follows the Methodology Variation section pattern the corpus already uses for trackers, and needs no change to the pack schema or the archetype matrix.
- **Selector.** `delivery_approach`, resolved per space through Step 0 of the methodology parameterization spec — the step that settles which methodology governs each space, operations or release, before any variant is chosen: operations consumers read `operational_methodology` and release consumers read `release_methodology` when a project declares them. A hybrid resolves by the existing union-and-dominance rule, or by its per-space assignment. For a Custom methodology with a base archetype, the document set is the one the parameterization spec's base-archetype case yields — the base archetype's matrix row, overridden by the Custom block — and each document then takes the base archetype's rows in this section; whether the block's artifact list replaces or merges with the base list is the methodology initiative's to settle. A Custom methodology without a base takes the neutral rows, because the Custom block carries no class.
- **Defaults where the sources are silent.** Phased approaches write at the phase gate and baseline there (sourced). Timeboxed approaches write within the increment — the sprint, or the program increment for SAFe — and keep design documents living, amended each increment. Continuous flow writes per item, and its policy documents are living (sourced). The timeboxed and continuous design default restates the epic's outcome; the corpus comes closest for Scrum and hybrids, whose documentation is updated within the sprint, but names no design document. The ratification adopted it as a labelled default: the declaration marks it as a default, not a sourced value.
- **What it fixes.** The neutral "per phase" cadence no longer applies to approaches without phases. PRINCE2's design and test documents follow its inner delivery engine, declared as a two-archetype array, so no new field is needed.

| Document group | Scrum (timeboxed) | Waterfall (phased) |
|---|---|---|
| design | per increment · living | at the phase gate · baselined |
| plan | backlogs living; Plan-entity members per increment · baselined | at the phase gate · baselined |
| test | per increment · class from the neutral row | at the phase gate · baselined |
| release | per release · baselined | at the phase gate · baselined |

### 7. Where a design lives, and the design → build → validate → document loop

The Stage 5 output comment is the **point-in-time** record of a change's design: its readers are Stages 6 to 8 of the same change. Its living successors are the **catalog page of each process node the change alters** and, for a decision that clears the ADR threshold, an **ADR**.

**Engineering Commit 0** is a release's first commit on its branch, which lands the release plan; it is made by one designated Engineering session, the **Commit-0 writer**, before any other Engineering session commits.

| Loop step | Stage | Reads | Writes | Mechanism |
|---|---|---|---|---|
| Read the current state | 2 Triage, 5 Solutioning | the catalog pages covering the affected files | one `Current-state pages read:` line | the planning reads of `design-artifact-standard.md` § 13.9 (built) |
| Design the future state | 5 Solutioning | the pages read; the change's ACs | the Stage 5 output, including a **node-delta block**: node ID · create, update, supersede or retire | new block in the Stage 5 output |
| Build it and document it in the same release | 6 Engineering | the node-delta block | Engineering Commit 0 writes each affected page as `status: DRAFT` on the release branch, so the PR shows the design before the code; the commit that builds a node edits its page to the built state and sets `status: ACTIVE`; a supersede row sets the predecessor `SUPERSEDED`; a retire row sets it `DEPRECATED` | Documentation Impact and the plan (built); the page writes (new) |
| Validate it | 7 Dev Testing, 8 QA, 9 Plan Review | the node-delta block and the pages on the branch | a designed-versus-built finding per row: resolved, or DRAFT residue | new read at Stage 7; a sibling of the drift engine's page-versus-source check, not a duplicate |
| Feed it back | 12 Execute, 13 Close | the merged pages | the pages are current on main | the close-out documentation gates (built) |
| Review it over time | after the release | each page's `last_verified_commit` | a drift finding | derived staleness (built); its granularity is the drift engine's to refine, because file-level staleness marks almost every release page stale after a few dozen pipeline commits |

The leading hypothesis is adopted with four modifications: the release branch is the future state (adopted); the node-delta block (adopted); DRAFT page edits are written at Engineering Commit 0 by the Commit-0 writer, because Stage 5 commits nothing and pages are not produced by a Stage 5 activation (modified); the flip to ACTIVE happens in the commit that builds the node, and an update keeps one page per ID rather than a successor (modified); the check is "no page that a merged release's node-delta created or revised remains DRAFT", because `DRAFT` also marks a page not yet through its pass gate, which the catalog standard allows on main (modified); the node-delta lint and the supersession-integrity check (adopted, warn-mode first; the lint on a supporting-grade premise, accepted at ratification); the designed-versus-built read at Stage 7 (modified to a read of the node-delta block against the branch); retired IDs tombstoned and never reused, no future-state folder on main, and no new artifact type or status (adopted; the catalog standard already requires the first two).

### 8. Who writes each catalog level when a change alters a process

| Level | Writer | When | Verified by |
|---|---|---|---|
| L0 universe, L1 value stream, L2 sub-process | the Engineering spoke, by hand | DRAFT at Commit 0 from the node-delta block; ACTIVE in the build commit | Stage 7 designed-versus-built; the operator at Stage 9 |
| L3 activity | the Engineering spoke; seeded from source once the catalog generator ships, then corrected by hand | as L0–L2 | as L0–L2, plus the generator's validator once tracked |
| L4 step rows | generated once the generator ships; hand-written and reviewed until then | the build commit | Stage 7 review |

No seeder or catalog generator is tracked on main at authoring; the catalog's generator — chosen by the engine decision, which settled that the catalog is built by a new small generator reading page frontmatter, built reuse-first — exists only as a prototype in the analysis workspace. Until it ships, every level is written by hand.

### 9. The engineering-harness universe takes its projection by reference

A change to the harness ships through the release pipeline, so the release projection's rows apply to it. The harness's runtime processes — install, update, checks, scheduled audits, usage measurement, session retros, gate-mode graduation — run on a schedule or an event, not at a position in a change, so a projection of their own would place almost every node in Operate and distinguish nothing. Their documents enter the declaration as `continuous` rows only when a stage or a future change reads them (an audit report read at intake; a warn log read when a gate graduates).

### 10. Who keeps a living delivery document current

The parent epic's Out list sends system documentation to the documentation pipeline, which keeps catalog pages current. For every other living delivery document, the upkeep owner is the producer the declaration's `updated at` names: for a project document, the skill the project entity model's owning-agent matrix names; for a release document, the stage. Its cadence comes from the hook. No new owner role is created.

### 11. Seams

| Seam | State | What it means for this design |
|---|---|---|
| The documentation model (ADR-224) | final | the page statuses, the catalog's levels and its generation boundary are reused unchanged; the declaration is normative and the catalog descriptive, so the two document vocabularies do not collide |
| The documentation pipeline (keeps pages current) | open, coordinating | it verifies the pages this design writes at Stage 6; the loop's feed-back and review steps run through its gates |
| The drift engine | open, coordinating | page-versus-source drift is its check; designed-versus-built is this design's; sibling checks |
| Non-tracked homes by risk class | open | decides where `platform-instance` and `project-instance` documents physically live |
| The risk-class home ADR (supersedes ADR-141) | **provisional** — still `Proposed` on its own release branch at this record's ratification | its draft's homes are all nameable by § 5's classes (re-checked at ratification); § 5 is re-checked again when that decision is ratified |
| Project data architecture | open | applies the project projection per project; owns owners and folder homes |
| Methodology and work-item types | open | owns the pack schema and renders the resolved methodology; the hook needs no pack change |
| The catalog's design-artifact extension and its planning reads | built | the foundation the loop's read and feed-back steps reuse |
| The baseline process-catalog pages | open | receive this release's current-state inventories as input |

## Gap map

| Element | Today | Designed | Gap | Closed by |
|---|---|---|---|---|
| Declaration | two unjoined tables in a file injected into operations skills | one standard, two projections, each row carrying the attributes of § 2 (the epic's six, plus projection, span, status carrier and cadence) | the standard does not exist | the declaration slice |
| Stage list | eleven names with "Verify"; three stages missing | the 13 stages, each with a span | defect in the mapping | the declaration slice |
| Project phases | five vocabularies, no design or hypercare slot | any phase timeline maps to one span; Design and Operate exist | no mapping | the declaration slice; the gap-detection slice |
| Spans | no shared vocabulary | eight spans, one glossary term | the term and both maps | the declaration slice |
| Lifecycle registers | page statuses and agent states unregistered and colliding | both machines registered, object-typed in prose | two missing registrations; a false claim in § 13.6 that no reserved name is used | the lifecycle-register slice |
| Class per file | stated per type in a table; per file in frontmatter | one crosswalk; point-in-time mapped onto Domain C | the mapping, ratified onto Domain C | the declaration slice |
| Home class | "tracked or an instance" | durability test plus six role-named homes | the rule | the declaration slice |
| Methodology | cadence dispersed over about two dozen surfaces; "per phase" default | one member-grain section through Step 0 | the section | the methodology slice |
| Gap detection | the skill runs its own checklist; the standard's table is not read | gap detection keyed to spans, reading the declaration | the re-key and the citation | the gap-detection slice |
| Stage 5 design | comment-only except ADRs | node-delta block; pages DRAFT at Commit 0, ACTIVE when built | the block, the writes, the Stage 7 read | the loop slice |
| Catalog integrity | status and successor read at close | node-delta lint, supersession integrity, no DRAFT residue from a merged node-delta | three checks | the integrity-check slice |
| Templates | many document types have no template family | the template gap list | the list | the template-gap slice (files cards; authoring is out of scope) |

## Delivery cut (proposed with this record; ratified with it)

Each slice carries its parent's framing (work nature, owed axes, altitude, overlap considerations), per ADR-211's continuity rule. The parent owes all four design axes: `data-structure-change` owes data, structure-placement and behaviour-over-time; its secondary `defect` nature adds process-flow.

| Slice | Work nature | Answers | Depends on | Size |
|---|---|---|---|---|
| S1 — one declaration: the standard with the model, the span maps and both projections; `operational-artifacts.md` cites it and drops its two retired governance rows; the two operations skill packages rebuilt | `data-structure-change` (secondary `defect`: the stage list) | data, structure-placement, behaviour-over-time, process-flow | this record | L |
| S2 — the lifecycle register gains the page-status and project agent-state machines | `defect` | process-flow, structure-placement | S1 | S |
| S3 — the methodology section and its Step 0 reading | `data-structure-change` | data, structure-placement, behaviour-over-time | S1 | M |
| S4 — gap detection keyed to spans; the project agent's gap reference cites the declaration | `defect` | process-flow, structure-placement | S1 | M |
| S5 — the template gap list, filed as template cards | `investigation` | none owed | S1 | S |
| S6 — the loop in the pipeline: the node-delta block, the Commit-0 and build-commit page writes, the Stage 7 designed-versus-built read | `behaviour-change` | process-flow, structure-placement, behaviour-over-time | S1; published catalog pages | L |
| S7 — the catalog integrity checks, warn-mode first | `new-capability` | data, process-flow, structure-placement, behaviour-over-time | S6; the catalog generator | M |

| Milestone | Slices | Capability (after it ships…) | External dependencies |
|---|---|---|---|
| One declaration | S1, S2, S3, S4, S5 | every stage of both projections has a declared document set that gap detection reads and methodology varies | none beyond this release |
| The design lives in the catalog | S6 | a change's process design is visible as DRAFT pages before its code and becomes the current state at merge | the first milestone; the baseline catalog pages being published |
| The catalog keeps its integrity | S7 | a merged release cannot leave a designed page DRAFT, a broken supersession or an unparseable node-delta unreported | the second milestone; the catalog generator |

S7 sits in a milestone of its own because it waits on the catalog generator: kept with S6, the second milestone would carry three external dependencies, where the composition doctrine targets two at most.

## Alternatives Considered

- **Extend `operational-artifacts.md` in place** — rejected: release-pipeline rows would ship inside two operations skill packages, against module independence and "no bloat".
- **Declare the set as a generated view of the catalog** — eliminated: the catalog is descriptive and is corrected against its sources; it cannot be the source of a rule.
- **Split the declaration per module** — eliminated by the one-declaration requirement.
- **Statuses only; class-specific statuses; statuses for pages and classes for documents** — rejected or eliminated: classes carry the amend / version / keep discipline the epic requires, and no new state names may be minted; splitting the axes by object type drops one axis from each population.
- **A class table with no per-file binding** — rejected: one fact would have two homes.
- **Home classes named by GitHub object type** — rejected: they cannot name a document on another ticketing or knowledge-base host.
- **Homes decided by risk class now** — unavailable while that decision is pending.
- **The pipeline-native vocabulary (C1)** — rejected: four project phases have no unique stage, and pipeline names carry no project-delivery meaning for Triage, Bundle or Snapshot.
- **The function spine as the vocabulary (C2)** — rejected: it puts the release plan and the design under one class, and Execution and Deployment under another, so it cannot carry a design-document class in either projection.
- **Neutral classes as a replacement, or as a new catalog level** — eliminated: a replacement renames hundreds of live files where a layer reaches the same outcome; a new level would supersede ADR-224's level model, where a page field is already permitted.
- **Lifecycle-keyed variants** — rejected: their own switch test fired, because Waterfall and PRINCE2, Scrum and SAFe, and Scrum and XP each share a Lifecycle value yet differ in document behaviour.
- **Group-grain columns on the archetype matrix; a document facet on packs; a document kit** — eliminated: the first asserts a class for frozen Plan members; the second is a pack-grammar change reserved to the methodology initiative; a kit names no archetype.
- **No hook; per-project declaration only; a configuration control with no default** — rejected: the first keeps a predictive default wrong for four approaches; the second and third make every project or adopter restate the model. The configuration control stays the extension path.
- **Pages written by the Stage 5 spoke; a tracked design record per release; the comment with a pointer; documenting at close-out** — eliminated or rejected: Stage 5 commits nothing and does not produce pages; a per-release record duplicates the plan, the ADR and the pages; a comment needs the host to be read; documenting at close separates the documentation from the build.
- **A third projection for the harness** — rejected: it would place almost every harness node in one span.
- **Cutting one slice per governing file, or one vertical slice per projection** — rejected: a file-shaped slice names no user capability, and per-projection milestones would edit the one declaration file in two milestones.

## Consequences

- **Positive.** One file answers what each stage writes, for both projections and every methodology, and every other surface cites it. A design document of a release and a design document of a project share one key (Design), so a later change finds both. The gap-detection rule gains the design and hypercare slots it lacks. A change's process design becomes visible in the pull request before its code and becomes the current state when it merges. No stage is renamed, no integer moves, and no new state name or catalog level is introduced.
- **Negative.** One glossary term and one new standard enter the corpus, and the two operations skill packages are rebuilt once when the stage tables move out. The frozen Axis-2 value set reopens if a point-in-time document is shown to need Domain C's `stale` state. The loop adds page writes to Engineering and a read to Dev Testing, and its checks wait for the catalog generator. The home-class rule is provisional until the risk-class home decision lands. Per-document rows, the coded inventory and the cell-level methodology matrix stay in the analysis workspace and expire with it unless the delivery slices carry them into the declaration.

## Reversibility

EXPENSIVE once built — every declaration row, stage-spec edit and catalog check would be rewritten by a change of model. Until the delivery slices build against it, the record itself is CHEAP to amend: nothing has been built against it yet. Confidence: HIGH on the single carrier, the class-status split and the home-class durability test; MEDIUM on the span vocabulary and the methodology defaults the corpus leaves unstated; LOW on the point-in-time mapping before ratification, which settled it with a stated reopen condition (§ 4).

## Related ADRs

- ADR-224 — the documentation model: this record reuses its page statuses, levels and generation boundary, and adds a span attribute where its § 13.3 permits page fields.
- ADR-211 — work natures, design axes and the continuity rule: the coverage states and the delivery cut follow it.
- ADR-181 — citation binding: other files cite this record by its slug token until the release claim binds its number.
- ADR-004 — the five-function spine: it stays the classifier of the kind of work; the spans classify position.
- ADR-141 — the operator-instance home: the pending risk-class home decision supersedes it, and § 5 is provisional on that.
- ADR-080 — the project folder taxonomy: project instances keep its folders; this record fixes only the home class.
- ADR-069 — the methodology pack as the composing unit: the hook adds no pack facet.

## References

- #8150 — the stage-to-document epic this record founds, with its 2026-10-24 widening to the full loop and its leading hypothesis
- #8157 — the design card whose design this record carries, ratified at the Stage 9 gate
- #8153 — the release-stage inventory card, verified at head
- #8154 — the project-delivery inventory card, verified with its noted observations
- #8155 — the stage-crosswalk card, verified with its refreshed rename costs
- #8156 — the methodology-variation card and its hook options
- #8117 — the documentation-model spike that ADR-224 answers
- #8114 — the documentation-pipeline epic that keeps catalog pages current
- #8112 — the drift-engine epic, sibling to the designed-versus-built check
- #8005 — the epic that homes non-tracked surfaces by risk class
- #8016 — the pending ADR that homes non-tracked data by risk class
- #8115 — the baseline catalog pages that receive the current-state inventories
- #7402 — the epic that renders the resolved methodology in every skill
- #8118 — the engine decision: a new small generator, built reuse-first
