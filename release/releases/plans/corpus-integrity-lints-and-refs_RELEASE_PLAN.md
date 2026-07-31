---
title: Release Plan — corpus-integrity-lints-and-refs (drain criterion-ID / count / constant drift, and ship the lints that keep it drained)
type: release-plan
plan_type: release
status: ACTIVE
release: slug-only (ADR-092 — concrete version binds at the Stage-12 atomic claim)
milestone: corpus-integrity-lints-and-refs
release_class: cross-cutting
reversibility: CHEAP / Confidence HIGH
---
# Release Plan — `corpus-integrity-lints-and-refs`

**Milestone:** `corpus-integrity-lints-and-refs` (milestone 308) · hub sub-task #4335 = Stage 4 plan source · #4340 / #4348 / #4352 / #4356 / #4360 / #4364 / #4368 / #4372 = Stage 5 Solutioning sources · #4341 = Stage 6 Engineering sub-task for the first member (#3804)
**Version identity:** **slug-only** per **ADR-092**. The plan file is `corpus-integrity-lints-and-refs_RELEASE_PLAN.md` and the branch is `release/corpus-integrity-lints-and-refs`; **no `vX.Y` appears in the plan filename, the branch name, or this plan's prose**. Bump class is `minor` (recorded determination, not a gate). The concrete number binds at the **Stage-12 atomic claim** (`git mv` to `plans/v<MAJOR>/vX.Y_RELEASE_PLAN.md`). `v4.02` was claimed by a sibling release mid-run at **zero cost to this release** — the early-binding HALT that ADR-092 exists to prevent did not occur.
**Topology:** D-C **SINGLE** — one release branch, one PR, one merge; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial** (operator verdict D-4). Stage-6 chips route one at a time in the approved sequence on the single branch; force-push (including `--force-with-lease`) is prohibited on the shared branch under any multi-chip activity.
**Release class:** **`cross-cutting`** (operator verdict D-1) with **engagement density overridden to `Standard`** — documented rationale below.

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #4335, reconciled to the approved Stage-5 Solutioning designs, the **Procedure 0 gate** verdicts (2026-07-31), the **Wave 1 Decision Briefing** verdicts (2026-07-31), and the **Collective Review scope-lock** (2026-07-31). Where a later disposition superseded a Stage-4 assumption, the transcribed section preserves the Stage-4 plan of record and the **§ Deviation Log** records the ratified delta. Authored at Engineering Commit 0 by the Stage-6 Engineering spoke for #3804 (#4341).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | slug-only pre-claim (ADR-092); bump class `minor` |
| **Date Created** | 2026-07-31 (Friday) |
| **Release Manager** | Agent-assisted (`release-hub` Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/corpus-integrity-lints-and-refs` |
| **PR** | (populated at PR creation — hub-owned) |
| **Milestone** | `corpus-integrity-lints-and-refs` (308) |
| **Baseline** | `origin/main` @ `93023d8e` (Commit-0 re-pin; Stage-4 pin was `c4dde614`, +25 commits) |

---

## Change Description

*Authored at Stage 6 Phase C1 per RELEASE_PROTOCOL § Change Description Protocol. Operator-facing.*

**Outcome.** The corpus stops asserting things about itself that are no longer true. Nine cards split evenly across two halves: **five drain existing drift** — mis-cited gate-criterion IDs, stale cross-references, hand-copied constants that have diverged from their canonical declarations — and **four ship the machinery that keeps it drained**: a probe-validity discipline (every check states its denominator and runs a control expected to fail), a `deploy.sh` lint that cross-validates a stated count against the structure it describes, a readiness-map invariant, and dynamic sourcing for constants that were previously copied by hand into three places. After this release, the class of defect where a document says "six criteria" over a table of nineteen has a machine that catches it.

**The through-line.** Every card in this bundle is an instance or a prevention of the same failure: *a claim about a structure, stored separately from the structure, that nobody swept when the structure changed.* The instances are drained first so the lints have a clean corpus to assert against; the lints land second so they cannot red-wall the drain.

**Key decisions.** Release class held at **`cross-cutting`** with engagement density overridden to `Standard` (D-1). Sequence **swapped** so #4195 — which authors the control-and-denominator discipline the other three lints cite — builds *before* its three consumers (D-2). Check 62 ships **enforce-mode, narrowly scoped** rather than warn-mode (D-3, held at revisit on corrected evidence). Concurrency posture **P0 serial** (D-4). All three Stage-5 scope expansions accepted (D-7), all three deferred items accepted, and A6.5 adversarial findings folded in **AC-affecting only**.

**Reversibility.** **CHEAP.** The drain half is prose-only — no executable, no schema behavior change. The prevention half is additive: two new `deploy.sh` check slots (62, 63), a new hooks lib, a committed baseline file, and a CI assertion. Whole-release rollback is `git revert` of the merge commit. The one MODERATE surface is Check 62's enforce posture: once other work merges green against an enforcing check, relaxing it silently re-opens the gap — which is why its heuristic is scoped narrowly and its baseline is committed rather than inferred.

**Downstream impact.** No runtime or skill behavior changes for end users. Two new `deploy.sh --check` slots run at deploy time and in CI. `packages/release-hub.skill` is rebuilt once, after both #4196 and #4197 land.

**Cross-references.** Stage-4 plan #4335 · Stage-5 designs #4340 / #4348 / #4352 / #4356 / #4360 / #4364 / #4368 / #4372 · milestone 308. Version identity per **ADR-092**; concurrency + overlap classes per **ADR-005**; canonical-spec-edit-wins per **ADR-062**.

---

## Scope

### Summary

Nine members, **21 raw pts**, one branch, one PR. **Zero hard dependency edges**; three *soft citation* edges all running out of #4195. Build posture: **SINGLE branch, P0 fully-serial**.

Capability outcome: **a claim about a structure is checkable against that structure.** Five cards make the corpus true; four make it stay true.

**Bundle sizing.** Raw sum = 21 pts (XS×1, S×6, M×2). `[bundling].release_class_capacity_weights` is **unresolved** (no `platform-config.toml` in this deployment), so the **G3-15 degraded path** applies: `class_weight = 1.0`, `effective_pts = 21`, with a **loud WARN that the result is unweighted**. 21 ≤ 25 → within the target band. Headroom is thin — a class weight above ~1.19 would breach 25 and fire the split disposition.

### Members

| # | Issue | Type | Size | Half | Surface |
|---|-------|------|------|------|---------|
| 1 | **#3804** G3-04 / G3-06 sibling-ID mis-citations | task | S | drain | `stage-io-contracts.md`, `operating-model.md`, `github-feature-strategy.md`, `five-function-spine-and-process-flows.md`, `ticket-information-architecture.md`, `stage-to-skill-mode-mapping.md` |
| 2 | **#3938** stale `Target:` framing in Automation-Level notes | improvement | XS | drain | 4 × `release/references/pipeline/stage-*.md` |
| 3 | **#3939** wire the cross-chain index into G2-13 | task | S | drain | `gate-criteria-spec.md`, `cross-chain-architecture-map.md` |
| 4 | **#3838** design-artifact rule-7 detection + §12 table-awareness | task | S | drain | `core/standards/design-artifact-standard.md` §12 |
| 5 | **#3839** `depicts=` convention for whole-file embedded artifacts | task | S | drain | `core/standards/design-artifact-standard.md` §9 |
| 6 | **#4195** probe-validity discipline (denominator + control) | story | M | prevent | `review-discipline-principles.md`, `evidence-grounding-standard.md`, `hub-spoke-bridge.md`, `review-composition-framework.md`, +3 fold-ins |
| 7 | **#4196** count-vs-structure lint (`deploy.sh` Check 62) | story | M | prevent | `core/deploy/deploy.sh`, `count-structure-baseline.txt` (new), release-hub skill files |
| 8 | **#4197** readiness-map TH-3 invariant (`deploy.sh` Check 63) | task | S | prevent | `readiness-map-template.md`, `core/deploy/deploy.sh`, `packages/release-hub.skill` |
| 9 | **#4198** dynamic-source the hand-copied fragile-ref constants | task | S | prevent | `core/hooks/**`, `.github/workflows/reference-durability.yml`, 3 installers |

### Wave Structure (Stage 6 Engineering)

Single branch, serial commit order. Hub Procedure 2 surfaces one Stage-6 chip at a time.

| Order | Member | Rationale |
|-------|--------|-----------|
| 0 | *(this plan)* | **Commit 0** — plan file lands before any member edit. |
| 1 | **#3804** | Widest cross-file breadth in the release (6 live files). Land it while the branch is clean so the AC1 enumeration runs against an unmutated tree. |
| 2 | **#3938** | 4 `pipeline/stage-*.md` files, fully disjoint from every other card. Cheapest card; clears fast. |
| 3 | **#3939** | `gate-criteria-spec.md` is the highest cross-PR-contention file after `deploy.sh`. Land early so a sibling merge forces a rebase of one small hunk, not a late one. |
| 4 | **#3838** | `design-artifact-standard.md` §12. |
| 5 | **#3839** | `design-artifact-standard.md` §9 — **immediately after #3838**, same file, disjoint sections. Adjacency confines the rebase surface to one commit pair. |
| 6 | **#4195** | **MOVED UP from declared position 7** (D-2). Authors the probe-validity discipline that positions 7–9 each cite. |
| 7 | **#4196** | `deploy.sh` Check 62 + committed baseline. Highest design risk in the release. |
| 8 | **#4197** | `deploy.sh` Check 63 + TH-3. Adjacent to #4196 so **one** `release-hub` package rebuild serves both (R-3). |
| 9 | **#4198** | Hooks + CI + installers. Fully file-disjoint from every other card — the safest tail position. |

Each issue is **marked as closed at Stage 13** on this plan's schedule; no issue closes at merge.

---

## Dependency Graph

Edge legend: **HARD** = build-blocking · **SOFT** = sequencing/hygiene · **CONTENTION** = shared-file write-serialization (drives commit order, not dependency).

**No `blocked-by` relations are declared on any of the nine cards** (verified `gh issue view` × 9 at the Stage-4 pin; #3939's only declared dependency, #779, is CLOSED 2026-07-26 and therefore satisfied).

```
#3804 ─┐
#3838 ─┤
#3839 ─┤   (no in-bundle edges — independent)
#3938 ─┤
#3939 ─┘

#4195 ──SOFT(citation)──▶ #4196
      ──SOFT(citation)──▶ #4197
      ──SOFT(citation)──▶ #4198

CONTENTION (not dependency):
  #3838 ∥ #3839   → core/standards/design-artifact-standard.md  (§12 vs §9, verified disjoint)
  #4196 ∥ #4197   → core/deploy/deploy.sh (slots 62 / 63) AND packages/release-hub.skill (BINARY whole-file)
```

| Edge | Class | Evidence |
|---|---|---|
| **#4195 → #4196** | SOFT (citation) | #4196 AC3 requires a *"mutation control — introduce one wrong count, confirm non-zero exit, revert"*. #4195 authors exactly that rule. Building #4196 first forces either a restatement (duplicate-source violation) or a forward-reference to an unwritten section. |
| **#4195 → #4197** | SOFT (citation) | #4197 AC2 verbatim: *"Confirm the check reports its denominator and a control, so a zero result is trustworthy."* |
| **#4195 → #4198** | SOFT (citation) | #4198 AC2: *"mutation control — alter one of the three declarations, confirm CI fails, revert."* |

**No edge #3838 ↔ #3839** despite the shared file — verified section-disjoint. **No edge #3939 → #3804** despite both touching Gate-criterion citations: #3804 reconciles G3-04/G3-06 meanings, #3939 adds a reference line inside the G2-13 body. Different criteria, no shared line range. Their coupling is graded at **CIAC-3**, not sequenced.

**No HARD intra-milestone blockers.**

---

## Implementation Sequence

Operator-adopted at the Procedure 0 gate (D-2, swap adopted):

```
#3804 → #3938 → #3939 → #3838 → #3839 → #4195 → #4196 → #4197 → #4198
```

1. **#3804** — reconcile G3-04 / G3-06 mis-citations across 6 files. Hybrid mechanism: re-ID where a canonical criterion carries the asserted meaning, **de-cite** where none does, **consolidate-to-pointer** where the site is a drifted bare duplicate. Includes the operator-approved L177 forced co-edit and the 4 range-citation updates.
2. **#3938** — replace `Target:` with `Today:` framing in 4 Automation-Level notes. Sweep denominator is **13** `pipeline/stage-*.md` files, not the 14 the card body states (R-10).
3. **#3939** — add one reference line inside the **G2-13** criterion body citing the cross-chain index; clear the `[DEFERRED]` forward-note in `cross-chain-architecture-map.md`. Cites, does not restate (AC2).
4. **#3838** — `design-artifact-standard.md` §12.1 rule-7 detection column + §12 table-awareness note + §12.2 harness. **Plus §3 declared in-milestone** (deferred item (b) accepted).
5. **#3839** — `design-artifact-standard.md` §9 `depicts=` convention for whole-file embedded artifacts.
6. **#4195** — author the probe-validity discipline (denominator + control-expected-non-zero) into `review-discipline-principles.md` and `evidence-grounding-standard.md`; cite it from `hub-spoke-bridge.md`; §5.6 mandatory cascade into `review-composition-framework.md`; +3 fold-ins; +R3 `design-review-checklist.md` row; +CD-2(a)/(b) `hub-spoke-bridge.md` actor-reach edits.
7. **#4196** — `deploy.sh` **Check 62** (count-vs-structure lint), **enforce-mode narrowly scoped**, with a committed **51-entry baseline** at `core/deploy/allowlists/count-structure-baseline.txt`. Both a `# Check 62` def-block and a `log "Check 62:"` emitter, per the Check-57 roster contract.
8. **#4197** — `readiness-map-template.md` TH-3 invariant + `deploy.sh` **Check 63** + the mandatory `build-skill-packages.sh release-hub` rebuild (serves #4196 and #4197 together).
9. **#4198** — dynamic-source **7 constants across 21 declaration sites in 10 files**, via a new shared lib `core/hooks/lib/fragile-ref-patterns.sh`, co-deployed by 3 installers. **No `deploy.sh` slot and no `deploy.sh` edit** — its control rides the existing tri-invoked `run-fragile-ref-fixtures.sh` harness.

---

## Stage Applicability Matrix

Default = all of Stages 5–13. Every skip carries its justification.

| Issue | S5 | S6 | S7 | S8 | S9 | S10–S11 | S12 | S13 |
|---|---|---|---|---|---|---|---|---|
| **#3804** | APPLY | APPLY | APPLY | APPLY | rel | rel | rel | APPLY |
| **#3838** | APPLY | APPLY | APPLY | APPLY | rel | rel | rel | APPLY |
| **#3839** | APPLY | APPLY | APPLY | APPLY | rel | rel | rel | APPLY |
| **#3938** | **SKIP** | APPLY | **REDUCED** | APPLY | rel | rel | rel | APPLY |
| **#3939** | **REDUCED** | APPLY | APPLY | APPLY | rel | rel | rel | APPLY |
| **#4195** | APPLY | APPLY | APPLY | APPLY | rel | rel | rel | APPLY |
| **#4196** | APPLY | APPLY | APPLY | APPLY | rel | rel | rel | APPLY |
| **#4197** | APPLY | APPLY | APPLY | APPLY | rel | rel | rel | APPLY |
| **#4198** | APPLY | APPLY | APPLY | APPLY | rel | rel | rel | APPLY |

`rel` = release-scoped (a single gate/spoke for the whole release; no per-issue axis per `hub-spoke-bridge.md` Procedure 2 Step 5). Stages 10–11 compressed per `release-process.md` § Stage Compression.

**Skip / reduction justifications:**

- **#3938 — Stage 5 SKIP.** Four one-line text corrections whose correct text is fully determined by the live skill roster (verified: all three named skills ship). Zero design surface — meets the "trivial" skip bar exactly. No `[ASSUMPTION – CONFIRM]` on the card.
- **#3938 — Stage 7 REDUCED (not skipped).** Both ACs are `grep`-shaped predicates that must be **run**, not reasoned about. Reduced = execute the two AC greps as a doc-conformance pass; author no tests.
- **#3939 — Stage 5 REDUCED.** The card's only open design question was *where* in the G2-13 surface the reference lands; the placement is settled in the File Change Matrix. Reduced Stage 5 = confirm the placement against duplicate-source discipline (AC2 requires citing, not restating) and stop.
- **No Stage 7/8 skips anywhere.** Every card carries `grep`/mutation-control ACs that must be executed to be graded. Grading a probe-validity release with unrun probes would be self-refuting.

---

## Contention Map

### Within-release (file-level)

| Surface | Issues | Class | Resolution |
|---|---|---|---|
| **`packages/release-hub.skill`** + `.sha256` | **#4196 × #4197** | **HARD — binary whole-file** | The package bundles `release-hub/SKILL.md`, `references/milestone-readiness-checklist.md` (#4196) **and** `references/readiness-map-template.md` (#4197). A binary artifact has no line ranges — either card's rebuild invalidates the other's. **Resolution:** sequence adjacent (7, 8); run **one** `build-skill-packages.sh release-hub` after **both** land; verify `deploy.sh --check` Check 7 before push. |
| **`core/deploy/deploy.sh`** | **#4196 × #4197** | append-pattern, distinct slots | **62 → #4196**, **63 → #4197** (rule-computed at Collective Review). Both append at the check-roster tail; neither edits an existing check body. Each needs **both** a `# Check NN` def-block and a `log "Check NN:"` emitter (Check-57 roster contract). |
| **`core/standards/design-artifact-standard.md`** | **#3838 × #3839** | soft — same file, disjoint hunks | #3838 → §12.1 + §12 note + §12.2 harness + §3 declaration. #3839 → §9. Verified disjoint. **Resolution:** adjacent sequencing (4, 5). |
| `core/schemas/gate-criteria-spec.md` | #3939 only | none in-release | #3804 explicitly does **not** edit this file — it is the canonical source both cards reconcile *to*. |
| `release/references/how-to/hub-spoke-bridge.md` | #4195 only | none in-release | Verified **not bundled in any `.skill` package** → adds no package-drift surface. |

### Cross-PR

**Baseline re-pinned at Commit 0.** The Stage-4 contention map was measured at `c4dde614`; `origin/main` has since advanced **25 commits** (two sibling releases merged; `v4.02` claimed by milestone 298). Collective Review verdict: **PROCEED; Stage 6 re-locates by content.** **13 of 14 target files verified untouched**; Check 62 verified still free.

**Standing instruction to every Engineering chip:** re-locate each edit anchor **by verified-unique content string, never by line number**, and re-verify at commit time — planning-time hunk claims about a file that concurrent PRs are editing go stale. Every Stage-5 design specified its edits by content anchor for exactly this reason.

**Structural-blast-radius (Tier-S):** this release's mover-set is **empty** — no rename, relocate, or delete anywhere in the File Change Matrix. No Tier-S serialization edge is created.

---

## Risk Register

Each entry names owner + mitigation. No passive risk voice.

| ID | Risk | Owner | Mitigation | Reversibility / Confidence |
|---|---|---|---|---|
| **R-1** | **`core/deploy/deploy.sh` cross-PR contention.** The highest-traffic file in the repo; sibling releases edit existing check bodies. | Engineering (#4196, #4197) | Allocate slots **62** and **63** (verified free at Commit-0 re-pin). Append at the roster tail — never edit an existing check body. Rebase before each commit if a sibling merges. | CHEAP / HIGH |
| **R-2** | **`core/schemas/gate-criteria-spec.md` cross-PR contention.** A sibling merge forces a rebase of #3939's hunk. | Engineering (#3939) | Sequence #3939 **early** (position 3) so the exposed hunk is small and short-lived. Land inside the **G2-13** body; **re-verify the region at commit time**, not from this plan. | CHEAP / HIGH |
| **R-3** | **`packages/release-hub.skill` binary shared-write between #4196 and #4197.** A binary has no line ranges, so either card's rebuild invalidates the other's. | Engineering (position 8) | Sequence adjacent. Run **one** rebuild after **both** land — never one per card. Verify Check 7 before push. | CHEAP / HIGH |
| **R-4** | **#4196 AC5 named an unreachable detection target** — workspace-root `CLAUDE.md`, not tracked in this repo. The AC as written cannot pass in CI. | Stage 5 (resolved) | Re-scoped to a tracked surface at Stage 5 per the Tier 1 [ADJUST]. Control: `core/CLAUDE.md.template` **is** tracked, proving the probe discriminates. | CHEAP / HIGH |
| **R-5** | **#4196 AC4's named instance already reads consistent on live main.** The release-hub `SKILL.md` / checklist pair was reconciled by earlier work. | Stage 5 + Stage 8 grader | **G-PL4 `re-scope-changed` on that AC sub-clause only** — not a `close-resolved` on the card. The card's headline still reproduces. Record the disposition as "already reconciled"; **do not manufacture an edit** to satisfy the AC. | CHEAP / HIGH |
| **R-6** | **#4196 false-positive blast radius.** A general "stated cardinality adjacent to an enumerable structure" heuristic over a ~500-file corpus over-fires; landed enforce-mode it can red-wall CI for this release and every sibling. | Engineering (#4196) + operator at D-3 | **Enforce, narrowly scoped** (D-3, held at revisit). The heuristic is scoped tightly at Stage 5 and paired with a **committed 51-entry baseline** so the accepted population is explicit, not inferred. Mutation controls (AC3/AC5) prove it has teeth. | MODERATE / MEDIUM |
| **R-7** | **#3804 scope exceeds its Affected Files list.** The card names 2 files; the AC1 enumeration finds mis-citations in **5**, and the approved range-citation scope adds a 6th. | Engineering (#3804) | The File Change Matrix carries all **6**. AC1 denominator restated at Stage 5 as **46 occurrences / 17 files** (26 × G3-04, 20 × G3-06) — *not* the 39 the readiness note recorded. Frozen artifacts (4 files / 9 occurrences) excluded and recorded per AC3. | CHEAP / HIGH |
| **R-8** | **Version double-claim by a sibling.** A sibling re-versioning mid-run can shift shared files under this release. | Hub | **Bind no version here** — ADR-092 slug-only. **Materialized and cost nothing:** `v4.02` was claimed by milestone 298 mid-run; this release was structurally immune because it binds nothing until the Stage-12 claim. | CHEAP / HIGH |
| **R-9** | **Check-roster contract breach.** A new slot requires **both** a `# Check NN` def-block **and** a `log "Check NN:"` emitter; authoring one without the other trips the roster check. | Engineering (#4196, #4197) | Author both in the same commit; run `deploy.sh --check` locally before push and grep the output for `"  FAIL:"` — the raw issue count is inflated by operator-instance drift and is not the signal. | CHEAP / HIGH |
| **R-10** | **#3938's AC2 sweep denominator is wrong in the card body** — states 14 `pipeline/stage-*.md` files; live count is **13**. | Engineering (#3938) + Stage 8 grader | State **13** when re-running the sweep. Findings otherwise reproduce exactly. **Worth naming:** this is itself an instance of the count-vs-structure class #4196 exists to catch, which is why CIAC-4 makes the release dogfood its own lint. | CHEAP / HIGH |
| **R-11** | **Rollback asymmetry on #4196.** Nine cards, one merge → release rollback is a single `git revert`. The exception is Check 62: if it lands enforce and later work merges green against it, a revert silently re-opens the gap. | Operator at Stage 9 | Release-level rollback stays CHEAP by construction. Check 62's committed baseline makes its accepted population auditable, so a revert is legible rather than silent. No snapshot beyond git history is required (Claude Code path — PR review *is* the dry-run gate). | Release-level CHEAP / HIGH; #4196-specific MODERATE / MEDIUM |
| **R-12** | **Baseline drift during the run.** Main advanced 25 commits between the Stage-4 pin and Commit 0; it will keep moving. | Every Engineering chip | **Re-locate every edit anchor by content, never by line number.** Verified at Commit 0: 13 of 14 target files untouched; Check 62 still free. Stage 9 A6.5 divergence re-check is the backstop. | CHEAP / HIGH |

---

## Cross-Issue Acceptance Criteria

Five cohesion constraints span ≥2 issues. Graded at Stage 9 QC3.5 / Phase A3.6 on the merged PR.

- [ ] **CIAC-1 (#4195 × #4196 × #4197 × #4198 — the probe-validity clause):** every check or lint this release authors reports a **denominator** and runs a **control expected to return non-zero**, and **cites** the probe-validity rule in `review-discipline-principles.md` rather than restating it.
  - *Method:* grep the Check-62 and Check-63 blocks in `core/deploy/deploy.sh`, the TH-3 row in `readiness-map-template.md`, and the identity-assertion step in `.github/workflows/reference-durability.yml` — each must match. **Control:** run the same grep against a pre-existing check block and confirm it does **not** match, proving the grep discriminates rather than matching everywhere.

- [ ] **CIAC-2 (#3838 × #3839 on `design-artifact-standard.md`):** the two amendments are section-disjoint, and the §12.2 enumeration harness agrees with **both** the amended rule-7 and the amended §9 `depicts=` convention.
  - *Method:* `git diff --unified=0 origin/main..HEAD -- core/standards/design-artifact-standard.md` — confirm hunk ranges do not overlap; then read §12.2 and confirm its decision-tree branch references neither a stale fence-only rule-7 shape nor a stale `depicts=` form. **Control:** the pre-change file's §12.2 branch, which diverges from the amended rule.

- [ ] **CIAC-3 (#3804 × #3939 — Gate-criterion citation integrity):** after both land, every Gate-criterion ID cited in the files this release touches resolves to its canonical meaning in `core/schemas/gate-criteria-spec.md` — **and neither card introduces a new mis-citation.**
  - *Method:* re-run the #3804 AC1 enumeration over the post-change tree, denominator restated, frozen artifacts excluded; classify each hit agree/disagree; confirm **zero** disagreements. **And** confirm the line #3939 adds inside G2-13 cites the index path without introducing a criterion-ID claim. **Control:** a known-correct `G3-05` citation classifies as *agree*.
  - *Note (folded from A6.5 PR-2):* the "no new mis-citation" half is load-bearing and is **not** satisfied by the `G3-0[46]` probe alone — a re-ID relocates a residual outside that probe's denominator. Grade the post-change **edge**, not the token.

- [ ] **CIAC-4 (#4196 × #3938 × #4197 — dogfooding: the release passes its own lint):** the release's own edits introduce **no** new stated-count-vs-structure mismatch, and the Check-62 lint this release ships flags none of the files this release touches.
  - *Method:* run `deploy.sh --check` filtered to Check 62 against the release-branch head, scoped to the File Change Matrix paths; confirm zero `  FAIL:` lines. **Control:** introduce one deliberately wrong count in a scratch copy of a touched file and confirm Check 62 flags it (mutation control; revert).
  - *Rationale for inclusion:* #3938's own card body already carried a count error (R-10) — this release is a live test population for its own lint.

- [ ] **CIAC-5 (#4197 × #4196 on `readiness-map-template.md`):** #4197's token-count edit to the TH-2 row is consistent with what #4196's Check 62 asserts about that same line — the two cards must not disagree about the same file.
  - *Method:* after both land, run Check 62 scoped to `readiness-map-template.md` and confirm it does not flag the TH-2 row #4197 edited. **Control:** revert the #4197 edit in a scratch copy and confirm Check 62's verdict changes, proving the check actually reads that line.
  - *Provenance:* accepted as deferred item (c) at Collective Review.

---

## File Change Matrix

Machine-readable — **one path per line**, for deterministic extraction by Stage 7/8/9 chip prompts. Intent in the trailing comment.

```paths
release/releases/plans/corpus-integrity-lints-and-refs_RELEASE_PLAN.md   # new  — this plan, Engineering Commit 0
core/schemas/stage-io-contracts.md                                       # edit — #3804 re-ID + de-cite Gate-3 citations (5 sites incl. the L177 forced co-edit)
core/disciplines/operating-model.md                                      # edit — #3804 consolidate the drifted Gate-3 restatement to a pointer + 2 range citations
core/disciplines/github-feature-strategy.md                              # edit — #3804 re-ID a Dependencies-field consumer citation
core/disciplines/five-function-spine-and-process-flows.md                # edit — #3804 re-ID the Stage-3 dependency-graph citation
release/references/specs/ticket-information-architecture.md              # edit — #3804 re-ID the #N-substring-validation gate list
release/references/specs/stage-to-skill-mode-mapping.md                  # edit — #3804 2 stale gate-range citations (approved expansion D-7(b))
release/references/pipeline/stage-03-bundle.md                           # edit — #3938 Automation-Level note: Target -> Today framing
release/references/pipeline/stage-04-planning.md                         # edit — #3938 same
release/references/pipeline/stage-05-solutioning.md                      # edit — #3938 same
release/references/pipeline/stage-06-engineering.md                      # edit — #3938 same
core/schemas/gate-criteria-spec.md                                       # edit — #3939 one reference line inside the G2-13 criterion body (cites, does not restate)
core/disciplines/cross-chain-architecture-map.md                         # edit — #3939 clear the [DEFERRED] forward-note
core/standards/design-artifact-standard.md                               # edit — #3838 §12.1 rule-7 + §12 table-awareness + §12.2 harness + §3 declared in-milestone; #3839 §9 depicts= convention
core/disciplines/review-discipline-principles.md                         # edit — #4195 author the probe-validity discipline (denominator + control)
core/standards/evidence-grounding-standard.md                            # edit — #4195 denominator/control requirement on grounded claims
release/references/how-to/hub-spoke-bridge.md                            # edit — #4195 spoke-prompt convention cites the discipline; + CD-2(a)/(b) actor-reach edits
core/standards/review-composition-framework.md                           # edit — #4195 mandatory 5.6 cascade (accepted D-6)
release/references/protocols/architecture-conformance-cadence.md         # edit — #4195 fold-in, 1 line (accepted D-6)
release/references/how-to/design-artifact-backfill-completion-condition.md # edit — #4195 fold-in, 3 lines (accepted D-6)
release/references/templates/design-review-checklist.md                  # edit — #4195 R3 row (approved expansion D-7(c))
core/deploy/deploy.sh                                                    # edit — #4196 Check 62 (def-block + log emitter); #4197 Check 63 (def-block + log emitter). APPEND ONLY, no existing check body edited
core/deploy/allowlists/count-structure-baseline.txt                      # new  — #4196 committed 51-entry accepted-population baseline
release/skills/release-hub/SKILL.md                                      # edit — #4196 named instance (see R-5 disposition)
release/skills/release-hub/references/milestone-readiness-checklist.md   # edit — #4196 named instance (see R-5 disposition)
release/skills/release-hub/references/readiness-map-template.md          # edit — #4197 add TH-3 invariant row; TH-2 token-count edit (CIAC-5)
packages/release-hub.skill                                               # edit — ONE rebuild after BOTH #4196 and #4197 land (R-3)
packages/release-hub.skill.sha256                                        # edit — content-baseline sidecar re-emitted by build-skill-packages.sh
core/hooks/lib/fragile-ref-patterns.sh                                   # new  — #4198 shared constant declarations (7 constants), the single source
core/hooks/block-fragile-refs.sh                                         # edit — #4198 source the shared lib instead of hand-copied literals
core/hooks/run-fragile-ref-fixtures.sh                                   # edit — #4198 same; also absorbs the partially-applied MIN_SELFDESCRIBE_WORDS precedent
core/hooks/lib/positional-issueref.awk                                   # edit — #4198 replace the "kept byte-identical" comment contract (AC3)
.github/workflows/reference-durability.yml                               # edit — #4198 source the constants dynamically; add the identity-assertion step
docs/scripts/setup-workspace.sh                                          # edit — #4198 co-deploy the new hooks lib
release/releases/RELEASE_LOG.md                                          # edit — Stage-13 close-out ledger row [Stage 13, not this build]
```

**Path-count note (dogfooding CIAC-4):** the block above enumerates **35** paths. This count is stated adjacent to the structure it describes and is therefore itself in Check 62's population — deliberately so.

**Provisional entries — confirm at the owning chip's commit, amend the § Deviation Log if they change:**
- **#4198's installer trio.** Collective Review locked scope at *"7 constants / 21 declaration sites / 10 files (lib `core/hooks/lib/fragile-ref-patterns.sh`, co-deploy allowlist across 3 installers)"*. `docs/scripts/setup-workspace.sh` is verified as a hooks-lib co-deploy surface `[SOURCE]`; the remaining two co-deploy surfaces are `[INFERRED]` from the same mechanism and are the **#4198 spoke's** to confirm and append. The matrix lists only the verified one.

**Explicitly NOT edited:**
- **`core/schemas/gate-criteria-spec.md` by #3804** — it is the canonical criterion registry both #3804 and #3939 reconcile *to*. #3804 changes consumers, never the source. (#3939 edits it, in the disjoint G2-13 body.)
- **The 4 frozen artifacts** carrying meta-references to the mis-citations — 2 shipped release notes, 2 shipped release plans, plus the `RELEASE_LOG.md` row. Untouched by design; the exclusion is recorded per #3804 AC3.
- **`core/skills/eval-writer/**`** — all its Gate-3 citations classify AGREE; editing would force a package rebuild for no gain.
- **`core/schemas/gate-evaluation-spec.md`** — its structural-criteria count is wrong (states 4, live value is 8), but correcting it changes *what the metric measures*. That is a behavioral change needing its own AC, routed to a follow-up. It is deliberately left as a live fixture for #4196's lint.
- **`core/deploy/deploy.sh` by #4198** — its control rides the existing tri-invoked fixture harness; no slot, no edit (rule-computed at Collective Review).

---

## Domain Practice Provenance

The File Change Matrix is entirely internal pmo-platform artifacts. 30 of 35 paths are `core/` / `release/` governance, pipeline-spec, and standards documents (`domain: governance`); the secondary class is `software` for the 5 executable paths (`core/deploy/deploy.sh`, 3 × `core/hooks/**`, `.github/workflows/reference-durability.yml`, `docs/scripts/setup-workspace.sh`). Sourcing-exempt per `stage-04-planning.md` § 5.7 — the entire matrix is internal artifacts and no external practice governs criterion-ID citation hygiene — but the domain class is mandatory in every mode and travels unchanged into Solutioning and Engineering.

domain_practice: { source: N/A — pipeline-internal release, date: 2026-07-31, domain: governance }

---

## Deviation Log

Deltas between the Stage-4 plan of record (#4335) and the ratified dispositions (Procedure 0 gate, Wave 1 Decision Briefing, Collective Review scope-lock), plus Stage-6 implementation findings. All are refinements or measured expansions; none re-opens the bundle.

| # | Stage-4 / spec record | Ratified / implemented delta | Basis |
|---|---|---|---|
| **Δ-D1** | Stage-4 spoke recommended an operator override to `novel` | **Class held at `cross-cutting`; engagement density overridden to `Standard`.** The multi-trigger rule makes `cross-cutting` rule-determined, so `novel` would be a stricter-to-cheaper re-classification requiring explicit risk acceptance. The hub surfaced a third option the spoke did not enumerate — hold the class, override the one dimension that actually differs. Stage 9 `Deep`, Stage 5 `ALL`, Stage 13 `30-day` are identical across both classes. | Procedure 0 gate, D-1 |
| **Δ-D2** | Declared sequence built #4196 before #4195 | **Swap adopted** — #4195 moves to position 6, ahead of its three citing consumers. Zero hard `blocked-by` edges: this is ordering hygiene, not unblocking. | Procedure 0 gate, D-2 |
| **Δ-D3** | Stage-4 spoke recommended **warn-mode** for Check 62 per the `shadow → warn → enforce` convention | **Enforce, narrowly scoped.** Held at the Wave-1 revisit on *corrected* evidence — the hub's original argument (that the warn cohort cannot graduate because its drain sinks are never written) was **over-broad and was withdrawn**: the deploy-check sink does have substantial history in the operator instance. The verdict stands on its own terms: enforce-narrow ships the value this release, the mutation controls give it teeth, and the heuristic is scoped so it cannot red-wall CI for this release or its siblings. | Procedure 0 D-3; **held** at Wave-1 D-3-REVISIT |
| **Δ-D6** | Stage-4 matrix carried neither the §5.6 cascade nor the two standing-doc fold-ins | **Accepted:** `review-composition-framework.md` (mandatory §5.6 cascade of #4195, 9 count-occurrences), `architecture-conformance-cadence.md` (1 line), `design-artifact-backfill-completion-condition.md` (3 lines). Both fold-ins are *standing* docs asserting gaps these cards close. | Wave 1 Decision Briefing, D-6 |
| **Δ-D7** | Stage-4 scoped #3804 to the mis-citation sites only | **All three expansions accepted:** (a) #3804's L177 **forced co-edit** — fixing the adjacent line without it would *manufacture* a new criterion-ID collision, the exact defect class the card drains; (b) #3804's **4 range citations** (`G3-01..G3-06`: 4 UPDATE / 1 PRESERVE / 2 routed out); (c) #4195's R3 `design-review-checklist.md` row. | Wave 1 Decision Briefing, D-7 |
| **Δ-lock** | Stage-4 sized #4198, #4196, #4197 from card bodies | **LOCK AT MEASURED SCOPE.** #4198 = 7 constants / 21 declaration sites / 10 files + a new shared lib + co-deploy across 3 installers. #4196 = lint + a committed 51-entry baseline. #4197 = check + `deploy.sh` slot 63 + the mandatory package rebuild. **No expansion adds a capability** — each is the measured size of already-approved work. | Collective Review scope-lock |
| **Δ-A6.5** | Five independent adversarial reviews produced ~45 advisory findings, zero Blockers | **FOLD IN AC-AFFECTING ONLY.** In Stage-6 scope: #3804 PR-2 (re-ID relocates the defect outside its own probe's denominator); #3839 FMF-3; #3939 PR-1 + FM-1; #3838's AC3 grading trap. Remainder routed to follow-ups. | Collective Review scope-lock |
| **Δ-defer** | Three items had been deferred at Stage 5 | **All three accepted:** (a) #4195 CD-2(a)/(b) — two `hub-spoke-bridge.md` edits closing the actor-reach gap; (b) #3838 CD-1 — §3 declared in-milestone, its deferral rationale having expired when #3839 canonicalized the resolving rule minutes later; (c) **CIAC-5**, binding #4197's token-count edit to #4196's Check 62 over the same `readiness-map-template.md` row. | Collective Review scope-lock |
| **Δ-slots** | Stage-4 identified Check 62 as free; #4197 and #4198 slots undetermined | **Rule-computed:** `deploy.sh` slot **62 → #4196**, slot **63 → #4197**. **#4198 needs no slot and no `deploy.sh` edit** — its control rides the existing tri-invoked `run-fragile-ref-fixtures.sh` harness. | Collective Review scope-lock |
| **Δ-baseline** | Stage-4 pinned `c4dde614`; contention map measured there | **Re-pinned at Commit 0 to `93023d8e`** (+25 commits: two siblings merged, `v4.02` claimed by milestone 298). **PROCEED** — 13 of 14 target files verified untouched, Check 62 verified still free. **Every chip re-locates its edit anchors by content, not by line number.** | Collective Review; Commit-0 re-verify |
| **Δ-version** | — | **`v4.02` was claimed by a sibling mid-run at zero cost to this release.** The early-binding HALT that ADR-092's slug-only rule exists to prevent did not occur. This is the first release to have the mechanism tested by a live concurrent claim rather than in theory. | Collective Review; ADR-092 |

---

## Rollback

Per `RELEASE_PROTOCOL.md § Rollback protocol` (operator-authorized). One branch, one PR, one merge → release-level rollback is `git revert` of the merge commit.

| Surface | Rollback | Tier |
|---|---|---|
| The five drain cards (#3804 / #3938 / #3939 / #3838 / #3839) — prose-only | `git revert` the slice commit | **CHEAP** |
| #4195 probe-validity discipline + cascade + fold-ins | `git revert` | **CHEAP** |
| #4196 Check 62 + committed baseline | `git revert` — but see the asymmetry note | **MODERATE** |
| #4197 Check 63 + TH-3 + package rebuild | `git revert`, then rebuild the package | **CHEAP** |
| #4198 hooks lib + dynamic sourcing + installer co-deploy | `git revert` (restores the hand-copied literals) | **CHEAP** |
| `packages/release-hub.skill` (+ `.sha256`) | `git revert`, then `build-skill-packages.sh release-hub` | **CHEAP** |

**Asymmetry note (R-11).** Check 62 ships **enforce**. Reverting it after other work has merged green against it silently re-opens the gap rather than announcing it — the one non-symmetric surface in this release. Its committed 51-entry baseline is the mitigation: the accepted population is auditable in-tree, so a revert is legible rather than silent.

No IRREVERSIBLE actions. **No tag is claimed by this plan** — version identity binds at the Stage-12 atomic claim, so there is no tag-rollback surface at Stage 6.

---

*Closure-phrasing note: every per-issue closure reference in this plan is written as "mark #N as closed at Stage 13" — no close-family verb is bound to an issue number, so transcription into PR bodies will not trip GitHub's auto-close parser.*
