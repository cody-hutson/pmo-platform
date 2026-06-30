<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: Generated-artifact cleanup trigger surface — a new on-demand skill (/generated-cleanup), schedulable via the existing /schedule seam, distinct from the orphan-state cleanup script
status: Accepted
date: 2026-06-30
release: 20-records-management-naming-and-cleanup
deciders: "Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment, corrected post-A6.5) + operator at the Collective Review scope-lock"
tags: [generated-cleanup, trigger-surface, on-demand-skill, schedule-seam, conflation-boundary, autonomy-tier-1, reversibility-cheap]
---

# ADR-056 — Generated-artifact cleanup trigger surface

## Status

**Accepted** — scope-locked at the Collective Review (2026-06-30); the new `generated-cleanup` skill + this ADR land on the release branch + PR, with PR-review at Stage 9 as the dry-run gate (Claude Code path).

Number **056** — next gap-free above the branch max 055 (`artifact-name-segment-order`, this release's #369 spoke) and 054 (`records-classification-retention-model`, this release's #372 spoke); `find release/ADRs core/ADRs -name 'ADR-*.md'` reports 055 as the highest assigned at the authoring commit. Referenced by **slug** (`generated-cleanup-trigger-surface`), never by integer, so the number re-resolves if a concurrent release claims 056 first. Binds atomically at Stage 12.

## Context

The `08-Generated/` cleanup automation (#277) must scan the generated-artifact surface, group stale / superseded / approaching-timeout candidates, present a grouped summary, and execute only operator-approved archive actions — consuming the reconciled lifecycle states (`lifecycle_state` / `promotion_state`) and the `artifact-lint` report as inputs. The decision this ADR fixes is the **trigger surface**: where the cleanup behavior lives and how it is invoked. The decision is non-obvious (three live candidates surveyed) and carries a cross-cutting governance touch (an `OPERATIONS.md` protocol subsection + a per-skill output contract), which clears the ADR-warrant threshold.

**Three grounded trigger-surface candidates were surveyed:**

- **(A) A new on-demand skill** — `generated-cleanup`, invoked by name (`/generated-cleanup`) and schedulable via the **existing** `/schedule` seam. Mirrors the established on-demand artifact-surface skill pattern (`artifact-lint`, `health-check`): a skill that reads the surface, recommends, and stops at an approval gate.
- **(B) A `weekly-status-rollup` hook** — fold the cleanup scan into the weekly roll-up so it fires on the roll-up cadence.
- **(C) A standalone MCP scheduled task** — a bespoke scheduled-task carrier outside the skill surface.

The original framing also conflated the cleanup behavior with `cleanup-orphan-state.sh`, a **different tool** that removes orphaned git/runtime *state files* (hardened for SIGPIPE-at-scale in a prior release). The artifact-surface cleanup and the state-file cleanup operate on different object classes and must not be named alike or wired together — the grooming note on #277 raised this as a load-bearing CONFLATION FLAG.

## Decision

**Adopt Candidate A — a new `generated-cleanup` skill, invoked on demand as `/generated-cleanup` and schedulable through the existing `/schedule` seam. The skill is the artifact-surface cleanup authority and is explicitly distinct from `cleanup-orphan-state.sh` (the git/runtime state-file tool). It operates at Autonomy Tier 1 — Recommend: the operator approves every archive action unconditionally; a scheduled run writes a pending proposal and never self-applies.**

1. **Trigger surface = a new on-demand skill (`/generated-cleanup`), schedulable via `/schedule`.** The skill reads the generated surface, groups candidates, stages a proposal, and stops at the approval gate. Scheduling is delegated to the platform's existing `/schedule` seam — the skill does not mint a new scheduling mechanism. This matches the `artifact-lint` + `health-check` precedent (an on-demand surface skill that recommends and stops), which both verify exactly against this shape.

2. **The CONFLATION boundary is first-class.** `generated-cleanup` operates on the `08-Generated/` **artifact** surface (markdown + derivatives); `cleanup-orphan-state.sh` operates on orphaned git/runtime **state files**. The skill carries an explicit Conflation Boundary section and a HAND-category failure mode forbidding any recommendation that names or routes through `cleanup-orphan-state.sh`. The two share the word "cleanup," not a contract.

3. **Autonomy Tier 1 — unconditional approval gate.** No archive action — location sweep or content retirement — executes without explicit operator approval. A scheduled run produces a **pending proposal** the operator dispositions; it never moves or retires a file on its own. This is the same recommend-only posture `artifact-lint` runs under.

4. **Consume, do not re-implement.** The skill keys on the reconciled `lifecycle_state` / `promotion_state` fields (zero reads of the deprecated single-field machine), derives staleness the way the platform already detects it (the >30-day-unreferenced zombie-detection signal, recommend-only), and consumes the `artifact-lint` report as the source for superseded / version-chain candidates rather than re-deriving lineage. The lifecycle, lineage, and staleness logic already exist on-tree; `generated-cleanup` wires to those outputs.

## Alternatives considered

- **(B) A `weekly-status-rollup` hook** — rejected: folding cleanup into the roll-up couples an artifact-surface hygiene scan to a cross-project status cadence, denies the operator on-demand invocation (AC-1 requires a named, working on-demand trigger), and would force `weekly-status-rollup/SKILL.md` edits that the skill-mode choice avoids entirely (dissolving the soft contention with the #369 spoke). The roll-up's job is status synthesis, not surface mutation.
- **(C) A standalone MCP scheduled task** — eliminated on seam-fit: the platform already exposes a `/schedule` seam that any on-demand skill can register against, so a bespoke MCP scheduled-task carrier would duplicate scheduling infrastructure for no capability gain. Candidate A reuses the existing seam; C reinvents it.
- **Extending `cleanup-orphan-state.sh` to also sweep generated artifacts** — rejected on object-class grounds: that script removes orphaned git/runtime state files; teaching it to move/retire markdown artifacts would conflate two unrelated tools and risk a state-file cleanup the operator never intended. The CONFLATION FLAG names this explicitly. The artifact surface gets its own skill.

## Consequences

- A new skill `operations/skills/generated-cleanup/SKILL.md` ships as the artifact-surface cleanup authority, invoked `/generated-cleanup` and schedulable via `/schedule`; the trigger is documented in `core/governance/OPERATIONS.md` § Generated-Artifact Cleanup Protocol (AC-1).
- The skill composes with `artifact-generator` (the producer that stamps lifecycle/lineage/promotion fields and owns the Auto-Archive sweep) and `artifact-lint` (the lineage-graph inspector whose report it consumes) **by data contract**, not by runtime invocation — `generated-cleanup` never invokes either and is never auto-cascaded by them.
- The unconditional Tier-1 approval gate means a scheduled run is a proposal generator, never an autonomous mutator — the never-delete / always-recoverable guarantee and the operator-in-the-loop guarantee both hold for scheduled and on-demand runs alike.
- The CONFLATION boundary is enforced in the SKILL.md (Conflation Boundary section + HAND failure mode) and in this ADR, so a future reader cannot re-conflate the two cleanup tools.

## Reversibility

**CHEAP / Confidence HIGH.** The new skill, this ADR, the `OPERATIONS.md` protocol subsection, and the per-skill output-contract entry are each individually CHEAP to reverse (`git revert` the release PR; the skill is additive and invoked only on demand, so removing it strands no state). Confidence is HIGH that the on-demand-skill trigger surface is correct: it is the exact shape of the two live precedents (`artifact-lint`, `health-check`), it reuses rather than reinvents the `/schedule` seam, and it keeps the cleanup behavior at the recommend-only Autonomy Tier the surface-mutation risk demands. The CONFLATION boundary is HIGH-confidence (the two tools provably operate on different object classes — markdown artifacts vs. git/runtime state files).

## Related ADRs

- **ADR-054** (records classification + retention model) — sibling spoke in this same release (`20-records-management-naming-and-cleanup`); the records-management policy whose Transient-class disposition trigger is the `08-Generated/` 10-business-day Auto-Archive that this cleanup skill sits adjacent to (and does not duplicate). Precedent for the slug-referenced, integer-rebinds-at-Stage-12 ADR-numbering discipline used here.
- **ADR-055** (artifact-name segment order) — sibling spoke (#369) in this release; same numbering discipline (integer-binds-at-authoring, slug-referenced-forever).
- **ADR-036** (version-claim determinism) — the version token binds at Stage 12; consistent with this ADR's integer-binds-at-authoring / slug-referenced posture.
