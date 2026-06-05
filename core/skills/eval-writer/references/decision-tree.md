# Master Decision Tree

Condensed from Module 6 §3 and §8 "Skill-Ready Decision Logic." Every rule is checkable from the Stage 0 five-tuple (single vs multi-agent, tool use, HITL, dev vs prod, safety-criticality). Multiple rules may apply — union the recommended eval portfolios.

Rule IDs are stable. References:
- `T-N` = Rubric template N in `rubric-templates.md`
- `F-XX` = Failure mode in `failure-modes.md`
- `A-XX` = Anti-pattern in `anti-patterns.md`

---

## Block A — Foundations (apply to every system)

### RULE F-A1: ALL SYSTEMS
**Require:** Stage 1 trace capture, Stage 2 hand-coded error analysis, Stage 3 evaluators, Stage 4 judge validation with α/κ + precision/recall.
**Templates:** T1 (base).
**Guards:** F-01..F-09 (all foundation failure modes), A-01, A-03, A-04, A-07, A-22.

### RULE F-A2: JUDGE IN PRODUCTION
**Condition:** `judge_used = true` AND `stage = production`
**Require:** pinned model snapshot; calibration set on every release; judge-vs-human agreement as live SLI.
**Guards:** F-04, F-05; A-11.

### RULE F-A3: PAIRWISE JUDGE
**Condition:** `judge_output_is_pairwise = true`
**Require:** swapped-order re-run; count win only if both orders agree.
**Guards:** F-01.

### RULE F-A4: SELF-ENHANCEMENT RISK
**Condition:** `judge_model_family = agent_model_family`
**Require:** cross-family judge OR flag self-enhancement risk in judge report.
**Guards:** F-03.

---

## Block B — Agentic (tool-using agents)

### RULE B-A1: TOOL-USING AGENT
**Condition:** `tool_use = true`
**Require:** T3 (tool-call correctness, 5 BFCL dimensions); state-based outcome check (T7); forbid primary reliance on trajectory-matching.
**Guards:** F-13, F-14; A-02.

### RULE B-A2: STRUCTURED OUTPUT
**Condition:** `tool_use = true` AND `output_is_structured = true`
**Prefer:** code assertion over LLM judge on structural checks.

### RULE B-A3: HIGH AUTONOMY
**Condition:** `agent_autonomy = high` OR `agent_can_write_to_env = true`
**Require:** METR-style elicitation (spurious / real / tradeoff classification); time-horizon against frozen human-baselined set; Apollo scheming probe smoke test; evaluation-awareness transcript flag; grader isolation from agent sandbox.
**Guards:** F-18, F-19, F-20, F-21, F-22; A-09.

### RULE B-A4: PUBLIC BENCHMARK
**Condition:** `benchmark_source = public`
**Require:** contamination audit (canary, temporal cutoff, RDI probe); private held-out set.
**Guards:** F-19, F-20; A-17.

### RULE B-A5: RELIABILITY REPORTING
**Condition:** `reliability_report_requested = true`
**Require:** pass^k (k ≥ 4), not pass^1; report cost-per-task.
**Guards:** A-16.

### RULE B-A6: ADVERSARIAL CoT
**Condition:** `judge_prompt_includes_CoT = true` AND `CoT_is_adversarially_shapeable = true`
**Require:** remove CoT from judge input (keep observations and actions only).
**Guards:** F-15; A-15.

---

## Block C — Multi-Agent

### RULE C-A1: ANY MAS
**Condition:** `multi_agent = true`
**Require:** three-tier portfolio (unit 20–30% / seam 30–40% / system 30–50%); T4 at every seam; failure attribution pipeline.
**Guards:** F-23..F-39; A-05, A-20.

### RULE C-A2: MAS PERFORMANCE CLAIM
**Condition:** `multi_agent = true` AND `claim = multi_agent_better`
**Require:** matched-compute single-agent baseline; do not accept claim without it.
**Guards:** F-39; A-06.

### RULE C-A3: HUB / HIERARCHICAL
**Condition:** `topology = hub-and-spoke` OR `topology = hierarchical`
**Add:** routing accuracy eval; decomposition quality eval; re-planning eval with forced-worker-failure injection; duplicate-work probe; subagent-count caps by task class (Anthropic 1 / 2–4 / 10+ heuristic).
**Guards:** F-23, F-24, F-26, F-38.

### RULE C-A4: PIPELINE
**Condition:** `topology = pipeline`
**Add:** handoff rubric at every seam; per-stage conditional-on-correct-input eval; compounding-loss probe (full vs summarized context).
**Guards:** F-25, F-27, F-38; A-19.

### RULE C-A5: PEER-TO-PEER / SWARM
**Condition:** `topology = peer-to-peer` OR `topology = swarm`
**Add:** who-speaks-next correctness eval; convergence / termination metrics; hard loop detector enforced outside agents.
**Guards:** F-10, F-32.

### RULE C-A6: DEBATE / EVALUATOR-OPTIMIZER
**Condition:** `topology = debate` OR `topology = evaluator-optimizer`
**Add:** judge self-preference probe; debater heterogeneity ablation; per-iteration quality curve; iteration cap + ε-improvement termination; sycophancy / consensus-collapse detection.
**Guards:** F-28, F-29, F-30, F-33.

### RULE C-A7: VALIDATOR-IN-THE-LOOP
**Condition:** `topology = validator-in-the-loop`
**Add:** validator FP/FN eval set; adversarial injection test with known-bad; validator held out from training; periodic rotation.
**Guards:** F-34, F-35; A-21.

### RULE C-A8: PROMPT-ONLY ROLES
**Condition:** `role_enforcement = prompt-only` AND `topology = hierarchical`
**Flag:** A-08; recommend graph-encoded role boundaries (LangGraph Command, etc.).

### RULE C-A9: JUDGE ENSEMBLE DECISION
**Condition:** `multi_agent = true`
**Apply thresholds:**
- `first_judge_agreement_with_human ≥ 0.90` → use single judge (do not ensemble by default)
- `0.70 ≤ agreement < 0.90` → add second judge from different family
- `agreement < 0.70` → rework rubric; adding layers won't fix it

**Guards:** A-10.

---

## Block D — Operational / Production

### RULE D-A1: PRODUCTION INSTRUMENTATION
**Condition:** `stage = production`
**Require:** OTel GenAI v1.37+; `gen_ai.provider.name`, `gen_ai.request.model`, `gen_ai.response.model`, `gen_ai.conversation.id` on every span.
**Guards:** F-43.

### RULE D-A2: PII HANDLING
**Condition:** `stage = production` AND `data_has_PII = true`
**Require:** content capture off by default; external content store with span references; Collector redaction + tail-sampling + routing processors.
**Guards:** F-40; A-12.

### RULE D-A3: USER-FACING
**Condition:** `stage = production` AND `user_facing = true`
**Require:** input + output guardrails (Llama Guard or equivalent); legal disclaimer policy; retention for tort limitation period (2–6 years).
**Guards:** F-42, F-44, F-45, F-47; A-13.

### RULE D-A4: UNTRUSTED CONTENT INGEST
**Condition:** `stage = production` AND `agent_ingests_untrusted_content = true`
**Require:** prompt-injection-specific defense on top of content guardrail (PromptArmor, MELON, tool-scope filtering).
**Guards:** F-41; A-14.

### RULE D-A5: COST ATTRIBUTION
**Condition:** `stage = production` AND `cost_attribution_required = true`
**Require:** compute `gen_ai.usage.input_tokens × provider_price` as Collector metric; per-tenant token budgets as rate limits.

### RULE D-A6: HIGH-STAKES RELEASE GATE
**Condition:** `release_gate = true` AND `safety_criticality = high`
**Require:** heterogeneous judge ensemble (3–5 models) at gate. Continuous monitoring can remain single-judge if F-A2 is satisfied.

### RULE D-A7: FRONTIER
**Condition:** `agent_frontier_class = true`
**Require:** map capability thresholds to provider RSP v3 / Preparedness v2; maintain pre-defined response playbook.
**Guards:** F-46; A-23.

---

## Block E — Terminology & Precision (self-guards)

### RULE E-A1: CANONICAL TERMS
**Condition:** `user_term in aliases_table`
**Require:** rewrite to canonical term (Module 6 §1) before dispatching downstream rules.

### RULE E-A2: HONESTY OVER COMPLETENESS
**Condition:** `rule_requires_metric` AND `metric_is_undefined_in_system`
**Require:** return a gap-flag, not a fabricated metric.

### RULE E-A3: CITATION PROVENANCE
**Condition:** `claim_source not in [M1, M2, M3, M4]`
**Refuse:** encoding it. Flag for module-6-out-of-scope or §10 Open Question.

---

## Usage pattern

For each rule that fires off the Stage 0 5-tuple, union the required evaluators, templates, failure guards, and anti-pattern alerts. Output the union set. For rules with conditional `Require` (D-A6's high-stakes gate), the playbook must check the stated condition — don't blindly apply.

Tensions (Module 6 §10) where rules disagree — single-judge vs ensemble, MAS claim vs matched-compute baseline — are surfaced as "judgment required" in the output, not hidden.
