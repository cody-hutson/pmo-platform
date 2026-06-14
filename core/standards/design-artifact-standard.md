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

A **design artifact** is a visual or structured representation of a known process, architecture, data flow, agent/human handoff, concept model, skill flow, or decision tree within pmo-platform scope. Design artifacts anchor the current state of the platform: they support human readers in understanding what agents are doing, and they support agents in maintaining coherent mental models across handoffs and cross-skill work.

This standard is the **META framework** governing design-artifact discipline. It owns the cross-class concerns — activation, storage, retention, refresh-gate, cross-reference, ownership, agent read/write — and **delegates per-flow-class rendering** to the per-class standard that already governs that class. The composition seam:

| Concern owned by THIS standard | Concern delegated to per-class standards |
|---|---|
| When to produce an artifact (activation) | How to draw a process-flow diagram → [`process-flow-diagram-standards.md`](../specs/process-flow-diagram-standards.md) |
| When to refresh an artifact (Stage 13 G-CL6) | Mermaid syntax, color/shape grammar, swimlane idiom → `process-flow-diagram-standards.md` |
| Where to store artifacts (hybrid model) | Per-class rendering rules for architecture / concept-model classes → this standard § 6 |
| Naming convention | Per-class rendering rules for data-flow class → this standard § 6 |
| Version retention policy | (none — rendering tools chosen are text-based source-of-truth) |
| Cross-reference protocol | — |
| Ownership + agent read/write | — |
| Refresh-gate (G-CL6 in `gate-criteria-spec.md`) | — |

**Non-goal:** This standard does NOT replace [`process-flow-diagram-standards.md`](../specs/process-flow-diagram-standards.md). It composes with it. The existing standard remains the canonical authority for Mermaid syntax, swimlane notation, color/shape grammar, and the diagram-form decision rule when the flow class is process-flow.

**Audience:** Stage 5 Solutioning spoke (produces artifacts) + Stage 13 Close spoke (refreshes artifacts) + release-plan author (declares Tier-A activated artifacts).

## § 2. The 7 Flow Types

| Flow class | Definition | Tool | Location | Naming pattern | Current-state reference |
|---|---|---|---|---|---|
| **Architecture** | Structural map of files, layers, components, or systems | ASCII tree in plain fenced code block | Embedded in parent doc by default | Section anchor in parent | [`architecture-overview.md`](../disciplines/architecture-overview.md), [`operating-model.md`](../disciplines/operating-model.md) |
| **Data flow** | Producer→consumer relationships, schemas, contracts | Markdown tables; Mermaid when ≥2 actors | Embedded in parent doc | Section anchor in parent | [`per-skill-output-contracts.md`](../schemas/per-skill-output-contracts.md), [`stage-io-contracts.md`](../schemas/stage-io-contracts.md), [`tracker-schemas.md`](../schemas/tracker-schemas.md) |
| **Agent process** | Steps an agent (skill, hub, spoke) takes through a workflow | Mermaid or ASCII flow-block per [`process-flow-diagram-standards.md`](../specs/process-flow-diagram-standards.md) decision rule | Embedded in parent doc (skill SKILL.md, pipeline-stage doc) | Section anchor in parent | `process-flow-diagram-standards.md` examples |
| **Human process** | Steps a human operator takes through a workflow | Same as agent process | Same | Same | Same |
| **Concept model** | Named structural concept and its relationships | ASCII tree + structured tables | Embedded in parent doc (explanation/ folder) | Section anchor in parent | [`five-function-spine-and-process-flows.md`](../disciplines/five-function-spine-and-process-flows.md), [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) |
| **Skill flow** | Mode-routing, internal phases, or invocation flow for a skill | Mermaid OR Mode-card tables per `process-flow-diagram-standards.md` | Co-located: `{core,operations,release}/skills/<skill>/SKILL.md` (embedded) or `{core,operations,release}/skills/<skill>/diagrams/` (dedicated, rare) | `skill-flow-<skill-name>.md` (dedicated); section anchor (embedded) | `pmo-skill-refiner/SKILL.md`, `delivery-engine/SKILL.md` |
| **Decision tree** | Gate-and-branch logic for a routing decision | Mermaid (gate nodes) per `process-flow-diagram-standards.md` | Embedded in parent doc | Section anchor in parent | [`version-management-protocol.md`](../../release/references/protocols/version-management-protocol.md), [`triage-design-rereview.md`](../../release/references/standards/triage-design-rereview.md) |

For each class, the tool column names the source-of-truth format. All formats are text-based and agent-readable. Per § 6, proprietary tools (Lucid / Figma / Miro / Whimsical), binary formats (SVG), and server-side-rendered formats (PlantUML) are rejected.

## § 3. Storage Model

**Decision:** Hybrid co-location/centralized.

- **Centralized at `core/diagrams/`** for cross-cutting / platform-anchor diagrams that are referenced from **≥3 parent docs**.
- **Embedded in parent doc** for diagrams that exist primarily to explain a specific doc's content (the dominant existing pattern — Mermaid blocks in [`process-flow-diagram-standards.md`](../specs/process-flow-diagram-standards.md), ASCII trees in [`architecture-overview.md`](../disciplines/architecture-overview.md)).
- **Co-located at `{core,operations,release}/skills/<skill>/diagrams/`** for skill-specific flow diagrams when the diagram is owned by the skill's behavior, not a cross-cutting concern.

**Centralization-test (the only rule that triggers a dedicated diagram file in `core/diagrams/`):** A diagram is centralized only when it is referenced from ≥3 distinct parent docs. Below the threshold, embed.

**Source-of-truth format:** markdown — Mermaid blocks for the process-flow class; ASCII tree for the architecture / concept-model class; tables for the data-flow class. No SVG, no PlantUML, no binary formats.

**Decision rule summary:**

```
Is the diagram referenced from ≥3 parent docs?
   ├── YES → dedicated file at core/diagrams/<flow-type>-<artifact-name>.md
   └── NO  → embed in parent doc
              ├── If skill-owned    → embed in {core,operations,release}/skills/<skill>/SKILL.md
              └── Otherwise         → embed in the governing reference/standards/pipeline doc
```

## § 4. Naming Convention

**Dedicated diagram file:** `<flow-type>-<artifact-name>.md`

- Lowercase, kebab-case throughout.
- `<flow-type>` is one of: `architecture`, `data-flow`, `agent-process`, `human-process`, `concept-model`, `skill-flow`, `decision-tree`.
- `<artifact-name>` is the canonical subject (e.g., `pipeline`, `knowledge-architecture`, `ppm-agent`).

**Examples:**

- `architecture-pipeline.md`
- `skill-flow-ppm-agent.md`
- `concept-model-knowledge-architecture.md`
- `decision-tree-bundle-refresh-routing.md`

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

## § 6. Tool Selection (per Flow Class)

| Flow class | Tool | Authoritative standard | Rationale |
|---|---|---|---|
| Agent process | Mermaid (≥1 gate/actor) OR ASCII flow-block (linear) | [`process-flow-diagram-standards.md`](../specs/process-flow-diagram-standards.md) | Defers to existing canonical authority. No new tool decision. |
| Human process | Same as agent process | Same | Same. |
| Skill flow | Same as agent process; OR Mode-card tables when modes are the dominant structure | Same | Same. |
| Decision tree | Mermaid (gate nodes) per `process-flow-diagram-standards.md` decision rule | Same | Same. |
| Architecture | ASCII tree in plain fenced code block | This standard (§ 6) | Matches existing [`architecture-overview.md`](../disciplines/architecture-overview.md), [`operating-model.md`](../disciplines/operating-model.md), [`five-function-spine-and-process-flows.md`](../disciplines/five-function-spine-and-process-flows.md) convention. |
| Concept model | ASCII tree + structured tables | This standard (§ 6) | Matches existing `explanation/` folder convention. |
| Data flow | Markdown tables; Mermaid when multi-actor | This standard (§ 6) + `process-flow-diagram-standards.md` (when multi-actor triggers process-flow rules) | Matches [`per-skill-output-contracts.md`](../schemas/per-skill-output-contracts.md) + [`stage-io-contracts.md`](../schemas/stage-io-contracts.md) precedent. |

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

Every design artifact carries bidirectional links between itself and the source files it depicts.

**Dedicated artifact file (in `core/diagrams/` or `{core,operations,release}/skills/<skill>/diagrams/`):**

- Includes a § Related References section linking to every source file the artifact depicts (governance files, skill SKILL.md, pipeline-stage docs).
- Each linked source file reciprocates with an inline link to the artifact in its § Related References section.

**Embedded artifact (section in a parent doc):**

- The parent doc IS the source-of-truth; no separate file exists.
- When the same concept is referenced from other docs, the citing doc links to the parent doc's section anchor (e.g., `[knowledge-architecture.md § Tier Map](../disciplines/knowledge-architecture.md#tier-map)`).

**Doc-link maintenance:** Bidirectional links are subject to [Check 14 / Check 15](../rules/doc-link-maintenance.md) protocols (the workspace's automated link-resolver and warn-log surface). Stale links surface during deploy-time scans and route per the standard finding triage path.

**Frontmatter (forward-compatible, not required yet):** A future-state extension may add a frontmatter field `depicts:` that names the source files an artifact depicts (machine-queryable cross-reference). Deferred to Backfill release scope; not required for Framework Part 1.

## § 10. Agent Read/Write + Ownership

### Read

- Agents MAY READ any design artifact freely. No permission check is required. Design artifacts live in `core/` / `{core,operations,release}/skills/<skill>/` and are governed by the standard read-access conventions for those locations.

### Write

| Operation | Authority | Stage |
|---|---|---|
| Produce a new artifact | Stage 5 Solutioning spoke, on Tier-A activation | Stage 5 |
| Refresh an existing artifact | Stage 5 Solutioning spoke (Tier-B activation) OR Stage 13 Close spoke (per G-CL6) | Stage 5 or Stage 13 |
| Edit an artifact during Engineering | Stage 6 Engineering spoke, when implementing the Stage 5 spec | Stage 6 |
| Create artifact outside Stage 5 Tier-A activation | NOT PERMITTED — out-of-stage creation is a Tier 2 [SCOPE CHANGE] per [`release-process.md` § Inter-Stage Feedback Protocol](../../release/governance/release-process.md) | — |

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

## Related References

- [`process-flow-diagram-standards.md`](../specs/process-flow-diagram-standards.md) — canonical authority for the process-flow class (Mermaid syntax, swimlane idiom, color/shape grammar). Composed per § 6 Tool Selection.
- [`gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) — canonical schema for Gate 13 G-CL6 row + self-repair action.
- [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) — Stage 5 PRODUCES surface (Phase A6).
- [`pipeline/stage-13-close.md`](../../release/references/pipeline/stage-13-close.md) — Stage 13 REFRESH-GATE surface (Phase A5 G-CL6).
- [`release-notes-standard.md`](../../release/references/standards/release-notes-standard.md) — sibling location-convention precedent (`core/standards/` for new "-standard.md" docs).
- [`evidence-grounding-standard.md`](evidence-grounding-standard.md) — sibling location-convention precedent.
- [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) — workspace-canonical warn-mode → enforce shakedown precedent (Checks 8/9/10/14/15).
- [`doc-link-maintenance.md`](../rules/doc-link-maintenance.md) — bidirectional cross-reference enforcement (Check 14 / Check 15).
- [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) — K1 tier classification (this standard is K1).
- Scope: Framework Part 1 + deferred Backfill Part 2.
- Composed-with origin: `process-flow-diagram-standards.md` introduction.
