---
title: Autonomous Execution Model
purpose: Platform-level patterns for self-repair-and-retry, escalation, and rollback during pipeline execution
type: discipline
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
applies_to: All skills + spokes producing decision-class or execution-class output during the 13-stage pipeline
parallel_to: decision-discipline.md, reversibility-protocol.md, review-discipline-principles.md, failure-mode-standard.md
source: autonomy-tiers-and-self-repair
---
<!-- reference-durability: allow-link -->

# Autonomous Execution Model

## Purpose

This document defines three named platform-level patterns that govern self-repair-and-retry between governance gates: **Retry**, **Escalate**, and **Rollback**. The patterns codify the operating-model commitment: one human gate (PR review) with autonomous execution and self-repair between gates. Without a documented protocol, "autonomous execution" would remain undefined — every skill would implement it differently or not at all. This model fixes that surface.

The model parameterizes:

- **WHEN** an agent self-repairs versus halts and surfaces to the operator (trigger conditions per pattern).
- **HOW** self-repair executes (mechanism per pattern, with bounded iteration counts).
- **WHAT** the operator sees on escalation (Decision Briefing format per `decision-discipline.md`).
- **WHO** authorizes destructive recovery actions (rollback is operator-only).

Consumer skills (planning, engineering, dev-testing, QA, deployment) cite this model from their per-stage Self-repair lines in `release-process.md`. The 13 cross-references make this document the single source of truth for cross-cutting recovery behavior across the pipeline.

## Scope and Applicability

### What this model governs

- Cross-cutting recovery behavior between the 13 governance stages (`pipeline/`).
- Iteration thresholds for retry loops, inter-stage feedback, and operator escalation.
- The composition rules between Retry → Escalate → Rollback.
- The format of the Decision Briefing surfaced to the operator on escalation.
- Rollback authorization (operator-only, post-merge).

### What this model does NOT govern

- **Per-skill error handling.** Skill-internal preconditions, input validation, and skill-specific failure modes are documented per skill in each `SKILL.md` § Failure modes per `failure-mode-standard.md`. This model intentionally does not absorb that surface — Risk R3 explicitly bounded the patterns at platform level. A skill that detects a malformed input still runs its own `## Failure modes` precondition check; the cross-cutting recovery behavior (when the precondition check itself raises a transient `gh` API failure, for example) is what this model governs.
- **Hook enforcement behavior.** PreToolUse hooks (`bypass-mode-readiness.md`) operate before tool invocation and have their own warn/enforce mode. Hook blocks are not retried by this model; they are escalated as governance-violation findings.
- **Manual operator workflows.** Operator-initiated work (cleanup, refactor, exploratory analysis) is out of scope. This model applies when an agent is executing pipeline work autonomously.

### Consumer scope

The model is consumed by the 13 stages of `release-process.md` (Stage 1 Intake through Stage 13 Close), via the `**Self-repair:**` line each stage carries. Skills inside each stage MAY cite this model from their own SKILL.md when their behavior crosses gate boundaries — but per-skill error handling stays in each skill's `## Failure modes` section per `failure-mode-standard.md`.

## Retry Pattern

### Trigger conditions

- Transient external failure (network timeout, `gh` API rate-limit, `git` lock contention, filesystem race).
- Failure type is recoverable (a fresh attempt with same inputs has plausible chance of success).
- Failure does NOT indicate semantic error (malformed input, missing artifact, unauthorized state, 4xx-class HTTP, governance violation).

### Mechanism (5 steps)

1. **Capture** failure: ≤200 char stderr summary appended to retry log (per-call-site, ephemeral).
2. **Wait** per backoff schedule (exponential with jitter — see below).
3. **Re-execute** the failed call with same inputs.
4. **On success**: log retry count + proceed. **On failure**: increment counter; if counter < cap, return to step 1 with next backoff interval.
5. **On cap exhaustion**: emit Escalate Pattern with retry log attached.

### Backoff schedule

Exponential backoff with jitter — **1s, 2s, 4s** for attempts 2, 3, 4 respectively. Three retry attempts maximum (call + 3 retries = 4 total invocations) for generic transients; bounded latency keeps the agent responsive and prevents thundering-herd amplification on shared services.

### Success criteria

- Retried call returns exit 0.
- Or: semantic-success signal (e.g., `gh pr create` returns URL; `git push` reports `up-to-date` / `new branch`; `gh issue edit` returns issue object).

### Give-up criteria (escalate)

- Retry attempts exhausted at the cap.
- Failure type changes between attempts (suggests systemic issue, not transient).
- Stderr indicates auth, permission, 4xx-class HTTP, or governance-violation signature.
- Hook block (escalate as governance-violation finding, not retry).

### Production-impacting cap exception

For production-impacting call sites — `core/deploy/deploy.sh --deploy`, `git push origin main`, `gh pr merge` — the retry cap is **2 attempts** (call + 2 retries = 3 total invocations) rather than 3. Rationale: production observability + partial-deploy risk warrant earlier escalation; the cost of running an extra retry on a partially-deployed state outweighs the benefit. Cited by `release-process.md` Stage 12 Self-repair line.

## Escalate Pattern

### Trigger conditions

- **Retry exhausted** at cap (transient cap=3 OR production-impacting cap=2).
- **Tier 1+ finding** from downstream stage per `release-process.md` § Inter-Stage Feedback Protocol.
- **D-class decision** identified during execution per `decision-discipline.md` § 3 (architectural / cross-cutting / load-bearing decision encountered).
- **Tier 0 Premise Rejection** per `triage-design-rereview.md` (always-escalate; cap=0).
- **Iteration threshold exceeded** for any inter-stage loop (DT cap=3, QA cap=3, generic boundary cap=2).
- **Ambiguous state** requiring human judgment (e.g., conflicting artifacts; cross-source date disagreement; unrecognized failure signature).

### Mechanism (4 steps)

1. **Compose** Decision Briefing per `decision-discipline.md` § 3 triage table.
2. **Surface** to operator at the appropriate channel:
   - **In-spoke** for sub-task-scoped decisions (post on the active sub-task).
   - **Hub-level** for release-scoped decisions (post on the release Milestone or release-plan deviation log).
   - **Direct** for session-blocking ambiguity (post in the active conversation).
3. **HALT** execution on the affected work item until operator decision arrives.
4. **On operator decision**: route per the rendered decision; record the routing decision in the sub-task or release-plan deviation log.

### Escalation surface format (template)

```markdown
## Escalation — [Trigger]

**Stage:** [Stage N name]
**Sub-task:** #NNNN
**Issue:** #M
**Trigger:** [retry-cap-exhausted | tier-1-finding | d-class-decision | tier-0-premise-rejection | iteration-threshold | ambiguous-state]

### Context
[1-3 sentences: what was attempted, what failed, what's blocked]

### Recommendation
[Per decision-discipline.md M1/M2/M3 as applicable]

### Options
- (a) [option] — [reversibility tier · confidence]
- (b) [option] — [reversibility tier · confidence]

### Reversibility / Confidence
[CHEAP|MODERATE|EXPENSIVE|IRREVERSIBLE · HIGH|MEDIUM|LOW]
```

The agent populates the template fields from the failure context. Reversibility tier follows `reversibility-protocol.md`; the agent labels each option's tier so the operator can match review rigor to undo cost.

## Pause-to-Learn Pattern

The third pre-action sibling to Retry and Escalate. Where Retry is **failure-anchored** (a transient failure already happened mid-action) and Escalate is **ambiguity-anchored** (a decision belongs to the operator), Pause-to-Learn is **competence-anchored and self-closing**: it fires *before* the agent acts, when the agent's grounds for the pending decision are weak, and its default resolution is to **learn the gap closed itself** — not to hand the decision to the operator. It is the agent asking "do I actually have grounds to act here?" and, when the answer is no on an action that is not trivially reversible, fetching new signal before proceeding rather than proceeding silently.

This pattern is strictly additive to the Retry / Escalate / Rollback set; it mutates none of them. It routes *into* the Escalate Pattern only as a terminal fallback (the self-closing default having failed to close the gap), exactly as Retry routes into Escalate on cap-exhaustion.

### Trigger conditions

- **A pending decision carries a low decision-confidence reading** — the agent's grounds for the conclusion are weak (independent cross-checks disagree, a specific gap is nameable, or the weakest evidence label is an unverified assumption) — **on an action whose reversibility tier is above CHEAP** (MODERATE / EXPENSIVE / IRREVERSIBLE). A low-confidence reading on a CHEAP action proceeds — pausing on a trivially-reversible action is ceremony with no payoff.
- The decision is **decision-class** (a recommendation, a proceed/defer choice, a plan, a proposed action) — not an observation, a status summary, or an evidence citation.
- The gap is **plausibly closable by injecting new external signal** (a canonical-source read, a second tool call, a re-derivation) rather than being a decision the operator must own — an operator-owned ambiguity is the Escalate Pattern's trigger, not this one.

This trigger is **pre-action**, distinct from Retry's mid-action transient-failure trigger: nothing has failed yet; the agent has not yet acted. It is **competence-anchored**, distinct from Escalate's ambiguity-anchored trigger: the question is whether *the agent* has grounds, not whether the decision is *the operator's* to make.

### Mechanism (4 steps)

1. **Read the decision-confidence signal** for the pending decision and select the action from the reversibility × autonomy threshold — both per the Decision-Confidence Protocol (`core/specs/decision-confidence-protocol.md`, landing this release). The reversibility tier scales the action: the same low-confidence reading proceeds at CHEAP, pauses here at MODERATE/EXPENSIVE, and routes straight to the Escalate Pattern at IRREVERSIBLE.
2. **Run the bounded pause-to-learn loop** per that protocol — name the gap, inject one new external signal, re-evaluate. The loop is bounded (a small cycle cap) and self-closing: a cycle that injects *no* new signal is a stall, not a pause, and is a guard violation.
3. **Exit on resolution** — when the new signal grounds the decision, proceed at the action's existing authorization tier. This pattern is a **brake, not an accelerator**: closing a confidence gap never promotes an action above the autonomy tier it was already authorized for (it lowers ceremony when grounded, never raises authority).
4. **Escalate on exhaustion** — if the loop's budget is reached and the gap has not closed, emit the Escalate Pattern with the named gap and what was tried as the Decision Briefing's Context. The escalation is the *fallback*, not the default — the default resolution is the agent closing the gap itself.

### Self-closing default — the load-bearing distinction

The load-bearing distinction from Escalate is **who resolves the trigger by default**. Retry resolves itself (a fresh attempt) and escalates only on cap-exhaustion. Pause-to-Learn likewise resolves itself (the agent fetches the missing signal) and escalates only on budget-exhaustion. Escalate, by contrast, hands the decision to the operator as its *first* move. Defaulting Pause-to-Learn to escalate-to-operator would collapse it into Escalate and erase the competence-anchored nature the pattern exists to capture — the whole point is that a low-confidence reading on a closable gap is the agent's to close, not the operator's to adjudicate.

The mechanism specification — the confidence signal, the reversibility × autonomy threshold, the bounded loop with its exit conditions, and the anti-theater guard that keeps a pause from degenerating into a stall — lives in the Decision-Confidence Protocol and is referenced here, not restated. This file registers the trigger as a control-flow sibling; the protocol owns the mechanism.

## Rollback Pattern

### Trigger conditions

- **Production-impacting failure post-merge** (Stage 12 / Stage 13 — observable defect in deployed state).
- **QC4 failure** post-deploy (per `release-process.md` § Checkpoint 4: Post-Deploy Verification).
- **Stage 9 NO-GO post-merge** (rare; pre-merge NO-GO is just branch reset, not rollback).
- **Operator-initiated rollback** per Decision Briefing routing.

### Authorization requirement — OPERATOR-ONLY

Agents do **NOT** initiate rollback autonomously. The Rollback Pattern is operator-authorized at every invocation — explicit confirmation in chat or a sub-task comment is required before the agent executes any of the 8 mechanism steps. This is the load-bearing distinction between Rollback and the other two patterns.

**Reversibility tier:** `IRREVERSIBLE · confidence: HIGH` per `reversibility-protocol.md` — the rollback action itself is reversible (re-merge restores the reverted state), but the externally-observable consequence (deployed-then-reverted state visible to consumers, GitHub history, or downstream tooling) is committed. This justifies the operator-only authorization gate.

### Mechanism (post-merge, agent-executed under operator authorization, 8 steps)

1. **Operator authorizes rollback** — explicit confirmation in chat or sub-task comment ("approved", "rollback vX.Y", or equivalent).
2. **Identify rollback target** — merge commit SHA introducing the regression (`git log --oneline main` to locate).
3. **Execute** `git revert <merge-sha>` on `main` — single revert undoes the squash-merged release atomically.
4. **Push** the revert via PR-merge per `gh` CLI; force-merge prohibited per `git-workflow.md`.
5. **Delete release tag** if appropriate: `git tag -d vX.Y` then `git push origin :vX.Y`.
6. **Reopen** all release issues; restore Status=Bundled; reassign Milestone vX.Y.
7. **Append** a `RELEASE_LOG.md` rollback entry per `RELEASE_PROTOCOL.md` § Rollback protocol.
8. **Restart** at Stage 4 Planning with a revised plan that addresses the regression cause.

### Rollback procedure reference

For the canonical procedure (including snapshot-restore semantics for the operational non-git surface), see `release/governance/RELEASE_PROTOCOL.md` § Pre-Change Snapshot Protocol § Rollback protocol. The 8-step mechanism above is the git-native rollback sequence; `RELEASE_PROTOCOL.md` is the authoritative source for the operations-domain (snapshot-driven) and cross-domain procedures.

### Operations-domain rollback (non-git)

Per `RELEASE_PROTOCOL.md` § Rollback protocol — restore from `Releases/_snapshots/[version]/` if within the 15-release active window; reconstruct from the Dry-Run Record otherwise. The operational surface has no git as a recovery mechanism; the snapshot is the rollback target.

### Pre-merge "rollback" (NOT a true rollback)

Stage 9 NO-GO before merge → branch reset (from a fresh worktree) or PR close with no merge. No production impact; no operator authorization gate (nothing was deployed). This case is named "rollback" colloquially but is not governed by this pattern; treat it as a Planning-stage iteration.

## Pattern Composition

The three patterns compose as a directed cascade:

```
[transient failure]
       │
       ▼
[Retry Pattern] — 1-3 attempts (or 1-2 production-impacting)
       │
       ▼ (cap exhausted or non-retryable)
[Escalate Pattern] — Decision Briefing surfaced to operator
       │
       ▼ (operator authorizes)
[Rollback Pattern] — operator-only, post-merge undo per RELEASE_PROTOCOL.md
```

### Composition rules

- **Retry MAY chain to Escalate** — automatic on cap-exhaustion. The escalation carries the retry log attached so the operator can diagnose.
- **Escalate MAY chain to Rollback** — operator-explicit only. The agent never auto-promotes an escalation to a rollback; rollback always requires the operator to render the decision.
- **Rollback NEVER chains to Retry** — a fresh forward-facing release is the recovery, not a retried rollback. If the rollback itself fails (e.g., `git revert` produces conflicts), the agent escalates again with the failure context; it does not loop the rollback.
- **Pause-to-Learn precedes the action and MAY chain to Escalate** — it is a pre-action trigger, not a node in the failure cascade above: it fires on a low-confidence decision *before* any action runs (so before any transient that would start the Retry → Escalate chain). It resolves itself by default (the agent closes the gap) and chains to Escalate only on budget-exhaustion, the same terminal-fallback relationship Retry has with Escalate. It never chains to Rollback (it is pre-action; nothing has been committed to roll back).

### Skip-permissions

- **Skip-Retry-to-Escalate IS permitted** for non-retryable failure types: auth, permission, malformed input, governance violation, hook block, 4xx-class HTTP. The agent skips the Retry Pattern and proceeds directly to Escalate when the failure signature is non-transient.
- **Skip-Escalate-to-Rollback IS prohibited** — rollback always requires explicit operator-authorized Escalate path. Every rollback invocation traces back to an Escalation that the operator rendered with rollback as the chosen option.
- **Skip-Pause-to-Escalate IS permitted (and required at IRREVERSIBLE)** — a low-confidence reading on an IRREVERSIBLE action skips the pause-to-learn loop and routes directly to Escalate, because no bounded learning loop can buy back an irreversible mistake; the operator owns that call. Likewise a gap that is plainly the operator's to adjudicate (not closable by the agent fetching signal) skips the pause and escalates directly.

## Per-Stage Application

The canonical map of which patterns apply to which stages. Each stage's `**Self-repair:**` line in `release-process.md` cites this section as the authoritative reference.

| Stage | Retry applies | Escalate applies | Rollback applies |
|---|---|---|---|
| 1 Intake | YES (`gh issue create` transients, cap=3) | YES (template fields cannot be populated → Observation tier) | NO (pre-merge) |
| 2 Triage | YES (`gh issue view` / `gh project item-edit` transients, cap=3) | YES (G2-04 dependency block on Rejected dep) | NO (pre-merge) |
| 3 Bundle | YES (`gh issue edit --milestone` / `--add-label` transients, cap=3) | YES (G3 FAIL without operator override) | NO (pre-merge) |
| 4 Planning | YES (`gh` / `git fetch` / `git log` transients, cap=3) | YES (D-Gate decisions; unresolved cross-PR contention) | NO (pre-merge) |
| 5 Solutioning | YES (`gh issue view` transients, cap=3) | YES (QC2 fail; Tier 0 Premise Rejection always-escalate; D-class design decision) | NO (pre-merge) |
| 6 Engineering | YES (`gh pr create` / `git push` transients, cap=3) | YES (retry-exhausted PR creation; merge conflict; Tier 2/3 DT findings) | NO (pre-merge) |
| 7 Dev Testing | YES (`gh pr view` / `git diff` / `core/deploy/deploy.sh --check` transients, cap=3) | YES (>3 DT iterations per existing protocol; Tier 2/3 findings) | NO (pre-merge) |
| 8 QA Testing | YES (eval-execution transients, cap=3) | YES (>3 QC3 round-trips per existing protocol; Tier 2/3 findings) | NO (pre-merge) |
| 9 Plan Review | NO (Tier 3 human gate — no automation to retry) | YES (NO-GO IS the Escalate path) | YES (post-merge NO-GO triggers operator-authorized rollback) |
| 10 Dry Run | N/A (compressed into Stage 9 for git-native releases) | N/A | N/A |
| 11 Snapshot | N/A (compressed; git history IS the snapshot) | N/A | N/A |
| 12 Execute | YES (`gh pr merge` / `git tag` / `core/deploy/deploy.sh --deploy` transients, **cap=2 — production-impacting**) | YES (retry-exhausted deploy; pre-merge metadata gap) | YES (operator-only on post-merge regression) |
| 13 Close | YES (`gh issue close` / `gh project item-edit` transients, cap=3) | YES (QC4 failure → automatic operator notification per existing rule) | YES (operator-only on QC4 systemic regression) |

### Notes on the table

- **Stage 9 Retry NO** because the stage is a pure human gate (`release-process.md` § Stage 9 `**Automation:** Tier 3 (Human-only)`) — there is no agent-side call site to retry. NO-GO IS the escalate-equivalent at this stage.
- **Stage 10 / Stage 11 N/A** because both compress into Stage 9 / git-native mechanisms for git-native releases. When compression exceptions apply (non-git deploys, destructive ops), these stages activate and the same Retry / Escalate posture as Stage 12 / Stage 13 applies.
- **Stage 12 Retry cap=2** is the production-impacting exception per the Retry Pattern — production observability + partial-deploy risk warrant the tighter cap.
- **Rollback applies post-merge only** — Stages 9, 12, 13. All other stages handle pre-merge NO-GO via branch reset, not rollback.

## Iteration Thresholds

The load-bearing iteration caps committed at Stage 5 Solutioning. These values are referenced by the per-stage Self-repair lines in `release-process.md` and by consumer skills.

| Threshold (load-bearing) | Cap | Source / Rationale |
|---|---|---|
| Network/API transient retry (per call site) | 3 attempts | Generic network-engineering heuristic; bounded latency; aligns with operator memory ("retry up to 3 attempts") |
| Production-impacting retry (per call site) | 2 attempts | Tighter than generic; production observability + partial-deploy risk |
| DT ↔ Engineering iteration loop (per issue) | 3 passes | `release-process.md` Stage 7 precedent (">3 iterations" escalates) |
| QA ↔ Engineering iteration loop (per issue) | 3 round-trips | `release-process.md` QC3 precedent (">3 round-trips" escalates). Harmonized with DT cap=3. |
| Inter-Stage Feedback boundary (default) | 2 iterations | `handoff-coordinator-spec.md` specification default (boundary-specific overrides allowed) |
| Solutioning entry — Tier 0 Premise Rejection | 0 retries | `triage-design-rereview.md` Phase 1 always-escalate |
| Generic skill-internal retry (skill SKILL.md self-repair) | Per skill SKILL.md | Per `failure-mode-standard.md`; **NOT governed by this model** (Risk R3 scope guard) |

### Notes on thresholds

- **DT cap=3 and QC3 cap=3 are harmonized**. Both escalation triggers fire on the 4th iteration / round-trip (literal reading: ">3 escalates" in both `release-process.md` Stage 7 Self-repair line and Stage 8 / Checkpoint 3). The harmonized value matches DT precedent (Stage 7 `>3 iterations`), operator memory ("retry up to 3 attempts"), and the most lenient interpretation that still escalates unproductive loops.
- **Per-skill error handling** is explicitly **NOT GOVERNED** by this model. Each skill's `SKILL.md` § Failure modes governs its own preconditions, input validation, and per-skill recovery — see `failure-mode-standard.md`. This model handles cross-cutting recovery (the cap when a skill's `gh` API call hits a transient, for instance), not the skill's domain-specific failure logic.

## Autonomous Execution Disposition

The Retry / Escalate / Rollback patterns above govern recovery *on failure*. This section governs the positive disposition *between* failures: when an agent acts autonomously versus surfacing a decision to the operator, and what an agent always produces after an analysis pass. The operating-model commitment is one human gate (PR review) with autonomous execution between gates — manufacturing extra approval gates the framework has already resolved is its own failure mode.

### Execute Tier 1 routing autonomously

Classify each finding against the routing tiers defined in `release-process.md` § Inter-Stage Feedback Protocol:

- **Tier 1 (minor adjustment)** — execute it. File fixes that match the spec, tooling-enumeration updates, stale cross-references, and documentation-precision tweaks go directly to Engineering via a fix commit. Report what was done and route to the next stage; do not request routing approval. Presenting options the framework has already resolved is a "context-available-but-not-applied" failure, not diligence.
- **Tier 2 (scope change)** — produce a Decision Briefing per § Escalate Pattern and surface it.
- **Tier 3 (plan rejection)** — escalate.

Within a scope-lock window (the period between scope-lock approval and the Plan Review gate), Tier 1 findings have predetermined routing — execute them without re-consulting the operator.

### Sequenced routing is pre-authorized

When the operator has approved a plan that establishes an execution sequence, advancing to the next item in that sequence is itself Tier 1 routine routing — the approved plan IS the standing authorization. Do not re-confirm each step ("shall I proceed to the next item?") after every completed unit of work. Verifying that the prior unit completed and emitting a brief status report ARE the autonomous action; they substitute for a per-step confirmation. Re-confirming each step duplicates the governance the plan approval already provided.

### Reserve operator decision points

Surface a decision to the operator only at: the governance gates (Plan Review, Execute), Tier 2/3 escalations, scope changes, irreversible actions, and genuinely novel or ambiguous situations the framework does not resolve. Between these, exercise judgment per the framework.

The disposition shows up in phrasing. Prefer the declarative form — *"Doing X because [framework rule]. Next: Y."* — over the interrogative *"Should I do X?"* / *"Shall I do Y?"* when the framework already says Y is next. Reach for a question only when the decision is genuinely the operator's to make.

### Always propose next steps

After any analysis pass — triage, review, planning, audit — end the output with explicit, actionable next-step recommendations. Do not stop at summarizing findings. Analysis without recommendations stalls at the review step; the disposition is push-to-resolve. Recommendations are about *forward motion* (what to do next); they are distinct from captured-debt logging (what to revisit later) — produce both where each applies.

## Relationship to Other Principles

This model composes with — but does not replace — the platform's other principal-level disciplines.

| Principle | Relationship | Composition |
|---|---|---|
| `decision-discipline.md` | Escalate Pattern produces decision-class output; the Decision Briefing inherits the M1/M2/M3 triage from `decision-discipline.md` § 3 | Escalate cites `decision-discipline.md` § 3 triage table for Briefing structure |
| `reversibility-protocol.md` | Each pattern carries a reversibility tier (Retry: CHEAP; Escalate: MODERATE-EXPENSIVE; Rollback: IRREVERSIBLE) | Pattern outputs label tier per `reversibility-protocol.md` four-tier vocabulary |
| `decision-confidence-protocol.md` (landing this release) | The Pause-to-Learn Pattern is the 3rd pre-action sibling to Retry/Escalate; that protocol owns its mechanism (confidence signal, reversibility × autonomy threshold, bounded loop, anti-theater guard) | Pause-to-Learn cites the Decision-Confidence Protocol for the signal it reads and the bounded loop it runs; this model registers the trigger as a control-flow sibling and does not restate the mechanism |
| `review-discipline-principles.md` | Review-class output disciplines apply to escalation findings (root cause, evidence, no PARTIAL verdicts) | Escalation findings cite `review-discipline-principles.md` when surfaced from review-class skills (build-reviewer, pmo-qa-auditor, pmo-skill-editor Mode D) |
| `failure-mode-standard.md` | Per-skill failure modes (skill-internal) compose orthogonally — skill failure → skill self-repair → escalate-to-pattern | Skill `SKILL.md` § Failure modes describes precondition checks; this model handles cross-cutting recovery |
| `pipeline/stage-NN-<name>.md` | Per-stage automation tier informs which patterns apply (Tier 1 stages carry full Retry+Escalate; Tier 3 stages skip Retry — Escalate IS the gate) | Per-stage table in § Per-Stage Application above is the authoritative pattern × stage map |

### Composition example — Escalation from a review-class skill

When `pmo-qa-auditor` (a review-class skill) detects a Tier 2 finding during Stage 8 QA Testing:

1. **Failure mode** (per `failure-mode-standard.md`): `pmo-qa-auditor` § Failure modes precondition flags the finding internally.
2. **Review discipline** (per `review-discipline-principles.md`): the finding is recorded with root cause + evidence, no PARTIAL verdicts.
3. **Escalate Pattern** (this model): the finding triggers Escalation per Stage 8 trigger conditions.
4. **Decision Briefing** (per `decision-discipline.md` § 3): the Escalation surface is composed from the M1/M2/M3 triage.
5. **Reversibility** (per `reversibility-protocol.md`): each option in the Briefing's Options block carries a CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE tier with a confidence label.

The four other principles compose into this model's Escalate Pattern; the model does not duplicate their content.
