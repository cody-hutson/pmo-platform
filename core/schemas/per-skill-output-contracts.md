---
title: Per-Skill Output Contracts
purpose: Defines the exact output structure each skill must produce per mode — the per-skill, per-mode contract the QA Auditor validates structural compliance against.
type: schema
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: pmo-qa-auditor (structural compliance per skill per mode); every skill (its own contract); output-format.md and agent-processing-contracts.md
---
<!-- reference-durability: allow-link -->
# Per-Skill Output Contracts
<!-- design-artifact: flow-class=data-flow; name=per-skill-output-contracts; depicts=core/skills/README.md,operations/skills/README.md,release/skills/README.md -->

**Compliance:** all Skills 1-12 meet the reversibility / evidence-label / G7 failure-mode standards.

## Purpose
Defines the exact output structure each skill must produce for each mode. Used by the QA Auditor to validate structural compliance. Each skill has its own contract evaluated against its own specification.

---

## Skill 1: PPM Agent (Tier 1 — Strategic Brain)

### Output Contract (7 Required Sections)

| Section | Content | Format | Notes |
|---------|---------|--------|-------|
| 1. Executive Narrative | Decision-grade summary of program state and recommended actions | 6–10 lines, prose | Must be actionable; summarizes Sections 2–7 |
| 2. Program Snapshot | Project name, phase, health (R/Y/G), current sprint, next milestone, critical path item(s) | Structured data (table or list) | Single source of truth for program health |
| 3. Resolved Actions | Drafted emails, RAID updates, meeting packages with readiness gate | Paste-ready blocks | Each artifact labeled: READY FOR SEND \| NOT READY |
| 4. Items Requiring Your Action | Sends, schedules, decisions, approvals with owner and deadline | Bulleted list or table | Owner ≠ PPM Agent (typically) |
| 5. Decisions Needed | Context, options, tradeoffs, recommendation, reversibility, deadline, decision-maker | Structured format | One row per decision |
| 6. Top Risks | Description, probability, impact, trigger, owner, mitigation, deadline; [NEW]/[UPDATED] labels | Table or structured list | Max 5 risks per run; sorted by exposure (P × I) |
| 7. Dependencies and Blockers | Inter-project, inter-team, vendor, and technical dependencies with status and owner | Bulleted list or table | Status: On Track \| At Risk \| Blocked |

### Required Elements

**Evidence Quality Tags:**
- All claims tagged with `[EVIDENCE: source]` or `[ASSUMPTION – CONFIRM: proposed answer]`
- Sources: RAID log, meeting transcript, ticket system, comms, domain knowledge

**Follow-up Tags:**
- Used to flag gaps requiring specialist routing
- Format: `[TAG: Context/Source/Scope/Inputs/Constraints]`
- Permitted tags: `[DELIVERY]`, `[COMMS]`, `[TECHNICAL]`, `[PROCESS]`, `[CHANGE]`
- Max depth: 2 (no tag chains)

**RAID Entries:**
- Prefix: `R-PPM-###` (e.g., R-PPM-001)
- Include in Section 3 (Resolved Actions) as paste-ready blocks
- Dual output format when creating RAID entry

**Dual Output:**
- Applies when producing artifacts (emails, RAID entries, meeting packages)
- Artifact shown in Section 3; metadata summarized in Sections 4–5
- Exception: If artifact marked NOT READY, include in Section 5 (Items for Your Action) with remediation gap

### Reversibility Tier + Confidence

Output class → default tier + confidence (per `../specs/reversibility-protocol.md`):

| Output class | Tier | Confidence |
|---|---|---|
| Recommendations (Section 1 narrative; Section 5 decision packages) | CHEAP / MODERATE per action class | HIGH (evidence strong) / MEDIUM (cross-project inference) / LOW (assumption-heavy) |
| RAID entries (R-PPM-###) | CHEAP | HIGH (file entries, revertable) |
| Status assessments (Sections 2, 6, 7) | CHEAP | HIGH (reports, revertable) |

Every decision-class item carries tier + confidence explicitly. No unlabeled recommendations.

### Evidence Labels

All factual claims carry one of the 5 evidence labels per CLAUDE.md § Universal Preferences: `[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, `[RECOMMENDED]`. Section 1-2 claims and Section 6 risks: `[SOURCE]` on transcripts/exports; `[INFERRED]` on cross-project correlations.

### Failure-Mode Conformance (G7)

`ppm-agent/SKILL.md` must contain ≥ 3 domain-specific failure modes per `../standards/failure-mode-standard.md` with 5-field template + category tag (TRIG / INPUT / PROC / OUT / HAND). G7 Phase 1 regex: `## Domain-Specific Failure Modes` heading + ≥ 3 `### <Title> — <CATEGORY>` sub-headings.

### Validation Checklist (QA Gate)
- [ ] All 7 sections present
- [ ] Executive Narrative is 6–10 lines and decision-grade
- [ ] Program Snapshot includes all 6 data points
- [ ] Readiness gate applied to all artifacts in Section 3
- [ ] Evidence tags on all claims in Sections 1–2
- [ ] Follow-up tags properly formatted (max depth 2)
- [ ] RAID entries use R-PPM-### prefix
- [ ] Dual output: artifact + metadata
- [ ] Top risks sorted by exposure (P × I)

---

## Skill 2: Delivery Engine (Tier 1 — Operational Backbone)

### Modes (7 Total)

| Mode | Trigger | Output Focus |
|------|---------|--------------|
| (A) Backlog Ingestion & Health Scan | New backlog exported or updated | Ticket classification, debt detection, refinement readiness |
| (B) Ticket Insight / Similarity | Ad-hoc ticket deep-dive or cross-ticket pattern analysis | Root cause, scope, risk, related tickets |
| (C) Refinement Manager (DoR Gate) | Pre-refinement check or backlog review | DoR compliance per ticket; gates |
| (D) Sprint Planning | Sprint kickoff input | Capacity, velocity, risk, dependencies |
| (E) Execution Control Tower | During sprint (mid-sprint or daily standup context) | Burndown, blockers, risk escalation, capacity adjustment |
| (F) DoD + Release Readiness Gate | End of sprint or pre-release | Acceptance criteria, test coverage, deployment readiness |
| (G) RAID / Decision / Milestone Artifact Update | Manual trigger or PPM Agent referral | Update to shared RAID/decision/milestone log |

### Output Contract (8 Sections + Change Summary)

| Section | Content | Format | Notes |
|---------|---------|--------|-------|
| 1. Mode & Inputs | Mode name, timestamp, source system [SOURCE] labels, relevant URLs/IDs | Metadata | [SOURCE] labels on all external data |
| 2. Summary | 3–5 lines, decision-grade finding or recommendation | Prose | Answer the question "Why does this matter?" |
| 3. Gate Results | Per-item evaluation (PASS / CONDITIONAL PASS / FAIL) for evaluative modes | Table or list | Only in modes C, D, F, G |
| 4. Findings & Remediations | Observation, evidence, impact, completed remediation (if any) | Structured blocks | One block per finding; linked to gate result |
| 5. Paste-Ready Artifacts | Copy/paste-ready blocks (ticket updates, sprint notes, status fields) | Code blocks | Labeled with target system and section |
| 6. Checklists | Mode-specific checklist (e.g., "Definition of Ready" for mode C) | Checkbox list | Clear pass/fail per item |
| 7. Next Actions | Owner, deadline, context, link to findings | Table | Owner ≠ Delivery Engine (typically) |
| 8. RAID Updates | Dual-output RAID entries for risks, decisions, or milestones | Paste-ready | Prefix: R-DE-### |
| Change Summary | (Appended) Summary of all updates to tracked artifacts | Bullet list | See Tier 2 protocol |

### Required Elements

**Dual-Framing Bridge (Agile + Waterfall Framing):**
- Applied when milestone or phase context is available and relevant
- Format: "In [phase], this [ticket/finding] affects [waterfall milestone/gate]"
- Example: "In Design phase, this integration risk may delay the 'API contract finalization' milestone (planned 2026-04-15)"
- Condition: Omit if milestone context unavailable; never invent waterfall mapping

**Gate Results:**
- Mandatory in modes C, D, F, G
- Format: `[Item ID]: PASS | CONDITIONAL PASS (condition) | FAIL (reason)`
- CONDITIONAL PASS includes explicit condition for pass-to-full-pass

**Dual Output (RAID entries):**
- RAID entry in Section 8 (paste-ready)
- Metadata in Section 7 (Next Actions) with deadline and owner

### Reversibility Tier + Confidence

Output class → default tier + confidence (per `../specs/reversibility-protocol.md`):

| Output class | Tier | Confidence |
|---|---|---|
| Gate results (modes C, D, F, G — PASS / CONDITIONAL PASS / FAIL) | CHEAP | HIGH |
| Sprint plans (mode D) | MODERATE | MEDIUM (capacity commitments) |
| RAID entries (R-DE-###) | CHEAP | HIGH |
| Findings & remediations (Section 4) | CHEAP / MODERATE per remediation class | HIGH (evidence-tied) / MEDIUM (heuristic) |

Every decision-class item carries tier + confidence explicitly.

### Evidence Labels

All factual claims carry one of the 5 evidence labels per CLAUDE.md § Universal Preferences: `[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, `[RECOMMENDED]`. Section 1 `[SOURCE]` on Jira / tool data; `[INFERRED]` on velocity derivations.

### Failure-Mode Conformance (G7)

`delivery-engine/SKILL.md` must contain ≥ 3 domain-specific failure modes per `../standards/failure-mode-standard.md` with 5-field template + category tag (TRIG / INPUT / PROC / OUT / HAND). G7 Phase 1 regex: `## Domain-Specific Failure Modes` heading + ≥ 3 `### <Title> — <CATEGORY>` sub-headings.

### Validation Checklist (QA Gate)
- [ ] All 8 sections present
- [ ] Mode and inputs identified with [SOURCE] labels
- [ ] Summary is 3–5 lines and decision-grade
- [ ] Gate results present (modes C, D, F, G only); PASS/CONDITIONAL/FAIL
- [ ] Each gate result linked to finding in Section 4
- [ ] Evidence tags on all findings
- [ ] Paste-ready artifacts include target system and section
- [ ] Checklists match mode specification
- [ ] RAID entries use R-DE-### prefix
- [ ] Dual-Framing Bridge present (if milestone context available)
- [ ] Change Summary appended
- [ ] Follow-up tags properly formatted (max depth 2)

---

## Skill 3: Comms Writer (Tier 1 — Voice of PMO)

### Communication Types (6 primary + 2 owned-generation)

The catalog is **name-keyed** (no `Type N` ordinals — renumber-proof). The **6 primary
PMO-unique types** are the dispatch catalog; **executive brief** and **stakeholder email**
are **owned-generation** types — comms-writer owns their generation first-party (own-with-harvest;
first-party, no runtime Anthropic dependency), with structure harvested at design time
from `product-management/stakeholder-comms` (catalogued in `../standards/upstream-reference-catalog.md`,
entry `stakeholder-comms-structure`).

| Type | Class | Audience | Channel | Typical Context |
|------|-------|----------|---------|-----------------|
| Meeting Agenda | primary | Meeting attendees (known group) | Email / Confluence | Pre-meeting prep |
| Meeting Recap | primary | Meeting attendees + distribution list | Email / Confluence | Post-meeting documentation |
| Escalation | primary | Sponsor, steering committee, executive leadership | Email / Confluence | Risk materialization, blocker, change in scope |
| Announcement | primary | All-hands or department | Email / Confluence / Teams | Go-live, phase transition, policy change |
| Confluence Documentation | primary | Knowledge base users, project team | Confluence | SOP update, reference material, playbook |
| Teams Message | primary | Real-time collaboration (team or channel) | Teams | Quick coordination, hypercare alert, standup supplement |
| Stakeholder Email | owned-generation (own-with-harvest; first-party, no runtime Anthropic dependency) | Executive, sponsor, cross-functional lead | Email | Ad-hoc decisions, status updates, escalations |
| Executive Brief | owned-generation (own-with-harvest; first-party, no runtime Anthropic dependency) | Executive team, C-suite | Email / Confluence / PDF | Strategic summary, quarterly health, major changes |

### Output Contract (6 Required Sections)

| Section | Content | Format | Notes |
|---------|---------|--------|-------|
| 1. Communication Metadata | Type, audience, channel, urgency (Routine / Time-Sensitive / Urgent), rationale | Structured | Sets context for reviewability |
| 2. Readiness Assessment | READY FOR SEND \| NOT READY with specific gaps | Decision gate | Blocks Send action; shows remediation path |
| 3. The Draft | Complete, copy/paste-ready communication | Native format (email, markdown, etc.) | For email/Teams: inherently paste-ready |
| 4. Compliance Check | (Conditional) Verification of brand, tone, legal, accessibility | Bullet checklist | Only if org-wide or escalation type |
| 5. Audience Notes | (Conditional) Guidance on audience sensitivities, context, known concerns | Prose | Helps recipient contextualize the communication |
| 6. Alternative Versions | (Conditional) Multi-audience variants (e.g., exec-friendly vs. team-friendly) | Multiple drafts | Only if significant audience gap exists |

### Required Elements

**READY/NOT READY Gate:**
- Mandatory decision gate on all communications
- READY = all claims have evidence; no [ASSUMPTION] tags; tone appropriate; compliance check (if applicable) passed
- NOT READY = specific gaps listed (e.g., "Missing decision from sponsor on timeline"; "Tone too casual for executive brief")
- If any claim tagged [ASSUMPTION], draft is NOT READY

**Evidence Quality Tags:**
- All factual claims tagged `[EVIDENCE: source]` or `[ASSUMPTION – CONFIRM: proposed]`
- Sources: RAID log, transcript, meeting notes, ticket, domain knowledge

**Dual Output Exception:**
- Email and Teams messages are inherently paste-ready (no dual output needed)
- Confluence/doc updates follow dual output protocol: draft shown in Section 3; metadata + target location in Section 4

**Tone & Accessibility:**
- All drafts reviewed for accessibility (plain language, active voice, numbered lists)
- Escalation drafts reviewed for urgency framing (clear ask, context, deadline)

**SIOR Escalation Structure (Escalation type):**
- Escalation-type output uses the SIOR block per [`sior-escalation-protocol.md`](../standards/sior-escalation-protocol.md):
  Situation / Impact / Options (2–3 with trade-offs) / Recommendation (with explicit confidence level).
- The Recommendation is mandatory and explicit; an Ask may accompany it but never replaces it
  (Recommendation ≠ Ask).
- Severity-threshold policy (when SIOR fires) is the canonical table in the protocol doc — CRITICAL
  always / HIGH with authority check / MEDIUM conditional-on-blocks-downstream.

### Reversibility Tier + Confidence

Output class → default tier + confidence (per `../specs/reversibility-protocol.md`):

| Output class | Tier | Confidence |
|---|---|---|
| READY drafts (Stakeholder Email, Meeting Recap, Doc Update) | CHEAP | HIGH (recallable, revisable) |
| Escalation drafts | MODERATE | MEDIUM (stakeholder perception impact, hard to fully recall once sent) |
| Executive Briefs / Org-Wide Announcements | MODERATE | HIGH per evidence quality |
| NOT READY drafts | CHEAP | n/a (gated, not for send) |

Every decision-class item carries tier + confidence explicitly. NOT READY status itself is a decision-class output (CHEAP / HIGH).

### Evidence Labels

All factual claims in drafts carry one of the 5 evidence labels per CLAUDE.md § Universal Preferences: `[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, `[RECOMMENDED]`. NOT READY status REQUIRES `[ASSUMPTION – CONFIRM]` tags on every unverified claim — that is the gate signal.

### Failure-Mode Conformance (G7)

`comms-writer/SKILL.md` must contain ≥ 3 domain-specific failure modes per `../standards/failure-mode-standard.md` with 5-field template + category tag (TRIG / INPUT / PROC / OUT / HAND). G7 Phase 1 regex: `## Domain-Specific Failure Modes` heading + ≥ 3 `### <Title> — <CATEGORY>` sub-headings.

### Validation Checklist (QA Gate)
- [ ] All 6 sections present
- [ ] Communication metadata complete (type, audience, channel, urgency)
- [ ] READY/NOT READY gate applied; if NOT READY, specific gaps listed
- [ ] Evidence tags on all factual claims; no [ASSUMPTION] tags if marked READY
- [ ] Draft is complete and copy/paste-ready
- [ ] Compliance check present (org-wide or escalation types)
- [ ] Escalation-type drafts carry a full SIOR block with an explicit Recommendation + confidence level
- [ ] Audience notes present (if needed)
- [ ] Alternative versions present (if significant audience gap)
- [ ] Tone appropriate for type and audience
- [ ] No links to external systems without context or approval

---

## Skill 4: Change Management (Tier 2 — Specialist)

### Modes (6 Total)

| Mode | Trigger | Output Focus |
|------|---------|--------------|
| (A) Change Impact Assessment | New change request or scope change | Scope, stakeholders, training needs, risk |
| (B) Training Plan | Post-design or pre-UAT | Training audience, content, delivery, success metrics |
| (C) Readiness Checklist | Pre-cutover or pre-hypercare | Readiness gates, training completion, comms, support |
| (D) Hypercare Plan | Post-go-live or during hypercare window | T-minus schedule, escalation paths, support model, comms cadence |
| (E) Change Matrix Ingestion | Multi-change governance or wave planning | Cross-change dependencies, wave sequencing, comms coordination |
| (F) CM Communications Schedule | Any mode output requiring multi-wave comms | T-minus schedule of all communications with owner and readiness |

### Output Contract (8 Sections + Change Summary)

| Section | Content | Format | Notes |
|---------|---------|--------|-------|
| 1. Mode & Inputs | Mode name, trigger, source system [SOURCE] labels, stakeholder list | Metadata | [SOURCE] on all external data |
| 2. Summary | 3–5 sentences, decision-grade finding or recommendation | Prose | "Why does this matter for change adoption?" |
| 3. Assessment / Plan / Checklist | Mode-specific output (impact assessment, training plan, readiness checklist, schedule) | Structured (table, checklist, timeline) | See mode-specific detail below |
| 4. Findings & Gaps | Observation, evidence, impact, remediation | Structured blocks | Linked to mode-specific output |
| 5. Paste-Ready Artifacts | Copy/paste-ready blocks for Confluence, email, spreadsheet | Code blocks | Target: Confluence → [Active Project] → Change Management |
| 6. Change Summary | Summary of all change tracking updates | Bullet list | Part of Tier 2 protocol |
| 7. Next Actions | Owner, deadline, context | Table | Owner ≠ Change Manager (typically) |
| 8. RAID Updates | Dual-output RAID entries for change risks or decisions | Paste-ready | Prefix: R-CM-### |

### Mode-Specific Detail

**Mode (A) – Change Impact Assessment:**
- Scope definition: affected systems, users, processes, data
- Stakeholder map: primary, secondary, tertiary with sentiment (supporter / neutral / resistor)
- Training needs: audience, topic, duration, format
- Comms plan (outline): phases, key messages, channels
- Risk factors: adoption risk, technical risk, organizational risk

**Mode (B) – Training Plan:**
- Target audiences: role-based or department-based
- Content outline: topics, depth, hands-on vs. knowledge
- Delivery method: live, self-paced, blended, on-demand
- Schedule: start date, duration, completions required by go-live
- Success metrics: completion %, assessment scores, post-training survey

**Mode (C) – Readiness Checklist:**
- Training completion (by audience)
- Comms completion (by wave)
- Support readiness (help desk trained, documentation ready)
- Hypercare plan (on standby)
- Stakeholder signoff (by role)

**Mode (D) – Hypercare Plan:**
- T-minus schedule: all comms, escalations, reviews from go-live to hypercare close
- Support model: triage, escalation, office hours
- Metrics dashboard: adoption, defects, satisfaction
- Exit criteria: when does hypercare end?
- Go/no-go decision points

**Mode (E) – Change Matrix Ingestion:**
- Cross-change dependency map: which changes affect which other changes
- Wave sequencing: recommended order, rationale, risks
- Comms coordination: deduplication, single-message framing

**Mode (F) – CM Communications Schedule:**
- T-minus timeline: every communication (pre-announcement, training prep, go-live, hypercare, closeout)
- Audience per communication: who gets what message when
- Owner per communication: who sends it (comms writer, change manager, sponsor)
- Readiness per communication: links to draft or placeholder

### Boundary Condition
Mode (F) produces T-minus schedule; individual communication drafts are tagged `[COMMS]` for routing to Comms Writer skill.

### Required Elements

**Change Summary (Tier 2 Protocol):**
- Part of Section 6; summarizes all changes to operational documents
- Format: "Updated [artifact name] with [what changed] per [evidence source]"

**Dual Output (RAID entries):**
- RAID entry in Section 8 (paste-ready)
- Metadata in Section 7 (Next Actions) with deadline and owner

### Reversibility Tier + Confidence

Output class → default tier + confidence (per `../specs/reversibility-protocol.md`):

| Output class | Tier | Confidence |
|---|---|---|
| Change impact assessments (mode A) | CHEAP | MEDIUM (recommendations, reversible) |
| Training plans (mode B) | MODERATE | MEDIUM (commitments to audiences, schedules) |
| Readiness checklists (mode C) | CHEAP | HIGH (gate state, revertable) |
| Hypercare plans (mode D) | MODERATE | HIGH (operational commitments through hypercare window) |
| RAID entries (R-CM-###) | CHEAP | HIGH |

Every decision-class item carries tier + confidence explicitly.

### Evidence Labels

All factual claims carry one of the 5 evidence labels per CLAUDE.md § Universal Preferences: `[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, `[RECOMMENDED]`.

### Failure-Mode Conformance (G7)

`change-management/SKILL.md` must contain ≥ 3 domain-specific failure modes per `../standards/failure-mode-standard.md` with 5-field template + category tag (TRIG / INPUT / PROC / OUT / HAND). G7 Phase 1 regex: `## Domain-Specific Failure Modes` heading + ≥ 3 `### <Title> — <CATEGORY>` sub-headings.

### Validation Checklist (QA Gate)
- [ ] All 8 sections present
- [ ] Mode and inputs identified with [SOURCE] labels
- [ ] Summary is 3–5 sentences and decision-grade
- [ ] Mode-specific output (A–F) fully specified
- [ ] Findings linked to assessments/plans/checklists
- [ ] Evidence tags on all observations
- [ ] Paste-ready artifacts include target location (Confluence path)
- [ ] RAID entries use R-CM-### prefix
- [ ] Change Summary appended and linked to evidence
- [ ] Communications tagged [COMMS] for routing
- [ ] Follow-up tags properly formatted (max depth 2)

---

## Skill 5: Technical Analyst (Tier 2 — Specialist)

### Modes (5 Total)

| Mode | Trigger | Output Focus |
|------|---------|--------------|
| (A) FDD Review | FDD version released or updated | Completeness, consistency, technical clarity, risk gaps |
| (B) Integration Spec / IDD Review | Integration design document or interface definition released | Interface completeness, protocol compliance, error handling, data mapping |
| (C) Architecture / Infrastructure Review | Architecture diagram, infrastructure spec, or environment plan released | Scalability, security, operational readiness, dependency clarity |
| (D) SOP / Operational Readiness Review | Standard operating procedures or operational runbooks released | Completeness, clarity, contingency procedures, runbook accuracy |
| (E) Cross-Artifact Technical Risk Assessment | Multi-document review (FDD + architecture + infrastructure) | Coherence, technical debt, integration risk, operational risk |

### Output Contract (8 Sections + Change Summary)

| Section | Content | Format | Notes |
|---------|---------|--------|-------|
| 1. Mode & Inputs | Mode name, document names, version numbers, [SOURCE] labels | Metadata | [SOURCE] on all external artifacts |
| 2. Technical Summary | 5–8 lines covering scope, key findings, and technical impact | Prose | Written for technical and non-technical readers |
| 3. Risk Matrix | 6-dimensional assessment: integration, data, performance, security, environment, operational | Table with R/Y/G rating per dimension | Sorted by severity; linked to findings in Section 4 |
| 4. Gap Analysis | Completeness gaps, ambiguity, missing detail, inconsistencies across artifacts | Structured blocks | Evidence-linked; impact rated (critical / major / minor) |
| 5. Dependency Map | System-to-system, service-to-service, vendor, environmental dependencies with status | Diagram or table | Status: Known \| At Risk \| Unverified |
| 6. Drafted Remediations | Proposed fixes, clarifications, additions to close gaps | Paste-ready blocks | Linked to gaps; includes acceptance criteria |
| 7. Next Actions | Owner, deadline, context | Table | Owner typically ≠ Technical Analyst |
| 8. RAID Updates | Dual-output RAID entries for technical risks or decisions | Paste-ready | Prefix: R-TA-### |
| Change Summary | Summary of operational artifact updates | Bullet list | Part of Tier 2 protocol |

### Risk Matrix Detail

| Dimension | Definition | Examples |
|-----------|-----------|----------|
| Integration | Cross-system interfaces, API contracts, data flow consistency | Missing error handling, version mismatch, breaking changes |
| Data | Data model consistency, completeness, transformation, mapping | Ambiguous field semantics, missing validation, truncation risk |
| Performance | Latency, throughput, scalability, resource consumption | Unverified load limits, missing indexing, N+1 queries |
| Security | Authentication, authorization, encryption, secrets management | Missing SSL verification, exposed credentials, injection risk |
| Environment | Infrastructure readiness, environment parity, deployment automation | Unprovisioned resources, environment drift, deployment manual steps |
| Operational | Runbook completeness, monitoring, alerting, incident response | Missing escalation path, unclear troubleshooting steps, no alerting |

### Tag Emission (Important)

**Can emit:**
- `[DELIVERY]` — If gap affects delivery timeline or sprint capacity
- `[CHANGE]` — If gap affects training, comms, or organizational readiness

**Cannot emit:**
- `[TECHNICAL]` (self-referential; redundant)
- Other tags

**Constraint:**
- Max depth 2 (no tag chains)

### Required Elements

**Change Summary (Tier 2 Protocol):**
- Part of Section 8; links to operational artifacts updated

**Dual Output (RAID entries):**
- RAID entry in Section 8 (paste-ready)
- Metadata in Section 7 (Next Actions) with deadline and owner

### Reversibility Tier + Confidence

Output class → default tier + confidence (per `../specs/reversibility-protocol.md`):

| Output class | Tier | Confidence |
|---|---|---|
| Risk matrices (Section 3) | CHEAP | varies with evidence quality (HIGH if FDD-grounded; MEDIUM if inferred) |
| Drafted remediations (Section 6) | MODERATE | MEDIUM (implementation implications carry through to delivery) |
| Architecture / infrastructure assessments (mode C) | MODERATE / EXPENSIVE per scope | varies with evidence |
| RAID entries (R-TA-###) | CHEAP | HIGH |

Every decision-class item carries tier + confidence explicitly.

### Evidence Labels

All factual claims carry one of the 5 evidence labels per CLAUDE.md § Universal Preferences: `[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, `[RECOMMENDED]`.

### Failure-Mode Conformance (G7)

`pmo-technical-analyst/SKILL.md` must contain ≥ 3 domain-specific failure modes per `../standards/failure-mode-standard.md` with 5-field template + category tag (TRIG / INPUT / PROC / OUT / HAND). G7 Phase 1 regex: `## Domain-Specific Failure Modes` heading + ≥ 3 `### <Title> — <CATEGORY>` sub-headings.

### Validation Checklist (QA Gate)
- [ ] All 8 sections present
- [ ] Mode and inputs identified with [SOURCE] labels
- [ ] Technical Summary is 5–8 lines and covers scope + findings + impact
- [ ] Risk Matrix includes all 6 dimensions; R/Y/G ratings assigned
- [ ] Gap Analysis blocks linked to risk matrix dimensions
- [ ] Impact ratings present (critical / major / minor)
- [ ] Dependency Map includes all external dependencies
- [ ] Remediations are paste-ready with acceptance criteria
- [ ] RAID entries use R-TA-### prefix
- [ ] Change Summary appended and linked to evidence
- [ ] Follow-up tags ([DELIVERY], [CHANGE] only); max depth 2
- [ ] Evidence tags on all findings

---

## Skill 6: Process Designer (Tier 2 — Specialist)

### Modes (5 Total)

| Mode | Trigger | Output Focus |
|------|---------|--------------|
| (A) Requirements Definition | New requirements document or requirements backlog | Completeness, clarity, traceability to process, feasibility |
| (B) Process Documentation | Process diagram, flowchart, or SOP release | Completeness, clarity, decision clarity, exception handling |
| (C) Gap Analysis | Compare-as-is vs. to-be or requirements vs. process | Gap identification, impact, remediation, traceability |
| (D) Traceability Matrix | Create or validate bidirectional linking (requirement → process → test) | Chain integrity, orphaned requirements, missing test coverage |
| (E) Requirements Review (Cross-Artifact) | Multi-document review (FDD + requirements + process) | Coherence, scope creep, feasibility, change impact |

### Output Contract (8 Sections + Change Summary)

| Section | Content | Format | Notes |
|---------|---------|--------|-------|
| 1. Mode & Inputs | Mode name, source documents, version numbers, [SOURCE] labels | Metadata | [SOURCE] on all external artifacts |
| 2. Process / Requirements Summary | 3–5 sentences covering scope, key findings, process/requirement integrity | Prose | Written for process and requirements audiences |
| 3. Structured Output | Mode-specific output (requirements list, process diagram, gap table, traceability matrix, coherence assessment) | Structured (table, diagram, checklist) | See mode-specific detail below |
| 4. Gap Analysis | Missing steps, ambiguous decisions, missing exception handling, orphaned requirements | Structured blocks | Evidence-linked; impact rated |
| 5. Findings | Scope issues, requirement conflicts, feasibility concerns, change impact | Structured blocks | Linked to gaps and mode-specific output |
| 6. Drafted Remediations | Proposed additions, clarifications, deletions | Paste-ready blocks | Linked to gaps; includes acceptance criteria |
| 7. Next Actions | Owner, deadline, context | Table | Owner typically ≠ Process Designer |
| 8. RAID Updates | Dual-output RAID entries for requirements decisions or risks | Paste-ready | Prefix: R-PD-### |
| Change Summary | Summary of operational artifact updates | Bullet list | Part of Tier 2 protocol |

### Mode-Specific Detail

**Mode (A) – Requirements Definition:**
- Requirements list: ID, description, priority (must/should/nice), traceability to stakeholder, acceptance criteria
- Completeness check: Are all stakeholder needs articulated?
- Clarity check: Can the delivery team understand and estimate?
- Feasibility assessment: Dependencies, constraints, risks

**Mode (B) – Process Documentation:**
- Process steps: sequence, decision points, exceptions, roles
- Clarity check: Can operators execute without ambiguity?
- Exception handling: What happens on error? Who escalates?
- Decision clarity: Are all gates, approvals, criteria explicit?

**Mode (C) – Gap Analysis:**
- As-is process summary
- To-be process summary (or desired state)
- Gap table: gap ID, description, impact, remediation, owner, deadline
- Scope impact: Does gap change project scope or timeline?

**Mode (D) – Traceability Matrix:**
- Bidirectional linking: Requirement ↔ Process ↔ Test
- Chain integrity metrics: % fully traced, % orphaned requirements, % untested processes
- Broken link identification: Which requirements have no process? Which processes have no test?

**Mode (E) – Requirements Review (Cross-Artifact):**
- Coherence: Do FDD, requirements, and process align?
- Scope creep detection: Are new requirements hiding in process docs?
- Feasibility: Are requirements achievable within constraints?
- Change impact: Do requirement changes propagate to process and test?

### Required Elements

**Bidirectional Process-Requirements Linking:**
- Hard rejection if bidirectional linking not enforced or broken
- Example: If requirement R-001 has no corresponding process step, R-001 is "orphaned" and chain is broken
- Chain integrity metrics must be calculated and shown

**Change Summary (Tier 2 Protocol):**
- Part of Section 8; links to operational artifacts updated

**Dual Output (RAID entries):**
- RAID entry in Section 8 (paste-ready)
- Metadata in Section 7 (Next Actions) with deadline and owner

### Reversibility Tier + Confidence

Output class → default tier + confidence (per `../specs/reversibility-protocol.md`):

| Output class | Tier | Confidence |
|---|---|---|
| Requirements (mode A — REQ-###) | MODERATE | MEDIUM (drive downstream design + delivery commitments) |
| Gap analyses (mode C) | CHEAP | HIGH (analysis output, revertable) |
| Traceability matrices (mode D) | CHEAP | HIGH (computed from existing IDs) |
| Process documentation (mode B) | MODERATE | MEDIUM (operator-executed; ambiguity creates rework) |
| RAID entries (R-PD-###) | CHEAP | HIGH |

Every decision-class item carries tier + confidence explicitly.

### Evidence Labels

All factual claims carry one of the 5 evidence labels per CLAUDE.md § Universal Preferences: `[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, `[RECOMMENDED]`.

### Failure-Mode Conformance (G7)

`pmo-process-designer/SKILL.md` must contain ≥ 3 domain-specific failure modes per `../standards/failure-mode-standard.md` with 5-field template + category tag (TRIG / INPUT / PROC / OUT / HAND). G7 Phase 1 regex: `## Domain-Specific Failure Modes` heading + ≥ 3 `### <Title> — <CATEGORY>` sub-headings.

### Validation Checklist (QA Gate)
- [ ] All 8 sections present
- [ ] Mode and inputs identified with [SOURCE] labels
- [ ] Summary is 3–5 sentences and covers scope + findings + integrity
- [ ] Mode-specific output (A–E) fully specified
- [ ] Gap Analysis blocks linked to mode output
- [ ] Impact ratings present (critical / major / minor)
- [ ] Bidirectional linking enforced (hard rejection if broken)
- [ ] Chain integrity metrics calculated (if mode D or E)
- [ ] Remediations are paste-ready with acceptance criteria
- [ ] RAID entries use R-PD-### prefix
- [ ] Change Summary appended and linked to evidence
- [ ] Follow-up tags properly formatted (max depth 2)
- [ ] Evidence tags on all findings

---

## Skill 7: PMO QA Auditor (Meta — Quality Gate)

### Modes (9 Total)

| Mode | Trigger | Output Focus |
|------|---------|--------------|
| (A) Single Output Review | Any skill output delivered | 6-gate structural compliance review |
| (B) Cross-Skill Coherence Review | Multiple skill outputs related to same topic or artifact | Consistency, contradiction detection, missing connections |
| (C) Push-to-Resolve Audit | Ad-hoc quality gate (triggered by PPM Agent or Delivery Engine) | Structural + content + actionability audit |
| (D) Document Management Compliance | Periodic audit of operational documents (RAID, decisions, milestones) | Naming, dating, ownership, archival compliance |
| (E) Platform Health Audit | "platform health audit", base-vs-build drift check, quarterly / drift-watch scheduled task | Observational base-vs-build drift + Failure-Mode Detector Battery → dated audit folder (no gate verdict) |
| (F) Release-Process Fitness Audit | "release-process fitness audit", a process-fitness cadence event or the 90-day sentinel | 13-dimension pipeline fitness (1–5) + UNTRACKED / PARTIAL / ALREADY-TRACKED classification → dated audit folder |
| (G) Dev Testing | "dev-test this PR", Stage-7 Dev Testing spoke (PR + release plan) | Stage-7 Quality Review Report (eval-assertion ladder; PASS / CONDITIONAL PASS / FAIL) posted as a PR comment |
| (H) Acceptance Review | "acceptance review this PR", Stage-8 QA invocation (PR + issue AC) | Per-criterion Stage-8 six-value verdicts + acceptance score → Acceptance Report |
| (I) As-Built Architecture-Conformance Audit | "as-built architecture-conformance audit", an architecture-conformance cadence event or the 90-day sentinel | Observational audit of delivered work (release record) vs the architecture baseline — conformance-drift + candidate cross-release fragmentation → dated audit folder + committed conformance-summary surface (no gate verdict; auto-files nothing) |

> **Output-contract scope.** The `### Output Contract` gate-table below frames the **gate-table
> modes (A–D)** — the consumer/reviewer modes that emit the QA Audit Report header + a gate
> results table. The **producer / stage modes (E–I)** each emit their own output contract
> documented in `pmo-qa-auditor/SKILL.md § Mode-specific output variations`, not this gate
> table: E/F/I emit a **dated on-disk audit folder** under the observational audit-class
> discipline (I additionally overwrites the committed
> `release/releases/architecture-conformance-summary.md` hand-off surface consumed by
> health-check); G emits the Stage-7 Quality Review Report as a PR comment; H emits the
> Stage-8 Acceptance Report. None of E–I emits a PASS/FAIL gate verdict.

### Output Contract

| Section | Content | Format | Notes |
|---------|---------|--------|-------|
| 1. QA Audit Report Header | Mode, timestamp, artifact(s) audited, auditor | Metadata | Clear identification of what was audited |
| 2. Gate Results Table | PASS / FAIL per gate with evidence | Table | See 6 gates below; one result per gate |
| 3. Findings | Location, what's wrong, why it matters, exact remediation text | Structured blocks | If any FAIL, remediation text is mandatory |
| 4. Summary Assessment | Overall quality (PASS / CONDITIONAL PASS / FAIL), confidence, rework estimate | Prose | Decision-grade conclusion |

### 6 Quality Gates (G1–G6)

All gates apply to all skills unless marked otherwise.

| Gate | Definition | Applies To | Failure Criteria |
|------|-----------|-----------|-----------------|
| **G1: Structural Completeness** | All required sections present per skill contract | All skills | Missing section; incomplete section |
| **G2: Evidence Quality** | All claims tagged [EVIDENCE] or [ASSUMPTION]; [ASSUMPTION] tags only in NOT READY items | All skills | Untagged claim; [ASSUMPTION] in READY item; untraced evidence source |
| **G3: Decision Clarity** | Output includes clear recommendation or decision gate (READY/NOT READY, PASS/FAIL, etc.) | All skills | Ambiguous recommendation; missing gate result; contradictory gates |
| **G4: Artifact Readiness** | All paste-ready artifacts are truly paste-ready (no placeholders, no TODOs) | All skills except QA Auditor | Placeholder text; [TODO] markers; incomplete sections in paste-ready blocks |
| **G5: Follow-up Routing** | Follow-up tags properly formatted and within max depth 2 | All skills | Malformed tag; depth > 2; tag to self (e.g., [TECHNICAL] from Technical Analyst) |
| **G6: Dual Output** | Artifacts and metadata both present; RAID entries include both entry and next-action metadata | Delivery Engine, Change Mgmt, Technical, Process Designer | Missing metadata; RAID entry without next-action link; artifact shown without target location |

### Reversibility Tier + Confidence

Output class → default tier + confidence (per `../specs/reversibility-protocol.md`):

| Output class | Tier | Confidence |
|---|---|---|
| Audit verdicts (PASS / CONDITIONAL PASS / FAIL) | CHEAP | HIGH per gate evidence |
| Finding remediations (Section 3 — exact remediation text) | CHEAP | HIGH (file-level edits, revertable) |
| Summary assessments (Section 4) | CHEAP | HIGH per gate-result aggregation |

Every decision-class item carries tier + confidence explicitly.

### Evidence Labels

All factual claims carry one of the 5 evidence labels per CLAUDE.md § Universal Preferences: `[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, `[RECOMMENDED]`. Auditor uses `[SOURCE]` for skill-output excerpts; `[INFERRED]` for cross-finding pattern detection.

### Failure-Mode Conformance (G7)

`pmo-qa-auditor/SKILL.md` must contain ≥ 3 domain-specific failure modes per `../standards/failure-mode-standard.md` with 5-field template + category tag (TRIG / INPUT / PROC / OUT / HAND). G7 Phase 1 regex: `## Domain-Specific Failure Modes` heading + ≥ 3 `### <Title> — <CATEGORY>` sub-headings.

### Validation Checklist (QA Auditor Self-Check)

- [ ] Mode identified and artifact(s) listed
- [ ] All 6 gates evaluated (G1–G6)
- [ ] Gate results (PASS / FAIL) with evidence
- [ ] Findings include exact remediation text
- [ ] Summary assessment is decision-grade (PASS / CONDITIONAL / FAIL)
- [ ] Confidence level stated (high / medium / low)
- [ ] Rework estimate provided (hours or effort range)
- [ ] Report is paste-ready and ready for review

---

## Skill 8: PMO Skill Editor (Meta — Suite Maintenance)

### Modes (4 Total)

| Mode | Trigger | Output Focus |
|------|---------|--------------|
| (A) Edit Mode | Requested change to skill spec, prompt, or output format | Change summary, regression test scope |
| (B) Coherence Check | Cross-skill validation (e.g., verify all skills emit consistent RAID prefixes) | Inconsistencies flagged and prioritized |
| (C) Regression Mode | Post-edit validation (re-run skill on previous test cases) | Pass/fail per test case, delta analysis |
| (D) Quality Audit | Master audit of all 8 skill specs against CLAUDE.md and per-skill-output-contracts.md | Compliance checklist, deviations flagged |

### Output Contract

| Section | Content | Format | Notes |
|---------|---------|--------|-------|
| 1. Change Summary | What changed, why, impact scope (which skills affected) | Bullet list | Evidence-linked |
| 2. Cross-Skill Impact Report | Dependencies, cascading changes, tier implications | Table | Scope: All 8 skills |
| 3. Regression Results | Per-test-case pass/fail, delta analysis (before/after) | Table or structured list | Links to test case ID |
| 4. Updated .skill File | Complete updated skill spec with version bump | Code block | Ready for commit |
| 5. Master Plan Update Recommendations | Changes to per-skill-output-contracts.md, OPERATIONS.md, or CLAUDE.md | Structured list | Conditional: only if meta-spec needs updating |

### Required Elements

**Change Summary:**
- Links to evidence (e.g., ticket ID, meeting transcript, QA audit finding)
- Impact assessment: which skills, which modes, severity (breaking / non-breaking)

**Cross-Skill Impact Report:**
- Tier implications: Does change affect Tier 1 (PPM Agent, Delivery Engine, Comms Writer)? Tier 2?
- Dependency chain: If Skill A changes, which skills depend on Skill A output?

**Regression Results:**
- Test case ID, mode, input, expected output, actual output
- Pass/fail per case
- Delta: what changed from previous run (if any)

**Version Bump:**
- Semantic versioning: Major.Minor.Patch
- Breaking change = Major bump
- New capability = Minor bump
- Bug fix = Patch bump

### Reversibility Tier + Confidence

Output class → default tier + confidence (per `../specs/reversibility-protocol.md`):

| Output class | Tier | Confidence |
|---|---|---|
| Skill edits (Section 4 — Updated .skill File) | CHEAP / MODERATE depending on scope | HIGH (skill-level edits revertable per file) |
| Version bumps (Section 4) | CHEAP | HIGH |
| Master Plan recommendations (Section 5 — changes to per-skill-output-contracts.md / OPERATIONS.md / CLAUDE.md) | MODERATE | MEDIUM (cross-skill propagation; governance-doc edits require approval gate) |
| Regression results (Section 3) | CHEAP | HIGH per test-case evidence |

Every decision-class item carries tier + confidence explicitly.

### Evidence Labels

All factual claims carry one of the 5 evidence labels per CLAUDE.md § Universal Preferences: `[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, `[RECOMMENDED]`.

### Failure-Mode Conformance (G7)

`pmo-skill-editor/SKILL.md` must contain ≥ 3 domain-specific failure modes per `../standards/failure-mode-standard.md` with 5-field template + category tag (TRIG / INPUT / PROC / OUT / HAND). G7 Phase 1 regex: `## Domain-Specific Failure Modes` heading + ≥ 3 `### <Title> — <CATEGORY>` sub-headings.

### Validation Checklist (QA Auditor Self-Check for Skill Editor)

- [ ] All 4 sections present
- [ ] Change Summary includes evidence links and impact assessment
- [ ] Cross-Skill Impact Report covers all affected skills
- [ ] Regression Results include all test cases with pass/fail
- [ ] .skill file updated with version bump
- [ ] Master Plan recommendations included (if applicable)
- [ ] No regression failures unresolved

---

## Skill 9: Build Reviewer (Meta — Production-Readiness Review)

### Modes (4 Total)

| Mode | Trigger | Output Focus |
|------|---------|--------------|
| (A) Copilot Builder Pack Review | Final-round review of Copilot Builder Agent Document Pack (30 docs + 1 derived artifact) | 12 Copilot-specific dimensions + 3 Principal dimensions; findings register using CS1..CS4 severity |
| (B) PMO Platform Review | Production-readiness review of pmo-platform/ (skills, governance, reference docs, pipeline stages, suite contracts) | 12 PMO-platform dimensions across 4 areas + 3 Principal dimensions; findings register using CRITICAL/HIGH/MEDIUM/LOW severity |
| (C) Generic Document Pack Review | Review of any document pack without a domain-specific pack match | 7 baseline dimensions + 3 Principal dimensions; fallback-banner when auto-selected; findings register using CRITICAL/HIGH/MEDIUM/LOW severity |
| (D) Multi-Pack Cross-Cutting Review | Review targets that span multiple domains (e.g., a PMO-platform skill that references Copilot-builder content) | Invokes multiple packs in sequence; cross-domain findings surfaced as systemic patterns |

**Pack selection:** Mode = the pack selected at invocation. User-specified `--pack=<name>` wins; otherwise path-pattern inference against pack `detection_patterns`; otherwise default to `generic` (triggers fallback banner). See `release/skills/build-reviewer/references/dimension-packs/README.md` for the pack registry and detection rules.

### Output Contract (4 Sections + 6 Summary Deliverables)

| Section | Content | Format | Notes |
|---------|---------|--------|-------|
| 1. Review Metadata | Pack loaded (name + version), domain-detection result (user-specified / path-pattern / fallback), target files, review round number, operator profile, severity scale in use | Metadata block | Identifies the scope and calibration of this review pass; fallback banner (when applicable) is rendered here |
| 2. Review Summary | 3-5 lines, PASS / CONDITIONAL / FAIL verdict derived from critical-path count and systemic-pattern risk | Prose | Verdict is decision-grade; PASS = zero critical-path findings; CONDITIONAL = all critical paths have accepted residual-risk disposition; FAIL = any unresolved critical path |
| 3. Findings Register | All findings using the 11-field per-finding format from SKILL.md + Reversibility Tier + Confidence (12 fields total) | Structured table or blocks | Every finding has: Finding ID, Dimension, Severity, Affected Document(s), Affected Section(s), Finding Description, Root Cause, Evidence, Risk if Unresolved, Recommended Resolution, Resolution Complexity, Reversibility Tier + Confidence |
| 4. Summary Deliverables | The 6 deliverables from `review-discipline-principles.md` § Section 5 | Nested subsections | See 6 sub-items below |

**Summary Deliverables (mirrors `review-discipline-principles.md` § Section 5):**
- **(a) Findings register** — all findings in the structured format of Section 3
- **(b) Critical path findings** — subset of the findings register whose unresolved state would cause production failure
- **(c) Systemic pattern analysis** — recurring root causes classified per Section 3 of review-discipline-principles.md (design flaws / implementation gaps / interface mismatches / governance failures / capacity shortfalls)
- **(d) Residual risk register** — risks consciously carried forward with disposition reason and monitoring criteria per Section 4
- **(e) Complexity assessment** — honest evaluation of whether the target's complexity is proportionate to its goals
- **(f) Remediation priority** — ordered list (blocking-effect first, systemic-pattern fixes next, isolated findings last) with justification per ordering decision

### Required Elements

**Evidence Quality Labels:**
- All factual claims in findings carry `[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, or `[RECOMMENDED]` per CLAUDE.md § Universal Preferences.

**Reversibility Tier + Confidence (per G4):**
- Every decision-class output carries a tier (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) paired with a confidence level (HIGH / MEDIUM / LOW) per `reversibility-protocol.md`.
- Decision-class outputs: per-finding Recommended Resolution, per-finding Resolution Complexity, Critical Path findings list, Systemic Pattern recommendations, Residual Risk register entries, Complexity Assessment, Remediation Priority items. See SKILL.md § Reversibility Discipline for the enumeration and label formats.

**Failure-Mode Discipline on Review Output:**
- Reviewer posture validated against `review-discipline-principles.md` § Section 7 (reviewer bias, finding inflation, scope creep, self-referential validation) — posture failures are themselves findings against the review.

**Generic-Fallback Banner:**
- When Mode C fires via fallback (not explicit `--pack=generic`), the findings register renders a banner at the top: `_Generic pack used — no domain-specific pack matched the target. Consider authoring a pack for this domain if reviews recur._`

**3 Principal Dimensions (always rendered):**
- Operational Awareness, Organizational Leverage, Mentorship & Culture — applied to every review regardless of pack selection per SKILL.md § Principal Dimensions.

**Severity Scale Consistency (per Rule 7):**
- Copilot-builder pack uses CS1..CS4; pmo-platform and generic packs use CRITICAL/HIGH/MEDIUM/LOW per `review-discipline-principles.md` § Section 5. Choose one form per review and apply consistently — no mixing.

### Validation Checklist (QA Gate)

- [ ] Section 1 Review Metadata present (pack, version, detection result, target files, round, operator profile, severity scale)
- [ ] Section 2 Review Summary present (3-5 lines, PASS/CONDITIONAL/FAIL verdict)
- [ ] Section 3 Findings Register present (all 12 fields per finding including Reversibility Tier + Confidence)
- [ ] Section 4 Summary Deliverables present (all 6 sub-items per review-discipline-principles.md Section 5)
- [ ] Summary (a) Findings register populated
- [ ] Summary (b) Critical path findings identified and cross-referenced to register Finding IDs
- [ ] Summary (c) Systemic pattern analysis with Section 3 category tags
- [ ] Summary (d) Residual risk register with monitoring criteria per risk
- [ ] Summary (e) Complexity assessment delivered
- [ ] Summary (f) Remediation priority ordered with justification
- [ ] Reversibility tier + confidence on every decision-class item (G4 check)
- [ ] Evidence labels on every factual claim (G2 check)
- [ ] Root-cause chain present for every finding per Section 2 format
- [ ] Findings register covers every dimension in the loaded pack + 3 Principal Dimensions
- [ ] Fallback banner present when Mode C fires by fallback (not by `--pack=generic` override)

---

## Skill 10: Implementation Planner (Meta — Remediation Planning)

**Purpose:** Converts build-reviewer findings registers into sequenced, minimal-change remediation implementation plans for any governed document pack — Copilot Builder Agent, PMO platform, or generic. Applies the Minimal-Change Remediation Bias and the RT-1..RT-8 remediation-type taxonomy. Output is Edit-ready (fenced `edit`/`bash` blocks) for direct consumption by Claude Code's native Edit and Bash tools per the reference workflow in `release/references/how-to/implementation-execution-pattern.md` .

**Skill source:** [`release/skills/implementation-planner/SKILL.md`](../../release/skills/implementation-planner/SKILL.md)
**Domain packs:** [`release/skills/implementation-planner/references/domain-packs/README.md`](../../release/skills/implementation-planner/references/domain-packs/README.md)
**Output format:** [`release/skills/implementation-planner/references/output-format-spec.md`](../../release/skills/implementation-planner/references/output-format-spec.md)

### Modes

- **Mode A — Copilot Builder Pack Planning.** Invoked when the findings register targets the Copilot Builder Agent Document Pack. Activates `copilot-builder` pack with CS1..CS4 severity scale, constitutional-first sequencing, RT-6/RT-7 applicable (Runtime_Constitutional_Minimum_Set regeneration + Doc 28 manifest update).
- **Mode B — PMO Platform Pack Planning.** Invoked when the findings register targets PMO skills, governance files, reference docs, pipeline stages, or suite contracts. Activates `pmo-platform` pack with CRITICAL..LOW severity scale, governance-first sequencing, RT-6/RT-7 N/A by default.
- **Mode C — Generic Document Pack Planning.** Fallback when no domain-specific pack matches. Activates `generic` pack with dependency-first sequencing, mandatory fallback banner at top of Implementation Register, RT-6/RT-7 excluded unless `--rt-extensions` override.

No Mode D cross-cutting — planning is pack-scoped by definition (findings register comes from one build-reviewer pack invocation).

### Output Contract (6 Sections)

- **Section 1 — Plan Metadata.** Pack loaded (pack_name, pack_version), domain detection result (user-specified / path-pattern / fallback), findings count, review round, operator profile (from pack `operator_profile_default` or future  project-level derivation).
- **Section 2 — Plan Summary.** 3-5 lines — e.g., "5 critical, 12 high, 30 medium findings; 8 batches; 2 RT-5 coordinations; ~47 edits estimated".
- **Section 3 — Implementation Register (table).** `RI-ID | Finding ID | Validation | Severity (original) | Severity (normalized) | Remediation Type | Primary File | Batch | Blast Radius | Reversibility`. Fallback banner (when generic pack selected by fallback) appears at top of this section.
- **Section 4 — Detailed Implementation Records.** Edit-ready per [`reference/output-format-spec.md`](../../release/skills/implementation-planner/references/output-format-spec.md). Every RI-NNN renders as fenced `edit` block (RT-1..RT-5), fenced `bash` block (RT-6/RT-7), or Markdown register entry (RT-8). Every record carries the Metadata block with Finding Validation + evidence label, Severity (original + normalized), Remediation Type, Reversibility tier + Confidence, Blast Radius, Regression scope, pre-computed Version log entry, Rationale.
- **Section 5 — Execution Batch Plan.** Sequenced batches with dependencies, scope descriptions, document-touch counts. Ordering per active pack's `sequencing_rules_ref` section (e.g., copilot-builder's `#constitutional-first-sequencing`). Batch size limits per active pack's `batch_limits` frontmatter.
- **Section 6 — Accepted Residual Risk Register Additions + Remediation Summary Statistics + Complexity Self-Audit.** RT-8 records formatted as register rows (per the active pack's register format). Summary statistics table (findings received / confirmed / not confirmed / per-RT counts / total batches / total files touched / estimated total edits). 5-point over-remediation / cascade / new-control / regression-proportionality / net-complexity self-audit.

### Required Elements

- **Evidence labels** on all factual claims (per CLAUDE.md § Universal Preferences — SOURCE, INFERRED, ASSUMPTION–CONFIRM, CONTEXT, RECOMMENDED).
- **Reversibility tier + confidence** on all decision-class items (per SKILL.md Anti-Laziness Rule #8 and the `## Reversibility Discipline` + `## Principal Dimensions — Sub-dimension 1` sections).
- **Severity dual-annotation** (original + normalized) on all RIs (per `## Severity Normalization`).
- **Edit-ready format** per `reference/output-format-spec.md` on all RI-NNN records (RT-1..RT-5 `edit` blocks; RT-6/RT-7 `bash` blocks; RT-8 markdown register entries).
- **Pack-selection visible in Section 1** — the loaded pack name + detection method + version must appear in Plan Metadata so downstream audits can trace which pack's semantics governed the plan.
- **Fallback banner** (when generic pack selected by fallback) — verbatim text at top of Section 3 Implementation Register: `_Generic pack used — no domain-specific pack matched the target. Consider authoring a pack for this domain if planning recurs._`

### Structural Checks (for QA Auditor reference — add to Validation Rules table)

- **G1 (Structural Completeness):** 6 sections (Plan Metadata / Summary / Register / Records / Batch Plan / Residuals+Stats+Audit).
- **G2 (Evidence Quality):** ✓ on all factual claims in every RI Metadata block.
- **G3 (Decision Clarity):** Severity normalization table applied; every RI carries both tokens; RT classification rationale inline; finding validation outcome (CONFIRMED / CONFIRMED_WITH_ADJUSTMENT / NOT_CONFIRMED) explicit.
- **G4 (Artifact Readiness):** ✓ — Edit-ready `edit`/`bash` blocks directly consumable; no prose-style "current text" / "replacement text" specifications.
- **G5 (Follow-up Routing):** N/A — planner role.
- **G6 (Dual Output):** ✓ (Plan artifact + Execution-pattern handoff per D13).
- **Reversibility:** ✓ (tier + confidence on every decision-class item per Anti-Laziness Rule #8).
- **Mode Identification:** ✓ (3 modes — one per pack).
- **Risk Matrix:** N/A — risks surface in RT-8 accepted-residuals rather than a standalone matrix.
- **Readiness Gate:** ✓ (Complexity Self-Audit in Section 6 is the pre-execution readiness check).
- **Artifact Target Location:** ✓ (absolute `file_path` in every `edit` block per output-format-spec.md Section 3).
- **RAID Entry Prefix:** `R-IP-###` (RI-NNN records surface in downstream RAID when RT-5 coordination risks or RT-8 residuals are adopted).

### Appendix: RAID Entry Prefix Reference (add to existing table at § Appendix)

- **Implementation Planner** — `R-IP-###` — example: `R-IP-042 (Risk: RT-5 coordination constraint pending workflow-executor verification per implementation-execution-pattern.md)`.

---

## Skill 11: PMO Skill Refiner (Meta — Factory)

**Purpose:** Creates and refines PMO-platform skills by wrapping an Anthropic scaffolding skill (default: `anthropic-skills:skill-creator`; alternative on operator request: `cowork-plugin-management:create-cowork-plugin`) with a PMO refinement layer. Interview mode captures structured intent; Create-New and Refine-Existing modes apply the 7 PMO injection fields (delivery_approach, output-contract stub, dependency-graph node, evidence-quality protocol, domain-specific failure modes, Principal Standard target, reversibility discipline) and run the preserved eval harness (variance analysis, blind A/B comparison, description-trigger optimization loop). Replaces the deprecated `skill-creator` skill. See `release/skills/pmo-skill-refiner/SKILL.md`.

**Skill source:** [`release/skills/pmo-skill-refiner/SKILL.md`](../../release/skills/pmo-skill-refiner/SKILL.md)
**References:** [`pmo-platform-template.md`](../../release/skills/pmo-skill-refiner/references/pmo-platform-template.md), [`pmo-platform-context.md`](../../release/skills/pmo-skill-refiner/references/pmo-platform-context.md), [`pmo-antipatterns.md`](../../release/skills/pmo-skill-refiner/references/pmo-antipatterns.md), [`eval-framework.md`](../../release/skills/pmo-skill-refiner/references/eval-framework.md), [`regression-protocol.md`](../../release/skills/pmo-skill-refiner/references/regression-protocol.md)

### Modes (3 Total)

| Mode | Trigger | Output Focus |
|------|---------|--------------|
| (A) Interview | Any invocation of pmo-skill-refiner | Structured intent packet — 9 questions covering purpose, triggers (T1/T2 evidence), output format + decision-class, delivery_approach, failure modes, dependencies, shared contracts, Principal Standard target, principal-vs-junior gradients |
| (B) Create New Skill | Interview packet + "new skill" intent | New SKILL.md with 7 PMO fields injected into Anthropic scaffold; eval harness run; trigger-description optimized; output contract, dependency-graph node, regression-checks entry registered |
| (C) Refine Existing Skill | Interview packet + "refine [skill]" intent | Delta-focused edits to existing skill — missing PMO-field injection, description-trigger optimization, blind A/B vs. baseline; structural-edit scope routes to pmo-skill-editor |

### Output Contract

| Section | Content | Format | Notes |
|---------|---------|--------|-------|
| 1. Mode & Target | Mode name, target skill path (Create-New: new path; Refine-Existing: existing path), Anthropic wrap target invoked | Metadata | Reproducibility for session log |
| 2. Interview Packet | 9 Q&A exchanges from Interview mode | Structured Q&A | Q1–Q9 complete; under-specification surfaced with loop-back |
| 3. Refined SKILL.md | Complete produced SKILL.md with all 7 PMO fields injected | Code block or file | Ready for commit; G7 Phase 1 regex matches ≥ 3 |
| 4. Eval Evidence | Workspace path + benchmark.json + run_loop_output.json + description delta | Paste-ready table | Variance-analyzed; gaming-detection flagged; best_description applied if delta crosses threshold |
| 5. Contracts Registered | per-skill-output-contracts.md Skill N entry added; registry.md CI row added; regression-checks.md entry added | Structured list | Each with ✓ / ✗ and link to edited file |
| 6. Pre-Handoff Gate Evidence | G7 Phase 1 (≥ 3 failure modes), Principal Standard self-check (CONDITIONAL PASS or better per `principal-standard-checklist.md` Scoring Guide), reversibility section present, zero placeholders, cross-references resolve | Pass/fail checklist | Gate fail → iterate, do not hand off |
| 7. Handoff Instructions | Paste-ready deploy command + canonical-session pre-check + downstream next-step (pmo-skill-editor routing if Refine-Existing spanned scope) | Code block + prose | D6 canonical-session check paired with every --deploy instruction |

### Required Elements

**Evidence Quality:**
- All factual claims in pmo-skill-refiner's own output carry evidence labels (per CLAUDE.md § Universal Preferences).
- Interview Q2 trigger phrasings require T1/T2 evidence citation; synthetic phrasings rejected absent explicit user waiver.

**Reversibility Tiers:**

Reversibility tier defaults (per `../specs/reversibility-protocol.md`):
- Refined SKILL.md (Create-New): typically CHEAP · HIGH
- Refined SKILL.md (Refine-Existing): typically MODERATE · MEDIUM
- `best_description` selection: CHEAP · HIGH
- Handoff decision (proceed vs. route to editor): CHEAP · HIGH
- Registration in per-skill-output-contracts.md / registry.md / regression-checks.md: CHEAP · HIGH

**Principal Standard Target:**
- Refiner itself: CONDITIONAL PASS or better per `../standards/principal-standard-checklist.md` Scoring Guide (≤ 2 competency FAILs; neither may be Push-to-Resolve or Evidence-Based Execution)
- Skills produced by refiner: CONDITIONAL PASS or better per the same Scoring Guide (injected as declared target via Field 7)

**RAID Prefix:** `R-PSR-###` — used when refinement surfaces a cross-skill risk or operator-escalation item. Refiner rarely produces RAID (normal output is the refined SKILL.md + eval evidence); when it does, prefix avoids collision with existing prefixes (R-PPM, R-DE, R-CM, R-TA, R-PD, R-IP).

### Validation Checklist (QA Auditor Self-Check for Skill Refiner)

- [ ] All 7 sections present
- [ ] Interview packet has 9 complete Q&A (or documented under-specification loop-back)
- [ ] Refined SKILL.md contains all 7 PMO injection fields (delivery_approach, Output Contract stub, Dependency Graph Node stub, Evidence Quality Protocol, Domain-Specific Failure Modes ≥ 3 with TRIG/INPUT/PROC/OUT/HAND tags, Reversibility Discipline, Principal Standard Target)
- [ ] Eval evidence includes workspace path + at least iteration-1 benchmark.json + run_loop_output.json (if description-optimization requested)
- [ ] Pre-Handoff Gate: G7 Phase 1 regex ≥ 3 matches; Principal Standard CONDITIONAL PASS or better per Scoring Guide; reversibility section present; zero `[INSERT]`/`[TBD]`; all cross-refs resolve
- [ ] Contracts registered: per-skill-output-contracts.md Skill N edit, registry.md CI row edit, regression-checks.md entry (create-if-missing supported)
- [ ] Handoff instructions include D6 canonical-session pre-check paired with deploy command
- [ ] No scope creep into pmo-skill-editor territory (structural edits routed, not performed)

### Structural Checks (for QA Auditor reference — applies to refiner's own outputs)

- **G1 (Structural Completeness):** 7 sections per Output Contract.
- **G2 (Evidence Quality):** ✓ on all factual claims (Interview transcript source-cited; benchmark numbers sourced to workspace artifact).
- **G3 (Decision Clarity):** ✓ — every decision-class item (Refined SKILL.md, best_description selection, handoff routing) carries reversibility tier + confidence.
- **G4 (Artifact Readiness):** ✓ — Refined SKILL.md is git-commit-ready; handoff deploy command is paste-ready with canonical-session pre-check.
- **G5 (Follow-up Routing):** N/A — refiner role (no emitted tags).
- **G6 (Dual Output):** ✓ — Refined SKILL.md artifact + pre-handoff-gate evidence metadata.
- **G7 (Domain-Specific Failure Modes):** ✓ on pmo-skill-refiner's own SKILL.md (≥ 3 conditional clauses, category-tagged).
- **Reversibility:** ✓ (tier + confidence on every decision-class item).
- **Mode Identification:** ✓ (3 modes — Interview, Create-New, Refine-Existing).

### Appendix: RAID Entry Prefix Reference (add to existing table at § Appendix)

- **PMO Skill Refiner** — `R-PSR-###` — example: `R-PSR-003 (Risk: Cross-skill trigger collision detected between [new-skill] and [existing-skill] per run_eval_audit.py output; recommend description differentiation)`.

---

## Skill 12: PMO Skill Refiner Selftest Canary (Smoke Test — Permanent Fixture per ADR-04)

**Purpose:** Minimal report-only skill that verifies consistency between the `release/skills/` directory and `deploy.sh` SKILL_LIST + SUPPLEMENTARY_SKILLS arrays. Produced via pmo-skill-refiner Create-New workflow during an AC demonstration. Preserved as permanent smoke test per ADR-04 (defer final disposition to operator at Stage 13 Close per Stage 5 Option A recommendation).

**Skill source:** [`release/skills/pmo-skill-refiner-selftest-canary/SKILL.md`](../../release/skills/pmo-skill-refiner-selftest-canary/SKILL.md)
**AC demo evidence:** artifacts removed (superseded; preserved in git history)

### Modes

Single-mode skill — no Interview, no Refine. Invocation is the mode.

| Trigger | Output Focus |
|---|---|
| "check the skill roster" / "count tracked skills" / "audit skill deployment drift" / "are all my skills deployed" / "does deploy.sh match the skills folder" | Roster consistency report — count + drift table |

### Output Contract (2 Sections)

| Section | Content | Format | Notes |
|---|---|---|---|
| 1. Summary paragraph | Count of skill directories + count of per-module-array (`OPERATIONS_SKILLS` / `RELEASE_SKILLS` / `CORE_SKILLS` / `CANARY_SKILLS`) + `SUPPLEMENTARY_SKILLS` entries + **split drift count** | Prose, single paragraph | Format: "<N> skill directories in release/skills/. <M> entries in the deploy.sh per-module arrays + SUPPLEMENTARY_SKILLS. <K> drift entries flagged (J expected-fixture, K−J actionable)." The drift count **splits** into fixture-induced (`[CANARY EXPECTED]`) vs. actionable so the downstream routing note (deep audit → pmo-qa-auditor Mode D) receives only actionable signal — per the § Skill 12 HAND failure mode. When no fixture rows are present, the split collapses to the actionable count alone. |
| 2. Drift table | Per-skill row with In-Folder / In-Roster / Status columns | Markdown table | Status values: OK, Folder Only, Roster Only, **`[CANARY EXPECTED]`** (a Folder-Only row whose subject is a registered source-only fixture — e.g. the canary itself, source-only per ADR-04, excluded from the deploy roster by design; annotated so the reader distinguishes fixture-induced signal from a factory regression per the § Skill 12 HAND failure mode). |

### Required Elements

**Evidence Quality:**
- All counts + drift flags tagged `[SOURCE]` (derived directly from filesystem listing + deploy.sh parse).
- No `[INFERRED]` or `[ASSUMPTION]` labels expected in normal operation.

**Reversibility:**
- Report-only; no decision-class items. G4 reversibility check N/A per declared opt-out.

**RAID Prefix:** None (report-only skill; does not produce RAID entries).

### Validation Checklist (QA Auditor Self-Check for Canary)

- [ ] Both sections present (Summary + Drift table)
- [ ] Count of skill directories matches `ls release/skills/` cardinality at run time
- [ ] Union of per-module arrays (`OPERATIONS_SKILLS` / `RELEASE_SKILLS` / `CORE_SKILLS` / `CANARY_SKILLS`) + SUPPLEMENTARY_SKILLS used in comparison (not just the per-module arrays — the second PROC failure-mode mitigation)
- [ ] Drift rows identify direction (Folder Only vs. Roster Only)
- [ ] No recommendations / actions (report-only discipline preserved)
- [ ] In-flight refactor warning present if uncommitted changes to release/skills/ or deploy.sh detected (TRIG failure mode #3 mitigation)

### Structural Checks (for QA Auditor reference)

- **G1 (Structural Completeness):** 2 sections (Summary paragraph + Drift table).
- **G2 (Evidence Quality):** ✓ ([SOURCE] labels on all counts and flags).
- **G3 (Decision Clarity):** N/A (report-only; no decision or recommendation surface).
- **G4 (Artifact Readiness):** ✓ (output is the artifact; directly readable by operator).
- **G5 (Follow-up Routing):** N/A (no emitted tags).
- **G6 (Dual Output):** N/A (report-only; no metadata-vs-artifact split).
- **G7 (Domain-Specific Failure Modes):** ✓ (≥3 domain-specific failure modes per `../standards/failure-mode-standard.md`, 5-field template + category tag TRIG / INPUT / PROC / OUT / HAND — the regression-safe floor form used by every other skill's G7 row; the canary currently carries 5 entries spanning all 5 categories per the ADR-04 fixture-scope decision, but this row states the floor, not a by-name enumeration, so it does not go stale when a canary entry is added).
- **Reversibility:** N/A (report-only opt-out declared).
- **Mode Identification:** Single-mode skill; invocation = mode.

### Appendix: RAID Entry Prefix Reference

No prefix — report-only skill.

---

## Validation Rules (for QA Auditor)

### Structural Checks Table

This table shows which structural checks apply per skill. Use this to conduct systematic QA validation.

| Check | PPM Agent | Delivery Engine | Comms Writer | Change Mgmt | Technical | Process Designer | QA Auditor | Skill Editor | Build Reviewer |
|-------|-----------|-----------------|--------------|-------------|-----------|------------------|------------|--------------|----------------|
| **G1: Structural Completeness** | 7 sections | 8 sections + CS | 6 sections | 8 sections + CS | 8 sections + CS | 8 sections + CS | 4 sections | 5 sections | 4 sections (metadata, summary, findings register, 6 deliverables) |
| **G2: Evidence Quality** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ (on inputs) | ✓ (on changes) | ✓ (on findings) |
| **G3: Decision Clarity** | ✓ | Gate results (C,D,F,G) | READY/NOT READY | ✓ (implicit in plan) | ✓ (risk matrix) | ✓ (gap analysis) | PASS/FAIL gate | ✓ (on edits) | PASS/CONDITIONAL/FAIL verdict |
| **G4: Artifact Readiness** | ✓ (paste-ready blocks) | ✓ (paste-ready) | ✓ (draft) | ✓ (paste-ready) | ✓ (paste-ready) | ✓ (paste-ready) | N/A (auditor role) | ✓ (.skill file) | ✓ (paste-ready findings register) |
| **G5: Follow-up Routing** | ✓ (max depth 2) | ✓ (max depth 2) | N/A (no routing) | ✓ ([COMMS] only) | ✓ ([DELIVERY], [CHANGE]) | N/A (no routing) | N/A (auditor role) | N/A (editor role) | N/A (review findings routed via register) |
| **G6: Dual Output** | ✓ (artifacts + metadata) | ✓ (RAID + metadata) | Email/Teams exempt | ✓ (RAID + metadata) | ✓ (RAID + metadata) | ✓ (RAID + metadata) | N/A (auditor role) | ✓ (change log + .skill) | N/A (no RAID dual-output; findings are the artifact) |
| **Dual-Framing Bridge** | N/A | ✓ (if milestone context) | N/A | N/A | N/A | N/A | N/A | N/A | N/A |
| **Mode Identification** | N/A | ✓ (7 modes) | ✓ (8 types) | ✓ (6 modes) | ✓ (5 modes) | ✓ (5 modes) | ✓ (4 modes) | ✓ (4 modes) | ✓ (4 modes — per pack + cross-cutting) |
| **Risk Matrix** | ✓ (top risks) | N/A | N/A | N/A | ✓ (6 dimensions) | N/A | N/A | N/A | N/A (findings register serves the function) |
| **Readiness Gate** | N/A (implicit health) | ✓ (gate results) | ✓ (explicit READY/NOT READY) | N/A (implicit readiness) | N/A (risk matrix as proxy) | N/A (implicit in gap analysis) | ✓ (PASS/FAIL per gate) | N/A | ✓ (PASS/CONDITIONAL/FAIL verdict) |
| **Artifact Target Location** | N/A | ✓ (system + section) | ✓ (Confluence path if applicable) | ✓ (Confluence → [Active Project] → CM) | N/A (integration to FDD, etc.) | N/A (updates existing artifacts) | N/A | ✓ (master plan location) | N/A (findings consumed by implementation-planner) |
| **Checklists** | N/A | ✓ (mode-specific) | N/A | ✓ (readiness checklist in mode C) | N/A | N/A | N/A | N/A | ✓ (14-item validation per Skill 9 contract) |
| **Change Summary** | N/A | ✓ (appended) | N/A | ✓ (appended) | ✓ (appended) | ✓ (appended) | N/A | ✓ (section 1) | N/A |
| **RAID Entry Prefix** | R-PPM-### | R-DE-### | N/A | R-CM-### | R-TA-### | R-PD-### | N/A | N/A (refs existing RAID) | R-BR-### |

### QA Audit Workflow

1. **Receive Output** — Identify skill, mode, intended audience
2. **Determine Applicable Checks** — Consult table above
3. **Evaluate Each Check** — For each applicable check, verify presence and quality
4. **Record Results** — PASS / FAIL per gate with evidence
5. **Compile Findings** — If any FAIL, include exact remediation text
6. **Decision Gate** — PASS / CONDITIONAL PASS / FAIL assessment
7. **Issue Report** — Share with skill operator and PPM Agent

### Sample QA Finding (Template)

```
FINDING: [Skill Name] – Mode [X]
Location: [Section], [subsection]
What's Wrong: [Description of failure, with evidence]
Why It Matters: [Impact on decision-making, downstream work, compliance]
Exact Remediation: [Copy/paste-ready fix or instruction]
Severity: [Critical / Major / Minor]
```

---

## Skill 13: Artifact Lint (Tier 1 — Generated-Surface Graph Integrity)

### Output Contract (Staged Report — 4 Required Sections)

Artifact Lint produces a single staged report at `08-Generated/artifact-lint-YYYY-MM-DD.md` (itself a Domain-C `analysis` artifact with a `lifecycle_state: draft` + `promotion_state: staged` header). The report has four required sections.

| Section | Content | Format | Notes |
|---------|---------|--------|-------|
| 1. Scope | In-scope surface (08-Generated/ + promoted 01-07), honored exclusions (09-Prototype/, _templates/; read-only _archived/), artifacts-scanned count, unscannable list | Structured block | The exclusion + override posture is stated every run |
| 2. Findings | Five check sub-sections — orphan, sibling duplicate, stale draft, displaced content, version chain — each a table of findings | One table per check | Empty checks reported explicitly as "none" (honest no-finding signal), never omitted |
| 3. Summary | Total finding count + the recommend-only assertion ("no file moves performed; user approves each action") | Structured line | The Tier-1 no-auto-mutation statement |
| 4. Metadata header | artifact-generator-format frontmatter (artifact_type: analysis, target_folder, confidence, created, source, dependencies, reversibility, lifecycle_state: draft, promotion_state: staged) | YAML frontmatter | The report stages like any Domain-C artifact |

### Required Elements

**Five checks, each recommend-only:** orphan (dangling/empty-source), sibling duplicate (strict-key match), stale draft (`lifecycle_state` content-maturity read + age threshold), displaced content (`promotion_state`-vs-folder), version chain (ordered chain + break detection). Each finding cites the frontmatter evidence that triggered it.

**Canonical state-read:** the content-maturity checks (stale draft, version chain) read the canonical `lifecycle_state` field; the displaced-content check reads the orthogonal `promotion_state` (+ `folder`) location field. The lint records which field fired in the evidence. (No dual-read: the legacy conflated single-field machine is deprecated and no longer stamped — see `core/artifact-workflow-protocol.md`.)

**Strict-match dedup key:** `parent_artifact + artifact_type + sibling_topic` (case-insensitive on sibling_topic), degrading to `parent_artifact + artifact_type` with a "missing sibling_topic — weak match" warning.

**No auto-mutation:** the report is the ONLY write. No scanned artifact is moved, renamed, archived, or deleted by the lint — every action is operator-approved (Autonomy Tier 1).

### Reversibility Tier + Confidence

Output class → default tier + confidence (per `../specs/reversibility-protocol.md`):

| Output class | Tier | Confidence |
|---|---|---|
| The lint report itself; stale-draft refresh; "mark distinct" outcome | CHEAP | HIGH (staged draft, revertable) |
| Archive / add-supersedes-edge / correct-folder / promote recommendations | MODERATE | HIGH (strict-key) / MEDIUM-LOW (weak match) |
| Merge recommendation on a promoted+consumed artifact | EXPENSIVE | per evidence strength |

Every finding carries tier + confidence explicitly. No unlabeled recommendations (pmo-qa-auditor G4).

### Evidence Labels

All factual claims carry one of the 5 evidence labels per CLAUDE.md § Universal Preferences. A finding's triggering frontmatter values are `[SOURCE]`; a proposed action is `[RECOMMENDED]`; an inferred chain ordering over incomplete edges is `[INFERRED]`. Never fabricate a `parent_artifact` value — an unknown upstream anchor is surfaced as an orphan finding, not invented.

### Failure-Mode Conformance (G7)

`artifact-lint/SKILL.md` must contain ≥ 3 domain-specific failure modes per `../standards/failure-mode-standard.md` with the 5-field template + category tag (TRIG / INPUT / PROC / OUT / HAND). G7 Phase 1 regex: `## Domain-Specific Failure Modes` heading + ≥ 3 `### <Title> — <CATEGORY>` sub-headings. (Ships with 5: dual-state-read INPUT, version-chain-as-duplicate OUT, auto-execute PROC, excluded-path TRIG, cleanup-tool-conflation HAND.)

### Validation Checklist (QA Gate)
- [ ] Report staged at `08-Generated/artifact-lint-YYYY-MM-DD.md` with the artifact-generator metadata header
- [ ] Scope block names the in-scope surface, the exclusions, and the unscannable list
- [ ] All five check sub-sections present (empty ones reported as "none")
- [ ] Every finding cites frontmatter evidence and carries a reversibility tier + confidence
- [ ] Dual state-read applied on stale-draft + version-chain findings
- [ ] Version variants routed to version-chain, NOT flagged as duplicates
- [ ] Recommend-only — report states no file moves performed; user approves each action

---

## Skill 14: Generated Cleanup (Tier 1 — Generated-Surface Retirement Proposals)

### Output Contract (Staged Proposal — 3 Required Sections)

Generated Cleanup produces a single staged proposal at `08-Generated/generated-cleanup-YYYY-MM-DD.md` (itself a Domain-C `analysis` artifact with a `lifecycle_state: draft` + `promotion_state: staged` header). The proposal has three required sections.

| Section | Content | Format | Notes |
|---------|---------|--------|-------|
| 1. Scope | In-scope surface (08-Generated/ approaching-timeout + promoted 01-07 promoted-and-stale), honored exclusions (09-Prototype/, _templates/, _archived/), the artifact-lint report consumed (or explicit "NONE FOUND"), artifacts-scanned + candidate counts | Structured block | The exclusion posture + the Auto-Archive composition (>10-bd staged ceded to the sweep) stated every run |
| 2. Candidates | Three group sub-sections — promoted-and-stale, approaching-timeout, superseded — each a table of candidates with evidence + proposed archive action + reversibility | One table per group | Empty groups reported explicitly as "none" (honest no-finding signal), never omitted |
| 3. Summary | Total candidate count + the recommend-only assertion ("no file moves performed; user approves each action; scheduled runs never self-apply") | Structured line | The Tier-1 no-auto-mutation statement |

(The metadata header — artifact-generator-format frontmatter with `artifact_type: analysis`, `lifecycle_state: draft`, `promotion_state: staged` — is the proposal's own YAML, staged like any Domain-C artifact.)

### Required Elements

**Three groups, each recommend-only:** promoted-and-stale (`promotion_state: promoted` ∧ derived >30-day-unreferenced, intersection — plus stamped `lifecycle_state: superseded`), approaching-timeout (`promotion_state: staged` ∧ `lifecycle_changed` under the 10-bd staging timeout, disjoint from the Auto-Archive sweep), superseded (consumed from the artifact-lint report, not re-derived). Each candidate cites the field values / derived signal / lint-report citation that triggered it.

**Zero reads of the deprecated single-field machine:** the grouping keys on the reconciled `lifecycle_state` + `promotion_state` (+ `lifecycle_changed` + the derived >30-day signal + the lint report). The deprecated single-field workflow machine is read zero times (no fallback read — it is no longer stamped; see `core/standards/lifecycle-states-canonical.md §3.2`). Staleness is **derived** (>30-day-unreferenced, recommend-only, labeled `[INFERRED]`), never read as a stamped `lifecycle_state: stale` value.

**Protocol-legal archive split (branches by `promotion_state`):** staged ⇒ location sweep to `08-Generated/_archived/` (`archived-in-place`); promoted ⇒ `lifecycle_state: archived` in place + `trust_category: historical-record` (no folder move). No `promoted → archived-in-place` action is ever proposed (`artifact-workflow-protocol.md §4.1`). Never delete — both paths recoverable.

**Auto-Archive composition:** the >10-bd staged population is ceded to the artifact-generator Auto-Archive sweep; the approaching-timeout group surfaces only the disjoint under-10-bd window — no duplication, no silent re-gating.

**No auto-mutation:** the proposal is the ONLY write. No scanned artifact is moved, content-retired, archived, or deleted by the skill — every action is operator-approved (Autonomy Tier 1), and a scheduled run (via the `/schedule` seam) stages a pending proposal that never self-applies.

**Conflation boundary:** never invokes, names as executor, or routes a recommendation through `cleanup-orphan-state.sh` (a git/runtime state-file tool — a different object class).

### Reversibility Tier + Confidence

Output class → default tier + confidence (per `../specs/reversibility-protocol.md`):

| Output class | Tier | Confidence |
|---|---|---|
| The cleanup proposal itself; an approaching-timeout location sweep on an unreferenced staged file | CHEAP | HIGH (staged draft / recoverable from _archived/) |
| Content-retirement of a promoted file; superseded archive of a promoted member | MODERATE | HIGH (stamped `superseded`) / MEDIUM-LOW (derived-stale) |
| Content-retirement of a promoted artifact consumed by downstream reviewers / stakeholder comms | EXPENSIVE | per evidence strength |

Every candidate carries tier + confidence explicitly. No unlabeled recommendations (pmo-qa-auditor G4).

### Evidence Labels

All factual claims carry one of the 5 evidence labels per CLAUDE.md § Universal Preferences. A candidate's stamped evidence (`lifecycle_state` / `promotion_state` / `lifecycle_changed`, or the artifact-lint report citation) is `[SOURCE]`; the **derived** staleness signal (computed >30-day-unreferenced) is `[INFERRED]` (computed, not stamped — never presented as a stamped `stale`); a proposed archive action is `[RECOMMENDED]`. Never fabricate a last-referenced date or a lifecycle value — a missing field is surfaced or skipped-with-note, not invented.

### Failure-Mode Conformance (G7)

`generated-cleanup/SKILL.md` must contain ≥ 3 domain-specific failure modes per `../standards/failure-mode-standard.md` with the 5-field template + category tag (TRIG / INPUT / PROC / OUT / HAND). G7 Phase 1 regex: `## Domain-Specific Failure Modes` heading + ≥ 3 `### <Title> — <CATEGORY>` sub-headings. (Ships with 5: promoted-file-illegal-terminal PROC, group-duplicates-auto-sweep PROC, stale-value-not-stamped INPUT, scheduled-auto-apply PROC, cleanup-tool-conflation HAND.)

### Validation Checklist (QA Gate)
- [ ] Proposal staged at `08-Generated/generated-cleanup-YYYY-MM-DD.md` with the artifact-generator metadata header
- [ ] Scope block names the in-scope surface, the exclusions (incl. _archived/), and the artifact-lint report consumed (or "NONE FOUND")
- [ ] All three group sub-sections present (empty ones reported as "none")
- [ ] Every candidate cites evidence and carries a reversibility tier + confidence
- [ ] Zero reads of the deprecated single-field machine; staleness derived (>30-day), never read as stamped `stale`
- [ ] Archive action branches by `promotion_state` — no `promoted → archived-in-place` proposed
- [ ] Group 2 (approaching-timeout) is disjoint from the Auto-Archive sweep (under-10-bd only)
- [ ] Recommend-only — proposal states no file moves performed; user approves each action; scheduled runs never self-apply

---

## Skill 15: Pipeline Triage (Stage-2 Triage Execution — Improvement Backlog)

### Output Contract (Consolidated Triage Summary — 4 Required Sections)

Pipeline Triage produces exactly ONE consolidated batch artifact per triage run — never a stream of per-action prompts. The summary is posted as the triage decision comment per the standard stage review header format (`stage-02-triage.md` §6 Outputs); no separate triage document is written (issue body is the source-of-truth layer; state anchors update at Resolve). The summary has four required sections.

| Section | Content | Format | Notes |
|---------|---------|--------|-------|
| 1. Batch Scope | The `status: proposed` query run (untriaged-view filter with observations excluded), the issue set triaged, the count | Structured block | States the improvement-backlog boundary explicitly (not a project/Jira backlog) |
| 2. Per-Issue Block | One block per issue: A6 summary fields (DoR status · duplicate/similarity candidates · dependency block/warn flags · `Dependency-position signal` · feasibility flags · priority assessment · size-routing outcome) + a per-issue **Approve / Defer / Reject recommendation** with evidence + reversibility tier + confidence | One block per issue | The recommendation is `[RECOMMENDED]`, never a rendered verdict |
| 3. Management-Task Signals (A6.5) | The per-batch 4-pattern sweep output (backlog hygiene / escalation signals / coordination needs / decomposition candidates) in the `stage-02-triage.md` §5 A6.5 signal-block format | `### Management-Task Signals` H3 block | Empty patterns reported explicitly as "none detected", never omitted |
| 4. Verdict-Reservation Note | Explicit statement that the Approve/Defer/Reject **verdict** is operator-only (Tier 3); the summary presents recommendations only | Structured line | The Tier-3 human-only reservation |

### Required Elements

**Auto-execute default:** the A1–A6.5 enrichment (DoR check, duplicate/similarity, dependency-state validation + native-dep mirror, feasibility, priority re-evaluation, oversize routing, per-issue summary, management-task identification) runs end-to-end for all in-scope `status: proposed` issues with NO per-action approval gate. Enrichment writes (comments, labels, native-dep mirror, Decision-Date/Priority Projects-field writes) post in one consolidated pass, binding the Tier-2 posture defined at `stage-02-triage.md` §8 (referenced, not restated).

**Close/Reject confirmation carve-out:** the ONE state-mutating action outside auto-execute is the Reject-close (`gh issue close --reason "not planned"`) — it blocks behind an explicit operator confirmation at the verdict-execution boundary. Approve/Defer execute as normal operator-approved batch label outcomes.

**Cite-don't-restate:** each phase (A1…A6.5) references its definition in `stage-02-triage.md` §5 + the relevant gate ID (G1-*, G2-01/04/09/10/11/12); the phase *definitions* are NOT restated inline (no-duplicate-source).

**No auto-verdict:** the skill presents per-issue recommendations; the Approve/Defer/Reject verdict is operator-only (Tier 3). The skill never applies a verdict as if it were the decision-maker.

### Reversibility Tier + Confidence

Output class → default tier + confidence (per `../specs/reversibility-protocol.md`):

| Output class | Tier | Confidence |
|---|---|---|
| An Approve or Defer recommendation; the A1–A6.5 enrichment writes; the consolidated summary | CHEAP | HIGH |
| A Reject recommendation (the operator-confirmed close) | MODERATE | per evidence (reversible via T6 reopen; loses queue position — hence the confirmation gate) |

Every recommendation carries tier + confidence explicitly. No unlabeled recommendations (pmo-qa-auditor G4).

### Evidence Labels

All factual claims carry one of the 5 evidence labels per CLAUDE.md § Universal Preferences. A verified GitHub Issue field / `gh` result / spec citation is `[SOURCE]`; a derived signal (similarity score, dependency-position count, oversize-predicate evaluation) is `[INFERRED]`; the per-issue Approve/Defer/Reject recommendation is `[RECOMMENDED]`. Never fabricate a DoR status, duplicate match, dependency state, or priority — a missing/unreadable field is surfaced or skipped-with-note, not invented.

### Failure-Mode Conformance (G7)

`pipeline-triage/SKILL.md` must contain ≥ 3 domain-specific failure modes per `../standards/failure-mode-standard.md` with the 5-field template + category tag (TRIG / INPUT / PROC / OUT / HAND). G7 Phase 1 regex: `## Domain-Specific Failure Modes` heading + ≥ 3 `### <Title> — <CATEGORY>` sub-headings. (Ships with 3: project-vs-improvement-backlog TRIG, phase-definition-restated OUT, auto-verdict/auto-close PROC.)

### Validation Checklist (QA Gate)
- [ ] Output is ONE consolidated batch summary (not per-action prompts); posted as the triage decision comment
- [ ] All four sections present (Batch Scope · Per-Issue Block · Management-Task Signals · Verdict-Reservation Note)
- [ ] Every per-issue block carries an Approve/Defer/Reject recommendation with evidence + reversibility tier + confidence
- [ ] Auto-execute default declared; no per-action approval gate in the A1–A6.5 path
- [ ] Close/Reject blocks behind explicit operator confirmation; Approve/Defer execute as batch outcomes
- [ ] Each phase cites `stage-02-triage.md` §5 (phase definitions NOT restated inline)
- [ ] Verdict-reservation note present — the Approve/Defer/Reject verdict is operator-only (Tier 3)
- [ ] Reads the improvement backlog (`status: proposed`), never a Jira/project-delivery backlog

---

## Appendix: RAID Entry Prefix Reference

| Skill | Prefix | Example |
|-------|--------|---------|
| PPM Agent | R-PPM-### | R-PPM-047 (Risk: Design phase delay) |
| Delivery Engine | R-DE-### | R-DE-031 (Risk: Sprint burndown at risk) |
| Change Management | R-CM-### | R-CM-015 (Risk: Training completion below threshold) |
| Technical Analyst | R-TA-### | R-TA-022 (Risk: Integration dependency unverified) |
| Process Designer | R-PD-### | R-PD-009 (Decision: Requirement scope clarification needed) |
| Build Reviewer | R-BR-### | R-BR-007 (Finding: Missing cross-reference in pipeline/stage-07-dev-testing.md) |
| Implementation Planner | R-IP-### | R-IP-042 (Risk: RT-5 coordination constraint pending workflow-executor verification per implementation-execution-pattern.md) |
| PMO Skill Refiner | R-PSR-### | R-PSR-003 (Risk: Cross-skill trigger collision detected between [new-skill] and [existing-skill] per run_eval_audit.py output; recommend description differentiation) |
| Pipeline Triage | R-PTR-### | R-PTR-005 (Risk: proposed issue #N cites a Rejected dependency; resolve before approval per stage-02-triage.md A3) |

---

## Appendix: Evidence Tag Format Reference

### Standard Evidence Tag
```
[EVIDENCE: source]
```
Examples:
- `[EVIDENCE: RAID log R-PPM-047]`
- `[EVIDENCE: 2026-03-15 governance meeting transcript]`
- `[EVIDENCE: Ticket DE-5124 (Jira)]`
- `[EVIDENCE: PMO domain knowledge]`

### Assumption Tag (Use When Evidence Unavailable)
```
[ASSUMPTION – CONFIRM: proposed answer]
```
Examples:
- `[ASSUMPTION – CONFIRM: UAT window is 2 weeks (April 1–15)]`
- `[ASSUMPTION – CONFIRM: 3 teams will support hypercare]`

**Rule:** If any claim in a communication or artifact is tagged [ASSUMPTION], that artifact is NOT READY for send/approval. All assumptions must be confirmed before release.

---

## Appendix: Follow-up Tag Format Reference

### Standard Follow-up Tag
```
[TAG: Context/Source/Scope/Inputs/Constraints]
```

### Valid Tags by Skill

| Skill | Can Emit | Cannot Emit | Max Depth |
|-------|----------|-----------|-----------|
| PPM Agent | [DELIVERY] [COMMS] [TECHNICAL] [PROCESS] [CHANGE] | None | 2 |
| Delivery Engine | [DELIVERY] [COMMS] [TECHNICAL] [PROCESS] [CHANGE] | None | 2 |
| Comms Writer | None (no routing) | All tags | N/A |
| Change Mgmt | [CHANGE] (self) [COMMS] (routing to writer) | [TECHNICAL] [DELIVERY] [PROCESS] | 2 |
| Technical Analyst | [DELIVERY] [CHANGE] | [TECHNICAL] [PROCESS] [COMMS] | 2 |
| Process Designer | [DELIVERY] [CHANGE] [TECHNICAL] | [COMMS] [PROCESS] | 2 |
| QA Auditor | N/A (auditor role) | All | N/A |
| Skill Editor | N/A (editor role) | All | N/A |
| Build Reviewer | None (review findings routed via findings register, not tags) | All | N/A |

### Example Follow-up Tag
```
[DELIVERY: context="UAT readiness depends on 3 critical bugs fixed"/
source="Delivery Engine mode E, ticket DE-5124"/
scope="UAT window 2026-04-01 to 2026-04-15"/
inputs="Bug list (Jira), impact assessment (Delivery Engine output)"/
constraints="Cannot slip UAT window due to go-live dependency"]
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-18 | Initial release; all 8 skills defined, 6 QA gates, validation rules, appendices |
| 2.0 | 2026-04-22 | Skills 1-8 uplift to baseline standards (Reversibility Tier + Confidence, Evidence Labels, Failure-Mode Conformance G7)  Principal Standard vocabulary swap (4 locations) from numeric ratio language to Scoring Guide vocabulary (PASS / CONDITIONAL PASS / FAIL) per `principal-standard-checklist.md` Single Source Rule. |

---

**Document Owner:** PMO QA Auditor
**Last Updated:** 2026-04-22
**Status:** Active
