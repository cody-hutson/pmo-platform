---
name: pmo-skill-refiner
description: >
  Creates and refines PMO-platform skills by wrapping an Anthropic scaffolding
  skill (default: anthropic-skills:skill-creator) with a PMO refinement layer.
  Captures intent via Interview mode (methodology, failure modes, dependencies,
  reversibility, trigger evidence), delegates commodity scaffolding to the
  Anthropic skill, then injects PMO-platform fields into the produced SKILL.md
  (delivery_approach, output-contract stub, dependency-graph node, evidence-
  quality protocol, failure-mode discipline, Principal Standard checklist,
  reversibility declaration). Runs the preserved eval harness from skill-creator
  (variance analysis, description-trigger optimization, blind A/B comparison,
  cross-skill false-positive detection). For modifying EXISTING PMO skills,
  coordinates with pmo-skill-editor. Use when the user wants to create a new
  PMO skill or iterate on an existing skill's eval/description/trigger set.
version: v1.10
license: BUSL-1.1
skill_discipline_migrated_v10_2: true
---

# PMO Skill Refiner

A narrower refinement wrapper over an Anthropic scaffolding skill that injects PMO-platform awareness and runs the preserved eval/optimization harness.

## When to use vs. skip

**Use this skill when:**
- Creating a new skill that will live under `release/skills/<name>/` (a PMO-platform skill, not a generic skill).
- Iterating on an existing PMO skill's eval set, trigger description, or benchmark — specifically the rigor work (quantitative eval, variance analysis, blind A/B, description-trigger optimization).
- Injecting missing PMO-platform fields into a skill that pre-dates the 7-field injection discipline.

**Skip and route elsewhere when:**
- Generic non-PMO skill creation → route to `anthropic-skills:skill-creator` directly.
- Modifying existing skills' SKILL.md structure absent eval work (adding a mode, reorganizing sections, editing Output Contract shape) → route to `pmo-skill-editor` directly.
- Creating a plugin with commands, hooks, MCP servers (not just a skill) → route to `cowork-plugin-management:create-cowork-plugin` directly.

The refiner's unique value-add is the PMO injection layer plus the preserved eval rigor (variance analysis, cross-skill false-positive detection, description-trigger optimization loop) on PMO-suite skills. Anywhere else is over-applying the tool.

## Use When

Common operator phrasings that route to this skill (preserved as trigger-matching examples for the description-trigger optimization loop):

**For new-skill creation:**
- "create a pmo skill for [X]"
- "build a skill for the pmo platform"
- "scaffold a new platform skill"

**For existing-skill refinement:**
- "iterate on the [skill] skill"
- "optimize triggers for [skill]"
- "run evals on [skill]"
- "benchmark [skill]"
- "refine [skill]'s description"

## Operating Principles

**Template-protocol consumption.** When refining a skill that produces a template-like artifact (delivery-engine RAID, eval-writer rubric, release-planner release-plan-template, etc.), validate that the produced artifact's lifecycle complies with `core/standards/template-protocol.md` (state machine, provenance schema, T1-T5 / P1-P5 gates) and that compliance is documented in the refined skill's behavioral markers. New skill-authored templates default to `skill-internal-standalone` unless P1-P5 promotion gates are met. See [`OPERATIONS.md § Template Protocol`](../../../core/governance/OPERATIONS.md).

## Modes

Three modes, sequenced as a pipeline: Interview always fires first, then Mode 2 or Mode 3 depending on intent.

| Mode | Trigger | Purpose |
|---|---|---|
| **1. Interview** | Any invocation | Capture structured intent packet (9 questions → markdown blob) |
| **2. Create New** | Interview + "new skill" intent | Wrap Anthropic scaffold → inject 7 PMO fields → run eval harness → register contracts → hand off |
| **3. Refine Existing** | Interview + "refine [skill-name]" intent | Delta-focused interview → baseline eval → scope-route (refiner vs. editor vs. both) → apply changes → blind A/B → hand off |

## Workflow — Create New Skill

Executed after Interview produces a complete packet and user intent is "new skill."

1. **Invoke wrapped Anthropic scaffolding skill** — default `anthropic-skills:skill-creator`; alternative `cowork-plugin-management:create-cowork-plugin` only on operator request. Pass the Interview packet's Q1/Q2/Q3 answers as structured input. Log which skill was invoked in the session transcript for reproducibility.
2. **Capture Anthropic output** — SKILL.md draft, any test cases, any evals the scaffolder produced.
3. **Validate Anthropic output** — confirm frontmatter parses, required `name`/`description` present. If malformed, HALT and report to user — do not inject (see §Domain-Specific Failure Modes, PROC entry).
4. **Apply PMO template** — read `references/pmo-platform-template.md` and inject the 7 PMO fields into the Anthropic-produced SKILL.md. Preserve whatever Anthropic produced; inject, don't replace.
5. **Run quantitative eval** — invoke `scripts/run_eval.py` against the Q3 output format. Apply variance analysis and gaming detection. Save to `<skill>-workspace/iteration-1/benchmark.json`.
6. **Run description-trigger optimization** — invoke `scripts/run_loop.py` with Q2 trigger phrasings as seed. Apply `best_description` to the frontmatter if delta exceeds the configured threshold.
7. **Extend regression-checks.md** — append new skill's entry per `references/regression-protocol.md`. Create the file if it does not yet exist.
8. **Register contracts** — append Skill N entry to `core/schemas/per-skill-output-contracts.md` (Q7 is the schema source); append `### <skill-name>` node to `core/knowledge-base/dependency-graph.md` (Q6 is the edge source).
9. **Self-compliance pre-handoff checks** (see §Pre-Handoff Gate below):
   - G7 Phase 1 structural regex on `## Domain-Specific Failure Modes` (≥ 3 matches, tag per category).
   - Principal Standard CONDITIONAL PASS or better per `core/standards/principal-standard-checklist.md` Scoring Guide.
   - Reversibility section present with tier vocabulary pinned to `reversibility-protocol.md` (or explicit report-only opt-out).
   - Zero `[INSERT]` / `[TBD]` placeholders (CLAUDE.md guardrail).
   - Cross-references resolve (every `references/*.md` path, every link to per-skill-output-contracts.md, dependency-graph.md, failure-mode-standard.md, reversibility-protocol.md).
10. **Hand off** — produce a handoff message with: (a) path to new SKILL.md, (b) path to workspace with eval evidence, (c) pre-handoff gate evidence summary, (d) deploy instruction with pre-deploy canonical-session check per `references/pmo-platform-context.md`.

## Workflow — Refine Existing Skill

Executed after Interview produces a delta-focused packet and user intent is "refine [skill-name]."

1. **Load target** — read `release/skills/<name>/SKILL.md` into context.
2. **Delta-focused interview** — only questions where existing answers are missing or the user has indicated change. Skip Q1 if `description` is present and intent is not a redesign; skip Q5 if `## Domain-Specific Failure Modes` already has ≥ 3 conforming entries.
3. **Baseline eval** — run `scripts/run_eval.py` on the current version. Save to `<skill>-workspace/iteration-<N>/baseline/`.
4. **Determine change scope:**
   - **Structural** (SKILL.md section reorg, mode addition, Output Contract shape change) → **HAND OFF to `pmo-skill-editor`**. Refiner's value-add is eval + PMO-injection, not structural editing.
   - **Eval-only** (description optimization, trigger tuning, benchmark improvement) → proceed in refiner.
   - **PMO-field injection** (missing reversibility section, outdated failure modes, missing `delivery_approach`) → proceed in refiner.
5. **Apply changes** — inject missing PMO fields per `references/pmo-platform-template.md`; run `scripts/run_loop.py` if description optimization requested; run blind A/B via `agents/comparator.md` if user requested rigorous comparison.
6. **Blind A/B vs. current version** — if eval delta ≥ configured threshold, keep new version; else keep current and report regression.
7. **Update regression-checks.md** — append new iteration reference per `references/regression-protocol.md`.
8. **Hand off** — same evidence bundle as Mode 2; flag any scope that routed to pmo-skill-editor.

**Boundary rule:** If a user request straddles refiner and editor scope (e.g., "add a new mode AND optimize the description"), run refiner-scope first, then explicitly delegate editor-scope to `pmo-skill-editor` as a distinct invocation with refiner output as input.

## PMO Injection Points

Seven fields injected into the Anthropic scaffold per `references/pmo-platform-template.md`. Each is concurrent with a platform-file registration where applicable — the stub in the skill body points at the authoritative registration.

| # | Field | Location | Source | Concurrent registration |
|---|---|---|---|---|
| 1 | `delivery_approach` frontmatter | YAML | Interview Q4 | None (frontmatter only) |
| 2 | `## Output Contract` stub | Body | Interview Q7 | Append Skill N to `per-skill-output-contracts.md` |
| 3 | `## Dependency Graph Node` stub | Body | Interview Q6 | Append `### <skill-name>` to `dependency-graph.md` |
| 4 | `## Evidence Quality Protocol` clause | Body | CLAUDE.md § Universal Preferences | None |
| 5 | `## Domain-Specific Failure Modes` section (≥ 3 conditional clauses) | Body | Interview Q5 + Q9 | None; G7 gate validates |
| 6 | `## Reversibility Discipline` section (or report-only opt-out) | Body | Interview Q3 + `reversibility-protocol.md` | None; G4 gate validates |
| 7 | `## Principal Standard Target` declaration | Body | Interview Q8 + `principal-standard-checklist.md` | None |

See `references/pmo-platform-template.md` for the exact placeholder template and `references/pmo-antipatterns.md` for the failure modes the refiner probes for during Interview.

## Interview Mode

Always fires first. Loads `references/pmo-platform-context.md` into context so the refiner asks informed questions about the platform (Layer 1/Layer 2 boundary, dependency graph conventions, delivery_approach semantics, shared contracts).

Nine questions, asked conversationally rather than as a checklist:

| # | Question | Drives |
|---|---|---|
| Q1 | What should this skill enable Claude to do? | Anthropic scaffolder `purpose` + PMO `description` |
| Q2 | When should this skill trigger? Give 3–5 real-world phrasings with T1/T2 evidence. | Trigger discipline; synthetic phrasings rejected |
| Q3 | Output format? Decision-class (recs/plans/escalations) or report-only? | Reversibility injection branch |
| Q4 | `delivery_approach` (waterfall/agile/kanban/hybrid/n/a)? Methodology-sensitive? | Frontmatter field |
| Q5 | Enumerate ≥ 3 domain-specific failure modes, "do NOT X when Y, because Z" format. | Failure-mode injection; refiner LOOPS Q5 if < 3 real answers |
| Q6 | Upstream and downstream PMO skills? | dependency-graph.md node |
| Q7 | Shared contracts honored? (RAID prefix, evidence labels, follow-up tags, output contract.) | per-skill-output-contracts.md Skill N |
| Q8 | Principal Standard target — which competencies (per `principal-standard-checklist.md`) does this skill strengthen vs. risk, and what Scoring Guide tier is targeted? | Principal-standard section; pre-handoff self-check |
| Q9 | Principal-vs-junior gradient for each Q5 failure mode? | 5th field of each failure-mode entry |

**Exit criteria:** All nine answers collected, or refiner flags under-specification (< 3 real Q5 answers, zero T1/T2 evidence on Q2) and returns to clarification. An under-specified domain is a signal to sharpen intent, not a signal to proceed with synthetic fill-ins.

## Pre-Handoff Gate

Pre-PR checks the refiner runs against the produced SKILL.md before declaring the skill ready. Failing any check returns the refiner to iteration — do not hand off a SKILL.md that fails its own gate.

| Check | Pass criterion | Escalation if fail |
|---|---|---|
| G7 Phase 1 (structural) | Regex `do NOT .+?(?:\s+when\s+.+?)?,\s+because\s+.+` matches ≥ 3 within `## Domain-Specific Failure Modes`; every `###` heading carries a TRIG/INPUT/PROC/OUT/HAND tag | Iterate failure modes — return to Interview Q5 if < 3 real answers |
| Principal Standard (CONDITIONAL PASS or better) | Scoring Guide tier CONDITIONAL PASS or better on self-check per `principal-standard-checklist.md` | Iterate SKILL.md content; if post-iteration still FAIL after ≥ 2 passes, ESCALATE to operator as scope change (skill scope may need narrowing) |
| Reversibility section | Decision-class: tier vocabulary pinned to `reversibility-protocol.md` and each decision-class mode carries a declared tier. Report-only: explicit opt-out statement present | Revise section; do not proceed without coverage |
| Zero `[INSERT]` / `[TBD]` | Grep returns zero matches | Fill placeholders or return to Interview for missing data |
| Cross-reference resolution | Every references/*.md path, every external doc link resolves to an existing file/section | Fix broken reference or remove the claim |

**Key behavioral rule:** the refiner iterates its own output against its own gate. If iteration cannot hit the bar, escalation is the correct move — silently shipping a sub-gate skill creates the factory-effect the refiner was built to prevent.

## Eval Framework

The refiner runs the preserved eval harness (`scripts/run_eval.py`, `scripts/run_loop.py`, `scripts/run_eval_audit.py`, plus `agents/grader.md`, `agents/comparator.md`, `agents/analyzer.md`, and the `eval-viewer/` UI). See `references/eval-framework.md` for the full workflow — script inventory, variance-analysis and gaming-detection interpretation, blind A/B protocol, and the description-trigger optimization loop end-to-end.

Workspace convention for regression tracking:
```
release/skills/<skill-name>-workspace/
├── iteration-1/
│   ├── benchmark.json
│   ├── grading.json
│   ├── timing.json
│   ├── feedback.json
│   ├── eval_metadata.json (one per eval)
│   └── run_loop_output.json
├── iteration-2/...
```
Multi-iteration persistence lets the refiner detect regression across passes — iteration N's pass rate must not drop below iteration N−1's without rationale.

## Regression Protocol

When creating or modifying a PMO skill, the refiner extends platform-level regression checks so the skill has an always-on behavioral baseline. See `references/regression-protocol.md` for the full protocol. The refiner automates this as step 7 in Create-New and step 7 in Refine-Existing — no manual intervention.

## Anti-Patterns

Common PMO-skill failure modes the refiner probes for during Interview, each formatted in the `failure-mode-standard.md` 5-field template. See `references/pmo-antipatterns.md` for the catalog (8 entries: generic-guardrails-restated, reversibility-tier-omitted, methodology-hardcoded, output-contract-unregistered, dependency-graph-node-undeclared, evidence-labels-missing-on-internal-analysis, trigger-set-synthetic, principal-standard-untargeted).

## Reversibility Discipline

This skill produces decision-class outputs. Every decision-class item the refiner emits — the refined SKILL.md itself, the `best_description` selection from `run_loop.py`, the benchmark analyst pass, the handoff decision — carries a reversibility tier (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) paired with confidence (HIGH / MEDIUM / LOW) per `core/specs/reversibility-protocol.md`. pmo-qa-auditor G4 validates tier labeling on outputs.

Typical tier mix for the refiner's outputs:

| Output | Typical tier | Rationale |
|---|---|---|
| Refined SKILL.md (Create-New) | CHEAP · HIGH | Net-new file; `git revert` undoes in seconds |
| Refined SKILL.md (Refine-Existing) | MODERATE · MEDIUM | Overwrites existing skill; if worse than baseline, blind A/B catches it — if gate missed, regressed skill deploys until next pmo-qa-auditor pass |
| `best_description` selection from `run_loop.py` | CHEAP · HIGH | One-line frontmatter edit; reverts cleanly |
| Handoff decision (route to pmo-skill-editor vs. proceed) | CHEAP · HIGH | Changing mid-flight is trivial; mis-routes cost one cycle of work |
| Registration of Skill N in per-skill-output-contracts.md / dependency-graph.md | CHEAP · HIGH | Additive section; revert removes cleanly |

## Principal Standard Target

CONDITIONAL PASS or better at creation per `core/standards/principal-standard-checklist.md` Scoring Guide.

Competencies this skill naturally strengthens:
- **Systems Thinking** — wrapper pattern + injection discipline requires seeing the factory effect across the skill suite.
- **Ruthless Clarity** — Interview mode produces a structured packet rather than a conversational blur.
- **Evidence-Based Execution** — Q2 requires T1/T2 trigger evidence; refiner rejects synthetic phrasings.
- **Judgment Under Uncertainty** — reversibility discipline injected into every decision-class output; tier declaration is non-negotiable.
- **Operational Awareness** — the refiner knows its boundary (hand-off to pmo-skill-editor for structural work) rather than over-scoping.
- **Learning & Escalation** — pre-handoff gate forces iteration; if iteration fails, the refiner escalates scope rather than shipping a sub-gate skill.

Competencies the refiner is at risk for:
- **Organizational Leverage** — the refiner is narrow; leverage compounds only when many new skills are created via it. Short-term it looks expensive.
- **Mentorship & Culture** — the refiner does not itself teach skill-authoring; it structurally enforces the disciplines. Mentorship still lives with the operator + `pmo-skill-editor` Mode D reviews.

## Domain-Specific Failure Modes

### Injection before scaffold validation — PROC

- **Signature (observable signal):** A produced SKILL.md has frontmatter where `name:` is present but `description:` is malformed (empty, unclosed block-scalar, or contains raw placeholder tokens), yet the refiner has already appended `## Output Contract` / `## Dependency Graph Node` stubs. The injection produced structured sections over a malformed base.
- **Conditional:** do NOT inject PMO template fields when the Anthropic scaffold output has not produced a syntactically valid SKILL.md (frontmatter parses, required `name`/`description` present), because injecting into a malformed file introduces silent corruption that looks like a successful refinement but fails G7 Phase 1 structural checks downstream and burns an iteration budget before the root cause is visible.
- **Root cause:** The scaffolder's output is trusted without validation because the scaffolder "just ran" — pressure to move to the rigor layer (run eval, optimize description) skips the one-minute YAML-parse step. The injection additively overlays sections, so malformed base survives into handoff.
- **Mitigation:** Between step 2 (capture) and step 4 (inject), run a hard validation: parse the YAML frontmatter, assert `name` and `description` exist and are non-empty, assert the body contains at least a top-level `#` heading. On failure, halt and surface the scaffolder's output to the user with the parse error — do not inject.
- **Principal response vs. junior response:** Principal treats the scaffolder's output as input to validate, not as truth to propagate — the scaffolder is an external dependency and its output contracts need enforcement at the boundary. Junior takes "scaffolder succeeded" as license to proceed and discovers the corruption at the pre-handoff gate, mid-eval, or worst, post-merge during pmo-qa-auditor audit.

### Interview accepts synthetic trigger phrasings — INPUT

- **Signature (observable signal):** Interview Q2 captures 3–5 trigger phrasings but the session transcript shows no T1/T2 evidence citations — no transcript quote, no user-ticket reference, no observed-invocation-miss note. The refiner moves to Create-New with a trigger set built on what "sounds plausible."
- **Conditional:** do NOT proceed past Interview Q2 with trigger candidates that lack real-world sourcing (transcript line, user ticket, observed invocation miss) when the user has not explicitly waived evidence-grounding, because synthetic trigger sets produce Gulf of Intention failures at invocation time — the refined skill either undertriggers or overtriggers and requires a remediation cycle the refiner was created to prevent.
- **Root cause:** Synthetic phrasings are fast and fluent; real evidence takes user effort to retrieve. The refiner is biased toward session throughput ("let's get the skill written") over the upstream evidence step. The result looks identical to a properly evidenced trigger set until the skill is in production.
- **Mitigation:** For each Q2 answer, require the user or session transcript to cite the source. If the user cannot cite ≥ 1 evidence source per trigger candidate, loop Q2 — probe for analogous past sessions, related skill invocations, or domain-specific phrasings from the user's actual work. Accept an explicit waiver only when the user states it ("I know these are hypothetical; proceed anyway"), and record the waiver in the session log so the resulting skill's description is marked as synthetic-trigger-sourced for later scrutiny.
- **Principal response vs. junior response:** Principal refuses to ship synthetic triggers silently — either the evidence is produced or the waiver is logged, and a waiver is treated as a follow-up debt. Junior accepts plausible phrasings, moves on, and the resulting skill's description shows 30–40% trigger-rate on the held-out eval test split — the gate the refiner was supposed to enforce.

### Hand off with under-specified failure-mode section — OUT

- **Signature (observable signal):** A refined SKILL.md has a `## Domain-Specific Failure Modes` section with exactly 3 entries, each of which restates a CLAUDE.md universal preference (no `[INSERT]`, evidence labels required, no question flooding) without naming a domain-specific conditional signal. G7 Phase 1 structural regex passes (3 matches of the pattern); G7 Phase 2 content check rejects on "generic platform-guardrail restatement."
- **Conditional:** do NOT hand off a refined SKILL.md when its `## Domain-Specific Failure Modes` section has < 3 entries or contains only platform-guardrail restatements, because under-specified failure surfaces produce skills that pass G7 Phase 1 structural checks but fail G7 Phase 2 LLM-graded content checks in production audit, shipping a false-positive structural pass that compounds the factory-effect the refiner was built to end.
- **Root cause:** G7 Phase 1 regex is visible to the refiner (it can be checked with grep); G7 Phase 2 content assessment runs downstream (pmo-qa-auditor). The refiner optimizes for the visible gate ("3 matches regex — pass") and ships, trusting that Phase 2 will catch content quality. The consequence is 3–5 day remediation cycles on skills that should never have left the factory.
- **Mitigation:** After G7 Phase 1 regex matches, perform an inline content check: is each entry's `X` specific to this skill's domain (not "be sloppy")? Is each `Y` observable from this skill's inputs or outputs (not "when working")? Is each `Z` grounded in this skill's specific failure surface (not "because it's wrong")? If any entry fails any of these three tests, treat the gate as failed and iterate. Lean on `references/pmo-antipatterns.md` during Interview to probe for real domain-specific failure modes.
- **Principal response vs. junior response:** Principal runs both gates (structural + content) before declaring the skill ready — G7 Phase 1 is necessary but not sufficient. Junior passes structural gate, hands off, and learns the content gap from the first pmo-qa-auditor audit, one release cycle too late.

### Deploy before canonical-session verification — HAND

- **Signature (observable signal):** A handoff message tells the user `core/deploy/deploy.sh --deploy pmo-skill-refiner` without prior evidence that `core/deploy/deploy.sh --check` was run on an idle main branch. The handoff proceeds and either deploys successfully (lucky) or deploys to the orphaned session (broken factory; invisible to the user until next invocation miss).
- **Conditional:** do NOT run `core/deploy/deploy.sh --deploy pmo-skill-refiner` when `core/deploy/deploy.sh --check` has not been run on an idle main branch to confirm the detected install path resolves to the canonical (not orphaned) session, because the D6 session-inversion risk (deploy-detection investigation pending) means deploying to the wrong session breaks the factory worse than the skill-creator status quo — the operator loses the skill-creation capability entirely with no visible signal until the next skill-creation attempt fails silently.
- **Root cause:** deploy.sh auto-detects an install path via fingerprint scanning; detection is probabilistic, not authoritative. In sessions where skills-plugin has multiple session UUIDs (from plugin reinstalls, app updates, or account re-auth), detection can resolve to the wrong session. The refiner does not own session detection — that belongs to deploy.sh and the deploy-detection investigation — but the refiner's handoff sequence can either respect or ignore the pre-check.
- **Mitigation:** In the handoff message produced by Workflow step 10 (Create-New) or step 8 (Refine-Existing), embed an explicit `core/deploy/deploy.sh --check --warn` pre-check with a pass criterion ("expected: exit 0 with ≥ 20 PASS rows"). Instruct the user to abort deploy on non-clean check output and surface via the deploy-detection investigation. Never provide a bare `--deploy` instruction without the pre-check paired.
- **Principal response vs. junior response:** Principal respects the boundary — session canonicity lives in deploy.sh and the deploy-detection investigation, and the refiner's job is to route the user through the correct runbook sequence. Junior treats deploy as "the obvious next step" and provides the raw deploy command, assuming session detection will "just work" — until it doesn't.

### Refiner pipeline applied to a skip-route request — TRIG

- **Signature (observable signal):** The full refiner pipeline — nine-question
  Interview, PMO 7-field injection, eval harness — runs against a request the
  When-to-use-vs-skip table routes elsewhere: a generic non-PMO skill, a
  structural-only SKILL.md edit with no eval work, or a plugin with commands,
  hooks, or MCP servers.
- **Conditional:** do NOT run the refiner pipeline when the request matches a
  skip-route row (generic non-PMO skill → anthropic-skills:skill-creator;
  structural edit absent eval work → pmo-skill-editor; plugin creation → the
  plugin tooling), because the refiner's value-add is the PMO injection layer
  plus eval rigor on PMO-suite skills — over-applying it injects platform
  fields into artifacts that must not carry them and burns the interview and
  harness budget on work the routed tool does directly.
- **Root cause:** The refiner reads as "the skill factory," so every
  skill-adjacent request gravitates to the wrapper; the skip table exists but
  sits after the trigger match, and running the familiar pipeline feels more
  thorough than handing off.
- **Mitigation:** Make the skip-table check the first act of every invocation,
  before Interview Q1: classify the request against the three skip rows; on a
  match, route to the table's named destination with a one-line reason.
  Boundary-straddling requests (eval work plus structural change) split per the
  boundary rule — refiner scope first, explicit editor delegation second.
- **Principal response vs. junior response:** Principal routes the generic skill
  to skill-creator and notes what the refiner would add if it ever joins the
  PMO suite. Junior interviews for nine questions, injects delivery_approach
  and dependency-graph stubs into a generic utility skill, and the consumer now
  carries PMO-platform fields it cannot honor.

### Eval-suite authoring absorbed into the refiner instead of eval-writer — TRIG

- **Signature (observable signal):** During a refinement session the refiner
  authors substantive eval content — new judge prompts, rubrics, failure
  taxonomies, calibration protocols — from its own judgment rather than routing
  the authoring to eval-writer; the workspace gains eval artifacts that never
  passed the trace-driven, binary-judge, calibration-protocol discipline.
- **Conditional:** do NOT author new eval-suite content (judge prompts, rubrics,
  failure taxonomies, calibration protocols) inside the refiner when the need is
  eval authoring rather than harness execution, because eval-writer owns
  authoring per the 2026 eval-writing consensus (trace-driven criteria, binary
  judges, cross-family calibration) — the refiner's preserved harness EXECUTES
  suites (run_eval.py, run_loop.py, blind A/B); it has no authoring framework,
  and refiner-authored judges skip the disciplines that keep judges honest.
- **Root cause:** The refiner's Use When list includes "run evals on [skill]"
  and "benchmark [skill]," and an eval-shaped session invites filling eval gaps
  inline; writing a quick judge prompt feels like part of the iteration loop,
  and the author/execute boundary lives in eval-writer's Role text, not in the
  refiner's own skip table.
- **Mitigation:** When a refinement session surfaces an eval-content gap
  (missing judge, no rubric, taxonomy holes), hand the authoring to eval-writer
  (Author mode, per-skill playbook) and consume its artifacts in the next
  harness run; the refiner's in-scope eval work is execution, variance
  analysis, description-trigger optimization, and A/B comparison over authored
  suites.
- **Principal response vs. junior response:** Principal pauses the iteration,
  routes the missing judge to eval-writer, and re-runs the harness against the
  authored artifact. Junior drafts a judge prompt inline "to keep the loop
  moving"; it is a five-point single-family judge with no calibration set, and
  the suite's verdicts drift unvalidated for the next three iterations.

## References

- `references/pmo-platform-template.md` — PMO-aware SKILL.md scaffold template (7 injection fields)
- `references/pmo-platform-context.md` — Platform architecture, Layer 1/2 boundary, dependency-graph schema, shared contracts
- `references/pmo-antipatterns.md` — Catalog of 8 common PMO-skill failure modes to probe during Interview
- `references/eval-framework.md` — Preserved eval harness invocation, variance analysis, blind A/B, description-trigger optimization
- `references/regression-protocol.md` — How the refiner extends `regression-checks.md` when creating or modifying a skill
- `references/schemas.md` — evals.json / grading.json / benchmark.json / timing.json / feedback.json schemas (preserved from skill-creator)
- `scripts/` — preserved eval harness (run_eval.py, run_loop.py, run_eval_audit.py, aggregate_benchmark.py, improve_description.py, package_skill.py, quick_validate.py, generate_report.py, utils.py)
- `agents/` — preserved subagents (grader.md, comparator.md, analyzer.md)
- `eval-viewer/` — preserved HTML review UI (generate_review.py, viewer.html)
- `assets/eval_review.html` — preserved description-optimization review template

## Relationship to other PMO skills

- **Upstream:** External — `anthropic-skills:skill-creator` (default wrap target per ADR-01/D16) or `cowork-plugin-management:create-cowork-plugin` (alternative). Platform-internal: `failure-mode-standard.md`, `reversibility-protocol.md`, `principal-standard-checklist.md`, and the schemas in `per-skill-output-contracts.md` + `dependency-graph.md`.
- **Downstream:** All newly-created or refined PMO skills. Any skill added to `release/skills/` flows through this refiner.
- **Coordinates with:** `pmo-skill-editor` (refine-existing handoff for structural edits), `pmo-qa-auditor` (G4 reversibility gate and G7 failure-mode gate validate refiner output post-deploy).
- **RAID prefix:** `R-PSR-###` (refiner rarely produces RAID, but cross-skill risk discovered during refinement uses this prefix).
