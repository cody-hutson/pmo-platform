---
artifact_type: template
template_family: ADR
domain: software
canonical_path: operations/templates/adr-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-07-04
updated: 2026-07-04
generated_by: release-pipeline v3.66
reviewer: N/A
canon: Nygard 2011
canon_compat: plugin-aligned
version: v3.66
supersedes: N/A
superseded_by: N/A
---
<!-- reference-durability: allow-link -->
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into rendered ADR instances — an instance starts at the H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6 P5(a)): `plugin-aligned` records the ANTICIPATED alignment path at DRAFT — authoritative only at an APPROVED transition. Registry basis: plugin `engineering:architecture` is the registered cross-ref for the ADR family per template-taxonomy.md §6 row 1 + §7 localization audit trail (inventory dated 2026-05-10); this template carries the 4 Nygard canon sections in canon order. Live-plugin check 2026-07-03/04: the engineering:*/operations:*/product-management:* plugin suites are NOT installed in this workspace and NOT present in the marketplace roster — alignment is registry-anticipated, not live-verified. P5 re-evaluates against the live plugin at any future APPROVED transition. -->

# ADR-{{NNN}}: {{DECISION_TITLE}}

**Canon:** Nygard, "Documenting Architecture Decisions" (2011) — Context / Decision / Status / Consequences. Registered as the ADR-family canon in [`template-taxonomy.md` §6 row 1](../../core/standards/template-taxonomy.md).
**Project:** {{PROJECT_NAME}}
**Author:** {{AUTHOR}}
**Date:** {{DECISION_DATE}}

---

## Context

{{CONTEXT — the forces at play: technical, business, team, constraints. Value-neutral: a reader should understand why a decision became necessary without being sold the answer.}}

## Decision

We will {{DECISION — active voice, full sentences: the chosen response to the forces above.}}

## Status

{{STATUS — one of: Proposed | Accepted | Deprecated | Superseded by ADR-{{MMM}}}}

## Alternatives Considered *(required — content conditional)*

*Keep this section in every rendered instance. Where ≥2 viable options were weighed, fill the table. Where a single forced approach existed, replace the table with that statement — "Single forced approach; no viable alternative was weighed." An absent section is a defect; a declared single-forced-approach is conformant.*

| Option | Summary | Why rejected |
|---|---|---|
| {{OPTION_A}} | {{OPTION_A_SUMMARY}} | {{OPTION_A_REJECTION}} |
| {{ASSUMPTION – CONFIRM}} | | |

## Consequences

{{CONSEQUENCES — the resulting context after the decision applies: positive AND negative. All consequences, not only the convenient ones.}}

---

### Authoring rules (template guidance — delete this section from rendered instances)

1. **One decision per ADR.** Capture a single architecturally-significant decision; a document covering several decisions is a design doc, not an ADR (see `design-doc-template.md`).
2. **Numbering is project-local and monotonic.** {{NNN}} is the next free number in the consuming project's own ADR sequence (e.g., `docs/adr/` in the project repo, or the project's `08-Generated/` staging area). Numbers are never reused or renumbered.
3. **ADRs are immutable once Accepted.** To change an Accepted decision, author a NEW ADR that supersedes it and update only the old record's Status to `Superseded by ADR-{{MMM}}` — never rewrite the accepted body (Nygard convention).
4. **Keep it short.** One to two pages, written as if explaining the decision to a future teammate.
5. **Scope boundary — platform-internal ADRs are a different population.** This template governs software-domain ADR *instances produced in a consuming project*. The PMO platform's own ADR corpus (`core/ADRs/`, `release/ADRs/`) is governed by a distinct contract — [`adr-schema.md`](../../core/schemas/adr-schema.md) + [`adr-authoring-guide.md`](../../core/standards/adr-authoring-guide.md) (7-field frontmatter; its own body-section set, defined once in that schema's §3 and led by Status; platform-global numbering). Do not use this template for platform-internal ADRs, and do not impose the platform contract on project ADRs. The one predicate the two populations share is the `## Alternatives Considered` **requirement level** — required section, conditional content — because a rendered project ADR that silently omits its alternatives has the same defect regardless of which corpus it lands in. Section order, section count, and numbering scope stay population-local.
