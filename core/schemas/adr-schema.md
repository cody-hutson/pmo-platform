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

## 3. Body sections (6, in order)

| # | Section | Required | Contract |
|---|---|---|---|
| 1 | `## Status` | Yes | Restates `status`; when Superseded, **cites the superseding ADR here** (supersession *representation* — see §5). |
| 2 | `## Context` | Yes | The forces/problem the decision addresses. |
| 3 | `## Decision` | Yes | The decision, stated actively. |
| 4 | `## Consequences` | Yes | Resulting trade-offs, positive + negative. |
| 5 | `## Reversibility` | Yes | One of CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE (+ optional rationale) per [`reversibility-protocol.md`](../specs/reversibility-protocol.md). |
| 6 | `## Related ADRs` | Yes | Cross-ADR composition/supersession links (ADR-number form). |

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
