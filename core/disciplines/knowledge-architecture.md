---
title: Knowledge Architecture & Taxonomy
purpose: 5-tier knowledge classification + the orthogonal universality/authorship axes + the placement model (incl. the parameterization seam) + a bounded local-context leakage register for the PMO platform corpus
type: reference
reversibility: CHEAP / Confidence HIGH
consumers: "corpus-curation.md, applicability-framework.md, km-protocols.md (forward-only — relocated via 2026-05-19 capacity-audit merge)"
glossary_anchor: "umbrella body Glossary (canonical knowledge-tier terms — verbatim source for §1)"
---
<!-- reference-durability: allow-link -->

# Knowledge Architecture & Taxonomy

This document is the platform's classification of **knowledge types** and the **placement model** stating where each type lives. It composes with — and does **not** restate — [`architecture-overview.md`](../disciplines/architecture-overview.md)'s Layer-1/Layer-2 model and the [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) Governance File Map. Its three contributions are: (1) the 5-tier classification K1–K5 with a deterministic classifier; (2) the net-new **universality axis** drawn orthogonal to the existing authorship axis, proving *custom ≠ contextual*; (3) the **placement model** whose load-bearing concept is the **parameterization seam** — the boundary where CLAUDE.md "Parameterize over hardcode" bites.

Terminology is locked verbatim to the **umbrella Glossary** (the umbrella body IS the canonical glossary per the anti-maintenance-debt rule). [`terminology-glossary.md`](../specs/terminology-glossary.md) is a **disjoint** methodology glossary (Area / Domain / Function / Process / Stage / WBS / Scope) — it carries no knowledge-tier terms; this doc cross-references both and redefines neither (see [§5 Boundaries](#boundaries)).

---

## §1 Five-Tier Classification {#five-tier-classification}

Five knowledge types are in play across the platform. The summary table is the at-a-glance index; the per-tier blocks below it carry the stable citation anchors downstream consumers reference.

| Tier | Canonical name (umbrella glossary) | Definition (verbatim) | Source framework (corpus-curation source-taxonomy) | Universality | Mutability (feeds km-protocols staleness-by-criticality) |
|---|---|---|---|---|---|
| **K1** | **Codified knowledge** | Explicit, transferable, decoupled from person/context | Nonaka SECI 1995 (externalization/combination) | **Universal** | Slow — version-anchored (release cadence) |
| **K2** | **Organizational Operating Model (OOM)** | How the org actually works — structure, cadences, norms (WoW = behavioral subset, SAFe/DA) | Business-architecture lit; operating-model.md | **Contextual (org)** | Medium |
| **K3** | **Institutional knowledge** | Persistent org facts (systems, vendors, roster, owner identity/contact) | Walsh & Ungson 1991 | **Contextual (org)** | Slow–medium |
| **K4** | **Instance knowledge** | Project-specific state | PMBOK / ITIL | **Contextual (project)** | Fast |
| **K5** | **Tacit / situated knowledge** | Learned by doing, hard to externalize; the CORRECTIONS.md class | Nonaka SECI 1995 (socialization); Schön reflective practice | **Contextual (situational)** | Emergent / fast |

### K1 — Codified knowledge {#k1-codified}

Explicit, transferable, decoupled from person/context. **Source framework:** Nonaka SECI 1995 (externalization/combination). **Universality:** Universal. **Mutability:** Slow — version-anchored. K1 is **the corpus** (the umbrella glossary "Corpus" term = the K1 set): `core/`, `release/skills/*/SKILL.md` (+ `references/`), `core/rules/`.

### K2 — Organizational Operating Model (OOM) {#k2-oom}

How the org actually works — structure, cadences, norms (Ways of Working is the behavioral subset; SAFe/DA). **Source framework:** business-architecture literature; `operating-model.md`. **Universality:** Contextual (org). **Mutability:** Medium. The OOM *model* is universal (K1); the OOM *values* are K2 parameters consumed from CLAUDE.md § Workspace Owner.

### K3 — Institutional knowledge {#k3-institutional}

Persistent org facts — systems, vendors, roster, owner identity/contact. **Source framework:** Walsh & Ungson 1991 (organizational memory). **Universality:** Contextual (org). **Mutability:** Slow–medium.

### K4 — Instance knowledge {#k4-instance}

Project-specific state. **Source framework:** PMBOK / ITIL. **Universality:** Contextual (project). **Mutability:** Fast. K4 lives only in Layer 2 (`projects/[Project]/`); never in Layer 1.

### K5 — Tacit / situated knowledge {#k5-tacit}

Learned by doing, hard to externalize — the CORRECTIONS.md class. **Source framework:** Nonaka SECI 1995 (socialization); Schön reflective practice. **Universality:** Contextual (situational). **Mutability:** Emergent / fast. Promotion path = observation → pattern → (maybe) governance; never hardcoded into K1.

### Tier-assignment decision rule — the classifier {#tier-classifier}

Implementation-ready, deterministic. **Q1 is the universality test** — the single load-bearing classifier and the exact predicate the [§4 leakage register](#local-context-leakage-register) applies.

```
Q1. Would this knowledge be TRUE-AND-USEFUL verbatim for a *different* org or
    project running the PMO platform?
      YES → K1 Codified  (universal; lives in Layer 1 platform corpus)
      NO  → go to Q2 (it is contextual)
Q2. What is the contextual SCOPE?
      org-wide, "how we work"        → K2 OOM
      org-wide, "persistent facts"   → K3 Institutional
      one project's live state       → K4 Instance
      emergent/corrective/adaptive   → K5 Tacit
```

---

## §2 Two Axes {#two-axes}

Two **orthogonal** axes describe any knowledge artifact. Conflating them is the structural reason local-context leakage is invisible to an authorship-only audit.

### Universality axis (NET-NEW — this doc's core contribution) {#universality-axis}

*universal ↔ contextual* = **whose context does this knowledge apply to?** (any PMO-platform deployment ↔ only [COMPANY_X] / only this project / only this situation). This is the axis Q1 of the [classifier](#tier-classifier) tests. K1 is universal; K2–K5 are contextual at successively narrower scope.

### Authorship axis (cross-referenced, NOT redefined here) {#authorship-axis}

*base ↔ custom* = **who authored it?** (Anthropic base ↔ PMO custom). [`anthropic-base-vs-build-registry.md`](../specs/anthropic-base-vs-build-registry.md) instantiates this axis for *skills*; this doc generalizes the axis label to all knowledge and declares it orthogonal to universality. This document **cross-references** the authorship axis; it does not redefine it.

### The 2×2 matrix {#axis-2x2}

| | **Base (Anthropic-authored)** | **Custom (PMO-authored)** |
|---|---|---|
| **Universal** | `anthropic-skills:skill-creator` conventions; pptx/docx/pdf skills | **(the bulk of the corpus)** 13-stage pipeline, `decision-discipline.md`, `failure-mode-standard.md`, `km-protocols.md`, `corpus-curation.md`, `applicability-framework.md` — PMO-built, applies to *any* PMO-platform instance |
| **Contextual** | rare — a base skill wrapped with org params (e.g., `pmo-skill-refiner` wrapping skill-creator + [COMPANY_X] injection) | **(the leakage zone)** [COMPANY_X] OOM (K2), owner identity/phone (K3), [PROJECT_KEY] RAID state (K4), CORRECTIONS observations (K5) |

**The dispositive insight:** the matrix proves **custom ≠ contextual**. The authorship axis alone cannot detect local-context leakage because a leak is a **universality-axis** violation (contextual content K2–K5 embedded in a universal container K1), *independent of authorship*. `comms-writer` hardcoding `[OPERATOR_NAME], Senior Program Manager • [OPERATOR_PHONE]` is **custom + contextual** — invisible to an authorship-only audit. This is the structural reason this doc's universality axis is a required net-new artifact and not a duplicate of the authorship registry.

---

## §3 Placement Model {#placement-model}

The model composes with (does **not** restate) [`architecture-overview.md`](../disciplines/architecture-overview.md)'s Layer-1/Layer-2 model and the [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) Governance File Map. Its novel contribution is the parameterization seam.

| Tier | Authoritative home | Layer | Owner | Read-by | Parameterization rule |
|---|---|---|---|---|---|
| **K1** | `core/`, `release/skills/*/SKILL.md` (+ `references/`), `core/rules/` | L1 | Claude Code (git) | all agents | MUST NOT embed K2–K5 literals; reference the parameter, never the value |
| **K2** | **Model:** `../disciplines/operating-model.md`  · **Values:** `CLAUDE.md` § Workspace Owner | L1 + parameter | Claude Code | all agents | model universal; *values* are parameters consumed from CLAUDE.md |
| **K3** | `CLAUDE.md` § Workspace Owner + `projects/[Project]/PROJECT.md` | L1 + L2 | mixed | all agents | skills say "workspace owner (from CLAUDE.md)" — never the literal name/number |
| **K4** | `projects/[Project]/` (01–08 + PROJECT.md) | L2 | Claude Code (operations) | Claude Code (operations) | never in L1 |
| **K5** | `projects/_config/CORRECTIONS.md`, the observation log + promoted confirmed-pattern entries (user auto-memory store) | L2 + auto-memory | Claude Code (operations) / auto-memory | both | never hardcoded into K1; promotion path = observation → pattern → (maybe) governance |

### Parameterization seam {#parameterization-seam}

The model's load-bearing concept, consumed by . The **K1↔K2/K3 boundary** is exactly where CLAUDE.md "Parameterize over hardcode" and "Pre-creation governance check" apply. The [§4 leakage register](#local-context-leakage-register) is the catalog of where this seam is currently breached.

**Positive exemplar (the canonical correct pattern):** `daily-status/SKILL.md:97` — *"Items assigned to the workspace owner (from CLAUDE.md)"* — references the K3 parameter by pointer, never the literal name/number. New and edited K1 artifacts MUST follow this pattern at the seam.

---

## §4 Local-Context Leakage Register {#local-context-leakage-register}

**Scope discipline (BOUNDED — per AC + Stage 4 plan "Discoveries outside scope"):** this register is a deliverable that **ENUMERATES and SIZES**; it does **not** remediate. Remediation is owned by **initiative-umbrella child issues**, milestone-agnostic and future. The Stage-4 plan's note tying the register to in-scope child issues is **stale post-D-NEW1(a)** — corrected here: register consumers are remediation children, **not** in-scope consumers (which consume the *taxonomy*, not the *register*).

**Classification rubric** (the register is not a flat file list):

| Class | Meaning |
|---|---|
| **TRUE-LEAK** | contextual (K2–K5) literal in a universal (K1) container — violates the [seam](#parameterization-seam) |
| **PARAMETERIZED-OK** | references CLAUDE.md / a param — **NOT** a leak (exemplar) |
| **ILLUSTRATIVE** | example / sample data — low severity, register-but-defer |
| **GENERIC-ROLE** | "workspace owner" / "the operator" with no literal — **NOT** a leak |

**Register (logical sources; mirror-copied refs de-duplicated):**

| # | Logical source (files) | Leaked tier | Signature | Class | Severity | Size note |
|---|---|---|---|---|---|---|
| L1 | `comms-writer/SKILL.md:156`, `references/channel-formats.md:88`, `references/voice-guide.md:165` | K3 | `[OPERATOR_NAME], Senior Program Manager • [OPERATOR_PHONE]` (incl. phone — PII-adjacent) | **TRUE-LEAK** | **MEDIUM-HIGH** | 3 files, 1 logical signature block |
| L2 | `project-initiator/references/project-md-template.md:55` + `templates/{communications-tracker,open-meetings-tracker,executive-status-report-prompt}-template.md` | K3 | `[OPERATOR_NAME] \| Senior Program Manager (TPM)` / `Prepared by: [OPERATOR_NAME]` | **TRUE-LEAK** | **MEDIUM** | 4 files; propagates identity on every project-init |
| L3 | `build-reviewer/references/dimension-packs/pmo-platform-dimensions.md:236` | K2+K3 | "[OPERATOR_NAME] — Senior Program Manager / Technical Program Manager at [COMPANY_X]" | **TRUE-LEAK** | **MEDIUM** | 1 file; full OOM+institutional identity in a dimension pack |
| L4 | `eval-writer/references/playbook-per-skill.md:38,44,139` | K2 | "[OPERATOR_NAME] reviews outputs", "already-coded failure modes", single-operator HITL assumed | **TRUE-LEAK** (also an applicability concern) | **LOW-MEDIUM** | 1 file, 3 lines; embeds single-operator OOM assumption |
| L5 | `../governance/OPERATIONS.md:5` | K2+K3 | header "[COMPANY_X] PMO / [OPERATOR_NAME]" | TRUE-LEAK (governance file — expected to carry identity; flag, low priority) | **LOW** | 1 line |
| L6 | `template-protocol.md` ×6 skills (delivery-engine, eval-writer, pmo-process-designer, pmo-skill-refiner, release-planner, project-initiator) lines 75/247/252 | K3 | example `reviewer/owner: [OPERATOR_NAME]` | **ILLUSTRATIVE** | **LOW** | 6 files, **1 logical source** (mirror-copied reference) |
| L7 | `template-storage.md` ×5 skills line 102 | K4 | "projects/[PROJECT_KEY] Implementation/...[PROJECT_KEY]_RAID_Log.csv ... [COLLEAGUE_I] integration delay" | **ILLUSTRATIVE** | **LOW** | 5 files, **1 logical source**; names a real project path |
| L8 | `delivery-engine/references/{dependency-rules,raid-templates}.md`; `change-management/SKILL.md:254`; `ppm-agent/SKILL.md:308` | K4 | `R-[PROJECT_KEY]-042`, "[PROJECT_KEY] go-live, 10.0.47", "steerco on [PROJECT_KEY] cutover" | **ILLUSTRATIVE** | **LOW** | example data; convention parameterized, value is the example |
| — | `daily-status/SKILL.md:97`; `release-executor/.../rollback-protocol.md:144`; `file-router/SKILL.md:289`; `prompt-builder/.../critique-rubric.md:138`; `implementation-planner` domain-pack `operator_profile_default:` | — | "workspace owner (from CLAUDE.md)" / generic role / overridable default | **PARAMETERIZED-OK / GENERIC-ROLE** | n/a | **NOT leaks** — `daily-status:97` is the positive exemplar |

**Sizing for triage:** 18 raw grep hits → **8 logical leakage rows** + 5 not-a-leak rows → **4 actionable TRUE-LEAKs at MEDIUM+ (L1–L4)** worth a downstream remediation child issue; L5 LOW (governance, defer); L6–L8 ILLUSTRATIVE LOW (defer or accept-as-example). The scan signatures used (`[COMPANY_X]`, `[OPERATOR_NAME]`/`[OPERATOR_NAME]`, role strings, `[PROJECT_KEY]`) are **not exhaustive** — a remediation child should also sweep vendor names and phone/email PII patterns. Register is **sufficient to triage**, not claimed complete.

**Authoritative inventory:** the complete audit register superseding this bounded snapshot lives in the operator-instance analysis archive (external to this repo) — the deliverable (10 TRUE-LEAK rows + 5 ILLUSTRATIVE rows; 9-column schema per [`universal-vs-localized-context.md` §9](../standards/universal-vs-localized-context.md)). §4 retained here as the **model-illustrating example** (illustrative; not authoritative); the audit register is the operative inventory for remediation triage.

---

## §5 Boundaries {#boundaries}

| Boundary | Relationship | Action |
|---|---|---|
|  — authorship axis (`anthropic-base-vs-build-registry.md`) | **Satisfied.**  owns *base ↔ custom*; this doc owns the orthogonal *universal ↔ contextual* and cross-references  for authorship. | No action — cross-reference only ([§2](#authorship-axis)). |
| Universal-Protocol vs Localized-Context separation (audit + standard) | The audit + enforcement standard **consumes** this doc's universality axis. This doc = the *model*; the standard = the *audit + enforcement standard* on it. **Out of scope here.** | **Do NOT action.** Boundary stated to prevent future duplication. |
| ** / [`operating-model.md`](../disciplines/operating-model.md)** — K2 model home | This doc's placement model assigns the K2 *model* to `operating-model.md`; K2 *values* are CLAUDE.md parameters. | Compose, do not restate. |
| **[`terminology-glossary.md`](../specs/terminology-glossary.md)** — disjoint methodology glossary | Carries Area/Domain/Function/Process/Stage/WBS/Scope — **no** knowledge-tier terms. No collision, no redefinition risk. | Cross-reference; redefine nothing. |
