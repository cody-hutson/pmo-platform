# Type Map (the work-item type registry seam)

This table is the parameterization seam for the work-item type system. The intake-elicitor loop reads the type set,
the intake hierarchy, and the per-type/per-level required-field maps from THIS file — never inline in SKILL.md. When
the work-item type system lands, it replaces or extends this table (or repoints the one-line registry source in
SKILL.md); no SKILL.md change is required on type-set growth. The seam is additive and intentional forward-debt: if
the type system's registry shape diverges materially, this single file is rewritten once. The governing decision is
recorded in the type-registry-seam ADR (see Provenance block at the end).

Today the registry enumerates the four shipped work-item types, keyed to the four GitHub Issue-Form templates under
`.github/ISSUE_TEMPLATE/`. Three of the four templates are GitHub Issue **Forms** with structured fields; the
emission mechanics for those structured fields (dropdowns that a freeform body cannot populate) live in
`references/output-contract.md`.

## The four current work-item types

| Type | Template | When to choose it |
|---|---|---|
| `improvement` | `improvement.yml` | A proposal with a specific change you can name. Spans story/feature/initiative altitudes via field emphasis until a first-class story/initiative type ships. |
| `bug` | `bug.yml` | A finding of the form "X is broken" rather than "we should add/change X". |
| `observation` | `observation.yml` | A gap or drift where "what good looks like" fits in one sentence and the next action is "look at it" rather than a specific change. The placeholder tier. |
| `adr` | `adr.yml` | The "idea" is actually an architecture or design decision needing a record, not a work item. |

## The intake hierarchy (altitude → type emphasis)

Until a first-class story/initiative type ships, both story-equivalent and initiative-equivalent items map to
`improvement`; the elicitor differentiates by altitude-driven field emphasis and records the intended granularity in
the body. This is exactly the seam the type system later formalizes.

| Altitude | Type | Field emphasis |
|---|---|---|
| Initiative / portfolio | `improvement` | Outcomes, domain context, child decomposition surfaced |
| Story / feature | `improvement` | Acceptance criteria, value (Proposed Change framed as an outcome) |
| Task / small change | `improvement` | Atomic change, named files, verifiable AC |
| Broken behavior | `bug` | Reproduction, environment |
| Design decision | `adr` | Considered options with pros/cons, decision, consequences |
| Thin / not-yet-authorable | `observation` | What is missing, what good looks like (one sentence) |

## Per-type required-field maps

The fields below are transcribed from the live issue-form templates. The elicitor must capture every required field
or mark it explicitly as `[ASSUMPTION – CONFIRM]` (for deferrable fields) before emit. Fields marked "dropdown" are
structured GitHub Issue-Form fields — see `references/output-contract.md` for how they are carried at emit time.

### `bug` (maps to `bug.yml`) — solution level

| Field | Required | Notes |
|---|---|---|
| Severity | YES (dropdown: P1 Blocker / P2 Material / P3 Annoyance / P4 Cosmetic) | No severity label exists — carried in the body per the output contract. |
| Reproduction Steps | YES | Numbered steps a fresh agent can follow; exact commands/files/inputs. The bug-distinctive field. |
| Expected Behavior | YES | What should happen. |
| Actual Behavior | YES | What happens instead; error messages verbatim. |
| Environment | YES | Branch, commit SHA, OS, relevant tool versions. The bug-distinctive field. |
| Evidence | YES | Every factual claim labeled with an evidence-quality label. |
| Affected Files | YES | Files where the fix will land (directional OK). |
| Documentation Impact | YES | Pointer list, or an explicit "None — no documentation impact (rationale: …)". |
| Acceptance Criteria | YES | Typically "reproduction steps no longer trigger actual behavior; expected behavior observed." |

### `improvement` (maps to `improvement.yml`) — stakeholder/business level

| Field | Required | Notes |
|---|---|---|
| Priority | NO (dropdown: P1 Urgent / P2 High / P3 Medium / P4 Low) | Optional at intake; triage validates. |
| Category | YES (dropdown: Skill Update / Protocol / Structure / Documentation / Enhancement / Tracker Schema / Routing Rules) | Required; carries the type granularity until a first-class type ships. If none fit, route to `observation`. |
| Description | YES | WHAT is missing/broken, not HOW. |
| Evidence | YES | Every factual claim labeled. |
| Affected Files | YES | Directional files, or the exact deferral marker "[ASSUMPTION – CONFIRM] TBD — identified in Planning". |
| Documentation Impact | YES | Pointer list, or an explicit "None — no documentation impact (rationale: …)". |
| Proposed Change | YES | The outcome, not the mechanism. For ambiguous design, defer to Solutioning with an `[ASSUMPTION – CONFIRM]`. |
| Dependencies | NO | Known dependencies as issue references. |
| Risks & Cross-Cutting Impact | NO | Named risks, or the literal "None identified". |
| Acceptance Criteria | YES | Each AC a testable predicate verifiable by a fresh agent; verb-led or naming a file/section plus an observable state. |

Story-vs-initiative emphasis within `improvement`: a story emphasizes acceptance criteria and value (Proposed Change
as an outcome); an initiative emphasizes outcomes, domain context, and child decomposition (surface the children,
do not auto-create them).

### `observation` (maps to `observation.yml`) — placeholder tier

| Field | Required | Notes |
|---|---|---|
| What is missing? | YES | The gap/drift/friction in one or two sentences. Do not propose a fix. |
| What does good look like? | YES | One sentence describing the intended end state. No HOW. |
| File or section affected | YES | Directional pointer to where the gap lives. |
| Notes | NO | Evidence label, related-item link, or context for promotion time. |

Route here when the 5-test's T3/T4/T5 fail and the user cannot fix at authoring time — rather than forcing a thin
`improvement`.

### `adr` (maps to `adr.yml`) — decision class

| Field | Required | Notes |
|---|---|---|
| Status | YES (dropdown: Proposed / Accepted / Deprecated / Superseded) | Lifecycle status. |
| Context | YES | The issue that motivates the decision. |
| Decision Drivers | YES | Constraints or goals that shape the choice. |
| Considered Options | YES | At least two options with pros and cons. |
| Decision | YES | Which option was chosen and why. |
| Consequences | YES | What follows — both positive and negative. |
| Related Issues | YES | Release issues, improvement issues, or prior ADRs this decision serves, as issue references. |

Surface `adr` when the user's "idea" is actually a design decision needing a durable record, not a work item.

## Provenance

This block is the single designated home for issue and ADR identifiers cited by this file.

- Type-registry-seam decision record: ADR-016
- Forward-coupled work-item type system (proposed, out of scope; later repoints this table): #409
- Originating skill issue: #412
