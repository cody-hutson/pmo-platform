<!-- reference-durability: allow-link -->
---
title: ADR-113 — A general analysis-mandate rule supersedes per-surface read-only point fixes
status: Proposed
date: 2026-08-04
release: agent-edit-discipline-codification
deciders: "Workspace owner (ratifies at the Stage 9 GO gate); design authored at Stage 5 Solutioning under the Principal Engineer persona; clause-file name resolved at Stage 6 Engineering after Collective Review declined to lock a shared container"
tags: [agent-behavior, read-only, analysis-mandate, pre-action-gate, core-rules, decision-time-adherence, reversibility-cheap]
source_observations:
  - "Two surface-scoped read-only guardrails already exist in the skill corpus with no cross-reference between them. The earlier was authored in the initial public release; the later, more than a month afterwards, by a card that never cited it. Two independent point fixes for one behaviour class meets the failure-mode promotion threshold, and that threshold was met before the generalizing card was filed."
  - "Nineteen of fifty-five skill definitions declare a read-only, recommend-only, or mutates-nothing contract; two carry a guardrail against violating it. The residual exposure is seventeen surfaces, measured rather than hypothesised."
  - "In both recorded instances the agent parsed the analytical request correctly and crossed later. The closed card's own root-cause record describes the readiness validation as abandoned mid-check in favour of remediation planning, at the moment it hit its most important signal."
  - "A corpus-wide probe for a general read-only or analysis-intent guardrail returned zero files, against a sensitivity arm returning eighty-eight and a specificity arm that declined a genuine near-miss on an input proven non-empty."
  - "The closed card's own body proposed a mechanical signal for a read-only mode invoking a mutating tool, and described it as a platform-wide pattern. That item was scoped out at authoring time and never filed."
---

# ADR-113 — A general analysis-mandate rule supersedes per-surface read-only point fixes

## Status

**Proposed.** Flips to **Accepted** at this release's Stage-9 GO gate. Per the established precedent the flip is verified against this file's own `status:` field and is never assumed from milestone closure.

**Numbering.** ADR numbers are platform-global monotonic across **both** homes (`core/ADRs/` and `release/ADRs/`), including in-flight pull-request claims. Re-verified at Engineering Commit 0: the union of both directories tops out at 112, and one open pull request holds 110 and 111. This record therefore takes **113**. The gap-free gate consequently reports the same transient, self-closing gap already documented for 112 — it names 110 and 111 as missing, not 113. That is the gate working, and it closes when the holder of 110/111 lands. Renumbering downward into a slot an open pull request holds would trade a transient gap for a permanent duplicate.

## Context

A read-only contract that the agent itself breaks is worse than no contract, because the operator relied on it.

Two instances are on record. In one, a readiness mode contracted to mutate nothing created and edited tracker state mid-assessment. In the other, an ad-hoc request to map how something works today was answered with a remediation plan instead of the map. Both were repaired the same way: a failure-mode entry added to the one skill definition where the failure was observed.

Three facts make that repair pattern the wrong shape.

**First, the pattern is already N=2 with independent provenance.** A second, earlier surface-scoped guardrail of the same shape exists in a different skill, authored over a month before the one everybody remembers, and the later author did not cite it. Two independent point fixes for one behaviour class is the promotion threshold in the failure-mode standard — met before the generalizing card was filed, not predicted by it.

**Second, the residual is measured, not hypothesised.** Nineteen skill definitions declare a read-only, recommend-only, or mutates-nothing contract. Two guard it. The next surface to fail this way is seventeen candidates deep, and each additional point fix would create one more independent source of truth for one behaviour.

**Third, no per-surface fix can reach the second recorded instance.** It happened in an ad-hoc conversational turn where no skill was loaded and there was no skill definition to carry an entry. A remedy that lives inside skill definitions is structurally blind to the case it must cover.

There is also a framing correction that changed the design. The card frames the failure as read-only *requests* answered with execution, which implies the remedy is better request classification. Both recorded instances falsify that: the request was parsed correctly and the crossing happened later, once the analysis surfaced something. A gate at request-arrival fires on every turn, including the overwhelming majority that are fine, and is silent at the moment that is not.

## Decision

**Codify one general rule at the finding-to-action transition, and make every surface-scoped guardrail an instance of it rather than an independent source.**

The rule lands as `core/rules/analysis-mandate.md`. It fires when the operative mandate is analysis-only **and** the agent is about to take the action a finding implies — or substitute a plan-to-act for the analysis requested — with the finding itself as the only citable authorization. The mandate limb has three satisfiers: an ask that names a finding, an ask carrying an explicit hold, or a surface whose own definition declares a read-only, recommend-only, or mutates-nothing contract. That third satisfier is what makes the rule general: it binds all nineteen declaring surfaces, whether or not any of them carries a guardrail of its own.

**Trigger at the transition, not at intake.** The trigger is observable and falsifiable from the response text alone — *what authorized this action, an instruction or my own finding?* — rather than a judgment about what the request meant. Request-intent classification has no ground truth for mixed asks and fires on every turn.

**Register the obligation as a checkpoint** in the decision-time adherence index, so it surfaces at the decision moment rather than being held and skipped. The registration satisfies that index's four-field declaration contract; the substantive prose stays in the rule's own file, and neither restates the other.

**State the non-triggers normatively, not as advice.** An explicit execution instruction, a standing authorization already given, reads performed in service of the analysis, ephemeral scratch outside the system under analysis, and a surface whose own contract already gates the same thing — five entries, enumerated, because over-firing is symmetric with under-firing and a rule that asks for permission it already holds trains the operator to stop reading it.

**Establish precedence explicitly.** A surface-scoped read-only guardrail is a worked instance that cites this rule and names only its own surface's boundary. The two shipped point fixes are cited, not superseded and not restated — each still carries surface-specific detail the general rule must not absorb. Authoring a third parallel *general* guardrail is the thing this record exists to prevent.

**On placement.** The rule is a discipline-named file of its own rather than a clause inside a shared agent-behaviour container. The Collective Review amendment moved the release's one-file constraint onto the surfacing index and expressly declined to grade clause placement, which removed the container's reason to exist. A category-named container would also have no boundary distinguishing what belongs in it from what does not, making it an unbounded surface; every one of the nine existing rules in that directory, including both authored earlier in this release, is named for a single discipline.

**Alternatives considered and rejected** (recorded so they are not re-litigated):

| Option | Disposition | Reason |
|---|---|---|
| Classify request intent at arrival and set a session-scoped analysis-only mode | **Rejected** | Fires where the failure is not — both instances parsed the request correctly — and fires on every turn, since every turn begins with an ask. Request intent is also not falsifiable for mixed asks, and a classification asserted once goes stale silently when the mandate changes mid-conversation. |
| Replicate the point fix into each read-only-declaring skill | **Rejected** | Seventeen further authorings of one rule, each a fresh source of truth and a fresh drift target, and it reaches none of the ad-hoc conversational turns where the second recorded instance occurred. This is the failure, not the fix. |
| Add a bullet to the charter's Universal Preferences list | **Rejected** | Out of scope by the card's own body, which names no charter surface. Independently: the charter has no mirror-pair entry, so the edit never reaches a running agent, and three of the four disciplines whose non-firing this release reports are already bullets there. |
| A pre-tool-use hook blocking a mutating tool while a read-only mode is active | **Deferred, not rejected** | The only real mechanical teeth, but the trigger is claim-shaped: a hook observes an edit, it cannot observe that the edit's authorization is the agent's own finding. The platform separately records the hook-deploy path and a subagent hook-bypass gap as open blockers. This is the same item the closed card scoped out and never filed; it is filed as a fast-follow this time rather than dropped twice. |
| Re-scope the shipped mode-scoped guardrail in place | **Rejected** | It would home a platform-general rule inside one release-module skill definition, unreachable whenever that skill is not loaded — inverting the source of truth. It also collides with an open pull request concurrently rewriting that file. |

## Consequences

**Positive.** One source of truth for one behaviour class, with a stated reason a third should not be authored. The trigger fires where the failure actually occurs and is falsifiable by a reviewer from the response text. Seventeen previously-unguarded declaring surfaces are covered without seventeen edits. The ad-hoc conversational turn is reached for the first time. And because the rule lives on the one corpus surface carrying a governed mirror contract, it can reach a running agent at all.

**Negative, stated plainly.** The teeth are governance-layer only until a hook layer ships. Enforcement is the agent honouring the checkpoint plus a reviewer scanning for the emitted token; nothing blocks the crossing mechanically.

**A second negative.** The two shipped point fixes remain in place and are cited rather than folded in, so three artifacts describe one behaviour class. That is deliberate — each point fix carries surface-specific detail — but it is real duplication, and the precedence clause is the only control preventing a fourth.

**A third, easy to misread as green.** The deploy check **detects** mirror drift; it does not **push** the mirror. Provisioning this rule into the workspace rules directory is an operator-side manual step, and until it is done the check emits a clean `SKIP` for the new pair. That `SKIP` is correct for a fresh checkout or a continuous-integration run and is **not** evidence the rule reached the running agent — asserting otherwise would be precisely the intermediate-signal promotion the sibling record exists to catch.

## Reversibility

**CHEAP / Confidence HIGH.** Every edit is additive: one new rule file, one appended index row, one appended mirror-pair entry in each of the two arrays that must hold identical path sets, and three enumeration cascades. No signature, path, enum, or schema is altered, and no consumer contract is broken. A revert of the release restores the prior state exactly and returns both mirror-pair arrays to their prior count.

## Related ADRs

- [ADR-112](ADR-112-decision-time-adherence-trigger-layer.md) — the decision-time adherence trigger layer. This rule is a consumer of its declaration contract; the checkpoint registered here is admitted by that contract's four-field gate rather than by author discretion.
- [ADR-094](../../release/ADRs/ADR-094-extend-before-create.md) — extend-before-create. The determination here is split: **extend** the adherence index, whose declaration contract is an explicit consumer seam; **create** the rule file, because a survey of every existing rule in that directory returned none governing agent response behaviour.
- [ADR-019](ADR-019-specialists-compose-not-absorb.md) — specialists compose rather than absorb. The cite-not-restate posture toward the two shipped point fixes is that principle applied to a general rule and its instances.
- [ADR-062](ADR-062-substrate-vs-canonical-precedent.md) — the substrate-versus-canonical precedent governing the translation of the card's deployed-mirror path reference back to its tracked corpus home.
- [ADR-030](ADR-030-hook-registry-drop-in-with-generated-index.md) — the hook registry, which would host the deferred mechanical-teeth layer once its two recorded blockers clear.
