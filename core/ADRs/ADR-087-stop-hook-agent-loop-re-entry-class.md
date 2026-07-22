---
title: "ADR-087 — `Stop`-hook agent-loop re-entry as a hook class (ship-inert activation boundary)"
status: Proposed
date: 2026-07-22
release: pipeline-telemetry-tail (#261) (v3.80 provisional; bound at Stage 12)
deciders: "Stage 8 QA spoke surfaced the gap (the rationale lived only in a skill references/ file); the operator elected 'companion ADR, not a widening of ADR-086' at the Stage 9 plan-review gate 2026-07-22; the Stage-9 remediation spoke authored it; operator ratifies at the Stage 9 / activation gate"
tags: [core, runtime-control, hooks, agent-loop, activation-boundary, session-retro, precedent, autonomy]
source_observations:
  - "`core/settings.json.template` previously registered only `PreToolUse` and `SessionStart` hook events. This release adds the platform's FIRST `Stop` registration, and with it the first hook whose contract is to RE-ENTER the agent loop via `{\"decision\":\"block\",\"reason\":…}` rather than to permit or deny a pending tool call."
  - "The rationale for that choice — why `Stop` and not `SessionEnd`, why a once-per-session sentinel is mandatory, why the hook fails open — was documented only inside `core/skills/session-retro/references/sampling-and-trigger.md` § 4. A skill reference is not a durable home for a platform-wide runtime-control precedent: the next author to register a `Stop` hook has no reason to read another skill's references folder."
  - "ADR-086 governs the event-log SCHEMA extension for the same release. Its decision class (a data contract, CHEAP, revert-with-one-commit) is different from this one (a runtime-control mechanism, MODERATE at activation, workspace-wide), and supersession is per-decision — so widening ADR-086 would bind two unrelated decisions to one future supersession event."
---
<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->

# ADR-087 — `Stop`-hook agent-loop re-entry as a hook class (ship-inert activation boundary)

## Status

Proposed — authored at the Stage-9 remediation of release `pipeline-telemetry-tail`; ratified at the operator's plan-review / activation gate. The Accepted flip is verified against this file's `status:` field, never assumed from milestone closure.

This ADR does **not** authorize activation. It records what the mechanism *is* and the boundary that keeps it inert; turning it on remains a separate operator decision with its own pre-conditions (see Consequences).

## Context

Until this release the platform's hook surface had exactly one shape. Every registered hook was a **gate**: it ran at `PreToolUse` (or `SessionStart`), inspected a pending action, and either permitted it or blocked it. `block-destructive.sh`, `block-egress.sh`, `block-fs-boundary.sh` and their siblings all sit on that one axis — they constrain what the agent may do next, and they never cause the agent to do anything.

The session-retro capability needs something structurally different. A retrospective over a session is **reflection**, and reflection is not a thing a shell script can perform: only the agent can read what happened and decide what was learned. So the trigger must be able to hand control *back* to the agent at a session boundary. That is a different verb from "permit / deny", and it lands on a hook event the platform had never registered.

Three candidate mechanisms were available, and the constraint that decided among them is that **a shell hook cannot make the agent reason**:

| Candidate | Verdict |
|---|---|
| `SessionEnd` | **Rejected.** Session-terminal and correct in principle, but it is a cleanup hook — it can run a script, not a reflection, and it cannot re-enter the agent loop. Using it would force *deferred* reflection at the next session start, which needs catch-up machinery and reflects on a session whose context is already gone. |
| `Stop` | **Selected.** A `Stop` hook may return `{"decision":"block","reason":"…"}`, which re-enters the agent — the only supported way to obtain a reflection at a session boundary. It also receives the session identifier and transcript pointer on stdin, so a cheap triviality predicate is computable without a model call. |
| No hook (skill only) | **Kept as the floor, not the answer.** The skill is fully usable with no hook installed; the hook only automates the timing. This is what makes the ship-inert posture below honest rather than a stub. |

`Stop` carries a property that makes it materially harder to use correctly than a `PreToolUse` gate: **it fires at every assistant-turn boundary, not once per session.** An unguarded `Stop` hook that blocks would re-trigger on every turn — and the re-entered work's own final turn would re-trigger it again, which is an unbounded loop. A hook class that can restart the agent is therefore not "a `PreToolUse` hook on a different event"; it has its own correctness obligations, and those obligations belong in the durable record rather than in the one skill that happened to need the mechanism first.

## Decision

**Agent-loop re-entry via a `Stop` hook is adopted as a distinct hook class, admitted under four standing obligations, and every instance of it ships inert until the operator activates it.**

1. **`Stop` + `decision:block` is the sanctioned mechanism for agent re-entry at a session boundary.** `SessionEnd` is not an alternative for this purpose — it cannot re-enter the loop. A capability that needs the agent to *reason* at a boundary registers `Stop`; a capability that needs a script to *run* at a boundary registers `SessionEnd` and does not block.

2. **A re-entrant hook MUST carry an idempotence guard keyed to the boundary it claims.** Because `Stop` fires per assistant turn, a once-per-session sentinel keyed by session id is mandatory, and it MUST be written **before** the block decision is emitted — so that a failure part-way through the re-entered work cannot loop. A re-entrant `Stop` hook without a guard written in that order is defective by construction, not merely risky.

3. **A re-entrant hook MUST fail open, on every path.** Unreadable config, missing state directory, malformed stdin, absent session identity — every error exits 0 with no decision. A hook that can restart the agent can also wedge a session; the fail-open contract is what bounds that. No telemetry or convenience trigger may ever hold a session hostage to its own failure.

4. **A re-entrant hook ships INERT and is activated only by an explicit operator edit — the ship-inert activation boundary (D2(a)).** The hook script and its settings-template registration ship with the release; the *activation* does not. Concretely: the config default is disabled, the first enabled posture is observe-and-record rather than interrupt, and **no live settings file is modified by the release** — the template seeds a fresh install, an existing instance is untouched until the operator acts. This is a governance boundary, not an implementation gap: it means a release can land a runtime-control mechanism, and CI can exercise it, without any session behaving differently.

**Scope bound.** This ADR governs the **hook class** — the re-entry mechanism and the conditions under which the platform will register one. It does **not** govern what any particular re-entrant hook does with the turn it takes, nor the sampling policy of the capability that motivated it (that is the skill's own contract), nor the activation decision for any specific instance.

## Consequences

- **The platform now has two hook shapes, and they are not interchangeable.** A *gate* hook constrains a pending action and is reasoned about in terms of blast radius. A *re-entrant* hook consumes agent turns and is reasoned about in terms of loop safety and interruption cost. A reviewer assessing a new hook must first decide which shape it is; the four obligations above apply only to the second.

- **Obligation 2 is where this class fails, and it fails silently.** A missing or mis-ordered sentinel does not surface as an error — it surfaces as an agent that will not stop. This is also the obligation a test suite is least likely to catch: a suite that drives the hook *once* exercises the predicate but never the re-fire, so it cannot falsify the guard. Any future re-entrant hook needs a regression test that drives a **multi-`Stop` sequence** with the real payload shape and asserts fire-exactly-once-at-the-intended-boundary. This release's own instance carries a live defect of exactly this shape (the sentinel is written on a *skip* as well as on a fire, so the predicate is decided at turn 1 and frozen) — it is contained entirely by obligation 4, and it is the reason obligation 4 is stated as a requirement of the class rather than as a property of one capability.

- **The ship-inert boundary is now a reusable release pattern, not a one-off.** A runtime-control mechanism can land, be reviewed, be exercised by CI, and accrue real review attention across a full release cycle *before* anyone decides whether it should run. The cost is that "shipped" and "working" come apart for this class of change: a defect can pass a release gate on the correct grounds that nothing is at risk, which is only true while the boundary holds. Activation therefore requires re-verification, not just a config flip — the pre-activation conditions attached to the motivating capability are the current instance of that requirement.

- **The rationale is now discoverable from the hook surface itself** rather than from one skill's `references/` folder. That was the concrete failure this ADR closes: at the activation gate someone will ask "what does it mean that a hook can restart the agent?", and until now there was no durable record to read.

- **Registering `Stop` is workspace-wide.** Unlike a skill (opt-in per invocation), a hook registration in the settings template applies to every session in an instance that adopts the template. That asymmetry is precisely why the activation boundary is part of the decision rather than a deployment detail.

## Reversibility

**CHEAP as shipped / MODERATE at activation — Confidence HIGH / MEDIUM respectively.**

*As shipped:* the registration, the script, and the config block are additive and inert; `git revert` of the release PR removes them and no session's behaviour changes in either direction, because none changed on the way in. Confidence HIGH — inertness is asserted by the hook's own self-test (absent config → no decision, exit 0) and does not depend on operator discipline.

*At activation:* enabling the trigger is two deliberate one-line edits to an operator-instance file, each reversible in one line, and the fail-open contract bounds the worst case to "the trigger does nothing". Confidence MEDIUM rather than HIGH because activation registers, workspace-wide, the platform's first hook able to re-enter the agent loop — the failure mode is interruption of live sessions, which is observable immediately but is not something a revert un-experiences.

## Related ADRs

- **ADR-086** (event-log schema decision-subtype extension, same release) — the **sibling, not the parent**. ADR-086 governs the *data contract* the session-retro capability writes into; this ADR governs the *runtime mechanism* that invokes it. They were deliberately kept separate: one is a CHEAP schema edit and the other a MODERATE runtime-control precedent, and because supersession is per-decision, folding them together would bind a future revision of either to a revision of both.
- **ADR-078** (security-hook dependency-resolution posture) — the nearest prior hook-scoped decision. It governs how a *gate* hook resolves its dependencies; this ADR introduces the second hook shape that decision's framing did not contemplate.
- No superseding or superseded relationship. This is the first ADR to govern agent-loop re-entry as a class.

### Issue References

- #2423 — the per-session self-retrospection capability whose trigger introduced the `Stop` registration; the ship-inert activation boundary and its pre-activation conditions attach to that work item.
- #261 — release milestone `pipeline-telemetry-tail`, under which the hook class was reviewed and this record was directed at the plan-review gate.
