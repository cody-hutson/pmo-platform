#### From the decision record — `### Terms` (whole subsection)

### Terms

- **Work nature** — how a piece of work relates to the solution's existing behaviour and structure; always two words. Not the work-organization mapping framework's "by nature" placement (meaning: without per-user governance).
- **Design axis** — a surface of the solution a framing must answer on: an ISO/IEC/IEEE 42010 viewpoint framing one concern, the framing's answer being the view. Not the architect role's altitude axis (ADR-127), design exploration's distinctness axes, a decision's own dimension (ADR-063), or the workspace-layout guide's design principle.
- **Users** — the operators and the agent sessions the platform governs. A change to what a check asserts, or to what a hook blocks or emits, changes what users get.
- **Altitude** — the level of the work-organization hierarchy at which a framing states its question (the per-level purpose ladder of the work-organization mapping framework).
- **Overlap considerations** — duplication or subsumption between an epic's slices and with other open work, and the shared surfaces the work touches: topics at framing, and files once the cut assigns them.

#### From the decision record — `### Work natures` (intro sentence and table)

### Work natures

The single key, orthogonal to kind, altitude, deliverable class and filing form: any story, task, epic or work item can carry any nature.

| Identifier | Definition | Boundary example | Source in practice |
|---|---|---|---|
| `defect` | Behaviour departs from what an authoritative statement recorded before the work was raised — a spec, rule, contract, schema, decision record, or the stated purpose of the capability — already requires; the work restores it. | A guard applying an allowlist's host patterns to GitHub write paths, when the allowlist's own header documents those patterns as matching the host portion of a URL, is a `defect`; an undeclared allowlist row still matching either kind of destination, where no rule requires rows to declare a kind, is not. | IEEE 1044; ISO/IEC/IEEE 14764 corrective maintenance |
| `new-capability` | Adds behaviour or an artifact that no existing capability delivers in any form; its absence violates no requirement. | A settings manager where operators hand-edit raw configuration; an allowlist helper gaining an option to declare an entry's kind extends an existing helper and is not one. | SAFe features; ISO/IEC/IEEE 14764 perfective maintenance (enhancements for users) |
| `data-structure-change` | Changes an authoritative shape — the canonical declaration of entities, fields, keys or value sets — that existing records and readers depend on, so they must migrate. | Adding a versioned field set to refusal records, which their readers must branch on while records written before it carry none; rewording a file's header so it describes an unchanged row format is not a shape change. | Ambler & Sadalage, *Refactoring Databases* (2006); BABOK v3 Data Modelling |
| `integration-change` | Changes exchange across a boundary not owned on both sides: contract, adapter, exchange sequence or identity mapping. | Changing the key a sync snapshot matches external records on; renaming a field only the solution reads is a `data-structure-change`. | Hohpe & Woolf, *Enterprise Integration Patterns* (2003); BABOK v3 Interface Analysis |
| `investigation` | Produces knowledge, not change: a question answered, a decision recorded, a feasibility established in a time box. | A spike recording a model decision, though its output is a file; the card building what it specifies is not. | Beck, *Extreme Programming Explained* (1999), spikes; SAFe exploration enablers |
| `infrastructure-change` | Changes the build, verify, deploy or run environment — pipeline and CI runners, deploy mechanics, hosting, hook installation and wiring, runtime configuration — without changing what users get. | Bounding CI suite run time, or wiring an existing hook into a further session type; changing what a check asserts, or what a hook blocks or emits, changes what users get and is not an infrastructure change. | SAFe infrastructure enablers; ITIL 4 change enablement |
| `restructure` | Changes where parts live or how they compose, preserving behaviour. | Collapsing hand-copied constants into one library with unchanged results; the same move made to change a result is not. | Fowler, *Refactoring* (1999; 2nd ed. 2018); ISO/IEC/IEEE 14764 perfective maintenance (recoding to improve maintainability) |
| `behaviour-change` | Deliberately changes an existing capability's behaviour with no prior requirement violated: the intent changes. | Silencing a hook's allow path where chatter was the design; silencing it because a rule required silence is a `defect`. | ISO/IEC/IEEE 14764 adaptive and perfective maintenance; Swanson (1976) |

#### From the decision record — `### Classification procedure` (from "Classify each acceptance criterion" through **Why this order.**)

### Classification procedure

Classify each acceptance criterion; the item's nature is the nature most of its criteria carry, ties going to the earlier step, and the others are recorded as secondary. An item with no acceptance criteria is classified on its proposed change as one unit. A criterion that verifies no change — a recorded baseline, a regression guard on existing behaviour — is not classified. For each criterion, the first yes wins:

1. Its output is knowledge and it changes nothing users rely on → `investigation`.
2. It changes only the build, verify, deploy or run environment and nothing users get → `infrastructure-change`. What a check asserts, and what a hook blocks or emits, are not environment.
3. It changes a contract with a party not owned on both sides → `integration-change`.
4. It changes an authoritative shape that existing records or readers depend on → `data-structure-change`.
5. An authoritative statement recorded before the work was raised — a spec, rule, contract, schema, decision record, or the stated purpose of the capability — already requires the missing or wrong behaviour, and it can be quoted → `defect`.
6. No existing capability delivers it in any form → `new-capability`.
7. It changes where parts live or how they compose and preserves behaviour → `restructure`.
8. It deliberately changes an existing capability's behaviour → `behaviour-change`.

Otherwise the criterion fits no nature, and the coder records that it fits none.

**Authoritative sources.** A governed file in the repository, an ADR, or a ratified release plan counts as an authoritative statement. An operator comment, directive or scanner alert counts only once a governed file adopts it. Each `defect` code records its source and the basis for its authority.

**Owed set.** An item owes the union of the owed axes of its primary nature and the owed axes of every surface nature (steps 3 and 4) that at least one of its classified criteria carries. The primary nature still indexes the item's row for grading.

**Why this order.** Steps 1 and 2 classify by what the output is, and after the exclusion in step 2 they cannot overlap the later steps. Steps 3 and 4 classify by the surface touched, and each carries parts that are owed whatever the motive — coordination with a party the work does not own, and migration of existing records and readers — so a surface nature outranks a motive nature, and its owed axes join the item's owed set even when a motive nature is primary: a defect fix that changes a canonical shape still owes the migration. Step 3 precedes step 4 because an exchange-contract change usually changes an exchanged shape too, and the other party's readers cannot be migrated by this work. Steps 5 and 6 classify by motive and apply only to what remains; step 5 precedes step 6 because behaviour that is required and missing is a defect, whose expected parts (root cause, regression) differ from a new capability's. Steps 7 and 8 apply only where nothing is required and something already exists, and they split on whether behaviour is preserved.

#### From the decision record — `### Design axes` (table and the "Not axes" sentence)

### Design axes

| Identifier | Answered when the framing states | Source in practice |
|---|---|---|
| `data` | what information the work creates, reads, changes or deletes; its shape (entities, keys, value sets); its owner | Zachman, *What* (1987); Rozanski & Woods, Information viewpoint (2011); UML 2.5 class diagrams; BABOK v3 Data Modelling |
| `process-flow` | the steps — who or what acts, in what order, with which hand-offs, decision points and error paths | Zachman, *How* (1987); Kruchten, 4+1 scenarios (1995); arc42 runtime view; UML 2.5 activity and sequence diagrams; BABOK v3 Process Modelling |
| `structure-placement` | the parts, where each lives, what each composes with or depends on | Zachman, *Where* (1987); Kruchten, 4+1 logical, development and physical views (1995); arc42 building-block and deployment views; UML 2.5 component, package and deployment diagrams |
| `behaviour-over-time` | the states the solution passes through, what moves it between them, what must persist across a session, phase or version boundary | Zachman, *When* (Sowa & Zachman 1992); UML 2.5 state machine and timing diagrams; BABOK v3 State Modelling |

Not axes: Zachman's *Who* and *Why* (the framing's actor and outcome fields carry them); quality attributes such as security or performance (cross-cutting perspectives, per Rozanski & Woods, applied through the domain best-practice guides); milestone sequencing (it sequences delivery, not the solution — see the continuity rule).

#### From the decision record — `### Owed axes by nature` (the Nature and four axis columns only; then the **Grades.** paragraph)

### Owed axes by nature

| Nature | data | process-flow | structure-placement | behaviour-over-time |
|---|---|---|---|---|
| `defect` | — | owed | owed | — |
| `new-capability` | owed | owed | owed | owed |
| `data-structure-change` | owed | — | owed | owed |
| `integration-change` | owed | owed | owed | owed |
| `investigation` | — | — | — | — |
| `infrastructure-change` | — | — | owed | owed |
| `restructure` | — | — | owed | — |
| `behaviour-change` | — | owed | owed | owed |

**Grades.** E0 nothing answers the axis · E1 the item's own framing names or partly answers it · E2 a delivered design or change answers it in an item-specific passage outside a template-forced section · E2-T the only delivered passage sits in a section or field that the governing template requires for every item regardless of nature, scored as E1 — the list is derived from the templates rather than closed, and includes the issue form's Affected Files and Documentation Impact fields, the release plan's File Change Matrix and Contention Map, the Stage-5 output's Blast Radius and Output for Stage 6 blocks, and the release PR template's Documentation Impact table · E3-P a planned Stage 2–5 refinement added it, scored as E2 on delivered items and never counted for owed-ness · E3-F the item's first framing was silent on it and an operator correction, or a re-scope made because the framing missed it, supplied it. Only delivered items (closed as completed) count as delivered evidence; items closed as not planned are coded and reported but enter no count.

#### From the release plan — § Validation Study Design: the **Rubric** table

**Rubric (item × axis).**

| Grade | Meaning | Counts as |
|---|---|---|
| E0 | nothing answers or names the axis question | E0 |
| E1 framed | the item's own body, as filed or converted at triage, names or partly answers it; an open item's design passages grade at most E1 | E1 |
| E2 delivered | a completed item's delivered design or change answers it in an item-specific passage, from the first source yielding one — closing PR body, the milestone's release PR body, commits citing the item, the item's Stage-5 output — outside a template-forced section | E2 |
| E2-T template-forced | the only delivered passage sits in a section or field that the governing template requires for every item regardless of nature (B3; list below) | E1, in every rule |
| E3-P pipeline refinement | the axis surface was added at a planned Stage 2–5 step inside a surface the framing named | E2 on a completed item, E1 otherwise; never counts for owed-ness |
| E3-F framing corrective | the item's first framing was E0 on the axis, and a later record supplies it by an operator correction naming it, or a re-scope whose stated reason is that the framing missed it | counts for owed-ness; E2 on a completed item |

#### From the release plan — § Validation Study Design: the **E2-T sections** paragraph

**E2-T sections — derived from the templates, not closed (B3).** Templates read at Stage 6: `.github/ISSUE_TEMPLATE/improvement.yml` (its required fields), `release/skills/release-planner/references/release-plan-template.md`, `release/references/standards/solutioning-output-template.md` § 3, and `.github/PULL_REQUEST_TEMPLATE.md`. Sections required for every item regardless of nature that can carry axis-shaped text: the issue form's **Affected Files** and **Documentation Impact** fields; the plan's **File Change Matrix**, **Contention Map**, **Agent-Editability Read** and per-issue **Change Specification** file line; the Stage-5 output's **Blast Radius** bucket and its **`### Output for Stage 6`** block (row 7 of that template's comment frame); and the release PR template's **Documentation Impact** table, **Implementation** table and **Verification Evidence** block.

#### From the release plan — § Validation Study Design: the **Coding scheme** bullets C1–C6

**Coding scheme (one row per item).**

- **C1 nature.** Run the record's procedure on each acceptance criterion (first yes wins per criterion); the item's primary nature is the one most criteria carry, ties to the earlier step; the others are secondary. No criteria → the proposed change as one unit. A criterion that verifies no change is not classified. Step 5 needs an authoritative statement (B1): a governed file, an ADR or a ratified release plan; an operator comment, directive or scanner alert only once a governed file adopts it — **each `defect` code records its source and the basis for its authority**. The item's **owed set** is the union of its primary nature's owed axes and those of every surface nature (steps 3–4) any classified criterion carries (B2). NO-FIT records the matching candidate. Crosswalk hints (type-map row, `type:` label, requirement type) are recorded; the procedure wins.
- **C2 axis grades.** Quote each graded passage (at most 25 words, with source) and code it to one primary axis: the axis whose "answered when" object is the passage's main-clause object — an entity, field, key, value set or owner → `data`; a step, order, actor, hand-off, decision point or error path → `process-flow`; a part, its location, or what it composes with or depends on → `structure-placement`; a state, a transition, or persistence across a session, phase or version boundary → `behaviour-over-time`. Other axes the passage answers are secondary; grades count on the primary axis only.
- **C3** an uncovered surface with its nearest established viewpoint, or "none". **C4** who set Domain (filer or triage conversion), when stated. **C5** concept-1 class by R-C1..R-C3. **C6** `state_reason`.

