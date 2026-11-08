---
title: "ADR-233 — The composition method is a core method that role skills cite, entered through one altitude-dispatching mode on the release planner"
status: Accepted — operator-ratified at the composition-method-host-decision Stage 13 Close ratification beat (Phase A13), 2026-11-08, under the operator's standing close-out direction of 2026-11-07
date: 2026-11-05
release: composition-method-host-decision
deciders: "operator (host, record-module, no-kind-path and record-amendment decisions at the Stage 5 scope lock; ratification at the Stage 13 close gate) + Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + Phase A6.5 adversarial design reviewer"
tags: [architecture, composition, decomposition, method-host, entry-point, altitude, skill-boundary, module-boundary, extend-before-create, methodology-neutral, grouping-label]
source_observations:
  - "At origin/main b1042eec nothing in the tracked corpus authors an epic's composition: every stage spec and skill that names one reads or checks it. A fixed-string probe for 'epic composition' returned 0 files against 6 for its control, 'epic-composition' (measured 2026-11-05)."
  - "Module dependency rules at b1042eec: operations references core only, with no exception. Release references core only, except that a documentary cross-reference may point at an entry in the operations module's Public API. That Public API lists the intake desk and the process designer, whose capability covers requirements definition and gap analysis; it does not list the business-analyst Specialist, which composes the process designer. Core references neither consumer module by path."
  - "Grouping role at b1042eec: 0 level_role declarations across the 4 kinds of the 3 shipped pack manifests, against 3 declarations in two test-fixture packs read by the same probe. The pack validator reports grouping=0 execution=4, and its self-test pins the shipped corpus at that value."
  - "Readers of the grouping role at b1042eec: the pack validator's domain rule, its level-footprint count and the self-test arm that pins the shipped corpus at grouping=0 execution=4; the intake desk's derived type registry, which takes grouping against execution from the declared role; and the work-item authoring standard's section 3, which states that the role has zero instances in the shipped manifests. The deploy-time pack-conformance check reads only the validator's pack, caveat and skip rows, never the grouping count. 13 tracked files name the field; the rest define it, record it historically, or are test fixtures (measured 2026-11-05)."
  - "Representation of the tier above the epic at b1042eec: ADR-049 (Accepted), Decision 1, defines an initiative as a multi-milestone grouping theme carried by a cross-milestone grouping label, never a container tier or a parent_ref target. The label taxonomy's initiative-labels section states that an initiative is never materialized as a standalone issue and is represented by its grouping label plus the roadmap that sequences it. The pack corpus README states that covering every organizational level needs no kind above the Work-Item one. The deferred grouping-tier card's body does not cite ADR-049 (read 2026-11-05)."
  - "Trigger collision, measured 2026-11-05 at b1042eec with the trigger-collision gate's own scoring primitives over all 56 skills: the five D6 phrases score at most 0.048 as a skill of their own. Added to the release planner, its highest pair is 0.094, and its pairs with the intake desk and the roadmap curator are 0.026 and 0.027 (escalate threshold 0.30; watch band from 0.201). An intake-shaped control phrase set scores 0.643 against the intake desk."
  - "Write-path precedent at b1042eec: the release planner's pattern review drafts each literal issue body, persists it to a handoff file and changes no tracker state. The release executor's pattern-review execute files each approved body verbatim with that file as its input, then reads the filed issue back against it, and its failure modes name re-rendering a body after approval as a defect. The intake desk's triage-readiness check returns a pass, or the failing test with its rewrite, and does not re-elicit a passing item. The planner's text records that a separate bundle-composer skill would be the absorb anti-pattern ADR-019 forbids."
  - "Skill size against upstream guidance, measured 2026-11-05: the upstream skill-creator's progressive-disclosure section says to keep a SKILL.md under 500 lines and move detail into references. At b1042eec the release planner's SKILL.md is 750 lines and the roadmap curator's is 375."
  - "Invokable-method precedent at b1042eec: the root-cause-analysis method in core/disciplines names its invocation points and is cited by six skills across both consumer modules."
supersedes: none
---

# ADR-233 — The composition method is a core method that role skills cite, entered through one altitude-dispatching mode on the release planner

## Status

**Accepted** — operator-ratified at the `composition-method-host-decision` Stage 13 Close ratification beat (Phase A13), 2026-11-08, under the operator's standing direction of 2026-11-07 to carry milestones through cleanup and close-out, applied to this record alone. Authored in that release from the design rendered at its Stage 5 Solutioning, as amended by that design's adversarial review and the release's scope lock. The ratification is read from this file's `status:` field, never inferred from milestone closure. Once Accepted, it changes only through a superseding record.

**Numbering provenance — `230 → 233`.** Held **ADR-230** branch-local; renumbered to **ADR-233** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 230. In-release citations that read "ADR-230" denote this record.

## Context

Composition derives one grouping from many candidate items. It has a method at one altitude and none at another. This section states what exists today, what this decision makes true, and each gap between the two, with the owner that closes it.

### Current state

- **At the milestone altitude,** the bundle-composition doctrine constructs a release bundle from a named capability. The doctrine's inductive-entry work adds the entry it lacks.
- **At the epic altitude,** there are consumers and no producer. Stage 3 parses an epic's composition table. Stages 1 and 2 relate items to a named epic. The release planner reads epic pull-in tables when it checks ownership. The roadmap curator places work into a ratified initiative set that it never re-draws. A seven-phase epic-readiness method ran one full loop on the platform's backlog, and it is recorded only in an archived operator-local project.
- **Above the epic,** the platform has already decided the representation. ADR-049 defines an initiative as a multi-milestone grouping theme carried by a cross-milestone grouping label — never a container tier, and never a parent that work items attach to. The label taxonomy adds that an initiative is never filed as an item of its own: it is its grouping label plus the roadmap that sequences it. No shipped pack declares a kind for this tier, and the pack corpus states that covering every organizational level needs none. A deferred grouping-tier card proposes declaring one.

The only entry point that is always available files a single work item. That is part of why work arrives as unit-level fixes rather than as cohesive features. The higher altitudes need an entry point that is just as easy to reach.

Five rules in force bound the answer:

1. **Extend before create.** A net-new surface placed beside infrastructure that plausibly covers the capability must state why in-place is infeasible; otherwise the design extends. Sources: ADR-094, and the Maintainability value, row 3 of the build philosophy in `core/disciplines/build-philosophy.md`.
2. **Compose, do not absorb.** A capability the platform already owns is invoked, never re-implemented, and a new skill needs its own triggers, its own write scope and its own primary role (ADR-019).
3. **The module boundary.** Operations references core only, with no exception. Release references core only, with one exception: it may cite an entry in the operations module's Public API. Core references neither (ADR-007). That Public API lists the intake desk and the process designer, which carries requirements definition and gap analysis; it does not list the business-analyst Specialist, which composes the process designer. The method composes capabilities in both consumer modules: business analysis and intake in operations; architecture, release planning and triage in release. Its sibling, the decomposition method, has rungs in all three modules.
4. **Methodology neutrality.** Behaviour never keys on a methodology's kind name (ADR-211, ADR-033).
   - ADR-211 defines altitude as a level of the work-organization ladder: Portfolio, Program, Project, Milestone/Workstream, Work Item. Of the method's three altitudes, only the milestone is a level.
   - An epic is a grouping kind at the Work Item level. Whether a kind groups or executes is declared by its `level_role` (ADR-180); when the field is absent, the kind executes.
   - No shipped pack declares `level_role` today, so no shipped pack yet declares a grouping kind.
   - The tier above the epic is not a kind at all today: ADR-049 represents it as a grouping label plus a roadmap.
5. **Read-only planning.** The release planner writes only its release plan, and leaves re-homing an item to the operator. It already hosts a read-only grouping verb, pattern review. Pattern review drafts each literal issue body and persists it to a handoff file without changing tracker state; an operator-explicit execute mode on the release executor then files each approved body verbatim and reads it back.

### Future state

Once this record is Accepted and the codification story has built on it:

- The composition method is one method document in `core/disciplines/`, cited by the role skills that run it and restated by none (D1).
- It has one entry point: a mode on the release planner, reached through trigger phrases on that skill's frontmatter `description:`, that picks the phases by the composed container's position (D2, D4, D6).
- One composition has one approval artifact: a persisted composition proposal carrying the groupings, their membership, the reasoning, and every new card's literal draft, each draft checked by the intake desk before the operator approves (D2).
- It has one write path: an operator-explicit execute step on the release executor files every approved body verbatim, wires membership, and reads both back (D3).
- Membership is durable in every pack: a native parent where the selected pack declares a grouping kind, and a grouping label on each member where it does not (D3, D5).
- The milestone altitude routes to the existing doctrine unchanged. The tier above the epic stays as ADR-049 represents it — a grouping label plus a roadmap — with placement through the roadmap curator (D4, D7).
- The decomposition method and the design-axis toolkit share this record's answer on where a method lives (D9).

### Gaps

Each gap between the two states, and its owner. The References section maps each owner's role to its work item.

| Gap | Closed by | How |
|---|---|---|
| Where the method lives and how it is entered is undecided | this record | D1, D2 |
| No method document, no planner mode and no execute step exist | the codification story | D10's edit set |
| Whether the execute step is a new executor mode or a widening of pattern-review execute | the codification story | its own solutioning, against D3 |
| The planner's text says its only file is the release plan, yet pattern review persists handoff files; the proposal file inherits that ambiguity, and where an approved proposal is kept after execution is unstated | the codification story | it states the handoff file's class and retention in the planner's read-only principle (D10.2) |
| The planner's skill body already exceeds the upstream size guidance, and a further mode deepens that | the codification story | the mode's procedure goes in the skill's references (D10.2) |
| The Scrum pack declares no grouping role, so the grouping position resolves no kind even in the platform's default methodology | the Scrum grouping declaration — a precondition the codification story carries, or a card of its own | D10.4 |
| The tier above the epic has no kind, and ADR-049 forbids filing it as an item | the deferred grouping-tier card, and only by reconciling with ADR-049 Decision 1 or through a record that supersedes it | until then ADR-049's representation governs, and the method files nothing there (D4, D5) |
| The design-axis toolkit has no carrier | the design-axis toolkit card | it decides its carrier against D9 |
| Which decomposition rungs cite the decomposition method | the decomposition epic's next-slice card | D9 |

## Decision

### D1 — The method's home

The composition method is a **method document in `core/disciplines/`**. The role skills that run it cite it, and none restates it. It takes the shape of the root-cause-analysis method: a thin, invokable procedure that names its invocation points and uses the capabilities it composes where they already live. The document names the skills it composes by skill name only, never by path, because core references neither consumer module. Its home extends the module-boundary seam: core is the shared kernel that both consumer modules cite.

**The composition phase set.** The method document defines the phases, in order. This record fixes only their four groups, as the codification story's acceptance criteria state them:

- the **inductive entry** — a candidate set in, candidate groupings out, with the reasoning recorded;
- the **discovery front-end** — current state, pain points, requirements traced to them, fit and gap against existing work, solution design and future state, with the entry conditions under which each phase is optional;
- the **grouping deliberation** — which candidates cohere into a grouping, which do not, and why;
- the **execution rigor** — a snapshot before any change, a readiness check on every drafted card, a validation verdict, and a disposition queue.

This record calls the whole ordered list *the composition phase set*.

**Extend-before-create determination (SR-G6):** `net-new because in-place is infeasible: the one surface that covers composition, the bundle-composition doctrine, is a release-module standard scoped to milestone bundles, and the method must be citable from both consumer modules — the capabilities it composes and the rungs of its sibling decomposition method sit in operations, release and core, and the module boundary admits a surface citable from both only in core (ADR-007); the core invokable-method precedent, the root-cause-analysis method, is scoped to defects and covers no grouping.` The posture comes from ADR-094 and from the Maintainability value of the build philosophy (row 3).

### D2 — One entry point

The method is entered through **one altitude-dispatching mode on the release planner**.

The mode is thin. It resolves the composed container's position (D4) and runs the phases the method assigns to that position. Its output is a **composition proposal**, persisted as one handoff file, the way the planner's pattern review persists each drafted body for its execute step. The proposal carries:

- the candidate groupings, and each grouping's membership;
- the reasoning for each grouping, and for each excluded candidate;
- the literal draft of every new card to be filed, including a grouping's own card when its position resolves a kind;
- where a position resolves no kind, the grouping label each member is to carry (D5).

The mode changes no tracker, governance or corpus state: the proposal file is its one artifact. Before the operator approves, the intake desk checks every new card's draft (D7). The operator then approves the proposal as written — the literal drafts, not a summary of them — and that one approval is what the execute step carries out (D3). At the milestone position, the mode routes to the planner's existing backlog-analysis mode and the bundle-composition doctrine.

**Structural determination.** The release planner's mode set was reviewed and **changed**, because the planner already holds the platform's grouping verbs: milestone bundling, and pattern clustering through a persisted draft with an operator-explicit execute step. A further grouping verb on the same draft-then-execute split extends a structure that already works. The planner's read-only contract is **retained**: like pattern review, the mode persists a handoff artifact and changes nothing else.

- **Best practice:** the method is cited, not copied (ADR-019). The host skill's frontmatter `description:` is its triggering surface, as the skill-authoring convention requires; the mode's procedure sits in the skill's references, because the skill body already exceeds the upstream size guidance (Consequences).
- **Scalability:** a new altitude is a new row in D4, not a new skill. Packs supply the kinds.
- **Maintainability:** one method body. The mode cites it and restates none of it.

### D3 — Where writes happen

Writes are operator-explicit and happen outside the planner, in **one execute step on the release executor** that the operator invokes with the approved proposal file. The step follows the executor's pattern-review execute by mechanism, not only by name:

1. **Validate the input.** The proposal file exists, every new card's draft in it passed the intake desk's check, and the operator's approval is explicit in it, never inferred. Any failure halts the step before a write.
2. **Snapshot** the state it will change.
3. **File each approved card body verbatim,** with the proposal's draft as the input. Nothing is re-rendered, substituted or synthesized after approval.
4. **Wire membership.**
   - Where the position resolved a grouping kind, each member is natively parented under the grouping's filed card.
   - Where it resolved none, each member is tagged with the grouping label the proposal names (D5). The label sits in a grouping-label namespace the deployment's label taxonomy registers (ADR-049, Decision 4), and is approved with the rest of the proposal. A label that does not yet exist is created deliberately, with a colour, before it is applied — never brought into being by applying an unknown name, which the label taxonomy names as the ungoverned path. A member that already carries a grouping label in that namespace is not relabelled; it goes to the disposition queue.
5. **Read both back** — each filed body against its approved draft, each member's parent or label against the proposal — and halt on a mismatch.
6. **Record a validation verdict,** and route anything not applied to a disposition queue for the operator.

Whether that step is a new executor mode or a widening of its pattern-review execute mode is the codification story's call.

### D4 — The altitude parameter

The parameter reads **ADR-211's altitude term**: the composed container's position on the work-organization ladder, refined at the Work Item level by the kind's declared `level_role`. It defines no altitude vocabulary of its own.

| Composed container | Ladder level (ADR-211) | Declared role | Resolves through | Phases run |
|---|---|---|---|---|
| A milestone | Milestone / Workstream | none — an entity tier, not a kind | the entity model, never a pack kind | route to the release planner's backlog-analysis mode and the bundle-composition doctrine, as the doctrine's inductive-entry work leaves it |
| A grouping of work items | Work Item | `grouping` | the selected pack's kinds that declare `level_role = "grouping"`; where none does, a grouping label (D5) | the composition phase set (D1); the method document states when its discovery front-end is optional |
| A coordination container above the grouping kind | none — a grouping theme, not a level on the ladder (ADR-049) | a grouping above a grouping kind | today, ADR-049's representation: a grouping label plus a roadmap, never a filed item. A kind only once the deferred grouping-tier card declares one **and** that declaration reconciles with ADR-049 Decision 1, or a record supersedes that decision | the discovery front-end over the whole container, then the composition phase set for each grouping it yields; placement goes to the roadmap curator (D7) |

A requester's words — "milestone", "epic", "initiative" — are hints. The mode maps them onto these positions through the selected pack's declared kinds and the entity model. It never branches on a kind name.

### D5 — When the selected pack declares no kind at a position

When that happens, the mode does four things:

1. It runs every phase whose output doesn't need the container to be a typed item: discovery, the grouping deliberation, and drafting child cards at their own resolvable positions.
2. It files no item for the container, and carries the grouping on the mechanism the platform already uses for a grouping that is not a typed item:
   - **At the grouping position,** the proposal names a grouping label and the execute step applies it to each member (D3). The work-organization mapping framework already treats a backlog grouping such as an epic as a grouping label, not a hierarchy level.
   - **At the coordination position,** the reason no item is filed is ADR-049, not only the missing kind: ADR-049 makes that tier a grouping label plus a roadmap, never a filed container. The proposal hands the groupings it yields to the roadmap curator for placement into the ratified initiative set.
3. It says so in its output, naming the position, the resolved methodology, and the owner of the missing declaration. The selected pack owns the grouping position. The coordination position takes a kind only if the deferred grouping-tier card reconciles with ADR-049 Decision 1 or a record supersedes that decision; until then ADR-049's representation governs, whatever a pack declares.
4. It never invents a kind. It never files the container as the grouping kind, which would make a grouping of groupings — the platform's kind-binding rules never propose one. It never keys on a kind name or a label name: the grouping label is a value the proposal carries, never a branch condition. It never falls back silently to another methodology's kind (ADR-033).

The milestone position never takes this path, because it resolves through the entity model. Today the coordination position takes it in every shipped pack, by ADR-049. The grouping position takes it in Kanban, whose pack declares only `card`, and in Scrum until its `epic` kind declares `level_role = "grouping"`. In each case the grouping persists on its label rather than being lost.

### D6 — Trigger phrasing

The host skill's frontmatter `description:` carries these trigger phrases for the mode, so the entry point is reachable without knowing which skill hosts it:

- "compose an epic from these items"
- "group this backlog slice into epics"
- "which epics does this initiative need"
- "derive the epics for this initiative"
- "shape these loose items into cohesive features"

The words "epic" and "initiative" are there because requesters use them; the behaviour keys on D4, not on them. The phrasing was checked against the composition-aware trigger-collision gate (ADR-114), using that gate's own scoring, over every skill:

- As a skill of its own, the phrase set stays below the gate's watch band against every skill.
- Added to the release planner's description, it keeps every pair the planner forms far below the escalate threshold, including the planner's pairs with the intake desk and the roadmap curator.

The measurement is recorded in the source observations.

### D7 — The composition boundary

Every invocation is a handoff the operator routes. None of these skills is on the auto-cascade allowlist, so no rule lets one auto-invoke another here.

| Composed capability (default owner) | The method invokes it for | The method performs itself |
|---|---|---|
| Business analysis (the business-analyst Specialist, which composes the process designer; a release-module host names the process designer, the operations Public API's route to requirements definition and gap analysis) | the discovery front-end at the coordination position: current state; pain points, including intent against actual; requirements traced to those pains; fit and gap against existing work | framing the candidate set and the requested position; deciding which discovery phases are optional at which entry condition; carrying discovery outputs into the proposal |
| Architecture (the architect Specialist) | solution-design grounding of each candidate grouping: component boundaries, blast radius, and answers to the design axes the grouping's work nature owes (through the design-axis toolkit) | recording, per candidate grouping, which design questions it owes and the coverage state each answer returns |
| Release planning (the release planner's backlog-analysis mode and the bundle-composition doctrine) | everything at the milestone position, and later the bundling of composed groupings into milestones | nothing at the milestone position — it routes |
| Triage (pipeline triage) | the readiness of every card the write step files or re-homes: definition of ready, duplicate and subsumption, dependency state | the cohesion deliberation — which candidates group, which do not, and why |
| Intake (the intake desk) | its triage-readiness check of every new card's literal draft, before the operator approves: a pass, or the failing test with its rewrite. It does not re-elicit a passing draft | drafting each new card's literal body from the grouping's membership and reasoning, including the grouping's own card when its position resolves a kind; revising a failing draft from the desk's rewrite and checking it again |
| *Neighbour:* the roadmap curator | placing a composed coordination container's groupings into the ratified initiative set, or re-baselining when the set itself must change | never re-draws the ratified initiative set |
| *Neighbour:* the release executor | the execute step (D3): verbatim filing, membership wiring, read-back | — |

### D8 — What this decision does not change

This decision changes none of these three entry points:

- **The milestone doctrine's entry point.** That covers the release planner's backlog-analysis mode, its bundle trigger, and the doctrine's own entry as the doctrine's inductive-entry work leaves it. This record does not freeze that work.
- **The roadmap authoring criteria** — section 3 of the initiative-roadmap framework.
- **The single-item intake path** — the intake desk's modes and triggers. The composition path uses the desk's existing triage-readiness check and adds no mode to it.

The codification story this record gates edits none of these: the bundle-composition doctrine, the initiative-roadmap framework, the roadmap curator, the intake desk.

One derived behaviour does change without an entry-point or file change. Once the Scrum pack declares its grouping role (D10.4), the intake desk's derived type registry reads the Scrum `epic` as a grouping kind, as the desk's own worked example already describes it. "Unchanged" here means the entry points and their files, not every behaviour derived from the packs.

### D9 — The sibling hosting questions

**The decomposition method: one shared answer on the home, separate answers on the entry.**

- **Home.** It is likewise a method document in `core/disciplines/`, cited by role skills and never a new skill, for the same reasons: its rungs sit in three modules, and only core is citable from all of them.
- **Entry.** Composition is invoked deliberately at a chosen position, so it has one dispatcher. Decomposition is a step inside many flows — the intake desk's child-decomposition callout, triage's oversize routing, and the cut that follows an epic's framing. So each of those rungs cites the method, and none dispatches. Which rungs cite it belongs to the decomposition epic's reach work.

**The design-axis toolkit: the same kind of home, but a separate document.**

- ADR-211 has settled the axis model, so the toolkit's carrier is answered now rather than jointly later.
- The toolkit is a reference document in core that role skills cite, keyed on ADR-211's work nature. Its own card decides its carrier against this answer.
- The composition method points to the toolkit at its solution-design phase but does not host it. The toolkit is consumed at two points — an epic's framing and the cut — so hosting it inside one consumer would make the other depend on that consumer.
- The two would become one answer only if the composition and decomposition methods merged into a single core method and the toolkit had no consumer outside it. Neither holds.

**Shared vocabulary.** Both methods key work on ADR-211's work-nature key and read altitude as D4 states it.

### D10 — What the codification story then edits

1. The method document in `core/disciplines/`, which is new. It defines the composition phase set (D1). The archived method's templates and scripts are recovered into it, verified against live state, and depersonalized.
2. The release planner: one composition mode, with its procedure in the skill's references and only its entry in the skill body; its trigger phrases on the skill's frontmatter `description:` (D6); the proposal handoff file, with its class and retention stated in the planner's read-only principle; and at least three domain failure modes. It is edited through the skill editor, with its package rebuilt.
3. The release executor: the execute step of D3 — verbatim filing, membership wiring, read-back — under the same discipline.
4. **Precondition — the Scrum grouping declaration.** The Scrum pack's `epic` kind declares `level_role = "grouping"`. The same change reconciles every reader the declaration moves:
   - the pack validator (`core/deploy/tools/check-work-hierarchy.py`): its domain rule admits the value, and its self-test arm that pins the shipped corpus at no grouping kind moves to one grouping kind, the rest execution;
   - the work-item authoring standard (`core/standards/work-item-authoring-standard.md`), section 3, whose sentence that the role has no instance in the shipped manifests is restated to the new state;
   - the intake desk's derived type registry, which reads the change with no file edit (D8);
   - no deploy-time check reads the grouping count, so none moves.

   Until the declaration lands, the grouping position takes D5's path in Scrum.

**Sequencing:** the bundle doctrine's inductive-entry work edits the release planner's backlog-analysis step, which this mode routes to. That work lands first, or the codification story rebases onto it.

## Alternatives Considered

| Option | Decision | Why |
|---|---|---|
| A thin dispatcher mode on the **roadmap curator**, with the method in core | Rejected — the strongest alternative | The curator is the roadmap-maintenance subdomain. It gates every run on an operator-local roadmap baseline that epic composition doesn't need. Its re-baseline slices initiatives straight into milestone-sized capability slices, so epics are as foreign to it as to the planner. And the milestone route would leave the skill instead of staying inside it. |
| A **release-planner** mode with the method held in that skill's own references | Rejected | The operations module, which references core only, could not cite the method. Nor could the decomposition method share it, because its rungs sit in all three modules. |
| A **roadmap-curator** mode with the method held in that skill's own references | Rejected | It carries both sets of costs above. |
| A **dedicated composing skill** | Rejected | In-place routes exist, so the net-new determination can't be stated (ADR-094). Its grouping triggers duplicate the planner's milestone bundling and the curator's initiative re-baseline, so it fails the first conjunct of ADR-019's boundary test. The release planner already rejects a separate composer skill for exactly this reason. |
| A **core method document with no single entry point**, cited at each altitude | Rejected | It answers where the method lives but not how it is entered: there is no one entry point, and no `description:` to carry a trigger. |
| A mode on the **intake desk** | Rejected | Intake files one typed item per request, and never decomposes or groups (ADR-016). An operations host would also have to reference release skills, which the module boundary forbids. |
| A mode on the **product-owner Specialist** | Rejected | An operations host would have to reference the release planner, triage and the architect, which the module boundary forbids. |
| **Recover the archived method operator-locally** | Rejected | An operator-local method is not invokable from the tracked corpus, and its pointers are already broken. |
| **New cards authored through the intake desk after approval,** one request and one confirmation per card | Rejected | Either the filed cards differ from the drafts the operator approved, or the operator approves drafts that do not yet exist; in both cases the approval stops binding what is filed — the defect the executor's pattern-review execute already names. It would also bring back per-card filing friction. The desk keeps its role by checking each draft before approval. |
| **Keep an unresolved grouping in the proposal only,** and file nothing for it | Rejected | Wherever no grouping kind resolves, the grouping deliberation would leave no durable output. A grouping label carries it on a mechanism the platform has already decided. |
| **Idle at a position with no kind:** report the missing kind and stop | Rejected | The platform already represents both positions without a kind — a grouping label at the grouping position, and ADR-049's grouping label plus a roadmap at the coordination position — so stopping would discard output a governed mechanism can hold. |
| **File the coordination container as a typed item as soon as a pack declares a kind for it** | Rejected | ADR-049 Decision 1 makes that tier a grouping label, never a container or a parent; filing it would contradict an Accepted record without superseding it. The forward path is conditional instead (D4, D5). |

## Consequences

**Positive.**

- The epic altitude gets a producer, reachable without knowing its host.
- The method is written once and cited, never copied.
- Composition, decomposition and the design-axis toolkit share one answer about where a method lives.
- The release planner changes no tracker state, and no new skill is created.
- One approval binds one artifact: the operator approves the literal drafts once per proposal, and those exact bodies are filed.
- A composed grouping persists in every pack — as a native parent where a grouping kind resolves, as a grouping label where none does.
- The altitude parameter reuses the platform's existing term, so it adds no vocabulary to reconcile.

**Negative, stated plainly.**

- The release planner gains another grouping verb, and grows. Its skill body already exceeds the upstream skill-authoring guidance to keep a skill body under 500 lines (measured in the source observations). The mode stays thin only while the method's body stays in the core document and the mode's own procedure sits in the skill's references.
- A composition now crosses three skills — the planner, the intake desk and the executor. The persisted proposal makes a skipped handoff visible, but does not prevent one.
- The one entry point sits in a release-module skill. Operations-module skills can cite the core method, but cannot route to that entry point, because operations references core only.
- Until the Scrum pack declares its grouping kind, Scrum groupings — the platform's own default methodology — live on labels rather than native parents. In Kanban, whose pack declares only `card`, they live on labels for as long as that holds.
- A grouping carried on a label has no card of its own: no body, and no readiness or done criteria. The proposal is its only description.
- The coordination container is never a typed item while ADR-049 Decision 1 stands. A typed one needs the grouping-tier card to reconcile with that decision, or a record that supersedes it.
- The collision check is lexical. Two phrasings with different words and the same meaning can still compete for a request.

## Reversibility

**MODERATE / Confidence MEDIUM.**

- Before merge, the record is revised in place or reverted.
- After ratification, it is superseded rather than edited, at a cost that grows as the codification story builds the document and the mode on it.
- Confidence is HIGH on the home, where four independent constraints agree. It is MEDIUM on the entry host, which was a judgment between two candidates that both survived elimination.

## Related ADRs

- ADR-007 — the module boundary, which decides the method's home.
- ADR-016 — intake files one typed item; why intake is not the host.
- ADR-019 — compose, not absorb, and the skill-boundary test.
- ADR-033 — methodology-conditional activation; why the no-kind path never falls back silently.
- ADR-049 — the initiative as a grouping label plus a roadmap, never a container tier; why no coordination container is filed, and the condition on any kind for that tier.
- ADR-094 — extend-before-create as Stage-5 criterion SR-G6.
- ADR-114 — the trigger-collision gate the phrasing was checked against.
- ADR-180 — `level_role`, the declared carrier of grouping against execution.
- ADR-211 — work nature, and the altitude term this record reads.

## References

The numbers below are provenance. The prose above leads with self-describing roles, so its meaning survives renumbering; each gap owner in Context names the role its line here gives.

- #6390 — the spike this record decides.
- #6388 — the composition-methods epic.
- #6389 — the codification story this record gates.
- #5870 — the doctrine's inductive-entry work at the milestone altitude.
- #6420 — the decomposition-method epic, whose hosting question D9 answers.
- #8099 — the decomposition epic's next-slice card, which coordinates with this decision.
- #7540 — the epic-framing epic.
- #7961 — the design-axis toolkit card in `epic-framing-states-axis-coverage`, whose carrier D9 answers.
- #7965 — how a framing states its altitude; D4 reuses the same term.
- #7539 — the deferred grouping-tier card, which proposes a kind above the epic.
- #754 — the invokable-methods precedent.
