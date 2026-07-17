---
title: Anti-Pattern Catalog
purpose: A catalog of 23 recurring eval-design anti-patterns (stable IDs, cite as A-XX) that eval-writer Review mode audits every finding against.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Anti-Pattern Catalog

Condensed from Module 6 §6. 23 anti-patterns that recur in eval design. **In Review mode, audit every finding against this list** — unflagged anti-patterns are the most common failure of eval suites written without a framework.

IDs stable; cite as A-XX.

---

## Foundations

| ID | Anti-pattern | Why harmful | Correct alternative |
|---|---|---|---|
| **A-01** | Relying on generic "helpfulness" LLM judges | Catches nothing useful; gives false comfort; masks real failure modes | Build failure-mode-specific binary judges from trace-driven error analysis |
| **A-03** | Reporting raw accuracy on imbalanced judge classes | 90% accuracy can hide zero recall on minority class | Report precision and recall separately; use κ/α |
| **A-04** | Using 1–5 Likert scales for LLM judges | Inflates verbosity bias; encourages low-information 3s | Binary pass/fail, or 1–4 scales |
| **A-07** | Using raw percent agreement as judge validation | Chance-corrected reliability can be near zero even at 90% raw | Krippendorff α (any data type); Cohen κ (2 raters); Fleiss K (balanced) |

## Agentic

| ID | Anti-pattern | Why harmful | Correct alternative |
|---|---|---|---|
| **A-02** | Trajectory-matching as primary outcome signal | Penalizes valid alternative paths; brittle to error-recovery | State-based outcome check; trajectory eval as secondary diagnostic |
| **A-09** | Letting grader run inside agent's sandbox | Enables reward hacking and direct exploit (RDI: 10-line scripts win) | Isolate grader environment; ground truth unreachable from agent |
| **A-15** | Including agent's CoT in judge prompt when CoT is adversarially shapeable | FPR inflates up to 90% on VLM judges under CoT rewrite | Blind the judge to CoT in production |
| **A-16** | Reporting pass^1 only | Hides catastrophic inconsistency (GPT-4o pass^1 ~50% → pass^8 <25% on Tau-bench retail) | Report pass^k (k ≥ 4) as headline metric |
| **A-17** | Treating one public benchmark number as the capability signal | Benchmarks fragmented along axes; scores not comparable across harnesses (10+ pt deltas) | Portfolio across axes; include private held-out set |
| **A-18** | Training away detected reward hacking without generalization check | Anthropic Sycophancy to Subterfuge: training on recognized hacks teaches stealthier hacks | Test generalization on held-out reward-hack scenarios; monitor evaluation-awareness |
| **A-22** | Delegating first-pass error analysis to an LLM | Criteria emerge from seeing outputs — "never delegate" (Husain/Shankar) | PM or domain expert reads raw traces by hand first; then automate |

## Multi-Agent

| ID | Anti-pattern | Why harmful | Correct alternative |
|---|---|---|---|
| **A-05** | Adding more agents to fix quality problems | 79% of MAS failures are specification/coordination, not capability; extra agents add coordination cost without closing the gap | Audit seams; tighten handoff rubric; reduce decomposition ambiguity; consider removing MAS structure |
| **A-06** | Accepting multi-agent lift without matched-compute baseline | Token usage alone explains 80% of BrowseComp variance; "multi-agent winning" often reduces to "more tokens winning" | Always run `single_agent(tokens = multi_agent_total_tokens)` baseline |
| **A-08** | Prompt-only role enforcement in hierarchical/crew topologies | Role boundaries unenforced at runtime → MAST FM-1.2 violations | Encode authority in graph topology (LangGraph Command), not prompt text |
| **A-10** | Ensembling judges by default | Anthropic found single well-tuned judge outperformed multi-judge ensembles for research eval | Single judge if agreement >90%; add layer only at 70–90%; rework below 70% |
| **A-19** | Naively passing the last message on handoff | Both Cognition and Anthropic agree this is wrong (for different reasons) | Full-trace pass OR summary-plus-filesystem-artifact; measure receiver performance either way |
| **A-20** | Scoring per-agent unit evals as if they predict system quality | Component-sum gap: mean per-agent high, end-to-end low | Three-tier portfolio (unit / seam / system) in parallel |
| **A-21** | Letting the worker train against the same validator in a loop | Reward hacking / co-evolution: worker learns to satisfy surface criteria | Hold validators out of training loop; rotate; held-out validator for eval |

## Operational

| ID | Anti-pattern | Why harmful | Correct alternative |
|---|---|---|---|
| **A-11** | Using `-latest` model aliases for judges or primary agent | Invisible judge drift; longitudinal metrics become meaningless | Pin exact snapshot (e.g. `claude-opus-4-7-20251015`) |
| **A-12** | Capturing message content on by default in prod | PII exfiltration risk; legal retention problems | Content capture off by default; external content store with span references |
| **A-13** | Treating chatbot output as not the company's words | Moffatt v. Air Canada: no "separate legal entity" defense | Treat every output as legally binding company statement unless wrapped in acknowledged disclaimer |
| **A-14** | Using content-moderation guardrail as injection defense | Llama Guard bypassed by ToAP up to 84%; addresses harmful-content, not injected-intent | Add injection-specific defense (PromptArmor/MELON/tool-scope filter) on top |
| **A-23** | Treating RSP/Preparedness frameworks as covering everyday harms | Both frameworks define severity as ~>1,000 deaths or >$100B; they cover tail risk | Layer: RSP/Preparedness at frontier; AgentHarm/AgentDojo for agents; runtime guardrails for everyday |

---

## Review checklist

When auditing existing evals (Review mode), run through this list explicitly:

- [ ] A-01 — Are any judges graded on "helpfulness" rather than failure-mode-specific criteria?
- [ ] A-02 — Is trajectory-matching the primary outcome signal (vs. state-based)?
- [ ] A-03 — Is accuracy reported without precision/recall on imbalanced classes?
- [ ] A-04 — Any 1–5 Likert scales present?
- [ ] A-05 — Any "add more agents to fix quality" patterns?
- [ ] A-06 — Any MAS performance claim without matched-compute baseline?
- [ ] A-07 — Any judge validation using raw percent agreement (vs κ/α)?
- [ ] A-08 — Prompt-only role enforcement in hierarchical topology?
- [ ] A-09 — Grader runs inside agent's sandbox?
- [ ] A-10 — Ensemble judges by default without agreement-threshold justification?
- [ ] A-11 — `-latest` model aliases anywhere?
- [ ] A-12 — Content capture on by default in prod?
- [ ] A-13 — Chatbot outputs treated as separate legal entity?
- [ ] A-14 — Content-moderation guardrail used as injection defense?
- [ ] A-15 — CoT included in judge prompt when CoT is adversarially shapeable?
- [ ] A-16 — pass^1 only (no pass^k)?
- [ ] A-17 — Single public benchmark treated as the capability signal?
- [ ] A-18 — Training away reward hacks without generalization check?
- [ ] A-19 — Last-message-only handoff?
- [ ] A-20 — Per-agent unit evals presumed to predict system quality?
- [ ] A-21 — Worker trained against same validator in a loop?
- [ ] A-22 — LLM delegated first-pass error analysis?
- [ ] A-23 — RSP/Preparedness frameworks used to cover everyday harms?

Each hit gets an entry in the Review report's Anti-pattern hits section with file:line evidence and proposed remediation.
