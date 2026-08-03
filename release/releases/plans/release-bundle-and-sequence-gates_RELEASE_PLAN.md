<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Release Plan — release-bundle-and-sequence-gates

> **Milestone:** `release-bundle-and-sequence-gates` (#299) · **Release Class:** `cross-cutting` (capacity weight 1.3) · **Version:** `v4.06` *provisional* *(bump-class `minor`; re-verified at Engineering Commit 0 — see § Commit-0 Version Re-Verify; the concrete number is claimed atomically at the Stage-12 merge tag per the two-phase allocation, so this plan file and its branch stay **slug-primary** until then, per ADR-092)* · **Scope:** 6 issues · 26 raw pts / 34 effective · One release branch, one PR, one merge gate (D-C **SINGLE**, D-Concurrency **P0 fully-serial**).

This plan is the Stage-4 release plan (rendered on sub-task #4508, approved at the Procedure 0 gate 2026-08-02 Sunday) written to disk as **Engineering Commit 0** by the first Stage-6 spoke, reconciled against the six Stage-5 Solutioning outputs consumed at the Collective Review scope-lock and against live mainline state at Commit 0. Deltas discovered between plan approval and Commit 0 are folded into the § Deviation Log rather than silently applied.

## Summary (30 seconds)

Six issues, one theme: **Stage-3 bundling and Stage-4 planning entry each validate their own inputs.** After this release a milestone's composition is closed once it enters Stage 4, the bundler re-validates its own claim at bundle time, the planner's priority tie-breaker actually executes, sequencing mode is selected from dependency density rather than assumed, Phase A0 consumes the Mode R briefing instead of re-deriving it, and release scaffolding produces the gate-stage sub-tasks the close-out depends on.

- **Dependency graph is genuinely flat** — **2 directed edges over 6 nodes** (1 hard, 1 soft), and both edges are *also* the only two file-contention edges. Engineering runs serial on one branch in 6 slices; Stages 5/7/8 run as **two parallel waves of 4 + 2**.
- **The pinned baseline moved before Engineering started.** `release/governance-hardening` (#290) **merged to `main`** as `39284a2d` after Stage-5 exit. This is the exact G-PR9 event the plan predicted; it is **resolved by construction** — the release branch is cut from post-merge `main`, so the two recorded contention rows are absorbed rather than mitigated. See § Deviation Log **DEV-1**.
- **That merge invalidated three slices' ADR allocations.** It landed ADR-105 (release) and ADR-106..109 (core). #3581 had specified ADR-107, #3817 and #2719 had each specified ADR-105 — all three now collide. Next-free at Commit 0 is **ADR-110**. See § Deviation Log **DEV-2** and § ADR Allocation.
- **#3581's slice grew from 4 files to 5** at Stage-5 Revision 1 (operator-accepted R-6): the composition-lock boundary is now *emitted* at Procedure 0 Step 5, not only inferred from a probe. Release Class trigger (b) consequently counts **4** governance surfaces instead of 3 — `cross-cutting` is strictly reinforced and the Stage-4 **R-5 re-classification trigger does not fire**.
- **Stage 5 added two acceptance criteria to #3581** (AC7, AC8) as Tier-1 `[ADJUST]`s at the A6.5 adversarial briefing, closing a cross-table-consistency gap no pre-existing AC could catch.
- **Quota Budget: WARN** — worst parallel batch 4 post-split. **Rollback: MODERATE** whole-release (the diff reverts trivially; the protocol *semantics* do not).

## Commit-0 Version Re-Verify

Run at Engineering Commit 0 on 2026-08-03 (Sunday) per the release-identity two-phase binding discipline. `v4.06` was rule-computed as provisional at Stage 4 (bump-class `minor`, anchor `v4.05`). This re-verify is the **first detection rung**; the Stage-12 atomic claim is the resolving authority. Protocol is **detect-and-HALT, no auto-retry** — a collision here stops Engineering and returns D-Version to the operator.

**Method.** `git fetch --tags origin && git fetch origin main`, then each arm of the claimed set evaluated independently against `origin/main`. Ledger input read via `git show origin/main:<path>`, never the worktree copy.

| Claimed-set arm | Probe | Result |
|---|---|---|
| Origin tags | `git ls-remote --tags origin` | highest = `v4.05`; **no `v4.06`** |
| Published GitHub Releases | `gh release list` | highest = `v4.05` (2026-08-02); **no `v4.06`** |
| Mainline version file | `git show origin/main:.version` | `v4.05` |
| In-flight plan files | `ls release/releases/plans/` | highest = `v4.02-release-closeout-integrity`; nothing ≥ `v4.06` |
| Live release branches | `git for-each-ref refs/remotes/origin` | only `release/governance-hardening` — **slug-primary, binds no version** (defer-to-merge, ADR-092) |

**Verdict: PROCEED.** `anchor()` = `v4.05`; floor (minor) = `v4.06`; `claimed_set()` has no member at or above the floor. **v4.06 remains next-free.** No HALT condition present.

**Watch item (not an override trigger).** Milestone #305 `release-notes-and-learnings` planned concurrently and binds no version under the same defer-to-merge architecture. Whichever release reaches Stage 12 first wins the number by compare-and-swap; the loser re-versions upward. Recorded, not mitigated.

## Dependency Graph

**2 directed edges / 6 nodes.** Every edge and every asserted non-edge carries evidence.

```
#3581 ──(hard: boundary-then-enforcement)──▶ #3822
#3817 ──(soft: sequencing-input ordering)──▶ #3827
#2719   (isolated)
#3819   (isolated)
```

| Edge | Class | Evidence |
|---|---|---|
| `#3581 → #3822` | **Hard** | #3822's re-validation must *enforce* a boundary #3581 *defines* — a bundle-entry check that re-validates an existing-milestone claim has nothing to assert against until the composition-lock boundary exists in `release-process.md` § A7. Recorded in the milestone description's `## Internal sequence` and in #3822's DoR-crisp block. |
| `#3817 → #3827` | **Soft (sequencing-input)** | #3827 AC4 requires `dependency-analysis.md` to cite the selector at Implementation Sequence — the same file #3817 AC3 requires to be reconciled with the parser. Not a hard block: #3827's § 2.4 extension is authorable independently; the coupling is that #3827's value/WIP-first arm reads a priority signal whose existence #3817 decides. **Not counted in the milestone's rule-14 tally of 1** — it is a soft edge, and Stage 4 concurred with that classification. |

**Asserted non-edges, with evidence:**

| Non-edge | Evidence it is genuinely independent |
|---|---|
| `#2719` ⟂ all | Scope is `stage-04-planning.md` Phase A0 + `release-hub` SKILL.md + the readiness checklist. Its AC set names no other in-release file. Composes with the *already-shipped* G-PL4, not with any in-release issue. |
| `#3819` ⟂ all | Scope is `hub-spoke-bridge.md` Procedure 1 + Procedure 7 + `automated-closeout.sh` + two deploy-check surfaces. Its Mode-R-resolved root cause touches the hub's artifact model, not the bundling/sequencing protocol the other five touch. **Note:** Stage 5 introduced a *file*-level (not dependency-level) adjacency with #3581 on `hub-spoke-bridge.md` — see § Contention Map. |
| `#3581` ⟂ `#3817`/`#3827`/`#2719` | No shared path. #3581 governs *whether a running bundle may grow*; #3817/#3827 govern *how the planner orders work*; #2719 governs *what Phase A0 reads at entry*. Disjoint predicates. |
| `#3822` ⟂ `#3817`/`#3827` | #3822 touches `release-planner/SKILL.md` Mode A (Stage-3 composition selection); #3817/#3827 touch `release-planner/references/dependency-analysis.md`. Different files, different modes. A Mode-A citation added by #3822 and a dependency-analysis edit by #3817/#3827 could in principle collide at the SKILL.md↔reference seam; graded by **CIAC-3**. |
| Zero cycles | Manual DAG walk over the 2-edge graph; full enumeration (6 nodes / 2 edges), not a sample. Sensitivity arm: the same walk on an injected `#3827 → #3817` back-edge yields a detected 2-cycle. Verdict **CLEAN**. |

**Rule-14 cohesion (recorded, not re-litigated):** 1 internal dependency edge against the 5 required for N=6. The bundle is held deliberately as a themed capability; the G3-15 oversize was adjudicated by the operator 2026-08-01 as disposition **C (keep-with-rationale)**. Carried as risk **R-4**.

**Reflexivity note.** #3827 ships a *dependency-density → sequencing-mode selector*. Applied to **this release's own graph** (6 nodes, 1 hard edge — far below the N−1 = 5 threshold), the selector classifies **flat → value/WIP-first**, which is exactly the sequencing this plan uses. This release is a ready-made worked example for its § 2.4 extension.

## Implementation Sequence

**Topology:** D-C **SINGLE** (hub-resolved). One release branch, one PR, one merge. Plan file lands as **Engineering Commit 0**.
**D-Concurrency Posture:** **P0 fully-serial** — recorded determination, not a gate. SINGLE topology maps to P0; there is no judgment fork when topology is already SINGLE. Force-push on the shared release branch (including `--force-with-lease`) is prohibited under any non-serial posture; P0 makes that moot and the prohibition stands.

### Stage 6 Engineering — serial order (one branch)

| # | Issue | Size | Why here |
|---|---|---|---|
| 1 | **#3581** | L | Chain head. Defines the composition-lock boundary in `release-process.md` § A7, `stage-03-bundle.md` § A9.8, `gate-criteria-spec.md` G-BR5, and the emission point in `hub-spoke-bridge.md` Procedure 0 Step 5. Everything #3822 asserts references this boundary. **Also owns Engineering Commit 0.** |
| 2 | **#3822** | M | Consumes #3581's boundary. **Placed adjacent** so both `stage-03-bundle.md` edits land back-to-back — minimises intra-branch churn on the one within-release contended file. |
| 3 | **#3817** | M | Second chain head. Repairs the inert priority path (`bundle-issues-parser.py` body-parse + the `dependency-analysis.md` tie-breaker claim). |
| 4 | **#3827** | S | Consumes #3817's resolution. **Placed adjacent** so both `dependency-analysis.md` edits land back-to-back — same rationale as slice 2. |
| 5 | **#2719** | M | Independent. Placed before #3819 because `stage-04-planning.md` was contended with the then-live `release/governance-hardening` branch. *(That branch has since merged — see DEV-1 — so the original rationale is discharged; the ordering is retained because it costs nothing and #3819 must stay last.)* |
| 6 | **#3819** | M | Independent, **placed last deliberately**. It edits `release/tools/automated-closeout.sh` — the script that runs **this release's own Stage 13 close-out**. Landing it closest to review keeps the reflexive-blast-radius surface under the freshest eyes (see **R-8**). |

### Stages 5 / 7 / 8 — parallel waves

The parallel-safe stages produce comments, not file writes, so file contention does not gate them; the dependency edges do.

| Wave | Issues | Count | Gate |
|---|---|---|---|
| **A** | #3581, #3817, #2719, #3819 | **4** | No upstream in-release design dependency |
| **B** | #3822, #3827 | **2** | Consume Wave-A design output |

**Worst parallel batch = 4** (not 6). This split is the plan-recorded quota mitigation. Checkpoint B re-validates at each wave and is the load-bearing gate.

**Stages 9–13** are release-scoped singletons (one sub-task each, not per-issue) — sub-tasks #4533 / #4534 / #4535 / #4536 / #4537.

## Stage Applicability Matrix

Default is all-apply. Deviations are argued, not asserted.

| Issue | S5 Solutioning | S6 Eng | S7 Dev Test | S8 QA | S9 | S10 | S11 | S12 | S13 |
|---|---|---|---|---|---|---|---|---|---|
| **#3581** | **APPLY** | APPLY | **APPLY** | APPLY | rel | comp | comp | rel | rel |
| **#3822** | **APPLY** | APPLY | **APPLY** | APPLY | rel | comp | comp | rel | rel |
| **#3817** | **APPLY** | APPLY | **APPLY** | APPLY | rel | comp | comp | rel | rel |
| **#3827** | **APPLY** | APPLY | **APPLY** | APPLY | rel | comp | comp | rel | rel |
| **#2719** | **APPLY** | APPLY | **APPLY** | APPLY | rel | comp | comp | rel | rel |
| **#3819** | **APPLY** | APPLY | **APPLY** | APPLY | rel | comp | comp | rel | rel |

`rel` = release-scoped singleton sub-task · `comp` = compressed for git-native releases (Stage 10: CI *is* the dry run; Stage 11: git history *is* the snapshot).

**Stage 5 — all 6 APPLY.** Class `cross-cutting` sets activation bias **ALL**, and the bias was *earned*: #3581 deferred its enforcement mechanism to Solutioning and carried two unresolved Triage questions; #3817 carried a genuine two-way resolution fork; #3819's root cause was re-established at Mode R; #3822/#3827/#2719 carried the compositional questions the CIACs grade. **All six ran and are closed** (#4509, #4513, #4517, #4521, #4525, #4529).

**Stage 7 — all 6 APPLY. No blanket doc-only skip.** Reasoning per issue rather than per file-extension:
- **#3817** — real executable surface: `release/tools/bundle-issues-parser.py` with an existing test at `release/tools/tests/test_bundle_issues_parser.py`. DT runs the suite.
- **#3819** — real executable surface: `release/tools/automated-closeout.sh`, plus `check-milestone-epic-membership.py` and a `deploy.sh` Check-56 branch. DT runs `bash -n` + a `--dry-run` close-out + `--self-test`.
- **#3581 / #3822 / #2719** — protocol changes with **functional pipeline impact**, not prose. #3581 changes a G-BR gate criterion the stage-gate evaluator reads; #3822 adds a bundle-entry check; #2719 changes what Phase A0 executes at entry. Their ACs are `grep`-shaped predicates — a runnable DT surface at near-zero cost.
- **#3827** — the weakest DT case (a discipline-doc extension). It still carries grep-verifiable ACs plus the ADR-019 no-duplicate-logic check, which is a real regression risk. APPLY.

**Stage 8 — all 6 APPLY.** Per-criterion AC verdicts; every issue carries a G1-05a-conformant observable AC set from the Mode R readiness pass.

## File Change Matrix

Machine-readable path list for Stage 7/8/9 chip extraction (baseline-pin awareness, Procedure 0). **Reconciled against all six Stage-5 outputs** — this list supersedes the Stage-4 rendering.

```
release/governance/release-process.md
release/references/pipeline/stage-03-bundle.md
core/schemas/gate-criteria-spec.md
release/references/how-to/hub-spoke-bridge.md
release/skills/release-planner/SKILL.md
release/tools/bundle-issues-parser.py
release/tools/tests/test_bundle_issues_parser.py
release/skills/release-planner/references/dependency-analysis.md
core/disciplines/discovery-discipline.md
release/references/pipeline/stage-04-planning.md
release/skills/release-hub/SKILL.md
release/skills/release-hub/references/milestone-readiness-checklist.md
release/releases/hub-state/readiness-briefing.md.template
release/releases/hub-state/README.md
core/standards/hub-session-continuity.md
release/references/standards/triage-design-rereview.md
release/tools/automated-closeout.sh
core/deploy/tools/check-milestone-epic-membership.py
core/deploy/deploy.sh
release/ADRs/
core/ADRs/
release/releases/plans/release-bundle-and-sequence-gates_RELEASE_PLAN.md
packages/release-planner.skill
packages/release-planner.skill.sha256
packages/release-hub.skill
packages/release-hub.skill.sha256
```

Per-issue, per-file intent — **anchored to headings and tokens, never line numbers** (the #290 merge shifted line numbers in two shared files; see DEV-1):

| Issue | Path | Intent | Region anchor / change |
|---|---|---|---|
| **#3581** | `release/governance/release-process.md` | **edit** | § A7 → `**Sub-window mutability:**` table (4→5 columns, additions/removals split) · new `**Composition lock (Stage-4 Planning entry):**` block with the act-typed rule, the 3-state resolution, the not-locked list, lift conditions, no-exception statement, and the Tier-A ASCII concept model · `**Churn-budget threshold…**` sub-window scoping · `**Refresh outcome paths…**` paths (1)/(2)/(3) · `**Gate:**` line `G-BR1..G-BR4` → `G-BR1..G-BR5` |
| **#3581** | `release/references/pipeline/stage-03-bundle.md` | **edit** | § A9.8 → the `- **Threshold-met → operator-prompt → decision flow:**` bullet gains the amend-target exclusion, **by citation** |
| **#3581** | `core/schemas/gate-criteria-spec.md` | **edit** | § Gate G-BR criteria table (append `G-BR5`) · its `### Self-Repair Actions` table (append `G-BR5`) · `## Versioning` schema bump + changelog entry. **Bump relative to the value read at Commit 0**, never hardcoded |
| **#3581** | `release/references/how-to/hub-spoke-bridge.md` | **edit** | **Procedure 0 Step 5 only** — emit the `### Composition Lock` H3 into the Milestone description via the `gh api … milestones/<N> -X PATCH` mechanism Step 7 already mandates. **Added at Stage-5 Revision 1** (DEV-3) |
| **#3581** | `release/ADRs/ADR-110-*.md` | **add** | Composition-lock decision record. Number **re-derived at Commit 0** (DEV-2) |
| **#3822** | `release/references/pipeline/stage-03-bundle.md` | **edit** | Bundle-entry checks — existing-milestone-claim re-validation (card **and** parent) + PT-2 subsumption re-run against a **bundling-time** baseline. **Shares this file with #3581**, disjoint regions |
| **#3822** | `release/skills/release-planner/SKILL.md` | **edit** | Mode A composition selection — *cite* the re-validation, do not restate (ADR-019). **Also carries #3581's R-1 cascade**: `G-BR1..G-BR4` → `G-BR1..G-BR5` and the co-located stale `T1/T2/T3/T4` → `T1–T6` |
| **#3817** | `release/tools/bundle-issues-parser.py` | **edit** | Replace `parse_priority_label` with a body-field parser (`### Priority`) + priority rank; rewire `build_issue_record`; extend `run_self_test`. Per **D-2 (operator: BODY-PARSE)** |
| **#3817** | `release/skills/release-planner/references/dependency-analysis.md` | **edit** | § Tie-Breaker Rule — reconcile the `P1 before P2…` claim with the parser's actual source. **Shares this file with #3827**, disjoint regions |
| **#3817** | `release/tools/tests/test_bundle_issues_parser.py` | **edit** | Fixture coverage for the body-parse path |
| **#3817** | `release/ADRs/` or `core/ADRs/` | **add** | ADR per its Stage-5 R-5. **Number must be re-derived** — its Stage-5 allocation (105) is claimed (DEV-2) |
| **#3827** | `core/disciplines/discovery-discipline.md` | **edit** | § 2.4 Scope-cleavage identification — second consumer of the existing rule-14 N−1 edge count: topology-first vs value/WIP-first + guards. **No parallel density metric** (AC3) |
| **#3827** | `release/skills/release-planner/references/dependency-analysis.md` | **edit** | Two regions. § Step 4 Topological Sort — replace the dead 3-item preference list with the selector citation + mode→key routing table; cite, do not restate (ADR-019). § Leverage Analysis — one scope clause binding the leverage rule to a dense verdict (Stage-5 Revision 1, CDF-2a). **Shares this file with #3817**, disjoint regions |
| **#2719** | `release/references/pipeline/stage-04-planning.md` | **edit** | Phase A0 — G-PL5 cache-read of a current Mode R briefing + currency guard composing with the shipped G-PL4 |
| **#2719** | `release/skills/release-hub/SKILL.md` | **edit** | Flip the double-running failure mode to shipped tense; narrow the Mode R state-mutation guardrail; add the briefing emit to Mode R |
| **#2719** | `release/skills/release-hub/references/milestone-readiness-checklist.md` | **edit** | Flip the `runs standalone` caveat; name the briefing surface + fingerprint field. **This is the real home of the caveat** — AC3 retargeted here at Stage 4 (DEV-4) |
| **#2719** | `release/releases/hub-state/readiness-briefing.md.template` | **add** | Surface D template (tracked, CUSTOMIZABLE-PUBLIC) |
| **#2719** | `release/releases/hub-state/README.md` · `core/standards/hub-session-continuity.md` | **edit** | Register Surface D in the runtime tree + Resume read-order |
| **#2719** | `release/references/standards/triage-design-rereview.md` | **edit (OPTIONAL)** | One § Anchor-patterns bullet registering G-PL5 as the machine consumer. **Optional per its Stage-5 R4** — the original AC3 target (`§ Integration`) does not exist and no defensive edit is authored to satisfy a stale assertion |
| **#2719** | `release/ADRs/` or `core/ADRs/` | **add** | Mode R briefing cache substrate + currency predicate. **Number must be re-derived** (DEV-2) |
| **#3819** | `release/references/how-to/hub-spoke-bridge.md` | **edit** | **Procedure 1** (six regions: § 1a insert, Step 2, Step 4, Step 6.5 insert, Sub-Task Template header + `**Parent:**` line, Skip Closure Format) + **Procedure 7** § Gate-passage proof recording. **Shares this file with #3581** — disjoint procedures (DEV-3) |
| **#3819** | `release/tools/automated-closeout.sh` | **edit** | New `_is_stage13_close_subtask` + `resolve_stage13_subtask`; rewrite `post_gate_passage_proof` so `MANUAL` becomes the *terminal fallback* rather than an unconditional emission; `--self-test` Tests 4e/4f |
| **#3819** | `core/deploy/tools/check-milestone-epic-membership.py` · `core/deploy/deploy.sh` | **edit** | Leg M3 + `--milestone` / `--leg` flags; Check 56 third branch via `flag_advisory_only`. **Allocates no ADR** |
| *release* | `release/releases/plans/release-bundle-and-sequence-gates_RELEASE_PLAN.md` | **add** | Engineering Commit 0. Slug-primary while in flight; renamed to `vX.Y_RELEASE_PLAN.md` at the Stage-12 atomic claim (ADR-092) |
| *release* | `packages/release-planner.skill` (+ `.sha256`) · `packages/release-hub.skill` (+ `.sha256`) | **rebuild** | Both source skills are edited (#3822/#3817/#3827, #2719/#3819) → `.skill` packages drift. **Each rebuild emits two artifacts** — the `.skill` and the `.sha256` content-baseline sidecar the script writes and Check 7 reads; the sidecar was undeclared until Stage-5 Revision 1 (FMF-3). **G6-06 is PR-time**, so both rebuilds land in this PR rather than waiting for `automated-closeout.sh` Phase 9.95. **Ownership is last-package-touching-slice, not last-slice:** `release-planner` → slice 4 (#3827, the last slice touching `release/skills/release-planner/`); `release-hub` → slice 6 (#3819, the last slice touching `release/skills/release-hub/`). |

**Structural blast radius (Tier-S): NONE from this release.** The mover-set is empty — every row is `edit` except plan-file/template/ADR `add`s (which eliminate no source path) and two package rebuilds. No rename, relocate, or delete. This release is not a serialization point for any sibling on the structural axis.

## ADR Allocation

**Next-free at Commit 0 = `ADR-110`.** Derived across `origin/main` **and** every unmerged remote branch — `git ls-tree -r --name-only <ref> -- core/ADRs release/ADRs` over `refs/remotes/origin/main` and `refs/remotes/origin/release/governance-hardening`; both max at **ADR-109**. `check-adr-numbers.py` globs the working tree only and returns a confident wrong answer against in-flight branches; it is **not** the authority here.

| Slice | Stage-5 allocation | Status at Commit 0 | Commit-0 allocation |
|---|---|---|---|
| **#3581** | ADR-107 | **COLLIDED** — `core/ADRs/ADR-107-payload-frontmatter-template-provenance.md` merged with #290 | **ADR-110** (claimed by this commit) |
| **#3817** | ADR-105 | **COLLIDED** — `release/ADRs/ADR-105-release-corpus-normalization.md` merged with #290 | **re-derive at its Commit** — next free after 110 |
| **#2719** | ADR-105 | **COLLIDED** — same | **re-derive at its Commit** — next free after 110 |
| **#3827** | none | — | none |
| **#3822** | none | — | none |
| **#3819** | explicitly none (*"ADR-109 stays unallocated"*) | — | none |

**Standing instruction to slices 3 and 5:** re-derive globally immediately before authoring, across both ADR directories and every unmerged remote branch **plus the ADRs already added on this release branch**. The ADR-number-integrity CI job blocks on a duplicate, so a collision fails loud — but re-derivation is cheaper than an amend.

## Contention Map

### Within-release

| Path | Claimed by | Class | Disposition |
|---|---|---|---|
| `release/references/pipeline/stage-03-bundle.md` | **#3581, #3822** | line-range-overlap | Sequence-adjacent (Eng slices 1→2). #3581 edits § A9.8; #3822 edits the bundle-entry checks. Distinct regions, same author-session order. |
| `release/skills/release-planner/references/dependency-analysis.md` | **#3817, #3827** | line-range-overlap | Sequence-adjacent (Eng slices 3→4). #3817 edits § Tie-Breaker Rule; #3827 edits § Step 4 Topological Sort. Distinct regions. |
| `release/references/how-to/hub-spoke-bridge.md` | **#3581, #3819** | line-range-overlap | **NEW at Stage 5** (DEV-3). #3581 takes **Procedure 0 Step 5 only**; #3819 takes **Procedure 1** (six regions) + **Procedure 7**. Disjoint procedures, disjoint anchor tokens. Slices 1 and 6 — maximally separated in the serial order. #3581's edit is append-only within Step 5 and reads none of #3819's state, so **no sequencing preference is asserted**. |
| `release/skills/release-planner/SKILL.md` | **#3822** (+ #3581's R-1 cascade routed in) | single-claim after routing | #3581's `G-BR1..G-BR4` → `G-BR1..G-BR5` cascade is **routed into #3822's slice** rather than opening a second claim on the file. Operator-approved as R-1. |

**The two dependency edges are also two of the four file-contention edges.** That is a coherence signal — the pairs the milestone sequenced on capability grounds are the same pairs that touch shared surface — and it is why the serial engineering order groups them adjacently.

### Cross-release

**Tier-1 — authoritative git evidence.** At Stage 4, `release/governance-hardening` (#290) was the only non-`main` release branch, 33 commits ahead, with hunks in `gate-criteria-spec.md` and `stage-04-planning.md` verified **disjoint** from our target regions. **It has since merged** (`39284a2d`). The contention is therefore **absorbed, not mitigated** — this release branches from post-merge `main`. See DEV-1. `release/governance-hardening` remains on the remote as a stale ref; it holds no ADR beyond 109 and no unmerged edit to our surface.

**Tier-2 — declared edit-intent (no branch yet).** Baseline-pinned; re-check at Stage 9 G-PR9.

| Our path | Sibling | Milestone (state at Stage 4) | Their declared region | Severity |
|---|---|---|---|---|
| `release/references/how-to/hub-spoke-bridge.md` | #3709 | `release-check-enforcement-gates` (#300) — **0 scaffolded sub-tasks; not started** | Sub-Task Template / creation procedure — same region as **#3819** | **MED** *(downgraded from HIGH at the Procedure 0 gate: the hub's adversarial verification established #300 has not entered the pipeline, so the "sequence after it lands" arm was unavailable and the "ahead of us" premise was false)* |
| `release/references/how-to/hub-spoke-bridge.md` | #4184, #3815 | `hub-spoke-execution-safety` (#301) — not started | worked examples · spoke output-path namespacing | MED |
| `release/references/how-to/hub-spoke-bridge.md` | #3826 | `release-check-enforcement-gates` (#300) | issue-reference block | MED |
| `release/references/how-to/hub-spoke-bridge.md` | #4199 | `version-binding-lifecycle` (#306) — not started | Procedure 0 § Canonical location | **LOW→WATCH** — different region from #3819's, but **Procedure 0 is now #3581's region too**. Coordinate at Stage 9 |
| `core/schemas/gate-criteria-spec.md` | #3703, #3820, #3821 | `release-check-enforcement-gates` (#300) | Gate-1 / Check-22 / G-CL8 criteria | MED |
| `release/references/pipeline/stage-04-planning.md` | #3828 | `version-binding-lifecycle` (#306) — not started | cross-release contention detection | MED |
| `release/references/pipeline/stage-04-planning.md` + `release/governance/release-process.md` | #4201 | `bundle-rebundle-mechanics` (#311) — not started | Phase A0 premise re-review + § A7 Bundle Mutability | **MED — two of our files, in the capability-overlap milestone.** Registered as **R-9** |
| `release/tools/automated-closeout.sh` | #4451, #3698 | `release-notes-and-learnings` (#305) — **planned concurrently** | the close-out producer | **MED — concurrent Stage 4.** Registered as **R-11** |
| `release/tools/automated-closeout.sh` | #1825 | `methodology-fields-and-statuses` (#265) | epic rollup-close step | MED |

**Operator determination at the Procedure 0 gate (D-1): LAND FIRST + COORDINATE.** Proceed with #3819 now; post coordination notes on #3709 and #4184 naming our Procedure 1 edit so they rebase onto us. No trim, no move (coordination-not-relocation: imminence zero, independent value present, target coherent). **This plan extends that determination to #3581's Procedure 0 Step 5 edit**, which is in the same file and reached the matrix after the gate — the coordination note should name both regions.

## Risk Register

| ID | Risk | Class | Sev | Root cause | Mitigation | Owner-stage | Reversibility |
|---|---|---|---|---|---|---|---|
| **R-1** | #3709 (#300) edits `hub-spoke-bridge.md`'s Sub-Task Template / creation procedure — the same region #3819 edits. | Contention | MED | The Parallelization Map recorded only the #4184 contender and only for the worked-examples region; nobody scanned the whole open-issue population for Procedure-1-region editors. | Operator verdict D-1 **LAND FIRST + COORDINATE**. Additive, token-anchored edits; coordination notes on #3709 and #4184. **Extend the note to cover #3581's Procedure 0 Step 5 region.** | Stage 9 | MODERATE / MEDIUM |
| **R-2** | Live `release/governance-hardening` branch had modified `gate-criteria-spec.md` + `stage-04-planning.md`. | Contention | **CLOSED** | Baseline-pin temporal limitation. | **DISCHARGED at Commit 0** — #290 merged and this branch is cut from post-merge `main`. The predicted G-PR9 hit fired and is resolved by construction, not by rebase. See DEV-1. | — | — |
| **R-3** | #4184 + #3815 (#301) also contend on `hub-spoke-bridge.md`; #301 has not started, so it may land *after* us and inherit the rebase. | Contention | MED | Same root cause as R-1. | Accept. This plan's Contention Map is the coordination token; whoever merges second rebases. | Stage 4 (record) | CHEAP / HIGH |
| **R-4** | **Oversize: 26 raw × 1.3 = 34 effective pts against a 25 ceiling.** | Scope | MED | Deliberate — G3-15 override **disposition C (keep-with-rationale)**, operator-adjudicated 2026-08-01. **Not re-litigated.** | Residual only: 6 issues × 4 per-issue stages = 24 spoke launches plus 5 release-scoped gates. The 4+2 wave split is the capacity mitigation. Watch for Stage-8 AC-verdict fatigue on a 6-issue matrix. | Stage 9 review depth | MODERATE / MEDIUM |
| **R-5** | `cross-cutting` class was threshold-fragile — trigger (b) fired at exactly 3 governance surfaces, one conditional on #3581's Stage-5 mechanism choice. | Class | **CLOSED** | The class was declared at Stage 3 against a File Change Matrix that did not yet exist. | **RESOLVED at Stage 5.** D-3581-Mechanism selected the G-BR5 criterion (AC4 mandates it), keeping `gate-criteria-spec.md` in the matrix; Revision 1 then **added** `hub-spoke-bridge.md`. Trigger (b) counts **4**. The re-classification trigger **does not fire**; weight stays 1.3, review depth Deep. | — | — |
| **R-6** | Cohesion floor: 1 internal dependency edge vs 5 required for N=6. | Cohesion | LOW-MED | Deliberate themed-capability bundle, recorded at Stage 3. | Accept per the recorded rationale. The file-contention edges (which the rule-14 count does not credit) provide real coupling; the CIACs make that coupling gradable rather than asserted. | Stage 9 | MODERATE / MEDIUM |
| **R-7** | #2719 AC3 targeted a section that does not exist (`triage-design-rereview.md § Integration`). | Currency (A0.5 / G-PL1) | **CLOSED** | The AC was authored from a remembered file layout. | **RESOLVED** — Tier 1 `[ADJUST]` applied to #2719 at the Procedure 0 gate; AC3 retargeted at `release-hub/SKILL.md` **and** `milestone-readiness-checklist.md` (the hub located two live caveat sites, one more than the spoke reported). No defensive edit authored to `triage-design-rereview.md`. See DEV-4. | — | CHEAP / HIGH |
| **R-8** | **Reflexive blast radius:** #3819 edits `automated-closeout.sh`, which **this release's own Stage 13 close-out executes**. A defective `post_gate_passage_proof` fallback would first manifest on this release's own close. | Rollback / operational | MED | Reflexive-pipeline-loop — a release that edits the close-out tool is closed by the edited tool. | Two controls: (a) Stage 7 DT for #3819 **must** run `bash -n` + `--self-test` + a `--dry-run` close-out exercising the new fallback branch, not merely read the diff; (b) engineering slice **6 of 6** keeps it under freshest review. The fix must preserve `MANUAL` as the *terminal* fallback so the pre-change runtime escape hatch survives. | Stage 7 DT | MODERATE / MEDIUM |
| **R-9** | Capability overlap with #311 `bundle-rebundle-mechanics`, whose #4201 declares edits to `stage-04-planning.md` Phase A0 **and** `release-process.md` § A7 — both files this release edits. | Contention / scope | LOW-MED | #311's own description names this milestone as its natural home and anticipates absorbing into a successor; disposition recorded as keep-with-rationale. | Register only. Revisit the merge at this milestone's close. **Do not act on it in this release.** | Stage 13 | CHEAP / HIGH |
| **R-10** | Two `.skill` packages (`release-planner`, `release-hub`) drift when their source files change. | Build hygiene | LOW | Package artifacts are built, not authored; drift surfaces as `deploy.sh --check` Check 7 / G6-06. | `automated-closeout.sh` Phase 9.95 `rebuild_skill_packages` handles this at close-out; both are in the File Change Matrix so the rebuild is expected rather than a surprise FAIL. **G6-06 is PR-time**, so the rebuild should land in this PR, not wait for close-out. | Stage 6 (final slice) / Stage 13 | CHEAP / HIGH |
| **R-11** | Milestone #305 is at Stage 4 concurrently and shares `automated-closeout.sh` (#4451). | Contention | LOW-MED | Two Stage-4 planning runs in the same window with no cross-plan reconciliation step in Procedure 0. | Hub-level: reconcile the two Stage-4 File Change Matrices before either enters Engineering. Whichever enters Engineering second records the other's baseline. **Also the live v4.06 version-claim contender** — see § Commit-0 Version Re-Verify. | Hub (Procedure 0) | CHEAP / HIGH |
| **R-12** | **NEW at Commit 0.** Three slices' Stage-5 ADR allocations collided with numbers landed by the #290 merge. Two remain unresolved (#3817, #2719). | Governance / build | MED | ADR next-free was derived at Stage 5 against a then-current mainline; an in-flight sibling merged four ADRs before Engineering started. `check-adr-numbers.py` globs the working tree only and cannot see in-flight branches. | Standing instruction in § ADR Allocation: re-derive globally immediately before authoring, including ADRs already added on this branch. CI blocks duplicates, so this fails loud. | Stage 6 (slices 3, 5) | CHEAP / HIGH |

## Cross-Issue Acceptance Criteria

Five CIACs. Each spans ≥2 issues, asserts a cohesion constraint the *integrated* release must hold, and is graded on the merged PR at **Stage 9 QC3.5 / Phase A3.6**.

- [ ] **CIAC-1 (#3581 × #3822 on `stage-03-bundle.md` + `release-process.md`):** the composition-lock boundary and the bundle-entry re-validation name the **same boundary token** — a re-validation that fires at a different moment than the lock closes leaves an unguarded window. **Predicate:** both surfaces state *Stage 4 Planning entry* as the composition-lock boundary, with no surface asserting a different boundary for the same lock. *Method:* `grep -n "Stage.4 Planning entry" release/references/pipeline/stage-03-bundle.md release/governance/release-process.md release/references/how-to/hub-spoke-bridge.md` — expect ≥1 hit in each and zero contradicting boundary claims. *(Scope extended at Stage 5 Revision 1 to include the emission surface.)*

- [ ] **CIAC-2 (#3581 × #3822 on `gate-criteria-spec.md` § G-BR and the Stage-3 bundle-entry check):** exactly **one** surface *defines* the composition-lock rule and its state resolution; the others *cite* it. Two definitions is the ADR-019 duplicate-logic failure this release is otherwise arguing against. **Predicate:** one definition, ≥1 citation, zero restatements. *Method:* `grep -n "Composition lock\|composition-lock\|pre-Stage-4\|at or past Stage-4" core/schemas/gate-criteria-spec.md release/references/pipeline/stage-03-bundle.md release/references/how-to/hub-spoke-bridge.md release/governance/release-process.md` — inspect each hit and confirm exactly one states the rule.

- [ ] **CIAC-3 (#3817 × #3827 on `dependency-analysis.md` + `bundle-issues-parser.py`):** the documented priority tie-breaker and the parser's actual capability **agree**, and the sequencing-mode selector does not cite a priority signal the parser does not produce. This is the exact defect class #3817 exists to fix — shipping #3827 on top of an unreconciled tie-breaker would re-create it one layer up. **Predicate:** `dependency-analysis.md` asserts a priority tie-breaker **iff** `IssueRecord.priority` is populated from a live source; and #3827's selector text cites no priority signal absent under the chosen resolution (**body-parse**, per operator D-2). *Method:* `grep -n "P1 before P2\|priority" release/skills/release-planner/references/dependency-analysis.md` cross-checked against `grep -n "priority" release/tools/bundle-issues-parser.py`.

- [ ] **CIAC-4 (#3819 × #2719 on the hub's artifact-scope model):** after this release, **one** statement governs which pipeline stages carry per-issue sub-tasks vs release-scoped singletons, and it is **correct for Stage 4** (which Procedure 0 Step 5 already creates release-scoped) as well as 9/12/13. #2719 wires Phase A0 to consume a **milestone-scoped** Mode R briefing, which presumes the same scope model. **Predicate:** Procedure 1 names per-issue = Stages 5–8 and release-scoped = Stages 4, 9, 12, 13; no surface claims Stage 4 is per-issue. *Method:* `grep -n "per stage per issue\|release-scoped" release/references/how-to/hub-spoke-bridge.md` and confirm Stage 4 is not claimed per-issue.

**Stage-5 integration criteria for the #3817 ↔ #3827 pair — the count is TWO, and one arm is a ratified residual.** Stage-5 Revision 1 adopted CDF-3: `INT-1′` and `INT-3′` are **retired** (both were answerable against #3827's artifact with #3817 absent — duplicated self-conformance arms, not integration coverage), and are replaced by a single bi-artifact criterion **`INT-3″`**. `INT-2` stands as authored. **Stage 9 QC3.5 counts two criteria for this pair, not three.**

- [ ] **INT-3″ (#3817 → #3827 on `dependency-analysis.md`):** after both slices land, does the file state **exactly one ordering rule per mode** — do § Tie-Breaker Rule (as #3817 leaves it) and § Step 4 (as #3827 leaves it) agree on which key orders the flat case, with **no site stating an unconditional rule the other conditions**? *Arms (mechanical proxies for the semantic assertion, and stated as such):* **(1)** whole-file `grep -c "highest leverage score should be implemented earliest"` → **1**, and within the `## Leverage Analysis` region `grep -cE "dense|density selector|topology-first"` → **≥1**. **(2)** within the `### Tie-Breaker Rule` region, `grep -cE "topology-first|value/WIP-first|density selector|both modes"` → **≥1**.
  **Expected verdict, declared in advance: arm (1) PASSES, arm (2) FAILS.** This is the ratified split of Stage-5 CDF-2 — **(a)** the `## Leverage Analysis` scope clause was adopted into slice 4 (one clause, zero external consumers), while **(b)** the `### Tie-Breaker Rule` scope clause was **DEFERRED** at scope-lock because that region belongs to #3817, which had already landed at slice 3. **The residual is therefore known, named, and deliberate, not an escape.** It is the sole remaining site of the three-way ordering contradiction this card otherwise retires: after this release § Tie-Breaker Rule still states its rejection of leverage unconditionally, while § Step 4 conditions it on the density verdict. INT-3″ arm (2) is the mechanism that keeps that residual visible at Stage 8 rather than silent. **Routing:** a one-hunk follow-up adding a leading scope clause to § Tie-Breaker Rule — not folded into this PR.

- [ ] **CIAC-5 (#3581 × #2719 on `stage-04-planning.md` Phase A0):** the Phase-A0 entry sequence remains a **single ordered gate stack** after both edits, and the new cache-read's currency guard **does not bypass** the composition-lock check. Both issues change what Phase A0 does at entry; independently-correct edits can compose into an order-ambiguous or lock-skipping stack. **Predicate:** Phase A0 enumerates its steps in one ordered list including the cache-read, A0.5, A0.6, A0.7, A0.8 and the composition-lock check, with the lock's position named; the cache-read's skip condition is scoped to PT-1..4 only. *Method:* read the Phase A0 block; confirm one ordered enumeration and that the cache-read's skip condition names PT-1..4 exclusively.

## Quota Budget

**Verdict: WARN** (per `quota-budget-protocol.md` Checkpoint A)

**Parallel-eligible spokes per parallel stage:** Stage 5: 6 · Stage 7: 6 · Stage 8: 6.
**Worst parallel batch under the recommended wave split: 4** (Wave A = #3581 `size:L`, #3817 `size:M`, #2719 `size:M`, #3819 `size:M`; Wave B = #3822 `size:M`, #3827 `size:S`). Un-split, the worst batch would be 6.
**Per-spoke cost estimate:** size-bucket ordinal band — `size:L` moderate–high (×1), `size:M` low–moderate (×4), `size:S` lowest (×1). **Source: heuristic.** The cutover to observed medians has **not** fired for any bucket — no telemetry population exists. The ordinal band is the retained floor.
**Assumed envelope:** no operator quota state was stated at hub start → conservative default. `[ASSUMPTION – CONFIRM]`
**Estimated cumulative draw:** **50–80%** of a conservatively-assumed envelope, across ~24 spoke launches for the release. Band placement `[CALIBRATE-AFTER-3]`, **MEDIUM** confidence, sensitive to the unstated envelope.

**Routing (WARN):** window-aware launch timing + split batch. **The split is already applied** — the Wave A / Wave B structure *is* the mitigation, sized so the worst batch is 4 rather than 6. Secondary recommendation: capture the operator's quota state at hub start so Checkpoint B has a real envelope.

**Framing (do not mis-route this):** this is a **usage-window / cumulative-draw** budget, not a rate-limit or stagger problem. Spreading spokes across minutes changes nothing about cumulative token consumption inside the window. Route any overrun to **SERIALIZE / DEFER / REDUCE-scope**, never to STAGGER.

**Note:** the Checkpoint-A verdict is **advisory**. The load-bearing gate is **Checkpoint B**, re-validated at **every** parallel wave at hub routing time.

## Rollback Strategy

**Release-level.** Single-branch (D-C SINGLE), one PR, one merge commit → rollback is `git revert -m 1 <merge-sha>` on `main`. Every change is additive text, a scoped function edit, or a new file; nothing is a schema migration, data mutation, or irreversible external action. **Overall reversibility: MODERATE / confidence HIGH** — MODERATE rather than CHEAP because the protocol semantics change how *future* bundles behave (a bundle locked under the new § A7 rule and then unlocked by a revert leaves an inconsistent audit trail), not because the diff is hard to undo.

| Slice | Rollback unit | Notes |
|---|---|---|
| #3581 | § A7 regions + § A9.8 routing + G-BR5 (+ schema-version bump) + Procedure 0 Step 5 emission + ADR-110 | Revert must include the `gate-criteria-spec.md` **version bump and changelog entry** together with the criterion, or the schema's own changelog goes inconsistent. The Procedure 0 emission may be reverted independently — the lock degrades to orders 2–3 of the three-valued resolution, which the design states is sound without the marker. |
| #3822 | Bundle-entry check block + Mode A citation + the R-1 cascade | Independent revert; leaves #3581's boundary in place (a defined boundary with no bundle-entry enforcement is the pre-release state, so this is safe). |
| #3817 | Parser function + tie-breaker doc claim + tests + ADR | **Must revert as a pair** — reverting one alone re-creates the exact doc↔code divergence the issue fixes. CIAC-3 is the detector. |
| #3827 | § 2.4 extension + `dependency-analysis.md` citation | Safe to revert alone **only if** #3817's arm is also reverted; otherwise the citation dangles. |
| #2719 | Phase A0 cache-read + currency guard + skill-doc reconciliations + template + ADR | Reverting the cache-read **must** also revert the "shipped" reconciliations, or the docs claim a behavior that no longer exists. |
| #3819 | Procedure 1 + Procedure 7 + `post_gate_passage_proof` + the two deploy-check surfaces | **Highest operational care.** See below. |

**#3819 / `automated-closeout.sh` — the reflexive case (R-8).** This release's own Stage 13 close-out executes the script #3819 edits. A defect in the new fallback branch manifests *first* on this release. Controls: (1) Stage 7 DT must exercise the new branch via `bash -n`, `--self-test`, and a `--dry-run` close-out, not merely read the diff; (2) if the fallback misbehaves at Stage 13, the recovery is **not** a revert mid-close-out — it is the documented `MANUAL` path (emit the proof text into the report and post by hand), which is precisely today's behavior. That property must be preserved *by design* in the fix.

**Package artifacts.** `packages/release-planner.skill` and `packages/release-hub.skill` are build outputs. A source revert without a package rebuild leaves Check 7 / G6-06 drift; the revert procedure must re-run `bash core/deploy/tools/build-skill-packages.sh release-planner release-hub`.

**Stage 11 note:** compressed — git history *is* the snapshot for a git-native release. No separate snapshot artifact is required or produced.

## Verification Plan

### Per-issue AC → verification method

| Issue | AC predicate class | Verification method | Expected result |
|---|---|---|---|
| **#3581** | file-path+state (8 ACs, incl. AC7/AC8 added at Stage 5) | `grep` the § A7 sub-window table B/C rows; the churn-budget block; § A9.8's routing sentence; `G-BR`; the add-only-vs-bidirectional statement; the exception clause. **AC7:** read every § A7 surface naming the lock and confirm each gates on `issues_added` rather than on the disposition name — a statement gating the `amend` path itself is a FAIL. **AC8:** confirm the lock-state resolver is three-valued and no consumer coerces `UNMARKED` to eligible | B/C rows carry no unqualified "Mutable" for additions; churn-budget names its sub-window scope; § A9.8 names the exclusion; ≥1 G-BR criterion references the lock boundary; both Triage questions answered **in prose**; `amend` reachable in B/C for zero-addition changes; three states present |
| **#3822** | file-path+state (3) + explicit `predicate:` (1) | `grep` bundle-entry checks for card **and** parent; confirm a bundling-time baseline; `grep` Mode A for the citation (no restatement); **replay the 2026-07-02 case** (parent #71, milestones #128 / #268) against the new check | Both card and parent named; baseline is bundling-time not filing-time; Mode A cites per ADR-019; the replay **fires** |
| **#3817** | file-path+state (2) + behavioral (2) | `grep` the parser for the forbidden label regex → **0**; run the parser over a fixture body carrying `P2 - High` and assert the resolved value; consistency-check doc↔code; `gh label list \| grep '^priority:'` → **0** | Body-parse arm per operator D-2. Executor exists: `release/tools/tests/test_bundle_issues_parser.py` |
| **#3827** | file-path+state (5) | `grep` § 2.4 for `topology-first` **and** `value/WIP-first`; for both failure-mode guards; confirm the rule-14 citation with **no second formula**; `grep` `dependency-analysis.md` for the citation. **AC3 carries a second arm ratified at scope-lock:** within § 2.4, `grep -cE "hard edge\|soft edge\|file-contention"` → **0** — the presence-grep alone cannot discriminate corrected text from the ambiguous original, so the edge-set scoping must read as a *deferral by citation* to the consumer surface, never as an enumeration authored in § 2.4 | All five present/absent as specified. **Baseline: 0 hits repo-wide today** apart from this plan file's own Change-Description mention of the two mode names, so any hit in a corpus file is attributable to this release |
| **#2719** | file-path+state (3) + behavioral (1) | `grep` Phase A0 for the cache-read step naming the Mode R briefing + the PT-1..4 skip condition; read the currency guard for its G-PL4 composition; `grep` the **corrected** surfaces (per DEV-4) for the caveat strings → 0; **run a worked Phase-A0 pass** with a current briefing present and a second with none | Cache-read path skips PT-1..4; fallback path runs it as today |
| **#3819** | file-path+state (3) + behavioral (1) | `grep` Procedure 1 for `release-scoped` and the named gate stages; read the sub-task creation step for an explicit milestone-assignment statement; `grep` `post_gate_passage_proof` for a **conditional** fallback branch (no bare `MANUAL`); **run a scaffold-completeness check** against a fully-scaffolded milestone **and** against a known-incomplete one | The check distinguishes the two. `bash -n` clean; `--self-test` green; `--dry-run` close-out exercises the new branch |

### #3827 dense-arm dormancy — the measurement, recorded here rather than in the corpus

Stage-5 Revision 1 withdrew #3827's empirical branch-liveness claim and routed the corrected measurement to this plan. It lives here, not in `discovery-discipline.md` § 2.4, because it is a point-in-time count over a population that changes with every release — embedding it in durable governance would violate *prefer durable structures over static examples* with no mechanism to refresh it. **§ 2.4 states the selector unconditionally and carries no count. Stage 8 grades the dormancy claim against this record, not against corpus text.**

> **Liveness test (corrected):** the number of surveyed bundles for which the two modes yield *different emitted sequences* under the selector's own precedence-bearing edge count — **not** how often the predicate `E ≥ N-1` evaluates true, which is what the Stage-5 Revision-0 survey actually measured.
>
> **Measured 2026-08-03 at `7943ae4a`: 0 of 48** (strict population) **/ ≤1 of 99** (full population). Two independent corrections produce the zero: 3 of 6 strict-population DENSE bundles admit exactly **one** valid topological order, so both modes provably emit the identical sequence and mode selection is unobservable; and all 3 remaining consequential cases carry **fewer precedence-bearing edges than `N-1`**, two of them stating verbatim in their own plans that they have zero hard edges.
>
> **Survey denominator (corrected at Revision 1):** **110** plan sections carrying a Dependency-Graph heading, of 145 plan files — not the 53 first published, which selected on markdown heading level and excluded 57 files (52% of the plans that record a graph). **11 DENSE / 88 FLAT (11.1%)** over 99 classifiable bundles; **0 of 59** bundles at `N ≥ 6` are dense. The superseded strict-population figure *"0 of 30"* at `N ≥ 6` is corrected to **0 of 29**.
>
> **Consequence, stated plainly:** the dense arm ships **documented-dormant**. It is defended normatively, not empirically — it gives a reachability condition to sequencing text `dependency-analysis.md` § Leverage Analysis already contained and nothing invoked. Its firing condition is a bundle with `E_precedence ≥ N-1` **and** more than one valid topological order. **Residual:** the first bundle composed dense fires the arm with no execution history behind it; bounded by the fact that it selects an ordering key already written in the corpus, and by precedence remaining binding in both modes — so a mis-selection can produce a suboptimal order, never an invalid one.

### Release-scoped verification

- **5 CIACs** graded at **Stage 9 QC3.5 / Phase A3.6** on the merged PR.
- **Executable regression:** `python3 release/tools/tests/test_bundle_issues_parser.py` (#3817) · `bash -n release/tools/automated-closeout.sh` + `--self-test` + `--dry-run` (#3819).
- **Platform checks:** `bash core/deploy/deploy.sh --check` — expect Check 7 / G6-06 package drift to surface until `build-skill-packages.sh release-planner release-hub` runs. **G6-06 is PR-time**, so the rebuild lands in this PR (R-10).
- **ADR-number integrity:** `check-adr-numbers.py` in CI must pass. Note it globs the working tree only — it is a *duplicate* detector on the branch, not a next-free authority against in-flight siblings.
- **Baseline currency (G-PR9):** at Stage 9, re-run `git log <branch-base>..origin/main --name-status --find-renames` and intersect against the File Change Matrix. The #290 hit already fired and is discharged (DEV-1); a *new* hit re-opens the re-validation.
- **Schema-integrity:** verify `gate-criteria-spec.md` carries a matching version bump **and** changelog entry per its own convention.

## Operator Decisions (D-Gate Block)

Rendered and recorded at the Procedure 0 gate (2026-08-02) unless noted.

| ID | Decision | Verdict | Reversibility / Confidence |
|---|---|---|---|
| **D-Version** | What version does this release claim? | **Recorded determination, not a gate.** Bump-class `minor`; anchor `v4.05`; next-free **v4.06** provisional. Slug-primary naming until the Stage-12 atomic claim. **Re-verified at Commit 0 — PROCEED.** | CHEAP pre-Engineering / MODERATE after Commit 0 / HIGH |
| **D-Concurrency** | Stage-6 parallelism posture | **Recorded determination.** **P0 — fully serial.** SINGLE topology maps to P0; no fork to render. | CHEAP / HIGH |
| **D-ReleaseClass** | Is `cross-cutting` correct? | **AGREED.** Trigger (b) fired at 3 governance surfaces at Stage 4; (a) and (c) verified not firing. **Now counts 4** after Stage-5 Revision 1 added `hub-spoke-bridge.md` — strictly reinforcing. Re-classification trigger does **not** fire; weight 1.3, review depth Deep, Stage-5 bias ALL, Stage-13 outcome window 30-day. | CHEAP / HIGH |
| **D-1 Contention-Bridge** | How does #3819 co-exist with the other `hub-spoke-bridge.md` editors? | **LAND FIRST + COORDINATE.** The hub's adversarial verification found the spoke's premise wrong — #300 and #301 both carry **0** scaffolded sub-tasks, so neither is "ahead of us" and the recorded "sequence after #4184 lands" arm was unavailable. Proceed now; post coordination notes on #3709 and #4184. No trim, no move. | MODERATE / HIGH |
| **D-2 #3817-Resolution** | Body-parse the priority field, or drop the documented tie-breaker? | **BODY-PARSE.** The parser sources priority from the issue body `### Priority` field (112/299 open issues carry it). No `priority:` label family introduced — `label-taxonomy.md` rule 5 preserved. Hub added the decisive rationale: **#3827, in this same release, adds a value/WIP-first mode that consumes priority** — the doc-only arm would delete the input its own release-mate is built to read. | CHEAP / HIGH |
| **D-3 Plan + Outcome Statement** | Approve? | **APPROVED AS BRIEFED.** Outcome Statement already present as an `### Release Outcome Statement` H3 on the milestone description; approved in place. Three Tier-1 adjustments authorized — see § Deviation Log DEV-4, DEV-5, DEV-6. | — |
| **D-3581-LockDirection** | Add-only or bidirectional? | **ADD-ONLY (asymmetric).** Sub-windows B/C become add-immutable; removals and deferrals stay legal at existing ceremony. A bidirectional lock is a **monotonicity inversion** — it would make B/C stricter than the hard lock, since G6-02 self-repair already sanctions descope-with-deviation-log at Stage 6, past Collective Review. | MODERATE / HIGH |
| **D-3581-Mechanism** | Which surface enforces the lock? | **G-BR5 criterion + protocol prose.** No new `deploy.sh` check — the lock is an *event-time* rule, not a continuous-state invariant, so a per-deploy monitor would poll for a condition that only exists at a decision moment. AC4 mandates the criterion, so this was not a free choice. | CHEAP / HIGH |
| **D-3581-Exception** | Hotfix / P1 carve-out? | **NO exception, recorded explicitly.** The `hotfix` Release Class is already the emergency route: a P1/P2 against a deployed release forms its own ≤3-issue corrective bundle, which reaches Stage 12 *faster* than a host bundle it would also contaminate. | CHEAP / HIGH |
| **D-3581-LockLift** | When does the lock release? | **Three conditions, no fifth outcome path:** Stage 13 Close · refresh outcome path (3) `re-bundle` (which re-executes Stage 3 Phase A1–A5 and returns the bundle to sub-window A) · run abandonment (recorded as path 3 or 4). | CHEAP / HIGH |
| **R-6 (Stage 5)** | Accept `hub-spoke-bridge.md` Procedure 0 Step 5 into #3581's slice (4 files → 5)? | **ACCEPTED.** The boundary becomes *emitted* rather than only inferred; cost is one PATCH in an already-mandated step. Named fallback (union-only, 4 files) not taken. | CHEAP / HIGH |
| **R-1 (Stage 5)** | `release-planner/SKILL.md` cascade (`G-BR1..G-BR4` → `..G-BR5` + stale `T1/T2/T3/T4` → `T1–T6`) | **Routed to #3822's slice**, which already owns that file and whose package is already scheduled for rebuild. Marginal cost ≈ 0. | CHEAP / HIGH |
| **R-2 (Stage 5)** | `gate-criteria-spec.md` § Gate G-BR malformed table delimiter (5 cells under a 6-column header) | **OPEN — operator judgment.** 6 such tables exist in the file; only 1 well-formed delimiter. Reconcile-don't-annotate argues for fixing the one being touched (1 line). **Not applied in slice 1** — the Stage-5 spec marked it conditional on approval that has not been recorded. See § Deviation Log DEV-7. | CHEAP / HIGH |

## Deviation Log

Deltas between the Stage-4 approved plan and this Commit-0 rendering. **The Stage-5 outcome wins where the two disagree.**

| # | Delta | Stage-4 position | Post-Stage-5 / Commit-0 position | Disposition |
|---|---|---|---|---|
| **DEV-1** | **Baseline advanced.** | Baseline pinned at `7943ae4a`; `release/governance-hardening` (#290) live at 33 commits ahead with two hunks disjoint from our regions; mitigation = record + re-check at Stage 9 G-PR9 (D-Baseline-GovHardening option B). | **#290 merged to `main` as `39284a2d`** between Stage-5 exit and Engineering Commit 0. The release branch is cut from post-merge `main`, so both contention rows are **absorbed by construction**. The predicted G-PR9 hit fired and is resolved without a rebase. `stage-04-planning.md` and `gate-criteria-spec.md` now carry #290's edits; **all region anchors in this plan are headings/tokens, not line numbers**, so no anchor was invalidated. | **Applied.** R-2 closed. G-PR9 still re-runs at Stage 9 for *new* siblings. |
| **DEV-2** | **ADR renumber cascade.** | #3581 → ADR-107; #3817 → ADR-105; #2719 → ADR-105. | The #290 merge landed ADR-105 (release) and ADR-106..109 (core). **All three allocations collide.** Next-free globally = **ADR-110**, taken by #3581 at this commit. #3817 and #2719 must re-derive at their own commits. | **Applied for #3581. Standing instruction issued for slices 3 and 5.** Registered as **R-12**. |
| **DEV-3** | **#3581's slice grew 4 files → 5.** | File Change Matrix listed 3 MODIFY + 1 NEW for #3581, with `hub-spoke-bridge.md` claimed only by #3819. | Stage-5 Revision 1 added `hub-spoke-bridge.md` **Procedure 0 Step 5** as the composition-lock emission point (operator-accepted R-6), making the boundary observable rather than inferred. This creates a **new within-release contention row** with #3819 — disjoint procedures (Procedure 0 Step 5 vs Procedure 1 + Procedure 7), disjoint anchor tokens, maximally separated slices (1 and 6). | **Applied.** Contention Map and File Change Matrix updated. |
| **DEV-4** | **#2719 AC3 retargeted.** | AC3 named `triage-design-rereview.md § Integration` — a heading that does not exist (0 `Integration` headings, 0 caveat-string hits over 504 lines). | Tier 1 `[ADJUST]` applied to #2719 at the Procedure 0 gate. The hub located **two** live caveat sites (one more than the spoke reported): `release-hub/SKILL.md` and `release-hub/references/milestone-readiness-checklist.md`. AC3 retargeted at both. **No defensive edit is authored to `triage-design-rereview.md`** to satisfy a stale assertion; its one optional bullet is a separate, justified change. | **Applied at Stage 4.** R-7 closed. |
| **DEV-5** | **Parallelization Map amended.** | Map recorded the *"sequence #3819 after #4184 lands"* mitigation and **one** `hub-spoke-bridge.md` contender. | The #4184 arm is **unavailable** (#301 has 0 scaffolded sub-tasks). The hub's adversarial verification further established that the spoke's escalation of #3709 to HIGH rested on a **false premise** — #300 also carries 0 sub-tasks and is not "ahead of us at Stage 5". Five contenders recorded, severity re-graded. | **Applied.** Tier 1 `[ADJUST]`; map re-dated. |
| **DEV-6** | **AC7 and AC8 added to #3581.** | Six ACs, all satisfiable by grepping the sub-window table or the G-BR gate. | The A6.5 adversarial review found a **cross-table consistency** gap no pre-existing AC could catch: a correct sub-window table plus a correct gate can together strand removals and re-sequences with no legal outcome path. **AC7** (the lock conjunct is addition-typed, not disposition-typed) and **AC8** (three-valued lock state; a zero probe result is never affirmative eligibility) added as Tier-1 `[ADJUST]`s. Both are **mandatory** for this slice. | **Applied to #3581.** |
| **DEV-7** | **R-2 delimiter repair — approved, carried by slice 2.** | Not in scope at Stage 4. | Stage-5 flagged the § Gate G-BR criteria table's delimiter row as malformed (5 cells under a 6-column header; systematic). The approval was **recorded at the Stage-5 briefing but not on a surface slice 1 could read**, so slice 1 correctly declined it and made **3** edits to `gate-criteria-spec.md`, not 4. The approval is real and **narrow — the G-BR delimiter row only**. Slice 2 carries it as a one-line change, which adds `gate-criteria-spec.md` to slice 2's file set. Census re-measured at the slice-2 baseline: **9** malformed delimiter rows in the file (6 under 6-column headers, 3 under 9-column headers) — more than the 6 Stage-5 reported, which counted the 6-column class only. **8 remain** and are out of scope. | **Applied in slice 2 (G-BR row only).** Remaining 8 route to a follow-up; see § Out of Scope. |
| **DEV-8** | **Stage-4 recorded no per-issue T1–T6 activation table.** | Stage 4 applied the class-based ALL bias and argued Stage-5 applicability in prose. | `planning-solutioning-handoff.md` § 4 defines a per-release evaluation table, and §§ 3.1/3.2 make the structural-premise and abstraction-altitude obligations travel from Stage 4 into the Stage-5 spec. Consequence here is nil (the SR-G determinations were discharged anyway), but **§ 7.2's conditional-fire predicate is keyed to a recording a class-biased Stage 4 never produces** — so on a release where the substance is less obvious, SR-G1..SR-G4 would silently not fire. | **Logged here per Stage-5 OSD-5.** Fix is a next-release intake item (reconcile the ALL-bias shortcut with § 7.2's fire predicate); not actioned in this release. |
| **DEV-9** | **#3827's design text and its ratified AC3 arm contradicted each other on edge classes.** | Stage-5 Revision 1's CDF-1 replacement sentence for § 2.4 reads *"…the edges that enter the dependency graph (§ Hard-vs-Soft Edge Classifier already excludes soft and file-contention edges)."* | That parenthetical **fails the AC3 second arm ratified at Collective Review scope-lock**, which requires `grep -cE "hard edge\|soft edge\|file-contention"` within § 2.4 to return **0** — § 2.4 must name no edge class of its own. The contradiction is internal to the design: CDF-1's own stated intent (ii) is *"a deferral to the consumer's own edge model by citation, not an enumeration authored in § 2.4"*, and Edit 2's delta 1 says *"the edge classes are named here, at the consumer surface, not in § 2.4."* **Resolved toward the ratified AC and the design's stated intent**: § 2.4 defers by citation to `dependency-analysis.md` § Step 4, which enumerates the classes. | **Applied in slice 4.** Arm verified **0** on the landed text. The enumeration lives once, at § Step 4. |
| **DEV-10** | **Stage-5 Revision 1's "§ 2.4 is net shorter" claim does not survive its own full delta set.** | Revision 1 asserted *"§ 2.4 net shorter than Revision 0"* on the strength of the CDF-1 substitution (*"one sentence replaces one sentence plus a paragraph-long qualitative exception"*). | Measured on the landed text against the Revision-0 block as specified: **one paragraph fewer** (property (3) deleted; 12 → 11 non-blank lines) but **+84 words / +534 characters**. The sub-swap Revision 1 counted is genuinely negative (≈ −27 words); Revision 1 then mandated **two additions in the same block** — PRF-3's replacement claim plus its named residual, and FMF-1's Guard-1 surface scope — and did not net them against the claim. Deletions ≈ 121 words, additions ≈ 205. **The content is exactly as Revision 1 specified; only its characterization of the resulting size is wrong.** Forcing the number down would require dropping a mandate the adversarial review imposed, so it was not done. | **Logged, not corrected.** Not a scope change — no content was added or removed beyond the Revision-1 delta set. Stage 8 should grade § 2.4 against the specified *content*, not against the withdrawn size claim. |
| **DEV-11** | **§ Step 4's flat-mode key is cited as `tie_breaker_key`, not as the design's "(priority-desc → issue-asc)".** | Stage-5 Revision 1 carried Revision 0's routing-table cell verbatim: *"the tie-breaker (priority-desc → issue-asc)"*. | Slice 3 (#3817) landed between design and implementation and **collapsed three undefined symbols for this one concept into a single defined `tie_breaker_key`**, stating in its own record that *"no fourth symbol is added."* Writing the parenthetical form would have re-introduced a fourth prose expression of the key the immediately-preceding slice had just retired, in the same file. § Step 4 now cites the defined symbol. | **Applied in slice 4** as a B3 minor adjustment. AC4's no-restatement arm is unaffected (`P1 *[>·—–-] *P2` within § Step 4 → **0**; whole-file `P1 before P2` → **1**, at its single home). |

## Out of Scope — Logged, Not Acted On

Surfaced during Stage 4 / Stage 5 survey. Each is an intake candidate; the operator triages.

- **`release/tools/check-bundle-refresh.sh` does not exist** (Stage-5 OSD-1). Cited by `release-process.md` § A7 trigger T4 and by `stage-04-planning.md` Phase A0. The `(or equivalent in-line bash)` escape makes it non-breaking today. Either ship the tool or drop the phantom citation.
- **`gate-criteria-spec.md` carries malformed table delimiter rows** (Stage-5 OSD-2 / R-2). Systematic and pre-existing. Re-measured at the slice-2 baseline: **9** rows whose delimiter cell count does not match its header — 6 under 6-column headers, plus **3 under 9-column headers that Stage-5's count missed**. The **G-BR row is repaired in this release** under the narrow operator approval recorded in DEV-7; the other **8 are out of scope** and route to a follow-up as a single mechanical repair.
- **`release-personas.md` § Stage 3 describes the A7 window as firing on "T1-T4"**; the live taxonomy is T1–T6 (Stage-5 OSD-3).
- **The Parallelization Map has no mechanism for enumerating *all* editors of a contended file.** It records the contenders someone happened to notice. This release found five `hub-spoke-bridge.md` editors where the map named one — a **detection-mechanism gap**, not a data-entry error. Check #3828 (in #306) for subsumption before filing.
- **`gate-criteria-spec.md` has no ID-collision guard.** Multiple in-flight milestones intend to add criteria to that file; the changelog convention records bumps but nothing prevents two branches claiming the same next criterion ID — the same class of problem the version-claim work solved for release numbers. **The ADR-number cascade in DEV-2 is the same failure shape one directory over**, and it *does* have a CI guard; the criterion IDs do not.
- **The ALL-bias shortcut and § 7.2's fire predicate are unreconciled** (Stage-5 OSD-5; see DEV-8).
- **`dependency-analysis.md` § Tie-Breaker Rule still states its leverage rejection unconditionally** — the deferred half of Stage-5 CDF-2. #3827 conditions the ordering key on the density verdict at § Step 4 and scopes § Leverage Analysis to match, but the third site sits inside #3817's region, which landed at slice 3. **Two adjacent hunks, both in #3817's territory:** (i) § Tie-Breaker Rule gains a leading scope clause naming both modes plus a parenthetical scoping the leverage rejection to the *tie-breaker* role specifically; (ii) the Kahn's BFS pseudocode's `ready.sort(key=tie_breaker_key)` gains a one-line note that this is the **flat-mode instantiation** of a key § Step 4 now makes mode-dependent — under a dense verdict the ready-set key is leverage-descending with `tie_breaker_key` resolving ties. Hunk (ii) is *incompleteness, not error*: the pseudocode is correct for the observed default and for the dormant arm's tie resolution, and it is strictly better than the pre-release state, where § Step 4's preference list contradicted the pseudocode outright with no condition attached. Deferred deliberately at Collective Review scope-lock, not overlooked; **INT-3″ arm (2) is the standing detector** and is expected to read FAIL at Stage 8 until this lands.
- **A sibling release edited a criterion body without a schema-version bump** (Stage-5 OSD-4), though the file's own convention treats a criterion-body refinement as a minor bump. Accepted-residual — it is that release's call — and it is the reason this plan says *bump relative to the value read at Commit 0*.

## Change Description

### Outcome

A milestone's composition is closed once it enters Stage 4 Planning, and the surfaces that decide bundle membership validate their own inputs before acting on them. After this release: newly-Approved theme-matching work routes to a *next* bundle rather than into a running one; the bundler re-checks its existing-milestone claim and re-runs subsumption at bundle time rather than trusting a filing-time verdict; the planner's priority tie-breaker executes instead of silently degrading; sequencing mode is chosen from measured dependency density rather than assumed; Stage-4 Phase A0 reads the Mode R briefing it already produced instead of re-deriving it; and release scaffolding creates the gate-stage sub-tasks the close-out depends on.

### Issues delivered

All six are **marked as closed at Stage 13** per the standard close-out. None is marked closed earlier, and no close-family verb is used against an issue number anywhere in this plan.

| Issue | Slice | Deliverable |
|---|---|---|
| #3581 | 1 | Composition lock at Stage-4 Planning entry — act-typed rule, three-valued lock state, emitted boundary marker, `G-BR5`, ADR-110 |
| #3822 | 2 | Bundle-time re-validation guard at Stage 3 (existing-milestone claim + fresh subsumption) |
| #3817 | 3 | Priority tie-breaker repaired — parser reads the body `### Priority` field |
| #3827 | 4 | Dependency-density → sequencing-mode selector (topology-first vs value/WIP-first) |
| #2719 | 5 | Stage-4 Phase-A0 cache-read of the Mode R briefing + currency guard |
| #3819 | 6 | Gate-stage (9/12/13) scaffold completeness + `post_gate_passage_proof` conditional fallback |

### Key decisions

The composition lock is **add-only**, not bidirectional — a symmetric freeze would make sub-windows B/C stricter than the post-Collective-Review hard lock, which sanctions descope-with-deviation-log at Stage 6. The lock binds the **act** (adding an issue), stated once at the definition surface, rather than the disposition bucket — gating the `amend` path itself would strand removals and pure re-sequences with no legal outcome. Lock state resolves **three-valued**, and the unmarked state is *not* eligibility: soundness comes from the state machine's default, not from probe coverage. There is **no hotfix carve-out** — the `hotfix` Release Class is already the faster emergency route. The priority signal is sourced from the issue **body**, not a label family, preserving `label-taxonomy.md` rule 5. The bundle-entry guard's consequence is **conferred by the gate that enforces it, not asserted by the check that emits it** — A1's own FAIL condition was amended so an undispositioned claim/subsumption finding excludes that *issue* from the A5 recommendation, which is weaker than the per-milestone stop the design first claimed and is the reach the file actually grants.

### Reversibility

**MODERATE / HIGH** at the release level. The diff reverts atomically via `git revert -m 1`; the protocol *semantics* do not, which is why the tier is not CHEAP. Per-slice tiers and revert-together constraints are in § Rollback Strategy.

### Downstream impact

`release-planner` and `release-hub` skill packages rebuild. The A7 outcome-path table gains a guard but no fifth path; the six-trigger taxonomy is unchanged in count. `gate-criteria-spec.md` takes a non-breaking minor schema bump for one additive criterion. Milestone #311 `bundle-rebundle-mechanics` overlaps this capability and should be revisited at close (R-9). Milestone #305 shares `automated-closeout.sh` and is the live contender for the `v4.06` slot (R-11).

### Cross-references

Stage 4 plan: #4508 · Stage 5 designs: #4509 (#3581, with Revision 1), #4513 (#3822), #4517 (#3817), #4521 (#3827), #4525 (#2719), #4529 (#3819) · Release-scoped gates: #4533 (Stage 9), #4534 (Stage 10), #4535 (Stage 11), #4536 (Stage 12), #4537 (Stage 13).
