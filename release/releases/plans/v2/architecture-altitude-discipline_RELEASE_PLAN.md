# Release Plan — architecture-altitude-discipline

**Milestone:** architecture-altitude-discipline (#223) · **Epic:** Architecture-Altitude Discipline
**Release Class:** cross-cutting (governance-doc-weighted)
**Version:** v2.17 (bump-class minor) — provisional-display; **claimed at merge** (slug-primary); re-verified by the Stage-12 atomic ref-CAS claim.
**Topology:** D-C SINGLE — one release branch `release/architecture-altitude-discipline`, one PR.
**Status:** Scope-locked at Collective Review (2026-06-21). This file is Engineering Commit 0; the working reference until it landed was the Stage-4 planning sub-task comment.

## Release Outcome Statement
**AFTER** — Every new capability is interrogated for its abstraction altitude (extend an existing platform seam, or solve point-wise?) as a **forcing function** at Stage 4/5 — not aspirational prose. A host-concrete point solution where a seam exists is caught at design time, not by the operator off-pipeline.
**BEFORE** — No forcing function interrogated abstraction altitude; the lift-up lived only as prose + memory + open intakes, so the version-claim design was framed tool-coupled until the operator caught it manually at Collective Review.

## Scope — 6 execution units + parent roll-up
| Unit | File(s) | Change |
|---|---|---|
| E1a (slice) | `core/standards/planning-solutioning-handoff.md` | Abstraction-altitude obligation as a rider on the §3 T3 trigger; fires at Stage 4, upstream of the estoppel. |
| E1b (slice) | `release/references/standards/design-exploration.md` | `altitude` 5th distinctness axis (point-fix / extend-seam / new-abstraction) + ≥2-band rule + altitude-diverging §6 worked example. |
| E1c (slice) | `release/references/templates/design-review-checklist.md` | New BLOCKING §4.7 seam-composition / abstraction-altitude check, wired into Section-4 Pass + Fail; AC#4 version-claim replay scenario. |
| E4 (story) | `core/disciplines/knowledge-architecture.md` (+ detector) | Register HOST-BINDING-LEAK §4 class; **plus a detector (AC#2, in-scope per Collective Review)** mirroring the path-portability gate, warn-mode-initial. |
| E2 (story) | `release/references/specs/release-personas.md`, `release/references/how-to/hub-spoke-bridge.md` | Scoped altitude exception in the A6.5 anti-pattern — advisory Premise-Altitude-Finding, no-autonomous-reversal guard; propagated through the adversarial chip discipline. |
| E3 (task) | `release/governance/release-process.md`, `release/references/pipeline/stage-12-execute.md` (non-version sites), `release/references/pipeline/stage-13-close.md` | `[adapters].repo_host` config-surface cross-reference at host-op sites (scope-corrected: version-op sites already cite the adapter). |

Parent story closes when its three slices close.

## Implementation Sequence (soft — single-branch serial; no hard file contention)
E1a -> E1b -> E1c -> E4 (class) -> E2 -> E3, then the E4 detector build last (it references the registered class).

## Stage Applicability
Stage 5 Solutioning **ACTIVATED** (Collective Review fired, >=2 units). Stages 7-8 **compressed** to a release-level verification pass (no functional code beyond the detector). Stage 9 Plan Review = the PR-review gate. Stage 12 Execute. Stage 13 Close.

## Contention Map
Near-zero. Only `hub-spoke-bridge.md` is shared — E2 edits one section, E1b only cites it (edit-vs-read). All units parallel-safe; executed hub-inline serially on the single branch. Cross-PR baseline (HEAD + the one open PR) had zero overlap with the nine files; re-check at Stage 9 + Stage 12.

## Collective Review scope-lock outcomes (2026-06-21)
- Consolidated altitude-discipline design locked as posted (5 specs + E3 omission-rationale).
- ADR: **CITE ADR-022** (Accepted; records the `[adapters]` seam) — no new ADR.
- E4 detector (AC#2): **IN-SCOPE** this release — built mirroring the path-portability gate, warn-mode-initial, handling 3 false-positive classes (prescribed-mechanism / adapter-documenting-its-binding / illustrative commands).
- A6.5 output-contract schema mirror in `stage-05-solutioning.md`: out-of-scope follow-up (logged, not built).

## Risk Register (all <= LOW residual)
- Self-contained E1c gate vs. the future evaluative-lens: inline forcing-function is correct standalone; a later edit binds the richer lens. CHEAP.
- E4 detector false-positives: warn-mode-initial + 3 FP-class handling + a self-test. CHEAP.
- Version slot drift: provisional v2.17 re-verified at the Stage-12 atomic claim. CHEAP pre-merge.
- Rollback: all changes additive governance-doc edits + one detector on independent files; whole release reverts via a single `git revert -m 1`. CHEAP.

## Engineering note
Stage 6 executed **hub-inline** (the Solutioning specs are implementation-ready exact insertions; the hub already operates in an isolated worktree, avoiding the spawned-spoke shared-branch cwd hazard). Stage 9 PR review is the independence/review gate.

### References
Work items: #1764 (parent), #1774, #1775, #1776, #1767, #1765, #1766. Planning sub-task: #1802. Solutioning sub-tasks: #1804, #1805, #1806, #1807, #1808, #1809. Decision record: ADR-022. Exemplar standard: `core/standards/repo-host-adapter-versioning.md`.
