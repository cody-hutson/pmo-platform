<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: The deliverable-domain axis lands on PROJECT.md frontmatter, not the type-pack
status: Accepted
date: 2026-06-29
release: 18-pmbok-coverage-and-project-schema
deciders: "Workspace owner"
tags: [project-schema, deliverable-type, domain-axis, methodology-orthogonal, type-pack-boundary, reversibility-expensive]
---

# ADR-050 — The deliverable-domain axis lands on PROJECT.md frontmatter, not the type-pack

## Status

**Accepted.**

Number **050** — next gap-free after 049; binds atomically at Stage 12.

## Context

The platform is methodology-aware but **domain-blind at the PROJECT.md layer**: `project-schema.md` frontmatter declares `delivery_approach` (*how work is governed*) but no project-level field for the **deliverable domain** (*what kind of work is delivered*). Non-software work — a website build, an ERP customization, a code-review engagement — degrades silently because consumers cannot branch on deliverable kind the way they branch on methodology.

This is **not greenfield**. A governed `domain:` class field already ships at the Stage-4 Planning layer (`stage-04-planning.md` §5.7), is mandatory in every mode, and drives three live consumers (the impact-analysis method selector, the design-best-practice review criterion, the domain-guide index). It **explicitly forward-references this decision**: *"a first-class PROJECT.md domain axis is a follow-up that later becomes an additional authoritative source feeding this same field without reworking the consumers."* Per-domain guides already exist (`core/standards/domain-best-practices/{software,governance,process}.md`); the intake-side domain representation shipped (#344). So this decision adds the **PROJECT.md authoritative source** a pre-built, already-consumed socket anticipates.

Two design forks had to be settled. **(1) Placement:** does the axis land on `project-schema.md` frontmatter, or as a `work-item-type-schema.md` type-pack grammar entry? **(2) Enum shape:** closed (exactly the recognized classes) or open (recognized-class-or-well-formed-string)?

## Decision

**The deliverable-domain axis lands as a project-level frontmatter field — `deliverable_type` — on `project-schema.md`, orthogonal to `delivery_approach`; it is NOT a type-pack grammar entry, and its enum is OPEN (shape-validated), mirroring `delivery_approach: Custom` openness.**

1. **Placement on project-schema, not the type-pack — forced by the ADR-018 kernel.** `work_item_type` is the *declarative discriminator for a work-item kind* (story/task/bug/spike), explicitly the **domain-neutral methodology→hierarchy map** (`work-item-type-schema.md`); `core/` must not depend on release-pipeline dev tooling (ADR-018). `deliverable_type` is a different axis entirely — *what the project produces*, not *what kind a work-item is*. The two are orthogonal and must stay so: a `deliverable_type: software` project still contains `work_item_type: story` items. The axis is therefore a PROJECT-level frontmatter field beside `delivery_approach`, validated by rule V13 (the reserved tail).

2. **Open enum, not closed — forced by precedent + the Stage-4 expansion rule.** Three shipped fields already canonicalize "open declaratively, closed at the enum/code level" — `delivery_approach: Custom`, the `work_item_type` custom-kind, and `analysis_type` (which already names `deliverable_type` as a member of that open-enum family). The Stage-4 `domain:` field already accepts "a free domain name when no guide exists yet … the demand signal for authoring a guide." A closed `deliverable_type` would be the lone closed sibling and would fight the expansion rule it must feed. The recognized set is the union of the live Stage-4 classes and the domains with shipped guides — `{software, governance, web, data, enterprise-platform, hardware, process}` — plus a non-empty lowercase-kebab escape.

3. **Compose with the methodology axis, never absorb it.** Consumption parallels §5: a new §5A in `methodology-parameterization-v1.md` branches `deliverable_type` → the matching domain guide, fallback = domain-agnostic-with-caveat (the §5 CASE-3 analog, no silent default). A consumer reads `delivery_approach` and `deliverable_type` independently and combines them. Gate G3-05 is conditioned so AC verifiability conforms to the deliverable's domain, extending the already-shipped domain-aware review chain.

4. **Additive — wire a source into a pre-built socket.** `deliverable_type` is optional on legacy files (required forward); existing methodology-only PROJECT.md files validate unchanged (V1–V12 + V13-N/A). Where present, the field is the authoritative source the Stage-4 `domain:` label reads — the consumer chain is unchanged.

## Alternatives Considered

- **Land the axis as a `work_item_type` type-pack entry** — rejected: violates the ADR-018 `core/`-independence kernel and conflates two orthogonal axes (deliverable-kind vs. work-item-kind). A `deliverable_type: software` project still contains `work_item_type: story` items; folding one into the other destroys the orthogonality.
- **Closed enum (exactly the recognized classes)** — rejected: every new domain would force a governed schema edit + V-rule churn, contradicting the Stage-4 "free domain name when no guide exists yet" expansion rule and breaking from the three shipped open-enum precedents. Tightening an open enum later is additive; loosening a closed one is the painful direction — open-first is the lower-regret default.
- **Reuse the bare name `domain`** — rejected: `domain` is overloaded 4 ways (Stage-4 deliverable-class, artifact-provenance `A|B|C`, content-area `delivery/{domain}`, the behavioral/domain-predicate adjective). The non-colliding name `deliverable_type` is mandatory; a disambiguation note fixes the boundaries.
- **Defer to the Stage-4 `domain:` label alone (no PROJECT.md field)** — rejected: that field is explicitly "an abstract signal, not a hard read of a structured PROJECT.md field" and forward-references this card as its authoritative source. Leaving the source unbuilt is the gap #351 closes.

## Consequences

- PROJECT.md gains a first-class, validated deliverable-domain axis; consumer skills and gate criteria can branch on *what kind of work is delivered* the way they already branch on *how it is governed*. Non-software domains stop degrading silently.
- The Stage-4 `domain:` label gains an authoritative PROJECT.md source without any consumer rework — the forward-reference contract is honored.
- #262 (org-structure / delivery-model / team-roster) sequences after this keystone; its V-rules derive off the post-V13 tail (V14).
- The 4-way `domain` overload (artifact-provenance `A|B|C`, content-area `delivery/{domain}`) remains pre-existing naming-debt — documented by the disambiguation note, out of scope to rename here. Accepted, documented residual.
- The Stage-4 line-81 class list omits `process` (a shipped guide's domain); #351's enum is the authoritative source and supersedes that "e.g." list. A one-line Stage-4 refresh is routed to a next-release issue.

## Reversibility

**EXPENSIVE / Confidence HIGH.** Downgraded from the source pack's original MEDIUM because the consumer chain (Stage-4 `domain:`, the guides, #344) is already built and forward-references this field — this wires a source into a pre-built socket rather than cutting a new cross-cutting axis. The field is additive (optional-on-legacy), so introduction is non-breaking; but once consumers and #262 derive off it, the axis is load-bearing across the schema and the pipeline, so removal would be a weeks-scale, stakeholder-impacting unwind. The *openness sub-choice* is CHEAP (tightening to a closed enum later is additive validation). Confidence HIGH that project-schema placement + open enum are correct: both were forced by named architectural constraints (ADR-018 kernel; three open-enum precedents + the Stage-4 expansion rule), not by preference.

## Related ADRs

- **ADR-018** (work-item type layer) — supplies the `core/`-independence kernel that forces project-schema placement over the type-pack.
- **ADR-040** (leadership-owner Person ref) — sibling project-schema frontmatter type-lift; precedent for additive, validated PROJECT.md field evolution.
