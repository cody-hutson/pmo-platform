---
title: "ADR-079 — Hub-owned sub-task close (spoke posts output; hub closes)"
status: Accepted
date: 2026-07-11
release: 98-pipeline-freshness-and-spoke-safety (v3.70 provisional; bound at Stage 12)
deciders: "Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) flagged the ADR; Stage 6 Engineering authored it; operator ratifies at the Stage 9 plan-review gate"
tags: [release-ops, hub-spoke, sub-task-lifecycle, close-ownership, security, authorized-close, guardrail-false-positive, external-write, lifecycle-ownership]
source_observations:
  - "A hub-spawned spoke closing the hub-created tracking sub-task it was explicitly instructed to close (the prescribed Procedure-3 behavior) trips an external-write SECURITY WARNING — the harness sees only 'closed an issue I did not create'. The warning fired on every spoke completion, adding routine review overhead with no security value (the close was authorized). Live instances: milestone-35 Stage 4 #1282 / Stage 5 #1298."
  - "The trigger is the spoke's close ACTION, not any content. An in-git authorization marker in the spoke prompt cannot reach the emitter — the warning is harness-level (out-of-git); hub verification located zero core/hooks or .claude/hooks file emitting it, so no in-repo marker or doc note can suppress it. Only removing the spoke's close action removes the trigger."
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->

# ADR-079 — Hub-owned sub-task close (spoke posts output; hub closes)

## Status

**Accepted** — authored at Stage 6 Engineering; ratified at the operator's Stage 9 plan-review gate. The Accepted flip is verified against this file's `status:` field, never assumed from milestone closure.

## Context

The hub-spoke release bridge tracks each stage's work as a GitHub sub-task the **hub** creates at scaffolding (Procedure 1). Under the prior convention the **spoke** closed its own hub-created sub-task on completion (the prescribed Procedure-3 behavior, restated across Procedures 0/1/3/4, the Return-Value `sub-task:` state enum, Procedure 4a, and the Tracking section).

That convention has a persistent cost: when a spoke closes an issue it did not create, the harness emits an external-write SECURITY WARNING — it sees only "closed an issue I did not create" and cannot tell an authorized hub-instructed close from an unauthorized one. The warning fires on **every** spoke completion, adding routine review overhead with zero security value, because the close was authorized by construction (#1342).

The trigger is the spoke's close **action**, not its content. The warning is emitted at the harness layer (out-of-git); hub verification found no `core/hooks/` or `.claude/hooks/` file emitting it, so no in-repo authorization marker or documentation note can reach the emitter. This rules out any resolution that annotates around the close while leaving the close with the spoke.

This decision is the close-ownership half of #2215 (hub-spoke write-authorization safety). The sibling half — the read-only-write-prohibition clause that stops a read-only spoke from acting on cross-issue writes (#1888) — is a straightforward prompt-clause addition that composes with the existing security posture and does not need its own ADR; it is recorded inline in `hub-spoke-bridge.md` Procedure 3.

## Decision

**The hub owns the sub-task close. The spoke posts its output and returns; it never closes its own sub-task.**

1. **Spoke behavior.** On success the spoke posts its output comment and returns the Return-Value state `output-posted` (renamed from `closed`); on a blocker it leaves the sub-task OPEN and returns `open-blocker`. The spoke performs no close under any path.
2. **Hub behavior.** The hub closes each `output-posted` sub-task in Procedure 4 Step 2, **after** consuming the spoke's output (Step 1). A hub-close is "closing an issue I created" (the hub created the sub-task at Procedure 1), so the harness warning has nothing to fire on — the trigger is removed **in-git**, with no harness change. A sub-task returned `open-blocker` stays OPEN and the blocker is surfaced to the operator.
3. **Scope of the reversal.** The change is universal — it applies to every spoke, read-only and write-capable, because the #1342 warning fires on any spoke that closes a hub-created sub-task. It is expressed in one file (`hub-spoke-bridge.md`) as a ~12-row cascade across Procedures 0/1/3/4, the Return-Value schema + enum + worked example, Procedure 4a, and the Tracking section.
4. **Return-Value enum canonicalization.** The `sub-task:` state enum member `closed` becomes `output-posted` — it names the spoke's actual terminal action, parallels the existing compound-adjective `open-blocker`, does not imply the spoke closed anything, and is neutral about hub-close timing.
5. **Gate sub-tasks are unaffected.** Stage 9 / Stage 12 gates run hub-direct with no spoke (Procedure 5); the hub already closes those gate sub-tasks. The prior wording that attributed a gate close partly to "the spoke's verdict closure" (Procedure 4 § Spoke drafts the next chip) is corrected to hub-closes, but no behavior at the gate changes.

## Alternatives Considered

- **(b) Recognizable authorization marker in the spoke prompt** — rejected: the warning is emitted on the close action at the harness layer, which does not parse the in-git prompt for a marker. Recognizing a marker would require an out-of-git harness change; the resolution would no longer be in-git and would carry its own operator-approval surface.
- **(c) Document the authorized-close pattern as "expected" so reviewers fast-clear it** — rejected: the warning still fires on every spoke completion; only the review *cost* drops. This fails the #2215 acceptance criterion "the authorized-close path no longer produces a routine security warning."
- **(a) Hub closes the sub-task itself — CHOSEN**: the only option that removes the *trigger* (the spoke's close action) rather than annotating around it, and the only one expressible entirely in-git. It also matches #1342's own "what good looks like" (the hub closes sub-tasks itself after consuming spoke output).

## Consequences

- The authorized-close false-positive is removed in-git — no harness change, no `.claude/hooks/` edit; the warning stops because its trigger (a spoke closing an issue it did not create) no longer occurs.
- Close ownership is single-owner: the prior spoke-closes / hub-verifies split collapses into hub-closes-on-consumption. Procedure 4 Step 2 changes from "verify sub-task(s) are closed" to "close each `output-posted` sub-task after consuming its output."
- The change composes with the read-only-write-prohibition clause (the other half of #2215): a read-only spoke never closes any issue — including its own assigned sub-task — which is exactly what hub-owned close guarantees.
- A spoke's own-sub-task **output comment** remains the spoke's one authorized write; only the **close** moves to the hub. The Session-Start-Checklist "sub-task is OPEN" precondition still holds — the sub-task stays open through the spoke's run and is closed by the hub afterward.
- Release-close verification (Procedure 7: "verify all sub-tasks closed") is unchanged and becomes more consistent — it asserts closed *state*, not *who* closed.
- Cutover: the introducing release (this one) is exempt per reflexive-pipeline-loop discipline — its own hub is already dogfooding hub-owned close during this run, which is expected; the exemption means the release is not audited against a convention it is simultaneously introducing. The convention binds for releases entering the pipeline strictly after this release's introducing merge SHA.

## Reversibility

CHEAP / Confidence HIGH — single-file documentation + behavior edits; `git revert` of the release PR restores the prior spoke-closes convention. No data or state migration; no harness change to unwind.

## Related ADRs

- ADR-076 — comment author-association trust boundary at the pipeline's comment-I/O seam — the nearest neighbor: both govern the hub-spoke pipeline's GitHub write surface. ADR-076 gates *inbound* comment trust; this ADR relocates *outbound* sub-task-close ownership. Neither supersedes the other; they compose at the comment/issue-write seam.

### Issue References

- Parent improvement: #2215 (hub-spoke write-authorization safety — this ADR resolves the authorized-close half).
- Source observations: #1342 (authorized sub-task close trips the guardrail) and #1888 (read-only spokes can self-act — the sibling half, resolved by the Procedure-3 read-only-write-prohibition clause, not this ADR).
- Referenced constraint: #1472 (worktree-session hook-loading untested) — the design's rationale for why the resolution stays doc/behavior-level and does not depend on a PreToolUse hook.

## References

- #3368 — the Stage 5 Solutioning design (Principal Engineer — Architecture Assessment) that flagged this ADR.
