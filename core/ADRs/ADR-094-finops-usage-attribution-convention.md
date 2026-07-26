<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-094 — FinOps usage attribution — session→work-item mapping convention, cross-file spoke linkage, and the unattributed bucket
status: Accepted
date: 2026-07-25
release: agent-finops-foundation (v3.94)
deciders: "Workspace owner (ratified D-AttributionConvention option A at the Stage-4 D-Gate, 2026-07-25; carried through the r2 Collective Review scope-lock with the operator ADJUST->lean directive, 2026-07-25). Design resolved at the C2 Stage-5 Solutioning (r1 + r2 revision)."
tags: [architecture, finops, token-spend, attribution, roll-up, work-item, hub-spoke, derived-cache, reversibility, deferred-scope]
source_observations:
  - "The C2 attribution/roll-up slice must map each usage session to its owning work item and roll per-session spend up to it, consuming the frozen v1.0.0 store from the C1 data-foundation slice. Session data lacks an explicit work-item linkage: git_branch is often a harness-auto claude/* name (unparseable), a release/chore name (milestone-only), or null."
  - "C2 Stage-5 Solutioning: this platform's hub-spoke model spawns spokes as SEPARATE session files, so the subagent->agent link crosses files. The roll-up does not need the spoke->hub parent link — it needs spoke->work-item, and both hub and spoke sessions attribute to the same work item."
  - "C2 r2 Collective Review (operator ADJUST->lean): an adversarial design review accepted six Major fixes. Load-bearing for this ADR: (a) no substrate join key reaches issue grain — the pipeline event log has no session_id/git_branch column and the hub sessions log has no work-item column, so reliable issue-grain is not deliverable from local data and is deferred; (b) the conservation identity is a tautology and cannot be the correctness proof; (c) a network gh call in the default resolver breaks the store's derived-cache determinism, so PR-resolve must be opt-in."
---

# ADR-094 — FinOps usage attribution: session→work-item mapping convention, cross-file spoke linkage, and the unattributed bucket

## Status

**Accepted.** Authored at the C2 Stage 6 per the Stage-6 ADR-authoring precedent (ADR-093 / ADR-031). This is the second of the two-ADR split for the agent-finops-foundation milestone: ADR-093 owns D-DataHome (where the store lives, what owns its schema, how git-ignore is enforced); this ADR owns D-AttributionConvention (how a session maps to a work item). The decision was ratified by the workspace owner at the Stage-4 D-Gate and carried through the r2 Collective Review scope-lock; the r2 revision sharpened the grain claim (milestone-reliable, issue-best-effort) and the correctness proof (ground-truth fixtures) without changing the decision's shape.

## Context

The roll-up phase needs a session→work-item map, but local session data carries no explicit work-item linkage. A session's `git_branch` is the primary attribution surface, and on this platform it is frequently a harness-auto `claude/<adjective-noun>` / `agent-*` name that does not parse to a work item, a `release/vX.Y-*` / `chore/vX.Y-stage-N-*` name that encodes only the **milestone** (not a sub-task), or `null` (legacy). Because hub-spawned spokes run as separate session files, the subagent→agent link crosses files, and — verified against the hub-state substrate — neither the pipeline event log (which has no `session_id` / `git_branch` column) nor the hub sessions log (which has no work-item column) carries a session↔work-item edge at issue grain. So the design must resolve what is resolvable, bucket the rest fail-visibly, and never claim a grain it cannot deliver. A further constraint: the store is a derived cache whose rebuild must be idempotent, so the default resolver cannot consult time-varying network state.

## Decision

1. **An ordered, first-match-wins, LOCAL-ONLY resolver** — issue-event key (best-effort issue-grain, from a local decision-event payload) → release/chore branch (reliable milestone-grain, the default workhorse) → hub-state lineage (milestone-grain corroboration via a worktree join) → `unattributed` (terminal, fail-visible). Every roll-up row carries an `attribution_tier` and a `reproducible` flag so a consumer can weight or exclude weaker tiers. A multi-branch guard sits above the resolver: a session whose source records spanned more than one branch is routed to a distinct `multi-branch` bucket, never collapsed onto one milestone.

2. **Milestone-grain is the reliable target; issue-grain is best-effort only where a deterministic key exists.** Broad reliable issue-grain, and a reliable hub-vs-spoke role split, both require a hub-emitted spawn-ledger marker (the hub logging each spoke's worktree / session id ↔ work item at spawn) and are **deferred to the downstream agent-finops-intelligence milestone**, out of this slice's file scope. A `fix/*` / `feat/*` → PR → closing-issue resolve is available but **opt-in** (a `--resolve-prs` flag); it touches the network, so it is off the default path, and every row it produces is stamped `pr-resolved` + `reproducible: false`.

3. **Cross-file spoke attribution targets the work item, not the parent link.** The roll-up sums `Σ session.tokens` over all sessions (hub and spoke) mapped to a work item, honoring the C1 summation invariant plus a named **count-once precondition** across the hub↔spoke file boundary. The subagent→agent hierarchy is not a correctness precondition, and no unreliable `by_role` split is emitted.

4. **Correctness is proven by ground-truth labeled fixtures, not conservation.** Each synthetic session fixture carries a known `(work_item, attribution_tier)` label the resolver must reproduce, tier by tier — the check a wrong resolver fails. The conservation identity (`Σ rollup == Σ session`) is retained only as a secondary plumbing guard, because it holds for any assignment (including routing everything to `unattributed`) and so proves nothing about attribution correctness.

5. **A run-level `coverage` record** carries the attribution-health metric (attributed-token fraction, per-tier distribution, milestone-vs-`unattributed` rates, a `health` enum). Its threshold is a provisional recommended default (no empirical distribution exists to calibrate against on a public repo) and is explicitly calibratable by the downstream calibration slice.

6. **The convention is codified** in `core/standards/finops-attribution-convention.md` (the mapping algorithm); the `rollup` + `coverage` record shapes live in `core/schemas/finops-usage-store-schema.md` at v1.1.0 (additive). The concern split — algorithm in the standard, shape in the schema — is deliberate.

## Alternatives Considered

- **Infer attribution purely from git / PR history** — rejected: needs `gh` (network, offline-fragile, non-reproducible), and still cannot attribute a harness-auto `claude/*` branch that references no work item. Retained only as the opt-in `--resolve-prs` enrichment, fenced off the default path.
- **Operator-manual session tagging** — rejected at Stage 4: not scalable, and it defeats the point of an automated roll-up.
- **The conservation identity as the correctness proof** (the r1 design) — rejected by the r2 review: it is a tautology (a resolver that mislabels every session still passes it). Replaced by the ground-truth labeled-fixture check, with conservation demoted to a secondary plumbing assertion.
- **Claiming reliable issue-grain from hub-state lineage** (the r1 design) — rejected by the r2 substrate re-verification: no substrate join key reaches issue grain, so the honest reliable target is milestone-grain, and reliable issue-grain is deferred to the hub-emitted spawn-ledger marker.

## Consequences

- **Positive:** safe-by-construction — the `unattributed` bucket never drops usage, and the convention never claims a grain it cannot deliver; it reuses the existing hub-state lineage substrate, so C2 adds no new session-tracking infrastructure; the roll-up is globally reconcilable (`Σ rollup`, including `unattributed` and `multi-branch`, equals `Σ session`); the local-only default preserves the store's derived-cache determinism (idempotent rebuild).
- **Negative:** attribution completeness depends on hub-state runtime presence and branch hygiene — a store with many harness-auto write-nothing sessions will show a high `unattributed` fraction (surfaced by the `coverage` health signal rather than hidden); deterministic issue-grain and a reliable role split are deferred to a future hub-emitted spawn-ledger marker.
- **Bounded residual:** the ground-truth threshold for `coverage.health` is a proposed default, not an empirically-grounded figure; it is flagged as calibratable rather than silently invented.

## Reversibility

**MODERATE / Confidence MEDIUM.** The attribution surface is additive net-new (the `rollup` + `coverage` records at schema v1.1.0, the convention standard, one new script) plus content-only edits; a single `git revert` of the release merge removes it, and the operator-local store is regenerated by re-extraction and re-roll-up. The MODERATE tier reflects that the convention is consumed by the downstream agent-finops-intelligence milestone (estimation, reporting, calibration); the `unattributed`-bucket safety and the additive-only extension are the mitigations. The MEDIUM confidence reflects that the mapping heuristic and the coverage threshold may need calibration once real usage data exists.

## Related ADRs

- ADR-093 — the sibling FinOps usage-store data-home ADR (the first of the two-ADR split for this milestone; same release branch). This ADR owns the attribution convention; ADR-093 owns the data home and schema authority.
- ADR-031 — autonomy-ceiling unified payload-triggered hook (the Stage-6 ADR-authoring + own-lifecycle precedent both FinOps ADRs follow).
