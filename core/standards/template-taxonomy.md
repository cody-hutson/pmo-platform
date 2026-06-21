<!-- reference-durability: allow-link -->
# Template Taxonomy — PMO Platform

**Last Refreshed:** 2026-05-10
**Authority:** L1 of the 5-Layer Template Architecture. Establishes the canonical artifact-family taxonomy across project + software + platform-internal domains and binds each family to a named best-practice canon.

## §1 Purpose

This document is L1 of the 5-Layer Template Architecture. It defines (a) the **three-domain model** for classifying every PMO template, (b) the **artifact-family taxonomy** within each domain (anchored on PMBOK 7 Performance Domains for project artifacts and on engineering best-practice canons for software artifacts), and (c) the **canon-per-artifact-family mapping** that binds each family to its native external best-practice convention plus any Anthropic plugin cross-reference. It is consumed by L3 Storage (registry layout + propagation declaration), L4 Lifecycle (promotion gates), and L5 Governance (consumer-skill integration). It exists in parallel to (and does not duplicate) the corpus-content taxonomy in the Knowledge Architecture — this document governs the **typed-format axis** (template structure), not the corpus-content axis.

**Reversibility tier:** CHEAP — Confidence: HIGH. This is a doc-only artifact; canon mappings are doc-edit reversible. Coupling intensifies once 5+ consumer skills reference canon-per-template (then MODERATE).

## §2 Three-Domain Model

Every PMO template is classified into exactly one of three domains. The domain determines which canon family applies, where the canonical copy lives, and which audience consumes the rendered artifact.

| Domain | Description | Canon Family | Realized in PMO By |
|---|---|---|---|
| **Project** | Stakeholder-facing artifacts produced during project delivery. Audience: PMs / sponsors / SteerCo / external stakeholders. | PMBOK 7 Performance Domains | 12 canonical templates today (status reports, RAID, communications tracker, etc.) — see §3 |
| **Software** | Engineering / technical-decision artifacts. Audience: developers / SREs / architects. | Per-family canon (Nygard / Google SRE / IETF / Rust / Anthropic plugin convention / etc.) | Currently absent from `operations/templates/` — 8 gaps surfaced (see §4 + §6) |
| **Platform-internal** | Skill-runtime guidance + skill-internal scaffolding. Audience: the skill itself at runtime, not stakeholders. | n/a (not stakeholder-facing artifacts) | 4 skill-embedded standalone templates (raid-templates, rubric-templates, pmo-platform-template, release-plan-template) |

**Domain boundary rule.** Project-domain artifacts represent project state observable to stakeholders. Software-domain artifacts represent engineering decisions or operations procedures observable to engineers. Platform-internal templates represent skill-runtime authoring guidance — they are not produced as stakeholder-visible artifacts. When a template ambiguously straddles two domains, classify by the audience of the rendered output, not by the audience that consumes the template specification.

**Cross-reference to ecosystem-design Three-Domain Architecture.** The PMO platform also defines a `Domain A / B / C` model in [`document-ecosystem-design.md` §3](../disciplines/document-ecosystem-design.md) (Source Artifacts / Managed Knowledge / Synthesized Intelligence). That model classifies **instances** by trust + lifecycle. This taxonomy classifies **template structures** by canon family. Both are valid orthogonal axes; a single template instance carries both classifications (e.g., a status report instance is `Domain B` for trust + `Project` for canon family). No conflict.

## §3 Project-Domain Taxonomy (PMBOK 7 Performance Domains)

The PMBOK 7 standard organizes project work into 8 Performance Domains. Each project-domain template anchors to exactly one Performance Domain.

### §3.1 Stakeholder

| Artifact Family | Description | Current Canonical PMO Template | Gap? |
|---|---|---|---|
| Communications Tracker | Log of stakeholder communications + cadence | `operations/templates/communications-tracker-template.md` | No |
| Open Meetings Tracker | Log of stakeholder meetings + outstanding agenda items | `operations/templates/open-meetings-tracker-template.md` | No |
| Stakeholder Register | Identification + classification + engagement strategy per stakeholder | (none) | YES — closure path: future release |
| RACI / RAEW / RAS | Responsibility-assignment matrix | (none) | YES — closure path: future release |
| Glossary / Key Terms | Shared-vocabulary index | `operations/templates/key-terms-glossary-template.csv` | No |

### §3.2 Team

| Artifact Family | Description | Current Canonical PMO Template | Gap? |
|---|---|---|---|
| Onboarding / KT doc | Team-onboarding or knowledge-transfer reference | `operations/templates/PMO_Platform_Template.md` | No (operational instance — KT for the platform itself) |

### §3.3 Development Approach + Lifecycle

| Artifact Family | Description | Current Canonical PMO Template | Gap? |
|---|---|---|---|
| Dual-Framing Bridge | Hybrid Agile↔Waterfall delivery-framing dual-output | `operations/templates/dual-framing-bridge-template.md` | No |

### §3.4 Planning

| Artifact Family | Description | Current Canonical PMO Template | Gap? |
|---|---|---|---|
| Milestone Tracker | Planned milestones + status + dependencies | `operations/templates/milestone-tracker-template.md` | No |
| Sprint Tracker | Sprint backlog + velocity + burndown | `operations/templates/sprint-tracker-template.md` | No |
| Requirements (epics/features/stories) | Decomposition hierarchy aligned with PMBOK 7 §Planning | `operations/templates/requirements-template.md` (promoted to canonical per L3 Storage) | No |
| PROJECT.md scaffolding | Per-project canonical state file | `operations/templates/project-md-template.md` (promoted to canonical per L3 Storage) | No |

### §3.5 Project Work

| Artifact Family | Description | Current Canonical PMO Template | Gap? |
|---|---|---|---|
| Transcript Register | Log of meeting/call transcripts + processing state | `operations/templates/transcript-register-template.md` | No |

### §3.6 Delivery

(No PMO templates yet — covered by trackers in §3.4 + status reports in §3.7.)

### §3.7 Measurement

| Artifact Family | Description | Current Canonical PMO Template | Gap? |
|---|---|---|---|
| Daily Status Log | Carry-forward log of daily status updates | `operations/templates/daily-status-log-template.md` | No |
| Daily Status Update Framework | Structural framework for daily status messages | `operations/templates/daily-status-update-framework-template.md` | No |
| Executive Status Report Prompt | Template for leadership-ready status reports | `operations/templates/executive-status-report-prompt-template.md` | No |

### §3.8 Uncertainty

| Artifact Family | Description | Current Canonical PMO Template | Gap? |
|---|---|---|---|
| RAID Log | Risks + Assumptions + Issues + Decisions/Dependencies | `operations/templates/raid-log-template.csv` | No |

## §4 Software-Domain Taxonomy (engineering best-practice canons)

The software domain organizes around the documents engineers produce. Each artifact family has a named native canon (the upstream best-practice convention) and, where applicable, an Anthropic plugin cross-reference (a plugin skill installed in this workspace that already implements the same canon as an authoring route).

### §4.1 Architecture / Decision (ADR)

| Artifact Family | Primary Canon | Anthropic Plugin Cross-Ref | Current PMO Template | Gap Status |
|---|---|---|---|---|
| ADR | **Nygard, "Documenting Architecture Decisions" (2011)** — 4-section structure (Context / Decision / Status / Consequences) | `engineering:architecture` plugin (described as "Create or evaluate an ADR") | (none) | YES — gap; closure path: future software-domain release |

### §4.2 Operations / Runbook

| Artifact Family | Primary Canon | Anthropic Plugin Cross-Ref | Current PMO Template | Gap Status |
|---|---|---|---|---|
| Runbook | **Google SRE Workbook §Runbook Design** — secondary: ITIL Service Operation §Operations Management | `operations:runbook` plugin (PMO operations role-skill) | (none) | YES — gap; closure path: future software-domain release |

### §4.3 Design / System

| Artifact Family | Primary Canon | Anthropic Plugin Cross-Ref | Current PMO Template | Gap Status |
|---|---|---|---|---|
| Design doc | **Google design-doc convention** (Atwood / Henderson templates) — Context / Goals / Non-goals / Proposal / Alternatives / Risks | `engineering:system-design` plugin | (none) | YES — gap; closure path: future software-domain release |

### §4.4 Specification / Protocol (RFC)

| Artifact Family | Primary Canon | Anthropic Plugin Cross-Ref | Current PMO Template | Gap Status |
|---|---|---|---|---|
| RFC | **IETF RFC 7322** + **Rust RFC template** (https://github.com/rust-lang/rfcs) | (no Anthropic plugin equivalent) | (none) | YES — gap; closure path: future software-domain release |

### §4.5 Product / PRD

| Artifact Family | Primary Canon | Anthropic Plugin Cross-Ref | Current PMO Template | Gap Status |
|---|---|---|---|---|
| PRD / Feature spec | **Anthropic `product-management:write-spec` plugin convention** (per Anthropic offload routing) — secondary: industry practice (Aha! / Lenny Rachitsky template) | `product-management:write-spec` plugin (direct hit) | (none) | YES — gap; closure path: the canon IS the plugin |

### §4.6 Reliability / Postmortem

| Artifact Family | Primary Canon | Anthropic Plugin Cross-Ref | Current PMO Template | Gap Status |
|---|---|---|---|---|
| Postmortem | **Google SRE Workbook §Postmortem Culture** | `engineering:incident-response` plugin (covers triage + communicate + postmortem) | (none) | YES — gap; closure path: future software-domain release |

### §4.7 Quality / Testing

| Artifact Family | Primary Canon | Anthropic Plugin Cross-Ref | Current PMO Template | Gap Status |
|---|---|---|---|---|
| Test plan / Test case | **PMBOK 7 §Quality** + **Anthropic `engineering:testing-strategy` plugin convention** | `engineering:testing-strategy` plugin | (none) | YES — gap; closure path: future software-domain release |

## §5 Platform-Internal Domain

Skill-embedded templates whose audience is the skill at runtime (not project stakeholders). These are skill-internal scaffolding / authoring guidance, not project artifacts. They remain inside their owning skills' `references/` directories — they are NOT promoted to the canonical registry.

| File | Skill | Purpose | Why platform-internal |
|---|---|---|---|
| `operations/skills/delivery-engine/references/raid-templates.md` | delivery-engine | Mode G runtime guidance for RAID-entry composition | The RAID *log* is the stakeholder artifact (see §3.8); this file is *guidance for filling rows*, consumed by the skill at runtime |
| `core/skills/eval-writer/references/rubric-templates.md` | eval-writer | 7 rubric templates for binary-grader composition (Module 6 §4) | Consumed by eval-writer at authoring time; not produced as a stakeholder artifact |
| `release/skills/pmo-skill-refiner/references/pmo-platform-template.md` | pmo-skill-refiner | Injection-point template for new SKILL.md authoring | Skill-development scaffolding; not a project artifact |
| `release/skills/release-planner/references/release-plan-template.md` | release-planner | Mode B output spec — defines `release/releases/plans/vX.Y_RELEASE_PLAN.md` structure | Skill-internal output spec; the rendered release plan is a platform artifact, but this file is the *spec for the spec* |

## §6 Canon-per-Artifact-Family Mapping (REQUIRED — AC4)

Single authoritative table — 8 rows binding each artifact family to its native canon plus Anthropic plugin cross-reference (per Foundation Stage 5 DD-2 + Stage 4 D4 operator-approved 2026-05-10 per the D-Gate Decision Record). Localization Notes per §7.

| # | Family | Domain | Primary Canon | Anthropic Plugin Cross-Ref | Current Canonical PMO Template | Localization Note |
|---|---|---|---|---|---|---|
| 1 | ADR | software | Nygard, "Documenting Architecture Decisions" (2011) — 4-section structure (Context / Decision / Status / Consequences) | `engineering:architecture` plugin | (none — gap) | Anthropic plugin implements Nygard convention; no CONFLICT |
| 2 | Runbook | software | Google SRE Workbook §Runbook Design | `operations:runbook` plugin (PMO operations role-skill — covers SOPs + recurring task documentation) | (none — gap) | ITIL Service Operation §Operations Management referenced as secondary; align template fields with `operations:runbook` field shape |
| 3 | Design doc | software | Google design-doc convention (Atwood/Henderson templates) — Context/Goals/Non-goals/Proposal/Alternatives/Risks | `engineering:system-design` plugin | (none — gap) | Anthropic plugin co-locates system-design output; PMO template aligns with Google convention referenced therein |
| 4 | RFC | software | IETF RFC 7322 + Rust RFC template | (no Anthropic plugin equivalent) | (none — gap) | Generic heuristic stands without localization; canon coverage complete via upstream documents |
| 5 | PRD / Feature spec | software | Anthropic `product-management:write-spec` plugin convention | `product-management:write-spec` plugin (direct hit per Stage 4 D4) | (none — gap) | Per Stage 4 D4 +  offload-routing: PMO PRD canon IS the Anthropic plugin convention; secondary reference Aha! / Lenny Rachitsky template fills any field-shape gap |
| 6 | Postmortem | software | Google SRE Workbook §Postmortem Culture | `engineering:incident-response` plugin (covers triage + communicate + postmortem) | (none — gap) | Anthropic plugin implements Google SRE postmortem convention; PRINCE2 lessons-learned cross-reference for project-domain instances |
| 7 | Status report | project | PMBOK 7 §Measurement Performance Domain | (no direct plugin; weekly-status-rollup PMO skill consumes) | `executive-status-report-prompt-template.md`, `daily-status-log-template.md`, `daily-status-update-framework-template.md` | Existing canonical templates already PMBOK-aligned operationally; row documents existing convention |
| 8 | Stakeholder Register / RACI | project | PMBOK 7 §Stakeholder Performance Domain +  composition | (no direct plugin; PMO operations role-skills indirectly consume) | (none — gap; ships in a future release) | RAEW / RAS variants noted as references for  authoring |

## §7 Localization Notes (Mechanism 1 audit trail)

For each canon mapping in §6, this section records the Localization Check audit trail per [`decision-discipline.md` § 2.1 Mechanism 1](../disciplines/decision-discipline.md). Each note answers three questions: what generic canon applied; what platform context invalidated reliance on the generic canon alone; what reconciliation was applied.

**Generic heuristic (in absence of localization):** cite the upstream best-practice canon (Nygard / Google SRE / IETF / etc.) and stop there.

**What invalidates the generic heuristic:** PMO has Anthropic plugin skills installed that already implement most of these canons as authoring routes — a row that cites only the upstream canon misses the operational authoring path the PMO skill ecosystem actually uses (per the Anthropic offload-routing pattern). The Anthropic plugin inventory available to this workspace as of 2026-05-10 includes: `engineering:architecture`, `engineering:documentation`, `engineering:debug`, `engineering:incident-response`, `engineering:system-design`, `engineering:testing-strategy`, `product-management:write-spec`, `operations:runbook`, `operations:process-doc`, `customer-support:kb-article`, plus role-suite skills for sales / marketing / data / finance / hr / legal.

**Reconciliation applied per row:** keep the upstream canon as PRIMARY; ADD an Anthropic plugin cross-reference for the 6 rows where a plugin exists. No row CHANGES the underlying canon. Rows 1-3, 5, 6, 7 carry plugin cross-references; row 4 (RFC) and row 8 (Stakeholder Register / RACI) have no Anthropic plugin equivalent and stand on the upstream canon alone.

**Per-row Localization Check status:** load-bearing per `decision-discipline.md § 2.1` (cites specific evidence — system-reminder skills inventory 2026-05-10; articulates heuristic; produces reconciliation). Not optional check-the-box; reconciliation modified DD-2 mapping (added cross-ref column to 6 of 8 rows).

## §8 References

**Primary canons:**
- PMBOK 7 (Performance Domains: Stakeholder / Team / Development Approach + Lifecycle / Planning / Project Work / Delivery / Measurement / Uncertainty)
- Nygard, M., "Documenting Architecture Decisions" (2011) — http://thinkrelevance.com/blog/2011/11/15/documenting-architecture-decisions
- Google SRE Workbook (chapters: Runbook Design + Postmortem Culture) — https://sre.google/workbook/
- IETF RFC 7322 (RFC Style Guide) — https://www.rfc-editor.org/rfc/rfc7322
- Rust RFC template — https://github.com/rust-lang/rfcs

**Anthropic plugin skills inventory (system-reminder skills list, 2026-05-10):**
- `engineering:architecture` (ADR authoring)
- `engineering:documentation` (technical documentation)
- `engineering:incident-response` (triage + communicate + postmortem)
- `engineering:system-design` (system / service design)
- `engineering:testing-strategy` (test plans / test cases)
- `product-management:write-spec` (PRD / feature spec)
- `operations:runbook` (operational runbook authoring)
- `operations:process-doc` (process documentation)

**PMO governance references:**
- Stage 4 Operator Decision Record (2026-05-10) — D1/D2/D3/D4/D5 approval
- D-CanonicalPromote scope expansion (2026-05-10) — Option A approval (project-md-template.md + requirements-template.md promotions)
- R-NEW1 Collective Review Decision Record (2026-05-10) — TEMPLATE_SYNC_MAP scope extension
- Foundation Audit (`pmo-platform/analysis/template-audit-2026-05-10/SUMMARY.md`) — L2 catalog + drift + dedup map
- [`document-ecosystem-design.md` §3 Three-Domain Architecture](../disciplines/document-ecosystem-design.md) — orthogonal `Domain A / B / C` instance-level model
- [`decision-discipline.md` § 2.1 Mechanism 1](../disciplines/decision-discipline.md) — Localization Check load-bearing test
