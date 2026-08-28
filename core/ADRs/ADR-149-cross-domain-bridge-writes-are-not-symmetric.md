<!-- reference-durability: allow-link -->
---
title: "ADR-149 — Cross-domain bridge writes are not symmetric, and Tier-0 permanence attaches to a correctly-scoped item"
status: Accepted
date: 2026-08-24
release: hooks-block-their-declared-subject
deciders: "operator (Collective Review scope-lock) + Stage 5 Solutioning spoke (design verification, defect set, empirical placement spec) + Stage 6 Engineering spoke (build, measurement)"
tags: [block-autonomy-ceiling, autonomy-tiers, irreducible-human-tasks, layer-separation, tier-0, mode-gating, master-activation, operations-bridge, security-control-scope]
source_observations:
  - "The two domains are SIBLING directories, not nested. `${PRIMARY_ROOT}/pmo-platform` is a git repository and is public; `${PRIMARY_ROOT}/projects` is not a git repository and is not in the platform repo's path space at all — `git check-ignore ../projects` reports it as outside repository. Only one of the two directions can therefore put content anywhere it becomes committable."
  - "The rule fired on the wrong population. Across the block log's full window, BLOCK-AUTONOMY-002 fired 11 times over 5 dates; 10 of 11 were the low-risk direction and every one of those originated from a harness-created worktree rather than a deliberate boundary cross. Exactly 1 of 11 was the high-risk direction."
  - "That single high-risk firing raises the stakes on the retained direction rather than lowering them: the control has caught the disclosure-bearing case once, in real use, so the narrowed rule is asserted to block under all three .autonomy-mode values AND under master-OFF, which is stricter than the symmetric rule met other than by accident of sharing a branch."
  - "The override text named a remedy that does not operationally exist. 'Route the change through the owning agent' has no referent in a single-operator workspace, leaving CLAUDE_HOOK_BYPASS=1 — a whole-session disable of every security hook — as the only advertised escape from what is now a warn-class signal."
  - "No new mechanism was required. always_block (mode- and level-independent) and apply_block (mode-gated) already exist in the same file and are already exercised by -001 and -003 respectively. The change adds a member to an existing tier; it does not re-tier the hook."
  - "Naive placement of the new rule fails OPEN, and this was reproduced rather than reasoned about. The hook runs `set -euo pipefail`; target_domain and cwd_domain are assigned only inside the `case \"$TOOL_NAME\"` Write|Edit branch. A -004 condition reading either name below that branch aborts the hook with `unbound variable`, exit 1, on every Bash and every mcp call — the two highest-traffic matchers it declares. An aborted PreToolUse hook does not deny."
  - "The audit-trail claim does not hold under the shipped default. -004 sits below the master-activation gate and master-OFF is the shipped default (lib/master-enable.sh: a fresh clone with no XDG value reads 'off'), so on a default install the hook exits at the gate and -004 writes no warn row at all. Probed across the full 3-mode x 2-master matrix."
  - "The test suite's verdict depended on how it was invoked. Standalone it read 41 PASS / 5 FAIL; under test-runner.sh the same suite read 46 PASS / 0 FAIL, because the runner exports a master-ON config root and pins the scope root to '/'. Two independent harness defects — a HOME pin redirecting the master-activation read to a nonexistent file, and mcp/Bash payload builders hard-coding an out-of-tree cwd — were each masked by the runner and visible only standalone."
---

# ADR-149 — Cross-domain bridge writes are not symmetric

## Status

**Accepted.** Authored at Engineering for the `hooks-block-their-declared-subject` release, against the Stage 5 design verification and the operator's Collective Review scope-lock.

**Amends in part:** [ADR-031](ADR-031-autonomy-ceiling-unified-payload-triggered-hook.md), which records the hook's irreducible set as *"governance-file modification and cross-domain bridge writes"*. That second member is no longer a single class. ADR-031 is not superseded — its trigger design, its payload-over-session-detection decision, and its floor/ceiling architecture all stand unchanged, and this record is built entirely out of mechanisms ADR-031 established. Only the membership of the irreducible set is amended.

**Numbering provenance — `143 → 149`.** Held **ADR-143** branch-local; renumbered to **ADR-149** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 143. In-release citations that read "ADR-143" denote this record.

## Context

`BLOCK-AUTONOMY-002` treated the two cross-domain write directions as one symmetric rule and `always_block`ed both — mode-independent, level-independent, above the master-activation gate. The two directions do not carry the same risk.

The domains are **sibling directories, not nested**. `pmo-platform/` is a git repository and is public. `projects/` is not a git repository and is not in the platform repo's path space at all. So:

| Direction | What it does | Can it reach the tracked repo? |
|---|---|---|
| `projects` cwd → writes into `pmo-platform` | An Operations session writing into the **public git repo** | **Yes** — the content becomes committable and pushable |
| `pmo-platform` cwd → writes into `projects` | An Engineering checkout writing into the untracked sibling operations tree | **No** — git cannot see the target |

The first is a disclosure control. The second is a layer-ownership signal with no disclosure component whatsoever, and it was being enforced at the same irreducible severity.

The consequence was visible in the firing record, not merely predicted from it. `-002` fired 11 times; **10 of 11 were the low-risk direction**, and every one of those originated from the harness auto-creating a worktree at session launch rather than from any agent deliberately crossing a boundary. The rule's remedy text compounded it by naming *"route the change through the owning agent"* — a remedy with no referent in a single-operator workspace — which left a whole-session security-hook disable as the only advertised escape.

**One of the eleven was the high-risk direction.** That fact cuts the opposite way from the rest and is the reason this record narrows rather than relaxes: the disclosure-bearing direction is not hypothetical, the control has caught it in real use, and so the retained direction is held to a *stricter* bar here than the symmetric rule ever actually met.

## Decision

**Split item 7 of the irreducible-human-tasks set by direction, and re-tier one half.**

1. **`BLOCK-AUTONOMY-002` — retained, narrowed to `projects` → `pmo-platform`.** Still `always_block`: mode-independent, level-independent, evaluated above the master-activation gate. The condition names both domains explicitly rather than testing inequality, so that adding a third domain later cannot silently re-admit the direction this record removes.

2. **`BLOCK-AUTONOMY-004` — new, mode-gated, `pmo-platform` → `projects`.** Routed through the existing `apply_block`, so it honours `.autonomy-mode`: `warn` → warn-log + allow · `enforce` → block · `off` → allow. Placed below the master-activation and workspace-scope gates.

3. **`autonomy-tiers.md` item 7 becomes items 7 and 7a**, at Tier 0 and Tier 2 respectively, and the declaring surfaces follow it: `operations-bridge.md` (item 7's cited *Source rule*), `subagent-security-posture.md`, and the hook registry fragment.

4. **Both override strings rewritten** to name remedies that exist. `-004` names relaunching in the operations workspace; neither leads with `CLAUDE_HOOK_BYPASS`.

**No new mechanism.** `always_block` and `apply_block` already existed in the same file and were already exercised by `-001` and `-003`. This adds a member to an existing tier rather than re-tiering the hook.

## The permanence claim this narrows, and how it is reconciled

`autonomy-tiers.md` asserts that *"Tier 0 is permanent for the irreducible-human-tasks set regardless of approval state."* Re-tiering half of item 7 to Tier 2 sits directly against that sentence, and leaving both statements standing unreconciled would reproduce — inside the governing spec itself — exactly the declaration-versus-enforcement mismatch this milestone exists to eliminate.

The reconciliation is that **permanence attaches to a correctly-scoped item, not to an item's wording as first drafted.**

- What permanence forbids, absolutely: lowering a listed item out of Tier 0 by approval, standing authorization, `automation_level`, mode, or master-activation state. None of those can reach a Tier-0 item, and this record does not weaken that by any amount.
- What remains available: the prior question of whether an item is scoped to the acts its own rationale actually covers. Item 7's stated rationale was layer integrity, but the two directions it named have different risk, and only one of them can place content in a public repository. The item was over-scoped relative to its own justification.

The safeguard is in the difference between the two moves. Re-scoping is visible, reviewed, evidence-bearing, and lands an ADR. Lowering a correctly-scoped item is not an available move at all. Item 7 is now the worked example carried in the spec, so a future reader meets the distinction where the permanence claim is made rather than having to reconstruct it.

## Consequences

**The audit trail is real but conditional, and the condition is the shipped default.** `-004` sits below the master-activation gate, and master-OFF is what a fresh install reads. On such an instance `-004` contributes nothing — not a block, not a warn, not a log row. The honest statement of the deliverable is therefore *"the friction is removed unconditionally; the warn-trail exists where the operator has enabled the security-hook suite"* — not *"a complete audit trail"*. That qualification is now carried in the hook comment, in the registry fragment, and in item 7a, so the claim and the behaviour cannot drift apart again.

**`-004` is additionally session-scoped.** Sitting below the workspace-scope gate makes it inert for sessions rooted outside the governed tree. Correct for a layer-discipline signal — a session with no layer has no layer to discipline — but it means the scope gate no longer gates only the ceiling, and the comment asserting otherwise was corrected.

**`-004` short-circuits `-003` on this path.** `apply_block` exits in every mode branch, so a `-004` firing means the ceiling check never runs. The observable divergence is confined to enforce-mode with a permissive ceiling. That is the layer signal out-ranking the tier ceiling, which is the intended ordering.

**Tooling that counts `-002` firings will under-count after the split**, since the common case moves to a new id and, under the shipped default, to no log at all. Low impact: the historical population is 11 rows.

**A latent fail-open was closed as part of the placement, not discovered after it.** Reading the cross-domain locals below the `Write|Edit` branch under `set -u` aborts the hook on every Bash and mcp call. The two-line unconditional declaration that prevents this is load-bearing, is commented as such, and is pinned by a fixture that deletes the declaration in a sandbox and requires the arm to fail against it — so the guard cannot be quietly removed by a future tidy-up.

## Alternatives considered

**A1 — Allow the low-risk direction outright, with an audit row.** Removes the same friction. Rejected: it discards the layer-discipline signal permanently and offers no path back to enforcement. Mode-gating keeps the signal and keeps the operator's ability to tighten it by editing one file.

**A2 — A scoped operator sentinel, of the kind a prior proposal weighed.** Per-release sentinel scoping is warranted where the blast radius is the corpus itself. Rejected here: the target is an untracked sibling tree, so a sentinel is ceremony without a corresponding risk. (That proposal itself closed `NOT_PLANNED`, and neither hook copy carries its token — verified, so no collision.)

**A3 — Place `-004` in STEP 1, above the master gate, via `apply_block`.** This is the option that would have made the audit-trail claim true as originally written, and it was rejected on that merit rather than ignored. It would create the hook's only mode-gated rule above the master-activation gate — a fourth posture with no precedent in this hook or its siblings — and every existing placement comment in the file exists to protect the invariant that everything below the gate is master-gated. Paying a novel posture in a security hook to rescue a sentence was the wrong trade; the sentence was corrected instead.

**A4 — Re-scope the master gate's class for this rule.** Rejected: reaches into a shipped ADR's design and re-litigates it for a warn-class signal.

## Verification

Fixtures were written before the hook edit and failed against the unmodified hook (11 failing arms), which is what makes their subsequent passing meaningful.

The matrix asserts, in both directions and under every mode:

- `-002` blocks under `warn` / `enforce` / `off`, **and** under master-OFF — the retained direction survives every dial.
- `-004` blocks under `enforce`, warns-and-allows under `warn` **with an asserted warn-log append**, allows under `off`, and under master-OFF exits 0 **with no warn row** — the discriminating assertion for the conditional-trail consequence, since exit status alone cannot separate that case from the warn case.
- A governance target hits `-001` first in **both** directions.
- Same-domain writes and an empty-`cwd_domain` session are unaffected.
- Bash and mcp payloads with an in-workspace cwd exit 0, paired with a same-cwd Write that must fire `-004` — the control proving those allow-arms reach the evaluation point rather than being answered by a gate above it.

The suite's own harness was repaired in the same change, for a reason worth recording: its verdict depended on how it was invoked. Standalone it read 41 PASS / 5 FAIL; under `test-runner.sh` the identical suite read 46 PASS / 0 FAIL, because the runner exports a master-ON config root and pins the scope root to `/`. Two independent defects — a `HOME` pin redirecting the master-activation read to a nonexistent file, and payload builders hard-coding an out-of-tree `cwd` — were each masked by the runner. Both made a gate *above* the ceiling answer a question *about* the ceiling. A suite that passes under one invocation and fails under another is not a gate, and the fix makes the two agree.

## References

- Prior scoped-operator-sentinel proposal weighed and rejected in A2 (closed `NOT_PLANNED`; neither hook copy carries its token): `#3728`.
