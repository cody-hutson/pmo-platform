---
title: Domain Best-Practice Guide — Data Architecture
purpose: A K1 universal reference carrying an Applicability Profile and indexing the authoritative best-practice sources for the data-architecture domain — modeling, mastering, lineage, data quality — for Stage-5 design and Stage-7 review consumption.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
domain: data
framework_version_anchor: "skill-surface-sync"
consumers: "release/references/pipeline/stage-05-solutioning.md §5.7 (domain-guide index, consulted when the deliverable's domain is data); the domain-best-practice review criterion (Stage-5/7); release/references/pipeline/stage-04-planning.md §5.7 (the domain: class field points here when domain==data); release/skills/pmo-architect (data dimension — modeling, mastering, storage-flow topology); release/skills/pmo-data-engineer (dimensional modeling, data-quality assertion design)"
frameworks_cited: "DAMA-DMBOK2 (2017); Kimball & Ross, The Data Warehouse Toolkit 3rd ed. (2013); DAMA UK Six Primary Dimensions of Data Quality (2013) — all registered in core/specs/framework-catalog.md"
---
<!-- reference-durability: allow-version-ref -->

# Domain Best-Practice Guide — Data Architecture

A domain best-practice guide is a K1 reference doc that carries an Applicability Profile and indexes the authoritative best-practice sources for one domain, for Stage-5/7 design consumption. This is the data guide — data-management scope and governance, mastering and lineage, dimensional modeling, and the data-quality dimensions an assertion set is written against. It is **not** new machinery: every structural property is borrowed from a shipped protocol — the Applicability Profile schema, the evidence-tier labels and source taxonomy, the framework catalog, and the K1 placement model. The guide cites authoritative sources (the sourcing input); a Stage-5/7 design or review consults the guide to check a data deliverable against current authoritative practice (the design-consumption content).

The data domain cites **external** data-management and modeling frameworks whose text lives outside the platform — the same posture the software, governance, and support guides take, and distinct from the process guide, whose rule bodies are already codified inside the platform. The guide therefore adds the design-consumption layer over those external sources and does not restate any framework body.

No ADR accompanies this guide: the decision is the one an existing ADR already governs — whether a domain earns a shared guide — and this domain clears its stated reversal trigger, since two peer designer surfaces consume it independently. The rationale is recorded inline here, exactly as the sibling guides record theirs.

**Altitude discipline (load-bearing, not stylistic).** This guide is written at **architecture** altitude and serves two readers without collapsing the boundary between them: the architect owns the topology, the mastering decision, and the data NFRs; the data engineer owns the build and the standing correctness of what runs. A concept here states what the *design* must decide and what a reviewer checks it for. It does not restate pipeline construction, orchestration mechanics, or operational runbook content — those sit below this altitude and belong to the engineering surface that owns them.

## Applicability Profile

The guide's spine is the platform's standard Applicability Profile schema. The Profile makes "does this guide apply to the deliverable in context C?" a decidable predicate, not interpretation.

```
Applicability Profile (for the data guide):
  UNIVERSALITY:          universal            # K1 — applies to any PMO-platform deployment; data-architecture best-practice is not org-specific
  APPLIES-WHEN:          deliverable domain == data   # the abstract domain signal from the domain_practice label's domain: field
  CONTRAINDICATED-WHEN:  CI-3 — enterprise-scale data-governance ceremony (formal stewardship councils, a full metadata-management program, a standing data-quality scorecard apparatus) is contraindicated for a single-store or single-operator deliverable where proportionate governance suffices
  EVIDENCE-TIER:         per-source (each concept carries its source's evidence tier at point of use; tiebreak input only)
  RESOLUTION-ON-CONFLICT: precedence ladder rung 2 (lex specialis) — a more-specific data practice beats a more-general one; equal specificity falls to rung 3 (evidence-tier tiebreak)
```

`UNIVERSALITY: universal` because a different organization running the platform would find this guide's content true and useful verbatim — a named owner per data asset, one system of record per entity, traceable lineage, a declared grain, and quality assertions mapped to named dimensions carry no operator-specific, project-specific, or single-reviewer assumption. The guide MUST NOT embed contextual literals (an operator name, a project name, a team-structure or single-operator-HITL assumption hardcoded as universal); the `CI-3` contraindication is exactly how context (the deliverable's scale) is consumed as a mediated input rather than baked in. The domain signal it is indexed by is the abstract `domain:` class, never a hard read of a project-specific field.

## Applicability rubric (per the platform applicability framework §5 — demonstrated in-doc)

```
### Applicability (per the applicability framework)
- **Universality:** universal
- **Applies when:** deliverable domain == data
- **Contraindicated when:** CI-3 (enterprise-scale data-governance ceremony on a single-store or single-operator deliverable where proportionate governance suffices)
- **On conflict:** precedence-ladder rung 2 (lex specialis); equal specificity → rung 3 (evidence-tier tiebreak)
- **Evidence tier:** per-source — see each concept's evidence label below
```

This is the data domain's fresh in-doc demonstration of the applicability rubric — a sixth instance alongside the software, governance, process, support, and security guides', disjoint from the platform's existing rubric demonstrations.

## Practice concepts × authoritative sources × design-consumption notes

Each concept names an evidence-tier-labeled authoritative source (the label applied at the point of use per the corpus-curation evidence-label discipline) and a design-consumption note (what a Stage-5/7 spoke checks a data deliverable against).

### Data-management scope and governance

**Source:** `[FRAMEWORK: DAMA-DMBOK2 2017]` (ET2 — the canonical data-management body of knowledge). DMBOK2 decomposes data management into a set of **knowledge areas** — governance, architecture, modeling and design, storage and operations, security, integration and interoperability, document and content, reference and master data, warehousing and business intelligence, metadata, and data quality — with **data governance at the hub**, coordinating the rest rather than sitting beside them. Its governing claim is that data management is a set of accountable functions, not a technology choice: an asset without a named accountable owner is unmanaged regardless of the platform it sits on.

**Design-consumption note:** a data deliverable is checked for (a) a named accountable owner per managed data asset — a role or function, not merely a system; (b) governance weight proportionate to scale (`CI-3`) — a stewardship council on a single-operator store is the tailoring failure, and the inverse of the contraindication; (c) the knowledge areas the design does *not* address named rather than silently omitted, so a deliberate scope boundary is distinguishable from an oversight.

### Mastering and lineage

**Source:** `[FRAMEWORK: DAMA-DMBOK2 2017]` (ET2), specifically its Reference & Master Data Management and Metadata Management knowledge areas. Master data management holds that for each core entity there is exactly **one authoritative system of record**, with other stores holding derived or replicated copies whose derivation is explicit; two stores both claiming to master one entity is not a redundancy but a defect, because there is then no rule that decides which is right. Metadata management supplies the complementary property — **lineage**: the traceable path from a consumed value back through its transformations to its origin, maintained as a design property rather than reconstructed forensically after a discrepancy.

**Design-consumption note:** a data deliverable is checked for (a) exactly one system of record per entity, named — two stores both claiming to master one entity is a defect to resolve at design time, not a reconciliation job to schedule; (b) lineage as a *design property*, traceable from consumption back to origin, rather than an after-the-fact investigation; (c) reference data distinguished from master data, since the two have different change cadences, different owners, and different blast radii when they drift.

### Grain-first dimensional modeling

**Source:** `[FRAMEWORK: Kimball & Ross, The Data Warehouse Toolkit 3rd ed. 2013]` (ET2 — the canonical dimensional-modeling reference). The method's first and least-negotiable step is to **declare the grain**: the precise meaning of a single fact-table row, fixed before any dimension is attached, because every subsequent decision about which dimensions apply and which measures are additive depends on it. It pairs this with **conformed dimensions** — a dimension defined once and shared across fact tables so that measures from different processes can be compared along the same axis — and with an explicit **slowly-changing-dimension** strategy for attributes whose values change over time, since the choice between overwriting history and preserving it is a modeling decision with query consequences, not an implementation detail.

**Design-consumption note:** a data deliverable is checked for (a) each fact table's grain declared **before** any dimension is attached, and stated in one sentence a reviewer can test a row against; (b) dimensions conformed across facts rather than duplicated per-fact, so cross-process comparison is possible by construction; (c) an explicit slowly-changing-dimension strategy wherever an attribute can change, with the history-preservation choice stated rather than defaulted.

### Data-quality dimensions

**Source:** `[CONSENSUS: DAMA UK — Six Primary Dimensions of Data Quality (2013)]` (ET3 — broadly-adopted practitioner consensus; admitted with the mandatory paired applicability note below). The six dimensions are **completeness** (is the expected data present), **validity** (does it conform to its defined syntax and domain), **uniqueness** (is anything recorded twice that should be recorded once), **timeliness** (does it represent reality at the required point in time), **consistency** (do representations agree across stores), and **accuracy** (does it correctly describe the real-world object). Their contribution is a shared vocabulary: an assertion mapped to a named dimension is checkable and comparable across datasets, where an ad-hoc assertion is neither.

**Mandatory paired applicability note (per the ET3 consensus rule — consensus is not universal fit):** these six are a broadly-adopted practitioner **consensus** taxonomy, **not** an exhaustive or empirically-derived one; other credible enumerations differ in both count and boundary. The set fits assertion design for a **curated dataset with real consumers**, and is **over-structure for a single ad-hoc extract** where one or two dimensions carry the whole risk. Apply the subset the asset's consumers actually depend on, and say which subset that is; do not assert all six by reflex, and do not treat the list as closed.

**Design-consumption note:** a data deliverable is checked for (a) each quality assertion mapped to a named dimension rather than written ad-hoc, so the assertion set is reviewable as a set; (b) the dimensions consciously *not* asserted named, so an unchecked dimension is a stated acceptance rather than an oversight; (c) NOT all six asserted by reflex on a low-stakes extract — proportionality is the applicability note's whole point.

## Sourcing vs design-consumption (the distinction this guide preserves)

This guide is **design-consumption content** — it tells a Stage-5/7 spoke what to check a data deliverable against. It is distinct from the platform's source taxonomy, which is the **sourcing input** (which authoritative source to cite per domain). The guide *cites* the data-management and modeling sources; the taxonomy does not carry an Applicability Profile and does not tell a design what to check. Different objects, clean seam: do not collapse the guide into the source taxonomy or vice versa.

As with the security guide, the corpus-curation source taxonomy carries no data row and is self-declared non-exhaustive; this guide's sources are registered in `core/specs/framework-catalog.md`, which is the governed registry a newly referenced framework enters the platform through. The absence of a taxonomy row is not a missing registration.

## The universal/contextual seam (forward-compat)

This guide is the **universal** (K1) instance of an Applicability-Profile-bearing unit. The identical Profile shape serves a future user-onboarded contextual knowledge base — same schema, but with `UNIVERSALITY: contextual` and a narrower context predicate (an organization's own entity catalogue, its master-data ownership map, its retention obligations), placed in the operator-instance layer rather than the platform corpus. Authoring this guide to the standard Profile schema **is** what lets a later onboarding capability plug in by emitting the same shape — reusing the existing schema, inventing nothing. A future contextual KB that needed a *different* Profile shape would signal this seam was mis-designed; conformance to the standard schema is therefore load-bearing, not cosmetic.

## Cutover

This guide applies to releases entering Stage 5/7 strictly AFTER the introducing-release merge SHA recorded in the release log. **The introducing release itself is exempt** — a guide shipping in a release cannot retroactively bind its own design/review work, which ran before the guide existed. All releases that entered Stage 5/7 prior to the introducing release are exempt. This matches the introducing-release-exempt reflexive-pipeline discipline the design-exploration protocol, the cascade-completeness sweep, and the framework-corpus discipline carry.
