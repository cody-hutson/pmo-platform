---
title: Actor Model & Governance-as-Contract — the target operating model
purpose: "Forward-looking / target-architecture statement — the single authoritative home for the three-actor target operating model (orchestrator / specialist skill / free AI agent) bound by governance-as-contract. Consumes the seed docs by reference; does not restate them. Not a current-state description."
type: discipline
status: ACTIVE (target-state model — forward-looking; the model itself is not yet ratified, D1–D5 open)
reversibility: CHEAP / Confidence HIGH
---
<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
# Actor Model & Governance-as-Contract — the target operating model

This document is the single authoritative statement of the platform's **target operating model**: the shift from today's hub-spoke orchestration toward a skills-and-agents process where **(1)** an *orchestrator* conducts, **(2)** *specialist skills* perform bounded capabilities, and **(3)** *free AI agents* own the irreducible judgment — all bound by **governance-as-contract**. It exists because that intent is real and partially seeded across the corpus but had **no single home**: no one document stated the three-actor model, the permanent determinism-vs-judgment division of labor, or the enforcement-model shift the target implies.

**What this is NOT.** It is **not** a current-state description, and it is **not** a restatement of the docs it draws on. It is forward-looking. Every normative claim about the *target* is self-marked **[TARGET-STATE — not yet ratified]** so the framing travels with the sentence, not just the section header. And it **consumes, does not redefine**: each governing surface it names keeps its own single source of truth (see § Consumed Surfaces), so this doc mints no parallel vocabulary.

## Status & Scope — a target-state model

This is an **evolving-vision** document (a Now/Next/Later target statement), not a ratified decision of record.

- **The doc is `ACTIVE`** in the sense that it is the live, published home for the target model — the place a reader goes to trace the target architecture and the migration path.
- **The model it describes is target-state and unratified.** The adopt-as-target framing is carried here as reversible prose. The sub-decisions that would harden it — labelled **D1–D5** below — are **open for ratification, not settled**, and are intended to decompose into their own small ADRs as each specific decision becomes ready (no big-bang keystone ADR is minted by this doc).
- **No keystone ADR.** At scope-lock the platform deliberately declined to author a thin keystone ADR for the whole model: nothing is ratified yet to anchor one, and an `Accepted` record would read downstream as a settled decision the open D1–D5 are not. When a *specific* decision (e.g. "orchestrator is an actor" or "the trigger-dispatch contract") is ratified, that one small ADR is authored then.

**The five open sub-decisions (D1–D5), named so the reader knows what is unsettled:**

| ID | Open decision |
|---|---|
| **D1** | The actor ownership split itself — orchestrator owns control · specialist skill owns capability · free agent owns judgment (⇒ skills are performers, not drivers). |
| **D2** | This doc's own posture — target-state prose today; whether/when it hardens to a ratified model. |
| **D3** | Which specific orchestration behaviours are routine dispatch (skill-eligible) vs. judgment-laden conducting (stays an agent) — see § The Open Boundary. |
| **D4** | The concrete contract form the enforcement shift lands on (a machine-checkable policy object) — see § The Enforcement-Model Shift. |
| **D5** | The migration sequencing from hub-spoke — see § Migration Path. |

## The Three-Actor Target Model

The target operating model has **three actor classes**. Each is defined by *what it performs*; the normative detail of each surface lives in the seed docs this table links (consume-not-restate — the one-line facet below is self-describing, the linked home carries the full definition).

| Actor | What it performs (one-line facet) | Marker |
|---|---|---|
| **Orchestrator** | *Conducts.* Owns Control — sequencing, dispatch, gate evaluation, and cross-stage reconciliation. It routes work and evaluates gates; it does not perform a stage's isolated capability itself. | [TARGET-STATE — not yet ratified: D1] |
| **Specialist skill** | *Performs.* Owns one bounded Capability — a packaged, single-source unit invoked to produce a defined output. It composes other skills by invocation; it does not absorb their function or the irreducible judgment it does not own. | [TARGET-STATE — not yet ratified: D1] |
| **Free AI agent** | *Judges.* Owns the irreducible Judgment — the interpretation, quality, and accountability that cannot be reduced to a deterministic procedure. This is the actor the human orchestrator delegates decision-shaped work to. | [TARGET-STATE — not yet ratified: D1] |

The fourth concern — **Constraint** — is **not** a fourth actor. It is expressed as the **governance contract** that binds all three (see § The Enforcement-Model Shift). Capability → specialist skill, Control → orchestrator, Judgment → free agent, Constraint → the contract: that is the whole shape.

### Disambiguation — "orchestrator" here vs. elsewhere

The word **orchestrator** is already overloaded in the corpus. The target-state *orchestrator actor* named above is a **new, fourth sense** — do not conflate it with the three existing ones:

| Existing sense | What it means today | Not the same as the target actor because… |
|---|---|---|
| **Human orchestrator** | The Portfolio/Program/Project human who directs the work and renders irreducible decisions (per [`architecture-overview.md`](architecture-overview.md) § Who This Serves). | The target orchestrator actor is an *agent/skill* surface that conducts execution; the human stays the accountable decision-maker above it. |
| **Hub session** | The single orchestrating Claude session that drives a release by spawning Spokes (per [`../specs/terminology-glossary.md`](../specs/terminology-glossary.md) `term: Hub`). | The Hub is *today's* concrete implementation of conducting; the target orchestrator is the *role* the Hub's function migrates into — they are not equated (a partial-read must not treat the live Hub as the ratified actor). |
| **Organizer-Orchestrator function-skill** | The function-named shared machinery in [`../ADRs/ADR-019-specialists-compose-not-absorb.md`](../ADRs/ADR-019-specialists-compose-not-absorb.md) (§ Decision — "Organizers and Orchestrators are function-named shared machinery"). | That is a *class of shared skill* Specialists compose; the target orchestrator actor is the conducting role, which may itself be realized as such machinery or as an agent — precisely the open boundary below. |

This doc **disambiguates inline** rather than minting a fifth canonical term; the glossary carries a one-line cross-reference to here (Appendix A, the "agent" workforce-identity row), not a new `### term:` registration.

## Each Actor's Governing Surface

Each actor is bound by **≥1 governing surface**, each with a `core/`-or-repo path citation. The target model does not invent new governance; it maps existing surfaces onto the actor they constrain.

| Actor | Governing surface(s) | Citation |
|---|---|---|
| **Orchestrator** | Pipeline stage specs + gate protocols + engagement charter + operating procedure — the sequencing, gate-evaluation, and engagement rules that conducting must obey. | [`../schemas/gate-evaluation-spec.md`](../schemas/gate-evaluation-spec.md), [`../schemas/gate-criteria-spec.md`](../schemas/gate-criteria-spec.md), [`../specs/engagement-charter.md`](../specs/engagement-charter.md), [`../../release/governance/release-process.md`](../../release/governance/release-process.md), `release/references/pipeline/stage-NN.md` |
| **Specialist skill** | Skill-pipeline alignment + Skill-Chaining Protocol + canonical skill structure + the compose-not-absorb decomposition rule — what a bounded skill may own and how it composes others. | [`../standards/skill-pipeline-alignment.md`](../standards/skill-pipeline-alignment.md), [`../governance/OPERATIONS.md`](../governance/OPERATIONS.md) § Skill Chaining Protocol, [`../standards/canonical-skill-structure.md`](../standards/canonical-skill-structure.md), [`../ADRs/ADR-019-specialists-compose-not-absorb.md`](../ADRs/ADR-019-specialists-compose-not-absorb.md) |
| **Free AI agent** | WHO-acts authorization (autonomy tiers) + subagent security posture + the AS4 autonomous-guard rung — the authorization and containment rules governing autonomous action. | [`../specs/autonomy-tiers.md`](../specs/autonomy-tiers.md), [`../standards/subagent-security-posture.md`](../standards/subagent-security-posture.md), [`../standards/agent-script-promotion-framework.md`](../standards/agent-script-promotion-framework.md) (AS4) |

## The Permanent Division of Labor — Determinism vs Judgment

The target model's load-bearing invariant is a **permanent** division of labor, not a transitional one:

- **Scripts and skills own determinism.** Mechanical, reproducible work — field presence, format match, state comparison, computed aggregates — is promoted onto deterministic executables so agent tokens concentrate on judgment. This is the autonomy north star the promotion framework encodes ([`../standards/agent-script-promotion-framework.md`](../standards/agent-script-promotion-framework.md)).
- **Free agents own judgment.** Interpretation, quality, actionability — the work that cannot be reduced to a procedure — stays with the agent.

The end-state is therefore explicitly **NOT** "everything becomes a skill" and **NOT** "everything becomes a script." The division is structural: it is set by *what class a step is*, not by how mature the platform is.

### The durable principle — judgment stays with free agents, permanently

> **Judgment stays with free agents — permanently.** [TARGET-STATE — not yet ratified: D1]

This is stated as a **structural invariant with a falsification condition**, not a point-in-time claim. It is **dual-grounded** — because judgment could leave the free-agent actor by *two* distinct paths, and each path is closed by a different rule:

1. **The script-promotion axis — the mixed-determinism rule.** A step whose Check class is *judgment* (per the `structural` / `metrics` / `judgment` enum in [`../schemas/gate-criteria-spec.md`](../schemas/gate-criteria-spec.md)) **never promotes end-to-end to a script**: only its evidence-gathering substrate promotes — *script gathers, agent judges* — per the **mixed-determinism rule** in [`../standards/agent-script-promotion-framework.md`](../standards/agent-script-promotion-framework.md). Scripting a judgment step end-to-end is the named **judgment-laundering** failure mode (same doc). This closes the *judgment → script* path.
2. **The actor-allocation axis — ADR-019 "specialists compose, not absorb."** A specialist skill is a *thin, bounded* capability that **composes** shared function-skills by invocation; it must **not absorb** function — or judgment — it does not own. Whether a capability may become its own bounded specialist is governed by the **skill-boundary test** (distinct trigger surface AND write-scope AND primary role), and a skill that re-implements/absorbs judgment it does not own **fails review**, per [`../ADRs/ADR-019-specialists-compose-not-absorb.md`](../ADRs/ADR-019-specialists-compose-not-absorb.md). This closes the *judgment → specialist-skill absorption* path — a path the mixed-determinism rule alone leaves open (both actors are in-context LLMs, neither a script, so the script-axis rule is silent on it).

**Falsification condition (the only revision triggers), one per axis:**

- Reclassifying a step **out of** the judgment class (to `structural`/`metrics`) and then fully promoting it does **not** violate the principle — it re-classifies the *step*; the invariant (*judgment-class work stays with agents*) still holds. The principle requires revision on the script axis **only if the mixed-determinism rule itself is overturned.**
- On the actor axis, the principle is falsified **only if ADR-019's compose-not-absorb rule is overturned** — i.e. if bounded specialist skills are permitted to absorb irreducible judgment.

So "permanent" is warranted precisely because it is derived from *what a judgment-class step is* and *what a specialist skill may own* — not from where the platform is today.

## The Enforcement-Model Shift — Governance-as-Procedure → Governance-as-Contract

The target model implies a shift in **how governance enforces**: [TARGET-STATE — not yet ratified: D4]

- **From governance-as-procedure** — human-readable playbooks that an agent reads and follows step-by-step. Today the `release/references/pipeline/stage-NN.md` shards are the **procedure form**: prose stage protocols an agent executes.
- **To governance-as-contract** — machine-checkable criteria a gate evaluates, independent of any one procedure's prose. The **contract form** is [`../schemas/gate-criteria-spec.md`](../schemas/gate-criteria-spec.md): structured gate criteria (`ID` / `Criterion` / `Type` / `Check` / `Automation` / `Validation method`) that a stage-gate evaluator routes on — `structural` → auto-validate, `metrics` → compute, `judgment` → agent-assess.

In the target state the **contract form becomes load-bearing** and the **procedure form demotes to advisory playbook**: the `stage-NN.md` shards remain useful narrative, but the gate *decision* is made against the contract, not by reading the prose. The concrete form the contract ultimately takes — for example a machine-checkable policy object rather than today's tables — is one of the open sub-decisions (**D4**) and is not settled here.

This is the fourth concern (**Constraint**) made concrete: the contract is what binds the three actors — it constrains what the orchestrator may dispatch, what a specialist skill may own, and what a free agent is authorized to do (composing with [`../specs/autonomy-tiers.md`](../specs/autonomy-tiers.md) and [`../standards/subagent-security-posture.md`](../standards/subagent-security-posture.md)).

## The Open Boundary — Orchestration-as-Skill vs. Orchestration-as-Agent

**[DEFERRED]** — resolved to a future small ADR, not decided here. [TARGET-STATE — not yet ratified: D3]

The single named open boundary is **which orchestration is a skill vs. an agent** — the routine-routing-vs-judgment split:

- **Routine, deterministic dispatch** (auto-invoke the next stage's evaluator at a boundary; route by a computed gate verdict) is **skill-eligible** — it is mechanical and belongs on the determinism side of the division above.
- **Judgment-laden conducting** (deciding whether an ambiguous gate result should PROCEED, re-sequencing under a surprise, weighing a scope change) is **judgment** — it stays with a free agent.

**Why deferred, not resolved:** the split depends on open decision **D1** (the actor ownership split itself), and its only current seed is itself forward-looking — the maturity path in [`../schemas/gate-evaluation-spec.md`](../schemas/gate-evaluation-spec.md) § Architecture Path, whose **Phase 2 "Standalone Skill" → Phase 3 "Orchestration Layer"** ("auto-invoked at stage transitions by the handoff coordinator; no manual trigger") describes exactly the *routine-dispatch* portion migrating to a skill while the judgment portion does not. Ratifying the precise cut is a decomposed decision for a future ADR, consistent with the no-big-bang-keystone posture in § Status & Scope; the interim rule is the determinism-vs-judgment division above.

## Migration Path from Hub-Spoke

How today's hub-spoke model maps onto the three actors (Now / Next / Later): [TARGET-STATE — not yet ratified: D5]

| Today (hub-spoke) | Target actor / form | Direction |
|---|---|---|
| **Hub session** (the single orchestrating Claude session that spawns Spokes) | **Orchestrator** — conducting migrates here; the routine-dispatch portion is skill-eligible, the judgment portion stays agent (see § The Open Boundary). | Now → Next |
| **Spoke / Sub-agent** (a spawned session executing one stage) | Split across **free AI agent** (the irreducible judgment the stage carries) **and** **specialist skill** (the bounded capability the stage invokes). | Next |
| **`stage-NN.md` procedures** (prose playbooks the spoke follows) | Demote to **advisory playbooks**; the **gate contract** (`gate-criteria-spec`) becomes the load-bearing enforcement surface. | Next → Later |

The migration is additive and reversible in the interim: the target model is carried as prose here while today's hub-spoke continues to run, and each hardening step (the first small ADR, the first contract-object) is taken only when its specific decision is ratified.

## Relationship to Neighbors

- [`architecture-overview.md`](architecture-overview.md) — the navigation parent (single-source current-state overview). This doc is the **forward-looking target-architecture** pointer from that overview's § Who This Serves human-orchestrator / agent-contributor split; the overview reciprocates with a link here.
- [`operating-model.md`](operating-model.md) — the **current** composition view (skill ownership, per-stage governance composition). This doc is its **target-state evolution**: operating-model.md describes how skills and governance compose *today*; this doc describes the *target* three-actor model that composition is evolving toward.

## Provenance

The issue and spike numbers below are provenance for this record; the prose above leads with self-describing roles so the meaning survives renumbering. This block is the designated reference home.

- The consolidating work item — the single authoritative statement this doc satisfies, sitting above (not restating) the pipeline-engine / role-skills / knowledge-architecture epics whose shared north-star it consolidates: #877.
- The home-decision spike — resolved the discipline-doc home for an evolving-vision-with-migration-path (ADRs being immutable point-decisions): #3617.
- **Consume-not-restate:** the six seed docs are cited by link at their point of use above (gate-evaluation-spec, gate-criteria-spec, agent-script-promotion-framework, autonomy-tiers, subagent-security-posture, terminology-glossary) and consolidated in § Consumed Surfaces; none has its normative text duplicated here, per [`../standards/duplicate-source-discipline.md`](../standards/duplicate-source-discipline.md).

### Consumed Surfaces (consume, not restate)

Cross-reference ledger — each seed doc cited by link, with the one-line facet it owns. No normative text is duplicated from these homes; this doc characterizes each by a self-describing facet and links to the source for the definition.

| Seed doc | The facet it holds |
|---|---|
| [`../schemas/gate-evaluation-spec.md`](../schemas/gate-evaluation-spec.md) | The stage-gate evaluation protocol + the Phase 1→2→3 maturity path (Manual → Standalone Skill → Orchestration Layer) — the seed for orchestration-as-skill. |
| [`../schemas/gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) | The structured gate-criteria schema and the `structural`/`metrics`/`judgment` Check enum — the **contract form** the enforcement shift lands on. |
| [`../standards/agent-script-promotion-framework.md`](../standards/agent-script-promotion-framework.md) | The AS0–AS4 promotion ladder, the **mixed-determinism rule**, and the **judgment-laundering** failure mode — the determinism-vs-judgment division on the script axis. |
| [`../specs/autonomy-tiers.md`](../specs/autonomy-tiers.md) | The Tier 0–3 WHO-acts-under-what-authorization axis governing autonomous action by the free agent. |
| [`../standards/subagent-security-posture.md`](../standards/subagent-security-posture.md) | The 4-mechanism defense-in-depth governing autonomous subagent spawning — the containment surface for free agents. |
| [`../specs/terminology-glossary.md`](../specs/terminology-glossary.md) | The canonical actor vocabulary (Hub / Spoke / Skill / Sub-agent) and the reserved workforce-identity slot this doc's `free AI agent` fills. |
