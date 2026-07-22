<!-- reference-durability: allow-link -->
---
title: ADR-041 — Mid-Stage-5 cross-ticket scope detection keys on the Stage-4 Contention Map with a two-signal escalation threshold
status: Accepted
deciders: "operator + Collective Review scope-lock"
tags: [hub-spoke, solutioning, stage-05, cross-ticket-scope, contention-map, escalation-threshold]
---

# ADR-041 — Mid-Stage-5 cross-ticket scope detection

## Status

**Proposed.** Drafted at Solutioning for the cross-ticket scope-detection rule and materialized alongside the Stage 5 protocol section it governs. Flips to **Accepted** at the Collective Review scope-lock that ratifies the bundle.

## Context

A Stage 5 Solutioning spoke designs one ticket in isolation. When two sibling tickets in the same milestone unknowingly target the same surface, the overlap is discovered only after both spokes have built conflicting work — late, and expensive to unwind. A mid-spoke detection step can surface the coupling at design time, but it faces two design constraints:

1. **Stage 5 spokes write no files.** There is no working-tree diff to inspect for file overlap — the spoke is producing a specification, not edits. Any file-overlap signal must come from a source that exists at design time.
2. **High-traffic shared files generate false positives.** Some files (the hub-spoke bridge reference, a release plan, an alphabetical registry) are touched by nearly every spoke. A naive "do our file sets intersect?" test fires on these constantly, training the operator to ignore the signal.

A detection rule that ignores either constraint is either inoperable (no diff to read) or noisy (fires on every shared high-traffic file).

## Decision

Mid-Stage-5 cross-ticket scope detection uses the **Stage-4 Contention Map** — not a live spoke diff — as the file-overlap source, and **escalates only on a two-signal-or-strong-single-signal threshold**, to bound false positives on shared high-traffic files.

1. **File-overlap source = the Stage-4 Contention Map.** The Contention Map already enumerates, per ticket, the concrete files each ticket touches; it is produced at Planning and is available at Stage 5 entry. The spoke compares its own File Change Matrix against that map rather than against a non-existent working-tree diff. This is a read of an existing planning artifact, not new physicalization.

2. **Two-signal-or-strong-single escalation threshold.** Escalate only when a *strong* signal holds: a file-overlap on a non-append-pattern file (a file where two writers genuinely collide, as opposed to an append-only surface where concurrent additions merge cleanly), AND/OR a sibling sharing at least one concrete path. A single *weak* signal — a semantic resemblance with no shared concrete file, or an overlap confined to an append-pattern file — is logged in the spoke output, not escalated. A file that every spoke touches is not, by itself, evidence of a cross-ticket collision.

3. **Detection routes, it does not self-authorize.** On a positive detection the spoke posts a Tier 2 scope-change finding to the hub before the release-level Collective Review. The spoke does not merge, split, or re-scope on its own authority; the hub renders the disposition (expand-scope-now vs hold-for-Collective-Review) at its receiving handler, and the operator approves.

4. **Reflexive cutover.** The rule cannot fire on the release that ships it (the introducing release's own Stage 5 authoring is exempt), avoiding a reflexive-pipeline loop.

## Consequences

### Positive

- The detection is operable at Stage 5 — it reads a planning artifact that exists, rather than a diff that does not.
- The two-signal bar keeps the signal trustworthy: it does not fire on the high-traffic files every spoke shares, so an escalation means something.
- Detection is decoupled from disposition — the spoke surfaces, the hub and operator decide — preserving the spoke's no-self-authorization boundary.
- The rule is additive: it adds a conditional phase to Stage 5 and a receiving handler to the bridge, with no change to existing phases.

### Negative / cost

- The detection is only as good as the Stage-4 Contention Map. A path the map omits is invisible to the file-overlap heuristic (the semantic-similarity heuristic is the partial backstop).
- The append-pattern-file judgment is a heuristic the spoke must apply, not a mechanical test — a misjudged append surface either over- or under-escalates.

## Alternatives rejected

| Option | Decision | Rationale |
|---|---|---|
| **Live-worktree-diff as the file-overlap source** | Rejected | Stage 5 spokes write no files, so there is no diff to read — the source does not exist at design time. The Contention Map is the artifact that carries the per-ticket file sets at Stage 5 entry. |
| **Single-signal escalation (any file-set intersection escalates)** | Rejected | Fires on every high-traffic shared file, producing alert fatigue that trains the operator to ignore the signal; the two-signal bar is what makes a positive meaningful. |
| **Spoke self-authorizes the merge/split on detection** | Rejected | Crosses the spoke's no-self-authorization boundary — a scope change is an operator-rendered disposition; the spoke routes a finding, it does not act on it. |

## Reversibility

**CHEAP / Confidence HIGH.** The rule is an additive conditional phase plus a receiving handler; removing or re-tuning the threshold is a documentation edit with no migration. The threshold can be re-calibrated against observed false-positive rates with operator approval.

## Provenance

This decision was sliced into the Stage 6 Engineering work for the hub-spoke-orchestration-discipline milestone and records the kernel the Stage 5 Phase 0.7 protocol section and the bridge escalation handler implement. The detection heuristics and the escalation threshold were settled at Solutioning and scope-locked at Collective Review.
