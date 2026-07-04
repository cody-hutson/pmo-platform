---
title: "ADR-076 — Comment author-association trust boundary at the pipeline's comment-I/O seam"
status: Accepted
date: 2026-07-04
release: 109-comment-trust-boundary (v3.65.1; bound at Stage 12)
deciders: "operator (plan approval / Stage 9 gate) + Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment)"
tags: [release-ops, security, prompt-injection, trust-boundary, comment-channel, stage-io, moderation, lock-at-close]
source_observations:
  - "An external no-association account posted an unsolicited package-install recommendation inside an active stage sub-task thread during a live release run, positioned exactly where downstream stage readers consume stage output. No incorporation occurred (verified via history search + PR file-list); the comment was later removed — the benign outcome was positional luck, not a control, and the removal itself demonstrates the deletion-destroys-evidence risk this decision's moderation posture addresses. The recorded evidence text in the originating improvement issue's Evidence section is the durable fixture."
---
<!-- reference-durability: allow-version-ref -->

# ADR-076 — Comment author-association trust boundary at the pipeline's comment-I/O seam

## Status

Accepted — ratified at the operator's Stage 9 plan-review gate (2026-07-04); the flip is verified against this file's `status:` field, never assumed from milestone closure.

## Context

The hub-spoke pipeline uses issue/PR comment threads as its stage-I/O channel: sub-tasks instruct spokes to post stage output as thread comments, and the hub + downstream stages read those threads as pipeline content. The repository is public — any account can comment at zero cost — and no rule in the corpus distinguished comments by author association (verified: zero `authorAssociation` references repo-wide). The Inter-Stage Feedback Protocol tiered arriving feedback by change-nature only, and two files asserted that in single-operator steady state "no review comments arrive" — a falsified dormancy claim on a public repository.

## Decision

1. **Author gate before classification.** Comments authored outside the trusted set — the host's `OWNER` / `MEMBER` / `COLLABORATOR` associations — are never stage content, instructions, requirements, or evidence for any pipeline reader; they are surfaced to the operator as untrusted third-party content and excluded from stage reasoning. The gate keys on repository relationship, never on content plausibility. Trusted-set precision: on this user-owned repository `OWNER` and `COLLABORATOR` are the write-bearing associations; `MEMBER` is an organization-membership relationship (not necessarily a write grant — an org member's base permission can be read or none) and is included as a **deliberate forward trust statement** for a possible future org migration, not as a claim that it is write-bearing today. This is not a zero-cost widening: the trusted set MUST be re-examined at any org migration, because `MEMBER` would then silently admit accounts whose write access was never granted (and the catalog `drift_check_protocol`, keyed on enum-value changes, would not catch it — no enum value changes).
2. **Canonical home = the Inter-Stage Feedback Protocol** (`release/governance/release-process.md`), extending the tier-by-change-nature mechanism with an author dimension (gate precedes tier-mapping). Operational procedure at `hub-spoke-bridge.md` (named section + sub-task template + spoke chip template + Procedure 4); one-line citations at the comment-consuming stage shards (Solutioning, Dev Testing, QA, Plan Review). The rules layer is not touched.
3. **Lock-at-close** ships as a manual Stage 13 checklist step (Phase C5) on the repo-host adapter seam — abstract thread-lock/unlock; `gh issue lock --reason resolved` as the GitHub-adapter binding. The sweep locks finished sub-task threads and the delivery card. Non-blocking for Milestone close initially.
4. **Moderation posture:** evidence-preserving — minimize-as-spam + lock over deletion. Evidence capture of untrusted content is descriptive or clearly quarantined, never inline verbatim prose in a trusted-authored artifact (a verbatim quotation re-arms the instruction, because the gate keys on the quoting author's association).
5. **Out of enforced scope:** repo interaction limits (decaying host control, silent expiry, no in-pipeline renewal owner) remain operator host-policy. New-issue *bodies* authored by external accounts at intake/triage — including the auto-applied `status: proposed` routing and the triage native-dependency mirror — are a distinct untrusted-ingestion surface NOT governed by this boundary; routed as a follow-up improvement (tracked in the release plan).

## Alternatives Considered

- **Canonical home in `core/rules/git-workflow.md`** — rejected: the file codifies git workflow and contains no thread-reading procedure; a pipeline ingestion rule there couples an unrelated surface and crosses the core↔release module boundary.
- **Canonical home in `hub-spoke-bridge.md`** — rejected: inverts the knowledge hierarchy (authoritative governance citing a how-to for a protocol-gating rule).
- **New universal rule file in `core/`** — rejected on the reuse-first bar (necessary, not plausible): every evidenced reader of the channel is a pipeline reader; a future generalization can lift the canonical block at CHEAP cost.
- **Lock-at-close via a host workflow (auto-lock on close)** — rejected for this release: a workflow file is a separate governed change with its own intake and raises rollback CHEAP → MODERATE (live CI state). Upgrade path: fold into the automated close-out tooling after the manual step proves reliable across N≥2 releases.
- **Per-spoke lock at each sub-task close** — rejected: many touched surfaces for marginal gain (mid-release locks block only non-collaborators, whom the boundary already excludes); the Stage-13 sweep covers all threads from one surface.

## Consequences

- Every pipeline thread reader inherits one rule from one canonical block; a future arrival channel adds a citation, not a mechanism.
- The single-operator no-op claims are scoped to trusted-reviewer traffic — the channel is never assumed empty; stage files no longer contradict the boundary.
- Untrusted content stays operator-visible (surfacing notice); the public intake surface stays open — outside reports route to issue templates as new issues.
- Finished sub-task threads and delivery cards are locked at release close; locks are host-state with a documented unlock inverse (a PR revert does not unlock).
- A trusted-set change (e.g. an org migration populating `MEMBER` accounts) is a one-line canonical edit — but is a deliberate re-examination point, not an automatic widening (see Decision 1).

## Reversibility

CHEAP / Confidence HIGH — text reverts with the release PR; locks revert via the adapter's thread-unlock per thread.

## Related ADRs

- ADR-062 — substrate-vs-canonical precedent (issue bodies remain historical record) — consumed by this design's reconciliation posture.

### Issue References

- Parent improvement: #3261 (author-association trust boundary; evidence instance recorded in its Evidence section)
