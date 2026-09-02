---
title: Template Taxonomy — PMO Platform
purpose: Layer 1 of the 5-Layer Template Architecture — the canonical artifact-family taxonomy across project, software, and platform-internal domains, each bound to a named best-practice canon.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: the 5-Layer Template Architecture (L1); template-storage and template-protocol; artifact-generator and the artifact-family-to-best-practice-canon binding
---
<!-- reference-durability: allow-link -->
# Template Taxonomy — PMO Platform

**Last Refreshed:** 2026-07-04
**Authority:** L1 of the 5-Layer Template Architecture. Establishes the canonical artifact-family taxonomy across project + software + platform-internal domains and binds each family to a named best-practice canon.

## §1 Purpose

This document is L1 of the 5-Layer Template Architecture. It defines (a) the **three-domain model** for classifying every PMO template, (b) the **artifact-family taxonomy** within each domain (anchored on PMBOK 7 Performance Domains for project artifacts and on engineering best-practice canons for software artifacts), and (c) the **canon-per-artifact-family mapping** that binds each family to its native external best-practice convention plus any Anthropic plugin cross-reference. It is consumed by L3 Storage (registry layout + propagation declaration), L4 Lifecycle (promotion gates), and L5 Governance (consumer-skill integration). It exists in parallel to (and does not duplicate) the corpus-content taxonomy in the Knowledge Architecture — this document governs the **typed-format axis** (template structure), not the corpus-content axis.

**Reversibility tier:** CHEAP — Confidence: HIGH. This is a doc-only artifact; canon mappings are doc-edit reversible. Coupling intensifies once 5+ consumer skills reference canon-per-template (then MODERATE).

## §2 Three-Domain Model

Every PMO template is classified into exactly one of three domains. The domain determines which canon family applies, where the canonical copy lives, and which audience consumes the rendered artifact.

| Domain | Description | Canon Family | Realized in PMO By |
|---|---|---|---|
| **Project** | Stakeholder-facing artifacts produced during project delivery — trackers and registers, the charter and change/lessons logs, and the shared-entity pages (person, system, vendor, workstream, decision, cross-project dependency) that project artifacts resolve against. Audience: PMs / sponsors / SteerCo / external stakeholders. | PMBOK 7 Performance Domains | 30 artifact families — see §3 for the enumeration and each family's canonical template(s) |
| **Software** | Engineering / technical-decision artifacts. Audience: developers / SREs / architects. | Per-family canon (Nygard / Google SRE / IETF / Rust / Anthropic plugin convention / etc.) | 8 canonical templates — `adr` / `runbook` / `design-doc` / `rfc` / `prd` / `postmortem` / `test-plan` / `qa-acceptance-report` (see §4 + §6) |
| **Platform-internal** | Skill-runtime guidance + skill-internal scaffolding. Audience: the skill itself at runtime, not stakeholders. | n/a (not stakeholder-facing artifacts) | 4 skill-embedded standalone templates (raid-templates, rubric-templates, pmo-platform-template, release-plan-template) |

**Domain boundary rule.** Project-domain artifacts represent project state observable to stakeholders. Software-domain artifacts represent engineering decisions or operations procedures observable to engineers. Platform-internal templates represent skill-runtime authoring guidance — they are not produced as stakeholder-visible artifacts. When a template ambiguously straddles two domains, classify by the audience of the rendered output, not by the audience that consumes the template specification.

### §2.1 Family-Assignment Rule (F-RULE)

A `template_family` names **one rendered-artifact structure**. This rule states the assignment procedure §3–§6 already practice; it codifies, it does not change any existing binding. It is the authority for answering *"does this template need a new family row, or does it bind to an existing one?"* — the question every provenance-header retro-fit has to answer, and the one that produced three different family counts from the same corpus while it was implicit.

**F1 — Domain.** Classify by the *audience of the rendered output*, per §2's Domain boundary rule: stakeholders / operator → `project` (§3); engineers → `software` (§4); the skill itself at runtime → `platform-internal` (§5).

**F2 — Existing-family test.** Does an enumerated family's *rendered structure* already cover this template — same sections or columns, differing only by altitude or variant? If yes, bind to it and add the file to that row's `Current Canonical PMO Template` cell. Do **not** author a new family.

> **F2's discriminator is the field schema, not the page shell.** Two templates that share a heading skeleton but bind different field schemas, different required keys, or different lifecycle state machines are **different families**. Shipped precedent for the granularity: §3.1 carries `Communications Tracker` and `Open Meetings Tracker` as separate families though both render an ID-keyed tracker table, and §3.7 carries three separate status families. Shipped precedent for the collapse: those same three §3.7 families collapse into a single §6 row 7, and §3.1's `Stakeholder Register` + `RACI / RAEW / RAS` collapse into §6 row 8. **§3–§5 enumerate at schema granularity; §6 collapses by shared canon.** A family count and a §6 row count are therefore different measurements and are not expected to match.

**F3 — New family.** Otherwise author a new row in the §3.x sub-table for the template's PMBOK 7 Performance Domain (project domain) or a new §4.x sub-section (software domain). The `template_family:` value is that new **Artifact Family** cell **verbatim** — the field is typed `string (enum)` against this enumeration ([`template-protocol.md`](template-protocol.md) §4.2), so free text is never permitted and a discovery annotation appended to a cell is not part of the value.

**F4 — §6 row.** Add a §6 row **only** when the family binds a *named external canon beyond bare PMBOK 7* or an Anthropic plugin cross-reference. A family standing on a PMBOK 7 Performance Domain alone is fully enumerated by its §3 row and takes no §6 row.

**Cross-reference to ecosystem-design Three-Domain Architecture.** The PMO platform also defines a three-domain instance model in [`document-ecosystem-design.md` §3](../disciplines/document-ecosystem-design.md) (Source Artifacts / Managed Knowledge / Synthesized Intelligence), carried on artifacts as `domain: source | managed | generated` per [`frontmatter-schema.md`](../schemas/frontmatter-schema.md) § Category 6 — the labels `Domain A / B / C` are **deprecated aliases** of those three and readers may still find either during the migration window. That model classifies **instances** by trust + lifecycle. This taxonomy classifies **template structures** by canon family. Both are valid orthogonal axes; a single template instance carries both classifications (e.g., a status report instance is `managed` for trust + `Project` for canon family). No conflict. **Both are `domain`-named, and they are concepts 2 and 5 of six** the bare token names across the corpus — the full index, including the one place the two meet in a single file and how that is resolved, is `core/specs/domain-token-registry.md`.

## §3 Project-Domain Taxonomy (PMBOK 7 Performance Domains)

The PMBOK 7 standard organizes project work into 8 Performance Domains. Each project-domain template anchors to exactly one Performance Domain.

### §3.1 Stakeholder

| Artifact Family | Description | Current Canonical PMO Template | Gap? |
|---|---|---|---|
| Communications Tracker | Log of stakeholder communications + cadence | `operations/templates/communications-tracker-template.md` | No |
| Open Meetings Tracker | Log of stakeholder meetings + outstanding agenda items | `operations/templates/open-meetings-tracker-template.md` | No |
| Stakeholder Register | Identification + classification + engagement strategy per stakeholder | `operations/templates/stakeholder-register-template.csv` | No (shipped; schema in tracker-schemas.md § Tracker 8) |
| RACI / RAEW / RAS | Responsibility-assignment matrix | `operations/templates/raci-template.md` | No (shipped; schema in tracker-schemas.md § Tracker 9) |
| Glossary / Key Terms | Shared-vocabulary index | `operations/templates/key-terms-glossary-template.csv` | No |
| Change Impact Matrix | Structured change-impact analysis per topic (current→future state, impact, stakeholders, mgmt plan) | `operations/templates/change-impact-matrix-template.md` | No |
| Training Plan | Training needs + delivery plan per team (approach, content, topics) | `operations/templates/training-plan-template.md` | No |
| People-Graph Clarification Queue | Work queue of unresolved person-name candidates awaiting operator confirmation before they resolve to a `person_id` | `operations/templates/people-graph-clarification-queue-template.md` | No |
| Person Entity Page | Shared-entity page for one person — the cross-project SSOT on `person_id`, with identity/aliases and per-project allocation | `operations/templates/person-entity-template.md` | No |
| Vendor Entity Page | Shared-entity page for one vendor — profile, category, primary contact, `active → inactive` lifecycle | `operations/templates/vendor-entity-template.md` | No |

### §3.2 Team

| Artifact Family | Description | Current Canonical PMO Template | Gap? |
|---|---|---|---|
| Onboarding / KT doc | Team-onboarding or knowledge-transfer reference | `(none — gap)` | Yes |

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
| Project Charter | Formal project authorization — sponsor mandate, objectives, high-level scope, success criteria | `operations/templates/project-charter-template.md` | No |
| Workstream Entity Page | Shared-entity page for one workstream — scope + deliverables, `BELONGS_TO` project anchor, lead, `active → paused → closed` lifecycle | `operations/templates/workstream-entity-template.md` | No |

### §3.5 Project Work

| Artifact Family | Description | Current Canonical PMO Template | Gap? |
|---|---|---|---|
| Transcript Register | Log of meeting/call transcripts + processing state | `operations/templates/transcript-register-template.md` | No |
| Artifact Register | Per-project configuration-management catalog of project artifacts — version, baseline status, owner, retention (schema in `core/schemas/tracker-schemas.md` § Tracker 6) | `operations/templates/artifact-register-template.md` | No |
| Change Log | Change requests against the project baseline — scope/schedule/cost impact, approval, decision owner (Waterfall change-control log) | `operations/templates/change-log-template.md` | No |
| Lessons Learned | Lessons register — what happened, impact, root cause, recommendation, adoption owner (PRINCE2 lessons log referenced as secondary) | `operations/templates/lessons-learned-template.md` | No |
| System Entity Page | Shared-entity page for one system — profile, owner, `active → deprecated → retired` lifecycle | `operations/templates/system-entity-template.md` | No |

### §3.6 Delivery

(No PMO templates yet — covered by trackers in §3.4 + status reports in §3.7.)

### §3.7 Measurement

| Artifact Family | Description | Current Canonical PMO Template | Gap? |
|---|---|---|---|
| Daily Status Log | Carry-forward log of daily status updates | `operations/templates/daily-status-log-template.md` | No |
| Daily Status Update Framework | Structural framework for daily status messages | `operations/templates/daily-status-update-framework-template.md` | No |
| Executive Status Report Prompt | Template for leadership-ready status reports | `operations/templates/executive-status-report-prompt-template.md` | No |
| Project Rollup (composed) | Per-project portfolio publishing rollup — a composed read-surface over six source entities under the 7-field write-back contract; owns no field it publishes | `operations/templates/project-rollup-template.md` | No |

### §3.8 Uncertainty

| Artifact Family | Description | Current Canonical PMO Template | Gap? |
|---|---|---|---|
| RAID Log | Risks + Assumptions + Issues + Decisions/Dependencies | `operations/templates/raid-log-template.csv` | No |
| Decision Entity Page | Shared-entity page for one decision — statement, rationale, maker, `proposed → accepted → reversed \| superseded` lifecycle. Distinct from the RAID Log's Decision *rows*: the log is a per-project table, this is a per-decision cross-project record | `operations/templates/decision-entity-template.md` | No |
| Cross-Project Dependency Entity Page | Shared-entity page for one directed cross-project dependency — from/to entity refs, kind, `open → satisfied \| broken \| waived` lifecycle. Same distinction from the RAID Log's Dependency rows | `operations/templates/dependency-entity-template.md` | No |

## §3A Portfolio-Framework Families (framework-selected)

Portfolio- and program-tier artifact families supplied by a **selected portfolio governance framework** rather than by the neutral core. These ship only to a deployment that sets `operator.toml [methodology].portfolio_framework`, and they live in a framework-keyed subtree at `operations/templates/portfolio-frameworks/<framework_id>/` per [ADR-170](../ADRs/ADR-170-portfolio-framework-axis-lands-as-template-registry-subtree.md) and [`template-storage.md` §2.4](template-storage.md).

Three things about this section are load-bearing:

1. **It is part of the `template_family` enumeration.** [`template-protocol.md`](template-protocol.md) §4.2 binds the field to *"§3–§5"*, and §3A sits inside that range. A template here takes its `template_family` value verbatim from an Artifact Family cell below, exactly as a §3 template does — no `template-protocol.md` edit is owed to admit them.
2. **These families are excluded from the §2 neutral-core census.** The *"30 artifact families"* figure in §2's Project row counts §3's project-domain families. §3A's 7 are framework-selected, reach only a deployment that opted into their framework, and are **not** added to it. Two different denominators, deliberately: one measures what every deployment receives, the other what a selecting deployment additionally receives.
3. **`domain: project` here means stakeholder-facing, not project-tier.** The domain enum has three members and no portfolio value, and §2's boundary rule classifies by the *audience of the rendered output* — for a portfolio charter that is sponsors and the portfolio governance board, i.e. stakeholders. The collision is with the operational **tier** vocabulary (portfolio → program → project), which is a different axis entirely: every family below is `domain: project` **and** portfolio- or program-**tier**. This is a seventh reading of an already-indexed token, not a new one — see `core/specs/domain-token-registry.md`.

### §3A.1 PMI (`framework_id: pmi`)

Canon: *The Standard for Portfolio Management* (portfolio tier) and *The Standard for Program Management* (program tier), PMI. Framework definition and its selector semantics: [`methodology-archetype-matrix.md` §3A](../../release/references/specs/methodology-archetype-matrix.md).

| Artifact Family | Tier | Description | Current Canonical PMO Template | Gap? |
|---|---|---|---|---|
| Portfolio Charter | portfolio | Authorizes the portfolio — mandate, component-inclusion criteria, prioritization model, governance body and decision rights, funding envelope, portfolio-level success measures, component-removal criteria. Distinct from §3.4 `Project Charter`, which binds one project's sponsor mandate and scope | `operations/templates/portfolio-frameworks/pmi/portfolio-charter-template.md` | No |
| Strategic Alignment Matrix | portfolio | Traceability between organizational objectives and portfolio components, with both orphan directions rendered explicitly — components serving no objective, and objectives no component serves | `operations/templates/portfolio-frameworks/pmi/strategic-alignment-matrix-template.md` | No |
| Portfolio Roadmap | portfolio | Time-phased component schedule, portfolio-visible milestones, cross-component dependencies and capacity conflicts. The unit is a component, not a work item; distinct from an initiative roadmap (a capability through Now/Next/Later with sunset criteria) and from a project plan | `operations/templates/portfolio-frameworks/pmi/portfolio-roadmap-template.md` | No |
| Portfolio Risk Profile | portfolio | Risk appetite, per-category thresholds, aggregate exposure and concentration. **Named *Portfolio* Risk Profile to keep the F2 separation from §3.8 `RAID Log` explicit**: the RAID Log binds per-item rows, this binds thresholds and aggregates, and summing per-item severities is not the same measurement as an appetite threshold | `operations/templates/portfolio-frameworks/pmi/risk-profile-template.md` | No |
| Program Charter | program | Authorizes one program — the coordination rationale (the benefit only coordination produces), component set, target benefits, governance, cross-component dependencies, closure criteria | `operations/templates/portfolio-frameworks/pmi/program-charter-template.md` | No |
| Benefits Realization Plan | program | Per-benefit measurement method with pre-change baseline, realization schedule separating delivered from realized, transition to a named operational owner, and sustainment after program closure | `operations/templates/portfolio-frameworks/pmi/benefits-realization-template.md` | No |
| PROGRAM.md scaffolding | program | The program's standing record — components, benefit standing, governance, open decisions. **Cites** the frozen Program entity field set (`entity-field-schemas.md` §3.14, `V-PROG-01`..`07`, `X-22`/`X-32`) and re-declares none of it | `operations/templates/portfolio-frameworks/pmi/program-md-template.md` | No |

**Why all seven are new families rather than bindings to existing ones (F2 discharge).** §2.1 F2's discriminator is the field schema, not the page shell, and its own note supplies the granularity precedent — §3.1 carries `Communications Tracker` and `Open Meetings Tracker` as separate families though both render an ID-keyed tracker table. Each family above binds a portfolio- or program-tier field schema that no §3 family carries. Same shell, different schema, different family, by the rule's own words.

**§6 rows owed: 2, not 7.** §6 collapses by shared canon (§2.1 F2's note; shipped precedent at rows 7 and 8), and these seven carry exactly two canons — see §6 rows 13–14.

## §4 Software-Domain Taxonomy (engineering best-practice canons)

The software domain organizes around the documents engineers produce. Each artifact family has a named native canon (the upstream best-practice convention) and, where applicable, an Anthropic plugin cross-reference — a convention-anchor that names the plugin authoring convention implementing the same canon, NOT a claim that the plugin is installed today; live availability is re-verified per template at the L4 P5 promotion gate (see §7).

### §4.1 Architecture / Decision (ADR)

| Artifact Family | Primary Canon | Anthropic Plugin Cross-Ref | Current PMO Template | Gap Status |
|---|---|---|---|---|
| ADR | **Nygard, "Documenting Architecture Decisions" (2011)** — 4-section structure (Context / Decision / Status / Consequences) | `engineering:architecture` plugin (described as "Create or evaluate an ADR") | `operations/templates/adr-template.md` | No (shipped) |

### §4.2 Operations / Runbook

| Artifact Family | Primary Canon | Anthropic Plugin Cross-Ref | Current PMO Template | Gap Status |
|---|---|---|---|---|
| Runbook | **Google SRE Workbook §Runbook Design** — secondary: ITIL Service Operation §Operations Management | `operations:runbook` plugin (PMO operations role-skill) | `operations/templates/runbook-template.md` | No (shipped) |

### §4.3 Design / System

| Artifact Family | Primary Canon | Anthropic Plugin Cross-Ref | Current PMO Template | Gap Status |
|---|---|---|---|---|
| Design doc | **Google design-doc convention** (Atwood / Henderson templates) — Context / Goals / Non-goals / Proposal / Alternatives / Risks | `engineering:system-design` plugin | `operations/templates/design-doc-template.md` | No (shipped) |

### §4.4 Specification / Protocol (RFC)

| Artifact Family | Primary Canon | Anthropic Plugin Cross-Ref | Current PMO Template | Gap Status |
|---|---|---|---|---|
| RFC | **IETF RFC 7322** + **Rust RFC template** (https://github.com/rust-lang/rfcs) | (no Anthropic plugin equivalent) | `operations/templates/rfc-template.md` | No |

### §4.5 Product / PRD

| Artifact Family | Primary Canon | Anthropic Plugin Cross-Ref | Current PMO Template | Gap Status |
|---|---|---|---|---|
| PRD / Feature spec | **Anthropic `product-management:write-spec` plugin convention** (per Anthropic offload routing) — secondary: industry practice (Aha! / Lenny Rachitsky template) | `product-management:write-spec` plugin (direct hit) | `operations/templates/prd-template.md` | No |

### §4.6 Reliability / Postmortem

| Artifact Family | Primary Canon | Anthropic Plugin Cross-Ref | Current PMO Template | Gap Status |
|---|---|---|---|---|
| Postmortem | **Google SRE Workbook §Postmortem Culture** | `engineering:incident-response` plugin (covers triage + communicate + postmortem) | `operations/templates/postmortem-template.md` | No |

### §4.7 Quality / Testing

| Artifact Family | Primary Canon | Anthropic Plugin Cross-Ref | Current PMO Template | Gap Status |
|---|---|---|---|---|
| Test plan / Test case | **PMBOK 7 §Quality** + **Anthropic `engineering:testing-strategy` plugin convention** | `engineering:testing-strategy` plugin | `operations/templates/test-plan-template.md` | No |

### §4.8 Quality / Pipeline output (`pipeline-output`)

Pipeline-produced **verdict** artifacts — the report a governed process emits when it *finishes* evaluating something. The discriminator from §4.7 is execution order, not subject matter: **§4.7 is the pre-execution artifact (the test plan — what will be verified and how); §4.8 is the post-execution artifact (the verdict report — what was verified and what the outcome was).** The two share PMBOK 7 §Quality and are separate families because they are produced at opposite ends of the same activity by different authors for different decisions. `pipeline-output` is the greppable category slug for this family; the load-bearing `template_family` value is the Artifact Family cell below.

| Artifact Family | Primary Canon | Anthropic Plugin Cross-Ref | Current PMO Template | Gap Status |
|---|---|---|---|---|
| Acceptance report / Stage verdict report | **PMBOK 7 §Quality** — companion: **ISO/IEC/IEEE 29119-3 §Test Completion Report** (successor to IEEE 829-2008 §Test Summary Report) | (no Anthropic plugin equivalent) | `operations/templates/qa-acceptance-report-template.md` | No (shipped) |

## §5 Platform-Internal Domain

Skill-embedded templates whose audience is the skill at runtime (not project stakeholders). These are skill-internal scaffolding / authoring guidance, not project artifacts. They remain inside their owning skills' `references/` directories — they are NOT promoted to the canonical registry.

| File | Skill | Purpose | Why platform-internal |
|---|---|---|---|
| `operations/skills/delivery-engine/references/raid-templates.md` | delivery-engine | Mode G runtime guidance for RAID-entry composition | The RAID *log* is the stakeholder artifact (see §3.8); this file is *guidance for filling rows*, consumed by the skill at runtime |
| `core/skills/eval-writer/references/rubric-templates.md` | eval-writer | 7 rubric templates for binary-grader composition (Module 6 §4) | Consumed by eval-writer at authoring time; not produced as a stakeholder artifact |
| `release/skills/pmo-skill-refiner/references/pmo-platform-template.md` | pmo-skill-refiner | Injection-point template for new SKILL.md authoring | Skill-development scaffolding; not a project artifact |
| `release/skills/release-planner/references/release-plan-template.md` | release-planner | Mode B output spec — defines `release/releases/plans/vX.Y_RELEASE_PLAN.md` structure | Skill-internal output spec; the rendered release plan is a platform artifact, but this file is the *spec for the spec* |

## §6 Canon-per-Artifact-Family Mapping (REQUIRED — AC4)

Single authoritative table — 14 rows binding each artifact family to its native canon plus Anthropic plugin cross-reference (rows 1–8 per Foundation Stage 5 DD-2 + Stage 4 D4 operator-approved 2026-05-10 per the D-Gate Decision Record; row 9 — Test plan / Test case — added per the D-TaxonomyRowShape operator decision, 2026-07-03; rows 10–11 — Change Impact Matrix + Training Plan — added 2026-07-24 as project-domain §Stakeholder families, both `canon_compat: none`; row 12 — Acceptance report / Stage verdict report — added 2026-08-03 as the §4.8 pipeline-output family, `canon_compat: none`; rows 13–14 — Portfolio-tier + Program-tier governance artifacts (PMI) — added 2026-09-01 as the §3A framework-selected families, both `canon_compat: none`). Localization Notes per §7.

**This table is a canon map over a subset of §3–§5, not a mirror of it.** A family earns a §6 row only when it binds a *named external canon beyond bare PMBOK 7* or an Anthropic plugin cross-reference; families that stand on a PMBOK 7 Performance Domain alone are enumerated in §3 and carry no row here. The enumeration `template_family` is bound to is **§3–§5** (per [`template-protocol.md`](template-protocol.md) §4.2), so §6's row count is always ≤ the §3–§5 family count and the two are not expected to agree. See §2.1 F4.

| # | Family | Domain | Primary Canon | Anthropic Plugin Cross-Ref | Current Canonical PMO Template | Localization Note |
|---|---|---|---|---|---|---|
| 1 | ADR | software | Nygard, "Documenting Architecture Decisions" (2011) — 4-section structure (Context / Decision / Status / Consequences) | `engineering:architecture` plugin | `adr-template.md` | Anthropic plugin implements Nygard convention; no CONFLICT |
| 2 | Runbook | software | Google SRE Workbook §Runbook Design | `operations:runbook` plugin (PMO operations role-skill — covers SOPs + recurring task documentation) | `runbook-template.md` | ITIL Service Operation §Operations Management referenced as secondary; align template fields with `operations:runbook` field shape |
| 3 | Design doc | software | Google design-doc convention (Atwood/Henderson templates) — Context/Goals/Non-goals/Proposal/Alternatives/Risks | `engineering:system-design` plugin | `design-doc-template.md` | Anthropic plugin implements Google design-doc convention; PMO template aligns with that convention |
| 4 | RFC | software | IETF RFC 7322 + Rust RFC template | (no Anthropic plugin equivalent) | `rfc-template.md` | Generic heuristic stands without localization; canon coverage complete via upstream documents |
| 5 | PRD / Feature spec | software | Anthropic `product-management:write-spec` plugin convention | `product-management:write-spec` plugin (direct hit per Stage 4 D4) | `prd-template.md` | Per Stage 4 D4 +  offload-routing: PMO PRD canon IS the Anthropic plugin convention; secondary reference Aha! / Lenny Rachitsky template fills any field-shape gap |
| 6 | Postmortem | software | Google SRE Workbook §Postmortem Culture | `engineering:incident-response` plugin (covers triage + communicate + postmortem) | `postmortem-template.md` | Anthropic plugin implements Google SRE postmortem convention; PRINCE2 lessons-learned cross-reference for project-domain instances |
| 7 | Status report | project | PMBOK 7 §Measurement Performance Domain | (no direct plugin; weekly-status-rollup PMO skill consumes) | `executive-status-report-prompt-template.md`, `daily-status-log-template.md`, `daily-status-update-framework-template.md` | Existing canonical templates already PMBOK-aligned operationally; row documents existing convention |
| 8 | Stakeholder Register / RACI | project | PMBOK 7 §Stakeholder Performance Domain +  composition | (no direct plugin; PMO operations role-skills indirectly consume) | `stakeholder-register-template.csv`, `raci-template.md` (schemas in tracker-schemas.md §§ Tracker 8-9) | RAEW / RAS variants noted as references for  authoring |
| 9 | Test plan / Test case | software | PMBOK 7 §Quality + Anthropic `engineering:testing-strategy` plugin convention | `engineering:testing-strategy` plugin | `test-plan-template.md` | Dual-anchor family — PMBOK 7 §Quality (quality-management framing) + plugin convention (engineer-facing structure); plugin availability re-verified at promotion per L4 P5; registered per the D-TaxonomyRowShape operator decision (2026-07-03) |
| 10 | Change Impact Matrix | project | PMBOK 7 §Stakeholder Performance Domain | (no Anthropic plugin equivalent) | `change-impact-matrix-template.md` | Project-domain OCM change-impact artifact; no Anthropic plugin counterpart — stands on the PMBOK 7 §Stakeholder canon alone (`canon_compat: none`, P5 path c-i); one of the first two project-domain templates to carry the L4 provenance header (added 2026-07-24) |
| 11 | Training Plan | project | PMBOK 7 §Stakeholder Performance Domain | (no Anthropic plugin equivalent) | `training-plan-template.md` | Project-domain stakeholder-enablement artifact; no Anthropic plugin counterpart — stands on the PMBOK 7 §Stakeholder canon alone (`canon_compat: none`, P5 path c-i); column model aligns with the change-management skill's `references/training-plan.md` (added 2026-07-24) |
| 12 | Acceptance report / Stage verdict report | software | PMBOK 7 §Quality + ISO/IEC/IEEE 29119-3 §Test Completion Report | (no Anthropic plugin equivalent) | `qa-acceptance-report-template.md` | Dual-anchor family — PMBOK 7 §Quality (quality-management framing) + ISO/IEC/IEEE 29119-3 §Test Completion Report (report structure; successor to the withdrawn IEEE 829-2008 §Test Summary Report). **Post-execution counterpart to row 9**: row 9 is the pre-execution test plan, row 12 the verdict report that closes the same activity. No Anthropic plugin counterpart, so it stands on the external canon alone (`canon_compat: none`, **P5 path c-ii** — `domain: software` with a named external canon and no plugin equivalent). Category slug `pipeline-output`; §4.8 (added 2026-08-03) |
| 13 | Portfolio-tier governance artifacts (PMI) | project | *The Standard for Portfolio Management* (PMI) | (no Anthropic plugin equivalent) | `portfolio-frameworks/pmi/portfolio-charter-template.md`, `strategic-alignment-matrix-template.md`, `portfolio-roadmap-template.md`, `risk-profile-template.md` | **Framework-selected**, not neutral-core — these ship only where `[methodology].portfolio_framework = "pmi"`. Collapses the four §3A portfolio-tier families by their shared canon, on the rows 7–8 precedent. Binds a named external canon beyond bare PMBOK 7, which is what earns the row per §2.1 F4; no Anthropic plugin counterpart, so `canon_compat: none`, **P5 path c-i** (`domain: project` with no plugin equivalent). Added 2026-09-01 |
| 14 | Program-tier governance artifacts (PMI) | project | *The Standard for Program Management* (PMI) | (no Anthropic plugin equivalent) | `portfolio-frameworks/pmi/program-charter-template.md`, `benefits-realization-template.md`, `program-md-template.md` | **Framework-selected**, not neutral-core. Collapses the three §3A program-tier families by their shared canon. **Program-tier is a distinct canon from row 13's portfolio tier**, which is why these do not collapse into one row: a program coordinates components toward benefits and ends, a portfolio governs standing component admission. `canon_compat: none`, **P5 path c-i**. The `PROGRAM.md scaffolding` family cites the frozen Program entity schema rather than re-declaring it. Added 2026-09-01 |

## §7 Localization Notes (Mechanism 1 audit trail)

For each canon mapping in §6, this section records the Localization Check audit trail per [`decision-discipline.md` § 2.1 Mechanism 1](../disciplines/decision-discipline.md). Each note answers three questions: what generic canon applied; what platform context invalidated reliance on the generic canon alone; what reconciliation was applied.

**Generic heuristic (in absence of localization):** cite the upstream best-practice canon (Nygard / Google SRE / IETF / etc.) and stop there.

**What invalidates the generic heuristic:** several of these canons have a named Anthropic-plugin authoring convention — a row that cites only the upstream canon misses the operational authoring route the PMO skill ecosystem maps to (per the Anthropic offload-routing pattern). These plugin references are **convention-anchors**: each names the plugin authoring convention its canon corresponds to, NOT a claim that the plugin is installed today. A 2026-05-10 system-reminder skills-list snapshot observed `engineering:architecture`, `engineering:documentation`, `engineering:debug`, `engineering:incident-response`, `engineering:system-design`, `engineering:testing-strategy`, `product-management:write-spec`, `operations:runbook`, `operations:process-doc`, `customer-support:kb-article`, plus role-suite skills for sales / marketing / data / finance / hr / legal. **That snapshot is superseded:** a 2026-07-03 re-survey (`~/.claude/plugins/installed_plugins.json` plus the official-marketplace roster) found the `engineering:*`, `product-management:*`, and `operations:*` suites **absent** — see the Row 9 addendum below, which is the governing statement of live availability. The canon bindings are load-bearing regardless of install state; live plugin availability is re-verified per template at the L4 P5 promotion gate.

**Reconciliation applied per row:** keep the upstream canon as PRIMARY; ADD an Anthropic plugin cross-reference — a convention-anchor naming the plugin's authoring convention, never an install claim — for the 6 rows where a plugin is named (rows 1–3, 5, 6 at the 2026-05-10 D-Gate; row 9 at its 2026-07-03 addition). No row CHANGES the underlying canon. Rows 1-3, 5, 6, and 9 carry plugin cross-references; row 4 (RFC), row 7 (Status report — consumed by a PMO skill, no Anthropic plugin), row 8 (Stakeholder Register / RACI), rows 10–11 (Change Impact Matrix, Training Plan), row 12 (Acceptance report / Stage verdict report), and rows 13–14 (Portfolio-tier + Program-tier governance artifacts, PMI) have no Anthropic plugin equivalent and stand on the upstream canon alone. *(Rows 10–11 were added to this enumeration 2026-08-03 alongside row 12 — they were `canon_compat: none` from their 2026-07-24 registration and the omission was a transcription gap, not a classification.)*

**Per-row Localization Check status:** load-bearing per `decision-discipline.md § 2.1` (cites specific evidence — system-reminder skills inventory 2026-05-10; articulates heuristic; produces reconciliation). Not optional check-the-box; reconciliation modified DD-2 mapping (added cross-ref column to 6 of the then-8 rows).

**Row 9 addendum (Test plan / Test case — registered 2026-07-04 per the D-TaxonomyRowShape operator decision, 2026-07-03):** Generic heuristic: cite PMBOK 7 §Quality plus the `engineering:testing-strategy` plugin convention and stop there. Localization: at registration the live plugin inventory was re-verified — the `engineering:*`, `product-management:*`, and `operations:*` plugin suites named in the 2026-05-10 inventory above are absent from the installed-plugin inventory and the current official-marketplace roster (survey 2026-07-03: `~/.claude/plugins/installed_plugins.json` + `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/`). Reconciliation: the canon bindings stand — each canon is the documented convention, not the plugin install; plugin cross-references remain the named authoring routes; live plugin availability is re-verified per template at the P5 promotion gate (`template-protocol.md` §6), which is where a persistent absence forces a canon_compat re-decision.

## §8 References

**Primary canons:**
- PMBOK 7 (Performance Domains: Stakeholder / Team / Development Approach + Lifecycle / Planning / Project Work / Delivery / Measurement / Uncertainty)
- Nygard, M., "Documenting Architecture Decisions" (2011) — http://thinkrelevance.com/blog/2011/11/15/documenting-architecture-decisions
- Google SRE Workbook (chapters: Runbook Design + Postmortem Culture) — https://sre.google/workbook/
- IETF RFC 7322 (RFC Style Guide) — https://www.rfc-editor.org/rfc/rfc7322
- Rust RFC template — https://github.com/rust-lang/rfcs

**Anthropic plugin convention-anchors** — the authoring-route conventions the §6 rows cross-reference. Observed in a 2026-05-10 system-reminder skills list; **re-surveyed 2026-07-03**, which found the `engineering:*`, `product-management:*`, and `operations:*` suites absent from `~/.claude/plugins/installed_plugins.json` and the official-marketplace roster. These entries therefore name each canon's plugin authoring convention and are **not** a live-install claim; the canon bindings stand regardless, and availability is re-verified per template at the L4 P5 promotion gate (see §7 Row 9 addendum):
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
- Foundation Audit (`<OPERATOR_INSTANCE_ANALYSIS_PATH>/template-audit-2026-05-10/SUMMARY.md`) — L2 catalog + drift + dedup map
- [`document-ecosystem-design.md` §3 Three-Domain Architecture](../disciplines/document-ecosystem-design.md) — orthogonal `Domain A / B / C` instance-level model
- [`decision-discipline.md` § 2.1 Mechanism 1](../disciplines/decision-discipline.md) — Localization Check load-bearing test
