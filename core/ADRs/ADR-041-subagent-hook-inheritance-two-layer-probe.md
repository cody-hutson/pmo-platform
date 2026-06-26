<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-041 — Subagent hook-inheritance is verified by a two-layer probe (CI logic-regression + manual live-delivery procedure), not a single CI suite
status: Accepted
deciders: Workspace owner
tags: [architecture, security, hooks, subagent, testing, empirical-verification, pretooluse]
source_observations:
  - "subagent-security-posture.md § 3 Mechanism 2 marks the harness-delivery claim LOGICAL-INFERRED-UNTIL-EMPIRICALLY-TESTED and prescribes a 'Stage 7 DT regression suite' as a single follow-up — but a subagent cannot observe its own hook interception (the hook fires in the harness layer, between the tool call and the tool_result), so a self-contained CI suite cannot assert live delivery."
  - "The PreToolUse hooks read only the tool-call payload from stdin (no session_id / parent_session / subagent_type), so a payload a hook blocks from a parent it blocks from a subagent by construction — the part a CI logic-regression CAN assert deterministically."
  - "#1472 (PreToolUse hooks wired at workspace root only; do not load for repo/worktree sessions) means a spoke — which runs in a worktree — may not fire hooks at all, an enforcement gap a logic-regression cannot see and only a live worktree-session probe surfaces."
---

# ADR-041 — Subagent hook-inheritance: two-layer probe, not a single CI suite

## Status

**Accepted.** This ADR records the verification model for the subagent
hook-inheritance and frontmatter-enforcement claims in
[`subagent-security-posture.md`](../standards/subagent-security-posture.md) § 1 /
§ 3 Mechanism 2. It references issues as bare `#N` under the file-level
`allow-issue-ref` marker above.

## Context

`subagent-security-posture.md` § 3 Mechanism 2 holds that subagent tool calls
fire the same PreToolUse hooks as parent-session calls — but flags the claim as
`LOGICAL-INFERRED-UNTIL-EMPIRICALLY-TESTED` and prescribes a single "Stage 7 DT
regression suite" to discharge it. That single-suite framing does not survive
contact with two facts:

1. **A subagent cannot observe its own hook interception.** The hook fires in the
   harness layer, between the tool call and the tool_result the subagent receives.
   The subagent sees a result (success/failure), not the interception event. And
   CI has no subagent-spawning harness. So a self-contained, in-process test
   cannot assert that the *live harness delivers* a subagent's tool calls to the
   hooks. That half is observable only by an operator driving a real spawn and
   reading the hooks' side-channel (`block-log.jsonl`).
2. **The claim has two separable parts with different testability.** Hook *logic*
   firing on a subagent-shaped payload IS deterministically CI-testable — the
   hooks read only the tool-call payload from stdin and have no notion of caller
   class, so a payload a hook blocks from a parent it blocks from a subagent by
   construction. Hook *delivery* (and worktree *wiring* — #1472) is not.

A single all-in-CI suite would therefore either **over-claim** (assert "subagent
calls are blocked" while only proving the payload logic, masking the unverified
delivery + the #1472 worktree gap) or be **impossible** (a CI job cannot spawn a
subagent and observe its own interception). Both failure modes are worse than an
honest split.

## Decision

**Verify subagent hook-inheritance with a TWO-LAYER probe, not a single CI suite:**

1. **Layer A — deterministic CI logic-regression.**
   `core/hooks/tests/subagent-hook-inheritance.test.sh` pipes synthetic
   subagent-shaped JSON payloads to each of the 6 most-relevant `block-*.sh`
   hooks and asserts the block/warn outcome by rule id + exit code. It is
   auto-discovered by `test-runner.sh` and gated by the `install-tests` hook-tests
   CI job. It proves hook **LOGIC** fires on subagent-shaped payloads — and
   regression-guards it — but explicitly does **not** prove live delivery or
   worktree wiring (a header guard banner states this).
2. **Layer B — manual operator-run live-delivery procedure.**
   `core/hooks/tests/subagent-hook-inheritance-probe.md` is a runnable operator
   procedure (NOT CI) that spawns a real subagent attempting always-enforce
   triggers, reads the interception from `block-log.jsonl`, repeats from a
   **worktree** session (the #1472 exercise), adds the Mechanism-1 frontmatter
   `tools:` probe, and records a results matrix. Its verdict selects the
   `subagent-security-posture.md` § 1 / § 3 reconcile branch.

The two layers are complementary, not redundant: Layer A owns the
deterministic-and-regressable half; Layer B owns the harness-delivery +
worktree-wiring half that no CI job can assert. A claim of "subagent calls are
enforced" is honest only when both are accounted for.

**#1472-blocker posture.** If the Layer-B probe records that hooks fire at
workspace-root but NOT in a worktree session, that is the #1472-predicted outcome
and a *finding to record, not a test to make pass*: **#1472 (PreToolUse hooks
wired at workspace root only) is the named blocker on real Mechanism-2 enforcement
of a spoke**, because a spoke executes in a worktree. The posture doc carries both
a delivery-confirmed (Branch V) and a worktree-gap (Branch G) qualifier; the
operator selects from the recorded verdict at Stage 7/8.

**Rejected alternative — a single all-in-CI empirical suite.** Rejected because it
cannot discharge the live-delivery claim (a subagent cannot observe its own
interception; CI has no subagent-spawning harness) and would therefore either
over-claim coverage it does not have or be impossible to write. Folding the
worktree-wiring question into CI is the same trap — #1472 is a harness-wiring
property no in-process logic test can observe. The honest split (CI for the
deterministic logic; an operator probe for live delivery + worktree wiring) is the
only model that neither over-claims nor omits the #1472 gap.

## Consequences

- **The deterministic half is regression-guarded forever.** Any future change that
  breaks a hook's block-on-subagent-payload logic reddens the `install-tests`
  hook-tests job via Layer A.
- **The non-deterministic half has a standing, runnable re-test.** Layer B is the
  documented procedure to re-verify live delivery + the worktree gap — in
  particular, the re-test to run when #1472 lands.
- **The posture doc never over-claims.** § 3 Mechanism 2 reconciles to EITHER
  EMPIRICALLY-VERIFIED (Branch V) or a DOCUMENTED RESIDUAL GAP with #1472 named as
  the blocker (Branch G), chosen from the recorded Layer-B verdict — not a blanket
  "verified".
- **No new enforcement gate ships.** This ADR governs *verification*, not
  enforcement; it adds tests + a procedure + a doc reconcile, all CHEAP to revert.

## Reversibility

**CHEAP.** The decision adds a CI regression test, an operator-run probe doc, and a
surgical reconcile of two qualifier lines + one version-history row in
`subagent-security-posture.md` — reverting the release PR removes all of it with
no data loss and no enforcement change.

## Related ADRs

- **ADR-031** (autonomy-ceiling — unified payload-triggered hook) — pairs with this
  ADR: ADR-031 established that the hooks trigger on the **tool-call payload**, not
  session context (the very property that makes Layer A's payload-logic regression
  valid and a session-detection approach infeasible). This ADR is the verification
  complement — it proves, layer-appropriately, that the payload-triggered hooks
  reach subagent calls (Layer A logic; Layer B delivery), and names #1472 as the
  worktree-delivery blocker ADR-031's enforcement model inherits.

## References

- Empirical-verification residual scope (the card this discharges): `#189`.
- Worktree hook-load blocker on real Mechanism-2 spoke enforcement: `#1472`.
- Posture doc reconciled by the Layer-B verdict: `core/standards/subagent-security-posture.md` § 1 + § 3 Mechanism 2.
- Layer A regression: `core/hooks/tests/subagent-hook-inheritance.test.sh`. Layer B probe: `core/hooks/tests/subagent-hook-inheritance-probe.md`.
- Payload-trigger precedent + enforcement model this verifies: ADR-031.
