---
title: ADR Schema — Architecture Decision Record Frontmatter + Body-Section Contract
purpose: The canonical single-source data contract for Architecture Decision Records — the frontmatter fields, their types + allowed values, and the required body-section structure. The ADR READMEs and the ADR authoring guide cite this doc instead of restating the field list.
type: schema
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: core/ADRs/README.md and release/ADRs/README.md (§Format cite this doc); the ADR authoring guide's template (references this field list — one source); pmo-qa-auditor / repo-integrity ADR authoring discipline
parallel_to: frontmatter-schema.md (disjoint population — operational K4 artifacts), platform-doc-frontmatter-standard.md (K1 core/** docs; §9 defers the ADR class here)
---
<!-- reference-durability: allow-link -->
# ADR Schema — Architecture Decision Record Frontmatter + Body-Section Contract

## 1. Purpose + scope

Canonical data contract for ADR files under `core/ADRs/` and `release/ADRs/`. Owns the **field + body-section contract**; it does NOT own the *when-to-write* rubric, the copy-paste template, or the supersession/immutability *policy* — those live in the ADR authoring guide (see §6 Boundary). Closes the [`platform-doc-frontmatter-standard.md`](../standards/platform-doc-frontmatter-standard.md) §9 ADR-class deferral: that standard names the ADR frontmatter set and defers its definition here; this doc is the definition.

## 2. Frontmatter fields (7)

| Field | Type | Required | Allowed values | Rule |
|---|---|---|---|---|
| `title` | string | Yes | free | `ADR-NNN — <human title>`; matches the H1. |
| `status` | enum-prefixed string | Yes | MUST begin with `Proposed` \| `Accepted` \| `Deprecated` \| `Superseded` (Nygard); optional prose tail permitted (ratification anchor / supersession pointer) | Leading-token rule (not a strict closed enum) — mirrors [`platform-doc-frontmatter-standard.md`](../standards/platform-doc-frontmatter-standard.md) §10 reversibility treatment; grounded in the ADR corpus (see §4). |
| `date` | ISO date | Yes | `YYYY-MM-DD` | Decision/authoring date. |
| `release` | string | Yes | release slug or version tag | The release the decision was rendered in. |
| `deciders` | string | Yes | free descriptive string | Who decided (operator + Stage 5 spoke + reviewers, in prose); NOT a closed enum — many observed forms. |
| `tags` | list[string] | Yes | free tags | Discovery tags. |
| `source_observations` | list[string] | Recommended | free prose entries | The grounding observations/evidence the decision rests on; may be long-form. |

## 3. Body sections (7, in order)

| # | Section | Required | Contract |
|---|---|---|---|
| 1 | `## Status` | Yes | Restates `status`; when Superseded, **cites the superseding ADR here** (supersession *representation* — see §5). |
| 2 | `## Context` | Yes | The forces/problem the decision addresses. |
| 3 | `## Decision` | Yes | The decision, stated actively. |
| 4 | `## Alternatives Considered` | Yes | **Required — content conditional** (see §3.1). Records the options weighed and why each was rejected; where a single forced approach existed, declares that explicitly. |
| 5 | `## Consequences` | Yes | Resulting trade-offs, positive + negative. |
| 6 | `## Reversibility` | Yes | One of CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE (+ optional rationale) per [`reversibility-protocol.md`](../specs/reversibility-protocol.md). |
| 7 | `## Related ADRs` | Yes | Cross-ADR composition/supersession links (ADR-number form). |

### 3.1 `## Alternatives Considered` — required section, conditional content

**Required — content conditional.** Every ADR carries this section. Where ≥2 viable options were weighed, it records each option and why it was rejected. Where a **single forced approach** existed — an ADR written because it binds a cross-artifact contract or supersedes a prior record, rather than because options were weighed — it says so explicitly. An **absent** section is a conformance defect; a section reading *"single forced approach; no viable alternative was weighed"* is **conformant**.

The canonical heading is the exact string `## Alternatives Considered` — H2, Title Case, at position 4.

The conditionality attaches to the section's **content**, never to its presence. The omission test is therefore **structural, not content-based**: presence is mechanically checkable, while the judgment about what the section says stays with the author. A presence rule closes the silent-omission failure mode that a presence-conditional rule leaves open — "only one option existed" stops being an unstated opt-out and becomes a reviewable claim on the record. This is the same construction [`evidence-grounding-standard.md`](../standards/evidence-grounding-standard.md) already applies to its own drift section, reused rather than re-invented.

**The set above is a MINIMUM, not a closed vocabulary.** An ADR may carry additional H2 sections beyond the seven — `## References`, `## Provenance`, `## Subordinate to` and similar are common and correct. A conformance check asserts that each of the seven **is present**; it never asserts that nothing else is.

### 3.2 Section-set authority chain

The section set and each section's requirement level are **defined here, once**. Every other **platform** surface **cites** this section and restates no level; the single exception is the project-ADR template, which governs a **disjoint** population behind its own §5 scope boundary and therefore **adopts** the same level in its own text rather than pointing at this section — the obligation its row below records verbatim. A surface added later joins this table and inherits the CITES obligation — that is what keeps a sixth surface from becoming a sixth divergent statement.

| Surface | Role | Obligation |
|---|---|---|
| `core/schemas/adr-schema.md` §3 (this section) | **DEFINES** | The single authority for the section set and each section's requirement level. |
| [`core/standards/adr-authoring-guide.md`](../standards/adr-authoring-guide.md) § ADR template | CITES | Renders the set as a copy-paste template; states no independent requirement level. |
| [`operations/templates/adr-template.md`](../../operations/templates/adr-template.md) | CITES (project-ADR population) | Adopts the same requirement level for its own **disjoint** population; keeps its §5 scope boundary intact. |
| [`core/skills/adr-helper/references/scaffolding-procedure.md`](../skills/adr-helper/references/scaffolding-procedure.md) | CITES | Scaffolds the set; emits every section as an author-fill placeholder. |
| `.github/ISSUE_TEMPLATE/adr.yml` | CITES | Intake fields mirror the set. |
| [`release/tools/check-adr-durability.py`](../../release/tools/check-adr-durability.py) | CITES (scope-declaring) + **enforces DELTA-ONLY** | Its self-test asserts its cited copy matches this section, membership **and** order. Rule R5 asserts **presence** of this set — never position, never a heading-form count — on two delta limbs only: a **net-new** ADR that lacks a section, and a **changed** ADR that has **lost** one it carried at the diff base. It asserts nothing about a section a record was already missing, and nothing at all without a diff base. Warn-mode at the CI surface. |

## 4. Value conventions

- **`status`** — the 4 Nygard tokens (see the §Status-enum table both ADR READMEs already carry: [`core/ADRs/README.md`](../ADRs/README.md) § Status enum); leading-token + optional tail.
- **`Reversibility`** — the 4-tier enum per [`reversibility-protocol.md`](../specs/reversibility-protocol.md) (both READMEs carry the tier table).
- ADR references in body/frontmatter use **ADR-number** form (`ADR-005`), not issue `#N` — keeps the durable-corpus gates green (see the ADR READMEs' § Repo-integrity authoring discipline).

## 5. Supersession — frontmatter/prose representation (policy lives in the authoring guide)

This doc documents only *how supersession is expressed*: (a) `status:` begins with `Superseded` (optionally `Superseded by ADR-NNN …`); (b) the `## Status` block cites the superseding ADR; (c) `## Related ADRs` carries the link. The *supersede-not-edit / immutability rule itself* is owned by the ADR authoring guide — see §6. Specimen: ADR-029 (`status: Superseded by ADR-045`).

## 6. Boundary — this schema vs the ADR authoring guide

This doc = the **data contract** (fields + sections + supersession representation). The ADR authoring guide = the **policy + ergonomics** (when-to-write rubric + non-triggers, the copy-paste template + worked example, the supersede-not-edit/immutability rule). The guide's template **references this schema** for the field list so the list has one source. [ASSUMPTION – CONFIRM at Collective Review: the authoring-guide milestone (`31-immutable-adr-system`) adopts this reference direction rather than re-inlining the fields.]

## 7. Relationship to platform-doc-frontmatter-standard.md

[`platform-doc-frontmatter-standard.md`](../standards/platform-doc-frontmatter-standard.md) governs authored K1 `core/**` docs and **explicitly excludes the ADR class from its field tables** (its §9 row + ADR-boundary note), deferring to this doc. This doc is that deferral's target. [`frontmatter-schema.md`](frontmatter-schema.md) governs a *third*, disjoint population (operational K4 project artifacts). The three do not overlap; an ADR obeys this doc.
