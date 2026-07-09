---
artifact_type: template
template_family: Design doc
domain: software
canonical_path: operations/templates/design-doc-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-07-04
updated: 2026-07-04
generated_by: release-pipeline v3.66
reviewer: N/A
canon: Google design-doc convention
canon_compat: plugin-aligned
version: v3.66
supersedes: N/A
superseded_by: N/A
---
<!-- reference-durability: allow-link -->
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into rendered design-doc instances — an instance starts at the H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5(a)): `plugin-aligned` records the ANTICIPATED alignment path at DRAFT — authoritative only at an APPROVED transition. Registry basis: plugin `engineering:system-design` co-locates system-design output aligned with the Google convention per template-taxonomy.md §6 row 3 + §7 localization audit trail (inventory dated 2026-05-10); this template carries the six canon sections. Live-plugin check 2026-07-03/04: the engineering:*/operations:*/product-management:* plugin suites are NOT installed in this workspace and NOT present in the marketplace roster — alignment is registry-anticipated, not live-verified. P5 re-evaluates against the live plugin at any future APPROVED transition. -->

# {{FEATURE_OR_SYSTEM}} — Design Doc

**Canon:** Google design-doc convention (Atwood / Henderson templates) — Context / Goals / Non-goals / Proposal / Alternatives / Risks. Registered as the Design-doc-family canon in [`template-taxonomy.md` §6 row 3](../../core/standards/template-taxonomy.md).
**Variant:** {{VARIANT — General | FDD | TDD | HLD | LLD (see Variant guidance below)}}
**Author:** {{AUTHOR}} · **Reviewers:** {{REVIEWERS}}
**Status:** {{DOC_STATUS — Draft | In review | Approved | Implemented | Deprecated}}
**Date:** {{DOC_DATE}}

---

## Context

{{CONTEXT — background + problem statement + scope, written for a reader unfamiliar with the system. What exists today, what hurts, and why this needs solving now.}}

## Goals

- {{GOAL_1 — measurable where possible}}
- {{GOAL_2}}

## Non-goals

- {{NON_GOAL_1 — something a reasonable reader might expect this design to cover, explicitly excluded, with a one-line why}}

## Proposal

{{PROPOSAL_SUMMARY — the design in one or two paragraphs, then structured to the depth the Variant requires:}}

### System context

{{SYSTEM_CONTEXT — where this sits among its neighbors; ownership and trust boundaries; a context diagram or its prose equivalent.}}

### Detailed design

{{DETAILED_DESIGN — components, data model, APIs/contracts, key flows. HLD: component responsibilities + interactions only. LLD: per-component interfaces, logic, and data structures. FDD: user-visible behavior and business rules; minimal internals.}}

### Cross-cutting concerns

{{CROSS_CUTTING — security, privacy, observability, capacity/performance, rollout/migration.}}

## Alternatives Considered

| Alternative | Summary | Why not chosen |
|---|---|---|
| {{ALT_1}} | {{ALT_1_SUMMARY}} | {{ALT_1_REASON}} |
| Do nothing | {{STATUS_QUO}} | {{STATUS_QUO_COST}} |

## Risks

| Risk | Likelihood / Impact | Mitigation | Owner |
|---|---|---|---|
| {{RISK_1}} | {{RISK_1_L_I}} | {{RISK_1_MITIGATION}} | {{RISK_1_OWNER}} |
| {{ASSUMPTION – CONFIRM}} | | | |

---

### Variant guidance (template guidance — delete this section from rendered instances)

One skeleton, four altitude/audience variants — the same six canon sections at different depth:

| Variant | Altitude | Primary audience | Proposal depth |
|---|---|---|---|
| FDD (Functional Design Doc) | Feature behavior | Business + delivery stakeholders | Functional behavior, user-visible flows, business rules; minimal internals |
| TDD (Technical Design Doc) | Implementation | Engineers on the owning team | Full detailed design: components, data, APIs, error handling |
| HLD (High-Level Design) | System architecture | Architects + adjacent teams | System context + component responsibilities and interactions; no per-component internals |
| LLD (Low-Level Design) | Component internals | Implementing engineers | Per-component interfaces, logic, data structures; assumes an HLD exists |

Authoring rules:

1. **Goals and Non-goals are the contract** — a reviewer should be able to reject scope creep by pointing at Non-goals.
2. **Alternatives Considered is load-bearing** — record the options a smart colleague would propose and why the chosen design beats them; "Do nothing" is always an alternative.
3. **Hold the Variant's altitude** — an FDD that drifts into schema design has lost its audience, and vice versa.
4. **Status advances** Draft → In review → Approved → Implemented; mark Deprecated when the doc no longer reflects reality (and link the successor).
