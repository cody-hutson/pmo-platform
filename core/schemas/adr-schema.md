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

## 2. Frontmatter fields (9)

| Field | Type | Required | Allowed values | Rule |
|---|---|---|---|---|
| `title` | string | Yes | free | `ADR-NNN — <human title>`; matches the H1. |
| `status` | enum-prefixed string | Yes | MUST begin with `Proposed` \| `Accepted` \| `Deprecated` \| `Superseded` (Nygard); optional prose tail permitted (ratification anchor / supersession pointer) | Leading-token rule (not a strict closed enum) — mirrors [`platform-doc-frontmatter-standard.md`](../standards/platform-doc-frontmatter-standard.md) §10 reversibility treatment; grounded in the ADR corpus (see §4). |
| `date` | ISO date | Yes | `YYYY-MM-DD` | Decision/authoring date. |
| `release` | string | Yes | release slug or version tag | The release the decision was rendered in. |
| `deciders` | string | Yes | free descriptive string | Who decided (operator + Stage 5 spoke + reviewers, in prose); NOT a closed enum — many observed forms. |
| `tags` | list[string] | Yes | free tags | Discovery tags. |
| `source_observations` | list[string] | Recommended | free prose entries | The grounding observations/evidence the decision rests on; may be long-form. |
| `supersedes` | string | Optional | `none`, or a comma-separated list of supersession entries per the §5 grammar | The **superseder** side of the supersession pair. Absent means the record supersedes nothing; `none` states the same thing explicitly. A superseded target that has no ADR record of its own is named in prose instead — the field is never forced to invent a target. |
| `superseded_by` | string | Optional | a comma-separated list of supersession entries per the §5 grammar, **every entry scoped `in-part`** | The **target** side of the supersession pair, and **partial supersessions only**. A whole supersession's reciprocal is the `status: Superseded by ADR-NNN` transition, not this field; a `whole`-scoped entry here is a conformance defect (§5). |

`supersedes` and `superseded_by` are a **documented inverse pair**: an entry on one side implies the matching entry on the other, per the §5 reciprocity rule. This adopts the inverse-pair convention already governed for operational artifacts by [`frontmatter-schema.md`](frontmatter-schema.md) § Lineage Fields rather than minting a second vocabulary; the populations stay disjoint per §7.

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

This doc documents only *how supersession is expressed*. The *supersede-not-edit / immutability rule itself* is owned by the ADR authoring guide — see §6.

Supersession has **two scopes**, and they are represented differently. The difference is not cosmetic: the `status:` leading token is a **permission state**, so the representation a partial edge uses determines whether its target remains editable and remains inside the durability lint's population.

### 5.1 Whole supersession

The superseded record is retired entirely. Representation is the Nygard transition the corpus already uses:

- `status:` begins with `Superseded` (optionally `Superseded by ADR-NNN …`);
- the `## Status` block cites the superseding ADR;
- `## Related ADRs` carries the link;
- the superseder carries `supersedes: ADR-NNN whole`.

Specimen: ADR-029 (`status: Superseded by ADR-045`). **The target does NOT carry a `superseded_by:` entry** — the `status:` transition is the reciprocal.

### 5.2 Partial supersession

A clause, rule, decision item, or substrate choice is superseded while the rest of the record still binds. Representation is the frontmatter inverse pair:

- the superseder carries `supersedes: ADR-NNN in-part (<scope label>)`;
- the target carries `superseded_by: ADR-MMM in-part (<scope label>)`;
- `## Related ADRs` carries the link on both sides.

**The target's `status:` leading token does NOT change.** It stays `Accepted`.

**Migration of the pre-carrier records.** Before this pair existed, a partial edge was written as body prose — most fully by ADR-078, which carries a `**Supersession — D4, partial.**` block naming ADR-130 as superseding decision item D4 only. **That body prose is correct and stays.** What such a record gains is the frontmatter half it never had: ADR-078 takes `superseded_by: ADR-130 in-part (D4)` and ADR-130 takes `supersedes: ADR-078 in-part (D4)`, while ADR-078's `status:` stays `Accepted` — it was never `Superseded`, and nothing about this migration changes that. The two records that instead improvised a **frontmatter `status:` prose tail** are migrated the other way: the tail moves into the field, and the status value returns to its bare leading token. Landing these edges across the corpus is a separate slice from defining the carrier; this section states the form they migrate INTO.

### 5.3 Entry grammar

```
<entry>        := ADR-NNN SP <scope> [ SP "(" <scope-label> ")" ] [ SP "—" SP <free rationale> ]
<scope>        := "whole" | "in-part"
<field-value>  := "none" | <entry> [ "," SP <entry> ]*
```

The parser reads the two leading tokens and the optional parenthesized label; free rationale after an em-dash is **preserved and ignored**, so the explanatory prose the corpus already writes survives verbatim.

```yaml
supersedes: ADR-029 whole
supersedes: ADR-012 in-part (location clause), ADR-017 in-part (roadmaps placement in the operator-instance path family)
supersedes: ADR-051 in-part (Decision 1) — the system-level canonical assignment; Decisions 2-5 stand
superseded_by: ADR-164 in-part (Decision 1)
```

Canonical parser symbol, defined here once and **cited** — never restated — by every consumer:

`SUPERSESSION_ENTRY_RE = ^ADR-(?P<n>\d{3})\s+(?P<scope>whole|in-part)(?:\s+\((?P<label>[^)]+)\))?`

A scope label names a **structural referent** — a decision item, a clause, a rule, a named section. It never carries a commit SHA or a count: those go stale against a record that is immutable by policy, and a durability check rejects them.

### 5.4 Two rules that hold without exception

1. **`superseded_by:` never carries `whole`.** A whole edge's reciprocal is the §5.1 `status:` transition. A `whole`-scoped `superseded_by:` entry is a conformance defect.
2. **A partial supersession never changes the target's `status:` leading token.** Flipping a partially-superseded record to `Superseded` asserts a retirement its own superseder denies, and — because the durability check derives its frozen-record exemption from that leading token — silently removes a still-binding record from the population that polices it.

### 5.5 Relation scope

These two fields carry **supersession only**. `amends-in-part` is supersession-in-part and uses the pair. *Qualifies*, *extends*, *composes* and *refines* are **not** carrier-eligible: a record that qualifies another without contradicting it has not superseded anything, and stating that relation in `## Related ADRs` prose is the correct representation.

### 5.6 Reciprocity

For every ADR **X** whose `supersedes:` names target **Y** with scope **S**:

- **S = `whole`** → Y's `status:` leading token is `Superseded` **and** Y's `status:` value cites `ADR-X`.
- **S = `in-part`** → Y carries a `superseded_by:` entry naming `ADR-X` with scope `in-part`.

And the converse: every `superseded_by:` entry on Y naming X requires a matching `supersedes:` entry on X.

**Declared exemption, never a silent skip.** An edge that cannot be landed carries `<!-- adr-supersession: reciprocity-exempt — <reason> -->` on the **superseder**, mirroring the existing declared-marker pattern. The check reports the exemption together with its reason; it never suppresses the count.

Reciprocity is enforced as rule **R6 RECIPROCITY** in [`check-adr-durability.py`](../../release/tools/check-adr-durability.py), delta-scoped on that tool's existing diff-base machinery and warn-mode at the existing CI surface.

## 6. Boundary — this schema vs the ADR authoring guide

This doc = the **data contract** (fields + sections + supersession representation). The ADR authoring guide = the **policy + ergonomics** (when-to-write rubric + non-triggers, the copy-paste template + worked example, the supersede-not-edit/immutability rule). The guide's template **references this schema** for the field list so the list has one source. [ASSUMPTION – CONFIRM at Collective Review: the authoring-guide milestone (`31-immutable-adr-system`) adopts this reference direction rather than re-inlining the fields.]

## 7. Relationship to platform-doc-frontmatter-standard.md

[`platform-doc-frontmatter-standard.md`](../standards/platform-doc-frontmatter-standard.md) governs authored K1 `core/**` docs and **explicitly excludes the ADR class from its field tables** (its §9 row + ADR-boundary note), deferring to this doc. This doc is that deferral's target. [`frontmatter-schema.md`](frontmatter-schema.md) governs a *third*, disjoint population (operational K4 project artifacts). The three do not overlap; an ADR obeys this doc.
