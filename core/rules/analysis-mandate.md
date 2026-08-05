---
title: Analysis Mandate — A Finding Is Not an Authorization
purpose: The operating rule that governs the finding-to-action transition — under an analysis-only mandate, a finding the agent produced is not an authorization to act on it; the analysis is finished, the held action is named with what would authorize it, and the checkpoint is emitted.
type: rule
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# Analysis Mandate — A Finding Is Not an Authorization

**Checkpoint:** registered as `DTA-9` in the Adherence Checkpoint Index of [`decision-time-adherence.md`](decision-time-adherence.md) § 2, so the rule surfaces at the moment the transition happens rather than being held and skipped.

## Purpose

An analysis was requested. The analysis found something. Closing what it found is not what was asked for.

The recurring failure is **not** misreading the request. It is receiving the request correctly, starting the right work, and crossing later — when the analysis surfaces a gap and the gap pulls toward closing it. A rule that fires when the request arrives is silent at the moment the failure happens and noisy at a moment when nothing is yet wrong. This rule moves the trigger to where the crossing occurs: the **finding-to-action transition**.

The cost is not only the unauthorized action. A check that stops assessing in order to remediate **corrupts the state it was invoked to certify** — the operator asked what is true and receives a report on a world the assessment itself changed.

## § 1 — What fires the rule

The rule fires when **both** hold.

**1 — The mandate is analysis-only.** Any one satisfier is sufficient:

| Satisfier | Signature |
|---|---|
| **The ask names a finding** rather than a change | map, list, assess, check, review, audit, compare, diagnose, trace, find · "is X ready" · "what would it take" · "where does Y stand" |
| **The ask carries an explicit hold** | "don't change anything" · "just tell me" · "read-only" · "don't do anything yet" |
| **The surface you are running under declares the contract** | a mode, skill, or stage whose own definition states it is read-only, recommend-only, or mutates nothing |

The third satisfier is why this rule is general. A declared read-only contract binds the surface **whether or not that surface carries its own guardrail against violating it** — the contract is the mandate, and the count of surfaces that declare one is far larger than the count that guard one.

**2 — You are about to cross from reporting to acting.** You have produced a finding and are about to take the action it implies, or to deliver a plan-to-act *in place of* the analysis that was asked for — and the authorization you would cite is **the finding itself**, not an instruction.

The trigger is **observable, not introspective**. It is never "am I overstepping?" — an agent that acts on its own finding is, by construction, acting on something it believes. It is: **what authorized this action — an instruction, or my own finding?**

## § 2 — The obligation

1. **Finish the analysis that was asked for.** A plan is not a substitute deliverable for a map, an assessment, or a check. Abandoning the scan at its most important signal is the failure, not a shortcut through it.
2. **Hold the execution, and name what you are holding.** One line: the action you are *not* taking, and what would authorize it. An unnamed hold is indistinguishable from not having noticed.
3. **Emit the checkpoint token** (per [`decision-time-adherence.md`](decision-time-adherence.md) § 3):

```
[DTA-9: mandate = "<the operative ask, quoted>" → analysis-only; holding <the named action>]
```

The left-hand side quotes the ask **verbatim**, because that quotation is the artifact a reviewer compares the response against. A token that paraphrases the mandate cannot falsify the agent's reading of it.

Recommendations, options, and a proposed plan are all in scope for an analysis mandate — **producing** them is analysis. **Executing** them is not.

## § 3 — What does NOT fire the rule

Stated positively, so the rule cannot creep into universal friction. The over-firing risk is symmetric with the under-firing risk: a rule that asks permission it already holds trains the operator to stop reading it.

- **An explicit execution instruction.** "Fix it", "update X", "run the release" — the ask licenses the act. No checkpoint.
- **A standing authorization that already covers the action** — an approved plan, an approved release, a stage running under an authorization already given. Re-opening a gate the operator already closed is its own failure mode; the *Approval authorizes the whole plan* preference in [`CLAUDE.md.template`](../CLAUDE.md.template) § Universal Preferences governs, and this rule never overrides it.
- **Reads and probes performed in service of the analysis.** Searching, opening, fetching, measuring — that **is** the analysis. Routine tool use with no action attached does not fire.
- **Ephemeral scratch outside the system under analysis** — a working note or a temporary probe that mutates nothing the analysis is about.
- **A surface whose own contract already carries an equivalent gate.** That gate discharges this one. No double-gating.

## § 4 — Worked instances (cited, not restated)

Two surface-scoped guardrails in the corpus are instances of this rule, each authored independently **before the rule existed** and neither referencing the other:

| Surface | Its own entry |
|---|---|
| [`release/skills/release-hub/SKILL.md`](../../release/skills/release-hub/SKILL.md) § Domain-Specific Failure Modes | the Mode-R entry — a read-only readiness mode that mutates state despite its contract |
| [`release/skills/release-planner/SKILL.md`](../../release/skills/release-planner/SKILL.md) § Domain-Specific Failure Modes | the Mode-B write-scope entry — read-only against governance files by contract |

Each remains authoritative for its own surface's specifics. Neither is restated here, and neither is superseded.

Two independent point fixes for one behavior class is the promotion threshold in [`failure-mode-standard.md`](../standards/failure-mode-standard.md) — met before the generalizing rule was written. The residual is the reason this rule is not scoped to those two surfaces: **every surface that declares a read-only, recommend-only, or mutates-nothing contract is bound by § 1 limb 1, and most of them carry no entry of their own.**

The rule also reaches a surface no skill-scoped guardrail can: an **ad-hoc conversational turn**, where no skill is loaded and there is no SKILL.md to carry an entry.

## § 5 — Precedence — do not author a third

A surface-scoped read-only guardrail is a **worked instance** of this rule, not an independent source.

When a new surface needs one: cite this rule, and name only that surface's own boundary. Do not restate the trigger, the obligation, or the non-trigger list — they live here and change here. Authoring another parallel *general* guardrail creates a second source for one behavior, which is precisely how this rule came to be needed.

## § 6 — Composition (compose, do not duplicate)

| Surface | Relationship |
|---|---|
| [`decision-time-adherence.md`](decision-time-adherence.md) | Owns the surfacing mechanism. This rule is `DTA-9`'s governing rule; the index owns when it surfaces and what is emitted. |
| [`discovery-discipline.md`](../disciplines/discovery-discipline.md) | Discovery-class work — asking what we do not know — is the activity class this rule most often protects. It defines the activity; this rule bounds what the agent may do on finding something during it. |
| [`review-discipline-principles.md`](../disciplines/review-discipline-principles.md) | Review-class work is the other locus. A review that remediates mid-pass has forfeited its own evidence. |
| [`CLAUDE.md.template`](../CLAUDE.md.template) § Universal Preferences — *Skill-boundary transparency* | The adjacent case: crossing a skill's declared scope under an authorization that already covers it. That preference governs the **notice**; this rule governs the case where **no such authorization exists**. |
