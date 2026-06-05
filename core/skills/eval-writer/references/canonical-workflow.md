# Canonical Eval Authoring Workflow

Condensed from Module 6 §2. The 10-stage end-to-end process from "I have a system" to "I have an eval suite in production." **eval-writer covers Stages 0–4 (authoring / validation). Stages 5–10 are execution / monitoring and belong to downstream harnesses** (`anthropic-skills:skill-creator`, CI, observability stack).

Each stage has entry criteria, activities, artifacts produced, and exit criteria. The exit criteria gate advancement — don't skip ahead.

---

## In scope for eval-writer

### Stage 0 — System characterization
**Entry:** The system exists (prototype or deployed).
**Activities:** Classify along five axes:
1. Single-agent vs multi-agent
2. Tool use (yes / no)
3. HITL present (escalation, review, sign-off) or fully autonomous
4. Dev vs production stage
5. Safety-criticality (routine / regulated / safety-critical)
**Artifacts:** `characterization.md` — the 5-tuple + topology diagram for MAS.
**Exit:** 5-tuple fully specified.

### Stage 1 — Trace capture
**Entry:** Stage 0 complete.
**Activities:** Instrument the system so every run emits a full trace: messages, tool calls, retrievals, state transitions, per-agent inputs and outputs, token usage, latency. In production, conform to OTel GenAI semantic conventions (`gen_ai.operation.name`, `gen_ai.request.model`, `gen_ai.response.model`, `gen_ai.provider.name`, `gen_ai.usage.input_tokens`, `gen_ai.usage.output_tokens`, `gen_ai.conversation.id`).
**Artifacts:** A corpus of ≥ a few dozen real traces (ideally hundreds).
**Exit:** Traces replayable; content capture policy documented (off by default in prod).
**eval-writer's role:** Point the user at the right trace-capture pattern for their system. For pmo-platform skills, traces are typically "a user said X, the skill produced Y" — straightforward. For agentic systems with tool use, require full-trace capture before proceeding.

### Stage 2 — Error analysis (hand-coded)
**Entry:** Trace corpus available.
**Activities:** PM or domain expert reads traces and writes free-form failure notes. **Never delegate the first pass.** Cluster notes into a binary failure taxonomy, counting prevalence.
**Artifacts:** `failure-taxonomy.md` — categories + prevalence counts. For MAS, map each failure to MAST's 14-mode taxonomy and classify as specification / coordination / verification-termination.
**Exit:** Taxonomy stabilized; reviewer can assign new traces to existing categories >80% of the time without adding categories.
**Why it matters:** Criteria drift (F-05) means you cannot specify "good" before seeing outputs. Generic helpfulness judges catch nothing useful (A-01). The hand-coding step is the highest-leverage activity in the whole stack.

### Stage 3 — Evaluator construction
**Entry:** Taxonomy stabilized.
**Activities:** For each failure mode, choose evaluator type:
- **Code assertion** where possible (regex, JSON schema, tool-call validation). Always prefer over LLM judge for structural checks.
- **LLM-as-judge** only for subjective cases. **Binary pass/fail output preferred** over 1–5 scores (A-04). If using an ordinal scale, use 1–4 rather than 1–5 to force concision reward and reduce verbosity bias.
- **Reference answers** in the prompt where available; **custom rubric** encoded in the prompt.
- **Blind the judge to the agent's chain-of-thought** whenever the CoT can be adversarially shaped (F-15, A-15 — CoT rewrites inflate VLM-judge FPR up to 90%).

**Artifacts:** `judge_prompts/*.md` — one file per judge. `rubrics.md` — scoring dimensions and thresholds. A typical production suite has 2–3 code evals and 1–2 LLM judges — focused, not comprehensive.
**Exit:** Every failure mode has at least one evaluator.

### Stage 4 — Judge validation
**Entry:** Evaluators drafted.
**Activities:** Treat every judge as a classifier. Hand-label a sample set (≥30 items). Report **precision and recall separately** (classes are usually imbalanced); do not rely on raw accuracy (A-03). Measure chance-corrected agreement (Krippendorff α preferred, Cohen κ for 2 raters, Fleiss K for balanced multi-rater nominal). Apply bias mitigations: randomized pairwise order + position-consistency check (only count a win if both orders agree); cross-family judging to reduce self-enhancement bias; 1–4 scales to reduce verbosity bias.

**Artifacts:** `calibration-protocol.md` — judge validation specification: sample size, labeling rubric, α/κ thresholds, precision/recall reporting, bias-test protocol.
**Exit:**
- α ≥ 0.80 → reliable conclusions; single judge suffices
- 0.67 ≤ α < 0.80 → tentative; add second layer from different model family
- α < 0.67 → **rework the rubric, not the judge ensemble** (A-10)
- If first judge achieves >90% agreement with human on held-out set, a single judge suffices; 70–90%, add a second layer of different base model; <70%, rework the rubric not add layers.

---

## Out of scope for eval-writer (execution / monitoring)

eval-writer produces the content for these stages but does not execute them. Downstream harnesses (`anthropic-skills:skill-creator`'s evals.json → grading.json → benchmark.json loop, CI systems, production observability) consume eval-writer's outputs.

### Stage 5 — Portfolio selection (capability + reliability)
Select capability benchmarks per axis (SWE-bench Verified, WebArena, BFCL, GAIA, etc.). Add reliability metrics: **pass^k** rather than pass^1, progress rate for long-horizon, cost-per-task. For MAS, add the **matched-compute single-agent baseline** — Anthropic found token usage alone explains 80% of BrowseComp variance (F-39, A-06).

### Stage 6 — Contamination & exploit audit
Assume every public benchmark is contaminated until proven otherwise. Run RDI-style probes: can the agent reach the grader? the config? the ground truth? Check for canary-string completion. Prefer temporal cutoffs (LiveCodeBench, SWE-Rebench), canary strings, and private / copyleft sourcing (SWE-Bench Pro). **Isolate the grader's execution environment from the agent's.**

### Stage 7 — Elicitation & safety stream (frontier / autonomous)
METR's elicitation protocol: best available scaffold per model, classify failures as spurious / real / tradeoff, 6 trials per task, time-horizon against frozen human-baselined set. Apollo's six scheming probes (Oversight Subversion, Self-Exfiltration, Goal-Guarding, Covert Email Reranking, Instrumental Alignment Faking, Sandbagging) with strong-goal-nudge and no-nudge conditions. Instrument for evaluation-awareness.

### Stage 8 — MAS-specific seam and attribution evals
Three-tier portfolio — unit / seam / system (20–30% / 30–40% / 30–50%). Handoff rubric at every seam (Template 4). MAST-style failure attribution pipeline. Matched-compute single-agent baseline for any MAS claim.

### Stage 9 — Production instrumentation & guardrails
Five non-negotiable layers: OTel GenAI instrumentation; pinned judge ensemble against versioned calibration set on every release; cost control (prompt caching, Batch API, per-tenant budgets); safety (Llama Guard + injection defense); governance (retain for tort limitation period 2–6 years, internal versioned Model/System Card).

### Stage 10 — Continuous monitoring, drift detection, refresh
Run calibration set every deployment and track agreement drift. Quarterly post-cutoff benchmark refresh (SWE-Rebench pattern). Version rubrics alongside prompts (criteria drift is real). Preserve genuine human-labeled data as infrastructure.

---

## How eval-writer hands off

When authoring completes (Stage 4 exit), the output should enable a downstream harness to execute the portfolio. For pmo-platform skills, that harness is `anthropic-skills:skill-creator` — its `evals.json` schema is the handoff format. For stage-gates, the handoff format is `gate-evaluation-spec.md`'s three-layer assessment protocol. For generic systems, the user specifies where artifacts land.

The handoff is explicit in the output: eval-writer's final message names the next actor and the file(s) they should read.
