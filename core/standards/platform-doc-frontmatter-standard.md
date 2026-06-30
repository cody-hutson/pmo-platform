---
title: Platform-Doc Frontmatter Standard
purpose: Required + optional frontmatter fields per platform-doc class for authored K1 docs under core/**
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: "Tier A backfill (governance-class dirs), the CI frontmatter gate, Tier B/C backfill (remaining core docs + ADR sub-case), and check-version-anchors.py (the framework_version_anchor seam) — issue refs in the References block"
composes_with: framework-catalog.md, knowledge-architecture.md, evidence-grounding-standard.md
parallel_to: frontmatter-schema.md (disjoint K4 operational-artifact population)
tags: [frontmatter, corpus-hygiene, knowledge-corpus, standard]
---
<!-- reference-durability: allow-link -->

# Platform-Doc Frontmatter Standard

## 1. Purpose + scope

This standard defines the YAML frontmatter that authored **K1 platform-reference docs under `core/**`** must carry: standards, schemas, specs, disciplines, rules, protocols, how-tos, templates, and references. K1 is the universal, transferable, enforcement-carrying knowledge tier — the `core/` tree is the K1 set per the knowledge-architecture model. These docs are version-anchored, cross-project, and durable; a uniform frontmatter contract makes them discoverable, lets tooling parse their version anchors, and makes the blast radius of a change to any one of them explicit.

The standard fixes three things: (1) the **REQUIRED core field-set** every in-scope doc carries; (2) the **REQUIRED-by-class** fields a doc carries because of what class it is; and (3) the **RECOMMENDED** and **explicitly-excluded** fields, so an author knows both what to add and what not to add. The field-set is **emergent and seam-grounded** — it is the set the corpus already converged on, not a theoretical superset (see §3 and §8).

This standard **defines** the contract; it does not itself backfill files or wire the enforcement gate. Those are its downstream children (§11). The standard's own frontmatter conforms to the standard it defines (it is a `type: standard` doc — see the block at the top of this file).

## 2. Scope vs `frontmatter-schema.md`

**Scope vs `frontmatter-schema.md`.** This standard governs **authored K1 platform-reference docs under `core/**`** (standards, schemas, specs, disciplines, rules, protocols, how-tos, templates, references) — the version-anchored, universal corpus (K1 per the knowledge-architecture model: `core/` is the K1 set). `core/schemas/frontmatter-schema.md` governs a **disjoint** population: **operational K4 artifacts under a project's `01-08/` folders** — project-specific, fast-mutating instance state (K4 lives only in the operations layer, never in the platform corpus). The two have **disjoint populations** (`core/**` repo docs vs project operational files), **disjoint field sets** (this standard's `purpose` / `type` / `consumers` / `reversibility` vs frontmatter-schema's `managed_by` / `domain` / `trust_category` / `lifecycle_state`), and **disjoint lineage** (the corpus-hygiene epic vs the project-data-architecture epic). Neither redefines the other; a doc obeys exactly one.

The two even share the field NAME `type` with **disjoint enums** — this standard's `type` enumerates document classes (`standard` / `schema` / `spec` / …); frontmatter-schema's `type` enumerates operational artifact kinds (`transcript` / `fdd` / `decision-package` / …). The disjoint-population guard is what keeps that from being a conflict: a file is in exactly one population, so exactly one `type` enum applies to it.

## 3. Design rationale — one unified standard, not a dialect registry

The meta-decision — a single unified standard with per-class field extensions, **NOT** a dialect registry indexing many per-class schemas — is settled upstream (resolved in the frontmatter-standardization runbook work; see the References block). This standard records the rationale rather than re-deciding it, and keeps the record as a slim section, **not a standalone ADR**: the decision is non-obvious enough to record but was already made upstream, so it fails the "author an ADR only when the decision is non-obvious *and unmade*" test.

- **Why unified, not registry.** A registry (file-class → which-of-N-schemas) optimizes for *divergent* dialects. The `core/` corpus does not diverge: it already converges on one core field-set (`title` / `purpose` / `type` / `status` / `reversibility` dominate every class). Per-class variation is **additive** — a class *adds* REQUIRED-by-class fields — not **substitutive** — a class never *swaps out* the core set. That is an extension model, not a dialect model. A single lookup answers "what must this doc carry?" by reading one table (§6 / §9) indexed on the doc's class.
- **Scope guard.** This standard governs authored K1 repo docs under `core/**` only. It does **not** absorb the other frontmatter dialects in the platform: SKILL.md frontmatter is owned by the skill-structure conventions; release plans and notes are owned by the release-corpus schema; project operational artifacts are owned by `frontmatter-schema.md`; the ADR class is owned by the ADR README convention. This standard cites those as siblings; it does not restate them.

## 4. Core REQUIRED field table

Every in-scope doc carries these five fields. They are the five highest-frequency fields actually in use across the frontmatter-bearing `core/` corpus — the REQUIRED set by frequency dominance, not by theory.

| Field | Type | Rule |
|---|---|---|
| `title` | string | Human-readable title of the doc. |
| `purpose` | string | One line stating why this doc exists — the "what does this give the reader" sentence. |
| `type` | enum (§5) | The doc's class — a canonical singular value from the §5 enum. |
| `status` | enum | Lifecycle state, one of `ACTIVE` \| `DRAFT` \| `DEPRECATED` \| `SUPERSEDED`. |
| `reversibility` | tier-prefixed string | A reversibility tier + confidence marker per the convention in §10. |

## 5. The `type` canonical enum

`type` is a **singular, lowercase, hyphenated-where-compound** enum. The singular form is canonical — this resolves the observed `standard` (singular) vs `standards` (plural) drift in favor of the singular, which is both the plurality form in the corpus and the grammatically-correct "this doc IS a `standard`" reading. Normalizing existing plural values is the backfill's job; this standard *defines* the singular form.

| `type` value | Doc class | Home dir (typical) |
|---|---|---|
| `standard` | standard | `core/standards/` |
| `schema` | schema | `core/schemas/` |
| `spec` | spec | `core/specs/` |
| `discipline` | discipline | `core/disciplines/` |
| `rule` | rule | `core/rules/` |
| `protocol` | protocol | (various) |
| `how-to` | how-to | (various) |
| `template` | template | (various) |
| `reference` | reference | `core/disciplines/`, `core/specs/` |

The enum is **closed** for the ten platform-doc classes this standard governs (the nine above plus the ADR class, which defers — see §9). Values outside this set that appear on skill-adjacent docs (for example `rubric` or `note` under `core/skills/`) are out of scope for this standard: those are skill-adjacent docs, not standalone K1 platform-reference docs. If they warrant frontmatter typing, that is the Tier B/C backfill's scope.

## 6. REQUIRED-by-class table

These fields are REQUIRED, but only for the classes named — they are carried because of what the doc *is* and what depends on it.

| Field | Required for class(es) | Seam / grounding |
|---|---|---|
| `framework_version_anchor` | any class whose doc is **cataloged in `framework-catalog.md`** (the catalog's `canonical_doc` column names it) | **Hard tooling seam** — `check-version-anchors.py` parses this field; a cataloged doc that lacks frontmatter is currently SKIPped by that check, which is exactly the enforcement gap this REQUIRED-by-class rule (with the backfill + gate) closes. |
| `consumers` | `standard`, `schema`, `spec` | **Blast-radius seam** — the downstream-impact surface a change to this doc must check. A governance seam (the change-impact set), made explicit so a future change can read its own blast radius. |

`framework_version_anchor` is grounded in a **parsing consumer** (the version-anchor check reads the key). `consumers` is required on **documentation + governance grounds** (human discoverability of the blast radius), not because a tool parses it today — its enforcement is the CI frontmatter gate as authored, not a pre-existing tool. Both are concentrated in exactly the classes named: `consumers` clusters on the standard / schema / spec / discipline docs, and `framework_version_anchor` appears only on cataloged docs.

## 7. RECOMMENDED fields

Present-but-not-required on any class. Each is real in the corpus but none is universal, so RECOMMENDED is the correct tier — add it when it carries meaning, omit it otherwise.

| Field | Meaning |
|---|---|
| `composes_with` | Sibling docs this one composes with (named, not linked). |
| `parallel_to` | A sibling doc that governs a parallel-but-disjoint population or concern. |
| `domain` | The domain the doc belongs to (e.g. `governance`). |
| `tags` | A list of free tags for discovery. |
| `source` | Provenance of the doc's content. |
| `version` | A doc-local version string, where the doc carries its own. |

## 8. EXCLUDE from REQUIRED

These fields are **named and excluded** from the required set. All six are absent from the `core/` frontmatter corpus (zero occurrences each) — the strongest possible grounding for not requiring them — and each carries an additional reason not to mandate it.

| Field | Why excluded |
|---|---|
| `altitude` | Not in corpus use (0 occurrences). |
| `diataxis_quadrant` | Not in corpus use (0); mandating it would contradict the Diátaxis framework doc's explicitly non-binding stance. |
| `lifecycle_pattern` | Not in corpus use (0). |
| `review_cadence` | Not in corpus use (0); review cadence is already homed in `framework-catalog.md` — requiring it here is duplicate-source risk. |
| `last_reviewed` | Not in corpus use (0); same home as `review_cadence` (`framework-catalog.md`) — duplicate-source risk. |
| `sunset_criteria` | Not in corpus use (0); sunset criteria are homed in the knowledge-management protocols — duplicate-source risk. |

Excluding these keeps the contract grounded in the convention the corpus actually carries and avoids the duplicate-source defect of re-homing fields that already live elsewhere.

## 9. Per-class matrix

The REQUIRED core (all five §4 fields) applies to **every** row. This matrix shows the *delta* per class — the REQUIRED-by-class additions and the fields a class typically carries from the RECOMMENDED set.

| Class | + REQUIRED-by-class | Typical RECOMMENDED | Home dir |
|---|---|---|---|
| `standard` | `consumers`; `framework_version_anchor` if cataloged | `composes_with`, `parallel_to`, `version`, `tags`, `source` | `core/standards/` |
| `schema` | `consumers`; `framework_version_anchor` if cataloged | `version`, `composes_with`, `tags` | `core/schemas/` |
| `spec` | `consumers`; `framework_version_anchor` if cataloged | `composes_with`, `parallel_to`, `tags` | `core/specs/` |
| `discipline` | `framework_version_anchor` if cataloged | `composes_with`, `parallel_to`, `domain`, `tags` | `core/disciplines/` |
| `rule` | — | `parallel_to`, `tags`, `source` | `core/rules/` |
| `protocol` | — | `composes_with`, `version`, `tags` | (various) |
| `how-to` | — | `domain`, `tags`, `source` | (various) |
| `template` | — | `version`, `tags` | (various) |
| `reference` | — | `domain`, `tags`, `source` | `core/disciplines/`, `core/specs/` |
| `ADR` | **DEFERS to the ADR README convention** — NOT defined here | (the ADR README / ADR-schema work owns it) | `core/ADRs/`, `release/ADRs/` |

**ADR boundary (explicit).** The ADR class is **out of scope for this standard's field tables**. Its frontmatter contract (`title` / `status` / `date` / `release` / `deciders` / `tags` / `source_observations`) lives in the ADR README's format section and is being canonicalized into a dedicated ADR-schema doc (see the References block). This standard **names the deferral**; it does not define ADR fields, which would duplicate that work.

## 10. `reversibility` value convention

`reversibility` is carried as a **tier-prefixed string**, not a strict closed enum. The corpus carries it as free prose, overwhelmingly in the form `CHEAP / Confidence HIGH` with occasional longer tails such as `MODERATE (… rationale …) / Confidence HIGH`. Imposing a strict closed enum would invalidate every existing prose value and create a spec-vs-reality defect.

The convention the standard fixes: the value MUST **begin** with one of the four reversibility tiers — `CHEAP` \| `MODERATE` \| `EXPENSIVE` \| `IRREVERSIBLE` — followed by a confidence marker (e.g. `Confidence HIGH`), with an optional prose tail. This is emergent-grounded (it matches the dominant form already in use) and parseable enough for a future lint, without breaking the docs that already carry it.

## 11. Downstream children

This standard is the **frontmatter sub-parent**: it owns only the standard. Three downstream children consume its field-set and carry the corpus from "defined" to "backfilled and gated." Each child is marked closed at its *own* close-out, not by the card that authored this standard. The issue numbers are recorded in the References block below; the children are named here descriptively so the sequence reads without the numbers.

| Child | Role | Consumes from this standard |
|---|---|---|
| **Tier A backfill** | Apply the field-set to the governance-class dirs (`core/standards/`, `core/schemas/`, `core/disciplines/`, `core/rules/`, `core/specs/`, `core/governance/`); normalize plural `standards` → singular `standard`. | The full per-class field-set; the canonical `type` enum. |
| **CI frontmatter gate** | A `deploy.sh --check` gate that reports non-compliant frontmatter. Ships warn-mode across `core/`; the enforce-flip mechanism is built but graduation is deferred to the Tier B/C card. | The REQUIRED + REQUIRED-by-class field-set as the gate predicate; stays consistent with the version-anchor check on `framework_version_anchor`. |
| **Tier B/C backfill** | The remaining non-governance-class `core/` docs plus the ADR sub-case; also carries the gate's flip-to-global-enforce. Deferred. | The same field-set, broader population. |

The sequence is strict: the standard is authored first, the Tier A backfill applies it, the gate makes residual/new gaps visible, and the Tier B/C backfill (with the enforce-flip) finishes the population.

## References

References #295 — the card that authors this standard (the frontmatter sub-parent); ships only the standard.
References #109 — Tier A backfill: applies this standard's field-set to the governance-class dirs and normalizes the `standards` → `standard` drift.
References #2220 — the CI frontmatter gate: ships warn-mode across `core/` with the enforce-flip mechanism built but deferred.
References #2221 — Tier B/C backfill plus the gate's flip-to-global-enforce; deferred.
References #67 — the frontmatter-standardization runbook work whose unify-vs-registry resolution (one unified standard with per-class extensions, NOT a dialect registry) §3 records.
References #2156 — the ADR canonical-frontmatter-schema work that the ADR class (§9) defers to.
