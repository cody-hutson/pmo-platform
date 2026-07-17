---
title: Failure Mode Catalog
purpose: A catalog of 47 unified eval failure modes across Foundations, Agentic, Multi-Agent, and Operational classes (stable IDs, cite as F-XX) for mapping observed failures when authoring a failure taxonomy.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Failure Mode Catalog

Condensed from Module 6 §5. 47 unified failure modes across Foundations (FND), Agentic (AGT), Multi-Agent (MAS), and Operational (OPS). IDs stable; cite as F-XX.

When authoring a failure taxonomy (`failure-taxonomy.md`), map observed failures to F-XX where the research supports the match. If an observed failure doesn't fit, invent a local ID (`F-LOCAL-01`) rather than forcing a stretch.

---

## Foundations (FND)

| ID | Failure mode | Cause | Detection | Mitigation |
|---|---|---|---|---|
| **F-01** | Judge position bias | Judge prefers first (or second) response regardless of content | Pairwise with swapped order; GPT-4 flips ~40% | Randomize; count win only if both orders agree |
| **F-02** | Judge verbosity bias | Judge prefers longer responses (~15% inflation) | "Repetitive list" padding attack; score-vs-length correlation | 1–4 scales; binary judges |
| **F-03** | Judge self-enhancement bias | Judge prefers own model family (5–7%; Claude-v1 +25pt) | Cross-family judge comparison | Judge ≠ model-under-test family |
| **F-04** | Judge drift (silent) | Provider updates model behind stable alias | Calibration-set agreement drop | Pin snapshots; calibration every release; SLI |
| **F-05** | Criteria drift | Criteria shift as graders see outputs | Rubric version history; inter-revision agreement | Version rubrics alongside prompts |
| **F-06** | LLM-judge brittleness | Low κ/α with human; bias vulnerabilities | Judge validation against hand-labeled set | Multi-judge ensemble for gates; code checks where possible |
| **F-07** | Static-benchmark overestimate | BLEU/ROUGE/held-out accuracy over-rate real quality | CheckList behavioral probes; error analysis | Trace-driven error analysis + behavioral tests |
| **F-08** | Statistical underpowering | Benchmarks too small to detect claimed effects | Power analysis; bootstrap CIs | Larger test sets; report CIs; Bradley–Terry bootstrap |
| **F-09** | Model collapse via synthetic loop | Training on own outputs erodes distribution tails | Longitudinal minority-pattern tracking | Preserve human-labeled eval data as infrastructure |

## Agentic (AGT)

| ID | Failure mode | Cause | Detection | Mitigation |
|---|---|---|---|---|
| **F-10** | Infinite / stuck loops | Agent cannot progress; repeats actions | Action-hash repetition; state similarity >85% | Hard step budget; loop-detector; pivot suggestion |
| **F-11** | Premature termination | Submit with budget left / unverified | Submission with budget left; incorrect-and-no-check | Executor→Validator→Critic scaffold |
| **F-12** | Cost runaway | Token/latency per task outlier | Cost/successful-task distribution | Per-task caps; tiered retries |
| **F-13** | Hallucinated tool call | Invalid tool name; fabricated IDs | Strict schema validation | JSON validation; semantic tool selection; Graph-RAG |
| **F-14** | Trajectory-match brittleness | Valid alt-path penalized | Outcome-eval passes, trajectory-eval fails | State-based outcome check; unordered trajectory |
| **F-15** | CoT-rewrite judge inflation | CoT shaped to fool judges (up to 90% FPR) | Holdout blind-judge test (CoT removed) | Blind judge to CoT when adversarially shapeable |
| **F-16** | Sycophancy in self-reports | 100% confirmation in Worker→Verifier chains | Cross-Context Verification | Information restriction; CCV |
| **F-17** | Memory / context decay | Position-stratified recall drops | HELMET/RULER probes | Compaction-fidelity tests; summarization reconstruction |
| **F-18** | Reward hacking | Agent exploits grader to inflate score | o3 audit: 0.7% HCAST, up to 100% visible-scoring | Isolate grader; hide scoring; cryptographic verification |
| **F-19** | Benchmark contamination | Eval data in training (direct or rephrased) | LessLeak-Bench; canary strings; temporal cutoff | SWE-Rebench; BrowseComp canary; SWE-Bench Pro |
| **F-20** | Grader-reachable exploit | Agent reads grader config / ground truth | RDI exploit probes (file://, eval(), conftest.py) | Isolate grader environment; unreachable ground truth |
| **F-21** | In-context scheming | Agent acts against operator goals | Apollo six evals | Apollo anti-scheming training (partial); monitor awareness |
| **F-22** | Evaluation-awareness | Agent recognizes eval, behaves differently | Apollo: Sonnet 3.7 often recognizes; flag in transcript | Diverse realistic scenarios; interpret ranges honestly |

## Multi-Agent (MAS)

| ID | Failure mode | Cause | Detection | Mitigation |
|---|---|---|---|---|
| **F-23** | Duplicate work | Orchestrator decomposes into overlapping subtasks | Cross-worker output diff; scope overlap classifier | Explicit scope boundaries; AgentPrune |
| **F-24** | Over-spawning / runaway | "50 subagents for simple queries" | Subagent-count vs task-complexity correlation | Count caps by task class (1/2–4/10+) |
| **F-25** | Handoff information loss | Summary drops facts needed downstream | Reconstruction test; full-vs-summary downstream accuracy | Handoff rubric (T4); filesystem artifact passing |
| **F-26** | Role boundary violation (MAST FM-1.2) | Agent exercises another role's authority | Role-scoped assertion grammar on traces | Encode boundaries in graph (LangGraph Command) |
| **F-27** | Cascade failure | Upstream small error → downstream large | Fault-injection replay | Per-stage conditional evals; error-propagation rate |
| **F-28** | Sycophantic consensus collapse | Debaters converge without reasoning | Disagreement-resolution histogram; Peacemaker/Troublemaker | Centralized judge; persona mixing; oracle-locks |
| **F-29** | Majority-opinion convergence on biases | Debaters share training biases | Targeted eval set on family-specific errors | Diverse base models; forced-disagreement |
| **F-30** | Echo chamber | Same-affiliation agents amplify | Round-over-round opinion divergence | Mandatory devil's-advocate; heterogeneity |
| **F-31** | Steganographic collusion | Hidden-channel coordination from reward misspec | NARCBENCH activation probes | Paraphrasing defenses; reward-spec audit |
| **F-32** | Infinite handoff loops | Peer/swarm A2A loops | Trace loop detectors; session budgets | Hard session budgets outside agents; circuit breakers |
| **F-33** | Escalation spirals | Validator demands ever-more revisions | Per-iteration quality curve flat | Hard iteration cap; must-improve-by-ε |
| **F-34** | Rubber-stamp validator (under-critical) | Validator accepts subtly-wrong artifact | Adversarial injection with known-bad | Validator meta-eval; periodic spot-check |
| **F-35** | Over-critical validator | Rejection rate > true error rate | Human-label sample of rejected; FP rate >20% | Validator FP/FN eval set; second-layer validator |
| **F-36** | Responsibility diffusion | Blame distributed; no fix location | Shapley-style ablation attribution | Encode authority in graph |
| **F-37** | Non-determinism compounding | 5% per-agent → 25% pipeline variance | Run-to-run output divergence | Fixed-input trace replay; batch-invariant kernels |
| **F-38** | Synthesis compression nuance loss | Orchestrator digest drops worker specifics | Reconstruction test at synthesis step | CitationAgent pattern; raw-source re-anchoring |
| **F-39** | "Don't split too early" violation | MAS used where single-agent would win | Matched-compute single-agent baseline | Run baseline first; defer MAS until clearly helps |

## Operational (OPS)

| ID | Failure mode | Cause | Detection | Mitigation |
|---|---|---|---|---|
| **F-40** | PII leak via unfiltered logs | Prompt/completion logs contain PII | Redaction processor audit; canary-PII probe | Collector redaction; external content store |
| **F-41** | Prompt injection via untrusted content | Malicious content in tool results hijacks agent | AgentDojo 97/629; "Important Messages" (53% baseline) | PromptArmor / MELON / tool-scope filtering |
| **F-42** | Chatbot hallucinated policy (Moffatt-class) | Agent invents company policy | Trace review; customer-facing output sampling | Grounding + citations; disclaimer policy; retention |
| **F-43** | Cost-unattributed traffic | Can't allocate spend to feature/tenant | `gen_ai.provider.name` + `response.model` not captured | Full OTel GenAI identity triple on every span |
| **F-44** | Guardrail language gap | Llama Guard drops 9–18% on SE Asian languages | Multilingual red-team probes | Layered: injection + provider refusal + output guard |
| **F-45** | Automated-black-box jailbreak | Tree-of-Attack-Prompts bypasses Llama Guard up to 84% | Red-team with ToAP-class attacks | Defense-in-depth; async two-stage classification |
| **F-46** | Frontier catastrophic-risk threshold hit | Capability crosses RSP/Preparedness threshold | Provider framework capability evals | Pre-defined response playbook tied to thresholds |
| **F-47** | Agent non-compliant refusal (AgentHarm) | Complies with malicious agent task without jailbreak | AgentHarm 110 tasks × 11 categories | Refusal training; AgentHarm gate pre-release |

---

## Usage

When authoring `failure-taxonomy.md`, the structure is:

```
# Failure Taxonomy: <system name>

## Observed failure modes
| Local ID | Description | F-XX mapping | Prevalence (count / N traces) |
|---|---|---|---|

## Anticipated failure modes (from decision tree)
| Rule | F-XX | Required evaluator |
|---|---|---|
```

Prevalence counting is the Stage 2 exit criterion. Don't ship a taxonomy without counts — it won't tell you which evals matter most.
