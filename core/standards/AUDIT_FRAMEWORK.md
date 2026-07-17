---
title: PMO Platform Operational Readiness Audit — Framework
purpose: The 3-session operational-readiness audit framework for the PMO platform — structural/behavioral, then deep-dive, then synthesis — each session producing a chained output file.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: operators running a platform operational-readiness audit; pmo-qa-auditor (Platform health audit mode); the session-chained audit output files it defines
---
<!-- reference-durability: allow-link -->
# PMO Platform Operational Readiness Audit — Framework

**Purpose:** Comprehensive audit of the PMO platform's structure, behavior, and operational readiness. Run in 3 sequential sessions, each producing an output file that feeds the next.

**Session chain:**
```
Session 1: Structural & Behavioral Audit → AUDIT_STRUCTURAL.md
Session 2: Pipeline & Integration Test   → AUDIT_PIPELINE.md (reads AUDIT_STRUCTURAL.md)
Session 3: Operational Readiness Score    → AUDIT_READINESS.md (reads both prior files)
```

---

## Session 1: Structural & Behavioral Audit

**Output:** `08-Generated/AUDIT_STRUCTURAL.md`
**Duration:** ~30 min
**Skill:** pmo-qa-auditor (invoke at start)

```
Run Phase 1 of the PMO Platform Operational Readiness Audit.

Read the audit framework at core/standards/AUDIT_FRAMEWORK.md first, then read
these files in order:
1. Claude/CLAUDE.md
2. core/governance/OPERATIONS.md
3. projects/_config/PORTFOLIO.md
4. projects/_config/SESSION_STATE.md
5. GitHub Issues (improvement backlog — `gh issue list --label improvement`)
6. projects/[Project]/PROJECT.md

Invoke the pmo-qa-auditor skill, then audit across these 7 dimensions. For each
dimension: state what SHOULD exist (from context files), state what ACTUALLY exists
(verified by reading files and checking paths), test it behaviorally (simulate or
execute the function), and score PASS / PARTIAL / FAIL with specific remediation.

DIMENSION 1: Context File Integrity & Coherence
- Do CLAUDE.md, OPERATIONS.md, PORTFOLIO.md, PROJECT.md, and SESSION_STATE.md exist and agree?
- Are lifecycle states consistent across files?
- Are dates consistent? Do day-of-week labels validate?
- Does OPERATIONS.md reference skills that are actually installed? Check every skill name
  against ~/.claude/skills/ directory.
- Does CLAUDE.md workspace structure match the actual folder layout?
- BEHAVIORAL TEST: Simulate a cold-start session — read SESSION_STATE.md, follow its
  instructions. Do you arrive at a coherent, complete understanding of the workspace?

DIMENSION 2: Skill Installation & Reference Integrity
- Are all PMO skills installed? Derive the expected set by enumerating the live
  source-of-truth skill trees (`core/skills/`, `operations/skills/`, `release/skills/`) —
  do not assume a fixed count or per-skill version; the live trees are authoritative.
- For each skill that references references/*.md files, do those files exist in the
  skill's installed references/ directory?
- Are there skills referenced in OPERATIONS.md that aren't installed?
- Are there installed PMO skills not referenced in OPERATIONS.md?
- BEHAVIORAL TEST: For each skill, read its SKILL.md and attempt to resolve every
  references/ path it mentions. Report any broken references.

DIMENSION 3: Folder Structure & Document Location
- Does the [Project] project folder match the standard structure defined in OPERATIONS.md?
- Are all 8 numbered folders present (01-08)?
- Do the expected portfolio-level shared docs and templates exist in their current homes (governance → `core/`, operational config → `projects/_config/`, templates → `operations/templates/`)?
- Are there orphan files (files in unexpected locations, stale artifacts)?
- Is projects/Archive/ properly separated from operational files?
- BEHAVIORAL TEST: Take a sample filename (e.g., "AM Testing 2026-03-19.txt") and
  trace the routing rules in OPERATIONS.md. Does the File Router skill's routing-patterns.md
  agree? Would the file land in the right folder?

DIMENSION 4: Operational Tracker Health
- Do all expected trackers exist in 04-PMO-Operations/ per OPERATIONS.md's artifact table?
- Are tracker schemas (from core/schemas/tracker-schemas.md) consistent with actual
  tracker file headers?
- Are there trackers defined in the schema that don't exist as files?
- Are there tracker files that don't appear in the schema?
- BEHAVIORAL TEST: Simulate a tracker update instruction (e.g., "add blocker BLK-099
  to Daily Status Log"). Does the Tracker Manager skill know the schema? Would it
  produce a valid change summary?

DIMENSION 5: Cross-Skill Handoff Pipeline
- Map every follow-up tag defined in OPERATIONS.md: emitter → tag → receiver
- For each tag, verify the emitting skill documents it AND the receiving skill
  documents how to accept it
- Check tag format consistency: does the emitter's context format match what the
  receiver expects?
- Are there tags defined in OPERATIONS.md but absent from any skill?
- Are there tags in skills but missing from OPERATIONS.md?
- Map RAID prefix ownership: does each skill use its assigned prefix? Are there
  collisions?
- BEHAVIORAL TEST: Walk through a realistic handoff end-to-end. PPM Agent processes a
  transcript and emits [TECHNICAL]. Read the PPM Agent's tag handoff format, then read
  the Technical Analyst's acceptance section. Does the downstream skill have enough
  context to begin work without re-reading the original source artifact?

DIMENSION 6: Evidence & Quality Standards
- Are evidence labels ([SOURCE], [INFERRED], [ASSUMPTION – CONFIRM], [CONTEXT],
  [RECOMMENDED]) defined in CLAUDE.md AND OPERATIONS.md AND in every skill's behavioral rules?
- Is the QA Auditor's per-skill-output-contracts.md complete? Does it cover all 14
  skills or document which it covers?
- Are guardrails (SG-1, SG-2) present in all required skills?
- BEHAVIORAL TEST: Take a sample claim from a skill output format (e.g., delivery
  engine's gate result). Could the QA Auditor validate it against the output contract?
  Walk through the 6-gate framework.

DIMENSION 7: Document Lifecycle & Tier Compliance
- Are all 4 tiers (Stakeholder-Facing, Operational, New Files, Context) defined and
  enforceable?
- For each tracker in 04-PMO-Operations, which tier is it? Does the assigned skill
  follow the tier protocol (Tier 1 = manual, Tier 2 = propose + approve)?
- Are auto-write folders (05, 06, 08) correctly designated?
- Are Tier 1 files protected from autonomous modification?
- BEHAVIORAL TEST: If the PPM Agent wanted to update the RAID Log (Tier 1), would it
  correctly propose the change rather than write directly? What about updating the
  Daily Status Log (Tier 2)?

---

## Output Format for Session 1

Produce AUDIT_STRUCTURAL.md with this exact structure:

```markdown
# PMO Platform Audit — Phase 1: Structural & Behavioral

**Date:** [Date]
**Auditor:** PMO QA Auditor
**Scope:** 7 dimensions, structural + behavioral

## Executive Summary
[3-5 sentences: overall health, critical findings, recommendation]

## Scorecard
| # | Dimension | Score | Critical Findings | Remediations |
|---|-----------|-------|-------------------|--------------|
| 1 | Context Coherence | P/PT/F | [count] | [count] |
...through 7...

## Dimension Details
[For each dimension: what was checked, what was found, behavioral test result,
specific remediations with file paths and effort estimates]

## Cross-Cutting Findings
[Issues that span multiple dimensions]

## Inputs for Phase 2
[Specific items Phase 2 should test behaviorally based on structural findings.
E.g., "Dimension 5 found tag format mismatch between PPM and TA — Phase 2 should
test this handoff with real data."]

## New Improvement Proposals
[Any findings that should become IMP-### entries, drafted in IMP format]
```

Save to projects/[Project]/08-Generated/AUDIT_STRUCTURAL.md
```

---

## Session 2: Pipeline & Integration Test

**Output:** `08-Generated/AUDIT_PIPELINE.md`
**Duration:** ~45 min (processes real artifacts)
**Prerequisite:** AUDIT_STRUCTURAL.md from Session 1

```
Run Phase 2 of the PMO Platform Operational Readiness Audit.

Read these files in order:
1. core/standards/AUDIT_FRAMEWORK.md (this framework)
2. projects/[Project]/08-Generated/AUDIT_STRUCTURAL.md (Phase 1 findings)
3. projects/_config/SESSION_STATE.md
4. core/governance/OPERATIONS.md

Phase 1 identified structural findings. This session tests whether the platform
works end-to-end with real project data. Use the [Project] project as the
test bed.

Read the "Inputs for Phase 2" section from AUDIT_STRUCTURAL.md — those are targeted
tests based on Phase 1 findings. Execute those PLUS the standard pipeline tests below.

DIMENSION 8: Daily Processing Cycle (End-to-End)
Map OPERATIONS.md's 15-step daily processing cycle. For each step:
- Which skill handles it?
- Is it automated (scheduled task) or manual trigger?
- Is it defined but unimplemented?
Execute the cycle against [Project] data:
a. Pick an unprocessed transcript from 05-Transcripts/ (or the most recent one)
b. Route it through the File Router — record classification result
c. Process through PPM Agent — record all 7 output sections, follow-up tags emitted
d. For each emitted tag, invoke the target skill — record whether the handoff worked
e. Feed results through Tracker Manager — record change summary
f. Generate a daily status update — record whether it's Teams-ready
g. Run QA Auditor on the PPM Agent output — record gate results
Identify where the pipeline pauses for human input vs. runs autonomously.
Score each stage: PASS / PARTIAL / FAIL.

DIMENSION 9: Weekly Synthesis & Portfolio Management
- Simulate the weekly roll-up: read all [Project] inputs the skill would consume
- Can the weekly-status-rollup produce all 6 sections from available data?
- Does the portfolio write-back correctly target PORTFOLIO.md fields?
- Walk through the human-in-the-loop checkpoint — what would the approval prompt
  look like with current [Project] data?
- Is the Friday 5PM scheduled task correctly configured?
- BEHAVIORAL TEST: Generate the weekly roll-up for [Project]. Evaluate whether it's
  executive-ready without editing.

DIMENSION 10: Project Lifecycle Pipeline
Test both ends of the lifecycle:
a. INITIATION: Simulate creating a new project "Warehouse Optimization" (Waterfall,
   go-live Aug 15, partner: [VENDOR_X], sponsor: [COLLEAGUE_A]). Walk through every
   project-initiator step. Would it produce a complete, operational project folder?
   Does it correctly update PORTFOLIO.md? Does the User Setup Checklist cover all
   systems?
b. CLOSURE: Simulate closing the [Project] project (don't actually close it). Walk through
   every Mode B step. Would it finalize all trackers? Produce a closure summary?
   Move to Archive? Update PORTFOLIO.md? Produce the teardown checklist?
c. GAP CHECK: Is there anything the lifecycle doesn't cover? What about the CLOSING
   state (hypercare transition between ACTIVE and CLOSED)?

DIMENSION 11: Automation & Self-Improvement Loop
- Map all scheduled tasks: what runs, when, what it produces
- Trace the improvement lifecycle: how are gaps identified → logged → surfaced →
  executed → verified?
- Check GitHub Issues (label: improvement): are there stale open items that should have been
  acted on? Are closed items actually reflected in live skills?
- What skills can surface new improvements? (PPM Agent, QA Auditor, weekly rollup)
- What skills can execute improvements? (Skill Editor, Skill Creator)
- Is there a feedback loop or does it depend entirely on the user remembering?
- BEHAVIORAL TEST: Identify one gap during this audit. Draft it as an IMP entry.
  Trace how it would get from identification → GitHub Issue → release pipeline →
  verification. Is every step covered by a skill or automation?

---

## Output Format for Session 2

```markdown
# PMO Platform Audit — Phase 2: Pipeline & Integration

**Date:** [Date]
**Scope:** 4 dimensions, real-data behavioral testing
**Prerequisite:** AUDIT_STRUCTURAL.md findings incorporated

## Executive Summary
[Pipeline health, critical breaks, recommendation]

## Pipeline Test Results
| Stage | Skill | Input | Result | Score | Notes |
|-------|-------|-------|--------|-------|-------|
| File Routing | File Router | [transcript] | [classification] | P/PT/F | |
| PPM Triage | PPM Agent | [transcript] | [sections/tags] | P/PT/F | |
| Specialist Handoff | [skill] | [tag context] | [output] | P/PT/F | |
| Tracker Update | Tracker Manager | [changes] | [summary] | P/PT/F | |
| Status Generation | Daily Status | [data] | [Teams msg] | P/PT/F | |
| Quality Gate | QA Auditor | [PPM output] | [gate results] | P/PT/F | |

## Dimension Details
[For each of dimensions 8-11: what was tested, results, specific findings]

## Phase 1 Targeted Test Results
[Results of the specific tests requested by AUDIT_STRUCTURAL.md's "Inputs for Phase 2"]

## Cross-Cutting Findings
[Issues that span pipeline stages or affect multiple skills]

## Inputs for Phase 3
[Readiness-relevant findings. E.g., "Pipeline breaks at tracker update stage —
Tracker Manager doesn't recognize the Daily Status Log schema. This blocks
autonomous daily processing."]

## New Improvement Proposals
[IMP-### entries discovered during testing]
```

Save to projects/[Project]/08-Generated/AUDIT_PIPELINE.md
```

---

## Session 3: Operational Readiness Assessment

**Output:** `08-Generated/AUDIT_READINESS.md`
**Duration:** ~20 min (synthesis, no new testing)
**Prerequisite:** Both AUDIT_STRUCTURAL.md and AUDIT_PIPELINE.md

```
Run Phase 3 of the PMO Platform Operational Readiness Audit.

Read these files in order:
1. core/standards/AUDIT_FRAMEWORK.md (this framework)
2. projects/[Project]/08-Generated/AUDIT_STRUCTURAL.md (Phase 1)
3. projects/[Project]/08-Generated/AUDIT_PIPELINE.md (Phase 2)
4. GitHub Issues — improvement label (`gh issue list --label improvement --state all`)
5. projects/_config/SESSION_STATE.md

This session synthesizes Phases 1 and 2 into an operational readiness score. No new
testing — this is judgment and scoring based on evidence from the prior two phases.

DIMENSION 12: Multi-Project & Scale Readiness
Using findings from Phases 1 and 2, assess:
- If a second project were added tomorrow, what would break?
- Does PORTFOLIO.md support multiple projects in its schema?
- Do daily-status and weekly-rollup handle multiple projects?
- Does the File Router distinguish between projects correctly?
- Are there hardcoded [Project]-specific assumptions in any skill or context file?
- Would the daily processing cycle handle 2 projects without doubling effort?

## Operational Readiness Scoring

Score the platform 1-5 on each criterion using evidence from Phases 1 and 2.
1 = Not functional, 2 = Major gaps, 3 = Works with workarounds, 4 = Works well
with minor gaps, 5 = Production-grade.

| # | Criterion | Score | Evidence | What moves it to next level |
|---|-----------|-------|----------|---------------------------|
| 1 | Autonomous Daily Processing | /5 | Can it process a transcript end-to-end without manual file management? | |
| 2 | Proactive Problem Detection | /5 | Can it detect and surface problems (aging blockers, stale items, drift) without being asked? | |
| 3 | Stakeholder-Ready Output | /5 | Can it produce exec summaries, status updates, and comms without editing? | |
| 4 | Project Onboarding | /5 | Can a new project be scaffolded from inputs and be immediately operational? | |
| 5 | Project Closure | /5 | Can a project be closed with full audit trail and clean archive? | |
| 6 | Self-Improvement | /5 | Can it identify its own gaps, log them, surface them, and guide execution? | |
| 7 | Document Currency | /5 | Can it keep trackers, portfolio, and context files current without manual sync? | |
| 8 | Multi-Project Readiness | /5 | Can it serve 2+ projects simultaneously without cross-contamination? | |
| 9 | Evidence & Traceability | /5 | Can every claim, update, and recommendation be traced to its source? | |
| 10 | Handoff Integrity | /5 | Do cross-skill handoffs work without data loss or format mismatch? | |
| 11 | Automation Coverage | /5 | What % of the defined daily/weekly cycle runs without manual trigger? | |
| 12 | Resilience & Recovery | /5 | Can a new session cold-start and resume operations from file state alone? | |

## Overall Readiness Verdict

Based on the 12 criteria:
- **READY FOR OPERATIONS:** Average ≥ 4.0, no criterion below 3
- **READY WITH CAVEATS:** Average ≥ 3.0, no criterion below 2. List caveats.
- **NOT READY:** Average < 3.0 or any criterion at 1. List blockers.

## Prioritized Remediation Plan

Consolidate ALL findings from Phases 1, 2, and 3 into a single prioritized list:
- P1 (Blocks operations): Must fix before relying on the platform
- P2 (Degrades quality): Fix within 1 week
- P3 (Nice to have): Add to improvement backlog

For each P1/P2 item: specific fix, affected files, effort estimate, which skill
or prompt to use for execution.

## Improvement Backlog Reconciliation

Compare current GitHub Issues (label: improvement) against all audit findings:
- Are there findings that should be new GitHub Issues?
- Are there existing issues that this audit validates or invalidates?
- Are there closed issues whose changes the audit found aren't actually working?
Draft new GitHub Issues in standard format.

## Updated SESSION_STATE.md

Produce the specific edits to SESSION_STATE.md that reflect the audit results.
Include: readiness verdict, key findings summary, next action items.

---

## Output Format for Session 3

```markdown
# PMO Platform Audit — Phase 3: Operational Readiness Assessment

**Date:** [Date]
**Inputs:** AUDIT_STRUCTURAL.md, AUDIT_PIPELINE.md
**Verdict:** [READY / READY WITH CAVEATS / NOT READY]

## Executive Summary
[5 sentences: overall readiness, top strengths, critical gaps, verdict, next action]

## Readiness Scorecard (12 Criteria)
[Table with all 12 criteria scored 1-5]

## Overall Score: [X.X / 5.0]

## Top 3 Strengths
[What the platform does well, with evidence]

## Top 3 Gaps
[Most impactful gaps, with evidence and remediation]

## Consolidated Findings (All Phases)
### P1 — Blocks Operations
[Specific items with remediation]

### P2 — Degrades Quality
[Specific items with remediation]

### P3 — Improvement Backlog
[Items for future sessions]

## Improvement Backlog Updates
[New IMP entries to add, existing entries to update]

## SESSION_STATE.md Updates
[Exact edits to apply]

## Recommended Next Steps
[Ordered list of what to do after this audit]
```

Save to projects/[Project]/08-Generated/AUDIT_READINESS.md
Create GitHub Issues for any new improvement findings.
Update SESSION_STATE.md with audit results.
```

---

## Quick Reference

| Session | Focus | Reads | Produces | Duration |
|---------|-------|-------|----------|----------|
| 1 | Structure + Behavior (7 dimensions) | Context files, skills, references | AUDIT_STRUCTURAL.md | ~30 min |
| 2 | Pipeline + Integration (4 dimensions) | Phase 1 output + real [Project] data | AUDIT_PIPELINE.md | ~45 min |
| 3 | Readiness Score (1 dimension + synthesis) | Phase 1 + Phase 2 outputs | AUDIT_READINESS.md | ~20 min |

**Total:** 12 dimensions, ~1.5 hours across 3 sessions.

---

## Methodology Variation — Audit Criteria

The 12 audit dimensions above are methodology-agnostic at the structural level (every dimension is evaluated under every `delivery_approach`). What varies per [Methodology](../specs/terminology-glossary.md#term-methodology) is the **emphasis weight** and the **evidence type** each dimension privileges. The table below documents archetype-sensitive dimensions; other dimensions (e.g., Dimension 1 Context File Integrity) evaluate identically across all archetypes.

| Archetype | Variation | Applies to | Notes |
|---|---|---|---|
| **Scrum / XP** | Dimension 4 Operational Tracker Health weights **sprint-burndown + velocity** trackers primary; sparse phase-gate evidence is NOT a finding. Dimension 7 Operational Execution Quality weights iteration-cadence decisions + sprint-retro lessons. | Dimension 4, Dimension 7 | [SOURCE] Scrum Guide 2020 — iteration-cadence health metrics. |
| **Kanban** | Dimension 4 weights **flow-efficiency + cycle-time + throughput** trackers primary; absence of sprint-burndown is NOT a finding. Dimension 7 weights continuous-review cadence + class-of-service discipline. | Dimension 4, Dimension 7 | [SOURCE] Kanban Method — flow over velocity. |
| **Waterfall / PRINCE2** | Dimension 4 weights **milestone + phase-gate + change-control logs** primary; absence of sprint trackers is NOT a finding. Dimension 7 weights **phase-gate evidence quality** (sign-off packages, change-control approvals, end-stage assessments); sparse iteration cadence is NOT a finding. | Dimension 4, Dimension 7, Dimension 9 | [SOURCE] PMBOK predictive + PRINCE2 2017 — gate-based evidence. |
| **SAFe** | Dimension 4 weights **PI-objectives + ART-metrics** (predictability, program-velocity) primary. Dimension 7 weights Inspect-and-Adapt workshop quality + PI Planning outputs. Auditor reads PI cadence (8-12 weeks) as baseline, not sprint cadence. | Dimension 4, Dimension 7 | [SOURCE] SAFe 6.0 — PI-level instrumentation. |
| **Hybrid** | Audit dimensions partition by phase — predictive-phase stages audited Waterfall-style; iterative-phase stages audited Scrum-style. Auditor MUST identify the active phase before applying dimension weighting. | Dimensions 4, 7, 9 | [INFERRED] Composition of predictive + iterative audit criteria. |
| **Custom** | See the `custom_methodology_definition` block in PROJECT.md; derive audit emphasis from declared `lifecycle` (continuous → Kanban-style audit; phased → Waterfall-style; timeboxed → Scrum-style) and `artifacts` fields (what evidence should exist). Auditor MUST NOT default to any archetype when `base_archetype` is `null`. | All dimensions | [SOURCE] [`methodology-parameterization-v1.md § Custom Extension Protocol`](../../release/references/specs/methodology-parameterization-v1.md). |
| **All other archetypes + dimensions (archetype-agnostic)** | Dimensions 1-3, 5, 6, 8, 10-12 evaluate identically across archetypes (context file integrity, skill definitions, cross-references, etc.). Not sensitive to `delivery_approach`. | Dimensions 1, 2, 3, 5, 6, 8, 10, 11, 12 | [INFERRED] — structural audit invariants. |

**Consumer guidance.** `pmo-qa-auditor` reads `delivery_approach` at invocation, consults this table, and weights its dimension assessments accordingly. Audit output MUST declare the `delivery_approach` under which the audit was performed so consumers can interpret findings in context.
