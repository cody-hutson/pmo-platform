---
title: Corpus Curation & Epistemology
purpose: 5-tier evidence rubric (ET1–ET5) + the orthogonality axiom (evidence strength ⊥ universality) + the 6-step curation protocol + a 6-domain authoritative-source taxonomy + the methodological-claim evidence-label extension for the PMO platform K1 corpus
type: reference
status: ACTIVE
source: ""
reversibility: CHEAP / Confidence HIGH
adr: ""
consumers: "km-protocols.md (hard D-Struct cross-ref consumer of #evidence-tier-vocabulary); framework-catalog.md (soft forward-compat optional evidence_tier column); applicability-framework.md (evidence ⊥ applicability boundary consumer)"
glossary_anchor: " umbrella body Glossary (\"Evidence-based practice\" / \"Codified knowledge\" — grounds the ET rubric + D5 source-taxonomy row)"
---
<!-- reference-durability: allow-link -->

# Corpus Curation & Epistemology

This document is the platform's standard for **what qualifies for the K1 corpus** — the evidence a methodological practice must present, how a candidate is curated in, and the named authoritative sources preferred per domain. It composes with — and does **not** restate — [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) (which defines *whose context* a practice applies to via the universality axis) and the [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) Evidence-quality-labels guardrail (which labels *project* claims; this doc extends the discipline to *methodological* claims). Its five contributions are: (1) the 5-tier evidence rubric **ET1–ET5** with per-tier acceptance thresholds; (2) the **orthogonality axiom** — evidence strength is independent of universality, and the corpus is gated on *both*; (3) the 6-step **curation protocol** (intake → review → approve → version-anchor → publish → retire) with owner + gate + cross-ref per step; (4) a 6-domain **source taxonomy** of named authoritative sources; (5) the **evidence-label extension** for methodological claims.

Scope is **K1 only**. "Corpus" = the K1 Codified set per [`knowledge-architecture.md#k1-codified`](../disciplines/knowledge-architecture.md#k1-codified) (the umbrella Glossary "Corpus" term). Contextual K2–K5 knowledge is **not corpus** — it routes to its placement home and is never curated here (see [§5 Boundaries](#boundaries)).

---

## §1 Evidence Tiers {#evidence-tiers}

Five tiers, ordered by epistemic strength, locked to the source issue-body enumeration ("systematic review / peer-reviewed body / practitioner consensus / emergent pattern / expert opinion"). The **acceptance threshold** is the *minimum evidence a candidate must present to be admitted at that tier*; approver and review intensity scale inversely with tier strength. This table plus the orthogonality axiom below is the canonical **evidence-tier vocabulary** ({#evidence-tier-vocabulary}) — the single home that `km-protocols.md` cites by stable anchor and never redefines (single-home discipline per [`standards/duplicate-source-discipline.md`](../standards/duplicate-source-discipline.md); see [Cross-Reference: km-protocols.md](#cross-ref-km-protocols)).

<a id="evidence-tier-vocabulary"></a>

| Tier | Name | Evidence definition | Acceptance threshold (admission gate) | Approver | Review intensity (→ review cadence tier) |
|---|---|---|---|---|---|
| **ET1** | Systematic review / meta-analysis | ≥2 independent studies synthesized (Cochrane-style, or a published meta-analysis) | Cite the review + year; corroborating study count stated | Workspace owner (auto-admit; lowest scrutiny) | Lowest → `stable` (36mo) |
| **ET2** | Peer-reviewed canonical framework | Established framework with a peer-reviewed foundation (Nonaka SECI 1995; Pawson & Tilley 1997; PMBOK) | Cite framework + **edition/year** (composes w/ the `version_anchor`); named author/body | Workspace owner | Low → `stable`/`evolving` |
| **ET3** | Practitioner consensus / industry standard | Broadly-adopted professional standard, limited formal empirical base (Scrum Guide 2020; SAFe 6.0; Diátaxis) | Cite standard + edition; **paired applicability note** (consensus ≠ universal fit — handoff seam to ) | Workspace owner | Medium → `evolving` (12mo) |
| **ET4** | Emergent / internal pattern | Platform-originated convention validated by internal use (`decision-discipline.md` emergence rule; `failure-mode-standard.md`) | Cite originating release/issue + **≥2 internal applications** (mirrors `decision-discipline.md` N=2 emergence); **provisional** admit | Workspace owner + emergence-rule satisfied | High → `emerging` (continuous) |
| **ET5** | Expert opinion / single-source | One author / single expert / blog, no corroboration (a single-author heuristic) | Admit **only** with explicit `[EXPERT-OPINION:]` label **+ mandatory paired contraindication** (per the evidence rubric) **+ scheduled re-review**; never silently authoritative | Workspace owner, explicit per-instance | Highest → `emerging` + forced upgrade-or-retire review |

**Orthogonality axiom (the load-bearing design contribution — cite ):**

> Evidence tier (ET1–ET5, *epistemic strength*) is **orthogonal** to the universality axis ([`knowledge-architecture.md#universality-axis`](../disciplines/knowledge-architecture.md#universality-axis), *whose context*). They are independent questions. A practice may be **universal + low-evidence** (an ET4 platform convention that applies to any PMO-platform instance) or **contextual + high-evidence** (an ET1-backed practice that only fits a specific OOM). **Corpus admission requires BOTH gates:** (a) **universality gate** — the practice must classify as **K1 Codified** per the Q1 universality test ([`knowledge-architecture.md#tier-classifier`](../disciplines/knowledge-architecture.md#tier-classifier)); contextual K2–K5 knowledge is *not corpus* and routes to its placement home, **never** curated here; (b) **evidence gate** — it must clear its claimed ET tier's acceptance threshold. The two gates are evaluated independently at curation Review ([§2](#curation-protocol) step 2). This is the exact independence the knowledge-architecture contract specifies.

This makes "which tier" and "is it corpus" both **decidable**, not interpretive. K1 itself is defined at [`knowledge-architecture.md#k1-codified`](../disciplines/knowledge-architecture.md#k1-codified); this section adds the evidence dimension orthogonal to it.

---

## §2 Curation Protocol {#curation-protocol}

Six steps. Each names **owner**, **gate**, **cross-ref**. This is a *workflow* (verbs), deliberately **not** a lifecycle state machine — the artifact's state machine is `km-protocols.md`'s territory (step 6 binds to it; see [Cross-Reference: km-protocols.md](#cross-ref-km-protocols)).

| Step | Action | Owner | Gate (admission criterion) | Cross-ref |
|---|---|---|---|---|
| **1 Intake** | Candidate practice proposed (from the OPERATIONS.md §Corpus Research & Adoption Protocol output, or a `decision-discipline.md` emergence-rule promotion). Required fields: source citation, proposed ET, universality position, domain. | Proposer (any agent / operator) | All 4 intake fields present | [OPERATIONS.md §Corpus Research & Adoption Protocol](../governance/OPERATIONS.md); [`decision-discipline.md`](../disciplines/decision-discipline.md) emergence promotion (one intake source) |
| **2 Review** | Evaluate evidence vs. claimed ET threshold → assign **final** ET. Run **both** orthogonal gates ([§1](#evidence-tiers) axiom): universality (must be K1) + evidence (must clear ET). Conflict scan vs. existing corpus. | Workspace owner | Both gates pass; no unresolved corpus conflict | [`knowledge-architecture.md#tier-classifier`](../disciplines/knowledge-architecture.md#tier-classifier) (universality gate); [`knowledge-architecture.md#universality-axis`](../disciplines/knowledge-architecture.md#universality-axis); conflict → `applicability-framework.md` (forward) |
| **3 Approve** | ET1–ET3 → standard admit. ET4 → **provisional** (sunset/promotion review scheduled). ET5 → explicit per-instance + mandatory contraindication. | Workspace owner (governance gate per [`../standards/km-governance-framework.md § 3`](../standards/km-governance-framework.md)) | Approver authority matches the tier row ([§1](#evidence-tiers)); new-artifact vs amendment scope distinction lives at [`km-governance-framework.md § 3.2`](../standards/km-governance-framework.md) | `km-governance-framework.md` (shipped — governance/ownership layer ABOVE this; cites ET1–ET5 verbatim, never redefines) |
| **4 Version-anchor** | Register the framework/source in the `framework-catalog.md` (`version_anchor`). This doc owns the **evidence_tier assignment**; `framework-catalog.md` owns the **version_anchor**. No duplicated data. | Workspace owner | Catalog row exists w/ non-empty `version_anchor` | `framework-catalog.md` (soft-relate seam — [§5](#boundaries)) |
| **5 Publish** | Practice enters the K1 corpus (a `reference/` doc, SKILL.md, or `core/rules/`). Evidence label ([§4](#evidence-labels)) applied **at point of use**. | Engineering (per the normal release pipeline) | Evidence label present at every use site | [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) Evidence-label guardrail; [§4](#evidence-labels) |
| **6 Retire / Supersede** | Retirement triggers enumerated below. The terminal transition **BINDS to `km-protocols.md` KM-artifact lifecycle states** — this doc states the *trigger*, `km-protocols.md` owns the *state*. | Workspace owner | Trigger documented; artifact moved to the `km-protocols.md`-defined retired/superseded state | [Cross-Reference: km-protocols.md](#cross-ref-km-protocols) (D-Struct — `km-protocols.md#km-artifact-lifecycle`) |

**Retirement triggers (enumerated — durable structure per [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) "prefer durable structures over static examples"; not prose-narrated):**

| # | Trigger | Detection signal |
|---|---|---|
| RT-a | Evidence overturned | A higher-ET source contradicts the practice's empirical basis |
| RT-b | Framework deprecated by its issuing body | The source body publishes a successor edition that supersedes the cited one |
| RT-c | Superseded by a higher-ET practice | A new corpus entry covers the same claim at a stronger tier |
| RT-d | ET5 scheduled re-review lapsed | An `[EXPERT-OPINION:]` entry's mandated re-review date passed without upgrade-or-retire |

In every RT case, the artifact moves to the `km-protocols.md`-owned retired/superseded state — this doc never defines that state (single-home discipline; see [Cross-Reference: km-protocols.md](#cross-ref-km-protocols)).

---

## §3 Source Taxonomy {#source-taxonomy}

Six domains (≥5 AC exceeded), each with named authoritative sources + default evidence tier + version-anchor expectation (composes with the `framework-catalog.md`; does not duplicate it — see the [§5](#boundaries) granularity seam). The taxonomy is the **preferred-source lookup**: a curation candidate in domain Dx defaults to that row's tier unless its specific evidence warrants a different ET.

**AC4 self-demonstration:** every "Named authoritative sources" cell below is written **using the [§4](#evidence-labels) evidence-label extension** — this doc is its own ≥1 applied-example demonstration (`corpus-curation.md` IS a `core/` doc), satisfying AC4 by construction with zero contention against any skill `references/` edit.

| # | Domain | Named authoritative sources (written in §4 labels) | Default tier | Version-anchor (→ ) |
|---|---|---|---|---|
| **D1** | Project / Program Management | `[FRAMEWORK: PMI PMBOK 7th 2021]`; `[FRAMEWORK: PRINCE2 2017]` | ET2 | edition/year |
| **D2** | Agile / Lean delivery | `[CONSENSUS: Scrum Guide 2020]`; `[CONSENSUS: SAFe 6.0]`; `[CONSENSUS: Disciplined Agile (current)]`; `[FRAMEWORK: Kanban — Anderson 2010]` | ET3 | edition/year |
| **D3** | Knowledge Management | `[FRAMEWORK: Nonaka SECI 1995]`; `[CONSENSUS: Diátaxis (current)]`; `[FRAMEWORK: Walsh & Ungson 1991]`; `[FRAMEWORK: Schön — reflective practice 1983]` | ET2 | edition/year or `(current)` |
| **D4** | Software engineering / architecture | `[FRAMEWORK: ADR — Nygard 2011]`; `[FRAMEWORK: Gang of Four 1994]`; `[EXPERT-OPINION: Fowler — named heuristic; paired contraindication via `applicability-framework.md` (forward)]` | ET2 (GoF/ADR) / ET5 (single-author heuristics) | edition/year |
| **D5** | Evidence-Based Management | `[EMPIRICAL: Pfeffer & Sutton 2006]`; `[FRAMEWORK: Rousseau 2006]` | ET1/ET2 | year |
| **D6** | Realist evaluation | `[FRAMEWORK: Pawson & Tilley 1997]` — grounds applicability contraindications | ET2 | year |

The taxonomy is **sufficient to route a candidate to its preferred source**, not claimed exhaustive — a new domain or source is added via the [§2](#curation-protocol) curation protocol like any other corpus change.

---

## §4 Evidence Labels {#evidence-labels}

Mirrors and **extends** [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>)'s project-claim labels (`[SOURCE]` `[INFERRED]` `[ASSUMPTION – CONFIRM]` `[CONTEXT]` `[RECOMMENDED]`) into the **methodological-claim** domain. Each label maps to an ET tier and a citation requirement. These five labels are part of the [#evidence-tier-vocabulary](#evidence-tier-vocabulary) that `km-protocols.md` cites and never redefines.

| Label | ET | Required payload | Example |
|---|---|---|---|
| `[EMPIRICAL: <review/n>]` | ET1 | review name or study count + year | `[EMPIRICAL: Cochrane-style, n=4 studies, 2019]` |
| `[FRAMEWORK: <name> <edition/year>]` | ET2 | framework + edition/year (composes w/ the catalog anchor) | `[FRAMEWORK: Nonaka SECI 1995]` |
| `[CONSENSUS: <standard> <edition>]` | ET3 | standard + edition + paired applicability note | `[CONSENSUS: Scrum Guide 2020]` |
| `[EMERGENT: <release/issue>, n=<X>]` | ET4 | originating release/issue + ≥2 internal applications | `[EMERGENT: <release>, n=2]` |
| `[EXPERT-OPINION: <source>]` | ET5 | single source + **mandatory paired contraindication ref ** | `[EXPERT-OPINION: Fowler — paired contraindication §X]` |

The label is applied **at the point of use** in the corpus ([§2](#curation-protocol) step 5), not centrally registered here. `framework-catalog.md` is the natural *future* adopter (labels annotate catalog rows) — flagged forward-compat, **not in scope** (see [§5](#boundaries)).

---

## §5 Boundaries {#boundaries}

| Boundary | Relationship | Action |
|---|---|---|
| **`framework-catalog.md`** — `framework-catalog.md` + `## Framework Review Cadence Protocol` | **Soft relate-to (content-separation, NOT contention).** The catalog owns *which* frameworks exist + *what edition* (`version_anchor`) + *review cadence tier*; this doc owns *what evidence qualifies* a practice + *how it is curated* + *source taxonomy* + *evidence labels*. **Granularity distinction:** the catalog catalogs **frameworks** ("SAFe 6.0"); this doc tiers **methodological claims/practices** ("use WSJF prioritisation" inherits SAFe's ET3) — different objects. | **Compose, do not restate.** `framework-catalog.md` MAY add an optional `evidence_tier` column citing [#evidence-tier-vocabulary](#evidence-tier-vocabulary) as forward-compat enrichment — Collective-Review coherence note, **LOW**, not in scope. |
| **`applicability-framework.md`** — `applicability-framework.md` (contraindications / conflict-resolution) | **Evidence ⊥ applicability.** Evidence tier (this doc) answers *how strong is the evidence*; applicability (the other doc) answers *does it fit this context*. Independent axes. The ET3 **paired-applicability-note** and ET5 **mandatory-contraindication** are forward **handoff seams** to `applicability-framework.md`. | **Boundary stated to prevent future duplication.** This doc does **not** define applicability — forward-ref only, no duplication. |
| **`knowledge-architecture.md`** — `knowledge-architecture.md` (K-tier taxonomy + universality axis) | **K1-only scope.** Evidence tiers + curation apply to the **K1 corpus only**. The universality gate ([§1](#evidence-tiers) axiom) consumes its [`#tier-classifier`](../disciplines/knowledge-architecture.md#tier-classifier) + [`#universality-axis`](../disciplines/knowledge-architecture.md#universality-axis) by reference. Contextual K2–K5 knowledge routes to its placement home and is never curated here. | **Consume, do not redefine.** Universality axis is knowledge-architecture's; evidence axis is this doc's; they are orthogonal. |
| **Anti-maintenance-debt** — standalone-doc justification | Standalone `corpus-curation.md` is justified by the **same demonstrable-use escape clause** that the prior knowledge-architecture ADR invoked for `knowledge-architecture.md`: a hard cross-ref consumer (`km-protocols.md`), an explicit issue AC, and the source issue body naming the file. | **Reference the prior precedent; do not re-derive.** This doc's own decision is recorded in its own decision record. |

---

## Cross-Reference: km-protocols.md {#cross-ref-km-protocols}

This section states the **D-Struct bidirectional cross-reference contract** between this doc and `km-protocols.md` in **prose only**. It deliberately contains **no live outbound markdown link** to `km-protocols.md` at Engineering — `km-protocols.md` does not yet exist (the downstream sequence places `km-protocols.md` Engineering last), and a live forward link would surface as a Check-14 broken-link / Stage-7 deprecated-path finding. The single live outbound link is back-patched here by **`km-protocols.md` Engineering**, atomically with `km-protocols.md`'s inbound link, so no broken-link transient ever exists.

**Ownership split (single-home discipline per [`standards/duplicate-source-discipline.md`](../standards/duplicate-source-discipline.md)):**

- **This doc owns the evidence-tier vocabulary.** The [#evidence-tier-vocabulary](#evidence-tier-vocabulary) anchor ([§1](#evidence-tiers) ET1–ET5 table + orthogonality axiom + the [§4](#evidence-labels) five labels + threshold semantics) is the single canonical home. `km-protocols.md` **cites** it by the stable anchor `corpus-curation.md#evidence-tier-vocabulary` and **must not redefine** any ET tier or label.
- **`km-protocols.md` owns the KM-artifact lifecycle.** `km-protocols.md` will define a stable anchor `km-protocols.md#km-artifact-lifecycle` (KM-artifact states incl. retired/superseded, staleness-by-criticality). This doc's curation [§2](#curation-protocol) **step 6 binds** to that anchor — it states the retirement *trigger* (the [§2](#curation-protocol) RT-a..RT-d table) and defers the *state* to `km-protocols.md`. This doc never defines a retire-state machine.
- **Forward consumption:** `km-protocols.md`'s doc-debt scoring / staleness-by-criticality consumes the evidence-tier vocabulary — a low-ET (ET4/ET5) practice carries higher staleness criticality than an ET1/ET2 one. `km-protocols.md` cites the ET semantics; it does not duplicate them.

**Atomic mechanic (binding sequencing contract for `km-protocols.md` Engineering):** `km-protocols.md` Engineering creates `km-protocols.md` with the inbound `km-protocols.md → corpus-curation.md#evidence-tier-vocabulary` link **and** back-patches the single live outbound `corpus-curation.md → km-protocols.md#km-artifact-lifecycle` link into this reserved section in the same commit. Both directions resolve at the same commit → zero broken-link transient → Check-14-clean → the downstream sequence is honoured.

**Back-patched live cross-reference (`km-protocols.md` Engineering):** [km-protocols.md](km-protocols.md#km-artifact-lifecycle) — the canonical KM-artifact lifecycle anchor that §2 curation step 6 (the RT-a..RT-d retirement triggers) binds to for the *state*. This is the single live outbound link the atomic mechanic above prescribes; it resolves as of the same commit that creates `km-protocols.md`, so no broken-link transient ever exists.
