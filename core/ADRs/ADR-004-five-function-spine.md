---
title: ADR-004 — Five-Function Spine and Cross-Cutting Process Flows
status: Accepted
date: 2026-05-10
deciders: "operator + Stage 5 Solutioning spoke"
tags: [architecture, governance, methodology, pmbok, role-skills]
source_observations:
  - Stage 4 release plan (D-519-Scope = A, D-182-vs-519-Boundary = A)
  - Stage 5 spec (Spec Surfaces 1, 2, 3, 6)
  - Collective Review record (CONFLICT-1 ADR numbering = three sequential)
---

# ADR-004 — Five-Function Spine and Cross-Cutting Process Flows

## Status

Accepted (operator decision rendered at Stage 4 D-519-Scope 2026-05-07; design
surfaces resolved at Stage 5 spec 2026-05-10; ADR authored at Stage 6 per
Stage 5 spec § Spec Surface 6; numbered ADR-004 per Collective Review CONFLICT-1
resolution 2026-05-10 — three sequential ADRs: ADR-002,
ADR-003, ADR-004).

## Context

[`core/disciplines/five-function-spine-and-process-flows.md`](../disciplines/five-function-spine-and-process-flows.md)
maps the platform's 13-stage improvement-to-deployment pipeline to the 5
universal PMBOK Process Groups (Initiating, Planning, Executing, Monitoring
& Controlling, Closing), enumerates 10 cross-cutting process flows that
thread through the pipeline, and provides a methodology-primitive → stage
variants table for 3 named archetypes (Scrum, Waterfall, Kanban). It is the
authoritative anchor for the [Function](../specs/terminology-glossary.md#term-function)
concept named in the [terminology glossary](../specs/terminology-glossary.md)
and pre-cited at line 111 of [`execution-framework.md`](../disciplines/execution-framework.md).

The file is a **HARD-handoff data contract** for the role-skill wave:
downstream role skills will compose against
the function-mapping table as a stable vocabulary. The companion file
[`operating-model.md`](../disciplines/operating-model.md) (authored in the same release) inlines the Primary Function value from
this file's mapping table as a data column in its Per-Stage Execution
Blueprint — making the function-mapping rows load-bearing for the
operating-model's reader experience and for delivery-engine
consumers that read both files together.

Three load-bearing design choices were made during authoring. Each has
plausible alternatives that future authors may want to revisit; preserving
rationale here protects the rationale from being lost if the file is
re-organized in a later release.

## Decision

### Decision 1 — Primary+Secondary function-mapping scheme

Each stage maps to exactly **one Primary Function** + zero-or-more
**Secondary Functions**. The Primary Function names what the stage primarily
accomplishes in PMBOK terms (a one-word answer for column-level citation);
the Secondary Functions name the cross-cutting work that overlaps inside the
stage (most often Monitoring & Controlling, which PMBOK treats as cross-cutting
throughout the lifecycle). Across the 13 stages, Monitoring & Controlling
appears as Secondary on 9 stages — capturing the empirical reality without
overloading the Primary column.

**Rationale.** Of the four mapping schemes considered (strict 1:1, many-to-one
Primary-only, Primary+Secondary, many-to-many), Primary+Secondary is the only
scheme that honors PMBOK Process Group overlap honestly while preserving the
1-word answer affordance needed for [`operating-model.md`](../disciplines/operating-model.md)'s
Universal Function column. Strict 1:1 would misrepresent stages like Stage 6
Engineering (where M&C runs concurrently with Executing through DT↔Engineering
iteration feedback). Many-to-many would over-engineer a 13×5 grid and lose
the per-stage 1-word answer that the operating-model consumes as a data
column. Many-to-one (Primary-only) would hide the M&C cross-cutting reality
that the platform's own QC checkpoints (QC2 at Stage 5, QC3 at Stage 7, QC4
at Stage 13) make load-bearing.

### Decision 2 — 10-flow cross-cutting taxonomy

The cross-cutting taxonomy is **10 flows** — Risk Management, Change Control,
Quality Assurance, Stakeholder Engagement, Communication & Handoff,
Configuration Management, Decision Management, Audit Trail / Knowledge
Capture, Continuous Improvement, Dependency Management. Each maps 1:1 to
either a PMBOK Knowledge Area or a platform-native mechanism with no clean
PMBOK analog. No invented flows.

**Rationale.** The 10-count was validated against fewer-and-more
alternatives. **Fewer would conflate distinct mechanisms**: Risk Management
and Change Control are separate PMBOK Knowledge Areas served by separate
platform sources (Risk Register vs. Inter-Stage Feedback Protocol);
collapsing them loses per-flow citation discipline. Quality Assurance and
Audit Trail / Knowledge Capture are likewise distinct surfaces (gate
criteria vs. captured evidence). **More would over-fragment**: Rollback /
Reversibility was considered as a separate flow and rejected (too narrow;
rolled into Change Control); Cost / Resource Management was rejected
(not applicable to single-operator PMO); Procurement was rejected (not
applicable); Schedule Management was rejected (overlaps with Configuration
release cadence + Methodology Variants); Issue Management was rejected
(overlaps with Change Control + Audit Trail). The 10 names that remain
each trace to a canonical platform source — no taxonomy is invented for
this document.

### Decision 3 — 13×3 archetype × stage variants matrix

The Methodology Variants section uses a **13-stage-row × 3-archetype-column**
master table covering Scrum, Waterfall, and Kanban. A per-archetype 1-paragraph
intro precedes the table. The 5 archetypes not covered here (XP, PRINCE2,
SAFe, Hybrid, Custom) are pointed to [`methodology-archetype-matrix.md`](../../release/references/specs/methodology-archetype-matrix.md)
for archetype properties.

**Rationale.** Three table cuts were considered. **(a) Per-archetype subsection
with prose per stage** would balloon Section length and lose the cross-stage
comparison affordance that a matrix provides. **(b) 13×8 full matrix covering
all 8 archetypes** would produce ~104 cells, most of which would be "N/A" or
"see Custom block" — most cells would not earn their tokens. The issue body
explicitly names 3 archetypes (Scrum / Waterfall / Kanban) as the scope; the
13×3 master table covers exactly the named archetypes with one cell per
intersection. **(c) 13×3 master table (selected)** matches the issue scope,
preserves cross-stage comparison (read down a column to see archetype
progression; read across a row to see how a single stage manifests under
3 archetypes), and produces a finite, reviewable artifact. The Coverage Note
paragraph at the top of the Methodology Variants section (per Tier 1
in Stage 5 spec § Spec Surface 5 / Finding 1) explicitly states that this
section occupies the **third complementary methodology-variation slot**
(per-archetype methodology-primitive → stage mapping), distinct from
the archetype-properties matrix and `release-process.md`'s
release-cadence variation table.

## Consequences

**Positive:**

- **Stable vocabulary for role-skills.** Role skills compose against
  the Primary Function name as a 1-word answer per stage. The table is
  finite (one row per pipeline stage), enumerable, and grep-stable.
- **Operating-model.md column inline is feasible.** Because Primary is
  exactly one value per stage, [`operating-model.md`](../disciplines/operating-model.md)
  Universal Function column carries plain-text data (not a hyperlink per
  stage). Cross-reference density between the two files stays at 2 total
  (1 each direction) — under the Collective Review density threshold.
- **Honors PMBOK overlap.** Secondary Functions capture the cross-cutting
  reality that Monitoring & Controlling threads through 9 of 13 stages
  without overloading the Primary column.
- **10-flow taxonomy is grep-stable.** Each flow has a dedicated H3 and a
  canonical-source citation; downstream consumers (e.g., the audit-trail
  capture) can grep-enumerate the 10 flows when normalizing per-flow
  schemas.
- **13×3 matrix is reviewable.** Each cell is one bullet of text; the
  whole table fits on one page and can be reviewed without scrolling.

**Negative:**

- **Primary+Secondary requires authors to make a judgment call** on each
  stage's primary categorization. Reasonable people may disagree (e.g.,
  Stage 12 Execute is Executing + M&C + Closing — three plausible
  Primaries). Mitigated by the rationale column in the function-mapping
  table; future authors can revisit specific cells without re-designing
  the scheme.
- **10-flow taxonomy adds a 10th item that future authors may try to
  fold into 8 or 9.** The taxonomy is not load-bearing for any current
  consumer; it is load-bearing if function-level audit
  schemas are adopted. Mitigated by per-flow canonical-source citation
  (each flow has a discoverable mechanism).
- **13×3 matrix omits 5 archetypes.** Authors of a methodology variant
  not named in the 3-column scope must consult two cross-references
  (`methodology-archetype-matrix.md` + `methodology-parameterization-v1.md`)
  to assemble the equivalent mapping. Mitigated by the Coverage Note
  paragraph that explicitly points consumers to the other 5 archetypes'
  reference docs.

**Mitigation of negatives:**

- Function-mapping table includes a rationale sentence per row — disputes
  on specific cells can be resolved against the rationale without
  re-designing the scheme.
- 10-flow taxonomy carries per-flow canonical-source citation; if a future
  release wants to fold flows, the merging release supersedes this ADR
  with a new ADR documenting the merge.
- For methodology variants beyond the 3 named archetypes, the
  `custom_methodology_definition` block in PROJECT.md (per
  [`methodology-parameterization-v1.md § Custom Extension Protocol`](../../release/references/specs/methodology-parameterization-v1.md))
  is the authoritative escape hatch — skills derive stage variants from
  the declared lifecycle / ceremonies / artifacts / cadence fields.

## Alternatives Considered

### Decision 1 alternatives

- **(A) Strict 1:1 (each stage → exactly one function)** — REJECTED.
  Misrepresents PMBOK Process Group overlap (M&C runs throughout) and
  produces a falsely clean mapping. Stages 6, 7, and 8 in particular
  carry irreducible M&C work alongside their Primary function.
- **(B) Many-to-one with Primary only (no Secondary)** — REJECTED. Hides
  the cross-cutting reality that the platform's own QC checkpoints (M&C)
  overlap with Executing during Stage 6 and with Closing during Stages
  8-9-12. The operating-model.md Universal Function column can take just
  the Primary value, but the spine doc itself needs Secondary visibility
  for the function-mapping rationale to hold.
- **(C) Primary + Secondary (selected).**
- **(D) Many-to-many (free-mapping across the 13×5 grid)** — REJECTED.
  Over-engineers the table to capture cross-cutting that the Cross-Cutting
  Process Flows section already names explicitly. Loses the per-stage
  1-word answer affordance needed by `operating-model.md`'s data column.

### Decision 2 alternatives

- **(A) 10 flows (selected).**
- **(B) Fewer flows (collapse Risk + Change, collapse QA + Audit Trail)** —
  REJECTED. Conflates distinct PMBOK Knowledge Areas and platform sources.
  Risk Register and Inter-Stage Feedback Protocol are separate mechanisms;
  gate criteria and captured evidence are separate surfaces.
- **(C) More flows (Rollback, Cost, Procurement, Schedule, Issue
  Management as separate H3s)** — REJECTED on a per-candidate basis:
  Rollback is a Change Control terminal action (not a separate flow);
  Cost and Procurement do not apply to single-operator PMO; Schedule
  overlaps with Configuration (release cadence) + Methodology Variants;
  Issue Management overlaps with Change Control + Audit Trail.

### Decision 3 alternatives

- **(A) 13×3 matrix (selected).**
- **(B) Per-archetype subsection with prose per stage** — REJECTED.
  Inflates section length; loses cross-stage comparison affordance.
- **(C) 13×8 full matrix covering all 8 archetypes** — REJECTED. Produces
  ~104 cells, most of which would be "N/A" or "see Custom block". Most
  cells would not earn their tokens. The issue body explicitly names
  3 archetypes as the scope.

## Reversibility

CHEAP — the file is a reference document; revising Decisions 1, 2, or 3
requires rewriting the corresponding section of
[`five-function-spine-and-process-flows.md`](../disciplines/five-function-spine-and-process-flows.md)
and superseding this ADR with ADR-NNN documenting the new policy.
Downstream consumers (operating-model.md, the role-skill wave) consume
the function-mapping rows by name; a row-level revision is a SHA-pinned
cascade rather than a full re-design. Full-scheme revision (e.g., switching
from Primary+Secondary to many-to-many) would be EXPENSIVE because the
operating-model.md Universal Function column inlines the 1-word Primary
value as data — a scheme change would re-cast the data contract for those
consumers.

## References

- Parent issue — Architecture: Five-Function Spine & Cross-Cutting Process Flows
- Stage 5 spec (Spec Surfaces 1, 2, 3, 6)
- Stage 4 release plan (operator decision record D-519-Scope = (A); D-182-vs-519-Boundary = (A); D-Release-Scope = (A); 2026-05-07)
- Collective Review record (CONFLICT-1 ADR numbering = three sequential ADR-002/003/004; CONFLICT-2 cross-ref pattern = (A) 2 total cross-refs)
- Companion file: [`core/disciplines/five-function-spine-and-process-flows.md`](../disciplines/five-function-spine-and-process-flows.md)
- Companion ADR: [`ADR-003-operating-model-composition.md`](ADR-003-operating-model-composition.md) (authored in subsequent commit on this PR's feature branch)
- Companion ADR: [`ADR-002-modular-pipeline-stages-split.md`](../../release/ADRs/ADR-002-modular-pipeline-stages-split.md) (authored on the release branch)
- Pre-existing forward refs to this file: [`execution-framework.md:111`](../disciplines/execution-framework.md), [`terminology-glossary.md § term: Function`](../specs/terminology-glossary.md#term-function)
- Cross-issue coordination — function-level audit-trail schema candidate
- Stage 6 spoke output: this Engineering execution.
