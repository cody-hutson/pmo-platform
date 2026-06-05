# Process Documentation — PMO Reference

## Purpose

This file provides the framework for creating, classifying, and governing process
documentation across delivery methodologies. The pmo-process-designer skill reads
this file in Mode B (Process Documentation & Optimization) to guide documentation
decisions, template selection, and investment calibration.

---

## Diataxis Documentation Framework

Every document serves one of four purposes. Mixing purposes within a single document
degrades effectiveness for all reader types. Classify every document by its primary
Diataxis quadrant before writing.

| Quadrant | Purpose | Audience Need | Structure | Example |
|----------|---------|--------------|-----------|---------|
| **Tutorial** | Learning-oriented | "Help me get started" | Step-by-step guided exercise; sequential; narrated; outcome at each step visible | "Your First Sprint: Setting Up the Board" |
| **How-To Guide** | Task-oriented | "Help me solve a specific problem" | Problem statement → prerequisites → numbered steps → verification → troubleshooting | "How to Escalate a Risk to the Steering Committee" |
| **Explanation** | Understanding-oriented | "Help me understand why" | Conceptual; discusses alternatives, trade-offs, history, design rationale | "Why We Use WSJF Instead of MoSCoW" |
| **Reference** | Information-oriented | "Help me look something up" | Tabular; exhaustive; no narrative; designed for scanning, not reading | "RAID Severity Definitions and SLA Targets" |

**Classification decision:**

| If the reader needs to... | Then write a... |
|--------------------------|-----------------|
| Learn a new skill or capability from scratch | Tutorial |
| Accomplish a specific task they already understand conceptually | How-To Guide |
| Understand why something works the way it does | Explanation |
| Look up a specific fact, parameter, or definition | Reference |

**Anti-pattern — Quadrant mixing:** A document titled "How to Configure Risk Thresholds"
that opens with 3 pages of risk management theory before reaching the steps. The theory
belongs in an Explanation document; the steps belong in a How-To Guide. Link between them
rather than combining.

---

## JBGE Decision Checklist

Before creating any process document, answer these five questions. If the answer to
question 4 is "yes," do not create the document — use the simpler format instead.

| # | Question | Decision Impact |
|---|----------|----------------|
| 1 | **Who will consume this document?** | Determines depth, vocabulary, and Diataxis quadrant |
| 2 | **What decision will it inform?** | If no decision, challenge whether the document is needed |
| 3 | **What is the minimum content needed for that decision?** | Sets the upper bound on scope; everything beyond this is waste |
| 4 | **Is there a simpler format (conversation, demo, test, board policy) that achieves the same purpose?** | If yes, use the simpler format — document is not the default |
| 5 | **Will this document be maintained? By whom? At what cadence?** | If no maintenance plan, the document will become stale — which is worse than no document (false confidence) |

**JBGE does NOT mean minimal documentation.** A regulated environment with JBGE may
still produce substantial documentation — because the risk, audience, and compliance
requirements justify the investment. JBGE means proportional, not minimal.

---

## Process Documentation Template

Use this template for any process document. Every section is required; mark "N/A"
with rationale if a section does not apply.

| Section | Content | Required? |
|---------|---------|-----------|
| **Process Name** | Clear, unambiguous name; matches the name used in conversation and tools | Yes |
| **Process Owner** | Named individual (not a role or team) accountable for process health | Yes |
| **Diataxis Classification** | Primary quadrant this document serves (Tutorial, How-To, Explanation, Reference) | Yes |
| **Trigger** | What event initiates this process (time-based, event-based, or on-demand) | Yes |
| **Inputs** | What artifacts, data, or decisions must exist before the process starts | Yes |
| **Preconditions** | System state or organizational conditions required | Yes |
| **Steps** | Numbered, sequential actions with decision points explicitly marked | Yes |
| **Decision Points** | For each branch in the process: condition, options, decision authority, and default | Yes |
| **Outputs** | What artifacts, data, or state changes the process produces | Yes |
| **Consumers** | Who uses the outputs; what they use them for | Yes |
| **Exception Handling** | What happens when the process fails, is blocked, or encounters unexpected input | Yes |
| **Metrics** | How process health is measured (cycle time, error rate, compliance rate) | Recommended |
| **Review Cadence** | When this document is reviewed for accuracy (quarterly minimum) | Yes |
| **Version History** | Date, author, change description for each modification | Yes |

---

## Documentation Investment Decision Model

Use this matrix to determine the appropriate documentation investment level.
Assess each factor independently; the highest-investment factor determines the floor.

| Factor | Comprehensive | Balanced | Minimal |
|--------|-------------|----------|---------|
| **Regulatory requirements** | FDA, SOX, HIPAA, government contracts | Industry-standard compliance | No external requirements |
| **Team stability** | High turnover; geographically distributed | Moderate stability | Stable, co-located team |
| **System complexity** | Enterprise integration; multi-vendor; multi-system | Standard complexity | Single-team, single-system |
| **Audit requirements** | Formal audit trails required | Periodic review | Self-governing |
| **Knowledge risk** | High bus factor risk; critical institutional knowledge | Moderate | Low; knowledge distributed |
| **Longevity** | Process will exist for years; multiple handoffs expected | 6-12 month horizon | Short-lived; prototype or spike |
| **Audience breadth** | Multiple teams, external partners, regulatory bodies | Single team + stakeholders | Team-internal only |

**Scoring:** Count factors in each column. Majority determines investment level.
When factors split evenly, default to the higher investment level — under-documentation
is harder to recover from than over-documentation (McKinsey: $13,500/employee annual
loss from knowledge search costs).

---

## Documentation Quality Criteria

Every process document must satisfy these five quality dimensions:

| Dimension | Definition | Validation Question |
|-----------|------------|-------------------|
| **Unambiguous** | Only one interpretation possible for each statement | "Could two reasonable people read this differently?" |
| **Testable** | Each process step produces a verifiable outcome | "How would I confirm this step was done correctly?" |
| **Traceable** | Links to upstream requirements and downstream outputs are explicit | "Can I trace from this process to the business need it serves?" |
| **Current** | Content reflects actual current practice, not aspirational state | "Is this how we actually do it today, or how we wish we did it?" |
| **Maintainable** | Structured so updates are localized; no duplicated content | "If this process changes, how many documents need updating?" |

---

## Documentation Philosophy by Methodology

| Philosophy | Approach(es) | Principle | Typical Investment | PMO Application |
|-----------|-------------|-----------|-------------------|-----------------|
| **Minimal** | XP, Agile Philosophy | Working software > docs; code and tests are primary documentation | Embedded in code; story cards; TDD as requirements | Appropriate for team-internal technical processes; NOT for cross-team governance |
| **Just Enough** | DA, Kanban, Scrumban | JBGE — sufficient for purpose, no more | Explicit board policies; actionable, not bureaucratic | Default for most PMO operational processes; apply JBGE checklist |
| **Living** | Kanban, Lean | Process-explicit; documented policies evolve experimentally | Continuous updates; policies as living documentation | Board policies, explicit flow policies, WIP governance |
| **Balanced** | Scrum, Hybrid | Essential governance docs + lightweight delivery docs | DoD includes documentation; sprint-embedded updates | Sprint-level process docs; governance templates |
| **Hierarchical** | SAFe | Multi-level documentation aligned to organizational altitude | Team → ART → Solution → Portfolio layers | Multi-altitude process documentation; Solution Intent |
| **Comprehensive** | Waterfall, PRINCE2 | Full document suite; "if it isn't documented, it doesn't exist" | 20-40% of project time on documentation | Regulated environments; compliance-driven projects |

**Key insight:** Documentation quality matters universally. Documentation volume varies
by approach. Both minimal-and-high-quality (Agile) and comprehensive-and-high-quality
(Waterfall) can achieve high DORA scores. The variable is quality, not volume.

---

## Anti-Patterns

| Anti-Pattern | Signal | Root Cause | Remediation |
|-------------|--------|------------|-------------|
| **Zombie Artifacts** | Zero views in 90 days; no edits; "we've always had it" | Mandated without purpose; never audited | Quarterly audits; "read it or kill it"; archive artifacts with <2 views in 90 days |
| **Over-Documentation** | >20% of team time on documentation vs. delivery | Template mandates without cost-benefit analysis | Apply JBGE checklist to every document; challenge every mandate with ROI reasoning |
| **Under-Documentation** | Critical knowledge in heads only; bus factor = 1 | "Because agile" used to justify zero documentation | Bus factor >1 rule; JBGE does not mean zero |
| **Stale Artifacts** | Outdated but referenced as current (most dangerous pattern) | No freshness monitoring; updates not in change management | Automated staleness detection; review cadence enforced; 40% of users view out-of-date docs |
| **Cargo Cult Artifacts** | 20+ artifacts for 3-person project; created "because PMOs do this" | Template mandates applied without context assessment | Question every artifact against JBGE; tailor to project scale |
| **Template-Driven Artifacts** | All projects produce identical documents regardless of context | Template completion treated as quality substitute | Understand template intent; adapt to context; defend deviations |
| **Documentation Debt** | Artifacts progressively behind reality | Documentation maintenance not budgeted | Treat as risk; budget maintenance explicitly; include doc updates in DoD |
