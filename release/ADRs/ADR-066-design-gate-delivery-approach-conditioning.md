<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: "ADR-066 — Design-before-slicing gate conditioned on delivery_approach: a new Gate-3 criterion (G3-18) that biases the design-invocation expectation per the declared methodology via the §5 Skill Consumption Pattern, base behavior unchanged when the axis is absent"
status: Accepted
date: 2026-07-01
release: 105-knowledge-corpus-tail-closeout
tags: [gate-criteria, delivery_approach, methodology-conditioning, design-before-slicing, stage-3, gate-3, pipeline, methodology-parameterization]
source_observations:
  - "Originating gap (#1087, REMAINING half): the platform's design governance is stage-bound and methodology-blind. Design is governed per-issue at Stage 5 Solutioning (Phase 0 Activation Gate) — i.e. AFTER slicing — with no read of delivery_approach anywhere in the gate stack. Lean/Scrum gate design-first before slicing; Kanban flows continuously (no sprint-slice gate); Waterfall uses phase-gates — but nothing invokes the archetype-appropriate design expectation at the correct pipeline stage. The observation carried an explicit operator caution: 'do NOT hardcode these gates — design the parameterization first.'"
  - "Substrate confirmed shipped (Stage 5 survey, 2026-07-01): the delivery_approach enum (core/schemas/project-schema.md §4), the Methodology Awareness Protocol (core/governance/OPERATIONS.md), and the platform backlog's methodology-preference home (core/config/operator.toml.template default_delivery_approach = 'Scrum') are all present. The 'no preference home for the repo's own backlog' gap the observation described is CLOSED; this ADR designs only the REMAINING gate-wiring."
  - "On-precedent (verified live): G3-05 (gate-criteria-spec.md) is a shipped Gate-3 criterion conditioned on a project axis (deliverable_type) via the §5A Domain-Axis Consumption Pattern, with a 'base measurability check unchanged' fallback when the axis is absent and unchanged Type/Check/Automation columns. §5A self-declares as the domain-axis sibling of §5, and §5 IS the delivery_approach consumption pattern (CASE 1 / 1-ARRAY / 2 / 3 with a no-silent-default fallback). ADR-033 governs methodology-conditional activation (dormant-off-match, [ASSUMPTION – CONFIRM]-when-absent). No gate criterion currently READS delivery_approach — only G3-10 notes it is orthogonal to Release Class."
---

# ADR-066 — Design-before-slicing gate conditioned on `delivery_approach` (criterion G3-18)

## Status

Accepted — operator-ratified at this release's Collective Review scope-lock (the Status-enum gate the release-ADR README names: "Operator-ratified at Collective Review or equivalent gate"). Authored at Stage 6 per the Stage-6 ADR-authoring precedent.

Numbered as the next-free slot across `core/ADRs/` and `release/ADRs/`, resolved at the authoring commit with `release/tools/check-adr-numbers.py` (the `adr-number-integrity` CI job) as the backstop. Referenced downstream **by slug**, never by number. Extended or reversed only by a **successor / superseding ADR** — never by an in-place edit of this record.

**Deliberate `deciders`-field omission.** This ADR is authored **without** a `deciders` frontmatter field, pending #1487/#1488 (the literal-name `deciders` convention is not yet ratified). The release-ADR README frontmatter template lists `deciders`; this ADR is a deliberate exception to that template until #1487/#1488 resolve. The omission is not a defect — do not add the field before the convention lands.

## Context

The "design-before-slicing" decision — *must the archetype-appropriate design activity be settled before work is decomposed into sub-tasks?* — is **methodology-dependent**: Scrum / XP / Lean-as-lightweight-Agile gate design-first before slicing; Waterfall / PRINCE2 use a phase-gate; Kanban flows continuously and has no sprint-slice gate. Today the platform governs design per-issue at Stage 5 Solutioning (the Phase 0 Activation Gate), which fires *after* slicing and reads no `delivery_approach` — so the design-invocation expectation is effectively hardcoded to one flow regardless of the declared methodology.

The methodology substrate has shipped: the `delivery_approach` enum, the Methodology Awareness Protocol, and the platform backlog's `default_delivery_approach` preference home. What is missing is the **gate-wiring** that makes the design-invocation expectation conform to the declared approach at the correct pipeline stage.

The correct stage is the **Stage 3 → 4 (Bundle → Planning) boundary = Gate 3 (Release Readiness)**. This is the point where a bundled milestone is judged "can this be responsibly assigned to a release" *before* Stage 6 Engineering slices it into sub-tasks (the Engineering-altitude decomposition at Stage 6 sub-task scaffolding). "Design-before-slicing" is by definition a *pre-slice* decision, so the gate that carries it must fire before Stage 6 — Gate 3 is that boundary.

The operator's explicit caution — *do not hardcode; design the parameterization first* — rules out a naïve "always gate design-first before slice." A gate that fired the design-first expectation unconditionally would break Kanban's continuous flow and regress every backlog/project that declares no methodology.

## Decision

**Add criterion G3-18 to Gate 3 (Release Readiness), conditioning the design-invocation expectation at the Bundle→Planning boundary on `delivery_approach` via the §5 Skill Consumption Pattern, following the G3-05 / §5A precedent.**

The conditioning shape mirrors G3-05 exactly:

- **CASE 1** (Scrum / XP / Lean-as-lightweight-Agile) → **design-first before slicing** (Stage 5 Solutioning activation is expected/biased-on for design-bearing issues before Stage 6 sub-task decomposition); Waterfall / PRINCE2 → **phase-gate** (design settled at the stage boundary); Kanban → **continuous, no sprint-slice gate** (the design-first-before-slice expectation does NOT fire).
- **CASE 1-ARRAY** (Hybrid `[A,B]`) → the phased constituent governs the gate expectation, rendered per §5's dominance rule.
- **CASE 3 / absent / `Custom` + `base_archetype: null`** → **base behavior UNCHANGED**: the pre-change design governance (design governed per-issue at Stage 5 on activation via the Phase 0 Activation Gate) applies with no methodology lens. This branch is implemented as an **explicit no-op default**, never a silent default-fire — dormant-with-`[ASSUMPTION – CONFIRM]` per ADR-033.

**The conditioning ADDS a methodology lens to *when* the design invocation is expected; it never removes the base design-activation check.** The Stage 5 Phase 0 Activation Gate remains the unconditional floor. Resolution of the axis goes through the **Config-Hierarchy Resolution Protocol** (`OPERATIONS.md`) — G3-18 does not hardcode a bare `operator.toml` file read; it resolves `default_delivery_approach` (platform backlog) or a project's `delivery_approach` (project-schema §4) through that protocol.

**Criterion columns — Type = `field` (CD-2 resolution).** G3-18 adopts G3-05's column shape: **`field` / `judgment` / `recommend`**. The Stage-5 design proposed `validation` for the Type column; the A6.5 review (CD-2) flagged this as a divergence from the very precedent the design claims to mirror. Reconciled to `field` because — per the § Schema Type-column enum (`field` = issue/config body field; `validation` = *cross-issue or cross-system check*) — G3-18 conditions gate behavior on a **declared axis value** (`default_delivery_approach` / project `delivery_approach`), exactly as G3-05 conditions on the declared `deliverable_type` field. It is not a cross-issue/cross-system check (which is what `validation` denotes, e.g. G1-09 label↔template or dependency-cycle detection). `field` is therefore the precedent-consistent Type, and it honors the design's own "columns unchanged per G3-05 precedent" invariant.

**Absent-axis no-op is a Stage-8 regression gate (FM-3).** The CASE-3/absent branch's "base behavior unchanged" property is promoted from a recommendation to a **Stage-8 acceptance gate** named `G3-18-absent-axis-noop`: a fixture milestone with no resolvable `default_delivery_approach` (and no project `delivery_approach`) MUST produce the identical verdict/routing it produced before G3-18 (trivial-PASS deferring wholly to the base Stage 5 Phase 0 Activation Gate). A second fixture with `delivery_approach: Kanban` MUST NOT fire the design-first-before-slice expectation. A third with `delivery_approach: Scrum` MUST fire it. Implement the branch as `if delivery_approach resolves AND ∈ gating-set → fire; else → trivial-PASS` — absence falls to the else-as-no-op, never to an else-as-gate.

## Alternatives Considered

- **(i) Hardcode design-first-before-slice for all flows.** REJECTED — violates the operator caution and breaks Kanban's continuous flow; regresses every un-declared backlog/project.
- **(ii) A brand-new §5B pattern for the gate axis.** REJECTED — §5 already IS the `delivery_approach` consumption pattern; reuse it rather than re-found it (the same reason §5A references §5 rather than forking it).
- **(iii) Condition at Stage 5 Phase 0 instead of Gate 3.** REJECTED — design-*before-slicing* is a pre-Engineering-slice decision; Stage 5 Phase 0 fires per-issue *after* slicing. Gate 3 is the Bundle→Planning boundary that precedes Stage 6 slicing — the correct altitude.
- **(iv) Extend an existing criterion (e.g. G3-04 scope-implementation-ready) with a methodology clause.** REJECTED — conflates "scope ready" (structural) with "design-invocation expectation" (methodology); overloads a criterion. A new criterion is the on-pattern choice (G3-05 establishes "a NEW Gate-3 criterion conditioned on a project axis via §5/§5A" as the canonical shape).

## Consequences

- **+ Methodology-appropriate design invocation.** Kanban stops being forced through a sprint-slice gate; Scrum/XP/Lean get the design-first-before-slice expectation; Waterfall/PRINCE2 get the phase-gate expectation.
- **+ Zero behavior change for the un-declared installed base.** The CASE-3/absent explicit no-op guarantees that any backlog/project not declaring a methodology sees no change unless it opts in via `default_delivery_approach` / `delivery_approach`.
- **− One new judgment-recommend criterion** (non-blocking, warn-class) + one self-repair row in `gate-criteria-spec.md`, plus a Stage-8 regression fixture (`G3-18-absent-axis-noop`, owed at Stage 8).

## Reversibility

**CHEAP / Confidence HIGH.** Additive gate criterion (one criterion row + one self-repair row + the §5-reference in the schema version-history); `git revert` of the release PR restores prior state. The CASE-3/absent no-op guarantees zero behavior change for un-declared backlogs, so the rollback surface is inert for the installed base.

## Related ADRs

- **ADR-033** (methodology-conditional skill activation) — G3-18's fallback semantics (dormant-off-match, `[ASSUMPTION – CONFIRM]`-when-absent, no silent default-fire) ARE ADR-033's activation semantics applied to a gate criterion, not a new convention.
- **The G3-05 / §5A conditioning precedent** — same shape (Gate-3 criterion conditioned on a project axis via the §5/§5A pattern, columns unchanged, base-unchanged fallback), sibling axis. G3-18 is to `delivery_approach` (§5) what G3-05 is to `deliverable_type` (§5A).
