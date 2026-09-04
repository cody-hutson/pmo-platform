<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
---
title: Release Plan — rules-mirror-delivered (the rules mirror is delivered, bounded and resolvable)
type: release-plan
plan_type: release
status: Executing
release: "{{RELEASE_VERSION}}"
milestone: rules-mirror-delivered
release_class: novel
reversibility: CHEAP rollback (additive; `git revert -m 1` on the release merge commit) / Confidence HIGH
---
# Release Plan — `rules-mirror-delivered`

**Topology:** D-C SINGLE — one release branch (`release/rules-mirror-delivered`), one PR, one merge; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** P0 fully-serial (operator-ratified) — Stage-6 slices route one at a time in Implementation-Sequence order on the single branch; force-push (including `--force-with-lease`) on the shared branch is prohibited under any multi-chip activity.
**Release class:** `novel` (D-3, operator-confirmed). Engagement density **Standard** · Stage 9 depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome-window **30-day**.
**Baseline pin:** `origin/main` = `ef008d6d9c32c5982feb943a1a916c4b80c7c321`, fetched fresh at Engineering Commit 0. The branch is cut from that SHA and the merge-base is identical to it (zero divergence at Commit 0).
**Domain-practice provenance:** `domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-03, domain: governance }` — Form X, sourcing-exempt, determined at Stage 4 Phase A1.5. Every add/edit row in the File Change Matrix targets internal pmo-platform governance, rules, pipeline specs, and deploy tooling; secondary domain `software` for `core/deploy/deploy.sh`, `core/deploy/tools/check-mirror-pair-parity.py`, and `release/tools/blast-radius.sh`. `governance` dominates by row count and by the release's Outcome clause. No Mode B→A upgrade is possible — the design depends on internal platform conventions rather than external practice, so the label travels unchanged.

> **Provenance.** This file transcribes the Stage-4 Release Planning output, reconciled to the operator's Procedure-0 plan-approval decisions (D-1 … D-4, D-Version) **and** to the sub-wave-1 Collective Review decisions (D-3, D-Version, D-C, D-6, D-E/D-E2, D-A, D-B, D-C1, D-C2, D-D). Where a later decision supersedes a Stage-4 determination the amended form is transcribed here and the supersession is named inline. Authored at Engineering Commit 0 by the first Engineering spoke (the mirror-pair parity card, sequence 1 of 4).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | `minor` — the durable determination. The concrete number binds only at the Stage-12 atomic claim (ADR-092); this file is authored **slug-primary / pre-claim** and carries the stamp token above rather than a digit. Recomputed at Engineering Commit 0 per the authoritative-version-selection procedure against five independently-controlled arms (origin tag refs · published GitHub Releases · the mainline release ledger read via `git show origin/main:` · `release/releases/plans/v4/` · the adapter's own `--dry-run`): `anchor()` = **v4.52**, floor for a `minor` bump = `(4, 53, 0)`, recomputed next-free = **v4.53**, free on all five. See § Verification Plan → *Commit-0 version re-verify*. |
| **Date Created** | 2026-09-04 (Friday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing |
| **Branch** | `release/rules-mirror-delivered` |
| **PR** | populated at Stage 6 PR assembly |
| **Milestone** | `rules-mirror-delivered` |

## Scope

### Release Outcome Statement

**AFTER** this release: the rules mirror is actually delivered to sessions, and what it delivers is bounded and resolvable — the corpus has published admission criteria and a measured size budget, its cross-tree links resolve from the mirror location, and every holder of the mirror-pair path set is machine-asserted to agree.

**BEFORE:** the mirror has a contract but no carrier; half of sessions never load it. The corpus it would carry is unbounded and unclassified, its cross-tree links dangle from the deployed location, and nothing asserts that the two path sets stay identical.

### Issues Included

| # | Issue | Title | Priority | Category | Size |
|---|-------|-------|----------|----------|------|
| 1 | #4738 | Nothing asserts that the two mirror-pair path sets stay identical | P2 | Protocol | M (4) |
| 2 | #4739 | Cross-tree links do not resolve from the mirror location | P2 | Protocol | M (4) |
| 3 | #6441 | The rules corpus has no admission criteria and no measured load ceiling | P2 | Protocol | L (8) |
| 4 | #4740 | The rules mirror has a contract but no carrier | P2 | Protocol | M (4) |

**Composition:** 4 cards · 20 raw pts · 23 effective (`round_half_up(20 × 1.15)`, `novel` class weight) — in the 15–25 pt band. Composition locked at Stage 4 Planning entry, 2026-09-03.

### Dependency Graph

Directional; edge hardness is not collapsed — a ship-gate is not a build blocker.

```
#4738 ──(soft: two-list cost)──▶ #6441 ──(GATE: must-not-ship-ahead)──▶ #4740
                                                                          ▲
#4739 ──────────────(soft: land-at-or-before)─────────────────────────────┘
```

#### Topologically Sorted Sequence

| Position | Issue | Priority | Status | Dependencies (in-release) | Edge Type |
|---|---|---|---|---|---|
| 1 | #4738 | P2 | bundled | (none — root) | — |
| 2 | #4739 | P2 | bundled | (none — root) | — |
| 3 | #6441 | P2 | bundled | #4738 (soft, cost-avoidance) | DEPENDS_ON |
| 4 | #4740 | P2 | bundled | #6441 (ship-gate), #4739 (ordering) | BLOCKS |

**Hard build-blocking edges: 0.** All three edges are soft or ship-gating; the sequence is chosen for cost-avoidance and coherence, not because any card cannot be built before another.

| # | Edge | Class | Blocking? | Evidence |
|---|---|---|---|---|
| E1 | #6441 → #4740 | release-gate | No — ship-gate only | #6441 § Dependencies states the carrier must not ship ahead of the budget and calls it a release-gate relationship, not a build blocker; #6441 AC7 requires the carrier to carry the recorded note. |
| E2 | #4739 → #4740 | soft / ordering | No | #4740 § Dependencies states the sequencing preference is to land the link fix at or before the carrier, so the first populated mirror is not full of dangling links. |
| E3 | #4738 → #6441 | soft / cost-avoidance | No | #6441 § Risks states that sequencing the corpus work before the parity assertion means removals must touch both lists by hand. |

#### Artifact Relationship Graph

| Source | Type | Target | Direction | Derived from |
|---|---|---|---|---|
| #4738 | GENERATES | core/deploy/tools/check-mirror-pair-parity.py | #4738 → file | File Change Matrix (add) |
| #4738 | GENERATES | core/ADRs/ADR-NNN-mirror-pair-holder-registration-contract.md | #4738 → file | File Change Matrix (add), D-C2 |
| #6441 | GENERATES | core/standards/rules-corpus-admission-standard.md | #6441 → file | File Change Matrix (add, CONDITIONAL) |
| #6441 | DEPENDS_ON | #4738 | #6441 → #4738 | body Dependencies (soft) |
| #4740 | DEPENDS_ON | #6441 | #4740 → #6441 | body Dependencies (ship-gate) |
| #4740 | DEPENDS_ON | #4739 | #4740 → #4739 | body Dependencies (ordering) |

#### Tie-Breaker Trace

- Positions 1 and 2 are both roots with no in-release dependency and identical priority (P2). Broken by cost-avoidance, not by issue number: #4738 lands the parity assertion **before** #6441 can remove a pair-set member, so a removal becomes a checked two-file edit rather than a remembered one (E3). #4739 is ordered second so its C4-clause edit lands on a paragraph that already carries #4738's obligation sentence, rather than colliding with it.

### File Change Matrix

Machine-readable — one path per line, `<path>  <VERB>`, path-first. A `CONDITIONAL:<token>` row is promoted to unconditional in the commit where its condition resolves; a row whose condition resolved **false** at the Collective Review has been moved to the § Release-wide explicit non-scope block below with its basis recorded, rather than left CONDITIONAL.

```
# ── #4738 — assert every holder of the mirror-pair path set agrees ────────────
core/deploy/deploy.sh                                          edit
core/deploy/tools/check-mirror-pair-parity.py                  add
core/ADRs/ADR-NNN-mirror-pair-holder-registration-contract.md  add
release/references/pipeline/stage-06-engineering.md            edit
release/tools/blast-radius.sh                                  edit
core/rules/harness-deployment.md                               edit
.github/deploy-check-ci.enforce                                edit
.github/workflows/deploy-check-ci.yml                          edit
core/deploy/allowlists/selftest-coverage-manifest.txt          edit
core/deploy/tools/README.md                                    edit

# ── #4739 — cross-tree links resolve from the mirror location ────────────────
release/references/pipeline/stage-06-engineering.md            edit
core/rules/doc-link-maintenance.md                             edit
core/standards/doc-link-maintenance-protocol.md                edit
core/rules/analysis-mandate.md                                 edit
core/rules/decision-time-adherence.md                          edit
core/rules/git-workflow.md                                     edit
core/rules/governance-files.md                                 edit
core/rules/harness-deployment.md                               edit
core/rules/rename-reference-cascade.md                         edit
core/rules/skill-deployment.md                                 edit
core/rules/operations-bridge.md                                edit

# ── #6441 — rules-corpus admission criteria + measured load ceiling ──────────
core/standards/rules-corpus-admission-standard.md              CONDITIONAL:new-standard-vs-extend-knowledge-architecture add
core/disciplines/knowledge-architecture.md                     edit
core/rules/analysis-mandate.md                                 edit
core/rules/decision-time-adherence.md                          edit
core/rules/doc-link-maintenance.md                             edit
core/rules/git-workflow.md                                     edit
core/rules/governance-files.md                                 edit
core/rules/harness-deployment.md                               edit
core/rules/operations-bridge.md                                edit
core/rules/rename-reference-cascade.md                         edit
core/rules/skill-deployment.md                                 edit
core/deploy/deploy.sh                                          edit
release/tools/blast-radius.sh                                  edit

# ── #4740 — the mirror carrier ───────────────────────────────────────────────
core/deploy/deploy.sh                                          edit
core/rules/harness-deployment.md                               edit
core/rules/operations-bridge.md                                edit
core/CLAUDE.md.template                                        edit
operations/CLAUDE.md.template                                  CONDITIONAL:second-carrier-lands-on-the-operations-anchor edit
release/references/pipeline/stage-12-execute.md                edit

# ── release-scoped ───────────────────────────────────────────────────────────
release/releases/plans/rules-mirror-delivered_RELEASE_PLAN.md   add
```

```
#### Read-only inputs
core/ADRs/ADR-085-canonical-link-resolution-rule.md            READ
core/hooks/block-autonomy-ceiling.sh                           READ
core/hooks/block-skill-direct-edit.sh                          READ
core/disciplines/corpus-curation.md                            READ
core/standards/canonical-skill-structure.md                    READ
core/standards/gate-efficacy-standard.md                       READ
core/standards/repo-host-adapter-versioning.md                 READ

#### Release-wide explicit non-scope
core/schemas/gate-criteria-spec.md                                          NOT EDITED
release/governance/release-process.md                                       NOT EDITED
core/rules/bypass-mode-readiness.md                                         NOT EDITED
core/rules/bypass-mode-readiness/_header.md                                 NOT EDITED
core/rules/bypass-mode-readiness/_cross-cutting.md                          NOT EDITED
core/rules/bypass-mode-readiness/block-*.md                                 NOT EDITED
core/deploy/tools/build-hook-registry.py                                    NOT EDITED
release/references/pipeline/stage-10-dry-run.md                             NOT EDITED
CHANGELOG.md                                                                NOT EDITED
release/releases/RELEASE_LOG.md                                             NOT EDITED
release/releases/RELEASE_INDEX.md                                           NOT EDITED
release/releases/RELEASE_DIGEST.md                                          NOT EDITED
release/releases/notes/                                                     NOT EDITED
```

**Non-scope basis, one line per row** — each is a condition that resolved *false*, recorded rather than left shielded behind an unfired predicate:

| Path | Basis |
|---|---|
| `core/schemas/gate-criteria-spec.md` | **R3 resolved NOT TAKEN.** A deploy check needs no `G*-NN` criterion row: the pre-merge roster's members are registered in the runner's own allowlist array and the workflow's gate-efficacy header, not by minting a criterion. The surface carries 169 referrers, so taking it would trip the Stage-4 escalation watch toward a `cross-cutting` re-class (26 effective pts, over the 25 ceiling). |
| `release/governance/release-process.md` | **D-A superseded.** Scope A excludes this file from the rules corpus by removing it from the mirror-pair array; its 162 links resolve in place from `release/governance/`. Removing it from the pair set costs **zero** edits to the file itself. |
| `core/rules/bypass-mode-readiness.md` and its `bypass-mode-readiness/` drop-ins | **D-4 superseded.** Scope A excludes the index from the rules corpus and retires the directory-shaped mirror loop, so the nested drop-in set is no longer mirrored and the AC3 extension has no subject. The generated-file hazard (hand-edits silently reverted at regeneration) is therefore not exercised by this release. |
| `core/deploy/tools/build-hook-registry.py` | Same basis — with the generated index out of the mirrored set, no generated-index link rewrite is required at source. |
| `CHANGELOG.md`, `release/releases/RELEASE_{LOG,INDEX,DIGEST}.md`, `release/releases/notes/` | Release-corpus governance artifacts land via the **Stage 12** and **Stage 13 chore PRs**, never the release PR. Engineering ships content only. |

> **Re-promotion is permitted and must carry its basis.** If an owning card's Stage 5 finds that a non-scope row must be edited after all, it is promoted into the unconditional set in the commit that edits it, with the real basis recorded — never edited while still shielded by a predicate that never fired.

**New-executable companion obligation: DOES NOT FIRE.** The matrix carries **no `add` row for a `*.sh`**. The one added executable is `core/deploy/tools/check-mirror-pair-parity.py`, a Python primitive invoked through the already-allowlisted interpreter. Measured at the baseline: `core/config/allowlists/script-execution-allowlist.txt` carries **50** rows naming `core/deploy/tools/`, **all `.sh`**, and **zero** rows naming any `.py` script (the single `.py` string in that file is prose inside a comment block, not a row). The working precedent is `check-extraction-contract.py`, which is absent from the allowlist and executes successfully. No allowlist row and no CI wiring row enter the matrix for it. **CI wiring statement:** the primitive is executed by `core/deploy/deploy.sh` on both the `--check` lifecycle surface and the `--check-required-subset` pre-merge surface; the latter is run by the `deploy-check-ci` workflow. It is not invoked directly by any CI job.

### File Contention Map

| File | Issues | Intent Mix | Severity | Recommendation |
|---|---|---|---|---|
| `core/deploy/deploy.sh` | #4738, #6441, #4740 | edit×3 | MULTI-WAY | Serial in sequence order 1 → 3 → 4. Parity assertion first, then the member removals it now guards, then the producer. |
| `core/rules/harness-deployment.md` | #4738, #4739, #6441, #4740 | edit×4 | MULTI-WAY | Hottest doc. Serial per sequence; each card appends to a distinct section — no move, renumber or restructure by any card. |
| `core/rules/doc-link-maintenance.md` | #4739, #6441 | edit×2 | BINARY | Serial, #4739 then #6441. |
| `core/rules/operations-bridge.md` | #4739, #6441, #4740 | edit×3 | MULTI-WAY | Serial, #4739 → #6441 → #4740. |
| `core/rules/*.md` — the other 6 retained members | #4739, #6441 | edit×2 | BINARY | Serial, #4739 (links) then #6441 (frontmatter contract). |
| `release/tools/blast-radius.sh` | #4738, #6441 | edit×2 | BINARY | Serial, #4738 (markers, no functional change) then #6441 (member removal). |
| `release/references/pipeline/stage-06-engineering.md` | #4738, #4739 | edit×2 | BINARY | **Same paragraph.** Serial #4738 then #4739; CIAC-4 asserts the merged result is coherent. |

**Parse-quality:** 4 issues parsed cleanly · 0 deferred · 0 parse-failed.

### Cross-Milestone Dependency Validation

#### G3-07 Status

`PASS — 3 dependency edge(s) checked, 0 cross-milestone violations.` All three edges are internal to this bundle; the one out-of-bundle content dependency named in #6441's body points at an issue moved to the successor slice, which is a forward edge from a *later* milestone and therefore not a violation of this one.

#### Violations

None — enumerated over all three in-release edges (E1, E2, E3) plus the one out-of-bundle body-declared edge; zero cross-milestone gap violations found.

#### Resolved Edges (B is Done)

N/A — enumerated over the three in-release edges; none has a target already Done in a closed milestone.

#### Registered Exceptions

N/A — enumerated over the violation set (empty); no exception was needed or registered.

### Bundle Refresh State

**Refresh trigger:** T4 (Stage 4 boundary), preceded by a 2026-09-01 readiness sweep and a 2026-09-02 operator-approved re-bundle.
**Churn:** composition moved from 8 cards / 28 raw pts to 4 cards / 20 raw pts (23 effective). `theme_preserved: TRUE`.
**Outcome path selected:** re-bundle.
**Decision recorded:** milestone description `[BUNDLE AMENDMENT — 2026-09-02, operator-approved re-bundle]` block; Composition Lock at Stage 4 Planning entry, 2026-09-03.
**Refresh-check date:** 2026-09-03.

**Detected since last refresh-check:** the re-bundle moved #5655 to the successor slice (both its prerequisites ship in this core), moved #4579 out (serves no Outcome clause), returned #4982 to triage, and detached epic #6442 from the delivery slice while leaving it as the cross-milestone frame. No membership change since the Composition Lock.

### Exclusions

- **#5655** — deferred to the successor slice; both of its prerequisites ship in this core, so it re-bundles cleanly at the next cycle.
- **#4579** — moved out; serves no clause of this release's Outcome Statement.
- **#4982** — moved out; its pin-or-close question returns to triage.
- **#6442** — epic detached from the delivery slice; remains the cross-milestone frame, labels untouched.

## Implementation Sequence

Single release branch, **fully serial**. One Engineering chip at a time; the next chip waits until the prior commit lands on the release branch.

| Order | Issue | Size | Why here | Exit condition before the next chip |
|---|---|---|---|---|
| 1 | #4738 | M (4) | E3. Lands the parity assertion **before** #6441 can remove a pair-set member, so any removal is a checked two-file edit rather than a remembered one. Also the most self-contained card, which puts a green check on the release's shared surface early. | The parity check exists, reports PARITY at the delivered holder count, and FAILs under single-entry injection into any holder. |
| 2 | #4739 | M (4) | E2. Rewrites the cross-tree links to the canonical form and repairs the C4 clause **before** the carrier makes those links live. Ordered after #4738 so the shared C4 paragraph already carries the parity-obligation sentence. | Zero links resolving from only one of the two locations across the retained corpus; both link checkers agree. |
| 3 | #6441 | L (8) | E1 + E3. Classification, admission test, size budget, frontmatter contract. Runs after #4738 so a removal verdict is machine-asserted, and after #4739 so the frontmatter edits do not collide with the link rewrite in the same files. | Budget published; retained set measured at-or-below it. |
| 4 | #4740 | M (4) | Terminal by E1 + E2. The carrier ships last, over a corpus that is now bounded, resolvable, and parity-asserted. | Mirror populated by deploy; `never populated` distinguishable from `in sync`; the operations branch loads the subset. |

### Issue #4738: Nothing asserts that the two mirror-pair path sets stay identical

**Change Specification:**

- **Files modified:** `core/deploy/deploy.sh`, `release/tools/blast-radius.sh`, `core/rules/harness-deployment.md`, `release/references/pipeline/stage-06-engineering.md`, `.github/deploy-check-ci.enforce`, `.github/workflows/deploy-check-ci.yml`
- **Files added:** `core/deploy/tools/check-mirror-pair-parity.py`, `core/ADRs/ADR-NNN-mirror-pair-holder-registration-contract.md`
- **Change description:** The source-side mirror-pair path set is held independently by more than one artifact, and their agreement was asserted nowhere. This card makes the invariant **arity-general from the first line**: every holder wraps its path set in an in-band `mirror-pair-set:` marker pair declaring its own separator and field index, a new Python primitive discovers holders by corpus scan and diffs each holder's extracted set against the union of all of them, and a new deploy check consumes the primitive's TSV on two surfaces. Adding holder N+1 costs **one marker pair inside the new holder and zero change to the check**. The in-band form is chosen over a central registry because a registry is itself a list of the same kind — a fourth artifact that can desynchronise, recursively re-creating the defect. The check ships **warn-mode initial** and joins the pre-merge required-subset roster, because the card's own root cause is that a one-sided edit escaped both the automated check surface *and* PR review, and the post-merge lifecycle surface alone does not close that.
- **Failure semantics:** four-valued and surface-dependent — `PARITY` / `DIVERGENT` / `UNPARSEABLE` / `NOT-EVALUATED` — plus a **vacuity guard**: fewer than two discovered holders FAILs rather than passing, because "all holders agree" over one holder is vacuously true and that is exactly the false-green the check exists to prevent. `NOT-EVALUATED` is never emitted on the pre-merge surface, where every holder is a tracked file and an unreadable holder is a checkout defect rather than a measurement outage.
- **Acceptance criteria:** AC1–AC5 per the issue body (extraction-diff across both files; passes at the delivered holder count; single-entry injection FAILs naming entry and side; per-side delimiter handling with a cross-extractor mutation test; the prose invariant comment cites the asserting check by name).
- **Estimated complexity:** Medium.
- **Dependencies:** None — sequence root.

### Issue #4739: Cross-tree links do not resolve from the mirror location

**Change Specification:**

- **Files modified:** the retained rule-corpus members carrying cross-tree links, `core/rules/doc-link-maintenance.md`, `core/standards/doc-link-maintenance-protocol.md`, `release/references/pipeline/stage-06-engineering.md`
- **Change description:** Author the canonical mirror-pair link-form rule at `core/standards/doc-link-maintenance-protocol.md` and its rule-mirror (D-B — the rule home is now selected, so the Stage-4 CONDITIONAL is promoted), rewrite the cross-tree links in the retained corpus to that form, and repair the C4 clause in the Stage-6 spec: correct the self-pair expression, drop the retired bare module-prefix mandate, and cite the canonical rule rather than restating its rationale.
- **Inherited disposition — 4 links that will dangle.** Under Scope A the `bypass-mode-readiness.md` index leaves the mirrored corpus, and **4 links across 3 retained members point at it**: `core/rules/doc-link-maintenance.md` lines 119 and 158, `core/rules/harness-deployment.md` line 102, `core/rules/skill-deployment.md` line 304. Their disposition is #4739's to decide at its Stage 5 — recorded here so it is not rediscovered as new scope.
- **Coherence contract on the shared C4 paragraph:** on arrival the mirror-pair sub-block carries **two** sentences. Sentence 1 states the link form; sentence 2 states the path-set parity obligation and was authored by #4738. **Edit sentence 1 and its `See …` pointer; leave sentence 2 untouched.** The two are non-overlapping by construction — sentence 2 makes no link-form claim and cites the check by its stable id rather than by number — so the merged paragraph carries no restatement and no contradiction.
- **Acceptance criteria:** AC1–AC5 per the issue body. **D-4 is superseded:** the Stage-4 extension of AC3 to the mirrored nested drop-in set has no subject, because Scope A retires the directory-shaped mirror loop and the nested set is no longer mirrored.
- **Estimated complexity:** Medium.
- **Dependencies:** None — sequence root; ordered second by the tie-breaker.

### Issue #6441: The rules corpus has no admission criteria and no measured load ceiling

**Change Specification:**

- **Files modified:** `core/disciplines/knowledge-architecture.md`, the nine retained `core/rules/*.md` members (frontmatter contract), `core/deploy/deploy.sh`, `release/tools/blast-radius.sh`
- **Files added:** `core/standards/rules-corpus-admission-standard.md` (CONDITIONAL — new standard versus a third axis on the existing corpus-admission protocol; resolved at #6441's Stage 5)
- **Change description:** Publish the admission test for the rules directory, apply it, and make the resulting size budget **verifiable at build time** rather than only observable at runtime.
- **Scope A — CONFIRMED, and it requires THREE acts, not two.** The admission test retains **9** members: the nine `core/rules/*.md` files carrying `type: rule`. Excluded: `release/governance/release-process.md` and `core/rules/bypass-mode-readiness.md`. An adversarial re-test confirmed the index exclusion (admission arms A1 and A3 fail outright). The three acts:
  1. remove `release/governance/release-process.md` from the mirror-pair array,
  2. remove the `bypass-mode-readiness.md` index from the mirror-pair array,
  3. **retire the directory-shaped mirror loop** in `core/deploy/deploy.sh` that enumerates `core/rules/bypass-mode-readiness/*.md` and mirrors each drop-in 1:1.

  **Act 3 is load-bearing and was not in the Stage-4 reading.** Hub-measured: removing the two array entries while that loop still runs leaves **277,655 B = 136%** of the **204,800 B** ceiling — a budget breach. Retiring the loop as well reaches **144,184 B = 70%**. Acts 1 and 2 alone do not deliver the bounded corpus the Outcome Statement claims.
- **Acceptance criteria:** AC1–AC7 per the issue body.
- **Estimated complexity:** High.
- **Dependencies:** #4738 (soft, cost-avoidance) — its removals become checked two-file edits once the parity assertion lands.

### Issue #4740: The rules mirror has a contract but no carrier

**Change Specification:**

- **Files modified:** `core/deploy/deploy.sh`, `core/rules/harness-deployment.md`, `core/rules/operations-bridge.md`, `core/CLAUDE.md.template`, `release/references/pipeline/stage-12-execute.md`; `operations/CLAUDE.md.template` CONDITIONAL on the second carrier landing on the operations anchor
- **Change description:** Ship the producer. No file in the repository currently writes the workspace rules mirror, which is why the advertised "re-run the deploy to restore" remedy cannot work. The carrier populates the mirror at deploy time and makes `never populated` distinguishable from `in sync`. The second carrier extends the same reach to operations-rooted sessions.
- **Holder-registration contract binds this card.** **Preferred:** reuse the existing pair array in place — no third holder exists and nothing can desynchronise. **If** the carrier declares its own copy set, it MUST carry a `mirror-pair-set:` marker pair with a distinct holder id. **Either way, record which branch was taken** — CIAC-1's grading depends on it (D-D).
- **Boundary constraint:** the routing change lands in `core/CLAUDE.md.template` (tracked, unconstrained) and reaches the deployed charter through deploy — never by editing the deployed file, which is Tier-0 floored. The same applies to the operations anchor.
- **Telemetry obligation:** the `deploy-rules-mirror` telemetry exclusion is deliberately dark *because no producer exists*, with an in-tree instruction to re-evaluate it when the producer ships. This card ships that producer, so re-evaluating the exclusion belongs in this card's change spec — otherwise the release ships a producer whose deploys emit no telemetry and leaves a self-invalidating comment in the tree.
- **Acceptance criteria:** AC1–AC5 per the issue body.
- **Estimated complexity:** Medium.
- **Dependencies:** #6441 (ship-gate), #4739 (ordering).

### Agent-Editability Read

**Derivation** — controls read at commit `ef008d6d`:

- **Tier-0 floor:** `core/hooks/block-autonomy-ceiling.sh` — **2** `case` blocks whose arms invoke `always_block "BLOCK-AUTONOMY-001"`. Block 1 is anchored to the primary root and names the deployed charter, the deployed operations anchor, the deployed governance and protocol files, `settings.json`, `.claude/hooks/*` and `.claude/rules/*`. Block 2 is anchor-free (guarded by the platform-worktree test) and names the three governance basenames `*/CLAUDE.md`, `*/OPERATIONS.md`, `*/RELEASE_PROTOCOL.md`. **Projection + tracked-index filter:** the `.claude/*` arms project to paths the repository tracks zero of and are discarded for repo-relative work; the repository tracks no file named `CLAUDE.md` (the charter surfaces are tracked as `*.template`). **Tier-0 floor = any tracked path whose basename is `CLAUDE.md`, `OPERATIONS.md`, or `RELEASE_PROTOCOL.md`.**
- **Sanctioned-session gate:** `core/hooks/block-skill-direct-edit.sh` — the skill-scope pattern matches `<module>/skills/<name>/(SKILL.md|references/*.md)`; the exemption list is resolved at the **deployed** location, present with 1 entry. The in-repo copy is not the file the hook reads.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| #4738 | `core/deploy/deploy.sh` | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #4738 | `core/deploy/tools/check-mirror-pair-parity.py` | no | no | unconstrained | ″ | ″ |
| #4738 | `core/ADRs/ADR-NNN-*.md` | no | no | unconstrained | ″ | ″ |
| #4738 | `release/tools/blast-radius.sh` | no | no | unconstrained | ″ | ″ |
| #4738 | `core/rules/harness-deployment.md` | no | no | unconstrained | ″ | ″ |
| #4738 | `release/references/pipeline/stage-06-engineering.md` | no | no | unconstrained | ″ | ″ |
| #4738 | `.github/deploy-check-ci.enforce` | no | no | unconstrained | ″ | ″ |
| #4738 | `.github/workflows/deploy-check-ci.yml` | no | no | unconstrained | ″ | ″ |
| #4739 | `core/rules/*.md` (9 retained), `core/standards/doc-link-maintenance-protocol.md`, `release/references/pipeline/stage-06-engineering.md` | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #6441 | `core/standards/rules-corpus-admission-standard.md` (add), `core/disciplines/knowledge-architecture.md`, `core/rules/*.md`, `core/deploy/deploy.sh`, `release/tools/blast-radius.sh` | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #4740 | `core/deploy/deploy.sh`, `core/rules/operations-bridge.md`, `core/rules/harness-deployment.md`, `release/references/pipeline/stage-12-execute.md` | no | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #4740 | `core/CLAUDE.md.template` | no — basename is `CLAUDE.md.template`, which the `*/CLAUDE.md` arm does not match | no | unconstrained | ″ | ″ |
| #4740 | `operations/CLAUDE.md.template` (CONDITIONAL) | no — same reason | no | unconstrained | ″ | ″ |

**Every row is `unconstrained`, and that is the informative output** — the discriminating negative is what makes the flag mean something when it fires. Two adjacent Tier-0 boundaries are named because the release runs directly alongside them:

- **The deployed charter IS Tier-0 floored.** The carrier's routing change must land in the tracked template and reach the deployed file through deploy, never by editing the deployed file.
- **The deployed rules directory — the carrier's own output surface — IS Tier-0 floored.** The carrier's writes are performed by the deploy script, not by an agent write payload, so they fall outside both controls per the generated-file clause and are classed with their source. The operational consequence is real: end-to-end verification of the carrier requires running the deploy against a live workspace whose rules directory no agent may write directly. Stage 7 plans that as a script-mediated observation, not an agent write.

## Risk Register

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|
| R-1 | **The carrier could become an unasserted third holder of the pair-set path list.** A carrier that copies a set diverging from the enforced array reintroduces the silent desync this release exists to close. | High if unaddressed | High | Structurally closed: the parity check is arity-general and holders self-register in-band. The carrier's preferred shape reuses the existing array (no third holder); if it declares its own set it MUST carry a marker with a distinct holder id. **CIAC-1** grades it. | Stage 5 / 6 |
| R-2 | **A new holder authored WITHOUT the marker is invisible to the check.** The residual of in-band registration: no discovery mechanism removes it without guessing — 75 files name two or more of the source paths, so a heuristic arm needs a tuned threshold plus an exemption register. | Low | Medium | Accepted, and closed **contractually** rather than heuristically: the holder-registration ADR makes marker-carrying the contract, with the carrier as its first bound consumer. A heuristic candidate-detection arm is filed as a successor observation. | Stage 6 (#4738) |
| R-3 | **The check number is a collision surface.** The next-free deploy check number is a perishable reading; a sibling release landed a check mid-flight during the prior release, invalidating a stage-old reading. | Medium | Low | Re-derived at Engineering Commit 0 from the live roster rather than transcribed, and re-verified at Stage 9. The Stage-6 spec sentence cites the check by its stable id, never by number, so the prose is immune to renumbering. | Stage 6 / 9 |
| R-4 | **Same-file contention with an in-flight sibling on the deploy script.** Two open release PRs edit `core/deploy/deploy.sh`. | Medium | Low | **Measured disjoint at launch:** the sibling hunks and this release's regions do not intersect. Ordinary rebase; re-measure at Stage 9. | Stage 6 / 9 |
| R-5 | **The budget is enforced against a directory no session loads until the carrier ships.** A budget established before the carrier ships is enforced against nothing, and will not hold once the carrier lands. | Medium | High | The budget must be a **build-time** assertion in the check suite, not a runtime observation. **CIAC-3** grades the carrier's delivered payload against it. | Stage 5 (#6441) |
| R-6 | **Act 3 of Scope A is easy to miss.** Removing the two array entries without retiring the directory-shaped mirror loop leaves 136% of the ceiling — a budget breach that reads like a completed scope. | Medium | High | Named as a numbered act in this plan's #6441 change spec with both byte figures recorded, so the partial form is visibly incomplete rather than plausibly done. | Stage 5 / 6 (#6441) |
| R-7 | **Reclassifying a large corpus member could become a rename-reference-cascade event.** The two largest members are referenced by name across the corpus. | Low | High | **Structurally avoided by Scope A:** exclusion is achieved by removing array entries, not by relocating files. Zero edits to either excluded file. If a later verdict relocates one, the rename-reference-cascade rule governs and the cascade enters the matrix explicitly. | Stage 5 (#6441) |
| R-8 | **Version-slot collision.** The last several releases each lost a slot mid-run to a sibling merge. | Medium | Low | Structural: this plan carries the stamp token, never a baked number. Re-run the authoritative-version-selection procedure at Engineering Commit 0 (done — see § Verification Plan) and again at Stage 12. `anchor + 1` is the rule; do not pre-emptively pick a higher number. | Stage 6 / 12 |
| R-9 | **A populated mirror changes agent behavior at the next session start.** Combined with the frontmatter contract, the change to what loads at launch is the release's whole point — and is observable immediately. | High (by design) | Medium | Land the budget before the carrier so the first populated mirror is bounded. Stage 13 outcome-window 30-day. Recovery from a bad state is a re-deploy from reverted source. | Stage 12 / 13 |
| R-10 | **The second carrier crosses the operations/engineering boundary.** The operations workspace is deliberately outside the tracked repo; its deployed anchor is Tier-0 floored. | Medium | Medium | Design the second carrier as **template + deploy** — edit the tracked template, let deploy render the anchor — never an agent write to the deployed anchor. | Stage 5 (#4740) |

**Rollback strategy.** Single release branch merged as a two-parent merge commit, so `git revert -m 1 <merge-sha>` restores the pre-release corpus in one operation. The one non-file-reversible surface is the **deployed workspace mirror**: reverting the source does not un-populate it. Recovery is a re-run of the deploy from the reverted source — a second, operator-run action, not folded into the revert. Overall release reversibility: **CHEAP / HIGH**.

## Delivery Strategy

| Aspect | Decision |
|---|---|
| **Implementation approach** | Sequential (dependency-ordered), P0 fully-serial |
| **Commit strategy** | Engineering Commit 0 (this plan file), then commit-per-coherent-slice within each card, in Implementation-Sequence order |
| **Review approach** | Single PR for the entire release, created draft at Stage 6 and transitioned to ready at the Stage 9 gate |
| **Deployment mechanism** | Git merge + deploy-mediated propagation of `core/rules/` to the workspace mirror |
| **Stacked-base cleanup posture** | N/A — Option A (no stacked-base waves planned under SINGLE topology) |

## Stage Applicability Matrix

| Issue | 5 Solutioning | 6 Engineering | 7 Dev Test | 8 QA | 9 Plan Review | 10 Dry Run | 11 Snapshot | 12 Execute | 13 Close |
|---|---|---|---|---|---|---|---|---|---|
| #4738 | APPLY | APPLY | APPLY | APPLY | APPLY (rel) | **COMPRESSED** | **COMPRESSED** | APPLY (rel) | APPLY (rel) |
| #4739 | APPLY | APPLY | APPLY | APPLY | ″ | ″ | ″ | ″ | ″ |
| #6441 | APPLY | APPLY | APPLY | APPLY | ″ | ″ | ″ | ″ | ″ |
| #4740 | APPLY | APPLY | APPLY | APPLY | ″ | ″ | ″ | ″ | ″ |

*(rel) = release-scoped singleton, not per-issue.*

**Stages 10 and 11 are COMPRESSED (D-6), not skipped.** Both are git-native on this release: the PR diff **is** the dry-run (Stage 10) and git history **is** the pre-change snapshot set (Stage 11). Routing is therefore **Stage 9 GO → Stage 12 Execute** with no intervening spoke, and no `stage-10` or `stage-11` sub-task exists. This is the Claude Code path's standing substitution for the Cowork path's per-step diff preview and `_snapshots/` writes; it removes no review, it relocates it into the PR.

**Stage 5 applied to all four — no skips, each for its own reason:** #6441 carried two `[ASSUMPTION – CONFIRM]` items whose stated owner was Solutioning; #4740 explicitly deferred the second carrier's shape; #4739's AC2 requires citing a canonical rule that did not exist; and #4738's arity decision was load-bearing because a third holder ships in the same release.

**Stages 7 and 8 apply to all four** — every card has functional impact: #4738 adds an executing check, #4740 adds a deploy-path producer and changes the mirror check's verdict semantics, #6441 changes what loads at session start, #4739 changes link resolution on both checker surfaces.

## Verification Plan

### Commit-0 version re-verify

Run at Engineering Commit 0, spanning the plan-file write and its commit, against freshly-fetched authoritative host state (`git fetch --tags origin && git fetch origin main`). The ledger arm was read via `git show origin/main:` — never the worktree copy.

| Arm | Denominator | `v4.53` (candidate) | `v4.52` (sensitivity) | specificity control |
|---|---|---|---|---|
| origin tag refs | 53 `v4.x` tags | **0** | 1 | `v4.999` → 0 |
| published GitHub Releases | 194 | **0** | 1 | `v4.99` → 0 |
| mainline release-ledger version rows | 196 table rows | **0** | 1 | `v4.99` → 0 |
| `release/releases/plans/v4/` files | 53 | **0** | present | — |
| adapter `--dry-run` (fifth, corroborating) | — | prints `v4.53`, exit 0 | — | — |

`anchor()` = **v4.52** · floor for a `minor` bump = `(4, 53, 0)` · recomputed next-free = **v4.53** · planned value = **v4.53**. Not in the claimed set **and** equal to the recomputed next-free ⇒ **PROCEED**. Binding remains forward-only at the Stage-12 atomic claim; re-verify there.

**Stamp-manifest assertion (step 3b):** `release/tools/claim-version.sh --verify-stamp rules-mirror-delivered` run after the plan-file write and before its commit; exit 0 required. Result recorded in § Verification Evidence.

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|---------------------|-----------------|
| #4738 | AC-1 | `test -f core/deploy/tools/check-mirror-pair-parity.py` | The parity primitive exists at its declared canonical path |
| #4738 | AC-2 | `grep -c 'mirror-pair-set: BEGIN' core/deploy/deploy.sh release/tools/blast-radius.sh` | Each holder file carries exactly one BEGIN marker; the check reports PARITY at the delivered holder count |
| #4738 | AC-3 | `grep -q 'absent from holder' core/deploy/tools/check-mirror-pair-parity.py` | The divergence message names both the path and the holder it is missing from |
| #4738 | AC-4 | `grep -q 'sep=' core/deploy/deploy.sh` | Each holder declares its own separator in-band, so the extractor is per-holder rather than shared; the primitive's self-test covers the swapped-separator mutation and fails rather than passing vacuously |
| #4738 | AC-5 | `grep -q 'mirror-pair-parity' core/deploy/deploy.sh` | The prose invariant comment cites the asserting check by its stable id |
| #4739 | AC-1 | `test -f core/standards/doc-link-maintenance-protocol.md` | The canonical mirror-pair link-form rule has a named home |
| #4739 | AC-2 | `grep -c 'workspace-root fallback' release/references/pipeline/stage-06-engineering.md` | Zero · control: the same instrument for the cited canonical rule's filename in the same file must return non-zero |
| #4739 | AC-3 | `grep -c ']\(\.\./' core/rules/git-workflow.md` | Zero relative cross-tree links remain in the retained corpus members |
| #4739 | AC-4 | `grep -q 'claude/rules' release/references/pipeline/stage-06-engineering.md` | The C4 clause names a real mirror pair rather than a self-pair |
| #4739 | AC-5 | `bash core/deploy/deploy.sh --check` | Doc-link integrity (Check 14) reports no unresolved internal link in the modified files |
| #6441 | AC-1 | `test -f core/standards/rules-corpus-admission-standard.md` | The admission test is published at a named canonical path |
| #6441 | AC-2 | `grep -q 'type: rule' core/rules/git-workflow.md` | The frontmatter contract is applied to a retained corpus member |
| #6441 | AC-3 | `grep -c 'release/governance/release-process.md' core/deploy/deploy.sh` | Zero — the excluded member is gone from the mirror-pair array |
| #6441 | AC-4 | `grep -c 'core/rules/bypass-mode-readiness.md:' core/deploy/deploy.sh` | Zero — the excluded index is gone from the mirror-pair array |
| #6441 | AC-5 | `grep -c 'core/rules/bypass-mode-readiness/\*.md' core/deploy/deploy.sh` | Zero — act 3, the directory-shaped mirror loop, is retired |
| #6441 | AC-6 | `grep -q '204800' core/standards/rules-corpus-admission-standard.md` | The published budget states a measured byte ceiling |
| #6441 | AC-7 | `grep -q 'budget' core/rules/harness-deployment.md` | The carrier's ship-gate note on the budget is recorded |
| #4740 | AC-1 | `grep -c 'claude/rules' core/deploy/deploy.sh` | A producer writes the workspace rules mirror; the copy-op count is no longer zero |
| #4740 | AC-2 | `grep -q 'never populated' core/deploy/deploy.sh` | `never populated` is distinguishable from `in sync` in the mirror check's verdict |
| #4740 | AC-3 | `grep -q 'rules' core/CLAUDE.md.template` | The charter template routes sessions to the mirrored rules set |
| #4740 | AC-4 | `grep -q 'deploy-rules-mirror' core/deploy/deploy.sh` | The telemetry exclusion is re-evaluated now that the producer ships |
| #4740 | AC-5 | `grep -q 'mirror' release/references/pipeline/stage-12-execute.md` | The deploy-output surface records the carrier's execution step |

**AC baseline** — per-issue criterion counts as read at plan time, and the commit read against:

`ac_baseline: { #4738: 5, #4739: 5, #6441: 7, #4740: 5, read_at: ef008d6d }`

Ordinals are positional. A count that no longer matches this baseline is the mechanical signal to re-bind the per-issue verification rows rather than to silently re-index them.

### Release-Level Verification

- [ ] **File Integrity** — every declared unconditional ADD in the File Change Matrix is present in the merged diff.
- [ ] **Content Correctness** — the parity check reports PARITY at the delivered holder count; the published budget's ceiling is met by the retained corpus.
- [ ] **Cross-Reference Validity** — `core/deploy/deploy.sh --check` Check 14 reports no unresolved internal markdown link in any modified `.md` file.
- [ ] **Skill Invocation** — N/A — enumerated over the File Change Matrix; no rostered skill's `SKILL.md` or `references/` is edited by any card, so no `.skill` package rebuild is owed and the package-freshness gate has no subject.
- [ ] **Output Contract Compliance** — the parity primitive's TSV is consumed through the residual-row path, so an unrecognized class value is reported as a finding rather than silently filtered to nothing.

## Cross-Issue Acceptance Criteria

Four release-scoped cohesion constraints. Graded at **Stage 9 QC3.5 / Phase A3.6** on the merged PR.

- [ ] **CIAC-1 (#4738 × #4740 × #6441 on the mirror-pair source-path set):** every holder of the mirror-pair source-path set agrees, and the asserting check is written so that adding a further holder is a one-line change — the "all holders agree" framing rather than "these two agree". *Shared surface:* the source-side mirror-pair path set. *Method:* `python3 core/deploy/tools/check-mirror-pair-parity.py --self-test` — the primitive's holder-count-independent arity case is the load-bearing arm, and it must include a three-holder divergence case that FAILs naming both the path and the holder. **Arity amendment (D-D — the grading contract, deferred at sub-wave 1 and resolved at #4740's Stage 5):** the literal "≥3 holders" method is unsatisfiable under the carrier's preferred shape, where the carrier reuses the existing array and no third holder exists. Grade the disjunction instead: the check FAILs under single-entry injection into **any** registered holder, **AND** either (a) three or more holders are marker-registered and the injection arm runs against the carrier, **or** (b) the carrier is recorded as reusing an existing holder's array, evidenced by the absence of a second path list in its diff. A grader reading the un-amended literal form would record a false NOT-MET against a correctly-built release. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-2 (#4739 × #4740 on the deployed mirror tree):** after the carrier populates the mirror, every cross-tree link inside a mirrored rule file resolves **from the mirror location**, not only from the source location. *Shared surface:* the deployed rules tree the carrier creates and the links must survive. *Method:* `bash core/deploy/deploy.sh --check` with the link checker run against the populated mirror; count of links resolving from source-but-not-mirror expected **0** · control: the same instrument against the pre-release link form on the same populated tree must return a **non-zero** count, so a zero is a real absence rather than an unresolvable target. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-3 (#6441 × #4740 on the delivered payload):** the payload the carrier actually copies is at or below the session-start size budget the admission standard publishes — the ship-gate relationship made testable rather than asserted. *Shared surface:* the retained pair set's measured byte total versus the published budget. *Method:* sum the byte size of every path in the carrier's copy set and compare against the budget value parsed from the published standard; expected **≤ 204800** · control: the same summation over the **pre-release** 11-member set must return **491255** (the measured baseline total), demonstrating the summation instrument reads real sizes rather than returning a vacuous zero. **Recorded correction:** the #6441 issue body states 489,339 B for that baseline; the hub measured **491,255 B** at the pinned commit — a 1,916 B gap. The control arm grades against **491255**. **Scope-A projection:** acts 1 and 2 alone leave **277,655 B = 136%** of the ceiling; all three acts reach **144,184 B = 70%**. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-4 (#4739 × #4738 on the Stage-6 C4 self-verification clause):** both cards edit the same C4 paragraph, and the merged result is coherent — the clause no longer mandates the retired bare module-prefix form, cites the canonical link-resolution rule rather than restating its rationale, names a real mirror pair rather than a self-pair, **and** states the mirror-pair edit as a checked obligation naming the asserting check. *Shared surface:* the C4 self-verification clause in `release/references/pipeline/stage-06-engineering.md`. *Method:* `grep -c 'workspace-root fallback' release/references/pipeline/stage-06-engineering.md` expected **0** · control: the same instrument for the cited canonical rule's filename must return **non-zero**, so a zero on the first arm is a real removal rather than an unresolvable path. **Non-overlap contract:** the paragraph carries two sentences by construction — sentence 1 (link form, #4739) and sentence 2 (path-set parity obligation, #4738). Sentence 2 carries neither the retired-fallback token nor any link-form claim, so it cannot contradict the canonical rule and does not perturb the first arm's zero. *Graded at Stage 9 QC3.5 on the merged PR.*

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Rollback Complexity |
|-------|-----------------|---------------------|
| #4738 | `git revert` the card's commits — every change is additive; the markers are comments no current consumer parses, and the check is warn-mode with no path to the exit code | Low |
| #4739 | `git revert` the card's commits — link-form rewrites are textual and self-contained | Low |
| #6441 | Forward fix preferred once the carrier depends on the published budget; before that, `git revert` restores the 11-member array and the directory-shaped loop | Medium |
| #4740 | `git revert` the card's commits, then re-run the deploy from the reverted source to un-populate the mirror — reverting source alone does not remove deployed files | Medium |

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|----------|---------|-----------|
| **Partial Revert** | Isolated card failure found post-merge | Revert that card's commits; the serial commit order makes the boundaries unambiguous |
| **Full Restore** | Systemic failure | `git revert -m 1 <merge-sha>` on the two-parent release merge commit, then re-run the deploy from the reverted source to restore the workspace mirror to its pre-release state |
| **Forward Fix** | Minor issue, fix well-understood | Fix branch off `main` per the rollback protocol |

## Operational Deployment Manifest

Layer 2 file propagation targets for Stage 12/13:

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|------------------|------------------|-----------|--------------|
| 1 | the nine retained `core/rules/*.md` members | the deployed workspace rules directory | deploy-mediated copy by the carrier (#4740) | the mirror check reports byte-identity for every pair; `never populated` is distinguishable from `in sync` |
| 2 | `core/CLAUDE.md.template` | the deployed workspace charter | deploy render | the deployed charter routes sessions to the mirrored rules set |
| 3 | `operations/CLAUDE.md.template` (CONDITIONAL) | the deployed operations context anchor | deploy render | the operations-rooted session loads the declared subset |

**No skill packages propagate in this release** — enumerated over the File Change Matrix: no rostered skill's `SKILL.md` or `references/` is edited, so the direct-copy skill mechanism has no subject.

### Schema Migrations (if applicable)

N/A — enumerated over the classes reasoned over: data-schema changes, frontmatter-schema changes, and check-roster renumbering. The frontmatter contract (#6441) **adds** fields to nine rule files rather than migrating existing values, and the new deploy check takes the next free number rather than renumbering an existing one. No migration is present in this release.

## Verification Evidence

(Populated during Stage 6 C4 self-verification and re-run at Stage 7; see the release PR body for the emitted block.)

## Deployment Execution Log

(Populated during Stage 12.)

| Step | Timestamp | Result | Notes |
|------|-----------|--------|-------|
| Pre-execution check | | PASS/FAIL | |
| Merge PR | | PASS/FAIL | |
| Tag release | | PASS/FAIL | |
| Skill deployment | | PASS/FAIL | |
| Manifest execution | | PASS/FAIL | |
| State anchor update | | PASS/FAIL | |
| Post-execution verification | | PASS/FAIL | |

## Deviation Log

| # | Declared | Actual | Basis | Recorded by |
|---|----------|--------|-------|-------------|
| DEV-1 | Parity primitive emits five TSV class values | Seven — adds `SCAN` and `NOT-EVALUATED` | `NOT-EVALUATED` is required by the spec's own lifecycle token set: the wrapper must emit that token and can only learn it from the primitive. `SCAN` carries the scan mode and denominator, because `HOLDERS 0` with no denominator beside it is the un-diagnosable zero this check exists to remove. Both are classified by the wrapper, so neither reaches the residual bucket. | #4738 |
| DEV-2 | Wrapper routes unrecognized TSV class values through the shared `tsv_residual_rows` helper | Same predicate, implemented inline in the top-level verdict body | That helper is defined nested inside the lifecycle command and does not exist when the pre-merge runner executes. Calling it would work on one surface and fail on the other — the exact single-engine divergence the body is factored to top level to prevent. | #4738 |
| DEV-3 | The Stage-6 clause sentence cites the check in `deploy.sh --check` | Cites both `--check` and the pre-merge `--check-required-subset` surface | The sentence's own claim is that a one-sided edit "can no longer merge green", which holds only because of the pre-merge surface. Naming only the post-merge surface would have made the sentence contradict its cited mechanism. The roster join was accepted after the sentence was drafted. | #4738 |
| DEV-4 | Marker indentation as literally transcribed from the design spec | Matched to each holder's surrounding code indentation | Cosmetic; the discovery regex is whitespace-insensitive. The literal transcription would have left the marker visibly misaligned against the array it wraps. | #4738 |
| DEV-5 | Two files edited that were not in the Stage-4 matrix: `core/deploy/allowlists/selftest-coverage-manifest.txt` and `core/deploy/tools/README.md` | Promoted into the unconditional matrix above, in the commit that edited them | The self-test coverage gate's own rule: a tool added to `core/deploy/tools/` is not complete until its manifest row and its README coverage row land in the **same change**. The gate caught the omission on three arms (manifest floor, doc coverage, denominator identity). The manifest is regenerated by its own emitter, never hand-edited. | #4738 |

## Change Description

*(Authored incrementally by the Engineering spokes and refreshed as each card lands; complete before the PR is transitioned to ready-for-review at the Stage 9 gate.)*

### Outcome

This release makes the rules mirror something sessions actually receive, and makes what it delivers both bounded and resolvable. The mirror-pair path set stops being a pair of hand-maintained lists whose agreement was nobody's job: every holder now declares itself in-band and a check diffs them all against each other, on the pre-merge surface as well as after merge. The corpus that mirror carries gets published admission criteria and a measured size ceiling, its cross-tree links are rewritten to a form that resolves from the deployed location, and — finally — a producer writes the mirror at deploy time. At Stage 9 Plan Review the operator sees a single PR whose diff carries all four, in dependency order.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #4738 | Every holder of the mirror-pair path set self-registers in-band and is machine-diffed against the others, pre-merge and post-merge | DONE |
| #4739 | Cross-tree links in the retained rule corpus resolve from the mirror location, and the canonical link-form rule has a named home | PENDING — sequence position 2 |
| #6441 | The rules corpus has a published admission test, a measured byte ceiling, and a frontmatter contract | PENDING — sequence position 3 |
| #4740 | The deploy writes the workspace rules mirror, and a never-populated mirror is distinguishable from a synced one | PENDING — sequence position 4 |

### Key decisions

- **D-3:** Release class held at `novel`. Re-classing to `cross-cutting` would move the class weight to 1.3 and put the release at 26 effective points, over the 25 ceiling — buying one notch of engagement density at the cost of re-dispositioning an operator-approved composition.
- **D-6:** Stages 10 and 11 **COMPRESSED** (git-native). The PR diff is the dry-run and git history is the snapshot set; routing is Stage 9 GO → Stage 12 Execute.
- **D-E / D-E2:** Scope A confirmed — the rules corpus retains **9** members, and the exclusion requires **three** acts, not two. Retiring the directory-shaped mirror loop is the third and is what takes the corpus from 136% of the ceiling to 70%.
- **D-A superseded:** the excluded release-process document's links resolve in place, so removing it from the pair set costs zero edits.
- **D-4 superseded:** with the nested drop-in set no longer mirrored, the extension of #4739's third criterion to that set has no subject.
- **D-B:** the canonical mirror-pair link-form rule is authored at `core/standards/doc-link-maintenance-protocol.md` and its rule-mirror.
- **D-C1:** the parity check joins the pre-merge required-subset roster with posture `required(warn-mode-initial)`; the enforcement sentinel ships unchanged at `warn`, so a finding is reported and swallowed rather than gating.
- **D-C2:** a holder-registration ADR is authored in `core/ADRs/`, slug-cited so its number binds at merge.
- **D-D:** the arity clause of CIAC-1 is amended to a disjunction, resolved at the carrier's Stage 5.

### Reversibility

**CHEAP — HIGH confidence.** Every change is additive at the source layer; `git revert -m 1 <merge-sha>` on the two-parent release merge commit restores the pre-release corpus in one operation. The single non-file-reversible surface is the deployed workspace mirror, which is restored by a second, operator-run deploy from the reverted source.

### Downstream impact

- The holder-registration contract binds every future consumer of the mirror-pair path set, not just the carrier shipped here.
- A member add or removal becomes a checked multi-file edit; the successor design — collapsing to a single generated source that dissolves the parity problem entirely — is recorded as the named successor once the carrier makes that single source verifiable at build time.
- A bounded, admission-tested rules corpus is the prerequisite the deferred successor card was waiting on; it re-bundles cleanly at the next cycle.
- Consumers affected: the deploy check suite, the pre-merge required-subset runner and its CI job, the blast-radius topology tool, and every session that loads the workspace rules directory at start.

### Cross-references

- Release plan: this file, top section
- Milestone: `rules-mirror-delivered`
- User-facing release notes: authored at Stage 13 Close per the release-notes standard
