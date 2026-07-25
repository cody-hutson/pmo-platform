---
title: Release Plan — release-identity-and-plan-naming (slug-primary claim-time binding)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned — provisional {{RELEASE_VERSION}} (bump-class minor; slug-primary pre-claim, version binds atomically at the Stage-12 claim)
milestone: release-identity-and-plan-naming
release_class: novel
reversibility: MODERATE / Confidence HIGH
---
# Release Plan — `release-identity-and-plan-naming`

**Milestone:** `release-identity-and-plan-naming` (#279) · slices #2548 (+ split sibling #3993) · #3107 · #3119 · #3307
**Version identity:** **versioned** — bump-class `minor`, provisional **{{RELEASE_VERSION}}** (recorded determination; binds atomically at the Stage-12 tag per the two-phase allocation rule). This plan is authored **slug-primary / pre-claim** under the **Hybrid dogfood** decision (D-Dogfood **(C)**): the branch, this plan filename, and in-file version references carry the slug / `{{RELEASE_VERSION}}` placeholder now; the concrete number binds at Stage 12 via the **current** `claim-version.sh` engine (this introducing release does **not** self-exercise the unmerged claim-time substitution pass it ships — reflexive-pipeline-loop discipline).
**Topology:** D-C SINGLE — one release branch (`release/release-identity-and-plan-naming`), one PR, one merge; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** P0 fully-serial (heavy shared-file contention on `deploy.sh` + `lint_release_corpus.py` + the lockstep pair) — Stage-6 slices build one at a time in dependency order on the single branch.
**Release class:** `novel` (Stage-4 recommendation R1: `novel`-(b) fires — three release-specific D-class decisions; buys Deep Stage 9 + Stage-5 activation-bias ALL; risk-appropriate for the self-referential scope).

> **Provenance.** This file transcribes the Stage-4 Release Planning output (hub sub-task; comment `5079886320`) reconciled to the four approved Stage-5 Solutioning designs (sub-tasks #3994 / #3998 / #4002 / #4010) and the Collective-Review scope-lock (D-Split, D-Reconcile, D-Dogfood, and the AC5 CARVE to #3713). Where a scope-lock disposition superseded a Stage-4 assumption, the § Deviation Log records the ratified delta.

---

## Summary (30 seconds)

Milestone **#279** — five in-scope delivery slices, topology **D-C SINGLE** (one branch → one PR → one merge). Keystone **#2548** (bind the monotonic release-identity — plan-file name + branch — with a placeholder until claim-time, resolved at the atomic CAS win) is the load-bearing refactor; it hard-blocks **#3107** (slug-primary conformance check) — enforcing the check before the migration lands would fail every existing release. **#2548** split at Stage 4 into a **core** half (retained on #2548: protocol/mechanism — `plans/README.md`, `RELEASE_PROTOCOL.md`, `release-process.md`, `claim-version.sh`, ADR-092) and an in-milestone **sibling #3993** (executing-skill gates + broad prescribing surfaces + `.skill` rebuild). **#3119** (de-dup + re-home the misnamed `v3.54` plan) and **#3307** (widen the plan-filename lint regex to admit the `vX.Y.Z` patch form) are otherwise-independent correctives.

Three properties bind the release:
1. **CIAC-1** — no gap between what #2548 migrates and what #3107 enforces (the slug-primary pre-claim form is byte-identical on both sides).
2. **CIAC-2** — lockstep: the corpus mandate (#2548-core) and the executing skills (#3993) agree, and ship in the same PR/merge.
3. **CIAC-3** — the widened `CANONICAL_FILENAME_RE` (`lint_release_corpus.py`) admits the slug-primary form (#2548) AND the `vX.Y.Z` patch form (#3307) in **one** coordinated edit, and still rejects malformed names.

Reversibility of the release as a whole: **MODERATE · confidence HIGH** (coordinated corpus + skill-package change; `git revert -m 1`-able; the existing re-verify guards remain a backstop). #3119 / #3307 in isolation are **CHEAP**.

---

## Dependency Graph

```
#2548-core  ──BLOCKS──▶  #3107               (native dep — enforcing before the migration would fail every existing release)
#2548-core  ◀─DEPENDS_ON─▶  #3993 (sibling)  (lockstep — partial migration regrows the leak; skills reject what the corpus mandates until BOTH land)
#3119       (no edges — independent corrective; grandfathered post-claim target)
#3307       (no ticket edge — independent; FILE-contends #2548 on lint_release_corpus.py)
```

- **Critical path:** `#2548-core → #3107` (one edge). The lockstep pair `#2548-core ↔ #3993` is co-terminal (same merge), not a serial hop.
- **Leverage:** #2548-core is the sequence head — the conformance check, the skill migration, and the lint slug-form all key off it.
- No cycles.

---

## Implementation Sequence

Dependency-ordered **commit order on the single release branch** (D-C SINGLE — sequence = commit order, not separate merges; P0 fully-serial):

0. **Commit 0 — this release plan file** (Engineering Commit 0), slug-named at `release/releases/plans/release-identity-and-plan-naming_RELEASE_PLAN.md`.
1. **#2548-core** — corpus mechanism: `plans/README.md` (AC1) + `RELEASE_PROTOCOL.md` & `release-process.md` (AC2, edited **independently** — not a Check-9 mirror pair) + `claim-version.sh` post-CAS stamping pass (AC3) + **ADR-092** + the coordinated lint slug-form (with #3307). AC5 (Check#/ADR# tokenization) is **STRUCK** — carved to #3713.
2. **#3993 (sibling)** *(lockstep with #2548-core — same PR/merge)* — executing-skill gates (AC4: `release-planner/SKILL.md`, `release-plan-template.md`, `release-executor/execution-checklist.md`) + broad prescribing surfaces (AC6: `git-workflow.md` + P2 docs/schemas) + `.skill` package rebuilds. Per-occurrence pre-claim/post-claim discrimination — **not** a blanket `vX.Y`→slug sweep.
3. **#3307 + the coordinated lint edit** — widen `CANONICAL_FILENAME_RE` to admit BOTH the slug-primary pre-claim form AND the `vX.Y.Z` patch form (ONE regex, authored once) + note the patch PLAN-filename form in `release-notes-standard.md`.
4. **#3119** — content-verify EACH `v3.54` plan, then `git mv` the `86-methodology-pack-foundation` copy to `plans/v3/v3.60_RELEASE_PLAN.md`; the other is de-dup'd only if a confirmed 86 duplicate.
5. **#3107** — add the slug-primary conformance check (new `check-identity-conformance.py` + `deploy.sh` Check 59). **MUST be the last identity-touching commit** (after #2548's migration is present on the branch).

---

## File Change Matrix

```
release/releases/plans/README.md                     | #2548-core | edit — generalize _unversioned/ claim-at-merge slug-keying to the versioned pre-claim window (AC1); reconcile the vX.Y mandate + disposition rule
release/governance/RELEASE_PROTOCOL.md                | #2548-core | edit — extend "binds no concrete value" from the tag to plan-file/branch (AC2); compose with the {versioned,version-less} mode (do not collapse)
release/governance/release-process.md                | #2548-core | edit — §Release-Plan Versioning "Artifact of record": pre-claim slug + post-claim versioned rename (AC2; edited INDEPENDENTLY)
release/tools/claim-version.sh                        | #2548-core | edit — ADD pre-CAS pre-flight + post-CAS {{RELEASE_VERSION}} stamping + slug→plans/v<MAJOR>/vX.Y rename on the CAS-win path (AC3); CAS arithmetic/retry UNTOUCHED
core/ADRs/ADR-092-plan-file-claim-time-stamping.md    | #2548-core | add — plan-file identity binds at claim-time stamping (post-CAS), extending ADR-088
core/deploy/tools/lint_release_corpus.py             | #2548-core + #3307 | edit — ONE coordinated CANONICAL_FILENAME_RE change: slug-primary + vX.Y.Z; prune now-dead allowlist entries (CIAC-3)
release/skills/release-planner/SKILL.md              | #3993 | edit — target-path gate (~L384) admits the slug-keyed pre-claim form (AC4)
release/skills/release-planner/references/release-plan-template.md | #3993 | edit — Version→{{RELEASE_VERSION}}, Branch→release/<slug>, Milestone→<slug>, header slug form (AC4/AC6)
release/skills/release-executor/references/execution-checklist.md  | #3993 | edit — pre-exec Check #5 accepts the slug-keyed pre-claim form (AC4)
packages/release-planner.skill                       | #3993 | rebuild
packages/release-executor.skill                      | #3993 | rebuild
core/rules/git-workflow.md                           | #3993 | edit — branch/commit/PR/PR-title slug-primary forms; LEAVE the tag form (claim-time) (AC6)
core/schemas/stage-io-contracts.md                   | #3993 | edit — pre-claim rows → slug; leave post-claim (tag/RELEASE_LOG) rows (AC6, P2)
release/references/standards/release-corpus-schema.md | #3993 | edit — ADDITIVE placeholder-until-claim statement; LEAVE shipped-corpus canonical filenames (AC6, P2)
core/specs/terminology-glossary.md                   | #3993 | edit — pre-claim milestone/plan forms → slug; leave the tag clause (AC6, P2)
core/disciplines/execution-framework.md              | #3993 | edit — Commit-0 pre-claim plan form → slug (AC6, P2)
release/releases/hub-state/*.template                | #3993 | edit — pre-claim placeholder forms → slug (AC6, P2)
core/standards/hub-session-continuity.md             | #3993 | edit — plan-file + runtime-dir + sed keys → slug (AC6, P2)
core/deploy/tools/cross_module_audit_helper.py       | #3993 | edit — retarget the L122 suppression to the new release/<slug> branch form (AC6)
release/references/standards/release-notes-standard.md | #3307 | edit — note the patch vX.Y.Z PLAN filename is admitted (scope to the PLAN filename; do NOT touch the notes "no patches" content policy)
release/releases/plans/v3.54_RELEASE_PLAN.md         | #3119 | git mv → release/releases/plans/v3/v3.60_RELEASE_PLAN.md (86-methodology-pack-foundation; RELEASE_LOG.md:124 authority)
core/deploy/tools/check-identity-conformance.py      | #3107 | add — window-gated slug-primary conformance predicate (+ --self-test, 4 fixtures)
core/deploy/deploy.sh                                | #3107 | edit — add Check 59 wiring the primitive (concrete integer, per Check-57 roster contract)
```

---

## Risk Register

| ID | Class | Risk | Mitigation | Reversibility·Confidence |
|---|---|---|---|---|
| **R1** | Dependency | #2548 → #3107 hard edge: #3107 cannot verify until #2548's migration is on the branch. | Build order (#3107 last identity commit). CIAC-1 asserts no gap. | MODERATE·HIGH |
| **R2** | Contention | `lint_release_corpus.py` `CANONICAL_FILENAME_RE` co-edited by #2548 (slug) + #3307 (patch). | ONE coordinated regex change (CIAC-3). | MODERATE·HIGH |
| **R3** | Lockstep | #2548-core (corpus) + #3993 (skills) must land together — partial migration regrows the leak. | D-C SINGLE — both are commits on one branch, one merge. CIAC-2 grades it. | MODERATE·HIGH |
| **R4** | Data / correctness | #3119: TWO `v3.54` plans exist (flat + `v3/`); the slot was contended across milestones 80/86. | Content-verify EACH before any move: the 86 copy → `v3/v3.60`; the other de-dup'd only if a confirmed 86 duplicate, else halt-and-report. `[authority: RELEASE_LOG.md:124]` | CHEAP·MEDIUM |
| **R5** | Self-referential | This release edits `claim-version.sh` + the release skills + `plans/README.md` + `RELEASE_PROTOCOL.md` — the machinery the pipeline runs under. | `.skill` rebuild at Stage 13 (deployed spoke copies unaffected mid-run); `claim-version.sh` change is ADDITIVE (CAS path untouched); D-Dogfood (C) — do NOT self-exercise the unmerged claim path; forward-only cutover grandfathers existing artifacts. | MODERATE·MEDIUM |
| **R6** | Blast radius (scope) | AC5 (Check#/ADR# tokenization) fights the gap-free ADR CI + the deploy.sh Check-count convention. | **CARVED to #3713** (Stage-5 #3994 verdict): Check#/ADR# are already claim-deferred by the renumber-at-Engineering discipline (cheap collision + existing indirection), a different class from the plan-file's expensive-collision seam. #2548 tightens to AC1-AC3/AC7/AC8. | CHEAP·HIGH |
| **R7** | Version-slot contention (live) | Heavy concurrent-release churn; a sibling may claim the next provisional slot before this release merges. | D-Version is a recorded determination (bump-class `minor`, provisional {{RELEASE_VERSION}}); re-verify at Engineering Commit 0 + the Stage-12 atomic claim — the standing mechanism, no new work. | CHEAP·HIGH |
| **R9** | Rollback | Whole-release rollback is a coordinated corpus + `.skill` revert. | `git revert -m 1` the merge; `.skill` rebuilds from reverted source; the pre-existing re-verify guards remain the backstop. #3119/#3307 revert independently (CHEAP). | MODERATE·HIGH |

---

## Cross-Issue Acceptance Criteria

**CIAC-1 — no gap between what is migrated and what is enforced.** #2548 (+#3993) × #3107. The slug-primary pre-claim form #2548 establishes is EXACTLY the form #3107's check accepts; a version-primary in-flight identity is rejected by #3107 and absent from every surface #2548 migrates. Verify: run #3107's check against slug-primary (PASS) + version-primary (FAIL) in-flight fixtures.

**CIAC-2 — lockstep: corpus mandate and executing skills agree.** #2548-core × #3993. No normative version-primary in-flight identity survives across the corpus AND the executing-skill surfaces; the `.skill` packages are rebuilt. Verify: `grep -rn` for a surviving normative pre-claim `vX.Y_RELEASE_PLAN.md` / `release/vX.Y` → zero; `.skill` mtimes/hashes refreshed.

**CIAC-3 — the widened lint regex admits both new forms and no malformed form.** #2548 × #3307. After the coordinated change, the lint accepts the slug-primary pre-claim form AND the `vX.Y.Z` patch form, and still rejects malformed names (`v3.65.1.2`, `v3.65.`, `v3.65.1.`). Verify: run `lint_release_corpus.py --check filename` against each fixture.

---

## Operator Decision Gates (rendered at Collective Review — recorded here)

- **D-Split → (A) SPLIT.** #2548 carved into core (#2548, AC1-AC3/AC7/AC8) + in-milestone sibling #3993 (AC4 + AC6 + `.skill` rebuild). CIAC-2 enforces lockstep-ship.
- **D-Reconcile → (A) ACCEPT.** Slug-keying is the universal PRE-claim form; the `{versioned, version-less}` mode governs POST-claim disposition (versioned → rename/stamp `vX.Y` at the claim; version-less → stays slug-keyed in `_unversioned/`). Composes with #3016, does not collapse it.
- **D-Dogfood-naming → (C) HYBRID.** Adopt the slug-primary NAME (branch + this plan) now; bind the version via the CURRENT (pre-migration) `claim-version.sh` engine at Stage 12. Do NOT self-exercise the unmerged substitution pass (reflexive-pipeline-loop; introducing-release-exempt).
- **AC5 CARVE → #3713.** Check#/ADR# tokenization struck from #2548 (Stage-5 #3994 verdict — different identifier class; already claim-deferred by renumber-at-Engineering).
- **D-Version.** Recorded determination: bump-class `minor`, provisional {{RELEASE_VERSION}}; re-verify at Engineering Commit 0 + the Stage-12 atomic claim.

---

## Deviation Log

Populated by the Stage-6 engineering spoke as deltas from the Stage-5 designs are encountered; empty at plan authoring. (Substantive deltas — e.g. #3119's second `v3.54` file resolving to a different milestone than the de-dup framing assumed — are recorded here and surfaced in the PR body.)

---

## Verification Evidence

(Populated after Stage 12 execution.) Release-level: `lint_release_corpus.py --check filename` clean incl. the new slug plan; `check-adr-numbers.py` PASS (ADR-092 contiguous); `check-identity-conformance.py --self-test` PASS; `.skill` packages rebuilt; `claim-version.sh --self-test` PASS (U-0..U-13).
