---
title: Universal vs. Release-Pipeline Split Rule (core/ vs release/references/)
purpose: Per-file placement rule for the new pmo-platform tree (post-reorg modular monolith). Codifies the 3-step decision tree for assigning standards / specs / protocols / templates to `core/<kind>/` (UNIVERSAL-PLATFORM-KNOWLEDGE) or `release/references/<kind>/` (RELEASE-PIPELINE-SPECIFIC). Composes with — does not restate — `public-repo-vs-operator-instance-taxonomy.md` (universal-vs-localized content classification; this rule operates ABOVE that classification — both UNIVERSAL-PUBLIC and CUSTOMIZABLE-PUBLIC cells can live in either core/ or release/references/ depending on the consumer-surface test below).
type: standards
source: Stage 5 Solutioning sub-task; ratified at Collective Review
composes_with:
  - public-repo-vs-operator-instance-taxonomy.md
  - knowledge-architecture.md
  - duplicate-source-discipline.md
applies_to: All files authored at or migrated to the new pmo-platform tree from the reorg forward
reversibility: CHEAP / Confidence HIGH
version:
consumers:
  - reorg dispositions
  - future-release Stage 5 spokes selecting placement for new K1 docs
---

# Universal vs. Release-Pipeline Split Rule

## §1 Purpose

After the modular-monolith reorg, the new pmo-platform tree has TWO surfaces for codified-knowledge:

- `core/<kind>/` — universal-platform-knowledge consumed by skills / agents / all pmo-platform deployments regardless of whether they operate the 13-stage release pipeline.
- `release/references/<kind>/` — release-pipeline-specific knowledge consumed by the 13-stage pipeline and the release-class skills (`release-planner`, `release-executor`, `pmo-qa-auditor`).

This rule defines WHICH side a file belongs on. It composes with (does NOT restate) `public-repo-vs-operator-instance-taxonomy.md` and `knowledge-architecture.md` (K1-K5 tiers). Both axes — universal-vs-operator AND core-vs-release — apply to every file independently.

## §2 The 3-Step Decision Tree

Apply per file. First match wins.

### Q1 — Release-pipeline consumer surface (binary)

Does the file's body name AS PRIMARY consumers (per the "Primary consumer" or "Primary consumers" header line, or per the file's clearly load-bearing consumer surface) ≥1 of the following?

- `release/governance/release-process.md`
- `release/references/pipeline/stage-*.md` (any per-stage shard)
- `release-planner` / `release-executor` / `pmo-qa-auditor` (release-class skills)
- Release-class taxonomy entries (per `release/references/specs/release-class-taxonomy.md`)
- Release Outcome Statement / RELEASE_LOG / RELEASE_INDEX / RELEASE_DIGEST / RELEASE_NOTES / CHANGELOG schema entries (the ref-permitted ledger surfaces — see §8)
- Stage 5 / 9 / 12 / 13 gate criteria (per `core/schemas/gate-criteria-spec.md` G3/G5/G9/G12/G13)
- Stage 3 Bundle / Stage 4 Planning / Stage 5 Solutioning / Stage 6 Engineering / Stage 7 Dev Testing / Stage 8 QA / Stage 9 Plan Review / Stage 12 Execute / Stage 13 Close as PRIMARY operational surface

```
Q1 outcome:
  YES → release/references/<kind>/ [STOP]
  NO  → continue to Q2
```

**Disambiguation:** Q1 binds on **PRIMARY** consumers (the file's load-bearing consumer surface), not on incidental cross-references. A universal-platform-knowledge document MAY cite the release pipeline in its evidence/rationale without becoming release-pipeline-specific. Verify Q1 by reading the file's primary-consumer header line (when present) and the file's "Consumers" section (when present).

### Q2 — Universal-platform-knowledge test

Does the file codify universal-platform-knowledge consumed by skills, agents, OR all pmo-platform deployments regardless of release-pipeline operation?

Examples of YES: `failure-mode-standard.md` (every skill consumes), `reversibility-protocol.md` (every decision consumes), `evidence-grounding-standard.md` (every Stage 5 spoke consumes — but ALSO universal R1 discipline beyond Stage 5).

```
Q2 outcome:
  YES → core/<kind>/ [STOP]
  NO  → continue to Q3
```

### Q3 — Ambiguity tie-breaker (primary consumer test)

When the file is ambiguous between universal AND release-pipeline scopes, apply "primary consumer" test — where is the file's content load-bearing FIRST?

```
Q3 outcome:
  Release-pipeline consumer dominates  → release/references/<kind>/ [STOP]
  Universal consumer dominates         → core/<kind>/ [STOP]
  TIE                                  → core/<kind>/ (default per §4 Q3 default — universal home)
```

## §3 The kind values

For each side, the same kind taxonomy applies:

| Kind | Definition |
|---|---|
| `standards` | Standardized normative rules (frontmatter, gate criteria, schema standards) |
| `specs` | Specifications (taxonomies, frameworks, definitions) |
| `protocols` | Procedural how-to documents (governance procedures) |
| `templates` | Reusable templates (artifact templates, output templates) |
| `schemas` | Machine-readable schemas (JSON Schema, etc.) — `core/` only by convention; release-pipeline schemas live under `core/schemas/` if universal |
| `disciplines` | Understanding-and-rationale documents (rationale, models, frameworks) — `core/` only |

## §4 Promote-on-Demand Rule (for new kinds)

When a new `<kind>/` subdirectory candidate emerges (e.g., a new file class that doesn't fit existing kinds), introduce the directory ONLY when ≥2 universal residents exist. This prevents speculative directories that become drift surfaces.

Current state (2026-05-28):
- `core/protocols/` — DOES NOT EXIST; 0 universal residents (6 in `release/references/protocols/` all release-pipeline-scoped per per-file body grep: blast-radius-protocol / fission-convention / improvement-review-process / mixed-release-solutioning-routing / subsumption-convention / version-management-protocol)
- `core/templates/` — DOES NOT EXIST; 0 universal residents (1 in `release/references/templates/` — `design-review-checklist.md` — is release-pipeline-scoped; 12+ in `operations/templates/` are operations-class CUSTOMIZABLE-PUBLIC per the taxonomy cell (2))

When ≥2 universal protocols emerge: introduce `core/protocols/`. When ≥2 universal templates emerge (i.e., cross-skill or cross-deployment): introduce `core/templates/`. Until then, the directories DO NOT exist.

## §5 Verification + known divergences (full-population audit per CD-1)

### Sample-13 verification (per Stage 5 spec)

13 of 13 spec-sampled files (8 from `core/standards/`, 5 from `release/references/standards/`) verified CORRECTLY placed per the rule:

| Sample | Side | Verification |
|---|---|---|
| `evidence-grounding-standard.md` | core/ | "Universal codification of canonicalization-evidence discipline" — universal. CORRECT. |
| `depersonalization-spec.md` | core/ | Substitution vocabulary for public-flip; universal across operator deployments. CORRECT. |
| `upstream-reference-catalog.md` | core/ | Anthropic upstream API catalog; universal-knowledge. CORRECT. |
| `universal-vs-localized-context.md` | core/ | DC1-DC6 framework for content/localization classification; universal. CORRECT. |
| `decision-outcome-tracking.md` | release/ | Stage 13 chore PR consumer; 4-value enum (SUCCESS/PARTIAL/ROLLBACK/DEFERRED). CORRECT. |
| `pipeline-event-log-schema.md` | release/ | Schema for `pipeline-event-log.md` release artifact. CORRECT. |
| `release-corpus-schema.md` | release/ | RELEASE_INDEX + RELEASE_DIGEST + RELEASE_LOG + release-notes schemas. CORRECT. |
| `triage-design-rereview.md` | release/ | Stage 4 + Stage 5 entry re-review protocol. CORRECT. |
| `failure-mode-standard.md` | core/specs/ | 5-field template + 5-category tag for SKILL.md domain-specific failure modes; universal. CORRECT. |
| `autonomy-tiers.md` | core/specs/ | 4-tier classification for ALL agent actions; universal. CORRECT. |
| `reversibility-protocol.md` | core/specs/ | Universal CHEAP/MODERATE/EXPENSIVE/IRREVERSIBLE tier framework. CORRECT. |
| `release-class-taxonomy.md` | release/specs/ | Release-pipeline-only classification. CORRECT. |
| `methodology-archetype-matrix.md` | release/specs/ | Consumed by release-planner skill. CORRECT. |

### Full-population Q1-grep audit (per CD-1 absorption)

Per the adversarial-review CD-1 Counter-Design absorption, Stage 6 executed full Q1-grep across all 64 substantive files at the standards+specs axis (33 at `core/standards/` + 11 at `release/references/standards/` + 11 at `core/specs/` + 9 at `release/references/specs/`). Per-hit confirmation surfaced known divergences below.

### Known divergences (verified misplacements; file moves DEFERRED to follow-up issue)

Two files at `core/standards/` would route to `release/references/standards/` of the rule above. Per scope-guardrail discipline ( scope is structural-integrity review, not corpus-wide reorganization), file moves are DEFERRED:

| File | Current path | Q1 evidence | Q1 verdict | Routing |
|---|---|---|---|---|
| `per-stage-shard-standard.md` | `core/standards/` | **Primary consumers (verbatim from L4):** "Stage 5 Solutioning spokes (when authoring or materially modifying a per-stage shard); Stage 6 Engineering spokes (when implementing shard edits); `release-planner` Mode B (when planning shard-touching releases); `build-reviewer` (when auditing pipeline-corpus structural integrity); future Stage 14+ authors." | Q1=YES (Stage 5/6 + `release-planner` + `build-reviewer` are all release-pipeline consumers) | **Belongs `release/references/standards/`** |
| `planning-solutioning-handoff.md` | `core/standards/` | **Primary consumer (verbatim from L4):** "Stage 4 Planning spokes (per `pipeline/stage-04-planning.md` § 5 Phase B Handoff)." Secondary: Stage 5 Solutioning spokes + `release-planner` Mode B. | Q1=YES (Stage 4 Planning is a release-pipeline stage) | **Belongs `release/references/standards/`** |

**Ambiguous case (catalogued as YES-Q2 universal, retained at core/):**

| File | Current path | Disambiguation |
|---|---|---|
| `framework-corpus-discipline.md` | `core/standards/` | "Owner: Platform engineering — release-ops domain. Enforcement: deploy.sh --check Check 18." Q1 borderline (deploy.sh is universal-tooling, not release-pipeline-only). Q2 universal-platform-knowledge test: catalog/anchor convention IS universal-platform-knowledge consumed by every framework author. **Retain at core/standards/.** |

**Disposition decision:** Two verified misplacements (per-stage-shard-standard.md + planning-solutioning-handoff.md) are catalogued here as "known divergences" rather than file-moved in this release. Rationale: Stage 5 spec scope-cleavage (S2) recommendation EXPLICITLY excluded full corpus reorganization; the K1 standard ratifies the rule and acknowledges these two empirically-verified gaps. Follow-up issue authoring + file-move execution scheduled for a future release per operator routing decision.

## §6 Composition with sibling standards

| Sibling | Composition |
|---|---|
| `public-repo-vs-operator-instance-taxonomy.md` | Orthogonal — this rule operates on the SUBDIRECTORY-PLACEMENT axis; the taxonomy operates on the CONTENT-NATURE axis. Both apply to every file. |
| `knowledge-architecture.md` | This rule is the subdirectory-placement instance of the K1↔K2/K3 boundary at the new modular-monolith tree. |
| `duplicate-source-discipline.md` | Promote-on-demand rule honors register-or-remove discipline. |

## §7 Cutover

Applies to files authored at or migrated to the new pmo-platform tree from the reorg forward. Pre-reorg placements are grandfathered per the reorg state (post-curation). Subsequent cleanups (per the full-population audit) align grandfathered placements with this rule where divergence surfaces; the two known divergences at §5 above are documented for follow-up file moves.

## §8 Ref-Permitted Ledger Surfaces (the queryable enforcement input)

The split rule routes a release-tracking ledger surface to the release side (Q1). A distinct property of those same surfaces is that they are **ref-permitted**: milestone and issue references, pull-request URLs, and merge SHAs are native provenance on a ledger and are NOT fragile-reference violations there. Every OTHER tracked file is ref-prohibited and must be self-contained per the reference-durability standard. This section is the single queryable enumeration of the five ref-permitted surfaces — the authoring lookup for "where may a release reference live?" and the named input the enforcement primitives realize. There is no second list: the reference-durability allowlist and the repository-integrity gate exemptions implement the table below; they do not define a parallel one.

| # | Ledger surface | Canonical path | Ref-permission realized by (enforcement exemption) |
|---|---|---|---|
| 1 | RELEASE_LOG | `release/releases/RELEASE_LOG.md` | The `release/releases/*` exemption carried by the repository-integrity issue-reference and depersonalization gates; outside the reference-durability durable-corpus scope (not under a `core/` / `release/references/` durable glob). |
| 2 | RELEASE_INDEX | `release/releases/RELEASE_INDEX.md` | Same `release/releases/*` exemption. |
| 3 | RELEASE_DIGEST | `release/releases/RELEASE_DIGEST.md` | Same `release/releases/*` exemption. |
| 4 | RELEASE_NOTES | `release/releases/notes/*.md` | Same `release/releases/*` exemption. |
| 5 | CHANGELOG | `CHANGELOG.md` (repository top level) | The Class-U `is_ledger_exempt` case (top-level `CHANGELOG.md`). CHANGELOG is top-level, so it is already outside both the durable-corpus scan scope and the `release/releases/*` exemption; the explicit ledger-exempt case names it as a categorical ref-permitted surface rather than a per-file escape, keeping the seam closed by construction. |

A reference that belongs on one of these surfaces is authored there directly. A reference that surfaces in any other tracked file is a self-containment violation: rewrite it as an inline summary at the durable rung, per the reference-durability standard.

## §9 See also

- [`public-repo-vs-operator-instance-taxonomy.md`](public-repo-vs-operator-instance-taxonomy.md) — orthogonal content-nature axis (UNIVERSAL-PUBLIC / CUSTOMIZABLE-PUBLIC / OPERATOR-INSTANCE)
- `knowledge-architecture.md` — K1-K5 tier taxonomy + parameterization seam (at `core/disciplines/knowledge-architecture.md`)
- `duplicate-source-discipline.md` — composition rule (sibling at `core/standards/duplicate-source-discipline.md`)
