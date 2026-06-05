# PMO Skill Anti-Patterns

## Usage

Catalog of common PMO-skill failure modes observed across the 2026-04-18 skill review (`<OPERATOR_INSTANCE_ANALYSIS_PATH>/skill-review-2026-04-18/`). The refiner loads this file during Interview Mode and generates probing questions per anti-pattern so the new skill surfaces these failure modes before shipping.

Each entry conforms to the `failure-mode-standard.md` 5-field template (Signature, Conditional, Root cause, Mitigation, Principal-vs-junior response) and carries a category tag (TRIG / INPUT / PROC / OUT / HAND). These are the failure modes to probe **during** Interview Q5 and Q9 — they are NOT what a new skill's own `## Domain-Specific Failure Modes` section should restate. A new skill's failure modes must be specific to its domain, not inherited from this catalog.

---

## 1. Generic guardrails restated as domain-specific failure modes — OUT

- **Signature (observable signal):** A skill's `## Domain-Specific Failure Modes` section has ≥ 3 entries but each restates a CLAUDE.md universal preference ("no `[INSERT]` placeholders," "evidence labels required," "no question flooding"). G7 Phase 1 structural regex passes; G7 Phase 2 content check rejects on generic-guardrail restatement. Observed in 20 of 20 current skills per the 2026-04-18 review.
- **Conditional:** do NOT ship a `## Domain-Specific Failure Modes` section that restates CLAUDE.md universal preferences, because the section's purpose is to document the skill's own domain-specific failure surface — restating platform-wide guardrails provides no incremental discipline and signals under-specified domain understanding.
- **Root cause:** The 3-entry floor is visible and easy to satisfy by copying guardrails. Surfacing real domain-specific failure modes requires deeper thinking about the skill's input/process/output surface than re-listing what CLAUDE.md already enforces.
- **Mitigation:** During Interview Q5, require each candidate failure mode to pass three filters: (a) specific to this skill's domain, (b) observable from this skill's inputs or outputs, (c) grounded in this skill's failure surface. Loop Q5 if < 3 candidates pass.
- **Principal response vs. junior response:** Principal surfaces 4–6 domain-specific failure modes because the skill's scope demands them. Junior lists generic guardrails, passes regex, and ships — waiting for pmo-qa-auditor Phase 2 to find the gap.

## 2. Reversibility tier omitted on decision-class outputs — OUT

- **Signature (observable signal):** A skill produces recommendations, plans, or escalations without any CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE tier label. G4 pmo-qa-auditor gate FAILS on the skill's outputs in the next audit cycle.
- **Conditional:** do NOT produce decision-class output without a reversibility tier paired with confidence, because the user cannot calibrate process weight (confirm vs. sign-off gate) without knowing the cost of reversal — missing tier forces either unsafe auto-proceed or over-ceremonious review.
- **Root cause:** Reversibility discipline was added to the platform after many skills were authored; retrofitting requires per-output labeling discipline the original skill design did not enforce. New skills inherit the gap if the refiner does not inject the section.
- **Mitigation:** Interview Q3 establishes decision-class vs. report-only. Form A injection (decision-class) is required; the skill body cannot ship without a typical-tier-mix table for its outputs.
- **Principal response vs. junior response:** Principal knows reversibility is a contract the skill owes downstream reviewers; the table is part of the skill's documented surface. Junior treats reversibility as a runtime decision per output, fails to document, and ships a skill that G4 rejects.

## 3. Methodology assumed rather than parameterized — TRIG

- **Signature (observable signal):** A skill hardcodes waterfall ("per phase-gate review") or agile ("sprint planning output") assumptions without checking `delivery_approach`. The skill then either misfires on projects using the other methodology, or silently applies waterfall logic to an agile project (or vice versa).
- **Conditional:** do NOT hardcode a single methodology when the skill's behavior changes materially across waterfall / agile / kanban / hybrid, because PMO projects span methodologies and a skill that assumes one produces wrong output on the others — often subtly wrong, which is worse than obviously wrong.
- **Root cause:** The author is working on a specific project with a specific methodology at authoring time; generalizing requires declaring the field and branching behavior. Shortcut: write for the observed methodology and ship.
- **Mitigation:** Interview Q4 establishes `delivery_approach`. If the skill's behavior is methodology-sensitive, the skill body branches on the field. If `delivery_approach` is `n/a` (methodology-agnostic), the skill's logic must prove methodology-independence — Q4 probes for this explicitly.
- **Principal response vs. junior response:** Principal parameterizes from day one even if only one methodology is exercised at authoring time — the field is cheap to add, expensive to retrofit. Junior writes for one methodology, discovers the gap when the skill is applied to a project using another, and ships a retrofit.

## 4. Output contract absent from per-skill-output-contracts.md — HAND

- **Signature (observable signal):** A skill has a well-defined output format in its SKILL.md body but no entry in `core/schemas/per-skill-output-contracts.md`. pmo-qa-auditor Mode A has no canonical schema to audit against; audit results default to "schema not registered" rather than specific pass/fail.
- **Conditional:** do NOT ship a skill without registering its output contract in per-skill-output-contracts.md, because the contract is what pmo-qa-auditor audits — unregistered output has no audit surface and drifts silently over future iterations.
- **Root cause:** Registration is an additional file-edit step beyond writing the SKILL.md; fast-path skill authoring skips it. The refiner's step 8 automates this, but only if Interview Q7 populates the schema source.
- **Mitigation:** Interview Q7 elicits the output contract (required sections, evidence labels, RAID prefix, validation checklist). The refiner's Create-New workflow step 8 registers Skill N concurrently with the skill body injection. Registration is not optional.
- **Principal response vs. junior response:** Principal treats per-skill-output-contracts.md as part of the skill's deliverable surface. Junior treats it as administrative overhead, ships the skill, and the audit gap surfaces in the next pmo-qa-auditor cycle.

## 5. Dependency-graph node undeclared — HAND

- **Signature (observable signal):** A skill has real upstream (reads from another skill's output) and downstream (produces output consumed by another skill) edges, but no entry in `core/knowledge-base/dependency-graph.md`. Cross-skill impact analysis (e.g., pmo-skill-editor's suite coherence check) misses the edges.
- **Conditional:** do NOT ship a skill without registering its dependency edges in dependency-graph.md, because cross-skill impact analysis depends on the graph being complete — missing edges lead to regression risk when an upstream skill changes and the downstream skill's assumptions silently break.
- **Root cause:** Similar to anti-pattern 4 — registration is an extra step. Authors think of the skill as standalone and miss the edges.
- **Mitigation:** Interview Q6 elicits upstream and downstream edges. The refiner's step 8 registers the `### <skill-name>` node concurrently with the body injection. For new skills that genuinely have no dependencies (pure utilities), the node still registers with `Upstream: None (entry point or standalone)` so the graph is complete.
- **Principal response vs. junior response:** Principal enumerates dependencies explicitly — even declaring "none" is informative. Junior declines to register "because the skill has no dependencies," leaving the graph ambiguous.

## 6. Evidence labels missing on internal analysis — INPUT

- **Signature (observable signal):** A skill's output carries evidence labels on user-facing claims, but the skill's internal analysis (intermediate reasoning, inferred facts, derivation chains) has no labels. An auditor reading the skill's trace cannot distinguish sourced facts from inferences from assumptions.
- **Conditional:** do NOT apply evidence quality labels only to user-facing output, because the skill's internal analysis chain is what produces the output — unlabeled intermediate inferences propagate into user-facing claims without the label discipline that would have flagged the inference.
- **Root cause:** Evidence discipline is framed in CLAUDE.md as a universal preference, visible in user-facing output. The internal analysis surface is less visible; authors apply discipline where they see output, not where they reason.
- **Mitigation:** The `## Evidence Quality Protocol` injection (field 4) mandates internal-analysis labeling explicitly. The refiner's pre-handoff gate cannot structurally enforce this (internal analysis is emergent at runtime), but the skill body declares the discipline so runtime agents honor it.
- **Principal response vs. junior response:** Principal treats evidence discipline as a reasoning hygiene standard applied to every factual claim, regardless of visibility. Junior applies it at the output boundary and produces high-confidence-looking outputs over un-evidenced reasoning chains.

## 7. Trigger set built on synthetic phrasings — INPUT

- **Signature (observable signal):** A skill's `description:` field contains 3–5 trigger phrasings that read fluently but were never observed in real user transcripts, tickets, or session logs. The skill either undertriggers (user phrasing in practice doesn't match) or overtriggers (trigger phrasings overlap adjacent skills).
- **Conditional:** do NOT finalize the `description:` field with trigger phrasings that lack T1/T2 evidence (transcript line, user ticket, observed invocation miss) when the user has not explicitly waived evidence-grounding, because synthetic trigger sets produce Gulf of Intention failures — the skill is invoked at wrong moments or not invoked when needed, and the factory's description optimization loop cannot fix misaligned phrasing without evidence-grounded queries.
- **Root cause:** Synthetic phrasings are cheap and sound plausible. Real evidence requires the user to retrieve transcripts or recall session history. Under throughput pressure, the refiner accepts plausible over evidenced.
- **Mitigation:** Interview Q2 requires T1/T2 evidence per candidate. Candidates without evidence are rejected unless the user explicitly waives with rationale logged. The description-trigger optimization loop (`scripts/run_loop.py`) requires evidenced queries in its 60/40 train/test split.
- **Principal response vs. junior response:** Principal demands evidence citations even when it slows the session — the cost of a wrong trigger set compounds over every future invocation. Junior accepts fluent phrasings, ships, and the description is re-optimized in a follow-up pass after real trigger rate data lands.

## 8. Principal Standard not targeted — PROC

- **Signature (observable signal):** A skill's SKILL.md has no `## Principal Standard Target` section or the section omits a declared Scoring Guide target tier. The skill ships without a self-stated bar; later reviews against the principal-standard-checklist.md reveal FAIL — below the CONDITIONAL PASS bar.
- **Conditional:** do NOT skip declaring a Principal Standard PASS target at creation when the skill's complexity warrants CONDITIONAL PASS or better (all non-utility skills), because the declared target is what the refiner's pre-handoff gate enforces — skipping declaration means shipping without a bar, and the factory effect compounds when many skills skip together.
- **Root cause:** Principal Standard is subjective and feels optional; concrete fields like Output Contract feel obligatory. Authors ship when the feature-visible fields are complete and treat competency targeting as an afterthought.
- **Mitigation:** Interview Q8 requires a declared target and enumerates which competencies the skill strengthens vs. risks (per the Scoring Guide tier definitions). Refiner's pre-handoff gate runs the checklist; if tier below target, iterate SKILL.md. If post-iteration still below target, escalate as scope change — the skill may need narrowing.
- **Principal response vs. junior response:** Principal owns the target and iterates until the skill meets it — including narrowing scope if the skill cannot sustainably hit CONDITIONAL PASS or better. Junior ships at the first feature-complete draft and lets the first audit find the gap.

---

## Cross-reference map

| Anti-pattern | Root reference | Refiner injection field addressing it |
|---|---|---|
| 1. Generic guardrails restated | `failure-mode-standard.md` | Field 5 (Domain-Specific Failure Modes) + pre-handoff content check |
| 2. Reversibility tier omitted | `reversibility-protocol.md` | Field 6 (Reversibility Discipline) |
| 3. Methodology assumed | `pmo-platform-context.md` § Methodology | Field 1 (`delivery_approach` frontmatter) |
| 4. Output contract unregistered | `per-skill-output-contracts.md` | Field 2 (Output Contract stub) + concurrent registration |
| 5. Dependency-graph node undeclared | `dependency-graph.md` | Field 3 (Dependency Graph Node stub) + concurrent registration |
| 6. Evidence labels missing internal | CLAUDE.md § Universal Preferences | Field 4 (Evidence Quality Protocol clause) |
| 7. Synthetic triggers | skill-creator § Review Trigger Set Discipline (archival reference in this refiner) | Interview Q2 evidence requirement |
| 8. Principal Standard untargeted | `principal-standard-checklist.md` | Field 7 (Principal Standard Target) + pre-handoff check |
