---
title: Release Plan — governance-ci-gates (promote load-bearing governance checks to warn-mode pre-merge CI gates)
type: release-plan
plan_type: release
status: ACTIVE
release: version-less (theme-named; no tag claimed)
milestone: 93-governance-ci-gates
release_class: cross-cutting
reversibility: MODERATE / Confidence HIGH
---
# Release Plan — `governance-ci-gates`

**Milestone:** `93-governance-ci-gates` (#236) · hub sub-task #3734 = Stage 4 plan source · #3790 = Stage 5 Solutioning source · #3791 = Stage 6 Engineering sub-task
**Version identity:** **version-less / theme-named** — D-Version condition **(B)** (milestone title is slug-only). **No `v*` tag is claimed at Stage 12**; the Engineering-Commit-0 version re-verify and the Stage-12 atomic version claim are **inapplicable** (there is no version slot to contend for). Re-verified at Engineering Commit 0: `git fetch --tags origin` shows only version-numbered `v*` tags belonging to numbered releases; this roadmap-numbered milestone ships version-less per RELEASE_LOG precedent (e.g. `43-public-flip-depersonalization-enforcement`).
**Topology:** D-C SINGLE — one release branch (`release/governance-ci-gates`), one PR, one merge; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** P0 fully-serial (operator-ratified) — Stage 6 slices route one at a time in dep order on the single branch; force-push (incl. `--force-with-lease`) prohibited on the shared branch under any multi-chip activity.
**Release class:** `cross-cutting` (milestone declaration; trigger (c) — ≥3 in-bundle compositional edges on `core/deploy/deploy.sh`).

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #3734, reconciled to the approved **Stage-5 Solutioning** designs and the **Collective Review scope-lock dispositions** posted on #3790 (decisions D-1 / D-2). Where a scope-lock disposition superseded a Stage-4 assumption, the transcribed sections preserve the Stage-4 plan of record and the **§ Deviation Log** records the ratified delta. Authored at Engineering Commit 0 by the Stage-6 Engineering spoke (#3791).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | version-less (theme-named; no tag) |
| **Date Created** | 2026-07-24 (Friday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/governance-ci-gates` |
| **PR** | (populated at PR creation, Stage 6) |
| **Milestone** | `93-governance-ci-gates` (#236) |

---

## Change Description

*Authored at Stage 6 Phase C1 per RELEASE_PROTOCOL § Change Description Protocol. Operator-facing.*

**Outcome.** Governance self-validates *before* a change lands. Four load-bearing `deploy.sh --check` verifiers — which previously ran only at deploy time on the operator's machine, and so could not block a merge — gain thin-caller **pre-merge CI gates**, all shipping **warn-mode** (they report, they do not block yet). One long-standing criterion-ID collision is reconciled, and the deploy-time enforce-flip backlog gets a recorded, evidence-based decision. After this release, the release ledger's completeness, a skill's package-freshness, the hook-registry index, and the close-out output-set each have a machine gate reachable at the pull-request boundary — the flip to actually-blocking is a deliberate, one-token follow-up once each gate has dogfooded clean.

**Issues resolved (6).**
- **#1632** — the Gate-3 criterion ID `G3-05` resolved to three different meanings across the corpus (pre-renumber rot). Reconciled every live surface to the canonical "AC are measurable" (remedy a). The eval-writer skill's own eval suite already expected this, so the fix makes the playbook consistent with both the schema and the skill.
- **#1485 (+#3795)** — the whole `deploy.sh --check` battery ran only at deploy time. Adds an enumerated, extensible **required-subset CI runner** (seeded today with the one load-bearing check that lacked a mirror) and wires the previously-dead close-completeness gate to its CI caller.
- **#1484** — the highest-frequency documented release failure (closing a release with only its ledger row) now has a **release-corpus-completeness** pre-merge gate; Check 32 gains a `posture: required` declaration.
- **#2656** — a skill-source edit could merge green with a stale compiled `.skill` package; a **skill-package-freshness** pre-merge gate now catches it, registered as gate criterion G6-06.
- **#1486** — records the enforce-flip decision for the warn-mode check cohort: the flip mechanism already exists in-tree; every flip is **deferred** because the drain evidence is operator-instance data a CI agent cannot read, and the cohort is still warning at scale.

**Key decisions.** All new gates ship **warn-mode** (operator gate, Stage-4 R1 → Option A): dogfood green on this PR, flip to enforce as a separate Stage-12/13 step. The `#1485` subset **excludes** any check with a dedicated mirror, so Check 32 is never double-gated (R6). `#1486` ships the mechanism and defers all flips (scope-lock D-1). `#3795` folded into `#1485` (scope-lock D-2).

**Reversibility.** **CHEAP.** All-additive: new workflows + warn-mode sentinels + append-only register rows + behavior-preserving `deploy.sh` factoring (the inline checks keep their exact deploy-time verdicts). Whole-release rollback is `git revert` of the PR. The only MODERATE surface is the future operator-side branch-protection flip, reversible by un-requiring.

**Downstream impact.** No runtime/skill behavior changes for end users. Every new gate is warn-mode, so no PR is blocked by this release. The deploy-time `deploy.sh --check` verdicts are byte-identical to before (verified by a full `--check` run). Flipping any gate to blocking is an explicit future step (a one-token sentinel edit + a branch-protection change), gated on a clean dogfood.

**Cross-references.** Stage-4 plan #3734 · Stage-5 design #3790 · this milestone #236. Enforcement posture per `core/standards/gate-efficacy-standard.md` Req (b)/(b'); warn-mode-initial per `core/rules/git-workflow.md` § Repository-Integrity Gates.

---

## Scope

### Summary

Six members promote load-bearing `deploy.sh --check` verifiers into **warn-mode pre-merge CI gates**, drain one criterion-ID collision, and record the deploy-time enforce-flip decisions. Build posture: **single branch, P0 fully-serial** (4-of-6 members serialize on `core/deploy/deploy.sh`; one PR / one merge per "milestone = one PR").

The release's capability outcome: **governance self-validates** — every structural invariant the corpus asserts in prose gains a machine gate that fails when the prose and the live state diverge, reachable pre-merge.

**Enforcement posture (operator gate, Stage-4 R1 → Option A):** all three new CI gates (#1484/#1485/#2656) + the folded close-completeness gate (#3795) ship **warn-mode** this release — they report but do not block. They dogfood green on this release's own PR. The flip to enforce is a separate Stage-12/13 step (a one-token edit of each `.enforce` sentinel + an operator-side branch-protection `required_status_checks` addition), gated on a green dogfood. No enforce/required flip lands in this build.

### Members

| # | Issue | Type | Size | Surface |
|---|-------|------|------|---------|
| 1 | **#1632** reconcile G3-05 criterion-ID collision | task | S | `eval-writer/references/playbook-stage-gate.md`, `stage-io-contracts.md`, `operating-model.md` (+ `eval-writer.skill` rebuild) |
| 2 | **#1485** run the load-bearing `deploy.sh --check` subset pre-merge in CI (**+#3795** close-completeness CI wiring, folded per D-2) | story | M | `core/deploy/deploy.sh`, `.github/workflows/deploy-check-ci.yml` (new), `.github/workflows/close-completeness.yml` (new), sentinels, register |
| 3 | **#1484** CI-mirror Check 32 (release-corpus completeness) | story | M | `core/deploy/deploy.sh`, `.github/workflows/release-corpus-completeness.yml` (new), sentinel, register |
| 4 | **#2656** CI-mirror Check 7 (.skill package content-freshness) | task | M | `core/deploy/deploy.sh`, `.github/workflows/skill-package-freshness.yml` (new), sentinel, `gate-criteria-spec.md`, pipeline docs, register |
| 5 | **#1486** close warn-mode shakedowns + flip drained checks to enforce | task | S | `core/standards/gate-efficacy-standard.md` (register — flip decisions) |
| — | **#3795** wire close-completeness CI gate (**folded into #1485's Stage-6 scope** per D-2) | improvement | S | `.github/workflows/close-completeness.yml` (new) |

**#3795 fold (D-2):** the close-completeness probe (`deploy.sh --check-close-completeness`, Check 48) and its `.github/close-completeness.enforce` sentinel already ship, but no workflow calls the probe. #3795 adds the thin-caller `close-completeness.yml`, built within #1485's Stage-6 Engineering (same deploy-check CI surface, same thin-caller pattern).

### Wave Structure (Stage 6 Engineering)

Single branch, serial build order (Hub Procedure 2 surfaces one Stage-6 chip at a time):

| Order | Member | Rationale |
|-------|--------|-----------|
| 1 | **#1632** | Spec-first — reconcile the G3-05 criterion-ID collision before the gate corpus is extended. Touches no `deploy.sh`; independently shippable. Rebuilds `eval-writer.skill` (dogfoods #2656). |
| 2 | **#1485 (+#3795)** | Lands the `deploy.sh --check-required-subset` CLI entry + thin-caller pattern + first register rows the peers reuse. Establishes the pattern. |
| 3 | **#1484** | CI-mirror Check 32; adds `posture: required` header + dedicated path-filtered gate (Check-32 canonical required-context; R6). |
| 4 | **#2656** | CI-mirror Check 7; the release's `eval-writer.skill` rebuild (from #1632) is the live regression signal for this gate (CIAC-4). |
| 5 | **#1486** | **LAST** — enforce-flip decisions on pre-existing warn-mode checks. Additive changes before enforcement changes (branch stability). |

---

## Dependency Graph

Edge legend: **HARD** = build-blocking; **SOFT** = sequencing/hygiene; **CONTENTION** = shared-file write-serialization (drives commit order, not dependency).

```
External (all resolved / non-blocking):
  #1036 (posture back-fill, dep of #1485) .............. CLOSED  ✓ satisfied
  #2159 (Check-7 reproducibility, dep of #2656) ........ CLOSED  ✓ satisfied (2026-07-13)
  #757  (xref-gate pre-flip hardening, precedent #1486)  CLOSED  ✓ precedent exists
  #45   (per-check registry) ........................... OPEN, DORMANT → SOFT alignment target only (per-check thin callers); NO hard edge
  #1178 (parent epic GH-Deploy-Health) ................. OPEN umbrella; not a blocker

In-bundle edges:
  #1632 ──SOFT(spec-first)──▶ #1485, #1484, #2656   (resolve G3-05 ambiguity before extending the gate corpus; hygiene, not a build blocker)
  #1485 ──SOFT(pattern)────▶ #1484, #2656            (#1485 lands the deploy.sh CLI-entry + thin-caller pattern + first register rows the peers reuse)
  #1484 ∥ #2656                                       PARALLEL peers; serialize ONLY on deploy.sh (CONTENTION), no dependency
  #1484,#1485,#2656 ──SOFT(branch-stability)─▶ #1486  (#1486 records flip decisions on PRE-EXISTING checks — sequencing, not a hard edge)
  #3795 ──folded-into──▶ #1485                        (same deploy-check CI surface; D-2)
```

**No HARD intra-milestone blockers.** All hard deps (#1036/#2159/#757) CLOSED.

---

## Implementation Sequence

Dependency-ordered; commit order under SINGLE topology follows this list.

1. **#1632** — Reconcile G3-05 criterion ID-collision. Remedy **(a)** re-ID (see § Deviation Log Δ-1632). Rebuild `eval-writer.skill` after the reference edit.
2. **#1485 (+#3795)** — Add `cmd_check_required_subset` (enumerated allowlist, seeded with Check 38 only) + `_c38_compute_verdict` factor + `--check-required-subset` dispatch; new `deploy-check-ci.yml` + `.github/deploy-check-ci.enforce` (`warn`); +1 register row. **#3795:** new `close-completeness.yml` (thin caller of `--check-close-completeness`, honors the existing `close-completeness.enforce` sentinel).
3. **#1484** — Factor `_c32_compute_verdict`; add `cmd_check_release_corpus` + `--check-release-corpus` dispatch; add `# gate-efficacy: posture=required` header to Check 32; new `release-corpus-completeness.yml` (path-filter `release/releases/**`) + `.enforce` (`warn`); +1 register row (R6 canonical Check-32 context; #1485's subset EXCLUDES Check 32).
4. **#2656** — Factor `_c7_compute_verdict`; add `cmd_check_package_freshness` + `--check-package-freshness` dispatch; new `skill-package-freshness.yml` (path-filter skill sources + `packages/*.skill`) + `.enforce` (`warn`); new PR-CI criterion in `gate-criteria-spec.md`; note-CI-gated edits to stage-06/stage-12/release-process; +1 separate CI-mirror register row (distinct from the deploy-time Check-7 row).
5. **#1486** — Record the per-check enforce-flip decisions. Drain signal (`*-warn-log.jsonl`) is operator-instance + git-ignored + absent in a fresh checkout → not repo-derivable by a PR spoke. **Ship the mechanism (already in-tree: `resolve_check_mode "<id>" "enforce"` committed-default pattern, live at Check 22 / Check 47 / version-freeness), defer all enforce-flips**, record each decision in the register (see § Deviation Log Δ-1486).

---

## Stage Applicability Matrix

Default = all Stages 5–13 apply. Exceptions justified.

| Issue | S5 | S6 | S7 | S8 | S9 | S12 | S13 | Notes |
|-------|----|----|----|----|----|-----|-----|-------|
| #1632 | **SKIP** | ✔ | ✔ (light) | ✔ | ✔ | ✔ | ✔ | Trivial reconciliation — binary a/b remedy, no design surface |
| #1485 | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | Subset-runner + fixture design |
| #1484 | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | New workflow + fixture |
| #2656 | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | Path-filter mechanism = design surface |
| #1486 | ✔ (light) | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | Per-check flip judgment; Deep S9 |
| #3795 | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | Thin-caller (folded into #1485) |

---

## Contention Map

| Shared surface | Members | Nature | Serialization note |
|----------------|---------|--------|---------------------|
| **`core/deploy/deploy.sh`** | #1485, #1484, #2656 | **PRIMARY** — new `cmd_check_*` entries + `_cNN_compute_verdict` factors + dispatch `case` arms + Check-32 posture header | Factors land in distinct line regions (Check 7 ~L2633, Check 32 ~L5195, Check 38 ~L6187); dispatch `case` (~L8141) is the shared hunk → append in order, serial. |
| **`core/standards/gate-efficacy-standard.md`** (register) | #1485, #1484, #2656, #1486 | Register-row appends | Append-pattern → low conflict; serialize. |
| **`core/schemas/gate-criteria-spec.md`** | #2656 (new PR-CI criterion) | Section-local | Sole editor this release (#1486 records G3-14/15/CL7/CL8 status in the register, not by editing the spec). |
| `.github/workflows/*.yml` | #1485 (×2 w/ #3795), #1484, #2656 | 4 NEW distinct files | **No contention** — disjoint filenames. All run on THIS PR (dogfood). |
| `.github/*.enforce` sentinels | #1485, #1484, #2656 | 3 NEW distinct files | Disjoint; each ships `warn`. |
| eval-writer skill references (+ `packages/eval-writer.skill`) | #1632 only | single (+ skill rebuild) | No contention; rebuild dogfoods #2656's gate. |
| `release/references/pipeline/stage-06-engineering.md`, `stage-12-execute.md`, `release/governance/release-process.md` | #2656 only | single | No contention. |

**Contention clusters:** (1) `deploy.sh` — {#1485,#1484,#2656}; (2) gate-efficacy register — {#1485,#1484,#2656,#1486}. These are the ≥3-compositional-edge evidence for cross-cutting.

---

## Risk Register

| ID | Risk | Type | Sev | Owner | Mitigation | Reversibility |
|----|------|------|-----|-------|------------|---------------|
| R1 | **Warn-mode-vs-required tension.** The Outcome Statement wants failing PRs *blocked*, but the 3 new gates have no shakedown history. | Scope | HIGH | Operator (Stage-12/13) | Option A (approved): ship warn-mode → dogfood green on this PR → flip to enforce + operator branch-protection at Stage 12/13. Predicates mirror battle-tested deploy.sh checks. | MODERATE (flip reversible by un-requiring) |
| R2 | **deploy.sh 3-way contention.** Members edit one file; mis-sequenced commits collide. | Contention | MED | Hub Procedure 2 | Strict serial commit order; P0 posture; no force-push. Factors land in distinct regions. | CHEAP (git revert per commit) |
| R3 | **"Flip to required" is out-of-tree.** Branch-protection is an operator repo-settings change, not a PR file. | Dependency | MED | Operator | Stage-12/13 operator-side handoff (Hook-Blocked→user-side pattern); the PR carries the posture *declaration*; branch-protection is the enforcement. | MODERATE (operator un-checks) |
| R4 | **#2656 false-positive regression.** Check 7 historically emitted non-reproducible-archive false-positives (#2159). | Dependency | MED | #2656 | Dep #2159 CLOSED (2026-07-13) — verified. Gate ships warn-mode; this release's own `eval-writer.skill` rebuild (#1632) is the live regression signal on its own PR. | CHEAP (revert workflow) |
| R5 | **In-file refactor risk (factoring `_cNN_compute_verdict`).** Extracting verdict bodies from `cmd_check` could drift deploy-time behavior. | Refactor | MED | eng | The inline block keeps calling the same body (single-engine, DD1); version-freeness/close-completeness ports prove the pattern is safe; exit-code/ISSUES accounting preserved; dogfood `deploy.sh --check` green on own tree. | CHEAP (revert commit) |
| R6 | **#1484/#1485 double-coverage of Check 32.** #1485 subset + #1484 dedicated gate could both run/require Check 32. | Contention/scope | LOW | #1484+#1485 | #1484's dedicated gate is Check 32's ONE canonical required-context; #1485's subset EXCLUDES Check 32; cross-noted in both register rows. One canonical required-context in branch protection. | CHEAP |
| R7 | **#1486 premature flip.** A not-drained check flipped to enforce false-fails `deploy.sh --check`. | Rollback | MED | #1486 | Drain signal (warn-logs) verified inaccessible to a PR spoke (operator-instance, git-ignored, absent) → defer ALL flips, ship mechanism only. No enforce flip lands. | MODERATE (revert per-check) |

---

## Cross-Issue Acceptance Criteria

Graded on the merged PR at Stage 9 (QC3.5). Verification methods reproducible.

- [ ] **CIAC-1 (#1484 × #1485 × #2656 on the required-status-check surface):** every newly-CI-mirrored gate that the operator later flips to required blocks a PR that fails it. *Method:* per gate, a known-bad fixture PR turns the CI job red AND (post-flip) `gh pr view --json mergeStateStatus` is BLOCKED. The "required" half is verified at the operator-side flip (R3), not by PR content. *This release ships warn-mode; the block-half is a Stage-12/13 verification.*
- [ ] **CIAC-2 (#1485 × #1484 × #2656 on `.github/workflows/*` + `deploy.sh`):** each new workflow is a THIN caller of its `deploy.sh --check-*` entrypoint — no check predicate re-encoded in YAML (single-engine). *Method:* `grep` each new workflow — confirm each `run:` block invokes `deploy.sh --check-<name>` and carries a `# gate-efficacy:` header; confirm no version/hash/corpus predicate re-implemented in YAML.
- [ ] **CIAC-3 (#1485 × #1484 × #2656 × #1486 on `gate-efficacy-standard.md`):** every gate this release adds or whose flip-decision it records has exactly one gate-coverage-register row. *Method:* `grep` the register for a row per new gate + per recorded flip decision; assert no gate lacks a row, no duplicate rows.
- [ ] **CIAC-4 (#1632 × #2656 on `packages/eval-writer.skill`):** #1632's edit to `playbook-stage-gate.md` leaves `eval-writer.skill` content-fresh — the release rebuilds the package, and #2656's Check-7 CI mirror passes green on this release's own PR. *Method:* after #1632's edit, `build-skill-packages.sh eval-writer` then `deploy.sh --check-package-freshness` reports FRESH.

---

## File Change Matrix

Machine-readable — one path per line. Add/edit intent in the trailing comment.

```paths
core/skills/eval-writer/references/playbook-stage-gate.md          # edit — #1632 re-ID G3-05 "Bundle rationale" → canonical "AC are measurable" (remedy a)
packages/eval-writer.skill                                         # edit — #1632 rebuild after eval-writer reference edit (dogfoods #2656 Check-7)
packages/eval-writer.skill.sha256                                  # edit — #1632 content-baseline sidecar re-emitted by build-skill-packages.sh
core/schemas/stage-io-contracts.md                                # edit — #1632 reconcile the G3-05 "Capacity" citation
core/disciplines/operating-model.md                               # edit — #1632 reconcile the G3-05 "version assigned" citation (AC-completeness; third divergent surface)
core/deploy/deploy.sh                                             # edit — #1485 _c38_compute_verdict factor + cmd_check_required_subset + --check-required-subset dispatch; #1484 _c32_compute_verdict factor + cmd_check_release_corpus + --check-release-corpus dispatch + Check-32 posture header; #2656 _c7_compute_verdict factor + cmd_check_package_freshness + --check-package-freshness dispatch
.github/workflows/deploy-check-ci.yml                             # new  — #1485 thin caller of deploy.sh --check-required-subset (warn-mode-initial)
.github/deploy-check-ci.enforce                                   # new  — #1485 token-flagged enforce sentinel (ships `warn`)
.github/workflows/close-completeness.yml                         # new  — #3795 thin caller of deploy.sh --check-close-completeness (honors existing close-completeness.enforce sentinel)
.github/workflows/release-corpus-completeness.yml                # new  — #1484 thin caller of deploy.sh --check-release-corpus, path-filtered release/releases/** (warn-mode-initial)
.github/release-corpus-completeness.enforce                      # new  — #1484 token-flagged enforce sentinel (ships `warn`)
.github/workflows/skill-package-freshness.yml                    # new  — #2656 thin caller of deploy.sh --check-package-freshness, path-filtered skill sources + packages/*.skill (warn-mode-initial)
.github/skill-package-freshness.enforce                          # new  — #2656 token-flagged enforce sentinel (ships `warn`)
core/schemas/gate-criteria-spec.md                               # edit — #2656 new PR-CI package-freshness criterion
core/standards/gate-efficacy-standard.md                         # edit — #1485/#1484/#2656 CI-mirror register rows; #1486 per-check flip-decision rows
release/references/pipeline/stage-06-engineering.md              # edit — #2656 note the package-rebuild beat is CI-gated
release/references/pipeline/stage-12-execute.md                  # edit — #2656 note Check-7 CI enforcement at the merge gate
release/governance/release-process.md                            # edit — #2656 Stage-6 package-rebuild beat is CI-gated
release/releases/plans/governance-ci-gates_RELEASE_PLAN.md        # new  — this plan, committed as Engineering Commit 0
release/releases/RELEASE_LOG.md                                   # edit — Stage-13 close-out ledger row (version-less; slug-keyed) [Stage 13, not this build]
```

**Explicitly NOT edited:**
- `core/rules/bypass-mode-readiness.md` — a GENERATED artifact (Check 38 regenerates it from sources via `build-hook-registry.py`); hand-editing it would self-trip Check 38. #1486 flip-status tracking lands in the gate-efficacy register instead (the issue's "if flip status tracked there" is conditional and the register is the correct surface).
- Branch-protection `required_status_checks` — an operator-side repo-settings change, out-of-tree (R3). The `# gate-efficacy: posture=required` declaration is the in-tree intent; branch protection is the operator-side enforcement.

---

## Deviation Log

Deltas between the Stage-4 plan of record (#3734) and the ratified Stage-5 scope-lock (#3790), plus Stage-6 implementation findings. All are refinements or reductions; none re-opens the bundle.

| # | Stage-4 / spec record | Ratified/implemented delta | Basis |
|---|----------------------|-----------------------------|-------|
| **Δ-D1** | #1486 = "flip drained checks to enforce" | **Ship the `resolve_check_mode` committed-enforce-default mechanism + flip ONLY clean-verified checks; defer the rest to a tracked fast-follow.** | Scope-lock D-1 (operator, 2026-07-24) |
| **Δ-D2** | #3795 (close-completeness dead-gate) as a standalone member | **Folded into #1485's Stage-6 Engineering** — the thin-caller `close-completeness.yml` is built on the same deploy-check CI surface within #1485's scope. | Scope-lock D-2 (operator, 2026-07-24) |
| **Δ-1632** | Remedy a-vs-b "to decide at triage" | **Remedy (a) — re-ID to canonical.** The eval-writer playbook's `G3-05 = "Bundle rationale is documented"` is a **mislabeled reference to the canonical Gate-3 space**, not an independent eval-writer numbering: the playbook explicitly instructs "read `gate-criteria-spec.md`, filter to `Check=judgment`", and the skill's OWN `evals.json` already asserts `G3-05 = "AC are measurable"` (evals.json:48/51/59). Re-IDing to canonical makes the playbook consistent with both the SSOT and the skill's own eval suite. **No eval-pack file rename** — `G3-05-bundle-rationale.md` is only a referenced example name in the playbook (tree diagram + rubrics table), not a real file (`find … -iname "*G3-05*"` → empty); the referenced name is updated to `G3-05-ac-measurable.md` in place. | Stage-6 inspection |
| **Δ-1632-b** | Issue named 2 divergent surfaces (playbook + stage-io-contracts) | **A THIRD divergent surface found: `core/disciplines/operating-model.md:336`** (`G3-05 version assigned`). Reconciled the G3-05 token to canonical (`AC measurable`) so the AC-1 `grep -rn "G3-05"` all-agree test passes — without it the primary AC fails. The stale sibling-ID mis-citations on the same construct (G3-01/02/03/04/06 in operating-model.md:336; G3-04 in stage-io-contracts.md:126, G3-06 in :128) are a **separate pre-renumber-rot class** with ambiguous canonical mappings (canonical Gate 3 has no capacity / bundle-rationale criterion) — flagged as a follow-up finding, NOT re-mapped here (out of the G3-05 collision scope; re-mapping ambiguous IDs risks new errors). | Stage-6 corpus-wide `grep -rn "G3-05"` |
| **Δ-factor** | Stage-5: "factor `_c7/_c32/_c38_compute_verdict` out of `cmd_check`" | Factored per the version-freeness (`_vf_compute_verdict`) / close-completeness (`_cc_compute_verdict`) DD1 precedent: the body emits its verdict protocol line on **stdout** and per-item detail on **stderr**; the inline `cmd_check` block re-logs an aggregate summary and preserves the exact `ISSUES` accounting (exit-code byte-identical); the probe consumes the same body on the `"gate"` surface (single-engine, CIAC-2). | Stage-6 implementation |
| **Δ-c32-posture** | #1484: add `# gate-efficacy: posture=required` to Check 32 | Header declares `posture: required` with **enforcement-surface = the `release-corpus-completeness` CI gate (warn-mode-initial)**; the deploy-time inline surface stays warn (via `DEPLOY_CHECK_MODE`) — the `required` posture obligates the CI mirror (Req b′), which #1484 provides; the deploy-time enforce-flip is #1486's separate concern (and Check 32 is not in #1486's flip set). | Stage-5 spec + gate-efficacy-standard Req b′ |
| **Δ-1486-defer** | #1486: flip drained checks | **All enforce-flips deferred (evidence-based).** The drain signal (`core/hooks/*-warn-log.jsonl` + operator-instance `deploy-check-warn-log.jsonl`) is **git-ignored and absent in a fresh checkout** (verified: `git check-ignore` confirms; `core/hooks/*.jsonl` → no matches), so a PR spoke cannot verify shakedown-drain; a green-on-current-tree snapshot is NOT the shakedown criterion. Checks 9/11/30 are explicitly deferred (dormant per #1036, scope-lock). The `resolve_check_mode "<id>" "enforce"` mechanism is already in-tree and proven (Check 22 `g1-enforcement`, Check 47 `release-body-drift`, `version-freeness`) — #1486 records the per-check flip decisions in the register and defers all flips per the hub fallback ("ship only the mechanism, defer all flips, noting so"). | Scope-lock D-1 + Stage-6 warn-log accessibility verification |

---

## Rollback

Per `RELEASE_PROTOCOL.md § Rollback protocol` (operator-authorized). All-additive core (new workflows + warn-mode sentinels + append-only register rows + factored-but-behavior-preserving `deploy.sh` edits) → CHEAP revert-the-PR.

| Surface | Rollback | Tier |
|---------|----------|------|
| New workflows + `.enforce` sentinels (#1484/#1485/#2656/#3795) | `git revert` the slice commit | **CHEAP** |
| `deploy.sh` `_cNN_compute_verdict` factors + `cmd_check_*` probes | `git revert` the slice commit (inline behavior preserved regardless) | **CHEAP** |
| #1632 reconciliation + `eval-writer.skill` rebuild | `git revert` | **CHEAP** |
| `gate-criteria-spec.md` new criterion (#2656) | `git revert` | **CHEAP** |
| Register rows (#1485/#1484/#2656/#1486) | `git revert` | **CHEAP** |
| Operator-side branch-protection flip (Stage 12/13) | operator un-requires | **MODERATE** |

No IRREVERSIBLE actions; no tag claimed (version-less) so no tag-rollback surface.

---

*Closure-phrasing note: every per-issue closure reference in this plan is written as "mark #N as closed at Stage 13" — no close-family verbs bound to an issue number, so transcription into PR bodies will not trip GitHub's close parser.*
