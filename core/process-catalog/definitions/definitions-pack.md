---
title: Definitions Pack (process catalog)
purpose: What a catalog page must contain — the fields, sections, vocabularies and authoring rules the validator checks — with a pointer to the standard or decision that owns each rule the pack does not own.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Definitions Pack — version 2

This pack is what a page author reads before writing and what the catalog's validator checks against. It adds only what the platform does not already define: where [the design-artifact standard](/core/standards/design-artifact-standard.md) (its section on the generated process catalog) or decision 12 of [ADR-224](/core/ADRs/ADR-224-system-documentation-is-a-generated-process-catalog.md) owns a rule, the pack names the owner and does not restate the rule.

**Machine source.** Every value list here is held in [`pack.json`](pack.json), which the tools read. If the two disagree, `pack.json` wins and this page is corrected in the same change.

Below, "the standard" is the design-artifact standard's section on the generated process catalog, cited by subsection, and "decision 12" is that decision of ADR-224.

## Reused definitions

Each concept below is defined elsewhere. A page uses it as defined there; this table says where.

| Concept | Canonical home | How a page uses it |
|---|---|---|
| Process, Stage, Phase, Step; Task and Sub-task; Hub, Spoke, Skill, Sub-agent; Domain, Area | [the terminology glossary](/core/specs/terminology-glossary.md) | The level names avoid its reserved words, and field names avoid the names it reserves |
| Page frontmatter for a file under `core/`: `title`, `purpose`, `type`, `status`, `reversibility` | [the platform-doc frontmatter standard](/core/standards/platform-doc-frontmatter-standard.md) | Every page carries all five |
| Flow classes; `flow_class` and `depicts` | [the design-artifact standard](/core/standards/design-artifact-standard.md); [ADR-089](/core/ADRs/ADR-089-embedded-design-artifact-declaration-marker.md) | Every page declares both |
| Diagram notation: the Mermaid form, swimlanes as `subgraph`, the shape and colour grammar | [the process-flow diagram standards](/core/standards/process-flow-diagram-standards.md) | Every Flow diagram follows it |
| The four design axes | [ADR-211](/core/ADRs/ADR-211-design-axes-and-cut-patterns-key-on-work-nature.md) | Pages cover the process-flow axis; the generated views cover structure, data and behaviour over time |
| Reserved lifecycle state names | [the canonical lifecycle states](/core/standards/lifecycle-states-canonical.md) | None is used: a page's lifecycle is its `status` |
| What may be public, templated or instance-only | [the public-repository taxonomy](/core/standards/public-repo-vs-operator-instance-taxonomy.md) | The public-surface rules below |
| Stage boundary inputs and outputs | [the stage contracts](/core/schemas/stage-io-contracts.md) | A source for a sub-process page's Entry and exit |
| Event-log fields, event types, the release join key and its read ladder, and the log's rule for personal data | [the pipeline event-log schema](/release/references/standards/pipeline-event-log-schema.md) | Case notions and privacy, below |
| Work-item kinds and labels | [the label taxonomy](/core/specs/label-taxonomy.md) | Cited when a step creates or moves a work item |
| Gate coverage and named gaps | [the gate-efficacy standard](/core/standards/gate-efficacy-standard.md) | A source for Controls rows |
| Evidence labels; reversibility tiers; autonomy tiers | [the workspace charter](/core/CLAUDE.md.template); [the reversibility protocol](/core/specs/reversibility-protocol.md); [the autonomy tiers](/core/specs/autonomy-tiers.md) | Evidence tables, and a page's `reversibility` |
| The token estimate, and each level's token budget | the standard, § 13.2 | A page stays within its level's budget; the budgets are held in `pack.json` |
| File naming for operational artifacts | [the artifact-naming standard](/core/standards/artifact-naming-standard.md) | Not applied: it governs generated project artifacts. A page's file name is its node's ID |

## Levels

The levels, the test that places a node at each one, the tie-breaks and the token budgets are the standard's (§ 13.2), with decision 12 for the sub-process budget. The pack restates none of them. It adds one sentence: a hook is a mechanism or a control and never a value stream, and one hook rule family may be an activity.

## The page and its fields

One Markdown page per node, at the path the standard gives (§ 13.1). The standard owns the identity and source fields and the flat, inline form of the frontmatter (§ 13.3), and the link fields (§ 13.4). The pack adds four fields:

| Field | Meaning | Required at |
|---|---|---|
| `actors` | Who acts in the node, by kind (Actors, below) | L1 to L3 |
| `owner` | The actor responsible for keeping the page true | every level |
| `lens_status` | The page's verdict (Lenses and evidence, below) | every level |
| `pack_version` | The version of this pack the page was written against | every level |

`pack.json` holds the type of every field and the levels that require it.

**Reserved field names.** Four names are never used as a field, because the glossary reserves the word or the value is derived from another field. `pack.json` lists each with its reason.

**Folder names.** A universe's ID is never the name of a folder the catalog reserves for something that is not a page. The validator holds those names and reports a clash.

**Sections and tables.** `pack.json` holds the sections a page of each level must carry, in order, and the columns of each section's table. An activity page carries a **Step profile** section: a two-column table whose rows summarize the page's own Steps table. Its rows "Deterministic steps" and "Judgment steps" are counts, and each equals the number of Steps rows whose Model need carries the matching value; decision 12 owns that rule and `pack.json` holds the pairs. Its other rows, "Harness features relied on" and "Context read", are written by the author.

**Navigation and sources.** Every page ends with a Navigation section and then a Sources section. The navigation links sit between the two markers `pack.json` holds.

**A step is a row.** Each row of an activity page's Steps table is one step. Its first cell is the step key, which names the step everywhere else on the page. A step key is lower-case letters, digits and single hyphens; its first segment is letters only; and no run of digits in it is longer than three characters. Each row names its inputs and outputs with their shape (for example "issue body → triage comment with its six sections"), so a test case can be written from the row alone.

**A tool call is a mechanism.** A tool call is written in the Mechanism cell of the step that makes it. It is never an activity of its own.

**Files named on a page.** A file a page names by its bare name is a tracked file, or a file of the page's own sources.

**Pipes in tables.** A code span inside a table row holds no unescaped pipe: the host splits a table cell on every unescaped pipe, inside a code span too. Write `\|`, or reword.

## The flow diagram

The standard requires a page to draw its flow in Mermaid (§ 13.8, with decision 2 of ADR-224), and the process-flow diagram standards own the notation. The pack adds two rules.

- **Node limit.** A flow stays within the node limit `pack.json` holds for its level. A flow that needs more nodes is two pages.
- **Keywords.** A node ID is never exactly one of the Mermaid keywords `call`, `click`, `end`, `style`, `class`, `classDef`, `subgraph` or `linkStyle`: the parser rejects the line. The match is case-sensitive. A statement line and the text of a label do not count.

## Page lifecycle

The lifecycle states, the retire step and the rule that staleness is derived are the standard's (§ 13.6), with decision 6 of ADR-224. The pack adds two rules: an `ACTIVE` page never reads `not-assessed`, and a page becomes `ACTIVE` only in a change that also re-verifies it, so `status` and `last_verified_commit` move together.

## Actors

A value of `actors` or `owner` is one of the bare roles `operator`, `hub` and `spoke`, or a kind prefix followed by a name, such as `skill:<name>` or `ci:<workflow>`. The kinds are held in `pack.json`. The three bare roles keep their glossary meanings: on a page they are actors in the process being described. An external system is named by its role, as the standard requires (§ 13.4).

**The primary actor of a decision activity is the decider.** When an activity's purpose is to approve, lock, accept or decide, its primary actor is the actor whose judgment is recorded, even where another actor performs most of its steps. The Steps table shows who performs each step. This rule is checked by review: no code detects a violation.

## Controls and the registers

The six enforcement classes, the surfaces, and the rule that a Controls row takes its class from the register are the standard's (§ 13.7) and decision 12's. The pack adds the following.

- **Class qualifiers.** A class may carry one qualifier in parentheses. Three are in common use: `mixed-mode` (the arms of one check carry different classes), `dormant` (enforcing code whose population is empty, so it cannot fire) and `tacit-duplicate` (an unwritten rule that restates a written one).
- **The controls register.** The register is the file `pack.json` names in `controls_register`, beside this file. The mechanism kinds a row may carry and the values its class cell may hold are listed in `controls_register_rules`.
- **A register-only value.** `not-a-control` is a value of the register's class cell: it marks an inventoried item that asserts nothing. It is not an enforcement class. A Controls row carries it only by citing a register row that has it.
- **A rule with no register row.** A Controls row for such a rule cites no control ID and carries the class of the standard (§ 13.7) that describes how the rule is enforced: `prose-only` when a governed document states it and nothing detects a violation. `not-a-control` is never written on a row that cites no ID.
- **Held IDs.** A control ID that is absent from the register lies in a held range listed in `pack.json`. A row that leaves the register adds its ID to `held_ids` in the same change, as a single `C-NNN` or by widening a range.
- **The highest minted ID.** `highest_minted_id` records the highest control ID ever minted, and it only rises. The rule that reads it and the rule for minting a new ID are stated in the register section of the catalog's README.
- **The registers' own rules.** The controls register and the ID registry are checked by `core/deploy/tools/check-process-catalog.py --registers-only`. The identifiers that check prints are the registers' own and are not among this pack's rule codes.

## Lenses and evidence

| Lens | Question | Typical sources |
|---|---|---|
| designed | What do the specs and skills say happens? | Stage specs, skill definitions, standards |
| built | What does code enforce or run? | Hooks, workflows, tools |
| executed | What do the records show happened? | A registered measure over this repository's own records. Decision 12 owns the rule; [the pipeline event-log schema](/release/references/standards/pipeline-event-log-schema.md) gives the log's fields. The measures are listed in [the catalog's measures register](/core/process-catalog/definitions/measures.tsv) |
| described | What do overviews and summaries say? | Orientation documents. The lowest authority; used when it is all there is |

**Authority order for describing today:** executed, then built, then designed, then described.

**A disagreement is recorded, never resolved silently.** A disagreement between lenses is recorded in the page's Evidence and routed as a work item. A page never changes its source (the standard, under Authority).

**Two designed sources that contradict each other are a recorded deviation.** The page records both in its Evidence and reads `deviates`. This rule is checked by review: no code detects a violation.

Every Evidence row carries an evidence label from the workspace charter.

### The verdict

`lens_status` is the page's verdict, one of four words.

| Word | Meaning |
|---|---|
| `conformant` | Designed, built and reproducible executed evidence agree for every step. A page reads `conformant` only when the workflows linked on its clause rows, each an input of a run-history measure that row cites, are stated between them to run every step in its Steps table. On a page with no Steps table, `conformant` needs the lenses to agree and one reproducible executed row |
| `deviates` | A recorded disagreement. The page states it in an Evidence row whose lens is a comparison |
| `unobserved` | No executed evidence that a reader of the repository can reproduce is published; the page's in-scope rows say why. It covers a page whose linked workflows are not stated to run every step in its Steps table: they run none, or some and not all. Its clause rows say what is covered, and one row states the reason |
| `not-assessed` | Not yet checked |

- **The coverage clause.** A clause row is an executed Evidence row that cites a run-history measure. Its Source cell carries, beside the measure reference, a root link to each workflow file the clause relies on. The clause is the last thing in its Observation cell: the word `covers:` followed by one or more step keys, each a code span, separated by a comma, in the order of the Steps table, none repeated. Every linked workflow is a run-history input of a measure the row cites, and every measure the row cites is one any reader can reproduce. A step that is its workflow's own act is listed only on a row that links that workflow. A clause that breaks one of these rules counts toward no verdict. The activity template shows the form.
- **Runs a step.** A workflow runs a step by one of two limbs, and the step's own Actor cell says which applies. *The Actor cell does not name the workflow:* a job of the workflow executes the mechanism the step's row names, and that job can return the step's own verdict from what a checkout of the repository holds and what the host supplies to the run. A job that runs only a sub-arm or a self-test of the mechanism does not run the step; nor does a job whose verdict input no checkout holds, so that every run can only report skipped or not evaluated. *The Actor cell names the workflow:* the step is the workflow's own act — its trigger, one of its own steps, its gate decision — and it is run on each run that reaches it. A call whose job can only report not-evaluated credits nothing. A step whose row names several mechanisms is run only when the workflow runs every one of them. A step whose actor is the operator or a hook is run by no workflow.
- **What supports no verdict.** A held row and a working-state measure support no verdict. A page whose only executed support is one install's working state reads `unobserved`, keeps those rows, and says nothing of what that install showed.
- **A sub-process takes its status from its child pages only.** Its `lens_status` is the worse of its own lenses and those of the activity pages whose `parent` it is. An Activities row that points to an activity under another sub-process passes nothing on, and an activity never inherits. This rule is checked by review: no code detects a violation.
- The verdict of a universe page and of a value-stream page is derived by the generator, as decision 12 states.

### The two markers

An executed row that cites no registered measure opens its Source cell with one of two markers.

| Marker | Meaning, true on any install | A row takes it when… |
|---|---|---|
| `no measure —` | No registered measure reads what would show this | No row of the tracked measures register reads the surface, and the surface is not an install-wide store |
| `held local —` | What would show this is a store that describes sessions or work across an install. No measure of such a store can be registered, and nothing from it is published | The surface is such a store |

The choice is by the class of the surface.

## Case notions and the activity taxonomy

A case is one run of a value stream.

| Case notion | Key | Source |
|---|---|---|
| Release | The milestone slug, resolved by the event-log schema's read ladder | The event log, through [the pipeline event-log schema](/release/references/standards/pipeline-event-log-schema.md) |
| Work item | The issue number; a status change is read from a label transition | The status labels of [the label taxonomy](/core/specs/label-taxonomy.md) |

How a recorded signal maps to a level:

| Signal | Maps to |
|---|---|
| Event-log `decision` | A decision step, or the gate at a sub-process boundary when it is a stage-gate decision |
| `gate-outcome` | The event at a sub-process boundary |
| `test-run`, `deployment-status` | A step in a testing activity; a Stage 12 step |
| `escalation`, `self-repair`, `iteration`, `re-review` | Exception paths and loops on the flow |
| `scope-change`, `release-synthesis`, `spoke-launch`, `session-retro` | A scope-control activity; a Stage 13 activity; an orchestration step; a post-release activity |
| An issue's status label moving to `approved`; from `approved` to `bundled` | The triage gate; the bundle gate |
| A stage sub-task created already `bundled` | Stage sub-task scaffolding, not intake |
| Handoff comments, in-place backup copies | Noise; excluded |

## Ready and Done

| | Ready to write | Done |
|---|---|---|
| Every level | The ID is minted; the parent page is published, or the node is a universe; the sources are listed; the pack version is stated | The validator passes the page; an independent re-derivation of a sample from source matches; every lens is evidenced or marked `unobserved` with its reason; every disagreement is recorded in Evidence |
| Value stream | The operator has seen the list of value streams | The Sub-processes table lists every sub-process whose `parent` it is |
| Activity | — | Every step row has a source link and its input and output shapes |

## Privacy and the public surface

- A page names a system by its role and its configuration key, never by the key's value.
- No person's name or handle appears on a page, the operator's included: the actor is `operator`. The handle rule is [the depersonalization specification](/core/standards/depersonalization-spec.md)'s.
- Operations as practised is described as a process, not as a record of an employer's work.
- Anything drawn from the event log also follows that log's own rule for personal data, in [the pipeline event-log schema](/release/references/standards/pipeline-event-log-schema.md).
- What executed evidence may appear on a page is set by the rules for an executed Evidence row: the standard, and Lenses and evidence above.
- A page carries no issue or pull-request number (the standard, § 13.4, under Evergreen references).

## Quality rubric

Each criterion scores 0, 1 or 2. A page passes with no zero and at least 10 of 12.

| Criterion | 2 means |
|---|---|
| Readability | A newcomer can say what happens, who does it and what comes out, from the page alone |
| Completeness | Every required field and section is filled with substance |
| Source accuracy | An independent re-derivation from source matches |
| Link integrity | Every link and every `depicts` path resolves |
| Token budget | Under the level's budget |
| Vocabulary | Only the terms of this pack and the glossary; no phrase `pack.json` forbids |

## Vocabulary

`pack.json` holds three lists a page is read against: phrases a page never uses, each with the wording to use in its place; contested terms, which are flagged for the author to check; and platform terms a page links or explains on first use, which decision 12 requires.

The terms below may be used on a page with these meanings.

| Term | Meaning on a page |
|---|---|
| **value stream** | An end-to-end flow from a trigger to an outcome someone values, as the standard's level table defines it. It is the operational value stream of the common frameworks, not the flow that builds a solution |
| **delivery phase** | A period of a project's delivery lifecycle. *Phase* alone keeps the glossary meaning: a sub-division of a pipeline Stage |
| **agent state**, **phase timeline** | The three agent states, and a project's ordered reporting phases, as [lifecycle tailoring](/core/disciplines/lifecycle-tailoring.md) defines them |
| **decision gate** | The gate at a sub-process boundary |
| **lifecycle class** | living, point-in-time or baselined, as [the operational-artifacts standard](/core/standards/operational-artifacts.md) defines them |
| **home class** | Where a document type lives: a tracked file, a tracked template, a project instance, an issue body, an issue comment, a pull request, the event log, a git-ignored instance file or a host record |
| **staging surface** | A place outputs wait before promotion: a spoke's staging folder in hub state, or a project's generated-artifact folder |
| **chore PR** | The post-merge pull request that carries the release-corpus writes the release pull request cannot carry |
| **scaffold-less release** | A release run without stage sub-task issues, whose outputs land on the pull request or in staging |
| **release-scoped** | Said of a Task created once per release, not once per work item |

## Harness-feature taxonomy

The Harness cell of a step names the harness features the step relies on. Each feature has a **portability class**:

- `portable` — works with any agent runtime, or as plain code and files.
- `adapter` — another agent runtime can supply an equivalent through configuration or an open protocol.
- `rebuild` — specific to the current agent runtime or desktop app; it needs re-implementing, usually as orchestration code.

<!-- harness-features:begin -->
| Feature | Portability class | Description |
|---|---|---|
| `ask-the-user-prompt` | adapter | A structured question put to the operator in the middle of a run |
| `background-monitor` | adapter | A watcher that runs beside the main work and reports back |
| `browser-automation` | adapter | Driving a web browser |
| `context-files` | adapter | Instruction files the runtime loads when a run starts |
| `cowork-sandbox` | rebuild | The sandboxed runtime of the desktop app's operations workspace |
| `cross-session-messaging` | rebuild | One run sending a message to another |
| `deferred-tool-loading` | adapter | Tool definitions fetched only when a run needs them |
| `desktop-app-session-tools` | rebuild | Tools the desktop app supplies for managing its own runs |
| `explicit-skill-call` | rebuild | A skill invoked by name |
| `file-and-shell-tools` | portable | Reading, writing and searching files, and running shell commands |
| `git-and-gh-cli` | portable | git, and the repository host's command-line client |
| `hook-loading-surface` | rebuild | The place the runtime loads its tool-event hooks from |
| `mcp-connectors` | adapter | External tools reached over the Model Context Protocol |
| `memory-store-load` | adapter | A persistent note store loaded into context |
| `permission-modes-and-rules` | adapter | The runtime's permission modes, and its allow, deny and ask rules |
| `scheduled-routines` | adapter | Runs started on a schedule |
| `skill-auto-load` | rebuild | A skill loaded because its description matches the request |
| `sub-agent-spawn` | rebuild | Starting another agent with a context of its own |
| `tool-event-hooks` | rebuild | Code the runtime runs before or after a tool call |
| `web-fetch-and-search` | adapter | Fetching a web page, or searching the web |
| `worktree-isolation` | adapter | An isolated working copy for a run |
<!-- harness-features:end -->
A step that uses no harness feature writes `none` in its Harness cell. `none` is not a feature: it is not in `harness_features`, and it never stands as a row of the table above.

## Model-need taxonomy

The Model need cell of a step is written as `context/reasoning/tool use/determinism/latency`, for example `M/medium/write/templated/batch`.

| Dimension | Bands |
|---|---|
| Context read | XS under 2k tokens · S 2k to 8k · M 8k to 32k · L 32k to 128k · XL over 128k |
| Reasoning | none (a script could do it) · low (classify or extract) · medium (synthesize across sources) · high (design judgment or adversarial review) |
| Tool use | none · read · write · orchestrate (starts or coordinates other agents) |
| Determinism | scriptable (fixed input to fixed output) · templated (fixed shape, variable content) · judgment (open-ended) |
| Latency | interactive (an operator is waiting) · batch (runs unattended) |

Bands are estimates from source size and step shape, not measurements.

A step the operator performs writes `human` in its Model need cell. It counts in neither count of the Step profile section, and the page may add an "Operator steps" row there. This rule is checked by review: no code detects a violation.

## What reads the pack

<!-- design-artifact: flow-class=data-flow; name=data-flow-definitions-pack-readers; depicts=core/process-catalog/definitions/pack.json,core/process-catalog/definitions/controls-register.tsv -->

| Reader | Reads | To do what |
|---|---|---|
| The validator | `pack.json`; this document's marked tables; the controls register, through the name `pack.json` gives | Check each page's frontmatter, sections, tables, flow, links and vocabulary; check that this document's marked tables and the lists in `pack.json` agree; check the registers against their own rules |
| The generator | `pack.json`; the controls register, through the same name | Build the index, the graph and the views from the pages |
| A page author | This document; the template for the page's level, in `core/process-catalog/definitions/templates/` | Write a page the validator passes |

## Rules and their owners

A rule code is added or retired in the rules table and in `rule_codes` in one commit, and a harness feature in the feature table and in `harness_features` in one commit.

Each row below is one rule the catalog's validator checks, with the document that states it. The validator's `--list-rules` prints each code with the condition it tests; this table names the rule and its owner and restates neither.

<!-- rule-codes:begin -->
| Code | Rule | Owner |
|---|---|---|
| `ANC001` | a line citation carries a source anchor | the standard, § 13.4 (Evergreen references) |
| `ANC002` | a source anchor is well formed and follows its link | the standard, § 13.4 (Evergreen references) |
| `ANC003` | an anchor and its link's fragment name the same lines | the standard, § 13.4 (Evergreen references) |
| `ANC004` | a source link's label carries no line number | the standard, § 13.4 (Evergreen references) |
| `ANC005` | no line reference outside a citation | the standard, § 13.4 (Evergreen references) |
| `CTL001` | a Controls row names its control ID | the standard, § 13.7; decision 12 |
| `CTL002` | a Controls row's class equals the register's | the standard, § 13.7; decision 12 |
| `CTL003` | a cited control ID is in the register | the standard, § 13.7; decision 12 |
| `CTL004` | a hand-run detector's class and surface | the standard, § 13.7; decision 12 |
| `CTL005` | a Controls row's class is a listed class | the standard, § 13.7 |
| `EVD001` | an executed row names its registered measure, or says why none is published | decision 12 |
| `EVD002` | an executed row states no figure | the standard, § 13 (Authoring rules) |
| `EVD003` | a verdict rests on evidence any reader can reproduce | [this pack](#lenses-and-evidence) |
| `EVD004` | evidence does not point at one install | [this pack](#lenses-and-evidence) |
| `EVD005` | outcome wording on an executed row is flagged | [this pack](#lenses-and-evidence) |
| `FM001` | a readable frontmatter block | the standard, § 13.3 |
| `FM002` | required fields are present | the standard, § 13.3; [this pack](#the-page-and-its-fields) for `actors`, `owner`, `lens_status` and `pack_version` |
| `FM003` | enum fields hold a listed value | the standard, § 13.3; [this pack](#the-page-and-its-fields) for `actors`, `owner`, `lens_status` and `pack_version` |
| `FM004` | fields match their pattern | the standard, § 13.3; [this pack](#the-page-and-its-fields) for `actors`, `owner`, `lens_status` and `pack_version` |
| `FM005` | lists are inline | the standard, § 13.3; ADR-224, decision 9 |
| `FM006` | no reserved field name | [this pack](#the-page-and-its-fields) |
| `FM007` | the ID equals the file name | the standard, § 13.3 |
| `FM008` | actors are of a listed kind | [this pack](#actors) |
| `FM009` | a trigger is a node or a listed trigger kind | the standard, § 13.4 |
| `FM010` | a superseded page names its successor | the standard, § 13.6 |
| `FM011` | the page states its pack version | [this pack](#the-page-and-its-fields) |
| `FM012` | an `ACTIVE` page has an assessed lens status | [this pack](#lenses-and-evidence) |
| `LNK001` | links resolve | decision 12; the standard, § 13.4 |
| `LNK002` | a source link starts at the repository root | decision 12; the standard, § 13.4 |
| `MMD001` | the page draws its flow in Mermaid | the standard, § 13.8; ADR-224, decision 2 |
| `MMD002` | the flow stays within its node limit | [this pack](#the-flow-diagram) |
| `MMD003` | the flow is a flowchart with a direction | the process-flow diagram standards |
| `MMD004` | no Mermaid keyword as a node ID | [this pack](#the-flow-diagram) |
| `NAV001` | navigation markers | [this pack](#the-page-and-its-fields) |
| `PAG001` | only pages in a universe's folder | the standard, § 13.1 |
| `PAG002` | only registered universes under the catalog | the standard, § 13.1 |
| `PAG003` | no stray file under the catalog | the standard, § 13.1 |
| `PCK001` | the pack and the validator name the same rules | [this pack](#rules-and-their-owners) |
| `PCK002` | the pack document's two marked tables match the pack's two lists | [this pack](#rules-and-their-owners) |
| `REF001` | no issue or pull-request number | the standard, § 13.4 (Evergreen references) |
| `REG001` | the page's ID is minted | the standard, § 13.3; ADR-224, decision 5 |
| `REG002` | every ID a page names is minted | the standard, § 13.3; ADR-224, decision 5 |
| `REG003` | level and universe agree with the registry | the standard, § 13.3; ADR-224, decision 5 |
| `SEC001` | required sections | [this pack](#the-page-and-its-fields) |
| `SRC001` | depicted paths exist | the standard, § 13.4 |
| `SRC002` | the verification commit exists | the standard, § 13.3 |
| `SRC003` | a file named on a page exists in the repository or in the page's sources | [this pack](#the-page-and-its-fields) |
| `STP001` | a step's harness feature is a listed one | [this pack](#harness-feature-taxonomy) |
| `SUM001` | summary counts are computed from the Steps table | decision 12 |
| `TAB001` | table columns | [this pack](#the-page-and-its-fields) |
| `TAB002` | well-formed rows | [this pack](#the-page-and-its-fields) |
| `TAB003` | no unescaped pipe in a code span | [this pack](#the-page-and-its-fields) |
| `TOK001` | the page is within its level's token budget | the standard, § 13.2 |
| `TRM001` | a platform term is linked or explained | decision 12 |
| `VOC001` | no forbidden phrase | [this pack](#vocabulary) |
| `VOC002` | contested terms are flagged | [this pack](#vocabulary) |
<!-- rule-codes:end -->

Four rules of this pack are checked by review, and no code detects a violation. Each is stated in the section named beside it.

| Rule | Owner |
|---|---|
| the primary actor of a decision activity is the decider | [this pack](#actors) |
| two designed sources that contradict each other are a recorded deviation | [this pack](#lenses-and-evidence) |
| a sub-process takes its status from its child pages only | [this pack](#lenses-and-evidence) |
| a step the operator performs writes `human` in its Model need cell | [this pack](#model-need-taxonomy) |
