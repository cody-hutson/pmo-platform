---
title: Design-Artifact Standard
purpose: The K1 standard governing design artifacts (produced at Stage 5 Solutioning, refreshed at Stage 13) and the generated process catalog — structure, storage, lifecycle and retirement, and the primary consumers of each.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: Stage 5 Solutioning spokes (per stage-05-solutioning.md); Stage 13 Close (design-artifact capture, the G-CL8 retire verification); the design-artifact review criterion; the process-catalog pages and their generator; the Stage 2 and Stage 5 planning reads of catalog pages
---
<!-- reference-durability: allow-link -->
# Design-Artifact Standard

**Origin:** Framework Part 1 — design-artifact discipline at Stage 5 + Stage 13.
**Tier:** K1 codified-knowledge corpus per [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md).
**Primary consumers:** Stage 5 Solutioning spokes (per [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md)); Stage 13 Close spokes (per [`pipeline/stage-13-close.md`](../../release/references/pipeline/stage-13-close.md) G-CL6).
**Secondary consumers:** Release plan template (declares Tier-A activated artifacts); pmo-qa-auditor gate-check coverage.
**Status:** Canonical
**Introduced:** Framework Part 1 (stage-execution and process discipline)
**Cross-references:** see § 9 Cross-Reference Protocol and § Related References at the foot of this file.

## § 1. Purpose + Scope

A **design artifact** is a visual or structured representation of a known process, architecture, data flow, agent/human handoff, concept model, skill flow, decision tree, or state and lifecycle within pmo-platform scope. Design artifacts anchor the current state of the platform: they support human readers in understanding what agents are doing, and they support agents in maintaining coherent mental models across handoffs and cross-skill work.

This standard is the **META framework** governing design-artifact discipline. It owns the cross-class concerns — activation, storage, retention, refresh-gate, cross-reference, ownership, agent read/write — and **delegates per-flow-class rendering** to the per-class standard that already governs that class. The composition seam:

| Concern owned by THIS standard | Concern delegated to per-class standards |
|---|---|
| When to produce an artifact (activation) | How to draw a process-flow diagram → [`process-flow-diagram-standards.md`](../standards/process-flow-diagram-standards.md) |
| When to refresh an artifact (Stage 13 G-CL6) | Mermaid syntax, color/shape grammar, swimlane idiom → `process-flow-diagram-standards.md` |
| Where to store artifacts (hybrid model) | Per-class rendering rules for architecture / concept-model classes → this standard § 6 |
| Naming convention | Per-class rendering rules for data-flow class → this standard § 6 |
| Version retention policy | (none — rendering tools chosen are text-based source-of-truth) |
| Cross-reference protocol | — |
| Ownership + agent read/write | — |
| Refresh-gate (G-CL6 in `gate-criteria-spec.md`) | — |

**Non-goal:** This standard does NOT replace [`process-flow-diagram-standards.md`](../standards/process-flow-diagram-standards.md). It composes with it. The existing standard remains the canonical authority for Mermaid syntax, swimlane notation, color/shape grammar, and the diagram-form decision rule when the flow class is process-flow.

**Audience:** Stage 5 Solutioning spoke (produces artifacts) + Stage 13 Close spoke (refreshes artifacts) + release-plan author (declares Tier-A activated artifacts).

**Two models, one standard.** §§ 2–12 govern the **artifact model**: design artifacts embedded in the document they explain, or held as dedicated files. § 13 governs the **generated process catalog**: the platform's system documentation as one page per process node, with its index, graph and views generated from page frontmatter. A catalog page is also a dedicated artifact for enumeration, with the exceptions § 13.8 states.

## § 2. Flow Types

| Flow class | Definition | Tool | Location | Naming pattern | Current-state reference |
|---|---|---|---|---|---|
| **Architecture** | Structural map of files, layers, components, or systems | ASCII tree in plain fenced code block | Embedded in parent doc by default | Section anchor in parent | [`architecture-overview.md`](../disciplines/architecture-overview.md) (fenced ASCII tree § File Architecture); `operating-model.md` is concept prose + tables (no fenced tree) — not an architecture artifact |
| **Data flow** | Producer→consumer relationships, schemas, contracts | Markdown tables; Mermaid when ≥2 actors | Embedded in parent doc | Section anchor in parent | [`per-skill-output-contracts.md`](../schemas/per-skill-output-contracts.md), [`stage-io-contracts.md`](../schemas/stage-io-contracts.md), [`tracker-schemas.md`](../schemas/tracker-schemas.md) |
| **Agent process** | Steps an agent (skill, hub, spoke) takes through a workflow | Mermaid or ASCII flow-block per [`process-flow-diagram-standards.md`](../standards/process-flow-diagram-standards.md) decision rule | Embedded in parent doc (skill SKILL.md, pipeline-stage doc) | Section anchor in parent | `release/references/pipeline/stage-07-dev-testing.md` (Loop Flow), `release/references/pipeline/stage-13-close.md` (Layer-1 dual-write emit sequence), `release/references/standards/design-exploration.md` § 7 — NOT `process-flow-diagram-standards.md` (that is the rendering standard; its blocks are labelled "Example") |
| **Human process** | Steps a human operator takes through a workflow | Same as agent process | Same | Same | `docs/release-record-keeping.md` (dedicated) |
| **Concept model** | Named structural concept and its relationships | ASCII tree + structured tables | Embedded in parent doc (explanation/ folder) | Section anchor in parent | [`five-function-spine-and-process-flows.md`](../disciplines/five-function-spine-and-process-flows.md), [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) |
| **Skill flow** | Mode-routing, internal phases, or invocation flow for a skill | Mermaid OR Mode-card tables per `process-flow-diagram-standards.md` | Co-located: `{core,operations,release}/skills/<skill>/SKILL.md` (embedded) or `{core,operations,release}/skills/<skill>/diagrams/` (dedicated, rare) | `skill-flow-<skill-name>.md` (dedicated); section anchor (embedded) | `release/skills/pmo-skill-refiner/SKILL.md`, `operations/skills/delivery-engine/SKILL.md` (navigation aids; ~14 SKILL.md carry a Mode-card table corpus-wide — enumerate via § 12.2) |
| **Decision tree** | Gate-and-branch logic for a routing decision | Mermaid (gate nodes) per `process-flow-diagram-standards.md` | Embedded in parent doc | Section anchor in parent | [`version-management-protocol.md`](../../release/references/protocols/version-management-protocol.md), [`triage-design-rereview.md`](../../release/references/standards/triage-design-rereview.md) |
| **State and lifecycle** | The states something passes through, the triggers that move it between them, and what must hold across a boundary (behaviour over time) | Mermaid `stateDiagram-v2`, or a markdown state-transition table | Embedded in parent doc; generated as a catalog view (§ 13.5) | Section anchor in parent | The catalog's generated state and lifecycle view (§ 13.5) |

For each class, the tool column names the source-of-truth format. All formats are text-based and agent-readable. Per § 6, proprietary tools (Lucid / Figma / Miro / Whimsical), binary formats (SVG), and server-side-rendered formats (PlantUML) are rejected.

**Machine-identification of each class** — how an artifact of a given flow type is *declared* (so the set is enumerable) and how its region is *conformance-checked* (table-aware for every type whose rendering can be a table) is specified in [§ 12 Artifact Identification & Detection](#-12-artifact-identification--detection). Identification is declaration-based, not rendering-based: the `Current-state reference` column above is a human navigation aid, not the query surface.

## § 3. Storage Model

**Decision:** Hybrid co-location/centralized.

- **Centralized at `core/diagrams/`** for cross-cutting / platform-anchor diagrams that are referenced from **≥3 parent docs**.
- **Embedded in parent doc** for diagrams that exist primarily to explain a specific doc's content (the dominant existing pattern — Mermaid blocks in [`process-flow-diagram-standards.md`](../standards/process-flow-diagram-standards.md), ASCII trees in [`architecture-overview.md`](../disciplines/architecture-overview.md)).
- **Co-located at `{core,operations,release}/skills/<skill>/diagrams/`** for skill-specific flow diagrams when the diagram is owned by the skill's behavior, not a cross-cutting concern.
- **In the generated process catalog at `core/process-catalog/`** for process pages, one per process node, governed by § 13. The centralization test below does not apply to a page: it lives in the catalog because it documents a process node, not because of how many documents reference it.

**Centralization-test (the only rule that triggers a dedicated diagram file in `core/diagrams/`):** A diagram is centralized only when it is referenced from ≥3 distinct parent docs. Below the threshold, embed.

**Source-of-truth format:** markdown — Mermaid blocks for the process-flow class; ASCII tree for the architecture / concept-model class; tables for the data-flow class; Mermaid `stateDiagram-v2` or a transition table for the state-lifecycle class. No SVG, no PlantUML, no binary formats.

**Decision rule summary:**

```
Is it a page of the generated process catalog (one process node)?
   └── YES → core/process-catalog/<universe-id>/<node-id>.md (§ 13)

Is the diagram referenced from ≥3 parent docs?
   ├── YES → dedicated file at core/diagrams/<flow-type>-<artifact-name>.md
   └── NO  → embed in parent doc
              ├── If skill-owned    → embed in {core,operations,release}/skills/<skill>/SKILL.md
              └── Otherwise         → embed in the governing reference/standards/pipeline doc
```

## § 4. Naming Convention

**Dedicated diagram file:** `<flow-type>-<artifact-name>.md`

- Lowercase, kebab-case throughout.
- `<flow-type>` is one of: `architecture`, `data-flow`, `agent-process`, `human-process`, `concept-model`, `skill-flow`, `decision-tree`, `state-lifecycle`.
- `<artifact-name>` is the canonical subject (e.g., `pipeline`, `knowledge-architecture`, `ppm-agent`).

**Examples:**

- `architecture-pipeline.md`
- `skill-flow-ppm-agent.md`
- `concept-model-knowledge-architecture.md`
- `decision-tree-bundle-refresh-routing.md`

**Catalog page:** `core/process-catalog/<universe-id>/<node-id>.md`. The filename is the node's ID (§ 13.3); the `<flow-type>-<artifact-name>` form does not apply.

**Embedded diagram:** Section anchor at level-2 or level-3 heading in the parent doc. Anchor name uses the same `<flow-type>-<artifact-name>` form when the section can stand alone; otherwise the parent doc's existing section conventions apply.

## § 5. Version Retention

**Policy:** Current-only + git history. A single canonical version per artifact lives at its storage location. Historical versions reside in `git log --follow <file>`. There is no parallel snapshot directory. There is no per-release version numbering. There is no `last-N retained` policy.

**Historical-view procedure:**

```bash
git log --follow <path/to/artifact.md>
git show <sha>:<path/to/artifact.md>
```

The current file is the current state. Git is the version database. This matches workspace precedent — [`RELEASE_LOG.md`](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>) is append-only with git as rollback; release plan files at [`release/releases/plans/`](../../release/releases/plans/) are single-version per release; [`release-notes-standard.md`](../../release/references/standards/release-notes-standard.md) and [`evidence-grounding-standard.md`](evidence-grounding-standard.md) ship as single canonical files with git as retention.

**Rationale:**

- The parent issue body flags version-bloat risk as an explicit operator constraint.
- Adopting a parallel snapshot directory would be the FIRST exception to the workspace's "git is canonical retention" pattern.
- Text-based source-of-truth (Mermaid, ASCII, tables) gives human-readable git diffs at no extra cost — the snapshot directory adds maintenance overhead without observable benefit.

### Retirement

Retiring an artifact or a catalog page withdraws it from the current state. The retire step depends on whether the document carries the platform-doc `status` field (`ACTIVE`, `DRAFT`, `DEPRECATED`, `SUPERSEDED`):

| What is retired | Retire step | Deleted? |
|---|---|---|
| A document that carries the `status` field: a dedicated artifact file, a catalog page, or a parent doc retired as a whole | Move `status` to `DEPRECATED`, or to `SUPERSEDED` and name the successor (a catalog page names it in `superseded_by`, § 13.4). The file stays where it is. | No |
| A document without the `status` field | Delete the file. | Yes |
| An embedded artifact whose parent doc stays | Remove the declaration marker and the declared region (§ 9). | The region only |

In every case **every inbound reference is re-pointed in the same change**, to the successor where there is one and otherwise removed, so no live document still names the retired item. Release-tracking records under `release/releases/` and ADRs are historical records and are not re-pointed. Git history keeps every retired version. A change declares a retirement as the `retire` action in its Documentation Impact, and Stage 13 verifies it under gate G-CL8.

## § 6. Tool Selection (per Flow Class)

| Flow class | Tool | Authoritative standard | Rationale |
|---|---|---|---|
| Agent process | Mermaid (≥1 gate/actor) OR ASCII flow-block (linear) | [`process-flow-diagram-standards.md`](../standards/process-flow-diagram-standards.md) | Defers to existing canonical authority. No new tool decision. |
| Human process | Same as agent process | Same | Same. |
| Skill flow | Same as agent process; OR Mode-card tables when modes are the dominant structure | Same | Same. |
| Decision tree | Mermaid (gate nodes) per `process-flow-diagram-standards.md` decision rule | Same | Same. |
| Architecture | ASCII tree in plain fenced code block | This standard (§ 6) | Matches existing [`architecture-overview.md`](../disciplines/architecture-overview.md), [`five-function-spine-and-process-flows.md`](../disciplines/five-function-spine-and-process-flows.md) convention (`operating-model.md` is concept prose + tables, not a fenced ASCII tree). |
| Concept model | ASCII tree + structured tables | This standard (§ 6) | Matches existing `explanation/` folder convention. |
| Data flow | Markdown tables; Mermaid when multi-actor | This standard (§ 6) + `process-flow-diagram-standards.md` (when multi-actor triggers process-flow rules) | Matches [`per-skill-output-contracts.md`](../schemas/per-skill-output-contracts.md) + [`stage-io-contracts.md`](../schemas/stage-io-contracts.md) precedent. |
| State and lifecycle | Mermaid `stateDiagram-v2` (named states and the transitions between them) OR a markdown state-transition table (a from-state, a trigger and a to-state column) | This standard (§ 6) | A state machine is the usual view for behaviour over time; Mermaid keeps it text, like the process-flow classes, and the table form keeps a pure-table rendering valid. |

**Rejected tools (with rationale):**

| Tool | Rejection rationale |
|---|---|
| PlantUML | Text-based but requires server-side rendering; not GitHub-native; adds tool dependency. |
| SVG | File-based; less agent-readable in source form; git-diffable but not git-readable. |
| Proprietary (Lucid / Figma / Miro / Whimsical) | Operator-flagged constraint (tool lock-in risk); agent-opaque; long-term maintenance debt. |

The locked-in process-flow decision composes with these per-class defaults for the other classes. The new standard does not re-litigate process-flow tool selection.

## § 7. Activation Criteria

Three-tier activation matrix.

### Tier-A activation (REQUIRED — Stage 5 PRODUCES a design artifact)

| Flow class | Trigger | Rendering tool |
|---|---|---|
| Process-flow (agent / human / skill / decision) | Per `process-flow-diagram-standards.md` decision rule (≥1 gate, ≥2 actors, OR cited as canonical) | Mermaid or ASCII flow-block |
| Architecture | Issue creates a new `explanation/` doc with ≥1 structural diagram, OR materially modifies an existing `explanation/` doc's structural diagram (>3 line delta) | ASCII tree |
| Data flow | Issue creates/modifies a schema, contract, or output-format file with cross-component data flow (≥2 producer/consumer entities) | Markdown tables OR Mermaid (multi-actor) |
| Concept model | Issue creates a new `core/disciplines/` doc, OR introduces a new architectural concept named in a governance file | ASCII tree + structured tables |

### Tier-B activation (CONDITIONAL — refresh-only at Stage 13, no new artifact produced)

| Trigger | Behavior |
|---|---|
| Issue modifies content reflected in an existing design artifact (e.g., adds a stage transition, changes a skill mode, alters a concept-model relationship) | Stage 13 refresh-gate (G-CL6) fires; existing artifact updated to reflect new state. No new artifact produced. |

### Tier-C exemption (NO ACTIVATION — design-artifact discipline does not fire)

| Exemption | Examples |
|---|---|
| Doc-cleanup PRs | Path correction, broken-link fix, IMPROVEMENTS-bridge cleanup |
| Mechanical fixes | typo, formatting, frontmatter backfill |
| Label-only changes | governance label addition |
| Single-file additive prose | new section in existing doc with no new structural concept |
| Test-only / eval-only | eval suite additions in `evals/` |
| Trivial-ticket size | issue is `size: S` AND single-file scope AND no governance-file edit |

### Per-stage scope

- **Stage 5 PRODUCES** Tier-A activated artifacts (or refreshes Tier-B for existing artifacts).
- **Stage 13 REFRESHES** Tier-B activated artifacts and gate-verifies that the refresh occurred (G-CL6).
- No other stages produce or refresh design artifacts. Stage 6 Engineering may EDIT diagrams as a normal part of implementing the Stage 5 spec; that's not "producing" — Stage 5 made the design decision.

### Release-plan declaration

Stage 5 spoke output declares activated artifacts in the release plan's **"Tier-A activated design artifacts"** section. The declaration carries: artifact path, flow class, trigger that fired, and whether Tier-A (new artifact) or Tier-B (refresh of existing). Stage 13 spoke reads this section to scope G-CL6 detection.

## § 8. Refresh-Gate (Stage 13 G-CL6)

**Gate criterion:** [`gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) Gate 13 row `G-CL6`. See the schema doc for the canonical row text and self-repair action.

**Detection mechanism (Stage 13 spoke implements):**

1. Read the release plan's "Tier-A activated design artifacts" section.
2. For each declared artifact, run:
   - `git log --oneline <release-branch-base>..HEAD -- <artifact-path>` to verify at least one commit on the release branch touched the artifact.
   - `git diff <release-branch-base>..HEAD -- <artifact-path>` to verify the diff is non-trivial (>3 line delta, excludes frontmatter-only changes).
3. Per-artifact PASS / FAIL recorded in the release plan's Verification Evidence section.

**Failure handling — warn-mode → enforce transition:**

| Posture | Failure behavior | Mode flag |
|---|---|---|
| **Warn-mode (initial — first 2-3 releases post-cutover)** | Log per-artifact FAIL to `.claude/hooks/design-artifact-warn-log.jsonl` per workspace warn-log convention. Milestone close proceeds. Operator reviews log for false-positives, missed activations, or template gaps. | warn |
| **Enforce-mode (post-shakedown)** | Per-artifact FAIL blocks Milestone close. Operator override per Reversibility tier: **CHEAP** (one-line `Override: <rationale>` entry in release plan deviation log). | enforce |

**Shakedown duration:** 2-3 releases per the [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) Shakedown → Enforce Transition Checklist. The flip-to-enforce is operator-driven via `.claude/hooks/.mode` or equivalent surface, after warn-log review confirms low false-positive rate.

**Override protocol (enforce state):**

```
Override: design-artifact <artifact-path> not refreshed because <reason>.
Reversibility: CHEAP. Deviation logged for Stage 13 retrospective.
```

The override goes in the release plan's deviation log section. Override is governed (auditable), not forbidden.

**Composition with QC4-05:** G-CL6 is structurally enforced at Milestone close (post-shakedown). QC4-05 (release-plan invariant re-verification) is a parallel post-deploy check focused on AV-N assertions; the two checks address different domains and do not collide.

## § 9. Cross-Reference Protocol

Every design artifact carries bidirectional links between itself and the source files it depicts, except a catalog page, whose inbound links are generated (the process-page exception below).

**Dedicated artifact file (in `core/diagrams/` or `{core,operations,release}/skills/<skill>/diagrams/`):**

- Includes a § Related References section linking to every source file the artifact depicts (governance files, skill SKILL.md, pipeline-stage docs).
- Each linked source file reciprocates with an inline link to the artifact in its § Related References section.

**Embedded artifact (section in a parent doc):**

- The parent doc IS the source-of-truth; no separate file exists.
- When the same concept is referenced from other docs, the citing doc names the parent doc's section by its heading text in the link label, over a plain link to the parent doc with no fragment (e.g., `[knowledge-architecture.md § Five-Tier Classification](../disciplines/knowledge-architecture.md)`, the section that carries that doc's embedded concept model) — the corpus citation form `reference-durability-standard.md` states, which a renumber of the parent doc cannot make wrong.
- **Declaration marker (REQUIRED — this is what distinguishes an artifact section from ordinary prose).** An embedded design artifact declares itself with a **section-level HTML-comment marker** placed on its own line immediately BELOW the artifact's section heading:

  ```
  <!-- design-artifact: flow-class=<flow-class>; name=<artifact-name>; depicts=<path>[,<path>...] -->
  ```

  - `flow-class` — exactly one of the flow-class values in § 2 (`architecture` `data-flow` `agent-process` `human-process` `concept-model` `skill-flow` `decision-tree` `state-lifecycle`).
  - `name` — the canonical kebab-case subject of the artifact (the `<artifact-name>` form from § 4).
  - `depicts` — a comma-separated list of repo-root-relative source paths the artifact depicts. It carries the dedicated-file `depicts:` field's **value** semantics (repo-root-relative source paths; every path resolves to an existing repo file) but **not** that field's bidirectional-link contract: an embedded artifact has no separate file for a depicted source to link back to, so the reciprocation rule below applies to dedicated artifact files only.
  - **Declared region** — the marker bounds the artifact: from the marker line to the next heading of the **same or higher level**. That region *is* the artifact; everything else in the parent doc is ordinary prose. This is the crisp artifact-vs-prose boundary the conformance check in § 12 inspects.
  - **Whole-file scope.** When the declared region above runs to end-of-file — that is, no heading of the same or higher level follows the marker — the region and the file are the same object, and the **whole document is the artifact**. At this scope `depicts` names the repo files whose structure, flow, or concept the document maps, at the granularity it maps them (the set's index file when the document maps a set through one; the named files otherwise), and the list **MUST NOT contain the document's own path**: where region and file coincide, that path names the artifact itself rather than anything the artifact depicts. (At section scope the region is a proper subset of the file, so the parent doc's path names an object distinct from the artifact and remains a valid `depicts` value — this is the corpus's dominant form and is unaffected by this rule.) A document whose depicted files cannot be named without listing itself is not a whole-file artifact: place the marker on the artifact-bearing section instead, where `depicts` names the parent doc.
  - **Discovery query:** `grep -rnE '<!-- design-artifact:[^>]*flow-class=(architecture|data-flow|agent-process|human-process|concept-model|skill-flow|decision-tree|state-lifecycle)\b' core operations release docs` → each hit is one embedded artifact; parse `flow-class` / `name` / `depicts` from the line. The query is **enum-anchored** (requires a real flow-class value) and field-order-tolerant (`[^>]*`), so the § 9 grammar line above and the bracketed `<flow-class>` / `<data-flow>` examples do not self-match — the `>` in `[^>]` is what excludes them.
  - The marker renders invisibly on GitHub (it is an HTML comment), so it carries the machine payload without altering the human reading surface. The rationale for choosing a section-level marker over a parent-frontmatter index or a heading-convention amendment is recorded in [ADR-089](../ADRs/ADR-089-embedded-design-artifact-declaration-marker.md).

**Doc-link maintenance:** Bidirectional links are subject to [Check 14 and the PR-time link check](../rules/doc-link-maintenance.md), which verify that each link resolves; no check asserts that a reciprocal link exists. Stale links surface during deploy-time scans and route per the standard finding triage path.

**Frontmatter `depicts:` + `flow_class:` (REQUIRED for dedicated artifact files):** Every dedicated artifact file (a file living in a dedicated-artifact home per § 3 — `core/diagrams/`, `{core,operations,release}/skills/<skill>/diagrams/`, or a catalog page under `core/process-catalog/`) carries two machine-queryable frontmatter fields:

- **`depicts:`** — a YAML list of **repo-root-relative** source-file paths the artifact depicts (the files whose structure/flow/concept the artifact maps). Block form or inline-flow form are both valid, matching the established `composes_with: [a, b, c]` corpus shape; a catalog page uses the inline form (§ 13.3).
- **`flow_class:`** — exactly one of the flow-class values in § 2: `architecture` `data-flow` `agent-process` `human-process` `concept-model` `skill-flow` `decision-tree` `state-lifecycle`. This makes the per-flow-type count a frontmatter query rather than a prose scrape.
- **Placement:** in the YAML frontmatter block, after `type:` / `status:`, consistent with the existing field-ordering convention.
- **Validation (3 rules):**
  1. Every path in `depicts:` MUST resolve to an existing repo file (reuses the dead-file-ref gate pattern; `<!-- repo-integrity: allow-dead-file-ref -->` is the negative-space precedent for a deliberately-forward target).
  2. `flow_class:` MUST be one of the flow-class values in § 2.
  3. Each depicted source's `## Related References` reciprocates with a link back to the artifact — the § 9 dedicated-file bidirectional contract. Check 14 verifies that the link resolves; no check asserts that it exists.

**Process-page exception (rule 3).** Rule 3 does not apply to a catalog page (§ 13). A page's depicted sources are not edited to link back to it: the generated graph's inbound index (§ 13.5), which lists for each source the pages that depict it, replaces that link. Most depicted sources are durable-corpus files, where a link sequence is banned, so a hand-kept reciprocal link would also be impossible there.

**Canonical dedicated-artifact query:** `grep -rl '^depicts:' core operations release docs` → the dedicated artifact set (location-independent, so it also catches skill `diagrams/` artifacts). See [§ 12 Artifact Identification & Detection](#-12-artifact-identification--detection) for the combined dedicated + embedded enumeration harness and the per-flow-type detection criteria.

## § 10. Agent Read/Write + Ownership

### Read

- Agents MAY READ any design artifact freely. No permission check is required. Design artifacts live in `core/` / `{core,operations,release}/skills/<skill>/` and are governed by the standard read-access conventions for those locations.

### Write

| Operation | Authority | Stage |
|---|---|---|
| Produce a new artifact | Stage 5 Solutioning spoke, on Tier-A activation | Stage 5 |
| Refresh an existing artifact | Stage 5 Solutioning spoke (Tier-B activation) OR Stage 13 Close spoke (per G-CL6) | Stage 5 or Stage 13 |
| Edit an artifact during Engineering | Stage 6 Engineering spoke, when implementing the Stage 5 spec | Stage 6 |
| Retire an artifact (§ 5 Retirement) | Stage 6 Engineering spoke, implementing a change whose Documentation Impact declares `retire` | Stage 6 |
| Publish, regenerate or retire a catalog page | Under § 13, not § 7 activation | — |
| Create artifact outside Stage 5 Tier-A activation (catalog pages excepted, § 13.8) | NOT PERMITTED — out-of-stage creation is a Tier 2 [SCOPE CHANGE] per [`release-process.md` § Inter-Stage Feedback Protocol](../../release/governance/release-process.md) | — |

### Ownership

| Flow class | Authoring persona | Refreshing persona | Source skill |
|---|---|---|---|
| Architecture | Principal Engineer (Skills-Map.md §9 Mode 1 Architect) | Release Manager (Skills-Map.md §13 Mode 4) | Stage 5 / Stage 13 release-spoke |
| Data flow | Principal Engineer (§9 Mode 1) | Release Manager (§13) | Same |
| Agent process | Principal Engineer (§9 Mode 1) or Solutioning persona owning the skill | Release Manager (§13) | Same |
| Human process | Principal Engineer (§9 Mode 1) | Release Manager (§13) | Same |
| Concept model | Principal Engineer (§9 Mode 1) | Release Manager (§13) | Same |
| Skill flow | Skill author (or pmo-skill-editor when modifying existing) | Release Manager (§13) | pmo-skill-editor / pmo-skill-refiner |
| Decision tree | Principal Engineer (§9 Mode 1) | Release Manager (§13) | Stage 5 / Stage 13 release-spoke |
| State and lifecycle | Principal Engineer (§9 Mode 1) | Release Manager (§13) | Stage 5 / Stage 13 release-spoke |

Persona-card behavioral-marker additions to [`release-personas.md`](../../release/references/specs/release-personas.md) Stage 5 and Stage 13 entries are deferred to the Backfill release (Part 2). The Framework Part 1 ownership table above is authoritative until persona cards are updated.

## § 11. Cutover + Version History

### Cutover

**Applies to all Stage 5 work going forward.** The discipline applies prospectively to all releases after this standard takes effect.

**G-CL6 cutover (identical semantics):** the refresh-gate applies to all Stage 13 closes going forward.

This cutover discipline matches workspace precedent.

### Version History

| Version | Date | Change | Issue |
|---|---|---|---|

Revisions are tracked in git history. Per § 5, git history is the canonical retention — this table is a navigation aid, not a parallel snapshot.

## § 12. Artifact Identification & Detection

Design-artifact identification is **declaration-based, not rendering-based.** A survey of the § 2-cited current-state files (2026-07-24) established the reason: three of the seven flow types (data-flow, concept-model, skill-flow) render as **markdown tables**, and four cited artifact-bearing files (`operating-model.md`, `stage-io-contracts.md`, `five-function-spine-and-process-flows.md`, `delivery-engine/SKILL.md`) carry **zero fenced code blocks and zero Mermaid**. Any fence-count or Mermaid-count mechanism is structurally blind to them. So the artifact set is discovered from explicit **declarations** — `depicts:` frontmatter for dedicated files (§ 9), the `<!-- design-artifact: … -->` marker for embedded artifacts (§ 9) — and the rendering-tool rule is demoted to a **region-scoped conformance check** applied only after discovery.

### § 12.1 Per-flow-type detection criteria (every flow type)

Discovery is declaration-based (immune to table-invisibility). The rule below is the **classification + conformance** layer, applied to the **declared region** only — the dedicated file's body, or an embedded artifact's marker-bounded region (§ 9). The `Table-aware?` column marks the types whose conformance rule inspects the region's **table shape**, explicitly NOT a global fence tally.

| # | Flow type | Rendering-tool conformance rule (names the tool it tests for) | Table-aware? |
|---|---|---|---|
| 1 | **architecture** | declared region contains a fenced code block whose body carries tree glyphs `├ └ │` | fence-based |
| 2 | **data-flow** | declared region contains ≥1 markdown table with producer→consumer / schema / contract columns; Mermaid only when ≥2 actors | **YES** — region table-shape inspection, never a fence count |
| 3 | **agent-process** | declared region contains a ` ```mermaid ` fence OR a fenced ASCII flow-block (arrows `→` / `▼`) | fence/Mermaid |
| 4 | **human-process** | same rule as agent-process | fence/Mermaid |
| 5 | **concept-model** | declared region contains a fenced ASCII tree AND/OR ≥1 structured relationship table naming the concept | **YES** — region tree + table |
| 6 | **skill-flow** | declared region contains a ` ```mermaid ` fence OR Mode-card tables (a table whose header names modes/phases) | **YES** — region Mode-card table |
| 7 | **decision-tree** | declared region contains a ` ```mermaid ` fence with gate/branch nodes OR a fenced ASCII decision-block OR ≥1 markdown table carrying the **decision-table signature**: a *discriminator* column (the case / condition / class being tested) paired with a *branch* column stating the routed outcome (routing · action · disposition · verdict · authority · behavior), whose rows enumerate a **closed, mutually-exclusive branch set**. An instance **register** — rows keyed by an `ID` / `#` / `Risk` / `Finding` / `File` column, i.e. records rather than branches — is **NOT** a decision table even when it carries a Resolution / Mitigation / Disposition column | **YES** — region table-shape inspection (discriminator→branch signature); Mermaid/fence limbs retained |
| 8 | **state-lifecycle** | declared region contains a ` ```mermaid ` fence whose diagram is `stateDiagram-v2` (or `stateDiagram`) OR ≥1 markdown table carrying the **transition signature**: a *from-state* column, a *trigger* (event or condition) column and a *to-state* column, whose rows are transitions between named states | **YES** — region table-shape inspection (transition signature); Mermaid limb retained |

**Why this is table-aware and the fence-count under-measurement is cured:** rows 2, 5, 6, 7 and 8 never rely on a fence/Mermaid tally — they inspect the *declared region* for the type's own table signature. Row 7 retains its Mermaid and fenced-ASCII limbs alongside the table limb, so a decision tree rendered either way conforms, and a decision tree rendered *only* as a table is no longer missed. Because **discovery** is by declaration, the type is known before the conformance rule runs, so a pure-table artifact (0 fences) is still found and still classified.

### § 12.2 Enumeration harness (runnable, deterministic)

```bash
# Dedicated artifacts (depicts: frontmatter — § 9)
grep -rl '^depicts:' core operations release docs

# Embedded artifacts (section-level marker — § 9; enum-anchored + field-order-tolerant so the
# § 9 grammar line and the bracketed <flow-class> examples do not self-match — the `>` in [^>] excludes them)
grep -rnE '<!-- design-artifact:[^>]*flow-class=(architecture|data-flow|agent-process|human-process|concept-model|skill-flow|decision-tree|state-lifecycle)\b' core operations release docs

# Per-flow-type count (dedicated + embedded, one row per type)
for t in architecture data-flow agent-process human-process concept-model skill-flow decision-tree state-lifecycle; do
  d=$(grep -rlE "^flow_class:[[:space:]]+$t\b" core operations release docs --include='*.md' | wc -l)
  e=$(grep -rn "design-artifact:[^>]*flow-class=$t\b" core operations release docs --include='*.md' | wc -l)
  printf "%-16s dedicated=%s embedded=%s total=%s\n" "$t" "$d" "$e" "$((d+e))"
done

# Enum-validation lint — surface any marker whose flow-class is NOT one of the § 2 values (the per-type
# loop above drops an out-of-enum / typo'd flow-class silently; this catches it)
grep -rnoE '<!-- design-artifact:[^>]*flow-class=[a-z-]+' core operations release docs --include='*.md' \
 | grep -vE 'flow-class=(architecture|data-flow|agent-process|human-process|concept-model|skill-flow|decision-tree|state-lifecycle)\b' \
 && echo "WARN: out-of-enum flow-class marker(s) above" || echo "enum OK"
```

The three queries are deterministic (RUN 1 == RUN 2 over an unchanged tree). This harness is the enumeration method the six flow-type backfill children cite for their completion condition, and the source of the per-flow-type gap count for the confirm-or-collapse (fission) decision.

### § 12.3 Applying the criteria — worked verdicts

The marker mechanism gives an **unambiguous** artifact-vs-prose verdict even for pure-table files that a fence count cannot see:

| Parent doc | Section | Marker present? | Verdict |
|---|---|---|---|
| `core/disciplines/architecture-overview.md` | an embedded ASCII structure tree | marker under the heading | **ARTIFACT** (unambiguous — marker present) |
| `core/disciplines/architecture-overview.md` | an ordinary prose+table governance-tier section | no marker | **PROSE** (unambiguous — no marker) |
| `core/schemas/stage-io-contracts.md` | the boundary producer→consumer contract tables | marker under the heading | **ARTIFACT** (even though the file has 0 fences / 0 Mermaid / 100 table rows) |
| `release/references/standards/triage-design-rereview.md` | `§ 3 Classifications` — the C1/C2/C3 routing table at `\| Cls \| Name \| Definition \| Routing \|` | marker under the heading | **ARTIFACT**, `decision-tree` — the region carries **0 Mermaid fences and 0 fenced ASCII decision-blocks**, and conforms on rule 7's decision-table limb: `Cls` is the discriminator, `Routing` is the branch, and C1/C2/C3 is a closed mutually-exclusive branch set |

The third row is the decisive one for **discovery**: under a fence-count mechanism `stage-io-contracts.md` is invisible; under the marker mechanism it is unambiguously an artifact. That is the whole point of declaration-based identification.

The fourth row is the decisive one for **rule-7 conformance**, and it is the reason it is recorded here rather than left implicit. Before rule 7 carried its table limb, this exact region was the standing counter-example — genuine decision logic that the rule could not classify, recorded as a known rule-gap rather than forced to pass. Naming the conforming instance is what keeps the limb falsifiable: a reader who doubts that rule 7 is table-aware can settle it by reading one named region, instead of re-deriving "not table-aware" from the rule text and logging the gap a second time.

## § 13. The Generated Process Catalog

The process catalog is the platform's system documentation: one page per process node, written as text, with every index, graph and cross-cutting view generated from the pages, per {{ADR:system-documentation-is-a-generated-process-catalog}}. It sits beside the artifact model of §§ 2–12 and does not replace it: an embedded or dedicated artifact still explains the document it belongs to, while a catalog page orients a reader in a process and links to the sources that govern it.

### § 13.1 Where the catalog lives

- **Folder:** `core/process-catalog/`. It is under `core/` and outside the durable-corpus paths, so pages may carry Markdown links; it is inside the depersonalization gate's scope, so every page is scanned for personal data.
- **Layout:**

| Path | What it holds | Written or generated |
|---|---|---|
| `core/process-catalog/README.md` | Orientation for the folder. It never lists pages. | Written |
| `core/process-catalog/<universe-id>/<node-id>.md` | One page per L0–L3 node of that universe; the L0 page is `<universe-id>/<universe-id>.md` | Written, or seeded and corrected (§ 13.2) |
| `core/process-catalog/INDEX.md` | The entry point: L0 and L1 nodes with their paths | Generated |
| `core/process-catalog/graph.json` | Every node and link, including the inbound index (§ 13.5) | Generated |
| `core/process-catalog/views/` | The cross-cutting views (§ 13.5) | Generated |

- **No folder name carries a state.** A `DRAFT` page sits beside the `ACTIVE` pages of its universe and its `status` says what it is. No path segment may be one the draft-file guard blocks (`proposals`, `drafts`, `draft`, `scratch`, `sandbox`, `wip`).
- **Link-check scope.** The folder is an entry in the shared scope list `core/deploy/allowlists/doc-link-target-paths.txt`, which deploy-time Check 14 and the PR-time link check both read with `--require-targets`. A directory entry must resolve to at least one Markdown file, so `README.md` is the folder's first tracked file and is never removed while the entry stands.

### § 13.2 Levels, and what earns a node a page

A node earns a page only by passing its level's decision test. A page orients and links; it never restates a SKILL.md, spec or standard.

| Level | Name | A node is at this level when… | Page | Token budget | Written how |
|---|---|---|---|---|---|
| L0 | universe | it could be adopted, replaced or retired as a whole, and has its own owners and lifecycle | yes | 2,000 | written |
| L1 | value stream | it starts on a trigger from outside the platform's own flow and ends in an outcome someone values | yes | 2,000 | written |
| L2 | sub-process | it is bounded by a gate or a handoff at both ends | yes | 2,500 | written |
| L3 | activity | one primary actor carries it out for one purpose | yes | 3,000 | seeded from source where the source class allows, then corrected by hand |
| L4 | step | one verb and one object: one tool call, one decision or one write | no — a row in its activity page's Steps table | — | generated, then reviewed |
| L5 | detail | a schema, field, template, flag or source line | no — linked from its step, never restated | — | — |

A node that passes two tests takes the higher, less detailed level, and a sub-process with a single activity collapses into that activity. `INDEX.md` stays under 4,000 tokens. Token counts use the context-budget auditor's estimate. Mapped onto the glossary's nest, each pipeline Stage is a sub-process, each Phase of a stage (or mode of a skill) is an activity, and each numbered step is a step.

### § 13.3 Page identity and frontmatter

- **Identity.** Each node has a stable kebab-case ID, minted centrally and never positional, and its page's filename is that ID. A step is addressed as `<activity-id>#<step-slug>`. A renamed node gets a new ID and supersedes the old page (§ 13.6); an ID is never reused.
- **Flat frontmatter, inline lists.** One `key: value` per line, and every list inline as `[a, b]`: the platform's shared frontmatter reader returns a block-form list as empty.
- **Fields every page carries:**

| Field | Meaning |
|---|---|
| `title`, `purpose`, `type`, `status`, `reversibility` | The platform-doc frontmatter fields. `type` is `reference`; `status` is the page lifecycle (§ 13.6). |
| `id` | The node's ID, equal to the filename stem |
| `level` | `L0`, `L1`, `L2` or `L3` |
| `universe` | The L0 node the page belongs to (an L0 page names itself) |
| `flow_class` | The flow class of the page's flow diagram (§ 2): `concept-model` at L0; at L1–L3, `agent-process`, `human-process`, `skill-flow` or `decision-tree` |
| `depicts` | The repository files the page summarizes (§ 13.4) |
| `last_verified_commit` | The commit the page was last checked against. A page is **stale** when a file in its `depicts` list changed after this commit. Staleness is derived by the drift check and never stored. |

Each page also carries the link fields of § 13.4 that apply to it. Page templates may add fields; they never redefine the fields above.

**Authoring rules.** The rules the catalog's validator enforces on page content are recorded in decision 12 of {{ADR:system-documentation-is-a-generated-process-catalog}} and are not restated here: an executed number cites a saved query, a Controls row takes its class from the register, a summary count is computed from the page's own Steps table, a source link starts at the repository root, and a platform term is linked or explained on first use.

### § 13.4 Link types

Every link is carried in a catalog page's frontmatter. No file outside the catalog is edited to carry one.

| Link type | From → to | Carried in | Notes |
|---|---|---|---|
| `sub-flow-of` | a page → its parent node, one level up | `parent:` — one ID, on L1–L3 pages | A node's children are derived from it and never stored |
| `precedes` | a node → the sibling nodes that come next under the same parent | `precedes:` — IDs | Optional |
| `triggered-by` | a node → what starts it: a node ID, or `event:<name>`, `schedule:<cadence>` or `external:<system-role>` | `triggered_by:` | Optional. An external system is named by its role, never by product or tenant |
| `depends-on` | a node → a node outside its own sequence whose output it needs | `depends_on:` — IDs | Optional; for a dependency that `precedes` cannot express |
| `depicts` | a page → the repository files it summarizes | `depicts:` — repository-root-relative paths, at least one | The § 9 value rule applies: every path resolves to a tracked file |
| `documents` | a document outside the catalog → the node it explains to its reader, such as a user guide under `docs/` | `documented_by:` — paths, on the node's page | Recorded on the page, so the document itself is not edited |
| `supersedes` | a page → the page it replaces | `supersedes:` and `superseded_by:` — IDs, each the inverse of the other | Both pages carry their half when a page is superseded (§ 13.6) |

Edges the generator derives from page content, such as what a step reads or writes, which control enforces it and who performs it, are part of the generator's design and are not authored link types.

### § 13.5 Generated surfaces

- The index (`INDEX.md`), the graph (`graph.json`) and the cross-cutting views under `views/` (structure, data flow, state and lifecycle, controls, interfaces and jobs) are **generated from page frontmatter and the element inventory, and never hand-maintained**. A hand edit to a generated file is a defect, not a fix.
- The graph carries the **inbound index**: for each repository file, the pages whose `depicts` names it, and for each document, the nodes whose `documented_by` names it. A reader of a source finds the pages about it there (the process-page exception in § 9).
- **Generated output is committed**, so GitHub renders it and any agent reads it with plain file reads, and a CI step regenerates it and diffs to catch drift. No generated file is committed without the generator that produces it.
- The control layer (hooks, permission rules, CI gates) is a generated view and a column on every page, not a value stream.

### § 13.6 Lifecycle and retirement

- **Lifecycle.** The page lifecycle is the platform-doc `status` field: `DRAFT` for a page not yet through its pass gate or a proposed target flow, `ACTIVE` for a page that describes the system as of its `last_verified_commit`, `SUPERSEDED` for a page replaced by the page named in its `superseded_by`, and `DEPRECATED` for a retired page. No new state names are introduced, so none of the names `lifecycle-states-canonical.md` reserves is used.
- **Retirement.** A page retires by the § 5 retire step: a status move to `SUPERSEDED` or `DEPRECATED`, with every inbound reference re-pointed in the same change, and nothing deleted or moved. A `SUPERSEDED` page stays in place, names its successor and is marked as superseded in the generated index; a `DEPRECATED` page stays in place and the generated index omits it.

### § 13.7 Controls and enforcement classes

A page's Controls rows record the rules its node follows. A row names its control ID where the catalog's controls register has one, and its enforcement class must equal the register's. The **enforcement class** records a control's effective behaviour on a default install:

| Class | The control… |
|---|---|
| `code-enforce` | is a hook, CI check or tool that blocks the action or fails the run |
| `code-warn` | is code that detects and reports a violation without blocking (warn mode, an advisory check) |
| `code-off` | is code that exists but is inert by default: its mode is off, or it sits below a master activation that ships off |
| `prose-only` | is stated in a governed document, and nothing detects a violation |
| `tacit` | lives only in operator memory, corrections or habit, not in the corpus |
| `host-config` | is enforced by repository-host settings, such as branch protection or rulesets, where an operator configured them |

The **enforcement surface** says where a control acts: `hook`, `deploy-run`, `ci-run`, `merge-gate`, `host` or `agent-run`. A detector an agent runs by hand is `code-warn` on `agent-run`. The enforcement class describes a control as a page records it; it is distinct from the `posture` and `enforcement` annotations that the gate-efficacy standard reads from workflows, which record how a gate is wired.

### § 13.8 How the catalog composes with §§ 2–12

- **Enumeration.** A catalog page is a dedicated artifact for enumeration: it carries `flow_class` and `depicts`, so the § 12.2 harness finds it, and § 9 validation rules 1 and 2 apply to it. Rule 3 does not (the process-page exception in § 9).
- **Production.** § 7 activation and the § 10 creation rule do not govern pages. Pages are published and regenerated under this section, not produced by a Stage 5 Tier-A activation, and § 8's refresh gate does not read them: a page's freshness is its `last_verified_commit`, checked by the drift check.
- **Rendering.** Mermaid syntax, shapes and colours on a page's flow follow `process-flow-diagram-standards.md`, as for every process-flow artifact. § 6 tool selection and § 12.1 conformance do not govern a page's flow; decision 2 of {{ADR:system-documentation-is-a-generated-process-catalog}} does — the flow is a Mermaid block, whatever the page's `flow_class`, so an L0 page declared `concept-model` still draws its flow in Mermaid.

## Related References

- [`process-flow-diagram-standards.md`](../standards/process-flow-diagram-standards.md) — canonical authority for the process-flow class (Mermaid syntax, swimlane idiom, color/shape grammar). Composed per § 6 Tool Selection.
- [`gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) — canonical schema for Gate 13 G-CL6 row + self-repair action.
- [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) — Stage 5 PRODUCES surface (Phase A6).
- [`pipeline/stage-13-close.md`](../../release/references/pipeline/stage-13-close.md) — Stage 13 REFRESH-GATE surface (Phase A5 G-CL6).
- [`release-notes-standard.md`](../../release/references/standards/release-notes-standard.md) — sibling location-convention precedent (`core/standards/` for new "-standard.md" docs).
- [`evidence-grounding-standard.md`](evidence-grounding-standard.md) — sibling location-convention precedent.
- [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) — workspace-canonical warn-mode → enforce shakedown precedent (Checks 8/9/10/14/15).
- [`doc-link-maintenance.md`](../rules/doc-link-maintenance.md) — link-resolution enforcement (Check 14 and the PR-time link check).
- The documentation-model decision record, {{ADR:system-documentation-is-a-generated-process-catalog}} — the decision § 13 implements.
- [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) — K1 tier classification (this standard is K1).
- Scope: Framework Part 1 + deferred Backfill Part 2.
- Composed-with origin: `process-flow-diagram-standards.md` introduction.
