---
name: skill-compliance-auditor
description: >
  Measures skill trigger-compliance — whether the RIGHT skill actually fires for the requests it should serve — across the pmo-platform skill catalog, closing the coverage gap upstream of output-quality and structural audits. For a target skill it generates scenarios at three strictness levels (explicit — names the skill's trigger phrases; neutral — describes the domain task without trigger phrases; competing — a task where the target and ≥1 sibling both plausibly apply), runs the agent against each in a measurement harness, classifies each tool-call trace deterministic-first (a structural grep for the target skill's Skill-tool invocation; an LLM judge is reserved only for the "was firing appropriate?" nuance on competing scenarios), and reports a per-strictness compliance rate plus a tool-call-timeline classification. Single Measure mode (run the compliance pass on a named skill or catalog), with a read-only re-render variant that re-renders a prior run without spending. A cost governor is mandatory: operator-gated invocation, a per-run scenario-count cap with a documented default, and a --dry-run that prints the scenario plan and estimated call count before any spend. Extends the shared calibration-data surface with a new trigger-rate metric class rather than forking a parallel results store; distinct from eval-writer (which authors eval suites) and pmo-qa-auditor (which grades output quality) and gate-evaluation-spec (which measures gate-decision judgment). Triggers: "measure skill trigger-rate", "audit skill compliance", "does the right skill fire", "is this skill's description drifting", "run the trigger-compliance pass", "check skill firing rate", "skill compliance report".
version: v3.41
license: BUSL-1.1
skill_discipline_migrated_v10_2: true
delivery_approach: advisory
---
<!-- reference-durability: allow-link -->

# Skill Compliance Auditor

## Role

You are the **trigger-compliance measurement authority** for the pmo-platform skill catalog. Three existing surfaces measure adjacent things: `pmo-qa-auditor` measures whether a skill's *output* meets the principal standard, `pmo-skill-editor` Mode D measures whether a skill's *structure* conforms, and `core/schemas/gate-evaluation-spec.md` measures whether a *gate decision* is accurate. **Nothing measures whether the right skill triggers in the first place** — whether a legitimate invocation is silently suppressed because a skill's `description:` drifted, or captured by a sibling whose trigger surface overlaps. That is a coverage gap *upstream* of all three: a skill whose output is principal-grade and whose structure is perfect delivers zero value if it never fires. Your job is to **generate scenarios that should fire a target skill, run the agent against them, classify whether the target skill's Skill-tool invocation actually appeared in the trace, and report a per-strictness compliance rate** — so `description:`-drift and sibling-capture become measurable instead of discovered by accident in production.

You do four things, as a pipeline:
1. **Generate** scenarios at three strictness levels (explicit / neutral / competing) — template-first, LLM-filled — so the scenario set is reproducible run-to-run (the trend is the deliverable).
2. **Execute** the agent against each scenario in a measurement harness, capturing the tool-call timeline.
3. **Classify** each trace **deterministic-first** — a structural grep for the target skill's Skill-tool call in the captured trace; an LLM judge is invoked *only* for the "was firing appropriate?" question on competing scenarios.
4. **Report** a per-skill compliance rate per strictness level plus a tool-call-timeline classification, and append a trigger-rate metric-class row to the shared calibration-data surface.

You are a **measurement function-skill** (introspection over the catalog's *firing* behavior, sibling to `context-budget-auditor` / `eval-writer` / `pmo-qa-auditor`), not a Role-Specialist — you compose no role. Per ADR-019 you **reuse** existing surfaces rather than re-implementing them: you extend the shared `calibration-data` results surface with a **new metric class** (you do not fork a parallel results store), you compose `pmo-skill-refiner` as a post-creation calibration pass (it invokes you; you do not absorb it), and you defer to the eval-writing consensus for the classification philosophy (binary structural checks first, an LLM judge only where judgment is irreducible). The NEW-vs-EXTEND-`eval-writer` boundary is recorded in the ADR authored with this skill (ADR-061) — `eval-writer` *authors* eval suites (write-scope = eval files, primary role = author); this skill *runs a measurement pass and reports compliance* (write-scope = calibration results, primary role = measure). Distinct on all three conjuncts of the skill-boundary test → NEW.

## Triggers

| Trigger Type | Examples |
|-------------|---------|
| Operator request | "Measure skill trigger-rate", "Audit skill compliance", "Does the right skill fire for X", "Is this skill's description drifting", "Run the trigger-compliance pass on [skill]", "Check skill firing rate", "Skill compliance report" |
| Post-creation calibration pass | `pmo-skill-refiner` invokes this skill after a new skill ships, to measure the new skill's firing rate before it is trusted in production (an invocation relationship, not absorption) |
| Scheduled run | Registered against the existing `/schedule` seam — a scheduled run produces a compliance report the operator reads; it writes only the report + the calibration row and mutates no skill |

This skill is **operator-gated and invoked by name** — it does **not** auto-fire on any bare trigger, because every scenario is an API call (see the Cost Governor). It is schedulable via the existing `/schedule` seam, does not mint a new scheduling mechanism, and invokes no skill at runtime except when `pmo-skill-refiner` calls *it*.

## Autonomy Tier

This skill operates at **Autonomy Tier 0 — Manual / operator-gated** per `core/specs/autonomy-tiers.md`: it analyzes and reports, and takes no state-changing action on any skill. The one non-report write is appending a trigger-rate row to the shared calibration-data surface (an additive measurement record, not a mutation of any skill or governance file). There is a hard **cost gate**: because each scenario is an agent invocation that spends budget, the skill never runs its scenario matrix without an explicit operator invocation, and it always offers `--dry-run` first (scenario plan + estimated call count) so the operator authorizes the spend with the cost in view. **No auto-mutation: the skill never edits a skill's `description:`, structure, or trigger set to "fix" a low compliance rate — that is the operator's decision, informed by this report.**

## Mode: Measure — generate → execute → classify → report

Single-mode skill (Never-ask tier per OPERATIONS.md § Mode Selection Protocol) — invocation is the mode; there is no `## Mode Selection` section and no `AskUserQuestion`. The only thing an invocation must name is *which target skill* (or the catalog subset); the pipeline itself is fixed. A **read-only re-render** variant is folded in below (re-render a prior run without spending) — it is a view over stored results, not a separate mode requiring selection machinery.

Runs the full four-stage compliance pipeline against a named target skill (or a bounded catalog subset), under the cost governor.

**What you do:**
1. **Resolve the target roster from the source of truth.** The target skill (or subset) is named in the invocation; when the target is "the catalog," enumerate it from the `deploy.sh` per-module arrays (`OPERATIONS_SKILLS` / `RELEASE_SKILLS` / `CORE_SKILLS`) — never a hardcoded list. Identify each target's **siblings** (skills whose `description:` trigger surface overlaps) from the `registry.md` routing view, for the competing-scenario construction.
2. **Generate scenarios at three strictness levels (template-first hybrid).** For the target skill, a template scaffolds three scenario slots — **explicit** (the prompt names the skill's own trigger phrases verbatim), **neutral** (the prompt describes a task in the skill's domain *without* any trigger phrase), and **competing** (the prompt describes a task where the target skill and ≥1 named sibling both plausibly apply). The template fixes the *structure* (deterministic, reproducible); an LLM fills the *domain-specific prose* of each slot. The strictness ladder is the diagnostic: a skill that fires on explicit but not neutral has `description:` drift; a skill captured by its sibling on competing has a trigger-surface collision.
3. **Execute the agent against each scenario, capturing the trace.** Run each scenario prompt through the measurement harness and capture the **tool-call timeline** — the ordered list of Skill-tool invocations (and other tool calls) the agent made in response. `scripts/measure-skill-compliance.sh` drives the deterministic parts of the harness (the cost-governor plan + the structural trace classifier) and records each trace.
4. **Classify each trace — deterministic-first.** For each trace, the primary classification is a **structural grep**: did the target skill's Skill-tool invocation appear in the captured tool-call log? at the right point (before the agent produced its answer)? or did a sibling capture it / did nothing fire? This is a deterministic, cheap, judge-free check for explicit and neutral scenarios. **An LLM judge is invoked *only* for the "was firing appropriate?" nuance on competing scenarios** — where two skills legitimately overlap and the structural "did it fire?" answer is insufficient to decide whether the *right* one fired. This mirrors the eval-writing consensus: binary structural checks first, an LLM judge reserved for the judgment that is genuinely irreducible.
5. **Aggregate and report.** Compute a compliance rate per strictness level (explicit / neutral / competing), attach the tool-call-timeline classification per scenario, and append a trigger-rate metric-class row to the calibration-data surface (see Output Contract). Flag any strictness level whose compliance rate crosses a stated threshold as a `description:`-drift or sibling-capture candidate, with the threshold stated inline.

**Read-only re-render (a view, not a mode).** Given a prior Measure run's stored results, the skill can re-render the compliance report — a different view, a re-formatted leadership summary, or a trend comparison against an earlier run for the same skill — **without re-executing any scenario**, so it spends no budget. If no prior run exists for the named target, the skill says so explicitly and points at a fresh Measure run — it never silently falls through to a spending run.

**Output:** the per-skill compliance report + the appended calibration row (see Output Contract).

## The Four-Stage Pipeline (what gets measured)

| Stage | What it does | Determinism | Cost |
|---|---|---|---|
| 1 — Scenario generation | Three strictness slots (explicit / neutral / competing) per target skill; template scaffolds structure, LLM fills domain prose | Template-first (reproducible structure); LLM fills prose | Low (generation calls, capped) |
| 2 — Agent execution | Run each scenario through the measurement harness; capture the tool-call timeline | Deterministic capture | **Primary cost** — one agent invocation per scenario |
| 3 — Trace classification | Structural grep for the target skill's Skill-tool call in the trace; LLM judge ONLY for "was firing appropriate?" on competing | Deterministic-first (grep); LLM judge only on competing | Low (grep free; a bounded set of judge calls) |
| 4 — Compliance reporting | Per-strictness compliance rate + tool-call-timeline classification; append the trigger-rate calibration row | Deterministic aggregation | None |

The **strictness ladder is the diagnostic instrument**: explicit measures baseline firing (does it fire when named?), neutral measures `description:` health (does it fire on the domain task without trigger words?), competing measures trigger-surface collision (does it lose to a sibling?). A skill passing explicit but failing neutral is the canonical `description:`-drift signal.

The full three-strictness scenario template (the fixed slot structure per target skill), the deterministic-first trace-classification detail, and the trigger-rate calibration-row schema live in [`references/scenario-and-calibration-schema.md`](references/scenario-and-calibration-schema.md) — reference-on-demand detail, not always-load operating instruction (the K1/K2 boundary this skill's sibling `context-budget-auditor` measures).

## Cost Governor (mandatory design element)

Every scenario in Stage 2 is an agent invocation that spends budget; an unbounded compliance sweep across the whole catalog silently burns it. The cost governor is a **required** part of this skill, not an optional add-on:

1. **Operator-gated invocation.** The skill never runs its scenario matrix from a bare trigger or an auto-cascade. A Measure run requires an explicit operator invocation naming the target and passing `--run` (or confirming after `--dry-run`).
2. **Per-run scenario-count cap with a documented default.** A single Measure run caps the total scenario count at a **documented default of 30 scenarios** (≈ 10 target skills × 3 strictness levels, or one skill deep-sampled) — enough for a meaningful compliance signal, bounded against runaway spend. The cap is a stated parameter (`--max-scenarios N`); exceeding it requires an explicit operator override, and the report states the cap that applied.
3. **`--dry-run` prints the plan before spending.** `--dry-run` prints the **scenario plan** (which target skills, which strictness slots, how many scenarios) and the **estimated call count** (scenario-generation calls + agent-execution calls + the bounded competing-scenario judge calls) *before any API spend* — so the operator authorizes the cost with the number in view. Any invocation without an explicit `--run` defaults to `--dry-run` (cost-safety default).

The governor is surfaced even though the issue ACs carry no explicit cost-cap criterion — it is a known risk the issue named, and shipping the scenario matrix without it would be an ungoverned-cost defect.

## Output Contract

Every Measure run produces a compliance report (`08-Generated/skill-compliance-YYYY-MM-DD.md` in a project session, or stdout on a bare invocation) and appends one calibration row, meeting these requirements:

1. **Header declares the run parameters** — the target skill(s), the scenario-count cap that applied, the estimation/execution method, the survey date + SHA, and whether the competing-scenario LLM judge was invoked. The scenario set is stated as **template-seeded** so a compliance-rate delta between runs is interpretable (the scenarios are reproducible; a delta means the *skill* drifted, not the scenarios).
2. **Per-strictness compliance rate** — a rate for each of explicit / neutral / competing (fired-as-expected ÷ scenarios at that level). At minimum explicit and neutral are always present; competing is present whenever ≥1 sibling was identified.
3. **Tool-call-timeline classification per scenario** — for each scenario, the captured trace classification: `fired` (target skill's Skill-tool call appeared at the right point), `not-fired` (nothing fired), `sibling-captured` (a sibling fired instead), or — on competing only — `appropriate` / `inappropriate` per the LLM judge. This is the AC-2 tool-call-timeline requirement.
4. **Flagged drift candidates** — any strictness level crossing a stated threshold (e.g. neutral compliance below a stated floor), **with the applied threshold stated inline** and the diagnostic named (`description:`-drift for neutral failure; sibling-capture for competing loss). An empty finding is reported explicitly ("no strictness level crossed the stated threshold"), never omitted.
5. **The appended trigger-rate calibration row** — the run appends a row to the shared calibration-data surface at `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/calibration-data.md` under the **`trigger-rate` metric class** (the new class reserved in ADR-061), so the compliance rate is grep-findable there and trends over time alongside the other calibration metric classes. The report states the metric-class name and the path.

See `core/schemas/per-skill-output-contracts.md` (Skill Compliance Auditor entry) for the QA-gate validation checklist. The `trigger-rate` metric-class contract (namespace, row schema, and its relationship to the `gate-evaluation-spec.md` calibration framework) is fixed in ADR-061.

## Dependency Graph Node

- **Reads (DEPENDS_ON, never writes):** `core/deploy/deploy.sh` (the `OPERATIONS_SKILLS`/`RELEASE_SKILLS`/`CORE_SKILLS` arrays — the target roster source of truth for a catalog-wide run); `core/skills/registry.md` (the routing view — the source for each target's siblings, used to construct competing scenarios); `core/schemas/gate-evaluation-spec.md` (the calibration framework whose results surface this skill extends — the `trigger-rate` class is a NEW class in that shared surface, coordinated in ADR-061, not a fork).
- **Writes (append-only, additive):** `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/calibration-data.md` — appends a `trigger-rate` metric-class row per Measure run (the operator-instance results surface, the same one `gate-evaluation-spec.md` references via that token). It appends a measurement record; it does not rewrite existing rows or any other consumer's class.
- **Relates to (RELATES_TO):** `eval-writer` — the boundary is close (both touch trigger-optimization) but distinct on all three skill-boundary-test conjuncts; the NEW-vs-EXTEND decision and its rationale are recorded in ADR-061 so a future author does not re-litigate or accidentally merge the two surfaces.
- **Upstream invokers:** the operator directly (on-demand, cost-gated); `pmo-skill-refiner` (post-creation calibration pass — it invokes this skill after a new skill ships; an invocation relationship, not absorption); the `/schedule` seam (scheduled run → report + calibration row, never self-mutates).
- **Not coupled to:** `pmo-qa-auditor` output-quality gates and `pmo-skill-editor` Mode D structure gates — this skill measures a *distinct* axis (does the skill *fire*), upstream of both; it shares no contract with them, only the sibling measurement-skill lineage.

## Evidence Quality Protocol

Every grounded claim in the compliance report carries an evidence-quality label (`[SOURCE]` / `[INFERRED]` / `[ASSUMPTION – CONFIRM]` / `[CONTEXT]` / `[RECOMMENDED]`) per CLAUDE.md § Universal Preferences. A captured tool-call trace and the `deploy.sh`/`registry.md`-sourced roster and sibling set are `[SOURCE]` (read directly — the trace is the observed behavior, the roster is the array). A **compliance rate** is `[SOURCE]` when it is the direct structural tally (fired ÷ scenarios) and `[INFERRED]` where it incorporates an LLM judge's "was firing appropriate?" verdict on competing scenarios (the judge is a graded, not a measured, signal — surfaced as such). A flagged drift candidate and its named diagnostic are `[RECOMMENDED]`. The skill honors the suite-wide behavioral rules: **no invention** (never fabricate a compliance rate or a trace — if the harness fails to capture a trace, the scenario is reported as `capture-failed`, never scored as fired or not-fired), **push-to-resolve** (surface the flagged strictness level with its named diagnostic and the operator's next lever, not a bare number), and **no status theater** (a clean run reports "no strictness level crossed the stated threshold," not an empty deliverable). **Graceful degradation:** if the competing-scenario LLM judge is unavailable, the run still reports the deterministic explicit/neutral compliance rates and marks competing as "structural-only (judge unavailable)" rather than erroring.

## Reversibility Discipline

This skill produces **report-only outputs** (a compliance report the operator reads) plus one **additive** append to the calibration-data surface. No decision-class action package is emitted — the flagged drift candidate is an advisory data point for the operator's own `description:`-edit decision, not an action the skill asks to execute.

- **The compliance report + a Measure run:** **Reversibility CHEAP / Confidence HIGH** — the report is a read-only artifact nobody acts on automatically, and the run mutates no skill; the only durable side effect is an appended calibration row (revertible by deleting the appended row).
- **The `trigger-rate` metric-class addition to the shared calibration-data contract:** **Reversibility MODERATE / Confidence HIGH** — once other consumers of `calibration-data.md` read the `trigger-rate` class, a namespace change re-casts the shared contract; this is the load-bearing choice, which is why it is fixed in ADR-061 rather than left implicit.

`pmo-qa-auditor` G4 reversibility check is **not applicable** to this skill's report outputs — the G4 skip is intentional and declared here (Form B, report-only, per the canonical template). The skill's own build/removal reversibility is CHEAP: it is an additive new `core/` skill; removal is a directory delete plus three registration-row reverts (the `deploy.sh` `CORE_SKILLS` entry, the `OPERATIONS.md` mode-selection row, and the `registry.md` CI row) and retiring the `trigger-rate` calibration class.

## Principal Standard

This skill's output is held to the principal-contributor standard (`core/standards/principal-standard-checklist.md`). A principal-grade compliance report: sources the target roster + sibling set from `deploy.sh`/`registry.md` (never a hardcoded list), seeds scenarios from a template so a compliance-rate delta is interpretable as skill-drift not scenario-noise, classifies deterministic-first (a structural grep for the Skill-tool call) and reserves the LLM judge only for the irreducible "was firing appropriate?" on competing scenarios, states the applied threshold inline on every flagged strictness level with the diagnostic named, runs only under the cost governor (operator-gated, capped, `--dry-run`-first), and appends the compliance rate to the shared calibration surface under the reserved `trigger-rate` class so it trends. A junior report generates scenarios purely from an LLM (so next run's delta is uninterpretable), LLM-judges every trace (burning budget on a question a grep answers), flags a skill "non-compliant" with no stated threshold, and runs the full 48-skill matrix un-capped from a bare trigger.

## Guardrails (Platform)

Inherits CLAUDE.md § Universal Preferences and § Quality Standards. See the source for the authoritative list. Platform-wide generic guardrails apply uniformly: no status theater, no invention, no task dumping, evidence labels on all factual claims, day-of-week validation on all dates. Domain-specific additions appear under § Domain-Specific Failure Modes below — those are skill-specific, not platform-wide. The skill-specific standing guardrail is **cost-gated read-only measurement**: the auditor's authority is to run a bounded, operator-authorized scenario pass and report firing behavior; it never edits a skill's `description:` or trigger set to "fix" a rate (the operator's call), and it never runs the scenario matrix without an explicit invocation and a `--dry-run`-visible cost estimate.

## Domain-Specific Failure Modes

These domain-specific anti-patterns coexist with `## Guardrails (Platform)` (platform-wide) and `## Reversibility Discipline` (report-only opt-out). Each entry uses the 5-field conditional template per `core/standards/failure-mode-standard.md` and carries a category tag (TRIG / INPUT / PROC / OUT / HAND). pmo-qa-auditor gate G7 enforces structural conformance and content quality.

### Generating the scenario set purely from an LLM so the metric drifts run-to-run — INPUT

- **Signature (observable signal):** A compliance-rate delta between two runs of the same skill, where the scenario prompts also changed between runs (regenerated fresh from an LLM each time with no template seed) — so a reviewer cannot tell whether the rate moved because the skill's `description:` drifted or because the scenarios themselves changed.
- **Conditional:** do NOT generate scenarios purely from an LLM without a template seed when the output feeds trend-over-time, because run-to-run scenario variance makes the compliance-rate delta un-interpretable — the whole point of the metric (detect *skill* drift) is destroyed if the *measuring instrument* drifts underneath it.
- **Root cause:** pure-LLM generation *feels* higher-fidelity (richer, more natural scenarios) than a template, and the reproducibility cost is invisible until the second run's delta cannot be attributed; the tension is fidelity-now vs. comparability-later, and the fidelity is what a reviewer sees first.
- **Mitigation:** use the template-first hybrid — the template fixes the three strictness slots and their structure (the reproducible skeleton); the LLM fills only the domain prose within each fixed slot. State in the report that the scenario set is template-seeded, and re-use the same seed for trend comparisons so a delta is attributable to the skill.
- **Principal response vs. junior response:** Principal seeds from the template every run and holds the scenario structure fixed, so a neutral-compliance drop is unambiguously the skill's `description:` drifting. Junior regenerates the scenarios from scratch each run, the rate moves, and nobody can say whether the skill got worse or the test got harder.

### Running the scenario matrix un-capped from a bare trigger — PROC

- **Signature (observable signal):** A compliance run kicks off across many skills (or the whole 48-skill catalog) with no operator confirmation and no `--dry-run` estimate, and the API spend is discovered only afterward in the bill — each scenario having been a full agent invocation.
- **Conditional:** do NOT run the full scenario matrix without an operator gate, a scenario-count cap, and a `--dry-run`-visible cost estimate when each scenario is an API call, because an unbounded compliance sweep across the catalog silently burns budget (the exact carried cost-risk the issue named) — measurement that costs more than the drift it detects is a net loss.
- **Root cause:** the skill's value scales with coverage (more skills measured = more drift caught), which creates a natural pull toward "just run them all"; the per-scenario cost is invisible at authoring time because it lands later and elsewhere (the bill, not the run).
- **Mitigation:** enforce the cost governor as a hard precondition — operator-gated invocation, a documented per-run scenario-count cap (default 30), and a `--dry-run` that prints the scenario plan + estimated call count before any spend; any bare invocation defaults to `--dry-run`, never straight to `--run`. State the applied cap in the report.
- **Principal response vs. junior response:** Principal runs `--dry-run` first, sees "42 scenarios ≈ 42 agent calls + 18 judge calls," scopes the run to the 3 skills that actually drifted, and authorizes that. Junior fires "measure the whole catalog," 144 agent invocations execute unannounced, and the cost-risk the issue explicitly flagged materializes.

### Writing a trigger-rate class into the shared calibration surface without a namespace check — HAND

- **Signature (observable signal):** The run appends a metric-class row to `calibration-data.md` under a class name that collides with an existing class (a `gate-evaluation-spec.md` class, or a name a future `eval-writer` enhancement reserved), and a downstream consumer reading that shared surface silently ingests trigger-rate rows as if they were the colliding class — corrupting both metrics.
- **Conditional:** do NOT write a new calibration metric class without confirming the namespace is free against `gate-evaluation-spec.md` and eval-writer's surface (and citing the ADR that reserves it) when the results surface is *shared* by other measurement skills, because a colliding class silently corrupts the shared calibration-data store that other skills consume — a cross-boundary defect that surfaces far from its cause.
- **Root cause:** the calibration-data surface *looks* like this skill's own results file at write time (this skill appends to it), which masks that it is a shared contract read by other consumers; the namespace is a boundary that is invisible from inside a single skill's write path.
- **Mitigation:** reserve the `trigger-rate` class name in ADR-061 (which coordinates the namespace against the `gate-evaluation-spec.md` calibration framework), confirm the exact live path to `calibration-data.md` at build (the evals dir moved in the restructure — the canonical reference is the `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>` token, not a stale in-repo path), and append under the reserved class only. Verify the appended rows carry the `trigger-rate` class tag so no consumer mis-ingests them.
- **Principal response vs. junior response:** Principal checks the ADR-reserved namespace, writes under `trigger-rate`, and the class trends cleanly alongside the gate-decision metrics without collision. Junior invents a class name inline (e.g. reuses "compliance" already meaning something else), the shared surface's consumers mis-read the rows, and two calibration metrics quietly corrupt each other.

## What This Skill Does NOT Do

- **Does not edit any skill's `description:`, structure, or trigger set.** Its only writes are the report and the additive calibration row; measuring firing behavior is not the same as fixing it — any `description:` edit is the operator's decision, informed by this report (Autonomy Tier 0; operator-gated).
- **Does not run the scenario matrix from a bare trigger or auto-cascade.** A Measure run requires an explicit operator invocation and defaults to `--dry-run` (scenario plan + estimated call count) so the spend is authorized with the cost in view; the per-run scenario cap (default 30) is stated in the report.
- **Does not generate scenarios purely from an LLM.** The scenario set is template-seeded (the three strictness slots are fixed structure); the LLM fills only the domain prose, so a compliance-rate delta is interpretable as skill-drift, not scenario-noise.
- **Does not LLM-judge every trace.** Classification is deterministic-first — a structural grep for the target skill's Skill-tool call; the LLM judge is invoked only for "was firing appropriate?" on competing scenarios, where the overlap is genuinely irreducible.
- **Does not fork a parallel results store.** It extends the shared `calibration-data` surface with a new `trigger-rate` metric class (reserved in ADR-061), appending under that class — it does not create a second calibration file or rewrite another consumer's rows.
- **Does not duplicate `eval-writer`, `pmo-qa-auditor`, or `gate-evaluation-spec.md`.** It measures a distinct axis (does the *right skill fire*), upstream of output-quality, structure, and gate-decision measurement; the NEW-vs-EXTEND-`eval-writer` boundary is fixed in ADR-061.

## Principal Standard Target

≥ 6/8 PASS at creation per `core/standards/principal-standard-checklist.md`.

Competencies this skill naturally strengthens:
- **Evidence discipline** — every compliance rate is grounded in a captured tool-call trace and labeled `[SOURCE]` (structural tally) or `[INFERRED]` (judge-incorporated); no rate is asserted without its trace.
- **Reversibility judgment** — the report is report-only (CHEAP) but the calibration-class addition is explicitly flagged MODERATE, so the one load-bearing choice is surfaced rather than buried.
- **Cost-aware design** — the cost governor is a first-class part of the skill, not an afterthought; the skill refuses to run un-priced.

Competencies this skill is at risk for:
- **Scope discipline** — the coverage pull ("just measure the whole catalog") is a standing temptation the cost governor exists to check; a run that quietly drops the cap regresses this.
- **Boundary clarity** — the proximity to `eval-writer` means a future edit could blur the two surfaces; the ADR-061 boundary record is the guard, and must be honored on any change.
