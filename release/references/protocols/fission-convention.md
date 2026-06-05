# Fission Convention

Defines how to decompose a single too-broad issue into multiple implementable children with bi-directional traceability. Fission is the **1→N inverse** of [subsumption](subsumption-convention.md): subsumption closes a redundant smaller ticket into a broader survivor (N→1), while fission splits a too-broad parent into N peer children that each re-enter Triage independently.

## When to Fission

Use fission when:
- T1 atomicity fails per the [5-test rule](../how-to/intake-style-guide.md) — a single `git revert` cannot atomically undo the bundled change because ≥2 unrelated changes are coupled in one ticket.
- More than one implementer could work disjoint AC subsets independently.
- The parent's Acceptance Criteria do not share a common observable outcome — each AC describes a separate capability.

Do **not** fission when:
- The parent's scope is reducible by removing one AC — that is **scope reduction**, edit the parent body in Triage Phase B.
- The parent partially overlaps with another open issue — that is a **dependency link** (`Related to #N`), not a split.
- The parent has already been Approved and bundled into a Milestone — that is a **Tier 2 [SCOPE CHANGE]** escalation per [release-process.md § Inter-Stage Feedback Protocol](../../governance/release-process.md), not in-Triage fission.

## Parent Disposition

The parent takes one of two paths after fission (per D-ParentDisposition: TWO-PATH):

- **(a) Close as fissioned (default).** Parent closes with `not planned` reason and adds the `duplicate` label for traceability (mirrors [subsumption Step 3](subsumption-convention.md)). Children take their own re-triage path independently. Apply when the parent's coordination value is exhausted once children exist.
- **(b) Convert to tracking (operator-elect).** Parent stays OPEN with body amendment to "Tracks: #A, #B, #C..."; the `umbrella` label is applied if registered (otherwise plain body annotation suffices). Apply when ≥3 children plus sustained cross-issue coordination value justify keeping the parent as a tracking surface.

Default close honors the structural symmetry with subsumption; convert-to-tracking is the operator's explicit opt-in.

## AC Distribution

Each Acceptance Criterion on the parent maps to exactly one of three distribution patterns, recorded in the parent's Fission Comment Distribution Map (see Procedure Step 3):

- **(a) Assigned** — the AC lands verbatim on one child. The child inherits the AC text and its predicate.
- **(b) Duplicated** — the AC lands on multiple children. Each child's body cites "Inherits parent AC#N for [scope]"; each child verifies its scoped slice.
- **(c) Rewritten** — the AC is rewritten per child to reflect that child's narrower scope. Each child names the parent AC# as ancestor in its body so the rewrite chain is auditable.

The author drafts the distribution table in the Fission Comment on the parent before children are created; the operator validates it at Triage Phase B.

## Evidence Inheritance

Evidence labels on the parent (`[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, `[RECOMMENDED]`) copy to children per relevance:

- **Shared-context evidence** (CLAUDE.md citations, governance file references, cross-cutting `[CONTEXT]` blocks) copies verbatim to ALL children.
- **Child-specific evidence** (a `[SOURCE]` that grounds one child's scope only) copies only to the relevant child.
- **Inherited `[ASSUMPTION – CONFIRM]` flags** copy to the child whose scope inherits the assumption — and remain as `[ASSUMPTION – CONFIRM]` until that child's own Triage resolves them.

The author drafts evidence-distribution rationale in the Fission Comment; the agent verifies inheritance at each child's Triage A1 (DoR completeness check).

## Dependency Rewiring

Body `#N` references in the parent's Dependencies field route to exactly one of three rewiring patterns:

- **(a) Retarget to specific child** — when the downstream consumer of the dep is now one child's scope, the dep moves to that child's body Dependencies field; the parent body's reference is removed (or rewritten to the new owner).
- **(b) Stay on parent** — when the parent takes the Convert-to-tracking path, deps may stay on the parent if they reflect tracking-level coordination (not per-child execution).
- **(c) Duplicated across children** — when the dep was multi-target (e.g., a foundational protocol that several children inherit), the dep appears on each relevant child's body Dependencies field.

The native `blocked-by` re-mirror fires at each child's Triage A3.5 per existing protocol — the per-child mirror handles propagation without new logic.

The author drafts the dep-rewire table in the Fission Comment; the operator validates at parent close; child Triage A3.5 re-fires native-mirror per the existing per-child protocol.

## Bi-directional Traceability

Both directions of the parent-child relationship must be navigable:

- **Parent body annotation** — the parent's Notes section gains: `**Fissions into:** #A, #B, #C — [one-line rationale per child]`. Mirrors the subsumption `**Subsumes: #N**` annotation pattern.
- **Child body annotation** — each child's Notes section gains: `**Fissioned from:** #<parent> — [scope summary]`.
- **Parent close comment** — the parent's close comment posts the canonical 3-section Fission Comment template (see Procedure Step 3).
- **Query mechanism** — `gh issue list --search "in:body fissioned from #<parent>"` returns all children for any parent.

Bi-directionality is what distinguishes traceable fission from ad-hoc split.

## Re-triage State

Children land as `status: proposed` (full re-triage required) and inherit the parent's labels per the carry-forward rule (per D-ChildState: PROPOSED-INHERIT-LABELS):

- **Carry-forward labels:** parent's `cluster:*` + parent's category label + parent's priority (`P1`-`P4`) + any `initiative:*` labels.
- **Decision Date:** does NOT carry forward — each child gets its own Decision Date at child Triage CER Resolve (G2-06 fires fresh per child).
- **Status:** parent's `status: approved` / `status: bundled` (if any) does NOT transfer — children must pass Triage gates independently.

Triage gates (G1 DoR, G2-04 dependency state, G2-06 Decision Date) fire per child. Approving-by-inheritance would bypass the gates that detected the parent's intake-quality issue in the first place — and would silently propagate the atomicity defect to children.

## Fission Procedure

### Step 1: Update the Parent Issue Body

Add an annotation to the parent's Notes section:

```
**Fissions into:** #A, #B, #C — [one-line rationale per child]
```

If the operator elects the Convert-to-tracking path, also amend the body to "Tracks: #A, #B, #C". Per D-LabelDecision (ANNOTATION-ONLY), no new `triage: split-candidate` label is added.

### Step 2: Author Children

Each child gets:
- **Title** — scoped from the parent's title to the specific child scope.
- **Body Notes section line** — `**Fissioned from:** #<parent> — [scope summary]`.
- **Acceptance Criteria** — per the AC Distribution table (assigned / duplicated / rewritten per the parent's Fission Comment).
- **Evidence** — per the Evidence Inheritance table.
- **Dependencies** — per the Dependency Rewiring table.
- **Labels** — parent's `cluster:*` + parent's category + parent's priority + parent's `initiative:*` (carried forward) + `status: proposed` (children re-enter Triage fresh).

### Step 3: Post Fission Comment on Parent

Canonical 3-section template (mirrors [subsumption Step 2](subsumption-convention.md)):

```
## Fission

**Fissions into:** #A, #B, #C — [one-line rationale per child]

**Decomposition rationale:** [Why T1 atomicity failed; what dimension drove the split (skill / surface / capability / pipeline-stage / etc.)]

**Distribution map:**

| Element | #A | #B | #C |
|---|---|---|---|
| AC subset | [assigned / duplicated / rewritten] | [...] | [...] |
| Evidence inherited | [shared / per-child] | [...] | [...] |
| Dependencies | [retargeted / stay / duplicated] | [...] | [...] |

**Parent disposition:** [Close as fissioned / Convert to tracking]
```

### Step 4: Close (or Convert) the Parent

- **Close path (default):** `gh issue close <parent> --reason "not planned"` and add the `duplicate` label for traceability (mirrors [subsumption Step 3](subsumption-convention.md)).
- **Convert path (D-ParentDisposition b):** Parent stays OPEN; body amended to the tracking model; `umbrella` label applied if registered, plain body annotation otherwise. Children take their own re-triage path independently regardless of path choice.

## Integration with Triage (Stage 2)

During Triage Phase A1 (DoR completeness check):

1. The 5-test rule per [intake-style-guide.md](../how-to/intake-style-guide.md) renders SPLIT verdicts on T1 atomicity failure.
2. The Triage agent's A6 summary surfaces SPLIT candidates with proposed child decomposition for operator review.
3. The operator renders the fission decision at Phase B with parent-disposition choice (close as fissioned / convert to tracking).
4. The Triage agent executes the fission protocol per Procedure Steps 1-4 above BEFORE rendering the parent verdict.
5. Children enter their own fresh Triage cycle independently; the parent's verdict resolves via the standard 3-verdict semantics (typically Reject when fully decomposed via close-path; Approve when converted to tracking).

## Worked Example

Example: `[Skill Update]: PMO Role Skills Suite (18 Skills) → SPLIT` (the canonical 5-test T1 failure case cited at [intake-style-guide.md § Applied Examples](../how-to/intake-style-guide.md)). Illustrative 3-child decomposition shown.

| Field label | Value (worked example) |
|---|---|
| **When to Fission** | T1 atomicity fails — a single-commit revert cannot atomically undo an 18-skill build. ≥2 unrelated changes (each skill is independent code). >1 implementer can work disjoint AC subsets. |
| **Parent Disposition** | Convert-to-tracking (operator electing per D-ParentDisposition path b — 18 children + sustained coordination value via shared skill-deployment substrate). `umbrella` label applied conditionally; body amended to "Tracks: #A, #B, #C..." |
| **AC Distribution** | Parent's 4 AC distributed: AC#1 (skill-deployment.md updated) → all children (duplicated); AC#2 (per-skill SKILL.md authored) → one child each (assigned); AC#3 (cross-skill integration tested) → tracking-parent only (rewritten); AC#4 (release-bundled) → tracking-parent only (rewritten). |
| **Evidence Inheritance** | `[SOURCE: CLAUDE.md Skill Chaining Protocol]` → all children (shared-context); `[CONTEXT: skill-deployment.md S-2 mechanism]` → all children; `[ASSUMPTION – CONFIRM]` per-skill behavioral markers → only the corresponding child. |
| **Dependency Rewiring** | Parent's Dependencies field cited the release-planner ticket plus a related release-planner dependency — both retargeted to the tracking-parent (stays at tracking level, not per-child). Children declare no in-parent dependencies (decomposition was orthogonal). |
| **Bi-directional Traceability** | Parent body Notes: `**Fissions into:** #A, #B, #C — A: artifact-generator skill, B: build-reviewer skill, C: change-management skill` (+15 more rows in the actual fissioned case). Each child body Notes: `**Fissioned from:** <parent-id> — Skill A: [scope summary]`. Query `gh issue list --search "in:body fissioned from <parent-id>"` returns 18 children. |
| **Re-triage State** | Children A/B/C all land as `status: proposed` with `cluster: skill-modes` (carried from parent) + `skill-update` (carried from parent) + `P2` priority (carried from parent). Each child sets its own Decision Date at child Triage (CER Resolve fires fresh per child). |
| **Fission Comment on Parent** | (canonical 3-section template per Procedure Step 3) |
| **Fission Annotation on Parent Body** | `**Fissions into:** #A, #B, #C, ... (18 children) — see fission comment for full table` |

## Decision Table

| Scenario | Action | Convention |
|---|---|---|
| Atomicity fails (T1) — bundled unrelated changes | Fission parent into N children | This convention |
| Scope reducible by removing one AC | Scope reduction (edit parent body); NOT fission | Triage Phase B (operator decides at A6 summary) |
| Partial overlap with another issue | Dependency link `Related to #N`; NOT fission | Triage Phase A3 (existing dep validation) |
| Parent already Approved or bundled | Tier 2 [SCOPE CHANGE] escalation; NOT in-Triage fission | [release-process.md § Inter-Stage Feedback Protocol](../../governance/release-process.md) |
| Sub-implementation units within one issue | Engineering sub-task decomposition; NOT fission | Stage 6 sub-task pattern |
| Spans multiple milestones / capability tracks | Initiative breakdown; NOT fission | [initiative-roadmap framework](../../../core/standards/initiative-roadmap-framework.md) |

## Boundary Statements

The following three boundary statements distinguish fission from adjacent protocols:

1. **Fission ≠ subsumption.** Fission is 1→N (split a too-broad parent into N implementable children). Subsumption is N→1 (close a redundant smaller ticket into a broader survivor). The two are structural inverses operating on different cardinalities; they share the bi-directional traceability discipline but invert the parent/child closure direction.

2. **Fission ≠ Engineering sub-task decomposition.** Fission produces **independently triageable, independently bundleable** children — each child re-enters Stage 2 Triage; each child may bundle into a different Milestone. Engineering sub-task decomposition produces **implementation units within one bundled issue** — sub-tasks are scoped to one parent issue, one Milestone, and one Engineering session. Fission operates at the Stage 2 boundary; sub-task decomposition operates at the Stage 6 boundary.

3. **Fission ≠ initiative breakdown.** Fission operates at the **ticket level within Triage** — one parent → N children, all peers, all entering Triage. Initiative breakdown operates **across milestones with different cohesion-check requirements** — an initiative umbrella tracks long-running cross-milestone work; children bundle into different Milestones over time. Fission's children share a single Triage cycle; initiative children share a single capability outcome.

## Cutover

**Cutover discipline:** Applies to all issues entering Stage 2 (Triage) going forward.
